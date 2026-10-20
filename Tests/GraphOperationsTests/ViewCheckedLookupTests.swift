// The `checked:` lookups on the GraphOperations views: `transposedView`, `complementView` and the
// subgraph views, and `egoGraphView(checkedOf:)` of several centers. Each returns what the trapping spelling returns for a vertex of the view and
// throws `VertexNotFound` for any other value, a vertex the subgraph drops included. The directed
// complement's `source(checkedEdgeAt:)` and `target(checkedEdgeAt:)` throw `EdgeNotFound` for a
// cell that is out of range, on the diagonal, or joined in the base.

import AdjacencyListModule
import GraphOperations
import GraphProtocols
import Testing

@Suite("Checked lookups on the GraphOperations views")
struct ViewCheckedLookupTests {
    @Test("egoGraphView(checkedOf:) with several centers: the trapping spelling's view, VertexNotFound for a center that is not a vertex, with and without a budget")
    func egoGraphCenters() throws {
        let base = AdjacencyList(vertices: ["a", "b", "c", "d", "e"], edges: [
            DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "d"), DirectedEdge(from: "d", to: "e"), DirectedEdge(from: "e", to: "a"),
        ])
        let priority = { (v: String) -> Int in v == "d" ? 1 : 0 }
        #expect(try Array(base.egoGraphView(checkedOf: ["a", "c"]).vertices) == Array(base.egoGraphView(of: ["a", "c"]).vertices))
        #expect(try Array(base.egoGraphView(checkedOf: ["a", "c"], radius: 2, undirected: true).vertices) == ["a", "b", "c", "d", "e"])
        #expect(try Array(base.egoGraphView(checkedOf: ["a", "c"], maximumVertexCount: 3, priority: priority).vertices) == ["a", "c", "d"])
        #expect(try Array(base.egoGraphView(checkedOf: ["a"], radius: 1, undirected: true, maximumVertexCount: 2, priority: priority).vertices) == ["a", "b"])
        #expect(try Array(base.egoGraphView(checkedOf: [] as [String]).vertices) == [] as [String])
        #expect(throws: VertexNotFound.self) { try base.egoGraphView(checkedOf: ["a", "z"]) }
        #expect(throws: VertexNotFound.self) { try base.egoGraphView(checkedOf: ["z"], radius: 2, undirected: true) }
        #expect(throws: VertexNotFound.self) { try base.egoGraphView(checkedOf: ["a", "z"], maximumVertexCount: 3, priority: priority) }
        #expect(throws: VertexNotFound.self) { try base.egoGraphView(checkedOf: ["z"], undirected: false, maximumVertexCount: 3, priority: priority) }
        let undirected = UndirectedAdjacencyList(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("c", "d")])
        #expect(try Array(undirected.egoGraphView(checkedOf: ["b", "d"]).vertices) == ["a", "b", "c", "d"])
        #expect(try Array(undirected.egoGraphView(checkedOf: ["b", "d"], maximumVertexCount: 3, priority: priority).vertices) == ["a", "b", "d"])
        #expect(throws: VertexNotFound.self) { try undirected.egoGraphView(checkedOf: ["b", "q"]) }
        #expect(throws: VertexNotFound.self) { try undirected.egoGraphView(checkedOf: ["q"], maximumVertexCount: 3, priority: priority) }
    }

    @Test("transposedView: the checked reads are the base's with directions swapped")
    func transposed() throws {
        let base = AdjacencyList(vertices: ["a", "b", "c"], edges: [
            DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "c", to: "c"),
        ])
        let view = base.transposedView
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
        #expect(try Array(view.successors(checked: "b")) == ["a"])
        #expect(try view.inDegree(checked: "a") == 2)
        #expect(throws: VertexNotFound.self) { try view.successors(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.predecessors(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.outEdges(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.inEdges(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.outDegree(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.inDegree(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.degree(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.vertexIndex(checked: "z") }
    }

    @Test("complementView, directed: vertex reads, and checked endpoints of a cell")
    func complementDirected() throws {
        let base = AdjacencyList(vertices: ["a", "b", "c"], edges: [
            DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b"),
        ])
        let view = base.complementView
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
        #expect(try Array(view.successors(checked: "a")) == ["c"])
        #expect(throws: VertexNotFound.self) { try view.successors(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.inEdges(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.degree(checked: "z") }
        #expect(throws: VertexNotFound.self) { try view.vertexIndex(checked: "z") }

        typealias Cell = ComplementView<AdjacencyList<String>>.Cell
        for position in view.edges.indices {
            #expect(try view.source(checkedEdgeAt: position) == view.source(ofEdgeAt: position))
            #expect(try view.target(checkedEdgeAt: position) == view.target(ofEdgeAt: position))
        }
        #expect(try view.source(checkedEdgeAt: Cell(source: 2, target: 0)) == "c")
        #expect(try view.target(checkedEdgeAt: Cell(source: 2, target: 0)) == "a")
        // b→a is an edge of the complement: only a→b is in the base.
        #expect(try view.target(checkedEdgeAt: Cell(source: 1, target: 0)) == "a")
        for bad in [Cell(source: 0, target: 1), Cell(source: 1, target: 1), Cell(source: 0, target: 0),
                    Cell(source: 3, target: 0), Cell(source: 0, target: 3), Cell(source: -1, target: 0), Cell(source: 0, target: -1)] {
            #expect(throws: EdgeNotFound.self) { try view.source(checkedEdgeAt: bad) }
            #expect(throws: EdgeNotFound.self) { try view.target(checkedEdgeAt: bad) }
        }
    }

    @Test("complementView, undirected: the checked reads agree with the trapping ones")
    func complementUndirected() throws {
        let base = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let view = base.complementView
        for v in view.vertices {
            #expect(try Array(view.neighbors(checked: v)) == Array(view.neighbors(of: v)))
            #expect(try Array(view.incidentEdges(checked: v)) == Array(view.incidentEdges(of: v)))
            #expect(try view.degree(checked: v) == view.degree(of: v))
            #expect(try view.vertexIndex(checked: v) == view.vertexIndex(of: v))
        }
        #expect(try Array(view.neighbors(checked: 1)) == [3])
        #expect(throws: VertexNotFound.self) { try view.neighbors(checked: 4) }
        #expect(throws: VertexNotFound.self) { try view.incidentEdges(checked: 4) }
        #expect(throws: VertexNotFound.self) { try view.degree(checked: 4) }
        #expect(throws: VertexNotFound.self) { try view.vertexIndex(checked: 4) }
    }

    @Test("a directed subgraph view throws for a vertex it drops as for a non-vertex")
    func subgraphDirected() throws {
        let base = AdjacencyList(vertices: ["a", "b", "c", "d"], edges: [
            DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "a", to: "d"),
        ])
        for view in [base.inducedSubgraphView(on: ["a", "b", "c"]), base.subgraphView(vertices: ["a", "b", "c"], edges: [0, 2]),
                     base.spanningSubgraphView(edges: [0, 3])] {
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
            #expect(throws: VertexNotFound.self) { try view.successors(checked: "z") }
        }
        let induced = base.inducedSubgraphView(on: ["a", "b", "c"])
        #expect(try Array(induced.successors(checked: "a")) == ["b"])
        #expect(throws: VertexNotFound.self) { try induced.successors(checked: "d") }
        #expect(throws: VertexNotFound.self) { try induced.predecessors(checked: "d") }
        #expect(throws: VertexNotFound.self) { try induced.outEdges(checked: "d") }
        #expect(throws: VertexNotFound.self) { try induced.inEdges(checked: "d") }
        #expect(throws: VertexNotFound.self) { try induced.outDegree(checked: "d") }
        #expect(throws: VertexNotFound.self) { try induced.inDegree(checked: "d") }
        #expect(throws: VertexNotFound.self) { try induced.degree(checked: "d") }
        #expect(throws: VertexNotFound.self) { try induced.vertexIndex(checked: "d") }
        let spanning = base.spanningSubgraphView(edges: [0, 3])
        #expect(try spanning.outDegree(checked: "a") == 2)
        #expect(try spanning.inDegree(checked: "a") == 0)
    }

    @Test("an undirected subgraph view throws for a vertex it drops as for a non-vertex")
    func subgraphUndirected() throws {
        let base = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let view = base.inducedSubgraphView(on: [1, 2, 3])
        for v in view.vertices {
            #expect(try Array(view.neighbors(checked: v)) == Array(view.neighbors(of: v)))
            #expect(try Array(view.incidentEdges(checked: v)) == Array(view.incidentEdges(of: v)))
            #expect(try view.degree(checked: v) == view.degree(of: v))
            #expect(try view.vertexIndex(checked: v) == view.vertexIndex(of: v))
        }
        #expect(try view.degree(checked: 1) == 1)
        #expect(try view.vertexIndex(checked: 3) == 2)
        #expect(throws: VertexNotFound.self) { try view.neighbors(checked: 0) }
        #expect(throws: VertexNotFound.self) { try view.incidentEdges(checked: 0) }
        #expect(throws: VertexNotFound.self) { try view.degree(checked: 0) }
        #expect(throws: VertexNotFound.self) { try view.vertexIndex(checked: 0) }
        #expect(throws: VertexNotFound.self) { try view.neighbors(checked: 9) }
    }
}
