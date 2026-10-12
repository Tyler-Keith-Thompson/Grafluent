// §K: 10⁶-vertex shapes, which no recursive walk survives. Each runs inside a Task, whose stack is
// much smaller than the main thread's, so a recursive depth-first rooting, preorder, postorder or
// path overflows on the 10⁶-vertex path (depth 10⁶ − 1). The star has one row of 10⁶ − 1 entries,
// the complete binary tree 10⁶ vertices at height 19, and the forest 10⁶ one-vertex trees that
// `trees` must not build until read. TS-800 and TS-801 read the path from a graph, a file-private
// implicit conformer that costs nothing to build; the others build through `Tree(vertices:edges:)`
// or the parent-array initializer. Each test has a one-minute limit and is meant to stay within a
// couple of seconds in a debug build; the benchmarks take timings. Expected values come from the
// catalog's reference (`ref.py`, the proposed algorithm, checked against closed forms). Case IDs
// (TS-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

/// The path 0 – 1 – … – (n − 1) as an implicit graph: edge k joins k and k + 1, rows are computed,
/// so building it costs nothing (an `UndirectedAdjacencyList` of 10⁶ vertices takes seconds to
/// build in a debug build). Vertex and edge indices are the vertices and positions.
private struct ImplicitPath: Graph {
    let n: Int
    var vertices: Range<Int> { 0 ..< n }
    var edges: LazyMapCollection<Range<Int>, UndirectedEdge<Int>> { (0 ..< n - 1).lazy.map { UndirectedEdge($0, $0 + 1) } }
    func incidentEdges(of vertex: Int) -> [Int] { [vertex - 1, vertex].filter { $0 >= 0 && $0 < n - 1 } }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { $0 == vertex ? vertex + 1 : $0 } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < n }
    var vertexIndexBound: Int? { n }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { n - 1 }
    func edgeIndex(of position: Int) -> Int { position }
}

@Suite("Trees at 10⁶ vertices, without recursion")
struct TreeStressTests {
    @Test("TS-800 isTree is true on the 10⁶-vertex path", .timeLimit(.minutes(1)))
    func pathIsTree() async throws {
        try await Task {
            // U: P(0..999999)
            let graph = ImplicitPath(n: 1_000_000)
            #expect(graph.isTree)
            let tree = try #require(Tree(graph))
            #expect(tree.edgeCount == 999_999)
            #expect(Forest(graph) != nil)
        }.value
    }

    @Test("TS-801 RootedTree(P(0..999999), root: 0).depth(of: 999999) is 999999", .timeLimit(.minutes(1)))
    func pathDepth() async throws {
        try await Task {
            // U: P(0..999999)
            let graph = ImplicitPath(n: 1_000_000)
            let rooted = try #require(RootedTree(graph, root: 0))
            #expect(rooted.depth(of: 999_999) == 999_999)
            #expect(rooted.height == 999_999)
        }.value
    }

    @Test("TS-802 RootedTree(P(0..999999), root: 0).postorder[0] is 999999", .timeLimit(.minutes(1)))
    func pathPostorder() async throws {
        try await Task {
            // U: P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let rooted = RootedTree(tree, root: 0)
            let postorder = rooted.postorder
            #expect(postorder.count == n)
            #expect(postorder[0] == 999_999)
            #expect(postorder[n - 1] == 0)
        }.value
    }

    @Test("TS-803 RootedTree(P(0..999999), root: 500000).height is 500000", .timeLimit(.minutes(1)))
    func pathMiddleHeight() async throws {
        try await Task {
            // U: P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let rooted = RootedTree(tree, root: 500_000)
            #expect(rooted.height == 500_000)
            #expect(Array(rooted.children(of: 500_000)) == [499_999, 500_001])
        }.value
    }

    @Test("TS-804 Tree(P(0..999999)).path(from: 0, to: 999999).length is 999999", .timeLimit(.minutes(1)))
    func pathEndToEnd() async throws {
        try await Task {
            // U: P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let path = tree.path(from: 0, to: 999_999)
            #expect(path.length == 999_999)
            #expect(path.edges.first == 0)
            #expect(path.edges.last == 999_998)
            let back = tree.path(from: 999_999, to: 0)
            #expect(back.vertices.first == 999_999)
            #expect(back.length == 999_999)
        }.value
    }

    @Test("TS-805 RootedTree(P(0..999999), root: 0).isAncestor(1, of: 999999) is true", .timeLimit(.minutes(1)))
    func pathAncestor() async throws {
        try await Task {
            // U: P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let rooted = RootedTree(tree, root: 0)
            #expect(rooted.isAncestor(1, of: 999_999))
            #expect(!rooted.isAncestor(999_999, of: 1))
        }.value
    }

    @Test("TS-806 RootedTree(P(0..999999), root: 999999).descendants(of: 500000).count is 500000", .timeLimit(.minutes(1)))
    func pathDescendants() async throws {
        try await Task {
            // U: P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let rooted = RootedTree(tree, root: 999_999)
            #expect(rooted.descendants(of: 500_000).count == 500_000)
            #expect(rooted.preorder.first == 999_999)
            #expect(rooted.preorder.last == 0)
        }.value
    }

