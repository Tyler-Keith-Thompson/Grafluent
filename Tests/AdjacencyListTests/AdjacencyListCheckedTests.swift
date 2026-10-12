// The `checked:` spellings (README Principle 6) on `AdjacencyList`: each agrees with its trapping spelling for a vertex or position in the graph, and throws
// `VertexNotFound` or `EdgeNotFound`, changing nothing, where the trapping spelling would trap.
// `insert(checked:)` inserts only between existing vertices. See README.md.

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("AdjacencyList checked spellings")
struct AdjacencyListCheckedTests {
    @Test("Directed lookups of a vertex agree with the trapping spellings")
    func directedLookupsOfAVertex() throws {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3)])
        for v in [0, 1, 2, 3] {
            #expect(try Array(graph.successors(checked: v)) == Array(graph.successors(of: v)))
            #expect(try Array(graph.predecessors(checked: v)) == Array(graph.predecessors(of: v)))
            #expect(try graph.outEdges(checked: v) == graph.outEdges(of: v))
            #expect(try graph.inEdges(checked: v) == graph.inEdges(of: v))
            #expect(try graph.outDegree(checked: v) == graph.outDegree(of: v))
            #expect(try graph.inDegree(checked: v) == graph.inDegree(of: v))
            #expect(try graph.degree(checked: v) == graph.degree(of: v))
            #expect(try graph.vertexIndex(checked: v) == graph.vertexIndex(of: v))
        }
        // Pinned values for vertex 1: the loop once out and once in.
        #expect(try Set(graph.successors(checked: 1)) == [1, 3])
        #expect(try Set(graph.predecessors(checked: 1)) == [0, 1, 2])
        #expect(try graph.outDegree(checked: 1) == 2)
        #expect(try graph.inDegree(checked: 1) == 3)
        #expect(try graph.degree(checked: 1) == 5)
        #expect(try graph.vertexIndex(checked: 1) == 1)
    }

    @Test("Directed lookups of a non-vertex throw VertexNotFound")
    func directedLookupsOfANonVertex() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
        #expect(throws: VertexNotFound()) { try graph.successors(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.predecessors(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.outEdges(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.inEdges(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.outDegree(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.inDegree(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.degree(checked: 7) }
        #expect(throws: VertexNotFound()) { try graph.vertexIndex(checked: 7) }
        #expect(throws: VertexNotFound()) { try AdjacencyList<Int>().degree(checked: 0) }
        // try? gives nil.
        #expect((try? graph.outDegree(checked: -1)) == nil)
    }

    @Test("Directed lookups after a removal follow the moved slot")
    func directedLookupsAfterRemoval() throws {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        graph.remove(0)
        // The last slot, vertex 2, moved into slot 0.
        #expect(try graph.vertexIndex(checked: 2) == 0)
        #expect(try graph.vertexIndex(checked: 1) == 1)
        #expect(try Array(graph.predecessors(checked: 2)) == [1])
        #expect(try graph.outDegree(checked: 2) == 0)
        #expect(throws: VertexNotFound()) { try graph.vertexIndex(checked: 0) }
        #expect(throws: VertexNotFound()) { try graph.successors(checked: 0) }
    }

    @Test("source and target by checked position")
    func checkedEndpoints() throws {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)])
        for p in 0 ..< graph.edgeCount {
            #expect(try graph.source(checkedEdgeAt: p) == graph.source(ofEdgeAt: p))
            #expect(try graph.target(checkedEdgeAt: p) == graph.target(ofEdgeAt: p))
        }
        #expect(try graph.source(checkedEdgeAt: 2) == 2)
        #expect(try graph.target(checkedEdgeAt: 1) == 2)
        for p in [-1, 3, Int.min, Int.max] {
            #expect(throws: EdgeNotFound()) { try graph.source(checkedEdgeAt: p) }
            #expect(throws: EdgeNotFound()) { try graph.target(checkedEdgeAt: p) }
        }
        // Removing position 0 moves the last edge, 2→2, into it; position 2 is gone.
        graph.remove(edge: DirectedEdge(from: 0, to: 1))
        #expect(try graph.source(checkedEdgeAt: 0) == 2)
        #expect(try graph.target(checkedEdgeAt: 0) == 2)
        #expect(throws: EdgeNotFound()) { try graph.source(checkedEdgeAt: 2) }
        #expect(throws: EdgeNotFound()) { try AdjacencyList<Int>().target(checkedEdgeAt: 0) }
    }

    @Test("insert(checked:) inserts only between existing vertices")
    func directedCheckedInsert() throws {
        var graph = AdjacencyList(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1)])
        let added = try graph.insert(checked: DirectedEdge(from: 1, to: 2))
        #expect(added.inserted)
        #expect(added.memberAfterInsert == DirectedEdge(from: 1, to: 2))
        let loop = try graph.insert(checked: DirectedEdge(from: 2, to: 2))
        #expect(loop.inserted)
        // An existing edge: not inserted, the graph's own edge returned.
        let again = try graph.insert(checked: DirectedEdge(from: 0, to: 1))
        #expect(!again.inserted)
        #expect(again.memberAfterInsert == DirectedEdge(from: 0, to: 1))
        #expect(graph.edgeCount == 3)
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 2)))

        // A missing endpoint: throws, and neither the vertex nor the edge is inserted.
        let before = graph
        #expect(throws: VertexNotFound()) { try graph.insert(checked: DirectedEdge(from: 0, to: 9)) }
        #expect(throws: VertexNotFound()) { try graph.insert(checked: DirectedEdge(from: 9, to: 0)) }
        #expect(throws: VertexNotFound()) { try graph.insert(checked: DirectedEdge(from: 9, to: 9)) }
        #expect(graph == before)
        #expect(!graph.contains(9))
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
    }

    @Test("insert(checked:) and the lookups with String vertices")
    func directedCheckedStrings() throws {
        var graph = AdjacencyList<String>(vertices: ["a", "b"])
        let result = try graph.insert(checked: DirectedEdge(from: "a", to: "b"))
        #expect(result.inserted)
        #expect(result.memberAfterInsert == DirectedEdge(from: "a", to: "b"))
        #expect(try Array(graph.successors(checked: "a")) == ["b"])
        #expect(throws: VertexNotFound()) { try graph.insert(checked: DirectedEdge(from: "a", to: "c")) }
        #expect(throws: VertexNotFound()) { try graph.predecessors(checked: "c") }
    }

    @Test("A checked insert matches the unchecked one when the endpoints exist")
    func checkedInsertMatchesPlainInsert() throws {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)]
        var plain = AdjacencyList<Int>(vertices: [0, 1, 2])
        var checked = AdjacencyList<Int>(vertices: [0, 1, 2])
        for edge in edges {
            let p = plain.insert(edge: edge)
            let c = try checked.insert(checked: edge)
            #expect(p.inserted == c.inserted && p.memberAfterInsert == c.memberAfterInsert)
        }
        #expect(plain == checked)
        #expect(Array(plain.edges) == Array(checked.edges))
    }
}
