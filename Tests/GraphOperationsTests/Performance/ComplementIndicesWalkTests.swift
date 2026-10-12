// The complement view's edges.indices, split from GraphOperationsConformanceTests.swift because it
// relies on speed: each step starts from the current cell rather than rescanning the row, so every
// cell of n = 1500 is walked within a one-minute limit. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphOperations
import GraphProtocols
import Multigraphs
import ShortestPaths
import StableGraphs
import Testing
import Traversal

@Suite("GraphOperations complement indices at scale", .tags(.conformance))
struct ComplementIndicesWalkTests {
    @Test("Walking a complement's edges.indices steps from the current cell: every cell of n = 1500 in time", .timeLimit(.minutes(1)))
    func complementIndicesWalk() {
        // Before, index(after:) rescanned the row from its start, O(n) a step and O(n³) in all:
        // 800× iteration at n = 2000. Now one contains(edge:) per column passed.
        let n = 1500
        var rng = SeededRandomNumberGenerator(seed: 71)
        var arcs = Set<[Int]>()
        while arcs.count < 3 * n { arcs.insert([Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)]) }
        let base = CompressedSparseRow(vertexCount: n, edges: arcs.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let complement = base.complement
        var count = 0, previous: ComplementView<CompressedSparseRow>.Cell?
        var sources = 0, ascending = true
        for cell in complement.edges.indices {
            if let previous, !(previous < cell) { ascending = false }
            previous = cell
            count += 1
            sources &+= cell.source
        }
        #expect(ascending)
        #expect(count == complement.edgeCount && count == n * (n - 1) - arcs.filter { $0[0] != $0[1] }.count)
        #expect(sources == complement.edges.reduce(0) { $0 &+ $1.source })

        var pairs = Set<[Int]>()
        while pairs.count < 3 * n {
            let a = Int.random(in: 0 ..< n, using: &rng), b = Int.random(in: 0 ..< n, using: &rng)
            if a != b { pairs.insert([Swift.min(a, b), Swift.max(a, b)]) }
        }
        let undirected = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0[0], $0[1]) })
        var cells = 0, upper = true
        var last: ComplementView<UndirectedAdjacencyList<Int>>.Cell?
        for cell in undirected.complement.edges.indices {
            if cell.source >= cell.target { upper = false }
            if let last, !(last < cell) { upper = false }
            last = cell
            cells += 1
        }
        #expect(upper)
        #expect(cells == undirected.complement.edgeCount && cells == n * (n - 1) / 2 - pairs.count)
    }
}
