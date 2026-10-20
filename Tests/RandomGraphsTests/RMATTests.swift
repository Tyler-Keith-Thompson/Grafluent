// R-MAT (Chakrabarti, Zhan and Faloutsos): 2^scale vertices and exactly the edges asked for, simple,
// in row-major order, the same again from the same seed, on undirected and directed targets. The
// quadrant probabilities are checked statistically: with a near 1 almost every edge lies among the
// first half of the vertices, with equal quarters about a quarter does, and with b = 1 every edge
// goes from the first half to the second. Degenerate cases (scale 0, no edges, every pair),
// an undirected graph's canonical pairs, and the exit tests for the preconditions.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import RandomGraphs
import Testing

@Suite("RandomGraphs R-MAT")
struct RMATTests {
    @Test("2^scale vertices, exactly the edges asked for, simple, canonical, repeatable by seed")
    func shape() {
        for scale in [1, 3, 6] {
            let n = 1 << scale
            for m in [0, 1, n, 3 * n] where m <= n * (n - 1) / 2 {
                var a = Xoshiro256StarStar(seed: UInt64(scale * 100 + m)), b = a
                let graph = UndirectedAdjacencyList<Int>.rmat(scale: scale, edgeCount: m, using: &a)
                #expect(graph.vertexCount == n && graph.edgeCount == m, "scale \(scale), m \(m)")
                #expect(graph.edges.allSatisfy { $0.u < $0.v }, "scale \(scale), m \(m)")
                #expect(Set(graph.edges.map { [$0.u, $0.v] }).count == m, "scale \(scale), m \(m)")
                #expect(UndirectedAdjacencyList<Int>.rmat(scale: scale, edgeCount: m, using: &b) == graph, "scale \(scale), m \(m)")
                var c = Xoshiro256StarStar(seed: UInt64(scale * 100 + m))
                let digraph = CompressedSparseRow.rmat(scale: scale, edgeCount: m, using: &c)
                #expect(digraph.vertexCount == n && digraph.edgeCount == m, "directed scale \(scale), m \(m)")
                #expect(digraph.edges.allSatisfy { $0.source != $0.target }, "directed scale \(scale), m \(m)")
                let pairs = digraph.edges.map { [$0.source, $0.target] }
                #expect(pairs == pairs.sorted { $0.lexicographicallyPrecedes($1) }, "row-major; directed scale \(scale), m \(m)")
            }
        }
    }

