// Large inputs, each inside a Task with a one-minute limit, meant to finish within seconds in a
// debug build; the benchmarks take timings. Every expected value is a closed form or a theorem:
// grids, where λ₂ is tiny against the spectrum's width (SciPy's `eigsh(which="SA")` returns a
// wrong λ₂ on the 100 × 100 grid, api.md) and the square grid's λ₂ is double; random 3-regular
// multigraphs, whose λ₂ is 3 − 2√2 up to o(1) (Alon–Boppana and Friedman) and whose spectral radius
// is 3; spanning-tree counts of K_n up to and past Double's range; resistances on a cycle and a
// weighted binary tree; and the matrices of a 300 × 300 grid. See README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory at scale")
struct SpectralStressTests {
    @Test("Grid 100 × 100: λ₂ = 2 − 2cos(π/100) (double), not SciPy's 0.00888; ρ(A) = 4cos(π/101)", .timeLimit(.minutes(1)))
    func squareGrid() async throws {
        try await Task {
            let side = 100
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< side {
                for j in 0 ..< side {
                    let v = i * side + j
                    if j + 1 < side { edges.append(UndirectedEdge(v, v + 1)) }
                    if i + 1 < side { edges.append(UndirectedEdge(v, v + side)) }
                }
            }
            let graph = ReferencePseudograph(vertices: Array(0 ..< side * side), edges: edges)
            let pi = 3.141592653589793
            // 2 − 2cos(π/100), written as 4 sin²(π/200) to keep the digits.
            var s = pi / 200
            var sine = 0.0
            var term = s
            for k in 1 ... 12 {
                sine += term
                term *= -(s * s) / Double((2 * k) * (2 * k + 1))
            }
            let lambda2 = 4 * sine * sine
            #expect(abs(lambda2 - 0.000986879268) <= 1e-12)
            let scale = 8.0
            let value = try graph.algebraicConnectivity()
            #expect(abs(value - lambda2) <= 1e-6 * scale)
            #expect(abs(value - 0.00887607) > 1e-3)
            // The Fiedler vector of a double λ₂: only invariants.
            let fiedler = try #require(try graph.fiedlerVector())
            #expect(abs(fiedler.algebraicConnectivity - lambda2) <= 1e-6 * scale)
            let x = fiedler.values
            #expect(x.count == side * side)
            #expect(abs(x.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
            #expect(abs(x.reduce(0, +)) <= 1e-6)
            let lx = graph.laplacianMatrix() * x
            let residual = zip(lx, x).reduce(0) { $0 + ($1.0 - fiedler.algebraicConnectivity * $1.1) * ($1.0 - fiedler.algebraicConnectivity * $1.1) }
            #expect(residual.squareRoot() <= 1e-6 * scale)
            // ρ(A) = 2 · 2cos(π/101).
            s = pi / 101
            var cosine = 0.0
            term = 1
            for k in 1 ... 12 {
                cosine += term
                term *= -(s * s) / Double((2 * k - 1) * (2 * k))
            }
            let radius = try graph.spectralRadius()
            #expect(abs(radius - 4 * cosine) <= 1e-6 * 4)
            #expect(abs(radius - 3.99807) <= 1e-4)
        }.value
    }

