// Properties with shrinking (swift-property-based) of the configuration model, Chung–Lu,
// Holme–Kim, Newman–Watts–Strogatz, connected Watts–Strogatz, random k-out, directed scale-free and
// G(a, b, m), over random sizes, parameters and seeds, against the invariants api.md documents and
// references written out in each test. Each family runs on every conformer of its kind, which must
// give the same edges and leave the generator in the same state. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import RandomGraphs
import StableGraphs
import Testing

@Suite("RandomGraphs later families, with shrinking", .tags(.randomized))
struct LaterFamilyPropertyTests {
    @Test("configurationModel: every vertex has exactly its degree; the stubs are a Fisher–Yates shuffle, replayed here")
    func configurationModel() async {
        await propertyCheck(count: 150, input: Gen.int(in: 0 ... 6).array(of: 0 ... 25), Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            var degrees = raw
            if degrees.reduce(0, +) % 2 == 1 { degrees.append(1) }
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = Pseudograph<Int>.configurationModel(degreeSequence: degrees, using: &generator)
            #expect(graph.vertexCount == degrees.count && graph.edgeCount == degrees.reduce(0, +) / 2, "\(degrees)")
            let built = (0 ..< degrees.count).map { graph.degree(of: $0) }
            #expect(built == degrees, "\(degrees)")
            // The procedure, written out: stubs in vertex order, Fisher–Yates with below(i + 1), and the
            // first half paired with the second.
            var replay = Xoshiro256StarStar(seed: UInt64(seed))
            var stubs: [Int] = []
            for (v, d) in degrees.enumerated() { stubs += Array(repeating: v, count: d) }
            var i = stubs.count - 1
            while i >= 1 {
                let bits = Int.bitWidth - (i + 1).leadingZeroBitCount
                var j = Int(replay.next() >> UInt64(64 - bits))
                while j > i { j = Int(replay.next() >> UInt64(64 - bits)) }
                stubs.swapAt(i, j)
                i -= 1
            }
            let half = stubs.count / 2
            let expected = (0 ..< half).map { [stubs[$0], stubs[half + $0]] }
            #expect(graph.edges.map { [$0.u, $0.v] } == expected, "\(degrees)")
            #expect(replay == generator, "\(degrees)")
            // Built in bulk, the same graph as one insertion per pair: rows and parallel classes.
            let inserted = Pseudograph(vertices: 0 ..< degrees.count, edges: graph.edges)
            let rowsAgree = (0 ..< degrees.count).allSatisfy { v in
                Array(graph.incidentEdges(of: v)) == Array(inserted.incidentEdges(of: v))
                    && Array(graph.neighbors(of: v)) == Array(inserted.neighbors(of: v))
            }
            let multiplicities = graph.edges.allSatisfy { graph.edgeCount(between: $0.u, and: $0.v) == inserted.edgeCount(between: $0.u, and: $0.v) }
            #expect(graph == inserted && rowsAgree && multiplicities, "\(degrees)")
        }
    }

