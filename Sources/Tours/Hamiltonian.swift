import GraphProtocols
import Walks

/// The rows a Hamiltonian search reads, in index space: `row` is the graph's own (each edge end
/// in `incidentEdges` or `outEdges` order, with its edge number), which fixes the order of the
/// search; `next` and `previous` are the distinct other neighbours (successors, predecessors) of
/// each vertex, self-loops and parallel copies dropped, which the pruning counts. Undirected,
/// `previous` is `next`.
@frozen
@usableFromInline
struct _HamiltonianRows: Sendable {
    @usableFromInline var rowOffsets: [Int]
    @usableFromInline var rowTargets: [Int]
    @usableFromInline var rowEdges: [Int]
    @usableFromInline var nextOffsets: [Int]
    @usableFromInline var next: [Int]
    @usableFromInline var previousOffsets: [Int]
    @usableFromInline var previous: [Int]
    @usableFromInline let directed: Bool

    @inlinable
    var count: Int { rowOffsets.count - 1 }

    /// From rows with edge numbers.
    @inlinable
    init(_ rows: _CompressedRows, directed: Bool) {
        let n = rows.count
        let offsets = rows.offsets, targets = rows.targets
        rowOffsets = offsets
        rowTargets = targets
        rowEdges = rows.edges
        self.directed = directed
        var stamp = [Int](repeating: -1, count: n)
        var nextOffsets = [Int](repeating: 0, count: n + 1)
        var next: [Int] = []
        next.reserveCapacity(targets.count)
        for v in 0 ..< n {
            for k in offsets[v] ..< offsets[v + 1] {
                let w = targets[k]
                if w == v || stamp[w] == v { continue }
                stamp[w] = v
                next.append(w)
            }
            nextOffsets[v + 1] = next.count
        }
        self.nextOffsets = nextOffsets
        self.next = next
        if directed {
            // The predecessors: the distinct successor lists turned around, by a counting sort.
            var previousOffsets = [Int](repeating: 0, count: n + 1)
            for w in next { previousOffsets[w + 1] += 1 }
            for v in 0 ..< n { previousOffsets[v + 1] += previousOffsets[v] }
            var fill = previousOffsets
            var previous = [Int](repeating: 0, count: next.count)
            for v in 0 ..< n {
                for k in nextOffsets[v] ..< nextOffsets[v + 1] {
                    let w = next[k]
                    previous[fill[w]] = v
                    fill[w] += 1
                }
            }
            self.previousOffsets = previousOffsets
            self.previous = previous
        } else {
            previousOffsets = nextOffsets
            previous = next
        }
    }
}

/// A fixed-size buffer of trivial values (vertex numbers, counts, flags) with checked indexing and
/// no copy-on-write: a write is a store through `nonmutating set`, with no uniqueness check and no
/// retain or release of an array's storage, which the search's mutating methods paid on every
/// access (as MatchingModule's `_BlossomBuffer`). Freed by `deallocate()`.
@frozen
@usableFromInline
struct _SearchBuffer<Element> {
    @usableFromInline let base: UnsafeMutablePointer<Element>
    @usableFromInline let count: Int

    @inlinable
    init(repeating value: Element, count: Int) {
        self.count = count
        base = UnsafeMutablePointer<Element>.allocate(capacity: Swift.max(count, 1))
        base.initialize(repeating: value, count: count)
    }

    @inlinable
    init(_ elements: [Element]) {
        count = elements.count
        base = UnsafeMutablePointer<Element>.allocate(capacity: Swift.max(count, 1))
        elements.withUnsafeBufferPointer { if let source = $0.baseAddress { base.initialize(from: source, count: count) } }
    }

    @inlinable
    subscript(i: Int) -> Element {
        @inline(__always) get {
            precondition(UInt(bitPattern: i) < UInt(bitPattern: count), "Index out of range")
            return base[i]
        }
        @inline(__always) nonmutating set {
            precondition(UInt(bitPattern: i) < UInt(bitPattern: count), "Index out of range")
            base[i] = newValue
        }
    }

    @inlinable
    func deallocate() {
        base.deinitialize(count: count)
        base.deallocate()
    }
}

