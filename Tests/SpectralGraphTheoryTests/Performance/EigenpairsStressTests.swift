// Large inputs under a time limit: eigenpairs by Lanczos on the 70 × 70 grid and on 10⁴
// vertices, the stationary distribution of a 10⁵-vertex digraph, hitting and commute times on a long cycle, and the
// incidence matrix of the 300 × 300 grid.

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("Eigenpairs and random walks at scale")
struct EigenpairsStressTests {
    @Test("Grid 70 × 70: L's 4 smallest are 0, the double 2 − 2cos(π/70), then 4 − 4cos(π/70)", .timeLimit(.minutes(1)))
    func gridLaplacian() throws {
        let side = 70
        var edges: [UndirectedEdge<Int>] = []
        for r in 0 ..< side {
            for c in 0 ..< side {
                if c + 1 < side { edges.append(UndirectedEdge(r * side + c, r * side + c + 1)) }
                if r + 1 < side { edges.append(UndirectedEdge(r * side + c, (r + 1) * side + c)) }
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: edges)
        var all: [Double] = []
        for i in 0 ..< 4 { for j in 0 ..< 4 { all.append(4 - 2 * cos(Double.pi * Double(i) / Double(side)) - 2 * cos(Double.pi * Double(j) / Double(side))) } }
        all.sort()
        let pairs = try graph.laplacianEigenpairs(smallest: 4)
        for i in 0 ..< 4 { #expect(abs(pairs.eigenvalues[i] - all[i]) <= 1e-7 * max(all[i], 1e-9), "λ\(i)") }
        let largest = try graph.adjacencyEigenpairs(largest: 3)
        let top = 4 * cos(Double.pi / Double(side + 1))
        #expect(abs(largest.eigenvalues[0] - top) < 1e-7)
        #expect(abs(largest.eigenvalues[1] - (2 * cos(Double.pi / Double(side + 1)) + 2 * cos(2 * Double.pi / Double(side + 1)))) < 1e-7)
        #expect(abs(largest.eigenvalues[2] - largest.eigenvalues[1]) < 1e-7)
    }

    @Test("A random 3-regular multigraph on 10⁴ vertices: L's 6 smallest, orthonormal, with small residuals", .timeLimit(.minutes(1)))
    func randomRegular() throws {
        let n = 10_000
        var rng = SeededRandomNumberGenerator(seed: 21)
        var edges: [UndirectedEdge<Int>] = []
        for _ in 0 ..< 3 {
            let perm = Array(0 ..< n).shuffled(using: &rng)
            for i in stride(from: 0, to: n, by: 2) { edges.append(UndirectedEdge(perm[i], perm[i + 1])) }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
        let pairs = try graph.laplacianEigenpairs(smallest: 6)
        let laplacian = graph.laplacianMatrix()
        #expect(pairs.eigenvalues[0] == 0)
        for i in 1 ..< 6 {
            let x = pairs.eigenvector(at: i)
            let lx = laplacian * x
            var residual = 0.0
            for v in 0 ..< n { residual += (lx[v] - pairs.eigenvalues[i] * x[v]) * (lx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-6 * pairs.eigenvalues[i], "residual \(i)")
            #expect(pairs.eigenvalues[i] >= pairs.eigenvalues[i - 1])
            // Friedman: λ₂ near 3 − 2√2 ≈ 0.17.
            #expect(pairs.eigenvalues[i] > 0.1 && pairs.eigenvalues[i] < 0.3)
        }
    }

    @Test("The stationary distribution of a random digraph of 10⁵ vertices and 5 · 10⁵ arcs: πP = π", .timeLimit(.minutes(1)))
    func stationary() throws {
        let n = 100_000
        var rng = SeededRandomNumberGenerator(seed: 24)
        let arcs = (0 ..< 5 * n).map { _ in DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)) }
        let graph = AdjacencyList(vertices: 0 ..< n, edges: arcs)
        let pi = try graph.stationaryDistribution().probabilities
        var out = [Int](repeating: 0, count: n)
        for v in 0 ..< n { out[v] = graph.outDegree(of: v) }
        var next = [Double](repeating: 0, count: n)
        var dangling = 0.0
        for v in 0 ..< n {
            if out[v] == 0 {
                dangling += pi[v]
            } else {
                for w in graph.successors(of: v) { next[w] += pi[v] / Double(out[v]) }
            }
        }
        var residual = 0.0
        for v in 0 ..< n { residual += abs(next[v] + dangling / Double(n) - pi[v]) }
        #expect(residual <= 1e-11)
        #expect(abs(pi.reduce(0, +) - 1) < 1e-12)
    }

    @Test("C₂₀₀₀: h(0 → k) = k(n − k), commute 2n · k(n − k)/n", .timeLimit(.minutes(1)))
    func cycleHittingTimes() throws {
        let n = 2_000
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
        for k in [1, 500, 1_000] {
            let expected = Double(k * (n - k))
            let h = try #require(try graph.hittingTime(from: 0, to: k))
            #expect(abs(h - expected) <= 1e-7 * expected, "h(0 → \(k))")
            let commute = try #require(try graph.commuteTime(from: 0, to: k))
            #expect(abs(commute - 2 * expected) <= 1e-7 * expected, "κ(0, \(k))")
        }
    }

    @Test("Grid 300 × 300: the oriented incidence matrix, 2 entries per column, rows summing to out minus in", .timeLimit(.minutes(1)))
    func gridIncidence() {
        let side = 300
        var edges: [UndirectedEdge<Int>] = []
        for r in 0 ..< side {
            for c in 0 ..< side {
                if c + 1 < side { edges.append(UndirectedEdge(r * side + c, r * side + c + 1)) }
                if r + 1 < side { edges.append(UndirectedEdge(r * side + c, (r + 1) * side + c)) }
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: edges)
        let b = graph.incidenceMatrix(oriented: true)
        #expect(b.rowCount == side * side && b.columnCount == edges.count && b.nonzeroCount == 2 * edges.count)
        let sums = b * [Double](repeating: 1, count: edges.count)
        var expected = [Double](repeating: 0, count: side * side)
        for e in graph.edges {
            expected[e.u] -= 1
            expected[e.v] += 1
        }
        #expect(sums == expected)
    }
}
