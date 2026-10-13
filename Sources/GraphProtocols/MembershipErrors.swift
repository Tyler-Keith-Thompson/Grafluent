/// The error a `checked:` call throws when a vertex it was given isn't in the graph.
///
/// It carries no vertex, because an `Error` must be `Sendable` and a graph's vertex type need not
/// be. The caller already holds the vertex it passed. The unlabeled spelling of the same call
/// traps instead, and is the fast path for code that has already validated its vertices. `try?`
/// turns the checked spelling into an optional.
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
/// name an edge, or a vertex that isn't in the graph.
///
/// Like ``VertexNotFound`` and ``EdgeNotFound``, the cases carry no payload, so a `catch` can
/// match a case directly and stay exhaustive:
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
    /// A vertex it was given isn't in the graph, as ``VertexNotFound`` reports alone.
    case vertex
    /// An edge position it was given is out of range or its edge was removed, as
    /// ``EdgeNotFound`` reports alone.
    case edge
}
