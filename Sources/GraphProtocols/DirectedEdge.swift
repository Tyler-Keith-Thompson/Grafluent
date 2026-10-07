/// An edge of a directed graph: the ordered pair (source, target), directed from `source` to `target`.
///
/// An edge whose source and target are equal is a self-loop.
@frozen
public struct DirectedEdge<Vertex: Hashable>: Hashable {
    /// The vertex the edge leaves.
    public var source: Vertex

    /// The vertex the edge enters.
    public var target: Vertex

    @inlinable
    public init(from source: Vertex, to target: Vertex) {
        self.source = source
        self.target = target
    }

    /// Whether the edge is a self-loop, from a vertex to itself.
    @inlinable
    public var isSelfLoop: Bool { source == target }
}

extension DirectedEdge: Sendable where Vertex: Sendable {}

extension DirectedEdge: Encodable where Vertex: Encodable {}

extension DirectedEdge: Decodable where Vertex: Decodable {}

extension DirectedEdge: CustomStringConvertible {
    public var description: String { "\(source)→\(target)" }
}
