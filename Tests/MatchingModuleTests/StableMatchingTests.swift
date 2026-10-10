// `stableMatching(proposerPreferences:reviewerPreferences:)` (catalog §Stable, MA-213 – MA-228): the
// proposer-optimal stable matching, exact mates from both sides, and against every stable matching
// enumerated here by brute force: the result is one of them, no proposer does better in another
// (proposer-optimal), and all of them match the same agents (the rural hospitals theorem). Generated
// from cases.md by swiftgen.py, which re-evaluates each row with ref.py's model; see README.md.

import MatchingModule
import Testing

@Suite("stableMatching: Gale–Shapley deferred acceptance")
struct StableMatchingTests {
    @Test("MA-213 Gale–Shapley 1962 example 1 (3×3) (each proposer gets a first choice): mates [0, 1, 2]")
    func ma213() {
        // P [012, 120, 201]; R [120, 201, 012]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[0, 1, 2], [1, 2, 0], [2, 0, 1]]
        let reviewers: [[Int]] = [[1, 2, 0], [2, 0, 1], [0, 1, 2]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [0, 1, 2]
        let expectedReviewerMates: [Int?] = [0, 1, 2]
        for p in 0 ..< 3 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 3 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 3)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 3 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 3 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 3)
        let found = (0 ..< 3).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 3 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 3 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-214 same instance, roles swapped (the reviewer-optimal matching of the original, read from the other side)")
    func ma214() {
        // P [120, 201, 012]; R [012, 120, 201]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[1, 2, 0], [2, 0, 1], [0, 1, 2]]
        let reviewers: [[Int]] = [[0, 1, 2], [1, 2, 0], [2, 0, 1]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [1, 2, 0]
        let expectedReviewerMates: [Int?] = [2, 0, 1]
        for p in 0 ..< 3 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 3 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 3)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 3 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 3 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 3)
        let found = (0 ..< 3).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 3 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 3 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-215 everyone agrees (serial dictatorship): mates [0, 1, 2]")
    func ma215() {
        // P [012, 012, 012]; R [012, 012, 012]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[0, 1, 2], [0, 1, 2], [0, 1, 2]]
        let reviewers: [[Int]] = [[0, 1, 2], [0, 1, 2], [0, 1, 2]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [0, 1, 2]
        let expectedReviewerMates: [Int?] = [0, 1, 2]
        for p in 0 ..< 3 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 3 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 3)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 3 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 3 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 3).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 3 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 3 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-216 one each: mates [0]")
    func ma216() {
        // P [0]; R [0]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[0]]
        let reviewers: [[Int]] = [[0]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [0]
        let expectedReviewerMates: [Int?] = [0]
        for p in 0 ..< 1 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 1 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 1)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 1 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 1 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 1).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 1 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 1 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-217 no proposers: mates []")
    func ma217() {
        // P []; R [·, ·]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = []
        let reviewers: [[Int]] = [[], []]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = []
        let expectedReviewerMates: [Int?] = [nil, nil]
        for p in 0 ..< 0 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 2 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 2)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 0 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 0 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 0).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 0 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 0 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-218 no reviewers: mates [nil, nil]")
    func ma218() {
        // P [·, ·]; R []; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[], []]
        let reviewers: [[Int]] = []
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [nil, nil]
        let expectedReviewerMates: [Int?] = []
        for p in 0 ..< 2 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 0 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 0)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 2 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 2 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 2).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 2 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 2 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-219 empty lists: mates [nil, nil]")
    func ma219() {
        // P [·, ·]; R [·, ·]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[], []]
        let reviewers: [[Int]] = [[], []]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [nil, nil]
        let expectedReviewerMates: [Int?] = [nil, nil]
        for p in 0 ..< 2 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 2 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 2)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 2 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 2 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 2).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 2 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 2 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-220 one-sided acceptability is unacceptable: mates [nil]")
    func ma220() {
        // P [0]; R [·]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[0]]
        let reviewers: [[Int]] = [[]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [nil]
        let expectedReviewerMates: [Int?] = [nil]
        for p in 0 ..< 1 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 1 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 1)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 1 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 1 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 1).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 1 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 1 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-221 more proposers than reviewers: mates [nil, 1, 0]")
    func ma221() {
        // P [01, 01, 10]; R [201, 120]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[0, 1], [0, 1], [1, 0]]
        let reviewers: [[Int]] = [[2, 0, 1], [1, 2, 0]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [nil, 1, 0]
        let expectedReviewerMates: [Int?] = [2, 1]
        for p in 0 ..< 3 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 2 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 2)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 3 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 3 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 3).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 3 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 3 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-222 more reviewers than proposers: mates [0, 2]")
    func ma222() {
        // P [20, 21]; R [01, 10, 10]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[2, 0], [2, 1]]
        let reviewers: [[Int]] = [[0, 1], [1, 0], [1, 0]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [0, 2]
        let expectedReviewerMates: [Int?] = [0, nil, 1]
        for p in 0 ..< 2 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 3 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 3)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 2 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 2 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 2).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 2 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 2 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-223 incomplete lists, a proposer left single: mates [nil, 0, 1]")
    func ma223() {
        // P [0, 01, 1]; R [10, 21]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[0], [0, 1], [1]]
        let reviewers: [[Int]] = [[1, 0], [2, 1]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [nil, 0, 1]
        let expectedReviewerMates: [Int?] = [1, 2]
        for p in 0 ..< 3 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 2 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 2)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 3 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 3 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 3).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 3 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 3 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-224 cyclic 3×3, reviewers reversed: two stable matchings: mates [0, 1, 2]")
    func ma224() {
        // P [012, 120, 201]; R [012, 201, 120]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[0, 1, 2], [1, 2, 0], [2, 0, 1]]
        let reviewers: [[Int]] = [[0, 1, 2], [2, 0, 1], [1, 2, 0]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [0, 1, 2]
        let expectedReviewerMates: [Int?] = [0, 1, 2]
        for p in 0 ..< 3 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 3 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 3)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 3 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 3 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 2)
        let found = (0 ..< 3).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 3 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 3 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-225 4×4 Gusfield–Irving style: mates [1, 0, 2, 3]")
    func ma225() {
        // P [3120, 1023, 0123, 0312]; R [0123, 0321, 1023, 3102]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[3, 1, 2, 0], [1, 0, 2, 3], [0, 1, 2, 3], [0, 3, 1, 2]]
        let reviewers: [[Int]] = [[0, 1, 2, 3], [0, 3, 2, 1], [1, 0, 2, 3], [3, 1, 0, 2]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [1, 0, 2, 3]
        let expectedReviewerMates: [Int?] = [1, 0, 2, 3]
        for p in 0 ..< 4 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 4 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 4)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 4 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 4 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 4).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 4 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 4 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-226 random 5×5 complete (LCG(7) Fisher–Yates): mates [1, 4, 0, 3, 2]")
    func ma226() {
        // P [21043, 24130, 03124, 14302, 21430]; R [20341, 41203, 42103, 41230, 20134]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[2, 1, 0, 4, 3], [2, 4, 1, 3, 0], [0, 3, 1, 2, 4], [1, 4, 3, 0, 2], [2, 1, 4, 3, 0]]
        let reviewers: [[Int]] = [[2, 0, 3, 4, 1], [4, 1, 2, 0, 3], [4, 2, 1, 0, 3], [4, 1, 2, 3, 0], [2, 0, 1, 3, 4]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [1, 4, 0, 3, 2]
        let expectedReviewerMates: [Int?] = [2, 0, 4, 3, 1]
        for p in 0 ..< 5 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 5 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 5)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 5 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 5 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 2)
        let found = (0 ..< 5).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 5 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 5 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-227 random 6×6 complete (continuing LCG(7)): mates [5, 1, 3, 2, 0, 4]")
    func ma227() {
        // P [532401, 135042, 305142, 254031, 250431, 142305]; R [401253, 402153, 213450, 012435, 205413, 213504]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[5, 3, 2, 4, 0, 1], [1, 3, 5, 0, 4, 2], [3, 0, 5, 1, 4, 2], [2, 5, 4, 0, 3, 1], [2, 5, 0, 4, 3, 1], [1, 4, 2, 3, 0, 5]]
        let reviewers: [[Int]] = [[4, 0, 1, 2, 5, 3], [4, 0, 2, 1, 5, 3], [2, 1, 3, 4, 5, 0], [0, 1, 2, 4, 3, 5], [2, 0, 5, 4, 1, 3], [2, 1, 3, 5, 0, 4]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [5, 1, 3, 2, 0, 4]
        let expectedReviewerMates: [Int?] = [4, 1, 3, 2, 5, 0]
        for p in 0 ..< 6 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 6 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 6)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 6 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 6 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 2)
        let found = (0 ..< 6).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 6 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 6 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }

    @Test("MA-228 random 5×4 truncated lists: mates [3, 2, nil, 0, 1]")
    func ma228() {
        // P [31, 32, 12, 01, 31]; R [103, 104, 134, 320]; stableMatching(proposerPreferences:reviewerPreferences:)
        let proposers: [[Int]] = [[3, 1], [3, 2], [1, 2], [0, 1], [3, 1]]
        let reviewers: [[Int]] = [[1, 0, 3], [1, 0, 4], [1, 3, 4], [3, 2, 0]]
        let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
        let expectedProposerMates: [Int?] = [3, 2, nil, 0, 1]
        let expectedReviewerMates: [Int?] = [3, 4, 1, 0]
        for p in 0 ..< 5 { #expect(result.mate(ofProposer: p) == expectedProposerMates[p], "proposer \(p)") }
        for r in 0 ..< 4 { #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], "reviewer \(r)") }
        // Every matching over acceptable pairs, by brute force; the stable ones.
        func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
        func isStable(_ m: [Int?]) -> Bool {
            var held = [Int?](repeating: nil, count: 4)
            for (p, r) in m.enumerated() { if let r { held[r] = p } }
            for p in 0 ..< 5 {
                for r in proposers[p] where acceptable(p, r) && m[p] != r {
                    let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                    let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                    if proposerPrefers && reviewerPrefers { return false }
                }
            }
            return true
        }
        var stable: [[Int?]] = []
        var current: [Int?] = []
        var taken = Set<Int>()
        func choose(_ p: Int) {
            guard p < 5 else {
                if isStable(current) { stable.append(current) }
                return
            }
            current.append(nil)
            choose(p + 1)
            current.removeLast()
            for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                taken.insert(r)
                current.append(r)
                choose(p + 1)
                current.removeLast()
                taken.remove(r)
            }
        }
        choose(0)
        #expect(stable.count == 1)
        let found = (0 ..< 5).map { result.mate(ofProposer: $0) }
        for p in 0 ..< 5 { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) } }
        #expect(isStable(found), "stable")
        #expect(stable.contains { $0 == found })
        for other in stable {
            // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.
            for p in 0 ..< 5 {
                if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other)") }
            }
            // Rural hospitals: every stable matching matches the same agents on both sides.
            #expect(other.map { $0 != nil } == found.map { $0 != nil })
            #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))
        }
    }
}
