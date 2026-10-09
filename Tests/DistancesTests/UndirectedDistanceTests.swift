// §B: connected undirected graphs without weights: NetworkX's docstring graph and grid, cycles and
// complete graphs (vertex-transitive: every vertex central and peripheral, the bounding
// algorithm's worst shape), K₃,₄, Petersen, Zachary's karate club, two triangles joined by a path,
// and a path with 12 pseudo-random chords. Every `eccentricities` row also checks
// `eccentricity(ofIndex:)`, `eccentricity(of:)` on the value and on the graph, that the one-shot
// `radius()`, `diameter()`, `center()` and `periphery()` equal the value's members, and that
// `graph.directed` gives the same eccentricities; every radius, diameter, center and periphery row
// checks the one-shot call and the `Eccentricities` member. `diameterPath()` pins the breadth-first
// path from the first peripheral vertex (rows in position order). Literals are catalog cells.
// Case IDs (DI-nnn) refer to the catalog; see README.md.

import Distances
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Undirected, unweighted")
struct UndirectedDistanceTests {
    @Test("DI-101 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).eccentricities() is [2, 3, 2, 2, 3]: NetworkX's docstring graph")
    func eccentricities101() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [2, 3, 2, 2, 3]
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

    @Test("DI-102 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).center() is [1, 3, 4]: NetworkX docstring `[1, 3, 4]`")
    func center102() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [1, 3, 4])
        #expect(graph.eccentricities().center == [1, 3, 4])
    }

    @Test("DI-103 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).periphery() is [2, 5]: NetworkX docstring `[2, 5]`")
    func periphery103() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.periphery() == [2, 5])
        #expect(graph.eccentricities().periphery == [2, 5])
    }

    @Test("DI-104 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).radius() is #2")
    func radius104() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.radius() == 2)
        #expect(graph.eccentricities().radius == 2)
    }

    @Test("DI-105 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).diameter() is #3")
    func diameter105() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.diameter() == 3)
        #expect(graph.eccentricities().diameter == 3)
    }

    @Test("DI-106 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).centroid() is [1, 3, 4]: NetworkX 3.7 `centroid` docstring `[1, 3, 4]`")
    func centroid106() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == [1, 3, 4])
    }

    @Test("DI-107 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).wienerIndex() is #15")
    func wienerIndex107() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.wienerIndex() == 15)
    }

    @Test("DI-108 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).averageShortestPathLength() is #1.5")
    func averageShortestPathLength108() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageShortestPathLength() == 1.5)
    }

    @Test("DI-109 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).density is #0.6")
    func density109() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.density == 0.6)
    }

    @Test("DI-110 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).diameterPath() is [2, 1, 3, 5]/[0, 1, 4]: From 2, the first peripheral vertex, to 5")
    func diameterPath110() throws {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [2, 1, 3, 5])
        #expect(path.edges == [0, 1, 4])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-111 U(grid(4,4)).eccentricities() is [6, 5, 5, 6, 5, 4, 4, 5, 5, 4, 4, 5, 6, 5, 5, 6]: NetworkX `test_distance_measures` grid (its labels are ours + 1)")
    func eccentricities111() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [6, 5, 5, 6, 5, 4, 4, 5, 5, 4, 4, 5, 6, 5, 5, 6]
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

    @Test("DI-112 U(grid(4,4)).diameter() is #6: NetworkX 6")
    func diameter112() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.diameter() == 6)
        #expect(graph.eccentricities().diameter == 6)
    }

    @Test("DI-113 U(grid(4,4)).radius() is #4: NetworkX 4")
    func radius113() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.radius() == 4)
        #expect(graph.eccentricities().radius == 4)
    }

    @Test("DI-114 U(grid(4,4)).center() is [5, 6, 9, 10]: NetworkX `[6, 7, 10, 11]`")
    func center114() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [5, 6, 9, 10])
        #expect(graph.eccentricities().center == [5, 6, 9, 10])
    }

    @Test("DI-115 U(grid(4,4)).periphery() is [0, 3, 12, 15]: NetworkX `[1, 4, 13, 16]`")
    func periphery115() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.periphery() == [0, 3, 12, 15])
        #expect(graph.eccentricities().periphery == [0, 3, 12, 15])
    }

    @Test("DI-116 U(grid(4,4)).diameterPath() is [0, 1, 2, 3, 7, 11, 15]/[0, 2, 4, 6, 13, 20]: 0 to 15: breadth-first parents go right before down")
    func diameterPath116() throws {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 1, 2, 3, 7, 11, 15])
        #expect(path.edges == [0, 2, 4, 6, 13, 20])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-117 U(grid(4,4)).eccentricity(of: 5) is #4: NetworkX `eccentricity(G, 6)` = 4")
    func eccentricity117() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.eccentricity(of: 5) == 4)
        #expect(graph.eccentricities().eccentricity(of: 5) == 4)
    }

    @Test("DI-118 U(grid(4,4)).centroid() is [5, 6, 9, 10]")
    func centroid118() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == [5, 6, 9, 10])
    }

    @Test("DI-120 U(C(0..4)).eccentricities() is [2, 2, 2, 2, 2]")
    func eccentricities120() {
        // U: [] C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [2, 2, 2, 2, 2]
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

    @Test("DI-121 U(C(0..4)).center() is [0, 1, 2, 3, 4]: Vertex-transitive: everything")
    func center121() {
        // U: [] C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [0, 1, 2, 3, 4])
        #expect(graph.eccentricities().center == [0, 1, 2, 3, 4])
    }

    @Test("DI-122 U(C(0..4)).periphery() is [0, 1, 2, 3, 4]")
    func periphery122() {
        // U: [] C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.periphery() == [0, 1, 2, 3, 4])
        #expect(graph.eccentricities().periphery == [0, 1, 2, 3, 4])
    }

    @Test("DI-123 U(C(0..4)).diameterPath() is [0, 1, 2]/[0, 1]")
    func diameterPath123() throws {
        // U: [] C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 1, 2])
        #expect(path.edges == [0, 1])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-124 U(C(0..5)).diameterPath() is [0, 1, 2, 3]/[0, 1, 2]: Two shortest 0–3 paths: the breadth-first one (via 1)")
    func diameterPath124() throws {
        // U: [] C(0..5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 1, 2, 3])
        #expect(path.edges == [0, 1, 2])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-125 U(C(0..4)).averageShortestPathLength() is #1.5: igraph 1.5")
    func averageShortestPathLength125() {
        // U: [] C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageShortestPathLength() == 1.5)
    }

    @Test("DI-126 U(K(5)).eccentricities() is [1, 1, 1, 1, 1]")
    func eccentricities126() {
        // U: [] K(5)
        let pairs: [(Int, Int)] = (0 ..< 5).flatMap { i in (i + 1 ..< 5).map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [1, 1, 1, 1, 1]
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

    @Test("DI-127 U(K(5)).diameterPath() is [0, 1]/[0]")
    func diameterPath127() throws {
        // U: [] K(5)
        let pairs: [(Int, Int)] = (0 ..< 5).flatMap { i in (i + 1 ..< 5).map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 1])
        #expect(path.edges == [0])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-128 U(K(5)).density is #1.0")
    func density128() {
        // U: [] K(5)
        let pairs: [(Int, Int)] = (0 ..< 5).flatMap { i in (i + 1 ..< 5).map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.density == 1.0)
    }

    @Test("DI-129 U(K(5)).wienerIndex() is #10: C(5, 2)")
    func wienerIndex129() {
        // U: [] K(5)
        let pairs: [(Int, Int)] = (0 ..< 5).flatMap { i in (i + 1 ..< 5).map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.wienerIndex() == 10)
    }

    @Test("DI-130 U(K(5)).averageShortestPathLength() is #1.0")
    func averageShortestPathLength130() {
        // U: [] K(5)
        let pairs: [(Int, Int)] = (0 ..< 5).flatMap { i in (i + 1 ..< 5).map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageShortestPathLength() == 1.0)
    }

    @Test("DI-131 U(KB(0..2;3..6)).eccentricities() is [2, 2, 2, 2, 2, 2, 2]: K₃,₄")
    func eccentricities131() {
        // U: [] KB(0..2;3..6)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (0, 6), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [2, 2, 2, 2, 2, 2, 2]
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

    @Test("DI-132 U(KB(0..2;3..6)).diameterPath() is [0, 3, 1]/[0, 4]: 0 to 1 through 3")
    func diameterPath132() throws {
        // U: [] KB(0..2;3..6)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (0, 6), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 3, 1])
        #expect(path.edges == [0, 4])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-133 U(KB(0..2;3..6)).centroid() is [0, 1, 2]: The smaller side has the smaller total: 4·1 + 2·2 = 8 against 3·1 + 3·2 = 9")
    func centroid133() {
        // U: [] KB(0..2;3..6)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (0, 6), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == [0, 1, 2])
    }

    @Test("DI-134 U(nx(petersen)).eccentricities() is [2, 2, 2, 2, 2, 2, 2, 2, 2, 2]")
    func eccentricities134() {
        // U: [] nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
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

    @Test("DI-135 U(nx(petersen)).wienerIndex() is #75")
    func wienerIndex135() {
        // U: [] nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.wienerIndex() == 75)
    }

    @Test("DI-136 U(nx(petersen)).averageShortestPathLength() is #1.6666666666666667")
    func averageShortestPathLength136() {
        // U: [] nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageShortestPathLength() == 1.6666666666666667)
    }

    @Test("DI-137 U(nx(petersen)).density is #0.3333333333333333")
    func density137() {
        // U: [] nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.density == 0.3333333333333333)
    }

    @Test("DI-138 U(nx(karate_club)).eccentricities() is [3, 3, 3, 3, 4, 4, 4, 4, 3, 4, 4, 4, 4, 3, 5, 5, 5, 4, 5, 3, 5, 4, 5, 5, 4, 4, 5, 4, 4, 5, 4, 3, 4, 4]: Zachary's karate club")
    func eccentricities138() {
        // U: [] nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [3, 3, 3, 3, 4, 4, 4, 4, 3, 4, 4, 4, 4, 3, 5, 5, 5, 4, 5, 3, 5, 4, 5, 5, 4, 4, 5, 4, 4, 5, 4, 3, 4, 4]
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

    @Test("DI-139 U(nx(karate_club)).diameter() is #5")
    func diameter139() {
        // U: [] nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.diameter() == 5)
        #expect(graph.eccentricities().diameter == 5)
    }

    @Test("DI-140 U(nx(karate_club)).radius() is #3")
    func radius140() {
        // U: [] nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.radius() == 3)
        #expect(graph.eccentricities().radius == 3)
    }

    @Test("DI-141 U(nx(karate_club)).center() is [0, 1, 2, 3, 8, 13, 19, 31]")
    func center141() {
        // U: [] nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [0, 1, 2, 3, 8, 13, 19, 31])
        #expect(graph.eccentricities().center == [0, 1, 2, 3, 8, 13, 19, 31])
    }

    @Test("DI-142 U(nx(karate_club)).periphery() is [14, 15, 16, 18, 20, 22, 23, 26, 29]")
    func periphery142() {
        // U: [] nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.periphery() == [14, 15, 16, 18, 20, 22, 23, 26, 29])
        #expect(graph.eccentricities().periphery == [14, 15, 16, 18, 20, 22, 23, 26, 29])
    }

    @Test("DI-143 U(nx(karate_club)).centroid() is [0]")
    func centroid143() {
        // U: [] nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == [0])
    }

    @Test("DI-144 U(nx(karate_club)).wienerIndex() is #1351")
    func wienerIndex144() {
        // U: [] nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.wienerIndex() == 1351)
    }

    @Test("DI-145 U(nx(karate_club)).averageShortestPathLength() is #2.408199643493761")
    func averageShortestPathLength145() {
        // U: [] nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageShortestPathLength() == 2.408199643493761)
    }

    @Test("DI-146 U(nx(karate_club)).density is #0.13903743315508021")
    func density146() {
        // U: [] nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.density == 0.13903743315508021)
    }

    @Test("DI-147 U(nx(karate_club)).diameterPath() is [14, 32, 2, 0, 5, 16]/[46, 31, 1, 4, 39]")
    func diameterPath147() throws {
        // U: [] nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19),
            (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7),
            (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33),
            (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33),
            (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33),
            (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33),
            (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [14, 32, 2, 0, 5, 16])
        #expect(path.edges == [46, 31, 1, 4, 39])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-150 U(C(0..2), P(2,3,4), C(4..6)).eccentricities() is [4, 4, 3, 2, 3, 4, 4]: Two triangles joined by a path")
    func eccentricities150() {
        // U: [] C(0..2), P(2,3,4), C(4..6)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [4, 4, 3, 2, 3, 4, 4]
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

    @Test("DI-151 U(C(0..2), P(2,3,4), C(4..6)).center() is [3]")
    func center151() {
        // U: [] C(0..2), P(2,3,4), C(4..6)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [3])
        #expect(graph.eccentricities().center == [3])
    }

    @Test("DI-152 U(C(0..2), P(2,3,4), C(4..6)).periphery() is [0, 1, 5, 6]")
    func periphery152() {
        // U: [] C(0..2), P(2,3,4), C(4..6)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.periphery() == [0, 1, 5, 6])
        #expect(graph.eccentricities().periphery == [0, 1, 5, 6])
    }

    @Test("DI-153 U(C(0..2), P(2,3,4), C(4..6)).diameterPath() is [0, 2, 3, 4, 5]/[2, 3, 4, 5]")
    func diameterPath153() throws {
        // U: [] C(0..2), P(2,3,4), C(4..6)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 2, 3, 4, 5])
        #expect(path.edges == [2, 3, 4, 5])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-154 U(P(0..29), lcg(30,12,7)).eccentricities() is [8, 7, 6, 5, 4, 5, 6, 7, 7, 6, 7, 7, 7, 6, 7, 6, 5, 6, 5, 5, 6, 6, 5, 5, 5, 6, 7, 8, 8, 7]: A path plus 12 chords")
    func eccentricities154() {
        // U: [] P(0..29), lcg(30,12,7)
        let pairs: [(Int, Int)] = (0 ..< 29).map { ($0, $0 + 1) } + [(8, 11), (3, 23), (25, 29), (4, 24), (19, 16), (25, 15), (2, 20), (9, 22), (15, 9), (6, 11), (16, 13), (4, 18)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [8, 7, 6, 5, 4, 5, 6, 7, 7, 6, 7, 7, 7, 6, 7, 6, 5, 6, 5, 5, 6, 6, 5, 5, 5, 6, 7, 8, 8, 7]
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

    @Test("DI-155 U(P(0..29), lcg(30,12,7)).center() is [4]")
    func center155() {
        // U: [] P(0..29), lcg(30,12,7)
        let pairs: [(Int, Int)] = (0 ..< 29).map { ($0, $0 + 1) } + [(8, 11), (3, 23), (25, 29), (4, 24), (19, 16), (25, 15), (2, 20), (9, 22), (15, 9), (6, 11), (16, 13), (4, 18)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [4])
        #expect(graph.eccentricities().center == [4])
    }

    @Test("DI-156 U(P(0..29), lcg(30,12,7)).periphery() is [0, 27, 28]")
    func periphery156() {
        // U: [] P(0..29), lcg(30,12,7)
        let pairs: [(Int, Int)] = (0 ..< 29).map { ($0, $0 + 1) } + [(8, 11), (3, 23), (25, 29), (4, 24), (19, 16), (25, 15), (2, 20), (9, 22), (15, 9), (6, 11), (16, 13), (4, 18)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.periphery() == [0, 27, 28])
        #expect(graph.eccentricities().periphery == [0, 27, 28])
    }

    @Test("DI-157 U(P(0..29), lcg(30,12,7)).diameterPath() is [0, 1, 2, 3, 4, 24, 25, 26, 27]/[0, 1, 2, 3, 32, 24, 25, 26]")
    func diameterPath157() throws {
        // U: [] P(0..29), lcg(30,12,7)
        let pairs: [(Int, Int)] = (0 ..< 29).map { ($0, $0 + 1) } + [(8, 11), (3, 23), (25, 29), (4, 24), (19, 16), (25, 15), (2, 20), (9, 22), (15, 9), (6, 11), (16, 13), (4, 18)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 1, 2, 3, 4, 24, 25, 26, 27])
        #expect(path.edges == [0, 1, 2, 3, 32, 24, 25, 26])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-158 U(P(0..29), lcg(30,12,7)).wienerIndex() is #1532")
    func wienerIndex158() {
        // U: [] P(0..29), lcg(30,12,7)
        let pairs: [(Int, Int)] = (0 ..< 29).map { ($0, $0 + 1) } + [(8, 11), (3, 23), (25, 29), (4, 24), (19, 16), (25, 15), (2, 20), (9, 22), (15, 9), (6, 11), (16, 13), (4, 18)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.wienerIndex() == 1532)
    }
}
