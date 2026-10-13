// Grids, hypercubes, the Petersen graph and empty graphs (catalog NG-052 – NG-082): grids row-major
// with the last dimension fastest, periodic wraps only in dimensions of length ≥ 3; Q_d by bits;
// Petersen as outer 0–4, spokes i – i+5, inner pentagram; both arcs when directed.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing

@Suite("NamedGraphs grids, hypercubes, Petersen and empty graphs")
struct GridHypercubePetersenTests {
    @Test("NG-052 3")
    func ng052() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [3]) → n 3; m 2; deg [1, 2, 1]; E [0–1, 1–2]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 2 && graph.edges.count == 2, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect((0 ..< 3).map { graph.vertexIndex(of: $0) } == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.degree(of: $0) } == [1, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 3).map { graph.neighbors(of: $0).sorted() } == [[1], [0, 2], [1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 3).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [3]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [3]), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [3]), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect((0 ..< 3).map { graph.vertexIndex(of: $0) } == Array(0 ..< 3), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [1, 2], [2, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [1, 2, 1] as [Int], "\(type)")
            #expect(inDegrees == [1, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 3).map { graph.successors(of: $0).sorted() } == [[1], [0, 2], [1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 3).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [3]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [3]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [3]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [3]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [3]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [3]), "StableDirectedGraph<Int>")
    }

    @Test("NG-053 2×3")
    func ng053() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [2, 3]) → n 6; m 7; deg [2, 3, 2, 2, 3, 2]; E [0–1, 0–3, 1–2, 1–4, 2–5, 3–4, 4–5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [1, 4], [2, 5], [3, 4], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 3, 2, 2, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2, 4], [1, 5], [0, 4], [1, 3, 5], [2, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [2, 3]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [2, 3]), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [2, 3]), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [1, 0], [1, 2], [1, 4], [2, 1], [2, 5], [3, 0], [3, 4], [4, 1], [4, 3], [4, 5], [5, 2], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 3, 2, 2, 3, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 3, 2, 2, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 3], [0, 2, 4], [1, 5], [0, 4], [1, 3, 5], [2, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [2, 3]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [2, 3]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [2, 3]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [2, 3]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [2, 3]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [2, 3]), "StableDirectedGraph<Int>")
    }

    @Test("NG-054 3×3")
    func ng054() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [3, 3]) → n 9; m 12; deg [2, 3, 2, 3, 4, 3, 2, 3, 2]; E [0–1, 0–3, 1–2, 1–4, 2–5, 3–4, 3–6, 4–5, 4–7, 5–8, 6–7, 7–8]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 9 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 9), "\(type)")
            #expect((0 ..< 9).map { graph.vertexIndex(of: $0) } == Array(0 ..< 9), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [1, 4], [2, 5], [3, 4], [3, 6], [4, 5], [4, 7], [5, 8], [6, 7], [7, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 9).map { graph.degree(of: $0) } == [2, 3, 2, 3, 4, 3, 2, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 9).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2, 4], [1, 5], [0, 4, 6], [1, 3, 5, 7], [2, 4, 8], [3, 7], [4, 6, 8], [5, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 9).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [3, 3]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [3, 3]), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [3, 3]), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 9 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 9), "\(type)")
            #expect((0 ..< 9).map { graph.vertexIndex(of: $0) } == Array(0 ..< 9), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 9)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [1, 0], [1, 2], [1, 4], [2, 1], [2, 5], [3, 0], [3, 4], [3, 6], [4, 1], [4, 3], [4, 5], [4, 7], [5, 2], [5, 4], [5, 8], [6, 3], [6, 7], [7, 4], [7, 6], [7, 8], [8, 5], [8, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 9).map { graph.outDegree(of: $0) } == [2, 3, 2, 3, 4, 3, 2, 3, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 3, 2, 3, 4, 3, 2, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 9).map { graph.successors(of: $0).sorted() } == [[1, 3], [0, 2, 4], [1, 5], [0, 4, 6], [1, 3, 5, 7], [2, 4, 8], [3, 7], [4, 6, 8], [5, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 9).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [3, 3]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [3, 3]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [3, 3]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [3, 3]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [3, 3]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [3, 3]), "StableDirectedGraph<Int>")
    }

    @Test("NG-055 2×2×2")
    func ng055() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [2, 2, 2]) → n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3], [2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 4], [0, 3, 5], [0, 3, 6], [1, 2, 7], [0, 5, 6], [1, 4, 7], [2, 4, 7], [3, 5, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [2, 2, 2]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [2, 2, 2]), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [2, 2, 2]), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 4], [1, 0], [1, 3], [1, 5], [2, 0], [2, 3], [2, 6], [3, 1], [3, 2], [3, 7], [4, 0], [4, 5], [4, 6], [5, 1], [5, 4], [5, 7], [6, 2], [6, 4], [6, 7], [7, 3], [7, 5], [7, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 2, 4], [0, 3, 5], [0, 3, 6], [1, 2, 7], [0, 5, 6], [1, 4, 7], [2, 4, 7], [3, 5, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [2, 2, 2]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [2, 2, 2]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [2, 2, 2]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [2, 2, 2]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [2, 2, 2]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [2, 2, 2]), "StableDirectedGraph<Int>")
    }

    @Test("NG-056 0×4")
    func ng056() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [0, 4]) → n 0; m 0; deg []; E []
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
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [0, 4]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [0, 4]), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [0, 4]), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.grid(dimensions: [0, 4]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [0, 4]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [0, 4]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [0, 4]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [0, 4]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [0, 4]), "StableDirectedGraph<Int>")
    }

    @Test("NG-057 1×1")
    func ng057() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [1, 1]) → n 1; m 0; deg [0]; E []
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 1 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1), "\(type)")
            #expect((0 ..< 1).map { graph.vertexIndex(of: $0) } == Array(0 ..< 1), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 1).map { graph.degree(of: $0) } == [0] as [Int], "\(type)")
            #expect((0 ..< 1).map { graph.neighbors(of: $0).sorted() } == [[]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 1).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [1, 1]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [1, 1]), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [1, 1]), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 1 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1), "\(type)")
            #expect((0 ..< 1).map { graph.vertexIndex(of: $0) } == Array(0 ..< 1), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 1)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 1).map { graph.outDegree(of: $0) } == [0] as [Int], "\(type)")
            #expect(inDegrees == [0] as [Int], "\(type)")
            #expect((0 ..< 1).map { graph.successors(of: $0).sorted() } == [[]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 1).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [1, 1]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [1, 1]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [1, 1]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [1, 1]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [1, 1]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [1, 1]), "StableDirectedGraph<Int>")
    }

    @Test("NG-058 3 periodic")
    func ng058() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [3], periodic: true) → n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2]
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
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [3], periodic: true), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [3], periodic: true), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [3], periodic: true), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.grid(dimensions: [3], periodic: true), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [3], periodic: true), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [3], periodic: true), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [3], periodic: true), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [3], periodic: true), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [3], periodic: true), "StableDirectedGraph<Int>")
    }

    @Test("NG-059 3×4 periodic")
    func ng059() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [3, 4], periodic: true) → n 12; m 24; deg [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]; E [0–1, 0–3, 0–4, 0–8, 1–2, 1–5, 1–9, 2–3, 2–6, 2–10, 3–7, 3–11, 4–5, 4–7, 4–8, 5–6, 5–9, 6–7, 6–10, 7–11, 8–9, 8–11, 9–10, 10–11]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [0, 4], [0, 8], [1, 2], [1, 5], [1, 9], [2, 3], [2, 6], [2, 10], [3, 7], [3, 11], [4, 5], [4, 7], [4, 8], [5, 6], [5, 9], [6, 7], [6, 10], [7, 11], [8, 9], [8, 11], [9, 10], [10, 11]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.neighbors(of: $0).sorted() } == [[1, 3, 4, 8], [0, 2, 5, 9], [1, 3, 6, 10], [0, 2, 7, 11], [0, 5, 7, 8], [1, 4, 6, 9], [2, 5, 7, 10], [3, 4, 6, 11], [0, 4, 9, 11], [1, 5, 8, 10], [2, 6, 9, 11], [3, 7, 8, 10]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [3, 4], periodic: true), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [3, 4], periodic: true), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [3, 4], periodic: true), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 48 && graph.edges.count == 48, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [0, 4], [0, 8], [1, 0], [1, 2], [1, 5], [1, 9], [2, 1], [2, 3], [2, 6], [2, 10], [3, 0], [3, 2], [3, 7], [3, 11], [4, 0], [4, 5], [4, 7], [4, 8], [5, 1], [5, 4], [5, 6], [5, 9], [6, 2], [6, 5], [6, 7], [6, 10], [7, 3], [7, 4], [7, 6], [7, 11], [8, 0], [8, 4], [8, 9], [8, 11], [9, 1], [9, 5], [9, 8], [9, 10], [10, 2], [10, 6], [10, 9], [10, 11], [11, 3], [11, 7], [11, 8], [11, 10]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect(inDegrees == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.successors(of: $0).sorted() } == [[1, 3, 4, 8], [0, 2, 5, 9], [1, 3, 6, 10], [0, 2, 7, 11], [0, 5, 7, 8], [1, 4, 6, 9], [2, 5, 7, 10], [3, 4, 6, 11], [0, 4, 9, 11], [1, 5, 8, 10], [2, 6, 9, 11], [3, 7, 8, 10]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [3, 4], periodic: true), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [3, 4], periodic: true), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [3, 4], periodic: true), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [3, 4], periodic: true), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [3, 4], periodic: true), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [3, 4], periodic: true), "StableDirectedGraph<Int>")
    }

    @Test("NG-060 2×3 periodic")
    func ng060() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [2, 3], periodic: true) → n 6; m 9; deg [3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–4, 2–5, 3–4, 3–5, 4–5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 4], [2, 5], [3, 4], [3, 5], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3], [0, 2, 4], [0, 1, 5], [0, 4, 5], [1, 3, 5], [2, 3, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 4)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [2, 3], periodic: true), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [2, 3], periodic: true), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [2, 3], periodic: true), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 0], [1, 2], [1, 4], [2, 0], [2, 1], [2, 5], [3, 0], [3, 4], [3, 5], [4, 1], [4, 3], [4, 5], [5, 2], [5, 3], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [0, 2, 4], [0, 1, 5], [0, 4, 5], [1, 3, 5], [2, 3, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 4)), "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [2, 3], periodic: true), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [2, 3], periodic: true), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [2, 3], periodic: true), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [2, 3], periodic: true), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [2, 3], periodic: true), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [2, 3], periodic: true), "StableDirectedGraph<Int>")
    }

    @Test("NG-061 1×3 periodic")
    func ng061() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [1, 3], periodic: true) → n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2]
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
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [1, 3], periodic: true), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [1, 3], periodic: true), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [1, 3], periodic: true), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.grid(dimensions: [1, 3], periodic: true), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [1, 3], periodic: true), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [1, 3], periodic: true), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [1, 3], periodic: true), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [1, 3], periodic: true), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [1, 3], periodic: true), "StableDirectedGraph<Int>")
    }

    @Test("NG-062 3×3×3 periodic")
    func ng062() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [3, 3, 3], periodic: true) → n 27; m 81; deg 6…6
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 27 && graph.edgeCount == 81 && graph.edges.count == 81, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 27), "\(type)")
            #expect((0 ..< 27).map { graph.vertexIndex(of: $0) } == Array(0 ..< 27), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 6], [0, 9], [0, 18], [1, 2], [1, 4], [1, 7], [1, 10], [1, 19], [2, 5], [2, 8], [2, 11], [2, 20], [3, 4], [3, 5], [3, 6], [3, 12], [3, 21], [4, 5], [4, 7], [4, 13], [4, 22], [5, 8], [5, 14], [5, 23], [6, 7], [6, 8], [6, 15], [6, 24], [7, 8], [7, 16], [7, 25], [8, 17], [8, 26], [9, 10], [9, 11], [9, 12], [9, 15], [9, 18], [10, 11], [10, 13], [10, 16], [10, 19], [11, 14], [11, 17], [11, 20], [12, 13], [12, 14], [12, 15], [12, 21], [13, 14], [13, 16], [13, 22], [14, 17], [14, 23], [15, 16], [15, 17], [15, 24], [16, 17], [16, 25], [17, 26], [18, 19], [18, 20], [18, 21], [18, 24], [19, 20], [19, 22], [19, 25], [20, 23], [20, 26], [21, 22], [21, 23], [21, 24], [22, 23], [22, 25], [23, 26], [24, 25], [24, 26], [25, 26]] as [[Int]], "\(type)")
            #expect((0 ..< 27).map { graph.degree(of: $0) } == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect((0 ..< 27).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 6, 9, 18], [0, 2, 4, 7, 10, 19], [0, 1, 5, 8, 11, 20], [0, 4, 5, 6, 12, 21], [1, 3, 5, 7, 13, 22], [2, 3, 4, 8, 14, 23], [0, 3, 7, 8, 15, 24], [1, 4, 6, 8, 16, 25], [2, 5, 6, 7, 17, 26], [0, 10, 11, 12, 15, 18], [1, 9, 11, 13, 16, 19], [2, 9, 10, 14, 17, 20], [3, 9, 13, 14, 15, 21], [4, 10, 12, 14, 16, 22], [5, 11, 12, 13, 17, 23], [6, 9, 12, 16, 17, 24], [7, 10, 13, 15, 17, 25], [8, 11, 14, 15, 16, 26], [0, 9, 19, 20, 21, 24], [1, 10, 18, 20, 22, 25], [2, 11, 18, 19, 23, 26], [3, 12, 18, 22, 23, 24], [4, 13, 19, 21, 23, 25], [5, 14, 20, 21, 22, 26], [6, 15, 18, 21, 25, 26], [7, 16, 19, 22, 24, 26], [8, 17, 20, 23, 24, 25]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 27).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 4)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [3, 3, 3], periodic: true), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [3, 3, 3], periodic: true), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [3, 3, 3], periodic: true), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 27 && graph.edgeCount == 162 && graph.edges.count == 162, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 27), "\(type)")
            #expect((0 ..< 27).map { graph.vertexIndex(of: $0) } == Array(0 ..< 27), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 27)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 6], [0, 9], [0, 18], [1, 0], [1, 2], [1, 4], [1, 7], [1, 10], [1, 19], [2, 0], [2, 1], [2, 5], [2, 8], [2, 11], [2, 20], [3, 0], [3, 4], [3, 5], [3, 6], [3, 12], [3, 21], [4, 1], [4, 3], [4, 5], [4, 7], [4, 13], [4, 22], [5, 2], [5, 3], [5, 4], [5, 8], [5, 14], [5, 23], [6, 0], [6, 3], [6, 7], [6, 8], [6, 15], [6, 24], [7, 1], [7, 4], [7, 6], [7, 8], [7, 16], [7, 25], [8, 2], [8, 5], [8, 6], [8, 7], [8, 17], [8, 26], [9, 0], [9, 10], [9, 11], [9, 12], [9, 15], [9, 18], [10, 1], [10, 9], [10, 11], [10, 13], [10, 16], [10, 19], [11, 2], [11, 9], [11, 10], [11, 14], [11, 17], [11, 20], [12, 3], [12, 9], [12, 13], [12, 14], [12, 15], [12, 21], [13, 4], [13, 10], [13, 12], [13, 14], [13, 16], [13, 22], [14, 5], [14, 11], [14, 12], [14, 13], [14, 17], [14, 23], [15, 6], [15, 9], [15, 12], [15, 16], [15, 17], [15, 24], [16, 7], [16, 10], [16, 13], [16, 15], [16, 17], [16, 25], [17, 8], [17, 11], [17, 14], [17, 15], [17, 16], [17, 26], [18, 0], [18, 9], [18, 19], [18, 20], [18, 21], [18, 24], [19, 1], [19, 10], [19, 18], [19, 20], [19, 22], [19, 25], [20, 2], [20, 11], [20, 18], [20, 19], [20, 23], [20, 26], [21, 3], [21, 12], [21, 18], [21, 22], [21, 23], [21, 24], [22, 4], [22, 13], [22, 19], [22, 21], [22, 23], [22, 25], [23, 5], [23, 14], [23, 20], [23, 21], [23, 22], [23, 26], [24, 6], [24, 15], [24, 18], [24, 21], [24, 25], [24, 26], [25, 7], [25, 16], [25, 19], [25, 22], [25, 24], [25, 26], [26, 8], [26, 17], [26, 20], [26, 23], [26, 24], [26, 25]] as [[Int]], "\(type)")
            #expect((0 ..< 27).map { graph.outDegree(of: $0) } == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect(inDegrees == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect((0 ..< 27).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 6, 9, 18], [0, 2, 4, 7, 10, 19], [0, 1, 5, 8, 11, 20], [0, 4, 5, 6, 12, 21], [1, 3, 5, 7, 13, 22], [2, 3, 4, 8, 14, 23], [0, 3, 7, 8, 15, 24], [1, 4, 6, 8, 16, 25], [2, 5, 6, 7, 17, 26], [0, 10, 11, 12, 15, 18], [1, 9, 11, 13, 16, 19], [2, 9, 10, 14, 17, 20], [3, 9, 13, 14, 15, 21], [4, 10, 12, 14, 16, 22], [5, 11, 12, 13, 17, 23], [6, 9, 12, 16, 17, 24], [7, 10, 13, 15, 17, 25], [8, 11, 14, 15, 16, 26], [0, 9, 19, 20, 21, 24], [1, 10, 18, 20, 22, 25], [2, 11, 18, 19, 23, 26], [3, 12, 18, 22, 23, 24], [4, 13, 19, 21, 23, 25], [5, 14, 20, 21, 22, 26], [6, 15, 18, 21, 25, 26], [7, 16, 19, 22, 24, 26], [8, 17, 20, 23, 24, 25]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 27).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 4)), "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [3, 3, 3], periodic: true), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [3, 3, 3], periodic: true), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [3, 3, 3], periodic: true), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [3, 3, 3], periodic: true), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [3, 3, 3], periodic: true), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [3, 3, 3], periodic: true), "StableDirectedGraph<Int>")
    }

    @Test("NG-063 2×3 directed: both arcs")
    func ng063() {
        // CompressedSparseRow.grid(dimensions: [2, 3]) → n 6; m 14; out [2, 3, 2, 2, 3, 2]; in [2, 3, 2, 2, 3, 2]; E [0→1, 0→3, 1→0, 1→2, 1→4, 2→1, 2→5, 3→0, 3→4, 4→1, 4→3, 4→5, 5→2, 5→4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [1, 4], [2, 5], [3, 4], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 3, 2, 2, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2, 4], [1, 5], [0, 4], [1, 3, 5], [2, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [2, 3]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [2, 3]), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [2, 3]), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [1, 0], [1, 2], [1, 4], [2, 1], [2, 5], [3, 0], [3, 4], [4, 1], [4, 3], [4, 5], [5, 2], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 3, 2, 2, 3, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 3, 2, 2, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 3], [0, 2, 4], [1, 5], [0, 4], [1, 3, 5], [2, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [2, 3]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [2, 3]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [2, 3]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [2, 3]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [2, 3]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [2, 3]), "StableDirectedGraph<Int>")
    }

    @Test("NG-064 3×3 periodic directed")
    func ng064() {
        // CompressedSparseRow.grid(dimensions: [3, 3], periodic: true) → n 9; m 36; out [4, 4, 4, 4, 4, 4, 4, 4, 4]; in [4, 4, 4, 4, 4, 4, 4, 4, 4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 9 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 9), "\(type)")
            #expect((0 ..< 9).map { graph.vertexIndex(of: $0) } == Array(0 ..< 9), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 6], [1, 2], [1, 4], [1, 7], [2, 5], [2, 8], [3, 4], [3, 5], [3, 6], [4, 5], [4, 7], [5, 8], [6, 7], [6, 8], [7, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 9).map { graph.degree(of: $0) } == [4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 9).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 6], [0, 2, 4, 7], [0, 1, 5, 8], [0, 4, 5, 6], [1, 3, 5, 7], [2, 3, 4, 8], [0, 3, 7, 8], [1, 4, 6, 8], [2, 5, 6, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 9).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 4)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [3, 3], periodic: true), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [3, 3], periodic: true), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [3, 3], periodic: true), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 9 && graph.edgeCount == 36 && graph.edges.count == 36, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 9), "\(type)")
            #expect((0 ..< 9).map { graph.vertexIndex(of: $0) } == Array(0 ..< 9), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 9)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 6], [1, 0], [1, 2], [1, 4], [1, 7], [2, 0], [2, 1], [2, 5], [2, 8], [3, 0], [3, 4], [3, 5], [3, 6], [4, 1], [4, 3], [4, 5], [4, 7], [5, 2], [5, 3], [5, 4], [5, 8], [6, 0], [6, 3], [6, 7], [6, 8], [7, 1], [7, 4], [7, 6], [7, 8], [8, 2], [8, 5], [8, 6], [8, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 9).map { graph.outDegree(of: $0) } == [4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect(inDegrees == [4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 9).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 6], [0, 2, 4, 7], [0, 1, 5, 8], [0, 4, 5, 6], [1, 3, 5, 7], [2, 3, 4, 8], [0, 3, 7, 8], [1, 4, 6, 8], [2, 5, 6, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 9).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 4)), "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [3, 3], periodic: true), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [3, 3], periodic: true), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [3, 3], periodic: true), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [3, 3], periodic: true), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [3, 3], periodic: true), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [3, 3], periodic: true), "StableDirectedGraph<Int>")
    }

    @Test("NG-065 100×100 counts")
    func ng065() {
        // UndirectedAdjacencyList<Int>.grid(dimensions: [100, 100]) → n 10000; m 19800; deg 2…4
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10000 && graph.edgeCount == 19800 && graph.edges.count == 19800, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10000), "\(type)")
            #expect((0 ..< 10000).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10000), "\(type)")
            // Sorted, u < v, no repeats, and each edge by the family's rule.
            let ends = graph.edges.map { [$0.u, $0.v] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.u < e.v && e.v < 10000 && { let (a, b) = (min(e.u, e.v), max(e.u, e.v)); return (b - a == 1 && a % 100 != 99) || b - a == 100 }() }, "\(type)")
            #expect((0 ..< 10000).allSatisfy { v in graph.degree(of: v) == [v / 100 > 0, v / 100 < 99, v % 100 > 0, v % 100 < 99].filter { $0 }.count }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.grid(dimensions: [100, 100]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.grid(dimensions: [100, 100]), "Pseudograph<Int>")
        check(Multigraph<Int>.grid(dimensions: [100, 100]), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10000 && graph.edgeCount == 39600 && graph.edges.count == 39600, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10000), "\(type)")
            #expect((0 ..< 10000).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10000), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10000)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            // Row-major, no repeats, no self-loops, and each arc by the family's rule.
            let ends = graph.edges.map { [$0.source, $0.target] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.source != e.target && e.source < 10000 && e.target < 10000 && { let (a, b) = (min(e.source, e.target), max(e.source, e.target)); return (b - a == 1 && a % 100 != 99) || b - a == 100 }() }, "\(type)")
            #expect((0 ..< 10000).allSatisfy { v in graph.outDegree(of: v) == [v / 100 > 0, v / 100 < 99, v % 100 > 0, v % 100 < 99].filter { $0 }.count && inDegrees[v] == graph.outDegree(of: v) }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.grid(dimensions: [100, 100]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.grid(dimensions: [100, 100]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.grid(dimensions: [100, 100]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.grid(dimensions: [100, 100]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.grid(dimensions: [100, 100]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.grid(dimensions: [100, 100]), "StableDirectedGraph<Int>")
    }

    @Test("NG-069 Q0: u – u ^ (1 << k)")
    func ng069() {
        // UndirectedAdjacencyList<Int>.hypercube(dimension: 0) → n 1; m 0; deg [0]; E []
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 1 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1), "\(type)")
            #expect((0 ..< 1).map { graph.vertexIndex(of: $0) } == Array(0 ..< 1), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 1).map { graph.degree(of: $0) } == [0] as [Int], "\(type)")
            #expect((0 ..< 1).map { graph.neighbors(of: $0).sorted() } == [[]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 1).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hypercube(dimension: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hypercube(dimension: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.hypercube(dimension: 0), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 1 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1), "\(type)")
            #expect((0 ..< 1).map { graph.vertexIndex(of: $0) } == Array(0 ..< 1), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 1)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 1).map { graph.outDegree(of: $0) } == [0] as [Int], "\(type)")
            #expect(inDegrees == [0] as [Int], "\(type)")
            #expect((0 ..< 1).map { graph.successors(of: $0).sorted() } == [[]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 1).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(CompressedSparseRow.hypercube(dimension: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hypercube(dimension: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hypercube(dimension: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hypercube(dimension: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hypercube(dimension: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hypercube(dimension: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-070 Q1: u – u ^ (1 << k)")
    func ng070() {
        // UndirectedAdjacencyList<Int>.hypercube(dimension: 1) → n 2; m 1; deg [1, 1]; E [0–1]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 1 && graph.edges.count == 1, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect((0 ..< 2).map { graph.vertexIndex(of: $0) } == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.degree(of: $0) } == [1, 1] as [Int], "\(type)")
            #expect((0 ..< 2).map { graph.neighbors(of: $0).sorted() } == [[1], [0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 2).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hypercube(dimension: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hypercube(dimension: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.hypercube(dimension: 1), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 2 && graph.edges.count == 2, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect((0 ..< 2).map { graph.vertexIndex(of: $0) } == Array(0 ..< 2), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 2)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.outDegree(of: $0) } == [1, 1] as [Int], "\(type)")
            #expect(inDegrees == [1, 1] as [Int], "\(type)")
            #expect((0 ..< 2).map { graph.successors(of: $0).sorted() } == [[1], [0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 2).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(CompressedSparseRow.hypercube(dimension: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hypercube(dimension: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hypercube(dimension: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hypercube(dimension: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hypercube(dimension: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hypercube(dimension: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-071 Q2: u – u ^ (1 << k)")
    func ng071() {
        // UndirectedAdjacencyList<Int>.hypercube(dimension: 2) → n 4; m 4; deg [2, 2, 2, 2]; E [0–1, 0–2, 1–3, 2–3]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 3], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 3], [0, 3], [1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hypercube(dimension: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hypercube(dimension: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.hypercube(dimension: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 3], [2, 0], [2, 3], [3, 1], [3, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2], [0, 3], [0, 3], [1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hypercube(dimension: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hypercube(dimension: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hypercube(dimension: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hypercube(dimension: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hypercube(dimension: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hypercube(dimension: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-072 Q3: u – u ^ (1 << k)")
    func ng072() {
        // UndirectedAdjacencyList<Int>.hypercube(dimension: 3) → n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3], [2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 4], [0, 3, 5], [0, 3, 6], [1, 2, 7], [0, 5, 6], [1, 4, 7], [2, 4, 7], [3, 5, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hypercube(dimension: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hypercube(dimension: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.hypercube(dimension: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 4], [1, 0], [1, 3], [1, 5], [2, 0], [2, 3], [2, 6], [3, 1], [3, 2], [3, 7], [4, 0], [4, 5], [4, 6], [5, 1], [5, 4], [5, 7], [6, 2], [6, 4], [6, 7], [7, 3], [7, 5], [7, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 2, 4], [0, 3, 5], [0, 3, 6], [1, 2, 7], [0, 5, 6], [1, 4, 7], [2, 4, 7], [3, 5, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hypercube(dimension: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hypercube(dimension: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hypercube(dimension: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hypercube(dimension: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hypercube(dimension: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hypercube(dimension: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-073 Q2 directed: both arcs")
    func ng073() {
        // CompressedSparseRow.hypercube(dimension: 2) → n 4; m 8; out [2, 2, 2, 2]; in [2, 2, 2, 2]; E [0→1, 0→2, 1→0, 1→3, 2→0, 2→3, 3→1, 3→2]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 3], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 3], [0, 3], [1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hypercube(dimension: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hypercube(dimension: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.hypercube(dimension: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 3], [2, 0], [2, 3], [3, 1], [3, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2], [0, 3], [0, 3], [1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hypercube(dimension: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hypercube(dimension: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hypercube(dimension: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hypercube(dimension: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hypercube(dimension: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hypercube(dimension: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-074 Q10 counts")
    func ng074() {
        // UndirectedAdjacencyList<Int>.hypercube(dimension: 10) → n 1024; m 5120; deg 10…10
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 1024 && graph.edgeCount == 5120 && graph.edges.count == 5120, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1024), "\(type)")
            #expect((0 ..< 1024).map { graph.vertexIndex(of: $0) } == Array(0 ..< 1024), "\(type)")
            // Sorted, u < v, no repeats, and each edge by the family's rule.
            let ends = graph.edges.map { [$0.u, $0.v] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.u < e.v && e.v < 1024 && (e.u ^ e.v).nonzeroBitCount == 1 }, "\(type)")
            #expect((0 ..< 1024).allSatisfy { graph.degree(of: $0) == 10 }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hypercube(dimension: 10), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hypercube(dimension: 10), "Pseudograph<Int>")
        check(Multigraph<Int>.hypercube(dimension: 10), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 1024 && graph.edgeCount == 10240 && graph.edges.count == 10240, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1024), "\(type)")
            #expect((0 ..< 1024).map { graph.vertexIndex(of: $0) } == Array(0 ..< 1024), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 1024)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            // Row-major, no repeats, no self-loops, and each arc by the family's rule.
            let ends = graph.edges.map { [$0.source, $0.target] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.source != e.target && e.source < 1024 && e.target < 1024 && (e.source ^ e.target).nonzeroBitCount == 1 }, "\(type)")
            #expect((0 ..< 1024).allSatisfy { graph.outDegree(of: $0) == 10 } && inDegrees.allSatisfy { $0 == 10 }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hypercube(dimension: 10), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hypercube(dimension: 10), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hypercube(dimension: 10), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hypercube(dimension: 10), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hypercube(dimension: 10), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hypercube(dimension: 10), "StableDirectedGraph<Int>")
    }

    @Test("NG-077 NetworkX's numbering: outer 0–4, spokes i–i+5, inner pentagram")
    func ng077() {
        // UndirectedAdjacencyList<Int>.petersen() → n 10; m 15; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–4, 0–5, 1–2, 1–6, 2–3, 2–7, 3–4, 3–8, 4–9, 5–7, 5–8, 6–8, 6–9, 7–9]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 15 && graph.edges.count == 15, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8], [6, 8], [6, 9], [7, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.neighbors(of: $0).sorted() } == [[1, 4, 5], [0, 2, 6], [1, 3, 7], [2, 4, 8], [0, 3, 9], [0, 7, 8], [1, 8, 9], [2, 5, 9], [3, 5, 6], [4, 6, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.petersen(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.petersen(), "Pseudograph<Int>")
        check(Multigraph<Int>.petersen(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 30 && graph.edges.count == 30, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 4], [0, 5], [1, 0], [1, 2], [1, 6], [2, 1], [2, 3], [2, 7], [3, 2], [3, 4], [3, 8], [4, 0], [4, 3], [4, 9], [5, 0], [5, 7], [5, 8], [6, 1], [6, 8], [6, 9], [7, 2], [7, 5], [7, 9], [8, 3], [8, 5], [8, 6], [9, 4], [9, 6], [9, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.successors(of: $0).sorted() } == [[1, 4, 5], [0, 2, 6], [1, 3, 7], [2, 4, 8], [0, 3, 9], [0, 7, 8], [1, 8, 9], [2, 5, 9], [3, 5, 6], [4, 6, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.petersen(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.petersen(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.petersen(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.petersen(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.petersen(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.petersen(), "StableDirectedGraph<Int>")
    }

    @Test("NG-078 directed: both arcs")
    func ng078() {
        // CompressedSparseRow.petersen() → n 10; m 30; out [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 15 && graph.edges.count == 15, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8], [6, 8], [6, 9], [7, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.neighbors(of: $0).sorted() } == [[1, 4, 5], [0, 2, 6], [1, 3, 7], [2, 4, 8], [0, 3, 9], [0, 7, 8], [1, 8, 9], [2, 5, 9], [3, 5, 6], [4, 6, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.petersen(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.petersen(), "Pseudograph<Int>")
        check(Multigraph<Int>.petersen(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 30 && graph.edges.count == 30, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 4], [0, 5], [1, 0], [1, 2], [1, 6], [2, 1], [2, 3], [2, 7], [3, 2], [3, 4], [3, 8], [4, 0], [4, 3], [4, 9], [5, 0], [5, 7], [5, 8], [6, 1], [6, 8], [6, 9], [7, 2], [7, 5], [7, 9], [8, 3], [8, 5], [8, 6], [9, 4], [9, 6], [9, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.successors(of: $0).sorted() } == [[1, 4, 5], [0, 2, 6], [1, 3, 7], [2, 4, 8], [0, 3, 9], [0, 7, 8], [1, 8, 9], [2, 5, 9], [3, 5, 6], [4, 6, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.petersen(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.petersen(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.petersen(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.petersen(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.petersen(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.petersen(), "StableDirectedGraph<Int>")
    }

    @Test("NG-079 empty graph on 0")
    func ng079() {
        // UndirectedAdjacencyList<Int>.empty(vertexCount: 0) → n 0; m 0; deg []; E []
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
        check(UndirectedAdjacencyList<Int>.empty(vertexCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.empty(vertexCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.empty(vertexCount: 0), "Multigraph<Int>")
        // The directed form: no arcs.
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
        checkDirected(CompressedSparseRow.empty(vertexCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.empty(vertexCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.empty(vertexCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.empty(vertexCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.empty(vertexCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.empty(vertexCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-080 empty graph on 1")
    func ng080() {
        // UndirectedAdjacencyList<Int>.empty(vertexCount: 1) → n 1; m 0; deg [0]; E []
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 1 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1), "\(type)")
            #expect((0 ..< 1).map { graph.vertexIndex(of: $0) } == Array(0 ..< 1), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 1).map { graph.degree(of: $0) } == [0] as [Int], "\(type)")
            #expect((0 ..< 1).map { graph.neighbors(of: $0).sorted() } == [[]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 1).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.empty(vertexCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.empty(vertexCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.empty(vertexCount: 1), "Multigraph<Int>")
        // The directed form: no arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 1 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1), "\(type)")
            #expect((0 ..< 1).map { graph.vertexIndex(of: $0) } == Array(0 ..< 1), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 1)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 1).map { graph.outDegree(of: $0) } == [0] as [Int], "\(type)")
            #expect(inDegrees == [0] as [Int], "\(type)")
            #expect((0 ..< 1).map { graph.successors(of: $0).sorted() } == [[]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 1).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(CompressedSparseRow.empty(vertexCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.empty(vertexCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.empty(vertexCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.empty(vertexCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.empty(vertexCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.empty(vertexCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-081 empty graph on 4")
    func ng081() {
        // UndirectedAdjacencyList<Int>.empty(vertexCount: 4) → n 4; m 0; deg [0, 0, 0, 0]; E []
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [0, 0, 0, 0] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.empty(vertexCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.empty(vertexCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.empty(vertexCount: 4), "Multigraph<Int>")
        // The directed form: no arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [0, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 0, 0, 0] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.empty(vertexCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.empty(vertexCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.empty(vertexCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.empty(vertexCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.empty(vertexCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.empty(vertexCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-082 directed")
    func ng082() {
        // CompressedSparseRow.empty(vertexCount: 3) → n 3; m 0; out [0, 0, 0]; in [0, 0, 0]; E []
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect((0 ..< 3).map { graph.vertexIndex(of: $0) } == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.degree(of: $0) } == [0, 0, 0] as [Int], "\(type)")
            #expect((0 ..< 3).map { graph.neighbors(of: $0).sorted() } == [[], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 3).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.empty(vertexCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.empty(vertexCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.empty(vertexCount: 3), "Multigraph<Int>")
        // The directed form: no arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect((0 ..< 3).map { graph.vertexIndex(of: $0) } == Array(0 ..< 3), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 0, 0] as [Int], "\(type)")
            #expect((0 ..< 3).map { graph.successors(of: $0).sorted() } == [[], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 3).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.empty(vertexCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.empty(vertexCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.empty(vertexCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.empty(vertexCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.empty(vertexCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.empty(vertexCount: 3), "StableDirectedGraph<Int>")
    }
}
