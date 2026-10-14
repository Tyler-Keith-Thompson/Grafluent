// Infomap (Rosvall and Bergstrom) and the two-level map equation's code length. Code lengths of
// igraph 1.0's `community_infomap` partitions (its `codelength`) are the expected values;
// partitions where one is clearly best; degenerate graphs; weights; representations; exits; and a
// property test against the map equation written out over the edges.

import AdjacencyListModule
import CommunityDetection
import Foundation
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("Infomap")
struct InfomapTests {
    @Test("Two triangles joined by an edge: the two triangles, at igraph's code length")
    func twoTriangles() {
        let pairs = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = graph.infomapCommunities(using: &generator)
        #expect(result.map(Array.init) == [[0, 1, 2], [3, 4, 5]])
        #expect(abs(graph.codeLength(of: result) - 2.3207303568337903) <= 1e-12)
        #expect(abs(graph.codeLength(of: [Array(0 ..< 6)]) - 2.556656707462823) <= 1e-12)
    }

    @Test("A path of six: ties between equal moves go either way, so single trials find the two halves")
    func pathTies() {
        // Every vertex of the path 4–3–1–0–2–5 starts with two equal moves. Always taking the first
        // in row order merges the path into one module (2.5219 bits); the two halves are shorter.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(3, 4), UndirectedEdge(2, 5)])
        let halves = graph.codeLength(of: [[4, 3, 1], [0, 2, 5]])
        #expect(halves < graph.codeLength(of: [Array(0 ..< 6)]))
        var found = 0
        for seed in 0 ..< 40 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let partition = graph.infomapCommunities(trials: 1, using: &generator)
            if abs(graph.codeLength(of: partition) - halves) < 1e-12 { found += 1 }
        }
        #expect(found >= 10)
    }

    @Test("Zachary's karate club: igraph's partition has igraph's code length, and Infomap finds one as short")
    func karate() {
        let fixture = UndirectedFixture<Int>.karate
        let graph = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let membership = [0, 0, 0, 0, 1, 1, 1, 0, 2, 0, 1, 0, 0, 0, 2, 2, 1, 0, 2, 0, 2, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
        let igraph = (0 ..< 3).map { c in (0 ..< 34).filter { membership[$0] == c } }
        #expect(abs(graph.codeLength(of: igraph) - 4.31179264580183) <= 1e-12)
        #expect(abs(graph.codeLength(of: [Array(0 ..< 34)]) - 4.704422598883343) <= 1e-12)
        for seed in 0 ..< 5 as Range<UInt> {
            var generator = SeededRandomNumberGenerator(seed: seed)
            let result = graph.infomapCommunities(using: &generator)
            #expect(graph.codeLength(of: result) <= 4.31179264580183 + 1e-9, "seed \(seed)")
        }
    }

    @Test("A complete graph is one module; two disjoint K₄s are two, at 2 bits against one module's 3")
    func cliques() {
        var complete: [UndirectedEdge<Int>] = []
        for u in 0 ..< 5 { for v in u + 1 ..< 5 { complete.append(UndirectedEdge(u, v)) } }
        var generator = SeededRandomNumberGenerator(seed: 2)
        let k5 = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: complete)
        #expect(k5.infomapCommunities(using: &generator).map(Array.init) == [Array(0 ..< 5)])
        var two: [UndirectedEdge<Int>] = []
        for base in [0, 4] { for u in 0 ..< 4 { for v in u + 1 ..< 4 { two.append(UndirectedEdge(base + u, base + v)) } } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 8, edges: two)
        let result = graph.infomapCommunities(trials: 1, using: &generator)
        #expect(result.map(Array.init) == [[0, 1, 2, 3], [4, 5, 6, 7]])
        #expect(abs(graph.codeLength(of: result) - 2) <= 1e-12)
        #expect(abs(graph.codeLength(of: [Array(0 ..< 8)]) - 3) <= 1e-12)
    }

    @Test("No edges, only self-loops, or weights all zero: every vertex alone, code length 0 where nothing flows")
    func degenerate() {
        var generator = SeededRandomNumberGenerator(seed: 3)
        let empty = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(empty.infomapCommunities(using: &generator).isEmpty)
        #expect(empty.codeLength(of: [[Int]]()) == 0)
        let isolated = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: [])
        #expect(isolated.infomapCommunities(using: &generator).map(Array.init) == [[0], [1], [2]])
        #expect(isolated.codeLength(of: [[0, 1, 2]]) == 0)
        // Self-loops never leave a module: alone, each vertex costs nothing; together, one bit.
        let loops = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 0), UndirectedEdge(1, 1)])
        #expect(loops.infomapCommunities(using: &generator).map(Array.init) == [[0], [1]])
        #expect(abs(loops.codeLength(of: [[0], [1]])) <= 1e-12)
        #expect(abs(loops.codeLength(of: [[0, 1]]) - 1) <= 1e-12)
        let path = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(path.infomapCommunities(weight: { _ in 0.0 }, using: &generator).map(Array.init) == [[0], [1], [2]])
        #expect(path.codeLength(of: [[0, 1, 2]], weight: { _ in 0.0 }) == 0)
    }

    @Test("Weights: uniform ones and threes give the unweighted code length; a heavy edge pulls its ends together")
    func weights() {
        let pairs = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let split = [[0, 1, 2], [3, 4, 5]]
        #expect(abs(graph.codeLength(of: split, weight: { _ in 1.0 }) - graph.codeLength(of: split)) <= 1e-12)
        #expect(abs(graph.codeLength(of: split, weight: { _ in 3.0 }) - graph.codeLength(of: split)) <= 1e-12)
        // Parallel edges add like weights.
        let doubled = ReferencePseudograph(vertices: 0 ..< 6, edges: (pairs + pairs).map { UndirectedEdge($0.0, $0.1) })
        #expect(abs(doubled.codeLength(of: split) - graph.codeLength(of: split)) <= 1e-12)
        // A path 0–1–2–3 whose middle edge is heavy: {1, 2} keeps the flow.
        let path = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let heavy: (Int) -> Double = { path.edges[$0] == UndirectedEdge(1, 2) ? 50 : 1 }
        var generator = SeededRandomNumberGenerator(seed: 4)
        let result = path.infomapCommunities(weight: { heavy($0) }, using: &generator)
        #expect(result.community(of: 1) == result.community(of: 2))
        #expect(path.codeLength(of: result, weight: { heavy($0) }) <= path.codeLength(of: [[0], [1], [2], [3]], weight: { heavy($0) }))
    }

    @Test("The same seed gives the same partition; representations agree")
    func representations() {
        let pairs = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3), (5, 6), (6, 7), (7, 8), (8, 6)]
        let list = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var a = SeededRandomNumberGenerator(seed: 5), b = SeededRandomNumberGenerator(seed: 5)
        let first = list.infomapCommunities(using: &a)
        #expect(first == list.infomapCommunities(using: &b))
        #expect(first.map(Array.init) == [[0, 1, 2], [3, 4, 5], [6, 7, 8]])
        // Through undirectedView each pair is one arc, so the code lengths match.
        let arcs = AdjacencyList(vertices: 0 ..< 9, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
        #expect(abs(arcs.codeLength(of: first.map(Array.init)) - list.codeLength(of: first)) <= 1e-12)
        var c = SeededRandomNumberGenerator(seed: 6)
        #expect(arcs.infomapCommunities(using: &c).map(Array.init) == [[0, 1, 2], [3, 4, 5], [6, 7, 8]])
        let names = UndirectedAdjacencyList(vertices: (0 ..< 9).map { "v\($0)" }, edges: pairs.map { UndirectedEdge("v\($0.0)", "v\($0.1)") })
        var d = SeededRandomNumberGenerator(seed: 7)
        let named = names.infomapCommunities(using: &d)
        #expect(named.map(Array.init) == [["v0", "v1", "v2"], ["v3", "v4", "v5"], ["v6", "v7", "v8"]])
        #expect(named.community(of: "v7") == 2)
    }

    @Test("Seeded runs on planted blocks reach these code lengths; each step of the search is needed to get there")
    func seededDraws() {
        // Graphs of planted blocks, seeds and code lengths found by this implementation (3 trials);
        // a search missing one of its steps stops longer on the case noted.
        let cases: [(seed: UInt, vertexCount: Int, length: Double, edges: [(Int, Int)])] = [
            // 1 trial or fine tuning alone stops longer
            (114, 15, 3.296225677415, [(8, 3), (10, 9), (9, 7), (1, 4), (5, 6), (0, 2), (3, 14), (13, 12), (3, 0), (8, 11), (12, 4), (9, 11), (0, 1), (14, 13), (7, 13), (13, 11), (12, 11), (3, 2)]),
            // no move to an empty module stops longer
            (109, 20, 3.306132517761, [(14, 10), (18, 5), (0, 4), (15, 17), (6, 8), (7, 13), (10, 13), (19, 16), (1, 4), (7, 5), (3, 0), (3, 1), (7, 8), (0, 2), (6, 5), (12, 11), (12, 13), (9, 5), (8, 18), (14, 11), (8, 9), (1, 0), (6, 4), (6, 13), (18, 19), (5, 12)]),
            // without merging modules into nodes
            (125, 15, 3.629588762172, [(12, 0), (12, 6), (1, 3), (8, 7), (14, 10), (2, 0), (3, 11), (5, 7), (11, 10), (14, 1), (11, 12), (12, 10), (2, 1), (0, 4), (11, 13), (14, 6), (10, 13), (6, 7), (3, 5), (2, 10), (8, 9)]),
            // after one sweep
            (111, 25, 4.375973883669, [(24, 23), (9, 22), (11, 12), (20, 23), (16, 18), (21, 23), (0, 1), (18, 5), (9, 5), (7, 3), (19, 17), (19, 3), (11, 10), (20, 2), (14, 12), (8, 7), (9, 6), (10, 13), (19, 21), (5, 23), (23, 6), (2, 1), (0, 7), (14, 22), (17, 16), (14, 11), (6, 20), (20, 10), (0, 2), (6, 8), (10, 2), (17, 15), (5, 8), (10, 14), (8, 2), (9, 7), (21, 24), (13, 1), (11, 13), (10, 12), (21, 20), (24, 12), (14, 2), (3, 4), (24, 16), (17, 6), (24, 11), (15, 22), (4, 0), (20, 3), (3, 2)]),
            // submodules started in their own modules
            (104, 35, 3.022470650647, [(6, 3), (1, 13), (17, 15), (5, 2), (4, 2), (19, 10), (17, 22), (30, 34), (32, 28), (4, 22), (0, 1), (13, 9), (0, 6), (29, 30), (23, 21), (24, 25), (34, 32), (34, 33), (17, 19), (22, 11), (19, 16), (12, 7), (1, 15), (14, 20), (13, 12), (25, 1), (0, 4), (18, 15), (23, 26), (31, 28), (12, 8)]),
            // with self-loops: submodules found without the loops' flow
            (97, 21, 3.615048846336, [(5, 0), (12, 13), (4, 3), (6, 1), (14, 16), (6, 11), (2, 4), (14, 17), (17, 16), (3, 0), (7, 11), (14, 20), (10, 16), (14, 5), (0, 2), (8, 13), (9, 11), (17, 5), (7, 14), (8, 12), (13, 10), (14, 6), (1, 2), (9, 10), (15, 13), (13, 4), (19, 15), (8, 17), (5, 2), (0, 4), (11, 12), (0, 1), (11, 13), (5, 1), (20, 15), (11, 11), (1, 1), (15, 15), (10, 10), (12, 12), (6, 6)]),
        ]
        for c in cases {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< c.vertexCount, edges: c.edges.map { UndirectedEdge($0.0, $0.1) })
            var generator = SeededRandomNumberGenerator(seed: c.seed)
            let result = graph.infomapCommunities(trials: 3, using: &generator)
            #expect(graph.codeLength(of: result) <= c.length + 1e-9, "seed \(c.seed)")
        }
    }

    @Test("Exits: no trials, a negative weight, a vertex not in the graph, a vertex listed twice")
    func traps() async {
        await #expect(processExitsWith: .failure) {
            var generator = SeededRandomNumberGenerator(seed: 0)
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).infomapCommunities(trials: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = SeededRandomNumberGenerator(seed: 0)
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).infomapCommunities(weight: { _ in -1.0 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).codeLength(of: [[0, 1, 2]])
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).codeLength(of: [[0, 1], [1]])
        }
    }

    @Test("codeLength(of:) is the map equation over the edges; Infomap is no longer than every vertex alone or one module", .tags(.randomized))
    func againstFormula() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 30)
        await propertyCheck(count: 200, input: Gen.int(in: 1 ... 10), edges, Gen.int(in: 0 ... 1000)) { n, raw, seed in
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let labels = (0 ..< n).map { ($0 * 7 + seed) % 3 }
            let grouping = (0 ..< 3).map { c in (0 ..< n).filter { labels[$0] == c } }
            func f(_ x: Double) -> Double { x > 0 ? x * log2(x) : 0 }
            func length(_ labels: [Int]) -> Double {
                let total = Double(pairs.count)
                guard total > 0 else { return 0 }
                let k = max(n, 3)
                var p = [Double](repeating: 0, count: n), q = [Double](repeating: 0, count: k), size = [Double](repeating: 0, count: k)
                for (u, v) in pairs {
                    p[u] += 1 / (2 * total)
                    p[v] += 1 / (2 * total)
                    if labels[u] != labels[v] {
                        q[labels[u]] += 1 / (2 * total)
                        q[labels[v]] += 1 / (2 * total)
                    }
                }
                for v in 0 ..< n { size[labels[v]] += p[v] }
                return f(q.reduce(0, +)) - 2 * q.map(f).reduce(0, +) - p.map(f).reduce(0, +) + (0 ..< k).map { f(q[$0] + size[$0]) }.reduce(0, +)
            }
            #expect(abs(graph.codeLength(of: grouping) - length(labels)) <= 1e-9, "\(pairs)")
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let result = graph.infomapCommunities(trials: 2, using: &generator)
            let found = graph.codeLength(of: result)
            #expect(found <= length(Array(0 ..< n)) + 1e-9, "\(pairs)")
            #expect(found <= length([Int](repeating: 0, count: n)) + 1e-9, "\(pairs)")
            #expect(abs(found - length((0 ..< n).map { result.community(of: $0) })) <= 1e-9)
        }
    }
}
