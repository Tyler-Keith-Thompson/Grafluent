// Load, percolation, current-flow betweenness and closeness, subgraph centrality, communicability,
// VoteRank and the group centralities: values from NetworkX 3.7 (load_centrality,
// percolation_centrality, current_flow_betweenness_centrality, current_flow_closeness_centrality,
// subgraph_centrality, communicability, voterank, group_betweenness_centrality,
// group_closeness_centrality, group_degree_centrality, group_in_degree_centrality,
// group_out_degree_centrality) on a 5-vertex graph, a 4-vertex digraph and the karate club, and
// hand-computed cases. Path counts compare within 1e-12 relative; the measures built on a matrix
// factorization or exponential within 1e-9.

import AdjacencyListModule
import Centrality
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Load, percolation, current-flow, communicability, VoteRank and group centrality")
struct PathAndFlowCentralityTests {
    static let karatePairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17),
        (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9),
        (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
        (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33),
        (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29),
        (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]

    @Test("Load centrality: a 5-vertex graph (normalized and not, ordered pairs), a digraph, the karate club; it differs from betweenness where paths branch unevenly")
    func load() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (1, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.loadCentrality().scores == [0, 0.5, 0, 0.5, 0])
        #expect(graph.loadCentrality(normalized: false).scores == [0, 6, 0, 6, 0])
        #expect(graph.loadCentrality(weight: { _ in 1 }).scores == [0, 0.5, 0, 0.5, 0])
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (0, 3), (3, 2), (2, 0)]
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let expected = [0.6666666666666666, 0.08333333333333333, 0.6666666666666666, 0.08333333333333333]
        for (got, want) in zip(digraph.loadCentrality().scores, expected) { #expect(abs(got - want) <= 1e-12) }
        for (got, want) in zip(digraph.loadCentrality(weight: { _ in 2.0 }).scores, expected) { #expect(abs(got - want) <= 1e-12) }
        let karate = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: Self.karatePairs.map { UndirectedEdge($0.0, $0.1) })
        let karateLoad = [0.43468342276936023, 0.05493607954545455, 0.14834280303030306, 0.014234138257575758, 0.0006313131313131311,
            0.029987373737373736, 0.02998737373737374, 0.0, 0.051530934343434365, 0.0007891414141414141, 0.0006313131313131311, 0.0, 0.0,
            0.047887731481481496, 0.0, 0.0, 0.0, 0.0, 0.0, 0.03391992845117845, 0.0, 0.0, 0.0, 0.017676767676767676, 0.0023279671717171715,
            0.00495580808080808, 0.0, 0.023926767676767675, 0.0017624158249158247, 0.0036497790404040405, 0.014207175925925925,
            0.13407512626262627, 0.1476352062289563, 0.29843355429292934]
        for (v, want) in karateLoad.enumerated() { #expect(abs(karate.loadCentrality().score(of: v) - want) <= 1e-12, "vertex \(v)") }
        // A diamond 0-1-3, 0-2-3 and a tail 3-4 with 0-1 doubled: betweenness splits by path counts
        // (2 of 3 paths through 1), load splits each packet evenly by predecessor edge.
        let diamond = ReferencePseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 3), UndirectedEdge(0, 2), UndirectedEdge(2, 3)])
        // Toward 0, 3's packet splits over its predecessors 1 and 2 (½ each); toward 3, 0's packet
        // splits over its three predecessor edges, two to 1 (⅔) and one to 2 (⅓). Likewise toward 1
        // and 2 the packets of 2 and 1 split over 0 and 3: ½ each, and ⅔ to 0, ⅓ to 3.
        let load = diamond.loadCentrality(normalized: false).scores
        let shares = [0.5 + 2.0 / 3, 0.5 + 2.0 / 3, 0.5 + 1.0 / 3, 0.5 + 1.0 / 3]
        for (got, want) in zip(load, shares) { #expect(abs(got - want) <= 1e-12) }
        #expect(ReferencePseudograph<Int>(vertices: [], edges: []).loadCentrality().scores.isEmpty)
        // A weight a sum absorbs: 0 → 1 and 0 → 2 at 10²⁰, 1 → 2 and 2 → 1 at 1, so 1 and 2 are both
        // at 10²⁰ from 0 and one step between them looks shortest; only the one from the vertex
        // settled first is a DAG step, so from 0 the load is ½ in all (the other vertex's packet
        // split over two predecessors, half through the first).
        let absorbing = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1)])
        let heavy: [Double] = [1e20, 1e20, 1, 1]
        #expect(absorbing.loadCentrality(weight: { heavy[$0] }, normalized: false).scores.reduce(0, +) == 0.5)
        #expect(ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)]).loadCentrality().scores == [0, 0])
    }

    @Test("Percolation centrality: NetworkX's values; equal states give the normalized betweenness")
    func percolation() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (1, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let states = (0 ..< 5).map { Double($0 % 3) / 2 }
        let expected = [0.0, 0.3333333333333333, 0.0, 0.5, 0.0]
        for (got, want) in zip(graph.percolationCentrality(state: { states[$0] }).scores, expected) { #expect(abs(got - want) <= 1e-12) }
        for (got, want) in zip(graph.percolationCentrality(state: { states[$0] }, weight: { _ in 3 }).scores, expected) { #expect(abs(got - want) <= 1e-12) }
        let karate = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: Self.karatePairs.map { UndirectedEdge($0.0, $0.1) })
        let even = karate.percolationCentrality(state: { _ in 0.5 }).scores
        let betweenness = karate.betweennessCentrality().scores
        for v in 0 ..< 34 { #expect(abs(even[v] - betweenness[v]) <= 1e-12) }
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (0, 3), (3, 2), (2, 0)]
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let directedEven = digraph.percolationCentrality(state: { _ in 1 }).scores
        for (got, want) in zip(directedEven, digraph.betweennessCentrality().scores) { #expect(abs(got - want) <= 1e-12) }
        // All states 0: every term is 0/0, so 0.
        #expect(graph.percolationCentrality(state: { _ in 0 }).scores == [0, 0, 0, 0, 0])
        #expect(digraph.percolationCentrality(state: { _ in 1 }, weight: { _ in 1.0 }).scores == digraph.percolationCentrality(state: { _ in 1 }).scores)
    }

    @Test("Current-flow betweenness and closeness: NetworkX's values on a 5-vertex graph and the karate club (also weighted); a path's current flow is its betweenness")
    func currentFlow() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (1, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        for (got, want) in zip(graph.currentFlowBetweennessCentrality().scores, [0, 0.611111111111111, 0.22222222222222218, 0.611111111111111, 0]) {
            #expect(abs(got - want) <= 1e-9)
        }
        for (got, want) in zip(graph.currentFlowBetweennessCentrality(normalized: false).scores, [0, 3.666666666666666, 1.333333333333333, 3.666666666666666, 0]) {
            #expect(abs(got - want) <= 1e-9)
        }
        for (got, want) in zip(graph.currentFlowClosenessCentrality().scores, [0.1428571428571429, 0.25000000000000006, 0.2142857142857143, 0.25000000000000006, 0.14285714285714285]) {
            #expect(abs(got - want) <= 1e-9)
        }
        let karate = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: Self.karatePairs.map { UndirectedEdge($0.0, $0.1) })
        let betweenness = [0.4863872083592644, 0.18376431381413486, 0.25273846110572723, 0.09987735216323095, 0.04689992025518343,
            0.0717869484316854, 0.0717869484316854, 0.053561782210208714, 0.10353592793411022, 0.029126328568624016, 0.046899920255183525, 0.0,
            0.021792873013136576, 0.09521613203920223, 0.009878160254182543, 0.009878160254182543, 0.015749601275917083, 0.020610952534966434,
            0.009878160254182537, 0.06788125885531363, 0.009878160254182543, 0.02061095253496649, 0.009878160254182537, 0.09254870183404551,
            0.041771068760782855, 0.04684284394689104, 0.015894402718282057, 0.08118574227825898, 0.0475059951347963, 0.058546256409499633,
            0.07559533700334578, 0.15521701365947665, 0.24768161900117455, 0.39036851955898444]
        for (v, want) in betweenness.enumerated() { #expect(abs(karate.currentFlowBetweennessCentrality().score(of: v) - want) <= 1e-9, "vertex \(v)") }
        let closeness = [0.058567106045101555, 0.05252500943344552, 0.055765414968630314, 0.04682680760435631, 0.0327352440331331,
            0.03410635983780078, 0.03410635983780078, 0.04203271504240412, 0.04710638325774851, 0.031629733155447266, 0.0327352440331331,
            0.02037721036113521, 0.03022150358560399, 0.04675782020511094, 0.03094550141692615, 0.030945501416926157, 0.023957204300193245,
            0.0308494946667879, 0.030945501416926157, 0.03909590482434084, 0.030945501416926164, 0.030849494666787915, 0.03094550141692617,
            0.043622478785180066, 0.0335867778973753, 0.03376348116644054, 0.02920213627986426, 0.04126899979931104, 0.03817020635900134,
            0.039675682866820175, 0.043043271644583055, 0.047582600558111615, 0.05509452020307344, 0.059182906932661455]
        for (v, want) in closeness.enumerated() { #expect(abs(karate.currentFlowClosenessCentrality().score(of: v) - want) <= 1e-9, "vertex \(v)") }
        let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3,
            3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
        let weighted = [0.4706081583162641, 0.18993573407603437, 0.2875292731502664, 0.10773893577514834, 0.04552357752917117,
            0.08002047723718606, 0.07240917839528449, 0.05322307407701424, 0.13448792546403343, 0.0183283508578965, 0.0432202300886891, 0.0,
            0.012107783898798375, 0.11115116593113188, 0.007768097828949393, 0.011754661376139581, 0.012323250549522687, 0.009486680868132915,
            0.00459694648241016, 0.03512631086576913, 0.004564607895856724, 0.014441722657654055, 0.00827346021853858, 0.11171787890658268,
            0.025797552755549902, 0.058238561331859104, 0.014882534235423534, 0.08491506977034322, 0.04129871558922864, 0.06320960607750398,
            0.07283805542995177, 0.15490113226501068, 0.26807625135555824, 0.3878265618606896]
        for (v, want) in weighted.enumerated() { #expect(abs(karate.currentFlowBetweennessCentrality(weight: { w[$0] }).score(of: v) - want) <= 1e-9, "vertex \(v)") }
        // On a tree current flows along the only path: current-flow betweenness is betweenness.
        let path = ReferencePseudograph(vertices: 0 ..< 6, edges: (0 ..< 5).map { UndirectedEdge($0, $0 + 1) })
        for (got, want) in zip(path.currentFlowBetweennessCentrality().scores, path.betweennessCentrality().scores) { #expect(abs(got - want) <= 1e-9) }
        // Resistances on a path are distances: closeness of an end of P₃ is 1 / (1 + 2).
        let p3 = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(abs(p3.currentFlowClosenessCentrality().score(of: 0) - 1.0 / 3) <= 1e-12)
        // Parallel copies halve the resistance; doubling the conductance does the same.
        let doubled = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 2), UndirectedEdge(2, 1), UndirectedEdge(1, 1)])
        #expect(abs(doubled.currentFlowClosenessCentrality().score(of: 0) - 2.0 / 3) <= 1e-12)
        #expect(abs(p3.currentFlowClosenessCentrality(weight: { _ in 2.0 }).score(of: 0) - 2.0 / 3) <= 1e-12)
        #expect(ReferencePseudograph<Int>(vertices: [0], edges: []).currentFlowClosenessCentrality().scores == [0])
        #expect(ReferencePseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)]).currentFlowBetweennessCentrality().scores == [0, 0])
        #expect(ReferencePseudograph<Int>(vertices: [], edges: []).currentFlowBetweennessCentrality().scores.isEmpty)
    }

    @Test("Subgraph centrality and communicability: NetworkX's values; K₂ in closed form (cosh 1, sinh 1); loops and parallel edges as 0/1 adjacency")
    func communicability() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (1, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        for (got, want) in zip(graph.subgraphCentrality().scores, [1.6632340684887565, 3.5712178774109815, 2.8583432409549365, 3.571217877410981, 1.6632340684887585]) {
            #expect(abs(got - want) <= 1e-9 * want)
        }
        let c = graph.communicability()
        #expect(abs(c.communicability(of: 0, and: 4) - 0.2659375519887135) <= 1e-9)
        #expect(abs(c.communicability(of: 1, and: 3) - 2.9149492824345145) <= 1e-9)
        #expect(c.communicability(of: 1, and: 3) == c.communicability(ofIndex: 3, andIndex: 1))
        #expect(abs(c.communicability(of: 2, and: 2) - graph.subgraphCentrality().score(of: 2)) <= 1e-12)
        #expect((try? c.communicability(checked: 0, and: 9)) == nil)
        #expect((try? c.communicability(checked: 0, and: 4)) == c.communicability(of: 0, and: 4))
        let k2 = ReferencePseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)])
        #expect(abs(k2.communicability().communicability(of: 0, and: 0) - 1.5430806348152437) <= 1e-12)
        #expect(abs(k2.communicability().communicability(of: 0, and: 1) - 1.1752011936438014) <= 1e-12)
        // A loop: A = [1], e^A = e.
        let loop = ReferencePseudograph(vertices: [0], edges: [UndirectedEdge(0, 0)])
        #expect(abs(loop.subgraphCentrality().score(of: 0) - 2.718281828459045) <= 1e-12)
        #expect(ReferencePseudograph<Int>(vertices: [0], edges: []).subgraphCentrality().scores == [1])
        #expect(ReferencePseudograph<Int>(vertices: [], edges: []).subgraphCentrality().scores.isEmpty)
        // A dense graph (K₂₀) needs squaring: e^{A}_vv = (e^{19} + 19 e^{-1}) / 20.
        var k20: [UndirectedEdge<Int>] = []
        for i in 0 ..< 20 { for j in i + 1 ..< 20 { k20.append(UndirectedEdge(i, j)) } }
        let complete = UndirectedAdjacencyList(vertices: 0 ..< 20, edges: k20)
        let exact = (178_482_300.96318725 + 19 * 0.36787944117144233) / 20
        #expect(abs(complete.subgraphCentrality().score(of: 7) - exact) <= 1e-12 * exact)
    }

    @Test("VoteRank: NetworkX's spreaders on the karate club (all and three) and on a digraph; nothing to choose")
    func voteRank() {
        let karate = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: Self.karatePairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(karate.voteRank() == [33, 0, 32, 2, 1, 5, 31, 23, 6, 3, 24, 29, 4, 8])
        #expect(karate.voteRank(count: 3) == [33, 0, 32])
        #expect(karate.voteRank(count: 0).isEmpty)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (0, 3), (3, 2), (2, 0)]
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(digraph.voteRank() == [0, 1, 3])
        let csr = CompressedSparseRow(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(csr.voteRank() == [0, 1, 3])
        #expect(ReferencePseudograph<Int>(vertices: 0 ..< 3, edges: []).voteRank().isEmpty)
        #expect(ReferencePseudograph<Int>(vertices: [], edges: []).voteRank().isEmpty)
        let labeled = ReferencePseudograph(vertices: ["b", "a", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("a", "c")])
        #expect(labeled.voteRank() == ["a"])
    }

    @Test("Group centralities: NetworkX's betweenness, closeness and degree of {0, 33} in the karate club and of one vertex of a digraph")
    func group() {
        let karate = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: Self.karatePairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(abs(karate.groupBetweennessCentrality(of: [0, 33]) - 0.6845574116743472) <= 1e-12)
        #expect(abs(karate.groupBetweennessCentrality(of: [33, 0, 33], normalized: false) - 339.5404761904762) <= 1e-9)
        #expect(abs(karate.groupBetweennessCentrality(of: [0, 33], endpoints: true) - 0.7211060181648418) <= 1e-12)
        // A repeated member counts once in the normalization's N = n − |C|.
        #expect(abs(karate.groupBetweennessCentrality(of: [0, 33, 0]) - 0.6845574116743472) <= 1e-12)
        #expect(abs(karate.groupBetweennessCentrality(of: [0, 33], weight: { _ in 1 }) - 0.6845574116743472) <= 1e-12)
        #expect(abs(karate.groupClosenessCentrality(of: [0, 33]) - 0.9142857142857143) <= 1e-12)
        #expect(abs(karate.groupDegreeCentrality(of: [0, 33]) - 0.90625) <= 1e-12)
        let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3,
            3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
        #expect(abs(karate.groupClosenessCentrality(of: [0, 33], weight: { w[$0] }) - 0.36363636363636365) <= 1e-12)
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (0, 3), (3, 2), (2, 0)]
        let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(abs(digraph.groupBetweennessCentrality(of: [1]) - 0.08333333333333333) <= 1e-12)
        #expect(digraph.groupBetweennessCentrality(of: [1], normalized: false) == 0.5)
        #expect(digraph.groupBetweennessCentrality(of: [1], weight: { _ in 1 }, normalized: false) == 0.5)
        #expect(digraph.groupClosenessCentrality(of: [2]) == 0.75)
        #expect(digraph.groupClosenessCentrality(of: [2], weight: { _ in 2.0 }) == 0.375)
        #expect(abs(digraph.groupInDegreeCentrality(of: [2]) - 2.0 / 3) <= 1e-15)
        #expect(abs(digraph.groupOutDegreeCentrality(of: [2]) - 1.0 / 3) <= 1e-15)
        // A group that is a cut: every path between the sides meets it.
        let path = ReferencePseudograph(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        // Pairs outside {2}: {0,1} × {3,4} cross it, 4 of the 6 unordered pairs.
        #expect(abs(path.groupBetweennessCentrality(of: [2]) - 4.0 / 6) <= 1e-12)
        #expect(path.groupBetweennessCentrality(of: [2], normalized: false) == 4)
        #expect(path.groupBetweennessCentrality(of: [Int]()) == 0)
        // Closeness: d = 2, 1, 1, 2 from the middle; an unreached vertex adds 0.
        #expect(path.groupClosenessCentrality(of: [2]) == 4.0 / 6)
        let split = ReferencePseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        #expect(split.groupClosenessCentrality(of: [0]) == 2.0 / 1)
        #expect(split.groupClosenessCentrality(of: [2]) == 0)
        #expect(split.groupDegreeCentrality(of: [0]) == 0.5)
    }
}
