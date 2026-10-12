// The index-space hooks (`outDegree(ofIndex:)`, `inDegree(ofIndex:)`, `sourceIndex(ofEdgeAt:)`,
// `targetIndex(ofEdgeAt:)`, `degree(ofIndex:)`, `endpointIndices(ofEdgeAt:)`) read the stored rows
// and records without a lookup. Each test checks them against the vertex-space members after a
// swap-remove has moved a vertex into another slot, with labels that are not their indices.

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("AdjacencyList index-space hooks")
struct AdjacencyListIndexHookTests {
    @Test("AdjacencyList: degrees and edge ends by index agree with the members after a swap-remove")
    func directedHooksAfterSwapRemove() {
        var graph = AdjacencyList<String>(
            vertices: ["e", "a", "d", "b", "c"],
            edges: [
                DirectedEdge(from: "e", to: "a"), DirectedEdge(from: "a", to: "d"), DirectedEdge(from: "d", to: "b"),
                DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "e"), DirectedEdge(from: "a", to: "c"),
                DirectedEdge(from: "c", to: "a"), DirectedEdge(from: "d", to: "e"),
            ])
        #expect(graph.remove("a") == "a")
        #expect(graph.remove(edge: DirectedEdge(from: "d", to: "b")) != nil)
        // "c", last, moved into "a"'s slot.
        #expect(graph.vertex(atIndex: 1) == "c")
        let n = graph.vertexIndexBound!
        #expect(n == 4)
        for i in 0 ..< n {
            let v = graph.vertex(atIndex: i)
            #expect(graph.vertexIndex(of: v) == i)
            #expect(graph.outDegree(ofIndex: i) == graph.outDegree(of: v), "out-degree at \(i)")
            #expect(graph.inDegree(ofIndex: i) == graph.inDegree(of: v), "in-degree at \(i)")
        }
        var count = 0
        for p in graph.edges.indices {
            #expect(graph.sourceIndex(ofEdgeAt: p) == graph.vertexIndex(of: graph.source(ofEdgeAt: p)))
            #expect(graph.targetIndex(ofEdgeAt: p) == graph.vertexIndex(of: graph.target(ofEdgeAt: p)))
            count += 1
        }
        #expect(count == graph.edgeCount)
        #expect(graph.outDegree(ofIndex: graph.vertexIndex(of: "c")) == 1)
        #expect(graph.inDegree(ofIndex: graph.vertexIndex(of: "e")) == 2)
    }

    @Test("UndirectedAdjacencyList: degrees and edge ends by index agree with the members after a swap-remove")
    func undirectedHooksAfterSwapRemove() {
        var graph = UndirectedAdjacencyList<String>(
            vertices: ["q", "x", "m", "b", "k"],
            edges: [
                UndirectedEdge("q", "x"), UndirectedEdge("x", "m"), UndirectedEdge("m", "b"), UndirectedEdge("b", "k"),
                UndirectedEdge("k", "q"), UndirectedEdge("x", "k"), UndirectedEdge("m", "q"),
            ])
        #expect(graph.remove("x") == "x")
        #expect(graph.remove(edge: UndirectedEdge("m", "b")) != nil)
        // "k", last, moved into "x"'s slot.
        #expect(graph.vertex(atIndex: 1) == "k")
        let n = graph.vertexIndexBound!
        #expect(n == 4)
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
        #expect(graph.degree(ofIndex: graph.vertexIndex(of: "q")) == 2)
    }
}
