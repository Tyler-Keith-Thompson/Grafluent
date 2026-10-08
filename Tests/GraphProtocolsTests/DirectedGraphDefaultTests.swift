// The default implementations, through minimal conformers that supply only the required members,
// and dispatch: a conformer's own version of a requirement with a default is the one generic code
// calls. Case IDs (DG-Dnn) refer to the catalog in README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing

/// Supplies only what BidirectionalDirectedGraph requires, with neighborhoods that are
/// single-pass sequences.
private struct SequenceSuccessorsGraph: BidirectionalDirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]

    func successors(of vertex: Int) -> AnyIterator<Int> {
        var remaining = edges.filter { $0.source == vertex }.map(\.target)[...]
        return AnyIterator { remaining.popFirst() }
    }

    func predecessors(of vertex: Int) -> AnyIterator<Int> {
        var remaining = edges.filter { $0.target == vertex }.map(\.source)[...]
        return AnyIterator { remaining.popFirst() }
    }

    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func inEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].target == vertex } }
}

/// Supplies only what BidirectionalDirectedGraph requires, with collection neighborhoods.
private struct CollectionNeighborsGraph: BidirectionalDirectedGraph {
    let vertices: [String]
    let edges: [DirectedEdge<String>]

    func successors(of vertex: String) -> [String] { edges.filter { $0.source == vertex }.map(\.target) }
    func predecessors(of vertex: String) -> [String] { edges.filter { $0.target == vertex }.map(\.source) }
    func outEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func inEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].target == vertex } }
}

/// Answers every requirement with a default in its own, deliberately wrong, way.
private struct OverridingGraph: BidirectionalDirectedGraph {
    var vertices: [Int] { [0, 1] }
    var edges: [DirectedEdge<Int>] { [DirectedEdge(from: 0, to: 1)] }
    func successors(of vertex: Int) -> [Int] { vertex == 0 ? [1] : [] }
    func predecessors(of vertex: Int) -> [Int] { vertex == 1 ? [0] : [] }
    func outEdges(of vertex: Int) -> [Int] { vertex == 0 ? [0] : [] }
    func inEdges(of vertex: Int) -> [Int] { vertex == 1 ? [0] : [] }
    func source(ofEdgeAt position: Int) -> Int { 600 }
    func target(ofEdgeAt position: Int) -> Int { 700 }
    var vertexIndexBound: Int? { 800 }
    func vertexIndex(of vertex: Int) -> Int { 900 }
    func vertex(atIndex index: Int) -> Int { 1000 }
    var vertexCount: Int { 100 }
    var edgeCount: Int { 200 }
    func contains(_ vertex: Int) -> Bool { vertex == 42 }
    func contains(edge: DirectedEdge<Int>) -> Bool { edge.source == 42 }
    func outDegree(of vertex: Int) -> Int { 300 }
    func inDegree(of vertex: Int) -> Int { 400 }
    func degree(of vertex: Int) -> Int { 500 }
}

