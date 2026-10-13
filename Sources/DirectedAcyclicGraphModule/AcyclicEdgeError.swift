/// Why a `DirectedAcyclicGraph` rejected an edge. The graph is unchanged after any of them.
///
/// No case carries a vertex, since a graph's vertex type need not be `Sendable`. The caller
/// already holds the edge. A rejection allocates nothing.
public enum AcyclicEdgeError: Error, Hashable, Sendable {
    /// The edge would close a cycle. `bidirectionalShortestPath(from: edge.target, to:
    /// edge.source)` (Traversal) is a path the edge would close.
    case cycle
    /// The edge is a self-loop, a cycle of length one.
    case selfLoop
    /// An endpoint is not a vertex. Only `insert(checked:)` throws it. `insert(edge:)` inserts the
    /// endpoint instead.
    case missingEndpoint
}
