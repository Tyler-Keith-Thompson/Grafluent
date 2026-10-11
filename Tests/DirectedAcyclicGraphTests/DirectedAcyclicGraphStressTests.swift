// Stress. Long chains on each base: built forward (the fast path), closed by a rejected edge whose
// witness runs the whole chain, and taken apart from the front (each removal trims the order's front).
// An adversarial insert order that forces a reordering of the whole prefix on every insert: reversing
// a chain one edge at a time. A random DAG with a hidden order, its edges inserted in random order
// (Pearce and Kelly's model), checked against the hidden order's reachability. Churn on each base:
// new sources placed first, new targets last, reorderings and removals anywhere, with every place,
// subscript and index checked against the order after each round. Keys across 1024-key pages, with
// pages emptied, dropped and filled again. See README.md.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing
import Traversal
import Walks

@Suite("DirectedAcyclicGraph stress", .tags(.randomized))
struct DirectedAcyclicGraphStressTests {
    @Test("A chain of 20 000 vertices on AdjacencyList: forward inserts, a rejected closing edge, removal from the front")
    func longChainOnAdjacencyList() throws {
        let n = 20_000
        var graph = DirectedAcyclicGraph<AdjacencyList<Int>>()
        for i in 0 ..< n - 1 {
            #expect(graph.insert(edge: DirectedEdge(from: i, to: i + 1)) == i)
        }
        #expect(Array(graph.topologicalOrder) == Array(0 ..< n) && graph.edgeCount == n - 1)
        #expect(graph.insert(edge: DirectedEdge(from: n - 1, to: 0)) == nil)
        #expect(graph.insert(edge: DirectedEdge(from: n / 2, to: n / 4)) == nil)
        let witness = try #require(graph.bidirectionalShortestPath(from: 0, to: n - 1))
        #expect(witness.vertices == Array(0 ..< n) && witness.edges == Array(0 ..< n - 1))
        #expect(graph.hasPath(from: 0, to: n - 1) && !graph.hasPath(from: n - 1, to: 0))
        #expect(graph.edgeCount == n - 1 && Array(graph.topologicalOrder) == Array(0 ..< n))
        // A shortcut is forward and changes nothing in the order.
        #expect(graph.insert(edge: DirectedEdge(from: 0, to: n - 1)) == n - 1)
        #expect(graph.longestPath()?.length == n - 1)
        // Each removal from the front closes a gap at place 0, shifting the whole order.
        let cut = 300
        for i in 0 ..< cut {
            #expect(graph.remove(i) == i)
        }
        #expect(Array(graph.topologicalOrder) == Array(cut ..< n) && graph.edgeCount == n - 1 - cut)
        #expect((cut ..< n).allSatisfy { graph.topologicalPosition(of: $0) == $0 - cut })
    }

