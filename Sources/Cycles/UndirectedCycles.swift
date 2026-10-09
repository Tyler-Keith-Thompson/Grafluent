import DisjointSetModule
import GraphProtocols
import Walks

extension Graph {
    /// Whether the graph has no cycle (is a forest). A self-loop is a cycle, and so is a pair of
    /// parallel edges. The empty graph is acyclic.
    ///
    /// O(1) when `edgeCount >= vertexCount` and there is a vertex (a forest has fewer edges than
    /// vertices); otherwise a union–find over the rows, joining each edge's ends the first time
    /// a row lists it and stopping at the first edge whose ends are already joined, O(n + m α(n)).
    @inlinable
    public var isAcyclic: Bool {
        if edgeCount >= max(vertexCount, 1) { return false }
        return _runOnUndirectedRows(_UndirectedForestTest())
    }

    /// A cycle of the graph, or `nil` when it is acyclic: the one closed by the first edge a
    /// depth-first search meets that leads back to a vertex on the search path. Roots are taken
    /// in `vertices` order, each vertex's edges in `incidentEdges` order, and the search never
    /// goes back along the edge it arrived by, so a self-loop or a parallel pair is found.
    ///
    /// The cycle starts at its least vertex in `vertices` order and leaves it through the lesser
    /// of its two edges there. O(n + m); rows are read only as the search reaches them.
    @inlinable
    public func findCycle() -> Cycle<Vertex, Edges.Index>? {
        _findCycle(roots: nil)
    }

    /// A cycle reachable from `roots`, searched from each in order (skipping roots already
    /// reached), or `nil` when their components are acyclic. Otherwise as `findCycle()`.
    ///
    /// - Precondition: Every root is a vertex of the graph.
    @inlinable
    public func findCycle(from roots: some Sequence<Vertex>) -> Cycle<Vertex, Edges.Index>? {
        var numbers: [Int] = []
        if vertexIndexBound != nil {
            for root in roots {
                precondition(contains(root), "A root is not a vertex of the graph")
                numbers.append(vertexIndex(of: root))
            }
        } else {
            var byVertex: [Vertex: Int] = [:]
            byVertex.reserveCapacity(vertexCount)
            for (i, v) in vertices.enumerated() { byVertex[v] = i }
            for root in roots {
                guard let number = byVertex[root] else { preconditionFailure("A root is not a vertex of the graph") }
                numbers.append(number)
            }
        }
        return _findCycle(roots: numbers)
    }

    @inlinable
    func _findCycle(roots: [Int]?) -> Cycle<Vertex, Edges.Index>? {
        guard let (vs, es) = _runOnUndirectedRows(_FindUndirectedCycle(roots: roots)) else { return nil }
        let (vertices, edges) = _canonicalCycle(vs, es, undirected: true)
        return _cycle(vertices, edges, _listedVertices(), nil)
    }

    /// A cycle basis: the fundamental cycles of the breadth-first spanning forest, one for each
    /// edge outside the forest, in ascending position of that edge, so `edgeCount - vertexCount +
    /// c` cycles for c components. Roots are taken in `vertices` order and edges in
    /// `incidentEdges` order; a vertex's tree edge is the one that discovered it. Self-loops and
    /// parallel edges are supported: a loop is a cycle of its own, and a second copy of an edge
    /// closes a cycle of length 2.
    ///
    /// Every cycle in the basis has exactly one edge outside the forest, so the cycles are
    /// independent, and every cycle of the graph is a sum of them (mod 2). Each starts at its
    /// least vertex in `vertices` order and leaves it through the lesser of its two edges there.
    /// O(n + m) plus the total length of the cycles.
    @inlinable
    public func cycleBasis() -> [Cycle<Vertex, Edges.Index>] {
        let (rows, positions) = _cycleRows()
        let listed = _listedVertices()
        return _fundamentalCycles(rows, edgeCount: edgeCount).map { vs, es in
            let (vertices, edges) = _canonicalCycle(vs, es, undirected: true)
            return _cycle(vertices, edges, listed, positions)
        }
    }
}

/// Whether the rows describe a forest: each edge joined once, the first time a row lists it.
@frozen
@usableFromInline
struct _UndirectedForestTest: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> Bool {
        var sets = DisjointSet(count: n)
        var joined = [Bool](repeating: false, count: edgeCount)
        for v in 0 ..< n {
            for k in 0 ..< rows.count(v) {
                let e = rows.edge(v, k)
                precondition(UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "An edge index is out of range")
                if joined[e] { continue }
                joined[e] = true
                let w = rows.neighbor(v, k)
                precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                if !sets.union(v, w) { return false }
            }
        }
        return true
    }
}

