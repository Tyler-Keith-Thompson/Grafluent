/// The bottleneck semiring (max, min) over `Value`: widest paths, also called maximum-capacity or
/// bottleneck paths (Gondran–Minoux; GraphBLAS's `GrB_MAX_MIN_SEMIRING`).
///
/// `zero` is −∞ (`Int.min`, `-.infinity`), `one` is +∞ (`Int.max`, `.infinity`), ⊕ is `max` and
/// ⊗ is `min`, so neither ever overflows. `<` is the natural order, "wider": `BottleneckSemiring(9) <
/// BottleneckSemiring(2)`. A path's value is its narrowest edge, and a weight of −∞ carries no
/// path. No operation checks for NaN.
///
///     graph.dijkstraShortestPaths(from: s) { BottleneckSemiring(capacity[$0]) }
///
/// Dijkstra's cutoff then means "at least this wide".
@frozen
public struct BottleneckSemiring<Value: _SemiringScalar>: SelectiveSemiring, Hashable, Sendable {
    /// The width.
    public var value: Value

    /// A bottleneck value of width `value`.
    @inlinable
    @inline(__always)
    public init(_ value: Value) {
        self.value = value
    }

    /// −∞: `Value.min` for integers, `-.infinity` for floating point.
    @inlinable
    public static var zero: Self { Self(Value._semiringNegativeInfinity) }

    /// +∞: `Value.max` for integers, `.infinity` for floating point.
    @inlinable
    public static var one: Self { Self(Value._semiringInfinity) }

    /// The wider: `max`.
    @inlinable
    @inline(__always)
    public func plus(_ other: Self) -> Self {
        value < other.value ? other : self
    }

    /// The narrower: `min`.
    @inlinable
    @inline(__always)
    public func times(_ other: Self) -> Self {
        other.value < value ? other : self
    }

    /// Whether `lhs` is wider.
    @inlinable
    @inline(__always)
    public static func < (lhs: Self, rhs: Self) -> Bool {
        rhs.value < lhs.value
    }
}

extension BottleneckSemiring: CustomStringConvertible {
    /// The value, as `"3"` or `"inf"`.
    public var description: String { "\(value)" }
}
