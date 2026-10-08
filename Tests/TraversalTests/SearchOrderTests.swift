// Breadth-first layers, depth-first preorder and postorder, depth limits, pruning and early exit.
// Undirected NetworkX graphs are written as both directions. Case IDs (TR-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

@Suite("Breadth-first layers and trees")
struct BreadthFirstLayerTests {
    @Test("TR-19 layers of a tree")
    func treeLayers() {
        // NetworkX test_bfs.py: path 0…6 plus 2–7–8–9–10, undirected.
        var edges: [DirectedEdge<Int>] = []
        for (a, b) in [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (2, 7), (7, 8), (8, 9), (9, 10)] {
            edges += [DirectedEdge(from: a, to: b), DirectedEdge(from: b, to: a)]
        }
        let expected = [[0], [1], [2], [3, 7], [4, 8], [5, 9], [6, 10]]
        #expect(AdjacencyMatrix(vertexCount: 11, edges: edges).breadthFirstLayers(from: 0) == expected)
        #expect(CompressedSparseRow(vertexCount: 11, edges: edges).breadthFirstLayers(from: 0) == expected)
        #expect(AdjacencyList(edges: edges).breadthFirstLayers(from: 0).map(Set.init) == expected.map(Set.init))
    }

    @Test("TR-20 layers of NetworkX's TestBFS graph, from one source, a list, and a repeated source")
    func testBFSLayers() {
        var edges: [DirectedEdge<Int>] = []
        for (a, b) in [(0, 1), (1, 2), (1, 3), (2, 4), (3, 4)] {
            edges += [DirectedEdge(from: a, to: b), DirectedEdge(from: b, to: a)]
        }
        let graph = CompressedSparseRow(vertexCount: 5, edges: edges)
        #expect(graph.breadthFirstLayers(from: 0) == [[0], [1], [2, 3], [4]])
        #expect(graph.breadthFirstLayers(from: [0]) == [[0], [1], [2, 3], [4]])
        #expect(graph.breadthFirstLayers(from: [0, 0]) == [[0], [1], [2, 3], [4]])
        // TR-14: a repeated source is ignored by the search, too.
        #expect(Array(graph.breadthFirstSearch(from: [0, 0])) == Array(graph.breadthFirstSearch(from: 0)))
    }

    @Test("TR-15 no sources: no events and no layers")
    func noSources() {
        let graph = AdjacencyList(edges: DirectedFixture<Int>.house.edges)
        #expect(Array(graph.breadthFirstSearch(from: [Int]())).isEmpty)
        #expect(Array(graph.depthFirstSearch(from: [Int]())).isEmpty)
        #expect(graph.breadthFirstLayers(from: [Int]()) == [])
    }

    @Test("TR-21 layers of a disconnected graph")
    func disconnectedLayers() {
        var edges: [DirectedEdge<Int>] = []
        for (a, b) in [(0, 1), (2, 3), (2, 7), (7, 8), (8, 9), (9, 10)] {
            edges += [DirectedEdge(from: a, to: b), DirectedEdge(from: b, to: a)]
        }
        #expect(AdjacencyMatrix(vertexCount: 11, edges: edges).breadthFirstLayers(from: 2) == [[2], [3, 7], [8], [9], [10]])
    }

    @Test("TR-22 a layer is NetworkX's descendants_at_distance")
    func descendantsAtDistance() {
        var path: [DirectedEdge<Int>] = []
        for i in 0 ..< 4 { path += [DirectedEdge(from: i, to: i + 1), DirectedEdge(from: i + 1, to: i)] }
        #expect(Set(AdjacencyList(edges: path).breadthFirstLayers(from: 2)[2]) == [0, 4])
        let binary = (0 ..< 3).flatMap { [DirectedEdge(from: $0, to: 2 * $0 + 1), DirectedEdge(from: $0, to: 2 * $0 + 2)] }
        #expect(Set(AdjacencyList(edges: binary).breadthFirstLayers(from: 0)[2]) == [3, 4, 5, 6])
    }

