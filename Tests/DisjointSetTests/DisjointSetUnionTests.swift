// `union(_:_:)`, `find(_:)` and `inSameSet(_:_:)`, with the cases of petgraph, JGraphT, Boost,
// NetworkX and LEMON translated to elements 0..<count. Representatives are exact: the rule is
// documented (the larger set's representative wins; for sets of the same size, the smaller one).
// Expected values come from the catalog's reference (`ref.py`, `cases.py`), which is
// cross-checked against scipy's and NetworkX's own implementations.
// Case IDs (DS-nn) refer to the catalog; see README.md.

import DisjointSetModule
import GrafluentTestSupport
import Testing

@Suite("DisjointSet union")
struct DisjointSetUnionTests {
    @Test("DS-08 union returns whether it merged, and is idempotent")
    func unionResult() {
        var d = DisjointSet(count: 4)
        #expect(d.setCount == 4)
        #expect(d.union(0, 1) == true)
        #expect(d.setCount == 3)
        #expect(d.union(0, 1) == false)
        #expect(d.setCount == 3)
        #expect(d.union(1, 0) == false)
        #expect(d.setCount == 3)
    }

    @Test("DS-09 inSameSet is transitive and symmetric")
    func transitivity() {
        var d = DisjointSet(count: 8)
        d.union(0, 1)
        #expect(d.inSameSet(0, 1) == true)
        d.union(1, 3)
        d.union(1, 4)
        d.union(4, 7)
        #expect(d.inSameSet(0, 7) == true)
        #expect(d.inSameSet(1, 3) == true)
        #expect(d.inSameSet(0, 2) == false)
        #expect(d.inSameSet(7, 0) == true)
        d.union(5, 6)
        #expect(d.inSameSet(6, 5) == true)
        #expect(d.inSameSet(6, 7) == false)
    }

    @Test("DS-10 petgraph uf_test, exact")
    func petgraphUnionFind() {
        var d = DisjointSet(count: 8)
        #expect(d.union(0, 1) == true)
        #expect(d.union(1, 3) == true)
        #expect(d.union(1, 4) == true)
        #expect(d.union(4, 7) == true)
        #expect(d.union(5, 6) == true)
        // Boost's or LEMON's tie rule (second argument wins) would give [1, 1, 2, 1, 1, 6, 6, 1].
        #expect((0 ..< 8).map { d.find($0) } == [0, 0, 2, 0, 0, 5, 5, 0])
        #expect(d.setCount == 3)
        #expect(d.sets() == [[0, 1, 3, 4, 7], [2], [5, 6]])
        #expect(d.labels() == [0, 0, 1, 0, 0, 2, 2, 0])
        #expect((0 ..< 8).map { d.setSize(of: $0) } == [5, 5, 1, 5, 5, 2, 2, 5])
    }

    @Test("DS-11 petgraph labeling: two chains joined")
    func petgraphLabeling() {
        var d = DisjointSet(count: 48)
        for i in 0 ..< 24 { d.union(i + 1, i) }
        for i in 25 ..< 47 { d.union(i, i + 1) }
        #expect(d.setCount == 2)
        #expect(Set((0 ..< 48).map { d.find($0) }) == [0, 25])
        #expect((0 ... 24).allSatisfy { d.find($0) == 0 })
        #expect((25 ..< 48).allSatisfy { d.find($0) == 25 })
        #expect(d.union(23, 25) == true)
        #expect(d.union(24, 23) == false)
        #expect(d.setCount == 1)
        #expect((0 ..< 48).allSatisfy { d.find($0) == 0 })
        #expect(d.labels() == Array(repeating: 0, count: 48))
    }

    @Test("DS-12 JGraphT testUnionFind, translated: the larger set wins, not the higher rank")
    func jgraphtUnionFind() {
        // "aaa" … "eee" become 0 … 4, their TreeSet order.
        var d = DisjointSet(count: 5)
        #expect(d.setCount == 5)
        #expect(d.union(0, 1) == true)
        #expect(d.setCount == 4)
        #expect(d.inSameSet(0, 1) == true)
        #expect(d.inSameSet(1, 2) == false)
        #expect(d.union(2, 3) == true)
        #expect(d.setCount == 3)
        #expect(d.union(2, 4) == true)
        #expect(d.setCount == 2)
        #expect(d.union(2, 4) == false)
        #expect(d.setCount == 2)
        #expect(d.union(0, 4) == true)
        #expect(d.setCount == 1)
        // {2, 3, 4} (size 3) absorbs {0, 1} (size 2). Union by rank would see equal ranks and give 0.
        #expect((0 ..< 5).map { d.find($0) } == [2, 2, 2, 2, 2])
        #expect(d.makeSet() == 5)
        #expect(d.setCount == 2)
        #expect(d.count == 6)
    }

