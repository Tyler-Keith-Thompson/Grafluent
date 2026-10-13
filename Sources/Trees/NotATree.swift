/// The error a checked conversion throws when its input is not one tree, such as a shortest-path
/// forest grown from several sources given to `Arborescence(checked:)`.
///
/// It carries no payload, because an `Error` must be `Sendable` and a vertex type need not be.
/// The unlabelled conversion traps instead.
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
