// §I: the same answers on every representation. Every test in §A – §G already runs on the
// ReferencePseudograph or ReferenceDirectedMultigraph as the catalog writes it (CY-700); this file
// adds UndirectedAdjacencyList and AdjacencyList built in written order (CY-701: rows without
// repeats, so nothing collapses and positions are the written ones), CompressedSparseRow and
// AdjacencyMatrix (CY-702: positions are the representation's own, cells on the matrix), the views
// `.undirected` (arcs as edges, rows out-edges then in-edges) and `.directed` (two arcs per edge),
// conformers private to this file without indices and with vertex indices only (CY-703), rows out
// of position order (CY-704 – CY-706), String and Collider vertices (CY-709), and adjacency lists
// after removals, whose rows are no longer in position order, against a brute force over their own
// rows written inside the test (CY-710). Expected literals come from the catalog's reference
// (`ref.py`), with rows modelled as each representation stores them. Case IDs (CY-nnn) refer to
// the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

/// An undirected pseudograph whose incidence rows are not in position order, as on an
/// `UndirectedAdjacencyList` after removals: each row is built in position order (a self-loop
/// twice), then reversed or rotated left by one (the catalog's `~rev` and `~rot`). Vertex and edge
/// indices are positions.
private struct ReorderedPseudograph<Vertex: Hashable>: Graph {
    enum Reordering { case reversed, rotated }

    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [UndirectedEdge<Vertex>], rows reordering: Reordering) {
        let inOrder = ReferencePseudograph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { v in
            let row = inOrder.incidentEdges(of: v)
            switch reordering {
            case .reversed: return Array(row.reversed())
            case .rotated: return row.isEmpty ? row : Array(row.dropFirst()) + [row[0]]
            }
        }
    }

    func incidentEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

/// A directed multigraph whose out-edge rows are not in position order: each row is built in
/// position order, then reversed or rotated left by one (the catalog's `~rev` and `~rot`). Vertex
/// indices are positions.
private struct ReorderedDirectedMultigraph<Vertex: Hashable>: DirectedGraph {
    enum Reordering { case reversed, rotated }

    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [DirectedEdge<Vertex>], rows reordering: Reordering) {
        let inOrder = ReferenceDirectedMultigraph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { v in
            let row = inOrder.outEdges(of: v)
            switch reordering {
            case .reversed: return Array(row.reversed())
            case .rotated: return row.isEmpty ? row : Array(row.dropFirst()) + [row[0]]
            }
        }
    }

    func outEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
}

/// An undirected pseudograph with no vertex or edge indices, rows in position order (a self-loop
/// twice), so the algorithms number vertices through a dictionary.
private struct PlainGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// Vertex indices (the positions in `vertices`) but no edge indices, rows in position order.
private struct VertexIndexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { vertices.firstIndex(of: vertex)! }
    func vertex(atIndex index: Int) -> Vertex { vertices[index] }
}

/// A directed multigraph with no vertex or edge indices, out-edges in position order.
private struct PlainDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}