/// `_HamiltonianRows` copied into buffers once, shared by the searches from every start.
/// Undirected, `previous` is `next` (the same buffers, freed once).
@frozen
@usableFromInline
struct _HamiltonianRowBuffers {
    @usableFromInline let rowOffsets: _SearchBuffer<Int>
    @usableFromInline let rowTargets: _SearchBuffer<Int>
    @usableFromInline let rowEdges: _SearchBuffer<Int>
    @usableFromInline let nextOffsets: _SearchBuffer<Int>
    @usableFromInline let next: _SearchBuffer<Int>
    @usableFromInline let previousOffsets: _SearchBuffer<Int>
    @usableFromInline let previous: _SearchBuffer<Int>
    @usableFromInline let directed: Bool
    @usableFromInline let count: Int

    @inlinable
    init(_ rows: _HamiltonianRows) {
        rowOffsets = _SearchBuffer(rows.rowOffsets)
        rowTargets = _SearchBuffer(rows.rowTargets)
        rowEdges = _SearchBuffer(rows.rowEdges)
        nextOffsets = _SearchBuffer(rows.nextOffsets)
        next = _SearchBuffer(rows.next)
        directed = rows.directed
        previousOffsets = rows.directed ? _SearchBuffer(rows.previousOffsets) : nextOffsets
        previous = rows.directed ? _SearchBuffer(rows.previous) : next
        count = rows.count
    }

    @inlinable
    func deallocate() {
        for buffer in [rowOffsets, rowTargets, rowEdges, nextOffsets, next] { buffer.deallocate() }
        if directed {
            previousOffsets.deallocate()
            previous.deallocate()
        }
    }
}

/// The depth-first backtracking search for the first Hamiltonian path (or cycle) in row order:
/// from `start`, extend through each row in order to an unvisited vertex; a cycle closes through
/// the first edge of the last vertex's row back to the start that the path has not used.
///
/// Pruning only cuts subtrees that hold no solution, so the first solution found is the first in
/// search order, pruned or not. After each step, with U the unvisited vertices and x the path's
/// end: every vertex of U must be reachable from x through U, and must keep enough usable
/// neighbours. Undirected, f(u) counts u's neighbours in U ∪ {x} (∪ {start}, for a cycle): every
/// u in U needs f(u) ≥ 2, except the path's last vertex, which needs 1 (the target, or, without
/// one, at most one such vertex). Directed, u needs a predecessor in U ∪ {x}, and a successor in
/// U (∪ {start}, for a cycle) unless it is the path's last vertex. A cycle's start also needs a
/// predecessor in U while U is not empty. The degree counts are kept incrementally, O(degree) per
/// step. The reachability is a search, O(n + m), run only when it can fail: every state the search
/// stands on passed it, so before a step from p to x every vertex of U ∪ {x} was reachable from p
/// through U ∪ {x}; when x is p's only neighbour (successor) in U ∪ {x}, each of those paths
/// leaves p through x and, made simple, stays in U after it, so every vertex of U is reachable
/// from x through U and the search is skipped. On a cycle or a path graph that leaves one search
/// at the first step, so the whole search is linear. Neither runs below three vertices, where
/// parallel edges and self-loops decide.
///
/// State lives in `_SearchBuffer`s, freed by `deallocate()`.
@frozen
@usableFromInline
struct _HamiltonianSearch {
    @usableFromInline let rows: _HamiltonianRowBuffers
    @usableFromInline let n: Int
    @usableFromInline let cycle: Bool
    @usableFromInline let start: Int
    /// −1 for none.
    @usableFromInline let target: Int
    @usableFromInline let pruned: Bool

    @usableFromInline let visited: _SearchBuffer<Bool>
    /// Undirected: f. Directed: the predecessors in U ∪ {x}, and the successors in U (∪ {start}).
    @usableFromInline let free: _SearchBuffer<Int>
    @usableFromInline let freeOut: _SearchBuffer<Int>
    @usableFromInline var dead = 0
    @usableFromInline var soft = 0
    @usableFromInline var startPredecessors = 0
    @usableFromInline let isStartPredecessor: _SearchBuffer<Bool>
    @usableFromInline var unvisited: Int

    // Scratch for the reachability search.
    @usableFromInline let seen: _SearchBuffer<Int>
    @usableFromInline var stamp = 0
    @usableFromInline let stack: _SearchBuffer<Int>

