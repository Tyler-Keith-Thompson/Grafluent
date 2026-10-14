# Semirings: API

The `Semiring` protocol, its `SelectiveSemiring` refinement, six semirings:
`TropicalSemiring` (min, +), `MaxPlusSemiring` (max, +), `BottleneckSemiring` (max, min),
`ViterbiSemiring` (max, ×), `BooleanSemiring` (∨, ∧) and `CountingSemiring` (+, ×), and the
`LexicographicSemiring` product of two selective semirings. The algorithms that take them are in ShortestPaths, as overloads of
its numeric (`W`) entry points plus `dagShortestDistances`.

`cases.md` (SR-001 – SR-577) pins the values; `LexicographicSemiring`, whose values are pairs, is
tested by hand (`SemiringProductTests.swift`). `ref.py` computes every row from the definitions
below with Swift's `Int` (trapping) and `Double` arithmetic. It recomputes every algorithm row
another way:

- tropical rows against NetworkX 3.7 and scipy 1.18.1 (`shortest_path` 'D', 'BF' and 'FW',
  `NegativeCycleError`, `floyd_warshall`, `negative_edge_cycle`), and max-plus rows the same way
  with every weight negated (a positive cycle is then a negative one);
- Viterbi rows by brute force over simple paths;
- bottleneck and Boolean rows by brute force over simple paths and against NetworkX
  `descendants` and `transitive_closure(reflexive=True)`;
- counting rows against `all_simple_edge_paths` or the closed forms 2^k and C(r+c−2, r−1).

It evaluates both sides of every law row and asserts that they are equal. `--stress` adds 300
random multigraphs per semiring and algorithm (loops, parallel edges, negative weights, n ≤ 7)
and 3,500 random law triples.

`uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with numpy==2.3.4 python3 Tests/Catalogs/Semirings/ref.py [--write] [--stress]`

Rows SR-430 – SR-458 (the "Phase 2" groups) pin `star`, `kleeneClosure` and `LogSemiring`, which
the library does not declare. `swiftgen.py` writes tests for them only with `--phase2`.

## Summary

