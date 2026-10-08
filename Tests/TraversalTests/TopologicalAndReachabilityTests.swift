// Topological sorting, cycle finding, reachability, bidirectional search, iterative deepening, and
// the closure-based entry points for state spaces that are not finite graphs. Case IDs (TR-nn)
// refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

@Suite("Topological sorting and cycles")
struct TopologicalSortTests {
    @Test("TR-86 the empty graph")
    func empty() {
        let graph = AdjacencyList<Int>()
        #expect(graph.topologicalSort() == [])
        #expect(graph.lexicographicalTopologicalSort() == [])
        #expect(graph.topologicalGenerations() == [])
        #expect(graph.findCycle() == nil)
        #expect(graph.isAcyclic)
    }

    @Test("TR-87 – TR-91 the three orders on the fixtures")
    func fixtures() {
        let cases: [(DirectedFixture<Int>, depthFirst: [Int], lexicographical: [Int], generations: [[Int]])] = [
            (.isolatedVertices, Array((0 ..< 10).reversed()), Array(0 ..< 10), [Array(0 ..< 10)]),
            (.house, [5, 3, 4, 2, 1, 0], [5, 3, 2, 4, 1, 0], [[5], [3], [2, 4], [1], [0]]),
            (.neo4jDirected, [0, 1, 3, 2, 4], [0, 1, 2, 3, 4], [[0], [1], [2, 3], [4]]),
            (.boostCsrUnsorted, [5, 4, 3, 1, 0, 2], [3, 4, 1, 5, 0, 2], [[3, 4, 5], [0, 1], [2]]),
            (.scipyConstructor2, [5, 3, 4, 2, 1, 0], [0, 1, 2, 3, 4, 5], [[0, 1, 2, 3, 5], [4]]),
        ]
        for (fixture, depthFirst, lexicographical, generations) in cases {
            let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
            #expect(matrix.topologicalSort() == depthFirst, "\(fixture.name)")
            #expect(sparse.topologicalSort() == depthFirst, "\(fixture.name)")
            // Generations as sets; their order within a generation is checked by TR-96.
            #expect(matrix.topologicalGenerations()?.map(Set.init) == generations.map(Set.init), "\(fixture.name)")
            #expect(sparse.topologicalGenerations()?.map(Set.init) == generations.map(Set.init), "\(fixture.name)")
            #expect(list.topologicalGenerations()?.map(Set.init) == generations.map(Set.init), "\(fixture.name)")
            // The lexicographical order does not depend on successor order.
            #expect(matrix.lexicographicalTopologicalSort() == lexicographical, "\(fixture.name)")
            #expect(list.lexicographicalTopologicalSort() == lexicographical, "\(fixture.name)")
            #expect(list.isAcyclic)
        }
    }

    @Test("TR-92 / TR-93 / TR-94 String vertices")
    func strings() {
        let dag = DirectedFixture<String>.petgraphDAG
        let list = AdjacencyList(vertices: dag.vertices, edges: dag.edges)
        #expect(list.lexicographicalTopologicalSort() == ["a", "d", "b", "c", "f", "e", "g"])
        #expect(list.topologicalGenerations()?.map(Set.init) == [["a"], ["d"], ["b", "f"], ["c"], ["e"], ["g"]])
        #expect(ReferenceDirectedMultigraph(vertices: dag.vertices, edges: dag.edges).topologicalSort() == ["a", "d", "f", "b", "c", "e", "g"])
        let extended = AdjacencyList(vertices: dag.vertices, edges: dag.edges + [
            DirectedEdge(from: "h", to: "i"), DirectedEdge(from: "h", to: "j"), DirectedEdge(from: "i", to: "j"),
        ])
        #expect(extended.lexicographicalTopologicalSort() == ["a", "d", "b", "c", "f", "e", "g", "h", "i", "j"])
        #expect(extended.topologicalGenerations()?.map(Set.init) == [["a", "h"], ["d", "i"], ["b", "f", "j"], ["c"], ["e"], ["g"]])
        let abcd = DirectedFixture<String>.networkXABCD
        let abcdList = AdjacencyList(vertices: abcd.vertices, edges: abcd.edges)
        #expect(abcdList.lexicographicalTopologicalSort() == ["A", "B", "C", "D", "G", "J", "K"])
        #expect(abcdList.topologicalGenerations()?.map(Set.init) == [["A", "G", "J", "K"], ["B"], ["C"], ["D"]])
        #expect(ReferenceDirectedMultigraph(vertices: abcd.vertices, edges: abcd.edges).topologicalSort() == ["A", "B", "C", "D", "K", "J", "G"])
    }

