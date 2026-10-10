// §B: Newman–Girvan modularity with Reichardt–Bornholdt's resolution γ on `Graph` (an undirected
// self-loop is A_vv = 2w, parallel edges add), Leicht–Newman on `DirectedGraph` (a directed loop is one
// out- and one in-arc), weights by edge position, empty communities, community order, `connectedComponents()`
// as a partition, and labeled vertices.
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); scalars compare within 1e-12 relative to max(1, |value|), partitions
// exactly, in canonical order (communities by least vertex number, each in `vertices` order). Every
// partition row also checks `count`, `community(of:)` against membership, `community(ofIndex:)`
// against `community(of:)`, and the modularity of the result (at the call's weight and resolution)
// against ref.py's; undirected rows of the measures, Louvain and greedy modularity also run on
// `graph.directed` (the same values). Case IDs (CD-nnn) refer to the catalog; see README.md.

import CommunityDetection
import Connectivity
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Modularity")
struct ModularityTests {
    @Test("CD-035 U(P(0,1,2)).modularity(of: [[0, 1], [2]]) is -0.125: (1/2 − 9/16) + (0 − 1/16)")
    func modularity035() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - -0.125) <= 1e-12 * max(1, abs(-0.125)), "graph.directed")
    }

    @Test("CD-036 U(P(0,1,2)).modularity(of: [[0, 1, 2]]) is 0: One community: 1 − γ")
    func modularity036() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2]]
        let value = graph.modularity(of: communities)
        #expect(abs(value) <= 1e-12)
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs) <= 1e-12, "graph.directed")
    }

    @Test("CD-037 U(P(0,1,2)).modularity(of: [[0], [1], [2]]) is -0.375: Singletons: −Σ(d/2m)²")
    func modularity037() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0], [1], [2]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - -0.375) <= 1e-12 * max(1, abs(-0.375)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - -0.375) <= 1e-12 * max(1, abs(-0.375)), "graph.directed")
    }

    @Test("CD-038 U(P(0,1,2)).modularity(of: [[2], [0, 1]]) is -0.125: Community order does not matter")
    func modularity038() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[2], [0, 1]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - -0.125) <= 1e-12 * max(1, abs(-0.125)), "graph.directed")
    }

    @Test("CD-039 U(P(0,1,2)).modularity(of: [[0, 1], [], [2]]) is -0.125: An empty community contributes 0 (NetworkX `is_partition` accepts it)")
    func modularity039() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [], [2]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - -0.125) <= 1e-12 * max(1, abs(-0.125)), "graph.directed")
    }

    @Test("CD-040 U(K(4)).modularity(of: [[0, 1, 2, 3]]) is 0")
    func modularity040() {
        // U: K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2, 3]]
        let value = graph.modularity(of: communities)
        #expect(abs(value) <= 1e-12)
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs) <= 1e-12, "graph.directed")
    }

    @Test("CD-041 U(K(4)).modularity(of: [[0, 1], [2, 3]]) is -0.166666666667")
    func modularity041() {
        // U: K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2, 3]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - -0.16666666666666669) <= 1e-12 * max(1, abs(-0.16666666666666669)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - -0.16666666666666669) <= 1e-12 * max(1, abs(-0.16666666666666669)), "graph.directed")
    }

    @Test("CD-042 U(K(0..2), K(3..5), 2-3).modularity(of: [[0, 1, 2], [3, 4, 5]]) is 0.357142857143: Two triangles: 5/14 = 0.357…")
    func modularity042() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)), "graph.directed")
    }

    @Test("CD-043 U(K(0..2), K(3..5), 2-3).modularity(of: [[0, 1, 2, 3, 4, 5]]) is 0")
    func modularity043() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2, 3, 4, 5]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)), "graph.directed")
    }

    @Test("CD-044 U(K(0..2), K(3..5), 2-3).modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0) is 0.857142857143: γ = 0: the coverage, 6/7")
    func modularity044() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let value = graph.modularity(of: communities, resolution: 0)
        #expect(abs(value - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
        let arcs = graph.directed.modularity(of: communities, resolution: 0)
        #expect(abs(arcs - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)), "graph.directed")
    }

    @Test("CD-045 U(K(0..2), K(3..5), 2-3).modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0.5) is 0.607142857143")
    func modularity045() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let value = graph.modularity(of: communities, resolution: 0.5)
        #expect(abs(value - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        let arcs = graph.directed.modularity(of: communities, resolution: 0.5)
        #expect(abs(arcs - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)), "graph.directed")
    }

    @Test("CD-046 U(K(0..2), K(3..5), 2-3).modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2) is -0.142857142857")
    func modularity046() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let value = graph.modularity(of: communities, resolution: 2)
        #expect(abs(value - -0.1428571428571428) <= 1e-12 * max(1, abs(-0.1428571428571428)))
        let arcs = graph.directed.modularity(of: communities, resolution: 2)
        #expect(abs(arcs - -0.1428571428571428) <= 1e-12 * max(1, abs(-0.1428571428571428)), "graph.directed")
    }

    @Test("CD-047 U(K(0..2), K(3..5), 2-3).modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 5]) is 0.0454545454545: A heavy bridge lowers Q")
    func modularity047() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let w: [Double] = [1, 1, 1, 1, 1, 1, 5]
        let value = graph.modularity(of: communities, weight: { w[$0] })
        #expect(abs(value - 0.045454545454545414) <= 1e-12 * max(1, abs(0.045454545454545414)))
        let arcs = graph.directed.modularity(of: communities, weight: { w[$0.position] })
        #expect(abs(arcs - 0.045454545454545414) <= 1e-12 * max(1, abs(0.045454545454545414)), "graph.directed")
    }

    @Test("CD-048 U(K(0..2), K(3..5), 2-3).modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [0.5, 0.5, 0.5, 0.5, 0… is 0.357142857143: Scaling every weight leaves Q unchanged")
    func modularity048() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let w: [Double] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
        let value = graph.modularity(of: communities, weight: { w[$0] })
        #expect(abs(value - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        let arcs = graph.directed.modularity(of: communities, weight: { w[$0.position] })
        #expect(abs(arcs - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)), "graph.directed")
    }

    @Test("CD-049 U(K(0..2), K(3..5), 2-3).modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 0]) is 0.5: A zero-weight bridge: two disjoint triangles, ½")
    func modularity049() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let w: [Double] = [1, 1, 1, 1, 1, 1, 0]
        let value = graph.modularity(of: communities, weight: { w[$0] })
        #expect(abs(value - 0.5) <= 1e-12 * max(1, abs(0.5)))
        let arcs = graph.directed.modularity(of: communities, weight: { w[$0.position] })
        #expect(abs(arcs - 0.5) <= 1e-12 * max(1, abs(0.5)), "graph.directed")
    }

    @Test("CD-050 U(K(0..2), K(3..5), 2-3).modularity(of: components) is 0: `connectedComponents()` is a partition: one community here")
    func modularity050() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities = graph.connectedComponents()
        let value = graph.modularity(of: communities)
        #expect(abs(value - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)), "graph.directed")
    }

    @Test("CD-051 U(K(0..2), K(3..5)).modularity(of: components) is 0.5: Two components: ½")
    func modularity051() {
        // U: K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities = graph.connectedComponents()
        let value = graph.modularity(of: communities)
        #expect(abs(value - 0.5) <= 1e-12 * max(1, abs(0.5)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - 0.5) <= 1e-12 * max(1, abs(0.5)), "graph.directed")
    }

    @Test("CD-052 U(K(0..4), K(5..9), 4-5).modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]) is 0.452380952381")
    func modularity052() {
        // U: K(0..4), K(5..9), 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)), "graph.directed")
    }

    @Test("CD-053 U(nx(barbell,5,0)).modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]) is 0.452380952381: barbell(5, 0) is two K5 joined by an edge")
    func modularity053() {
        // U: nx(barbell,5,0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)), "graph.directed")
    }

    @Test("CD-054 U(nx(ring_of_cliques,4,4)).modularity(of: […]) is 0.607142857143")
    func modularity054() {
        // U: nx(ring_of_cliques,4,4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 13), (1, 2), (1, 3), (1, 4), (2, 3), (4, 5),
            (4, 6), (4, 7), (5, 6), (5, 7), (5, 8), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11),
            (9, 12), (10, 11), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
        let graph = ReferencePseudograph(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)), "graph.directed")
    }

    @Test("CD-055 U(nx(karate_club)).modularity(of: […]) is 0.358234714004: Zachary's observed split: 0.3582 (unweighted)")
    func modularity055() {
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
        let value = graph.modularity(of: communities)
        #expect(abs(value - 0.3582347140039448) <= 1e-12 * max(1, abs(0.3582347140039448)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - 0.3582347140039448) <= 1e-12 * max(1, abs(0.3582347140039448)), "graph.directed")
    }

    @Test("CD-056 U(nx(karate_club)).modularity(of: […], weight: […]) is 0.391437566762: NetworkX's karate `weight` attribute")
    func modularity056() {
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
        let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5,
            1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4,
            3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
        let value = graph.modularity(of: communities, weight: { w[$0] })
        #expect(abs(value - 0.39143756676224206) <= 1e-12 * max(1, abs(0.39143756676224206)))
        let arcs = graph.directed.modularity(of: communities, weight: { w[$0.position] })
        #expect(abs(arcs - 0.39143756676224206) <= 1e-12 * max(1, abs(0.39143756676224206)), "graph.directed")
    }

    @Test("CD-057 U(nx(karate_club)).directed.modularity(of: […]) is 0.358234714004: graph.directed (two arcs per edge) gives the same Q")
    func modularity057() {
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
        let value = graph.directed.modularity(of: communities)
        #expect(abs(value - 0.3582347140039448) <= 1e-12 * max(1, abs(0.3582347140039448)))
    }

    @Test("CD-058 U(0-1, 0-1, 1-2, 2-3).modularity(of: [[0, 1], [2, 3]]) is 0.21875: Parallel edges add: the same as weight 2")
    func modularity058() {
        // U: 0-1, 0-1, 1-2, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2, 3]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - 0.21875) <= 1e-12 * max(1, abs(0.21875)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - 0.21875) <= 1e-12 * max(1, abs(0.21875)), "graph.directed")
    }

    @Test("CD-059 U(0-1, 1-2, 2-3).modularity(of: [[0, 1], [2, 3]], weight: [2, 1, 1]) is 0.21875: Equals the previous row")
    func modularity059() {
        // U: 0-1, 1-2, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2, 3]]
        let w: [Double] = [2, 1, 1]
        let value = graph.modularity(of: communities, weight: { w[$0] })
        #expect(abs(value - 0.21875) <= 1e-12 * max(1, abs(0.21875)))
        let arcs = graph.directed.modularity(of: communities, weight: { w[$0.position] })
        #expect(abs(arcs - 0.21875) <= 1e-12 * max(1, abs(0.21875)), "graph.directed")
    }

    @Test("CD-060 U(0-1, 1-2, 1-1).modularity(of: [[0, 1], [2]]) is -0.0555555555556: A loop is A_11 = 2: d(1) = 4, L = 2 (NetworkX, igraph: −1/18)")
    func modularity060() {
        // U: 0-1, 1-2, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - -0.055555555555555566) <= 1e-12 * max(1, abs(-0.055555555555555566)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - -0.055555555555555566) <= 1e-12 * max(1, abs(-0.055555555555555566)), "graph.directed")
    }

    @Test("CD-061 U(0-1, 1-2, 1-1).modularity(of: [[0, 1], [2]], weight: [1, 1, 3]) is -0.02: A weighted loop counts its weight twice in the degree")
    func modularity061() {
        // U: 0-1, 1-2, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let w: [Double] = [1, 1, 3]
        let value = graph.modularity(of: communities, weight: { w[$0] })
        #expect(abs(value - -0.02000000000000001) <= 1e-12 * max(1, abs(-0.02000000000000001)))
        let arcs = graph.directed.modularity(of: communities, weight: { w[$0.position] })
        #expect(abs(arcs - -0.02000000000000001) <= 1e-12 * max(1, abs(-0.02000000000000001)), "graph.directed")
    }

    @Test("CD-062 U(0-1, 1-2, 1-1).directed.modularity(of: [[0, 1], [2]]) is -0.0555555555556: A loop is two loop arcs in graph.directed: the same Q")
    func modularity062() {
        // U: 0-1, 1-2, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let value = graph.directed.modularity(of: communities)
        #expect(abs(value - -0.055555555555555566) <= 1e-12 * max(1, abs(-0.055555555555555566)))
    }

    @Test("CD-063 D(0>1, 1>2).modularity(of: [[0, 1], [2]]) is 0: Leicht–Newman: (1/2 − 2·1/4) + (0 − 0·1/4) = 0; igraph with `directed=False`: −0.125")
    func modularity063() {
        // D: 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let value = graph.modularity(of: communities)
        #expect(abs(value) <= 1e-12)
    }

    @Test("CD-064 D(0>1, 1>0, 1>2).modularity(of: [[0, 1], [2]]) is 0")
    func modularity064() {
        // D: 0>1, 1>0, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let value = graph.modularity(of: communities)
        #expect(abs(value) <= 1e-12)
    }

    @Test("CD-065 D(C(0,1,2), C(3,4,5), 2>3).modularity(of: [[0, 1, 2], [3, 4, 5]]) is 0.367346938776")
    func modularity065() {
        // D: C(0,1,2), C(3,4,5), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
    }

    @Test("CD-066 D(C(0,1,2), C(3,4,5), 2>3).modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2) is -0.122448979592")
    func modularity066() {
        // D: C(0,1,2), C(3,4,5), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let value = graph.modularity(of: communities, resolution: 2)
        #expect(abs(value - -0.12244897959183676) <= 1e-12 * max(1, abs(-0.12244897959183676)))
    }

    @Test("CD-067 D(0>0, 0>1).modularity(of: [[0], [1]]) is 0: A directed loop is one out- and one in-arc")
    func modularity067() {
        // D: 0>0, 0>1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let communities: [[Int]] = [[0], [1]]
        let value = graph.modularity(of: communities)
        #expect(abs(value) <= 1e-12)
    }

    @Test("CD-068 U([a, b, c] a-b, b-c).modularity(of: [[a, b], [c]]) is -0.125: Labeled vertices")
    func modularity068() {
        // U: [a, b, c] a-b, b-c
        let pairs: [(String, String)] = [("a", "b"), ("b", "c")]
        let listed: [String] = ["a", "b", "c"]
        let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[String]] = [["a", "b"], ["c"]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - -0.125) <= 1e-12 * max(1, abs(-0.125)), "graph.directed")
    }
}
