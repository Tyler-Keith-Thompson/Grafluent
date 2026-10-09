// §C: trees, where every value must equal TreeAlgorithms' (`= TA-nnn` rows: `Tree.center()`,
// `centroid()`, `diameter()`, `diameterPath()`, weighted too); each such row runs Distances on the
// `ReferencePseudograph`, `Tree`'s own member, and Distances on the `Tree` read as a `Graph`
// through a generic function, which must all give the catalog cell. `vertices` order decides
// `center`, `periphery` and `centroid` order (DI-201, DI-250) and the start of `diameterPath`
// (DI-204, DI-251); row order decides the path between fixed endpoints (DI-251 against DI-252,
// DI-253 against DI-254, the `~rev` rows on a conformer private to this file whose rows are
// reversed). Weighted rows use `Int` and `Double` weights, zeros included (DI-229, DI-236). Literals
// are catalog cells. DI-240 (a negative weight) is an exit test in `DistancePreconditionTests.swift`.
// Case IDs (DI-nnn) refer to the catalog; see README.md.

import Distances
import GrafluentTestSupport
import GraphProtocols
import Testing
import TreeAlgorithms
import Trees
import Walks

/// An undirected pseudograph whose incidence rows are not in position order: each row is built in
/// position order (a self-loop twice), then reversed (the catalog's `~rev`). Vertex and edge
/// indices are positions.
private struct ReversedPseudograph<Vertex: Hashable>: Graph {
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

