// Large shapes, each inside a Task with a one-minute limit, meant to finish within a few seconds in a
// debug build; the benchmarks take timings. A random mapping on 3 × 10⁵ vertices (the decomposition
// against its own invariants, sampled orbits and Connectivity), a path of 10⁶ vertices into a fixed
// point (no recursion in the decomposition), a permutation of 10⁵ vertices, and Pollard-rho closures
// x² + c mod m with m up to 3 × 10⁹, where both detectors must agree with an orbit dictionary and
// Floyd with its closed-form call count. See README.md.

import Connectivity
import FunctionalGraphs
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("FunctionalGraphs at scale")
struct FunctionalGraphStressTests {
    @Test("A random mapping on 3 × 10⁵ vertices", .timeLimit(.minutes(1)))
    func randomMapping() async {
        await Task {
            let n = 300_000
            var rng = SeededRandomNumberGenerator(seed: 11)
            let successors = (0 ..< n).map { _ in Int.random(in: 0 ..< n, using: &rng) }
            let graph = FunctionalGraph(successors: successors)
            let whole = graph.cycleDecomposition()
            // Invariants: each cyclic vertex is on exactly one listed cycle, which starts at its least
            // vertex; cycles are ordered by least vertex; preimages partition the vertices.
            // Violations are counted, not expected one by one, to keep a debug run fast.
            var onCycle = [Bool](repeating: false, count: n)
            var previousLeast = -1
            var violations = 0
            for (i, cycle) in whole.cycles.enumerated() {
                if cycle.first! != cycle.min()! || cycle.first! <= previousLeast { violations += 1 }
                previousLeast = cycle.first!
                for (k, v) in cycle.enumerated() {
                    if onCycle[v] || successors[v] != cycle[cycle.startIndex + (k + 1) % cycle.count] { violations += 1 }
                    onCycle[v] = true
                    if whole.component(of: v) != i || whole.tailLength(of: v) != 0 || whole.root(of: v) != v { violations += 1 }
                }
            }
            var preimageTotal = 0
            for v in 0 ..< n {
                preimageTotal += whole.preimages(of: v).count
                if whole.preimages(of: v).contains(where: { successors[$0] != v }) { violations += 1 }
                let w = successors[v]
                if !onCycle[v], whole.tailLength(of: v) != whole.tailLength(of: w) + 1 || whole.root(of: v) != whole.root(of: w) { violations += 1 }
                if whole.component(of: v) != whole.component(of: w) { violations += 1 }
            }
            #expect(violations == 0)
            #expect(preimageTotal == n)
            #expect(graph.weaklyConnectedComponents().count == whole.cycles.count)
            // Sampled orbits against an orbit dictionary, and f^k against a walk.
            for _ in 0 ..< 200 {
                let v = Int.random(in: 0 ..< n, using: &rng)
                var seen: [Int: Int] = [:]
                var x = v, i = 0
                while seen[x] == nil {
                    seen[x] = i
                    x = successors[x]
                    i += 1
                }
                let mu = seen[x]!, lambda = i - mu
                #expect(whole.tailLength(of: v) == mu && whole.cycleLength(of: v) == lambda && whole.root(of: v) == x)
                let detected = brentCycleDetection(from: v) { successors[$0] }
                #expect(detected.tailLength == mu && detected.cycleLength == lambda && detected.root == x)
                for k in [0, 1, mu / 2, mu, mu + 1, n + 1, 1_000_000_000_000_000] {
                    var y = v
                    for _ in 0 ..< (k <= mu ? k : mu + (k - mu) % lambda) { y = successors[y] }
                    #expect(whole.successor(of: v, steps: k) == y && graph.successor(of: v, steps: k) == y)
                }
            }
        }.value
    }

