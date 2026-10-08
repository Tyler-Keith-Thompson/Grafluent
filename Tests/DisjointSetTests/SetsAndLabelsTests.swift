// `setCount`, `setSize(of:)`, `sets()` and `labels()`: the count and size laws on seeded runs,
// scipy's test_subsets traced exactly, and the canonical order (sets by smallest element, each
// ascending; labels number sets in that order, not by representative). Expected values come from
// the catalog's reference (`ref.py`, `cases.py`), which is cross-checked against scipy's and
// NetworkX's own implementations.
// Case IDs (DS-nn) refer to the catalog; see README.md.

import DisjointSetModule
import GrafluentTestSupport
import Testing

@Suite("DisjointSet counts and sizes", .tags(.randomized))
struct CountAndSizeLawTests {
    @Test("DS-26 setCount is count minus the unions that merged, after every step", arguments: 1 ... 10)
    func setCountLaw(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for n in [1, 10, 100] {
            var d = DisjointSet(count: n)
            var merges = 0
            for _ in 0 ..< 3 * n {
                if Int.random(in: 0 ..< 10, using: &generator) == 0 {
                    #expect(d.makeSet() == d.count - 1)
                } else {
                    let a = Int.random(in: 0 ..< d.count, using: &generator)
                    let b = Int.random(in: 0 ..< d.count, using: &generator)
                    if d.union(a, b) { merges += 1 }
                }
                #expect(d.setCount == d.count - merges)
            }
        }
    }

    @Test("DS-27 sizes match sets(), add up to count, and add on a merge", arguments: 1 ... 10)
    func sizeLaws(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for n in [1, 10, 100] {
            var d = DisjointSet(count: n)
            for _ in 0 ..< 3 * n {
                if Int.random(in: 0 ..< 10, using: &generator) == 0 {
                    let x = d.makeSet()
                    #expect(d.setSize(of: x) == 1)
                } else {
                    let a = Int.random(in: 0 ..< d.count, using: &generator)
                    let b = Int.random(in: 0 ..< d.count, using: &generator)
                    let sizeOfA = d.setSize(of: a)
                    let sizeOfB = d.setSize(of: b)
                    let separate = !d.inSameSet(a, b)
                    #expect(d.union(a, b) == separate)
                    if separate {
                        #expect(d.setSize(of: a) == sizeOfA + sizeOfB)
                        #expect(d.setSize(of: b) == sizeOfA + sizeOfB)
                    } else {
                        #expect(d.setSize(of: a) == sizeOfA)
                    }
                }
                let sets = d.sets()
                let labels = d.labels()
                #expect((0 ..< d.count).allSatisfy { d.setSize(of: $0) == sets[labels[$0]].count })
                #expect(sets.map(\.count).reduce(0, +) == d.count)
            }
        }
    }
}

