// The index-space hooks (`outDegree(ofIndex:)`, `inDegree(ofIndex:)`, `sourceIndex(ofEdgeAt:)`,
// `targetIndex(ofEdgeAt:)`) against the vertex-space members, after edges are removed and a row
// crosses a word boundary.

import AdjacencyMatrixModule
import GraphProtocols
import Testing

@Suite("AdjacencyMatrix index-space hooks")
struct AdjacencyMatrixIndexHookTests {
    @Test("Degrees and edge ends by index agree with the members after removals")
    func hooksAgreeWithMembers() {
        var graph = AdjacencyMatrix(vertexCount: 70)
        for (s, t) in [(0, 69), (69, 0), (3, 3), (5, 64), (64, 63), (63, 5), (5, 6), (6, 5), (40, 2)] {
            graph.insert(edge: DirectedEdge(from: s, to: t))
        }
        #expect(graph.remove(edge: DirectedEdge(from: 69, to: 0)) != nil)
        #expect(graph.remove(edge: DirectedEdge(from: 5, to: 6)) != nil)
        let n = graph.vertexIndexBound!
        #expect(n == 70)
        for i in 0 ..< n {
            let v = graph.vertex(atIndex: i)
            #expect(graph.outDegree(ofIndex: i) == graph.outDegree(of: v), "out-degree at \(i)")
            #expect(graph.inDegree(ofIndex: i) == graph.inDegree(of: v), "in-degree at \(i)")
        }
        var count = 0
        for p in graph.edges.indices {
            #expect(graph.sourceIndex(ofEdgeAt: p) == graph.vertexIndex(of: graph.source(ofEdgeAt: p)))
            #expect(graph.targetIndex(ofEdgeAt: p) == graph.vertexIndex(of: graph.target(ofEdgeAt: p)))
            count += 1
        }
        #expect(count == 7)
        #expect(graph.outDegree(ofIndex: 5) == 1)
        #expect(graph.inDegree(ofIndex: 5) == 2)
    }
}
