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

@Suite("Disjoint paths on every representation")
struct DisjointPathsRepresentationTests {
    @Test("FL-502 one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl502() {
        // V [0, 1]; E [0→1]; edgeDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.edgeDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-503 one edge, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl503() {
        // V [0, 1]; E [0→1]; vertexDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.vertexDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1)]
            let graph = AdjacencyMatrix(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-504 no path, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl504() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; edgeDisjointPaths(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let paths = graph.edgeDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 0)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 0)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let paths = graph.edgeDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 0)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 0)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-505 no path, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl505() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; vertexDisjointPaths(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let paths = graph.vertexDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 0)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 0)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let paths = graph.vertexDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 0)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 0)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-506 K(2) with parallel edges: each copy an edge path, one vertex path, on ReferencePseudograph, no indices")
    func fl506() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; edgeDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let paths = graph.edgeDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 3)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 3)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-507 K(2) with parallel edges: each copy an edge path, one vertex path, on ReferencePseudograph, no indices")
    func fl507() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; vertexDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let paths = graph.vertexDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-508 directed: adjacent pair: the edge counts as one path, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl508() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; edgeDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.edgeDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-509 directed: adjacent pair: the edge counts as one path, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl509() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; vertexDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.vertexDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
            let graph = AdjacencyMatrix(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 1)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-510 directed: parallel arcs, on ReferenceDirectedMultigraph, no indices")
    func fl510() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; edgeDisjointPaths(from: 2, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.edgeDisjointPaths(from: 2, to: 1)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 2 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 2, to: 1)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 2 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-511 directed: parallel arcs, on ReferenceDirectedMultigraph, no indices")
    func fl511() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; vertexDisjointPaths(from: 2, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        do { // ReferenceDirectedMultigraph
            let graph = ReferenceDirectedMultigraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.vertexDisjointPaths(from: 2, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 2 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 2, to: 1)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 2 && $0.vertices.last == 1 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-512 two triangles sharing a vertex: 2 edge paths, 1 vertex path, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl512() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; edgeDisjointPaths(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let paths = graph.edgeDisjointPaths(from: 0, to: 4)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 4 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 0, to: 4)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 4 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let paths = graph.edgeDisjointPaths(from: 0, to: 4)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 4 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 4)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 4 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-513 two triangles sharing a vertex: 2 edge paths, 1 vertex path, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl513() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; vertexDisjointPaths(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let paths = graph.vertexDisjointPaths(from: 0, to: 4)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 4 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 0, to: 4)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 4 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let paths = graph.vertexDisjointPaths(from: 0, to: 4)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 4 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 4)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 4 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-514 CLRS figure 26.1, unit, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl514() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1, s→v2, v1→v3, v2→v1, v2→v4, v3→v2, v3→t, v4→v3, v4→t]; edgeDisjointPaths(from: s, to: t)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.edgeDisjointPaths(from: "s", to: "t")
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == "s" && $0.vertices.last == "t" })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: "s", to: "t")
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == "s" && $0.vertices.last == "t" })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 5)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 5 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 5)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 5 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-515 CLRS figure 26.1, unit, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl515() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1, s→v2, v1→v3, v2→v1, v2→v4, v3→v2, v3→t, v4→v3, v4→t]; vertexDisjointPaths(from: s, to: t)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.vertexDisjointPaths(from: "s", to: "t")
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == "s" && $0.vertices.last == "t" })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: "s", to: "t")
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == "s" && $0.vertices.last == "t" })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = CompressedSparseRow(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 5)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 5 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 1), (2, 4), (3, 2), (3, 5), (4, 3), (4, 5)]
            let graph = AdjacencyMatrix(vertexCount: 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 5)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 5 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-516 Petersen, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl516() {
        // nx(petersen_graph); edgeDisjointPaths(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let paths = graph.edgeDisjointPaths(from: 0, to: 7)
            #expect(paths.count == 3)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 7 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 0, to: 7)
            #expect(paths.count == 3)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 7 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let paths = graph.edgeDisjointPaths(from: 0, to: 7)
            #expect(paths.count == 3)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 7 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 7)
            #expect(paths.count == 3)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 7 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-517 Petersen, on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl517() {
        // nx(petersen_graph); vertexDisjointPaths(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let paths = graph.vertexDisjointPaths(from: 0, to: 7)
            #expect(paths.count == 3)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 7 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 0, to: 7)
            #expect(paths.count == 3)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 7 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let paths = graph.vertexDisjointPaths(from: 0, to: 7)
            #expect(paths.count == 3)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 7 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
            let graph = AdjacencyMatrix(vertexCount: 10, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 7)
            #expect(paths.count == 3)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 7 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-518 grid(3,4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl518() {
        // grid(3,4); edgeDisjointPaths(from: 0, to: 11)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let paths = graph.edgeDisjointPaths(from: 0, to: 11)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 11 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 0, to: 11)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 11 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let paths = graph.edgeDisjointPaths(from: 0, to: 11)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 11 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 11)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 11 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-519 grid(3,4), on Pseudograph, no indices, AdjacencyList.undirected, AdjacencyMatrix.undirected")
    func fl519() {
        // grid(3,4); vertexDisjointPaths(from: 0, to: 11)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        do { // Pseudograph
            let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let paths = graph.vertexDisjointPaths(from: 0, to: 11)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 11 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 0, to: 11)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 11 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyList.undirected
            let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            let paths = graph.vertexDisjointPaths(from: 0, to: 11)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 11 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyMatrix.undirected
            let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
            let graph = AdjacencyMatrix(vertexCount: 12, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 11)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 11 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-520 directed: bidirected C(5), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl520() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; edgeDisjointPaths(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.edgeDisjointPaths(from: 0, to: 2)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 2 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 0, to: 2)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 2 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 2)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 2 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 2)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 2 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-521 directed: bidirected C(5), on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl521() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; vertexDisjointPaths(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.vertexDisjointPaths(from: 0, to: 2)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 2 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 0, to: 2)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 2 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = CompressedSparseRow(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 2)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 2 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
            let graph = AdjacencyMatrix(vertexCount: 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 2)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 2 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-522 self-loops and a cycle on the way, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl522() {
        // V [0, 1, 2, 3]; E [0→0, 0→1, 1→2, 2→1, 2→3, 1→1, 0→2]; edgeDisjointPaths(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 1), (2, 3), (1, 1), (0, 2)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.edgeDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 1), (2, 3), (1, 1), (0, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 1), (2, 3), (1, 1), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-523 self-loops and a cycle on the way, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl523() {
        // V [0, 1, 2, 3]; E [0→0, 0→1, 1→2, 2→1, 2→3, 1→1, 0→2]; vertexDisjointPaths(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 1), (2, 3), (1, 1), (0, 2)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.vertexDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 1), (2, 3), (1, 1), (0, 2)]
            let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 1), (2, 3), (1, 1), (0, 2)]
            let graph = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 0, to: 3)
            #expect(paths.count == 1)
            #expect(paths.allSatisfy { $0.vertices.first == 0 && $0.vertices.last == 3 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }

    @Test("FL-530 directed: a flow cycle the decomposition drops, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl530() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [3→6, 5→8, 0→7, 7→0, 7→3, 8→4, 0→6, 5→7, 4→0]; edgeDisjointPaths(from: 5, to: 6)
        let pairs: [(Int, Int)] = [(3, 6), (5, 8), (0, 7), (7, 0), (7, 3), (8, 4), (0, 6), (5, 7), (4, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.edgeDisjointPaths(from: 5, to: 6)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 5 && $0.vertices.last == 6 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.edgeDisjointPaths(from: 5, to: 6)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 5 && $0.vertices.last == 6 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(3, 6), (5, 8), (0, 7), (7, 0), (7, 3), (8, 4), (0, 6), (5, 7), (4, 0)]
            let graph = CompressedSparseRow(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 5, to: 6)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 5 && $0.vertices.last == 6 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(3, 6), (5, 8), (0, 7), (7, 0), (7, 3), (8, 4), (0, 6), (5, 7), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.edgeDisjointPaths(from: 5, to: 6)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 5 && $0.vertices.last == 6 })
            #expect(Set(paths.flatMap(\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })
        }
    }

    @Test("FL-531 directed: a flow cycle the decomposition drops, on DirectedPseudograph, no indices, CompressedSparseRow, AdjacencyMatrix")
    func fl531() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [3→6, 5→8, 0→7, 7→0, 7→3, 8→4, 0→6, 5→7, 4→0]; vertexDisjointPaths(from: 5, to: 6)
        let pairs: [(Int, Int)] = [(3, 6), (5, 8), (0, 7), (7, 0), (7, 3), (8, 4), (0, 6), (5, 7), (4, 0)]
        do { // DirectedPseudograph
            let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let paths = graph.vertexDisjointPaths(from: 5, to: 6)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 5 && $0.vertices.last == 6 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // no indices
            let graph = UnindexedDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
            let paths = graph.vertexDisjointPaths(from: 5, to: 6)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 5 && $0.vertices.last == 6 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // CompressedSparseRow
            let pairs: [(Int, Int)] = [(3, 6), (5, 8), (0, 7), (7, 0), (7, 3), (8, 4), (0, 6), (5, 7), (4, 0)]
            let graph = CompressedSparseRow(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 5, to: 6)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 5 && $0.vertices.last == 6 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
        do { // AdjacencyMatrix
            let pairs: [(Int, Int)] = [(3, 6), (5, 8), (0, 7), (7, 0), (7, 3), (8, 4), (0, 6), (5, 7), (4, 0)]
            let graph = AdjacencyMatrix(vertexCount: 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Positions here are row-major cells: each catalog edge's position, and back.
            let paths = graph.vertexDisjointPaths(from: 5, to: 6)
            #expect(paths.count == 2)
            #expect(paths.allSatisfy { $0.vertices.first == 5 && $0.vertices.last == 6 })
            #expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })
        }
    }
}
