/// What Gale and Shapley's deferred acceptance reports, in order, as `stableMatching` runs it.
///
/// Free proposers are taken from a stack, lowest index first at the start. A free proposer
/// proposes to the next reviewer on its list. The reviewer rejects a proposer it does not list or
/// ranks below the one it holds, accepts when it holds no one, and otherwise trades up, freeing
/// the proposer it held, who goes on top of the stack. A rejected proposer proposes again; an
/// accepted one waits. A proposer whose list runs out stays unmatched. The pairs held at the end
/// are `stableMatching`'s matching.
@frozen
public enum GaleShapleyEvent: Hashable, Sendable {
    /// `proposer` proposes to `reviewer`, the next one on its list.
    case propose(proposer: Int, reviewer: Int)
    /// `reviewer`, holding no one, holds `proposer`.
    case accept(proposer: Int, reviewer: Int)
    /// `reviewer` does not list `proposer`, or prefers the proposer it holds.
    case reject(proposer: Int, reviewer: Int)
    /// `reviewer` drops `from`, now free again, and holds `to`, whom it prefers.
    case tradeUp(reviewer: Int, from: Int, to: Int)
    /// `proposer` has proposed to every reviewer on its list and stays unmatched.
    case exhausted(proposer: Int)
}

extension GaleShapleyEvent: CustomStringConvertible {
    /// `propose(p → r)`, `accept(p, r)`, `reject(p, r)`, `tradeUp(r: a → b)`, `exhausted(p)`.
    public var description: String {
        switch self {
        case .propose(let p, let r): "propose(\(p) → \(r))"
        case .accept(let p, let r): "accept(\(p), \(r))"
        case .reject(let p, let r): "reject(\(p), \(r))"
        case .tradeUp(let r, let a, let b): "tradeUp(\(r): \(a) → \(b))"
        case .exhausted(let p): "exhausted(\(p))"
        }
    }
}

/// Gale and Shapley's deferred acceptance as a sequence of `GaleShapleyEvent`s, one proposal at a
/// time: the proposals of `stableMatching`, in its order. It holds the preference lists, and can
/// be iterated more than once.
@frozen
public struct GaleShapleyEvents: Sequence, Sendable {
    public typealias Element = GaleShapleyEvent

    @usableFromInline let proposerPreferences: [[Int]]
    @usableFromInline let reviewerCount: Int
    @usableFromInline let ranks: _StableMatchingRanks

    @inlinable
    init(proposerPreferences: [[Int]], reviewerPreferences: [[Int]]) {
        self.proposerPreferences = proposerPreferences
        reviewerCount = reviewerPreferences.count
        ranks = _StableMatchingRanks(proposerPreferences: proposerPreferences, reviewerPreferences: reviewerPreferences)
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(self) }

    public struct Iterator: IteratorProtocol, Sendable {
        @usableFromInline let base: GaleShapleyEvents
        @usableFromInline var nextChoice: [Int]
        @usableFromInline var held: [Int]
        @usableFromInline var free: [Int]
        /// The proposer proposing, or -1 to take the next free one.
        @usableFromInline var current = -1
        /// The reviewer's answer to the proposal just reported.
        @usableFromInline var answer: GaleShapleyEvent?

        @inlinable
        init(_ base: GaleShapleyEvents) {
            self.base = base
            let p = base.proposerPreferences.count
            nextChoice = [Int](repeating: 0, count: p)
            held = [Int](repeating: -1, count: base.reviewerCount)
            free = Array((0 ..< p).reversed())
        }

        @inlinable
        public mutating func next() -> GaleShapleyEvent? {
            if let answer {
                self.answer = nil
                return answer
            }
            if current < 0 {
                guard let proposer = free.popLast() else { return nil }
                current = proposer
            }
            let proposer = current
            let list = base.proposerPreferences[proposer]
            guard nextChoice[proposer] < list.count else {
                current = -1
                return .exhausted(proposer: proposer)
            }
            let reviewer = list[nextChoice[proposer]]
            nextChoice[proposer] += 1
            let mine = base.ranks.rank(of: proposer, by: reviewer)
            let holding = held[reviewer]
            if mine < 0 {
                answer = .reject(proposer: proposer, reviewer: reviewer)
            } else if holding < 0 {
                held[reviewer] = proposer
                current = -1
                answer = .accept(proposer: proposer, reviewer: reviewer)
            } else if mine < base.ranks.rank(of: holding, by: reviewer) {
                held[reviewer] = proposer
                free.append(holding)
                current = -1
                answer = .tradeUp(reviewer: reviewer, from: holding, to: proposer)
            } else {
                answer = .reject(proposer: proposer, reviewer: reviewer)
            }
            return .propose(proposer: proposer, reviewer: reviewer)
        }
    }
}

/// Gale and Shapley's deferred acceptance, as `stableMatching` runs it, as a sequence of events:
/// each proposal, then the reviewer's acceptance, rejection or trade-up, and each proposer left
/// unmatched. See `GaleShapleyEvent` for the order. There is no graph to take `lazy` from, so the
/// stepper is a function of the preference lists, like `stableMatching` itself.
///
/// - Precondition: every index is in range, and no index appears twice in one list.
/// - Complexity: O(total list length) to make the sequence and to iterate every event.
@inlinable
public func galeShapley(proposerPreferences: [[Int]], reviewerPreferences: [[Int]]) -> GaleShapleyEvents {
    GaleShapleyEvents(proposerPreferences: proposerPreferences, reviewerPreferences: reviewerPreferences)
}
