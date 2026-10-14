// Graphical degree sequences and the Havel–Hakimi constructions (catalog RG-152 – RG-190):
// Erdős–Gallai and Fulkerson–Chen–Anstee against NetworkX's decisions; Havel–Hakimi and Kleitman–Wang
// with NetworkX's ties, on every conformer of their kind.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing

@Suite("RandomGraphs graphicality and Havel–Hakimi")
struct DegreeSequenceTests {
    @Test("RG-152 [3, 3, 3, 3]: K4")
    func rg152() {
        // isGraphical([3, 3, 3, 3]) → true; = NetworkX
        #expect(isGraphical([3, 3, 3, 3]) == true)
        // Any collection of degrees, in any order.
        #expect(isGraphical([3, 3, 3, 3].reversed()) == true)
        #expect(isGraphical(ContiguousArray([3, 3, 3, 3])) == true)
    }

    @Test("RG-153 [3, 3, 3, 1]: odd sum")
    func rg153() {
        // isGraphical([3, 3, 3, 1]) → false; = NetworkX
        #expect(isGraphical([3, 3, 3, 1]) == false)
        // Any collection of degrees, in any order.
        #expect(isGraphical([3, 3, 3, 1].reversed()) == false)
        #expect(isGraphical(ContiguousArray([3, 3, 3, 1])) == false)
    }

    @Test("RG-154 []: the empty sequence")
    func rg154() {
        // isGraphical([]) → true; = NetworkX
        #expect(isGraphical([]) == true)
        // Any collection of degrees, in any order.
        #expect(isGraphical([].reversed()) == true)
        #expect(isGraphical(ContiguousArray([])) == true)
    }

    @Test("RG-155 [0, 0]: no edges")
    func rg155() {
        // isGraphical([0, 0]) → true; = NetworkX
        #expect(isGraphical([0, 0]) == true)
        // Any collection of degrees, in any order.
        #expect(isGraphical([0, 0].reversed()) == true)
        #expect(isGraphical(ContiguousArray([0, 0])) == true)
    }

    @Test("RG-156 [1]: odd sum, one vertex")
    func rg156() {
        // isGraphical([1]) → false; = NetworkX
        #expect(isGraphical([1]) == false)
        // Any collection of degrees, in any order.
        #expect(isGraphical([1].reversed()) == false)
        #expect(isGraphical(ContiguousArray([1])) == false)
    }

    @Test("RG-157 [4, 1, 1, 1, 1]: a star")
    func rg157() {
        // isGraphical([4, 1, 1, 1, 1]) → true; = NetworkX
        #expect(isGraphical([4, 1, 1, 1, 1]) == true)
        // Any collection of degrees, in any order.
        #expect(isGraphical([4, 1, 1, 1, 1].reversed()) == true)
        #expect(isGraphical(ContiguousArray([4, 1, 1, 1, 1])) == true)
    }

    @Test("RG-158 [3, 3, 1, 1]: Erdős–Gallai fails at k = 2")
    func rg158() {
        // isGraphical([3, 3, 1, 1]) → false; = NetworkX
        #expect(isGraphical([3, 3, 1, 1]) == false)
        // Any collection of degrees, in any order.
        #expect(isGraphical([3, 3, 1, 1].reversed()) == false)
        #expect(isGraphical(ContiguousArray([3, 3, 1, 1])) == false)
    }

    @Test("RG-159 [-1, 1]: a negative degree")
    func rg159() {
        // isGraphical([-1, 1]) → false; = NetworkX
        #expect(isGraphical([-1, 1]) == false)
        // Any collection of degrees, in any order.
        #expect(isGraphical([-1, 1].reversed()) == false)
        #expect(isGraphical(ContiguousArray([-1, 1])) == false)
    }

