// §D: Louvain (Blondel et al.) with NetworkX's arithmetic and stop rule: vertices in index order,
// a vertex stays when its own community ties the best gain, other ties go to the greatest community
// label; parallel edges are weight, self-loops count in degrees; the Dugué–Perez gain on
// `DirectedGraph`; `resolution`, `threshold`, weights, and `using:` on graphs where every order gives
// the same partition (CD-112 – CD-114). CD-174 (total weight 0, not a trap) is here too.
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

@Suite("Louvain")
struct LouvainTests {
    @Test("CD-083 U(K(0..2), K(3..5), 2-3).louvainCommunities() is [[0, 1, 2], [3, 4, 5]]: The two triangles")
    func louvain083() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-084 U(K(0..4), K(5..9), 4-5).louvainCommunities() is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]")
    func louvain084() {
        // U: K(0..4), K(5..9), 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-085 U(nx(barbell,5,0)).louvainCommunities() is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]")
    func louvain085() {
        // U: nx(barbell,5,0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-086 U(nx(ring_of_cliques,4,4)).louvainCommunities() is the catalog's partition (4 communities): One community per clique")
    func louvain086() {
        // U: nx(ring_of_cliques,4,4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 13), (1, 2), (1, 3), (1, 4), (2, 3), (4, 5),
            (4, 6), (4, 7), (5, 6), (5, 7), (5, 8), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11),
            (9, 12), (10, 11), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-087 U(nx(connected_caveman,4,5)).louvainCommunities() is the catalog's partition (4 communities)")
    func louvain087() {
        // U: nx(connected_caveman,4,5)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 19), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (9, 10),
            (10, 12), (10, 13), (10, 14), (11, 12), (11, 13), (11, 14), (12, 13), (12, 14), (13, 14),
            (14, 15), (15, 17), (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 18), (17, 19),
            (18, 19)]
        let graph = ReferencePseudograph(vertices: 0 ..< 20, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-088 U(nx(karate_club)).louvainCommunities() is the catalog's partition (4 communities): Q = 0.4188, igraph `community_multilevel`'s value; NetworkX's shuffled runs give 0.3854 – 0.4198 by seed (50 seeds)")
    func louvain088() {
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
        let result = graph.louvainCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
            [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
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
        #expect(abs(q - 0.41880341880341876) <= 1e-12 * max(1, abs(0.41880341880341876)))
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-089 U(nx(karate_club)).louvainCommunities().count is 4")
    func louvain089() {
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
        let result = graph.louvainCommunities()
        #expect(result.count == 4)
        #expect(result.reduce(0) { $0 + $1.count } == graph.vertexCount)
        for (c, community) in result.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
    }

    @Test("CD-090 U(nx(karate_club)).louvainCommunities().community(of: 33) is 2: Communities ordered by least vertex")
    func louvain090() {
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
        let result = graph.louvainCommunities()
        #expect(result.community(of: 33) == 2)
        #expect(result[2].contains(33))
        #expect(result.community(ofIndex: 33) == 2)
    }

    @Test("CD-091 U(nx(karate_club)).louvainCommunities(weight: […]) is the catalog's partition (4 communities)")
    func louvain091() {
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
        let result = graph.louvainCommunities(weight: { w[$0] })
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
        let q = graph.modularity(of: result, weight: { w[$0] })
        #expect(abs(q - 0.44490358126721763) <= 1e-12 * max(1, abs(0.44490358126721763)))
        let arcs = graph.directed.louvainCommunities(weight: { w[$0.position] })
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-092 U(nx(karate_club)).louvainCommunities(resolution: 0.5) is the catalog's partition (2 communities): Lower γ, larger communities")
    func louvain092() {
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
        let result = graph.louvainCommunities(resolution: 0.5)
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
        let q = graph.modularity(of: result, resolution: 0.5)
        #expect(abs(q - 0.6217948717948718) <= 1e-12 * max(1, abs(0.6217948717948718)))
        let arcs = graph.directed.louvainCommunities(resolution: 0.5)
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-093 U(nx(karate_club)).louvainCommunities(resolution: 2) is the catalog's partition (7 communities): Higher γ, smaller communities")
    func louvain093() {
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
        let result = graph.louvainCommunities(resolution: 2)
        let expected: [[Int]] = [[0, 1, 11, 12, 17, 19, 21], [2, 3, 7, 13], [4, 5, 6, 10, 16], [8, 30],
            [9, 26, 29, 33], [14, 15, 18, 20, 22, 32], [23, 24, 25, 27, 28, 31]]
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
        #expect(abs(q - 0.1561472715318869) <= 1e-12 * max(1, abs(0.1561472715318869)))
        let arcs = graph.directed.louvainCommunities(resolution: 2)
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-094 U(nx(karate_club)).louvainCommunities(resolution: 0) is the catalog's partition (1 communities): γ = 0: every connected component is one community")
    func louvain094() {
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
        let result = graph.louvainCommunities(resolution: 0)
        let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
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
        let arcs = graph.directed.louvainCommunities(resolution: 0)
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-095 U(nx(karate_club)).louvainCommunities(threshold: 1) is the catalog's partition (6 communities): Threshold ≥ any gain: stops after the first level")
    func louvain095() {
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
        let result = graph.louvainCommunities(threshold: 1)
        let expected: [[Int]] = [[0, 1, 11, 17, 19, 21], [2, 3, 7, 9, 12, 13], [4, 10], [5, 6, 16],
            [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
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
        #expect(abs(q - 0.3613576594345825) <= 1e-12 * max(1, abs(0.3613576594345825)))
        let arcs = graph.directed.louvainCommunities(threshold: 1)
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-096 U(nx(florentine_families)).louvainCommunities() is the catalog's partition (4 communities): String vertices")
    func louvain096() {
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
        let result = graph.louvainCommunities()
        let expected: [[String]] = [["Acciaiuoli", "Medici", "Barbadori", "Ridolfi", "Tornabuoni"],
            ["Castellani", "Peruzzi", "Strozzi", "Bischeri"],
            ["Albizzi", "Guadagni", "Ginori", "Lamberteschi"], ["Salviati", "Pazzi"]]
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
        #expect(abs(q - 0.3975) <= 1e-12 * max(1, abs(0.3975)))
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-097 U(K(0..2), K(3..5)).louvainCommunities() is [[0, 1, 2], [3, 4, 5]]: Components never merge (merging lowers Q)")
    func louvain097() {
        // U: K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
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
        #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-098 U(K(0..2), K(3..5), 2-3, 2-3, 2-3).louvainCommunities() is [[0, 1], [2, 3], [4, 5]]: Parallel edges are weight: the triple bridge pulls 2 and 3 together")
    func louvain098() {
        // U: K(0..2), K(3..5), 2-3, 2-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3), (2, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
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
        #expect(abs(q - 0.14814814814814814) <= 1e-12 * max(1, abs(0.14814814814814814)))
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-099 U(K(0..2), K(3..5), 2-3, 0-0, 4-4).louvainCommunities() is [[0, 1, 2], [3, 4, 5]]: Loops count in degrees")
    func louvain099() {
        // U: K(0..2), K(3..5), 2-3, 0-0, 4-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3), (0, 0), (4, 4)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
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
        #expect(abs(q - 0.38888888888888884) <= 1e-12 * max(1, abs(0.38888888888888884)))
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-100 U(K(0..2), K(3..5), 2-3).louvainCommunities(weight: [1, 1, 1, 1, 1, 1, 10]) is [[0, 1], [2, 3], [4, 5]]: A heavy bridge")
    func louvain100() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [1, 1, 1, 1, 1, 1, 10]
        let result = graph.louvainCommunities(weight: { w[$0] })
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
        let q = graph.modularity(of: result, weight: { w[$0] })
        #expect(abs(q - 0.15625) <= 1e-12 * max(1, abs(0.15625)))
        let arcs = graph.directed.louvainCommunities(weight: { w[$0.position] })
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-101 U(P(0,1,2,3,4,5,6,7)).louvainCommunities() is [[0, 1, 2, 3], [4, 5, 6, 7]]: Path: ties broken to the greatest label")
    func louvain101() {
        // U: P(0,1,2,3,4,5,6,7)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7)]
        let graph = ReferencePseudograph(vertices: 0 ..< 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-102 U(C(0,1,2,3,4,5,6,7,8,9)).louvainCommunities() is [[0, 1, 2, 9], [3, 4, 5, 6], [7, 8]]: Cycle: every first move is a tie")
    func louvain102() {
        // U: C(0,1,2,3,4,5,6,7,8,9)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9),
            (9, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
        let expected: [[Int]] = [[0, 1, 2, 9], [3, 4, 5, 6], [7, 8]]
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-103 U(S(0;1..6)).louvainCommunities() is [[0, 1, 2, 3, 4, 5, 6]]: Star")
    func louvain103() {
        // U: S(0;1..6)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6)]
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6]]
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-104 U(grid(4,4)).louvainCommunities() is the catalog's partition (4 communities)")
    func louvain104() {
        // U: grid(4,4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8),
            (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14),
            (11, 15), (12, 13), (13, 14), (14, 15)]
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
        let expected: [[Int]] = [[0, 1, 4, 5], [2, 3, 6, 7], [8, 9, 12, 13], [10, 11, 14, 15]]
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
        #expect(abs(q - 0.41666666666666663) <= 1e-12 * max(1, abs(0.41666666666666663)))
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-105 U(lcg(40,90,7)).louvainCommunities() is the catalog's partition (5 communities): Pseudo-random graph (api.md `lcg`)")
    func louvain105() {
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
        let result = graph.louvainCommunities()
        let expected: [[Int]] = [[38, 29, 2, 16, 37, 8, 10, 28, 21, 22], [31, 36, 33, 14, 18, 30, 11],
            [25, 32, 0, 5, 9, 27, 12, 15, 34, 1, 17, 23], [19, 24, 4, 6, 13, 35, 39, 7], [20, 26, 3]]
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
        #expect(abs(q - 0.34469135802469136) <= 1e-12 * max(1, abs(0.34469135802469136)))
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-106 U(lcg(60,150,11)).louvainCommunities() is the catalog's partition (7 communities)")
    func louvain106() {
        // U: lcg(60,150,11)
        let pairs: [(Int, Int)] = [(16, 31), (23, 48), (34, 43), (13, 42), (0, 23), (15, 47), (8, 31),
            (29, 47), (44, 7), (13, 17), (19, 39), (56, 38), (58, 30), (6, 19), (48, 51), (54, 29), (37, 23),
            (34, 10), (56, 18), (56, 4), (4, 9), (55, 54), (31, 10), (43, 32), (2, 30), (22, 10), (8, 10),
            (43, 30), (29, 26), (29, 37), (59, 36), (1, 35), (43, 28), (57, 17), (13, 57), (30, 9), (49, 4),
            (32, 37), (13, 48), (41, 9), (45, 3), (36, 27), (22, 36), (45, 30), (6, 2), (4, 45), (59, 3),
            (11, 26), (51, 58), (28, 17), (44, 4), (1, 20), (13, 31), (32, 48), (40, 22), (33, 21), (11, 30),
            (15, 40), (43, 5), (35, 4), (51, 6), (29, 12), (10, 38), (55, 17), (15, 30), (27, 19), (46, 19),
            (55, 31), (31, 42), (15, 47), (5, 28), (57, 49), (11, 2), (59, 1), (3, 36), (47, 50), (59, 57),
            (27, 55), (34, 22), (59, 10), (4, 13), (18, 47), (2, 16), (30, 43), (54, 8), (21, 23), (30, 36),
            (24, 7), (4, 59), (2, 26), (26, 37), (3, 19), (46, 11), (25, 46), (2, 30), (10, 1), (55, 10),
            (24, 56), (55, 26), (50, 22), (10, 36), (9, 3), (15, 27), (40, 17), (15, 39), (54, 37), (36, 55),
            (29, 30), (48, 54), (25, 44), (55, 1), (14, 20), (41, 6), (57, 44), (6, 23), (26, 52), (59, 2),
            (34, 25), (9, 43), (18, 52), (27, 17), (59, 21), (51, 26), (16, 34), (38, 10), (54, 39),
            (21, 19), (51, 5), (12, 9), (1, 22), (7, 26), (51, 44), (27, 57), (15, 33), (52, 45), (40, 53),
            (5, 58), (29, 27), (57, 27), (15, 51), (16, 35), (41, 18), (17, 34), (28, 30), (15, 43), (5, 0),
            (35, 20), (26, 23), (51, 7), (41, 18)]
        let listed: [Int] = [16, 31, 23, 48, 34, 43, 13, 42, 0, 15, 47, 8, 29, 44, 7, 17, 19, 39, 56, 38, 58,
            30, 6, 51, 54, 37, 10, 18, 4, 9, 55, 32, 2, 22, 26, 59, 36, 1, 35, 28, 57, 49, 41, 45, 3, 27, 11,
            20, 40, 33, 21, 5, 12, 46, 50, 24, 25, 14, 52, 53]
        let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.louvainCommunities()
        let expected: [[Int]] = [[16, 34, 8, 38, 10, 22, 59, 36, 1, 35, 3, 20, 50, 14],
            [31, 13, 42, 17, 55, 57, 27], [23, 48, 29, 54, 37, 32, 26, 12],
            [43, 0, 58, 30, 51, 9, 2, 28, 11, 5], [15, 47, 19, 39, 40, 33, 21, 53],
            [44, 7, 56, 4, 49, 46, 24, 25], [6, 18, 41, 45, 52]]
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
        #expect(abs(q - 0.40613333333333335) <= 1e-12 * max(1, abs(0.40613333333333335)))
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-107 U(lcg(30,60,3)).louvainCommunities(weight: e%5+1) is the catalog's partition (6 communities)")
    func louvain107() {
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
        let result = graph.louvainCommunities(weight: { Double($0 % 5 + 1) })
        let expected: [[Int]] = [[29, 23, 9, 26, 7, 14], [13, 24, 12, 6], [5, 28, 25, 16, 11, 0, 10, 27],
            [19, 18, 17, 8, 15], [21, 3, 2, 4], [1, 20]]
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
        #expect(abs(q - 0.422854938271605) <= 1e-12 * max(1, abs(0.422854938271605)))
        let arcs = graph.directed.louvainCommunities(weight: { Double($0.position % 5 + 1) })
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-108 D(C(0,1,2), C(3,4,5), 2>3).louvainCommunities() is [[0, 1, 2], [3, 4, 5]]: Directed (Dugué–Perez gain)")
    func louvain108() {
        // D: C(0,1,2), C(3,4,5), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.louvainCommunities()
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

    @Test("CD-109 D(nx(karate_club)).louvainCommunities() is the catalog's partition (4 communities): Each edge as one arc u → v, u < v; the same communities as undirected here")
    func louvain109() {
        // D: nx(karate_club)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = graph.louvainCommunities()
        let expected: [[Int]] = [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
            [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
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
        #expect(abs(q - 0.43622616699539773) <= 1e-12 * max(1, abs(0.43622616699539773)))
    }

    @Test("CD-110 D(lcg(40,100,5)).louvainCommunities() is the catalog's partition (5 communities)")
    func louvain110() {
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
        let result = graph.louvainCommunities()
        let expected: [[Int]] = [[32, 34, 5, 35, 33, 37, 21, 7, 31, 39, 27, 26], [13, 2, 20, 17, 22],
            [15, 29, 10, 24, 30, 25, 4, 16], [11, 19, 28, 23, 8, 1, 9, 12, 3, 18], [14, 38, 36, 0, 6]]
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
        #expect(abs(q - 0.34759999999999996) <= 1e-12 * max(1, abs(0.34759999999999996)))
    }

    @Test("CD-111 U(K(0..2), K(3..5), 2-3).directed.louvainCommunities() is [[0, 1, 2], [3, 4, 5]]: graph.directed: the same communities")
    func louvain111() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = graph.directed.louvainCommunities()
        let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.directed.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.directed.modularity(of: result)
        #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
    }

    @Test("CD-112 U(K(0..4), K(5..9)).louvainCommunities(using: rng(1)) is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]: Disjoint cliques: every order gives this (ref.py: 200 orders, NetworkX 25 seeds)")
    func louvain112() {
        // U: K(0..4), K(5..9)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = graph.louvainCommunities(using: &generator)
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
        #expect(graph.louvainCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-113 U(nx(ring_of_cliques,4,4)).louvainCommunities(using: rng(2)) is the catalog's partition (4 communities): Every order gives one community per clique")
    func louvain113() {
        // U: nx(ring_of_cliques,4,4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 13), (1, 2), (1, 3), (1, 4), (2, 3), (4, 5),
            (4, 6), (4, 7), (5, 6), (5, 7), (5, 8), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11),
            (9, 12), (10, 11), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 2)
        let result = graph.louvainCommunities(using: &generator)
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
        var again = SeededRandomNumberGenerator(seed: 2)
        #expect(graph.louvainCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-114 U(K(0..4), K(5..9), 4-5).louvainCommunities(using: rng(3)) is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]")
    func louvain114() {
        // U: K(0..4), K(5..9), 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 3)
        let result = graph.louvainCommunities(using: &generator)
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
        var again = SeededRandomNumberGenerator(seed: 3)
        #expect(graph.louvainCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-174 U(P(0,1,2)).louvainCommunities(weight: [0, 0]) is [[0], [1], [2]]: Not a trap: no gain is positive")
    func louvain174() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [0, 0]
        let result = graph.louvainCommunities(weight: { w[$0] })
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
        let arcs = graph.directed.louvainCommunities(weight: { w[$0.position] })
        #expect(arcs == result, "graph.directed")
    }
}
