// The catalog's rows again on other representations: directed rows on `DirectedPseudograph` (or
// `ReferenceDirectedMultigraph` for rows already on it), a file-private conformer with no vertex or
// edge indices, and, without a repeated edge, `CompressedSparseRow` and `AdjacencyMatrix` on the
// vertex indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and,
// without a repeated edge, `AdjacencyList.undirected` (each edge an arc as written) and
// `AdjacencyMatrix.undirected`. CompressedSparseRow and AdjacencyMatrix number edges by row-major
// cell, so there each catalog edge's position is looked up, a cut's edges are listed in that order,
// and Edmonds–Karp's flow (which follows positions) was recomputed by swiftgen.py with ref.py's
// model on those positions. Everything else is the catalog's. See README.md.

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

@Suite("Minimum-cost flows on every representation")
struct MinimumCostFlowRepresentationTests {
    @Test("FL-275 NetworkX docs example: cost 24, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl275() throws {
        // V [a, b, c, d]; E [a→b 4 @3, a→c 10 @6, b→d 9 @1, c→d 5 @2]; supply [a: 5, d: -5]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(String, String)] = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")]
        let capacities: [Int] = [4, 10, 9, 5]
        do { // DirectedPseudograph
            let vertexList = ["a", "b", "c", "d"] as [String]
            let graph = DirectedPseudograph<String>(vertices: ["a", "b", "c", "d"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [3, 6, 1, 2]
            let supplies: [Int] = [5, 0, 0, -5]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 24)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [4, 1, 4, 1] as [Int])
        }
        do { // no indices
            let vertexList = ["a", "b", "c", "d"] as [String]
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "b", "c", "d"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [3, 6, 1, 2]
            let supplies: [Int] = [5, 0, 0, -5]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 24)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [4, 1, 4, 1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [3, 6, 1, 2]
            let supplies: [Int] = [5, 0, 0, -5]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 24)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [4, 1, 4, 1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [3, 6, 1, 2]
            let supplies: [Int] = [5, 0, 0, -5]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 24)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [4, 1, 4, 1] as [Int])
        }
    }

    @Test("FL-276 no vertices, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl276() throws {
        // V []; E []; supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        do { // DirectedPseudograph
            let vertexList = [] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = []
            let supplies: [Int] = []
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [] as [Int])
        }
        do { // no indices
            let vertexList = [] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = []
            let supplies: [Int] = []
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let graph = CompressedSparseRow(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = []
            let supplies: [Int] = []
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = []
            let supplies: [Int] = []
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [] as [Int])
        }
    }

    @Test("FL-277 no supply, no edges, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl277() throws {
        // V [0, 1]; E []; supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = []
            let supplies: [Int] = [0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = []
            let supplies: [Int] = [0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = []
            let supplies: [Int] = [0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = []
            let supplies: [Int] = [0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [] as [Int])
        }
    }

    @Test("FL-278 no supply, positive costs: nothing moves, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl278() throws {
        // V [0, 1]; E [0→1 3 @1, 1→0 3 @1]; supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [3, 3]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, 1]
            let supplies: [Int] = [0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 0] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, 1]
            let supplies: [Int] = [0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 0] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 1]
            let supplies: [Int] = [0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 0] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 1]
            let supplies: [Int] = [0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 0] as [Int])
        }
    }

    @Test("FL-279 no supply, a negative cycle: saturated to capacity 2, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl279() throws {
        // V [0, 1, 2]; E [0→1 2 @1, 1→2 3 @-5, 2→0 4 @1]; supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let capacities: [Int] = [2, 3, 4]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, -5, 1]
            let supplies: [Int] = [0, 0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -6)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 2, 2] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1, 2] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, -5, 1]
            let supplies: [Int] = [0, 0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -6)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 2, 2] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, -5, 1]
            let supplies: [Int] = [0, 0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -6)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2, 2] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, -5, 1]
            let supplies: [Int] = [0, 0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -6)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2, 2] as [Int])
        }
    }

    @Test("FL-280 negative self-loop saturated, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl280() throws {
        // V [0, 1]; E [0→0 3 @-2, 0→1 1 @1]; supply [0: 1, 1: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let capacities: [Int] = [3, 1]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [-2, 1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -5)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [3, 1] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [-2, 1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -5)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [3, 1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-2, 1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -5)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [3, 1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-2, 1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -5)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [3, 1] as [Int])
        }
    }

    @Test("FL-281 zero-cost self-loop carries nothing, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl281() throws {
        // V [0, 1]; E [0→0 3 @0, 0→1 1 @1]; supply [0: 1, 1: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let capacities: [Int] = [3, 1]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [0, 1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 1)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 1] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [0, 1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 1)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [0, 1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 1)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [0, 1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 1)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 1] as [Int])
        }
    }

    @Test("FL-282 one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl282() throws {
        // V [0, 1]; E [0→1 5 @2]; supply [0: 3, 1: -3]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [5]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [2]
            let supplies: [Int] = [3, -3]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 6)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [3] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [2]
            let supplies: [Int] = [3, -3]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 6)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [3] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [2]
            let supplies: [Int] = [3, -3]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 6)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [3] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [2]
            let supplies: [Int] = [3, -3]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 6)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [3] as [Int])
        }
    }

    @Test("FL-283 supply over capacity: infeasible, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl283() {
        // V [0, 1]; E [0→1 1 @1]; supply [0: 2, 1: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [1]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1]
            let supplies: [Int] = [2, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1]
            let supplies: [Int] = [2, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1]
            let supplies: [Int] = [2, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1]
            let supplies: [Int] = [2, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
    }

    @Test("FL-284 unbalanced supplies: nil (NetworkX: total node demand is not zero), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl284() {
        // V [0, 1]; E [0→1 3 @1]; supply [0: 1, 1: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [3]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1]
            let supplies: [Int] = [1, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1]
            let supplies: [Int] = [1, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1]
            let supplies: [Int] = [1, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1]
            let supplies: [Int] = [1, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
    }

    @Test("FL-285 unbalanced, more supply, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl285() {
        // V [0, 1]; E [0→1 3 @1]; supply [0: 2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [3]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1]
            let supplies: [Int] = [2, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1]
            let supplies: [Int] = [2, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1]
            let supplies: [Int] = [2, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1]
            let supplies: [Int] = [2, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
    }

    @Test("FL-286 no path to the demand, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl286() {
        // V [0, 1, 2]; E [0→1 3 @1]; supply [0: 1, 2: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [3]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1]
            let supplies: [Int] = [1, 0, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let vertexList = [0, 1, 2] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1]
            let supplies: [Int] = [1, 0, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1]
            let supplies: [Int] = [1, 0, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1]
            let supplies: [Int] = [1, 0, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
    }

    @Test("FL-287 cheaper long way, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl287() throws {
        // V [0, 1, 2]; E [0→2 5 @5, 0→1 5 @1, 1→2 5 @1]; supply [0: 4, 2: -4]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
        let capacities: [Int] = [5, 5, 5]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [5, 1, 1]
            let supplies: [Int] = [4, 0, -4]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 8)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 4, 4] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1, 2] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [5, 1, 1]
            let supplies: [Int] = [4, 0, -4]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 8)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 4, 4] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [5, 1, 1]
            let supplies: [Int] = [4, 0, -4]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 8)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 4, 4] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [5, 1, 1]
            let supplies: [Int] = [4, 0, -4]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 8)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 4, 4] as [Int])
        }
    }

    @Test("FL-288 cheaper long way, capacity spills, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl288() throws {
        // V [0, 1, 2]; E [0→2 5 @5, 0→1 2 @1, 1→2 5 @1]; supply [0: 4, 2: -4]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
        let capacities: [Int] = [5, 2, 5]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [5, 1, 1]
            let supplies: [Int] = [4, 0, -4]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 14)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 2, 2] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1, 2] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [5, 1, 1]
            let supplies: [Int] = [4, 0, -4]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 14)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 2, 2] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [5, 1, 1]
            let supplies: [Int] = [4, 0, -4]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 14)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2, 2] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [5, 1, 1]
            let supplies: [Int] = [4, 0, -4]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 14)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2, 2] as [Int])
        }
    }

    @Test("FL-289 ties: two equal routes, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl289() throws {
        // V [0, 1, 2, 3]; E [0→1 2 @1, 0→2 2 @1, 1→3 2 @1, 2→3 2 @1]; supply [0: 2, 3: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [2, 2, 2, 2]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2, 3] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, 1, 1, 1]
            let supplies: [Int] = [2, 0, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 4)
            #expect(flowResult.value == 2)
            // One of several optima: capacity, conservation and the potentials' certificate, by catalog edge.
            let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
            var balance = [Int](repeating: 0, count: supplies.count)
            for (k, (a, b)) in pairs.enumerated() {
                #expect(flows[k] >= 0 && flows[k] <= capacities[k])
                let ia = vertexList.firstIndex(of: a)!, ib = vertexList.firstIndex(of: b)!
                balance[ia] += Int(flows[k])
                balance[ib] -= Int(flows[k])
                let reduced = Int(costs[k]) + Int(flowResult.potential(of: a)) - Int(flowResult.potential(of: b))
                if flows[k] < capacities[k] { #expect(reduced >= 0) }
                if flows[k] > 0 { #expect(reduced <= 0) }
            }
            #expect(balance == supplies.map { Int($0) })
        }
        do { // no indices
            let vertexList = [0, 1, 2, 3] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, 1, 1, 1]
            let supplies: [Int] = [2, 0, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 4)
            #expect(flowResult.value == 2)
            // One of several optima: capacity, conservation and the potentials' certificate, by catalog edge.
            let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
            var balance = [Int](repeating: 0, count: supplies.count)
            for (k, (a, b)) in pairs.enumerated() {
                #expect(flows[k] >= 0 && flows[k] <= capacities[k])
                let ia = vertexList.firstIndex(of: a)!, ib = vertexList.firstIndex(of: b)!
                balance[ia] += Int(flows[k])
                balance[ib] -= Int(flows[k])
                let reduced = Int(costs[k]) + Int(flowResult.potential(of: a)) - Int(flowResult.potential(of: b))
                if flows[k] < capacities[k] { #expect(reduced >= 0) }
                if flows[k] > 0 { #expect(reduced <= 0) }
            }
            #expect(balance == supplies.map { Int($0) })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 1, 1, 1]
            let supplies: [Int] = [2, 0, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 4)
            #expect(flowResult.value == 2)
            // One of several optima: capacity, conservation and the potentials' certificate, by catalog edge.
            let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) }
            var balance = [Int](repeating: 0, count: supplies.count)
            for (k, (a, b)) in pairs.enumerated() {
                #expect(flows[k] >= 0 && flows[k] <= capacities[k])
                let ia = a, ib = b
                balance[ia] += Int(flows[k])
                balance[ib] -= Int(flows[k])
                let reduced = Int(costs[k]) + Int(flowResult.potential(of: a)) - Int(flowResult.potential(of: b))
                if flows[k] < capacities[k] { #expect(reduced >= 0) }
                if flows[k] > 0 { #expect(reduced <= 0) }
            }
            #expect(balance == supplies.map { Int($0) })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 1, 1, 1]
            let supplies: [Int] = [2, 0, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 4)
            #expect(flowResult.value == 2)
            // One of several optima: capacity, conservation and the potentials' certificate, by catalog edge.
            let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) }
            var balance = [Int](repeating: 0, count: supplies.count)
            for (k, (a, b)) in pairs.enumerated() {
                #expect(flows[k] >= 0 && flows[k] <= capacities[k])
                let ia = a, ib = b
                balance[ia] += Int(flows[k])
                balance[ib] -= Int(flows[k])
                let reduced = Int(costs[k]) + Int(flowResult.potential(of: a)) - Int(flowResult.potential(of: b))
                if flows[k] < capacities[k] { #expect(reduced >= 0) }
                if flows[k] > 0 { #expect(reduced <= 0) }
            }
            #expect(balance == supplies.map { Int($0) })
        }
    }

    @Test("FL-290 parallel edges, different costs, on ReferenceDirectedMultigraph, no indices")
    func fl290() throws {
        // V [0, 1]; E [0→1 2 @3, 0→1 2 @1, 0→1 2 @2]; supply [0: 3, 1: -3]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (0, 1)]
        let capacities: [Int] = [2, 2, 2]
        do { // ReferenceDirectedMultigraph
            let vertexList = [0, 1] as [Int]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [3, 1, 2]
            let supplies: [Int] = [3, -3]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 4)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 2, 1] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [3, 1, 2]
            let supplies: [Int] = [3, -3]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 4)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 2, 1] as [Int])
        }
    }

    @Test("FL-291 antiparallel edges: the back edge carries nothing, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl291() throws {
        // V [0, 1]; E [0→1 5 @2, 1→0 5 @1]; supply [0: 2, 1: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [5, 5]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [2, 1]
            let supplies: [Int] = [2, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 4)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 0] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [2, 1]
            let supplies: [Int] = [2, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 4)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 0] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [2, 1]
            let supplies: [Int] = [2, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 4)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 0] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [2, 1]
            let supplies: [Int] = [2, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 4)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 0] as [Int])
        }
    }

    @Test("FL-292 negative cost on the route, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl292() throws {
        // V [0, 1, 2]; E [0→1 3 @-2, 1→2 3 @1, 0→2 3 @0]; supply [0: 2, 2: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let capacities: [Int] = [3, 3, 3]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [-2, 1, 0]
            let supplies: [Int] = [2, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -2)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 2, 0] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1, 2] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [-2, 1, 0]
            let supplies: [Int] = [2, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -2)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 2, 0] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-2, 1, 0]
            let supplies: [Int] = [2, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -2)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2, 0] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-2, 1, 0]
            let supplies: [Int] = [2, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -2)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2, 0] as [Int])
        }
    }

    @Test("FL-293 negative cycle beside the route, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl293() throws {
        // V [0, 1, 2, 3]; E [0→3 1 @1, 1→2 2 @-3, 2→1 2 @1]; supply [0: 1, 3: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 3), (1, 2), (2, 1)]
        let capacities: [Int] = [1, 2, 2]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2, 3] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, -3, 1]
            let supplies: [Int] = [1, 0, 0, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -3)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1, 2, 2] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1, 2, 3] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, -3, 1]
            let supplies: [Int] = [1, 0, 0, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -3)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1, 2, 2] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 3), (1, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, -3, 1]
            let supplies: [Int] = [1, 0, 0, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -3)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 2, 2] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 3), (1, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, -3, 1]
            let supplies: [Int] = [1, 0, 0, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -3)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 2, 2] as [Int])
        }
    }

    @Test("FL-294 transshipment vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl294() throws {
        // V [p, w, c1, c2]; E [p→w 10 @1, w→c1 10 @1, w→c2 10 @2, p→c1 2 @5]; supply [p: 6, c1: -3, c2: -3]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(String, String)] = [("p", "w"), ("w", "c1"), ("w", "c2"), ("p", "c1")]
        let capacities: [Int] = [10, 10, 10, 2]
        do { // DirectedPseudograph
            let vertexList = ["p", "w", "c1", "c2"] as [String]
            let graph = DirectedPseudograph<String>(vertices: ["p", "w", "c1", "c2"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, 1, 2, 5]
            let supplies: [Int] = [6, 0, -3, -3]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 15)
            #expect(flowResult.value == 6)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [6, 3, 3, 0] as [Int])
        }
        do { // no indices
            let vertexList = ["p", "w", "c1", "c2"] as [String]
            let graph = UnindexedDirectedGraph<String>(vertices: ["p", "w", "c1", "c2"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, 1, 2, 5]
            let supplies: [Int] = [6, 0, -3, -3]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 15)
            #expect(flowResult.value == 6)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [6, 3, 3, 0] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 3), (0, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 1, 2, 5]
            let supplies: [Int] = [6, 0, -3, -3]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 15)
            #expect(flowResult.value == 6)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [6, 3, 3, 0] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 1, 2, 5]
            let supplies: [Int] = [6, 0, -3, -3]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 15)
            #expect(flowResult.value == 6)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [6, 3, 3, 0] as [Int])
        }
    }

    @Test("FL-295 two supplies, two demands (transportation), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl295() throws {
        // V [s1, s2, d1, d2]; E [s1→d1 9 @4, s1→d2 9 @6, s2→d1 9 @5, s2→d2 9 @3]; supply [s1: 3, s2: 4, d1: -5, d2: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(String, String)] = [("s1", "d1"), ("s1", "d2"), ("s2", "d1"), ("s2", "d2")]
        let capacities: [Int] = [9, 9, 9, 9]
        do { // DirectedPseudograph
            let vertexList = ["s1", "s2", "d1", "d2"] as [String]
            let graph = DirectedPseudograph<String>(vertices: ["s1", "s2", "d1", "d2"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [4, 6, 5, 3]
            let supplies: [Int] = [3, 4, -5, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 28)
            #expect(flowResult.value == 7)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [3, 0, 2, 2] as [Int])
        }
        do { // no indices
            let vertexList = ["s1", "s2", "d1", "d2"] as [String]
            let graph = UnindexedDirectedGraph<String>(vertices: ["s1", "s2", "d1", "d2"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [4, 6, 5, 3]
            let supplies: [Int] = [3, 4, -5, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 28)
            #expect(flowResult.value == 7)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [3, 0, 2, 2] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [4, 6, 5, 3]
            let supplies: [Int] = [3, 4, -5, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 28)
            #expect(flowResult.value == 7)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [3, 0, 2, 2] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [4, 6, 5, 3]
            let supplies: [Int] = [3, 4, -5, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 28)
            #expect(flowResult.value == 7)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [3, 0, 2, 2] as [Int])
        }
    }

    @Test("FL-296 assignment 3×3 as flow: scipy linear_sum_assignment cost 5, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl296() throws {
        // V [r0, r1, r2, c0, c1, c2]; E [r0→c0 1 @4, r0→c1 1 @1, r0→c2 1 @3, r1→c0 1 @2, r1→c1 1 @0, r1→c2 1 @5, r2→c0 1 @3, r2→c1 1 @2, r2→c2 1 @2]; supply [r0: 1, r1: 1, r2: 1, c0: -1, c1: -1, c2: -1]; min…
        let pairs: [(String, String)] = [("r0", "c0"), ("r0", "c1"), ("r0", "c2"), ("r1", "c0"), ("r1", "c1"), ("r1", "c2"), ("r2", "c0"), ("r2", "c1"), ("r2", "c2")]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1]
        do { // DirectedPseudograph
            let vertexList = ["r0", "r1", "r2", "c0", "c1", "c2"] as [String]
            let graph = DirectedPseudograph<String>(vertices: ["r0", "r1", "r2", "c0", "c1", "c2"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [4, 1, 3, 2, 0, 5, 3, 2, 2]
            let supplies: [Int] = [1, 1, 1, -1, -1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 5)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 1, 0, 1, 0, 0, 0, 0, 1] as [Int])
        }
        do { // no indices
            let vertexList = ["r0", "r1", "r2", "c0", "c1", "c2"] as [String]
            let graph = UnindexedDirectedGraph<String>(vertices: ["r0", "r1", "r2", "c0", "c1", "c2"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [4, 1, 3, 2, 0, 5, 3, 2, 2]
            let supplies: [Int] = [1, 1, 1, -1, -1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 5)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 1, 0, 1, 0, 0, 0, 0, 1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [4, 1, 3, 2, 0, 5, 3, 2, 2]
            let supplies: [Int] = [1, 1, 1, -1, -1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 5)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 1, 0, 1, 0, 0, 0, 0, 1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [4, 1, 3, 2, 0, 5, 3, 2, 2]
            let supplies: [Int] = [1, 1, 1, -1, -1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 5)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 1, 0, 1, 0, 0, 0, 0, 1] as [Int])
        }
    }

    @Test("FL-297 infeasible behind a cut, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl297() {
        // V [0, 1, 2, 3]; E [0→1 5 @1, 0→2 5 @1, 1→3 1 @1, 2→3 1 @1]; supply [0: 3, 3: -3]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [5, 5, 1, 1]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2, 3] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, 1, 1, 1]
            let supplies: [Int] = [3, 0, 0, -3]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let vertexList = [0, 1, 2, 3] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, 1, 1, 1]
            let supplies: [Int] = [3, 0, 0, -3]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 1, 1, 1]
            let supplies: [Int] = [3, 0, 0, -3]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 1, 1, 1]
            let supplies: [Int] = [3, 0, 0, -3]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
    }

    @Test("FL-298 demand reached only against an edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl298() {
        // V [0, 1]; E [1→0 5 @1]; supply [0: 1, 1: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(1, 0)]
        let capacities: [Int] = [5]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1]
            let supplies: [Int] = [1, -1]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(result == nil)
        }
    }

    @Test("FL-299 zero-capacity edges, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl299() throws {
        // V [0, 1, 2]; E [0→1 0 @-9, 0→2 2 @1, 2→1 2 @1]; supply [0: 1, 1: -1]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let capacities: [Int] = [0, 2, 2]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [-9, 1, 1]
            let supplies: [Int] = [1, -1, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 2)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 1, 1] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1, 2] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [-9, 1, 1]
            let supplies: [Int] = [1, -1, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 2)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 1, 1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-9, 1, 1]
            let supplies: [Int] = [1, -1, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 2)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 1, 1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-9, 1, 1]
            let supplies: [Int] = [1, -1, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 2)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 1, 1] as [Int])
        }
    }

    @Test("FL-300 supply at a vertex with only a loop, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl300() throws {
        // V [0]; E [0→0 4 @-1]; supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 0)]
        let capacities: [Int] = [4]
        do { // DirectedPseudograph
            let vertexList = [0] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [-1]
            let supplies: [Int] = [0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -4)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [4] as [Int])
        }
        do { // no indices
            let vertexList = [0] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [-1]
            let supplies: [Int] = [0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -4)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [4] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = CompressedSparseRow(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-1]
            let supplies: [Int] = [0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -4)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [4] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-1]
            let supplies: [Int] = [0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -4)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [4] as [Int])
        }
    }

    @Test("FL-301 lcgcost(8,20,11,5,0,9), on ReferenceDirectedMultigraph, no indices")
    func fl301() throws {
        // lcgcost(8,20,11,5,0,9); supply [0: 4, 7: -4]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 3), (6, 3), (4, 3), (0, 3), (0, 3), (0, 2), (6, 7), (2, 5), (2, 6), (4, 1), (3, 6), (6, 2), (0, 2), (1, 6), (3, 4), (3, 0), (6, 1), (4, 5), (5, 7), (6, 4)]
        let capacities: [Int] = [4, 4, 1, 5, 4, 4, 4, 3, 2, 1, 4, 3, 4, 5, 2, 3, 5, 4, 2, 1]
        do { // ReferenceDirectedMultigraph
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7] as [Int]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [8, 2, 7, 7, 7, 0, 1, 3, 8, 4, 2, 0, 0, 7, 5, 7, 4, 8, 7, 0]
            let supplies: [Int] = [4, 0, 0, 0, 0, 0, 0, -4]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 38)
            #expect(flowResult.value == 4)
            // One of several optima: capacity, conservation and the potentials' certificate, by catalog edge.
            let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
            var balance = [Int](repeating: 0, count: supplies.count)
            for (k, (a, b)) in pairs.enumerated() {
                #expect(flows[k] >= 0 && flows[k] <= capacities[k])
                let ia = vertexList.firstIndex(of: a)!, ib = vertexList.firstIndex(of: b)!
                balance[ia] += Int(flows[k])
                balance[ib] -= Int(flows[k])
                let reduced = Int(costs[k]) + Int(flowResult.potential(of: a)) - Int(flowResult.potential(of: b))
                if flows[k] < capacities[k] { #expect(reduced >= 0) }
                if flows[k] > 0 { #expect(reduced <= 0) }
            }
            #expect(balance == supplies.map { Int($0) })
        }
        do { // no indices
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [8, 2, 7, 7, 7, 0, 1, 3, 8, 4, 2, 0, 0, 7, 5, 7, 4, 8, 7, 0]
            let supplies: [Int] = [4, 0, 0, 0, 0, 0, 0, -4]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 38)
            #expect(flowResult.value == 4)
            // One of several optima: capacity, conservation and the potentials' certificate, by catalog edge.
            let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }
            var balance = [Int](repeating: 0, count: supplies.count)
            for (k, (a, b)) in pairs.enumerated() {
                #expect(flows[k] >= 0 && flows[k] <= capacities[k])
                let ia = vertexList.firstIndex(of: a)!, ib = vertexList.firstIndex(of: b)!
                balance[ia] += Int(flows[k])
                balance[ib] -= Int(flows[k])
                let reduced = Int(costs[k]) + Int(flowResult.potential(of: a)) - Int(flowResult.potential(of: b))
                if flows[k] < capacities[k] { #expect(reduced >= 0) }
                if flows[k] > 0 { #expect(reduced <= 0) }
            }
            #expect(balance == supplies.map { Int($0) })
        }
    }

    @Test("FL-302 lcgcost(8,20,6,5,-4,9): negative costs, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl302() throws {
        // lcgcost(8,20,6,5,-4,9); supply [0: 3, 5: -1, 7: -2]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(7, 6), (4, 3), (2, 7), (2, 6), (3, 5), (7, 2), (5, 0), (1, 3), (0, 4), (0, 1), (7, 3), (3, 6), (2, 5), (0, 3), (6, 0), (5, 7), (2, 0), (5, 2), (1, 5), (7, 1)]
        let capacities: [Int] = [4, 2, 1, 1, 4, 3, 2, 3, 3, 5, 1, 3, 2, 5, 1, 1, 2, 4, 4, 2]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [-3, -2, -4, 2, -4, 5, 6, 0, -2, -1, 0, 0, 0, 7, 5, 2, 5, -2, 7, 3]
            let supplies: [Int] = [3, 0, 0, 0, 0, -1, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -31)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 2, 1, 0, 4, 0, 0, 2, 2, 2, 0, 0, 2, 0, 0, 1, 1, 4, 0, 0] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [-3, -2, -4, 2, -4, 5, 6, 0, -2, -1, 0, 0, 0, 7, 5, 2, 5, -2, 7, 3]
            let supplies: [Int] = [3, 0, 0, 0, 0, -1, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -31)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 2, 1, 0, 4, 0, 0, 2, 2, 2, 0, 0, 2, 0, 0, 1, 1, 4, 0, 0] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(7, 6), (4, 3), (2, 7), (2, 6), (3, 5), (7, 2), (5, 0), (1, 3), (0, 4), (0, 1), (7, 3), (3, 6), (2, 5), (0, 3), (6, 0), (5, 7), (2, 0), (5, 2), (1, 5), (7, 1)]
            let graph = CompressedSparseRow(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-3, -2, -4, 2, -4, 5, 6, 0, -2, -1, 0, 0, 0, 7, 5, 2, 5, -2, 7, 3]
            let supplies: [Int] = [3, 0, 0, 0, 0, -1, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -31)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 2, 1, 0, 4, 0, 0, 2, 2, 2, 0, 0, 2, 0, 0, 1, 1, 4, 0, 0] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(7, 6), (4, 3), (2, 7), (2, 6), (3, 5), (7, 2), (5, 0), (1, 3), (0, 4), (0, 1), (7, 3), (3, 6), (2, 5), (0, 3), (6, 0), (5, 7), (2, 0), (5, 2), (1, 5), (7, 1)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-3, -2, -4, 2, -4, 5, 6, 0, -2, -1, 0, 0, 0, 7, 5, 2, 5, -2, 7, 3]
            let supplies: [Int] = [3, 0, 0, 0, 0, -1, 0, -2]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -31)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 2, 1, 0, 4, 0, 0, 2, 2, 2, 0, 0, 2, 0, 0, 1, 1, 4, 0, 0] as [Int])
        }
    }

    @Test("FL-303 lcgcost(10,30,13,6,-5,5): a circulation, on ReferenceDirectedMultigraph, no indices")
    func fl303() throws {
        // lcgcost(10,30,13,6,-5,5); supply []; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(2, 5), (8, 6), (0, 1), (3, 1), (7, 6), (0, 1), (2, 6), (3, 5), (2, 4), (4, 6), (1, 5), (0, 6), (8, 1), (5, 7), (7, 4), (9, 5), (0, 7), (0, 8), (9, 8), (1, 3), (5, 4), (3, 6), (8, 5), (9, 5), (4, 1), (5, 1), (0, 1), (3, 8), (8, 6), (1, 8)]
        let capacities: [Int] = [5, 4, 6, 5, 1, 1, 3, 3, 5, 6, 1, 5, 4, 1, 4, 6, 3, 6, 4, 4, 3, 6, 2, 5, 1, 1, 4, 5, 5, 3]
        do { // ReferenceDirectedMultigraph
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [2, -2, 0, 2, -2, -5, -3, 0, -5, 4, -5, -2, -2, -1, 0, -5, 4, -1, -2, 5, 0, 1, -2, 0, -3, 0, 2, -2, 5, 4]
            let supplies: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -9)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [2, -2, 0, 2, -2, -5, -3, 0, -5, 4, -5, -2, -2, -1, 0, -5, 4, -1, -2, 5, 0, 1, -2, 0, -3, 0, 2, -2, 5, 4]
            let supplies: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -9)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0] as [Int])
        }
    }

    @Test("FL-304 lcgcost(12,40,14,9,1,20), on ReferenceDirectedMultigraph, no indices")
    func fl304() throws {
        // lcgcost(12,40,14,9,1,20); supply [0: 6, 1: 3, 10: -4, 11: -5]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(4, 2), (9, 7), (7, 11), (3, 10), (9, 6), (0, 9), (6, 3), (2, 6), (0, 11), (10, 7), (1, 2), (11, 5), (5, 11), (11, 7), (4, 2), (5, 2), (6, 5), (0, 1), (3, 5), (4, 10), (6, 3), (7, 11), (10, 5), (8, 6), (8, 9), (4, 9), (11, 0), (2, 1), (7, 5), (1, 5), (0, 7), (0, 10), (0, 8), (6, 7), (2, 4), (1, 9), (11, 9), (4, 8), (7, 0), (9, 5)]
        let capacities: [Int] = [1, 4, 2, 1, 9, 2, 3, 1, 2, 5, 3, 5, 1, 6, 1, 9, 2, 7, 5, 6, 4, 7, 4, 5, 9, 7, 5, 9, 1, 7, 2, 9, 7, 5, 5, 3, 8, 7, 4, 2]
        do { // ReferenceDirectedMultigraph
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [10, 14, 9, 10, 5, 19, 20, 15, 11, 8, 3, 8, 14, 9, 10, 4, 1, 8, 18, 4, 2, 16, 7, 13, 20, 19, 2, 9, 13, 20, 15, 12, 20, 10, 16, 1, 9, 20, 10, 14]
            let supplies: [Int] = [6, 3, 0, 0, 0, 0, 0, 0, 0, 0, -4, -5]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 139)
            #expect(flowResult.value == 9)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 2, 2, 0, 1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 3, 0, 0, 0, 0] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [10, 14, 9, 10, 5, 19, 20, 15, 11, 8, 3, 8, 14, 9, 10, 4, 1, 8, 18, 4, 2, 16, 7, 13, 20, 19, 2, 9, 13, 20, 15, 12, 20, 10, 16, 1, 9, 20, 10, 14]
            let supplies: [Int] = [6, 3, 0, 0, 0, 0, 0, 0, 0, 0, -4, -5]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 139)
            #expect(flowResult.value == 9)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 2, 2, 0, 1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 3, 0, 0, 0, 0] as [Int])
        }
    }

    @Test("FL-305 lcgcost(6,8,15,2,1,3): more supply than the network carries, on ReferenceDirectedMultigraph, no indices")
    func fl305() {
        // lcgcost(6,8,15,2,1,3); supply [0: 9, 5: -9]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(5, 3), (4, 1), (1, 0), (2, 1), (0, 5), (2, 1), (2, 1), (4, 5)]
        let capacities: [Int] = [2, 1, 2, 1, 2, 2, 2, 2]
        do { // ReferenceDirectedMultigraph
            let vertexList = [0, 1, 2, 3, 4, 5] as [Int]
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [2, 1, 1, 1, 3, 3, 1, 1]
            let supplies: [Int] = [9, 0, 0, 0, 0, -9]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let vertexList = [0, 1, 2, 3, 4, 5] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [2, 1, 1, 1, 3, 3, 1, 1]
            let supplies: [Int] = [9, 0, 0, 0, 0, -9]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(result == nil)
        }
    }

    @Test("FL-308 one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl308() {
        // V [0, 1]; E [0→1 3 @2]; minimumCostMaximumFlow(from: 0, to: 1, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [3]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [2]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 6)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [3] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [2]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 6)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [3] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [2]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 6)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [3] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [2]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 6)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [3] as [Int])
        }
    }

    @Test("FL-309 no path: value 0, cost 0, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl309() {
        // V [0, 1, 2]; E [0→1 3 @2]; minimumCostMaximumFlow(from: 0, to: 2, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [3]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [2]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [2]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [2]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [2]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 0)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0] as [Int])
        }
    }

    @Test("FL-310 cheaper of two routes first, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl310() {
        // V [0, 1, 2, 3]; E [0→1 2 @1, 0→2 2 @3, 1→3 2 @1, 2→3 2 @3]; minimumCostMaximumFlow(from: 0, to: 3, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [2, 2, 2, 2]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, 3, 1, 3]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 16)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 2, 2, 2] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, 3, 1, 3]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 16)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 2, 2, 2] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 3, 1, 3]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 16)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2, 2, 2] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 3, 1, 3]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 16)
            #expect(flowResult.value == 4)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2, 2, 2] as [Int])
        }
    }

    @Test("FL-311 maximum before cheap: the dear edge is still used, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl311() {
        // V [0, 1, 2]; E [0→2 1 @100, 0→1 5 @1, 1→2 5 @1]; minimumCostMaximumFlow(from: 0, to: 2, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
        let capacities: [Int] = [1, 5, 5]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [100, 1, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 110)
            #expect(flowResult.value == 6)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1, 5, 5] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [100, 1, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 110)
            #expect(flowResult.value == 6)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1, 5, 5] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [100, 1, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 110)
            #expect(flowResult.value == 6)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 5, 5] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 2), (0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [100, 1, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 110)
            #expect(flowResult.value == 6)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 5, 5] as [Int])
        }
    }

    @Test("FL-312 CLRS figure 26.1 with unit costs, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl312() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16 @1, s→v2 13 @1, v1→v3 12 @1, v2→v1 4 @1, v2→v4 14 @1, v3→v2 9 @1, v3→t 20 @1, v4→v3 7 @1, v4→t 4 @1]; minimumCostMaximumFlow(from: s, to: t, capacity:cost:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 76)
            #expect(flowResult.value == 23)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [12, 11, 12, 0, 11, 0, 19, 7, 4] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 76)
            #expect(flowResult.value == 23)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [12, 11, 12, 0, 11, 0, 19, 7, 4] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 76)
            #expect(flowResult.value == 23)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [12, 11, 12, 0, 11, 0, 19, 7, 4] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 76)
            #expect(flowResult.value == 23)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [12, 11, 12, 0, 11, 0, 19, 7, 4] as [Int])
        }
    }

    @Test("FL-313 negative cycle off the path is saturated: NetworkX max_flow_min_cost too, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl313() {
        // V [0, 1, 2, 3]; E [0→3 1 @1, 1→2 2 @-1, 2→1 2 @-1]; minimumCostMaximumFlow(from: 0, to: 3, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 3), (1, 2), (2, 1)]
        let capacities: [Int] = [1, 2, 2]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, -1, -1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == -3)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1, 2, 2] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, -1, -1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == -3)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1, 2, 2] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 3), (1, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, -1, -1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == -3)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 2, 2] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 3), (1, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, -1, -1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == -3)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 2, 2] as [Int])
        }
    }

    @Test("FL-314 negative self-loop, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl314() {
        // V [0, 1]; E [0→1 2 @1, 1→1 4 @-1]; minimumCostMaximumFlow(from: 0, to: 1, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let capacities: [Int] = [2, 4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, -1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == -2)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 4] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, -1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == -2)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [2, 4] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, -1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == -2)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 4] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, -1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == -2)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 4] as [Int])
        }
    }

    @Test("FL-315 parallel edges, on ReferenceDirectedMultigraph, no indices")
    func fl315() {
        // V [0, 1, 2]; E [0→1 2 @5, 0→1 2 @1, 1→2 3 @0]; minimumCostMaximumFlow(from: 0, to: 2, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let capacities: [Int] = [2, 2, 3]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [5, 1, 0]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 7)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1, 2, 3] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [5, 1, 0]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 7)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1, 2, 3] as [Int])
        }
    }

    @Test("FL-316 cancel along a reverse arc, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl316() {
        // V [0, 1, 2, 3]; E [0→1 1 @1, 0→2 1 @5, 1→2 1 @1, 1→3 1 @5, 2→3 1 @1]; minimumCostMaximumFlow(from: 0, to: 3, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [1, 1, 1, 1, 1]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [1, 5, 1, 5, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 12)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1, 1, 0, 1, 1] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [1, 5, 1, 5, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 12)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1, 1, 0, 1, 1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 5, 1, 5, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 12)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 1, 0, 1, 1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [1, 5, 1, 5, 1]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 12)
            #expect(flowResult.value == 2)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 1, 0, 1, 1] as [Int])
        }
    }

    @Test("FL-317 lcgcost(8,24,21,5,0,9), on ReferenceDirectedMultigraph, no indices")
    func fl317() {
        // lcgcost(8,24,21,5,0,9); minimumCostMaximumFlow(from: 0, to: 7, capacity:cost:)
        let pairs: [(Int, Int)] = [(3, 5), (1, 4), (7, 4), (4, 7), (4, 0), (6, 4), (0, 5), (7, 2), (7, 2), (1, 7), (2, 7), (5, 2), (5, 2), (3, 1), (5, 3), (7, 0), (0, 3), (0, 4), (1, 3), (3, 6), (4, 7), (1, 4), (3, 5), (3, 5)]
        let capacities: [Int] = [4, 2, 4, 5, 3, 3, 2, 3, 3, 2, 4, 2, 5, 2, 4, 4, 4, 4, 1, 4, 5, 3, 3, 5]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [6, 2, 0, 0, 7, 6, 1, 8, 8, 0, 1, 5, 9, 4, 8, 8, 7, 6, 6, 0, 4, 6, 8, 7]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 7, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 90)
            #expect(flowResult.value == 10)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 0, 0, 5, 0, 2, 2, 0, 0, 2, 2, 2, 0, 2, 0, 0, 4, 4, 0, 2, 1, 0, 0, 0] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [6, 2, 0, 0, 7, 6, 1, 8, 8, 0, 1, 5, 9, 4, 8, 8, 7, 6, 6, 0, 4, 6, 8, 7]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 7, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 90)
            #expect(flowResult.value == 10)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 0, 0, 5, 0, 2, 2, 0, 0, 2, 2, 2, 0, 2, 0, 0, 4, 4, 0, 2, 1, 0, 0, 0] as [Int])
        }
    }

    @Test("FL-318 lcgcost(10,30,17,5,-3,9), on ReferenceDirectedMultigraph, no indices")
    func fl318() {
        // lcgcost(10,30,17,5,-3,9); minimumCostMaximumFlow(from: 0, to: 9, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (5, 7), (0, 5), (6, 2), (1, 0), (8, 2), (2, 6), (0, 5), (0, 3), (0, 7), (4, 3), (0, 2), (7, 6), (9, 3), (8, 7), (5, 7), (7, 0), (1, 8), (9, 7), (3, 7), (6, 1), (0, 8), (9, 0), (4, 5), (2, 6), (5, 9), (5, 8), (8, 7), (8, 0), (1, 5)]
        let capacities: [Int] = [1, 3, 3, 5, 3, 5, 3, 5, 4, 4, 4, 5, 3, 1, 5, 1, 5, 5, 1, 3, 3, 4, 1, 4, 1, 3, 3, 4, 2, 3]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [7, 6, 7, 7, 5, 6, 0, 4, 7, -1, 0, -3, -1, -3, 1, 9, 3, 5, 2, 1, 5, 4, 7, 4, -1, 7, 7, 0, -3, 8]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 33)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [7, 6, 7, 7, 5, 6, 0, 4, 7, -1, 0, -3, -1, -3, 1, 9, 3, 5, 2, 1, 5, 4, 7, 4, -1, 7, 7, 0, -3, 8]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 33)
            #expect(flowResult.value == 3)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0] as [Int])
        }
    }

    @Test("FL-488 Int.max capacities, a negative cycle: both arcs near Int.max (only the solver's own arcs are unbounded), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl488() throws {
        // V [0, 1]; E [0→1 9223372036854775807 @0, 1→0 9223372036854775807 @-1]; supply [0: 5, 1: -5]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [9223372036854775807, 9223372036854775807]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [0, -1]
            let supplies: [Int] = [5, -5]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -9223372036854775802)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [9223372036854775807, 9223372036854775802] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [0, -1]
            let supplies: [Int] = [5, -5]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -9223372036854775802)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [9223372036854775807, 9223372036854775802] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [0, -1]
            let supplies: [Int] = [5, -5]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -9223372036854775802)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [9223372036854775807, 9223372036854775802] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [0, -1]
            let supplies: [Int] = [5, -5]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -9223372036854775802)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [9223372036854775807, 9223372036854775802] as [Int])
        }
    }

    @Test("FL-489 Int.max capacities, the negative arc first, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl489() throws {
        // V [0, 1]; E [0→1 9223372036854775807 @-1, 1→0 9223372036854775807 @0]; supply [0: 5, 1: -5]; minimumCostFlow(supply:capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [9223372036854775807, 9223372036854775807]
        do { // DirectedPseudograph
            let vertexList = [0, 1] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [-1, 0]
            let supplies: [Int] = [5, -5]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -9223372036854775807)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [9223372036854775807, 9223372036854775802] as [Int])
        }
        do { // no indices
            let vertexList = [0, 1] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [-1, 0]
            let supplies: [Int] = [5, -5]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -9223372036854775807)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [9223372036854775807, 9223372036854775802] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-1, 0]
            let supplies: [Int] = [5, -5]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -9223372036854775807)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [9223372036854775807, 9223372036854775802] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-1, 0]
            let supplies: [Int] = [5, -5]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == -9223372036854775807)
            #expect(flowResult.value == 5)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [9223372036854775807, 9223372036854775802] as [Int])
        }
    }

    @Test("FL-490 Int.max capacity against a negative arc: the value is Int.max, so the negative arc cannot be used, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl490() {
        // V [1, 0]; E [0→1 3 @-2, 1→0 9223372036854775807 @0]; minimumCostMaximumFlow(from: 1, to: 0, capacity:cost:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [3, 9223372036854775807]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [1, 0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int] = [-2, 0]
            let flowResult = graph.minimumCostMaximumFlow(from: 1, to: 0, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 9223372036854775807)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 9223372036854775807] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [1, 0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int] = [-2, 0]
            let flowResult = graph.minimumCostMaximumFlow(from: 1, to: 0, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 9223372036854775807)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [0, 9223372036854775807] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(1, 0), (0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-2, 0]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 9223372036854775807)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 9223372036854775807] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(1, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int] = [-2, 0]
            let flowResult = graph.minimumCostMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            #expect(flowResult.cost == 0)
            #expect(flowResult.value == 9223372036854775807)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 9223372036854775807] as [Int])
        }
    }

    @Test("FL-491 Int8 costs on 130 vertices: no bound on (n + 1) × the greatest cost, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl491() throws {
        // Int8 V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,…
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int8] = [1]
        do { // DirectedPseudograph
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129] as [Int]
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let costs: [Int8] = [1]
            let supplies: [Int8] = [1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 1)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1] as [Int8])
        }
        do { // no indices
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129] as [Int]
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let costs: [Int8] = [1]
            let supplies: [Int8] = [1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[vertexList.firstIndex(of: $0)!] }, capacity: { capacities[$0] }, cost: { costs[$0] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 1)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: $0) } == [1] as [Int8])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 130, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int8] = [1]
            let supplies: [Int8] = [1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 1)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [1] as [Int8])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 130, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let costs: [Int8] = [1]
            let supplies: [Int8] = [1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[edgeOf[$0]!] }, cost: { costs[edgeOf[$0]!] })
            let flowResult = try #require(result)
            #expect(flowResult.cost == 1)
            #expect(flowResult.value == 1)
            #expect(pairs.indices.map { flowResult.flow(ofEdgeAt: positionOfEdge[$0]) } == [1] as [Int8])
        }
    }
}
