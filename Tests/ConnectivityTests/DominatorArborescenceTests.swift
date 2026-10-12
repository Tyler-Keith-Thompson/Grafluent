// Arborescence(_: DominatorTree): a dominator or post-dominator tree as a Trees arborescence.
// Each conversion is checked against the tree it comes from: the reachable vertices in vertex
// order, the root, immediate dominators as parents, children in the same order, and dominance
// as ancestry. Case IDs (CN-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Dominator trees as arborescences")
struct DominatorArborescenceTests {
    @Test("CN-147 NetworkX's docstring graph")
    func networkXDocstring() {
        let edges = [(1, 2), (1, 3), (2, 5), (3, 4), (4, 5)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = AdjacencyList(vertices: 1 ... 5, edges: edges)
        let arborescence = Arborescence(graph.dominatorTree(root: 1))
        #expect(arborescence.root == 1)
        #expect(Array(arborescence.vertices) == [1, 2, 3, 4, 5])
        // immediate_dominators: {1: 1, 2: 1, 3: 1, 4: 3, 5: 1}.
        #expect(arborescence.parent(of: 1) == nil)
        for (v, d) in [2: 1, 3: 1, 4: 3, 5: 1] { #expect(arborescence.parent(of: v) == d, "\(v)") }
        #expect(Array(arborescence.children(of: 1)) == [2, 3, 5])
        #expect(Array(arborescence.edges) == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 1, to: 5)])
        #expect(arborescence.depth(of: 4) == 2)
    }

    @Test("CN-148 unreachable vertices are left out, and the root need not come first")
    func unreachable() {
        // Root 3; 0 and 5 are not reached.
        let edges = [(3, 1), (1, 2), (3, 4), (4, 2), (0, 3), (5, 5)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = CompressedSparseRow(vertexCount: 6, edges: edges)
        let tree = graph.dominatorTree(root: 3)
        let arborescence = Arborescence(tree)
        #expect(arborescence.root == 3)
        #expect(Array(arborescence.vertices) == [1, 2, 3, 4])
        #expect(arborescence.rootIndex == 2)
        #expect(arborescence.parent(of: 2) == 3)
        #expect(arborescence.parent(of: 1) == 3)
        // Edges follow the listed vertices other than the root: 1, 2, 4.
        #expect(Array(arborescence.edges) == [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 3, to: 4)])
    }

    @Test("CN-149 seeded random digraphs: parents, children and dominance agree", .tags(.randomized), arguments: 0 ..< 10)
    func againstTheTree(seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(149 + seed))
        let n = 20
        let arcs = (0 ..< 45).map { _ in DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator)) }
        let graphs: [any DirectedGraph<Int>] = [
            AdjacencyList(vertices: 0 ..< n, edges: arcs),
            CompressedSparseRow(vertexCount: n, edges: arcs),
            AdjacencyMatrix(vertexCount: n, edges: arcs),
        ]
        func check<G: DirectedGraph<Int>>(_ graph: G, root: Int) {
            let tree = graph.dominatorTree(root: root)
            let arborescence = Arborescence(tree)
            let reached = (0 ..< n).filter { tree.dominators(of: $0) != nil }
            #expect(Array(arborescence.vertices) == reached)
            #expect(arborescence.root == root)
            #expect(arborescence.edgeCount == reached.count - 1)
            for v in reached {
                #expect(arborescence.parent(of: v) == tree.immediateDominator(of: v))
                #expect(Array(arborescence.children(of: v)) == Array(tree.children(of: v)))
                // The ancestors are the strict dominators, nearest first.
                #expect(Array(arborescence.ancestors(of: v)) == tree.strictDominators(of: v))
                for u in reached { #expect(tree.dominates(u, v) == (u == v || arborescence.isAncestor(u, of: v))) }
            }
        }
        for graph in graphs { check(graph, root: Int.random(in: 0 ..< n, using: &generator)) }
    }

    @Test("CN-150 a post-dominator tree converts the same way, rooted at the exit")
    func postDominators() {
        // 0 → 1, 0 → 2, 1 → 3, 2 → 3, 3 → 4; 5 → 0 too; 6 cannot reach 4.
        let edges = [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4), (5, 0), (4, 6)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let graph = AdjacencyList(vertices: 0 ..< 7, edges: edges)
        let tree = graph.postDominatorTree(exit: 4)
        let arborescence = Arborescence(tree)
        #expect(arborescence.root == 4)
        #expect(Array(arborescence.vertices) == [0, 1, 2, 3, 4, 5])
        for v in [0, 1, 2, 3, 5] { #expect(arborescence.parent(of: v) == tree.immediateDominator(of: v), "\(v)") }
        #expect(arborescence.parent(of: 0) == 3)
        #expect(arborescence.parent(of: 5) == 0)
    }

    @Test("CN-151 String vertices and a one-vertex tree")
    func vertexTypes() {
        let graph = AdjacencyList(vertices: ["exit", "entry", "body"], edges: [DirectedEdge(from: "entry", to: "body"), DirectedEdge(from: "body", to: "exit"), DirectedEdge(from: "entry", to: "exit")])
        let arborescence = Arborescence(graph.dominatorTree(root: "entry"))
        #expect(Array(arborescence.vertices) == ["exit", "entry", "body"])
        #expect(arborescence.root == "entry")
        #expect(arborescence.parent(of: "exit") == "entry")
        #expect(arborescence.parent(of: "body") == "entry")
        let alone = Arborescence(AdjacencyList(vertices: [7, 8], edges: [DirectedEdge(from: 8, to: 7)]).dominatorTree(root: 7))
        #expect(alone.vertexCount == 1)
        #expect(alone.root == 7)
    }
}
