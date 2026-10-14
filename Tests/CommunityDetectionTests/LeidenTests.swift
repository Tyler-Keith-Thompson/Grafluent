// Leiden (Traag, Waltman and van Eck 2019) and the constant Potts model: hand-computed cases on
// graphs where every seed gives the same partition, degenerate graphs, both quality functions,
// resolution, weights, parallel edges and self-loops, directed graphs, the karate club's best known
// modularity, `connectedComponents(within:)`, and the representations. Expected values are worked
// out in each test's comments.

import AdjacencyListModule
import CommunityDetection
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Leiden")
struct LeidenTests {
    @Test("Two triangles joined by an edge: the triangles, for every seed, both quality functions")
    func twoTriangles() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        for seed in 0 ..< 20 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let result = graph.leidenCommunities(using: &generator)
            #expect(result.map { Array($0) } == [[0, 1, 2], [3, 4, 5]], "seed \(seed)")
            #expect(result.community(of: 4) == 1)
            // H = Σ_c [e_c − γ n_c²/2]: at γ = ½ each triangle is 3 − 9/4 = ¾, the whole graph
            // 7 − 9 = −2, singletons −3/2.
            let cpm = graph.leidenCommunities(quality: .constantPottsModel, resolution: 0.5, using: &generator)
            #expect(cpm.map { Array($0) } == [[0, 1, 2], [3, 4, 5]], "seed \(seed)")
        }
        // Q = 2 (3/7 − (7/14)²) = 5/14.
        var generator = SeededRandomNumberGenerator(seed: 3)
        #expect(abs(graph.modularity(of: graph.leidenCommunities(using: &generator)) - 5.0 / 14) <= 1e-12)
    }

    @Test("The resolution: at γ = 0.1 the constant Potts model keeps the two triangles together (7 − 1.8 > 2 (3 − 0.45)); modularity at γ = 0 gives the component")
    func resolution() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        for seed in 0 ..< 10 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let cpm = graph.leidenCommunities(quality: .constantPottsModel, resolution: 0.1, using: &generator)
            #expect(cpm.map { Array($0) } == [[0, 1, 2, 3, 4, 5]], "seed \(seed)")
            let whole = graph.leidenCommunities(resolution: 0, using: &generator)
            #expect(whole.map { Array($0) } == [[0, 1, 2, 3, 4, 5]], "seed \(seed)")
            // At γ = 2 the constant Potts model is below zero for any community of two or more
            // vertices here (a triangle: 3 − 9; an edge: 1 − 4), so the singletons.
            let fine = graph.leidenCommunities(quality: .constantPottsModel, resolution: 2, using: &generator)
            #expect(fine.count == 6, "seed \(seed)")
        }
    }

    @Test("Two K₅ joined by an edge, and a ring of four K₄: the cliques")
    func cliques() {
        var pairs: [(Int, Int)] = []
        for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        for i in 5 ..< 10 { for j in i + 1 ..< 10 { pairs.append((i, j)) } }
        pairs.append((4, 5))
        let two = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var ring: [(Int, Int)] = []
        for c in 0 ..< 4 {
            for i in 0 ..< 4 { for j in i + 1 ..< 4 { ring.append((4 * c + i, 4 * c + j)) } }
            ring.append((4 * c + 3, 4 * ((c + 1) % 4)))
        }
        let rings = ReferencePseudograph(vertices: 0 ..< 16, edges: ring.map { UndirectedEdge($0.0, $0.1) })
        for seed in 0 ..< 10 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            #expect(two.leidenCommunities(using: &generator).map { Array($0) } == [Array(0 ..< 5), Array(5 ..< 10)], "seed \(seed)")
            #expect(rings.leidenCommunities(using: &generator).map { Array($0) } == (0 ..< 4).map { Array(4 * $0 ..< 4 * $0 + 4) }, "seed \(seed)")
            #expect(rings.leidenCommunities(quality: .constantPottsModel, resolution: 0.5, using: &generator).count == 4, "seed \(seed)")
        }
    }

    @Test("The karate club: the best known modularity, 0.4197896…, for every seed; four communities")
    func karate() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17),
            (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9),
            (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33),
            (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29),
            (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        for seed in 0 ..< 20 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let result = graph.leidenCommunities(using: &generator)
            // igraph's community_leiden finds the same value on every seed; it is the optimum
            // (Brandes et al. 2008).
            #expect(abs(graph.modularity(of: result) - 0.4197896120973044) <= 1e-9, "seed \(seed)")
            #expect(result.count == 4, "seed \(seed)")
        }
    }

    @Test("Degenerate graphs: no vertices, one vertex, no edges, self-loops only, K₂, all weights zero")
    func degenerate() {
        var generator = SeededRandomNumberGenerator(seed: 1)
        let empty = ReferencePseudograph<Int>(vertices: [], edges: [])
        #expect(empty.leidenCommunities(using: &generator).isEmpty)
        #expect(empty.leidenCommunities(quality: .constantPottsModel, using: &generator).isEmpty)
        let one = ReferencePseudograph<Int>(vertices: [0], edges: [])
        #expect(one.leidenCommunities(using: &generator).map { Array($0) } == [[0]])
        let edgeless = ReferencePseudograph<Int>(vertices: 0 ..< 4, edges: [])
        #expect(edgeless.leidenCommunities(using: &generator).map { Array($0) } == [[0], [1], [2], [3]])
        #expect(edgeless.leidenCommunities(quality: .constantPottsModel, resolution: 0, using: &generator).map { Array($0) } == [[0], [1], [2], [3]])
        // Loops count in degrees and inside their vertex's community, and never move a vertex.
        let loops = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 0), UndirectedEdge(1, 1)])
        #expect(loops.leidenCommunities(using: &generator).map { Array($0) } == [[0], [1]])
        #expect(loops.leidenCommunities(quality: .constantPottsModel, using: &generator).map { Array($0) } == [[0], [1]])
        // K₂: together Q = 1 − 1 = 0, apart Q = −½; the constant Potts model at γ = 1: 1 − 2 = −1
        // together, −1 apart, a tie, so the singletons stay.
        let k2 = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(k2.leidenCommunities(using: &generator).map { Array($0) } == [[0, 1]])
        #expect(k2.leidenCommunities(quality: .constantPottsModel, using: &generator).map { Array($0) } == [[0], [1]])
        #expect(k2.leidenCommunities(quality: .constantPottsModel, resolution: 0.5, using: &generator).map { Array($0) } == [[0, 1]])
        // Total weight zero: modularity is 0 for every partition, so the singletons.
        let path = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(path.leidenCommunities(weight: { _ in 0.0 }, using: &generator).map { Array($0) } == [[0], [1], [2]])
        #expect(path.leidenCommunities(weight: { _ in 0.0 }, quality: .constantPottsModel, resolution: 0, using: &generator).map { Array($0) } == [[0], [1], [2]])
    }

    @Test("Weights: a heavy bridge pulls its ends together; parallel copies are weight")
    func weights() {
        // Two triangles and the bridge 2-3 at weight 10: m = 16; {2, 3} and the two pairs.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1, 1, 1, 1, 1, 1, 10]
        // The same graph with the bridge as ten parallel copies.
        let copies = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) } + Array(repeating: UndirectedEdge(2, 3), count: 9))
        for seed in 0 ..< 10 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let weighted = graph.leidenCommunities(weight: { w[$0] }, using: &generator)
            let parallel = copies.leidenCommunities(using: &generator)
            #expect(weighted == parallel, "seed \(seed)")
            #expect(abs(graph.modularity(of: weighted, weight: { w[$0] }) - copies.modularity(of: parallel)) <= 1e-12)
            // Every single-vertex move from the result lowers Q (checked against modularity(of:)).
            let q = graph.modularity(of: weighted, weight: { w[$0] })
            let groups = weighted.map { Array($0) }
            for v in 0 ..< 6 {
                for target in 0 ... groups.count {
                    var moved = groups.map { $0.filter { $0 != v } }
                    if target == groups.count { moved.append([v]) } else { moved[target].append(v) }
                    #expect(graph.modularity(of: moved, weight: { w[$0] }) <= q + 1e-12, "seed \(seed), vertex \(v) to \(target)")
                }
            }
        }
    }

    @Test("Directed: two directed triangles joined by an arc (both quality functions), graph.directedView of an undirected graph")
    func directed() {
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        for seed in 0 ..< 10 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            #expect(graph.leidenCommunities(using: &generator).map { Array($0) } == [[0, 1, 2], [3, 4, 5]], "seed \(seed)")
            // Directed H = Σ_c [e_c − γ n_c²]: at γ = ¼ each cycle is 3 − 9/4 = ¾; the whole graph
            // 7 − 9 = −2.
            #expect(graph.leidenCommunities(quality: .constantPottsModel, resolution: 0.25, using: &generator).map { Array($0) } == [[0, 1, 2], [3, 4, 5]], "seed \(seed)")
        }
        // Directed modularity of the two cycles: 2 (3/7 − (4·3)/49) = 18/49.
        var generator = SeededRandomNumberGenerator(seed: 5)
        let result = graph.leidenCommunities(using: &generator)
        #expect(abs(graph.modularity(of: result) - 18.0 / 49) <= 1e-12)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let undirected = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(undirected.directedView.leidenCommunities(using: &generator).map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
    }

    @Test("The same seed gives the same partition; the overloads without a generator give a valid partition")
    func seeds() {
        var pairs: [(Int, Int)] = []
        var x: UInt64 = 12345
        for _ in 0 ..< 120 {
            x = x &* 6364136223846793005 &+ 1442695040888963407
            let u = Int((x >> 33) % 40)
            x = x &* 6364136223846793005 &+ 1442695040888963407
            let v = Int((x >> 33) % 40)
            if u != v { pairs.append((u, v)) }
        }
        let graph = ReferencePseudograph(vertices: 0 ..< 40, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var a = SeededRandomNumberGenerator(seed: 99), b = SeededRandomNumberGenerator(seed: 99)
        #expect(graph.leidenCommunities(using: &a) == graph.leidenCommunities(using: &b))
        #expect(graph.leidenCommunities(weight: { Double($0 % 3 + 1) }, quality: .constantPottsModel, resolution: 0.05, using: &a)
            == graph.leidenCommunities(weight: { Double($0 % 3 + 1) }, quality: .constantPottsModel, resolution: 0.05, using: &b))
        let system = graph.leidenCommunities()
        #expect(system.reduce(0) { $0 + $1.count } == 40)
        #expect(graph.modularity(of: system) > graph.modularity(of: (0 ..< 40).map { [$0] }))
        let weighted = graph.leidenCommunities(weight: { Double($0 % 3 + 1) })
        #expect(weighted.reduce(0) { $0 + $1.count } == 40)
        let directed = ReferenceDirectedMultigraph(vertices: 0 ..< 40, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(directed.leidenCommunities().reduce(0) { $0 + $1.count } == 40)
        #expect(directed.leidenCommunities(weight: { Double($0 % 3 + 1) }).reduce(0) { $0 + $1.count } == 40)
    }

    @Test("iterations: one iteration gives runs, which leaves no single move that gains; iterations beyond the fixed point change nothing")
    func iterations() {
        let n = 400
        let path = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        for seed in 0 ..< 5 {
            var a = SeededRandomNumberGenerator(seed: UInt(seed)), b = a, c = a
            let full = path.leidenCommunities(using: &a)
            let many = path.leidenCommunities(iterations: 1000, using: &b)
            #expect(full == many, "seed \(seed)")
            let once = path.leidenCommunities(iterations: 1, using: &c)
            for community in once { #expect(community.last! - community.first! == community.count - 1, "seed \(seed)") }
            #expect(path.modularity(of: once) > 0.8)
            // At the fixed point every block is a run, and moving an end vertex to its neighbor's
            // block does not raise Q.
            let q = path.modularity(of: full)
            let groups = full.map { Array($0) }
            for (i, block) in groups.enumerated() where i + 1 < groups.count {
                var moved = groups
                moved[i].removeLast()
                moved[i + 1].insert(block.last!, at: 0)
                #expect(path.modularity(of: moved.filter { !$0.isEmpty }) <= q + 1e-12, "seed \(seed)")
            }
        }
    }

    @Test("Representations: UndirectedAdjacencyList, AdjacencyList and CompressedSparseRow give the reference conformers' partitions for the same seed")
    func representations() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3), (5, 6), (6, 7), (7, 8), (8, 6)]
        let reference = ReferencePseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let list = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let arcs = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let directedReference = ReferenceDirectedMultigraph(vertices: 0 ..< 9, edges: arcs)
        let directedList = AdjacencyList(vertices: 0 ..< 9, edges: arcs)
        let csr = CompressedSparseRow(vertexCount: 9, edges: arcs)
        for seed in 0 ..< 10 {
            var a = SeededRandomNumberGenerator(seed: UInt(seed)), b = a, c = a, d = a, e = a
            let expected = reference.leidenCommunities(using: &a).map { Array($0) }
            #expect(expected == [[0, 1, 2], [3, 4, 5], [6, 7, 8]], "seed \(seed)")
            #expect(list.leidenCommunities(using: &b).map { Array($0) } == expected, "seed \(seed)")
            let directed = directedReference.leidenCommunities(using: &c).map { Array($0) }
            #expect(directed == [[0, 1, 2], [3, 4, 5], [6, 7, 8]], "seed \(seed)")
            #expect(directedList.leidenCommunities(using: &d).map { Array($0) } == directed, "seed \(seed)")
            #expect(csr.leidenCommunities(using: &e).map { Array($0) } == directed, "seed \(seed)")
        }
    }

    @Test("constantPottsModel(of:): hand-computed values, undirected and directed, weighted, loops and parallel copies inside")
    func constantPottsModelValues() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        // 2 (3 − 9/2) = −3; the whole: 7 − 18 = −11; singletons −3; at γ = ½: 2 (3 − 9/4) = 3/2.
        #expect(graph.constantPottsModel(of: [[0, 1, 2], [3, 4, 5]]) == -3)
        #expect(graph.constantPottsModel(of: [[0, 1, 2, 3, 4, 5]]) == -11)
        #expect(graph.constantPottsModel(of: (0 ..< 6).map { [$0] }) == -3)
        #expect(graph.constantPottsModel(of: [[0, 1, 2], [3, 4, 5]], resolution: 0.5) == 1.5)
        // Weighted: the triangle 0, 1, 2 weighs 1 + 2 + 3; γ = 0 is the weight inside.
        #expect(graph.constantPottsModel(of: [[0, 1, 2], [3, 4, 5], []], weight: { Double($0 + 1) }, resolution: 0) == 6 + 15)
        // A loop and two parallel copies, all inside: 3 − 4/2 = 1.
        let multi = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(1, 0)])
        #expect(multi.constantPottsModel(of: [[0, 1]]) == 1)
        // Directed Σ_c [e_c − γ n_c²]: two 3-cycles and an arc between, at γ = 1: 2 (3 − 9) = −12.
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(digraph.constantPottsModel(of: [[0, 1, 2], [3, 4, 5]]) == -12)
        #expect(digraph.constantPottsModel(of: [[0, 1, 2], [3, 4, 5]], weight: { _ in 2.0 }, resolution: 0.5) == 2 * (6 - 4.5))
        #expect(ReferencePseudograph<Int>(vertices: [], edges: []).constantPottsModel(of: [[Int]]()) == 0)
    }

    @Test("connectedComponents(within:) and weaklyConnectedComponents(within:) split each community into its components and never lower modularity")
    func componentsWithin() {
        // A path 0-1-2 and an edge 3-4; the grouping {0, 2, 3}, {1, 4} splits into five pieces,
        // {0, 1, 2} and {3, 4} stay.
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.connectedComponents(within: [[0, 2, 3], [1, 4]]).map { Array($0) } == [[0], [1], [2], [3], [4]])
        #expect(graph.connectedComponents(within: [[0, 1, 2, 3, 4]]).map { Array($0) } == [[0, 1, 2], [3, 4]])
        #expect(graph.connectedComponents(within: [[3, 4], [], [0, 1, 2]]).map { Array($0) } == [[0, 1, 2], [3, 4]])
        let grouping = [[0, 1, 3, 4], [2]]
        let split = graph.connectedComponents(within: grouping)
        #expect(split.map { Array($0) } == [[0, 1], [2], [3, 4]])
        #expect(graph.modularity(of: split) >= graph.modularity(of: grouping))
        // Directed: weak connectivity, 1 → 0 ← 2 holds together.
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 0)])
        #expect(digraph.weaklyConnectedComponents(within: [[0, 1, 2, 3]]).map { Array($0) } == [[0, 1, 2], [3]])
        #expect(digraph.weaklyConnectedComponents(within: [[1, 2], [0, 3]]).map { Array($0) } == [[0], [1], [2], [3]])
        #expect(ReferencePseudograph<Int>(vertices: [], edges: []).connectedComponents(within: [[Int]]()).isEmpty)
    }

    @Test("louvainPartitions: the levels end with louvainCommunities(), each a union of the last's communities")
    func louvainLevels() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17),
            (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9),
            (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33),
            (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29),
            (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let levels = graph.louvainPartitions()
        #expect(levels.count >= 2)
        #expect(levels.last == graph.louvainCommunities())
        for (finer, coarser) in zip(levels, levels.dropFirst()) {
            for community in finer {
                let c = coarser.community(of: community.first!)
                #expect(community.allSatisfy { coarser.community(of: $0) == c })
            }
            #expect(graph.modularity(of: coarser) > graph.modularity(of: finer))
        }
        let w = (0 ..< pairs.count).map { Double($0 % 4 + 1) }
        #expect(graph.louvainPartitions(weight: { w[$0] }).last == graph.louvainCommunities(weight: { w[$0] }))
        var a = SeededRandomNumberGenerator(seed: 4), b = a
        #expect(graph.louvainPartitions(using: &a).last == graph.louvainCommunities(using: &b))
        #expect(graph.louvainPartitions(weight: { w[$0] }, using: &a).last == graph.louvainCommunities(weight: { w[$0] }, using: &b))
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(digraph.louvainPartitions().last == digraph.louvainCommunities())
        #expect(digraph.louvainPartitions(weight: { w[$0] }).last == digraph.louvainCommunities(weight: { w[$0] }))
        #expect(digraph.louvainPartitions(using: &a).last == digraph.louvainCommunities(using: &b))
        #expect(digraph.louvainPartitions(weight: { w[$0] }, using: &a).last == digraph.louvainCommunities(weight: { w[$0] }, using: &b))
        // No edges: one level, the singletons.
        let edgeless = ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: [])
        #expect(edgeless.louvainPartitions().map { $0.map { Array($0) } } == [[[0], [1], [2]]])
    }
}
