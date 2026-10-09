// §G: `diameter()`, `diameter(weight:)`, `diameterPath()` and `diameterPath(weight:)`. The
// diameter is the greatest eccentricity, 0 for one vertex. The path joins the lexicographically
// least pair (u, v), by vertex index, at that distance: u the first vertex in `vertices` order of
// greatest eccentricity, v the first vertex farthest from u (TA-604: `vertices` = [1, 0] starts at
// 1; TA-607: a star's leaves 1 and 2). When the diameter is zero (one vertex, or every weight
// zero) it is the trivial path at `vertices[0]` (TA-617); with zero weights it is not the path
// with the most edges (TA-618). The weighted forms return `(path, distance)` as
// `dijkstraShortestPath` does, call the closure once per edge in position order, and never call
// it on K₁ (TA-622). Catalog rows with `Int` weights are repeated with the same weights as
// `Double`. Sources are written on the `ReferencePseudograph` as the catalog writes them.
// Literals are catalog cells, computed by `ref.py` and checked by brute force over all pairs and
// against NetworkX 3.7's `diameter`, or, for the `Double` and `-0.0` repeats and the few extra
// rows, computed with the same reference. TA-620 and TA-621 (negative, NaN) are exit tests in
// `TreeAlgorithmPreconditionTests.swift`. Case IDs (TA-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees
import Walks

