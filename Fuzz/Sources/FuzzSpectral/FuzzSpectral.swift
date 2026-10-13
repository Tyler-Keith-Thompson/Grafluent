// SpectralGraphTheory on random weighted pseudographs (loops, parallel edges, weight-0 edges) given
// as a plain edge list,
// with weights unit, small integers, or log-uniform over up to 2⁻²⁰ … 2²¹:
// - on 64 to 95 vertices (the Lanczos paths): λ₂ of L and of N against the dense spectrum, the
//   Fiedler pair's residual, unit length and orthogonality to the null vector, ρ(A) against the
//   dense spectrum of A (negative weights included);
// - on up to 9 vertices: the matrix-tree count against a Bareiss determinant in Int128 (exact for
//   integer weights below 2⁵³), resistance as a metric, Foster's theorem Σ w_e R(e) = n − 1, the
//   pairwise sum against `effectiveGraphResistance`, and the Kemeny constant against
//   (1/2vol) Σ dᵢdⱼR(i, j).

import FuzzSupport
import GraphProtocols
import SpectralGraphTheory

/// An undirected pseudograph as a plain edge list with vertex indices 0..<n, so the harness
/// depends on no representation module: a loop is incident twice, parallel edges each once.
struct EdgeListGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    let incidence: [[Int]]

    init(vertices: Range<Int>, edges: [UndirectedEdge<Int>]) {
        self.vertices = Array(vertices)
        self.edges = edges
        var incidence = [[Int]](repeating: [], count: vertices.count)
        for (k, e) in edges.enumerated() {
            incidence[e.u].append(k)
            incidence[e.v].append(k)
        }
        self.incidence = incidence
    }

    func incidentEdges(of vertex: Int) -> [Int] { incidence[vertex] }
    func neighbors(of vertex: Int) -> [Int] { incidence[vertex].map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
}

@main
enum FuzzSpectral {
    static func main() { runFuzzer(fuzz) }

    /// A weight from the input: class 0 unit, 1 an integer in 0 ... 4, 2 log-uniform over
    /// 2^±spread, 3 the same with a sign (only where negative weights are allowed).
    static func weight(_ input: inout FuzzInput, _ kind: Int, _ spread: Int) -> Double {
        switch kind {
        case 0: return 1
        case 1: return Double(input.int(in: 0 ... 4))
        default:
            let e = input.int(in: 0 ... 2 * spread) - spread
            let w = Double(sign: .plus, exponent: e, significand: 1 + Double(input.byte()) / 256)
            return kind == 3 && input.byte() % 4 == 0 ? -w : w
        }
    }

    static func fuzz(_ input: inout FuzzInput) {
        do {
            if input.byte() % 2 == 0 { try large(&input) } else { try small(&input) }
        } catch {
            // The default iteration limits should never be reached, so a throw is a finding.
            check(false, "\(error)")
        }
    }

