// The `checked:` lookups on the two views between the protocols, `directedView` and
// `undirectedView`: each returns what the trapping spelling returns for a vertex of the graph, and
// throws `VertexNotFound` for any other value.

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("Checked lookups on directedView and undirectedView")
struct ViewCheckedLookupTests {
    @Test("the directed view's checked reads agree with the trapping ones and throw for a non-vertex")
    func directedView() throws {
        let base = UndirectedAdjacencyList(vertices: ["a", "b", "c", "d"], edges: [
            UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "c"),
        ])
        let view = base.directedView
        for v in view.vertices {
            #expect(try Array(view.successors(checked: v)) == Array(view.successors(of: v)))
            #expect(try Array(view.predecessors(checked: v)) == Array(view.predecessors(of: v)))
            #expect(try Array(view.outEdges(checked: v)) == Array(view.outEdges(of: v)))
            #expect(try Array(view.inEdges(checked: v)) == Array(view.inEdges(of: v)))
            #expect(try view.outDegree(checked: v) == view.outDegree(of: v))
            #expect(try view.inDegree(checked: v) == view.inDegree(of: v))
            #expect(try view.degree(checked: v) == view.degree(of: v))
            #expect(try view.vertexIndex(checked: v) == view.vertexIndex(of: v))
        }
        #expect(try view.degree(checked: "c") == 6)
        #expect(throws: VertexNotFound.self) { try view.successors(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.predecessors(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.outEdges(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.inEdges(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.outDegree(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.inDegree(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.degree(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.vertexIndex(checked: "z") }
        #expect((try? view.successors(checked: "")) == nil)
    }

    @Test("the undirected view's checked reads agree with the trapping ones and throw for a non-vertex")
    func undirectedView() throws {
        let base = AdjacencyList(vertices: [3, 1, 2], edges: [
            DirectedEdge(from: 3, to: 1), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 2),
        ])
        let view = base.undirectedView
        for v in view.vertices {
            #expect(try Array(view.neighbors(checked: v)) == Array(view.neighbors(of: v)))
            #expect(try Array(view.incidentEdges(checked: v)) == Array(view.incidentEdges(of: v)))
            #expect(try view.degree(checked: v) == view.degree(of: v))
            #expect(try view.vertexIndex(checked: v) == view.vertexIndex(of: v))
        }
        #expect(try Array(view.neighbors(checked: 1)) == [3, 3])
        #expect(try view.vertexIndex(checked: 2) == 2)
        #expect(throws: VertexNotFound.self) { try view.neighbors(checked: 0) }
        #expect(throws: VertexNotFound.self) { try view.incidentEdges(checked: 0) }
        #expect(throws: VertexNotFound.self) { try view.degree(checked: 0) }
        #expect(throws: VertexNotFound.self) { try view.vertexIndex(checked: 0) }
    }

    @Test("the checked reads are reachable from generic code over either protocol")
    func generic() throws {
        func outDegree<G: DirectedGraph<Int>>(_ g: G, _ v: Int) -> Int? { try? g.outDegree(checked: v) }
        func degree<G: Graph<Int>>(_ g: G, _ v: Int) -> Int? { try? g.degree(checked: v) }
        let path = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(outDegree(path.directedView, 1) == 2)
        #expect(outDegree(path.directedView, 5) == nil)
        #expect(degree(path.directedView.undirectedView, 1) == 4)
        #expect(degree(path, 7) == nil)
        // A representation's own checked read through generic code: the extension's, the same values.
        #expect(degree(path, 0) == 1)
    }
}
