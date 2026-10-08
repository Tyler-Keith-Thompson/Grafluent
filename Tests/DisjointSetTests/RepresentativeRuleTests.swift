// The documented representative rule, exactly: `union(a, b)` keeps the representative of the
// larger set, or, for sets of the same size, the smaller of the two representatives, whatever the
// order of the arguments. `find` never changes a representative. scipy's tests are ported with
// their exact pairs. Expected values come from the catalog's reference (`ref.py`, `cases.py`),
// which is cross-checked against scipy's and NetworkX's own implementations.
// Case IDs (DS-nn) refer to the catalog; see README.md.

import DisjointSetModule
import GrafluentTestSupport
import Testing

@Suite("DisjointSet representative rule")
struct RepresentativeRuleTests {
    @Test("DS-19 equal sizes: the smaller index wins, whatever the argument order")
    func equalSizes() {
        var p = DisjointSet(count: 4)
        #expect(p.union(3, 1) == true)
        // petgraph's and JGraphT's first-argument tie would give [0, 3, 2, 3].
        #expect((0 ..< 4).map { p.find($0) } == [0, 1, 2, 1])

        var q = DisjointSet(count: 4)
        #expect(q.union(1, 3) == true)
        #expect((0 ..< 4).map { q.find($0) } == [0, 1, 2, 1])
    }

    @Test("DS-19 equal sizes: the tie is between the representatives, not the arguments")
    func tieBetweenRepresentatives() {
        var d = DisjointSet(count: 4)
        d.union(0, 3)
        d.union(1, 2)
        // Representatives 0 and 1: 0 wins, although the arguments 3 and 2 favor the other set.
        #expect(d.union(3, 2) == true)
        #expect((0 ..< 4).map { d.find($0) } == [0, 0, 0, 0])
    }

    @Test("DS-20 the larger set wins, whatever the indices")
    func largerWins() {
        var d = DisjointSet(count: 8)
        d.union(5, 6)
        d.union(6, 7)
        d.union(0, 5)
        #expect((0 ..< 8).map { d.find($0) } == [5, 1, 2, 3, 4, 5, 5, 5])
    }

    @Test("DS-21 scipy test_linear_union_sequence, forwards", arguments: [10, 100])
    func linearForwards(_ n: Int) {
        var d = DisjointSet(count: n)
        for (step, i) in (0 ..< n - 1).enumerated() {
            #expect(d.inSameSet(i, i + 1) == false)
            #expect(d.union(i, i + 1) == true)
            #expect(d.inSameSet(i, i + 1) == true)
            #expect(d.setCount == n - 1 - step)
        }
        #expect((0 ..< n).allSatisfy { d.find($0) == 0 })
        #expect(d.union(0, n - 1) == false)
    }

    @Test("DS-21 scipy test_linear_union_sequence, backwards: every representative is n − 2", arguments: [10, 100])
    func linearBackwards(_ n: Int) {
        var d = DisjointSet(count: n)
        for (step, i) in (0 ..< n - 1).reversed().enumerated() {
            #expect(d.inSameSet(i, i + 1) == false)
            #expect(d.union(i, i + 1) == true)
            #expect(d.inSameSet(i, i + 1) == true)
            #expect(d.setCount == n - 1 - step)
        }
        #expect((0 ..< n).allSatisfy { d.find($0) == n - 2 })
        #expect(d.union(0, n - 1) == false)
    }

    @Test("DS-22 scipy test_equal_size_ordering, n = 10: each pair takes its smaller element")
    func equalSizeOrdering() {
        // The pairs scipy draws with RandomState(0).shuffle.
        let pairs = [(2, 8), (4, 9), (1, 6), (7, 3), (0, 5)]
        var forwards = DisjointSet(count: 10)
        for (a, b) in pairs { #expect(forwards.union(a, b) == true) }
        #expect((0 ..< 10).map { forwards.find($0) } == [0, 1, 2, 3, 4, 0, 1, 3, 2, 4])

        var swapped = DisjointSet(count: 10)
        for (a, b) in pairs { #expect(swapped.union(b, a) == true) }
        #expect((0 ..< 10).map { swapped.find($0) } == [0, 1, 2, 3, 4, 0, 1, 3, 2, 4])
    }

    @Test("DS-23 scipy test_binary_tree: after each round find(x) == x − x % 2k", .tags(.randomized), arguments: [5, 10])
    func binaryTree(_ kmax: Int) {
        // scipy picks with RandomState(0); the result does not depend on the picks.
        var generator = SeededRandomNumberGenerator(seed: UInt(kmax))
        let n = 1 << kmax
        var d = DisjointSet(count: n)
        var k = 1
        while k < n {
            for i in stride(from: 0, to: n, by: 2 * k) {
                let a = Int.random(in: i ..< i + k, using: &generator)
                let b = Int.random(in: i + k ..< i + 2 * k, using: &generator)
                #expect(d.inSameSet(a, b) == false)
                #expect(d.union(a, b) == true)
                #expect(d.inSameSet(a, b) == true)
            }
            #expect((0 ..< n).allSatisfy { d.find($0) == $0 - $0 % (2 * k) })
            k *= 2
        }
        #expect(d.setCount == 1)
    }

    @Test("DS-24 find, queries and failed unions never change a representative", .tags(.randomized), arguments: 1 ... 5)
    func findKeepsRepresentatives(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        var d = DisjointSet(count: 10)
        for (a, b) in [(5, 0), (3, 3), (7, 9), (3, 5), (2, 4), (7, 6), (8, 8), (1, 6), (7, 7), (8, 1)] { d.union(a, b) }
        let expected = [0, 7, 2, 0, 2, 0, 7, 7, 7, 7]
        #expect((0 ..< 10).map { d.find($0) } == expected)
        for _ in 0 ..< 3 {
            for x in (0 ..< 10).shuffled(using: &generator) {
                _ = d.find(x)
                _ = d.inSameSet(x, Int.random(in: 0 ..< 10, using: &generator))
                _ = d.setSize(of: x)
                _ = d.sets()
                _ = d.labels()
                #expect((0 ..< 10).map { d.find($0) } == expected)
            }
        }
        // Unions inside a set fail and change nothing.
        #expect(d.union(3, 5) == false)
        #expect(d.union(9, 1) == false)
        #expect(d.union(4, 4) == false)
        #expect((0 ..< 10).map { d.find($0) } == expected)
        #expect(d.setCount == 3)
    }

    @Test("DS-25 argument order never matters: union(a, b) and union(b, a) leave the same representatives", .tags(.randomized), arguments: 1 ... 10)
    func argumentOrder(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 200
        let pairs = (0 ..< 400).map { _ in (Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator)) }
        var p = DisjointSet(count: n)
        var q = DisjointSet(count: n)
        for (a, b) in pairs {
            let merged = p.union(a, b)
            #expect(q.union(b, a) == merged)
        }
        #expect((0 ..< n).map { p.find($0) } == (0 ..< n).map { q.find($0) })
        #expect(p == q)
        #expect(p.setCount == q.setCount)
    }
}
