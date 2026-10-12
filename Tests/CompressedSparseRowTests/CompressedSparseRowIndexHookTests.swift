// The index-space hooks (`outDegree(ofIndex:)`, `sourceIndex(ofEdgeAt:)`, `targetIndex(ofEdgeAt:)`)
// against the vertex-space members, on rows with repeats, self-loops and empty rows.

import CompressedSparseRowModule
import GraphProtocols
import Testing

@Suite("CompressedSparseRow index-space hooks")
struct CompressedSparseRowIndexHookTests {
    @Test("Degrees and edge ends by index agree with the members")
    func hooksAgreeWithMembers() {
        let graph = CompressedSparseRow(
            vertexCount: 6,
            edges: [
                DirectedEdge(from: 4, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 3),
                DirectedEdge(from: 5, to: 1), DirectedEdge(from: 1, to: 4), DirectedEdge(from: 4, to: 5), DirectedEdge(from: 4, to: 2),
            ])
        let n = graph.vertexIndexBound!
        #expect(n == 6)
        for i in 0 ..< n {
            let v = graph.vertex(atIndex: i)
            #expect(graph.outDegree(ofIndex: i) == graph.outDegree(of: v), "out-degree at \(i)")
        }
        var count = 0
        for p in graph.edges.indices {
            #expect(graph.sourceIndex(ofEdgeAt: p) == graph.vertexIndex(of: graph.source(ofEdgeAt: p)))
            #expect(graph.targetIndex(ofEdgeAt: p) == graph.vertexIndex(of: graph.target(ofEdgeAt: p)))
            count += 1
        }
        #expect(count == graph.edgeCount)
        #expect(graph.outDegree(ofIndex: 4) == 3)
        #expect(graph.outDegree(ofIndex: 2) == 0)
    }
}
