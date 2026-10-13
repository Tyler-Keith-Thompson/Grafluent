// §6: walks of undirected graphs. The stored vertex sequence orients each edge, so one triangle
// gives two stored orders (one per direction); as cycles they are equal, because cycle equality
// includes reversal, and as circuits they are not. There and back over one edge is a
// closed walk of g but a genuine 2-cycle of `g.directedView`. Fixtures: U = triangle 0–1, 1–2, 2–0;
// UP = parallel pair 0–1, 0–1; UL = two loops at 0. Case IDs (WK-nnn) refer to the catalog; see
// README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Walks of undirected graphs")
struct UndirectedWalkTests {
    @Test("WK-601 the triangle in each direction is a cycle")
    func bothDirections() throws {
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let a = try #require(Cycle([0, 1, 2], in: u))
        let b = try #require(Cycle([0, 2, 1], in: u))
        #expect(a.edges == [0, 1, 2])
        #expect(b.edges == [2, 1, 0])
        #expect(Cycle(vertices: a.vertices, edges: a.edges, in: u) != nil)
        #expect(Cycle(vertices: b.vertices, edges: b.edges, in: u) != nil)
    }

    @Test("WK-602 the two directions are one cycle, with one hash, and two circuits")
    func reflectionEqual() throws {
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let a = try #require(Cycle([0, 1, 2], in: u))
        let b = try #require(Cycle([0, 2, 1], in: u))
        #expect(a.vertices != b.vertices)
        #expect(a == b)
        #expect(b == a)
        #expect(a.hashValue == b.hashValue)
        #expect(a == b.reversed())
        #expect(b == a.reversed())
        #expect(Circuit(a) != Circuit(b))
        #expect(Circuit(a) == Circuit(b.reversed()))
    }

    @Test("WK-603 there and back on one edge is a closed walk but not a trail, circuit or cycle")
    func thereAndBack() throws {
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let walk = try  #require(Walk(vertices: [0, 1, 0], edges: [0, 0], in: u))
        #expect(walk.isClosed)
        #expect(Trail(walk) == nil)
        #expect(Circuit(walk) == nil)
        #expect(Cycle(walk) == nil)
        #expect(Trail(vertices: [0, 1, 0], edges: [0, 0], in: u) == nil)
        #expect(Cycle(vertices: [0, 1], edges: [0, 0], in: u) == nil)
    }

    @Test("WK-604 there and back over one edge of g.directedView is a 2-cycle of distinct arcs")
    func directedViewDigon() throws {
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        typealias Arc = DirectedView<ReferencePseudograph<Int>>.Edges.Index
        let arcs = [Arc(position: 0, reversed: false), Arc(position: 0, reversed: true)]
        let c = try #require(Cycle(vertices: [0, 1], edges: arcs, in: u.directedView))
        #expect(c.length == 2)
        #expect(Cycle([0, 1], in: u.directedView)?.edges == arcs)
        #expect(Cycle(vertices: [0, 1], edges: [arcs[1], arcs[0]], in: u.directedView) == nil)
    }

    @Test("WK-605 a parallel pair is a 2-cycle (NetworkX lists [0, 1])")
    func parallelPairDigon() {
        let up = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(Cycle([0, 1], in: up)?.edges == [0, 1])
        #expect(Cycle([1, 0], in: up)?.edges == [0, 1])
    }

    @Test("WK-606 an undirected loop is a 1-cycle; two loops are a circuit", .tags(.selfLoops))
    func undirectedLoops() {
        let ul = ReferencePseudograph(edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        #expect(Cycle([0], in: ul)?.edges == [0])
        #expect(Circuit([0, 0], in: ul)?.edges == [0, 1])
        #expect(Cycle([0, 0], in: ul) == nil)
    }

    @Test("WK-607 one undirected triangle is one cycle value and two circuit values; the bidirected triangle has 5 directed cycles (NetworkX)")
    func reflectionCounts() {
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let orders = [[0, 1, 2], [1, 2, 0], [2, 0, 1], [0, 2, 1], [2, 1, 0], [1, 0, 2]]
        let cycles = orders.compactMap { Cycle($0, in: u) }
        #expect(cycles.count == 6)
        #expect(Set(cycles).count == 1)
        #expect(Set(cycles.map { Circuit($0) }).count == 2)
        // The bidirected triangle as a digraph: 2 triangles and 3 digons.
        let d = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        var sequences: [[Int]] = []
        for a in 0 ..< 3 {
            for b in 0 ..< 3 where b != a {
                sequences.append([a, b])
                for c in 0 ..< 3 where c != a && c != b { sequences.append([a, b, c]) }
            }
        }
        #expect(Set(sequences.compactMap { Cycle($0, in: d) }).count == 5)
    }
}
