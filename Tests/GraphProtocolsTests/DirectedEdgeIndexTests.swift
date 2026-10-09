// Dense edge indices, index-space out-edges, edges in index order and index-space in-edges
// (DG-L29 – DG-L32), added with
// ShortestPaths: weights keyed by edge position live in arrays when the positions are dense.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("DirectedGraph edge indices")
struct DirectedEdgeIndexTests {
    @Test("DG-L29 – DG-L31 edge indices are one-to-one onto 0..<edgeCount and follow edges order, on the adjacency list and compressed sparse row", .tags(.randomized), arguments: 1 ... 8)
    func edgeIndexLaws(_ seed: Int) {
        func laws<G: DirectedGraph>(_ graph: G) {
            guard let bound = graph.edgeIndexBound else {
                Issue.record("\(G.self) should have edge indices")
                return
            }
            #expect(bound == graph.edgeCount)
            #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) }.sorted() == Array(0 ..< bound))
            // DG-L31: edges is in index order.
            #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == Array(0 ..< bound))
            for v in graph.vertices {
                // DG-L30: out-edges by index are out-edges by vertex.
                #expect(Array(graph.outEdges(ofIndex: graph.vertexIndex(of: v))) == Array(graph.outEdges(of: v)))
            }
        }
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 2_900)
        let n = 12
        var edges: [DirectedEdge<Int>] = []
        for _ in 0 ..< 40 { edges.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator))) }
        var list = AdjacencyList(vertices: 0 ..< n, edges: edges)
        laws(list)
        laws(CompressedSparseRow(vertexCount: n, edges: edges))
        // Removals move edges into freed positions; the positions stay dense.
        for _ in 0 ..< 10 { list.remove(edge: edges[Int.random(in: 0 ..< edges.count, using: &generator)]) }
        list.remove(Int.random(in: 0 ..< n, using: &generator))
        laws(list)
    }

    @Test("DG-L32 inEdges(ofIndex:) is inEdges(of:), on every bidirectional representation and view, before and after removals", .tags(.randomized), arguments: 1 ... 8)
    func inEdgesByIndex(_ seed: Int) {
        func law<G: BidirectionalDirectedGraph>(_ graph: G) where G.InEdges: Sequence, G.Edges.Index: Equatable {
            for v in graph.vertices {
                let i = graph.vertexIndex(of: v)
                #expect(Array(graph.inEdges(ofIndex: i)) == Array(graph.inEdges(of: v)))
                #expect(graph.inEdges(of: v).allSatisfy { graph.target(ofEdgeAt: $0) == v })
                #expect(graph.inEdges(of: v).map { graph.source(ofEdgeAt: $0) } == Array(graph.predecessors(of: v)))
            }
        }
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 3_100)
        let n = 12
        var edges: [DirectedEdge<Int>] = []
        for _ in 0 ..< 40 { edges.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator))) }
        var list = AdjacencyList(vertices: 0 ..< n, edges: edges)
        law(list)
        law(AdjacencyMatrix(vertexCount: n, edges: edges))
        law(ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: edges))
        law(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.source, $0.target) }).directed)
        // Removals move edges and slots; the stored in-edge rows follow.
        for _ in 0 ..< 10 { list.remove(edge: edges[Int.random(in: 0 ..< edges.count, using: &generator)]) }
        list.remove(Int.random(in: 0 ..< n, using: &generator))
        law(list)
        list.remove(Int.random(in: 0 ..< n, using: &generator))
        law(list)
    }

    @Test("DG-L29 an adjacency list's positions are 0..<edgeCount in insertion order until a removal, and a weight array follows them")
    func adjacencyListPositions() {
        var list = AdjacencyList(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "c", to: "c")])
        #expect(Array(list.edges.indices) == [0, 1, 2, 3])
        #expect(list.edges.map(\.target) == ["b", "c", "c", "c"])
        #expect(Array(list.outEdges(of: "a")) == [0, 2])
        #expect(list.inEdges(of: "c") == [1, 2, 3])
        #expect(list.source(ofEdgeAt: 3) == "c")
        #expect(list.target(ofEdgeAt: 0) == "b")
        // Removing a→b moves the last edge, c→c, into position 0.
        list.remove(edge: DirectedEdge(from: "a", to: "b"))
        #expect(list.edges.map { "\($0.source)\($0.target)" } == ["cc", "bc", "ac"])
        #expect(Array(list.outEdges(of: "c")) == [0])
        #expect(Array(list.outEdges(of: "a")) == [2])
        let weight = [5, 7, 9]
        #expect(list.outEdges(of: "a").map { weight[$0] } == [9])
    }

    @Test("DG-L29 representations without dense edge indices report nil, and edgeIndex(of:) traps", .tags(.precondition))
    func noEdgeIndices() async {
        #expect(AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).edgeIndexBound == nil)
        #expect(ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)]).edgeIndexBound == nil)
        await #expect(processExitsWith: .failure) {
            let matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = matrix.edgeIndex(of: matrix.edges.startIndex)
        }
    }

    @Test("DG-L30 out-edges by index on every representation, defaults included")
    func outEdgesOfIndex() {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 1)]
        func check<G: DirectedGraph<Int>>(_ graph: G) {
            for v in graph.vertices {
                let byIndex = Array(graph.outEdges(ofIndex: graph.vertexIndex(of: v)))
                #expect(byIndex == Array(graph.outEdges(of: v)))
                #expect(byIndex.map { graph.target(ofEdgeAt: $0) } == Array(graph.successors(of: v)))
            }
        }
        check(AdjacencyList(edges: edges))
        check(AdjacencyMatrix(vertexCount: 3, edges: edges))
        check(CompressedSparseRow(vertexCount: 3, edges: edges))
        check(ReferenceDirectedMultigraph(edges: edges))
        check(UndirectedAdjacencyList(edges: edges.map { UndirectedEdge($0.source, $0.target) }).directed)
    }
}
