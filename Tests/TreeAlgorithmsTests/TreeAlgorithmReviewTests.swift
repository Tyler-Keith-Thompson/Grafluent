// Cases added after the review: floating-point weights whose sums differ by summation order
// (diameterPath used to look one sum up in the other and trap), all-zero weights, the centroid
// decomposition of a tree rooted away from vertex 0, lowest common ancestors at sizes that reach
// the sparse table's higher levels, and the index-space forms. Case IDs (TA-nnn) refer to the
// catalog; see README.md.

import GraphProtocols
import Testing
import TreeAlgorithms
import Trees
import Walks

@Suite("TreeAlgorithms review cases")
struct TreeAlgorithmReviewTests {
    @Test("TA-1001 diameterPath(weight:) with 0.1, 0.2, 0.3: the path and its own sum, no trap")
    func inexactDoubles() throws {
        let tree = try #require(Tree(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)]))
        let weights = [0.1, 0.2, 0.3]
        let (path, distance) = tree.diameterPath { weights[$0] }
        #expect(path.vertices == [0, 1, 2, 3] || path.vertices == [3, 2, 1, 0])
        #expect(distance == path.edges.map { weights[$0] }.reduce(0, +) || abs(distance - 0.6) < 1e-12)
        #expect(abs(tree.diameter { weights[$0] } - 0.6) < 1e-12)
    }

    @Test("TA-1002 all-zero weights: the trivial diameter path at the first vertex, every vertex a center")
    func zeroWeights() throws {
        let tree = try #require(Tree(vertices: [5, 6, 7], edges: [UndirectedEdge(5, 6), UndirectedEdge(6, 7)]))
        let (path, distance) = tree.diameterPath { _ in 0 }
        #expect(path.vertices == [5] && distance == 0)
        #expect(tree.center { _ in 0.0 } == [5, 6, 7])
        #expect(tree.diameter { _ in 0 } == 0)
    }

    @Test("TA-1003 a tree rooted away from vertex 0 gives the same measures and decomposition")
    func nonZeroRoot() throws {
        let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(2, 5), UndirectedEdge(5, 6)]
        let plain = try #require(Tree(vertices: 0 ..< 7, edges: edges))
        let rerooted = Tree(RootedTree(plain, root: 6))
        #expect(rerooted.centroidDecomposition() == plain.centroidDecomposition())
        #expect(rerooted.center() == plain.center())
        #expect(rerooted.centroid() == plain.centroid())
        #expect(rerooted.diameterPath().vertices == plain.diameterPath().vertices)
        #expect(plain.centroidDecomposition().root == plain.centroid()[0])
    }

    @Test("TA-1004 lowest common ancestors on random trees of 1000 – 5000 vertices agree with climbing", arguments: [1000, 2049, 5000])
    func largeRandom(n: Int) throws {
        var state: UInt64 = UInt64(n) &* 0x9E37_79B9_7F4A_7C15
        func next(_ bound: Int) -> Int {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((state >> 33) % UInt64(bound))
        }
        // Parents a short hop or a long jump back, so the tree is deep in places and bushy in others.
        let parents: [Int?] = (0 ..< n).map { i in i == 0 ? nil : (next(2) == 0 ? i - 1 - next(min(i, 3)) : next(i)) }
        let rooted = try #require(RootedTree(parents: parents))
        let lca = LowestCommonAncestors(rooted)
        let hld = HeavyLightDecomposition(rooted)
        for _ in 0 ..< 4000 {
            let a = next(n), b = next(n)
            let expected = rooted.lowestCommonAncestor(of: a, b)
            #expect(lca.lowestCommonAncestor(of: a, b) == expected)
            #expect(lca.lowestCommonAncestor(ofIndex: a, b) == expected)
            #expect(hld.lowestCommonAncestor(ofIndex: a, b) == expected)
            #expect(rooted.lowestCommonAncestor(ofIndex: a, b) == expected)
            let length = rooted.path(from: a, to: b).length
            #expect(lca.distance(from: a, to: b) == length)
        }
    }

    @Test("TA-1005 the heavy–light index forms agree with the vertex forms")
    func indexForms() throws {
        // Vertices whose values are not their indices.
        let tree = try #require(Tree(vertices: [40, 10, 30, 20, 50], edges: [UndirectedEdge(40, 10), UndirectedEdge(10, 30), UndirectedEdge(40, 20), UndirectedEdge(20, 50)]))
        let rooted = RootedTree(tree, root: 40)
        let hld = HeavyLightDecomposition(rooted)
        for (i, v) in tree.vertices.enumerated() {
            #expect(tree.vertex(atIndex: hld.head(ofIndex: i)) == hld.head(of: v))
            #expect(hld.heavyChild(ofIndex: i).map { tree.vertex(atIndex: $0) } == hld.heavyChild(of: v))
            #expect(hld.subtree(ofIndex: i) == hld.subtree(of: v))
            #expect(hld.vertexIndex(atPosition: hld.position(ofIndex: i)) == i)
            for (j, w) in tree.vertices.enumerated() {
                #expect(hld.segments(fromIndex: i, toIndex: j) == hld.segments(from: v, to: w))
                #expect(hld.segments(fromIndex: i, toIndex: j, includingCommonAncestor: false) == hld.segments(from: v, to: w, includingCommonAncestor: false))
            }
        }
    }
}
