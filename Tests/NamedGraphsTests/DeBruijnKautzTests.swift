// De Bruijn and Kautz graphs (catalog NG-186 – NG-196): words in lexicographic order, each joined to the
// words it shifts into; de Bruijn on the representations that allow self-loops.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import StableGraphs
import Testing

@Suite("NamedGraphs de Bruijn and Kautz graphs")
struct DeBruijnKautzTests {
    @Test("NG-186 B(2, 3): loops at 000 and 111")
    func ng186() {
        // AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 3) → n 8; m 16; out [2, 2, 2, 2, 2, 2, 2, 2]; in [2, 2, 2, 2, 2, 2, 2, 2]; E [0→0, 0→1, 1→2, 1→3, 2→4, 2→5, 3→6, 3→7, 4→0, 4→1, 5→2, 5→3, 6→4, 6→5, 7→6, 7→7]
        // The directed form: word → its shifts.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 16 && graph.edges.count == 16, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect((0 ..< 8).map { graph.vertexIndex(of: $0) } == Array(0 ..< 8), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 0], [0, 1], [1, 2], [1, 3], [2, 4], [2, 5], [3, 6], [3, 7], [4, 0], [4, 1], [5, 2], [5, 3], [6, 4], [6, 5], [7, 6], [7, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 8).map { graph.successors(of: $0).sorted() } == [[0, 1], [2, 3], [4, 5], [6, 7], [0, 1], [2, 3], [4, 5], [6, 7]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 8).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.deBruijn(alphabetSize: 2, wordLength: 3), "DirectedPseudograph<Int>")
    }

    @Test("NG-187 B(3, 1): every arc, loops included")
    func ng187() {
        // AdjacencyList<Int>.deBruijn(alphabetSize: 3, wordLength: 1) → n 3; m 9; out [3, 3, 3]; in [3, 3, 3]; E [0→0, 0→1, 0→2, 1→0, 1→1, 1→2, 2→0, 2→1, 2→2]
        // The directed form: word → its shifts.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 9 && graph.edges.count == 9, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect((0 ..< 3).map { graph.vertexIndex(of: $0) } == Array(0 ..< 3), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2], [2, 0], [2, 1], [2, 2]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 3).map { graph.successors(of: $0).sorted() } == [[0, 1, 2], [0, 1, 2], [0, 1, 2]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 3).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(AdjacencyList<Int>.deBruijn(alphabetSize: 3, wordLength: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.deBruijn(alphabetSize: 3, wordLength: 1), "DirectedPseudograph<Int>")
    }

    @Test("NG-188 B(1, 2): one word, one loop")
    func ng188() {
        // AdjacencyList<Int>.deBruijn(alphabetSize: 1, wordLength: 2) → n 1; m 1; out [1]; in [1]; E [0→0]
        // The directed form: word → its shifts.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 1 && graph.edgeCount == 1 && graph.edges.count == 1, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 1), "\(type)")
            #expect((0 ..< 1).map { graph.vertexIndex(of: $0) } == Array(0 ..< 1), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 1)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 0]] as [[Int]], "\(type)")
            #expect((0 ..< 1).map { graph.outDegree(of: $0) } == [1] as [Int], "\(type)")
            #expect(inDegrees == [1] as [Int], "\(type)")
            #expect((0 ..< 1).map { graph.successors(of: $0).sorted() } == [[0]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 1).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(AdjacencyList<Int>.deBruijn(alphabetSize: 1, wordLength: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.deBruijn(alphabetSize: 1, wordLength: 2), "DirectedPseudograph<Int>")
    }

