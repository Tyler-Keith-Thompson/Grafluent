// The maximum spanning forest: computed by a reversed comparison, never by negating, so unsigned
// weights work; edges in nonincreasing weight, ties in position order. Case IDs (ST-nn) refer to
// the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import SpanningTrees
import Testing

@Suite("Maximum spanning forests")
struct MaximumSpanningTreeTests {
    @Test("ST-80 Wikipedia's graph (NetworkX test_maximum_edges): 59, unique")
    func wikipedia() {
        let edges: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.maximumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [6, 10, 3, 9, 2, 0])
        #expect(tree.weight == 59)
        // NetworkX's expected set.
        let expected: Set = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 6), UndirectedEdge(5, 6)]
        #expect(Set(tree.edges.map { graph.edges[$0] }) == expected)
        // Nonincreasing weight.
        let weights = tree.edges.map { edges[$0].2 }
        #expect(weights == weights.sorted(by: >))
    }

    @Test("ST-81 NetworkX test_multigraph_keys_max: the heavier copy")
    func heavierCopy() {
        let edges: [(Int, Int, Int)] = [(0, 1, 2), (0, 1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.maximumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0])
        #expect(tree.weight == 2)
    }

    @Test("ST-82 NetworkX test_weight_attribute, maximum: a tie goes to the earlier position")
    func tieToEarlierPosition() {
        let edges: [(Int, Int, Int)] = [(0, 1, 7), (0, 2, 1), (1, 2, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.maximumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(tree.weight == 8)
        #expect(Set(tree.edges.map { graph.edges[$0] }) == [UndirectedEdge(0, 1), UndirectedEdge(0, 2)])
    }

    @Test("ST-83 NetworkX's maximum spanning-tree iterator, first tree: 23")
    func iteratorFirstTree() {
        let edges: [(Int, Int, Int)] = [(0, 1, 5), (1, 2, 4), (1, 4, 6), (2, 3, 5), (2, 4, 7), (3, 4, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.maximumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [4, 2, 0, 3])
        #expect(tree.weight == 23)
        #expect(Set(tree.edges.map { graph.edges[$0] }) == [UndirectedEdge(0, 1), UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4)])
    }

    @Test("ST-84 LEMON's graph with costs −10…−1, maximum: −22")
    func lemonMaximum() {
        let pairs = [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (3, 2), (2, 4), (4, 3), (3, 5), (4, 5)]
        let edges = pairs.enumerated().map { ($0.element.0, $0.element.1, -10 + $0.offset) }
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.maximumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [9, 8, 6, 4, 1])
        #expect(tree.weight == -22)
    }

    @Test("ST-85 UInt8 weights: 220, where negating would trap")
    func unsignedMaximum() {
        let edges: [(Int, Int, UInt8)] = [(0, 1, 120), (1, 2, 100), (0, 2, 50)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.maximumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(tree.weight == 220)
        // Zero and UInt8.max are ordinary too.
        let extremes: [UInt8] = [0, 255, 0]
        let extreme = graph.maximumSpanningTree { extremes[$0] }
        #expect(extreme.edges == [1, 0])
        #expect(extreme.weight == 255)
    }

    @Test("ST-86 NetworkX's multigraph iterator graph, maximum: the heavy copies, 46")
    func doubledMaximum() {
        let edges: [(Int, Int, Int)] = [
            (0, 1, 5), (0, 1, 10), (1, 2, 4), (1, 2, 8), (1, 4, 6), (1, 4, 12), (2, 3, 5), (2, 3, 10), (2, 4, 7), (2, 4, 14), (3, 4, 3), (3, 4, 6),
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.maximumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [9, 5, 1, 7])
        #expect(tree.weight == 46)
    }

    @Test("ST-87 a −∞ edge on a cycle is left out of the maximum")
    func negativeInfinityChord() {
        let edges: [(Int, Int, Double)] = [(0, 1, 1), (1, 2, 2), (0, 2, -.infinity)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.maximumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [1, 0])
        #expect(tree.weight == 3)
    }

    @Test("ST-88 a −∞ bridge is in the maximum (NetworkX's maximum Borůvka drops it)")
    func negativeInfinityBridge() {
        let edges: [(Int, Int, Double)] = [(0, 1, 1), (1, 2, -.infinity)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.maximumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(tree.weight == -.infinity)
    }

    @Test("ST-89 the maximum of w equals the minimum of −w, edge for edge and in order", .tags(.randomized), arguments: [0, 1, 2, 3, 10, 1000])
    func maximumIsNegatedMinimum(k: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(89_000 + k))
        for _ in 0 ..< 70 {
            let n = Int.random(in: 0 ... 12, using: &rng)
            let m = n == 0 ? 0 : Int.random(in: 0 ... 3 * n, using: &rng)
            let raw = (0 ..< m).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng), Int.random(in: -k ... k, using: &rng)) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let maximum = graph.maximumSpanningTree { raw[$0].2 }
            let negated = graph.minimumSpanningTree { -raw[$0].2 }
            #expect(maximum.edges == negated.edges, "\(raw)")
            #expect(maximum.weight == -negated.weight, "\(raw)")
            // Nonincreasing weight, ties in position order.
            for (a, b) in zip(maximum.edges, maximum.edges.dropFirst()) {
                #expect(raw[a].2 > raw[b].2 || (raw[a].2 == raw[b].2 && a < b), "\(raw)")
            }
        }
    }
}