    /// The Lanczos paths against the dense solver.
    static func large(_ input: inout FuzzInput) throws {
        let n = 64 + input.int(below: 32)
        let kind = input.int(below: 3), spread = input.int(in: 1 ... 20)
        var edges: [UndirectedEdge<Int>] = []
        var weights: [Double] = []
        // A backbone (path or cycle) unless the input leaves it out, so most graphs are connected.
        let backbone = input.int(below: 4)
        if backbone > 0 {
            for v in 0 ..< n - 1 {
                edges.append(UndirectedEdge(v, v + 1))
                weights.append(weight(&input, kind, spread))
            }
            if backbone == 2 {
                edges.append(UndirectedEdge(n - 1, 0))
                weights.append(weight(&input, kind, spread))
            }
        }
        let extra = input.int(below: 48)
        for _ in 0 ..< extra {
            edges.append(UndirectedEdge(input.int(below: n), input.int(below: n)))
            weights.append(weight(&input, kind, spread))
        }
        let graph = EdgeListGraph(vertices: 0 ..< n, edges: edges)
        var degree = [Double](repeating: 0, count: n)
        for (k, e) in edges.enumerated() where e.u != e.v {
            degree[e.u] += weights[k]
            degree[e.v] += weights[k]
        }
        let sigma = 2 * degree.max()!
        for normalized in [false, true] {
            let spectrum = try normalized ? graph.normalizedLaplacianSpectrum(weight: { weights[$0] }) : graph.laplacianSpectrum(weight: { weights[$0] })
            let scale = normalized ? 2 : sigma
            let dense = spectrum[1]
            let value = try graph.algebraicConnectivity(weight: { weights[$0] }, normalized: normalized)
            // The dense λ₂ is accurate to about n ε · scale; the iterative one relative to itself.
            check(abs(value - dense) <= 1e-6 * dense + 1e-11 * Double(n) * scale, "λ₂ \(value) against dense \(dense), normalized \(normalized), n \(n)")
            guard let fiedler = try graph.fiedlerVector(weight: { weights[$0] }, normalized: normalized) else {
                check(dense <= 1e-11 * Double(n) * scale, "nil Fiedler vector with dense λ₂ \(dense)")
                continue
            }
            check(fiedler.algebraicConnectivity == value, "fiedlerVector's λ₂ differs from algebraicConnectivity")
            let x = fiedler.values
            var length = 0.0
            for t in x { length += t * t }
            check(abs(length - 1) <= 1e-10, "Fiedler vector length² \(length)")
            let matrix = normalized ? graph.normalizedLaplacianMatrix(weight: { weights[$0] }) : graph.laplacianMatrix(weight: { weights[$0] })
            let mx = matrix * x
            var residual = 0.0
            for i in 0 ..< n { residual += (mx[i] - value * x[i]) * (mx[i] - value * x[i]) }
            check(residual.squareRoot() <= 1e-6 * value + 1e-11 * Double(n) * scale, "Fiedler residual \(residual.squareRoot()), λ₂ \(value), normalized \(normalized)")
            var null = [Double](repeating: 1, count: n)
            if normalized {
                var d = [Double](repeating: 0, count: n)
                for (k, e) in edges.enumerated() {
                    d[e.u] += weights[k]
                    d[e.v] += weights[k]
                }
                null = d.map { $0.squareRoot() }
            }
            var dot = 0.0, nullLength = 0.0
            for i in 0 ..< n {
                dot += null[i] * x[i]
                nullLength += null[i] * null[i]
            }
            check(abs(dot) <= 1e-9 * nullLength.squareRoot(), "Fiedler vector not orthogonal to the null vector: \(dot)")
        }
        // ρ(A), with negative weights when the class allows them.
        let signed = edges.indices.map { _ in weight(&input, kind == 2 ? 3 : kind, spread) }
        let a = try graph.adjacencySpectrum(weight: { signed[$0] })
        let rho = max(abs(a.first ?? 0), abs(a.last ?? 0))
        var bound = 0.0
        var rows = [Double](repeating: 0, count: n)
        for (k, e) in edges.enumerated() {
            rows[e.u] += abs(signed[k])
            rows[e.v] += abs(signed[k])
        }
        bound = rows.max()!
        let radius = try graph.spectralRadius(weight: { signed[$0] })
        check(abs(radius - rho) <= 1e-6 * rho + 1e-11 * Double(n) * bound, "ρ \(radius) against dense \(rho)")
    }

