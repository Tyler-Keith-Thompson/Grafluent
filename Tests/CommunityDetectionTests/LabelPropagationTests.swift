// §F: label propagation on `Graph`. Semi-synchronous (Cordasco–Gargano, NetworkX's deterministic
// rules: a greedy largest-degree-first coloring, classes updated in color order) and asynchronous
// (Raghavan et al.: vertices in index order, ties to the greatest label; `using:` where every order and
// tie choice gives the same partition). Votes are the row: parallel copies each vote, self-loops vote
// for nothing, weights add.
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

@Suite("Label propagation")
struct LabelPropagationTests {
    @Test("CD-133 U(K(0..2), K(3..5), 2-3).labelPropagationCommunities() is [[0, 1, 2], [3, 4, 5]]: Semi-synchronous (Cordasco–Gargano), NetworkX's deterministic rule")
    func labelPropagation133() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.labelPropagationCommunities()
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

    @Test("CD-134 U(K(0..4), K(5..9), 4-5).labelPropagationCommunities() is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]")
    func labelPropagation134() {
        // U: K(0..4), K(5..9), 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.labelPropagationCommunities()
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

    @Test("CD-135 U(nx(ring_of_cliques,4,4)).labelPropagationCommunities() is the catalog's partition (4 communities)")
    func labelPropagation135() {
        // U: nx(ring_of_cliques,4,4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 13), (1, 2), (1, 3), (1, 4), (2, 3), (4, 5),
            (4, 6), (4, 7), (5, 6), (5, 7), (5, 8), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11),
            (9, 12), (10, 11), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.labelPropagationCommunities()
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
    }

    @Test("CD-136 U(nx(karate_club)).labelPropagationCommunities() is the catalog's partition (3 communities): NetworkX `label_propagation_communities` itself; Q = 0.3251")
    func labelPropagation136() {
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
        let result = graph.labelPropagationCommunities()
        let expected: [[Int]] = [[0, 1, 3, 4, 7, 10, 11, 12, 13, 17, 19, 21, 24, 25, 31],
            [2, 8, 9, 14, 15, 18, 20, 22, 23, 26, 27, 28, 29, 30, 32, 33], [5, 6, 16]]
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
        #expect(abs(q - 0.3251150558842867) <= 1e-12 * max(1, abs(0.3251150558842867)))
    }

    @Test("CD-137 U(nx(karate_club)).labelPropagationCommunities().count is 3")
    func labelPropagation137() {
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
        let result = graph.labelPropagationCommunities()
        #expect(result.count == 3)
        #expect(result.reduce(0) { $0 + $1.count } == graph.vertexCount)
        for (c, community) in result.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
    }

