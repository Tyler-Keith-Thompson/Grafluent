// §F: self-loops and parallel edges, on the `ReferencePseudograph` and `ReferenceDirectedMultigraph`
// (the adjacency lists cannot hold parallel edges). Loops and parallel copies change no distance;
// `diameterPath()` goes through the first copy in the row (DI-503, DI-510); density counts every
// edge, a loop once, so it can exceed 1 (DI-504, DI-507, DI-509). Literals are catalog cells.
// Case IDs (DI-nnn) refer to the catalog; see README.md.

import Distances
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Self-loops and parallel edges")
struct MultigraphDistanceTests {
    @Test("DI-501 U(0-0, 0-1, 0-1, 1-2).eccentricities() is [2, 1, 2]: igraph probe graph: loops and parallel edges change no distance")
    func eccentricities501() {
        // U: [] 0-0, 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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
        let arcs = graph.directed.eccentricities()
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-502 U(0-0, 0-1, 0-1, 1-2).center() is [1]")
    func center502() {
        // U: [] 0-0, 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [1])
        #expect(graph.eccentricities().center == [1])
    }

    @Test("DI-503 U(0-0, 0-1, 0-1, 1-2).diameterPath() is [0, 1, 2]/[1, 3]: The first parallel copy in 0's row (position 1)")
    func diameterPath503() throws {
        // U: [] 0-0, 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [0, 1, 2])
        #expect(path.edges == [1, 3])
        #expect(path.length == graph.diameter())
    }

    @Test("DI-504 U(0-0, 0-1, 0-1, 1-2).density is #1.3333333333333333: Every edge counts, the loop once: 2·4 / (3·2). NetworkX the same; igraph `loops=False` 1.333…, `loops=True` 0.666…")
    func density504() {
        // U: [] 0-0, 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.density == 1.3333333333333333)
    }

    @Test("DI-505 U(0-0, 0-1, 0-1, 1-2).wienerIndex() is #4")
    func wienerIndex505() {
        // U: [] 0-0, 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.wienerIndex() == 4)
    }

    @Test("DI-506 U(0-0, 0-1, 0-1, 1-2).averageShortestPathLength() is #1.3333333333333333")
    func averageShortestPathLength506() {
        // U: [] 0-0, 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageShortestPathLength() == 1.3333333333333333)
    }

    @Test("DI-507 U(0-1, 0-1, 1-2, 1-2, 0-1).density is #1.6666666666666667: Above 1")
    func density507() {
        // U: [] 0-1, 0-1, 1-2, 1-2, 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (1, 2), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.density == 1.6666666666666667)
    }

    @Test("DI-508 D(0>1, 0>1, 1>0).eccentricities() is [1, 1]")
    func eccentricities508() {
        // D: [] 0>1, 0>1, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
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
    }

    @Test("DI-509 D(0>1, 0>1, 1>0).density is #1.5")
    func density509() {
        // D: [] 0>1, 0>1, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.density == 1.5)
    }

    @Test("DI-510 U(1-2, 0-1, 0-1).diameterPath() is [2, 1, 0]/[0, 1]: `vertices` = [1, 2, 0]: from 2 to 0, through the first copy")
    func diameterPath510() throws {
        // U: [] 1-2, 0-1, 0-1
        let pairs: [(Int, Int)] = [(1, 2), (0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let path = try #require(graph.diameterPath())
        #expect(path.vertices == [2, 1, 0])
        #expect(path.edges == [0, 1])
        #expect(path.length == graph.diameter())
    }
}
