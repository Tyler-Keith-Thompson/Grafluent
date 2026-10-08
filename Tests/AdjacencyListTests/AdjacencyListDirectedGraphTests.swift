// AdjacencyList as a DirectedGraph and a BidirectionalDirectedGraph. Every value is read through
// a generic function declared inside the test, so these check the conformance, not the concrete
// members. Case IDs (DG-Lnn, DG-Rnn) refer to the protocol catalog; see
// Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList as a DirectedGraph", .tags(.conformance))
struct AdjacencyListDirectedGraphTests {
    @Test("DG-L01 – L09, L14, L15, L18 the DirectedGraph laws", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func laws(_ fixture: DirectedFixture<Int>) {
        func check<G: DirectedGraph>(_ g: G, absent: G.Vertex) {
            let vertices = Array(g.vertices)
            let edges = Array(g.edges)
            let vertexSet = Set(vertices)
            // L01, L02: counts, and vertices are distinct.
            #expect(g.vertexCount == vertices.count)
            #expect(vertexSet.count == g.vertexCount)
            #expect(g.edgeCount == edges.count)
            // L03: every vertex is contained, and every endpoint is a vertex.
            for v in vertices { #expect(g.contains(v)) }
            for e in edges {
                #expect(vertexSet.contains(e.source))
                #expect(vertexSet.contains(e.target))
            }
            var outDegreeSum = 0
            for v in vertices {
                let successors = Array(g.successors(of: v))
                // L04: the successors are the targets of the edges leaving v, repeats included.
                var fromSuccessors: [G.Vertex: Int] = [:]
                for w in successors { fromSuccessors[w, default: 0] += 1 }
                var fromEdges: [G.Vertex: Int] = [:]
                for e in edges where e.source == v { fromEdges[e.target, default: 0] += 1 }
                #expect(fromSuccessors == fromEdges)
                // L05: the out-degree is the number of successors.
                #expect(g.outDegree(of: v) == successors.count)
                // L18: asking again gives the same sequence.
                #expect(Array(g.successors(of: v)) == successors)
                // L14: a self-loop puts v among its own successors.
                #expect(successors.contains(v) == edges.contains(DirectedEdge(from: v, to: v)))
                // L15: a simple graph lists each successor once.
                #expect(Set(successors).count == successors.count)
                outDegreeSum += g.outDegree(of: v)
            }
            // L06: the out-degrees sum to the edge count.
            #expect(outDegreeSum == g.edgeCount)
            // L07: contains(edge:) agrees with edges and with successors, for every pair.
            let edgeSet = Set(edges)
            for u in vertices {
                let successors = Array(g.successors(of: u))
                for v in vertices {
                    let edge = DirectedEdge(from: u, to: v)
                    #expect(g.contains(edge: edge) == edgeSet.contains(edge))
                    #expect(g.contains(edge: edge) == successors.contains(v))
                }
            }
            // L08, L09: absent vertices are not contained, and asking does not trap.
            #expect(!g.contains(absent))
            #expect(!g.contains(edge: DirectedEdge(from: absent, to: absent)))
            for v in vertices {
                #expect(!g.contains(edge: DirectedEdge(from: v, to: absent)))
                #expect(!g.contains(edge: DirectedEdge(from: absent, to: v)))
            }
            // L15: a simple graph has no repeated edges.
            #expect(edgeSet.count == g.edgeCount)
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges), absent: -1)
    }

    @Test("DG-L01 – L09 the DirectedGraph laws with String vertices", .tags(.fixture), arguments: DirectedFixture<String>.all)
    func lawsWithStrings(_ fixture: DirectedFixture<String>) {
        func check<G: DirectedGraph>(_ g: G, absent: G.Vertex) {
            let vertices = Array(g.vertices)
            let edges = Array(g.edges)
            #expect(g.vertexCount == vertices.count)
            #expect(Set(vertices).count == g.vertexCount)
            #expect(g.edgeCount == edges.count)
            var outDegreeSum = 0
            for v in vertices {
                #expect(g.contains(v))
                let successors = Array(g.successors(of: v))
                var fromSuccessors: [G.Vertex: Int] = [:]
                for w in successors { fromSuccessors[w, default: 0] += 1 }
                var fromEdges: [G.Vertex: Int] = [:]
                for e in edges where e.source == v { fromEdges[e.target, default: 0] += 1 }
                #expect(fromSuccessors == fromEdges)
                #expect(g.outDegree(of: v) == successors.count)
                outDegreeSum += successors.count
                for w in vertices {
                    #expect(g.contains(edge: DirectedEdge(from: v, to: w)) == successors.contains(w))
                }
            }
            #expect(outDegreeSum == g.edgeCount)
            #expect(!g.contains(absent))
            #expect(!g.contains(edge: DirectedEdge(from: absent, to: absent)))
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges), absent: "∅")
    }

