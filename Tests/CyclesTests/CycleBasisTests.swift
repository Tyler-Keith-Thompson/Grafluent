// §B: `cycleBasis()`, the fundamental cycles of the breadth-first spanning forest (roots in
// `vertices` order, rows in incidence order): one cycle per non-tree edge, loops and parallel
// copies included, in ascending position of that edge, each in canonical form. Every graph is
// written as the catalog writes it, on the `ReferencePseudograph`, so positions are exact.
// Expected values come from the catalog's reference (`ref.py`). The minimum cycle basis rows
// (CY-150 – CY-156) are phase 2 and not tested here. Case IDs (CY-nnn) refer to the catalog;
// see README.md.

import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing

/// An undirected pseudograph whose incidence rows are not in position order, as on an
/// `UndirectedAdjacencyList` after removals: each row is built in position order (a self-loop
/// twice), then reversed or rotated left by one (the catalog's `~rev` and `~rot`). Vertex and edge
/// indices are positions.
private struct ReorderedPseudograph<Vertex: Hashable>: Graph {
    enum Reordering { case reversed, rotated }

    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [UndirectedEdge<Vertex>], rows reordering: Reordering) {
        let inOrder = ReferencePseudograph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { v in
            let row = inOrder.incidentEdges(of: v)
            switch reordering {
            case .reversed: return Array(row.reversed())
            case .rotated: return row.isEmpty ? row : Array(row.dropFirst()) + [row[0]]
            }
        }
    }

    func incidentEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

@Suite("Cycle basis")
struct CycleBasisTests {
    @Test("CY-100 cycleBasis() is empty: igraph cycle_bases null graph")
    func cycleBasis100() {
        // []
        let graph = ReferencePseudograph<Int>(edges: [])
        let basis = graph.cycleBasis()
        #expect(basis.isEmpty)
    }

    @Test("CY-101 cycleBasis() is empty: igraph singleton")
    func cycleBasis101() {
        // [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let basis = graph.cycleBasis()
        #expect(basis.isEmpty)
    }

