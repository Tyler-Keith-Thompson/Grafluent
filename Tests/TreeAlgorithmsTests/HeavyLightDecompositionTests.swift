// §D: `HeavyLightDecomposition`. The heavy child is the child with the largest subtree, the first
// in `children(of:)` order on a tie (TA-305 against TA-306); positions are the preorder that
// takes the heavy child first, then the other children in `children(of:)` order, so a heavy path
// is an interval from its head and a subtree is `subtree(of:)`. `segments(from:to:)` cuts the
// path where it changes heavy path, in walk order: on the way up a segment is visited from its
// last position to its first (`isReversed`), on the way down from first to last, and a
// one-position segment is never reversed (TA-317's `4..<5`), so the flag is canonical. Without
// the common ancestor the ancestor's position, the low end of the segment that holds it, is
// dropped, and that segment with it when it held only the ancestor (TA-325); `source == target`
// then gives no segment (TA-303). The walk's reverse gives the same ranges in reverse order with
// the flags of the multi-position segments flipped (TA-318). `Segment` has no public
// initializer in api.md, so segments are compared by their `positions` and `isReversed`. F1 is
// `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8`, F1b the same edges in the position order
// `4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5`, NX NetworkX's `TestTreeLCA` arborescence. Literals are
// catalog cells or were computed with `ref.py`'s model (heads, heavy children and positions of
// every F1 vertex, the extra segments), which checks each segment list by expanding it back into
// the path. TA-336 is an exit test in `TreeAlgorithmPreconditionTests.swift`. Case IDs (TA-nnn)
// refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees

