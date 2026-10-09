// The catalog rows on the package's representations (not a catalog section). Every row of §A – §G
// whose graph has no parallel edges and no `~rev` is repeated on `UndirectedAdjacencyList` or
// `AdjacencyList` built in written order, so vertex order, rows and positions are the catalog's
// (the vertex order is asserted first) and the values are the catalog cells;
// `UndirectedAdjacencyList` lends its index rows to the algorithms instead of `incidentEdges`.
// Directed rows on the vertices 0..<n are repeated on `CompressedSparseRow` with the arcs rewritten
// in row-major order (the representation's own positions) and the weights carried with their arcs;
// those literals were computed by `ref.py` on the rewritten graph, and every one but the edge
// positions of a path equals the catalog cell. One test per graph, each row in its own `do` block.
// Case IDs (DI-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import Distances
import GraphProtocols
import Testing

@Suite("Distances on every representation")
struct DistanceRepresentationTests {
    @Test("DI-001, DI-002 … DI-010 on UndirectedAdjacencyList: U: []")
    func undirectedAdjacencyList001() {
        // U: []
        let graph = UndirectedAdjacencyList<Int>(vertices: [], edges: [])
        #expect(Array(graph.vertices) == [])
        do {
            // DI-001: eccentricities
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
        do {
            // DI-002: radius
            #expect(graph.radius() == nil)
            #expect(graph.eccentricities().radius == nil)
        }
        do {
            // DI-003: diameter
            #expect(graph.diameter() == nil)
            #expect(graph.eccentricities().diameter == nil)
        }
        do {
            // DI-004: center
            #expect(graph.center() == [])
            #expect(graph.eccentricities().center == [])
        }
        do {
            // DI-005: periphery
            #expect(graph.periphery() == [])
            #expect(graph.eccentricities().periphery == [])
        }
        do {
            // DI-006: diameterPath
            #expect(graph.diameterPath() == nil)
        }
        do {
            // DI-007: centroid
            #expect(graph.centroid() == [])
        }
        do {
            // DI-008: wienerIndex
            #expect(graph.wienerIndex() == 0)
        }
        do {
            // DI-009: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == nil)
        }
        do {
            // DI-010: density
            #expect(graph.density == 0.0)
        }
    }

    @Test("DI-011, DI-012 on AdjacencyList: D: []")
    func adjacencyList011() {
        // D: []
        let graph = AdjacencyList<Int>(vertices: [], edges: [])
        #expect(Array(graph.vertices) == [])
        do {
            // DI-011: diameter
            #expect(graph.diameter() == nil)
            #expect(graph.eccentricities().diameter == nil)
        }
        do {
            // DI-012: density
            #expect(graph.density == 0.0)
        }
    }

    @Test("DI-013, DI-014 … DI-043 on UndirectedAdjacencyList: U: [0]")
    func undirectedAdjacencyList013() throws {
        // U: [0]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0], edges: [])
        #expect(Array(graph.vertices) == [0])
        do {
            // DI-013: eccentricities
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
        do {
            // DI-014: radius
            #expect(graph.radius() == 0)
            #expect(graph.eccentricities().radius == 0)
        }
        do {
            // DI-015: diameter
            #expect(graph.diameter() == 0)
            #expect(graph.eccentricities().diameter == 0)
        }
        do {
            // DI-016: center
            #expect(graph.center() == [0])
            #expect(graph.eccentricities().center == [0])
        }
        do {
            // DI-017: periphery
            #expect(graph.periphery() == [0])
            #expect(graph.eccentricities().periphery == [0])
        }
        do {
            // DI-018: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0])
            #expect(path.edges == [])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-019: centroid
            #expect(graph.centroid() == [0])
        }
        do {
            // DI-020: wienerIndex
            #expect(graph.wienerIndex() == 0)
        }
        do {
            // DI-021: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == 0.0)
        }
        do {
            // DI-022: density
            #expect(graph.density == 0.0)
        }
        do {
            // DI-023: center(weight: [])
            var calls = 0
            let weight = { (_: Int) -> Int in
                calls += 1
                return 1
            }
            #expect(graph.center(weight: weight) == [0])
            #expect(graph.eccentricities(weight: weight).center == [0])
            #expect(calls == 0)
        }
        do {
            // DI-024: diameterPath(weight: [])
            var calls = 0
            let weight = { (_: Int) -> Int in
                calls += 1
                return 1
            }
            let result = try #require(graph.diameterPath(weight: weight))
            #expect(result.path.vertices == [0])
            #expect(result.path.edges == [])
            #expect(result.distance == 0)
            #expect(calls == 0)
        }
        do {
            // DI-043: eccentricity(of: 0)
            #expect(graph.eccentricity(of: 0) == 0)
            #expect(graph.eccentricities().eccentricity(of: 0) == 0)
        }
    }

    @Test("DI-025, DI-026 … DI-034 on UndirectedAdjacencyList: U: [0, 1]")
    func undirectedAdjacencyList025() {
        // U: [0, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [])
        #expect(Array(graph.vertices) == [0, 1])
        do {
            // DI-025: eccentricities
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
        do {
            // DI-026: radius
            #expect(graph.radius() == nil)
            #expect(graph.eccentricities().radius == nil)
        }
        do {
            // DI-027: diameter
            #expect(graph.diameter() == nil)
            #expect(graph.eccentricities().diameter == nil)
        }
        do {
            // DI-028: center
            #expect(graph.center() == [0, 1])
            #expect(graph.eccentricities().center == [0, 1])
        }
        do {
            // DI-029: periphery
            #expect(graph.periphery() == [0, 1])
            #expect(graph.eccentricities().periphery == [0, 1])
        }
        do {
            // DI-030: diameterPath
            #expect(graph.diameterPath() == nil)
        }
        do {
            // DI-031: centroid
            #expect(graph.centroid() == [0, 1])
        }
        do {
            // DI-032: wienerIndex
            #expect(graph.wienerIndex() == nil)
        }
        do {
            // DI-033: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == nil)
        }
        do {
            // DI-034: density
            #expect(graph.density == 0.0)
        }
    }

    @Test("DI-035, DI-036 … DI-629 on UndirectedAdjacencyList: U: [] 0-1")
    func undirectedAdjacencyList035() throws {
        // U: [] 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1])
        do {
            // DI-035: eccentricities
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
        do {
            // DI-036: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 1])
            #expect(path.edges == [0])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-038: density
            #expect(graph.density == 1.0)
        }
        do {
            // DI-629: eccentricities(weight: [inf])
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
    }

    @Test("DI-037 on UndirectedAdjacencyList: U: [] 1-0")
    func undirectedAdjacencyList037() throws {
        // U: [] 1-0
        let pairs: [(Int, Int)] = [(1, 0)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [1, 0])
        do {
            // DI-037: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [1, 0])
            #expect(path.edges == [0])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-039, DI-040, DI-041 on UndirectedAdjacencyList: U: [] 0-0")
    func undirectedAdjacencyList039() throws {
        // U: [] 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0])
        do {
            // DI-039: eccentricities
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
        do {
            // DI-040: density
            #expect(graph.density == 0.0)
        }
        do {
            // DI-041: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0])
            #expect(path.edges == [])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-101, DI-102 … DI-609 on UndirectedAdjacencyList: U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5")
    func undirectedAdjacencyList101() throws {
        // U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 4), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [1, 2, 3, 4, 5])
        do {
            // DI-101: eccentricities
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
        do {
            // DI-102: center
            #expect(graph.center() == [1, 3, 4])
            #expect(graph.eccentricities().center == [1, 3, 4])
        }
        do {
            // DI-103: periphery
            #expect(graph.periphery() == [2, 5])
            #expect(graph.eccentricities().periphery == [2, 5])
        }
        do {
            // DI-104: radius
            #expect(graph.radius() == 2)
            #expect(graph.eccentricities().radius == 2)
        }
        do {
            // DI-105: diameter
            #expect(graph.diameter() == 3)
            #expect(graph.eccentricities().diameter == 3)
        }
        do {
            // DI-106: centroid
            #expect(graph.centroid() == [1, 3, 4])
        }
        do {
            // DI-107: wienerIndex
            #expect(graph.wienerIndex() == 15)
        }
        do {
            // DI-108: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == 1.5)
        }
        do {
            // DI-109: density
            #expect(graph.density == 0.6)
        }
        do {
            // DI-110: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [2, 1, 3, 5])
            #expect(path.edges == [0, 1, 4])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-601: eccentricities(weight: [1, 2, 3, 1, 2, 3])
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
        do {
            // DI-602: center(weight: [1, 2, 3, 1, 2, 3])
            let w = [1, 2, 3, 1, 2, 3]
            #expect(graph.center(weight: { w[$0] }) == [3])
            #expect(graph.eccentricities(weight: { w[$0] }).center == [3])
        }
        do {
            // DI-603: periphery(weight: [1, 2, 3, 1, 2, 3])
            let w = [1, 2, 3, 1, 2, 3]
            #expect(graph.periphery(weight: { w[$0] }) == [2, 5])
            #expect(graph.eccentricities(weight: { w[$0] }).periphery == [2, 5])
        }
        do {
            // DI-604: radius(weight: [1, 2, 3, 1, 2, 3])
            let w = [1, 2, 3, 1, 2, 3]
            #expect(graph.radius(weight: { w[$0] }) == 3)
            #expect(graph.eccentricities(weight: { w[$0] }).radius == 3)
        }
        do {
            // DI-605: diameter(weight: [1, 2, 3, 1, 2, 3])
            let w = [1, 2, 3, 1, 2, 3]
            #expect(graph.diameter(weight: { w[$0] }) == 5)
            #expect(graph.eccentricities(weight: { w[$0] }).diameter == 5)
        }
        do {
            // DI-606: diameterPath(weight: [1, 2, 3, 1, 2, 3])
            let w = [1, 2, 3, 1, 2, 3]
            let result = try #require(graph.diameterPath(weight: { w[$0] }))
            #expect(result.path.vertices == [2, 1, 3, 5])
            #expect(result.path.edges == [0, 1, 4])
            #expect(result.distance == 5)
        }
        do {
            // DI-607: centroid(weight: [1, 2, 3, 1, 2, 3])
            let w = [1, 2, 3, 1, 2, 3]
            #expect(graph.centroid(weight: { w[$0] }) == [3])
        }
        do {
            // DI-608: wienerIndex(weight: [1, 2, 3, 1, 2, 3])
            let w = [1, 2, 3, 1, 2, 3]
            #expect(graph.wienerIndex(weight: { w[$0] }) == 28)
        }
        do {
            // DI-609: averageShortestPathLength(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0])
            let w: [Double] = [1.0, 2.0, 3.0, 1.0, 2.0, 3.0]
            #expect(graph.averageShortestPathLength(weight: { w[$0] }) == 2.8)
        }
    }

    @Test("DI-111, DI-112 … DI-628 on UndirectedAdjacencyList: U: [] grid(4,4)")
    func undirectedAdjacencyList111() throws {
        // U: [] grid(4,4)
        let pairs: [(Int, Int)] = (0 ..< 16).flatMap { v -> [(Int, Int)] in (v % 4 + 1 < 4 ? [(v, v + 1)] : []) + (v / 4 + 1 < 4 ? [(v, v + 4)] : []) }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
        do {
            // DI-111: eccentricities
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
        do {
            // DI-112: diameter
            #expect(graph.diameter() == 6)
            #expect(graph.eccentricities().diameter == 6)
        }
        do {
            // DI-113: radius
            #expect(graph.radius() == 4)
            #expect(graph.eccentricities().radius == 4)
        }
        do {
            // DI-114: center
            #expect(graph.center() == [5, 6, 9, 10])
            #expect(graph.eccentricities().center == [5, 6, 9, 10])
        }
        do {
            // DI-115: periphery
            #expect(graph.periphery() == [0, 3, 12, 15])
            #expect(graph.eccentricities().periphery == [0, 3, 12, 15])
        }
        do {
            // DI-116: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 1, 2, 3, 7, 11, 15])
            #expect(path.edges == [0, 2, 4, 6, 13, 20])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-117: eccentricity(of: 5)
            #expect(graph.eccentricity(of: 5) == 4)
            #expect(graph.eccentricities().eccentricity(of: 5) == 4)
        }
        do {
            // DI-118: centroid
            #expect(graph.centroid() == [5, 6, 9, 10])
        }
        do {
            // DI-625: eccentricities(weight: e%3+1)
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
        do {
            // DI-626: center(weight: e%3+1)
            #expect(graph.center(weight: { $0 % 3 + 1 }) == [10])
            #expect(graph.eccentricities(weight: { $0 % 3 + 1 }).center == [10])
        }
        do {
            // DI-627: periphery(weight: e%3+1)
            #expect(graph.periphery(weight: { $0 % 3 + 1 }) == [2, 3, 8, 12])
            #expect(graph.eccentricities(weight: { $0 % 3 + 1 }).periphery == [2, 3, 8, 12])
        }
        do {
            // DI-628: centroid(weight: e%3+1)
            #expect(graph.centroid(weight: { $0 % 3 + 1 }) == [10])
        }
    }

    @Test("DI-120, DI-121 … DI-125 on UndirectedAdjacencyList: U: [] C(0..4)")
    func undirectedAdjacencyList120() throws {
        // U: [] C(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // DI-120: eccentricities
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
        do {
            // DI-121: center
            #expect(graph.center() == [0, 1, 2, 3, 4])
            #expect(graph.eccentricities().center == [0, 1, 2, 3, 4])
        }
        do {
            // DI-122: periphery
            #expect(graph.periphery() == [0, 1, 2, 3, 4])
            #expect(graph.eccentricities().periphery == [0, 1, 2, 3, 4])
        }
        do {
            // DI-123: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 1, 2])
            #expect(path.edges == [0, 1])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-125: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == 1.5)
        }
    }

    @Test("DI-124 on UndirectedAdjacencyList: U: [] C(0..5)")
    func undirectedAdjacencyList124() throws {
        // U: [] C(0..5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        do {
            // DI-124: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 1, 2, 3])
            #expect(path.edges == [0, 1, 2])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-126, DI-127 … DI-130 on UndirectedAdjacencyList: U: [] K(5)")
    func undirectedAdjacencyList126() throws {
        // U: [] K(5)
        let pairs: [(Int, Int)] = (0 ..< 5).flatMap { i in (i + 1 ..< 5).map { (i, $0) } }
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // DI-126: eccentricities
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
        do {
            // DI-127: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 1])
            #expect(path.edges == [0])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-128: density
            #expect(graph.density == 1.0)
        }
        do {
            // DI-129: wienerIndex
            #expect(graph.wienerIndex() == 10)
        }
        do {
            // DI-130: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == 1.0)
        }
    }

    @Test("DI-131, DI-132, DI-133 on UndirectedAdjacencyList: U: [] KB(0..2;3..6)")
    func undirectedAdjacencyList131() throws {
        // U: [] KB(0..2;3..6)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (0, 6), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 6, 1, 2])
        do {
            // DI-131: eccentricities
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
        do {
            // DI-132: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 3, 1])
            #expect(path.edges == [0, 4])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-133: centroid
            #expect(graph.centroid() == [0, 1, 2])
        }
    }

    @Test("DI-134, DI-135 … DI-137 on UndirectedAdjacencyList: U: [] nx(petersen)")
    func undirectedAdjacencyList134() {
        // U: [] nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9)
        ]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        do {
            // DI-134: eccentricities
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
        do {
            // DI-135: wienerIndex
            #expect(graph.wienerIndex() == 75)
        }
        do {
            // DI-136: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == 1.6666666666666667)
        }
        do {
            // DI-137: density
            #expect(graph.density == 0.3333333333333333)
        }
    }

    @Test("DI-138, DI-139 … DI-147 on UndirectedAdjacencyList: U: [] nx(karate_club)")
    func undirectedAdjacencyList138() throws {
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
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33])
        do {
            // DI-138: eccentricities
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
        do {
            // DI-139: diameter
            #expect(graph.diameter() == 5)
            #expect(graph.eccentricities().diameter == 5)
        }
        do {
            // DI-140: radius
            #expect(graph.radius() == 3)
            #expect(graph.eccentricities().radius == 3)
        }
        do {
            // DI-141: center
            #expect(graph.center() == [0, 1, 2, 3, 8, 13, 19, 31])
            #expect(graph.eccentricities().center == [0, 1, 2, 3, 8, 13, 19, 31])
        }
        do {
            // DI-142: periphery
            #expect(graph.periphery() == [14, 15, 16, 18, 20, 22, 23, 26, 29])
            #expect(graph.eccentricities().periphery == [14, 15, 16, 18, 20, 22, 23, 26, 29])
        }
        do {
            // DI-143: centroid
            #expect(graph.centroid() == [0])
        }
        do {
            // DI-144: wienerIndex
            #expect(graph.wienerIndex() == 1351)
        }
        do {
            // DI-145: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == 2.408199643493761)
        }
        do {
            // DI-146: density
            #expect(graph.density == 0.13903743315508021)
        }
        do {
            // DI-147: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [14, 32, 2, 0, 5, 16])
            #expect(path.edges == [46, 31, 1, 4, 39])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-150, DI-151 … DI-153 on UndirectedAdjacencyList: U: [] C(0..2), P(2,3,4), C(4..6)")
    func undirectedAdjacencyList150() throws {
        // U: [] C(0..2), P(2,3,4), C(4..6)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 6), (6, 4)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        do {
            // DI-150: eccentricities
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
        do {
            // DI-151: center
            #expect(graph.center() == [3])
            #expect(graph.eccentricities().center == [3])
        }
        do {
            // DI-152: periphery
            #expect(graph.periphery() == [0, 1, 5, 6])
            #expect(graph.eccentricities().periphery == [0, 1, 5, 6])
        }
        do {
            // DI-153: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 2, 3, 4, 5])
            #expect(path.edges == [2, 3, 4, 5])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-154, DI-155 … DI-158 on UndirectedAdjacencyList: U: [] P(0..29), lcg(30,12,7)")
    func undirectedAdjacencyList154() throws {
        // U: [] P(0..29), lcg(30,12,7)
        let pairs: [(Int, Int)] = (0 ..< 29).map { ($0, $0 + 1) } + [(8, 11), (3, 23), (25, 29), (4, 24), (19, 16), (25, 15), (2, 20), (9, 22), (15, 9), (6, 11), (16, 13), (4, 18)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29])
        do {
            // DI-154: eccentricities
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
        do {
            // DI-155: center
            #expect(graph.center() == [4])
            #expect(graph.eccentricities().center == [4])
        }
        do {
            // DI-156: periphery
            #expect(graph.periphery() == [0, 27, 28])
            #expect(graph.eccentricities().periphery == [0, 27, 28])
        }
        do {
            // DI-157: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 24, 25, 26, 27])
            #expect(path.edges == [0, 1, 2, 3, 32, 24, 25, 26])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-158: wienerIndex
            #expect(graph.wienerIndex() == 1532)
        }
    }

    @Test("DI-201, DI-202 … DI-204 on UndirectedAdjacencyList: U: [4, 2, 7, 1] 7-2, 2-4, 4-1")
    func undirectedAdjacencyList201() throws {
        // U: [4, 2, 7, 1] 7-2, 2-4, 4-1
        let pairs: [(Int, Int)] = [(7, 2), (2, 4), (4, 1)]
        let graph = UndirectedAdjacencyList(vertices: [4, 2, 7, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [4, 2, 7, 1])
        do {
            // DI-201: center
            #expect(graph.center() == [4, 2])
            #expect(graph.eccentricities().center == [4, 2])
        }
        do {
            // DI-202: periphery
            #expect(graph.periphery() == [7, 1])
            #expect(graph.eccentricities().periphery == [7, 1])
        }
        do {
            // DI-203: centroid
            #expect(graph.centroid() == [4, 2])
        }
        do {
            // DI-204: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [7, 2, 4, 1])
            #expect(path.edges == [0, 1, 2])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-205 on UndirectedAdjacencyList: U: [] P(3,1,0,2)")
    func undirectedAdjacencyList205() {
        // U: [] P(3,1,0,2)
        let pairs: [(Int, Int)] = [(3, 1), (1, 0), (0, 2)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [3, 1, 0, 2])
        do {
            // DI-205: center
            #expect(graph.center() == [1, 0])
            #expect(graph.eccentricities().center == [1, 0])
        }
    }

    @Test("DI-206 on UndirectedAdjacencyList: U: [] 1-2, 1-3, 2-4, 2-5")
    func undirectedAdjacencyList206() {
        // U: [] 1-2, 1-3, 2-4, 2-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [1, 2, 3, 4, 5])
        do {
            // DI-206: center
            #expect(graph.center() == [1, 2])
            #expect(graph.eccentricities().center == [1, 2])
        }
    }

    @Test("DI-207, DI-228 … DI-234 on UndirectedAdjacencyList: U: [] P(0..4)")
    func undirectedAdjacencyList207() throws {
        // U: [] P(0..4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // DI-207: center
            #expect(graph.center() == [2])
            #expect(graph.eccentricities().center == [2])
        }
        do {
            // DI-228: center(weight: [1, 1, 1, 10])
            let w = [1, 1, 1, 10]
            #expect(graph.center(weight: { w[$0] }) == [3])
            #expect(graph.eccentricities(weight: { w[$0] }).center == [3])
        }
        do {
            // DI-233: diameter(weight: [1, 1, 1, 10])
            let w = [1, 1, 1, 10]
            #expect(graph.diameter(weight: { w[$0] }) == 13)
            #expect(graph.eccentricities(weight: { w[$0] }).diameter == 13)
        }
        do {
            // DI-234: diameterPath(weight: [1, 1, 1, 10])
            let w = [1, 1, 1, 10]
            let result = try #require(graph.diameterPath(weight: { w[$0] }))
            #expect(result.path.vertices == [0, 1, 2, 3, 4])
            #expect(result.path.edges == [0, 1, 2, 3])
            #expect(result.distance == 13)
        }
    }

    @Test("DI-208 on UndirectedAdjacencyList: U: [] P(0..98)")
    func undirectedAdjacencyList208() {
        // U: [] P(0..98)
        let pairs: [(Int, Int)] = (0 ..< 98).map { ($0, $0 + 1) }
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98])
        do {
            // DI-208: center
            #expect(graph.center() == [49])
            #expect(graph.eccentricities().center == [49])
        }
    }

    @Test("DI-209, DI-227 on UndirectedAdjacencyList: U: [] P(0..99)")
    func undirectedAdjacencyList209() {
        // U: [] P(0..99)
        let pairs: [(Int, Int)] = (0 ..< 99).map { ($0, $0 + 1) }
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99])
        do {
            // DI-209: center
            #expect(graph.center() == [49, 50])
            #expect(graph.eccentricities().center == [49, 50])
        }
        do {
            // DI-227: centroid
            #expect(graph.centroid() == [49, 50])
        }
    }

    @Test("DI-210, DI-222 on UndirectedAdjacencyList: U: [] S(0;1..5)")
    func undirectedAdjacencyList210() throws {
        // U: [] S(0;1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        do {
            // DI-210: center
            #expect(graph.center() == [0])
            #expect(graph.eccentricities().center == [0])
        }
        do {
            // DI-222: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [1, 0, 2])
            #expect(path.edges == [0, 1])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-211, DI-224 on UndirectedAdjacencyList: U: [] kary(40,3)")
    func undirectedAdjacencyList211() {
        // U: [] kary(40,3)
        let pairs: [(Int, Int)] = (0 ..< 40).flatMap { i -> [(Int, Int)] in (3 * i + 1 ... 3 * i + 3).filter { $0 < 40 }.map { (i, $0) } }
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39])
        do {
            // DI-211: center
            #expect(graph.center() == [0])
            #expect(graph.eccentricities().center == [0])
        }
        do {
            // DI-224: diameter
            #expect(graph.diameter() == 6)
            #expect(graph.eccentricities().diameter == 6)
        }
    }

    @Test("DI-212, DI-213, DI-223 on UndirectedAdjacencyList: U: [] S(0;1..6), P(6,7,8,9,10)")
    func undirectedAdjacencyList212() throws {
        // U: [] S(0;1..6), P(6,7,8,9,10)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (6, 7), (7, 8), (8, 9), (9, 10)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        do {
            // DI-212: center
            #expect(graph.center() == [7])
            #expect(graph.eccentricities().center == [7])
        }
        do {
            // DI-213: centroid
            #expect(graph.centroid() == [0])
        }
        do {
            // DI-223: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [1, 0, 6, 7, 8, 9, 10])
            #expect(path.edges == [0, 5, 6, 7, 8, 9])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-214, DI-215 … DI-239 on UndirectedAdjacencyList: U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8")
    func undirectedAdjacencyList214() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = UndirectedAdjacencyList(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        do {
            // DI-214: center
            #expect(graph.center() == [0])
            #expect(graph.eccentricities().center == [0])
        }
        do {
            // DI-215: centroid
            #expect(graph.centroid() == [1])
        }
        do {
            // DI-216: diameter
            #expect(graph.diameter() == 6)
            #expect(graph.eccentricities().diameter == 6)
        }
        do {
            // DI-217: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [6, 4, 1, 0, 2, 5, 8])
            #expect(path.edges == [5, 3, 0, 1, 4, 7])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-239: diameterPath(weight: [5, 1, 1, 1, 1, 1, 1, 1])
            let w = [5, 1, 1, 1, 1, 1, 1, 1]
            let result = try #require(graph.diameterPath(weight: { w[$0] }))
            #expect(result.path.vertices == [6, 4, 1, 0, 2, 5, 8])
            #expect(result.path.edges == [5, 3, 0, 1, 4, 7])
            #expect(result.distance == 10)
        }
    }

    @Test("DI-218 on UndirectedAdjacencyList: U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5")
    func undirectedAdjacencyList218() throws {
        // U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5
        let pairs: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        do {
            // DI-218: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [6, 4, 1, 0, 2, 5, 8])
            #expect(path.edges == [5, 2, 4, 1, 7, 3])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-219, DI-220, DI-221 on UndirectedAdjacencyList: U: [] a-b, b-c, b-d, d-e")
    func undirectedAdjacencyList219() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == ["a", "b", "c", "d", "e"])
        do {
            // DI-219: center
            #expect(graph.center() == ["b", "d"])
            #expect(graph.eccentricities().center == ["b", "d"])
        }
        do {
            // DI-220: centroid
            #expect(graph.centroid() == ["b"])
        }
        do {
            // DI-221: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == ["a", "b", "d", "e"])
            #expect(path.edges == [0, 2, 3])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-225 on UndirectedAdjacencyList: U: [] P(0..9)")
    func undirectedAdjacencyList225() throws {
        // U: [] P(0..9)
        let pairs: [(Int, Int)] = (0 ..< 9).map { ($0, $0 + 1) }
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        do {
            // DI-225: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
            #expect(path.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-226 on UndirectedAdjacencyList: U: [] kary(8,2)")
    func undirectedAdjacencyList226() {
        // U: [] kary(8,2)
        let pairs: [(Int, Int)] = (0 ..< 8).flatMap { i -> [(Int, Int)] in (2 * i + 1 ... 2 * i + 2).filter { $0 < 8 }.map { (i, $0) } }
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        do {
            // DI-226: centroid
            #expect(graph.centroid() == [0, 1])
        }
    }

    @Test("DI-229, DI-230 … DI-238 on UndirectedAdjacencyList: U: [] P(0..3)")
    func undirectedAdjacencyList229() throws {
        // U: [] P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // DI-229: center(weight: [0, 1, 0])
            let w = [0, 1, 0]
            #expect(graph.center(weight: { w[$0] }) == [0, 1, 2, 3])
            #expect(graph.eccentricities(weight: { w[$0] }).center == [0, 1, 2, 3])
        }
        do {
            // DI-230: center(weight: [1, 0, 1])
            let w = [1, 0, 1]
            #expect(graph.center(weight: { w[$0] }) == [1, 2])
            #expect(graph.eccentricities(weight: { w[$0] }).center == [1, 2])
        }
        do {
            // DI-232: center(weight: [0.5, 0.25, 0.75])
            let w: [Double] = [0.5, 0.25, 0.75]
            #expect(graph.center(weight: { w[$0] }) == [2])
            #expect(graph.eccentricities(weight: { w[$0] }).center == [2])
        }
        do {
            // DI-237: diameterPath(weight: [0, 1, 0])
            let w = [0, 1, 0]
            let result = try #require(graph.diameterPath(weight: { w[$0] }))
            #expect(result.path.vertices == [0, 1, 2])
            #expect(result.path.edges == [0, 1])
            #expect(result.distance == 1)
        }
        do {
            // DI-238: diameter(weight: [0.5, 0.25, 0.75])
            let w: [Double] = [0.5, 0.25, 0.75]
            #expect(graph.diameter(weight: { w[$0] }) == 1.5)
            #expect(graph.eccentricities(weight: { w[$0] }).diameter == 1.5)
        }
    }

    @Test("DI-231, DI-235 on UndirectedAdjacencyList: U: [] S(0;1..4)")
    func undirectedAdjacencyList231() throws {
        // U: [] S(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // DI-231: center(weight: [3, 1, 30, 2])
            let w = [3, 1, 30, 2]
            #expect(graph.center(weight: { w[$0] }) == [0])
            #expect(graph.eccentricities(weight: { w[$0] }).center == [0])
        }
        do {
            // DI-235: diameterPath(weight: [3, 1, 3, 2])
            let w = [3, 1, 3, 2]
            let result = try #require(graph.diameterPath(weight: { w[$0] }))
            #expect(result.path.vertices == [1, 0, 3])
            #expect(result.path.edges == [0, 2])
            #expect(result.distance == 6)
        }
    }

    @Test("DI-236 on UndirectedAdjacencyList: U: [] P(0..2)")
    func undirectedAdjacencyList236() throws {
        // U: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // DI-236: diameterPath(weight: [0, 0])
            let w = [0, 0]
            let result = try #require(graph.diameterPath(weight: { w[$0] }))
            #expect(result.path.vertices == [0])
            #expect(result.path.edges == [])
            #expect(result.distance == 0)
        }
    }

    @Test("DI-250, DI-251 on UndirectedAdjacencyList: U: [5, 4, 3, 2, 1, 0] C(0..5)")
    func undirectedAdjacencyList250() throws {
        // U: [5, 4, 3, 2, 1, 0] C(0..5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList(vertices: [5, 4, 3, 2, 1, 0], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [5, 4, 3, 2, 1, 0])
        do {
            // DI-250: center
            #expect(graph.center() == [5, 4, 3, 2, 1, 0])
            #expect(graph.eccentricities().center == [5, 4, 3, 2, 1, 0])
        }
        do {
            // DI-251: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [5, 4, 3, 2])
            #expect(path.edges == [4, 3, 2])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-253 on UndirectedAdjacencyList: U: [] grid(3,3)")
    func undirectedAdjacencyList253() throws {
        // U: [] grid(3,3)
        let pairs: [(Int, Int)] = (0 ..< 9).flatMap { v -> [(Int, Int)] in (v % 3 + 1 < 3 ? [(v, v + 1)] : []) + (v / 3 + 1 < 3 ? [(v, v + 3)] : []) }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        do {
            // DI-253: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 1, 2, 5, 8])
            #expect(path.edges == [0, 2, 4, 9])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-301, DI-302 … DI-635 on UndirectedAdjacencyList: U: [] P(0..2), 3-4")
    func undirectedAdjacencyList301() {
        // U: [] P(0..2), 3-4
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        do {
            // DI-301: eccentricities
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
        do {
            // DI-302: radius
            #expect(graph.radius() == nil)
            #expect(graph.eccentricities().radius == nil)
        }
        do {
            // DI-303: diameter
            #expect(graph.diameter() == nil)
            #expect(graph.eccentricities().diameter == nil)
        }
        do {
            // DI-304: center
            #expect(graph.center() == [0, 1, 2, 3, 4])
            #expect(graph.eccentricities().center == [0, 1, 2, 3, 4])
        }
        do {
            // DI-305: periphery
            #expect(graph.periphery() == [0, 1, 2, 3, 4])
            #expect(graph.eccentricities().periphery == [0, 1, 2, 3, 4])
        }
        do {
            // DI-306: diameterPath
            #expect(graph.diameterPath() == nil)
        }
        do {
            // DI-307: centroid
            #expect(graph.centroid() == [0, 1, 2, 3, 4])
        }
        do {
            // DI-308: wienerIndex
            #expect(graph.wienerIndex() == nil)
        }
        do {
            // DI-309: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == nil)
        }
        do {
            // DI-310: density
            #expect(graph.density == 0.3)
        }
        do {
            // DI-316: diameter(weight: [1, 1, 1])
            let w = [1, 1, 1]
            #expect(graph.diameter(weight: { w[$0] }) == nil)
            #expect(graph.eccentricities(weight: { w[$0] }).diameter == nil)
        }
        do {
            // DI-635: wienerIndex(weight: [1, 1, 1])
            let w = [1, 1, 1]
            #expect(graph.wienerIndex(weight: { w[$0] }) == nil)
        }
    }

    @Test("DI-311, DI-312 … DI-315 on UndirectedAdjacencyList: U: [0..3] P(0..2)")
    func undirectedAdjacencyList311() {
        // U: [0..3] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ... 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // DI-311: eccentricities
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
        do {
            // DI-312: radius
            #expect(graph.radius() == nil)
            #expect(graph.eccentricities().radius == nil)
        }
        do {
            // DI-313: center
            #expect(graph.center() == [0, 1, 2, 3])
            #expect(graph.eccentricities().center == [0, 1, 2, 3])
        }
        do {
            // DI-314: eccentricity(of: 1)
            #expect(graph.eccentricity(of: 1) == nil)
            #expect(graph.eccentricities().eccentricity(of: 1) == nil)
        }
        do {
            // DI-315: eccentricity(of: 3)
            #expect(graph.eccentricity(of: 3) == nil)
            #expect(graph.eccentricities().eccentricity(of: 3) == nil)
        }
    }

    @Test("DI-401, DI-402 … DI-624 on AdjacencyList: D: [] P(0..2)")
    func adjacencyList401() {
        // D: [] P(0..2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // DI-401: eccentricities
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
        do {
            // DI-402: radius
            #expect(graph.radius() == 2)
            #expect(graph.eccentricities().radius == 2)
        }
        do {
            // DI-403: diameter
            #expect(graph.diameter() == nil)
            #expect(graph.eccentricities().diameter == nil)
        }
        do {
            // DI-404: center
            #expect(graph.center() == [0])
            #expect(graph.eccentricities().center == [0])
        }
        do {
            // DI-405: periphery
            #expect(graph.periphery() == [1, 2])
            #expect(graph.eccentricities().periphery == [1, 2])
        }
        do {
            // DI-406: centroid
            #expect(graph.centroid() == [0])
        }
        do {
            // DI-407: wienerIndex
            #expect(graph.wienerIndex() == nil)
        }
        do {
            // DI-408: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == nil)
        }
        do {
            // DI-409: density
            #expect(graph.density == 0.3333333333333333)
        }
        do {
            // DI-410: diameterPath
            #expect(graph.diameterPath() == nil)
        }
        do {
            // DI-411: eccentricity(of: 0)
            #expect(graph.eccentricity(of: 0) == 2)
            #expect(graph.eccentricities().eccentricity(of: 0) == 2)
        }
        do {
            // DI-412: eccentricity(of: 2)
            #expect(graph.eccentricity(of: 2) == nil)
            #expect(graph.eccentricities().eccentricity(of: 2) == nil)
        }
        do {
            // DI-623: eccentricities(weight: [2, 3])
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
        do {
            // DI-624: radius(weight: [2, 3])
            let w = [2, 3]
            #expect(graph.radius(weight: { w[$0] }) == 5)
            #expect(graph.eccentricities(weight: { w[$0] }).radius == 5)
        }
    }

    @Test("DI-413, DI-414 … DI-417 on AdjacencyList: D: [] C(0..3)")
    func adjacencyList413() throws {
        // D: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // DI-413: eccentricities
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
        do {
            // DI-414: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 1, 2, 3])
            #expect(path.edges == [0, 1, 2])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-415: wienerIndex
            #expect(graph.wienerIndex() == 24)
        }
        do {
            // DI-416: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == 2.0)
        }
        do {
            // DI-417: density
            #expect(graph.density == 0.3333333333333333)
        }
    }

    @Test("DI-418, DI-419 … DI-422 on AdjacencyList: D: [] 0>1, 1>2, 2>0, 0>2")
    func adjacencyList418() throws {
        // D: [] 0>1, 1>2, 2>0, 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // DI-418: eccentricities
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
        do {
            // DI-419: center
            #expect(graph.center() == [0])
            #expect(graph.eccentricities().center == [0])
        }
        do {
            // DI-420: periphery
            #expect(graph.periphery() == [1, 2])
            #expect(graph.eccentricities().periphery == [1, 2])
        }
        do {
            // DI-421: centroid
            #expect(graph.centroid() == [0])
        }
        do {
            // DI-422: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [1, 2, 0])
            #expect(path.edges == [1, 2])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-423, DI-424 on AdjacencyList: D: [] 0>1, 0>2, 1>3")
    func adjacencyList423() {
        // D: [] 0>1, 0>2, 1>3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // DI-423: eccentricities
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
        do {
            // DI-424: center
            #expect(graph.center() == [0])
            #expect(graph.eccentricities().center == [0])
        }
    }

    @Test("DI-425, DI-426 … DI-430 on AdjacencyList: D: [] K(4)")
    func adjacencyList425() {
        // D: [] K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // DI-425: eccentricities
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
        do {
            // DI-426: radius
            #expect(graph.radius() == 1)
            #expect(graph.eccentricities().radius == 1)
        }
        do {
            // DI-427: periphery
            #expect(graph.periphery() == [1, 2, 3])
            #expect(graph.eccentricities().periphery == [1, 2, 3])
        }
        do {
            // DI-430: density
            #expect(graph.density == 0.5)
        }
    }

    @Test("DI-431, DI-432 on AdjacencyList: D: [0..2] 0>1, 1>0")
    func adjacencyList431() {
        // D: [0..2] 0>1, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList(vertices: 0 ... 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // DI-431: eccentricities
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
        do {
            // DI-432: center
            #expect(graph.center() == [0, 1, 2])
            #expect(graph.eccentricities().center == [0, 1, 2])
        }
    }

    @Test("DI-433 on AdjacencyList: D: [] 0>1, 1>0, 1>2, 2>1")
    func adjacencyList433() {
        // D: [] 0>1, 1>0, 1>2, 2>1
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 1)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // DI-433: eccentricities
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
    }

    @Test("DI-440 on AdjacencyList: D: [] 0>0")
    func adjacencyList440() {
        // D: [] 0>0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0])
        do {
            // DI-440: eccentricities
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
    }

    @Test("DI-441 on AdjacencyList: D: [] 0>0, 0>1, 1>0")
    func adjacencyList441() {
        // D: [] 0>0, 0>1, 1>0
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1])
        do {
            // DI-441: density
            #expect(graph.density == 1.5)
        }
    }

    @Test("DI-613 on UndirectedAdjacencyList: U: [] 0-0, 0-1")
    func undirectedAdjacencyList613() {
        // U: [] 0-0, 0-1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1])
        do {
            // DI-613: eccentricities(weight: [0, 4])
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
    }

    @Test("DI-614, DI-615 … DI-619 on UndirectedAdjacencyList: U: [] C(0..3)")
    func undirectedAdjacencyList614() throws {
        // U: [] C(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // DI-614: eccentricities(weight: 0)
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
        do {
            // DI-615: center(weight: 0)
            #expect(graph.center(weight: { _ in 0 }) == [0, 1, 2, 3])
            #expect(graph.eccentricities(weight: { _ in 0 }).center == [0, 1, 2, 3])
        }
        do {
            // DI-616: diameterPath(weight: 0)
            let result = try #require(graph.diameterPath(weight: { _ in 0 }))
            #expect(result.path.vertices == [0])
            #expect(result.path.edges == [])
            #expect(result.distance == 0)
        }
        do {
            // DI-617: eccentricities(weight: [0.5, 0.25, 0.75, 0.125])
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
        do {
            // DI-618: center(weight: [0.5, 0.25, 0.75, 0.125])
            let w: [Double] = [0.5, 0.25, 0.75, 0.125]
            #expect(graph.center(weight: { w[$0] }) == [1])
            #expect(graph.eccentricities(weight: { w[$0] }).center == [1])
        }
        do {
            // DI-619: diameterPath(weight: [0.5, 0.25, 0.75, 0.125])
            let w: [Double] = [0.5, 0.25, 0.75, 0.125]
            let result = try #require(graph.diameterPath(weight: { w[$0] }))
            #expect(result.path.vertices == [0, 1, 2])
            #expect(result.path.edges == [0, 1])
            #expect(result.distance == 0.75)
        }
    }

    @Test("DI-620, DI-621, DI-622 on AdjacencyList: D: [] C(0..2), 0>2")
    func adjacencyList620() throws {
        // D: [] C(0..2), 0>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = AdjacencyList(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // DI-620: eccentricities(weight: [1, 1, 1, 5])
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
        do {
            // DI-621: diameterPath(weight: [1, 1, 1, 5])
            let w = [1, 1, 1, 5]
            let result = try #require(graph.diameterPath(weight: { w[$0] }))
            #expect(result.path.vertices == [0, 1, 2])
            #expect(result.path.edges == [0, 1])
            #expect(result.distance == 2)
        }
        do {
            // DI-622: wienerIndex(weight: [1, 1, 1, 5])
            let w = [1, 1, 1, 5]
            #expect(graph.wienerIndex(weight: { w[$0] }) == 9)
        }
    }

    @Test("DI-634 on UndirectedAdjacencyList: U: [] 0-1, 1-2")
    func undirectedAdjacencyList634() {
        // U: [] 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2])
        do {
            // DI-634: eccentricity(of: 1, weight: [3, 4])
            let w = [3, 4]
            #expect(graph.eccentricity(of: 1, weight: { w[$0] }) == 4)
            #expect(graph.eccentricities(weight: { w[$0] }).eccentricity(of: 1) == 4)
        }
    }

    @Test("DI-636 on UndirectedAdjacencyList: U: [] K(4)")
    func undirectedAdjacencyList636() {
        // U: [] K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        do {
            // DI-636: centroid(weight: [1, 1, 1, 1, 1, 9])
            let w = [1, 1, 1, 1, 1, 9]
            #expect(graph.centroid(weight: { w[$0] }) == [0, 1])
        }
    }

    @Test("DI-011, DI-012 on CompressedSparseRow: D: [], arcs rewritten row-major")
    func compressedSparseRow011() {
        // D: []
        let graph = CompressedSparseRow(vertexCount: 0)
        do {
            // DI-011: diameter
            #expect(graph.diameter() == nil)
            #expect(graph.eccentricities().diameter == nil)
        }
        do {
            // DI-012: density
            #expect(graph.density == 0.0)
        }
    }

    @Test("DI-401, DI-402 … DI-624 on CompressedSparseRow: D: [] P(0..2), arcs rewritten row-major")
    func compressedSparseRow401() {
        // D: [0..2] 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // DI-401: eccentricities
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
        do {
            // DI-402: radius
            #expect(graph.radius() == 2)
            #expect(graph.eccentricities().radius == 2)
        }
        do {
            // DI-403: diameter
            #expect(graph.diameter() == nil)
            #expect(graph.eccentricities().diameter == nil)
        }
        do {
            // DI-404: center
            #expect(graph.center() == [0])
            #expect(graph.eccentricities().center == [0])
        }
        do {
            // DI-405: periphery
            #expect(graph.periphery() == [1, 2])
            #expect(graph.eccentricities().periphery == [1, 2])
        }
        do {
            // DI-406: centroid
            #expect(graph.centroid() == [0])
        }
        do {
            // DI-407: wienerIndex
            #expect(graph.wienerIndex() == nil)
        }
        do {
            // DI-408: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == nil)
        }
        do {
            // DI-409: density
            #expect(graph.density == 0.3333333333333333)
        }
        do {
            // DI-410: diameterPath
            #expect(graph.diameterPath() == nil)
        }
        do {
            // DI-411: eccentricity(of: 0)
            #expect(graph.eccentricity(of: 0) == 2)
            #expect(graph.eccentricities().eccentricity(of: 0) == 2)
        }
        do {
            // DI-412: eccentricity(of: 2)
            #expect(graph.eccentricity(of: 2) == nil)
            #expect(graph.eccentricities().eccentricity(of: 2) == nil)
        }
        do {
            // DI-623: eccentricities(weight: [2, 3])
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
        do {
            // DI-624: radius(weight: [2, 3])
            let w = [2, 3]
            #expect(graph.radius(weight: { w[$0] }) == 5)
            #expect(graph.eccentricities(weight: { w[$0] }).radius == 5)
        }
    }

    @Test("DI-413, DI-414 … DI-417 on CompressedSparseRow: D: [] C(0..3), arcs rewritten row-major")
    func compressedSparseRow413() throws {
        // D: [0..3] 0>1, 1>2, 2>3, 3>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // DI-413: eccentricities
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
        do {
            // DI-414: diameterPath
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [0, 1, 2, 3])
            #expect(path.edges == [0, 1, 2])
            #expect(path.length == graph.diameter())
        }
        do {
            // DI-415: wienerIndex
            #expect(graph.wienerIndex() == 24)
        }
        do {
            // DI-416: averageShortestPathLength
            #expect(graph.averageShortestPathLength() == 2.0)
        }
        do {
            // DI-417: density
            #expect(graph.density == 0.3333333333333333)
        }
    }

    @Test("DI-418, DI-419 … DI-422 on CompressedSparseRow: D: [] 0>1, 1>2, 2>0, 0>2, arcs rewritten row-major")
    func compressedSparseRow418() throws {
        // D: [0..2] 0>1, 0>2, 1>2, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 0)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // DI-418: eccentricities
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
        do {
            // DI-419: center
            #expect(graph.center() == [0])
            #expect(graph.eccentricities().center == [0])
        }
        do {
            // DI-420: periphery
            #expect(graph.periphery() == [1, 2])
            #expect(graph.eccentricities().periphery == [1, 2])
        }
        do {
            // DI-421: centroid
            #expect(graph.centroid() == [0])
        }
        do {
            // DI-422: diameterPath (computed with ref.py on the rewritten arcs: [1, 2, 0]/[2, 3])
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == [1, 2, 0])
            #expect(path.edges == [2, 3])
            #expect(path.length == graph.diameter())
        }
    }

    @Test("DI-423, DI-424 on CompressedSparseRow: D: [] 0>1, 0>2, 1>3, arcs rewritten row-major")
    func compressedSparseRow423() {
        // D: [0..3] 0>1, 0>2, 1>3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // DI-423: eccentricities
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
        do {
            // DI-424: center
            #expect(graph.center() == [0])
            #expect(graph.eccentricities().center == [0])
        }
    }

    @Test("DI-425, DI-426 … DI-430 on CompressedSparseRow: D: [] K(4), arcs rewritten row-major")
    func compressedSparseRow425() {
        // D: [0..3] 0>1, 0>2, 0>3, 1>2, 1>3, 2>3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // DI-425: eccentricities
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
        do {
            // DI-426: radius
            #expect(graph.radius() == 1)
            #expect(graph.eccentricities().radius == 1)
        }
        do {
            // DI-427: periphery
            #expect(graph.periphery() == [1, 2, 3])
            #expect(graph.eccentricities().periphery == [1, 2, 3])
        }
        do {
            // DI-430: density
            #expect(graph.density == 0.5)
        }
    }

    @Test("DI-431, DI-432 on CompressedSparseRow: D: [0..2] 0>1, 1>0, arcs rewritten row-major")
    func compressedSparseRow431() {
        // D: [0..2] 0>1, 1>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // DI-431: eccentricities
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
        do {
            // DI-432: center
            #expect(graph.center() == [0, 1, 2])
            #expect(graph.eccentricities().center == [0, 1, 2])
        }
    }

    @Test("DI-433 on CompressedSparseRow: D: [] 0>1, 1>0, 1>2, 2>1, arcs rewritten row-major")
    func compressedSparseRow433() {
        // D: [0..2] 0>1, 1>0, 1>2, 2>1
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 1)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // DI-433: eccentricities
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
    }

    @Test("DI-440 on CompressedSparseRow: D: [] 0>0, arcs rewritten row-major")
    func compressedSparseRow440() {
        // D: [0..0] 0>0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = CompressedSparseRow(vertexCount: 1, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // DI-440: eccentricities
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
    }

    @Test("DI-441 on CompressedSparseRow: D: [] 0>0, 0>1, 1>0, arcs rewritten row-major")
    func compressedSparseRow441() {
        // D: [0..1] 0>0, 0>1, 1>0
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
        let graph = CompressedSparseRow(vertexCount: 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // DI-441: density
            #expect(graph.density == 1.5)
        }
    }

    @Test("DI-620, DI-621, DI-622 on CompressedSparseRow: D: [] C(0..2), 0>2, arcs rewritten row-major")
    func compressedSparseRow620() throws {
        // D: [0..2] 0>1, 0>2, 1>2, 2>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 0)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        do {
            // DI-620: eccentricities(weight: [1, 5, 1, 1])
            let w = [1, 5, 1, 1]
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
        do {
            // DI-621: diameterPath(weight: [1, 5, 1, 1]) (computed with ref.py on the rewritten arcs: [0, 1, 2]/[0, 2] #2)
            let w = [1, 5, 1, 1]
            let result = try #require(graph.diameterPath(weight: { w[$0] }))
            #expect(result.path.vertices == [0, 1, 2])
            #expect(result.path.edges == [0, 2])
            #expect(result.distance == 2)
        }
        do {
            // DI-622: wienerIndex(weight: [1, 5, 1, 1])
            let w = [1, 5, 1, 1]
            #expect(graph.wienerIndex(weight: { w[$0] }) == 9)
        }
    }
}
