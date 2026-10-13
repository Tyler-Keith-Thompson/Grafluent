// Relative accuracy where the weights spread over many orders of magnitude, against references
// that keep it: the dense λ₂ where it is accurate, power iteration on a weighted path's explicit
// grounded inverse, closed forms, series–parallel resistances and exact spanning-tree counts
// (`ref.py`'s exact determinant). Then scale invariance at c = 10^±150, and the work limits: a
// tolerance below rounding traps rather than running on. See README.md.

import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory accuracy under weight spread")
struct SpectralAccuracyTests {
    @Test("Weighted λ₂, n from 64 to 500, weights log-uniform over five decades: relative to the dense λ₂, on L and on N")
    func weightedAlgebraicConnectivity() throws {
        for (n, seed) in [(64, 1), (150, 2), (250, 3), (500, 4)] as [(Int, UInt)] {
            var rng = SeededRandomNumberGenerator(seed: seed)
            var edges = (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) }
            for _ in 0 ..< n { edges.append(UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))) }
            // 2^k · s, k uniform in −8 ... 8, s uniform in [1, 2): log-uniform over 2⁻⁸ … 2⁹.
            let weights = edges.indices.map { _ in Double(sign: .plus, exponent: Int.random(in: -8 ... 8, using: &rng), significand: Double.random(in: 1 ..< 2, using: &rng)) }
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            for normalized in [false, true] {
                let dense = try normalized ? graph.normalizedLaplacianSpectrum(weight: { weights[$0] })[1] : graph.laplacianSpectrum(weight: { weights[$0] })[1]
                let value = try graph.algebraicConnectivity(weight: { weights[$0] }, normalized: normalized)
                // The dense N carries more rounding than the dense L, so its bound is looser.
                #expect(abs(value - dense) <= (normalized ? 1e-7 : 1e-9) * dense, "n \(n), normalized \(normalized): \(value) against \(dense)")
                let fiedler = try graph.fiedlerVector(weight: { weights[$0] }, normalized: normalized)
                #expect(fiedler?.algebraicConnectivity == value, "n \(n), normalized \(normalized)")
            }
        }
    }

    @Test("Weighted paths, one edge of 10⁶ or 10¹² and log-uniform over twelve decades: λ₂ and the Fiedler vector against power iteration on L_g⁻¹")
    func heavyEdgePaths() throws {
        /// λ₂ and its unit eigenvector (canonical sign) of the path with conductances `c`: power
        /// iteration on L⁺, applied through the grounded inverse (L_g⁻¹)ᵢⱼ = Σ_{e < min(i, j)} 1/c_e.
        func reference(_ c: [Double]) -> (value: Double, vector: [Double]) {
            let n = c.count + 1
            var b = (0 ..< n).map { Double($0) - Double(n - 1) / 2 }
            var mu = 0.0
            for _ in 0 ..< 300 {
                var mean = 0.0
                for t in b { mean += t }
                mean /= Double(n)
                var length = 0.0
                for i in 0 ..< n {
                    b[i] -= mean
                    length += b[i] * b[i]
                }
                length = length.squareRoot()
                for i in 0 ..< n { b[i] /= length }
                // y = L_g⁻¹ b: y_i = Σ_{e < i} (Σ_{j > e} b_j) / c_e.
                var suffix = [Double](repeating: 0, count: n)
                for i in stride(from: n - 2, through: 0, by: -1) { suffix[i] = suffix[i + 1] + b[i + 1] }
                var y = [Double](repeating: 0, count: n)
                for i in 1 ..< n { y[i] = y[i - 1] + suffix[i - 1] / c[i - 1] }
                var yMean = 0.0
                for t in y { yMean += t }
                yMean /= Double(n)
                mu = 0
                for i in 0 ..< n {
                    y[i] -= yMean
                    mu += b[i] * y[i]
                }
                b = y
            }
            var length = 0.0
            for t in b { length += t * t }
            length = length.squareRoot()
            var largest = 0.0
            for t in b { largest = max(largest, abs(t)) }
            let sign = b.first { abs($0) >= 1e-4 * largest }! < 0 ? -1.0 : 1.0
            return (1 / mu, b.map { sign * $0 / length })
        }
        var rng = SeededRandomNumberGenerator(seed: 11)
        let spread = (0 ..< 499).map { _ in Double(sign: .plus, exponent: Int.random(in: -20 ... 20, using: &rng), significand: Double.random(in: 1 ..< 2, using: &rng)) }
        let cases: [(String, [Double])] = [
            ("300, first edge 10⁶", (0 ..< 299).map { $0 == 0 ? 1e6 : 1 }),
            ("300, first edge 10¹²", (0 ..< 299).map { $0 == 0 ? 1e12 : 1 }),
            ("1000, first edge 10⁶", (0 ..< 999).map { $0 == 0 ? 1e6 : 1 }),
            ("1000, middle edge 10¹²", (0 ..< 999).map { $0 == 500 ? 1e12 : 1 }),
            ("500, log-uniform over 2⁻²⁰ … 2²¹", spread),
        ]
        for (name, c) in cases {
            let n = c.count + 1
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let (value, vector) = reference(c)
            let lambda = try graph.algebraicConnectivity(weight: { c[$0] })
            #expect(abs(lambda - value) <= 1e-7 * value, "\(name): \(lambda) against \(value)")
            guard let fiedler = try graph.fiedlerVector(weight: { c[$0] }) else {
                Issue.record("\(name): nil on a connected path")
                continue
            }
            #expect(abs(fiedler.algebraicConnectivity - value) <= 1e-7 * value, "\(name)")
            var error = 0.0
            for i in 0 ..< n { error = max(error, abs(fiedler.values[i] - vector[i])) }
            #expect(error <= 1e-6, "\(name): Fiedler entries off by \(error)")
            // The residual for L itself, not only for the operator iterated on:
            // relative to λ₂, plus the rounding of the product, ε · max weighted degree.
            let lx = graph.laplacianMatrix(weight: { c[$0] }) * fiedler.values
            var residual = 0.0
            for i in 0 ..< n { residual += (lx[i] - fiedler.algebraicConnectivity * fiedler.values[i]) * (lx[i] - fiedler.algebraicConnectivity * fiedler.values[i]) }
            let largest = c.max()!
            #expect(residual.squareRoot() <= 1e-7 * value + 1e-14 * largest, "\(name): residual \(residual.squareRoot())")
        }
    }

    @Test("The Fiedler residual ‖Lx − λ₂x‖ is within 10⁻⁷ · λ₂ on random graphs with weights over twelve decades (shift-invert; a FuzzSpectral finding)")
    func fiedlerResidualUnderSpread() throws {
        for seed in 1 ... 12 as ClosedRange<UInt> {
            var rng = SeededRandomNumberGenerator(seed: seed)
            let n = 80
            var edges = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
            for _ in 0 ..< 20 { edges.append(UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))) }
            let weights = edges.indices.map { _ in Double(sign: .plus, exponent: Int.random(in: -20 ... 20, using: &rng), significand: Double.random(in: 1 ..< 2, using: &rng)) }
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            guard let fiedler = try graph.fiedlerVector(weight: { weights[$0] }) else {
                Issue.record("seed \(seed): nil on a connected graph")
                continue
            }
            let x = fiedler.values, lambda = fiedler.algebraicConnectivity
            let lx = graph.laplacianMatrix(weight: { weights[$0] }) * x
            var residual = 0.0
            for i in 0 ..< n { residual += (lx[i] - lambda * x[i]) * (lx[i] - lambda * x[i]) }
            var degree = [Double](repeating: 0, count: n)
            for (k, e) in edges.enumerated() where e.u != e.v {
                degree[e.u] += weights[k]
                degree[e.v] += weights[k]
            }
            // Plus the rounding of the product, ε · max weighted degree.
            #expect(residual.squareRoot() <= 1e-7 * lambda + 1e-13 * degree.max()!, "seed \(seed): residual \(residual.squareRoot()), λ₂ \(lambda)")
        }
    }

    @Test("Lanczos-sized graphs with loops and parallel edges: λ₂ of L and of N against the dense λ₂ (the shifted operators drop the loops)")
    func loopsOnTheShiftedPath() throws {
        for seed in 1 ... 3 as ClosedRange<UInt> {
            var rng = SeededRandomNumberGenerator(seed: seed)
            let n = 100
            var edges = (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) }
            for _ in 0 ..< 2 * n { edges.append(UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))) }
            for _ in 0 ..< 20 {
                let v = Int.random(in: 0 ..< n, using: &rng)
                edges.append(UndirectedEdge(v, v))
            }
            let weights = edges.indices.map { _ in Int.random(in: 1 ... 3, using: &rng) }
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            let dense = try graph.laplacianSpectrum(weight: { weights[$0] })[1]
            let value = try graph.algebraicConnectivity(weight: { weights[$0] })
            #expect(abs(value - dense) <= 1e-9 * dense, "seed \(seed): \(value) against \(dense)")
            let denseN = try graph.normalizedLaplacianSpectrum(weight: { weights[$0] })[1]
            let valueN = try graph.algebraicConnectivity(weight: { weights[$0] }, normalized: true)
            #expect(abs(valueN - denseN) <= 1e-7 * denseN, "seed \(seed), normalized: \(valueN) against \(denseN)")
        }
    }

    @Test("Negative weights on a Lanczos-sized graph: ρ is max |λ(A)|, the most negative eigenvalue when it is the larger; parallel edges of opposite weight store nothing")
    func negativeWeights() throws {
        var rng = SeededRandomNumberGenerator(seed: 13)
        let n = 90
        var edges = (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) }
        for _ in 0 ..< 2 * n { edges.append(UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))) }
        let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
        for sign in [-1, 1] {
            // All weights −1: A = −A₀, whose largest magnitude is −λ_min(A) = ρ(A₀) on a graph with odd cycles.
            let spectrum = try graph.adjacencySpectrum(weight: { _ in sign })
            let rho = max(abs(spectrum.first!), abs(spectrum.last!))
            let value = try graph.spectralRadius(weight: { _ in sign })
            #expect(abs(value - rho) <= 1e-8 * rho, "sign \(sign): \(value) against \(rho)")
        }
        let pair = ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let weights = [2.5, -2.5, 1]
        let a = pair.adjacencyMatrix(weight: { weights[$0] })
        #expect(a.nonzeroCount == 2 && a[0, 1] == 0 && a[1, 2] == 1)
    }

    @Test("Barbells (two cliques joined by a long path): λ₂ relative to the dense λ₂, on L and on N")
    func barbells() throws {
        for (k, p) in [(20, 100), (40, 300)] {
            var edges: [UndirectedEdge<Int>] = []
            for a in 0 ..< k {
                for b in a + 1 ..< k {
                    edges.append(UndirectedEdge(a, b))
                    edges.append(UndirectedEdge(k + p + a, k + p + b))
                }
            }
            for i in k - 1 ..< k + p { edges.append(UndirectedEdge(i, i + 1)) }
            let n = 2 * k + p
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            let dense = try graph.laplacianSpectrum()[1]
            let value = try graph.algebraicConnectivity()
            #expect(abs(value - dense) <= 1e-9 * dense, "K\(k) + P\(p): \(value) against \(dense)")
            let denseN = try graph.normalizedLaplacianSpectrum()[1]
            let valueN = try graph.algebraicConnectivity(normalized: true)
            #expect(abs(valueN - denseN) <= 1e-7 * denseN, "K\(k) + P\(p), normalized: \(valueN) against \(denseN)")
        }
    }

    @Test("Spanning-tree counts keep their relative accuracy: the path {h, 1} is h up to h = 10³⁰⁰, alternating 10¹² and 3 multiply out")
    func countsUnderSpread() {
        let path3 = ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        for h in [1e8, 1e15, 1e16, 1e17, 1e100, 1e300] {
            #expect(path3.numberOfSpanningTrees(weight: { $0 == 0 ? h : 1.0 }) == h, "h \(h)")
            #expect(path3.numberOfSpanningTrees(weight: { $0 == 0 ? 1.0 : h }) == h, "h \(h), heavy edge second")
        }
        for h in [100_000_000, 10_000_000_000_000_000, Int.max] {
            #expect(path3.numberOfSpanningTrees(weight: { $0 == 0 ? h : 1 }) == Double(h), "Int h \(h)")
        }
        let n = 50
        let path = ReferencePseudograph(vertices: Array(0 ..< n), edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        let weights = (0 ..< n - 1).map { $0 % 2 == 0 ? 3.0 : 1e12 }
        var exact = 1.0
        for w in weights { exact *= w }
        let count = path.numberOfSpanningTrees(weight: { weights[$0] })
        #expect(abs(count - exact) <= 1e-13 * exact, "\(count) against \(exact)")
        // A cycle with one heavy edge: τ = Σ over the edge left out of the product of the others.
        let cycle = ReferencePseudograph(vertices: Array(0 ..< 4), edges: (0 ..< 4).map { UndirectedEdge($0, ($0 + 1) % 4) })
        let c = [1e16, 1, 1, 1]
        #expect(cycle.numberOfSpanningTrees(weight: { c[$0] }) == 3e16 + 1, "cycle")
    }

    @Test("Exact spanning-tree counts between 10¹³ and 2⁵³, against ref.py's exact determinant: simple graphs, and multigraphs with loops and integer weights")
    func exactCounts() {
        let cases: [(UInt64, Int, [(Int, Int)], [Int])] = [
            (584532722743982, 23, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (2, 11), (3, 21), (13, 16), (4, 12), (3, 6), (18, 22), (3, 19), (4, 10), (10, 19), (4, 11), (8, 22), (0, 17), (1, 20), (13, 22), (3, 22), (4, 14), (0, 7), (1, 8), (0, 8), (12, 17), (0, 13), (3, 13), (17, 19), (2, 14), (1, 13), (5, 10), (13, 20), (14, 17), (9, 14), (4, 9), (3, 17), (8, 18), (1, 17), (1, 5), (7, 18), (10, 22), (1, 7), (9, 21), (1, 15), (5, 18), (3, 16), (5, 7), (15, 18), (13, 15), (3, 14)], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            (23629654327088, 26, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (17, 20), (1, 10), (8, 15), (3, 14), (0, 12), (10, 17), (14, 20), (5, 17), (0, 10), (12, 22), (1, 13), (10, 14), (2, 18), (6, 25), (14, 16), (17, 19), (2, 9), (8, 17), (6, 22), (10, 22), (5, 7), (0, 11), (16, 18), (9, 19), (7, 15), (5, 8), (12, 24), (23, 25), (11, 16), (18, 23), (7, 17), (7, 13), (7, 18)], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            (689086211383988, 30, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 26), (26, 27), (27, 28), (28, 29), (0, 22), (6, 20), (11, 28), (4, 8), (1, 12), (13, 19), (3, 24), (13, 23), (1, 20), (17, 24), (17, 23), (24, 26), (7, 15), (13, 15), (9, 21), (9, 14), (7, 11), (2, 19), (7, 27), (3, 20), (0, 2), (3, 23), (9, 26), (12, 21), (12, 27), (3, 19), (21, 24), (4, 23), (6, 12), (11, 21), (3, 12), (14, 26), (16, 23), (13, 20), (10, 23), (19, 26), (7, 21)], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            (17249864598306, 22, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (9, 16), (2, 21), (4, 21), (1, 19), (1, 7), (0, 9), (1, 17), (16, 20), (5, 9), (5, 18), (12, 14), (9, 12), (4, 10), (3, 9), (5, 13), (2, 15), (4, 16), (3, 10), (0, 10), (11, 15), (15, 19), (1, 5), (0, 11), (1, 6), (3, 17), (15, 18), (5, 12), (5, 17), (11, 16), (3, 19), (0, 17), (3, 18), (1, 15), (12, 19), (4, 7), (0, 14), (13, 19), (1, 14), (3, 16)], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            (71061948999593, 28, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 26), (26, 27), (3, 18), (0, 4), (16, 20), (1, 13), (16, 19), (6, 14), (8, 19), (1, 10), (13, 25), (0, 22), (3, 16), (16, 18), (4, 22), (14, 26), (13, 23), (4, 23), (18, 21), (8, 23), (20, 23), (1, 14), (1, 25), (5, 11), (7, 18), (5, 21), (12, 20), (7, 23), (3, 5), (3, 6), (14, 17), (9, 27), (6, 13), (9, 23), (12, 17)], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            (36485494946683, 26, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (4, 10), (12, 22), (10, 22), (2, 13), (11, 15), (6, 24), (0, 15), (4, 14), (4, 8), (2, 17), (0, 14), (1, 25), (7, 24), (14, 17), (12, 23), (0, 9), (4, 11), (4, 20), (12, 24), (7, 11), (0, 21), (11, 21), (9, 21), (10, 12), (12, 14), (4, 23), (19, 21), (10, 13), (2, 16), (3, 9), (4, 25), (6, 10), (0, 19), (5, 21)], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            (1160328129482076, 28, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 26), (26, 27), (4, 12), (13, 15), (13, 27), (0, 22), (3, 20), (5, 16), (4, 16), (7, 12), (15, 18), (19, 23), (6, 19), (17, 23), (1, 21), (11, 20), (20, 24), (7, 22), (6, 9), (14, 16), (0, 2), (13, 23), (10, 21), (1, 3), (19, 25), (6, 13), (8, 19), (8, 12), (10, 22), (2, 5), (4, 10), (1, 10), (2, 6), (9, 24), (17, 20), (17, 24), (5, 26), (3, 7), (0, 9)], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            (99651866423074, 27, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 26), (0, 23), (2, 11), (4, 24), (12, 24), (10, 18), (7, 9), (5, 16), (6, 22), (13, 20), (8, 22), (12, 22), (16, 21), (22, 24), (11, 15), (12, 23), (0, 16), (5, 17), (2, 10), (10, 17), (0, 20), (18, 24), (17, 25), (9, 21), (3, 15), (3, 14), (0, 26), (3, 8), (14, 21), (5, 24), (12, 17), (20, 24), (17, 21), (14, 22), (11, 21), (4, 16)], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            (4379743238809176, 28, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 26), (26, 27), (18, 26), (5, 23), (3, 23), (14, 27), (7, 17), (15, 27), (12, 21), (3, 24), (0, 24), (23, 27), (10, 16), (7, 10), (4, 14), (0, 3), (7, 26), (18, 21), (9, 25), (6, 14), (10, 24), (3, 13), (12, 14), (7, 21), (3, 19), (2, 7), (3, 14), (6, 11), (7, 18), (7, 13), (8, 26), (9, 22), (0, 23), (9, 13), (11, 27), (6, 8), (1, 22), (3, 5), (2, 27), (4, 12), (10, 21), (6, 17), (5, 11)], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            (1365747904440311, 28, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 26), (26, 27), (11, 20), (7, 16), (12, 19), (18, 25), (12, 26), (2, 14), (15, 23), (8, 19), (0, 16), (0, 13), (12, 15), (2, 12), (1, 7), (10, 12), (22, 27), (7, 15), (13, 20), (1, 16), (8, 25), (1, 14), (16, 26), (14, 18), (8, 14), (6, 22), (5, 26), (1, 11), (16, 23), (12, 23), (9, 23), (0, 21), (0, 17), (13, 25), (10, 16), (8, 12), (3, 5), (10, 20), (3, 8), (6, 10), (2, 18)], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
            (714655386983856, 23, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (5, 21), (15, 11), (21, 17), (21, 12), (21, 1), (5, 11), (7, 16), (1, 15), (9, 4), (3, 16), (2, 0), (19, 17), (18, 1), (8, 3), (11, 18), (17, 13)], [1, 1, 1, 2, 1, 1, 1, 3, 2, 2, 3, 4, 3, 1, 2, 4, 2, 3, 1, 3, 1, 2, 3, 1, 3, 3, 4, 4, 1, 4, 2, 1, 4, 1, 2, 1, 4, 3]),
            (5142321657652140, 23, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (3, 16), (21, 19), (14, 13), (7, 21), (10, 17), (13, 6), (18, 4), (4, 5), (19, 1), (5, 2), (9, 19), (8, 21), (1, 10), (0, 11), (13, 2)], [4, 2, 1, 4, 4, 3, 1, 4, 4, 3, 3, 1, 4, 1, 1, 3, 3, 3, 4, 2, 3, 3, 1, 3, 1, 2, 1, 4, 4, 1, 1, 1, 2, 1, 1, 2, 4]),
            (4357302004370304, 17, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (10, 14), (6, 6), (12, 11), (15, 10), (6, 7), (13, 13), (12, 10), (14, 9), (14, 4), (0, 12), (7, 8), (15, 4), (14, 0), (3, 9), (10, 7), (16, 14), (15, 3), (10, 8), (3, 16), (0, 5), (16, 1), (2, 8), (9, 9), (7, 3), (14, 15), (5, 9), (15, 16), (13, 3), (1, 1)], [2, 2, 4, 2, 2, 3, 3, 4, 2, 2, 4, 2, 3, 3, 4, 2, 3, 4, 4, 2, 4, 4, 4, 4, 1, 4, 4, 2, 2, 4, 1, 1, 3, 4, 2, 1, 2, 4, 4, 3, 3, 2, 1, 3, 3]),
            (218722567874880, 16, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (8, 5), (13, 3), (4, 2), (15, 4), (2, 7), (14, 12), (15, 14), (5, 4), (6, 9), (7, 9), (6, 0), (14, 2), (3, 6), (11, 10), (8, 12), (10, 15), (8, 14), (15, 13), (12, 4), (7, 0), (2, 7), (4, 6), (11, 4)], [4, 2, 4, 1, 3, 1, 1, 3, 3, 4, 3, 4, 1, 4, 4, 1, 3, 1, 1, 1, 3, 4, 2, 3, 4, 3, 1, 4, 4, 1, 2, 1, 1, 4, 3, 4, 3, 3]),
            (329186342338560, 27, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 26), (18, 22), (7, 3), (21, 16), (17, 23), (21, 14), (19, 8)], [1, 1, 2, 4, 1, 4, 2, 3, 4, 4, 4, 2, 3, 3, 2, 1, 3, 4, 4, 1, 4, 3, 2, 2, 4, 4, 4, 3, 4, 2, 1, 3]),
            (486545235701760, 26, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20), (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (23, 24), (5, 1), (21, 10), (16, 10), (17, 13), (24, 8), (17, 1), (20, 22), (7, 12)], [2, 1, 1, 1, 2, 2, 3, 3, 4, 4, 2, 3, 2, 2, 4, 3, 1, 3, 2, 3, 4, 4, 3, 2, 2, 3, 3, 3, 2, 2, 2, 1, 1, 3]),
        ]
        for (exact, n, edges, weights) in cases {
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let count = weights.allSatisfy { $0 == 1 } ? graph.numberOfSpanningTrees() : graph.numberOfSpanningTrees(weight: { weights[$0] })
            #expect(count == Double(exact), "n \(n), \(edges.count) edges: \(count) against \(exact)")
            #expect(graph.numberOfSpanningTrees(weight: { Double(weights[$0]) }) == Double(exact), "n \(n), Double weights")
        }
        // Integer weights whose count is exact in Double but whose Cholesky pivots are not.
        let path = ReferencePseudograph(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let weights = [1 << 40, 4097, 3]
        #expect(path.numberOfSpanningTrees(weight: { weights[$0] }) == Double((1 << 40) * 4097 * 3))
    }

    @Test("Exact counts past 2⁶² and below 2¹⁰⁰ (the Chinese remainder step), correctly rounded: K₂₀ = 20¹⁸, K₂₁ = 21¹⁹, a weighted 5-cycle")
    func exactLargeCounts() {
        for (n, digits) in [(20, "262144000000000000000000"), (21, "13248496640331026125580781")] {
            var edges: [UndirectedEdge<Int>] = []
            for a in 0 ..< n { for b in a + 1 ..< n { edges.append(UndirectedEdge(a, b)) } }
            let complete = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            #expect(complete.numberOfSpanningTrees() == Double(digits)!, "K\(n)")
        }
        // τ(C₅) = Σᵢ Πⱼ≠ᵢ wⱼ.
        let weights = [1_000_003, 1_000_033, 1_000_037, 999_983, 999_979]
        let cycle = ReferencePseudograph(vertices: Array(0 ..< 5), edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
        #expect(cycle.numberOfSpanningTrees(weight: { weights[$0] }) == Double("5000139997041950692371673")!)
    }

    @Test("Dense spectra of weights near Double's limits (the scaled blocks of the root-free iteration): c times the unit spectrum")
    func extremeSpectra() throws {
        let edges = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2), (1, 1)].map { UndirectedEdge($0.0, $0.1) }
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges)
        let unitL = try graph.laplacianSpectrum(), unitA = try graph.adjacencySpectrum()
        for c in [1e300, 1e-300, 1e200, 1e-200] {
            for (a, b) in zip(try graph.laplacianSpectrum(weight: { _ in c }), unitL) { #expect(abs(a - c * b) <= 1e-14 * c * 4, "L, c \(c)") }
            for (a, b) in zip(try graph.adjacencySpectrum(weight: { _ in c }), unitA) { #expect(abs(a - c * b) <= 1e-14 * c * 4, "A, c \(c)") }
        }
    }

    @Test("Normalized matrices with weights near Double's limit: w/√d/√d does not overflow; N, its spectrum, λ₂ and the Kemeny constant are the unweighted ones")
    func normalizedOverflow() throws {
        let graph = ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        for w in [1e200, 1e300, 1e-300] {
            let heavy = graph.normalizedLaplacianMatrix(weight: { _ in w }), plain = graph.normalizedLaplacianMatrix()
            #expect(heavy.columns == plain.columns, "w \(w)")
            for (a, b) in zip(heavy.values, plain.values) { #expect(abs(a - b) <= 1e-15, "w \(w): \(a) against \(b)") }
            let spectrum = try graph.normalizedLaplacianSpectrum(weight: { _ in w })
            for (a, b) in zip(spectrum, try graph.normalizedLaplacianSpectrum()) { #expect(abs(a - b) <= 1e-14, "w \(w)") }
            #expect(abs(try graph.algebraicConnectivity(weight: { _ in w }, normalized: true) - 1) <= 1e-14, "w \(w)")
            let kemeny = graph.kemenyConstant(weight: { _ in w })
            #expect(kemeny.map { abs($0 - 1.5) <= 1e-14 } == true, "w \(w): \(String(describing: kemeny))")
        }
    }

    @Test("Effective graph resistance and the Kemeny constant on weighted paths: relative 10⁻¹² against Σ r(k + 1)(n − k − 1) and (1/2vol) Σ dᵢdⱼR(i, j)")
    func electricalUnderSpread() {
        var rng = SeededRandomNumberGenerator(seed: 23)
        let n = 40
        let spread = (0 ..< n - 1).map { _ in Double(sign: .plus, exponent: Int.random(in: -30 ... 30, using: &rng), significand: Double.random(in: 1 ..< 2, using: &rng)) }
        let cases: [(String, [Double])] = [
            ("first edge 10⁴", (0 ..< n - 1).map { $0 == 0 ? 1e4 : 1 }),
            ("first edge 10¹²", (0 ..< n - 1).map { $0 == 0 ? 1e12 : 1 }),
            ("middle edge 10⁻¹²", (0 ..< n - 1).map { $0 == 20 ? 1e-12 : 1 }),
            ("log-uniform over 2⁻³⁰ … 2³¹", spread),
        ]
        let path = ReferencePseudograph(vertices: Array(0 ..< n), edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        for (name, c) in cases {
            var kirchhoff = 0.0
            for k in 0 ..< n - 1 { kirchhoff += Double((k + 1) * (n - k - 1)) / c[k] }
            var d = [Double](repeating: 0, count: n)
            for k in 0 ..< n - 1 {
                d[k] += c[k]
                d[k + 1] += c[k]
            }
            var volume = 0.0
            for t in d { volume += t }
            var sum = 0.0
            for i in 0 ..< n {
                var r = 0.0
                for j in i + 1 ..< n {
                    r += 1 / c[j - 1]
                    sum += d[i] * d[j] * r
                }
            }
            let kemeny = sum / volume
            let kf = path.effectiveGraphResistance(weight: { c[$0] })
            #expect(kf.map { abs($0 - kirchhoff) <= 1e-12 * kirchhoff } == true, "\(name): \(String(describing: kf)) against \(kirchhoff)")
            let k = path.kemenyConstant(weight: { c[$0] })
            #expect(k.map { abs($0 - kemeny) <= 1e-12 * kemeny } == true, "\(name): \(String(describing: k)) against \(kemeny)")
        }
    }

    @Test("Resistance distance across 300 series bundles of three parallel two-edge paths, conductances over twelve decades: within 10⁻⁸ of the series–parallel law")
    func resistanceUnderSpread() throws {
        var rng = SeededRandomNumberGenerator(seed: 31)
        let bundles = 300
        var edges: [UndirectedEdge<Int>] = []
        var weights: [Double] = []
        var exact = 0.0
        var next = bundles + 1
        for b in 0 ..< bundles {
            var conductance = 0.0
            for _ in 0 ..< 3 {
                let middle = next
                next += 1
                let x = Double(sign: .plus, exponent: Int.random(in: -20 ... 20, using: &rng), significand: Double.random(in: 1 ..< 2, using: &rng))
                let y = Double(sign: .plus, exponent: Int.random(in: -20 ... 20, using: &rng), significand: Double.random(in: 1 ..< 2, using: &rng))
                edges += [UndirectedEdge(b, middle), UndirectedEdge(middle, b + 1)]
                weights += [x, y]
                conductance += 1 / (1 / x + 1 / y)
            }
            exact += 1 / conductance
        }
        let graph = ReferencePseudograph(vertices: Array(0 ..< next), edges: edges)
        let r = try graph.resistanceDistance(from: 0, to: bundles, weight: { weights[$0] })
        #expect(r.map { abs($0 - exact) <= 1e-8 * exact } == true, "\(String(describing: r)) against \(exact)")
        let back = try graph.resistanceDistance(from: bundles, to: 0, weight: { weights[$0] })
        #expect(back.map { abs($0 - exact) <= 1e-8 * exact } == true, "reversed: \(String(describing: back))")
    }

    @Test("Scale invariance at c = 10^±150: λ₂(cw) = cλ₂(w), N(cw) = N(w), τ(cw) = c^(n−1)τ(w), R(cw) = R(w)/c", .tags(.randomized))
    func scaleInvariance() async throws {
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 1 ... 9)).array(of: 0 ... 14)
        await propertyCheck(count: 120, input: triples, Gen.int(in: 2 ... 7), Gen.bool) { raw, n, up in
            let c = up ? 1e150 : 1e-150
            let edges = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) } + raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = (0 ..< n - 1).map { _ in 1.0 } + raw.map { Double($0.2) / 4 }
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            let context = "n \(n), edges \(raw), c \(c)"
            for normalized in [false, true] {
                let plain = try graph.algebraicConnectivity(weight: { weights[$0] }, normalized: normalized)
                let scaled = try graph.algebraicConnectivity(weight: { c * weights[$0] }, normalized: normalized)
                let expected = normalized ? plain : c * plain
                #expect(abs(scaled - expected) <= 1e-9 * expected, "normalized \(normalized), \(context)")
            }
            let n0 = graph.normalizedLaplacianMatrix(weight: { weights[$0] }), n1 = graph.normalizedLaplacianMatrix(weight: { c * weights[$0] })
            #expect(n0.columns == n1.columns, "\(context)")
            for (a, b) in zip(n0.values, n1.values) { #expect(abs(a - b) <= 1e-14 * max(1, abs(a)), "\(context)") }
            if n <= 3 {
                let tau = graph.numberOfSpanningTrees(weight: { weights[$0] })
                let scaledTau = graph.numberOfSpanningTrees(weight: { c * weights[$0] })
                var power = 1.0
                for _ in 0 ..< n - 1 { power *= c }
                #expect(abs(scaledTau - power * tau) <= 1e-14 * power * tau, "\(context)")
            }
            let r = try graph.resistanceDistance(from: 0, to: n - 1, weight: { weights[$0] })!
            let scaledR = try graph.resistanceDistance(from: 0, to: n - 1, weight: { c * weights[$0] })!
            #expect(abs(scaledR - r / c) <= 1e-9 * r / c, "\(context)")
        }
        // The Lanczos paths (shifted and shift-invert), on 120 vertices.
        let n = 120
        var rng = SeededRandomNumberGenerator(seed: 41)
        var edges = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
        for _ in 0 ..< 40 { edges.append(UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))) }
        let weights = edges.indices.map { _ in Double.random(in: 0.5 ... 2, using: &rng) }
        let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
        let path = ReferencePseudograph(vertices: Array(0 ..< n), edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        for c in [1e150, 1e-150] {
            for g in [graph, path] {
                let plain = try g.algebraicConnectivity(weight: { weights[$0] })
                let scaled = try g.algebraicConnectivity(weight: { c * weights[$0] })
                #expect(abs(scaled - c * plain) <= 1e-7 * c * plain, "c \(c)")
                let r = try g.resistanceDistance(from: 0, to: n - 1, weight: { weights[$0] })!
                let scaledR = try g.resistanceDistance(from: 0, to: n - 1, weight: { c * weights[$0] })!
                #expect(abs(scaledR - r / c) <= 1e-8 * r / c, "c \(c)")
            }
        }
    }

    @Test("Weights whose sums overflow Double trap rather than return infinities: a weighted degree, a merged parallel pair", .tags(.precondition))
    func overflowingSums() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = try graph.algebraicConnectivity(weight: { _ in 1.5e308 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2)])
            _ = graph.kemenyConstant(weight: { _ in 1.5e308 })
        }
        await #expect(processExitsWith: .failure) {
            let digraph = ReferenceDirectedMultigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
            _ = digraph.adjacencyMatrix(weight: { _ in 1.5e308 })
        }
        // Without the fault: the same graphs with weights whose sums stay finite.
        let graph = ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(try graph.algebraicConnectivity(weight: { _ in 1e307 }) > 0)
        let digraph = ReferenceDirectedMultigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(digraph.adjacencyMatrix(weight: { _ in 1e307 })[0, 1] == 2e307)
    }

    @Test("Work limits: a tolerance below rounding runs Lanczos (on A; by shift-invert) out of products, which throws NoConvergence at the default limit; the default tolerance converges")
    func workLimits() throws {
        do {
            // A random graph: no symmetry, so the Krylov space never closes early.
            let n = 64
            var rng = SeededRandomNumberGenerator(seed: 7)
            let edges = (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) } + (0 ..< n).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            let error = #expect(throws: NoConvergence.self) { try graph.spectralRadius(tolerance: 1e-300) }
            // 20,000 + 20√64 products.
            #expect(error?.iterations == 20_160)
            #expect((error?.residual ?? 0) > 1e-300)
        }
        do {
            // σ/λ₂ ≈ 0.4 n² > 20 n: the shift-invert path, 1,000 products.
            let n = 64
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let error = #expect(throws: NoConvergence.self) { try graph.algebraicConnectivity(tolerance: 1e-300) }
            #expect(error?.iterations == 1_000)
            #expect((error?.residual ?? 0) > 1e-300)
        }
        // Without the fault: the default tolerance converges on the same graphs.
        let n = 64
        var rng = SeededRandomNumberGenerator(seed: 7)
        let edges = (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) } + (0 ..< n).map { _ in UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
        let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
        let largest = try graph.adjacencySpectrum().map { abs($0) }.max()!
        #expect(abs(try graph.spectralRadius() - largest) <= 1e-8 * largest)
        let path = ReferencePseudograph(vertices: Array(0 ..< n), edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        // 2 − 2cos(π/64) = 4 sin²(π/128).
        let s = 0.024541228522912288
        #expect(abs(try path.algebraicConnectivity() - 4 * s * s) <= 1e-8 * 4 * s * s)
    }
}
