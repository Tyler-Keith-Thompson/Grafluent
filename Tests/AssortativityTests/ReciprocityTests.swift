// Reciprocity on the simple digraph underneath: self-loops ignored, parallel arcs once. Overall:
// reciprocated arcs over arcs. Per vertex: 2|N⁺ ∩ N⁻| / (|N⁺| + |N⁻|) over distinct neighbors
// other than the vertex. The six-arc digraph's values agree with NetworkX 3.7.

import AdjacencyListModule
import Assortativity
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

/// A bidirectional digraph with no vertex indices, its vertices listed out of value order.
private struct UnindexedBidirectional: BidirectionalDirectedGraph {
    let vertices: [String]
    let edges: [DirectedEdge<String>]
    func successors(of vertex: String) -> [String] { outEdges(of: vertex).map { edges[$0].target } }
    func predecessors(of vertex: String) -> [String] { inEdges(of: vertex).map { edges[$0].source } }
    func outEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func inEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].target == vertex } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("Reciprocity")
struct ReciprocityTests {
    @Test("The six-arc digraph: 4 of 6 arcs reciprocated; vertices 2/3, 0, 4/5, 1")
    func sixArcs() throws {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)])
        #expect(try #require(graph.reciprocity()) == 4.0 / 6.0)
        #expect(graph.reciprocity(of: 0) == 2.0 / 3.0)
        #expect(graph.reciprocity(of: 1) == 0)
        #expect(graph.reciprocity(of: 2) == 0.8)
        #expect(graph.reciprocity(of: 3) == 1)
    }

    @Test("No arcs between distinct vertices: nil overall; an isolated vertex: nil")
    func undefined() {
        #expect(AdjacencyList<Int>().reciprocity() == nil)
        #expect(AdjacencyList(vertices: 0 ..< 3, edges: []).reciprocity() == nil)
        let loops = AdjacencyList(edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 1, to: 1)])
        #expect(loops.reciprocity() == nil)
        #expect(loops.reciprocity(of: 0) == nil)
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.reciprocity(of: 2) == nil)
        #expect(graph.reciprocity(of: 0) == 0)
    }

    @Test("Self-loops change nothing, overall or per vertex")
    func selfLoops() {
        let plain = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2)])
        let looped = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 2, to: 2)])
        #expect(plain.reciprocity() == 2.0 / 3.0)
        #expect(looped.reciprocity() == plain.reciprocity())
        for v in 0 ..< 3 { #expect(looped.reciprocity(of: v) == plain.reciprocity(of: v)) }
        #expect(looped.reciprocity(of: 1) == 2.0 * 1 / 3)
    }

    @Test("Parallel arcs count once")
    func parallelArcs() {
        let graph = DirectedPseudograph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2)])
        // Distinct arcs 0→1, 1→0, 1→2: two of three reciprocated.
        #expect(graph.reciprocity() == 2.0 / 3.0)
        #expect(graph.reciprocity(of: 0) == 1)
        #expect(graph.reciprocity(of: 1) == 2.0 / 3.0)
        #expect(graph.reciprocity(of: 2) == 0)
    }

    @Test("A complete digraph is fully reciprocal; a tournament not at all")
    func extremes() {
        var both: [DirectedEdge<Int>] = [], one: [DirectedEdge<Int>] = []
        for u in 0 ..< 5 {
            for v in 0 ..< 5 where u != v {
                both.append(DirectedEdge(from: u, to: v))
                if u < v { one.append(DirectedEdge(from: u, to: v)) }
            }
        }
        let complete = AdjacencyList(edges: both), tournament = AdjacencyList(edges: one)
        #expect(complete.reciprocity() == 1)
        #expect(tournament.reciprocity() == 0)
        for v in 0 ..< 5 {
            #expect(complete.reciprocity(of: v) == 1)
            #expect(tournament.reciprocity(of: v) == 0)
        }
    }

    @Test("Per vertex on a graph without vertex indices")
    func unindexed() {
        let graph = UnindexedBidirectional(vertices: ["c", "b", "a"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "a", to: "a")])
        #expect(graph.reciprocity(of: "a") == 2.0 * 1 / 3)
        #expect(graph.reciprocity(of: "b") == 1)
        #expect(graph.reciprocity(of: "c") == 0)
        #expect(graph.reciprocity() == 2.0 / 3.0)
    }
}
