// Generations (GraphProtocols' `GraphGeneration`): every structural mutation of a
// StableDirectedGraph starts a new one, and a call that changes nothing (an existing vertex, an
// absent edge, the same endpoint) does not; attaching and writing maps and reserving capacity do
// not either. A copy is in the same generation until either is mutated, and a decoded or built
// graph has one. See README.md.

import Foundation
import GraphProtocols
import StableGraphs
import Testing

@Suite("StableGraphs generations")
struct StableGraphGenerationTests {
    @Test("Every structural mutation starts a generation; a call that changes nothing does not")
    func everyMutation() throws {
        var graph = StableDirectedGraph<Int>()
        // Never mutated: no generation, current for nothing.
        #expect(!graph.generation.isCurrent(for: graph))
        graph.insert(0)
        var seen = graph.generation
        #expect(seen.isCurrent(for: graph))

        // Each step mutates the graph; the previous generation must be stale after it, and the
        // new one current.
        let steps: [(String, (inout StableDirectedGraph<Int>) throws -> Void)] = [
            ("insert(_:)", { _ = $0.insert(1) }),
            ("insert(edge:)", { _ = $0.insert(edge: DirectedEdge(from: 0, to: 1)) }),
            ("insert(edge:) with new endpoints", { _ = $0.insert(edge: DirectedEdge(from: 2, to: 3)) }),
            ("insert(checked:)", { _ = try $0.insert(checked: DirectedEdge(from: 1, to: 2)) }),
            ("changeTarget(ofEdgeAt:to:)", { $0.changeTarget(ofEdgeAt: 0, to: 3) }),
            ("changeSource(ofEdgeAt:to:)", { $0.changeSource(ofEdgeAt: 0, to: 2) }),
            ("changeTarget(ofEdgeAt:checked:)", { try $0.changeTarget(ofEdgeAt: 0, checked: 1) }),
            ("changeSource(ofEdgeAt:checked:)", { try $0.changeSource(ofEdgeAt: 0, checked: 0) }),
            ("remove(edgeAt:)", { _ = $0.remove(edgeAt: 1) }),
            ("remove(edge:)", { _ = $0.remove(edge: DirectedEdge(from: 0, to: 1)) }),
            ("insert(edge:) 3→0", { _ = $0.insert(edge: DirectedEdge(from: 3, to: 0)) }),
            ("removeAllEdges(from:to:) removing", { _ = $0.removeAllEdges(from: 3, to: 0) }),
            ("insert(edge:) again", { _ = $0.insert(edge: DirectedEdge(from: 1, to: 2)) }),
            ("removeAllEdges(from:where:)", { _ = $0.removeAllEdges(from: 1) { _ in true } }),
            ("insert(edge:) for removeAllEdges(where:)", { _ = $0.insert(edge: DirectedEdge(from: 2, to: 2)) }),
            ("removeAllEdges(where:)", { _ = $0.removeAllEdges { _ in true } }),
            ("remove(_:)", { _ = $0.remove(3) }),
            ("insert(edge:) before removeAllEdges()", { _ = $0.insert(edge: DirectedEdge(from: 0, to: 2)) }),
            ("removeAllEdges(keepingCapacity:)", { $0.removeAllEdges(keepingCapacity: true) }),
            ("removeAll(keepingCapacity:)", { $0.removeAll() }),
        ]
        for (name, step) in steps {
            try step(&graph)
            #expect(!seen.isCurrent(for: graph), "\(name)")
            #expect(graph.generation.isCurrent(for: graph), "\(name)")
            seen = graph.generation
        }

        // Calls that change nothing keep the generation.
        graph.insert(5)
        graph.insert(edge: DirectedEdge(from: 5, to: 6))
        seen = graph.generation
        let unchanged: [(String, (inout StableDirectedGraph<Int>) throws -> Void)] = [
            ("insert(_:) of a vertex", { _ = $0.insert(5) }),
            ("remove(_:) of a non-vertex", { _ = $0.remove(9) }),
            ("remove(edge:) of an absent edge", { _ = $0.remove(edge: DirectedEdge(from: 6, to: 5)) }),
            ("removeAllEdges(from:to:) of none", { _ = $0.removeAllEdges(from: 6, to: 5) }),
            ("removeAllEdges(from:where:) choosing none", { _ = $0.removeAllEdges(from: 5) { _ in false } }),
            ("removeAllEdges(where:) choosing none", { _ = $0.removeAllEdges { _ in false } }),
            ("changeTarget(ofEdgeAt:to:) to the same target", { $0.changeTarget(ofEdgeAt: 0, to: 6) }),
            ("changeSource(ofEdgeAt:to:) to the same source", { $0.changeSource(ofEdgeAt: 0, to: 5) }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 100, edgeCount: 100) }),
            ("attaching and writing maps", {
                let w = $0.addEdgeMap(default: 0)
                $0[w, ofEdgeAt: 0] = 3
                let t = $0.addVertexMap(of: String.self)
                $0[t, of: 5] = "five"
                $0.removeEdgeMap(w)
            }),
        ]
        for (name, step) in unchanged {
            try step(&graph)
            #expect(seen.isCurrent(for: graph), "\(name)")
        }
    }

    @Test("A copy shares the generation until either is mutated; built and decoded graphs have one")
    func copiesAndConstruction() throws {
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
        let built = graph.generation
        #expect(built.isCurrent(for: graph))
        var copy = graph
        #expect(built.isCurrent(for: copy) && copy.generation.isCurrent(for: graph))
        copy.insert(edge: DirectedEdge(from: 1, to: 2))
        #expect(!built.isCurrent(for: copy) && built.isCurrent(for: graph))
        graph.remove(edgeAt: 0)
        #expect(!built.isCurrent(for: graph) && !graph.generation.isCurrent(for: copy))
        // The bulk initializers and decoding go through the same mutations.
        let sorted = StableDirectedGraph<Int>(_vertexCount: 3, sortedEdges: [DirectedEdge(from: 0, to: 1)], _ConstructionToken())
        #expect(sorted.generation.isCurrent(for: sorted))
        let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: JSONEncoder().encode(copy))
        #expect(decoded.generation.isCurrent(for: decoded) && !decoded.generation.isCurrent(for: copy))
        // Equality ignores the generation.
        #expect(decoded == copy)
        // Views report the graph's.
        #expect(copy.generation.isCurrent(for: copy.undirectedView))
    }
}
