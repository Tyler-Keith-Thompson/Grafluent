// Representations (catalog NG-084 – NG-090): one family on every conformer reads the same vertices
// and the same edges in the same order.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing

@Suite("NamedGraphs on every conformer")
struct RepresentationTests {
    @Test("NG-084 AdjacencyList<Int>: same arcs, edges in row-major order")
    func ng084() {
        // AdjacencyList<Int>.cycle(vertexCount: 4) → n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0]
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

    @Test("NG-085 AdjacencyMatrix: same arcs, edges in row-major order")
    func ng085() {
        // AdjacencyMatrix.cycle(vertexCount: 4) → n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0]
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

    @Test("NG-086 StableDirectedGraph<Int>: same arcs, edges in row-major order")
    func ng086() {
        // StableDirectedGraph<Int>.cycle(vertexCount: 4) → n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0]
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

    @Test("NG-087 DirectedPseudograph<Int>: same arcs, edges in row-major order")
    func ng087() {
        // DirectedPseudograph<Int>.cycle(vertexCount: 4) → n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0]
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

    @Test("NG-088 DirectedMultigraph<Int>: same arcs, edges in row-major order")
    func ng088() {
        // DirectedMultigraph<Int>.cycle(vertexCount: 4) → n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0]
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

    @Test("NG-089 Pseudograph<Int>: same edges, sorted")
    func ng089() {
        // Pseudograph<Int>.wheel(vertexCount: 4) → n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]
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

    @Test("NG-090 Multigraph<Int>: same edges, sorted")
    func ng090() {
        // Multigraph<Int>.wheel(vertexCount: 4) → n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]
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
}
