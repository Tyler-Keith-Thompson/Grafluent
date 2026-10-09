// The Int-weighted rows of §C and §G again with the same weights as `Double`, and, where a weight is
// zero, with `-0.0` for each zero (not below `.zero`, so allowed, and equal to 0). The values are
// the Int rows' (every weight here is a small integer, so every sum is exact); each literal was
// computed by `ref.py` on the row with its weights rewritten. Case IDs (DI-nnn) refer to the
// catalog; see README.md.

import Distances
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Double weights")
struct DoubleWeightTests {
    @Test("DI-228 with Double weights: U: [] P(0..4).center(weight: [1.0, 1.0, 1.0, 10.0]) is [3] (the Int row gives [3])")
    func centerWeighted228Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 1.0, 1.0, 10.0]
        #expect(graph.center(weight: { w[$0] }) == [3])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [3])
    }

    @Test("DI-229 with Double weights: U: [] P(0..3).center(weight: [0.0, 1.0, 0.0]) is [0, 1, 2, 3] (the Int row gives [0, 1, 2, 3])")
    func centerWeighted229Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.0, 1.0, 0.0]
        #expect(graph.center(weight: { w[$0] }) == [0, 1, 2, 3])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [0, 1, 2, 3])
    }

    @Test("DI-229 with Double weights, -0.0 for each zero: U: [] P(0..3).center(weight: [-0.0, 1.0, -0.0]) is [0, 1, 2, 3] (the Int row gives [0, 1, 2, 3])")
    func centerWeighted229NegativeZero() {
        // Computed with ref.py: the catalog row with the weights as Double, -0.0 for each zero.
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [-0.0, 1.0, -0.0]
        #expect(graph.center(weight: { w[$0] }) == [0, 1, 2, 3])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [0, 1, 2, 3])
    }

    @Test("DI-230 with Double weights: U: [] P(0..3).center(weight: [1.0, 0.0, 1.0]) is [1, 2] (the Int row gives [1, 2])")
    func centerWeighted230Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 0.0, 1.0]
        #expect(graph.center(weight: { w[$0] }) == [1, 2])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [1, 2])
    }

    @Test("DI-230 with Double weights, -0.0 for each zero: U: [] P(0..3).center(weight: [1.0, -0.0, 1.0]) is [1, 2] (the Int row gives [1, 2])")
    func centerWeighted230NegativeZero() {
        // Computed with ref.py: the catalog row with the weights as Double, -0.0 for each zero.
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, -0.0, 1.0]
        #expect(graph.center(weight: { w[$0] }) == [1, 2])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [1, 2])
    }

    @Test("DI-231 with Double weights: U: [] S(0;1..4).center(weight: [3.0, 1.0, 30.0, 2.0]) is [0] (the Int row gives [0])")
    func centerWeighted231Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [3.0, 1.0, 30.0, 2.0]
        #expect(graph.center(weight: { w[$0] }) == [0])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [0])
    }

    @Test("DI-233 with Double weights: U: [] P(0..4).diameter(weight: [1.0, 1.0, 1.0, 10.0]) is #13.0 (the Int row gives #13)")
    func diameterWeighted233Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 1.0, 1.0, 10.0]
        #expect(graph.diameter(weight: { w[$0] }) == 13.0)
        #expect(graph.eccentricities(weight: { w[$0] }).diameter == 13.0)
    }

    @Test("DI-234 with Double weights: U: [] P(0..4).diameterPath(weight: [1.0, 1.0, 1.0, 10.0]) is [0, 1, 2, 3, 4]/[0, 1, 2, 3] #13.0 (the Int row gives [0, 1, 2, 3, 4]/[0, 1, 2, 3] #13)")
    func diameterPathWeighted234Double() throws {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 1.0, 1.0, 10.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2, 3, 4])
        #expect(result.path.edges == [0, 1, 2, 3])
        #expect(result.distance == 13.0)
    }

    @Test("DI-235 with Double weights: U: [] S(0;1..4).diameterPath(weight: [3.0, 1.0, 3.0, 2.0]) is [1, 0, 3]/[0, 2] #6.0 (the Int row gives [1, 0, 3]/[0, 2] #6)")
    func diameterPathWeighted235Double() throws {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [3.0, 1.0, 3.0, 2.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [1, 0, 3])
        #expect(result.path.edges == [0, 2])
        #expect(result.distance == 6.0)
    }

    @Test("DI-236 with Double weights: U: [] P(0..2).diameterPath(weight: [0.0, 0.0]) is [0]/[] #0 (the Int row gives [0]/[] #0)")
    func diameterPathWeighted236Double() throws {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.0, 0.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0])
        #expect(result.path.edges == [])
        #expect(result.distance == 0)
    }

    @Test("DI-236 with Double weights, -0.0 for each zero: U: [] P(0..2).diameterPath(weight: [-0.0, -0.0]) is [0]/[] #0 (the Int row gives [0]/[] #0)")
    func diameterPathWeighted236NegativeZero() throws {
        // Computed with ref.py: the catalog row with the weights as Double, -0.0 for each zero.
        // U: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [-0.0, -0.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0])
        #expect(result.path.edges == [])
        #expect(result.distance == 0)
    }

    @Test("DI-237 with Double weights: U: [] P(0..3).diameterPath(weight: [0.0, 1.0, 0.0]) is [0, 1, 2]/[0, 1] #1.0 (the Int row gives [0, 1, 2]/[0, 1] #1)")
    func diameterPathWeighted237Double() throws {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.0, 1.0, 0.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [0, 1])
        #expect(result.distance == 1.0)
    }

    @Test("DI-237 with Double weights, -0.0 for each zero: U: [] P(0..3).diameterPath(weight: [-0.0, 1.0, -0.0]) is [0, 1, 2]/[0, 1] #1.0 (the Int row gives [0, 1, 2]/[0, 1] #1)")
    func diameterPathWeighted237NegativeZero() throws {
        // Computed with ref.py: the catalog row with the weights as Double, -0.0 for each zero.
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [-0.0, 1.0, -0.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [0, 1])
        #expect(result.distance == 1.0)
    }

    @Test("DI-239 with Double weights: U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8.diameterPath(weight: [5.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]) is [6, 4, 1, 0, 2, 5, 8]/[5, 3, 0, 1, 4, 7] #10.0 (the Int row gives [6, 4, 1, 0, 2, 5, 8]/[5, 3, 0, 1, 4, 7] #10)")
    func diameterPathWeighted239Double() throws {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [5.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(result.path.edges == [5, 3, 0, 1, 4, 7])
        #expect(result.distance == 10.0)
    }

    @Test("DI-316 with Double weights: U: [] P(0..2), 3-4.diameter(weight: [1.0, 1.0, 1.0]) is nil (the Int row gives nil)")
    func diameterWeighted316Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 1.0, 1.0]
        #expect(graph.diameter(weight: { w[$0] }) == nil)
        #expect(graph.eccentricities(weight: { w[$0] }).diameter == nil)
    }

    @Test("DI-601 with Double weights: U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5.eccentricities(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is [4.0, 5.0, 3.0, 4.0, 5.0] (the Int row gives [4, 5, 3, 4, 5])")
    func eccentricitiesWeighted601Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        let expected: [Double?] = [4.0, 5.0, 3.0, 4.0, 5.0]
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

    @Test("DI-602 with Double weights: U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5.center(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is [3] (the Int row gives [3])")
    func centerWeighted602Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        #expect(graph.center(weight: { w[$0] }) == [3])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [3])
    }

    @Test("DI-603 with Double weights: U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5.periphery(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is [2, 5] (the Int row gives [2, 5])")
    func peripheryWeighted603Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        #expect(graph.periphery(weight: { w[$0] }) == [2, 5])
        #expect(graph.eccentricities(weight: { w[$0] }).periphery == [2, 5])
    }

    @Test("DI-604 with Double weights: U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5.radius(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is #3.0 (the Int row gives #3)")
    func radiusWeighted604Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        #expect(graph.radius(weight: { w[$0] }) == 3.0)
        #expect(graph.eccentricities(weight: { w[$0] }).radius == 3.0)
    }

    @Test("DI-605 with Double weights: U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5.diameter(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is #5.0 (the Int row gives #5)")
    func diameterWeighted605Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        #expect(graph.diameter(weight: { w[$0] }) == 5.0)
        #expect(graph.eccentricities(weight: { w[$0] }).diameter == 5.0)
    }

    @Test("DI-606 with Double weights: U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5.diameterPath(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is [2, 1, 3, 5]/[0, 1, 4] #5.0 (the Int row gives [2, 1, 3, 5]/[0, 1, 4] #5)")
    func diameterPathWeighted606Double() throws {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [2, 1, 3, 5])
        #expect(result.path.edges == [0, 1, 4])
        #expect(result.distance == 5.0)
    }

    @Test("DI-607 with Double weights: U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5.centroid(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is [3] (the Int row gives [3])")
    func centroidWeighted607Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        #expect(graph.centroid(weight: { w[$0] }) == [3])
    }

    @Test("DI-608 with Double weights: U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5.wienerIndex(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is #28.0 (the Int row gives #28)")
    func wienerIndexWeighted608Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        #expect(graph.wienerIndex(weight: { w[$0] }) == 28.0)
    }

    @Test("DI-610 with Double weights: U: [] 0-1, 0-1, 1-2.eccentricities(weight: [5.0, 1.0, 2.0]) is [3.0, 2.0, 3.0] (the Int row gives [3, 2, 3])")
    func eccentricitiesWeighted610Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [5.0, 1.0, 2.0]
        let expected: [Double?] = [3.0, 2.0, 3.0]
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

    @Test("DI-611 with Double weights: U: [] 0-1, 0-1, 1-2.diameterPath(weight: [5.0, 1.0, 2.0]) is [0, 1, 2]/[1, 2] #3.0 (the Int row gives [0, 1, 2]/[1, 2] #3)")
    func diameterPathWeighted611Double() throws {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [5.0, 1.0, 2.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [1, 2])
        #expect(result.distance == 3.0)
    }

    @Test("DI-612 with Double weights: U: [] 0-1, 0-1, 1-2.diameterPath(weight: [1.0, 5.0, 2.0]) is [0, 1, 2]/[0, 2] #3.0 (the Int row gives [0, 1, 2]/[0, 2] #3)")
    func diameterPathWeighted612Double() throws {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 5.0, 2.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [0, 2])
        #expect(result.distance == 3.0)
    }

    @Test("DI-613 with Double weights: U: [] 0-0, 0-1.eccentricities(weight: [0.0, 4.0]) is [4.0, 4.0] (the Int row gives [4, 4])")
    func eccentricitiesWeighted613Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 0-0, 0-1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.0, 4.0]
        let expected: [Double?] = [4.0, 4.0]
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

    @Test("DI-613 with Double weights, -0.0 for each zero: U: [] 0-0, 0-1.eccentricities(weight: [-0.0, 4.0]) is [4.0, 4.0] (the Int row gives [4, 4])")
    func eccentricitiesWeighted613NegativeZero() {
        // Computed with ref.py: the catalog row with the weights as Double, -0.0 for each zero.
        // U: [] 0-0, 0-1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [-0.0, 4.0]
        let expected: [Double?] = [4.0, 4.0]
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

    @Test("DI-614 with Double weights: U: [] C(0..3).eccentricities(weight: [0.0, 0.0, 0.0, 0.0]) is [0, 0.0, 0.0, 0.0] (the Int row gives [0, 0, 0, 0])")
    func eccentricitiesWeighted614Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.0, 0.0, 0.0, 0.0]
        let expected: [Double?] = [0, 0.0, 0.0, 0.0]
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

    @Test("DI-614 with Double weights, -0.0 for each zero: U: [] C(0..3).eccentricities(weight: [-0.0, -0.0, -0.0, -0.0]) is [0, 0.0, 0.0, 0.0] (the Int row gives [0, 0, 0, 0])")
    func eccentricitiesWeighted614NegativeZero() {
        // Computed with ref.py: the catalog row with the weights as Double, -0.0 for each zero.
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [-0.0, -0.0, -0.0, -0.0]
        let expected: [Double?] = [0, 0.0, 0.0, 0.0]
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

    @Test("DI-615 with Double weights: U: [] C(0..3).center(weight: [0.0, 0.0, 0.0, 0.0]) is [0, 1, 2, 3] (the Int row gives [0, 1, 2, 3])")
    func centerWeighted615Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.0, 0.0, 0.0, 0.0]
        #expect(graph.center(weight: { w[$0] }) == [0, 1, 2, 3])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [0, 1, 2, 3])
    }

    @Test("DI-615 with Double weights, -0.0 for each zero: U: [] C(0..3).center(weight: [-0.0, -0.0, -0.0, -0.0]) is [0, 1, 2, 3] (the Int row gives [0, 1, 2, 3])")
    func centerWeighted615NegativeZero() {
        // Computed with ref.py: the catalog row with the weights as Double, -0.0 for each zero.
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [-0.0, -0.0, -0.0, -0.0]
        #expect(graph.center(weight: { w[$0] }) == [0, 1, 2, 3])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [0, 1, 2, 3])
    }

    @Test("DI-616 with Double weights: U: [] C(0..3).diameterPath(weight: [0.0, 0.0, 0.0, 0.0]) is [0]/[] #0 (the Int row gives [0]/[] #0)")
    func diameterPathWeighted616Double() throws {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0.0, 0.0, 0.0, 0.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0])
        #expect(result.path.edges == [])
        #expect(result.distance == 0)
    }

    @Test("DI-616 with Double weights, -0.0 for each zero: U: [] C(0..3).diameterPath(weight: [-0.0, -0.0, -0.0, -0.0]) is [0]/[] #0 (the Int row gives [0]/[] #0)")
    func diameterPathWeighted616NegativeZero() throws {
        // Computed with ref.py: the catalog row with the weights as Double, -0.0 for each zero.
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [-0.0, -0.0, -0.0, -0.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0])
        #expect(result.path.edges == [])
        #expect(result.distance == 0)
    }

    @Test("DI-620 with Double weights: D: [] C(0..2), 0>2.eccentricities(weight: [1.0, 1.0, 1.0, 5.0]) is [2.0, 2.0, 2.0] (the Int row gives [2, 2, 2])")
    func eccentricitiesWeighted620Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // D: [] C(0..2), 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: [Double] = [1.0, 1.0, 1.0, 5.0]
        let expected: [Double?] = [2.0, 2.0, 2.0]
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

    @Test("DI-621 with Double weights: D: [] C(0..2), 0>2.diameterPath(weight: [1.0, 1.0, 1.0, 5.0]) is [0, 1, 2]/[0, 1] #2.0 (the Int row gives [0, 1, 2]/[0, 1] #2)")
    func diameterPathWeighted621Double() throws {
        // Computed with ref.py: the catalog row with the weights as Double.
        // D: [] C(0..2), 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: [Double] = [1.0, 1.0, 1.0, 5.0]
        let result = try #require(graph.diameterPath(weight: { w[$0] }))
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [0, 1])
        #expect(result.distance == 2.0)
    }

    @Test("DI-622 with Double weights: D: [] C(0..2), 0>2.wienerIndex(weight: [1.0, 1.0, 1.0, 5.0]) is #9.0 (the Int row gives #9)")
    func wienerIndexWeighted622Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // D: [] C(0..2), 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: [Double] = [1.0, 1.0, 1.0, 5.0]
        #expect(graph.wienerIndex(weight: { w[$0] }) == 9.0)
    }

    @Test("DI-623 with Double weights: D: [] P(0..2).eccentricities(weight: [2.0, 3.0]) is [5.0, nil, nil] (the Int row gives [5, nil, nil])")
    func eccentricitiesWeighted623Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: [Double] = [2.0, 3.0]
        let expected: [Double?] = [5.0, nil, nil]
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

    @Test("DI-624 with Double weights: D: [] P(0..2).radius(weight: [2.0, 3.0]) is #5.0 (the Int row gives #5)")
    func radiusWeighted624Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w: [Double] = [2.0, 3.0]
        #expect(graph.radius(weight: { w[$0] }) == 5.0)
        #expect(graph.eccentricities(weight: { w[$0] }).radius == 5.0)
    }

    @Test("DI-625 with Double weights: U: [] grid(4,4).eccentricities(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is [8.0, 7.0, 9.0, 9.0, 8.0, 6.0, 6.0, 8.0, 9.0, 6.0, 5.0, 6.0, 9.0, 8.0, 6.0, 8.0] (the Int row gives [8, 7, 9, 9, 8, 6, 6, 8, 9, 6, 5, 6, 9, 8, 6, 8])")
    func eccentricitiesWeighted625Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        let expected: [Double?] = [8.0, 7.0, 9.0, 9.0, 8.0, 6.0, 6.0, 8.0, 9.0, 6.0, 5.0, 6.0, 9.0, 8.0, 6.0, 8.0]
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

    @Test("DI-626 with Double weights: U: [] grid(4,4).center(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is [10] (the Int row gives [10])")
    func centerWeighted626Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        #expect(graph.center(weight: { w[$0] }) == [10])
        #expect(graph.eccentricities(weight: { w[$0] }).center == [10])
    }

    @Test("DI-627 with Double weights: U: [] grid(4,4).periphery(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is [2, 3, 8, 12] (the Int row gives [2, 3, 8, 12])")
    func peripheryWeighted627Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        #expect(graph.periphery(weight: { w[$0] }) == [2, 3, 8, 12])
        #expect(graph.eccentricities(weight: { w[$0] }).periphery == [2, 3, 8, 12])
    }

    @Test("DI-628 with Double weights: U: [] grid(4,4).centroid(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0]) is [10] (the Int row gives [10])")
    func centroidWeighted628Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
        #expect(graph.centroid(weight: { w[$0] }) == [10])
    }

    @Test("DI-634 with Double weights: U: [] 0-1, 1-2.eccentricity(of: 1, weight: [3.0, 4.0]) is #4.0 (the Int row gives #4)")
    func eccentricityWeighted634Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [3.0, 4.0]
        #expect(graph.eccentricity(of: 1, weight: { w[$0] }) == 4.0)
        #expect(graph.eccentricities(weight: { w[$0] }).eccentricity(of: 1) == 4.0)
    }

    @Test("DI-635 with Double weights: U: [] P(0..2), 3-4.wienerIndex(weight: [1.0, 1.0, 1.0]) is nil (the Int row gives nil)")
    func wienerIndexWeighted635Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 1.0, 1.0]
        #expect(graph.wienerIndex(weight: { w[$0] }) == nil)
    }

    @Test("DI-636 with Double weights: U: [] K(4).centroid(weight: [1.0, 1.0, 1.0, 1.0, 1.0, 9.0]) is [0, 1] (the Int row gives [0, 1])")
    func centroidWeighted636Double() {
        // Computed with ref.py: the catalog row with the weights as Double.
        // U: [] K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1.0, 1.0, 1.0, 1.0, 1.0, 9.0]
        #expect(graph.centroid(weight: { w[$0] }) == [0, 1])
    }
}