    @Test("A fixed seed gives these arcs: the levels descend from the top bit, the draws in order")
    func pinned() {
        var generator = Xoshiro256StarStar(seed: 3)
        let graph = CompressedSparseRow.rmat(scale: 3, edgeCount: 6, a: 0.6, b: 0.3, c: 0.1, using: &generator)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 6], [0, 7], [1, 2], [2, 1], [4, 0], [6, 0]])
    }

    @Test("Degenerate cases: scale 0 is one vertex with no edges; every pair is the complete graph")
    func degenerate() {
        var generator = Xoshiro256StarStar(seed: 1)
        let one = UndirectedAdjacencyList<Int>.rmat(scale: 0, edgeCount: 0, using: &generator)
        #expect(one.vertexCount == 1 && one.edgeCount == 0)
        let full = UndirectedAdjacencyList<Int>.rmat(scale: 3, edgeCount: 28, using: &generator)
        #expect(full.edgeCount == 28 && (0 ..< 8).allSatisfy { full.degree(of: $0) == 7 })
        let fullDirected = CompressedSparseRow.rmat(scale: 2, edgeCount: 12, using: &generator)
        #expect(fullDirected.edgeCount == 12 && (0 ..< 4).allSatisfy { fullDirected.outDegree(of: $0) == 3 })
        let system = UndirectedAdjacencyList<Int>.rmat(scale: 4, edgeCount: 20)
        #expect(system.vertexCount == 16 && system.edgeCount == 20)
        let systemDirected = CompressedSparseRow.rmat(scale: 4, edgeCount: 20)
        #expect(systemDirected.vertexCount == 16 && systemDirected.edgeCount == 20)
    }

    @Test("The quadrant probabilities: a near 1 keeps edges in the first half, equal quarters spread them, b = 1 sends every arc from the first half to the second")
    func quadrants() {
        let scale = 10, n = 1 << scale, m = 4000
        var generator = Xoshiro256StarStar(seed: 7)
        // a = 0.7: at the top level the top-left quadrant is chosen with 0.7, but the skew piles
        // draws onto a few cells, and the repeats and loops redrawn pull the kept fraction down;
        // it still lies well above the uniform quarter.
        let skewed = CompressedSparseRow.rmat(scale: scale, edgeCount: m, a: 0.7, b: 0.1, c: 0.1, using: &generator)
        let firstHalf = Double(skewed.edges.filter { $0.source < n / 2 && $0.target < n / 2 }.count) / Double(m)
        #expect(firstHalf > 0.55 && firstHalf < 0.75, "\(firstHalf)")
        let uniform = CompressedSparseRow.rmat(scale: scale, edgeCount: m, a: 0.25, b: 0.25, c: 0.25, using: &generator)
        let quarter = Double(uniform.edges.filter { $0.source < n / 2 && $0.target < n / 2 }.count) / Double(m)
        #expect(quarter > 0.2 && quarter < 0.3, "\(quarter)")
        #expect(firstHalf > quarter + 0.2)
        // b = 1: every level picks the top-right quadrant, so every arc goes from vertex 0 to the
        // last vertex; only one such arc exists, so ask for one.
        let corner = CompressedSparseRow.rmat(scale: 3, edgeCount: 1, a: 0, b: 1, c: 0, using: &generator)
        #expect(corner.edges.map { [$0.source, $0.target] } == [[0, 7]])
        // c = 1 is the transpose: from the last vertex to 0.
        let other = CompressedSparseRow.rmat(scale: 3, edgeCount: 1, a: 0, b: 0, c: 1, using: &generator)
        #expect(other.edges.map { [$0.source, $0.target] } == [[7, 0]])
        // Undirected, the same pair is 0–7 either way.
        let undirected = UndirectedAdjacencyList<Int>.rmat(scale: 3, edgeCount: 1, a: 0, b: 0, c: 1, using: &generator)
        #expect(undirected.edges.map { [$0.u, $0.v] } == [[0, 7]])
    }
}

@Suite("RandomGraphs R-MAT preconditions", .tags(.precondition))
struct RMATPreconditionTests {
    @Test("A negative scale traps")
    func negativeScale() async {
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 1)
            _ = UndirectedAdjacencyList<Int>.rmat(scale: -1, edgeCount: 0, using: &generator)
        }
    }

    @Test("More edges than pairs traps")
    func tooManyEdges() async {
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 1)
            _ = UndirectedAdjacencyList<Int>.rmat(scale: 2, edgeCount: 7, using: &generator)
        }
    }

    @Test("A negative edge count traps, directed")
    func negativeEdges() async {
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 1)
            _ = CompressedSparseRow.rmat(scale: 2, edgeCount: -1, using: &generator)
        }
    }

    @Test("Probabilities summing past 1 trap")
    func probabilitiesOverOne() async {
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 1)
            _ = UndirectedAdjacencyList<Int>.rmat(scale: 3, edgeCount: 4, a: 0.6, b: 0.3, c: 0.3, using: &generator)
        }
    }

    @Test("A negative probability traps")
    func negativeProbability() async {
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 1)
            _ = CompressedSparseRow.rmat(scale: 3, edgeCount: 4, a: -0.1, b: 0.5, c: 0.3, using: &generator)
        }
    }

    @Test("A NaN probability traps")
    func nanProbability() async {
        await #expect(processExitsWith: .failure) {
            var generator = Xoshiro256StarStar(seed: 1)
            _ = UndirectedAdjacencyList<Int>.rmat(scale: 3, edgeCount: 4, a: .nan, b: 0.2, c: 0.2, using: &generator)
        }
    }
}
