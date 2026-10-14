// Binomial and full r-ary trees (catalog NG-168 – NG-182): the parent of v is v & (v − 1), or (v − 1)/r;
// parent → child when directed, and as a Tree.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing
import Trees

@Suite("NamedGraphs binomial and full r-ary trees")
struct BinomialFullRaryTreeTests {
    @Test("NG-168 B0: parent of v is v & (v − 1)")
    func ng168() {
        // UndirectedAdjacencyList<Int>.binomialTree(order: 0) → n 1; m 0; deg [0]; E []
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
        check(UndirectedAdjacencyList<Int>.binomialTree(order: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.binomialTree(order: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.binomialTree(order: 0), "Multigraph<Int>")
        // The directed form: parent → child.
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
        checkDirected(CompressedSparseRow.binomialTree(order: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.binomialTree(order: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.binomialTree(order: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.binomialTree(order: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.binomialTree(order: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.binomialTree(order: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-169 B1: parent of v is v & (v − 1)")
    func ng169() {
        // UndirectedAdjacencyList<Int>.binomialTree(order: 1) → n 2; m 1; deg [1, 1]; E [0–1]
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
        check(UndirectedAdjacencyList<Int>.binomialTree(order: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.binomialTree(order: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.binomialTree(order: 1), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 1 && graph.edges.count == 1, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect((0 ..< 2).map { graph.vertexIndex(of: $0) } == Array(0 ..< 2), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 2)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.outDegree(of: $0) } == [1, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1] as [Int], "\(type)")
            #expect((0 ..< 2).map { graph.successors(of: $0).sorted() } == [[1], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 2).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.binomialTree(order: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.binomialTree(order: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.binomialTree(order: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.binomialTree(order: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.binomialTree(order: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.binomialTree(order: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-170 B2: parent of v is v & (v − 1)")
    func ng170() {
        // UndirectedAdjacencyList<Int>.binomialTree(order: 2) → n 4; m 3; deg [2, 1, 2, 1]; E [0–1, 0–2, 2–3]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [2, 1, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0], [0, 3], [2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.binomialTree(order: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.binomialTree(order: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.binomialTree(order: 2), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [2, 0, 1, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2], [], [3], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.binomialTree(order: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.binomialTree(order: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.binomialTree(order: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.binomialTree(order: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.binomialTree(order: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.binomialTree(order: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-171 B3: parent of v is v & (v − 1)")
    func ng171() {
        // UndirectedAdjacencyList<Int>.binomialTree(order: 3) → n 8; m 7; deg [3, 1, 2, 1, 3, 1, 2, 1]; E [0–1, 0–2, 0–4, 2–3, 4–5, 4–6, 6–7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [2, 3], [4, 5], [4, 6], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 1, 2, 1, 3, 1, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 4], [0], [0, 3], [2], [0, 5, 6], [4], [4, 7], [6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.binomialTree(order: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.binomialTree(order: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.binomialTree(order: 3), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 4], [2, 3], [4, 5], [4, 6], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [3, 0, 1, 0, 2, 0, 1, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 2, 4], [], [3], [], [5, 6], [], [7], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.binomialTree(order: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.binomialTree(order: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.binomialTree(order: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.binomialTree(order: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.binomialTree(order: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.binomialTree(order: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-172 directed: parent → child")
    func ng172() {
        // CompressedSparseRow.binomialTree(order: 3) → n 8; m 7; out [3, 0, 1, 0, 2, 0, 1, 0]; in [0, 1, 1, 1, 1, 1, 1, 1]; E [0→1, 0→2, 0→4, 2→3, 4→5, 4→6, 6→7]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [2, 3], [4, 5], [4, 6], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 1, 2, 1, 3, 1, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 4], [0], [0, 3], [2], [0, 5, 6], [4], [4, 7], [6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.binomialTree(order: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.binomialTree(order: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.binomialTree(order: 3), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 4], [2, 3], [4, 5], [4, 6], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [3, 0, 1, 0, 2, 0, 1, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[1, 2, 4], [], [3], [], [5, 6], [], [7], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.binomialTree(order: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.binomialTree(order: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.binomialTree(order: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.binomialTree(order: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.binomialTree(order: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.binomialTree(order: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-173 Tree.binomialTree")
    func ng173() {
        // Tree<Int>.binomialTree(order: 3) → n 8; m 7; deg [3, 1, 2, 1, 3, 1, 2, 1]; E [0–1, 0–2, 0–4, 2–3, 4–5, 4–6, 6–7]
        let graph = Tree<Int>.binomialTree(order: 3)
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 4], [2, 3], [4, 5], [4, 6], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.degree(of: $0) } == [3, 1, 2, 1, 3, 1, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 4], [0], [0, 3], [2], [0, 5, 6], [4], [4, 7], [6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(graph, "Tree<Int>")
    }

    @Test("NG-176 r = 2, n = 0 is the null graph")
    func ng176() {
        // UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0) → n 0; m 0; deg []; E []
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
        check(UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0), "Multigraph<Int>")
        // The directed form: parent → child.
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
        checkDirected(CompressedSparseRow.fullRaryTree(branchingFactor: 2, vertexCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.fullRaryTree(branchingFactor: 2, vertexCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-177 r = 2, n = 1 is one vertex")
    func ng177() {
        // UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1) → n 1; m 0; deg [0]; E []
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
        check(UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1), "Multigraph<Int>")
        // The directed form: parent → child.
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
        checkDirected(CompressedSparseRow.fullRaryTree(branchingFactor: 2, vertexCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.fullRaryTree(branchingFactor: 2, vertexCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-178 r = 2, n = 6: the last level partly filled")
    func ng178() {
        // UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6) → n 6; m 5; deg [2, 3, 2, 1, 1, 1]; E [0–1, 0–2, 1–3, 1–4, 2–5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 3, 2, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 3, 4], [0, 5], [1], [1], [2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "Pseudograph<Int>")
        check(Multigraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 2, 1, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 2], [3, 4], [5], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.fullRaryTree(branchingFactor: 2, vertexCount: 6), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.fullRaryTree(branchingFactor: 2, vertexCount: 6), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "StableDirectedGraph<Int>")
    }

    @Test("NG-179 r = 3, n = 10")
    func ng179() {
        // UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 10) → n 10; m 9; deg [3, 4, 4, 1, 1, 1, 1, 1, 1, 1]; E [0–1, 0–2, 0–3, 1–4, 1–5, 1–6, 2–7, 2–8, 2–9]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 4], [1, 5], [1, 6], [2, 7], [2, 8], [2, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.degree(of: $0) } == [3, 4, 4, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3], [0, 4, 5, 6], [0, 7, 8, 9], [0], [1], [1], [1], [2], [2], [2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 4)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 10), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 10), "Pseudograph<Int>")
        check(Multigraph<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 10), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 10), "\(type)")
            #expect((0 ..< 10).map { graph.vertexIndex(of: $0) } == Array(0 ..< 10), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 10)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 4], [1, 5], [1, 6], [2, 7], [2, 8], [2, 9]] as [[Int]], "\(type)")
            #expect((0 ..< 10).map { graph.outDegree(of: $0) } == [3, 3, 3, 0, 0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 10).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [4, 5, 6], [7, 8, 9], [], [], [], [], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 10).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 4)), "\(type)")
        }
        checkDirected(CompressedSparseRow.fullRaryTree(branchingFactor: 3, vertexCount: 10), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.fullRaryTree(branchingFactor: 3, vertexCount: 10), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 10), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 10), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 10), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 10), "StableDirectedGraph<Int>")
    }

    @Test("NG-180 r = 1, n = 4 is the path P4")
    func ng180() {
        // UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 4) → n 4; m 3; deg [1, 2, 2, 1]; E [0–1, 1–2, 2–3]
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
        check(UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 4), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [1, 1, 1, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1], [2], [3], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.fullRaryTree(branchingFactor: 1, vertexCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.fullRaryTree(branchingFactor: 1, vertexCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-181 directed: parent → child")
    func ng181() {
        // CompressedSparseRow.fullRaryTree(branchingFactor: 2, vertexCount: 6) → n 6; m 5; out [2, 2, 1, 0, 0, 0]; in [0, 1, 1, 1, 1, 1]; E [0→1, 0→2, 1→3, 1→4, 2→5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 3, 2, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 3, 4], [0, 5], [1], [1], [2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "Pseudograph<Int>")
        check(Multigraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 2, 1, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 2], [3, 4], [5], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.fullRaryTree(branchingFactor: 2, vertexCount: 6), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.fullRaryTree(branchingFactor: 2, vertexCount: 6), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6), "StableDirectedGraph<Int>")
    }

    @Test("NG-182 Tree.fullRaryTree")
    func ng182() {
        // Tree<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 7) → n 7; m 6; deg [3, 4, 1, 1, 1, 1, 1]; E [0–1, 0–2, 0–3, 1–4, 1–5, 1–6]
        let graph = Tree<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 7)
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 4], [1, 5], [1, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [3, 4, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3], [0, 4, 5, 6], [0], [0], [1], [1], [1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 4)), "\(type)")
        }
        check(graph, "Tree<Int>")
    }
}
