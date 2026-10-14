// Graph edit distance at sizes a debug build would take too long on: random pairs on 7 vertices
// against brute force over every partial injection, and pairs on 10 vertices (the Petersen graph
// against the 5-prism, G(10, 0.3) pairs) within a one-minute limit, the distance symmetric
// and the path optimal. Random graphs come from the package's seeded generator. See README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import IsomorphismModule
import Testing

@Suite("Graph edit distance on larger inputs")
struct GraphEditDistanceScaleTests {
    @Test("Random pairs on 7 vertices, edge probability 0.4: the distance equals brute force", .timeLimit(.minutes(1)))
    func againstBruteForce() async {
        await Task {
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 21)
            for _ in 0 ..< 12 {
                let n = 7
                var gPairs: [[Int]] = [], hPairs: [[Int]] = []
                for a in 0 ..< n {
                    for b in a + 1 ..< n {
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.4 { gPairs.append([a, b]) }
                        if Double.random(in: 0 ..< 1, using: &rng) < 0.4 { hPairs.append([a, b]) }
                    }
                }
                var gAdjacent = [Bool](repeating: false, count: n * n), hAdjacent = gAdjacent
                for p in gPairs { gAdjacent[p[0] * n + p[1]] = true; gAdjacent[p[1] * n + p[0]] = true }
                for p in hPairs { hAdjacent[p[0] * n + p[1]] = true; hAdjacent[p[1] * n + p[0]] = true }
                // Every partial injection: deleted and inserted vertices and edges cost 1.
                var best = Int.max
                var f = [Int](repeating: -1, count: n), taken = [Bool](repeating: false, count: n)
                func visit(_ u: Int, _ cost: Int) {
                    if cost >= best { return }
                    if u == n {
                        var total = cost + taken.filter { !$0 }.count
                        for p in hPairs where !taken[p[0]] || !taken[p[1]] { total += 1 }
                        best = min(best, total)
                        return
                    }
                    for x in -1 ..< n where x < 0 || !taken[x] {
                        // The vertex, then its pairs with the vertices already decided.
                        var step = x < 0 ? 1 : 0
                        for w in 0 ..< u {
                            let mine = gAdjacent[u * n + w]
                            let theirs = x >= 0 && f[w] >= 0 && hAdjacent[x * n + f[w]]
                            if x >= 0 && f[w] >= 0 { step += mine != theirs ? 1 : 0 } else { step += mine ? 1 : 0 }
                        }
                        f[u] = x
                        if x >= 0 { taken[x] = true }
                        visit(u + 1, cost + step)
                        if x >= 0 { taken[x] = false }
                        f[u] = -1
                    }
                }
                visit(0, 0)
                let g = UndirectedAdjacencyList(vertices: 0 ..< n, edges: gPairs.map { UndirectedEdge($0[0], $0[1]) })
                let h = UndirectedAdjacencyList(vertices: 0 ..< n, edges: hPairs.map { UndirectedEdge($0[0], $0[1]) })
                #expect(g.graphEditDistance(to: h) == best, "G \(gPairs), H \(hPairs)")
            }
        }.value
    }

    @Test("Pairs on 10 vertices: symmetric, with an optimal path, within the time limit", .timeLimit(.minutes(1)))
    func tenVertices() async throws {
        try await Task {
            let outer = (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) }, spokes = (0 ..< 5).map { UndirectedEdge($0, $0 + 5) }
            let petersen = UndirectedAdjacencyList<Int>(vertices: 0 ..< 10, edges: outer + spokes + (0 ..< 5).map { UndirectedEdge($0 + 5, ($0 + 2) % 5 + 5) })
            let prism = UndirectedAdjacencyList<Int>(vertices: 0 ..< 10, edges: outer + spokes + (0 ..< 5).map { UndirectedEdge($0 + 5, ($0 + 1) % 5 + 5) })
            var pairs = [(petersen, prism)]
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 33)
            for _ in 0 ..< 4 {
                var sides: [UndirectedAdjacencyList<Int>] = []
                for _ in 0 ..< 2 {
                    var edges: [UndirectedEdge<Int>] = []
                    for a in 0 ..< 10 { for b in a + 1 ..< 10 where Double.random(in: 0 ..< 1, using: &rng) < 0.3 { edges.append(UndirectedEdge(a, b)) } }
                    sides.append(UndirectedAdjacencyList(vertices: 0 ..< 10, edges: edges))
                }
                pairs.append((sides[0], sides[1]))
            }
            for (g, h) in pairs {
                let found = try #require(g.optimalEditPath(to: h))
                #expect(found.isOptimal)
                #expect(found.cost == found.deletedVertices.count + found.insertedVertices.count + found.deletedEdges.count + found.insertedEdges.count)
                #expect(h.graphEditDistance(to: g) == found.cost)
            }
        }.value
    }
}
