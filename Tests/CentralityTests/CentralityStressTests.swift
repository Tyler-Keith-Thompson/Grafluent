// Large shapes, which no recursive search survives and no dense matrix fits. Each runs inside a
// Task, whose stack is much smaller than the main thread's, with a one-minute limit; each is sized
// to stay well under that in a debug build. The catalog has no stress section, so every literal
// here was computed with ref.py's model functions (api.md's model in index space) at that size,
// with the dense matrix of its iterative models replaced by the same rows: degree on a 10⁵-leaf
// star, one-vertex closeness and harmonic on a 10⁵-vertex path (unweighted and weighted), every
// closeness, harmonic and betweenness score of a 2000-vertex path (closed forms ref.py checks
// against its model), Brandes on a 30 × 30 grid (shortest-path counts above 2⁵³, which ref.py
// checks against exact rational arithmetic to 1.1e-16), a directed 1000-cycle, PageRank on a 10⁵-leaf
// star and a 10⁵-vertex directed path, Katz on a 10⁵-vertex path, HITS on a 10⁵-leaf directed star,
// and eigenvector centrality on a 10⁴-leaf star (slow to converge: nil with the defaults) and a
// 10⁵-cycle. Iterative results are compared with the limit, within a bound ref.py's model meets
// with the same parameters.

