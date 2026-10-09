// §E: rooted queries on `RootedTree` and `Arborescence`. `children(of:)` is the vertex's incidence
// row without its parent edge, so in position order of the child edges (TS-219, TS-225);
// `preorder` is the root, then each child's subtree in that order, `postorder` each vertex after
// its subtree; `descendants(of:)` is the subtree in preorder without the vertex; `ancestors(of:)`
// runs parent first up to the root; `isAncestor(_:of:)` is strict; `depth(of: root) == 0` and
// `height` is the greatest depth. Tree E1 is `U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6`; E2 is
// `U: 4-2, 0-2, 2-1, 1-3` (positions not in vertex order). Sources are written on the
// `ReferencePseudograph` / `ReferenceDirectedMultigraph` as the catalog writes them. Expected
// values come from the catalog's reference (`ref.py`, cross-checked against NetworkX's
// `dfs_preorder_nodes` / `dfs_postorder_nodes` on the same adjacency order). Case IDs (TS-nnn)
// refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Rooted queries")
struct RootedQueryTests {
    @Test("TS-200 RootedTree(E1, root: 0).preorder is [0, 1, 3, 4, 6, 2, 5]")
    func preorderE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.preorder) == [0, 1, 3, 4, 6, 2, 5])
        #expect(rooted.preorder.count == 7)
        #expect(rooted.root == 0)
    }

    @Test("TS-201 RootedTree(E1, root: 0).postorder is [3, 6, 4, 1, 5, 2, 0]")
    func postorderE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.postorder == [3, 6, 4, 1, 5, 2, 0])
    }

    @Test("TS-202 RootedTree(E1, root: 0).children(of: 1) is [3, 4]")
    func childrenE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let children = rooted.children(of: 1)
        #expect(Array(children) == [3, 4])
        #expect(children.count == 2)
        #expect(children[children.index(after: children.startIndex)] == 4)
        #expect(Array(children.reversed()) == [4, 3])
    }

    @Test("TS-203 RootedTree(E1, root: 0).parent(of: 6) is 4")
    func parentE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.parent(of: 6) == 4)
    }

    @Test("TS-204 RootedTree(E1, root: 0).parent(of: 0) is nil")
    func parentOfRoot() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.parent(of: 0) == nil)
    }

    @Test("TS-205 RootedTree(E1, root: 0).parentEdge(of: 6) is 5")
    func parentEdgeE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.parentEdge(of: 6) == 5)
    }

    @Test("TS-206 RootedTree(E1, root: 0).parentEdge(of: 0) is nil")
    func parentEdgeOfRoot() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.parentEdge(of: 0) == nil)
    }

    @Test("TS-207 RootedTree(E1, root: 0).depth(of: 6) is 3")
    func depthE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.depth(of: 6) == 3)
        #expect(rooted.depth(of: 0) == 0)
    }

    @Test("TS-208 RootedTree(E1, root: 0).height is 3")
    func heightE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.height == 3)
    }

    @Test("TS-209 RootedTree(E1, root: 0).descendants(of: 1) is [3, 4, 6]: a preorder slice")
    func descendantsE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let descendants = rooted.descendants(of: 1)
        #expect(Array(descendants) == [3, 4, 6])
        // A slice of preorder: its indices are preorder's.
        let preorder = rooted.preorder
        #expect(Array(preorder[descendants.startIndex ..< descendants.endIndex]) == [3, 4, 6])
        #expect(preorder.index(before: descendants.startIndex) == preorder.firstIndex(of: 1))
    }

    @Test("TS-210 RootedTree(E1, root: 0).descendants(of: 1).count is 3: subtree size − 1")
    func descendantsCountE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.descendants(of: 1).count == 3)
    }

    @Test("TS-211 RootedTree(E1, root: 0).descendants(of: 6) is empty: a leaf")
    func descendantsOfLeaf() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.descendants(of: 6).isEmpty)
    }

    @Test("TS-212 RootedTree(E1, root: 0).ancestors(of: 6) is [4, 1, 0]: nearest first")
    func ancestorsE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.ancestors(of: 6)) == [4, 1, 0])
        // Lazy and restartable: iterating twice gives the same.
        let ancestors = rooted.ancestors(of: 6)
        #expect(Array(ancestors) == Array(ancestors))
        #expect(Array(ancestors.prefix(1)) == [4])
    }

    @Test("TS-213 RootedTree(E1, root: 0).ancestors(of: 0) is empty")
    func ancestorsOfRoot() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.ancestors(of: 0)).isEmpty)
    }

    @Test("TS-214 RootedTree(E1, root: 0).isAncestor(1, of: 6) is true")
    func isAncestorTrue() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.isAncestor(1, of: 6))
    }

    @Test("TS-215 RootedTree(E1, root: 0).isAncestor(6, of: 6) is false: strict")
    func isAncestorStrict() throws {
        // As ancestors(of:) and NetworkX ancestors; Swing's isNodeAncestor and DominatorTree.dominates are reflexive.
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(!rooted.isAncestor(6, of: 6))
        #expect(!rooted.isAncestor(0, of: 0))
    }

    @Test("TS-216 RootedTree(E1, root: 0).isAncestor(2, of: 6) is false: different branches")
    func isAncestorOtherBranch() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(!rooted.isAncestor(2, of: 6))
    }

    @Test("TS-217 RootedTree(E1, root: 0).isAncestor(6, of: 1) is false: reversed")
    func isAncestorReversed() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(!rooted.isAncestor(6, of: 1))
    }

    @Test("TS-218 RootedTree(E1, root: 4).preorder is [4, 1, 0, 2, 5, 3, 6]: rerooted at an inner vertex")
    func rerootedPreorder() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        #expect(Array(rooted.preorder) == [4, 1, 0, 2, 5, 3, 6])
        let tree = try #require(Tree(graph))
        #expect(Array(RootedTree(tree, root: 4).preorder) == [4, 1, 0, 2, 5, 3, 6])
    }

    @Test("TS-219 RootedTree(E1, root: 4).children(of: 4) is [1, 6]: the former parent first, rows in position order")
    func rerootedChildren() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        #expect(Array(rooted.children(of: 4)) == [1, 6])
    }

    @Test("TS-220 RootedTree(E1, root: 4).parent(of: 0) is 1")
    func rerootedParent() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        #expect(rooted.parent(of: 0) == 1)
        #expect(rooted.parent(of: 4) == nil)
    }

    @Test("TS-221 RootedTree(E1, root: 6).height is 5")
    func rerootedAtLeafHeight() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 6))
        #expect(rooted.height == 5)
    }

    @Test("TS-222 RootedTree(E1, root: 6).ancestors(of: 5) is [2, 0, 1, 4, 6]")
    func rerootedAtLeafAncestors() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 6))
        #expect(Array(rooted.ancestors(of: 5)) == [2, 0, 1, 4, 6])
    }

    @Test("TS-223 Tree > RootedTree(root: 5) > Tree > RootedTree(root: 0) has the preorder of rooting directly")
    func roundTripThroughTree() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let atFive = RootedTree(tree, root: 5)
        let again = RootedTree(Tree(atFive), root: 0)
        #expect(Array(again.preorder) == [0, 1, 3, 4, 6, 2, 5])
        #expect(again.postorder == [3, 6, 4, 1, 5, 2, 0])
    }

    @Test("TS-224 RootedTree(E2, root: 0).preorder is [0, 2, 4, 1, 3]")
    func preorderE2() throws {
        // U: 4-2, 0-2, 2-1, 1-3
        let pairs: [(Int, Int)] = [(4, 2), (0, 2), (2, 1), (1, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.preorder) == [0, 2, 4, 1, 3])
    }

    @Test("TS-225 RootedTree(E2, root: 0).children(of: 2) is [4, 1]: by child-edge position, not vertex order")
    func childrenByEdgePosition() throws {
        // U: 4-2, 0-2, 2-1, 1-3
        let pairs: [(Int, Int)] = [(4, 2), (0, 2), (2, 1), (1, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.children(of: 2)) == [4, 1])
    }

    @Test("TS-226 RootedTree(E2, root: 0).postorder is [4, 3, 1, 2, 0]")
    func postorderE2() throws {
        // U: 4-2, 0-2, 2-1, 1-3
        let pairs: [(Int, Int)] = [(4, 2), (0, 2), (2, 1), (1, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.postorder == [4, 3, 1, 2, 0])
    }

    @Test("TS-227 RootedTree(E2, root: 0).parentEdge(of: 4) is 0")
    func parentEdgeE2() throws {
        // U: 4-2, 0-2, 2-1, 1-3
        let pairs: [(Int, Int)] = [(4, 2), (0, 2), (2, 1), (1, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.parentEdge(of: 4) == 0)
    }

    @Test("TS-228 RootedTree(K₁, root: 0).preorder is [0]")
    func preorderK1() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.preorder) == [0])
        #expect(rooted.postorder == [0])
    }

    @Test("TS-229 RootedTree(K₁, root: 0).descendants(of: 0) is empty")
    func descendantsK1() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.descendants(of: 0).isEmpty)
        #expect(rooted.children(of: 0).isEmpty)
    }

    @Test("TS-230 RootedTree(S(0;1..5), root: 0).children(of: 0) is [1, 2, 3, 4, 5]")
    func starChildren() throws {
        // U: S(0;1..5)
        let graph = ReferencePseudograph(edges: (1 ... 5).map { UndirectedEdge(0, $0) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.children(of: 0)) == [1, 2, 3, 4, 5])
    }

    @Test("TS-231 RootedTree(S(0;1..5), root: 3).preorder is [3, 0, 1, 2, 4, 5]: a star rooted at a leaf")
    func starRootedAtLeafPreorder() throws {
        // U: S(0;1..5)
        let graph = ReferencePseudograph(edges: (1 ... 5).map { UndirectedEdge(0, $0) })
        let rooted = try #require(RootedTree(graph, root: 3))
        #expect(Array(rooted.preorder) == [3, 0, 1, 2, 4, 5])
    }

    @Test("TS-232 RootedTree(S(0;1..5), root: 3).height is 2")
    func starRootedAtLeafHeight() throws {
        // U: S(0;1..5)
        let graph = ReferencePseudograph(edges: (1 ... 5).map { UndirectedEdge(0, $0) })
        let rooted = try #require(RootedTree(graph, root: 3))
        #expect(rooted.height == 2)
    }

    @Test("TS-233 RootedTree(P(0..5), root: 3).children(of: 3) is [2, 4]")
    func pathChildren() throws {
        // U: P(0..5)
        let graph = ReferencePseudograph(edges: (0 ..< 5).map { UndirectedEdge($0, $0 + 1) })
        let rooted = try #require(RootedTree(graph, root: 3))
        #expect(Array(rooted.children(of: 3)) == [2, 4])
    }

    @Test("TS-234 RootedTree(P(0..5), root: 3).postorder is [0, 1, 2, 5, 4, 3]")
    func pathPostorder() throws {
        // U: P(0..5)
        let graph = ReferencePseudograph(edges: (0 ..< 5).map { UndirectedEdge($0, $0 + 1) })
        let rooted = try #require(RootedTree(graph, root: 3))
        #expect(rooted.postorder == [0, 1, 2, 5, 4, 3])
    }

    @Test("TS-235 RootedTree(kary(15,2), root: 0).preorder")
    func binaryTreePreorder() throws {
        // U: kary(15,2)
        var pairs: [(Int, Int)] = []
        for i in 0 ..< 15 {
            for j in 1 ... 2 where 2 * i + j < 15 { pairs.append((i, 2 * i + j)) }
        }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.preorder) == [0, 1, 3, 7, 8, 4, 9, 10, 2, 5, 11, 12, 6, 13, 14])
    }

    @Test("TS-236 RootedTree(kary(15,2), root: 0).postorder")
    func binaryTreePostorder() throws {
        // U: kary(15,2)
        var pairs: [(Int, Int)] = []
        for i in 0 ..< 15 {
            for j in 1 ... 2 where 2 * i + j < 15 { pairs.append((i, 2 * i + j)) }
        }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.postorder == [7, 8, 3, 9, 10, 4, 1, 11, 12, 5, 13, 14, 6, 2, 0])
    }

    @Test("TS-237 RootedTree(kary(15,2), root: 0).descendants(of: 2) is [5, 11, 12, 6, 13, 14]")
    func binaryTreeDescendants() throws {
        // U: kary(15,2)
        var pairs: [(Int, Int)] = []
        for i in 0 ..< 15 {
            for j in 1 ... 2 where 2 * i + j < 15 { pairs.append((i, 2 * i + j)) }
        }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(rooted.descendants(of: 2)) == [5, 11, 12, 6, 13, 14])
    }

    @Test("TS-238 RootedTree(kary(15,2), root: 0).height is 3")
    func binaryTreeHeight() throws {
        // U: kary(15,2)
        var pairs: [(Int, Int)] = []
        for i in 0 ..< 15 {
            for j in 1 ... 2 where 2 * i + j < 15 { pairs.append((i, 2 * i + j)) }
        }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.height == 3)
    }

    @Test("TS-239 Arborescence(E1 as arcs).preorder is [0, 1, 3, 4, 6, 2, 5]")
    func arborescencePreorder() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(arborescence.preorder) == [0, 1, 3, 4, 6, 2, 5])
        #expect(arborescence.postorder == [3, 6, 4, 1, 5, 2, 0])
        #expect(Array(arborescence.descendants(of: 1)) == [3, 4, 6])
        #expect(Array(arborescence.ancestors(of: 6)) == [4, 1, 0])
        #expect(arborescence.isAncestor(1, of: 6))
        #expect(!arborescence.isAncestor(6, of: 6))
        #expect(!arborescence.isAncestor(2, of: 6))
        #expect(arborescence.parent(of: 6) == 4)
        #expect(arborescence.parent(of: 0) == nil)
        #expect(arborescence.parentEdge(of: 6) == 5)
        #expect(arborescence.parentEdge(of: 0) == nil)
        #expect(arborescence.depth(of: 6) == 3)
        #expect(arborescence.height == 3)
    }

    @Test("TS-240 Arborescence > RootedTree keeps the root: postorder is [3, 6, 4, 1, 5, 2, 0]")
    func arborescenceToRootedTree() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let rooted = RootedTree(arborescence)
        #expect(rooted.postorder == [3, 6, 4, 1, 5, 2, 0])
        #expect(rooted.root == 0)
    }

    @Test("TS-241 Arborescence > RootedTree > Tree > RootedTree(root: 4) > Arborescence flips the arcs on the 0–4 path")
    func rerootingFlipsArcs() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let rerooted = Arborescence(RootedTree(Tree(RootedTree(arborescence)), root: 4))
        let expected: [(Int, Int)] = [(1, 0), (0, 2), (1, 3), (4, 1), (2, 5), (4, 6)]
        #expect(Array(rerooted.edges) == expected.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(rerooted.root == 4)
    }

    @Test("TS-242 Arborescence(D: 2>3, 2>0, 0>1).children(of: 2) is [3, 0]: out-edges in position order")
    func arborescenceChildrenByPosition() throws {
        // D: 2>3, 2>0, 0>1
        let pairs: [(Int, Int)] = [(2, 3), (2, 0), (0, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(arborescence.children(of: 2)) == [3, 0])
    }

    @Test("TS-243 Arborescence(D: 2>3, 2>0, 0>1).depth(of: 1) is 2")
    func arborescenceDepth() throws {
        // D: 2>3, 2>0, 0>1
        let pairs: [(Int, Int)] = [(2, 3), (2, 0), (0, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.depth(of: 1) == 2)
    }

    @Test("TS-244 RootedTree(g, root: dee).preorder is [dee, cy, ann, bob]: String vertices")
    func stringPreorder() throws {
        // U: ann-bob, ann-cy, cy-dee
        let pairs: [(String, String)] = [("ann", "bob"), ("ann", "cy"), ("cy", "dee")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: "dee"))
        #expect(Array(rooted.preorder) == ["dee", "cy", "ann", "bob"])
    }

    @Test("TS-245 RootedTree(g, root: dee).ancestors(of: bob) is [ann, cy, dee]")
    func stringAncestors() throws {
        // U: ann-bob, ann-cy, cy-dee
        let pairs: [(String, String)] = [("ann", "bob"), ("ann", "cy"), ("cy", "dee")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: "dee"))
        #expect(Array(rooted.ancestors(of: "bob")) == ["ann", "cy", "dee"])
    }

    @Test("Index space: rootIndex, parent(ofIndex:) and depth(ofIndex:) are the vertex queries through vertexIndex(of:)")
    func indexSpaceQueries() throws {
        // E1 rerooted at 4 (TS-218) and E2 at 0 (TS-224), on both rooted types.
        let sources: [(pairs: [(Int, Int)], root: Int)] = [
            ([(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)], 4),
            ([(4, 2), (0, 2), (2, 1), (1, 3)], 0),
        ]
        for source in sources {
            let tree = try #require(Tree(edges: source.pairs.map { UndirectedEdge($0.0, $0.1) }))
            let rooted = RootedTree(tree, root: source.root)
            let arborescence = Arborescence(rooted)
            #expect(rooted.rootIndex == rooted.vertexIndex(of: rooted.root))
            #expect(arborescence.rootIndex == arborescence.vertexIndex(of: arborescence.root))
            for v in rooted.vertices {
                let i = rooted.vertexIndex(of: v)
                let parentIndex = rooted.parent(of: v).map { rooted.vertexIndex(of: $0) }
                #expect(rooted.parent(ofIndex: i) == parentIndex, "\(v)")
                #expect(rooted.depth(ofIndex: i) == rooted.depth(of: v), "\(v)")
                let j = arborescence.vertexIndex(of: v)
                let arcParentIndex = arborescence.parent(of: v).map { arborescence.vertexIndex(of: $0) }
                #expect(arborescence.parent(ofIndex: j) == arcParentIndex, "\(v)")
                #expect(arborescence.depth(ofIndex: j) == arborescence.depth(of: v), "\(v)")
            }
        }
    }

    @Test("Rooted queries agree with each other on E1 at every root")
    func queriesAgreeAtEveryRoot() throws {
        // Each relation written from the others, at all seven roots of E1.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let tree = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        for root in 0 ... 6 {
            let rooted = RootedTree(tree, root: root)
            #expect(rooted.root == root)
            #expect(rooted.preorder.first == root)
            #expect(rooted.postorder.last == root)
            #expect(Set(rooted.preorder) == Set(0 ... 6))
            for v in 0 ... 6 {
                let ancestors = Array(rooted.ancestors(of: v))
                #expect(ancestors.count == rooted.depth(of: v), "root \(root), v \(v)")
                #expect(ancestors.first == rooted.parent(of: v), "root \(root), v \(v)")
                for c in rooted.children(of: v) {
                    #expect(rooted.parent(of: c) == v, "root \(root), v \(v)")
                    #expect(rooted.depth(of: c) == rooted.depth(of: v) + 1, "root \(root), v \(v)")
                }
                if let e = rooted.parentEdge(of: v), let p = rooted.parent(of: v) {
                    #expect(rooted.edges[e] == UndirectedEdge(p, v), "root \(root), v \(v)")
                }
                for w in 0 ... 6 {
                    let inSubtree = rooted.descendants(of: v).contains(w)
                    #expect(rooted.isAncestor(v, of: w) == inSubtree, "root \(root), \(v) of \(w)")
                    #expect(rooted.isAncestor(v, of: w) == Array(rooted.ancestors(of: w)).contains(v), "root \(root), \(v) of \(w)")
                }
            }
            let heights = (0 ... 6).map { rooted.depth(of: $0) }
            #expect(rooted.height == heights.max())
        }
    }
}
