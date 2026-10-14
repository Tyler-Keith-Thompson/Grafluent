// Degree sequences, checked against references written out in each test: every sequence on up to
// six vertices (and every pair of sequences on up to four) against the graphs that realize it,
// enumerated; longer random sequences against Erdős–Gallai and Fulkerson–Chen–Anstee checked at
// every k; and Havel–Hakimi and Kleitman–Wang realizing the degrees of random graphs on every
// conformer of their kind. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import RandomGraphs
import StableGraphs
import Testing

@Suite("RandomGraphs degree sequences, against enumeration and the inequalities", .tags(.randomized))
struct DegreeSequencePropertyTests {
    @Test("isGraphical is true exactly for the degree sequences of the simple graphs on n ≤ 6 vertices")
    func graphicalByEnumeration() {
        for n in 0 ... 6 {
            // Every simple graph on n vertices, as a bit per pair.
            var pairs: [(Int, Int)] = []
            for u in 0 ..< n { for v in u + 1 ..< max(n, u + 1) { pairs.append((u, v)) } }
            var realized = Set<[Int]>()
            for mask in 0 ..< (1 << pairs.count) {
                var degrees = [Int](repeating: 0, count: n)
                for (bit, pair) in pairs.enumerated() where mask >> bit & 1 == 1 {
                    degrees[pair.0] += 1
                    degrees[pair.1] += 1
                }
                realized.insert(degrees)
            }
            // Every sequence with entries in -1 ... n.
            var sequence = [Int](repeating: -1, count: n)
            var checked = 0
            while true {
                let expected = realized.contains(sequence)
                let actual = isGraphical(sequence)
                if actual != expected { Issue.record("isGraphical(\(sequence)) is \(actual)") }
                checked += 1
                var i = n - 1
                while i >= 0, sequence[i] == n {
                    sequence[i] = -1
                    i -= 1
                }
                if i < 0 { break }
                sequence[i] += 1
            }
            var count = 1
            for _ in 0 ..< n { count *= n + 2 }
            #expect(checked == count, "n \(n)")
        }
    }

    @Test("isDigraphical is true exactly for the degree sequences of the simple digraphs on n ≤ 4 vertices")
    func digraphicalByEnumeration() {
        for n in 0 ... 4 {
            var arcs: [(Int, Int)] = []
            for u in 0 ..< n { for v in 0 ..< n where u != v { arcs.append((u, v)) } }
            var realized = Set<[Int]>()
            for mask in 0 ..< (1 << arcs.count) {
                var degrees = [Int](repeating: 0, count: 2 * n)
                for (bit, arc) in arcs.enumerated() where mask >> bit & 1 == 1 {
                    degrees[arc.1] += 1      // in-degrees first
                    degrees[n + arc.0] += 1  // then out-degrees
                }
                realized.insert(degrees)
            }
            // Every pair of sequences with entries in 0 ... n (n itself is never a degree).
            var both = [Int](repeating: 0, count: 2 * n)
            while true {
                let expected = realized.contains(both)
                let actual = isDigraphical(inDegrees: both[0 ..< n], outDegrees: both[n ..< 2 * n])
                if actual != expected { Issue.record("isDigraphical(\(both)) is \(actual)") }
                var i = 2 * n - 1
                while i >= 0, both[i] == n {
                    both[i] = 0
                    i -= 1
                }
                if i < 0 { break }
                both[i] += 1
            }
        }
    }

    @Test("isGraphical agrees with Erdős–Gallai checked at every k, on random sequences of up to 40")
    func graphicalAgainstErdosGallai() async {
        await propertyCheck(count: 400, input: Gen.int(in: 0 ... 12).array(of: 0 ... 40)) { raw in
            // Bias toward even sums, so that both answers occur.
            var sequence = raw.map { min($0, max(raw.count - 1, 0)) }
            if sequence.reduce(0, +) % 2 == 1, let i = sequence.firstIndex(where: { $0 > 0 }) { sequence[i] -= 1 }
            let n = sequence.count
            let sorted = sequence.sorted(by: >)
            var expected = sorted.reduce(0, +) % 2 == 0
            if expected {
                for k in 1 ... max(n, 1) where k <= n {
                    let left = sorted[0 ..< k].reduce(0, +)
                    let right = k * (k - 1) + sorted[k...].reduce(0) { $0 + min($1, k) }
                    if left > right {
                        expected = false
                        break
                    }
                }
            }
            let actual = isGraphical(sequence)
            #expect(actual == expected, "\(sequence)")
        }
    }

