// Edge betweenness beyond the catalog rows (§I, EdgeBetweennessTests.swift): degenerate graphs on
// CompressedSparseRow, every representation against the reference conformers (positions mapped by
// edge), and the result's lookups by position, plain and checked, for integer positions 0..<m and
// for integer positions that are not, and for struct positions (AdjacencyMatrix cells,
// `graph.directedView` arcs).

import AdjacencyListModule
import AdjacencyMatrixModule
import Centrality
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

/// A directed graph without vertex or edge indices whose edge positions are the integers 3..<3 + m,
/// not 0..<m: its edges are a slice.
private struct SlicedDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: ArraySlice<DirectedEdge<Int>>
    func successors(of vertex: Int) -> [Int] { outEdges(of: vertex).map { edges[$0].target } }
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

/// Edges at the positions start, start + 2, start + 4, …
private struct SteppedEdges: Collection {
    let base: [DirectedEdge<Int>]
    let start: Int
    var startIndex: Int { start }
    var endIndex: Int { start + 2 * base.count }
    func index(after i: Int) -> Int { i + 2 }
    subscript(position: Int) -> DirectedEdge<Int> { base[(position - start) / 2] }
}

/// A directed graph without vertex or edge indices whose edge positions step by 2 from `start`.
private struct SteppedDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: SteppedEdges
    func successors(of vertex: Int) -> [Int] { outEdges(of: vertex).map { edges[$0].target } }
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