    @Test("CD-138 U(nx(karate_club)).labelPropagationCommunities(weight: […]) is the catalog's partition (4 communities): Weighted votes (NetworkX has no weight here)")
    func labelPropagation138() {
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
        let result = graph.labelPropagationCommunities(weight: { w[$0] })
        let expected: [[Int]] = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 10], [5, 6, 16],
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
        #expect(abs(q - 0.41782387886283984) <= 1e-12 * max(1, abs(0.41782387886283984)))
    }

    @Test("CD-139 U(P(0,1,2,3,4,5)).labelPropagationCommunities() is [[0, 1, 2], [3, 4, 5]]")
    func labelPropagation139() {
        // U: P(0,1,2,3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.labelPropagationCommunities()
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
        #expect(abs(q - 0.30000000000000004) <= 1e-12 * max(1, abs(0.30000000000000004)))
    }

    @Test("CD-140 U(K(0..2), 2-3, 3-3, 3-3).labelPropagationCommunities() is [[0, 1, 2, 3]]: Loops vote for nothing")
    func labelPropagation140() {
        // U: K(0..2), 2-3, 3-3, 3-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (3, 3), (3, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.labelPropagationCommunities()
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

    @Test("CD-141 U(0-1, 0-1, 1-2).labelPropagationCommunities() is [[0, 1, 2]]: Parallel edges each vote")
    func labelPropagation141() {
        // U: 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.labelPropagationCommunities()
        let expected: [[Int]] = [[0, 1, 2]]
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

    @Test("CD-142 U(lcg(40,90,7)).labelPropagationCommunities() is the catalog's partition (5 communities)")
    func labelPropagation142() {
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
        let result = graph.labelPropagationCommunities()
        let expected: [[Int]] = [[38, 31, 5, 14, 18, 30, 12, 8, 10, 20, 26, 3, 1, 23, 7],
            [25, 4, 6, 32, 0, 16, 33, 37, 9, 27, 15, 28, 34, 11], [19, 13, 39, 17], [24, 36, 35],
            [29, 2, 21, 22]]
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
        #expect(abs(q - 0.32123456790123456) <= 1e-12 * max(1, abs(0.32123456790123456)))
    }

    @Test("CD-143 U(K(0..2), K(3..5), 2-3).asynchronousLabelPropagationCommunities() is [[0, 1, 2], [3, 4, 5]]: Index order, ties to the greatest label")
    func asynchronousLabelPropagation143() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.asynchronousLabelPropagationCommunities()
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

    @Test("CD-144 U(K(0..4), K(5..9), 4-5).asynchronousLabelPropagationCommunities() is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]")
    func asynchronousLabelPropagation144() {
        // U: K(0..4), K(5..9), 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.asynchronousLabelPropagationCommunities()
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

    @Test("CD-145 U(nx(ring_of_cliques,4,4)).asynchronousLabelPropagationCommunities() is [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]]: Index order floods the ring with one label: the known weakness of asynchronous propagation; shuffled orders usually find the cliques")
    func asynchronousLabelPropagation145() {
        // U: nx(ring_of_cliques,4,4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 13), (1, 2), (1, 3), (1, 4), (2, 3), (4, 5),
            (4, 6), (4, 7), (5, 6), (5, 7), (5, 8), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11),
            (9, 12), (10, 11), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.asynchronousLabelPropagationCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]]
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
        #expect(abs(q - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)))
    }

    @Test("CD-146 U(nx(karate_club)).asynchronousLabelPropagationCommunities() is the catalog's partition (2 communities): Q = 0.2807")
    func asynchronousLabelPropagation146() {
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
        let result = graph.asynchronousLabelPropagationCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21, 24, 25, 28, 30, 31],
            [9, 14, 15, 18, 20, 22, 23, 26, 27, 29, 32, 33]]
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
        #expect(abs(q - 0.2807363576594346) <= 1e-12 * max(1, abs(0.2807363576594346)))
    }

    @Test("CD-147 U(nx(karate_club)).asynchronousLabelPropagationCommunities(weight: […]) is the catalog's partition (6 communities)")
    func asynchronousLabelPropagation147() {
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
        let result = graph.asynchronousLabelPropagationCommunities(weight: { w[$0] })
        let expected: [[Int]] = [[0, 1, 2, 3, 7, 8, 11, 12, 13, 17, 19, 21, 30], [4, 10], [5, 6, 16],
            [9, 15, 18, 22, 27, 28, 33], [14, 20, 23, 26, 29, 32], [24, 25, 31]]
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
        #expect(abs(q - 0.35829538426941027) <= 1e-12 * max(1, abs(0.35829538426941027)))
    }

    @Test("CD-148 U(P(0,1,2,3,4,5)).asynchronousLabelPropagationCommunities() is [[0, 1], [2, 3], [4, 5]]")
    func asynchronousLabelPropagation148() {
        // U: P(0,1,2,3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.asynchronousLabelPropagationCommunities()
        let expected: [[Int]] = [[0, 1], [2, 3], [4, 5]]
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
        #expect(abs(q - 0.26) <= 1e-12 * max(1, abs(0.26)))
    }

    @Test("CD-149 U(0-1, 0-1, 1-2).asynchronousLabelPropagationCommunities() is [[0, 1, 2]]: 1 sides with 0 (two votes)")
    func asynchronousLabelPropagation149() {
        // U: 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.asynchronousLabelPropagationCommunities()
        let expected: [[Int]] = [[0, 1, 2]]
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

    @Test("CD-150 U(0-1, 1-2).asynchronousLabelPropagationCommunities(weight: [1, 3]) is [[0, 1, 2]]")
    func asynchronousLabelPropagation150() {
        // U: 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1, 3]
        let result = graph.asynchronousLabelPropagationCommunities(weight: { w[$0] })
        let expected: [[Int]] = [[0, 1, 2]]
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
    }

    @Test("CD-151 U(K(0..2), 2-3, 3-3, 3-3).asynchronousLabelPropagationCommunities() is [[0, 1, 2, 3]]: Loops vote for nothing")
    func asynchronousLabelPropagation151() {
        // U: K(0..2), 2-3, 3-3, 3-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (2, 3), (3, 3), (3, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.asynchronousLabelPropagationCommunities()
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

    @Test("CD-152 U(lcg(40,90,7)).asynchronousLabelPropagationCommunities() is the catalog's partition (1 communities)")
    func asynchronousLabelPropagation152() {
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
        let result = graph.asynchronousLabelPropagationCommunities()
        let expected: [[Int]] = [[38, 31, 25, 19, 24, 4, 6, 32, 0, 29, 2, 5, 36, 16, 33, 14, 18, 13, 37, 30, 35, 9, 27, 12, 15, 8, 10, 20, 26, 28, 34, 11, 3, 39, 1, 21, 17, 23, 7, 22]]
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

    @Test("CD-153 U(K(0..4), K(5..9)).asynchronousLabelPropagationCommunities(using: rng(1)) is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]: Every order and tie choice gives this")
    func asynchronousLabelPropagation153() {
        // U: K(0..4), K(5..9)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = graph.asynchronousLabelPropagationCommunities(using: &generator)
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
        #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        var again = SeededRandomNumberGenerator(seed: 1)
        #expect(graph.asynchronousLabelPropagationCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-154 U(K(0..3), K(4..7), K(8..11)).asynchronousLabelPropagationCommunities(using: rng(9)) is [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11]]")
    func asynchronousLabelPropagation154() {
        // U: K(0..3), K(4..7), K(8..11)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7),
            (5, 6), (5, 7), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11), (10, 11)]
        let graph = ReferencePseudograph(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 9)
        let result = graph.asynchronousLabelPropagationCommunities(using: &generator)
        let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11]]
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
        #expect(abs(q - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        var again = SeededRandomNumberGenerator(seed: 9)
        #expect(graph.asynchronousLabelPropagationCommunities(using: &again) == result, "the same seed again")
    }
}
