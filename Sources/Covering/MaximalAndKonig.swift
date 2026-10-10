import BipartiteGraphs
import GraphProtocols
import MatchingModule

/// The greedy pass straight over the rows (repeats and loops need no copy): seeds first, then each
/// vertex in number order that is not blocked and has no self-loop.
@frozen
@usableFromInline
struct _MaximalIndependentSet: _UndirectedRowsAlgorithm {
    @usableFromInline let seeded: [Bool]

    @inlinable
    init(seeded: [Bool]) { self.seeded = seeded }

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> [Bool]? {
        var inSet = [Bool](repeating: false, count: n)
        var blocked = [Bool](repeating: false, count: n)
        for pass in 0 ..< 2 {
            for v in 0 ..< n where pass == 0 ? seeded[v] : !seeded[v] {
                if pass == 1, inSet[v] || blocked[v] { continue }
                // A self-loop shows in v's own row.
                var looped = false
                for k in 0 ..< rows.count(v) where rows.neighbor(v, k) == v { looped = true }
                if pass == 0, looped || blocked[v] { return nil }
                if looped { continue }
                inSet[v] = true
                for k in 0 ..< rows.count(v) {
                    let w = rows.neighbor(v, k)
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                    blocked[w] = true
                }
            }
        }
        return inSet
    }
}

extension Graph {
    /// A maximal independent set (NetworkX `maximal_independent_set`, without the randomness): each
    /// vertex in `vertices` order joins when it has no self-loop and no neighbour in the set yet.
    /// On a graph without self-loops it is also a minimal dominating set. O(n + m).
    @inlinable
    public func maximalIndependentSet() -> [Vertex] { maximalIndependentSet(containing: EmptyCollection())! }

    /// A maximal independent set containing `seeds`, which go in first, then each vertex in
    /// `vertices` order as `maximalIndependentSet()`; nil when `seeds` is not an independent set
    /// (two are adjacent, or one has a self-loop). Repeats are one seed. O(n + m).
    ///
    /// - Precondition: every seed is a vertex of the graph.
    @inlinable
    public func maximalIndependentSet(containing seeds: some Sequence<Vertex>) -> [Vertex]? {
        let listed = _listedVertices()
        let seeded = _coveringFlags(seeds, listed)
        guard let inSet = _runOnUndirectedRows(_MaximalIndependentSet(seeded: seeded)) else { return nil }
        return _coveringVertices(flagged: inSet, listed)
    }

    /// König's minimum vertex cover of a bipartite graph (NetworkX `to_vertex_cover`, the same
    /// cover): from a maximum matching (Hopcroft–Karp on the sides), Z is the set of vertices
    /// reached from the free left vertices by alternating paths, an edge not in the matching from
    /// left to right, then the matched edge back; the cover is (left ∖ Z) ∪ (right ∩ Z), in
    /// `vertices` order. It is the one minimum cover with the most left vertices, so it does not
    /// depend on the matching. O(m √n).
    ///
    /// - Precondition: `bipartition` is this graph's (`bipartition()`).
    @inlinable
    public func minimumVertexCover(bipartition: Bipartition<Self>) -> [Vertex] {
        let structure = _matchingGraph()
        let n = structure.count
        precondition(bipartition.left.count + bipartition.right.count == n, "The bipartition is not this graph's")
        var isLeft = [Bool](repeating: false, count: n)
        var left: [Int] = []
        for v in 0 ..< n where bipartition.side(ofIndex: v) == .left {
            isLeft[v] = true
            left.append(v)
        }
        let mateEdge = _hopcroftKarp(structure, left: left, isLeft: isLeft)
        var mate = [Int](repeating: -1, count: n)
        for v in 0 ..< n where mateEdge[v] >= 0 { mate[v] = structure.opposite(v, mateEdge[v]) }
        var reached = [Bool](repeating: false, count: n)
        var queue: [Int] = []
        for v in left where mate[v] < 0 {
            reached[v] = true
            queue.append(v)
        }
        var head = 0
        while head < queue.count {
            let v = queue[head]
            head += 1
            if isLeft[v] {
                for slot in structure.offsets[v] ..< structure.offsets[v + 1] {
                    let u = structure.targets[slot]
                    if mate[v] != u, !reached[u] {
                        reached[u] = true
                        queue.append(u)
                    }
                }
            } else if mate[v] >= 0, !reached[mate[v]] {
                reached[mate[v]] = true
                queue.append(mate[v])
            }
        }
        var cover = [Bool](repeating: false, count: n)
        for v in 0 ..< n { cover[v] = isLeft[v] != reached[v] }
        return _coveringVertices(flagged: cover, _listedVertices())
    }

