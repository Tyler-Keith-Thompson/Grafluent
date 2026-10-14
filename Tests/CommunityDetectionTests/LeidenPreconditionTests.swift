// Preconditions of Leiden, the constant Potts model, Louvain's levels and the component split, as
// exit tests: a number of iterations below one, a randomness that is zero, negative, NaN or infinite, a resolution that is negative,
// NaN or infinite, weights that are negative, NaN or infinite, and groupings that are not partitions
// of the vertices. Each exit test builds its inputs inside the closure.

import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Leiden preconditions", .tags(.precondition))
struct LeidenPreconditionTests {
    @Test("Leiden traps on a randomness of 0")
    func randomnessZero() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.leidenCommunities(randomness: 0, using: &generator)
        }
    }

    @Test("Leiden traps on a negative randomness, on a directed graph")
    func randomnessNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.leidenCommunities(randomness: -0.01, using: &generator)
        }
    }

    @Test("Leiden traps on a NaN randomness, without a generator")
    func randomnessNaN() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.leidenCommunities(randomness: .nan)
        }
    }

    @Test("Leiden traps on an infinite randomness, weighted")
    func randomnessInfinite() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.leidenCommunities(weight: { _ in 1.0 }, randomness: .infinity)
        }
    }

    @Test("Leiden traps on zero iterations")
    func iterationsZero() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.leidenCommunities(iterations: 0, using: &generator)
        }
    }

    @Test("Leiden traps on negative iterations, directed and weighted")
    func iterationsNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.leidenCommunities(weight: { _ in 1.0 }, iterations: -1)
        }
    }

    @Test("Leiden traps on a negative resolution, constant Potts model")
    func resolutionNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.leidenCommunities(quality: .constantPottsModel, resolution: -1, using: &generator)
        }
    }

    @Test("Leiden traps on a NaN resolution, directed and weighted")
    func resolutionNaN() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.leidenCommunities(weight: { _ in 1.0 }, resolution: .nan, using: &generator)
        }
    }

    @Test("Leiden traps on an infinite resolution, directed, without a generator")
    func resolutionInfinite() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.leidenCommunities(resolution: .infinity)
        }
    }

    @Test("Leiden traps on a negative weight")
    func weightNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.leidenCommunities(weight: { $0 == 1 ? -1.0 : 1.0 }, using: &generator)
        }
    }

    @Test("Leiden traps on a NaN weight, directed, without a generator")
    func weightNaN() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.leidenCommunities(weight: { _ in Double.nan })
        }
    }

    @Test("Leiden traps on an infinite Float weight, directed")
    func weightInfinite() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.leidenCommunities(weight: { _ in Float.infinity }, using: &generator)
        }
    }

    @Test("constantPottsModel(of:) traps on a vertex missing")
    func pottsMissing() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.constantPottsModel(of: [[0, 1]])
        }
    }

    @Test("constantPottsModel(of:) traps on a vertex listed twice, directed")
    func pottsTwice() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.constantPottsModel(of: [[0, 1], [1, 2]])
        }
    }

    @Test("constantPottsModel(of:) traps on a negative resolution, weighted")
    func pottsResolution() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.constantPottsModel(of: [[0, 1, 2]], weight: { _ in 1.0 }, resolution: -0.5)
        }
    }

    @Test("constantPottsModel(of:) traps on a negative weight, directed")
    func pottsWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.constantPottsModel(of: [[0, 1, 2]], weight: { _ in -1.0 })
        }
    }

    @Test("constantPottsModel(of:) traps on a NaN resolution, directed")
    func pottsResolutionNaN() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.constantPottsModel(of: [[0, 1, 2]], resolution: .nan)
        }
    }

    @Test("louvainPartitions traps on a negative threshold")
    func louvainLevelsThreshold() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.louvainPartitions(threshold: -1)
        }
    }

    @Test("louvainPartitions traps on a NaN resolution, directed, with a generator")
    func louvainLevelsResolution() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.louvainPartitions(resolution: .nan, using: &generator)
        }
    }

    @Test("louvainPartitions traps on a negative weight")
    func louvainLevelsWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.louvainPartitions(weight: { _ in -1.0 })
        }
    }

    @Test("connectedComponents(within:) traps on a non-vertex")
    func componentsNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.connectedComponents(within: [[0, 1, 2, 7]])
        }
    }

    @Test("weaklyConnectedComponents(within:) traps on a vertex missing")
    func componentsMissing() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.weaklyConnectedComponents(within: [[0, 1]])
        }
    }
}
