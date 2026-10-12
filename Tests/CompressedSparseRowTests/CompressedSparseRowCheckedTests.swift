// The `checked:` spellings (README Principle 6): each throws `VertexNotFound` or `EdgeNotFound`
// where its trapping spelling would trap (CSR-P01, CSR-P02, CSR-P06), and otherwise returns what
// the trapping spelling returns. Case IDs CSR-P08 and CSR-P09 refer to the harvested test catalog.

import CompressedSparseRowModule
import GraphProtocols
import Testing

@Suite("CompressedSparseRow checked: spellings")
struct CompressedSparseRowCheckedTests {
    @Test("CSR-P08 every checked: row lookup equals its trapping spelling on every vertex")
    func rowsAgree() throws {
        // Rows of different lengths, an empty row (3) and a self-loop (4).
        let graph = CompressedSparseRow(vertexCount: 5, edges: [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 4),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4),
            DirectedEdge(from: 4, to: 4),
        ])
        for v in 0 ..< 5 {
            #expect(try graph.successors(checked: v) == graph.successors(of: v))
            #expect(try graph.successors(checked: v).indices == graph.successors(of: v).indices)
            #expect(try graph.outEdges(checked: v) == graph.outEdges(of: v))
            #expect(try graph.outDegree(checked: v) == graph.outDegree(of: v))
            #expect(try graph.vertexIndex(checked: v) == v)
        }
        #expect(Array(try graph.successors(checked: 2)) == [0, 3, 4])
        #expect(try graph.outEdges(checked: 2) == 3 ..< 6)
        #expect(try graph.outDegree(checked: 3) == 0)
    }

    @Test("CSR-P08 every checked: row lookup throws VertexNotFound outside 0..<n", arguments: [-1, 5, 6, Int.min, Int.max])
    func rowsThrow(vertex: Int) {
        let graph = CompressedSparseRow(vertexCount: 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 4, to: 4)])
        #expect(throws: VertexNotFound()) { try graph.successors(checked: vertex) }
        #expect(throws: VertexNotFound()) { try graph.outEdges(checked: vertex) }
        #expect(throws: VertexNotFound()) { try graph.outDegree(checked: vertex) }
        #expect(throws: VertexNotFound()) { try graph.vertexIndex(checked: vertex) }
        #expect((try? graph.outDegree(checked: vertex)) == nil)
    }

    @Test("CSR-P08 the last vertex is in range and the first past it is not")
    func vertexBoundary() {
        let graph = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 2, to: 0)])
        #expect((try? graph.outDegree(checked: 2)) == 1)
        #expect((try? graph.vertexIndex(checked: 0)) == 0)
        #expect((try? graph.outDegree(checked: 3)) == nil)
        #expect((try? CompressedSparseRow().outDegree(checked: 0)) == nil)
    }

    @Test("CSR-P09 source(checkedEdgeAt:) and target(checkedEdgeAt:) equal the trapping spellings on every edge index")
    func endpointsAgree() throws {
        let graph = CompressedSparseRow(vertexCount: 5, edges: [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 4),
            DirectedEdge(from: 2, to: 0), DirectedEdge(from: 4, to: 4),
        ])
        var edges: [DirectedEdge<Int>] = []
        for k in 0 ..< graph.edgeCount {
            let source = try graph.source(checkedEdgeAt: k)
            let target = try graph.target(checkedEdgeAt: k)
            #expect(source == graph.source(ofEdgeAt: k))
            #expect(target == graph.target(ofEdgeAt: k))
            edges.append(DirectedEdge(from: source, to: target))
        }
        #expect(edges == Array(graph.edges))
        #expect(try graph.source(checkedEdgeAt: 4) == 4)
        #expect(try graph.target(checkedEdgeAt: 0) == 1)
    }

    @Test("CSR-P09 an edge index outside 0..<edgeCount throws EdgeNotFound", arguments: [-1, 3, 4, Int.min, Int.max])
    func endpointsThrow(edgeIndex: Int) {
        let graph = CompressedSparseRow(vertexCount: 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 3, to: 3),
        ])
        #expect(throws: EdgeNotFound()) { try graph.source(checkedEdgeAt: edgeIndex) }
        #expect(throws: EdgeNotFound()) { try graph.target(checkedEdgeAt: edgeIndex) }
        #expect((try? graph.source(checkedEdgeAt: edgeIndex)) == nil)
        #expect((try? graph.target(checkedEdgeAt: edgeIndex)) == nil)
    }

    @Test("CSR-P09 a graph with vertices and no edges has no edge index")
    func noEdges() {
        let graph = CompressedSparseRow(vertexCount: 3)
        #expect(throws: EdgeNotFound()) { try graph.source(checkedEdgeAt: 0) }
        #expect(throws: EdgeNotFound()) { try graph.target(checkedEdgeAt: 0) }
    }
}