    @Test("TR-23 / TR-24 layers of the fixtures, the same on every representation")
    func fixtureLayers() {
        let boost = DirectedFixture<Int>.boost24
        let expected = [[7], [11, 17], [4, 15, 19, 20], [0, 5, 6, 22, 18, 23, 13], [14, 3, 21, 9, 16, 8], [12, 10, 1], [2]]
        #expect(AdjacencyMatrix(vertexCount: 24, edges: boost.edges).breadthFirstLayers(from: 7) == expected)
        #expect(CompressedSparseRow(vertexCount: 24, edges: boost.edges).breadthFirstLayers(from: 7) == expected)
        #expect(AdjacencyList(edges: boost.edges).breadthFirstLayers(from: 7).map(Set.init) == expected.map(Set.init))
        let house = DirectedFixture<Int>.house
        #expect(AdjacencyList(edges: house.edges).breadthFirstLayers(from: 5).map(Set.init) == [[5], [3], [2, 4], [0, 1]])
        let scc9 = DirectedFixture<Int>.scc9
        #expect(AdjacencyList(edges: scc9.edges).breadthFirstLayers(from: 1).map(Set.init) == [[1], [7], [4, 5], [8], [2, 6], [0], [3]])
    }

    @Test("TR-25 – TR-27 the breadth-first tree, read from the tree edges")
    func parents() {
        func parents<G: DirectedGraph>(_ g: G, from source: G.Vertex) -> [G.Vertex: G.Vertex] {
            var parent: [G.Vertex: G.Vertex] = [:]
            for case .treeEdge(let edge) in g.breadthFirstSearch(from: source) { parent[edge.target] = edge.source }
            return parent
        }
        let house = DirectedFixture<Int>.house
        #expect(parents(AdjacencyMatrix(vertexCount: 6, edges: house.edges), from: 5) == [3: 5, 2: 3, 4: 3, 1: 2, 0: 4])
        let edgesDirected = DirectedFixture<Int>.petgraphEdgesDirected
        #expect(parents(CompressedSparseRow(vertexCount: 7, edges: edgesDirected.edges), from: 0) == [1: 0, 2: 0, 3: 0, 5: 0, 4: 2])
        // JGraphT BreadthFirstIteratorTest: an undirected tree, so the parents are unique.
        var tree: [DirectedEdge<String>] = []
        for (a, b) in [("a", "b"), ("b", "c"), ("b", "z"), ("b", "d"), ("d", "e")] {
            tree += [DirectedEdge(from: a, to: b), DirectedEdge(from: b, to: a)]
        }
        let jgrapht = AdjacencyList(edges: tree)
        #expect(parents(jgrapht, from: "a") == ["b": "a", "c": "b", "d": "b", "z": "b", "e": "d"])
        #expect(jgrapht.breadthFirstLayers(from: "a").map(Set.init) == [["a"], ["b"], ["c", "d", "z"], ["e"]])
        let cycle = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0)])
        #expect(parents(cycle, from: 0) == [1: 0, 2: 1, 3: 2])
    }

    @Test("TR-28 igraph's binary out-tree")
    func binaryTree() {
        let edges = (0 ..< 20).flatMap { i in [2 * i + 1, 2 * i + 2].filter { $0 < 20 }.map { DirectedEdge(from: i, to: $0) } }
        let graph = CompressedSparseRow(vertexCount: 20, edges: edges)
        #expect(graph.breadthFirstLayers(from: 0).map(\.count) == [1, 2, 4, 8, 5])
        #expect(graph.breadthFirstLayers(from: 0).joined().elementsEqual(0 ..< 20))
        #expect(graph.breadthFirstLayers(from: 7) == [[7], [15, 16]])
    }

    @Test("TR-29 layers are the discover events grouped by depth", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func layersMatchEvents(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        for source in graph.vertices {
            var depth = [source: 0]
            var discovered: [Int] = []
            for event in graph.breadthFirstSearch(from: source) {
                switch event {
                case .discover(let v): discovered.append(v)
                case .treeEdge(let edge): depth[edge.target] = depth[edge.source]! + 1
                default: break
                }
            }
            let layers = graph.breadthFirstLayers(from: source)
            #expect(Array(layers.joined()) == discovered)
            for (k, layer) in layers.enumerated() {
                for v in layer { #expect(depth[v] == k) }
            }
        }
    }

    @Test("TR-30 hasPath")
    func hasPath() {
        let house = AdjacencyList(edges: DirectedFixture<Int>.house.edges)
        #expect(!house.hasPath(from: 0, to: 5))
        #expect(house.hasPath(from: 5, to: 0))
        #expect(house.hasPath(from: 0, to: 0))
        let scipy = AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.scipyConstructor2.edges)
        #expect(!scipy.hasPath(from: 0, to: 4))
        #expect(scipy.hasPath(from: 3, to: 4))
    }
}

