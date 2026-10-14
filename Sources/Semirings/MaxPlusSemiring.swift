/// The max-plus semiring (max, +) over `Value`, for longest paths, also called the arctic
/// semiring.
///
/// `zero` is −∞ (`Int.min`, `-.infinity`), `one` is 0, ⊕ is `max` and ⊗ is `+`. `<` is the
/// natural order, in which longer is better: `MaxPlusSemiring(9) < MaxPlusSemiring(2)`. The order
/// is the reverse of the values', so `[a, b].max()` is the shorter and `.min()` the longer.
///
/// ⊗ is a closed sum. −∞ (the zero) absorbs every value, and any other sum traps on integer
/// overflow. A finite integer sum that lands exactly on `.min` is the zero, so an edge of that
/// weight carries no path. The carrier is ℝ ∪ {−∞}, without +∞. No operation checks for NaN. The
/// ShortestPaths entry points trap on a NaN weight.
///
/// Longest paths exist where no cycle has a positive length: `dagShortestPaths` gives them in an
/// acyclic graph, and Bellman–Ford returns `nil` when a positive cycle is reachable. Dijkstra's
/// algorithm needs every examined weight to be at most 0.
///
///     dag.dagShortestPaths(from: s) { MaxPlusSemiring(duration[$0]) }
@frozen
public struct MaxPlusSemiring<Value: _SemiringScalar & SignedNumeric>: SelectiveSemiring, Hashable, Sendable {
    /// The length.
    public var value: Value

    /// A max-plus value of length `value`.
    @inlinable
    @inline(__always)
    public init(_ value: Value) {
        self.value = value
    }

    /// −∞: `Value.min` for integers, `-.infinity` for floating point.
    @inlinable
    public static var zero: Self { Self(Value._semiringNegativeInfinity) }

    /// 0.
    @inlinable
    public static var one: Self { Self(.zero) }

    /// The longer: `max`.
    @inlinable
    @inline(__always)
    public func plus(_ other: Self) -> Self {
        value < other.value ? other : self
    }

    /// The sum, with −∞ absorbing; traps on integer overflow.
    @inlinable
    @inline(__always)
    public func times(_ other: Self) -> Self {
        let negativeInfinity = Value._semiringNegativeInfinity
        if value == negativeInfinity || other.value == negativeInfinity { return .zero }
        return Self(value + other.value)
    }

    /// Whether `lhs` is longer: the reverse of the values' order.
    @inlinable
    @inline(__always)
    public static func < (lhs: Self, rhs: Self) -> Bool {
        rhs.value < lhs.value
    }
}

extension MaxPlusSemiring: CustomStringConvertible {
    /// The value, as `"3"` or `"-inf"`.
    public var description: String { "\(value)" }
}
