// Leading-eigenvector communities (Newman 2006): igraph 1.0's community_leading_eigenvector on the
// karate club and on small graphs, degenerate graphs, weights, and a property test: every split
// raised modularity, so the result is no worse than one community, and no community's own leading
// eigenvector split (computed densely in the test by Jacobi rotations) gains.

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("Leading-eigenvector communities")
struct LeadingEigenvectorTests {
    @Test("The karate club: igraph's four communities, Q = 0.3934")
    func karate() throws {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17),
            (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9),
            (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33),
            (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29),
            (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try graph.leadingEigenvectorCommunities()
        let membership = [0, 2, 2, 2, 0, 0, 0, 2, 1, 1, 0, 0, 2, 2, 1, 1, 0, 2, 1, 2, 1, 2, 1, 3, 3, 3, 1, 3, 3, 1, 1, 3, 1, 1]
        let expected = (0 ... 3).map { c in (0 ..< 34).filter { membership[$0] == c } }
        #expect(Set(result.map { Array($0) }) == Set(expected))
        #expect(abs(graph.modularity(of: result) - 0.3934089414858645) <= 1e-12)
        let weighted = try graph.leadingEigenvectorCommunities(weight: { _ in 3.0 })
        #expect(weighted == result)
    }

    @Test("Two triangles joined by an edge and two disjoint triangles: the triangles; no edges: singletons; K₄: one community")
    func small() throws {
        let tri: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let joined = ReferencePseudograph(vertices: 0 ..< 6, edges: tri.map { UndirectedEdge($0.0, $0.1) })
        #expect(try joined.leadingEigenvectorCommunities().map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
        let apart = ReferencePseudograph(vertices: 0 ..< 6, edges: tri.dropLast().map { UndirectedEdge($0.0, $0.1) })
        #expect(try apart.leadingEigenvectorCommunities().map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
        #expect(try ReferencePseudograph<Int>(vertices: 0 ..< 4, edges: []).leadingEigenvectorCommunities().map { Array($0) } == [[0], [1], [2], [3]])
        #expect(try ReferencePseudograph<Int>(vertices: [], edges: []).leadingEigenvectorCommunities().isEmpty)
        var k4: [UndirectedEdge<Int>] = []
        for i in 0 ..< 4 { for j in i + 1 ..< 4 { k4.append(UndirectedEdge(i, j)) } }
        #expect(try ReferencePseudograph(vertices: 0 ..< 4, edges: k4).leadingEigenvectorCommunities().map { Array($0) } == [[0, 1, 2, 3]])
        // A loop counts in the degrees only; parallel copies add.
        let multi = ReferencePseudograph(vertices: 0 ..< 6, edges: tri.map { UndirectedEdge($0.0, $0.1) } + [UndirectedEdge(0, 1), UndirectedEdge(4, 4)])
        #expect(try multi.leadingEigenvectorCommunities().map { Array($0) } == [[0, 1, 2], [3, 4, 5]])
        // All weights zero: total weight 0, singletons.
        #expect(try joined.leadingEigenvectorCommunities(weight: { _ in 0.0 }).count == 6)
    }

