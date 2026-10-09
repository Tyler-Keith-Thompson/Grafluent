// §A: the empty graph, K₁, two isolated vertices, K₂ both ways and a lone self-loop. The empty
// graph has no eccentricities: radius and diameter nil, center, periphery and centroid empty, the
// Wiener index the empty sum 0, the average nil (no pairs), density 0 (DI-001 – DI-012). Two
// isolated vertices have every eccentricity infinite (nil), so every vertex is in the center and
// the periphery (DI-028, DI-029). K₁ weighted never calls the closure (DI-023, DI-024). Rows citing
// `= TA-nnn` also run `Tree`'s own member (TreeAlgorithms) and Distances on the `Tree` as a
// `Graph`, and must equal the catalog cell. Every literal is a catalog cell (`ref.py`: api.md's
// model, Floyd–Warshall, NetworkX 3.7 and scipy 1.18.1). DI-042 (not a vertex) is an exit test in
// `DistancePreconditionTests.swift`. Case IDs (DI-nnn) refer to the catalog; see README.md.

import Distances
import GrafluentTestSupport
import GraphProtocols
import Testing
import TreeAlgorithms
import Trees
import Walks

@Suite("Degenerate graphs")
struct DegenerateGraphTests {
    @Test("DI-001 U().eccentricities() is []: Empty graph: no vertices. NetworkX raises `NetworkXPointlessConcept` for every measure here; igraph gives NaN; JGraphT 0 and 0")
    func eccentricities001() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let expected: [Int?] = []
        let eccentricities = graph.eccentricities()
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0) }
        #expect(oneByOne == expected)
        #expect(graph.radius() == eccentricities.radius)
        #expect(graph.diameter() == eccentricities.diameter)
        #expect(graph.center() == eccentricities.center)
        #expect(graph.periphery() == eccentricities.periphery)
        let arcs = graph.directed.eccentricities()
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-002 U().radius() is nil")
    func radius002() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.radius() == nil)
        #expect(graph.eccentricities().radius == nil)
    }

    @Test("DI-003 U().diameter() is nil")
    func diameter003() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.diameter() == nil)
        #expect(graph.eccentricities().diameter == nil)
    }

    @Test("DI-004 U().center() is []")
    func center004() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.center() == [])
        #expect(graph.eccentricities().center == [])
    }

    @Test("DI-005 U().periphery() is []")
    func periphery005() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.periphery() == [])
        #expect(graph.eccentricities().periphery == [])
    }

    @Test("DI-006 U().diameterPath() is nil")
    func diameterPath006() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.diameterPath() == nil)
    }

    @Test("DI-007 U().centroid() is []")
    func centroid007() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.centroid() == [])
    }

    @Test("DI-008 U().wienerIndex() is #0: The empty sum (NetworkX raises: connectivity of the null graph is undefined)")
    func wienerIndex008() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.wienerIndex() == 0)
    }

    @Test("DI-009 U().averageShortestPathLength() is nil: No pairs (NetworkX raises)")
    func averageShortestPathLength009() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.averageShortestPathLength() == nil)
    }

    @Test("DI-010 U().density is #0.0: NetworkX 0; igraph NaN")
    func density010() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(graph.density == 0.0)
    }

    @Test("DI-011 D().diameter() is nil")
    func diameter011() {
        // D: []
        let graph = ReferenceDirectedMultigraph<Int>(vertices: [], edges: [])
        #expect(graph.diameter() == nil)
        #expect(graph.eccentricities().diameter == nil)
    }

    @Test("DI-012 D().density is #0.0")
    func density012() {
        // D: []
        let graph = ReferenceDirectedMultigraph<Int>(vertices: [], edges: [])
        #expect(graph.density == 0.0)
    }

    @Test("DI-013 U([0]).eccentricities() is [0]: K₁")
    func eccentricities013() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let expected: [Int?] = [0]
        let eccentricities = graph.eccentricities()
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0) }
        #expect(oneByOne == expected)
        #expect(graph.radius() == eccentricities.radius)
        #expect(graph.diameter() == eccentricities.diameter)
        #expect(graph.center() == eccentricities.center)
        #expect(graph.periphery() == eccentricities.periphery)
        let arcs = graph.directed.eccentricities()
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-014 U([0]).radius() is #0")
    func radius014() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.radius() == 0)
        #expect(graph.eccentricities().radius == 0)
    }

    @Test("DI-015 U([0]).diameter() is #0: = TA-601")
    func diameter015() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.diameter() == 0)
        #expect(graph.eccentricities().diameter == 0)
        // TA-601: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.diameter() == 0)
        func onGraph<G: Graph>(_ g: G) -> Int? where G.Edges.Index == Int { g.diameter() }
        #expect(onGraph(tree) == 0)
    }

    @Test("DI-016 U([0]).center() is [0]: = TA-401")
    func center016() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.center() == [0])
        #expect(graph.eccentricities().center == [0])
        // TA-401: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [0])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center() }
        #expect(onGraph(tree) == [0])
    }

    @Test("DI-017 U([0]).periphery() is [0]")
    func periphery017() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.periphery() == [0])
        #expect(graph.eccentricities().periphery == [0])
    }

    @Test("DI-018 U([0]).diameterPath() is [0]/[]: = TA-602")
    func diameterPath018() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0])
        #expect(path.edges == [])
        #expect(path.length == graph.diameter())
        // TA-602: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treePath = tree.diameterPath()
        #expect(treePath.vertices == [0])
        #expect(treePath.edges == [])
        func onGraph<G: Graph>(_ g: G) -> Path<G.Vertex, Int>? where G.Edges.Index == Int { g.diameterPath() }
        let graphPath = try #require(onGraph(tree))
        #expect(graphPath == treePath)
    }

    @Test("DI-019 U([0]).centroid() is [0]: = TA-501")
    func centroid019() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.centroid() == [0])
        // TA-501: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [0])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.centroid() }
        #expect(onGraph(tree) == [0])
    }

    @Test("DI-020 U([0]).wienerIndex() is #0")
    func wienerIndex020() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.wienerIndex() == 0)
    }

    @Test("DI-021 U([0]).averageShortestPathLength() is #0.0: NetworkX returns 0 for one vertex; igraph NaN")
    func averageShortestPathLength021() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.averageShortestPathLength() == 0.0)
    }

    @Test("DI-022 U([0]).density is #0.0: NetworkX 0; igraph NaN")
    func density022() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.density == 0.0)
    }

    @Test("DI-023 U([0]).center(weight: []) is [0]: = TA-423: K₁ weighted, the closure is never called")
    func centerWeighted023() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        var calls = 0
        let weight = { (_: Int) -> Int in
            calls += 1
            return 1
        }
        #expect(graph.center(weight: weight) == [0])
        #expect(graph.eccentricities(weight: weight).center == [0])
        // TA-423: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        #expect(tree.center(weight: weight) == [0])
        func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int { g.center(weight: weight) }
        #expect(onGraph(tree) == [0])
        #expect(calls == 0)
    }

    @Test("DI-024 U([0]).diameterPath(weight: []) is [0]/[] #0: = TA-622")
    func diameterPathWeighted024() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        var calls = 0
        let weight = { (_: Int) -> Int in
            calls += 1
            return 1
        }
        let result = try #require(graph.diameterPath(weight: weight))
        #expect(result.path.vertices == [0])
        #expect(result.path.edges == [])
        #expect(result.distance == 0)
        // TA-622: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treeResult = tree.diameterPath(weight: weight)
        #expect(treeResult.path.vertices == [0])
        #expect(treeResult.path.edges == [])
        #expect(treeResult.distance == 0)
        func onGraph<G: Graph>(_ g: G) -> (path: Path<G.Vertex, Int>, distance: Int)? where G.Edges.Index == Int { g.diameterPath(weight: weight) }
        let graphResult = try #require(onGraph(tree))
        #expect(graphResult.path == treeResult.path)
        #expect(graphResult.distance == treeResult.distance)
        #expect(calls == 0)
    }

    @Test("DI-025 U([0, 1]).eccentricities() is [nil, nil]: Two isolated vertices: every eccentricity infinite")
    func eccentricities025() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        let expected: [Int?] = [nil, nil]
        let eccentricities = graph.eccentricities()
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0) }
        #expect(oneByOne == expected)
        #expect(graph.radius() == eccentricities.radius)
        #expect(graph.diameter() == eccentricities.diameter)
        #expect(graph.center() == eccentricities.center)
        #expect(graph.periphery() == eccentricities.periphery)
        let arcs = graph.directed.eccentricities()
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-026 U([0, 1]).radius() is nil")
    func radius026() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.radius() == nil)
        #expect(graph.eccentricities().radius == nil)
    }

    @Test("DI-027 U([0, 1]).diameter() is nil")
    func diameter027() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.diameter() == nil)
        #expect(graph.eccentricities().diameter == nil)
    }

    @Test("DI-028 U([0, 1]).center() is [0, 1]: Every eccentricity equals the (infinite) radius: every vertex, as JGraphT and scipy's infinities give")
    func center028() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.center() == [0, 1])
        #expect(graph.eccentricities().center == [0, 1])
    }

    @Test("DI-029 U([0, 1]).periphery() is [0, 1]")
    func periphery029() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.periphery() == [0, 1])
        #expect(graph.eccentricities().periphery == [0, 1])
    }

    @Test("DI-030 U([0, 1]).diameterPath() is nil")
    func diameterPath030() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.diameterPath() == nil)
    }

    @Test("DI-031 U([0, 1]).centroid() is [0, 1]")
    func centroid031() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.centroid() == [0, 1])
    }

    @Test("DI-032 U([0, 1]).wienerIndex() is nil: NetworkX `inf`")
    func wienerIndex032() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.wienerIndex() == nil)
    }

    @Test("DI-033 U([0, 1]).averageShortestPathLength() is nil: NetworkX raises")
    func averageShortestPathLength033() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.averageShortestPathLength() == nil)
    }

    @Test("DI-034 U([0, 1]).density is #0.0")
    func density034() {
        // U: [0, 1]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1], edges: [])
        #expect(graph.density == 0.0)
    }

    @Test("DI-035 U(0-1).eccentricities() is [1, 1]")
    func eccentricities035() {
        // U: [] 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [1, 1]
        let eccentricities = graph.eccentricities()
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0) }
        #expect(oneByOne == expected)
        #expect(graph.radius() == eccentricities.radius)
        #expect(graph.diameter() == eccentricities.diameter)
        #expect(graph.center() == eccentricities.center)
        #expect(graph.periphery() == eccentricities.periphery)
        let arcs = graph.directed.eccentricities()
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-036 U(0-1).diameterPath() is [0, 1]/[0]: = TA-603")
    func diameterPath036() throws {
        // U: [] 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 1])
        #expect(path.edges == [0])
        #expect(path.length == graph.diameter())
        // TA-603: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treePath = tree.diameterPath()
        #expect(treePath.vertices == [0, 1])
        #expect(treePath.edges == [0])
        func onGraph<G: Graph>(_ g: G) -> Path<G.Vertex, Int>? where G.Edges.Index == Int { g.diameterPath() }
        let graphPath = try #require(onGraph(tree))
        #expect(graphPath == treePath)
    }

    @Test("DI-037 U(1-0).diameterPath() is [1, 0]/[0]: = TA-604: `vertices` = [1, 0], so the path starts at 1")
    func diameterPath037() throws {
        // U: [] 1-0
        let pairs: [(Int, Int)] = [(1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [1, 0])
        #expect(path.edges == [0])
        #expect(path.length == graph.diameter())
        // TA-604: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.
        let tree = try #require(Tree(graph))
        let treePath = tree.diameterPath()
        #expect(treePath.vertices == [1, 0])
        #expect(treePath.edges == [0])
        func onGraph<G: Graph>(_ g: G) -> Path<G.Vertex, Int>? where G.Edges.Index == Int { g.diameterPath() }
        let graphPath = try #require(onGraph(tree))
        #expect(graphPath == treePath)
    }

    @Test("DI-038 U(0-1).density is #1.0")
    func density038() {
        // U: [] 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.density == 1.0)
    }

    @Test("DI-039 U(0-0).eccentricities() is [0]: One vertex with a loop")
    func eccentricities039() {
        // U: [] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [0]
        let eccentricities = graph.eccentricities()
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0) }
        #expect(oneByOne == expected)
        #expect(graph.radius() == eccentricities.radius)
        #expect(graph.diameter() == eccentricities.diameter)
        #expect(graph.center() == eccentricities.center)
        #expect(graph.periphery() == eccentricities.periphery)
        let arcs = graph.directed.eccentricities()
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-040 U(0-0).density is #0.0: n ≤ 1 gives 0 whatever the loops (NetworkX)")
    func density040() {
        // U: [] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.density == 0.0)
    }

    @Test("DI-041 U(0-0).diameterPath() is [0]/[]: The loop is never on a path")
    func diameterPath041() throws {
        // U: [] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0])
        #expect(path.edges == [])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-043 U([0]).eccentricity(of: 0) is #0")
    func eccentricity043() {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(graph.eccentricity(of: 0) == 0)
        #expect(graph.eccentricities().eccentricity(of: 0) == 0)
    }
}
