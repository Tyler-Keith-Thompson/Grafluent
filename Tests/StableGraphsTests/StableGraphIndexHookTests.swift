// The index-space hooks (`outDegree(ofIndex:)`, `inDegree(ofIndex:)`, `sourceIndex(ofEdgeAt:)`,
// `targetIndex(ofEdgeAt:)`) read the stored rows and records without the hash. A vertex removal
// leaves a hole (no vertex indices), so the test removes edges, leaving edge holes, and checks
// the hooks against the vertex-space members with labels that are not their indices.

import GraphProtocols
import StableGraphs
import Testing

@Suite("StableDirectedGraph index-space hooks")
struct StableGraphIndexHookTests {
    @Test("Degrees and edge ends by index agree with the members around edge holes")
    func hooksAroundEdgeHoles() {
        var graph = StableDirectedGraph<String>(
            vertices: ["v7", "v2", "v9", "v4", "v1"],
            edges: [
                DirectedEdge(from: "v7", to: "v2"), DirectedEdge(from: "v7", to: "v2"), DirectedEdge(from: "v2", to: "v2"),
                DirectedEdge(from: "v9", to: "v4"), DirectedEdge(from: "v4", to: "v1"), DirectedEdge(from: "v1", to: "v7"),
                DirectedEdge(from: "v2", to: "v9"), DirectedEdge(from: "v1", to: "v9"),
            ])
        _ = graph.remove(edgeAt: 1)
        _ = graph.remove(edgeAt: 4)
        graph.insert("v0")
        graph.insert(edge: DirectedEdge(from: "v0", to: "v4"))
        let n = graph.vertexIndexBound!
        #expect(n == 6)
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
        #expect(count == 7)
        #expect(graph.inDegree(ofIndex: graph.vertexIndex(of: "v4")) == 2)
    }
}
