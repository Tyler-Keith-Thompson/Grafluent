// Results on an adjacency list whose slots have moved, post-dominators on random graphs against a
// brute-force reference, and dominance queries that must be false on deep graphs. Added after the
// critical review; case IDs (CN-nn) continue the catalog, see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing

/// Supplies DirectedGraph and BidirectionalDirectedGraph without vertex indices, so algorithms
/// use dictionaries.
private struct BidirectionalDictionaryGraph<Vertex: Hashable>: BidirectionalDirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func predecessors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.target == vertex }.map(\.source) }
    func inEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].target == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Connectivity against references")
struct ConnectivityReferenceTests {
    @Test("CN-144 an adjacency list after removals gives exactly the results of the same vertices and successors in a multigraph", arguments: [1, 2, 3, 4, 5, 6])
    func adjacencyListAfterRemovals(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 1_440)
        let n = 24
        var edges: [DirectedEdge<Int>] = []
        for _ in 0 ..< 60 {
            edges.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator)))
        }
        var list = AdjacencyList(vertices: 0 ..< n, edges: edges)
        // Removals move other vertices into the freed slots.
        for v in [3, 0, 17, 11] { _ = list.remove(v) }
        for _ in 0 ..< 10 {
            let edge = DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator))
            _ = list.remove(edge: edge)
        }
        // The same graph, written in the adjacency list's own vertex and successor order.
        let order = Array(list.vertices)
        let written = order.flatMap { u in list.successors(of: u).map { DirectedEdge(from: u, to: $0) } }
        let multigraph = Multigraph(vertices: order, edges: written)
        #expect(list.stronglyConnectedComponents().map(Array.init) == multigraph.stronglyConnectedComponents().map(Array.init))
        #expect(list.weaklyConnectedComponents().map(Array.init) == multigraph.weaklyConnectedComponents().map(Array.init))
        #expect(list.condensation().graph == multigraph.condensation().graph)
        #expect(list.attractingComponents().map(Array.init) == multigraph.attractingComponents().map(Array.init))
        #expect(list.isStronglyConnected == multigraph.isStronglyConnected)
        #expect(list.isWeaklyConnected == multigraph.isWeaklyConnected)
        for v in order {
            #expect(list.stronglyConnectedComponents().component(of: v) == multigraph.stronglyConnectedComponents().component(of: v))
        }
        for root in order.prefix(4) {
            let tree = list.dominatorTree(root: root)
            let expected = multigraph.dominatorTree(root: root)
            let frontiers = list.dominanceFrontiers(root: root)
            let expectedFrontiers = multigraph.dominanceFrontiers(root: root)
            for v in order {
                #expect(tree.immediateDominator(of: v) == expected.immediateDominator(of: v))
                #expect(Array(tree.children(of: v)) == Array(expected.children(of: v)))
                #expect(frontiers[v].map(Array.init) == expectedFrontiers[v].map(Array.init))
            }
            let post = list.postDominatorTree(exit: root)
            let expectedPost = multigraph.postDominatorTree(exit: root)
            for v in order {
                #expect(post.immediateDominator(of: v) == expectedPost.immediateDominator(of: v))
            }
        }
    }

    @Test("CN-145 post-dominators match brute force, with and without vertex indices, on spread-out vertices", .tags(.randomized), arguments: [1, 2, 3, 4, 5, 6, 7, 8])
    func postDominatorsByBruteForce(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 1_450)
        for n in [1, 2, 5, 12] {
            var pairs: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 3 * n, using: &generator) {
                pairs.append((Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator)))
            }
            let vertices = (0 ..< n).map { $0 * 5 - 7 }
            let edges = pairs.map { DirectedEdge(from: $0.0 * 5 - 7, to: $0.1 * 5 - 7) }
            // Brute force: u post-dominates v when v reaches the exit, and every path from v to
            // the exit passes through u (v reaches the exit only through u).
            func reachesExit(from v: Int, exit: Int, avoiding blocked: Int?) -> Bool {
                if v == blocked { return false }
                var seen: Set<Int> = [v]
                var stack = [v]
                while let u = stack.popLast() {
                    if u == exit { return true }
                    for e in edges where e.source == u && e.target != blocked && !seen.contains(e.target) {
                        seen.insert(e.target)
                        stack.append(e.target)
                    }
                }
                return false
            }
            let indexed = AdjacencyList(vertices: vertices, edges: edges)
            let unindexed = BidirectionalDictionaryGraph(vertices: vertices, edges: edges)
            for exit in vertices {
                let indexedTree = indexed.postDominatorTree(exit: exit)
                let unindexedTree = unindexed.postDominatorTree(exit: exit)
                let trees: [(String, [Int: [Int]?])] = [
                    ("indexed", Dictionary(uniqueKeysWithValues: vertices.map { ($0, indexedTree.dominators(of: $0)) })),
                    ("unindexed", Dictionary(uniqueKeysWithValues: vertices.map { ($0, unindexedTree.dominators(of: $0)) })),
                ]
                for v in vertices {
                    let expected: Set<Int>? = reachesExit(from: v, exit: exit, avoiding: nil)
                        ? Set(vertices.filter { u in u == v || u == exit || !reachesExit(from: v, exit: exit, avoiding: u) })
                        : nil
                    for (name, dominators) in trees {
                        #expect(dominators[v]!.map(Set.init) == expected, "\(name), n \(n), exit \(exit), vertex \(v)")
                    }
                }
            }
        }
    }

    @Test("CN-146 dominates is false up the tree and across branches on deep graphs")
    func deepDominatesIsFalse() async {
        await Task {
            let n = 100_000
            let path = CompressedSparseRow(vertexCount: n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) })
            let tree = path.dominatorTree(root: 0)
            #expect(tree.dominates(0, n - 1))
            #expect(tree.dominates(n / 2, n - 1))
            #expect(!tree.dominates(n - 1, 0))
            #expect(!tree.dominates(n - 1, n / 2))
            #expect(!tree.dominates(n / 2 + 1, n / 2))
            // A lasso, 0 → 1 → … → n − 1 → 1: 1 dominates everything after it, not 0.
            let lasso = CompressedSparseRow(vertexCount: n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) } + [DirectedEdge(from: n - 1, to: 1)])
            let lassoTree = lasso.dominatorTree(root: 0)
            #expect(lassoTree.dominates(1, n - 1))
            #expect(!lassoTree.dominates(1, 0))
            #expect(!lassoTree.dominates(n - 1, 1))
            // Two branches from 0: neither side dominates the other.
            let fork = CompressedSparseRow(vertexCount: 2 * n + 1, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: n + 1)]
                + (1 ..< n).map { DirectedEdge(from: $0, to: $0 + 1) } + (n + 1 ..< 2 * n).map { DirectedEdge(from: $0, to: $0 + 1) })
            let forkTree = fork.dominatorTree(root: 0)
            #expect(forkTree.dominates(1, n))
            #expect(!forkTree.dominates(1, 2 * n))
            #expect(!forkTree.dominates(n + 1, n))
            #expect(forkTree.dominates(0, 2 * n))
        }.value
    }
}
