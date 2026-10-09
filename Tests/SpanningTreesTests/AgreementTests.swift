// The algorithms against each other and against oracles written in each test: the catalog's
// Int-weighted cases under every algorithm, tie-heavy random multigraphs against a stable-sort
// Kruskal and brute force, JGraphT's random G(200, 0.5) instances, igraph's multigraphs with
// loops, Prim's root, and a path that makes Borůvka run many rounds. Case IDs (ST-nn) refer to the
// catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import SpanningTrees
import Testing

@Suite("Agreement between the algorithms")
struct AgreementTests {
    @Test("ST-70 every Int-weighted catalog case under every algorithm (NetworkX MinimumSpanningTreeTestBase)")
    func everyCaseEveryAlgorithm() {
        // (case, vertices, edges, the canonical forest, whether the optimum is unique). Letters
        // are numbered in order: A = 0, B = 1, ….
        let cases: [(String, [Int], [(Int, Int, Int)], [Int], Bool)] = [
            ("ST-02", [0], [], [], true),
            ("ST-04", Array(0 ..< 7), [(0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11)], [1, 5, 7, 0, 4, 9], true),
            ("ST-06", Array(0 ..< 6), [(0, 1, 2), (0, 3, 4), (1, 2, 1), (1, 5, 7), (2, 4, 5), (4, 5, 1), (3, 4, 1)], [2, 5, 6, 0, 1], true),
            ("ST-07", Array(0 ..< 5), [(0, 1, 2), (0, 2, 3), (1, 3, 5), (2, 3, 20), (3, 4, 5), (0, 4, 100)], [0, 1, 2, 4], true),
            ("ST-08", Array(0 ..< 5), [(0, 1, 2), (0, 3, 1), (1, 2, 3), (1, 3, 2), (2, 3, 5), (2, 4, 4), (3, 4, 6)], [1, 0, 2, 5], false),
            ("ST-09", Array(0 ..< 5), [(0, 1, 2), (0, 3, 1), (1, 2, 3), (1, 3, 2), (2, 4, 4), (3, 4, 6)], [1, 0, 2, 4], false),
            ("ST-10", Array(0 ..< 5), [(0, 2, 1), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1)], [0, 1, 5, 6], true),
            ("ST-11", Array(0 ..< 6), [(0, 1, 2), (0, 2, 2), (1, 2, 2), (2, 1, 2), (1, 3, 2), (3, 2, 2), (2, 4, 2), (4, 3, 2), (3, 5, 2), (4, 5, 2)], [0, 1, 4, 6, 8], false),
            ("ST-12", Array(0 ..< 6), [(0, 1, -10), (0, 2, -9), (1, 2, -8), (2, 1, -7), (1, 3, -6), (3, 2, -5), (2, 4, -4), (4, 3, -3), (3, 5, -2), (4, 5, -1)], [0, 1, 4, 6, 8], true),
            ("ST-17", [1, 2, 3], [(1, 2, 1), (2, 3, 1), (1, 3, 10)], [0, 1], true),
            ("ST-18", Array(0 ..< 5), [(0, 1, 5), (1, 2, 4), (1, 4, 6), (2, 3, 5), (2, 4, 7), (3, 4, 3)], [5, 1, 0, 3], true),
            ("ST-25", Array(0 ..< 3), [(0, 1, 1), (1, 2, 1), (0, 2, 1)], [0, 1], false),
            ("ST-26", Array(0 ..< 4), [(0, 1, 1), (0, 2, 1), (0, 3, 1), (1, 2, 1), (1, 3, 1), (2, 3, 1)], [0, 1, 2], false),
            ("ST-27", Array(0 ..< 5), [(0, 2, 1), (1, 3, 1), (1, 4, 2), (2, 1, 7), (2, 3, 3), (3, 4, 1), (4, 0, 1), (4, 1, 1)], [0, 1, 5, 6], false),
            ("ST-28", Array(0 ..< 2), [(0, 1, 2), (0, 1, 1)], [1], true),
            ("ST-29", [1, 2, 3], [(1, 2, 2), (1, 2, 3), (3, 2, 2), (3, 1, 4)], [0, 2], true),
            ("ST-30", Array(0 ..< 2), [(0, 1, 3), (0, 1, 3)], [0], false),
            ("ST-31", Array(0 ..< 2), [(0, 0, -100), (0, 1, 5), (1, 1, -1)], [1], true),
            ("ST-32", [0], [(0, 0, 4)], [], true),
            ("ST-33", Array(0 ..< 4), [(0, 1, 0), (1, 2, 0), (2, 3, 0), (3, 0, 0), (0, 2, 0)], [0, 1, 2], false),
            ("ST-34", Array(0 ..< 3), [(0, 2, 1), (1, 2, 1), (0, 1, 1)], [0, 1], false),
            ("ST-35", Array(0 ..< 4), [(0, 1, 7), (0, 2, 1), (1, 2, 1)], [1, 2], true),
            ("ST-36", Array(0 ..< 5), [(0, 1, 5), (0, 1, 10), (1, 2, 4), (1, 2, 8), (1, 4, 6), (1, 4, 12), (2, 3, 5), (2, 3, 10), (2, 4, 7), (2, 4, 14), (3, 4, 3), (3, 4, 6)], [10, 2, 0, 6], true),
            ("ST-40", Array(0 ..< 4), [(0, 1, 1), (2, 3, 2)], [0, 1], true),
            ("ST-41", Array(0 ..< 3), [], [], true),
            ("ST-42", [1, 2, 3, 4, 5, 6, 7, 0], [(1, 2, 7), (1, 4, 5), (2, 3, 8), (2, 4, 9), (2, 5, 7), (3, 5, 5), (4, 5, 15), (4, 6, 6), (5, 6, 8), (5, 7, 9), (6, 7, 11)], [1, 5, 7, 0, 4, 9], true),
            ("ST-43", Array(0 ..< 10), [(0, 1, 7), (0, 3, 5), (3, 1, 9), (1, 2, 8), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (5, 4, 8), (5, 6, 11), (4, 6, 9), (7, 8, 1), (7, 9, 3), (8, 9, 1)], [11, 13, 1, 5, 7, 0, 4, 10], true),
            ("ST-44", Array(0 ..< 8), [(0, 1, 5), (0, 2, 10), (1, 3, 15), (2, 3, 20), (4, 5, 20), (4, 6, 15), (6, 7, 10), (5, 7, 5)], [0, 7, 1, 6, 2, 5], true),
            ("ST-45", Array(0 ..< 5), [(0, 1, 1), (2, 3, 8), (2, 4, 5), (3, 4, 1)], [0, 3, 2], true),
            ("ST-46", Array(0 ..< 7), [], [], true),
            ("ST-47", Array(0 ..< 6), [(0, 1, 1), (1, 2, 2), (0, 2, 3), (3, 4, 5)], [0, 1, 3], true),
            ("ST-50", Array(0 ..< 3), [(0, 1, -1), (1, 2, -2), (0, 2, -3)], [2, 1], true),
            ("ST-51", [1, 2, 3], [(1, 2, 1), (1, 3, -1), (2, 3, -2)], [2, 1], true),
        ]
        for (id, vertices, edges, canonical, unique) in cases {
            let graph = ReferencePseudograph(vertices: vertices, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let weight = canonical.reduce(0) { $0 + edges[$1].2 }
            let tree = graph.minimumSpanningTree { edges[$0].2 }
            #expect(tree.edges == canonical, "\(id)")
            #expect(tree.weight == weight, "\(id)")
            #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree, "\(id)")
            let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
            #expect(boruvka.edges.count == canonical.count, "\(id)")
            #expect(Set(boruvka.edges) == Set(canonical), "\(id)")
            #expect(boruvka.weight == weight, "\(id)")
            let prim = graph.primMinimumSpanningTree { edges[$0].2 }
            #expect(prim.edges.count == canonical.count, "\(id)")
            #expect(prim.weight == weight, "\(id)")
            if unique {
                #expect(Set(prim.edges) == Set(canonical), "\(id)")
            }
        }
    }

