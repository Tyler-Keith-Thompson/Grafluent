/// The textual form every representation shares, so two graphs with the same vertices and edges
/// print alike whatever their storage: `[0, 1, 2]; [0→1, 1→2]`. Elements are written as `Array`
/// writes them (with `String(reflecting:)`), and each list stops after `limit` items with `…`.
package enum GraphDescription {
    /// The most vertices or edges a description lists before eliding the rest.
    package static let limit = 16

    /// `[a, b, …]`: at most `limit` items of `items`, which has `count` items in all.
    package static func list<Items: Sequence>(_ items: Items, count: Int, _ render: (Items.Element) -> String) -> String {
        var parts = items.prefix(limit).map(render)
        if count > limit { parts.append("…") }
        return "[" + parts.joined(separator: ", ") + "]"
    }

    package static func vertex<Vertex>(_ vertex: Vertex) -> String {
        String(reflecting: vertex)
    }

    package static func edge<Vertex>(_ edge: DirectedEdge<Vertex>) -> String {
        String(reflecting: edge.source) + "→" + String(reflecting: edge.target)
    }

    package static func edge<Vertex>(_ edge: UndirectedEdge<Vertex>) -> String {
        String(reflecting: edge.u) + "–" + String(reflecting: edge.v)
    }

    /// `[vertices]; [edges]`.
    package static func graph<Vertices: Sequence, Edges: Sequence, Vertex>(
        vertices: Vertices, vertexCount: Int, edges: Edges, edgeCount: Int
    ) -> String where Vertices.Element == Vertex, Edges.Element == DirectedEdge<Vertex> {
        list(vertices, count: vertexCount) { String(reflecting: $0) } + "; " + list(edges, count: edgeCount) { GraphDescription.edge($0) }
    }

    /// `[vertices]; [edges]` for an undirected graph.
    package static func graph<Vertices: Sequence, Edges: Sequence, Vertex>(
        vertices: Vertices, vertexCount: Int, edges: Edges, edgeCount: Int
    ) -> String where Vertices.Element == Vertex, Edges.Element == UndirectedEdge<Vertex> {
        list(vertices, count: vertexCount) { String(reflecting: $0) } + "; " + list(edges, count: edgeCount) { GraphDescription.edge($0) }
    }
}
