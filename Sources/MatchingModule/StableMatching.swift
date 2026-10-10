/// The proposer-optimal stable matching (Gale and Shapley's deferred acceptance). Each list ranks
/// the other side's indices, best first; a pair is acceptable when each lists the other. Unequal
/// sides and incomplete lists are allowed. The result is unique, so the order of proposals does
/// not matter: every proposer gets the best reviewer it has in any stable matching, and the same
/// agents are matched in all of them. O(total list length).
///
/// - Precondition: every index is in range, and no index appears twice in one list.
@inlinable
public func stableMatching(proposerPreferences: [[Int]], reviewerPreferences: [[Int]]) -> StableMatching {
    let p = proposerPreferences.count, r = reviewerPreferences.count
    var total = 0
    for list in reviewerPreferences { total += list.count }
    // Each reviewer's rank of each proposer it lists (−1: not listed): a dense table when it is at
    // most a few times the input, otherwise a dictionary keyed reviewer · p + proposer.
    let dense = r.multipliedReportingOverflow(by: p).partialValue <= 8 * total + (1 << 20) && !r.multipliedReportingOverflow(by: p).overflow
    var table = dense ? [Int](repeating: -1, count: r * p) : []
    var sparse: [Int: Int] = [:]
    var stamp = [Int](repeating: -1, count: max(p, r))
    for (reviewer, list) in reviewerPreferences.enumerated() {
        for (k, proposer) in list.enumerated() {
            precondition(proposer >= 0 && proposer < p, "Proposer \(proposer) is out of range")
            precondition(stamp[proposer] != reviewer, "Reviewer \(reviewer) lists proposer \(proposer) twice")
            stamp[proposer] = reviewer
            if dense { table[reviewer * p + proposer] = k } else { sparse[reviewer * p + proposer] = k }
        }
    }
    for k in stamp.indices { stamp[k] = -1 }
    for (proposer, list) in proposerPreferences.enumerated() {
        for reviewer in list {
            precondition(reviewer >= 0 && reviewer < r, "Reviewer \(reviewer) is out of range")
            precondition(stamp[reviewer] != proposer, "Proposer \(proposer) lists reviewer \(reviewer) twice")
            stamp[reviewer] = proposer
        }
    }
    var next = [Int](repeating: 0, count: p)
    var held = [Int](repeating: -1, count: r)
    var free = Array((0 ..< p).reversed())
    while let proposer = free.popLast() {
        let list = proposerPreferences[proposer]
        while next[proposer] < list.count {
            let reviewer = list[next[proposer]]
            next[proposer] += 1
            let mine = dense ? table[reviewer * p + proposer] : sparse[reviewer * p + proposer] ?? -1
            if mine < 0 { continue }
            let current = held[reviewer]
            if current < 0 {
                held[reviewer] = proposer
                break
            }
            let theirs = dense ? table[reviewer * p + current] : sparse[reviewer * p + current]!
            if mine < theirs {
                held[reviewer] = proposer
                free.append(current)
                break
            }
        }
    }
    var mate = [Int](repeating: -1, count: p)
    for reviewer in 0 ..< r where held[reviewer] >= 0 { mate[held[reviewer]] = reviewer }
    return StableMatching(proposerMates: mate, reviewerMates: held)
}

/// A stable matching between proposers and reviewers, by index: the result of `stableMatching`.
@frozen
public struct StableMatching: Hashable, Sendable, CustomStringConvertible {
    @usableFromInline let _proposerMates: [Int]
    @usableFromInline let _reviewerMates: [Int]

    @inlinable
    init(proposerMates: [Int], reviewerMates: [Int]) {
        _proposerMates = proposerMates
        _reviewerMates = reviewerMates
    }

    /// The reviewer matched to `proposer`, or nil.
    ///
    /// - Precondition: `proposer` is in range.
    @inlinable
    public func mate(ofProposer proposer: Int) -> Int? {
        precondition(proposer >= 0 && proposer < _proposerMates.count, "Proposer \(proposer) is out of range")
        let m = _proposerMates[proposer]
        return m < 0 ? nil : m
    }

    /// The proposer matched to `reviewer`, or nil.
    ///
    /// - Precondition: `reviewer` is in range.
    @inlinable
    public func mate(ofReviewer reviewer: Int) -> Int? {
        precondition(reviewer >= 0 && reviewer < _reviewerMates.count, "Reviewer \(reviewer) is out of range")
        let m = _reviewerMates[reviewer]
        return m < 0 ? nil : m
    }

    /// `{0–2, 1–0}`: each matched proposer with its reviewer, by proposer.
    public var description: String {
        "{" + _proposerMates.enumerated().filter { $0.element >= 0 }.map { "\($0.offset)–\($0.element)" }.joined(separator: ", ") + "}"
    }
}
