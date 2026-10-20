// Stochastic Kronecker graphs (Leskovec et al.) beyond the catalog rows: degenerate initiators (all
// ones, all zeros, the identity), the draws replayed by hand for a fixed seed on directed,
// undirected and asymmetric initiators, the expected edge count checked statistically, and the
// exit tests for the preconditions.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import RandomGraphs
import Testing

@Suite("RandomGraphs stochastic Kronecker properties")
struct StochasticKroneckerPropertyTests {
    @Test("All-ones initiator gives the complete graph, all-zeros the empty one, the identity no edges at all")
    func degenerate() {
        let ones = [[1.0, 1.0], [1.0, 1.0]]
        var generator = Xoshiro256StarStar(seed: 1)
        let complete = UndirectedAdjacencyList<Int>.stochasticKronecker(initiator: ones, iterations: 3, using: &generator)
        #expect(complete.vertexCount == 8 && complete.edgeCount == 28)
        #expect(complete.edges.allSatisfy { $0.u < $0.v })
        let digraph = CompressedSparseRow.stochasticKronecker(initiator: ones, iterations: 3, using: &generator)
        #expect(digraph.vertexCount == 8 && digraph.edgeCount == 56 && digraph.edges.allSatisfy { $0.source != $0.target })
        let zeros = [[0.0, 0.0], [0.0, 0.0]]
        #expect(UndirectedAdjacencyList<Int>.stochasticKronecker(initiator: zeros, iterations: 4, using: &generator).edgeCount == 0)
        // The identity: a pair with any differing digit has probability zero.
        let identity = [[1.0, 0.0], [0.0, 1.0]]
        let none = CompressedSparseRow.stochasticKronecker(initiator: identity, iterations: 5, using: &generator)
        #expect(none.vertexCount == 32 && none.edgeCount == 0)
        // No iterations: one vertex; a 1 × 1 initiator: one vertex too.
        #expect(UndirectedAdjacencyList<Int>.stochasticKronecker(initiator: ones, iterations: 0, using: &generator).vertexCount == 1)
        #expect(CompressedSparseRow.stochasticKronecker(initiator: [[0.5]], iterations: 6, using: &generator).vertexCount == 1)
    }

    @Test("A fixed seed gives these arcs, one draw per pair in row-major order")
    func pinned() {
        let initiator = [[0.9, 0.6], [0.6, 0.2]]
        var generator = Xoshiro256StarStar(seed: 3)
        let graph = CompressedSparseRow.stochasticKronecker(initiator: initiator, iterations: 2, using: &generator)
        // Replaying the draws by hand: pair (u, v) in row-major order takes uniform01 < p(u, v).
        var replay = Xoshiro256StarStar(seed: 3)
        var expected: [DirectedEdge<Int>] = []
        for u in 0 ..< 4 {
            for v in 0 ..< 4 where v != u {
                let p = initiator[u / 2][v / 2] * initiator[u % 2][v % 2]
                if Double(replay.next() >> 11) * 0x1p-53 < p { expected.append(DirectedEdge(from: u, to: v)) }
            }
        }
        #expect(Array(graph.edges) == expected)
        #expect(generator == replay)
        var again = Xoshiro256StarStar(seed: 3)
        #expect(CompressedSparseRow.stochasticKronecker(initiator: initiator, iterations: 2, using: &again) == graph)
    }

