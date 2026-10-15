// Bellman–Ford as an event sequence (`lazy.bellmanFord`): a hand-traced graph with a negative
// edge, a reachable negative cycle and its witness, several sources, and a property test against
// `bellmanFordShortestPaths` and `findNegativeCycle`. Case IDs (SP-nn) refer to the catalog; see
// README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import ShortestPaths
import Testing
import Walks

@Suite("Bellman–Ford search events")
struct BellmanFordSearchTests {
    @Test("SP-210 a hand-traced graph with a negative edge: every round, examination and relaxation in order", .tags(.fixture))
    func handTraced() {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 1)]
        let weights = [4, 1, 1, -2]
        let graph = CompressedSparseRow(vertexCount: 4, edges: edges)
        let expected: [BellmanFordEvent<Int, Int, Int>] = [
            .round(1), .examine(0, distance: 0), .edgeRelaxed(0, distance: 4), .edgeRelaxed(1, distance: 1),
            .round(2), .examine(1, distance: 4), .edgeRelaxed(2, distance: 5), .examine(2, distance: 1), .edgeRelaxed(3, distance: -1),
            .round(3), .examine(3, distance: 5), .examine(1, distance: -1), .edgeRelaxed(2, distance: 0),
            .round(4), .examine(3, distance: 0),
        ]
        let events = Array(graph.lazy.bellmanFord(from: 0) { weights[$0] })
        #expect(events == expected)
        #expect(events.map(\.description).prefix(3) == ["round(1)", "examine(0, 0)", "edgeRelaxed(0, 4)"])
        // Over an AdjacencyList, weighed by endpoints: the same examinations.
        let byEndpoints = Dictionary(uniqueKeysWithValues: zip(edges, weights))
        let list = AdjacencyList(vertices: 0 ..< 4, edges: edges)
        let examined = list.lazy.bellmanFord(from: 0) { byEndpoints[list.edges[$0]]! }.compactMap { event -> String? in
            if case .examine(let v, let d) = event { "\(v):\(d)" } else { nil }
        }
        #expect(examined == ["0:0", "1:4", "2:1", "3:5", "1:-1", "3:0"])
        // Iterating again gives the same events.
        let search = graph.lazy.bellmanFord(from: 0) { weights[$0] }
        #expect(Array(search) == Array(search))
    }

    @Test("SP-211 a reachable negative cycle: the vertex count's rounds, then the cycle findNegativeCycle gives; an unreachable one is not reported")
    func negativeCycle() {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 3)]
        let weights = [1, -3, 1, -1]
        let graph = CompressedSparseRow(vertexCount: 4, edges: edges)
        let events = Array(graph.lazy.bellmanFord(from: 0) { weights[$0] })
        #expect(events.filter { if case .round = $0 { true } else { false } }.count == 4)
        guard case .negativeCycle(let cycle)? = events.last else {
            Issue.record("no negative cycle reported")
            return
        }
        #expect(cycle.vertices == [1, 2])
        #expect(cycle.edges == [1, 2])
        #expect(cycle == graph.findNegativeCycle(from: 0) { weights[$0] })
        // From 2 the cycle is reachable too; from 3 only its own negative loop is.
        #expect(Array(graph.lazy.bellmanFord(from: 3) { weights[$0] }).last == .negativeCycle(graph.findNegativeCycle(from: 3) { weights[$0] }!))
        let free = Array(graph.lazy.bellmanFord(from: 0) { max(weights[$0], 0) })
        #expect(!free.contains { if case .negativeCycle = $0 { true } else { false } })
    }

    @Test("SP-212 several sources share the first round at distance zero; a repeated source is ignored")
    func severalSources() {
        let graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        let weights = [5, -1]
        #expect(Array(graph.lazy.bellmanFord(from: [1, 0, 1]) { weights[$0] }) == [
            .round(1), .examine(1, distance: 0), .edgeRelaxed(1, distance: -1), .examine(0, distance: 0), .edgeNotRelaxed(0, distance: -1),
            .round(2), .examine(2, distance: -1),
        ])
    }

    @Test("SP-213 property (PropertyBased): replayed, the events give bellmanFordShortestPaths' distances, or findNegativeCycle's cycle", .tags(.randomized))
    func property() async {
        // Up to 20 edges on vertices 0..<6 with weights -2...6; repeats and self-loops allowed.
        let raw = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: -2 ... 6)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: raw, Gen.int(in: 0 ... 5)) { raw, source in
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let weight = { (p: Int) in raw[p].2 }
            var distance: [Int: Int] = [source: 0]
            var cycle: Cycle<Int, Int>?
            var examined = 0
            for event in graph.lazy.bellmanFord(from: source, weight: weight) {
                switch event {
                case .examine(let v, let d):
                    #expect(distance[v] == d)
                    examined += 1
                case .edgeRelaxed(let e, let d):
                    #expect(distance[graph.edges[e].target].map { d < $0 } ?? true)
                    distance[graph.edges[e].target] = d
                case .edgeNotRelaxed(let e, let d):
                    #expect(distance[graph.edges[e].target] == d)
                case .negativeCycle(let c): cycle = c
                case .round: break
                }
            }
            #expect(examined > 0)
            if let tree = graph.bellmanFordShortestPaths(from: source, weight: weight) {
                #expect(cycle == nil)
                for v in 0 ..< 6 { #expect(distance[v] == tree.distance(to: v), "vertex \(v)") }
            } else {
                #expect(cycle != nil && cycle == graph.findNegativeCycle(from: source, weight: weight))
            }
        }
    }
}
