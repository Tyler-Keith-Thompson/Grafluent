// §D: `Graph.simpleCycles()`: every simple cycle once, in canonical form (its least vertex first,
// leaving it through the lesser of its two edges there, by position), emitted by least vertex and
// then lexicographically by each edge's offset in its vertex's `incidentEdges` row. Graphs from
// NetworkX, igraph and Boost and the classic families, written as the catalog writes them on the
// `ReferencePseudograph`, so positions are exact. Expected values come from the catalog's
// reference (`ref.py`). Case IDs (CY-nnn) refer to the catalog; see README.md.

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

@Suite("Undirected simple cycles")
struct UndirectedSimpleCycleTests {
    @Test("CY-300 simpleCycles() is [0,1,2,3,4,5,6,7]/[0,1,2,3,4,5,6,7]: NetworkX test_simple_cycles_graph")
    func simpleCycles300() {
        // C(0..7)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7]]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-301 simpleCycles() is [0,1,2,3,4,5,6,7]/[0,2,3,4,6,8,9,1]: the same with pendant paths")
    func simpleCycles301() {
        // [0,1,2,3,4,5,6,7,-1,-2,-3,-4] 0-1 0-7 1-2 2-3 3-4 3--2 4-5 4--1 5-6 6-7 -2--3 -3--4
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 7), (1, 2), (2, 3), (3, 4), (3, -2), (4, 5), (4, -1), (5, 6), (6, 7), (-2, -3),
            (-3, -4)
        ]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, -1, -2, -3, -4], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7]]
        let expectedEdges: [[Int]] = [[0, 2, 3, 4, 6, 8, 9, 1]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-302 simpleCycles(): 2 cycles in order: plus cycle_graph(8..15)")
    func simpleCycles302() {
        // [0,1,2,3,4,5,6,7,-1,-2,-3,-4,8,9,10,11,12,13,14,15] 0-1 0-7 1-2 2-3 3-4 3--2 4-5 4--1 5-6 6-7 -2--3 -3--4 8-9 8-15 9-10 10-11 11-12 12-13 13-14 14-15
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 7), (1, 2), (2, 3), (3, 4), (3, -2), (4, 5), (4, -1), (5, 6), (6, 7), (-2, -3),
            (-3, -4), (8, 9), (8, 15), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15)
        ]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, -1, -2, -3, -4, 8, 9, 10, 11, 12, 13, 14, 15], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7], [8, 9, 10, 11, 12, 13, 14, 15]]
        let expectedEdges: [[Int]] = [[0, 2, 3, 4, 6, 8, 9, 1], [12, 14, 15, 16, 17, 18, 19, 13]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-303 simpleCycles(): 6 cycles in order: plus cycle_graph(4..11) (nx#6)")
    func simpleCycles303() {
        // NetworkX lists the six by vertices
        // [0,1,2,3,4,5,6,7,-1,-2,-3,-4,8,9,10,11,12,13,14,15] 0-1 0-7 1-2 2-3 3-4 3--2 4-5 4--1 4-11 5-6 6-7 7-8 -2--3 -3--4 8-9 8-15 9-10 10-11 11-12 12-13 13-14 14-15
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 7), (1, 2), (2, 3), (3, 4), (3, -2), (4, 5), (4, -1), (4, 11), (5, 6), (6, 7),
            (7, 8), (-2, -3), (-3, -4), (8, 9), (8, 15), (9, 10), (10, 11), (11, 12), (12, 13),
            (13, 14), (14, 15)
        ]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, -1, -2, -3, -4, 8, 9, 10, 11, 12, 13, 14, 15], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 1, 2, 3, 4, 5, 6, 7], [0, 1, 2, 3, 4, 11, 10, 9, 8, 7],
            [0, 1, 2, 3, 4, 11, 12, 13, 14, 15, 8, 7], [4, 5, 6, 7, 8, 9, 10, 11],
            [4, 5, 6, 7, 8, 15, 14, 13, 12, 11], [8, 9, 10, 11, 12, 13, 14, 15]
        ]
        let expectedEdges: [[Int]] = [
            [0, 2, 3, 4, 6, 9, 10, 1], [0, 2, 3, 4, 8, 17, 16, 14, 11, 1],
            [0, 2, 3, 4, 8, 18, 19, 20, 21, 15, 11, 1], [6, 9, 10, 11, 14, 16, 17, 8],
            [6, 9, 10, 11, 15, 21, 20, 19, 18, 8], [14, 16, 17, 18, 19, 20, 21, 15]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-304 simpleCycles() emits 20: NetworkX \"basis size 5\" figure (nx#20)")
    func count304() {
        // 2⁵ − 1 − 11 disjoint combinations
        // [0..15] 0-1 0-11 1-2 2-3 2-13 2-14 3-4 4-5 4-14 4-15 5-6 6-7 7-8 8-9 8-12 8-15 9-10 10-11 10-12 10-13
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 11), (1, 2), (2, 3), (2, 13), (2, 14), (3, 4), (4, 5), (4, 14), (4, 15),
            (5, 6), (6, 7), (7, 8), (8, 9), (8, 12), (8, 15), (9, 10), (10, 11), (10, 12), (10, 13)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 15, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 20)
    }

    @Test("CY-305 simpleCycles() emits 0: NetworkX A002807")
    func count305() {
        // K₀
        // []
        let graph = ReferencePseudograph<Int>(edges: [])
        #expect(Array(graph.simpleCycles()).count == 0)
    }

    @Test("CY-306 simpleCycles() emits 0")
    func count306() {
        // K(1)
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(Array(graph.simpleCycles()).count == 0)
    }

    @Test("CY-307 simpleCycles() emits 0")
    func count307() {
        // K(2)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 0)
    }

    @Test("CY-308 simpleCycles() emits 1")
    func count308() {
        // K(3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 1)
    }

    @Test("CY-309 simpleCycles() emits 7")
    func count309() {
        // K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 7)
    }

    @Test("CY-310 simpleCycles() emits 37: NetworkX A002807; igraph complete DAG under ALL (ig#37)")
    func count310() {
        // K(5): every pair u < v, lexicographic
        let n = 5
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }
        let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 37)
    }

    @Test("CY-311 simpleCycles() emits 197")
    func count311() {
        // K(6): every pair u < v, lexicographic
        let n = 6
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }
        let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 197)
    }

    @Test("CY-312 simpleCycles() emits 1172")
    func count312() {
        // K(7): every pair u < v, lexicographic
        let n = 7
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }
        let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 1172)
    }

    @Test("CY-313 simpleCycles() emits 1: igraph undirected ring")
    func count313() {
        // C(0..9)
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 0)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 1)
    }

    @Test("CY-314 simpleCycles() emits 0: igraph undirected star")
    func count314() {
        // S(0;1..6)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 0)
    }

    @Test("CY-315 simpleCycles() emits 1: igraph ring ∪ star")
    func count315() {
        // C(0..9) S(10;11..16)
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 0), (10, 11),
            (10, 12), (10, 13), (10, 14), (10, 15), (10, 16)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 1)
    }

    @Test("CY-316 simpleCycles() emits 1: igraph ring ∪ star plus 7–13")
    func count316() {
        // C(0..9) S(10;11..16) 7-13
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 0), (10, 11),
            (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (7, 13)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 1)
    }

    @Test("CY-317 simpleCycles() emits 0: igraph kary_tree(20, 3)")
    func count317() {
        // kary(20,3)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 4), (1, 5), (1, 6), (2, 7), (2, 8), (2, 9), (3, 10), (3, 11),
            (3, 12), (4, 13), (4, 14), (4, 15), (5, 16), (5, 17), (5, 18), (6, 19)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 0)
    }

    @Test("CY-318 simpleCycles() emits 73: igraph undirected wheel of 10 (ig#73)")
    func count318() {
        // igraph's comment: 9 of 10 vertices, 10 of 9, 9 of each length 8 … 3
        // W(0;1..9)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (1, 2), (2, 3),
            (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 1)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 73)
    }

    @Test("CY-319 simpleCycles(): 13 cycles in order: igraph \"envelope\" (ig#13)")
    func simpleCycles319() {
        // 0-1 0-3 0-4 1-2 1-3 2-3 2-4 3-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 4), (1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 1, 2, 3], [0, 1, 2, 3, 4], [0, 1, 2, 4], [0, 1, 2, 4, 3], [0, 1, 3], [0, 1, 3, 2, 4],
            [0, 1, 3, 4], [0, 3, 1, 2, 4], [0, 3, 2, 4], [0, 3, 4], [1, 2, 3], [1, 2, 4, 3], [3, 2, 4]
        ]
        let expectedEdges: [[Int]] = [
            [0, 3, 5, 1], [0, 3, 5, 7, 2], [0, 3, 6, 2], [0, 3, 6, 7, 1], [0, 4, 1], [0, 4, 5, 6, 2],
            [0, 4, 7, 2], [1, 4, 3, 6, 2], [1, 5, 6, 2], [1, 7, 2], [3, 5, 4], [3, 6, 7, 4], [5, 6, 7]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-320 simpleCycles(): 6 cycles in order: igraph \"boat\" (ig#6)")
    func simpleCycles320() {
        // 0-2 0-4 1-2 1-3 1-4 2-3 2-4
        let pairs: [(Int, Int)] = [(0, 2), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 2, 1, 4], [0, 2, 3, 1, 4], [0, 2, 4], [2, 1, 3], [2, 1, 4], [2, 3, 1, 4]
        ]
        let expectedEdges: [[Int]] = [
            [0, 2, 4, 1], [0, 5, 3, 4, 1], [0, 6, 1], [2, 3, 5], [2, 4, 6], [5, 3, 4, 6]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-321 simpleCycles(): 3 cycles in order: igraph \"house\" (ig#3)")
    func simpleCycles321() {
        // 0-3 0-4 1-2 1-3 1-4 2-3
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 3, 1, 4], [0, 3, 2, 1, 4], [3, 1, 2]]
        let expectedEdges: [[Int]] = [[0, 3, 4, 1], [0, 5, 2, 4, 1], [3, 2, 5]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-322 simpleCycles() emits 14: igraph \"prism\" (ig#14)")
    func count322() {
        // 0-1 0-3 0-5 1-4 1-5 2-3 2-4 2-5 3-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 5), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 14)
    }

    @Test("CY-323 simpleCycles() emits 89: igraph \"7 vertices\" (ig#89)")
    func count323() {
        // 0-1 0-4 0-5 0-6 1-2 1-3 1-5 1-6 2-3 2-6 3-4 3-5 3-6 4-5
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 5), (1, 6), (2, 3), (2, 6), (3, 4),
            (3, 5), (3, 6), (4, 5)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 89)
    }

    @Test("CY-324 simpleCycles() emits 295: igraph \"shooting star\" (ig#295)")
    func count324() {
        // 18 + 43 + 78 + 96 + 60
        // 0-1 0-2 0-3 0-4 0-6 1-2 1-3 1-4 1-5 1-6 2-3 2-4 2-6 3-4 3-5 4-6 5-6
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3),
            (2, 4), (2, 6), (3, 4), (3, 5), (4, 6), (5, 6)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 295)
    }

    @Test("CY-325 simpleCycles(): 3 cycles in order: igraph \"Mickey\" (ig#3)")
    func simpleCycles325() {
        // [0..6] 0-1 1-2 2-0 0-0 0-3 3-4 4-5 5-0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 0), (0, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: 0 ... 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2], [0], [0, 3, 4, 5]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [3], [4, 5, 6, 7]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-326 simpleCycles(): 3 cycles in order: igraph \"Mickey2\" (ig#3)")
    func simpleCycles326() {
        // [0..6] 0-1 1-2 2-0 1-1 0-3 3-4 4-5 5-0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 1), (0, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: 0 ... 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2], [0, 3, 4, 5], [1]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [4, 5, 6, 7], [3]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-327 simpleCycles(): 6 cycles in order: igraph \"Mickey3\" (ig#6 nx#5)")
    func simpleCycles327() {
        // Two loops at 5 are two cycles; NetworkX merges them
        // [0..6] 0-1 1-2 2-0 0-3 3-4 4-5 5-0 1-1 5-6 6-5 5-5 5-5
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 5), (5, 0), (1, 1), (5, 6), (6, 5), (5, 5),
            (5, 5)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2], [0, 3, 4, 5], [1], [5, 6], [5], [5]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [3, 4, 5, 6], [7], [8, 9], [10], [11]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-328 simpleCycles(): 5 cycles in order: Boost hawick_circuits.cpp undirected ER(20, 0.1) (bh#30 bhu#27 bt#8)")
    func simpleCycles328() {
        // Boost reads an undirected graph as two arcs per edge: every edge is a circuit, every cycle twice (CY-415)
        // [0..19] 0-1 12-17 19-3 10-7 5-14 1-11 11-16 11-10 17-19 14-19 5-8 17-13 18-19 3-17 18-5 18-8 6-10 7-15 13-10 11-1
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 19, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [1, 11], [3, 19, 17], [5, 14, 19, 18], [5, 14, 19, 18, 8], [5, 8, 18]
        ]
        let expectedEdges: [[Int]] = [[5, 19], [2, 8, 13], [4, 9, 12, 14], [4, 9, 12, 15, 10], [10, 15, 14]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-329 simpleCycles(): 6 cycles in order: Boost tiernan_all_cycles.cpp undirected, seed 42 (bh#32 bhu#20 bt#2)")
    func simpleCycles329() {
        // [0..19] 0-11 5-8 13-19 12-14 0-4 15-10 9-0 17-9 16-15 10-11 9-17 15-8 17-7 18-0 1-6 6-8 19-12 12-3 18-17 17-18
        let pairs: [(Int, Int)] = [
            (0, 11), (5, 8), (13, 19), (12, 14), (0, 4), (15, 10), (9, 0), (17, 9), (16, 15), (10, 11),
            (9, 17), (15, 8), (17, 7), (18, 0), (1, 6), (6, 8), (19, 12), (12, 3), (18, 17), (17, 18)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 19, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 9, 17, 18], [0, 9, 17, 18], [0, 9, 17, 18], [0, 9, 17, 18], [9, 17], [17, 18]
        ]
        let expectedEdges: [[Int]] = [
            [6, 7, 18, 13], [6, 7, 19, 13], [6, 10, 18, 13], [6, 10, 19, 13], [7, 10], [18, 19]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-330 simpleCycles(): 7 cycles in order: K₄: the canonical form and order")
    func simpleCycles330() {
        // K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 1, 2], [0, 1, 2, 3], [0, 1, 3], [0, 1, 3, 2], [0, 2, 1, 3], [0, 2, 3], [1, 2, 3]
        ]
        let expectedEdges: [[Int]] = [
            [0, 3, 1], [0, 3, 5, 2], [0, 4, 2], [0, 4, 5, 1], [1, 3, 4, 2], [1, 5, 2], [3, 5, 4]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-331 simpleCycles(): 7 cycles in order: K₄, rows reversed")
    func simpleCycles331() {
        // The same seven cycles, the same canonical forms, another order
        // K(4) ~rev
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReorderedPseudograph(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, rows: .reversed)
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 2, 3], [0, 2, 1, 3], [0, 1, 3, 2], [0, 1, 3], [0, 1, 2, 3], [0, 1, 2], [1, 2, 3]
        ]
        let expectedEdges: [[Int]] = [
            [1, 5, 2], [1, 3, 4, 2], [0, 4, 5, 1], [0, 4, 2], [0, 3, 5, 2], [0, 3, 1], [3, 5, 4]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-332 simpleCycles(): 3 cycles in order: C₄ with a chord")
    func simpleCycles332() {
        // C(0..3) 0-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3], [0, 1, 2], [0, 3, 2]]
        let expectedEdges: [[Int]] = [[0, 1, 2, 3], [0, 1, 4], [3, 2, 4]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-333 simpleCycles(): 2 cycles in order: bowtie")
    func simpleCycles333() {
        // C(0,1,2) C(0,3,4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2], [0, 3, 4]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-334 simpleCycles() emits 6: ladder (rungs choose 2)")
    func count334() {
        // grid(2,4)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (5, 6), (6, 7)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 6)
    }

    @Test("CY-335 simpleCycles() emits 13: 3 × 3 grid")
    func count335() {
        // grid(3,3)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7),
            (7, 8)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 13)
    }

    @Test("CY-336 simpleCycles() emits 57: Petersen")
    func count336() {
        // nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 57)
    }

    @Test("CY-337 simpleCycles() emits 15: complete bipartite K₃,₃")
    func count337() {
        // KB(0..2;3..5)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 15)
    }

    @Test("CY-338 simpleCycles() emits 43: igraph directed wheel under ALL (ig#43)")
    func count338() {
        // W(0;1..7)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (2, 3), (3, 4), (4, 5),
            (5, 6), (6, 7), (7, 1)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.simpleCycles()).count == 43)
    }

    @Test("CY-339 simpleCycles() is [A,B,C]/[0,1,2]: string vertices")
    func simpleCycles339() {
        // A-B B-C C-A
        let pairs: [(String, String)] = [("A", "B"), ("B", "C"), ("C", "A")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[String]] = [["A", "B", "C"]]
        let expectedEdges: [[Int]] = [[0, 1, 2]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-340 simpleCycles(): 2 cycles in order: least vertex by vertices order")
    func simpleCycles340() {
        // 3 comes first in vertices
        // C(3,4,5) C(0,1,2)
        let pairs: [(Int, Int)] = [(3, 4), (4, 5), (5, 3), (0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[3, 4, 5], [0, 1, 2]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-341 simpleCycles(): 3 cycles in order: cycles through a cut vertex")
    func simpleCycles341() {
        // C(0,1,2) C(2,3,4) C(4,5,6)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2], [2, 3, 4], [4, 5, 6]]
        let expectedEdges: [[Int]] = [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-342 simpleCycles(): 2 cycles in order: NetworkX test_chordless_cycles_graph graph")
    func simpleCycles342() {
        // 0-1 0-4 1-2 2-3 3-4 4-5 4-11 5-6 6-7 7-8 8-9 9-10 10-11
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (2, 3), (3, 4), (4, 5), (4, 11), (5, 6), (6, 7), (7, 8), (8, 9),
            (9, 10), (10, 11)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [[0, 1, 2, 3, 4], [4, 5, 6, 7, 8, 9, 10, 11]]
        let expectedEdges: [[Int]] = [[0, 2, 3, 4, 1], [5, 7, 8, 9, 10, 11, 12, 6]]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }

    @Test("CY-343 simpleCycles(): 6 cycles in order: the same plus 7–3")
    func simpleCycles343() {
        // 0-1 0-4 1-2 2-3 3-4 4-5 4-11 5-6 6-7 7-8 8-9 9-10 10-11 7-3
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (2, 3), (3, 4), (4, 5), (4, 11), (5, 6), (6, 7), (7, 8), (8, 9),
            (9, 10), (10, 11), (7, 3)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cycles = Array(graph.simpleCycles())
        let expectedVertices: [[Int]] = [
            [0, 1, 2, 3, 4], [0, 1, 2, 3, 7, 6, 5, 4], [0, 1, 2, 3, 7, 8, 9, 10, 11, 4],
            [4, 3, 7, 6, 5], [4, 3, 7, 8, 9, 10, 11], [4, 5, 6, 7, 8, 9, 10, 11]
        ]
        let expectedEdges: [[Int]] = [
            [0, 2, 3, 4, 1], [0, 2, 3, 13, 8, 7, 5, 1], [0, 2, 3, 13, 9, 10, 11, 12, 6, 1],
            [4, 13, 8, 7, 5], [4, 13, 9, 10, 11, 12, 6], [5, 7, 8, 9, 10, 11, 12, 6]
        ]
        #expect(cycles.map(\.vertices) == expectedVertices)
        #expect(cycles.map(\.edges) == expectedEdges)
    }
}
