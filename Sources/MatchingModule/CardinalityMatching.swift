import BipartiteGraphs
import GraphProtocols

/// Greedy: each edge in number order joins when neither end is matched; self-loops skipped.
@inlinable
package func _maximalMatching(_ graph: _MatchingGraph) -> [Int] {
    var mateEdge = [Int](repeating: -1, count: graph.count)
    for e in 0 ..< graph.edgeCount {
        let u = graph.from[e], v = graph.to[e]
        if u != v, mateEdge[u] < 0, mateEdge[v] < 0 {
            mateEdge[u] = e
            mateEdge[v] = e
        }
    }
    return mateEdge
}

/// What Hopcroft–Karp tells its caller about each phase: nothing for the plain calls, which
/// specialize the calls away, and the phases themselves for `HopcroftKarpEvents`.
@usableFromInline
package protocol _HopcroftKarpObserver {
    /// A phase's layering found shortest augmenting paths with `free` left vertices on each.
    mutating func layered(free: Int)
    /// An augmenting path found, before it is applied: `stack` holds its left vertices and the
    /// slots of the arcs it takes out of them; `mateSlot` is still the matching before it.
    mutating func augmenting(_ stack: [(vertex: Int, slot: Int)], mateSlot: [Int])
}

/// The observer of the plain calls.
@frozen
@usableFromInline
package struct _HopcroftKarpSilence: _HopcroftKarpObserver {
    @inlinable package init() {}
    @inlinable @inline(__always) package func layered(free: Int) {}
    @inlinable @inline(__always) package func augmenting(_ stack: [(vertex: Int, slot: Int)], mateSlot: [Int]) {}
}

/// Hopcroft–Karp, iterative, one phase at a time: each phase layers the left vertices by a
/// breadth-first search from the free ones (in `left` order), then depth-first searches from each
/// free left vertex, a row cursor per frame, descend into the mate one layer deeper; a vertex whose
/// search fails leaves the phase. Phases run until none augments. Row v is
/// `targets[offsets[v] ..< offsets[v + 1]]`; only targets that `accept` admits are followed (rows
/// of left vertices hold right vertices). `mateSlot[v]` is the slot of left vertex v's matched arc
/// (−1 free) and `pairRight[w]` right vertex w's mate (−1 free); the caller may seed them with any
/// matching.
@frozen
@usableFromInline
package struct _HopcroftKarpRun {
    @usableFromInline let offsets: [Int]
    @usableFromInline let targets: [Int]
    @usableFromInline let left: [Int]
    @usableFromInline package var mateSlot: [Int]
    @usableFromInline package var pairRight: [Int]
    @usableFromInline var layer: [Int]
    @usableFromInline var queue: [Int]
    @usableFromInline var stack: [(vertex: Int, slot: Int)] = []

    @inlinable
    package init(offsets: [Int], targets: [Int], left: [Int], mateSlot: [Int], pairRight: [Int]) {
        self.offsets = offsets
        self.targets = targets
        self.left = left
        self.mateSlot = mateSlot
        self.pairRight = pairRight
        layer = [Int](repeating: Int.max, count: offsets.count - 1)
        queue = [Int](repeating: 0, count: left.count)
    }

    /// One phase; false, changing nothing, when no augmenting path is left.
    @inlinable
    package mutating func phase(accept: (Int) -> Bool, observer: inout some _HopcroftKarpObserver) -> Bool {
        // The arrays move into locals for the phase, as the plain loop's locals, and back after.
        var mateSlot: [Int] = [], pairRight: [Int] = [], layer: [Int] = [], queue: [Int] = [], stack: [(vertex: Int, slot: Int)] = []
        swap(&mateSlot, &self.mateSlot)
        swap(&pairRight, &self.pairRight)
        swap(&layer, &self.layer)
        swap(&queue, &self.queue)
        swap(&stack, &self.stack)
        defer {
            swap(&mateSlot, &self.mateSlot)
            swap(&pairRight, &self.pairRight)
            swap(&layer, &self.layer)
            swap(&queue, &self.queue)
            swap(&stack, &self.stack)
        }
        let offsets = offsets, targets = targets, left = left
        let infinity = Int.max
        // Breadth-first layering; `free` is the layer of the free right vertices.
        var head = 0, tail = 0
        for v in left {
            if mateSlot[v] < 0 {
                layer[v] = 0
                queue[tail] = v
                tail += 1
            } else {
                layer[v] = infinity
            }
        }
        var free = infinity
        while head < tail {
            let v = queue[head]
            head += 1
            guard layer[v] < free else { continue }
            for slot in offsets[v] ..< offsets[v + 1] {
                let w = targets[slot]
                guard accept(w) else { continue }
                let p = pairRight[w]
                if p < 0 {
                    if free == infinity { free = layer[v] + 1 }
                } else if layer[p] == infinity {
                    layer[p] = layer[v] + 1
                    queue[tail] = p
                    tail += 1
                }
            }
        }
        guard free != infinity else { return false }
        observer.layered(free: free)
        // Depth-first augmentation from each free left vertex.
        for root in left where mateSlot[root] < 0 {
            stack.removeAll(keepingCapacity: true)
            stack.append((root, offsets[root]))
            var augmented = false
            while let (v, slot) = stack.last {
                if slot == offsets[v + 1] {
                    layer[v] = infinity
                    stack.removeLast()
                    if let parent = stack.last { stack[stack.count - 1].slot = parent.slot + 1 }
                    continue
                }
                let w = targets[slot]
                if accept(w) {
                    let p = pairRight[w]
                    let next = layer[v] + 1
                    if p < 0 {
                        if free == next {
                            augmented = true
                            break
                        }
                    } else if layer[p] == next {
                        stack.append((p, offsets[p]))
                        continue
                    }
                }
                stack[stack.count - 1].slot = slot + 1
            }
            if augmented {
                observer.augmenting(stack, mateSlot: mateSlot)
                for (v, slot) in stack {
                    pairRight[targets[slot]] = v
                    mateSlot[v] = slot
                }
            }
        }
        return true
    }
}

