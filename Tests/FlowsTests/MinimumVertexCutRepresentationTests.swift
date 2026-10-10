// The catalog's rows again on other representations: directed rows on `DirectedPseudograph` (or
// `ReferenceDirectedMultigraph` for rows already on it), a file-private conformer with no vertex or
// edge indices, and, without a repeated edge, `CompressedSparseRow` and `AdjacencyMatrix` on the
// vertex indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and,
// without a repeated edge, `AdjacencyList.undirected` (each edge an arc as written) and
// `AdjacencyMatrix.undirected`. CompressedSparseRow and AdjacencyMatrix number edges by row-major
// cell, so there each catalog edge's position is looked up, a cut's edges are listed in that order,
// and Edmonds–Karp's flow (which follows positions) was recomputed by swiftgen.py with ref.py's
// model on those positions. Everything else is the catalog's. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Flows
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

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

@Suite("minimumVertexCut on every representation")
struct MinimumVertexCutRepresentationTests {
    @Test("FL-321 empty graph, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl321() {
        // undirected V []; E []; minimumVertexCut()
        let pairs: [(Int, Int)] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
    }

    @Test("FL-324 one vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl324() {
        // undirected V [0]; E []; minimumVertexCut()
        let pairs: [(Int, Int)] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
    }

    @Test("FL-327 two isolated vertices, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl327() {
        // undirected V [0, 1]; E []; minimumVertexCut()
        let pairs: [(Int, Int)] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
    }