    @Test("RG-160 [4, 1, 1, 1]: a degree ≥ n")
    func rg160() {
        // isGraphical([4, 1, 1, 1]) → false; = NetworkX
        #expect(isGraphical([4, 1, 1, 1]) == false)
        // Any collection of degrees, in any order.
        #expect(isGraphical([4, 1, 1, 1].reversed()) == false)
        #expect(isGraphical(ContiguousArray([4, 1, 1, 1])) == false)
    }

    @Test("RG-161 [2, 2, 2, 2, 2, 2]: Zverovich–Zverovich accepts at once")
    func rg161() {
        // isGraphical([2, 2, 2, 2, 2, 2]) → true; = NetworkX
        #expect(isGraphical([2, 2, 2, 2, 2, 2]) == true)
        // Any collection of degrees, in any order.
        #expect(isGraphical([2, 2, 2, 2, 2, 2].reversed()) == true)
        #expect(isGraphical(ContiguousArray([2, 2, 2, 2, 2, 2])) == true)
    }

    @Test("RG-162 [6, 6, 5, 4, 4, 3, 2, 2, 1, 1]: runs of equal degrees")
    func rg162() {
        // isGraphical([6, 6, 5, 4, 4, 3, 2, 2, 1, 1]) → true; = NetworkX
        #expect(isGraphical([6, 6, 5, 4, 4, 3, 2, 2, 1, 1]) == true)
        // Any collection of degrees, in any order.
        #expect(isGraphical([6, 6, 5, 4, 4, 3, 2, 2, 1, 1].reversed()) == true)
        #expect(isGraphical(ContiguousArray([6, 6, 5, 4, 4, 3, 2, 2, 1, 1])) == true)
    }

    @Test("RG-163 [5, 5, 5, 5, 2, 2, 2]: fails at the Durfee number")
    func rg163() {
        // isGraphical([5, 5, 5, 5, 2, 2, 2]) → false; = NetworkX
        #expect(isGraphical([5, 5, 5, 5, 2, 2, 2]) == false)
        // Any collection of degrees, in any order.
        #expect(isGraphical([5, 5, 5, 5, 2, 2, 2].reversed()) == false)
        #expect(isGraphical(ContiguousArray([5, 5, 5, 5, 2, 2, 2])) == false)
    }

    @Test("RG-164 [4, 4, 4, 1, 1, 1, 1]: fails past the first run")
    func rg164() {
        // isGraphical([4, 4, 4, 1, 1, 1, 1]) → false; = NetworkX
        #expect(isGraphical([4, 4, 4, 1, 1, 1, 1]) == false)
        // Any collection of degrees, in any order.
        #expect(isGraphical([4, 4, 4, 1, 1, 1, 1].reversed()) == false)
        #expect(isGraphical(ContiguousArray([4, 4, 4, 1, 1, 1, 1])) == false)
    }

    @Test("RG-165 in [1, 1, 1], out [1, 1, 1]: the directed 3-cycle")
    func rg165() {
        // isDigraphical(inDegrees: [1, 1, 1], outDegrees: [1, 1, 1]) → true; = NetworkX
        #expect(isDigraphical(inDegrees: [1, 1, 1], outDegrees: [1, 1, 1]) == true)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [1, 1, 1].reversed(), outDegrees: [1, 1, 1].reversed()) == true)
    }

    @Test("RG-166 in [2, 0, 0], out [0, 1, 1]: two arcs into 0")
    func rg166() {
        // isDigraphical(inDegrees: [2, 0, 0], outDegrees: [0, 1, 1]) → true; = NetworkX
        #expect(isDigraphical(inDegrees: [2, 0, 0], outDegrees: [0, 1, 1]) == true)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [2, 0, 0].reversed(), outDegrees: [0, 1, 1].reversed()) == true)
    }