/// Hopcroft–Karp's phases (`_HopcroftKarpRun`) until none augments, from the matching in
/// `mateSlot` and `pairRight`, which hold the maximum matching afterwards.
@inlinable
package func _hopcroftKarpPhases(
    offsets: [Int], targets: [Int], left: [Int], mateSlot: inout [Int], pairRight: inout [Int], accept: (Int) -> Bool
) {
    var run = _HopcroftKarpRun(offsets: offsets, targets: targets, left: left, mateSlot: mateSlot, pairRight: pairRight)
    // The run holds the only reference, so its writes copy nothing.
    mateSlot = []
    pairRight = []
    var silence = _HopcroftKarpSilence()
    while run.phase(accept: accept, observer: &silence) {}
    mateSlot = run.mateSlot
    pairRight = run.pairRight
}

/// Hopcroft–Karp from the empty matching (`_hopcroftKarpPhases`). Returns the matched edge number
/// per vertex.
@inlinable
package func _hopcroftKarp(_ graph: _MatchingGraph, left: [Int], isLeft: [Bool]) -> [Int] {
    let n = graph.count
    for v in 0 ..< n {
        for slot in graph.offsets[v] ..< graph.offsets[v + 1] {
            precondition(isLeft[graph.targets[slot]] != isLeft[v], "An edge joins two vertices on one side: the bipartition is not this graph's")
        }
    }
    var mateSlot = [Int](repeating: -1, count: n)
    var pairRight = [Int](repeating: -1, count: n)
    _hopcroftKarpPhases(offsets: graph.offsets, targets: graph.targets, left: left, mateSlot: &mateSlot, pairRight: &pairRight) { _ in true }
    var mateEdge = [Int](repeating: -1, count: n)
    for v in left where mateSlot[v] >= 0 {
        let slot = mateSlot[v], e = graph.edges[slot]
        mateEdge[v] = e
        mateEdge[graph.targets[slot]] = e
    }
    return mateEdge
}

