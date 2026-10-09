// §D: core numbers, degeneracy, the degeneracy ordering, k-cores and k-shells (CQ-301 – CQ-349), all
// on the simple graph: a parallel pair or a loop adds nothing (CQ-328 – CQ-333; igraph counts them,
// NetworkX raises). Core numbers are checked by index, by vertex and on `graph.directed.undirected`;
// the degeneracy ordering exactly (api.md pins Batagelj–Zaversnik's removal order: a stable counting
// sort by degree, neighbours in row order), together with its defining property (at most core(v)
// neighbours after each v, core numbers nondecreasing along it). `~rev` rows use a conformer private
// to this file whose rows are reversed. Every literal is a catalog cell (`ref.py`: api.md's model,
// peeling, NetworkX 3.7 `core_number`). Case IDs (CQ-nnn) refer to the catalog; see README.md.

import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

/// An undirected pseudograph whose incidence rows are reversed (the catalog's `~rev`): each row
/// is built in position order (a self-loop twice), then reversed. Vertex and edge indices are
/// positions.
private struct ReversedRowsPseudograph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [UndirectedEdge<Vertex>]) {
        let inOrder = ReferencePseudograph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { Array(inOrder.incidentEdges(of: $0).reversed()) }
    }

    init(edges: [UndirectedEdge<Vertex>]) {
        self.init(vertices: [], edges: edges)
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

@Suite("Core numbers and degeneracy")
struct CoreNumberTests {
    @Test("CQ-301 U(K(0..2), 2-3).coreNumbers is [2, 2, 2, 1]")
    func coreNumbers301() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [2, 2, 2, 1]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-302 U(K(0..2), 2-3).degeneracy is #2")
    func degeneracy302() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 2)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 2)
        #expect(graph.cliqueNumber() <= 2 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 2)
    }

    @Test("CQ-303 U(K(0..2), 2-3).degeneracyOrdering is [3, 0, 1, 2]")
    func degeneracyOrdering303() {
        // U: K(0..2), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [3, 0, 1, 2]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-304 U(P(0..4)).coreNumbers is [1, 1, 1, 1, 1]")
    func coreNumbers304() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 1, 1, 1, 1]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-305 U(P(0..4)).degeneracy is #1")
    func degeneracy305() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 1)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 1)
        #expect(graph.cliqueNumber() <= 1 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 1)
    }

    @Test("CQ-306 U(P(0..4)).degeneracyOrdering is [0, 4, 1, 3, 2]")
    func degeneracyOrdering306() {
        // U: P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 4, 1, 3, 2]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-307 U(C(0..4)).coreNumbers is [2, 2, 2, 2, 2]")
    func coreNumbers307() {
        // U: C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [2, 2, 2, 2, 2]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-308 U(C(0..4)).degeneracy is #2")
    func degeneracy308() {
        // U: C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 2)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 2)
        #expect(graph.cliqueNumber() <= 2 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 2)
    }

    @Test("CQ-309 U(C(0..4)).degeneracyOrdering is [0, 1, 2, 3, 4]")
    func degeneracyOrdering309() {
        // U: C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2, 3, 4]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-310 U(S(0;1..4)).coreNumbers is [1, 1, 1, 1, 1]")
    func coreNumbers310() {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 1, 1, 1, 1]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-311 U(S(0;1..4)).degeneracy is #1")
    func degeneracy311() {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 1)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 1)
        #expect(graph.cliqueNumber() <= 1 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 1)
    }

    @Test("CQ-312 U(S(0;1..4)).degeneracyOrdering is [1, 2, 3, 4, 0]")
    func degeneracyOrdering312() {
        // U: S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 2, 3, 4, 0]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-313 U(K(4), 3-4, 4-5, 5-6, 6-4).coreNumbers is [3, 3, 3, 3, 2, 2, 2]: K₄ with a pendant triangle")
    func coreNumbers313() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [3, 3, 3, 3, 2, 2, 2]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-314 U(K(4), 3-4, 4-5, 5-6, 6-4).degeneracy is #3")
    func degeneracy314() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 3)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 3)
        #expect(graph.cliqueNumber() <= 3 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 3)
    }

    @Test("CQ-315 U(K(4), 3-4, 4-5, 5-6, 6-4).degeneracyOrdering is [5, 6, 4, 1, 2, 0, 3]")
    func degeneracyOrdering315() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [5, 6, 4, 1, 2, 0, 3]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-316 U(K(0..2), 1-3, 2-3).coreNumbers is [2, 2, 2, 2]: Diamond")
    func coreNumbers316() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [2, 2, 2, 2]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-317 U(K(0..2), 1-3, 2-3).degeneracy is #2")
    func degeneracy317() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 2)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 2)
        #expect(graph.cliqueNumber() <= 2 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 2)
    }

    @Test("CQ-318 U(K(0..2), 1-3, 2-3).degeneracyOrdering is [0, 3, 1, 2]")
    func degeneracyOrdering318() {
        // U: K(0..2), 1-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 3, 1, 2]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-319 U(nx(karate_club)).coreNumbers is listed below: Degeneracy 4 (NetworkX, igraph)")
    func coreNumbers319() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [
            4, 4, 4, 4, 3, 3, 3, 4, 4, 2, 3, 1, 2, 4, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 2, 3, 3, 3, 4,
            3, 4, 4
        ]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-320 U(nx(karate_club)).degeneracy is #4")
    func degeneracy320() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 4)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 4)
        #expect(graph.cliqueNumber() <= 4 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 4)
    }

    @Test("CQ-321 U(nx(karate_club)).degeneracyOrdering is listed below")
    func degeneracyOrdering321() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [
            11, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 4, 10, 19, 24, 25, 28, 5, 6, 29, 27, 31, 23,
            30, 7, 32, 33, 8, 1, 3, 13, 0, 2
        ]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-322 U(nx(petersen)).coreNumbers is [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]: 3-regular")
    func coreNumbers322() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-323 U(nx(petersen)).degeneracy is #3")
    func degeneracy323() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 3)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 3)
        #expect(graph.cliqueNumber() <= 3 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 3)
    }

    @Test("CQ-324 U(nx(petersen)).degeneracyOrdering is [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]")
    func degeneracyOrdering324() {
        // U: nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-325 U(grid(3,4)).coreNumbers is [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]")
    func coreNumbers325() {
        // U: grid(3,4)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9),
            (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-326 U(grid(3,4)).degeneracy is #2")
    func degeneracy326() {
        // U: grid(3,4)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9),
            (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 2)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 2)
        #expect(graph.cliqueNumber() <= 2 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 2)
    }

    @Test("CQ-327 U(grid(3,4)).degeneracyOrdering is [0, 3, 8, 11, 1, 4, 2, 7, 9, 10, 5, 6]")
    func degeneracyOrdering327() {
        // U: grid(3,4)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9),
            (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 3, 8, 11, 1, 4, 2, 7, 9, 10, 5, 6]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-328 U([0, 1] 0-1, 0-1).coreNumbers is [1, 1]: Parallel pair: core 1 (igraph `coreness`: 2)")
    func coreNumbers328() {
        // U: [0, 1] 0-1, 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 1]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-329 U([0, 1] 0-1, 0-1).degeneracy is #1")
    func degeneracy329() {
        // U: [0, 1] 0-1, 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 1)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 1)
        #expect(graph.cliqueNumber() <= 1 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 1)
    }

    @Test("CQ-330 U([0, 1] 0-1, 0-1).degeneracyOrdering is [0, 1]")
    func degeneracyOrdering330() {
        // U: [0, 1] 0-1, 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-331 U([0, 1] 0-1, 0-0, 1-1).coreNumbers is [1, 1]: Loops: core 1 (igraph: 3; NetworkX raises)")
    func coreNumbers331() {
        // U: [0, 1] 0-1, 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 1]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-332 U([0, 1] 0-1, 0-0, 1-1).degeneracy is #1")
    func degeneracy332() {
        // U: [0, 1] 0-1, 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 1)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 1)
        #expect(graph.cliqueNumber() <= 1 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 1)
    }

    @Test("CQ-333 U([0, 1] 0-1, 0-0, 1-1).degeneracyOrdering is [0, 1]")
    func degeneracyOrdering333() {
        // U: [0, 1] 0-1, 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-334 U(S(0;1..4) ~rev).coreNumbers is [1, 1, 1, 1, 1]")
    func coreNumbers334() {
        // U: S(0;1..4) ~rev
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReversedRowsPseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 1, 1, 1, 1]
        let cores = graph.coreNumbers()
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
        #expect(byVertex == expected)
        #expect(cores.degeneracy == (expected.max() ?? 0))
        let view = graph.directed.undirected.coreNumbers()
        let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("CQ-335 U(S(0;1..4) ~rev).degeneracy is #1")
    func degeneracy335() {
        // U: S(0;1..4) ~rev
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReversedRowsPseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let cores = graph.coreNumbers()
        #expect(cores.degeneracy == 1)
        let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }
        #expect((byIndex.max() ?? 0) == 1)
        #expect(graph.cliqueNumber() <= 1 + 1)
        #expect(graph.directed.undirected.coreNumbers().degeneracy == 1)
    }

    @Test("CQ-336 U(S(0;1..4) ~rev).degeneracyOrdering is [1, 2, 3, 4, 0]")
    func degeneracyOrdering336() {
        // U: S(0;1..4) ~rev
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReversedRowsPseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [1, 2, 3, 4, 0]
        let cores = graph.coreNumbers()
        #expect(cores.degeneracyOrdering == expected)
        #expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)
        // At most its own core number of neighbours after each vertex, and core numbers never decrease.
        for (i, v) in expected.enumerated() {
            let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }
            #expect(later.count <= cores.coreNumber(of: v), "\(v)")
        }
        let coresInOrder = expected.map { cores.coreNumber(of: $0) }
        #expect(coresInOrder == coresInOrder.sorted())
    }

    @Test("CQ-337 U(K(4), 3-4, 4-5, 5-6, 6-4).kCore(0) is [0, 1, 2, 3, 4, 5, 6]")
    func kCore337() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2, 3, 4, 5, 6]
        let cores = graph.coreNumbers()
        #expect(cores.kCore(0) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 0 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(0) == expected)
    }

    @Test("CQ-338 U(K(4), 3-4, 4-5, 5-6, 6-4).kCore(1) is [0, 1, 2, 3, 4, 5, 6]")
    func kCore338() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2, 3, 4, 5, 6]
        let cores = graph.coreNumbers()
        #expect(cores.kCore(1) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 1 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(1) == expected)
    }

    @Test("CQ-339 U(K(4), 3-4, 4-5, 5-6, 6-4).kCore(2) is [0, 1, 2, 3, 4, 5, 6]")
    func kCore339() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2, 3, 4, 5, 6]
        let cores = graph.coreNumbers()
        #expect(cores.kCore(2) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 2 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(2) == expected)
    }

    @Test("CQ-340 U(K(4), 3-4, 4-5, 5-6, 6-4).kCore(3) is [0, 1, 2, 3]")
    func kCore340() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2, 3]
        let cores = graph.coreNumbers()
        #expect(cores.kCore(3) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 3 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(3) == expected)
    }

    @Test("CQ-341 U(K(4), 3-4, 4-5, 5-6, 6-4).kCore(4) is []")
    func kCore341() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = []
        let cores = graph.coreNumbers()
        #expect(cores.kCore(4) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 4 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(4) == expected)
    }

    @Test("CQ-342 U(K(4), 3-4, 4-5, 5-6, 6-4).kCore(5) is []")
    func kCore342() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = []
        let cores = graph.coreNumbers()
        #expect(cores.kCore(5) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 5 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(5) == expected)
    }

    @Test("CQ-343 U(K(4), 3-4, 4-5, 5-6, 6-4).kShell(0) is []")
    func kShell343() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = []
        let cores = graph.coreNumbers()
        #expect(cores.kShell(0) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) == 0 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kShell(0) == expected)
    }

    @Test("CQ-344 U(K(4), 3-4, 4-5, 5-6, 6-4).kShell(1) is []")
    func kShell344() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = []
        let cores = graph.coreNumbers()
        #expect(cores.kShell(1) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) == 1 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kShell(1) == expected)
    }

    @Test("CQ-345 U(K(4), 3-4, 4-5, 5-6, 6-4).kShell(2) is [4, 5, 6]")
    func kShell345() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [4, 5, 6]
        let cores = graph.coreNumbers()
        #expect(cores.kShell(2) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) == 2 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kShell(2) == expected)
    }

    @Test("CQ-346 U(K(4), 3-4, 4-5, 5-6, 6-4).kShell(3) is [0, 1, 2, 3]")
    func kShell346() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2, 3]
        let cores = graph.coreNumbers()
        #expect(cores.kShell(3) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) == 3 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kShell(3) == expected)
    }

    @Test("CQ-347 U(K(4), 3-4, 4-5, 5-6, 6-4).kShell(4) is []")
    func kShell347() {
        // U: K(4), 3-4, 4-5, 5-6, 6-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = []
        let cores = graph.coreNumbers()
        #expect(cores.kShell(4) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) == 4 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kShell(4) == expected)
    }

    @Test("CQ-348 U(nx(karate_club)).kCore(4) is [0, 1, 2, 3, 7, 8, 13, 30, 32, 33]: The main core")
    func kCore348() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2, 3, 7, 8, 13, 30, 32, 33]
        let cores = graph.coreNumbers()
        #expect(cores.kCore(4) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) >= 4 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kCore(4) == expected)
    }

    @Test("CQ-349 U(nx(karate_club)).kShell(1) is [11]")
    func kShell349() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [11]
        let cores = graph.coreNumbers()
        #expect(cores.kShell(1) == expected)
        let byCore = graph.vertices.filter { cores.coreNumber(of: $0) == 1 }
        #expect(byCore == expected)
        #expect(graph.directed.undirected.coreNumbers().kShell(1) == expected)
    }
}
