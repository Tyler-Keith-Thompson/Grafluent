// Dinic with dynamic trees against the plain Dinic on the network the trees are for, directed and
// undirected: a chain of 10⁴ arcs fanning out to 10⁴ unit paths into the sink. Every augmenting
// path runs the whole chain, so the plain blocking flow spends the chain's length on each of the 10⁴ augmentations,
// and the trees O(log n). Bounded at a quarter of the plain Dinic's time. The two sides are timed
// in alternating rounds, each keeping its fastest of five, and the comparison is retried up to
// three times while it looks slow. The timing runs only in an optimized build; a debug build
// checks that both agree.

import AdjacencyListModule
import Flows
import GraphProtocols
import Testing

@Suite("Dinic with dynamic trees against Dinic")
struct DinicDynamicTreesRatioTests {
    @Test("A chain of 10⁴ arcs fanning out to 10⁴ unit paths: the dynamic trees within 0.25× the plain Dinic's time", .timeLimit(.minutes(2)))
    func chainAndFan() async {
        await Task {
            let length = 10_000, width = 10_000
            let sink = length + width + 1
            var edges = (0 ..< length).map { DirectedEdge(from: $0, to: $0 + 1) }
            for j in 0 ..< width {
                edges.append(DirectedEdge(from: length, to: length + 1 + j))
                edges.append(DirectedEdge(from: length + 1 + j, to: sink))
            }
            let graph = AdjacencyList(vertices: 0 ... sink, edges: edges)
            let capacities = (0 ..< edges.count).map { $0 < length ? width : 1 }
            let plain = graph.dinicMaximumFlow(from: 0, to: sink) { capacities[$0] }
            let trees = graph.dinicMaximumFlow(from: 0, to: sink, dynamicTrees: true) { capacities[$0] }
            #expect(plain.value == width && trees.value == width)
            #expect(plain.minimumCut == trees.minimumCut)
            #if !DEBUG
            func seconds(_ body: () -> Int) -> Double {
                let start = ContinuousClock.now
                let value = body()
                let elapsed = ContinuousClock.now - start
                precondition(value == width)
                return Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) * 1e-18
            }
            var ratio = Double.infinity
            for _ in 0 ..< 3 where ratio > 0.25 {
                var bestPlain = Double.infinity, bestTrees = Double.infinity
                for _ in 0 ..< 5 {
                    bestPlain = min(bestPlain, seconds { graph.dinicMaximumFlow(from: 0, to: sink) { capacities[$0] }.value })
                    bestTrees = min(bestTrees, seconds { graph.dinicMaximumFlow(from: 0, to: sink, dynamicTrees: true) { capacities[$0] }.value })
                }
                ratio = bestTrees / bestPlain
            }
            #expect(ratio <= 0.25, "dynamic trees / plain = \(ratio)")
            #endif
        }.value
    }

    @Test("The same network undirected: the dynamic trees within 0.25× the plain Dinic's time", .timeLimit(.minutes(2)))
    func undirectedChainAndFan() async {
        await Task {
            let length = 10_000, width = 10_000
            let sink = length + width + 1
            var edges = (0 ..< length).map { UndirectedEdge($0, $0 + 1) }
            for j in 0 ..< width {
                edges.append(UndirectedEdge(length, length + 1 + j))
                edges.append(UndirectedEdge(length + 1 + j, sink))
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ... sink, edges: edges)
            let capacities = (0 ..< edges.count).map { $0 < length ? width : 1 }
            let plain = graph.dinicMaximumFlow(from: 0, to: sink) { capacities[$0] }
            let trees = graph.dinicMaximumFlow(from: 0, to: sink, dynamicTrees: true) { capacities[$0] }
            #expect(plain.value == width && trees.value == width)
            #expect(plain.minimumCut == trees.minimumCut)
            #if !DEBUG
            func seconds(_ body: () -> Int) -> Double {
                let start = ContinuousClock.now
                let value = body()
                let elapsed = ContinuousClock.now - start
                precondition(value == width)
                return Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) * 1e-18
            }
            var ratio = Double.infinity
            for _ in 0 ..< 3 where ratio > 0.25 {
                var bestPlain = Double.infinity, bestTrees = Double.infinity
                for _ in 0 ..< 5 {
                    bestPlain = min(bestPlain, seconds { graph.dinicMaximumFlow(from: 0, to: sink) { capacities[$0] }.value })
                    bestTrees = min(bestTrees, seconds { graph.dinicMaximumFlow(from: 0, to: sink, dynamicTrees: true) { capacities[$0] }.value })
                }
                ratio = bestTrees / bestPlain
            }
            #expect(ratio <= 0.25, "dynamic trees / plain = \(ratio)")
            #endif
        }.value
    }
}