/// Depth-first search for an undirected cycle: its vertex and edge numbers, uncanonical.
@frozen
@usableFromInline
struct _FindUndirectedCycle: _UndirectedRowsAlgorithm {
    @usableFromInline let roots: [Int]?

    @inlinable
    init(roots: [Int]?) {
        self.roots = roots
    }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> (vertices: [Int], edges: [Int])? {
        // The depth of each vertex on the search path, −1 before it is reached, −2 once done.
        var depth = [Int](repeating: -1, count: n)
        // The path: each vertex, the edge it was reached by, the next offset in its row, and the
        // row's length. One loop, no nested function: captured locals would be boxed, retained
        // and released on every step.
        var path: [(v: Int, edge: Int, k: Int, count: Int)] = []
        var next = 0
        while true {
            let root: Int
            if let roots {
                guard next < roots.count else { break }
                root = roots[next]
            } else {
                guard next < n else { break }
                root = next
            }
            next += 1
            guard depth[root] == -1 else { continue }
            depth[root] = 0
            path.append((root, -1, 0, rows.count(root)))
            while let (v, arrived, k, count) = path.last {
                let d = path.count - 1
                if k < count {
                    path[d].k = k + 1
                    let e = rows.edge(v, k)
                    precondition(UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "An edge index is out of range")
                    if e == arrived { continue }
                    let w = rows.neighbor(v, k)
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                    if depth[w] >= 0 {
                        let j = depth[w]
                        var edges = path[(j + 1)...].map(\.edge)
                        edges.append(e)
                        return (path[j...].map(\.v), edges)
                    }
                    // A vertex already done is never reached again: it would have met v first.
                    if depth[w] == -1 {
                        depth[w] = d + 1
                        path.append((w, e, 0, rows.count(w)))
                    }
                } else {
                    depth[v] = -2
                    path.removeLast()
                }
            }
        }
        return nil
    }
}

/// The fundamental cycles of the breadth-first forest, as vertex and edge numbers, uncanonical,
/// in ascending number of their edge outside the forest.
@inlinable
func _fundamentalCycles(_ rows: _CycleRows, edgeCount m: Int) -> [(vertices: [Int], edges: [Int])] {
    let n = rows.count
    var parent = [Int](repeating: -1, count: n)
    var parentEdge = [Int](repeating: -1, count: n)
    var depth = [Int](repeating: -1, count: n)
    var isTree = [Bool](repeating: false, count: m)
    // Each edge's two ends, from the first time a row lists it.
    var endA = [Int](repeating: -1, count: m)
    var endB = [Int](repeating: -1, count: m)
    var queue: [Int] = []
    queue.reserveCapacity(n)
    for root in 0 ..< n where depth[root] < 0 {
        depth[root] = 0
        queue.append(root)
        var head = queue.count - 1
        while head < queue.count {
            let v = queue[head]
            head += 1
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let w = rows.targets[slot], e = rows.edges[slot]
                if endA[e] < 0 {
                    endA[e] = v
                    endB[e] = w
                }
                if depth[w] < 0 {
                    depth[w] = depth[v] + 1
                    parent[w] = v
                    parentEdge[w] = e
                    isTree[e] = true
                    queue.append(w)
                }
            }
        }
    }
    var cycles: [(vertices: [Int], edges: [Int])] = []
    cycles.reserveCapacity(max(m - n, 0))
    for e in 0 ..< m where !isTree[e] {
        let a = endA[e], b = endB[e]
        if a == b {
            cycles.append(([a], [e]))
            continue
        }
        // Climb from both ends to their lowest common ancestor.
        var upA = [a], edgesA: [Int] = []
        var upB = [b], edgesB: [Int] = []
        var x = a, y = b
        while depth[x] > depth[y] {
            edgesA.append(parentEdge[x])
            x = parent[x]
            upA.append(x)
        }
        while depth[y] > depth[x] {
            edgesB.append(parentEdge[y])
            y = parent[y]
            upB.append(y)
        }
        while x != y {
            edgesA.append(parentEdge[x])
            x = parent[x]
            upA.append(x)
            edgesB.append(parentEdge[y])
            y = parent[y]
            upB.append(y)
        }
        // a … ancestor … b, then e back to a.
        var vertices = upA
        vertices.append(contentsOf: upB.dropLast().reversed())
        var edges = edgesA
        edges.append(contentsOf: edgesB.reversed())
        edges.append(e)
        cycles.append((vertices, edges))
    }
    return cycles
}
