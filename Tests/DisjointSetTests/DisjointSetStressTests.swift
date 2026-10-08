// Large inputs, and a randomized differential test against a naive reference written inside the
// test. Deep cases run inside a Task, whose stack is much smaller than the main thread's, so a
// recursive find would overflow there first. Per-element checks are folded into one expectation
// each to keep the suite fast. Expected values come from the catalog's reference (`ref.py`,
// `cases.py`), which is cross-checked against scipy's and NetworkX's own implementations.
// Case IDs (DS-nn) refer to the catalog; see README.md.

import DisjointSetModule
import GrafluentTestSupport
import Testing

@Suite("DisjointSet on large inputs")
struct DisjointSetLargeInputTests {
    @Test("DS-39 a forward chain of 10⁶: union(i, i + 1)")
    func forwardChain() async {
        await Task {
            let n = 1_000_000
            var d = DisjointSet(count: n)
            #expect((0 ..< n - 1).allSatisfy { d.union($0, $0 + 1) })
            #expect(d.setCount == 1)
            #expect((0 ..< n).allSatisfy { d.find($0) == 0 })
            #expect(d.setSize(of: 0) == 1_000_000)
            #expect(d.labels().allSatisfy { $0 == 0 })
            #expect(d.sets().count == 1)
        }.value
    }

    @Test("DS-39 a backward chain of 10⁶: every representative is 999 998")
    func backwardChain() async {
        await Task {
            let n = 1_000_000
            var d = DisjointSet(count: n)
            #expect((0 ..< n - 1).reversed().allSatisfy { d.union($0, $0 + 1) })
            #expect(d.setCount == 1)
            #expect((0 ..< n).allSatisfy { d.find($0) == 999_998 })
            #expect(d.setSize(of: 0) == 1_000_000)
            #expect(d.labels().allSatisfy { $0 == 0 })
            #expect(d.sets().count == 1)
        }.value
    }

    @Test("DS-39 a forward chain of 10⁶ with the arguments swapped: union(i + 1, i)")
    func forwardChainSwapped() async {
        await Task {
            let n = 1_000_000
            var d = DisjointSet(count: n)
            #expect((0 ..< n - 1).allSatisfy { d.union($0 + 1, $0) })
            #expect(d.setCount == 1)
            #expect((0 ..< n).allSatisfy { d.find($0) == 0 })
            #expect(d.labels().allSatisfy { $0 == 0 })
            #expect(d.sets().count == 1)
        }.value
    }

    @Test("DS-39 a star of 10⁶: union(i, 0)")
    func star() async {
        await Task {
            let n = 1_000_000
            var d = DisjointSet(count: n)
            #expect((1 ..< n).allSatisfy { d.union($0, 0) })
            #expect(d.setCount == 1)
            #expect((0 ..< n).allSatisfy { d.find($0) == 0 })
            #expect(d.labels().allSatisfy { $0 == 0 })
            #expect(d.sets().count == 1)
        }.value
    }

    @Test("DS-41 the binomial tree on 2²⁰ elements, the deepest union by size allows")
    func binomialTree() async {
        await Task {
            let n = 1 << 20
            var d = DisjointSet(count: n)
            var k = 1
            var allMerged = true
            while k < n {
                // Both arguments are roots of sets of size k.
                for i in stride(from: 0, to: n, by: 2 * k) where !d.union(i, i + k) { allMerged = false }
                k *= 2
            }
            #expect(allMerged)
            #expect(d.setCount == 1)
            #expect(d.find(n - 1) == 0)
            #expect((0 ..< n).allSatisfy { d.find($0) == 0 })
        }.value
    }

    @Test("DS-43 10⁶ random unions: setCount law, and the reversed and swapped orders give an equal value", .tags(.randomized))
    func randomMillion() async {
        await Task {
            var generator = SeededRandomNumberGenerator(seed: 1)
            let n = 1_000_000
            let pairs = (0 ..< n).map { _ in (Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator)) }
            var forwards = DisjointSet(count: n)
            var merges = 0
            for (a, b) in pairs where forwards.union(a, b) { merges += 1 }
            #expect(forwards.setCount == n - merges)
            var backwards = DisjointSet(count: n)
            for (a, b) in pairs.reversed() { backwards.union(a, b) }
            #expect(backwards.setCount == n - merges)
            #expect(forwards == backwards)
            #expect(forwards.labels() == backwards.labels())
            var swapped = DisjointSet(count: n)
            for (a, b) in pairs.reversed() { swapped.union(b, a) }
            #expect(forwards == swapped)
            #expect(forwards.labels() == swapped.labels())
        }.value
    }
}

