// Triangular and hexagonal lattices (catalog NG-199 – NG-213): sized by triangles and hexagons, nodes
// numbered row by row (triangular) or column by column (hexagonal). Both arcs when directed.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing

@Suite("NamedGraphs triangular and hexagonal lattices")
struct TriangularHexagonalLatticeTests {
    @Test("NG-199 1 × 1 triangles: one triangle")
    func ng199() {
        // UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 1, columnCount: 1) → n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect((0 ..< 3).map { graph.vertexIndex(of: $0) } == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.degree(of: $0) } == [2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 3).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 2], [0, 1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 3).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 1, columnCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.triangularLattice(rowCount: 1, columnCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.triangularLattice(rowCount: 1, columnCount: 1), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect((0 ..< 3).map { graph.vertexIndex(of: $0) } == Array(0 ..< 3), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 3).map { graph.successors(of: $0).sorted() } == [[1, 2], [0, 2], [0, 1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 3).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(CompressedSparseRow.triangularLattice(rowCount: 1, columnCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.triangularLattice(rowCount: 1, columnCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.triangularLattice(rowCount: 1, columnCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.triangularLattice(rowCount: 1, columnCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.triangularLattice(rowCount: 1, columnCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.triangularLattice(rowCount: 1, columnCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-200 1 × 2 triangles: a rhombus")
    func ng200() {
        // UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 1, columnCount: 2) → n 4; m 5; deg [2, 3, 3, 2]; E [0–1, 0–2, 1–2, 1–3, 2–3]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [1, 3], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [2, 3, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 2, 3], [0, 1, 3], [1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 1, columnCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.triangularLattice(rowCount: 1, columnCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.triangularLattice(rowCount: 1, columnCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [1, 3], [2, 0], [2, 1], [2, 3], [3, 1], [3, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [2, 3, 3, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 3, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2], [0, 2, 3], [0, 1, 3], [1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.triangularLattice(rowCount: 1, columnCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.triangularLattice(rowCount: 1, columnCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.triangularLattice(rowCount: 1, columnCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.triangularLattice(rowCount: 1, columnCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.triangularLattice(rowCount: 1, columnCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.triangularLattice(rowCount: 1, columnCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-201 2 × 3 triangles: odd n, odd rows one shorter")
    func ng201() {
        // UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: 3) → n 8; m 13; deg [2, 4, 2, 5, 5, 2, 4, 2]; E [0–1, 0–3, 1–2, 1–3, 1–4, 2–4, 3–4, 3–5, 3–6, 4–6, 4–7, 5–6, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 13 && graph.edges.count == 13, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [1, 3], [1, 4], [2, 4], [3, 4], [3, 5], [3, 6], [4, 6], [4, 7], [5, 6], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [2, 4, 2, 5, 5, 2, 4, 2] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2, 3, 4], [1, 4], [0, 1, 4, 5, 6], [1, 2, 3, 6, 7], [3, 6], [3, 4, 5, 7], [4, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.triangularLattice(rowCount: 2, columnCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.triangularLattice(rowCount: 2, columnCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 26 && graph.edges.count == 26, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [1, 0], [1, 2], [1, 3], [1, 4], [2, 1], [2, 4], [3, 0], [3, 1], [3, 4], [3, 5], [3, 6], [4, 1], [4, 2], [4, 3], [4, 6], [4, 7], [5, 3], [5, 6], [6, 3], [6, 4], [6, 5], [6, 7], [7, 4], [7, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [2, 4, 2, 5, 5, 2, 4, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 4, 2, 5, 5, 2, 4, 2] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 3], [0, 2, 3, 4], [1, 4], [0, 1, 4, 5, 6], [1, 2, 3, 6, 7], [3, 6], [3, 4, 5, 7], [4, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.triangularLattice(rowCount: 2, columnCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.triangularLattice(rowCount: 2, columnCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.triangularLattice(rowCount: 2, columnCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.triangularLattice(rowCount: 2, columnCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.triangularLattice(rowCount: 2, columnCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-202 2 × 4 triangles")
    func ng202() {
        // UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: 4) → n 9; m 16; deg [2, 4, 3, 5, 6, 3, 2, 4, 3]; E [0–1, 0–3, 1–2, 1–3, 1–4, 2–4, 2–5, 3–4, 3–6, 3–7, 4–5, 4–7, 4–8, 5–8, 6–7, 7–8]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 9 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 9), "\(type)")
            #expect((0 ..< 9).map { graph.vertexIndex(of: $0) } == Array(0 ..< 9), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [1, 3], [1, 4], [2, 4], [2, 5], [3, 4], [3, 6], [3, 7], [4, 5], [4, 7], [4, 8], [5, 8], [6, 7], [7, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 9).map { graph.degree(of: $0) } == [2, 4, 3, 5, 6, 3, 2, 4, 3] as [Int], "\(type)")
            #expect((0 ..< 9).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2, 3, 4], [1, 4, 5], [0, 1, 4, 6, 7], [1, 2, 3, 5, 7, 8], [2, 4, 8], [3, 7], [3, 4, 6, 8], [4, 5, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 9).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.triangularLattice(rowCount: 2, columnCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.triangularLattice(rowCount: 2, columnCount: 4), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 9 && graph.edgeCount == 32 && graph.edges.count == 32, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 9), "\(type)")
            #expect((0 ..< 9).map { graph.vertexIndex(of: $0) } == Array(0 ..< 9), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 9)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [1, 0], [1, 2], [1, 3], [1, 4], [2, 1], [2, 4], [2, 5], [3, 0], [3, 1], [3, 4], [3, 6], [3, 7], [4, 1], [4, 2], [4, 3], [4, 5], [4, 7], [4, 8], [5, 2], [5, 4], [5, 8], [6, 3], [6, 7], [7, 3], [7, 4], [7, 6], [7, 8], [8, 4], [8, 5], [8, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 9).map { graph.outDegree(of: $0) } == [2, 4, 3, 5, 6, 3, 2, 4, 3] as [Int], "\(type)")
            #expect(inDegrees == [2, 4, 3, 5, 6, 3, 2, 4, 3] as [Int], "\(type)")
            #expect((0 ..< 9).map { graph.successors(of: $0).sorted() } == [[1, 3], [0, 2, 3, 4], [1, 4, 5], [0, 1, 4, 6, 7], [1, 2, 3, 5, 7, 8], [2, 4, 8], [3, 7], [3, 4, 6, 8], [4, 5, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 9).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.triangularLattice(rowCount: 2, columnCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.triangularLattice(rowCount: 2, columnCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.triangularLattice(rowCount: 2, columnCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.triangularLattice(rowCount: 2, columnCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.triangularLattice(rowCount: 2, columnCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-203 3 × 2 triangles")
    func ng203() {
        // UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 3, columnCount: 2) → n 8; m 13; deg [2, 3, 5, 3, 3, 5, 3, 2]; E [0–1, 0–2, 1–2, 1–3, 2–3, 2–4, 2–5, 3–5, 4–5, 4–6, 5–6, 5–7, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 13 && graph.edges.count == 13, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [1, 3], [2, 3], [2, 4], [2, 5], [3, 5], [4, 5], [4, 6], [5, 6], [5, 7], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [2, 3, 5, 3, 3, 5, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 2, 3], [0, 1, 3, 4, 5], [1, 2, 5], [2, 5, 6], [2, 3, 4, 6, 7], [4, 5, 7], [5, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 3, columnCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.triangularLattice(rowCount: 3, columnCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.triangularLattice(rowCount: 3, columnCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 26 && graph.edges.count == 26, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [1, 3], [2, 0], [2, 1], [2, 3], [2, 4], [2, 5], [3, 1], [3, 2], [3, 5], [4, 2], [4, 5], [4, 6], [5, 2], [5, 3], [5, 4], [5, 6], [5, 7], [6, 4], [6, 5], [6, 7], [7, 5], [7, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [2, 3, 5, 3, 3, 5, 3, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 3, 5, 3, 3, 5, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 2], [0, 2, 3], [0, 1, 3, 4, 5], [1, 2, 5], [2, 5, 6], [2, 3, 4, 6, 7], [4, 5, 7], [5, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.triangularLattice(rowCount: 3, columnCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.triangularLattice(rowCount: 3, columnCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.triangularLattice(rowCount: 3, columnCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.triangularLattice(rowCount: 3, columnCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.triangularLattice(rowCount: 3, columnCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.triangularLattice(rowCount: 3, columnCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-204 0 × 3 triangles: no rows, the null graph")
    func ng204() {
        // UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 0, columnCount: 3) → n 0; m 0; deg []; E []
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 0), "\(type)")
            #expect((0 ..< 0).map { graph.vertexIndex(of: $0) } == Array(0 ..< 0), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 0).map { graph.degree(of: $0) } == [] as [Int], "\(type)")
            #expect((0 ..< 0).map { graph.neighbors(of: $0).sorted() } == [] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 0).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 0, columnCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.triangularLattice(rowCount: 0, columnCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.triangularLattice(rowCount: 0, columnCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 0), "\(type)")
            #expect((0 ..< 0).map { graph.vertexIndex(of: $0) } == Array(0 ..< 0), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 0)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 0).map { graph.outDegree(of: $0) } == [] as [Int], "\(type)")
            #expect(inDegrees == [] as [Int], "\(type)")
            #expect((0 ..< 0).map { graph.successors(of: $0).sorted() } == [] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 0).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(CompressedSparseRow.triangularLattice(rowCount: 0, columnCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.triangularLattice(rowCount: 0, columnCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.triangularLattice(rowCount: 0, columnCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.triangularLattice(rowCount: 0, columnCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.triangularLattice(rowCount: 0, columnCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.triangularLattice(rowCount: 0, columnCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-205 directed: both arcs")
    func ng205() {
        // CompressedSparseRow.triangularLattice(rowCount: 2, columnCount: 2) → n 6; m 18; out [2, 3, 5, 3, 2, 3]; in [2, 3, 5, 3, 2, 3]; E [0→1, 0→2, 1→0, 1→2, 1→3, 2→0, 2→1, 2→3, 2→4, 2→5, 3→1, 3→2, 3→5, 4→2, 4→5, 5→2, 5→3, 5→4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [1, 3], [2, 3], [2, 4], [2, 5], [3, 5], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 3, 5, 3, 2, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 2, 3], [0, 1, 3, 4, 5], [1, 2, 5], [2, 5], [2, 3, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.triangularLattice(rowCount: 2, columnCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.triangularLattice(rowCount: 2, columnCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [1, 3], [2, 0], [2, 1], [2, 3], [2, 4], [2, 5], [3, 1], [3, 2], [3, 5], [4, 2], [4, 5], [5, 2], [5, 3], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 3, 5, 3, 2, 3] as [Int], "\(type)")
            #expect(inDegrees == [2, 3, 5, 3, 2, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 2], [0, 2, 3], [0, 1, 3, 4, 5], [1, 2, 5], [2, 5], [2, 3, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.triangularLattice(rowCount: 2, columnCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.triangularLattice(rowCount: 2, columnCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.triangularLattice(rowCount: 2, columnCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.triangularLattice(rowCount: 2, columnCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.triangularLattice(rowCount: 2, columnCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-207 1 × 1 hexagons is C6")
    func ng207() {
        // UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 1) → n 6; m 6; deg [2, 2, 2, 2, 2, 2]; E [0–1, 0–3, 1–2, 2–5, 3–4, 4–5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [2, 5], [3, 4], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2], [1, 5], [0, 4], [3, 5], [2, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hexagonalLattice(rowCount: 1, columnCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 1), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [1, 0], [1, 2], [2, 1], [2, 5], [3, 0], [3, 4], [4, 3], [4, 5], [5, 2], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 3], [0, 2], [1, 5], [0, 4], [3, 5], [2, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hexagonalLattice(rowCount: 1, columnCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hexagonalLattice(rowCount: 1, columnCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hexagonalLattice(rowCount: 1, columnCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-208 1 × 2 hexagons")
    func ng208() {
        // UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 2) → n 10; m 11; deg [2, 2, 2, 2, 3, 3, 2, 2, 2, 2]; E [0–1, 0–3, 1–2, 2–5, 3–4, 4–5, 4–7, 5–6, 6–9, 7–8, 8–9]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [2, 5], [3, 4], [4, 5], [4, 7], [5, 6], [6, 9], [7, 8], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [2, 2, 2, 2, 3, 3, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2], [1, 5], [0, 4], [3, 5, 7], [2, 4, 6], [5, 9], [4, 8], [7, 9], [6, 8]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 22 && graph.edges.count == 22, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [1, 0], [1, 2], [2, 1], [2, 5], [3, 0], [3, 4], [4, 3], [4, 5], [4, 7], [5, 2], [5, 4], [5, 6], [6, 5], [6, 9], [7, 4], [7, 8], [8, 7], [8, 9], [9, 6], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 3, 3, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2, 3, 3, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.successors(of: $0).sorted() } == [[1, 3], [0, 2], [1, 5], [0, 4], [3, 5, 7], [2, 4, 6], [5, 9], [4, 8], [7, 9], [6, 8]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hexagonalLattice(rowCount: 1, columnCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hexagonalLattice(rowCount: 1, columnCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-209 2 × 1 hexagons")
    func ng209() {
        // UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 2, columnCount: 1) → n 10; m 11; deg [2, 2, 3, 2, 2, 2, 2, 3, 2, 2]; E [0–1, 0–5, 1–2, 2–3, 2–7, 3–4, 4–9, 5–6, 6–7, 7–8, 8–9]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 5], [1, 2], [2, 3], [2, 7], [3, 4], [4, 9], [5, 6], [6, 7], [7, 8], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [2, 2, 3, 2, 2, 2, 2, 3, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.neighbors(of: $0).sorted() } == [[1, 5], [0, 2], [1, 3, 7], [2, 4], [3, 9], [0, 6], [5, 7], [2, 6, 8], [7, 9], [4, 8]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 2, columnCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hexagonalLattice(rowCount: 2, columnCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.hexagonalLattice(rowCount: 2, columnCount: 1), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 22 && graph.edges.count == 22, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [1, 0], [1, 2], [2, 1], [2, 3], [2, 7], [3, 2], [3, 4], [4, 3], [4, 9], [5, 0], [5, 6], [6, 5], [6, 7], [7, 2], [7, 6], [7, 8], [8, 7], [8, 9], [9, 4], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [2, 2, 3, 2, 2, 2, 2, 3, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 3, 2, 2, 2, 2, 3, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.successors(of: $0).sorted() } == [[1, 5], [0, 2], [1, 3, 7], [2, 4], [3, 9], [0, 6], [5, 7], [2, 6, 8], [7, 9], [4, 8]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hexagonalLattice(rowCount: 2, columnCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hexagonalLattice(rowCount: 2, columnCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hexagonalLattice(rowCount: 2, columnCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hexagonalLattice(rowCount: 2, columnCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hexagonalLattice(rowCount: 2, columnCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hexagonalLattice(rowCount: 2, columnCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-210 2 × 2 hexagons")
    func ng210() {
        // UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 2, columnCount: 2) → n 16; m 19; deg [2, 2, 3, 2, 2, 2, 3, 3, 3, 3, 2, 2, 2, 3, 2, 2]; E [0–1, 0–5, 1–2, 2–3, 2–7, 3–4, 4–9, 5–6, 6–7, 6–11, 7–8, 8–9, 8–13, 9–10, 10–15, 11–12, 12–13, 13–14, 14–15]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 16 && graph.edgeCount == 19 && graph.edges.count == 19, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 16), "\(type)")
            #expect((0 ..< 16).map { graph.vertexIndex(of: $0) } == Array(0 ..< 16), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 5], [1, 2], [2, 3], [2, 7], [3, 4], [4, 9], [5, 6], [6, 7], [6, 11], [7, 8], [8, 9], [8, 13], [9, 10], [10, 15], [11, 12], [12, 13], [13, 14], [14, 15]] as [[Int]], "\(type)")
            #expect((0 ..< 16).map { graph.degree(of: $0) } == [2, 2, 3, 2, 2, 2, 3, 3, 3, 3, 2, 2, 2, 3, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 16).map { graph.neighbors(of: $0).sorted() } == [[1, 5], [0, 2], [1, 3, 7], [2, 4], [3, 9], [0, 6], [5, 7, 11], [2, 6, 8], [7, 9, 13], [4, 8, 10], [9, 15], [6, 12], [11, 13], [8, 12, 14], [13, 15], [10, 14]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 16).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 2, columnCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hexagonalLattice(rowCount: 2, columnCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.hexagonalLattice(rowCount: 2, columnCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 16 && graph.edgeCount == 38 && graph.edges.count == 38, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 16), "\(type)")
            #expect((0 ..< 16).map { graph.vertexIndex(of: $0) } == Array(0 ..< 16), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 16)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [1, 0], [1, 2], [2, 1], [2, 3], [2, 7], [3, 2], [3, 4], [4, 3], [4, 9], [5, 0], [5, 6], [6, 5], [6, 7], [6, 11], [7, 2], [7, 6], [7, 8], [8, 7], [8, 9], [8, 13], [9, 4], [9, 8], [9, 10], [10, 9], [10, 15], [11, 6], [11, 12], [12, 11], [12, 13], [13, 8], [13, 12], [13, 14], [14, 13], [14, 15], [15, 10], [15, 14]] as [[Int]], "\(type)")
            #expect((0 ..< 16).map { graph.outDegree(of: $0) } == [2, 2, 3, 2, 2, 2, 3, 3, 3, 3, 2, 2, 2, 3, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 3, 2, 2, 2, 3, 3, 3, 3, 2, 2, 2, 3, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 16).map { graph.successors(of: $0).sorted() } == [[1, 5], [0, 2], [1, 3, 7], [2, 4], [3, 9], [0, 6], [5, 7, 11], [2, 6, 8], [7, 9, 13], [4, 8, 10], [9, 15], [6, 12], [11, 13], [8, 12, 14], [13, 15], [10, 14]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 16).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hexagonalLattice(rowCount: 2, columnCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hexagonalLattice(rowCount: 2, columnCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hexagonalLattice(rowCount: 2, columnCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hexagonalLattice(rowCount: 2, columnCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hexagonalLattice(rowCount: 2, columnCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hexagonalLattice(rowCount: 2, columnCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-211 1 × 3 hexagons: odd n drops the top of the last column")
    func ng211() {
        // UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 3) → n 14; m 16; deg [2, 2, 2, 2, 3, 3, 2, 2, 3, 3, 2, 2, 2, 2]; E [0–1, 0–3, 1–2, 2–5, 3–4, 4–5, 4–8, 5–6, 6–10, 7–8, 7–11, 8–9, 9–10, 9–13, 11–12, 12–13]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 14 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 14), "\(type)")
            #expect((0 ..< 14).map { graph.vertexIndex(of: $0) } == Array(0 ..< 14), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [2, 5], [3, 4], [4, 5], [4, 8], [5, 6], [6, 10], [7, 8], [7, 11], [8, 9], [9, 10], [9, 13], [11, 12], [12, 13]] as [[Int]], "\(type)")
            #expect((0 ..< 14).map { graph.degree(of: $0) } == [2, 2, 2, 2, 3, 3, 2, 2, 3, 3, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 14).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2], [1, 5], [0, 4], [3, 5, 8], [2, 4, 6], [5, 10], [8, 11], [4, 7, 9], [8, 10, 13], [6, 9], [7, 12], [11, 13], [9, 12]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 14).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hexagonalLattice(rowCount: 1, columnCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 14 && graph.edgeCount == 32 && graph.edges.count == 32, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 14), "\(type)")
            #expect((0 ..< 14).map { graph.vertexIndex(of: $0) } == Array(0 ..< 14), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 14)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [1, 0], [1, 2], [2, 1], [2, 5], [3, 0], [3, 4], [4, 3], [4, 5], [4, 8], [5, 2], [5, 4], [5, 6], [6, 5], [6, 10], [7, 8], [7, 11], [8, 4], [8, 7], [8, 9], [9, 8], [9, 10], [9, 13], [10, 6], [10, 9], [11, 7], [11, 12], [12, 11], [12, 13], [13, 9], [13, 12]] as [[Int]], "\(type)")
            #expect((0 ..< 14).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 3, 3, 2, 2, 3, 3, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2, 3, 3, 2, 2, 3, 3, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 14).map { graph.successors(of: $0).sorted() } == [[1, 3], [0, 2], [1, 5], [0, 4], [3, 5, 8], [2, 4, 6], [5, 10], [8, 11], [4, 7, 9], [8, 10, 13], [6, 9], [7, 12], [11, 13], [9, 12]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 14).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hexagonalLattice(rowCount: 1, columnCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hexagonalLattice(rowCount: 1, columnCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hexagonalLattice(rowCount: 1, columnCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-212 3 × 0 hexagons: no columns, the null graph")
    func ng212() {
        // UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 3, columnCount: 0) → n 0; m 0; deg []; E []
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 0), "\(type)")
            #expect((0 ..< 0).map { graph.vertexIndex(of: $0) } == Array(0 ..< 0), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 0).map { graph.degree(of: $0) } == [] as [Int], "\(type)")
            #expect((0 ..< 0).map { graph.neighbors(of: $0).sorted() } == [] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 0).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 3, columnCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hexagonalLattice(rowCount: 3, columnCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.hexagonalLattice(rowCount: 3, columnCount: 0), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 0), "\(type)")
            #expect((0 ..< 0).map { graph.vertexIndex(of: $0) } == Array(0 ..< 0), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 0)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 0).map { graph.outDegree(of: $0) } == [] as [Int], "\(type)")
            #expect(inDegrees == [] as [Int], "\(type)")
            #expect((0 ..< 0).map { graph.successors(of: $0).sorted() } == [] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 0).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(CompressedSparseRow.hexagonalLattice(rowCount: 3, columnCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hexagonalLattice(rowCount: 3, columnCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hexagonalLattice(rowCount: 3, columnCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hexagonalLattice(rowCount: 3, columnCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hexagonalLattice(rowCount: 3, columnCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hexagonalLattice(rowCount: 3, columnCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-213 directed: both arcs")
    func ng213() {
        // CompressedSparseRow.hexagonalLattice(rowCount: 1, columnCount: 2) → n 10; m 22; out [2, 2, 2, 2, 3, 3, 2, 2, 2, 2]; in [2, 2, 2, 2, 3, 3, 2, 2, 2, 2]; E [0→1, 0→3, 1→0, 1→2, 2→1, 2→5, 3→0, 3→4, 4→3, 4→5, 4→7, 5→2, 5→4, 5→6, 6→5, 6→9, 7→4, 7→8, 8→7, 8→9, 9→6, 9→8]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [2, 5], [3, 4], [4, 5], [4, 7], [5, 6], [6, 9], [7, 8], [8, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [2, 2, 2, 2, 3, 3, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2], [1, 5], [0, 4], [3, 5, 7], [2, 4, 6], [5, 9], [4, 8], [7, 9], [6, 8]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 22 && graph.edges.count == 22, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [1, 0], [1, 2], [2, 1], [2, 5], [3, 0], [3, 4], [4, 3], [4, 5], [4, 7], [5, 2], [5, 4], [5, 6], [6, 5], [6, 9], [7, 4], [7, 8], [8, 7], [8, 9], [9, 6], [9, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 3, 3, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2, 3, 3, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.successors(of: $0).sorted() } == [[1, 3], [0, 2], [1, 5], [0, 4], [3, 5, 7], [2, 4, 6], [5, 9], [4, 8], [7, 9], [6, 8]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hexagonalLattice(rowCount: 1, columnCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hexagonalLattice(rowCount: 1, columnCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hexagonalLattice(rowCount: 1, columnCount: 2), "StableDirectedGraph<Int>")
    }
}
