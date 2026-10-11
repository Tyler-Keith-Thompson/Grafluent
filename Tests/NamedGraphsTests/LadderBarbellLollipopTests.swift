// Ladders, circular ladders, barbells and lollipops (catalog NG-091 – NG-109), numbered as NetworkX
// numbers them: rails 0..<n and n..<2n with rungs i – (i + n); cliques joined by a path. Both arcs
// when directed.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing

@Suite("NamedGraphs ladders, barbells and lollipops")
struct LadderBarbellLollipopTests {
    @Test("NG-091 L0 is the null graph")
    func ng091() {
        // UndirectedAdjacencyList<Int>.ladder(rungCount: 0) → n 0; m 0; deg []; E []
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
        check(UndirectedAdjacencyList<Int>.ladder(rungCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.ladder(rungCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.ladder(rungCount: 0), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.ladder(rungCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.ladder(rungCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.ladder(rungCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.ladder(rungCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.ladder(rungCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.ladder(rungCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-092 L1 is K2")
    func ng092() {
        // UndirectedAdjacencyList<Int>.ladder(rungCount: 1) → n 2; m 1; deg [1, 1]; E [0–1]
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
        check(UndirectedAdjacencyList<Int>.ladder(rungCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.ladder(rungCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.ladder(rungCount: 1), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.ladder(rungCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.ladder(rungCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.ladder(rungCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.ladder(rungCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.ladder(rungCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.ladder(rungCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-093 L4: rails 0..<4 and 4..<8, rungs i–i+4")
    func ng093() {
        // UndirectedAdjacencyList<Int>.ladder(rungCount: 4) → n 8; m 10; deg [2, 3, 3, 2, 2, 3, 3, 2]; E [0–1, 0–4, 1–2, 1–5, 2–3, 2–6, 3–7, 4–5, 5–6, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 4], [1, 2], [1, 5], [2, 3], [2, 6], [3, 7], [4, 5], [5, 6], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [2, 3, 3, 2, 2, 3, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 4], [0, 2, 5], [1, 3, 6], [2, 7], [0, 5], [1, 4, 6], [2, 5, 7], [3, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.ladder(rungCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.ladder(rungCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.ladder(rungCount: 4), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 20 && graph.edges.count == 20, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 4], [1, 0], [1, 2], [1, 5], [2, 1], [2, 3], [2, 6], [3, 2], [3, 7], [4, 0], [4, 5], [5, 1], [5, 4], [5, 6], [6, 2], [6, 5], [6, 7], [7, 3], [7, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [2, 3, 3, 2, 2, 3, 3, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 3, 3, 2, 2, 3, 3, 2] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 4], [0, 2, 5], [1, 3, 6], [2, 7], [0, 5], [1, 4, 6], [2, 5, 7], [3, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.ladder(rungCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.ladder(rungCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.ladder(rungCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.ladder(rungCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.ladder(rungCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.ladder(rungCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-094 L3 directed: both arcs")
    func ng094() {
        // CompressedSparseRow.ladder(rungCount: 3) → n 6; m 14; out [2, 3, 2, 2, 3, 2]; in [2, 3, 2, 2, 3, 2]; E [0→1, 0→3, 1→0, 1→2, 1→4, 2→1, 2→5, 3→0, 3→4, 4→1, 4→3, 4→5, 5→2, 5→4]
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
        check(UndirectedAdjacencyList<Int>.ladder(rungCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.ladder(rungCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.ladder(rungCount: 3), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.ladder(rungCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.ladder(rungCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.ladder(rungCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.ladder(rungCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.ladder(rungCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.ladder(rungCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-096 CL3: each rail closed by its first and last vertex")
    func ng096() {
        // UndirectedAdjacencyList<Int>.circularLadder(rungCount: 3) → n 6; m 9; deg [3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–4, 2–5, 3–4, 3–5, 4–5]
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
        check(UndirectedAdjacencyList<Int>.circularLadder(rungCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.circularLadder(rungCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.circularLadder(rungCount: 3), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.circularLadder(rungCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.circularLadder(rungCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.circularLadder(rungCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.circularLadder(rungCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.circularLadder(rungCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.circularLadder(rungCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-097 CL4: each rail closed by its first and last vertex")
    func ng097() {
        // UndirectedAdjacencyList<Int>.circularLadder(rungCount: 4) → n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–3, 0–4, 1–2, 1–5, 2–3, 2–6, 3–7, 4–5, 4–7, 5–6, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [0, 4], [1, 2], [1, 5], [2, 3], [2, 6], [3, 7], [4, 5], [4, 7], [5, 6], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 3, 4], [0, 2, 5], [1, 3, 6], [0, 2, 7], [0, 5, 7], [1, 4, 6], [2, 5, 7], [3, 4, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.circularLadder(rungCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.circularLadder(rungCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.circularLadder(rungCount: 4), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [0, 4], [1, 0], [1, 2], [1, 5], [2, 1], [2, 3], [2, 6], [3, 0], [3, 2], [3, 7], [4, 0], [4, 5], [4, 7], [5, 1], [5, 4], [5, 6], [6, 2], [6, 5], [6, 7], [7, 3], [7, 4], [7, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 3, 4], [0, 2, 5], [1, 3, 6], [0, 2, 7], [0, 5, 7], [1, 4, 6], [2, 5, 7], [3, 4, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.circularLadder(rungCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.circularLadder(rungCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.circularLadder(rungCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.circularLadder(rungCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.circularLadder(rungCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.circularLadder(rungCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-098 CL3 directed: both arcs")
    func ng098() {
        // CompressedSparseRow.circularLadder(rungCount: 3) → n 6; m 18; out [3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3]; E [0→1, 0→2, 0→3, 1→0, 1→2, 1→4, 2→0, 2→1, 2→5, 3→0, 3→4, 3→5, 4→1, 4→3, 4→5, 5→2, 5→3, 5→4]
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
        check(UndirectedAdjacencyList<Int>.circularLadder(rungCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.circularLadder(rungCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.circularLadder(rungCount: 3), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.circularLadder(rungCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.circularLadder(rungCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.circularLadder(rungCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.circularLadder(rungCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.circularLadder(rungCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.circularLadder(rungCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-100 two K2 joined by a path of 0")
    func ng100() {
        // UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 0) → n 4; m 3; deg [1, 2, 2, 1]; E [0–1, 1–2, 2–3]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [1, 2, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[1], [0, 2], [1, 3], [2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 0), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [1, 2], [2, 1], [2, 3], [3, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [1, 2, 2, 1] as [Int], "\(type)")
            #expect(inDegrees == [1, 2, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1], [0, 2], [1, 3], [2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.barbell(cliqueVertexCount: 2, pathVertexCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.barbell(cliqueVertexCount: 2, pathVertexCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-101 two K3 joined by a path of 2")
    func ng101() {
        // UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 2) → n 8; m 9; deg [2, 2, 3, 2, 2, 3, 2, 2]; E [0–1, 0–2, 1–2, 2–3, 3–4, 4–5, 5–6, 5–7, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [5, 7], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [2, 2, 3, 2, 2, 3, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 2], [0, 1, 3], [2, 4], [3, 5], [4, 6, 7], [5, 7], [5, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1], [2, 3], [3, 2], [3, 4], [4, 3], [4, 5], [5, 4], [5, 6], [5, 7], [6, 5], [6, 7], [7, 5], [7, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [2, 2, 3, 2, 2, 3, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 3, 2, 2, 3, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 2], [0, 2], [0, 1, 3], [2, 4], [3, 5], [4, 6, 7], [5, 7], [5, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.barbell(cliqueVertexCount: 3, pathVertexCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.barbell(cliqueVertexCount: 3, pathVertexCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-102 two K4 joined by a path of 0")
    func ng102() {
        // UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 4, pathVertexCount: 0) → n 8; m 13; deg [3, 3, 3, 4, 4, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 3–4, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 13 && graph.edges.count == 13, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3], [3, 4], [4, 5], [4, 6], [4, 7], [5, 6], [5, 7], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 3, 3, 4, 4, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2, 4], [3, 5, 6, 7], [4, 6, 7], [4, 5, 7], [4, 5, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 4)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 4, pathVertexCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.barbell(cliqueVertexCount: 4, pathVertexCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.barbell(cliqueVertexCount: 4, pathVertexCount: 0), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 26 && graph.edges.count == 26, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 0], [1, 2], [1, 3], [2, 0], [2, 1], [2, 3], [3, 0], [3, 1], [3, 2], [3, 4], [4, 3], [4, 5], [4, 6], [4, 7], [5, 4], [5, 6], [5, 7], [6, 4], [6, 5], [6, 7], [7, 4], [7, 5], [7, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [3, 3, 3, 4, 4, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 4, 4, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2, 4], [3, 5, 6, 7], [4, 6, 7], [4, 5, 7], [4, 5, 6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 4)), "\(type)")
        }
        checkDirected(CompressedSparseRow.barbell(cliqueVertexCount: 4, pathVertexCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.barbell(cliqueVertexCount: 4, pathVertexCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.barbell(cliqueVertexCount: 4, pathVertexCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.barbell(cliqueVertexCount: 4, pathVertexCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.barbell(cliqueVertexCount: 4, pathVertexCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.barbell(cliqueVertexCount: 4, pathVertexCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-103 directed: both arcs")
    func ng103() {
        // CompressedSparseRow.barbell(cliqueVertexCount: 3, pathVertexCount: 1) → n 7; m 16; out [2, 2, 3, 2, 3, 2, 2]; in [2, 2, 3, 2, 3, 2, 2]; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1, 2→3, 3→2, 3→4, 4→3, 4→5, 4→6, 5→4, 5→6, 6→4, 6→5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [2, 3], [3, 4], [4, 5], [4, 6], [5, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [2, 2, 3, 2, 3, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 2], [0, 1, 3], [2, 4], [3, 5, 6], [4, 6], [4, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 1), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1], [2, 3], [3, 2], [3, 4], [4, 3], [4, 5], [4, 6], [5, 4], [5, 6], [6, 4], [6, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [2, 2, 3, 2, 3, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 3, 2, 3, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.successors(of: $0).sorted() } == [[1, 2], [0, 2], [0, 1, 3], [2, 4], [3, 5, 6], [4, 6], [4, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.barbell(cliqueVertexCount: 3, pathVertexCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.barbell(cliqueVertexCount: 3, pathVertexCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-106 K2 with a path of 0 at 1")
    func ng106() {
        // UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 0) → n 2; m 1; deg [1, 1]; E [0–1]
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
        check(UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 0), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.lollipop(cliqueVertexCount: 2, pathVertexCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.lollipop(cliqueVertexCount: 2, pathVertexCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-107 K3 with a path of 2 at 2")
    func ng107() {
        // UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2) → n 5; m 5; deg [2, 2, 3, 2, 1]; E [0–1, 0–2, 1–2, 2–3, 3–4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [2, 3], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [2, 2, 3, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 2], [0, 1, 3], [2, 4], [3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1], [2, 3], [3, 2], [3, 4], [4, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [2, 2, 3, 2, 1] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 3, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 2], [0, 2], [0, 1, 3], [2, 4], [3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-108 K4 with a path of 1 at 3")
    func ng108() {
        // UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 4, pathVertexCount: 1) → n 5; m 7; deg [3, 3, 3, 4, 1]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 3–4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [3, 3, 3, 4, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2, 4], [3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 4)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 4, pathVertexCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.lollipop(cliqueVertexCount: 4, pathVertexCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.lollipop(cliqueVertexCount: 4, pathVertexCount: 1), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 0], [1, 2], [1, 3], [2, 0], [2, 1], [2, 3], [3, 0], [3, 1], [3, 2], [3, 4], [4, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [3, 3, 3, 4, 1] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 4, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2, 4], [3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 4)), "\(type)")
        }
        checkDirected(CompressedSparseRow.lollipop(cliqueVertexCount: 4, pathVertexCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.lollipop(cliqueVertexCount: 4, pathVertexCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.lollipop(cliqueVertexCount: 4, pathVertexCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.lollipop(cliqueVertexCount: 4, pathVertexCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.lollipop(cliqueVertexCount: 4, pathVertexCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.lollipop(cliqueVertexCount: 4, pathVertexCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-109 directed: both arcs")
    func ng109() {
        // CompressedSparseRow.lollipop(cliqueVertexCount: 3, pathVertexCount: 2) → n 5; m 10; out [2, 2, 3, 2, 1]; in [2, 2, 3, 2, 1]; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1, 2→3, 3→2, 3→4, 4→3]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [2, 3], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [2, 2, 3, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 2], [0, 1, 3], [2, 4], [3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 10 && graph.edges.count == 10, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1], [2, 3], [3, 2], [3, 4], [4, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [2, 2, 3, 2, 1] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 3, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 2], [0, 2], [0, 1, 3], [2, 4], [3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2), "StableDirectedGraph<Int>")
    }
}
