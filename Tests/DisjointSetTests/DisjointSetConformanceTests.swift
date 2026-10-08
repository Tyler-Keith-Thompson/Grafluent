// Equality and hashing (same count, same partition; representatives are not part of the value),
// value semantics, descriptions, `Sendable`, and the patterns of the consumers (Kruskal, cycle
// detection, connected components). Expected values come from the catalog's reference (`ref.py`,
// `cases.py`).
// Case IDs (DS-nn) refer to the catalog; see README.md.

import DisjointSetModule
import GrafluentTestSupport
import Testing

@Suite("DisjointSet equality and hashing", .tags(.conformance))
struct DisjointSetEqualityTests {
    @Test("DS-31 the same partition with different representatives is equal")
    func samePartitionDifferentRepresentatives() {
        var a = DisjointSet(count: 3)
        a.union(1, 2)
        a.union(0, 1)
        var b = DisjointSet(count: 3)
        b.union(0, 1)
        b.union(1, 2)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
        #expect(a.description == "[[0, 1, 2]]")
        #expect(b.description == "[[0, 1, 2]]")
        // The representative is visible but is not part of the value.
        #expect((0 ..< 3).map { a.find($0) } == [1, 1, 1])
        #expect((0 ..< 3).map { b.find($0) } == [0, 0, 0])
        #expect(a.find(0) != b.find(0))
        #expect(a == b)
    }

    @Test("DS-31 the same pairs in forward and reversed order give equal values", .tags(.randomized), arguments: 1 ... 10)
    func pairOrder(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 200
        let pairs = (0 ..< 400).map { _ in (Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator)) }
        var forwards = DisjointSet(count: n)
        for (a, b) in pairs { forwards.union(a, b) }
        var backwards = DisjointSet(count: n)
        for (a, b) in pairs.reversed() { backwards.union(a, b) }
        #expect(forwards == backwards)
        #expect(forwards.hashValue == backwards.hashValue)
        #expect(forwards.labels() == backwards.labels())
        #expect(forwards.sets() == backwards.sets())
        #expect(forwards.description == backwards.description)
    }

    @Test("DS-32 different counts or partitions are not equal")
    func inequality() {
        #expect(DisjointSet(count: 3) != DisjointSet(count: 4))

        var zeroOne = DisjointSet(count: 4)
        zeroOne.union(0, 1)
        var twoThree = DisjointSet(count: 4)
        twoThree.union(2, 3)
        let none = DisjointSet(count: 4)
        #expect(zeroOne != twoThree)
        #expect(zeroOne != none)
        #expect(twoThree != none)

        // Same setCount and the same sizes, different partitions.
        var pairsA = DisjointSet(count: 4)
        pairsA.union(0, 1)
        pairsA.union(2, 3)
        var pairsB = DisjointSet(count: 4)
        pairsB.union(0, 2)
        pairsB.union(1, 3)
        #expect(pairsA.setCount == pairsB.setCount)
        #expect(pairsA != pairsB)

        var fiveZeroOne = DisjointSet(count: 5)
        fiveZeroOne.union(0, 1)
        #expect(zeroOne != fiveZeroOne)
    }

    @Test("DS-32 every partition of four elements hashes differently from the others")
    func distinctPartitionsHashDifferently() {
        // The 15 partitions of {0, 1, 2, 3}, each as the unions that build it. Equal hashes for
        // different values are allowed, but for all 15 to collide in 64 bits would mean the hash
        // ignores the partition.
        let partitions: [[(Int, Int)]] = [
            [], [(0, 1)], [(0, 2)], [(0, 3)], [(1, 2)], [(1, 3)], [(2, 3)],
            [(0, 1), (2, 3)], [(0, 2), (1, 3)], [(0, 3), (1, 2)],
            [(0, 1), (1, 2)], [(0, 1), (1, 3)], [(0, 2), (2, 3)], [(1, 2), (2, 3)],
            [(0, 1), (1, 2), (2, 3)],
        ]
        var hashes: Set<Int> = []
        for unions in partitions {
            var d = DisjointSet(count: 4)
            for (a, b) in unions { d.union(a, b) }
            hashes.insert(d.hashValue)
        }
        #expect(hashes.count == 15)
    }

    @Test("DS-33 equality laws: finds do not change the value, hashing agrees, and growth does not matter")
    func equalityLaws() {
        var d = DisjointSet(count: 8)
        for (a, b) in [(0, 1), (1, 3), (1, 4), (4, 7), (5, 6)] { d.union(a, b) }
        var c = d
        _ = c.find(7)
        #expect(c == d)
        #expect(d == d)

        var a = DisjointSet(count: 3)
        a.union(1, 2)
        a.union(0, 1)
        var b = DisjointSet(count: 3)
        b.union(0, 1)
        b.union(1, 2)
        #expect(Set([a, b, DisjointSet(count: 3)]).count == 2)

        var grown = DisjointSet()
        for _ in 0 ..< 8 { grown.makeSet() }
        for (x, y) in [(0, 1), (1, 3), (1, 4), (4, 7), (5, 6)] { grown.union(x, y) }
        #expect(grown == d)
        #expect(grown.hashValue == d.hashValue)
    }
}