    @Test("CY-102 cycleBasis() is [0]/[0]: igraph single vertex with loop; NetworkX test_cycle_basis_self_loop")
    func cycleBasis102() {
        // igraph: (0)
        // 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0]]
        let expectedEdges: [[Int]] = [[0]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-103 cycleBasis() is empty: igraph tree kary_tree(3, 2)")
    func cycleBasis103() {
        // kary(3,2)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        #expect(basis.isEmpty)
    }

    @Test("CY-104 cycleBasis() is [0,1]/[0,1]: igraph 2-cycle")
    func cycleBasis104() {
        // igraph: (0 1). NetworkX and JGraphT's Paton reject multigraphs
        // 0-1 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1]]
        let expectedEdges: [[Int]] = [[0, 1]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-105 cycleBasis() has 7 cycles: igraph disconnected multigraph (igb#7)")
    func cycleBasis105() {
        // igraph: (1 0 2) (4 5) (3 5) (7 6 10) (8 10 9) (11) (13): the same cycles but (4 5) for (3 4)
        // [0..12] 1-2 2-3 3-1 4-5 5-4 4-5 6-7 7-8 8-9 9-6 6-8 10-10 10-11 12-12
        let pairs: [(Int, Int)] = [
            (1, 2), (2, 3), (3, 1), (4, 5), (5, 4), (4, 5), (6, 7), (7, 8), (8, 9), (9, 6), (6, 8),
            (10, 10), (10, 11), (12, 12)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[1, 2, 3], [4, 5], [4, 5], [6, 7, 8], [6, 9, 8], [10], [12]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [3, 4], [3, 5], [6, 7, 10], [9, 8, 10], [11], [13]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-106 cycleBasis() has 3 cycles: NetworkX test_cycle_basis (nxb#3)")
    func cycleBasis106() {
        // NetworkX, sorted: [0,1,2,3], [0,1,6,7,8], [0,3,4,5]: the same vertex sets
        // 0-1 0-3 0-5 0-8 1-2 1-6 2-3 3-4 4-5 6-7 7-8 8-9
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 3), (0, 5), (0, 8), (1, 2), (1, 6), (2, 3), (3, 4), (4, 5), (6, 7), (7, 8),
            (8, 9)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 2, 3], [0, 3, 4, 5], [0, 1, 6, 7, 8]]
        let expectedEdges: [[Int]] = [[0, 4, 6, 1], [1, 7, 8, 2], [0, 5, 9, 10, 3]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-107 cycleBasis() has 4 cycles: NetworkX disconnected, add_cycle(\"ABC\") (nxb#4)")
    func cycleBasis107() {
        // 0-1 0-3 0-5 0-8 1-2 1-6 2-3 3-4 4-5 6-7 7-8 8-9 A-B B-C C-A
        let pairs: [(String, String)] = [
            ("0", "1"), ("0", "3"), ("0", "5"), ("0", "8"), ("1", "2"), ("1", "6"), ("2", "3"),
            ("3", "4"), ("4", "5"), ("6", "7"), ("7", "8"), ("8", "9"), ("A", "B"), ("B", "C"),
            ("C", "A")
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[String]] = [
            ["0", "1", "2", "3"], ["0", "3", "4", "5"], ["0", "1", "6", "7", "8"], ["A", "B", "C"]
        ]
        let expectedEdges: [[Int]] = [[0, 4, 6, 1], [1, 7, 8, 2], [0, 5, 9, 10, 3], [12, 13, 14]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-108 cycleBasis() has 4 cycles: NetworkX test_cycle_basis_self_loop (nxb#4)")
    func cycleBasis108() {
        // NetworkX sorted: [0], [0,1,2], [0,2,3], [0,2,6]
        // [0,1,2,3,6] 0-1 0-3 0-0 0-6 0-2 1-2 2-3 2-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 0), (0, 6), (0, 2), (1, 2), (2, 3), (2, 6)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 6], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0], [0, 1, 2], [0, 3, 2], [0, 6, 2]]
        let expectedEdges: [[Int]] = [[2], [0, 5, 4], [1, 6, 4], [3, 7, 4]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-109 cycleBasis() has 2 cycles: rustworkx test_cycle_basis (nxb#2)")
    func cycleBasis109() {
        // rustworkx sorted: [0,1,2,3], [0,3,4,5]
        // [0..5] 0-1 0-3 0-5 1-2 2-3 3-4 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ... 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 2, 3], [0, 3, 4, 5]]
        let expectedEdges: [[Int]] = [[0, 3, 4, 1], [1, 5, 6, 2]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-110 cycleBasis() has 4 cycles: rustworkx test_self_loop (nxb#4)")
    func cycleBasis110() {
        // [0..9] 0-1 0-3 0-5 0-8 1-2 1-6 2-3 3-4 4-5 6-7 7-8 8-9 1-1
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 3), (0, 5), (0, 8), (1, 2), (1, 6), (2, 3), (3, 4), (4, 5), (6, 7), (7, 8),
            (8, 9), (1, 1)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 2, 3], [0, 3, 4, 5], [0, 1, 6, 7, 8], [1]]
        let expectedEdges: [[Int]] = [[0, 4, 6, 1], [1, 7, 8, 2], [0, 5, 9, 10, 3], [12]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-111 cycleBasis() has 7 cycles: JGraphT testPatonCycleBasis1")
    func cycleBasis111() {
        // JGraphT's Paton basis has total length 44; this breadth-first one 41 (7, 7, 7, 4, 6, 3, 7): bases differ by forest
        // 1-2 1-3 1-4 1-12 3-5 3-6 12-13 6-7 6-8 13-14 7-9 8-10 14-15 10-11 2-11 5-4 5-9 9-10 9-11 10-14 11-15
        let pairs: [(Int, Int)] = [
            (1, 2), (1, 3), (1, 4), (1, 12), (3, 5), (3, 6), (12, 13), (6, 7), (6, 8), (13, 14),
            (7, 9), (8, 10), (14, 15), (10, 11), (2, 11), (5, 4), (5, 9), (9, 10), (9, 11), (10, 14),
            (11, 15)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [
            [1, 2, 11, 9, 7, 6, 3], [1, 2, 11, 10, 8, 6, 3], [1, 2, 11, 15, 14, 13, 12], [1, 3, 5, 4],
            [1, 2, 11, 9, 5, 3], [9, 10, 11], [1, 2, 11, 10, 14, 13, 12]
        ]
        let expectedEdges: [[Int]] = [
            [0, 14, 18, 10, 7, 5, 1], [0, 14, 13, 11, 8, 5, 1], [0, 14, 20, 12, 9, 6, 3],
            [1, 4, 15, 2], [0, 14, 18, 16, 4, 1], [17, 13, 18], [0, 14, 13, 19, 9, 6, 3]
        ]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-112 cycleBasis() has 3 cycles: JGraphT testPatonCycleBasis")
    func cycleBasis112() {
        // 1-2 1-3 2-4 2-5 3-6 3-7 4-5 6-7 4-6
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 4), (2, 5), (3, 6), (3, 7), (4, 5), (6, 7), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[2, 4, 5], [3, 6, 7], [1, 2, 4, 6, 3]]
        let expectedEdges: [[Int]] = [[2, 6, 3], [4, 7, 5], [0, 2, 8, 4, 1]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-113 cycleBasis() has 3 cycles: K₄")
    func cycleBasis113() {
        // Breadth-first from 0: every cycle a triangle through 0
        // K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 2], [0, 1, 3], [0, 2, 3]]
        let expectedEdges: [[Int]] = [[0, 3, 1], [0, 4, 2], [1, 5, 2]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-114 cycleBasis() has 6 cycles: Petersen")
    func basisCount114() {
        // 15 − 10 + 1
        // nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cycleBasis().count == 6)
    }

    @Test("CY-115 cycleBasis() has 6 cycles: JGraphT grid")
    func cycleBasis115() {
        // grid(3,4)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9),
            (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 11, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [
            [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [0, 1, 5, 9, 8, 4], [1, 2, 6, 10, 9, 5],
            [2, 3, 7, 11, 10, 6]
        ]
        let expectedEdges: [[Int]] = [
            [0, 3, 7, 1], [2, 5, 9, 3], [4, 6, 11, 5], [0, 3, 10, 14, 8, 1], [2, 5, 12, 15, 10, 3],
            [4, 6, 13, 16, 12, 5]
        ]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-116 cycleBasis() is empty: tree")
    func cycleBasis116() {
        // P(0..6) 3-7 7-8
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (3, 7), (7, 8)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        #expect(basis.isEmpty)
    }

    @Test("CY-117 cycleBasis() has 2 cycles: NetworkX test_cycle_basis_ordered (gh-6654)")
    func cycleBasis117() {
        // [0..7] 0-1 0-4 1-2 2-3 3-4 3-7 4-5 5-6 6-7
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (2, 3), (3, 4), (3, 7), (4, 5), (5, 6), (6, 7)]
        let graph = ReferencePseudograph(vertices: 0 ... 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 2, 3, 4], [3, 4, 5, 6, 7]]
        let expectedEdges: [[Int]] = [[0, 2, 3, 4, 1], [4, 6, 7, 8, 5]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-118 cycleBasis() has 4 cycles: grid, rows reversed")
    func cycleBasis118() {
        // The forest follows incidence order: compare CY-122
        // grid(3,3) ~rev
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7),
            (7, 8)
        ]
        let graph = ReorderedPseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, rows: .reversed)
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 4, 3], [0, 1, 2, 5, 4, 3], [3, 4, 7, 6], [3, 4, 5, 8, 7, 6]]
        let expectedEdges: [[Int]] = [[0, 3, 5, 1], [0, 2, 4, 7, 5, 1], [5, 8, 10, 6], [5, 7, 9, 11, 10, 6]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-119 cycleBasis() has 3 cycles: everything at once")
    func cycleBasis119() {
        // One cycle per non-tree edge, ascending position: a triangle, the 2-cycle, the loop
        // 0-1 1-2 2-0 0-1 2-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 1), (2, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 2], [0, 1], [2]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [0, 3], [4]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-120 cycleBasis() is [A,B,C]/[0,1,2]: string vertices")
    func cycleBasis120() {
        // A-B B-C C-A C-D
        let pairs: [(String, String)] = [("A", "B"), ("B", "C"), ("C", "A"), ("C", "D")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[String]] = [["A", "B", "C"]]
        let expectedEdges: [[Int]] = [[0, 1, 2]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-121 cycleBasis() has 6 cycles: wheel")
    func cycleBasis121() {
        // W(0;1..6)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6),
            (6, 1)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 6], [0, 1, 6]]
        let expectedEdges: [[Int]] = [[0, 6, 1], [1, 7, 2], [2, 8, 3], [3, 9, 4], [4, 10, 5], [0, 11, 5]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-122 cycleBasis() has 4 cycles: grid")
    func cycleBasis122() {
        // grid(3,3)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7),
            (7, 8)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 1, 4, 3], [1, 2, 5, 4], [0, 1, 4, 7, 6, 3], [1, 2, 5, 8, 7, 4]]
        let expectedEdges: [[Int]] = [[0, 3, 5, 1], [2, 4, 7, 3], [0, 3, 8, 10, 6, 1], [2, 4, 9, 11, 8, 3]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }

    @Test("CY-123 cycleBasis() has 4 cycles: not every basis is fundamental: NetworkX cycle_basis (Paton) gives [0,3,4], [2,3,4], [0,1,3], [0,2,4], and [0,3,4] has no edge of its own (nxb#4)")
    func cycleBasis123() {
        // Ours: each cycle holds exactly one non-tree edge, its own. JGraphT documents Paton's output as "weakly fundamental"
        // [0..4] 0-4 0-3 0-2 0-1 1-3 2-4 2-3 3-4
        let pairs: [(Int, Int)] = [(0, 4), (0, 3), (0, 2), (0, 1), (1, 3), (2, 4), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ... 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let basis = graph.cycleBasis()
        let expectedVertices: [[Int]] = [[0, 3, 1], [0, 4, 2], [0, 3, 2], [0, 4, 3]]
        let expectedEdges: [[Int]] = [[1, 4, 3], [0, 5, 2], [1, 6, 2], [0, 7, 1]]
        #expect(basis.map(\.vertices) == expectedVertices)
        #expect(basis.map(\.edges) == expectedEdges)
    }
}
