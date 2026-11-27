//
//  ParallelCentralityPreconditionTests.swift
//  Grafluent
//
//  The parallel measures' preconditions, as exit tests: parallelism must be positive, and weights
//  in the weighted measure must be positive.
//

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import ParallelCentrality
import Testing

@Suite struct ParallelCentralityPreconditionTests {
    @Test("PC-7 zero or negative parallelism traps", .tags(.precondition))
    func parallelismTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = await graph.betweennessCentrality(parallelism: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = await graph.closenessCentrality(parallelism: -1)
        }
    }

    @Test("PC-8 a weight of zero traps in the weighted parallel measure", .tags(.precondition))
    func zeroWeightTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = await graph.betweennessCentrality(weight: { _ in 0 }, parallelism: 2)
        }
    }
}
