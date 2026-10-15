// The triadic census on the simple digraph underneath (self-loops ignored, parallel arcs once):
// each of the 16 triad types realized on three vertices, the six-arc digraph as NetworkX 3.7
// counts it, and the invariants (the counts add up to C(n, 3); relabeling changes nothing).

import AdjacencyListModule
import Assortativity
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

@Suite("Triadic census")
struct TriadicCensusTests {
    @Test("Each of the 16 triad types, realized on vertices 0, 1, 2")
    func everyType() {
        let realizations: [(String, [(Int, Int)])] = [
            ("003", []),
            ("012", [(0, 1)]),
            ("102", [(0, 1), (1, 0)]),
            ("021D", [(0, 1), (0, 2)]),
            ("021U", [(1, 0), (2, 0)]),
            ("021C", [(0, 1), (1, 2)]),
            ("111D", [(0, 1), (1, 0), (2, 1)]),
            ("111U", [(0, 1), (1, 0), (1, 2)]),
            ("030T", [(0, 1), (1, 2), (0, 2)]),
            ("030C", [(0, 1), (1, 2), (2, 0)]),
            ("201", [(0, 1), (1, 0), (0, 2), (2, 0)]),
            ("120D", [(0, 1), (0, 2), (1, 2), (2, 1)]),
            ("120U", [(1, 0), (2, 0), (1, 2), (2, 1)]),
            ("120C", [(0, 1), (1, 2), (0, 2), (2, 0)]),
            ("210", [(0, 1), (1, 0), (0, 2), (2, 0), (1, 2)]),
            ("300", [(0, 1), (1, 0), (0, 2), (2, 0), (1, 2), (2, 1)]),
        ]
        #expect(realizations.map(\.0) == TriadicCensus.types)
        for (type, arcs) in realizations {
            let graph = AdjacencyList(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let census = graph.triadicCensus()
            #expect(census[type] == 1, "\(type)")
            #expect(census.counts.reduce(0, +) == 1, "\(type)")
            // Every relabeling of the three vertices gives the same type.
            for permutation in [[0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]] {
                let relabeled = AdjacencyList(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: permutation[$0.0], to: permutation[$0.1]) })
                #expect(relabeled.triadicCensus() == census, "\(type) under \(permutation)")
            }
        }
    }

    @Test("The six-arc digraph, as NetworkX counts it")
    func sixArcs() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let census = graph.triadicCensus()
        var expected = [Int64](repeating: 0, count: 16)
        for (type, count) in [("012", 1), ("111D", 1), ("201", 1), ("120C", 1)] as [(String, Int64)] { expected[TriadicCensus.types.firstIndex(of: type)!] = count }
        #expect(census.counts == expected)
        #expect(census["003"] == 0)
    }

    @Test("Fewer than three vertices: every count 0; isolated vertices make 003 and dyadic triads")
    func small() {
        #expect(AdjacencyList<Int>().triadicCensus().counts == [Int64](repeating: 0, count: 16))
        #expect(AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)]).triadicCensus().counts == [Int64](repeating: 0, count: 16))
        // Five vertices, one arc: 012 with each of the other three, 003 for the rest of C(5, 3) = 10.
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: [DirectedEdge(from: 3, to: 1)])
        let census = graph.triadicCensus()
        #expect(census["012"] == 3 && census["003"] == 7)
        let mutual = AdjacencyList(vertices: 0 ..< 5, edges: [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 1, to: 3)])
        #expect(mutual.triadicCensus()["102"] == 3 && mutual.triadicCensus()["003"] == 7)
    }

    @Test("Self-loops are ignored and parallel arcs count once")
    func multigraph() {
        let simple = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 3, to: 0)])
        let multi = DirectedPseudograph(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 3, to: 3), DirectedEdge(from: 3, to: 0)])
        #expect(multi.triadicCensus() == simple.triadicCensus())
        // 030C on 0, 1, 2; 3→0 makes 021C with (3, 0, 1)? 3→0→1: 021C. (3, 2, 0): 2→0, 3→0: 021U. (3, 1, 2): 012 (1→2).
        let census = simple.triadicCensus()
        #expect(census["030C"] == 1 && census["021C"] == 1 && census["021U"] == 1 && census["012"] == 1)
    }

    @Test("A directed out-star and in-star: C(L, 2) triads 021D, 021U")
    func stars() {
        let leaves = 6
        let out = AdjacencyList(vertices: 0 ... leaves, edges: (1 ... leaves).map { DirectedEdge(from: 0, to: $0) })
        #expect(out.triadicCensus()["021D"] == 15 && out.triadicCensus()["003"] == 20)
        let into = AdjacencyList(vertices: 0 ... leaves, edges: (1 ... leaves).map { DirectedEdge(from: $0, to: 0) })
        #expect(into.triadicCensus()["021U"] == 15)
        // The hub last in index order.
        let last = AdjacencyList(vertices: 0 ... leaves, edges: (0 ..< leaves).map { DirectedEdge(from: leaves, to: $0) })
        #expect(last.triadicCensus() == out.triadicCensus())
    }

    @Test("The census on a graph without vertex indices")
    func unindexed() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a")])
        #expect(graph.triadicCensus()["030C"] == 1)
    }

    @Test("2,400 vertices and one arc: more than 2³¹ triples, counted in Int64 at either Int width")
    func pastInt32() {
        let graph = AdjacencyList(vertices: 0 ..< 2400, edges: [DirectedEdge(from: 0, to: 1)])
        let census = graph.triadicCensus()
        // C(2400, 3) = 2,301,120,800 triples: 2,398 hold the arc, the rest are empty.
        #expect(census["012"] == 2398)
        #expect(census["003"] == 2_301_118_402)
        #expect(census.counts.reduce(0, +) == 2_301_120_800)
    }
}
