// Preconditions (catalog SG-050 – SG-065): each trapping call runs in a child process (exit test).
// The same setup then runs in this process one step short of the precondition, so the trap is
// the call's and not the setup's. Then the preconditions the catalog does not list
// (extra_traps.swift).
// Generated from cases.md by swiftgen.py; see README.md.

import Foundation
import GrafluentTestSupport
import GraphProtocols
import StableGraphs
import Testing

@Suite("StableGraphs preconditions", .tags(.precondition))
struct StableGraphPreconditionTests {
    @Test("SG-050 successors(of:) non-vertex")
    func sg050() async {
        // V [0]; E [] / successors(of: 9) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [] as [DirectedEdge<Int>])
            _ = Array(graph.successors(of: 9))
        }
        // Without the call: the setup's results and the state the call would apply to.
        let graph = StableDirectedGraph<Int>(vertices: [0], edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == [0])
        #expect(Array(graph.vertices.indices) == [0])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 1)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 0)
        #expect(graph.vertexIndexBound == 1)
        #expect(graph.edgeIndexBound == 0)
        #expect(graph.vertexCount == 1)
        #expect(graph.vertices.count == 1)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 0 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 0)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { graph.vertex(atIndex: $0) } == [0])
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [] as [Int])
    }

    @Test("SG-051 outEdges(of:) removed vertex")
    func sg051() async {
        // V [0, 1]; E [0→1] / remove(0) / outEdges(of: 0) → 0; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(0)
            _ = Array(graph.outEdges(of: 0))
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.remove(0) == 0)
        #expect(Array(graph.vertices) == [1])
        #expect(Array(graph.vertices.indices) == [1])
        #expect(graph.vertices.startIndex == 1)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 1)
        #expect(graph.edges.endIndex == 1)
        #expect(graph.vertexIndexBound == nil)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 1)
        #expect(graph.vertices.count == 1)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 0)
    }

    @Test("SG-052 inEdges(of:) non-vertex")
    func sg052() async {
        // V [0]; E [] / inEdges(of: 9) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [] as [DirectedEdge<Int>])
            _ = Array(graph.inEdges(of: 9))
        }
        // Without the call: the setup's results and the state the call would apply to.
        let graph = StableDirectedGraph<Int>(vertices: [0], edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == [0])
        #expect(Array(graph.vertices.indices) == [0])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 1)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 0)
        #expect(graph.vertexIndexBound == 1)
        #expect(graph.edgeIndexBound == 0)
        #expect(graph.vertexCount == 1)
        #expect(graph.vertices.count == 1)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 0 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 0)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { graph.vertex(atIndex: $0) } == [0])
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [] as [Int])
    }

    @Test("SG-053 remove(edgeAt:) hole")
    func sg053() async {
        // V [0, 1]; E [0→1, 0→1] / remove(edgeAt: 0) / remove(edgeAt: 0) → 0→1; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(edgeAt: 0)
            _ = graph.remove(edgeAt: 0)
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        #expect(graph.remove(edgeAt: 0) == DirectedEdge(from: 0, to: 1))
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(graph.edges.indices) == [1])
        #expect(graph.edges.startIndex == 1)
        #expect(graph.edges.endIndex == 2)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [1])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 1 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 1)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [1])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 1 && graph.degree(of: 1) == 1)
        #expect(Array(graph.edges(from: 0, to: 1)) == [1])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
    }

    @Test("SG-054 remove(edgeAt:) past end")
    func sg054() async {
        // V [0, 1]; E [0→1] / remove(edgeAt: 1) → **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(edgeAt: 1)
        }
        // Without the call: the setup's results and the state the call would apply to.
        let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 1)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == 1)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 1 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 1)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 1 && graph.degree(of: 1) == 1)
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0])
    }

    @Test("SG-055 remove(edgeAt:) negative")
    func sg055() async {
        // V [0, 1]; E [0→1] / remove(edgeAt: -1) → **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(edgeAt: -1)
        }
        // Without the call: the setup's results and the state the call would apply to.
        let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 1)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == 1)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 1 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 1)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 1 && graph.degree(of: 1) == 1)
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0])
    }

    @Test("SG-056 source(ofEdgeAt:) hole")
    func sg056() async {
        // V [0, 1]; E [0→1] / remove(edgeAt: 0) / source(ofEdgeAt: 0) → 0→1; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(edgeAt: 0)
            _ = graph.source(ofEdgeAt: 0)
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.remove(edgeAt: 0) == DirectedEdge(from: 0, to: 1))
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 1)
        #expect(graph.edges.endIndex == 1)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 0 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 0)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 0)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
    }

    @Test("SG-057 edges[p] hole")
    func sg057() async {
        // V [0, 1]; E [0→1, 1→0] / remove(edgeAt: 0) / edges[0] → 0→1; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.remove(edgeAt: 0)
            _ = graph.edges[0]
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.remove(edgeAt: 0) == DirectedEdge(from: 0, to: 1))
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0]])
        #expect(Array(graph.edges.indices) == [1])
        #expect(graph.edges.startIndex == 1)
        #expect(graph.edges.endIndex == 2)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[1, 0]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 1, to: 0)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [1])
        #expect(Array(graph.inEdges(of: 0)) == [1])
        #expect(graph.outDegree(of: 0) == 0 && graph.inDegree(of: 0) == 1 && graph.degree(of: 0) == 1)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [0])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 1 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 0)) == [1])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 0)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
    }

    @Test("SG-058 vertices[p] hole")
    func sg058() async {
        // V [0, 1]; E [] / remove(0) / vertices[0] → 0; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])
            _ = graph.remove(0)
            _ = graph.vertices[0]
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])
        #expect(graph.remove(0) == 0)
        #expect(Array(graph.vertices) == [1])
        #expect(Array(graph.vertices.indices) == [1])
        #expect(graph.vertices.startIndex == 1)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 0)
        #expect(graph.vertexIndexBound == nil)
        #expect(graph.edgeIndexBound == 0)
        #expect(graph.vertexCount == 1)
        #expect(graph.vertices.count == 1)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 0)
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [] as [Int])
    }

    @Test("SG-059 vertex(atIndex:) with vertex holes")
    func sg059() async {
        // V [0, 1, 2]; E [] / vertex(atIndex: 2) / remove(0) / vertex(atIndex: 0) → 2; 0; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [] as [DirectedEdge<Int>])
            _ = graph.vertex(atIndex: 2)
            _ = graph.remove(0)
            _ = graph.vertex(atIndex: 0)
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [] as [DirectedEdge<Int>])
        #expect(graph.vertex(atIndex: 2) == 2)
        #expect(graph.remove(0) == 0)
        #expect(Array(graph.vertices) == [1, 2])
        #expect(Array(graph.vertices.indices) == [1, 2])
        #expect(graph.vertices.startIndex == 1)
        #expect(graph.vertices.endIndex == 3)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 0)
        #expect(graph.vertexIndexBound == nil)
        #expect(graph.edgeIndexBound == 0)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 0)
        #expect(graph.vertices.firstIndex(of: 2) == 2)
        #expect(graph.vertices[2] == 2)
        #expect(Array(graph.successors(of: 2)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 2)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 2)) == [] as [Int])
        #expect(graph.outDegree(of: 2) == 0 && graph.inDegree(of: 2) == 0 && graph.degree(of: 2) == 0)
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [] as [Int])
    }

    @Test("SG-060 vertexIndex(of:) with vertex holes")
    func sg060() async {
        // V [0, 1]; E [] / vertexIndex(of: 1) / remove(0) / vertexIndex(of: 1) → 1; 0; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])
            _ = graph.vertexIndex(of: 1)
            _ = graph.remove(0)
            _ = graph.vertexIndex(of: 1)
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])
        #expect(graph.vertexIndex(of: 1) == 1)
        #expect(graph.remove(0) == 0)
        #expect(Array(graph.vertices) == [1])
        #expect(Array(graph.vertices.indices) == [1])
        #expect(graph.vertices.startIndex == 1)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 0)
        #expect(graph.vertexIndexBound == nil)
        #expect(graph.edgeIndexBound == 0)
        #expect(graph.vertexCount == 1)
        #expect(graph.vertices.count == 1)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 0)
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [] as [Int])
    }

    @Test("SG-061 edgeIndex(of:) with edge holes")
    func sg061() async {
        // V [0, 1]; E [0→1, 1→0] / edgeIndex(of: 1) / remove(edgeAt: 0) / edgeIndex(of: 1) → 1; 0→1; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.edgeIndex(of: 1)
            _ = graph.remove(edgeAt: 0)
            _ = graph.edgeIndex(of: 1)
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.edgeIndex(of: 1) == 1)
        #expect(graph.remove(edgeAt: 0) == DirectedEdge(from: 0, to: 1))
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0]])
        #expect(Array(graph.edges.indices) == [1])
        #expect(graph.edges.startIndex == 1)
        #expect(graph.edges.endIndex == 2)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[1, 0]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 1, to: 0)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [1])
        #expect(Array(graph.inEdges(of: 0)) == [1])
        #expect(graph.outDegree(of: 0) == 0 && graph.inDegree(of: 0) == 1 && graph.degree(of: 0) == 1)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [0])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 1 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 0)) == [1])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 0)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
    }

    @Test("SG-062 edge removal alone keeps vertex indices")
    func sg062() async {
        // V [0, 1]; E [0→1] / remove(edgeAt: 0) / vertexIndex(of: 1) / edgeIndex(of: 0) → 0→1; 1; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(edgeAt: 0)
            _ = graph.vertexIndex(of: 1)
            _ = graph.edgeIndex(of: 0)
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.remove(edgeAt: 0) == DirectedEdge(from: 0, to: 1))
        #expect(graph.vertexIndex(of: 1) == 1)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 1)
        #expect(graph.edges.endIndex == 1)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 0 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 0)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 0)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
    }

    @Test("SG-063 vertex(atIndex:) past bound")
    func sg063() async {
        // V [0, 1]; E [] / vertex(atIndex: 2) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])
            _ = graph.vertex(atIndex: 2)
        }
        // Without the call: the setup's results and the state the call would apply to.
        let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 0)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == 0)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 0 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 0)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 0)
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [] as [Int])
    }

    @Test("SG-064 index(after:) at endIndex")
    func sg064() async {
        // V [0]; E [0→0] / edges.index(after: edges.endIndex) → **trap**
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
            _ = graph.edges.index(after: graph.edges.endIndex)
        }
        // Without the call: the last live position steps to endIndex.
        let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
        #expect(graph.edges.index(after: 0) == graph.edges.endIndex)
        #expect(graph.edges.endIndex == 1)
    }

    @Test("SG-065 reserveCapacity negative")
    func sg065() async {
        // V []; E [] / reserveCapacity(vertexCount: -1, edgeCount: 0) → **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>])
            graph.reserveCapacity(vertexCount: -1, edgeCount: 0)
        }
        // Without the trap: zero is allowed and changes nothing.
        var graph = StableDirectedGraph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>])
        graph.reserveCapacity(vertexCount: 0, edgeCount: 0)
        #expect(graph == StableDirectedGraph<Int>())
        #expect(graph.vertices.endIndex == 0)
        #expect(graph.edges.endIndex == 0)
    }

    @Test("SG-119 source(ofEdgeAt:) at a position in a freed page traps")
    func sg119() async {
        // V [0, 1]; E [0→1] / 2500 × { insert(edge: 0→1); remove(edgeAt: edges.startIndex) } / source(ofEdgeAt: 5) → nil; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            for _ in 0 ..< 2500 { graph.insert(edge: DirectedEdge(from: 0, to: 1)); graph.remove(edgeAt: graph.edges.startIndex) }
            _ = graph.source(ofEdgeAt: 5)
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        for _ in 0 ..< 2500 { graph.insert(edge: DirectedEdge(from: 0, to: 1)); graph.remove(edgeAt: graph.edges.startIndex) }
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(graph.edges.indices) == [2500])
        #expect(graph.edges.startIndex == 2500)
        #expect(graph.edges.endIndex == 2501)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [2500])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 1 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 1)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [2500])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 1 && graph.degree(of: 1) == 1)
        #expect(Array(graph.edges(from: 0, to: 1)) == [2500])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
    }

    @Test("SG-120 vertices[p] at a position in a freed page traps")
    func sg120() async {
        // V [0]; E [] / for i in 0..<2100 { insert(edge: i→i+1); remove(i) } / vertices[3] → nil; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0], edges: [] as [DirectedEdge<Int>])
            for i in 0 ..< 2100 { graph.insert(edge: DirectedEdge(from: i, to: i + 1)); graph.remove(i) }
            _ = graph.vertices[3]
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0], edges: [] as [DirectedEdge<Int>])
        for i in 0 ..< 2100 { graph.insert(edge: DirectedEdge(from: i, to: i + 1)); graph.remove(i) }
        #expect(Array(graph.vertices) == [2100])
        #expect(Array(graph.vertices.indices) == [2100])
        #expect(graph.vertices.startIndex == 2100)
        #expect(graph.vertices.endIndex == 2101)
        #expect(graph.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(graph.edges.startIndex == 2100)
        #expect(graph.edges.endIndex == 2100)
        #expect(graph.vertexIndexBound == nil)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 1)
        #expect(graph.vertices.count == 1)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.count == 0)
        #expect(graph.vertices.firstIndex(of: 2100) == 2100)
        #expect(graph.vertices[2100] == 2100)
        #expect(Array(graph.successors(of: 2100)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 2100)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 2100)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 2100)) == [] as [Int])
        #expect(graph.outDegree(of: 2100) == 0 && graph.inDegree(of: 2100) == 0 && graph.degree(of: 2100) == 0)
    }

    @Test("SG-128 changeTarget(ofEdgeAt:to:) to a non-vertex traps")
    func sg128() async {
        // V [0, 1]; E [0→1] / changeTarget(ofEdgeAt: 0, to: 1) / changeTarget(ofEdgeAt: 0, to: 9) → nil; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            graph.changeTarget(ofEdgeAt: 0, to: 1)
            graph.changeTarget(ofEdgeAt: 0, to: 9)
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        graph.changeTarget(ofEdgeAt: 0, to: 1)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1]])
        #expect(Array(graph.edges.indices) == [0])
        #expect(graph.edges.startIndex == 0)
        #expect(graph.edges.endIndex == 1)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == 1)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 1 && graph.inDegree(of: 0) == 0 && graph.degree(of: 0) == 1)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 1) == 1 && graph.degree(of: 1) == 1)
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
        #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == [0])
    }

    @Test("SG-129 changeSource(ofEdgeAt:to:) at a hole traps")
    func sg129() async {
        // V [0, 1]; E [0→1, 1→0] / remove(edgeAt: 0) / changeSource(ofEdgeAt: 0, to: 1) → 0→1; **trap**
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.remove(edgeAt: 0)
            graph.changeSource(ofEdgeAt: 0, to: 1)
        }
        // Without the call: the setup's results and the state the call would apply to.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.remove(edgeAt: 0) == DirectedEdge(from: 0, to: 1))
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.vertices.indices) == [0, 1])
        #expect(graph.vertices.startIndex == 0)
        #expect(graph.vertices.endIndex == 2)
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 0]])
        #expect(Array(graph.edges.indices) == [1])
        #expect(graph.edges.startIndex == 1)
        #expect(graph.edges.endIndex == 2)
        #expect(graph.vertexIndexBound == 2)
        #expect(graph.edgeIndexBound == nil)
        #expect(graph.vertexCount == 2)
        #expect(graph.vertices.count == 2)
        #expect(graph.edgeCount == 1)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[1, 0]])
        #expect(graph.edges.indices.map { graph.edges[$0] } == [DirectedEdge(from: 1, to: 0)])
        #expect(graph.vertices.firstIndex(of: 0) == 0)
        #expect(graph.vertices[0] == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [1])
        #expect(Array(graph.inEdges(of: 0)) == [1])
        #expect(graph.outDegree(of: 0) == 0 && graph.inDegree(of: 0) == 1 && graph.degree(of: 0) == 1)
        #expect(graph.vertices.firstIndex(of: 1) == 1)
        #expect(graph.vertices[1] == 1)
        #expect(Array(graph.successors(of: 1)) == [0])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 1)) == [] as [Int])
        #expect(graph.outDegree(of: 1) == 1 && graph.inDegree(of: 1) == 0 && graph.degree(of: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 0)) == [1])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 0)))
        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { graph.vertex(atIndex: $0) } == [0, 1])
    }

    @Test("Every neighbourhood and degree of a non-vertex or a removed vertex traps")
    func neighbourhoodsOfAbsentVertices() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
            _ = Array(graph.predecessors(of: 9))
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
            _ = graph.outDegree(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
            _ = graph.inDegree(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])
            _ = graph.degree(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(1)
            _ = Array(graph.successors(of: 1))
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(1)
            _ = Array(graph.inEdges(of: 1))
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(0)
            _ = graph.outDegree(of: 0)
        }
        // Without the calls: the same vertices that are present answer.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        _ = graph.remove(1)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(graph.outDegree(of: 0) == 0)
        #expect(!graph.contains(1))
    }

    @Test("Position lookups trap at a hole, a negative position and past the end")
    func positionLookups() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.remove(edgeAt: 0)
            _ = graph.target(ofEdgeAt: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.source(ofEdgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.target(ofEdgeAt: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edges[1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edges[-1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertices[2]
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertices[-1]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.remove(0)
            _ = graph.remove(edgeAt: 0)
        }
        // Without the calls: the live positions answer.
        let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.edges[0] == DirectedEdge(from: 0, to: 1))
        #expect(graph.vertices[1] == 1)
    }

    @Test("A position from before a reset names a new edge or nothing: removing it again traps")
    func positionsAfterReset() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            graph.removeAllEdges()
            _ = graph.remove(edgeAt: 1)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            graph.removeAll()
            _ = graph.vertices[0]
        }
        // Without the calls: the reset positions are not live.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        graph.removeAllEdges()
        #expect(!graph.edges.indices.contains(1))
        #expect(graph.edges.endIndex == 0)
    }

    @Test("Dense index lookups trap out of range without holes, and for any argument with holes")
    func denseIndexLookups() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertex(atIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertexIndex(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edgeIndex(of: 1)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2])
            _ = graph.remove(1)
            _ = graph.vertex(atIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.remove(edgeAt: 1)
            _ = graph.edgeIndex(of: 0)
        }
        // Without the calls: in range and without holes, the indices are the positions.
        let graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertex(atIndex: 1) == 1)
        #expect(graph.vertexIndex(of: 1) == 1)
        #expect(graph.edgeIndex(of: 0) == 0)
    }

    @Test("Stepping past either end of vertices or edges traps")
    func steppingPastTheEnds() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertices.index(after: graph.vertices.endIndex)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.remove(0)
            _ = graph.vertices.index(before: graph.vertices.startIndex)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
            _ = graph.remove(edgeAt: 0)
            _ = graph.edges.index(before: graph.edges.startIndex)
        }
        // Without the calls: stepping skips holes in both directions.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2])
        _ = graph.remove(1)
        #expect(graph.vertices.index(after: 0) == 2)
        #expect(graph.vertices.index(before: 2) == 0)
        #expect(graph.vertices.index(before: graph.vertices.endIndex) == 2)
    }

    @Test("A negative edge capacity traps")
    func negativeEdgeCapacity() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>()
            graph.reserveCapacity(vertexCount: 0, edgeCount: -1)
        }
        var graph = StableDirectedGraph<Int>()
        graph.reserveCapacity(vertexCount: 4, edgeCount: 4)
        #expect(graph.vertexCount == 0 && graph.edges.endIndex == 0)
    }

    @Test("SparselyIndexedDirectedGraph lookups trap for a non-vertex and at a hole")
    func sparseLookups() async {
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertexPosition(of: 9)
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.remove(0)
            _ = graph.vertex(atPosition: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            _ = graph.vertex(atPosition: 2)
        }
        // Without the calls: liveness answers without trapping.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1])
        _ = graph.remove(0)
        #expect(!graph.containsVertex(atPosition: 0) && !graph.containsVertex(atPosition: 9) && graph.vertex(atPosition: 1) == 1)
    }

    @Test("insert(edge:) traps once edge positions are exhausted (edgeEnd decoded as Int.max)")
    func edgePositionsExhausted() async throws {
        let payload = Data(#"{"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[],"edgePositions":[],"edgeEnd":9223372036854775807}"#.utf8)
        await #expect(processExitsWith: .failure) {
            var graph = try! JSONDecoder().decode(StableDirectedGraph<Int>.self, from: Data(#"{"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[],"edgePositions":[],"edgeEnd":9223372036854775807}"#.utf8))
            _ = graph.insert(edge: DirectedEdge(from: 0, to: 0))
        }
        // Without the call: the graph decodes, and vertex positions are not exhausted.
        var graph = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
        #expect(graph.edges.endIndex == Int.max && graph.edgeCount == 0)
        #expect(graph.insert(1).inserted)
        #expect(graph.insert(safe: DirectedEdge(from: 0, to: 9)) == nil)
    }

    @Test("An attached map's handle traps on another graph, after removeEdgeMap, and to set a dead position")
    func mapHandleMisuse() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            let labels = graph.addEdgeMap(of: String.self)
            let other = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = other[labels, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            let labels = graph.addEdgeMap(of: String.self)
            graph.removeEdgeMap(labels)
            _ = graph[labels, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            // Two copies of one graph each add a map: one copy's handle does not name the other's map.
            let graph = StableDirectedGraph<Int>(vertices: [0, 1])
            var a = graph, b = graph
            _ = b.addVertexMap(of: Int.self)
            let names = a.addVertexMap(of: Int.self)
            _ = b[names, ofVertexAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            let labels = graph.addEdgeMap(of: String.self)
            graph.remove(edgeAt: 0)
            graph[labels, ofEdgeAt: 0] = "stale"
        }
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1])
            let names = graph.addVertexMap(of: String.self)
            graph[names, of: 9] = "missing"
        }
        // Without the misuse: the handle works on its graph and on copies, and nil is always allowed.
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let labels = graph.addEdgeMap(of: String.self), names = graph.addVertexMap(of: String.self)
        graph[labels, ofEdgeAt: 0] = "a"
        var copy = graph
        copy[labels, ofEdgeAt: 0] = "b"
        graph[labels, ofEdgeAt: 5] = nil
        graph[names, of: 9] = nil
        #expect(graph[labels, ofEdgeAt: 0] == "a" && copy[labels, ofEdgeAt: 0] == "b" && graph[names, of: 9] == nil)
    }
}
