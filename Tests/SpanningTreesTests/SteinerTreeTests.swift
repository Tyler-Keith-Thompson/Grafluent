// Steiner trees by Mehlhorn's algorithm and by Kou, Markowsky and Berman's: NetworkX's examples,
// the trivial cases, two terminals (a shortest path), every vertex a terminal (a minimum spanning
// tree), disconnected terminals, parallel edges and self-loops, the checked spellings, the traps,
// and seeded random graphs against the exact optimum by brute force. Case IDs (ST-nn) refer to
// the catalog; see README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import SpanningTrees
import Testing

@Suite("Steiner trees")
struct SteinerTreeTests {
    @Test("ST-220 a detour through two non-terminals beats the direct path (NetworkX-style example)")
    func detour() {
        let edges: [(Int, Int, Int)] = [(1, 2, 10), (2, 3, 10), (3, 4, 10), (4, 5, 10), (5, 6, 10), (2, 7, 1), (7, 5, 1)]
        let graph = UndirectedAdjacencyList(edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let w: (Int) -> Int = { edges[$0].2 }
        for tree in [graph.steinerTree(terminals: [1, 3, 5], weight: w), graph.kouSteinerTree(terminals: [1, 3, 5], weight: w)] {
            #expect(tree?.edges == [0, 1, 5, 6])
            #expect(tree?.weight == 22)
        }
    }

    @Test("ST-221 NetworkX test_steinertree: G1, G2 and G3 with their terminals, both methods, NetworkX's weights", arguments: [0, 1, 2])
    func networkXGraphs(index: Int) {
        let g1: [(Int, Int, Int)] = [(1, 2, 10), (2, 3, 10), (3, 4, 10), (4, 5, 10), (5, 6, 10), (2, 7, 1), (7, 5, 1)]
        let g2: [(Int, Int, Int)] = [(0, 5, 6), (1, 2, 2), (1, 5, 3), (2, 4, 4), (3, 5, 5), (4, 5, 1)]
        let g3: [(Int, Int, Int)] = [
            (1, 2, 8), (1, 9, 3), (1, 8, 6), (1, 10, 2), (1, 14, 3), (2, 3, 6), (3, 4, 3), (3, 10, 2), (3, 11, 1), (4, 5, 1), (4, 11, 1),
            (5, 6, 4), (5, 11, 2), (5, 12, 1), (5, 13, 3), (6, 7, 2), (6, 12, 3), (6, 13, 1), (7, 8, 3), (7, 9, 3), (7, 11, 5), (7, 13, 2),
            (7, 14, 4), (8, 9, 2), (9, 14, 1), (10, 11, 2), (10, 14, 1), (11, 12, 1), (11, 14, 7), (12, 14, 3), (12, 15, 1), (13, 14, 4),
            (13, 15, 1), (14, 15, 2),
        ]
        let edges = [g1, g2, g3][index]
        let terminals = [[1, 2, 3, 4, 5], [0, 2, 3], [1, 3, 5, 6, 8, 10, 11, 12, 13]][index]
        let expected = [32, 16, 14][index]
        let graph = UndirectedAdjacencyList(edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let w: (Int) -> Int = { edges[$0].2 }
        for tree in [graph.steinerTree(terminals: terminals, weight: w), graph.kouSteinerTree(terminals: terminals, weight: w)] {
            #expect(tree?.weight == expected)
            #expect(tree.map { $0.edges.reduce(0) { $0 + edges[$1].2 } } == expected)
            let ends = Set(tree?.edges.flatMap { [edges[$0].0, edges[$0].1] } ?? [])
            #expect(ends.isSuperset(of: terminals))
            #expect(tree?.edges.count == ends.count - 1)
        }
    }

    @Test("ST-222 no terminals or one: the empty tree, of weight zero; repeats count once")
    func trivial() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var asked = 0
        let w: (Int) -> Int = { _ in
            asked += 1
            return 1
        }
        for terminals in [[], [1], [2, 2, 2]] {
            #expect(graph.steinerTree(terminals: terminals, weight: w)?.edges == [])
            #expect(graph.steinerTree(terminals: terminals, weight: w)?.weight == 0)
            #expect(graph.kouSteinerTree(terminals: terminals, weight: w)?.edges == [])
        }
        #expect(graph.steinerTree(terminals: [0, 2, 0], weight: w)?.edges == [0, 1])
        #expect(graph.kouSteinerTree(terminals: [2, 0, 2], weight: w)?.weight == 2)
        let empty = UndirectedAdjacencyList<Int>()
        #expect(empty.steinerTree(terminals: [], weight: w)?.edges == [])
        #expect(empty.kouSteinerTree(terminals: [], weight: w)?.weight == 0)
    }

    @Test("ST-223 terminals in different components: nil")
    func disconnected() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        #expect(graph.steinerTree(terminals: [0, 3]) { _ in 1 } == nil)
        #expect(graph.kouSteinerTree(terminals: [0, 3]) { _ in 1 } == nil)
        #expect(graph.steinerTree(terminals: [0, 1]) { _ in 1 }?.edges == [0])
        #expect(graph.kouSteinerTree(terminals: [2, 3]) { _ in 1 }?.edges == [1])
    }