@Suite("Diameter")
struct DiameterTests {
    @Test("TA-601 Tree(K₁).diameter() is 0")
    func singleVertex() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let tree = try #require(Tree(graph))
        #expect(tree.diameter() == 0)
    }

    @Test("TA-602 Tree(K₁).diameterPath() is the trivial path [0]")
    func singleVertexPath() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let tree = try #require(Tree(graph))
        let path = tree.diameterPath()
        #expect(path.vertices == [0])
        #expect(path.edges == [])
        #expect(path.isTrivial)
    }

    @Test("TA-603 Tree(K₂).diameterPath() is [0, 1] / [0]")
    func edgePath() throws {
        // U: [] 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let tree = try #require(Tree(graph))
        let path = tree.diameterPath()
        #expect(path.vertices == [0, 1])
        #expect(path.edges == [0])
    }

    @Test("TA-604 Tree(1-0).diameterPath() is [1, 0] / [0]: vertices = [1, 0], the path starts at 1")
    func edgeListedBackwards() throws {
        // U: [] 1-0
        let graph = ReferencePseudograph(edges: [UndirectedEdge(1, 0)])
        let tree = try #require(Tree(graph))
        #expect(Array(tree.vertices) == [1, 0])
        let path = tree.diameterPath()
        #expect(path.vertices == [1, 0])
        #expect(path.edges == [0])
    }

    @Test("TA-605 Tree(P(0..9)).diameter() is 9")
    func pathOfTen() throws {
        // U: [] P(0..9)
        let pairs = (0 ..< 9).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.diameter() == 9)
    }

    @Test("TA-606 Tree(P(0..9)).diameterPath() runs from the first end")
    func pathOfTenPath() throws {
        // U: [] P(0..9)
        let pairs = (0 ..< 9).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.diameterPath()
        #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(path.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8])
    }

    @Test("TA-607 Tree(S(0; 1..5)).diameterPath() is [1, 0, 2] / [0, 1]: of many diametral pairs, leaves 1 and 2")
    func starPath() throws {
        // U: [] S(0;1..5)
        let pairs = (1 ... 5).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.diameterPath()
        #expect(path.vertices == [1, 0, 2])
        #expect(path.edges == [0, 1])
    }

    @Test("TA-608 Tree(F1).diameter() is 6")
    func f1() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.diameter() == 6)
    }

    @Test("TA-609 Tree(F1).diameterPath(): 6 is the first peripheral vertex, 8 the first farthest from it")
    func f1Path() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.diameterPath()
        #expect(path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(path.edges == [5, 3, 0, 1, 4, 7])
        #expect(path.length == tree.diameter())
        // The tree's own path between the ends.
        #expect(path == tree.path(from: 6, to: 8))
    }

    @Test("TA-610 Tree(F1b).diameterPath(): the same vertices, other edge positions")
    func f1bPath() throws {
        // U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5
        let pairs: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.diameterPath()
        #expect(path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(path.edges == [5, 2, 4, 1, 7, 3])
    }

    @Test("TA-611 Tree(a-b, b-c, b-d, d-e).diameterPath() is [a, b, d, e] / [0, 2, 3]")
    func stringPath() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.diameterPath()
        #expect(path.vertices == ["a", "b", "d", "e"])
        #expect(path.edges == [0, 2, 3])
    }

    @Test("TA-612 Tree(S(0; 1..6), P(6, 7, 8, 9, 10)).diameterPath() is [1, 0, 6, 7, 8, 9, 10]")
    func starWithLongBranchPath() throws {
        // U: [] S(0;1..6), P(6,7,8,9,10)
        let pairs = (1 ... 6).map { (0, $0) } + (6 ..< 10).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.diameterPath()
        #expect(path.vertices == [1, 0, 6, 7, 8, 9, 10])
        #expect(path.edges == [0, 5, 6, 7, 8, 9])
        // Computed with ref.py.
        #expect(tree.diameter() == 6)
    }

    @Test("TA-613 Tree(kary(40, 3)).diameter() is 6: balanced_tree(3, 3)")
    func balancedTernary() throws {
        // U: [] kary(40,3)
        let n = 40
        let pairs = (0 ..< n).flatMap { i in [3 * i + 1, 3 * i + 2, 3 * i + 3].filter { $0 < n }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.diameter() == 6)
    }

    @Test("TA-614 Tree(P(0..4)).diameter(weight: [1, 1, 1, 10]) is 13")
    func weightedPath() throws {
        // U: [] P(0..4)
        let pairs = (0 ..< 4).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [1, 1, 1, 10]
        #expect(tree.diameter(weight: { w[$0] }) == 13)
        let d: [Double] = [1, 1, 1, 10]
        #expect(tree.diameter(weight: { d[$0] }) == 13)
    }

    @Test("TA-615 Tree(P(0..4)).diameterPath(weight: [1, 1, 1, 10]) is [0, 1, 2, 3, 4] / [0, 1, 2, 3], 13")
    func weightedPathPath() throws {
        // U: [] P(0..4)
        let pairs = (0 ..< 4).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [1, 1, 1, 10]
        let result = tree.diameterPath(weight: { w[$0] })
        #expect(result.path.vertices == [0, 1, 2, 3, 4])
        #expect(result.path.edges == [0, 1, 2, 3])
        #expect(result.distance == 13)
        // Computed with ref.py: as Double.
        let d: [Double] = [1, 1, 1, 10]
        let doubled = tree.diameterPath(weight: { d[$0] })
        #expect(doubled.path.vertices == [0, 1, 2, 3, 4])
        #expect(doubled.distance == 13)
    }

    @Test("TA-616 Tree(S(0; 1..4)).diameterPath(weight: [3, 1, 3, 2]) is [1, 0, 3] / [0, 2], 6: weights pick the spokes")
    func weightedStarPath() throws {
        // U: [] S(0;1..4)
        let pairs = (1 ... 4).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [3, 1, 3, 2]
        let result = tree.diameterPath(weight: { w[$0] })
        #expect(result.path.vertices == [1, 0, 3])
        #expect(result.path.edges == [0, 2])
        #expect(result.distance == 6)
        // Computed with ref.py: as Double; and with the long spoke of TA-419.
        let d: [Double] = [3, 1, 3, 2]
        let doubled = tree.diameterPath(weight: { d[$0] })
        #expect(doubled.path.vertices == [1, 0, 3])
        #expect(doubled.distance == 6)
        let long = [3, 1, 30, 2]
        let longResult = tree.diameterPath(weight: { long[$0] })
        #expect(longResult.path.vertices == [1, 0, 3])
        #expect(longResult.distance == 33)
        #expect(tree.diameter(weight: { long[$0] }) == 33)
    }

    @Test("TA-617 Tree(P(0..2)).diameterPath(weight: [0, 0]) is the trivial path at vertices[0], 0")
    func allZeroWeights() throws {
        // U: [] P(0..2)
        let pairs = (0 ..< 2).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [0, 0]
        let result = tree.diameterPath(weight: { w[$0] })
        #expect(result.path.vertices == [0])
        #expect(result.path.edges == [])
        #expect(result.distance == 0)
        // Computed with ref.py.
        #expect(tree.diameter(weight: { w[$0] }) == 0)
        // Computed with ref.py: as Double, and with −0.0.
        let d: [Double] = [0, 0]
        let doubled = tree.diameterPath(weight: { d[$0] })
        #expect(doubled.path.vertices == [0])
        #expect(doubled.distance == 0)
        let negativeZero: [Double] = [-0.0, -0.0]
        let signed = tree.diameterPath(weight: { negativeZero[$0] })
        #expect(signed.path.vertices == [0])
        #expect(signed.distance == 0)
    }

    @Test("TA-618 Tree(P(0..3)).diameterPath(weight: [0, 1, 0]) is [0, 1, 2] / [0, 1], 1: not the path with most edges")
    func zeroEndEdges() throws {
        // U: [] P(0..3)
        let pairs = (0 ..< 3).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [0, 1, 0]
        let result = tree.diameterPath(weight: { w[$0] })
        #expect(result.path.vertices == [0, 1, 2])
        #expect(result.path.edges == [0, 1])
        #expect(result.distance == 1)
        // Computed with ref.py.
        #expect(tree.diameter(weight: { w[$0] }) == 1)
        let d: [Double] = [0, 1, 0]
        let doubled = tree.diameterPath(weight: { d[$0] })
        #expect(doubled.path.vertices == [0, 1, 2])
        #expect(doubled.path.edges == [0, 1])
        #expect(doubled.distance == 1)
    }

    @Test("TA-619 Tree(P(0..3)).diameter(weight: [0.5, 0.25, 0.75]) is 1.5: floating point")
    func doubleWeights() throws {
        // U: [] P(0..3)
        let pairs = (0 ..< 3).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [0.5, 0.25, 0.75]
        #expect(tree.diameter(weight: { w[$0] }) == 1.5)
        // Computed with ref.py.
        let result = tree.diameterPath(weight: { w[$0] })
        #expect(result.path.vertices == [0, 1, 2, 3])
        #expect(result.path.edges == [0, 1, 2])
        #expect(result.distance == 1.5)
    }

    @Test("TA-622 Tree(K₁).diameterPath(weight:) is the trivial path [0], 0: the closure is never called")
    func singleVertexWeighted() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let tree = try #require(Tree(graph))
        var calls = 0
        let result = tree.diameterPath(weight: { (_: Int) -> Int in
            calls += 1
            return 1
        })
        #expect(result.path.vertices == [0])
        #expect(result.path.edges == [])
        #expect(result.distance == 0)
        let diameter = tree.diameter(weight: { (_: Int) -> Double in
            calls += 1
            return 1
        })
        #expect(diameter == 0)
        #expect(calls == 0)
    }

    @Test("TA-623 Tree(F1).diameterPath(weight: all 1) equals the unweighted answer (TA-609), 6")
    func unitWeights() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [1, 1, 1, 1, 1, 1, 1, 1]
        let result = tree.diameterPath(weight: { w[$0] })
        #expect(result.path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(result.path.edges == [5, 3, 0, 1, 4, 7])
        #expect(result.distance == 6)
        #expect(result.path == tree.diameterPath())
    }

    @Test("TA-624 Tree(F1).diameterPath(weight: [5, 1, 1, 1, 1, 1, 1, 1]) is the same path, 10")
    func heavyRootEdge() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let w = [5, 1, 1, 1, 1, 1, 1, 1]
        let result = tree.diameterPath(weight: { w[$0] })
        #expect(result.path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(result.path.edges == [5, 3, 0, 1, 4, 7])
        #expect(result.distance == 10)
        // The distance is the path's weight.
        #expect(result.path.weight { w[$0] } == 10)
        // Computed with ref.py: as Double.
        let d: [Double] = [5, 1, 1, 1, 1, 1, 1, 1]
        let doubled = tree.diameterPath(weight: { d[$0] })
        #expect(doubled.path.vertices == [6, 4, 1, 0, 2, 5, 8])
        #expect(doubled.distance == 10)
    }

    @Test("TA-412's tree: diameterPath() starts at vertices[2] = 7, the first peripheral vertex in vertices order")
    func vertexOrderNotValueOrder() throws {
        // U: [4, 2, 7, 1] 7-2, 2-4, 4-1. Computed with ref.py.
        let pairs: [(Int, Int)] = [(7, 2), (2, 4), (4, 1)]
        let graph = ReferencePseudograph(vertices: [4, 2, 7, 1], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.diameterPath()
        #expect(path.vertices == [7, 2, 4, 1])
        #expect(path.edges == [0, 1, 2])
    }

    @Test("diameter(weight:) and diameterPath(weight:) call the closure once per edge, in position order")
    func weightCallOrder() throws {
        // U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5 (F1b)
        let pairs: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        var calls: [Int] = []
        let diameter = tree.diameter(weight: { (e: Int) -> Int in
            calls.append(e)
            return 1
        })
        #expect(calls == Array(0 ..< 8))
        #expect(diameter == tree.diameter())
        calls = []
        let result = tree.diameterPath(weight: { (e: Int) -> Int in
            calls.append(e)
            return 1
        })
        #expect(calls == Array(0 ..< 8))
        #expect(result.path == tree.diameterPath())
    }
}
