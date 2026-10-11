import GraphProtocols

/// The Petersen graph's 15 edges in NetworkX's numbering, sorted: the outer pentagon 0–1–2–3–4,
/// the spokes i–(i + 5), and the inner pentagram 5–7–9–6–8. This is the generalized Petersen
/// graph GP(5, 2) in its standard numbering.
@usableFromInline
let _petersenPairs: [DirectedEdge<Int>] = [
    (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9),
    (5, 7), (5, 8), (6, 8), (6, 9), (7, 9),
].map { DirectedEdge(from: $0.0, to: $0.1) }

/// Both arcs of every Petersen edge, in row-major order.
@usableFromInline
let _petersenArcs: [DirectedEdge<Int>] = (_petersenPairs + _petersenPairs.map { DirectedEdge(from: $0.target, to: $0.source) }).sorted()

extension _GraphConstruction {
    /// The Petersen graph: 10 vertices, 15 edges, 3-regular, in NetworkX's numbering (outer
    /// pentagon 0–1–2–3–4, spokes i–(i + 5), inner pentagram 5–7–9–6–8; NetworkX
    /// `petersen_graph`, igraph `Famous("Petersen")` up to numbering). O(1).
    @inlinable
    public static func petersen() -> Self {
        Self(_vertexCount: 10, sortedEdges: _petersenPairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The Petersen graph with both arcs for every edge, 30 arcs in row-major order. O(1).
    @inlinable
    public static func petersen() -> Self {
        Self(_vertexCount: 10, sortedEdges: _petersenArcs, _ConstructionToken())
    }
}
