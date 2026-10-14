// LCF notation and named graphs (catalog NG-215 – NG-235): the n-cycle and its chords; Heawood,
// Möbius–Kantor, Pappus, Desargues, dodecahedral and Frucht in LCF; icosahedral, Tutte, Chvátal and
// Hoffman–Singleton from their constructions. Both arcs when directed.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing

@Suite("NamedGraphs LCF notation and the named cubic and other graphs")
struct LCFNamedGraphTests {
    @Test("NG-215 [3, -3]^3 on 6: K3,3")
    func ng215() {
        // UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3) → n 6; m 9; deg [3, 3, 3, 3, 3, 3]; E [0–1, 0–3, 0–5, 1–2, 1–4, 2–3, 2–5, 3–4, 4–5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [0, 5], [1, 2], [1, 4], [2, 3], [2, 5], [3, 4], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 3, 5], [0, 2, 4], [1, 3, 5], [0, 2, 4], [1, 3, 5], [0, 2, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [0, 5], [1, 0], [1, 2], [1, 4], [2, 1], [2, 3], [2, 5], [3, 0], [3, 2], [3, 4], [4, 1], [4, 3], [4, 5], [5, 0], [5, 2], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 3, 5], [0, 2, 4], [1, 3, 5], [0, 2, 4], [1, 3, 5], [0, 2, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-216 [4]^8 on 8: the Wagner graph, chords repeated from both ends")
    func ng216() {
        // UndirectedAdjacencyList<Int>.lcf(vertexCount: 8, shifts: [4], repeatCount: 8) → n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–4, 0–7, 1–2, 1–5, 2–3, 2–6, 3–4, 3–7, 4–5, 5–6, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [0, 7], [1, 2], [1, 5], [2, 3], [2, 6], [3, 4], [3, 7], [4, 5], [5, 6], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 4, 7], [0, 2, 5], [1, 3, 6], [2, 4, 7], [0, 3, 5], [1, 4, 6], [2, 5, 7], [0, 3, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.lcf(vertexCount: 8, shifts: [4], repeatCount: 8), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.lcf(vertexCount: 8, shifts: [4], repeatCount: 8), "Pseudograph<Int>")
        check(Multigraph<Int>.lcf(vertexCount: 8, shifts: [4], repeatCount: 8), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 4], [0, 7], [1, 0], [1, 2], [1, 5], [2, 1], [2, 3], [2, 6], [3, 2], [3, 4], [3, 7], [4, 0], [4, 3], [4, 5], [5, 1], [5, 4], [5, 6], [6, 2], [6, 5], [6, 7], [7, 0], [7, 3], [7, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 4, 7], [0, 2, 5], [1, 3, 6], [2, 4, 7], [0, 3, 5], [1, 4, 6], [2, 5, 7], [0, 3, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.lcf(vertexCount: 8, shifts: [4], repeatCount: 8), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.lcf(vertexCount: 8, shifts: [4], repeatCount: 8), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.lcf(vertexCount: 8, shifts: [4], repeatCount: 8), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.lcf(vertexCount: 8, shifts: [4], repeatCount: 8), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.lcf(vertexCount: 8, shifts: [4], repeatCount: 8), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.lcf(vertexCount: 8, shifts: [4], repeatCount: 8), "StableDirectedGraph<Int>")
    }

    @Test("NG-217 [2]^4 on 4: K4")
    func ng217() {
        // UndirectedAdjacencyList<Int>.lcf(vertexCount: 4, shifts: [2], repeatCount: 4) → n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.lcf(vertexCount: 4, shifts: [2], repeatCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.lcf(vertexCount: 4, shifts: [2], repeatCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.lcf(vertexCount: 4, shifts: [2], repeatCount: 4), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 0], [1, 2], [1, 3], [2, 0], [2, 1], [2, 3], [3, 0], [3, 1], [3, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(CompressedSparseRow.lcf(vertexCount: 4, shifts: [2], repeatCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.lcf(vertexCount: 4, shifts: [2], repeatCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.lcf(vertexCount: 4, shifts: [2], repeatCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.lcf(vertexCount: 4, shifts: [2], repeatCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.lcf(vertexCount: 4, shifts: [2], repeatCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.lcf(vertexCount: 4, shifts: [2], repeatCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-218 []^0 on 5: no chords, C5")
    func ng218() {
        // UndirectedAdjacencyList<Int>.lcf(vertexCount: 5, shifts: [], repeatCount: 0) → n 5; m 5; deg [2, 2, 2, 2, 2]; E [0–1, 0–4, 1–2, 2–3, 3–4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [1, 2], [2, 3], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 4], [0, 2], [1, 3], [2, 4], [0, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.lcf(vertexCount: 5, shifts: [], repeatCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.lcf(vertexCount: 5, shifts: [], repeatCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.lcf(vertexCount: 5, shifts: [], repeatCount: 0), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 4], [1, 0], [1, 2], [2, 1], [2, 3], [3, 2], [3, 4], [4, 0], [4, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 4], [0, 2], [1, 3], [2, 4], [0, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.lcf(vertexCount: 5, shifts: [], repeatCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.lcf(vertexCount: 5, shifts: [], repeatCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.lcf(vertexCount: 5, shifts: [], repeatCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.lcf(vertexCount: 5, shifts: [], repeatCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.lcf(vertexCount: 5, shifts: [], repeatCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.lcf(vertexCount: 5, shifts: [], repeatCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-219 [2]^1 on 6: one chord")
    func ng219() {
        // UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [2], repeatCount: 1) → n 6; m 7; deg [3, 2, 3, 2, 2, 2]; E [0–1, 0–2, 0–5, 1–2, 2–3, 3–4, 4–5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 5], [1, 2], [2, 3], [3, 4], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [3, 2, 3, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 5], [0, 2], [0, 1, 3], [2, 4], [3, 5], [0, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [2], repeatCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.lcf(vertexCount: 6, shifts: [2], repeatCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.lcf(vertexCount: 6, shifts: [2], repeatCount: 1), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 5], [1, 0], [1, 2], [2, 0], [2, 1], [2, 3], [3, 2], [3, 4], [4, 3], [4, 5], [5, 0], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [3, 2, 3, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [3, 2, 3, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 2, 5], [0, 2], [0, 1, 3], [2, 4], [3, 5], [0, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.lcf(vertexCount: 6, shifts: [2], repeatCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.lcf(vertexCount: 6, shifts: [2], repeatCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.lcf(vertexCount: 6, shifts: [2], repeatCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.lcf(vertexCount: 6, shifts: [2], repeatCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.lcf(vertexCount: 6, shifts: [2], repeatCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.lcf(vertexCount: 6, shifts: [2], repeatCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-220 directed: both arcs")
    func ng220() {
        // CompressedSparseRow.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3) → n 6; m 18; out [3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3]; E [0→1, 0→3, 0→5, 1→0, 1→2, 1→4, 2→1, 2→3, 2→5, 3→0, 3→2, 3→4, 4→1, 4→3, 4→5, 5→0, 5→2, 5→4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [0, 5], [1, 2], [1, 4], [2, 3], [2, 5], [3, 4], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 3, 5], [0, 2, 4], [1, 3, 5], [0, 2, 4], [1, 3, 5], [0, 2, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [0, 5], [1, 0], [1, 2], [1, 4], [2, 1], [2, 3], [2, 5], [3, 0], [3, 2], [3, 4], [4, 1], [4, 3], [4, 5], [5, 0], [5, 2], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 3, 5], [0, 2, 4], [1, 3, 5], [0, 2, 4], [1, 3, 5], [0, 2, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-224 heawood: [5, -5]^7 on 14")
    func ng224() {
        // UndirectedAdjacencyList<Int>.heawood() → n 14; m 21; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–5, 0–13, 1–2, 1–10, 2–3, 2–7, 3–4, 3–12, 4–5, 4–9, 5–6, 6–7, 6–11, 7–8, 8–9, 8–13, 9–10, 10–11, 11–12, 12–13]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 14 && graph.edgeCount == 21 && graph.edges.count == 21, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 14), "\(type)")
            #expect((0 ..< 14).map { graph.vertexIndex(of: $0) } == Array(0 ..< 14), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 5], [0, 13], [1, 2], [1, 10], [2, 3], [2, 7], [3, 4], [3, 12], [4, 5], [4, 9], [5, 6], [6, 7], [6, 11], [7, 8], [8, 9], [8, 13], [9, 10], [10, 11], [11, 12], [12, 13]] as [[Int]], "\(type)")
            #expect((0 ..< 14).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 14).map { graph.neighbors(of: $0).sorted() } == [[1, 5, 13], [0, 2, 10], [1, 3, 7], [2, 4, 12], [3, 5, 9], [0, 4, 6], [5, 7, 11], [2, 6, 8], [7, 9, 13], [4, 8, 10], [1, 9, 11], [6, 10, 12], [3, 11, 13], [0, 8, 12]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 14).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.heawood(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.heawood(), "Pseudograph<Int>")
        check(Multigraph<Int>.heawood(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 14 && graph.edgeCount == 42 && graph.edges.count == 42, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 14), "\(type)")
            #expect((0 ..< 14).map { graph.vertexIndex(of: $0) } == Array(0 ..< 14), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 14)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [0, 13], [1, 0], [1, 2], [1, 10], [2, 1], [2, 3], [2, 7], [3, 2], [3, 4], [3, 12], [4, 3], [4, 5], [4, 9], [5, 0], [5, 4], [5, 6], [6, 5], [6, 7], [6, 11], [7, 2], [7, 6], [7, 8], [8, 7], [8, 9], [8, 13], [9, 4], [9, 8], [9, 10], [10, 1], [10, 9], [10, 11], [11, 6], [11, 10], [11, 12], [12, 3], [12, 11], [12, 13], [13, 0], [13, 8], [13, 12]] as [[Int]], "\(type)")
            #expect((0 ..< 14).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 14).map { graph.successors(of: $0).sorted() } == [[1, 5, 13], [0, 2, 10], [1, 3, 7], [2, 4, 12], [3, 5, 9], [0, 4, 6], [5, 7, 11], [2, 6, 8], [7, 9, 13], [4, 8, 10], [1, 9, 11], [6, 10, 12], [3, 11, 13], [0, 8, 12]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 14).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.heawood(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.heawood(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.heawood(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.heawood(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.heawood(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.heawood(), "StableDirectedGraph<Int>")
    }

    @Test("NG-225 moebiusKantor: [5, -5]^8 on 16")
    func ng225() {
        // UndirectedAdjacencyList<Int>.moebiusKantor() → n 16; m 24; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–5, 0–15, 1–2, 1–12, 2–3, 2–7, 3–4, 3–14, 4–5, 4–9, 5–6, 6–7, 6–11, 7–8, 8–9, 8–13, 9–10, 10–11, 10–15, 11–12, 12–13, 13–14, 14–15]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 16 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 16), "\(type)")
            #expect((0 ..< 16).map { graph.vertexIndex(of: $0) } == Array(0 ..< 16), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 5], [0, 15], [1, 2], [1, 12], [2, 3], [2, 7], [3, 4], [3, 14], [4, 5], [4, 9], [5, 6], [6, 7], [6, 11], [7, 8], [8, 9], [8, 13], [9, 10], [10, 11], [10, 15], [11, 12], [12, 13], [13, 14], [14, 15]] as [[Int]], "\(type)")
            #expect((0 ..< 16).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 16).map { graph.neighbors(of: $0).sorted() } == [[1, 5, 15], [0, 2, 12], [1, 3, 7], [2, 4, 14], [3, 5, 9], [0, 4, 6], [5, 7, 11], [2, 6, 8], [7, 9, 13], [4, 8, 10], [9, 11, 15], [6, 10, 12], [1, 11, 13], [8, 12, 14], [3, 13, 15], [0, 10, 14]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 16).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.moebiusKantor(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.moebiusKantor(), "Pseudograph<Int>")
        check(Multigraph<Int>.moebiusKantor(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 16 && graph.edgeCount == 48 && graph.edges.count == 48, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 16), "\(type)")
            #expect((0 ..< 16).map { graph.vertexIndex(of: $0) } == Array(0 ..< 16), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 16)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [0, 15], [1, 0], [1, 2], [1, 12], [2, 1], [2, 3], [2, 7], [3, 2], [3, 4], [3, 14], [4, 3], [4, 5], [4, 9], [5, 0], [5, 4], [5, 6], [6, 5], [6, 7], [6, 11], [7, 2], [7, 6], [7, 8], [8, 7], [8, 9], [8, 13], [9, 4], [9, 8], [9, 10], [10, 9], [10, 11], [10, 15], [11, 6], [11, 10], [11, 12], [12, 1], [12, 11], [12, 13], [13, 8], [13, 12], [13, 14], [14, 3], [14, 13], [14, 15], [15, 0], [15, 10], [15, 14]] as [[Int]], "\(type)")
            #expect((0 ..< 16).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 16).map { graph.successors(of: $0).sorted() } == [[1, 5, 15], [0, 2, 12], [1, 3, 7], [2, 4, 14], [3, 5, 9], [0, 4, 6], [5, 7, 11], [2, 6, 8], [7, 9, 13], [4, 8, 10], [9, 11, 15], [6, 10, 12], [1, 11, 13], [8, 12, 14], [3, 13, 15], [0, 10, 14]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 16).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.moebiusKantor(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.moebiusKantor(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.moebiusKantor(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.moebiusKantor(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.moebiusKantor(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.moebiusKantor(), "StableDirectedGraph<Int>")
    }

    @Test("NG-226 pappus: [5, 7, -7, 7, -7, -5]^3 on 18")
    func ng226() {
        // UndirectedAdjacencyList<Int>.pappus() → n 18; m 27; deg 3…3; E [0–1, 0–5, 0–17, 1–2, 1–8, 2–3, 2–13, 3–4, 3–10, 4–5, 4–15, 5–6, 6–7, 6–11, 7–8, 7–14, 8–9, 9–10, 9–16, 10–11, 11–12, 12–13, 12–17, 13–14, 14–15, 15–16, 16–17]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 18 && graph.edgeCount == 27 && graph.edges.count == 27, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 18), "\(type)")
            #expect((0 ..< 18).map { graph.vertexIndex(of: $0) } == Array(0 ..< 18), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 5], [0, 17], [1, 2], [1, 8], [2, 3], [2, 13], [3, 4], [3, 10], [4, 5], [4, 15], [5, 6], [6, 7], [6, 11], [7, 8], [7, 14], [8, 9], [9, 10], [9, 16], [10, 11], [11, 12], [12, 13], [12, 17], [13, 14], [14, 15], [15, 16], [16, 17]] as [[Int]], "\(type)")
            #expect((0 ..< 18).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 18).map { graph.neighbors(of: $0).sorted() } == [[1, 5, 17], [0, 2, 8], [1, 3, 13], [2, 4, 10], [3, 5, 15], [0, 4, 6], [5, 7, 11], [6, 8, 14], [1, 7, 9], [8, 10, 16], [3, 9, 11], [6, 10, 12], [11, 13, 17], [2, 12, 14], [7, 13, 15], [4, 14, 16], [9, 15, 17], [0, 12, 16]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 18).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.pappus(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.pappus(), "Pseudograph<Int>")
        check(Multigraph<Int>.pappus(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 18 && graph.edgeCount == 54 && graph.edges.count == 54, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 18), "\(type)")
            #expect((0 ..< 18).map { graph.vertexIndex(of: $0) } == Array(0 ..< 18), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 18)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [0, 17], [1, 0], [1, 2], [1, 8], [2, 1], [2, 3], [2, 13], [3, 2], [3, 4], [3, 10], [4, 3], [4, 5], [4, 15], [5, 0], [5, 4], [5, 6], [6, 5], [6, 7], [6, 11], [7, 6], [7, 8], [7, 14], [8, 1], [8, 7], [8, 9], [9, 8], [9, 10], [9, 16], [10, 3], [10, 9], [10, 11], [11, 6], [11, 10], [11, 12], [12, 11], [12, 13], [12, 17], [13, 2], [13, 12], [13, 14], [14, 7], [14, 13], [14, 15], [15, 4], [15, 14], [15, 16], [16, 9], [16, 15], [16, 17], [17, 0], [17, 12], [17, 16]] as [[Int]], "\(type)")
            #expect((0 ..< 18).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 18).map { graph.successors(of: $0).sorted() } == [[1, 5, 17], [0, 2, 8], [1, 3, 13], [2, 4, 10], [3, 5, 15], [0, 4, 6], [5, 7, 11], [6, 8, 14], [1, 7, 9], [8, 10, 16], [3, 9, 11], [6, 10, 12], [11, 13, 17], [2, 12, 14], [7, 13, 15], [4, 14, 16], [9, 15, 17], [0, 12, 16]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 18).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.pappus(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.pappus(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.pappus(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.pappus(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.pappus(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.pappus(), "StableDirectedGraph<Int>")
    }

    @Test("NG-227 desargues: [5, -5, 9, -9]^5 on 20")
    func ng227() {
        // UndirectedAdjacencyList<Int>.desargues() → n 20; m 30; deg 3…3; E [0–1, 0–5, 0–19, 1–2, 1–16, 2–3, 2–11, 3–4, 3–14, 4–5, 4–9, 5–6, 6–7, 6–15, 7–8, 7–18, 8–9, 8–13, 9–10, 10–11, 10–19, 11–12, 12–13, 12–17, 13–14, 14–15, 15–16, 16–17, 17–18, 18–19]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 20 && graph.edgeCount == 30 && graph.edges.count == 30, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 20), "\(type)")
            #expect((0 ..< 20).map { graph.vertexIndex(of: $0) } == Array(0 ..< 20), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 5], [0, 19], [1, 2], [1, 16], [2, 3], [2, 11], [3, 4], [3, 14], [4, 5], [4, 9], [5, 6], [6, 7], [6, 15], [7, 8], [7, 18], [8, 9], [8, 13], [9, 10], [10, 11], [10, 19], [11, 12], [12, 13], [12, 17], [13, 14], [14, 15], [15, 16], [16, 17], [17, 18], [18, 19]] as [[Int]], "\(type)")
            #expect((0 ..< 20).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 20).map { graph.neighbors(of: $0).sorted() } == [[1, 5, 19], [0, 2, 16], [1, 3, 11], [2, 4, 14], [3, 5, 9], [0, 4, 6], [5, 7, 15], [6, 8, 18], [7, 9, 13], [4, 8, 10], [9, 11, 19], [2, 10, 12], [11, 13, 17], [8, 12, 14], [3, 13, 15], [6, 14, 16], [1, 15, 17], [12, 16, 18], [7, 17, 19], [0, 10, 18]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 20).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.desargues(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.desargues(), "Pseudograph<Int>")
        check(Multigraph<Int>.desargues(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 20 && graph.edgeCount == 60 && graph.edges.count == 60, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 20), "\(type)")
            #expect((0 ..< 20).map { graph.vertexIndex(of: $0) } == Array(0 ..< 20), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 20)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [0, 19], [1, 0], [1, 2], [1, 16], [2, 1], [2, 3], [2, 11], [3, 2], [3, 4], [3, 14], [4, 3], [4, 5], [4, 9], [5, 0], [5, 4], [5, 6], [6, 5], [6, 7], [6, 15], [7, 6], [7, 8], [7, 18], [8, 7], [8, 9], [8, 13], [9, 4], [9, 8], [9, 10], [10, 9], [10, 11], [10, 19], [11, 2], [11, 10], [11, 12], [12, 11], [12, 13], [12, 17], [13, 8], [13, 12], [13, 14], [14, 3], [14, 13], [14, 15], [15, 6], [15, 14], [15, 16], [16, 1], [16, 15], [16, 17], [17, 12], [17, 16], [17, 18], [18, 7], [18, 17], [18, 19], [19, 0], [19, 10], [19, 18]] as [[Int]], "\(type)")
            #expect((0 ..< 20).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 20).map { graph.successors(of: $0).sorted() } == [[1, 5, 19], [0, 2, 16], [1, 3, 11], [2, 4, 14], [3, 5, 9], [0, 4, 6], [5, 7, 15], [6, 8, 18], [7, 9, 13], [4, 8, 10], [9, 11, 19], [2, 10, 12], [11, 13, 17], [8, 12, 14], [3, 13, 15], [6, 14, 16], [1, 15, 17], [12, 16, 18], [7, 17, 19], [0, 10, 18]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 20).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.desargues(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.desargues(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.desargues(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.desargues(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.desargues(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.desargues(), "StableDirectedGraph<Int>")
    }

    @Test("NG-228 dodecahedral: [10, 7, 4, -4, -7, 10, -4, 7, -7, 4]^2 on 20")
    func ng228() {
        // UndirectedAdjacencyList<Int>.dodecahedral() → n 20; m 30; deg 3…3; E [0–1, 0–10, 0–19, 1–2, 1–8, 2–3, 2–6, 3–4, 3–19, 4–5, 4–17, 5–6, 5–15, 6–7, 7–8, 7–14, 8–9, 9–10, 9–13, 10–11, 11–12, 11–18, 12–13, 12–16, 13–14, 14–15, 15–16, 16–17, 17–18, 18–19]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 20 && graph.edgeCount == 30 && graph.edges.count == 30, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 20), "\(type)")
            #expect((0 ..< 20).map { graph.vertexIndex(of: $0) } == Array(0 ..< 20), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 10], [0, 19], [1, 2], [1, 8], [2, 3], [2, 6], [3, 4], [3, 19], [4, 5], [4, 17], [5, 6], [5, 15], [6, 7], [7, 8], [7, 14], [8, 9], [9, 10], [9, 13], [10, 11], [11, 12], [11, 18], [12, 13], [12, 16], [13, 14], [14, 15], [15, 16], [16, 17], [17, 18], [18, 19]] as [[Int]], "\(type)")
            #expect((0 ..< 20).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 20).map { graph.neighbors(of: $0).sorted() } == [[1, 10, 19], [0, 2, 8], [1, 3, 6], [2, 4, 19], [3, 5, 17], [4, 6, 15], [2, 5, 7], [6, 8, 14], [1, 7, 9], [8, 10, 13], [0, 9, 11], [10, 12, 18], [11, 13, 16], [9, 12, 14], [7, 13, 15], [5, 14, 16], [12, 15, 17], [4, 16, 18], [11, 17, 19], [0, 3, 18]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 20).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.dodecahedral(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.dodecahedral(), "Pseudograph<Int>")
        check(Multigraph<Int>.dodecahedral(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 20 && graph.edgeCount == 60 && graph.edges.count == 60, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 20), "\(type)")
            #expect((0 ..< 20).map { graph.vertexIndex(of: $0) } == Array(0 ..< 20), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 20)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 10], [0, 19], [1, 0], [1, 2], [1, 8], [2, 1], [2, 3], [2, 6], [3, 2], [3, 4], [3, 19], [4, 3], [4, 5], [4, 17], [5, 4], [5, 6], [5, 15], [6, 2], [6, 5], [6, 7], [7, 6], [7, 8], [7, 14], [8, 1], [8, 7], [8, 9], [9, 8], [9, 10], [9, 13], [10, 0], [10, 9], [10, 11], [11, 10], [11, 12], [11, 18], [12, 11], [12, 13], [12, 16], [13, 9], [13, 12], [13, 14], [14, 7], [14, 13], [14, 15], [15, 5], [15, 14], [15, 16], [16, 12], [16, 15], [16, 17], [17, 4], [17, 16], [17, 18], [18, 11], [18, 17], [18, 19], [19, 0], [19, 3], [19, 18]] as [[Int]], "\(type)")
            #expect((0 ..< 20).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 20).map { graph.successors(of: $0).sorted() } == [[1, 10, 19], [0, 2, 8], [1, 3, 6], [2, 4, 19], [3, 5, 17], [4, 6, 15], [2, 5, 7], [6, 8, 14], [1, 7, 9], [8, 10, 13], [0, 9, 11], [10, 12, 18], [11, 13, 16], [9, 12, 14], [7, 13, 15], [5, 14, 16], [12, 15, 17], [4, 16, 18], [11, 17, 19], [0, 3, 18]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 20).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.dodecahedral(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.dodecahedral(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.dodecahedral(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.dodecahedral(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.dodecahedral(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.dodecahedral(), "StableDirectedGraph<Int>")
    }

    @Test("NG-229 frucht: [-5, -2, -4, 2, 5, -2, 2, 5, -2, -5, 4, 2]^1 on 12")
    func ng229() {
        // UndirectedAdjacencyList<Int>.frucht() → n 12; m 18; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–7, 0–11, 1–2, 1–11, 2–3, 2–10, 3–4, 3–5, 4–5, 4–9, 5–6, 6–7, 6–8, 7–8, 8–9, 9–10, 10–11]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 7], [0, 11], [1, 2], [1, 11], [2, 3], [2, 10], [3, 4], [3, 5], [4, 5], [4, 9], [5, 6], [6, 7], [6, 8], [7, 8], [8, 9], [9, 10], [10, 11]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.neighbors(of: $0).sorted() } == [[1, 7, 11], [0, 2, 11], [1, 3, 10], [2, 4, 5], [3, 5, 9], [3, 4, 6], [5, 7, 8], [0, 6, 8], [6, 7, 9], [4, 8, 10], [2, 9, 11], [0, 1, 10]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.frucht(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.frucht(), "Pseudograph<Int>")
        check(Multigraph<Int>.frucht(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 36 && graph.edges.count == 36, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 7], [0, 11], [1, 0], [1, 2], [1, 11], [2, 1], [2, 3], [2, 10], [3, 2], [3, 4], [3, 5], [4, 3], [4, 5], [4, 9], [5, 3], [5, 4], [5, 6], [6, 5], [6, 7], [6, 8], [7, 0], [7, 6], [7, 8], [8, 6], [8, 7], [8, 9], [9, 4], [9, 8], [9, 10], [10, 2], [10, 9], [10, 11], [11, 0], [11, 1], [11, 10]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.successors(of: $0).sorted() } == [[1, 7, 11], [0, 2, 11], [1, 3, 10], [2, 4, 5], [3, 5, 9], [3, 4, 6], [5, 7, 8], [0, 6, 8], [6, 7, 9], [4, 8, 10], [2, 9, 11], [0, 1, 10]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.frucht(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.frucht(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.frucht(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.frucht(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.frucht(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.frucht(), "StableDirectedGraph<Int>")
    }

    @Test("NG-230 Heawood directed: both arcs")
    func ng230() {
        // CompressedSparseRow.heawood() → n 14; m 42; out [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0→1, 0→5, 0→13, 1→0, 1→2, 1→10, 2→1, 2→3, 2→7, 3→2, 3→4, 3→12, 4→3, 4→5, 4→9, 5→0, 5→4, 5→6, 6→5, 6→7, 6→11, 7→2, 7→6, 7→8, 8→7, 8→9, 8→13, 9→4, 9→8, 9→10, 10→1, 10→9, 10→11, 11→6, 11→10, 11→12, 12→3, 12→11, 12→13, 13→0, 13→8, 13→12]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 14 && graph.edgeCount == 21 && graph.edges.count == 21, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 14), "\(type)")
            #expect((0 ..< 14).map { graph.vertexIndex(of: $0) } == Array(0 ..< 14), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 5], [0, 13], [1, 2], [1, 10], [2, 3], [2, 7], [3, 4], [3, 12], [4, 5], [4, 9], [5, 6], [6, 7], [6, 11], [7, 8], [8, 9], [8, 13], [9, 10], [10, 11], [11, 12], [12, 13]] as [[Int]], "\(type)")
            #expect((0 ..< 14).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 14).map { graph.neighbors(of: $0).sorted() } == [[1, 5, 13], [0, 2, 10], [1, 3, 7], [2, 4, 12], [3, 5, 9], [0, 4, 6], [5, 7, 11], [2, 6, 8], [7, 9, 13], [4, 8, 10], [1, 9, 11], [6, 10, 12], [3, 11, 13], [0, 8, 12]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 14).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.heawood(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.heawood(), "Pseudograph<Int>")
        check(Multigraph<Int>.heawood(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 14 && graph.edgeCount == 42 && graph.edges.count == 42, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 14), "\(type)")
            #expect((0 ..< 14).map { graph.vertexIndex(of: $0) } == Array(0 ..< 14), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 14)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 5], [0, 13], [1, 0], [1, 2], [1, 10], [2, 1], [2, 3], [2, 7], [3, 2], [3, 4], [3, 12], [4, 3], [4, 5], [4, 9], [5, 0], [5, 4], [5, 6], [6, 5], [6, 7], [6, 11], [7, 2], [7, 6], [7, 8], [8, 7], [8, 9], [8, 13], [9, 4], [9, 8], [9, 10], [10, 1], [10, 9], [10, 11], [11, 6], [11, 10], [11, 12], [12, 3], [12, 11], [12, 13], [13, 0], [13, 8], [13, 12]] as [[Int]], "\(type)")
            #expect((0 ..< 14).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 14).map { graph.successors(of: $0).sorted() } == [[1, 5, 13], [0, 2, 10], [1, 3, 7], [2, 4, 12], [3, 5, 9], [0, 4, 6], [5, 7, 11], [2, 6, 8], [7, 9, 13], [4, 8, 10], [1, 9, 11], [6, 10, 12], [3, 11, 13], [0, 8, 12]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 14).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.heawood(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.heawood(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.heawood(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.heawood(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.heawood(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.heawood(), "StableDirectedGraph<Int>")
    }

    @Test("NG-231 icosahedral")
    func ng231() {
        // UndirectedAdjacencyList<Int>.icosahedral() → n 12; m 30; deg [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–2, 1–5, 1–6, 1–7, 2–3, 2–7, 2–8, 3–4, 3–8, 3–9, 4–5, 4–9, 4–10, 5–6, 5–10, 6–7, 6–10, 6–11, 7–8, 7–11, 8–9, 8–11, 9–10, 9–11, 10–11]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 30 && graph.edges.count == 30, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 2], [1, 5], [1, 6], [1, 7], [2, 3], [2, 7], [2, 8], [3, 4], [3, 8], [3, 9], [4, 5], [4, 9], [4, 10], [5, 6], [5, 10], [6, 7], [6, 10], [6, 11], [7, 8], [7, 11], [8, 9], [8, 11], [9, 10], [9, 11], [10, 11]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4, 5], [0, 2, 5, 6, 7], [0, 1, 3, 7, 8], [0, 2, 4, 8, 9], [0, 3, 5, 9, 10], [0, 1, 4, 6, 10], [1, 5, 7, 10, 11], [1, 2, 6, 8, 11], [2, 3, 7, 9, 11], [3, 4, 8, 10, 11], [4, 5, 6, 9, 11], [6, 7, 8, 9, 10]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 6)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.icosahedral(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.icosahedral(), "Pseudograph<Int>")
        check(Multigraph<Int>.icosahedral(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 60 && graph.edges.count == 60, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 0], [1, 2], [1, 5], [1, 6], [1, 7], [2, 0], [2, 1], [2, 3], [2, 7], [2, 8], [3, 0], [3, 2], [3, 4], [3, 8], [3, 9], [4, 0], [4, 3], [4, 5], [4, 9], [4, 10], [5, 0], [5, 1], [5, 4], [5, 6], [5, 10], [6, 1], [6, 5], [6, 7], [6, 10], [6, 11], [7, 1], [7, 2], [7, 6], [7, 8], [7, 11], [8, 2], [8, 3], [8, 7], [8, 9], [8, 11], [9, 3], [9, 4], [9, 8], [9, 10], [9, 11], [10, 4], [10, 5], [10, 6], [10, 9], [10, 11], [11, 6], [11, 7], [11, 8], [11, 9], [11, 10]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            #expect(inDegrees == [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4, 5], [0, 2, 5, 6, 7], [0, 1, 3, 7, 8], [0, 2, 4, 8, 9], [0, 3, 5, 9, 10], [0, 1, 4, 6, 10], [1, 5, 7, 10, 11], [1, 2, 6, 8, 11], [2, 3, 7, 9, 11], [3, 4, 8, 10, 11], [4, 5, 6, 9, 11], [6, 7, 8, 9, 10]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 6)), "\(type)")
        }
        checkDirected(CompressedSparseRow.icosahedral(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.icosahedral(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.icosahedral(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.icosahedral(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.icosahedral(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.icosahedral(), "StableDirectedGraph<Int>")
    }

    @Test("NG-232 tutte")
    func ng232() {
        // UndirectedAdjacencyList<Int>.tutte() → n 46; m 69; deg 3…3; E [0–1, 0–16, 0–31, 1–2, 1–3, 2–4, 2–5, 3–5, 3–6, 4–7, 4–8, 5–9, 6–10, 6–11, 7–12, 7–44, 8–9, 8–13, 9–11, 10–14, 10–15, 11–15, 12–13, 12–14, 13–15, 14–22, 16–17, 16–18, 17–19, 17–20, 18–20, 18–21, 19–22, 19–23, 20–24, 21–25, 21–26, 22–27, 23–24, 23–28, 24–26, 25–29, 25–30, 26–30, 27–28, 27–29, 28–30, 29–37, 31–32, 31–33, 32–34, 32–35, 33–35, 33–36, 34–37, 34–38, 35–39, 36–40, 36–41, 37–42, 38–39, 38–43, 39–41, 40–44, 40–45, 41–45, 42–43, 42–44, 43–45]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 46 && graph.edgeCount == 69 && graph.edges.count == 69, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 46), "\(type)")
            #expect((0 ..< 46).map { graph.vertexIndex(of: $0) } == Array(0 ..< 46), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 16], [0, 31], [1, 2], [1, 3], [2, 4], [2, 5], [3, 5], [3, 6], [4, 7], [4, 8], [5, 9], [6, 10], [6, 11], [7, 12], [7, 44], [8, 9], [8, 13], [9, 11], [10, 14], [10, 15], [11, 15], [12, 13], [12, 14], [13, 15], [14, 22], [16, 17], [16, 18], [17, 19], [17, 20], [18, 20], [18, 21], [19, 22], [19, 23], [20, 24], [21, 25], [21, 26], [22, 27], [23, 24], [23, 28], [24, 26], [25, 29], [25, 30], [26, 30], [27, 28], [27, 29], [28, 30], [29, 37], [31, 32], [31, 33], [32, 34], [32, 35], [33, 35], [33, 36], [34, 37], [34, 38], [35, 39], [36, 40], [36, 41], [37, 42], [38, 39], [38, 43], [39, 41], [40, 44], [40, 45], [41, 45], [42, 43], [42, 44], [43, 45]] as [[Int]], "\(type)")
            #expect((0 ..< 46).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 46).map { graph.neighbors(of: $0).sorted() } == [[1, 16, 31], [0, 2, 3], [1, 4, 5], [1, 5, 6], [2, 7, 8], [2, 3, 9], [3, 10, 11], [4, 12, 44], [4, 9, 13], [5, 8, 11], [6, 14, 15], [6, 9, 15], [7, 13, 14], [8, 12, 15], [10, 12, 22], [10, 11, 13], [0, 17, 18], [16, 19, 20], [16, 20, 21], [17, 22, 23], [17, 18, 24], [18, 25, 26], [14, 19, 27], [19, 24, 28], [20, 23, 26], [21, 29, 30], [21, 24, 30], [22, 28, 29], [23, 27, 30], [25, 27, 37], [25, 26, 28], [0, 32, 33], [31, 34, 35], [31, 35, 36], [32, 37, 38], [32, 33, 39], [33, 40, 41], [29, 34, 42], [34, 39, 43], [35, 38, 41], [36, 44, 45], [36, 39, 45], [37, 43, 44], [38, 42, 45], [7, 40, 42], [40, 41, 43]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 46).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.tutte(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.tutte(), "Pseudograph<Int>")
        check(Multigraph<Int>.tutte(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 46 && graph.edgeCount == 138 && graph.edges.count == 138, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 46), "\(type)")
            #expect((0 ..< 46).map { graph.vertexIndex(of: $0) } == Array(0 ..< 46), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 46)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 16], [0, 31], [1, 0], [1, 2], [1, 3], [2, 1], [2, 4], [2, 5], [3, 1], [3, 5], [3, 6], [4, 2], [4, 7], [4, 8], [5, 2], [5, 3], [5, 9], [6, 3], [6, 10], [6, 11], [7, 4], [7, 12], [7, 44], [8, 4], [8, 9], [8, 13], [9, 5], [9, 8], [9, 11], [10, 6], [10, 14], [10, 15], [11, 6], [11, 9], [11, 15], [12, 7], [12, 13], [12, 14], [13, 8], [13, 12], [13, 15], [14, 10], [14, 12], [14, 22], [15, 10], [15, 11], [15, 13], [16, 0], [16, 17], [16, 18], [17, 16], [17, 19], [17, 20], [18, 16], [18, 20], [18, 21], [19, 17], [19, 22], [19, 23], [20, 17], [20, 18], [20, 24], [21, 18], [21, 25], [21, 26], [22, 14], [22, 19], [22, 27], [23, 19], [23, 24], [23, 28], [24, 20], [24, 23], [24, 26], [25, 21], [25, 29], [25, 30], [26, 21], [26, 24], [26, 30], [27, 22], [27, 28], [27, 29], [28, 23], [28, 27], [28, 30], [29, 25], [29, 27], [29, 37], [30, 25], [30, 26], [30, 28], [31, 0], [31, 32], [31, 33], [32, 31], [32, 34], [32, 35], [33, 31], [33, 35], [33, 36], [34, 32], [34, 37], [34, 38], [35, 32], [35, 33], [35, 39], [36, 33], [36, 40], [36, 41], [37, 29], [37, 34], [37, 42], [38, 34], [38, 39], [38, 43], [39, 35], [39, 38], [39, 41], [40, 36], [40, 44], [40, 45], [41, 36], [41, 39], [41, 45], [42, 37], [42, 43], [42, 44], [43, 38], [43, 42], [43, 45], [44, 7], [44, 40], [44, 42], [45, 40], [45, 41], [45, 43]] as [[Int]], "\(type)")
            #expect((0 ..< 46).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 46).map { graph.successors(of: $0).sorted() } == [[1, 16, 31], [0, 2, 3], [1, 4, 5], [1, 5, 6], [2, 7, 8], [2, 3, 9], [3, 10, 11], [4, 12, 44], [4, 9, 13], [5, 8, 11], [6, 14, 15], [6, 9, 15], [7, 13, 14], [8, 12, 15], [10, 12, 22], [10, 11, 13], [0, 17, 18], [16, 19, 20], [16, 20, 21], [17, 22, 23], [17, 18, 24], [18, 25, 26], [14, 19, 27], [19, 24, 28], [20, 23, 26], [21, 29, 30], [21, 24, 30], [22, 28, 29], [23, 27, 30], [25, 27, 37], [25, 26, 28], [0, 32, 33], [31, 34, 35], [31, 35, 36], [32, 37, 38], [32, 33, 39], [33, 40, 41], [29, 34, 42], [34, 39, 43], [35, 38, 41], [36, 44, 45], [36, 39, 45], [37, 43, 44], [38, 42, 45], [7, 40, 42], [40, 41, 43]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 46).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.tutte(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.tutte(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.tutte(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.tutte(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.tutte(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.tutte(), "StableDirectedGraph<Int>")
    }

    @Test("NG-233 chvatal")
    func ng233() {
        // UndirectedAdjacencyList<Int>.chvatal() → n 12; m 24; deg [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]; E [0–1, 0–4, 0–6, 0–9, 1–2, 1–5, 1–7, 2–3, 2–6, 2–8, 3–4, 3–7, 3–9, 4–5, 4–8, 5–10, 5–11, 6–10, 6–11, 7–8, 7–11, 8–10, 9–10, 9–11]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [0, 6], [0, 9], [1, 2], [1, 5], [1, 7], [2, 3], [2, 6], [2, 8], [3, 4], [3, 7], [3, 9], [4, 5], [4, 8], [5, 10], [5, 11], [6, 10], [6, 11], [7, 8], [7, 11], [8, 10], [9, 10], [9, 11]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.neighbors(of: $0).sorted() } == [[1, 4, 6, 9], [0, 2, 5, 7], [1, 3, 6, 8], [2, 4, 7, 9], [0, 3, 5, 8], [1, 4, 10, 11], [0, 2, 10, 11], [1, 3, 8, 11], [2, 4, 7, 10], [0, 3, 10, 11], [5, 6, 8, 9], [5, 6, 7, 9]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.chvatal(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.chvatal(), "Pseudograph<Int>")
        check(Multigraph<Int>.chvatal(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 48 && graph.edges.count == 48, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 4], [0, 6], [0, 9], [1, 0], [1, 2], [1, 5], [1, 7], [2, 1], [2, 3], [2, 6], [2, 8], [3, 2], [3, 4], [3, 7], [3, 9], [4, 0], [4, 3], [4, 5], [4, 8], [5, 1], [5, 4], [5, 10], [5, 11], [6, 0], [6, 2], [6, 10], [6, 11], [7, 1], [7, 3], [7, 8], [7, 11], [8, 2], [8, 4], [8, 7], [8, 10], [9, 0], [9, 3], [9, 10], [9, 11], [10, 5], [10, 6], [10, 8], [10, 9], [11, 5], [11, 6], [11, 7], [11, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect(inDegrees == [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.successors(of: $0).sorted() } == [[1, 4, 6, 9], [0, 2, 5, 7], [1, 3, 6, 8], [2, 4, 7, 9], [0, 3, 5, 8], [1, 4, 10, 11], [0, 2, 10, 11], [1, 3, 8, 11], [2, 4, 7, 10], [0, 3, 10, 11], [5, 6, 8, 9], [5, 6, 7, 9]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.chvatal(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.chvatal(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.chvatal(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.chvatal(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.chvatal(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.chvatal(), "StableDirectedGraph<Int>")
    }

    @Test("NG-234 hoffmanSingleton")
    func ng234() {
        // UndirectedAdjacencyList<Int>.hoffmanSingleton() → n 50; m 175; deg 7…7
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 50 && graph.edgeCount == 175 && graph.edges.count == 175, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 50), "\(type)")
            #expect((0 ..< 50).map { graph.vertexIndex(of: $0) } == Array(0 ..< 50), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [0, 25], [0, 30], [0, 35], [0, 40], [0, 45], [1, 2], [1, 26], [1, 31], [1, 36], [1, 41], [1, 46], [2, 3], [2, 27], [2, 32], [2, 37], [2, 42], [2, 47], [3, 4], [3, 28], [3, 33], [3, 38], [3, 43], [3, 48], [4, 29], [4, 34], [4, 39], [4, 44], [4, 49], [5, 6], [5, 9], [5, 25], [5, 31], [5, 37], [5, 43], [5, 49], [6, 7], [6, 26], [6, 32], [6, 38], [6, 44], [6, 45], [7, 8], [7, 27], [7, 33], [7, 39], [7, 40], [7, 46], [8, 9], [8, 28], [8, 34], [8, 35], [8, 41], [8, 47], [9, 29], [9, 30], [9, 36], [9, 42], [9, 48], [10, 11], [10, 14], [10, 25], [10, 32], [10, 39], [10, 41], [10, 48], [11, 12], [11, 26], [11, 33], [11, 35], [11, 42], [11, 49], [12, 13], [12, 27], [12, 34], [12, 36], [12, 43], [12, 45], [13, 14], [13, 28], [13, 30], [13, 37], [13, 44], [13, 46], [14, 29], [14, 31], [14, 38], [14, 40], [14, 47], [15, 16], [15, 19], [15, 25], [15, 33], [15, 36], [15, 44], [15, 47], [16, 17], [16, 26], [16, 34], [16, 37], [16, 40], [16, 48], [17, 18], [17, 27], [17, 30], [17, 38], [17, 41], [17, 49], [18, 19], [18, 28], [18, 31], [18, 39], [18, 42], [18, 45], [19, 29], [19, 32], [19, 35], [19, 43], [19, 46], [20, 21], [20, 24], [20, 25], [20, 34], [20, 38], [20, 42], [20, 46], [21, 22], [21, 26], [21, 30], [21, 39], [21, 43], [21, 47], [22, 23], [22, 27], [22, 31], [22, 35], [22, 44], [22, 48], [23, 24], [23, 28], [23, 32], [23, 36], [23, 40], [23, 49], [24, 29], [24, 33], [24, 37], [24, 41], [24, 45], [25, 27], [25, 28], [26, 28], [26, 29], [27, 29], [30, 32], [30, 33], [31, 33], [31, 34], [32, 34], [35, 37], [35, 38], [36, 38], [36, 39], [37, 39], [40, 42], [40, 43], [41, 43], [41, 44], [42, 44], [45, 47], [45, 48], [46, 48], [46, 49], [47, 49]] as [[Int]], "\(type)")
            #expect((0 ..< 50).map { graph.degree(of: $0) } == [7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7] as [Int], "\(type)")
            #expect((0 ..< 50).map { graph.neighbors(of: $0).sorted() } == [[1, 4, 25, 30, 35, 40, 45], [0, 2, 26, 31, 36, 41, 46], [1, 3, 27, 32, 37, 42, 47], [2, 4, 28, 33, 38, 43, 48], [0, 3, 29, 34, 39, 44, 49], [6, 9, 25, 31, 37, 43, 49], [5, 7, 26, 32, 38, 44, 45], [6, 8, 27, 33, 39, 40, 46], [7, 9, 28, 34, 35, 41, 47], [5, 8, 29, 30, 36, 42, 48], [11, 14, 25, 32, 39, 41, 48], [10, 12, 26, 33, 35, 42, 49], [11, 13, 27, 34, 36, 43, 45], [12, 14, 28, 30, 37, 44, 46], [10, 13, 29, 31, 38, 40, 47], [16, 19, 25, 33, 36, 44, 47], [15, 17, 26, 34, 37, 40, 48], [16, 18, 27, 30, 38, 41, 49], [17, 19, 28, 31, 39, 42, 45], [15, 18, 29, 32, 35, 43, 46], [21, 24, 25, 34, 38, 42, 46], [20, 22, 26, 30, 39, 43, 47], [21, 23, 27, 31, 35, 44, 48], [22, 24, 28, 32, 36, 40, 49], [20, 23, 29, 33, 37, 41, 45], [0, 5, 10, 15, 20, 27, 28], [1, 6, 11, 16, 21, 28, 29], [2, 7, 12, 17, 22, 25, 29], [3, 8, 13, 18, 23, 25, 26], [4, 9, 14, 19, 24, 26, 27], [0, 9, 13, 17, 21, 32, 33], [1, 5, 14, 18, 22, 33, 34], [2, 6, 10, 19, 23, 30, 34], [3, 7, 11, 15, 24, 30, 31], [4, 8, 12, 16, 20, 31, 32], [0, 8, 11, 19, 22, 37, 38], [1, 9, 12, 15, 23, 38, 39], [2, 5, 13, 16, 24, 35, 39], [3, 6, 14, 17, 20, 35, 36], [4, 7, 10, 18, 21, 36, 37], [0, 7, 14, 16, 23, 42, 43], [1, 8, 10, 17, 24, 43, 44], [2, 9, 11, 18, 20, 40, 44], [3, 5, 12, 19, 21, 40, 41], [4, 6, 13, 15, 22, 41, 42], [0, 6, 12, 18, 24, 47, 48], [1, 7, 13, 19, 20, 48, 49], [2, 8, 14, 15, 21, 45, 49], [3, 9, 10, 16, 22, 45, 46], [4, 5, 11, 17, 23, 46, 47]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 50).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.hoffmanSingleton(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.hoffmanSingleton(), "Pseudograph<Int>")
        check(Multigraph<Int>.hoffmanSingleton(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 50 && graph.edgeCount == 350 && graph.edges.count == 350, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 50), "\(type)")
            #expect((0 ..< 50).map { graph.vertexIndex(of: $0) } == Array(0 ..< 50), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 50)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            // Row-major, no repeats, no self-loops, and each arc by the family's rule.
            let ends = graph.edges.map { [$0.source, $0.target] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.source != e.target && e.source < 50 && e.target < 50 }, "\(type)")
            #expect((0 ..< 50).allSatisfy { graph.outDegree(of: $0) == 7 } && inDegrees.allSatisfy { $0 == 7 }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 50).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.hoffmanSingleton(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.hoffmanSingleton(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.hoffmanSingleton(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.hoffmanSingleton(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.hoffmanSingleton(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.hoffmanSingleton(), "StableDirectedGraph<Int>")
    }

    @Test("NG-235 icosahedral directed: both arcs")
    func ng235() {
        // CompressedSparseRow.icosahedral() → n 12; m 60; out [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]; in [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]; E [0→1, 0→2, 0→3, 0→4, 0→5, 1→0, 1→2, 1→5, 1→6, 1→7, 2→0, 2→1, 2→3, 2→7, 2→8, 3→0, 3→2, 3→4, 3→8, 3→9, 4→0, 4→3, 4→5, 4→9, 4→10, 5→0, 5→1, 5→4, 5→6, 5→10, 6→1, 6→5, 6→7, 6→10, 6→11, 7→1, 7→2, 7→6, 7→8, 7→11, 8→2, 8→3, 8→7, 8→9, 8→11, 9→3, 9→4, 9→8, 9→10, 9→11, 10→4, 10→5, 10→6, 10→9, 10→11, 11→6, 11→7, 11→8, 11→9, 11→10]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 30 && graph.edges.count == 30, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 2], [1, 5], [1, 6], [1, 7], [2, 3], [2, 7], [2, 8], [3, 4], [3, 8], [3, 9], [4, 5], [4, 9], [4, 10], [5, 6], [5, 10], [6, 7], [6, 10], [6, 11], [7, 8], [7, 11], [8, 9], [8, 11], [9, 10], [9, 11], [10, 11]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.degree(of: $0) } == [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4, 5], [0, 2, 5, 6, 7], [0, 1, 3, 7, 8], [0, 2, 4, 8, 9], [0, 3, 5, 9, 10], [0, 1, 4, 6, 10], [1, 5, 7, 10, 11], [1, 2, 6, 8, 11], [2, 3, 7, 9, 11], [3, 4, 8, 10, 11], [4, 5, 6, 9, 11], [6, 7, 8, 9, 10]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 6)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.icosahedral(), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.icosahedral(), "Pseudograph<Int>")
        check(Multigraph<Int>.icosahedral(), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 60 && graph.edges.count == 60, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 0], [1, 2], [1, 5], [1, 6], [1, 7], [2, 0], [2, 1], [2, 3], [2, 7], [2, 8], [3, 0], [3, 2], [3, 4], [3, 8], [3, 9], [4, 0], [4, 3], [4, 5], [4, 9], [4, 10], [5, 0], [5, 1], [5, 4], [5, 6], [5, 10], [6, 1], [6, 5], [6, 7], [6, 10], [6, 11], [7, 1], [7, 2], [7, 6], [7, 8], [7, 11], [8, 2], [8, 3], [8, 7], [8, 9], [8, 11], [9, 3], [9, 4], [9, 8], [9, 10], [9, 11], [10, 4], [10, 5], [10, 6], [10, 9], [10, 11], [11, 6], [11, 7], [11, 8], [11, 9], [11, 10]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            #expect(inDegrees == [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4, 5], [0, 2, 5, 6, 7], [0, 1, 3, 7, 8], [0, 2, 4, 8, 9], [0, 3, 5, 9, 10], [0, 1, 4, 6, 10], [1, 5, 7, 10, 11], [1, 2, 6, 8, 11], [2, 3, 7, 9, 11], [3, 4, 8, 10, 11], [4, 5, 6, 9, 11], [6, 7, 8, 9, 10]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 6)), "\(type)")
        }
        checkDirected(CompressedSparseRow.icosahedral(), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.icosahedral(), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.icosahedral(), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.icosahedral(), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.icosahedral(), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.icosahedral(), "StableDirectedGraph<Int>")
    }
}
