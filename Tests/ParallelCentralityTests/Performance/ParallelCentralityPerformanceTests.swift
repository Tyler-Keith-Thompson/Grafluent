//
//  ParallelCentralityPerformanceTests.swift
//  Grafluent
//
//  The parallel measures must not fall behind the sequential ones: with the searches shared among
//  tasks, the wall-clock time is bounded by the sequential time plus the cost of the shares'
//  scratch arrays and the final sum.
//

import AdjacencyListModule
import Centrality
import GrafluentTestSupport
import GraphProtocols
import ParallelCentrality
import Testing

@Suite struct ParallelCentralityPerformanceTests {
    @Test("Betweenness and closeness at four tasks take at most twice the sequential time on a random graph", .timeLimit(.minutes(2)))
    func parallelKeepsPace() async {
        #if DEBUG
        let n = 400, m = 1_600
        #else
        let n = 3_000, m = 15_000
        #endif
        var generator = SeededRandomNumberGenerator(seed: 11)
        var edges: [DirectedEdge<Int>] = []
        edges.reserveCapacity(m)
        for _ in 0 ..< m { edges.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator))) }
        let graph = AdjacencyList<Int>(vertices: 0 ..< n, edges: edges)

        let clock = ContinuousClock()
        _ = graph.betweennessCentrality()
        let sequential = clock.measure { _ = graph.betweennessCentrality() }
        _ = await graph.betweennessCentrality(parallelism: 4)
        let start = clock.now
        _ = await graph.betweennessCentrality(parallelism: 4)
        let parallel = clock.now - start
        #expect(parallel <= sequential * 2, "parallel \(parallel), sequential \(sequential)")

        let sequentialCloseness = clock.measure { _ = graph.closenessCentrality() }
        let startCloseness = clock.now
        _ = await graph.closenessCentrality(parallelism: 4)
        let parallelCloseness = clock.now - startCloseness
        #expect(parallelCloseness <= sequentialCloseness * 2, "parallel \(parallelCloseness), sequential \(sequentialCloseness)")
    }
}