@Suite("DisjointSet value semantics", .tags(.copyOnWrite))
struct DisjointSetValueSemanticsTests {
    @Test("DS-34 a union on a copy leaves the original alone")
    func unionOnCopy() {
        var a = DisjointSet(count: 4)
        a.union(0, 1)
        var b = a
        b.union(2, 3)
        #expect(a.setCount == 3)
        #expect(a.inSameSet(2, 3) == false)
        #expect(a.sets() == [[0, 1], [2], [3]])
        #expect(b.sets() == [[0, 1], [2, 3]])
        #expect(b.setCount == 2)

        var c = DisjointSet(count: 4)
        c.union(0, 1)
        let e = c
        c.union(2, 3)
        #expect(e.setCount == 3)
        #expect(e.inSameSet(2, 3) == false)
        #expect(e.sets() == [[0, 1], [2], [3]])
        #expect(c.sets() == [[0, 1], [2, 3]])
    }

    @Test("DS-35 a compressing find on a copy changes neither")
    func findOnCopy() {
        // The binomial tree on 2¹⁰ elements: the deepest tree union by size allows.
        let n = 1 << 10
        var a = DisjointSet(count: n)
        var k = 1
        while k < n {
            for i in stride(from: 0, to: n, by: 2 * k) { a.union(i, i + k) }
            k *= 2
        }
        var b = a
        for x in 0 ..< n { _ = b.find(x) }
        #expect(a == b)
        #expect((0 ..< n).allSatisfy { a.find($0) == 0 })
        #expect((0 ..< n).allSatisfy { b.find($0) == 0 })
        a.makeSet()
        #expect(a.count == n + 1)
        #expect(b.count == n)
        #expect(b.setCount == 1)
    }

    @Test("DS-36 makeSet and reserveCapacity on a copy leave the original alone")
    func growthOnCopy() {
        var a = DisjointSet(count: 4)
        a.union(0, 1)
        var b = a
        b.makeSet()
        b.reserveCapacity(10_000)
        #expect(a.count == 4)
        #expect(a.setCount == 3)
        var expected = DisjointSet(count: 4)
        expected.union(0, 1)
        #expect(a == expected)
        #expect(b.count == 5)
        #expect(b.sets() == [[0, 1], [2], [3], [4]])
    }
}

@Suite("DisjointSet descriptions and conformances")
struct DisjointSetDescriptionTests {
    @Test("DS-44 description and debugDescription list at most 16 sets and 16 elements per set")
    func descriptions() {
        var d = DisjointSet(count: 8)
        for (a, b) in [(0, 1), (1, 3), (1, 4), (4, 7), (5, 6)] { d.union(a, b) }
        #expect(d.description == "[[0, 1, 3, 4, 7], [2], [5, 6]]")
        #expect(d.debugDescription == "DisjointSet(count: 8, setCount: 3, sets: [[0, 1, 3, 4, 7], [2], [5, 6]])")

        #expect(DisjointSet().description == "[]")
        #expect(DisjointSet().debugDescription == "DisjointSet(count: 0, setCount: 0, sets: [])")

        #expect(DisjointSet(count: 20).description
            == "[[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], …]")
        #expect(DisjointSet(count: 16).description
            == "[[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15]]")

        var sixteen = DisjointSet(count: 16)
        for i in 1 ..< 16 { sixteen.union(0, i) }
        #expect(sixteen.description == "[[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]]")

        var one = DisjointSet(count: 20)
        for i in 1 ..< 20 { one.union(0, i) }
        #expect(one.description == "[[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, …]]")
        #expect(one.debugDescription
            == "DisjointSet(count: 20, setCount: 1, sets: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, …]])")
    }

    @Test("DS-45 a disjoint set crosses into a Task and back")
    func sendable() async {
        var d = DisjointSet(count: 4)
        d.union(0, 1)
        let sent = d
        let returned = await Task {
            var copy = sent
            copy.union(2, 3)
            return copy
        }.value
        #expect(returned.sets() == [[0, 1], [2, 3]])
        #expect(sent.sets() == [[0, 1], [2], [3]])
    }

    @Test("DS-46 consumer patterns: connected components and cycle detection")
    func consumerPatterns() {
        // petgraph's connected_components example: a→b→c→d→a and e→f→g→h→e.
        var d = DisjointSet(count: 8)
        let edges = [(0, 1), (1, 2), (2, 3), (3, 0), (4, 5), (5, 6), (6, 7), (7, 4)]
        #expect(edges.map { d.union($0.0, $0.1) } == [true, true, true, false, true, true, true, false])
        #expect(d.setCount == 2)
        #expect(d.labels() == [0, 0, 0, 0, 1, 1, 1, 1])
        #expect(d.union(1, 4) == true)
        #expect(d.setCount == 1)

        // The triangle: the third edge closes the cycle.
        var triangle = DisjointSet(count: 3)
        #expect([(0, 1), (1, 2), (2, 0)].map { triangle.union($0.0, $0.1) } == [true, true, false])
    }
}