@Suite("DisjointSet against a naive reference", .tags(.randomized))
struct DisjointSetDifferentialTests {
    @Test("DS-40 random operations agree with a naive owner-and-members model", arguments: 1 ... 30)
    func differential(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for n in [1, 2, 10, 100, 1000] {
            var d = DisjointSet(count: n)
            // Oracle: owner[x] is x's set id, members[s] its elements, representative[s] its
            // representative, kept by the documented rule from the sizes and representatives alone.
            var owner = Array(0 ..< n)
            var members = (0 ..< n).map { [$0] }
            var representative = Array(0 ..< n)
            var naiveSetCount = n
            func naiveUnion(_ a: Int, _ b: Int) -> Bool {
                var kept = owner[a]
                var absorbed = owner[b]
                if kept == absorbed { return false }
                let sizeA = members[kept].count
                let sizeB = members[absorbed].count
                let repA = representative[kept]
                let repB = representative[absorbed]
                let winner = sizeA > sizeB || (sizeA == sizeB && repA < repB) ? repA : repB
                if members[kept].count < members[absorbed].count { swap(&kept, &absorbed) }
                for x in members[absorbed] { owner[x] = kept }
                members[kept] += members[absorbed]
                members[absorbed] = []
                representative[kept] = winner
                naiveSetCount -= 1
                return true
            }
            for _ in 0 ..< 4 * n {
                let roll = Int.random(in: 0 ..< 100, using: &generator)
                if roll < 5 {
                    let x = d.makeSet()
                    #expect(x == owner.count)
                    owner.append(members.count)
                    members.append([x])
                    representative.append(x)
                    naiveSetCount += 1
                    #expect(d.setSize(of: x) == 1)
                } else {
                    let a = Int.random(in: 0 ..< d.count, using: &generator)
                    let b = Int.random(in: 0 ..< d.count, using: &generator)
                    switch roll % 3 {
                    case 0:
                        #expect(d.union(a, b) == naiveUnion(a, b))
                    case 1:
                        #expect(d.inSameSet(a, b) == (owner[a] == owner[b]))
                    default:
                        #expect(d.find(a) == representative[owner[a]])
                    }
                    #expect(d.setSize(of: a) == members[owner[a]].count)
                    #expect(d.setSize(of: b) == members[owner[b]].count)
                }
                #expect(d.setCount == naiveSetCount)
                #expect(d.count == owner.count)
            }
            let count = owner.count
            #expect((0 ..< count).map { d.find($0) } == (0 ..< count).map { representative[owner[$0]] })
            var expectedSets: [[Int]] = []
            var expectedLabels = Array(repeating: -1, count: count)
            var labelOfSet = Array(repeating: -1, count: members.count)
            for x in 0 ..< count {
                if labelOfSet[owner[x]] < 0 {
                    labelOfSet[owner[x]] = expectedSets.count
                    expectedSets.append(members[owner[x]].sorted())
                }
                expectedLabels[x] = labelOfSet[owner[x]]
            }
            #expect(d.sets() == expectedSets)
            #expect(d.labels() == expectedLabels)
            // The same partition, built from the naive sets in a different union order.
            var rebuilt = DisjointSet(count: count)
            for set in expectedSets.reversed() {
                for x in set.dropLast().reversed() { rebuilt.union(set.last!, x) }
            }
            #expect(rebuilt == d)
            #expect(rebuilt.hashValue == d.hashValue)
        }
    }

    @Test("DS-42 petgraph's uf_rand law: union merges exactly when the representatives differ", arguments: 1 ... 5)
    func petgraphRandomLaw(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for (n, pairCount) in [(1 << 14, 100), (256, 2048)] {
            var d = DisjointSet(count: n)
            for _ in 0 ..< pairCount {
                let a = Int.random(in: 0 ..< n, using: &generator)
                let b = Int.random(in: 0 ..< n, using: &generator)
                let separate = d.find(a) != d.find(b)
                #expect(d.union(a, b) == separate)
            }
        }
    }
}
