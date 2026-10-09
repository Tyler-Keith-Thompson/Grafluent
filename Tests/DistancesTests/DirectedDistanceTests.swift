// §E: directed graphs, over out-distances. A digraph that is not strongly connected has a finite
// radius when some vertex reaches every vertex (DI-402, DI-426: the dipath and the acyclic
// tournament) and a nil diameter; its center is the vertices of least finite eccentricity and its
// periphery the vertices that do not reach everything (DI-405, DI-427). The Wiener index sums
// ordered pairs, so `graph.directed` doubles it (DI-438) and keeps the average and the density
// (DI-437, DI-439); `digraph.undirected` reads each arc as an edge (DI-428, DI-429, DI-434). Loops
// count in the density (DI-441). Literals are catalog cells. Case IDs (DI-nnn) refer to the
// catalog; see README.md.

import Distances
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Directed graphs")
struct DirectedDistanceTests {
    @Test("DI-401 D(P(0..2)).eccentricities() is [2, nil, nil]: Out-distances: only 0 reaches everything. igraph [2, 1, 0]")
    func eccentricities401() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let expected: [Int?] = [2, nil, nil]
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
    }

    @Test("DI-402 D(P(0..2)).radius() is #2: Finite though the graph is not strongly connected (Boost, JGraphT). igraph 0")
    func radius402() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.radius() == 2)
        #expect(graph.eccentricities().radius == 2)
    }

    @Test("DI-403 D(P(0..2)).diameter() is nil: NetworkX raises; igraph `unconn=True` 2")
    func diameter403() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.diameter() == nil)
        #expect(graph.eccentricities().diameter == nil)
    }

    @Test("DI-404 D(P(0..2)).center() is [0]")
    func center404() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.center() == [0])
        #expect(graph.eccentricities().center == [0])
    }

    @Test("DI-405 D(P(0..2)).periphery() is [1, 2]: The vertices of infinite eccentricity")
    func periphery405() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.periphery() == [1, 2])
        #expect(graph.eccentricities().periphery == [1, 2])
    }

    @Test("DI-406 D(P(0..2)).centroid() is [0]")
    func centroid406() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.centroid() == [0])
    }

    @Test("DI-407 D(P(0..2)).wienerIndex() is nil")
    func wienerIndex407() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.wienerIndex() == nil)
    }

    @Test("DI-408 D(P(0..2)).averageShortestPathLength() is nil")
    func averageShortestPathLength408() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.averageShortestPathLength() == nil)
    }

    @Test("DI-409 D(P(0..2)).density is #0.3333333333333333")
    func density409() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.density == 0.3333333333333333)
    }

    @Test("DI-410 D(P(0..2)).diameterPath() is nil")
    func diameterPath410() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.diameterPath() == nil)
    }

    @Test("DI-411 D(P(0..2)).eccentricity(of: 0) is #2")
    func eccentricity411() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.eccentricity(of: 0) == 2)
        #expect(graph.eccentricities().eccentricity(of: 0) == 2)
    }

    @Test("DI-412 D(P(0..2)).eccentricity(of: 2) is nil")
    func eccentricity412() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.eccentricity(of: 2) == nil)
        #expect(graph.eccentricities().eccentricity(of: 2) == nil)
    }

    @Test("DI-413 D(C(0..3)).eccentricities() is [3, 3, 3, 3]: Directed 4-cycle")
    func eccentricities413() {
        // D: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let expected: [Int?] = [3, 3, 3, 3]
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
    }

    @Test("DI-414 D(C(0..3)).diameterPath() is [0, 1, 2, 3]/[0, 1, 2]")
    func diameterPath414() throws {
        // D: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 1, 2, 3])
        #expect(path.edges == [0, 1, 2])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-415 D(C(0..3)).wienerIndex() is #24: Ordered pairs: 4·(1 + 2 + 3)")
    func wienerIndex415() {
        // D: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.wienerIndex() == 24)
    }

    @Test("DI-416 D(C(0..3)).averageShortestPathLength() is #2.0")
    func averageShortestPathLength416() {
        // D: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.averageShortestPathLength() == 2.0)
    }

    @Test("DI-417 D(C(0..3)).density is #0.3333333333333333")
    func density417() {
        // D: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.density == 0.3333333333333333)
    }

    @Test("DI-418 D(0>1, 1>2, 2>0, 0>2).eccentricities() is [1, 2, 2]")
    func eccentricities418() {
        // D: [] 0>1, 1>2, 2>0, 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let expected: [Int?] = [1, 2, 2]
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
    }

    @Test("DI-419 D(0>1, 1>2, 2>0, 0>2).center() is [0]")
    func center419() {
        // D: [] 0>1, 1>2, 2>0, 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.center() == [0])
        #expect(graph.eccentricities().center == [0])
    }

    @Test("DI-420 D(0>1, 1>2, 2>0, 0>2).periphery() is [1, 2]")
    func periphery420() {
        // D: [] 0>1, 1>2, 2>0, 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.periphery() == [1, 2])
        #expect(graph.eccentricities().periphery == [1, 2])
    }

    @Test("DI-421 D(0>1, 1>2, 2>0, 0>2).centroid() is [0]: NetworkX 3.7 `centroid` on a digraph sums out-distances: [0]")
    func centroid421() {
        // D: [] 0>1, 1>2, 2>0, 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.centroid() == [0])
    }

    @Test("DI-422 D(0>1, 1>2, 2>0, 0>2).diameterPath() is [1, 2, 0]/[1, 2]: From 1, the first peripheral vertex, to 0")
    func diameterPath422() throws {
        // D: [] 0>1, 1>2, 2>0, 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [1, 2, 0])
        #expect(path.edges == [1, 2])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-423 D(0>1, 0>2, 1>3).eccentricities() is [2, nil, nil, nil]: An arborescence: only the root reaches everything")
    func eccentricities423() {
        // D: [] 0>1, 0>2, 1>3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let expected: [Int?] = [2, nil, nil, nil]
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
    }

    @Test("DI-424 D(0>1, 0>2, 1>3).center() is [0]")
    func center424() {
        // D: [] 0>1, 0>2, 1>3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.center() == [0])
        #expect(graph.eccentricities().center == [0])
    }

    @Test("DI-425 D(K(4)).eccentricities() is [1, nil, nil, nil]: The acyclic tournament")
    func eccentricities425() {
        // D: [] K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let expected: [Int?] = [1, nil, nil, nil]
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
    }

    @Test("DI-426 D(K(4)).radius() is #1")
    func radius426() {
        // D: [] K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.radius() == 1)
        #expect(graph.eccentricities().radius == 1)
    }

    @Test("DI-427 D(K(4)).periphery() is [1, 2, 3]")
    func periphery427() {
        // D: [] K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.periphery() == [1, 2, 3])
        #expect(graph.eccentricities().periphery == [1, 2, 3])
    }

    @Test("DI-428 D(K(4)).undirected.diameter() is #1: `digraph.undirected` is K₄")
    func undirectedDiameter428() {
        // D: [] K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let view = graph.undirected
        #expect(view.diameter() == 1)
        #expect(view.eccentricities().diameter == 1)
    }

    @Test("DI-429 D(K(4)).undirected.density is #1.0: Each arc an edge: twice the directed density")
    func undirectedDensity429() {
        // D: [] K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let view = graph.undirected
        #expect(view.density == 1.0)
    }

    @Test("DI-430 D(K(4)).density is #0.5")
    func density430() {
        // D: [] K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.density == 0.5)
    }

    @Test("DI-431 D([0..2]; 0>1, 1>0).eccentricities() is [nil, nil, nil]: An isolated vertex")
    func eccentricities431() {
        // D: [0..2] 0>1, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let expected: [Int?] = [nil, nil, nil]
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
    }

    @Test("DI-432 D([0..2]; 0>1, 1>0).center() is [0, 1, 2]: Every eccentricity infinite: every vertex")
    func center432() {
        // D: [0..2] 0>1, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.center() == [0, 1, 2])
        #expect(graph.eccentricities().center == [0, 1, 2])
    }

    @Test("DI-433 D(0>1, 1>0, 1>2, 2>1).eccentricities() is [2, 1, 2]: Both directions: the undirected path's values")
    func eccentricities433() {
        // D: [] 0>1, 1>0, 1>2, 2>1
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let expected: [Int?] = [2, 1, 2]
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
    }

    @Test("DI-434 D(P(0..2)).undirected.eccentricities() is [2, 1, 2]")
    func undirectedEccentricities434() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let view = graph.undirected
        let expected: [Int?] = [2, 1, 2]
        let eccentricities = view.eccentricities()
        let byIndex = (0 ..< view.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = view.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = view.vertices.map { view.eccentricity(of: $0) }
        #expect(oneByOne == expected)
        #expect(view.radius() == eccentricities.radius)
        #expect(view.diameter() == eccentricities.diameter)
        #expect(view.center() == eccentricities.center)
        #expect(view.periphery() == eccentricities.periphery)
    }

    @Test("DI-435 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).directed.eccentricities() is [2, 3, 2, 2, 3]: `graph.directed`: the same values as DI-101")
    func directedEccentricities435() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let view = graph.directed
        let expected: [Int?] = [2, 3, 2, 2, 3]
        let eccentricities = view.eccentricities()
        let byIndex = (0 ..< view.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = view.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = view.vertices.map { view.eccentricity(of: $0) }
        #expect(oneByOne == expected)
        #expect(view.radius() == eccentricities.radius)
        #expect(view.diameter() == eccentricities.diameter)
        #expect(view.center() == eccentricities.center)
        #expect(view.periphery() == eccentricities.periphery)
    }

    @Test("DI-436 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).directed.center() is [1, 3, 4]")
    func directedCenter436() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let view = graph.directed
        #expect(view.center() == [1, 3, 4])
        #expect(view.eccentricities().center == [1, 3, 4])
    }

    @Test("DI-437 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).directed.density is #0.6: Twice the arcs, the same density as DI-109")
    func directedDensity437() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let view = graph.directed
        #expect(view.density == 0.6)
    }

    @Test("DI-438 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).directed.wienerIndex() is #30: Ordered pairs: twice DI-107")
    func directedWienerIndex438() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let view = graph.directed
        #expect(view.wienerIndex() == 30)
    }

    @Test("DI-439 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).directed.averageShortestPathLength() is #1.5: The same as DI-108")
    func directedAverageShortestPathLength439() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let view = graph.directed
        #expect(view.averageShortestPathLength() == 1.5)
    }

    @Test("DI-440 D(0>0).eccentricities() is [0]")
    func eccentricities440() {
        // D: [] 0>0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
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
    }

    @Test("DI-441 D(0>0, 0>1, 1>0).density is #1.5: Loops count (NetworkX); igraph `loops=False` 1.5 too, `loops=True` 0.75")
    func density441() {
        // D: [] 0>0, 0>1, 1>0
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.density == 1.5)
    }

    @Test("DI-442 D([0..9]; lcg(10,25,3)).eccentricities() is [4, 3, nil, nil, 4, 4, 3, 4, 5, 4]")
    func eccentricities442() {
        // D: [0..9] lcg(10,25,3)
        let pairs: [(Int, Int)] = [
            (9, 3), (5, 8), (4, 3), (3, 2), (6, 9), (8, 5), (7, 6), (5, 6), (1, 6), (5, 4), (9, 4), (1, 9),
            (5, 8), (1, 3), (8, 9), (5, 9), (0, 6), (0, 7), (5, 9), (9, 8), (1, 6), (6, 1), (5, 6), (4, 1),
            (1, 0)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let expected: [Int?] = [4, 3, nil, nil, 4, 4, 3, 4, 5, 4]
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
    }

    @Test("DI-443 D([0..9]; lcg(10,25,3)).center() is [1, 6]")
    func center443() {
        // D: [0..9] lcg(10,25,3)
        let pairs: [(Int, Int)] = [
            (9, 3), (5, 8), (4, 3), (3, 2), (6, 9), (8, 5), (7, 6), (5, 6), (1, 6), (5, 4), (9, 4), (1, 9),
            (5, 8), (1, 3), (8, 9), (5, 9), (0, 6), (0, 7), (5, 9), (9, 8), (1, 6), (6, 1), (5, 6), (4, 1),
            (1, 0)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.center() == [1, 6])
        #expect(graph.eccentricities().center == [1, 6])
    }

    @Test("DI-444 D([0..9]; lcg(10,25,3)).diameterPath() is nil")
    func diameterPath444() {
        // D: [0..9] lcg(10,25,3)
        let pairs: [(Int, Int)] = [
            (9, 3), (5, 8), (4, 3), (3, 2), (6, 9), (8, 5), (7, 6), (5, 6), (1, 6), (5, 4), (9, 4), (1, 9),
            (5, 8), (1, 3), (8, 9), (5, 9), (0, 6), (0, 7), (5, 9), (9, 8), (1, 6), (6, 1), (5, 6), (4, 1),
            (1, 0)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.diameterPath() == nil)
    }

    @Test("DI-445 D([0..9]; lcg(10,25,3)).centroid() is [1]")
    func centroid445() {
        // D: [0..9] lcg(10,25,3)
        let pairs: [(Int, Int)] = [
            (9, 3), (5, 8), (4, 3), (3, 2), (6, 9), (8, 5), (7, 6), (5, 6), (1, 6), (5, 4), (9, 4), (1, 9),
            (5, 8), (1, 3), (8, 9), (5, 9), (0, 6), (0, 7), (5, 9), (9, 8), (1, 6), (6, 1), (5, 6), (4, 1),
            (1, 0)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.centroid() == [1])
    }
}
