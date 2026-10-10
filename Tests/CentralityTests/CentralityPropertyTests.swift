// Properties against oracles written inside each test, with shrinking (swift-property-based): on a
// failure, PropertyBased shrinks the generated input and prints the smallest one that still fails.
// Graphs are multigraphs with self-loops on up to 8 vertices (betweenness: 7), listed in an order
// chosen by a seed (seed 0 keeps 0, 1, 2, …), with incidence or out-edge rows shuffled by the same
// seed, so `score(ofIndex:)` (by position in `vertices`) and `score(of:)` (by value) differ. The
// oracles use only the definitions over the edge list, by vertex value: breadth-first search and
// Floyd–Warshall for incoming distances (closeness, harmonic), shortest-path counts over edge
// sequences and Σ σ_sv·σ_vt/σ_st for betweenness, and dense iterations run to convergence on the
// adjacency matrix as api.md defines it (an undirected loop twice, parallel copies adding) for
// eigenvector, Katz, PageRank and HITS. The iterative measures are called with a tight tolerance
// and a large iteration budget, so they are compared with the limit. See README.md.

import Centrality
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

/// An undirected multigraph on `0..<vertexCount`, its vertices listed in a seeded order and its
/// incidence rows (built in position order, a self-loop twice) shuffled by the same seed, unless
/// the seed is 0. Vertex indices are positions in `vertices`; edge indices are positions.
private struct ShuffledPseudograph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    private let index: [Int]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [UndirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() {
            rows[edge.u].append(k)
            rows[edge.v].append(k)
        }
        var listed = Array(0 ..< vertexCount)
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
            listed.shuffle(using: &rng)
        }
        var index = [Int](repeating: 0, count: vertexCount)
        for (i, v) in listed.enumerated() { index[v] = i }
        self.vertices = listed
        self.edges = edges
        self.index = index
        self.rows = rows
    }

    func incidentEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func neighbors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { index[vertex] }
    func vertex(atIndex i: Int) -> Int { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

/// A directed multigraph on `0..<vertexCount`, its vertices listed in a seeded order and its
/// out-edge rows (built in position order) shuffled by the same seed, unless the seed is 0.
private struct ShuffledDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    private let index: [Int]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [DirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() { rows[edge.source].append(k) }
        var listed = Array(0 ..< vertexCount)
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
            listed.shuffle(using: &rng)
        }
        var index = [Int](repeating: 0, count: vertexCount)
        for (i, v) in listed.enumerated() { index[v] = i }
        self.vertices = listed
        self.edges = edges
        self.index = index
        self.rows = rows
    }

    func outEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func successors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].target } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { index[vertex] }
    func vertex(atIndex i: Int) -> Int { vertices[i] }
}

