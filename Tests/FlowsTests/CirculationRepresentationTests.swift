// The catalog's rows again on other representations: directed rows on `DirectedPseudograph` (or
// `ReferenceDirectedMultigraph` for rows already on it), a file-private conformer with no vertex or
// edge indices, and, without a repeated edge, `CompressedSparseRow` and `AdjacencyMatrix` on the
// vertex indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and,
// without a repeated edge, `AdjacencyList.undirectedView` (each edge an arc as written) and
// `AdjacencyMatrix.undirectedView`. CompressedSparseRow and AdjacencyMatrix number edges by
// row-major cell, so there each catalog edge's position is looked up, a cut's edges are listed in
// that order, and Edmonds–Karp's flow (which follows positions) was recomputed by swiftgen.py with
// ref.py's model on those positions. Everything else is the catalog's. See README.md.

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

@Suite("Feasible flows on every representation")
struct CirculationRepresentationTests {
    @Test("FL-570 no vertices, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl570() throws {
        // V []; E []; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = []
        let lowerBounds: [Int] = []
        let capacities: [Int] = []
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let graph = CompressedSparseRow(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("FL-571 no edges, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl571() throws {
        // V [0, 1]; E []; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = []
        let lowerBounds: [Int] = []
        let capacities: [Int] = []
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("FL-572 cycle within its bounds: 2 on every edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl572() throws {
        // V [0, 1, 2]; E [0→1 1..3, 1→2 2..4, 2→0 0..5]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let lowerBounds: [Int] = [1, 2, 0]
        let capacities: [Int] = [3, 4, 5]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("FL-573 cycle, one lower bound past another's capacity, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl573() {
        // V [0, 1, 2]; E [0→1 4..6, 1→2 0..3, 2→0 0..9]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let lowerBounds: [Int] = [4, 0, 0]
        let capacities: [Int] = [6, 3, 9]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == [1] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == [1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == [1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == [1] as [Int])
        }
    }

    @Test("FL-574 a lower bound on an edge no cycle carries, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl574() {
        // V [0, 1]; E [0→1 1..2]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let lowerBounds: [Int] = [1]
        let capacities: [Int] = [2]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == [1] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == [1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == [1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == [1] as [Int])
        }
    }

    @Test("FL-575 zero lower bounds: the zero flow, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl575() throws {
        // V [0, 1, 2]; E [0→1 0..3, 1→2 0..3]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let lowerBounds: [Int] = [0, 0]
        let capacities: [Int] = [3, 3]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("FL-576 self-loop carries its lower bound, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl576() throws {
        // V [0, 1]; E [0→0 2..5, 0→1 0..1, 1→0 0..1]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
        let lowerBounds: [Int] = [2, 0, 0]
        let capacities: [Int] = [5, 1, 1]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("FL-577 parallel edges share the demand, on ReferenceDirectedMultigraph, no indices")
    func fl577() throws {
        // V [0, 1]; E [0→1 1..1, 0→1 0..2, 1→0 3..3]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let lowerBounds: [Int] = [1, 0, 3]
        let capacities: [Int] = [1, 2, 3]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
    }

    @Test("FL-578 two cycles through a bottleneck, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl578() {
        // V [a, b, c, d]; E [a→b 2..4, b→a 0..1, b→c 0..1, c→d 1..3, d→c 1..3, c→b 0..5]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(String, String)] = [("a", "b"), ("b", "a"), ("b", "c"), ("c", "d"), ("d", "c"), ("c", "b")]
        let lowerBounds: [Int] = [2, 0, 0, 1, 1, 0]
        let capacities: [Int] = [4, 1, 1, 3, 3, 5]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["a", "b", "c", "d"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == ["b", "c", "d"] as [String])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "b", "c", "d"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == ["b", "c", "d"] as [String])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 3), (3, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == [1, 2, 3] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 3), (3, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == [1, 2, 3] as [Int])
        }
    }

    @Test("FL-579 supplies: a feasible transport, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl579() throws {
        // V [s, a, b, t]; E [s→a 1..3, s→b 0..2, a→t 0..3, b→t 1..2, a→b 0..1]; supply [s: 4, t: -4]; feasibleCirculation(supply:lowerBound:capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("s", "b"), ("a", "t"), ("b", "t"), ("a", "b")]
        let lowerBounds: [Int] = [1, 0, 0, 1, 0]
        let capacities: [Int] = [3, 2, 3, 2, 1]
        let supplies: [Int] = [4, 0, 0, -4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "a", "b", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = ["s", "a", "b", "t"] as [String]
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "a", "b", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = ["s", "a", "b", "t"] as [String]
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("FL-580 supplies: the source cannot send its supply: barrier {s}, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl580() {
        // V [s, a, t]; E [s→a 0..2, a→t 0..5]; supply [s: 3, t: -3]; feasibleCirculation(supply:lowerBound:capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("a", "t")]
        let lowerBounds: [Int] = [0, 0]
        let capacities: [Int] = [2, 5]
        let supplies: [Int] = [3, 0, -3]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "a", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = ["s", "a", "t"] as [String]
            #expect(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == ["s"] as [String])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "a", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = ["s", "a", "t"] as [String]
            #expect(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == ["s"] as [String])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(graph.feasibleCirculation(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
            #expect(graph.findCirculationBarrier(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == [0] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(graph.feasibleCirculation(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
            #expect(graph.findCirculationBarrier(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == [0] as [Int])
        }
    }

    @Test("FL-581 supplies: a lower bound above the supply, returned on a back edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl581() throws {
        // V [s, a, t]; E [s→a 0..4, a→t 3..4, t→a 0..1]; supply [s: 2, t: -2]; feasibleCirculation(supply:lowerBound:capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("a", "t"), ("t", "a")]
        let lowerBounds: [Int] = [0, 3, 0]
        let capacities: [Int] = [4, 4, 1]
        let supplies: [Int] = [2, 0, -2]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "a", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = ["s", "a", "t"] as [String]
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "a", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = ["s", "a", "t"] as [String]
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("FL-582 supplies with zero lower bounds: a transportation problem, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl582() throws {
        // V [0, 1, 2, 3, 4]; E [0→2 0..2, 0→3 0..2, 1→3 0..1, 1→4 0..3, 2→4 0..1]; supply [0: 3, 1: 2, 2: -1, 3: -2, 4: -2]; feasibleCirculation(supply:lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 3), (1, 4), (2, 4)]
        let lowerBounds: [Int] = [0, 0, 0, 0, 0]
        let capacities: [Int] = [2, 2, 1, 3, 1]
        let supplies: [Int] = [3, 2, -1, -2, -2]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = [0, 1, 2, 3, 4] as [Int]
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = [0, 1, 2, 3, 4] as [Int]
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 3), (1, 4), (2, 4)]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 3), (1, 4), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[$0] }, lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("FL-583 negative lower bound: flow against the edge, on ReferenceDirectedMultigraph, no indices")
    func fl583() throws {
        // V [0, 1]; E [0→1 -3..-1, 0→1 0..2]; supply [0: -1, 1: 1]; feasibleCirculation(supply:lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let lowerBounds: [Int] = [-3, 0]
        let capacities: [Int] = [-1, 2]
        let supplies: [Int] = [-1, 1]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = [0, 1] as [Int]
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = [0, 1] as [Int]
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
    }

    @Test("FL-584 Double bounds, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl584() throws {
        // Double V [0, 1, 2]; E [0→1 0.5..1.5, 1→2 0.25..1.0, 2→0 0.75..2.0]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let lowerBounds: [Double] = [0.5, 0.25, 0.75]
        let capacities: [Double] = [1.5, 1.0, 2.0]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let circulation = try #require(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: positionOfEdge[$0]) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
        }
    }

    @Test("FL-585 Double, infeasible, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl585() {
        // Double V [0, 1, 2]; E [0→1 1.25..1.5, 1→2 0.25..1.0, 2→0 0.0..2.0]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let lowerBounds: [Double] = [1.25, 0.25, 0.0]
        let capacities: [Double] = [1.5, 1.0, 2.0]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == [1] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == [1] as [Int])
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == [1] as [Int])
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[edgeOf[$0]!] }, capacity: { capacities[edgeOf[$0]!] }) == [1] as [Int])
        }
    }

    @Test("FL-586 lcg(8 vertices, 20 edges, seed 77), on ReferenceDirectedMultigraph, no indices")
    func fl586() {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [7→5 2..4, 3→6 2..3, 1→4 1..2, 3→3 0..1, 7→2 2..3, 3→7 0..1, 2→1 0..3, 2→1 1..3, 1→4 0..2, 0→2 1..4, 7→6 0..0, 1→2 2..4, 2→3 1..1, 5→2 1..4, 2→6 0..2, 6→1 1..1, 0→4 2.…
        let pairs: [(Int, Int)] = [(7, 5), (3, 6), (1, 4), (3, 3), (7, 2), (3, 7), (2, 1), (2, 1), (1, 4), (0, 2), (7, 6), (1, 2), (2, 3), (5, 2), (2, 6), (6, 1), (0, 4), (0, 7), (3, 0), (3, 6)]
        let lowerBounds: [Int] = [2, 2, 1, 0, 2, 0, 0, 1, 0, 1, 0, 2, 1, 1, 0, 1, 2, 2, 1, 2]
        let capacities: [Int] = [4, 3, 2, 1, 3, 1, 3, 3, 2, 4, 0, 4, 1, 4, 2, 1, 4, 3, 1, 4]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == [1, 2, 4, 5, 6] as [Int])
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            #expect(graph.feasibleCirculation(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
            #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == [1, 2, 4, 5, 6] as [Int])
        }
    }

    @Test("FL-587 lcg(9 vertices, 24 edges, seed 5), with supplies, on ReferenceDirectedMultigraph, no indices")
    func fl587() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [7→8 0..1, 4→5 1..6, 5→6 1..6, 6→2 1..4, 2→3 0..1, 4→1 0..3, 0→5 1..6, 5→4 0..5, 8→3 1..5, 6→6 0..2, 8→0 0..5, 7→6 0..2, 2→1 0..1, 8→3 0..1, 4→7 1..4, 0→8 0..2, 1→7…
        let pairs: [(Int, Int)] = [(7, 8), (4, 5), (5, 6), (6, 2), (2, 3), (4, 1), (0, 5), (5, 4), (8, 3), (6, 6), (8, 0), (7, 6), (2, 1), (8, 3), (4, 7), (0, 8), (1, 7), (3, 8), (7, 2), (3, 5), (4, 4), (1, 5), (1, 0), (0, 4)]
        let lowerBounds: [Int] = [0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0]
        let capacities: [Int] = [1, 6, 6, 4, 1, 3, 6, 5, 5, 2, 5, 2, 1, 1, 4, 2, 1, 4, 4, 1, 3, 4, 2, 2]
        let supplies: [Int] = [4, 0, 0, -2, 0, 0, 0, 0, -2]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int]
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let vertexList = [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int]
            let circulation = try #require(graph.feasibleCirculation(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
            let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
            #expect(pairs.indices.allSatisfy { lowerBounds[$0] <= flows[$0] && flows[$0] <= capacities[$0] })
            #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
        }
    }
}
