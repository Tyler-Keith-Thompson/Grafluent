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

/// Hopcroft–Karp as NetworkX's `hopcroft_karp_matching` (the textbook procedure), iterative: each
/// phase layers the left vertices by a breadth-first search from the free ones (in `left` order),
/// then depth-first searches from each free left vertex, a row cursor per frame, descend into the
/// mate one layer deeper; a vertex whose search fails leaves the phase. Returns the matched edge
/// number per vertex.
@inlinable
package func _hopcroftKarp(_ graph: _MatchingGraph, left: [Int], isLeft: [Bool]) -> [Int] {
    let n = graph.count
    let infinity = Int.max
    var pairLeft = [Int](repeating: -1, count: n)   // by left vertex: its right mate
    var pairRight = [Int](repeating: -1, count: n)  // by right vertex: its left mate
    var mateEdge = [Int](repeating: -1, count: n)
    var layer = [Int](repeating: infinity, count: n)
    var queue = [Int](repeating: 0, count: left.count)
    var stack: [(vertex: Int, slot: Int)] = []
    for v in 0 ..< n {
        for slot in graph.offsets[v] ..< graph.offsets[v + 1] {
            precondition(isLeft[graph.targets[slot]] != isLeft[v], "An edge joins two vertices on one side: the bipartition is not this graph's")
        }
    }
    while true {
        // Breadth-first layering; `free` is the layer of the free right vertices (NetworkX's
        // dist[None]).
        var head = 0, tail = 0
        for v in left {
            if pairLeft[v] < 0 {
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
            for slot in graph.offsets[v] ..< graph.offsets[v + 1] {
                let p = pairRight[graph.targets[slot]]
                if p < 0 {
                    if free == infinity { free = layer[v] + 1 }
                } else if layer[p] == infinity {
                    layer[p] = layer[v] + 1
                    queue[tail] = p
                    tail += 1
                }
            }
        }
        guard free != infinity else { break }
        // Depth-first augmentation from each free left vertex.
        for root in left where pairLeft[root] < 0 {
            stack.removeAll(keepingCapacity: true)
            stack.append((root, graph.offsets[root]))
            var augmented = false
            while let (v, slot) = stack.last {
                if slot == graph.offsets[v + 1] {
                    layer[v] = infinity
                    stack.removeLast()
                    if let parent = stack.last { stack[stack.count - 1].slot = parent.slot + 1 }
                    continue
                }
                let p = pairRight[graph.targets[slot]]
                let next = layer[v] + 1
                if p < 0 {
                    if free == next {
                        augmented = true
                        break
                    }
                } else if layer[p] == next {
                    stack.append((p, graph.offsets[p]))
                    continue
                }
                stack[stack.count - 1].slot = slot + 1
            }
            if augmented {
                for (v, slot) in stack {
                    let u = graph.targets[slot], e = graph.edges[slot]
                    pairRight[u] = v
                    pairLeft[v] = u
                    mateEdge[v] = e
                    mateEdge[u] = e
                }
            }
        }
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

    /// A maximal matching (NetworkX `maximal_matching`): each edge in position order joins when
    /// neither end is matched yet; self-loops are skipped. Maximal, not necessarily maximum.
    /// O(n + m).
    @inlinable
    public func maximalMatching() -> Matching<Self, Int> {
        let structure = _matchingGraph()
        return _matching(structure, _maximalMatching(structure))
    }

    /// A maximum-cardinality matching by Edmonds' blossom algorithm: for each still-free vertex in
    /// vertex order, a breadth-first alternating search (rows in `incidentEdges` order) that
    /// contracts blossoms and augments along the first free vertex found, skipping the vertices of
    /// earlier failed searches. The matching returned is
    /// this procedure's, a documented function of the vertex order and rows. Parallel edges: the
    /// copy met first. Vertices of a search that fails are skipped by later searches. O(n · m · log n).
    @inlinable
    public func maximumMatching() -> Matching<Self, Int> {
        let structure = _matchingGraph()
        return _matching(structure, _edmonds(structure))
    }

    /// A maximum-cardinality matching of a bipartite graph by Hopcroft–Karp (NetworkX
    /// `hopcroft_karp_matching`, the same matching), left vertices in `bipartition.left` order.
    /// O(m √n).
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

    /// Whether `edges` (positions) is a matching (NetworkX `is_matching`): no position twice, no
    /// self-loop, no two edges sharing an end. O(n + |edges|) with edge indices, O(n + m) without.
    ///
    /// - Precondition: every element is a position of the graph's `edges`.
    @inlinable
    public func isMatching(_ edges: some Sequence<Edges.Index>) -> Bool { _matchedVertices(edges) != nil }

    /// Whether `edges` is a matching with no edge (other than a self-loop) between two free vertices
    /// (NetworkX `is_maximal_matching`). O(n + m).
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

    /// Whether `edges` is a matching that covers every vertex (NetworkX `is_perfect_matching`).
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
            let edge = self.edges[position]
            guard edge.u != edge.v else { return nil }
            let u = listed == nil ? vertexIndex(of: edge.u) : numbers[edge.u]!
            let v = listed == nil ? vertexIndex(of: edge.v) : numbers[edge.v]!
            guard !covered[u], !covered[v] else { return nil }
            covered[u] = true
            covered[v] = true
        }
        return covered
    }
}

extension BipartiteGraph {
    /// A maximum-cardinality matching by Hopcroft–Karp, left vertices in `left` order (NetworkX
    /// `hopcroft_karp_matching` on the same sides). O(m √n).
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
