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

@Suite("edgeConnectivity on every representation")
struct EdgeConnectivityRepresentationTests {
    @Test("FL-322 empty graph, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl322() {
        // undirected V []; E []; edgeConnectivity()
        let pairs: [(Int, Int)] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 0)
        }
    }

    @Test("FL-325 one vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl325() {
        // undirected V [0]; E []; edgeConnectivity()
        let pairs: [(Int, Int)] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 0)
        }
    }

    @Test("FL-328 two isolated vertices, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl328() {
        // undirected V [0, 1]; E []; edgeConnectivity()
        let pairs: [(Int, Int)] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 0)
        }
    }

    @Test("FL-331 two isolated vertices, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl331() {
        // undirected V [0, 1]; E []; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 0)
        }
    }

    @Test("FL-334 K(2): κ = n − 1: all but the first vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl334() {
        // K(2); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 1)
        }
    }

    @Test("FL-337 K(2): κ = n − 1: all but the first vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl337() {
        // K(2); edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
    }

    @Test("FL-340 K(2) with parallel edges: λ counts copies, κ does not, on ReferencePseudograph, no indices")
    func fl340() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 3)
        }
    }

    @Test("FL-343 K(2) with parallel edges: λ counts copies, κ does not, on ReferencePseudograph, no indices")
    func fl343() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 3)
        }
    }

    @Test("FL-346 self-loops ignored, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl346() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 1)
        }
    }

    @Test("FL-349 self-loops ignored, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl349() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; edgeConnectivity(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 1)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 1)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 1)
        }
    }

    @Test("FL-352 path P(4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl352() {
        // P(4); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 1)
        }
    }

    @Test("FL-355 path P(4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl355() {
        // P(4); edgeConnectivity(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 1)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 1)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 1)
        }
    }

    @Test("FL-358 path P(4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl358() {
        // P(4); edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
    }

    @Test("FL-361 cycle C(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl361() {
        // C(5); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 2)
        }
    }

    @Test("FL-364 cycle C(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl364() {
        // C(5); edgeConnectivity(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 2)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 2)
        }
    }

    @Test("FL-367 K(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl367() {
        // K(5); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 4)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 4)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 4)
        }
    }

    @Test("FL-370 K(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl370() {
        // K(5); edgeConnectivity(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 4) == 4)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 4) == 4)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 4) == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 4) == 4)
        }
    }

    @Test("FL-373 Kb(3,3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl373() {
        // Kb(3,3); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 3)
        }
    }

    @Test("FL-376 Kb(3,3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl376() {
        // Kb(3,3); edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 3)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 3)
        }
    }

    @Test("FL-379 Kb(3,3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl379() {
        // Kb(3,3); edgeConnectivity(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 3)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 3)
        }
    }

    @Test("FL-382 wheel(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl382() {
        // wheel(5); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 3)
        }
    }

    @Test("FL-385 wheel(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl385() {
        // wheel(5); edgeConnectivity(from: 1, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 1, to: 3) == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 1, to: 3) == 3)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 1, to: 3) == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 1, to: 3) == 3)
        }
    }

    @Test("FL-388 two triangles sharing a vertex: κ 1, λ 2, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl388() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 2)
        }
    }

    @Test("FL-391 two triangles sharing a vertex: κ 1, λ 2, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl391() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; edgeConnectivity(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 4) == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 4) == 2)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 4) == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 4) == 2)
        }
    }

    @Test("FL-394 two K(4) joined by two edges, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl394() {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7, 0–4, 1–5]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 2)
        }
    }

    @Test("FL-397 two K(4) joined by two edges, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl397() {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7, 0–4, 1–5]; edgeConnectivity(from: 2, to: 6)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 2, to: 6) == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 2, to: 6) == 2)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 2, to: 6) == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 2, to: 6) == 2)
        }
    }

    @Test("FL-400 disconnected, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl400() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 0)
        }
    }

    @Test("FL-403 disconnected, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl403() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; edgeConnectivity(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 0)
        }
    }

    @Test("FL-406 Petersen, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl406() {
        // nx(petersen_graph); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 3)
        }
    }

    @Test("FL-409 Petersen, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl409() {
        // nx(petersen_graph); edgeConnectivity(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 7) == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 7) == 3)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 7) == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 7) == 3)
        }
    }

    @Test("FL-412 hypercube Q(3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl412() {
        // Q(3); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 3)
        }
    }

    @Test("FL-415 hypercube Q(3), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl415() {
        // Q(3); edgeConnectivity(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 7) == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 7) == 3)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 7) == 3)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 7) == 3)
        }
    }

    @Test("FL-418 grid(3,4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl418() {
        // grid(3,4); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 2)
        }
    }

    @Test("FL-421 grid(3,4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl421() {
        // grid(3,4); edgeConnectivity(from: 0, to: 11)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 11) == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 11) == 2)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 11) == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 11) == 2)
        }
    }

    @Test("FL-424 karate club, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl424() {
        // nx(karate_club_graph); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyMatrix(vertexCount: 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 1)
        }
    }

    @Test("FL-427 karate club, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl427() {
        // nx(karate_club_graph); edgeConnectivity(from: 0, to: 33)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 33) == 10)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 33) == 10)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            #expect(graph.edgeConnectivity(from: 0, to: 33) == 10)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
            let graph = AdjacencyMatrix(vertexCount: 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 33) == 10)
        }
    }

    @Test("FL-430 directed: one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl430() {
        // V [0, 1]; E [0→1]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 0)
        }
    }

    @Test("FL-433 directed: one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl433() {
        // V [0, 1]; E [0→1]; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
    }

    @Test("FL-436 directed: one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl436() {
        // V [0, 1]; E [0→1]; edgeConnectivity(from: 1, to: 0)
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 1, to: 0) == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 1, to: 0) == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 1, to: 0) == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 1, to: 0) == 0)
        }
    }

    @Test("FL-439 directed: two-cycle, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl439() {
        // V [0, 1]; E [0→1, 1→0]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 1)
        }
    }

    @Test("FL-442 directed: two-cycle, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl442() {
        // V [0, 1]; E [0→1, 1→0]; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 1)
        }
    }

    @Test("FL-445 directed: cycle Cd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl445() {
        // Cd(4); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 1)
        }
    }

    @Test("FL-448 directed: cycle Cd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl448() {
        // Cd(4); edgeConnectivity(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 1)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 1)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 1)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 1)
        }
    }

    @Test("FL-451 directed: complete Kd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl451() {
        // Kd(4); edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 3)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 3)
        }
    }

    @Test("FL-454 directed: complete Kd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl454() {
        // Kd(4); edgeConnectivity(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 3)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 3)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 3)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 3)
        }
    }

    @Test("FL-457 directed: adjacent pair counts the edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl457() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 0)
        }
    }

    @Test("FL-460 directed: adjacent pair counts the edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl460() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 2)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 2)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 2)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 2)
        }
    }

    @Test("FL-463 directed: adjacent pair counts the edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl463() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; edgeConnectivity(from: 1, to: 0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 1, to: 0) == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 1, to: 0) == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 1, to: 0) == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 1, to: 0) == 0)
        }
    }

    @Test("FL-466 directed: weakly but not strongly connected, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl466() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 0)
        }
    }

    @Test("FL-469 directed: weakly but not strongly connected, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl469() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; edgeConnectivity(from: 3, to: 0)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 3, to: 0) == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 3, to: 0) == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 3, to: 0) == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 3, to: 0) == 0)
        }
    }

    @Test("FL-472 directed: weakly but not strongly connected, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl472() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; edgeConnectivity(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 1)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 1)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 1)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 3) == 1)
        }
    }

    @Test("FL-475 directed: bidirected C(5), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl475() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 2)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity() == 2)
        }
    }

    @Test("FL-478 directed: bidirected C(5), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl478() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; edgeConnectivity(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 2)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 2)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 2)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            #expect(graph.edgeConnectivity(from: 0, to: 2) == 2)
        }
    }

    @Test("FL-481 directed: parallel arcs, on ReferenceDirectedMultigraph, no indices")
    func fl481() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; edgeConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity() == 1)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity() == 1)
        }
    }

    @Test("FL-484 directed: parallel arcs, on ReferenceDirectedMultigraph, no indices")
    func fl484() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; edgeConnectivity(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 2)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.edgeConnectivity(from: 0, to: 1) == 2)
        }
    }
}
