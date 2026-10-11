// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The
// same setup then runs in this process without the fault, so the trap is the call's and not the
// setup's. Then the preconditions the catalog does not list (extra_traps.swift).
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphOperations
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing

@Suite("GraphOperations preconditions", .tags(.precondition))
struct GraphOperationsPreconditionTests {
    @Test("GO-022 label not in base traps")
    func go022() async {
        // AL V [a, b]; E [a→b] / .inducedSubgraph(on: [a, z]) → **trap** (z is not a vertex)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.inducedSubgraph(on: ["a", "z"])
        }
        // Without the fault: the same setup, accepted.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"]])
        #expect(graph.vertexIndexBound == 2)
        let view = graph.inducedSubgraph(on: ["a"])
        #expect(Array(view.vertices) == ["a"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { view.vertex(atIndex: $0) } == ["a"])
        #expect(view.vertexCount == 1 && view.edgeCount == 0 && view.edges.count == 0)
        #expect(view.vertexIndexBound == 1 && view.edgeIndexBound == nil)
        #expect(Array(view.edges.indices) == [] as [Int])
        #expect(view.edges.map { [$0.source, $0.target] } == [] as [[String]])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.outEdges(of: "a")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.outDegree(of: "a") == 0 && view.outDegree(ofIndex: 0) == 0)
        #expect(Array(view.predecessors(of: "a")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.inEdges(of: "a")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.inDegree(of: "a") == 0 && view.inDegree(ofIndex: 0) == 0 && view.degree(of: "a") == 0)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false])
    }

    @Test("GO-023 base vertex outside the view: vertexIndex traps")
    func go023() async {
        // AL V [a, b]; E [a→b] / .inducedSubgraph(on: [a]) / .vertexIndex(of: b) → **trap** (b is not a vertex of the subgraph)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            let view = graph.inducedSubgraph(on: ["a"])
            _ = view.vertexIndex(of: "b")
        }
        // Without the fault: the same setup, accepted.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"]])
        #expect(graph.vertexIndexBound == 2)
        let view = graph.inducedSubgraph(on: ["a"])
        #expect(Array(view.vertices) == ["a"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { view.vertex(atIndex: $0) } == ["a"])
        #expect(view.vertexCount == 1 && view.edgeCount == 0 && view.edges.count == 0)
        #expect(view.vertexIndexBound == 1 && view.edgeIndexBound == nil)
        #expect(Array(view.edges.indices) == [] as [Int])
        #expect(view.edges.map { [$0.source, $0.target] } == [] as [[String]])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.outEdges(of: "a")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.outDegree(of: "a") == 0 && view.outDegree(ofIndex: 0) == 0)
        #expect(Array(view.predecessors(of: "a")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.inEdges(of: "a")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.inDegree(of: "a") == 0 && view.inDegree(ofIndex: 0) == 0 && view.degree(of: "a") == 0)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false])
    }

    @Test("GO-025 base without vertex indices traps (phase 1)")
    func go025() async {
        // Stable (with holes) V [a, b]; E [a→b] / .inducedSubgraph(on: [a]) → **trap** (the base has no vertex indices (vertexIndexBound is nil))
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<String>(vertices: ["a", "b", "removed"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.remove("removed")
            _ = graph.inducedSubgraph(on: ["a"])
        }
        // Without the removal the same base has vertex indices, and the call is accepted.
        let graph = StableDirectedGraph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(graph.vertexIndexBound == 2)
        let view = graph.inducedSubgraph(on: ["a"])
        #expect(Array(view.vertices) == ["a"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { view.vertex(atIndex: $0) } == ["a"])
        #expect(view.vertexCount == 1 && view.edgeCount == 0 && view.edges.count == 0)
        #expect(view.vertexIndexBound == 1 && view.edgeIndexBound == nil)
        #expect(Array(view.edges.indices) == [] as [Int])
        #expect(view.edges.map { [$0.source, $0.target] } == [] as [[String]])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.outEdges(of: "a")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.outDegree(of: "a") == 0 && view.outDegree(ofIndex: 0) == 0)
        #expect(Array(view.predecessors(of: "a")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.inEdges(of: "a")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.inDegree(of: "a") == 0 && view.inDegree(ofIndex: 0) == 0 && view.degree(of: "a") == 0)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false])
        // The removal itself leaves a hole.
        var holed = StableDirectedGraph<String>(vertices: ["a", "b", "removed"], edges: [DirectedEdge(from: "a", to: "b")])
        _ = holed.remove("removed")
        #expect(holed.vertexIndexBound == nil && Array(holed.vertices) == ["a", "b"])
    }

    @Test("GO-036 position not in base traps")
    func go036() async {
        // AL V [a, b]; E [a→b] / .spanningSubgraph(edges: [0, 5]) → **trap** (5 is not an edge position of the base)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.spanningSubgraph(edges: [0, 5])
        }
        // Without the fault: the same setup, accepted.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"]])
        #expect(graph.vertexIndexBound == 2)
        let view = graph.spanningSubgraph(edges: [0])
        #expect(Array(view.vertices) == ["a", "b"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { view.vertex(atIndex: $0) } == ["a", "b"])
        #expect(view.vertexCount == 2 && view.edgeCount == 1 && view.edges.count == 1)
        #expect(view.vertexIndexBound == 2 && view.edgeIndexBound == 1)
        #expect(Array(view.edges.indices) == [0])
        #expect(view.edges.map { [$0.source, $0.target] } == [["a", "b"]])
        #expect(view.edges.indices.map { [view.source(ofEdgeAt: $0), view.target(ofEdgeAt: $0)] } == [["a", "b"]])
        #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(view.edges.indices.map { view.edgeIndex(of: $0) } == [0])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == ["b"])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(view.outEdges(of: "a")) == [0])
        #expect(Array(view.outEdges(ofIndex: 0)) == [0])
        #expect(view.outDegree(of: "a") == 1 && view.outDegree(ofIndex: 0) == 1)
        #expect(Array(view.predecessors(of: "a")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.inEdges(of: "a")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.inDegree(of: "a") == 0 && view.inDegree(ofIndex: 0) == 0 && view.degree(of: "a") == 1)
        #expect(view.contains("b"))
        #expect(Array(view.successors(of: "b")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 1)) == [] as [Int])
        #expect(Array(view.outEdges(of: "b")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 1)) == [] as [Int])
        #expect(view.outDegree(of: "b") == 0 && view.outDegree(ofIndex: 1) == 0)
        #expect(Array(view.predecessors(of: "b")) == ["a"])
        #expect(Array(view.predecessorIndices(ofIndex: 1)) == [0])
        #expect(Array(view.inEdges(of: "b")) == [0])
        #expect(Array(view.inEdges(ofIndex: 1)) == [0])
        #expect(view.inDegree(of: "b") == 1 && view.inDegree(ofIndex: 1) == 1 && view.degree(of: "b") == 1)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false, true, false, false])
    }

    @Test("GO-044 label not in base traps")
    func go044() async {
        // AL V [a, b]; E [a→b] / .subgraph(vertices: [q], edges: [0]) → **trap** (q is not a vertex)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.subgraph(vertices: ["q"], edges: [0])
        }
        // Without the fault: the same setup, accepted.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"]])
        #expect(graph.vertexIndexBound == 2)
        let view = graph.subgraph(vertices: ["a"], edges: [0])
        #expect(Array(view.vertices) == ["a"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { view.vertex(atIndex: $0) } == ["a"])
        #expect(view.vertexCount == 1 && view.edgeCount == 0 && view.edges.count == 0)
        #expect(view.vertexIndexBound == 1 && view.edgeIndexBound == 0)
        #expect(Array(view.edges.indices) == [] as [Int])
        #expect(view.edges.map { [$0.source, $0.target] } == [] as [[String]])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.outEdges(of: "a")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.outDegree(of: "a") == 0 && view.outDegree(ofIndex: 0) == 0)
        #expect(Array(view.predecessors(of: "a")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.inEdges(of: "a")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.inDegree(of: "a") == 0 && view.inDegree(ofIndex: 0) == 0 && view.degree(of: "a") == 0)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false])
    }

    @Test("GO-045 position not in base traps")
    func go045() async {
        // AL V [a, b]; E [a→b] / .subgraph(vertices: [a], edges: [3]) → **trap** (3 is not an edge position of the base)
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.subgraph(vertices: ["a"], edges: [3])
        }
        // Without the fault: the same setup, accepted.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "b"]])
        #expect(graph.vertexIndexBound == 2)
        let view = graph.subgraph(vertices: ["a"], edges: [0])
        #expect(Array(view.vertices) == ["a"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { view.vertex(atIndex: $0) } == ["a"])
        #expect(view.vertexCount == 1 && view.edgeCount == 0 && view.edges.count == 0)
        #expect(view.vertexIndexBound == 1 && view.edgeIndexBound == 0)
        #expect(Array(view.edges.indices) == [] as [Int])
        #expect(view.edges.map { [$0.source, $0.target] } == [] as [[String]])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == [] as [String])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.outEdges(of: "a")) == [] as [Int])
        #expect(Array(view.outEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.outDegree(of: "a") == 0 && view.outDegree(ofIndex: 0) == 0)
        #expect(Array(view.predecessors(of: "a")) == [] as [String])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [] as [Int])
        #expect(Array(view.inEdges(of: "a")) == [] as [Int])
        #expect(Array(view.inEdges(ofIndex: 0)) == [] as [Int])
        #expect(view.inDegree(of: "a") == 0 && view.inDegree(ofIndex: 0) == 0 && view.degree(of: "a") == 0)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false])
    }

    @Test("GO-063 base without vertex indices traps (phase 1)")
    func go063() async {
        // Stable (with holes) V [a, b]; E [] / .complement → **trap** (the base has no vertex indices (vertexIndexBound is nil))
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<String>(vertices: ["a", "b", "removed"], edges: [] as [DirectedEdge<String>])
            _ = graph.remove("removed")
            _ = graph.complement
        }
        // Without the removal the same base has vertex indices, and the call is accepted.
        let graph = StableDirectedGraph<String>(vertices: ["a", "b"], edges: [] as [DirectedEdge<String>])
        #expect(graph.vertexIndexBound == 2)
        let view = graph.complement
        #expect(Array(view.vertices) == ["a", "b"])
        #expect(view.vertices.map { view.vertexIndex(of: $0) } == [0, 1])
        #expect((0 ..< 2).map { view.vertex(atIndex: $0) } == ["a", "b"])
        #expect(view.vertexCount == 2 && view.edgeCount == 2 && view.edges.count == 2)
        #expect(view.vertexIndexBound == 2 && view.edgeIndexBound == nil)
        #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[0, 1], [1, 0]])
        #expect(view.edges.map { [$0.source, $0.target] } == [["a", "b"], ["b", "a"]])
        #expect(view.edges.indices.map { [view.source(ofEdgeAt: $0), view.target(ofEdgeAt: $0)] } == [["a", "b"], ["b", "a"]])
        #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[0, 1], [1, 0]])
        #expect(view.contains("a"))
        #expect(Array(view.successors(of: "a")) == ["b"])
        #expect(Array(view.successorIndices(ofIndex: 0)) == [1])
        #expect(view.outEdges(of: "a").map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(view.outEdges(ofIndex: 0).map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(view.outDegree(of: "a") == 1 && view.outDegree(ofIndex: 0) == 1)
        #expect(Array(view.predecessors(of: "a")) == ["b"])
        #expect(Array(view.predecessorIndices(ofIndex: 0)) == [1])
        #expect(view.inEdges(of: "a").map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[1, 0]])
        #expect(view.inEdges(ofIndex: 0).map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[1, 0]])
        #expect(view.inDegree(of: "a") == 1 && view.inDegree(ofIndex: 0) == 1 && view.degree(of: "a") == 2)
        #expect(view.contains("b"))
        #expect(Array(view.successors(of: "b")) == ["a"])
        #expect(Array(view.successorIndices(ofIndex: 1)) == [0])
        #expect(view.outEdges(of: "b").map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[1, 0]])
        #expect(view.outEdges(ofIndex: 1).map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[1, 0]])
        #expect(view.outDegree(of: "b") == 1 && view.outDegree(ofIndex: 1) == 1)
        #expect(Array(view.predecessors(of: "b")) == ["a"])
        #expect(Array(view.predecessorIndices(ofIndex: 1)) == [0])
        #expect(view.inEdges(of: "b").map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(view.inEdges(ofIndex: 1).map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(view.inDegree(of: "b") == 1 && view.inDegree(ofIndex: 1) == 1 && view.degree(of: "b") == 2)
        // contains(edge:) for every ordered pair, source-major.
        #expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == [false, true, true, false])
        // The removal itself leaves a hole.
        var holed = StableDirectedGraph<String>(vertices: ["a", "b", "removed"], edges: [] as [DirectedEdge<String>])
        _ = holed.remove("removed")
        #expect(holed.vertexIndexBound == nil && Array(holed.vertices) == ["a", "b"])
    }

    @Test("GO-070 self-loop traps (phase 1: the construction hook takes no self-loops)")
    func go070() async {
        // AL V [a, b]; E [a→a, a→b] / CompressedSparseRow.lineGraph(of: g) → **trap** (a self-loop's line graph has a self-loop, which the construction targets do not take)
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "a", to: "b")])
            _ = CompressedSparseRow.lineGraph(of: graph)
        }
        // Without the fault: the same setup, accepted.
        let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "a", to: "b")])
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "a"], ["a", "b"]])
        #expect(graph.vertexIndexBound == 2)
    }

    @Test("GO-092 vertex in two blocks traps")
    func go092() async {
        // UL V [a, b]; E [a–b] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a, b], [b]]) → **trap** (b is in two blocks)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = UndirectedAdjacencyList<Int>.quotient(of: graph, by: [["a", "b"], ["b"]])
        }
        // Without the fault: the same setup, accepted.
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"]])
        #expect(graph.vertexIndexBound == 2)
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, by: [["a"], ["b"]])
        #expect(result.vertexCount == 2 && result.edgeCount == 1)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [0])
        #expect(result.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(Array(result.neighbors(of: 0)) == [1])
        #expect(Array(result.neighbors(of: 1)) == [0])
    }

    @Test("GO-093 missing vertex traps")
    func go093() async {
        // UL V [a, b, c]; E [a–b] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a, b]]) → **trap** (the blocks do not cover every vertex)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b")])
            _ = UndirectedAdjacencyList<Int>.quotient(of: graph, by: [["a", "b"]])
        }
        // Without the fault: the same setup, accepted.
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b")])
        #expect(Array(graph.vertices) == ["a", "b", "c"])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"]])
        #expect(graph.vertexIndexBound == 3)
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, by: [["a", "b"], ["c"]])
        #expect(result.vertexCount == 2 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [0, 1])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(Array(result.neighbors(of: 0)) == [] as [Int])
        #expect(Array(result.neighbors(of: 1)) == [] as [Int])
    }

    @Test("GO-094 label not a vertex traps")
    func go094() async {
        // UL V [a, b]; E [a–b] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a, b, z]]) → **trap** (z is not a vertex)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = UndirectedAdjacencyList<Int>.quotient(of: graph, by: [["a", "b", "z"]])
        }
        // Without the fault: the same setup, accepted.
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "b"]])
        #expect(graph.vertexIndexBound == 2)
        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, by: [["a", "b"]])
        #expect(result.vertexCount == 1 && result.edgeCount == 0)
        #expect(Array(result.vertices) == [0])
        #expect(Array(result.edges.indices) == [] as [Int])
        #expect(result.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect(Array(result.neighbors(of: 0)) == [] as [Int])
    }

    @Test("GO-099 self-loop traps (phase 1)")
    func go099() async {
        // AL V [a]; E [a→a] ; AL V [b]; E [] / CompressedSparseRow.disjointUnion(g, h) → **trap** (a self-loop, which the construction targets do not take)
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<String>(vertices: ["a"], edges: [DirectedEdge(from: "a", to: "a")])
            let other = AdjacencyList<String>(vertices: ["b"], edges: [] as [DirectedEdge<String>])
            _ = CompressedSparseRow.disjointUnion(graph, other)
        }
        // Without the fault: the same setup, accepted.
        let graph = DirectedPseudograph<String>(vertices: ["a"], edges: [DirectedEdge(from: "a", to: "a")])
        #expect(Array(graph.vertices) == ["a"])
        #expect(graph.edges.map { [$0.source, $0.target] } == [["a", "a"]])
        #expect(graph.vertexIndexBound == 1)
        let other = AdjacencyList<String>(vertices: ["b"], edges: [] as [DirectedEdge<String>])
        #expect(Array(other.vertices) == ["b"])
        #expect(other.edges.map { [$0.source, $0.target] } == [] as [[String]])
        #expect(other.vertexIndexBound == 1)
    }

    @Test("GO-105 self-loop traps (phase 1)")
    func go105() async {
        // UL V [a]; E [a–a] ; UL V [b]; E [] / UndirectedAdjacencyList<Int>.join(g, h) → **trap** (a self-loop, which the construction targets do not take)
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<String>(vertices: ["a"], edges: [UndirectedEdge("a", "a")])
            let other = UndirectedAdjacencyList<String>(vertices: ["b"], edges: [] as [UndirectedEdge<String>])
            _ = UndirectedAdjacencyList<Int>.join(graph, other)
        }
        // Without the fault: the same setup, accepted.
        let graph = Pseudograph<String>(vertices: ["a"], edges: [UndirectedEdge("a", "a")])
        #expect(Array(graph.vertices) == ["a"])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "a"]])
        #expect(graph.vertexIndexBound == 1)
        let other = UndirectedAdjacencyList<String>(vertices: ["b"], edges: [] as [UndirectedEdge<String>])
        #expect(Array(other.vertices) == ["b"])
        #expect(other.edges.map { [$0.u, $0.v] } == [] as [[String]])
        #expect(other.vertexIndexBound == 1)
    }

    @Test("Label-space rows of a vertex outside a subgraph view trap; index-space reads past the bound trap")
    func subgraphOutsideVertices() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = Array(graph.inducedSubgraph(on: ["a"]).successors(of: "b"))
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = Array(graph.inducedSubgraph(on: ["b"]).predecessors(of: "a"))
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = Array(graph.inducedSubgraph(on: ["a"]).neighbors(of: "b"))
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.inducedSubgraph(on: ["a"]).vertex(atIndex: 1)
        }
        // Without the faults: the kept vertex answers.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let view = graph.inducedSubgraph(on: ["a"])
        #expect(Array(view.successors(of: "a")).isEmpty && view.vertex(atIndex: 0) == "a" && view.vertexIndexBound == 1)
        let undirected = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        #expect(Array(undirected.inducedSubgraph(on: ["a", "b"]).neighbors(of: "b")) == ["a"])
    }

    @Test("Undirected subgraph views trap on a label or a position the base does not have")
    func undirectedSubgraphFaults() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.inducedSubgraph(on: ["a", "z"])
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.spanningSubgraph(edges: [1])
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            _ = graph.subgraph(vertices: ["a", "q"], edges: [0])
        }
        // Without the faults.
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        #expect(graph.inducedSubgraph(on: ["a", "b"]).edgeCount == 1)
        #expect(graph.spanningSubgraph(edges: [0]).edgeIndexBound == 1)
        #expect(graph.subgraph(vertices: ["a"], edges: [0]).edgeCount == 0)
    }

    @Test("edgeIndex(of:) on an induced subgraph traps: it has no edge indices")
    func inducedHasNoEdgeIndices() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = graph.inducedSubgraph(on: ["a", "b"]).edgeIndex(of: 0)
        }
        // Without the fault: an edge set gives the same view edge indices.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(graph.inducedSubgraph(on: ["a", "b"]).edgeIndexBound == nil)
        #expect(graph.subgraph(vertices: ["a", "b"], edges: [0]).edgeIndex(of: 0) == 0)
    }

    @Test("Directed quotient traps on a vertex in two blocks, a missing vertex and a non-vertex")
    func directedQuotientFaults() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = CompressedSparseRow.quotient(of: graph, by: [["a"], ["a", "b"]])
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = CompressedSparseRow.quotient(of: graph, by: [["b"]])
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            _ = CompressedSparseRow.quotient(of: graph, by: [["a"], ["b"], ["z"]])
        }
        // Without the faults.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let result = CompressedSparseRow.quotient(of: graph, by: [["b"], ["a"]])
        #expect(result.vertexCount == 2 && result.edges.map { [$0.source, $0.target] } == [[1, 0]])
    }

    @Test("A self-loop in either input traps in disjointUnion and join, directed and undirected")
    func selfLoopsInEitherInput() async {
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a"], edges: [] as [DirectedEdge<String>])
            let h = AdjacencyList<String>(vertices: ["b"], edges: [DirectedEdge(from: "b", to: "b")])
            _ = CompressedSparseRow.disjointUnion(g, h)
        }
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a"], edges: [DirectedEdge(from: "a", to: "a")])
            let h = AdjacencyList<String>(vertices: ["b"], edges: [] as [DirectedEdge<String>])
            _ = CompressedSparseRow.join(g, h)
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a"], edges: [] as [UndirectedEdge<String>])
            let h = UndirectedAdjacencyList<String>(vertices: ["b"], edges: [UndirectedEdge("b", "b")])
            _ = UndirectedAdjacencyList<Int>.disjointUnion(g, h)
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a"], edges: [] as [UndirectedEdge<String>])
            let h = UndirectedAdjacencyList<String>(vertices: ["b"], edges: [UndirectedEdge("b", "b")])
            _ = UndirectedAdjacencyList<Int>.join(g, h)
        }
        // Without the loops.
        let g = AdjacencyList<String>(vertices: ["a"], edges: [] as [DirectedEdge<String>])
        let h = AdjacencyList<String>(vertices: ["b"], edges: [] as [DirectedEdge<String>])
        #expect(CompressedSparseRow.disjointUnion(g, h).edgeCount == 0)
        #expect(CompressedSparseRow.join(g, h).edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]])
        let u = UndirectedAdjacencyList<String>(vertices: ["a"], edges: [] as [UndirectedEdge<String>])
        #expect(UndirectedAdjacencyList<Int>.join(u, u).edges.map { [$0.u, $0.v] } == [[0, 1]])
    }

    @Test("A directed self-loop anywhere traps in lineGraph(of:); undirected it does not")
    func lineGraphSelfLoops() async {
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b")])
            _ = AdjacencyList<Int>.lineGraph(of: graph)
        }
        // Without the loop, and undirected with it.
        let graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        #expect(AdjacencyList<Int>.lineGraph(of: graph).vertexCount == 1)
        let undirected = Pseudograph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "b")])
        #expect(UndirectedAdjacencyList<Int>.lineGraph(of: undirected).edges.map { [$0.u, $0.v] } == [[0, 1]])
    }
}
