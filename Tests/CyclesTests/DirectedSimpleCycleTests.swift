// §C: `DirectedGraph.simpleCycles()`: every elementary circuit once, starting at its least vertex
// (in `vertices` order), emitted by least vertex and then lexicographically by each arc's offset
// in its vertex's `outEdges` row. Parallel arcs give one cycle per copy. Graphs from NetworkX,
// rustworkx, JGraphT, igraph and Boost, written as the catalog writes them on the
// `ReferenceDirectedMultigraph`, so positions are exact. Expected values come from the catalog's
// reference (`ref.py`). Case IDs (CY-nnn) refer to the catalog; see README.md.

import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing

/// A directed multigraph whose out-edge rows are not in position order: each row is built in
/// position order, then reversed or rotated left by one (the catalog's `~rev` and `~rot`). Vertex
/// indices are positions.
private struct ReorderedDirectedMultigraph<Vertex: Hashable>: DirectedGraph {
    enum Reordering { case reversed, rotated }

    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [DirectedEdge<Vertex>], rows reordering: Reordering) {
        let inOrder = ReferenceDirectedMultigraph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { v in
            let row = inOrder.outEdges(of: v)
            switch reordering {
            case .reversed: return Array(row.reversed())
            case .rotated: return row.isEmpty ? row : Array(row.dropFirst()) + [row[0]]
            }
        }
    }

    func outEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
}