    /// The electrical laws and the matrix-tree theorem on small graphs.
    static func small(_ input: inout FuzzInput) throws {
        let n = input.int(in: 1 ... 9)
        let kind = input.int(below: 3), spread = input.int(in: 1 ... 20)
        let m = input.int(below: 24)
        var edges: [UndirectedEdge<Int>] = []
        var weights: [Double] = []
        for _ in 0 ..< m {
            edges.append(UndirectedEdge(input.int(below: n), input.int(below: n)))
            weights.append(weight(&input, kind, spread))
        }
        let graph = EdgeListGraph(vertices: 0 ..< n, edges: edges)
        // Connectivity over positive weights.
        var parent = Array(0 ..< n)
        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (k, e) in edges.enumerated() where weights[k] > 0 { parent[find(e.u)] = find(e.v) }
        let connected = (0 ..< n).allSatisfy { find($0) == find(0) }

        // The matrix-tree count.
        let count = graph.numberOfSpanningTrees(weight: { weights[$0] })
        if kind < 2 {
            // Bareiss on the integer Laplacian without its last row and column.
            let size = n - 1
            var l = [[Int128]](repeating: [Int128](repeating: 0, count: max(size, 1)), count: max(size, 1))
            for (k, e) in edges.enumerated() where e.u != e.v {
                let w = Int128(weights[k])
                if e.u < size { l[e.u][e.u] += w }
                if e.v < size { l[e.v][e.v] += w }
                if e.u < size && e.v < size {
                    l[e.u][e.v] -= w
                    l[e.v][e.u] -= w
                }
            }
            var exact: Int128 = size == 0 ? 1 : 0
            if size > 0 {
                var previous: Int128 = 1
                var sign: Int128 = 1
                var singular = false
                for p in 0 ..< size - 1 {
                    if l[p][p] == 0 {
                        guard let r = (p + 1 ..< size).first(where: { l[$0][p] != 0 }) else {
                            singular = true
                            break
                        }
                        l.swapAt(p, r)
                        sign = -sign
                    }
                    for i in p + 1 ..< size {
                        for j in p + 1 ..< size { l[i][j] = (l[i][j] * l[p][p] - l[i][p] * l[p][j]) / previous }
                    }
                    previous = l[p][p]
                }
                exact = singular ? 0 : sign * l[size - 1][size - 1]
            }
            let exactCount = graph.numberOfSpanningTrees(as: UInt128.self, weight: { Int(weights[$0]) })
            check(exactCount == UInt128(exact), "exact τ \(String(describing: exactCount)) against Bareiss \(exact)")
            if exact < Int128(1) << 53 {
                check(count == Double(exact), "τ \(count) against Bareiss \(exact)")
            } else {
                check(abs(count - Double(exact)) <= 1e-13 * Double(exact), "τ \(count) against Bareiss \(exact)")
            }
        }
        check((count > 0) == connected, "τ \(count) on a graph that is connected: \(connected)")
        guard n > 1 else { return }
        // Scaling by a power of two scales τ by its (n − 1)th power, exactly.
        let shift = input.int(in: 0 ... 40) - 20
        let scaled = graph.numberOfSpanningTrees(weight: { Double(sign: .plus, exponent: shift, significand: 1) * weights[$0] })
        let expected = Double(sign: .plus, exponent: shift * (n - 1), significand: 1) * count
        if expected.isNormal || expected == 0 {
            check(abs(scaled - expected) <= 1e-13 * expected, "τ(2^\(shift) w) = \(scaled), expected \(expected)")
        }

        // Resistance laws.
        var r = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
        for u in 0 ..< n {
            for v in 0 ..< n {
                let value = try graph.resistanceDistance(from: u, to: v, weight: { weights[$0] })
                check((value == nil) == (find(u) != find(v)), "R(\(u), \(v)) nil: \(value == nil)")
                r[u][v] = value ?? .infinity
            }
        }
        for u in 0 ..< n {
            check(r[u][u] == 0, "R(v, v) = \(r[u][u])")
            for v in 0 ..< n where find(u) == find(v) {
                check(abs(r[u][v] - r[v][u]) <= 1e-8 * r[u][v], "R not symmetric: \(r[u][v]), \(r[v][u])")
                for t in 0 ..< n where find(t) == find(u) {
                    check(r[u][v] <= (r[u][t] + r[t][v]) * (1 + 1e-8), "triangle inequality: R(\(u), \(v)) = \(r[u][v]) through \(t)")
                }
            }
        }
        let kf = graph.effectiveGraphResistance(weight: { weights[$0] })
        let kemeny = graph.kemenyConstant(weight: { weights[$0] })
        check((kf == nil) == !connected && (kemeny == nil) == !connected, "nil effective resistance or Kemeny constant on a graph that is connected: \(connected)")
        guard connected else { return }
        // Foster: Σ over non-loop edges of w_e R(e) = n − 1.
        var foster = 0.0, total = 0.0
        var d = [Double](repeating: 0, count: n)
        for (k, e) in edges.enumerated() where weights[k] > 0 {
            d[e.u] += weights[k]
            d[e.v] += weights[k]
            if e.u != e.v { foster += weights[k] * r[e.u][e.v] }
        }
        check(abs(foster - Double(n - 1)) <= 1e-6 * Double(n), "Foster's sum \(foster), n − 1 = \(n - 1)")
        var volume = 0.0
        for t in d { volume += t }
        var commute = 0.0
        for u in 0 ..< n {
            for v in u + 1 ..< n {
                total += r[u][v]
                commute += d[u] * d[v] * r[u][v]
            }
        }
        check(abs(kf! - total) <= 1e-7 * total, "effective graph resistance \(kf!) against Σ R \(total)")
        let k = commute / volume
        check(abs(kemeny! - k) <= 1e-7 * k, "Kemeny constant \(kemeny!) against Σ dᵢdⱼR/vol \(k)")
    }
}
