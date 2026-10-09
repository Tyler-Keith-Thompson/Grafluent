// §G: weighted measures, `Int` and `Double` weights given by edge position. The lighter of parallel
// edges counts and the path names it (DI-610 – DI-612); a zero-weight loop changes nothing; all-zero
// weights make every vertex central and give the trivial path at `vertices[0]` (DI-614 – DI-616);
// dyadic `Double` weights are exact (DI-617 – DI-619); directed weights (DI-620 – DI-624); a grid
// with weights e mod 3 + 1 (DI-625 – DI-628); `+infinity` is a value, not "unreachable" (DI-629).
// The weighted average needs `BinaryFloatingPoint` weights (DI-609). Literals are catalog cells.
// DI-630 – DI-633 (negative and NaN weights) are exit tests in `DistancePreconditionTests.swift`;
// the weight closure's call order is in `WeightReadingTests.swift`. Case IDs (DI-nnn) refer to the
// catalog; see README.md.

import Distances
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Weighted")
struct WeightedDistanceTests {
    @Test("DI-601 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).eccentricities(weight: [1, 2, 3, 1, 2, 3]) is [4, 5, 3, 4, 5]")
    func eccentricitiesWeighted601() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 2, 3, 1, 2, 3]
        let expected: [Int?] = [4, 5, 3, 4, 5]
        let eccentricities = graph.eccentricities(weight: { w[$0] })
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0, weight: { w[$0] }) }
        #expect(oneByOne == expected)
        #expect(graph.radius(weight: { w[$0] }) == eccentricities.radius)
        #expect(graph.diameter(weight: { w[$0] }) == eccentricities.diameter)
        #expect(graph.center(weight: { w[$0] }) == eccentricities.center)
        #expect(graph.periphery(weight: { w[$0] }) == eccentricities.periphery)
        let arcs = graph.directed.eccentricities(weight: { w[$0.position] })
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-602 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).center(weight: [1, 2, 3, 1, 2, 3]) is [3]")
    func centerWeighted602() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 2, 3, 1, 2, 3]
        #expect(graph.center(weight: { w[$0] }) == [3])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [3])
    }

    @Test("DI-603 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).periphery(weight: [1, 2, 3, 1, 2, 3]) is [2, 5]")
    func peripheryWeighted603() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 2, 3, 1, 2, 3]
        #expect(graph.periphery(weight: { w[$0] }) == [2, 5])
        #expect(graph.eccentricities(weight: { w[$0] }).periphery == [2, 5])
    }

    @Test("DI-604 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).radius(weight: [1, 2, 3, 1, 2, 3]) is #3")
    func radiusWeighted604() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 2, 3, 1, 2, 3]
        #expect(graph.radius(weight: { w[$0] }) == 3)
        #expect(graph.eccentricities(weight: { w[$0] }).radius == 3)
    }

    @Test("DI-605 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).diameter(weight: [1, 2, 3, 1, 2, 3]) is #5")
    func diameterWeighted605() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 2, 3, 1, 2, 3]
        #expect(graph.diameter(weight: { w[$0] }) == 5)
        #expect(graph.eccentricities(weight: { w[$0] }).diameter == 5)
    }

    @Test("DI-606 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).diameterPath(weight: [1, 2, 3, 1, 2, 3]) is [2, 1, 3, 5]/[0, 1, 4] #5")
    func diameterPathWeighted606() throws {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 2, 3, 1, 2, 3]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [2, 1, 3, 5])
        #expect(result.path.edges == [0, 1, 4])
        #expect(result.distance == 5)
    }

    @Test("DI-607 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).centroid(weight: [1, 2, 3, 1, 2, 3]) is [3]")
    func centroidWeighted607() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 2, 3, 1, 2, 3]
        #expect(graph.centroid(weight: { w[$0] }) == [3])
    }

    @Test("DI-608 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).wienerIndex(weight: [1, 2, 3, 1, 2, 3]) is #28")
    func wienerIndexWeighted608() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 2, 3, 1, 2, 3]
        #expect(graph.wienerIndex(weight: { w[$0] }) == 28)
    }

    @Test("DI-609 U(1-2, 1-3, 1-4, 3-4, 3-5, 4-5).averageShortestPathLength(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is #2.8: `Double` weights (the weighted average needs `BinaryFloatingPoint`)")
    func averageShortestPathLengthWeighted609() {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        #expect(graph.averageShortestPathLength(weight: { w[$0] }) == 2.8)
    }

    @Test("DI-610 U(0-1, 0-1, 1-2).eccentricities(weight: [5, 1, 2]) is [3, 2, 3]: Parallel edges: the lighter one counts")
    func eccentricitiesWeighted610() {
        // U: [] 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [5, 1, 2]
        let expected: [Int?] = [3, 2, 3]
        let eccentricities = graph.eccentricities(weight: { w[$0] })
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0, weight: { w[$0] }) }
        #expect(oneByOne == expected)
        #expect(graph.radius(weight: { w[$0] }) == eccentricities.radius)
        #expect(graph.diameter(weight: { w[$0] }) == eccentricities.diameter)
        #expect(graph.center(weight: { w[$0] }) == eccentricities.center)
        #expect(graph.periphery(weight: { w[$0] }) == eccentricities.periphery)
        let arcs = graph.directed.eccentricities(weight: { w[$0.position] })
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-611 U(0-1, 0-1, 1-2).diameterPath(weight: [5, 1, 2]) is [0, 1, 2]/[1, 2] #3: Through position 1, the lighter copy")
    func diameterPathWeighted611() throws {
        // U: [] 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [5, 1, 2]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [1, 2])
        #expect(result.distance == 3)
    }

    @Test("DI-612 U(0-1, 0-1, 1-2).diameterPath(weight: [1, 5, 2]) is [0, 1, 2]/[0, 2] #3")
    func diameterPathWeighted612() throws {
        // U: [] 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 5, 2]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [0, 2])
        #expect(result.distance == 3)
    }

    @Test("DI-613 U(0-0, 0-1).eccentricities(weight: [0, 4]) is [4, 4]: A zero-weight loop changes nothing")
    func eccentricitiesWeighted613() {
        // U: [] 0-0, 0-1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [0, 4]
        let expected: [Int?] = [4, 4]
        let eccentricities = graph.eccentricities(weight: { w[$0] })
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0, weight: { w[$0] }) }
        #expect(oneByOne == expected)
        #expect(graph.radius(weight: { w[$0] }) == eccentricities.radius)
        #expect(graph.diameter(weight: { w[$0] }) == eccentricities.diameter)
        #expect(graph.center(weight: { w[$0] }) == eccentricities.center)
        #expect(graph.periphery(weight: { w[$0] }) == eccentricities.periphery)
        let arcs = graph.directed.eccentricities(weight: { w[$0.position] })
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-614 U(C(0..3)).eccentricities(weight: 0) is [0, 0, 0, 0]: All zero")
    func eccentricitiesWeighted614() {
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [0, 0, 0, 0]
        let eccentricities = graph.eccentricities(weight: { _ in 0 })
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0, weight: { _ in 0 }) }
        #expect(oneByOne == expected)
        #expect(graph.radius(weight: { _ in 0 }) == eccentricities.radius)
        #expect(graph.diameter(weight: { _ in 0 }) == eccentricities.diameter)
        #expect(graph.center(weight: { _ in 0 }) == eccentricities.center)
        #expect(graph.periphery(weight: { _ in 0 }) == eccentricities.periphery)
        let arcs = graph.directed.eccentricities(weight: { _ in 0 })
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-615 U(C(0..3)).center(weight: 0) is [0, 1, 2, 3]")
    func centerWeighted615() {
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center(weight: { _ in 0 }) == [0, 1, 2, 3])
        #expect(graph.eccentricities(weight: { _ in 0 }).center == [0, 1, 2, 3])
    }

    @Test("DI-616 U(C(0..3)).diameterPath(weight: 0) is [0]/[] #0")
    func diameterPathWeighted616() throws {
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try #require(graph.diameterPath(weight: { _ in 0 }))
        #expect(result.path.vertices == [0])
        #expect(result.path.edges == [])
        #expect(result.distance == 0)
    }

    @Test("DI-617 U(C(0..3)).eccentricities(weight: [0.5, 0.25, 0.75, 0.125]) is [0.75, 0.625, 0.75, 0.75]: Dyadic `Double` weights: exact")
    func eccentricitiesWeighted617() {
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.5, 0.25, 0.75, 0.125]
        let expected: [Double?] = [0.75, 0.625, 0.75, 0.75]
        let eccentricities = graph.eccentricities(weight: { w[$0] })
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0, weight: { w[$0] }) }
        #expect(oneByOne == expected)
        #expect(graph.radius(weight: { w[$0] }) == eccentricities.radius)
        #expect(graph.diameter(weight: { w[$0] }) == eccentricities.diameter)
        #expect(graph.center(weight: { w[$0] }) == eccentricities.center)
        #expect(graph.periphery(weight: { w[$0] }) == eccentricities.periphery)
        let arcs = graph.directed.eccentricities(weight: { w[$0.position] })
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-618 U(C(0..3)).center(weight: [0.5, 0.25, 0.75, 0.125]) is [1]")
    func centerWeighted618() {
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.5, 0.25, 0.75, 0.125]
        #expect(graph.center(weight: { w[$0] }) == [1])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [1])
    }

    @Test("DI-619 U(C(0..3)).diameterPath(weight: [0.5, 0.25, 0.75, 0.125]) is [0, 1, 2]/[0, 1] #0.75")
    func diameterPathWeighted619() throws {
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.5, 0.25, 0.75, 0.125]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [0, 1])
        #expect(result.distance == 0.75)
    }

    @Test("DI-620 D(C(0..2), 0>2).eccentricities(weight: [1, 1, 1, 5]) is [2, 2, 2]: The direct arc 0>2 is longer than the way round")
    func eccentricitiesWeighted620() {
        // D: [] C(0..2), 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = [1, 1, 1, 5]
        let expected: [Int?] = [2, 2, 2]
        let eccentricities = graph.eccentricities(weight: { w[$0] })
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0, weight: { w[$0] }) }
        #expect(oneByOne == expected)
        #expect(graph.radius(weight: { w[$0] }) == eccentricities.radius)
        #expect(graph.diameter(weight: { w[$0] }) == eccentricities.diameter)
        #expect(graph.center(weight: { w[$0] }) == eccentricities.center)
        #expect(graph.periphery(weight: { w[$0] }) == eccentricities.periphery)
    }

    @Test("DI-621 D(C(0..2), 0>2).diameterPath(weight: [1, 1, 1, 5]) is [0, 1, 2]/[0, 1] #2")
    func diameterPathWeighted621() throws {
        // D: [] C(0..2), 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = [1, 1, 1, 5]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [0, 1])
        #expect(result.distance == 2)
    }

    @Test("DI-622 D(C(0..2), 0>2).wienerIndex(weight: [1, 1, 1, 5]) is #9")
    func wienerIndexWeighted622() {
        // D: [] C(0..2), 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = [1, 1, 1, 5]
        #expect(graph.wienerIndex(weight: { w[$0] }) == 9)
    }

    @Test("DI-623 D(P(0..2)).eccentricities(weight: [2, 3]) is [5, nil, nil]")
    func eccentricitiesWeighted623() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = [2, 3]
        let expected: [Int?] = [5, nil, nil]
        let eccentricities = graph.eccentricities(weight: { w[$0] })
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0, weight: { w[$0] }) }
        #expect(oneByOne == expected)
        #expect(graph.radius(weight: { w[$0] }) == eccentricities.radius)
        #expect(graph.diameter(weight: { w[$0] }) == eccentricities.diameter)
        #expect(graph.center(weight: { w[$0] }) == eccentricities.center)
        #expect(graph.periphery(weight: { w[$0] }) == eccentricities.periphery)
    }

    @Test("DI-624 D(P(0..2)).radius(weight: [2, 3]) is #5")
    func radiusWeighted624() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = [2, 3]
        #expect(graph.radius(weight: { w[$0] }) == 5)
        #expect(graph.eccentricities(weight: { w[$0] }).radius == 5)
    }

    @Test("DI-625 U(grid(4,4)).eccentricities(weight: e%3+1) is [8, 7, 9, 9, 8, 6, 6, 8, 9, 6, 5, 6, 9, 8, 6, 8]")
    func eccentricitiesWeighted625() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int?] = [8, 7, 9, 9, 8, 6, 6, 8, 9, 6, 5, 6, 9, 8, 6, 8]
        let eccentricities = graph.eccentricities(weight: { $0 % 3 + 1 })
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0, weight: { $0 % 3 + 1 }) }
        #expect(oneByOne == expected)
        #expect(graph.radius(weight: { $0 % 3 + 1 }) == eccentricities.radius)
        #expect(graph.diameter(weight: { $0 % 3 + 1 }) == eccentricities.diameter)
        #expect(graph.center(weight: { $0 % 3 + 1 }) == eccentricities.center)
        #expect(graph.periphery(weight: { $0 % 3 + 1 }) == eccentricities.periphery)
        let arcs = graph.directed.eccentricities(weight: { $0.position % 3 + 1 })
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-626 U(grid(4,4)).center(weight: e%3+1) is [10]")
    func centerWeighted626() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.center(weight: { $0 % 3 + 1 }) == [10])
        #expect(graph.eccentricities(weight: { $0 % 3 + 1 }).center == [10])
    }

    @Test("DI-627 U(grid(4,4)).periphery(weight: e%3+1) is [2, 3, 8, 12]")
    func peripheryWeighted627() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.periphery(weight: { $0 % 3 + 1 }) == [2, 3, 8, 12])
        #expect(graph.eccentricities(weight: { $0 % 3 + 1 }).periphery == [2, 3, 8, 12])
    }

    @Test("DI-628 U(grid(4,4)).centroid(weight: e%3+1) is [10]")
    func centroidWeighted628() {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.centroid(weight: { $0 % 3 + 1 }) == [10])
    }

    @Test("DI-629 U(0-1).eccentricities(weight: [inf]) is [inf, inf]: `+infinity` is a value, not \"unreachable\": the eccentricity is `.some(.infinity)`")
    func eccentricitiesWeighted629() {
        // U: [] 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [.infinity]
        let expected: [Double?] = [.infinity, .infinity]
        let eccentricities = graph.eccentricities(weight: { w[$0] })
        let byIndex = (0 ..< graph.vertexCount).map { eccentricities.eccentricity(ofIndex: $0) }
        #expect(byIndex == expected)
        let byVertex = graph.vertices.map { eccentricities.eccentricity(of: $0) }
        #expect(byVertex == expected)
        let oneByOne = graph.vertices.map { graph.eccentricity(of: $0, weight: { w[$0] }) }
        #expect(oneByOne == expected)
        #expect(graph.radius(weight: { w[$0] }) == eccentricities.radius)
        #expect(graph.diameter(weight: { w[$0] }) == eccentricities.diameter)
        #expect(graph.center(weight: { w[$0] }) == eccentricities.center)
        #expect(graph.periphery(weight: { w[$0] }) == eccentricities.periphery)
        let arcs = graph.directed.eccentricities(weight: { w[$0.position] })
        let viaArcs = (0 ..< graph.vertexCount).map { arcs.eccentricity(ofIndex: $0) }
        #expect(viaArcs == expected)
    }

    @Test("DI-634 U(0-1, 1-2).eccentricity(of: 1, weight: [3, 4]) is #4")
    func eccentricityWeighted634() {
        // U: [] 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [3, 4]
        #expect(graph.eccentricity(of: 1, weight: { w[$0] }) == 4)
        #expect(graph.eccentricities(weight: { w[$0] }).eccentricity(of: 1) == 4)
    }

    @Test("DI-635 U(P(0..2), 3-4).wienerIndex(weight: [1, 1, 1]) is nil")
    func wienerIndexWeighted635() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 1, 1]
        #expect(graph.wienerIndex(weight: { w[$0] }) == nil)
    }

    @Test("DI-636 U(K(4)).centroid(weight: [1, 1, 1, 1, 1, 9]) is [0, 1]: One heavy edge (2–3) pushes its ends out")
    func centroidWeighted636() {
        // U: [] K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1, 1, 1, 1, 1, 9]
        #expect(graph.centroid(weight: { w[$0] }) == [0, 1])
    }
}
