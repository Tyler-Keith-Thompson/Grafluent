/// The tropical semiring (min, +) over `Value`, for shortest paths (Mohri). This is the min-plus
/// form.
///
/// `zero` is +∞ (`Int.max`, `.infinity`), `one` is 0, ⊕ is `min` and ⊗ is `+`. `<` compares the
/// values, so shorter is better.
///
/// On integers ⊗ is a closed sum. `.max` (+∞, the zero) absorbs, then `.min` (−∞), and any other
/// sum traps on overflow. A finite sum that lands exactly on `.max` is the zero, so an edge of
/// that weight carries no path.
///
/// On floating point the carrier is ℝ ∪ {+∞}, and ⊗ is `+`, where `.infinity` absorbs every finite
/// value. −∞ is outside the carrier, and `-.infinity ⊗ .zero` is NaN, not `.zero`. No algorithm
/// here computes that product, because each skips a `.zero` distance and treats a NaN candidate as
/// no improvement. No operation checks for NaN. The ShortestPaths entry points trap on a NaN
/// weight.
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

/// A selective semiring with values that absorb ⊗ by everything but `zero`, as the tropical −∞
/// does. A distance at such a value cannot improve, so Bellman–Ford reads this to find a cycle
/// better than `one` that the saturated distances hide. Not meant for other conformers.
public protocol _SaturatingSemiring: SelectiveSemiring {
    /// Whether `self ⊗ x == self` for every `x` other than `zero`.
    var _isSaturated: Bool { get }
}

extension TropicalSemiring: _SaturatingSemiring {
    /// Whether the value is −∞ (`Int.min`, `-.infinity`); never for unsigned integers, whose
    /// `.min` is `one`.
    @inlinable
    public var _isSaturated: Bool {
        Value._semiringNegativeInfinity < .zero && value == Value._semiringNegativeInfinity
    }
}
