/// The counting semiring (+, ×) over `Value` (Green, Karvounarakis and Tannen's ℕ).
///
/// With unit weights, `dagShortestDistances` counts the paths. With other weights it sums, over
/// every path, the product of the path's weights, which is the probability semiring when the
/// weights are probabilities.
///
/// `zero` is 0, `one` is 1, ⊕ is `+` and ⊗ is `*`. It is not selective, because ⊕ is not
/// idempotent (`a ⊕ a == 2a`), and not `Comparable`, so only `dagShortestDistances` takes it.
///
/// Over `Int` both operations trap on overflow, like every sum in ShortestPaths, because a
/// saturated or wrapped count would be silently wrong. `Int.max` paths fit: 2⁶³ − 1, or 2³¹ − 1 where
/// `Int` is 32 bits. `Double` rounds past 2⁵³.
/// For exact large counts, use any `Numeric & Hashable` big-integer type.
///
///     dag.dagShortestDistances(from: s) { _ in CountingSemiring(1) }
@frozen
public struct CountingSemiring<Value: Numeric & Hashable>: Semiring, Hashable {
    /// The count, or sum of products.
    public var value: Value

    /// A counting value.
    @inlinable
    @inline(__always)
    public init(_ value: Value) {
        self.value = value
    }

    /// 0.
    @inlinable
    public static var zero: Self { Self(.zero) }

    /// 1.
    @inlinable
    public static var one: Self { Self(1) }

    /// `+`, trapping on integer overflow.
    @inlinable
    @inline(__always)
    public func plus(_ other: Self) -> Self {
        Self(value + other.value)
    }

    /// `*`, trapping on integer overflow.
    @inlinable
    @inline(__always)
    public func times(_ other: Self) -> Self {
        Self(value * other.value)
    }
}

extension CountingSemiring: Sendable where Value: Sendable {}

extension CountingSemiring: CustomStringConvertible {
    /// The value, as `"3"` or `"0.5"`.
    public var description: String { "\(value)" }
}
