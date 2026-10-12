// Generations (catalog AM-11, GraphProtocols' `GraphGeneration`): every structural mutation of an
// AdjacencyList or UndirectedAdjacencyList starts a new one, and a call that changes nothing (an
// existing vertex or edge, an absent one, clearing an empty graph) does not; nor do attaching and
// writing maps or reserving capacity. A copy is in the same generation until either is mutated,
// and a built or decoded graph has one. Each test is self-contained.

import AdjacencyListModule
import Foundation
import GraphProtocols
import Testing

@Suite("AdjacencyList generations")
struct AdjacencyListGenerationTests {
    @Test("AM-11 AdjacencyList: every structural mutation starts a generation; a call that changes nothing does not")
    func directed() throws {
        var graph = AdjacencyList<Int>()
        // Never mutated: no generation, current for nothing.
        #expect(!graph.generation.isCurrent(for: graph))
        graph.removeAll()
        graph.removeAllEdges()
        #expect(!graph.generation.isCurrent(for: graph))
        graph.insert(0)
        var seen = graph.generation
        #expect(seen.isCurrent(for: graph))

        let steps: [(String, (inout AdjacencyList<Int>) throws -> Void)] = [
            ("insert(_:)", { _ = $0.insert(1) }),
            ("insert(edge:)", { _ = $0.insert(edge: DirectedEdge(from: 0, to: 1)) }),
            ("insert(edge:) with new endpoints", { _ = $0.insert(edge: DirectedEdge(from: 2, to: 3)) }),
            ("insert(checked:)", { _ = try $0.insert(checked: DirectedEdge(from: 1, to: 2)) }),
            ("remove(edge:)", { _ = $0.remove(edge: DirectedEdge(from: 0, to: 1)) }),
            ("_removeEdge(at:)", { _ = $0._removeEdge(at: 0) }),
            ("_insertVertex", { _ = $0._insertVertex(9) }),
            ("_insertEdge(fromKey:toKey:)", { _ = $0._insertEdge(fromKey: 0, toKey: 1) }),
            ("remove(_:) of an isolated vertex", { _ = $0.remove(9) }),
            ("remove(_:)", { _ = $0.remove(3) }),
            ("_removeVertex(atKey:)", { _ = $0._removeVertex(atKey: 0) }),
            ("insert(edge:) before removeAllEdges", { _ = $0.insert(edge: DirectedEdge(from: 1, to: 2)) }),
            ("removeAllEdges(keepingCapacity:)", { $0.removeAllEdges(keepingCapacity: true) }),
            ("removeAll(keepingCapacity:)", { $0.removeAll() }),
        ]
        for (name, step) in steps {
            try step(&graph)
            #expect(!seen.isCurrent(for: graph), "\(name)")
            #expect(graph.generation.isCurrent(for: graph), "\(name)")
            seen = graph.generation
        }

        graph.insert(edge: DirectedEdge(from: 5, to: 6))
        seen = graph.generation
        let unchanged: [(String, (inout AdjacencyList<Int>) throws -> Void)] = [
            ("insert(_:) of a vertex", { _ = $0.insert(5) }),
            ("insert(edge:) of an edge", { _ = $0.insert(edge: DirectedEdge(from: 5, to: 6)) }),
            ("_insertEdge(fromKey:toKey:) of an edge", { _ = $0._insertEdge(fromKey: 0, toKey: 1) }),
            ("remove(_:) of a non-vertex", { _ = $0.remove(9) }),
            ("remove(edge:) of an absent edge", { _ = $0.remove(edge: DirectedEdge(from: 6, to: 5)) }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 100, edgeCount: 100) }),
            ("attaching and writing maps", {
                let w = $0.addEdgeMap(default: 0)
                $0[w, ofEdgeAt: 0] = 3
                let t = $0.addVertexMap(of: String.self)
                $0[t, of: 5] = "five"
                $0.removeEdgeMap(w)
                $0.removeVertexMap(t)
            }),
        ]
        for (name, step) in unchanged {
            try step(&graph)
            #expect(seen.isCurrent(for: graph), "\(name)")
        }
    }

    @Test("AM-11 UndirectedAdjacencyList: every structural mutation starts a generation; a call that changes nothing does not")
    func undirected() throws {
        var graph = UndirectedAdjacencyList<Int>()
        #expect(!graph.generation.isCurrent(for: graph))
        graph.removeAll()
        graph.removeAllEdges()
        #expect(!graph.generation.isCurrent(for: graph))
        graph.insert(0)
        var seen = graph.generation
        #expect(seen.isCurrent(for: graph))

        let steps: [(String, (inout UndirectedAdjacencyList<Int>) throws -> Void)] = [
            ("insert(_:)", { _ = $0.insert(1) }),
            ("insert(edge:)", { _ = $0.insert(edge: UndirectedEdge(0, 1)) }),
            ("insert(edge:) with new endpoints", { _ = $0.insert(edge: UndirectedEdge(2, 3)) }),
            ("insert(checked:)", { _ = try $0.insert(checked: UndirectedEdge(1, 2)) }),
            ("_reverseEdge(at:)", { $0._reverseEdge(at: 0) }),
            ("_insertVertex", { _ = $0._insertVertex(9) }),
            ("_insertEdge(fromKey:toKey:)", { _ = $0._insertEdge(fromKey: 0, toKey: 0) }),
            ("remove(edge:)", { _ = $0.remove(edge: UndirectedEdge(1, 0)) }),
            ("remove(_:)", { _ = $0.remove(3) }),
            ("insert(edge:) before removeAllEdges", { _ = $0.insert(edge: UndirectedEdge(2, 9)) }),
            ("removeAllEdges(keepingCapacity:)", { $0.removeAllEdges(keepingCapacity: true) }),
            ("removeAll(keepingCapacity:)", { $0.removeAll() }),
        ]
        for (name, step) in steps {
            try step(&graph)
            #expect(!seen.isCurrent(for: graph), "\(name)")
            #expect(graph.generation.isCurrent(for: graph), "\(name)")
            seen = graph.generation
        }

        graph.insert(edge: UndirectedEdge(5, 6))
        seen = graph.generation
        let unchanged: [(String, (inout UndirectedAdjacencyList<Int>) throws -> Void)] = [
            ("insert(_:) of a vertex", { _ = $0.insert(5) }),
            ("insert(edge:) of an edge, reversed", { _ = $0.insert(edge: UndirectedEdge(6, 5)) }),
            ("insert(checked:) of an edge", { _ = try $0.insert(checked: UndirectedEdge(5, 6)) }),
            ("_insertEdge(fromKey:toKey:) of an edge", { _ = $0._insertEdge(fromKey: 1, toKey: 0) }),
            ("remove(_:) of a non-vertex", { _ = $0.remove(9) }),
            ("remove(edge:) of an absent edge", { _ = $0.remove(edge: UndirectedEdge(5, 5)) }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 100, edgeCount: 100) }),
            ("attaching and writing maps", {
                let w = $0.addEdgeMap(default: 0)
                $0[w, ofEdgeAt: 0] = 3
                let t = $0.addVertexMap(default: "")
                $0[t, of: 5] = "five"
            }),
        ]
        for (name, step) in unchanged {
            try step(&graph)
            #expect(seen.isCurrent(for: graph), "\(name)")
        }
    }

    @Test("AM-11 a copy shares the generation until either is mutated; built and decoded graphs have one")
    func copiesAndConstruction() throws {
        var graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
        let built = graph.generation
        #expect(built.isCurrent(for: graph))
        var copy = graph
        #expect(built.isCurrent(for: copy) && copy.generation.isCurrent(for: graph))
        copy.insert(edge: DirectedEdge(from: 1, to: 2))
        #expect(!built.isCurrent(for: copy) && built.isCurrent(for: graph))
        graph.remove(edge: DirectedEdge(from: 0, to: 1))
        #expect(!built.isCurrent(for: graph) && !graph.generation.isCurrent(for: copy))
        let decoded = try JSONDecoder().decode(AdjacencyList<Int>.self, from: JSONEncoder().encode(copy))
        #expect(decoded.generation.isCurrent(for: decoded) && !decoded.generation.isCurrent(for: copy))
        #expect(decoded == copy)
        // The identity conversion is the same graph; the bulk builds stamp a generation.
        #expect(AdjacencyList(copy).generation.isCurrent(for: copy))
        let sorted = AdjacencyList<Int>(_vertexCount: 3, sortedEdges: [DirectedEdge(from: 0, to: 1)], _ConstructionToken())
        #expect(sorted.generation.isCurrent(for: sorted))
        let empty = AdjacencyList<Int>(_vertexCount: 0, sortedEdges: [], _ConstructionToken())
        #expect(empty.generation.isCurrent(for: empty))
        let slotted = AdjacencyList<String>(_uncheckedVertices: ["a", "b"], sortedSlotEdges: [DirectedEdge(from: 0, to: 1)])
        #expect(slotted.generation.isCurrent(for: slotted))
        let fileOrder = AdjacencyList<Int>._built(vertices: [0, 1], sourceKeys: [1], targetKeys: [0], reportingPositions: false, _ConstructionToken()).graph
        #expect(fileOrder.generation.isCurrent(for: fileOrder))
        let undirectedSorted = UndirectedAdjacencyList<Int>(_vertexCount: 3, sortedEdges: [UndirectedEdge(0, 1)], _ConstructionToken())
        #expect(undirectedSorted.generation.isCurrent(for: undirectedSorted))
        let undirectedSlotted = UndirectedAdjacencyList<String>(_uncheckedVertices: ["a", "b"], sortedSlotEdges: [UndirectedEdge(0, 1)])
        #expect(undirectedSlotted.generation.isCurrent(for: undirectedSlotted))
        let undirectedFileOrder = UndirectedAdjacencyList<Int>._built(vertices: [0, 1], uKeys: [1], vKeys: [0], reportingPositions: false, _ConstructionToken()).graph
        #expect(undirectedFileOrder.generation.isCurrent(for: undirectedFileOrder))

        var undirected = UndirectedAdjacencyList<Int>(edges: [UndirectedEdge(0, 1)])
        let seen = undirected.generation
        let undirectedCopy = undirected
        #expect(seen.isCurrent(for: undirectedCopy))
        undirected.insert(edge: UndirectedEdge(1, 2))
        #expect(seen.isCurrent(for: undirectedCopy) && !seen.isCurrent(for: undirected))
        // Views report the graph's.
        #expect(undirected.generation.isCurrent(for: undirected.directedView))
    }
}
