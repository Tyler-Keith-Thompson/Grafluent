// A test conformer: a directed multigraph with indexed adjacency and edges in written order, so
// the protocol's multigraph rules (a vertex once per edge, counts with repeats, parallel edges told apart by position) can
// be tested on something other than the simple-graph representations.

import GraphProtocols

/// Vertices in the order given (endpoints added in order of first appearance), edges as given,
/// repeats included, and out- and in-lists of edge positions per vertex. Dense vertex indices
/// are the vertices' positions.
public struct ReferenceDirectedMultigraph<Vertex: Hashable>: BidirectionalDirectedGraph {
    public let vertices: [Vertex]
    public let edges: [DirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let out: [[Int]]
    private let into: [[Int]]

    public init(edges: [DirectedEdge<Vertex>]) {
        self.init(vertices: [], edges: edges)
    }

    public init(vertices listed: some Sequence<Vertex>, edges: [DirectedEdge<Vertex>]) {
        var vertices: [Vertex] = []
        var index: [Vertex: Int] = [:]
        for v in Array(listed) + edges.flatMap({ [$0.source, $0.target] }) where index[v] == nil {
            index[v] = vertices.count
            vertices.append(v)
        }
        var out = [[Int]](repeating: [], count: vertices.count)
        var into = [[Int]](repeating: [], count: vertices.count)
        for (k, edge) in edges.enumerated() {
            out[index[edge.source]!].append(k)
            into[index[edge.target]!].append(k)
        }
        self.vertices = vertices
        self.edges = edges
        self.index = index
        self.out = out
        self.into = into
    }

    public func successors(of vertex: Vertex) -> [Vertex] { out[index[vertex]!].map { edges[$0].target } }
    public func predecessors(of vertex: Vertex) -> [Vertex] { into[index[vertex]!].map { edges[$0].source } }
    public func outEdges(of vertex: Vertex) -> [Int] { out[index[vertex]!] }
    public func inEdges(of vertex: Vertex) -> [Int] { into[index[vertex]!] }
    public func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    public var vertexIndexBound: Int? { vertices.count }
    public func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    public func vertex(atIndex i: Int) -> Vertex { vertices[i] }
}