```swift
// Semirings (no dependencies)
infix operator ⊕: AdditionPrecedence
infix operator ⊗: MultiplicationPrecedence

public protocol Semiring: Equatable {
    static var zero: Self { get }               // 0̄: plus's identity, annihilates under times
    static var one: Self { get }                // 1̄: times's identity
    func plus(_ other: Self) -> Self            // ⊕
    func times(_ other: Self) -> Self           // ⊗
}
extension Semiring {
    public static func ⊕ (lhs: Self, rhs: Self) -> Self    // lhs.plus(rhs)
    public static func ⊗ (lhs: Self, rhs: Self) -> Self    // lhs.times(rhs)
}
/// ⊕ returns one of its operands, and `<` is the natural order: a < b when a ⊕ b == a != b
/// ("a is better"). So a ⊕ b == min(a, b) by `<`, and `.zero` is the greatest element.
public protocol SelectiveSemiring: Semiring, Comparable {}

@frozen public struct TropicalSemiring<Value: _SemiringScalar>: SelectiveSemiring, Hashable, Sendable {
    public var value: Value
    public init(_ value: Value)
    // zero = +∞ (Int.max, .infinity), one = 0, ⊕ = min, ⊗ = + (0̄ absorbing, otherwise trapping)
}
@frozen public struct MaxPlusSemiring<Value: _SemiringScalar & SignedNumeric>: SelectiveSemiring, Hashable, Sendable {
    public var value: Value
    public init(_ value: Value)
    // zero = −∞ (Int.min, -.infinity), one = 0, ⊕ = max, ⊗ = + (0̄ absorbing, otherwise trapping); `<` is "longer"
}
@frozen public struct ViterbiSemiring<Value: _SemiringScalar & BinaryFloatingPoint>: SelectiveSemiring, Hashable, Sendable {
    public var value: Value
    public init(_ value: Value)
    // zero = 0, one = 1, ⊕ = max, ⊗ = *; `<` is "more probable"
}
@frozen public struct LexicographicSemiring<First: SelectiveSemiring, Second: SelectiveSemiring>: SelectiveSemiring {
    public let first: First, second: Second
    public init(_ first: First, _ second: Second)   // zero when either component is its zero
    // zero = (0̄, 0̄), one = (1̄, 1̄), ⊕ = the better by first, then second, ⊗ componentwise;
    // a semiring when First's ⊗ keeps strict order (integer tropical, max-plus)
}   // Hashable, Sendable when both are
@frozen public struct BottleneckSemiring<Value: _SemiringScalar>: SelectiveSemiring, Hashable, Sendable {
    public var value: Value
    public init(_ value: Value)
    // zero = −∞ (Int.min, -.infinity), one = +∞, ⊕ = max, ⊗ = min; `<` is "wider"
}
@frozen public struct BooleanSemiring: SelectiveSemiring, Hashable, Sendable {
    public var value: Bool
    public init(_ value: Bool)
    // zero = false, one = true, ⊕ = ||, ⊗ = &&; `<` is "true before false"
}
@frozen public struct CountingSemiring<Value: Numeric & Hashable>: Semiring, Hashable {
    public var value: Value
    public init(_ value: Value)
    // zero = 0, one = 1, ⊕ = +, ⊗ = * (trapping on Int overflow)
}
extension CountingSemiring: Sendable where Value: Sendable {}
// All four: CustomStringConvertible (the value, e.g. "3" or "inf")

/// The standard library's fixed-width integers and binary floating-point types. Underscored:
/// supplies ±∞ (`.max`/`.min` or `±.infinity`) and the tropical product of each; not for other types.
public protocol _SemiringScalar: Comparable, AdditiveArithmetic, Hashable, Sendable { … }

// ShortestPaths
extension DirectedGraph {
    public func dijkstraShortestPaths<S: SelectiveSemiring>(from source: Vertex, cutoff: S? = nil, weight: (Edges.Index) -> S) -> ShortestPathTree<Self, S>
    public func dijkstraShortestPaths<S: SelectiveSemiring>(from sources: some Sequence<Vertex>, cutoff: S? = nil, weight: (Edges.Index) -> S) -> ShortestPathTree<Self, S>
    public func dijkstraShortestPath<S: SelectiveSemiring>(from source: Vertex, to target: Vertex, weight: (Edges.Index) -> S) -> (path: Path<Vertex, Edges.Index>, distance: S)?
    public func bellmanFordShortestPaths<S: SelectiveSemiring>(from source: Vertex, weight: (Edges.Index) -> S) -> ShortestPathTree<Self, S>?
    public func bellmanFordShortestPaths<S: SelectiveSemiring>(from sources: some Sequence<Vertex>, weight: (Edges.Index) -> S) -> ShortestPathTree<Self, S>?
    public func dagShortestPaths<S: SelectiveSemiring>(from source: Vertex, weight: (Edges.Index) -> S) -> ShortestPathTree<Self, S>?
    public func dagShortestPaths<S: SelectiveSemiring>(from sources: some Sequence<Vertex>, weight: (Edges.Index) -> S) -> ShortestPathTree<Self, S>?
    public func dagShortestDistances<S: Semiring>(from source: Vertex, weight: (Edges.Index) -> S) -> ShortestDistances<Self, S>?
    public func dagShortestDistances<S: Semiring>(from sources: some Sequence<Vertex>, weight: (Edges.Index) -> S) -> ShortestDistances<Self, S>?
    public func floydWarshallShortestPaths<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> DistanceMatrix<Self, W>?
    public func floydWarshallShortestPaths<W: _SemiringScalar & BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> DistanceMatrix<Self, W>?   // +∞ is no edge
    public func floydWarshallShortestPaths<S: SelectiveSemiring>(weight: (Edges.Index) -> S) -> DistanceMatrix<Self, S>?
}
extension Graph {   // through `directedView`, like the W overloads
    public func dijkstraShortestPaths<S: SelectiveSemiring>(from: Vertex / some Sequence<Vertex>, cutoff: S? = nil, weight: (Edges.Index) -> S) -> ShortestPathTree<DirectedView<Self>, S>
    public func dijkstraShortestPath<S: SelectiveSemiring>(from: Vertex, to: Vertex, weight: (Edges.Index) -> S) -> (path: Path<Vertex, DirectedView<Self>.Edges.Index>, distance: S)?
    public func bellmanFordShortestPaths<S: SelectiveSemiring>(from: Vertex / some Sequence<Vertex>, weight: (Edges.Index) -> S) -> ShortestPathTree<DirectedView<Self>, S>?
    public func floydWarshallShortestPaths<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> DistanceMatrix<DirectedView<Self>, W>?
    public func floydWarshallShortestPaths<W: _SemiringScalar & BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> DistanceMatrix<DirectedView<Self>, W>?
    public func floydWarshallShortestPaths<S: SelectiveSemiring>(weight: (Edges.Index) -> S) -> DistanceMatrix<DirectedView<Self>, S>?
}
extension DirectedAcyclicGraph {
    public func dagShortestPaths<S: SelectiveSemiring>(from …, weight: …) -> ShortestPathTree<Self, S>       // not optional
    public func dagShortestDistances<S: Semiring>(from …, weight: …) -> ShortestDistances<Self, S>           // not optional
}

public struct ShortestPathTree<G: DirectedGraph, Distance: Comparable>
public struct ShortestDistances<G: DirectedGraph, Distance> {
    public let sources: [G.Vertex]
    public func distance(to vertex: G.Vertex) -> Distance          // .zero where no path
    public func distance(toIndex index: Int) -> Distance
}
public struct DistanceMatrix<G: DirectedGraph, Distance> {
    public func distance(from: G.Vertex, to: G.Vertex) -> Distance?          // nil where no path
    public func hasPath(from: G.Vertex, to: G.Vertex) -> Bool
    public func path(from: G.Vertex, to: G.Vertex) -> Path<G.Vertex, G.Edges.Index>?
    public func distance(fromIndex: Int, toIndex: Int) -> Distance?
}
```

