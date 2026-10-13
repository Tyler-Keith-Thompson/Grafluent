// The `checked:` spellings: each throws `VertexNotFound` or `EdgeNotFound`
// where its trapping spelling would trap, and otherwise returns what the trapping spelling
// returns. Case ID AM-R08 refers to the case catalog.

import AdjacencyMatrixModule
import BitCollections
import GraphProtocols
import Testing

@Suite("AdjacencyMatrix checked: spellings")
struct AdjacencyMatrixCheckedTests {
    @Test("AM-R08 every checked: row lookup equals its trapping spelling on every vertex")
    func rowsAgree() throws {
        // FX-03: a self-loop on 6 and an isolated-in vertex 5.
        let matrix = AdjacencyMatrix(vertexCount: 7, edges: [
            DirectedEdge(from: 0, to: 5), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3),
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 0), DirectedEdge(from: 6, to: 6),
        ])
        for v in 0 ..< 7 {
            #expect(try matrix.successors(checked: v) == matrix.successors(of: v))
            #expect(try matrix.predecessors(checked: v) == matrix.predecessors(of: v))
            #expect(Array(try matrix.outEdges(checked: v)) == Array(matrix.outEdges(of: v)))
            #expect(Array(try matrix.inEdges(checked: v)) == Array(matrix.inEdges(of: v)))
            #expect(try matrix.outDegree(checked: v) == matrix.outDegree(of: v))
            #expect(try matrix.inDegree(checked: v) == matrix.inDegree(of: v))
            #expect(try matrix.degree(checked: v) == matrix.degree(of: v))
            #expect(try matrix.vertexIndex(checked: v) == v)
        }
        #expect(Array(try matrix.successors(checked: 0)) == [1, 2, 3, 5])
        #expect(Array(try matrix.predecessors(checked: 3)) == [0, 1, 2])
        #expect(try matrix.outDegree(checked: 0) == 4)
        #expect(try matrix.inDegree(checked: 3) == 3)
        #expect(try matrix.degree(checked: 6) == 2)
    }

    @Test("AM-R08 every checked: row lookup throws VertexNotFound just outside 0..<n", arguments: [-1, 7, 8, Int.min, Int.max])
    func rowsThrow(vertex: Int) {
        let matrix = AdjacencyMatrix(vertexCount: 7, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 6, to: 6)])
        #expect(throws: VertexNotFound()) { try matrix.successors(checked: vertex) }
        #expect(throws: VertexNotFound()) { try matrix.predecessors(checked: vertex) }
        #expect(throws: VertexNotFound()) { try matrix.outEdges(checked: vertex) }
        #expect(throws: VertexNotFound()) { try matrix.inEdges(checked: vertex) }
        #expect(throws: VertexNotFound()) { try matrix.outDegree(checked: vertex) }
        #expect(throws: VertexNotFound()) { try matrix.inDegree(checked: vertex) }
        #expect(throws: VertexNotFound()) { try matrix.degree(checked: vertex) }
        #expect(throws: VertexNotFound()) { try matrix.vertexIndex(checked: vertex) }
        #expect((try? matrix.outDegree(checked: vertex)) == nil)
        #expect((try? matrix.successors(checked: vertex)) == nil)
    }

    @Test("AM-R08 the last vertex is in range and the first past it is not")
    func boundary() {
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 2, to: 0)])
        #expect((try? matrix.outDegree(checked: 2)) == 1)
        #expect((try? matrix.inDegree(checked: 0)) == 1)
        #expect((try? matrix.vertexIndex(checked: 0)) == 0)
        #expect((try? matrix.outDegree(checked: 3)) == nil)
        #expect((try? AdjacencyMatrix().degree(checked: 0)) == nil)
    }

    @Test("AM-R08 source(checkedEdgeAt:) and target(checkedEdgeAt:) equal the trapping spellings on every edge")
    func endpointsAgree() throws {
        let matrix = AdjacencyMatrix(vertexCount: 4, edges: [
            DirectedEdge(from: 0, to: 3), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 3),
        ])
        var seen: [DirectedEdge<Int>] = []
        for position in matrix.edges.indices {
            let source = try matrix.source(checkedEdgeAt: position)
            let target = try matrix.target(checkedEdgeAt: position)
            #expect(source == matrix.source(ofEdgeAt: position))
            #expect(target == matrix.target(ofEdgeAt: position))
            seen.append(DirectedEdge(from: source, to: target))
        }
        #expect(seen == [DirectedEdge(from: 0, to: 3), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 3)])
    }

    @Test("AM-R08 a cell that holds no edge throws EdgeNotFound, also after the edge is removed")
    func endpointsThrow() throws {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let first = try #require(matrix.outEdges(of: 0).first)
        let second = try #require(matrix.outEdges(of: 1).first)
        matrix.remove(edge: DirectedEdge(from: 0, to: 1))
        #expect(throws: EdgeNotFound()) { try matrix.source(checkedEdgeAt: first) }
        #expect(throws: EdgeNotFound()) { try matrix.target(checkedEdgeAt: first) }
        #expect((try? matrix.source(checkedEdgeAt: second)) == 1)
        #expect((try? matrix.target(checkedEdgeAt: second)) == 2)
        // A cell past the matrix: the position from a larger matrix.
        let wide = AdjacencyMatrix(vertexCount: 5, edges: [DirectedEdge(from: 4, to: 4), DirectedEdge(from: 0, to: 4)])
        for position in wide.edges.indices {
            #expect(throws: EdgeNotFound()) { try matrix.source(checkedEdgeAt: position) }
            #expect(throws: EdgeNotFound()) { try matrix.target(checkedEdgeAt: position) }
        }
        #expect((try? matrix.target(checkedEdgeAt: first)) == nil)
    }

    @Test("AM-R08 insert(checked:) inserts like insert(edge:) when both endpoints are in range")
    func insertInRange() throws {
        var checked = AdjacencyMatrix(vertexCount: 4)
        var plain = AdjacencyMatrix(vertexCount: 4)
        let edges = [DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 3), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 2, to: 0)]
        for edge in edges {
            let a = try checked.insert(checked: edge)
            let b = plain.insert(edge: edge)
            #expect(a.inserted == b.inserted)
            #expect(a.memberAfterInsert == b.memberAfterInsert)
            #expect(checked == plain)
        }
        #expect(checked.edgeCount == 3)
        #expect(checked.contains(edge: DirectedEdge(from: 3, to: 3)))
    }

    @Test("AM-R08 insert(checked:) throws VertexNotFound for either endpoint out of range and changes nothing", arguments: [
        DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 0), DirectedEdge(from: -1, to: 0),
        DirectedEdge(from: 0, to: -1), DirectedEdge(from: 3, to: 3), DirectedEdge(from: 2, to: Int.max),
    ])
    func insertOutOfRange(edge: DirectedEdge<Int>) {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)])
        let before = matrix
        #expect(throws: VertexNotFound()) { try matrix.insert(checked: edge) }
        #expect(matrix == before)
        #expect(matrix.edgeCount == 1)
        #expect(matrix.vertexCount == 3)
        #expect((try? matrix.insert(checked: edge)) == nil)
    }
}
