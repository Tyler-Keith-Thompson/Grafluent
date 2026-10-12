// Properties against oracles written inside each test, with shrinking (swift-property-based): on a
// failure, PropertyBased shrinks the generated input and prints the smallest one that still fails.
// Graphs are random multigraphs with self-loops on up to 7 vertices, on the `ReferencePseudograph`
// with the vertices listed in an order chosen by a seed (seed 0 keeps 0, 1, 2, …), so that matrix
// row i is the vertex at position i of `vertices`, not vertex i. Weights are small integers, 0
// included (a weight-0 edge is no edge). The oracles use only the definitions over the edge list:
// A with an undirected loop adding 2w, D its row sums, L = D − A; brute-force spanning-tree
// enumeration; the series and parallel laws. See README.md.

import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory properties against oracles, with shrinking", .tags(.randomized))
struct SpectralPropertyTests {
    @Test("L = D − A, N = D^-1/2 L D^-1/2, L_rw = D⁻¹ L and Q = D + A, entry by entry, stored exactly when nonzero")
    func matricesFromTheDefinitions() async {
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 4)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 0 ... 7), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, weighted, seed in
            guard n > 0 || raw.isEmpty else { return }
            let edges = n == 0 ? [] : raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = raw.map { weighted ? $0.2 : 1 }
            var listed = Array(0 ..< n)
            if seed != 0 {
                var rng = SeededRandomNumberGenerator(seed: UInt(seed))
                listed.shuffle(using: &rng)
            }
            let graph = ReferencePseudograph(vertices: listed, edges: edges)
            // The oracle, in index space (row i is listed[i]).
            var position = [Int](repeating: 0, count: n)
            for (i, v) in listed.enumerated() { position[v] = i }
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for (k, edge) in edges.enumerated() {
                let u = position[edge.u], v = position[edge.v]
                if u == v {
                    a[u][u] += 2 * Double(weights[k])
                } else {
                    a[u][v] += Double(weights[k])
                    a[v][u] += Double(weights[k])
                }
            }
            let d = a.map { $0.reduce(0, +) }
            let context = "n \(n), edges \(raw), weighted \(weighted), seed \(seed)"
            let adjacency = weighted ? graph.adjacencyMatrix(weight: { weights[$0] }) : graph.adjacencyMatrix()
            let laplacian = weighted ? graph.laplacianMatrix(weight: { weights[$0] }) : graph.laplacianMatrix()
            let normalized = weighted ? graph.normalizedLaplacianMatrix(weight: { weights[$0] }) : graph.normalizedLaplacianMatrix()
            let randomWalk = weighted ? graph.randomWalkLaplacianMatrix(weight: { weights[$0] }) : graph.randomWalkLaplacianMatrix()
            let signless = weighted ? graph.signlessLaplacianMatrix(weight: { weights[$0] }) : graph.signlessLaplacianMatrix()
            for (name, matrix) in [("A", adjacency), ("L", laplacian), ("N", normalized), ("L_rw", randomWalk), ("Q", signless)] {
                // Compressed sparse rows: columns ascending in each row, no stored zero.
                #expect(matrix.rowCount == n && matrix.offsets.count == n + 1 && matrix.offsets.first == 0, "\(name), \(context)")
                #expect(matrix.offsets.last == matrix.nonzeroCount && matrix.columns.count == matrix.nonzeroCount, "\(name), \(context)")
                #expect(matrix.values.count == matrix.nonzeroCount && !matrix.values.contains(0), "\(name), \(context)")
                for i in 0 ..< n {
                    let row = matrix.columns[matrix.offsets[i] ..< matrix.offsets[i + 1]]
                    #expect(zip(row, row.dropFirst()).allSatisfy { $0 < $1 }, "\(name) row \(i), \(context)")
                }
            }
            var nonzero = [String: Int]()
            for i in 0 ..< n {
                for j in 0 ..< n {
                    // L: the loops cancel, so a loop-only diagonal is exactly 0.
                    let l = (i == j ? d[i] : 0) - a[i][j]
                    let q = (i == j ? d[i] : 0) + a[i][j]
                    let nij = d[i] > 0 && d[j] > 0 ? l / (d[i] * d[j]).squareRoot() : 0
                    let rw = d[i] > 0 ? l / d[i] : 0
                    #expect(adjacency[i, j] == a[i][j], "A[\(i)][\(j)], \(context)")
                    #expect(laplacian[i, j] == l, "L[\(i)][\(j)], \(context)")
                    #expect(signless[i, j] == q, "Q[\(i)][\(j)], \(context)")
                    #expect(abs(normalized[i, j] - nij) <= 1e-12 * max(1, abs(nij)), "N[\(i)][\(j)], \(context)")
                    #expect(abs(randomWalk[i, j] - rw) <= 1e-12 * max(1, abs(rw)), "L_rw[\(i)][\(j)], \(context)")
                    nonzero["A", default: 0] += a[i][j] != 0 ? 1 : 0
                    nonzero["L", default: 0] += l != 0 ? 1 : 0
                    nonzero["Q", default: 0] += q != 0 ? 1 : 0
                    nonzero["N", default: 0] += nij != 0 ? 1 : 0
                    nonzero["L_rw", default: 0] += rw != 0 ? 1 : 0
                }
            }
            #expect(adjacency.nonzeroCount == nonzero["A", default: 0], "\(context)")
            #expect(laplacian.nonzeroCount == nonzero["L", default: 0], "\(context)")
            #expect(signless.nonzeroCount == nonzero["Q", default: 0], "\(context)")
            #expect(normalized.nonzeroCount == nonzero["N", default: 0], "\(context)")
            #expect(randomWalk.nonzeroCount == nonzero["L_rw", default: 0], "\(context)")
            // pattern is the stored positions.
            #expect(laplacian.pattern.offsets == laplacian.offsets && laplacian.pattern.targets == laplacian.columns, "\(context)")
        }
    }

    @Test("Rows of L sum to 0, xᵀLx = Σ w(x_u − x_v)², and the spectra of L, N, A are ordered, PSD and sum to the trace")
    func laplacianIsPositiveSemidefinite() async throws {
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 4)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 1 ... 7), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, weighted, seed in
            let edges = raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = raw.map { weighted ? $0.2 : 1 }
            var listed = Array(0 ..< n)
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            if seed != 0 { listed.shuffle(using: &rng) }
            let graph = ReferencePseudograph(vertices: listed, edges: edges)
            var position = [Int](repeating: 0, count: n)
            for (i, v) in listed.enumerated() { position[v] = i }
            let context = "n \(n), edges \(raw), weighted \(weighted), seed \(seed)"
            let laplacian = weighted ? graph.laplacianMatrix(weight: { weights[$0] }) : graph.laplacianMatrix()
            // Row sums: L · 1 = 0, exactly (integer weights).
            #expect(laplacian * [Double](repeating: 1, count: n) == [Double](repeating: 0, count: n), "\(context)")
            // The quadratic form on a random vector equals the sum over non-loop edges.
            let x = (0 ..< n).map { _ in Double(Int.random(in: -9 ... 9, using: &rng)) }
            let lx = laplacian * x
            let form = zip(x, lx).reduce(0) { $0 + $1.0 * $1.1 }
            var expected = 0.0
            for (k, edge) in edges.enumerated() {
                let difference = x[position[edge.u]] - x[position[edge.v]]
                expected += Double(weights[k]) * difference * difference
            }
            #expect(form == expected, "\(context)")
            // Spectra: ascending, n values, L and N nonnegative, N at most 2, sums equal to the traces.
            let ls = try weighted ? graph.laplacianSpectrum(weight: { weights[$0] }) : graph.laplacianSpectrum()
            let ns = try weighted ? graph.normalizedLaplacianSpectrum(weight: { weights[$0] }) : graph.normalizedLaplacianSpectrum()
            let asp = try weighted ? graph.adjacencySpectrum(weight: { weights[$0] }) : graph.adjacencySpectrum()
            let adjacency = weighted ? graph.adjacencyMatrix(weight: { weights[$0] }) : graph.adjacencyMatrix()
            let normalized = weighted ? graph.normalizedLaplacianMatrix(weight: { weights[$0] }) : graph.normalizedLaplacianMatrix()
            let scale = max(1, ls.last ?? 0)
            for (name, spectrum) in [("L", ls), ("N", ns), ("A", asp)] {
                #expect(spectrum.count == n && zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 }, "\(name), \(context)")
            }
            #expect(ls.allSatisfy { $0 >= -1e-9 * scale }, "\(context)")
            #expect(ns.allSatisfy { $0 >= -1e-9 && $0 <= 2 + 1e-9 }, "\(context)")
            let traces = [laplacian, normalized, adjacency].map { m in (0 ..< n).reduce(0.0) { $0 + m[$1, $1] } }
            for (name, (spectrum, trace)) in zip(["L", "N", "A"], zip([ls, ns, asp], traces)) {
                #expect(abs(spectrum.reduce(0, +) - trace) <= 1e-9 * Double(n) * max(1, spectrum.map { abs($0) }.max() ?? 0), "\(name), \(context)")
            }
            // Σ λ² of A is the sum of squared entries (the trace of A²).
            let squares = adjacency.values.reduce(0) { $0 + $1 * $1 }
            #expect(abs(asp.reduce(0) { $0 + $1 * $1 } - squares) <= 1e-9 * max(1, squares), "\(context)")
            // The spectral radius is the largest |λ(A)|.
            let radius = try weighted ? graph.spectralRadius(weight: { weights[$0] }) : graph.spectralRadius()
            let largest = asp.map { abs($0) }.max() ?? 0
            #expect(abs(radius - largest) <= 1e-6 * max(1, largest), "\(context)")
        }
    }

    @Test("The Fiedler pair satisfies ‖Mx − λ₂x‖ ≤ 1e-6 · scale, λ₂ is the second eigenvalue, and 0 means disconnected")
    func eigenResidual() async throws {
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 4)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 2 ... 7), Gen.bool, Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, weighted, normalized, seed in
            let edges = raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = raw.map { weighted ? $0.2 : 1 }
            var listed = Array(0 ..< n)
            if seed != 0 {
                var rng = SeededRandomNumberGenerator(seed: UInt(seed))
                listed.shuffle(using: &rng)
            }
            let graph = ReferencePseudograph(vertices: listed, edges: edges)
            let context = "n \(n), edges \(raw), weighted \(weighted), normalized \(normalized), seed \(seed)"
            // Connectivity oracle: union–find over positive-weight edges.
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (k, edge) in edges.enumerated() where weights[k] > 0 { parent[find(edge.u)] = find(edge.v) }
            let connected = Set((0 ..< n).map(find)).count == 1
            let matrix = normalized
                ? (weighted ? graph.normalizedLaplacianMatrix(weight: { weights[$0] }) : graph.normalizedLaplacianMatrix())
                : (weighted ? graph.laplacianMatrix(weight: { weights[$0] }) : graph.laplacianMatrix())
            let spectrum = normalized
                ? try (weighted ? graph.normalizedLaplacianSpectrum(weight: { weights[$0] }) : graph.normalizedLaplacianSpectrum())
                : try (weighted ? graph.laplacianSpectrum(weight: { weights[$0] }) : graph.laplacianSpectrum())
            let scale = max(1, spectrum.last ?? 0)
            let lambda = weighted
                ? try graph.algebraicConnectivity(weight: { weights[$0] }, normalized: normalized)
                : try graph.algebraicConnectivity(normalized: normalized)
            let fiedler = weighted
                ? try graph.fiedlerVector(weight: { weights[$0] }, normalized: normalized)
                : try graph.fiedlerVector(normalized: normalized)
            guard connected else {
                #expect(lambda == 0 && fiedler == nil, "\(context)")
                return
            }
            #expect(abs(lambda - spectrum[1]) <= 1e-6 * scale, "\(context)")
            guard let fiedler else {
                Issue.record("nil Fiedler vector on a connected graph, \(context)")
                return
            }
            #expect(abs(fiedler.algebraicConnectivity - spectrum[1]) <= 1e-6 * scale, "\(context)")
            let x = fiedler.values
            #expect(x.count == n && abs(x.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9, "\(context)")
            let mx = matrix * x
            let residual = zip(mx, x).reduce(0) { $0 + ($1.0 - fiedler.algebraicConnectivity * $1.1) * ($1.0 - fiedler.algebraicConnectivity * $1.1) }
            #expect(residual.squareRoot() <= 1e-6 * scale, "\(context)")
            // The Rayleigh quotient is λ₂.
            let rayleigh = zip(mx, x).reduce(0) { $0 + $1.0 * $1.1 }
            #expect(abs(rayleigh - spectrum[1]) <= 1e-6 * scale, "\(context)")
        }
    }

    @Test("The matrix-tree count equals brute-force spanning-tree enumeration (Σ over trees of Π w)")
    func matrixTreeTheorem() async {
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 4)).array(of: 0 ... 11)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 0 ... 7), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, weighted, seed in
            guard n > 0 || raw.isEmpty else { return }
            let edges = n == 0 ? [] : raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = raw.map { weighted ? $0.2 : 1 }
            var listed = Array(0 ..< n)
            if seed != 0 {
                var rng = SeededRandomNumberGenerator(seed: UInt(seed))
                listed.shuffle(using: &rng)
            }
            let graph = ReferencePseudograph(vertices: listed, edges: edges)
            // Every (n − 1)-subset of the non-loop edges that joins all n vertices, weights multiplied.
            var total = 0
            if n == 1 {
                total = 1
            } else if n > 1 {
                let candidates = edges.indices.filter { edges[$0].u != edges[$0].v }
                var chosen: [Int] = []
                func extend(from start: Int) {
                    if chosen.count == n - 1 {
                        var parent = Array(0 ..< n)
                        func find(_ x: Int) -> Int {
                            var x = x
                            while parent[x] != x { x = parent[x] }
                            return x
                        }
                        var product = 1
                        for k in chosen {
                            let a = find(edges[k].u), b = find(edges[k].v)
                            if a == b { return }
                            parent[a] = b
                            product *= weights[k]
                        }
                        total += product
                        return
                    }
                    guard start < candidates.count else { return }
                    for c in start ..< candidates.count {
                        chosen.append(candidates[c])
                        extend(from: c + 1)
                        chosen.removeLast()
                    }
                }
                extend(from: 0)
            }
            let count = weighted ? graph.numberOfSpanningTrees(weight: { weights[$0] }) : graph.numberOfSpanningTrees()
            let context = "n \(n), edges \(raw), weighted \(weighted), seed \(seed)"
            // Counts below 2⁵³ that are integers come out exact: unweighted ones are rounded.
            if weighted {
                #expect(abs(count - Double(total)) <= 1e-9 * max(1, Double(total)), "\(context)")
            } else {
                #expect(count == Double(total), "\(context)")
            }
        }
    }

    @Test("Resistance is a metric: 0 on the diagonal, symmetric, the triangle inequality; and it sums to the effective graph resistance")
    func resistanceIsAMetric() async throws {
        let triples = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 1 ... 4)).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 1 ... 6), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, weighted, seed in
            let edges = raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = raw.map { weighted ? Double($0.2) / 2 : 1 }
            var listed = Array(0 ..< n)
            if seed != 0 {
                var rng = SeededRandomNumberGenerator(seed: UInt(seed))
                listed.shuffle(using: &rng)
            }
            let graph = ReferencePseudograph(vertices: listed, edges: edges)
            let context = "n \(n), edges \(raw), weighted \(weighted), seed \(seed)"
            var r = [[Double?]](repeating: [Double?](repeating: nil, count: n), count: n)
            for a in 0 ..< n {
                for b in 0 ..< n {
                    r[a][b] = try weighted ? graph.resistanceDistance(from: a, to: b, weight: { weights[$0] }) : graph.resistanceDistance(from: a, to: b)
                }
            }
            for a in 0 ..< n {
                #expect(r[a][a] == 0, "R(\(a), \(a)), \(context)")
                for b in 0 ..< n {
                    #expect((r[a][b] == nil) == (r[b][a] == nil), "\(context)")
                    if let x = r[a][b], let y = r[b][a] {
                        #expect(x >= 0 && abs(x - y) <= 1e-6 * max(1, x), "R(\(a), \(b)), \(context)")
                    }
                    for c in 0 ..< n {
                        if let ab = r[a][b], let bc = r[b][c] {
                            // Reachability is transitive, and so is the bound.
                            guard let ac = r[a][c] else {
                                Issue.record("R(\(a), \(c)) nil, \(context)")
                                continue
                            }
                            #expect(ac <= ab + bc + 1e-6 * max(1, ab + bc), "R(\(a), \(c)) ≤ R(\(a), \(b)) + R(\(b), \(c)), \(context)")
                        }
                    }
                }
            }
            let connected = r[0].allSatisfy { $0 != nil }
            let effective = weighted ? graph.effectiveGraphResistance(weight: { weights[$0] }) : graph.effectiveGraphResistance()
            if connected {
                var sum = 0.0
                for a in 0 ..< n { for b in a + 1 ..< n { sum += r[a][b]! } }
                #expect(effective.map { abs($0 - sum) <= 1e-6 * max(1, sum) } == true, "\(context)")
            } else {
                #expect(effective == nil, "\(context)")
            }
        }
    }

    @Test("Series and parallel laws: a path of bundles of parallel edges has R = Σ 1 / Σ conductances")
    func seriesAndParallel() async throws {
        // Each bundle: 1 to 4 parallel edges between consecutive path vertices, conductances 1…8 / 4.
        let bundles = Gen.int(in: 1 ... 8).array(of: 1 ... 4).array(of: 1 ... 6)
        await propertyCheck(count: 300, input: bundles, Gen.int(in: 0 ... 1_000_000)) { bundles, seed in
            var edges: [UndirectedEdge<Int>] = []
            var weights: [Double] = []
            for (i, bundle) in bundles.enumerated() {
                for c in bundle {
                    edges.append(UndirectedEdge(i, i + 1))
                    weights.append(Double(c) / 4)
                }
            }
            // Edge positions shuffled by the seed: the law does not depend on edge order.
            var order = Array(edges.indices)
            if seed != 0 {
                var rng = SeededRandomNumberGenerator(seed: UInt(seed))
                order.shuffle(using: &rng)
            }
            let graph = ReferencePseudograph(vertices: Array(0 ... bundles.count), edges: order.map { edges[$0] })
            let shuffledWeights = order.map { weights[$0] }
            let context = "bundles \(bundles), seed \(seed)"
            var expected = 0.0
            for (i, bundle) in bundles.enumerated() {
                let parallel = 1 / bundle.reduce(0.0) { $0 + Double($1) / 4 }
                expected += parallel
                // One bundle alone: the parallel law.
                let r = try graph.resistanceDistance(from: i, to: i + 1, weight: { shuffledWeights[$0] })
                #expect(r.map { abs($0 - parallel) <= 1e-6 * max(1, parallel) } == true, "bundle \(i), \(context)")
            }
            let end = bundles.count
            let r = try graph.resistanceDistance(from: 0, to: end, weight: { shuffledWeights[$0] })
            #expect(r.map { abs($0 - expected) <= 1e-6 * max(1, expected) } == true, "\(context)")
            // Unweighted, each edge a unit resistor: Σ 1/(bundle size).
            let unit = bundles.reduce(0.0) { $0 + 1 / Double($1.count) }
            let ru = try graph.resistanceDistance(from: end, to: 0)
            #expect(ru.map { abs($0 - unit) <= 1e-6 * max(1, unit) } == true, "\(context)")
        }
    }

    @Test("The Fiedler vector is orthogonal to the null vector (1, or D^1/2 · 1 normalized) and follows the relative sign rule")
    func fiedlerOrthogonalAndSigned() async throws {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 1 ... 4)).array(of: 1 ... 16)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 2 ... 8), Gen.bool, Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, weighted, normalized, seed in
            // A spanning path keeps the graph connected; the random edges (loops included) follow it.
            let path = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
            let edges = path + raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = path.map { _ in 1 } + raw.map { weighted ? $0.2 : 1 }
            var listed = Array(0 ..< n)
            if seed != 0 {
                var rng = SeededRandomNumberGenerator(seed: UInt(seed))
                listed.shuffle(using: &rng)
            }
            let graph = ReferencePseudograph(vertices: listed, edges: edges)
            let context = "n \(n), edges \(raw), weighted \(weighted), normalized \(normalized), seed \(seed)"
            let fiedler = weighted
                ? try graph.fiedlerVector(weight: { weights[$0] }, normalized: normalized)
                : try graph.fiedlerVector(normalized: normalized)
            guard let fiedler else {
                Issue.record("nil on a connected graph, \(context)")
                return
            }
            let x = fiedler.values
            var null = [Double](repeating: 1, count: n)
            if normalized {
                let d = weighted ? graph.adjacencyMatrix(weight: { weights[$0] }) * null : graph.adjacencyMatrix() * null
                null = d.map { $0.squareRoot() }
            }
            let length = null.reduce(0) { $0 + $1 * $1 }.squareRoot()
            #expect(abs(zip(x, null).reduce(0) { $0 + $1.0 * $1.1 }) / length <= 1e-6, "\(context)")
            // The first entry, in index order, of magnitude at least 1e-4 of the largest is positive.
            let largest = x.map { abs($0) }.max() ?? 0
            let first = x.first { abs($0) >= 1e-4 * largest }
            #expect(first.map { $0 > 0 } == true, "\(x), \(context)")
            // value(of:) and value(ofIndex:) read the same entries, by position in `vertices`.
            for (i, v) in listed.enumerated() {
                #expect(fiedler.value(of: v) == x[i] && fiedler.value(ofIndex: i) == x[i], "\(context)")
            }
            // The ordering of a connected graph with more than two vertices sorts by this vector when
            // λ₂ is simple (otherwise by some λ₂ vector, not necessarily this one).
            let order = try weighted ? graph.spectralOrdering(weight: { weights[$0] }, normalized: normalized) : graph.spectralOrdering(normalized: normalized)
            #expect(order.sorted() == listed.sorted(), "\(context)")
            let spectrum = normalized
                ? try (weighted ? graph.normalizedLaplacianSpectrum(weight: { weights[$0] }) : graph.normalizedLaplacianSpectrum())
                : try (weighted ? graph.laplacianSpectrum(weight: { weights[$0] }) : graph.laplacianSpectrum())
            let simple = n > 2 && spectrum[2] - spectrum[1] > 1e-3 * max(1, spectrum[n - 1])
            if simple {
                for (a, b) in zip(order, order.dropFirst()) {
                    #expect(fiedler.value(of: a) <= fiedler.value(of: b) + 1e-6, "\(a) before \(b), \(context)")
                }
            } else if n == 2 {
                #expect(order == listed, "\(context)")
            }
        }
    }

    @Test("The spectral ordering lists components by least index, small ones in index order, each sorted")
    func orderingByComponents() async throws {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 3)).array(of: 0 ... 10)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            let edges = raw.map { UndirectedEdge($0.0 % n, $0.1 % n) }
            let weights = raw.map(\.2)
            var listed = Array(0 ..< n)
            if seed != 0 {
                var rng = SeededRandomNumberGenerator(seed: UInt(seed))
                listed.shuffle(using: &rng)
            }
            let graph = ReferencePseudograph(vertices: listed, edges: edges)
            let context = "n \(n), edges \(raw), seed \(seed)"
            // Components by positive-weight edges, in index space, ordered by least index.
            var position = [Int](repeating: 0, count: n)
            for (i, v) in listed.enumerated() { position[v] = i }
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (k, edge) in edges.enumerated() where weights[k] > 0 {
                let a = find(position[edge.u]), b = find(position[edge.v])
                parent[max(a, b)] = min(a, b)
            }
            var components: [[Int]] = []
            var seen: [Int: Int] = [:]
            for i in 0 ..< n {
                let r = find(i)
                if let k = seen[r] { components[k].append(i) } else { seen[r] = components.count; components.append([i]) }
            }
            let order = try graph.spectralOrdering(weight: { weights[$0] })
            #expect(order.count == n, "\(context)")
            var start = 0
            for component in components {
                let segment = Array(order[start ..< min(start + component.count, order.count)])
                start += component.count
                let expected = component.map { listed[$0] }
                #expect(segment.sorted() == expected.sorted(), "component \(expected), \(context)")
                if component.count <= 2 {
                    #expect(segment == expected, "small component in index order, \(context)")
                }
            }
        }
    }
}
