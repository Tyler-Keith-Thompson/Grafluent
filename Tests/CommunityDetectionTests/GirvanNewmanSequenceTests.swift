// Girvan–Newman beyond the catalog rows (§H, GirvanNewmanTests.swift): the length of the whole
// sequence, parallel copies against edge betweenness, graphs without vertex indices, and the
// sequence's laziness, restarts and refinement order.

import AdjacencyListModule
import Centrality
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Girvan–Newman sequence")
struct GirvanNewmanSequenceTests {
    @Test("Karate club: n − 1 levels in all, the last every vertex alone")
    func karateLength() {
        let pairs = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16),
            (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25),
            (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33),
            (31, 32), (31, 33), (32, 33),
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        // n − 1 splits in all: the last level is every vertex alone.
        let all = Array(graph.girvanNewmanCommunities())
        #expect(all.count == 33)
        #expect(all.last?.count == 34)
    }

    @Test("Parallel edges share their pairs' paths: the single edge goes first, then the copies one by one")
    func parallel() {
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1)])
        #expect(graph.edgeBetweennessCentrality(normalized: false).scores == [1, 2, 1])
        let levels = graph.girvanNewmanCommunities().map { $0.map { Array($0) } }
        #expect(levels == [[[0, 1], [2]], [[0], [1], [2]]])
    }

    @Test("Graphs without vertex indices, and vertices listed out of value order")
    func unindexed() {
        let graph = UndirectedAdjacencyList(vertices: ["e", "d", "c", "b", "a"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d"), UndirectedEdge("d", "e")])
        let levels = Array(graph.girvanNewmanCommunities())
        #expect(levels.count == 4)
        // The middle of the path has the greatest betweenness: b-c and c-d tie, b-c is first.
        #expect(levels[0].count == 2)
        #expect(levels[0].community(of: "a") == levels[0].community(of: "b"))
        #expect(levels[0].community(of: "c") == levels[0].community(of: "e"))
        #expect(levels[0].community(of: "a") != levels[0].community(of: "c"))
        #expect(levels[3].count == 5)
        for (i, v) in graph.vertices.enumerated() {
            #expect(levels[1].community(ofIndex: i) == levels[1].community(of: v))
        }
    }

    @Test("The sequence is lazy and restartable: each iterator starts over, every partition refines the one before and has one more community")
    func sequence() {
        let pairs = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 3), (5, 6), (6, 7), (7, 8), (8, 6)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let sequence = graph.girvanNewmanCommunities()
        var iterator = sequence.makeIterator()
        let first = iterator.next()
        #expect(first?.count == 2)
        let all = Array(sequence)
        #expect(all.first == first)
        #expect(all.count == 8)
        for (previous, next) in zip(all, all.dropFirst()) {
            #expect(next.count == previous.count + 1)
            for community in next {
                let owners = Set(community.map { previous.community(of: $0) })
                #expect(owners.count == 1)
            }
        }
        var finished = sequence.makeIterator()
        while finished.next() != nil {}
        #expect(finished.next() == nil)
    }
}