    func incidentEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

@Suite("Trees: agreement with TreeAlgorithms, and tie order")
struct TreeAgreementTests {
    @Test("DI-201 U([4, 2, 7, 1]; 7-2, 2-4, 4-1).center() is [4, 2]: = TA-412: `vertices` order, not value order")
    func center201() throws {
        // U: [4, 2, 7, 1] 7-2, 2-4, 4-1
        let pairs: [(Int, Int)] = [(7, 2), (2, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: [4, 2, 7, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [4, 2])
        #expect(graph.eccentricities().center == [4, 2])
        // TA-412: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [4, 2])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == [4, 2])
    }

    @Test("DI-202 U([4, 2, 7, 1]; 7-2, 2-4, 4-1).periphery() is [7, 1]: `vertices` order")
    func periphery202() {
        // U: [4, 2, 7, 1] 7-2, 2-4, 4-1
        let pairs: [(Int, Int)] = [(7, 2), (2, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: [4, 2, 7, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.periphery() == [7, 1])
        #expect(graph.eccentricities().periphery == [7, 1])
    }

    @Test("DI-203 U([4, 2, 7, 1]; 7-2, 2-4, 4-1).centroid() is [4, 2]: = TA-510")
    func centroid203() throws {
        // U: [4, 2, 7, 1] 7-2, 2-4, 4-1
        let pairs: [(Int, Int)] = [(7, 2), (2, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: [4, 2, 7, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == [4, 2])
        // TA-510: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [4, 2])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.centroid() }
        #expect(onGraph(tree) == [4, 2])
    }

    @Test("DI-204 U([4, 2, 7, 1]; 7-2, 2-4, 4-1).diameterPath() is [7, 2, 4, 1]/[0, 1, 2]: From 7, the first peripheral vertex in `vertices` order")
    func diameterPath204() throws {
        // U: [4, 2, 7, 1] 7-2, 2-4, 4-1
        let pairs: [(Int, Int)] = [(7, 2), (2, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: [4, 2, 7, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [7, 2, 4, 1])
        #expect(path.edges == [0, 1, 2])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-205 U(P(3,1,0,2)).center() is [1, 0]: NetworkX `center(path_graph([3, 1, 0, 2]))` is `[1, 0]` too")
    func center205() {
        // U: [] P(3,1,0,2)
        let pairs: [(Int, Int)] = [(3, 1), (1, 0), (0, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [1, 0])
        #expect(graph.eccentricities().center == [1, 0])
    }

    @Test("DI-206 U(1-2, 1-3, 2-4, 2-5).center() is [1, 2]: = TA-403")
    func center206() throws {
        // U: [] 1-2, 1-3, 2-4, 2-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 4), (2, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [1, 2])
        #expect(graph.eccentricities().center == [1, 2])
        // TA-403: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [1, 2])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == [1, 2])
    }

    @Test("DI-207 U(P(0..4)).center() is [2]: = TA-404")
    func center207() throws {
        // U: [] P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [2])
        #expect(graph.eccentricities().center == [2])
        // TA-404: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [2])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == [2])
    }

    @Test("DI-208 U(P(0..98)).center() is [49]: = TA-405")
    func center208() throws {
        // U: [] P(0..98)
        let pairs: [(Int, Int)] = (0 ..< 98).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [49])
        #expect(graph.eccentricities().center == [49])
        // TA-405: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [49])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == [49])
    }

    @Test("DI-209 U(P(0..99)).center() is [49, 50]: = TA-406")
    func center209() throws {
        // U: [] P(0..99)
        let pairs: [(Int, Int)] = (0 ..< 99).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [49, 50])
        #expect(graph.eccentricities().center == [49, 50])
        // TA-406: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [49, 50])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == [49, 50])
    }

    @Test("DI-210 U(S(0;1..5)).center() is [0]: = TA-407")
    func center210() throws {
        // U: [] S(0;1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [0])
        #expect(graph.eccentricities().center == [0])
        // TA-407: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [0])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == [0])
    }

    @Test("DI-211 U(kary(40,3)).center() is [0]: = TA-408")
    func center211() throws {
        // U: [] kary(40,3)
        let pairs: [(Int, Int)] = (0 ..< 40).flatMap { i -> [(Int, Int)] in (3 * i + 1 ... 3 * i + 3).filter { $0 < 40 }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [0])
        #expect(graph.eccentricities().center == [0])
        // TA-408: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [0])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == [0])
    }

    @Test("DI-212 U(S(0;1..6), P(6,7,8,9,10)).center() is [7]: = TA-409")
    func center212() throws {
        // U: [] S(0;1..6), P(6,7,8,9,10)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (6, 7), (7, 8), (8, 9), (9, 10)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [7])
        #expect(graph.eccentricities().center == [7])
        // TA-409: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [7])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == [7])
    }

    @Test("DI-213 U(S(0;1..6), P(6,7,8,9,10)).centroid() is [0]: = TA-506: the median is not the center")
    func centroid213() throws {
        // U: [] S(0;1..6), P(6,7,8,9,10)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (6, 7), (7, 8), (8, 9), (9, 10)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == [0])
        // TA-506: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [0])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.centroid() }
        #expect(onGraph(tree) == [0])
    }

    @Test("DI-214 U([0..8]; 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8).center() is [0]: = TA-410")
    func center214() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [0])
        #expect(graph.eccentricities().center == [0])
        // TA-410: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [0])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == [0])
    }

    @Test("DI-215 U([0..8]; 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8).centroid() is [1]: = TA-508")
    func centroid215() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == [1])
        // TA-508: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [1])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.centroid() }
        #expect(onGraph(tree) == [1])
    }

    @Test("DI-216 U([0..8]; 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8).diameter() is #6: = TA-608")
    func diameter216() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.diameter() == 6)
        #expect(graph.eccentricities().diameter == 6)
        // TA-608: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.diameter() == 6)
        func onGraph<G: Graph>(_ g: G) -> Int? where G.Edges.Index == Int { g.diameter() }
        #expect(onGraph(tree) == 6)
    }

    @Test("DI-217 U([0..8]; 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8).diameterPath() is [6, 4, 1, 0, 2, 5, 8]/[5, 3, 0, 1, 4, 7]: = TA-609")
    func diameterPath217() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(path.edges == [5, 3, 0, 1, 4, 7])
        #expect(path.length == graph.diameter())
        // TA-609: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treePath = tree.diameterPath()
        #expect(treePath.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(treePath.edges == [5, 3, 0, 1, 4, 7])
        func onGraph<G: Graph>(_ g: G) -> Path<G.Vertex, Int>? where G.Edges.Index == Int { g.diameterPath() }
        let graphPath = try #require(onGraph(tree))
        #expect(graphPath == treePath)
    }

    @Test("DI-218 U([0..8]; 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5).diameterPath() is [6, 4, 1, 0, 2, 5, 8]/[5, 2, 4, 1, 7, 3]: = TA-610: same vertices, other positions")
    func diameterPath218() throws {
        // U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5
        let pairs: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(path.edges == [5, 2, 4, 1, 7, 3])
        #expect(path.length == graph.diameter())
        // TA-610: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treePath = tree.diameterPath()
        #expect(treePath.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(treePath.edges == [5, 2, 4, 1, 7, 3])
        func onGraph<G: Graph>(_ g: G) -> Path<G.Vertex, Int>? where G.Edges.Index == Int { g.diameterPath() }
        let graphPath = try #require(onGraph(tree))
        #expect(graphPath == treePath)
    }

    @Test("DI-219 U(a-b, b-c, b-d, d-e).center() is [b, d]: = TA-411")
    func center219() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == ["b", "d"])
        #expect(graph.eccentricities().center == ["b", "d"])
        // TA-411: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == ["b", "d"])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == ["b", "d"])
    }

