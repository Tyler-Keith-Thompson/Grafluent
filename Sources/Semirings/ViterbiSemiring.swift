/// The Viterbi semiring (max, ×) over `Value`, for most probable paths.
///
/// `zero` is 0, `one` is 1, ⊕ is `max` and ⊗ is `*`. `<` is the natural order, in which more
/// probable is better: `ViterbiSemiring(0.9) < ViterbiSemiring(0.2)`. The order is the reverse of
/// the values', so `[a, b].max()` is the less probable and `.min()` the more probable. A path's
/// value is the product of its weights, and a weight of 0 carries no path.
///
/// The carrier is the nonnegative values. With probabilities, every weight is in `0...1` and no
/// better than `one`, so Dijkstra's algorithm applies; a weight above 1 is still a semiring value,
/// but Dijkstra's algorithm then traps. Products of many small probabilities underflow to 0; over
/// long paths, `TropicalSemiring` over negative log-probabilities keeps the precision. No
/// operation checks for NaN or a negative value. The ShortestPaths entry points trap on a NaN
/// weight.
///
///     graph.dijkstraShortestPath(from: s, to: t) { ViterbiSemiring(probability[$0]) }
@frozen
public struct ViterbiSemiring<Value: _SemiringScalar & BinaryFloatingPoint>: SelectiveSemiring, Hashable, Sendable {
    /// The probability.
    public var value: Value

    /// A Viterbi value of probability `value`.
    @inlinable
    @inline(__always)
    public init(_ value: Value) {
        self.value = value
    }

    /// 0.
    @inlinable
    public static var zero: Self { Self(0) }

    /// 1.
    @inlinable
    public static var one: Self { Self(1) }

    /// The more probable: `max`.
    @inlinable
    @inline(__always)
    public func plus(_ other: Self) -> Self {
        value < other.value ? other : self
    }

    /// The product.
    @inlinable
    @inline(__always)
    public func times(_ other: Self) -> Self {
        Self(value * other.value)
    }

    /// Whether `lhs` is more probable: the reverse of the values' order.
    @inlinable
    @inline(__always)
    public static func < (lhs: Self, rhs: Self) -> Bool {
        rhs.value < lhs.value
    }
}

extension ViterbiSemiring: CustomStringConvertible {
    /// The value, as `"0.5"`.
    public var description: String { "\(value)" }
}
