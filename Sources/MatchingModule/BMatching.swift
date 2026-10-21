import BipartiteGraphs
import Flows
import GraphProtocols
import Multigraphs

/// A b-matching in a bipartite graph: edges, each taken at most once, meeting every vertex `v`
/// at most `b(v)` times, as positions in the graph's `edges`, with the sum of their weights. Never
/// contains a self-loop.
///
/// It keeps a copy of the graph to look vertices up. While the result is alive, the next mutation
/// of the original copies the graph. The positions are the graph's, valid until it is mutated.
@frozen
public struct BMatching<G: Graph, Weight: Comparable & AdditiveArithmetic> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    /// Each vertex's matched edges, as offsets into `edges`, in compressed rows by vertex number.
    @usableFromInline let _offsets: [Int]
    @usableFromInline let _slots: [Int]
    /// The matched edges, ascending (in `edges` order).
    public let edges: [G.Edges.Index]
    /// The sum of the matched edges' weights, in `edges` order.
    public let weight: Weight

    /// A b-matching from the matched edge numbers (ascending), their ends and the weights by
    /// edge number.
    @inlinable
    init(_ graph: G, listed: [G.Vertex]?, structure: _MatchingGraph, matched: [Int], weights: [Weight]) {
        let n = structure.count
        var offsets = [Int](repeating: 0, count: n + 1)
        for e in matched {
            offsets[structure.from[e] + 1] += 1
            offsets[structure.to[e] + 1] += 1
        }
        for v in 0 ..< n { offsets[v + 1] += offsets[v] }
        var fill = offsets
        var slots = [Int](repeating: 0, count: 2 * matched.count)
        var total = Weight.zero
        for (k, e) in matched.enumerated() {
            slots[fill[structure.from[e]]] = k
            fill[structure.from[e]] += 1
            slots[fill[structure.to[e]]] = k
            fill[structure.to[e]] += 1
            total += weights[e]
        }
        _graph = graph
        if let listed {
            var table: [G.Vertex: Int] = [:]
            table.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { table[v] = i }
            _numbers = table
        } else {
            _numbers = nil
        }
        _offsets = offsets
        _slots = slots
        edges = graph._positions(ofAscendingEdgeNumbers: matched)
        weight = total
    }

    @inlinable
    func _number(of vertex: G.Vertex) -> Int {
        if let numbers = _numbers {
            guard let v = numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return v
        }
        return _graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph")
    }

    @inlinable
    func _checkedNumber(of vertex: G.Vertex) throws(VertexNotFound) -> Int {
        if let numbers = _numbers {
            guard let v = numbers[vertex] else { throw VertexNotFound() }
            return v
        }
        guard _graph.contains(vertex) else { throw VertexNotFound() }
        return _graph.vertexIndex(of: vertex)
    }

    /// The number of matched edges at `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func degree(of vertex: G.Vertex) -> Int {
        let v = _number(of: vertex)
        return _offsets[v + 1] - _offsets[v]
    }

    /// The matched edges at `vertex`, ascending.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func matchedEdges(of vertex: G.Vertex) -> [G.Edges.Index] {
        let v = _number(of: vertex)
        return _slots[_offsets[v] ..< _offsets[v + 1]].map { edges[$0] }
    }

    /// `degree(of:)`, throwing `VertexNotFound` instead of trapping.
    @inlinable
    public func degree(checked vertex: G.Vertex) throws(VertexNotFound) -> Int {
        let v = try _checkedNumber(of: vertex)
        return _offsets[v + 1] - _offsets[v]
    }

    /// `matchedEdges(of:)`, throwing `VertexNotFound` instead of trapping.
    @inlinable
    public func matchedEdges(checked vertex: G.Vertex) throws(VertexNotFound) -> [G.Edges.Index] {
        let v = try _checkedNumber(of: vertex)
        return _slots[_offsets[v] ..< _offsets[v + 1]].map { edges[$0] }
    }
}

extension BMatching: Equatable where G.Edges.Index: Equatable {
    @inlinable
    public static func == (lhs: BMatching, rhs: BMatching) -> Bool { lhs.edges == rhs.edges }
}

extension BMatching: Hashable where G.Edges.Index: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) { hasher.combine(edges) }
}

extension BMatching: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, Weight: Sendable {}

