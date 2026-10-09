// Cases added after the critical review: the edge-index laws, and view and builder behavior that
// survived the first suite. Case IDs continue the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Graph review cases")
struct GraphReviewTests {
    @Test("UG-L24 edge indices: one-to-one onto 0..<edgeIndexBound, and incident ones are incidentEdges mapped", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func edgeIndexLaws(_ fixture: UndirectedFixture<Int>) {
        func laws<G: Graph>(_ graph: G) {
            guard let bound = graph.edgeIndexBound, graph.vertexIndexBound != nil else {
                Issue.record("\(G.self) should have vertex and edge indices")
                return
            }
            #expect(bound == graph.edgeCount)
            #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) }.sorted() == Array(0 ..< bound))
            for v in graph.vertices {
                let i = graph.vertexIndex(of: v)
                #expect(Array(graph.incidentEdgeIndices(ofIndex: i)) == graph.incidentEdges(of: v).map { graph.edgeIndex(of: $0) })
                #expect(Array(graph.incidentEdgeIndices(ofIndex: i)).count == Array(graph.neighborIndices(ofIndex: i)).count)
            }
        }
        laws(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        laws(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("UG-L24 the undirected view forwards its base's edge indices, or their absence", .tags(.precondition))
    func viewEdgeIndices() async {
        let list = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 1)])
        let view = list.undirected
        #expect(view.edgeIndexBound == 3)
        #expect(view.edges.indices.map { view.edgeIndex(of: $0) } == list.edges.indices.map { list.edgeIndex(of: $0) })
        for v in view.vertices {
            let i = view.vertexIndex(of: v)
            #expect(Array(view.incidentEdges(ofIndex: i)) == Array(view.incidentEdges(of: v)))
            #expect(Array(view.incidentEdgeIndices(ofIndex: i)) == view.incidentEdges(of: v).map { view.edgeIndex(of: $0) })
        }
        let matrixView = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).undirected
        #expect(matrixView.edgeIndexBound == nil)
        await #expect(processExitsWith: .failure) {
            let view = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).undirected
            _ = view.edgeIndex(of: view.edges.startIndex)
        }
    }

    @Test("UG-L25 with edge indices, edges is in index order", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func edgesInIndexOrder(_ fixture: UndirectedFixture<Int>) {
        func law<G: Graph>(_ graph: G) {
            guard let bound = graph.edgeIndexBound else {
                Issue.record("\(G.self) should have edge indices")
                return
            }
            #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == Array(0 ..< bound))
        }
        law(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        law(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
        let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges.map { DirectedEdge(from: $0.u, to: $0.v) })
        law(list.undirected)
    }

    @Test("UG-C03 the directed view's predecessor indices are its predecessors mapped", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func directedViewPredecessorIndices(_ fixture: UndirectedFixture<Int>) {
        let view = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges).directed
        for v in view.vertices {
            let i = view.vertexIndex(of: v)
            #expect(Array(view.predecessorIndices(ofIndex: i)) == view.predecessors(of: v).map { view.vertexIndex(of: $0) })
            #expect(Array(view.predecessorIndices(ofIndex: i)) == Array(view.successorIndices(ofIndex: i)))
        }
    }

    @Test("UG-C01 the directed view's edges are empty exactly when the graph has no edges")
    func directedViewIsEmpty() {
        #expect(UndirectedAdjacencyList<Int>(vertices: [0, 1]).directed.edges.isEmpty)
        #expect(UndirectedAdjacencyList<Int>().directed.edges.isEmpty)
        #expect(!UndirectedAdjacencyList(edges: [UndirectedEdge(0, 0)]).directed.edges.isEmpty)
        #expect(UndirectedAdjacencyList(edges: [UndirectedEdge(0, 0)]).directed.edges.count == 2)
        #expect(AdjacencyList<Int>(vertices: [0]).undirected.edges.isEmpty)
    }

    @Test("UG-T08 the result builder keeps an if without an else, and either branch of an if–else")
    func builderOptional() {
        for includeLoop in [false, true] {
            let graph = UndirectedAdjacencyList<Int> {
                UndirectedEdge(0, 1)
                if includeLoop { UndirectedEdge(1, 1) }
                if includeLoop { 7 } else { 8 }
            }
            #expect(graph.edgeCount == (includeLoop ? 2 : 1))
            #expect(graph.contains(edge: UndirectedEdge(1, 1)) == includeLoop)
            #expect(graph.contains(includeLoop ? 7 : 8))
            #expect(!graph.contains(includeLoop ? 8 : 7))
        }
    }
}
