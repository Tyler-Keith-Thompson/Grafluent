// Generations (GraphProtocols' `GraphGeneration`): every structural mutation of a
// StableDirectedGraph starts a new one, and a call that changes nothing (an existing vertex, an
// absent edge, the same endpoint) does not; attaching and writing maps and reserving capacity do
// not either. A copy is in the same generation until either is mutated, and a decoded or built
// graph has one. See README.md.
// Two copies, under every interleaving of three steps, never share a generation in different
// states.

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

    @Test("Emptying the edges, then resetting the edge positions, starts a generation each time")
    func emptiedEdges() {
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
        // The last live edge goes, and its page with it.
        graph.remove(edgeAt: 0)
        let emptied = graph.generation
        #expect(emptied.isCurrent(for: graph))
        // No live edge, but the positions start over: a structural change.
        graph.removeAllEdges()
        #expect(!emptied.isCurrent(for: graph) && graph.generation.isCurrent(for: graph))
        #expect(graph.edges.endIndex == 0)
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

    @Test("StableDirectedGraph: two copies never share a generation in different states, under every interleaving of three steps")
    func divergence() {
        // Two copies of one graph, each step applied to either: whenever two generations seen along
        // the way are current for each other, the states they were read from are the same. The
        // states are read into plain values, which hold none of the graph's storage, so the copies'
        // arrays are shared exactly as the steps leave them.
        func state(of graph: StableDirectedGraph<Int>) -> String {
            let vertices = graph.vertices, edges = graph.edges
            return "\(vertices.indices.map { "\($0):\(vertices[$0])" }) \(vertices.endIndex) \(edges.indices.map { "\($0):\(edges[$0])" }) \(edges.endIndex)"
        }
        func make() -> StableDirectedGraph<Int> {
            var graph = StableDirectedGraph<Int>()
            for (s, t) in [(0, 1), (1, 2), (2, 3), (3, 0), (0, 1)] { graph.insert(edge: DirectedEdge(from: s, to: t)) }
            return graph
        }
        let steps: [(String, (inout StableDirectedGraph<Int>) -> Void)] = [
            ("insert(_:)", { _ = $0.insert(9) }),
            ("insert(edge:)", { _ = $0.insert(edge: DirectedEdge(from: 4, to: 0)) }),
            ("insert(edge:) of a copy", { _ = $0.insert(edge: DirectedEdge(from: 0, to: 1)) }),
            ("remove(edge:)", { _ = $0.remove(edge: DirectedEdge(from: 1, to: 2)) }),
            ("remove(edgeAt:)", { if let p = $0.edges.indices.first { _ = $0.remove(edgeAt: p) } }),
            ("changeTarget(ofEdgeAt:checked:)", { if let p = $0.edges.indices.first { try? $0.changeTarget(ofEdgeAt: p, checked: 2) } }),
            ("changeSource(ofEdgeAt:checked:)", { if let p = $0.edges.indices.last { try? $0.changeSource(ofEdgeAt: p, checked: 0) } }),
            ("removeAllEdges(from:where:)", { _ = $0.removeAllEdges(from: 0) { _ in true } }),
            ("removeAllEdges(where:) choosing none", { _ = $0.removeAllEdges { _ in false } }),
            ("remove(_:)", { _ = $0.remove(2) }),
            ("remove(_:) of a non-vertex", { _ = $0.remove(7) }),
            ("removeAllEdges(keepingCapacity: true)", { $0.removeAllEdges(keepingCapacity: true) }),
            ("removeAll()", { $0.removeAll() }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 4096, edgeCount: 4096) }),
            ("a map attached and written", { let w = $0.addEdgeMap(default: 0); if let p = $0.edges.indices.first { $0[w, ofEdgeAt: p] = 1 } })
        ]
        var violations: [String] = []
        let choices = 2 * steps.count
        for first in 0 ..< choices {
            for second in 0 ..< choices {
                for third in 0 ..< choices {
                    var a = make()
                    var b = a
                    var seen = [(a.generation, state(of: a), "start")]
                    var history = ""
                    for choice in [first, second, third] {
                        let (name, step) = steps[choice % steps.count]
                        if choice < steps.count { step(&a) } else { step(&b) }
                        history += (choice < steps.count ? " a." : " b.") + name
                        seen.append((a.generation, state(of: a), "a after" + history))
                        seen.append((b.generation, state(of: b), "b after" + history))
                    }
                    for i in seen.indices {
                        for j in seen.indices where j > i && seen[i].0.isCurrent(for: seen[j].0) && seen[i].1 != seen[j].1 {
                            violations.append("\(seen[i].2) and \(seen[j].2)")
                        }
                    }
                }
            }
        }
        #expect(violations.isEmpty, "\(violations.count) violations, among them \(violations.prefix(3))")
    }

    @Test("With every vertex page freed, the resets still tell two copies apart; an empty decoded graph has a generation")
    func freedPages() throws {
        // A full page of vertices, all removed: the out-row table is empty again, and only the
        // ends tell the states apart.
        var graph = StableDirectedGraph<Int>()
        for v in 0 ..< 1024 { graph.insert(v) }
        graph.insert(edge: DirectedEdge(from: 0, to: 1))
        for v in 0 ..< 1024 { graph.remove(v) }
        #expect(graph.vertexCount == 0 && graph.vertices.endIndex == 1024 && graph.edges.endIndex == 1)
        let steps: [(String, (inout StableDirectedGraph<Int>) -> Void)] = [
            ("removeAll()", { $0.removeAll() }),
            ("removeAllEdges()", { $0.removeAllEdges() }),
        ]
        for (aName, a) in steps {
            for (bName, b) in steps {
                var first = graph
                var second = first
                a(&first)
                b(&second)
                let differ = first.vertices.endIndex != second.vertices.endIndex || first.edges.endIndex != second.edges.endIndex
                #expect(!differ || !first.generation.isCurrent(for: second.generation), "\(aName) and \(bName)")
            }
        }
        let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: JSONEncoder().encode(StableDirectedGraph<Int>()))
        #expect(decoded.generation.isCurrent(for: decoded))
    }

}
