// The edge set of a subgraph view with an edge filter: a bit mask over the base's edge indices,
// or, for a base without edge indices, the kept positions in sorted order (SubgraphView.swift).

/// A set of edge indices in `0..<bound` as a bit mask, with the number of set bits before each
/// 64-bit word, so a member's rank among the members costs one popcount.
@frozen
@usableFromInline
struct _EdgeMask: Sendable {
    @usableFromInline var words: [UInt64]
    /// `ranks[w]` is the number of members in words `0..<w`.
    @usableFromInline var ranks: [Int32]
    @usableFromInline var count: Int
    @usableFromInline let bound: Int

    @inlinable
    init(bound: Int) {
        precondition(bound <= Int(Int32.max), "Too many edges for an edge filter")
        self.bound = bound
        words = [UInt64](repeating: 0, count: (bound + 63) >> 6)
        ranks = []
        count = 0
    }

    @inlinable
    @inline(__always)
    func contains(_ i: Int) -> Bool {
        words[i >> 6] & (1 << UInt64(i & 63)) != 0
    }

    @inlinable
    mutating func insert(_ i: Int) {
        words[i >> 6] |= 1 << UInt64(i & 63)
    }

    @inlinable
    mutating func remove(_ i: Int) {
        words[i >> 6] &= ~(1 << UInt64(i & 63))
    }

    /// Computes the ranks and the count once the members are in. O(bound / 64).
    @inlinable
    mutating func seal() {
        var ranks = [Int32](repeating: 0, count: words.count)
        var total = 0
        for w in words.indices {
            ranks[w] = Int32(truncatingIfNeeded: total)
            total &+= words[w].nonzeroBitCount
        }
        self.ranks = ranks
        count = total
    }

    /// The number of members below `i`. O(1).
    @inlinable
    @inline(__always)
    func rank(_ i: Int) -> Int {
        let w = i >> 6
        let below = words[w] & ((1 << UInt64(i & 63)) &- 1)
        return Int(ranks[w]) &+ below.nonzeroBitCount
    }
}

/// The type-erased base class of a subgraph view's edge set, which lets `SubgraphView` store it
/// without knowing that its base is a graph. Immutable once made, and safe to share across
/// threads.
@usableFromInline
class _EdgeTestBox: @unchecked Sendable {
    @inlinable init() {}
}
