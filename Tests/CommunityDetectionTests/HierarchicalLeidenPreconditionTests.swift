// Preconditions of hierarchical Leiden, as exit tests: a cap below one, a randomness of zero, a
// resolution that is negative, a number of iterations below one, a negative weight, and the
// hierarchy's out-of-range queries. Each exit test builds its inputs inside the closure.

import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Hierarchical Leiden preconditions", .tags(.precondition))
struct HierarchicalLeidenPreconditionTests {
    @Test("Hierarchical Leiden traps on a cap of 0")
    func capZero() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 0, using: &generator)
        }
    }

    @Test("Hierarchical Leiden traps on a negative cap, on a directed graph")
    func capNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.hierarchicalLeidenCommunities(maximumCommunitySize: -1)
        }
    }

    @Test("Hierarchical Leiden traps on a randomness of 0")
    func randomnessZero() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 2, randomness: 0, using: &generator)
        }
    }

    @Test("Hierarchical Leiden traps on a negative resolution")
    func resolutionNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 2, resolution: -1)
        }
    }

    @Test("Hierarchical Leiden traps on 0 iterations")
    func iterationsZero() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 2, iterations: 0, using: &generator)
        }
    }

    @Test("Weighted hierarchical Leiden traps on a negative weight")
    func weightNegative() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.hierarchicalLeidenCommunities(weight: { $0 == 1 ? -1.0 : 1.0 }, maximumCommunitySize: 2)
        }
    }

    @Test("A hierarchy traps on a community number out of range")
    func communityOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            let result = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 3, using: &generator)
            _ = result.parent(of: result.count)
        }
    }

    @Test("A hierarchy traps on a level out of range")
    func levelOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            let result = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 3, using: &generator)
            _ = result.communities(atLevel: result.levelCount)
        }
    }

    @Test("A hierarchy traps on community(of:) for a vertex not in the graph")
    func vertexNotFound() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            let result = graph.hierarchicalLeidenCommunities(maximumCommunitySize: 3, using: &generator)
            _ = result.community(of: 7)
        }
    }
}