    @Test("RG-167 in [2, 2, 2], out [2, 2, 2]: the complete digraph on 3")
    func rg167() {
        // isDigraphical(inDegrees: [2, 2, 2], outDegrees: [2, 2, 2]) → true; = NetworkX
        #expect(isDigraphical(inDegrees: [2, 2, 2], outDegrees: [2, 2, 2]) == true)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [2, 2, 2].reversed(), outDegrees: [2, 2, 2].reversed()) == true)
    }

    @Test("RG-168 in [1, 0], out [0, 2]: unequal sums")
    func rg168() {
        // isDigraphical(inDegrees: [1, 0], outDegrees: [0, 2]) → false; = NetworkX
        #expect(isDigraphical(inDegrees: [1, 0], outDegrees: [0, 2]) == false)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [1, 0].reversed(), outDegrees: [0, 2].reversed()) == false)
    }

    @Test("RG-169 in [2, 0], out [0, 2]: a degree ≥ n")
    func rg169() {
        // isDigraphical(inDegrees: [2, 0], outDegrees: [0, 2]) → false; = NetworkX
        #expect(isDigraphical(inDegrees: [2, 0], outDegrees: [0, 2]) == false)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [2, 0].reversed(), outDegrees: [0, 2].reversed()) == false)
    }

    @Test("RG-170 in [0, 2, 1, 1], out [2, 0, 1, 1]")
    func rg170() {
        // isDigraphical(inDegrees: [0, 2, 1, 1], outDegrees: [2, 0, 1, 1]) → true; = NetworkX
        #expect(isDigraphical(inDegrees: [0, 2, 1, 1], outDegrees: [2, 0, 1, 1]) == true)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [0, 2, 1, 1].reversed(), outDegrees: [2, 0, 1, 1].reversed()) == true)
    }

    @Test("RG-171 in [1, 1, 1, 0], out [0, 0, 0, 3]: a source to every other vertex")
    func rg171() {
        // isDigraphical(inDegrees: [1, 1, 1, 0], outDegrees: [0, 0, 0, 3]) → true; = NetworkX
        #expect(isDigraphical(inDegrees: [1, 1, 1, 0], outDegrees: [0, 0, 0, 3]) == true)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [1, 1, 1, 0].reversed(), outDegrees: [0, 0, 0, 3].reversed()) == true)
    }

    @Test("RG-172 in [0, 0, 2, 2], out [2, 2, 0, 0]: K2,2 one way")
    func rg172() {
        // isDigraphical(inDegrees: [0, 0, 2, 2], outDegrees: [2, 2, 0, 0]) → true; = NetworkX
        #expect(isDigraphical(inDegrees: [0, 0, 2, 2], outDegrees: [2, 2, 0, 0]) == true)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [0, 0, 2, 2].reversed(), outDegrees: [2, 2, 0, 0].reversed()) == true)
    }

    @Test("RG-173 in [3, 0, 0, 0], out [0, 1, 1, 1]")
    func rg173() {
        // isDigraphical(inDegrees: [3, 0, 0, 0], outDegrees: [0, 1, 1, 1]) → true; = NetworkX
        #expect(isDigraphical(inDegrees: [3, 0, 0, 0], outDegrees: [0, 1, 1, 1]) == true)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [3, 0, 0, 0].reversed(), outDegrees: [0, 1, 1, 1].reversed()) == true)
    }

    @Test("RG-174 in [2, 1, 0], out [0, 1, 2]: a transitive tournament")
    func rg174() {
        // isDigraphical(inDegrees: [2, 1, 0], outDegrees: [0, 1, 2]) → true; = NetworkX
        #expect(isDigraphical(inDegrees: [2, 1, 0], outDegrees: [0, 1, 2]) == true)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [2, 1, 0].reversed(), outDegrees: [0, 1, 2].reversed()) == true)
    }

    @Test("RG-175 in [1, 1, 2, 0], out [2, 1, 0, 1]")
    func rg175() {
        // isDigraphical(inDegrees: [1, 1, 2, 0], outDegrees: [2, 1, 0, 1]) → true; = NetworkX
        #expect(isDigraphical(inDegrees: [1, 1, 2, 0], outDegrees: [2, 1, 0, 1]) == true)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [1, 1, 2, 0].reversed(), outDegrees: [2, 1, 0, 1].reversed()) == true)
    }

