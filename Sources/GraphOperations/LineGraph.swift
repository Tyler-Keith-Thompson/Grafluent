import GraphProtocols

/// The vertex count of a graph that a materialized operation reads in index space, which phase 1
/// requires.
@inlinable
func _requireIndices(_ bound: Int?, _ what: StaticString) -> Int {
    guard let n = bound else {
        preconditionFailure("The graph has no vertex indices (vertexIndexBound is nil); \(what) needs them in phase 1")
    }
    return n
}

/// The ordinal of every edge position: its edge index when the graph has them, or else its place
/// in `edges` through a dictionary (one hash of the position per lookup).
@frozen
@usableFromInline
struct _EdgeOrdinals<Position: Hashable> {
    @usableFromInline let positions: [Position]
    @usableFromInline let table: [Position: Int]?

    @inlinable
    init(positions: [Position], indexed: Bool) {
        self.positions = positions
        if indexed {
            table = nil
        } else {
            var table: [Position: Int] = [:]
            table.reserveCapacity(positions.count)
            for (k, p) in positions.enumerated() { table[p] = k }
            self.table = table
        }
    }
}

extension _DirectedGraphConstruction {
    /// The line graph of `graph`: a vertex for each edge, and an arc e → f whenever e's target is
    /// f's source (NetworkX's `line_graph`, igraph's `linegraph`; Harary and Norman's line
    /// digraph). Vertex `k` is the edge with edge index `k`, or the `k`th position of `edges`
    /// when the graph has no edge indices (one hash of a position per edge then). Parallel edges
    /// are distinct vertices.
    ///
    /// O(m + |E(L)| + the row sorts).
    ///
    /// - Precondition: the graph has vertex indices and no self-loop. A self-loop's line graph
    ///   has a self-loop, which the construction targets do not take (phase 1).
    @inlinable
    public static func lineGraph<G: DirectedGraph>(of graph: G) -> Self {
        _ = _requireIndices(graph.vertexIndexBound, "lineGraph(of:)")
        let indexed = graph.edgeIndexBound != nil
        let ordinals = _EdgeOrdinals(positions: Array(graph.edges.indices), indexed: indexed)
        var edges: [DirectedEdge<Int>] = []
        var row: [Int] = []
        for (k, e) in ordinals.positions.enumerated() {
            let s = graph.sourceIndex(ofEdgeAt: e), t = graph.targetIndex(ofEdgeAt: e)
            precondition(s != t, "The graph has a self-loop; its line graph would have a self-loop, which the construction targets do not take")
            row.removeAll(keepingCapacity: true)
            for f in graph.outEdges(ofIndex: t) {
                row.append(indexed ? graph.edgeIndex(of: f) : ordinals.table.unsafelyUnwrapped[f].unsafelyUnwrapped)
            }
            row.sort()
            for f in row { edges.append(DirectedEdge(from: k, to: f)) }
        }
        return Self(_vertexCount: ordinals.positions.count, sortedEdges: edges, _ConstructionToken())
    }
}

extension _GraphConstruction {
    /// The line graph of `graph`: a vertex for each edge, and an edge between two distinct edges
    /// that share an end (NetworkX's `line_graph`, igraph's `linegraph`, JGraphT's
    /// `LineGraphConverter`). Two parallel edges are joined once; a self-loop is joined to every
    /// other edge at its vertex and gets no loop. Vertex `k` is the edge with edge index `k`, or
    /// the `k`th position of `edges` when the graph has no edge indices.
    ///
    /// O(Σᵥ deg(v)² + the row sorts), with a stamp array of m entries for deduplication.
    ///
    /// - Precondition: the graph has vertex indices.
    @inlinable
    public static func lineGraph<G: Graph>(of graph: G) -> Self {
        _ = _requireIndices(graph.vertexIndexBound, "lineGraph(of:)")
        let indexed = graph.edgeIndexBound != nil
        let ordinals = _EdgeOrdinals(positions: Array(graph.edges.indices), indexed: indexed)
        let m = ordinals.positions.count
        var stamp = [Int](repeating: -1, count: m)
        var edges: [UndirectedEdge<Int>] = []
        var row: [Int] = []
        for (k, e) in ordinals.positions.enumerated() {
            let ends = graph.endpointIndices(ofEdgeAt: e)
            row.removeAll(keepingCapacity: true)
            for side in 0 ..< (ends.u == ends.v ? 1 : 2) {
                for f in graph.incidentEdges(ofIndex: side == 0 ? ends.u : ends.v) {
                    let j = indexed ? graph.edgeIndex(of: f) : ordinals.table.unsafelyUnwrapped[f].unsafelyUnwrapped
                    if j > k, stamp[j] != k {
                        stamp[j] = k
                        row.append(j)
                    }
                }
            }
            row.sort()
            for f in row { edges.append(UndirectedEdge(k, f)) }
        }
        return Self(_vertexCount: m, sortedEdges: edges, _ConstructionToken())
    }
}
