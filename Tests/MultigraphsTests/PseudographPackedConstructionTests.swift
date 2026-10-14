// `Pseudograph(vertices:edges:)` and `DirectedPseudograph(vertices:edges:)` lay the rows out once,
// packed in slot order, and must build the graph that inserting the same vertices and edges one at
// a time builds: every copy kept, at its position, in its orientation. The lent row table is
// checked for the packed layout and for the one table both pools share.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Pseudograph packed bulk construction")
struct PseudographPackedConstructionTests {
    @Test("DirectedPseudograph(vertices:edges:) is the inserted graph, copies and loops kept, with packed rows")
    func directed() {
        let edges = [("a", "b"), ("b", "a"), ("a", "b"), ("d", "d"), ("d", "d"), ("c", "a")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let bulk = DirectedPseudograph(vertices: ["c"], edges: edges)
        var inserted = DirectedPseudograph<String>()
        inserted.insert("c")
        for edge in edges { inserted.insert(edge: edge) }
        #expect(Array(bulk.vertices) == ["c", "a", "b", "d"])
        #expect(Array(bulk.vertices) == Array(inserted.vertices))
        #expect(Array(bulk.edges) == edges)
        #expect(bulk.edgeCount(from: "a", to: "b") == 2 && bulk.edgeCount(from: "d", to: "d") == 2)
        for v in 0 ..< bulk.vertexCount {
            #expect(Array(bulk.successorIndices(ofIndex: v)) == Array(inserted.successorIndices(ofIndex: v)))
            #expect(Array(bulk.outEdges(ofIndex: v)) == Array(inserted.outEdges(ofIndex: v)))
            #expect(Array(bulk.inEdges(ofIndex: v)) == Array(inserted.inEdges(ofIndex: v)))
        }
        #expect(Array(DirectedPseudograph(edges: edges).vertices) == ["a", "b", "d", "c"])
        let packed = bulk._withOutIndexRows { _, targetRows, _, edgeRows -> Bool in
            var next = 0
            for v in 0 ..< bulk.vertexCount {
                guard targetRows[3 * v] == next, targetRows[3 * v + 2] == targetRows[3 * v + 1] else { return false }
                next += targetRows[3 * v + 1]
            }
            return next == bulk.edgeCount && edgeRows.baseAddress == targetRows.baseAddress
        }
        #expect(packed == true)
        var grown = bulk
        grown.insert(edge: DirectedEdge(from: "c", to: "b"))
        #expect(grown.edgeCount == 7 && bulk.edgeCount == 6)
        #expect(Array(grown.outEdges(of: "c")) == [5, 6])
        #expect(grown._withOutIndexRows { _, targetRows, _, edgeRows in edgeRows.baseAddress == targetRows.baseAddress } == true)
    }

    @Test("Pseudograph(vertices:edges:) is the inserted graph, copies, loops and orientations kept, with packed rows")
    func undirected() {
        let edges = [("a", "b"), ("b", "a"), ("d", "d"), ("c", "a")].map { UndirectedEdge($0.0, $0.1) }
        let bulk = Pseudograph(vertices: ["c"], edges: edges)
        var inserted = Pseudograph<String>()
        inserted.insert("c")
        for edge in edges { inserted.insert(edge: edge) }
        #expect(Array(bulk.vertices) == Array(inserted.vertices))
        #expect(bulk.edgeCount == 4 && bulk.edgeCount(between: "a", and: "b") == 2)
        for p in 0 ..< bulk.edgeCount {
            #expect(bulk.endpointIndices(ofEdgeAt: p) == inserted.endpointIndices(ofEdgeAt: p))
            #expect(bulk.vertex(atIndex: bulk.endpointIndices(ofEdgeAt: p).u) == edges[p].u)
        }
        for v in 0 ..< bulk.vertexCount {
            #expect(Array(bulk.neighborIndices(ofIndex: v)) == Array(inserted.neighborIndices(ofIndex: v)))
            #expect(Array(bulk.incidentEdges(ofIndex: v)) == Array(inserted.incidentEdges(ofIndex: v)))
        }
        #expect(Pseudograph(edges: edges).degree(of: "d") == 2)
        let packed = bulk._withIncidentIndexRows { _, rows, _, edgeRows -> Bool in
            var next = 0
            for v in 0 ..< bulk.vertexCount {
                guard rows[3 * v] == next, rows[3 * v + 2] == rows[3 * v + 1] else { return false }
                next += rows[3 * v + 1]
            }
            return next == 2 * bulk.edgeCount && edgeRows.baseAddress == rows.baseAddress
        }
        #expect(packed == true)
        #expect(inserted._withIncidentIndexRows { _, rows, _, edgeRows in edgeRows.baseAddress == rows.baseAddress } == true)
    }
}
