// Complete multipartite and Turán graphs and balanced trees (catalog NG-112 – NG-135): parts as
// consecutive ranges, earlier part → later part when directed; the balanced tree in breadth-first
// order, parent → child when directed, and as a Tree.
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

@Suite("NamedGraphs complete multipartite, Turán and balanced tree graphs")
struct MultipartiteBalancedTreeTests {
    @Test("NG-112 parts []")
    func ng112() {
        // UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: []) → n 0; m 0; deg []; E []
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
        check(UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: []), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeMultipartite(partSizes: []), "Pseudograph<Int>")
        check(Multigraph<Int>.completeMultipartite(partSizes: []), "Multigraph<Int>")
        // The directed form: earlier part → later part.
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
        checkDirected(CompressedSparseRow.completeMultipartite(partSizes: []), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeMultipartite(partSizes: []), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeMultipartite(partSizes: []), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeMultipartite(partSizes: []), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeMultipartite(partSizes: []), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeMultipartite(partSizes: []), "StableDirectedGraph<Int>")
    }

    @Test("NG-113 parts [2, 0, 1]")
    func ng113() {
        // UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [2, 0, 1]) → n 3; m 2; deg [1, 1, 2]; E [0–2, 1–2]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 2 && graph.edges.count == 2, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect((0 ..< 3).map { graph.vertexIndex(of: $0) } == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [1, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.degree(of: $0) } == [1, 1, 2] as [Int], "\(type)")
            #expect((0 ..< 3).map { graph.neighbors(of: $0).sorted() } == [[2], [2], [0, 1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 3).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [2, 0, 1]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeMultipartite(partSizes: [2, 0, 1]), "Pseudograph<Int>")
        check(Multigraph<Int>.completeMultipartite(partSizes: [2, 0, 1]), "Multigraph<Int>")
        // The directed form: earlier part → later part.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 2 && graph.edges.count == 2, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect((0 ..< 3).map { graph.vertexIndex(of: $0) } == Array(0 ..< 3), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [1, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [1, 1, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 0, 2] as [Int], "\(type)")
            #expect((0 ..< 3).map { graph.successors(of: $0).sorted() } == [[2], [2], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 3).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.completeMultipartite(partSizes: [2, 0, 1]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeMultipartite(partSizes: [2, 0, 1]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeMultipartite(partSizes: [2, 0, 1]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeMultipartite(partSizes: [2, 0, 1]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeMultipartite(partSizes: [2, 0, 1]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeMultipartite(partSizes: [2, 0, 1]), "StableDirectedGraph<Int>")
    }

    @Test("NG-114 parts [1, 2, 3]")
    func ng114() {
        // UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1, 2, 3]) → n 6; m 11; deg [5, 4, 4, 3, 3, 3]; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [5, 4, 4, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4, 5], [0, 3, 4, 5], [0, 3, 4, 5], [0, 1, 2], [0, 1, 2], [0, 1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1, 2, 3]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeMultipartite(partSizes: [1, 2, 3]), "Pseudograph<Int>")
        check(Multigraph<Int>.completeMultipartite(partSizes: [1, 2, 3]), "Multigraph<Int>")
        // The directed form: earlier part → later part.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [5, 3, 3, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4, 5], [3, 4, 5], [3, 4, 5], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.completeMultipartite(partSizes: [1, 2, 3]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeMultipartite(partSizes: [1, 2, 3]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeMultipartite(partSizes: [1, 2, 3]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeMultipartite(partSizes: [1, 2, 3]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeMultipartite(partSizes: [1, 2, 3]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeMultipartite(partSizes: [1, 2, 3]), "StableDirectedGraph<Int>")
    }

    @Test("NG-115 parts [1, 1, 1, 1]")
    func ng115() {
        // UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1, 1, 1, 1]) → n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]
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
        check(UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1, 1, 1, 1]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeMultipartite(partSizes: [1, 1, 1, 1]), "Pseudograph<Int>")
        check(Multigraph<Int>.completeMultipartite(partSizes: [1, 1, 1, 1]), "Multigraph<Int>")
        // The directed form: earlier part → later part.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [3, 2, 1, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 2, 3] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [2, 3], [3], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.completeMultipartite(partSizes: [1, 1, 1, 1]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeMultipartite(partSizes: [1, 1, 1, 1]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeMultipartite(partSizes: [1, 1, 1, 1]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeMultipartite(partSizes: [1, 1, 1, 1]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeMultipartite(partSizes: [1, 1, 1, 1]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeMultipartite(partSizes: [1, 1, 1, 1]), "StableDirectedGraph<Int>")
    }

    @Test("NG-116 directed: earlier part → later part")
    func ng116() {
        // CompressedSparseRow.completeMultipartite(partSizes: [1, 2, 3]) → n 6; m 11; out [5, 3, 3, 0, 0, 0]; in [0, 1, 1, 3, 3, 3]; E [0→1, 0→2, 0→3, 0→4, 0→5, 1→3, 1→4, 1→5, 2→3, 2→4, 2→5]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [5, 4, 4, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3, 4, 5], [0, 3, 4, 5], [0, 3, 4, 5], [0, 1, 2], [0, 1, 2], [0, 1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(1, 2)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1, 2, 3]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.completeMultipartite(partSizes: [1, 2, 3]), "Pseudograph<Int>")
        check(Multigraph<Int>.completeMultipartite(partSizes: [1, 2, 3]), "Multigraph<Int>")
        // The directed form: earlier part → later part.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [5, 3, 3, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[1, 2, 3, 4, 5], [3, 4, 5], [3, 4, 5], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.completeMultipartite(partSizes: [1, 2, 3]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.completeMultipartite(partSizes: [1, 2, 3]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.completeMultipartite(partSizes: [1, 2, 3]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.completeMultipartite(partSizes: [1, 2, 3]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.completeMultipartite(partSizes: [1, 2, 3]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.completeMultipartite(partSizes: [1, 2, 3]), "StableDirectedGraph<Int>")
    }

    @Test("NG-119 T(5, 2): parts [2, 3], smaller first")
    func ng119() {
        // UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 2) → n 5; m 6; deg [3, 3, 2, 2, 2]; E [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]
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
        check(UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.turan(vertexCount: 5, partCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.turan(vertexCount: 5, partCount: 2), "Multigraph<Int>")
        // The directed form: earlier part → later part.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [3, 3, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 0, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[2, 3, 4], [2, 3, 4], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.turan(vertexCount: 5, partCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.turan(vertexCount: 5, partCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.turan(vertexCount: 5, partCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.turan(vertexCount: 5, partCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.turan(vertexCount: 5, partCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.turan(vertexCount: 5, partCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-120 T(7, 3): parts [2, 2, 3]")
    func ng120() {
        // UndirectedAdjacencyList<Int>.turan(vertexCount: 7, partCount: 3) → n 7; m 16; deg [5, 5, 5, 5, 4, 4, 4]; E [0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 1–3, 1–4, 1–5, 1–6, 2–4, 2–5, 2–6, 3–4, 3–5, 3–6]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [2, 4], [2, 5], [2, 6], [3, 4], [3, 5], [3, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [5, 5, 5, 5, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.neighbors(of: $0).sorted() } == [[2, 3, 4, 5, 6], [2, 3, 4, 5, 6], [0, 1, 4, 5, 6], [0, 1, 4, 5, 6], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 1)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.turan(vertexCount: 7, partCount: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.turan(vertexCount: 7, partCount: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.turan(vertexCount: 7, partCount: 3), "Multigraph<Int>")
        // The directed form: earlier part → later part.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [2, 4], [2, 5], [2, 6], [3, 4], [3, 5], [3, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [5, 5, 3, 3, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 0, 2, 2, 4, 4, 4] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.successors(of: $0).sorted() } == [[2, 3, 4, 5, 6], [2, 3, 4, 5, 6], [4, 5, 6], [4, 5, 6], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.turan(vertexCount: 7, partCount: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.turan(vertexCount: 7, partCount: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.turan(vertexCount: 7, partCount: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.turan(vertexCount: 7, partCount: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.turan(vertexCount: 7, partCount: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.turan(vertexCount: 7, partCount: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-121 T(4, 4) is K4")
    func ng121() {
        // UndirectedAdjacencyList<Int>.turan(vertexCount: 4, partCount: 4) → n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]
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
        check(UndirectedAdjacencyList<Int>.turan(vertexCount: 4, partCount: 4), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.turan(vertexCount: 4, partCount: 4), "Pseudograph<Int>")
        check(Multigraph<Int>.turan(vertexCount: 4, partCount: 4), "Multigraph<Int>")
        // The directed form: earlier part → later part.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [3, 2, 1, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 2, 3] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [2, 3], [3], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)), "\(type)")
        }
        checkDirected(CompressedSparseRow.turan(vertexCount: 4, partCount: 4), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.turan(vertexCount: 4, partCount: 4), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.turan(vertexCount: 4, partCount: 4), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.turan(vertexCount: 4, partCount: 4), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.turan(vertexCount: 4, partCount: 4), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.turan(vertexCount: 4, partCount: 4), "StableDirectedGraph<Int>")
    }

    @Test("NG-122 T(4, 1): one part, no edges")
    func ng122() {
        // UndirectedAdjacencyList<Int>.turan(vertexCount: 4, partCount: 1) → n 4; m 0; deg [0, 0, 0, 0]; E []
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
        check(UndirectedAdjacencyList<Int>.turan(vertexCount: 4, partCount: 1), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.turan(vertexCount: 4, partCount: 1), "Pseudograph<Int>")
        check(Multigraph<Int>.turan(vertexCount: 4, partCount: 1), "Multigraph<Int>")
        // The directed form: earlier part → later part.
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
        checkDirected(CompressedSparseRow.turan(vertexCount: 4, partCount: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.turan(vertexCount: 4, partCount: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.turan(vertexCount: 4, partCount: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.turan(vertexCount: 4, partCount: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.turan(vertexCount: 4, partCount: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.turan(vertexCount: 4, partCount: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-123 directed: earlier part → later part")
    func ng123() {
        // CompressedSparseRow.turan(vertexCount: 5, partCount: 2) → n 5; m 6; out [3, 3, 0, 0, 0]; in [0, 0, 2, 2, 2]; E [0→2, 0→3, 0→4, 1→2, 1→3, 1→4]
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
        check(UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.turan(vertexCount: 5, partCount: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.turan(vertexCount: 5, partCount: 2), "Multigraph<Int>")
        // The directed form: earlier part → later part.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect((0 ..< 5).map { graph.vertexIndex(of: $0) } == Array(0 ..< 5), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [3, 3, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 0, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 5).map { graph.successors(of: $0).sorted() } == [[2, 3, 4], [2, 3, 4], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 5).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.turan(vertexCount: 5, partCount: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.turan(vertexCount: 5, partCount: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.turan(vertexCount: 5, partCount: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.turan(vertexCount: 5, partCount: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.turan(vertexCount: 5, partCount: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.turan(vertexCount: 5, partCount: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-126 r = 2, h = 2: children of p are 2p + 1, 2p + 2")
    func ng126() {
        // UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 2) → n 7; m 6; deg [2, 3, 3, 1, 1, 1, 1]; E [0–1, 0–2, 1–3, 1–4, 2–5, 2–6]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5], [2, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [2, 3, 3, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 3, 4], [0, 5, 6], [1], [1], [2], [2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.balancedTree(branchingFactor: 2, height: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.balancedTree(branchingFactor: 2, height: 2), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5], [2, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [2, 2, 2, 0, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.successors(of: $0).sorted() } == [[1, 2], [3, 4], [5, 6], [], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.balancedTree(branchingFactor: 2, height: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.balancedTree(branchingFactor: 2, height: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.balancedTree(branchingFactor: 2, height: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.balancedTree(branchingFactor: 2, height: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.balancedTree(branchingFactor: 2, height: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-127 r = 3, h = 2")
    func ng127() {
        // UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 3, height: 2) → n 13; m 12; deg [3, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1]; E [0–1, 0–2, 0–3, 1–4, 1–5, 1–6, 2–7, 2–8, 2–9, 3–10, 3–11, 3–12]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 13 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 13), "\(type)")
            #expect((0 ..< 13).map { graph.vertexIndex(of: $0) } == Array(0 ..< 13), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 4], [1, 5], [1, 6], [2, 7], [2, 8], [2, 9], [3, 10], [3, 11], [3, 12]] as [[Int]], "\(type)")
            #expect((0 ..< 13).map { graph.degree(of: $0) } == [3, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 13).map { graph.neighbors(of: $0).sorted() } == [[1, 2, 3], [0, 4, 5, 6], [0, 7, 8, 9], [0, 10, 11, 12], [1], [1], [1], [2], [2], [2], [3], [3], [3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 13).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 4)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 3, height: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.balancedTree(branchingFactor: 3, height: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.balancedTree(branchingFactor: 3, height: 2), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 13 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 13), "\(type)")
            #expect((0 ..< 13).map { graph.vertexIndex(of: $0) } == Array(0 ..< 13), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 13)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [1, 4], [1, 5], [1, 6], [2, 7], [2, 8], [2, 9], [3, 10], [3, 11], [3, 12]] as [[Int]], "\(type)")
            #expect((0 ..< 13).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 13).map { graph.successors(of: $0).sorted() } == [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12], [], [], [], [], [], [], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 13).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 4)), "\(type)")
        }
        checkDirected(CompressedSparseRow.balancedTree(branchingFactor: 3, height: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.balancedTree(branchingFactor: 3, height: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.balancedTree(branchingFactor: 3, height: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.balancedTree(branchingFactor: 3, height: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.balancedTree(branchingFactor: 3, height: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.balancedTree(branchingFactor: 3, height: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-128 r = 1, h = 3 is the path P4")
    func ng128() {
        // UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 1, height: 3) → n 4; m 3; deg [1, 2, 2, 1]; E [0–1, 1–2, 2–3]
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
        check(UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 1, height: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.balancedTree(branchingFactor: 1, height: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.balancedTree(branchingFactor: 1, height: 3), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.balancedTree(branchingFactor: 1, height: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.balancedTree(branchingFactor: 1, height: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.balancedTree(branchingFactor: 1, height: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.balancedTree(branchingFactor: 1, height: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.balancedTree(branchingFactor: 1, height: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.balancedTree(branchingFactor: 1, height: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-129 r = 0, h = 3 is the root alone")
    func ng129() {
        // UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 0, height: 3) → n 1; m 0; deg [0]; E []
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
        check(UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 0, height: 3), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.balancedTree(branchingFactor: 0, height: 3), "Pseudograph<Int>")
        check(Multigraph<Int>.balancedTree(branchingFactor: 0, height: 3), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.balancedTree(branchingFactor: 0, height: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.balancedTree(branchingFactor: 0, height: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.balancedTree(branchingFactor: 0, height: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.balancedTree(branchingFactor: 0, height: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.balancedTree(branchingFactor: 0, height: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.balancedTree(branchingFactor: 0, height: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-130 r = 2, h = 0 is the root alone")
    func ng130() {
        // UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 0) → n 1; m 0; deg [0]; E []
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
        check(UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 0), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.balancedTree(branchingFactor: 2, height: 0), "Pseudograph<Int>")
        check(Multigraph<Int>.balancedTree(branchingFactor: 2, height: 0), "Multigraph<Int>")
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
        checkDirected(CompressedSparseRow.balancedTree(branchingFactor: 2, height: 0), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.balancedTree(branchingFactor: 2, height: 0), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 0), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.balancedTree(branchingFactor: 2, height: 0), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.balancedTree(branchingFactor: 2, height: 0), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.balancedTree(branchingFactor: 2, height: 0), "StableDirectedGraph<Int>")
    }

    @Test("NG-131 directed: parent → child")
    func ng131() {
        // CompressedSparseRow.balancedTree(branchingFactor: 2, height: 2) → n 7; m 6; out [2, 2, 2, 0, 0, 0, 0]; in [0, 1, 1, 1, 1, 1, 1]; E [0→1, 0→2, 1→3, 1→4, 2→5, 2→6]
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5], [2, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [2, 3, 3, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 3, 4], [0, 5, 6], [1], [1], [2], [2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 2), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.balancedTree(branchingFactor: 2, height: 2), "Pseudograph<Int>")
        check(Multigraph<Int>.balancedTree(branchingFactor: 2, height: 2), "Multigraph<Int>")
        // The directed form: parent → child.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect((0 ..< 7).map { graph.vertexIndex(of: $0) } == Array(0 ..< 7), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 7)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5], [2, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.outDegree(of: $0) } == [2, 2, 2, 0, 0, 0, 0] as [Int], "\(type)")
            #expect(inDegrees == [0, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 7).map { graph.successors(of: $0).sorted() } == [[1, 2], [3, 4], [5, 6], [], [], [], []] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 7).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 3)), "\(type)")
        }
        checkDirected(CompressedSparseRow.balancedTree(branchingFactor: 2, height: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.balancedTree(branchingFactor: 2, height: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.balancedTree(branchingFactor: 2, height: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.balancedTree(branchingFactor: 2, height: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.balancedTree(branchingFactor: 2, height: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-132 Tree.balancedTree")
    func ng132() {
        // Tree<Int>.balancedTree(branchingFactor: 2, height: 3) → n 15; m 14; deg [2, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1]; E [0–1, 0–2, 1–3, 1–4, 2–5, 2–6, 3–7, 3–8, 4–9, 4–10, 5–11, 5–12, 6–13, 6–14]
        let graph = Tree<Int>.balancedTree(branchingFactor: 2, height: 3)
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 15 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 15), "\(type)")
            #expect((0 ..< 15).map { graph.vertexIndex(of: $0) } == Array(0 ..< 15), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5], [2, 6], [3, 7], [3, 8], [4, 9], [4, 10], [5, 11], [5, 12], [6, 13], [6, 14]] as [[Int]], "\(type)")
            #expect((0 ..< 15).map { graph.degree(of: $0) } == [2, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1] as [Int], "\(type)")
            #expect((0 ..< 15).map { graph.neighbors(of: $0).sorted() } == [[1, 2], [0, 3, 4], [0, 5, 6], [1, 7, 8], [1, 9, 10], [2, 11, 12], [2, 13, 14], [3], [3], [4], [4], [5], [5], [6], [6]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, "\(type)")
            #expect((0 ..< 15).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, "\(type)")
            #expect(!graph.contains(edge: UndirectedEdge(0, 3)), "\(type)")
        }
        check(graph, "Tree<Int>")
    }
}
