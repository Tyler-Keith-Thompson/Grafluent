// Large shapes, each inside a Task with a one-minute limit, meant to finish within a few seconds in a
// debug build; the benchmarks take timings. Every expected value is known by construction or is
// Connectivity's result on the incidence graph: 2 × 10⁴ vertices and 4 × 10⁴ hyperedges of sizes
// 2–8 (components, the handshake law, the s-line graph at s = 2), a directed chain of 10⁴ Horn
// clauses for B- and F-Visit, a directed cycle of 10⁴ hyperedges for strong components, and 10⁴
// counted vertices whose whole-hypergraph algorithms hash nothing. See README.md.

import Connectivity
import GrafluentTestSupport
import GraphProtocols
import Hypergraphs
import Testing
import Traversal

@Suite("Hypergraphs at scale")
struct HypergraphStressTests {
    @Test("2 × 10⁴ vertices, 4 × 10⁴ hyperedges: components equal the incidence graph's", .timeLimit(.minutes(1)))
    func undirectedAtScale() async {
        await Task {
            let n = 20_000, m = 40_000
            var rng = SeededRandomNumberGenerator(seed: 17)
            var hypergraph = UndirectedIncidenceList<Int>(vertices: 0 ..< n)
            hypergraph.reserveCapacity(vertexCount: n, hyperedgeCount: m, incidenceCount: 5 * m)
            // Hyperedges stay inside blocks of 1 000 vertices, so the components are the 20 blocks.
            for p in 0 ..< m {
                let block = (p % 20) * 1_000
                hypergraph.insert(hyperedge: (0 ..< Int.random(in: 2 ... 8, using: &rng)).map { _ in block + Int.random(in: 0 ..< 1_000, using: &rng) })
            }
            for block in 0 ..< 20 { hypergraph.insert(hyperedge: Array(stride(from: block * 1_000, to: block * 1_000 + 1_000, by: 1))) }
            #expect(hypergraph.vertexCount == n && hypergraph.hyperedgeCount == m + 20)
            let sizes = (0 ..< hypergraph.hyperedgeCount).reduce(0) { $0 + hypergraph.size(ofHyperedgeAt: $1) }
            let degrees = (0 ..< n).reduce(0) { $0 + hypergraph.degree(ofIndex: $1) }
            #expect(sizes == degrees)
            let components = hypergraph.connectedComponents()
            #expect(components.count == 20 && components.allSatisfy { $0.count == 1_000 })
            #expect(components.map { $0.first! } == Array(stride(from: 0, to: n, by: 1_000)))
            let view = hypergraph.incidenceGraphView
            #expect(view.vertexCount == n + m + 20 && view.edgeCount == sizes)
            #expect(view.connectedComponents().count == 20)
            let reached = view.directedView.lazy.breadthFirstSearch(from: 0).reduce(0) { count, event in
                if case .discover = event { return count + 1 }
                return count
            }
            #expect(reached == 1_000 + m / 20 + 1)
            // s = 2: the s-components are the line graph's components.
            let line = hypergraph.lineGraph(s: 2)
            #expect(line.vertexCount == m + 20)
            #expect(hypergraph.sConnectedComponents(s: 2).count == line.connectedComponents().count)
            #expect(hypergraph.dual().hyperedgeCount == n)
        }.value
    }

    @Test("A directed chain of 10⁴ Horn clauses: B-Visit fires every one, F-Visit walks back", .timeLimit(.minutes(1)))
    func directedChainAtScale() async {
        await Task {
            let n = 10_000
            // {x_i, key} → {x_{i+1}}, and {x_0} → {key}: from x_0 everything; from x_1 only x_1.
            var hypergraph = IncidenceList<Int>(vertices: 0 ... n)
            let key = n
            hypergraph.insert(sources: [0], targets: [key])
            for i in 0 ..< n - 1 { hypergraph.insert(sources: [i, key], targets: [i + 1]) }
            #expect(hypergraph.bConnectedVertices(from: 0).count == n + 1)
            #expect(hypergraph.bConnectedVertices(from: 1) == [1])
            #expect(hypergraph.isBConnected(from: 0, to: n - 1) && !hypergraph.isBConnected(from: 1, to: 2))
            #expect(hypergraph.fConnectedVertices(to: n - 1).count == n + 1)
            #expect(hypergraph.isFConnected(from: 0, to: n - 1) && hypergraph.isBHypergraph && !hypergraph.isFHypergraph)
            #expect(hypergraph.weaklyConnectedComponents().count == 1)
            #expect(hypergraph.stronglyConnectedComponents().count == n + 1)
            #expect(hypergraph.reversed.bConnectedVertices(from: n - 1).count == n + 1)
        }.value
    }

    @Test("A directed cycle of 10⁴ hyperedges is one strong component; the view agrees", .timeLimit(.minutes(1)))
    func directedCycleAtScale() async {
        await Task {
            let n = 10_000
            var hypergraph = IncidenceList<Int>(vertices: 0 ..< n)
            for i in 0 ..< n { hypergraph.insert(sources: [i], targets: [(i + 1) % n, (i + 7) % n]) }
            #expect(hypergraph.stronglyConnectedComponents().count == 1 && hypergraph.isStronglyConnected)
            #expect(hypergraph.incidenceGraphView.stronglyConnectedComponents().count == 1)
            #expect(hypergraph.bConnectedVertices(from: 0).count == n)
            // Backwards, a hyperedge fires only once both its targets are reached.
            #expect(hypergraph.fConnectedVertices(to: 0) == hypergraph.reversed.bConnectedVertices(from: 0))
            #expect(hypergraph.dual().dual() == hypergraph)
            #expect(hypergraph.cliqueExpansion().edgeCount == 2 * n)
        }.value
    }

    @Test("10⁴ counted vertices: whole-hypergraph algorithms hash nothing", .timeLimit(.minutes(1)))
    func countedAtScale() async {
        await Task {
            final class Tally: @unchecked Sendable {
                var hashes = 0
            }
            struct Counted: Hashable {
                let name: Int
                let tally: Tally
                static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }
                func hash(into hasher: inout Hasher) {
                    tally.hashes += 1
                    hasher.combine(name)
                }
            }
            let tally = Tally()
            let n = 10_000
            let undirected = UndirectedIncidenceList(vertices: (0 ..< n).map { Counted(name: $0, tally: tally) },
                                                     hyperedges: (0 ..< n).map { i in [i, (i + 1) % n, (i * 7) % n].map { Counted(name: $0, tally: tally) } })
            let directed = IncidenceList(vertices: (0 ..< n).map { Counted(name: $0, tally: tally) },
                                         hyperedges: (0 ..< n).map { i in (sources: [Counted(name: i, tally: tally)], targets: [Counted(name: (i + 1) % n, tally: tally)]) })
            tally.hashes = 0
            #expect(undirected.connectedComponents().count == 1 && undirected.isConnected)
            #expect(undirected.sConnectedComponents(s: 2).count >= 1 && undirected.dual().vertexCount == n)
            #expect(undirected.incidenceGraphView.connectedComponents().count == 1)
            #expect(directed.stronglyConnectedComponents().count == 1 && directed.weaklyConnectedComponents().count == 1)
            #expect(directed.incidenceGraphView.stronglyConnectedComponents().count == 1)
            #expect(tally.hashes == 0)
            #expect(directed.bConnectedVertices(from: Counted(name: 0, tally: tally)).count == n)
            #expect(tally.hashes == 1)
        }.value
    }
}
