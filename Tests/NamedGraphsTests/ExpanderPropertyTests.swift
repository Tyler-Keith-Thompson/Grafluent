// Properties with shrinking (swift-property-based) of the expander families against their
// definitions and invariants: Margulis–Gabber–Galil's four steps as a simple graph, the chordal
// cycle's chords as inverses mod p, the Paley graph's regularity and self-complementarity and the
// Paley tournament's one arc per pair. Every property builds the conformers of its kind and
// requires the same edges in the same order. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import PropertyBased
import StableGraphs
import Testing

@Suite("NamedGraphs expander families, with shrinking", .tags(.randomized))
struct ExpanderPropertyTests {
    @Test("margulisGabberGalil: the four steps from (x, y), loops dropped and repeats merged, sorted; directed both arcs")
    func margulisGabberGalil() async {
        await propertyCheck(count: 60, input: Gen.int(in: 1 ... 12)) { n in
            var reference = Set<[Int]>()
            for x in 0 ..< n {
                for y in 0 ..< n {
                    let v = x * n + y
                    for (a, b) in [((x + 2 * y) % n, y), ((x + 2 * y + 1) % n, y), (x, (y + 2 * x) % n), (x, (y + 2 * x + 1) % n)] {
                        let w = a * n + b
                        if w != v { reference.insert([min(v, w), max(v, w)]) }
                    }
                }
            }
            let pairs = reference.sorted { $0.lexicographicallyPrecedes($1) }
            let undirected: [[[Int]]] = [UndirectedAdjacencyList<Int>.margulisGabberGalil(side: n).edges.map { [$0.u, $0.v] },
                                         Pseudograph<Int>.margulisGabberGalil(side: n).edges.map { [$0.u, $0.v] },
                                         Multigraph<Int>.margulisGabberGalil(side: n).edges.map { [$0.u, $0.v] }]
            #expect(undirected.allSatisfy { $0 == pairs }, "side \(n)")
            let arcs = (pairs + pairs.map { [$0[1], $0[0]] }).sorted { $0.lexicographicallyPrecedes($1) }
            let directed: [[[Int]]] = [CompressedSparseRow.margulisGabberGalil(side: n).edges.map { [$0.source, $0.target] },
                                       AdjacencyMatrix.margulisGabberGalil(side: n).edges.map { [$0.source, $0.target] },
                                       StableDirectedGraph<Int>.margulisGabberGalil(side: n).edges.map { [$0.source, $0.target] }]
            #expect(directed.allSatisfy { $0 == arcs }, "side \(n) directed")
            // At most 8 neighbors, and at least 4 for n ≥ 3 (the 1-shifted steps never return).
            let graph = UndirectedAdjacencyList<Int>.margulisGabberGalil(side: n)
            #expect((0 ..< n * n).allSatisfy { graph.degree(of: $0) <= 8 && (n < 3 || graph.degree(of: $0) >= 4) }, "side \(n) degrees")
        }
    }

    @Test("chordalCycle: the cycle and a chord from each x ≥ 1 to its inverse mod p; directed both arcs")
    func chordalCycle() async {
        let primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
        await propertyCheck(count: 40, input: Gen.int(in: 0 ..< primes.count)) { index in
            let p = primes[index]
            var reference = Set<[Int]>()
            for x in 0 ..< p where (x + 1) % p != x { reference.insert([min(x, (x + 1) % p), max(x, (x + 1) % p)]) }
            for x in 1 ..< p {
                let inverse = (1 ..< p).first { x * $0 % p == 1 }!
                if inverse != x { reference.insert([min(x, inverse), max(x, inverse)]) }
            }
            let pairs = reference.sorted { $0.lexicographicallyPrecedes($1) }
            let undirected: [[[Int]]] = [UndirectedAdjacencyList<Int>.chordalCycle(prime: p).edges.map { [$0.u, $0.v] },
                                         Pseudograph<Int>.chordalCycle(prime: p).edges.map { [$0.u, $0.v] }]
            #expect(undirected.allSatisfy { $0 == pairs }, "p \(p)")
            let arcs = (pairs + pairs.map { [$0[1], $0[0]] }).sorted { $0.lexicographicallyPrecedes($1) }
            let directed: [[[Int]]] = [CompressedSparseRow.chordalCycle(prime: p).edges.map { [$0.source, $0.target] },
                                       AdjacencyList<Int>.chordalCycle(prime: p).edges.map { [$0.source, $0.target] }]
            #expect(directed.allSatisfy { $0 == arcs }, "p \(p) directed")
            // Every vertex has 2 or 3 neighbors (the ends of the cycle and at most one chord), and
            // 0, 1 and p − 1 have no chord for p ≥ 5.
            let graph = UndirectedAdjacencyList<Int>.chordalCycle(prime: p)
            #expect((0 ..< p).allSatisfy { (min(2, p - 1) ... 3).contains(graph.degree(of: $0)) }, "p \(p) degrees")
            if p >= 5 {
                let chordless = [0, 1, p - 1].map { graph.degree(of: $0) }
                #expect(chordless == [2, 2, 2], "p \(p) chordless vertices")
            }
        }
    }

