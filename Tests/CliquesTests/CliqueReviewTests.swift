// Shapes that would cost a quadratic setup or memory in a hub's degree if handled naively (a star
// whose hub comes last in degeneracy order, a star whose hub has index 0, a hub with many
// 5-cycles), a complete graph whose clique number must not restart its search at every size, and
// dense seeded graphs whose candidate sets span several 64-bit words, with values from
// NetworkX 3.7 (find_cliques, core_number, triangles) on the same edges: each pair (u, v), u < v,
// is an edge when the generator's next value is below the probability.
// CQ-1001 – CQ-1004, the large shapes, rely on speed and are in
// Performance/CliqueReviewScaleTests.swift. Case IDs (CQ-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Cliques
import GraphProtocols
import Testing

@Suite("Cliques review cases")
struct CliqueReviewTests {
    @Test("CQ-1005 maximalCliques() comes in the documented order exactly: degeneracy order, Tomita's pivot with ties to the least index, branches ascending", arguments: [(24, 2, 5, 3), (30, 1, 4, 4)])
    func documentedOrder(n: Int, numerator: UInt64, denominator: UInt64, seed: UInt64) {
        // Expected sequences from the order's reference model (scripts/differential.py,
        // maximal_cliques_in_order) on the same edges, rows in insertion order.
        let expected: [Int: [[Int]]] = [
            24: [[1, 6, 7, 15], [1, 7, 17], [7, 15, 22], [7, 17, 22], [0, 8, 12], [0, 8, 16], [0, 8, 22], [0, 13, 16], [0, 9, 13, 17], [0, 13, 17, 22], [1, 3, 11, 16, 21], [1, 3, 16, 20, 21], [1, 15, 16, 21], [2, 3, 11, 16, 21], [2, 3, 16, 20, 21], [5, 12, 23], [14, 17, 23], [14, 19, 23], [5, 11, 18, 23], [11, 18, 19, 23], [17, 18, 23], [3, 6, 12], [3, 10, 12, 20], [5, 8, 12, 20], [1, 9, 17], [1, 14, 17], [2, 9, 17], [2, 17, 22], [13, 14, 17], [3, 6, 18], [6, 15, 18], [3, 11, 18], [5, 15, 18], [15, 18, 19], [1, 3, 6], [1, 6, 9, 15], [1, 6, 14, 15], [4, 6, 9], [5, 9, 13], [5, 13, 22], [9, 10, 13, 19], [10, 13, 16, 19], [13, 14, 19], [13, 19, 22], [8, 14, 15], [14, 15, 19], [1, 14, 20], [8, 14, 20], [2, 4, 5, 8, 22], [2, 19, 22], [5, 8, 15, 22], [15, 19, 22], [1, 3, 10, 16, 20], [2, 3, 10, 16, 20], [1, 5, 9, 11], [2, 5, 9, 11], [2, 9, 11, 19], [2, 11, 16, 19], [2, 4, 5, 9], [2, 4, 9, 10], [2, 4, 10, 16], [2, 4, 8, 16], [2, 5, 8, 20], [2, 8, 16, 20], [8, 15, 16], [1, 5, 9, 15], [9, 15, 19], [15, 16, 19], [2, 9, 10, 19], [2, 10, 16, 19], [1, 5, 20], [1, 9, 10]],
            30: [[1, 3], [1, 16], [3, 9, 12], [12, 26], [9, 24], [24, 27], [24, 28], [2, 16, 17], [13, 16, 17], [0, 9], [5, 15, 20], [5, 15, 27], [5, 21], [0, 20], [7, 15, 20], [8, 20], [20, 22], [3, 6, 7, 15], [3, 6, 13], [3, 8], [3, 7, 23], [4, 6, 15], [6, 15, 26, 27], [7, 15, 17], [7, 21, 23], [11, 14, 23], [14, 21, 23], [14, 23, 25], [11, 23, 26], [6, 7, 29], [7, 17, 19, 21], [7, 19, 29], [0, 25, 27], [2, 6, 25], [6, 14, 25], [6, 25, 27], [2, 10, 25], [0, 13, 19, 29], [2, 17, 19], [13, 17, 19], [4, 8, 21], [4, 18, 21], [8, 14, 21], [14, 17, 21], [17, 18, 21], [8, 11, 14, 28], [11, 14, 17], [0, 11, 26, 27], [11, 22, 26, 27], [0, 27, 29], [6, 27, 29], [22, 27, 29], [0, 13, 26], [0, 18, 26], [2, 11, 17], [2, 17, 18], [2, 8, 11], [4, 8, 11], [8, 11, 26, 28], [10, 11, 28], [10, 13, 28, 29], [13, 26, 28], [6, 13, 26], [6, 13, 29], [2, 6, 18], [4, 6, 18], [6, 18, 26], [4, 6, 29], [2, 10, 11, 22], [4, 10, 11, 22], [4, 10, 22, 29], [2, 10, 18], [4, 10, 18]],
        ]
        var state = seed &* 0x9E37_79B9_7F4A_7C15
        var edges: [UndirectedEdge<Int>] = []
        for u in 0 ..< n {
            for v in u + 1 ..< n {
                state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                if (state >> 33) % denominator < numerator { edges.append(UndirectedEdge(u, v)) }
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
        let cliques = Array(graph.maximalCliques())
        #expect(cliques == expected[n])
    }

    @Test("CQ-1006 the pivot's tie goes to the least vertex index, not the first one met: a 16-vertex graph where the two differ")
    func pivotTieByIndex() {
        // Self-loops included (ignored); the expected order is the reference model's on the same
        // rows (scripts/differential.py, maximal_cliques_in_order).
        let pairs: [(Int, Int)] = [(5, 7), (5, 14), (7, 1), (11, 8), (8, 13), (4, 14), (15, 7), (14, 15), (13, 15), (7, 3), (1, 4), (6, 7), (12, 7), (1, 1), (10, 11), (9, 7), (11, 15), (9, 12), (3, 9), (2, 8), (11, 6), (0, 14), (12, 12), (0, 6), (10, 9), (1, 14), (0, 11), (13, 11), (12, 2), (14, 13), (15, 2), (8, 10), (7, 4), (3, 2), (7, 11), (5, 13), (4, 13), (4, 5), (9, 4), (9, 14), (6, 13), (1, 12), (9, 13), (1, 11), (0, 4), (7, 13), (2, 0), (9, 0), (11, 12), (1, 9), (13, 13), (14, 7), (1, 2), (2, 9), (3, 13), (14, 8), (0, 13), (14, 3), (0, 12), (2, 5), (1, 15), (5, 1), (6, 9), (5, 5), (7, 2), (15, 15), (12, 14), (9, 9), (4, 12), (4, 8)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [[Int]] = [[8, 10, 11], [9, 10], [2, 3, 7, 9], [3, 7, 9, 13, 14], [0, 6, 9, 13], [0, 6, 11, 13], [6, 7, 9, 13], [6, 7, 11, 13], [2, 8], [4, 8, 13, 14], [8, 11, 13], [1, 2, 5, 7], [1, 4, 5, 7, 14], [4, 5, 7, 13, 14], [1, 2, 7, 15], [1, 7, 11, 15], [1, 7, 14, 15], [7, 11, 13, 15], [7, 13, 14, 15], [1, 7, 11, 12], [0, 11, 12], [0, 2, 9, 12], [1, 2, 7, 9, 12], [0, 4, 9, 13, 14], [4, 7, 9, 13, 14], [0, 4, 9, 12, 14], [1, 4, 7, 9, 12, 14]]
        #expect(Array(graph.maximalCliques()) == expected)
    }
}
