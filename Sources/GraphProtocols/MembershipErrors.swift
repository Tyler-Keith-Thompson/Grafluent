/// The error a `checked:` call throws when a vertex it was given isn't in the graph. Named after
/// NetworkX's `NodeNotFound`.
///
/// It carries no vertex: an `Error` must be `Sendable` and a graph's vertex type needn't be, and
/// the caller already holds the vertex it passed. The unlabelled spelling of the same call traps
/// instead, and is the fast path inside code that has already validated its vertices; `try?` turns
/// the checked spelling into an Optional.
///
/// ```swift
/// guard let next = try? graph.successors(checked: id) else { return }
/// ```
@frozen
public struct VertexNotFound: Error, Sendable, Hashable {
    /// The error.
    @inlinable
    public init() {}
}

/// The error a `checked:` call throws when an edge position it was given doesn't name an edge in
/// the graph, because it is out of range or its edge was removed. The vertex counterpart is
/// ``VertexNotFound``.
@frozen
public struct EdgeNotFound: Error, Sendable, Hashable {
    /// The error.
    @inlinable
    public init() {}
}

/// The error a `checked:` call throws when it can fail both ways: an edge position that doesn't
/// name an edge, or a vertex that isn't in the graph. "Element" is the collective term for vertices
/// and edges, as in GraphML's graph elements and the BGL's descriptors.
///
/// The cases carry no payload, as ``VertexNotFound`` and ``EdgeNotFound`` don't, so a `catch` can
/// match a case directly and stays exhaustive:
///
/// ```swift
/// do throws(ElementNotFound) {
///     try graph.changeTarget(ofEdgeAt: position, checked: newTarget)
/// } catch .edge {
///     // The edge was removed.
/// } catch .vertex {
///     // newTarget is not a vertex.
/// }
/// ```
@frozen
public enum ElementNotFound: Error, Sendable, Hashable {
    /// A vertex it was given isn't in the graph: what ``VertexNotFound`` reports alone.
    case vertex
    /// An edge position it was given is out of range or its edge was removed: what
    /// ``EdgeNotFound`` reports alone.
    case edge
}
