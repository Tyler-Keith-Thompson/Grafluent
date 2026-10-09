// §C: the maximum clique and the clique number (CQ-201 – CQ-220). `maximumClique()` is the
// lexicographically least largest clique by vertex index: of two disjoint triangles the one with the
// least index, also when `vertices` is reversed (CQ-203) or the edges are written the other way
// round (CQ-205); the first vertex of an edgeless graph (CQ-207, where NetworkX's
// `max_weight_clique` returns the last); [0, 1, 2, 3, 7] over [0, 1, 2, 3, 13] on the karate club
// (CQ-211). Each test also checks `maximumClique().count == cliqueNumber()`, `cliqueNumber() <=
// degeneracy + 1` and `graph.directed.undirected`. Every literal is a catalog cell (`ref.py`:
// brute force over the maximal cliques, NetworkX 3.7). Case IDs (CQ-nnn) refer to the catalog; see
// README.md.

import Cliques
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Maximum clique and clique number")
struct MaximumCliqueTests {
    @Test("CQ-201 U(K(0..2), K(3..5)).maximumClique is [0, 1, 2]: Two triangles: the first")
    func maximumClique201() {
        // U: K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-202 U(K(0..2), K(3..5)).cliqueNumber is #3")
    func cliqueNumber202() {
        // U: K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 3)
        #expect(graph.maximumClique().count == 3)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(3 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 3)
    }

    @Test("CQ-203 U([5, 4, 3, 2, 1, 0] K(0..2), K(3..5)).maximumClique is [5, 4, 3]: `vertices` reversed: [5, 4, 3] has indices [0, 1, 2]")
    func maximumClique203() {
        // U: [5, 4, 3, 2, 1, 0] K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(vertices: [5, 4, 3, 2, 1, 0], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [5, 4, 3]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-204 U([5, 4, 3, 2, 1, 0] K(0..2), K(3..5)).cliqueNumber is #3")
    func cliqueNumber204() {
        // U: [5, 4, 3, 2, 1, 0] K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(vertices: [5, 4, 3, 2, 1, 0], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 3)
        #expect(graph.maximumClique().count == 3)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(3 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 3)
    }

    @Test("CQ-205 U(K(3..5), K(0..2)).maximumClique is [3, 4, 5]: Edge order does not matter")
    func maximumClique205() {
        // U: K(3..5), K(0..2)
        let pairs: [(Int, Int)] = [(3, 4), (3, 5), (4, 5), (0, 1), (0, 2), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [3, 4, 5]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-206 U(K(3..5), K(0..2)).cliqueNumber is #3")
    func cliqueNumber206() {
        // U: K(3..5), K(0..2)
        let pairs: [(Int, Int)] = [(3, 4), (3, 5), (4, 5), (0, 1), (0, 2), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 3)
        #expect(graph.maximumClique().count == 3)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(3 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 3)
    }

    @Test("CQ-207 U([0, 1, 2]).maximumClique is [0]: Edgeless: the first vertex (NetworkX `max_weight_clique(weight=None)`: `[2]`, the last)")
    func maximumClique207() {
        // U: [0, 1, 2]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2], edges: [])
        let expected: [Int] = [0]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-208 U([0, 1, 2]).cliqueNumber is #1")
    func cliqueNumber208() {
        // U: [0, 1, 2]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2], edges: [])
        #expect(graph.cliqueNumber() == 1)
        #expect(graph.maximumClique().count == 1)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(1 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 1)
    }

    @Test("CQ-209 U(KB(0..2;3..5)).maximumClique is [0, 3]: Bipartite: an edge, the least")
    func maximumClique209() {
        // U: KB(0..2;3..5)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 3]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-210 U(KB(0..2;3..5)).cliqueNumber is #2")
    func cliqueNumber210() {
        // U: KB(0..2;3..5)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 2)
        #expect(graph.maximumClique().count == 2)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(2 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 2)
    }

    @Test("CQ-211 U(nx(karate_club)).maximumClique is [0, 1, 2, 3, 7]: Two 5-cliques, [0, 1, 2, 3, 7] and [0, 1, 2, 3, 13] (igraph `largest_cliques`: both)")
    func maximumClique211() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2, 3, 7]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-212 U(nx(karate_club)).cliqueNumber is #5")
    func cliqueNumber212() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17),
            (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16),
            (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33),
            (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27),
            (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33),
            (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33),
            (32, 33)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 5)
        #expect(graph.maximumClique().count == 5)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(5 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 5)
    }

    @Test("CQ-213 U(S(0;1..5), C(1..5)).maximumClique is [0, 1, 2]")
    func maximumClique213() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1, 2]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-214 U(S(0;1..5), C(1..5)).cliqueNumber is #3")
    func cliqueNumber214() {
        // U: S(0;1..5), C(1..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 3)
        #expect(graph.maximumClique().count == 3)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(3 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 3)
    }

    @Test("CQ-215 U(C(0..4), K(5..8)).maximumClique is [5, 6, 7, 8]")
    func maximumClique215() {
        // U: C(0..4), K(5..8)
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)
        ]
        let graph = ReferencePseudograph(vertices: [5, 6, 7, 8, 0, 1, 2, 3, 4], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [5, 6, 7, 8]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-216 U(C(0..4), K(5..8)).cliqueNumber is #4")
    func cliqueNumber216() {
        // U: C(0..4), K(5..8)
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)
        ]
        let graph = ReferencePseudograph(vertices: [5, 6, 7, 8, 0, 1, 2, 3, 4], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 4)
        #expect(graph.maximumClique().count == 4)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(4 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 4)
    }

    @Test("CQ-217 U(moon(3)).maximumClique is [0, 3, 6]")
    func maximumClique217() {
        // U: moon(3)
        let pairs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
            (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 6), (3, 7), (3, 8), (4, 6),
            (4, 7), (4, 8), (5, 6), (5, 7), (5, 8)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 3, 6]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-218 U(moon(3)).cliqueNumber is #3")
    func cliqueNumber218() {
        // U: moon(3)
        let pairs: [(Int, Int)] = [
            (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
            (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 6), (3, 7), (3, 8), (4, 6),
            (4, 7), (4, 8), (5, 6), (5, 7), (5, 8)
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 3)
        #expect(graph.maximumClique().count == 3)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(3 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 3)
    }

    @Test("CQ-219 U(P(0..3), 3-3, 3-3).maximumClique is [0, 1]")
    func maximumClique219() {
        // U: P(0..3), 3-3, 3-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 3), (3, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected: [Int] = [0, 1]
        #expect(graph.maximumClique() == expected)
        #expect(graph.cliqueNumber() == expected.count)
        #expect(graph.directed.undirected.maximumClique() == expected)
    }

    @Test("CQ-220 U(P(0..3), 3-3, 3-3).cliqueNumber is #2")
    func cliqueNumber220() {
        // U: P(0..3), 3-3, 3-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 3), (3, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.cliqueNumber() == 2)
        #expect(graph.maximumClique().count == 2)
        let degeneracy = graph.coreNumbers().degeneracy
        #expect(2 <= degeneracy + 1)
        #expect(graph.directed.undirected.cliqueNumber() == 2)
    }
}