    @inlinable
    init(_ rows: _HamiltonianRowBuffers, start: Int, target: Int, cycle: Bool) {
        self.rows = rows
        let n = rows.count
        self.n = n
        self.start = start
        self.target = target
        self.cycle = cycle
        pruned = n >= 3
        visited = _SearchBuffer(repeating: false, count: n)
        free = _SearchBuffer(repeating: 0, count: n)
        freeOut = _SearchBuffer(repeating: 0, count: rows.directed ? n : 0)
        isStartPredecessor = _SearchBuffer(repeating: false, count: n)
        unvisited = n - 1
        seen = _SearchBuffer(repeating: 0, count: n)
        stack = _SearchBuffer(repeating: 0, count: n)
        visited[start] = true
        guard pruned else { return }
        // x = start: undirected f(u) is every distinct neighbour; directed, every predecessor,
        // and the successors other than the start unless the start closes a cycle.
        for u in 0 ..< n where u != start {
            if rows.directed {
                free[u] = rows.previousOffsets[u + 1] - rows.previousOffsets[u]
                var out = rows.nextOffsets[u + 1] - rows.nextOffsets[u]
                if !cycle {
                    for k in rows.nextOffsets[u] ..< rows.nextOffsets[u + 1] where rows.next[k] == start { out -= 1 }
                }
                freeOut[u] = out
            } else {
                free[u] = rows.nextOffsets[u + 1] - rows.nextOffsets[u]
            }
            count(u, 1)
        }
        if cycle {
            for k in rows.previousOffsets[start] ..< rows.previousOffsets[start + 1] {
                isStartPredecessor[rows.previous[k]] = true
                startPredecessors += 1
            }
        }
    }

    @inlinable
    func deallocate() {
        for buffer in [free, freeOut, seen, stack] { buffer.deallocate() }
        visited.deallocate()
        isStartPredecessor.deallocate()
    }

    /// Adds (`sign` 1) or removes (−1) u's contribution to the dead and soft counts.
    @inlinable @inline(__always)
    mutating func count(_ u: Int, _ sign: Int) {
        let isTarget = u == target
        if rows.directed {
            if free[u] < 1 || (freeOut[u] < 1 && (cycle || (target >= 0 && !isTarget))) {
                dead += sign
            } else if freeOut[u] < 1 && !cycle && target < 0 {
                soft += sign
            }
        } else {
            let f = free[u]
            if cycle || target >= 0 {
                if f < (isTarget ? 1 : 2) { dead += sign }
            } else if f < 1 {
                dead += sign
            } else if f == 1 {
                soft += sign
            }
        }
    }

    @inlinable
    var isViable: Bool {
        dead == 0 && soft <= 1 && (!cycle || unvisited == 0 || startPredecessors > 0)
    }

    /// The path's end moves from `p` to the unvisited `y` (`sign` 1), or back (−1, the exact
    /// reverse). Moving forward, returns how many neighbours (successors) of `p` are still
    /// unvisited, or −1 when not counted (no pruning, or a cycle leaving its undirected start).
    @inlinable @discardableResult
    mutating func move(from p: Int, to y: Int, _ sign: Int) -> Int {
        if sign > 0 {
            visited[y] = true
            unvisited -= 1
            if cycle && isStartPredecessor[y] { startPredecessors -= 1 }
        }
        guard pruned else {
            if sign < 0 {
                visited[y] = false
                unvisited += 1
            }
            return -1
        }
        if sign > 0 { count(y, -1) }
        var others = -1
        if rows.directed {
            // p is no longer the end, so no longer a predecessor in U ∪ {x}; y left U, so it is
            // no longer a successor in U.
            others = 0
            for k in rows.nextOffsets[p] ..< rows.nextOffsets[p + 1] {
                let u = rows.next[k]
                if visited[u] { continue }
                others += 1
                count(u, -1)
                free[u] -= sign
                count(u, 1)
            }
            for k in rows.previousOffsets[y] ..< rows.previousOffsets[y + 1] {
                let u = rows.previous[k]
                if visited[u] { continue }
                count(u, -1)
                freeOut[u] -= sign
                count(u, 1)
            }
        } else if !(cycle && p == start) {
            others = 0
            for k in rows.nextOffsets[p] ..< rows.nextOffsets[p + 1] {
                let u = rows.next[k]
                if visited[u] { continue }
                others += 1
                count(u, -1)
                free[u] -= sign
                count(u, 1)
            }
        }
        if sign < 0 {
            count(y, 1)
            visited[y] = false
            unvisited += 1
            if cycle && isStartPredecessor[y] { startPredecessors += 1 }
        }
        return others
    }