@Suite("DirectedGraph default implementations")
struct DirectedGraphDefaultTests {
    @Test("DG-D06 without vertex indices, asking for one traps", .tags(.precondition))
    func noIndices() async {
        await #expect(processExitsWith: .failure) {
            let g: any DirectedGraph<Int> = SequenceSuccessorsGraph(vertices: [0], edges: [])
            _ = g.vertexIndex(of: 0)
        }
        await #expect(processExitsWith: .failure) {
            let g: any DirectedGraph<Int> = SequenceSuccessorsGraph(vertices: [0], edges: [])
            _ = g.vertex(atIndex: 0)
        }
    }

    @Test("DG-D01 the defaults from vertices, edges and single-pass neighborhoods", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func sequenceDefaults(_ fixture: DirectedFixture<Int>) {
        func check<G: BidirectionalDirectedGraph<Int>>(_ g: G) {
            #expect(g.vertexCount == fixture.vertexCount)
            #expect(g.edgeCount == fixture.edges.count)
            for v in fixture.vertexSet {
                #expect(g.contains(v))
                let out = fixture.edges.filter { $0.source == v }.count
                let into = fixture.edges.filter { $0.target == v }.count
                #expect(g.outDegree(of: v) == out)
                #expect(g.inDegree(of: v) == into)
                #expect(g.degree(of: v) == out + into)
                for w in fixture.vertexSet {
                    #expect(g.contains(edge: DirectedEdge(from: v, to: w)) == fixture.edges.contains(DirectedEdge(from: v, to: w)))
                }
            }
            #expect(!g.contains(-1))
            #expect(!g.contains(edge: DirectedEdge(from: -1, to: -1)))
            // Endpoints default to edges[position], and there are no vertex indices by default.
            for e in g.edges.indices {
                #expect(g.source(ofEdgeAt: e) == g.edges[e].source)
                #expect(g.target(ofEdgeAt: e) == g.edges[e].target)
            }
            #expect(g.vertexIndexBound == nil)
            for v in fixture.vertexSet {
                #expect(!g.contains(edge: DirectedEdge(from: v, to: -1)))
                #expect(!g.contains(edge: DirectedEdge(from: -1, to: v)))
            }
        }
        check(SequenceSuccessorsGraph(vertices: Array(fixture.vertexSet), edges: fixture.edges))
    }

    @Test("DG-D02 the bidirectional defaults from collection neighborhoods", .tags(.fixture), arguments: DirectedFixture<String>.all)
    func collectionDefaults(_ fixture: DirectedFixture<String>) {
        func check<G: BidirectionalDirectedGraph<String>>(_ g: G) {
            for v in fixture.vertexSet {
                let out = fixture.edges.filter { $0.source == v }.count
                let into = fixture.edges.filter { $0.target == v }.count
                #expect(g.outDegree(of: v) == out)
                #expect(g.inDegree(of: v) == into)
                #expect(g.degree(of: v) == out + into)
            }
            #expect(!g.contains("∅"))
            #expect(!g.contains(edge: DirectedEdge(from: "∅", to: "∅")))
        }
        check(CollectionNeighborsGraph(vertices: Array(fixture.vertexSet), edges: fixture.edges))
    }

    @Test("DG-D03 a self-loop counts twice in the default degree", .tags(.selfLoops))
    func selfLoopDegree() {
        func degree(_ g: some BidirectionalDirectedGraph<String>, of v: String) -> Int { g.degree(of: v) }
        let g = CollectionNeighborsGraph(vertices: ["a"], edges: [DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "a", to: "a")])
        #expect(degree(g, of: "a") == 4)
    }

    @Test("DG-D04 the default contains(edge:) checks both endpoints before reading successors")
    func defaultContainsEdgeChecksEndpoints() {
        // successors(of:) of a vertex that is not there would list the edge's target here.
        let g = SequenceSuccessorsGraph(vertices: [0], edges: [DirectedEdge(from: 5, to: 0), DirectedEdge(from: 0, to: 5)])
        func contains(_ g: some DirectedGraph<Int>, _ edge: DirectedEdge<Int>) -> Bool { g.contains(edge: edge) }
        #expect(!contains(g, DirectedEdge(from: 5, to: 0)))
        #expect(!contains(g, DirectedEdge(from: 0, to: 5)))
    }

    @Test("DG-D05 generic code calls a conformer's own version of every requirement with a default")
    func dispatch() {
        func answers<G: BidirectionalDirectedGraph<Int>>(_ g: G) -> [Int] where G.Edges.Index == Int {
            [g.vertexCount, g.edgeCount, g.contains(42) ? 1 : 0, g.contains(edge: DirectedEdge(from: 42, to: 0)) ? 1 : 0,
             g.outDegree(of: 0), g.inDegree(of: 0), g.degree(of: 0), g.source(ofEdgeAt: 0), g.target(ofEdgeAt: 0),
             g.vertexIndexBound ?? -1, g.vertexIndex(of: 0), g.vertex(atIndex: 0)]
        }
        // Through a second generic layer, which only knows DirectedGraph.
        func base(_ g: some DirectedGraph<Int>) -> [Int] {
            [g.vertexCount, g.edgeCount, g.outDegree(of: 0), g.vertexIndexBound ?? -1, g.vertexIndex(of: 0), g.vertex(atIndex: 0)]
        }
        func outer(_ g: some BidirectionalDirectedGraph<Int>) -> [Int] { base(g) }
        func existential(_ g: any BidirectionalDirectedGraph<Int>) -> [Int] {
            [g.vertexCount, g.edgeCount, g.contains(42) ? 1 : 0, g.contains(edge: DirectedEdge(from: 42, to: 0)) ? 1 : 0,
             g.outDegree(of: 0), g.inDegree(of: 0), g.degree(of: 0), g.vertexIndexBound ?? -1, g.vertexIndex(of: 0), g.vertex(atIndex: 0)]
        }
        #expect(answers(OverridingGraph()) == [100, 200, 1, 1, 300, 400, 500, 600, 700, 800, 900, 1000])
        #expect(outer(OverridingGraph()) == [100, 200, 300, 800, 900, 1000])
        #expect(existential(OverridingGraph()) == [100, 200, 1, 1, 300, 400, 500, 800, 900, 1000])
    }
}