    @Test("An asymmetric initiator weighs the pair by the source's digits against the target's")
    func asymmetric() {
        let initiator = [[0.9, 0.1], [0.7, 0.3]]
        var generator = Xoshiro256StarStar(seed: 8)
        let graph = CompressedSparseRow.stochasticKronecker(initiator: initiator, iterations: 3, using: &generator)
        var replay = Xoshiro256StarStar(seed: 8)
        var expected: [DirectedEdge<Int>] = []
        for u in 0 ..< 8 {
            for v in 0 ..< 8 where v != u {
                var p = 1.0
                var a = u, b = v
                for _ in 0 ..< 3 {
                    p *= initiator[a % 2][b % 2]
                    a /= 2
                    b /= 2
                }
                if Double(replay.next() >> 11) * 0x1p-53 < p { expected.append(DirectedEdge(from: u, to: v)) }
            }
        }
        #expect(Array(graph.edges) == expected && generator == replay)
        // Transposing the initiator changes the graph: the digits are not interchangeable.
        var transposedGenerator = Xoshiro256StarStar(seed: 8)
        let transposed = CompressedSparseRow.stochasticKronecker(initiator: [[0.9, 0.7], [0.1, 0.3]], iterations: 3, using: &transposedGenerator)
        #expect(transposed != graph)
    }

    @Test("Undirected: the pairs with u < v only, by the digits of the lower end against the higher; the multigraph target agrees")
    func undirected() {
        let initiator = [[0.9, 0.6], [0.6, 0.2]]
        var generator = Xoshiro256StarStar(seed: 5)
        let graph = UndirectedAdjacencyList<Int>.stochasticKronecker(initiator: initiator, iterations: 3, using: &generator)
        var replay = Xoshiro256StarStar(seed: 5)
        var expected: [UndirectedEdge<Int>] = []
        for u in 0 ..< 8 {
            for v in u + 1 ..< 8 {
                var p = 1.0
                var a = u, b = v
                for _ in 0 ..< 3 {
                    p *= initiator[a % 2][b % 2]
                    a /= 2
                    b /= 2
                }
                if Double(replay.next() >> 11) * 0x1p-53 < p { expected.append(UndirectedEdge(u, v)) }
            }
        }
        #expect(Array(graph.edges) == expected && generator == replay)
        var multigraphGenerator = Xoshiro256StarStar(seed: 5)
        #expect(Array(Multigraph<Int>.stochasticKronecker(initiator: initiator, iterations: 3, using: &multigraphGenerator).edges) == expected)
    }

    @Test("The edge count is near its expectation: the sum of the probabilities over the pairs")
    func expectedCount() {
        let initiator = [[0.9, 0.5], [0.5, 0.3]]
        let k = 7
        let n = 1 << k
        var total = 0.0
        for u in 0 ..< n {
            for v in 0 ..< n where v != u {
                var p = 1.0
                var a = u, b = v
                for _ in 0 ..< k {
                    p *= initiator[a % 2][b % 2]
                    a /= 2
                    b /= 2
                }
                total += p
            }
        }
        var generator = Xoshiro256StarStar(seed: 11)
        var counts: [Double] = []
        for _ in 0 ..< 20 {
            counts.append(Double(CompressedSparseRow.stochasticKronecker(initiator: initiator, iterations: k, using: &generator).edgeCount))
        }
        let mean = counts.reduce(0, +) / 20
        #expect(abs(mean - total) < 0.05 * total + 5, "mean \(mean), expected \(total)")
    }

    @Test("Preconditions: a ragged or empty initiator, an entry outside 0...1, and negative iterations trap")
    func traps() async {
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.stochasticKronecker(initiator: [[0.5, 0.5], [0.5]], iterations: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.stochasticKronecker(initiator: [], iterations: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.stochasticKronecker(initiator: [[1.5, 0.5], [0.5, 0.5]], iterations: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = UndirectedAdjacencyList<Int>.stochasticKronecker(initiator: [[0.5, 0.5], [0.5, -0.1]], iterations: 2, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 0)
            _ = CompressedSparseRow.stochasticKronecker(initiator: [[0.5, 0.5], [0.5, 0.5]], iterations: -1, using: &generator)
        }
        var generator = Xoshiro256StarStar(seed: 0)
        #expect(UndirectedAdjacencyList<Int>.stochasticKronecker(initiator: [[0.5, 0.5], [0.5, 0.5]], iterations: 2, using: &generator).vertexCount == 4)
    }
}
