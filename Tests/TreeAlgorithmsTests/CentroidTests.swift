// §F: `Tree.centroid()`, the vertices whose removal leaves no component of more than n/2
// vertices, in `vertices` order (one, or two adjacent: TA-505, TA-510), and
// `Tree.centroidDecomposition()`, the rooted tree on the same vertices whose root is the centroid
// (the first in `vertices` order when there are two, TA-512, TA-514) and whose root's children are
// the centroids, chosen the same way, of the components left when it is removed, and so on.
// The result is built by the parent-function rule: the input's vertices in their order, edges
// `(parent, child)` per non-root vertex in vertex order, `children(of:)` in vertex order. So it
// is compared, edges and all, against `RootedTree(parents:)` / `RootedTree(vertices:parent:)` on
// the catalog's parent column. Its height is at most ⌊log₂ n⌋. The centroid differs from the center
// (TA-506 / TA-409, TA-508 / TA-410). Sources are written on the `ReferencePseudograph` as the
// catalog writes them. Literals are catalog cells, computed by `ref.py` and checked against a
// recursive decomposition over vertex sets and NetworkX 3.7's `tree.centroid` and `centroid`; the
// few extra rows (F1b, TA-412's tree, kary(8, 2)) were computed with the same reference. Case IDs
// (TA-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees

@Suite("Centroid and centroid decomposition")
struct CentroidTests {
    @Test("TA-501 Tree(K₁).centroid() is [0]")
    func singleVertex() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [0])
    }

    @Test("TA-502 Tree(K₂).centroid() is [0, 1]")
    func edge() throws {
        // U: [] 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [0, 1])
    }

    @Test("TA-503 Tree(P(0..98)).centroid() is [49]")
    func pathOf99() throws {
        // U: [] P(0..98)
        let pairs = (0 ..< 98).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [49])
    }

    @Test("TA-504 Tree(P(0..99)).centroid() is [49, 50]")
    func pathOf100() throws {
        // U: [] P(0..99)
        let pairs = (0 ..< 99).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [49, 50])
    }

    @Test("TA-505 Tree(kary(8, 2)).centroid() is [0, 1]: two, NetworkX's full_rary_tree(2, 8)")
    func binaryTreeOfEight() throws {
        // U: [] kary(8,2)
        let n = 8
        let pairs = (0 ..< n).flatMap { i in [2 * i + 1, 2 * i + 2].filter { $0 < n }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [0, 1])
        // Computed with ref.py: the decomposition roots the first of the two.
        let decomposition = tree.centroidDecomposition()
        let expected = try #require(RootedTree(parents: [nil, 0, 0, 1, 1, 2, 2, 3]))
        #expect(decomposition == expected)
        #expect(Array(decomposition.edges) == Array(expected.edges))
    }

    @Test("TA-506 Tree(S(0; 1..6), P(6, 7, 8, 9, 10)).centroid() is [0]: the center is [7]")
    func starWithLongBranch() throws {
        // U: [] S(0;1..6), P(6,7,8,9,10)
        let pairs = (1 ... 6).map { (0, $0) } + (6 ..< 10).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [0])
        #expect(tree.center() == [7])
    }

    @Test("TA-507 Tree(kary(40, 3)).centroid() is [0]: balanced_tree(3, 3)")
    func balancedTernary() throws {
        // U: [] kary(40,3)
        let n = 40
        let pairs = (0 ..< n).flatMap { i in [3 * i + 1, 3 * i + 2, 3 * i + 3].filter { $0 < n }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [0])
    }

    @Test("TA-508 Tree(F1).centroid() is [1]: the center is [0]")
    func f1() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [1])
        #expect(tree.center() == [0])
        // Computed with ref.py: F1b, the same edges in another order.
        let reordered: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let f1b = try #require(Tree(vertices: 0 ... 8, edges: reordered.map { UndirectedEdge($0.0, $0.1) }))
        #expect(f1b.centroid() == [1])
    }

    @Test("TA-509 Tree(a-b, b-c, b-d, d-e).centroid() is [b]: one centroid, two centers")
    func stringVertices() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == ["b"])
        #expect(tree.center() == ["b", "d"])
    }

    @Test("TA-510 Tree([4, 2, 7, 1]; 7-2, 2-4, 4-1).centroid() is [4, 2]: vertices order")
    func vertexOrderNotValueOrder() throws {
        // U: [4, 2, 7, 1] 7-2, 2-4, 4-1
        let pairs: [(Int, Int)] = [(7, 2), (2, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: [4, 2, 7, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.centroid() == [4, 2])
        // Computed with ref.py: the decomposition roots 4, the first of the two.
        let decomposition = tree.centroidDecomposition()
        let parent: [Int: Int?] = [4: nil, 2: 4, 7: 2, 1: 4]
        let expected = try #require(RootedTree(vertices: [4, 2, 7, 1], parent: { parent[$0]! }))
        #expect(decomposition == expected)
        #expect(Array(decomposition.vertices) == [4, 2, 7, 1])
        #expect(Array(decomposition.edges) == Array(expected.edges))
    }

    @Test("TA-511 Tree(K₁).centroidDecomposition() is the one-vertex rooted tree")
    func singleVertexDecomposition() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let tree = try #require(Tree(graph))
        let decomposition = tree.centroidDecomposition()
        #expect(decomposition.root == 0)
        #expect(decomposition.vertexCount == 1)
        #expect(decomposition.height == 0)
        #expect(decomposition == RootedTree(parents: [nil]))
    }

    @Test("TA-512 Tree(K₂).centroidDecomposition() is [_, 0]: of two centroids the first is the root")
    func edgeDecomposition() throws {
        // U: [] 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let tree = try #require(Tree(graph))
        let decomposition = tree.centroidDecomposition()
        let expected = try #require(RootedTree(parents: [nil, 0]))
        #expect(decomposition == expected)
        #expect(decomposition.root == 0)
    }

    @Test("TA-513 Tree(P(0..6)).centroidDecomposition() is [1, 3, 1, _, 5, 3, 5]: a perfect binary hierarchy")
    func pathOfSeven() throws {
        // U: [] P(0..6)
        let pairs = (0 ..< 6).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let decomposition = tree.centroidDecomposition()
        let expected = try #require(RootedTree(parents: [1, 3, 1, nil, 5, 3, 5]))
        #expect(decomposition == expected)
        // Parent-function rule: edges (parent, child) per non-root vertex in vertex order.
        #expect(Array(decomposition.edges) == Array(expected.edges))
        #expect(Array(decomposition.children(of: 3)) == [1, 5])
        #expect(decomposition.height == 2)
    }

    @Test("TA-514 Tree(P(0..7)).centroidDecomposition() is [1, 3, 1, _, 5, 3, 5, 6]: ties at every level, by vertices order")
    func pathOfEight() throws {
        // U: [] P(0..7)
        let pairs = (0 ..< 7).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let decomposition = tree.centroidDecomposition()
        let expected = try #require(RootedTree(parents: [1, 3, 1, nil, 5, 3, 5, 6]))
        #expect(decomposition == expected)
        #expect(Array(decomposition.edges) == Array(expected.edges))
        #expect(decomposition.height == 3)
    }

    @Test("TA-515 Tree(F1).centroidDecomposition() is [2, _, 1, 1, 1, 2, 4, 4, 5]")
    func f1Decomposition() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let decomposition = tree.centroidDecomposition()
        let expected = try #require(RootedTree(parents: [2, nil, 1, 1, 1, 2, 4, 4, 5]))
        #expect(decomposition == expected)
        #expect(Array(decomposition.edges) == Array(expected.edges))
        #expect(Array(decomposition.vertices) == Array(tree.vertices))
        // Its edges are not the input tree's: 1–2 (2's parent is 1) is no edge of F1.
        #expect(!tree.contains(edge: UndirectedEdge(1, 2)))
        #expect(decomposition.contains(edge: UndirectedEdge(1, 2)))
        // Computed with ref.py: F1b decomposes the same way (the rule reads vertices, not positions).
        let reordered: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let f1b = try #require(Tree(vertices: 0 ... 8, edges: reordered.map { UndirectedEdge($0.0, $0.1) }))
        #expect(f1b.centroidDecomposition() == expected)
    }

    @Test("TA-516 Tree(S(0; 1..5)).centroidDecomposition() is [_, 0, 0, 0, 0, 0]: height 1")
    func starDecomposition() throws {
        // U: [] S(0;1..5)
        let pairs = (1 ... 5).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let decomposition = tree.centroidDecomposition()
        let expected = try #require(RootedTree(parents: [nil, 0, 0, 0, 0, 0]))
        #expect(decomposition == expected)
        #expect(decomposition.height == 1)
    }

    @Test("TA-517 Tree(a-b, b-c, b-d, d-e).centroidDecomposition() is [b, _, b, b, d]: String vertices")
    func stringDecomposition() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let decomposition = tree.centroidDecomposition()
        // vertices = [a, b, c, d, e]
        let parent: [String: String?] = ["a": "b", "b": nil, "c": "b", "d": "b", "e": "d"]
        let expected = try #require(RootedTree(vertices: ["a", "b", "c", "d", "e"], parent: { parent[$0]! }))
        #expect(decomposition == expected)
        #expect(Array(decomposition.vertices) == ["a", "b", "c", "d", "e"])
        #expect(Array(decomposition.edges) == Array(expected.edges))
        #expect(Array(decomposition.children(of: "b")) == ["a", "c", "d"])
    }

    @Test("TA-518 Tree(kary(63, 2)).centroidDecomposition().height is 5")
    func completeBinaryHeight() throws {
        // U: [] kary(63,2)
        let n = 63
        let pairs = (0 ..< n).flatMap { i in [2 * i + 1, 2 * i + 2].filter { $0 < n }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let decomposition = tree.centroidDecomposition()
        #expect(decomposition.height == 5)
        // Computed with ref.py: the root is the centroid 0.
        #expect(decomposition.root == 0)
        #expect(tree.centroid() == [0])
    }

    @Test("TA-519 Tree(P(0..127)).centroidDecomposition().height is 7: ⌊log₂ 128⌋")
    func pathOf128Height() throws {
        // U: [] P(0..127)
        let pairs = (0 ..< 127).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let decomposition = tree.centroidDecomposition()
        #expect(decomposition.height == 7)
        #expect(decomposition.vertexCount == 128)
    }
}
