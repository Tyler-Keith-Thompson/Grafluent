// §L: the two-level map equation's code length (Rosvall and Bergstrom) of given groupings: flow
// d_v / 2W at each vertex and w / 2W along each edge each way, a loop twice in its vertex's degree
// and never leaving a module. ref.py rechecks every value as the entropy form q H(Q) + Σ p_i H(P_i);
// the karate partition and the two triangles are igraph's `community_infomap` results, at its
// codelength. Trap rows are exit tests.
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

@Suite("The map equation")
struct MapEquationCatalogTests {
    @Test("CD-249 U(K(0..2), K(3..5), 2-3).codeLength(of: [[0, 1, 2], [3, 4, 5]]) is 2.32073035683: igraph `community_infomap` finds it, codelength 2.3207303568")
    func codeLength249() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let value = graph.codeLength(of: communities)
        #expect(abs(value - 2.3207303568337903) <= 1e-12 * max(1, abs(2.3207303568337903)))
    }

    @Test("CD-250 U(K(0..2), K(3..5), 2-3).codeLength(of: [[0, 1, 2, 3, 4, 5]]) is 2.55665670746: One module: the entropy of the vertex flows")
    func codeLength250() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2, 3, 4, 5]]
        let value = graph.codeLength(of: communities)
        #expect(abs(value - 2.556656707462823) <= 1e-12 * max(1, abs(2.556656707462823)))
    }

    @Test("CD-251 U(K(0..2), K(3..5), 2-3).codeLength(of: [[0], [1], [2], [3], [4], [5]]) is 4.55665670746: Singletons")
    func codeLength251() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0], [1], [2], [3], [4], [5]]
        let value = graph.codeLength(of: communities)
        #expect(abs(value - 4.556656707462823) <= 1e-12 * max(1, abs(4.556656707462823)))
    }

    @Test("CD-252 U(nx(karate_club)).codeLength(of: […]) is 4.3117926458: igraph `community_infomap`'s partition, codelength 4.3117926458")
    func codeLength252() {
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
        let communities: [[Int]] = [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
            [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
        let value = graph.codeLength(of: communities)
        #expect(abs(value - 4.311792645801829) <= 1e-12 * max(1, abs(4.311792645801829)))
    }

    @Test("CD-253 U(nx(karate_club)).codeLength(of: […]) is 4.46209072138: The club's split")
    func codeLength253() {
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
        let value = graph.codeLength(of: communities)
        #expect(abs(value - 4.462090721377538) <= 1e-12 * max(1, abs(4.462090721377538)))
    }

    @Test("CD-254 U(nx(karate_club)).codeLength(of: […], weight: […]) is 4.25414247029: Weighted: flows by weight")
    func codeLength254() {
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
        let value = graph.codeLength(of: communities, weight: { w[$0] })
        #expect(abs(value - 4.254142470292201) <= 1e-12 * max(1, abs(4.254142470292201)))
    }

    @Test("CD-255 U(0-0, 1-1).codeLength(of: [[0], [1]]) is 0: Loops never leave a module: 0")
    func codeLength255() {
        // U: 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0], [1]]
        let value = graph.codeLength(of: communities)
        #expect(abs(value) <= 1e-12)
    }

    @Test("CD-256 U(0-0, 1-1).codeLength(of: [[0, 1]]) is 1: One module of two equal flows: 1 bit")
    func codeLength256() {
        // U: 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1]]
        let value = graph.codeLength(of: communities)
        #expect(abs(value - 1) <= 1e-12 * max(1, abs(1)))
    }

    @Test("CD-257 U(0-1, 0-1, 1-2).codeLength(of: [[0, 1], [2]]) is 2.12581458369: Parallel edges add")
    func codeLength257() {
        // U: 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let value = graph.codeLength(of: communities)
        #expect(abs(value - 2.1258145836939115) <= 1e-12 * max(1, abs(2.1258145836939115)))
    }

    @Test("CD-258 U([0..2]).codeLength(of: [[0, 1, 2]]) is 0: No edges: 0")
    func codeLength258() {
        // U: [0..2]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2]]
        let value = graph.codeLength(of: communities)
        #expect(abs(value) <= 1e-12)
    }

    @Test("CD-259 U([]).codeLength(of: []) is 0")
    func codeLength259() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let communities: [[Int]] = []
        let value = graph.codeLength(of: communities)
        #expect(abs(value) <= 1e-12)
    }

    @Test("CD-260 U(P(0,1,2)).codeLength(of: [[0, 1, 2]], weight: [0, 0]) is 0: Total weight 0: 0")
    func codeLength260() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2]]
        let w: [Double] = [0, 0]
        let value = graph.codeLength(of: communities, weight: { w[$0] })
        #expect(abs(value) <= 1e-12)
    }

    @Test("CD-261 U(P(0,1,2)).codeLength(of: [[0, 1], [1, 2]]) traps: A vertex listed twice")
    func codeLength261() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1], [1, 2]]
            _ = graph.codeLength(of: communities)
        }
    }

    @Test("CD-262 U(P(0,1,2)).codeLength(of: [[0, 1, 2]], weight: [1, -1]) traps: A negative weight")
    func codeLength262() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let communities: [[Int]] = [[0, 1, 2]]
            let w: [Double] = [1, -1]
            _ = graph.codeLength(of: communities, weight: { w[$0] })
        }
    }
}
