// Properties with shrinking (swift-property-based). The generator against its published test
// vectors and against xoshiro256** and SplitMix64 written out in the test; then every family over
// random sizes, parameters and seeds against the invariants api.md documents: simple, sorted
// edges; the exact edge counts; the degree laws; connectivity where promised; a geometric graph's
// edges from its positions; a random tree's Prüfer code from the stream; a random DAG's order.
// Each family also runs on every conformer of its kind, which must give the same edges and leave
// the generator in the same state. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import CompressedSparseRowModule
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import RandomGraphs
import StableGraphs
import Testing
import Trees

@Suite("RandomGraphs properties, with shrinking", .tags(.randomized))
struct RandomGraphPropertyTests {
    @Test("Xoshiro256StarStar: rand_xoshiro's ten-value vector from (1, 2, 3, 4), and splitmix64.c's vector for seed 1234567")
    func publishedVectors() {
        var generator = Xoshiro256StarStar(state: (1, 2, 3, 4))
        #expect((0 ..< 10).map { _ in generator.next() } == [11520, 0, 1509978240, 1215971899390074240, 1216172134540287360,
                                                             607988272756665600, 16172922978634559625, 8476171486693032832,
                                                             10595114339597558777, 2904607092377533576] as [UInt64])
        // init(seed:) fills the state with the first four SplitMix64 outputs.
        #expect(Xoshiro256StarStar(seed: 1234567) == Xoshiro256StarStar(state: (6457827717110365317, 3203168211198807973,
                                                                                 9817491932198370423, 4593380528125082431)))
    }

    @Test("Xoshiro256StarStar agrees with the reference algorithm written out here, from any seed and any state")
    func referenceAlgorithm() async {
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... Int.max), Gen.int(in: 1 ... 40)) { seed, count in
            // SplitMix64 (Steele, Lea and Flood), as in Vigna's splitmix64.c.
            var x = UInt64(seed)
            var words: [UInt64] = []
            for _ in 0 ..< 4 {
                x &+= 0x9E37_79B9_7F4A_7C15
                var z = x
                z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
                z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
                words.append(z ^ (z >> 31))
            }
            let fromSeed = Xoshiro256StarStar(seed: UInt64(seed))
            #expect(fromSeed == Xoshiro256StarStar(state: (words[0], words[1], words[2], words[3])), "seed \(seed)")
            // xoshiro256** 1.0 (Blackman and Vigna).
            var s = words
            var expected: [UInt64] = []
            for _ in 0 ..< count {
                let product = s[1] &* 5
                expected.append(((product << 7) | (product >> 57)) &* 9)
                let t = s[1] << 17
                s[2] ^= s[0]
                s[3] ^= s[1]
                s[1] ^= s[2]
                s[0] ^= s[3]
                s[2] ^= t
                s[3] = (s[3] << 45) | (s[3] >> 19)
            }
            var generator = fromSeed
            #expect((0 ..< count).map { _ in generator.next() } == expected, "seed \(seed)")
            #expect(generator == Xoshiro256StarStar(state: (s[0], s[1], s[2], s[3])), "seed \(seed)")
            // A value: the copy replays, and equal states hash alike.
            var copy = fromSeed
            #expect(copy.next() == expected[0] && copy != fromSeed, "seed \(seed)")
            #expect(Set([fromSeed, Xoshiro256StarStar(seed: UInt64(seed))]).count == 1, "seed \(seed)")
        }
    }

    @Test("G(n, p): simple, sorted, the same edges and the same draws on every conformer; directed, the undirected arcs come first")
    func erdosRenyiProbability() async {
        await propertyCheck(count: 150, input: Gen.int(in: 0 ... 40), Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 1_000_000)) { n, tenths, seed in
            let p = Double(tenths) / 10
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: n, edgeProbability: p, using: &generator)
            let ends = graph.edges.map { [$0.u, $0.v] }
            #expect(graph.vertexCount == n && Array(graph.vertices) == Array(0 ..< n), "\(n), \(p), \(seed)")
            #expect(ends.allSatisfy { $0[0] < $0[1] && $0[1] < n }, "\(n), \(p), \(seed)")
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(n), \(p), \(seed)")
            if p == 0 { #expect(ends.isEmpty && generator == Xoshiro256StarStar(seed: UInt64(seed))) }
            if p == 1 { #expect(ends.count == n * (n - 1) / 2 && generator == Xoshiro256StarStar(seed: UInt64(seed))) }
            do {
                var g = Xoshiro256StarStar(seed: UInt64(seed))
                let pseudograph = Pseudograph<Int>.erdosRenyi(vertexCount: n, edgeProbability: p, using: &g)
                #expect(pseudograph.edges.map { [$0.u, $0.v] } == ends && g == generator, "Pseudograph \(n), \(p), \(seed)")
            }
            do {
                var g = Xoshiro256StarStar(seed: UInt64(seed))
                let multigraph = Multigraph<Int>.erdosRenyi(vertexCount: n, edgeProbability: p, using: &g)
                #expect(multigraph.edges.map { [$0.u, $0.v] } == ends && g == generator, "Multigraph \(n), \(p), \(seed)")
            }
            // Directed: the first sweep draws exactly what the undirected one does and gives the lower → higher arcs.
            var d = Xoshiro256StarStar(seed: UInt64(seed))
            let csr = CompressedSparseRow.erdosRenyi(vertexCount: n, edgeProbability: p, using: &d)
            let arcs = csr.edges.map { [$0.source, $0.target] }
            #expect(arcs.allSatisfy { $0[0] != $0[1] && $0[0] < n && $0[1] < n }, "\(n), \(p), \(seed)")
            #expect(zip(arcs, arcs.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(n), \(p), \(seed)")
            #expect(arcs.filter { $0[0] < $0[1] } == ends, "\(n), \(p), \(seed)")
            var directed: [(any DirectedGraph<Int>, Xoshiro256StarStar)] = []
            var g1 = Xoshiro256StarStar(seed: UInt64(seed))
            directed.append((AdjacencyMatrix.erdosRenyi(vertexCount: n, edgeProbability: p, using: &g1), g1))
            var g2 = Xoshiro256StarStar(seed: UInt64(seed))
            directed.append((AdjacencyList<Int>.erdosRenyi(vertexCount: n, edgeProbability: p, using: &g2), g2))
            var g3 = Xoshiro256StarStar(seed: UInt64(seed))
            directed.append((DirectedPseudograph<Int>.erdosRenyi(vertexCount: n, edgeProbability: p, using: &g3), g3))
            var g4 = Xoshiro256StarStar(seed: UInt64(seed))
            directed.append((DirectedMultigraph<Int>.erdosRenyi(vertexCount: n, edgeProbability: p, using: &g4), g4))
            var g5 = Xoshiro256StarStar(seed: UInt64(seed))
            directed.append((StableDirectedGraph<Int>.erdosRenyi(vertexCount: n, edgeProbability: p, using: &g5), g5))
            for (other, g) in directed {
                #expect(other.edges.map { [$0.source, $0.target] } == arcs && g == d, "\(type(of: other)) \(n), \(p), \(seed)")
            }
            // The random DAG: the undirected draws, oriented upward, 0..<n as its order.
            var a = Xoshiro256StarStar(seed: UInt64(seed))
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: n, edgeProbability: p, using: &a)
            #expect(dag.edges.map { [$0.source, $0.target] } == ends && a == generator, "\(n), \(p), \(seed)")
            #expect(Array(dag.topologicalOrder) == Array(0 ..< n), "\(n), \(p), \(seed)")
        }
    }

    @Test("G(n, m): exactly m edges in both branches, sorted, simple, on every conformer; the DAG is the undirected draw oriented upward")
    func erdosRenyiCount() async {
        await propertyCheck(count: 200, input: Gen.int(in: 0 ... 12), Gen.int(in: 0 ... 1000), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { n, share, isDirected, seed in
            let pairs = isDirected ? n * (n - 1) : n * (n - 1) / 2
            let m = pairs * share / 1000
            if isDirected {
                var expected: [[Int]]?
                var end: Xoshiro256StarStar?
                var graphs: [(any DirectedGraph<Int>, Xoshiro256StarStar)] = []
                var g0 = Xoshiro256StarStar(seed: UInt64(seed))
                graphs.append((CompressedSparseRow.erdosRenyi(vertexCount: n, edgeCount: m, using: &g0), g0))
                var g1 = Xoshiro256StarStar(seed: UInt64(seed))
                graphs.append((AdjacencyMatrix.erdosRenyi(vertexCount: n, edgeCount: m, using: &g1), g1))
                var g2 = Xoshiro256StarStar(seed: UInt64(seed))
                graphs.append((AdjacencyList<Int>.erdosRenyi(vertexCount: n, edgeCount: m, using: &g2), g2))
                var g3 = Xoshiro256StarStar(seed: UInt64(seed))
                graphs.append((DirectedPseudograph<Int>.erdosRenyi(vertexCount: n, edgeCount: m, using: &g3), g3))
                var g4 = Xoshiro256StarStar(seed: UInt64(seed))
                graphs.append((DirectedMultigraph<Int>.erdosRenyi(vertexCount: n, edgeCount: m, using: &g4), g4))
                var g5 = Xoshiro256StarStar(seed: UInt64(seed))
                graphs.append((StableDirectedGraph<Int>.erdosRenyi(vertexCount: n, edgeCount: m, using: &g5), g5))
                for (graph, g) in graphs {
                    let arcs = graph.edges.map { [$0.source, $0.target] }
                    #expect(graph.vertexCount == n && arcs.count == m, "\(type(of: graph)) \(n), \(m), \(seed)")
                    #expect(arcs.allSatisfy { $0[0] != $0[1] && $0[0] < n && $0[1] < n }, "\(n), \(m), \(seed)")
                    #expect(zip(arcs, arcs.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(n), \(m), \(seed)")
                    if let expected { #expect(arcs == expected && g == end, "\(type(of: graph)) \(n), \(m), \(seed)") }
                    expected = arcs
                    end = g
                }
            } else {
                var g0 = Xoshiro256StarStar(seed: UInt64(seed))
                let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: n, edgeCount: m, using: &g0)
                let ends = graph.edges.map { [$0.u, $0.v] }
                #expect(graph.vertexCount == n && ends.count == m, "\(n), \(m), \(seed)")
                #expect(ends.allSatisfy { $0[0] < $0[1] && $0[1] < n }, "\(n), \(m), \(seed)")
                #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(n), \(m), \(seed)")
                if m == 0 || m == pairs { #expect(g0 == Xoshiro256StarStar(seed: UInt64(seed)), "no draws \(n), \(m), \(seed)") }
                var g1 = Xoshiro256StarStar(seed: UInt64(seed))
                let pseudograph = Pseudograph<Int>.erdosRenyi(vertexCount: n, edgeCount: m, using: &g1)
                #expect(pseudograph.edges.map { [$0.u, $0.v] } == ends && g1 == g0, "\(n), \(m), \(seed)")
                var g2 = Xoshiro256StarStar(seed: UInt64(seed))
                let multigraph = Multigraph<Int>.erdosRenyi(vertexCount: n, edgeCount: m, using: &g2)
                #expect(multigraph.edges.map { [$0.u, $0.v] } == ends && g2 == g0, "\(n), \(m), \(seed)")
                var g3 = Xoshiro256StarStar(seed: UInt64(seed))
                let dag = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: n, edgeCount: m, using: &g3)
                #expect(dag.edges.map { [$0.source, $0.target] } == ends && g3 == g0, "\(n), \(m), \(seed)")
                #expect(Array(dag.topologicalOrder) == Array(0 ..< n), "\(n), \(m), \(seed)")
            }
        }
    }

    @Test("Barabási–Albert: m(n − m) edges, the star on 0…m, every later vertex joins m older ones, connected; directed new → old")
    func barabasiAlbert() async {
        await propertyCheck(count: 150, input: Gen.int(in: 2 ... 60), Gen.int(in: 1 ... 6), Gen.int(in: 0 ... 1_000_000)) { n, rawM, seed in
            let m = min(rawM, n - 1)
            var g = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: n, edgesPerVertex: m, using: &g)
            let ends = graph.edges.map { [$0.u, $0.v] }
            #expect(graph.vertexCount == n && ends.count == m * (n - m), "\(n), \(m), \(seed)")
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(n), \(m), \(seed)")
            #expect(ends.allSatisfy { $0[0] < $0[1] && $0[1] < n }, "\(n), \(m), \(seed)")
            #expect((1 ... m).allSatisfy { graph.contains(edge: UndirectedEdge(0, $0)) }, "\(n), \(m), \(seed)")
            // Each vertex past m has exactly m edges to older vertices.
            #expect((m + 1 ..< n).allSatisfy { s in ends.filter { $0[1] == s }.count == m }, "\(n), \(m), \(seed)")
            var seen: Set<Int> = [0], stack = [0]
            while let v = stack.popLast() {
                for w in graph.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }
            }
            #expect(seen.count == n, "\(n), \(m), \(seed)")
            var d = Xoshiro256StarStar(seed: UInt64(seed))
            let csr = CompressedSparseRow.barabasiAlbert(vertexCount: n, edgesPerVertex: m, using: &d)
            #expect(d == g, "the same draws: \(n), \(m), \(seed)")
            #expect(Set(csr.edges.map { [$0.target, $0.source] }) == Set(ends), "\(n), \(m), \(seed)")
            #expect(csr.edges.allSatisfy { $0.source > $0.target }, "\(n), \(m), \(seed)")
            var p = Xoshiro256StarStar(seed: UInt64(seed))
            #expect(Multigraph<Int>.barabasiAlbert(vertexCount: n, edgesPerVertex: m, using: &p).edges.map { [$0.u, $0.v] } == ends && p == g)
            var q = Xoshiro256StarStar(seed: UInt64(seed))
            #expect(StableDirectedGraph<Int>.barabasiAlbert(vertexCount: n, edgesPerVertex: m, using: &q).edges.map { [$0.source, $0.target] }
                    == csr.edges.map { [$0.source, $0.target] } && q == g)
        }
    }

    @Test("Watts–Strogatz: nk/2 edges for every p, degree ≥ k/2, simple and sorted; p = 0 is the ring lattice")
    func wattsStrogatz() async {
        await propertyCheck(count: 150, input: Gen.int(in: 0 ... 40), Gen.int(in: 0 ... 20), Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 1_000_000)) { n, rawK, tenths, seed in
            let k = min(rawK, n) / 2 * 2
            let p = Double(tenths) / 10
            var g = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, using: &g)
            let ends = graph.edges.map { [$0.u, $0.v] }
            let m = k == n ? n * (n - 1) / 2 : n * k / 2
            #expect(graph.vertexCount == n && ends.count == m, "\(n), \(k), \(p), \(seed)")
            #expect(ends.allSatisfy { $0[0] < $0[1] && $0[1] < n }, "\(n), \(k), \(p), \(seed)")
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(n), \(k), \(p), \(seed)")
            #expect((0 ..< n).allSatisfy { graph.degree(of: $0) >= k / 2 }, "\(n), \(k), \(p), \(seed)")
            if p == 0 || k == n {
                var ring: Set<[Int]> = []
                for u in 0 ..< n { for j in 0 ..< n where j >= 1 && j <= (k == n ? n : k / 2) && (u + j) % n != u { ring.insert([min(u, (u + j) % n), max(u, (u + j) % n)]) } }
                #expect(Set(ends) == ring, "\(n), \(k), \(p), \(seed)")
            }
            var a = Xoshiro256StarStar(seed: UInt64(seed))
            #expect(Pseudograph<Int>.wattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, using: &a).edges.map { [$0.u, $0.v] } == ends && a == g)
            var b = Xoshiro256StarStar(seed: UInt64(seed))
            #expect(Multigraph<Int>.wattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, using: &b).edges.map { [$0.u, $0.v] } == ends && b == g)
        }
    }

    @Test("Random geometric: the positions are the stream's uniform01 draws, and u – v exactly when the squared distance is at most r²")
    func randomGeometric() async {
        await propertyCheck(count: 150, input: Gen.int(in: 0 ... 30), Gen.int(in: 0 ... 12), Gen.int(in: 1 ... 4), Gen.int(in: 0 ... 1_000_000)) { n, twelfths, dimension, seed in
            let radius = Double(twelfths) / 8
            var g = Xoshiro256StarStar(seed: UInt64(seed))
            let (graph, positions) = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: n, radius: radius, dimension: dimension, using: &g)
            #expect(positions.count == n * dimension, "\(n), \(radius), \(dimension), \(seed)")
            var replay = Xoshiro256StarStar(seed: UInt64(seed))
            #expect(positions == (0 ..< n * dimension).map { _ in Double(replay.next() >> 11) * 0x1p-53 }, "\(n), \(radius), \(dimension), \(seed)")
            #expect(replay == g, "\(n), \(radius), \(dimension), \(seed)")
            var expected: [[Int]] = []
            for u in 0 ..< n {
                for v in u + 1 ..< max(n, u + 1) {
                    var sum = 0.0
                    for i in 0 ..< dimension {
                        let delta = positions[u * dimension + i] - positions[v * dimension + i]
                        sum += delta * delta
                    }
                    if sum <= radius * radius { expected.append([u, v]) }
                }
            }
            #expect(graph.vertexCount == n && graph.edges.map { [$0.u, $0.v] } == expected, "\(n), \(radius), \(dimension), \(seed)")
            var a = Xoshiro256StarStar(seed: UInt64(seed))
            let other = Multigraph<Int>.randomGeometric(vertexCount: n, radius: radius, dimension: dimension, using: &a)
            #expect(other.graph.edges.map { [$0.u, $0.v] } == expected && other.positions == positions && a == g)
        }
    }

    @Test("Stochastic block model: consecutive blocks; a block pair of probability 0 has no edge, of probability 1 every pair; the same on every conformer")
    func stochasticBlockModel() async {
        await propertyCheck(count: 150, input: Gen.int(in: 0 ... 6).array(of: 1 ... 4), Gen.int(in: 0 ... 2).array(of: 16 ... 16), Gen.int(in: 0 ... 1_000_000)) { sizes, levels, seed in
            let b = sizes.count
            let choices = [0.0, 0.4, 1.0]
            let directedP = (0 ..< b).map { i in (0 ..< b).map { j in choices[levels[i * 4 + j]] } }
            let symmetricP = (0 ..< b).map { i in (0 ..< b).map { j in directedP[min(i, j)][max(i, j)] } }
            var block: [Int] = []
            for (i, size) in sizes.enumerated() { block += Array(repeating: i, count: size) }
            let n = block.count
            var g = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: sizes, edgeProbabilities: symmetricP, using: &g)
            let ends = Set(graph.edges.map { [$0.u, $0.v] })
            #expect(graph.vertexCount == n && ends.count == graph.edgeCount, "\(sizes), \(symmetricP), \(seed)")
            #expect(zip(graph.edges.map { [$0.u, $0.v] }, graph.edges.map { [$0.u, $0.v] }.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) })
            for u in 0 ..< n {
                for v in u + 1 ..< max(n, u + 1) {
                    let p = symmetricP[block[u]][block[v]]
                    if p == 0 { #expect(!ends.contains([u, v]), "\(sizes), \(symmetricP), \(seed): \(u)–\(v)") }
                    if p == 1 { #expect(ends.contains([u, v]), "\(sizes), \(symmetricP), \(seed): \(u)–\(v)") }
                }
            }
            var a = Xoshiro256StarStar(seed: UInt64(seed))
            #expect(Set(Pseudograph<Int>.stochasticBlockModel(blockSizes: sizes, edgeProbabilities: symmetricP, using: &a).edges.map { [$0.u, $0.v] }) == ends && a == g)
            var d = Xoshiro256StarStar(seed: UInt64(seed))
            let csr = CompressedSparseRow.stochasticBlockModel(blockSizes: sizes, edgeProbabilities: directedP, using: &d)
            let arcs = Set(csr.edges.map { [$0.source, $0.target] })
            #expect(csr.vertexCount == n && arcs.count == csr.edgeCount)
            for u in 0 ..< n {
                for v in 0 ..< n where u != v {
                    let p = directedP[block[u]][block[v]]
                    if p == 0 { #expect(!arcs.contains([u, v]), "\(sizes), \(directedP), \(seed): \(u)→\(v)") }
                    if p == 1 { #expect(arcs.contains([u, v]), "\(sizes), \(directedP), \(seed): \(u)→\(v)") }
                }
            }
            #expect(!arcs.contains { $0[0] == $0[1] })
            var e = Xoshiro256StarStar(seed: UInt64(seed))
            #expect(AdjacencyMatrix.stochasticBlockModel(blockSizes: sizes, edgeProbabilities: directedP, using: &e).edges.map { [$0.source, $0.target] }
                    == csr.edges.map { [$0.source, $0.target] } && e == d)
        }
    }

    @Test("Tree.random: n − 1 edges, connected, its Prüfer code is the stream's n − 2 draws below(n), degree(v) = 1 + occurrences of v")
    func randomTree() async {
        await propertyCheck(count: 200, input: Gen.int(in: 1 ... 80), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var g = Xoshiro256StarStar(seed: UInt64(seed))
            let tree = Tree<Int>.random(vertexCount: n, using: &g)
            #expect(tree.vertexCount == n && tree.edgeCount == n - 1 && Array(tree.vertices) == Array(0 ..< n), "\(n), \(seed)")
            var seen: Set<Int> = [0], stack = [0]
            while let v = stack.popLast() {
                for w in tree.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }
            }
            #expect(seen.count == n, "\(n), \(seed)")
            var replay = Xoshiro256StarStar(seed: UInt64(seed))
            var code: [Int] = []
            let bits = Int.bitWidth - n.leadingZeroBitCount
            while code.count < max(n - 2, 0) {
                let r = Int(replay.next() >> UInt64(64 - bits))
                if r < n { code.append(r) }
            }
            #expect(replay == g, "\(n), \(seed)")
            if n >= 2 {
                #expect(tree.pruferSequence == code, "\(n), \(seed)")
                #expect(tree == Tree<Int>(pruferSequence: code), "\(n), \(seed)")
            }
            #expect((0 ..< n).allSatisfy { v in tree.degree(of: v) == (n == 1 ? 0 : 1 + code.filter { $0 == v }.count) }, "\(n), \(seed)")
        }
    }

    @Test("Random regular: nd/2 edges, every degree d, simple and sorted, the same edges and draws on every conformer; directed, both arcs")
    func randomRegular() async {
        await propertyCheck(count: 120, input: Gen.int(in: 1 ... 24), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 1_000_000)) { n, degree, seed in
            let d = min(degree, n - 1) - (n * min(degree, n - 1)) % 2
            guard d >= 0 else { return }
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: n, degree: d, using: &generator)
            let ends = graph.edges.map { [$0.u, $0.v] }
            #expect(graph.vertexCount == n && graph.edgeCount == n * d / 2, "\(n), \(d), \(seed)")
            #expect((0 ..< n).allSatisfy { graph.degree(of: $0) == d }, "\(n), \(d), \(seed)")
            #expect(ends.allSatisfy { $0[0] < $0[1] }, "\(n), \(d), \(seed)")
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(n), \(d), \(seed)")
            var g1 = Xoshiro256StarStar(seed: UInt64(seed))
            let multigraph = Multigraph<Int>.randomRegular(vertexCount: n, degree: d, using: &g1)
            #expect(multigraph.edges.map { [$0.u, $0.v] } == ends && g1 == generator, "\(n), \(d), \(seed)")
            var g2 = Xoshiro256StarStar(seed: UInt64(seed))
            let csr = CompressedSparseRow.randomRegular(vertexCount: n, degree: d, using: &g2)
            let arcs = (ends + ends.map { [$0[1], $0[0]] }).sorted { $0.lexicographicallyPrecedes($1) }
            #expect(csr.edges.map { [$0.source, $0.target] } == arcs && g2 == generator, "\(n), \(d), \(seed)")
            var g3 = Xoshiro256StarStar(seed: UInt64(seed))
            let stable = StableDirectedGraph<Int>.randomRegular(vertexCount: n, degree: d, using: &g3)
            #expect(stable.edges.map { [$0.source, $0.target] } == arcs && g3 == generator, "\(n), \(d), \(seed)")
        }
    }

    @Test("Random bipartite: every edge joins the sides, sorted, the same edges and draws on every conformer and on BipartiteGraph; directed, the forward sweep first")
    func randomBipartite() async {
        await propertyCheck(count: 150, input: Gen.int(in: 0 ... 12), Gen.int(in: 0 ... 12), Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 1_000_000)) { a, b, tenths, seed in
            let p = Double(tenths) / 10
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: a, rightCount: b, edgeProbability: p, using: &generator)
            let ends = graph.edges.map { [$0.u, $0.v] }
            #expect(graph.vertexCount == a + b && ends.allSatisfy { $0[0] < a && $0[1] >= a }, "\(a), \(b), \(p), \(seed)")
            #expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(a), \(b), \(p), \(seed)")
            if p == 1 { #expect(ends.count == a * b && generator == Xoshiro256StarStar(seed: UInt64(seed))) }
            if p == 0 { #expect(ends.isEmpty && generator == Xoshiro256StarStar(seed: UInt64(seed))) }
            var g1 = Xoshiro256StarStar(seed: UInt64(seed))
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: a, rightCount: b, edgeProbability: p, using: &g1)
            #expect(bipartite.edges.map { [$0.u, $0.v] } == ends && g1 == generator, "\(a), \(b), \(p), \(seed)")
            #expect(Array(bipartite.left) == Array(0 ..< a) && Array(bipartite.right) == Array(a ..< a + b), "\(a), \(b), \(p), \(seed)")
            // Directed: the first sweep draws exactly what the undirected one does.
            var g2 = Xoshiro256StarStar(seed: UInt64(seed))
            let csr = CompressedSparseRow.randomBipartite(leftCount: a, rightCount: b, edgeProbability: p, using: &g2)
            let arcs = csr.edges.map { [$0.source, $0.target] }
            #expect(arcs.filter { $0[0] < a } == ends, "\(a), \(b), \(p), \(seed)")
            #expect(arcs.allSatisfy { ($0[0] < a) != ($0[1] < a) }, "\(a), \(b), \(p), \(seed)")
            #expect(zip(arcs, arcs.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, "\(a), \(b), \(p), \(seed)")
            var g3 = Xoshiro256StarStar(seed: UInt64(seed))
            let list = AdjacencyList<Int>.randomBipartite(leftCount: a, rightCount: b, edgeProbability: p, using: &g3)
            #expect(list.edges.map { [$0.source, $0.target] } == arcs && g3 == g2, "\(a), \(b), \(p), \(seed)")
        }
    }

    @Test("Without using:, every factory draws from the system generator and still keeps its invariants")
    func systemGenerator() {
        for _ in 0 ..< 20 {
            let gnp = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 30, edgeProbability: 0.2)
            #expect(gnp.vertexCount == 30 && gnp.edges.allSatisfy { $0.u < $0.v })
            #expect(CompressedSparseRow.erdosRenyi(vertexCount: 5, edgeProbability: 1.0).edgeCount == 20)
            #expect(UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 30, edgeCount: 40).edgeCount == 40)
            #expect(CompressedSparseRow.erdosRenyi(vertexCount: 6, edgeCount: 25).edgeCount == 25)
            #expect(UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 30, edgesPerVertex: 3).edgeCount == 81)
            #expect(CompressedSparseRow.barabasiAlbert(vertexCount: 30, edgesPerVertex: 3).edgeCount == 81)
            let ws = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 30, nearestNeighborCount: 4, rewiringProbability: 0.5)
            #expect(ws.edgeCount == 60 && (0 ..< 30).allSatisfy { ws.degree(of: $0) >= 2 })
            let geometric = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 20, radius: 0.3)
            #expect(geometric.graph.vertexCount == 20 && geometric.positions.count == 40 && geometric.positions.allSatisfy { $0 >= 0 && $0 < 1 })
            let sbm = UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [3, 4], edgeProbabilities: [[1, 0], [0, 1]])
            #expect(sbm.edgeCount == 9)
            #expect(CompressedSparseRow.stochasticBlockModel(blockSizes: [3, 4], edgeProbabilities: [[0, 1], [0, 0]]).edgeCount == 12)
            #expect(Tree<Int>.random(vertexCount: 25).edgeCount == 24)
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 20, edgeProbability: 0.3)
            #expect(dag.edges.allSatisfy { $0.source < $0.target } && Array(dag.topologicalOrder) == Array(0 ..< 20))
            #expect(DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 6, edgeCount: 15).edgeCount == 15)
        }
    }
}
