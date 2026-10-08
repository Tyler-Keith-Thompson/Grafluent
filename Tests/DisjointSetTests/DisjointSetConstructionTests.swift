// Construction and growth: the empty value, singletons, self-unions, `reserveCapacity(_:)` and
// `makeSet()`. Expected values come from the catalog's reference (`ref.py`, `cases.py`), which is
// cross-checked against scipy's and NetworkX's own implementations.
// Case IDs (DS-nn) refer to the catalog; see README.md.

import DisjointSetModule
import GrafluentTestSupport
import Testing

@Suite("DisjointSet construction")
struct DisjointSetConstructionTests {
    @Test("DS-01 the empty disjoint set")
    func empty() {
        let d = DisjointSet()
        #expect(d.count == 0)
        #expect(d.isEmpty)
        #expect(d.setCount == 0)
        #expect(d.sets() == [])
        #expect(d.labels() == [])
        #expect(d.description == "[]")
    }

    @Test("DS-02 init(count: 0) is the empty value, and one element is its own set")
    func zeroAndOne() {
        #expect(DisjointSet(count: 0) == DisjointSet())
        #expect(DisjointSet(count: 0).isEmpty)

        var d = DisjointSet(count: 1)
        #expect(!d.isEmpty)
        #expect(d.count == 1)
        #expect(d.find(0) == 0)
        #expect(d.setSize(of: 0) == 1)
        #expect(d.inSameSet(0, 0) == true)
        #expect(d.union(0, 0) == false)
        #expect(d.setCount == 1)
        #expect(d.sets() == [[0]])
        #expect(d.labels() == [0])
    }

    @Test("DS-03 init(count:) is the discrete partition")
    func discrete() {
        var d = DisjointSet(count: 8)
        #expect(d.count == 8)
        #expect(d.setCount == 8)
        #expect((0 ..< 8).map { d.find($0) } == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect((0 ..< 8).map { d.setSize(of: $0) } == [1, 1, 1, 1, 1, 1, 1, 1])
        #expect(d.sets() == [[0], [1], [2], [3], [4], [5], [6], [7]])
        #expect(d.labels() == [0, 1, 2, 3, 4, 5, 6, 7])
    }

    @Test("DS-04 self-unions change nothing")
    func selfUnions() {
        var d = DisjointSet(count: 8)
        for i in 0 ..< 8 {
            #expect(d.union(i, i) == false)
            #expect(d.inSameSet(i, i) == true)
        }
        #expect(d.setCount == 8)
        #expect((0 ..< 8).map { d.find($0) } == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(d == DisjointSet(count: 8))
    }

    @Test("DS-05 reserveCapacity is invisible")
    func reserve() {
        var d = DisjointSet()
        d.reserveCapacity(100)
        #expect(d.count == 0)
        #expect(d == DisjointSet())
        for _ in 0 ..< 100 { d.makeSet() }
        #expect(d == DisjointSet(count: 100))

        var e = DisjointSet(count: 5)
        e.reserveCapacity(0)
        #expect(e == DisjointSet(count: 5))
        #expect(e.count == 5)
    }

    @Test("DS-06 makeSet from empty: petgraph uf_incremental, translated")
    func incremental() {
        var d = DisjointSet()
        #expect(d.makeSet() == 0)
        #expect(d.makeSet() == 1)
        #expect(d.count == 2)
        d.union(0, 1)
        #expect(d.makeSet() == 2)
        #expect(d.makeSet() == 3)
        d.union(1, 3)
        #expect(d.makeSet() == 4)
        d.union(1, 4)
        #expect(d.makeSet() == 5)
        #expect(d.makeSet() == 6)
        #expect(d.makeSet() == 7)
        #expect(d.count == 8)
        d.union(4, 7)
        d.union(5, 6)
        #expect(d.inSameSet(0, 3) == true)
        #expect(d.inSameSet(1, 3) == true)
        #expect(d.inSameSet(0, 2) == false)
        #expect(d.inSameSet(7, 0) == true)
        #expect(d.inSameSet(6, 5) == true)
        #expect(d.inSameSet(6, 7) == false)
        #expect(d.setCount == 3)
        #expect((0 ..< 8).map { d.find($0) } == [0, 0, 2, 0, 0, 5, 5, 0])

        // The same unions on init(count: 8), as in DS-10.
        var built = DisjointSet(count: 8)
        for (a, b) in [(0, 1), (1, 3), (1, 4), (4, 7), (5, 6)] { built.union(a, b) }
        #expect(d == built)
    }

    @Test("DS-07 makeSet on a non-empty set adds a singleton")
    func makeSetOnNonEmpty() {
        var d = DisjointSet(count: 3)
        d.union(0, 1)
        #expect(d.makeSet() == 3)
        #expect(d.count == 4)
        #expect(d.setCount == 3)
        #expect(d.find(3) == 3)
        #expect(d.setSize(of: 3) == 1)
        #expect(d.inSameSet(3, 0) == false)
        #expect(d.sets() == [[0, 1], [2], [3]])
    }
}
