// Algorithms see the base. Traversal and Connectivity run on seeded random DAGs over each of the three
// bases, built by random inserts (some rejected) and removals, and every result must equal the same
// call on `graph.base`, positions included: the wrapper forwards every index-space member. After every
// operation `topologicalOrder` must be a topological order: a permutation of the vertices with every
// edge going forward. Then the conformances: Equatable and Hashable ignore the order, the descriptions,
// Codable round trips on every base (holes included), copy-on-write, the resets and capacity,
// `init(_ graph:)` across bases, Sendable, and the stable base's sparse indexing. See README.md.

import AdjacencyListModule
import Connectivity
import DirectedAcyclicGraphModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing
import Traversal
import Walks

@Suite("DirectedAcyclicGraph conformances and algorithms", .tags(.conformance))
struct DirectedAcyclicGraphConformanceTests {
    @Test("Over AdjacencyList: Traversal and Connectivity equal the base's, and the order stays topological", arguments: [1, 2, 3, 4, 5])
    func algorithmsOverAdjacencyList(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 6 + seed * 3
        var graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: (0 ..< n).shuffled(using: &rng))
        for step in 0 ..< n * 4 {
            let u = Int.random(in: 0 ..< n + 2, using: &rng), v = Int.random(in: 0 ..< n + 2, using: &rng)
            if step % 9 == 8 {
                _ = graph.remove(u)
            } else if step % 7 == 6 {
                _ = graph.remove(edge: DirectedEdge(from: u, to: v))
            } else {
                _ = try? graph.insert(edge: DirectedEdge(from: u, to: v))
            }
            let order = Array(graph.topologicalOrder)
            #expect(Set(order) == Set(graph.vertices) && order.count == graph.vertexCount, "step \(step)")
            #expect(graph.edges.allSatisfy { order.firstIndex(of: $0.source)! < order.firstIndex(of: $0.target)! }, "step \(step)")
        }
        let base = graph.base
        let vertices = Array(graph.vertices)
        #expect(Array(graph.edges) == Array(base.edges))
        #expect(graph.vertexIndexBound == base.vertexIndexBound && graph.edgeIndexBound == base.edgeIndexBound)
        for i in vertices.indices {
            #expect(graph.vertex(atIndex: i) == base.vertex(atIndex: i) && graph.vertexIndex(of: vertices[i]) == base.vertexIndex(of: vertices[i]))
            #expect(Array(graph.successorIndices(ofIndex: i)) == Array(base.successorIndices(ofIndex: i)))
            #expect(Array(graph.predecessorIndices(ofIndex: i)) == Array(base.predecessorIndices(ofIndex: i)))
            #expect(Array(graph.outEdges(ofIndex: i)) == Array(base.outEdges(ofIndex: i)) && Array(graph.inEdges(ofIndex: i)) == Array(base.inEdges(ofIndex: i)))
        }
        for p in graph.edges.indices {
            #expect(graph.sourceIndex(ofEdgeAt: p) == base.sourceIndex(ofEdgeAt: p) && graph.targetIndex(ofEdgeAt: p) == base.targetIndex(ofEdgeAt: p))
            #expect(graph.edgeIndex(of: p) == base.edgeIndex(of: p))
        }
        #expect(graph.topologicalSort() != nil && graph.topologicalSort() == base.topologicalSort())
        #expect(graph.topologicalGenerations() == base.topologicalGenerations())
        #expect(graph.lexicographicalTopologicalSort() == base.lexicographicalTopologicalSort())
        #expect(graph.findCycle() == nil && base.findCycle() == nil && graph.isAcyclic)
        #expect(Array(graph.depthFirstSearch()) == Array(base.depthFirstSearch()))
        #expect(graph.weaklyConnectedComponents().map { Array($0) } == base.weaklyConnectedComponents().map { Array($0) })
        #expect(graph.stronglyConnectedComponents().map { Array($0) } == base.stronglyConnectedComponents().map { Array($0) })
        #expect(graph.stronglyConnectedComponents().count == graph.vertexCount)
        #expect(graph.condensation().components.map { Array($0) } == base.condensation().components.map { Array($0) })
        #expect(Array(graph.condensation().graph.edges) == Array(base.condensation().graph.edges))
        #expect(graph.attractingComponents().map { Array($0) } == base.attractingComponents().map { Array($0) })
        for source in vertices {
            #expect(Array(graph.breadthFirstSearch(from: source)) == Array(base.breadthFirstSearch(from: source)))
            #expect(Array(graph.depthFirstSearch(from: source)) == Array(base.depthFirstSearch(from: source)))
            #expect(graph.breadthFirstLayers(from: source) == base.breadthFirstLayers(from: source))
            #expect(graph.descendants(of: source) == base.descendants(of: source))
            #expect(graph.ancestors(of: source) == base.ancestors(of: source))
            let tree = graph.dominatorTree(root: source), baseTree = base.dominatorTree(root: source)
            for target in vertices {
                #expect(graph.hasPath(from: source, to: target) == base.hasPath(from: source, to: target))
                #expect(graph.bidirectionalShortestPath(from: source, to: target) == base.bidirectionalShortestPath(from: source, to: target))
                #expect(tree.immediateDominator(of: target) == baseTree.immediateDominator(of: target))
            }
        }
    }

    @Test("Over DirectedPseudograph: Traversal and Connectivity equal the base's, and the order stays topological", arguments: [1, 2, 3, 4, 5])
    func algorithmsOverDirectedPseudograph(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(20 + seed))
        let n = 6 + seed * 3
        var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: (0 ..< n).shuffled(using: &rng))
        for step in 0 ..< n * 4 {
            let u = Int.random(in: 0 ..< n + 2, using: &rng), v = Int.random(in: 0 ..< n + 2, using: &rng)
            if step % 9 == 8 {
                _ = graph.remove(u)
            } else if step % 7 == 6, graph.edgeCount > 0 {
                _ = graph.remove(edgeAt: Int.random(in: 0 ..< graph.edgeCount, using: &rng))
            } else if step % 5 == 4 {
                _ = graph.remove(edge: DirectedEdge(from: u, to: v))
            } else {
                // Copies too: a repeat of an accepted edge is accepted again.
                _ = try? graph.insert(edge: DirectedEdge(from: u, to: v))
            }
            let order = Array(graph.topologicalOrder)
            #expect(Set(order) == Set(graph.vertices) && order.count == graph.vertexCount, "step \(step)")
            #expect(graph.edges.allSatisfy { order.firstIndex(of: $0.source)! < order.firstIndex(of: $0.target)! }, "step \(step)")
        }
        let base = graph.base
        let vertices = Array(graph.vertices)
        #expect(Array(graph.edges) == Array(base.edges))
        #expect(graph.vertexIndexBound == base.vertexIndexBound && graph.edgeIndexBound == base.edgeIndexBound)
        for i in vertices.indices {
            #expect(graph.vertex(atIndex: i) == base.vertex(atIndex: i) && graph.vertexIndex(of: vertices[i]) == base.vertexIndex(of: vertices[i]))
            #expect(Array(graph.successorIndices(ofIndex: i)) == Array(base.successorIndices(ofIndex: i)))
            #expect(Array(graph.predecessorIndices(ofIndex: i)) == Array(base.predecessorIndices(ofIndex: i)))
            #expect(Array(graph.outEdges(ofIndex: i)) == Array(base.outEdges(ofIndex: i)) && Array(graph.inEdges(ofIndex: i)) == Array(base.inEdges(ofIndex: i)))
        }
        for p in graph.edges.indices {
            #expect(graph.sourceIndex(ofEdgeAt: p) == base.sourceIndex(ofEdgeAt: p) && graph.targetIndex(ofEdgeAt: p) == base.targetIndex(ofEdgeAt: p))
            #expect(graph.edgeIndex(of: p) == base.edgeIndex(of: p))
        }
        #expect(graph.topologicalSort() != nil && graph.topologicalSort() == base.topologicalSort())
        #expect(graph.topologicalGenerations() == base.topologicalGenerations())
        #expect(graph.lexicographicalTopologicalSort() == base.lexicographicalTopologicalSort())
        #expect(graph.findCycle() == nil && base.findCycle() == nil && graph.isAcyclic)
        #expect(Array(graph.depthFirstSearch()) == Array(base.depthFirstSearch()))
        #expect(graph.weaklyConnectedComponents().map { Array($0) } == base.weaklyConnectedComponents().map { Array($0) })
        #expect(graph.stronglyConnectedComponents().map { Array($0) } == base.stronglyConnectedComponents().map { Array($0) })
        #expect(graph.stronglyConnectedComponents().count == graph.vertexCount)
        #expect(graph.condensation().components.map { Array($0) } == base.condensation().components.map { Array($0) })
        #expect(Array(graph.condensation().graph.edges) == Array(base.condensation().graph.edges))
        #expect(graph.attractingComponents().map { Array($0) } == base.attractingComponents().map { Array($0) })
        for source in vertices {
            #expect(Array(graph.breadthFirstSearch(from: source)) == Array(base.breadthFirstSearch(from: source)))
            #expect(Array(graph.depthFirstSearch(from: source)) == Array(base.depthFirstSearch(from: source)))
            #expect(graph.breadthFirstLayers(from: source) == base.breadthFirstLayers(from: source))
            #expect(graph.descendants(of: source) == base.descendants(of: source))
            #expect(graph.ancestors(of: source) == base.ancestors(of: source))
            let tree = graph.dominatorTree(root: source), baseTree = base.dominatorTree(root: source)
            for target in vertices {
                #expect(graph.hasPath(from: source, to: target) == base.hasPath(from: source, to: target))
                #expect(graph.bidirectionalShortestPath(from: source, to: target) == base.bidirectionalShortestPath(from: source, to: target))
                #expect(tree.immediateDominator(of: target) == baseTree.immediateDominator(of: target))
            }
        }
    }

    @Test("Over StableDirectedGraph with holes: Traversal and Connectivity equal the base's, and the order stays topological", arguments: [1, 2, 3, 4, 5])
    func algorithmsOverStableDirectedGraph(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(40 + seed))
        let n = 6 + seed * 3
        var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: (0 ..< n).shuffled(using: &rng))
        for step in 0 ..< n * 4 {
            let u = Int.random(in: 0 ..< n + 2, using: &rng), v = Int.random(in: 0 ..< n + 2, using: &rng)
            if step % 9 == 8 {
                _ = graph.remove(u)
            } else if step % 7 == 6, let p = Array(graph.edges.indices).randomElement(using: &rng) {
                _ = graph.remove(edgeAt: p)
            } else if step % 5 == 4 {
                _ = graph.remove(edge: DirectedEdge(from: u, to: v))
            } else {
                _ = try? graph.insert(edge: DirectedEdge(from: u, to: v))
            }
            let order = Array(graph.topologicalOrder)
            #expect(Set(order) == Set(graph.vertices) && order.count == graph.vertexCount, "step \(step)")
            #expect(graph.edges.allSatisfy { order.firstIndex(of: $0.source)! < order.firstIndex(of: $0.target)! }, "step \(step)")
        }
        // Holes at both ends: the sparse path of the algorithms.
        if let first = graph.vertices.first { _ = graph.remove(first) }
        let base = graph.base
        let vertices = Array(graph.vertices)
        #expect(graph.vertexIndexBound == base.vertexIndexBound && graph.edgeIndexBound == base.edgeIndexBound)
        #expect(Array(graph.edges) == Array(base.edges) && Array(graph.edges.indices) == Array(base.edges.indices))
        #expect(graph.vertexPositionBound == base.vertexPositionBound && graph.edgePositionBound == base.edgePositionBound)
        for v in vertices {
            #expect(graph.vertexPosition(of: v) == base.vertexPosition(of: v))
            #expect(graph.vertex(atPosition: graph.vertexPosition(of: v)) == v)
        }
        for p in 0 ..< base.edgePositionBound {
            #expect(graph.containsEdge(atPosition: p) == base.containsEdge(atPosition: p))
        }
        for p in 0 ..< base.vertexPositionBound {
            #expect(graph.containsVertex(atPosition: p) == base.containsVertex(atPosition: p))
        }
        #expect(graph.topologicalSort() != nil && graph.topologicalSort() == base.topologicalSort())
        #expect(graph.topologicalGenerations() == base.topologicalGenerations())
        #expect(graph.lexicographicalTopologicalSort() == base.lexicographicalTopologicalSort())
        #expect(graph.findCycle() == nil && base.findCycle() == nil && graph.isAcyclic)
        #expect(Array(graph.depthFirstSearch()) == Array(base.depthFirstSearch()))
        #expect(graph.weaklyConnectedComponents().map { Array($0) } == base.weaklyConnectedComponents().map { Array($0) })
        #expect(graph.stronglyConnectedComponents().map { Array($0) } == base.stronglyConnectedComponents().map { Array($0) })
        #expect(graph.stronglyConnectedComponents().count == graph.vertexCount)
        #expect(graph.condensation().components.map { Array($0) } == base.condensation().components.map { Array($0) })
        #expect(graph.attractingComponents().map { Array($0) } == base.attractingComponents().map { Array($0) })
        for source in vertices {
            #expect(Array(graph.breadthFirstSearch(from: source)) == Array(base.breadthFirstSearch(from: source)))
            #expect(Array(graph.depthFirstSearch(from: source)) == Array(base.depthFirstSearch(from: source)))
            #expect(graph.breadthFirstLayers(from: source) == base.breadthFirstLayers(from: source))
            #expect(graph.descendants(of: source) == base.descendants(of: source))
            #expect(graph.ancestors(of: source) == base.ancestors(of: source))
            for target in vertices {
                #expect(graph.hasPath(from: source, to: target) == base.hasPath(from: source, to: target))
                #expect(graph.bidirectionalShortestPath(from: source, to: target) == base.bidirectionalShortestPath(from: source, to: target))
            }
        }
    }

    @Test("Traversal's topological queries on the wrapper never answer nil or a cycle")
    func traversalNeverFindsACycle() throws {
        let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 2),
        ]))
        #expect(graph.topologicalSort() == [0, 1, 2])
        #expect(graph.topologicalGenerations() == [[0], [1], [2]])
        #expect(graph.lexicographicalTopologicalSort() == [0, 1, 2])
        #expect(graph.findCycle() == nil && graph.findCycle(from: [2, 1, 0]) == nil && graph.isAcyclic)
        #expect(graph.descendants(of: 0) == [1, 2] && graph.ancestors(of: 2) == [0, 1])
        // The bulk initializer's order is the generations flattened.
        #expect(Array(graph.topologicalOrder) == graph.topologicalGenerations()!.flatMap { $0 })
    }

    @Test("Equality and hashing are the base's: the order is history and does not count")
    func equalityIgnoresTheOrder() throws {
        var a = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1, 2])
        #expect(try a.insert(edge: DirectedEdge(from: 2, to: 0)) == 0)
        #expect(a.remove(edge: DirectedEdge(from: 2, to: 0)) == DirectedEdge(from: 2, to: 0))
        let b = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1, 2])
        #expect(Array(a.topologicalOrder) == [2, 1, 0] && Array(b.topologicalOrder) == [0, 1, 2])
        #expect(a == b && a.hashValue == b.hashValue && Set([a, b]).count == 1)
        // The hash is the base's own.
        #expect(a.hashValue == a.base.hashValue && b.hashValue == b.base.hashValue)
        #expect(a.base == b.base)
        var c = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 1])
        let d = c
        #expect(try c.insert(edge: DirectedEdge(from: 0, to: 1)) == 0)
        #expect(c != d && Set([c, d]).count == 2)
        // A copy is the base's notion: on DirectedPseudograph two copies differ from one.
        let one = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [DirectedEdge(from: 0, to: 1)]))
        let two = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)]))
        #expect(one != two)
        // Stable: equal live vertices and edges, whatever the holes.
        var holes = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [9, 0, 1])
        _ = holes.remove(9)
        let dense = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
        #expect((holes == dense) == (holes.base == dense.base))
    }

    @Test("Descriptions: equal graphs describe alike whatever the order; the debug form also shows the order")
    func descriptions() throws {
        var a = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1])
        #expect(try a.insert(edge: DirectedEdge(from: 1, to: 0)) == 0)
        _ = a.remove(edge: DirectedEdge(from: 1, to: 0))
        let b = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1])
        #expect(a == b)
        #expect(a.description == b.description && !a.description.isEmpty)
        #expect(String(describing: a) == a.description)
        #expect(a.debugDescription != b.debugDescription)
        #expect(String(reflecting: a) == a.debugDescription)
    }

    @Test("Codable round trips keep the order, the vertices and the positions, on every base")
    func codableRoundTrips() throws {
        var dense = DirectedAcyclicGraph<AdjacencyList<String>>(vertices: ["a", "b", "c", "d"])
        #expect(try dense.insert(edge: DirectedEdge(from: "d", to: "a")) == 0)
        #expect(try dense.insert(edge: DirectedEdge(from: "c", to: "d")) == 1)
        _ = dense.remove("b")
        let denseAgain = try JSONDecoder().decode(DirectedAcyclicGraph<AdjacencyList<String>>.self, from: try JSONEncoder().encode(dense))
        #expect(denseAgain == dense && Array(denseAgain.topologicalOrder) == Array(dense.topologicalOrder))
        #expect(Array(denseAgain.topologicalOrder) == ["c", "d", "a"])
        #expect(Array(denseAgain.vertices) == Array(dense.vertices) && Array(denseAgain.edges) == Array(dense.edges))

        var multi = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1, 2])
        #expect(try multi.insert(edge: DirectedEdge(from: 2, to: 1)) == 0)
        #expect(try multi.insert(edge: DirectedEdge(from: 2, to: 1)) == 1)
        #expect(try multi.insert(edge: DirectedEdge(from: 1, to: 0)) == 2)
        let multiAgain = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: try JSONEncoder().encode(multi))
        #expect(multiAgain == multi && Array(multiAgain.topologicalOrder) == [2, 1, 0])
        #expect(Array(multiAgain.edges) == Array(multi.edges))

        var stable = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1, 2, 3])
        #expect(try stable.insert(edge: DirectedEdge(from: 3, to: 0)) == 0)
        #expect(try stable.insert(edge: DirectedEdge(from: 2, to: 3)) == 1)
        #expect(try stable.insert(edge: DirectedEdge(from: 1, to: 2)) == 2)
        _ = stable.remove(edgeAt: 1)
        _ = stable.remove(0)
        let stableAgain = try JSONDecoder().decode(DirectedAcyclicGraph<StableDirectedGraph<Int>>.self, from: try JSONEncoder().encode(stable))
        #expect(stableAgain == stable && Array(stableAgain.topologicalOrder) == Array(stable.topologicalOrder))
        #expect(Array(stableAgain.edges.indices) == [2] && stableAgain.vertexPosition(of: 3) == stable.vertexPosition(of: 3))
        // The decoded value keeps working: an edge against the decoded order reorders.
        var grown = stableAgain
        #expect(try grown.insert(edge: DirectedEdge(from: 3, to: 1)) == 3)
        #expect(Array(grown.topologicalOrder) == [3, 1, 2])
        #expect(throws: AcyclicEdgeError.cycle) { try grown.insert(edge: DirectedEdge(from: 2, to: 3)) }
    }

    @Test("Copy-on-write: mutating a copy leaves the original's base and order alone")
    func copyOnWrite() throws {
        let original = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        var copy = original
        #expect(try copy.insert(edge: DirectedEdge(from: 3, to: 0)) == 2)
        _ = copy.remove(2)
        #expect(Array(original.topologicalOrder) == [0, 1, 2] && Array(original.vertices) == [0, 1, 2])
        #expect(Array(original.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(Array(copy.topologicalOrder) == [3, 0, 1])
        var stable = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
        let snapshot = stable
        #expect(try stable.insert(edge: DirectedEdge(from: 1, to: 0)) == 0)
        stable.removeAll()
        #expect(Array(snapshot.topologicalOrder) == [0, 1] && snapshot.edgeCount == 0 && snapshot.vertexCount == 2)
        // The closure and the reduction are new values.
        var chain = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        let closure = chain.transitiveClosure()
        #expect(try chain.insert(edge: DirectedEdge(from: 2, to: 3)) == 2)
        #expect(closure.edgeCount == 3 && closure.vertexCount == 3)
    }

    @Test("removeAll and removeAllEdges, with and without capacity; reserveCapacity changes nothing")
    func resetsAndCapacity() throws {
        for keep in [false, true] {
            var graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [2, 1, 0], edges: [DirectedEdge(from: 0, to: 1)]))
            #expect(Array(graph.topologicalOrder) == [2, 0, 1])
            graph.reserveCapacity(vertexCount: 100, edgeCount: 100)
            #expect(Array(graph.topologicalOrder) == [2, 0, 1] && graph.edgeCount == 1)
            graph.removeAllEdges(keepingCapacity: keep)
            #expect(Array(graph.topologicalOrder) == [2, 0, 1] && graph.edgeCount == 0 && graph.vertexCount == 3)
            // The kept order still decides: 1 is placed after 0, so 1 -> 0 moves 1.
            #expect(try graph.insert(edge: DirectedEdge(from: 1, to: 0)) == 0)
            #expect(Array(graph.topologicalOrder) == [2, 1, 0])
            graph.removeAll(keepingCapacity: keep)
            #expect(Array(graph.topologicalOrder) == [] as [Int] && graph.vertexCount == 0 && graph.edgeCount == 0)
            #expect(graph == DirectedAcyclicGraph<DirectedPseudograph<Int>>())
            #expect(try graph.insert(edge: DirectedEdge(from: 5, to: 4)) == 0)
            #expect(Array(graph.topologicalOrder) == [5, 4])
        }
        var stable = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [0, 1])
        stable.reserveCapacity(vertexCount: 10, edgeCount: 10)
        stable.removeAll(keepingCapacity: true)
        #expect(stable.vertexCount == 0 && Array(stable.topologicalOrder) == [] as [Int])
        var dense = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [0, 1])
        dense.removeAll()
        #expect(dense.insert(0).inserted && Array(dense.topologicalOrder) == [0])
    }

    @Test("init(_ graph:) from any DirectedGraph is init(vertices:edges:) of its vertices and edges")
    func initFromAnyGraph() throws {
        let source = AdjacencyList<Int>(vertices: [3, 2], edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let multi = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(source))
        #expect(Array(multi.vertices) == [3, 2, 1, 0] && Array(multi.topologicalOrder) == [3, 1, 2, 0])
        #expect(Array(multi.edges) == Array(source.edges))
        let stable = try #require(DirectedAcyclicGraph<StableDirectedGraph<Int>>(source))
        #expect(Array(stable.topologicalOrder) == [3, 1, 2, 0] && stable == DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [3, 2, 1, 0], edges: Array(source.edges)))
        let fromDAG = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(multi))
        #expect(Array(fromDAG.vertices) == [3, 2, 1, 0] && Array(fromDAG.edges) == Array(multi.edges))
        // Its order is Kahn's on the copy, not the source's order.
        var reordered = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1])
        #expect(try reordered.insert(edge: DirectedEdge(from: 1, to: 0)) == 0)
        _ = reordered.remove(edge: DirectedEdge(from: 1, to: 0))
        let copied = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(reordered))
        #expect(Array(reordered.topologicalOrder) == [1, 0] && Array(copied.topologicalOrder) == [0, 1])
        // The same type comes back unchanged, its order included.
        let same = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(reordered))
        #expect(Array(same.topologicalOrder) == [1, 0] && same == reordered)
        // A Base, even when only known to be some DirectedGraph, keeps its storage: here Stable's holes.
        var holes = StableDirectedGraph<Int>(vertices: [5, 6, 7, 8], edges: [DirectedEdge(from: 5, to: 6), DirectedEdge(from: 8, to: 7), DirectedEdge(from: 6, to: 7)])
        _ = holes.remove(5)
        func converted(_ graph: some DirectedGraph<Int>) -> DirectedAcyclicGraph<StableDirectedGraph<Int>>? { DirectedAcyclicGraph(graph) }
        let kept = try #require(converted(holes))
        #expect(Array(kept.vertices.indices) == [1, 2, 3] && Array(kept.edges.indices) == [1, 2])
        #expect(Array(kept.topologicalOrder) == [6, 8, 7] && kept.base == holes)
        let cyclic = AdjacencyList<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(DirectedAcyclicGraph<DirectedPseudograph<Int>>(cyclic) == nil)
        #expect(DirectedAcyclicGraph<StableDirectedGraph<Int>>(cyclic) == nil)
    }

    @Test("topologicalOrder is a random-access collection whose firstIndex(of:) is the vertex's place")
    func orderCollection() throws {
        var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: [4, 3, 2, 1, 0])
        #expect(try graph.insert(edge: DirectedEdge(from: 0, to: 4)) == 0)
        let order = graph.topologicalOrder
        // B = {0} and F = {4} trade places; 3, 2 and 1 stay.
        #expect(Array(order) == [0, 3, 2, 1, 4] && order.count == 5 && order.startIndex == 0 && order.endIndex == 5)
        #expect(order.first == 0 && order.last == 4 && Array(order.reversed()) == [4, 1, 2, 3, 0])
        #expect(Array(order[1 ..< 3]) == [3, 2] && order.index(after: 0) == 1 && order.index(0, offsetBy: 4) == 4)
        for (place, vertex) in order.enumerated() {
            #expect(order.firstIndex(of: vertex) == place && order.contains(vertex))
            #expect(graph.topologicalPosition(of: vertex) == place && order[place] == vertex)
        }
        #expect(order.firstIndex(of: 9) == nil && !order.contains(9))
        // A value: later changes to the graph do not reach it.
        _ = graph.remove(3)
        #expect(Array(order) == [0, 3, 2, 1, 4] && Array(graph.topologicalOrder) == [0, 2, 1, 4])
    }

    @Test("Sendable when the base is; the result builder")
    func sendableAndBuilder() throws {
        let graph = try #require(DirectedAcyclicGraph<AdjacencyList<Int>> {
            3
            DirectedEdge(from: 0, to: 1)
            2
            DirectedEdge(from: 1, to: 2)
        })
        let sendable: any Sendable = graph
        #expect(sendable is DirectedAcyclicGraph<AdjacencyList<Int>>)
        let order: any Sendable = graph.topologicalOrder
        #expect(order is DirectedAcyclicGraph<AdjacencyList<Int>>.TopologicalOrder)
        // Bare vertices first, wherever they are written, then the edges' new endpoints.
        #expect(Array(graph.vertices) == [3, 2, 0, 1] && Array(graph.topologicalOrder) == [3, 0, 1, 2])
        let cyclic = DirectedAcyclicGraph<DirectedPseudograph<Int>> {
            DirectedEdge(from: 0, to: 1)
            DirectedEdge(from: 1, to: 0)
        }
        #expect(cyclic == nil)
    }
}
