// §4: edges and orientation. Edge i of an open walk joins self[i] and self[i + 1]; edge i of a
// circuit joins self[i] and self[(i + 1) % count]. In an undirected graph the vertex sequence
// orients each edge, so an edge may be crossed from either end; in `g.directed` the arc's
// `reversed` flag must match. The step law is also checked on AdjacencyMatrix and
// CompressedSparseRow, whose positions are not list indices. Case IDs (WK-nnn) refer to the
// catalog; see README.md.

import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Walk edges and orientation")
struct WalkEdgeTests {
    @Test("WK-401 edge i runs from self[i] to self[i + 1], on the reference graph, a matrix and CSR")
    func stepLaw() throws {
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let d4 = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let w = try #require(Walk([0, 1, 2, 3, 0, 1], in: d4))
        for i in 0 ..< w.length {
            #expect(d4.source(ofEdgeAt: w.edges[i]) == w[i])
            #expect(d4.target(ofEdgeAt: w.edges[i]) == w[i + 1])
        }
        let matrix = AdjacencyMatrix(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let m = try #require(Walk([0, 1, 2, 3, 0, 1], in: matrix))
        #expect(m.length == 5)
        for i in 0 ..< m.length {
            #expect(matrix.source(ofEdgeAt: m.edges[i]) == m[i])
            #expect(matrix.target(ofEdgeAt: m.edges[i]) == m[i + 1])
        }
        #expect(Walk(vertices: m.vertices, edges: m.edges, in: matrix) == m)
        #expect(Walk([0, 2], in: matrix) == nil)
        let csr = CompressedSparseRow(vertexCount: 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let s = try #require(Walk([0, 1, 2, 3, 0, 1], in: csr))
        for i in 0 ..< s.length {
            #expect(csr.source(ofEdgeAt: s.edges[i]) == s[i])
            #expect(csr.target(ofEdgeAt: s.edges[i]) == s[i + 1])
        }
        #expect(Path(vertices: [0, 1, 2], edges: Array(s.edges.prefix(2)), in: csr) != nil)
        #expect(Path(vertices: [0, 1, 2], edges: [s.edges[1], s.edges[0]], in: csr) == nil)
    }

    @Test("WK-402 edge i of a cycle joins self[i] and self[(i + 1) % count]")
    func cycleStepLaw() throws {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let c = try #require(Cycle([1, 2, 3, 0], in: d4))
        for i in 0 ..< c.count {
            #expect(d4.source(ofEdgeAt: c.edges[i]) == c[i])
            #expect(d4.target(ofEdgeAt: c.edges[i]) == c[(i + 1) % c.count])
        }
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let t = try #require(Cycle([0, 2, 1], in: u))
        for i in 0 ..< t.count {
            #expect(u.edges[t.edges[i]] == UndirectedEdge(t[i], t[(i + 1) % t.count]))
        }
    }

    @Test("WK-403 an undirected edge may be crossed from either end")
    func eitherEnd() throws {
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let forward = try  #require(Walk(vertices: [0, 1], edges: [0], in: u))
        let backward = try  #require(Walk(vertices: [1, 0], edges: [0], in: u))
        #expect(forward != backward)
        #expect(forward.reversed() == backward)
    }

    @Test("WK-404 an undirected edge must join its two vertices")
    func wrongEnds() {
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        #expect(Walk(vertices: [0, 2], edges: [0], in: u) == nil)
        #expect(Walk(vertices: [0, 0], edges: [0], in: u) == nil)
    }

    @Test("WK-405 in g.directed the arc's direction must match the step")
    func directedViewArcs() {
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let g = u.directed
        typealias Arc = DirectedView<ReferencePseudograph<Int>>.Edges.Index
        #expect(Walk(vertices: [0, 1], edges: [Arc(position: 0, reversed: true)], in: g) == nil)
        #expect(Walk(vertices: [0, 1], edges: [Arc(position: 0, reversed: false)], in: g) != nil)
        #expect(Walk(vertices: [1, 0], edges: [Arc(position: 0, reversed: true)], in: g) != nil)
        #expect(Walk([1, 0], in: g)?.edges == [Arc(position: 0, reversed: true)])
    }
}