    @Test("NG-189 B(2, 1)")
    func ng189() {
        // AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 1) → n 2; m 4; out [2, 2]; in [2, 2]; E [0→0, 0→1, 1→0, 1→1]
        // The directed form: word → its shifts.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect((0 ..< 2).map { graph.vertexIndex(of: $0) } == Array(0 ..< 2), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 2)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 0], [0, 1], [1, 0], [1, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.outDegree(of: $0) } == [2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2] as [Int], "\(type)")
            #expect((0 ..< 2).map { graph.successors(of: $0).sorted() } == [[0, 1], [0, 1]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 2).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
        }
        checkDirected(AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.deBruijn(alphabetSize: 2, wordLength: 1), "DirectedPseudograph<Int>")
    }

    @Test("NG-190 DirectedPseudograph: the same arcs")
    func ng190() {
        // DirectedPseudograph<Int>.deBruijn(alphabetSize: 2, wordLength: 2) → n 4; m 8; out [2, 2, 2, 2]; in [2, 2, 2, 2]; E [0→0, 0→1, 1→2, 1→3, 2→0, 2→1, 3→2, 3→3]
        // The directed form: word → its shifts.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 8 && graph.edges.count == 8, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect((0 ..< 4).map { graph.vertexIndex(of: $0) } == Array(0 ..< 4), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 0], [0, 1], [1, 2], [1, 3], [2, 0], [2, 1], [3, 2], [3, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 4).map { graph.successors(of: $0).sorted() } == [[0, 1], [2, 3], [0, 1], [2, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 4).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 2)), "\(type)")
        }
        checkDirected(AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.deBruijn(alphabetSize: 2, wordLength: 2), "DirectedPseudograph<Int>")
    }

    @Test("NG-193 words of 3 over 2 letters: 010 and 101")
    func ng193() {
        // CompressedSparseRow.kautz(alphabetSize: 2, wordLength: 3) → n 2; m 2; out [1, 1]; in [1, 1]; E [0→1, 1→0]
        // The directed form: word → its shifts.
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
        checkDirected(CompressedSparseRow.kautz(alphabetSize: 2, wordLength: 3), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.kautz(alphabetSize: 2, wordLength: 3), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.kautz(alphabetSize: 2, wordLength: 3), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.kautz(alphabetSize: 2, wordLength: 3), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.kautz(alphabetSize: 2, wordLength: 3), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.kautz(alphabetSize: 2, wordLength: 3), "StableDirectedGraph<Int>")
    }

    @Test("NG-194 words of 2 over 3 letters")
    func ng194() {
        // CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 2) → n 6; m 12; out [2, 2, 2, 2, 2, 2]; in [2, 2, 2, 2, 2, 2]; E [0→2, 0→3, 1→4, 1→5, 2→0, 2→1, 3→4, 3→5, 4→0, 4→1, 5→2, 5→3]
        // The directed form: word → its shifts.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 12 && graph.edges.count == 12, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect((0 ..< 6).map { graph.vertexIndex(of: $0) } == Array(0 ..< 6), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 3], [1, 4], [1, 5], [2, 0], [2, 1], [3, 4], [3, 5], [4, 0], [4, 1], [5, 2], [5, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect(inDegrees == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
            #expect((0 ..< 6).map { graph.successors(of: $0).sorted() } == [[2, 3], [4, 5], [0, 1], [4, 5], [0, 1], [2, 3]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 6).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.kautz(alphabetSize: 3, wordLength: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.kautz(alphabetSize: 3, wordLength: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.kautz(alphabetSize: 3, wordLength: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.kautz(alphabetSize: 3, wordLength: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.kautz(alphabetSize: 3, wordLength: 2), "StableDirectedGraph<Int>")
    }

    @Test("NG-195 words of 1 over 3 letters is the complete digraph on 3")
    func ng195() {
        // CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 1) → n 3; m 6; out [2, 2, 2]; in [2, 2, 2]; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1]
        // The directed form: word → its shifts.
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
        checkDirected(CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 1), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.kautz(alphabetSize: 3, wordLength: 1), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.kautz(alphabetSize: 3, wordLength: 1), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.kautz(alphabetSize: 3, wordLength: 1), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.kautz(alphabetSize: 3, wordLength: 1), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.kautz(alphabetSize: 3, wordLength: 1), "StableDirectedGraph<Int>")
    }

    @Test("NG-196 words of 2 over 4 letters")
    func ng196() {
        // CompressedSparseRow.kautz(alphabetSize: 4, wordLength: 2) → n 12; m 36; out [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0→3, 0→4, 0→5, 1→6, 1→7, 1→8, 2→9, 2→10, 2→11, 3→0, 3→1, 3→2, 4→6, 4→7, 4→8, 5→9, 5→10, 5→11, 6→0, 6→1, 6→2, 7→3, 7→4, 7→5, 8→9, 8→10, 8→11, 9→0, 9→1, 9→2, 10→3, 10→4, 10→5, 11→6, 11→7, 11→8]
        // The directed form: word → its shifts.
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 12 && graph.edgeCount == 36 && graph.edges.count == 36, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 12), "\(type)")
            #expect((0 ..< 12).map { graph.vertexIndex(of: $0) } == Array(0 ..< 12), "\(type)")
            var inDegrees = [Int](repeating: 0, count: 12)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 3], [0, 4], [0, 5], [1, 6], [1, 7], [1, 8], [2, 9], [2, 10], [2, 11], [3, 0], [3, 1], [3, 2], [4, 6], [4, 7], [4, 8], [5, 9], [5, 10], [5, 11], [6, 0], [6, 1], [6, 2], [7, 3], [7, 4], [7, 5], [8, 9], [8, 10], [8, 11], [9, 0], [9, 1], [9, 2], [10, 3], [10, 4], [10, 5], [11, 6], [11, 7], [11, 8]] as [[Int]], "\(type)")
            #expect((0 ..< 12).map { graph.outDegree(of: $0) } == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect(inDegrees == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3] as [Int], "\(type)")
            #expect((0 ..< 12).map { graph.successors(of: $0).sorted() } == [[3, 4, 5], [6, 7, 8], [9, 10, 11], [0, 1, 2], [6, 7, 8], [9, 10, 11], [0, 1, 2], [3, 4, 5], [9, 10, 11], [0, 1, 2], [3, 4, 5], [6, 7, 8]] as [[Int]], "\(type)")
            #expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, "\(type)")
            #expect((0 ..< 12).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, "\(type)")
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 1)), "\(type)")
        }
        checkDirected(CompressedSparseRow.kautz(alphabetSize: 4, wordLength: 2), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.kautz(alphabetSize: 4, wordLength: 2), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.kautz(alphabetSize: 4, wordLength: 2), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.kautz(alphabetSize: 4, wordLength: 2), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.kautz(alphabetSize: 4, wordLength: 2), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.kautz(alphabetSize: 4, wordLength: 2), "StableDirectedGraph<Int>")
    }
}