    @Test("DI-220 U(a-b, b-c, b-d, d-e).centroid() is [b]: = TA-509")
    func centroid220() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == ["b"])
        // TA-509: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == ["b"])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.centroid() }
        #expect(onGraph(tree) == ["b"])
    }

    @Test("DI-221 U(a-b, b-c, b-d, d-e).diameterPath() is [a, b, d, e]/[0, 2, 3]: = TA-611")
    func diameterPath221() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == ["a", "b", "d", "e"])
        #expect(path.edges == [0, 2, 3])
        #expect(path.length == graph.diameter())
        // TA-611: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treePath = tree.diameterPath()
        #expect(treePath.vertices == ["a", "b", "d", "e"])
        #expect(treePath.edges == [0, 2, 3])
        func onGraph<G: Graph>(_ g: G) -> Path<G.Vertex, Int>? where G.Edges.Index == Int { g.diameterPath() }
        let graphPath = try #require(onGraph(tree))
        #expect(graphPath == treePath)
    }

    @Test("DI-222 U(S(0;1..5)).diameterPath() is [1, 0, 2]/[0, 1]: = TA-607")
    func diameterPath222() throws {
        // U: [] S(0;1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [1, 0, 2])
        #expect(path.edges == [0, 1])
        #expect(path.length == graph.diameter())
        // TA-607: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treePath = tree.diameterPath()
        #expect(treePath.vertices == [1, 0, 2])
        #expect(treePath.edges == [0, 1])
        func onGraph<G: Graph>(_ g: G) -> Path<G.Vertex, Int>? where G.Edges.Index == Int { g.diameterPath() }
        let graphPath = try #require(onGraph(tree))
        #expect(graphPath == treePath)
    }

    @Test("DI-223 U(S(0;1..6), P(6,7,8,9,10)).diameterPath() is [1, 0, 6, 7, 8, 9, 10]/[0, 5, 6, 7, 8, 9]: = TA-612")
    func diameterPath223() throws {
        // U: [] S(0;1..6), P(6,7,8,9,10)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (6, 7), (7, 8), (8, 9), (9, 10)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [1, 0, 6, 7, 8, 9, 10])
        #expect(path.edges == [0, 5, 6, 7, 8, 9])
        #expect(path.length == graph.diameter())
        // TA-612: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treePath = tree.diameterPath()
        #expect(treePath.vertices == [1, 0, 6, 7, 8, 9, 10])
        #expect(treePath.edges == [0, 5, 6, 7, 8, 9])
        func onGraph<G: Graph>(_ g: G) -> Path<G.Vertex, Int>? where G.Edges.Index == Int { g.diameterPath() }
        let graphPath = try #require(onGraph(tree))
        #expect(graphPath == treePath)
    }

    @Test("DI-224 U(kary(40,3)).diameter() is #6: = TA-613")
    func diameter224() throws {
        // U: [] kary(40,3)
        let pairs: [(Int, Int)] = (0 ..< 40).flatMap { i -> [(Int, Int)] in (3 * i + 1 ... 3 * i + 3).filter { $0 < 40 }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.diameter() == 6)
        #expect(graph.eccentricities().diameter == 6)
        // TA-613: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.diameter() == 6)
        func onGraph<G: Graph>(_ g: G) -> Int? where G.Edges.Index == Int { g.diameter() }
        #expect(onGraph(tree) == 6)
    }

    @Test("DI-225 U(P(0..9)).diameterPath() is [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]/[0, 1, 2, 3, 4, 5, 6, 7, 8]: = TA-606")
    func diameterPath225() throws {
        // U: [] P(0..9)
        let pairs: [(Int, Int)] = (0 ..< 9).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(path.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(path.length == graph.diameter())
        // TA-606: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treePath = tree.diameterPath()
        #expect(treePath.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(treePath.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        func onGraph<G: Graph>(_ g: G) -> Path<G.Vertex, Int>? where G.Edges.Index == Int { g.diameterPath() }
        let graphPath = try #require(onGraph(tree))
        #expect(graphPath == treePath)
    }

    @Test("DI-226 U(kary(8,2)).centroid() is [0, 1]: = TA-505: two medians")
    func centroid226() throws {
        // U: [] kary(8,2)
        let pairs: [(Int, Int)] = (0 ..< 8).flatMap { i -> [(Int, Int)] in (2 * i + 1 ... 2 * i + 2).filter { $0 < 8 }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == [0, 1])
        // TA-505: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [0, 1])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.centroid() }
        #expect(onGraph(tree) == [0, 1])
    }

    @Test("DI-227 U(P(0..99)).centroid() is [49, 50]: = TA-504")
    func centroid227() throws {
        // U: [] P(0..99)
        let pairs: [(Int, Int)] = (0 ..< 99).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == [49, 50])
        // TA-504: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [49, 50])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.centroid() }
        #expect(onGraph(tree) == [49, 50])
    }

    @Test("DI-228 U(P(0..4)).center(weight: [1, 1, 1, 10]) is [3]: = TA-413")
    func centerWeighted228() throws {
        // U: [] P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 1, 1, 10]
        #expect(graph.center(weight: { w[$0] }) == [3])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [3])
        // TA-413: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center(weight: { w[$0] }) == [3])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center(weight: { w[$0] }) }
        #expect(onGraph(tree) == [3])
    }

    @Test("DI-229 U(P(0..3)).center(weight: [0, 1, 0]) is [0, 1, 2, 3]: = TA-416: zero end edges, four centers")
    func centerWeighted229() throws {
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [0, 1, 0]
        #expect(graph.center(weight: { w[$0] }) == [0, 1, 2, 3])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [0, 1, 2, 3])
        // TA-416: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center(weight: { w[$0] }) == [0, 1, 2, 3])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center(weight: { w[$0] }) }
        #expect(onGraph(tree) == [0, 1, 2, 3])
    }

    @Test("DI-230 U(P(0..3)).center(weight: [1, 0, 1]) is [1, 2]: = TA-417")
    func centerWeighted230() throws {
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 0, 1]
        #expect(graph.center(weight: { w[$0] }) == [1, 2])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [1, 2])
        // TA-417: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center(weight: { w[$0] }) == [1, 2])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center(weight: { w[$0] }) }
        #expect(onGraph(tree) == [1, 2])
    }

    @Test("DI-231 U(S(0;1..4)).center(weight: [3, 1, 30, 2]) is [0]: = TA-419")
    func centerWeighted231() throws {
        // U: [] S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [3, 1, 30, 2]
        #expect(graph.center(weight: { w[$0] }) == [0])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [0])
        // TA-419: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center(weight: { w[$0] }) == [0])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center(weight: { w[$0] }) }
        #expect(onGraph(tree) == [0])
    }

    @Test("DI-232 U(P(0..3)).center(weight: [0.5, 0.25, 0.75]) is [2]: = TA-420")
    func centerWeighted232() throws {
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.5, 0.25, 0.75]
        #expect(graph.center(weight: { w[$0] }) == [2])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [2])
        // TA-420: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center(weight: { w[$0] }) == [2])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center(weight: { w[$0] }) }
        #expect(onGraph(tree) == [2])
    }

    @Test("DI-233 U(P(0..4)).diameter(weight: [1, 1, 1, 10]) is #13: = TA-614")
    func diameterWeighted233() throws {
        // U: [] P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 1, 1, 10]
        #expect(graph.diameter(weight: { w[$0] }) == 13)
        #expect(graph.eccentricities(weight: { w[$0] }).diameter == 13)
        // TA-614: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.diameter(weight: { w[$0] }) == 13)
        func onGraph<G: Graph>(_ g: G) -> Int? where G.Edges.Index == Int { g.diameter(weight: { w[$0] }) }
        #expect(onGraph(tree) == 13)
    }

    @Test("DI-234 U(P(0..4)).diameterPath(weight: [1, 1, 1, 10]) is [0, 1, 2, 3, 4]/[0, 1, 2, 3] #13: = TA-615")
    func diameterPathWeighted234() throws {
        // U: [] P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 1, 1, 10]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2, 3, 4])
        #expect(result.path.edges == [0, 1, 2, 3])
        #expect(result.distance == 13)
        // TA-615: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treeResult = tree.diameterPath(weight: { w[$0] })
        #expect(treeResult.path.vertices == [0, 1, 2, 3, 4])
        #expect(treeResult.path.edges == [0, 1, 2, 3])
        #expect(treeResult.distance == 13)
        func onGraph<G: Graph>(_ g: G) -> (path: Path<G.Vertex, Int>, distance: Int)? where G.Edges.Index == Int { g.diameterPath(weight: { w[$0] }) }
        let graphResult = try #require(onGraph(tree))
        #expect(graphResult.path == treeResult.path)
        #expect(graphResult.distance == treeResult.distance)
    }

    @Test("DI-235 U(S(0;1..4)).diameterPath(weight: [3, 1, 3, 2]) is [1, 0, 3]/[0, 2] #6: = TA-616")
    func diameterPathWeighted235() throws {
        // U: [] S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [3, 1, 3, 2]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [1, 0, 3])
        #expect(result.path.edges == [0, 2])
        #expect(result.distance == 6)
        // TA-616: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treeResult = tree.diameterPath(weight: { w[$0] })
        #expect(treeResult.path.vertices == [1, 0, 3])
        #expect(treeResult.path.edges == [0, 2])
        #expect(treeResult.distance == 6)
        func onGraph<G: Graph>(_ g: G) -> (path: Path<G.Vertex, Int>, distance: Int)? where G.Edges.Index == Int { g.diameterPath(weight: { w[$0] }) }
        let graphResult = try #require(onGraph(tree))
        #expect(graphResult.path == treeResult.path)
        #expect(graphResult.distance == treeResult.distance)
    }

    @Test("DI-236 U(P(0..2)).diameterPath(weight: [0, 0]) is [0]/[] #0: = TA-617: all zero, the trivial path at `vertices[0]`")
    func diameterPathWeighted236() throws {
        // U: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [0, 0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0])
        #expect(result.path.edges == [])
        #expect(result.distance == 0)
        // TA-617: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treeResult = tree.diameterPath(weight: { w[$0] })
        #expect(treeResult.path.vertices == [0])
        #expect(treeResult.path.edges == [])
        #expect(treeResult.distance == 0)
        func onGraph<G: Graph>(_ g: G) -> (path: Path<G.Vertex, Int>, distance: Int)? where G.Edges.Index == Int { g.diameterPath(weight: { w[$0] }) }
        let graphResult = try #require(onGraph(tree))
        #expect(graphResult.path == treeResult.path)
        #expect(graphResult.distance == treeResult.distance)
    }

    @Test("DI-237 U(P(0..3)).diameterPath(weight: [0, 1, 0]) is [0, 1, 2]/[0, 1] #1: = TA-618: the least pair at distance 1 is (0, 2)")
    func diameterPathWeighted237() throws {
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [0, 1, 0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [0, 1])
        #expect(result.distance == 1)
        // TA-618: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treeResult = tree.diameterPath(weight: { w[$0] })
        #expect(treeResult.path.vertices == [0, 1, 2])
        #expect(treeResult.path.edges == [0, 1])
        #expect(treeResult.distance == 1)
        func onGraph<G: Graph>(_ g: G) -> (path: Path<G.Vertex, Int>, distance: Int)? where G.Edges.Index == Int { g.diameterPath(weight: { w[$0] }) }
        let graphResult = try #require(onGraph(tree))
        #expect(graphResult.path == treeResult.path)
        #expect(graphResult.distance == treeResult.distance)
    }

    @Test("DI-238 U(P(0..3)).diameter(weight: [0.5, 0.25, 0.75]) is #1.5: = TA-619")
    func diameterWeighted238() throws {
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.5, 0.25, 0.75]
        #expect(graph.diameter(weight: { w[$0] }) == 1.5)
        #expect(graph.eccentricities(weight: { w[$0] }).diameter == 1.5)
        // TA-619: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.diameter(weight: { w[$0] }) == 1.5)
        func onGraph<G: Graph>(_ g: G) -> Double? where G.Edges.Index == Int { g.diameter(weight: { w[$0] }) }
        #expect(onGraph(tree) == 1.5)
    }

    @Test("DI-239 U([0..8]; 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8).diameterPath(weight: [5, 1, 1, 1, 1, 1, 1, 1]) is [6, 4, 1, 0, 2, 5, 8]/[5, 3, 0, 1, 4, 7] #10: = TA-624")
    func diameterPathWeighted239() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [5, 1, 1, 1, 1, 1, 1, 1]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(result.path.edges == [5, 3, 0, 1, 4, 7])
        #expect(result.distance == 10)
        // TA-624: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treeResult = tree.diameterPath(weight: { w[$0] })
        #expect(treeResult.path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(treeResult.path.edges == [5, 3, 0, 1, 4, 7])
        #expect(treeResult.distance == 10)
        func onGraph<G: Graph>(_ g: G) -> (path: Path<G.Vertex, Int>, distance: Int)? where G.Edges.Index == Int { g.diameterPath(weight: { w[$0] }) }
        let graphResult = try #require(onGraph(tree))
        #expect(graphResult.path == treeResult.path)
        #expect(graphResult.distance == treeResult.distance)
    }

    @Test("DI-250 U([5, 4, 3, 2, 1, 0]; C(0..5)).center() is [5, 4, 3, 2, 1, 0]: Everything, in `vertices` order")
    func center250() {
        // U: [5, 4, 3, 2, 1, 0] C(0..5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: [5, 4, 3, 2, 1, 0], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [5, 4, 3, 2, 1, 0])
        #expect(graph.eccentricities().center == [5, 4, 3, 2, 1, 0])
    }

    @Test("DI-251 U([5, 4, 3, 2, 1, 0]; C(0..5)).diameterPath() is [5, 4, 3, 2]/[4, 3, 2]: u = 5 (first in `vertices`), v = 2 (first at distance 3): breadth-first parents through 4, the first edge in 5's row")
    func diameterPath251() throws {
        // U: [5, 4, 3, 2, 1, 0] C(0..5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: [5, 4, 3, 2, 1, 0], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [5, 4, 3, 2])
        #expect(path.edges == [4, 3, 2])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-252 U([5, 4, 3, 2, 1, 0]; C(0..5) ~rev).diameterPath() is [5, 0, 1, 2]/[5, 0, 1]: Rows reversed: the other way round. Row order decides the path, never the endpoints")
    func diameterPath252() throws {
        // U: [5, 4, 3, 2, 1, 0] C(0..5) ~rev
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReversedPseudograph(vertices: [5, 4, 3, 2, 1, 0], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [5, 0, 1, 2])
        #expect(path.edges == [5, 0, 1])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-253 U(grid(3,3)).diameterPath() is [0, 1, 2, 5, 8]/[0, 2, 4, 9]")
    func diameterPath253() throws {
        // U: [] grid(3,3)
        let pairs: [(Int, Int)] = (0 ..< 9).flatMap { v -> [(Int, Int)] in (v % 3 + 1 < 3 ? [(v, v + 1)] : []) + (v / 3 + 1 < 3 ? [(v, v + 3)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 1, 2, 5, 8])
        #expect(path.edges == [0, 2, 4, 9])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-254 U(grid(3,3) ~rev).diameterPath() is [0, 3, 6, 7, 8]/[1, 6, 10, 11]")
    func diameterPath254() throws {
        // U: [] grid(3,3) ~rev
        let pairs: [(Int, Int)] = (0 ..< 9).flatMap { v -> [(Int, Int)] in (v % 3 + 1 < 3 ? [(v, v + 1)] : []) + (v / 3 + 1 < 3 ? [(v, v + 3)] : []) }
        let graph = ReversedPseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 3, 6, 7, 8])
        #expect(path.edges == [1, 6, 10, 11])
        #expect(path.length == graph.diameter())
    }
}
