// hasSelfLoops, verticesWithSelfLoops() and selfLoopEdges(), directed and undirected: fixtures for
// the edge cases (no vertices, no loops, repeated loops, a loop on the first or last vertex) and
// PropertyBased laws against a brute-force model over the case's own edge list, on each path the
// queries take: stored rows (CSR, AdjacencyList), a row with its own membership test
// (AdjacencyMatrix), index-space rows without storage (the reference multigraphs), and
// conformers without vertex indices.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing

/// Supplies only what DirectedGraph requires: no vertex indices.
private struct DictionaryGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// Supplies only what Graph requires: no vertex indices; a self-loop's position listed twice.
private struct DictionaryUndirectedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func incidentEdges(of vertex: Vertex) -> [Int] {
        var positions: [Int] = []
        for (k, e) in edges.enumerated() {
            if e.u == vertex { positions.append(k) }
            if e.v == vertex { positions.append(k) }
        }
        return positions
    }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Self-loops")
struct SelfLoopTests {
    @Test("graphs without self-loops report none")
    func none() {
        #expect(!AdjacencyList<Int>().hasSelfLoops)
        #expect(AdjacencyList<Int>().verticesWithSelfLoops().isEmpty)
        #expect(AdjacencyList<Int>().selfLoopEdges().isEmpty)
        let path = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)]
        #expect(!CompressedSparseRow(vertexCount: 3, edges: path).hasSelfLoops)
        #expect(!AdjacencyMatrix(vertexCount: 3, edges: path).hasSelfLoops)
        #expect(!AdjacencyList(vertices: 0 ..< 3, edges: path).hasSelfLoops)
        #expect(!DictionaryGraph(vertices: [0, 1, 2], edges: path).hasSelfLoops)
        #expect(!UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).hasSelfLoops)
        #expect(!DictionaryUndirectedGraph(vertices: [0, 1], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)]).hasSelfLoops)
    }

    @Test("directed: a loop on the first or last vertex, repeated loops listed once per copy, vertices once")
    func directed() {
        let edges = [DirectedEdge(from: 2, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2), DirectedEdge(from: 0, to: 0)]
        let multigraph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: edges)
        #expect(multigraph.hasSelfLoops)
        #expect(multigraph.verticesWithSelfLoops() == [0, 2])
        #expect(multigraph.selfLoopEdges().map { multigraph.edges[$0] } == [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 2, to: 2), DirectedEdge(from: 2, to: 2)])
        let sparse = CompressedSparseRow(vertexCount: 3, edges: edges)
        #expect(sparse.verticesWithSelfLoops() == [0, 2])
        #expect(sparse.selfLoopEdges().map { sparse.edges[$0] } == [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 2, to: 2)])
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: edges)
        #expect(matrix.verticesWithSelfLoops() == [0, 2])
        #expect(matrix.selfLoopEdges().map { matrix.edges[$0] } == [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 2, to: 2)])
        let labeled = DictionaryGraph(vertices: ["z", "a"], edges: [DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "z", to: "z")])
        #expect(labeled.verticesWithSelfLoops() == ["z", "a"])
        #expect(labeled.selfLoopEdges() == [1, 0])
    }

    @Test("undirected: a loop listed twice in its row is one edge; repeated loops once per copy")
    func undirected() {
        let edges = [UndirectedEdge(1, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(2, 2)]
        let pseudograph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges)
        #expect(pseudograph.hasSelfLoops)
        #expect(pseudograph.verticesWithSelfLoops() == [1, 2])
        #expect(pseudograph.selfLoopEdges().count == 3)
        #expect(Set(pseudograph.selfLoopEdges().map { pseudograph.edges[$0] }) == [UndirectedEdge(1, 1), UndirectedEdge(2, 2)])
        let list = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: edges)
        #expect(list.verticesWithSelfLoops() == [1, 2])
        #expect(list.selfLoopEdges().map { list.edges[$0] } == [UndirectedEdge(1, 1), UndirectedEdge(2, 2)])
        let dictionary = DictionaryUndirectedGraph(vertices: [2, 1, 0], edges: edges)
        #expect(dictionary.verticesWithSelfLoops() == [2, 1])
        #expect(dictionary.selfLoopEdges() == [3, 0, 2])
    }

    @Test("law, directed: the loops of the edge list, by vertex then in outEdges order; a failure shrinks")
    func directedLaw() async {
        // Up to 16 edges on vertices 0..<6, repeats and self-loops allowed.
        let raw = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: raw) { pairs in
            let n = 6
            let edges = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
            func check<G: DirectedGraph<Int>>(_ g: G) {
                // Model: the graph's own edge list, read edge by edge.
                let loops = g.edges.indices.filter { g.edges[$0].isSelfLoop }
                let looped = (0 ..< n).filter { v in loops.contains { g.edges[$0].source == v } }
                #expect(g.hasSelfLoops == !loops.isEmpty)
                #expect(g.verticesWithSelfLoops() == looped)
                let expected = looped.flatMap { v in g.outEdges(of: v).filter { g.edges[$0].isSelfLoop } }
                #expect(g.selfLoopEdges() == expected)
                #expect(Set(g.selfLoopEdges()) == Set(loops) && g.selfLoopEdges().count == loops.count)
            }
            check(AdjacencyList(vertices: 0 ..< n, edges: edges))
            check(AdjacencyMatrix(vertexCount: n, edges: edges))
            check(CompressedSparseRow(vertexCount: n, edges: edges))
            check(ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: edges))
            check(DictionaryGraph(vertices: Array(0 ..< n), edges: edges))
        }
    }

    @Test("law, undirected: the loops of the edge list, each once, by vertex; a failure shrinks")
    func undirectedLaw() async {
        let raw = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: raw) { pairs in
            let n = 6
            let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
            func check<G: Graph<Int>>(_ g: G) {
                let loops = g.edges.indices.filter { g.edges[$0].isSelfLoop }
                let looped = (0 ..< n).filter { v in loops.contains { g.edges[$0].u == v } }
                #expect(g.hasSelfLoops == !loops.isEmpty)
                #expect(g.verticesWithSelfLoops() == looped)
                let found = g.selfLoopEdges()
                #expect(Set(found) == Set(loops) && found.count == loops.count)
                #expect(found.map { g.edges[$0].u } == found.map { g.edges[$0].u }.sorted())
            }
            check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges))
            check(ReferencePseudograph(vertices: 0 ..< n, edges: edges))
            check(DictionaryUndirectedGraph(vertices: Array(0 ..< n), edges: edges))
        }
    }
}
