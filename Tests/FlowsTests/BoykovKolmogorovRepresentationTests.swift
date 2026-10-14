// The catalog's rows again on other representations: directed rows on `DirectedPseudograph` (or
// `ReferenceDirectedMultigraph` for rows already on it), a file-private conformer with no vertex or
// edge indices, and, without a repeated edge, `CompressedSparseRow` and `AdjacencyMatrix` on the
// vertex indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and,
// without a repeated edge, `AdjacencyList.undirectedView` (each edge an arc as written) and
// `AdjacencyMatrix.undirectedView`. CompressedSparseRow and AdjacencyMatrix number edges by
// row-major cell, so there each catalog edge's position is looked up, a cut's edges are listed in
// that order, and Edmonds–Karp's flow (which follows positions) was recomputed by swiftgen.py with
// ref.py's model on those positions. Everything else is the catalog's. See README.md.

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

@Suite("boykovKolmogorovMaximumFlow on every representation")
struct BoykovKolmogorovRepresentationTests {
    @Test("FL-532 one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl532() {
        // V [0, 1]; E [0→1 5]; boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [5]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 5)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 5)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 5)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 5)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 5)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 5)
        }
    }

    @Test("FL-533 no edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl533() {
        // V [0, 1]; E []; boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [] as [Int])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-534 no path: disconnected, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl534() {
        // V [0, 1, 2, 3]; E [0→1 4, 2→3 4]; boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let capacities: [Int] = [4, 4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [] as [Int])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-535 zero capacities on the only path, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl535() {
        // V [0, 1, 2]; E [0→1 3, 1→2 0]; boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [3, 0]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [1] as [Int])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [1] as [Int])
            #expect(cut.value == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1] as [Int])
            #expect(cut.value == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1] as [Int])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-536 self-loop ignored, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl536() {
        // V [0, 1]; E [0→0 9, 0→1 4, 1→1 9]; boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
        let capacities: [Int] = [9, 4, 9]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [1] as [Int])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [1] as [Int])
            #expect(cut.value == 4)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1] as [Int])
            #expect(cut.value == 4)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1] as [Int])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-537 parallel edges add, on ReferenceDirectedMultigraph, no indices")
    func fl537() {
        // V [0, 1, 2]; E [0→1 2, 0→1 3, 1→2 1, 1→2 9]; boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (1, 2)]
        let capacities: [Int] = [2, 3, 1, 9]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges == [0, 1] as [Int])
            #expect(cut.value == 5)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges == [0, 1] as [Int])
            #expect(cut.value == 5)
        }
    }

    @Test("FL-538 antiparallel pair on the path, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl538() {
        // V [0, 1, 2, 3]; E [0→1 3, 0→2 3, 1→2 2, 2→1 2, 1→3 1, 2→3 5]; boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (2, 3)]
        let capacities: [Int] = [3, 3, 2, 2, 1, 5]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 6)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges == [4, 5] as [Int])
            #expect(cut.value == 6)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 6)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges == [4, 5] as [Int])
            #expect(cut.value == 6)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 6)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [4, 5] as [Int])
            #expect(cut.value == 6)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 6)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [4, 5] as [Int])
            #expect(cut.value == 6)
        }
    }

    @Test("FL-539 CLRS figure 26.1, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl539() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v3 12, v2→v1 4, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; boykovKolmogorovMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 23)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s", "v1", "v2", "v4"] as [String])
            #expect(Array(cut.sinkSide) == ["v3", "t"] as [String])
            #expect(cut.edges == [2, 7, 8] as [Int])
            #expect(cut.value == 23)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 23)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s", "v1", "v2", "v4"] as [String])
            #expect(Array(cut.sinkSide) == ["v3", "t"] as [String])
            #expect(cut.edges == [2, 7, 8] as [Int])
            #expect(cut.value == 23)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 23)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
            #expect(Array(cut.sinkSide) == [3, 5] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2, 7, 8] as [Int])
            #expect(cut.value == 23)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 23)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
            #expect(Array(cut.sinkSide) == [3, 5] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2, 7, 8] as [Int])
            #expect(cut.value == 23)
        }
    }

    @Test("FL-540 Ford–Fulkerson's slow case, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl540() {
        // V [s, a, b, t]; E [s→a 1000, s→b 1000, a→b 1, a→t 1000, b→t 1000]; boykovKolmogorovMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("s", "b"), ("a", "b"), ("a", "t"), ("b", "t")]
        let capacities: [Int] = [1000, 1000, 1, 1000, 1000]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "a", "b", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 2000)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s", "a", "b"] as [String])
            #expect(Array(cut.sinkSide) == ["t"] as [String])
            #expect(cut.edges == [3, 4] as [Int])
            #expect(cut.value == 2000)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "a", "b", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 2000)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s", "a", "b"] as [String])
            #expect(Array(cut.sinkSide) == ["t"] as [String])
            #expect(cut.edges == [3, 4] as [Int])
            #expect(cut.value == 2000)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2000)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [3, 4] as [Int])
            #expect(cut.value == 2000)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2000)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [3, 4] as [Int])
            #expect(cut.value == 2000)
        }
    }

    @Test("FL-541 NetworkX docs example, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl541() {
        // Double V [x, a, b, c, d, e, y]; E [x→a 3.0, x→b 1.0, a→c 3.0, b→c 5.0, b→d 4.0, d→e 2.0, c→y 2.0, e→y 3.0]; boykovKolmogorovMaximumFlow(from: x, to: y, capacity:)
        let pairs: [(String, String)] = [("x", "a"), ("x", "b"), ("a", "c"), ("b", "c"), ("b", "d"), ("d", "e"), ("c", "y"), ("e", "y")]
        let capacities: [Double] = [3.0, 1.0, 3.0, 5.0, 4.0, 2.0, 2.0, 3.0]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["x", "a", "b", "c", "d", "e", "y"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: "x", to: "y", capacity: { capacities[$0] })
            #expect(flow.value == 3.0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["x", "a", "c"] as [String])
            #expect(Array(cut.sinkSide) == ["b", "d", "e", "y"] as [String])
            #expect(cut.edges == [1, 6] as [Int])
            #expect(cut.value == 3.0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["x", "a", "b", "c", "d", "e", "y"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: "x", to: "y", capacity: { capacities[$0] })
            #expect(flow.value == 3.0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["x", "a", "c"] as [String])
            #expect(Array(cut.sinkSide) == ["b", "d", "e", "y"] as [String])
            #expect(cut.edges == [1, 6] as [Int])
            #expect(cut.value == 3.0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (2, 4), (4, 5), (3, 6), (5, 6)]
            let graph = CompressedSparseRow(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 6, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3.0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 3] as [Int])
            #expect(Array(cut.sinkSide) == [2, 4, 5, 6] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1, 6] as [Int])
            #expect(cut.value == 3.0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (2, 4), (4, 5), (3, 6), (5, 6)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 6, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3.0)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 3] as [Int])
            #expect(Array(cut.sinkSide) == [2, 4, 5, 6] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1, 6] as [Int])
            #expect(cut.value == 3.0)
        }
    }

    @Test("FL-542 trees meet in the middle, then orphans re-adopt, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl542() {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0→1 4, 0→2 4, 1→3 2, 2→3 2, 3→4 3, 4→5 2, 4→6 2, 5→7 4, 6→7 4, 1→4 1, 2→5 1]; boykovKolmogorovMaximumFlow(from: 0, to: 7, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4), (4, 5), (4, 6), (5, 7), (6, 7), (1, 4), (2, 5)]
        let capacities: [Int] = [4, 4, 2, 2, 3, 2, 2, 4, 4, 1, 1]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 7, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4] as [Int])
            #expect(Array(cut.sinkSide) == [5, 6, 7] as [Int])
            #expect(cut.edges == [5, 6, 10] as [Int])
            #expect(cut.value == 5)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 7, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4] as [Int])
            #expect(Array(cut.sinkSide) == [5, 6, 7] as [Int])
            #expect(cut.edges == [5, 6, 10] as [Int])
            #expect(cut.value == 5)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4), (4, 5), (4, 6), (5, 7), (6, 7), (1, 4), (2, 5)]
            let graph = CompressedSparseRow(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 7, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 5)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4] as [Int])
            #expect(Array(cut.sinkSide) == [5, 6, 7] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [10, 5, 6] as [Int])
            #expect(cut.value == 5)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4), (4, 5), (4, 6), (5, 7), (6, 7), (1, 4), (2, 5)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 7, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 5)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4] as [Int])
            #expect(Array(cut.sinkSide) == [5, 6, 7] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [10, 5, 6] as [Int])
            #expect(cut.value == 5)
        }
    }

    @Test("FL-543 lcgnet(10,30,10,20), on ReferenceDirectedMultigraph, no indices")
    func fl543() {
        // lcgnet(10,30,10,20); boykovKolmogorovMaximumFlow(from: 0, to: 9, capacity:)
        let pairs: [(Int, Int)] = [(9, 2), (9, 5), (5, 7), (5, 9), (2, 6), (0, 8), (1, 3), (8, 7), (4, 5), (0, 9), (4, 9), (7, 5), (0, 1), (9, 2), (3, 2), (4, 5), (6, 5), (2, 6), (7, 6), (0, 5), (5, 6), (1, 9), (5, 0), (6, 2), (1, 5), (8, 1), (2, 4), (4, 6), (6, 0), (3, 0)]
        let capacities: [Int] = [4, 16, 7, 10, 8, 7, 3, 5, 12, 12, 5, 6, 12, 19, 18, 6, 19, 20, 10, 5, 5, 2, 13, 10, 2, 19, 8, 17, 1, 14]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] })
            #expect(flow.value == 29)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(Array(cut.sinkSide) == [9] as [Int])
            #expect(cut.edges == [3, 9, 10, 21] as [Int])
            #expect(cut.value == 29)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] })
            #expect(flow.value == 29)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(Array(cut.sinkSide) == [9] as [Int])
            #expect(cut.edges == [3, 9, 10, 21] as [Int])
            #expect(cut.value == 29)
        }
    }

    @Test("FL-544 lcgnet(16,60,4,100), on ReferenceDirectedMultigraph, no indices")
    func fl544() {
        // lcgnet(16,60,4,100); boykovKolmogorovMaximumFlow(from: 0, to: 15, capacity:)
        let pairs: [(Int, Int)] = [(10, 12), (11, 1), (1, 5), (8, 15), (14, 8), (7, 12), (0, 10), (7, 10), (13, 0), (13, 11), (3, 8), (8, 6), (1, 2), (2, 14), (5, 13), (15, 10), (0, 6), (3, 4), (12, 10), (10, 5), (4, 13), (5, 1), (3, 5), (5, 6), (12, 7), (8, 7), (0, 14), (13, 12), (2, 8), (0, 10), (14, 12), (4, 12), (12, 15), (11, 1), (9, 12), (5, 2), (13, 2), (8, 15), (14, 8), (8, 15), (9, 8), (15, 1), (11, 2), (13, 9), (8, 14), (15, 8), (11, 12), (8, 7), (14, 12), (9, 11), (12, 3), (5, 8), (13, 11), (12, 13), (9, 6), (12, 5), (1, 3), (14, 9), (10, 6), (5, 10)]
        let capacities: [Int] = [75, 8, 15, 15, 92, 98, 59, 79, 47, 1, 30, 36, 69, 55, 21, 4, 48, 32, 64, 42, 80, 45, 38, 70, 69, 63, 22, 30, 50, 89, 90, 37, 94, 80, 16, 2, 57, 12, 80, 46, 48, 22, 80, 23, 76, 61, 20, 2, 69, 62, 82, 44, 74, 52, 49, 62, 86, 76, 80, 62]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 15, capacity: { capacities[$0] })
            #expect(flow.value == 139)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 6, 10] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3, 4, 5, 7, 8, 9, 11, 12, 13, 14, 15] as [Int])
            #expect(cut.edges == [0, 19, 26] as [Int])
            #expect(cut.value == 139)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 15, capacity: { capacities[$0] })
            #expect(flow.value == 139)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 6, 10] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3, 4, 5, 7, 8, 9, 11, 12, 13, 14, 15] as [Int])
            #expect(cut.edges == [0, 19, 26] as [Int])
            #expect(cut.value == 139)
        }
    }

    @Test("FL-545 lcgnet(30,150,5,50), on ReferenceDirectedMultigraph, no indices")
    func fl545() {
        // lcgnet(30,150,5,50); boykovKolmogorovMaximumFlow(from: 0, to: 29, capacity:)
        let pairs: [(Int, Int)] = [(22, 23), (11, 29), (20, 24), (24, 18), (3, 17), (3, 22), (10, 4), (12, 21), (1, 24), (19, 20), (5, 3), (23, 15), (20, 11), (18, 10), (10, 0), (16, 8), (2, 20), (6, 0), (1, 7), (12, 21), (4, 16), (28, 2), (15, 29), (22, 28), (1, 22), (11, 28), (4, 25), (1, 7), (27, 22), (27, 28), (24, 25), (21, 17), (16, 5), (23, 19), (17, 3), (24, 5), (3, 27), (23, 1), (29, 15), (8, 23), (24, 13), (2, 13), (6, 19), (2, 28), (7, 17), (15, 24), (19, 15), (25, 10), (26, 0), (13, 29), (12, 14), (18, 13), (18, 21), (7, 27), (16, 9), (2, 7), (13, 12), (5, 19), (15, 5), (3, 4), (29, 12), (9, 2), (17, 23), (14, 23), (7, 28), (16, 17), (5, 27), (12, 29), (15, 8), (10, 19), (4, 18), (1, 11), (4, 2), (5, 20), (12, 14), (16, 4), (5, 13), (9, 1), (27, 2), (1, 0), (24, 7), (1, 14), (18, 11), (8, 0), (12, 16), (26, 24), (8, 4), (6, 7), (18, 13), (25, 14), (29, 16), (5, 22), (15, 20), (14, 20), (29, 15), (14, 28), (23, 17), (11, 5), (16, 2), (16, 2), (22, 10), (2, 9), (29, 3), (15, 16), (12, 5), (6, 19), (24, 26), (4, 21), (2, 17), (29, 5), (28, 10), (9, 10), (10, 21), (2, 22), (5, 13), (1, 15), (19, 26), (24, 2), (7, 28), (0, 12), (3, 5), (11, 23), (17, 7), (7, 11), (1, 12), (17, 9), (0, 21), (27, 29), (5, 13), (5, 28), (18, 23), (5, 14), (16, 13), (24, 18), (17, 22), (6, 1), (2, 7), (12, 17), (14, 6), (23, 12), (7, 1), (15, 6), (10, 29), (3, 29), (9, 7), (19, 15), (13, 7), (26, 9), (0, 25), (1, 3)]
        let capacities: [Int] = [35, 10, 6, 22, 19, 41, 29, 15, 20, 40, 16, 40, 15, 35, 5, 25, 18, 1, 42, 26, 22, 41, 12, 20, 43, 31, 18, 2, 43, 17, 9, 15, 2, 11, 45, 9, 49, 26, 24, 13, 6, 4, 25, 3, 13, 8, 41, 3, 20, 35, 22, 40, 33, 5, 44, 32, 22, 15, 13, 32, 41, 34, 31, 3, 28, 17, 12, 6, 48, 45, 42, 37, 41, 26, 20, 2, 19, 31, 17, 46, 20, 20, 46, 28, 46, 20, 11, 27, 8, 16, 4, 9, 47, 27, 19, 10, 28, 27, 36, 43, 18, 11, 47, 22, 48, 49, 48, 18, 22, 44, 17, 28, 5, 49, 25, 6, 13, 37, 44, 7, 6, 44, 18, 3, 49, 48, 6, 17, 42, 32, 3, 40, 45, 48, 35, 20, 22, 49, 48, 47, 42, 48, 47, 29, 42, 48, 13, 7, 24, 25]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 29, capacity: { capacities[$0] })
            #expect(flow.value == 32)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 25] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28, 29] as [Int])
            #expect(cut.edges == [47, 89, 119, 126] as [Int])
            #expect(cut.value == 32)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 29, capacity: { capacities[$0] })
            #expect(flow.value == 32)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 25] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28, 29] as [Int])
            #expect(cut.edges == [47, 89, 119, 126] as [Int])
            #expect(cut.value == 32)
        }
    }

    @Test("FL-546 Double, dyadic, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl546() {
        // Double V [0, 1, 2, 3]; E [0→1 0.5, 0→2 0.75, 1→3 0.25, 2→3 1.0, 1→2 0.125]; boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)]
        let capacities: [Double] = [0.5, 0.75, 0.25, 1.0, 0.125]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 1.125)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges == [1, 2, 4] as [Int])
            #expect(cut.value == 1.125)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 1.125)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges == [1, 2, 4] as [Int])
            #expect(cut.value == 1.125)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 1.125)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1, 4, 2] as [Int])
            #expect(cut.value == 1.125)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 1.125)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1, 4, 2] as [Int])
            #expect(cut.value == 1.125)
        }
    }

    @Test("FL-547 UInt8, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl547() {
        // UInt8 V [0, 1, 2]; E [0→1 200, 1→2 50, 0→2 5]; boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let capacities: [UInt8] = [200, 50, 5]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 55)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [1, 2] as [Int])
            #expect(cut.value == 55)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 55)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [1, 2] as [Int])
            #expect(cut.value == 55)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 55)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2, 1] as [Int])
            #expect(cut.value == 55)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 55)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2, 1] as [Int])
            #expect(cut.value == 55)
        }
    }

    @Test("FL-548 undirected: an edge used against its order, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl548() {
        // undirected V [0, 1, 2, 3]; E [0–1 4, 2–1 4, 2–3 4, 0–2 1]; boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 1), (2, 3), (0, 2)]
        let capacities: [Int] = [4, 4, 4, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2"] as [String])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (2, 1), (2, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["2"] as [String])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-549 undirected: parallel edges and a loop, on ReferencePseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl549() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–0 2, 1–1 7, 1–2 9]; boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 1), (1, 2)]
        let capacities: [Int] = [2, 2, 7, 9]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r"] as [String])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["0", "1r"] as [String])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-550 undirected grid(4,4), unit, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl550() {
        // grid(4,4); boykovKolmogorovMaximumFlow(from: 0, to: 15, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 15, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14] as [Int])
            #expect(Array(cut.sinkSide) == [15] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["20", "23"] as [String])
            #expect(cut.value == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 15, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14] as [Int])
            #expect(Array(cut.sinkSide) == [15] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["20", "23"] as [String])
            #expect(cut.value == 2)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 15, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14] as [Int])
            #expect(Array(cut.sinkSide) == [15] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["20", "23"] as [String])
            #expect(cut.value == 2)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
            let graph = AdjacencyMatrix(vertexCount: 16, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 15, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14] as [Int])
            #expect(Array(cut.sinkSide) == [15] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["20", "23"] as [String])
            #expect(cut.value == 2)
        }
    }

    @Test("FL-551 undirected lcgund(10,25,6,9), on ReferencePseudograph, no indices")
    func fl551() {
        // lcgund(10,25,6,9); boykovKolmogorovMaximumFlow(from: 0, to: 9, capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (9, 4), (4, 9), (4, 0), (5, 0), (1, 3), (3, 4), (4, 7), (5, 6), (6, 1), (2, 4), (0, 7), (0, 7), (1, 3), (0, 2), (0, 7), (6, 1), (2, 6), (9, 1), (4, 0), (8, 4), (1, 0), (4, 2), (2, 3), (8, 1)]
        let capacities: [Int] = [4, 3, 9, 8, 8, 2, 7, 5, 2, 5, 8, 6, 4, 6, 7, 9, 4, 5, 3, 7, 2, 3, 7, 7, 1]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] })
            #expect(flow.value == 15)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(Array(cut.sinkSide) == [9] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1r", "2", "18r"] as [String])
            #expect(cut.value == 15)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.boykovKolmogorovMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] })
            #expect(flow.value == 15)
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(Array(cut.sinkSide) == [9] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1r", "2", "18r"] as [String])
            #expect(cut.value == 15)
        }
    }
}