    @Test("directed configurationModel: every vertex has exactly its in- and out-degree, out-stubs shuffled before in-stubs")
    func directedConfigurationModel() async {
        await propertyCheck(count: 150, input: zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)).array(of: 0 ... 20), Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            var nOuts = raw.map(\.0)
            var ins = raw.map(\.1)
            // Equal sums: the difference onto vertex 0.
            let difference = nOuts.reduce(0, +) - ins.reduce(0, +)
            if difference > 0 { ins[0] += difference } else if difference < 0 { nOuts[0] -= difference }
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = DirectedPseudograph<Int>.configurationModel(inDegrees: ins, outDegrees: nOuts, using: &generator)
            let builtOuts = (0 ..< ins.count).map { graph.outDegree(of: $0) }
            var builtIns = [Int](repeating: 0, count: ins.count)
            for edge in graph.edges { builtIns[edge.target] += 1 }
            #expect(builtOuts == nOuts && builtIns == ins, "in \(ins), out \(nOuts)")
            #expect(graph.edgeCount == ins.reduce(0, +), "in \(ins), out \(nOuts)")
        }
    }

    @Test("chungLu: simple and sorted, the same edges and draws on every conformer; directed, both arcs; all-zero weights draw nothing")
    func chungLu() async {
        await propertyCheck(count: 120, input: Gen.int(in: 0 ... 12).array(of: 0 ... 40), Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let weights = raw.map { Double($0) / 2 }
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: weights, using: &generator)
            let ends = graph.edges.map { [$0.u, $0.v] }
            let sorted = zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }
            let simple = ends.allSatisfy { $0[0] < $0[1] }
            #expect(sorted && simple && graph.vertexCount == weights.count, "\(weights)")
            // A vertex of weight 0 has probability 0 with everyone.
            let zeroIsolated = (0 ..< weights.count).allSatisfy { weights[$0] > 0 || graph.degree(of: $0) == 0 }
            #expect(zeroIsolated, "\(weights)")
            var other = Xoshiro256StarStar(seed: UInt64(seed))
            let pseudograph = Pseudograph<Int>.chungLu(expectedDegrees: weights, using: &other)
            #expect(pseudograph.edges.map { [$0.u, $0.v] } == ends && other == generator, "\(weights)")
            var directedGenerator = Xoshiro256StarStar(seed: UInt64(seed))
            let directed = CompressedSparseRow.chungLu(expectedDegrees: weights, using: &directedGenerator)
            var arcs = ends + ends.map { [$0[1], $0[0]] }
            arcs.sort { $0.lexicographicallyPrecedes($1) }
            #expect(directed.edges.map { [$0.source, $0.target] } == arcs && directedGenerator == generator, "\(weights)")
            if weights.allSatisfy({ $0 == 0 }) {
                #expect(graph.edgeCount == 0 && generator == Xoshiro256StarStar(seed: UInt64(seed)), "\(weights)")
            }
        }
    }

    @Test("holmeKim: m(n − m) edges, each later vertex joined to m older ones; directed newer → older with the same draws")
    func holmeKim() async {
        await propertyCheck(count: 120, input: Gen.int(in: 1 ... 40), Gen.int(in: 1 ... 5), Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 1_000_000)) { n, rawM, tenths, seed in
            let m = min(rawM, n)
            let p = Double(tenths) / 10
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: n, edgesPerVertex: m, triangleProbability: p, using: &generator)
            #expect(graph.vertexCount == n && graph.edgeCount == m * (n - m), "n \(n), m \(m), p \(p)")
            let older = (0 ..< n).map { v in graph.neighbors(of: v).filter { $0 < v }.count }
            let expected = (0 ..< n).map { $0 < m ? 0 : m }
            #expect(older == expected, "n \(n), m \(m), p \(p)")
            var directedGenerator = Xoshiro256StarStar(seed: UInt64(seed))
            let directed = CompressedSparseRow.holmeKim(vertexCount: n, edgesPerVertex: m, triangleProbability: p, using: &directedGenerator)
            let arcs = Set(directed.edges.map { [$0.source, $0.target] })
            let reversed = Set(graph.edges.map { [$0.v, $0.u] })
            #expect(arcs == reversed && directedGenerator == generator, "n \(n), m \(m), p \(p)")
            var multigraphGenerator = Xoshiro256StarStar(seed: UInt64(seed))
            let multigraph = Multigraph<Int>.holmeKim(vertexCount: n, edgesPerVertex: m, triangleProbability: p, using: &multigraphGenerator)
            #expect(multigraph.edges.map { [$0.u, $0.v] } == graph.edges.map { [$0.u, $0.v] } && multigraphGenerator == generator)
        }
    }

    @Test("newmanWattsStrogatz: the ring lattice kept, shortcuts only added, simple; directed, both arcs with the same draws")
    func newmanWattsStrogatz() async {
        await propertyCheck(count: 120, input: Gen.int(in: 0 ... 40), Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 1_000_000)) { n, half, tenths, seed in
            let k = min(2 * half, n - n % 2)
            let p = Double(tenths) / 10
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: n, nearestNeighborCount: k, shortcutProbability: p, using: &generator)
            let edges = Set(graph.edges.map { [$0.u, $0.v] })
            var ring = Set<[Int]>()
            for u in 0 ..< n {
                for j in 1 ..< max(k / 2 + 1, 1) where k > 0 {
                    let v = (u + j) % n
                    ring.insert([min(u, v), max(u, v)])
                }
            }
            #expect(ring.isSubset(of: edges) && edges.count == graph.edgeCount, "n \(n), k \(k), p \(p)")
            let simple = graph.edges.allSatisfy { $0.u < $0.v }
            #expect(simple, "n \(n), k \(k), p \(p)")
            if p == 0, k < n { #expect(edges == ring, "n \(n), k \(k)") }
            var directedGenerator = Xoshiro256StarStar(seed: UInt64(seed))
            let directed = AdjacencyList<Int>.newmanWattsStrogatz(vertexCount: n, nearestNeighborCount: k, shortcutProbability: p, using: &directedGenerator)
            let arcs = Set(directed.edges.map { [$0.source, $0.target] })
            let both = edges.union(edges.map { [$0[1], $0[0]] })
            #expect(arcs == both && directedGenerator == generator, "n \(n), k \(k), p \(p)")
        }
    }

    @Test("connectedWattsStrogatz: the first connected graph among the Watts–Strogatz draws on the stream, or nil when none of the tries is")
    func connectedWattsStrogatz() async {
        await propertyCheck(count: 100, input: Gen.int(in: 1 ... 24), Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 1_000_000)) { n, half, tenths, tries, seed in
            let k = min(2 * half, n - n % 2)
            let p = Double(tenths) / 10
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(
                vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, tries: tries, using: &generator)
            // The reference: wattsStrogatz again on the same stream until connected.
            func isConnected(_ g: UndirectedAdjacencyList<Int>) -> Bool {
                var seen: Set<Int> = [0], stack = [0]
                while let v = stack.popLast() {
                    for w in g.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }
                }
                return seen.count == g.vertexCount
            }
            var replay = Xoshiro256StarStar(seed: UInt64(seed))
            var expected: UndirectedAdjacencyList<Int>?
            for _ in 0 ..< tries {
                let attempt = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, using: &replay)
                if isConnected(attempt) {
                    expected = attempt
                    break
                }
            }
            #expect(graph == expected && replay == generator, "n \(n), k \(k), p \(p), tries \(tries)")
            if let graph { #expect(isConnected(graph), "n \(n), k \(k), p \(p)") }
        }
    }

    @Test("randomKOut: out-degree k, no self-loop or repeat, row-major; undirected, the directed draw's pairs, each degree at least k")
    func randomKOut() async {
        await propertyCheck(count: 150, input: Gen.int(in: 0 ... 60), Gen.int(in: 0 ... 12), Gen.int(in: 0 ... 1_000_000)) { n, rawK, seed in
            let k = min(rawK, max(n - 1, 0))
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = CompressedSparseRow.randomKOut(vertexCount: n, outDegree: k, using: &generator)
            let arcs = graph.edges.map { [$0.source, $0.target] }
            let ordered = zip(arcs, arcs.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }
            let loopless = arcs.allSatisfy { $0[0] != $0[1] }
            let degrees = (0 ..< n).allSatisfy { graph.outDegree(of: $0) == k }
            #expect(ordered && loopless && degrees && graph.edgeCount == n * k, "n \(n), k \(k)")
            var matrixGenerator = Xoshiro256StarStar(seed: UInt64(seed))
            let matrix = AdjacencyMatrix.randomKOut(vertexCount: n, outDegree: k, using: &matrixGenerator)
            #expect(matrix.edges.map { [$0.source, $0.target] } == arcs && matrixGenerator == generator, "n \(n), k \(k)")
            var undirectedGenerator = Xoshiro256StarStar(seed: UInt64(seed))
            let undirected = UndirectedAdjacencyList<Int>.randomKOut(vertexCount: n, outDegree: k, using: &undirectedGenerator)
            let pairs = Set(arcs.map { [min($0[0], $0[1]), max($0[0], $0[1])] })
            #expect(Set(undirected.edges.map { [$0.u, $0.v] }) == pairs && undirected.edgeCount == pairs.count, "n \(n), k \(k)")
            let atLeastK = (0 ..< n).allSatisfy { undirected.degree(of: $0) >= k }
            #expect(atLeastK && undirectedGenerator == generator, "n \(n), k \(k)")
        }
    }

    @Test("scaleFree: n vertices from the 3-cycle; every vertex after the first 3 arrives with one arc; in- and out-degree sums equal")
    func scaleFree() async {
        await propertyCheck(count: 120, input: Gen.int(in: 3 ... 60), Gen.int(in: 1 ... 8), Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 1_000_000)) { n, a, b, delta, seed in
            let total = Double(a + b + 1)
            let alpha = Double(a) / total, beta = Double(b) / total, gamma = 1 - alpha - beta
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = DirectedPseudograph<Int>.scaleFree(
                vertexCount: n, alpha: alpha, beta: beta, gamma: gamma, deltaIn: Double(delta) / 10, deltaOut: Double(10 - delta) / 10,
                using: &generator)
            #expect(graph.vertexCount == n && Array(graph.vertices) == Array(0 ..< n))
            let arcs = graph.edges.map { [$0.source, $0.target] }
            #expect(Array(arcs.prefix(3)) == [[0, 1], [1, 2], [2, 0]], "\(arcs)")
            // Each new vertex v first appears in the arc that adds it, as its source or its target.
            var seen = 3
            var valid = true
            for arc in arcs.dropFirst(3) {
                let newest = max(arc[0], arc[1])
                if newest == seen { seen += 1 } else if newest > seen { valid = false }
            }
            #expect(valid && seen == n, "\(arcs)")
            let outSum = (0 ..< n).reduce(0) { $0 + graph.outDegree(of: $1) }
            #expect(outSum == graph.edgeCount, "\(arcs)")
            // Built in bulk, the same graph as one insertion per arc.
            let inserted = DirectedPseudograph(vertices: 0 ..< n, edges: graph.edges)
            let rowsAgree = (0 ..< n).allSatisfy { v in
                Array(graph.outEdges(of: v)) == Array(inserted.outEdges(of: v)) && Array(graph.inEdges(of: v)) == Array(inserted.inEdges(of: v))
            }
            #expect(graph == inserted && rowsAgree, "\(arcs)")
        }
    }

    @Test("randomBipartite(edgeCount:): m edges, each across the sides, sorted, the same on every conformer and BipartiteGraph")
    func randomBipartiteEdgeCount() async {
        await propertyCheck(count: 150, input: Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 100), Gen.int(in: 0 ... 1_000_000)) { a, b, rawM, seed in
            let m = min(rawM, a * b)
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: a, rightCount: b, edgeCount: m, using: &generator)
            let ends = graph.edges.map { [$0.u, $0.v] }
            let across = ends.allSatisfy { $0[0] < a && $0[1] >= a }
            let sorted = zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }
            #expect(graph.edgeCount == m && across && sorted, "\(a), \(b), \(m)")
            var bipartiteGenerator = Xoshiro256StarStar(seed: UInt64(seed))
            let bipartite = BipartiteGraph<Int>.randomBipartite(leftCount: a, rightCount: b, edgeCount: m, using: &bipartiteGenerator)
            #expect(bipartite.edges.map { [$0.u, $0.v] } == ends && bipartiteGenerator == generator, "\(a), \(b), \(m)")
            #expect(Array(bipartite.left) == Array(0 ..< a) && Array(bipartite.right) == Array(a ..< a + b))
            let arcCount = min(rawM, 2 * a * b)
            var directedGenerator = Xoshiro256StarStar(seed: UInt64(seed))
            let directed = StableDirectedGraph<Int>.randomBipartite(leftCount: a, rightCount: b, edgeCount: arcCount, using: &directedGenerator)
            let crossing = directed.edges.allSatisfy { ($0.source < a) != ($0.target < a) }
            #expect(directed.edgeCount == arcCount && crossing, "\(a), \(b), \(arcCount)")
        }
    }

    @Test("Every overload without using: gives a graph of the documented shape")
    func systemGeneratorOverloads() {
        #expect(Pseudograph<Int>.configurationModel(degreeSequence: [2, 2, 2]).edgeCount == 3)
        #expect(DirectedPseudograph<Int>.configurationModel(inDegrees: [1, 1], outDegrees: [1, 1]).edgeCount == 2)
        #expect(UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: [1.0, 1.0, 1.0]).vertexCount == 3)
        #expect(CompressedSparseRow.chungLu(expectedDegrees: [1.0, 1.0]).vertexCount == 2)
        #expect(UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5).edgeCount == 16)
        #expect(CompressedSparseRow.holmeKim(vertexCount: 10, edgesPerVertex: 2, triangleProbability: 0.5).edgeCount == 16)
        #expect(UndirectedAdjacencyList<Int>.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0).edgeCount == 10)
        #expect(CompressedSparseRow.newmanWattsStrogatz(vertexCount: 10, nearestNeighborCount: 2, shortcutProbability: 0).edgeCount == 20)
        #expect(UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0)?.edgeCount == 20)
        #expect(CompressedSparseRow.connectedWattsStrogatz(vertexCount: 10, nearestNeighborCount: 4, rewiringProbability: 0)?.edgeCount == 40)
        #expect(CompressedSparseRow.randomKOut(vertexCount: 6, outDegree: 2).edgeCount == 12)
        #expect(UndirectedAdjacencyList<Int>.randomKOut(vertexCount: 6, outDegree: 5).edgeCount == 15)
        #expect(DirectedPseudograph<Int>.scaleFree(vertexCount: 20).vertexCount == 20)
        #expect(UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeCount: 4).edgeCount == 4)
        #expect(CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 3, edgeCount: 10).edgeCount == 10)
        #expect(BipartiteGraph<Int>.randomBipartite(leftCount: 3, rightCount: 3, edgeCount: 9).edgeCount == 9)
    }
}
