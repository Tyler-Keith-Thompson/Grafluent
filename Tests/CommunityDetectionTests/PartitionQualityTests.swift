// §C: coverage (edges inside communities over edges, parallel copies each counted, a loop inside) and
// performance (vertex pairs classified correctly over pairs: adjacency is "at least one edge", loops
// are not pairs, ordered pairs on `DirectedGraph`). Each test checks both members of the result.
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

@Suite("Partition quality")
struct PartitionQualityTests {
    @Test("CD-069 U(K(0..2), K(3..5), 2-3).partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).coverage is 0.857142857143: 6 of 7 edges inside")
    func quality069() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
        #expect(abs(quality.performance - 0.9333333333333333) <= 1e-12 * max(1, abs(0.9333333333333333)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)), "graph.directed")
        #expect(abs(arcs.performance - 0.9333333333333333) <= 1e-12 * max(1, abs(0.9333333333333333)), "graph.directed")
    }

    @Test("CD-070 U(K(0..2), K(3..5), 2-3).partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).performance is 0.933333333333: (6 + 8)/15")
    func quality070() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
        #expect(abs(quality.performance - 0.9333333333333333) <= 1e-12 * max(1, abs(0.9333333333333333)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)), "graph.directed")
        #expect(abs(arcs.performance - 0.9333333333333333) <= 1e-12 * max(1, abs(0.9333333333333333)), "graph.directed")
    }

    @Test("CD-071 U(K(0..2), K(3..5), 2-3).partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).coverage is 0")
    func quality071() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0], [1], [2], [3], [4], [5]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage) <= 1e-12)
        #expect(abs(quality.performance - 0.5333333333333333) <= 1e-12 * max(1, abs(0.5333333333333333)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage) <= 1e-12, "graph.directed")
        #expect(abs(arcs.performance - 0.5333333333333333) <= 1e-12 * max(1, abs(0.5333333333333333)), "graph.directed")
    }

    @Test("CD-072 U(K(0..2), K(3..5), 2-3).partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).performance is 0.533333333333: Every non-edge pair is correct: 8/15")
    func quality072() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0], [1], [2], [3], [4], [5]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage) <= 1e-12)
        #expect(abs(quality.performance - 0.5333333333333333) <= 1e-12 * max(1, abs(0.5333333333333333)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage) <= 1e-12, "graph.directed")
        #expect(abs(arcs.performance - 0.5333333333333333) <= 1e-12 * max(1, abs(0.5333333333333333)), "graph.directed")
    }

    @Test("CD-073 U(K(0..2), K(3..5), 2-3).partitionQuality(of: components).performance is 0.466666666667: One community: the density 7/15")
    func quality073() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities = graph.connectedComponents()
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 1) <= 1e-12 * max(1, abs(1)))
        #expect(abs(quality.performance - 0.4666666666666667) <= 1e-12 * max(1, abs(0.4666666666666667)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage - 1) <= 1e-12 * max(1, abs(1)), "graph.directed")
        #expect(abs(arcs.performance - 0.4666666666666667) <= 1e-12 * max(1, abs(0.4666666666666667)), "graph.directed")
    }

    @Test("CD-074 U(nx(karate_club)).partitionQuality(of: […]).coverage is 0.858974358974")
    func quality074() {
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
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.8589743589743589) <= 1e-12 * max(1, abs(0.8589743589743589)))
        #expect(abs(quality.performance - 0.6149732620320856) <= 1e-12 * max(1, abs(0.6149732620320856)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage - 0.8589743589743589) <= 1e-12 * max(1, abs(0.8589743589743589)), "graph.directed")
        #expect(abs(arcs.performance - 0.6149732620320856) <= 1e-12 * max(1, abs(0.6149732620320856)), "graph.directed")
    }

    @Test("CD-075 U(nx(karate_club)).partitionQuality(of: […]).performance is 0.614973262032")
    func quality075() {
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
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.8589743589743589) <= 1e-12 * max(1, abs(0.8589743589743589)))
        #expect(abs(quality.performance - 0.6149732620320856) <= 1e-12 * max(1, abs(0.6149732620320856)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage - 0.8589743589743589) <= 1e-12 * max(1, abs(0.8589743589743589)), "graph.directed")
        #expect(abs(arcs.performance - 0.6149732620320856) <= 1e-12 * max(1, abs(0.6149732620320856)), "graph.directed")
    }

    @Test("CD-076 U(0-1, 0-1, 1-2).partitionQuality(of: [[0, 1], [2]]).coverage is 0.666666666667: Parallel edges each count: 2/3")
    func quality076() {
        // U: 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)), "graph.directed")
        #expect(abs(arcs.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)), "graph.directed")
    }

    @Test("CD-077 U(0-1, 0-1, 1-2).partitionQuality(of: [[0, 1], [2]]).performance is 0.666666666667: Pairs by adjacency: 2/3; NetworkX returns −1 on multigraphs")
    func quality077() {
        // U: 0-1, 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)), "graph.directed")
        #expect(abs(arcs.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)), "graph.directed")
    }

    @Test("CD-078 U(0-1, 1-2, 1-1).partitionQuality(of: [[0, 1], [2]]).coverage is 0.666666666667: A loop is inside its community: 2/3")
    func quality078() {
        // U: 0-1, 1-2, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)), "graph.directed")
        #expect(abs(arcs.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)), "graph.directed")
    }

    @Test("CD-079 U(0-1, 1-2, 1-1).partitionQuality(of: [[0, 1], [2]]).performance is 0.666666666667: Loops are not pairs: 2/3 (NetworkX counts the loop: 1)")
    func quality079() {
        // U: 0-1, 1-2, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(abs(arcs.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)), "graph.directed")
        #expect(abs(arcs.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)), "graph.directed")
    }

    @Test("CD-080 D(0>1, 1>2).partitionQuality(of: [[0, 1], [2]]).coverage is 0.5")
    func quality080() {
        // D: 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.5) <= 1e-12 * max(1, abs(0.5)))
        #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
    }

    @Test("CD-081 D(0>1, 1>2).partitionQuality(of: [[0, 1], [2]]).performance is 0.666666666667: Ordered pairs: (1 + 3)/6")
    func quality081() {
        // D: 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.5) <= 1e-12 * max(1, abs(0.5)))
        #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
    }

    @Test("CD-082 D(0>1, 1>0, 1>2).partitionQuality(of: [[0, 1], [2]]).performance is 0.833333333333")
    func quality082() {
        // D: 0>1, 1>0, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let communities: [[Int]] = [[0, 1], [2]]
        let quality = graph.partitionQuality(of: communities)
        #expect(abs(quality.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        #expect(abs(quality.performance - 0.8333333333333334) <= 1e-12 * max(1, abs(0.8333333333333334)))
    }
}
