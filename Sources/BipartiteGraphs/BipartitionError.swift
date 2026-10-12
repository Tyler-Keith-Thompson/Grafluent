/// Why a `BipartiteGraph` rejected a mutation. The graph is unchanged after any of them.
///
/// No case carries a vertex: an `Error` must be `Sendable` and a graph's vertex type needn't be,
/// and the caller already holds the vertex or edge.
public enum BipartitionError: Error, Hashable, Sendable {
    /// Both endpoints of the edge are on this side (a self-loop included). `insert(edge:)` and
    /// `insert(checked:)` throw it.
    case sameSide(BipartiteSide)
    /// The vertex is already a vertex on this side, the other one. `insert(_:on:)` throws it.
    case onOtherSide(BipartiteSide)
    /// An endpoint of the edge is not a vertex. Only `insert(checked:)` throws it; `insert(edge:)`
    /// traps instead.
    case missingEndpoint
}
