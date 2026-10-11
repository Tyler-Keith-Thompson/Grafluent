// Complete and complete bipartite graphs (catalog NG-001 – NG-019): K_n on 0..<n with every pair, both
// arcs when directed; K_{a,b} with left 0..<a and right a..<a+b, both arcs when directed; and
// BipartiteGraph.completeBipartite with its sides.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing

@Suite("NamedGraphs complete and complete bipartite graphs")
struct CompleteGraphTests {
    @Test("NG-001 K0")
    func ng001() {
        // UndirectedAdjacencyList<Int>.complete(vertexCount: 0) → n 0; m 0; deg []; E []
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
        check(UndirectedAdjacencyList<Int>.complete(vertexCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.complete(vertexCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.complete(vertexCount: 0), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.complete(vertexCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.complete(vertexCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.complete(vertexCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.complete(vertexCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.complete(vertexCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.complete(vertexCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-002 K1")
    func ng002() {
        // UndirectedAdjacencyList<Int>.complete(vertexCount: 1) → n 1; m 0; deg [0]; E []
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
        check(UndirectedAdjacencyList<Int>.complete(vertexCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.complete(vertexCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.complete(vertexCount: 1), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.complete(vertexCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.complete(vertexCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.complete(vertexCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.complete(vertexCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.complete(vertexCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.complete(vertexCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-003 K2")
    func ng003() {
        // UndirectedAdjacencyList<Int>.complete(vertexCount: 2) → n 2; m 1; deg [1, 1]; E [0–1]
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
        check(UndirectedAdjacencyList<Int>.complete(vertexCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.complete(vertexCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.complete(vertexCount: 2), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.complete(vertexCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.complete(vertexCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.complete(vertexCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.complete(vertexCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.complete(vertexCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.complete(vertexCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-004 K3")
    func ng004() {
        // UndirectedAdjacencyList<Int>.complete(vertexCount: 3) → n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2]
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
        check(UndirectedAdjacencyList<Int>.complete(vertexCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.complete(vertexCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.complete(vertexCount: 3), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.complete(vertexCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.complete(vertexCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.complete(vertexCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.complete(vertexCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.complete(vertexCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.complete(vertexCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-005 K5")
    func ng005() {
        // UndirectedAdjacencyList<Int>.complete(vertexCount: 5) → n 5; m 10; deg [4, 4, 4, 4, 4]; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–4, 2–3, 2–4, 3–4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4], [0, 2, 3, 4], [0, 1, 3, 4], [0, 1, 2, 4], [0, 1, 2, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.complete(vertexCount: 5), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.complete(vertexCount: 5), "Pseudograph<Int>")
        check(Multigraph<Int>.complete(vertexCount: 5), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 20 && graph.edges.count == 20, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 0], [1, 2], [1, 3], [1, 4], [2, 0], [2, 1], [2, 3], [2, 4], [3, 0], [3, 1], [3, 2], [3, 4], [4, 0], [4, 1], [4, 2], [4, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect(inDegrees == [4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4], [0, 2, 3, 4], [0, 1, 3, 4], [0, 1, 2, 4], [0, 1, 2, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(CompressedSparseRow.complete(vertexCount: 5), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.complete(vertexCount: 5), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.complete(vertexCount: 5), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.complete(vertexCount: 5), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.complete(vertexCount: 5), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.complete(vertexCount: 5), "StableDirectedGraph<Int>")
    }

    @Test("NG-006 K0 directed: both arcs, row-major")
    func ng006() {
        // CompressedSparseRow.complete(vertexCount: 0) → n 0; m 0; out []; in []; E []
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
        check(UndirectedAdjacencyList<Int>.complete(vertexCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.complete(vertexCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.complete(vertexCount: 0), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.complete(vertexCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.complete(vertexCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.complete(vertexCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.complete(vertexCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.complete(vertexCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.complete(vertexCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-007 K1 directed: both arcs, row-major")
    func ng007() {
        // CompressedSparseRow.complete(vertexCount: 1) → n 1; m 0; out [0]; in [0]; E []
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
        check(UndirectedAdjacencyList<Int>.complete(vertexCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.complete(vertexCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.complete(vertexCount: 1), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.complete(vertexCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.complete(vertexCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.complete(vertexCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.complete(vertexCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.complete(vertexCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.complete(vertexCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-008 K3 directed: both arcs, row-major")
    func ng008() {
        // CompressedSparseRow.complete(vertexCount: 3) → n 3; m 6; out [2, 2, 2]; in [2, 2, 2]; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1]
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
        check(UndirectedAdjacencyList<Int>.complete(vertexCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.complete(vertexCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.complete(vertexCount: 3), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.complete(vertexCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.complete(vertexCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.complete(vertexCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.complete(vertexCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.complete(vertexCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.complete(vertexCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-009 K60 counts only")
    func ng009() {
        // UndirectedAdjacencyList<Int>.complete(vertexCount: 60) → n 60; m 1770; deg 59…59
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 60 && graph.edgeCount == 1770 && graph.edges.count == 1770, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 60), "\(type)")
            #expect((0 ..< 60).map { graph.vertexIndex(of: $0) } == Array(0 ..< 60), "\(type)")
            // Sorted, u < v, no repeats, and each edge by the family's rule.
            let ends = graph.edges.map { [$0.u, $0.v] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.u < e.v && e.v < 60 }, "\(type)")
            #expect((0 ..< 60).allSatisfy { graph.degree(of: $0) == 59 }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 60).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.complete(vertexCount: 60), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.complete(vertexCount: 60), "Pseudograph<Int>")
        check(Multigraph<Int>.complete(vertexCount: 60), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 60 && graph.edgeCount == 3540 && graph.edges.count == 3540, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 60), "\(type)")
            #expect((0 ..< 60).map { graph.vertexIndex(of: $0) } == Array(0 ..< 60), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 60)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            // Row-major, no repeats, no self-loops, and each arc by the family's rule.
            let ends = graph.edges.map { [$0.source, $0.target] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.source != e.target && e.source < 60 && e.target < 60 }, "\(type)")
            #expect((0 ..< 60).allSatisfy { graph.outDegree(of: $0) == 59 } && inDegrees.allSatisfy { $0 == 59 }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 60).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(CompressedSparseRow.complete(vertexCount: 60), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.complete(vertexCount: 60), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.complete(vertexCount: 60), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.complete(vertexCount: 60), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.complete(vertexCount: 60), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.complete(vertexCount: 60), "StableDirectedGraph<Int>")
    }

    @Test("NG-012 K0,0: left 0..<0, right 0..<0")
    func ng012() {
        // UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 0, rightCount: 0) → n 0; m 0; deg []; E []
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
        check(UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 0, rightCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeBipartite(leftCount: 0, rightCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.completeBipartite(leftCount: 0, rightCount: 0), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.completeBipartite(leftCount: 0, rightCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeBipartite(leftCount: 0, rightCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeBipartite(leftCount: 0, rightCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeBipartite(leftCount: 0, rightCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeBipartite(leftCount: 0, rightCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeBipartite(leftCount: 0, rightCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-013 K0,3: left 0..<0, right 0..<3")
    func ng013() {
        // UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 0, rightCount: 3) → n 3; m 0; deg [0, 0, 0]; E []
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
        check(UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 0, rightCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeBipartite(leftCount: 0, rightCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.completeBipartite(leftCount: 0, rightCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
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
        checkDirected(CompressedSparseRow.completeBipartite(leftCount: 0, rightCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeBipartite(leftCount: 0, rightCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeBipartite(leftCount: 0, rightCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeBipartite(leftCount: 0, rightCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeBipartite(leftCount: 0, rightCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeBipartite(leftCount: 0, rightCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-014 K1,1: left 0..<1, right 1..<2")
    func ng014() {
        // UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 1, rightCount: 1) → n 2; m 1; deg [1, 1]; E [0–1]
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
        check(UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 1, rightCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeBipartite(leftCount: 1, rightCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.completeBipartite(leftCount: 1, rightCount: 1), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.completeBipartite(leftCount: 1, rightCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeBipartite(leftCount: 1, rightCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeBipartite(leftCount: 1, rightCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeBipartite(leftCount: 1, rightCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeBipartite(leftCount: 1, rightCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeBipartite(leftCount: 1, rightCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-015 K2,3: left 0..<2, right 2..<5")
    func ng015() {
        // UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: 3) → n 5; m 6; deg [3, 3, 2, 2, 2]; E [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [3, 3, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[2, 3, 4], [2, 3, 4], [0, 1], [0, 1], [0, 1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeBipartite(leftCount: 2, rightCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.completeBipartite(leftCount: 2, rightCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 0], [2, 1], [3, 0], [3, 1], [4, 0], [4, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [3, 3, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[2, 3, 4], [2, 3, 4], [0, 1], [0, 1], [0, 1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.completeBipartite(leftCount: 2, rightCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeBipartite(leftCount: 2, rightCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeBipartite(leftCount: 2, rightCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeBipartite(leftCount: 2, rightCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeBipartite(leftCount: 2, rightCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-016 K3,2: left 0..<3, right 3..<5")
    func ng016() {
        // UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 3, rightCount: 2) → n 5; m 6; deg [2, 2, 2, 3, 3]; E [0–3, 0–4, 1–3, 1–4, 2–3, 2–4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 3], [0, 4], [1, 3], [1, 4], [2, 3], [2, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [2, 2, 2, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[3, 4], [3, 4], [3, 4], [0, 1, 2], [0, 1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 3, rightCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeBipartite(leftCount: 3, rightCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.completeBipartite(leftCount: 3, rightCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 3], [0, 4], [1, 3], [1, 4], [2, 3], [2, 4], [3, 0], [3, 1], [3, 2], [4, 0], [4, 1], [4, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [2, 2, 2, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[3, 4], [3, 4], [3, 4], [0, 1, 2], [0, 1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.completeBipartite(leftCount: 3, rightCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeBipartite(leftCount: 3, rightCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeBipartite(leftCount: 3, rightCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeBipartite(leftCount: 3, rightCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeBipartite(leftCount: 3, rightCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeBipartite(leftCount: 3, rightCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-017 K2,3 directed: both arcs")
    func ng017() {
        // CompressedSparseRow.completeBipartite(leftCount: 2, rightCount: 3) → n 5; m 12; out [3, 3, 2, 2, 2]; in [3, 3, 2, 2, 2]; E [0→2, 0→3, 0→4, 1→2, 1→3, 1→4, 2→0, 2→1, 3→0, 3→1, 4→0, 4→1]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [3, 3, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[2, 3, 4], [2, 3, 4], [0, 1], [0, 1], [0, 1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeBipartite(leftCount: 2, rightCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.completeBipartite(leftCount: 2, rightCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 0], [2, 1], [3, 0], [3, 1], [4, 0], [4, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [3, 3, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[2, 3, 4], [2, 3, 4], [0, 1], [0, 1], [0, 1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.completeBipartite(leftCount: 2, rightCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeBipartite(leftCount: 2, rightCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeBipartite(leftCount: 2, rightCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeBipartite(leftCount: 2, rightCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeBipartite(leftCount: 2, rightCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-018 BipartiteGraph sides")
    func ng018() {
        // BipartiteGraph<Int>.completeBipartite(leftCount: 2, rightCount: 2) → n 4; m 4; deg [2, 2, 2, 2]; E [0–2, 0–3, 1–2, 1–3]; left [0, 1]; right [2, 3]
        let graph = BipartiteGraph<Int>.completeBipartite(leftCount: 2, rightCount: 2)
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 3], [1, 2], [1, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[2, 3], [2, 3], [0, 1], [0, 1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(graph, "BipartiteGraph<Int>")
        #expect(Array(graph.left) == [0, 1] as [Int] && Array(graph.right) == [2, 3] as [Int])
        #expect((0 ..< 4).map { graph.side(of: $0) } == [.left, .left, .right, .right] as [BipartiteSide])
    }

    @Test("NG-019 BipartiteGraph with an empty side")
    func ng019() {
        // BipartiteGraph<Int>.completeBipartite(leftCount: 0, rightCount: 2) → n 2; m 0; deg [0, 0]; E []; left []; right [0, 1]
        let graph = BipartiteGraph<Int>.completeBipartite(leftCount: 0, rightCount: 2)
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect((0 ..< 2).map { graph.vertexIndex(of: $0) } == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.degree(of: $0) } == [0, 0] as [Int], "\(type)")
            #expect((0 ..< 2).map { graph.neighbors(of: $0).sorted() } == [[], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 2).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(graph, "BipartiteGraph<Int>")
        #expect(Array(graph.left) == [] as [Int] && Array(graph.right) == [0, 1] as [Int])
        #expect((0 ..< 2).map { graph.side(of: $0) } == [.right, .right] as [BipartiteSide])
    }
}
