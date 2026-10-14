// Properties with shrinking (swift-property-based) of the planar, spectral, scaling, shell and
// ForceAtlas2 layouts on random graphs: planarLayout on random planar multigraphs (grid points in
// bounds, distinct, no crossing; nil exactly when isPlanar is false), spectralLayout's axes as
// eigenvectors of the Laplacian (residual, unit, orthogonal, Rayleigh quotients ascending and at
// most the brute-force second and third eigenvalues of a dense Jacobi reference), classical scaling
// of a random weighted path reproducing its distances, shells at their radii, and ForceAtlas2's
// stepper equal to its run.

import GraphDrawing
import GraphProtocols
import Multigraphs
import Planarity
import PropertyBased
import RandomGraphs
import Testing

@Suite("GraphDrawing layout properties, with shrinking")
struct GraphDrawingLayoutPropertyTests {
    @Test("planarLayout: random planar multigraphs drawn without crossings; nil when not planar")
    func planar() async {
        let input = Gen.int(in: 0 ... 1_000_000).array(of: 1 ... 60)
        await propertyCheck(count: 200, input: input) { choices in
            let n = 4 + choices[0] % 13
            var edges: [UndirectedEdge<Int>] = []
            var rejected: [UndirectedEdge<Int>]?
            for c in choices.dropFirst() {
                let edge = UndirectedEdge(c % n, (c / n) % n)
                let candidate = Pseudograph<Int>(vertices: 0 ..< n, edges: edges + [edge])
                if candidate.isPlanar { edges.append(edge) } else if rejected == nil { rejected = edges + [edge] }
            }
            if let rejected { let holds1 = Pseudograph<Int>(vertices: 0 ..< n, edges: rejected).planarLayout() == nil; #expect(holds1) }
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
            guard let layout = graph.planarLayout() else {
                Issue.record("no drawing of a planar graph: n \(n), \(edges)")
                return
            }
            let p = layout.positions
            for q in p {
                let holds2 = q.x == q.x.rounded() && q.y == q.y.rounded() && q.x >= 0 && q.x <= Double(2 * n - 4) && q.y >= 0 && q.y <= Double(n - 2)
                #expect(holds2, "\(q): n \(n), \(edges)")
            }
            let holds3 = Set(p.map { [$0.x, $0.y] }).count == n
            #expect(holds3, "two vertices share a point: n \(n), \(edges)")
            func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Double {
                (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
            }
            let segments = Set(edges.filter { $0.u != $0.v }.map { [min($0.u, $0.v), max($0.u, $0.v)] }).map { ($0[0], $0[1]) }
            for (a, b) in segments {
                for v in 0 ..< n where v != a && v != b {
                    let c = p[v]
                    let on = orientation(p[a], p[b], c) == 0 && min(p[a].x, p[b].x) <= c.x && c.x <= max(p[a].x, p[b].x)
                        && min(p[a].y, p[b].y) <= c.y && c.y <= max(p[a].y, p[b].y)
                    let holds4 = !on
                    #expect(holds4, "vertex \(v) on edge \(a)–\(b): n \(n), \(edges)")
                }
            }
            for i in 0 ..< segments.count {
                for j in i + 1 ..< segments.count {
                    let (a, b) = segments[i], (c, d) = segments[j]
                    guard Set([a, b, c, d]).count == 4 else { continue }
                    let crosses = orientation(p[a], p[b], p[c]) * orientation(p[a], p[b], p[d]) < 0
                        && orientation(p[c], p[d], p[a]) * orientation(p[c], p[d], p[b]) < 0
                    let holds5 = !crosses
                    #expect(holds5, "\(a)–\(b) crosses \(c)–\(d): n \(n), \(edges)")
                }
            }
        }
    }

    @Test("spectralLayout: the axes are unit eigenvectors of L orthogonal to 1 and to each other, for the second and third eigenvalues")
    func spectral() async {
        let input = Gen.int(in: 0 ... 1_000_000).array(of: 0 ... 40)
        await propertyCheck(count: 200, input: input) { choices in
            let n = 3 + (choices.first ?? 0) % 10
            let edges = choices.dropFirst().map { UndirectedEdge($0 % n, ($0 / n) % n) }
            let weights = choices.dropFirst().map { Double(1 + ($0 / (n * n)) % 4) }
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
            guard let layout = try? graph.spectralLayout(weight: { weights[$0] }) else {
                Issue.record("NoConvergence")
                return
            }
            var laplacian = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for (k, e) in edges.enumerated() where e.u != e.v {
                laplacian[e.u][e.u] += weights[k]
                laplacian[e.v][e.v] += weights[k]
                laplacian[e.u][e.v] -= weights[k]
                laplacian[e.v][e.u] -= weights[k]
            }
            // The reference spectrum: cyclic Jacobi on a copy.
            var a = laplacian
            for _ in 0 ..< 100 {
                var off = 0.0
                for i in 0 ..< n { for j in 0 ..< n where i != j { off += a[i][j] * a[i][j] } }
                if off < 1e-24 { break }
                for p in 0 ..< n {
                    for q in p + 1 ..< n where a[p][q] != 0 {
                        let theta = (a[q][q] - a[p][p]) / (2 * a[p][q])
                        let t = (theta >= 0 ? 1.0 : -1.0) / (abs(theta) + (theta * theta + 1).squareRoot())
                        let c = 1 / (t * t + 1).squareRoot(), s = t * c
                        for k in 0 ..< n {
                            let akp = a[k][p], akq = a[k][q]
                            a[k][p] = c * akp - s * akq
                            a[k][q] = s * akp + c * akq
                        }
                        for k in 0 ..< n {
                            let apk = a[p][k], aqk = a[q][k]
                            a[p][k] = c * apk - s * aqk
                            a[q][k] = s * apk + c * aqk
                        }
                    }
                }
            }
            let spectrum = (0 ..< n).map { a[$0][$0] }.sorted()
            var lambdas: [Double] = []
            for axis in 0 ..< 2 {
                let x = layout.positions.map { axis == 0 ? $0.x : $0.y }
                let lx = (0 ..< n).map { i in (0 ..< n).reduce(0.0) { $0 + laplacian[i][$1] * x[$1] } }
                let lambda = zip(x, lx).reduce(0.0) { $0 + $1.0 * $1.1 }
                lambdas.append(lambda)
                let residual = zip(lx, x).reduce(0.0) { $0 + ($1.0 - lambda * $1.1) * ($1.0 - lambda * $1.1) }.squareRoot()
                let holds6 = residual <= 1e-9 * Swift.max(1, spectrum[n - 1])
                #expect(holds6, "axis \(axis) residual \(residual): n \(n), \(edges)")
                let holds7 = abs(x.reduce(0.0) { $0 + $1 * $1 } - 1) <= 1e-9
                #expect(holds7)
                let holds8 = abs(spectrum[axis + 1] - lambda) <= 1e-8 * Swift.max(1, spectrum[n - 1])
                #expect(holds8, "λ \(lambda) vs \(spectrum): n \(n), \(edges)")
                let big = x.map(abs).max()!
                let holds9 = x.first { abs($0) >= 1e-4 * big }! > 0
                #expect(holds9)
            }
            let dot = layout.positions.reduce(0.0) { $0 + $1.x * $1.y }
            let holds10 = abs(dot) <= 1e-9 || abs(lambdas[0] - lambdas[1]) <= 1e-9
            #expect(holds10)
        }
    }

    @Test("multidimensionalScalingLayout: a random weighted path is drawn on a line at its distances")
    func scalingPath() async {
        let input = Gen.int(in: 1 ... 1_000).array(of: 1 ... 25)
        await propertyCheck(count: 200, input: input) { lengths in
            let n = lengths.count + 1
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            guard let layout = try? graph.multidimensionalScalingLayout(edgeLength: { Double(lengths[$0]) }) else {
                Issue.record("NoConvergence")
                return
            }
            var at = [0.0]
            for l in lengths { at.append(at.last! + Double(l)) }
            let total = at.last!
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let d = layout.positions[i] - layout.positions[j]
                    let holds11 = abs((d * d).sum().squareRoot() - (at[j] - at[i])) <= 1e-9 * total
                    #expect(holds11, "\(lengths) \(i) \(j)")
                }
            }
        }
    }