Usage: `g.dijkstraShortestPaths(from: s) { BottleneckSemiring(capacity[$0]) }` (widest paths),
`g.floydWarshallShortestPaths { _ in BooleanSemiring(true) }` (transitive closure),
`dag.dagShortestDistances(from: s) { _ in CountingSemiring(1) }` (number of paths).

## Entry points

| Entry point | Semiring | Behavior |
|---|---|---|
| `dijkstraShortestPaths(from:cutoff:weight:)` (one source, several), `dijkstraShortestPath(from:to:weight:)` | `S: SelectiveSemiring`, no examined weight better than `.one` | Tropical gives shortest paths, bottleneck gives widest paths (the cutoff means "at least this wide"), Boolean gives reachability. |
| `bellmanFordShortestPaths(from:weight:)` (one, several) | `S: SelectiveSemiring` | `nil` when a cycle better than `.one` is reachable. Only the tropical semiring has such cycles. A −∞ distance (`Int.min`, `-.infinity`) cannot improve, so after the rounds a check on the subgraph of −∞ distances finds a cycle through a −∞ weight, or a negative cycle of finite weights there (SR-341 – SR-352). `findNegativeCycle` has only `W` overloads. |
| `dagShortestPaths(from:weight:)` on `DirectedGraph` (optional) and `DirectedAcyclicGraph` | `S: SelectiveSemiring` | Widest paths in a DAG, reachability. `nil` on a `DirectedGraph` when a cycle is reachable. |
| `dagShortestDistances(from:weight:)` → `ShortestDistances<Self, S>` (optional on `DirectedGraph`, not on `DirectedAcyclicGraph`) | `S: Semiring` | Mohri's shortest distance: ⊕ over every path of the ⊗ of its weights, in topological order. Over `CountingSemiring` it counts paths (with weights, weighted path sums). The one entry point that takes `CountingSemiring`. |
| `floydWarshallShortestPaths(weight:)` → `DistanceMatrix<Self, D>?` | `W: Comparable & AdditiveArithmetic`, `W: _SemiringScalar & BinaryFloatingPoint`, or `S: SelectiveSemiring` | All-pairs paths. Over `BooleanSemiring` it is the reflexive transitive closure (the diagonal is `.one`, the empty path). `nil` when a diagonal entry ends better than `.one`. The binary floating-point overload (`Double`, `Float`, `Float16`) runs the tropical loop, where a weight of +∞, or a path rounding to +∞, is no edge. Integers and other `W` treat every weight as an edge (SR-353, SR-354). |
| Undirected graphs | | Overloads on `Graph` of `dijkstraShortestPaths` (one source, several), `dijkstraShortestPath`, `bellmanFordShortestPaths` (one, several), and `floydWarshallShortestPaths` with its `W` and `S` overloads. Each answers as the same call on `directedView` (SR-220 and SR-239 call it directly). A reachable edge better than `.one` is a 2-cycle better than `.one`, so Bellman–Ford returns `nil`, as a negative edge does in the `W` overload. Tests: `SemiringUndirectedTests.swift`. |

## Rules

**Overloads.** The `S: SelectiveSemiring` overloads sit beside the `W: Comparable &
AdditiveArithmetic` ones. No semiring type conforms to `AdditiveArithmetic`, and no numeric type
conforms to `Semiring`, so `{ w[$0] }` with `w: [Int]` resolves to the `W` overload and
`{ TropicalSemiring(w[$0]) }` to the semiring one (SR-264 – SR-272 check that both give the same
distances).

**Laws.** `Semiring` requires `zero`, `one`, `plus(_:)` and `times(_:)`. `⊕` and `⊗` are an
extension that calls the two methods, so the spellings cannot disagree. The laws (⊕ associative
and commutative, identities, 0̄ annihilating, distributivity on both sides) are documented and
pinned per type by SR-008 – SR-207. `SelectiveSemiring` adds selectivity and the natural order
(`<`). Dijkstra requires `!(w < .one)` for each examined weight, the generalized `w >= .zero`
(SR-223); every bottleneck and Boolean weight meets it. ⊗ need not be commutative: algorithms
compute `distance ⊗ weight`, in path order. All four semirings are commutative.

`#expect` folds its expression without the custom operators' precedences, so
`#expect(a ⊕ b == c)` does not type-check while `#expect(a.plus(b) == c)` does.

