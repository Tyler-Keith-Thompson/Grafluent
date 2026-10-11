// Generic algorithms on the implicit graph (catalog IG-016 – IG-022): Traversal's layers with one
// call per discovered vertex, ShortestPaths with the weight read from the position's target,
// Connectivity's components (as sets), topological order and findCycle.
// Generated from cases.md by swiftgen.py; see README.md.

import Connectivity
import GraphProtocols
import ImplicitGraphs
import ShortestPaths
import Testing
import Traversal

@Suite("ImplicitGraphs generic algorithms")
struct ImplicitGraphGenericTests {
    @Test("IG-016 breadthFirstLayers on the grid: one call per discovered vertex")
    func ig016() {
        // IG (12, grid) / breadthFirstLayers(from: 0) / calls() / breadthFirstLayers(from: 5) → [[0], [1, 4], [2, 8], [3, 9], [7, 10], [11]]; 10; [[5]]
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 12, successors: { (v: Int) -> LazyFilterSequence<[Int]> in
            calls += 1
            // 4 × 3 cells r * 4 + c, walls at 5 and 6; up, left, right, down.
            let walls: Set<Int> = [5, 6]
            let (r, c) = (v / 4, v % 4)
            let up = r > 0 ? v - 4 : -1, left = c > 0 ? v - 1 : -1, right = c < 3 ? v + 1 : -1, down = r < 2 ? v + 4 : -1
            return [up, left, right, down].lazy.filter { $0 >= 0 && !walls.contains($0) && !walls.contains(v) }
        })
        #expect(graph.breadthFirstLayers(from: 0) == [[0], [1, 4], [2, 8], [3, 9], [7, 10], [11]])
        #expect(calls == 10)
        calls = 0
        #expect(graph.breadthFirstLayers(from: 5) == [[5]])
        do {
            // The whole graph, from the model, with the closure calls each read makes.
            calls = 0
            #expect(graph.vertexCount == 12 && graph.vertexIndexBound == 12 && graph.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] && !graph.contains(-1) && !graph.contains(12))
            #expect(graph.edgeCount == 20)
            #expect(calls == 12)
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == [[0, 1], [0, 4], [1, 0], [1, 2], [2, 1], [2, 3], [3, 2], [3, 7], [4, 0], [4, 8], [7, 3], [7, 11], [8, 4], [8, 9], [9, 8], [9, 10], [10, 9], [10, 11], [11, 7], [11, 10]])
            #expect(calls == 12)
            calls = 0
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1, 4], [0, 2], [1, 3], [2, 7], [0, 8], [] as [Int], [] as [Int], [3, 11], [4, 9], [8, 10], [9, 11], [7, 10]])
            #expect(calls == 12)
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1, 4], [0, 2], [1, 3], [2, 7], [0, 8], [] as [Int], [] as [Int], [3, 11], [4, 9], [8, 10], [9, 11], [7, 10]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 0, 0, 2, 2, 2, 2, 2])
            #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [2, 2, 2, 2, 2, 0, 0, 2, 2, 2, 2, 2])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9], [10, 10], [11, 11]])
            calls = 0
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(calls == 12)
            #expect(positions.map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [0, 1, 4], [1, 0, 0], [1, 1, 2], [2, 0, 1], [2, 1, 3], [3, 0, 2], [3, 1, 7], [4, 0, 0], [4, 1, 8], [7, 0, 3], [7, 1, 11], [8, 0, 4], [8, 1, 9], [9, 0, 8], [9, 1, 10], [10, 0, 9], [10, 1, 11], [11, 0, 7], [11, 1, 10]])
            #expect(graph.vertices.flatMap { Array(graph.outEdges(ofIndex: $0)) } == positions)
            calls = 0
            #expect(positions.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == positions.map { [$0.source, $0.target] })
            #expect(positions.map { graph.edges[$0] } == positions.map { DirectedEdge(from: $0.source, to: $0.target) })
            #expect(calls == 0)
            // Stepping by index(after:) visits the positions iteration lists, in order.
            var stepped: [ImplicitDirectedGraph<LazyFilterSequence<[Int]>>.Edges.Index] = []
            var position = graph.edges.startIndex
            while position != graph.edges.endIndex {
                stepped.append(position)
                position = graph.edges.index(after: position)
            }
            #expect(stepped == positions && stepped.map(\.target) == positions.map(\.target))
            #expect(Set(positions).count == 20 && positions == positions.sorted())
            calls = 0
            #expect(positions.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })
            #expect(calls == 20)
        }
    }

    @Test("IG-017 shortestPaths(from:) distances")
    func ig017() {
        // IG (12, grid) / shortestPaths(from: 0).distance(to:) for 0..<12 → [0, 1, 2, 3, 1, nil, nil, 4, 2, 3, 4, 5]
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 12, successors: { (v: Int) -> LazyFilterSequence<[Int]> in
            calls += 1
            // 4 × 3 cells r * 4 + c, walls at 5 and 6; up, left, right, down.
            let walls: Set<Int> = [5, 6]
            let (r, c) = (v / 4, v % 4)
            let up = r > 0 ? v - 4 : -1, left = c > 0 ? v - 1 : -1, right = c < 3 ? v + 1 : -1, down = r < 2 ? v + 4 : -1
            return [up, left, right, down].lazy.filter { $0 >= 0 && !walls.contains($0) && !walls.contains(v) }
        })
        let hops = graph.shortestPaths(from: 0)
        #expect((0 ..< 12).map { hops.distance(to: $0) } == [0, 1, 2, 3, 1, nil, nil, 4, 2, 3, 4, 5] as [Int?])
        do {
            // The whole graph, from the model, with the closure calls each read makes.
            calls = 0
            #expect(graph.vertexCount == 12 && graph.vertexIndexBound == 12 && graph.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] && !graph.contains(-1) && !graph.contains(12))
            #expect(graph.edgeCount == 20)
            #expect(calls == 12)
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == [[0, 1], [0, 4], [1, 0], [1, 2], [2, 1], [2, 3], [3, 2], [3, 7], [4, 0], [4, 8], [7, 3], [7, 11], [8, 4], [8, 9], [9, 8], [9, 10], [10, 9], [10, 11], [11, 7], [11, 10]])
            #expect(calls == 12)
            calls = 0
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1, 4], [0, 2], [1, 3], [2, 7], [0, 8], [] as [Int], [] as [Int], [3, 11], [4, 9], [8, 10], [9, 11], [7, 10]])
            #expect(calls == 12)
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1, 4], [0, 2], [1, 3], [2, 7], [0, 8], [] as [Int], [] as [Int], [3, 11], [4, 9], [8, 10], [9, 11], [7, 10]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 0, 0, 2, 2, 2, 2, 2])
            #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [2, 2, 2, 2, 2, 0, 0, 2, 2, 2, 2, 2])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9], [10, 10], [11, 11]])
            calls = 0
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(calls == 12)
            #expect(positions.map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [0, 1, 4], [1, 0, 0], [1, 1, 2], [2, 0, 1], [2, 1, 3], [3, 0, 2], [3, 1, 7], [4, 0, 0], [4, 1, 8], [7, 0, 3], [7, 1, 11], [8, 0, 4], [8, 1, 9], [9, 0, 8], [9, 1, 10], [10, 0, 9], [10, 1, 11], [11, 0, 7], [11, 1, 10]])
            #expect(graph.vertices.flatMap { Array(graph.outEdges(ofIndex: $0)) } == positions)
            calls = 0
            #expect(positions.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == positions.map { [$0.source, $0.target] })
            #expect(positions.map { graph.edges[$0] } == positions.map { DirectedEdge(from: $0.source, to: $0.target) })
            #expect(calls == 0)
            // Stepping by index(after:) visits the positions iteration lists, in order.
            var stepped: [ImplicitDirectedGraph<LazyFilterSequence<[Int]>>.Edges.Index] = []
            var position = graph.edges.startIndex
            while position != graph.edges.endIndex {
                stepped.append(position)
                position = graph.edges.index(after: position)
            }
            #expect(stepped == positions && stepped.map(\.target) == positions.map(\.target))
            #expect(Set(positions).count == 20 && positions == positions.sorted())
            calls = 0
            #expect(positions.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })
            #expect(calls == 20)
        }
    }

    @Test("IG-018 dijkstraShortestPaths with weight from the position: entering a cell in row r costs r + 1")
    func ig018() {
        // IG (12, grid) / dijkstraShortestPaths(from: 0, weight: { $0.target / 4 + 1 }).distance(to:) for 0..<12 → [0, 1, 2, 3, 2, nil, nil, 5, 5, 8, 11, 8]
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 12, successors: { (v: Int) -> LazyFilterSequence<[Int]> in
            calls += 1
            // 4 × 3 cells r * 4 + c, walls at 5 and 6; up, left, right, down.
            let walls: Set<Int> = [5, 6]
            let (r, c) = (v / 4, v % 4)
            let up = r > 0 ? v - 4 : -1, left = c > 0 ? v - 1 : -1, right = c < 3 ? v + 1 : -1, down = r < 2 ? v + 4 : -1
            return [up, left, right, down].lazy.filter { $0 >= 0 && !walls.contains($0) && !walls.contains(v) }
        })
        let tree = graph.dijkstraShortestPaths(from: 0, weight: { $0.target / 4 + 1 })
        #expect((0 ..< 12).map { tree.distance(to: $0) } == [0, 1, 2, 3, 2, nil, nil, 5, 5, 8, 11, 8] as [Int?])
        // The paths cost what they say: each step into row r costs r + 1.
        for v in 0 ..< 12 {
            if let path = tree.path(to: v) {
                #expect(path.vertices.first == 0 && path.vertices.last == v)
                #expect(path.vertices.dropFirst().reduce(0) { $0 + $1 / 4 + 1 } == tree.distance(to: v))
                #expect(path.edges.map { [$0.source, $0.target] } == zip(path.vertices, path.vertices.dropFirst()).map { [$0, $1] })
            }
        }
        do {
            // The whole graph, from the model, with the closure calls each read makes.
            calls = 0
            #expect(graph.vertexCount == 12 && graph.vertexIndexBound == 12 && graph.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] && !graph.contains(-1) && !graph.contains(12))
            #expect(graph.edgeCount == 20)
            #expect(calls == 12)
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == [[0, 1], [0, 4], [1, 0], [1, 2], [2, 1], [2, 3], [3, 2], [3, 7], [4, 0], [4, 8], [7, 3], [7, 11], [8, 4], [8, 9], [9, 8], [9, 10], [10, 9], [10, 11], [11, 7], [11, 10]])
            #expect(calls == 12)
            calls = 0
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1, 4], [0, 2], [1, 3], [2, 7], [0, 8], [] as [Int], [] as [Int], [3, 11], [4, 9], [8, 10], [9, 11], [7, 10]])
            #expect(calls == 12)
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1, 4], [0, 2], [1, 3], [2, 7], [0, 8], [] as [Int], [] as [Int], [3, 11], [4, 9], [8, 10], [9, 11], [7, 10]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [2, 2, 2, 2, 2, 0, 0, 2, 2, 2, 2, 2])
            #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [2, 2, 2, 2, 2, 0, 0, 2, 2, 2, 2, 2])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9], [10, 10], [11, 11]])
            calls = 0
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(calls == 12)
            #expect(positions.map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [0, 1, 4], [1, 0, 0], [1, 1, 2], [2, 0, 1], [2, 1, 3], [3, 0, 2], [3, 1, 7], [4, 0, 0], [4, 1, 8], [7, 0, 3], [7, 1, 11], [8, 0, 4], [8, 1, 9], [9, 0, 8], [9, 1, 10], [10, 0, 9], [10, 1, 11], [11, 0, 7], [11, 1, 10]])
            #expect(graph.vertices.flatMap { Array(graph.outEdges(ofIndex: $0)) } == positions)
            calls = 0
            #expect(positions.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == positions.map { [$0.source, $0.target] })
            #expect(positions.map { graph.edges[$0] } == positions.map { DirectedEdge(from: $0.source, to: $0.target) })
            #expect(calls == 0)
            // Stepping by index(after:) visits the positions iteration lists, in order.
            var stepped: [ImplicitDirectedGraph<LazyFilterSequence<[Int]>>.Edges.Index] = []
            var position = graph.edges.startIndex
            while position != graph.edges.endIndex {
                stepped.append(position)
                position = graph.edges.index(after: position)
            }
            #expect(stepped == positions && stepped.map(\.target) == positions.map(\.target))
            #expect(Set(positions).count == 20 && positions == positions.sorted())
            calls = 0
            #expect(positions.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })
            #expect(calls == 20)
        }
    }

    @Test("IG-019 weaklyConnectedComponents as sets")
    func ig019() {
        // IG (5, twoCycles) / weaklyConnectedComponents() → [[0, 1, 2, 3], [4]]
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 5, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1], [0, 2], [3], [2], []][v]
        })
        #expect(Set(graph.weaklyConnectedComponents().map { Set($0) }) == Set([[0, 1, 2, 3], [4]].map { Set($0) }))
        do {
            // The whole graph, from the model, with the closure calls each read makes.
            calls = 0
            #expect(graph.vertexCount == 5 && graph.vertexIndexBound == 5 && graph.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == [0, 1, 2, 3, 4] && !graph.contains(-1) && !graph.contains(5))
            #expect(graph.edgeCount == 5)
            #expect(calls == 5)
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == [[0, 1], [1, 0], [1, 2], [2, 3], [3, 2]])
            #expect(calls == 5)
            calls = 0
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1], [0, 2], [3], [2], [] as [Int]])
            #expect(calls == 5)
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1], [0, 2], [3], [2], [] as [Int]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 2, 1, 1, 0])
            #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [1, 2, 1, 1, 0])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4]])
            calls = 0
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(calls == 5)
            #expect(positions.map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [1, 0, 0], [1, 1, 2], [2, 0, 3], [3, 0, 2]])
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
            #expect(Set(positions).count == 5 && positions == positions.sorted())
            calls = 0
            #expect(positions.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })
            #expect(calls == 5)
        }
    }

    @Test("IG-020 stronglyConnectedComponents as sets")
    func ig020() {
        // IG (5, twoCycles) / stronglyConnectedComponents() → [[0, 1], [2, 3], [4]]
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 5, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1], [0, 2], [3], [2], []][v]
        })
        #expect(Set(graph.stronglyConnectedComponents().map { Set($0) }) == Set([[0, 1], [2, 3], [4]].map { Set($0) }))
        do {
            // The whole graph, from the model, with the closure calls each read makes.
            calls = 0
            #expect(graph.vertexCount == 5 && graph.vertexIndexBound == 5 && graph.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == [0, 1, 2, 3, 4] && !graph.contains(-1) && !graph.contains(5))
            #expect(graph.edgeCount == 5)
            #expect(calls == 5)
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == [[0, 1], [1, 0], [1, 2], [2, 3], [3, 2]])
            #expect(calls == 5)
            calls = 0
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1], [0, 2], [3], [2], [] as [Int]])
            #expect(calls == 5)
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1], [0, 2], [3], [2], [] as [Int]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 2, 1, 1, 0])
            #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [1, 2, 1, 1, 0])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4]])
            calls = 0
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(calls == 5)
            #expect(positions.map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [1, 0, 0], [1, 1, 2], [2, 0, 3], [3, 0, 2]])
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
            #expect(Set(positions).count == 5 && positions == positions.sorted())
            calls = 0
            #expect(positions.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })
            #expect(calls == 5)
        }
    }

    @Test("IG-021 topologicalSort is a valid order on a DAG and nil on a cycle")
    func ig021() {
        // IG (4, diamond) / topologicalSort() is a topological order / IG(5, twoCycles).topologicalSort() → true; nil
        var calls = 0
        var otherCalls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [[1, 2], [3], [3], []][v]
        })
        let order = graph.topologicalSort()!
        #expect(order.sorted() == Array(graph.vertices))
        let place = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        #expect(graph.edges.allSatisfy { place[$0.source]! < place[$0.target]! })
        let cyclic = ImplicitDirectedGraph(vertexCount: 5, successors: { (v: Int) -> [Int] in
            otherCalls += 1
            return [[1], [0, 2], [3], [2], []][v]
        })
        #expect(cyclic.topologicalSort() == nil)
        #expect(otherCalls > 0)
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

    @Test("IG-022 a ring is one strongly connected component")
    func ig022() {
        // IG (5, ring5) / stronglyConnectedComponents() / findCycle()!.count → [[0, 1, 2, 3, 4]]; 5
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 5, successors: { (v: Int) -> [Int] in
            calls += 1
            return [(v + 1) % 5]
        })
        #expect(Set(graph.stronglyConnectedComponents().map { Set($0) }) == Set([[0, 1, 2, 3, 4]].map { Set($0) }))
        let cycle = graph.findCycle()!
        #expect(cycle.count == 5)
        #expect(zip(cycle.vertices, cycle.vertices.dropFirst() + cycle.vertices.prefix(1)).allSatisfy { graph.contains(edge: DirectedEdge(from: $0, to: $1)) })
        do {
            // The whole graph, from the model, with the closure calls each read makes.
            calls = 0
            #expect(graph.vertexCount == 5 && graph.vertexIndexBound == 5 && graph.edgeIndexBound == nil)
            #expect(Array(graph.vertices) == [0, 1, 2, 3, 4] && !graph.contains(-1) && !graph.contains(5))
            #expect(graph.edgeCount == 5)
            #expect(calls == 5)
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0]])
            #expect(calls == 5)
            calls = 0
            #expect(graph.vertices.map { Array(graph.successors(of: $0)) } == [[1], [2], [3], [4], [0]])
            #expect(calls == 5)
            #expect(graph.vertices.map { Array(graph.successorIndices(ofIndex: $0)) } == [[1], [2], [3], [4], [0]])
            #expect(graph.vertices.map { graph.outDegree(of: $0) } == [1, 1, 1, 1, 1])
            #expect(graph.vertices.map { graph.outDegree(ofIndex: $0) } == [1, 1, 1, 1, 1])
            #expect(graph.vertices.map { [graph.vertexIndex(of: $0), graph.vertex(atIndex: $0)] } == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4]])
            calls = 0
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(calls == 5)
            #expect(positions.map { [$0.source, $0.rank, $0.target] } == [[0, 0, 1], [1, 0, 2], [2, 0, 3], [3, 0, 4], [4, 0, 0]])
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
            #expect(Set(positions).count == 5 && positions == positions.sorted())
            calls = 0
            #expect(positions.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })
            #expect(calls == 5)
        }
    }
}
