// CompressedSparseRow as a DirectedGraph. It has no in-adjacency, so it is not a
// BidirectionalDirectedGraph. Every value is read through a generic function declared inside the
// test. Case IDs (DG-Lnn, DG-Rnn, DG-Cnn) refer to the protocol catalog; see
// Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("CompressedSparseRow as a DirectedGraph", .tags(.conformance))
struct CompressedSparseRowDirectedGraphTests {
    @Test("DG-L01 – L09, L14, L15, L18 the DirectedGraph laws", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
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
        check(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges), absent: -1)
    }

    @Test("DG-L19 – L23 out-edge positions agree with successors, and vertex indices are one-to-one and in vertices order (L27)", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
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
                // L28: flat rows, when offered, are successorIndices.
                let rows: [[Int]]? = g._withSuccessorIndexRows { offsets, targets in
                    (0 ..< n).map { Array(targets[offsets[$0] ..< offsets[$0 + 1]]) }
                }
                #expect(rows == (0 ..< n).map { Array(g.successorIndices(ofIndex: $0)) })
            }
            // L23: vertices and edges are the same when asked again.
            #expect(Array(g.vertices) == Array(g.vertices))
            #expect(Array(g.edges) == Array(g.edges))
        }
        check(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
    }

    @Test("DG-L16 generic code gets the same answers as the concrete members", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func genericMatchesConcrete(_ fixture: DirectedFixture<Int>) {
        func answers<G: DirectedGraph>(_ g: G, _ v: G.Vertex, _ w: G.Vertex) -> [Int] {
            [g.vertexCount, g.edgeCount, g.contains(v) ? 1 : 0, g.contains(edge: DirectedEdge(from: v, to: w)) ? 1 : 0, g.outDegree(of: v)]
        }
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        for v in graph.vertices {
            for w in graph.vertices {
                #expect(answers(graph, v, w) == [
                    graph.vertexCount, graph.edgeCount, graph.contains(v) ? 1 : 0, graph.contains(edge: DirectedEdge(from: v, to: w)) ? 1 : 0,
                    graph.outDegree(of: v),
                ])
            }
        }
    }

    @Test("DG-L17 generic counts and out-degrees agree with the fixture", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func agreesWithFixture(_ fixture: DirectedFixture<Int>) {
        func check<G: DirectedGraph<Int>>(_ g: G) {
            #expect(g.vertexCount == fixture.vertexCount)
            #expect(g.edgeCount == fixture.edgeCount)
            for v in g.vertices {
                #expect(g.outDegree(of: v) == fixture.outDegree[v], "outDegree(of: \(v))")
            }
        }
        check(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
    }

    @Test("DG-R06 petgraph's csr1 through the protocol", .tags(.selfLoops))
    func petgraphCsr1() {
        func check(_ g: some DirectedGraph<Int>) {
            #expect(Array(g.successors(of: 0)) == [0, 2])
            #expect(Array(g.successors(of: 1)) == [0, 1, 2])
            #expect(Array(g.successors(of: 2)) == [2])
            #expect([0, 1, 2].map { g.outDegree(of: $0) } == [2, 3, 1])
            #expect(!g.contains(edge: DirectedEdge(from: 2, to: 1)))
            #expect(g.contains(edge: DirectedEdge(from: 1, to: 1)))
        }
        check(CompressedSparseRow(vertexCount: 3, edges: DirectedFixture<Int>.petgraphCsr1.edges))
    }

    @Test("DG-R07 / DG-R08 row-major edges and trailing isolated vertices through the protocol")
    func rowMajorAndIsolated() {
        func edges(_ g: some DirectedGraph<Int>) -> [DirectedEdge<Int>] { Array(g.edges) }
        #expect(edges(CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.boostCsrUnsorted.edges)) == [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 5, to: 0), DirectedEdge(from: 5, to: 2),
        ])
        func check(_ g: some DirectedGraph<Int>) {
            #expect(g.vertexCount == 6)
            #expect(g.edgeCount == 1)
            #expect(g.vertices.map { g.outDegree(of: $0) } == [0, 0, 0, 1, 0, 0])
        }
        check(CompressedSparseRow(vertexCount: 6, edges: DirectedFixture<Int>.scipyConstructor2.edges))
    }

    @Test("DG-R09 a compressed sparse row graph is not bidirectional")
    func notBidirectional() {
        #expect(!((CompressedSparseRow() as Any) is any BidirectionalDirectedGraph))
        #expect((CompressedSparseRow() as Any) is any DirectedGraph)
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
        check(CompressedSparseRow())
    }

    @Test("DG-R15 querying out of range through the protocol (an existential) traps", .tags(.precondition))
    func outOfRangeTraps() async {
        await #expect(processExitsWith: .failure) {
            let g: any DirectedGraph<Int> = CompressedSparseRow(vertexCount: 6)
            _ = Array(g.successors(of: 6))
        }
        await #expect(processExitsWith: .failure) {
            let g: any DirectedGraph<Int> = CompressedSparseRow(vertexCount: 6)
            _ = g.outDegree(of: -1)
        }
    }
}

@Suite("CompressedSparseRow conversion from any DirectedGraph")
struct CompressedSparseRowGraphConversionTests {
    @Test("DG-C08 converting a compressed sparse row graph gives an equal one", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func selfConversion(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        #expect(CompressedSparseRow(graph) == graph)
    }

    @Test("DG-C07 converting an adjacency list or a matrix on 0..<n", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func fromOthers(_ fixture: DirectedFixture<Int>) {
        let expected = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        #expect(CompressedSparseRow(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)) == expected)
        #expect(CompressedSparseRow(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)) == expected)
    }

    @Test("DG-C04 a matrix's edges become canonical rows")
    func fromMatrixExact() {
        let graph = CompressedSparseRow(AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostCsrUnsorted.edges))
        #expect(graph.offsets == [0, 1, 1, 1, 2, 4, 6])
        #expect(graph.targets == [2, 2, 0, 1, 0, 2])
    }

    @Test("DG-C09 vertices that are not exactly 0..<n trap", .tags(.precondition))
    func notZeroBased() async {
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(AdjacencyList(edges: DirectedFixture<Int>.directedCycle4.edges))
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(AdjacencyList(edges: DirectedFixture<Int>.triangleWithReciprocalEdge.edges))
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(AdjacencyList(edges: [DirectedEdge(from: 0, to: 2)]))
        }
        await #expect(processExitsWith: .failure) {
            // No edge is out of range, so only the vertex check can catch this.
            _ = CompressedSparseRow(AdjacencyList(vertices: [5]))
        }
    }
}
