// Preconditions, as exit tests. A vertex argument that is not a vertex traps, on the graph and on
// the `Eccentricities` value, undirected and directed (DI-042); an index out of range traps on
// `eccentricity(ofIndex:)` (api.md: "Precondition: in range"). A weight below `.zero` or NaN traps
// in every weighted entry point (DI-240, DI-630 – DI-633), with `Int` and `Double` weights, and is
// checked as the weights are read, before any search: DI-630 traps although the first search finds
// the graph disconnected and no search would reach the bad edge, DI-632 on a directed loop no
// search uses, DI-633 on the single-source call. Each exit test builds its inputs inside the
// closure. Case IDs (DI-nnn) refer to the catalog; see README.md.

import Distances
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Distances preconditions", .tags(.precondition))
struct DistancePreconditionTests {
    @Test("DI-042 U([0]).eccentricity(of: 1) traps: not a vertex")
    func eccentricityOfNonVertex() async {
        await #expect(processExitsWith: .failure) {
            // U: [0]
            let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
            _ = graph.eccentricity(of: 1)
        }
    }

    @Test("DI-042 also on the Eccentricities value, weighted, and directed: every vertex argument that is not a vertex traps")
    func everyVertexArgumentOnNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
            _ = graph.eccentricities().eccentricity(of: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.eccentricity(of: 2, weight: { _ in 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.eccentricity(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.eccentricities().eccentricity(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.eccentricity(of: 2, weight: { _ in 1 })
        }
    }

    @Test("Eccentricities.eccentricity(ofIndex:) traps out of range: n and -1")
    func eccentricityOfIndexOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.eccentricities().eccentricity(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
            _ = graph.eccentricities().eccentricity(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.eccentricities().eccentricity(ofIndex: 2)
        }
    }

    @Test("DI-240 U(P(0..3)).center(weight: [1, -1, 1]) traps: TA-421 traps too")
    func centerNegativeWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: [] P(0..3)
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w = [1, -1, 1]
            _ = graph.center(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w: [Double] = [1, -1, 1]
            _ = graph.center(weight: { w[$0] })
        }
    }

    @Test("DI-240 every undirected weighted entry point traps on U(P(0..3)) with weights [1, -1, 1]")
    func everyUndirectedEntryPointNegativeWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w = [1, -1, 1]
            _ = graph.eccentricities(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w = [1, -1, 1]
            _ = graph.eccentricity(of: 0, weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w = [1, -1, 1]
            _ = graph.radius(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w = [1, -1, 1]
            _ = graph.diameter(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w = [1, -1, 1]
            _ = graph.periphery(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w = [1, -1, 1]
            _ = graph.diameterPath(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w = [1, -1, 1]
            _ = graph.centroid(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w = [1, -1, 1]
            _ = graph.wienerIndex(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w: [Double] = [1, -1, 1]
            _ = graph.averageShortestPathLength(weight: { w[$0] })
        }
    }

    @Test("DI-630 U(0-1, 2-3).diameter(weight: [1, -1]) traps: every weight is read and checked first, though the graph is not connected")
    func negativeWeightOutOfReach() async {
        await #expect(processExitsWith: .failure) {
            // U: [] 0-1, 2-3
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
            let w = [1, -1]
            _ = graph.diameter(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
            let w = [1, -1]
            _ = graph.wienerIndex(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
            let w = [1, -1]
            _ = graph.eccentricity(of: 0, weight: { w[$0] })
        }
    }

    @Test("DI-631 U(P(0..3)).diameter(weight: [1, nan, 1]) traps")
    func nanWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: [] P(0..3)
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w: [Double] = [1, .nan, 1]
            _ = graph.diameter(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            let w: [Double] = [1, 1, .nan]
            _ = graph.averageShortestPathLength(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            let w: [Double] = [1, .nan]
            _ = graph.eccentricities(weight: { w[$0] })
        }
    }

    @Test("DI-632 D(0>1, 2>2).eccentricities(weight: [1, -1]) traps: a negative loop")
    func negativeDirectedLoop() async {
        await #expect(processExitsWith: .failure) {
            // D: [] 0>1, 2>2
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
            let w = [1, -1]
            _ = graph.eccentricities(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
            let w: [Double] = [1, -1]
            _ = graph.diameter(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
            let w = [1, -1]
            _ = graph.radius(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
            let w = [1, -1]
            _ = graph.diameterPath(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
            let w = [1, -1]
            _ = graph.centroid(weight: { w[$0] })
        }
    }

    @Test("DI-633 U([0]; 0-1).eccentricity(of: 0, weight: [-1]) traps: single-source too")
    func singleSourceNegativeWeight() async {
        await #expect(processExitsWith: .failure) {
            // U: [0] 0-1
            let graph = ReferencePseudograph(vertices: [0], edges: [UndirectedEdge(0, 1)])
            let w = [-1]
            _ = graph.eccentricity(of: 0, weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: [0], edges: [DirectedEdge(from: 0, to: 1)])
            let w = [-1]
            _ = graph.eccentricity(of: 0, weight: { w[$0] })
        }
    }

    @Test("Extreme bad weights trap: -infinity, Int.min, -Double.leastNonzeroMagnitude, the bad weight last, and through graph.directed")
    func extremeBadWeights() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w: [Double] = [1, -.infinity]
            _ = graph.radius(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w = [1, Int.min]
            _ = graph.center(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w: [Double] = [1, -Double.leastNonzeroMagnitude]
            _ = graph.periphery(weight: { w[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let w = [1, -1]
            _ = graph.directed.diameter(weight: { w[$0.position] })
        }
    }
}
