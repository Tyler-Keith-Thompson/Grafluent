/// The tropical semiring (min, +) over `Value`: shortest paths (Mohri; GraphBLAS's
/// `GrB_MIN_PLUS_SEMIRING`). Some libraries call max-plus "tropical"; this one is min-plus.
///
/// `zero` is +∞ (`Int.max`, `.infinity`), `one` is 0, ⊕ is `min` and ⊗ is `+`. `<` compares the
/// values: shorter is better.
///
/// On integers ⊗ is Boost's `closed_plus`: `.max` (+∞, the zero) absorbs, then `.min` (−∞), and
/// any other sum traps on overflow. A finite sum that lands exactly on `.max` is the zero, so an
/// edge of that weight carries no path. On floating point ⊗ is `+`, where `.infinity` absorbs every
/// finite value. −∞ and NaN are outside the laws (`-.infinity + .infinity` is NaN), and no
/// operation checks for NaN.
///
///     graph.dijkstraShortestPaths(from: s) { TropicalSemiring(length[$0]) }
@frozen
public struct TropicalSemiring<Value: _SemiringScalar>: SelectiveSemiring, Hashable, Sendable {
    /// The length.
    public var value: Value

    /// A tropical value of length `value`.
    @inlinable
    @inline(__always)
    public init(_ value: Value) {
        self.value = value
    }

    /// +∞: `Value.max` for integers, `.infinity` for floating point.
    @inlinable
    public static var zero: Self { Self(Value._semiringInfinity) }

    /// 0.
    @inlinable
    public static var one: Self { Self(.zero) }

    /// The shorter: `min`.
    @inlinable
    @inline(__always)
    public func plus(_ other: Self) -> Self {
        other.value < value ? other : self
    }

    /// The sum, with +∞ absorbing (and −∞ on integers); traps on integer overflow.
    @inlinable
    @inline(__always)
    public func times(_ other: Self) -> Self {
        Self(Value._tropicalProduct(value, other.value))
    }

    /// Whether `lhs` is shorter.
    @inlinable
    @inline(__always)
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}

extension TropicalSemiring: CustomStringConvertible {
    /// The value, as `"3"` or `"inf"`.
    public var description: String { "\(value)" }
}
