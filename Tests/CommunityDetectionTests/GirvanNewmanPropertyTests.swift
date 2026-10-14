// Girvan–Newman against an oracle written inside the test, with shrinking (swift-property-based).
// Graphs are multigraphs with self-loops on up to 8 vertices, listed in an order chosen by a seed
// (seed 0 keeps 0, 1, 2, …), with incidence rows shuffled by the same seed. The oracle recomputes
// edge betweenness on the whole remaining graph by the definition (breadth-first distances and
// path counts over the edge list, by vertex value, parallel copies distinct), removes the greatest
// (least position on a tie), and records the components each time their number grows. Floating
// sums can split a tie of the exact values either way, so the levels are compared up to the first
// removal whose greatest score is within 1e-9 of another's; the shape of the whole sequence is
// checked always: n − c levels (c components; one level without non-loop edges), each splitting
// one community of the last in two, ending with every vertex alone.

import CommunityDetection
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

@Suite("Girvan–Newman against an oracle, with shrinking", .tags(.randomized))
struct GirvanNewmanPropertyTests {
    @Test("Girvan–Newman's levels are the oracle's (whole-graph recomputation, least position on ties) up to the first near tie; the sequence always has n − c levels, each splitting one community in two, ending with every vertex alone")
    func levels() async {
        let pairs = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: pairs, Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            func components(_ alive: [Bool]) -> Set<Set<Int>> {
                var label = Array(0 ..< n)
                func find(_ x: Int) -> Int { label[x] == x ? x : find(label[x]) }
                for (k, (a, b)) in ends.enumerated() where alive[k] { label[find(a)] = find(b) }
                var groups: [Int: Set<Int>] = [:]
                for v in 0 ..< n { groups[find(v), default: []].insert(v) }
                return Set(groups.values)
            }
            // Ordered-pair edge betweenness of the edges left, by the definition.
            func scores(_ alive: [Bool]) -> [Double] {
                var arcs: [(Int, Int, Int)] = []
                for (k, (a, b)) in ends.enumerated() where alive[k] && a != b {
                    arcs.append((k, a, b))
                    arcs.append((k, b, a))
                }
                var d = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
                var sigma = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
                for s in 0 ..< n {
                    d[s][s] = 0
                    sigma[s][s] = 1
                    var frontier = [s], depth = 0
                    while !frontier.isEmpty {
                        depth += 1
                        var next: [Int] = []
                        for (_, a, b) in arcs where frontier.contains(a) {
                            if d[s][b] == nil {
                                d[s][b] = depth
                                next.append(b)
                            }
                            if d[s][b] == depth { sigma[s][b] += sigma[s][a] }
                        }
                        frontier = next
                    }
                }
                var bc = [Double](repeating: 0, count: ends.count)
                for s in 0 ..< n {
                    for t in 0 ..< n where t != s {
                        guard let st = d[s][t] else { continue }
                        for (k, a, b) in arcs {
                            if let sa = d[s][a], let bt = d[b][t], sa + 1 + bt == st { bc[k] += sigma[s][a] * sigma[b][t] / sigma[s][t] }
                        }
                    }
                }
                return bc
            }
            var alive = ends.map { $0.0 != $0.1 }
            var expected: [Set<Set<Int>>] = []
            var count = components(alive).count
            while alive.contains(true) {
                let bc = scores(alive)
                let live = ends.indices.filter { alive[$0] }
                let best = live.max { bc[$0] < bc[$1] || (bc[$0] == bc[$1] && $0 > $1) }!
                if live.contains(where: { $0 != best && abs(bc[$0] - bc[best]) <= 1e-9 * max(1, bc[best]) }) { break }
                alive[best] = false
                let now = components(alive)
                if now.count > count {
                    count = now.count
                    expected.append(now)
                }
            }
            let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            let levels = Array(graph.girvanNewmanCommunities())
            let sets = levels.map { level in Set(level.map { Set($0) }) }
            #expect(Array(sets.prefix(expected.count)) == expected, "\(ends), seed \(seed)")
            // The shape of the whole sequence.
            let start = components(ends.map { _ in true }).count
            let hasEdges = ends.contains { $0.0 != $0.1 }
            #expect(levels.count == (hasEdges ? n - start : 1), "\(ends)")
            if !hasEdges { #expect(sets.first == components(ends.map { _ in false }), "\(ends)") }
            if hasEdges { #expect(levels.first?.count == start + 1, "\(ends)") }
            #expect(levels.last?.count == n, "\(ends)")
            for (previous, next) in zip(levels, levels.dropFirst()) {
                #expect(next.count == previous.count + 1)
                for community in next { #expect(Set(community.map { previous.community(of: $0) }).count == 1, "\(ends)") }
            }
            for level in levels {
                for (i, v) in graph.vertices.enumerated() { #expect(level.community(ofIndex: i) == level.community(of: v)) }
            }
        }
    }
}
