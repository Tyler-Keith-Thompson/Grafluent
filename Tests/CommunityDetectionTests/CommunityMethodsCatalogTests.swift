// §J: Kernighan–Lin bisection from a given start (NetworkX's kernighan_lin_bisection, its heap ties
// included); k-clique communities (overlapping, NetworkX's k_clique_communities); Walktrap with exact
// Ward merges (ref.py's dense model, rechecked with Lance–Williams updates); leading-eigenvector
// communities (igraph's community_leading_eigenvector). Trap rows are exit tests.
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); scalars compare within 1e-12 relative to max(1, |value|), partitions
// exactly, in canonical order (communities by least vertex number, each in `vertices` order). Every
// partition row also checks `count`, `community(of:)` against membership, `community(ofIndex:)`
// against `community(of:)`, and the modularity of the result (at the call's weight and resolution)
// against ref.py's; undirected rows of the measures, Louvain and greedy modularity also run on
// `graph.directedView` (the same values). Case IDs (CD-nnn) refer to the catalog; see README.md.

import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Kernighan–Lin, k-clique, Walktrap and leading-eigenvector communities")
struct CommunityMethodsCatalogTests {
    @Test("CD-218 U(K(0..2), K(3..5), 2-3).kernighanLinBisection(startingFrom: [[0, 3, 4], [1, 2, 5]]) is [[0, 1, 2], [3, 4, 5]]: NetworkX `kernighan_lin_bisection` agrees")
    func kernighanLin218() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let start: [[Int]] = [[0, 3, 4], [1, 2, 5]]
        let result = graph.kernighanLinBisection(startingFrom: start)
        let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
    }

    @Test("CD-219 U(nx(karate_club)).kernighanLinBisection(startingFrom: […]) is the catalog's partition (2 communities): NetworkX agrees")
    func kernighanLin219() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let start: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
            [17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
        let result = graph.kernighanLinBisection(startingFrom: start)
        let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19, 21],
            [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.3717948717948718) <= 1e-12 * max(1, abs(0.3717948717948718)))
    }

    @Test("CD-220 U(nx(karate_club)).kernighanLinBisection(startingFrom: […], weight: […]) is the catalog's partition (2 communities): NetworkX agrees")
    func kernighanLin220() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let start: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
            [17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
        let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5,
            1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4,
            3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
        let result = graph.kernighanLinBisection(startingFrom: start, weight: { w[$0] })
        let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19, 21],
            [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result, weight: { w[$0] })
        #expect(abs(q - 0.3998332115215232) <= 1e-12 * max(1, abs(0.3998332115215232)))
    }

    @Test("CD-221 U(K(0..2), K(3..5), 2-3).kernighanLinBisection(startingFrom: [[0, 3, 4], [1, 2, 5]], iteration… is [[0, 3, 4], [1, 2, 5]]: No pass: the start")
    func kernighanLin221() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let start: [[Int]] = [[0, 3, 4], [1, 2, 5]]
        let result = graph.kernighanLinBisection(startingFrom: start, iterations: 0)
        let expected: [[Int]] = [[0, 3, 4], [1, 2, 5]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - -0.21428571428571425) <= 1e-12 * max(1, abs(-0.21428571428571425)))
    }

    @Test("CD-222 U([0..3]).kernighanLinBisection(startingFrom: [[0, 1], [2, 3]]) is [[0, 1], [2, 3]]: No edges: no pass lowers the cut")
    func kernighanLin222() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let start: [[Int]] = [[0, 1], [2, 3]]
        let result = graph.kernighanLinBisection(startingFrom: start)
        let expected: [[Int]] = [[0, 1], [2, 3]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q) <= 1e-12)
    }

    @Test("CD-223 U(P(0,1,2)).kernighanLinBisection(startingFrom: [[0], [1], [2]]) traps")
    func kernighanLin223() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let start: [[Int]] = [[0], [1], [2]]
            _ = graph.kernighanLinBisection(startingFrom: start)
        }
    }

    @Test("CD-224 U(nx(karate_club)).kCliqueCommunities(k: 3) is the catalog's partition (3 communities): NetworkX `k_clique_communities`; communities overlap")
    func kClique224() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.kCliqueCommunities(3)
        let expected: [[Int]] = [[0, 1, 2, 3, 7, 8, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23, 26, 27, 28, 29, 30, 31, 32, 33],
            [0, 4, 5, 6, 10, 16], [24, 25, 31]]
        #expect(result == expected)
    }

    @Test("CD-225 U(nx(karate_club)).kCliqueCommunities(k: 4) is [[0, 1, 2, 3, 7, 13], [8, 30, 32, 33], [23, 29, 32, 33]]")
    func kClique225() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.kCliqueCommunities(4)
        let expected: [[Int]] = [[0, 1, 2, 3, 7, 13], [8, 30, 32, 33], [23, 29, 32, 33]]
        #expect(result == expected)
    }

    @Test("CD-226 U(K(0..3), K(3..6)).kCliqueCommunities(k: 4) is [[0, 1, 2, 3], [3, 4, 5, 6]]: Two K4 sharing a vertex: separate, overlapping")
    func kClique226() {
        // U: K(0..3), K(3..6)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4), (3, 5), (3, 6),
            (4, 5), (4, 6), (5, 6)]
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.kCliqueCommunities(4)
        let expected: [[Int]] = [[0, 1, 2, 3], [3, 4, 5, 6]]
        #expect(result == expected)
    }

    @Test("CD-227 U(K(0..2), 1-3, 2-3, 3-4).kCliqueCommunities(k: 3) is [[0, 1, 2, 3]]: Two triangles sharing an edge percolate")
    func kClique227() {
        // U: K(0..2), 1-3, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.kCliqueCommunities(3)
        let expected: [[Int]] = [[0, 1, 2, 3]]
        #expect(result == expected)
    }

    @Test("CD-228 U(K(0..2), 1-3, 2-3, 3-4).kCliqueCommunities(k: 2) is [[0, 1, 2, 3, 4]]: k = 2: the components with an edge")
    func kClique228() {
        // U: K(0..2), 1-3, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.kCliqueCommunities(2)
        let expected: [[Int]] = [[0, 1, 2, 3, 4]]
        #expect(result == expected)
    }

    @Test("CD-229 U(P(0,1,2)).kCliqueCommunities(k: 1) traps")
    func kClique229() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.kCliqueCommunities(1)
        }
    }

    @Test("CD-230 U(K(0..2), K(3..5), 2-3).walktrapCommunities() is [[0, 1, 2], [3, 4, 5]]")
    func walktrap230() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.walktrapCommunities()
        let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
    }

    @Test("CD-231 U(nx(karate_club)).walktrapCommunities() is the catalog's partition (4 communities): Exact Ward merges; igraph's `community_walktrap` reads stale Δσ and cuts at Q = 0.3532")
    func walktrap231() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.walktrapCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
            [8, 9, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.41978961209730437) <= 1e-12 * max(1, abs(0.41978961209730437)))
    }

    @Test("CD-232 U(K(0..4), K(5..9), 4-5).walktrapCommunities(steps: 2) is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]")
    func walktrap232() {
        // U: K(0..4), K(5..9), 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.walktrapCommunities(steps: 2)
        let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
    }

    @Test("CD-233 U(nx(connected_caveman,4,5)).walktrapCommunities() is the catalog's partition (4 communities)")
    func walktrap233() {
        // U: nx(connected_caveman,4,5)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 19), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (9, 10),
            (10, 12), (10, 13), (10, 14), (11, 12), (11, 13), (11, 14), (12, 13), (12, 14), (13, 14),
            (14, 15), (15, 17), (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 18), (17, 19),
            (18, 19)]
        let graph = ReferencePseudograph(vertices: 0 ..< 20, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.walktrapCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14], [15, 16, 17, 18, 19]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.65) <= 1e-12 * max(1, abs(0.65)))
    }

    @Test("CD-234 U([0..2]).walktrapCommunities() is [[0], [1], [2]]: No edges: singletons")
    func walktrap234() {
        // U: [0..2]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.walktrapCommunities()
        let expected: [[Int]] = [[0], [1], [2]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q) <= 1e-12)
    }

    @Test("CD-235 U(P(0,1,2)).walktrapCommunities(steps: 0) traps")
    func walktrap235() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.walktrapCommunities(steps: 0)
        }
    }

    @Test("CD-236 U(K(0..2), K(3..5), 2-3).leadingEigenvectorCommunities() is [[0, 1, 2], [3, 4, 5]]: igraph `community_leading_eigenvector` agrees")
    func leadingEigenvector236() throws {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try graph.leadingEigenvectorCommunities()
        let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
    }

    @Test("CD-237 U(nx(karate_club)).leadingEigenvectorCommunities() is the catalog's partition (4 communities): igraph agrees: Q = 0.3934")
    func leadingEigenvector237() throws {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try graph.leadingEigenvectorCommunities()
        let expected: [[Int]] = [[0, 4, 5, 6, 10, 11, 16], [1, 2, 3, 7, 12, 13, 17, 19, 21],
            [8, 9, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.3934089414858645) <= 1e-12 * max(1, abs(0.3934089414858645)))
    }

    @Test("CD-238 U(nx(barbell,5,0)).leadingEigenvectorCommunities() is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]: The two K5 (a symmetric ring of cliques has a repeated leading eigenvalue, so no row)")
    func leadingEigenvector238() throws {
        // U: nx(barbell,5,0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try graph.leadingEigenvectorCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
    }

    @Test("CD-239 U([0..3]).leadingEigenvectorCommunities() is [[0], [1], [2], [3]]: Total weight 0: singletons (igraph agrees)")
    func leadingEigenvector239() throws {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try graph.leadingEigenvectorCommunities()
        let expected: [[Int]] = [[0], [1], [2], [3]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q) <= 1e-12)
    }

    @Test("CD-240 U(K(0..3)).leadingEigenvectorCommunities() is [[0, 1, 2, 3]]: λ ≤ 0: indivisible")
    func leadingEigenvector240() throws {
        // U: K(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = try graph.leadingEigenvectorCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q) <= 1e-12)
    }
}
