// Properties with shrinking (swift-property-based), each against a model written out in the test:
// - the decomposition laws, against orbits walked with a dictionary of first occurrences (the tail
//   length, cycle length and root of every vertex), cycles listed from their least vertex in order
//   of least vertex, preimages and in-degrees by filtering, components by cycle;
// - f^k on the graph and on the decomposition, against iterating f, for small k and for huge k
//   reduced by the orbit;
// - Floyd and Brent over a closure, against the orbit model, with Floyd's call count against its
//   closed form 3ν + 2μ + λ and Brent's against the pinned formulation run on the array;
// - init?(_ graph:) round trips and rejects any out-degree but 1.
// See README.md.

import FunctionalGraphs
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("FunctionalGraphs properties against models, with shrinking", .tags(.randomized))
struct FunctionalGraphPropertyTests {
    @Test("The decomposition agrees with orbits walked from every vertex")
    func decompositionLaws() async {
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 1_000).array(of: 0 ... 40)) { raw in
            let n = raw.count
            let successors = raw.map { $0 % max(n, 1) }
            let graph = FunctionalGraph(successors: successors)
            let whole = graph.cycleDecomposition()
            // The model: each orbit's first repeat.
            var tail = [Int](repeating: 0, count: n), length = tail, root = tail
            for v in 0 ..< n {
                var seen: [Int: Int] = [:]
                var x = v, i = 0
                while seen[x] == nil {
                    seen[x] = i
                    x = successors[x]
                    i += 1
                }
                tail[v] = seen[x]!
                length[v] = i - seen[x]!
                root[v] = x
            }
            var cycles: [[Int]] = []
            var listed = Set<Int>()
            for v in 0 ..< n where tail[v] == 0 && !listed.contains(v) {
                var cycle = [v]
                var x = successors[v]
                while x != v {
                    cycle.append(x)
                    x = successors[x]
                }
                listed.formUnion(cycle)
                cycles.append(cycle)
            }
            let context = "\(successors)"
            #expect(whole.cycles.map { Array($0) } == cycles, "\(context)")
            for v in 0 ..< n {
                #expect(whole.tailLength(of: v) == tail[v] && whole.cycleLength(of: v) == length[v] && whole.root(of: v) == root[v], "\(context): \(v)")
                #expect(whole.cycles[whole.component(of: v)].contains(root[v]), "\(context): \(v)")
                let preimages = (0 ..< n).filter { successors[$0] == v }
                #expect(Array(whole.preimages(of: v)) == preimages && whole.inDegree(of: v) == preimages.count, "\(context): \(v)")
            }
            #expect(cycles.reduce(0) { $0 + $1.count } == tail.filter { $0 == 0 }.count, "\(context)")
        }
    }

    @Test("f^k on the graph and on the decomposition equals iterating f")
    func stepsAgainstIteration() async {
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 1_000).array(of: 1 ... 30), Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let n = raw.count
            let successors = raw.map { $0 % n }
            let graph = FunctionalGraph(successors: successors)
            let whole = graph.cycleDecomposition()
            let v = seed % n
            var x = v
            for k in 0 ... 2 * n + 2 {
                #expect(graph.successor(of: v, steps: k) == x && whole.successor(of: v, steps: k) == x, "\(successors): \(v), \(k)")
                x = successors[x]
            }
            // A huge k: f^k(v) = f^(μ + (k − μ) mod λ)(v), with μ and λ from v's orbit.
            var seen: [Int: Int] = [:]
            x = v
            var i = 0
            while seen[x] == nil {
                seen[x] = i
                x = successors[x]
                i += 1
            }
            let mu = seen[x]!, lambda = i - mu
            for k in [Int.max, Int.max - 1, Int.max - seed, 1 << 40 + seed, 3 * n + seed] {
                var y = v
                for _ in 0 ..< mu + (k - mu) % lambda { y = successors[y] }
                #expect(graph.successor(of: v, steps: k) == y && whole.successor(of: v, steps: k) == y, "\(successors): \(v), \(k)")
            }
        }
    }

    @Test("Floyd and Brent find the orbit's first repeat, with the pinned call counts")
    func cycleDetectionAgainstModel() async {
        await propertyCheck(count: 400, input: Gen.int(in: 0 ... 1_000).array(of: 1 ... 60), Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let n = raw.count
            let successors = raw.map { $0 % n }
            let start = seed % n
            var seen: [Int: Int] = [:]
            var x = start, i = 0
            while seen[x] == nil {
                seen[x] = i
                x = successors[x]
                i += 1
            }
            let mu = seen[x]!, lambda = i - mu, root = x
            var floydCalls = 0
            let floyd = floydCycleDetection(from: start, successor: { (v: Int) -> Int in
                floydCalls += 1
                return successors[v]
            })
            var brentCalls = 0
            let brent = brentCycleDetection(from: start, successor: { (v: Int) -> Int in
                brentCalls += 1
                return successors[v]
            })
            let context = "\(successors) from \(start)"
            #expect(floyd.tailLength == mu && floyd.cycleLength == lambda && floyd.root == root, "\(context)")
            #expect(brent.tailLength == mu && brent.cycleLength == lambda && brent.root == root, "\(context)")
            // Floyd: ν is the least multiple of λ that is at least max(μ, 1).
            let nu = lambda * ((max(mu, 1) + lambda - 1) / lambda)
            #expect(floydCalls == 3 * nu + 2 * mu + lambda, "\(context)")
            // Brent, as api.md pins it, run on the array: the power-of-two search, λ more steps for
            // the hare, then μ steps for both.
            var power = 1, found = 1, calls = 1
            var tortoise = start, hare = successors[start]
            while tortoise != hare {
                if power == found {
                    tortoise = hare
                    power *= 2
                    found = 0
                }
                hare = successors[hare]
                calls += 1
                found += 1
            }
            #expect(found == lambda, "\(context)")
            #expect(brentCalls == calls + lambda + 2 * mu, "\(context)")
        }
    }

    @Test("Floyd and Brent over Pollard-rho closures x² + c mod m")
    func pollardRho() async {
        await propertyCheck(count: 300, input: Gen.int(in: 2 ... 5_000), Gen.int(in: 1 ... 5_000), Gen.int(in: 0 ... 5_000)) { m, c, x0 in
            let f = { (x: Int) -> Int in (x * x + c) % m }
            var seen: [Int: Int] = [:]
            var x = x0 % m, i = 0
            while seen[x] == nil {
                seen[x] = i
                x = f(x)
                i += 1
            }
            let mu = seen[x]!, lambda = i - mu
            var floydCalls = 0
            let floyd = floydCycleDetection(from: x0 % m, successor: { (v: Int) -> Int in
                floydCalls += 1
                return f(v)
            })
            let brent = brentCycleDetection(from: x0 % m, successor: f)
            #expect(floyd.tailLength == mu && floyd.cycleLength == lambda && floyd.root == x, "m \(m), c \(c), x0 \(x0)")
            #expect(brent.tailLength == mu && brent.cycleLength == lambda && brent.root == x, "m \(m), c \(c), x0 \(x0)")
            let nu = lambda * ((max(mu, 1) + lambda - 1) / lambda)
            #expect(floydCalls == 3 * nu + 2 * mu + lambda, "m \(m), c \(c), x0 \(x0)")
        }
    }

    @Test("init?(_ graph:) round trips a functional graph and rejects any out-degree but 1")
    func fromGraph() async {
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 1_000).array(of: 1 ... 20), Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let n = raw.count
            let successors = raw.map { $0 % n }
            let edges = (0 ..< n).map { DirectedEdge(from: $0, to: successors[$0]) }
            // Vertices listed in a rotated order: vertex i is the graph's i-th vertex.
            let order = (0 ..< n).map { ($0 + seed) % n }
            let position = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
            let rotated = FunctionalGraph(DirectedPseudograph<Int>(vertices: order, edges: edges))
            #expect(rotated == FunctionalGraph(successors: order.map { position[successors[$0]]! }), "\(successors)")
            #expect(FunctionalGraph(DirectedPseudograph<Int>(vertices: 0 ..< n, edges: edges)) == FunctionalGraph(successors: successors))
            // One more edge (a parallel one included), or one fewer, gives nil.
            let extra = DirectedEdge(from: seed % n, to: (seed / n) % n)
            #expect(FunctionalGraph(DirectedPseudograph<Int>(vertices: 0 ..< n, edges: edges + [extra])) == nil, "\(successors) + \(extra)")
            var fewer = edges
            fewer.remove(at: seed % n)
            #expect(FunctionalGraph(DirectedPseudograph<Int>(vertices: 0 ..< n, edges: fewer)) == nil, "\(successors)")
        }
    }

    @Test("init(vertexCount:successor:) equals init(successors:) and calls once per vertex, ascending")
    func closureInit() async {
        await propertyCheck(count: 200, input: Gen.int(in: 0 ... 1_000).array(of: 0 ... 30)) { raw in
            let n = raw.count
            let successors = raw.map { $0 % max(n, 1) }
            var log: [Int] = []
            let graph = FunctionalGraph(vertexCount: n, successor: { (v: Int) -> Int in
                log.append(v)
                return successors[v]
            })
            #expect(graph == FunctionalGraph(successors: successors) && log == Array(0 ..< n), "\(successors)")
        }
    }
}
