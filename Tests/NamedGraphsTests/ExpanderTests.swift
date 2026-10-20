// Expander families (catalog NG-237 – NG-266): Margulis–Gabber–Galil on ℤₙ² as a simple graph (returning
// steps dropped, meeting steps merged), the chordal cycle on a prime field (the cycle and a chord to each
// inverse), and the Paley graph (y − x a nonzero square), undirected for p ≡ 1 (mod 4) and the Paley
// tournament for p ≡ 3 (mod 4). Both arcs when directed, except the tournament.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing

@Suite("NamedGraphs expander families")
struct ExpanderTests {
    @Test("NG-237 side 1: every step returns to the vertex, no edges")
    func ng237() {
        // UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 1) → n 1; m 0; deg [0]; E []
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
        check(UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.margulisGabberGalil(side: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.margulisGabberGalil(side: 1), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.margulisGabberGalil(side: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.margulisGabberGalil(side: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.margulisGabberGalil(side: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.margulisGabberGalil(side: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.margulisGabberGalil(side: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.margulisGabberGalil(side: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-238 side 2")
    func ng238() {
        // UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 2) → n 4; m 4; deg [2, 2, 2, 2]; E [0–1, 0–2, 1–3, 2–3]
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
        check(UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.margulisGabberGalil(side: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.margulisGabberGalil(side: 2), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.margulisGabberGalil(side: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.margulisGabberGalil(side: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.margulisGabberGalil(side: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.margulisGabberGalil(side: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.margulisGabberGalil(side: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.margulisGabberGalil(side: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-239 side 3: 4-regular")
    func ng239() {
        // UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 3) → n 9; m 18; deg [4, 4, 4, 4, 4, 4, 4, 4, 4]; E [0–1, 0–2, 0–3, 0–6, 1–2, 1–4, 1–7, 2–5, 2–8, 3–4, 3–5, 3–6, 4–5, 4–7, 5–8, 6–7, 6–8, 7–8]
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
        check(UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.margulisGabberGalil(side: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.margulisGabberGalil(side: 3), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.margulisGabberGalil(side: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.margulisGabberGalil(side: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.margulisGabberGalil(side: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.margulisGabberGalil(side: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.margulisGabberGalil(side: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.margulisGabberGalil(side: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-240 side 4: a step that meets another is one edge, degrees 4 to 6")
    func ng240() {
        // UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 4) → n 16; m 40; deg [4, 5, 4, 5, 5, 6, 5, 6, 4, 5, 4, 5, 5, 6, 5, 6]; E [0–1, 0–3, 0–4, 0–12, 1–2, 1–5, 1–9, 1–13, 2–3, 2–6, 2–14, 3–7, 3–11, 3–15, 4–5, 4–6, 4–7, 4–8, 5–6, 5–7, 5–9, 5–13, 6–7, 6–10, 7–11, 7–15, 8–9, 8–11, 8–12, 9–10, 9–13, 10–11, 10–14, 11–15, 12–13, 12–14, 12–15, 13–14, 13–15, 14–15]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 16 && graph.edgeCount == 40 && graph.edges.count == 40, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 16), "\(type)")
            #expect((0 ..< 16).map { graph.vertexIndex(of: $0) } == Array(0 ..< 16), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [0, 4], [0, 12], [1, 2], [1, 5], [1, 9], [1, 13], [2, 3], [2, 6], [2, 14], [3, 7], [3, 11], [3, 15], [4, 5], [4, 6], [4, 7], [4, 8], [5, 6], [5, 7], [5, 9], [5, 13], [6, 7], [6, 10], [7, 11], [7, 15], [8, 9], [8, 11], [8, 12], [9, 10], [9, 13], [10, 11], [10, 14], [11, 15], [12, 13], [12, 14], [12, 15], [13, 14], [13, 15], [14, 15]] as [[Int]], "\(type)")
            #expect((0 ..< 16).map { graph.degree(of: $0) } == [4, 5, 4, 5, 5, 6, 5, 6, 4, 5, 4, 5, 5, 6, 5, 6] as [Int], "\(type)")
            #expect((0 ..< 16).map { graph.neighbors(of: $0).sorted() } == [[1, 3, 4, 12], [0, 2, 5, 9, 13], [1, 3, 6, 14], [0, 2, 7, 11, 15], [0, 5, 6, 7, 8], [1, 4, 6, 7, 9, 13], [2, 4, 5, 7, 10], [3, 4, 5, 6, 11, 15], [4, 9, 11, 12], [1, 5, 8, 10, 13], [6, 9, 11, 14], [3, 7, 8, 10, 15], [0, 8, 13, 14, 15], [1, 5, 9, 12, 14, 15], [2, 10, 12, 13, 15], [3, 7, 11, 12, 13, 14]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 16).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.margulisGabberGalil(side: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.margulisGabberGalil(side: 4), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 16 && graph.edgeCount == 80 && graph.edges.count == 80, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 16), "\(type)")
            #expect((0 ..< 16).map { graph.vertexIndex(of: $0) } == Array(0 ..< 16), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 16)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [0, 4], [0, 12], [1, 0], [1, 2], [1, 5], [1, 9], [1, 13], [2, 1], [2, 3], [2, 6], [2, 14], [3, 0], [3, 2], [3, 7], [3, 11], [3, 15], [4, 0], [4, 5], [4, 6], [4, 7], [4, 8], [5, 1], [5, 4], [5, 6], [5, 7], [5, 9], [5, 13], [6, 2], [6, 4], [6, 5], [6, 7], [6, 10], [7, 3], [7, 4], [7, 5], [7, 6], [7, 11], [7, 15], [8, 4], [8, 9], [8, 11], [8, 12], [9, 1], [9, 5], [9, 8], [9, 10], [9, 13], [10, 6], [10, 9], [10, 11], [10, 14], [11, 3], [11, 7], [11, 8], [11, 10], [11, 15], [12, 0], [12, 8], [12, 13], [12, 14], [12, 15], [13, 1], [13, 5], [13, 9], [13, 12], [13, 14], [13, 15], [14, 2], [14, 10], [14, 12], [14, 13], [14, 15], [15, 3], [15, 7], [15, 11], [15, 12], [15, 13], [15, 14]] as [[Int]], "\(type)")
            #expect((0 ..< 16).map { graph.outDegree(of: $0) } == [4, 5, 4, 5, 5, 6, 5, 6, 4, 5, 4, 5, 5, 6, 5, 6] as [Int], "\(type)")
            #expect(inDegrees == [4, 5, 4, 5, 5, 6, 5, 6, 4, 5, 4, 5, 5, 6, 5, 6] as [Int], "\(type)")
            #expect((0 ..< 16).map { graph.successors(of: $0).sorted() } == [[1, 3, 4, 12], [0, 2, 5, 9, 13], [1, 3, 6, 14], [0, 2, 7, 11, 15], [0, 5, 6, 7, 8], [1, 4, 6, 7, 9, 13], [2, 4, 5, 7, 10], [3, 4, 5, 6, 11, 15], [4, 9, 11, 12], [1, 5, 8, 10, 13], [6, 9, 11, 14], [3, 7, 8, 10, 15], [0, 8, 13, 14, 15], [1, 5, 9, 12, 14, 15], [2, 10, 12, 13, 15], [3, 7, 11, 12, 13, 14]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 16).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.margulisGabberGalil(side: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.margulisGabberGalil(side: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.margulisGabberGalil(side: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.margulisGabberGalil(side: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.margulisGabberGalil(side: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.margulisGabberGalil(side: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-241 side 5: degrees 4 to 8")
    func ng241() {
        // UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 5) → n 25; m 70; deg 4…8
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 25 && graph.edgeCount == 70 && graph.edges.count == 70, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 25), "\(type)")
            #expect((0 ..< 25).map { graph.vertexIndex(of: $0) } == Array(0 ..< 25), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [0, 5], [0, 20], [1, 2], [1, 11], [1, 16], [2, 3], [2, 7], [2, 22], [3, 4], [3, 8], [3, 13], [3, 18], [3, 23], [4, 9], [4, 14], [4, 19], [4, 24], [5, 7], [5, 8], [5, 10], [6, 8], [6, 9], [6, 16], [6, 21], [7, 9], [7, 12], [8, 13], [8, 18], [8, 23], [9, 14], [9, 19], [9, 24], [10, 11], [10, 14], [10, 15], [11, 12], [11, 21], [12, 13], [12, 17], [13, 14], [13, 18], [13, 23], [14, 19], [14, 24], [15, 16], [15, 17], [15, 18], [15, 19], [15, 20], [16, 17], [16, 18], [16, 19], [17, 18], [17, 19], [17, 22], [18, 19], [18, 23], [19, 24], [20, 21], [20, 22], [20, 23], [20, 24], [21, 22], [21, 23], [21, 24], [22, 23], [22, 24], [23, 24]] as [[Int]], "\(type)")
            #expect((0 ..< 25).map { graph.degree(of: $0) } == [4, 4, 4, 6, 6, 4, 4, 4, 6, 6, 4, 4, 4, 6, 6, 6, 6, 6, 8, 8, 6, 6, 6, 8, 8] as [Int], "\(type)")
            #expect((0 ..< 25).map { graph.neighbors(of: $0).sorted() } == [[1, 4, 5, 20], [0, 2, 11, 16], [1, 3, 7, 22], [2, 4, 8, 13, 18, 23], [0, 3, 9, 14, 19, 24], [0, 7, 8, 10], [8, 9, 16, 21], [2, 5, 9, 12], [3, 5, 6, 13, 18, 23], [4, 6, 7, 14, 19, 24], [5, 11, 14, 15], [1, 10, 12, 21], [7, 11, 13, 17], [3, 8, 12, 14, 18, 23], [4, 9, 10, 13, 19, 24], [10, 16, 17, 18, 19, 20], [1, 6, 15, 17, 18, 19], [12, 15, 16, 18, 19, 22], [3, 8, 13, 15, 16, 17, 19, 23], [4, 9, 14, 15, 16, 17, 18, 24], [0, 15, 21, 22, 23, 24], [6, 11, 20, 22, 23, 24], [2, 17, 20, 21, 23, 24], [3, 8, 13, 18, 20, 21, 22, 24], [4, 9, 14, 19, 20, 21, 22, 23]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 25).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 5), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.margulisGabberGalil(side: 5), "Pseudograph<Int>")
        check(Multigraph<Int>.margulisGabberGalil(side: 5), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 25 && graph.edgeCount == 140 && graph.edges.count == 140, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 25), "\(type)")
            #expect((0 ..< 25).map { graph.vertexIndex(of: $0) } == Array(0 ..< 25), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 25)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 4], [0, 5], [0, 20], [1, 0], [1, 2], [1, 11], [1, 16], [2, 1], [2, 3], [2, 7], [2, 22], [3, 2], [3, 4], [3, 8], [3, 13], [3, 18], [3, 23], [4, 0], [4, 3], [4, 9], [4, 14], [4, 19], [4, 24], [5, 0], [5, 7], [5, 8], [5, 10], [6, 8], [6, 9], [6, 16], [6, 21], [7, 2], [7, 5], [7, 9], [7, 12], [8, 3], [8, 5], [8, 6], [8, 13], [8, 18], [8, 23], [9, 4], [9, 6], [9, 7], [9, 14], [9, 19], [9, 24], [10, 5], [10, 11], [10, 14], [10, 15], [11, 1], [11, 10], [11, 12], [11, 21], [12, 7], [12, 11], [12, 13], [12, 17], [13, 3], [13, 8], [13, 12], [13, 14], [13, 18], [13, 23], [14, 4], [14, 9], [14, 10], [14, 13], [14, 19], [14, 24], [15, 10], [15, 16], [15, 17], [15, 18], [15, 19], [15, 20], [16, 1], [16, 6], [16, 15], [16, 17], [16, 18], [16, 19], [17, 12], [17, 15], [17, 16], [17, 18], [17, 19], [17, 22], [18, 3], [18, 8], [18, 13], [18, 15], [18, 16], [18, 17], [18, 19], [18, 23], [19, 4], [19, 9], [19, 14], [19, 15], [19, 16], [19, 17], [19, 18], [19, 24], [20, 0], [20, 15], [20, 21], [20, 22], [20, 23], [20, 24], [21, 6], [21, 11], [21, 20], [21, 22], [21, 23], [21, 24], [22, 2], [22, 17], [22, 20], [22, 21], [22, 23], [22, 24], [23, 3], [23, 8], [23, 13], [23, 18], [23, 20], [23, 21], [23, 22], [23, 24], [24, 4], [24, 9], [24, 14], [24, 19], [24, 20], [24, 21], [24, 22], [24, 23]] as [[Int]], "\(type)")
            #expect((0 ..< 25).map { graph.outDegree(of: $0) } == [4, 4, 4, 6, 6, 4, 4, 4, 6, 6, 4, 4, 4, 6, 6, 6, 6, 6, 8, 8, 6, 6, 6, 8, 8] as [Int], "\(type)")
            #expect(inDegrees == [4, 4, 4, 6, 6, 4, 4, 4, 6, 6, 4, 4, 4, 6, 6, 6, 6, 6, 8, 8, 6, 6, 6, 8, 8] as [Int], "\(type)")
            #expect((0 ..< 25).map { graph.successors(of: $0).sorted() } == [[1, 4, 5, 20], [0, 2, 11, 16], [1, 3, 7, 22], [2, 4, 8, 13, 18, 23], [0, 3, 9, 14, 19, 24], [0, 7, 8, 10], [8, 9, 16, 21], [2, 5, 9, 12], [3, 5, 6, 13, 18, 23], [4, 6, 7, 14, 19, 24], [5, 11, 14, 15], [1, 10, 12, 21], [7, 11, 13, 17], [3, 8, 12, 14, 18, 23], [4, 9, 10, 13, 19, 24], [10, 16, 17, 18, 19, 20], [1, 6, 15, 17, 18, 19], [12, 15, 16, 18, 19, 22], [3, 8, 13, 15, 16, 17, 19, 23], [4, 9, 14, 15, 16, 17, 18, 24], [0, 15, 21, 22, 23, 24], [6, 11, 20, 22, 23, 24], [2, 17, 20, 21, 23, 24], [3, 8, 13, 18, 20, 21, 22, 24], [4, 9, 14, 19, 20, 21, 22, 23]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 25).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.margulisGabberGalil(side: 5), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.margulisGabberGalil(side: 5), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.margulisGabberGalil(side: 5), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.margulisGabberGalil(side: 5), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.margulisGabberGalil(side: 5), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.margulisGabberGalil(side: 5), "StableDirectedGraph<Int>")
    }

    @Test("NG-242 directed: both arcs")
    func ng242() {
        // CompressedSparseRow.margulisGabberGalil(side: 3) → n 9; m 36; out [4, 4, 4, 4, 4, 4, 4, 4, 4]; in [4, 4, 4, 4, 4, 4, 4, 4, 4]; E [0→1, 0→2, 0→3, 0→6, 1→0, 1→2, 1→4, 1→7, 2→0, 2→1, 2→5, 2→8, 3→0, 3→4, 3→5, 3→6, 4→1, 4→3, 4→5, 4→7, 5→2, 5→3, 5→4, 5→8, 6→0, 6→3, 6→7, 6→8, 7→1, 7→4, 7→6, 7→8, 8→2, 8→5, 8→6, 8→7]
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
        check(UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.margulisGabberGalil(side: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.margulisGabberGalil(side: 3), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.margulisGabberGalil(side: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.margulisGabberGalil(side: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.margulisGabberGalil(side: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.margulisGabberGalil(side: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.margulisGabberGalil(side: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.margulisGabberGalil(side: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-243 side 7")
    func ng243() {
        // UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 7) → n 49; m 154; deg 4…8
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 49 && graph.edgeCount == 154 && graph.edges.count == 154, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 49), "\(type)")
            #expect((0 ..< 49).map { graph.vertexIndex(of: $0) } == Array(0 ..< 49), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 6], [0, 7], [0, 42], [1, 2], [1, 15], [1, 22], [1, 29], [1, 36], [2, 3], [2, 16], [2, 23], [2, 30], [2, 37], [3, 4], [3, 10], [3, 45], [4, 5], [4, 11], [4, 18], [4, 39], [4, 46], [5, 6], [5, 26], [5, 33], [6, 13], [6, 20], [6, 41], [6, 48], [7, 9], [7, 10], [7, 11], [7, 12], [7, 14], [8, 10], [8, 11], [8, 12], [8, 13], [8, 22], [8, 29], [8, 36], [8, 43], [9, 11], [9, 12], [9, 13], [9, 23], [9, 30], [9, 37], [9, 44], [10, 12], [10, 13], [10, 17], [11, 13], [11, 18], [11, 25], [11, 46], [12, 33], [12, 40], [13, 20], [13, 27], [13, 48], [14, 16], [14, 17], [14, 18], [14, 19], [14, 21], [15, 17], [15, 18], [15, 19], [15, 20], [15, 29], [15, 36], [15, 43], [16, 18], [16, 19], [16, 20], [16, 30], [16, 37], [16, 44], [17, 19], [17, 20], [17, 24], [18, 20], [18, 25], [18, 32], [19, 40], [19, 47], [20, 27], [20, 34], [21, 22], [21, 27], [21, 28], [22, 23], [22, 36], [22, 43], [23, 24], [23, 37], [23, 44], [24, 25], [24, 31], [25, 26], [25, 32], [25, 39], [26, 27], [26, 47], [27, 34], [27, 41], [28, 29], [28, 30], [28, 33], [28, 34], [28, 35], [29, 30], [29, 31], [29, 34], [29, 43], [30, 31], [30, 32], [30, 44], [31, 32], [31, 33], [31, 38], [32, 33], [32, 34], [32, 39], [32, 46], [33, 34], [34, 41], [34, 48], [35, 38], [35, 39], [35, 42], [36, 39], [36, 40], [37, 40], [37, 41], [38, 41], [38, 45], [39, 46], [41, 48], [42, 43], [42, 44], [42, 47], [42, 48], [43, 44], [43, 45], [43, 48], [44, 45], [44, 46], [45, 46], [45, 47], [46, 47], [46, 48], [47, 48]] as [[Int]], "\(type)")
            #expect((0 ..< 49).map { graph.degree(of: $0) } == [4, 6, 6, 4, 6, 4, 6, 6, 8, 8, 6, 8, 6, 8, 6, 8, 8, 6, 8, 6, 8, 4, 6, 6, 4, 6, 4, 6, 6, 8, 8, 6, 8, 6, 8, 4, 6, 6, 4, 6, 4, 6, 6, 8, 8, 6, 8, 6, 8] as [Int], "\(type)")
            #expect((0 ..< 49).map { graph.neighbors(of: $0).sorted() } == [[1, 6, 7, 42], [0, 2, 15, 22, 29, 36], [1, 3, 16, 23, 30, 37], [2, 4, 10, 45], [3, 5, 11, 18, 39, 46], [4, 6, 26, 33], [0, 5, 13, 20, 41, 48], [0, 9, 10, 11, 12, 14], [10, 11, 12, 13, 22, 29, 36, 43], [7, 11, 12, 13, 23, 30, 37, 44], [3, 7, 8, 12, 13, 17], [4, 7, 8, 9, 13, 18, 25, 46], [7, 8, 9, 10, 33, 40], [6, 8, 9, 10, 11, 20, 27, 48], [7, 16, 17, 18, 19, 21], [1, 17, 18, 19, 20, 29, 36, 43], [2, 14, 18, 19, 20, 30, 37, 44], [10, 14, 15, 19, 20, 24], [4, 11, 14, 15, 16, 20, 25, 32], [14, 15, 16, 17, 40, 47], [6, 13, 15, 16, 17, 18, 27, 34], [14, 22, 27, 28], [1, 8, 21, 23, 36, 43], [2, 9, 22, 24, 37, 44], [17, 23, 25, 31], [11, 18, 24, 26, 32, 39], [5, 25, 27, 47], [13, 20, 21, 26, 34, 41], [21, 29, 30, 33, 34, 35], [1, 8, 15, 28, 30, 31, 34, 43], [2, 9, 16, 28, 29, 31, 32, 44], [24, 29, 30, 32, 33, 38], [18, 25, 30, 31, 33, 34, 39, 46], [5, 12, 28, 31, 32, 34], [20, 27, 28, 29, 32, 33, 41, 48], [28, 38, 39, 42], [1, 8, 15, 22, 39, 40], [2, 9, 16, 23, 40, 41], [31, 35, 41, 45], [4, 25, 32, 35, 36, 46], [12, 19, 36, 37], [6, 27, 34, 37, 38, 48], [0, 35, 43, 44, 47, 48], [8, 15, 22, 29, 42, 44, 45, 48], [9, 16, 23, 30, 42, 43, 45, 46], [3, 38, 43, 44, 46, 47], [4, 11, 32, 39, 44, 45, 47, 48], [19, 26, 42, 45, 46, 48], [6, 13, 34, 41, 42, 43, 46, 47]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 49).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 7), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.margulisGabberGalil(side: 7), "Pseudograph<Int>")
        check(Multigraph<Int>.margulisGabberGalil(side: 7), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 49 && graph.edgeCount == 308 && graph.edges.count == 308, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 49), "\(type)")
            #expect((0 ..< 49).map { graph.vertexIndex(of: $0) } == Array(0 ..< 49), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 49)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            // Row-major, no repeats, no self-loops, and each arc by the family's rule.
            let ends = graph.edges.map { [$0.source, $0.target] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.source != e.target && e.source < 49 && e.target < 49 }, "\(type)")
            #expect((0 ..< 49).allSatisfy { (4 ... 8).contains(graph.outDegree(of: $0)) && inDegrees[$0] == graph.outDegree(of: $0) }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 49).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.margulisGabberGalil(side: 7), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.margulisGabberGalil(side: 7), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.margulisGabberGalil(side: 7), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.margulisGabberGalil(side: 7), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.margulisGabberGalil(side: 7), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.margulisGabberGalil(side: 7), "StableDirectedGraph<Int>")
    }

    @Test("NG-245 p = 2: K2")
    func ng245() {
        // UndirectedAdjacencyList<Int>.chordalCycle(prime: 2) → n 2; m 1; deg [1, 1]; E [0–1]
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
        check(UndirectedAdjacencyList<Int>.chordalCycle(prime: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.chordalCycle(prime: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.chordalCycle(prime: 2), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.chordalCycle(prime: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.chordalCycle(prime: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.chordalCycle(prime: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.chordalCycle(prime: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.chordalCycle(prime: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.chordalCycle(prime: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-246 p = 3: a triangle, 1 and 2 are their own inverses")
    func ng246() {
        // UndirectedAdjacencyList<Int>.chordalCycle(prime: 3) → n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2]
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
        check(UndirectedAdjacencyList<Int>.chordalCycle(prime: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.chordalCycle(prime: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.chordalCycle(prime: 3), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.chordalCycle(prime: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.chordalCycle(prime: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.chordalCycle(prime: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.chordalCycle(prime: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.chordalCycle(prime: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.chordalCycle(prime: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-247 p = 5")
    func ng247() {
        // UndirectedAdjacencyList<Int>.chordalCycle(prime: 5) → n 5; m 5; deg [2, 2, 2, 2, 2]; E [0–1, 0–4, 1–2, 2–3, 3–4]
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
        check(UndirectedAdjacencyList<Int>.chordalCycle(prime: 5), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.chordalCycle(prime: 5), "Pseudograph<Int>")
        check(Multigraph<Int>.chordalCycle(prime: 5), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.chordalCycle(prime: 5), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.chordalCycle(prime: 5), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.chordalCycle(prime: 5), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.chordalCycle(prime: 5), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.chordalCycle(prime: 5), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.chordalCycle(prime: 5), "StableDirectedGraph<Int>")
    }

    @Test("NG-248 p = 7")
    func ng248() {
        // UndirectedAdjacencyList<Int>.chordalCycle(prime: 7) → n 7; m 9; deg [2, 2, 3, 3, 3, 3, 2]; E [0–1, 0–6, 1–2, 2–3, 2–4, 3–4, 3–5, 4–5, 5–6]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 6], [1, 2], [2, 3], [2, 4], [3, 4], [3, 5], [4, 5], [5, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [2, 2, 3, 3, 3, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.neighbors(of: $0).sorted() } == [[1, 6], [0, 2], [1, 3, 4], [2, 4, 5], [2, 3, 5], [3, 4, 6], [0, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.chordalCycle(prime: 7), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.chordalCycle(prime: 7), "Pseudograph<Int>")
        check(Multigraph<Int>.chordalCycle(prime: 7), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 6], [1, 0], [1, 2], [2, 1], [2, 3], [2, 4], [3, 2], [3, 4], [3, 5], [4, 2], [4, 3], [4, 5], [5, 3], [5, 4], [5, 6], [6, 0], [6, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [2, 2, 3, 3, 3, 3, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 3, 3, 3, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.successors(of: $0).sorted() } == [[1, 6], [0, 2], [1, 3, 4], [2, 4, 5], [2, 3, 5], [3, 4, 6], [0, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.chordalCycle(prime: 7), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.chordalCycle(prime: 7), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.chordalCycle(prime: 7), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.chordalCycle(prime: 7), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.chordalCycle(prime: 7), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.chordalCycle(prime: 7), "StableDirectedGraph<Int>")
    }

    @Test("NG-249 p = 11")
    func ng249() {
        // UndirectedAdjacencyList<Int>.chordalCycle(prime: 11) → n 11; m 13; deg [2, 2, 3, 2, 2, 3, 3, 2, 2, 3, 2]; E [0–1, 0–10, 1–2, 2–3, 2–6, 3–4, 4–5, 5–6, 5–9, 6–7, 7–8, 8–9, 9–10]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 11 && graph.edgeCount == 13 && graph.edges.count == 13, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 11), "\(type)")
            #expect((0 ..< 11).map { graph.vertexIndex(of: $0) } == Array(0 ..< 11), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 10], [1, 2], [2, 3], [2, 6], [3, 4], [4, 5], [5, 6], [5, 9], [6, 7], [7, 8], [8, 9], [9, 10]] as [[Int]], "\(type)")
            #expect((0 ..< 11).map { graph.degree(of: $0) } == [2, 2, 3, 2, 2, 3, 3, 2, 2, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 11).map { graph.neighbors(of: $0).sorted() } == [[1, 10], [0, 2], [1, 3, 6], [2, 4], [3, 5], [4, 6, 9], [2, 5, 7], [6, 8], [7, 9], [5, 8, 10], [0, 9]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 11).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.chordalCycle(prime: 11), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.chordalCycle(prime: 11), "Pseudograph<Int>")
        check(Multigraph<Int>.chordalCycle(prime: 11), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 11 && graph.edgeCount == 26 && graph.edges.count == 26, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 11), "\(type)")
            #expect((0 ..< 11).map { graph.vertexIndex(of: $0) } == Array(0 ..< 11), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 11)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 10], [1, 0], [1, 2], [2, 1], [2, 3], [2, 6], [3, 2], [3, 4], [4, 3], [4, 5], [5, 4], [5, 6], [5, 9], [6, 2], [6, 5], [6, 7], [7, 6], [7, 8], [8, 7], [8, 9], [9, 5], [9, 8], [9, 10], [10, 0], [10, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 11).map { graph.outDegree(of: $0) } == [2, 2, 3, 2, 2, 3, 3, 2, 2, 3, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 3, 2, 2, 3, 3, 2, 2, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 11).map { graph.successors(of: $0).sorted() } == [[1, 10], [0, 2], [1, 3, 6], [2, 4], [3, 5], [4, 6, 9], [2, 5, 7], [6, 8], [7, 9], [5, 8, 10], [0, 9]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 11).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.chordalCycle(prime: 11), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.chordalCycle(prime: 11), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.chordalCycle(prime: 11), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.chordalCycle(prime: 11), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.chordalCycle(prime: 11), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.chordalCycle(prime: 11), "StableDirectedGraph<Int>")
    }

    @Test("NG-250 directed: both arcs")
    func ng250() {
        // CompressedSparseRow.chordalCycle(prime: 7) → n 7; m 18; out [2, 2, 3, 3, 3, 3, 2]; in [2, 2, 3, 3, 3, 3, 2]; E [0→1, 0→6, 1→0, 1→2, 2→1, 2→3, 2→4, 3→2, 3→4, 3→5, 4→2, 4→3, 4→5, 5→3, 5→4, 5→6, 6→0, 6→5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 6], [1, 2], [2, 3], [2, 4], [3, 4], [3, 5], [4, 5], [5, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [2, 2, 3, 3, 3, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.neighbors(of: $0).sorted() } == [[1, 6], [0, 2], [1, 3, 4], [2, 4, 5], [2, 3, 5], [3, 4, 6], [0, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.chordalCycle(prime: 7), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.chordalCycle(prime: 7), "Pseudograph<Int>")
        check(Multigraph<Int>.chordalCycle(prime: 7), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 6], [1, 0], [1, 2], [2, 1], [2, 3], [2, 4], [3, 2], [3, 4], [3, 5], [4, 2], [4, 3], [4, 5], [5, 3], [5, 4], [5, 6], [6, 0], [6, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [2, 2, 3, 3, 3, 3, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 3, 3, 3, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.successors(of: $0).sorted() } == [[1, 6], [0, 2], [1, 3, 4], [2, 4, 5], [2, 3, 5], [3, 4, 6], [0, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.chordalCycle(prime: 7), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.chordalCycle(prime: 7), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.chordalCycle(prime: 7), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.chordalCycle(prime: 7), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.chordalCycle(prime: 7), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.chordalCycle(prime: 7), "StableDirectedGraph<Int>")
    }

    @Test("NG-251 p = 101")
    func ng251() {
        // UndirectedAdjacencyList<Int>.chordalCycle(prime: 101) → n 101; m 148; deg 2…3
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 101 && graph.edgeCount == 148 && graph.edges.count == 148, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 101), "\(type)")
            #expect((0 ..< 101).map { graph.vertexIndex(of: $0) } == Array(0 ..< 101), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 100], [1, 2], [2, 3], [2, 51], [3, 4], [3, 34], [4, 5], [4, 76], [5, 6], [5, 81], [6, 7], [6, 17], [7, 8], [7, 29], [8, 9], [8, 38], [9, 10], [9, 45], [10, 11], [10, 91], [11, 12], [11, 46], [12, 13], [12, 59], [13, 14], [13, 70], [14, 15], [14, 65], [15, 16], [15, 27], [16, 17], [16, 19], [17, 18], [18, 19], [18, 73], [19, 20], [20, 21], [20, 96], [21, 22], [21, 77], [22, 23], [23, 24], [24, 25], [24, 80], [25, 26], [25, 97], [26, 27], [26, 35], [27, 28], [28, 29], [28, 83], [29, 30], [30, 31], [30, 64], [31, 32], [31, 88], [32, 33], [32, 60], [33, 34], [33, 49], [34, 35], [35, 36], [36, 37], [36, 87], [37, 38], [37, 71], [38, 39], [39, 40], [39, 57], [40, 41], [40, 48], [41, 42], [41, 69], [42, 43], [42, 89], [43, 44], [43, 47], [44, 45], [44, 62], [45, 46], [46, 47], [47, 48], [48, 49], [49, 50], [50, 51], [50, 99], [51, 52], [52, 53], [52, 68], [53, 54], [53, 61], [54, 55], [54, 58], [55, 56], [55, 90], [56, 57], [56, 92], [57, 58], [58, 59], [59, 60], [60, 61], [61, 62], [62, 63], [63, 64], [63, 93], [64, 65], [65, 66], [66, 67], [66, 75], [67, 68], [67, 98], [68, 69], [69, 70], [70, 71], [71, 72], [72, 73], [72, 94], [73, 74], [74, 75], [74, 86], [75, 76], [76, 77], [77, 78], [78, 79], [79, 80], [80, 81], [81, 82], [82, 83], [82, 85], [83, 84], [84, 85], [84, 95], [85, 86], [86, 87], [87, 88], [88, 89], [89, 90], [90, 91], [91, 92], [92, 93], [93, 94], [94, 95], [95, 96], [96, 97], [97, 98], [98, 99], [99, 100]] as [[Int]], "\(type)")
            #expect((0 ..< 101).map { graph.degree(of: $0) } == [2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 101).map { graph.neighbors(of: $0).sorted() } == [[1, 100], [0, 2], [1, 3, 51], [2, 4, 34], [3, 5, 76], [4, 6, 81], [5, 7, 17], [6, 8, 29], [7, 9, 38], [8, 10, 45], [9, 11, 91], [10, 12, 46], [11, 13, 59], [12, 14, 70], [13, 15, 65], [14, 16, 27], [15, 17, 19], [6, 16, 18], [17, 19, 73], [16, 18, 20], [19, 21, 96], [20, 22, 77], [21, 23], [22, 24], [23, 25, 80], [24, 26, 97], [25, 27, 35], [15, 26, 28], [27, 29, 83], [7, 28, 30], [29, 31, 64], [30, 32, 88], [31, 33, 60], [32, 34, 49], [3, 33, 35], [26, 34, 36], [35, 37, 87], [36, 38, 71], [8, 37, 39], [38, 40, 57], [39, 41, 48], [40, 42, 69], [41, 43, 89], [42, 44, 47], [43, 45, 62], [9, 44, 46], [11, 45, 47], [43, 46, 48], [40, 47, 49], [33, 48, 50], [49, 51, 99], [2, 50, 52], [51, 53, 68], [52, 54, 61], [53, 55, 58], [54, 56, 90], [55, 57, 92], [39, 56, 58], [54, 57, 59], [12, 58, 60], [32, 59, 61], [53, 60, 62], [44, 61, 63], [62, 64, 93], [30, 63, 65], [14, 64, 66], [65, 67, 75], [66, 68, 98], [52, 67, 69], [41, 68, 70], [13, 69, 71], [37, 70, 72], [71, 73, 94], [18, 72, 74], [73, 75, 86], [66, 74, 76], [4, 75, 77], [21, 76, 78], [77, 79], [78, 80], [24, 79, 81], [5, 80, 82], [81, 83, 85], [28, 82, 84], [83, 85, 95], [82, 84, 86], [74, 85, 87], [36, 86, 88], [31, 87, 89], [42, 88, 90], [55, 89, 91], [10, 90, 92], [56, 91, 93], [63, 92, 94], [72, 93, 95], [84, 94, 96], [20, 95, 97], [25, 96, 98], [67, 97, 99], [50, 98, 100], [0, 99]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.chordalCycle(prime: 101), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.chordalCycle(prime: 101), "Pseudograph<Int>")
        check(Multigraph<Int>.chordalCycle(prime: 101), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 101 && graph.edgeCount == 296 && graph.edges.count == 296, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 101), "\(type)")
            #expect((0 ..< 101).map { graph.vertexIndex(of: $0) } == Array(0 ..< 101), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 101)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            // Row-major, no repeats, no self-loops, and each arc by the family's rule.
            let ends = graph.edges.map { [$0.source, $0.target] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.source != e.target && e.source < 101 && e.target < 101 }, "\(type)")
            #expect((0 ..< 101).allSatisfy { (2 ... 3).contains(graph.outDegree(of: $0)) && inDegrees[$0] == graph.outDegree(of: $0) }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.chordalCycle(prime: 101), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.chordalCycle(prime: 101), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.chordalCycle(prime: 101), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.chordalCycle(prime: 101), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.chordalCycle(prime: 101), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.chordalCycle(prime: 101), "StableDirectedGraph<Int>")
    }

    @Test("NG-254 p = 5: C5")
    func ng254() {
        // UndirectedAdjacencyList<Int>.paley(prime: 5) → n 5; m 5; deg [2, 2, 2, 2, 2]; E [0–1, 0–4, 1–2, 2–3, 3–4]
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
        check(UndirectedAdjacencyList<Int>.paley(prime: 5), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.paley(prime: 5), "Pseudograph<Int>")
        check(Multigraph<Int>.paley(prime: 5), "Multigraph<Int>")
        // The directed form: x → y when y − x is a nonzero square mod p; a tournament for p ≡ 3 (mod 4).
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
        checkDirected(CompressedSparseRow.paley(prime: 5), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.paley(prime: 5), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.paley(prime: 5), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.paley(prime: 5), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.paley(prime: 5), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.paley(prime: 5), "StableDirectedGraph<Int>")
    }

    @Test("NG-255 p = 13: 6-regular")
    func ng255() {
        // UndirectedAdjacencyList<Int>.paley(prime: 13) → n 13; m 39; deg [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]; E [0–1, 0–3, 0–4, 0–9, 0–10, 0–12, 1–2, 1–4, 1–5, 1–10, 1–11, 2–3, 2–5, 2–6, 2–11, 2–12, 3–4, 3–6, 3–7, 3–12, 4–5, 4–7, 4–8, 5–6, 5–8, 5–9, 6–7, 6–9, 6–10, 7–8, 7–10, 7–11, 8–9, 8–11, 8–12, 9–10, 9–12, 10–11, 11–12]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 13 && graph.edgeCount == 39 && graph.edges.count == 39, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 13), "\(type)")
            #expect((0 ..< 13).map { graph.vertexIndex(of: $0) } == Array(0 ..< 13), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [0, 4], [0, 9], [0, 10], [0, 12], [1, 2], [1, 4], [1, 5], [1, 10], [1, 11], [2, 3], [2, 5], [2, 6], [2, 11], [2, 12], [3, 4], [3, 6], [3, 7], [3, 12], [4, 5], [4, 7], [4, 8], [5, 6], [5, 8], [5, 9], [6, 7], [6, 9], [6, 10], [7, 8], [7, 10], [7, 11], [8, 9], [8, 11], [8, 12], [9, 10], [9, 12], [10, 11], [11, 12]] as [[Int]], "\(type)")
            #expect((0 ..< 13).map { graph.degree(of: $0) } == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect((0 ..< 13).map { graph.neighbors(of: $0).sorted() } == [[1, 3, 4, 9, 10, 12], [0, 2, 4, 5, 10, 11], [1, 3, 5, 6, 11, 12], [0, 2, 4, 6, 7, 12], [0, 1, 3, 5, 7, 8], [1, 2, 4, 6, 8, 9], [2, 3, 5, 7, 9, 10], [3, 4, 6, 8, 10, 11], [4, 5, 7, 9, 11, 12], [0, 5, 6, 8, 10, 12], [0, 1, 6, 7, 9, 11], [1, 2, 7, 8, 10, 12], [0, 2, 3, 8, 9, 11]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 13).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.paley(prime: 13), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.paley(prime: 13), "Pseudograph<Int>")
        check(Multigraph<Int>.paley(prime: 13), "Multigraph<Int>")
        // The directed form: x → y when y − x is a nonzero square mod p; a tournament for p ≡ 3 (mod 4).
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 13 && graph.edgeCount == 78 && graph.edges.count == 78, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 13), "\(type)")
            #expect((0 ..< 13).map { graph.vertexIndex(of: $0) } == Array(0 ..< 13), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 13)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [0, 4], [0, 9], [0, 10], [0, 12], [1, 0], [1, 2], [1, 4], [1, 5], [1, 10], [1, 11], [2, 1], [2, 3], [2, 5], [2, 6], [2, 11], [2, 12], [3, 0], [3, 2], [3, 4], [3, 6], [3, 7], [3, 12], [4, 0], [4, 1], [4, 3], [4, 5], [4, 7], [4, 8], [5, 1], [5, 2], [5, 4], [5, 6], [5, 8], [5, 9], [6, 2], [6, 3], [6, 5], [6, 7], [6, 9], [6, 10], [7, 3], [7, 4], [7, 6], [7, 8], [7, 10], [7, 11], [8, 4], [8, 5], [8, 7], [8, 9], [8, 11], [8, 12], [9, 0], [9, 5], [9, 6], [9, 8], [9, 10], [9, 12], [10, 0], [10, 1], [10, 6], [10, 7], [10, 9], [10, 11], [11, 1], [11, 2], [11, 7], [11, 8], [11, 10], [11, 12], [12, 0], [12, 2], [12, 3], [12, 8], [12, 9], [12, 11]] as [[Int]], "\(type)")
            #expect((0 ..< 13).map { graph.outDegree(of: $0) } == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect(inDegrees == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect((0 ..< 13).map { graph.successors(of: $0).sorted() } == [[1, 3, 4, 9, 10, 12], [0, 2, 4, 5, 10, 11], [1, 3, 5, 6, 11, 12], [0, 2, 4, 6, 7, 12], [0, 1, 3, 5, 7, 8], [1, 2, 4, 6, 8, 9], [2, 3, 5, 7, 9, 10], [3, 4, 6, 8, 10, 11], [4, 5, 7, 9, 11, 12], [0, 5, 6, 8, 10, 12], [0, 1, 6, 7, 9, 11], [1, 2, 7, 8, 10, 12], [0, 2, 3, 8, 9, 11]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 13).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.paley(prime: 13), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.paley(prime: 13), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.paley(prime: 13), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.paley(prime: 13), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.paley(prime: 13), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.paley(prime: 13), "StableDirectedGraph<Int>")
    }

    @Test("NG-256 p = 17")
    func ng256() {
        // UndirectedAdjacencyList<Int>.paley(prime: 17) → n 17; m 68; deg 8…8
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 17 && graph.edgeCount == 68 && graph.edges.count == 68, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 17), "\(type)")
            #expect((0 ..< 17).map { graph.vertexIndex(of: $0) } == Array(0 ..< 17), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [0, 8], [0, 9], [0, 13], [0, 15], [0, 16], [1, 2], [1, 3], [1, 5], [1, 9], [1, 10], [1, 14], [1, 16], [2, 3], [2, 4], [2, 6], [2, 10], [2, 11], [2, 15], [3, 4], [3, 5], [3, 7], [3, 11], [3, 12], [3, 16], [4, 5], [4, 6], [4, 8], [4, 12], [4, 13], [5, 6], [5, 7], [5, 9], [5, 13], [5, 14], [6, 7], [6, 8], [6, 10], [6, 14], [6, 15], [7, 8], [7, 9], [7, 11], [7, 15], [7, 16], [8, 9], [8, 10], [8, 12], [8, 16], [9, 10], [9, 11], [9, 13], [10, 11], [10, 12], [10, 14], [11, 12], [11, 13], [11, 15], [12, 13], [12, 14], [12, 16], [13, 14], [13, 15], [14, 15], [14, 16], [15, 16]] as [[Int]], "\(type)")
            #expect((0 ..< 17).map { graph.degree(of: $0) } == [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8] as [Int], "\(type)")
            #expect((0 ..< 17).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 4, 8, 9, 13, 15, 16], [0, 2, 3, 5, 9, 10, 14, 16], [0, 1, 3, 4, 6, 10, 11, 15], [1, 2, 4, 5, 7, 11, 12, 16], [0, 2, 3, 5, 6, 8, 12, 13], [1, 3, 4, 6, 7, 9, 13, 14], [2, 4, 5, 7, 8, 10, 14, 15], [3, 5, 6, 8, 9, 11, 15, 16], [0, 4, 6, 7, 9, 10, 12, 16], [0, 1, 5, 7, 8, 10, 11, 13], [1, 2, 6, 8, 9, 11, 12, 14], [2, 3, 7, 9, 10, 12, 13, 15], [3, 4, 8, 10, 11, 13, 14, 16], [0, 4, 5, 9, 11, 12, 14, 15], [1, 5, 6, 10, 12, 13, 15, 16], [0, 2, 6, 7, 11, 13, 14, 16], [0, 1, 3, 7, 8, 12, 14, 15]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 17).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.paley(prime: 17), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.paley(prime: 17), "Pseudograph<Int>")
        check(Multigraph<Int>.paley(prime: 17), "Multigraph<Int>")
        // The directed form: x → y when y − x is a nonzero square mod p; a tournament for p ≡ 3 (mod 4).
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 17 && graph.edgeCount == 136 && graph.edges.count == 136, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 17), "\(type)")
            #expect((0 ..< 17).map { graph.vertexIndex(of: $0) } == Array(0 ..< 17), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 17)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 4], [0, 8], [0, 9], [0, 13], [0, 15], [0, 16], [1, 0], [1, 2], [1, 3], [1, 5], [1, 9], [1, 10], [1, 14], [1, 16], [2, 0], [2, 1], [2, 3], [2, 4], [2, 6], [2, 10], [2, 11], [2, 15], [3, 1], [3, 2], [3, 4], [3, 5], [3, 7], [3, 11], [3, 12], [3, 16], [4, 0], [4, 2], [4, 3], [4, 5], [4, 6], [4, 8], [4, 12], [4, 13], [5, 1], [5, 3], [5, 4], [5, 6], [5, 7], [5, 9], [5, 13], [5, 14], [6, 2], [6, 4], [6, 5], [6, 7], [6, 8], [6, 10], [6, 14], [6, 15], [7, 3], [7, 5], [7, 6], [7, 8], [7, 9], [7, 11], [7, 15], [7, 16], [8, 0], [8, 4], [8, 6], [8, 7], [8, 9], [8, 10], [8, 12], [8, 16], [9, 0], [9, 1], [9, 5], [9, 7], [9, 8], [9, 10], [9, 11], [9, 13], [10, 1], [10, 2], [10, 6], [10, 8], [10, 9], [10, 11], [10, 12], [10, 14], [11, 2], [11, 3], [11, 7], [11, 9], [11, 10], [11, 12], [11, 13], [11, 15], [12, 3], [12, 4], [12, 8], [12, 10], [12, 11], [12, 13], [12, 14], [12, 16], [13, 0], [13, 4], [13, 5], [13, 9], [13, 11], [13, 12], [13, 14], [13, 15], [14, 1], [14, 5], [14, 6], [14, 10], [14, 12], [14, 13], [14, 15], [14, 16], [15, 0], [15, 2], [15, 6], [15, 7], [15, 11], [15, 13], [15, 14], [15, 16], [16, 0], [16, 1], [16, 3], [16, 7], [16, 8], [16, 12], [16, 14], [16, 15]] as [[Int]], "\(type)")
            #expect((0 ..< 17).map { graph.outDegree(of: $0) } == [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8] as [Int], "\(type)")
            #expect(inDegrees == [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8] as [Int], "\(type)")
            #expect((0 ..< 17).map { graph.successors(of: $0).sorted() } == [[1, 2, 4, 8, 9, 13, 15, 16], [0, 2, 3, 5, 9, 10, 14, 16], [0, 1, 3, 4, 6, 10, 11, 15], [1, 2, 4, 5, 7, 11, 12, 16], [0, 2, 3, 5, 6, 8, 12, 13], [1, 3, 4, 6, 7, 9, 13, 14], [2, 4, 5, 7, 8, 10, 14, 15], [3, 5, 6, 8, 9, 11, 15, 16], [0, 4, 6, 7, 9, 10, 12, 16], [0, 1, 5, 7, 8, 10, 11, 13], [1, 2, 6, 8, 9, 11, 12, 14], [2, 3, 7, 9, 10, 12, 13, 15], [3, 4, 8, 10, 11, 13, 14, 16], [0, 4, 5, 9, 11, 12, 14, 15], [1, 5, 6, 10, 12, 13, 15, 16], [0, 2, 6, 7, 11, 13, 14, 16], [0, 1, 3, 7, 8, 12, 14, 15]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 17).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.paley(prime: 17), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.paley(prime: 17), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.paley(prime: 17), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.paley(prime: 17), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.paley(prime: 17), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.paley(prime: 17), "StableDirectedGraph<Int>")
    }

    @Test("NG-257 directed, p = 13: both arcs")
    func ng257() {
        // CompressedSparseRow.paley(prime: 13) → n 13; m 78; out [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]; in [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]; E [0→1, 0→3, 0→4, 0→9, 0→10, 0→12, 1→0, 1→2, 1→4, 1→5, 1→10, 1→11, 2→1, 2→3, 2→5, 2→6, 2→11, 2→12, 3→0, 3→2, 3→4, 3→6, 3→7, 3→12, 4→0, 4→1, 4→3, 4→5, 4→7, 4→8, 5→1, 5→2, 5→4, 5→6, 5→8, 5→9, 6→2, 6→3, 6→5, 6→7, 6→9, 6→10, 7→3, 7→4, 7→6, 7→8, 7→10, 7→11, 8→4, 8→5, 8→7, 8→9, 8→11, 8→12, 9→0, 9→5, 9→6, 9→8, 9→10, 9→12, 10→0, 10→1, 10→6, 10→7, 10→9, 10→11, 11→1, 11→2, 11→7, 11→8, 11→10, 11→12, 12→0, 12→2, 12→3, 12→8, 12→9, 12→11]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 13 && graph.edgeCount == 39 && graph.edges.count == 39, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 13), "\(type)")
            #expect((0 ..< 13).map { graph.vertexIndex(of: $0) } == Array(0 ..< 13), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [0, 4], [0, 9], [0, 10], [0, 12], [1, 2], [1, 4], [1, 5], [1, 10], [1, 11], [2, 3], [2, 5], [2, 6], [2, 11], [2, 12], [3, 4], [3, 6], [3, 7], [3, 12], [4, 5], [4, 7], [4, 8], [5, 6], [5, 8], [5, 9], [6, 7], [6, 9], [6, 10], [7, 8], [7, 10], [7, 11], [8, 9], [8, 11], [8, 12], [9, 10], [9, 12], [10, 11], [11, 12]] as [[Int]], "\(type)")
            #expect((0 ..< 13).map { graph.degree(of: $0) } == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect((0 ..< 13).map { graph.neighbors(of: $0).sorted() } == [[1, 3, 4, 9, 10, 12], [0, 2, 4, 5, 10, 11], [1, 3, 5, 6, 11, 12], [0, 2, 4, 6, 7, 12], [0, 1, 3, 5, 7, 8], [1, 2, 4, 6, 8, 9], [2, 3, 5, 7, 9, 10], [3, 4, 6, 8, 10, 11], [4, 5, 7, 9, 11, 12], [0, 5, 6, 8, 10, 12], [0, 1, 6, 7, 9, 11], [1, 2, 7, 8, 10, 12], [0, 2, 3, 8, 9, 11]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 13).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.paley(prime: 13), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.paley(prime: 13), "Pseudograph<Int>")
        check(Multigraph<Int>.paley(prime: 13), "Multigraph<Int>")
        // The directed form: x → y when y − x is a nonzero square mod p; a tournament for p ≡ 3 (mod 4).
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 13 && graph.edgeCount == 78 && graph.edges.count == 78, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 13), "\(type)")
            #expect((0 ..< 13).map { graph.vertexIndex(of: $0) } == Array(0 ..< 13), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 13)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [0, 4], [0, 9], [0, 10], [0, 12], [1, 0], [1, 2], [1, 4], [1, 5], [1, 10], [1, 11], [2, 1], [2, 3], [2, 5], [2, 6], [2, 11], [2, 12], [3, 0], [3, 2], [3, 4], [3, 6], [3, 7], [3, 12], [4, 0], [4, 1], [4, 3], [4, 5], [4, 7], [4, 8], [5, 1], [5, 2], [5, 4], [5, 6], [5, 8], [5, 9], [6, 2], [6, 3], [6, 5], [6, 7], [6, 9], [6, 10], [7, 3], [7, 4], [7, 6], [7, 8], [7, 10], [7, 11], [8, 4], [8, 5], [8, 7], [8, 9], [8, 11], [8, 12], [9, 0], [9, 5], [9, 6], [9, 8], [9, 10], [9, 12], [10, 0], [10, 1], [10, 6], [10, 7], [10, 9], [10, 11], [11, 1], [11, 2], [11, 7], [11, 8], [11, 10], [11, 12], [12, 0], [12, 2], [12, 3], [12, 8], [12, 9], [12, 11]] as [[Int]], "\(type)")
            #expect((0 ..< 13).map { graph.outDegree(of: $0) } == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect(inDegrees == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect((0 ..< 13).map { graph.successors(of: $0).sorted() } == [[1, 3, 4, 9, 10, 12], [0, 2, 4, 5, 10, 11], [1, 3, 5, 6, 11, 12], [0, 2, 4, 6, 7, 12], [0, 1, 3, 5, 7, 8], [1, 2, 4, 6, 8, 9], [2, 3, 5, 7, 9, 10], [3, 4, 6, 8, 10, 11], [4, 5, 7, 9, 11, 12], [0, 5, 6, 8, 10, 12], [0, 1, 6, 7, 9, 11], [1, 2, 7, 8, 10, 12], [0, 2, 3, 8, 9, 11]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 13).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.paley(prime: 13), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.paley(prime: 13), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.paley(prime: 13), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.paley(prime: 13), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.paley(prime: 13), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.paley(prime: 13), "StableDirectedGraph<Int>")
    }

    @Test("NG-258 directed, p = 3: the Paley tournament, one arc per pair")
    func ng258() {
        // CompressedSparseRow.paley(prime: 3) → n 3; m 3; out [1, 1, 1]; in [1, 1, 1]; E [0→1, 1→2, 2→0]
        // The directed form: x → y when y − x is a nonzero square mod p; a tournament for p ≡ 3 (mod 4).
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect((0 ..< 3).map { graph.vertexIndex(of: $0) } == Array(0 ..< 3), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [1, 1, 1] as [Int], "\(type)")
            #expect(inDegrees == [1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 3).map { graph.successors(of: $0).sorted() } == [[1], [2], [0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 3).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.paley(prime: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.paley(prime: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.paley(prime: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.paley(prime: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.paley(prime: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.paley(prime: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-259 directed, p = 7: the Paley tournament")
    func ng259() {
        // CompressedSparseRow.paley(prime: 7) → n 7; m 21; out [3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3]; E [0→1, 0→2, 0→4, 1→2, 1→3, 1→5, 2→3, 2→4, 2→6, 3→0, 3→4, 3→5, 4→1, 4→5, 4→6, 5→0, 5→2, 5→6, 6→0, 6→1, 6→3]
        // The directed form: x → y when y − x is a nonzero square mod p; a tournament for p ≡ 3 (mod 4).
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 21 && graph.edges.count == 21, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 4], [1, 2], [1, 3], [1, 5], [2, 3], [2, 4], [2, 6], [3, 0], [3, 4], [3, 5], [4, 1], [4, 5], [4, 6], [5, 0], [5, 2], [5, 6], [6, 0], [6, 1], [6, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.successors(of: $0).sorted() } == [[1, 2, 4], [2, 3, 5], [3, 4, 6], [0, 4, 5], [1, 5, 6], [0, 2, 6], [0, 1, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.paley(prime: 7), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.paley(prime: 7), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.paley(prime: 7), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.paley(prime: 7), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.paley(prime: 7), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.paley(prime: 7), "StableDirectedGraph<Int>")
    }

    @Test("NG-260 directed, p = 2: both arcs of K2")
    func ng260() {
        // CompressedSparseRow.paley(prime: 2) → n 2; m 2; out [1, 1]; in [1, 1]; E [0→1, 1→0]
        // The directed form: x → y when y − x is a nonzero square mod p; a tournament for p ≡ 3 (mod 4).
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
        checkDirected(CompressedSparseRow.paley(prime: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.paley(prime: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.paley(prime: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.paley(prime: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.paley(prime: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.paley(prime: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-261 p = 101")
    func ng261() {
        // UndirectedAdjacencyList<Int>.paley(prime: 101) → n 101; m 2525; deg 50…50
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 101 && graph.edgeCount == 2525 && graph.edges.count == 2525, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 101), "\(type)")
            #expect((0 ..< 101).map { graph.vertexIndex(of: $0) } == Array(0 ..< 101), "\(type)")
            // Sorted, u < v, no repeats, and each edge by the family's rule.
            let ends = graph.edges.map { [$0.u, $0.v] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.u < e.v && e.v < 101 }, "\(type)")
            #expect((0 ..< 101).allSatisfy { graph.degree(of: $0) == 50 }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.paley(prime: 101), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.paley(prime: 101), "Pseudograph<Int>")
        check(Multigraph<Int>.paley(prime: 101), "Multigraph<Int>")
        // The directed form: x → y when y − x is a nonzero square mod p; a tournament for p ≡ 3 (mod 4).
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 101 && graph.edgeCount == 5050 && graph.edges.count == 5050, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 101), "\(type)")
            #expect((0 ..< 101).map { graph.vertexIndex(of: $0) } == Array(0 ..< 101), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 101)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            // Row-major, no repeats, no self-loops, and each arc by the family's rule.
            let ends = graph.edges.map { [$0.source, $0.target] }
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(type)")
            #expect(graph.edges.allSatisfy { e in e.source != e.target && e.source < 101 && e.target < 101 }, "\(type)")
            #expect((0 ..< 101).allSatisfy { graph.outDegree(of: $0) == 50 } && inDegrees.allSatisfy { $0 == 50 }, "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.paley(prime: 101), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.paley(prime: 101), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.paley(prime: 101), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.paley(prime: 101), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.paley(prime: 101), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.paley(prime: 101), "StableDirectedGraph<Int>")
    }
}