    @Test("paley: (p − 1)/2-regular, self-complementary (a nonsquare multiplier maps it onto its complement); directed both arcs")
    func paley() async {
        let primes = [5, 13, 17, 29, 37, 41, 53, 61, 73, 89, 97, 101, 109, 113]
        await propertyCheck(count: 30, input: Gen.int(in: 0 ..< primes.count)) { index in
            let p = primes[index]
            var squares = Set<Int>()
            for x in 1 ..< p { squares.insert(x * x % p) }
            var reference: [[Int]] = []
            for x in 0 ..< p { for y in x + 1 ..< p where squares.contains((y - x) % p) { reference.append([x, y]) } }
            let undirected: [[[Int]]] = [UndirectedAdjacencyList<Int>.paley(prime: p).edges.map { [$0.u, $0.v] },
                                         Multigraph<Int>.paley(prime: p).edges.map { [$0.u, $0.v] }]
            #expect(undirected.allSatisfy { $0 == reference }, "p \(p)")
            let arcs = (reference + reference.map { [$0[1], $0[0]] }).sorted { $0.lexicographicallyPrecedes($1) }
            let directed: [[[Int]]] = [CompressedSparseRow.paley(prime: p).edges.map { [$0.source, $0.target] },
                                       AdjacencyMatrix.paley(prime: p).edges.map { [$0.source, $0.target] }]
            #expect(directed.allSatisfy { $0 == arcs }, "p \(p) directed")
            let graph = UndirectedAdjacencyList<Int>.paley(prime: p)
            #expect((0 ..< p).allSatisfy { graph.degree(of: $0) == (p - 1) / 2 }, "p \(p) regular")
            // x ↦ n·x for a nonsquare n sends squares to nonsquares: an edge to a non-edge.
            let nonsquare = (1 ..< p).first { !squares.contains($0) }!
            let mapped = graph.edges.allSatisfy { !graph.contains(edge: UndirectedEdge(nonsquare * $0.u % p, nonsquare * $0.v % p)) }
            #expect(mapped && graph.edgeCount * 2 == p * (p - 1) / 2, "p \(p) self-complementary")
        }
    }

    @Test("paley tournament: for p ≡ 3 (mod 4) exactly one arc between every two vertices, (p − 1)/2 out and in")
    func paleyTournament() async {
        let primes = [3, 7, 11, 19, 23, 31, 43, 47, 59, 67, 71, 79, 83]
        await propertyCheck(count: 30, input: Gen.int(in: 0 ..< primes.count)) { index in
            let p = primes[index]
            let graph = CompressedSparseRow.paley(prime: p)
            let list = AdjacencyList<Int>.paley(prime: p)
            #expect(graph.edges.map { [$0.source, $0.target] } == list.edges.map { [$0.source, $0.target] }, "p \(p) conformers")
            var oneArc = true
            for x in 0 ..< p {
                for y in x + 1 ..< p where graph.contains(edge: DirectedEdge(from: x, to: y)) == graph.contains(edge: DirectedEdge(from: y, to: x)) {
                    oneArc = false
                }
            }
            #expect(oneArc && graph.edgeCount == p * (p - 1) / 2, "p \(p) tournament")
            #expect((0 ..< p).allSatisfy { graph.outDegree(of: $0) == (p - 1) / 2 && list.inDegree(of: $0) == (p - 1) / 2 }, "p \(p) regular")
        }
    }

    @Test("_isPrime agrees with a sieve to 2000")
    func isPrime() {
        var composite = [Bool](repeating: false, count: 2001)
        for d in 2 ... 2000 where !composite[d] {
            var k = d * d
            while k <= 2000 {
                composite[k] = true
                k += d
            }
        }
        let primes = (0 ... 2000).filter { $0 >= 2 && !composite[$0] }
        #expect((0 ... 2000).filter { _isPrime($0) } == primes)
        #expect(!_isPrime(-7) && !_isPrime(1_000_001) && _isPrime(1_000_003))
    }
}
