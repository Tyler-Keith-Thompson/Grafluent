/// The lexicographic product of two selective semirings, for paths best by `First` with ties
/// broken by `Second` (Mohri's lexicographic semiring): the shortest among the widest paths, or
/// the fewest hops among the shortest.
///
/// A value is a pair. ⊗ multiplies componentwise, and ⊕ keeps the better pair: the better
/// `first`, and on a tie the better `second`. `zero` is `(First.zero, Second.zero)` and `one` is
/// `(First.one, Second.one)`. `<` compares `first`, then `second`. A pair with either component at
/// its zero is the zero: `init(_:_:)` makes it one, and so does a product in which either
/// component reaches its zero, so no path is half reached.
///
/// The laws hold when `First`'s ⊗ keeps strict order on both sides: `a < b` gives `a ⊗ c < b ⊗ c`
/// and `c ⊗ a < c ⊗ b` for every `c` other than `zero`. Integer `TropicalSemiring` and
/// `MaxPlusSemiring` values keep it (floating point up to rounding), so the lexicographic product
/// of either with any selective semiring is a selective semiring, and Dijkstra's algorithm,
/// Bellman–Ford and the other selective entry points give best pairs. A bottleneck or Boolean
/// `first` does not keep it: a narrow edge can tie two paths of different widths, and ⊕ then no
/// longer distributes.
///
///     // Shortest paths, the fewest edges among equals.
///     graph.dijkstraShortestPaths(from: s) { LexicographicSemiring(TropicalSemiring(length[$0]), TropicalSemiring(1)) }
@frozen
public struct LexicographicSemiring<First: SelectiveSemiring, Second: SelectiveSemiring>: SelectiveSemiring {
    /// The value that decides first.
    public let first: First

    /// The value that breaks ties in `first`.
    public let second: Second

    /// The pair (`first`, `second`), or `zero` when either component is its semiring's zero.
    @inlinable
    @inline(__always)
    public init(_ first: First, _ second: Second) {
        if first == .zero || second == .zero {
            self.first = .zero
            self.second = .zero
        } else {
            self.first = first
            self.second = second
        }
    }

    /// (`First.zero`, `Second.zero`).
    @inlinable
    public static var zero: Self { Self(.zero, .zero) }

    /// (`First.one`, `Second.one`).
    @inlinable
    public static var one: Self { Self(.one, .one) }

    /// The better pair, by `first` and then `second`.
    @inlinable
    @inline(__always)
    public func plus(_ other: Self) -> Self {
        other < self ? other : self
    }

    /// The componentwise product, or `zero` when either component's product is its zero.
    @inlinable
    @inline(__always)
    public func times(_ other: Self) -> Self {
        Self(first.times(other.first), second.times(other.second))
    }

    /// Whether `lhs` is better: a better `first`, or an equal one and a better `second`.
    @inlinable
    @inline(__always)
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.first < rhs.first || (lhs.first == rhs.first && lhs.second < rhs.second)
    }
}

extension LexicographicSemiring: Hashable where First: Hashable, Second: Hashable {}

extension LexicographicSemiring: Sendable where First: Sendable, Second: Sendable {}

extension LexicographicSemiring: CustomStringConvertible {
    /// The pair, as `"(3, 2)"`.
    public var description: String { "(\(first), \(second))" }
}
