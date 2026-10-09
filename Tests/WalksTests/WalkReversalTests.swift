// §10: reversal and concatenation. reversed() reverses the vertices and the edges and keeps the
// type. Over a Graph the result is a walk of the same graph; over a DirectedGraph it is a walk of
// the converse (written here by hand, with each arc flipped at its own position), and over
// `g.directed` it names the original arcs, which point backward. Concatenation is on Walk only.
// Fixtures: U3 = 0–1, 1–2, 2–3 weights 2, 3, 4 (JGraphT testReversePathUndirected); D3 = 0→1,
// 1→2, 2→3; C = 0→1, 1→2, 2→3, 3→1 (JGraphT testConcatPath1). Case IDs (WK-nnn) refer to the
// catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Walk reversal and concatenation")
struct WalkReversalTests {
    @Test("WK-1001 an undirected walk reversed is a walk of the same graph with the same weight (JGraphT testReversePathUndirected)")
    func undirectedReversal() throws {
        let u3 = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 3)].map { UndirectedEdge($0.0, $0.1) })
        let weights = [2, 3, 4]
        let walk = try #require(Walk([0, 1, 2, 3], in: u3))
        let reversed = walk.reversed()
        #expect(reversed.vertices == [3, 2, 1, 0])
        #expect(reversed.edges == [2, 1, 0])
        #expect(Walk(vertices: reversed.vertices, edges: reversed.edges, in: u3) == reversed)
        #expect(reversed.weight { weights[$0] } == 9)
        #expect(walk.weight { weights[$0] } == 9)
    }

    @Test("WK-1002 a directed walk reversed is a walk of the converse, not of the graph")
    func directedReversal() throws {
        let d3 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3)].map { DirectedEdge(from: $0.0, to: $0.1) })
        // The converse, each arc flipped at its own position.
        let converse = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3)].map { DirectedEdge(from: $0.1, to: $0.0) })
        let reversed = try #require(Walk([0, 1, 2, 3], in: d3)).reversed()
        #expect(reversed.vertices == [3, 2, 1, 0])
        #expect(reversed.edges == [2, 1, 0])
        #expect(Walk(vertices: reversed.vertices, edges: reversed.edges, in: d3) == nil)
        #expect(Walk(vertices: reversed.vertices, edges: reversed.edges, in: converse) == reversed)
    }

    @Test("WK-1003 appending joins at the shared vertex (JGraphT testConcatPath1)")
    func concatenate() throws {
        let c = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 1)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let first = try #require(Walk([0, 1, 2], in: c))
        let second = try  #require(Walk(vertices: [2, 3, 1], edges: [2, 3], in: c))
        let joined = first.appending(second)
        #expect(joined.vertices == [0, 1, 2, 3, 1])
        #expect(joined.edges == [0, 1, 2, 3])
        #expect(Walk(vertices: joined.vertices, edges: joined.edges, in: c) == joined)
        #expect(joined.length == first.length + second.length)
        // The operands are unchanged.
        #expect(first.vertices == [0, 1, 2])
        #expect(second.vertices == [2, 3, 1])
    }

    @Test("WK-1004 appending a trivial walk at either end changes nothing (JGraphT testConcatPathWithSingleton)")
    func appendTrivial() throws {
        let w = Walk(vertices: [0, 1, 2], edges: [5, 6])
        #expect(w.appending(Walk(vertex: w.target)) == w)
        #expect(Walk(vertex: w.source).appending(w) == w)
        #expect(Walk<Int, Int>(vertex: 4).appending(Walk(vertex: 4)) == Walk(vertex: 4))
    }

    @Test("WK-1005 the trivial walk reversed is itself")
    func trivialReversed() {
        #expect(Walk<Int, Int>(vertex: 7).reversed() == Walk<Int, Int>(vertex: 7))
        #expect(Path<Int, Int>(vertex: 7).reversed() == Path<Int, Int>(vertex: 7))
    }

    @Test("WK-1006 a digon reversed is a different cycle")
    func digonReversed() throws {
        let c = try #require(Cycle(vertices: [0, 1], edges: [0, 1]))
        let r = c.reversed()
        // Reversed, 1 reaches 0 through edge 0, and 0 closes back to 1 through edge 1.
        #expect(r.vertices == [1, 0])
        #expect(r.edges == [0, 1])
        #expect(r != c)
    }

    @Test("WK-1007 a walk of g.directed reversed names the original arcs, so it is not a walk of g.directed")
    func directedViewReversal() throws {
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        typealias Arc = DirectedView<ReferencePseudograph<Int>>.Edges.Index
        let arcs = [Arc(position: 0, reversed: false), Arc(position: 1, reversed: false)]
        let walk = try  #require(Walk(vertices: [0, 1, 2], edges: arcs, in: u.directed))
        let reversed = walk.reversed()
        #expect(reversed.vertices == [2, 1, 0])
        #expect(reversed.edges == [Arc(position: 1, reversed: false), Arc(position: 0, reversed: false)])
        #expect(Walk(vertices: reversed.vertices, edges: reversed.edges, in: u.directed) == nil)
        // Flipping each arc gives the walk back in g.directed.
        let flipped = reversed.edges.map { Arc(position: $0.position, reversed: !$0.reversed) }
        #expect(Walk(vertices: reversed.vertices, edges: flipped, in: u.directed) != nil)
    }

    @Test("WK-1008 append(_:) gives the same walk as appending(_:) and leaves copies alone", .tags(.copyOnWrite))
    func appendInPlace() throws {
        let first = Walk(vertices: [0, 1, 2], edges: [0, 1])
        let second = Walk(vertices: [2, 3, 1], edges: [2, 3])
        var w = first
        w.append(second)
        #expect(w == first.appending(second))
        #expect(w.vertices == [0, 1, 2, 3, 1])
        #expect(first.vertices == [0, 1, 2] && first.edges == [0, 1])
        var trivial = Walk<Int, Int>(vertex: 0)
        trivial.append(first)
        #expect(trivial == first)
    }

    @Test("WK-1009 reversed() keeps the type")
    func reversedKeepsType() throws {
        let path = try #require(Path(vertices: [0, 1, 2], edges: [0, 1]))
        let trail = try #require(Trail(vertices: [0, 1, 0], edges: [0, 1]))
        let circuit = try #require(Circuit(vertices: [0, 1, 2], edges: [0, 1, 2]))
        let cycle = try #require(Cycle(vertices: [0, 1, 2], edges: [0, 1, 2]))
        let walk = Walk(vertices: [0, 1], edges: [0])
        #expect(type(of: path.reversed()) == Path<Int, Int>.self)
        #expect(type(of: trail.reversed()) == Trail<Int, Int>.self)
        #expect(type(of: circuit.reversed()) == Circuit<Int, Int>.self)
        #expect(type(of: cycle.reversed()) == Cycle<Int, Int>.self)
        #expect(type(of: walk.reversed()) == Walk<Int, Int>.self)
        #expect(path.reversed().vertices == [2, 1, 0] && path.reversed().edges == [1, 0])
        #expect(trail.reversed().vertices == [0, 1, 0] && trail.reversed().edges == [1, 0])
        #expect(circuit.reversed().vertices == [2, 1, 0] && circuit.reversed().edges == [1, 0, 2])
    }

    @Test("WK-1010 a cycle of D4 reversed lists its vertices backward over the same arcs, a cycle of the converse graph")
    func d4CycleReversed() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let r = try #require(Cycle([0, 1, 2, 3], in: d4)).reversed()
        #expect(r.vertices == [3, 2, 1, 0])
        #expect(r.edges == [2, 1, 0, 3])
        let converse = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.1, to: $0.0) })
        #expect(Cycle(vertices: r.vertices, edges: r.edges, in: converse) == r)
        #expect(Cycle(vertices: r.vertices, edges: r.edges, in: d4) == nil)
    }
}
