/// Why a `Multigraph` or `DirectedMultigraph` rejected an edge.
///
/// `insert(edge:)` and `insert(checked:)` both throw this type. The graph is unchanged after
/// either case. No case carries the edge, because a graph's vertex type need not be `Sendable`.
public enum LooplessEdgeError: Error, Hashable, Sendable {
    /// The edge is a self-loop, which neither type allows.
    case selfLoop
    /// An endpoint is not a vertex. Only `insert(checked:)` throws it; `insert(edge:)` inserts the
    /// endpoint instead.
    case missingEndpoint
}