@Suite("Heavy–light decomposition")
struct HeavyLightDecompositionTests {
    @Test("TA-301 HeavyLightDecomposition(K₁).preorder is [0]")
    func singleVertexPreorder() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(Array(hld.preorder) == [0])
        #expect(hld.heavyChild(of: 0) == nil)
        #expect(hld.head(of: 0) == 0)
        #expect(hld.position(of: 0) == 0)
        #expect(hld.subtree(of: 0) == 0 ..< 1)
        #expect(hld.lowestCommonAncestor(of: 0, 0) == 0)
    }

    @Test("TA-302 HeavyLightDecomposition(K₁).segments(from: 0, to: 0) is [0..<1], not reversed")
    func singleVertexSegment() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 0, to: 0)
        #expect(segments.map(\.positions) == [0 ..< 1])
        #expect(segments.map(\.isReversed) == [false])
        // The default is includingCommonAncestor: true.
        #expect(segments == hld.segments(from: 0, to: 0, includingCommonAncestor: true))
    }

    @Test("TA-303 HeavyLightDecomposition(K₁).segments(from: 0, to: 0, includingCommonAncestor: false) is empty")
    func singleVertexWithoutAncestor() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.segments(from: 0, to: 0, includingCommonAncestor: false).isEmpty)
    }

    @Test("TA-304 HeavyLightDecomposition(F1, root: 0).preorder is [0, 1, 4, 6, 7, 3, 2, 5, 8]: heavy children first")
    func f1Preorder() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let preorder = hld.preorder
        #expect(Array(preorder) == [0, 1, 4, 6, 7, 3, 2, 5, 8])
        #expect(preorder.count == 9)
        // position(of:) is the offset in preorder, by vertex and by index.
        for (offset, v) in preorder.enumerated() {
            #expect(hld.position(of: v) == offset)
            #expect(hld.position(ofIndex: rooted.vertexIndex(of: v)) == offset)
            #expect(preorder[preorder.index(preorder.startIndex, offsetBy: offset)] == v)
        }
    }

    @Test("TA-305 HeavyLightDecomposition(F1, root: 0).heavyChild(of: 4) is 6: a tie goes to the first child")
    func f1HeavyChildTie() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.heavyChild(of: 4) == 6)
        #expect(Array(rooted.children(of: 4)) == [6, 7])
    }

    @Test("TA-306 HeavyLightDecomposition(F1b, root: 0).heavyChild(of: 4) is 7: the tie goes the other way, by edge position")
    func f1bHeavyChildTie() throws {
        // U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5
        let pairs: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.heavyChild(of: 4) == 7)
    }

    @Test("TA-307 HeavyLightDecomposition(F1b, root: 0).preorder is [0, 1, 4, 7, 6, 3, 2, 5, 8]")
    func f1bPreorder() throws {
        // U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5
        let pairs: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(Array(hld.preorder) == [0, 1, 4, 7, 6, 3, 2, 5, 8])
        // The heavy child 1 of the root is first although children(of: 0) is [2, 1].
        #expect(Array(rooted.children(of: 0)) == [2, 1])
    }

    @Test("TA-308 HeavyLightDecomposition(F1, root: 0).heavyChild(of: 8) is nil: a leaf")
    func f1LeafHeavyChild() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.heavyChild(of: 8) == nil)
    }

    @Test("TA-309 HeavyLightDecomposition(F1, root: 0).heavyChild(of: 0) is 1")
    func f1RootHeavyChild() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.heavyChild(of: 0) == 1)
    }

    @Test("TA-310 HeavyLightDecomposition(F1, root: 0).head(of: 6) is 0: on the root's heavy path")
    func f1HeadOnRootPath() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.head(of: 6) == 0)
    }

    @Test("TA-311 HeavyLightDecomposition(F1, root: 0).head(of: 7) is 7: a light child heads its own path")
    func f1HeadOfLightChild() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.head(of: 7) == 7)
    }

    @Test("TA-312 HeavyLightDecomposition(F1, root: 0).head(of: 8) is 2")
    func f1HeadOfDeepLeaf() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.head(of: 8) == 2)
    }

    @Test("TA-313 HeavyLightDecomposition(F1, root: 0).position(of: 7) is 4")
    func f1Position() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.position(of: 7) == 4)
        #expect(hld.position(ofIndex: rooted.vertexIndex(of: 7)) == 4)
    }

    @Test("TA-314 HeavyLightDecomposition(F1, root: 0).subtree(of: 1) is 1..<6: subtrees are intervals")
    func f1SubtreeOfOne() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let range = hld.subtree(of: 1)
        #expect(range == 1 ..< 6)
        // The interval holds exactly 1 and its descendants.
        let members = range.map { hld.preorder[hld.preorder.index(hld.preorder.startIndex, offsetBy: $0)] }
        #expect(Set(members) == Set([1] + Array(rooted.descendants(of: 1))))
    }

    @Test("TA-315 HeavyLightDecomposition(F1, root: 0).subtree(of: 2) is 6..<9")
    func f1SubtreeOfTwo() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.subtree(of: 2) == 6 ..< 9)
    }

    @Test("TA-316 HeavyLightDecomposition(F1, root: 0).subtree(of: 0) is 0..<9: everything")
    func f1SubtreeOfRoot() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.subtree(of: 0) == 0 ..< 9)
    }

    @Test("TA-317 HeavyLightDecomposition(F1, root: 0).segments(from: 7, to: 8) is [4..<5, 0..<3 R, 6..<9]")
    func f1SegmentsUpAndDown() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 7, to: 8)
        #expect(segments.map(\.positions) == [4 ..< 5, 0 ..< 3, 6 ..< 9])
        // Up a light leaf (one position: not reversed), up the root's path, down another.
        #expect(segments.map(\.isReversed) == [false, true, false])
    }

    @Test("TA-318 HeavyLightDecomposition(F1, root: 0).segments(from: 8, to: 7) is [6..<9 R, 0..<3, 4..<5]: the reverse walk")
    func f1SegmentsReversed() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 8, to: 7)
        #expect(segments.map(\.positions) == [6 ..< 9, 0 ..< 3, 4 ..< 5])
        #expect(segments.map(\.isReversed) == [true, false, false])
        // The same ranges as TA-317, in reverse order.
        let forward = hld.segments(from: 7, to: 8)
        #expect(segments.map(\.positions) == forward.reversed().map(\.positions))
        // Computed with ref.py: without the ancestor, the reverse of TA-323.
        let withoutAncestor = hld.segments(from: 8, to: 7, includingCommonAncestor: false)
        #expect(withoutAncestor.map(\.positions) == [6 ..< 9, 1 ..< 3, 4 ..< 5])
        #expect(withoutAncestor.map(\.isReversed) == [true, false, false])
    }

    @Test("TA-319 HeavyLightDecomposition(F1, root: 0).segments(from: 6, to: 3) is [1..<4 R, 5..<6]")
    func f1SegmentsUpThenLight() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 6, to: 3)
        #expect(segments.map(\.positions) == [1 ..< 4, 5 ..< 6])
        #expect(segments.map(\.isReversed) == [true, false])
        // Computed with ref.py: without the ancestor 1, the low end of 1..<4 goes.
        let withoutAncestor = hld.segments(from: 6, to: 3, includingCommonAncestor: false)
        #expect(withoutAncestor.map(\.positions) == [2 ..< 4, 5 ..< 6])
        #expect(withoutAncestor.map(\.isReversed) == [true, false])
    }

    @Test("TA-320 HeavyLightDecomposition(F1, root: 0).segments(from: 0, to: 6) is [0..<4]: straight down one heavy path")
    func f1SegmentsDownHeavyPath() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 0, to: 6)
        #expect(segments.map(\.positions) == [0 ..< 4])
        #expect(segments.map(\.isReversed) == [false])
    }

    @Test("TA-321 HeavyLightDecomposition(F1, root: 0).segments(from: 0, to: 6, includingCommonAncestor: false) is [1..<4]")
    func f1SegmentsDownWithoutAncestor() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 0, to: 6, includingCommonAncestor: false)
        #expect(segments.map(\.positions) == [1 ..< 4])
        #expect(segments.map(\.isReversed) == [false])
    }

    @Test("TA-322 HeavyLightDecomposition(F1, root: 0).segments(from: 6, to: 0, includingCommonAncestor: false) is [1..<4 R]")
    func f1SegmentsUpWithoutAncestor() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 6, to: 0, includingCommonAncestor: false)
        #expect(segments.map(\.positions) == [1 ..< 4])
        #expect(segments.map(\.isReversed) == [true])
    }

    @Test("TA-323 HeavyLightDecomposition(F1, root: 0).segments(from: 7, to: 8, includingCommonAncestor: false) is [4..<5, 1..<3 R, 6..<9]")
    func f1SegmentsMiddleLosesAncestor() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 7, to: 8, includingCommonAncestor: false)
        #expect(segments.map(\.positions) == [4 ..< 5, 1 ..< 3, 6 ..< 9])
        #expect(segments.map(\.isReversed) == [false, true, false])
    }

    @Test("TA-324 HeavyLightDecomposition(F1, root: 0).segments(from: 3, to: 3) is [5..<6]")
    func f1SegmentsSameVertex() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 3, to: 3)
        #expect(segments.map(\.positions) == [5 ..< 6])
        #expect(segments.map(\.isReversed) == [false])
        // Computed with ref.py: a vertex on a heavy path, without itself, is no segment.
        #expect(hld.segments(from: 6, to: 6, includingCommonAncestor: false).isEmpty)
    }

    @Test("TA-325 HeavyLightDecomposition(F1, root: 0).segments(from: 3, to: 4, includingCommonAncestor: false) is [5..<6, 2..<3]: the ancestor's own segment disappears")
    func f1SegmentsAncestorAlone() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 3, to: 4, includingCommonAncestor: false)
        #expect(segments.map(\.positions) == [5 ..< 6, 2 ..< 3])
        #expect(segments.map(\.isReversed) == [false, false])
        // Computed with ref.py: with the ancestor, 1 and 4 share the root's heavy path.
        let withAncestor = hld.segments(from: 3, to: 4)
        #expect(withAncestor.map(\.positions) == [5 ..< 6, 1 ..< 3])
        #expect(withAncestor.map(\.isReversed) == [false, false])
        let back = hld.segments(from: 4, to: 3)
        #expect(back.map(\.positions) == [1 ..< 3, 5 ..< 6])
        #expect(back.map(\.isReversed) == [true, false])
    }

    @Test("TA-326 HeavyLightDecomposition(F1, root: 0).lowestCommonAncestor(of: 7, 8) is 0")
    func f1LCAAcrossRoot() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.lowestCommonAncestor(of: 7, 8) == 0)
    }

    @Test("TA-327 HeavyLightDecomposition(F1, root: 0).lowestCommonAncestor(of: 6, 7) is 4")
    func f1LCASiblings() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.lowestCommonAncestor(of: 6, 7) == 4)
    }

    @Test("TA-328 HeavyLightDecomposition(F1, root: 4).preorder is [4, 1, 0, 2, 5, 8, 3, 6, 7]: rerooted")
    func f1RerootedPreorder() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        let hld = HeavyLightDecomposition(rooted)
        #expect(Array(hld.preorder) == [4, 1, 0, 2, 5, 8, 3, 6, 7])
        // Computed with ref.py: the head of every vertex 0 … 8.
        let heads = (0 ... 8).map { hld.head(of: $0) }
        #expect(heads == [4, 4, 4, 3, 4, 4, 6, 7, 4])
    }

    @Test("TA-329 HeavyLightDecomposition(F1, root: 4).segments(from: 3, to: 8) is [6..<7, 1..<6]")
    func f1RerootedSegments() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 3, to: 8)
        #expect(segments.map(\.positions) == [6 ..< 7, 1 ..< 6])
        #expect(segments.map(\.isReversed) == [false, false])
        // Computed with ref.py: the reverse walk, and without the ancestor 1.
        let back = hld.segments(from: 8, to: 3)
        #expect(back.map(\.positions) == [1 ..< 6, 6 ..< 7])
        #expect(back.map(\.isReversed) == [true, false])
        let withoutAncestor = hld.segments(from: 3, to: 8, includingCommonAncestor: false)
        #expect(withoutAncestor.map(\.positions) == [6 ..< 7, 2 ..< 6])
        #expect(withoutAncestor.map(\.isReversed) == [false, false])
    }

    @Test("TA-330 HeavyLightDecomposition(S(0; 1..3), root: 0).heavyChild(of: 0) is 1: all children tie, the first")
    func starHeavyChild() throws {
        // U: [] S(0;1..3)
        let pairs = (1 ... 3).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        #expect(hld.heavyChild(of: 0) == 1)
    }

    @Test("TA-331 HeavyLightDecomposition(S(0; 1..3), root: 0).segments(from: 2, to: 3) is [2..<3, 0..<1, 3..<4]")
    func starSegments() throws {
        // U: [] S(0;1..3)
        let pairs = (1 ... 3).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 2, to: 3)
        #expect(segments.map(\.positions) == [2 ..< 3, 0 ..< 1, 3 ..< 4])
        // Three one-position segments: none reversed.
        #expect(segments.map(\.isReversed) == [false, false, false])
    }

    @Test("TA-332 HeavyLightDecomposition(Arborescence(NX)).segments(from: 4, to: 6) is [3..<4, 0..<2 R, 4..<5, 6..<7]")
    func arborescenceSegments() throws {
        // D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let hld = HeavyLightDecomposition(arborescence)
        let segments = hld.segments(from: 4, to: 6)
        #expect(segments.map(\.positions) == [3 ..< 4, 0 ..< 2, 4 ..< 5, 6 ..< 7])
        #expect(segments.map(\.isReversed) == [false, true, false, false])
        // Computed with ref.py.
        #expect(Array(hld.preorder) == [0, 1, 3, 4, 2, 5, 6])
        // The same as through the rooted tree.
        let viaRooted = HeavyLightDecomposition(RootedTree(arborescence))
        #expect(viaRooted.segments(from: 4, to: 6) == segments)
        #expect(Array(viaRooted.preorder) == Array(hld.preorder))
    }

    @Test("TA-333 HeavyLightDecomposition(kary(63, 2), root: 0).segments(from: 62, to: 31): light edges at every level")
    func completeBinarySegments() throws {
        // U: [] kary(63,2)
        let n = 63
        let pairs = (0 ..< n).flatMap { i in [2 * i + 1, 2 * i + 2].filter { $0 < n }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: 62, to: 31)
        #expect(segments.map(\.positions) == [62 ..< 63, 60 ..< 61, 56 ..< 57, 48 ..< 49, 32 ..< 33, 0 ..< 6])
        #expect(segments.map(\.isReversed) == [false, false, false, false, false, false])
        // Computed with ref.py: the reverse walk, and without the ancestor 0.
        let back = hld.segments(from: 31, to: 62)
        #expect(back.map(\.positions) == [0 ..< 6, 32 ..< 33, 48 ..< 49, 56 ..< 57, 60 ..< 61, 62 ..< 63])
        #expect(back.map(\.isReversed) == [true, false, false, false, false, false])
        let withoutAncestor = hld.segments(from: 62, to: 31, includingCommonAncestor: false)
        #expect(withoutAncestor.map(\.positions) == [62 ..< 63, 60 ..< 61, 56 ..< 57, 48 ..< 49, 32 ..< 33, 1 ..< 6])
    }

    @Test("TA-334 HeavyLightDecomposition(kary(63, 2), root: 0).segments(from: 62, to: 31).count is 6")
    func completeBinarySegmentCount() throws {
        // U: [] kary(63,2)
        let n = 63
        let pairs = (0 ..< n).flatMap { i in [2 * i + 1, 2 * i + 2].filter { $0 < n }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let count = hld.segments(from: 62, to: 31).count
        #expect(count == 6)
        // At most 2⌊log₂ n⌋ + 1 = 11.
        #expect(count <= 11)
    }

    @Test("TA-335 HeavyLightDecomposition(a-b, b-c, b-d, d-e; root: c).segments(from: a, to: e) is [4..<5, 1..<4]: String vertices")
    func stringSegments() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: "c"))
        let hld = HeavyLightDecomposition(rooted)
        let segments = hld.segments(from: "a", to: "e")
        #expect(segments.map(\.positions) == [4 ..< 5, 1 ..< 4])
        #expect(segments.map(\.isReversed) == [false, false])
        // Computed with ref.py.
        #expect(Array(hld.preorder) == ["c", "b", "d", "e", "a"])
        let back = hld.segments(from: "e", to: "a")
        #expect(back.map(\.positions) == [1 ..< 4, 4 ..< 5])
        #expect(back.map(\.isReversed) == [true, false])
        let withoutAncestor = hld.segments(from: "a", to: "e", includingCommonAncestor: false)
        #expect(withoutAncestor.map(\.positions) == [4 ..< 5, 2 ..< 4])
        #expect(withoutAncestor.map(\.isReversed) == [false, false])
    }

    @Test("F1 rooted at 0: the head, heavy child, position and subtree of every vertex")
    func f1EveryVertex() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8. Computed with ref.py.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let hld = HeavyLightDecomposition(rooted)
        let heads = (0 ... 8).map { hld.head(of: $0) }
        #expect(heads == [0, 0, 2, 3, 0, 2, 0, 7, 2])
        let heavyChildren = (0 ... 8).map { hld.heavyChild(of: $0) }
        #expect(heavyChildren == [1, 4, 5, nil, 6, 8, nil, nil, nil])
        let positions = (0 ... 8).map { hld.position(of: $0) }
        #expect(positions == [0, 1, 6, 5, 2, 7, 3, 4, 8])
        let subtrees = (0 ... 8).map { hld.subtree(of: $0) }
        #expect(subtrees == [0 ..< 9, 1 ..< 6, 6 ..< 9, 5 ..< 6, 2 ..< 5, 7 ..< 9, 3 ..< 4, 4 ..< 5, 8 ..< 9])
    }

    @Test("TA-317 – TA-325 F1 rooted at 0: every pair's segments expand to the tree's path, each inside one heavy path")
    func f1EveryPairExpands() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let tree = Tree(rooted)
        let hld = HeavyLightDecomposition(rooted)
        let order = Array(hld.preorder)
        for a in 0 ... 8 {
            for b in 0 ... 8 {
                let ancestor = rooted.lowestCommonAncestor(of: a, b)
                let path = tree.path(from: a, to: b).vertices
                for including in [true, false] {
                    let segments = hld.segments(from: a, to: b, includingCommonAncestor: including)
                    let expanded = segments.flatMap { $0.isReversed ? Array($0.positions.reversed()) : Array($0.positions) }
                    let expected = including ? path : path.filter { $0 != ancestor }
                    #expect(expanded.map { order[$0] } == expected, "(\(a), \(b), \(including))")
                    for segment in segments {
                        let heads = Set(segment.positions.map { hld.head(of: order[$0]) })
                        #expect(heads.count == 1, "(\(a), \(b)): \(segment.positions) spans heavy paths")
                        #expect(!segment.positions.isEmpty)
                        if segment.positions.count == 1 { #expect(!segment.isReversed) }
                    }
                }
            }
        }
    }
}
