// §9: weight(_:) adds the closure's value for each edge actually taken, from .zero, in stored
// order. Unlike NetworkX's path_weight there is no guess between parallel edges. Expected values
// come from the catalog's reference (ref.py, NetworkX 3.7 test_pathweight and JGraphT's
// testReversePathDirected). Case IDs (WK-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

/// The error a weight closure throws in WK-906.
private struct NegativeWeight: Error, Equatable {
    let position: Int
}

@Suite("Walk weight")
struct WalkWeightTests {
    @Test("WK-901 the weight uses the parallel edge taken, where NetworkX's path_weight takes the lightest")
    func parallelEdgeTaken() throws {
        // NetworkX test_pathweight: (1, 2) cost 5, (2, 3) cost 3, (1, 2) cost 1.
        let pairs = [(1, 2), (2, 3), (1, 2)]
        let cost = [5, 3, 1]
        let light = Walk(vertices: [1, 2, 3], edges: [2, 1])
        let heavy = Walk(vertices: [1, 2, 3], edges: [0, 1])
        #expect(light.weight { cost[$0] } == 4)
        #expect(heavy.weight { cost[$0] } == 8)
        let d = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let u = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Walk(vertices: [1, 2, 3], edges: [2, 1], in: d)?.weight { cost[$0] } == 4)
        #expect(Walk(vertices: [1, 2, 3], edges: [0, 1], in: d)?.weight { cost[$0] } == 8)
        #expect(Walk(vertices: [1, 2, 3], edges: [2, 1], in: u)?.weight { cost[$0] } == 4)
        #expect(Walk(vertices: [1, 2, 3], edges: [0, 1], in: u)?.weight { cost[$0] } == 8)
        // The vertices-only initializer takes the first copy, so the heavier one.
        #expect(Walk([1, 2, 3], in: d)?.weight { cost[$0] } == 8)
    }

    @Test("WK-902 on a simple graph holding the later edge's data, cost 4 and dist 6 (NetworkX Graph and DiGraph)")
    func simpleGraphWeights() throws {
        // NetworkX's simple graphs keep the third edge's data for (1, 2): cost 1, dist 2.
        let pairs = [(1, 2), (2, 3)]
        let cost = [1, 3]
        let dist = [2, 4]
        let d = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let u = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let dw = try #require(Walk([1, 2, 3], in: d))
        let uw = try #require(Walk([1, 2, 3], in: u))
        #expect(dw.weight { cost[$0] } == 4)
        #expect(dw.weight { dist[$0] } == 6)
        #expect(uw.weight { cost[$0] } == 4)
        #expect(uw.weight { dist[$0] } == 6)
    }

    @Test("WK-903 the trivial walk weighs zero")
    func trivialZero() {
        #expect(Walk<Int, Int>(vertex: 1).weight { _ in 1 } == 0)
        #expect(Path<Int, Int>(vertex: 1).weight { _ in 2.5 } == 0.0)
        #expect(Trail<Int, Int>(vertex: 1).weight { _ in 1 } == 0)
    }

    @Test("WK-904 equal cycles in different rotations can weigh differently in the last place")
    func floatingPointRotation() throws {
        let w = [0.1, 0.2, 0.3]
        let c0 = try #require(Cycle(vertices: [0, 1, 2], edges: [0, 1, 2]))
        let c1 = try #require(Cycle(vertices: [1, 2, 0], edges: [1, 2, 0]))
        #expect(c0 == c1)
        #expect(c0.weight { w[$0] } == 0.6000000000000001)
        #expect(c1.weight { w[$0] } == 0.6)
    }

    @Test("WK-905 exactly representable weights sum alike in every rotation")
    func exactRotation() throws {
        let w = [0.5, 0.25, 0.125]
        let vs = [0, 1, 2]
        let es = [0, 1, 2]
        for k in 0 ..< 3 {
            let c = try #require(Circuit(vertices: Array(vs[k...] + vs[..<k]), edges: Array(es[k...] + es[..<k])))
            #expect(c.weight { w[$0] } == 0.875, "k = \(k)")
            #expect(Walk(c).weight { w[$0] } == 0.875)
        }
    }

    @Test("WK-906 a throwing weight closure's typed error is rethrown")
    func typedThrows() throws {
        let walk = Walk(vertices: [0, 1, 2, 3], edges: [0, 1, 2])
        let weights = [4, -1, 7]
        func checked(_ position: Int) throws(NegativeWeight) -> Int {
            guard weights[position] >= 0 else { throw NegativeWeight(position: position) }
            return weights[position]
        }
        #expect(throws: NegativeWeight(position: 1)) { try walk.weight(checked) }
        // The error's static type is the closure's, not `any Error`.
        do throws(NegativeWeight) {
            _ = try walk.weight(checked)
            Issue.record("no error")
        } catch {
            let typed: NegativeWeight = error
            #expect(typed.position == 1)
        }
        let fine = Walk(vertices: [0, 1], edges: [0])
        #expect(throws: Never.self) { try fine.weight(checked) }
        #expect((try? fine.weight(checked)) == 4)
        let cycle = try #require(Cycle(vertices: [0, 1, 2], edges: [0, 1, 2]))
        #expect(throws: NegativeWeight(position: 1)) { try cycle.weight(checked) }
    }

    @Test("WK-907 JGraphT testReversePathDirected: the walk 3, 2, 1, 0 takes the back arcs and weighs 15")
    func jgraphtReverseDirected() throws {
        // 0→1:1, 1→2:2, 2→3:3, 3→2:4, 2→1:5, 1→0:6
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 2), (2, 1), (1, 0)]
        let w = [1, 2, 3, 4, 5, 6]
        let d = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let walk = try #require(Walk([3, 2, 1, 0], in: d))
        #expect(walk.edges == [3, 4, 5])
        #expect(walk.weight { w[$0] } == 15)
        #expect(try #require(Walk([0, 1, 2, 3], in: d)).weight { w[$0] } == 6)
    }
}