    /// Whether every unvisited vertex is reachable from `x` through unvisited vertices. The search
    /// asks only while some vertex is unvisited (the skip rule covers the last step), but the
    /// answer for none is kept right rather than left to the caller.
    @inlinable
    mutating func reachesAll(from x: Int) -> Bool {
        guard unvisited > 0 else { return true }
        stamp += 1
        var top = 0, reached = 0
        stack[0] = x
        top = 1
        while top > 0 {
            top -= 1
            let v = stack[top]
            for k in rows.nextOffsets[v] ..< rows.nextOffsets[v + 1] {
                let w = rows.next[k]
                if visited[w] || seen[w] == stamp { continue }
                seen[w] = stamp
                reached += 1
                if reached == unvisited { return true }
                stack[top] = w
                top += 1
            }
        }
        return false
    }

    /// The first solution: the vertex numbers and the edge numbers (n − 1 for a path, n for a
    /// cycle), or nil.
    @inlinable
    mutating func run() -> (vertices: [Int], edges: [Int])? {
        let s = start
        if n == 1 {
            guard cycle else { return ([s], []) }
            for k in rows.rowOffsets[s] ..< rows.rowOffsets[s + 1] where rows.rowTargets[k] == s { return ([s], [rows.rowEdges[k]]) }
            return nil
        }
        if target == s { return nil }
        if pruned && (!isViable || !reachesAll(from: s)) { return nil }
        let path = _SearchBuffer(repeating: 0, count: n)
        let pathEdges = _SearchBuffer(repeating: 0, count: n)
        let cursor = _SearchBuffer(repeating: 0, count: n)
        // Each depth's frame number, so a parallel copy of an edge already tried from the same
        // frame is skipped: its subtree is the same.
        let frame = _SearchBuffer(repeating: 0, count: n)
        let tried = _SearchBuffer(repeating: -1, count: n)
        defer {
            for buffer in [path, pathEdges, cursor, frame, tried] { buffer.deallocate() }
        }
        var frames = 0
        path[0] = s
        cursor[0] = rows.rowOffsets[s]
        var depth = 0
        while depth >= 0 {
            let v = path[depth]
            if depth == n - 1 {
                if cycle {
                    for k in rows.rowOffsets[v] ..< rows.rowOffsets[v + 1] where rows.rowTargets[k] == s {
                        let e = rows.rowEdges[k]
                        if depth == 1 && e == pathEdges[0] { continue }
                        pathEdges[depth] = e
                        return ((0 ..< n).map { path[$0] }, (0 ..< n).map { pathEdges[$0] })
                    }
                } else {
                    // The target is entered only as the last vertex, so a full path ends there.
                    return ((0 ..< n).map { path[$0] }, (0 ..< n - 1).map { pathEdges[$0] })
                }
            } else {
                var k = cursor[depth]
                let end = rows.rowOffsets[v + 1]
                var advanced = false
                while k < end {
                    let x = rows.rowTargets[k], e = rows.rowEdges[k]
                    k += 1
                    if visited[x] || (x == target && depth + 1 != n - 1) || tried[x] == frame[depth] { continue }
                    tried[x] = frame[depth]
                    let others = move(from: v, to: x, 1)
                    if !pruned || (isViable && (others == 0 || reachesAll(from: x))) {
                        cursor[depth] = k
                        depth += 1
                        path[depth] = x
                        pathEdges[depth - 1] = e
                        cursor[depth] = rows.rowOffsets[x]
                        frames += 1
                        frame[depth] = frames
                        advanced = true
                        break
                    }
                    move(from: v, to: x, -1)
                }
                if advanced { continue }
            }
            // Backtrack.
            if depth > 0 { move(from: path[depth - 1], to: v, -1) }
            depth -= 1
        }
        return nil
    }
}

