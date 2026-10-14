// Properties of the eigenpairs, incidence and modularity matrices, random walks against oracles written inside each test, with shrinking (swift-property-based).
// Graphs are random multigraphs with self-loops on up to 7 vertices (or 64 to 80 for the Lanczos
// paths), on the `ReferencePseudograph` with the vertices listed in a seeded order, weights small
// integers with 0 included. The oracles use only the definitions over the edge list. Each body is a
// nested function, so no closure inside an `#expect` sits inside the property's closure.

import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import SpectralGraphTheory
import Testing

@Suite("Eigenpairs, incidence, modularity and random walks against oracles, with shrinking", .tags(.randomized))
struct EigenpairsPropertyTests {
    @Test("Every end of A, L, N and Q: the dense spectrum's values, unit orthogonal vectors with small residuals and the canonical sign")
    func eigenpairsAgainstSpectra() async {
        func check(_ raw: [(Int, Int, Int)], _ n: Int, _ k: Int, _ seed: Int) throws {
            let edges = raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = raw.map { $0.2 }
            var listed = Array(0 ..< n)
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            listed.shuffle(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: edges)
            let count = min(k, n)
            let context = "n \(n), edges \(raw), k \(count), seed \(seed)"
            let a = try graph.adjacencySpectrum(weight: { weights[$0] })
            let l = try graph.laplacianSpectrum(weight: { weights[$0] })
            let nl = try graph.normalizedLaplacianSpectrum(weight: { weights[$0] })
            // Q's spectrum: the dense eigenvalues of D + A by its own Rayleigh–Ritz on every vector.
            let q = try graph.signlessLaplacianEigenpairs(smallest: n, weight: { weights[$0] }).eigenvalues
            let cases: [(String, SparseMatrix, [Double], Eigenpairs<ReferencePseudograph<Int>>, Eigenpairs<ReferencePseudograph<Int>>)] = [
                ("A", graph.adjacencyMatrix(weight: { weights[$0] }), a, try graph.adjacencyEigenpairs(smallest: count, weight: { weights[$0] }), try graph.adjacencyEigenpairs(largest: count, weight: { weights[$0] })),
                ("L", graph.laplacianMatrix(weight: { weights[$0] }), l, try graph.laplacianEigenpairs(smallest: count, weight: { weights[$0] }), try graph.laplacianEigenpairs(largest: count, weight: { weights[$0] })),
                ("N", graph.normalizedLaplacianMatrix(weight: { weights[$0] }), nl, try graph.normalizedLaplacianEigenpairs(smallest: count, weight: { weights[$0] }), try graph.normalizedLaplacianEigenpairs(largest: count, weight: { weights[$0] })),
                ("Q", graph.signlessLaplacianMatrix(weight: { weights[$0] }), q, try graph.signlessLaplacianEigenpairs(smallest: count, weight: { weights[$0] }), try graph.signlessLaplacianEigenpairs(largest: count, weight: { weights[$0] })),
            ]
            for (name, matrix, spectrum, smallest, largest) in cases {
                let scale = max(1, abs(spectrum.first ?? 0), abs(spectrum.last ?? 0))
                for (end, pairs) in [("smallest", smallest), ("largest", largest)] {
                    #expect(pairs.count == count, "\(name) \(end), \(context)")
                    for i in 0 ..< pairs.count {
                        let expected = end == "smallest" ? spectrum[i] : spectrum[n - 1 - i]
                        #expect(abs(pairs.eigenvalues[i] - expected) <= 1e-9 * scale, "\(name) \(end) λ\(i), \(context)")
                        let x = pairs.eigenvector(at: i)
                        let mx = matrix * x
                        var residual = 0.0, largestEntry = 0.0
                        for v in 0 ..< n {
                            residual += (mx[v] - pairs.eigenvalues[i] * x[v]) * (mx[v] - pairs.eigenvalues[i] * x[v])
                            largestEntry = max(largestEntry, abs(x[v]))
                        }
                        #expect(residual.squareRoot() <= 1e-9 * scale, "\(name) \(end) residual \(i), \(context)")
                        // The canonical sign: the first entry of magnitude ≥ 1e-4 of the largest is positive.
                        var first = 0.0
                        for v in 0 ..< n where abs(x[v]) >= 1e-4 * largestEntry {
                            first = x[v]
                            break
                        }
                        #expect(first > 0, "\(name) \(end) sign \(i), \(context)")
                        for j in 0 ... i {
                            let y = pairs.eigenvector(at: j)
                            var dot = 0.0
                            for v in 0 ..< n { dot += x[v] * y[v] }
                            #expect(abs(dot - (i == j ? 1 : 0)) <= 1e-12, "\(name) \(end) x\(i)·x\(j), \(context)")
                        }
                    }
                }
            }
        }
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 4)).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 1 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 1_000_000)) { raw, n, k, seed in
            try check(raw, n, k, seed)
        }
    }

    @Test("L's smallest: one 0 per component, its vector the normalized indicator, components by least vertex")
    func nullVectorsPerComponent() async {
        func check(_ raw: [(Int, Int, Int)], _ n: Int) throws {
            let edges = raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = raw.map { $0.2 }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: edges)
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (k, e) in edges.enumerated() where weights[k] > 0 { parent[find(e.u)] = find(e.v) }
            var roots: [Int] = []
            for v in 0 ..< n where !roots.contains(find(v)) { roots.append(find(v)) }
            let pairs = try graph.laplacianEigenpairs(smallest: roots.count, weight: { weights[$0] })
            let context = "n \(n), edges \(raw)"
            for (c, root) in roots.enumerated() {
                #expect(pairs.eigenvalues[c] == 0, "λ\(c), \(context)")
                let members = (0 ..< n).filter { find($0) == root }
                let entry = 1 / Double(members.count).squareRoot()
                let x = pairs.eigenvector(at: c)
                for v in 0 ..< n { #expect(x[v] == (find(v) == root ? entry : 0), "x\(c)[\(v)], \(context)") }
            }
        }
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 3)).array(of: 0 ... 10)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 1 ... 7)) { raw, n in
            try check(raw, n)
        }
    }

    @Test("On 64 to 80 vertices (Lanczos): the k smallest of L and N and the largest of A against the dense spectrum")
    func lanczosAgainstDense() async {
        func check(_ extra: [(Int, Int, Int)], _ n: Int, _ k: Int) throws {
            // A path backbone and random extra edges, weights 1 … 4.
            var edges = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
            var weights = [Int](repeating: 1, count: n - 1)
            for (u, v, w) in extra {
                edges.append(UndirectedEdge(u % n, v % n))
                weights.append(w)
            }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: edges)
            let context = "n \(n), extra \(extra), k \(k)"
            let l = try graph.laplacianSpectrum(weight: { weights[$0] })
            let nl = try graph.normalizedLaplacianSpectrum(weight: { weights[$0] })
            let a = try graph.adjacencySpectrum(weight: { weights[$0] })
            let ls = try graph.laplacianEigenpairs(smallest: k, weight: { weights[$0] })
            let ns = try graph.normalizedLaplacianEigenpairs(smallest: k, weight: { weights[$0] })
            let al = try graph.adjacencyEigenpairs(largest: k, weight: { weights[$0] })
            for i in 0 ..< k {
                #expect(abs(ls.eigenvalues[i] - l[i]) <= 1e-7 * max(l[i], 1e-6) + 1e-12 * l[n - 1] * Double(n), "L λ\(i), \(context)")
                #expect(abs(ns.eigenvalues[i] - nl[i]) <= 1e-7 * max(nl[i], 1e-6) + 1e-12 * Double(n), "N λ\(i), \(context)")
                #expect(abs(al.eigenvalues[i] - a[n - 1 - i]) <= 1e-7 * max(1, a[n - 1]), "A λ\(i), \(context)")
            }
        }
        let triples = zip(Gen.int(in: 0 ... 79), Gen.int(in: 0 ... 79), Gen.int(in: 1 ... 4)).array(of: 0 ... 40)
        await propertyCheck(count: 25, input: triples, Gen.int(in: 64 ... 80), Gen.int(in: 1 ... 5)) { extra, n, k in
            try check(extra, n, k)
        }
    }

    @Test("Incidence matrices: B Bᵀ = Q unoriented and L oriented; a column per edge with its endpoints")
    func incidence() async {
        func check(_ raw: [(Int, Int, Int)], _ n: Int, _ seed: Int) {
            let edges = raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            var listed = Array(0 ..< n)
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            listed.shuffle(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: edges)
            var position = [Int](repeating: 0, count: n)
            for (i, v) in listed.enumerated() { position[v] = i }
            let context = "n \(n), edges \(raw), seed \(seed)"
            for oriented in [false, true] {
                let b = graph.incidenceMatrix(oriented: oriented)
                let expected = oriented ? graph.laplacianMatrix() : graph.signlessLaplacianMatrix()
                #expect(b.rowCount == n && b.columnCount == edges.count, "\(context)")
                for (j, e) in edges.enumerated() {
                    let u = position[e.u], v = position[e.v]
                    for r in 0 ..< n {
                        let entry: Double = u == v ? (oriented || r != u ? 0 : 2) : (r == u ? (oriented ? -1 : 1) : r == v ? 1 : 0)
                        #expect(b[r, j] == entry, "B[\(r)][\(j)], oriented \(oriented), \(context)")
                    }
                }
                for i in 0 ..< n {
                    for j in 0 ..< n {
                        var sum = 0.0
                        for e in 0 ..< edges.count { sum += b[i, e] * b[j, e] }
                        #expect(sum == expected[i, j], "(B Bᵀ)[\(i)][\(j)], oriented \(oriented), \(context)")
                    }
                }
            }
        }
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 0)).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 1 ... 7), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            check(raw, n, seed)
        }
    }

    @Test("Modularity matrices against A − k kᵀ / vol and A − k_out k_inᵀ / m")
    func modularity() async {
        func check(_ raw: [(Int, Int, Int)], _ n: Int) {
            let weights = raw.map { $0.2 }
            let undirected = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0 % n, $0.1 % n) })
            let directed = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0 % n, to: $0.1 % n) })
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            var arcs = a
            for (k, t) in raw.enumerated() {
                let u = t.0 % n, v = t.1 % n
                a[u][v] += Double(weights[k])
                a[v][u] += Double(weights[k])
                arcs[u][v] += Double(weights[k])
            }
            let k = a.map { $0.reduce(0, +) }
            let volume = k.reduce(0, +)
            let out = arcs.map { $0.reduce(0, +) }
            var into = [Double](repeating: 0, count: n)
            for u in 0 ..< n { for v in 0 ..< n { into[v] += arcs[u][v] } }
            let total = out.reduce(0, +)
            let b = undirected.modularityMatrix(weight: { weights[$0] })
            let c = directed.modularityMatrix(weight: { weights[$0] })
            let context = "n \(n), edges \(raw)"
            for i in 0 ..< n {
                for j in 0 ..< n {
                    let expected = volume > 0 ? a[i][j] - k[i] * k[j] / volume : a[i][j]
                    #expect(abs(b[i][j] - expected) <= 1e-12 * max(1, volume), "B[\(i)][\(j)], \(context)")
                    let directedExpected = total > 0 ? arcs[i][j] - out[i] * into[j] / total : arcs[i][j]
                    #expect(abs(c[i][j] - directedExpected) <= 1e-12 * max(1, total), "directed B[\(i)][\(j)], \(context)")
                }
            }
        }
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 4)).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 1 ... 7)) { raw, n in
            check(raw, n)
        }
    }

    @Test("Hitting times solve h = 1 + P h off the target; commute times are both hitting times and vol · R")
    func hittingTimes() async {
        func check(_ raw: [(Int, Int, Int)], _ n: Int, _ target: Int) throws {
            let edges = raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = raw.map { Double($0.2) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: edges)
            let t = target % n
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for (k, e) in edges.enumerated() {
                a[e.u][e.v] += weights[k]
                a[e.v][e.u] += weights[k]
            }
            let d = a.map { $0.reduce(0, +) }
            let context = "n \(n), edges \(raw), target \(t)"
            var h = [Double?](repeating: nil, count: n)
            for v in 0 ..< n { h[v] = try graph.hittingTime(from: v, to: t, weight: { weights[$0] }) }
            #expect(h[t] == 0, "\(context)")
            for v in 0 ..< n where v != t {
                guard let hv = h[v] else {
                    // Unreachable: no path of positive weight to t, so no neighbour of v has a time.
                    for u in 0 ..< n where a[v][u] > 0 { #expect(h[u] == nil && u != t, "\(context)") }
                    continue
                }
                // h(v) = 1 + Σ_u P(v, u) h(u), with h(t) = 0.
                var expected = 1.0
                for u in 0 ..< n where a[v][u] > 0 { expected += a[v][u] / d[v] * (h[u] ?? .nan) }
                #expect(abs(hv - expected) <= 1e-7 * max(1, hv), "h(\(v)), \(context)")
                let back = try #require(try graph.hittingTime(from: t, to: v, weight: { weights[$0] }))
                let commute = try #require(try graph.commuteTime(from: v, to: t, weight: { weights[$0] }))
                let r = try #require(try graph.resistanceDistance(from: v, to: t, weight: { weights[$0] }))
                var volume = 0.0
                for u in 0 ..< n where u == t || h[u] != nil { volume += d[u] }
                #expect(abs(commute - (hv + back)) <= 1e-7 * commute, "κ(\(v)), \(context)")
                #expect(abs(commute - volume * r) <= 1e-9 * commute, "κ = vol · R (\(v)), \(context)")
            }
        }
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 3)).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 1 ... 7), Gen.int(in: 0 ... 6)) { raw, n, target in
            try check(raw, n, target)
        }
    }

    @Test("The stationary distribution: a probability vector with πP = π, dangling vertices spread uniformly")
    func stationary() async {
        func check(_ raw: [(Int, Int, Int)], _ n: Int) throws {
            let weights = raw.map { $0.2 }
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0 % n, to: $0.1 % n) })
            let pi = try graph.stationaryDistribution(weight: { weights[$0] }).probabilities
            var out = [Double](repeating: 0, count: n)
            for (k, t) in raw.enumerated() { out[t.0 % n] += Double(weights[k]) }
            var next = [Double](repeating: 0, count: n)
            for v in 0 ..< n where out[v] == 0 { for u in 0 ..< n { next[u] += pi[v] / Double(n) } }
            for (k, t) in raw.enumerated() where out[t.0 % n] > 0 { next[t.1 % n] += pi[t.0 % n] * Double(weights[k]) / out[t.0 % n] }
            var residual = 0.0, total = 0.0
            for v in 0 ..< n {
                residual += abs(next[v] - pi[v])
                total += pi[v]
                #expect(pi[v] >= 0, "π(\(v)), n \(n), arcs \(raw)")
            }
            #expect(residual <= 1e-11 && abs(total - 1) <= 1e-13, "‖πP − π‖₁ \(residual), Σ \(total), n \(n), arcs \(raw)")
        }
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 3)).array(of: 0 ... 14)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 1 ... 7)) { raw, n in
            try check(raw, n)
        }
    }
}
