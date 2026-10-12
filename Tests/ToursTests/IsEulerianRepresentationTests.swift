// The catalog's rows again on other representations: directed rows on `DirectedPseudograph` (or
// `ReferenceDirectedMultigraph` for rows already on it), a file-private conformer with no vertex or
// edge indices, and, without a repeated edge, `CompressedSparseRow` and `AdjacencyMatrix` on the
// vertex indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and,
// without a repeated edge, `AdjacencyList.undirectedView` (each edge an arc as written; a vertex's
// row its out-edges, then its in-edges) and `AdjacencyMatrix.undirectedView` (rows by neighbour).
// CompressedSparseRow and AdjacencyMatrix number edges by row-major cell, so there each catalog
// edge's position is looked up. The walks follow each vertex's row, and Christofides' ties follow
// positions: where ref.py's models, run by swiftgen.py on the representation's rows and positions,
// give the catalog's result, it is pinned exactly; otherwise (a comment says so) the result is
// checked as genuine, with the documented start, and existing exactly when the catalog's does. See
// README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing
import Tours

/// A directed graph with no vertex or edge indices: only the protocol's vertex-level members. Out-rows
/// are in position order; parallel edges and self-loops are kept.
private struct UnindexedDirectedGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]

    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
}

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members. Rows
/// are in position order, a self-loop's position twice; parallel edges are kept.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("isEulerian on every representation")
struct IsEulerianRepresentationTests {
    @Test("TO-001 empty graph, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to001() {
        // V []; E []; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-005 one vertex, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to005() {
        // V [0]; E []; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-009 two isolated vertices (isolated vertices ignored), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to009() {
        // V [0, 1]; E []; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = []
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-013 one self-loop, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to013() {
        // multigraph V [0]; E [0-0]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-017 two self-loops at one vertex, on ReferencePseudograph, no indices")
    func to017() {
        // multigraph V [0]; E [0-0, 0-0]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-021 self-loop beside an isolated vertex, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to021() {
        // multigraph V [0, 1]; E [1-1]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(1, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-025 self-loops at two vertices: two components with edges, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to025() {
        // multigraph V [0, 1]; E [0-0, 1-1]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-029 one edge: a trail, no circuit, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to029() {
        // V [0, 1]; E [0-1]; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-033 two parallel edges: a circuit of length 2, on ReferencePseudograph, no indices")
    func to033() {
        // multigraph V [0, 1]; E [0-1, 0-1]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-037 three parallel edges: odd at both ends, on ReferencePseudograph, no indices")
    func to037() {
        // multigraph V [0, 1]; E [0-1, 1-0, 0-1]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-041 path P(3), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to041() {
        // P(3); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-045 path P(4), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to045() {
        // P(4); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-049 triangle C(3), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to049() {
        // C(3); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-053 cycle C(5), on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to053() {
        // C(5); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-057 triangle beside an isolated vertex, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to057() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-061 isolated first vertex: the circuit starts at the first vertex with an edge, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to061() {
        // V [0, 1, 2, 3]; E [1-2, 2-3, 3-1]; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-065 two triangles apart, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to065() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3]; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-069 bowtie: two triangles at a shared vertex, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to069() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-073 triangle with a loop: loops add 2, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to073() {
        // multigraph V [0, 1, 2]; E [0-1, 0-0, 1-2, 2-0]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-077 edge with a loop at the end: odd 0 and 1, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to077() {
        // multigraph V [0, 1]; E [0-1, 1-1]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-081 loop at a vertex, an edge elsewhere: two components, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to081() {
        // multigraph V [0, 1, 2]; E [0-0, 1-2]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-085 star(3): four odd vertices, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to085() {
        // V [0, 1, 2, 3]; E [0-1, 0-2, 0-3]; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-089 K(4): every degree 3, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to089() {
        // K(4); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-093 K(5): every degree 4, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to093() {
        // K(5); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-097 Königsberg: seven bridges, four odd land masses, on ReferencePseudograph, no indices")
    func to097() {
        // multigraph V [A, B, C, D]; E [A-B, A-B, A-C, A-C, A-D, B-D, C-D]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = ReferencePseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(String, String)] = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = UnindexedGraph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-101 Königsberg less one A–B bridge: a trail, on ReferencePseudograph, no indices")
    func to101() {
        // multigraph V [A, B, C, D]; E [A-B, A-C, A-C, A-D, B-D, C-D]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = ReferencePseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
            let graph = UnindexedGraph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["A", "B", "C", "D"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-105 house: odd at the base, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to105() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-0, 2-4, 4-3]; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-109 vertex order, not label order, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to109() {
        // V [d, a, c, b]; E [a-c, c-b, b-a, d-a, d-c]; isEulerian
        do { // Pseudograph
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
            let graph = Pseudograph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
            let graph = UnindexedGraph<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
            let graph = AdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == ["d", "a", "c", "b"] as [String])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1), (0, 1), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-113 odd vertices last in the order, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to113() {
        // V [0, 1, 2, 3, 4]; E [4-3, 3-0, 0-1, 1-2, 2-0, 0-4, 4-1]; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-117 grid(3,3): four odd corners' neighbours, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to117() {
        // grid(3,3); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-121 Petersen: every degree 3, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to121() {
        // nx(petersen_graph); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-125 octahedral: every degree 4, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to125() {
        // nx(octahedral_graph); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-129 wheel(4): rim odd, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to129() {
        // wheel(4); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-133 K(3,3) less nothing: degree 3, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to133() {
        // Kb(3,3); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-137 Kb(2,4): even sides, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to137() {
        // Kb(2,4); isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-141 rows decide: the first edge out of 0 is the second chord, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func to141() {
        // V [0, 1, 2, 3, 4]; E [0-3, 0-1, 1-2, 2-0, 3-4, 4-0]; isEulerian
        do { // Pseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyList.undirectedView
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-145 parallel edges inside a longer circuit, on ReferencePseudograph, no indices")
    func to145() {
        // multigraph V [0, 1, 2]; E [0-1, 1-2, 1-2, 1-2, 2-0, 1-1]; isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 2), (1, 2), (2, 0), (1, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 2), (1, 2), (2, 0), (1, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-149 lcgwalk(6,14,1), on ReferencePseudograph, no indices")
    func to149() {
        // lcgwalk(6,14,1); isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-153 lcgwalk(8,30,2), on ReferencePseudograph, no indices")
    func to153() {
        // lcgwalk(8,30,2); isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-157 lcgwalk(5,20,3,open), on ReferencePseudograph, no indices")
    func to157() {
        // lcgwalk(5,20,3,open); isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-161 lcgwalk(10,40,4,open), on ReferencePseudograph, no indices")
    func to161() {
        // lcgwalk(10,40,4,open); isEulerian
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 6), (6, 2), (2, 4), (4, 1), (1, 5), (5, 7), (7, 1), (1, 3), (3, 4), (4, 6), (6, 5), (5, 4), (4, 6), (6, 4), (4, 1), (1, 7), (7, 4), (4, 7), (7, 8), (8, 8), (8, 8), (8, 5), (5, 0), (0, 8), (8, 7), (7, 6), (6, 6), (6, 3), (3, 7), (7, 0), (0, 9), (9, 8), (8, 9), (9, 0), (0, 0), (0, 5), (5, 3), (3, 2), (2, 8), (8, 4)]
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 6), (6, 2), (2, 4), (4, 1), (1, 5), (5, 7), (7, 1), (1, 3), (3, 4), (4, 6), (6, 5), (5, 4), (4, 6), (6, 4), (4, 1), (1, 7), (7, 4), (4, 7), (7, 8), (8, 8), (8, 8), (8, 5), (5, 0), (0, 8), (8, 7), (7, 6), (6, 6), (6, 3), (3, 7), (7, 0), (0, 9), (9, 8), (8, 9), (9, 0), (0, 0), (0, 5), (5, 3), (3, 2), (2, 8), (8, 4)]
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-165 empty digraph, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to165() {
        // V []; E []; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = []
            let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedDirectedGraph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let graph = CompressedSparseRow(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-169 one vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to169() {
        // V [0]; E []; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = []
            let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = []
            let graph = UnindexedDirectedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let graph = CompressedSparseRow(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-173 one self-loop: in 1, out 1, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to173() {
        // multigraph V [0]; E [0→0]; isEulerian
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = CompressedSparseRow(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-177 one edge 0→1, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to177() {
        // V [0, 1]; E [0→1]; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-181 antiparallel pair, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to181() {
        // V [0, 1]; E [0→1, 1→0]; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-185 parallel pair 0→1 twice: unbalanced by 2, on ReferenceDirectedMultigraph, no indices")
    func to185() {
        // multigraph V [0, 1]; E [0→1, 0→1]; isEulerian
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-189 directed cycle Cd(3), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to189() {
        // Cd(3); isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-193 directed path Pd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to193() {
        // Pd(4); isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-197 two sources: no trail, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to197() {
        // V [0, 1, 2]; E [0→2, 1→2]; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-201 balanced but two components, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to201() {
        // V [0, 1, 2, 3]; E [0→1, 1→0, 2→3, 3→2]; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-205 Cd(3) beside an isolated vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to205() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0]; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-209 isolated first vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to209() {
        // V [0, 1, 2, 3]; E [1→2, 2→3, 3→1]; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-213 start is the vertex with out − in = 1, not the first, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to213() {
        // V [0, 1, 2, 3]; E [1→2, 2→0, 0→1, 2→3, 3→1, 1→3]; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-217 two directed cycles at a shared vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to217() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→0, 0→3, 3→4, 4→0]; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-221 loop on a directed cycle, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to221() {
        // multigraph V [0, 1, 2]; E [0→1, 1→1, 1→2, 2→0]; isEulerian
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-225 Cd(3) with a chord: a trail from 0, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to225() {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2]; isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-229 in − out = 2 at one vertex, on ReferenceDirectedMultigraph, no indices")
    func to229() {
        // multigraph V [0, 1, 2]; E [0→2, 1→2, 2→1, 1→0, 0→2]; isEulerian
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-233 Kd(3): every in = out = 2, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to233() {
        // Kd(3); isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-237 Kd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to237() {
        // Kd(4); isEulerian
        do { // DirectedPseudograph
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-241 self-loop and an edge elsewhere, on ReferenceDirectedMultigraph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func to241() {
        // multigraph V [0, 1, 2]; E [0→0, 1→2]; isEulerian
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2] as [Int])
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-245 lcgwalkd(6,14,1), on ReferenceDirectedMultigraph, no indices")
    func to245() {
        // lcgwalkd(6,14,1); isEulerian
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-249 lcgwalkd(8,30,2), on ReferenceDirectedMultigraph, no indices")
    func to249() {
        // lcgwalkd(8,30,2); isEulerian
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == true)
        }
    }

    @Test("TO-253 lcgwalkd(5,20,3,open), on ReferenceDirectedMultigraph, no indices")
    func to253() {
        // lcgwalkd(5,20,3,open); isEulerian
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }

    @Test("TO-257 lcgwalkd(9,40,5,open), on ReferenceDirectedMultigraph, no indices")
    func to257() {
        // lcgwalkd(9,40,5,open); isEulerian
        do { // ReferenceDirectedMultigraph
            let pairs: [(Int, Int)] = [(0, 7), (7, 8), (8, 7), (7, 1), (1, 4), (4, 5), (5, 8), (8, 7), (7, 5), (5, 6), (6, 3), (3, 6), (6, 6), (6, 2), (2, 3), (3, 5), (5, 2), (2, 3), (3, 1), (1, 3), (3, 4), (4, 1), (1, 3), (3, 3), (3, 0), (0, 5), (5, 1), (1, 0), (0, 5), (5, 4), (4, 5), (5, 4), (4, 8), (8, 3), (3, 4), (4, 2), (2, 6), (6, 6), (6, 8), (8, 5)]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
        do { // no indices
            let pairs: [(Int, Int)] = [(0, 7), (7, 8), (8, 7), (7, 1), (1, 4), (4, 5), (5, 8), (8, 7), (7, 5), (5, 6), (6, 3), (3, 6), (6, 6), (6, 2), (2, 3), (3, 5), (5, 2), (2, 3), (3, 1), (1, 3), (3, 4), (4, 1), (1, 3), (3, 3), (3, 0), (0, 5), (5, 1), (1, 0), (0, 5), (5, 4), (4, 5), (5, 4), (4, 8), (8, 3), (3, 4), (4, 2), (2, 6), (6, 6), (6, 8), (8, 5)]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = Array(graph.vertices)
            #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
            // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
            #expect(graph.isEulerian == false)
        }
    }
}
