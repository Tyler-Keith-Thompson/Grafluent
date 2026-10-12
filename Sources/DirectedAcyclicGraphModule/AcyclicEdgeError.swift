/// Why a `DirectedAcyclicGraph` rejected an edge. Named and shaped after petgraph's
/// `AcyclicEdgeError`. The graph is unchanged after any of them.
///
/// No case carries a vertex: an `Error` must be `Sendable` and a graph's vertex type needn't be,
/// and the caller already holds the edge. A rejection allocates nothing.
public enum AcyclicEdgeError: Error, Hashable, Sendable {
    /// The edge would close a cycle. `bidirectionalShortestPath(from: edge.target, to:
    /// edge.source)` (Traversal) is a path the edge would close.
    case cycle
    /// The edge is a self-loop, a cycle of length one.
    case selfLoop
    /// An endpoint is not a vertex. Only `insert(checked:)` throws it; `insert(edge:)` inserts the
    /// endpoint instead. petgraph's `InvalidEdge`.
    case missingEndpoint
}
