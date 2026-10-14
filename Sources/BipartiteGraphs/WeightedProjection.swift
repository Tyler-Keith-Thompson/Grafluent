import AdjacencyListModule
import GraphProtocols

/// A one-mode projection of a bipartite graph with a weight on each edge: the graph that
/// `projectedGraph(onto:)` gives, at the same positions, and an edge map attached to it.
///
/// Read a weight with `graph[weights, ofEdgeAt: position]`, or pass
/// `{ projection.graph[projection.weights, ofEdgeAt: $0] }` to an algorithm. The map is the
/// graph's own, so it follows any later mutation of `graph`.
@frozen
public struct WeightedProjection<Vertex: Hashable, Weight: Sendable> {
    /// The projection.
    public var graph: UndirectedAdjacencyList<Vertex>
    /// Each edge's weight, attached to `graph`.
    public let weights: EdgeMap<Weight>

    @inlinable
    init(graph: UndirectedAdjacencyList<Vertex>, weights: EdgeMap<Weight>) {
        self.graph = graph
        self.weights = weights
    }
}

extension WeightedProjection: Sendable where Vertex: Sendable {}

extension BipartiteGraph {
    /// The projection onto `side`, each edge weighted by `weight(shared, collaboration, du, dx)`:
    /// the number of shared neighbours, the sum of 1 / (d(w) − 1) over them (only when
    /// `collaboration` is true, otherwise 0), and the two ends' degrees. Edges are inserted in
    /// `projectedGraph(onto:)`'s order: for each u in side order, the vertices after u met through
    /// u's row, in the order first met.
    @inlinable
    func _weightedProjection<W: Numeric & Sendable>(
        onto side: BipartiteSide, collaboration: Bool,
        _ weight: (_ shared: Int, _ collaboration: Double, _ uDegree: Int, _ xDegree: Int) -> W
    ) -> WeightedProjection<Vertex, W> {
        let slots = side == .left ? _left : _right
        var shared = [Int](repeating: 0, count: _side.count)
        var sums = [Double](repeating: 0, count: collaboration ? _side.count : 0)
        var touched: [Int] = []
        var result = UndirectedAdjacencyList<Vertex>()
        result.reserveCapacity(vertexCount: slots.count, edgeCount: 0)
        for u in slots { result.insert(_base.vertex(atIndex: u)) }
        var values: [W] = []
        // In `result`, side position k is slot k.
        for (k, u) in slots.enumerated() {
            let du = _base.degree(ofIndex: u)
            for w in _base.neighborIndices(ofIndex: u) {
                let dw = _base.degree(ofIndex: w)
                // Every x met here shares w with u, so d(w) ≥ 2 whenever the loop body runs.
                let share = collaboration && dw > 1 ? 1 / Double(dw &- 1) : 0
                for x in _base.neighborIndices(ofIndex: w) where x != u {
                    if shared[x] == 0 { touched.append(x) }
                    shared[x] &+= 1
                    if collaboration { sums[x] += share }
                }
            }
            for x in touched {
                let other = _sideOffset[x]
                if other > k {
                    result._insertEdge(slots: k, other)
                    values.append(weight(shared[x], collaboration ? sums[x] : 0, du, _base.degree(ofIndex: x)))
                }
                shared[x] = 0
                if collaboration { sums[x] = 0 }
            }
            touched.removeAll(keepingCapacity: true)
        }
        let map = result.addEdgeMap(default: W.zero)
        for p in values.indices { result[map, ofEdgeAt: p] = values[p] }
        return WeightedProjection(graph: result, weights: map)
    }

    /// The projection onto `side` with each edge weighted by the number of neighbours its ends
    /// share, as NetworkX's `weighted_projected_graph` makes it. The graph is
    /// `projectedGraph(onto:)`'s, at the same positions.
    ///
    /// - Parameter side: The side whose vertices are kept.
    /// - Returns: The projection and its weights.
    /// - Complexity: O(n + Σ_{u ∈ side} Σ_{w ∈ N(u)} deg(w)).
    @inlinable
    public func weightedProjectedGraph(onto side: BipartiteSide) -> WeightedProjection<Vertex, Int> {
        _weightedProjection(onto: side, collaboration: false) { shared, _, _, _ in shared }
    }

    /// The projection onto `side` with each edge weighted by how much its ends' neighbourhoods
    /// overlap, as NetworkX's `overlap_weighted_projected_graph` makes it: |N(u) ∩ N(v)| /
    /// |N(u) ∪ N(v)| (the Jaccard index), or, when `jaccard` is false, |N(u) ∩ N(v)| /
    /// min(d(u), d(v)). The graph is `projectedGraph(onto:)`'s, at the same positions.
    ///
    /// - Parameters:
    ///   - side: The side whose vertices are kept.
    ///   - jaccard: Whether to divide by the union's size rather than the lesser degree.
    /// - Returns: The projection and its weights, each in (0, 1].
    /// - Complexity: O(n + Σ_{u ∈ side} Σ_{w ∈ N(u)} deg(w)).
    @inlinable
    public func overlapWeightedProjectedGraph(onto side: BipartiteSide, jaccard: Bool = true) -> WeightedProjection<Vertex, Double> {
        _weightedProjection(onto: side, collaboration: false) { shared, _, du, dx in
            Double(shared) / Double(jaccard ? du &+ dx &- shared : Swift.min(du, dx))
        }
    }

    /// The projection onto `side` with Newman's collaboration weights, as NetworkX's
    /// `collaboration_weighted_projected_graph` makes it: the edge {u, v} weighs the sum, over
    /// the neighbours w they share, of 1 / (d(w) − 1). The sum runs over u's row in order, u being
    /// the end earlier in side order. The graph is `projectedGraph(onto:)`'s, at the same
    /// positions.
    ///
    /// - Parameter side: The side whose vertices are kept.
    /// - Returns: The projection and its weights.
    /// - Complexity: O(n + Σ_{u ∈ side} Σ_{w ∈ N(u)} deg(w)).
    @inlinable
    public func collaborationWeightedProjectedGraph(onto side: BipartiteSide) -> WeightedProjection<Vertex, Double> {
        _weightedProjection(onto: side, collaboration: true) { _, sum, _, _ in sum }
    }
}
