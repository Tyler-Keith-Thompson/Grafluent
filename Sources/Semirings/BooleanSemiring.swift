/// The Boolean semiring (∨, ∧): reachability, and over Floyd–Warshall Warshall's reflexive
/// transitive closure (Mohri; GraphBLAS's `GrB_LOR_LAND_SEMIRING_BOOL`).
///
/// `zero` is `false`, `one` is `true`, ⊕ is `||` and ⊗ is `&&`. `<` is the natural order, "true
/// before false": `BooleanSemiring(true) < BooleanSemiring(false)`. An edge weighing `false`
/// carries no path.
///
///     graph.floydWarshallShortestPaths { _ in BooleanSemiring(true) }
@frozen
public struct BooleanSemiring: SelectiveSemiring, Hashable, Sendable {
    /// Whether there is a path.
    public var value: Bool

    /// A Boolean value.
    @inlinable
    @inline(__always)
    public init(_ value: Bool) {
        self.value = value
    }

    /// `false`.
    @inlinable
    public static var zero: Self { Self(false) }

    /// `true`.
    @inlinable
    public static var one: Self { Self(true) }

    /// `||`.
    @inlinable
    @inline(__always)
    public func plus(_ other: Self) -> Self {
        Self(value || other.value)
    }

    /// `&&`.
    @inlinable
    @inline(__always)
    public func times(_ other: Self) -> Self {
        Self(value && other.value)
    }

    /// Whether `lhs` is `true` and `rhs` is `false`.
    @inlinable
    @inline(__always)
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value && !rhs.value
    }
}

extension BooleanSemiring: CustomStringConvertible {
    /// `"true"` or `"false"`.
    public var description: String { "\(value)" }
}
