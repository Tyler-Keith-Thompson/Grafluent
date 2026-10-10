// Inputs found by planted-bug (mutation) testing and by fuzzing (`FuzzTours`), each pinning a rule
// no catalog row isolates. Expected values are worked out in each test's comments. See README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

@Suite("Tours regressions")
struct ToursRegressionTests {
    @Test("Directed: one vertex with out − in = 1 and one with in − out = 1 is not enough when another is unbalanced by 2")
    func directedTrailNeedsTheRestBalanced() {
        // Edges 0→2, 2→3, 2→3, 2→1: out − in is +1 at 0, −1 at 1, +2 at 2, −2 at 3. Every vertex is
        // reached from 0, so only the balance rule says no.
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 1),
        ])
        #expect(!graph.hasEulerianTrail)
        #expect(!graph.isEulerian)
        #expect(graph.eulerianTrail() == nil)
        #expect(graph.eulerianTrail(from: 0) == nil)
    }

    @Test("Directed: a trail is found from its start even when the first vertex with an edge reaches nothing")
    func directedTrailReachedFromItsStart() throws {
        // 1→0: vertex 0 comes first and has an edge, but no out-edge; the trail starts at 1.
        let graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 1, to: 0)])
        #expect(graph.hasEulerianTrail)
        #expect(!graph.isEulerian)
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [1, 0] && trail.edges == [0])
        // The same on a longer one: 2→1→0 with 0 first.
        let path = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1)])
        #expect(path.hasEulerianTrail)
        let walk = try #require(path.eulerianTrail())
        #expect(walk.vertices == [2, 1, 0] && walk.edges == [1, 0])
    }

    @Test("FuzzTours: Hierholzer on edges in two components stops cleanly (it read before its edge buffer when the walk ended early)")
    func hierholzerMissingEdges() {
        // Self-loops at two vertices: each is even (balanced), but the edges are not connected.
        // The walk from vertex 0 takes its two loops and ends with edges left; the last pop used
        // to copy the edge below the bottom of the stack.
        let directed = DirectedPseudograph<Int>(vertices: [1, 0], edges: [
            DirectedEdge(from: 0, to: 0), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 0),
        ])
        #expect(!directed.isEulerian && !directed.hasEulerianTrail)
        #expect(directed.eulerianCircuit() == nil && directed.eulerianTrail() == nil)
        #expect(directed.eulerianCircuit(from: 0) == nil && directed.eulerianTrail(from: 0) == nil)
        let undirected = Pseudograph<Int>(vertices: [1, 0], edges: [
            UndirectedEdge(0, 0), UndirectedEdge(1, 1), UndirectedEdge(1, 1), UndirectedEdge(0, 0),
        ])
        #expect(!undirected.isEulerian && !undirected.hasEulerianTrail)
        #expect(undirected.eulerianCircuit() == nil && undirected.eulerianTrail() == nil)
        #expect(undirected.eulerianCircuit(from: 0) == nil && undirected.eulerianTrail(from: 0) == nil)
    }
}
