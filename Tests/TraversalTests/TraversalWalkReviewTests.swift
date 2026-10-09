// Cases added after the critical review of Walks: findCycle and bidirectionalShortestPath on a
// conformer without vertex indices (the lookup path), on a multigraph with parallel edges, and
// through the directed view of an undirected graph with a self-loop; each result is checked as a
// cycle or path of its graph. Case IDs (WK-nn) refer to the Walks catalog; see
// Tests/WalksTests/README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal
import Walks

/// A bidirectional multigraph with no vertex indices: edges in written order.
private struct PlainBidirectionalGraph: BidirectionalDirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func inEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].target == vertex } }
    func successors(of vertex: Int) -> [Int] { outEdges(of: vertex).map { edges[$0].target } }
    func predecessors(of vertex: Int) -> [Int] { inEdges(of: vertex).map { edges[$0].source } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

@Suite("Traversal walks: review cases")
struct TraversalWalkReviewTests {
    @Test("WK-1216 findCycle without vertex indices, with parallel edges and a self-loop: a cycle of the graph, its edges the first of each step")
    func findCycleWithoutIndices() {
        // 0⇉1 (edges 0 and 1), 1→2, 2→0, and a loop at 3 reached after the triangle.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 3, to: 3)]
        let graph = PlainBidirectionalGraph(vertices: [0, 1, 2, 3], edges: edges)
        #expect(graph.vertexIndexBound == nil)
        let cycle = graph.findCycle()
        #expect(cycle?.vertices == [0, 1, 2])
        #expect(cycle?.edges == [0, 2, 3])
        #expect(cycle.map { Cycle(vertices: $0.vertices, edges: $0.edges, in: graph) != nil } == true)
        let loop = graph.findCycle(from: [3])
        #expect(loop?.vertices == [3] && loop?.edges == [4])
    }

    @Test("WK-1217 bidirectionalShortestPath with backward steps over parallel edges is a path of the graph, with or without vertex indices")
    func bidirectionalWithParallelEdges() {
        // 0→1→2→3→4 with the last two steps doubled, and three dead ends 0→5, 0→6, 0→7 so the
        // forward frontier is wider: the backward search then expands from 4 and meets the forward
        // one at 1, so the steps 1→2→3→4 are all found backward, over in-edges.
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 3, to: 4),
                     DirectedEdge(from: 0, to: 5), DirectedEdge(from: 0, to: 6), DirectedEdge(from: 0, to: 7)]
        let plain = PlainBidirectionalGraph(vertices: Array(0 ... 7), edges: edges)
        let indexed = ReferenceDirectedMultigraph(vertices: 0 ... 7, edges: edges)
        for (path, name) in [(plain.bidirectionalShortestPath(from: 0, to: 4), "plain"), (indexed.bidirectionalShortestPath(from: 0, to: 4), "indexed")] {
            #expect(path?.vertices == [0, 1, 2, 3, 4], "\(name)")
            #expect(path?.length == 4, "\(name)")
            #expect(path.map { Path(vertices: $0.vertices, edges: $0.edges, in: plain) != nil } == true, "\(name)")
        }
        #expect(indexed.bidirectionalShortestPath(from: 4, to: 0) == nil)
        #expect(plain.bidirectionalShortestPath(from: 2, to: 2)?.vertices == [2])
    }

    @Test("WK-1218 findCycle on a multigraph with parallel edges and vertex indices names edges of the graph", .tags(.randomized), arguments: 0 ..< 6)
    func findCycleOnIndexedMultigraph(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(1218 + seed))
        for _ in 0 ..< 40 {
            let n = Int.random(in: 1 ... 7, using: &rng)
            var edges: [DirectedEdge<Int>] = []
            for _ in 0 ..< Int.random(in: 0 ... 12, using: &rng) {
                let e = DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng))
                edges.append(e)
                if Bool.random(using: &rng) { edges.append(e) }
            }
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: edges)
            let plain = PlainBidirectionalGraph(vertices: Array(0 ..< n), edges: edges)
            let cycle = graph.findCycle()
            #expect((cycle == nil) == graph.isAcyclic, "\(edges)")
            if let cycle {
                #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil, "\(edges): \(cycle)")
                // The lookup path finds the same cycle with the same edges.
                #expect(plain.findCycle()?.vertices == cycle.vertices && plain.findCycle()?.edges == cycle.edges, "\(edges)")
            }
        }
    }

    @Test("WK-1219 findCycle through the directed view of an undirected graph with a self-loop is the loop's forward arc")
    func findCycleThroughDirectedView() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 0)])
        let view = graph.directed
        let cycle = view.findCycle()
        #expect(cycle?.vertices == [0])
        #expect(cycle.map { Cycle(vertices: $0.vertices, edges: $0.edges, in: view) != nil } == true)
        #expect(cycle?.edges.first?.position == 0)
    }
}
