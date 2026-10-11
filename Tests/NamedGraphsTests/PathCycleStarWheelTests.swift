// Paths, cycles, stars and wheels (catalog NG-021 – NG-049): i – i+1; the cycle's closing edge stored
// as 0 – (n − 1); hub 0; the wheel as a star and a rim cycle composed. Directed forms follow the
// natural orientation. Tree.path and Tree.star.
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

@Suite("NamedGraphs paths, cycles, stars and wheels")
struct PathCycleStarWheelTests {
    @Test("NG-021 P0")
    func ng021() {
        // UndirectedAdjacencyList<Int>.path(vertexCount: 0) → n 0; m 0; deg []; E []
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
        check(UndirectedAdjacencyList<Int>.path(vertexCount: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.path(vertexCount: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.path(vertexCount: 0), "Multigraph<Int>")
        // The directed form: i → i + 1.
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
        checkDirected(CompressedSparseRow.path(vertexCount: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.path(vertexCount: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.path(vertexCount: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.path(vertexCount: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.path(vertexCount: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.path(vertexCount: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-022 P1")
    func ng022() {
        // UndirectedAdjacencyList<Int>.path(vertexCount: 1) → n 1; m 0; deg [0]; E []
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
        check(UndirectedAdjacencyList<Int>.path(vertexCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.path(vertexCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.path(vertexCount: 1), "Multigraph<Int>")
        // The directed form: i → i + 1.
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
        checkDirected(CompressedSparseRow.path(vertexCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.path(vertexCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.path(vertexCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.path(vertexCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.path(vertexCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.path(vertexCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-023 P2")
    func ng023() {
        // UndirectedAdjacencyList<Int>.path(vertexCount: 2) → n 2; m 1; deg [1, 1]; E [0–1]
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
        check(UndirectedAdjacencyList<Int>.path(vertexCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.path(vertexCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.path(vertexCount: 2), "Multigraph<Int>")
        // The directed form: i → i + 1.
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
        checkDirected(CompressedSparseRow.path(vertexCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.path(vertexCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.path(vertexCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.path(vertexCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.path(vertexCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.path(vertexCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-024 P5")
    func ng024() {
        // UndirectedAdjacencyList<Int>.path(vertexCount: 5) → n 5; m 4; deg [1, 2, 2, 2, 1]; E [0–1, 1–2, 2–3, 3–4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2], [2, 3], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [1, 2, 2, 2, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1], [0, 2], [1, 3], [2, 4], [3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.path(vertexCount: 5), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.path(vertexCount: 5), "Pseudograph<Int>")
        check(Multigraph<Int>.path(vertexCount: 5), "Multigraph<Int>")
        // The directed form: i → i + 1.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [1, 1, 1, 1, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1], [2], [3], [4], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.path(vertexCount: 5), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.path(vertexCount: 5), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.path(vertexCount: 5), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.path(vertexCount: 5), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.path(vertexCount: 5), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.path(vertexCount: 5), "StableDirectedGraph<Int>")
    }

    @Test("NG-025 P4 directed: i → i + 1")
    func ng025() {
        // CompressedSparseRow.path(vertexCount: 4) → n 4; m 3; out [1, 1, 1, 0]; in [0, 1, 1, 1]; E [0→1, 1→2, 2→3]
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
        check(UndirectedAdjacencyList<Int>.path(vertexCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.path(vertexCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.path(vertexCount: 4), "Multigraph<Int>")
        // The directed form: i → i + 1.
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
        checkDirected(CompressedSparseRow.path(vertexCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.path(vertexCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.path(vertexCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.path(vertexCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.path(vertexCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.path(vertexCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-026 Tree.path")
    func ng026() {
        // Tree<Int>.path(vertexCount: 4) → n 4; m 3; deg [1, 2, 2, 1]; E [0–1, 1–2, 2–3]
        let graph = Tree<Int>.path(vertexCount: 4)
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
        check(graph, "Tree<Int>")
    }

    @Test("NG-027 Tree.path(1) is one vertex")
    func ng027() {
        // Tree<Int>.path(vertexCount: 1) → n 1; m 0; deg [0]; E []
        let graph = Tree<Int>.path(vertexCount: 1)
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
        check(graph, "Tree<Int>")
    }

    @Test("NG-030 C3: closing edge stored as 0–2")
    func ng030() {
        // UndirectedAdjacencyList<Int>.cycle(vertexCount: 3) → n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2]
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
        check(UndirectedAdjacencyList<Int>.cycle(vertexCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.cycle(vertexCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.cycle(vertexCount: 3), "Multigraph<Int>")
        // The directed form: i → (i + 1) mod n.
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
        checkDirected(CompressedSparseRow.cycle(vertexCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.cycle(vertexCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.cycle(vertexCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.cycle(vertexCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.cycle(vertexCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.cycle(vertexCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-031 C4: closing edge stored as 0–3")
    func ng031() {
        // UndirectedAdjacencyList<Int>.cycle(vertexCount: 4) → n 4; m 4; deg [2, 2, 2, 2]; E [0–1, 0–3, 1–2, 2–3]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2], [1, 3], [0, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.cycle(vertexCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.cycle(vertexCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.cycle(vertexCount: 4), "Multigraph<Int>")
        // The directed form: i → (i + 1) mod n.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [1, 1, 1, 1] as [Int], "\(type)")
            #expect(inDegrees == [1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1], [2], [3], [0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.cycle(vertexCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.cycle(vertexCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.cycle(vertexCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.cycle(vertexCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.cycle(vertexCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.cycle(vertexCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-032 C6: closing edge stored as 0–5")
    func ng032() {
        // UndirectedAdjacencyList<Int>.cycle(vertexCount: 6) → n 6; m 6; deg [2, 2, 2, 2, 2, 2]; E [0–1, 0–5, 1–2, 2–3, 3–4, 4–5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 5], [1, 2], [2, 3], [3, 4], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 5], [0, 2], [1, 3], [2, 4], [3, 5], [0, 4]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.cycle(vertexCount: 6), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.cycle(vertexCount: 6), "Pseudograph<Int>")
        check(Multigraph<Int>.cycle(vertexCount: 6), "Multigraph<Int>")
        // The directed form: i → (i + 1) mod n.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect(inDegrees == [1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1], [2], [3], [4], [5], [0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.cycle(vertexCount: 6), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.cycle(vertexCount: 6), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.cycle(vertexCount: 6), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.cycle(vertexCount: 6), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.cycle(vertexCount: 6), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.cycle(vertexCount: 6), "StableDirectedGraph<Int>")
    }

    @Test("NG-033 C4 directed: i → i + 1 mod n, row-major")
    func ng033() {
        // CompressedSparseRow.cycle(vertexCount: 4) → n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 3], [1, 2], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.neighbors(of: $0).sorted() } == [[1, 3], [0, 2], [1, 3], [0, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.cycle(vertexCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.cycle(vertexCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.cycle(vertexCount: 4), "Multigraph<Int>")
        // The directed form: i → (i + 1) mod n.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 2], [2, 3], [3, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [1, 1, 1, 1] as [Int], "\(type)")
            #expect(inDegrees == [1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1], [2], [3], [0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(CompressedSparseRow.cycle(vertexCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.cycle(vertexCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.cycle(vertexCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.cycle(vertexCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.cycle(vertexCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.cycle(vertexCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-038 star of 1 vertices: hub 0")
    func ng038() {
        // UndirectedAdjacencyList<Int>.star(vertexCount: 1) → n 1; m 0; deg [0]; E []
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
        check(UndirectedAdjacencyList<Int>.star(vertexCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.star(vertexCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.star(vertexCount: 1), "Multigraph<Int>")
        // The directed form: hub → leaf.
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
        checkDirected(CompressedSparseRow.star(vertexCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.star(vertexCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.star(vertexCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.star(vertexCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.star(vertexCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.star(vertexCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-039 star of 2 vertices: hub 0")
    func ng039() {
        // UndirectedAdjacencyList<Int>.star(vertexCount: 2) → n 2; m 1; deg [1, 1]; E [0–1]
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
        check(UndirectedAdjacencyList<Int>.star(vertexCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.star(vertexCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.star(vertexCount: 2), "Multigraph<Int>")
        // The directed form: hub → leaf.
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
        checkDirected(CompressedSparseRow.star(vertexCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.star(vertexCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.star(vertexCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.star(vertexCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.star(vertexCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.star(vertexCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-040 star of 5 vertices: hub 0")
    func ng040() {
        // UndirectedAdjacencyList<Int>.star(vertexCount: 5) → n 5; m 4; deg [4, 1, 1, 1, 1]; E [0–1, 0–2, 0–3, 0–4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [4, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4], [0], [0], [0], [0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.star(vertexCount: 5), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.star(vertexCount: 5), "Pseudograph<Int>")
        check(Multigraph<Int>.star(vertexCount: 5), "Multigraph<Int>")
        // The directed form: hub → leaf.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [4, 0, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4], [], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.star(vertexCount: 5), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.star(vertexCount: 5), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.star(vertexCount: 5), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.star(vertexCount: 5), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.star(vertexCount: 5), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.star(vertexCount: 5), "StableDirectedGraph<Int>")
    }

    @Test("NG-041 directed: hub → leaf")
    func ng041() {
        // CompressedSparseRow.star(vertexCount: 4) → n 4; m 3; out [3, 0, 0, 0]; in [0, 1, 1, 1]; E [0→1, 0→2, 0→3]
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
        check(UndirectedAdjacencyList<Int>.star(vertexCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.star(vertexCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.star(vertexCount: 4), "Multigraph<Int>")
        // The directed form: hub → leaf.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [3, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.star(vertexCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.star(vertexCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.star(vertexCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.star(vertexCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.star(vertexCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.star(vertexCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-042 Tree.star")
    func ng042() {
        // Tree<Int>.star(vertexCount: 4) → n 4; m 3; deg [3, 1, 1, 1]; E [0–1, 0–2, 0–3]
        let graph = Tree<Int>.star(vertexCount: 4)
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
        check(graph, "Tree<Int>")
    }

    @Test("NG-044 NetworkX's star_graph(4) has 5 vertices; ours counts vertices")
    func ng044() {
        // UndirectedAdjacencyList<Int>.star(vertexCount: 5) → n 5; m 4; deg [4, 1, 1, 1, 1]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [4, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4], [0], [0], [0], [0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.star(vertexCount: 5), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.star(vertexCount: 5), "Pseudograph<Int>")
        check(Multigraph<Int>.star(vertexCount: 5), "Multigraph<Int>")
        // The directed form: hub → leaf.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [4, 0, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4], [], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.star(vertexCount: 5), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.star(vertexCount: 5), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.star(vertexCount: 5), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.star(vertexCount: 5), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.star(vertexCount: 5), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.star(vertexCount: 5), "StableDirectedGraph<Int>")
    }

    @Test("NG-045 W4: hub 0, rim 1..<4")
    func ng045() {
        // UndirectedAdjacencyList<Int>.wheel(vertexCount: 4) → n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]
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
        check(UndirectedAdjacencyList<Int>.wheel(vertexCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.wheel(vertexCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.wheel(vertexCount: 4), "Multigraph<Int>")
        // The directed form: hub → rim, rim i → i + 1 and n − 1 → 1.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 2], [2, 3], [3, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [3, 1, 1, 1] as [Int], "\(type)")
            #expect(inDegrees == [0, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [2], [3], [1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.wheel(vertexCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.wheel(vertexCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.wheel(vertexCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.wheel(vertexCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.wheel(vertexCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.wheel(vertexCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-046 W5: hub 0, rim 1..<5")
    func ng046() {
        // UndirectedAdjacencyList<Int>.wheel(vertexCount: 5) → n 5; m 8; deg [4, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–4, 2–3, 3–4]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 4], [2, 3], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [4, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4], [0, 2, 4], [0, 1, 3], [0, 2, 4], [0, 1, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.wheel(vertexCount: 5), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.wheel(vertexCount: 5), "Pseudograph<Int>")
        check(Multigraph<Int>.wheel(vertexCount: 5), "Multigraph<Int>")
        // The directed form: hub → rim, rim i → i + 1 and n − 1 → 1.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [2, 3], [3, 4], [4, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [4, 1, 1, 1, 1] as [Int], "\(type)")
            #expect(inDegrees == [0, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4], [2], [3], [4], [1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.wheel(vertexCount: 5), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.wheel(vertexCount: 5), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.wheel(vertexCount: 5), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.wheel(vertexCount: 5), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.wheel(vertexCount: 5), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.wheel(vertexCount: 5), "StableDirectedGraph<Int>")
    }

    @Test("NG-047 W7: hub 0, rim 1..<7")
    func ng047() {
        // UndirectedAdjacencyList<Int>.wheel(vertexCount: 7) → n 7; m 12; deg [6, 3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 1–6, 2–3, 3–4, 4–5, 5–6]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 2], [1, 6], [2, 3], [3, 4], [4, 5], [5, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [6, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4, 5, 6], [0, 2, 6], [0, 1, 3], [0, 2, 4], [0, 3, 5], [0, 4, 6], [0, 1, 5]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.wheel(vertexCount: 7), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.wheel(vertexCount: 7), "Pseudograph<Int>")
        check(Multigraph<Int>.wheel(vertexCount: 7), "Multigraph<Int>")
        // The directed form: hub → rim, rim i → i + 1 and n − 1 → 1.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [6, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect(inDegrees == [0, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4, 5, 6], [2], [3], [4], [5], [6], [1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.wheel(vertexCount: 7), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.wheel(vertexCount: 7), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.wheel(vertexCount: 7), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.wheel(vertexCount: 7), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.wheel(vertexCount: 7), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.wheel(vertexCount: 7), "StableDirectedGraph<Int>")
    }

    @Test("NG-048 W4 is K4")
    func ng048() {
        // UndirectedAdjacencyList<Int>.wheel(vertexCount: 4) == UndirectedAdjacencyList<Int>.complete(vertexCount: 4) → n 4; m 6; deg [3, 3, 3, 3]; equal true
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
        check(UndirectedAdjacencyList<Int>.wheel(vertexCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.wheel(vertexCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.wheel(vertexCount: 4), "Multigraph<Int>")
        // W4 is K4 on every undirected conformer.
        #expect(UndirectedAdjacencyList<Int>.wheel(vertexCount: 4) == UndirectedAdjacencyList<Int>.complete(vertexCount: 4))
        #expect(Pseudograph<Int>.wheel(vertexCount: 4) == Pseudograph<Int>.complete(vertexCount: 4))
        #expect(Multigraph<Int>.wheel(vertexCount: 4) == Multigraph<Int>.complete(vertexCount: 4))
        // The directed form: hub → rim, rim i → i + 1 and n − 1 → 1.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 2], [2, 3], [3, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [3, 1, 1, 1] as [Int], "\(type)")
            #expect(inDegrees == [0, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [2], [3], [1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.wheel(vertexCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.wheel(vertexCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.wheel(vertexCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.wheel(vertexCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.wheel(vertexCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.wheel(vertexCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-049 directed: hub → rim, rim cycle 1 → 2 → … → n − 1 → 1")
    func ng049() {
        // CompressedSparseRow.wheel(vertexCount: 5) → n 5; m 8; out [4, 1, 1, 1, 1]; in [0, 2, 2, 2, 2]; E [0→1, 0→2, 0→3, 0→4, 1→2, 2→3, 3→4, 4→1]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 4], [2, 3], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [4, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4], [0, 2, 4], [0, 1, 3], [0, 2, 4], [0, 1, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.wheel(vertexCount: 5), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.wheel(vertexCount: 5), "Pseudograph<Int>")
        check(Multigraph<Int>.wheel(vertexCount: 5), "Multigraph<Int>")
        // The directed form: hub → rim, rim i → i + 1 and n − 1 → 1.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [2, 3], [3, 4], [4, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [4, 1, 1, 1, 1] as [Int], "\(type)")
            #expect(inDegrees == [0, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4], [2], [3], [4], [1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.wheel(vertexCount: 5), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.wheel(vertexCount: 5), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.wheel(vertexCount: 5), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.wheel(vertexCount: 5), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.wheel(vertexCount: 5), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.wheel(vertexCount: 5), "StableDirectedGraph<Int>")
    }
}