@Suite("DisjointSet sets and labels")
struct SetsAndLabelsTests {
    @Test("DS-28 scipy test_subsets, n = 10, traced exactly")
    func scipySubsets() {
        // The pairs scipy draws with RandomState(0).randint(0, 10, (10, 2)).
        var d = DisjointSet(count: 10)
        #expect(d.union(5, 0) == true)
        #expect(d.sets() == [[0, 5], [1], [2], [3], [4], [6], [7], [8], [9]])
        #expect(d.union(3, 3) == false)
        #expect(d.sets() == [[0, 5], [1], [2], [3], [4], [6], [7], [8], [9]])
        #expect(d.union(7, 9) == true)
        #expect(d.sets() == [[0, 5], [1], [2], [3], [4], [6], [7, 9], [8]])
        #expect(d.union(3, 5) == true)
        #expect(d.sets() == [[0, 3, 5], [1], [2], [4], [6], [7, 9], [8]])
        #expect(d.union(2, 4) == true)
        #expect(d.sets() == [[0, 3, 5], [1], [2, 4], [6], [7, 9], [8]])
        #expect(d.union(7, 6) == true)
        #expect(d.sets() == [[0, 3, 5], [1], [2, 4], [6, 7, 9], [8]])
        #expect(d.union(8, 8) == false)
        #expect(d.sets() == [[0, 3, 5], [1], [2, 4], [6, 7, 9], [8]])
        #expect(d.union(1, 6) == true)
        #expect(d.sets() == [[0, 3, 5], [1, 6, 7, 9], [2, 4], [8]])
        #expect(d.union(7, 7) == false)
        #expect(d.sets() == [[0, 3, 5], [1, 6, 7, 9], [2, 4], [8]])
        #expect(d.union(8, 1) == true)
        #expect(d.sets() == [[0, 3, 5], [1, 6, 7, 8, 9], [2, 4]])

        #expect((0 ..< 10).map { d.find($0) } == [0, 7, 2, 0, 2, 0, 7, 7, 7, 7])
        #expect(d.labels() == [0, 1, 2, 0, 2, 0, 1, 1, 1, 1])
        #expect((0 ..< 10).map { d.setSize(of: $0) } == [3, 5, 2, 3, 2, 3, 5, 5, 5, 5])
        // scipy's own assertion: subset_size == len(subset).
        let sets = d.sets()
        #expect((0 ..< 10).allSatisfy { d.setSize(of: $0) == sets[d.labels()[$0]].count })
        #expect(d.setCount == 3)
    }

    @Test("DS-29 labels number sets by their first element, not by representative")
    func labelsByFirstElement() {
        var d = DisjointSet(count: 5)
        d.union(3, 0)
        d.union(4, 1)
        #expect(d.labels() == [0, 1, 2, 0, 1])
        #expect(d.sets() == [[0, 3], [1, 4], [2]])

        var e = DisjointSet(count: 4)
        e.union(2, 3)
        e.union(0, 2)
        #expect((0 ..< 4).map { e.find($0) } == [2, 1, 2, 2])
        // Numbering by representative would give [1, 0, 1, 1].
        #expect(e.labels() == [0, 1, 0, 0])
        #expect(e.sets() == [[0, 2, 3], [1]])
    }

    @Test("DS-30 sets(), labels(), inSameSet and setSize agree, are canonical, and work on a let", .tags(.randomized), arguments: 1 ... 10)
    func consistency(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for n in [1, 10, 100] {
            var d = DisjointSet(count: n)
            for _ in 0 ..< 3 * n {
                if Int.random(in: 0 ..< 10, using: &generator) == 0 {
                    d.makeSet()
                } else {
                    d.union(Int.random(in: 0 ..< d.count, using: &generator), Int.random(in: 0 ..< d.count, using: &generator))
                }
                let snapshot = d
                let sets = snapshot.sets()
                let labels = snapshot.labels()
                #expect(sets.count == snapshot.setCount)
                #expect(sets.joined().sorted() == Array(0 ..< snapshot.count))
                #expect(sets.allSatisfy { $0 == $0.sorted() && !$0.isEmpty })
                #expect(sets.map { $0[0] } == sets.map { $0[0] }.sorted())
                #expect(labels.count == snapshot.count)
                #expect((0 ..< snapshot.count).allSatisfy { sets[labels[$0]].contains($0) })
                // The non-writing queries agree with the sets, on a `let`.
                let a = Int.random(in: 0 ..< snapshot.count, using: &generator), b = Int.random(in: 0 ..< snapshot.count, using: &generator)
                #expect(snapshot.inSameSet(a, b) == (labels[a] == labels[b]))
                #expect(snapshot.setSize(of: a) == sets[labels[a]].count)
                #expect(labels.max() == (snapshot.setCount == 0 ? nil : snapshot.setCount - 1))
                #expect(!snapshot.description.isEmpty)
                #expect(!snapshot.isEmpty)
            }
        }
        let empty = DisjointSet()
        #expect(empty.labels().max() == nil)
        #expect(empty.sets().isEmpty)
    }
}
