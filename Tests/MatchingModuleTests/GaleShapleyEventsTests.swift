// Gale and Shapley's deferred acceptance as an event sequence (`galeShapley`): a hand-traced
// instance with a trade-up and rejections, unacceptable pairs and an exhausted list, and a
// property test replaying the events into `stableMatching`'s matching. Case IDs (MA-nn) are
// listed in README.md.

import MatchingModule
import PropertyBased
import Testing

@Suite("Gale–Shapley events")
struct GaleShapleyEventsTests {
    @Test("MA-1105 three proposers and reviewers: every proposal and answer in order", .tags(.fixture))
    func handTraced() {
        let proposers = [[0, 1, 2], [0, 2, 1], [1, 0, 2]]
        let reviewers = [[1, 0, 2], [0, 1, 2], [0, 1, 2]]
        let expected: [GaleShapleyEvent] = [
            .propose(proposer: 0, reviewer: 0), .accept(proposer: 0, reviewer: 0),
            .propose(proposer: 1, reviewer: 0), .tradeUp(reviewer: 0, from: 0, to: 1),
            .propose(proposer: 0, reviewer: 1), .accept(proposer: 0, reviewer: 1),
            .propose(proposer: 2, reviewer: 1), .reject(proposer: 2, reviewer: 1),
            .propose(proposer: 2, reviewer: 0), .reject(proposer: 2, reviewer: 0),
            .propose(proposer: 2, reviewer: 2), .accept(proposer: 2, reviewer: 2),
        ]
        let events = galeShapley(proposerPreferences: proposers, reviewerPreferences: reviewers)
        #expect(Array(events) == expected)
        #expect(Array(events) == Array(events))
        #expect(expected[3].description == "tradeUp(0: 0 → 1)" && expected[0].description == "propose(0 → 0)")
        let matching = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        #expect(matching.mate(ofProposer: 0) == 1 && matching.mate(ofProposer: 1) == 0 && matching.mate(ofProposer: 2) == 2)
    }

    @Test("MA-1106 an unacceptable pair is proposed and rejected; a list that runs out leaves its proposer unmatched; no proposers, no events")
    func unacceptableAndExhausted() {
        // Reviewer 0 lists only proposer 1; proposer 0 lists only reviewer 0.
        #expect(Array(galeShapley(proposerPreferences: [[0], [0]], reviewerPreferences: [[1]])) == [
            .propose(proposer: 0, reviewer: 0), .reject(proposer: 0, reviewer: 0), .exhausted(proposer: 0),
            .propose(proposer: 1, reviewer: 0), .accept(proposer: 1, reviewer: 0),
        ])
        #expect(Array(galeShapley(proposerPreferences: [[]], reviewerPreferences: [])) == [.exhausted(proposer: 0)])
        #expect(Array(galeShapley(proposerPreferences: [], reviewerPreferences: [[], []])).isEmpty)
    }

    @Test("MA-1107 property (PropertyBased): replayed, the events hold stableMatching's matching; each proposer proposes down its list once", .tags(.randomized))
    func property() async {
        let lists = Gen.int(in: 0 ... 4).array(of: 0 ... 5).array(of: 0 ... 5)
        await propertyCheck(count: 300, input: lists, lists) { rawProposers, rawReviewers in
            func distinct(_ list: [Int], below bound: Int) -> [Int] {
                var seen = Set<Int>()
                return list.filter { $0 < bound && seen.insert($0).inserted }
            }
            let reviewers = rawReviewers.map { distinct($0, below: rawProposers.count) }
            let proposers = rawProposers.map { distinct($0, below: reviewers.count) }
            var held = [Int](repeating: -1, count: reviewers.count)
            var proposed = [[Int]](repeating: [], count: proposers.count)
            var exhausted = Set<Int>()
            for event in galeShapley(proposerPreferences: proposers, reviewerPreferences: reviewers) {
                switch event {
                case .propose(let p, let r): proposed[p].append(r)
                case .accept(let p, let r):
                    #expect(held[r] == -1)
                    held[r] = p
                case .tradeUp(let r, let from, let to):
                    #expect(held[r] == from)
                    held[r] = to
                case .reject(let p, let r): #expect(held[r] != p)
                case .exhausted(let p):
                    #expect(proposed[p] == proposers[p])
                    exhausted.insert(p)
                }
            }
            let matching = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
            for r in reviewers.indices { #expect(matching.mate(ofReviewer: r) == (held[r] < 0 ? nil : held[r])) }
            for p in proposers.indices {
                #expect(proposed[p] == Array(proposers[p].prefix(proposed[p].count)))
                #expect(exhausted.contains(p) == (matching.mate(ofProposer: p) == nil))
            }
        }
    }
}
