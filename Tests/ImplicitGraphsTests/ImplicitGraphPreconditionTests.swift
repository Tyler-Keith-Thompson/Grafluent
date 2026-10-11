// Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The
// same setup then runs in this process without the fault. Then the preconditions the catalog
// does not list (extra_traps.swift).
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import ImplicitGraphs
import Testing
import Traversal

@Suite("ImplicitGraphs preconditions", .tags(.precondition))
struct ImplicitGraphPreconditionTests {
    @Test("IG-003 negative vertex count")
    func ig003() async {
        // ImplicitDirectedGraph(vertexCount: -1, successors: { _ in [] }) → **trap** (negative vertex count -1)
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: -1, successors: { _ in [] as [Int] })
        }
        // The nearest accepted input: no vertices.
        let graph = ImplicitDirectedGraph(vertexCount: 0, successors: { _ in [] as [Int] })
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.vertices.isEmpty)
    }

    @Test("IG-012 successors(of:) a non-vertex")
    func ig012() async {
        // IG (4, diamond) / successors(of: 4) → **trap** (4 is not a vertex of the graph)
        await #expect(processExitsWith: .failure) {
            var calls = 0
            let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
                calls += 1
                return [[1, 2], [3], [3], []][v]
            })
            _ = graph.successors(of: 4)
            _ = calls
        }
        // Without the call: the setup, in this process.
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        // The whole graph, from the model, with the closure calls each read makes.
        calls = 0
        #expect(graph.vertexCount == 4 && graph.vertexIndexBound == 4 && graph.edgeIndexBound == nil)
        #expect(Array(graph.vertices) == [0, 1, 2, 3] && !graph.contains(-1) && !graph.contains(4))
        #expect(graph.edgeCount == 4)
        #expect(calls == 4)
        calls = 0
        var iterated: [[Int]] = []
        for edge in graph.edges { iterated.append([edge.source, edge.target]) }
        #expect(iterated == [[0, 1], [0, 2], [1, 3], [2, 3]])
        #expect(calls == 4)
        calls = 0
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1, 2], [3], [3], [] as [Int]])
        #expect(calls == 4)
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1, 2], [3], [3], [] as [Int]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [2, 1, 1, 0])
        #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [2, 1, 1, 0])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3]])
        calls = 0
        let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
        #expect(calls == 4)
        #expect(positions.map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [0, 1, 2], [1, 0, 3], [2, 0, 3]])
        #expect(graph.vertices.flatMap { Array(graph.outEdges(ofIndex: $0)) } == positions)
        calls = 0
        #expect(positions.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == positions.map { [$0.source, $0.target] })
        #expect(positions.map { graph.edges[$0] } == positions.map { DirectedEdge(from: $0.source, to: $0.target) })
        #expect(calls == 0)
        // Stepping by index(after:) visits the positions iteration lists, in order.
        var stepped: [ImplicitDirectedGraph<[Int]>.Edges.Index] = []
        var position = graph.edges.startIndex
        while position != graph.edges.endIndex {
            stepped.append(position)
            position = graph.edges.index(after: position)
        }
        #expect(stepped == positions && stepped.map(\.target) == positions.map(\.target))
        #expect(Set(positions).count == 4 && positions == positions.sorted())
        calls = 0
        #expect(positions.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })
        #expect(calls == 4)
    }

    @Test("IG-013 outDegree(of:) a negative vertex")
    func ig013() async {
        // IG (4, diamond) / outDegree(of: -1) → **trap** (-1 is not a vertex of the graph)
        await #expect(processExitsWith: .failure) {
            var calls = 0
            let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
                calls += 1
                return [[1, 2], [3], [3], []][v]
            })
            _ = graph.outDegree(of: -1)
            _ = calls
        }
        // Without the call: the setup, in this process.
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        // The whole graph, from the model, with the closure calls each read makes.
        calls = 0
        #expect(graph.vertexCount == 4 && graph.vertexIndexBound == 4 && graph.edgeIndexBound == nil)
        #expect(Array(graph.vertices) == [0, 1, 2, 3] && !graph.contains(-1) && !graph.contains(4))
        #expect(graph.edgeCount == 4)
        #expect(calls == 4)
        calls = 0
        var iterated: [[Int]] = []
        for edge in graph.edges { iterated.append([edge.source, edge.target]) }
        #expect(iterated == [[0, 1], [0, 2], [1, 3], [2, 3]])
        #expect(calls == 4)
        calls = 0
        #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1, 2], [3], [3], [] as [Int]])
        #expect(calls == 4)
        #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1, 2], [3], [3], [] as [Int]])
        #expect(graph.vertices.map { graph.outDegree(of: $0) } == [2, 1, 1, 0])
        #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [2, 1, 1, 0])
        #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3]])
        calls = 0
        let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
        #expect(calls == 4)
        #expect(positions.map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [0, 1, 2], [1, 0, 3], [2, 0, 3]])
        #expect(graph.vertices.flatMap { Array(graph.outEdges(ofIndex: $0)) } == positions)
        calls = 0
        #expect(positions.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == positions.map { [$0.source, $0.target] })
        #expect(positions.map { graph.edges[$0] } == positions.map { DirectedEdge(from: $0.source, to: $0.target) })
        #expect(calls == 0)
        // Stepping by index(after:) visits the positions iteration lists, in order.
        var stepped: [ImplicitDirectedGraph<[Int]>.Edges.Index] = []
        var position = graph.edges.startIndex
        while position != graph.edges.endIndex {
            stepped.append(position)
            position = graph.edges.index(after: position)
        }
        #expect(stepped == positions && stepped.map(\.target) == positions.map(\.target))
        #expect(Set(positions).count == 4 && positions == positions.sorted())
        calls = 0
        #expect(positions.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })
        #expect(calls == 4)
    }

    @Test("IG-014 the closure returns a non-vertex: trap when it is read")
    func ig014() async {
        // IG (2, { _ in [0, 2] }) / successors(of: 0) → **trap** (successor 2 of 0 is not a vertex (0..<2))
        await #expect(processExitsWith: .failure) {
            var calls = 0
            let graph = ImplicitDirectedGraph(vertexCount: 2, successors: { (v: Int) -> [Int] in
                calls += 1
                return [0, 2]
            })
            _ = Array(graph.successors(of: 0))
            _ = calls
        }
        // Without the call: the setup, in this process.
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 2, successors: { (v: Int) -> [Int] in
            calls += 1
            return [0, 2]
        })
        // Without reading past the good successor, nothing traps: the check is lazy.
        #expect(graph.successors(of: 0).first(where: { _ in true }) == 0)
        #expect(calls == 1)
        #expect(graph.vertexCount == 2 && graph.contains(1) && !graph.contains(2))
    }

    @Test("IG-015 a negative successor, read by edgeCount")
    func ig015() async {
        // IG (2, { _ in [-1] }) / edgeCount → **trap** (successor -1 of 0 is not a vertex (0..<2))
        await #expect(processExitsWith: .failure) {
            var calls = 0
            let graph = ImplicitDirectedGraph(vertexCount: 2, successors: { (v: Int) -> [Int] in
                calls += 1
                return [-1]
            })
            _ = graph.edgeCount
            _ = calls
        }
        // Without the call: the setup, in this process.
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 2, successors: { (v: Int) -> [Int] in
            calls += 1
            return [-1]
        })
        // Without reading the row, nothing traps.
        _ = graph.successors(of: 0)
        #expect(calls == 1 && graph.vertexCount == 2)
    }

    @Test("Every vertex-taking read traps off 0..<n")
    func readsOfNonVertices() async {
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] }).outEdges(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] }).successorIndices(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] }).outEdges(ofIndex: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] }).vertexIndex(of: 3)
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] }).vertex(atIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 0, successors: { _ in [] as [Int] }).successors(of: 0)
        }
        // Without the faults: the same reads of vertices answer.
        let graph = ImplicitDirectedGraph(vertexCount: 3, successors: { [($0 + 1) % 3] })
        #expect(Array(graph.outEdges(of: 2)).map(\.target) == [0] && Array(graph.successorIndices(ofIndex: 0)) == [1])
        #expect(Array(graph.outEdges(ofIndex: 1)).map(\.target) == [2])
        #expect(graph.vertexIndex(of: 2) == 2 && graph.vertex(atIndex: 0) == 0)
    }

    @Test("A successor off 0..<n traps wherever it is read")
    func badSuccessorWhereverRead() async {
        await #expect(processExitsWith: .failure) {
            _ = Array(ImplicitDirectedGraph(vertexCount: 2, successors: { _ in [1, 2] }).outEdges(of: 0))
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 2, successors: { _ in [1, 2] }).outDegree(of: 1)
        }
        await #expect(processExitsWith: .failure) {
            for _ in ImplicitDirectedGraph(vertexCount: 2, successors: { $0 == 1 ? [5] : [] }).edges {}
        }
        await #expect(processExitsWith: .failure) {
            let graph = ImplicitDirectedGraph(vertexCount: 2, successors: { $0 == 1 ? [5] : [] })
            _ = graph.edges.startIndex
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 2, successors: { _ in [2, 1] }).contains(edge: DirectedEdge(from: 0, to: 1))
        }
        await #expect(processExitsWith: .failure) {
            _ = ImplicitDirectedGraph(vertexCount: 3, successors: { $0 == 2 ? [3] : [$0 + 1] }).breadthFirstLayers(from: 0)
        }
        // Without the faults: the good prefix of a row reads, and a row of vertices answers.
        let graph = ImplicitDirectedGraph(vertexCount: 2, successors: { _ in [1, 2] })
        #expect(graph.successors(of: 0).first(where: { _ in true }) == 1)
        #expect(ImplicitDirectedGraph(vertexCount: 2, successors: { _ in [1, 0] }).contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(ImplicitDirectedGraph(vertexCount: 3, successors: { $0 == 2 ? [] : [$0 + 1] }).breadthFirstLayers(from: 0) == [[0], [1], [2]])
    }
}