/// Edmonds' blossom algorithm (Gabow's representation, union–find bases): for each still-free
/// vertex in number order, one breadth-first alternating search, augmenting at the first free
/// vertex found. Per search, only the vertices it labels are reset. A search that fails leaves a
/// Hungarian tree whose vertices are never on a later augmenting path, so they are marked dead and
/// skipped by every later search (otherwise unmatched vertices make the algorithm quadratic).
@inlinable
package func _edmonds(_ graph: _MatchingGraph) -> [Int] {
    let n = graph.count
    var mate = [Int](repeating: -1, count: n)
    var mateEdge = [Int](repeating: -1, count: n)
    var label = [Int8](repeating: 0, count: n)  // 0 unlabeled, 1 even, 2 odd
    var link = [Int](repeating: -1, count: n)
    var linkEdge = [Int](repeating: -1, count: n)
    var base = Array(0 ..< n)
    var mark = [Int](repeating: 0, count: n)
    var markRound = 0
    var queue = [Int](repeating: 0, count: n)
    var touched: [Int] = []
    // Vertices of a failed search's tree: never on a later augmenting path (Edmonds), so later
    // searches skip them.
    var dead = [Bool](repeating: false, count: n)
    var head = 0, tail = 0

    for root in 0 ..< n where mate[root] < 0 && !dead[root] {
        for v in touched {
            label[v] = 0
            link[v] = -1
            linkEdge[v] = -1
            base[v] = v
        }
        touched.removeAll(keepingCapacity: true)
        head = 0
        tail = 0
        label[root] = 1
        touched.append(root)
        queue[tail] = root
        tail += 1
        var augmented = false
        search: while head < tail {
            let v = queue[head]
            head += 1
            for slot in graph.offsets[v] ..< graph.offsets[v + 1] {
                let w = graph.targets[slot], e = graph.edges[slot]
                if dead[w] || _find(&base, v) == _find(&base, w) || label[w] == 2 { continue }
                if label[w] == 0 {
                    link[w] = v
                    linkEdge[w] = e
                    touched.append(w)
                    if mate[w] < 0 {
                        // Augment along w, v, …, root.
                        var t = w
                        while t != -1 {
                            let p = link[t]
                            let following = mate[p]
                            mate[t] = p
                            mate[p] = t
                            mateEdge[t] = linkEdge[t]
                            mateEdge[p] = linkEdge[t]
                            t = following
                        }
                        augmented = true
                        break search
                    }
                    label[w] = 2
                    let m = mate[w]
                    label[m] = 1
                    touched.append(m)
                    queue[tail] = m
                    tail += 1
                } else {
                    // Both even: a blossom. Its base is the lowest common base of v and w.
                    markRound += 1
                    var x = v, y = w
                    var a = -1
                    while true {
                        if x != -1 {
                            x = _find(&base, x)
                            if mark[x] == markRound {
                                a = x
                                break
                            }
                            mark[x] = markRound
                            x = mate[x] == -1 ? -1 : link[mate[x]]
                        }
                        swap(&x, &y)
                    }
                    for (start, other) in [(v, w), (w, v)] {
                        var x = start, y = other, edge = e
                        while _find(&base, x) != a {
                            link[x] = y
                            linkEdge[x] = edge
                            y = mate[x]
                            if label[y] == 2 {
                                label[y] = 1
                                queue[tail] = y
                                tail += 1
                            }
                            if _find(&base, x) == x { base[x] = a }
                            if _find(&base, y) == y { base[y] = a }
                            edge = linkEdge[y]
                            x = link[y]
                        }
                    }
                }
            }
        }
        if !augmented { for v in touched { dead[v] = true } }
    }
    return mateEdge
}

/// The union–find root of `x`, with path halving.
@inlinable
package func _find(_ base: inout [Int], _ x: Int) -> Int {
    var x = x
    while base[x] != x {
        base[x] = base[base[x]]
        x = base[x]
    }
    return x
}

extension Graph {
    @inlinable
    func _matching(_ structure: _MatchingGraph, _ mateEdge: [Int]) -> Matching<Self, Int> {
        Matching(self, listed: _listedVertices(), structure: structure, mateEdge: mateEdge, weights: nil, count: { $0 })
    }

