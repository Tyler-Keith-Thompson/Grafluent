// Preconditions of Kernighan–Lin bisection, k-clique communities, fluid communities and Walktrap,
// as exit tests. Each exit test builds its inputs inside the closure.

import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Bisection, k-clique, fluid and Walktrap preconditions", .tags(.precondition))
struct BisectionAndOverlapPreconditionTests {
    @Test("Kernighan–Lin traps on a negative number of iterations")
    func kernighanLinIterations() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1)])
            _ = graph.kernighanLinBisection(startingFrom: [[0, 1], [2, 3]], iterations: -1)
        }
    }

    @Test("Kernighan–Lin traps on three starting communities")
    func kernighanLinThree() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.kernighanLinBisection(startingFrom: [[0], [1], [2]])
        }
    }

    @Test("Kernighan–Lin traps on a start that leaves a vertex out")
    func kernighanLinMissing() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.kernighanLinBisection(startingFrom: [[0], [1]], weight: { _ in 1.0 })
        }
    }

    @Test("Kernighan–Lin traps on a negative weight")
    func kernighanLinWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.kernighanLinBisection(weight: { _ in -1.0 }, using: &generator)
        }
    }

    @Test("k-clique communities trap on k = 1")
    func kCliqueOne() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.kCliqueCommunities(1)
        }
    }

    @Test("Fluid communities trap on a disconnected graph")
    func fluidDisconnected() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
            _ = graph.asynchronousFluidCommunities(count: 2)
        }
    }

    @Test("Fluid communities trap on more communities than vertices")
    func fluidTooMany() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.asynchronousFluidCommunities(count: 3, using: &generator)
        }
    }

    @Test("Fluid communities trap on zero communities")
    func fluidZero() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.asynchronousFluidCommunities(count: 0)
        }
    }

    @Test("Fluid communities trap on zero iterations")
    func fluidIterations() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.asynchronousFluidCommunities(count: 1, iterations: 0)
        }
    }

    @Test("Fluid communities trap on the empty graph")
    func fluidEmpty() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
            _ = graph.asynchronousFluidCommunities(count: 1)
        }
    }

    @Test("Walktrap traps on walks of zero steps")
    func walktrapSteps() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.walktrapCommunities(steps: 0)
        }
    }

    @Test("Walktrap traps on a NaN weight")
    func walktrapWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.walktrapCommunities(weight: { _ in Double.nan })
        }
    }
}