@Suite("Centrality properties against oracles, with shrinking", .tags(.randomized))
struct CentralityPropertyTests {
    @Test("Degree, in-degree and out-degree centrality equal the counts over the edge list ÷ (n − 1), loops twice undirected; graph.directed doubles them")
    func degree() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 16)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 0 ... 9), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            // Oracle: counts by vertex value.
            var outCount = [Int](repeating: 0, count: n)
            var inCount = [Int](repeating: 0, count: n)
            for (a, b) in ends {
                outCount[a] += 1
                inCount[b] += 1
            }
            func scaled(_ d: Int) -> Double { n == 1 ? 1 : Double(d) / Double(n - 1) }
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let total = graph.degreeCentrality()
                let ins = graph.inDegreeCentrality()
                let outs = graph.outDegreeCentrality()
                #expect(total.scores.count == n)
                for v in 0 ..< n {
                    let totalError = abs(total.score(of: v) - scaled(outCount[v] + inCount[v]))
                    #expect(totalError <= 1e-12, "\(ends), vertex \(v)")
                    let inError = abs(ins.score(of: v) - scaled(inCount[v]))
                    #expect(inError <= 1e-12, "\(ends), vertex \(v)")
                    let outError = abs(outs.score(of: v) - scaled(outCount[v]))
                    #expect(outError <= 1e-12, "\(ends), vertex \(v)")
                }
                let byIndex = graph.vertices.map { total.score(of: $0) }
                #expect(byIndex == total.scores)
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let result = graph.degreeCentrality()
                let arcs = graph.directed.degreeCentrality()
                #expect(result.scores.count == n)
                for v in 0 ..< n {
                    let expected = scaled(outCount[v] + inCount[v])
                    let error = abs(result.score(of: v) - expected)
                    #expect(error <= 1e-12, "\(ends), vertex \(v)")
                    let doubled = n == 1 ? 1 : 2 * expected
                    let arcError = abs(arcs.score(of: v) - doubled)
                    #expect(arcError <= 1e-12, "graph.directed, vertex \(v)")
                }
                let byIndex = graph.vertices.map { result.score(of: $0) }
                #expect(byIndex == result.scores)
            }
        }
    }

    @Test("Unweighted closeness (both corrections) and harmonic equal breadth-first search over incoming distances, undirected and directed; the one-vertex forms and graph.directed agree")
    func closenessHarmonicUnweighted() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 16)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 0 ... 9), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            // Oracle: BFS from every vertex over the edge list by value; dist[v][u] is d(v, u).
            func distancesFrom(_ s: Int) -> [Int?] {
                var dist = [Int?](repeating: nil, count: n)
                dist[s] = 0
                var queue = [s]
                var head = 0
                while head < queue.count {
                    let x = queue[head]
                    head += 1
                    for (a, b) in ends {
                        var next: [Int] = []
                        if a == x { next.append(b) }
                        if !isDirected && b == x { next.append(a) }
                        for y in next where dist[y] == nil {
                            dist[y] = dist[x]! + 1
                            queue.append(y)
                        }
                    }
                }
                return dist
            }
            let dist = (0 ..< n).map { distancesFrom($0) }
            var closeness: [Double] = []
            var plain: [Double] = []
            var harmonic: [Double] = []
            for u in 0 ..< n {
                let incoming = (0 ..< n).compactMap { dist[$0][u] }
                let r = incoming.count
                let s = incoming.reduce(0, +)
                let base = s == 0 ? 0 : Double(r - 1) / Double(s)
                plain.append(base)
                closeness.append(s == 0 ? 0 : base * Double(r - 1) / Double(n - 1))
                harmonic.append(incoming.filter { $0 > 0 }.reduce(0.0) { $0 + 1 / Double($1) })
            }
            func check(_ got: [Double], _ want: [Double], _ label: String) {
                #expect(got.count == want.count, "\(label)")
                for (g, w) in zip(got, want) {
                    let error = abs(g - w)
                    #expect(error <= 1e-12 * max(1, abs(w)), "\(label): \(ends), directed \(isDirected), seed \(seed)")
                }
            }
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let c = graph.closenessCentrality()
                let p = graph.closenessCentrality(wfImproved: false)
                let h = graph.harmonicCentrality()
                check((0 ..< n).map { c.score(of: $0) }, closeness, "closeness")
                check((0 ..< n).map { p.score(of: $0) }, plain, "closeness without correction")
                check((0 ..< n).map { h.score(of: $0) }, harmonic, "harmonic")
                check((0 ..< n).map { graph.closenessCentrality(of: $0) }, closeness, "closeness(of:)")
                check((0 ..< n).map { graph.closenessCentrality(of: $0, wfImproved: false) }, plain, "closeness(of:) without correction")
                check((0 ..< n).map { graph.harmonicCentrality(of: $0) }, harmonic, "harmonic(of:)")
                check(graph.vertices.map { c.score(of: $0) }, c.scores, "score(of:) in vertices order")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let c = graph.closenessCentrality()
                let p = graph.closenessCentrality(wfImproved: false)
                let h = graph.harmonicCentrality()
                check((0 ..< n).map { c.score(of: $0) }, closeness, "closeness")
                check((0 ..< n).map { p.score(of: $0) }, plain, "closeness without correction")
                check((0 ..< n).map { h.score(of: $0) }, harmonic, "harmonic")
                check((0 ..< n).map { graph.closenessCentrality(of: $0) }, closeness, "closeness(of:)")
                check((0 ..< n).map { graph.harmonicCentrality(of: $0) }, harmonic, "harmonic(of:)")
                check(graph.vertices.map { c.score(of: $0) }, c.scores, "score(of:) in vertices order")
                let arcs = graph.directed.closenessCentrality()
                check((0 ..< n).map { arcs.score(of: $0) }, closeness, "graph.directed closeness")
                let arcsHarmonic = graph.directed.harmonicCentrality()
                check((0 ..< n).map { arcsHarmonic.score(of: $0) }, harmonic, "graph.directed harmonic")
            }
        }
    }

    @Test("Weighted closeness and harmonic (Int 0 … 4 and Double quarters, zeros included) equal Floyd–Warshall over incoming distances; a zero distance to another vertex adds nothing to harmonic")
    func closenessHarmonicWeighted() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 4)).array(of: 0 ... 16)
        await propertyCheck(count: 200, input: triples, Gen.int(in: 0 ... 8), Gen.bool, Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, quarters, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Int] = n == 0 ? [] : raw.map(\.2)
            let wd: [Double] = w.map { Double($0) / 4 }
            // Oracle: Floyd–Warshall over the edge list, by value, in Double (sums of quarters are exact).
            var d = [[Double?]](repeating: [Double?](repeating: nil, count: n), count: n)
            for i in 0 ..< n { d[i][i] = 0 }
            for (k, (a, b)) in ends.enumerated() where a != b {
                let c = quarters ? wd[k] : Double(w[k])
                if d[a][b] == nil || c < d[a][b]! { d[a][b] = c }
                if !isDirected, d[b][a] == nil || c < d[b][a]! { d[b][a] = c }
            }
            for k in 0 ..< n {
                for i in 0 ..< n {
                    for j in 0 ..< n {
                        if let x = d[i][k], let y = d[k][j], d[i][j] == nil || x + y < d[i][j]! { d[i][j] = x + y }
                    }
                }
            }
            var closeness: [Double] = []
            var harmonic: [Double] = []
            for u in 0 ..< n {
                let incoming = (0 ..< n).compactMap { d[$0][u] }
                let r = incoming.count
                let s = incoming.reduce(0, +)
                closeness.append(s == 0 ? 0 : Double(r - 1) / s * Double(r - 1) / Double(n - 1))
                harmonic.append(incoming.filter { $0 > 0 }.reduce(0.0) { $0 + 1 / $1 })
            }
            func check(_ got: [Double], _ want: [Double], _ label: String) {
                #expect(got.count == want.count, "\(label)")
                for (g, x) in zip(got, want) {
                    let error = abs(g - x)
                    #expect(error <= 1e-12 * max(1, abs(x)), "\(label): \(ends), weights \(w), quarters \(quarters), directed \(isDirected)")
                }
            }
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                if quarters {
                    let c = graph.closenessCentrality(weight: { wd[$0] })
                    let h = graph.harmonicCentrality(weight: { wd[$0] })
                    check((0 ..< n).map { c.score(of: $0) }, closeness, "closeness")
                    check((0 ..< n).map { h.score(of: $0) }, harmonic, "harmonic")
                    check((0 ..< n).map { graph.closenessCentrality(of: $0, weight: { wd[$0] }) }, closeness, "closeness(of:)")
                    check((0 ..< n).map { graph.harmonicCentrality(of: $0, weight: { wd[$0] }) }, harmonic, "harmonic(of:)")
                } else {
                    let c = graph.closenessCentrality(weight: { w[$0] })
                    let h = graph.harmonicCentrality(weight: { w[$0] })
                    check((0 ..< n).map { c.score(of: $0) }, closeness, "closeness")
                    check((0 ..< n).map { h.score(of: $0) }, harmonic, "harmonic")
                    check((0 ..< n).map { graph.closenessCentrality(of: $0, weight: { w[$0] }) }, closeness, "closeness(of:)")
                    check((0 ..< n).map { graph.harmonicCentrality(of: $0, weight: { w[$0] }) }, harmonic, "harmonic(of:)")
                }
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                if quarters {
                    let c = graph.closenessCentrality(weight: { wd[$0] })
                    let h = graph.harmonicCentrality(weight: { wd[$0] })
                    check((0 ..< n).map { c.score(of: $0) }, closeness, "closeness")
                    check((0 ..< n).map { h.score(of: $0) }, harmonic, "harmonic")
                    check((0 ..< n).map { graph.closenessCentrality(of: $0, weight: { wd[$0] }) }, closeness, "closeness(of:)")
                    let arcs = graph.directed.harmonicCentrality(weight: { wd[$0.position] })
                    check((0 ..< n).map { arcs.score(of: $0) }, harmonic, "graph.directed harmonic")
                } else {
                    let c = graph.closenessCentrality(weight: { w[$0] })
                    let h = graph.harmonicCentrality(weight: { w[$0] })
                    check((0 ..< n).map { c.score(of: $0) }, closeness, "closeness")
                    check((0 ..< n).map { h.score(of: $0) }, harmonic, "harmonic")
                    check((0 ..< n).map { graph.harmonicCentrality(of: $0, weight: { w[$0] }) }, harmonic, "harmonic(of:)")
                    let arcs = graph.directed.closenessCentrality(weight: { w[$0.position] })
                    check((0 ..< n).map { arcs.score(of: $0) }, closeness, "graph.directed closeness")
                }
            }
        }
    }

    @Test("Betweenness equals Σ σ_sv·σ_vt/σ_st over ordered pairs with path counts over edge sequences (parallel copies distinct, loops on no path), unweighted, Int and Double weights, every rescaling, undirected and directed; graph.directed keeps the normalized values and doubles the others")
    func betweennessDefinition() async {
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 1 ... 3)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 2), Gen.int(in: 0 ... 3), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, weighting, scaling, isDirected, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            // weighting 0: unweighted; 1: Int 1 … 3; 2: the same as Double (exact ties).
            let w: [Int] = n == 0 ? [] : raw.map { weighting == 0 ? 1 : $0.2 }
            let normalized = scaling % 2 == 0
            let endpoints = scaling >= 2
            // Oracle: Floyd–Warshall, then σ by increasing distance over the arcs, then the definition.
            var arcs: [(Int, Int, Int)] = []
            for (k, (a, b)) in ends.enumerated() where a != b {
                arcs.append((a, b, w[k]))
                if !isDirected { arcs.append((b, a, w[k])) }
            }
            var d = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for i in 0 ..< n { d[i][i] = 0 }
            for (a, b, c) in arcs where d[a][b] == nil || c < d[a][b]! { d[a][b] = c }
            for k in 0 ..< n {
                for i in 0 ..< n {
                    for j in 0 ..< n {
                        if let x = d[i][k], let y = d[k][j], d[i][j] == nil || x + y < d[i][j]! { d[i][j] = x + y }
                    }
                }
            }
            var sigma = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for s in 0 ..< n {
                sigma[s][s] = 1
                let order = (0 ..< n).filter { d[s][$0] != nil }.sorted { d[s][$0]! < d[s][$1]! }
                for v in order where v != s {
                    for (a, b, c) in arcs where b == v {
                        if let da = d[s][a], da + c == d[s][v]! { sigma[s][v] += sigma[s][a] }
                    }
                }
            }
            var bc = [Double](repeating: 0, count: n)
            for s in 0 ..< n {
                for t in 0 ..< n where t != s {
                    guard let st = d[s][t] else { continue }
                    if endpoints {
                        bc[s] += 1
                        bc[t] += 1
                    }
                    for v in 0 ..< n where v != s && v != t {
                        if let sv = d[s][v], let vt = d[v][t], sv + vt == st {
                            bc[v] += sigma[s][v] * sigma[v][t] / sigma[s][t]
                        }
                    }
                }
            }
            var scale = 1.0
            if normalized {
                if endpoints, n >= 2 { scale = 1 / Double(n * (n - 1)) }
                if !endpoints, n > 2 { scale = 1 / Double((n - 1) * (n - 2)) }
            } else if !isDirected {
                scale = 0.5
            }
            let expected = bc.map { $0 * scale }
            func check(_ got: [Double], _ want: [Double], _ label: String) {
                #expect(got.count == want.count, "\(label)")
                for (g, x) in zip(got, want) {
                    let error = abs(g - x)
                    #expect(error <= 1e-9 * max(1, abs(x)), "\(label): \(ends), weights \(w), normalized \(normalized), endpoints \(endpoints)")
                }
            }
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let result: CentralityScores<ShuffledDigraph>
                if weighting == 0 {
                    result = graph.betweennessCentrality(normalized: normalized, endpoints: endpoints)
                } else if weighting == 1 {
                    result = graph.betweennessCentrality(weight: { w[$0] }, normalized: normalized, endpoints: endpoints)
                } else {
                    result = graph.betweennessCentrality(weight: { Double(w[$0]) }, normalized: normalized, endpoints: endpoints)
                }
                check((0 ..< n).map { result.score(of: $0) }, expected, "directed")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let result: CentralityScores<DirectedView<ShuffledPseudograph>>
                let viaArcs: CentralityScores<DirectedView<ShuffledPseudograph>>
                if weighting == 0 {
                    result = graph.betweennessCentrality(normalized: normalized, endpoints: endpoints)
                    viaArcs = graph.directed.betweennessCentrality(normalized: normalized, endpoints: endpoints)
                } else if weighting == 1 {
                    result = graph.betweennessCentrality(weight: { w[$0] }, normalized: normalized, endpoints: endpoints)
                    viaArcs = graph.directed.betweennessCentrality(weight: { w[$0.position] }, normalized: normalized, endpoints: endpoints)
                } else {
                    result = graph.betweennessCentrality(weight: { Double(w[$0]) }, normalized: normalized, endpoints: endpoints)
                    viaArcs = graph.directed.betweennessCentrality(weight: { Double(w[$0.position]) }, normalized: normalized, endpoints: endpoints)
                }
                check((0 ..< n).map { result.score(of: $0) }, expected, "undirected")
                let factor = normalized ? 1.0 : 2.0
                check((0 ..< n).map { viaArcs.score(of: $0) }, expected.map { factor * $0 }, "graph.directed")
            }
        }
    }

    @Test("Eigenvector centrality equals the limit of the dense power iteration on Aᵀ + I, on connected undirected and strongly connected directed multigraphs with loops, unweighted and weighted; norm 1, non-negative")
    func eigenvector() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 1 ... 8)).array(of: 0 ... 12)
        await propertyCheck(count: 150, input: triples, Gen.int(in: 1 ... 8), Gen.bool, Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, weighted, seed in
            // A spanning path (undirected) or a Hamiltonian cycle (directed) keeps the Perron vector unique.
            var ends: [(Int, Int)] = isDirected ? (n > 1 ? (0 ..< n).map { ($0, ($0 + 1) % n) } : []) : (0 ..< max(0, n - 1)).map { ($0, $0 + 1) }
            var w: [Double] = Array(repeating: 1, count: ends.count)
            ends += raw.map { ($0.0 % n, $0.1 % n) }
            w += raw.map { weighted ? Double($0.2) / 4 : 1 }
            // Oracle: A as rows list it (an undirected loop twice), iterate x ← (Aᵀ + I)x / ‖·‖₂.
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for (k, (s, t)) in ends.enumerated() {
                a[s][t] += w[k]
                if !isDirected { a[t][s] += w[k] }
            }
            var x = [Double](repeating: 1 / Double(n), count: n)
            for _ in 0 ..< 200_000 {
                var y = x
                for s in 0 ..< n { for t in 0 ..< n { y[t] += a[s][t] * x[s] } }
                let norm = y.reduce(0) { $0 + $1 * $1 }.squareRoot()
                y = y.map { $0 / norm }
                let change = zip(x, y).reduce(0) { $0 + abs($1.0 - $1.1) }
                x = y
                if change < 1e-15 { break }
            }
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let result = weighted
                    ? graph.eigenvectorCentrality(weight: { w[$0] }, tolerance: 1e-13, maxIterations: 100_000)
                    : graph.eigenvectorCentrality(tolerance: 1e-13, maxIterations: 100_000)
                guard let result else {
                    Issue.record("nil on a strongly connected digraph: \(ends), weights \(w)")
                    return
                }
                for v in 0 ..< n {
                    let error = abs(result.score(of: v) - x[v])
                    #expect(error <= 1e-7, "\(ends), weights \(w), vertex \(v)")
                }
                let norm = result.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
                #expect(abs(norm - 1) <= 1e-12)
                #expect(result.scores.allSatisfy { $0 >= 0 })
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let found = weighted
                    ? graph.eigenvectorCentrality(weight: { w[$0] }, tolerance: 1e-13, maxIterations: 100_000)
                    : graph.eigenvectorCentrality(tolerance: 1e-13, maxIterations: 100_000)
                let arcs = weighted
                    ? graph.directed.eigenvectorCentrality(weight: { w[$0.position] }, tolerance: 1e-13, maxIterations: 100_000)
                    : graph.directed.eigenvectorCentrality(tolerance: 1e-13, maxIterations: 100_000)
                guard let found, let arcs else {
                    Issue.record("nil on a connected graph: \(ends), weights \(w)")
                    return
                }
                for v in 0 ..< n {
                    let error = abs(found.score(of: v) - x[v])
                    #expect(error <= 1e-7, "\(ends), weights \(w), vertex \(v)")
                    let arcError = abs(arcs.score(of: v) - x[v])
                    #expect(arcError <= 1e-7, "graph.directed, vertex \(v)")
                }
                let norm = found.scores.reduce(0) { $0 + $1 * $1 }.squareRoot()
                #expect(abs(norm - 1) <= 1e-12)
                #expect(found.scores.allSatisfy { $0 >= 0 })
            }
        }
    }

    @Test("Katz equals the solution of (I − αAᵀ)x = β1 (normalized to norm 1 or not) for α below 1/ρ(A), on multigraphs with loops, unweighted and weighted; as α → 0 it tends to uniform")
    func katz() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 8)).array(of: 0 ... 14)
        await propertyCheck(count: 150, input: triples, Gen.int(in: 1 ... 8), Gen.bool, Gen.bool, Gen.int(in: 1 ... 4), Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, normalized, betaQuarters, seed in
            let ends: [(Int, Int)] = raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = raw.map { Double($0.2) / 4 }
            let beta = Double(betaQuarters) / 2
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for (k, (s, t)) in ends.enumerated() {
                a[s][t] += w[k]
                if !isDirected { a[t][s] += w[k] }
            }
            // ρ(A) is at most the greatest in-weight (column sum), so α = ½ / that converges at rate ≤ ½.
            let greatestColumn = (0 ..< n).map { t in (0 ..< n).reduce(0.0) { $0 + a[$1][t] } }.max()!
            let alpha = 0.5 / max(1, greatestColumn)
            // Oracle: Jacobi iteration x ← αAᵀx + β to a fixed point (a contraction by ½).
            var x = [Double](repeating: 0, count: n)
            for _ in 0 ..< 200 {
                x = (0 ..< n).map { t in alpha * (0 ..< n).reduce(0.0) { $0 + a[$1][t] * x[$1] } + beta }
            }
            if normalized {
                let norm = x.reduce(0) { $0 + $1 * $1 }.squareRoot()
                x = x.map { $0 / norm }
            }
            let tiny: CentralityScores<ShuffledDigraph>?
            let found: CentralityScores<ShuffledDigraph>?
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                found = graph.katzCentrality(weight: { w[$0] }, alpha: alpha, beta: beta, normalized: normalized, tolerance: 1e-14)
                tiny = graph.katzCentrality(weight: { w[$0] }, alpha: 1e-9, beta: beta, normalized: normalized)
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let undirected = graph.katzCentrality(weight: { w[$0] }, alpha: alpha, beta: beta, normalized: normalized, tolerance: 1e-14)
                let arcs = graph.directed.katzCentrality(weight: { w[$0.position] }, alpha: alpha, beta: beta, normalized: normalized, tolerance: 1e-14)
                guard let undirected, let arcs else {
                    Issue.record("nil below 1/ρ: \(ends), weights \(w), α \(alpha)")
                    return
                }
                for v in 0 ..< n {
                    let error = abs(undirected.score(of: v) - x[v])
                    #expect(error <= 1e-9 * max(1, abs(x[v])), "\(ends), weights \(w), vertex \(v)")
                    let arcError = abs(arcs.score(of: v) - x[v])
                    #expect(arcError <= 1e-9 * max(1, abs(x[v])), "graph.directed, vertex \(v)")
                }
                let unweighted = graph.katzCentrality(alpha: 1e-9, beta: beta, normalized: normalized)
                guard let unweighted else {
                    Issue.record("nil at α = 1e-9")
                    return
                }
                let uniform = normalized ? 1 / Double(n).squareRoot() : beta
                for v in 0 ..< n {
                    let error = abs(unweighted.score(of: v) - uniform)
                    #expect(error <= 1e-6 * max(1, uniform), "α → 0, vertex \(v)")
                }
                return
            }
            guard let found, let tiny else {
                Issue.record("nil below 1/ρ: \(ends), weights \(w), α \(alpha)")
                return
            }
            for v in 0 ..< n {
                let error = abs(found.score(of: v) - x[v])
                #expect(error <= 1e-9 * max(1, abs(x[v])), "\(ends), weights \(w), vertex \(v)")
                let uniform = normalized ? 1 / Double(n).squareRoot() : beta
                let tinyError = abs(tiny.score(of: v) - uniform)
                #expect(tinyError <= 1e-6 * max(1, uniform), "α → 0, vertex \(v)")
            }
        }
    }

    @Test("PageRank equals the limit of the dense iteration with dangling mass along the personalization, on multigraphs with loops, zero out-weights and random personalizations; it sums to 1")
    func pageRank() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 8)).array(of: 0 ... 14)
        let personal = Gen.int(in: 0 ... 4).array(of: 8 ... 8)
        await propertyCheck(count: 150, input: triples, Gen.int(in: 1 ... 8), Gen.bool, Gen.int(in: 0 ... 3), personal, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, dampingChoice, rawPersonal, seed in
            let ends: [(Int, Int)] = raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = raw.map { Double($0.2) / 4 }
            let damping = [0, 0.3, 0.85, 0.85][dampingChoice]
            let personalized = dampingChoice != 3
            var p: [Double] = (0 ..< n).map { Double(rawPersonal[$0]) }
            if p.allSatisfy({ $0 == 0 }) { p[0] = 1 }
            let pTotal = p.reduce(0, +)
            let jump = personalized ? p.map { $0 / pTotal } : [Double](repeating: 1 / Double(n), count: n)
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for (k, (s, t)) in ends.enumerated() {
                a[s][t] += w[k]
                if !isDirected { a[t][s] += w[k] }
            }
            let outWeight = a.map { $0.reduce(0, +) }
            let danglingVertices = (0 ..< n).filter { outWeight[$0] == 0 }
            let linking = (0 ..< n).filter { outWeight[$0] > 0 }
            // Oracle: x ← d(Pᵀx + dangling·p) + (1 − d)p from uniform, to a fixed point (a contraction by d).
            var x = [Double](repeating: 1 / Double(n), count: n)
            for _ in 0 ..< 400 {
                let dangling = danglingVertices.reduce(0.0) { $0 + x[$1] }
                x = (0 ..< n).map { t in
                    let flow = linking.reduce(0.0) { $0 + x[$1] * a[$1][t] / outWeight[$1] }
                    return damping * (flow + dangling * jump[t]) + (1 - damping) * jump[t]
                }
            }
            var results: [CentralityScores<ShuffledDigraph>?] = []
            var viewResults: [CentralityScores<DirectedView<ShuffledPseudograph>>?] = []
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                if personalized {
                    results.append(graph.pageRank(weight: { w[$0] }, dampingFactor: damping, personalization: { p[$0] }, tolerance: 1e-14, maxIterations: 10_000))
                } else {
                    results.append(graph.pageRank(weight: { w[$0] }, dampingFactor: damping, tolerance: 1e-14, maxIterations: 10_000))
                }
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                if personalized {
                    viewResults.append(graph.pageRank(weight: { w[$0] }, dampingFactor: damping, personalization: { p[$0] }, tolerance: 1e-14, maxIterations: 10_000))
                    viewResults.append(graph.directed.pageRank(weight: { w[$0.position] }, dampingFactor: damping, personalization: { p[$0] }, tolerance: 1e-14, maxIterations: 10_000))
                } else {
                    viewResults.append(graph.pageRank(weight: { w[$0] }, dampingFactor: damping, tolerance: 1e-14, maxIterations: 10_000))
                    viewResults.append(graph.directed.pageRank(weight: { w[$0.position] }, dampingFactor: damping, tolerance: 1e-14, maxIterations: 10_000))
                }
            }
            let scoreLists: [[Double]?] = results.map { r in r.map { s in (0 ..< n).map { s.score(of: $0) } } }
                + viewResults.map { r in r.map { s in (0 ..< n).map { s.score(of: $0) } } }
            for scores in scoreLists {
                guard let scores else {
                    Issue.record("nil: \(ends), weights \(w), d \(damping)")
                    continue
                }
                for v in 0 ..< n {
                    let error = abs(scores[v] - x[v])
                    #expect(error <= 1e-9, "\(ends), weights \(w), d \(damping), p \(p), vertex \(v)")
                }
                let total = scores.reduce(0, +)
                #expect(abs(total - 1) <= 1e-12)
            }
        }
    }

    @Test("HITS on graph.directed of a connected non-bipartite multigraph: hubs = authorities = eigenvector centrality rescaled to sum 1")
    func hitsSymmetric() async {
        let pairs = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 12)
        await propertyCheck(count: 150, input: pairs, Gen.int(in: 3 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            // A spanning path and the triangle 0-1-2: connected, not bipartite, so σ₁ = λ₁ is simple.
            var ends: [(Int, Int)] = (0 ..< n - 1).map { ($0, $0 + 1) } + [(0, 2)]
            ends += raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            let hits = graph.directed.hits(tolerance: 1e-13, maxIterations: 100_000)
            let eigenvector = graph.eigenvectorCentrality(tolerance: 1e-13, maxIterations: 100_000)
            guard let hits, let eigenvector else {
                Issue.record("nil: \(ends)")
                return
            }
            let total = eigenvector.scores.reduce(0, +)
            for v in 0 ..< n {
                let expected = eigenvector.score(of: v) / total
                let hubError = abs(hits.hubs.score(of: v) - expected)
                #expect(hubError <= 1e-7, "\(ends), vertex \(v)")
                let authorityError = abs(hits.authorities.score(of: v) - expected)
                #expect(authorityError <= 1e-7, "\(ends), vertex \(v)")
            }
        }
    }

    @Test("HITS equals the limit of the dense iteration a = Aᵀh, h = Aa from the uniform start, on random weighted digraphs; each vector sums to 1")
    func hitsGeneral() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 1 ... 8)).array(of: 1 ... 14)
        await propertyCheck(count: 150, input: triples, Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            let ends: [(Int, Int)] = raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = raw.map { Double($0.2) / 4 }
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            for (k, (s, t)) in ends.enumerated() { a[s][t] += w[k] }
            // Oracle: the iteration with the greatest entry rescaled to 1, then sums to 1.
            var h = [Double](repeating: 1 / Double(n), count: n)
            var auth = h
            var converged = false
            for _ in 0 ..< 20_000 {
                auth = (0 ..< n).map { t in (0 ..< n).reduce(0.0) { $0 + a[$1][t] * h[$1] } }
                var next = (0 ..< n).map { s in (0 ..< n).reduce(0.0) { $0 + a[s][$1] * auth[$1] } }
                let greatestHub = next.max()!
                let greatestAuthority = auth.max()!
                next = next.map { $0 / greatestHub }
                auth = auth.map { $0 / greatestAuthority }
                let change = zip(next, h).reduce(0) { $0 + abs($1.0 - $1.1) }
                h = next
                if change < 1e-15 {
                    converged = true
                    break
                }
            }
            // Slowly converging inputs (σ₂ close to σ₁) are left to the catalog.
            guard converged else { return }
            let hubTotal = h.reduce(0, +)
            let authorityTotal = auth.reduce(0, +)
            let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
            guard let result = graph.hits(weight: { w[$0] }, tolerance: 1e-13, maxIterations: 100_000) else {
                Issue.record("nil: \(ends), weights \(w)")
                return
            }
            for v in 0 ..< n {
                let hubError = abs(result.hubs.score(of: v) - h[v] / hubTotal)
                #expect(hubError <= 1e-6, "\(ends), weights \(w), vertex \(v)")
                let authorityError = abs(result.authorities.score(of: v) - auth[v] / authorityTotal)
                #expect(authorityError <= 1e-6, "\(ends), weights \(w), vertex \(v)")
            }
            let hubSum = result.hubs.scores.reduce(0, +)
            #expect(abs(hubSum - 1) <= 1e-12)
            let authoritySum = result.authorities.scores.reduce(0, +)
            #expect(abs(authoritySum - 1) <= 1e-12)
        }
    }
}