    @Test("A ring of eight K₁₀ (Lanczos from 64 vertices): the cliques; a one-product budget throws NoConvergence")
    func budget() throws {
        var pairs: [(Int, Int)] = []
        for c in 0 ..< 8 {
            for i in 0 ..< 10 { for j in i + 1 ..< 10 { pairs.append((10 * c + i, 10 * c + j)) } }
            pairs.append((10 * c + 9, 10 * ((c + 1) % 8)))
        }
        let graph = ReferencePseudograph(vertices: 0 ..< 80, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(try graph.leadingEigenvectorCommunities().map { Array($0) } == (0 ..< 8).map { Array(10 * $0 ..< 10 * $0 + 10) })
        #expect(throws: NoConvergence.self) { try graph.leadingEigenvectorCommunities(maxIterations: 1) }
    }

    @Test("Every community is indivisible: its leading eigenvector split gains no modularity", .tags(.randomized))
    func indivisible() async {
        let pairs = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 25)
        await propertyCheck(count: 100, input: pairs, Gen.int(in: 1 ... 10)) { raw, n in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            guard let result = try? graph.leadingEigenvectorCommunities() else {
                Issue.record("NoConvergence on \(ends)")
                return
            }
            #expect(result.reduce(0) { $0 + $1.count } == n)
            let m2 = Double(2 * ends.count)
            guard m2 > 0 else { return }
            #expect(graph.modularity(of: result) >= graph.modularity(of: [Array(0 ..< n)]) - 1e-12, "\(ends)")
            var a = [[Double]](repeating: [Double](repeating: 0, count: n), count: n)
            var k = [Double](repeating: 0, count: n)
            for (u, v) in ends {
                k[u] += 1
                k[v] += 1
                if u != v {
                    a[u][v] += 1
                    a[v][u] += 1
                }
            }
            for g in result.map(Array.init) where g.count > 1 && g.count <= 10 {
                let s = g.count
                let kg = g.reduce(0.0) { $0 + k[$1] }
                var b = [[Double]](repeating: [Double](repeating: 0, count: s), count: s)
                for i in 0 ..< s {
                    let rowSum = g.reduce(0.0) { $0 + a[g[i]][$1] } - k[g[i]] * kg / m2
                    for j in 0 ..< s { b[i][j] = a[g[i]][g[j]] - k[g[i]] * k[g[j]] / m2 - (i == j ? rowSum : 0) }
                }
                // The leading eigenpair by cyclic Jacobi rotations.
                var m = b
                var vectors = (0 ..< s).map { i in (0 ..< s).map { $0 == i ? 1.0 : 0 } }
                for _ in 0 ..< 100 {
                    for p in 0 ..< s {
                        for q in p + 1 ..< s where abs(m[p][q]) > 1e-15 {
                            let theta = (m[q][q] - m[p][p]) / (2 * m[p][q])
                            let t = (theta >= 0 ? 1.0 : -1.0) / (abs(theta) + (theta * theta + 1).squareRoot())
                            let c = 1 / (t * t + 1).squareRoot(), sn = t * c
                            for r in 0 ..< s {
                                let x = m[r][p], y = m[r][q]
                                m[r][p] = c * x - sn * y
                                m[r][q] = sn * x + c * y
                            }
                            for r in 0 ..< s {
                                let x = m[p][r], y = m[q][r]
                                m[p][r] = c * x - sn * y
                                m[q][r] = sn * x + c * y
                            }
                            for r in 0 ..< s {
                                let x = vectors[r][p], y = vectors[r][q]
                                vectors[r][p] = c * x - sn * y
                                vectors[r][q] = sn * x + c * y
                            }
                        }
                    }
                }
                let top = (0 ..< s).max { m[$0][$0] < m[$1][$1] }!
                let lambda = m[top][top]
                // Entries 0 up to rounding go together to the side of greater gain.
                let largest = (0 ..< s).map { abs(vectors[$0][top]) }.max()!
                var gain = -Double.infinity
                var split: [Double] = []
                for zeroSide in [-1.0, 1.0] {
                    let candidate = (0 ..< s).map { i -> Double in
                        let x = vectors[i][top]
                        return abs(x) <= 1e-9 * largest ? zeroSide : (x > 0 ? 1 : -1)
                    }
                    var q = 0.0
                    for i in 0 ..< s { for j in 0 ..< s { q += candidate[i] * b[i][j] * candidate[j] } }
                    if Set(candidate).count == 2, q > gain {
                        gain = q
                        split = candidate
                    }
                }
                // Degenerate leading eigenvalues leave the eigenvector, so the split, undetermined.
                let sorted = (0 ..< s).map { m[$0][$0] }.sorted()
                let degenerate = s > 1 && sorted[s - 1] - sorted[s - 2] < 1e-6
                if !degenerate {
                    #expect(lambda <= 1e-6 || gain <= 1e-6 || split.isEmpty, "community \(g) of \(ends): λ \(lambda), gain \(gain)")
                }
            }
        }
    }
}