extension Graph {
    /// The maximum-weight b-matching of a bipartite graph: the edges of greatest total weight,
    /// each taken at most once, meeting each vertex `v` at most `capacity(v)` times.
    ///
    /// A minimum-cost circulation (the network simplex): a source feeds each left vertex up to its
    /// capacity, each edge of positive weight carries one unit at the cost of minus its weight,
    /// each right vertex drains into a sink up to its capacity, and the sink returns to the
    /// source. Edges of weight zero or less are never taken. Parallel edges are distinct and may
    /// both be taken. Which optimum is returned when several exist is
    /// unspecified, but the same input always gives the same result. `capacity` is called once
    /// per vertex in `vertices` order and `weight` once per edge in position order.
    ///
    /// - Parameters:
    ///   - bipartition: The graph's two sides.
    ///   - capacity: How many matched edges each vertex may have, at least zero.
    ///   - weight: Each edge's weight by position.
    /// - Complexity: that of the network simplex on n + 2 vertices and n + m + 1 arcs; polynomial
    ///   in practice, O(n² m) in the worst case of its pivots.
    /// - Precondition: `bipartition` is this graph's; every capacity is at least zero and the
    ///   capacities fit in `Int`; |weight| fits the network simplex's cost bound (4(n + 3)(the
    ///   greatest weight + 1) fits in `Int`).
    @inlinable
    public func maximumWeightBMatching<W: SignedInteger>(
        bipartition: Bipartition<Self>, capacity: (Vertex) -> Int, weight: (Edges.Index) -> W
    ) -> BMatching<Self, W> {
        let structure = _matchingGraph()
        let n = structure.count
        precondition(bipartition.left.count + bipartition.right.count == n, "The bipartition is not this graph's")
        var isLeft = [Bool](repeating: false, count: n)
        for v in 0 ..< n where bipartition.side(ofIndex: v) == .left { isLeft[v] = true }
        return _maximumWeightBMatching(structure, isLeft: isLeft, capacity: capacity, weight: weight)
    }

    @inlinable
    func _maximumWeightBMatching<W: SignedInteger>(
        _ structure: _MatchingGraph, isLeft: [Bool], capacity: (Vertex) -> Int, weight: (Edges.Index) -> W
    ) -> BMatching<Self, W> {
        let n = structure.count
        let listed = _listedVertices()
        var capacities: [Int] = []
        capacities.reserveCapacity(n)
        for v in 0 ..< n {
            let b = capacity(listed?[v] ?? vertex(atIndex: v))
            precondition(b >= 0, "A capacity is negative")
            capacities.append(b)
        }
        let weights = _matchingWeights(structure, weight, { _ in true }, "")
        // The network: 0..<n the vertices, n the source, n + 1 the sink; arc k < m is edge k
        // (left to right), then the source and sink arcs, then the return arc.
        let source = n, sink = n + 1
        var arcs: [DirectedEdge<Int>] = []
        var arcCapacity: [Int] = [], arcCost: [Int] = []
        var arcEdge: [Int] = []
        for e in 0 ..< structure.edgeCount {
            let u = structure.from[e], v = structure.to[e]
            // A bipartite graph has no self-loops; an edge of weight zero or less never helps.
            guard weights[e] > 0, let w = Int(exactly: weights[e]) else { continue }
            let (l, r) = isLeft[u] ? (u, v) : (v, u)
            precondition(isLeft[l] != isLeft[r], "An edge joins two vertices of one side")
            arcs.append(DirectedEdge(from: l, to: r))
            arcCapacity.append(1)
            arcCost.append(-w)
            arcEdge.append(e)
        }
        let edgeArcs = arcs.count
        var total = 0
        for v in 0 ..< n where capacities[v] > 0 {
            arcs.append(isLeft[v] ? DirectedEdge(from: source, to: v) : DirectedEdge(from: v, to: sink))
            arcCapacity.append(capacities[v])
            arcCost.append(0)
            let (sum, overflow) = total.addingReportingOverflow(capacities[v])
            precondition(!overflow, "The capacities overflow")
            total = sum
        }
        arcs.append(DirectedEdge(from: sink, to: source))
        arcCapacity.append(total)
        arcCost.append(0)
        let network = DirectedPseudograph<Int>(vertices: 0 ..< n + 2, edges: arcs)
        guard let flow = network.minimumCostFlow(supply: { _ in 0 }, capacity: { arcCapacity[$0] }, cost: { arcCost[$0] }) else {
            preconditionFailure("A circulation always exists")
        }
        // The edge arcs were laid down in edge order, so the matched edges come out ascending.
        var matched: [Int] = []
        for k in 0 ..< edgeArcs where flow.flow(ofEdgeAt: k) > 0 { matched.append(arcEdge[k]) }
        return BMatching(self, listed: listed, structure: structure, matched: matched, weights: weights)
    }
}

extension BipartiteGraph {
    /// The maximum-weight b-matching, as `Graph`'s with this graph's sides.
    ///
    /// - Precondition: every capacity is at least zero; |weight| fits the network simplex's cost
    ///   bound.
    @inlinable
    public func maximumWeightBMatching<W: SignedInteger>(capacity: (Vertex) -> Int, weight: (Int) -> W) -> BMatching<Self, W> {
        let structure = _matchingGraph()
        var isLeft = [Bool](repeating: false, count: structure.count)
        for v in left { isLeft[vertexIndex(of: v)] = true }
        return _maximumWeightBMatching(structure, isLeft: isLeft, capacity: capacity, weight: weight)
    }
}
