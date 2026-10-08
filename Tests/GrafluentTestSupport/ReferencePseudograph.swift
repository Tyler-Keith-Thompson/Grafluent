// A test conformer: an undirected pseudograph (self-loops and parallel edges allowed) with indexed
// adjacency and edges in written order, so the protocol's counting rules (a neighbor once per edge
// end, a self-loop twice, parallel edges told apart by position) can be tested on something other
// than the simple representations.

import GraphProtocols

/// Vertices in the order given (endpoints added in order of first appearance), edges as given,
/// repeats and self-loops included, and a list of incident edge positions per vertex: each edge's
/// position at its `u` end and then at its `v` end, so a self-loop's position is listed twice.
/// Dense vertex indices are the vertices' positions, and dense edge indices the edges'.
public struct ReferencePseudograph<Vertex: Hashable>: Graph {
    public let vertices: [Vertex]
    public let edges: [UndirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let incident: [[Int]]

    public init(edges: [UndirectedEdge<Vertex>]) {
        self.init(vertices: [], edges: edges)
    }

    public init(vertices listed: some Sequence<Vertex>, edges: [UndirectedEdge<Vertex>]) {
        var vertices: [Vertex] = []
        var index: [Vertex: Int] = [:]
        for v in Array(listed) + edges.flatMap({ [$0.u, $0.v] }) where index[v] == nil {
            index[v] = vertices.count
            vertices.append(v)
        }
        var incident = [[Int]](repeating: [], count: vertices.count)
        for (k, edge) in edges.enumerated() {
            incident[index[edge.u]!].append(k)
            incident[index[edge.v]!].append(k)
        }
        self.vertices = vertices
        self.edges = edges
        self.index = index
        self.incident = incident
    }

    public func neighbors(of vertex: Vertex) -> [Vertex] {
        // A self-loop's two entries both name the vertex itself.
        incident[index[vertex]!].map { edges[$0].oppositeVertex(to: vertex) }
    }

    public func incidentEdges(of vertex: Vertex) -> [Int] { incident[index[vertex]!] }
    public func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    public var vertexIndexBound: Int? { vertices.count }
    public func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    public func vertex(atIndex i: Int) -> Vertex { vertices[i] }
    // Dense edge indices are the positions; `incidentEdgeIndices` is the protocol's default.
    public var edgeIndexBound: Int? { edges.count }
    public func edgeIndex(of position: Int) -> Int { position }
}

extension ReferencePseudograph: Sendable where Vertex: Sendable {}
