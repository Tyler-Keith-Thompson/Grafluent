// Circulant, generalized Petersen, Kneser and windmill graphs (catalog NG-136 – NG-165): offsets mod n,
// each edge once; GP(n, k) as outer cycle, spokes and inner star polygon; k-subsets in lexicographic
// order, adjacent when disjoint; cliques sharing hub 0. Both arcs when directed.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing

@Suite("NamedGraphs circulant, generalized Petersen, Kneser and windmill graphs")
struct CirculantKneserWindmillTests {
    @Test("NG-136 C6(1, 2)")
    func ng136() {
        // UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 2]) → n 6; m 12; deg [4, 4, 4, 4, 4, 4]; E [0–1, 0–2, 0–4, 0–5, 1–2, 1–3, 1–5, 2–3, 2–4, 3–4, 3–5, 4–5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [0, 5], [1, 2], [1, 3], [1, 5], [2, 3], [2, 4], [3, 4], [3, 5], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 4, 5], [0, 2, 3, 5], [0, 1, 3, 4], [1, 2, 4, 5], [0, 2, 3, 5], [0, 1, 3, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "Pseudograph<Int>")
        check(Multigraph<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 4], [0, 5], [1, 0], [1, 2], [1, 3], [1, 5], [2, 0], [2, 1], [2, 3], [2, 4], [3, 1], [3, 2], [3, 4], [3, 5], [4, 0], [4, 2], [4, 3], [4, 5], [5, 0], [5, 1], [5, 3], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect(inDegrees == [4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 2, 4, 5], [0, 2, 3, 5], [0, 1, 3, 4], [1, 2, 4, 5], [0, 2, 3, 5], [0, 1, 3, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.circulant(vertexCount: 6, offsets: [1, 2]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.circulant(vertexCount: 6, offsets: [1, 2]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "StableDirectedGraph<Int>")
    }

    @Test("NG-137 C5(1) is C5")
    func ng137() {
        // UndirectedAdjacencyList<Int>.circulant(vertexCount: 5, offsets: [1]) → n 5; m 5; deg [2, 2, 2, 2, 2]; E [0–1, 0–4, 1–2, 2–3, 3–4]
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
        check(UndirectedAdjacencyList<Int>.circulant(vertexCount: 5, offsets: [1]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.circulant(vertexCount: 5, offsets: [1]), "Pseudograph<Int>")
        check(Multigraph<Int>.circulant(vertexCount: 5, offsets: [1]), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.circulant(vertexCount: 5, offsets: [1]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.circulant(vertexCount: 5, offsets: [1]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.circulant(vertexCount: 5, offsets: [1]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.circulant(vertexCount: 5, offsets: [1]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.circulant(vertexCount: 5, offsets: [1]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.circulant(vertexCount: 5, offsets: [1]), "StableDirectedGraph<Int>")
    }

    @Test("NG-138 C8(1, 4): offset n/2 gives each edge once")
    func ng138() {
        // UndirectedAdjacencyList<Int>.circulant(vertexCount: 8, offsets: [1, 4]) → n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–4, 0–7, 1–2, 1–5, 2–3, 2–6, 3–4, 3–7, 4–5, 5–6, 6–7]
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
        check(UndirectedAdjacencyList<Int>.circulant(vertexCount: 8, offsets: [1, 4]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.circulant(vertexCount: 8, offsets: [1, 4]), "Pseudograph<Int>")
        check(Multigraph<Int>.circulant(vertexCount: 8, offsets: [1, 4]), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.circulant(vertexCount: 8, offsets: [1, 4]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.circulant(vertexCount: 8, offsets: [1, 4]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.circulant(vertexCount: 8, offsets: [1, 4]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.circulant(vertexCount: 8, offsets: [1, 4]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.circulant(vertexCount: 8, offsets: [1, 4]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.circulant(vertexCount: 8, offsets: [1, 4]), "StableDirectedGraph<Int>")
    }

    @Test("NG-139 C6(2, -2, 4): 2, −2 and 4 are one offset")
    func ng139() {
        // UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [2, -2, 4]) → n 6; m 6; deg [2, 2, 2, 2, 2, 2]; E [0–2, 0–4, 1–3, 1–5, 2–4, 3–5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 4], [1, 3], [1, 5], [2, 4], [3, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[2, 4], [3, 5], [0, 4], [1, 5], [0, 2], [1, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [2, -2, 4]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.circulant(vertexCount: 6, offsets: [2, -2, 4]), "Pseudograph<Int>")
        check(Multigraph<Int>.circulant(vertexCount: 6, offsets: [2, -2, 4]), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 4], [1, 3], [1, 5], [2, 0], [2, 4], [3, 1], [3, 5], [4, 0], [4, 2], [5, 1], [5, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[2, 4], [3, 5], [0, 4], [1, 5], [0, 2], [1, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.circulant(vertexCount: 6, offsets: [2, -2, 4]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.circulant(vertexCount: 6, offsets: [2, -2, 4]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.circulant(vertexCount: 6, offsets: [2, -2, 4]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.circulant(vertexCount: 6, offsets: [2, -2, 4]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.circulant(vertexCount: 6, offsets: [2, -2, 4]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.circulant(vertexCount: 6, offsets: [2, -2, 4]), "StableDirectedGraph<Int>")
    }

    @Test("NG-140 C2(1) is K2")
    func ng140() {
        // UndirectedAdjacencyList<Int>.circulant(vertexCount: 2, offsets: [1]) → n 2; m 1; deg [1, 1]; E [0–1]
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
        check(UndirectedAdjacencyList<Int>.circulant(vertexCount: 2, offsets: [1]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.circulant(vertexCount: 2, offsets: [1]), "Pseudograph<Int>")
        check(Multigraph<Int>.circulant(vertexCount: 2, offsets: [1]), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.circulant(vertexCount: 2, offsets: [1]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.circulant(vertexCount: 2, offsets: [1]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.circulant(vertexCount: 2, offsets: [1]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.circulant(vertexCount: 2, offsets: [1]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.circulant(vertexCount: 2, offsets: [1]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.circulant(vertexCount: 2, offsets: [1]), "StableDirectedGraph<Int>")
    }

    @Test("NG-141 C1() is K1")
    func ng141() {
        // UndirectedAdjacencyList<Int>.circulant(vertexCount: 1, offsets: []) → n 1; m 0; deg [0]; E []
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
        check(UndirectedAdjacencyList<Int>.circulant(vertexCount: 1, offsets: []), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.circulant(vertexCount: 1, offsets: []), "Pseudograph<Int>")
        check(Multigraph<Int>.circulant(vertexCount: 1, offsets: []), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.circulant(vertexCount: 1, offsets: []), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.circulant(vertexCount: 1, offsets: []), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.circulant(vertexCount: 1, offsets: []), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.circulant(vertexCount: 1, offsets: []), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.circulant(vertexCount: 1, offsets: []), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.circulant(vertexCount: 1, offsets: []), "StableDirectedGraph<Int>")
    }

    @Test("NG-142 directed: both arcs")
    func ng142() {
        // CompressedSparseRow.circulant(vertexCount: 6, offsets: [1, 2]) → n 6; m 24; out [4, 4, 4, 4, 4, 4]; in [4, 4, 4, 4, 4, 4]; E [0→1, 0→2, 0→4, 0→5, 1→0, 1→2, 1→3, 1→5, 2→0, 2→1, 2→3, 2→4, 3→1, 3→2, 3→4, 3→5, 4→0, 4→2, 4→3, 4→5, 5→0, 5→1, 5→3, 5→4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [0, 5], [1, 2], [1, 3], [1, 5], [2, 3], [2, 4], [3, 4], [3, 5], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 4, 5], [0, 2, 3, 5], [0, 1, 3, 4], [1, 2, 4, 5], [0, 2, 3, 5], [0, 1, 3, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "Pseudograph<Int>")
        check(Multigraph<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 4], [0, 5], [1, 0], [1, 2], [1, 3], [1, 5], [2, 0], [2, 1], [2, 3], [2, 4], [3, 1], [3, 2], [3, 4], [3, 5], [4, 0], [4, 2], [4, 3], [4, 5], [5, 0], [5, 1], [5, 3], [5, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect(inDegrees == [4, 4, 4, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 2, 4, 5], [0, 2, 3, 5], [0, 1, 3, 4], [1, 2, 4, 5], [0, 2, 3, 5], [0, 1, 3, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.circulant(vertexCount: 6, offsets: [1, 2]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.circulant(vertexCount: 6, offsets: [1, 2]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.circulant(vertexCount: 6, offsets: [1, 2]), "StableDirectedGraph<Int>")
    }

    @Test("NG-145 GP(5, 2) is the Petersen graph")
    func ng145() {
        // UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 2) → n 10; m 15; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–4, 0–5, 1–2, 1–6, 2–3, 2–7, 3–4, 3–8, 4–9, 5–7, 5–8, 6–8, 6–9, 7–9]
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
        check(UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.generalizedPetersen(outerCycleLength: 5, step: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.generalizedPetersen(outerCycleLength: 5, step: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-146 GP(4, 1) is the cube")
    func ng146() {
        // UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 4, step: 1) → n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–3, 0–4, 1–2, 1–5, 2–3, 2–6, 3–7, 4–5, 4–7, 5–6, 6–7]
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
        check(UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 4, step: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.generalizedPetersen(outerCycleLength: 4, step: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.generalizedPetersen(outerCycleLength: 4, step: 1), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.generalizedPetersen(outerCycleLength: 4, step: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.generalizedPetersen(outerCycleLength: 4, step: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.generalizedPetersen(outerCycleLength: 4, step: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.generalizedPetersen(outerCycleLength: 4, step: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.generalizedPetersen(outerCycleLength: 4, step: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.generalizedPetersen(outerCycleLength: 4, step: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-147 GP(7, 2)")
    func ng147() {
        // UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 7, step: 2) → n 14; m 21; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–6, 0–7, 1–2, 1–8, 2–3, 2–9, 3–4, 3–10, 4–5, 4–11, 5–6, 5–12, 6–13, 7–9, 7–12, 8–10, 8–13, 9–11, 10–12, 11–13]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 14 && graph.edgeCount == 21 && graph.edges.count == 21, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 14), "\(type)")
            #expect((0 ..< 14).map { graph.vertexIndex(of: $0) } == Array(0 ..< 14), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 6], [0, 7], [1, 2], [1, 8], [2, 3], [2, 9], [3, 4], [3, 10], [4, 5], [4, 11], [5, 6], [5, 12], [6, 13], [7, 9], [7, 12], [8, 10], [8, 13], [9, 11], [10, 12], [11, 13]] as [[Int]], "\(type)")
            #expect((0 ..< 14).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 14).map { graph.neighbors(of: $0).sorted() } == [[1, 6, 7], [0, 2, 8], [1, 3, 9], [2, 4, 10], [3, 5, 11], [4, 6, 12], [0, 5, 13], [0, 9, 12], [1, 10, 13], [2, 7, 11], [3, 8, 12], [4, 9, 13], [5, 7, 10], [6, 8, 11]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 14).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 7, step: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.generalizedPetersen(outerCycleLength: 7, step: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.generalizedPetersen(outerCycleLength: 7, step: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 14 && graph.edgeCount == 42 && graph.edges.count == 42, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 14), "\(type)")
            #expect((0 ..< 14).map { graph.vertexIndex(of: $0) } == Array(0 ..< 14), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 14)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 6], [0, 7], [1, 0], [1, 2], [1, 8], [2, 1], [2, 3], [2, 9], [3, 2], [3, 4], [3, 10], [4, 3], [4, 5], [4, 11], [5, 4], [5, 6], [5, 12], [6, 0], [6, 5], [6, 13], [7, 0], [7, 9], [7, 12], [8, 1], [8, 10], [8, 13], [9, 2], [9, 7], [9, 11], [10, 3], [10, 8], [10, 12], [11, 4], [11, 9], [11, 13], [12, 5], [12, 7], [12, 10], [13, 6], [13, 8], [13, 11]] as [[Int]], "\(type)")
            #expect((0 ..< 14).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 14).map { graph.successors(of: $0).sorted() } == [[1, 6, 7], [0, 2, 8], [1, 3, 9], [2, 4, 10], [3, 5, 11], [4, 6, 12], [0, 5, 13], [0, 9, 12], [1, 10, 13], [2, 7, 11], [3, 8, 12], [4, 9, 13], [5, 7, 10], [6, 8, 11]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 14).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.generalizedPetersen(outerCycleLength: 7, step: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.generalizedPetersen(outerCycleLength: 7, step: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.generalizedPetersen(outerCycleLength: 7, step: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.generalizedPetersen(outerCycleLength: 7, step: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.generalizedPetersen(outerCycleLength: 7, step: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.generalizedPetersen(outerCycleLength: 7, step: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-148 GP(3, 1) is the prism")
    func ng148() {
        // UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 3, step: 1) → n 6; m 9; deg [3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–4, 2–5, 3–4, 3–5, 4–5]
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
        check(UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 3, step: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.generalizedPetersen(outerCycleLength: 3, step: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.generalizedPetersen(outerCycleLength: 3, step: 1), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.generalizedPetersen(outerCycleLength: 3, step: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.generalizedPetersen(outerCycleLength: 3, step: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.generalizedPetersen(outerCycleLength: 3, step: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.generalizedPetersen(outerCycleLength: 3, step: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.generalizedPetersen(outerCycleLength: 3, step: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.generalizedPetersen(outerCycleLength: 3, step: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-149 directed: both arcs")
    func ng149() {
        // CompressedSparseRow.generalizedPetersen(outerCycleLength: 5, step: 2) → n 10; m 30; out [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0→1, 0→4, 0→5, 1→0, 1→2, 1→6, 2→1, 2→3, 2→7, 3→2, 3→4, 3→8, 4→0, 4→3, 4→9, 5→0, 5→7, 5→8, 6→1, 6→8, 6→9, 7→2, 7→5, 7→9, 8→3, 8→5, 8→6, 9→4, 9→6, 9→7]
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
        check(UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.generalizedPetersen(outerCycleLength: 5, step: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.generalizedPetersen(outerCycleLength: 5, step: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.generalizedPetersen(outerCycleLength: 5, step: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-153 KG(5, 2): the Petersen graph, subsets in lexicographic order")
    func ng153() {
        // UndirectedAdjacencyList<Int>.kneser(setSize: 5, subsetSize: 2) → n 10; m 15; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–7, 0–8, 0–9, 1–5, 1–6, 1–9, 2–4, 2–6, 2–8, 3–4, 3–5, 3–7, 4–9, 5–8, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 15 && graph.edges.count == 15, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 7], [0, 8], [0, 9], [1, 5], [1, 6], [1, 9], [2, 4], [2, 6], [2, 8], [3, 4], [3, 5], [3, 7], [4, 9], [5, 8], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.neighbors(of: $0).sorted() } == [[7, 8, 9], [5, 6, 9], [4, 6, 8], [4, 5, 7], [2, 3, 9], [1, 3, 8], [1, 2, 7], [0, 3, 6], [0, 2, 5], [0, 1, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.kneser(setSize: 5, subsetSize: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.kneser(setSize: 5, subsetSize: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.kneser(setSize: 5, subsetSize: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 30 && graph.edges.count == 30, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 7], [0, 8], [0, 9], [1, 5], [1, 6], [1, 9], [2, 4], [2, 6], [2, 8], [3, 4], [3, 5], [3, 7], [4, 2], [4, 3], [4, 9], [5, 1], [5, 3], [5, 8], [6, 1], [6, 2], [6, 7], [7, 0], [7, 3], [7, 6], [8, 0], [8, 2], [8, 5], [9, 0], [9, 1], [9, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.successors(of: $0).sorted() } == [[7, 8, 9], [5, 6, 9], [4, 6, 8], [4, 5, 7], [2, 3, 9], [1, 3, 8], [1, 2, 7], [0, 3, 6], [0, 2, 5], [0, 1, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.kneser(setSize: 5, subsetSize: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.kneser(setSize: 5, subsetSize: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.kneser(setSize: 5, subsetSize: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.kneser(setSize: 5, subsetSize: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.kneser(setSize: 5, subsetSize: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.kneser(setSize: 5, subsetSize: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-154 KG(4, 1) is K4")
    func ng154() {
        // UndirectedAdjacencyList<Int>.kneser(setSize: 4, subsetSize: 1) → n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]
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
        check(UndirectedAdjacencyList<Int>.kneser(setSize: 4, subsetSize: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.kneser(setSize: 4, subsetSize: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.kneser(setSize: 4, subsetSize: 1), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.kneser(setSize: 4, subsetSize: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.kneser(setSize: 4, subsetSize: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.kneser(setSize: 4, subsetSize: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.kneser(setSize: 4, subsetSize: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.kneser(setSize: 4, subsetSize: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.kneser(setSize: 4, subsetSize: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-155 KG(5, 3): n < 2k, no edges")
    func ng155() {
        // UndirectedAdjacencyList<Int>.kneser(setSize: 5, subsetSize: 3) → n 10; m 0; deg [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; E []
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.neighbors(of: $0).sorted() } == [[], [], [], [], [], [], [], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.kneser(setSize: 5, subsetSize: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.kneser(setSize: 5, subsetSize: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.kneser(setSize: 5, subsetSize: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.successors(of: $0).sorted() } == [[], [], [], [], [], [], [], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.kneser(setSize: 5, subsetSize: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.kneser(setSize: 5, subsetSize: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.kneser(setSize: 5, subsetSize: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.kneser(setSize: 5, subsetSize: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.kneser(setSize: 5, subsetSize: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.kneser(setSize: 5, subsetSize: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-156 KG(6, 2)")
    func ng156() {
        // UndirectedAdjacencyList<Int>.kneser(setSize: 6, subsetSize: 2) → n 15; m 45; deg [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]; E [0–9, 0–10, 0–11, 0–12, 0–13, 0–14, 1–6, 1–7, 1–8, 1–12, 1–13, 1–14, 2–5, 2–7, 2–8, 2–10, 2–11, 2–14, 3–5, 3–6, 3–8, 3–9, 3–11, 3–13, 4–5, 4–6, 4–7, 4–9, 4–10, 4–12, 5–12, 5–13, 5–14, 6–10, 6–11, 6–14, 7–9, 7–11, 7–13, 8–9, 8–10, 8–12, 9–14, 10–13, 11–12]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 15 && graph.edgeCount == 45 && graph.edges.count == 45, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 15), "\(type)")
            #expect((0 ..< 15).map { graph.vertexIndex(of: $0) } == Array(0 ..< 15), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 9], [0, 10], [0, 11], [0, 12], [0, 13], [0, 14], [1, 6], [1, 7], [1, 8], [1, 12], [1, 13], [1, 14], [2, 5], [2, 7], [2, 8], [2, 10], [2, 11], [2, 14], [3, 5], [3, 6], [3, 8], [3, 9], [3, 11], [3, 13], [4, 5], [4, 6], [4, 7], [4, 9], [4, 10], [4, 12], [5, 12], [5, 13], [5, 14], [6, 10], [6, 11], [6, 14], [7, 9], [7, 11], [7, 13], [8, 9], [8, 10], [8, 12], [9, 14], [10, 13], [11, 12]] as [[Int]], "\(type)")
            #expect((0 ..< 15).map { graph.degree(of: $0) } == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect((0 ..< 15).map { graph.neighbors(of: $0).sorted() } == [[9, 10, 11, 12, 13, 14], [6, 7, 8, 12, 13, 14], [5, 7, 8, 10, 11, 14], [5, 6, 8, 9, 11, 13], [5, 6, 7, 9, 10, 12], [2, 3, 4, 12, 13, 14], [1, 3, 4, 10, 11, 14], [1, 2, 4, 9, 11, 13], [1, 2, 3, 9, 10, 12], [0, 3, 4, 7, 8, 14], [0, 2, 4, 6, 8, 13], [0, 2, 3, 6, 7, 12], [0, 1, 4, 5, 8, 11], [0, 1, 3, 5, 7, 10], [0, 1, 2, 5, 6, 9]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 15).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.kneser(setSize: 6, subsetSize: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.kneser(setSize: 6, subsetSize: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.kneser(setSize: 6, subsetSize: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 15 && graph.edgeCount == 90 && graph.edges.count == 90, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 15), "\(type)")
            #expect((0 ..< 15).map { graph.vertexIndex(of: $0) } == Array(0 ..< 15), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 15)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 9], [0, 10], [0, 11], [0, 12], [0, 13], [0, 14], [1, 6], [1, 7], [1, 8], [1, 12], [1, 13], [1, 14], [2, 5], [2, 7], [2, 8], [2, 10], [2, 11], [2, 14], [3, 5], [3, 6], [3, 8], [3, 9], [3, 11], [3, 13], [4, 5], [4, 6], [4, 7], [4, 9], [4, 10], [4, 12], [5, 2], [5, 3], [5, 4], [5, 12], [5, 13], [5, 14], [6, 1], [6, 3], [6, 4], [6, 10], [6, 11], [6, 14], [7, 1], [7, 2], [7, 4], [7, 9], [7, 11], [7, 13], [8, 1], [8, 2], [8, 3], [8, 9], [8, 10], [8, 12], [9, 0], [9, 3], [9, 4], [9, 7], [9, 8], [9, 14], [10, 0], [10, 2], [10, 4], [10, 6], [10, 8], [10, 13], [11, 0], [11, 2], [11, 3], [11, 6], [11, 7], [11, 12], [12, 0], [12, 1], [12, 4], [12, 5], [12, 8], [12, 11], [13, 0], [13, 1], [13, 3], [13, 5], [13, 7], [13, 10], [14, 0], [14, 1], [14, 2], [14, 5], [14, 6], [14, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 15).map { graph.outDegree(of: $0) } == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect(inDegrees == [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6] as [Int], "\(type)")
            #expect((0 ..< 15).map { graph.successors(of: $0).sorted() } == [[9, 10, 11, 12, 13, 14], [6, 7, 8, 12, 13, 14], [5, 7, 8, 10, 11, 14], [5, 6, 8, 9, 11, 13], [5, 6, 7, 9, 10, 12], [2, 3, 4, 12, 13, 14], [1, 3, 4, 10, 11, 14], [1, 2, 4, 9, 11, 13], [1, 2, 3, 9, 10, 12], [0, 3, 4, 7, 8, 14], [0, 2, 4, 6, 8, 13], [0, 2, 3, 6, 7, 12], [0, 1, 4, 5, 8, 11], [0, 1, 3, 5, 7, 10], [0, 1, 2, 5, 6, 9]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 15).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.kneser(setSize: 6, subsetSize: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.kneser(setSize: 6, subsetSize: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.kneser(setSize: 6, subsetSize: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.kneser(setSize: 6, subsetSize: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.kneser(setSize: 6, subsetSize: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.kneser(setSize: 6, subsetSize: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-157 KG(1, 1): one vertex")
    func ng157() {
        // UndirectedAdjacencyList<Int>.kneser(setSize: 1, subsetSize: 1) → n 1; m 0; deg [0]; E []
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
        check(UndirectedAdjacencyList<Int>.kneser(setSize: 1, subsetSize: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.kneser(setSize: 1, subsetSize: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.kneser(setSize: 1, subsetSize: 1), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.kneser(setSize: 1, subsetSize: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.kneser(setSize: 1, subsetSize: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.kneser(setSize: 1, subsetSize: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.kneser(setSize: 1, subsetSize: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.kneser(setSize: 1, subsetSize: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.kneser(setSize: 1, subsetSize: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-158 directed: both arcs")
    func ng158() {
        // CompressedSparseRow.kneser(setSize: 5, subsetSize: 2) → n 10; m 30; out [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0→7, 0→8, 0→9, 1→5, 1→6, 1→9, 2→4, 2→6, 2→8, 3→4, 3→5, 3→7, 4→2, 4→3, 4→9, 5→1, 5→3, 5→8, 6→1, 6→2, 6→7, 7→0, 7→3, 7→6, 8→0, 8→2, 8→5, 9→0, 9→1, 9→4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 15 && graph.edges.count == 15, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 7], [0, 8], [0, 9], [1, 5], [1, 6], [1, 9], [2, 4], [2, 6], [2, 8], [3, 4], [3, 5], [3, 7], [4, 9], [5, 8], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.neighbors(of: $0).sorted() } == [[7, 8, 9], [5, 6, 9], [4, 6, 8], [4, 5, 7], [2, 3, 9], [1, 3, 8], [1, 2, 7], [0, 3, 6], [0, 2, 5], [0, 1, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.kneser(setSize: 5, subsetSize: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.kneser(setSize: 5, subsetSize: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.kneser(setSize: 5, subsetSize: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 30 && graph.edges.count == 30, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 7], [0, 8], [0, 9], [1, 5], [1, 6], [1, 9], [2, 4], [2, 6], [2, 8], [3, 4], [3, 5], [3, 7], [4, 2], [4, 3], [4, 9], [5, 1], [5, 3], [5, 8], [6, 1], [6, 2], [6, 7], [7, 0], [7, 3], [7, 6], [8, 0], [8, 2], [8, 5], [9, 0], [9, 1], [9, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.successors(of: $0).sorted() } == [[7, 8, 9], [5, 6, 9], [4, 6, 8], [4, 5, 7], [2, 3, 9], [1, 3, 8], [1, 2, 7], [0, 3, 6], [0, 2, 5], [0, 1, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.kneser(setSize: 5, subsetSize: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.kneser(setSize: 5, subsetSize: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.kneser(setSize: 5, subsetSize: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.kneser(setSize: 5, subsetSize: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.kneser(setSize: 5, subsetSize: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.kneser(setSize: 5, subsetSize: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-161 Wd(3, 2): the friendship graph F2 (butterfly)")
    func ng161() {
        // UndirectedAdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3) → n 5; m 6; deg [4, 2, 2, 2, 2]; E [0–1, 0–2, 0–3, 0–4, 1–2, 3–4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [4, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4], [0, 2], [0, 1], [0, 4], [0, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 0], [1, 2], [2, 0], [2, 1], [3, 0], [3, 4], [4, 0], [4, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [4, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [4, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4], [0, 2], [0, 1], [0, 4], [0, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.windmill(cliqueCount: 2, cliqueVertexCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.windmill(cliqueCount: 2, cliqueVertexCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-162 Wd(3, 3): F3")
    func ng162() {
        // UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 3) → n 7; m 9; deg [6, 2, 2, 2, 2, 2, 2]; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 3–4, 5–6]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 2], [3, 4], [5, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [6, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4, 5, 6], [0, 2], [0, 1], [0, 4], [0, 3], [0, 6], [0, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 18 && graph.edges.count == 18, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 0], [1, 2], [2, 0], [2, 1], [3, 0], [3, 4], [4, 0], [4, 3], [5, 0], [5, 6], [6, 0], [6, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [6, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [6, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4, 5, 6], [0, 2], [0, 1], [0, 4], [0, 3], [0, 6], [0, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.windmill(cliqueCount: 3, cliqueVertexCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.windmill(cliqueCount: 3, cliqueVertexCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-163 Wd(2, 3) is a star")
    func ng163() {
        // UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2) → n 4; m 3; deg [3, 1, 1, 1]; E [0–1, 0–2, 0–3]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [3, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3], [0], [0], [0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 0], [2, 0], [3, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [3, 1, 1, 1] as [Int], "\(type)")
            #expect(inDegrees == [3, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [0], [0], [0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.windmill(cliqueCount: 3, cliqueVertexCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.windmill(cliqueCount: 3, cliqueVertexCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-164 Wd(4, 2)")
    func ng164() {
        // UndirectedAdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 4) → n 7; m 12; deg [6, 3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 1–3, 2–3, 4–5, 4–6, 5–6]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 2], [1, 3], [2, 3], [4, 5], [4, 6], [5, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [6, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4, 5, 6], [0, 2, 3], [0, 1, 3], [0, 1, 2], [0, 5, 6], [0, 4, 6], [0, 4, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 4)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 4), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 24 && graph.edges.count == 24, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 0], [1, 2], [1, 3], [2, 0], [2, 1], [2, 3], [3, 0], [3, 1], [3, 2], [4, 0], [4, 5], [4, 6], [5, 0], [5, 4], [5, 6], [6, 0], [6, 4], [6, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [6, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [6, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4, 5, 6], [0, 2, 3], [0, 1, 3], [0, 1, 2], [0, 5, 6], [0, 4, 6], [0, 4, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 4)), "\(type)")
        }
        checkDirected(CompressedSparseRow.windmill(cliqueCount: 2, cliqueVertexCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.windmill(cliqueCount: 2, cliqueVertexCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-165 directed: both arcs")
    func ng165() {
        // CompressedSparseRow.windmill(cliqueCount: 2, cliqueVertexCount: 3) → n 5; m 12; out [4, 2, 2, 2, 2]; in [4, 2, 2, 2, 2]; E [0→1, 0→2, 0→3, 0→4, 1→0, 1→2, 2→0, 2→1, 3→0, 3→4, 4→0, 4→3]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [4, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4], [0, 2], [0, 1], [0, 4], [0, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "Multigraph<Int>")
        // The directed form: both arcs.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 0], [1, 2], [2, 0], [2, 1], [3, 0], [3, 4], [4, 0], [4, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [4, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [4, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4], [0, 2], [0, 1], [0, 4], [0, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.windmill(cliqueCount: 2, cliqueVertexCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.windmill(cliqueCount: 2, cliqueVertexCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3), "StableDirectedGraph<Int>")
    }
}
