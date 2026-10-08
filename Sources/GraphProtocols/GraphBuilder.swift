/// Builds the vertices and edges of an undirected graph from a list of statements.
///
/// Each statement is an `UndirectedEdge` or a bare vertex (which adds the vertex without any edges), and
/// `if`, `switch` and `for` work as usual:
///
/// ```swift
/// let graph = UndirectedAdjacencyList<Int> {
///     for i in 0 ..< 10 { UndirectedEdge(i, (i + 1) % 10) }
///     99
/// }
/// ```
@resultBuilder
public enum GraphBuilder<Vertex: Hashable> {
    /// The vertices and edges built so far, in the order they were written.
    public struct Content {
        public var vertices: [Vertex]
        public var edges: [UndirectedEdge<Vertex>]

        @inlinable
        public init(vertices: [Vertex] = [], edges: [UndirectedEdge<Vertex>] = []) {
            self.vertices = vertices
            self.edges = edges
        }
    }

    @inlinable
    public static func buildExpression(_ edge: UndirectedEdge<Vertex>) -> Content {
        Content(edges: [edge])
    }

    /// Disfavored so that an `UndirectedEdge` expression is read as an edge, never as a vertex whose
    /// type happens to be `UndirectedEdge`.
    @inlinable
    @_disfavoredOverload
    public static func buildExpression(_ vertex: Vertex) -> Content {
        Content(vertices: [vertex])
    }

    @inlinable
    public static func buildBlock(_ contents: Content...) -> Content {
        buildArray(contents)
    }

    @inlinable
    public static func buildArray(_ contents: [Content]) -> Content {
        var result = Content()
        for content in contents {
            result.vertices += content.vertices
            result.edges += content.edges
        }
        return result
    }

    @inlinable
    public static func buildOptional(_ content: Content?) -> Content {
        content ?? Content()
    }

    @inlinable
    public static func buildEither(first content: Content) -> Content {
        content
    }

    @inlinable
    public static func buildEither(second content: Content) -> Content {
        content
    }

    @inlinable
    public static func buildLimitedAvailability(_ content: Content) -> Content {
        content
    }
}

extension GraphBuilder.Content: Sendable where Vertex: Sendable {}
