/// The standard library's fixed-width integers and binary floating-point types, as the values of
/// `TropicalSemiring` and `BottleneckSemiring`.
///
/// Underscored: it supplies +∞ and −∞ (`±.infinity` for floating point; for integers the
/// package-level sentinels `.infinity` and `.negativeInfinity`, which are `.max` and `.min`) and the
/// tropical product, and is not meant for other conformers.
public protocol _SemiringScalar: Comparable, AdditiveArithmetic, Hashable, Sendable {
    /// +∞: `.infinity` (for integers the sentinel `.max`).
    static var _semiringInfinity: Self { get }

    /// −∞: `-.infinity` (for integers the sentinel `.min`).
    static var _semiringNegativeInfinity: Self { get }

    /// The tropical product: `a + b`, with +∞ absorbing.
    static func _tropicalProduct(_ a: Self, _ b: Self) -> Self
}

extension FixedWidthInteger {
    /// `.max`, the absorbing sentinel that stands for +∞ in the integer semirings (the tropical
    /// zero, the bottleneck one). Not an arithmetic infinity: `Int.infinity + 1` traps. Package
    /// level, so library users never see a misleading `Int.infinity`.
    @inlinable
    @inline(__always)
    package static var infinity: Self { .max }
}

extension FixedWidthInteger where Self: SignedInteger {
    /// `.min`, the absorbing sentinel that stands for −∞ in the integer semirings (the bottleneck
    /// zero). Not an arithmetic infinity: `Int.negativeInfinity - 1` traps. Package level, as
    /// `infinity`.
    @inlinable
    @inline(__always)
    package static var negativeInfinity: Self { .min }
}

extension _SemiringScalar where Self: FixedWidthInteger & SignedInteger {
    @inlinable
    public static var _semiringInfinity: Self { .infinity }

    @inlinable
    public static var _semiringNegativeInfinity: Self { .negativeInfinity }

    /// Boost's `closed_plus`: +∞ (`.infinity`, which is `.max`) absorbs, then −∞
    /// (`.negativeInfinity`, `.min`), and any other sum traps on overflow. A finite sum landing
    /// exactly on `.max` reads as +∞.
    @inlinable
    @inline(__always)
    public static func _tropicalProduct(_ a: Self, _ b: Self) -> Self {
        if a == .infinity || b == .infinity { return .infinity }
        if a == .negativeInfinity || b == .negativeInfinity { return .negativeInfinity }
        return a + b
    }
}

extension _SemiringScalar where Self: FixedWidthInteger & UnsignedInteger {
    @inlinable
    public static var _semiringInfinity: Self { .infinity }

    /// `0` (`.min`), which is also the tropical `one`, so it does not absorb: there is no −∞
    /// sentinel for unsigned integers.
    @inlinable
    public static var _semiringNegativeInfinity: Self { .min }

    /// +∞ (`.infinity`, which is `.max`) absorbs; any other sum traps on overflow.
    @inlinable
    @inline(__always)
    public static func _tropicalProduct(_ a: Self, _ b: Self) -> Self {
        if a == .infinity || b == .infinity { return .infinity }
        return a + b
    }
}

extension _SemiringScalar where Self: BinaryFloatingPoint {
    @inlinable
    public static var _semiringInfinity: Self { .infinity }

    @inlinable
    public static var _semiringNegativeInfinity: Self { -.infinity }

    /// Plain `+`: IEEE 754 already makes `.infinity` absorb every finite value. `-.infinity +
    /// .infinity` is NaN; the tropical carrier is ℝ ∪ {+∞} (Mohri), without −∞.
    @inlinable
    @inline(__always)
    public static func _tropicalProduct(_ a: Self, _ b: Self) -> Self {
        a + b
    }
}

extension Int: _SemiringScalar {}
extension Int8: _SemiringScalar {}
extension Int16: _SemiringScalar {}
extension Int32: _SemiringScalar {}
extension Int64: _SemiringScalar {}
extension UInt: _SemiringScalar {}
extension UInt8: _SemiringScalar {}
extension UInt16: _SemiringScalar {}
extension UInt32: _SemiringScalar {}
extension UInt64: _SemiringScalar {}
extension Float: _SemiringScalar {}
extension Double: _SemiringScalar {}
#if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
extension Float16: _SemiringScalar {}
#endif