extension _HamiltonianRows {
    /// The first Hamiltonian path from each start in turn (all vertices when `start` is −1): one
    /// search per start until one succeeds, so a graph with no path costs n searches.
    @inlinable
    func path(from start: Int, to target: Int) -> (vertices: [Int], edges: [Int])? {
        let n = count
        guard n > 0 else { return nil }
        let buffers = _HamiltonianRowBuffers(self)
        defer { buffers.deallocate() }
        for s in start < 0 ? 0 ..< n : start ..< start + 1 {
            var search = _HamiltonianSearch(buffers, start: s, target: target, cycle: false)
            defer { search.deallocate() }
            if let found = search.run() { return found }
        }
        return nil
    }

    @inlinable
    func cycle() -> (vertices: [Int], edges: [Int])? {
        guard count > 0 else { return nil }
        let buffers = _HamiltonianRowBuffers(self)
        defer { buffers.deallocate() }
        var search = _HamiltonianSearch(buffers, start: 0, target: -1, cycle: true)
        defer { search.deallocate() }
        return search.run()
    }
}

// MARK: - DirectedGraph

extension DirectedGraph {
    @inlinable
    func _hamiltonianRows() -> (_HamiltonianRows, _DirectedTourRows<Self>) {
        let rows = _directedTourRows(positions: true)
        let search = _withTourRows(rows) { offsets, targets in
            _HamiltonianRows(_CompressedRows(offsets: Array(offsets), targets: Array(targets), edges: Array(0 ..< targets.count)), directed: true)
        }
        return (search, rows)
    }

    @inlinable
    func _hamiltonianPath(from start: Vertex?, to end: Vertex?) -> Path<Vertex, Edges.Index>? {
        let (search, rows) = _hamiltonianRows()
        let s = start.map { _tourNumber(of: $0, rows, "\($0) is not a vertex of the graph") } ?? -1
        let t = end.map { _tourNumber(of: $0, rows, "\($0) is not a vertex of the graph") } ?? -1
        guard let found = search.path(from: s, to: t) else { return nil }
        return Path(_uncheckedVertices: _tourVertices(found.vertices, rows), edges: _tourPositions(found.edges, rows))
    }

    /// A Hamiltonian path, or nil when there is none (or no vertex): the first one a depth-first
    /// backtracking search finds, from each vertex in `vertices` order, extending through each
    /// vertex's `outEdges` in order to an unvisited vertex (Mathematica `FindHamiltonianPath`).
    /// Self-loops never help; one vertex is the trivial path. Pruning cuts only subtrees with no
    /// solution (an unvisited vertex unreachable, or left without a usable predecessor or
    /// successor), so it keeps the order. Without a start the search is run again from each
    /// vertex in turn until one succeeds, so a graph with no Hamiltonian path costs n searches.
    ///
    /// - Complexity: exponential in the worst case (n! paths); O(degree) per step of the search,
    ///   plus O(n + m) for the reachability test where it can fail (not after a step from a
    ///   vertex with no other unvisited successor, so a path or cycle graph takes O(n + m)).
    @inlinable
    public func hamiltonianPath() -> Path<Vertex, Edges.Index>? { _hamiltonianPath(from: nil, to: nil) }

    /// The first Hamiltonian path from `start`, in the same search order.
    ///
    /// - Precondition: `start` is a vertex of the graph.
    /// - Complexity: exponential in the worst case.
    @inlinable
    public func hamiltonianPath(from start: Vertex) -> Path<Vertex, Edges.Index>? { _hamiltonianPath(from: start, to: nil) }

    /// The first Hamiltonian path from `start` that ends at `end` (Mathematica
    /// `FindHamiltonianPath[g, s, t]`); nil when `start == end` and there is more than one vertex.
    ///
    /// - Precondition: `start` and `end` are vertices of the graph.
    /// - Complexity: exponential in the worst case.
    @inlinable
    public func hamiltonianPath(from start: Vertex, to end: Vertex) -> Path<Vertex, Edges.Index>? { _hamiltonianPath(from: start, to: end) }