    @Test("A path of 10⁶ vertices into a fixed point", .timeLimit(.minutes(1)))
    func longPath() async {
        await Task {
            let n = 1_000_000
            let graph = FunctionalGraph(vertexCount: n) { min($0 + 1, n - 1) }
            let whole = graph.cycleDecomposition()
            #expect(whole.cycles.map { Array($0) } == [[n - 1]])
            #expect(whole.tailLength(of: 0) == n - 1 && whole.root(of: 0) == n - 1)
            #expect(whole.successor(of: 0, steps: n / 2) == n / 2 && whole.successor(of: 0, steps: Int.max) == n - 1)
            #expect(graph.successor(of: 0, steps: n - 2) == n - 2 && graph.successor(of: 0, steps: n + 5) == n - 1)
            #expect(whole.inDegree(of: n - 1) == 2 && Array(whole.preimages(of: n - 1)) == [n - 2, n - 1])
            let floyd = floydCycleDetection(from: 0) { min($0 + 1, n - 1) }
            #expect(floyd.tailLength == n - 1 && floyd.cycleLength == 1 && floyd.root == n - 1)
        }.value
    }

    @Test("A permutation of 10⁵ vertices: every tail is zero and f^λ is the identity", .timeLimit(.minutes(1)))
    func permutation() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 12)
            let successors = Array((0 ..< n).shuffled(using: &rng))
            let graph = FunctionalGraph(successors: successors)
            let whole = graph.cycleDecomposition()
            #expect(whole.cycles.reduce(0) { $0 + $1.count } == n)
            for v in stride(from: 0, to: n, by: 97) {
                #expect(whole.tailLength(of: v) == 0 && whole.inDegree(of: v) == 1)
                #expect(whole.successor(of: v, steps: whole.cycleLength(of: v)) == v)
                #expect(whole.successor(of: v, steps: whole.cycleLength(of: v) * 1_000_003 + 1) == successors[v])
            }
        }.value
    }

    @Test("Pollard-rho closures x² + c mod m, m up to 3 × 10⁹", .timeLimit(.minutes(1)))
    func pollardRho() async {
        await Task {
            var rng = SeededRandomNumberGenerator(seed: 13)
            for round in 0 ..< 120 {
                let m = round < 100 ? Int.random(in: 2 ... 1_000_000, using: &rng) : Int.random(in: 1_000_000_000 ... 3_000_000_000, using: &rng)
                let c = Int.random(in: 1 ..< m, using: &rng)
                let x0 = Int.random(in: 0 ..< m, using: &rng)
                let f = { (x: Int) -> Int in (x * x + c) % m }
                var seen: [Int: Int] = [:]
                var x = x0, i = 0
                while seen[x] == nil {
                    seen[x] = i
                    x = f(x)
                    i += 1
                }
                let mu = seen[x]!, lambda = i - mu
                var floydCalls = 0
                let floyd = floydCycleDetection(from: x0, successor: { (v: Int) -> Int in
                    floydCalls += 1
                    return f(v)
                })
                let brent = brentCycleDetection(from: x0, successor: f)
                #expect(floyd.tailLength == mu && floyd.cycleLength == lambda && floyd.root == x, "m \(m), c \(c), x0 \(x0)")
                #expect(brent.tailLength == mu && brent.cycleLength == lambda && brent.root == x, "m \(m), c \(c), x0 \(x0)")
                #expect(floydCalls == 3 * lambda * ((max(mu, 1) + lambda - 1) / lambda) + 2 * mu + lambda, "m \(m), c \(c), x0 \(x0)")
            }
            // The factor-finding use: gcd(|x − y|, m) at the meeting point of 8 051 = 83 · 97.
            let m = 8_051
            let f = { (x: Int) -> Int in (x * x + 1) % m }
            let rho = brentCycleDetection(from: 2, successor: f)
            var a = rho.root, b = rho.root
            for _ in 0 ..< rho.cycleLength { b = f(b) }
            #expect(a == b)
            a = 2
            b = 2
            var factor = 1
            while factor == 1 {
                a = f(a)
                b = f(f(b))
                var p = abs(a - b), q = m
                while q != 0 { (p, q) = (q, p % q) }
                factor = p
            }
            #expect(factor == 97)
        }.value
    }
}
