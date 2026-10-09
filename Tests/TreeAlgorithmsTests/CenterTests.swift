// §E: `Tree.center()` and `Tree.center(weight:)`, the vertices of least eccentricity in
// `vertices` order (TA-412: `[4, 2]`, where sorting the values would give `[2, 4]`). Unweighted
// and with positive weights it is one vertex or two adjacent ones; with zero weights any number
// (TA-415, TA-416). The weight closure maps edge positions to any `Comparable &
// AdditiveArithmetic` type and is called once per edge, in position order, never on K₁
// (TA-423). Catalog rows with `Int` weights are repeated with the same weights as `Double`, and
// `-0.0` (which is not below `.zero`) counts as a zero weight. Sources are written on the
// `ReferencePseudograph` as the catalog writes them. Literals are catalog cells (computed by
// `ref.py`, checked against brute-force distances and NetworkX 3.7's `tree.center` and
// `center(weight=)`) or, for the `Double` and `-0.0` repeats, computed with the same reference.
// TA-421 and TA-422 (negative, NaN) are exit tests in `TreeAlgorithmPreconditionTests.swift`.
// Case IDs (TA-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees

@Suite("Center")
struct CenterTests {
    @Test("TA-401 Tree(K₁).center() is [0]")
    func singleVertex() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [0])
    }

    @Test("TA-402 Tree(K₂).center() is [0, 1]: both ends")
    func edge() throws {
        // U: [] 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [0, 1])
    }

    @Test("TA-403 Tree(1-2, 1-3, 2-4, 2-5).center() is [1, 2]: NetworkX's simple tree")
    func networkXSimpleTree() throws {
        // U: [] 1-2, 1-3, 2-4, 2-5
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 4), (2, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [1, 2])
    }

    @Test("TA-404 Tree(P(0..4)).center() is [2]")
    func pathOfFive() throws {
        // U: [] P(0..4)
        let pairs = (0 ..< 4).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [2])
    }

    @Test("TA-405 Tree(P(0..98)).center() is [49]")
    func pathOf99() throws {
        // U: [] P(0..98)
        let pairs = (0 ..< 98).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [49])
    }

    @Test("TA-406 Tree(P(0..99)).center() is [49, 50]: two")
    func pathOf100() throws {
        // U: [] P(0..99)
        let pairs = (0 ..< 99).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [49, 50])
    }

    @Test("TA-407 Tree(S(0; 1..5)).center() is [0]")
    func star() throws {
        // U: [] S(0;1..5)
        let pairs = (1 ... 5).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [0])
    }

    @Test("TA-408 Tree(kary(40, 3)).center() is [0]: balanced_tree(3, 3)")
    func balancedTernary() throws {
        // U: [] kary(40,3)
        let n = 40
        let pairs = (0 ..< n).flatMap { i in [3 * i + 1, 3 * i + 2, 3 * i + 3].filter { $0 < n }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [0])
    }

    @Test("TA-409 Tree(S(0; 1..6), P(6, 7, 8, 9, 10)).center() is [7]: not the centroid (TA-506)")
    func starWithLongBranch() throws {
        // U: [] S(0;1..6), P(6,7,8,9,10)
        let pairs = (1 ... 6).map { (0, $0) } + (6 ..< 10).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [7])
        #expect(tree.centroid() == [0])
    }

    @Test("TA-410 Tree(F1).center() is [0]")
    func f1() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.center() == [0])
        // Computed with ref.py: F1b, the same edges in another order, the same center.
        let reordered: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let f1b = try #require(Tree(vertices: 0 ... 8, edges: reordered.map { UndirectedEdge($0.0, $0.1) }))
        #expect(f1b.center() == [0])
    }

    @Test("TA-411 Tree(a-b, b-c, b-d, d-e).center() is [b, d]: two centers")
    func stringVertices() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.center() == ["b", "d"])
    }

    @Test("TA-412 Tree([4, 2, 7, 1]; 7-2, 2-4, 4-1).center() is [4, 2]: vertices order, not value order")
    func vertexOrderNotValueOrder() throws {
        // U: [4, 2, 7, 1] 7-2, 2-4, 4-1
        let pairs: [(Int, Int)] = [(7, 2), (2, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: [4, 2, 7, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(tree.vertices) == [4, 2, 7, 1])
        #expect(tree.center() == [4, 2])
    }

    @Test("TA-413 Tree(P(0..4)).center(weight: [1, 1, 1, 10]) is [3]: a heavy end edge moves the center")
    func heavyEndEdge() throws {
        // U: [] P(0..4)
        let pairs = (0 ..< 4).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [1, 1, 1, 10]
        #expect(tree.center(weight: { w[$0] }) == [3])
        // Computed with ref.py: the same weights as Double.
        let d: [Double] = [1, 1, 1, 10]
        #expect(tree.center(weight: { d[$0] }) == [3])
    }

    @Test("TA-414 Tree(K₂).center(weight: [5]) is [0, 1]")
    func weightedEdge() throws {
        // U: [] 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let tree = try #require(Tree(graph))
        let w = [5]
        #expect(tree.center(weight: { w[$0] }) == [0, 1])
        // Computed with ref.py: as Double.
        let d: [Double] = [5]
        #expect(tree.center(weight: { d[$0] }) == [0, 1])
    }

    @Test("TA-415 Tree(P(0..2)).center(weight: [0, 0]) is [0, 1, 2]: all zero, every eccentricity 0")
    func allZeroWeights() throws {
        // U: [] P(0..2)
        let pairs = (0 ..< 2).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [0, 0]
        #expect(tree.center(weight: { w[$0] }) == [0, 1, 2])
        // Computed with ref.py: as Double, and with −0.0, which is not below .zero.
        let d: [Double] = [0, 0]
        #expect(tree.center(weight: { d[$0] }) == [0, 1, 2])
        let negativeZero: [Double] = [-0.0, -0.0]
        #expect(tree.center(weight: { negativeZero[$0] }) == [0, 1, 2])
    }

    @Test("TA-416 Tree(P(0..3)).center(weight: [0, 1, 0]) is [0, 1, 2, 3]: zero end edges, four centers")
    func zeroEndEdges() throws {
        // U: [] P(0..3)
        let pairs = (0 ..< 3).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [0, 1, 0]
        #expect(tree.center(weight: { w[$0] }) == [0, 1, 2, 3])
        // Computed with ref.py: as Double.
        let d: [Double] = [0, 1, 0]
        #expect(tree.center(weight: { d[$0] }) == [0, 1, 2, 3])
    }

    @Test("TA-417 Tree(P(0..3)).center(weight: [1, 0, 1]) is [1, 2]")
    func zeroMiddleEdge() throws {
        // U: [] P(0..3)
        let pairs = (0 ..< 3).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [1, 0, 1]
        #expect(tree.center(weight: { w[$0] }) == [1, 2])
        // Computed with ref.py: as Double.
        let d: [Double] = [1, 0, 1]
        #expect(tree.center(weight: { d[$0] }) == [1, 2])
    }

    @Test("TA-418 Tree(S(0; 1..4)).center(weight: [3, 1, 3, 2]) is [0]")
    func weightedStar() throws {
        // U: [] S(0;1..4)
        let pairs = (1 ... 4).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [3, 1, 3, 2]
        #expect(tree.center(weight: { w[$0] }) == [0])
        // Computed with ref.py: as Double.
        let d: [Double] = [3, 1, 3, 2]
        #expect(tree.center(weight: { d[$0] }) == [0])
    }

    @Test("TA-419 Tree(S(0; 1..4)).center(weight: [3, 1, 30, 2]) is [0]: one long spoke, the hub stays")
    func longSpoke() throws {
        // U: [] S(0;1..4)
        let pairs = (1 ... 4).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [3, 1, 30, 2]
        #expect(tree.center(weight: { w[$0] }) == [0])
        // Computed with ref.py: as Double.
        let d: [Double] = [3, 1, 30, 2]
        #expect(tree.center(weight: { d[$0] }) == [0])
    }

    @Test("TA-420 Tree(P(0..3)).center(weight: [0.5, 0.25, 0.75]) is [2]: floating-point weights")
    func doubleWeights() throws {
        // U: [] P(0..3)
        let pairs = (0 ..< 3).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [0.5, 0.25, 0.75]
        #expect(tree.center(weight: { w[$0] }) == [2])
    }

    @Test("TA-423 Tree(K₁).center(weight:) is [0]: the closure is never called")
    func singleVertexWeighted() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let tree = try #require(Tree(graph))
        var calls = 0
        let center = tree.center(weight: { (_: Int) -> Int in
            calls += 1
            return 1
        })
        #expect(center == [0])
        #expect(calls == 0)
    }

    @Test("center(weight:) calls the closure once per edge, in position order")
    func weightCallOrder() throws {
        // U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5 (F1b): positions not in vertex order.
        let pairs: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        var calls: [Int] = []
        let center = tree.center(weight: { (e: Int) -> Int in
            calls.append(e)
            return 1
        })
        #expect(calls == Array(0 ..< 8))
        // Unit weights: the unweighted answer.
        #expect(center == tree.center())
    }

    @Test("TA-410 Tree(F1).center(weight: [5, 1, 1, 1, 1, 1, 1, 1]) is [0]")
    func f1Weighted() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8. Computed with ref.py.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [5, 1, 1, 1, 1, 1, 1, 1]
        #expect(tree.center(weight: { w[$0] }) == [0])
    }
}
