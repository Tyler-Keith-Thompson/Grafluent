// Generations (GraphProtocols' `GraphGeneration`): a BipartiteGraph reports its base's, every
// structural mutation starts a new one, and a call that changes nothing does not: an existing
// vertex or edge, a mutation that throws `BipartitionError`, an absent vertex or edge, attaching,
// writing and removing maps, and reserving capacity. A copy is in the same generation until either
// is mutated, and a built or decoded graph has one. Each test is self-contained.

import AdjacencyListModule
import BipartiteGraphs
import Foundation
import GraphProtocols
import Testing

@Suite("BipartiteGraph generations")
struct BipartiteGraphGenerationTests {
    @Test("every structural mutation starts a generation, which is the base's")
    func mutations() throws {
        var graph = BipartiteGraph<Int>()
        #expect(!graph.generation.isCurrent(for: graph))
        _ = try graph.insert(0, on: .left)
        var seen = graph.generation
        #expect(seen.isCurrent(for: graph))
        #expect(seen.isCurrent(for: graph.base))

        let steps: [(String, (inout BipartiteGraph<Int>) throws -> Void)] = [
            ("insert(_:on:) left", { _ = try $0.insert(1, on: .left) }),
            ("insert(_:on:) right", { _ = try $0.insert(2, on: .right) }),
            ("insert(edge:)", { _ = try $0.insert(edge: UndirectedEdge(2, 0)) }),
            ("insert(checked:)", { _ = try $0.insert(checked: UndirectedEdge(1, 2)) }),
            ("remove(edge:)", { _ = $0.remove(edge: UndirectedEdge(0, 2)) }),
            ("remove(_:)", { _ = $0.remove(1) }),
            ("insert(_:on:) before removeAllEdges", { _ = try $0.insert(3, on: .right) }),
            ("insert(edge:) before removeAllEdges", { _ = try $0.insert(edge: UndirectedEdge(0, 3)) }),
            ("removeAllEdges(keepingCapacity:)", { $0.removeAllEdges(keepingCapacity: true) }),
            ("removeAll(keepingCapacity:)", { $0.removeAll() }),
        ]
        for (name, step) in steps {
            try step(&graph)
            #expect(!seen.isCurrent(for: graph), "\(name) kept the generation")
            seen = graph.generation
            #expect(seen.isCurrent(for: graph), "\(name)")
            #expect(seen.isCurrent(for: graph.base), "\(name)")
        }
    }

    @Test("a call that changes nothing keeps the generation")
    func unchanged() throws {
        var graph = try #require(BipartiteGraph(left: [0, 1], right: [2], edges: [UndirectedEdge(0, 2)]))
        let seen = graph.generation
        #expect(seen.isCurrent(for: graph))
        let steps: [(String, (inout BipartiteGraph<Int>) throws -> Void)] = [
            ("insert(_:on:) of a vertex on its side", { _ = try $0.insert(0, on: .left) }),
            ("insert(_:on:) on the other side", { _ = try? $0.insert(0, on: .right) }),
            ("insert(edge:) of an edge", { _ = try $0.insert(edge: UndirectedEdge(2, 0)) }),
            ("insert(edge:) inside a side", { _ = try? $0.insert(edge: UndirectedEdge(0, 1)) }),
            ("insert(checked:) with a missing endpoint", { _ = try? $0.insert(checked: UndirectedEdge(0, 9)) }),
            ("remove(edge:) of an absent edge", { _ = $0.remove(edge: UndirectedEdge(1, 2)) }),
            ("remove(_:) of a non-vertex", { _ = $0.remove(9) }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 100, edgeCount: 100) }),
            ("attaching and writing maps", {
                let w = $0.addEdgeMap(default: 0.0)
                let t = $0.addVertexMap(of: String.self)
                $0[w, ofEdgeAt: 0] = 2
                $0[t, of: 1] = "one"
                $0.removeVertexMap(t)
                $0.removeEdgeMap(w)
            }),
            ("side and projection reads", {
                _ = $0.side(of: 0)
                _ = $0.projectedGraph(onto: .left)
                _ = Array($0.left)
            }),
        ]
        for (name, step) in steps {
            try step(&graph)
            #expect(seen.isCurrent(for: graph), "\(name) started a generation")
        }
    }

    @Test("a copy shares the generation until either is mutated")
    func copies() throws {
        var graph = try #require(BipartiteGraph(left: [0], right: [1], edges: [UndirectedEdge(0, 1)]))
        var copy = graph
        let shared = graph.generation
        #expect(shared.isCurrent(for: copy))
        _ = try copy.insert(2, on: .right)
        #expect(shared.isCurrent(for: graph))
        #expect(!shared.isCurrent(for: copy))
        _ = try graph.insert(2, on: .right)
        #expect(graph == copy)
        #expect(!graph.generation.isCurrent(for: copy))
    }

    @Test("built, converted and decoded graphs have a generation")
    func builtGraphs() throws {
        let sides = try #require(BipartiteGraph(left: [0], right: [1]))
        #expect(sides.generation.isCurrent(for: sides))
        let built = try #require(BipartiteGraph(left: [0], right: [1], edges: [UndirectedEdge(1, 0)]))
        #expect(built.generation.isCurrent(for: built))
        let list: UndirectedAdjacencyList<Int> = [0: [1], 1: [2]]
        let fromList = try #require(BipartiteGraph(list))
        #expect(fromList.generation.isCurrent(for: fromList))
        let fromLeft = try #require(BipartiteGraph(list, left: [1]))
        #expect(fromLeft.generation.isCurrent(for: fromLeft))
        let decoded = try JSONDecoder().decode(BipartiteGraph<Int>.self, from: JSONEncoder().encode(built))
        #expect(decoded.generation.isCurrent(for: decoded))
        #expect(!built.generation.isCurrent(for: decoded))
    }
}
