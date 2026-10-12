// Generations (GraphProtocols' `GraphGeneration`): every structural mutation of a Pseudograph or
// DirectedPseudograph starts a new one, and a call that changes nothing (an existing vertex, an
// absent edge or vertex, clearing an empty graph) does not; nor do attaching, writing and removing
// maps or reserving capacity. A copy is in the same generation until either is mutated, and a
// built or decoded graph has one. The multigraphs report their base's. Each test is
// self-contained.

import Foundation
import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs generations")
struct MultigraphGenerationTests {
    @Test("Pseudograph: every structural mutation starts a generation; a call that changes nothing does not")
    func pseudograph() throws {
        var graph = Pseudograph<Int>()
        // Never mutated: no generation, current for nothing.
        #expect(!graph.generation.isCurrent(for: graph))
        graph.removeAll()
        graph.removeAllEdges()
        #expect(!graph.generation.isCurrent(for: graph))
        graph.insert(0)
        var seen = graph.generation
        #expect(seen.isCurrent(for: graph))

        let steps: [(String, (inout Pseudograph<Int>) throws -> Void)] = [
            ("insert(_:)", { _ = $0.insert(1) }),
            ("insert(edge:)", { _ = $0.insert(edge: UndirectedEdge(0, 1)) }),
            ("insert(edge:), a copy", { _ = $0.insert(edge: UndirectedEdge(1, 0)) }),
            ("insert(edge:), a loop with a new endpoint", { _ = $0.insert(edge: UndirectedEdge(2, 2)) }),
            ("insert(checked:)", { _ = try $0.insert(checked: UndirectedEdge(1, 2)) }),
            ("remove(edge:)", { _ = $0.remove(edge: UndirectedEdge(0, 1)) }),
            ("remove(edgeAt:)", { _ = $0.remove(edgeAt: 0) }),
            ("_insertVertex", { _ = $0._insertVertex(9) }),
            ("_insertEdge(fromKey:toKey:)", { _ = $0._insertEdge(fromKey: 0, toKey: 1) }),
            ("removeAllEdges(between:and:)", { _ = $0.removeAllEdges(between: 0, and: 1) }),
            ("remove(_:) of an isolated vertex", { _ = $0.remove(9) }),
            ("remove(_:)", { _ = $0.remove(2) }),
            ("insert(edge:) before removeAllEdges", { _ = $0.insert(edge: UndirectedEdge(0, 1)) }),
            ("removeAllEdges(keepingCapacity:)", { $0.removeAllEdges(keepingCapacity: true) }),
            ("removeAll(keepingCapacity:)", { $0.removeAll() }),
        ]
        for (name, step) in steps {
            try step(&graph)
            #expect(!seen.isCurrent(for: graph), "\(name) kept the generation")
            seen = graph.generation
            #expect(seen.isCurrent(for: graph), "\(name)")
        }

        graph.insert(edge: UndirectedEdge(0, 1))
        seen = graph.generation
        let unchanged: [(String, (inout Pseudograph<Int>) throws -> Void)] = [
            ("insert(_:) of a vertex", { _ = $0.insert(0) }),
            ("remove(edge:) of an absent edge", { _ = $0.remove(edge: UndirectedEdge(0, 7)) }),
            ("removeAllEdges(between:and:) of an absent pair", { _ = $0.removeAllEdges(between: 1, and: 1) }),
            ("remove(_:) of a non-vertex", { _ = $0.remove(7) }),
            ("insert(checked:) that throws", { _ = try? $0.insert(checked: UndirectedEdge(0, 7)) }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 100, edgeCount: 100) }),
            ("attaching and writing maps", {
                let w = $0.addEdgeMap(default: 0.0)
                let t = $0.addVertexMap(of: String.self)
                $0[w, ofEdgeAt: 0] = 2
                $0[t, of: 1] = "one"
                $0.removeVertexMap(t)
            }),
        ]
        for (name, step) in unchanged {
            try step(&graph)
            #expect(seen.isCurrent(for: graph), "\(name) started a generation")
        }
        // Clearing the edges of a graph with none changes nothing either.
        var isolated = Pseudograph(vertices: [0, 1])
        let before = isolated.generation
        isolated.removeAllEdges()
        #expect(before.isCurrent(for: isolated))
    }

    @Test("DirectedPseudograph: every structural mutation starts a generation; a call that changes nothing does not")
    func directedPseudograph() throws {
        var graph = DirectedPseudograph<Int>()
        #expect(!graph.generation.isCurrent(for: graph))
        graph.removeAll()
        #expect(!graph.generation.isCurrent(for: graph))
        graph.insert(0)
        var seen = graph.generation

        let steps: [(String, (inout DirectedPseudograph<Int>) throws -> Void)] = [
            ("insert(_:)", { _ = $0.insert(1) }),
            ("insert(edge:)", { _ = $0.insert(edge: DirectedEdge(from: 0, to: 1)) }),
            ("insert(edge:), a copy", { _ = $0.insert(edge: DirectedEdge(from: 0, to: 1)) }),
            ("insert(checked:)", { _ = try $0.insert(checked: DirectedEdge(from: 1, to: 1)) }),
            ("remove(edge:)", { _ = $0.remove(edge: DirectedEdge(from: 0, to: 1)) }),
            ("remove(edgeAt:)", { _ = $0.remove(edgeAt: 0) }),
            ("_insertVertex", { _ = $0._insertVertex(9) }),
            ("_insertEdge(fromKey:toKey:)", { _ = $0._insertEdge(fromKey: 0, toKey: 2) }),
            ("_removeEdge(at:)", { _ = $0._removeEdge(at: 0) }),
            ("removeAllEdges(from:to:)", { _ = $0.removeAllEdges(from: 0, to: 9) }),
            ("_removeVertex(atKey:)", { _ = $0._removeVertex(atKey: 2) }),
            ("remove(_:)", { _ = $0.remove(1) }),
            ("insert(edge:) before removeAllEdges", { _ = $0.insert(edge: DirectedEdge(from: 0, to: 0)) }),
            ("removeAllEdges(keepingCapacity:)", { $0.removeAllEdges(keepingCapacity: false) }),
            ("removeAll(keepingCapacity:)", { $0.removeAll(keepingCapacity: true) }),
        ]
        for (name, step) in steps {
            try step(&graph)
            #expect(!seen.isCurrent(for: graph), "\(name) kept the generation")
            seen = graph.generation
        }

        graph.insert(edge: DirectedEdge(from: 0, to: 1))
        seen = graph.generation
        _ = graph.insert(1)
        _ = graph.remove(edge: DirectedEdge(from: 1, to: 0))
        _ = graph.removeAllEdges(from: 1, to: 0)
        _ = graph.remove(5)
        graph.reserveCapacity(vertexCount: 10, edgeCount: 10)
        let w = graph.addEdgeMap(default: 1)
        graph[w, ofEdgeAt: 0] = 5
        graph.removeEdgeMap(w)
        #expect(seen.isCurrent(for: graph))
    }

    @Test("a copy shares the generation until either is mutated, and each then has its own")
    func copies() {
        var graph = Pseudograph(edges: [UndirectedEdge(0, 1)])
        var copy = graph
        let shared = graph.generation
        #expect(shared.isCurrent(for: copy))
        copy.insert(edge: UndirectedEdge(1, 2))
        #expect(shared.isCurrent(for: graph))
        #expect(!shared.isCurrent(for: copy))
        graph.insert(edge: UndirectedEdge(1, 2))
        // Equal graphs from different histories are in different generations.
        #expect(graph == copy)
        #expect(!graph.generation.isCurrent(for: copy))
        #expect(!copy.generation.isCurrent(for: graph))
    }

    @Test("built, bulk-built and decoded graphs have a generation")
    func builtGraphs() throws {
        let built = Pseudograph(edges: [UndirectedEdge(0, 1)])
        #expect(built.generation.isCurrent(for: built))
        let sorted = Pseudograph<Int>(_vertexCount: 3, sortedEdges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)], _ConstructionToken())
        #expect(sorted.generation.isCurrent(for: sorted))
        let directedSorted = DirectedPseudograph<Int>(_vertexCount: 3, sortedEdges: [DirectedEdge(from: 0, to: 1)], _ConstructionToken())
        #expect(directedSorted.generation.isCurrent(for: directedSorted))
        let keyed = Pseudograph<Int>._built(vertices: [0, 1, 2], uKeys: [0, 1], vKeys: [1, 1], reportingPositions: false, _ConstructionToken()).graph
        #expect(keyed.generation.isCurrent(for: keyed))
        let directedKeyed = DirectedPseudograph<Int>._built(vertices: [0, 1], sourceKeys: [0], targetKeys: [1], reportingPositions: false, _ConstructionToken()).graph
        #expect(directedKeyed.generation.isCurrent(for: directedKeyed))
        let decoded = try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: Data(#"{"vertices":[0,1],"edges":[0,1]}"#.utf8))
        #expect(decoded.generation.isCurrent(for: decoded))
        // A decoded graph is a new graph: not in the generation of the one encoded.
        let encoded = DirectedPseudograph(edges: [DirectedEdge(from: 0, to: 1)])
        let roundTrip = try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: JSONEncoder().encode(encoded))
        #expect(!encoded.generation.isCurrent(for: roundTrip))
    }

    @Test("the multigraphs report their base's generation, and their mutations start new ones")
    func multigraphs() throws {
        var graph = try #require(Multigraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]))
        var seen = graph.generation
        #expect(seen.isCurrent(for: graph))
        #expect(seen.isCurrent(for: graph.base))
        #expect(seen.isCurrent(for: Pseudograph(graph)))
        _ = try graph.insert(edge: UndirectedEdge(1, 2))
        #expect(!seen.isCurrent(for: graph))
        seen = graph.generation
        #expect(throws: LooplessEdgeError.selfLoop) { try graph.insert(edge: UndirectedEdge(2, 2)) }
        #expect(seen.isCurrent(for: graph))
        graph.remove(edgeAt: 0)
        #expect(!seen.isCurrent(for: graph))

        var directed = try #require(DirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1)]))
        var directedSeen = directed.generation
        #expect(directedSeen.isCurrent(for: directed.base))
        #expect(throws: LooplessEdgeError.missingEndpoint) { try directed.insert(checked: DirectedEdge(from: 0, to: 5)) }
        #expect(directedSeen.isCurrent(for: directed))
        let w = directed.addEdgeMap(default: 0)
        directed[w, ofEdgeAt: 0] = 3
        #expect(directedSeen.isCurrent(for: directed))
        _ = directed.remove(0)
        #expect(!directedSeen.isCurrent(for: directed))
        directedSeen = directed.generation
        #expect(directedSeen.isCurrent(for: DirectedPseudograph(directed)))
    }
}
