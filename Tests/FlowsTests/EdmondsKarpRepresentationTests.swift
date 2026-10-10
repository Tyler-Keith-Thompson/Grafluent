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

@Suite("edmondsKarpMaximumFlow on every representation")
struct EdmondsKarpRepresentationTests {
    @Test("FL-002 one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl002() {
        // V [0, 1]; E [0→1 5]; edmondsKarpMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [5]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 5)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [5] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [5] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 5)
        }
    }

    @Test("FL-007 no edge: value 0, the sink alone on its side, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl007() {
        // V [0, 1]; E []; edmondsKarpMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [] as [Int])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-012 no path: edge into the source only, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl012() {
        // V [0, 1]; E [1→0 5]; edmondsKarpMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(1, 0)]
        let capacities: [Int] = [5]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [] as [Int])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-017 no path: disconnected, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl017() {
        // V [0, 1, 2, 3]; E [0→1 4, 2→3 4]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let capacities: [Int] = [4, 4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 0] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 0] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [] as [Int])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-022 zero capacity: a zero edge still crosses the cut, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl022() {
        // V [0, 1]; E [0→1 0]; edmondsKarpMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [0]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-027 zero capacities on the only path, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl027() {
        // V [0, 1, 2]; E [0→1 3, 1→2 0]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [3, 0]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [1] as [Int])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 0] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 0] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1] as [Int])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-032 path: the first bottleneck from the sink: every edge is a minimum cut; the one nearest t, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl032() {
        // V [0, 1, 2, 3]; E [0→1 2, 1→2 2, 2→3 2]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let capacities: [Int] = [2, 2, 2]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [2, 2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges == [2] as [Int])
            #expect(cut.value == 2)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [2, 2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges == [2] as [Int])
            #expect(cut.value == 2)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2] as [Int])
            #expect(cut.value == 2)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2] as [Int])
            #expect(cut.value == 2)
        }
    }

    @Test("FL-037 path with a later bottleneck, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl037() {
        // V [0, 1, 2, 3]; E [0→1 1, 1→2 3, 2→3 2]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let capacities: [Int] = [1, 3, 2]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 1)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 1)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 1)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 1)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 1)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 1)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 1)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 1)
        }
    }

    @Test("FL-042 source and sink not first and last, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl042() {
        // V [a, t, s]; E [s→a 2, a→t 3]; edmondsKarpMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("a", "t")]
        let capacities: [Int] = [2, 3]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["a", "t", "s"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s"] as [String])
            #expect(Array(cut.sinkSide) == ["a", "t"] as [String])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 2)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["a", "t", "s"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s"] as [String])
            #expect(Array(cut.sinkSide) == ["a", "t"] as [String])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 2)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(2, 0), (0, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 2, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [2] as [Int])
            #expect(Array(cut.sinkSide) == [0, 1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 2)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(2, 0), (0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 2, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [2] as [Int])
            #expect(Array(cut.sinkSide) == [0, 1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 2)
        }
    }

    @Test("FL-047 isolated extra vertex: unreachable vertices sit on the source side, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl047() {
        // V [0, 1, 2]; E [0→2 3]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 2)]
        let capacities: [Int] = [3]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [3] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 3)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [3] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 3)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [3] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 3)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [3] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 3)
        }
    }

    @Test("FL-052 vertex reaching only the sink: 1 can reach t: sink side, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl052() {
        // V [0, 1, 2]; E [0→2 3, 1→2 9]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
        let capacities: [Int] = [3, 9]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [3, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 3)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [3, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges == [0] as [Int])
            #expect(cut.value == 3)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [3, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 3)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [3, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0] as [Int])
            #expect(cut.value == 3)
        }
    }

    @Test("FL-057 dead end off the source, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl057() {
        // V [0, 1, 2]; E [0→1 7, 0→2 3]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
        let capacities: [Int] = [7, 3]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 3] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [1] as [Int])
            #expect(cut.value == 3)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 3] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [1] as [Int])
            #expect(cut.value == 3)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 3] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1] as [Int])
            #expect(cut.value == 3)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 3] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1] as [Int])
            #expect(cut.value == 3)
        }
    }

    @Test("FL-062 self-loop ignored: loops carry no flow, never cross, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl062() {
        // V [0, 1]; E [0→0 9, 0→1 4, 1→1 9]; edmondsKarpMaximumFlow(from: 0, to: 1, capacity:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
        let capacities: [Int] = [9, 4, 9]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 4, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges == [1] as [Int])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 4, 0] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 4, 0] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 4, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1] as [Int])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-067 parallel edges add, on ReferenceDirectedMultigraph, no indices")
    func fl067() {
        // V [0, 1, 2]; E [0→1 2, 0→1 3, 1→2 1, 1→2 9]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (1, 2)]
        let capacities: [Int] = [2, 3, 1, 9]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [2, 3, 1, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges == [0, 1] as [Int])
            #expect(cut.value == 5)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [2, 3, 1, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges == [0, 1] as [Int])
            #expect(cut.value == 5)
        }
    }

    @Test("FL-072 antiparallel pair: each arc its own reverse, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl072() {
        // V [0, 1, 2]; E [0→1 5, 1→0 3, 1→2 4]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let capacities: [Int] = [5, 3, 4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [4, 0, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [2] as [Int])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [4, 0, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [2] as [Int])
            #expect(cut.value == 4)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [4, 0, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2] as [Int])
            #expect(cut.value == 4)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [4, 0, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2] as [Int])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-077 antiparallel pair on the path, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl077() {
        // V [0, 1, 2, 3]; E [0→1 3, 0→2 3, 1→2 2, 2→1 2, 1→3 1, 2→3 5]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (2, 3)]
        let capacities: [Int] = [3, 3, 2, 2, 1, 5]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [3, 3, 2, 0, 1, 5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges == [4, 5] as [Int])
            #expect(cut.value == 6)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [3, 3, 2, 0, 1, 5] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [3, 3, 2, 0, 1, 5] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [3, 3, 2, 0, 1, 5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [4, 5] as [Int])
            #expect(cut.value == 6)
        }
    }

    @Test("FL-082 edge into the source and out of the sink, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl082() {
        // V [0, 1, 2]; E [1→0 4, 0→1 3, 2→1 6, 1→2 2, 2→0 8]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(1, 0), (0, 1), (2, 1), (1, 2), (2, 0)]
        let capacities: [Int] = [4, 3, 6, 2, 8]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 2, 0, 2, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [3] as [Int])
            #expect(cut.value == 2)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 2, 0, 2, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [3] as [Int])
            #expect(cut.value == 2)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(1, 0), (0, 1), (2, 1), (1, 2), (2, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 2, 0, 2, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [3] as [Int])
            #expect(cut.value == 2)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(1, 0), (0, 1), (2, 1), (1, 2), (2, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0, 2, 0, 2, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [3] as [Int])
            #expect(cut.value == 2)
        }
    }

    @Test("FL-087 CLRS figure 26.1: value 23, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl087() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v3 12, v2→v1 4, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; edmondsKarpMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 23)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [12, 11, 12, 0, 11, 0, 19, 7, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s", "v1", "v2", "v4"] as [String])
            #expect(Array(cut.sinkSide) == ["v3", "t"] as [String])
            #expect(cut.edges == [2, 7, 8] as [Int])
            #expect(cut.value == 23)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 23)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [12, 11, 12, 0, 11, 0, 19, 7, 4] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 23)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [12, 11, 12, 0, 11, 0, 19, 7, 4] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 23)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [12, 11, 12, 0, 11, 0, 19, 7, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
            #expect(Array(cut.sinkSide) == [3, 5] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2, 7, 8] as [Int])
            #expect(cut.value == 23)
        }
    }

    @Test("FL-092 CLRS 2nd ed., with v1⇄v2, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl092() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v2 10, v2→v1 4, v1→v3 12, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; edmondsKarpMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v2"), ("v2", "v1"), ("v1", "v3"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 10, 4, 12, 14, 9, 20, 7, 4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 23)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [12, 11, 0, 0, 12, 11, 0, 19, 7, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s", "v1", "v2", "v4"] as [String])
            #expect(Array(cut.sinkSide) == ["v3", "t"] as [String])
            #expect(cut.edges == [4, 8, 9] as [Int])
            #expect(cut.value == 23)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 23)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [12, 11, 0, 0, 12, 11, 0, 19, 7, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s", "v1", "v2", "v4"] as [String])
            #expect(Array(cut.sinkSide) == ["v3", "t"] as [String])
            #expect(cut.edges == [4, 8, 9] as [Int])
            #expect(cut.value == 23)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 23)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [12, 11, 0, 0, 12, 11, 0, 19, 7, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
            #expect(Array(cut.sinkSide) == [3, 5] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [4, 8, 9] as [Int])
            #expect(cut.value == 23)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 23)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [12, 11, 0, 0, 12, 11, 0, 19, 7, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
            #expect(Array(cut.sinkSide) == [3, 5] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [4, 8, 9] as [Int])
            #expect(cut.value == 23)
        }
    }

    @Test("FL-097 Ford–Fulkerson's slow case: Edmonds–Karp needs two augmentations, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl097() {
        // V [s, a, b, t]; E [s→a 1000, s→b 1000, a→b 1, a→t 1000, b→t 1000]; edmondsKarpMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("s", "b"), ("a", "b"), ("a", "t"), ("b", "t")]
        let capacities: [Int] = [1000, 1000, 1, 1000, 1000]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "a", "b", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 2000)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [1000, 1000, 0, 1000, 1000] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s", "a", "b"] as [String])
            #expect(Array(cut.sinkSide) == ["t"] as [String])
            #expect(cut.edges == [3, 4] as [Int])
            #expect(cut.value == 2000)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "a", "b", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 2000)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [1000, 1000, 0, 1000, 1000] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2000)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [1000, 1000, 0, 1000, 1000] as [Int])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2000)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [1000, 1000, 0, 1000, 1000] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [3, 4] as [Int])
            #expect(cut.value == 2000)
        }
    }

    @Test("FL-102 NetworkX docs example, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl102() {
        // Double V [x, a, b, c, d, e, y]; E [x→a 3.0, x→b 1.0, a→c 3.0, b→c 5.0, b→d 4.0, d→e 2.0, c→y 2.0, e→y 3.0]; edmondsKarpMaximumFlow(from: x, to: y, capacity:)
        let pairs: [(String, String)] = [("x", "a"), ("x", "b"), ("a", "c"), ("b", "c"), ("b", "d"), ("d", "e"), ("c", "y"), ("e", "y")]
        let capacities: [Double] = [3.0, 1.0, 3.0, 5.0, 4.0, 2.0, 2.0, 3.0]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["x", "a", "b", "c", "d", "e", "y"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: "x", to: "y", capacity: { capacities[$0] })
            #expect(flow.value == 3.0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [2.0, 1.0, 2.0, 0.0, 1.0, 1.0, 2.0, 1.0] as [Double])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["x", "a", "c"] as [String])
            #expect(Array(cut.sinkSide) == ["b", "d", "e", "y"] as [String])
            #expect(cut.edges == [1, 6] as [Int])
            #expect(cut.value == 3.0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["x", "a", "b", "c", "d", "e", "y"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: "x", to: "y", capacity: { capacities[$0] })
            #expect(flow.value == 3.0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [2.0, 1.0, 2.0, 0.0, 1.0, 1.0, 2.0, 1.0] as [Double])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 6, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3.0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [2.0, 1.0, 2.0, 0.0, 1.0, 1.0, 2.0, 1.0] as [Double])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 6, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3.0)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [2.0, 1.0, 2.0, 0.0, 1.0, 1.0, 2.0, 1.0] as [Double])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 3] as [Int])
            #expect(Array(cut.sinkSide) == [2, 4, 5, 6] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1, 6] as [Int])
            #expect(cut.value == 3.0)
        }
    }

    @Test("FL-107 diamond, two equal cuts, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl107() {
        // V [0, 1, 2, 3]; E [0→1 1, 0→2 1, 1→3 1, 2→3 1]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [1, 1, 1, 1]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [1, 1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges == [2, 3] as [Int])
            #expect(cut.value == 2)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [1, 1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges == [2, 3] as [Int])
            #expect(cut.value == 2)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2, 3] as [Int])
            #expect(cut.value == 2)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2, 3] as [Int])
            #expect(cut.value == 2)
        }
    }

    @Test("FL-112 cut not at either end, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl112() {
        // V [0, 1, 2, 3, 4, 5]; E [0→1 5, 0→2 5, 1→3 1, 2→4 1, 3→5 5, 4→5 5, 1→2 3]; edmondsKarpMaximumFlow(from: 0, to: 5, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 5), (4, 5), (1, 2)]
        let capacities: [Int] = [5, 5, 1, 1, 5, 5, 3]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [1, 1, 1, 1, 1, 1, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3, 4, 5] as [Int])
            #expect(cut.edges == [2, 3] as [Int])
            #expect(cut.value == 2)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [1, 1, 1, 1, 1, 1, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3, 4, 5] as [Int])
            #expect(cut.edges == [2, 3] as [Int])
            #expect(cut.value == 2)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 5), (4, 5), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 1, 1, 1, 1, 1, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3, 4, 5] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2, 3] as [Int])
            #expect(cut.value == 2)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 5), (4, 5), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 1, 1, 1, 1, 1, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3, 4, 5] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [2, 3] as [Int])
            #expect(cut.value == 2)
        }
    }

    @Test("FL-117 bipartite matching as flow, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl117() {
        // V [s, a, b, c, x, y, z, t]; E [s→a 1, s→b 1, s→c 1, a→x 1, a→y 1, b→x 1, c→x 1, c→z 1, x→t 1, y→t 1, z→t 1]; edmondsKarpMaximumFlow(from: s, to: t, capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("s", "b"), ("s", "c"), ("a", "x"), ("a", "y"), ("b", "x"), ("c", "x"), ("c", "z"), ("x", "t"), ("y", "t"), ("z", "t")]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "a", "b", "c", "x", "y", "z", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s", "a", "b", "c", "x", "y", "z"] as [String])
            #expect(Array(cut.sinkSide) == ["t"] as [String])
            #expect(cut.edges == [8, 9, 10] as [Int])
            #expect(cut.value == 3)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "a", "b", "c", "x", "y", "z", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: "s", to: "t", capacity: { capacities[$0] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["s", "a", "b", "c", "x", "y", "z"] as [String])
            #expect(Array(cut.sinkSide) == ["t"] as [String])
            #expect(cut.edges == [8, 9, 10] as [Int])
            #expect(cut.value == 3)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (1, 5), (2, 4), (3, 4), (3, 6), (4, 7), (5, 7), (6, 7)]
            let graph = CompressedSparseRow(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 7, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6] as [Int])
            #expect(Array(cut.sinkSide) == [7] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [8, 9, 10] as [Int])
            #expect(cut.value == 3)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (1, 5), (2, 4), (3, 4), (3, 6), (4, 7), (5, 7), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 7, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 3)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6] as [Int])
            #expect(Array(cut.sinkSide) == [7] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [8, 9, 10] as [Int])
            #expect(cut.value == 3)
        }
    }

    @Test("FL-122 lcgnet(8,20,8,9), on ReferenceDirectedMultigraph, no indices")
    func fl122() {
        // lcgnet(8,20,8,9); edmondsKarpMaximumFlow(from: 0, to: 7, capacity:)
        let pairs: [(Int, Int)] = [(4, 0), (3, 6), (2, 3), (5, 7), (6, 3), (0, 6), (6, 0), (1, 4), (5, 6), (3, 6), (0, 4), (2, 1), (0, 7), (1, 3), (5, 2), (6, 5), (0, 5), (0, 7), (0, 5), (3, 1)]
        let capacities: [Int] = [6, 6, 2, 2, 5, 6, 3, 5, 5, 7, 1, 5, 9, 9, 3, 4, 2, 2, 3, 1]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 7, capacity: { capacities[$0] })
            #expect(flow.value == 13)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 2, 2, 0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6] as [Int])
            #expect(Array(cut.sinkSide) == [7] as [Int])
            #expect(cut.edges == [3, 12, 17] as [Int])
            #expect(cut.value == 13)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 7, capacity: { capacities[$0] })
            #expect(flow.value == 13)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 2, 2, 0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6] as [Int])
            #expect(Array(cut.sinkSide) == [7] as [Int])
            #expect(cut.edges == [3, 12, 17] as [Int])
            #expect(cut.value == 13)
        }
    }

    @Test("FL-127 lcgnet(10,30,10,20), on ReferenceDirectedMultigraph, no indices")
    func fl127() {
        // lcgnet(10,30,10,20); edmondsKarpMaximumFlow(from: 0, to: 9, capacity:)
        let pairs: [(Int, Int)] = [(9, 2), (9, 5), (5, 7), (5, 9), (2, 6), (0, 8), (1, 3), (8, 7), (4, 5), (0, 9), (4, 9), (7, 5), (0, 1), (9, 2), (3, 2), (4, 5), (6, 5), (2, 6), (7, 6), (0, 5), (5, 6), (1, 9), (5, 0), (6, 2), (1, 5), (8, 1), (2, 4), (4, 6), (6, 0), (3, 0)]
        let capacities: [Int] = [4, 16, 7, 10, 8, 7, 3, 5, 12, 12, 5, 6, 12, 19, 18, 6, 19, 20, 10, 5, 5, 2, 13, 10, 2, 19, 8, 17, 1, 14]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] })
            #expect(flow.value == 29)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 0, 0, 10, 0, 5, 3, 5, 0, 12, 5, 3, 7, 0, 3, 0, 0, 0, 2, 5, 0, 2, 0, 2, 2, 0, 5, 0, 0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(Array(cut.sinkSide) == [9] as [Int])
            #expect(cut.edges == [3, 9, 10, 21] as [Int])
            #expect(cut.value == 29)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] })
            #expect(flow.value == 29)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 0, 0, 10, 0, 5, 3, 5, 0, 12, 5, 3, 7, 0, 3, 0, 0, 0, 2, 5, 0, 2, 0, 2, 2, 0, 5, 0, 0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(Array(cut.sinkSide) == [9] as [Int])
            #expect(cut.edges == [3, 9, 10, 21] as [Int])
            #expect(cut.value == 29)
        }
    }

    @Test("FL-132 lcgnet(12,40,3,5), on ReferenceDirectedMultigraph, no indices")
    func fl132() {
        // lcgnet(12,40,3,5); edmondsKarpMaximumFlow(from: 0, to: 11, capacity:)
        let pairs: [(Int, Int)] = [(11, 7), (10, 0), (7, 5), (9, 7), (8, 9), (5, 3), (7, 8), (10, 11), (5, 11), (7, 1), (1, 6), (7, 5), (9, 3), (9, 0), (0, 5), (2, 5), (1, 5), (5, 11), (8, 5), (2, 1), (11, 3), (1, 11), (0, 6), (2, 9), (7, 3), (3, 9), (9, 3), (0, 9), (10, 4), (9, 11), (2, 11), (3, 9), (2, 10), (4, 9), (9, 4), (5, 0), (8, 5), (11, 9), (11, 1), (11, 3)]
        let capacities: [Int] = [1, 4, 5, 3, 4, 5, 1, 2, 4, 5, 2, 4, 4, 2, 1, 2, 2, 2, 2, 1, 2, 5, 5, 1, 4, 5, 5, 4, 5, 1, 1, 4, 1, 1, 2, 5, 2, 1, 4, 2]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 11, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 0, 3, 3, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 3, 4, 6, 9] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 5, 7, 8, 10, 11] as [Int])
            #expect(cut.edges == [3, 14, 29] as [Int])
            #expect(cut.value == 5)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 11, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0, 0, 3, 3, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 3, 4, 6, 9] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 5, 7, 8, 10, 11] as [Int])
            #expect(cut.edges == [3, 14, 29] as [Int])
            #expect(cut.value == 5)
        }
    }

    @Test("FL-137 lcgnet(16,60,4,100), on ReferenceDirectedMultigraph, no indices")
    func fl137() {
        // lcgnet(16,60,4,100); edmondsKarpMaximumFlow(from: 0, to: 15, capacity:)
        let pairs: [(Int, Int)] = [(10, 12), (11, 1), (1, 5), (8, 15), (14, 8), (7, 12), (0, 10), (7, 10), (13, 0), (13, 11), (3, 8), (8, 6), (1, 2), (2, 14), (5, 13), (15, 10), (0, 6), (3, 4), (12, 10), (10, 5), (4, 13), (5, 1), (3, 5), (5, 6), (12, 7), (8, 7), (0, 14), (13, 12), (2, 8), (0, 10), (14, 12), (4, 12), (12, 15), (11, 1), (9, 12), (5, 2), (13, 2), (8, 15), (14, 8), (8, 15), (9, 8), (15, 1), (11, 2), (13, 9), (8, 14), (15, 8), (11, 12), (8, 7), (14, 12), (9, 11), (12, 3), (5, 8), (13, 11), (12, 13), (9, 6), (12, 5), (1, 3), (14, 9), (10, 6), (5, 10)]
        let capacities: [Int] = [75, 8, 15, 15, 92, 98, 59, 79, 47, 1, 30, 36, 69, 55, 21, 4, 48, 32, 64, 42, 80, 45, 38, 70, 69, 63, 22, 30, 50, 89, 90, 37, 94, 80, 16, 2, 57, 12, 80, 46, 48, 22, 80, 23, 76, 61, 20, 2, 69, 62, 82, 44, 74, 52, 49, 62, 86, 76, 80, 62]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 15, capacity: { capacities[$0] })
            #expect(flow.value == 139)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [75, 0, 0, 15, 22, 0, 59, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 22, 0, 0, 58, 0, 0, 75, 0, 0, 0, 0, 12, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 6, 10] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3, 4, 5, 7, 8, 9, 11, 12, 13, 14, 15] as [Int])
            #expect(cut.edges == [0, 19, 26] as [Int])
            #expect(cut.value == 139)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 15, capacity: { capacities[$0] })
            #expect(flow.value == 139)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [75, 0, 0, 15, 22, 0, 59, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 22, 0, 0, 58, 0, 0, 75, 0, 0, 0, 0, 12, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 6, 10] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3, 4, 5, 7, 8, 9, 11, 12, 13, 14, 15] as [Int])
            #expect(cut.edges == [0, 19, 26] as [Int])
            #expect(cut.value == 139)
        }
    }

    @Test("FL-147 Double, dyadic: exact in binary, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl147() {
        // Double V [0, 1, 2, 3]; E [0→1 0.5, 0→2 0.75, 1→3 0.25, 2→3 1.0, 1→2 0.125]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)]
        let capacities: [Double] = [0.5, 0.75, 0.25, 1.0, 0.125]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 1.125)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0.375, 0.75, 0.25, 0.875, 0.125] as [Double])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges == [1, 2, 4] as [Int])
            #expect(cut.value == 1.125)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 1.125)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [0.375, 0.75, 0.25, 0.875, 0.125] as [Double])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 1.125)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0.375, 0.75, 0.25, 0.875, 0.125] as [Double])
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
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 1.125)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [0.375, 0.75, 0.25, 0.875, 0.125] as [Double])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1, 4, 2] as [Int])
            #expect(cut.value == 1.125)
        }
    }

    @Test("FL-154 Double, irrational-like, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl154() {
        // Double V [0, 1, 2, 3]; E [0→1 1.4142135623730951, 0→2 1.7320508075688772, 1→2 1.0, 1→3 1.0, 2→3 2.0]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let capacities: [Double] = [1.4142135623730951, 1.7320508075688772, 1.0, 1.0, 2.0]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(abs(flow.value - 3.0) <= 1e-12)
            let expectedFlows: [Double] = [1.2679491924311228, 1.7320508075688772, 0.2679491924311228, 1.0, 2.0]
            #expect(zip(pairs.indices.map { flow.flow(ofEdgeAt: $0) }, expectedFlows).allSatisfy { abs($0 - $1) <= 1e-12 })
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges == [3, 4] as [Int])
            #expect(cut.value == 3.0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(abs(flow.value - 3.0) <= 1e-12)
            let expectedFlows: [Double] = [1.2679491924311228, 1.7320508075688772, 0.2679491924311228, 1.0, 2.0]
            #expect(zip(pairs.indices.map { flow.flow(ofEdgeAt: $0) }, expectedFlows).allSatisfy { abs($0 - $1) <= 1e-12 })
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges == [3, 4] as [Int])
            #expect(cut.value == 3.0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(abs(flow.value - 3.0) <= 1e-12)
            let expectedFlows: [Double] = [1.2679491924311228, 1.7320508075688772, 0.2679491924311228, 1.0, 2.0]
            #expect(zip(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) }, expectedFlows).allSatisfy { abs($0 - $1) <= 1e-12 })
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [3, 4] as [Int])
            #expect(cut.value == 3.0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(abs(flow.value - 3.0) <= 1e-12)
            let expectedFlows: [Double] = [1.2679491924311228, 1.7320508075688772, 0.2679491924311228, 1.0, 2.0]
            #expect(zip(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) }, expectedFlows).allSatisfy { abs($0 - $1) <= 1e-12 })
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [3, 4] as [Int])
            #expect(cut.value == 3.0)
        }
    }

    @Test("FL-157 Int8 near overflow: source capacities sum to Int8.max, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl157() {
        // Int8 V [0, 1, 2, 3]; E [0→1 100, 0→2 27, 1→3 127, 2→3 127]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let capacities: [Int8] = [100, 27, 127, 127]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 127)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [100, 27, 100, 27] as [Int8])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
            #expect(cut.edges == [0, 1] as [Int])
            #expect(cut.value == 127)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 127)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [100, 27, 100, 27] as [Int8])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
            #expect(cut.edges == [0, 1] as [Int])
            #expect(cut.value == 127)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 127)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [100, 27, 100, 27] as [Int8])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            #expect(cut.value == 127)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 127)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [100, 27, 100, 27] as [Int8])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2, 3] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [0, 1] as [Int])
            #expect(cut.value == 127)
        }
    }

    @Test("FL-162 Int, large: 2^63 - 1 total, Int.max, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl162() {
        // V [0, 1, 2]; E [0→1 4611686018427387904, 0→2 4611686018427387903, 1→2 4611686018427387904]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let capacities: [Int] = [4611686018427387904, 4611686018427387903, 4611686018427387904]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 9223372036854775807)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [4611686018427387904, 4611686018427387903, 4611686018427387904] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [1, 2] as [Int])
            #expect(cut.value == 9223372036854775807)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 9223372036854775807)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: $0) } == [4611686018427387904, 4611686018427387903, 4611686018427387904] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [1, 2] as [Int])
            #expect(cut.value == 9223372036854775807)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 9223372036854775807)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [4611686018427387904, 4611686018427387903, 4611686018427387904] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1, 2] as [Int])
            #expect(cut.value == 9223372036854775807)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 9223372036854775807)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: positionOfEdge[$0]) } == [4611686018427387904, 4611686018427387903, 4611686018427387904] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1, 2] as [Int])
            #expect(cut.value == 9223372036854775807)
        }
    }

    @Test("FL-165 undirected: one edge both ways: flow -5 on edge 0, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl165() {
        // undirected V [0, 1]; E [0–1 5]; edmondsKarpMaximumFlow(from: 1, to: 0, capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [5]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 1, to: 0, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [-5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0r"] as [String])
            #expect(cut.value == 5)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 1, to: 0, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [-5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0r"] as [String])
            #expect(cut.value == 5)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let flow = graph.edmondsKarpMaximumFlow(from: 1, to: 0, capacity: { capacities[$0] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [-5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0r"] as [String])
            #expect(cut.value == 5)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 1, to: 0, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 5)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: false)) - flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: true)) } == [-5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["0r"] as [String])
            #expect(cut.value == 5)
        }
    }

    @Test("FL-170 undirected path, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl170() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–2 3]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [2, 3]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
            #expect(cut.value == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
            #expect(cut.value == 2)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
            #expect(cut.value == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 2)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: false)) - flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: true)) } == [2, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["0"] as [String])
            #expect(cut.value == 2)
        }
    }

    @Test("FL-175 undirected: an edge used against its order, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl175() {
        // undirected V [0, 1, 2, 3]; E [0–1 4, 2–1 4, 2–3 4, 0–2 1]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 1), (2, 3), (0, 2)]
        let capacities: [Int] = [4, 4, 4, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [3, -3, 4, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2"] as [String])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [3, -3, 4, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [3, -3, 4, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 1), (2, 3), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: false)) - flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: true)) } == [3, -3, 4, 1] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["2"] as [String])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-180 undirected: parallel edges and a loop, on ReferencePseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl180() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–0 2, 1–1 7, 1–2 9]; edmondsKarpMaximumFlow(from: 0, to: 2, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 1), (1, 2)]
        let capacities: [Int] = [2, 2, 7, 9]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [2, -2, 0, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r"] as [String])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [2, -2, 0, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [2, -2, 0, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: false)) - flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: true)) } == [2, -2, 0, 4] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["0", "1r"] as [String])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-185 undirected: flows meet head on, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl185() {
        // undirected V [0, 1, 2, 3]; E [0–1 3, 0–2 3, 1–2 5, 1–3 1, 2–3 5]; edmondsKarpMaximumFlow(from: 0, to: 3, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let capacities: [Int] = [3, 3, 5, 1, 5]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [3, 3, 2, 1, 5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["3", "4"] as [String])
            #expect(cut.value == 6)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [3, 3, 2, 1, 5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["3", "4"] as [String])
            #expect(cut.value == 6)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[$0] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [3, 3, 2, 1, 5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["3", "4"] as [String])
            #expect(cut.value == 6)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 3, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: false)) - flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: true)) } == [3, 3, 2, 1, 5] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["3", "4"] as [String])
            #expect(cut.value == 6)
        }
    }

    @Test("FL-190 undirected Stoer–Wagner paper graph, 1 to 8, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl190() {
        // undirected V [1, 2, 3, 4, 5, 6, 7, 8]; E [1–2 2, 1–5 3, 2–3 3, 2–5 2, 2–6 2, 3–4 4, 3–7 2, 4–7 2, 4–8 2, 5–6 3, 6–7 1, 7–8 3]; edmondsKarpMaximumFlow(from: 1, to: 8, capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (2, 3), (2, 5), (2, 6), (3, 4), (3, 7), (4, 7), (4, 8), (5, 6), (6, 7), (7, 8)]
        let capacities: [Int] = [2, 3, 3, 2, 2, 4, 2, 2, 2, 3, 1, 3]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 1, to: 8, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [2, 2, 3, -1, 0, 2, 1, 0, 2, 1, 1, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [1, 2, 5, 6] as [Int])
            #expect(Array(cut.sinkSide) == [3, 4, 7, 8] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2", "10"] as [String])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 1, to: 8, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [2, 2, 3, -1, 0, 2, 1, 0, 2, 1, 1, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [1, 2, 5, 6] as [Int])
            #expect(Array(cut.sinkSide) == [3, 4, 7, 8] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2", "10"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let flow = graph.edmondsKarpMaximumFlow(from: 1, to: 8, capacity: { capacities[$0] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [2, 2, 3, -1, 0, 2, 1, 0, 2, 1, 1, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [1, 2, 5, 6] as [Int])
            #expect(Array(cut.sinkSide) == [3, 4, 7, 8] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2", "10"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 4), (1, 5), (2, 3), (2, 6), (3, 6), (3, 7), (4, 5), (5, 6), (6, 7)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 7, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 4)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: false)) - flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: true)) } == [2, 2, 3, -1, 0, 2, 1, 0, 2, 1, 1, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 4, 5] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3, 6, 7] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["2", "10"] as [String])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-195 undirected Wikipedia Gomory–Hu graph, 0 to 5, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl195() {
        // undirected V [0, 1, 2, 3, 4, 5]; E [0–1 1, 0–2 7, 1–2 1, 1–3 3, 1–4 2, 2–4 4, 3–4 1, 3–5 6, 4–5 2]; edmondsKarpMaximumFlow(from: 0, to: 5, capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
        let capacities: [Int] = [1, 7, 1, 3, 2, 4, 1, 6, 2]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[$0] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [1, 5, -1, 3, -1, 4, -1, 4, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
            #expect(Array(cut.sinkSide) == [3, 5] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["3", "6r", "8"] as [String])
            #expect(cut.value == 6)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[$0] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [1, 5, -1, 3, -1, 4, -1, 4, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
            #expect(Array(cut.sinkSide) == [3, 5] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["3", "6r", "8"] as [String])
            #expect(cut.value == 6)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[$0] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [1, 5, -1, 3, -1, 4, -1, 4, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
            #expect(Array(cut.sinkSide) == [3, 5] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["3", "6r", "8"] as [String])
            #expect(cut.value == 6)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 6)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: false)) - flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: true)) } == [1, 5, -1, 3, -1, 4, -1, 4, 2] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4] as [Int])
            #expect(Array(cut.sinkSide) == [3, 5] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["3", "6r", "8"] as [String])
            #expect(cut.value == 6)
        }
    }

    @Test("FL-200 undirected lcgund(10,25,6,9), on ReferencePseudograph, no indices")
    func fl200() {
        // lcgund(10,25,6,9); edmondsKarpMaximumFlow(from: 0, to: 9, capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (9, 4), (4, 9), (4, 0), (5, 0), (1, 3), (3, 4), (4, 7), (5, 6), (6, 1), (2, 4), (0, 7), (0, 7), (1, 3), (0, 2), (0, 7), (6, 1), (2, 6), (9, 1), (4, 0), (8, 4), (1, 0), (4, 2), (2, 3), (8, 1)]
        let capacities: [Int] = [4, 3, 9, 8, 8, 2, 7, 5, 2, 5, 8, 6, 4, 6, 7, 9, 4, 5, 3, 7, 2, 3, 7, 7, 1]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] })
            #expect(flow.value == 15)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [0, -3, 9, -8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -3, -4, 0, -3, 0, 0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(Array(cut.sinkSide) == [9] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1r", "2", "18r"] as [String])
            #expect(cut.value == 15)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 9, capacity: { capacities[$0] })
            #expect(flow.value == 15)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [0, -3, 9, -8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -3, -4, 0, -3, 0, 0, 0] as [Int])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
            #expect(Array(cut.sinkSide) == [9] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1r", "2", "18r"] as [String])
            #expect(cut.value == 15)
        }
    }

    @Test("FL-209 undirected Double, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl209() {
        // Double undirected V [a, b, c]; E [a–b 0.5, b–c 1.5, a–c 0.25]; edmondsKarpMaximumFlow(from: a, to: c, capacity:)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("a", "c")]
        let capacities: [Double] = [0.5, 1.5, 0.25]
        do { // Pseudograph
            let graph = Pseudograph<String>(vertices: ["a", "b", "c"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let flow = graph.edmondsKarpMaximumFlow(from: "a", to: "c", capacity: { capacities[$0] })
            #expect(flow.value == 0.75)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [0.5, 0.5, 0.25] as [Double])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["a"] as [String])
            #expect(Array(cut.sinkSide) == ["b", "c"] as [String])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "2"] as [String])
            #expect(cut.value == 0.75)
        }
        do { // no indices
            let graph = UnindexedGraph<String>(vertices: ["a", "b", "c"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let flow = graph.edmondsKarpMaximumFlow(from: "a", to: "c", capacity: { capacities[$0] })
            #expect(flow.value == 0.75)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [0.5, 0.5, 0.25] as [Double])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["a"] as [String])
            #expect(Array(cut.sinkSide) == ["b", "c"] as [String])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "2"] as [String])
            #expect(cut.value == 0.75)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<String>(vertices: ["a", "b", "c"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let flow = graph.edmondsKarpMaximumFlow(from: "a", to: "c", capacity: { capacities[$0] })
            #expect(flow.value == 0.75)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) - flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [0.5, 0.5, 0.25] as [Double])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == ["a"] as [String])
            #expect(Array(cut.sinkSide) == ["b", "c"] as [String])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "2"] as [String])
            #expect(cut.value == 0.75)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2, capacity: { capacities[edgeOf[$0]!] })
            #expect(flow.value == 0.75)
            #expect(pairs.indices.map { flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: false)) - flow.flow(ofEdgeAt: .init(position: positionOfEdge[$0], reversed: true)) } == [0.5, 0.5, 0.25] as [Double])
            let cut = flow.minimumCut
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["0", "2"] as [String])
            #expect(cut.value == 0.75)
        }
    }
}
