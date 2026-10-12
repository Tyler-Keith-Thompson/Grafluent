// The `checked:` lookups of the results (README Principle 6), `Arborescence(checked:)` and
// `Forest(_: ShortestPathTree)`. Each lookup throws `VertexNotFound` where its plain spelling
// traps, and otherwise returns the plain spelling's value, a nil included (an unreached vertex, a
// source). The graphs cover the three ways a result finds a vertex's index: the graph's own vertex
// indices (`CompressedSparseRow`, `ReferenceDirectedMultigraph`), a numbered sparse graph with a
// hole (`StableDirectedGraph` after a removal), and a dictionary for a graph with no indices.
// Case IDs (SP-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Semirings
import ShortestPaths
import StableGraphs
import Testing
import Trees

/// A directed graph with no vertex indices, so a result looks its vertices up in a dictionary.
private struct UnindexedDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("checked: lookups on shortest-path results")
struct ShortestPathCheckedLookupTests {
    @Test("SP-146 ShortestPathTree's checked lookups match the plain ones on every vertex, nil for the source and the unreached vertex; indexed Int vertices")
    func treeIndexed() throws {
        // 0 → 1, 0 → 2, 2 → 3, 1 → 3; 4 → 0, so 4 is unreached from 0.
        let graph = CompressedSparseRow(vertexCount: 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 4, to: 0),
        ])
        let tree = graph.shortestPaths(from: 0)
        for v in 0 ..< 5 {
            #expect(try tree.distance(checkedTo: v) == tree.distance(to: v))
            #expect(try tree.hasPath(checkedTo: v) == tree.hasPath(to: v))
            #expect(try tree.parent(checked: v) == tree.parent(of: v))
            #expect(try tree.parentEdge(checked: v) == tree.parentEdge(of: v))
            #expect(try tree.path(checkedTo: v)?.vertices == tree.path(to: v)?.vertices)
            #expect(try tree.path(checkedTo: v)?.edges == tree.path(to: v)?.edges)
        }
        #expect(try tree.distance(checkedTo: 3) == 2)
        #expect(try tree.distance(checkedTo: 4) == nil)
        #expect(try tree.hasPath(checkedTo: 4) == false)
        #expect(try tree.hasPath(checkedTo: 0) == true)
        #expect(try tree.parent(checked: 0) == nil)
        #expect(try tree.parent(checked: 2) == 0)
        #expect(try tree.parentEdge(checked: 0) == nil)
        #expect(try tree.parentEdge(checked: 4) == nil)
        #expect(try tree.parentEdge(checked: 2) != nil)
        #expect(try tree.path(checkedTo: 0)?.vertices == [0])
        #expect(try tree.path(checkedTo: 4) == nil)
        #expect(try tree.path(checkedTo: 3)?.vertices.count == 3)
        for missing in [5, -1, 99] {
            #expect(throws: VertexNotFound()) { try tree.distance(checkedTo: missing) }
            #expect(throws: VertexNotFound()) { try tree.hasPath(checkedTo: missing) }
            #expect(throws: VertexNotFound()) { try tree.parent(checked: missing) }
            #expect(throws: VertexNotFound()) { try tree.parentEdge(checked: missing) }
            #expect(throws: VertexNotFound()) { try tree.path(checkedTo: missing) }
        }
    }

    @Test("SP-147 ShortestPathTree's checked lookups on String vertices: indexed, unindexed, and a numbered graph with a removed vertex")
    func treeOtherLookups() throws {
        let arcs = [DirectedEdge(from: "s", to: "a"), DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "s", to: "c"), DirectedEdge(from: "d", to: "s")]
        let names = ["s", "a", "b", "c", "d"]

        let indexed = ReferenceDirectedMultigraph(vertices: names, edges: arcs)
        let indexedTree = indexed.shortestPaths(from: "s")
        for v in names {
            #expect(try indexedTree.distance(checkedTo: v) == indexedTree.distance(to: v))
            #expect(try indexedTree.parent(checked: v) == indexedTree.parent(of: v))
            #expect(try indexedTree.path(checkedTo: v)?.vertices == indexedTree.path(to: v)?.vertices)
        }
        #expect(try indexedTree.distance(checkedTo: "b") == 2)
        #expect(try indexedTree.distance(checkedTo: "d") == nil)
        #expect(throws: VertexNotFound()) { try indexedTree.distance(checkedTo: "z") }
        #expect(throws: VertexNotFound()) { try indexedTree.path(checkedTo: "z") }

        let unindexed = UnindexedDigraph(vertices: names, edges: arcs)
        let unindexedTree = unindexed.shortestPaths(from: "s")
        for v in names {
            #expect(try unindexedTree.distance(checkedTo: v) == unindexedTree.distance(to: v))
            #expect(try unindexedTree.hasPath(checkedTo: v) == unindexedTree.hasPath(to: v))
            #expect(try unindexedTree.parent(checked: v) == unindexedTree.parent(of: v))
            #expect(try unindexedTree.parentEdge(checked: v) == unindexedTree.parentEdge(of: v))
        }
        #expect(try unindexedTree.parent(checked: "b") == "a")
        #expect(throws: VertexNotFound()) { try unindexedTree.parent(checked: "z") }
        #expect(throws: VertexNotFound()) { try unindexedTree.hasPath(checkedTo: "z") }

        var stable = StableDirectedGraph(vertices: names + ["gone"], edges: arcs + [DirectedEdge(from: "s", to: "gone")])
        _ = stable.remove("gone")
        let stableTree = stable.shortestPaths(from: "s")
        for v in names {
            #expect(try stableTree.distance(checkedTo: v) == stableTree.distance(to: v))
            #expect(try stableTree.parentEdge(checked: v) == stableTree.parentEdge(of: v))
            #expect(try stableTree.path(checkedTo: v)?.vertices == stableTree.path(to: v)?.vertices)
        }
        #expect(try stableTree.distance(checkedTo: "c") == 1)
        #expect(throws: VertexNotFound()) { try stableTree.distance(checkedTo: "gone") }
        #expect(throws: VertexNotFound()) { try stableTree.parentEdge(checked: "gone") }
    }

    @Test("SP-148 DistanceMatrix's checked lookups match the plain ones on every pair, and throw when either end is missing")
    func matrix() throws {
        // 0 → 1 (2), 1 → 2 (3), 0 → 2 (9); 3 reaches nothing and nothing reaches it.
        let arcs = [(0, 1, 2), (1, 2, 3), (0, 2, 9)]
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let matrix = try #require(graph.floydWarshallShortestPaths { arcs[$0].2 })
        for u in 0 ..< 4 {
            for v in 0 ..< 4 {
                #expect(try matrix.distance(checkedFrom: u, to: v) == matrix.distance(from: u, to: v))
                #expect(try matrix.hasPath(checkedFrom: u, to: v) == matrix.hasPath(from: u, to: v))
                #expect(try matrix.path(checkedFrom: u, to: v)?.vertices == matrix.path(from: u, to: v)?.vertices)
                #expect(try matrix.path(checkedFrom: u, to: v)?.edges == matrix.path(from: u, to: v)?.edges)
            }
        }
        #expect(try matrix.distance(checkedFrom: 0, to: 2) == 5)
        #expect(try matrix.distance(checkedFrom: 2, to: 0) == nil)
        #expect(try matrix.distance(checkedFrom: 3, to: 3) == 0)
        #expect(try matrix.hasPath(checkedFrom: 0, to: 3) == false)
        #expect(try matrix.hasPath(checkedFrom: 3, to: 3) == true)
        #expect(try matrix.path(checkedFrom: 0, to: 2)?.vertices == [0, 1, 2])
        #expect(try matrix.path(checkedFrom: 1, to: 1)?.vertices == [1])
        #expect(try matrix.path(checkedFrom: 2, to: 0) == nil)
        for (u, v) in [(4, 0), (0, 4), (-1, 1), (1, -1), (7, 8)] {
            #expect(throws: VertexNotFound()) { try matrix.distance(checkedFrom: u, to: v) }
            #expect(throws: VertexNotFound()) { try matrix.hasPath(checkedFrom: u, to: v) }
            #expect(throws: VertexNotFound()) { try matrix.path(checkedFrom: u, to: v) }
        }
    }

    @Test("SP-149 DistanceMatrix's checked lookups on a graph with no vertex indices")
    func matrixUnindexed() throws {
        let graph = UnindexedDigraph(vertices: ["a", "b", "c"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c")])
        let matrix = try #require(graph.floydWarshallShortestPaths { _ in 1 })
        #expect(try matrix.distance(checkedFrom: "a", to: "c") == 2)
        #expect(try matrix.hasPath(checkedFrom: "c", to: "a") == false)
        #expect(try matrix.path(checkedFrom: "a", to: "c")?.vertices == ["a", "b", "c"])
        #expect(throws: VertexNotFound()) { try matrix.distance(checkedFrom: "a", to: "z") }
        #expect(throws: VertexNotFound()) { try matrix.hasPath(checkedFrom: "z", to: "a") }
        #expect(throws: VertexNotFound()) { try matrix.path(checkedFrom: "z", to: "z") }
    }

    @Test("SP-150 ShortestDistances.distance(checkedTo:) matches distance(to:), .zero when unreached, and throws for a missing vertex")
    func semiringDistances() throws {
        // Path counts: 0 → 1, 0 → 2, 1 → 3, 2 → 3, so two paths reach 3; 4 is unreached.
        let graph = CompressedSparseRow(vertexCount: 5, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
        ])
        let distances = try #require(graph.dagShortestDistances(from: 0) { _ in CountingSemiring(1) })
        for v in 0 ..< 5 { #expect(try distances.distance(checkedTo: v) == distances.distance(to: v)) }
        #expect(try distances.distance(checkedTo: 3) == CountingSemiring(2))
        #expect(try distances.distance(checkedTo: 4) == .zero)
        #expect(throws: VertexNotFound()) { try distances.distance(checkedTo: 5) }
        #expect(throws: VertexNotFound()) { try distances.distance(checkedTo: -1) }

        let unindexed = UnindexedDigraph(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let named = try #require(unindexed.dagShortestDistances(from: "a") { _ in CountingSemiring(1) })
        #expect(try named.distance(checkedTo: "b") == CountingSemiring(1))
        #expect(throws: VertexNotFound()) { try named.distance(checkedTo: "z") }
    }

    @Test("SP-151 Arborescence(checked:) is Arborescence(_:) from one source and throws NotATree from two")
    func checkedArborescence() throws {
        let graph = AdjacencyList(vertices: 0 ..< 6, edges: [DirectedEdge(from: 3, to: 0), DirectedEdge(from: 3, to: 5), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 5, to: 4)])
        let one = graph.shortestPaths(from: 3)
        let checked = try Arborescence(checked: one)
        #expect(checked == Arborescence(one))
        #expect(checked.root == 3)
        #expect(Array(checked.vertices) == [0, 1, 3, 4, 5])
        #expect(throws: NotATree()) { try Arborescence(checked: graph.shortestPaths(from: [3, 2])) }
        // Repeated sources are one source.
        #expect(try Arborescence(checked: graph.shortestPaths(from: [3, 3])).root == 3)
        let named = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: "r", to: "x"), DirectedEdge(from: "y", to: "x")])
        #expect(throws: NotATree()) { try Arborescence(checked: named.shortestPaths(from: ["r", "y"])) }
        #expect((try? Arborescence(checked: named.shortestPaths(from: ["r", "y"]))) == nil)
        #expect(try Arborescence(checked: named.shortestPaths(from: "r")).root == "r")
    }

    @Test("SP-152 Forest(_:) of a one-source tree: the reached vertices in index order, edge k to the k-th non-root vertex")
    func forestOneSource() throws {
        let graph = AdjacencyList(vertices: 0 ..< 6, edges: [DirectedEdge(from: 3, to: 0), DirectedEdge(from: 3, to: 5), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 5, to: 4)])
        let tree = graph.shortestPaths(from: 3)
        let forest = Forest(tree)
        #expect(Array(forest.vertices) == [0, 1, 3, 4, 5])
        #expect(Array(forest.edges) == [UndirectedEdge(3, 0), UndirectedEdge(0, 1), UndirectedEdge(5, 4), UndirectedEdge(3, 5)])
        #expect(forest.trees.count == 1)
        // Each edge is stored (parent, child), which `==` alone does not see.
        #expect(forest.edges.map(\.u) == [3, 0, 5, 3])
        #expect(forest.edges.map(\.v) == [0, 1, 4, 5])
        // The arborescence's edges, undirected.
        let arborescence = Arborescence(tree)
        #expect(Array(forest.edges) == arborescence.edges.map { UndirectedEdge($0.source, $0.target) })
        #expect(!forest.contains(2))
    }

    @Test("SP-153 Forest(_:) of a two-source tree: one tree per source, String vertices past the small-tree limit")
    func forestTwoSources() throws {
        // Two stars: r → a1…a5 and q → b1…b4, plus an unreached vertex z → r.
        let leftLeaves = (1 ... 5).map { "a\($0)" }, rightLeaves = (1 ... 4).map { "b\($0)" }
        let arcs = leftLeaves.map { DirectedEdge(from: "r", to: $0) } + rightLeaves.map { DirectedEdge(from: "q", to: $0) } + [DirectedEdge(from: "z", to: "r")]
        let graph = ReferenceDirectedMultigraph(edges: arcs)
        let tree = graph.shortestPaths(from: ["r", "q"])
        let forest = Forest(tree)
        let reached = graph.vertices.filter { $0 != "z" }
        #expect(Array(forest.vertices) == Array(reached))
        #expect(forest.vertexCount == 11)
        #expect(forest.edgeCount == 9)
        #expect(forest.trees.count == 2)
        let nonRoots = reached.filter { $0 != "r" && $0 != "q" }
        for (k, v) in nonRoots.enumerated() {
            #expect(forest.edges[k] == UndirectedEdge(tree.parent(of: v)!, v))
        }
        #expect(forest.component(of: "a3") == forest.component(of: "r"))
        #expect(forest.component(of: "b2") != forest.component(of: "r"))
        #expect(forest.path(from: "a1", to: "a2")?.vertices == ["a1", "r", "a2"])
        #expect(forest.path(from: "a1", to: "b1") == nil)
        #expect(!forest.contains("z"))
    }

    @Test("SP-154 Forest(_:) when Bellman–Ford improves one source from another: that source gets a parent, one tree")
    func forestImprovedSource() throws {
        // s → t (-2): the source t is reached from the source s by a negative path.
        let arcs = [(0, 1, -2), (1, 2, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let tree = try #require(graph.bellmanFordShortestPaths(from: [0, 1]) { arcs[$0].2 })
        #expect(tree.parent(of: 1) == 0)
        let forest = Forest(tree)
        #expect(Array(forest.vertices) == [0, 1, 2])
        #expect(Array(forest.edges) == [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(forest.trees.count == 1)
        #expect(throws: NotATree()) { try Arborescence(checked: tree) }
    }
}