    @Test("isDigraphical agrees with Fulkerson–Chen–Anstee checked at every k, on random pairs of up to 30")
    func digraphicalAgainstFulkersonChenAnstee() async {
        await propertyCheck(count: 400, input: zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 30)) { raw in
            let n = raw.count
            var ins = raw.map { min($0.0, max(n - 1, 0)) }
            let outs = raw.map { min($0.1, max(n - 1, 0)) }
            // Move in-degree to balance the sums where it fits, so that both answers occur.
            var difference = outs.reduce(0, +) - ins.reduce(0, +)
            for i in 0 ..< n where difference != 0 {
                let step = difference > 0 ? min(difference, n - 1 - ins[i]) : max(difference, -ins[i])
                ins[i] += step
                difference -= step
            }
            var expected = ins.reduce(0, +) == outs.reduce(0, +)
            if expected {
                // (out, in) pairs, lexicographically non-increasing.
                let pairs = zip(outs, ins).sorted { $0.0 != $1.0 ? $0.0 > $1.0 : $0.1 > $1.1 }
                for k in 1 ... max(n, 1) where k <= n {
                    let left = pairs[0 ..< k].reduce(0) { $0 + $1.0 }
                    let right = pairs[0 ..< k].reduce(0) { $0 + min($1.1, k - 1) } + pairs[k...].reduce(0) { $0 + min($1.1, k) }
                    if left > right {
                        expected = false
                        break
                    }
                }
            }
            let actual = isDigraphical(inDegrees: ins, outDegrees: outs)
            #expect(actual == expected, "in \(ins), out \(outs)")
        }
    }

    @Test("havelHakimi realizes the degrees of a random graph, simple and sorted, the same on every undirected conformer")
    func havelHakimiRealizes() async {
        await propertyCheck(count: 120, input: Gen.int(in: 0 ... 40), Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 1_000_000)) { n, tenths, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let source = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: n, edgeProbability: Double(tenths) / 10, using: &generator)
            let degrees = (0 ..< n).map { source.degree(of: $0) }
            #expect(isGraphical(degrees), "\(degrees)")
            let graph = UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: degrees)
            let built = (0 ..< n).map { graph.degree(of: $0) }
            #expect(built == degrees, "\(degrees)")
            let ends = graph.edges.map { [$0.u, $0.v] }
            let sorted = zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }
            let simple = ends.allSatisfy { $0[0] < $0[1] }
            #expect(sorted && simple, "\(degrees)")
            let pseudograph = Pseudograph<Int>.havelHakimi(degreeSequence: degrees).edges.map { [$0.u, $0.v] }
            let multigraph = Multigraph<Int>.havelHakimi(degreeSequence: degrees).edges.map { [$0.u, $0.v] }
            #expect(pseudograph == ends && multigraph == ends, "\(degrees)")
        }
    }

    @Test("Kleitman–Wang realizes the in- and out-degrees of a random digraph, simple and row-major, on every directed conformer")
    func kleitmanWangRealizes() async {
        await propertyCheck(count: 120, input: Gen.int(in: 0 ... 30), Gen.int(in: 0 ... 10), Gen.int(in: 0 ... 1_000_000)) { n, tenths, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let source = CompressedSparseRow.erdosRenyi(vertexCount: n, edgeProbability: Double(tenths) / 10, using: &generator)
            let outs = (0 ..< n).map { source.outDegree(of: $0) }
            var ins = [Int](repeating: 0, count: n)
            for edge in source.edges { ins[edge.target] += 1 }
            #expect(isDigraphical(inDegrees: ins, outDegrees: outs), "in \(ins), out \(outs)")
            let graph = CompressedSparseRow.havelHakimi(inDegrees: ins, outDegrees: outs)
            var builtIns = [Int](repeating: 0, count: n)
            for edge in graph.edges { builtIns[edge.target] += 1 }
            let builtOuts = (0 ..< n).map { graph.outDegree(of: $0) }
            #expect(builtIns == ins && builtOuts == outs, "in \(ins), out \(outs)")
            let arcs = graph.edges.map { [$0.source, $0.target] }
            let ordered = zip(arcs, arcs.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }
            let loopless = arcs.allSatisfy { $0[0] != $0[1] }
            #expect(ordered && loopless, "in \(ins), out \(outs)")
            let others: [[[Int]]] = [AdjacencyMatrix.havelHakimi(inDegrees: ins, outDegrees: outs).edges.map { [$0.source, $0.target] },
                                     AdjacencyList<Int>.havelHakimi(inDegrees: ins, outDegrees: outs).edges.map { [$0.source, $0.target] },
                                     DirectedPseudograph<Int>.havelHakimi(inDegrees: ins, outDegrees: outs).edges.map { [$0.source, $0.target] },
                                     DirectedMultigraph<Int>.havelHakimi(inDegrees: ins, outDegrees: outs).edges.map { [$0.source, $0.target] },
                                     StableDirectedGraph<Int>.havelHakimi(inDegrees: ins, outDegrees: outs).edges.map { [$0.source, $0.target] }]
            #expect(others.allSatisfy { $0 == arcs }, "in \(ins), out \(outs)")
        }
    }

    @Test("A graphical sequence with one degree raised by 2 past n − 1, or with an odd sum, is not graphical")
    func perturbedSequences() async {
        await propertyCheck(count: 100, input: Gen.int(in: 1 ... 30), Gen.int(in: 0 ... 1_000_000)) { n, seed in
            var generator = Xoshiro256StarStar(seed: UInt64(seed))
            let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: n, edgeProbability: 0.3, using: &generator)
            var degrees = (0 ..< n).map { graph.degree(of: $0) }
            #expect(isGraphical(degrees))
            degrees[0] += 1
            #expect(!isGraphical(degrees), "odd sum \(degrees)")
            degrees[0] = n
            #expect(!isGraphical(degrees), "degree n \(degrees)")
        }
    }
}
