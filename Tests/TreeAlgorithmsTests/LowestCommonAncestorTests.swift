// §A: the one-shot `lowestCommonAncestor(of:_:)` on `RootedTree` and `Arborescence`. The deepest
// vertex that is an ancestor of both, where a vertex counts as its own ancestor (NetworkX; CLRS
// 21-3): if one is an ancestor of the other it is the answer (TA-006), and `lca(v, v) == v`
// (TA-008). The answer depends on the root (TA-009 against TA-003). F1 is
// `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8`; NX is NetworkX's `TestTreeLCA` arborescence
// `0>1, 0>2, 1>3, 1>4, 2>5, 2>6`. Sources are written on the `ReferencePseudograph` /
// `ReferenceDirectedMultigraph` as the catalog writes them; parent arrays go to the
// initializers. Expected values are the catalog's, computed by `ref.py` and checked against
// NetworkX 3.7's `lowest_common_ancestor`. TA-019 and TA-020 (non-vertices) are exit tests in
// `TreeAlgorithmPreconditionTests.swift`. Case IDs (TA-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees

@Suite("One-shot lowest common ancestor")
struct LowestCommonAncestorTests {
    @Test("TA-001 RootedTree(K₁, root: 0).lowestCommonAncestor(of: 0, 0) is 0")
    func singleVertex() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.lowestCommonAncestor(of: 0, 0) == 0)
    }

    @Test("TA-002 RootedTree(K₂, root: 1).lowestCommonAncestor(of: 0, 1) is 1: the root")
    func edgeRootedAtOne() throws {
        // U: [] 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let rooted = try #require(RootedTree(graph, root: 1))
        #expect(rooted.lowestCommonAncestor(of: 0, 1) == 1)
        #expect(rooted.lowestCommonAncestor(of: 1, 0) == 1)
    }

    @Test("TA-003 RootedTree(F1, root: 0).lowestCommonAncestor(of: 3, 7) is 1")
    func f1Cousins() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.lowestCommonAncestor(of: 3, 7) == 1)
    }

    @Test("TA-004 RootedTree(F1, root: 0).lowestCommonAncestor(of: 6, 7) is 4: siblings")
    func f1Siblings() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.lowestCommonAncestor(of: 6, 7) == 4)
    }

    @Test("TA-005 RootedTree(F1, root: 0).lowestCommonAncestor(of: 8, 6) is 0: different subtrees of the root")
    func f1AcrossRoot() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.lowestCommonAncestor(of: 8, 6) == 0)
    }

    @Test("TA-006 RootedTree(F1, root: 0).lowestCommonAncestor(of: 4, 6) is 4: an ancestor is its own answer")
    func f1Ancestor() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.lowestCommonAncestor(of: 4, 6) == 4)
        // Trees' isAncestor stays strict; LCA uses the reflexive notion.
        #expect(rooted.isAncestor(4, of: 6))
        #expect(!rooted.isAncestor(4, of: 4))
    }

    @Test("TA-007 RootedTree(F1, root: 0).lowestCommonAncestor(of: 6, 4) is 4: symmetric")
    func f1AncestorSymmetric() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.lowestCommonAncestor(of: 6, 4) == 4)
    }

    @Test("TA-008 RootedTree(F1, root: 0).lowestCommonAncestor(of: 5, 5) is 5: the same vertex")
    func f1SameVertex() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(rooted.lowestCommonAncestor(of: 5, 5) == 5)
    }

    @Test("TA-009 RootedTree(F1, root: 4).lowestCommonAncestor(of: 3, 8) is 1: the answer depends on the root")
    func f1Rerooted() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        #expect(rooted.lowestCommonAncestor(of: 3, 8) == 1)
        // TA-003's pair at root 0 has another answer.
        let atZero = RootedTree(Tree(rooted), root: 0)
        #expect(atZero.lowestCommonAncestor(of: 3, 7) == 1)
        #expect(rooted.lowestCommonAncestor(of: 3, 7) == 4)
    }

    @Test("TA-010 RootedTree(F1, root: 4).lowestCommonAncestor(of: 0, 6) is 4: the new root")
    func f1NewRoot() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        #expect(rooted.lowestCommonAncestor(of: 0, 6) == 4)
    }

    @Test("TA-011 RootedTree(F1, root: 8).lowestCommonAncestor(of: 3, 7) is 1: rooted at a leaf")
    func f1RootedAtLeaf() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 8))
        #expect(rooted.lowestCommonAncestor(of: 3, 7) == 1)
    }

    @Test("TA-012 Arborescence(NX).lowestCommonAncestor(of: 3, 4) is 1")
    func nxSiblings() throws {
        // D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.lowestCommonAncestor(of: 3, 4) == 1)
    }

    @Test("TA-013 Arborescence(NX).lowestCommonAncestor(of: 3, 5) is 0")
    func nxAcrossRoot() throws {
        // D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.lowestCommonAncestor(of: 3, 5) == 0)
    }

    @Test("TA-014 Arborescence(NX).lowestCommonAncestor(of: 5, 6) is 2")
    func nxOtherSiblings() throws {
        // D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.lowestCommonAncestor(of: 5, 6) == 2)
    }

    @Test("TA-015 Arborescence(NX).lowestCommonAncestor(of: 2, 6) is 2: an ancestor")
    func nxAncestor() throws {
        // D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.lowestCommonAncestor(of: 2, 6) == 2)
        #expect(arborescence.lowestCommonAncestor(of: 6, 2) == 2)
    }

    @Test("TA-016 Arborescence(parents: [_, 0, 0, 1, 1, 2, 2]).lowestCommonAncestor(of: 4, 6) is 0")
    func parentArrayArborescence() throws {
        // parents: [_, 0, 0, 1, 1, 2, 2]
        let arborescence = try #require(Arborescence(parents: [nil, 0, 0, 1, 1, 2, 2]))
        #expect(arborescence.lowestCommonAncestor(of: 4, 6) == 0)
    }

    @Test("TA-017 RootedTree(parents: [3, 3, _, 2, 0]).lowestCommonAncestor(of: 4, 1) is 3: root not at index 0")
    func rootNotFirst() throws {
        // parents: [3, 3, _, 2, 0]
        let rooted = try #require(RootedTree(parents: [3, 3, nil, 2, 0]))
        #expect(rooted.root == 2)
        #expect(rooted.lowestCommonAncestor(of: 4, 1) == 3)
    }

    @Test("TA-018 RootedTree(a-b, b-c, b-d, d-e; root: c).lowestCommonAncestor(of: a, e) is b: String vertices")
    func stringVertices() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: "c"))
        #expect(rooted.lowestCommonAncestor(of: "a", "e") == "b")
    }
}
