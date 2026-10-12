// Flows on StableDirectedGraph with holes: edge holes only (vertex indices kept, edge positions
// numbered through an array sized by the bound), vertex holes, and both. Each value and minimum cut
// is compared with the compacting DirectedPseudograph(g), whose edge k is the graph's kth live
// position, capacities read by position. See README.md.

import Flows
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing

@Suite("Flows on StableDirectedGraph with holes")
struct FlowsStableGraphTests {
    @Test("flow(checkedEdgeAt:) throws for a position past the end, a negative one or a removed edge's, with and without edge holes")
    func checkedFlowPositions() throws {
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 3)
        for (a, b) in [(0, 1), (1, 2), (0, 2)] { graph.insert(edge: DirectedEdge(from: a, to: b)) }
        // Edge indices: StableDirectedGraph.edgeIndex(of:) traps on a position out of range, so
        // the checked spelling must test the range first.
        #expect(graph.edgeIndexBound == 3)
        let flow = graph.maximumFlow(from: 0, to: 2, capacity: { $0 + 1 })
        for bad in [3, 99, -1] { #expect(throws: EdgeNotFound()) { try flow.flow(checkedEdgeAt: bad) } }
        #expect(try (0 ..< 3).map { try flow.flow(checkedEdgeAt: $0) } == (0 ..< 3).map { flow.flow(ofEdgeAt: $0) })
        // An edge hole: no edge indices, so positions are searched; the removed one is not found.
        var holed = graph
        holed.remove(edgeAt: 1)
        #expect(holed.edgeIndexBound == nil)
        let holedFlow = holed.maximumFlow(from: 0, to: 2, capacity: { $0 + 1 })
        for bad in [1, 3, -1] { #expect(throws: EdgeNotFound()) { try holedFlow.flow(checkedEdgeAt: bad) } }
        #expect(try holedFlow.flow(checkedEdgeAt: 0) == 0 && holedFlow.flow(checkedEdgeAt: 2) == 3)
    }

    @Test("Maximum flow with edge holes only, vertex holes, or both equals the compacted copy's, positions mapped", arguments: [1, 2, 3, 4, 5])
    func maximumFlowWithHoles(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 12
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< n)
        for _ in 0 ..< n * 4 {
            graph.insert(edge: DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)))
        }
        var edgeHoles = graph
        for p in Array(edgeHoles.edges.indices) where Int.random(in: 0 ..< 3, using: &rng) == 0 { edgeHoles.remove(edgeAt: p) }
        var vertexHoles = graph
        vertexHoles.remove(5)
        var both = edgeHoles
        both.remove(6)
        #expect(edgeHoles.vertexIndexBound == n && edgeHoles.edgeIndexBound == nil)
        #expect(vertexHoles.vertexIndexBound == nil && both.vertexIndexBound == nil && both.edgeIndexBound == nil)
        let capacity = (0 ..< graph.edges.endIndex).map { ($0 &* 7) % 5 + 1 }
        for g in [graph, edgeHoles, vertexHoles, both] {
            let compacted = DirectedPseudograph<Int>(g)
            let positions = Array(g.edges.indices)
            for (s, t) in [(0, n - 1), (1, 2), (3, 0)] {
                let flow = g.maximumFlow(from: s, to: t, capacity: { capacity[$0] })
                let copy = compacted.maximumFlow(from: s, to: t, capacity: { capacity[positions[$0]] })
                #expect(flow.value == copy.value)
                #expect(Array(flow.minimumCut.sourceSide) == Array(copy.minimumCut.sourceSide))
                #expect(flow.minimumCut.edges == copy.minimumCut.edges.map { positions[$0] })
            }
        }
    }
}
