/// ⊕, a semiring's sum: `a ⊕ b` is `a.plus(b)`.
infix operator ⊕: AdditionPrecedence

/// ⊗, a semiring's product: `a ⊗ b` is `a.times(b)`.
infix operator ⊗: MultiplicationPrecedence

/// A semiring (S, ⊕, ⊗, 0̄, 1̄), the algebra of path problems (Mohri 2002; Gondran–Minoux 2008).
///
/// ⊗ extends a path by an edge and ⊕ combines alternative paths. The shortest-path entry points in
/// ShortestPaths answer a different question for each conformer. The tropical semiring gives
/// shortest paths, the bottleneck semiring widest paths, the Boolean semiring reachability, and the
/// counting semiring the number of paths.
///
/// A conformer implements the four requirements. The type system does not check the laws, and an
/// algorithm's result is meaningful only when they hold:
///
/// - ⊕ is associative and commutative, with identity `zero`;
/// - ⊗ is associative, with identity `one`;
/// - `zero` annihilates: `a ⊗ 0̄ == 0̄ ⊗ a == 0̄`;
/// - ⊗ distributes over ⊕ from both sides.
///
/// ⊗ need not be commutative. Algorithms always compute `distance ⊗ weight`, in path order.
///
/// `zero` is not `AdditiveArithmetic.zero`. No semiring type here is a number, and a tropical
/// `zero` is +∞.
///
/// The operators `⊕` and `⊗` call `plus(_:)` and `times(_:)`, so the two spellings always agree.
/// Prefer the methods where another module might declare the same operators, and inside
/// `#expect`. That macro folds an expression without these operators' precedences, so
/// `#expect(a ⊕ b == c)` does not type-check, while `#expect(a.plus(b) == c)` does.
public protocol Semiring: Equatable {
    /// 0̄: the identity of `plus(_:)`, which annihilates under `times(_:)`. In a path problem, the
    /// value of no path.
    static var zero: Self { get }

    /// 1̄: the identity of `times(_:)`. In a path problem, the value of the empty path.
    static var one: Self { get }

    /// ⊕: combines two alternatives.
    func plus(_ other: Self) -> Self

    /// ⊗: extends by `other`.
    func times(_ other: Self) -> Self
}

extension Semiring {
    /// `lhs.plus(rhs)`.
    @inlinable
    @inline(__always)
    public static func ⊕ (lhs: Self, rhs: Self) -> Self {
        lhs.plus(rhs)
    }

    /// `lhs.times(rhs)`.
    @inlinable
    @inline(__always)
    public static func ⊗ (lhs: Self, rhs: Self) -> Self {
        lhs.times(rhs)
    }
}

/// A semiring whose ⊕ returns one of its operands (a selective dioid in Gondran–Minoux's terms),
/// with `<` as its natural order.
///
/// `a < b` exactly when `a ⊕ b == a` and `a != b`, read as "a is better than b". `a ⊕ b` is the
/// better of the two, `<` is a strict total order, and `zero` is the worst element. `<` is not the
/// order of the raw values: `BottleneckSemiring(9) < BottleneckSemiring(2)` because wider is
/// better, and `BooleanSemiring(true) < BooleanSemiring(false)`.
///
/// Dijkstra's algorithm, Bellman–Ford, DAG shortest paths and Floyd–Warshall in ShortestPaths take
/// a selective semiring. Dijkstra's algorithm also needs every examined weight to be no better than
/// `one`, so that extending a path never improves it. A negative tropical weight breaks that, and
/// no bottleneck or Boolean weight does.
public protocol SelectiveSemiring: Semiring, Comparable {}