    /// A Hamiltonian cycle, or nil (Mathematica `FindHamiltonianCycle`): the search from the first
    /// vertex, closed by the first edge of the last vertex's row back to it. A self-loop is the
    /// cycle of a one-vertex graph and an antiparallel pair the cycle of a two-vertex one (the
    /// `Cycle` type's rules).
    ///
    /// - Complexity: exponential in the worst case.
    @inlinable
    public func hamiltonianCycle() -> Cycle<Vertex, Edges.Index>? {
        let (search, rows) = _hamiltonianRows()
        guard let found = search.cycle() else { return nil }
        return Cycle(_uncheckedVertices: _tourVertices(found.vertices, rows), edges: _tourPositions(found.edges, rows))
    }
}

// MARK: - Graph

extension Graph {
    @inlinable
    func _hamiltonianRows() -> (_HamiltonianRows, _TourNumbering<Vertex>) {
        let numbering = _tourNumbering()
        let rows = _runOnUndirectedRows(_CopyRows(readsEdges: true, dropsLoops: false), vertexNumbering: numbering.isIndexed ? nil : (numbering.listed, numbering.numbers))
        return (_HamiltonianRows(rows, directed: false), numbering)
    }

    @inlinable
    func _hamiltonianPath(from start: Vertex?, to end: Vertex?) -> Path<Vertex, Edges.Index>? {
        let (rows, numbering) = _hamiltonianRows()
        let s = start.map { _tourNumber(of: $0, numbering, "\($0) is not a vertex of the graph") } ?? -1
        let t = end.map { _tourNumber(of: $0, numbering, "\($0) is not a vertex of the graph") } ?? -1
        guard let found = rows.path(from: s, to: t) else { return nil }
        return Path(_uncheckedVertices: _tourVertices(found.vertices, numbering), edges: _tourPositions(found.edges))
    }

    /// A Hamiltonian path, or nil when there is none (or no vertex): the first one a depth-first
    /// backtracking search finds, from each vertex in `vertices` order, extending through each
    /// vertex's `incidentEdges` in order to an unvisited vertex (Mathematica
    /// `FindHamiltonianPath`). Self-loops never help; one vertex is the trivial path. Pruning cuts
    /// only subtrees with no solution (an unvisited vertex unreachable, or left with too few
    /// usable neighbours), so it keeps the order. Without a start the search is run again from
    /// each vertex in turn until one succeeds, so a graph with no Hamiltonian path costs n
    /// searches.
    ///
    /// - Complexity: exponential in the worst case (n! paths); O(degree) per step of the search,
    ///   plus O(n + m) for the reachability test where it can fail (not after a step from a
    ///   vertex with no other unvisited neighbour, so a path or cycle graph takes O(n + m)).
    @inlinable
    public func hamiltonianPath() -> Path<Vertex, Edges.Index>? { _hamiltonianPath(from: nil, to: nil) }

    /// The first Hamiltonian path from `start`, in the same search order.
    ///
    /// - Precondition: `start` is a vertex of the graph.
    /// - Complexity: exponential in the worst case.
    @inlinable
    public func hamiltonianPath(from start: Vertex) -> Path<Vertex, Edges.Index>? { _hamiltonianPath(from: start, to: nil) }

    /// The first Hamiltonian path from `start` that ends at `end` (Mathematica
    /// `FindHamiltonianPath[g, s, t]`); nil when `start == end` and there is more than one vertex.
    ///
    /// - Precondition: `start` and `end` are vertices of the graph.
    /// - Complexity: exponential in the worst case.
    @inlinable
    public func hamiltonianPath(from start: Vertex, to end: Vertex) -> Path<Vertex, Edges.Index>? { _hamiltonianPath(from: start, to: end) }

    /// A Hamiltonian cycle, or nil (Mathematica `FindHamiltonianCycle`): the search from the first
    /// vertex, closed by the first unused edge of the last vertex's row back to it. It leaves the
    /// first vertex through the lesser of its two edges in that vertex's row (the search meets
    /// that orientation first), as Cycles' canonical form does. A self-loop is the cycle of a
    /// one-vertex graph and two parallel edges the cycle of a two-vertex one (the `Cycle` type's
    /// rules).
    ///
    /// - Complexity: exponential in the worst case.
    @inlinable
    public func hamiltonianCycle() -> Cycle<Vertex, Edges.Index>? {
        let (rows, numbering) = _hamiltonianRows()
        guard let found = rows.cycle() else { return nil }
        return Cycle(_uncheckedVertices: _tourVertices(found.vertices, numbering), edges: _tourPositions(found.edges))
    }
}