@Suite("Depth-first preorder and postorder")
struct DepthFirstOrderTests {
    @Test("TR-52 / TR-53 preorder and postorder of NetworkX's TestDFS graphs")
    func networkXOrders() {
        var g: [DirectedEdge<Int>] = []
        for (a, b) in [(0, 1), (1, 2), (1, 3), (2, 4), (3, 0), (0, 4)] {
            g += [DirectedEdge(from: a, to: b), DirectedEdge(from: b, to: a)]
        }
        let graph = CompressedSparseRow(vertexCount: 5, edges: g)
        #expect(Array(graph.depthFirstSearch(from: 0).preorder) == [0, 1, 2, 4, 3])
        #expect(Array(graph.depthFirstSearch(from: 0).postorder) == [4, 2, 3, 1, 0])
        #expect(Array(graph.depthFirstSearch(from: 1).preorder) == [1, 0, 3, 4, 2])
        var d: [DirectedEdge<Int>] = []
        for (a, b) in [(0, 1), (2, 3)] { d += [DirectedEdge(from: a, to: b), DirectedEdge(from: b, to: a)] }
        let disconnected = AdjacencyMatrix(vertexCount: 4, edges: d)
        #expect(Array(disconnected.depthFirstSearch().preorder) == [0, 1, 2, 3])
        #expect(Array(disconnected.depthFirstSearch().postorder) == [1, 0, 3, 2])
        #expect(Array(disconnected.depthFirstSearch(from: 2).preorder) == [2, 3])
        #expect(Array(disconnected.depthFirstSearch(from: 0).postorder) == [1, 0])
    }

    @Test("TR-54 / TR-55 tree edges match NetworkX's dfs_edges, in ascending and descending successor order")
    func treeEdges() {
        func treeEdges<G: DirectedGraph>(_ search: DepthFirstSearch<G>) -> [DirectedEdge<G.Vertex>] {
            search.compactMap { if case .treeEdge(let edge) = $0 { edge } else { nil } }
        }
        var g: [DirectedEdge<Int>] = []
        for (a, b) in [(0, 1), (1, 2), (1, 3), (2, 4), (3, 0), (0, 4)] {
            g += [DirectedEdge(from: a, to: b), DirectedEdge(from: b, to: a)]
        }
        let ascending = AdjacencyMatrix(vertexCount: 5, edges: g)
        #expect(treeEdges(ascending.depthFirstSearch(from: 0)) == [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 1, to: 3),
        ])
        let descending = ReferenceDirectedMultigraph(edges: g.sorted { ($0.source, $1.target) < ($1.source, $0.target) })
        #expect(treeEdges(descending.depthFirstSearch(from: 0)) == [
            DirectedEdge(from: 0, to: 4), DirectedEdge(from: 4, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3),
        ])
        // NetworkX dfs_successors from 1.
        var successors: [Int: [Int]] = [:]
        for edge in treeEdges(ascending.depthFirstSearch(from: 1)) { successors[edge.source, default: []].append(edge.target) }
        #expect(successors == [1: [0], 0: [3, 4], 4: [2]])
    }

    @Test("TR-60 JGraphT's iterator graph, successors ascending")
    func jgraphtIterator() {
        let pairs = [("1", "2"), ("1", "3"), ("2", "4"), ("3", "5"), ("3", "6"), ("5", "6"), ("5", "7"), ("6", "1"), ("7", "8"), ("7", "9"), ("8", "2"), ("9", "4")]
        let graph = ReferenceDirectedMultigraph(vertices: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "orphan"], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.depthFirstSearch().preorder) == ["1", "2", "4", "3", "5", "6", "7", "8", "9", "orphan"])
        #expect(Array(graph.depthFirstSearch().postorder) == ["4", "2", "6", "8", "9", "7", "5", "3", "1", "orphan"])
        // JGraphT visits successors in reverse insertion order: written that way, its preorder appears.
        let reversed = ReferenceDirectedMultigraph(vertices: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "orphan"], edges: pairs.reversed().map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(reversed.depthFirstSearch().preorder) == ["1", "3", "6", "5", "7", "9", "4", "8", "2", "orphan"])
    }

    @Test("TR-61 JGraphT's bug 1169182 graph")
    func jgraphtBug() {
        let pairs = [("A", "B"), ("B", "C"), ("C", "D"), ("C", "E"), ("C", "F"), ("C", "G"), ("C", "J"), ("D", "H"), ("E", "H"), ("F", "I"), ("G", "I"), ("H", "J"), ("I", "C"), ("J", "K"), ("K", "L")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let search = graph.depthFirstSearch(from: "A")
        #expect(search.preorder.joined() == "ABCDHJKLEFIG")
        #expect(search.postorder.joined() == "LKJHDEIFGCBA")
        var counts = [0, 0, 0, 0]
        for event in search {
            switch event {
            case .treeEdge: counts[0] += 1
            case .backEdge(let edge):
                counts[1] += 1
                #expect(edge == DirectedEdge(from: "I", to: "C"))
            case .forwardEdge: counts[2] += 1
            case .crossEdge: counts[3] += 1
            default: break
            }
        }
        #expect(counts == [11, 1, 1, 2])
    }

    @Test("TR-64 preorder and postorder are the discover and finish events", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func ordersMatchEvents(_ fixture: DirectedFixture<Int>) {
        let search = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges).depthFirstSearch()
        #expect(Array(search.preorder) == search.compactMap { if case .discover(let v) = $0 { v } else { nil } })
        #expect(Array(search.postorder) == search.compactMap { if case .finish(let v) = $0 { v } else { nil } })
        #expect(Set(search.preorder) == Set(0 ..< fixture.vertexCount))
    }
}

