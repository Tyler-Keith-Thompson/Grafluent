// forceAtlas2Layout quality (catalog DR-213, DR-214): the median over seeds 1…20 of
// Xoshiro256StarStar of the normalized stress, computed inline from `positions`, against the
// catalog's bound (1.1 × NetworkX's median).
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphDrawing
import GraphProtocols
import Multigraphs
import RandomGraphs
import Testing

@Suite("forceAtlas2Layout quality")
struct ForceAtlas2LayoutTests {
    @Test("DR-213 ForceAtlas2 quality, grid 5 x 5 (NetworkX median 0.0305)", .tags(.randomized))
    func dr213() {
        // U: grid(5,5); forceAtlas2Layout(using: &Xoshiro256StarStar(seed: s)), median over 1…20 → ≤ 0.034
        let graph = Pseudograph<Int>(vertices: 0 ..< 25, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6),
            UndirectedEdge(2, 3), UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(5, 10), UndirectedEdge(6, 7), UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 12), UndirectedEdge(8, 9),
            UndirectedEdge(8, 13), UndirectedEdge(9, 14), UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(11, 16),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(13, 18), UndirectedEdge(14, 19), UndirectedEdge(15, 16),
            UndirectedEdge(15, 20), UndirectedEdge(16, 17), UndirectedEdge(16, 21), UndirectedEdge(17, 18), UndirectedEdge(17, 22), UndirectedEdge(18, 19),
            UndirectedEdge(18, 23), UndirectedEdge(19, 24), UndirectedEdge(20, 21), UndirectedEdge(21, 22), UndirectedEdge(22, 23), UndirectedEdge(23, 24)])
        #expect(Array(graph.vertices) == Array(0 ..< 25) && graph.edgeCount == 40)
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        var values: [Double] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            values.append(normalizedStress(graph.forceAtlas2Layout(using: &generator).positions))
        }
        let sorted = values.sorted()
        let median = (sorted[9] + sorted[10]) / 2
        #expect(median <= 0.034, "median normalized stress \(median)")
    }

    @Test("DR-214 ForceAtlas2 quality, random graph, 40 vertices, 60 edges (NetworkX median 0.1101)", .tags(.randomized))
    func dr214() {
        // U: lcggraph(40,60,5); forceAtlas2Layout(using: &Xoshiro256StarStar(seed: s)), median over 1…20 → ≤ 0.122
        let graph = Pseudograph<Int>(vertices: 0 ..< 40, edges: [UndirectedEdge(32, 13), UndirectedEdge(34, 5), UndirectedEdge(15, 11),
            UndirectedEdge(19, 29), UndirectedEdge(10, 24), UndirectedEdge(35, 34), UndirectedEdge(28, 11), UndirectedEdge(33, 37), UndirectedEdge(28, 23),
            UndirectedEdge(2, 20), UndirectedEdge(30, 24), UndirectedEdge(8, 2), UndirectedEdge(21, 14), UndirectedEdge(1, 14), UndirectedEdge(9, 19),
            UndirectedEdge(10, 9), UndirectedEdge(35, 33), UndirectedEdge(35, 13), UndirectedEdge(25, 29), UndirectedEdge(20, 1), UndirectedEdge(14, 38),
            UndirectedEdge(30, 4), UndirectedEdge(14, 36), UndirectedEdge(28, 34), UndirectedEdge(32, 20), UndirectedEdge(7, 16), UndirectedEdge(30, 10),
            UndirectedEdge(31, 17), UndirectedEdge(1, 12), UndirectedEdge(21, 5), UndirectedEdge(14, 36), UndirectedEdge(31, 38), UndirectedEdge(12, 10),
            UndirectedEdge(35, 39), UndirectedEdge(31, 32), UndirectedEdge(28, 9), UndirectedEdge(11, 12), UndirectedEdge(12, 21), UndirectedEdge(38, 0),
            UndirectedEdge(14, 35), UndirectedEdge(27, 1), UndirectedEdge(7, 21), UndirectedEdge(7, 22), UndirectedEdge(2, 17), UndirectedEdge(8, 6),
            UndirectedEdge(14, 25), UndirectedEdge(8, 31), UndirectedEdge(17, 14), UndirectedEdge(26, 15), UndirectedEdge(1, 23), UndirectedEdge(29, 30),
            UndirectedEdge(7, 23), UndirectedEdge(35, 38), UndirectedEdge(33, 7), UndirectedEdge(28, 3), UndirectedEdge(11, 25), UndirectedEdge(29, 15),
            UndirectedEdge(23, 18), UndirectedEdge(23, 2), UndirectedEdge(4, 13)])
        #expect(Array(graph.vertices) == Array(0 ..< 40) && graph.edgeCount == 60)
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        var values: [Double] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            values.append(normalizedStress(graph.forceAtlas2Layout(using: &generator).positions))
        }
        let sorted = values.sorted()
        let median = (sorted[9] + sorted[10]) / 2
        #expect(median <= 0.122, "median normalized stress \(median)")
    }
}
