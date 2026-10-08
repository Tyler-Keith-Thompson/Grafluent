// Inserting and removing vertices and edges, self-loops among them, with the Graph laws checked
// after each step. Removal moves the last vertex and the last edge into the holes it leaves, so
// these cases reach the moved records. Case IDs (UG-Rnn) refer to the protocol catalog; see
// Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("UndirectedAdjacencyList mutation")
struct UndirectedAdjacencyListMutationTests {
    @Test("UG-R07 removing petgraph's hub leaves one edge")
    func removeHub() {
        var graph = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.petgraphUndirected.edges)
        #expect(graph.remove(0) == 0)
        func check<G: Graph<Int>>(_ g: G) {
            // petgraph: node_count() == 3, edge_count() == 1, neighbors(b) == [c].
            #expect(g.vertexCount == 3)
            #expect(g.edgeCount == 1)
            #expect(Array(g.edges) == [UndirectedEdge(1, 2)])
            #expect(Array(g.neighbors(of: 1)) == [2])
            #expect(Array(g.neighbors(of: 3)) == [])
            #expect(!g.contains(edge: UndirectedEdge(0, 1)))
            #expect(!g.contains(edge: UndirectedEdge(3, 0)))
            #expect(!g.contains(edge: UndirectedEdge(0, 0)))
            #expect(g.contains(edge: UndirectedEdge(2, 1)))
        }
        check(graph)
    }

    @Test("UG-R08 removing a vertex with an incident self-loop", .tags(.selfLoops))
    func removeVertexWithLoop() {
        var graph = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.loopAndPath.edges)
        #expect(graph.remove(0) == 0)
        #expect(graph.remove(0) == nil)
        func check<G: Graph<Int>>(_ g: G) {
            // NetworkX: edges [(1, 2)].
            #expect(Set(g.vertices) == [1, 2])
            #expect(Array(g.edges) == [UndirectedEdge(1, 2)])
            #expect(g.degree(of: 1) == 1)
            #expect(g.degree(of: 2) == 1)
        }
        check(graph)
    }

    @Test("UG-R09 removing a loop, then a vertex so that a slot with a loop moves", .tags(.selfLoops))
    func removeLoopThenMoveLoopedSlot() {
        func laws<G: Graph>(_ g: G) {
            var degreeSum = 0
            var positionCounts: [G.Edges.Index: Int] = [:]
            for v in g.vertices {
                let neighbors = Array(g.neighbors(of: v))
                let incident = Array(g.incidentEdges(of: v))
                #expect(g.degree(of: v) == neighbors.count)
                #expect(incident.count == neighbors.count)
                #expect(incident.map { g.oppositeVertex(to: v, acrossEdgeAt: $0) } == neighbors)
                for e in incident {
                    #expect(g.edges[e].u == v || g.edges[e].v == v)
                    positionCounts[e, default: 0] += 1
                }
                for w in g.vertices {
                    #expect(g.contains(edge: UndirectedEdge(v, w)) == neighbors.contains(w))
                }
                if let n = g.vertexIndexBound {
                    #expect(g.vertexIndex(of: v) < n)
                    #expect(g.vertex(atIndex: g.vertexIndex(of: v)) == v)
                    #expect(Array(g.neighborIndices(ofIndex: g.vertexIndex(of: v))) == neighbors.map { g.vertexIndex(of: $0) })
                }
                degreeSum += neighbors.count
            }
            #expect(degreeSum == 2 * g.edgeCount)
            #expect(Set(positionCounts.keys) == Set(g.edges.indices))
            #expect(positionCounts.values.allSatisfy { $0 == 2 })
            #expect(g.vertices.map { g.vertexIndex(of: $0) } == Array(0 ..< g.vertexCount))
        }
        var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(2, 2)])
        laws(graph)
        #expect(graph.remove(edge: UndirectedEdge(0, 0)) == UndirectedEdge(0, 0))
        #expect(graph.edgeCount == 3)
        #expect(graph.degree(of: 0) == 2)
        #expect(Array(graph.neighbors(of: 0)).sorted() == [1, 2])
        laws(graph)
        #expect(graph.remove(1) == 1)
        #expect(graph.edgeCount == 2)
        #expect(graph.degree(of: 2) == 3)
        #expect(Array(graph.neighbors(of: 2)).sorted() == [0, 2, 2])
        laws(graph)
        #expect(graph == UndirectedAdjacencyList(edges: [UndirectedEdge(2, 2), UndirectedEdge(2, 0)]))
    }

    @Test("UG-R10 inserting an edge written the other way round finds the stored one")
    func reversedDuplicateInsert() {
        var graph = UndirectedAdjacencyList<Int>()
        let first = graph.insert(edge: UndirectedEdge(0, 1))
        #expect(first.inserted)
        #expect(first.memberAfterInsert.u == 0)
        let second = graph.insert(edge: UndirectedEdge(1, 0))
        #expect(!second.inserted)
        #expect(second.memberAfterInsert == UndirectedEdge(0, 1))
        #expect(second.memberAfterInsert.u == 0)
        #expect(second.memberAfterInsert.v == 1)
        #expect(graph.edgeCount == 1)
        let removed = graph.remove(edge: UndirectedEdge(1, 0))
        #expect(removed == UndirectedEdge(0, 1))
        #expect(removed?.u == 0)
        #expect(removed?.v == 1)
        #expect(graph.edgeCount == 0)
        #expect(graph.vertexCount == 2)
        #expect(graph.remove(edge: UndirectedEdge(1, 0)) == nil)
    }

    @Test("UG-R10 a repeated self-loop is inserted once", .tags(.selfLoops))
    func repeatedLoop() {
        var graph = UndirectedAdjacencyList<String>()
        #expect(graph.insert(edge: UndirectedEdge("a", "a")).inserted)
        #expect(!graph.insert(edge: UndirectedEdge("a", "a")).inserted)
        #expect(graph.edgeCount == 1)
        #expect(graph.degree(of: "a") == 2)
    }

    @Test("UG-R11 after each edge removal the positions are 0..<edgeCount and the incidence laws hold", arguments: UndirectedFixture<Int>.nonempty)
    func positionsAfterRemoval(_ fixture: UndirectedFixture<Int>) {
        func laws<G: Graph>(_ g: G) where G.Edges.Index == Int {
            #expect(Array(g.edges.indices) == Array(0 ..< g.edgeCount))
            var positionCounts: [Int: Int] = [:]
            for v in g.vertices {
                let incident = Array(g.incidentEdges(of: v))
                // UG-L16: each incident edge has v as an endpoint, and the far ends are the neighbors.
                for e in incident { #expect(g.edges[e].u == v || g.edges[e].v == v) }
                #expect(incident.map { g.oppositeVertex(to: v, acrossEdgeAt: $0) } == Array(g.neighbors(of: v)))
                for e in incident { positionCounts[e, default: 0] += 1 }
            }
            // UG-L17: every position twice, once per end.
            #expect(Set(positionCounts.keys) == Set(g.edges.indices))
            #expect(positionCounts.values.allSatisfy { $0 == 2 })
        }
        var graph = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        // Remove from the front, so the last edge moves into each hole.
        while let first = graph.edges.first {
            #expect(graph.remove(edge: first) == first)
            #expect(!graph.contains(edge: first))
            laws(graph)
        }
        #expect(graph.vertexCount == fixture.vertexCount)
    }

    @Test("UG-R09 removing every vertex in turn keeps the laws", arguments: UndirectedFixture<Int>.nonempty)
    func removeEveryVertex(_ fixture: UndirectedFixture<Int>) {
        func handshake<G: Graph>(_ g: G) -> Bool {
            g.vertices.map { g.degree(of: $0) }.reduce(0, +) == 2 * g.edgeCount
        }
        var graph = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        var remaining = Set(fixture.edges)
        for v in fixture.vertexSet.sorted() {
            #expect(graph.remove(v) == v)
            remaining = remaining.filter { $0.u != v && $0.v != v }
            #expect(Set(graph.edges) == remaining)
            #expect(graph.edgeCount == remaining.count)
            #expect(handshake(graph))
            for w in graph.vertices {
                let expected = remaining.map { ($0.u == w ? 1 : 0) + ($0.v == w ? 1 : 0) }.reduce(0, +)
                #expect(graph.degree(of: w) == expected)
                #expect(graph.incidentEdges(of: w).map { graph.oppositeVertex(to: w, acrossEdgeAt: $0) } == Array(graph.neighbors(of: w)))
            }
        }
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }

    @Test("inserting a vertex returns the stored instance; removeAll and removeAllEdges")
    func vertexInsertionAndClearing() {
        var graph = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.k3WithLoop.edges)
        #expect(graph.insert(7) == (true, 7))
        #expect(graph.insert(7) == (false, 7))
        #expect(graph.vertexCount == 4)
        graph.removeAllEdges()
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 0)
        for v in 0 ..< 3 { #expect(graph.degree(of: v) == 0) }
        graph.insert(edge: UndirectedEdge(1, 7))
        #expect(graph.degree(of: 7) == 1)
        graph.removeAll(keepingCapacity: true)
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
        graph.reserveCapacity(vertexCount: 10, edgeCount: 20)
        #expect(graph == UndirectedAdjacencyList())
    }
}
