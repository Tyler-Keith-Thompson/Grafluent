// Undirected networks whose capacities are near the capacity type's maximum: with one residual
// pair per edge the residual against a flow reaches c + f, up to 2c, which passes Int8.max for any
// capacity above 63. The results must be those of exact arithmetic (expected values from ref.py's
// models, which use Python integers), and nothing may trap while the capacities at each source sum
// within the type.

import AdjacencyListModule
import Flows
import GraphProtocols
import Testing

@Suite("Undirected Int8 capacities near the maximum")
struct UndirectedCapacityRangeTests {
    @Test("All four maximum flows on Int8 capacities where 2c overflows: value 120, the canonical cut, Edmonds–Karp's flow")
    func int8NearMaximum() {
        // Int8 undirected V [0, 1, 2, 3]; E [0–1 60, 0–2 60, 2–1 100, 2–3 120, 1–3 5], from 0 to 3.
        // Edge 2 carries 55 against its stored order, so its other residual would be 155.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1), (2, 3), (1, 3)]
        let capacities: [Int8] = [60, 60, 100, 120, 5]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })

        #expect(graph.maximumFlowValue(from: 0, to: 3) { capacities[$0] } == 120)
        let cut = graph.minimumCut(from: 0, to: 3) { capacities[$0] }
        #expect(cut.value == 120)
        #expect(Array(cut.sourceSide) == [0])
        #expect(Array(cut.sinkSide) == [1, 2, 3])
        #expect(cut.edges == [.init(position: 0, reversed: false), .init(position: 1, reversed: false)])

        let pinned = graph.edmondsKarpMaximumFlow(from: 0, to: 3) { capacities[$0] }
        #expect(pinned.value == 120)
        #expect(pinned.minimumCut == cut)
        // Signed flow along each edge's stored order: [60, 60, -55, 115, 5].
        let along = graph.edges.indices.map { pinned.flow(ofEdgeAt: .init(position: $0, reversed: false)) }
        let against = graph.edges.indices.map { pinned.flow(ofEdgeAt: .init(position: $0, reversed: true)) }
        #expect(along == [60, 60, 0, 115, 5])
        #expect(against == [0, 0, 55, 0, 0])

        for flow in [graph.maximumFlow(from: 0, to: 3) { capacities[$0] }, graph.dinicMaximumFlow(from: 0, to: 3) { capacities[$0] }] {
            #expect(flow.value == 120)
            #expect(flow.minimumCut == cut)
            // Capacity (at most one direction used, within c) and conservation, in Int.
            var balance = [0, 0, 0, 0]
            for e in graph.edges.indices {
                let a = flow.flow(ofEdgeAt: .init(position: e, reversed: false))
                let b = flow.flow(ofEdgeAt: .init(position: e, reversed: true))
                #expect(a == 0 || b == 0)
                #expect(a <= capacities[e] && b <= capacities[e] && a >= 0 && b >= 0)
                let f = Int(a) - Int(b)
                balance[pairs[e].0] -= f
                balance[pairs[e].1] += f
            }
            #expect(balance == [-120, 0, 0, 120])
        }
    }

    @Test("gomoryHuTree with Int8 capacities where 2c overflows: the path 0–1 100, 1–2 20")
    func int8GomoryHu() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let capacities: [Int8] = [100, 20]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.gomoryHuTree { capacities[$0] }!
        #expect(tree.tree.edges.map { [$0.u, $0.v] } == [[1, 0], [2, 1]])
        #expect(tree.capacity(ofEdgeAt: 0) == 100)
        #expect(tree.capacity(ofEdgeAt: 1) == 20)
        #expect(tree.minimumCutValue(between: 0, and: 2) == 20)
        let cut = tree.minimumCut(between: 0, and: 1)
        #expect(cut.value == 100)
        #expect(Array(cut.sourceSide) == [0])
        #expect(Array(cut.sinkSide) == [1, 2])
    }

    @Test("UInt8 undirected capacities near the maximum: 0–1 200 and 1–2 200 carry 200")
    func uint8NearMaximum() {
        let pairs: [(Int, Int)] = [(1, 0), (2, 1)]
        let capacities: [UInt8] = [200, 200]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let flow = graph.edmondsKarpMaximumFlow(from: 0, to: 2) { capacities[$0] }
        #expect(flow.value == 200)
        // Both edges are used against their stored order.
        #expect(graph.edges.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) } == [200, 200])
        #expect(graph.maximumFlow(from: 0, to: 2) { capacities[$0] }.value == 200)
        #expect(graph.dinicMaximumFlow(from: 0, to: 2) { capacities[$0] }.value == 200)
        let cut = graph.minimumCut(from: 0, to: 2) { capacities[$0] }
        #expect(cut.value == 200)
        #expect(Array(cut.sinkSide) == [2])
    }
}