    @Test("DS-13 Boost disjoint_set_test, translated")
    func boostDisjointSetTest() {
        var d = DisjointSet(count: 4)
        for a in 0 ..< 4 {
            for b in a + 1 ..< 4 { #expect(d.inSameSet(a, b) == false) }
        }
        d.union(0, 1)
        d.union(2, 3)
        #expect(d.find(0) != d.find(3))
        let a = d.find(0)
        let b = d.find(2)
        #expect(a == 0)
        #expect(d.find(1) == a)
        #expect(b == 2)
        #expect(d.find(3) == b)
        #expect(d.union(a, b) == true)
        #expect(d.inSameSet(a, b) == true)
        #expect(d.setCount == 1)
        #expect((0 ..< 4).map { d.find($0) } == [0, 0, 0, 0])
    }

    @Test("DS-14 Boost's documented example under Grafluent's rule")
    func boostExample() {
        var d = DisjointSet(count: 6)
        d.union(0, 1)
        d.union(1, 2)
        d.union(3, 4)
        // Boost prints 1 1 1 4 4 5: its tie goes to the second root.
        #expect((0 ..< 6).map { d.find($0) } == [0, 0, 0, 3, 3, 5])
        #expect(d.inSameSet(0, 2) == true)
        #expect(d.inSameSet(0, 5) == false)
        #expect(d.sets() == [[0, 1, 2], [3, 4], [5]])
    }

    @Test("DS-15 NetworkX test_subtree_union")
    func networkXSubtreeUnion() {
        var d = DisjointSet(count: 6) // 0 is unused
        d.union(1, 2)
        d.union(3, 4)
        d.union(4, 5)
        d.union(1, 5)
        #expect(d.sets() == [[0], [1, 2, 3, 4, 5]])
        #expect((0 ..< 6).map { d.find($0) } == [0, 3, 3, 3, 3, 3])
    }

    @Test("DS-16 NetworkX test_unbalanced_merge_weights: the larger set's representative wins")
    func networkXUnbalancedMerge() {
        var d = DisjointSet(count: 10)
        d.union(1, 2)
        d.union(2, 3)
        for i in 4 ..< 9 { d.union(i, i + 1) }
        #expect(d.setSize(of: 1) == 3)
        #expect(d.setSize(of: 4) == 6)
        #expect(d.find(4) == 4)
        #expect(d.union(1, 4) == true)
        #expect(d.find(1) == 4)
        #expect(d.setSize(of: 1) == 9)
        #expect((0 ..< 10).map { d.find($0) } == [0, 4, 4, 4, 4, 4, 4, 4, 4, 4])
    }

    @Test("DS-17 NetworkX test_unionfind_weights, variadic unions as chains")
    func networkXWeights() {
        var d = DisjointSet(count: 10)
        #expect(d.union(1, 4) == true)
        #expect(d.union(4, 7) == true)
        #expect(d.union(2, 5) == true)
        #expect(d.union(5, 8) == true)
        #expect(d.union(3, 6) == true)
        #expect(d.union(6, 9) == true)
        #expect(d.union(1, 2) == true)
        #expect(d.union(2, 3) == true)
        for i in 3 ..< 9 { #expect(d.union(i, i + 1) == false) }
        #expect(d.setSize(of: 1) == 9)
        #expect((0 ..< 10).map { d.find($0) } == [0, 1, 1, 1, 1, 1, 1, 1, 1, 1])
    }

    @Test("DS-18 LEMON unionfind_test, translated")
    func lemonUnionFind() {
        // Items 1 … 10, 0 unused; LEMON's insert(x, find(y)) becomes union(x, y).
        var d = DisjointSet(count: 11)
        #expect(d.union(1, 2) == true)
        #expect(d.union(1, 4) == true)
        #expect(d.union(2, 4) == false)
        #expect(d.union(3, 5) == true)
        d.union(8, 5)
        #expect([4, 5, 6, 2].map { d.setSize(of: $0) } == [3, 3, 1, 3])
        d.union(10, 9)
        #expect(d.union(8, 10) == true)
        #expect([4, 9, 8].map { d.setSize(of: $0) } == [3, 5, 5])
        #expect((0 ..< 11).map { d.find($0) } == [0, 1, 1, 3, 1, 3, 6, 7, 3, 3, 3])
        #expect(d.setCount == 5)
        #expect(d.sets() == [[0], [1, 2, 4], [3, 5, 8, 9, 10], [6], [7]])
    }
}