**Distances start at `.zero`, and only a strictly better candidate relaxes.** An edge of weight
`.zero` therefore carries no path: `TropicalSemiring(.infinity)` and `Int.max` block an edge, and
`false` does in the Boolean semiring (SR-224, SR-274, SR-305). The `W` Dijkstra reaches a vertex
at distance `.infinity`. A vertex is reached exactly when its distance is not `.zero`.

**Infinity through `_SemiringScalar`.** The underscored protocol, conformed by the standard
library's fixed-width integers and `Float16`/`Float`/`Double`, supplies +∞ and −∞ (`.max`/`.min`,
`±.infinity`) and the tropical product. On signed integers either operand `.max` gives `.max`,
then either operand `.min` gives `.min`, otherwise `+`, which traps on overflow (SR-208 – SR-211,
SR-273). A finite sum that lands exactly on `Int.max` reads as 0̄ (SR-209), and one that lands on
`Int.min` stays there. Unsigned integers have no −∞ sentinel (`.min` is 0, the tropical one) and
check only `.max`. On floating point the product is plain `+`, since IEEE 754 already makes ∞
absorbing. The carrier is ℝ ∪ {+∞}, and −∞ ⊗ +∞ is NaN, not 0̄. No engine computes that product:
each skips a 0̄ distance, and a NaN candidate never relaxes.

On unsigned integers `BottleneckSemiring.zero` is `0`, so an edge of capacity 0 carries no path
(SR-355). `BottleneckSemiring`'s `Comparable` is the natural order, the reverse of the values':
`.max()` of some widths is the narrowest.

**NaN.** Each engine checks each examined weight for NaN (`precondition(w == w)`), as the `W`
engines do, and Dijkstra checks its cutoff.

**Integer sentinels.** Inside the library, `FixedWidthInteger` has a `package`
`static var infinity: Self { .max }`, and signed integers a `negativeInfinity` (`.min`). They are
absorbing sentinels, not arithmetic infinities (`Int.infinity + 1` traps), so they are not public.
`_SemiringScalar`'s requirements are `_semiringInfinity` and `_semiringNegativeInfinity`.

**`CountingSemiring<Int>` traps on overflow** (SR-214, SR-215, SR-335, SR-337), like every `W` sum
in ShortestPaths. `CountingSemiring<Double>` rounds past 2^53 (SR-217). Any `Numeric & Hashable`
big-integer type works as `Value`. 2^62 paths fit (SR-334), and C(66, 33) ≈ 7.2·10^18 fits
(SR-336).

**Weights** are a non-escaping `(Edges.Index) -> S` closure. Each semiring is a one-field
`@frozen` struct with `@inlinable` operations, so `{ TropicalSemiring(w[$0]) }` is an array read.

**`ShortestPathTree`'s `Distance`** is only `Comparable`: the tree stores and returns distances
and never adds them. `ShortestDistances` and `DistanceMatrix` constrain nothing.

**Floyd–Warshall.** Init 0̄, diagonal 1̄, parallel edges ⊕-combined, row i skipped when
`d[i][k] == .zero`, then `nil` if any diagonal entry ends better than `.one` (a negative loop
counts: SR-240). Paths are stored as the last edge into each target (`Edges.Index`, which tells
parallel edges apart), n² entries. Undirected graphs go through `.directedView`. Ties are not
pinned beyond the distances.

**Preconditions.** Empty sources trap only where a tree is returned (`dijkstraShortestPaths`,
`bellmanFordShortestPaths`, `dagShortestPaths`, as in the `W` overloads).
`dagShortestDistances(from: [])` returns every distance `.zero` with `sources == []`. A non-vertex
source or target traps in every entry point. The results trap on a non-vertex (`distance(to:)`,
`path(to:)`, `distance(from:to:)`, `path(from:to:)`) and on an index outside `0..<vertexCount`
(`distance(toIndex:)`, `distance(fromIndex:toIndex:)`, either index). Every ⊕ and ⊗ an algorithm
computes must succeed, so tropical `Int` and `CountingSemiring<Int>` overflow traps.

**Several sources in `dagShortestDistances`.** Each source starts at `.one`, listed once, and a
source reached from another adds both: 1 + the number of paths from the other (SR-322).

## Complexity

| Entry point | Time | Space |
|---|---|---|
| Dijkstra over `S` | O((n + m) log n), like `W` | O(n) |
| Bellman–Ford over `S` | O(nm) worst case, about one pass when no weight is better than `.one` | O(n) |
| `dagShortestPaths`, `dagShortestDistances` | O(n + m) over the reachable part | O(n) |
| `floydWarshallShortestPaths` | O(n³), skipping rows with `d[i][k] == .zero` | O(n²) distances + O(n²) edge positions |
