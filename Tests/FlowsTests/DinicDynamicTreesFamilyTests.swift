// dinicMaximumFlow(from:to:dynamicTrees: true, capacity:) beyond the catalog rows: the network its
// dynamic trees are for (a chain that fans out near the sink, every augmenting path sharing the
// chain), unsigned capacities, whose residuals the trees only ever subtract from, and seeded
// random networks with parallel edges and self-loops, directed and undirected, against the plain Dinic's value and canonical cut.

import AdjacencyListModule
import Flows
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

@Suite("dinicMaximumFlow with dynamic trees")
struct DinicDynamicTreesFamilyTests {
    @Test("A chain of 300 arcs of capacity 200 fanning out to 200 unit paths: value 200, every fan arc saturated, the sink alone on its side")
    func chainAndFan() {
        // 0 → 1 → … → 300 (the hub), then hub → 301 + j → 501 for j in 0..<200.
        let length = 300, width = 200
        let sink = length + width + 1
        var edges = (0 ..< length).map { DirectedEdge(from: $0, to: $0 + 1) }
        for j in 0 ..< width {
            edges.append(DirectedEdge(from: length, to: length + 1 + j))
            edges.append(DirectedEdge(from: length + 1 + j, to: sink))
        }
        let graph = AdjacencyList(vertices: 0 ... sink, edges: edges)
        let capacities = (0 ..< edges.count).map { $0 < length ? width : 1 }
        let flow = graph.dinicMaximumFlow(from: 0, to: sink, dynamicTrees: true) { capacities[$0] }
        #expect(flow.value == width)
        let saturated = (0 ..< edges.count).allSatisfy { flow.flow(ofEdgeAt: $0) == capacities[$0] }
        #expect(saturated)
        #expect(flow.minimumCut.sinkSide == [sink])
        #expect(flow.minimumCut == graph.dinicMaximumFlow(from: 0, to: sink) { capacities[$0] }.minimumCut)
    }

    @Test("UInt8 capacities up to 255: the value and every arc's flow within its capacity")
    func unsignedCapacities() {
        // 0 → 1 (200), 0 → 2 (55), 1 → 2 (10), 1 → 3 (190), 2 → 3 (255): value 255, the only
        // maximum flow, which fills every arc but the last; 1 cannot reach the sink afterwards.
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        let capacities: [UInt8] = [200, 55, 10, 190, 255]
        let flow = graph.dinicMaximumFlow(from: 0, to: 3, dynamicTrees: true) { capacities[$0] }
        #expect(flow.value == 255)
        let within = (0 ..< 5).allSatisfy { flow.flow(ofEdgeAt: $0) <= capacities[$0] }
        #expect(within)
        #expect(flow.flow(ofEdgeAt: 0) == 200 && flow.flow(ofEdgeAt: 1) == 55)
        #expect(flow.flow(ofEdgeAt: 2) == 10 && flow.flow(ofEdgeAt: 3) == 190 && flow.flow(ofEdgeAt: 4) == 65)
        #expect(flow.minimumCut.sinkSide == [2, 3])
    }

    @Test("Seeded random networks: the value and canonical cut of the plain Dinic, directed and undirected", .tags(.randomized))
    func randomNetworks() {
        var rng = SeededRandomNumberGenerator(seed: 29)
        for round in 0 ..< 60 {
            let n = Int.random(in: 2 ... 40, using: &rng)
            let m = Int.random(in: 0 ... 5 * n, using: &rng)
            let pairs = (0 ..< m).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let capacities = (0 ..< m).map { _ in Int.random(in: 0 ... [1, 9, 1000][round % 3], using: &rng) }
            let s = Int.random(in: 0 ..< n, using: &rng)
            var t = Int.random(in: 0 ..< n - 1, using: &rng)
            if t >= s { t += 1 }
            let directed = DirectedPseudograph(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let plain = directed.dinicMaximumFlow(from: s, to: t) { capacities[$0] }
            let trees = directed.dinicMaximumFlow(from: s, to: t, dynamicTrees: true) { capacities[$0] }
            #expect(trees.value == plain.value, "round \(round)")
            #expect(trees.minimumCut == plain.minimumCut, "round \(round)")
            var excess = [Int](repeating: 0, count: n)
            for (k, (u, v)) in pairs.enumerated() {
                let f = trees.flow(ofEdgeAt: k)
                #expect(f >= 0 && f <= capacities[k] && (u != v || f == 0), "round \(round) edge \(k)")
                excess[u] -= f
                excess[v] += f
            }
            let conserved = (0 ..< n).allSatisfy { $0 == s || $0 == t || excess[$0] == 0 }
            #expect(conserved, "round \(round)")
            #expect(excess[t] == trees.value, "round \(round)")

            let undirected = Pseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let plainUndirected = undirected.dinicMaximumFlow(from: s, to: t) { capacities[$0] }
            let treesUndirected = undirected.dinicMaximumFlow(from: s, to: t, dynamicTrees: true) { capacities[$0] }
            #expect(treesUndirected.value == plainUndirected.value, "round \(round)")
            #expect(treesUndirected.minimumCut == plainUndirected.minimumCut, "round \(round)")
        }
    }
}