    @Test("ST-224 parallel edges and self-loops: the lighter copy, and loops never weighed")
    func multigraph() {
        let edges: [(Int, Int, Int)] = [(0, 1, 4), (1, 1, 0), (1, 0, 2), (1, 2, 3), (2, 1, 3), (0, 0, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        var asked: [Int] = []
        let w: (Int) -> Int = {
            asked.append($0)
            return edges[$0].2
        }
        let mehlhorn = graph.steinerTree(terminals: [0, 2], weight: w)
        #expect(mehlhorn?.weight == 5)
        #expect(mehlhorn?.edges.first == 2)
        #expect(asked.sorted() == [0, 2, 3, 4])
        asked = []
        let kou = graph.kouSteinerTree(terminals: [0, 2], weight: w)
        #expect(kou?.weight == 5)
        #expect(kou?.edges.first == 2)
        #expect(asked.sorted() == [0, 2, 3, 4])
    }

    @Test("ST-225 zero weights; the result's leaves are terminals")
    func zeroWeights() {
        // A star with a zero-weight hub and a heavy ring.
        let edges: [(Int, Int, Int)] = [(0, 1, 0), (0, 2, 0), (0, 3, 0), (1, 2, 5), (2, 3, 5), (3, 1, 5), (0, 4, 0)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let w: (Int) -> Int = { edges[$0].2 }
        for tree in [graph.steinerTree(terminals: [1, 2, 3], weight: w)!, graph.kouSteinerTree(terminals: [1, 2, 3], weight: w)!] {
            #expect(tree.weight == 0)
            #expect(tree.edges == [0, 1, 2])
        }
    }

    @Test("ST-230 Kou–Markowsky–Berman: tied shortest paths from both sides close a cycle in the union, and the minimum spanning tree of the union with pruning (one leaf, then two in turn) decides the tree")
    func kouUnionCycle() {
        // A square x–p–y–q–x whose two routes from x to y both weigh 3. Searching from x, p comes
        // first and y is reached through p; searching from y, q comes first and x through q. Far
        // terminals on x's side (weight 10 each) and near ones on y's side make the distance tree
        // L1–R1, R1–R2, R1–L2, so both routes are in the union. The tree keeps x–q–y: Kruskal
        // drops p–y, the last edge of weight 2, and p is pruned.
        // Vertices: x 0, p 1, q 2, y 3, L1 4, L2 5, R1 6, R2 7.
        let square: [(Int, Int, Int)] = [(0, 1, 1), (2, 3, 1), (0, 2, 2), (1, 3, 2), (4, 0, 10), (5, 0, 10), (6, 3, 1), (7, 3, 1)]
        let first = ReferencePseudograph(vertices: 0 ..< 8, edges: square.map { UndirectedEdge($0.0, $0.1) })
        let kou = first.kouSteinerTree(terminals: [4, 5, 6, 7]) { square[$0].2 }
        #expect(kou?.edges == [1, 2, 4, 5, 6, 7])
        #expect(kou?.weight == 25)
        #expect(first.steinerTree(terminals: [4, 5, 6, 7]) { square[$0].2 }?.weight == 25)

        // Routes x–a–b–y (2, 2, 6) and x–c–y (5, 5), both 10: Kruskal drops b–y, then b and a are
        // pruned in turn. Vertices: x 0, a 1, b 2, c 3, y 4, L1 5, L2 6, R1 7, R2 8.
        let long: [(Int, Int, Int)] = [(0, 1, 2), (1, 2, 2), (2, 4, 6), (0, 3, 5), (3, 4, 5), (5, 0, 20), (6, 0, 20), (7, 4, 1), (8, 4, 1)]
        let second = ReferencePseudograph(vertices: 0 ..< 9, edges: long.map { UndirectedEdge($0.0, $0.1) })
        let pruned = second.kouSteinerTree(terminals: [5, 6, 7, 8]) { long[$0].2 }
        #expect(pruned?.edges == [3, 4, 5, 6, 7, 8])
        #expect(pruned?.weight == 52)
    }

    @Test("ST-226 checked spellings throw for a missing terminal and agree otherwise")
    func checked() throws {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        #expect(throws: VertexNotFound.self) { try graph.steinerTree(checkedTerminals: ["a", "z"]) { _ in 1 } }
        #expect(throws: VertexNotFound.self) { try graph.kouSteinerTree(checkedTerminals: ["z"]) { _ in 1 } }
        #expect(try graph.steinerTree(checkedTerminals: ["a", "c"]) { _ in 1 } == graph.steinerTree(terminals: ["a", "c"]) { _ in 1 })
        #expect(try graph.kouSteinerTree(checkedTerminals: ["a", "c"]) { _ in 1.5 }?.weight == 3)
    }

    @Test("ST-227 a missing terminal or a negative weight traps", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.steinerTree(terminals: [0, 7]) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.kouSteinerTree(terminals: [7]) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.steinerTree(terminals: [0, 1]) { _ in -1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.kouSteinerTree(terminals: [0, 1]) { _ in Double.nan }
        }
    }
}

@Suite("Steiner tree properties on random graphs", .tags(.randomized))
struct SteinerTreePropertyTests {
    @Test("ST-228 both are trees spanning the terminals with terminal leaves, within 2(1 − 1/t) of the brute-force optimum", arguments: [3, 5, 7])
    func bruteForce(n: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(158_000 + n))
        for _ in 0 ..< 120 {
            var raw: [(Int, Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 11, using: &rng) {
                raw.append((Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ... 9, using: &rng)))
            }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let terminals = Array(Set((0 ..< Int.random(in: 1 ... n, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) })).sorted()
            // Whether the edge set given by `mask` connects the terminals.
            func connects(_ mask: Int) -> Bool {
                var parent = Array(0 ..< n)
                func find(_ x: Int) -> Int {
                    var x = x
                    while parent[x] != x { x = parent[x] }
                    return x
                }
                for k in raw.indices where mask & (1 << k) != 0 { parent[find(raw[k].0)] = find(raw[k].1) }
                return terminals.allSatisfy { find($0) == find(terminals[0]) }
            }
            var optimum: Int?
            for mask in 0 ..< (1 << raw.count) where connects(mask) {
                let total = raw.indices.filter { mask & (1 << $0) != 0 }.reduce(0) { $0 + raw[$1].2 }
                optimum = min(optimum ?? total, total)
            }
            let t = terminals.count
            func check(_ tree: SteinerTree<ReferencePseudograph<Int>, Int>?, _ name: String) {
                guard let optimum else {
                    #expect(tree == nil, "\(name): \(raw) \(terminals)")
                    return
                }
                guard let tree else {
                    Issue.record("\(name) is nil: \(raw) \(terminals)")
                    return
                }
                #expect(tree.edges == tree.edges.sorted(), "\(name): \(raw)")
                #expect(tree.weight == tree.edges.reduce(0) { $0 + raw[$1].2 }, "\(name): \(raw)")
                #expect(tree.weight >= optimum, "\(name): \(raw) \(terminals)")
                // weight ≤ 2(1 − 1/t)·optimum, in integers.
                #expect(t * tree.weight <= 2 * (t - 1) * optimum || t < 2 && tree.weight == 0, "\(name): \(tree.weight) vs \(optimum): \(raw) \(terminals)")
                // A tree: no self-loop, acyclic, connected over its vertices, which include every
                // terminal, and every leaf a terminal.
                var parent = Array(0 ..< n)
                func find(_ x: Int) -> Int {
                    var x = x
                    while parent[x] != x { x = parent[x] }
                    return x
                }
                var degree = [Int](repeating: 0, count: n)
                for k in tree.edges {
                    #expect(raw[k].0 != raw[k].1, "\(name): \(raw)")
                    #expect(find(raw[k].0) != find(raw[k].1), "\(name) has a cycle: \(raw)")
                    parent[find(raw[k].0)] = find(raw[k].1)
                    degree[raw[k].0] += 1
                    degree[raw[k].1] += 1
                }
                let vertices = Set(tree.edges.flatMap { [raw[$0].0, raw[$0].1] }).union(terminals)
                #expect(Set(vertices.map(find)).count == 1, "\(name) is not connected: \(raw) \(terminals)")
                for v in vertices where degree[v] == 1 { #expect(terminals.contains(v), "\(name): leaf \(v): \(raw) \(terminals)") }
            }
            check(graph.steinerTree(terminals: terminals) { raw[$0].2 }, "Mehlhorn")
            check(graph.kouSteinerTree(terminals: terminals) { raw[$0].2 }, "Kou")
        }
    }

    @Test("ST-228b on seeded grids with tied distances: both are trees with terminal leaves, no heavier than the terminals' distance-graph minimum spanning tree", arguments: [4, 6, 8])
    func tiedGrids(side: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(228_000 + side))
        for _ in 0 ..< 60 {
            let n = side * side
            var raw: [(Int, Int, Int)] = []
            for v in 0 ..< n {
                if v % side + 1 < side { raw.append((v, v + 1, Int.random(in: 1 ... 3, using: &rng))) }
                if v + side < n { raw.append((v, v + side, Int.random(in: 1 ... 3, using: &rng))) }
                // A diagonal now and then, so paths cross.
                if v % side + 1 < side && v + side < n && Int.random(in: 0 ..< 3, using: &rng) == 0 {
                    raw.append((v, v + side + 1, Int.random(in: 2 ... 5, using: &rng)))
                }
            }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let terminals = Array(Set((0 ..< Int.random(in: 3 ... n / 2, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) })).sorted()
            // Floyd–Warshall, then Prim over the terminals' distances.
            var d = [[Int]](repeating: [Int](repeating: Int.max / 4, count: n), count: n)
            for v in 0 ..< n { d[v][v] = 0 }
            for e in raw {
                d[e.0][e.1] = min(d[e.0][e.1], e.2)
                d[e.1][e.0] = d[e.0][e.1]
            }
            for k in 0 ..< n {
                for i in 0 ..< n {
                    for j in 0 ..< n where d[i][k] + d[k][j] < d[i][j] { d[i][j] = d[i][k] + d[k][j] }
                }
            }
            var inTree = [Bool](repeating: false, count: terminals.count)
            var best = [Int](repeating: Int.max, count: terminals.count)
            best[0] = 0
            var bound = 0
            for _ in terminals.indices {
                let next = terminals.indices.filter { !inTree[$0] }.min { best[$0] < best[$1] }!
                inTree[next] = true
                bound += best[next]
                for j in terminals.indices where !inTree[j] { best[j] = min(best[j], d[terminals[next]][terminals[j]]) }
            }
            for (name, tree) in [("Mehlhorn", graph.steinerTree(terminals: terminals) { raw[$0].2 }!), ("Kou", graph.kouSteinerTree(terminals: terminals) { raw[$0].2 }!)] {
                #expect(tree.weight <= bound, "\(name): \(tree.weight) > \(bound): \(raw) \(terminals)")
                var degree = [Int](repeating: 0, count: n)
                for k in tree.edges {
                    degree[raw[k].0] += 1
                    degree[raw[k].1] += 1
                }
                #expect(tree.edges.count == degree.filter { $0 > 0 }.count - 1, "\(name) is not a tree: \(raw) \(terminals)")
                for v in 0 ..< n where degree[v] == 1 { #expect(terminals.contains(v), "\(name): leaf \(v): \(raw) \(terminals)") }
            }
        }
    }

    @Test("ST-229 two terminals: a shortest path; every vertex a terminal: a minimum spanning tree")
    func exactCases() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 5)).array(of: 0 ... 18)
        await propertyCheck(count: 300, input: edges) { raw in
            let n = 7
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            // Floyd–Warshall distances.
            var d = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for v in 0 ..< n { d[v][v] = 0 }
            for e in raw where e.0 != e.1 {
                d[e.0][e.1] = min(d[e.0][e.1] ?? .max, e.2)
                d[e.1][e.0] = d[e.0][e.1]
            }
            for k in 0 ..< n {
                for i in 0 ..< n {
                    for j in 0 ..< n {
                        if let a = d[i][k], let b = d[k][j], a + b < (d[i][j] ?? .max) { d[i][j] = a + b }
                    }
                }
            }
            let mehlhorn = graph.steinerTree(terminals: [0, 6]) { raw[$0].2 }
            let kou = graph.kouSteinerTree(terminals: [0, 6]) { raw[$0].2 }
            #expect(mehlhorn?.weight == d[0][6])
            #expect(kou?.weight == d[0][6])
            let mst = graph.minimumSpanningTree { raw[$0].2 }
            let connected = mst.edges.count == n - 1
            #expect(graph.steinerTree(terminals: 0 ..< n) { raw[$0].2 }?.weight == (connected ? mst.weight : nil))
            #expect(graph.kouSteinerTree(terminals: 0 ..< n) { raw[$0].2 }?.weight == (connected ? mst.weight : nil))
        }
    }
}
