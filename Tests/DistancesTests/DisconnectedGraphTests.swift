// §D: undirected graphs that are not connected. Every eccentricity is infinite (nil), so the radius
// and the diameter are nil, every vertex is in the center and the periphery and the centroid
// (nil == nil, as JGraphT and scipy's infinities give), the Wiener index and the average are nil,
// and `diameterPath()` is nil; density still counts edges (DI-310). An isolated vertex is not a
// center of eccentricity 0 (igraph's reading). Literals are catalog cells. Case IDs (DI-nnn) refer
// to the catalog; see README.md.

import Distances
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Disconnected undirected graphs")
struct DisconnectedGraphTests {
    @Test("DI-301 U(P(0..2), 3-4).eccentricities() is [nil, nil, nil, nil, nil]: NetworkX raises; igraph ignores unreachable vertices and says [2, 1, 2, 1, 1]")
    func eccentricities301() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [nil, nil, nil, nil, nil]
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

    @Test("DI-302 U(P(0..2), 3-4).radius() is nil: igraph 1")
    func radius302() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.radius() == nil)
        #expect(graph.eccentricities().radius == nil)
    }

    @Test("DI-303 U(P(0..2), 3-4).diameter() is nil: igraph `unconn=True`: 2 (the largest finite); `unconn=False`: inf")
    func diameter303() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.diameter() == nil)
        #expect(graph.eccentricities().diameter == nil)
    }

    @Test("DI-304 U(P(0..2), 3-4).center() is [0, 1, 2, 3, 4]")
    func center304() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [0, 1, 2, 3, 4])
        #expect(graph.eccentricities().center == [0, 1, 2, 3, 4])
    }

    @Test("DI-305 U(P(0..2), 3-4).periphery() is [0, 1, 2, 3, 4]")
    func periphery305() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.periphery() == [0, 1, 2, 3, 4])
        #expect(graph.eccentricities().periphery == [0, 1, 2, 3, 4])
    }

    @Test("DI-306 U(P(0..2), 3-4).diameterPath() is nil: igraph `get_diameter` returns [0, 1, 2]")
    func diameterPath306() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.diameterPath() == nil)
    }

    @Test("DI-307 U(P(0..2), 3-4).centroid() is [0, 1, 2, 3, 4]: NetworkX raises `NetworkXNoPath`")
    func centroid307() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid() == [0, 1, 2, 3, 4])
    }

    @Test("DI-308 U(P(0..2), 3-4).wienerIndex() is nil: NetworkX `inf`")
    func wienerIndex308() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.wienerIndex() == nil)
    }

    @Test("DI-309 U(P(0..2), 3-4).averageShortestPathLength() is nil: igraph `unconn=True` averages the reachable pairs")
    func averageShortestPathLength309() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.averageShortestPathLength() == nil)
    }

    @Test("DI-310 U(P(0..2), 3-4).density is #0.3")
    func density310() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.density == 0.3)
    }

    @Test("DI-311 U([0..3]; P(0..2)).eccentricities() is [nil, nil, nil, nil]: An isolated vertex. igraph: [2, 1, 2, 0], radius 0")
    func eccentricities311() {
        // U: [0..3] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [nil, nil, nil, nil]
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

    @Test("DI-312 U([0..3]; P(0..2)).radius() is nil")
    func radius312() {
        // U: [0..3] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.radius() == nil)
        #expect(graph.eccentricities().radius == nil)
    }

    @Test("DI-313 U([0..3]; P(0..2)).center() is [0, 1, 2, 3]")
    func center313() {
        // U: [0..3] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center() == [0, 1, 2, 3])
        #expect(graph.eccentricities().center == [0, 1, 2, 3])
    }

    @Test("DI-314 U([0..3]; P(0..2)).eccentricity(of: 1) is nil")
    func eccentricity314() {
        // U: [0..3] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.eccentricity(of: 1) == nil)
        #expect(graph.eccentricities().eccentricity(of: 1) == nil)
    }

    @Test("DI-315 U([0..3]; P(0..2)).eccentricity(of: 3) is nil")
    func eccentricity315() {
        // U: [0..3] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.eccentricity(of: 3) == nil)
        #expect(graph.eccentricities().eccentricity(of: 3) == nil)
    }

    @Test("DI-316 U(P(0..2), 3-4).diameter(weight: [1, 1, 1]) is nil")
    func diameterWeighted316() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 1, 1]
        #expect(graph.diameter(weight: { w[$0] }) == nil)
        #expect(graph.eccentricities(weight: { w[$0] }).diameter == nil)
    }
}
