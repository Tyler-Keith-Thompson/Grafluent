// Average neighbor degree and average degree connectivity on hand-computed graphs. Undirected:
// Σ d(u) over a vertex's edge ends over its degree, so a parallel copy counts each time and a
// self-loop twice. Directed: the `target` degrees across the arcs `source` names, over the
// `source` degree. Weighted: Σ w · k over the weighted source degree, k unweighted. Expected
// values are worked out by hand; the directed tables agree with NetworkX 3.7's
// `average_neighbor_degree` and, for source in or out, `average_degree_connectivity`.

import AdjacencyListModule
import Assortativity
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Neighbor degrees")
struct NeighborDegreeTests {
    @Test("A triangle with a pendant: averages 5/2, 5/2, 5/3, 3")
    func trianglePendant() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let averages = graph.averageNeighborDegrees()
        let expected = [2.5, 2.5, 5.0 / 3.0, 3]
        #expect(averages.values == expected)
        #expect((0 ..< 4).map { averages.averageNeighborDegree(of: $0) } == expected)
        #expect((0 ..< 4).map { averages.averageNeighborDegree(ofIndex: $0) } == expected)
        #expect(graph.averageDegreeConnectivity() == [2: 2.5, 3: 5.0 / 3.0, 1: 3])
    }

    @Test("An isolated vertex averages 0 and joins k_nn at k = 0 with 0")
    func isolated() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        #expect(graph.averageNeighborDegrees().values == [1, 1, 0])
        #expect(graph.averageDegreeConnectivity() == [1: 1, 0: 0])
        #expect(UndirectedAdjacencyList<Int>().averageNeighborDegrees().values == [])
        #expect(UndirectedAdjacencyList<Int>().averageDegreeConnectivity() == [:])
    }

    @Test("Parallel edges and a self-loop count as edge ends")
    func multigraph() {
        // 0–1 twice, loop at 1, 1–2: degrees 2, 5, 1.
        // 0: (5 + 5) / 2 = 5. 1: (2 + 2 + 5 + 5 + 1) / 5 = 3. 2: 5.
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)])
        #expect(graph.averageNeighborDegrees().values == [5, 3, 5])
        #expect(graph.averageDegreeConnectivity() == [2: 5, 5: 3, 1: 5])
    }

    @Test("Weighted: Σ w d(u) / s(v) with unweighted neighbor degrees")
    func weighted() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let w: [Double] = [1, 2, 0.5, 4]
        // 0: (1·2 + 2·3) / 3 = 8/3. 1: (1·2 + 0.5·3) / 1.5 = 7/3. 2: (2·2 + 0.5·2 + 4·1) / 6.5 = 9/6.5. 3: 3.
        let values = graph.averageNeighborDegrees(weight: { w[$0] }).values
        let expected = [8.0 / 3.0, 7.0 / 3.0, 9 / 6.5, 3]
        for v in 0 ..< 4 { #expect(abs(values[v] - expected[v]) <= 1e-12) }
        let knn = graph.averageDegreeConnectivity(weight: { w[$0] })
        // k = 2: (8 + 3.5) / 4.5; k = 3: 9 / 6.5; k = 1: 12 / 4.
        #expect(Set(knn.keys) == [1, 2, 3])
        #expect(abs(knn[2]! - 11.5 / 4.5) <= 1e-12 && abs(knn[3]! - 9 / 6.5) <= 1e-12 && knn[1]! == 3)
    }

    @Test("Weighted: a vertex whose weights sum to 0 averages 0; k_nn takes the bare sum")
    func zeroStrength() {
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let w: [Double] = [0, 1]
        // 0: strength 0 → 0. 1: (0·1 + 1·1) / 1 = 1. 2: 2.
        #expect(graph.averageNeighborDegrees(weight: { w[$0] }).values == [0, 1, 2])
        // k = 1: vertices 0 and 2, sums 0 + 2, strengths 0 + 1 → 2. k = 2: 1.
        #expect(graph.averageDegreeConnectivity(weight: { w[$0] }) == [1: 2, 2: 1])
        let zero = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        #expect(zero.averageDegreeConnectivity(weight: { _ in 0.0 }) == [1: 0])
        // Weights 1 and −1 cancel: path 1–0–2–3 with weights 1, −1, 1. Degree-2 vertices 0 and 2
        // have strength 0 and sums 1·1 − 1·2 = −1 and −1·2 + 1·1 = −1: k_nn(2) is the bare −2.
        let cancelling = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(2, 3)])
        let signed: [Double] = [1, -1, 1]
        #expect(cancelling.averageNeighborDegrees(weight: { signed[$0] }).values == [0, 2, 0, 2])
        #expect(cancelling.averageDegreeConnectivity(weight: { signed[$0] }) == [2: -2, 1: 2])
    }

    @Test("Directed: every source and target pairing on the six-arc digraph, as NetworkX gives")
    func directed() {
        // Arcs 0→1, 0→2, 1→2, 2→0, 2→3, 3→2.
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        let table: [(DegreeType, DegreeType, [Double])] = [
            (.in, .in, [3, 1, 1, 3]), (.in, .out, [2, 2, 4.0 / 3.0, 2]), (.in, .total, [5, 3, 7.0 / 3.0, 5]),
            (.out, .in, [2, 3, 1, 3]), (.out, .out, [1.5, 2, 1.5, 2]), (.out, .total, [3.5, 5, 2.5, 5]),
            (.total, .in, [7.0 / 3.0, 2, 1, 3]), (.total, .out, [5.0 / 3.0, 2, 1.4, 2]), (.total, .total, [4, 4, 2.4, 5]),
        ]
        for (s, t, expected) in table {
            let values = graph.averageNeighborDegrees(source: s, target: t).values
            for v in 0 ..< 4 { #expect(abs(values[v] - expected[v]) <= 1e-12, "\(s) \(t) vertex \(v)") }
        }
        #expect(graph.averageNeighborDegrees().values == graph.averageNeighborDegrees(source: .out, target: .out).values)
        let connectivity: [(DegreeType, DegreeType, [Int: Double])] = [
            (.in, .in, [1: 7.0 / 3.0, 3: 1]), (.in, .out, [1: 2, 3: 4.0 / 3.0]), (.in, .total, [1: 13.0 / 3.0, 3: 7.0 / 3.0]),
            (.out, .in, [2: 1.5, 1: 3]), (.out, .out, [2: 1.5, 1: 2]), (.out, .total, [2: 3, 1: 5]),
        ]
        for (s, t, expected) in connectivity {
            let knn = graph.averageDegreeConnectivity(source: s, target: t)
            #expect(Set(knn.keys) == Set(expected.keys), "\(s) \(t)")
            for (k, value) in expected { #expect(abs(knn[k]! - value) <= 1e-12, "\(s) \(t) k = \(k)") }
        }
        // Total: both arcs of each vertex. Totals 3, 2, 5, 2; vertex 0 reads 1, 2 (out) and 2 (in):
        // (2 + 5 + 5) / 3 = 4; 1 and 3 (degree 2): (5 + 3 + 5 + 5) / 4 = 4.5; 2: (3 + 2 + 2 + 3 + 2) / 5.
        let total = graph.averageDegreeConnectivity()
        #expect(Set(total.keys) == [2, 3, 5])
        #expect(abs(total[3]! - 4) <= 1e-12 && abs(total[2]! - 4.5) <= 1e-12 && abs(total[5]! - 12.0 / 5.0) <= 1e-12)
    }

    @Test("Directed weighted: Σ w k(u) over the source arcs' weights")
    func directedWeighted() {
        // Arcs 0→1 (2), 0→2 (1), 1→2 (3). Out-degrees 2, 1, 0; in-degrees 0, 1, 2.
        let digraph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        let w: [Double] = [2, 1, 3]
        // Out-arcs, in-degree target: 0: (2·1 + 1·2) / 3 = 4/3; 1: (3·2) / 3 = 2; 2: 0.
        let out = digraph.averageNeighborDegrees(source: .out, target: .in, weight: { w[$0] }).values
        #expect(abs(out[0] - 4.0 / 3.0) <= 1e-12 && out[1] == 2 && out[2] == 0)
        // In-arcs, out-degree target: 0: 0; 1: (2·2) / 2 = 2; 2: (1·2 + 3·1) / 4 = 5/4.
        let into = digraph.averageNeighborDegrees(source: .in, target: .out, weight: { w[$0] }).values
        #expect(into == [0, 2, 1.25])
        // k_nn by in-degree, out-degree targets: k = 0: 0 (bare sum); k = 1: 4 / 2 = 2; k = 2: 5 / 4.
        #expect(digraph.averageDegreeConnectivity(source: .in, target: .out, weight: { w[$0] }) == [0: 0, 1: 2, 2: 1.25])
    }

    @Test("A directed self-loop reaches its own vertex, once each way")
    func directedSelfLoop() {
        // Arcs 0→0, 0→1. Out-degrees 2, 0; in-degrees 1, 1.
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)])
        // Out-arcs with out-degree target: 0: (2 + 0) / 2 = 1; 1: 0.
        #expect(graph.averageNeighborDegrees().values == [1, 0])
        // Total: 0 reads 0 (out), 1 (out), 0 (in): totals 3, 1 → (3 + 1 + 3) / 3.
        let total = graph.averageNeighborDegrees(source: .total, target: .total).values
        #expect(abs(total[0] - 7.0 / 3.0) <= 1e-12 && total[1] == 3)
    }
}
