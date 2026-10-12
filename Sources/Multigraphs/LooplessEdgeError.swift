/// Why a `Multigraph` or `DirectedMultigraph` rejected an edge. Shaped after `AcyclicEdgeError`:
/// `insert(edge:)` and `insert(checked:)` throw the one type, so a `catch` of either is exhaustive.
/// JGraphT's loopless `addEdge` throws `IllegalArgumentException("loops not allowed")` for a
/// self-loop. The graph is unchanged after either case.
///
/// No case carries an edge: an `Error` must be `Sendable` and a graph's vertex type needn't be,
/// and the caller already holds the edge.
public enum LooplessEdgeError: Error, Hashable, Sendable {
    /// The edge is a self-loop, which neither type allows.
    case selfLoop
    /// An endpoint is not a vertex. Only `insert(checked:)` throws it; `insert(edge:)` inserts the
    /// endpoint instead.
    case missingEndpoint
}