@Suite("Depth limits, pruning and early exit")
struct SearchControlTests {
    @Test("TR-74 / TR-75 / TR-78 depth-limited orders on NetworkX's tree")
    func depthLimitedOrders() {
        var edges: [DirectedEdge<Int>] = []
        for (a, b) in [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (2, 7), (7, 8), (8, 9), (9, 10)] {
            edges += [DirectedEdge(from: a, to: b), DirectedEdge(from: b, to: a)]
        }
        let graph = AdjacencyMatrix(vertexCount: 11, edges: edges)
        #expect(Array(graph.depthFirstSearch(from: 0, depthLimit: 2).preorder) == [0, 1, 2])
        // NetworkX's postorder drops the vertices at the limit ([1, 0]); here every discovered vertex finishes.
        #expect(Array(graph.depthFirstSearch(from: 0, depthLimit: 2).postorder) == [2, 1, 0])
        #expect(Array(graph.depthFirstSearch(from: 3, depthLimit: 3).preorder) == [3, 2, 1, 0, 7, 8, 4, 5, 6])
        #expect(Array(graph.depthFirstSearch(from: 3, depthLimit: 3).postorder) == [0, 1, 8, 7, 2, 6, 5, 4, 3])
        func treeEdges(_ search: DepthFirstSearch<AdjacencyMatrix>) -> [DirectedEdge<Int>] {
            search.compactMap { if case .treeEdge(let edge) = $0 { edge } else { nil } }
        }
        #expect(treeEdges(graph.depthFirstSearch(from: 9, depthLimit: 4)) == [
            DirectedEdge(from: 9, to: 8), DirectedEdge(from: 8, to: 7), DirectedEdge(from: 7, to: 2),
            DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 9, to: 10),
        ])
        #expect(treeEdges(graph.depthFirstSearch(from: 3, depthLimit: 1)) == [DirectedEdge(from: 3, to: 2), DirectedEdge(from: 3, to: 4)])
        var predecessors: [Int: Int] = [:]
        for edge in treeEdges(graph.depthFirstSearch(from: 0, depthLimit: 3)) { predecessors[edge.target] = edge.source }
        #expect(predecessors == [1: 0, 2: 1, 3: 2, 7: 2])
    }

    @Test("TR-77 every discovered vertex is finished, with or without a limit", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func everyDiscoveredFinishes(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        for limit in [nil, 0, 1, 2, 3] as [Int?] {
            for source in graph.vertices {
                let depthFirst = graph.depthFirstSearch(from: source, depthLimit: limit)
                #expect(Set(depthFirst.preorder) == Set(depthFirst.postorder))
                #expect(Array(depthFirst.preorder).count == Array(depthFirst.postorder).count)
                let breadthFirst = graph.breadthFirstSearch(from: source, depthLimit: limit)
                let discovered = breadthFirst.compactMap { if case .discover(let v) = $0 { v } else { nil } }
                let finished = breadthFirst.compactMap { if case .finish(let v) = $0 { v } else { nil } }
                #expect(discovered == finished)
            }
        }
    }

    @Test("TR-81 / TR-82 pruning after a discovery skips that vertex's out-edges but still finishes it")
    func depthFirstPrune() {
        let edges = [(0, 5), (0, 2), (0, 3), (0, 1), (1, 3), (2, 3), (2, 4), (4, 0), (4, 5)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = CompressedSparseRow(vertexCount: 6, edges: edges)
        var search = graph.depthFirstSearch(from: 0).makeIterator()
        var events: [String] = []
        while let event = search.next() {
            events.append(event.description)
            if event == .discover(2) { search.prune() }
        }
        // petgraph tests/graph.rs: "if we prune 2, we never see 4".
        #expect(events.joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) treeEdge(1→3) discover(3) finish(3) finish(1) treeEdge(0→2) discover(2) finish(2) forwardEdge(0→3) treeEdge(0→5) discover(5) finish(5) finish(0)")
        var root = graph.depthFirstSearch(from: 0).makeIterator()
        var rootEvents: [String] = []
        while let event = root.next() {
            rootEvents.append(event.description)
            if event == .discover(0) { root.prune() }
        }
        #expect(rootEvents == ["discover(0)", "finish(0)"])
    }

    @Test("TR-83 pruning a breadth-first search")
    func breadthFirstPrune() {
        let edges = [(0, 5), (0, 2), (0, 3), (0, 1), (1, 3), (2, 3), (2, 4), (4, 0), (4, 5)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = AdjacencyMatrix(vertexCount: 6, edges: edges)
        var search = graph.breadthFirstSearch(from: 0).makeIterator()
        var events: [String] = []
        while let event = search.next() {
            events.append(event.description)
            if event == .discover(2) { search.prune() }
        }
        #expect(events.joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) treeEdge(0→2) discover(2) treeEdge(0→3) discover(3) treeEdge(0→5) discover(5) finish(0) nonTreeEdge(1→3) finish(1) finish(2) finish(3) finish(5)")
    }

    @Test("TR-84 early exit: stop at the tree edge into a goal and read the path from the parents")
    func earlyExit() {
        let edges = [(0, 5), (0, 2), (0, 3), (0, 1), (1, 3), (2, 3), (2, 4), (4, 0), (4, 5)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = CompressedSparseRow(vertexCount: 6, edges: edges)
        var parent: [Int: Int] = [:]
        var consumed: [String] = []
        for event in graph.depthFirstSearch(from: 0) {
            consumed.append(event.description)
            if case .treeEdge(let edge) = event {
                parent[edge.target] = edge.source
                if edge.target == 4 { break }
            }
        }
        #expect(consumed.joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) treeEdge(1→3) discover(3) finish(3) finish(1) treeEdge(0→2) discover(2) crossEdge(2→3) treeEdge(2→4)")
        var path = [4]
        while let p = parent[path.last!] { path.append(p) }
        #expect(Array(path.reversed()) == [0, 2, 4])
    }

    @Test("TR-172 prune applies only right after a discover event", .tags(.precondition))
    func pruneOutsideADiscovery() async {
        await #expect(processExitsWith: .failure) {
            var search = AdjacencyList(edges: DirectedFixture<Int>.house.edges).depthFirstSearch(from: 5).makeIterator()
            search.prune()
        }
        await #expect(processExitsWith: .failure) {
            var search = AdjacencyList(edges: DirectedFixture<Int>.house.edges).depthFirstSearch(from: 5).makeIterator()
            _ = search.next()
            _ = search.next()
            // The last event was a tree edge.
            search.prune()
        }
        await #expect(processExitsWith: .failure) {
            var search = CompressedSparseRow(vertexCount: 1).breadthFirstSearch(from: 0).makeIterator()
            _ = search.next()
            _ = search.next()
            // The last event was finish(0); petgraph panics here too.
            search.prune()
        }
        await #expect(processExitsWith: .failure) {
            var search = CompressedSparseRow(vertexCount: 1).breadthFirstSearch(from: 0).makeIterator()
            while search.next() != nil {}
            search.prune()
        }
    }

    @Test("TR-176 pruning right after a discovery prunes that vertex, also after its tree edge was reported")
    func pruneJustDiscovered() {
        // In a probe, pruning after finish(0) used to prune vertex 2 instead.
        let graph = CompressedSparseRow(vertexCount: 4, edges: [(0, 1), (1, 2), (2, 3)].map { DirectedEdge(from: $0.0, to: $0.1) })
        var search = graph.depthFirstSearch(from: 0).makeIterator()
        var events: [String] = []
        while let event = search.next() {
            events.append(event.description)
            if event == .discover(2) { search.prune() }
        }
        #expect(events.joined(separator: " ") == "discover(0) treeEdge(0→1) discover(1) treeEdge(1→2) discover(2) finish(2) finish(1) finish(0)")
    }
}
