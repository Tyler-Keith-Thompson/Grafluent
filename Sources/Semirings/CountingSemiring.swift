/// The counting semiring (+, ×) over `Value` (Green, Karvounarakis and Tannen's ℕ): with unit
/// weights, `dagShortestDistances` counts the paths; with other weights it sums, over every path,
/// the product of its weights (a probability semiring when the weights are probabilities).
///
/// `zero` is 0, `one` is 1, ⊕ is `+` and ⊗ is `*`. Not selective (⊕ is not idempotent: `a ⊕ a ==
/// 2a`) and not `Comparable`, so only `dagShortestDistances` takes it.
///
/// Over `Int` both operations trap on overflow, like every sum in ShortestPaths: a saturated or
/// wrapped count would be wrong without saying so. 2⁶² paths fit. `Double` rounds past 2⁵³. For
/// exact large counts, use any `Numeric & Hashable` big-integer type.
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
