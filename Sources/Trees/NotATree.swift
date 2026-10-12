/// The error a checked conversion throws when its input is not one tree: a shortest-path forest
/// grown from several sources, given to `Arborescence(checked:)`. Named after
/// NetworkX's `NotATree`.
///
/// It carries nothing, as `VertexNotFound` doesn't: an `Error` must be `Sendable` and a graph's
/// vertex type needn't be, and the caller already holds the input. The unlabelled conversion
/// traps instead; `try?` turns the checked one into an Optional.
///
/// ```swift
/// guard let tree = try? Arborescence(checked: graph.shortestPaths(from: sources)) else { return }
/// ```
@frozen
public struct NotATree: Error, Sendable, Hashable {
    /// The error.
    @inlinable
    public init() {}
}