    @Test("TS-807 RootedTree(S(0;1..999999), root: 0).children(of: 0).count is 999999", .timeLimit(.minutes(1)))
    func starChildren() async throws {
        try await Task {
            // U: S(0;1..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) }))
            let rooted = RootedTree(tree, root: 0)
            let children = rooted.children(of: 0)
            #expect(children.count == 999_999)
            #expect(children.last == 999_999)
            #expect(rooted.height == 1)
        }.value
    }

    @Test("TS-808 RootedTree(S(0;1..999999), root: 7).preorder[2] is 1", .timeLimit(.minutes(1)))
    func starRootedAtLeaf() async throws {
        try await Task {
            // U: S(0;1..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(0, $0) }))
            let rooted = RootedTree(tree, root: 7)
            let preorder = rooted.preorder
            #expect(preorder[preorder.index(preorder.startIndex, offsetBy: 2)] == 1)
            #expect(rooted.height == 2)
        }.value
    }

    @Test("TS-809 Arborescence(parents: [nil, 0, 1, …, 29]).postorder[0] is 30")
    func shortChainPostorder() throws {
        // parents: [_,0,1,…,29]
        let parents: [Int?] = [nil] + (0 ..< 30).map { $0 }
        let arborescence = try #require(Arborescence(parents: parents))
        #expect(arborescence.postorder[0] == 30)
    }

    @Test("TS-810 Forest of 10⁶ isolated vertices has 10⁶ trees, built only when read", .timeLimit(.minutes(1)))
    func millionTrees() async throws {
        try await Task {
            // U: [0..999999]
            let n = 1_000_000
            let forest = try #require(Forest<Int>(vertices: 0 ..< n, edges: []))
            let trees = forest.trees
            #expect(trees.count == 1_000_000)
            let last = trees[trees.index(trees.startIndex, offsetBy: n - 1)]
            #expect(Array(last.vertices) == [999_999])
            #expect(forest.component(of: 999_999) == 999_999)
        }.value
    }

    @Test("TS-811 Tree(P(0..999999)).pruferSequence[999997] is 999998", .timeLimit(.minutes(1)))
    func pathPrufer() async throws {
        try await Task {
            // U: P(0..999999)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let code = try #require(tree.pruferSequence)
            #expect(code.count == 999_998)
            #expect(code[999_997] == 999_998)
            #expect(code[0] == 1)
        }.value
    }

    @Test("TS-812 RootedTree(kary(1000000,2), root: 0).height is 19", .timeLimit(.minutes(1)))
    func binaryTreeHeight() async throws {
        try await Task {
            // U: kary(1000000,2)
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(($0 - 1) / 2, $0) }))
            let rooted = RootedTree(tree, root: 0)
            #expect(rooted.height == 19)
        }.value
    }

    @Test("TS-813 RootedTree(kary(1000000,2), root: 0).preorder[19] is 524287: the leftmost leaf", .timeLimit(.minutes(1)))
    func binaryTreeLeftmostLeaf() async throws {
        try await Task {
            // U: kary(1000000,2). Edge k joins (k) / 2 to k + 1, the order kary writes them.
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (1 ..< n).map { UndirectedEdge(($0 - 1) / 2, $0) }))
            let rooted = RootedTree(tree, root: 0)
            let preorder = rooted.preorder
            #expect(preorder[preorder.index(preorder.startIndex, offsetBy: 19)] == 524_287)
            #expect(rooted.children(of: 524_287).isEmpty)
        }.value
    }

    @Test("A 10⁶-vertex chain from a parent array: Arborescence(parents:), depth, postorder and RootedTree", .timeLimit(.minutes(1)))
    func deepParentArray() async throws {
        try await Task {
            // TS-168's shape at 10⁶: vertex i has parent i − 1.
            let n = 1_000_000
            let parents: [Int?] = [nil] + (0 ..< n - 1).map { $0 }
            let arborescence = try #require(Arborescence(parents: parents))
            #expect(arborescence.depth(of: n - 1) == n - 1)
            #expect(arborescence.postorder[0] == n - 1)
            let path = try #require(arborescence.path(from: 0, to: n - 1))
            #expect(path.length == n - 1)
            #expect(arborescence.path(from: n - 1, to: 0) == nil)
            let rooted = RootedTree(arborescence)
            #expect(rooted.height == n - 1)
            #expect(Array(rooted.ancestors(of: 5)) == [4, 3, 2, 1, 0])
        }.value
    }

    @Test("A 10⁶-vertex path: rerooting, the forest, conversions and equality are iterative", .timeLimit(.minutes(1)))
    func deepConversions() async throws {
        try await Task {
            // TS-801's path, its edges in reverse order: the same value.
            let n = 1_000_000
            let tree = try #require(Tree(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            let reversed = try #require(Tree(edges: (0 ..< n - 1).reversed().map { UndirectedEdge($0 + 1, $0) }))
            #expect(tree == reversed)
            let arborescence = Arborescence(RootedTree(tree, root: n - 1))
            #expect(arborescence.root == n - 1)
            #expect(arborescence.edges[0] == DirectedEdge(from: 1, to: 0))
            let forest = Forest(tree)
            #expect(forest.trees.count == 1)
            #expect(forest.component(of: n - 1) == 0)
            let alsoForest = try #require(Forest(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }))
            #expect(alsoForest == forest)
        }.value
    }
}