    @Test("DG-L10 – L14 the BidirectionalDirectedGraph laws", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func bidirectionalLaws(_ fixture: DirectedFixture<Int>) {
        func check<G: BidirectionalDirectedGraph>(_ g: G) {
            let vertices = Array(g.vertices)
            let edges = Array(g.edges)
            var inDegreeSum = 0
            var degreeSum = 0
            for v in vertices {
                let predecessors = Array(g.predecessors(of: v))
                // L10: the predecessors are the sources of the edges entering v, repeats included.
                var fromPredecessors: [G.Vertex: Int] = [:]
                for u in predecessors { fromPredecessors[u, default: 0] += 1 }
                var fromEdges: [G.Vertex: Int] = [:]
                for e in edges where e.target == v { fromEdges[e.source, default: 0] += 1 }
                #expect(fromPredecessors == fromEdges)
                // L11, L12: degrees.
                #expect(g.inDegree(of: v) == predecessors.count)
                #expect(g.degree(of: v) == g.outDegree(of: v) + g.inDegree(of: v))
                // L14: a self-loop puts v among its own predecessors.
                #expect(predecessors.contains(v) == edges.contains(DirectedEdge(from: v, to: v)))
                inDegreeSum += g.inDegree(of: v)
                degreeSum += g.degree(of: v)
                // L13: duality.
                for u in vertices {
                    #expect(predecessors.filter { $0 == u }.count == Array(g.successors(of: u)).filter { $0 == v }.count)
                }
            }
            #expect(inDegreeSum == g.edgeCount)
            #expect(degreeSum == 2 * g.edgeCount)
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("DG-L19 – L23 out-edge positions agree with successors, and vertex indices are one-to-one and in vertices order (L27)", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func edgePositionsAndIndices(_ fixture: DirectedFixture<Int>) {
        func check<G: DirectedGraph>(_ g: G) {
            var seen = Set<G.Edges.Index>()
            for v in g.vertices {
                let outEdges = Array(g.outEdges(of: v))
                // L19: the out-edges' targets are the successors, in the same order.
                #expect(outEdges.map { g.target(ofEdgeAt: $0) } == Array(g.successors(of: v)))
                // L20: every out-edge leaves v, reads back from edges, and appears once overall.
                for e in outEdges {
                    #expect(g.source(ofEdgeAt: e) == v)
                    #expect(g.edges[e] == DirectedEdge(from: v, to: g.target(ofEdgeAt: e)))
                    #expect(seen.insert(e).inserted)
                }
                #expect(outEdges.count == g.outDegree(of: v))
                #expect(Array(g.outEdges(of: v)) == outEdges)
            }
            // L21: together the out-edges are every edge.
            #expect(seen == Set(g.edges.indices))
            // L22: vertex indices map the vertices one-to-one onto 0..<vertexCount.
            #expect(g.vertexIndexBound == g.vertexCount)
            if let n = g.vertexIndexBound {
                var indices = Set<Int>()
                for v in g.vertices {
                    let i = g.vertexIndex(of: v)
                    #expect((0 ..< n).contains(i))
                    #expect(g.vertex(atIndex: i) == v)
                    indices.insert(i)
                }
                #expect(indices == Set(0 ..< n))
                // L27: vertices are in index order.
                #expect(g.vertices.map { g.vertexIndex(of: $0) } == Array(0 ..< n))
                // L28: no flat rows on offer.
                #expect(g._withSuccessorIndexRows { _, _ in 0 } == nil)
            }
            // L23: vertices and edges are the same when asked again.
            #expect(Array(g.vertices) == Array(g.vertices))
            #expect(Array(g.edges) == Array(g.edges))
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("DG-L24 – L26 in-edge positions agree with predecessors", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func inEdgePositions(_ fixture: DirectedFixture<Int>) {
        func check<G: BidirectionalDirectedGraph>(_ g: G) {
            var seen = Set<G.Edges.Index>()
            for v in g.vertices {
                let inEdges = Array(g.inEdges(of: v))
                // L24: the in-edges' sources are the predecessors, in the same order.
                #expect(inEdges.map { g.source(ofEdgeAt: $0) } == Array(g.predecessors(of: v)))
                // L25: every in-edge enters v, and their number is the in-degree.
                for e in inEdges {
                    #expect(g.target(ofEdgeAt: e) == v)
                    #expect(g.edges[e].target == v)
                    #expect(seen.insert(e).inserted)
                }
                #expect(inEdges.count == g.inDegree(of: v))
                // L26: asking again gives the same answer.
                #expect(Array(g.predecessors(of: v)) == Array(g.predecessors(of: v)))
                #expect(Array(g.inEdges(of: v)) == inEdges)
            }
            #expect(seen == Set(g.edges.indices))
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("DG-L16 generic code gets the same answers as the concrete members", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func genericMatchesConcrete(_ fixture: DirectedFixture<Int>) {
        func answers<G: BidirectionalDirectedGraph>(_ g: G, _ v: G.Vertex, _ w: G.Vertex) -> [Int] {
            [g.vertexCount, g.edgeCount, g.contains(v) ? 1 : 0, g.contains(edge: DirectedEdge(from: v, to: w)) ? 1 : 0,
             g.outDegree(of: v), g.inDegree(of: v), g.degree(of: v)]
        }
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for v in graph.vertices {
            for w in graph.vertices {
                #expect(answers(graph, v, w) == [
                    graph.vertexCount, graph.edgeCount, graph.contains(v) ? 1 : 0, graph.contains(edge: DirectedEdge(from: v, to: w)) ? 1 : 0,
                    graph.outDegree(of: v), graph.inDegree(of: v), graph.degree(of: v),
                ])
            }
        }
    }

    @Test("DG-L17 generic counts and degrees agree with the fixture", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func agreesWithFixture(_ fixture: DirectedFixture<Int>) {
        func check<G: BidirectionalDirectedGraph<Int>>(_ g: G) {
            #expect(g.vertexCount == fixture.vertexCount)
            #expect(g.edgeCount == fixture.edgeCount)
            for v in g.vertices {
                #expect(g.outDegree(of: v) == fixture.outDegree[v], "outDegree(of: \(v))")
                #expect(g.inDegree(of: v) == fixture.inDegree[v], "inDegree(of: \(v))")
            }
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("DG-R01 the house graph through the protocol")
    func house() {
        func check(_ g: some BidirectionalDirectedGraph<Int>) {
            #expect(g.vertexCount == 6)
            #expect(g.edgeCount == 7)
            #expect([0, 1, 2, 3, 4, 5].map { g.outDegree(of: $0) } == [0, 1, 1, 2, 2, 1])
            #expect([0, 1, 2, 3, 4, 5].map { g.inDegree(of: $0) } == [2, 2, 1, 1, 1, 0])
        }
        check(AdjacencyList(edges: DirectedFixture<Int>.house.edges))
    }

    @Test("DG-R02 String vertices and isolated vertices through the protocol")
    func stringsAndIsolated() {
        func check(_ g: some BidirectionalDirectedGraph<String>) {
            #expect(g.vertexCount == 7)
            #expect(g.edgeCount == 5)
            #expect(Set(g.successors(of: "A")) == ["B", "C"])
            #expect(g.degree(of: "G") == 0)
            #expect(g.contains("G"))
        }
        let abcd = DirectedFixture<String>.networkXABCD
        check(AdjacencyList(vertices: abcd.vertices, edges: abcd.edges))
    }

    @Test("DG-R03 a self-loop through the protocol", .tags(.selfLoops))
    func selfLoop() {
        func check(_ g: some BidirectionalDirectedGraph<Int>) {
            #expect(Array(g.successors(of: 0)) == [0])
            #expect(Array(g.predecessors(of: 0)) == [0])
            #expect(g.outDegree(of: 0) == 1)
            #expect(g.inDegree(of: 0) == 1)
            #expect(g.degree(of: 0) == 2)
            #expect(g.contains(edge: DirectedEdge(from: 0, to: 0)))
        }
        check(AdjacencyList(edges: DirectedFixture<Int>.singleSelfLoop.edges))
    }

    @Test("DG-R16 the empty graph through the protocol")
    func empty() {
        func check(_ g: some DirectedGraph<Int>) {
            #expect(g.vertexCount == 0)
            #expect(g.edgeCount == 0)
            #expect(g.vertices.isEmpty)
            #expect(g.edges.isEmpty)
            #expect(!g.contains(0))
            #expect(!g.contains(edge: DirectedEdge(from: 0, to: 0)))
        }
        check(AdjacencyList<Int>())
    }

    @Test("DG-R14 querying an absent vertex through the protocol (an existential) traps", .tags(.precondition))
    func absentVertexTraps() async {
        await #expect(processExitsWith: .failure) {
            let g: any DirectedGraph<Int> = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = Array(g.successors(of: 99))
        }
        await #expect(processExitsWith: .failure) {
            let g: any DirectedGraph<Int> = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = g.outDegree(of: 99)
        }
        await #expect(processExitsWith: .failure) {
            let g: any BidirectionalDirectedGraph<Int> = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = Array(g.predecessors(of: 99))
        }
        await #expect(processExitsWith: .failure) {
            let g: any BidirectionalDirectedGraph<Int> = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = g.inDegree(of: 99)
        }
        await #expect(processExitsWith: .failure) {
            let g: any BidirectionalDirectedGraph<Int> = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = g.degree(of: 99)
        }
    }
}

/// Counts the comparisons made through it, so a test can tell an O(1) member from a scan that
/// happens to give the same answer.
private final class ComparisonCounter: @unchecked Sendable {
    var comparisons = 0
}

private struct CountingVertex: Hashable {
    let value: Int
    let counter: ComparisonCounter

    static func == (lhs: CountingVertex, rhs: CountingVertex) -> Bool {
        lhs.counter.comparisons += 1
        return lhs.value == rhs.value
    }

    func hash(into hasher: inout Hasher) { hasher.combine(value) }
}

@Suite("AdjacencyList's own members are the ones generic code calls")
struct AdjacencyListWitnessTests {
    @Test("DG-W01 contains and contains(edge:) are hash lookups through generic code, not the default scans")
    func lookupsThroughGenericCode() {
        let counter = ComparisonCounter()
        let hub = CountingVertex(value: 0, counter: counter)
        let leaves = (1 ... 200).map { CountingVertex(value: $0, counter: counter) }
        let graph = AdjacencyList(edges: leaves.map { DirectedEdge(from: hub, to: $0) })
        func contains(_ g: some DirectedGraph<CountingVertex>, _ v: CountingVertex) -> Bool { g.contains(v) }
        func contains(_ g: some DirectedGraph<CountingVertex>, edge: DirectedEdge<CountingVertex>) -> Bool { g.contains(edge: edge) }
        func outDegree(_ g: some DirectedGraph<CountingVertex>, _ v: CountingVertex) -> Int { g.outDegree(of: v) }
        // The defaults would compare against up to 201 vertices, or 200 successors.
        counter.comparisons = 0
        #expect(contains(graph, leaves[199]))
        #expect(counter.comparisons < 10)
        counter.comparisons = 0
        #expect(contains(graph, edge: DirectedEdge(from: hub, to: leaves[199])))
        #expect(counter.comparisons < 10)
        counter.comparisons = 0
        #expect(!contains(graph, edge: DirectedEdge(from: leaves[3], to: hub)))
        #expect(counter.comparisons < 10)
        counter.comparisons = 0
        #expect(outDegree(graph, hub) == 200)
        #expect(counter.comparisons < 10)
    }

    @Test("DG-I03 vertex indices after a removal are still one-to-one and in vertices order")
    func indicesAfterRemoval() {
        func check(_ g: some DirectedGraph<Int>) {
            #expect(g.vertexIndexBound == g.vertexCount)
            #expect(g.vertices.map { g.vertexIndex(of: $0) } == Array(0 ..< g.vertexCount))
            for v in g.vertices { #expect(g.vertex(atIndex: g.vertexIndex(of: v)) == v) }
        }
        var graph = AdjacencyList(edges: DirectedFixture<Int>.boost24.edges)
        graph.remove(3)
        graph.remove(17)
        check(graph)
    }
}

@Suite("AdjacencyList conversion from any DirectedGraph")
struct AdjacencyListConversionTests {
    @Test("DG-C08 converting an adjacency list gives an equal one", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func selfConversion(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        #expect(AdjacencyList(graph) == graph)
    }

    @Test("DG-C08 converting keeps isolated vertices, with String vertices")
    func keepsIsolatedVertices() {
        let abcd = DirectedFixture<String>.networkXABCD
        let graph = AdjacencyList(vertices: abcd.vertices, edges: abcd.edges)
        let converted = AdjacencyList(graph)
        #expect(converted == graph)
        #expect(converted.vertexCount == 7)
        #expect(converted.contains("G"))
    }
}
