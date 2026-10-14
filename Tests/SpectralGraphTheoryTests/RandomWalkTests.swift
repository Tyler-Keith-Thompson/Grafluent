// Random walks: the stationary distribution of a directed graph (hand-computed chains, dangling
// vertices, closed classes, weights, limits), and hitting and commute times on undirected graphs
// (hand-computed, closed forms on paths and complete graphs, loops, components, and commute time
// against vol · R and the two hitting times).

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import SpectralGraphTheory
import Testing

/// A directed graph with no vertex or edge indices: only the protocol's vertex-level members.
private struct UnindexedDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]

    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
}

@Suite("Random walks")
struct RandomWalkTests {
    @Test("A directed cycle: uniform; both arcs of an undirected path: d / vol")
    func reversibleChains() throws {
        let cycle = AdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 5).map { DirectedEdge(from: $0, to: ($0 + 1) % 5) })
        let uniform = try cycle.stationaryDistribution()
        #expect(uniform.probabilities.allSatisfy { abs($0 - 0.2) < 1e-12 })
        // P4 as a digraph: degrees 1, 2, 2, 1 over 6.
        let path = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let pi = try path.stationaryDistribution()
        let expected = [1.0, 2, 2, 1].map { $0 / 6 }
        for v in 0 ..< 4 { #expect(abs(pi.probabilities[v] - expected[v]) < 1e-10, "π(\(v))") }
        #expect(abs(pi.probabilities.reduce(0, +) - 1) < 1e-14)
    }

    @Test("A bipartite walk (period 2) converges through the lazy walk")
    func periodic() throws {
        // The star with both arcs per edge: π = (3, 1, 1, 1) / 6, though P has period 2.
        let star = AdjacencyList(vertices: 0 ..< 4, edges: (1 ..< 4).flatMap { [DirectedEdge(from: 0, to: $0), DirectedEdge(from: $0, to: 0)] })
        let pi = try star.stationaryDistribution()
        #expect(abs(pi.probability(of: 0) - 0.5) < 1e-10)
        for v in 1 ..< 4 { #expect(abs(pi.probability(of: v) - 1.0 / 6) < 1e-10) }
    }

    @Test("A dangling vertex jumps uniformly: 0 → 1 with 1 dangling gives (1/3, 2/3)")
    func dangling() throws {
        // π₀ = π₁/2, π₁ = π₀ + π₁/2.
        let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        let pi = try graph.stationaryDistribution()
        #expect(abs(pi.probabilities[0] - 1.0 / 3) < 1e-11 && abs(pi.probabilities[1] - 2.0 / 3) < 1e-11)
        // No arcs at all: uniform. One vertex: 1.
        let isolated = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [])
        #expect(try isolated.stationaryDistribution().probabilities.allSatisfy { abs($0 - 1.0 / 3) < 1e-15 })
        #expect(try AdjacencyList<Int>(vertices: 0 ..< 1, edges: []).stationaryDistribution().probabilities == [1])
        // A weight-0 arc is no arc: its tail dangles.
        let zero = try graph.stationaryDistribution(weight: { _ in 0 })
        #expect(zero.probabilities.allSatisfy { abs($0 - 0.5) < 1e-15 })
    }

    @Test("Weights and loops: P = [[1/4, 3/4], [1, 0]] has π = (4, 3) / 7")
    func weightsAndLoops() throws {
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let weights = [1, 3, 5]
        let pi = try graph.stationaryDistribution(weight: { weights[$0] })
        #expect(abs(pi.probabilities[0] - 4.0 / 7) < 1e-10 && abs(pi.probabilities[1] - 3.0 / 7) < 1e-10)
        let floating = try graph.stationaryDistribution(weight: { Double(weights[$0]) })
        #expect(floating.probabilities == pi.probabilities)
        // Parallel arcs add up as weights do.
        let parallel = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let counted = try parallel.stationaryDistribution()
        #expect(abs(counted.probabilities[0] - 4.0 / 7) < 1e-10)
    }

    @Test("Two closed classes: the limit from the uniform distribution splits the mass as it starts")
    func closedClasses() throws {
        // Two directed 2-cycles and a vertex 4 feeding both equally.
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0), DirectedEdge(from: 4, to: 2)])
        let pi = try graph.stationaryDistribution()
        // Each class starts with 2/5 and gains half of 1/5.
        for v in 0 ..< 4 { #expect(abs(pi.probabilities[v] - 0.25) < 1e-10, "π(\(v))") }
        #expect(pi.probabilities[4] < 1e-10)
    }

    @Test("CompressedSparseRow and a digraph without indices agree with AdjacencyList; checked lookups")
    func representations() throws {
        let arcs = [(0, 1), (1, 2), (2, 0), (2, 1), (1, 3)]
        let list = AdjacencyList(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let csr = CompressedSparseRow(list)
        let names = ["p", "q", "r", "s"]
        let unindexed = UnindexedDigraph(vertices: names, edges: arcs.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
        let reference = try list.stationaryDistribution()
        let fromCSR = try csr.stationaryDistribution()
        let named = try unindexed.stationaryDistribution()
        for v in 0 ..< 4 {
            #expect(abs(fromCSR.probability(ofIndex: v) - reference.probability(of: v)) < 1e-14)
            #expect(abs(named.probability(of: names[v]) - reference.probability(of: v)) < 1e-14)
            #expect(try reference.probability(checked: v) == reference.probability(of: v))
            #expect(try named.probability(checked: names[v]) == named.probability(of: names[v]))
        }
        #expect(throws: VertexNotFound.self) { try reference.probability(checked: 9) }
        #expect(throws: VertexNotFound.self) { try named.probability(checked: "z") }
        // πP = π on this chain (3 dangles).
        let pi = reference.probabilities
        var next = [Double](repeating: pi[3] / 4, count: 4)
        next[1] += pi[0]
        next[2] += pi[1] / 2
        next[3] += pi[1] / 2
        next[0] += pi[2] / 2
        next[1] += pi[2] / 2
        for v in 0 ..< 4 { #expect(abs(next[v] - pi[v]) < 1e-11) }
    }

    @Test("The empty digraph has the empty distribution; maxIterations throws NoConvergence")
    func limits() throws {
        #expect(try AdjacencyList<Int>(vertices: 0 ..< 0, edges: []).stationaryDistribution().probabilities.isEmpty)
        let path = AdjacencyList(vertices: 0 ..< 50, edges: (0 ..< 49).flatMap { [DirectedEdge(from: $0, to: $0 + 1), DirectedEdge(from: $0 + 1, to: $0)] })
        do throws(NoConvergence) {
            _ = try path.stationaryDistribution(maxIterations: 3)
            Issue.record("No NoConvergence")
        } catch {
            #expect(error.iterations == 3 && error.residual > 1e-12)
        }
        // A larger limit answers as the default does.
        #expect(try path.stationaryDistribution().probabilities == path.stationaryDistribution(maxIterations: 1_000_000).probabilities)
    }

    @Test("Hitting times on P3: h(0 → 2) = 4, h(1 → 0) = 3, h(0 → 1) = 1; commute 0 ↔ 2 is 8")
    func pathOfThree() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(abs(try #require(try graph.hittingTime(from: 0, to: 2)) - 4) < 1e-9)
        #expect(abs(try #require(try graph.hittingTime(from: 1, to: 0)) - 3) < 1e-9)
        #expect(abs(try #require(try graph.hittingTime(from: 0, to: 1)) - 1) < 1e-9)
        #expect(try graph.hittingTime(from: 1, to: 1) == 0)
        #expect(abs(try #require(try graph.commuteTime(from: 0, to: 2)) - 8) < 1e-9)
        #expect(abs(try #require(try graph.commuteTime(from: 2, to: 0)) - 8) < 1e-9)
        #expect(try graph.commuteTime(from: 2, to: 2) == 0)
    }

    @Test("Closed forms: h(0 → n − 1) = (n − 1)² on P_n; h(u → v) = n − 1 on K_n")
    func closedForms() throws {
        for n in [2, 10, 150] {
            let path = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let h = try #require(try path.hittingTime(from: 0, to: n - 1))
            #expect(abs(h - Double((n - 1) * (n - 1))) <= 1e-8 * Double(n * n), "P\(n)")
        }
        var edges: [UndirectedEdge<Int>] = []
        for u in 0 ..< 12 { for v in u + 1 ..< 12 { edges.append(UndirectedEdge(u, v)) } }
        let complete = UndirectedAdjacencyList(vertices: 0 ..< 12, edges: edges)
        #expect(abs(try #require(try complete.hittingTime(from: 3, to: 7)) - 11) < 1e-8)
        // κ = 2m · R = 132 · 2/12.
        #expect(abs(try #require(try complete.commuteTime(from: 3, to: 7)) - 22) < 1e-8)
    }

    @Test("A loop slows the walk: K2 with a loop at 0 has h(0 → 1) = 3, h(1 → 0) = 1, commute 4 = vol · R")
    func loops() throws {
        let graph = Pseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        #expect(abs(try #require(try graph.hittingTime(from: 0, to: 1)) - 3) < 1e-9)
        #expect(abs(try #require(try graph.hittingTime(from: 1, to: 0)) - 1) < 1e-9)
        #expect(abs(try #require(try graph.commuteTime(from: 0, to: 1)) - 4) < 1e-9)
        // Weighted: loop 2, edge 1: d₀ = 5, so h(0 → 1) = 5; vol 6, R 1.
        #expect(abs(try #require(try graph.hittingTime(from: 0, to: 1, weight: { [2, 1][$0] })) - 5) < 1e-9)
        #expect(abs(try #require(try graph.commuteTime(from: 1, to: 0, weight: { [2.0, 1][$0] })) - 6) < 1e-9)
    }

    @Test("Weights near Double's limits leave hitting times unchanged and scale nothing")
    func extremeWeights() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 1)])
        let plain = try #require(try graph.hittingTime(from: 0, to: 3))
        for c in [1e300, 1e-300] {
            let scaled = try #require(try graph.hittingTime(from: 0, to: 3, weight: { _ in c }))
            #expect(abs(scaled - plain) <= 1e-9 * plain, "c \(c)")
            let commute = try #require(try graph.commuteTime(from: 0, to: 3, weight: { _ in c }))
            #expect(abs(commute - (try #require(try graph.commuteTime(from: 0, to: 3)))) <= 1e-9 * commute, "c \(c)")
        }
    }

    @Test("Across components: nil; the volume is the component's")
    func components() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        #expect(try graph.hittingTime(from: 0, to: 2) == nil)
        #expect(try graph.commuteTime(from: 1, to: 4) == nil)
        // P3 on 2, 3, 4 alone: κ(2, 4) = 4 · 2.
        #expect(abs(try #require(try graph.commuteTime(from: 2, to: 4)) - 8) < 1e-9)
        #expect(abs(try #require(try graph.hittingTime(from: 2, to: 4)) - 4) < 1e-9)
        // A weight-0 edge does not connect.
        #expect(try graph.hittingTime(from: 0, to: 1, weight: { $0 == 0 ? 0 : 1 }) == nil)
    }

    @Test("commuteTime is the sum of the two hitting times on a weighted multigraph")
    func commuteIsTwoHittingTimes() throws {
        let graph = Pseudograph(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 5), UndirectedEdge(2, 5)])
        let weights = [1.0, 2, 0.5, 3, 1, 4, 2, 1.5, 0.25]
        for (s, t) in [(0, 5), (1, 4), (2, 3), (5, 0)] {
            let there = try #require(try graph.hittingTime(from: s, to: t, weight: { weights[$0] }))
            let back = try #require(try graph.hittingTime(from: t, to: s, weight: { weights[$0] }))
            let commute = try #require(try graph.commuteTime(from: s, to: t, weight: { weights[$0] }))
            #expect(abs(there + back - commute) <= 1e-8 * commute, "\(s) ↔ \(t)")
        }
    }

    @Test("maxIterations: hitting time throws NoConvergence after the iterations given")
    func hittingLimits() throws {
        let path = UndirectedAdjacencyList(vertices: 0 ..< 100, edges: (0 ..< 99).map { UndirectedEdge($0, $0 + 1) })
        do throws(NoConvergence) {
            _ = try path.hittingTime(from: 0, to: 99, maxIterations: 2)
            Issue.record("No NoConvergence")
        } catch {
            #expect(error.iterations == 2 && error.residual > 1e-10)
        }
        #expect(throws: NoConvergence.self) { try path.commuteTime(from: 0, to: 99, maxIterations: 2) }
    }
}
