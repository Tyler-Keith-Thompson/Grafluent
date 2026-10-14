// `chinesePostmanTour(weight:)` against oracles written inside each test, with shrinking
// (swift-property-based). Graphs are multigraphs with self-loops and parallel edges, their
// vertices listed in a seeded shuffled order (so vertex indices are not vertex values). The
// undirected oracle is the definition: the least total weight of a set of edges to duplicate that
// makes every degree even, over every subset of the non-loop edges. The directed oracle sends each
// unit of surplus to a unit of deficit along a shortest path (Floyd–Warshall), the least over every
// assignment. Every returned walk is checked on its own: closed, from the first vertex with an
// edge, each edge taken once plus once per listing in `duplicatedEdges`, each step along its edge.
// Conditions are computed into a constant before `#expect` (README.md).

import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing
import Tours
import Walks

@Suite("chinesePostmanTour against oracles, with shrinking", .tags(.randomized))
struct ChinesePostmanPropertyTests {
    @Test("Undirected: the weight is the least over every set of duplicated edges; the walk is genuine")
    func undirected() async {
        let raw = zip(Gen.int(in: 0 ... 6), zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 9))).array(of: 0 ... 10)
        await propertyCheck(count: 400, input: raw, Gen.int(in: 1 ... 7), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1.0 % n) }
            let weights = raw.map { $0.1.1 }
            let m = ends.count
            let graph = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
            // Number vertices by their index in `vertices`.
            let order = Array(graph.vertices)
            let index = { (v: Int) in order.firstIndex(of: v)! }
            let ix = ends.map { (index(listed[$0.0]), index(listed[$0.1])) }
            var degree = [Int](repeating: 0, count: n)
            var parent = Array(0 ..< n)
            func root(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (a, b) in ix {
                degree[a] += 1
                degree[b] += 1
                parent[root(a)] = root(b)
            }
            let withEdges = (0 ..< n).filter { degree[$0] > 0 }
            let connected = Set(withEdges.map(root)).count <= 1
            let tour = graph.chinesePostmanTour { weights[$0] }
            guard m > 0, connected else {
                let none = tour == nil
                #expect(none, "\(ends) on \(listed)")
                return
            }
            guard let tour else {
                Issue.record("nil for \(ends) on \(listed)")
                return
            }
            // The oracle: every subset of the non-loop edges.
            let candidates = (0 ..< m).filter { ix[$0].0 != ix[$0].1 }
            var best = Int.max
            for mask in 0 ..< (1 << candidates.count) {
                var parity = degree.map { $0 & 1 }
                var extra = 0
                for (bit, e) in candidates.enumerated() where mask >> bit & 1 == 1 {
                    parity[ix[e].0] ^= 1
                    parity[ix[e].1] ^= 1
                    extra += weights[e]
                }
                if parity.allSatisfy({ $0 == 0 }) { best = min(best, extra) }
            }
            let optimum = weights.reduce(0, +) + best
            // The walk on its own.
            let vs = tour.walk.vertices.map(index), es = tour.walk.edges
            var uses = [Int](repeating: 0, count: m)
            for e in es { uses[e] += 1 }
            var expectedUses = [Int](repeating: 1, count: m)
            for e in tour.duplicatedEdges { expectedUses[e] += 1 }
            let steps = es.indices.allSatisfy { i in
                let (a, b) = ix[es[i]]
                return (a == vs[i] && b == vs[i + 1]) || (b == vs[i] && a == vs[i + 1])
            }
            let walked = es.reduce(0) { $0 + weights[$1] }
            let genuine = vs.first == withEdges.first && vs.first == vs.last && uses == expectedUses && steps
                && tour.duplicatedEdges == tour.duplicatedEdges.sorted() && Set(tour.duplicatedEdges).count == tour.duplicatedEdges.count
            let optimal = tour.weight == optimum && walked == optimum
            #expect(genuine, "\(ends) on \(listed): \(tour)")
            #expect(optimal, "\(ends) on \(listed): \(tour.weight), optimum \(optimum)")
        }
    }

    @Test("Undirected, larger: the weight is the edges' total plus the least perfect matching of the odd vertices on Floyd–Warshall distances")
    func undirectedMatchingOracle() async {
        let raw = zip(Gen.int(in: 0 ... 11), zip(Gen.int(in: 0 ... 11), Gen.int(in: 1 ... 20))).array(of: 8 ... 26)
        await propertyCheck(count: 300, input: raw, Gen.int(in: 6 ... 12)) { raw, n in
            // A spanning path first, so the edges are connected.
            var ends = (0 ..< n - 1).map { ($0, $0 + 1) }
            var weights = (0 ..< n - 1).map { 1 + ($0 * 7) % 13 }
            for (u, (v, w)) in raw {
                ends.append((u % n, v % n))
                weights.append(w)
            }
            let graph = Pseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            let infinity = Int.max / 4
            var d = [[Int]](repeating: [Int](repeating: infinity, count: n), count: n)
            var degree = [Int](repeating: 0, count: n)
            for v in 0 ..< n { d[v][v] = 0 }
            for (e, (a, b)) in ends.enumerated() {
                degree[a] += 1
                degree[b] += 1
                d[a][b] = min(d[a][b], weights[e])
                d[b][a] = min(d[b][a], weights[e])
            }
            for k in 0 ..< n { for i in 0 ..< n { for j in 0 ..< n where d[i][k] + d[k][j] < d[i][j] { d[i][j] = d[i][k] + d[k][j] } } }
            let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
            // The least perfect matching, by pairing the first unmatched odd vertex with each other.
            func best(_ left: [Int]) -> Int {
                guard let first = left.first else { return 0 }
                var least = Int.max
                for i in 1 ..< left.count {
                    var rest = left
                    rest.remove(at: i)
                    rest.removeFirst()
                    least = min(least, d[first][left[i]] + best(rest))
                }
                return least
            }
            let optimum = weights.reduce(0, +) + best(odd)
            let tour = graph.chinesePostmanTour { weights[$0] }
            let weight = tour?.weight
            #expect(weight == optimum, "\(ends), weights \(weights)")
        }
    }

    @Test("Directed: the weight is the least assignment of surplus to deficit along shortest paths; the walk is genuine")
    func directed() async {
        let raw = zip(Gen.int(in: 0 ... 4), zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 9))).array(of: 0 ... 9)
        await propertyCheck(count: 400, input: raw, Gen.int(in: 1 ... 5), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = Array(0 ..< n).shuffled(using: &rng)
            var ends = raw.map { ($0.0 % n, $0.1.0 % n) }
            // Every other seed closes the arcs into a cycle through their ends, so most graphs are
            // strongly connected.
            if seed % 2 == 0, !ends.isEmpty {
                let touched = Array(Set(ends.flatMap { [$0.0, $0.1] })).sorted()
                for i in touched.indices { ends.append((touched[i], touched[(i + 1) % touched.count])) }
            }
            let weights = ends.indices.map { raw.isEmpty ? 1 : raw[$0 % raw.count].1.1 }
            let m = ends.count
            let graph = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
            let order = Array(graph.vertices)
            let index = { (v: Int) in order.firstIndex(of: v)! }
            let ix = ends.map { (index(listed[$0.0]), index(listed[$0.1])) }
            // Floyd–Warshall over the arcs.
            let infinity = Int.max / 4
            var d = [[Int]](repeating: [Int](repeating: infinity, count: n), count: n)
            for v in 0 ..< n { d[v][v] = 0 }
            var balance = [Int](repeating: 0, count: n)
            var hasEdge = [Bool](repeating: false, count: n)
            for (e, (a, b)) in ix.enumerated() {
                d[a][b] = min(d[a][b], weights[e])
                balance[b] += 1
                balance[a] -= 1
                hasEdge[a] = true
                hasEdge[b] = true
            }
            for k in 0 ..< n { for i in 0 ..< n { for j in 0 ..< n where d[i][k] + d[k][j] < d[i][j] { d[i][j] = d[i][k] + d[k][j] } } }
            let withEdges = (0 ..< n).filter { hasEdge[$0] }
            let strong = withEdges.allSatisfy { a in withEdges.allSatisfy { b in d[a][b] < infinity } }
            let tour = graph.chinesePostmanTour { weights[$0] }
            guard m > 0, strong else {
                let none = tour == nil
                #expect(none, "\(ends) on \(listed)")
                return
            }
            guard let tour else {
                Issue.record("nil for \(ends) on \(listed)")
                return
            }
            // Units of surplus (more in than out) and of deficit, each assignment of one to the other.
            var surplus: [Int] = [], deficit: [Int] = []
            for v in 0 ..< n {
                if balance[v] > 0 { surplus += Array(repeating: v, count: balance[v]) }
                if balance[v] < 0 { deficit += Array(repeating: v, count: -balance[v]) }
            }
            var best = Int.max
            if surplus.count <= 6 {
                var perm = Array(deficit.indices)
                func permute(_ k: Int) {
                    if k == perm.count {
                        best = min(best, zip(surplus, perm).reduce(0) { $0 + d[$1.0][deficit[$1.1]] })
                        return
                    }
                    for i in k ..< perm.count {
                        perm.swapAt(k, i)
                        permute(k + 1)
                        perm.swapAt(k, i)
                    }
                }
                permute(0)
            }
            let vs = tour.walk.vertices.map(index), es = tour.walk.edges
            var uses = [Int](repeating: 0, count: m)
            for e in es { uses[e] += 1 }
            var expectedUses = [Int](repeating: 1, count: m)
            for e in tour.duplicatedEdges { expectedUses[e] += 1 }
            let steps = es.indices.allSatisfy { ix[es[$0]] == (vs[$0], vs[$0 + 1]) }
            let walked = es.reduce(0) { $0 + weights[$1] }
            let genuine = vs.first == withEdges.first && vs.first == vs.last && uses == expectedUses && steps
                && tour.duplicatedEdges == tour.duplicatedEdges.sorted() && walked == tour.weight
            #expect(genuine, "\(ends) on \(listed): \(tour)")
            if best != Int.max {
                let optimal = tour.weight == weights.reduce(0, +) + best
                #expect(optimal, "\(ends) on \(listed): \(tour.weight), oracle \(weights.reduce(0, +) + best)")
            }
        }
    }
}
