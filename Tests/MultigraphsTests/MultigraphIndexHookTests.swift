// The index-space hooks (`outDegree(ofIndex:)`, `inDegree(ofIndex:)`, `sourceIndex(ofEdgeAt:)`,
// `targetIndex(ofEdgeAt:)`, `degree(ofIndex:)`, `endpointIndices(ofEdgeAt:)`) read the stored rows
// and records without a lookup. Each test checks them against the vertex-space members after a
// swap-remove of a vertex and the removal of an edge, with labels that are not their indices,
// copies and (where allowed) self-loops included.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs index-space hooks")
struct MultigraphIndexHookTests {
    @Test("DirectedPseudograph: degrees and edge ends by index agree with the members after a swap-remove")
    func directedPseudograph() {
        var graph = DirectedPseudograph<String>(
            vertices: ["v7", "v2", "v9", "v4", "v1"],
            edges: [
                DirectedEdge(from: "v7", to: "v2"), DirectedEdge(from: "v7", to: "v2"), DirectedEdge(from: "v2", to: "v2"),
                DirectedEdge(from: "v9", to: "v4"), DirectedEdge(from: "v4", to: "v1"), DirectedEdge(from: "v1", to: "v1"),
                DirectedEdge(from: "v1", to: "v7"), DirectedEdge(from: "v2", to: "v9"), DirectedEdge(from: "v1", to: "v9"),
            ])
        #expect(graph.remove("v2") == "v2")
        _ = graph.remove(edgeAt: graph.edges.startIndex)
        #expect(graph.vertex(atIndex: 1) == "v1")
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
    }

    @Test("DirectedMultigraph: degrees and edge ends by index agree with the members after a swap-remove")
    func directedMultigraph() {
        var graph = DirectedMultigraph<String>(
            vertices: ["v7", "v2", "v9", "v4", "v1"],
            edges: [
                DirectedEdge(from: "v7", to: "v2"), DirectedEdge(from: "v7", to: "v2"), DirectedEdge(from: "v9", to: "v4"),
                DirectedEdge(from: "v4", to: "v1"), DirectedEdge(from: "v1", to: "v7"), DirectedEdge(from: "v2", to: "v9"),
                DirectedEdge(from: "v1", to: "v9"), DirectedEdge(from: "v1", to: "v9"),
            ])!
        #expect(graph.remove("v2") == "v2")
        _ = graph.remove(edgeAt: graph.edges.startIndex)
        #expect(graph.vertex(atIndex: 1) == "v1")
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
    }

    @Test("Pseudograph: degrees and edge ends by index agree with the members after a swap-remove")
    func pseudograph() {
        var graph = Pseudograph<String>(
            vertices: ["v7", "v2", "v9", "v4", "v1"],
            edges: [
                UndirectedEdge("v7", "v2"), UndirectedEdge("v7", "v2"), UndirectedEdge("v2", "v2"), UndirectedEdge("v9", "v4"),
                UndirectedEdge("v4", "v1"), UndirectedEdge("v1", "v1"), UndirectedEdge("v1", "v7"), UndirectedEdge("v2", "v9"),
                UndirectedEdge("v9", "v1"),
            ])
        #expect(graph.remove("v2") == "v2")
        _ = graph.remove(edgeAt: graph.edges.startIndex)
        #expect(graph.vertex(atIndex: 1) == "v1")
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
    }

    @Test("Multigraph: degrees and edge ends by index agree with the members after a swap-remove")
    func multigraph() {
        var graph = Multigraph<String>(
            vertices: ["v7", "v2", "v9", "v4", "v1"],
            edges: [
                UndirectedEdge("v7", "v2"), UndirectedEdge("v7", "v2"), UndirectedEdge("v9", "v4"), UndirectedEdge("v4", "v1"),
                UndirectedEdge("v1", "v7"), UndirectedEdge("v2", "v9"), UndirectedEdge("v9", "v1"), UndirectedEdge("v9", "v1"),
            ])!
        #expect(graph.remove("v2") == "v2")
        _ = graph.remove(edgeAt: graph.edges.startIndex)
        #expect(graph.vertex(atIndex: 1) == "v1")
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
    }
}
