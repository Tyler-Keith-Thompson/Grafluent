// §E: greedy modularity (Clauset–Newman–Moore): merge the adjacent pair of greatest ΔQ while ΔQ ≥ 0,
// ties to the least pair (i, j) with i merged into j, NetworkX's `greedy_modularity_communities`;
// `resolution`, weights, parallel edges, loops and `DirectedGraph`. CD-173 (total weight 0, not a
// trap) is here too.
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); scalars compare within 1e-12 relative to max(1, |value|), partitions
// exactly, in canonical order (communities by least vertex number, each in `vertices` order). Every
// partition row also checks `count`, `community(of:)` against membership, `community(ofIndex:)`
// against `community(of:)`, and the modularity of the result (at the call's weight and resolution)
// against ref.py's; undirected rows of the measures, Louvain and greedy modularity also run on
// `graph.directed` (the same values). Case IDs (CD-nnn) refer to the catalog; see README.md.

import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Greedy modularity (Clauset–Newman–Moore)")
struct GreedyModularityTests {
    @Test("CD-115 U(K(0..2), K(3..5), 2-3).greedyModularityCommunities() is [[0, 1, 2], [3, 4, 5]]")
    func greedy115() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities()
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
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-116 U(K(0..4), K(5..9), 4-5).greedyModularityCommunities() is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]")
    func greedy116() {
        // U: K(0..4), K(5..9), 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities()
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
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-117 U(nx(ring_of_cliques,4,4)).greedyModularityCommunities() is the catalog's partition (4 communities)")
    func greedy117() {
        // U: nx(ring_of_cliques,4,4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 13), (1, 2), (1, 3), (1, 4), (2, 3), (4, 5),
            (4, 6), (4, 7), (5, 6), (5, 7), (5, 8), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11),
            (9, 12), (10, 11), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
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
        #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-118 U(nx(connected_caveman,4,5)).greedyModularityCommunities() is the catalog's partition (4 communities)")
    func greedy118() {
        // U: nx(connected_caveman,4,5)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 19), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (9, 10),
            (10, 12), (10, 13), (10, 14), (11, 12), (11, 13), (11, 14), (12, 13), (12, 14), (13, 14),
            (14, 15), (15, 17), (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 18), (17, 19),
            (18, 19)]
        let graph = ReferencePseudograph(vertices: 0 ..< 20, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities()
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
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-119 U(nx(karate_club)).greedyModularityCommunities() is the catalog's partition (3 communities): Q = 0.3807; igraph `community_fastgreedy` reaches the same Q")
    func greedy119() {
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
        let result = graph.greedyModularityCommunities()
        let expected: [[Int]] = [[0, 4, 5, 6, 10, 11, 16, 19], [1, 2, 3, 7, 9, 12, 13, 17, 21],
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
        #expect(abs(q - 0.3806706114398422) <= 1e-12 * max(1, abs(0.3806706114398422)))
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-120 U(nx(karate_club)).greedyModularityCommunities().count is 3")
    func greedy120() {
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
        let result = graph.greedyModularityCommunities()
        #expect(result.count == 3)
        #expect(result.reduce(0) { $0 + $1.count } == graph.vertexCount)
        for (c, community) in result.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
    }

    @Test("CD-121 U(nx(karate_club)).greedyModularityCommunities(weight: […]) is the catalog's partition (3 communities)")
    func greedy121() {
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
        let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5,
            1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4,
            3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
        let result = graph.greedyModularityCommunities(weight: { w[$0] })
        let expected: [[Int]] = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
            [8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
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
        #expect(abs(q - 0.4345214669889994) <= 1e-12 * max(1, abs(0.4345214669889994)))
        let arcs = graph.directed.greedyModularityCommunities(weight: { w[$0.position] })
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-122 U(nx(karate_club)).greedyModularityCommunities(resolution: 0.5) is the catalog's partition (2 communities)")
    func greedy122() {
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
        let result = graph.greedyModularityCommunities(resolution: 0.5)
        let expected: [[Int]] = [[0, 1, 3, 4, 5, 6, 7, 10, 11, 12, 13, 16, 17, 19, 21],
            [2, 8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
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
        let q = graph.modularity(of: result, resolution: 0.5)
        #expect(abs(q - 0.6158777120315582) <= 1e-12 * max(1, abs(0.6158777120315582)))
        let arcs = graph.directed.greedyModularityCommunities(resolution: 0.5)
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-123 U(nx(karate_club)).greedyModularityCommunities(resolution: 2) is the catalog's partition (7 communities)")
    func greedy123() {
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
        let result = graph.greedyModularityCommunities(resolution: 2)
        let expected: [[Int]] = [[0, 4, 5, 6, 10, 11, 16], [1, 17, 19, 21], [2, 9, 28], [3, 7, 12, 13],
            [8, 30], [14, 15, 18, 20, 22, 26, 29, 32, 33], [23, 24, 25, 27, 31]]
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
        let q = graph.modularity(of: result, resolution: 2)
        #expect(abs(q - 0.16354372123602892) <= 1e-12 * max(1, abs(0.16354372123602892)))
        let arcs = graph.directed.greedyModularityCommunities(resolution: 2)
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-124 U(nx(florentine_families)).greedyModularityCommunities() is the catalog's partition (3 communities)")
    func greedy124() {
        // U: nx(florentine_families)
        let pairs: [(String, String)] = [("Acciaiuoli", "Medici"), ("Medici", "Barbadori"),
            ("Medici", "Ridolfi"), ("Medici", "Tornabuoni"), ("Medici", "Albizzi"), ("Medici", "Salviati"),
            ("Castellani", "Peruzzi"), ("Castellani", "Strozzi"), ("Castellani", "Barbadori"),
            ("Peruzzi", "Strozzi"), ("Peruzzi", "Bischeri"), ("Strozzi", "Ridolfi"), ("Strozzi", "Bischeri"),
            ("Ridolfi", "Tornabuoni"), ("Tornabuoni", "Guadagni"), ("Albizzi", "Ginori"),
            ("Albizzi", "Guadagni"), ("Salviati", "Pazzi"), ("Bischeri", "Guadagni"),
            ("Guadagni", "Lamberteschi")]
        let listed: [String] = ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori",
            "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori",
            "Lamberteschi"]
        let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities()
        let expected: [[String]] = [["Acciaiuoli", "Medici", "Ridolfi", "Tornabuoni", "Salviati", "Pazzi"],
            ["Castellani", "Peruzzi", "Strozzi", "Barbadori", "Bischeri"],
            ["Albizzi", "Guadagni", "Ginori", "Lamberteschi"]]
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
        #expect(abs(q - 0.39874999999999994) <= 1e-12 * max(1, abs(0.39874999999999994)))
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-125 U(P(0,1,2,3,4,5,6,7)).greedyModularityCommunities() is [[0, 1, 2, 3], [4, 5, 6, 7]]: Ties: the least pair (u, v), u merged into v")
    func greedy125() {
        // U: P(0,1,2,3,4,5,6,7)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7)]
        let graph = ReferencePseudograph(vertices: 0 ..< 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7]]
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
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-126 U(C(0,1,2,3,4,5,6,7,8,9)).greedyModularityCommunities() is [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9]]")
    func greedy126() {
        // U: C(0,1,2,3,4,5,6,7,8,9)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9),
            (9, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9]]
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
        #expect(abs(q - 0.33999999999999997) <= 1e-12 * max(1, abs(0.33999999999999997)))
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-127 U(K(0..2), K(3..5), 2-3, 2-3, 0-0).greedyModularityCommunities() is [[0, 1], [2, 3, 4, 5]]: Parallel edges and loops")
    func greedy127() {
        // U: K(0..2), K(3..5), 2-3, 2-3, 0-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3), (2, 3), (0, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities()
        let expected: [[Int]] = [[0, 1], [2, 3, 4, 5]]
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
        #expect(abs(q - 0.22222222222222227) <= 1e-12 * max(1, abs(0.22222222222222227)))
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-128 U(K(0..2), K(3..5)).greedyModularityCommunities(resolution: 0) is [[0, 1, 2], [3, 4, 5]]: γ = 0: ΔQ ≥ 0 for every adjacent pair, so components")
    func greedy128() {
        // U: K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities(resolution: 0)
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
        let q = graph.modularity(of: result, resolution: 0)
        #expect(abs(q - 1) <= 1e-12 * max(1, abs(1)))
        let arcs = graph.directed.greedyModularityCommunities(resolution: 0)
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-129 U(lcg(40,90,7)).greedyModularityCommunities() is the catalog's partition (5 communities)")
    func greedy129() {
        // U: lcg(40,90,7)
        let pairs: [(Int, Int)] = [(38, 31), (25, 19), (24, 4), (19, 6), (32, 0), (29, 2), (5, 19), (36, 31),
            (16, 33), (14, 18), (13, 24), (0, 25), (13, 32), (32, 37), (30, 35), (13, 19), (9, 27), (12, 32),
            (5, 15), (8, 10), (20, 24), (26, 10), (12, 14), (37, 28), (34, 11), (8, 16), (26, 3), (39, 13),
            (3, 20), (35, 25), (20, 3), (32, 18), (1, 38), (30, 3), (8, 5), (38, 21), (10, 14), (32, 15),
            (16, 32), (17, 39), (18, 27), (39, 19), (5, 1), (37, 34), (8, 38), (35, 36), (5, 23), (16, 6),
            (5, 12), (35, 24), (14, 31), (1, 3), (28, 0), (5, 14), (2, 21), (30, 7), (7, 6), (18, 30),
            (10, 28), (32, 34), (25, 33), (10, 29), (23, 1), (25, 15), (33, 3), (9, 34), (0, 20), (24, 35),
            (2, 13), (33, 14), (17, 23), (1, 18), (35, 13), (25, 9), (19, 36), (37, 10), (7, 20), (0, 27),
            (21, 22), (31, 34), (31, 18), (23, 34), (18, 30), (28, 13), (6, 32), (9, 17), (24, 5), (11, 33),
            (38, 37), (6, 4)]
        let listed: [Int] = [38, 31, 25, 19, 24, 4, 6, 32, 0, 29, 2, 5, 36, 16, 33, 14, 18, 13, 37, 30, 35,
            9, 27, 12, 15, 8, 10, 20, 26, 28, 34, 11, 3, 39, 1, 21, 17, 23, 7, 22]
        let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities()
        let expected: [[Int]] = [[38, 29, 2, 16, 33, 8, 10, 26, 11, 21, 22],
            [31, 19, 24, 36, 13, 35, 39, 17], [25, 32, 0, 37, 9, 27, 15, 28, 34], [4, 6, 18, 30, 20, 3, 7],
            [5, 14, 12, 1, 23]]
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
        #expect(abs(q - 0.3493827160493827) <= 1e-12 * max(1, abs(0.3493827160493827)))
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-130 U(lcg(30,60,3)).greedyModularityCommunities(weight: e%5+1) is the catalog's partition (5 communities)")
    func greedy130() {
        // U: lcg(30,60,3)
        let pairs: [(Int, Int)] = [(29, 13), (5, 28), (24, 23), (25, 5), (29, 9), (13, 12), (26, 9), (28, 5),
            (9, 19), (7, 26), (5, 16), (11, 6), (25, 24), (19, 24), (11, 19), (5, 18), (21, 3), (18, 19),
            (25, 9), (0, 16), (0, 17), (5, 19), (19, 8), (11, 16), (25, 5), (16, 11), (5, 16), (14, 11),
            (1, 20), (7, 25), (5, 21), (11, 7), (29, 9), (12, 6), (29, 14), (3, 0), (7, 9), (18, 15),
            (9, 19), (24, 6), (15, 13), (19, 1), (10, 16), (19, 15), (29, 15), (8, 17), (25, 27), (15, 8),
            (2, 4), (25, 16), (27, 25), (3, 4), (8, 17), (18, 19), (26, 29), (6, 17), (27, 25), (11, 25),
            (23, 29), (15, 26)]
        let listed: [Int] = [29, 13, 5, 28, 24, 23, 25, 9, 12, 26, 19, 7, 16, 11, 6, 18, 21, 3, 0, 17, 8, 14,
            1, 20, 15, 10, 27, 2, 4]
        let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.greedyModularityCommunities(weight: { Double($0 % 5 + 1) })
        let expected: [[Int]] = [[29, 13, 9, 26, 7, 14, 15], [5, 28, 25, 16, 11, 0, 10, 27], [24, 23, 12, 6],
            [19, 18, 17, 8, 1, 20], [21, 3, 2, 4]]
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
        let q = graph.modularity(of: result, weight: { Double($0 % 5 + 1) })
        #expect(abs(q - 0.41766975308641974) <= 1e-12 * max(1, abs(0.41766975308641974)))
        let arcs = graph.directed.greedyModularityCommunities(weight: { Double($0.position % 5 + 1) })
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-131 D(C(0,1,2), C(3,4,5), 2>3).greedyModularityCommunities() is [[0, 1, 2], [3, 4, 5]]: Directed")
    func greedy131() {
        // D: C(0,1,2), C(3,4,5), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.greedyModularityCommunities()
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
        #expect(abs(q - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
    }

    @Test("CD-132 D(lcg(40,100,5)).greedyModularityCommunities() is the catalog's partition (5 communities)")
    func greedy132() {
        // D: lcg(40,100,5)
        let pairs: [(Int, Int)] = [(32, 13), (34, 5), (15, 11), (19, 29), (10, 24), (35, 34), (28, 11),
            (33, 37), (28, 23), (2, 20), (30, 24), (8, 2), (21, 14), (1, 14), (9, 19), (10, 9), (35, 33),
            (35, 13), (25, 29), (20, 1), (14, 38), (30, 4), (14, 36), (28, 34), (32, 20), (7, 16), (30, 10),
            (31, 17), (1, 12), (21, 5), (14, 36), (31, 38), (12, 10), (35, 39), (31, 32), (28, 9), (11, 12),
            (12, 21), (38, 0), (14, 35), (27, 1), (7, 21), (7, 22), (2, 17), (8, 6), (14, 25), (8, 31),
            (17, 14), (26, 15), (1, 23), (29, 30), (7, 23), (35, 38), (33, 7), (28, 3), (11, 25), (29, 15),
            (23, 18), (23, 2), (4, 13), (35, 32), (33, 23), (16, 29), (24, 2), (8, 12), (27, 7), (32, 35),
            (24, 27), (29, 15), (10, 25), (35, 5), (10, 2), (6, 0), (39, 23), (9, 14), (12, 14), (1, 8),
            (23, 19), (8, 11), (22, 17), (27, 34), (16, 29), (13, 22), (37, 31), (23, 12), (31, 5), (19, 4),
            (15, 5), (2, 13), (24, 1), (19, 12), (10, 19), (12, 23), (27, 3), (30, 15), (25, 4), (13, 2),
            (17, 28), (7, 6), (7, 26)]
        let listed: [Int] = [32, 13, 34, 5, 15, 11, 19, 29, 10, 24, 35, 28, 33, 37, 23, 2, 20, 30, 8, 21, 14,
            1, 9, 25, 38, 4, 36, 7, 16, 31, 17, 12, 39, 0, 27, 22, 6, 26, 3, 18]
        let graph = ReferenceDirectedMultigraph(vertices: listed, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.greedyModularityCommunities()
        let expected: [[Int]] = [[32, 34, 5, 35, 33, 37, 31, 39], [13, 2, 20, 17, 22],
            [15, 29, 30, 25, 4, 7, 16, 26], [11, 19, 10, 24, 28, 23, 8, 1, 9, 12, 27, 3, 18],
            [21, 14, 38, 36, 0, 6]]
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
        #expect(abs(q - 0.35609999999999997) <= 1e-12 * max(1, abs(0.35609999999999997)))
    }

    @Test("CD-173 U(P(0,1,2)).greedyModularityCommunities(weight: [0, 0]) is [[0], [1], [2]]: Not a trap: total weight 0 gives singletons (NetworkX divides by 0)")
    func greedy173() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0, 0]
        let result = graph.greedyModularityCommunities(weight: { w[$0] })
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
        let q = graph.modularity(of: result, weight: { w[$0] })
        #expect(abs(q) <= 1e-12)
        let arcs = graph.directed.greedyModularityCommunities(weight: { w[$0.position] })
        #expect(arcs == result, "graph.directed")
    }

    // MARK: - Merges with ΔQ = 0 continue (api.md; not a catalog row)

    @Test("D(0>1).greedyModularityCommunities() is [[0, 1]]: ΔQ = 1/m − (a₀b₁ + b₀a₁) = 0, and a merge with ΔQ = 0 continues (NetworkX agrees)")
    func greedyZeroGainArc() {
        // D: 0>1
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        let result = graph.greedyModularityCommunities()
        #expect(result.map { Array($0) } == [[0, 1]])
        #expect(abs(graph.modularity(of: result)) <= 1e-12)
    }

    @Test("U(K(0..2), K(3..5), 2-3).greedyModularityCommunities(weight: [1, 1, 1, 1, 1, 1, 0], resolution: 0) is one community: the zero-weight bridge has ΔQ = 0 at γ = 0, and the merge continues")
    func greedyZeroGainBridge() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1, 1, 1, 1, 1, 1, 0]
        let result = graph.greedyModularityCommunities(weight: { w[$0] }, resolution: 0)
        #expect(result.map { Array($0) } == [[0, 1, 2, 3, 4, 5]])
        let arcs = graph.directed.greedyModularityCommunities(weight: { w[$0.position] }, resolution: 0)
        #expect(arcs == result, "graph.directed")
    }
}