@Suite("Directed simple cycles")
struct DirectedSimpleCycleTests {
    @Test("CY-200 simpleCycles(): 5 cycles in order: NetworkX test_simple_cycles and docstring; rustworkx (nx#5 rx#5 bh#5 bhu#5 bt#3)")
    func simpleCycles200() {
        // NetworkX sorted: [0], [0,1,2], [0,2], [1,2], [2]
        // D: 0>0 0>1 0>2 1>2 2>0 2>1 2>2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 2), (1, 2), (2, 0), (2, 1), (2, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0], [0, 1, 2], [0, 2], [1, 2], [2]]
        let expectedEdges: [[Int]] = [[0], [1, 3, 4], [2, 4], [3, 5], [6]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-201 simpleCycles() is [0]/[0]: JGraphT reflexiveCycleFind; Boost probe (bh#1 bt#0)")
    func simpleCycles201() {
        // Boost's Tiernan ignores loops
        // D: 0>0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0]]
        let expectedEdges: [[Int]] = [[0]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-202 simpleCycles() is empty: JGraphT noCyclesFind")
    func simpleCycles202() {
        // D: [A,B,C] A>B B>C
        let pairs: [(String, String)] = [("A", "B"), ("B", "C")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).isEmpty)
    }

    @Test("CY-203 simpleCycles() is [A,B]/[0,1]: JGraphT singleDirectCycleFind (jg#1)")
    func simpleCycles203() {
        // D: A>B B>A
        let pairs: [(String, String)] = [("A", "B"), ("B", "A")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[String]] = [["A", "B"]]
        let expectedEdges: [[Int]] = [[0, 1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-204 simpleCycles() is [A,B,C]/[0,1,2]: JGraphT indirectCycleFind (jg#1)")
    func simpleCycles204() {
        // D: A>B B>C C>A
        let pairs: [(String, String)] = [("A", "B"), ("B", "C"), ("C", "A")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[String]] = [["A", "B", "C"]]
        let expectedEdges: [[Int]] = [[0, 1, 2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-205 simpleCycles(): 2 cycles in order: JGraphT twoCycles (jg#2)")
    func simpleCycles205() {
        // JGraphT's order too
        // D: A>B B>A B>C C>A
        let pairs: [(String, String)] = [("A", "B"), ("B", "A"), ("B", "C"), ("C", "A")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[String]] = [["A", "B"], ["A", "B", "C"]]
        let expectedEdges: [[Int]] = [[0, 1], [0, 2, 3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-206 simpleCycles(): 2 cycles in order: JGraphT twoSharingEdge (jg#2)")
    func simpleCycles206() {
        // D: [A,B,C,D] B>C A>B C>A D>B C>D
        let pairs: [(String, String)] = [("B", "C"), ("A", "B"), ("C", "A"), ("D", "B"), ("C", "D")]
        let graph = ReferenceDirectedMultigraph(vertices: ["A", "B", "C", "D"], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[String]] = [["A", "B", "C"], ["B", "C", "D"]]
        let expectedEdges: [[Int]] = [[1, 0, 2], [0, 4, 3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-207 simpleCycles(): 3 cycles in order: JGraphT simplestCycles (jg#3)")
    func simpleCycles207() {
        // JGraphT pins [A,B], [A], [B]: the same order
        // D: A>B B>A A>A B>B
        let pairs: [(String, String)] = [("A", "B"), ("B", "A"), ("A", "A"), ("B", "B")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[String]] = [["A", "B"], ["A"], ["B"]]
        let expectedEdges: [[Int]] = [[0, 1], [2], [3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-208 simpleCycles(): 2 cycles in order: JGraphT complexGraph (jg#2)")
    func simpleCycles208() {
        // D: [A,B,C,D,E,F] A>B B>C B>E C>D D>E E>F F>A
        let pairs: [(String, String)] = [
            ("A", "B"), ("B", "C"), ("B", "E"), ("C", "D"), ("D", "E"), ("E", "F"), ("F", "A")
        ]
        let graph = ReferenceDirectedMultigraph(vertices: ["A", "B", "C", "D", "E", "F"], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[String]] = [["A", "B", "C", "D", "E", "F"], ["A", "B", "E", "F"]]
        let expectedEdges: [[Int]] = [[0, 1, 3, 4, 5, 6], [0, 2, 5, 6]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-209 simpleCycles(): 2 cycles in order: JGraphT testOrder (jg#2)")
    func simpleCycles209() {
        // JGraphT pins "0,1,2,3" then "0,1,4,5,2,3": the same
        // D: [0..5] 0>1 1>2 2>3 3>0 1>4 4>5 5>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (1, 4), (4, 5), (5, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3], [0, 1, 4, 5, 2, 3]]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3], [0, 4, 5, 6, 2, 3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-210 simpleCycles(): 5 cycles in order: JGraphT DirectedSimpleCyclesTest incremental (jg#5)")
    func simpleCycles210() {
        // D: [0..6] 0>0 1>1 0>1 1>0 1>2 2>3 3>0 6>6
        let pairs: [(Int, Int)] = [(0, 0), (1, 1), (0, 1), (1, 0), (1, 2), (2, 3), (3, 0), (6, 6)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0], [0, 1], [0, 1, 2, 3], [1], [6]]
        let expectedEdges: [[Int]] = [[0], [2, 3], [2, 4, 5, 6], [1], [7]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-211 simpleCycles() is [a,1]/[0,1]: NetworkX test_unsortable")
    func simpleCycles211() {
        // D: a>1 1>a
        let pairs: [(String, String)] = [("a", "1"), ("1", "a")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[String]] = [["a", "1"]]
        let expectedEdges: [[Int]] = [[0, 1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-212 simpleCycles() is [1,2,3]/[0,1,2]: NetworkX test_simple_cycles_small")
    func simpleCycles212() {
        // D: C(1,2,3)
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1, 2, 3]]
        let expectedEdges: [[Int]] = [[0, 1, 2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-213 simpleCycles(): 2 cycles in order: NetworkX test_simple_cycles_small")
    func simpleCycles213() {
        // D: C(1,2,3) C(10,20,30)
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1), (10, 20), (20, 30), (30, 10)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1, 2, 3], [10, 20, 30]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-214 simpleCycles() is empty: NetworkX test_simple_cycles_empty; rustworkx")
    func simpleCycles214() {
        // D: []
        let graph = ReferenceDirectedMultigraph<Int>(edges: [])
        #expect(Array(graph.simpleCycles()).isEmpty)
    }

    @Test("CY-215 simpleCycles(): 9 cycles in order: NetworkX / rustworkx Johnson figure 1, k = 3 (nx#9)")
    func simpleCycles215() {
        // D: johnson(3)
        let pairs: [(Int, Int)] = [
            (1, 2), (2, 5), (1, 3), (3, 5), (1, 4), (4, 5), (7, 1), (5, 8), (5, 6), (6, 8), (6, 7),
            (7, 8), (9, 5), (8, 9), (9, 12), (8, 10), (10, 12), (8, 11), (11, 12), (12, 8)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [1, 2, 5, 6, 7], [1, 3, 5, 6, 7], [1, 4, 5, 6, 7], [5, 8, 9], [5, 6, 8, 9],
            [5, 6, 7, 8, 9], [8, 9, 12], [8, 10, 12], [8, 11, 12]
        ]
        let expectedEdges: [[Int]] = [
            [0, 1, 8, 10, 6], [2, 3, 8, 10, 6], [4, 5, 8, 10, 6], [7, 13, 12], [8, 9, 13, 12],
            [8, 10, 11, 13, 12], [13, 14, 19], [15, 16, 19], [17, 18, 19]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-216 simpleCycles() emits 27: NetworkX / rustworkx figure 1, k = 9 (nx#27)")
    func count216() {
        // D: johnson(9)
        let pairs: [(Int, Int)] = [
            (1, 2), (2, 11), (1, 3), (3, 11), (1, 4), (4, 11), (1, 5), (5, 11), (1, 6), (6, 11),
            (1, 7), (7, 11), (1, 8), (8, 11), (1, 9), (9, 11), (1, 10), (10, 11), (19, 1), (11, 20),
            (11, 12), (12, 20), (12, 13), (13, 20), (13, 14), (14, 20), (14, 15), (15, 20), (15, 16),
            (16, 20), (16, 17), (17, 20), (17, 18), (18, 20), (18, 19), (19, 20), (21, 11), (20, 21),
            (21, 30), (20, 22), (22, 30), (20, 23), (23, 30), (20, 24), (24, 30), (20, 25), (25, 30),
            (20, 26), (26, 30), (20, 27), (27, 30), (20, 28), (28, 30), (20, 29), (29, 30), (30, 20)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 27)
    }

    @Test("CY-217 simpleCycles() emits 26: NetworkX test_simple_graph_with_reported_bug (nx#26)")
    func count217() {
        // D: [0,2,3,1,4,5] 0>2 0>3 2>1 2>4 3>2 3>4 1>0 1>3 4>0 4>1 4>5 5>0 5>1 5>2 5>3
        let pairs: [(Int, Int)] = [
            (0, 2), (0, 3), (2, 1), (2, 4), (3, 2), (3, 4), (1, 0), (1, 3), (4, 0), (4, 1), (4, 5),
            (5, 0), (5, 1), (5, 2), (5, 3)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 26)
    }

    @Test("CY-218 simpleCycles() emits 0: NetworkX A006231")
    func count218() {
        // D: DK(1)
        let graph = ReferenceDirectedMultigraph<Int>(vertices: [0], edges: [])
        #expect(Array(graph.simpleCycles()).count == 0)
    }

    @Test("CY-219 simpleCycles() emits 1: NetworkX A006231; rustworkx mesh")
    func count219() {
        // D: DK(2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 1)
    }

    @Test("CY-220 simpleCycles() emits 5")
    func count220() {
        // D: DK(3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 5)
    }

    @Test("CY-221 simpleCycles() emits 20")
    func count221() {
        // D: DK(4)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1),
            (3, 2)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 20)
    }

    @Test("CY-222 simpleCycles() emits 84")
    func count222() {
        // DK(5): every arc a>b, a != b, row-major
        let n = 5
        var pairs: [(Int, Int)] = []
        for a in 0 ..< n { for b in 0 ..< n where a != b { pairs.append((a, b)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 84)
    }

    @Test("CY-223 simpleCycles() emits 409")
    func count223() {
        // DK(6): every arc a>b, a != b, row-major
        let n = 6
        var pairs: [(Int, Int)] = []
        for a in 0 ..< n { for b in 0 ..< n where a != b { pairs.append((a, b)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 409)
    }

    @Test("CY-224 simpleCycles() emits 2365")
    func count224() {
        // DK(7): every arc a>b, a != b, row-major
        let n = 7
        var pairs: [(Int, Int)] = []
        for a in 0 ..< n { for b in 0 ..< n where a != b { pairs.append((a, b)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 2365)
    }

    @Test("CY-225 simpleCycles() emits 16064: rustworkx test_mesh_graph n = 8")
    func count225() {
        // DK(8): every arc a>b, a != b, row-major
        let n = 8
        var pairs: [(Int, Int)] = []
        for a in 0 ..< n { for b in 0 ..< n where a != b { pairs.append((a, b)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 16064)
    }

    @Test("CY-226 simpleCycles() emits 1: JGraphT DirectedSimpleCyclesTest RESULTS")
    func count226() {
        // Every loop is a cycle: A006231 + n
        // D: DKL(1)
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 1)
    }

    @Test("CY-227 simpleCycles() emits 3")
    func count227() {
        // D: DKL(2)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0), (1, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 3)
    }

    @Test("CY-228 simpleCycles() emits 8")
    func count228() {
        // D: DKL(3)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 8)
    }

    @Test("CY-229 simpleCycles() emits 24")
    func count229() {
        // D: DKL(4)
        let pairs: [(Int, Int)] = [
            (0, 0), (0, 1), (0, 2), (0, 3), (1, 0), (1, 1), (1, 2), (1, 3), (2, 0), (2, 1), (2, 2),
            (2, 3), (3, 0), (3, 1), (3, 2), (3, 3)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 24)
    }

    @Test("CY-230 simpleCycles() emits 89")
    func count230() {
        // DKL(5): every arc a>b including loops, row-major
        let n = 5
        var pairs: [(Int, Int)] = []
        for a in 0 ..< n { for b in 0 ..< n { pairs.append((a, b)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 89)
    }

    @Test("CY-231 simpleCycles() emits 415")
    func count231() {
        // DKL(6): every arc a>b including loops, row-major
        let n = 6
        var pairs: [(Int, Int)] = []
        for a in 0 ..< n { for b in 0 ..< n { pairs.append((a, b)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 415)
    }

    @Test("CY-232 simpleCycles() emits 2372")
    func count232() {
        // DKL(7): every arc a>b including loops, row-major
        let n = 7
        var pairs: [(Int, Int)] = []
        for a in 0 ..< n { for b in 0 ..< n { pairs.append((a, b)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 2372)
    }

    @Test("CY-233 simpleCycles() emits 16072: JGraphT RESULTS[8]")
    func count233() {
        // RESULTS[9] = 125 673 is CY-806
        // DKL(8): every arc a>b including loops, row-major
        let n = 8
        var pairs: [(Int, Int)] = []
        for a in 0 ..< n { for b in 0 ..< n { pairs.append((a, b)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 16072)
    }

    @Test("CY-234 simpleCycles() is [0,1,2,3,4,5,6,7,8,9]/[0,1,2,3,4,5,6,7,8,9]: igraph directed cycle graph (ig#1)")
    func simpleCycles234() {
        // D: C(0..9)
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 0)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-235 simpleCycles() is empty: igraph directed star")
    func simpleCycles235() {
        // D: S(0;1..6)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).isEmpty)
    }

    @Test("CY-236 simpleCycles() is [1,2,3,4,5,6,7]/[7,8,9,10,11,12,13]: igraph directed wheel, OUT (ig#1)")
    func simpleCycles236() {
        // Its ALL reading is CY-338
        // D: S(0;1..7) C(1..7)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (2, 3), (3, 4), (4, 5),
            (5, 6), (6, 7), (7, 1)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1, 2, 3, 4, 5, 6, 7]]
        let expectedEdges: [[Int]] = [[7, 8, 9, 10, 11, 12, 13]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-237 simpleCycles() is empty: igraph complete DAG (full_citation(5)), OUT")
    func simpleCycles237() {
        // Its ALL reading is K₅, CY-310
        // TT(5): every arc x>y for y < x, row-major
        let n = 5
        var pairs: [(Int, Int)] = []
        for x in 0 ..< n { for y in 0 ..< x { pairs.append((x, y)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).isEmpty)
    }

    @Test("CY-238 simpleCycles(): 2 cycles in order: igraph cycle of 4 with a multi-edge, directed (ig#2 nx#1)")
    func simpleCycles238() {
        // Edge identity: one cycle per parallel copy
        // D: [0..4] 1>2 2>3 2>3 3>4 4>1
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (2, 3), (3, 4), (4, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1, 2, 3, 4], [1, 2, 3, 4]]
        let expectedEdges: [[Int]] = [[0, 1, 3, 4], [0, 2, 3, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-239 simpleCycles(): 2 cycles in order: igraph PR 2181 (ig#2)")
    func simpleCycles239() {
        // D: [0..4] 0>1 1>2 2>3 3>0 1>4 4>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (1, 4), (4, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3], [0, 1, 4, 2, 3]]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3], [0, 4, 5, 2, 3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-240 simpleCycles(): 4 cycles in order: igraph \"stable boat\" (ig#4)")
    func simpleCycles240() {
        // D: 0>2 0>3 0>4 1>0 2>3 3>4 4>1 4>3
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 0), (2, 3), (3, 4), (4, 1), (4, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 2, 3, 4, 1], [0, 3, 4, 1], [0, 4, 1], [3, 4]]
        let expectedEdges: [[Int]] = [[0, 4, 5, 6, 3], [1, 5, 6, 3], [2, 6, 3], [5, 7]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-241 simpleCycles(): 7 cycles in order: igraph \"stable letter\" (ig#7)")
    func simpleCycles241() {
        // D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 4), (2, 3), (2, 4), (3, 1), (4, 0), (4, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 2, 3, 1, 4], [0, 2, 4], [0, 3, 1, 2, 4], [0, 3, 1, 4], [2, 3, 1], [2, 3, 1, 4], [2, 4]
        ]
        let expectedEdges: [[Int]] = [
            [0, 4, 6, 3, 7], [0, 5, 7], [1, 6, 2, 5, 7], [1, 6, 3, 7], [4, 6, 2], [4, 6, 3, 8], [5, 8]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-242 simpleCycles(): 2 cycles in order: igraph \"double square\" (ig#2)")
    func simpleCycles242() {
        // D: 0>2 0>4 1>3 2>5 3>0 4>1 5>4
        let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 3), (2, 5), (3, 0), (4, 1), (5, 4)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 2, 5, 4, 1, 3], [0, 4, 1, 3]]
        let expectedEdges: [[Int]] = [[0, 3, 6, 5, 2, 4], [1, 5, 2, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-243 simpleCycles() emits 31: Boost hawick_circuits.cpp directed ER(20, 0.1), default minstd_rand (bh#31 bhu#24 bt#24)")
    func count243() {
        // hawick_circuits counts parallel copies as we do; hawick_unique_circuits and Tiernan count vertex sequences
        // D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1), (12, 8), (11, 16), (9, 15), (1, 3), (4, 15), (1, 3), (12, 11), (14, 6),
            (8, 18), (19, 11), (3, 13), (6, 9), (1, 2), (3, 8), (0, 10), (9, 11), (13, 1), (1, 16),
            (7, 3), (3, 19)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 19, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 31)
    }

    @Test("CY-244 simpleCycles() emits 113: Boost tiernan_all_cycles.cpp directed ER(20, 0.1), seed 42 (bh#113 bhu#74 bt#74)")
    func count244() {
        // D: [0..19] 0>11 5>8 13>19 12>14 0>4 15>10 9>0 17>9 16>15 10>11 9>17 15>8 17>7 18>0 1>6 6>8 19>12 12>3 18>17 17>18 11>3 3>9 13>9 0>1 7>15 10>12 18>6 1>3 8>6 3>13 4>17 6>1 2>4 8>6 11>3 12>6 6>18 16>19 7>0 18>5
        let pairs: [(Int, Int)] = [
            (0, 11), (5, 8), (13, 19), (12, 14), (0, 4), (15, 10), (9, 0), (17, 9), (16, 15), (10, 11),
            (9, 17), (15, 8), (17, 7), (18, 0), (1, 6), (6, 8), (19, 12), (12, 3), (18, 17), (17, 18),
            (11, 3), (3, 9), (13, 9), (0, 1), (7, 15), (10, 12), (18, 6), (1, 3), (8, 6), (3, 13),
            (4, 17), (6, 1), (2, 4), (8, 6), (11, 3), (12, 6), (6, 18), (16, 19), (7, 0), (18, 5)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 19, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).count == 113)
    }

    @Test("CY-245 simpleCycles() is empty: NetworkX test_simple_cycles_acyclic_tournament")
    func simpleCycles245() {
        // TT(10): every arc x>y for y < x, row-major
        let n = 10
        var pairs: [(Int, Int)] = []
        for x in 0 ..< n { for y in 0 ..< x { pairs.append((x, y)) } }
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.simpleCycles()).isEmpty)
    }

    @Test("CY-246 simpleCycles(): 2 cycles in order: NetworkX test_chordless_cycles_directed graph")
    func simpleCycles246() {
        // D: 0>1 1>2 2>3 3>4 4>0 4>5 5>6 6>7 7>8 8>9 9>10 10>11 11>4
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10),
            (10, 11), (11, 4)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3, 4], [4, 5, 6, 7, 8, 9, 10, 11]]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9, 10, 11, 12]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-247 simpleCycles(): 3 cycles in order: the same plus 7>3")
    func simpleCycles247() {
        // D: 0>1 1>2 2>3 3>4 4>0 4>5 5>6 6>7 7>8 8>9 9>10 10>11 11>4 7>3
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10),
            (10, 11), (11, 4), (7, 3)
        ]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3, 4], [3, 4, 5, 6, 7], [4, 5, 6, 7, 8, 9, 10, 11]]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3, 4], [3, 5, 6, 7, 13], [5, 6, 7, 8, 9, 10, 11, 12]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-248 simpleCycles(): 2 cycles in order: rows reversed")
    func simpleCycles248() {
        // Within a start vertex, out-edge order decides
        // D: 0>1 0>2 1>0 2>0 ~rev
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (2, 0)]
        let graph = ReorderedDirectedMultigraph(vertices: 0 ... 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }, rows: .reversed)
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 2], [0, 1]]
        let expectedEdges: [[Int]] = [[1, 3], [0, 2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-249 simpleCycles(): 2 cycles in order: a loop after an arc")
    func simpleCycles249() {
        // The loop is 0's second out-edge
        // D: 0>1 1>0 0>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1], [0]]
        let expectedEdges: [[Int]] = [[0, 1], [2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-250 simpleCycles() is [2,0,1]/[2,0,1]: start is the least vertex in vertices order, not by value")
    func simpleCycles250() {
        // D: [2,1,0] 0>1 1>2 2>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: [2, 1, 0], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[2, 0, 1]]
        let expectedEdges: [[Int]] = [[2, 0, 1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-251 simpleCycles(): 2 cycles in order: NetworkX test_directed_chordless_cycle_undirected graph")
    func simpleCycles251() {
        // D: 1>2 2>3 3>4 4>5 5>0 5>1 0>2
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (5, 1), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1, 2, 3, 4, 5], [2, 3, 4, 5, 0]]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3, 5], [1, 2, 3, 4, 6]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-252 simpleCycles() is [1,3,2,5]/[0,3,4,5]: python-igraph 1.0.0 simple_cycles returns no cycle here (an igraph bug; NetworkX and Boost agree with us)")
    func simpleCycles252() {
        // igraph skips start vertices of degree < 3 already visited, which is wrong for digraphs: 1, 2, 3 were visited from 0, which is on no cycle. It also undercounts CY-244 (111)
        // D: [0..5] 1>3 4>5 0>4 3>2 2>5 5>1
        let pairs: [(Int, Int)] = [(1, 3), (4, 5), (0, 4), (3, 2), (2, 5), (5, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[1, 3, 2, 5]]
        let expectedEdges: [[Int]] = [[0, 3, 4, 5]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }
}