    @Test("RG-176 in [], out []: the empty sequences")
    func rg176() {
        // isDigraphical(inDegrees: [], outDegrees: []) → true; = NetworkX
        #expect(isDigraphical(inDegrees: [], outDegrees: []) == true)
        // The same vertices listed in reverse.
        #expect(isDigraphical(inDegrees: [].reversed(), outDegrees: [].reversed()) == true)
    }

    @Test("RG-178 [3, 3, 3, 3]")
    func rg178() {
        // UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [3, 3, 3, 3]) → n 4; m 6; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3]; = NetworkX
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.degree(of: $0) } == [3, 3, 3, 3] as [Int], "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [3, 3, 3, 3]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.havelHakimi(degreeSequence: [3, 3, 3, 3]), "Pseudograph<Int>")
        check(Multigraph<Int>.havelHakimi(degreeSequence: [3, 3, 3, 3]), "Multigraph<Int>")
    }

    @Test("RG-179 [3, 2, 2, 2, 1]")
    func rg179() {
        // UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [3, 2, 2, 2, 1]) → n 5; m 5; E [0–1, 0–2, 0–3, 1–2, 3–4]; = NetworkX
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [3, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [3, 2, 2, 2, 1] as [Int], "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [3, 2, 2, 2, 1]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.havelHakimi(degreeSequence: [3, 2, 2, 2, 1]), "Pseudograph<Int>")
        check(Multigraph<Int>.havelHakimi(degreeSequence: [3, 2, 2, 2, 1]), "Multigraph<Int>")
    }

    @Test("RG-180 [2, 2, 2, 2, 2, 2]")
    func rg180() {
        // UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [2, 2, 2, 2, 2, 2]) → n 6; m 6; E [0–1, 0–2, 1–2, 3–4, 3–5, 4–5]; = NetworkX
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [1, 2], [3, 4], [3, 5], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [2, 2, 2, 2, 2, 2] as [Int], "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [2, 2, 2, 2, 2, 2]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.havelHakimi(degreeSequence: [2, 2, 2, 2, 2, 2]), "Pseudograph<Int>")
        check(Multigraph<Int>.havelHakimi(degreeSequence: [2, 2, 2, 2, 2, 2]), "Multigraph<Int>")
    }

    @Test("RG-181 [4, 1, 1, 1, 1]")
    func rg181() {
        // UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [4, 1, 1, 1, 1]) → n 5; m 4; E [0–1, 0–2, 0–3, 0–4]; = NetworkX
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [0, 4]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.degree(of: $0) } == [4, 1, 1, 1, 1] as [Int], "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [4, 1, 1, 1, 1]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.havelHakimi(degreeSequence: [4, 1, 1, 1, 1]), "Pseudograph<Int>")
        check(Multigraph<Int>.havelHakimi(degreeSequence: [4, 1, 1, 1, 1]), "Multigraph<Int>")
    }

    @Test("RG-182 [0, 0, 0]")
    func rg182() {
        // UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [0, 0, 0]) → n 3; m 0; E []; = NetworkX
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.degree(of: $0) } == [0, 0, 0] as [Int], "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [0, 0, 0]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.havelHakimi(degreeSequence: [0, 0, 0]), "Pseudograph<Int>")
        check(Multigraph<Int>.havelHakimi(degreeSequence: [0, 0, 0]), "Multigraph<Int>")
    }

    @Test("RG-183 []")
    func rg183() {
        // UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: []) → n 0; m 0; E []; = NetworkX
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 0), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 0).map { graph.degree(of: $0) } == [] as [Int], "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: []), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.havelHakimi(degreeSequence: []), "Pseudograph<Int>")
        check(Multigraph<Int>.havelHakimi(degreeSequence: []), "Multigraph<Int>")
    }

    @Test("RG-184 [3, 3, 2, 2, 2, 1, 1]")
    func rg184() {
        // UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [3, 3, 2, 2, 2, 1, 1]) → n 7; m 7; E [0–1, 0–2, 0–3, 1–3, 1–4, 2–4, 5–6]; = NetworkX
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 7 && graph.edgeCount == 7 && graph.edges.count == 7, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 7), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 3], [1, 4], [2, 4], [5, 6]] as [[Int]], "\(type)")
            #expect((0 ..< 7).map { graph.degree(of: $0) } == [3, 3, 2, 2, 2, 1, 1] as [Int], "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [3, 3, 2, 2, 2, 1, 1]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.havelHakimi(degreeSequence: [3, 3, 2, 2, 2, 1, 1]), "Pseudograph<Int>")
        check(Multigraph<Int>.havelHakimi(degreeSequence: [3, 3, 2, 2, 2, 1, 1]), "Multigraph<Int>")
    }

    @Test("RG-185 [1, 1, 1, 1, 1, 1]")
    func rg185() {
        // UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [1, 1, 1, 1, 1, 1]) → n 6; m 3; E [0–1, 2–3, 4–5]; = NetworkX
        func check(_ graph: some Graph<Int>, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 3], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.degree(of: $0) } == [1, 1, 1, 1, 1, 1] as [Int], "\(type)")
        }
        check(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: [1, 1, 1, 1, 1, 1]), "UndirectedAdjacencyList<Int>")
        check(Pseudograph<Int>.havelHakimi(degreeSequence: [1, 1, 1, 1, 1, 1]), "Pseudograph<Int>")
        check(Multigraph<Int>.havelHakimi(degreeSequence: [1, 1, 1, 1, 1, 1]), "Multigraph<Int>")
    }

    @Test("RG-186 Kleitman–Wang: in [1, 1, 1], out [1, 1, 1]")
    func rg186() {
        // CompressedSparseRow.havelHakimi(inDegrees: [1, 1, 1], outDegrees: [1, 1, 1]) → n 3; m 3; E [0→2, 1→0, 2→1]; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [1, 0], [2, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [1, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [1, 1, 1] as [Int], "\(type)")
        }
        checkDirected(CompressedSparseRow.havelHakimi(inDegrees: [1, 1, 1], outDegrees: [1, 1, 1]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.havelHakimi(inDegrees: [1, 1, 1], outDegrees: [1, 1, 1]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.havelHakimi(inDegrees: [1, 1, 1], outDegrees: [1, 1, 1]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.havelHakimi(inDegrees: [1, 1, 1], outDegrees: [1, 1, 1]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.havelHakimi(inDegrees: [1, 1, 1], outDegrees: [1, 1, 1]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.havelHakimi(inDegrees: [1, 1, 1], outDegrees: [1, 1, 1]), "StableDirectedGraph<Int>")
    }

    @Test("RG-187 Kleitman–Wang: in [0, 2, 1, 1], out [2, 0, 1, 1]")
    func rg187() {
        // CompressedSparseRow.havelHakimi(inDegrees: [0, 2, 1, 1], outDegrees: [2, 0, 1, 1]) → n 4; m 4; E [0→2, 0→3, 2→1, 3→1]; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 4 && graph.edgeCount == 4 && graph.edges.count == 4, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 4), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 3], [2, 1], [3, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 4).map { graph.outDegree(of: $0) } == [2, 0, 1, 1] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 4)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 2, 1, 1] as [Int], "\(type)")
        }
        checkDirected(CompressedSparseRow.havelHakimi(inDegrees: [0, 2, 1, 1], outDegrees: [2, 0, 1, 1]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.havelHakimi(inDegrees: [0, 2, 1, 1], outDegrees: [2, 0, 1, 1]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.havelHakimi(inDegrees: [0, 2, 1, 1], outDegrees: [2, 0, 1, 1]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.havelHakimi(inDegrees: [0, 2, 1, 1], outDegrees: [2, 0, 1, 1]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.havelHakimi(inDegrees: [0, 2, 1, 1], outDegrees: [2, 0, 1, 1]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.havelHakimi(inDegrees: [0, 2, 1, 1], outDegrees: [2, 0, 1, 1]), "StableDirectedGraph<Int>")
    }

    @Test("RG-188 Kleitman–Wang: in [2, 2, 2], out [2, 2, 2]")
    func rg188() {
        // CompressedSparseRow.havelHakimi(inDegrees: [2, 2, 2], outDegrees: [2, 2, 2]) → n 3; m 6; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1]; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [2, 2, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 2, 2] as [Int], "\(type)")
        }
        checkDirected(CompressedSparseRow.havelHakimi(inDegrees: [2, 2, 2], outDegrees: [2, 2, 2]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.havelHakimi(inDegrees: [2, 2, 2], outDegrees: [2, 2, 2]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.havelHakimi(inDegrees: [2, 2, 2], outDegrees: [2, 2, 2]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.havelHakimi(inDegrees: [2, 2, 2], outDegrees: [2, 2, 2]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.havelHakimi(inDegrees: [2, 2, 2], outDegrees: [2, 2, 2]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.havelHakimi(inDegrees: [2, 2, 2], outDegrees: [2, 2, 2]), "StableDirectedGraph<Int>")
    }

    @Test("RG-189 Kleitman–Wang: in [2, 1, 0], out [0, 1, 2]")
    func rg189() {
        // CompressedSparseRow.havelHakimi(inDegrees: [2, 1, 0], outDegrees: [0, 1, 2]) → n 3; m 3; E [1→0, 2→0, 2→1]; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 3 && graph.edgeCount == 3 && graph.edges.count == 3, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 3), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0], [2, 0], [2, 1]] as [[Int]], "\(type)")
            #expect((0 ..< 3).map { graph.outDegree(of: $0) } == [0, 1, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 3)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 1, 0] as [Int], "\(type)")
        }
        checkDirected(CompressedSparseRow.havelHakimi(inDegrees: [2, 1, 0], outDegrees: [0, 1, 2]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.havelHakimi(inDegrees: [2, 1, 0], outDegrees: [0, 1, 2]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.havelHakimi(inDegrees: [2, 1, 0], outDegrees: [0, 1, 2]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.havelHakimi(inDegrees: [2, 1, 0], outDegrees: [0, 1, 2]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.havelHakimi(inDegrees: [2, 1, 0], outDegrees: [0, 1, 2]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.havelHakimi(inDegrees: [2, 1, 0], outDegrees: [0, 1, 2]), "StableDirectedGraph<Int>")
    }

    @Test("RG-190 Kleitman–Wang: in [0, 0], out [0, 0]")
    func rg190() {
        // CompressedSparseRow.havelHakimi(inDegrees: [0, 0], outDegrees: [0, 0]) → n 2; m 0; E []; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 2 && graph.edgeCount == 0 && graph.edges.count == 0, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 2), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]], "\(type)")
            #expect((0 ..< 2).map { graph.outDegree(of: $0) } == [0, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 2)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 0] as [Int], "\(type)")
        }
        checkDirected(CompressedSparseRow.havelHakimi(inDegrees: [0, 0], outDegrees: [0, 0]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.havelHakimi(inDegrees: [0, 0], outDegrees: [0, 0]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.havelHakimi(inDegrees: [0, 0], outDegrees: [0, 0]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.havelHakimi(inDegrees: [0, 0], outDegrees: [0, 0]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.havelHakimi(inDegrees: [0, 0], outDegrees: [0, 0]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.havelHakimi(inDegrees: [0, 0], outDegrees: [0, 0]), "StableDirectedGraph<Int>")
    }

    @Test("RG-277 Kleitman–Wang: a source with no in-degree left goes back to the out-only heap")
    func rg277() {
        // CompressedSparseRow.havelHakimi(inDegrees: [2, 2, 3, 3, 4], outDegrees: [3, 4, 2, 3, 2]) → n 5; m 14; E [0→1, 0→3, 0→4, 1→0, 1→2, 1→3, 1→4, 2→0, 2→4, 3→1, 3→2, 3→4, 4→2, 4→3]; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 5 && graph.edgeCount == 14 && graph.edges.count == 14, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 5), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 3], [0, 4], [1, 0], [1, 2], [1, 3], [1, 4], [2, 0], [2, 4], [3, 1], [3, 2], [3, 4], [4, 2], [4, 3]] as [[Int]], "\(type)")
            #expect((0 ..< 5).map { graph.outDegree(of: $0) } == [3, 4, 2, 3, 2] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 5)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [2, 2, 3, 3, 4] as [Int], "\(type)")
        }
        checkDirected(CompressedSparseRow.havelHakimi(inDegrees: [2, 2, 3, 3, 4], outDegrees: [3, 4, 2, 3, 2]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.havelHakimi(inDegrees: [2, 2, 3, 3, 4], outDegrees: [3, 4, 2, 3, 2]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.havelHakimi(inDegrees: [2, 2, 3, 3, 4], outDegrees: [3, 4, 2, 3, 2]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.havelHakimi(inDegrees: [2, 2, 3, 3, 4], outDegrees: [3, 4, 2, 3, 2]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.havelHakimi(inDegrees: [2, 2, 3, 3, 4], outDegrees: [3, 4, 2, 3, 2]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.havelHakimi(inDegrees: [2, 2, 3, 3, 4], outDegrees: [3, 4, 2, 3, 2]), "StableDirectedGraph<Int>")
    }

    @Test("RG-282 Kleitman–Wang on 16 vertices: deep heaps")
    func rg282() {
        // CompressedSparseRow.havelHakimi(inDegrees: [4, 6, 6, 3, 6, 6, 5, 7, 1, 4, 8, 10, 9, 6, 5, 6], outDegrees: [8, 7, 6, 4, 2, 8, 5, 3, 11, 8, 6, 4, 7, 3, 4, 6]) → n 16; m 92; E [0→1, 0→2, 0→3, 0→5, 0→6, 0→9, 0→10, 0→11, 1→0, 1→3, 1→4, 1→5, 1→10, 1→11, 1→12, 2→3, 2→4, 2→6, 2→9, 2→10, 2→11, 3→1, 3→6, 3→9, 3→15, 4→1, 4→15, 5→2, 5→4, 5→7, 5→8, 5→10, 5→11, 5→12, 5→15, 6→4, 6→7, 6→10, 6→11, 6→15, 7→4, 7→12, 7→15, 8→0, 8→2, 8→4, 8→5, 8→6, 8→7, 8→9, 8→10, 8→11, 8→12, 8→15, 9→0, 9→2, 9→5, 9→7, 9→10, 9→12, 9→13, 9→14, 10→5, 10→7, 10→11, 10→12, 10→13, 10→14, 11→7, 11→12, 11→13, 11→14, 12→0, 12→2, 12→5, 12→7, 12→11, 12→13, 12→14, 13→1, 13→12, 13→14, 14→1, 14→6, 14→11, 14→13, 15→1, 15→2, 15→10, 15→11, 15→12, 15→13]; = NetworkX
        func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {
            #expect(graph.vertexCount == 16 && graph.edgeCount == 92 && graph.edges.count == 92, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 16), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 2], [0, 3], [0, 5], [0, 6], [0, 9], [0, 10], [0, 11], [1, 0], [1, 3], [1, 4], [1, 5], [1, 10], [1, 11], [1, 12], [2, 3], [2, 4], [2, 6], [2, 9], [2, 10], [2, 11], [3, 1], [3, 6], [3, 9], [3, 15], [4, 1], [4, 15], [5, 2], [5, 4], [5, 7], [5, 8], [5, 10], [5, 11], [5, 12], [5, 15], [6, 4], [6, 7], [6, 10], [6, 11], [6, 15], [7, 4], [7, 12], [7, 15], [8, 0], [8, 2], [8, 4], [8, 5], [8, 6], [8, 7], [8, 9], [8, 10], [8, 11], [8, 12], [8, 15], [9, 0], [9, 2], [9, 5], [9, 7], [9, 10], [9, 12], [9, 13], [9, 14], [10, 5], [10, 7], [10, 11], [10, 12], [10, 13], [10, 14], [11, 7], [11, 12], [11, 13], [11, 14], [12, 0], [12, 2], [12, 5], [12, 7], [12, 11], [12, 13], [12, 14], [13, 1], [13, 12], [13, 14], [14, 1], [14, 6], [14, 11], [14, 13], [15, 1], [15, 2], [15, 10], [15, 11], [15, 12], [15, 13]] as [[Int]], "\(type)")
            #expect((0 ..< 16).map { graph.outDegree(of: $0) } == [8, 7, 6, 4, 2, 8, 5, 3, 11, 8, 6, 4, 7, 3, 4, 6] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 16)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [4, 6, 6, 3, 6, 6, 5, 7, 1, 4, 8, 10, 9, 6, 5, 6] as [Int], "\(type)")
        }
        checkDirected(CompressedSparseRow.havelHakimi(inDegrees: [4, 6, 6, 3, 6, 6, 5, 7, 1, 4, 8, 10, 9, 6, 5, 6], outDegrees: [8, 7, 6, 4, 2, 8, 5, 3, 11, 8, 6, 4, 7, 3, 4, 6]), "CompressedSparseRow")
        checkDirected(AdjacencyMatrix.havelHakimi(inDegrees: [4, 6, 6, 3, 6, 6, 5, 7, 1, 4, 8, 10, 9, 6, 5, 6], outDegrees: [8, 7, 6, 4, 2, 8, 5, 3, 11, 8, 6, 4, 7, 3, 4, 6]), "AdjacencyMatrix")
        checkDirected(AdjacencyList<Int>.havelHakimi(inDegrees: [4, 6, 6, 3, 6, 6, 5, 7, 1, 4, 8, 10, 9, 6, 5, 6], outDegrees: [8, 7, 6, 4, 2, 8, 5, 3, 11, 8, 6, 4, 7, 3, 4, 6]), "AdjacencyList<Int>")
        checkDirected(DirectedPseudograph<Int>.havelHakimi(inDegrees: [4, 6, 6, 3, 6, 6, 5, 7, 1, 4, 8, 10, 9, 6, 5, 6], outDegrees: [8, 7, 6, 4, 2, 8, 5, 3, 11, 8, 6, 4, 7, 3, 4, 6]), "DirectedPseudograph<Int>")
        checkDirected(DirectedMultigraph<Int>.havelHakimi(inDegrees: [4, 6, 6, 3, 6, 6, 5, 7, 1, 4, 8, 10, 9, 6, 5, 6], outDegrees: [8, 7, 6, 4, 2, 8, 5, 3, 11, 8, 6, 4, 7, 3, 4, 6]), "DirectedMultigraph<Int>")
        checkDirected(StableDirectedGraph<Int>.havelHakimi(inDegrees: [4, 6, 6, 3, 6, 6, 5, 7, 1, 4, 8, 10, 9, 6, 5, 6], outDegrees: [8, 7, 6, 4, 2, 8, 5, 3, 11, 8, 6, 4, 7, 3, 4, 6]), "StableDirectedGraph<Int>")
    }
}
