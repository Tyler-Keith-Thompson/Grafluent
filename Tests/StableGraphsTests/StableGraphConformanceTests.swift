// Conformances and algorithms. Traversal, Connectivity and ShortestPaths run on graphs with many
// vertex and edge holes (and on the same graphs before any removal, the dense path), and every
// result is compared with the same algorithm on the compacting `DirectedPseudograph(g)`, whose edge
// k is the graph's kth live position. Then the protocol laws with holes, the collections as
// values and as bidirectional collections that skip holes, Codable through JSON and property
// lists, Hashable, Sendable, the builder, the resets, copy-on-write and capacity. See README.md.

import Connectivity
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import ShortestPaths
import StableGraphs
import Testing
import Traversal

@Suite("StableGraphs conformances and algorithms with holes", .tags(.conformance))
struct StableGraphConformanceTests {
    @Test("Algorithms on graphs with many holes agree with the compacted copy, positions mapped", arguments: [1, 2, 3, 4, 5, 6, 7, 8])
    func algorithmsWithManyHoles(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 12 + seed * 5
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< n)
        for _ in 0 ..< n * 4 {
            graph.insert(edge: DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)))
        }
        let dense = graph
        // Remove about half the vertices and then half the remaining edges, then add a few more.
        for v in 0 ..< n where Bool.random(using: &rng) { graph.remove(v) }
        for p in Array(graph.edges.indices) where Bool.random(using: &rng) { graph.remove(edgeAt: p) }
        let live = Array(graph.vertices)
        if !live.isEmpty {
            for _ in 0 ..< n {
                graph.insert(edge: DirectedEdge(from: live.randomElement(using: &rng)!, to: live.randomElement(using: &rng)!))
            }
        }
        graph.insert(n + 1)
        #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
        #expect(graph.edges.endIndex >= 2 * graph.edgeCount || graph.edgeCount < 4)
        for g in [dense, graph] {
            let compacted = DirectedPseudograph<Int>(g)
            let positions = Array(g.edges.indices)
            #expect(Array(compacted.vertices) == Array(g.vertices))
            #expect(compacted.edges.map { $0 } == positions.map { g.edges[$0] })
            #expect(Array(g.weaklyConnectedComponents().map { Array($0) }) == Array(compacted.weaklyConnectedComponents().map { Array($0) }))
            #expect(Array(g.stronglyConnectedComponents().map { Array($0) }) == Array(compacted.stronglyConnectedComponents().map { Array($0) }))
            #expect(Array(g.condensation().components.map { Array($0) }) == Array(compacted.condensation().components.map { Array($0) }))
            #expect(Array(g.condensation().graph.edges) == Array(compacted.condensation().graph.edges))
            #expect(g.attractingComponents().map { Array($0) } == compacted.attractingComponents().map { Array($0) })
            #expect(g.isStronglyConnected == compacted.isStronglyConnected)
            #expect(g.topologicalSort() == compacted.topologicalSort())
            #expect(Array(g.depthFirstSearch()) == Array(compacted.depthFirstSearch()))
            let weight = (0 ..< g.edges.endIndex).map { Int(UInt64($0) &* 2_654_435_761 % 9) + 1 }
            for source in g.vertices {
                #expect(Array(g.breadthFirstSearch(from: source)) == Array(compacted.breadthFirstSearch(from: source)))
                #expect(g.breadthFirstLayers(from: source) == compacted.breadthFirstLayers(from: source))
                #expect(g.descendants(of: source) == compacted.descendants(of: source))
                #expect(g.ancestors(of: source) == compacted.ancestors(of: source))
                let tree = g.dijkstraShortestPaths(from: source) { weight[$0] }
                let copy = compacted.dijkstraShortestPaths(from: source) { weight[positions[$0]] }
                let dominators = g.dominatorTree(root: source), copyDominators = compacted.dominatorTree(root: source)
                let hops = g.shortestPaths(from: source)
                let copyHops = compacted.shortestPaths(from: source)
                for vertex in g.vertices {
                    #expect(tree.distance(to: vertex) == copy.distance(to: vertex))
                    #expect(tree.parentEdge(of: vertex) == copy.parentEdge(of: vertex).map { positions[$0] })
                    #expect(hops.distance(to: vertex) == copyHops.distance(to: vertex))
                    let path = g.bidirectionalShortestPath(from: source, to: vertex)
                    let copyPath = compacted.bidirectionalShortestPath(from: source, to: vertex)
                    #expect(path?.vertices == copyPath?.vertices)
                    #expect(path?.edges == copyPath?.edges.map { positions[$0] })
                    #expect(dominators.immediateDominator(of: vertex) == copyDominators.immediateDominator(of: vertex))
                    #expect(dominators.dominators(of: vertex) == copyDominators.dominators(of: vertex))
                    if let p = tree.parentEdge(of: vertex) {
                        #expect(g.edges.indices.contains(p) && g.target(ofEdgeAt: p) == vertex)
                    }
                }
            }
        }
    }

    @Test("A row whose oldest entries were removed starts at its oldest live position, forwards and backwards")
    func rowStartsAfterRemovingTheOldest() {
        var graph = StableDirectedGraph<Int>()
        for target in [1, 2, 3] { graph.insert(edge: DirectedEdge(from: 0, to: target)) }
        for source in [1, 2, 3] { graph.insert(edge: DirectedEdge(from: source, to: 4)) }
        graph.remove(edgeAt: 0)
        graph.remove(edgeAt: 3)
        #expect(graph.outEdges(of: 0).startIndex == 1)
        #expect(graph.outEdges(of: 0).first == 1)
        #expect(graph.successors(of: 0).first == 2)
        #expect(graph.inEdges(of: 4).startIndex == 4)
        #expect(graph.inEdges(of: 4).first == 4)
        #expect(graph.predecessors(of: 4).first == 2)
        #expect(Array(graph.outEdges(of: 0).indices) == [1, 2])
        #expect(graph.outEdges(of: 0).index(before: graph.outEdges(of: 0).endIndex) == 2)
        graph.remove(edgeAt: 1)
        graph.remove(edgeAt: 2)
        #expect(graph.outEdges(of: 0).startIndex == graph.outEdges(of: 0).endIndex)
        #expect(graph.outEdges(of: 0).first == nil)
    }

    @Test("A DAG with many holes sorts topologically, as its compacted copy does")
    func topologicalSortWithHoles() throws {
        var rng = SeededRandomNumberGenerator(seed: 41)
        let n = 60
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< n)
        for _ in 0 ..< 300 {
            let a = Int.random(in: 0 ..< n, using: &rng), b = Int.random(in: 0 ..< n, using: &rng)
            if a != b { graph.insert(edge: DirectedEdge(from: min(a, b), to: max(a, b))) }
        }
        for v in stride(from: 0, to: n, by: 3) { graph.remove(v) }
        for p in Array(graph.edges.indices) where p.isMultiple(of: 2) { graph.remove(edgeAt: p) }
        #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)
        let order = try #require(graph.topologicalSort())
        #expect(order == DirectedPseudograph<Int>(graph).topologicalSort())
        #expect(Set(order) == Set(graph.vertices) && order.count == graph.vertexCount)
        let rank = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        #expect(graph.edges.allSatisfy { rank[$0.source]! < rank[$0.target]! })
        // The reverse of a live edge closes a cycle.
        let edge = try #require(graph.edges.first)
        graph.insert(edge: DirectedEdge(from: edge.target, to: edge.source))
        #expect(graph.topologicalSort() == nil)
    }

    @Test("The protocol laws hold with holes: rows against edges, degrees, membership, bounds")
    func lawsWithHoles() {
        var graph = StableDirectedGraph<String>(edges: [
            DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "c", to: "a"),
            DirectedEdge(from: "a", to: "a"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "d", to: "a"),
        ])
        graph.remove("b")
        graph.insert(edge: DirectedEdge(from: "e", to: "c"))
        graph.remove(edgeAt: 3)
        func check<G: BidirectionalDirectedGraph<String>>(_ g: G) where G.Edges.Index == Int, G.OutEdges.Element == Int, G.InEdges.Element == Int {
            #expect(g.vertexCount == g.vertices.count && g.edgeCount == g.edges.count)
            #expect(Set(g.vertices).count == g.vertexCount)
            var outSum = 0, inSum = 0
            for v in g.vertices {
                let out = Array(g.outEdges(of: v)), into = Array(g.inEdges(of: v))
                #expect(out == g.edges.indices.filter { g.source(ofEdgeAt: $0) == v })
                #expect(into == g.edges.indices.filter { g.target(ofEdgeAt: $0) == v })
                #expect(Array(g.successors(of: v)) == out.map { g.target(ofEdgeAt: $0) })
                #expect(Array(g.predecessors(of: v)) == into.map { g.source(ofEdgeAt: $0) })
                #expect(g.outDegree(of: v) == out.count && g.inDegree(of: v) == into.count)
                #expect(g.degree(of: v) == out.count + into.count)
                outSum += out.count
                inSum += into.count
            }
            #expect(outSum == g.edgeCount && inSum == g.edgeCount)
            for e in g.edges { #expect(g.contains(edge: e)) }
            #expect(!g.contains("b") && !g.contains(edge: DirectedEdge(from: "a", to: "c")))
            #expect(g.vertexIndexBound == nil && g.edgeIndexBound == nil)
        }
        check(graph)
        #expect(Array(graph.vertices) == ["a", "c", "d", "e"])
        #expect(Array(graph.vertices.indices) == [0, 2, 3, 4])
        #expect(Array(graph.edges.indices) == [2, 5, 6])
    }

    @Test("SparselyIndexedDirectedGraph through generic code: bounds cover every live position, liveness exact, stale positions not live")
    func sparselyIndexed() {
        func positions<G: SparselyIndexedDirectedGraph<Int>>(_ g: G) -> (vertices: [Int], edges: [Int], bounds: [Int]) {
            let vertices = (-2 ..< g.vertexPositionBound + 2).filter { g.containsVertex(atPosition: $0) }
            let edges = (-2 ..< g.edgePositionBound + 2).filter { g.containsEdge(atPosition: $0) }
            #expect(vertices.map { g.vertex(atPosition: $0) } == Array(g.vertices))
            #expect(g.vertices.map { g.vertexPosition(of: $0) } == vertices)
            #expect(edges.count == g.edgeCount && vertices.count == g.vertexCount)
            if let bound = g.vertexIndexBound { #expect(bound == g.vertexPositionBound && vertices == Array(0 ..< bound)) }
            if let bound = g.edgeIndexBound { #expect(bound == g.edgePositionBound && edges == Array(0 ..< bound)) }
            return (vertices, edges, [g.vertexPositionBound, g.edgePositionBound])
        }
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0),
        ])
        #expect(positions(graph) == ([0, 1, 2, 3, 4], [0, 1, 2, 3, 4], [5, 5]))
        graph.remove(2)
        #expect(positions(graph) == ([0, 1, 3, 4], [0, 3, 4], [5, 5]))
        graph.remove(edgeAt: 4)
        graph.insert(2)
        graph.insert(edge: DirectedEdge(from: 2, to: 0))
        #expect(positions(graph) == ([0, 1, 3, 4, 5], [0, 3, 5], [6, 6]))
        #expect(graph.vertexPosition(of: 2) == 5 && graph.vertex(atPosition: 5) == 2)
        // Stale positions stay dead: the removed vertex's old slot and the removed edges.
        #expect(!graph.containsVertex(atPosition: 2) && !graph.containsEdge(atPosition: 1) && !graph.containsEdge(atPosition: 4))
        graph.removeAllEdges()
        #expect(positions(graph) == ([0, 1, 3, 4, 5], [], [6, 0]))
        graph.removeAll()
        #expect(positions(graph) == ([], [], [0, 0]))
    }

    @Test("Vertices and edges are bidirectional collections that skip holes")
    func collectionsSkipHoles() {
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< 6, edges: [
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 1), DirectedEdge(from: 1, to: 1),
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 4, to: 4),
        ])
        for v in [0, 2, 5] { graph.remove(v) }
        graph.remove(edgeAt: 3)
        let vertices = graph.vertices, edges = graph.edges
        #expect(Array(vertices) == [1, 3, 4])
        #expect(Array(vertices.reversed()) == [4, 3, 1])
        #expect(vertices.startIndex == 1 && vertices.endIndex == 6)
        #expect(vertices.index(after: 1) == 3 && vertices.index(before: 6) == 4 && vertices.index(before: 3) == 1)
        #expect(vertices.index(vertices.startIndex, offsetBy: 2) == 4)
        #expect(vertices.distance(from: vertices.startIndex, to: vertices.endIndex) == 3)
        #expect(vertices.count == 3 && !vertices.isEmpty && vertices.first == 1 && vertices.last == 4)
        #expect(vertices.firstIndex(of: 3) == 3 && vertices.firstIndex(of: 0) == nil && vertices.firstIndex(of: 99) == nil)
        #expect(vertices.contains(4) && !vertices.contains(5))
        #expect(Array(vertices.indices) == [1, 3, 4])
        #expect(vertices.indices.count == 3)
        #expect(Array(vertices.indices.reversed()) == [4, 3, 1])
        #expect(vertices.indices.contains(3) && !vertices.indices.contains(2) && !vertices.indices.contains(6) && !vertices.indices.contains(-1))
        #expect(Array(edges.indices) == [0, 1, 2, 5, 7])
        #expect(edges.count == 5 && edges.first == DirectedEdge(from: 1, to: 3) && edges.last == DirectedEdge(from: 4, to: 4))
        #expect(Array(edges.reversed()) == [DirectedEdge(from: 4, to: 4), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 1), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 1, to: 3)])
        #expect(edges.index(after: 2) == 5 && edges.index(before: 5) == 2 && edges.index(edges.startIndex, offsetBy: 4) == 7)
        #expect(edges.distance(from: 1, to: 7) == 3)
        #expect(edges.indices.contains(7) && !edges.indices.contains(3) && !edges.indices.contains(4) && !edges.indices.contains(8))
        #expect(edges.startIndex == 0 && edges.endIndex == 8)
        // Values: later changes to the graph do not reach them.
        graph.insert(edge: DirectedEdge(from: 1, to: 3))
        graph.remove(1)
        #expect(Array(vertices) == [1, 3, 4] && edges.endIndex == 8 && edges.count == 5 && Array(edges.indices) == [0, 1, 2, 5, 7])
        // An empty graph's collections, and one emptied by removals.
        let empty = StableDirectedGraph<Int>()
        #expect(empty.vertices.isEmpty && empty.vertices.startIndex == 0 && empty.vertices.endIndex == 0)
        var emptied = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        emptied.remove(0)
        emptied.remove(1)
        #expect(emptied.vertices.isEmpty && emptied.vertices.startIndex == emptied.vertices.endIndex && emptied.vertices.endIndex == 2)
        #expect(emptied.edges.isEmpty && emptied.edges.startIndex == 1 && emptied.edges.endIndex == 1)
    }

    @Test("Rows: out- and in-edges are collections indexed by position, ending at Int.max; neighbours and copies follow them")
    func rows() {
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 1),
        ])
        graph.remove(edgeAt: 2)
        let out = graph.outEdges(of: 0), into = graph.inEdges(of: 1)
        #expect(Array(out) == [0, 1, 4] && out.count == 3)
        #expect(Array(out.indices) == [0, 1, 4] && out.endIndex == Int.max)
        #expect(out[out.startIndex] == 0 && out.index(after: 1) == 4 && out.index(before: out.endIndex) == 4)
        #expect(Array(out.reversed()) == [4, 1, 0])
        #expect(Array(into) == [0, 4] && into.endIndex == Int.max && Array(into.reversed()) == [4, 0])
        let successors = graph.successors(of: 0), predecessors = graph.predecessors(of: 1)
        #expect(Array(successors) == [1, 2, 1] && successors.count == 3 && Array(successors.reversed()) == [1, 2, 1])
        #expect(Array(predecessors) == [0, 0] && predecessors.count == 2)
        let copies = graph.edges(from: 0, to: 1)
        #expect(Array(copies) == [0, 4])
        #expect(Array(graph.edges(from: 1, to: 0)) == [] as [Int])
        #expect(Array(graph.edges(from: 7, to: 8)) == [] as [Int])
        #expect(graph.edgeCount(from: 0, to: 1) == 2 && graph.edgeCount(from: 9, to: 0) == 0)
        // Values: the views keep what they saw.
        graph.remove(edgeAt: 0)
        graph.insert(edge: DirectedEdge(from: 0, to: 1))
        #expect(Array(out) == [0, 1, 4] && Array(copies) == [0, 4] && Array(successors) == [1, 2, 1])
        #expect(Array(graph.edges(from: 0, to: 1)) == [4, 5])
        let emptyRow = graph.outEdges(of: 1)
        #expect(emptyRow.isEmpty && emptyRow.startIndex == emptyRow.endIndex && emptyRow.count == 0)
    }

    @Test("Codable through JSON and property lists keeps positions and ends, and the next fresh positions")
    func roundTrips() throws {
        var graph = StableDirectedGraph<String>(vertices: ["z"], edges: [
            DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a"), DirectedEdge(from: "b", to: "b"), DirectedEdge(from: "c", to: "a"),
        ])
        graph.remove(edgeAt: 1)
        graph.remove("z")
        graph.remove(edgeAt: 3)
        let viaJSON = try JSONDecoder().decode(StableDirectedGraph<String>.self, from: JSONEncoder().encode(graph))
        let viaPlist = try PropertyListDecoder().decode(StableDirectedGraph<String>.self, from: PropertyListEncoder().encode(graph))
        for var decoded in [viaJSON, viaPlist] {
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == Array(graph.vertices) && Array(decoded.vertices.indices) == Array(graph.vertices.indices))
            #expect(Array(decoded.edges) == Array(graph.edges) && Array(decoded.edges.indices) == Array(graph.edges.indices))
            #expect(decoded.vertices.endIndex == graph.vertices.endIndex && decoded.edges.endIndex == graph.edges.endIndex)
            for v in graph.vertices {
                #expect(Array(decoded.outEdges(of: v)) == Array(graph.outEdges(of: v)))
                #expect(Array(decoded.inEdges(of: v)) == Array(graph.inEdges(of: v)))
            }
            #expect(decoded.vertexIndexBound == nil && decoded.edgeIndexBound == nil)
            #expect(decoded.insert(edge: DirectedEdge(from: "q", to: "a")) == 4)
            #expect(decoded.vertices.firstIndex(of: "q") == 4)
        }
    }

    @Test("Hashable: positions, holes and orders ignored; edge multisets and orientation told apart")
    func hashing() {
        var a = StableDirectedGraph<Int>(vertices: [5, 0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
        a.remove(5)
        a.remove(edgeAt: 0)
        a.insert(edge: DirectedEdge(from: 0, to: 1))
        let b = StableDirectedGraph<Int>(vertices: [2, 1, 0], edges: [DirectedEdge(from: 2, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(a == b && a.hashValue == b.hashValue)
        let others: [StableDirectedGraph<Int>] = [
            StableDirectedGraph(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)]),
            StableDirectedGraph(vertices: [0, 1, 2], edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)]),
            StableDirectedGraph(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)]),
            StableDirectedGraph(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2), DirectedEdge(from: 2, to: 2)]),
            StableDirectedGraph(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 2)]),
        ]
        for other in others { #expect(other != a) }
        #expect(Set(others + [a, b]).count == others.count + 1)
    }

    @Test("Sendable: a graph and its collections cross a Task")
    func sendable() async {
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        graph.remove(edgeAt: 0)
        let copy = graph
        let (vertices, positions) = await Task { (Array(copy.vertices), Array(copy.edges.indices)) }.value
        #expect(vertices == [0, 1, 2] && positions == [1])
    }

    @Test("The builder with control flow, and the generic and pseudograph initializers")
    func builderAndInitializers() {
        let flag = true
        let graph = StableDirectedGraph<Int> {
            9
            DirectedEdge(from: 0, to: 1)
            if flag { DirectedEdge(from: 1, to: 2) } else { DirectedEdge(from: 2, to: 1) }
            for k in 0 ..< 2 { DirectedEdge(from: k, to: k) }
        }
        #expect(Array(graph.vertices) == [9, 0, 1, 2])
        #expect(Array(graph.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 0), DirectedEdge(from: 1, to: 1)])
        #expect(Array(graph.edges.indices) == [0, 1, 2, 3])
        // From another representation: vertices in order, edges at 0..<edgeCount in `edges` order.
        var pseudograph = DirectedPseudograph<Int>(vertices: [4], edges: [DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 3), DirectedEdge(from: 3, to: 4)])
        pseudograph.remove(edgeAt: 0)
        let rebuilt = StableDirectedGraph<Int>(pseudograph)
        #expect(Array(rebuilt.vertices) == Array(pseudograph.vertices))
        #expect(Array(rebuilt.edges) == Array(pseudograph.edges))
        #expect(Array(rebuilt.edges.indices) == Array(0 ..< pseudograph.edgeCount))
        #expect(rebuilt.vertexIndexBound == pseudograph.vertexCount && rebuilt.edgeIndexBound == pseudograph.edgeCount)
    }

    @Test("Resets: removeAll and removeAllEdges, with and without keeping capacity, start positions at 0")
    func resets() {
        for keep in [false, true] {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            graph.remove(0)
            graph.removeAllEdges(keepingCapacity: keep)
            #expect(Array(graph.vertices) == [1, 2] && Array(graph.vertices.indices) == [1, 2] && graph.vertices.endIndex == 3)
            #expect(graph.edges.isEmpty && graph.edges.endIndex == 0 && graph.edgeIndexBound == 0 && graph.vertexIndexBound == nil)
            #expect(graph.outDegree(of: 1) == 0 && graph.inDegree(of: 2) == 0)
            #expect(graph.insert(edge: DirectedEdge(from: 2, to: 1)) == 0)
            graph.removeAll(keepingCapacity: keep)
            #expect(graph == StableDirectedGraph<Int>() && graph.vertices.endIndex == 0 && graph.edges.endIndex == 0)
            #expect(graph.vertexIndexBound == 0 && graph.edgeIndexBound == 0 && !graph.contains(1))
            #expect(graph.insert(edge: DirectedEdge(from: 1, to: 1)) == 0)
            #expect(Array(graph.vertices.indices) == [0])
        }
    }

    @Test("Copy-on-write: every mutation leaves a copy unchanged", .tags(.copyOnWrite))
    func copyOnWrite() {
        var original = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 2)])
        original.remove(edgeAt: 0)
        let snapshot = (Array(original.vertices), Array(original.vertices.indices), Array(original.edges), Array(original.edges.indices),
                        Array(original.outEdges(of: 1)), Array(original.inEdges(of: 2)), original.vertices.endIndex, original.edges.endIndex)
        let mutations: [(inout StableDirectedGraph<Int>) -> Void] = [
            { _ = $0.insert(7) }, { _ = $0.insert(edge: DirectedEdge(from: 2, to: 1)) }, { _ = $0.remove(1) },
            { _ = $0.remove(edge: DirectedEdge(from: 1, to: 2)) }, { _ = $0.remove(edgeAt: 2) }, { _ = $0.removeAllEdges(from: 1, to: 2) },
            { $0.removeAll() }, { $0.removeAll(keepingCapacity: true) }, { $0.removeAllEdges() }, { $0.reserveCapacity(vertexCount: 64, edgeCount: 64) },
        ]
        for mutate in mutations {
            var copy = original
            mutate(&copy)
            #expect(Array(original.vertices) == snapshot.0 && Array(original.vertices.indices) == snapshot.1)
            #expect(Array(original.edges) == snapshot.2 && Array(original.edges.indices) == snapshot.3)
            #expect(Array(original.outEdges(of: 1)) == snapshot.4 && Array(original.inEdges(of: 2)) == snapshot.5)
            #expect(original.vertices.endIndex == snapshot.6 && original.edges.endIndex == snapshot.7)
        }
    }

    @Test("reserveCapacity changes no value or position")
    func capacity() {
        var graph = StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        graph.remove(edgeAt: 0)
        let before = graph
        graph.reserveCapacity(vertexCount: 1_000, edgeCount: 1_000)
        #expect(graph == before && Array(graph.edges.indices) == [1] && graph.edges.endIndex == 2)
        #expect(graph.insert(edge: DirectedEdge(from: 0, to: 0)) == 2)
    }
}
