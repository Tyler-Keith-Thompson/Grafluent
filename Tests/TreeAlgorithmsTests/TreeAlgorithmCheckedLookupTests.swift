// The `checked:` lookups of `HeavyLightDecomposition`,
// `LowestCommonAncestors` and the climbing `lowestCommonAncestor(checked:_:)` of `RootedTree` and
// `Arborescence`. Each throws `VertexNotFound` where its plain spelling traps (either argument of a
// two-vertex query), and otherwise returns the plain spelling's value, a leaf's nil heavy child
// included. F1 is `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` rooted at 0: dense `Int`
// vertices (a range check, negatives included); the named tree has more than 8 vertices (the hash
// table) and the small one at most 8 (a linear search). Case IDs (TA-nnn) refer to the catalog;
// see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees

@Suite("checked: lookups on tree algorithms")
struct TreeAlgorithmCheckedLookupTests {
    @Test("TA-1006 HeavyLightDecomposition's checked lookups match the plain ones on F1 and throw for a missing vertex")
    func heavyLight() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let hld = HeavyLightDecomposition(try #require(RootedTree(graph, root: 0)))
        for v in 0 ..< 9 {
            #expect(try hld.heavyChild(checked: v) == hld.heavyChild(of: v))
            #expect(try hld.head(checked: v) == hld.head(of: v))
            #expect(try hld.position(checked: v) == hld.position(of: v))
            #expect(try hld.subtree(checked: v) == hld.subtree(of: v))
            for w in 0 ..< 9 {
                #expect(try hld.lowestCommonAncestor(checked: v, w) == hld.lowestCommonAncestor(of: v, w))
                for including in [true, false] {
                    let checked = try hld.segments(checkedFrom: v, to: w, includingCommonAncestor: including)
                    let plain = hld.segments(from: v, to: w, includingCommonAncestor: including)
                    #expect(checked.map(\.positions) == plain.map(\.positions))
                    #expect(checked.map(\.isReversed) == plain.map(\.isReversed))
                }
            }
        }
        #expect(try hld.heavyChild(checked: 3) == nil)
        #expect(try hld.heavyChild(checked: 1) == 4)
        #expect(try hld.lowestCommonAncestor(checked: 6, 3) == 1)
        #expect(try hld.segments(checkedFrom: 3, to: 3).map(\.positions) == [hld.position(of: 3) ..< hld.position(of: 3) + 1])
        for missing in [9, -1] {
            #expect(throws: VertexNotFound()) { try hld.heavyChild(checked: missing) }
            #expect(throws: VertexNotFound()) { try hld.head(checked: missing) }
            #expect(throws: VertexNotFound()) { try hld.position(checked: missing) }
            #expect(throws: VertexNotFound()) { try hld.subtree(checked: missing) }
            #expect(throws: VertexNotFound()) { try hld.lowestCommonAncestor(checked: missing, 0) }
            #expect(throws: VertexNotFound()) { try hld.lowestCommonAncestor(checked: 0, missing) }
            #expect(throws: VertexNotFound()) { try hld.segments(checkedFrom: missing, to: 0) }
            #expect(throws: VertexNotFound()) { try hld.segments(checkedFrom: 0, to: missing, includingCommonAncestor: false) }
        }
    }

    @Test("TA-1007 LowestCommonAncestors' checked lookups match the plain ones and throw for a missing vertex, on F1 and a named tree")
    func lowestCommonAncestors() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let lca = LowestCommonAncestors(try #require(RootedTree(graph, root: 0)))
        for v in 0 ..< 9 {
            for w in 0 ..< 9 {
                #expect(try lca.lowestCommonAncestor(checked: v, w) == lca.lowestCommonAncestor(of: v, w))
                #expect(try lca.distance(checkedFrom: v, to: w) == lca.distance(from: v, to: w))
            }
        }
        #expect(try lca.lowestCommonAncestor(checked: 7, 8) == 0)
        #expect(try lca.distance(checkedFrom: 7, to: 8) == 6)
        for (a, b) in [(9, 0), (0, 9), (-1, 3), (3, -1)] {
            #expect(throws: VertexNotFound()) { try lca.lowestCommonAncestor(checked: a, b) }
            #expect(throws: VertexNotFound()) { try lca.distance(checkedFrom: a, to: b) }
        }

        // A star of 10 named vertices under "hub": past the small-tree limit, so a hash table.
        let names = (0 ..< 9).map { "leaf\($0)" }
        let star = try #require(Arborescence(edges: names.map { DirectedEdge(from: "hub", to: $0) }))
        let named = LowestCommonAncestors(star)
        #expect(try named.lowestCommonAncestor(checked: "leaf1", "leaf7") == "hub")
        #expect(try named.distance(checkedFrom: "leaf1", to: "hub") == 1)
        #expect(throws: VertexNotFound()) { try named.lowestCommonAncestor(checked: "leaf1", "nowhere") }
        #expect(throws: VertexNotFound()) { try named.distance(checkedFrom: "nowhere", to: "hub") }
    }

    @Test("TA-1008 RootedTree and Arborescence lowestCommonAncestor(checked:_:) match the plain climb and throw for a missing vertex")
    func climbing() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        let arborescence = Arborescence(rooted)
        for v in 0 ..< 9 {
            for w in 0 ..< 9 {
                #expect(try rooted.lowestCommonAncestor(checked: v, w) == rooted.lowestCommonAncestor(of: v, w))
                #expect(try arborescence.lowestCommonAncestor(checked: v, w) == arborescence.lowestCommonAncestor(of: v, w))
            }
        }
        #expect(try rooted.lowestCommonAncestor(checked: 3, 8) == 1)
        #expect(try arborescence.lowestCommonAncestor(checked: 6, 7) == 4)
        for (a, b) in [(9, 0), (0, 9), (-1, -1)] {
            #expect(throws: VertexNotFound()) { try rooted.lowestCommonAncestor(checked: a, b) }
            #expect(throws: VertexNotFound()) { try arborescence.lowestCommonAncestor(checked: a, b) }
        }

        // At most 8 named vertices: a linear search.
        let small = try #require(Arborescence(edges: [DirectedEdge(from: "r", to: "x"), DirectedEdge(from: "r", to: "y"), DirectedEdge(from: "x", to: "z")]))
        #expect(try small.lowestCommonAncestor(checked: "z", "y") == "r")
        #expect(try RootedTree(small).lowestCommonAncestor(checked: "z", "x") == "x")
        #expect(throws: VertexNotFound()) { try small.lowestCommonAncestor(checked: "z", "w") }
        #expect(throws: VertexNotFound()) { try RootedTree(small).lowestCommonAncestor(checked: "w", "z") }
    }
}
