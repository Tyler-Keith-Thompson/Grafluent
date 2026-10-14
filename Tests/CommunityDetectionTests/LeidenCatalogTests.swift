// §I: the constant Potts model (Σ_c [e_c − γ n_c²/2], directed Σ_c [e_c − γ n_c²]); Leiden with
// modularity and the constant Potts model on graphs where every order and every refinement draw gives
// the same partition (ref.py: 200 seeded runs of its model, and NetworkX's leiden_communities with 25
// seeds), so `using:` rows pin a partition; Louvain's levels (`louvainPartitions()[k]`, NetworkX's
// louvain_partitions with the identity shuffle). Trap rows are exit tests.
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

@Suite("Leiden, the constant Potts model and Louvain's levels")
struct LeidenCatalogTests {
    @Test("CD-192 U(K(0..2), K(3..5), 2-3).constantPottsModel(of: [[0, 1, 2], [3, 4, 5]]) is -3: 2 (3 − 9/2)")
    func constantPottsModel192() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let value = graph.constantPottsModel(of: communities)
        #expect(abs(value - -3) <= 1e-12 * max(1, abs(-3)))
    }

    @Test("CD-193 U(K(0..2), K(3..5), 2-3).constantPottsModel(of: [[0, 1, 2], [3, 4, 5]], resolution: 0.5) is 1.5: 2 (3 − 9/4)")
    func constantPottsModel193() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let value = graph.constantPottsModel(of: communities, resolution: 0.5)
        #expect(abs(value - 1.5) <= 1e-12 * max(1, abs(1.5)))
    }

    @Test("CD-194 U(K(0..2), K(3..5), 2-3).constantPottsModel(of: [[0, 1, 2, 3, 4, 5]], weight: [1, 2, 3, 4, 5, … is 26.2: 28 − 0.05 · 36")
    func constantPottsModel194() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2, 3, 4, 5]]
        let w: [Double] = [1, 2, 3, 4, 5, 6, 7]
        let value = graph.constantPottsModel(of: communities, weight: { w[$0] }, resolution: 0.1)
        #expect(abs(value - 26.2) <= 1e-12 * max(1, abs(26.2)))
    }

    @Test("CD-195 U(0-0, 0-1, 1-0).constantPottsModel(of: [[0, 1]]) is 1: A loop and both copies are inside: 3 − 2")
    func constantPottsModel195() {
        // U: 0-0, 0-1, 1-0
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1]]
        let value = graph.constantPottsModel(of: communities)
        #expect(abs(value - 1) <= 1e-12 * max(1, abs(1)))
    }

    @Test("CD-196 D(C(0,1,2), C(3,4,5), 2>3).constantPottsModel(of: [[0, 1, 2], [3, 4, 5]]) is -12: Directed: Σ [e_c − γ n_c²]")
    func constantPottsModel196() {
        // D: C(0,1,2), C(3,4,5), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let value = graph.constantPottsModel(of: communities)
        #expect(abs(value - -12) <= 1e-12 * max(1, abs(-12)))
    }

    @Test("CD-197 U(nx(karate_club)).constantPottsModel(of: […], resolution: 0.05) is 52.55: NetworkX `constant_potts_model`")
    func constantPottsModel197() {
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
        let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
            [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
        let value = graph.constantPottsModel(of: communities, resolution: 0.05)
        #expect(abs(value - 52.55) <= 1e-12 * max(1, abs(52.55)))
    }

    @Test("CD-198 U([]).constantPottsModel(of: []) is 0")
    func constantPottsModel198() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let communities: [[Int]] = []
        let value = graph.constantPottsModel(of: communities)
        #expect(abs(value) <= 1e-12)
    }

    @Test("CD-199 U(P(0,1,2)).constantPottsModel(of: [[0, 1, 2]], resolution: -1) traps")
    func constantPottsModel199() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1, 2]]
            _ = graph.constantPottsModel(of: communities, resolution: -1)
        }
    }

    @Test("CD-200 U(K(0..2), K(3..5), 2-3).leidenCommunities(using: rng(1)) is [[0, 1, 2], [3, 4, 5]]: Every order gives the triangles")
    func leiden200() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = graph.leidenCommunities(using: &generator)
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
        var again = SeededRandomNumberGenerator(seed: 1)
        #expect(graph.leidenCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-201 U(K(0..4), K(5..9), 4-5).leidenCommunities(using: rng(2)) is [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]")
    func leiden201() {
        // U: K(0..4), K(5..9), 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 2)
        let result = graph.leidenCommunities(using: &generator)
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
        var again = SeededRandomNumberGenerator(seed: 2)
        #expect(graph.leidenCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-202 U(nx(ring_of_cliques,4,4)).leidenCommunities(using: rng(3)) is the catalog's partition (4 communities): One community per clique")
    func leiden202() {
        // U: nx(ring_of_cliques,4,4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 13), (1, 2), (1, 3), (1, 4), (2, 3), (4, 5),
            (4, 6), (4, 7), (5, 6), (5, 7), (5, 8), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11),
            (9, 12), (10, 11), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 3)
        let result = graph.leidenCommunities(using: &generator)
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
        var again = SeededRandomNumberGenerator(seed: 3)
        #expect(graph.leidenCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-203 U(nx(connected_caveman,4,5)).leidenCommunities(using: rng(4)) is the catalog's partition (4 communities)")
    func leiden203() {
        // U: nx(connected_caveman,4,5)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 19), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (9, 10),
            (10, 12), (10, 13), (10, 14), (11, 12), (11, 13), (11, 14), (12, 13), (12, 14), (13, 14),
            (14, 15), (15, 17), (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 18), (17, 19),
            (18, 19)]
        let graph = ReferencePseudograph(vertices: 0 ..< 20, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 4)
        let result = graph.leidenCommunities(using: &generator)
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
        var again = SeededRandomNumberGenerator(seed: 4)
        #expect(graph.leidenCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-204 U(K(0..2), K(3..5), 2-3).leidenCommunities(quality: constantPottsModel, resolution: 0.5, using… is [[0, 1, 2], [3, 4, 5]]: Each triangle 3 − 9/4 > 0")
    func leiden204() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 5)
        let result = graph.leidenCommunities(quality: .constantPottsModel, resolution: 0.5, using: &generator)
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
        let q = graph.modularity(of: result, resolution: 0.5)
        #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        var again = SeededRandomNumberGenerator(seed: 5)
        #expect(graph.leidenCommunities(quality: .constantPottsModel, resolution: 0.5, using: &again) == result, "the same seed again")
    }

    @Test("CD-205 U(K(0..2), K(3..5), 2-3).leidenCommunities(quality: constantPottsModel, resolution: 0.1, using… is [[0, 1, 2, 3, 4, 5]]: 7 − 1.8 beats 2 (3 − 0.45)")
    func leiden205() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 6)
        let result = graph.leidenCommunities(quality: .constantPottsModel, resolution: 0.1, using: &generator)
        let expected: [[Int]] = [[0, 1, 2, 3, 4, 5]]
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
        let q = graph.modularity(of: result, resolution: 0.1)
        #expect(abs(q - 0.9) <= 1e-12 * max(1, abs(0.9)))
        var again = SeededRandomNumberGenerator(seed: 6)
        #expect(graph.leidenCommunities(quality: .constantPottsModel, resolution: 0.1, using: &again) == result, "the same seed again")
    }

    @Test("CD-206 U(K(0..2), K(3..5), 2-3).leidenCommunities(quality: constantPottsModel, resolution: 2, using: … is [[0], [1], [2], [3], [4], [5]]: Every community of two or more is below 0: singletons")
    func leiden206() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 7)
        let result = graph.leidenCommunities(quality: .constantPottsModel, resolution: 2, using: &generator)
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
        let q = graph.modularity(of: result, resolution: 2)
        #expect(abs(q - -0.346938775510204) <= 1e-12 * max(1, abs(-0.346938775510204)))
        var again = SeededRandomNumberGenerator(seed: 7)
        #expect(graph.leidenCommunities(quality: .constantPottsModel, resolution: 2, using: &again) == result, "the same seed again")
    }

    @Test("CD-207 U([0..3]).leidenCommunities(using: rng(8)) is [[0], [1], [2], [3]]: No edges: singletons")
    func leiden207() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 8)
        let result = graph.leidenCommunities(using: &generator)
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
        var again = SeededRandomNumberGenerator(seed: 8)
        #expect(graph.leidenCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-208 U(0-0, 1-1).leidenCommunities(using: rng(9)) is [[0], [1]]: Loops never join vertices")
    func leiden208() {
        // U: 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 9)
        let result = graph.leidenCommunities(using: &generator)
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
        var again = SeededRandomNumberGenerator(seed: 9)
        #expect(graph.leidenCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-209 U(K(0..2), K(3..5), 2-3, 2-3, 2-3).leidenCommunities(using: rng(10)) is [[0, 1], [2, 3], [4, 5]]: Parallel edges are weight")
    func leiden209() {
        // U: K(0..2), K(3..5), 2-3, 2-3, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3), (2, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 10)
        let result = graph.leidenCommunities(using: &generator)
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
        var again = SeededRandomNumberGenerator(seed: 10)
        #expect(graph.leidenCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-210 D(C(0,1,2), C(3,4,5), 2>3).leidenCommunities(using: rng(11)) is [[0, 1, 2], [3, 4, 5]]: Directed modularity")
    func leiden210() {
        // D: C(0,1,2), C(3,4,5), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 11)
        let result = graph.leidenCommunities(using: &generator)
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
        var again = SeededRandomNumberGenerator(seed: 11)
        #expect(graph.leidenCommunities(using: &again) == result, "the same seed again")
    }

    @Test("CD-211 U(P(0,1,2)).leidenCommunities(randomness: 0, using: rng(1)) traps")
    func leiden211() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.leidenCommunities(randomness: 0, using: &generator)
        }
    }

    @Test("CD-212 U(P(0,1,2)).leidenCommunities(iterations: 0, using: rng(1)) traps")
    func leiden212() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = graph.leidenCommunities(iterations: 0, using: &generator)
        }
    }

    @Test("CD-213 U(K(0..2), K(3..5), 2-3).louvainPartitions()[0] is [[0, 1, 2], [3, 4, 5]]: The first level")
    func louvainLevels213() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.louvainPartitions())[0]
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

    @Test("CD-214 U(nx(karate_club)).louvainPartitions()[0] is the catalog's partition (6 communities)")
    func louvainLevels214() {
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
        let result = Array(graph.louvainPartitions())[0]
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
    }

    @Test("CD-215 U(nx(karate_club)).louvainPartitions()[1] is the catalog's partition (4 communities): The last level is louvainCommunities() (CD-088)")
    func louvainLevels215() {
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
        let result = Array(graph.louvainPartitions())[1]
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
    }

    @Test("CD-216 D(C(0,1,2), C(3,4,5), 2>3).louvainPartitions()[0] is [[0, 1, 2], [3, 4, 5]]")
    func louvainLevels216() {
        // D: C(0,1,2), C(3,4,5), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let result = Array(graph.louvainPartitions())[0]
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

    @Test("CD-217 U([0..2]).louvainPartitions()[0] is [[0], [1], [2]]: No edges: one level of singletons")
    func louvainLevels217() {
        // U: [0..2]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let result = Array(graph.louvainPartitions())[0]
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
}