    @Test("ST-71 tie-heavy random multigraphs: the canonical forest, Borůvka's set, Prim's weight and brute force agree", .tags(.randomized), arguments: [0, 1, 2, 3, 10, 1000])
    func randomMultigraphs(k: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(71_000 + k))
        var bruteForced = 0
        for _ in 0 ..< 70 {
            let n = Int.random(in: 0 ... 12, using: &rng)
            let m = n == 0 ? 0 : Int.random(in: 0 ... 3 * n, using: &rng)
            // Self-loops and parallel edges happen by chance.
            let raw = (0 ..< m).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: -k ... k, using: &rng)) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })

            // Kruskal with a stable sort: ties in position order, both ways.
            func kruskal(maximum: Bool) -> [Int] {
                let order = raw.indices.filter { raw[$0].0 != raw[$0].1 }.sorted {
                    raw[$0].2 != raw[$1].2 ? (raw[$0].2 < raw[$1].2) != maximum : $0 < $1
                }
                var parent = Array(0 ..< n)
                func find(_ x: Int) -> Int {
                    var x = x
                    while parent[x] != x { x = parent[x] }
                    return x
                }
                var taken: [Int] = []
                for p in order {
                    let (ru, rv) = (find(raw[p].0), find(raw[p].1))
                    if ru != rv {
                        parent[ru] = rv
                        taken.append(p)
                    }
                }
                return taken
            }
            let minimum = kruskal(maximum: false)
            let maximum = kruskal(maximum: true)
            let minimumWeight = minimum.reduce(0) { $0 + raw[$1].2 }
            let maximumWeight = maximum.reduce(0) { $0 + raw[$1].2 }

            let tree = graph.minimumSpanningTree { raw[$0].2 }
            #expect(tree.edges == minimum, "\(raw)")
            #expect(tree.weight == minimumWeight, "\(raw)")
            #expect(graph.kruskalMinimumSpanningTree { raw[$0].2 } == tree, "\(raw)")
            let boruvka = graph.boruvkaMinimumSpanningTree { raw[$0].2 }
            #expect(boruvka.edges.count == minimum.count, "\(raw)")
            #expect(Set(boruvka.edges) == Set(minimum), "\(raw)")
            #expect(boruvka.weight == minimumWeight, "\(raw)")
            let prim = graph.primMinimumSpanningTree { raw[$0].2 }
            #expect(prim.edges.count == minimum.count, "\(raw)")
            #expect(prim.weight == minimumWeight, "\(raw)")
            let heaviest = graph.maximumSpanningTree { raw[$0].2 }
            #expect(heaviest.edges == maximum, "\(raw)")
            #expect(heaviest.weight == maximumWeight, "\(raw)")

            // Brute force: every set of `minimum.count` non-loop edges that is a forest.
            let candidates = raw.indices.filter { raw[$0].0 != raw[$0].1 }
            guard candidates.count <= 14 else { continue }
            bruteForced += 1
            var lightest: Int?
            var heaviestTotal: Int?
            var chosen: [Int] = []
            func extend(from start: Int) {
                if chosen.count == minimum.count {
                    var parent = Array(0 ..< n)
                    func find(_ x: Int) -> Int {
                        var x = x
                        while parent[x] != x { x = parent[x] }
                        return x
                    }
                    for p in chosen {
                        let (ru, rv) = (find(raw[p].0), find(raw[p].1))
                        if ru == rv { return }
                        parent[ru] = rv
                    }
                    let total = chosen.reduce(0) { $0 + raw[$1].2 }
                    lightest = min(lightest ?? total, total)
                    heaviestTotal = max(heaviestTotal ?? total, total)
                    return
                }
                guard start < candidates.count else { return }
                for i in start ..< candidates.count {
                    chosen.append(candidates[i])
                    extend(from: i + 1)
                    chosen.removeLast()
                }
            }
            extend(from: 0)
            #expect(lightest == minimumWeight, "\(raw)")
            #expect(heaviestTotal == maximumWeight, "\(raw)")
        }
        #expect(bruteForced > 0)
    }

    @Test("ST-72 JGraphT's testRandomInstances: G(200, 0.5) with random Doubles, identical edge sets", .tags(.randomized), arguments: 0 ..< 10)
    func randomDense(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(72_000 + seed))
        var edges: [(Int, Int, Double)] = []
        for u in 0 ..< 200 {
            for v in u + 1 ..< 200 where Double.random(in: 0 ..< 1, using: &rng) < 0.5 {
                edges.append((u, v, Double.random(in: 0 ..< 1, using: &rng)))
            }
        }
        let graph = ReferencePseudograph(vertices: 0 ..< 200, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        // Distinct weights make the forest unique; the Double totals may differ in the last ulp, so
        // compare edge sets.
        let kruskal = graph.kruskalMinimumSpanningTree { edges[$0].2 }
        #expect(kruskal.edges.count == 199)
        #expect(graph.minimumSpanningTree { edges[$0].2 } == kruskal)
        #expect(Set(graph.boruvkaMinimumSpanningTree { edges[$0].2 }.edges) == Set(kruskal.edges))
        #expect(Set(graph.primMinimumSpanningTree { edges[$0].2 }.edges) == Set(kruskal.edges))
        #expect(Set(graph.primMinimumSpanningTree(from: 199) { edges[$0].2 }.edges) == Set(kruskal.edges))
        #expect(abs(graph.primMinimumSpanningTree { edges[$0].2 }.weight - kruskal.weight) < 1e-9)
    }

    @Test("ST-73 igraph's G(50, 100) multigraphs with loops: forests of n − c edges and equal weights", .tags(.randomized), arguments: 0 ..< 20)
    func igraphMultigraphs(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(73_000 + seed))
        let n = 50
        let raw = (0 ..< 100).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: 1 ... 20, using: &rng)) }
        let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
        var parent = Array(0 ..< n)
        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        // c by union–find over every edge; and the first forest in position order.
        var firstForest: [Int] = []
        for (p, edge) in raw.enumerated() {
            let (ru, rv) = (find(edge.0), find(edge.1))
            if ru != rv {
                parent[ru] = rv
                firstForest.append(p)
            }
        }
        let components = (0 ..< n).filter { find($0) == $0 }.count
        let forests = [
            ("default", graph.minimumSpanningTree { raw[$0].2 }.edges),
            ("Kruskal", graph.kruskalMinimumSpanningTree { raw[$0].2 }.edges),
            ("Prim", graph.primMinimumSpanningTree { raw[$0].2 }.edges),
            ("Borůvka", graph.boruvkaMinimumSpanningTree { raw[$0].2 }.edges),
            ("maximum", graph.maximumSpanningTree { raw[$0].2 }.edges),
            ("unweighted", graph.minimumSpanningTree().edges),
        ]
        for (name, forest) in forests {
            #expect(forest.count == n - components, "\(name)")
            var forestParent = Array(0 ..< n)
            func forestFind(_ x: Int) -> Int {
                var x = x
                while forestParent[x] != x { x = forestParent[x] }
                return x
            }
            for p in forest {
                let (ru, rv) = (forestFind(raw[p].0), forestFind(raw[p].1))
                #expect(ru != rv, "\(name): position \(p) closes a cycle")
                forestParent[ru] = rv
            }
        }
        let weight = graph.kruskalMinimumSpanningTree { raw[$0].2 }.weight
        #expect(graph.primMinimumSpanningTree { raw[$0].2 }.weight == weight)
        #expect(graph.boruvkaMinimumSpanningTree { raw[$0].2 }.weight == weight)
        #expect(graph.minimumSpanningTree { raw[$0].2 }.weight == weight)
        #expect(graph.minimumSpanningTree().edges == firstForest)
        #expect(graph.minimumSpanningTree().weight == n - components)
    }

    @Test("ST-74 Prim's root does not matter within a component")
    func primRootIndependence() {
        let wiki: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        let wikiGraph = ReferencePseudograph(vertices: 0 ..< 7, edges: wiki.map { UndirectedEdge($0.0, $0.1) })
        for root in 0 ..< 7 {
            let tree = wikiGraph.primMinimumSpanningTree(from: root) { wiki[$0].2 }
            #expect(Set(tree.edges) == [1, 5, 7, 0, 4, 9], "from \(root)")
            #expect(tree.weight == 39, "from \(root)")
        }

        let doubled: [(Int, Int, Int)] = [
            (0, 1, 5), (0, 1, 10), (1, 2, 4), (1, 2, 8), (1, 4, 6), (1, 4, 12), (2, 3, 5), (2, 3, 10), (2, 4, 7), (2, 4, 14), (3, 4, 3), (3, 4, 6),
        ]
        let doubledGraph = ReferencePseudograph(vertices: 0 ..< 5, edges: doubled.map { UndirectedEdge($0.0, $0.1) })
        for root in 0 ..< 5 {
            let tree = doubledGraph.primMinimumSpanningTree(from: root) { doubled[$0].2 }
            #expect(Set(tree.edges) == [10, 2, 0, 6], "from \(root)")
            #expect(tree.weight == 17, "from \(root)")
        }

        let petgraph: [(String, String, Int)] = [
            ("A", "B", 7), ("A", "D", 5), ("D", "B", 9), ("B", "C", 8), ("B", "E", 7), ("C", "E", 5), ("D", "E", 15), ("D", "F", 6),
            ("F", "E", 8), ("F", "G", 11), ("E", "G", 9), ("H", "I", 1), ("H", "J", 3), ("I", "J", 1),
        ]
        let petgraphGraph = ReferencePseudograph(vertices: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"], edges: petgraph.map { UndirectedEdge($0.0, $0.1) })
        for root in ["A", "B", "C", "D", "E", "F", "G"] {
            let tree = petgraphGraph.primMinimumSpanningTree(from: root) { petgraph[$0].2 }
            #expect(Set(tree.edges) == [1, 5, 7, 0, 4, 10], "from \(root)")
            #expect(tree.weight == 39, "from \(root)")
        }
        for root in ["H", "I", "J"] {
            let tree = petgraphGraph.primMinimumSpanningTree(from: root) { petgraph[$0].2 }
            #expect(Set(tree.edges) == [11, 13], "from \(root)")
            #expect(tree.weight == 2, "from \(root)")
        }
    }

    @Test("ST-75 a path of 2¹⁰ + 1 vertices with weights increasing along it: Borůvka ≡ Kruskal")
    func boruvkaRounds() {
        let n = 1025
        let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        // Edge k weighs k + 1, so every component's lightest edge is its left one.
        let total = (n - 1) * n / 2
        let kruskal = graph.kruskalMinimumSpanningTree { $0 + 1 }
        #expect(kruskal.edges == Array(0 ..< n - 1))
        #expect(kruskal.weight == total)
        let boruvka = graph.boruvkaMinimumSpanningTree { $0 + 1 }
        #expect(boruvka.edges.count == n - 1)
        #expect(Set(boruvka.edges) == Set(0 ..< n - 1))
        #expect(boruvka.weight == total)
        // On a path from its end, Prim has one choice at each step.
        let prim = graph.primMinimumSpanningTree { $0 + 1 }
        #expect(prim.edges == Array(0 ..< n - 1))
        #expect(prim.weight == total)
        #expect(graph.minimumSpanningTree { $0 + 1 } == kruskal)
        #expect(graph.maximumSpanningTree { $0 + 1 }.edges == Array((0 ..< n - 1).reversed()))
    }
}