    @Test("shellLayout: each vertex at its shell's radius from the centre")
    func shells() async {
        let input = Gen.int(in: 0 ... 5).array(of: 2 ... 30)
        await propertyCheck(count: 200, input: input) { assignment in
            let n = assignment.count
            let shellCount = (assignment.max() ?? 0) + 1
            var shells = [[Int]](repeating: [], count: shellCount)
            for (v, k) in assignment.enumerated() { shells[k].append(v) }
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: [] as [UndirectedEdge<Int>])
            let layout = graph.shellLayout(shells: shells, radius: 2, center: SIMD2(1, -1))
            let bump = 2 / Double(shellCount)
            let firstRadius = shells[0].count == 1 ? 0 : bump
            for (k, shell) in shells.enumerated() {
                for v in shell {
                    let d = layout.position(of: v) - SIMD2(1, -1)
                    let holds12 = abs((d * d).sum().squareRoot() - (firstRadius + Double(k) * bump)) <= 1e-12
                    #expect(holds12, "\(assignment)")
                }
            }
        }
    }

    @Test("ForceAtlas2Layout: step by step equals run, every position finite")
    func forceAtlas2Stepper() async {
        let input = Gen.int(in: 0 ... 1_000_000).array(of: 1 ... 40)
        await propertyCheck(count: 100, input: input) { choices in
            let n = 1 + choices[0] % 15
            let edges = choices.dropFirst().map { UndirectedEdge($0 % n, ($0 / n) % n) }
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges)
            let modes = choices[0] / 15
            var a = Xoshiro256StarStar(seed: UInt64(choices[0]))
            let run = graph.forceAtlas2Layout(
                iterations: 30, strongGravity: modes & 1 != 0, linLog: modes & 2 != 0, dissuadeHubs: modes & 4 != 0,
                barnesHutTheta: modes & 8 != 0 ? 1.2 : nil, using: &a)
            var b = Xoshiro256StarStar(seed: UInt64(choices[0]))
            var stepper = ForceAtlas2Layout(
                graph, iterations: 30, strongGravity: modes & 1 != 0, linLog: modes & 2 != 0, dissuadeHubs: modes & 4 != 0,
                barnesHutTheta: modes & 8 != 0 ? 1.2 : nil, using: &b)
            while !stepper.isFinished { stepper.step() }
            let holds13 = stepper.drawing == run
            #expect(holds13)
            for p in run.positions { let holds14 = p.x.isFinite && p.y.isFinite; #expect(holds14, "\(choices)") }
        }
    }
}
