// The Graph default implementations, through minimal conformers that supply only the required
// members, and dispatch: a conformer's own version of a requirement with a default is the one
// generic code calls. Case IDs (UG-Tnn) refer to the catalog in README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing

/// Supplies only what Graph requires, with neighborhoods that are single-pass sequences.
private struct SequenceNeighborsGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]

    func neighbors(of vertex: Int) -> MinimalSequence<Int> {
        var ends: [Int] = []
        for e in edges {
            if e.u == vertex { ends.append(e.v) }
            if e.v == vertex { ends.append(e.u) }
        }
        return MinimalSequence(elements: ends)
    }

    func incidentEdges(of vertex: Int) -> [Int] {
        var positions: [Int] = []
        for (k, e) in edges.enumerated() {
            if e.u == vertex { positions.append(k) }
            if e.v == vertex { positions.append(k) }
        }
        return positions
    }
}

/// Supplies only what Graph requires, with collection neighborhoods and String vertices.
private struct CollectionNeighborsGraph: Graph {
    let vertices: [String]
    let edges: [UndirectedEdge<String>]

    func neighbors(of vertex: String) -> [String] {
        var ends: [String] = []
        for e in edges {
            if e.u == vertex { ends.append(e.v) }
            if e.v == vertex { ends.append(e.u) }
        }
        return ends
    }

    func incidentEdges(of vertex: String) -> [Int] {
        var positions: [Int] = []
        for (k, e) in edges.enumerated() {
            if e.u == vertex { positions.append(k) }
            if e.v == vertex { positions.append(k) }
        }
        return positions
    }
}

/// Answers every requirement with a default in its own, deliberately wrong, way.
private struct OverridingGraph: Graph {
    var vertices: [Int] { [0, 1] }
    var edges: [UndirectedEdge<Int>] { [UndirectedEdge(0, 1)] }
    func neighbors(of vertex: Int) -> [Int] { vertex == 0 ? [1] : [0] }
    func incidentEdges(of vertex: Int) -> [Int] { [0] }
    func oppositeVertex(to vertex: Int, acrossEdgeAt position: Int) -> Int { 600 }
    var vertexIndexBound: Int? { 800 }
    func vertexIndex(of vertex: Int) -> Int { 900 }
    func vertex(atIndex index: Int) -> Int { 1000 }
    func neighborIndices(ofIndex index: Int) -> [Int] { [1100] }
    var vertexCount: Int { 100 }
    var edgeCount: Int { 200 }
    func contains(_ vertex: Int) -> Bool { vertex == 42 }
    func contains(edge: UndirectedEdge<Int>) -> Bool { edge.u == 42 }
    func degree(of vertex: Int) -> Int { 300 }
}

