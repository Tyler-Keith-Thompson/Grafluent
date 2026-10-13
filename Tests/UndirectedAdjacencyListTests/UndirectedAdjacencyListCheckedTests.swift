// The `checked:` spellings on `UndirectedAdjacencyList`: each agrees with its
// trapping spelling for a vertex in the graph, and throws `VertexNotFound`, changing nothing, where
// the trapping spelling would trap. `insert(checked:)` inserts only between existing vertices.

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("UndirectedAdjacencyList checked spellings")
struct UndirectedAdjacencyListCheckedTests {
    @Test("Lookups of a vertex agree with the trapping spellings")
    func lookupsOfAVertex() throws {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)])
        for v in [0, 1, 2] {
            #expect(try Array(graph.neighbors(checked: v)) == Array(graph.neighbors(of: v)))
            #expect(try graph.incidentEdges(checked: v) == graph.incidentEdges(of: v))
            #expect(try graph.degree(checked: v) == graph.degree(of: v))
            #expect(try graph.vertexIndex(checked: v) == graph.vertexIndex(of: v))
        }
        // The self-loop counts twice and is listed twice.
        #expect(try graph.degree(checked: 1) == 4)
        #expect(try graph.neighbors(checked: 1).sorted() == [0, 1, 1, 2])
        #expect(try graph.incidentEdges(checked: 1).count == 4)
    }

    @Test("Lookups of a non-vertex throw VertexNotFound")
    func lookupsOfANonVertex() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        #expect(throws: VertexNotFound()) { try graph.neighbors(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.incidentEdges(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.degree(checked: 5) }
        #expect(throws: VertexNotFound()) { try graph.vertexIndex(checked: 5) }
        #expect(throws: VertexNotFound()) { try UndirectedAdjacencyList<Int>().neighbors(checked: 0) }
        #expect((try? graph.degree(checked: 5)) == nil)
    }

    @Test("Lookups after a removal follow the moved slot")
    func lookupsAfterRemoval() throws {
        var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        graph.remove(0)
        #expect(try graph.vertexIndex(checked: 2) == 0)
        #expect(try Array(graph.neighbors(checked: 2)) == [1])
        #expect(try graph.degree(checked: 1) == 1)
        #expect(throws: VertexNotFound()) { try graph.degree(checked: 0) }
    }

    @Test("insert(checked:) inserts only between existing vertices")
    func checkedInsert() throws {
        var graph = UndirectedAdjacencyList(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])
        let added = try graph.insert(checked: UndirectedEdge(2, 1))
        #expect(added.inserted)
        #expect([added.memberAfterInsert.u, added.memberAfterInsert.v] == [2, 1])
        // The same edge the other way round: not inserted, returned in its stored orientation.
        let again = try graph.insert(checked: UndirectedEdge(1, 0))
        #expect(!again.inserted)
        #expect([again.memberAfterInsert.u, again.memberAfterInsert.v] == [0, 1])
        let loop = try graph.insert(checked: UndirectedEdge(2, 2))
        #expect(loop.inserted)
        #expect(graph.edgeCount == 3)
        #expect(try graph.degree(checked: 2) == 3)

        let before = graph
        #expect(throws: VertexNotFound()) { try graph.insert(checked: UndirectedEdge(0, 9)) }
        #expect(throws: VertexNotFound()) { try graph.insert(checked: UndirectedEdge(9, 0)) }
        #expect(throws: VertexNotFound()) { try graph.insert(checked: UndirectedEdge(9, 9)) }
        #expect(graph == before)
        #expect(!graph.contains(9))
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
    }

    @Test("A checked insert matches the unchecked one when the endpoints exist")
    func checkedInsertMatchesPlainInsert() throws {
        let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(2, 2), UndirectedEdge(1, 2)]
        var plain = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2])
        var checked = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2])
        for edge in edges {
            let p = plain.insert(edge: edge)
            let c = try checked.insert(checked: edge)
            #expect(p.inserted == c.inserted && [p.memberAfterInsert.u, p.memberAfterInsert.v] == [c.memberAfterInsert.u, c.memberAfterInsert.v])
        }
        #expect(plain == checked)
        #expect(plain.edges.map { [$0.u, $0.v] } == checked.edges.map { [$0.u, $0.v] })
    }
}
