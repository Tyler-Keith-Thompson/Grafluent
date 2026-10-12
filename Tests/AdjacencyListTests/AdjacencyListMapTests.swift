// Attached maps (catalog AM-01 – AM-09): maps attached to an AdjacencyList or an
// UndirectedAdjacencyList (`PropertyGraph`): defaults for existing and new elements, values moved
// with the swap-remove of an edge or a vertex, `removeAll` and `removeAllEdges` emptying them,
// handles and copies, equality and coding ignoring them, and `values(of:)` snapshots. A removed
// element has no value: the checked reads throw. Each test is self-contained.

import AdjacencyListModule
import Foundation
import GraphProtocols
import Testing

@Suite("AdjacencyList attached maps")
struct AdjacencyListMapTests {
    @Test("AM-01 a map gives every existing and every new element its default")
    func defaults() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let weights = graph.addEdgeMap(default: 1.5)
        let ranks = graph.addVertexMap(default: -1)
        #expect((0 ..< graph.edgeCount).map { graph[weights, ofEdgeAt: $0] } == [1.5, 1.5])
        #expect(graph.vertices.map { graph[ranks, of: $0] } == [-1, -1, -1])
        graph[weights, ofEdgeAt: 1] = 4
        graph[ranks, of: 2] = 7
        #expect(graph.insert(edge: DirectedEdge(from: 2, to: 3)).inserted)
        #expect(graph[weights, ofEdgeAt: 2] == 1.5)
        #expect(graph[ranks, of: 3] == -1)
        #expect(graph[weights, ofEdgeAt: 1] == 4)
        #expect(graph[ranks, of: 2] == 7)
        // An edge already present inserts nothing, and so appends no value.
        #expect(!graph.insert(edge: DirectedEdge(from: 0, to: 1)).inserted)
        #expect(graph.values(of: weights)[2] == 1.5)
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: 3] }
        // Bulk construction has no maps; one attached after reaches every edge.
        var built = AdjacencyList<Int>(edges: [DirectedEdge(from: 0, to: 1)])
        built.reserveCapacity(vertexCount: 10, edgeCount: 10)
        let late = built.addEdgeMap(default: "x")
        #expect(built[late, ofEdgeAt: 0] == "x")
        #expect(built.values(of: late).defaultValue == "x")
    }

    @Test("AM-02 addEdgeMap(of:) and addVertexMap(of:) are Optional maps whose default is nil")
    func optionalMaps() throws {
        var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let labels = graph.addEdgeMap(of: String.self)
        let names = graph.addVertexMap(of: String.self)
        #expect(graph[labels, ofEdgeAt: 0] == nil)
        graph[labels, ofEdgeAt: 0] = "a"
        graph[names, of: 1] = "one"
        #expect(graph[labels, ofEdgeAt: 0] == "a")
        #expect(try graph[labels, checkedEdgeAt: 0] == "a")
        #expect(try graph[names, checked: 1] == "one")
        #expect(try graph[names, checkedVertexAt: graph.vertexIndex(of: 1)] == "one")
        graph[labels, ofEdgeAt: 0] = nil
        #expect(graph[labels, ofEdgeAt: 0] == nil)
        #expect(graph.values(of: names).defaultValue == nil)
    }

    @Test("AM-03 removing an edge moves the last edge's value into its position")
    func edgeRemovalMovesValues() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 2)])
        let w = graph.addEdgeMap(default: 0)
        for p in 0 ..< graph.edgeCount { graph[w, ofEdgeAt: p] = 10 * graph.source(ofEdgeAt: p) + graph.target(ofEdgeAt: p) }
        #expect(graph.remove(edge: DirectedEdge(from: 0, to: 1)) != nil)
        #expect(graph.edgeCount == 3)
        for p in 0 ..< graph.edgeCount {
            #expect(graph[w, ofEdgeAt: p] == 10 * graph.source(ofEdgeAt: p) + graph.target(ofEdgeAt: p))
        }
        // The last edge goes without moving anything.
        let last = graph.edges[graph.edgeCount - 1]
        #expect(graph.remove(edge: last) == last)
        #expect(graph.edges.indices.map { graph[w, ofEdgeAt: $0] } == graph.edges.map { 10 * $0.source + $0.target })

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2), UndirectedEdge(0, 2)])
        let uw = undirected.addEdgeMap(default: 0)
        for p in 0 ..< undirected.edgeCount {
            let e = undirected.edges[p]
            undirected[uw, ofEdgeAt: p] = 10 * min(e.u, e.v) + max(e.u, e.v)
        }
        #expect(undirected.remove(edge: UndirectedEdge(1, 0)) != nil)
        #expect(undirected.remove(edge: UndirectedEdge(2, 2)) != nil)
        #expect(undirected.edges.indices.map { undirected[uw, ofEdgeAt: $0] } == undirected.edges.map { 10 * min($0.u, $0.v) + max($0.u, $0.v) })
    }

    @Test("AM-04 removing a vertex removes its edges' values and moves the last vertex's value into its slot")
    func vertexRemovalMovesValues() throws {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 1), DirectedEdge(from: 3, to: 3)])
        let w = graph.addEdgeMap(default: 0)
        let name = graph.addVertexMap(default: "")
        for p in 0 ..< graph.edgeCount { graph[w, ofEdgeAt: p] = 10 * graph.source(ofEdgeAt: p) + graph.target(ofEdgeAt: p) }
        for v in graph.vertices { graph[name, of: v] = "v\(v)" }
        #expect(graph.remove(1) == 1)
        #expect(graph.vertexCount == 3)
        for v in graph.vertices {
            #expect(graph[name, of: v] == "v\(v)")
            #expect(graph[name, ofVertexAt: graph.vertexIndex(of: v)] == "v\(v)")
        }
        #expect(graph.edges.indices.map { graph[w, ofEdgeAt: $0] }.sorted() == [23, 33])
        #expect(graph.edges.indices.allSatisfy { graph[w, ofEdgeAt: $0] == 10 * graph.edges[$0].source + graph.edges[$0].target })
        #expect(throws: VertexNotFound.self) { try graph[name, checked: 1] }
        #expect(throws: VertexNotFound.self) { try graph[name, checkedVertexAt: 3] }
        #expect(throws: VertexNotFound.self) { try graph[name, checkedVertexAt: -1] }
        // Removing the vertex in the last slot moves nothing.
        let lastVertex = graph.vertices[graph.vertexCount - 1]
        #expect(graph.remove(lastVertex) == lastVertex)
        #expect(graph.vertices.allSatisfy { graph[name, of: $0] == "v\($0)" })
        #expect(graph.values(of: name)[0] == "v\(graph.vertices[0])")

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(3, 3)])
        let uw = undirected.addEdgeMap(default: 0)
        let un = undirected.addVertexMap(default: 0)
        for p in 0 ..< undirected.edgeCount {
            let e = undirected.edges[p]
            undirected[uw, ofEdgeAt: p] = 10 * min(e.u, e.v) + max(e.u, e.v)
        }
        for v in undirected.vertices { undirected[un, of: v] = v * v }
        #expect(undirected.remove(0) == 0)
        #expect(undirected.vertices.allSatisfy { undirected[un, of: $0] == $0 * $0 })
        #expect(undirected.edges.indices.map { undirected[uw, ofEdgeAt: $0] } == undirected.edges.map { 10 * min($0.u, $0.v) + max($0.u, $0.v) })
        #expect(undirected.edges.indices.map { undirected[uw, ofEdgeAt: $0] }.sorted() == [12, 23, 33])
    }

    @Test("AM-05 removeAll and removeAllEdges empty the maps and keep them attached")
    func removeAllKeepsMaps() throws {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let w = graph.addEdgeMap(default: 1)
        let r = graph.addVertexMap(default: 2)
        graph[w, ofEdgeAt: 0] = 5
        graph[r, of: 0] = 6
        graph.removeAllEdges()
        #expect(throws: EdgeNotFound.self) { try graph[w, checkedEdgeAt: 0] }
        #expect(graph[r, of: 0] == 6)
        graph.insert(edge: DirectedEdge(from: 1, to: 0))
        #expect(graph[w, ofEdgeAt: 0] == 1)
        graph.removeAll(keepingCapacity: true)
        #expect(throws: VertexNotFound.self) { try graph[r, checked: 0] }
        graph.insert(edge: DirectedEdge(from: 0, to: 1))
        #expect(graph[w, ofEdgeAt: 0] == 1)
        #expect(graph[r, of: 0] == 2 && graph[r, of: 1] == 2)

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        let uw = undirected.addEdgeMap(default: 1)
        let ur = undirected.addVertexMap(default: 2)
        undirected[uw, ofEdgeAt: 0] = 5
        undirected[ur, of: 1] = 6
        undirected.removeAllEdges(keepingCapacity: true)
        #expect(throws: EdgeNotFound.self) { try undirected[uw, checkedEdgeAt: 0] }
        #expect(undirected[ur, of: 1] == 6)
        undirected.removeAll()
        undirected.insert(edge: UndirectedEdge(1, 0))
        #expect(undirected[uw, ofEdgeAt: 0] == 1 && undirected[ur, of: 1] == 2)
    }

    @Test("AM-06 handles: several maps, removeEdgeMap, and a copy that shares then diverges")
    func handlesAndCopies() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let a = graph.addEdgeMap(default: 0)
        let b = graph.addEdgeMap(default: "")
        let c = graph.addVertexMap(default: 0.0)
        #expect(a != graph.addEdgeMap(default: 0))
        graph[a, ofEdgeAt: 0] = 1
        graph[b, ofEdgeAt: 1] = "b"
        graph.removeEdgeMap(a)
        // A later handle still finds its map after an earlier one was removed (its hint is stale).
        #expect(graph[b, ofEdgeAt: 1] == "b")
        graph[c, of: 2] = 2.5
        graph.removeVertexMap(c)
        let d = graph.addVertexMap(default: 9)
        #expect(graph[d, of: 2] == 9)

        var copy = graph
        copy[b, ofEdgeAt: 1] = "changed"
        copy.remove(edge: DirectedEdge(from: 0, to: 1))
        #expect(graph[b, ofEdgeAt: 1] == "b")
        #expect(graph.edgeCount == 2)
        #expect(copy[b, ofEdgeAt: 0] == "changed")
        // Equality ignores the maps.
        var bare = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(bare == graph && bare.hashValue == graph.hashValue)
        _ = bare.addEdgeMap(default: 3)
        #expect(bare == graph)

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        let u = undirected.addEdgeMap(default: 0)
        var undirectedCopy = undirected
        undirectedCopy[u, ofEdgeAt: 0] = 4
        #expect(undirected[u, ofEdgeAt: 0] == 0 && undirectedCopy[u, ofEdgeAt: 0] == 4)
        #expect(undirected == undirectedCopy)
    }

    @Test("AM-07 Codable and conversions carry no maps; the identity conversion keeps them")
    func codingAndConversion() throws {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
        let w = graph.addEdgeMap(default: 1)
        graph[w, ofEdgeAt: 0] = 2
        var decoded = try JSONDecoder().decode(AdjacencyList<Int>.self, from: JSONEncoder().encode(graph))
        #expect(decoded == graph)
        let fresh = decoded.addEdgeMap(default: 7)
        #expect(decoded[fresh, ofEdgeAt: 0] == 7)
        let same = AdjacencyList(graph)
        #expect(same[w, ofEdgeAt: 0] == 2)

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        let uw = undirected.addEdgeMap(default: 1)
        undirected[uw, ofEdgeAt: 0] = 2
        let undirectedDecoded = try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: JSONEncoder().encode(undirected))
        #expect(undirectedDecoded == undirected)
        #expect(UndirectedAdjacencyList(undirected)[uw, ofEdgeAt: 0] == 2)
    }

    @Test("AM-08 values(of:) is a snapshot read by position, like an array")
    func valuesSnapshot() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let w = graph.addEdgeMap(default: 0.0)
        let r = graph.addVertexMap(default: 0)
        for p in 0 ..< graph.edgeCount { graph[w, ofEdgeAt: p] = Double(p) + 0.5 }
        for v in graph.vertices { graph[r, of: v] = v + 100 }
        let values = graph.values(of: w)
        let ranks = graph.values(of: r)
        #expect((0 ..< 3).map { values[$0] } == [0.5, 1.5, 2.5])
        #expect(graph.vertices.map { ranks[graph.vertexIndex(of: $0)] } == [100, 101, 102])
        graph[w, ofEdgeAt: 0] = 9
        graph.remove(edge: DirectedEdge(from: 1, to: 2))
        // The snapshot keeps what it saw.
        #expect((0 ..< 3).map { values[$0] } == [0.5, 1.5, 2.5])
        let now = graph.values(of: w)
        #expect((0 ..< graph.edgeCount).map { now[$0] } == [9, 2.5])
        // An algorithm's weight closure.
        let total = graph.edges.indices.reduce(0.0) { $0 + now[$1] }
        #expect(total == 11.5)

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let uw = undirected.addEdgeMap(default: 2)
        let uv = undirected.addVertexMap(default: 3)
        #expect(undirected.values(of: uw)[1] == 2)
        #expect(undirected.values(of: uv)[2] == 3)
    }

    @Test("AM-09 views read the base's values by vertex; the undirected graph's directed view too")
    func throughViews() throws {
        var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        let r = graph.addVertexMap(default: 0)
        graph[r, of: 1] = 5
        let directed = graph.directedView
        #expect(directed[r, of: 1] == 5)
        #expect(directed[r, of: 0] == 0)
        #expect(throws: VertexNotFound.self) { try directed[r, checked: 2] }
    }
}