    @Test("Grid 120 × 30: λ₂ = 2 − 2cos(π/120) is simple; the Fiedler vector is cos(π(i + ½)/120) by row; the ordering goes row by row", .timeLimit(.minutes(1)))
    func rectangularGrid() async throws {
        try await Task {
            let rows = 120, columns = 30
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< rows {
                for j in 0 ..< columns {
                    let v = i * columns + j
                    if j + 1 < columns { edges.append(UndirectedEdge(v, v + 1)) }
                    if i + 1 < rows { edges.append(UndirectedEdge(v, v + columns)) }
                }
            }
            let graph = ReferencePseudograph(vertices: Array(0 ..< rows * columns), edges: edges)
            let pi = 3.141592653589793
            func sine(_ t: Double) -> Double {
                var sum = 0.0
                var term = t
                for k in 1 ... 16 {
                    sum += term
                    term *= -(t * t) / Double((2 * k) * (2 * k + 1))
                }
                return sum
            }
            let lambda2 = 4 * sine(pi / 240) * sine(pi / 240)
            let scale = 8.0
            #expect(abs(try graph.algebraicConnectivity() - lambda2) <= 1e-6 * scale)
            let fiedler = try #require(try graph.fiedlerVector())
            #expect(abs(fiedler.algebraicConnectivity - lambda2) <= 1e-6 * scale)
            // x[i·30 + j] = cos(π(i + ½)/120) / √(60 · 30): constant along a row, first entry positive.
            let norm = (60.0 * 30).squareRoot()
            var worst = 0.0
            for i in 0 ..< rows {
                // cos(π(i + ½)/120) = sin(π/2 − π(i + ½)/120), reduced into [−π/2, π/2].
                let expected = sine(pi / 2 - pi * (Double(i) + 0.5) / 120) / norm
                for j in 0 ..< columns { worst = max(worst, abs(fiedler.value(of: i * columns + j) - expected)) }
            }
            #expect(worst <= 1e-5)
            // Ascending: the last row first; a row's 30 vertices are tied, so only the blocks are pinned.
            let order = try graph.spectralOrdering()
            #expect(order.count == rows * columns)
            for k in 0 ..< rows {
                let block = order[k * columns ..< (k + 1) * columns].sorted()
                let row = rows - 1 - k
                #expect(block == Array(row * columns ..< (row + 1) * columns), "block \(k)")
            }
        }.value
    }

    @Test("Random 3-regular multigraph on 10⁴ vertices: λ₂ ≈ 3 − 2√2, ρ(A) = 3, and the Fiedler pair's residual", .timeLimit(.minutes(1)))
    func randomRegular() async throws {
        try await Task {
            // Three random perfect matchings: every degree is exactly 3 (parallel edges possible).
            let n = 10_000
            var rng = SeededRandomNumberGenerator(seed: 2026)
            var edges: [UndirectedEdge<Int>] = []
            for _ in 0 ..< 3 {
                let perm = Array(0 ..< n).shuffled(using: &rng)
                for k in stride(from: 0, to: n, by: 2) { edges.append(UndirectedEdge(perm[k], perm[k + 1])) }
            }
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            let lambda2 = try graph.algebraicConnectivity()
            // 3 − 2√2 = 0.17157…; for n = 10⁴ the observed λ₂ is within a few thousandths of it.
            let bound = 3 - 2 * 2.0.squareRoot()
            #expect(abs(lambda2 - bound) <= 0.03)
            #expect(abs(try graph.spectralRadius() - 3) <= 1e-6 * 3)
            let fiedler = try #require(try graph.fiedlerVector())
            #expect(abs(fiedler.algebraicConnectivity - lambda2) <= 1e-6 * 6)
            let x = fiedler.values
            #expect(abs(x.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)
            #expect(abs(x.reduce(0, +)) <= 1e-6)
            let lx = graph.laplacianMatrix() * x
            let residual = zip(lx, x).reduce(0) { $0 + ($1.0 - fiedler.algebraicConnectivity * $1.1) * ($1.0 - fiedler.algebraicConnectivity * $1.1) }
            #expect(residual.squareRoot() <= 1e-6 * 6)
            let rayleigh = zip(lx, x).reduce(0) { $0 + $1.0 * $1.1 }
            #expect(abs(rayleigh - lambda2) <= 1e-6 * 6)
            // Normalized: N = L / 3 for a 3-regular graph.
            #expect(abs(try graph.algebraicConnectivity(normalized: true) - lambda2 / 3) <= 1e-6 * 2)
        }.value
    }

    @Test("Spanning trees of K_n: n^(n−2) up to K₁₄₀ (about 10²⁹⁶), infinity past Double's range (K₂₀₀)", .timeLimit(.minutes(1)))
    func spanningTreesPastDouble() async throws {
        await Task {
            for n in [30, 140, 200] {
                var edges: [UndirectedEdge<Int>] = []
                for i in 0 ..< n { for j in i + 1 ..< n { edges.append(UndirectedEdge(i, j)) } }
                let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
                let expected = (0 ..< n - 2).reduce(1.0) { product, _ in product * Double(n) }
                let count = graph.numberOfSpanningTrees()
                if expected.isFinite {
                    #expect(abs(count - expected) <= 1e-9 * expected, "K\(n)")
                } else {
                    #expect(count == .infinity, "K\(n)")
                }
            }
        }.value
    }

