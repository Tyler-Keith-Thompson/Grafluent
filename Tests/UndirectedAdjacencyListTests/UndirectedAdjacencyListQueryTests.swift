// Queries on named graphs, read through a generic function declared inside each test, so these
// check the Graph conformance. Expected values come from NetworkX and petgraph; where NetworkX lists
// a self-loop's vertex once among its neighbors, Grafluent lists it once per end (twice). Case IDs
// (UG-Rnn) refer to the protocol catalog; see Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("UndirectedAdjacencyList queries", .tags(.fixture))
struct UndirectedAdjacencyListQueryTests {
    @Test("UG-R01 the empty graph")
    func empty() {
        func check(_ g: some Graph<Int>) {
            #expect(g.vertexCount == 0)
            #expect(g.edgeCount == 0)
            #expect(!g.contains(0))
            #expect(!g.contains(edge: UndirectedEdge(0, 0)))
            #expect(Array(g.vertices).isEmpty)
            #expect(Array(g.edges).isEmpty)
            #expect(g.vertexIndexBound == 0)
        }
        let fixture = UndirectedFixture<Int>.empty
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList<Int>())
    }

    @Test("UG-R02 one vertex, no edges")
    func trivial() {
        func check(_ g: some Graph<Int>) {
            #expect(Array(g.neighbors(of: 0)) == [])
            #expect(g.degree(of: 0) == 0)
            #expect(Array(g.incidentEdges(of: 0)) == [])
            #expect(g.vertexCount == 1)
            #expect(!g.contains(edge: UndirectedEdge(0, 0)))
        }
        let fixture = UndirectedFixture<Int>.trivial
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("UG-R03 a single self-loop: one edge, two ends at its vertex", .tags(.selfLoops))
    func singleSelfLoop() {
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(Array(g.edges) == [UndirectedEdge(0, 0)])
            #expect(g.edgeCount == 1)
            // NetworkX lists [0] with degree 2; here the neighborhood has the degree's length.
            #expect(Array(g.neighbors(of: 0)) == [0, 0])
            #expect(Array(g.incidentEdges(of: 0)) == [0, 0])
            #expect(g.degree(of: 0) == 2)
            #expect(g.contains(edge: UndirectedEdge(0, 0)))
            #expect(g.oppositeVertex(to: 0, acrossEdgeAt: 0) == 0)
        }
        let fixture = UndirectedFixture<Int>.singleSelfLoop
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("UG-R04 the triangle K₃, as NetworkX's BaseGraphTester checks it")
    func k3() {
        func check<G: Graph<Int>>(_ g: G) {
            #expect(Array(g.neighbors(of: 0)).sorted() == [1, 2])
            #expect(Set(g.incidentEdges(of: 0).map { g.edges[$0] }) == [UndirectedEdge(0, 1), UndirectedEdge(0, 2)])
            for v in 0 ..< 3 { #expect(g.degree(of: v) == 2) }
            #expect(g.edgeCount == 3)
            #expect(g.contains(edge: UndirectedEdge(1, 0)))
            #expect(g.contains(edge: UndirectedEdge(0, 1)))
            #expect(!g.contains(edge: UndirectedEdge(0, -1)))
            #expect(!g.contains(edge: UndirectedEdge(0, 0)))
        }
        let fixture = UndirectedFixture<Int>.k3
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("UG-R05 K₃ with a self-loop", .tags(.selfLoops))
    func k3WithLoop() {
        func check<G: Graph<Int>>(_ g: G) {
            #expect([g.degree(of: 0), g.degree(of: 1), g.degree(of: 2)] == [4, 2, 2])
            #expect(g.edgeCount == 4)
            #expect(Array(g.neighbors(of: 0)).sorted() == [0, 0, 1, 2])
            #expect(Array(g.neighbors(of: 1)).sorted() == [0, 2])
        }
        let fixture = UndirectedFixture<Int>.k3WithLoop
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("UG-R06 a loop on the end of a path, in insertion order", .tags(.selfLoops))
    func loopAndPath() {
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            // NetworkX: neighbors(0) == [0, 1], degree(0) == 3.
            #expect(Array(g.neighbors(of: 0)) == [0, 0, 1])
            #expect(Array(g.incidentEdges(of: 0)) == [0, 0, 1])
            #expect([g.degree(of: 0), g.degree(of: 1), g.degree(of: 2)] == [3, 2, 1])
            #expect(g.vertices.map { g.degree(of: $0) }.reduce(0, +) == 6)
            #expect(Array(g.neighbors(of: 1)) == [0, 2])
            #expect(Array(g.incidentEdges(of: 1)) == [1, 2])
        }
        let fixture = UndirectedFixture<Int>.loopAndPath
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("UG-R07 petgraph's undirected graph: repeats in either orientation collapse, the loop stays")
    func petgraphUndirected() {
        func check<G: Graph<Int>>(_ g: G) {
            #expect(g.edgeCount == 5)
            #expect([g.degree(of: 0), g.degree(of: 1), g.degree(of: 2), g.degree(of: 3)] == [5, 2, 2, 1])
            #expect(Array(g.neighbors(of: 1)).sorted() == [0, 2])
            #expect(g.contains(edge: UndirectedEdge(0, 1)))
            #expect(g.contains(edge: UndirectedEdge(3, 0)))
            #expect(g.contains(edge: UndirectedEdge(0, 0)))
            for e in g.edges {
                #expect(g.contains(edge: e))
                #expect(g.contains(edge: UndirectedEdge(e.v, e.u)))
            }
        }
        let fixture = UndirectedFixture<Int>.petgraphUndirected
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("UG-R12 the Petersen and cube graphs")
    func petersenAndCube() {
        func check<G: Graph<Int>>(_ g: G, vertices: Int, edges: Int, expected: Set<UndirectedEdge<Int>>) {
            #expect(g.vertexCount == vertices)
            #expect(g.edgeCount == edges)
            for v in g.vertices { #expect(g.degree(of: v) == 3) }
            #expect(Set(g.edges) == expected)
        }
        let petersen = UndirectedFixture<Int>.petersen
        let cube = UndirectedFixture<Int>.cube
        check(UndirectedAdjacencyList(edges: petersen.edges), vertices: 10, edges: 15, expected: Set(petersen.edges))
        check(UndirectedAdjacencyList(edges: cube.edges), vertices: 8, edges: 12, expected: Set(cube.edges))
    }

    @Test("UG-R13 Zachary's karate club")
    func karate() {
        func check<G: Graph<Int>>(_ g: G) {
            #expect(g.vertexCount == 34)
            #expect(g.edgeCount == 78)
            let expected = [16, 9, 10, 6, 3, 4, 4, 4, 5, 2, 3, 1, 2, 5, 2, 2, 2, 2, 2, 3, 2, 2, 2, 5, 3, 3, 2, 4, 3, 4, 4, 6, 12, 17]
            #expect((0 ..< 34).map { g.degree(of: $0) } == expected)
        }
        check(UndirectedAdjacencyList(edges: UndirectedFixture<Int>.karate.edges))
    }

    @Test("UG-R14 isolated vertices")
    func isolatedVertices() {
        func check<G: Graph<Int>>(_ g: G) {
            #expect(g.vertexCount == 10)
            #expect(g.edgeCount == 0)
            for v in 0 ..< 10 {
                #expect(g.degree(of: v) == 0)
                #expect(Array(g.neighbors(of: v)).isEmpty)
            }
        }
        let fixture = UndirectedFixture<Int>.isolatedVertices
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(UndirectedAdjacencyList(vertices: 0 ..< 10))
    }

    @Test("UG-R11 edge positions are 0..<edgeCount", arguments: UndirectedFixture<Int>.all)
    func positions(_ fixture: UndirectedFixture<Int>) {
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(Array(g.edges.indices) == Array(0 ..< g.edgeCount))
        }
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }
}
