/// The error `Multigraph.insert(edge:)` and `DirectedMultigraph.insert(edge:)` throw for a
/// self-loop, which neither type allows. JGraphT's loopless `addEdge` throws
/// `IllegalArgumentException("loops not allowed")` for the same edge. The graph is unchanged.
///
/// It carries no edge: an `Error` must be `Sendable` and a graph's vertex type needn't be, and
/// the caller already holds the edge.
public struct SelfLoopError: Error, Hashable, Sendable {
    /// The error.
    @inlinable
    public init() {}
}
