// Preconditions of `chinesePostmanTour(weight:)`, `simulatedAnnealingTour` and
// `thresholdAcceptingTour`, as exit tests: a negative, NaN or infinite weight; the matching's bound;
// an incomplete graph; a starting tour that does not list every vertex; parameters out of range.
// Each exit test builds its inputs inside the closure.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import Testing
import Tours
import Walks

@Suite("Postman and metaheuristic preconditions", .tags(.precondition))
struct PostmanAndMetaheuristicPreconditionTests {
    @Test("chinesePostmanTour: a negative weight traps, undirected and directed")
    func negativeWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.chinesePostmanTour { _ in -1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.chinesePostmanTour { _ in -1 }
        }
    }

    @Test("chinesePostmanTour: a NaN or infinite weight traps")
    func nonFiniteWeight() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.chinesePostmanTour { _ in Double.nan }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.chinesePostmanTour { _ in Double.infinity }
        }
    }

    @Test("chinesePostmanTour: a distance past the matching's bound traps")
    func matchingBound() async {
        await #expect(processExitsWith: .failure) {
            // Two odd vertices at distance 100: 2 · (2 · 100 + 1) > Int8.max / 8.
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.chinesePostmanTour { _ in Int8(100) }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.chinesePostmanTour { _ in Double.greatestFiniteMagnitude / 4 }
        }
    }

    @Test("chinesePostmanTour: an infinite weight traps on an Eulerian graph too, where no distance is matched")
    func infiniteEulerian() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
            _ = graph.chinesePostmanTour { $0 == 0 ? Double.infinity : 1 }
        }
    }

    @Test("chinesePostmanTour: just past the Int8 bound, and too many odd vertices for it even at weight zero")
    func matchingBoundJustPast() async {
        await #expect(processExitsWith: .failure) {
            // k = 2: 2 · (2 · 4 + 1) = 18 > 15.
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.chinesePostmanTour { _ in Int8(4) }
        }
        await #expect(processExitsWith: .failure) {
            // A star with 16 leaves: k = 16 > Int8.max / 8, so no distance passes.
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 17, edges: (1 ... 16).map { UndirectedEdge(0, $0) })
            _ = graph.chinesePostmanTour { _ in Int8(0) }
        }
    }

    @Test("Within the matching's bound: the largest Int8 distance two odd vertices may have")
    func matchingBoundEdge() {
        // k = 2: 2 · (2 · d + 1) ≤ 15 for d ≤ 3, so d = 3 is allowed; the tour weighs 6.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(graph.chinesePostmanTour { _ in Int8(3) }?.weight == 6)
    }

    @Test("chinesePostmanTour, directed: a weight past Int traps")
    func directedWeightPastInt() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 1)])
            _ = graph.chinesePostmanTour { _ in Int128(Int.max) + 1 }
        }
    }

    @Test("Metaheuristics: an incomplete graph traps, undirected and directed")
    func incomplete() async {
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
            _ = graph.simulatedAnnealingTour(weight: { _ in 1 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
            _ = graph.thresholdAcceptingTour(weight: { _ in 1 }, using: &generator)
        }
    }

    @Test("Metaheuristics: a starting tour that misses a vertex traps")
    func shortTour() async {
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            var ends: [UndirectedEdge<Int>] = []
            for u in 0 ..< 4 { for v in u + 1 ..< 4 { ends.append(UndirectedEdge(u, v)) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: ends)
            let triangle = Cycle([0, 1, 2], in: graph)!
            _ = graph.simulatedAnnealingTour(improving: triangle, weight: { _ in 1 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            var arcs: [DirectedEdge<Int>] = []
            for u in 0 ..< 4 { for v in 0 ..< 4 where u != v { arcs.append(DirectedEdge(from: u, to: v)) } }
            let graph = AdjacencyList(vertices: 0 ..< 4, edges: arcs)
            let triangle = Cycle([0, 1, 2], in: graph)!
            _ = graph.thresholdAcceptingTour(improving: triangle, weight: { _ in 1 }, using: &generator)
        }
    }

    @Test("Metaheuristics: parameters out of range trap")
    func parameters() async {
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            _ = graph.simulatedAnnealingTour(temperature: -1, weight: { _ in 1 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            _ = graph.simulatedAnnealingTour(alpha: 0, weight: { _ in 1 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            _ = graph.simulatedAnnealingTour(alpha: 1.5, weight: { _ in 1 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            _ = graph.thresholdAcceptingTour(threshold: .infinity, weight: { _ in 1 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            _ = graph.thresholdAcceptingTour(alpha: -0.5, weight: { _ in 1 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            _ = graph.thresholdAcceptingTour(maximumIterations: -1, weight: { _ in 1 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            _ = graph.simulatedAnnealingTour(innerIterations: -1, weight: { _ in 1 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 1)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
            _ = graph.simulatedAnnealingTour(weight: { _ in Double.nan }, using: &generator)
        }
    }
}
