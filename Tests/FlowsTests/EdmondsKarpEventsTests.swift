// The Edmonds–Karp algorithm as an event sequence (`lazy.edmondsKarp`): CLRS's network and a
// network whose second path cancels flow, on several representations, the trivial cases, value
// semantics, the preconditions, and a property test replaying the events against
// `edmondsKarpMaximumFlow`. Case IDs (FL-9nn) are listed in README.md; the traced rows come from
// Tests/Catalogs/Flows/cases_events.py.

import AdjacencyListModule
import Flows
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import StableGraphs
import Testing

/// A directed multigraph with no vertex or edge indices.
private struct UnindexedDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Edmonds–Karp events")
struct EdmondsKarpEventsTests {
    @Test("FL-900 CLRS's network: every event in order, on every representation, replaying edmondsKarpMaximumFlow", .tags(.fixture))
    func clrs() {
        let raw: [(Int, Int, Int)] = [(0, 1, 16), (0, 2, 13), (2, 1, 4), (1, 3, 12), (3, 2, 9), (2, 4, 14), (4, 3, 7), (3, 5, 20), (4, 5, 4)]
        let edges = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
        // Tests/Catalogs/Flows/cases_events.out, FL-900.
        let expected: [EdmondsKarpEvent<Int, Int>] = [
            .augmentingPath([0, 3, 7], bottleneck: 12), .push(0, amount: 12), .push(3, amount: 12), .push(7, amount: 12),
            .augmentingPath([1, 5, 8], bottleneck: 4), .push(1, amount: 4), .push(5, amount: 4), .push(8, amount: 4),
            .augmentingPath([1, 5, 6, 7], bottleneck: 7), .push(1, amount: 7), .push(5, amount: 7), .push(6, amount: 7), .push(7, amount: 7),
        ]
        func check<G: DirectedGraph<Int>>(_ graph: G) where G.Edges.Index == Int {
            var asked: [Int] = []
            let events = graph.lazy.edmondsKarp(from: 0, to: 5) { asked.append($0); return raw[$0].2 }
            #expect(asked == Array(0 ..< 9), "\(G.self)")
            #expect(Array(events) == expected, "\(G.self)")
            let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5) { raw[$0].2 }
            var flows = [Int](repeating: 0, count: raw.count)
            for event in events {
                if case .push(let e, let c) = event { flows[e] += c }
                if case .cancel(let e, let c) = event { flows[e] -= c }
            }
            #expect(flows == raw.indices.map { flow.flow(ofEdgeAt: $0) } && flow.value == 23, "\(G.self)")
        }
        check(AdjacencyList(vertices: 0 ..< 6, edges: edges))
        check(DirectedPseudograph(vertices: 0 ..< 6, edges: edges))
        check(ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: edges))
        check(UnindexedDigraph(vertices: Array(0 ..< 6), edges: edges))
        var stable = StableDirectedGraph(vertices: [99] + Array(0 ..< 6), edges: edges)
        stable.remove(99)
        check(stable)
        #expect(expected[0].description == "augmentingPath([0, 3, 7], 12)" && expected[1].description == "push(0, 12)")
    }

    @Test("FL-901 a cancelling path, a self-loop never asked, a parallel copy told apart", .tags(.fixture, .selfLoops))
    func cancelling() {
        let raw: [(Int, Int, Int)] = [(0, 1, 1), (1, 1, 5), (1, 2, 1), (2, 5, 1), (0, 3, 1), (3, 2, 1), (1, 4, 1), (4, 5, 1), (0, 3, 4)]
        let edges = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected: [EdmondsKarpEvent<Int, Int>] = [
            .augmentingPath([0, 2, 3], bottleneck: 1), .push(0, amount: 1), .push(2, amount: 1), .push(3, amount: 1),
            .augmentingPath([4, 5, 2, 6, 7], bottleneck: 1), .push(4, amount: 1), .push(5, amount: 1), .cancel(2, amount: 1),
            .push(6, amount: 1), .push(7, amount: 1),
        ]
        var asked: [Int] = []
        let graph = DirectedPseudograph(vertices: 0 ..< 6, edges: edges)
        #expect(Array(graph.lazy.edmondsKarp(from: 0, to: 5) { asked.append($0); return raw[$0].2 }) == expected)
        #expect(asked == [0, 2, 3, 4, 5, 6, 7, 8])
        #expect(Array(UnindexedDigraph(vertices: Array(0 ..< 6), edges: edges).lazy.edmondsKarp(from: 0, to: 5) { raw[$0].2 }) == expected)
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 5) { raw[$0].2 }
        #expect(raw.indices.map { flow.flow(ofEdgeAt: $0) } == [1, 0, 0, 1, 1, 1, 1, 1, 0])
        #expect(expected[7].description == "cancel(2, 1)")
    }

    @Test("FL-902 no augmenting path: no events; zero capacities; Double capacities")
    func trivial() {
        let apart = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 1, to: 2)])
        #expect(Array(apart.lazy.edmondsKarp(from: 0, to: 2) { _ in 4 }).isEmpty)
        let zero = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(Array(zero.lazy.edmondsKarp(from: 0, to: 1) { _ in 0 }).isEmpty)
        let named = AdjacencyList(vertices: ["s", "a", "t"], edges: [DirectedEdge(from: "s", to: "a"), DirectedEdge(from: "a", to: "t")])
        let events = Array(named.lazy.edmondsKarp(from: "s", to: "t") { [1.5, 0.5][$0] })
        #expect(events == [.augmentingPath([0, 1], bottleneck: 0.5), .push(0, amount: 0.5), .push(1, amount: 0.5)])
        #expect(Set(events).count == 3)
    }

    @Test("FL-903 value semantics: a later mutation does not change the events; each iterator starts over; stopping early")
    func valueSemantics() {
        var graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        var capacities = [3, 2]
        let events = graph.lazy.edmondsKarp(from: 0, to: 2) { capacities[$0] }
        capacities = [0, 0]
        _ = graph.insert(edge: DirectedEdge(from: 0, to: 2))
        let first = Array(events)
        #expect(first == [.augmentingPath([0, 1], bottleneck: 2), .push(0, amount: 2), .push(1, amount: 2)])
        #expect(Array(events) == first)
        #expect(Array(events.prefix(2)) == Array(first.prefix(2)))
        var iterator = events.makeIterator()
        for _ in 0 ..< 4 { _ = iterator.next() }
        #expect(iterator.next() == nil)
    }

    @Test("FL-904 the source as the sink, a missing vertex, a negative or NaN capacity, an overflowing source trap")
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.lazy.edmondsKarp(from: 0, to: 0) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.lazy.edmondsKarp(from: 0, to: 7) { _ in 1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.lazy.edmondsKarp(from: 0, to: 1) { _ in -1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.lazy.edmondsKarp(from: 0, to: 1) { _ in Double.nan }
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
            _ = graph.lazy.edmondsKarp(from: 0, to: 1) { _ in Int.max }
        }
        // Edges into the source do not count toward its sum.
        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 0)])
        #expect(Array(graph.lazy.edmondsKarp(from: 0, to: 1) { _ in Int.max }) == [.augmentingPath([0], bottleneck: .max), .push(0, amount: .max)])
    }

    @Test("FL-905 property: pushes less cancellations are edmondsKarpMaximumFlow's flows; bottlenecks add up to its value; paths are residual s–t paths", .tags(.randomized))
    func property() async {
        // Up to 24 edges on vertices 0..<7 with capacities 0...5; repeats and self-loops allowed.
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 5)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: edges) { raw in
            let arcs = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            func check<G: DirectedGraph<Int>>(_ graph: G, _ name: String) where G.Edges.Index == Int {
                let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 6) { raw[$0].2 }
                var flows = [Int](repeating: 0, count: raw.count)
                var value = 0
                var pending: [Int] = []
                var bottleneck = 0
                var at = 0
                for event in graph.lazy.edmondsKarp(from: 0, to: 6, capacity: { raw[$0].2 }) {
                    switch event {
                    case .augmentingPath(let path, let c):
                        #expect(pending.isEmpty && c > 0 && !path.isEmpty, "\(name)")
                        pending = path
                        bottleneck = c
                        value += c
                        at = 0
                    case .push(let e, let c):
                        #expect(pending.first == e && c == bottleneck && raw[e].0 == at, "\(name)")
                        flows[e] += c
                        #expect(flows[e] <= raw[e].2, "\(name)")
                        at = raw[e].1
                        pending.removeFirst()
                    case .cancel(let e, let c):
                        #expect(pending.first == e && c == bottleneck && raw[e].1 == at, "\(name)")
                        flows[e] -= c
                        #expect(flows[e] >= 0, "\(name)")
                        at = raw[e].0
                        pending.removeFirst()
                    }
                    if pending.isEmpty { #expect(at == 6, "\(name)") }
                }
                #expect(pending.isEmpty && value == flow.value, "\(name)")
                #expect(flows == raw.indices.map { flow.flow(ofEdgeAt: $0) }, "\(name)")
            }
            check(DirectedPseudograph(vertices: 0 ..< 7, edges: arcs), "pseudograph")
            check(ReferenceDirectedMultigraph(vertices: 0 ..< 7, edges: arcs), "reference multigraph")
            check(UnindexedDigraph(vertices: Array(0 ..< 7), edges: arcs), "unindexed")
        }
    }
}
