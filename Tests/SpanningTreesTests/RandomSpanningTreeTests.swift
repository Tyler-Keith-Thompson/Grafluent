// Random spanning trees by Wilson's algorithm: every result is a spanning forest; the draws are
// uniform over the spanning trees (K4's 16, a multigraph's trees told apart by position) or
// proportional to the product of the weights, by a chi-square bound over many seeded draws; the
// same seed gives the same tree; disconnected graphs give one tree per component. Case IDs (ST-nn)
// refer to the catalog; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import SpanningTrees
import Testing
import Trees

@Suite("Random spanning trees")
struct RandomSpanningTreeTests {
    @Test("ST-240 the trivial graphs: no vertices, one vertex, a self-loop")
    func trivial() {
        var rng = SeededRandomNumberGenerator(seed: 170)
        let empty = UndirectedAdjacencyList<Int>()
        #expect(empty.randomSpanningTree(using: &rng).edges == [])
        #expect(empty.randomSpanningTree(using: &rng).weight == 0)
        let loop = ReferencePseudograph(vertices: [0], edges: [UndirectedEdge(0, 0)])
        var asked = 0
        let forest = loop.randomSpanningTree(weight: { _ in
            asked += 1
            return 2.0
        }, using: &rng)
        #expect(forest.edges == [])
        #expect(forest.weight == 0)
        #expect(asked == 0)
        let edge = UndirectedAdjacencyList(edges: [UndirectedEdge("a", "b")])
        #expect(edge.randomSpanningTree(using: &rng).edges == [0])
        #expect(edge.randomSpanningTree(weight: { _ in 0.5 }, using: &rng).weight == 0.5)
    }

