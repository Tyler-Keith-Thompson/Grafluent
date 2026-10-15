// Kahn's topological sort as an event sequence (`kahnEvents`): a hand-traced DAG with a parallel
// copy and an isolated vertex on every representation, a cycle and a self-loop, the empty graph,
// value semantics, and a property test replaying the events against `topologicalGenerations()`.
// Case IDs (TR-nnn) refer to README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import StableGraphs
import Testing
import Traversal

/// A directed multigraph with no vertex indices.
private struct UnindexedDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Kahn events")
struct KahnEventsTests {
    @Test("TR-280 a DAG with a parallel copy and an isolated vertex: every event in order, on every representation", .tags(.fixture))
    func handTraced() {
        // 0→1, 0→2, 1→3, 2→3, 3→4, 1→3 again; 5 isolated.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4), (1, 3)]
        let edges = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected: [KahnEvent<Int, Int>] = [
            .ready(0), .ready(5),
            .emit(0), .removeEdge(0, inDegree: 0), .ready(1), .removeEdge(1, inDegree: 0), .ready(2),
            .emit(5),
            .emit(1), .removeEdge(2, inDegree: 2), .removeEdge(5, inDegree: 1),
            .emit(2), .removeEdge(3, inDegree: 0), .ready(3),
            .emit(3), .removeEdge(4, inDegree: 0), .ready(4),
            .emit(4),
        ]
        func check<G: DirectedGraph<Int>>(_ graph: G) where G.Edges.Index == Int {
            #expect(Array(graph.kahnEvents()) == expected, "\(G.self)")
            let emitted = graph.kahnEvents().compactMap { event -> Int? in if case .emit(let v) = event { v } else { nil } }
            #expect(emitted == graph.topologicalGenerations()?.flatMap { $0 }, "\(G.self)")
        }
        check(DirectedPseudograph(vertices: 0 ..< 6, edges: edges))
        check(ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: edges))
        check(UnindexedDigraph(vertices: Array(0 ..< 6), edges: edges))
        var stable = StableDirectedGraph(vertices: [99] + Array(0 ..< 6), edges: edges)
        stable.remove(99)
        check(stable)
        // Without the copy, on the simple representations: 3 waits for two edges.
        let simple = Array(edges.prefix(5))
        let simpleExpected: [KahnEvent<Int, Int>] = [
            .ready(0), .ready(5),
            .emit(0), .removeEdge(0, inDegree: 0), .ready(1), .removeEdge(1, inDegree: 0), .ready(2),
            .emit(5), .emit(1), .removeEdge(2, inDegree: 1), .emit(2), .removeEdge(3, inDegree: 0), .ready(3),
            .emit(3), .removeEdge(4, inDegree: 0), .ready(4), .emit(4),
        ]
        #expect(Array(AdjacencyList(vertices: 0 ..< 6, edges: simple).kahnEvents()) == simpleExpected)
        #expect(Array(CompressedSparseRow(vertexCount: 6, edges: simple).kahnEvents()) == simpleExpected)
        #expect(expected[3].description == "removeEdge(0, 0)" && expected[2].description == "emit(0)" && expected[0].description == "ready(0)")
    }

    @Test("TR-281 a cycle or a self-loop stops the sort short; no vertices: no events", .tags(.selfLoops))
    func cycles() {
        let cycle = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3)])
        #expect(Array(cycle.kahnEvents()) == [.ready(0), .emit(0), .removeEdge(0, inDegree: 1)])
        #expect(cycle.topologicalGenerations() == nil)
        let loop = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)])
        #expect(Array(loop.kahnEvents()).isEmpty)
        #expect(Array(AdjacencyList<Int>(vertices: []).kahnEvents()).isEmpty)
    }

    @Test("TR-282 value semantics: a later insertion does not change the events; each iterator starts over; stopping early; String vertices")
    func valueSemantics() {
        var graph = AdjacencyList(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let events = graph.kahnEvents()
        _ = graph.insert(edge: DirectedEdge(from: "b", to: "a"))
        let first = Array(events)
        #expect(first == [.ready("a"), .emit("a"), .removeEdge(0, inDegree: 0), .ready("b"), .emit("b")])
        #expect(Array(events) == first)
        #expect(Array(events.prefix(2)) == Array(first.prefix(2)))
        var iterator = events.makeIterator()
        for _ in first { _ = iterator.next() }
        #expect(iterator.next() == nil)
    }

    @Test("TR-283 property: the emitted order is topologicalGenerations() joined; every vertex ready once before it is emitted; in-degrees count down", .tags(.randomized))
    func property() async {
        // Up to 24 edges on vertices 0..<9; repeats and self-loops allowed. Half the time only
        // edges from a lower to a higher vertex, so most graphs are acyclic.
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: edges, Gen.bool) { raw, forward in
            let pairs = forward ? raw.filter { $0.0 < $0.1 } : raw
            let arcs = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
            func check<G: DirectedGraph<Int>>(_ graph: G, _ name: String) where G.Edges.Index == Int {
                var inDegree = [Int](repeating: 0, count: 9)
                for (_, v) in pairs { inDegree[v] += 1 }
                var ready = Set<Int>(), emitted: [Int] = []
                var current = -1
                for event in graph.kahnEvents() {
                    switch event {
                    case .ready(let v):
                        #expect(inDegree[v] == 0 && ready.insert(v).inserted, "\(name)")
                    case .emit(let v):
                        #expect(ready.contains(v) && !emitted.contains(v), "\(name)")
                        emitted.append(v)
                        current = v
                    case .removeEdge(let e, let d):
                        #expect(pairs[e].0 == current, "\(name)")
                        inDegree[pairs[e].1] -= 1
                        #expect(d == inDegree[pairs[e].1], "\(name)")
                    }
                }
                let generations = graph.topologicalGenerations()
                #expect((generations == nil) == (emitted.count < 9), "\(name)")
                if let generations { #expect(emitted == generations.flatMap { $0 }, "\(name)") }
            }
            check(DirectedPseudograph(vertices: 0 ..< 9, edges: arcs), "pseudograph")
            check(ReferenceDirectedMultigraph(vertices: 0 ..< 9, edges: arcs), "reference multigraph")
            check(UnindexedDigraph(vertices: Array(0 ..< 9), edges: arcs), "unindexed")
        }
    }
}