    @Test("A chain of 20 000 vertices on DirectedPseudograph, its edges inserted in random order: every insert takes the fast path")
    func longChainOnDirectedPseudograph() throws {
        let n = 20_000
        var rng = SeededRandomNumberGenerator(seed: 7)
        var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< n)
        let links = Array(0 ..< n - 1).shuffled(using: &rng)
        for (k, i) in links.enumerated() {
            #expect(graph.insert(edge: DirectedEdge(from: i, to: i + 1)) == k)
        }
        #expect(Array(graph.topologicalOrder) == Array(0 ..< n))
        #expect(graph.edges.allSatisfy { graph.topologicalPosition(of: $0.source) < graph.topologicalPosition(of: $0.target) })
        #expect(graph.insert(edge: DirectedEdge(from: n - 1, to: 0)) == nil)
        let witness = try #require(graph.bidirectionalShortestPath(from: 0, to: n - 1))
        #expect(witness.length == n - 1 && witness.vertices == Array(0 ..< n))
        #expect(witness.edges.indices.allSatisfy { graph.source(ofEdgeAt: witness.edges[$0]) == $0 && graph.target(ofEdgeAt: witness.edges[$0]) == $0 + 1 })
        // Parallel copies along the chain are accepted and keep the order.
        for i in stride(from: 0, to: n - 1, by: 100) {
            #expect(graph.insert(edge: DirectedEdge(from: i, to: i + 1)) != nil)
        }
        #expect(Array(graph.topologicalOrder) == Array(0 ..< n) && graph.edgeCount == n - 1 + (n - 1 + 99) / 100)
        #expect(graph.longestPath()?.length == n - 1)
    }

    @Test("A chain of 20 000 vertices on StableDirectedGraph with holes from removed edges and vertices")
    func longChainOnStableDirectedGraph() throws {
        let n = 20_000
        var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: 0 ..< n)
        for i in 0 ..< n - 1 {
            #expect(graph.insert(edge: DirectedEdge(from: i, to: i + 1)) == i)
        }
        // Cut the chain in the middle, then join its halves the other way round.
        #expect(graph.remove(edgeAt: n / 2 - 1) == DirectedEdge(from: n / 2 - 1, to: n / 2))
        #expect(graph.insert(edge: DirectedEdge(from: n - 1, to: 0)) == n - 1)
        let expected = Array(n / 2 ..< n) + Array(0 ..< n / 2)
        #expect(Array(graph.topologicalOrder) == expected)
        #expect(graph.insert(edge: DirectedEdge(from: n / 2 - 1, to: n / 2)) == nil)
        let witness = try #require(graph.bidirectionalShortestPath(from: n / 2, to: n / 2 - 1))
        #expect(witness.length == n - 1)
        #expect(witness.edges.indices.allSatisfy { graph.source(ofEdgeAt: witness.edges[$0]) == witness.vertices[$0] && graph.target(ofEdgeAt: witness.edges[$0]) == witness.vertices[$0 + 1] })
        for v in stride(from: 0, to: n, by: 97) { _ = graph.remove(v) }
        let remaining = expected.filter { !$0.isMultiple(of: 97) }
        #expect(Array(graph.topologicalOrder) == remaining)
        #expect(graph.edges.allSatisfy { graph.topologicalPosition(of: $0.source) < graph.topologicalPosition(of: $0.target) })
    }

    @Test("Adversarial: reversing a chain one edge at a time moves the whole prefix on every insert")
    func reverseChain() {
        let n = 1_000
        for base in 0 ..< 3 {
            let result: [Int]
            switch base {
            case 0:
                var graph = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< n)
                for i in 1 ..< n {
                    #expect(graph.insert(edge: DirectedEdge(from: i, to: i - 1)) == i - 1)
                    // After i -> i-1 the order begins i, i-1, ..., 0.
                    #expect(graph.topologicalOrder[0] == i && graph.topologicalOrder[i] == 0)
                }
                #expect(graph.insert(edge: DirectedEdge(from: 0, to: n - 1)) == nil)
                result = Array(graph.topologicalOrder)
            case 1:
                var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< n)
                for i in 1 ..< n {
                    #expect(graph.insert(edge: DirectedEdge(from: i, to: i - 1)) == i - 1)
                    #expect(graph.topologicalOrder[0] == i && graph.topologicalOrder[i] == 0)
                }
                #expect(graph.insert(edge: DirectedEdge(from: 0, to: n - 1)) == nil)
                result = Array(graph.topologicalOrder)
            default:
                var graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: 0 ..< n)
                for i in 1 ..< n {
                    #expect(graph.insert(edge: DirectedEdge(from: i, to: i - 1)) == i - 1)
                    #expect(graph.topologicalOrder[0] == i && graph.topologicalOrder[i] == 0)
                }
                #expect(graph.insert(edge: DirectedEdge(from: 0, to: n - 1)) == nil)
                result = Array(graph.topologicalOrder)
            }
            #expect(result == Array((0 ..< n).reversed()), "base \(base)")
        }
    }

    @Test("Pearce and Kelly's model: a random DAG with a hidden order, its edges inserted in random order", arguments: [1, 2, 3])
    func hiddenOrder(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 2_000, m = 8_000
        let rank = Array(0 ..< n).shuffled(using: &rng)
        var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< n)
        var accepted = 0
        for _ in 0 ..< m {
            var u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
            if u == v { continue }
            if rank[u] > rank[v] { swap(&u, &v) }
            // Every edge goes up the hidden order, so none is rejected.
            #expect(graph.insert(edge: DirectedEdge(from: u, to: v)) != nil)
            accepted += 1
        }
        #expect(graph.edgeCount == accepted)
        #expect(graph.edges.allSatisfy { graph.topologicalPosition(of: $0.source) < graph.topologicalPosition(of: $0.target) })
        #expect(Set(graph.topologicalOrder) == Set(0 ..< n) && graph.topologicalOrder.count == n)
        // Against the hidden order: an edge down it is rejected exactly when the target reaches the source.
        var rejected = 0
        for _ in 0 ..< 300 {
            let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
            guard rank[u] > rank[v] else { continue }
            let closes = graph.base.hasPath(from: v, to: u)
            let result = graph.insert(edge: DirectedEdge(from: u, to: v))
            #expect((result == nil) == closes)
            if result == nil { rejected += 1 }
            #expect(graph.hasPath(from: u, to: v) == graph.base.hasPath(from: u, to: v))
            #expect(graph.hasPath(from: v, to: u) == graph.base.hasPath(from: v, to: u))
        }
        #expect(rejected > 0)
        #expect(graph.edges.allSatisfy { graph.topologicalPosition(of: $0.source) < graph.topologicalPosition(of: $0.target) })
        // A tenth of the vertices removed: the order keeps its relative order.
        let before = Array(graph.topologicalOrder)
        for v in 0 ..< n where v.isMultiple(of: 10) { _ = graph.remove(v) }
        #expect(Array(graph.topologicalOrder) == before.filter { !$0.isMultiple(of: 10) })
        #expect(graph.edges.allSatisfy { graph.topologicalPosition(of: $0.source) < graph.topologicalPosition(of: $0.target) })
    }

    @Test("Churn: new sources first, new targets last, reorderings and removals; every place agrees with the order", arguments: [1, 2, 3])
    func churn(seed: Int) {
        func run<Base: MutableDirectedGraph<Int>>(_ graph: inout DirectedAcyclicGraph<Base>, _ rng: inout SeededRandomNumberGenerator, _ context: String) {
            var next = 0
            var live: [Int] = []
            for round in 0 ..< 40 {
                for _ in 0 ..< 150 {
                    let roll = Int.random(in: 0 ..< 10, using: &rng)
                    if roll < 3 || live.count < 2 {
                        // A new source to an old vertex (placed first), or a new target (last).
                        let old = live.isEmpty ? nil : live.randomElement(using: &rng)
                        let new = next
                        next += 1
                        if let old {
                            let edge = roll.isMultiple(of: 2) ? DirectedEdge(from: new, to: old) : DirectedEdge(from: old, to: new)
                            #expect(graph.insert(edge: edge) != nil, "\(context)")
                            if edge.source == new { #expect(graph.topologicalPosition(of: new) == 0, "\(context)") }
                            else { #expect(graph.topologicalPosition(of: new) == graph.vertexCount - 1, "\(context)") }
                        } else {
                            graph.insert(new)
                        }
                        live.append(new)
                    } else if roll < 7 {
                        let u = live.randomElement(using: &rng)!, v = live.randomElement(using: &rng)!
                        let closes = u == v || graph.base.hasPath(from: v, to: u)
                        #expect((graph.insert(edge: DirectedEdge(from: u, to: v)) == nil) == closes, "\(context)")
                    } else {
                        let k = Int.random(in: 0 ..< live.count, using: &rng)
                        #expect(graph.remove(live[k]) == live[k], "\(context)")
                        live.swapAt(k, live.count - 1)
                        live.removeLast()
                    }
                }
                let order = Array(graph.topologicalOrder)
                #expect(order.count == live.count && Set(order) == Set(live), "round \(round) \(context)")
                #expect(order.indices.allSatisfy { graph.topologicalPosition(of: order[$0]) == $0 && graph.topologicalOrder[$0] == order[$0] && graph.topologicalOrder.firstIndex(of: order[$0]) == $0 }, "round \(round) \(context)")
                #expect(graph.edges.allSatisfy { graph.topologicalPosition(of: $0.source) < graph.topologicalPosition(of: $0.target) }, "round \(round) \(context)")
            }
        }
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        var list = DirectedAcyclicGraph<AdjacencyList<Int>>()
        run(&list, &rng, "AdjacencyList")
        var pseudograph = DirectedAcyclicGraph<DirectedPseudograph<Int>>()
        run(&pseudograph, &rng, "DirectedPseudograph")
        var stable = DirectedAcyclicGraph<StableDirectedGraph<Int>>()
        run(&stable, &rng, "StableDirectedGraph")
    }

    @Test("Keys across 1024-key pages: emptied pages freed and reused, the first page dropped, removeAll after it")
    func keysAcrossPages() throws {
        // StableDirectedGraph: positions are never reused. Emptying the first page drops it; the
        // next two pages need two blocks, and must not share the freed one.
        var stable = DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: 0 ..< 2048)
        for v in 0 ..< 1024 { _ = stable.remove(v) }
        for v in 2048 ..< 4096 { stable.insert(v) }
        // One backward edge per page, so Pearce–Kelly reads the labels of each.
        #expect(stable.insert(edge: DirectedEdge(from: 4095, to: 1024)) != nil)
        #expect(stable.insert(edge: DirectedEdge(from: 3000, to: 2100)) != nil)
        var order = Array(stable.topologicalOrder)
        #expect(order.count == 3072 && Set(order) == Set(1024 ..< 4096))
        #expect(order.indices.allSatisfy { stable.topologicalPosition(of: order[$0]) == $0 && stable.topologicalOrder[$0] == order[$0] })
        #expect(stable.topologicalPosition(of: 4095) < stable.topologicalPosition(of: 1024))
        #expect(stable.topologicalPosition(of: 3000) < stable.topologicalPosition(of: 2100))
        // Positions start again at 0 after removeAll.
        stable.removeAll()
        #expect(stable.insert(edge: DirectedEdge(from: 1, to: 0)) == 0)
        #expect(Array(stable.topologicalOrder) == [1, 0] && stable.topologicalPosition(of: 0) == 1)

        // AdjacencyList: keys are dense. Removing the last 2000 vertices empties two pages; growing
        // past them again fills those two and a third, each with its own block.
        var dense = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3000)
        for v in (1000 ..< 3000).reversed() { _ = dense.remove(v) }
        for v in 3000 ..< 6500 { dense.insert(v) }
        #expect(dense.insert(edge: DirectedEdge(from: 6499, to: 0)) != nil)
        #expect(dense.insert(edge: DirectedEdge(from: 5000, to: 3500)) != nil)
        order = Array(dense.topologicalOrder)
        #expect(order.count == 4500 && Set(order) == Set(0 ..< 1000).union(3000 ..< 6500))
        #expect(order.indices.allSatisfy { dense.topologicalPosition(of: order[$0]) == $0 })
        #expect(dense.topologicalPosition(of: 6499) < dense.topologicalPosition(of: 0))
        #expect(dense.topologicalPosition(of: 5000) < dense.topologicalPosition(of: 3500))
    }
}
