// Edge betweenness and betweenness from pivots against oracles written inside each test, with
// shrinking (swift-property-based). Graphs are multigraphs with self-loops on up to 7 vertices,
// listed in an order chosen by a seed (seed 0 keeps 0, 1, 2, …), with incidence or out-edge rows
// shuffled by the same seed. The oracle works over the edge list by vertex value: Floyd–Warshall
// distances, shortest-path counts σ over edge sequences, and for each ordered pair (s, t) each arc
// a → b of a non-loop edge on a shortest path (d(s, a) + w + d(b, t) = d(s, t)) credited
// σ(s, a) · σ(b, t) / σ(s, t). The estimate from pivots is the same sum over the pivots' pairs,
// scaled as Brandes and Pich (and NetworkX's `_rescale`) scale it.

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

@Suite("Edge betweenness and pivots against oracles, with shrinking", .tags(.randomized))
struct EdgeBetweennessPropertyTests {
    @Test("Edge betweenness equals Σ σ(s, a)·σ(b, t)/σ(s, t) over ordered pairs and arcs on shortest paths (parallel copies distinct, loops 0), unweighted, Int and Double weights, normalized or not, undirected and directed, from every vertex or from pivots")
    func edgeDefinition() async {
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 1 ... 3)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 2), Gen.bool, Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, weighting, normalized, isDirected, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            // weighting 0: unweighted; 1: Int 1 … 3; 2: the same as Double (exact ties).
            let w: [Int] = n == 0 ? [] : raw.map { weighting == 0 ? 1 : $0.2 }
            // Pivots: every vertex whose bit in the seed is set, or every vertex when none is.
            var pivots = (0 ..< n).filter { (seed >> $0) & 1 == 1 }
            if pivots.isEmpty { pivots = Array(0 ..< n) }
            // Oracle: arcs (edge number, a, b, weight), Floyd–Warshall, σ by increasing distance.
            var arcs: [(Int, Int, Int, Int)] = []
            for (k, (a, b)) in ends.enumerated() where a != b {
                arcs.append((k, a, b, w[k]))
                if !isDirected { arcs.append((k, b, a, w[k])) }
            }
            var d = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for i in 0 ..< n { d[i][i] = 0 }
            for (_, a, b, c) in arcs where d[a][b] == nil || c < d[a][b]! { d[a][b] = c }
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
                    for (_, a, b, c) in arcs where b == v {
                        if let da = d[s][a], da + c == d[s][v]! { sigma[s][v] += sigma[s][a] }
                    }
                }
            }
            func sums(_ sources: [Int]) -> [Double] {
                var bc = [Double](repeating: 0, count: ends.count)
                for s in sources {
                    for t in 0 ..< n where t != s {
                        guard let st = d[s][t] else { continue }
                        for (k, a, b, c) in arcs {
                            if let sa = d[s][a], let bt = d[b][t], sa + c + bt == st {
                                bc[k] += sigma[s][a] * sigma[b][t] / sigma[s][t]
                            }
                        }
                    }
                }
                return bc
            }
            func scaled(_ bc: [Double], k: Int) -> [Double] {
                guard n >= 2 else { return bc }
                let scale = normalized ? 1 / (Double(k) * Double(n - 1)) : Double(n) / (Double(k) * (isDirected ? 1 : 2))
                return bc.map { $0 * scale }
            }
            let exact = scaled(sums(Array(0 ..< n)), k: n)
            let estimate = scaled(sums(pivots), k: pivots.count)
            func check(_ got: [Double], _ want: [Double], _ label: String) {
                #expect(got.count == want.count, "\(label)")
                for (g, x) in zip(got, want) {
                    #expect(abs(g - x) <= 1e-9 * max(1, abs(x)), "\(label): \(ends), weights \(w), normalized \(normalized), pivots \(pivots)")
                }
            }
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let result: EdgeCentralityScores<Int>
                let fromPivots: EdgeCentralityScores<Int>
                if weighting == 0 {
                    result = graph.edgeBetweennessCentrality(normalized: normalized)
                    fromPivots = graph.edgeBetweennessCentrality(pivots: pivots, normalized: normalized)
                } else if weighting == 1 {
                    result = graph.edgeBetweennessCentrality(weight: { w[$0] }, normalized: normalized)
                    fromPivots = graph.edgeBetweennessCentrality(weight: { w[$0] }, pivots: pivots, normalized: normalized)
                } else {
                    result = graph.edgeBetweennessCentrality(weight: { Double(w[$0]) }, normalized: normalized)
                    fromPivots = graph.edgeBetweennessCentrality(weight: { Double(w[$0]) }, pivots: pivots, normalized: normalized)
                }
                check(ends.indices.map { result.score(ofEdgeAt: $0) }, exact, "directed")
                check(fromPivots.scores, estimate, "directed, pivots")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let result: EdgeCentralityScores<Int>
                let fromPivots: EdgeCentralityScores<Int>
                if weighting == 0 {
                    result = graph.edgeBetweennessCentrality(normalized: normalized)
                    fromPivots = graph.edgeBetweennessCentrality(pivots: pivots, normalized: normalized)
                } else if weighting == 1 {
                    result = graph.edgeBetweennessCentrality(weight: { w[$0] }, normalized: normalized)
                    fromPivots = graph.edgeBetweennessCentrality(weight: { w[$0] }, pivots: pivots, normalized: normalized)
                } else {
                    result = graph.edgeBetweennessCentrality(weight: { Double(w[$0]) }, normalized: normalized)
                    fromPivots = graph.edgeBetweennessCentrality(weight: { Double(w[$0]) }, pivots: pivots, normalized: normalized)
                }
                check(ends.indices.map { result.score(ofEdgeAt: $0) }, exact, "undirected")
                check(fromPivots.scores, estimate, "undirected, pivots")
                // The directed view: an edge's two arcs add up to twice its undirected sum (ordered pairs).
                let view = graph.directedView.edgeBetweennessCentrality(normalized: false)
                let halves = graph.edgeBetweennessCentrality(normalized: false)
                if weighting == 0 {
                    for k in ends.indices {
                        let total = view.score(ofEdgeAt: .init(position: k, reversed: false)) + view.score(ofEdgeAt: .init(position: k, reversed: true))
                        #expect(abs(total - 2 * halves.score(ofEdgeAt: k)) <= 1e-9 * max(1, total), "graph.directedView: \(ends)")
                    }
                }
            }
        }
    }

    @Test("Unweighted, Σ over edges of the ordered-pair sums is Σ d(s, t) over reachable pairs: each shortest path crosses d(s, t) edges")
    func edgeSumIsDistanceSum() async {
        let pairs = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 18)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 1 ... 8), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, seed in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            var total = 0
            for s in 0 ..< n {
                var dist = [Int?](repeating: nil, count: n)
                dist[s] = 0
                var queue = [s], head = 0
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
                total += dist.compactMap { $0 }.reduce(0, +)
            }
            let sum: Double
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                sum = graph.edgeBetweennessCentrality(normalized: false).scores.reduce(0, +)
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                sum = 2 * graph.edgeBetweennessCentrality(normalized: false).scores.reduce(0, +)
            }
            #expect(abs(sum - Double(total)) <= 1e-9 * max(1, Double(total)), "\(ends), directed \(isDirected)")
        }
    }

    @Test("Vertex betweenness from pivots equals the oracle's sums over the pivots' searches, scaled by N/k off the pivots and N/(k − 1) on them (N = n − 1, or n with endpoints, every vertex by n/k), unweighted and weighted, undirected and directed")
    func vertexPivots() async {
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 1 ... 3)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 1 ... 7), Gen.bool, Gen.int(in: 0 ... 3), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, weighted, scaling, isDirected, seed in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let w = raw.map { weighted ? $0.2 : 1 }
            let normalized = scaling % 2 == 0
            let endpoints = scaling >= 2
            var pivots = (0 ..< n).filter { (seed >> $0) & 1 == 1 }
            if pivots.isEmpty { pivots = [seed % n] }
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
            for s in pivots {
                for t in 0 ..< n where t != s {
                    guard let st = d[s][t] else { continue }
                    if endpoints {
                        bc[s] += 1
                        bc[t] += 1
                    }
                    for v in 0 ..< n where v != s && v != t {
                        if let sv = d[s][v], let vt = d[v][t], sv + vt == st { bc[v] += sigma[s][v] * sigma[v][t] / sigma[s][t] }
                    }
                }
            }
            let big = Double(endpoints ? n : n - 1), k = Double(pivots.count)
            let correction: Double = isDirected ? 1 : 2
            var expected = bc
            if big >= 2 {
                for v in 0 ..< n {
                    let onPivot = !endpoints && pivots.contains(v)
                    let sources = onPivot ? k - 1 : k
                    expected[v] *= normalized ? 1 / (sources * (big - 1)) : big / (sources * correction)
                }
            }
            let got: [Double]
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let result = weighted
                    ? graph.betweennessCentrality(weight: { w[$0] }, pivots: pivots, normalized: normalized, endpoints: endpoints)
                    : graph.betweennessCentrality(pivots: pivots, normalized: normalized, endpoints: endpoints)
                got = (0 ..< n).map { result.score(of: $0) }
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let result = weighted
                    ? graph.betweennessCentrality(weight: { w[$0] }, pivots: pivots, normalized: normalized, endpoints: endpoints)
                    : graph.betweennessCentrality(pivots: pivots, normalized: normalized, endpoints: endpoints)
                got = (0 ..< n).map { result.score(of: $0) }
            }
            for v in 0 ..< n {
                if expected[v].isNaN {
                    // One pivot without endpoints: 0/0, unless nothing is scaled.
                    #expect(got[v].isNaN, "\(ends), pivots \(pivots), vertex \(v)")
                } else {
                    #expect(abs(got[v] - expected[v]) <= 1e-9 * max(1, abs(expected[v])), "\(ends), weights \(w), pivots \(pivots), normalized \(normalized), endpoints \(endpoints), vertex \(v)")
                }
            }
        }
    }
}
