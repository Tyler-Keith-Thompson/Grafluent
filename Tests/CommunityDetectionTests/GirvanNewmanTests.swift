// §H: Girvan–Newman (2002): the partitions found by removing an edge of greatest betweenness again
// and again, coarsest first; `[k]` is the k-th. Ties go to the least edge position; parallel copies
// share their pairs' paths; self-loops never matter; a graph without non-loop edges lists its
// components once.
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

@Suite("Girvan–Newman")
struct GirvanNewmanTests {
    @Test("CD-175 U([]).girvanNewmanCommunities()[0] is []: No vertices: one empty partition")
    func girvanNewman175() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = Array(graph.girvanNewmanCommunities())[0]
        let expected: [[Int]] = []
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

    @Test("CD-176 U([0..3]).girvanNewmanCommunities()[0] is [[0], [1], [2], [3]]: No edges: the components once (NetworkX)")
    func girvanNewman176() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[0]
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

    @Test("CD-177 U(0-0, 1-1).girvanNewmanCommunities()[0] is [[0], [1]]: Self-loops only: the components once (NetworkX yields nothing here)")
    func girvanNewman177() {
        // U: 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[0]
        let expected: [[Int]] = [[0], [1]]
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
        #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
    }

    @Test("CD-178 U(K(0..2), K(3..5), 2-3).girvanNewmanCommunities()[0] is [[0, 1, 2], [3, 4, 5]]: The bridge carries every crossing pair")
    func girvanNewman178() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[0]
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

    @Test("CD-179 U(K(0..2), K(3..5), 2-3).girvanNewmanCommunities()[1] is [[0], [1, 2], [3, 4, 5]]: Then every triangle edge ties: 0-1 goes (least position), then 0-2 of the path left")
    func girvanNewman179() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[1]
        let expected: [[Int]] = [[0], [1, 2], [3, 4, 5]]
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
        #expect(abs(q - 0.17346938775510204) <= 1e-12 * max(1, abs(0.17346938775510204)))
    }

    @Test("CD-180 U(K(0..2), K(3..5), 2-3).girvanNewmanCommunities()[4] is [[0], [1], [2], [3], [4], [5]]: The last level: every vertex alone")
    func girvanNewman180() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[4]
        let expected: [[Int]] = [[0], [1], [2], [3], [4], [5]]
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
        #expect(abs(q - -0.173469387755102) <= 1e-12 * max(1, abs(-0.173469387755102)))
    }

    @Test("CD-181 U(K(0..4), K(5..9), 4-5).girvanNewmanCommunities()[0] is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]: Two K5 and their bridge")
    func girvanNewman181() {
        // U: K(0..4), K(5..9), 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[0]
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

    @Test("CD-182 U(nx(barbell,5,0)).girvanNewmanCommunities()[0] is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]")
    func girvanNewman182() {
        // U: nx(barbell,5,0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[0]
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

    @Test("CD-183 U(nx(connected_caveman,4,5)).girvanNewmanCommunities()[0] is the catalog's partition (2 communities)")
    func girvanNewman183() {
        // U: nx(connected_caveman,4,5)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 19), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (9, 10),
            (10, 12), (10, 13), (10, 14), (11, 12), (11, 13), (11, 14), (12, 13), (12, 14), (13, 14),
            (14, 15), (15, 17), (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 18), (17, 19),
            (18, 19)]
        let graph = ReferencePseudograph(vertices: 0 ..< 20, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[0]
        let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [10, 11, 12, 13, 14, 15, 16, 17, 18, 19]]
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
        #expect(abs(q - 0.44999999999999996) <= 1e-12 * max(1, abs(0.44999999999999996)))
    }

    @Test("CD-184 U(nx(karate_club)).girvanNewmanCommunities()[0] is the catalog's partition (2 communities): NetworkX agrees (no tie decides it)")
    func girvanNewman184() {
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
        let result = Array(graph.girvanNewmanCommunities())[0]
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
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.3599605522682445) <= 1e-12 * max(1, abs(0.3599605522682445)))
    }

    @Test("CD-185 U(nx(karate_club)).girvanNewmanCommunities()[1] is the catalog's partition (3 communities): Vertex 9 splits off")
    func girvanNewman185() {
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
        let result = Array(graph.girvanNewmanCommunities())[1]
        let expected: [[Int]] = [[0, 1, 3, 4, 5, 6, 7, 10, 11, 12, 13, 16, 17, 19, 21],
            [2, 8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33], [9]]
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
        #expect(abs(q - 0.3487836949375411) <= 1e-12 * max(1, abs(0.3487836949375411)))
    }

    @Test("CD-186 U(nx(karate_club)).girvanNewmanCommunities()[2] is the catalog's partition (4 communities)")
    func girvanNewman186() {
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
        let result = Array(graph.girvanNewmanCommunities())[2]
        let expected: [[Int]] = [[0, 1, 3, 7, 11, 12, 13, 17, 19, 21],
            [2, 8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33], [4, 5, 6, 10, 16], [9]]
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
        #expect(abs(q - 0.36324786324786323) <= 1e-12 * max(1, abs(0.36324786324786323)))
    }

    @Test("CD-187 U(nx(florentine_families)).girvanNewmanCommunities()[0] is the catalog's partition (2 communities): `String` vertices")
    func girvanNewman187() {
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
        let result = Array(graph.girvanNewmanCommunities())[0]
        let expected: [[String]] = [["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"],
            ["Salviati", "Pazzi"]]
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
        #expect(abs(q - 0.08875000000000005) <= 1e-12 * max(1, abs(0.08875000000000005)))
    }

    @Test("CD-188 U(P(0,1,2), 3-4, 2-2).girvanNewmanCommunities()[0] is [[0], [1, 2], [3, 4]]: Already disconnected: one more community than the components; the loop changes nothing")
    func girvanNewman188() {
        // U: P(0,1,2), 3-4, 2-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (2, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[0]
        let expected: [[Int]] = [[0], [1, 2], [3, 4]]
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
        #expect(abs(q - 0.28125) <= 1e-12 * max(1, abs(0.28125)))
    }

    @Test("CD-189 U(P(0,1,2), 3-4, 2-2).girvanNewmanCommunities()[1] is [[0], [1], [2], [3, 4]]: 1-2 and 3-4 tie: 1-2 has the lesser position")
    func girvanNewman189() {
        // U: P(0,1,2), 3-4, 2-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (2, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[1]
        let expected: [[Int]] = [[0], [1], [2], [3, 4]]
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
        #expect(abs(q - 0.21875) <= 1e-12 * max(1, abs(0.21875)))
    }

    @Test("CD-190 U(0-1, 1-2, 0-1).girvanNewmanCommunities()[0] is [[0, 1], [2]]: Parallel copies share their pairs' paths, so the single edge goes first")
    func girvanNewman190() {
        // U: 0-1, 1-2, 0-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[0]
        let expected: [[Int]] = [[0, 1], [2]]
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
        #expect(abs(q - -0.055555555555555566) <= 1e-12 * max(1, abs(-0.055555555555555566)))
    }

    @Test("CD-191 U(0-1, 1-2, 0-1).girvanNewmanCommunities()[1] is [[0], [1], [2]]: Then both copies, one at a time")
    func girvanNewman191() {
        // U: 0-1, 1-2, 0-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.girvanNewmanCommunities())[1]
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
        #expect(abs(q - -0.3888888888888889) <= 1e-12 * max(1, abs(-0.3888888888888889)))
    }
}
