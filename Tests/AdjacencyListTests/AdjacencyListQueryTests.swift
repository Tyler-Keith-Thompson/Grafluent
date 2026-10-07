// Queries: membership, neighborhoods, degrees, counts. Case IDs (Q-nn, D-nn) refer to the
// harvested test catalog.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList queries")
struct AdjacencyListQueryTests {
    @Test("Q-01 contains(vertex)")
    func containsVertex() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        #expect(graph.contains(1))
        #expect(!graph.contains(4))
        #expect(!AdjacencyList<Int>().contains(0))
    }

    @Test("Q-02 contains(edge) respects direction")
    func containsEdgeIsDirectional() {
        // JGraphT SimpleDirectedGraphTest g4.
        let graph = AdjacencyList(edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 1)])
        #expect(graph.contains(DirectedEdge(from: 1, to: 2)))
        #expect(!graph.contains(DirectedEdge(from: 2, to: 1)))
        #expect(!graph.contains(DirectedEdge(from: 1, to: 4)))
        #expect(graph.contains(DirectedEdge(from: 4, to: 1)))
        #expect(!graph.contains(DirectedEdge(from: 1, to: 1)))
    }

    @Test("Q-03 contains(edge) with an absent endpoint is false")
    func containsEdgeWithAbsentEndpoint() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 5, to: 3), DirectedEdge(from: 1, to: 0)])
        #expect(!graph.contains(DirectedEdge(from: 0, to: -1)))
        #expect(!graph.contains(DirectedEdge(from: -1, to: 0)))
        #expect(!graph.contains(DirectedEdge(from: -1, to: -1)))
        #expect(!AdjacencyList<Int>().contains(DirectedEdge(from: 0, to: 0)))
    }

    @Test("Q-05 / Q-07 / Q-10 neighborhoods and degrees of every fixture", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func fixtureQueries(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for v in fixture.vertexSet {
            let out = Array(graph.successors(of: v))
            let into = Array(graph.predecessors(of: v))
            #expect(Set(out) == Set(fixture.edgeSet.filter { $0.source == v }.map(\.target)), "successors(of: \(v))")
            #expect(Set(into) == Set(fixture.edgeSet.filter { $0.target == v }.map(\.source)), "predecessors(of: \(v))")
            #expect(out.count == fixture.outDegree[v], "successors(of: \(v)) repeats a vertex")
            #expect(into.count == fixture.inDegree[v], "predecessors(of: \(v)) repeats a vertex")
            #expect(graph.outDegree(of: v) == fixture.outDegree[v], "outDegree(of: \(v))")
            #expect(graph.inDegree(of: v) == fixture.inDegree[v], "inDegree(of: \(v))")
            #expect(graph.degree(of: v) == fixture.outDegree[v]! + fixture.inDegree[v]!, "degree(of: \(v))")
        }
    }

    @Test("Q-05 Boost.Graph house DAG: exact neighborhoods")
    func houseNeighborhoods() {
        // Boost.Graph test/test_direction.hpp.
        let graph = AdjacencyList(edges: [
            DirectedEdge(from: 5, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0),
        ])
        #expect([0, 1, 2, 3, 4, 5].map(graph.outDegree(of:)) == [0, 1, 1, 2, 2, 1])
        #expect([0, 1, 2, 3, 4, 5].map(graph.inDegree(of:)) == [2, 2, 1, 1, 1, 0])
        #expect(Array(graph.successors(of: 1)) == [0])
        #expect(Array(graph.successors(of: 2)) == [1])
        #expect(Array(graph.successors(of: 5)) == [3])
        #expect(Array(graph.predecessors(of: 2)) == [3])
        #expect(Array(graph.predecessors(of: 3)) == [5])
        #expect(Array(graph.predecessors(of: 4)) == [3])
        #expect(graph.successors(of: 0).isEmpty)
        #expect(graph.predecessors(of: 5).isEmpty)
    }

    @Test("Q-07 NetworkX ABCD: out- and in-neighbors")
    func abcdNeighborhoods() {
        // NetworkX test_digraph_historical.py.
        let graph = AdjacencyList(
            vertices: ["G", "J", "K"],
            edges: [DirectedEdge(from: "A", to: "B"), DirectedEdge(from: "A", to: "C"), DirectedEdge(from: "B", to: "D"), DirectedEdge(from: "B", to: "C"), DirectedEdge(from: "C", to: "D")]
        )
        #expect(graph.vertexCount == 7)
        #expect(graph.edgeCount == 5)
        #expect(Set(graph.successors(of: "A")) == ["B", "C"])
        #expect(Set(graph.successors(of: "C")) == ["D"])
        #expect(Set(graph.predecessors(of: "C")) == ["A", "B"])
        #expect(graph.predecessors(of: "A").isEmpty)
        #expect(graph.successors(of: "G").isEmpty)
        #expect(["A", "B", "C", "D", "G", "J", "K"].map(graph.inDegree(of:)) == [0, 1, 2, 2, 0, 0, 0])
        #expect(["A", "B", "C", "D", "G", "J", "K"].map(graph.outDegree(of:)) == [2, 2, 1, 0, 0, 0, 0])
    }

    @Test("Q-22 sources and sinks")
    func sourcesAndSinks() {
        // The Boost.Graph house DAG has one source, 5, and one sink, 0.
        let graph = AdjacencyList(edges: [
            DirectedEdge(from: 5, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0),
        ])
        #expect(graph.vertices.filter { graph.inDegree(of: $0) == 0 } == [5])
        #expect(graph.vertices.filter { graph.outDegree(of: $0) == 0 } == [0])
    }

    // MARK: Counting identities

    @Test("Σ outDegree = Σ inDegree = edgeCount, and Σ degree = 2 · edgeCount", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func degreeSums(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        #expect(graph.vertices.map(graph.outDegree(of:)).reduce(0, +) == graph.edgeCount)
        #expect(graph.vertices.map(graph.inDegree(of:)).reduce(0, +) == graph.edgeCount)
        #expect(graph.vertices.map(graph.degree(of:)).reduce(0, +) == 2 * graph.edgeCount)
    }

    @Test("Q-19 vertexCount and edgeCount agree with the views", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func countsAgreeWithViews(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        #expect(graph.vertexCount == graph.vertices.count)
        #expect(graph.vertexCount == Set(graph.vertices).count, "`vertices` repeats a vertex")
        #expect(graph.edgeCount == graph.edges.count)
        #expect(graph.edgeCount == Set(graph.edges).count, "`edges` repeats an edge")
        #expect(graph.edgeCount == graph.vertices.map { graph.successors(of: $0).count }.reduce(0, +))
    }

    @Test("D-02 out- and in-adjacency mirror each other, and both agree with `edges`", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func adjacencyMirrors(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        var fromOut: Set<DirectedEdge<Int>> = []
        var fromIn: Set<DirectedEdge<Int>> = []
        for v in graph.vertices {
            for w in graph.successors(of: v) { fromOut.insert(DirectedEdge(from: v, to: w)) }
            for u in graph.predecessors(of: v) { fromIn.insert(DirectedEdge(from: u, to: v)) }
        }
        #expect(fromOut == Set(graph.edges))
        #expect(fromIn == Set(graph.edges))
        for edge in graph.edges {
            #expect(graph.contains(edge))
            #expect(graph.contains(edge.source))
            #expect(graph.contains(edge.target))
            #expect(graph.successors(of: edge.source).contains(edge.target))
            #expect(graph.predecessors(of: edge.target).contains(edge.source))
        }
    }

    // MARK: SelfLoops

    @Test("Q-13 a self-loop contributes 1 to outDegree, 1 to inDegree, 2 to degree, and 1 to edgeCount", .tags(.selfLoops))
    func selfLoopDegree() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 0)])
        #expect(graph.outDegree(of: 0) == 1)
        #expect(graph.inDegree(of: 0) == 1)
        #expect(graph.degree(of: 0) == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.vertexCount == 1)
    }

    @Test("Q-14 a vertex with a self-loop appears once in its own out- and in-neighborhoods", .tags(.selfLoops))
    func selfLoopInNeighborhoods() {
        // NetworkX test_function graph. Vertex 1: edges 1→1, 1→2, 1→0, and 0→1.
        let graph = AdjacencyList(adjacency: [0: [1, 2, 3], 1: [1, 2, 0], 4: []])
        #expect(graph.successors(of: 1).sorted() == [0, 1, 2])
        #expect(graph.predecessors(of: 1).sorted() == [0, 1])
        #expect(graph.outDegree(of: 1) == 3)
        #expect(graph.inDegree(of: 1) == 2)
        #expect(graph.degree(of: 1) == 5)
        // Successors and predecessors are sets, while degree counts the self-loop at both ends,
        // so |successors ∪ predecessors| < degree whenever v has a self-loop or a reciprocal edge.
        #expect(Set(graph.successors(of: 1)).union(graph.predecessors(of: 1)).count == 3)
    }

    @Test("a graph with only self-loops", .tags(.selfLoops))
    func onlySelfLoops() {
        let graph = AdjacencyList(edges: (0 ..< 5).map { DirectedEdge(from: $0, to: $0) })
        #expect(graph.vertexCount == 5)
        #expect(graph.edgeCount == 5)
        for v in 0 ..< 5 {
            #expect(Array(graph.successors(of: v)) == [v])
            #expect(Array(graph.predecessors(of: v)) == [v])
            #expect(graph.degree(of: v) == 2)
        }
        #expect(graph.edges.allSatisfy { $0.isSelfLoop })
    }

    @Test("X-10 1000 edges including a self-loop")
    func thousandEdges() {
        // petgraph tests/graphmap.rs: (i / 2) → i for i in 0..<1000; i = 0 gives the self-loop 0 → 0.
        let graph = AdjacencyList(edges: (0 ..< 1000).map { DirectedEdge(from: $0 / 2, to: $0) })
        #expect(graph.vertexCount == 1000)
        #expect(graph.edgeCount == 1000)
        #expect(graph.contains(DirectedEdge(from: 0, to: 0)))
        #expect(graph.outDegree(of: 0) == 2)
        #expect(graph.inDegree(of: 0) == 1)
        #expect(graph.outDegree(of: 499) == 2)
        #expect(graph.outDegree(of: 500) == 0)
        #expect(graph.inDegree(of: 999) == 1)
    }
}