    @Test("ST-241 K4: each of its 16 spanning trees about equally often")
    func uniformOnK4() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        var rng = SeededRandomNumberGenerator(seed: 171)
        var counts: [Set<Int>: Int] = [:]
        let draws = 32_000
        for _ in 0 ..< draws {
            let tree = graph.randomSpanningTree(using: &rng)
            #expect(tree.edges.count == 3)
            #expect(tree.weight == 3)
            counts[Set(tree.edges), default: 0] += 1
        }
        #expect(counts.count == 16)
        // Chi-square with 15 degrees of freedom: the 0.9999 quantile is about 44.3.
        let expected = Double(draws) / 16
        let chiSquare = counts.values.reduce(0.0) { $0 + (Double($1) - expected) * (Double($1) - expected) / expected }
        #expect(chiSquare < 44.3, "\(counts)")
    }

    @Test("ST-242 parallel edges are distinct edges: a doubled triangle edge is in twice as many trees")
    func uniformOnMultigraph() {
        // Triangle 0–1, 1–2, 2–0 with 0–1 doubled: trees are any 2 of the 3 sides, with either copy
        // of 0–1: {a, 1–2}, {b, 1–2}, {a, 2–0}, {b, 2–0}, {1–2, 2–0}: 5 trees.
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        var rng = SeededRandomNumberGenerator(seed: 172)
        var counts: [[Int]: Int] = [:]
        let draws = 25_000
        for _ in 0 ..< draws { counts[graph.randomSpanningTree(using: &rng).edges.sorted(), default: 0] += 1 }
        #expect(Set(counts.keys) == [[0, 2], [1, 2], [0, 3], [1, 3], [2, 3]])
        let expected = Double(draws) / 5
        // 4 degrees of freedom: the 0.9999 quantile is about 23.5.
        let chiSquare = counts.values.reduce(0.0) { $0 + (Double($1) - expected) * (Double($1) - expected) / expected }
        #expect(chiSquare < 23.5, "\(counts)")
    }

    @Test("ST-243 weighted: each tree in proportion to the product of its weights")
    func proportionalToProduct() {
        // A 4-cycle 0–1–2–3–0 plus the chord 0–2, weights 1, 2, 3, 4 and 0.5.
        let edges: [(Int, Int, Double)] = [(0, 1, 1), (1, 2, 2), (2, 3, 3), (3, 0, 4), (0, 2, 0.5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        // Every 3-edge subset that is a tree, with its product.
        var products: [Set<Int>: Double] = [:]
        for a in 0 ..< 5 {
            for b in a + 1 ..< 5 {
                for c in b + 1 ..< 5 {
                    var parent = Array(0 ..< 4)
                    func find(_ x: Int) -> Int {
                        var x = x
                        while parent[x] != x { x = parent[x] }
                        return x
                    }
                    var acyclic = true
                    for k in [a, b, c] {
                        let (ru, rv) = (find(edges[k].0), find(edges[k].1))
                        if ru == rv { acyclic = false } else { parent[ru] = rv }
                    }
                    if acyclic { products[[a, b, c]] = edges[a].2 * edges[b].2 * edges[c].2 }
                }
            }
        }
        #expect(products.count == 8)
        let sum = products.values.reduce(0, +)
        var rng = SeededRandomNumberGenerator(seed: 173)
        var counts: [Set<Int>: Int] = [:]
        let draws = 40_000
        for _ in 0 ..< draws {
            let tree = graph.randomSpanningTree(weight: { edges[$0].2 }, using: &rng)
            #expect(tree.weight == tree.edges.reduce(0) { $0 + edges[$1].2 })
            counts[Set(tree.edges), default: 0] += 1
        }
        #expect(Set(counts.keys).isSubset(of: Set(products.keys)))
        // 7 degrees of freedom: the 0.9999 quantile is about 29.9.
        var chiSquare = 0.0
        for (tree, product) in products {
            let expected = Double(draws) * product / sum
            let observed = Double(counts[tree] ?? 0)
            chiSquare += (observed - expected) * (observed - expected) / expected
        }
        #expect(chiSquare < 29.9, "\(counts)")
    }

    @Test("ST-244 the same seed gives the same tree; the forest spans every component")
    func reproducibleForest() {
        // Two triangles and an isolated vertex.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        var a = SeededRandomNumberGenerator(seed: 174)
        var b = SeededRandomNumberGenerator(seed: 174)
        for _ in 0 ..< 50 {
            let first = graph.randomSpanningTree(using: &a)
            let second = graph.randomSpanningTree(using: &b)
            #expect(first == second)
            #expect(first.edges.count == 4)
            let forest = Forest(first, in: graph)
            #expect(forest.vertexCount == 7)
            #expect(forest.edgeCount == 4)
        }
        var c = SeededRandomNumberGenerator(seed: 175)
        var d = SeededRandomNumberGenerator(seed: 175)
        let third = graph.randomSpanningTree(weight: { _ in 1.5 }, using: &c)
        let fourth = graph.randomSpanningTree(weight: { _ in 1.5 }, using: &d)
        #expect(third == fourth)
    }

    @Test("ST-245 a zero, negative, infinite or NaN weight traps", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            var rng = SeededRandomNumberGenerator(seed: 1)
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).randomSpanningTree(weight: { _ in 0.0 }, using: &rng)
        }
        await #expect(processExitsWith: .failure) {
            var rng = SeededRandomNumberGenerator(seed: 1)
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).randomSpanningTree(weight: { _ in -1.0 }, using: &rng)
        }
        await #expect(processExitsWith: .failure) {
            var rng = SeededRandomNumberGenerator(seed: 1)
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).randomSpanningTree(weight: { _ in Double.infinity }, using: &rng)
        }
        await #expect(processExitsWith: .failure) {
            var rng = SeededRandomNumberGenerator(seed: 1)
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).randomSpanningTree(weight: { _ in Float.nan }, using: &rng)
        }
    }
}

@Suite("Random spanning tree properties", .tags(.randomized))
struct RandomSpanningTreePropertyTests {
    @Test("ST-246 every draw is a spanning forest of the graph: n − c edges, acyclic, no self-loop, within components")
    func forestLaws() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: edges) { raw in
            let n = 8
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for e in raw { parent[find(e.0)] = find(e.1) }
            let components = Set((0 ..< n).map(find)).count
            var rng = SeededRandomNumberGenerator(seed: UInt(raw.count))
            for tree in [graph.randomSpanningTree(using: &rng).edges, graph.randomSpanningTree(weight: { Double($0 % 3 + 1) }, using: &rng).edges] {
                #expect(tree.count == n - components)
                var forestParent = Array(0 ..< n)
                func forestFind(_ x: Int) -> Int {
                    var x = x
                    while forestParent[x] != x { x = forestParent[x] }
                    return x
                }
                for k in tree {
                    #expect(raw[k].0 != raw[k].1)
                    #expect(forestFind(raw[k].0) != forestFind(raw[k].1))
                    forestParent[forestFind(raw[k].0)] = forestFind(raw[k].1)
                }
            }
        }
    }
}
