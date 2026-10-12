// The index-space hooks (`degree(ofIndex:)`, `endpointIndices(ofEdgeAt:)`) read the underlying
// list's rows and records without a lookup. Checked against the vertex-space members after a
// swap-remove, with labels that are not their indices.

import BipartiteGraphs
import GraphProtocols
import Testing

@Suite("BipartiteGraph index-space hooks")
struct BipartiteGraphIndexHookTests {
    @Test("Degrees and edge ends by index agree with the members after a swap-remove")
    func hooksAfterSwapRemove() {
        var graph = BipartiteGraph<String>(
            left: ["l3", "l1", "l2"], right: ["r9", "r4", "r6"],
            edges: [
                UndirectedEdge("l3", "r9"), UndirectedEdge("l1", "r9"), UndirectedEdge("r4", "l1"), UndirectedEdge("l2", "r6"),
                UndirectedEdge("l3", "r6"), UndirectedEdge("r4", "l2"),
            ])!
        #expect(graph.remove("l1") == "l1")
        #expect(graph.remove(edge: UndirectedEdge("l2", "r6")) != nil)
        let n = graph.vertexIndexBound!
        #expect(n == 5)
        for i in 0 ..< n {
            let v = graph.vertex(atIndex: i)
            #expect(graph.vertexIndex(of: v) == i)
            #expect(graph.degree(ofIndex: i) == graph.degree(of: v), "degree at \(i)")
        }
        var count = 0
        for p in graph.edges.indices {
            let edge = graph.edges[p]
            let ends = graph.endpointIndices(ofEdgeAt: p)
            #expect(ends.u == graph.vertexIndex(of: edge.u))
            #expect(ends.v == graph.vertexIndex(of: edge.v))
            count += 1
        }
        #expect(count == graph.edgeCount)
        #expect(count == 3)
        #expect(graph.degree(ofIndex: graph.vertexIndex(of: "l3")) == 2)
    }
}
