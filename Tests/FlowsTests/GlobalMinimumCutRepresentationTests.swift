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

@Suite("minimumCut(capacity:) on every representation")
struct GlobalMinimumCutRepresentationTests {
    @Test("FL-227 empty graph, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl227() {
        // undirected V []; E []; minimumCut(capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 0, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            #expect(result == nil)
        }
    }

    @Test("FL-228 one vertex, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl228() {
        // undirected V [0]; E [0–0 3]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 0)]
        let capacities: [Int] = [3]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0)]
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            #expect(result == nil)
        }
    }

    @Test("FL-229 two vertices, one edge, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl229() throws {
        // undirected V [0, 1]; E [0–1 4]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [4]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["0"] as [String])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-230 two vertices, parallel edges: weights add, on ReferencePseudograph, no indices")
    func fl230() throws {
        // undirected V [0, 1]; E [0–1 4, 1–0 1, 0–1 2]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
        let capacities: [Int] = [4, 1, 2]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r", "2"] as [String])
            #expect(cut.value == 7)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "1r", "2"] as [String])
            #expect(cut.value == 7)
        }
    }

    @Test("FL-231 two vertices, no edge, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl231() throws {
        // undirected V [0, 1]; E []; minimumCut(capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-232 disconnected: value 0, the first vertex's component, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl232() throws {
        // undirected V [0, 1, 2, 3]; E [0–1 5, 2–3 6]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let capacities: [Int] = [5, 6]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-233 disconnected, first vertex isolated, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl233() throws {
        // undirected V [0, 1, 2]; E [1–2 5]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(1, 2)]
        let capacities: [Int] = [5]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0] as [Int])
            #expect(Array(cut.sinkSide) == [1, 2] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == [] as [String])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-234 connected only by a zero edge: positive edges decide the components, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl234() throws {
        // undirected V [0, 1, 2, 3]; E [0–1 5, 1–2 0, 2–3 6]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let capacities: [Int] = [5, 0, 6]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1"] as [String])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1"] as [String])
            #expect(cut.value == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1"] as [String])
            #expect(cut.value == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["1"] as [String])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-235 self-loops ignored, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl235() throws {
        // undirected V [0, 1, 2]; E [0–0 9, 0–1 2, 1–2 3, 2–2 9, 0–2 4]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2), (0, 2)]
        let capacities: [Int] = [9, 2, 3, 9, 4]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 2] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "2r"] as [String])
            #expect(cut.value == 5)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 2] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "2r"] as [String])
            #expect(cut.value == 5)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 2] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "2r"] as [String])
            #expect(cut.value == 5)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 2] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["1", "2r"] as [String])
            #expect(cut.value == 5)
        }
    }

    @Test("FL-236 triangle, equal weights: ties: three minimum cuts, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl236() throws {
        // K(3); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let capacities: [Int] = [1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-237 path P(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl237() throws {
        // P(5); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let capacities: [Int] = [1, 1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 5 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 5 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 5 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 5 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-238 cycle C(6), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl238() throws {
        // C(6); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-239 K(5), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl239() throws {
        // K(5); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 4)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 5 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 4)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 5 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 4)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 5 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 4)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 5 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-240 Stoer–Wagner paper (1997, figure 1): value 4, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl240() throws {
        // undirected V [1, 2, 3, 4, 5, 6, 7, 8]; E [1–2 2, 1–5 3, 2–3 3, 2–5 2, 2–6 2, 3–4 4, 3–7 2, 4–7 2, 4–8 2, 5–6 3, 6–7 1, 7–8 3]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (2, 3), (2, 5), (2, 6), (3, 4), (3, 7), (4, 7), (4, 8), (5, 6), (6, 7), (7, 8)]
        let capacities: [Int] = [2, 3, 3, 2, 2, 4, 2, 2, 2, 3, 1, 3]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [1, 2, 5, 6] as [Int])
            #expect(Array(cut.sinkSide) == [3, 4, 7, 8] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2", "10"] as [String])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [1, 2, 5, 6] as [Int])
            #expect(Array(cut.sinkSide) == [3, 4, 7, 8] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["2", "10"] as [String])
            #expect(cut.value == 4)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
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
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 4, 5] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3, 6, 7] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["2", "10"] as [String])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-241 NetworkX stoer_wagner docs example, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl241() throws {
        // undirected V [x, a, b, c, d, e, y]; E [x–a 3, x–b 1, a–c 3, b–c 5, b–d 4, d–e 2, c–y 2, e–y 3]; minimumCut(capacity:)
        let pairs: [(String, String)] = [("x", "a"), ("x", "b"), ("a", "c"), ("b", "c"), ("b", "d"), ("d", "e"), ("c", "y"), ("e", "y")]
        let capacities: [Int] = [3, 1, 3, 5, 4, 2, 2, 3]
        do { // Pseudograph
            let graph = Pseudograph<String>(vertices: ["x", "a", "b", "c", "d", "e", "y"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 4)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 7 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == "x")
        }
        do { // no indices
            let graph = UnindexedGraph<String>(vertices: ["x", "a", "b", "c", "d", "e", "y"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 4)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 7 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == "x")
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<String>(vertices: ["x", "a", "b", "c", "d", "e", "y"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 4)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 7 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == "x")
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (2, 4), (4, 5), (3, 6), (5, 6)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 4)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 7 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-242 Wikipedia Gomory–Hu graph, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl242() throws {
        // undirected V [0, 1, 2, 3, 4, 5]; E [0–1 1, 0–2 7, 1–2 1, 1–3 3, 1–4 2, 2–4 4, 3–4 1, 3–5 6, 4–5 2]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
        let capacities: [Int] = [1, 7, 1, 3, 2, 4, 1, 6, 2]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 6)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 6)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 6)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 6)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-243 two K(4) joined by one light edge, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl243() throws {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1 3, 0–2 3, 0–3 3, 1–2 3, 1–3 3, 2–3 3, 4–5 3, 4–6 3, 4–7 3, 5–6 3, 5–7 3, 6–7 3, 3–4 1]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (3, 4)]
        let capacities: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3] as [Int])
            #expect(Array(cut.sinkSide) == [4, 5, 6, 7] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["12"] as [String])
            #expect(cut.value == 1)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3] as [Int])
            #expect(Array(cut.sinkSide) == [4, 5, 6, 7] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["12"] as [String])
            #expect(cut.value == 1)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3] as [Int])
            #expect(Array(cut.sinkSide) == [4, 5, 6, 7] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["12"] as [String])
            #expect(cut.value == 1)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 8, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3] as [Int])
            #expect(Array(cut.sinkSide) == [4, 5, 6, 7] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["12"] as [String])
            #expect(cut.value == 1)
        }
    }

    @Test("FL-244 Petersen, unit, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl244() throws {
        // nx(petersen_graph); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 3)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 10 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 3)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 10 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 3)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 10 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 3)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 10 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-245 grid(3,4), unit: a corner, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl245() throws {
        // grid(3,4); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 12 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 12 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 12 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 2)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 12 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-246 lcgund(10,25,6,9), on ReferencePseudograph, no indices")
    func fl246() throws {
        // lcgund(10,25,6,9); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(1, 2), (9, 4), (4, 9), (4, 0), (5, 0), (1, 3), (3, 4), (4, 7), (5, 6), (6, 1), (2, 4), (0, 7), (0, 7), (1, 3), (0, 2), (0, 7), (6, 1), (2, 6), (9, 1), (4, 0), (8, 4), (1, 0), (4, 2), (2, 3), (8, 1)]
        let capacities: [Int] = [4, 3, 9, 8, 8, 2, 7, 5, 2, 5, 8, 6, 4, 6, 7, 9, 4, 5, 3, 7, 2, 3, 7, 7, 1]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 9] as [Int])
            #expect(Array(cut.sinkSide) == [8] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["20r", "24r"] as [String])
            #expect(cut.value == 3)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5, 6, 7, 9] as [Int])
            #expect(Array(cut.sinkSide) == [8] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["20r", "24r"] as [String])
            #expect(cut.value == 3)
        }
    }

    @Test("FL-247 lcgund(12,40,7,20), on ReferencePseudograph, no indices")
    func fl247() throws {
        // lcgund(12,40,7,20); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(2, 11), (5, 1), (4, 0), (10, 7), (9, 10), (3, 0), (4, 1), (6, 5), (8, 5), (1, 2), (5, 11), (7, 4), (1, 11), (2, 8), (0, 8), (6, 8), (5, 8), (7, 4), (6, 7), (1, 11), (11, 5), (11, 8), (9, 2), (7, 4), (6, 1), (6, 0), (8, 0), (11, 2), (11, 7), (9, 1), (4, 10), (0, 9), (8, 2), (8, 7), (3, 0), (11, 5), (0, 8), (6, 2), (2, 11), (2, 10)]
        let capacities: [Int] = [14, 20, 20, 16, 6, 12, 15, 5, 14, 16, 10, 13, 9, 5, 7, 15, 15, 17, 20, 1, 1, 19, 11, 6, 11, 16, 18, 8, 6, 15, 16, 4, 6, 12, 15, 4, 6, 2, 8, 11]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["5r", "34r"] as [String])
            #expect(cut.value == 27)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
            #expect(Array(cut.sinkSide) == [3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["5r", "34r"] as [String])
            #expect(cut.value == 27)
        }
    }

    @Test("FL-248 Double weights, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl248() throws {
        // Double undirected V [0, 1, 2]; E [0–1 0.5, 1–2 0.25, 0–2 0.125]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let capacities: [Double] = [0.5, 0.25, 0.125]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "2"] as [String])
            #expect(cut.value == 0.375)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "2"] as [String])
            #expect(cut.value == 0.375)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "2"] as [String])
            #expect(cut.value == 0.375)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["2", "1"] as [String])
            #expect(cut.value == 0.375)
        }
    }

    @Test("FL-250 directed: one vertex, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl250() {
        // V [0]; E []; minimumCut(capacity:)
        let pairs: [(Int, Int)] = []
        let capacities: [Int] = []
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            #expect(result == nil)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = []
            let graph = CompressedSparseRow(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            #expect(result == nil)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = []
            let graph = AdjacencyMatrix(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            #expect(result == nil)
        }
    }

    @Test("FL-251 directed: one edge: 1 cannot reach 0: value 0, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl251() throws {
        // V [0, 1]; E [0→1 4]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let capacities: [Int] = [4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [] as [Int])
            #expect(cut.value == 0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [] as [Int])
            #expect(cut.value == 0)
        }
    }

    @Test("FL-252 directed: two-cycle, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl252() throws {
        // V [0, 1]; E [0→1 4, 1→0 2]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let capacities: [Int] = [4, 2]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges == [1] as [Int])
            #expect(cut.value == 2)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges == [1] as [Int])
            #expect(cut.value == 2)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1] as [Int])
            #expect(cut.value == 2)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [1] as [Int])
            #expect(Array(cut.sinkSide) == [0] as [Int])
            #expect(cut.edges.map { edgeOf[$0]! } == [1] as [Int])
            #expect(cut.value == 2)
        }
    }

    @Test("FL-253 directed: cycle Cd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl253() throws {
        // Cd(4); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let capacities: [Int] = [1, 1, 1, 1]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
    }

    @Test("FL-254 directed: complete Kd(4), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl254() throws {
        // Kd(4); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let capacities: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 3)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 3)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 3)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 3)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
    }

    @Test("FL-255 directed: CLRS figure 26.1: t has no out-edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl255() throws {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v3 12, v2→v1 4, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; minimumCut(capacity:)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let capacities: [Int] = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 0)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 0)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 0)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 0)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 6 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
    }

    @Test("FL-256 directed: lcgnet(8,30,8,9), on ReferenceDirectedMultigraph, no indices")
    func fl256() throws {
        // lcgnet(8,30,8,9); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(4, 0), (3, 6), (2, 3), (5, 7), (6, 3), (0, 6), (6, 0), (1, 4), (5, 6), (3, 6), (0, 4), (2, 1), (0, 7), (1, 3), (5, 2), (6, 5), (0, 5), (0, 7), (0, 5), (3, 1), (4, 7), (4, 2), (7, 4), (1, 3), (0, 1), (5, 7), (7, 4), (2, 5), (4, 1), (7, 4)]
        let capacities: [Int] = [6, 6, 2, 2, 5, 6, 3, 5, 5, 7, 1, 5, 9, 9, 3, 4, 2, 2, 3, 1, 4, 1, 5, 9, 1, 3, 4, 9, 4, 9]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 3, 4, 5, 6, 7] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [14, 21] as [Int])
            #expect(cut.value == 4)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 3, 4, 5, 6, 7] as [Int])
            #expect(Array(cut.sinkSide) == [2] as [Int])
            #expect(cut.edges == [14, 21] as [Int])
            #expect(cut.value == 4)
        }
    }

    @Test("FL-257 directed: lcgnet(10,40,21,5), on ReferenceDirectedMultigraph, no indices")
    func fl257() throws {
        // lcgnet(10,40,21,5); minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(1, 9), (6, 5), (6, 2), (2, 8), (2, 3), (0, 8), (4, 0), (8, 7), (6, 0), (3, 1), (9, 0), (8, 7), (7, 8), (7, 1), (0, 9), (1, 3), (1, 5), (6, 4), (1, 7), (4, 3), (3, 8), (2, 3), (4, 7), (7, 0), (8, 6), (4, 8), (0, 6), (4, 8), (4, 5), (4, 1), (7, 6), (6, 1), (7, 8), (9, 4), (0, 1), (5, 7), (0, 4), (2, 5), (6, 9), (5, 0)]
        let capacities: [Int] = [4, 5, 5, 1, 5, 4, 3, 3, 3, 2, 3, 4, 1, 1, 4, 2, 2, 5, 2, 2, 3, 4, 4, 4, 4, 1, 1, 1, 5, 2, 4, 3, 3, 3, 1, 5, 3, 2, 1, 1]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 5)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 10 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 5)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 10 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
    }

    @Test("FL-492 UInt8, every vertex within 255: a merged group's connection passes 255, on ReferencePseudograph, no indices")
    func fl492() throws {
        // UInt8 undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [1–5 5, 2–3 16, 4–7 21, 4–0 3, 3–7 39, 6–3 33, 6–0 43, 2–0 46, 5–0 1, 6–2 39, 2–6 119, 6–1 12, 0–7 33, 7–2 20, 0–4 66, 4–5 24, 1–3 42, 5–1 10, 7–3 40,…
        let pairs: [(Int, Int)] = [(1, 5), (2, 3), (4, 7), (4, 0), (3, 7), (6, 3), (6, 0), (2, 0), (5, 0), (6, 2), (2, 6), (6, 1), (0, 7), (7, 2), (0, 4), (4, 5), (1, 3), (5, 1), (7, 3), (1, 4), (4, 7), (4, 1), (3, 0), (3, 0), (6, 3), (3, 6), (2, 3)]
        let capacities: [UInt8] = [5, 16, 21, 3, 39, 33, 43, 46, 1, 39, 119, 12, 33, 20, 66, 24, 42, 10, 40, 22, 50, 20, 20, 12, 8, 1, 7]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 6, 7] as [Int])
            #expect(Array(cut.sinkSide) == [5] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "8r", "15", "17r"] as [String])
            #expect(cut.value == 40)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 6, 7] as [Int])
            #expect(Array(cut.sinkSide) == [5] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0", "8r", "15", "17r"] as [String])
            #expect(cut.value == 40)
        }
    }

    @Test("FL-493 UInt8, labels shuffled: the fuzzer's case: the greatest vertex sum 229, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl493() throws {
        // UInt8 undirected V [6, 2, 3, 5, 4, 0, 1]; E [2–3 40, 3–6 63, 6–4 63, 2–0 63, 2–5 63, 6–5 63, 5–1 40, 4–5 63]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(2, 3), (3, 6), (6, 4), (2, 0), (2, 5), (6, 5), (5, 1), (4, 5)]
        let capacities: [UInt8] = [40, 63, 63, 63, 63, 63, 40, 63]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [6, 2, 3, 5, 4, 0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [6, 2, 3, 5, 4, 0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["6"] as [String])
            #expect(cut.value == 40)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [6, 2, 3, 5, 4, 0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [6, 2, 3, 5, 4, 0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["6"] as [String])
            #expect(cut.value == 40)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [6, 2, 3, 5, 4, 0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [6, 2, 3, 5, 4, 0] as [Int])
            #expect(Array(cut.sinkSide) == [1] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["6"] as [String])
            #expect(cut.value == 40)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 4), (1, 5), (1, 3), (0, 3), (3, 6), (4, 3)]
            let graph = AdjacencyMatrix(vertexCount: 7, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(Array(cut.sinkSide) == [6] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["6"] as [String])
            #expect(cut.value == 40)
        }
    }

    @Test("FL-494 UInt8 star, the centre's sum past 255: the answer 200 fits, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl494() throws {
        // UInt8 undirected V [0, 1, 2, 3]; E [0–1 200, 0–2 200, 0–3 200]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let capacities: [UInt8] = [200, 200, 200]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 200)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 200)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 200)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 200)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-497 directed: UInt8, the capacities into a vertex past 255, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl497() throws {
        // UInt8 V [0, 1, 2]; E [1→0 200, 2→0 200, 0→1 5, 0→2 5, 1→2 3, 2→1 3]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(1, 0), (2, 0), (0, 1), (0, 2), (1, 2), (2, 1)]
        let capacities: [UInt8] = [200, 200, 5, 5, 3, 3]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 8)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 8)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(1, 0), (2, 0), (0, 1), (0, 2), (1, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 8)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(1, 0), (2, 0), (0, 1), (0, 2), (1, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 8)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
    }

    @Test("FL-498 directed: UInt8, the review's edges as arcs, on ReferenceDirectedMultigraph, no indices")
    func fl498() throws {
        // UInt8 V [0, 1, 2, 3, 4, 5, 6, 7]; E [1→5 5, 2→3 16, 4→7 21, 4→0 3, 3→7 39, 6→3 33, 6→0 43, 2→0 46, 5→0 1, 6→2 39, 2→6 119, 6→1 12, 0→7 33, 7→2 20, 0→4 66, 4→5 24, 1→3 42, 5→1 10, 7→3 40, 1→4 22, 4→…
        let pairs: [(Int, Int)] = [(1, 5), (2, 3), (4, 7), (4, 0), (3, 7), (6, 3), (6, 0), (2, 0), (5, 0), (6, 2), (2, 6), (6, 1), (0, 7), (7, 2), (0, 4), (4, 5), (1, 3), (5, 1), (7, 3), (1, 4), (4, 7), (4, 1), (3, 0), (3, 0), (6, 3), (3, 6), (2, 3)]
        let capacities: [UInt8] = [5, 16, 21, 3, 39, 33, 43, 46, 1, 39, 119, 12, 33, 20, 66, 24, 42, 10, 40, 22, 50, 20, 20, 12, 8, 1, 7]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [5] as [Int])
            #expect(Array(cut.sinkSide) == [0, 1, 2, 3, 4, 6, 7] as [Int])
            #expect(cut.edges == [8, 17] as [Int])
            #expect(cut.value == 11)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [5] as [Int])
            #expect(Array(cut.sinkSide) == [0, 1, 2, 3, 4, 6, 7] as [Int])
            #expect(cut.edges == [8, 17] as [Int])
            #expect(cut.value == 11)
        }
    }

    @Test("FL-499 Double cycle, ties, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl499() throws {
        // Double undirected V [0, 1, 2, 3]; E [0–1 0.5, 1–2 0.5, 2–3 0.5, 3–0 0.5]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let capacities: [Double] = [0.5, 0.5, 0.5, 0.5]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1.0)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1.0)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1.0)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 1.0)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 4 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-500 Double, one light edge, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl500() throws {
        // Double undirected V [0, 1, 2, 3]; E [0–1 0.75, 1–2 0.25, 2–3 0.75, 3–0 0.5, 0–2 0.125]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
        let capacities: [Double] = [0.75, 0.25, 0.75, 0.5, 0.125]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "3r", "4"] as [String])
            #expect(cut.value == 0.875)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "3r", "4"] as [String])
            #expect(cut.value == 0.875)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "3r", "4"] as [String])
            #expect(cut.value == 0.875)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["4", "1", "3r"] as [String])
            #expect(cut.value == 0.875)
        }
    }

    @Test("FL-501 directed: Double, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl501() throws {
        // Double V [0, 1, 2]; E [0→1 0.25, 1→2 0.5, 2→0 0.75, 1→0 0.125]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 0)]
        let capacities: [Double] = [0.25, 0.5, 0.75, 0.125]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 0.25)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 0.25)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 0.25)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 0.25)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
        }
    }

    @Test("FL-526 Int.max path: the middle vertex's sum passes Int, so the sums run in Int128, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl526() throws {
        // undirected V [0, 1, 2]; E [0–1 9223372036854775807, 1–2 9223372036854775807]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int] = [9223372036854775807, 9223372036854775807]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 9223372036854775807)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 9223372036854775807)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 9223372036854775807)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            // One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected
            // graph the first vertex on the source side.
            #expect(cut.value == 9223372036854775807)
            #expect(cut.sourceSide.count + cut.sinkSide.count == 3 && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)
            #expect(cut.sourceSide.first == 0)
        }
    }

    @Test("FL-528 found only in a later phase: Nagamochi–Ibaraki's first phase misses it, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl528() throws {
        // undirected V [0, 1, 2, 3, 4, 5]; E [2–0 1, 4–1 1, 5–2 2, 4–0 2, 0–5 2, 3–1 3, 1–0 1]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(2, 0), (4, 1), (5, 2), (4, 0), (0, 5), (3, 1), (1, 0)]
        let capacities: [Int] = [1, 1, 2, 2, 2, 3, 1]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 2, 4, 5] as [Int])
            #expect(Array(cut.sinkSide) == [1, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "6r"] as [String])
            #expect(cut.value == 2)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 2, 4, 5] as [Int])
            #expect(Array(cut.sinkSide) == [1, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "6r"] as [String])
            #expect(cut.value == 2)
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 2, 4, 5] as [Int])
            #expect(Array(cut.sinkSide) == [1, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["1", "6r"] as [String])
            #expect(cut.value == 2)
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(2, 0), (4, 1), (5, 2), (4, 0), (0, 5), (3, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let result = graph.minimumCut(capacity: { capacities[edgeOf[$0]!] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 2, 4, 5] as [Int])
            #expect(Array(cut.sinkSide) == [1, 3] as [Int])
            #expect(cut.edges.map { "\(edgeOf[$0.position]!)\($0.reversed ? "r" : "")" } == ["6r", "1"] as [String])
            #expect(cut.value == 2)
        }
    }

    @Test("FL-529 Double, found only in a later phase: on the heap rather than the bucket queue, on ReferencePseudograph, no indices")
    func fl529() throws {
        // Double undirected V [0, 1, 2, 3, 4, 5]; E [0–3 2.25, 0–1 2.0, 2–3 1.5, 2–3 2.0, 4–0 2.0, 4–5 2.0, 1–5 1.25]; minimumCut(capacity:)
        let pairs: [(Int, Int)] = [(0, 3), (0, 1), (2, 3), (2, 3), (4, 0), (4, 5), (1, 5)]
        let capacities: [Double] = [2.25, 2.0, 1.5, 2.0, 2.0, 2.0, 1.25]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 4, 5] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
            #expect(cut.value == 2.25)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let result = graph.minimumCut(capacity: { capacities[$0] })
            let cut = try #require(result)
            #expect(Array(cut.sourceSide) == [0, 1, 4, 5] as [Int])
            #expect(Array(cut.sinkSide) == [2, 3] as [Int])
            #expect(cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == ["0"] as [String])
            #expect(cut.value == 2.25)
        }
    }
}