import AdjacencyListModule
import Centrality
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Centrality on large graphs, without recursion")
struct CentralityStressTests {
    @Test("U(S(0;1..99999)).degreeCentrality() on UndirectedAdjacencyList: the hub 1, every leaf 1/(n − 1); graph.directed twice", .timeLimit(.minutes(1)))
    func starDegree() async {
        await Task {
            // U: [0..99999] S(0;1..99999)
            let n = 100_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) })
            let result = graph.degreeCentrality()
            // Computed with ref.py: degree_model.
            let leaf = 1.000010000100001e-05
            #expect(abs(result.score(of: 0) - 1) <= 1e-12)
            let worst = (1 ..< n).map { abs(result.score(of: $0) - leaf) }.max()!
            #expect(worst <= 1e-12 * leaf)
            let arcs = graph.directed.degreeCentrality()
            #expect(abs(arcs.score(of: 0) - 2) <= 1e-12)
            let arcLeaf = abs(arcs.score(of: n - 1) - 2 * leaf)
            #expect(arcLeaf <= 1e-12 * leaf)
        }.value
    }

    @Test("D(S(0;1..99999)) on CompressedSparseRow: out-degree 1 at the hub and 0 at the leaves, in-degree the reverse", .timeLimit(.minutes(1)))
    func directedStarDegree() async {
        await Task {
            // D: [0..99999] S(0;1..99999)
            let n = 100_000
            let graph = CompressedSparseRow(vertexCount: n, edges: (1 ..< n).map { DirectedEdge(from: 0, to: $0) })
            let outs = graph.outDegreeCentrality()
            let ins = graph.inDegreeCentrality()
            // Computed with ref.py: degree_model.
            let leaf = 1.000010000100001e-05
            #expect(abs(outs.score(of: 0) - 1) <= 1e-12)
            #expect(outs.score(of: 1) == 0)
            #expect(ins.score(of: 0) == 0)
            let worst = (1 ..< n).map { abs(ins.score(of: $0) - leaf) }.max()!
            #expect(worst <= 1e-12 * leaf)
        }.value
    }

    @Test("U(P(0..99999)): closenessCentrality(of:) at 0 and 50000, harmonicCentrality(of: 0), one search each", .timeLimit(.minutes(1)))
    func pathOneVertex() async {
        await Task {
            // U: [0..99999] P(0..99999)
            let n = 100_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            // Computed with ref.py: closeness_model(only:).
            let end = abs(graph.closenessCentrality(of: 0) - 2e-05)
            #expect(end <= 1e-12 * 2e-05)
            let middle = abs(graph.closenessCentrality(of: 50_000) - 3.99996e-05)
            #expect(middle <= 1e-12 * 3.99996e-05)
            let harmonic = abs(graph.harmonicCentrality(of: 0) - 12.090136129863428)
            #expect(harmonic <= 1e-12 * 12.090136129863428)
        }.value
    }

    @Test("U(P(0..99999)) weighted e % 3 + 1: closenessCentrality(of: 0) and harmonicCentrality(of: 99999), one Dijkstra each", .timeLimit(.minutes(1)))
    func weightedPathOneVertex() async {
        await Task {
            // U: [0..99999] P(0..99999), weight: e%3+1
            let n = 100_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let w = (0 ..< n - 1).map { $0 % 3 + 1 }
            // Computed with ref.py: closeness_model(only:) with these weights.
            let closeness = graph.closenessCentrality(of: 0, weight: { w[$0] })
            let error = abs(closeness - 1.0000066667111114e-05)
            #expect(error <= 1e-12 * 1.0000066667111114e-05)
            let harmonic = graph.harmonicCentrality(of: 99_999, weight: { Double(w[$0]) })
            let harmonicError = abs(harmonic - 5.779064938758595)
            #expect(harmonicError <= 1e-12 * 5.779064938758595)
        }.value
    }

    @Test("U(P(0..1999)): every closeness, harmonic and betweenness score", .timeLimit(.minutes(1)))
    func pathAllPairs() async {
        await Task {
            // U: [0..1999] P(0..1999)
            let n = 2_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let closeness = graph.closenessCentrality()
            let harmonic = graph.harmonicCentrality()
            let betweenness = graph.betweennessCentrality(normalized: false)
            // ref.py checks its model against these closed forms at n = 2000: closeness
            // (n − 1)/(i(i + 1)/2 + (n − 1 − i)(n − i)/2), betweenness i(n − 1 − i).
            for i in 0 ..< n {
                let total = i * (i + 1) / 2 + (n - 1 - i) * (n - i) / 2
                let expected = Double(n - 1) / Double(total)
                let error = abs(closeness.score(of: i) - expected)
                #expect(error <= 1e-12 * expected, "closeness \(i)")
                let between = abs(betweenness.score(of: i) - Double(i * (n - 1 - i)))
                #expect(between <= 1e-12 * max(1, Double(i * (n - 1 - i))), "betweenness \(i)")
            }
            // Computed with ref.py: closeness_model(harmonic: true).
            let indices = [0, 1, 999, 1000, 1999]
            let expectedHarmonic = [8.177868103610283, 9.17736785348522, 14.969941721100689, 14.969941721100689, 8.177868103610283]
            for (i, value) in zip(indices, expectedHarmonic) {
                let error = abs(harmonic.score(of: i) - value)
                #expect(error <= 1e-12 * value, "harmonic \(i)")
            }
        }.value
    }

    @Test("U(grid(30,30)).betweennessCentrality(): path counts above 2⁵³; the unnormalized total is Σ (d(s, t) − 1) over pairs", .timeLimit(.minutes(1)))
    func gridBetweenness() async {
        await Task {
            // U: grid(30,30): vertex 30r + c, edges right then down, row-major
            var pairs: [(Int, Int)] = []
            for r in 0 ..< 30 {
                for c in 0 ..< 30 {
                    let v = 30 * r + c
                    if c + 1 < 30 { pairs.append((v, v + 1)) }
                    if r + 1 < 30 { pairs.append((v, v + 30)) }
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 900, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let result = graph.betweennessCentrality()
            // Computed with ref.py: betweenness_model, checked against exact rational Brandes.
            let indices = [0, 1, 31, 435, 464, 899]
            let expected = [
                1.6980862373517557e-05, 0.0011593081235439897, 0.003302615653047926, 0.04702211644297475,
                0.04702211644297473, 1.698086237351756e-05
            ]
            for (i, value) in zip(indices, expected) {
                let error = abs(result.score(of: i) - value)
                #expect(error <= 1e-12, "vertex \(i)")
            }
            // Computed with ref.py: Σ over unordered pairs of (|Δr| + |Δc| − 1) = 7686450.
            let unnormalized = graph.betweennessCentrality(normalized: false)
            let total = unnormalized.scores.reduce(0, +)
            #expect(abs(total - 7_686_450) <= 1e-9 * 7_686_450)
        }.value
    }

    @Test("D(C(0..999)) on CompressedSparseRow: unnormalized betweenness (n − 1)(n − 2)/2 = 498501 everywhere", .timeLimit(.minutes(1)))
    func directedCycleBetweenness() async {
        await Task {
            // D: [0..999] C(0..999)
            let n = 1_000
            let graph = CompressedSparseRow(vertexCount: n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) })
            let result = graph.betweennessCentrality(normalized: false)
            // Computed with ref.py: betweenness_model.
            let worst = result.scores.map { abs($0 - 498_501) }.max()!
            #expect(worst <= 1e-12 * 498_501)
        }.value
    }

    @Test("U(S(0;1..99999)).pageRank(tolerance: 1e-12, maxIterations: 1000): hub 0.45946…, leaves 5.405…e-06; sum 1", .timeLimit(.minutes(1)))
    func starPageRank() async throws {
        try await Task {
            // U: [0..99999] S(0;1..99999)
            let n = 100_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) })
            let result = try #require(graph.pageRank(tolerance: 1e-12, maxIterations: 1_000))
            // Computed with ref.py: pagerank_model to tolerance 1e-15 (the limit); with these
            // parameters the model lies within 2.1e-8 of it.
            #expect(abs(result.score(of: 0) - 0.45946027028966857) <= 1e-6)
            let worst = (1 ..< n).map { abs(result.score(of: $0) - 5.40545135160651e-06) }.max()!
            #expect(worst <= 1e-6)
            let total = result.scores.reduce(0, +)
            #expect(abs(total - 1) <= 1e-9)
        }.value
    }

    @Test("D(P(0..99999)).pageRank() on CompressedSparseRow, defaults: within 1e-4 of the limit", .timeLimit(.minutes(1)))
    func directedPathPageRank() async throws {
        try await Task {
            // D: [0..99999] P(0..99999)
            let n = 100_000
            let graph = CompressedSparseRow(vertexCount: n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) })
            let result = try #require(graph.pageRank())
            // Computed with ref.py: pagerank_model's limit; with the defaults it lies within 7.3e-6.
            let indices = [0, 1, 50, 99_998, 99_999]
            let expected = [1.5000850048169153e-06, 2.7751572589112896e-06, 9.99805255666874e-06, 1.0000566696327601e-05, 1.0000566696327601e-05]
            for (i, value) in zip(indices, expected) {
                let error = abs(result.score(of: i) - value)
                #expect(error <= 1e-4, "vertex \(i)")
            }
        }.value
    }

    @Test("U(P(0..99999)).katzCentrality(), normalized and not, defaults", .timeLimit(.minutes(1)))
    func pathKatz() async throws {
        try await Task {
            // U: [0..99999] P(0..99999)
            let n = 100_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let result = try #require(graph.katzCentrality())
            // Computed with ref.py: katz_model's limit; with the defaults it lies within 2.2e-10
            // (normalized) and 1.3e-7 (not normalized).
            let indices = [0, 1, 2, 50_000, 99_999]
            let expected = [0.0028428288401687314, 0.0031300128720493756, 0.0031590243506870864, 0.0031622844412047425, 0.0028428288401687314]
            for (i, value) in zip(indices, expected) {
                let error = abs(result.score(of: i) - value)
                #expect(error <= 1e-6, "vertex \(i)")
            }
            let raw = try #require(graph.katzCentrality(normalized: false))
            let rawExpected = [1.1237243569579451, 1.2372435695794524, 1.2487113388365794, 1.25, 1.1237243569579451]
            for (i, value) in zip(indices, rawExpected) {
                let error = abs(raw.score(of: i) - value)
                #expect(error <= 1e-6, "vertex \(i)")
            }
        }.value
    }

    @Test("D(S(0;1..99999)).hits() on CompressedSparseRow: the hub is the only hub, the leaves share the authority", .timeLimit(.minutes(1)))
    func directedStarHITS() async throws {
        try await Task {
            // D: [0..99999] S(0;1..99999)
            let n = 100_000
            let graph = CompressedSparseRow(vertexCount: n, edges: (1 ..< n).map { DirectedEdge(from: 0, to: $0) })
            let result = try #require(graph.hits())
            // Computed with ref.py: hits_model.
            #expect(abs(result.hubs.score(of: 0) - 1) <= 1e-4)
            #expect(abs(result.authorities.score(of: 0)) <= 1e-4)
            let worstHub = (1 ..< n).map { abs(result.hubs.score(of: $0)) }.max()!
            #expect(worstHub <= 1e-4)
            let worstAuthority = (1 ..< n).map { abs(result.authorities.score(of: $0) - 1.000010000100001e-05) }.max()!
            #expect(worstAuthority <= 1e-9)
        }.value
    }

    @Test("U(S(0;1..9999)).eigenvectorCentrality(): nil with the defaults (the shifted iteration contracts by 0.98); with tolerance 1e-10 the hub is 1/√2", .timeLimit(.minutes(1)))
    func starEigenvector() async throws {
        try await Task {
            // U: [0..9999] S(0;1..9999)
            let n = 10_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) })
            // Computed with ref.py: eigenvector_model returns nil with the defaults.
            #expect(graph.eigenvectorCentrality() == nil)
            let result = try #require(graph.eigenvectorCentrality(tolerance: 1e-10, maxIterations: 10_000))
            // Computed with ref.py: the closed form 1/√2, 1/√(2(n − 1)), which its model at
            // tolerance 1e-13 meets within 5e-12; with these parameters it lies within 4.9e-9.
            #expect(abs(result.score(of: 0) - 0.7071067811865475) <= 1e-6)
            let worst = (1 ..< n).map { abs(result.score(of: $0) - 0.007071421391774782) }.max()!
            #expect(worst <= 1e-6)
        }.value
    }

    @Test("U(C(0..99999)).eigenvectorCentrality(): uniform 1/√n, converged on the first iteration", .timeLimit(.minutes(1)))
    func cycleEigenvector() async throws {
        try await Task {
            // U: [0..99999] C(0..99999)
            let n = 100_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            let result = try #require(graph.eigenvectorCentrality())
            // Computed with ref.py: eigenvector_model.
            let worst = result.scores.map { abs($0 - 0.0031622776601683794) }.max()!
            #expect(worst <= 1e-4)
            #expect(result.scores.count == n)
        }.value
    }
}
