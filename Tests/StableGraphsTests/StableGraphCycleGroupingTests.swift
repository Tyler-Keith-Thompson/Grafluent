// nontrivialStronglyConnectedComponents() and the self-loop queries on a StableDirectedGraph, with
// and without vertex holes: with holes the graph has no vertex indices, so the components come
// from its numbered rows and the self-loops from its successors by vertex. Every answer is checked
// against the same graph compacted (no holes) and against a model of the edges; and the
// documented sort by vertex position lists the components in insertion order.

import Connectivity
import GrafluentTestSupport
import GraphProtocols
import StableGraphs
import Testing

@Suite("Cycle grouping and self-loops on a StableDirectedGraph")
struct StableGraphCycleGroupingTests {
    @Test("with vertex holes, the nontrivial components and self-loops match the compacted graph")
    func holes() {
        var rng = SeededRandomNumberGenerator(seed: 4242)
        for _ in 0 ..< 200 {
            let n = Int.random(in: 2 ... 12, using: &rng)
            var graph = StableDirectedGraph<Int>(vertices: 0 ..< n)
            for _ in 0 ..< Int.random(in: 0 ... 3 * n, using: &rng) {
                _ = graph.insert(edge: DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)))
            }
            for _ in 0 ..< Int.random(in: 1 ... 2, using: &rng) {
                _ = graph.remove(Int.random(in: 0 ..< n, using: &rng))
            }
            let compacted = StableDirectedGraph<Int>(vertices: Array(graph.vertices), edges: Array(graph.edges))
            #expect(graph.nontrivialStronglyConnectedComponents().map(Array.init) == compacted.nontrivialStronglyConnectedComponents().map(Array.init))
            #expect(graph.nontrivialStronglyConnectedComponents().map(Array.init) == graph.stronglyConnectedComponents().map(Array.init).filter { $0.count > 1 || graph.successors(of: $0[0]).contains($0[0]) })
            let looped = graph.vertices.filter { v in graph.edges.contains { $0.source == v && $0.target == v } }
            #expect(graph.hasSelfLoops == !looped.isEmpty)
            #expect(graph.verticesWithSelfLoops() == Array(looped))
            #expect(graph.selfLoopEdges().map { graph.edges[$0] } == compacted.selfLoopEdges().map { compacted.edges[$0] })
            #expect(graph.selfLoopEdges().allSatisfy { graph.edges[$0].isSelfLoop })
            #expect(graph.selfLoopEdges().count == graph.edges.count { $0.isSelfLoop })
        }
    }

    @Test("sorting by the first vertex's position lists the components in insertion order")
    func insertionOrder() {
        // Inserted 0…5: a 2-cycle 0 ⇄ 3 reached last by the search, a self-loop at 4, a cycle 1 → 2 → 5 → 1.
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 6)
        for (u, v) in [(0, 3), (3, 0), (4, 4), (1, 2), (2, 5), (5, 1), (3, 1)] { _ = graph.insert(edge: DirectedEdge(from: u, to: v)) }
        let components = graph.nontrivialStronglyConnectedComponents()
        #expect(components.map(Array.init) == [[1, 2, 5], [0, 3], [4]])
        let sorted = components.sorted { graph.vertexPosition(of: $0.first!) < graph.vertexPosition(of: $1.first!) }
        #expect(sorted.map(Array.init) == [[0, 3], [1, 2, 5], [4]])
    }
}
