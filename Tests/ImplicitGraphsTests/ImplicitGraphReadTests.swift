// Reads (catalog IG-004 – IG-011, IG-045, IG-046): one closure call per row read, positions
// (source, rank, target) that read their ends without a call, edges in row order with one call per
// vertex, index(after:) re-reading the row, parallel edges and self-loops as distinct positions,
// contains, isEmpty and first reading every empty row, and the checked: spellings, which throw
// VertexNotFound for a non-vertex without calling the closure.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import ImplicitGraphs
import Testing

@Suite("ImplicitGraphs reads")
struct ImplicitGraphReadTests {
    @Test("IG-004 successors(of:) calls the closure once and returns its sequence")
    func ig004() {
        // IG (4, diamond) / successors(of: 0) / calls() / successors(of: 3) / calls() → [1, 2]; 1; []; 1
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        #expect(Array(graph.successors(of: 0)) == [1, 2])
        #expect(calls == 1)
        calls = 0
        #expect(Array(graph.successors(of: 3)) == [] as [Int])
        #expect(calls == 1)
        calls = 0
        do {
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
    }

    @Test("IG-005 outEdges(of:) positions carry (source, rank, target); one call")
    func ig005() {
        // IG (4, diamond) / outEdges(of: 0) / calls() / outDegree(of: 0) / calls() → [0.0→1, 0.1→2]; 1; 2; 1
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        #expect(Array(graph.outEdges(of: 0)).map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [0, 1, 2]])
        #expect(calls == 1)
        calls = 0
        #expect(graph.outDegree(of: 0) == 2)
        #expect(calls == 1)
        calls = 0
        do {
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
    }

    @Test("IG-006 source/target(ofEdgeAt:) read the position, no call")
    func ig006() {
        // IG (4, diamond) / let p = outEdges(of: 0)[1] / calls() / source(ofEdgeAt: p) / target(ofEdgeAt: p) / calls() → 0.1→2; 1; 0; 2; 0
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        let p = Array(graph.outEdges(of: 0))[1]
        #expect([p.source, p.rank, p.target] == [0, 1, 2])
        #expect(calls == 1)
        calls = 0
        #expect(graph.source(ofEdgeAt: p) == 0)
        #expect(graph.target(ofEdgeAt: p) == 2)
        #expect(calls == 0)
        calls = 0
        do {
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
    }

    @Test("IG-007 edges in row order; one call per vertex; edgeCount the same")
    func ig007() {
        // IG (4, diamond) / Array(edges) / calls() / edgeCount / calls() → [0.0→1, 0.1→2, 1.0→3, 2.0→3]; 4; 4; 4
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        #expect(Array(graph.edges).map { [$0.source, $0.target] } == [[0, 1], [0, 2], [1, 3], [2, 3]])
        #expect(calls == 4)
        calls = 0
        #expect(graph.edgeCount == 4)
        #expect(calls == 4)
        calls = 0
        do {
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
    }

    @Test("IG-008 edges.index(after:) re-reads the row: O(d) per step")
    func ig008() {
        // IG (4, diamond) / edges.index(after: 0.0→1) / calls() / edges.index(after: 0.1→2) / calls() / edges.index(after: 2.0→3) / calls() → 0.1→2; 1; 1.0→3; 2; endIndex; 2
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        // The positions the calls take, read from outEdges(of:) before counting.
        let p00 = Array(graph.outEdges(of: 0))[0]
        #expect([p00.source, p00.rank, p00.target] == [0, 0, 1])
        let p01 = Array(graph.outEdges(of: 0))[1]
        #expect([p01.source, p01.rank, p01.target] == [0, 1, 2])
        let p20 = Array(graph.outEdges(of: 2))[0]
        #expect([p20.source, p20.rank, p20.target] == [2, 0, 3])
        calls = 0
        let after00 = graph.edges.index(after: p00)
        #expect([after00.source, after00.rank, after00.target] == [0, 1, 2])
        #expect(calls == 1)
        calls = 0
        let after01 = graph.edges.index(after: p01)
        #expect([after01.source, after01.rank, after01.target] == [1, 0, 3])
        #expect(calls == 2)
        calls = 0
        #expect(graph.edges.index(after: p20) == graph.edges.endIndex)
        #expect(calls == 2)
        calls = 0
        do {
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
    }

    @Test("IG-009 parallel edges and a self-loop are distinct positions")
    func ig009() {
        // IG (2, parallel) / outEdges(of: 0) / outDegree(of: 0) / contains(edge: 0→1) / contains(edge: 0→0) / contains(edge: 1→0) → [0.0→1, 0.1→1, 0.2→0]; 3; true; true; false
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 2, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 1, 0], []][v]
        })
        #expect(Array(graph.outEdges(of: 0)).map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [0, 1, 1], [0, 2, 0]])
        #expect(graph.outDegree(of: 0) == 3)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 0)))
        #expect(!graph.contains(edge: DirectedEdge(from: 1, to: 0)))
        do {
            // The whole graph, from the model, with the closure calls each read makes.
            calls = 0
            #expect(graph.vertexCount == 2 && graph.vertexIndexBound == 2 && graph.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == [0, 1] && !graph.contains(-1) && !graph.contains(2))
            #expect(graph.edgeCount == 3)
            #expect(calls == 2)
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == [[0, 1], [0, 1], [0, 0]])
            #expect(calls == 2)
            calls = 0
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1, 1, 0], [] as [Int]])
            #expect(calls == 2)
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1, 1, 0], [] as [Int]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [3, 0])
            #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [3, 0])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1]])
            calls = 0
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(calls == 2)
            #expect(positions.map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [0, 1, 1], [0, 2, 0]])
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
            #expect(Set(positions).count == 3 && positions == positions.sorted())
            calls = 0
            #expect(positions.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })
            #expect(calls == 3)
        }
    }

    @Test("IG-010 contains: no call for vertices, one row scan for an edge")
    func ig010() {
        // IG (4, diamond) / contains(3) / contains(4) / contains(-1) / calls() / contains(edge: 1→3) / contains(edge: 9→3) / calls() → true; false; false; 0; true; false; 1
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        #expect(graph.contains(3))
        #expect(!graph.contains(4))
        #expect(!graph.contains(-1))
        #expect(calls == 0)
        calls = 0
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 3)))
        #expect(!graph.contains(edge: DirectedEdge(from: 9, to: 3)))
        #expect(calls == 1)
        calls = 0
        do {
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
    }

    @Test("IG-011 index members are the identity")
    func ig011() {
        // IG (4, diamond) / vertexIndex(of: 2) / vertex(atIndex: 3) / successorIndices(ofIndex: 0) → 2; 3; [1, 2]
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        #expect(graph.vertexIndex(of: 2) == 2)
        #expect(graph.vertex(atIndex: 3) == 3)
        #expect(Array(graph.successorIndices(ofIndex: 0)) == [1, 2])
        do {
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
    }

    @Test("IG-045 edges.isEmpty and edges.first read startIndex: a call per row up to the first non-empty one, so n calls when there are no edges")
    func ig045() {
        // IG (5, { _ in [] }) / edges.isEmpty / calls() / edges.first / calls() → true; 5; nil; 5
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 5, successors: { (v: Int) -> [Int] in
            calls += 1
            return []
        })
        #expect(graph.edges.isEmpty == true)
        #expect(calls == 5)
        calls = 0
        #expect(graph.edges.first == nil)
        #expect(calls == 5)
        calls = 0
        do {
            // The whole graph, from the model, with the closure calls each read makes.
            calls = 0
            #expect(graph.vertexCount == 5 && graph.vertexIndexBound == 5 && graph.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == [0, 1, 2, 3, 4] && !graph.contains(-1) && !graph.contains(5))
            #expect(graph.edgeCount == 0)
            #expect(calls == 5)
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == [] as [[Int]])
            #expect(calls == 5)
            calls = 0
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[] as [Int], [] as [Int], [] as [Int], [] as [Int], [] as [Int]])
            #expect(calls == 5)
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[] as [Int], [] as [Int], [] as [Int], [] as [Int], [] as [Int]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [0, 0, 0, 0, 0])
            #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [0, 0, 0, 0, 0])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4]])
            calls = 0
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(calls == 5)
            #expect(positions.map { [$0.source, $0.rank, $0.target] } == [] as [[Int]])
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
            #expect(Set(positions).count == 0 && positions == positions.sorted())
        }
    }

    @Test("IG-046 checked: spellings answer a vertex as the plain ones do, one call each; a non-vertex throws without a call")
    func ig046() throws {
        // IG (4, diamond) / successors(checked: 0) / calls() / outEdges(checked: 0) / outDegree(checked: 3) / vertexIndex(checked: 2) / calls() / successors(checked: 4) / outEdges(checked: -1) / outDegree(checked: 4) / vertexIndex(checked: -1) / vertexIndex(checked: 4) / calls() → [1, 2]; 1; [0.0→1, 0.1→2]; 0; 2; 2; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; 0
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        #expect(try Array(graph.successors(checked: 0)) == [1, 2])
        #expect(calls == 1)
        calls = 0
        #expect(try Array(graph.outEdges(checked: 0)).map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [0, 1, 2]])
        #expect(try graph.outDegree(checked: 3) == 0)
        #expect(try graph.vertexIndex(checked: 2) == 2)
        #expect(calls == 2)
        calls = 0
        #expect(throws: VertexNotFound.self) { try graph.successors(checked: 4) }
        #expect((try? graph.successors(checked: 4)) == nil)
        #expect(throws: VertexNotFound.self) { try graph.outEdges(checked: -1) }
        #expect((try? graph.outEdges(checked: -1)) == nil)
        #expect(throws: VertexNotFound.self) { try graph.outDegree(checked: 4) }
        #expect((try? graph.outDegree(checked: 4)) == nil)
        #expect(throws: VertexNotFound.self) { try graph.vertexIndex(checked: -1) }
        #expect((try? graph.vertexIndex(checked: -1)) == nil)
        #expect(throws: VertexNotFound.self) { try graph.vertexIndex(checked: 4) }
        #expect((try? graph.vertexIndex(checked: 4)) == nil)
        #expect(calls == 0)
        calls = 0
        do {
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
    }
}
