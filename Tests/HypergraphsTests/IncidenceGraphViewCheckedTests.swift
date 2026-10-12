// The `checked:` lookups on the incidence graph views: on `0 ..< n + m` they return what the
// trapping spellings return and throw `VertexNotFound` for any other index; the directed view's
// `source(checkedEdgeAt:)` and `target(checkedEdgeAt:)` throw `EdgeNotFound` outside
// `0 ..< edgeCount`.

import GraphProtocols
import Hypergraphs
import Testing

@Suite("Checked lookups on the incidence graph views")
struct IncidenceGraphViewCheckedTests {
    @Test("undirected: vertices and hyperedges read checked, other indices throw")
    func undirected() throws {
        let hypergraph = UndirectedIncidenceList(vertices: ["a", "b", "c"], hyperedges: [["a", "b"], ["b", "c", "a"], []])
        let view = hypergraph.incidenceGraphView
        for v in view.vertices {
            #expect(try Array(view.neighbors(checked: v)) == Array(view.neighbors(of: v)))
            #expect(try Array(view.incidentEdges(checked: v)) == Array(view.incidentEdges(of: v)))
            #expect(try view.degree(checked: v) == view.degree(of: v))
            #expect(try view.vertexIndex(checked: v) == view.vertexIndex(of: v))
        }
        #expect(try view.degree(checked: 4) == 3)
        #expect(try view.degree(checked: 5) == 0)
        for bad in [-1, 6, Int.max] {
            #expect(throws: VertexNotFound.self) { try view.neighbors(checked: bad) }
            #expect(throws: VertexNotFound.self) { try view.incidentEdges(checked: bad) }
            #expect(throws: VertexNotFound.self) { try view.degree(checked: bad) }
            #expect(throws: VertexNotFound.self) { try view.vertexIndex(checked: bad) }
        }
    }

    @Test("directed: vertex reads and arc endpoints read checked, other values throw")
    func directed() throws {
        let hypergraph = IncidenceList(vertices: ["a", "b", "c"], hyperedges: [
            (sources: ["a"], targets: ["b", "c"]), (sources: ["b", "c"], targets: ["a"]),
        ])
        let view = hypergraph.incidenceGraphView
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
        #expect(try Array(view.successors(checked: 3)) == [1, 2])
        for bad in [-1, 5] {
            #expect(throws: VertexNotFound.self) { try view.successors(checked: bad) }
            #expect(throws: VertexNotFound.self) { try view.predecessors(checked: bad) }
            #expect(throws: VertexNotFound.self) { try view.outEdges(checked: bad) }
            #expect(throws: VertexNotFound.self) { try view.inEdges(checked: bad) }
            #expect(throws: VertexNotFound.self) { try view.outDegree(checked: bad) }
            #expect(throws: VertexNotFound.self) { try view.inDegree(checked: bad) }
            #expect(throws: VertexNotFound.self) { try view.degree(checked: bad) }
            #expect(throws: VertexNotFound.self) { try view.vertexIndex(checked: bad) }
        }
        #expect(view.edgeCount == 6)
        for position in 0 ..< view.edgeCount {
            #expect(try view.source(checkedEdgeAt: position) == view.source(ofEdgeAt: position))
            #expect(try view.target(checkedEdgeAt: position) == view.target(ofEdgeAt: position))
        }
        #expect(try view.source(checkedEdgeAt: 0) == 0 && view.target(checkedEdgeAt: 0) == 3)
        #expect(try view.source(checkedEdgeAt: 5) == 4 && view.target(checkedEdgeAt: 5) == 0)
        for bad in [-1, 6, Int.min] {
            #expect(throws: EdgeNotFound.self) { try view.source(checkedEdgeAt: bad) }
            #expect(throws: EdgeNotFound.self) { try view.target(checkedEdgeAt: bad) }
        }
    }
}
