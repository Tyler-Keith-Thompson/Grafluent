/// The bottleneck semiring (max, min) over `Value`, for widest paths, also called
/// maximum-capacity or bottleneck paths (Gondran–Minoux).
///
/// `zero` is −∞ (`Int.min`, `-.infinity`), `one` is +∞ (`Int.max`, `.infinity`), ⊕ is `max` and
/// ⊗ is `min`, so neither ever overflows. `<` is the natural order, in which wider is better:
/// `BottleneckSemiring(9) < BottleneckSemiring(2)`. The order is the reverse of the values', so
/// `[a, b].max()` is the narrower and `.min()` the wider. A path's value is its narrowest edge,
/// and a weight equal to `zero` carries no path. No operation checks for NaN. The ShortestPaths
/// entry points trap on a NaN weight.
///
/// On unsigned integers `zero` is `0` (`Value.min`), so an edge of capacity 0 carries no path, as
/// −∞ does for signed integers and floating point.
///
///     graph.dijkstraShortestPaths(from: s) { BottleneckSemiring(capacity[$0]) }
///
/// Dijkstra's cutoff then means at least this wide.
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

    /// −∞: `Value.min` for integers (`0` for unsigned ones), `-.infinity` for floating point.
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

    /// Whether `lhs` is wider: the reverse of the values' order.
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