    @Test("FL-330 two isolated vertices, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl330() {
        // undirected V [0, 1]; E []; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 1) == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 1) == [] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 1) == [] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 1) == [] as [Int])
        }
    }

    @Test("FL-333 K(2): κ = n − 1: all but the first vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl333() {
        // K(2); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
    }

    @Test("FL-336 K(2): κ = n − 1: all but the first vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl336() {
        // K(2); minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
    }

    @Test("FL-339 K(2) with parallel edges: λ counts copies, κ does not, on ReferencePseudograph, no indices")
    func fl339() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
    }

    @Test("FL-342 K(2) with parallel edges: λ counts copies, κ does not, on ReferencePseudograph, no indices")
    func fl342() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
    }

    @Test("FL-345 self-loops ignored, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl345() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
    }

    @Test("FL-348 self-loops ignored, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl348() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; minimumVertexCut(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1] as [Int])
        }
    }

    @Test("FL-351 path P(4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl351() {
        // P(4); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
    }

    @Test("FL-354 path P(4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl354() {
        // P(4); minimumVertexCut(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [2] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [2] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [2] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [2] as [Int])
        }
    }

    @Test("FL-357 path P(4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl357() {
        // P(4); minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
    }

    @Test("FL-360 cycle C(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl360() {
        // C(5); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [1, 3] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1, 3] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [1, 3] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1, 3] as [Int])
        }
    }

    @Test("FL-363 cycle C(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl363() {
        // C(5); minimumVertexCut(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1, 3] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1, 3] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1, 3] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1, 3] as [Int])
        }
    }

    @Test("FL-366 K(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl366() {
        // K(5); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [1, 2, 3, 4] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1, 2, 3, 4] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [1, 2, 3, 4] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1, 2, 3, 4] as [Int])
        }
    }

    @Test("FL-369 K(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl369() {
        // K(5); minimumVertexCut(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 4) == nil)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 4) == nil)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 4) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 4) == nil)
        }
    }

    @Test("FL-372 Kb(3,3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl372() {
        // Kb(3,3); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [3, 4, 5] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [3, 4, 5] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [3, 4, 5] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [3, 4, 5] as [Int])
        }
    }

    @Test("FL-375 Kb(3,3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl375() {
        // Kb(3,3); minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 1) == [3, 4, 5] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 1) == [3, 4, 5] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 1) == [3, 4, 5] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 1) == [3, 4, 5] as [Int])
        }
    }

    @Test("FL-378 Kb(3,3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl378() {
        // Kb(3,3); minimumVertexCut(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 3) == nil)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 3) == nil)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 3) == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 3) == nil)
        }
    }

    @Test("FL-381 wheel(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl381() {
        // wheel(5); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [0, 2, 4] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [0, 2, 4] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [0, 2, 4] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [0, 2, 4] as [Int])
        }
    }

    @Test("FL-384 wheel(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl384() {
        // wheel(5); minimumVertexCut(from: 1, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 1, to: 3) == [0, 2, 4] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 1, to: 3) == [0, 2, 4] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 1, to: 3) == [0, 2, 4] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 1, to: 3) == [0, 2, 4] as [Int])
        }
    }

    @Test("FL-387 two triangles sharing a vertex: κ 1, λ 2, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl387() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [2] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [2] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [2] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [2] as [Int])
        }
    }

    @Test("FL-390 two triangles sharing a vertex: κ 1, λ 2, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl390() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; minimumVertexCut(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 4) == [2] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 4) == [2] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 4) == [2] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 4) == [2] as [Int])
        }
    }

    @Test("FL-393 two K(4) joined by two edges, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl393() {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7, 0–4, 1–5]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [1, 4] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1, 4] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [1, 4] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1, 4] as [Int])
        }
    }

    @Test("FL-396 two K(4) joined by two edges, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl396() {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7, 0–4, 1–5]; minimumVertexCut(from: 2, to: 6)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 2, to: 6) == [4, 5] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 2, to: 6) == [4, 5] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 2, to: 6) == [4, 5] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 2, to: 6) == [4, 5] as [Int])
        }
    }

    @Test("FL-399 disconnected, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl399() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
    }

    @Test("FL-402 disconnected, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl402() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; minimumVertexCut(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [] as [Int])
        }
    }

    @Test("FL-405 Petersen, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl405() {
        // nx(petersen_graph); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [1, 3, 7] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1, 3, 7] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [1, 3, 7] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1, 3, 7] as [Int])
        }
    }

    @Test("FL-408 Petersen, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl408() {
        // nx(petersen_graph); minimumVertexCut(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 7) == [2, 5, 9] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 7) == [2, 5, 9] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 7) == [2, 5, 9] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 7) == [2, 5, 9] as [Int])
        }
    }

    @Test("FL-411 hypercube Q(3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl411() {
        // Q(3); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [1, 2, 7] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1, 2, 7] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [1, 2, 7] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1, 2, 7] as [Int])
        }
    }

    @Test("FL-414 hypercube Q(3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl414() {
        // Q(3); minimumVertexCut(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 7) == [3, 5, 6] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 7) == [3, 5, 6] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 7) == [3, 5, 6] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 7) == [3, 5, 6] as [Int])
        }
    }

    @Test("FL-417 grid(3,4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl417() {
        // grid(3,4); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [1, 4] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1, 4] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [1, 4] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1, 4] as [Int])
        }
    }

    @Test("FL-420 grid(3,4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl420() {
        // grid(3,4); minimumVertexCut(from: 0, to: 11)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 11) == [7, 10] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 11) == [7, 10] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 11) == [7, 10] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 11) == [7, 10] as [Int])
        }
    }

    @Test("FL-423 karate club, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl423() {
        // nx(karate_club_graph); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut() == [0] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [0] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut() == [0] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyMatrix(vertexCount: 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [0] as [Int])
        }
    }

    @Test("FL-426 karate club, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl426() {
        // nx(karate_club_graph); minimumVertexCut(from: 0, to: 33)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 33) == [2, 8, 13, 19, 30, 31] as [Int])
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 33) == [2, 8, 13, 19, 30, 31] as [Int])
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.minimumVertexCut(from: 0, to: 33) == [2, 8, 13, 19, 30, 31] as [Int])
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyMatrix(vertexCount: 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 33) == [2, 8, 13, 19, 30, 31] as [Int])
        }
    }

    @Test("FL-429 directed: one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl429() {
        // V [0, 1]; E [0→1]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
    }

    @Test("FL-432 directed: one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl432() {
        // V [0, 1]; E [0→1]; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
    }

    @Test("FL-435 directed: one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl435() {
        // V [0, 1]; E [0→1]; minimumVertexCut(from: 1, to: 0)
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 1, to: 0) == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 1, to: 0) == [] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 1, to: 0) == [] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 1, to: 0) == [] as [Int])
        }
    }

    @Test("FL-438 directed: two-cycle, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl438() {
        // V [0, 1]; E [0→1, 1→0]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1] as [Int])
        }
    }

    @Test("FL-441 directed: two-cycle, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl441() {
        // V [0, 1]; E [0→1, 1→0]; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
    }

    @Test("FL-444 directed: cycle Cd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl444() {
        // Cd(4); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut() == [3] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [3] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [3] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [3] as [Int])
        }
    }

    @Test("FL-447 directed: cycle Cd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl447() {
        // Cd(4); minimumVertexCut(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1] as [Int])
        }
    }

    @Test("FL-450 directed: complete Kd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl450() {
        // Kd(4); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut() == [1, 2, 3] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1, 2, 3] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1, 2, 3] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1, 2, 3] as [Int])
        }
    }

    @Test("FL-453 directed: complete Kd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl453() {
        // Kd(4); minimumVertexCut(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 3) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 3) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 3) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 3) == nil)
        }
    }

    @Test("FL-456 directed: adjacent pair counts the edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl456() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
    }

    @Test("FL-459 directed: adjacent pair counts the edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl459() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
    }

    @Test("FL-462 directed: adjacent pair counts the edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl462() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; minimumVertexCut(from: 1, to: 0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 1, to: 0) == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 1, to: 0) == [] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 1, to: 0) == [] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 1, to: 0) == [] as [Int])
        }
    }

    @Test("FL-465 directed: weakly but not strongly connected, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl465() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [] as [Int])
        }
    }

    @Test("FL-468 directed: weakly but not strongly connected, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl468() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; minimumVertexCut(from: 3, to: 0)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 3, to: 0) == [] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 3, to: 0) == [] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 3, to: 0) == [] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 3, to: 0) == [] as [Int])
        }
    }

    @Test("FL-471 directed: weakly but not strongly connected, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl471() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; minimumVertexCut(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [2] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [2] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [2] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 3) == [2] as [Int])
        }
    }

    @Test("FL-474 directed: bidirected C(5), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl474() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut() == [1, 3] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [1, 3] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1, 3] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut() == [1, 3] as [Int])
        }
    }

    @Test("FL-477 directed: bidirected C(5), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl477() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; minimumVertexCut(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1, 3] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1, 3] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1, 3] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.minimumVertexCut(from: 0, to: 2) == [1, 3] as [Int])
        }
    }

    @Test("FL-480 directed: parallel arcs, on ReferenceDirectedMultigraph, no indices")
    func fl480() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut() == [2] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut() == [2] as [Int])
        }
    }

    @Test("FL-483 directed: parallel arcs, on ReferenceDirectedMultigraph, no indices")
    func fl483() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.minimumVertexCut(from: 0, to: 1) == nil)
        }
    }
}