    /// The edge numbers (offsets in `edges`) of `positions`.
    @inlinable
    func _coveringEdgeNumbers(_ positions: some Sequence<Edges.Index>) -> [Int] {
        if let bound = edgeIndexBound {
            return positions.map { position in
                let k = edgeIndex(of: position)
                precondition(k >= 0 && k < bound, "\(position) is not a position of the graph's edges")
                return k
            }
        }
        var numbers: [Edges.Index: Int] = [:]
        numbers.reserveCapacity(edgeCount)
        for (k, position) in edges.indices.enumerated() { numbers[position] = k }
        return positions.map { position in
            guard let k = numbers[position] else { preconditionFailure("\(position) is not a position of the graph's edges") }
            return k
        }
    }

    /// A minimum edge cover (positions, ascending), or nil when some vertex has no edge: the edges of
    /// `maximumMatching()`, then for each vertex still uncovered, in vertex order, its first edge in
    /// `incidentEdges` order (a self-loop covers its vertex). n − ν edges (Gallai).
    /// O(n · m · log n).
    @inlinable
    public func minimumEdgeCover() -> [Edges.Index]? { minimumEdgeCover(matching: maximumMatching()) }

    /// The same construction from `matching` (NetworkX's `matching_algorithm`): pass
    /// `maximumBipartiteMatching()` on a bipartite graph for O(m √n) and NetworkX's
    /// `bipartite.min_edge_cover`. Minimum when `matching` is maximum; from any other matching it is
    /// still an edge cover (a vertex covered by an edge added earlier in the pass is skipped). nil
    /// when some vertex has no edge. O(n + m).
    ///
    /// - Precondition: `matching` is a matching of this graph.
    @inlinable
    public func minimumEdgeCover<W>(matching: Matching<Self, W>) -> [Edges.Index]? {
        let structure = _matchingGraph()
        let n = structure.count
        var covered = [Bool](repeating: false, count: n)
        var chosen = [Bool](repeating: false, count: structure.edgeCount)
        for e in _coveringEdgeNumbers(matching.edges) {
            chosen[e] = true
            covered[structure.from[e]] = true
            covered[structure.to[e]] = true
        }
        for v in 0 ..< n where !covered[v] {
            guard structure.offsets[v] < structure.offsets[v + 1] else { return nil }
            let e = structure.edges[structure.offsets[v]]
            chosen[e] = true
            covered[structure.from[e]] = true
            covered[structure.to[e]] = true
        }
        var numbers: [Int] = []
        for e in 0 ..< structure.edgeCount where chosen[e] { numbers.append(e) }
        return _matchingPositions(ofAscendingEdgeNumbers: numbers)
    }

    /// Whether every edge, and every self-loop, has an end in `vertices` (NetworkX
    /// `is_vertex_cover`). Repeats are ignored. O(n + m).
    ///
    /// - Precondition: every element is a vertex of the graph.
    @inlinable
    public func isVertexCover(_ vertices: some Sequence<Vertex>) -> Bool {
        let inSet = _coveringFlags(vertices, _listedVertices())
        let graph = _coveringGraph()
        for v in 0 ..< graph.count where !inSet[v] {
            if graph.hasLoop[v] { return false }
            for k in graph.offsets[v] ..< graph.offsets[v + 1] where !inSet[graph.neighbors[k]] { return false }
        }
        return true
    }

    /// Whether no edge, and no self-loop, has both ends in `vertices`. Repeats are ignored.
    /// O(n + m).
    ///
    /// - Precondition: every element is a vertex of the graph.
    @inlinable
    public func isIndependentSet(_ vertices: some Sequence<Vertex>) -> Bool {
        let inSet = _coveringFlags(vertices, _listedVertices())
        let graph = _coveringGraph()
        for v in 0 ..< graph.count where inSet[v] {
            if graph.hasLoop[v] { return false }
            for k in graph.offsets[v] ..< graph.offsets[v + 1] where inSet[graph.neighbors[k]] { return false }
        }
        return true
    }

    /// Whether every vertex is in `vertices` or adjacent to one in it (NetworkX
    /// `is_dominating_set`). Repeats are ignored. O(n + m).
    ///
    /// - Precondition: every element is a vertex of the graph.
    @inlinable
    public func isDominatingSet(_ vertices: some Sequence<Vertex>) -> Bool {
        let inSet = _coveringFlags(vertices, _listedVertices())
        let graph = _coveringGraph()
        var dominated = inSet
        for v in 0 ..< graph.count where inSet[v] {
            for k in graph.offsets[v] ..< graph.offsets[v + 1] { dominated[graph.neighbors[k]] = true }
        }
        return !dominated.contains(false)
    }

    /// Whether every vertex is an end of some edge in `edges` (positions; NetworkX `is_edge_cover`).
    /// Repeats are ignored. O(n + m).
    ///
    /// - Precondition: every element is a position of the graph's `edges`.
    @inlinable
    public func isEdgeCover(_ edges: some Sequence<Edges.Index>) -> Bool {
        let structure = _matchingGraph()
        var covered = [Bool](repeating: false, count: structure.count)
        for e in _coveringEdgeNumbers(edges) {
            covered[structure.from[e]] = true
            covered[structure.to[e]] = true
        }
        return !covered.contains(false)
    }
}
