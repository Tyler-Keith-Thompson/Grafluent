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

@Suite("Cut metrics on every representation")
struct CutMetricsRepresentationTests {
    @Test("FL-553 empty set: every ratio over |S| is NaN, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl553() {
        // undirected V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; cut metrics of []
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 0)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect((graph.edgeExpansion(of: s)).isNaN)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect((graph.nodeExpansion(of: s)).isNaN)
            #expect((graph.boundaryExpansion(of: s)).isNaN)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 0)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect((graph.edgeExpansion(of: s)).isNaN)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect((graph.nodeExpansion(of: s)).isNaN)
            #expect((graph.boundaryExpansion(of: s)).isNaN)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 0)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect((graph.edgeExpansion(of: s)).isNaN)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect((graph.nodeExpansion(of: s)).isNaN)
            #expect((graph.boundaryExpansion(of: s)).isNaN)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 0)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect((graph.edgeExpansion(of: s)).isNaN)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect((graph.nodeExpansion(of: s)).isNaN)
            #expect((graph.boundaryExpansion(of: s)).isNaN)
        }
    }

    @Test("FL-554 whole vertex set: T empty, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl554() {
        // undirected V [0, 1, 2]; E [0–1, 1–2]; cut metrics of [0, 1, 2]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [0, 1, 2] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 4)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect((graph.edgeExpansion(of: s)).isNaN)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 0.0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0, 1, 2] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 4)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect((graph.edgeExpansion(of: s)).isNaN)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 0.0)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 1, 2] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 4)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect((graph.edgeExpansion(of: s)).isNaN)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 0.0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 1, 2] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 4)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect((graph.edgeExpansion(of: s)).isNaN)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 0.0)
        }
    }

    @Test("FL-555 path P(4), first half, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl555() {
        // P(4); cut metrics of [0, 1]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 1)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.6666666666666666)
            #expect(graph.edgeExpansion(of: s) == 0.5)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 1.5)
            #expect(graph.boundaryExpansion(of: s) == 0.5)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 1)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.6666666666666666)
            #expect(graph.edgeExpansion(of: s) == 0.5)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 1.5)
            #expect(graph.boundaryExpansion(of: s) == 0.5)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 1)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.6666666666666666)
            #expect(graph.edgeExpansion(of: s) == 0.5)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 1.5)
            #expect(graph.boundaryExpansion(of: s) == 0.5)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 1)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.6666666666666666)
            #expect(graph.edgeExpansion(of: s) == 0.5)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 1.5)
            #expect(graph.boundaryExpansion(of: s) == 0.5)
        }
    }

    @Test("FL-556 NetworkX doc: C(4), S = {0, 1}, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl556() {
        // C(4); cut metrics of [0, 1]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 4)
            #expect(graph.conductance(of: s) == 0.5)
            #expect(graph.normalizedCutSize(of: s) == 1.0)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.25)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 4)
            #expect(graph.conductance(of: s) == 0.5)
            #expect(graph.normalizedCutSize(of: s) == 1.0)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.25)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 4)
            #expect(graph.conductance(of: s) == 0.5)
            #expect(graph.normalizedCutSize(of: s) == 1.0)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.25)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 4)
            #expect(graph.conductance(of: s) == 0.5)
            #expect(graph.normalizedCutSize(of: s) == 1.0)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.25)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
    }

    @Test("FL-557 NetworkX doc: C(6), S = {0, 2, 4}, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl557() {
        // C(6); cut metrics of [0, 2, 4]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [0, 2, 4] as [Int]
            #expect(graph.cutSize(of: s) == 6)
            #expect(graph.volume(of: s) == 6)
            #expect(graph.conductance(of: s) == 1.0)
            #expect(graph.normalizedCutSize(of: s) == 2.0)
            #expect(graph.edgeExpansion(of: s) == 2.0)
            #expect(graph.mixingExpansion(of: s) == 0.5)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0, 2, 4] as [Int]
            #expect(graph.cutSize(of: s) == 6)
            #expect(graph.volume(of: s) == 6)
            #expect(graph.conductance(of: s) == 1.0)
            #expect(graph.normalizedCutSize(of: s) == 2.0)
            #expect(graph.edgeExpansion(of: s) == 2.0)
            #expect(graph.mixingExpansion(of: s) == 0.5)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 2, 4] as [Int]
            #expect(graph.cutSize(of: s) == 6)
            #expect(graph.volume(of: s) == 6)
            #expect(graph.conductance(of: s) == 1.0)
            #expect(graph.normalizedCutSize(of: s) == 2.0)
            #expect(graph.edgeExpansion(of: s) == 2.0)
            #expect(graph.mixingExpansion(of: s) == 0.5)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 2, 4] as [Int]
            #expect(graph.cutSize(of: s) == 6)
            #expect(graph.volume(of: s) == 6)
            #expect(graph.conductance(of: s) == 1.0)
            #expect(graph.normalizedCutSize(of: s) == 2.0)
            #expect(graph.edgeExpansion(of: s) == 2.0)
            #expect(graph.mixingExpansion(of: s) == 0.5)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
    }

    @Test("FL-558 K(5), S = {0, 1}, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl558() {
        // K(5); cut metrics of [0, 1]
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 6)
            #expect(graph.volume(of: s) == 8)
            #expect(graph.conductance(of: s) == 0.75)
            #expect(graph.normalizedCutSize(of: s) == 1.25)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.3)
            #expect(graph.nodeExpansion(of: s) == 2.5)
            #expect(graph.boundaryExpansion(of: s) == 1.5)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 6)
            #expect(graph.volume(of: s) == 8)
            #expect(graph.conductance(of: s) == 0.75)
            #expect(graph.normalizedCutSize(of: s) == 1.25)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.3)
            #expect(graph.nodeExpansion(of: s) == 2.5)
            #expect(graph.boundaryExpansion(of: s) == 1.5)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 6)
            #expect(graph.volume(of: s) == 8)
            #expect(graph.conductance(of: s) == 0.75)
            #expect(graph.normalizedCutSize(of: s) == 1.25)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.3)
            #expect(graph.nodeExpansion(of: s) == 2.5)
            #expect(graph.boundaryExpansion(of: s) == 1.5)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 6)
            #expect(graph.volume(of: s) == 8)
            #expect(graph.conductance(of: s) == 0.75)
            #expect(graph.normalizedCutSize(of: s) == 1.25)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.3)
            #expect(graph.nodeExpansion(of: s) == 2.5)
            #expect(graph.boundaryExpansion(of: s) == 1.5)
        }
    }

    @Test("FL-559 Petersen, the outer cycle, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl559() {
        // nx(petersen_graph); cut metrics of [0, 1, 2, 3, 4]
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [0, 1, 2, 3, 4] as [Int]
            #expect(graph.cutSize(of: s) == 5)
            #expect(graph.volume(of: s) == 15)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.6666666666666666)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0, 1, 2, 3, 4] as [Int]
            #expect(graph.cutSize(of: s) == 5)
            #expect(graph.volume(of: s) == 15)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.6666666666666666)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 1, 2, 3, 4] as [Int]
            #expect(graph.cutSize(of: s) == 5)
            #expect(graph.volume(of: s) == 15)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.6666666666666666)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0, 1, 2, 3, 4] as [Int]
            #expect(graph.cutSize(of: s) == 5)
            #expect(graph.volume(of: s) == 15)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.6666666666666666)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
    }

    @Test("FL-560 self-loops count twice in the volume, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl560() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; cut metrics of [0]
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 1)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.5333333333333333)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.125)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 1)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.5333333333333333)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.125)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 1)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.5333333333333333)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.125)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 1)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 0.3333333333333333)
            #expect(graph.normalizedCutSize(of: s) == 0.5333333333333333)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.125)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
    }

    @Test("FL-561 parallel edges each cross, on ReferencePseudograph, no indices")
    func fl561() {
        // undirected V [0, 1, 2]; E [0–1 2, 1–0 3, 0–1 5, 1–2 7]; cut metrics of [0]
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1), (1, 2)]
        let weights: [Int] = [2, 3, 5, 7]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 3)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 1.0)
            #expect(graph.normalizedCutSize(of: s) == 1.6)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.375)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 10)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 10)
            #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 1.0)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 1.4166666666666665)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 10.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.29411764705882354)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 3)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 1.0)
            #expect(graph.normalizedCutSize(of: s) == 1.6)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.375)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 10)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 10)
            #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 1.0)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 1.4166666666666665)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 10.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.29411764705882354)
        }
    }

    @Test("FL-562 weighted, isolated vertex: vol(S) = 0, on Pseudograph, no indices, AdjacencyList.undirectedView, AdjacencyMatrix.undirectedView")
    func fl562() {
        // undirected V [0, 1, 2, 3]; E [0–1 1, 1–2 2, 0–2 4]; cut metrics of [3]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
        let weights: [Int] = [1, 2, 4]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [3] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 0)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect(graph.edgeExpansion(of: s) == 0.0)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect(graph.nodeExpansion(of: s) == 0.0)
            #expect(graph.boundaryExpansion(of: s) == 0.0)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 0)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 0)
            #expect((graph.conductance(of: s, weight: { Double(weights[$0]) })).isNaN)
            #expect((graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) })).isNaN)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 0.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.0)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [3] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 0)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect(graph.edgeExpansion(of: s) == 0.0)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect(graph.nodeExpansion(of: s) == 0.0)
            #expect(graph.boundaryExpansion(of: s) == 0.0)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 0)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 0)
            #expect((graph.conductance(of: s, weight: { Double(weights[$0]) })).isNaN)
            #expect((graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) })).isNaN)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 0.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.0)
        }
        do { // AdjacencyList.undirectedView
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            let s = [3] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 0)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect(graph.edgeExpansion(of: s) == 0.0)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect(graph.nodeExpansion(of: s) == 0.0)
            #expect(graph.boundaryExpansion(of: s) == 0.0)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 0)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 0)
            #expect((graph.conductance(of: s, weight: { Double(weights[$0]) })).isNaN)
            #expect((graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) })).isNaN)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 0.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.0)
        }
        do { // AdjacencyMatrix.undirectedView
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let s = [3] as [Int]
            #expect(graph.cutSize(of: s) == 0)
            #expect(graph.volume(of: s) == 0)
            #expect((graph.conductance(of: s)).isNaN)
            #expect((graph.normalizedCutSize(of: s)).isNaN)
            #expect(graph.edgeExpansion(of: s) == 0.0)
            #expect(graph.mixingExpansion(of: s) == 0.0)
            #expect(graph.nodeExpansion(of: s) == 0.0)
            #expect(graph.boundaryExpansion(of: s) == 0.0)
            #expect(graph.cutSize(of: s, weight: { weights[edgeOf[$0]!] }) == 0)
            #expect(graph.volume(of: s, weight: { weights[edgeOf[$0]!] }) == 0)
            #expect((graph.conductance(of: s, weight: { Double(weights[edgeOf[$0]!]) })).isNaN)
            #expect((graph.normalizedCutSize(of: s, weight: { Double(weights[edgeOf[$0]!]) })).isNaN)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 0.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 0.0)
        }
    }

    @Test("FL-563 weighted lcgund(10,25,6,9), on ReferencePseudograph, no indices")
    func fl563() {
        // lcgund(10,25,6,9); cut metrics of [0, 2, 3, 7]
        let pairs: [(Int, Int)] = [(1, 2), (9, 4), (4, 9), (4, 0), (5, 0), (1, 3), (3, 4), (4, 7), (5, 6), (6, 1), (2, 4), (0, 7), (0, 7), (1, 3), (0, 2), (0, 7), (6, 1), (2, 6), (9, 1), (4, 0), (8, 4), (1, 0), (4, 2), (2, 3), (8, 1)]
        let weights: [Int] = [4, 3, 9, 8, 8, 2, 7, 5, 2, 5, 8, 6, 4, 6, 7, 9, 4, 5, 3, 7, 2, 3, 7, 7, 1]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let s = [0, 2, 3, 7] as [Int]
            #expect(graph.cutSize(of: s) == 12)
            #expect(graph.volume(of: s) == 22)
            #expect(graph.conductance(of: s) == 0.5454545454545454)
            #expect(graph.normalizedCutSize(of: s) == 0.974025974025974)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.24)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 70)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 136)
            #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 0.546875)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 1.0615808823529411)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 17.5)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.26515151515151514)
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0, 2, 3, 7] as [Int]
            #expect(graph.cutSize(of: s) == 12)
            #expect(graph.volume(of: s) == 22)
            #expect(graph.conductance(of: s) == 0.5454545454545454)
            #expect(graph.normalizedCutSize(of: s) == 0.974025974025974)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.24)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 70)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 136)
            #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 0.546875)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 1.0615808823529411)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 17.5)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.26515151515151514)
        }
    }

    @Test("FL-564 directed: both directions cross, out-degree volume, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl564() {
        // V [0, 1, 2, 3]; E [0→1, 1→0, 2→0, 1→3, 3→3]; cut metrics of [0, 1]
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 0), (1, 3), (3, 3)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 1.0)
            #expect(graph.normalizedCutSize(of: s) == 1.6666666666666665)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.2)
            #expect(graph.nodeExpansion(of: s) == 1.5)
            #expect(graph.boundaryExpansion(of: s) == 0.5)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 1.0)
            #expect(graph.normalizedCutSize(of: s) == 1.6666666666666665)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.2)
            #expect(graph.nodeExpansion(of: s) == 1.5)
            #expect(graph.boundaryExpansion(of: s) == 0.5)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 0), (1, 3), (3, 3)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 1.0)
            #expect(graph.normalizedCutSize(of: s) == 1.6666666666666665)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.2)
            #expect(graph.nodeExpansion(of: s) == 1.5)
            #expect(graph.boundaryExpansion(of: s) == 0.5)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 0), (1, 3), (3, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let s = [0, 1] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 3)
            #expect(graph.conductance(of: s) == 1.0)
            #expect(graph.normalizedCutSize(of: s) == 1.6666666666666665)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.2)
            #expect(graph.nodeExpansion(of: s) == 1.5)
            #expect(graph.boundaryExpansion(of: s) == 0.5)
        }
    }

    @Test("FL-565 directed: successors, not predecessors, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl565() {
        // V [0, 1, 2, 3]; E [0→1, 2→0, 3→0]; cut metrics of [0]
        let pairs: [(Int, Int)] = [(0, 1), (2, 0), (3, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 3)
            #expect(graph.volume(of: s) == 1)
            #expect(graph.conductance(of: s) == 3.0)
            #expect(graph.normalizedCutSize(of: s) == 4.5)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.5)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 3)
            #expect(graph.volume(of: s) == 1)
            #expect(graph.conductance(of: s) == 3.0)
            #expect(graph.normalizedCutSize(of: s) == 4.5)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.5)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (2, 0), (3, 0)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 3)
            #expect(graph.volume(of: s) == 1)
            #expect(graph.conductance(of: s) == 3.0)
            #expect(graph.normalizedCutSize(of: s) == 4.5)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.5)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (2, 0), (3, 0)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 3)
            #expect(graph.volume(of: s) == 1)
            #expect(graph.conductance(of: s) == 3.0)
            #expect(graph.normalizedCutSize(of: s) == 4.5)
            #expect(graph.edgeExpansion(of: s) == 3.0)
            #expect(graph.mixingExpansion(of: s) == 0.5)
            #expect(graph.nodeExpansion(of: s) == 1.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
        }
    }

    @Test("FL-566 directed: self-loop counts once, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl566() {
        // V [0, 1]; E [0→0 3, 0→1 2, 1→0 5]; cut metrics of [0]
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
        let weights: [Int] = [3, 2, 5]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 2)
            #expect(graph.conductance(of: s) == 2.0)
            #expect(graph.normalizedCutSize(of: s) == 3.0)
            #expect(graph.edgeExpansion(of: s) == 2.0)
            #expect(graph.mixingExpansion(of: s) == 0.3333333333333333)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 7)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 5)
            #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 1.4)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 2.8000000000000003)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 7.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.35)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 2)
            #expect(graph.conductance(of: s) == 2.0)
            #expect(graph.normalizedCutSize(of: s) == 3.0)
            #expect(graph.edgeExpansion(of: s) == 2.0)
            #expect(graph.mixingExpansion(of: s) == 0.3333333333333333)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 7)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 5)
            #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 1.4)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 2.8000000000000003)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 7.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.35)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 2)
            #expect(graph.conductance(of: s) == 2.0)
            #expect(graph.normalizedCutSize(of: s) == 3.0)
            #expect(graph.edgeExpansion(of: s) == 2.0)
            #expect(graph.mixingExpansion(of: s) == 0.3333333333333333)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
            #expect(graph.cutSize(of: s, weight: { weights[edgeOf[$0]!] }) == 7)
            #expect(graph.volume(of: s, weight: { weights[edgeOf[$0]!] }) == 5)
            #expect(graph.conductance(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 1.4)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 2.8000000000000003)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 7.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 0.35)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let s = [0] as [Int]
            #expect(graph.cutSize(of: s) == 2)
            #expect(graph.volume(of: s) == 2)
            #expect(graph.conductance(of: s) == 2.0)
            #expect(graph.normalizedCutSize(of: s) == 3.0)
            #expect(graph.edgeExpansion(of: s) == 2.0)
            #expect(graph.mixingExpansion(of: s) == 0.3333333333333333)
            #expect(graph.nodeExpansion(of: s) == 2.0)
            #expect(graph.boundaryExpansion(of: s) == 1.0)
            #expect(graph.cutSize(of: s, weight: { weights[edgeOf[$0]!] }) == 7)
            #expect(graph.volume(of: s, weight: { weights[edgeOf[$0]!] }) == 5)
            #expect(graph.conductance(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 1.4)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 2.8000000000000003)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 7.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 0.35)
        }
    }

    @Test("FL-567 directed: CLRS figure 26.1, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl567() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1 16, s→v2 13, v1→v3 12, v2→v1 4, v2→v4 14, v3→v2 9, v3→t 20, v4→v3 7, v4→t 4]; cut metrics of [s, v1, v2]
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let weights: [Int] = [16, 13, 12, 4, 14, 9, 20, 7, 4]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let s = ["s", "v1", "v2"] as [String]
            #expect(graph.cutSize(of: s) == 3)
            #expect(graph.volume(of: s) == 5)
            #expect(graph.conductance(of: s) == 0.75)
            #expect(graph.normalizedCutSize(of: s) == 1.35)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 1.3333333333333333)
            #expect(graph.boundaryExpansion(of: s) == 0.6666666666666666)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 35)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 59)
            #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 0.875)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 1.468220338983051)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 11.666666666666666)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.17676767676767677)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = ["s", "v1", "v2"] as [String]
            #expect(graph.cutSize(of: s) == 3)
            #expect(graph.volume(of: s) == 5)
            #expect(graph.conductance(of: s) == 0.75)
            #expect(graph.normalizedCutSize(of: s) == 1.35)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 1.3333333333333333)
            #expect(graph.boundaryExpansion(of: s) == 0.6666666666666666)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 35)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 59)
            #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 0.875)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 1.468220338983051)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 11.666666666666666)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.17676767676767677)
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let s = [0, 1, 2] as [Int]
            #expect(graph.cutSize(of: s) == 3)
            #expect(graph.volume(of: s) == 5)
            #expect(graph.conductance(of: s) == 0.75)
            #expect(graph.normalizedCutSize(of: s) == 1.35)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 1.3333333333333333)
            #expect(graph.boundaryExpansion(of: s) == 0.6666666666666666)
            #expect(graph.cutSize(of: s, weight: { weights[edgeOf[$0]!] }) == 35)
            #expect(graph.volume(of: s, weight: { weights[edgeOf[$0]!] }) == 59)
            #expect(graph.conductance(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 0.875)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 1.468220338983051)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 11.666666666666666)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 0.17676767676767677)
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let positionOfEdge = pairs.map { p in graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }! }
            let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })
            let s = [0, 1, 2] as [Int]
            #expect(graph.cutSize(of: s) == 3)
            #expect(graph.volume(of: s) == 5)
            #expect(graph.conductance(of: s) == 0.75)
            #expect(graph.normalizedCutSize(of: s) == 1.35)
            #expect(graph.edgeExpansion(of: s) == 1.0)
            #expect(graph.mixingExpansion(of: s) == 0.16666666666666666)
            #expect(graph.nodeExpansion(of: s) == 1.3333333333333333)
            #expect(graph.boundaryExpansion(of: s) == 0.6666666666666666)
            #expect(graph.cutSize(of: s, weight: { weights[edgeOf[$0]!] }) == 35)
            #expect(graph.volume(of: s, weight: { weights[edgeOf[$0]!] }) == 59)
            #expect(graph.conductance(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 0.875)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 1.468220338983051)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 11.666666666666666)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[edgeOf[$0]!]) }) == 0.17676767676767677)
        }
    }

    @Test("FL-568 directed: lcgnet(12,40,3,5), on ReferenceDirectedMultigraph, no indices")
    func fl568() {
        // lcgnet(12,40,3,5); cut metrics of [1, 4, 5, 6, 11]
        let pairs: [(Int, Int)] = [(11, 7), (10, 0), (7, 5), (9, 7), (8, 9), (5, 3), (7, 8), (10, 11), (5, 11), (7, 1), (1, 6), (7, 5), (9, 3), (9, 0), (0, 5), (2, 5), (1, 5), (5, 11), (8, 5), (2, 1), (11, 3), (1, 11), (0, 6), (2, 9), (7, 3), (3, 9), (9, 3), (0, 9), (10, 4), (9, 11), (2, 11), (3, 9), (2, 10), (4, 9), (9, 4), (5, 0), (8, 5), (11, 9), (11, 1), (11, 3)]
        let weights: [Int] = [1, 4, 5, 3, 4, 5, 1, 2, 4, 5, 2, 4, 4, 2, 1, 2, 2, 2, 2, 1, 2, 5, 5, 1, 4, 5, 5, 4, 5, 1, 1, 4, 1, 1, 2, 5, 2, 1, 4, 2]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let s = [1, 4, 5, 6, 11] as [Int]
            #expect(graph.cutSize(of: s) == 21)
            #expect(graph.volume(of: s) == 13)
            #expect(graph.conductance(of: s) == 1.6153846153846154)
            #expect(graph.normalizedCutSize(of: s) == 2.393162393162393)
            #expect(graph.edgeExpansion(of: s) == 4.2)
            #expect(graph.mixingExpansion(of: s) == 0.2625)
            #expect(graph.nodeExpansion(of: s) == 1.6)
            #expect(graph.boundaryExpansion(of: s) == 0.8)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 55)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 36)
            #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 1.5277777777777777)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 2.2152777777777777)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 11.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.23706896551724138)
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let s = [1, 4, 5, 6, 11] as [Int]
            #expect(graph.cutSize(of: s) == 21)
            #expect(graph.volume(of: s) == 13)
            #expect(graph.conductance(of: s) == 1.6153846153846154)
            #expect(graph.normalizedCutSize(of: s) == 2.393162393162393)
            #expect(graph.edgeExpansion(of: s) == 4.2)
            #expect(graph.mixingExpansion(of: s) == 0.2625)
            #expect(graph.nodeExpansion(of: s) == 1.6)
            #expect(graph.boundaryExpansion(of: s) == 0.8)
            #expect(graph.cutSize(of: s, weight: { weights[$0] }) == 55)
            #expect(graph.volume(of: s, weight: { weights[$0] }) == 36)
            #expect(graph.conductance(of: s, weight: { Double(weights[$0]) }) == 1.5277777777777777)
            #expect(graph.normalizedCutSize(of: s, weight: { Double(weights[$0]) }) == 2.2152777777777777)
            #expect(graph.edgeExpansion(of: s, weight: { Double(weights[$0]) }) == 11.0)
            #expect(graph.mixingExpansion(of: s, weight: { Double(weights[$0]) }) == 0.23706896551724138)
        }
    }
}