    @Test("Resistances: a cycle of 2 000 (k(n − k)/n) and a binary tree of 2¹⁴ − 1 vertices with conductances by depth", .timeLimit(.minutes(1)))
    func resistancesAtScale() async throws {
        try await Task {
            let n = 2_000
            let cycle = ReferencePseudograph(vertices: Array(0 ..< n), edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            for k in [1, 500, 1_000] {
                let expected = Double(k * (n - k)) / Double(n)
                let r = try cycle.resistanceDistance(from: 0, to: k)
                #expect(r.map { abs($0 - expected) <= 1e-6 * max(1, expected) } == true, "R(0, \(k))")
            }
            // Heap order: the parent of v is (v − 1)/2; the edge into a vertex at depth d conducts 1 + d.
            let depth = 13
            let count = (1 << (depth + 1)) - 1
            var edges: [UndirectedEdge<Int>] = []
            var weights: [Double] = []
            for v in 1 ..< count {
                var d = 0
                var x = v + 1
                while x > 1 { x >>= 1; d += 1 }
                edges.append(UndirectedEdge((v - 1) / 2, v))
                weights.append(Double(1 + d))
            }
            let tree = ReferencePseudograph(vertices: Array(0 ..< count), edges: edges)
            let expected = 2 * (1 ... depth).reduce(0.0) { $0 + 1 / Double(1 + $1) }
            let leftmost = (1 << depth) - 1, rightmost = count - 1
            let r = try tree.resistanceDistance(from: leftmost, to: rightmost, weight: { weights[$0] })
            #expect(r.map { abs($0 - expected) <= 1e-6 * max(1, expected) } == true)
        }.value
    }

    @Test("K₂₀₀: effective graph resistance n − 1, Kemeny constant (n − 1)²/n", .timeLimit(.minutes(1)))
    func completeGraphElectrical() async throws {
        await Task {
            let n = 200
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< n { for j in i + 1 ..< n { edges.append(UndirectedEdge(i, j)) } }
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            #expect(graph.effectiveGraphResistance().map { abs($0 - 199) <= 1e-9 * 199 } == true)
            let kemeny = 199.0 * 199 / 200
            #expect(graph.kemenyConstant().map { abs($0 - kemeny) <= 1e-9 * kemeny } == true)
        }.value
    }

    @Test("Grid 300 × 300 matrices: nnz n + 2m, trace 2m, rows summing to 0, columns ascending", .timeLimit(.minutes(1)))
    func gridMatrices() async throws {
        await Task {
            let side = 300
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< side {
                for j in 0 ..< side {
                    let v = i * side + j
                    if j + 1 < side { edges.append(UndirectedEdge(v, v + 1)) }
                    if i + 1 < side { edges.append(UndirectedEdge(v, v + side)) }
                }
            }
            let n = side * side, m = edges.count
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            let laplacian = graph.laplacianMatrix()
            #expect(laplacian.rowCount == n && laplacian.nonzeroCount == n + 2 * m)
            #expect(laplacian.values.reduce(0, +) == 0)
            #expect((0 ..< n).reduce(0.0) { $0 + laplacian[$1, $1] } == Double(2 * m))
            #expect(laplacian * [Double](repeating: 1, count: n) == [Double](repeating: 0, count: n))
            var ascending = true
            for i in 0 ..< n {
                let lo = laplacian.offsets[i], hi = laplacian.offsets[i + 1]
                for k in lo + 1 ..< max(lo + 1, hi) where laplacian.columns[k - 1] >= laplacian.columns[k] { ascending = false }
            }
            #expect(ascending)
            let adjacency = graph.adjacencyMatrix()
            #expect(adjacency.nonzeroCount == 2 * m && adjacency.values.allSatisfy { $0 == 1 })
            #expect(adjacency.pattern.edgeCount == 2 * m && adjacency.pattern.vertexCount == n)
        }.value
    }
}