    @Test("TR-95 NetworkX's test_topological_sort1: adding and removing a back edge")
    func addAndRemoveCycle() {
        let base = [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)]
        let acyclic = AdjacencyList(edges: base)
        #expect(acyclic.topologicalSort() == [1, 2, 3])
        #expect(acyclic.lexicographicalTopologicalSort() == [1, 2, 3])
        #expect(acyclic.topologicalGenerations() == [[1], [2], [3]])
        var cyclic = acyclic
        cyclic.insert(edge: DirectedEdge(from: 3, to: 2))
        #expect(cyclic.topologicalSort() == nil)
        #expect(cyclic.lexicographicalTopologicalSort() == nil)
        #expect(cyclic.topologicalGenerations() == nil)
        #expect(Set(cyclic.findCycle() ?? []) == [2, 3])
        #expect(!cyclic.isAcyclic)
        cyclic.remove(edge: DirectedEdge(from: 2, to: 3))
        #expect(cyclic.topologicalSort() == [1, 3, 2])
        #expect(cyclic.lexicographicalTopologicalSort() == [1, 3, 2])
        #expect(cyclic.topologicalGenerations() == [[1], [3], [2]])
    }

    @Test("TR-96 generations flattened in discovery order are NetworkX's and igraph's topological_sort")
    func flattenedGenerations() {
        let house = DirectedFixture<Int>.house
        #expect(Array(AdjacencyMatrix(vertexCount: 6, edges: house.edges).topologicalGenerations()!.joined()) == [5, 3, 2, 4, 1, 0])
        let unsorted = DirectedFixture<Int>.boostCsrUnsorted
        #expect(Array(CompressedSparseRow(vertexCount: 6, edges: unsorted.edges).topologicalGenerations()!.joined()) == [3, 4, 5, 1, 0, 2])
    }

    @Test("TR-97 / TR-98 the lexicographical order with a custom order, and with ties")
    func customOrder() {
        let edges = [(1, 2), (2, 3), (1, 4), (1, 5), (2, 6)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = AdjacencyList(edges: edges)
        #expect(graph.lexicographicalTopologicalSort() == [1, 2, 3, 4, 5, 6])
        #expect(graph.lexicographicalTopologicalSort(by: >) == [1, 5, 4, 2, 6, 3])
        // Equal keys: the order must not need to compare the vertices themselves, and ties go in the
        // order they became ready, which gives NetworkX's [0, 1, 2, 3].
        let ties = ReferenceDirectedMultigraph(edges: [(0, 1), (0, 2), (0, 3), (2, 3)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let order = ties.lexicographicalTopologicalSort { _, _ in false }
        #expect(order == [0, 1, 2, 3])
        #expect(order?.count == 4)
        if let order {
            let position = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
            for edge in ties.edges { #expect(position[edge.source]! < position[edge.target]!) }
        }
    }

    @Test("TR-99 / TR-100 generations from NetworkX and the pathfinding crate")
    func generations() {
        // NetworkX: the reverse of {1: [2, 3], 2: [4, 5], 3: [7], 5: [6, 7]}.
        let forward: [(Int, Int)] = [(1, 2), (1, 3), (2, 4), (2, 5), (3, 7), (5, 6), (5, 7)]
        let reversed = AdjacencyList(edges: forward.map { DirectedEdge(from: $0.1, to: $0.0) })
        #expect(reversed.topologicalGenerations()?.map(Set.init) == [[4, 6, 7], [3, 5], [2], [1]])
        let multi = ReferenceDirectedMultigraph(edges: forward.map { DirectedEdge(from: $0.1, to: $0.0) } + [DirectedEdge(from: 2, to: 1)])
        #expect(multi.topologicalGenerations()?.map(Set.init) == [[4, 6, 7], [3, 5], [2], [1]])
        let diamond = AdjacencyMatrix(vertexCount: 4, edges: [(0, 1), (0, 2), (1, 3), (2, 3)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(diamond.topologicalGenerations() == [[0], [1, 2], [3]])
        let second = AdjacencyMatrix(vertexCount: 6, edges: [(0, 1), (0, 5), (1, 2), (2, 3), (4, 5), (5, 3)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(second.topologicalGenerations() == [[0, 4], [1, 5], [2], [3]])
    }

    @Test("TR-101 igraph's Wikipedia DAG, and with a cycle added")
    func igraph() {
        let edges = [(0, 3), (0, 4), (1, 3), (2, 4), (2, 7), (3, 5), (3, 6), (3, 7), (4, 6)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = CompressedSparseRow(vertexCount: 8, edges: edges)
        #expect(Array(graph.topologicalGenerations()!.joined()) == [0, 1, 2, 3, 4, 5, 7, 6])
        #expect(graph.lexicographicalTopologicalSort() == Array(0 ..< 8))
        #expect(graph.topologicalSort() == [2, 1, 0, 4, 3, 7, 6, 5])
        let cyclic = CompressedSparseRow(vertexCount: 8, edges: edges + [DirectedEdge(from: 5, to: 0)])
        #expect(cyclic.topologicalSort() == nil)
        #expect(cyclic.findCycle() == [0, 3, 5])
    }

    @Test("TR-104 JGraphT's topological iterator graph")
    func jgrapht() {
        let edges = [("v0", "v1"), ("v0", "v2"), ("v1", "v4"), ("v2", "v4"), ("v3", "v2"), ("v3", "v4"), ("v4", "v5")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = AdjacencyList(edges: edges)
        #expect(graph.lexicographicalTopologicalSort() == ["v0", "v1", "v3", "v2", "v4", "v5"])
        #expect(graph.topologicalGenerations()?.map(Set.init) == [["v0", "v3"], ["v1", "v2"], ["v4"], ["v5"]])
        #expect(ReferenceDirectedMultigraph(vertices: ["v0", "v1", "v2", "v3", "v4", "v5"], edges: edges).topologicalSort() == ["v3", "v0", "v2", "v1", "v4", "v5"])
    }

    @Test("TR-105 parallel edges count in the in-degrees, and every order stays valid")
    func parallelEdges() {
        // NetworkX: 9 vertices, edge i→i+1 written i times.
        var edges: [DirectedEdge<Int>] = []
        for i in 1 ..< 9 { edges += Array(repeating: DirectedEdge(from: i, to: i + 1), count: i) }
        let graph = ReferenceDirectedMultigraph(edges: edges)
        #expect(graph.topologicalSort() == Array(1 ... 9))
        #expect(graph.lexicographicalTopologicalSort() == Array(1 ... 9))
        #expect(graph.topologicalGenerations() == (1 ... 9).map { [$0] })
    }

    @Test("TR-106 / TR-107 the cycle found is the first back edge's, on the ascending representations")
    func cycleWitness() {
        let cases: [(DirectedFixture<Int>, [Int])] = [
            (.singleSelfLoop, [0]), (.petgraphCsr1, [0]), (.boostExample, [2]),
            (.completeDirected3, [0, 1]), (.scc9, [0, 3, 6]), (.boost24, [5, 14, 12, 4]),
            (.petgraphEdgesDirected, [0, 2, 4]), (.igraphReverseEdges, [1, 2, 3]), (.directedCycle10, Array(0 ..< 10)),
        ]
        for (fixture, cycle) in cases {
            let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            #expect(matrix.findCycle() == cycle, "\(fixture.name)")
            #expect(sparse.findCycle() == cycle, "\(fixture.name)")
            #expect(sparse.topologicalSort() == nil, "\(fixture.name)")
            #expect(!sparse.isAcyclic, "\(fixture.name)")
        }
        // NetworkX test_topological_sort2 and 3.
        let two = AdjacencyMatrix(vertexCount: 16, edges: [(1, 2), (2, 3), (3, 4), (4, 5), (5, 1), (11, 12), (12, 13), (13, 14), (14, 15)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(two.findCycle() == [1, 2, 3, 4, 5])
    }

    @Test("TR-106 any cycle found is a cycle of the graph", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func cycleIsValid(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        if let cycle = graph.findCycle() {
            #expect(!cycle.isEmpty)
            #expect(Set(cycle).count == cycle.count)
            for (k, v) in cycle.enumerated() {
                #expect(graph.contains(edge: DirectedEdge(from: v, to: cycle[(k + 1) % cycle.count])))
            }
            #expect(graph.topologicalSort() == nil)
        } else {
            #expect(graph.topologicalSort() != nil)
        }
    }
}

@Suite("Reachability")
struct ReachabilityTests {
    @Test("TR-109 / TR-110 NetworkX's descendants and ancestors")
    func networkX() {
        let edges = [(1, 2), (1, 3), (4, 2), (4, 3), (4, 5), (2, 6), (5, 6)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let list = AdjacencyList(edges: edges)
        let matrix = AdjacencyMatrix(vertexCount: 7, edges: edges)
        for (v, expected) in [(1, [2, 3, 6]), (4, [2, 3, 5, 6]), (3, [])] as [(Int, Set<Int>)] {
            #expect(list.descendants(of: v) == expected)
            #expect(matrix.descendants(of: v) == expected)
        }
        for (v, expected) in [(6, [1, 2, 4, 5]), (3, [1, 4]), (1, [])] as [(Int, Set<Int>)] {
            #expect(list.ancestors(of: v) == expected)
            #expect(matrix.ancestors(of: v) == expected)
            #expect(ReferenceDirectedMultigraph(edges: edges).ancestors(of: v) == expected)
        }
    }

    @Test("TR-111 / TR-112 reverse reachability, and a vertex on a cycle is not its own descendant")
    func fixtures() {
        #expect(AdjacencyList(edges: DirectedFixture<Int>.scc9.edges).ancestors(of: 8) == [1, 2, 4, 5, 7])
        #expect(AdjacencyList(edges: DirectedFixture<Int>.petgraphBellmanFord.edges).ancestors(of: 8) == [4, 5, 6, 7])
        #expect(AdjacencyMatrix(vertexCount: 6, edges: DirectedFixture<Int>.boostExample.edges).ancestors(of: 5) == [1])
        #expect(AdjacencyList(edges: DirectedFixture<Int>.directedCycle4.edges).descendants(of: 1) == [2, 3, 4])
        #expect(AdjacencyList(edges: DirectedFixture<Int>.singleSelfLoop.edges).descendants(of: 0) == [])
    }

    @Test("TR-113 petgraph's reach counts")
    func petgraph() {
        let graph = AdjacencyList(vertices: ["Z"], edges: [("H", "I"), ("H", "J"), ("I", "J"), ("I", "K")].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.descendants(of: "H").count + 1 == 4)
        #expect(graph.descendants(of: "I").count + 1 == 3)
        #expect(graph.ancestors(of: "H") == [])
        #expect(graph.ancestors(of: "K") == ["I", "H"])
        #expect(graph.descendants(of: "Z") == [])
    }

    @Test("TR-114 hasPath agrees with descendants, and every vertex reaches itself", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func hasPathAgrees(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        for u in graph.vertices {
            let descendants = graph.descendants(of: u)
            for v in graph.vertices {
                #expect(graph.hasPath(from: u, to: v) == (u == v || descendants.contains(v)))
            }
        }
    }
}

@Suite("Bidirectional search and iterative deepening")
struct ShortestSearchTests {
    @Test("TR-115 NetworkX's cycle cases")
    func cycles() {
        var symmetric: [DirectedEdge<Int>] = []
        for i in 0 ..< 7 { symmetric += [DirectedEdge(from: i, to: (i + 1) % 7), DirectedEdge(from: (i + 1) % 7, to: i)] }
        let undirected = AdjacencyMatrix(vertexCount: 7, edges: symmetric)
        #expect(undirected.bidirectionalShortestPath(from: 0, to: 3) == [0, 1, 2, 3])
        #expect(undirected.bidirectionalShortestPath(from: 0, to: 4) == [0, 6, 5, 4])
        #expect(undirected.bidirectionalShortestPath(from: 3, to: 3) == [3])
        let directed = AdjacencyMatrix(vertexCount: 7, edges: (0 ..< 7).map { DirectedEdge(from: $0, to: ($0 + 1) % 7) })
        #expect(directed.bidirectionalShortestPath(from: 0, to: 3) == [0, 1, 2, 3])
    }

    @Test("TR-116 / TR-121 the fixtures: bidirectional search and iterative deepening find the same paths")
    func fixtures() {
        let cases: [(DirectedFixture<Int>, Int, Int, [Int]?)] = [
            (.house, 5, 0, [5, 3, 4, 0]), (.house, 5, 1, [5, 3, 2, 1]), (.house, 0, 5, nil),
            (.scc9, 1, 3, [1, 7, 5, 8, 6, 0, 3]), (.scc9, 6, 6, [6]),
            (.boost24, 7, 2, [7, 11, 19, 18, 9, 1, 2]), (.boost24, 23, 3, [23, 16, 6, 3]), (.boost24, 1, 7, nil),
            (.petgraphEdgesDirected, 2, 5, [2, 4, 0, 5]), (.petgraphEdgesDirected, 6, 0, nil),
            (.boostWebGraph, 4, 2, [4, 1, 0, 2]), (.boostWebGraph, 2, 4, [2, 0, 3, 4]),
            (.cube, 0, 7, [0, 1, 3, 7]), (.petersen, 0, 7, [0, 5, 7]), (.directedCycle10, 9, 8, [9] + Array(0 ... 8)),
        ]
        for (fixture, source, target, expected) in cases {
            let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
            #expect(matrix.bidirectionalShortestPath(from: source, to: target) == expected, "\(fixture.name) \(source)→\(target)")
            #expect(iterativeDeepeningDepthFirstSearch(from: source, successors: { matrix.successors(of: $0) }, until: { $0 == target }) == expected, "\(fixture.name) \(source)→\(target)")
            let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
            #expect(list.bidirectionalShortestPath(from: source, to: target)?.count == expected?.count, "\(fixture.name)")
        }
    }

    @Test("TR-117 / TR-125 both find a shortest path, of the breadth-first distance", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func shortest(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for source in graph.vertices {
            var distance: [Int: Int] = [:]
            for (k, layer) in graph.breadthFirstLayers(from: source).enumerated() {
                for v in layer { distance[v] = k }
            }
            for target in graph.vertices {
                let deepening = iterativeDeepeningDepthFirstSearch(from: source, successors: { graph.successors(of: $0) }, until: { $0 == target })
                for path in [graph.bidirectionalShortestPath(from: source, to: target), deepening] {
                    guard let path else {
                        #expect(distance[target] == nil)
                        continue
                    }
                    #expect(path.count - 1 == distance[target])
                    #expect(path.first == source)
                    #expect(path.last == target)
                    for k in 0 ..< path.count - 1 { #expect(graph.contains(edge: DirectedEdge(from: path[k], to: path[k + 1]))) }
                }
            }
        }
    }

    @Test("TR-174 the smaller frontier is expanded, so the backward search can decide which shortest path is found")
    func smallerFrontier() {
        // Two shortest paths, 0-1-5-6 and 0-2-4-6. After one forward level the frontier is
        // [1, 2, 3] against [6]; the backward levels reach 2 first, as NetworkX does.
        let edges = [(0, 1), (0, 2), (0, 3), (1, 5), (2, 4), (4, 6), (5, 6)].map { DirectedEdge(from: $0.0, to: $0.1) }
        #expect(AdjacencyMatrix(vertexCount: 7, edges: edges).bidirectionalShortestPath(from: 0, to: 6) == [0, 2, 4, 6])
    }

    @Test("TR-118 a 4×4 grid")
    func grid() {
        var edges: [DirectedEdge<Int>] = []
        for v in 1 ... 16 {
            if v % 4 != 0 { edges += [DirectedEdge(from: v, to: v + 1), DirectedEdge(from: v + 1, to: v)] }
            if v <= 12 { edges += [DirectedEdge(from: v, to: v + 4), DirectedEdge(from: v + 4, to: v)] }
        }
        let path = AdjacencyMatrix(vertexCount: 17, edges: edges).bidirectionalShortestPath(from: 1, to: 12)
        #expect(path?.count == 6)
        #expect(path == [1, 2, 3, 4, 8, 12])
    }

    @Test("TR-120 a source or target that is not a vertex traps", .tags(.precondition))
    func notAVertex() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).bidirectionalShortestPath(from: 8, to: 0)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).bidirectionalShortestPath(from: 0, to: 8)
        }
    }

    @Test("TR-122 / TR-123 iterative deepening: the source itself, and an unreachable target terminates")
    func iterativeDeepeningEdges() {
        let house = AdjacencyList(edges: DirectedFixture<Int>.house.edges)
        #expect(iterativeDeepeningDepthFirstSearch(from: 3, successors: { house.successors(of: $0) }, until: { $0 == 3 }) == [3])
        #expect(iterativeDeepeningDepthFirstSearch(from: 0, successors: { house.successors(of: $0) }, until: { $0 == 5 }) == nil)
        let scc9 = AdjacencyList(edges: DirectedFixture<Int>.scc9.edges)
        #expect(iterativeDeepeningDepthFirstSearch(from: 0, successors: { scc9.successors(of: $0) }, until: { $0 == 8 }) == nil)
    }

    @Test("TR-175 iterative deepening keeps its own stack: a 1 000-vertex chain on a task's small stack")
    func iterativeDeepeningDeep() async {
        // Each round walks the chain again, checking the path for repeats: cubic work, so the chain
        // is kept short. A recursive search crashed at depth 4 000 on a 256 KiB stack.
        let n = 1_000
        await Task {
            let path = iterativeDeepeningDepthFirstSearch(from: 0, successors: { $0 < n ? [$0 + 1] : [] }, until: { $0 == n })
            #expect(path == Array(0 ... n))
        }.value
    }
}

@Suite("Searches over successor closures")
struct ClosureSearchTests {
    @Test("TR-124 iterative deepening needs only Equatable states")
    func equatableStates() {
        struct State: Equatable { let value: Int }
        let path = iterativeDeepeningDepthFirstSearch(from: State(value: 0), successors: { state in
            [state.value + 1, state.value + 3].filter { $0 <= 20 }.map(State.init)
        }, until: { $0.value == 20 })
        #expect(path?.map(\.value) == [0, 1, 2, 5, 8, 11, 14, 17, 20])
    }

    @Test("TR-131 / TR-132 depth-first and breadth-first orders over a closure")
    func orders() {
        let preorder = depthFirstSearch(from: [0], successors: { [$0 + 1, $0 + 5].filter { $0 <= 10 } })
            .compactMap { if case .discover(let v) = $0 { v } else { nil } }
        #expect(preorder == Array(0 ... 10))
        let branching = { (n: Int) in [n + 2, n + 5].filter { $0 <= 10 } }
        #expect(depthFirstSearch(from: [0], successors: branching).compactMap { if case .discover(let v) = $0 { v } else { nil } } == [0, 2, 4, 6, 8, 10, 9, 7, 5])
        #expect(breadthFirstSearch(from: [0], successors: branching).compactMap { if case .discover(let v) = $0 { v } else { nil } } == [0, 2, 5, 4, 7, 10, 6, 9, 8])
    }

    @Test("TR-133 many repeated successors")
    func repeatedSuccessors() {
        let preorder = depthFirstSearch(from: [0], successors: { (k: Int) in k < 200 ? Array(repeating: k + 1, count: 200) : [] })
            .compactMap { if case .discover(let v) = $0 { v } else { nil } }
        #expect(preorder == Array(0 ... 200))
    }

    @Test("TR-134 an infinite space, cut short by the caller or by a depth limit")
    func infinite() {
        let children = { (n: Int) in [2 * n, 2 * n + 1] }
        let first = breadthFirstSearch(from: [1], successors: children)
            .lazy.compactMap { if case .discover(let v) = $0 { v } else { nil } }.prefix(15)
        #expect(Array(first) == Array(1 ... 15))
        let limited = depthFirstSearch(from: [1], depthLimit: 3, successors: children)
            .compactMap { if case .discover(let v) = $0 { v } else { nil } }
        #expect(limited == [1, 2, 4, 8, 9, 5, 10, 11, 3, 6, 12, 13, 7, 14, 15])
    }

    @Test("TR-135 / TR-136 topological sorting from roots over a closure")
    func topological() {
        // The pathfinding crate's documentation examples.
        let acyclic = topologicalSort(from: [5, 1], successors: { (n: Int) -> [Int] in
            n <= 7 ? [n + 1, n + 2] : n == 8 ? [9] : []
        })
        #expect(acyclic == Array(1 ... 9))
        let cyclic = topologicalSort(from: [1], successors: { (n: Int) -> [Int] in
            n <= 6 ? [n + 1, n + 2, 7] : n == 7 ? [8, 9] : n == 8 ? [7, 9] : [7]
        })
        #expect(cyclic == nil)
    }

    @Test("TR-137 the closure is called once per discovered state")
    func calledOncePerState() {
        var generator = SeededRandomNumberGenerator(seed: 137)
        var calls = 0
        let order = topologicalSort(from: Array(1 ... 999).shuffled(using: &generator), successors: { (n: Int) -> [Int] in
            calls += 1
            return n < 999 ? [n + 1] : []
        })
        #expect(order == Array(1 ... 999))
        #expect(calls == 999)
    }

    @Test("TR-138 several starts, stopping at the first goal")
    func multipleStarts() {
        let next = ["a": ["b"], "b": ["c"], "c": ["d"], "d": ["e"], "e": []]
        var parent: [String: String] = [:]
        var goal: String?
        for event in breadthFirstSearch(from: ["a", "b"], successors: { next[$0]! }) {
            if case .treeEdge(let edge) = event { parent[edge.target] = edge.source }
            if case .discover(let v) = event, v == "d" || v == "e" {
                goal = v
                break
            }
        }
        #expect(goal == "d")
        var path = ["d"]
        while let p = parent[path.last!] { path.append(p) }
        #expect(Array(path.reversed()) == ["b", "c", "d"])
    }
}