@Suite("Graph default implementations")
struct GraphDefaultTests {
    @Test("UG-T06 without vertex indices, asking for one traps", .tags(.precondition))
    func noIndices() async {
        await #expect(processExitsWith: .failure) {
            let g: any Graph<Int> = SequenceNeighborsGraph(vertices: [0], edges: [])
            _ = g.vertexIndex(of: 0)
        }
        await #expect(processExitsWith: .failure) {
            let g: any Graph<Int> = SequenceNeighborsGraph(vertices: [0], edges: [])
            _ = g.vertex(atIndex: 0)
        }
    }

    @Test("UG-T06 the defaults from vertices, edges and single-pass neighborhoods", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func sequenceDefaults(_ fixture: UndirectedFixture<Int>) {
        func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
            #expect(g.vertexCount == fixture.vertexCount)
            #expect(g.edgeCount == fixture.pseudographEdgeCount)
            for v in fixture.vertexSet {
                #expect(g.contains(v))
                // A self-loop's two ends both count.
                #expect(g.degree(of: v) == fixture.pseudographDegree[v])
                for w in fixture.vertexSet {
                    #expect(g.contains(edge: UndirectedEdge(v, w)) == fixture.edges.contains(UndirectedEdge(v, w)))
                }
            }
            #expect(!g.contains(-1))
            #expect(!g.contains(edge: UndirectedEdge(-1, -1)))
            // The far end defaults to edges[position], and there are no vertex indices by default.
            for e in g.edges.indices {
                #expect(g.oppositeVertex(to: g.edges[e].u, acrossEdgeAt: e) == g.edges[e].v)
                #expect(g.oppositeVertex(to: g.edges[e].v, acrossEdgeAt: e) == g.edges[e].u)
            }
            #expect(g.vertexIndexBound == nil)
            for v in fixture.vertexSet {
                #expect(!g.contains(edge: UndirectedEdge(v, -1)))
                #expect(!g.contains(edge: UndirectedEdge(-1, v)))
            }
        }
        check(SequenceNeighborsGraph(vertices: Array(fixture.vertexSet), edges: fixture.edges))
    }

    @Test("UG-T06 the defaults from collection neighborhoods", .tags(.fixture), arguments: UndirectedFixture<String>.all)
    func collectionDefaults(_ fixture: UndirectedFixture<String>) {
        func check<G: Graph<String>>(_ g: G) {
            for v in fixture.vertexSet {
                #expect(g.degree(of: v) == fixture.pseudographDegree[v])
            }
            #expect(!g.contains("∅"))
            #expect(!g.contains(edge: UndirectedEdge("∅", "∅")))
            #expect(g.vertexIndexBound == nil)
        }
        check(CollectionNeighborsGraph(vertices: Array(fixture.vertexSet), edges: fixture.edges))
    }

    @Test("UG-T06 a self-loop counts twice in the default degree", .tags(.selfLoops))
    func selfLoopDegree() {
        func degree(_ g: some Graph<String>, of v: String) -> Int { g.degree(of: v) }
        let g = CollectionNeighborsGraph(vertices: ["a"], edges: [UndirectedEdge("a", "a"), UndirectedEdge("a", "a")])
        #expect(degree(g, of: "a") == 4)
    }

    @Test("UG-T06 the default contains(edge:) checks both endpoints before reading neighbors")
    func defaultContainsEdgeChecksEndpoints() {
        // neighbors(of:) of a vertex that is not there would list the edge's other end here.
        let g = SequenceNeighborsGraph(vertices: [0], edges: [UndirectedEdge(5, 0)])
        func contains(_ g: some Graph<Int>, _ edge: UndirectedEdge<Int>) -> Bool { g.contains(edge: edge) }
        #expect(!contains(g, UndirectedEdge(5, 0)))
        #expect(!contains(g, UndirectedEdge(0, 5)))
    }

    @Test("UG-T06 the default neighborIndices maps neighbors through vertexIndex")
    func defaultNeighborIndices() {
        func indices<G: Graph<Int>>(_ g: G, of v: Int) -> [Int] { Array(g.neighborIndices(ofIndex: g.vertexIndex(of: v))) }
        // The pseudograph supplies indices but not neighborIndices.
        let g = ReferencePseudograph(vertices: [10, 20, 30], edges: [UndirectedEdge(30, 10), UndirectedEdge(10, 10)])
        #expect(indices(g, of: 10) == [2, 0, 0])
        #expect(indices(g, of: 30) == [0])
        #expect(indices(g, of: 20) == [])
    }

    @Test("UG-T07 generic code calls a conformer's own version of every requirement with a default")
    func dispatch() {
        func answers<G: Graph<Int>>(_ g: G) -> [Int] where G.Edges.Index == Int {
            [g.vertexCount, g.edgeCount, g.contains(42) ? 1 : 0, g.contains(edge: UndirectedEdge(42, 0)) ? 1 : 0,
             g.degree(of: 0), g.oppositeVertex(to: 0, acrossEdgeAt: 0), g.vertexIndexBound ?? -1, g.vertexIndex(of: 0),
             g.vertex(atIndex: 0)] + Array(g.neighborIndices(ofIndex: 0))
        }
        // Through a second generic layer.
        func base(_ g: some Graph<Int>) -> [Int] {
            [g.vertexCount, g.edgeCount, g.degree(of: 0), g.contains(edge: UndirectedEdge(42, 0)) ? 1 : 0, g.vertexIndexBound ?? -1, g.vertexIndex(of: 0), g.vertex(atIndex: 0)]
        }
        func outer(_ g: some Graph<Int>) -> [Int] { base(g) }
        func existential(_ g: any Graph<Int>) -> [Int] {
            [g.vertexCount, g.edgeCount, g.contains(42) ? 1 : 0, g.contains(edge: UndirectedEdge(42, 0)) ? 1 : 0,
             g.degree(of: 0), g.vertexIndexBound ?? -1, g.vertexIndex(of: 0), g.vertex(atIndex: 0)] + g.neighborIndices(ofIndex: 0).map { $0 }
        }
        #expect(answers(OverridingGraph()) == [100, 200, 1, 1, 300, 600, 800, 900, 1000, 1100])
        #expect(outer(OverridingGraph()) == [100, 200, 300, 1, 800, 900, 1000])
        #expect(existential(OverridingGraph()) == [100, 200, 1, 1, 300, 800, 900, 1000, 1100])
    }
}
