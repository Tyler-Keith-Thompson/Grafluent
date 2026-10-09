// §3: every walk type is a RandomAccessCollection of its vertices, indexed by Int from 0. An open
// walk has length + 1 elements, a circuit or cycle length elements (no repeated start). Case IDs
// (WK-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Walk collection behaviour", .tags(.conformance))
struct WalkCollectionTests {
    @Test("WK-301 a walk's elements are its vertices, count is length + 1, indices from 0")
    func elements() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = try #require(Walk([0, 1, 2, 3, 0, 1], in: d4))
        #expect(Array(w) == [0, 1, 2, 3, 0, 1])
        #expect(w.count == 6)
        #expect(w.length == 5)
        #expect(w.startIndex == 0)
        #expect(w.endIndex == 6)
        #expect(w[4] == 0)
        #expect(w[0] == 0 && w[5] == 1)
    }

    @Test("WK-302 first and last are the source and the target")
    func firstAndLast() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = try #require(Walk([0, 1, 2, 3, 0, 1], in: d4))
        #expect(w.first == 0)
        #expect(w.last == 1)
        #expect(w.source == 0)
        #expect(w.target == 1)
    }

    @Test("WK-303 a cycle's elements are its vertices once each; count equals length")
    func cycleElements() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let c = try #require(Cycle([2, 3, 0, 1], in: d4))
        #expect(Array(c) == [2, 3, 0, 1])
        #expect(c.count == 4)
        #expect(c.length == 4)
        #expect(c.edges == [2, 3, 0, 1])
        #expect(c.startIndex == 0 && c.endIndex == 4)
        let circuit = Circuit(c)
        #expect(Array(circuit) == [2, 3, 0, 1])
        #expect(circuit.count == 4 && circuit.length == 4)
    }

    @Test("WK-304 the trivial walk has one element and is not empty")
    func trivialElements() {
        let w = Walk<Int, Int>(vertex: 5)
        #expect(Array(w) == [5])
        #expect(w.indices == 0 ..< 1)
        #expect(!w.isEmpty)
        #expect(Array(Path<Int, Int>(vertex: 5)) == [5])
        #expect(Array(Trail<Int, Int>(vertex: 5)) == [5])
    }

    @Test("WK-305 reversed() and the generic BidirectionalCollection reversal agree element for element")
    func reversedAgrees() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = try #require(Walk([0, 1, 2, 3, 0, 1], in: d4))
        func generic<C: BidirectionalCollection>(_ c: C) -> [C.Element] { Array(c.reversed()) }
        let concrete: Walk<Int, Int> = w.reversed()
        #expect(Array(concrete) == generic(w))
        #expect(generic(w) == [1, 0, 3, 2, 1, 0])
        let c = try #require(Cycle([0, 1, 2, 3], in: d4))
        let concreteCycle: Cycle<Int, Int> = c.reversed()
        // For closed walks too, the concrete reversal lists exactly what generic code sees.
        #expect(Array(concreteCycle) == generic(c))
        #expect(generic(c) == [3, 2, 1, 0])
    }

    @Test("WK-306 consecutive pairs of a walk are its steps; a cycle's leave out the closing pair")
    func adjacentPairs() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = try #require(Walk([0, 1, 2, 3, 0, 1], in: d4))
        let pairs = zip(w, w.dropFirst()).map { [$0.0, $0.1] }
        #expect(pairs == [[0, 1], [1, 2], [2, 3], [3, 0], [0, 1]])
        let c = try #require(Cycle([2, 3, 0, 1], in: d4))
        #expect(zip(c, c.dropFirst()).map { [$0.0, $0.1] } == [[2, 3], [3, 0], [0, 1]])
    }

    @Test("WK-307 vertices and edges are the stored sequences")
    func verticesAndEdges() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = try #require(Walk([0, 1, 2, 3, 0, 1], in: d4))
        #expect(w.vertices == [0, 1, 2, 3, 0, 1])
        #expect(w.edges == [0, 1, 2, 3, 0])
    }

    @Test("WK-308 the RandomAccessCollection laws hold for every type")
    func randomAccessLaws() throws {
        func laws<C: RandomAccessCollection>(_ c: C, _ expected: [C.Element]) where C.Index == Int, C.Element: Equatable {
            #expect(Array(c) == expected)
            #expect(c.count == expected.count)
            #expect(c.distance(from: c.startIndex, to: c.endIndex) == expected.count)
            #expect(c.indices.map { c[$0] } == expected)
            var i = c.startIndex
            var walked = 0
            while i != c.endIndex {
                #expect(c.index(after: i) == i + 1)
                #expect(c.index(before: c.index(after: i)) == i)
                #expect(c.index(c.startIndex, offsetBy: walked) == i)
                #expect(c.distance(from: i, to: c.endIndex) == expected.count - walked)
                i = c.index(after: i)
                walked += 1
            }
            #expect(walked == expected.count)
            #expect(Array(c[c.index(after: c.startIndex)...]) == Array(expected.dropFirst()))
        }
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = try #require(Walk([0, 1, 2, 3, 0, 1], in: d4))
        laws(w, [0, 1, 2, 3, 0, 1])
        #expect(w.index(after: 5) == 6)
        #expect(w.distance(from: 0, to: 6) == 6)
        laws(try #require(Trail([0, 1, 2, 3, 0], in: d4)), [0, 1, 2, 3, 0])
        laws(try #require(Path([1, 2, 3], in: d4)), [1, 2, 3])
        laws(try #require(Circuit([3, 0, 1, 2], in: d4)), [3, 0, 1, 2])
        laws(try #require(Cycle([3, 0, 1, 2], in: d4)), [3, 0, 1, 2])
        laws(Walk<Int, Int>(vertex: 9), [9])
    }

    @Test("WK-309 isClosed compares source and target")
    func isClosed() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let open = try #require(Walk([0, 1, 2, 3, 0, 1], in: d4))
        #expect(!open.isClosed)
        #expect(!open.isTrivial)
        let closed = try #require(Walk([0, 1, 2, 3, 0], in: d4))
        #expect(closed.isClosed)
        #expect(try #require(Trail([0, 1, 2, 3, 0], in: d4)).isClosed)
        #expect(!(try #require(Trail([0, 1, 2], in: d4))).isClosed)
    }
}