    /// A maximal matching: each edge in position order joins when neither end is matched yet;
    /// self-loops are skipped. Maximal, not necessarily maximum.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func maximalMatching() -> Matching<Self, Int> {
        let structure = _matchingGraph()
        return _matching(structure, _maximalMatching(structure))
    }

    /// A maximum-cardinality matching by Edmonds' blossom algorithm.
    ///
    /// For each still-free vertex in vertex order, a breadth-first alternating search (rows in
    /// `incidentEdges` order) contracts blossoms and augments along the first free vertex found.
    /// Vertices of a search that fails are skipped by later searches. The result is determined by
    /// the vertex order and the rows; among parallel edges, the copy met first is used.
    ///
    /// - Complexity: O(n · m · log n).
    @inlinable
    public func maximumMatching() -> Matching<Self, Int> {
        let structure = _matchingGraph()
        return _matching(structure, _edmonds(structure))
    }

    /// A maximum-cardinality matching of a bipartite graph by Hopcroft–Karp, left vertices in
    /// `bipartition.left` order.
    ///
    /// - Complexity: O(m √n).
    ///
    /// - Precondition: `bipartition` is this graph's (`bipartition()`): the same vertices, every
    ///   edge across.
    @inlinable
    public func maximumBipartiteMatching(bipartition: Bipartition<Self>) -> Matching<Self, Int> {
        let structure = _matchingGraph()
        let n = structure.count
        precondition(bipartition.left.count + bipartition.right.count == n, "The bipartition is not this graph's")
        var isLeft = [Bool](repeating: false, count: n)
        var left: [Int] = []
        for v in 0 ..< n where bipartition.side(ofIndex: v) == .left {
            isLeft[v] = true
            left.append(v)
        }
        return _matching(structure, _hopcroftKarp(structure, left: left, isLeft: isLeft))
    }

    /// Whether `edges` (positions) is a matching: no position twice, no self-loop, no two edges
    /// sharing an end.
    ///
    /// - Complexity: O(n + |edges|) with edge indices, O(n + m) without.
    ///
    /// - Precondition: every element is a position of the graph's `edges`.
    @inlinable
    public func isMatching(_ edges: some Sequence<Edges.Index>) -> Bool { _matchedVertices(edges) != nil }

    /// Whether `edges` is a matching with no edge (other than a self-loop) between two free
    /// vertices.
    ///
    /// - Complexity: O(n + m).
    ///
    /// - Precondition: every element is a position of the graph's `edges`.
    @inlinable
    public func isMaximalMatching(_ edges: some Sequence<Edges.Index>) -> Bool {
        guard let covered = _matchedVertices(edges) else { return false }
        let structure = _matchingGraph()
        for e in 0 ..< structure.edgeCount {
            let u = structure.from[e], v = structure.to[e]
            if u != v, !covered[u], !covered[v] { return false }
        }
        return true
    }

    /// Whether `edges` is a matching that covers every vertex.
    ///
    /// - Precondition: every element is a position of the graph's `edges`.
    @inlinable
    public func isPerfectMatching(_ edges: some Sequence<Edges.Index>) -> Bool {
        guard let covered = _matchedVertices(edges) else { return false }
        return !covered.contains(false)
    }

    /// The vertices `edges` covers, by number, or nil when it is not a matching.
    @inlinable
    func _matchedVertices(_ edges: some Sequence<Edges.Index>) -> [Bool]? {
        let listed = _listedVertices()
        var numbers: [Vertex: Int] = [:]
        if let listed { for (i, v) in listed.enumerated() { numbers[v] = i } }
        var covered = [Bool](repeating: false, count: vertexCount)
        // Positions by edge index when there are edge indices; otherwise hashed.
        var usedIndex = edgeIndexBound.map { [Bool](repeating: false, count: $0) } ?? []
        var used = Set<Edges.Index>()
        let valid = edgeIndexBound == nil ? Set(self.edges.indices) : []
        for position in edges {
            if let bound = edgeIndexBound {
                let k = edgeIndex(of: position)
                precondition(k >= 0 && k < bound, "\(position) is not a position of the graph's edges")
                guard !usedIndex[k] else { return nil }
                usedIndex[k] = true
            } else {
                precondition(valid.contains(position), "\(position) is not a position of the graph's edges")
                guard used.insert(position).inserted else { return nil }
            }
            let u: Int, v: Int
            if listed == nil {
                (u, v) = endpointIndices(ofEdgeAt: position)
            } else {
                let edge = self.edges[position]
                (u, v) = (numbers[edge.u]!, numbers[edge.v]!)
            }
            guard u != v, !covered[u], !covered[v] else { return nil }
            covered[u] = true
            covered[v] = true
        }
        return covered
    }
}

extension BipartiteGraph {
    /// A maximum-cardinality matching by Hopcroft–Karp, left vertices in `left` order.
    ///
    /// - Complexity: O(m √n).
    @inlinable
    public func maximumBipartiteMatching() -> Matching<Self, Int> {
        let structure = _matchingGraph()
        var isLeft = [Bool](repeating: false, count: structure.count)
        var leftNumbers: [Int] = []
        leftNumbers.reserveCapacity(left.count)
        for v in left {
            let i = vertexIndex(of: v)
            isLeft[i] = true
            leftNumbers.append(i)
        }
        return _matching(structure, _hopcroftKarp(structure, left: leftNumbers, isLeft: isLeft))
    }
}