@Suite("Edge betweenness lookups and representations")
struct EdgeBetweennessLookupTests {
    @Test("Degenerate graphs: no vertices, one vertex, one vertex with a loop, two isolated vertices; no scaling when n < 2")
    func degenerate() {
        let empty = UndirectedAdjacencyList<Int>()
        #expect(empty.edgeBetweennessCentrality().scores.isEmpty)
        #expect(AdjacencyList<Int>().edgeBetweennessCentrality(normalized: false).scores.isEmpty)
        let one = ReferencePseudograph(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)])
        #expect(one.edgeBetweennessCentrality().scores == [0])
        #expect(one.edgeBetweennessCentrality(weight: { _ in 2 }).scores == [0])
        let pair = CompressedSparseRow(vertexCount: 2)
        #expect(pair.edgeBetweennessCentrality().scores.isEmpty)
        let edge = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(edge.edgeBetweennessCentrality().scores == [0.5])
    }

    @Test("Every representation agrees: UndirectedAdjacencyList, ReferencePseudograph, directedView, AdjacencyList, ReferenceDirectedMultigraph, CompressedSparseRow, AdjacencyMatrix")
    func representations() {
        let pairs = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4), (3, 4), (4, 5)]
        let list = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let reference = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let expected = reference.edgeBetweennessCentrality(normalized: false)
        let fromList = list.edgeBetweennessCentrality(normalized: false)
        for e in list.edges.indices {
            let edge = list.edges[e]
            let k = pairs.firstIndex { UndirectedEdge($0.0, $0.1) == edge }!
            #expect(abs(fromList.score(ofEdgeAt: e) - expected.score(ofEdgeAt: k)) <= 1e-12)
        }
        // The directed view: each arc carries its direction's share; the two arcs of an edge add up to it.
        let view = reference.directedView.edgeBetweennessCentrality(normalized: false)
        for k in pairs.indices {
            let forward = view.score(ofEdgeAt: .init(position: k, reversed: false))
            let backward = view.score(ofEdgeAt: .init(position: k, reversed: true))
            #expect(abs(forward + backward - 2 * expected.score(ofEdgeAt: k)) <= 1e-12)
        }
        // Both directions of every edge as arcs: the undirected ordered-pair sums, halved.
        let arcs = pairs.flatMap { [DirectedEdge(from: $0.0, to: $0.1), DirectedEdge(from: $0.1, to: $0.0)] }.sorted { ($0.source, $0.target) < ($1.source, $1.target) }
        let csr = CompressedSparseRow(vertexCount: 6, edges: arcs)
        let matrix = AdjacencyMatrix(vertexCount: 6, edges: arcs)
        let adjacency = AdjacencyList(vertices: 0 ..< 6, edges: arcs)
        let multigraph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: arcs)
        let fromCSR = csr.edgeBetweennessCentrality(normalized: false)
        let fromMatrix = matrix.edgeBetweennessCentrality(normalized: false)
        let fromAdjacency = adjacency.edgeBetweennessCentrality(normalized: false)
        let fromMultigraph = multigraph.edgeBetweennessCentrality(normalized: false)
        #expect(fromCSR.scores == fromMultigraph.scores)
        for (k, arc) in arcs.enumerated() {
            let edge = pairs.firstIndex { UndirectedEdge($0.0, $0.1) == UndirectedEdge(arc.source, arc.target) }!
            let positionInMatrix = matrix.edges.firstIndex(of: arc)!
            let positionInList = adjacency.edges.firstIndex(of: arc)!
            #expect(fromMatrix.score(ofEdgeAt: positionInMatrix) == fromCSR.score(ofEdgeAt: k))
            #expect(fromAdjacency.score(ofEdgeAt: positionInList) == fromCSR.score(ofEdgeAt: k))
            let pair = fromCSR.score(ofEdgeAt: k) + fromCSR.score(ofEdgeAt: arcs.firstIndex(of: DirectedEdge(from: arc.target, to: arc.source))!)
            #expect(abs(pair - 2 * expected.score(ofEdgeAt: edge)) <= 1e-12)
        }
    }

    @Test("score(checkedEdgeAt:) agrees with score(ofEdgeAt:) and throws EdgeNotFound off the graph, for integer positions 0..<m, other integers, and struct positions")
    func checked() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let scores = graph.edgeBetweennessCentrality(normalized: false)
        for e in graph.edges.indices { #expect(try scores.score(checkedEdgeAt: e) == scores.score(ofEdgeAt: e)) }
        #expect(throws: EdgeNotFound.self) { try scores.score(checkedEdgeAt: 2) }
        #expect(throws: EdgeNotFound.self) { try scores.score(checkedEdgeAt: -1) }
        let matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let fromMatrix = matrix.edgeBetweennessCentrality(normalized: false)
        for p in matrix.edges.indices { #expect(try fromMatrix.score(checkedEdgeAt: p) == 2) }
        let missing = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 2, to: 0)]).edges.indices.first!
        #expect(throws: EdgeNotFound.self) { try fromMatrix.score(checkedEdgeAt: missing) }
        // The directed view's arcs are struct positions too.
        let view = graph.directedView.edgeBetweennessCentrality(normalized: false)
        #expect(try view.score(checkedEdgeAt: .init(position: 0, reversed: false)) == 2)
        #expect(try view.score(checkedEdgeAt: .init(position: 0, reversed: true)) == 2)
        #expect(throws: EdgeNotFound.self) { try view.score(checkedEdgeAt: .init(position: 5, reversed: false)) }
    }

    @Test("Integer positions that are not 0..<m are looked up by position: an edge slice starting at 3")
    func slicedPositions() throws {
        let all = [DirectedEdge(from: 9, to: 9), DirectedEdge(from: 9, to: 9), DirectedEdge(from: 9, to: 9), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2)]
        let graph = SlicedDigraph(vertices: [2, 1, 0], edges: all[3...])
        let scores = graph.edgeBetweennessCentrality(normalized: false)
        // 0 → 1 and 1 → 2 carry their own pair and none of 0 → 2, which has its own arc.
        #expect(scores.scores == [1, 1, 1])
        for p in 3 ..< 6 {
            #expect(scores.score(ofEdgeAt: p) == 1)
            #expect(try scores.score(checkedEdgeAt: p) == 1)
        }
        for p in [0, 2, 6, -1] {
            #expect(throws: EdgeNotFound.self) { try scores.score(checkedEdgeAt: p) }
        }
        let fromPivots = graph.edgeBetweennessCentrality(pivots: [1], normalized: false)
        #expect(try fromPivots.score(checkedEdgeAt: 4) == 3)
        #expect(try fromPivots.score(checkedEdgeAt: 3) == 0)
        // A slice of length one starting at 0 is the identity again.
        let one = SlicedDigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)][0...])
        #expect(try one.edgeBetweennessCentrality().score(checkedEdgeAt: 0) == 0.5)
        #expect(throws: EdgeNotFound.self) { try one.edgeBetweennessCentrality().score(checkedEdgeAt: 1) }
    }

    @Test("Integer positions with gaps, from 0 (0, 2, 4) and from below 0 (−2, 0, 2), are looked up by position, not as edge numbers")
    func steppedPositions() throws {
        let arcs = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)]
        for start in [0, -2] {
            let graph = SteppedDigraph(vertices: [0, 1, 2, 3], edges: SteppedEdges(base: arcs, start: start))
            let scores = graph.edgeBetweennessCentrality(normalized: false)
            // 0 → 1 is on the paths from 0; 1 → 2 on those through it; 2 → 3 on those to 3.
            #expect(scores.scores == [3, 4, 3])
            #expect(scores.score(ofEdgeAt: start) == 3)
            #expect(scores.score(ofEdgeAt: start + 2) == 4)
            #expect(try scores.score(checkedEdgeAt: start + 4) == 3)
            #expect(throws: EdgeNotFound.self) { try scores.score(checkedEdgeAt: start + 1) }
            #expect(throws: EdgeNotFound.self) { try scores.score(checkedEdgeAt: start + 6) }
        }
    }
}
