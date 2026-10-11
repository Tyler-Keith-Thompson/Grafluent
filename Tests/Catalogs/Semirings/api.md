# Semirings: proposed API (phase 1, with phase 2 pinned)

The `Semiring` protocol, its `SelectiveSemiring` refinement, and four semirings:
`TropicalSemiring` (min, +), `BottleneckSemiring` (max, min), `BooleanSemiring` (∨, ∧) and
`CountingSemiring` (+, ×). The algorithms that take them live in ShortestPaths, as overloads of
its existing entry points plus one new name. Phase 2 adds `ClosedSemiring` (Kleene star),
`kleeneClosure(weight:)` (Lehmann's algebraic path problem), `LogSemiring`, and Mohri's generic
single-source algorithm for graphs with cycles.

`cases.md` (SR-001 – SR-369, 369 rows; SR-341 – SR-369 are phase 2) pins the values. `ref.py`
computes every row from the definitions below with Swift's `Int` (trapping) and `Double`
arithmetic. It recomputes every algorithm row another way: tropical rows against NetworkX 3.7 and
scipy 1.18.1 (`shortest_path` 'D', 'BF' and 'FW', `NegativeCycleError`, `floyd_warshall`,
`negative_edge_cycle`), bottleneck and Boolean rows by brute force over simple paths and against
NetworkX `descendants` and `transitive_closure(reflexive=True)`, and counting rows against
`all_simple_edge_paths` or the closed forms 2^k and C(r+c−2, r−1). It evaluates both sides of
every law row and asserts that they are equal. `--stress` adds 300 random multigraphs per
semiring and algorithm (loops, parallel edges, negative weights, n ≤ 7), the phase-2 closure
against its definition, and 3,500 random law triples. Run (about 2 s with `--stress`):

`uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with numpy==2.3.4 python3 Tests/Catalogs/Semirings/ref.py [--write] [--stress]`

## Scope

**Phase 1**

| Entry point | Semiring | Why |
|---|---|---|
| `dijkstraShortestPaths(from:cutoff:weight:)` (one source, several), `dijkstraShortestPath(from:to:weight:)` | `S: SelectiveSemiring`, no weight better than `.one` | Dijkstra is correct exactly when ⊕ picks one operand (a total natural order) and extending a path never improves it (Knuth's superior functions, 1977; Mohri 2002 §4; Gondran–Minoux ch. 4). Tropical gives shortest paths. Bottleneck gives **widest paths** (igraph `widest_path_widths_dijkstra`, Pollack's maximum-capacity route), and its cutoff means "at least this wide". Boolean gives reachability. |
| `bellmanFordShortestPaths(from:weight:)` (one, several) | `S: SelectiveSemiring` | LEMON's weak rounds; `nil` when a cycle whose weight is better than `.one` is reachable. That cycle is negative in the tropical semiring, and it cannot exist in the bottleneck or Boolean ones (SR-283: the tropical rows' negative cycle is harmless there). `findNegativeCycle` keeps its `W` overloads only, since only the tropical semiring has such cycles. |
| `dagShortestPaths(from:weight:)` on `DirectedGraph` (optional) and `DirectedAcyclicGraph` | `S: SelectiveSemiring` | Boost's `dag_shortest_paths` over any selective semiring: widest paths in a DAG, reachability. |
| `dagShortestDistances(from:weight:)` → `ShortestDistances<Self, S>` (optional on `DirectedGraph`, not on `DirectedAcyclicGraph`) | `S: Semiring` | Mohri's shortest distance: ⊕ over **every** path of the ⊗ of its weights, in topological order. Over `CountingSemiring` it is **path counting** (with weights, weighted path sums). It needs no idempotence, so it is the one entry point that takes `CountingSemiring`. |
| `floydWarshallShortestPaths(weight:)` → `DistanceMatrix<Self, D>?`, with both the existing `W: Comparable & AdditiveArithmetic` overload and the `S: SelectiveSemiring` one | either | README already plans Floyd–Warshall and `DistanceMatrix`. Over a selective semiring it is the all-pairs case of the algebraic path problem: all-pairs widest paths, and over `BooleanSemiring` **Warshall's transitive closure** (reflexive: the diagonal is `.one`, the empty path; NetworkX `transitive_closure(reflexive=True)`). `nil` when a diagonal entry ends better than `.one` (scipy's `NegativeCycleError`, NetworkX's negative diagonal). |
| Undirected graphs | | Overloads on `Graph` mirroring the `W` ones in `Undirected.swift`: `dijkstraShortestPaths` (one source, several), `dijkstraShortestPath`, `bellmanFordShortestPaths` (one, several), and `floydWarshallShortestPaths` with both its `W` and `S` overloads. Each runs over `directed` (SR-220 and SR-239 call it directly), and Dijkstra walks the graph's own rows when it has vertex indices. A reachable edge better than `.one` is a 2-cycle better than `.one` (w ⊗ w ⊑ w < 1̄), so Bellman–Ford returns `nil` after one O(V + E) pass, as a negative edge does in the `W` overload. Tests: `SemiringUndirectedTests.swift`, written by hand. |

**Phase 2** (rows pinned now, SR-341 – SR-369)

| Entry point | Why |
|---|---|
| `ClosedSemiring` (`star`), conformances for the tropical, bottleneck and Boolean semirings | Lehmann 1977: a closed semiring has a\* = 1̄ ⊕ a ⊕ a² ⊕ … . Tropical: a\* = 0 when a ≥ 0, else −∞; bottleneck: +∞; Boolean: `true`. `CountingSemiring<Int>` is not closed (1\* is infinite) and does not conform. |
| `kleeneClosure(weight:)` → `DistanceMatrix<Self, S>` (`S: ClosedSemiring`) | The algebraic path problem on graphs with any cycles (Lehmann; Rote 1990), Floyd–Warshall with d_kk\* in the middle. Tropical with negative cycles gives −∞ through them (SR-354), where Floyd–Warshall returns `nil`. |
| `LogSemiring<Value: BinaryFloatingPoint>` | Mohri's log semiring (⊕ = −log(e^−a + e^−b), ⊗ = +): path probabilities with `dagShortestDistances` (SR-369). Needs `log`/`exp` on a generic floating type, so it waits for a decision on swift-numerics `Real`, a new dependency. |
| `shortestDistances(from:weight:)` on graphs with cycles | Mohri's generic single-source algorithm over k-closed semirings (a queue, ⊕-accumulated residuals). Phase 1 has no type that needs it: the selective ones go through Bellman–Ford, and counting on a cyclic graph diverges. |

**Not planned, or later**

| Not in phase 1 | Reason |
|---|---|
| `IdempotentSemiring` as its own protocol | Gondran–Minoux's term, but no phase-1 type is idempotent without being selective, and no phase-1 algorithm needs idempotence alone. Add it with its first conformer (a set-of-paths semiring, say). |
| A semiring A\* | A\* adds a heuristic to the distance, an operation outside the semiring (Huang 2008 needs extra structure). It keeps its `W` overload only. |
| `widestPath(…)`, `transitiveClosure()` on `DirectedGraph`, `countPaths(…)` | These are the semiring overloads with a type argument (doc comments show the three uses). A second name per problem would be a synonym. `DirectedAcyclicGraph.transitiveClosure()`, which returns a graph, stays. |
| Max-plus ("arctic") semiring, `MaxTimes`, `MinTimes`, `PlusMin` and the other GraphBLAS built-ins | No graph algorithm in the plan needs them. DAG longest paths are `DirectedAcyclicGraph.longestPath(weight:)`. |
| Semiring matrix products (GraphBLAS `mxm`, `vxm`) | Linear-algebra kernels, not path algorithms. They belong to SpectralGraphTheory if ever. |

## Summary

```swift
// Semirings (Vocabulary layer; no dependencies)
infix operator ⊕: AdditionPrecedence
infix operator ⊗: MultiplicationPrecedence

public protocol Semiring: Equatable {
    static var zero: Self { get }               // 0̄: plus's identity, annihilates under times
    static var one: Self { get }                // 1̄: times's identity
    func plus(_ other: Self) -> Self            // ⊕ (Haskell Data.Semiring's `plus`)
    func times(_ other: Self) -> Self           // ⊗ (Haskell Data.Semiring's `times`)
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

// ShortestPaths (now depends on Semirings)
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
    public func floydWarshallShortestPaths<S: SelectiveSemiring>(weight: (Edges.Index) -> S) -> DistanceMatrix<Self, S>?
    // Phase 2
    public func kleeneClosure<S: ClosedSemiring>(weight: (Edges.Index) -> S) -> DistanceMatrix<Self, S>
}
extension Graph {   // through `directed`, as the W overloads in Undirected.swift
    public func dijkstraShortestPaths<S: SelectiveSemiring>(from: Vertex / some Sequence<Vertex>, cutoff: S? = nil, weight: (Edges.Index) -> S) -> ShortestPathTree<DirectedView<Self>, S>
    public func dijkstraShortestPath<S: SelectiveSemiring>(from: Vertex, to: Vertex, weight: (Edges.Index) -> S) -> (path: Path<Vertex, DirectedView<Self>.Edges.Index>, distance: S)?
    public func bellmanFordShortestPaths<S: SelectiveSemiring>(from: Vertex / some Sequence<Vertex>, weight: (Edges.Index) -> S) -> ShortestPathTree<DirectedView<Self>, S>?
    public func floydWarshallShortestPaths<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> DistanceMatrix<DirectedView<Self>, W>?
    public func floydWarshallShortestPaths<S: SelectiveSemiring>(weight: (Edges.Index) -> S) -> DistanceMatrix<DirectedView<Self>, S>?
}
extension DirectedAcyclicGraph {
    public func dagShortestPaths<S: SelectiveSemiring>(from …, weight: …) -> ShortestPathTree<Self, S>       // not optional
    public func dagShortestDistances<S: Semiring>(from …, weight: …) -> ShortestDistances<Self, S>           // not optional
}

public struct ShortestPathTree<G: DirectedGraph, Distance: Comparable>   // was Comparable & AdditiveArithmetic; a loosening
public struct ShortestDistances<G: DirectedGraph, Distance> {
    public let sources: [G.Vertex]
    public func distance(to vertex: G.Vertex) -> Distance          // .zero where no path
    public func distance(toIndex index: Int) -> Distance
}
public struct DistanceMatrix<G: DirectedGraph, Distance> {
    public func distance(from: G.Vertex, to: G.Vertex) -> Distance?          // nil where no path
    public func path(from: G.Vertex, to: G.Vertex) -> Path<G.Vertex, G.Edges.Index>?   // not for kleeneClosure
    public func distance(fromIndex: Int, toIndex: Int) -> Distance?
}

// Phase 2
public protocol ClosedSemiring: Semiring { var star: Self { get } }
@frozen public struct LogSemiring<Value: BinaryFloatingPoint>: Semiring, Comparable, Hashable
extension LogSemiring: Sendable where Value: Sendable {}
```

Usage: `g.dijkstraShortestPaths(from: s) { BottleneckSemiring(capacity[$0]) }` (widest paths),
`g.floydWarshallShortestPaths { _ in BooleanSemiring(true) }` (transitive closure),
`dag.dagShortestDistances(from: s) { _ in CountingSemiring(1) }` (number of paths).

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `Semiring`, `zero`, `one` | Mohri 2002 (0̄, 1̄), Haskell `semirings` (`zero`, `one`), Julia Semirings.jl (`zero`, `one`), GraphBLAS (the add monoid's identity) | `additiveIdentity` / `multiplicativeIdentity`: longer, and Swift already says `zero` for an additive identity. No semiring type conforms to `AdditiveArithmetic` or `Numeric`, so the two `zero`s never meet (a tropical `zero` is +∞). |
| `plus(_:)`, `times(_:)`, and the operators `⊕`, `⊗` | Haskell `semirings` (`Data.Semiring`: `plus`, `times`, `zero`, `one`); the operators after Mohri, Gondran–Minoux, Lehmann, Julia Semirings.jl (`⊕`, `⊗`) and README's own wording | Operators only: `⊕` and `⊗` are hard to type, so the requirements are the named methods and the operators are defined once, in an extension, by calling them (Haskell likewise defines `+` and `*` from `plus` and `times`). Not `+`/`*` themselves: `+` on a tropical value that computes `min` misleads, and `TropicalSemiring` must not look like a number. `add`/`multiply` (no library uses them for semirings). One risk: another module declaring `⊕` with another precedence makes a call site that imports both ambiguous; the methods are never ambiguous. A second reason to prefer the methods: Swift Testing's `#expect` folds its expression without these operators' precedences, so `#expect(a ⊕ b == c)` does not type-check, while `#expect(a.plus(b) == c)` does (the tests compute operator expressions outside the macro). The `Semiring` doc comment says so. |
| `SelectiveSemiring` | Gondran–Minoux, *Graphs, Dioids and Semirings* (2008), "selective dioid": a ⊕ b ∈ {a, b} | `OrderedSemiring` (a different notion in the literature: an order compatible with both operations), `TotallyOrderedSemiring`, `DijkstraSemiring`. |
| `<` as the natural order | Mohri's natural order (a ⊑ b iff a ⊕ b = a), Gondran–Minoux's canonical order | Comparing raw values. Bottleneck and Boolean then read reversed (`BottleneckSemiring(9) < BottleneckSemiring(2)`, `true < false`), but `<` means "better" in every selective semiring, so Dijkstra's queue, its cutoff and the "better than one" check are one code path. The raw value is `.value`. |
| `ClosedSemiring`, `star` | Lehmann 1977 "closed semiring", Haskell `Star` class (`star`), Kleene algebra | `asteroid`, `closure` (the matrix operation is the closure, the element operation the star). |
| `TropicalSemiring` = (min, +) | Mohri, Pin ("tropical semiring" = min-plus), GraphBLAS `GrB_MIN_PLUS_SEMIRING_*`, Semirings.jl `TropicalSemiring` | `MinPlusSemiring` (GraphBLAS's spelling, longer). TropicalNumbers.jl uses max-plus for "tropical": the doc comment states min-plus. |
| `BottleneckSemiring` = (max, min) | Gondran–Minoux, "bottleneck" / maximum-capacity path problem, GraphBLAS `GrB_MAX_MIN_SEMIRING_*` | `WidestPathSemiring`, `MaxMinSemiring`. |
| `BooleanSemiring` | Mohri, GraphBLAS `GrB_LOR_LAND_SEMIRING_BOOL`, Semirings.jl `BoolSemiring` | |
| `CountingSemiring` | Green, Karvounarakis, Tannen 2007 (the counting semiring ℕ); Haskell `semirings` has it as the numeric instance | `ProbabilitySemiring` (Mohri; a probability is a `CountingSemiring<Double>`, same operations), `PlusTimesSemiring` (GraphBLAS). |
| `dagShortestDistances`, `ShortestDistances` | Mohri 2002's "single-source shortest-distance problem" over any semiring (δ(s, q) = ⊕ over paths) | `pathCount`/`countPaths`: true only for the counting semiring. `pathSums`, `algebraicPaths`: not used by any library. "Shortest" reads oddly for a count, so the doc comment opens with Mohri's definition. |
| `floydWarshallShortestPaths`, `DistanceMatrix` | Boost `floyd_warshall_all_pairs_shortest_paths`, JGraphT `FloydWarshallShortestPaths`, NetworkX `floyd_warshall`; README's `DistanceMatrix` | |
| `kleeneClosure` | Kleene's algorithm (McNaughton–Yamada), Lehmann's and Rote's "closure" A\* | `algebraicPathProblem`, `transitiveClosure` (already a DAG member returning a graph). |

## Decisions

**D1. Overloads, not new names, for selective semirings.** `dijkstraShortestPaths`,
`bellmanFordShortestPaths`, `dagShortestPaths` and `floydWarshallShortestPaths` gain
`S: SelectiveSemiring` overloads. The `W: Comparable & AdditiveArithmetic` overloads stay as they
are. No type satisfies both constraints: no semiring type conforms to `AdditiveArithmetic`, and
no numeric type conforms to `Semiring`. So `{ w[$0] }` with `w: [Int]` resolves to the `W`
overload and `{ TropicalSemiring(w[$0]) }` to the semiring one, without ambiguity (SR-264 – SR-272
pin that both give the same distances). The one new name, `dagShortestDistances`, has a different
result (no tree: ⊕ over all paths) and takes non-selective semirings.

**D2. Requirements live in protocols, laws in documentation.** `Semiring` requires the four
operations: `zero`, `one`, `plus(_:)` and `times(_:)`. `⊕` and `⊗` are an extension on `Semiring`
calling the two methods, not requirements, so a conformer writes only the methods and the two
spellings cannot disagree. The laws (associativity, ⊕ commutative, identities, 0̄ annihilating, distributivity
on both sides) are documented and pinned per type by SR-008 – SR-207. `SelectiveSemiring` adds
selectivity and the natural order (`<`). Dijkstra's extra condition, that no weight is better
than `.one` (a ⊑ a ⊗ w), is a **precondition per examined edge**: `!(w < .one)`, the generalized
`w >= .zero` that Dijkstra already checks (SR-223). It is true of every bottleneck and Boolean
weight. `⊗` commutativity is not required (all four are commutative, SR rows say "not a
requirement"), so a phase-2 non-commutative semiring stays possible: algorithms always compute
`distance ⊗ weight`, in path order.

**D3. Distances start at `.zero`, and only a strictly better candidate relaxes.** The `W`
engines need a parent sentinel because `W` has no infinity. The semiring engines use `.zero`, the
worst element, so the relax test is `candidate < distance[v]` alone, one comparison fewer than
`parent[v] == -2 || …`. It follows that **an edge of weight `.zero` carries no path**
(annihilation): `TropicalSemiring(.infinity)` and `Int.max` block an edge, and `false` does in
the Boolean semiring (SR-224, SR-274, SR-305). The `W` Dijkstra, by contrast, reaches a vertex at
distance `.infinity`. A vertex is reached exactly when its distance is not `.zero`.

**D4. Infinity is a value, through `_SemiringScalar`.** `TropicalSemiring.zero` must be +∞,
which `Comparable & AdditiveArithmetic` cannot name. An underscored protocol, conformed by the
standard library's fixed-width integers and `Float16`/`Float`/`Double`, supplies +∞ and −∞
(`.max`/`.min`, `±.infinity`) and the tropical product. The tropical product on integers is
Boost's `closed_plus`: either operand `Int.max` gives `Int.max`, otherwise `+`, which traps on
overflow (SR-208 – SR-211, SR-273). A finite sum that lands exactly on `Int.max` reads as 0̄, as
in Boost (SR-209). After the `Int.max` check, either operand `Int.min` (−∞) gives `Int.min`, as
`ref.py`'s `trop_times_int` does: −∞ is absorbing except against 0̄, so phase 2's star (which
returns −∞) composes without overflow, and a path whose finite sum lands exactly on `Int.min`
stays there (the precondition tests' `bellmanFordShortestPaths` row reaching `Int.min`). Unsigned
integers have no −∞ sentinel (`.min` is 0, the tropical one) and check only `.max`. On floating
point, the product is plain `+`, since IEEE already makes ∞ absorbing. −∞ (and NaN) are outside
phase 1's laws: −∞ + ∞ is NaN, where `ref.py`'s `trop_times_double` returns ∞; phase 2 must
settle that before `star` produces −∞ over `Double`.

**There is no generic NaN check.** The semiring engines never compare a value with itself:
`TropicalSemiring(.nan)` compares false with everything, so it is never better than `.one`
(Dijkstra does not trap) and never better than a distance (it never relaxes). The `W` overloads
keep their NaN preconditions, and the `W` Floyd–Warshall checks each weight.

**Integer sentinels are spelled `.infinity`.** Inside the library, `FixedWidthInteger` has a
`package` (not `public`) `static var infinity: Self { .max }`, and signed integers a
`negativeInfinity` (`.min`), so the code reads `a == .infinity` where it means +∞ and
`Double`'s own `.infinity` reads the same. They are absorbing sentinels, not arithmetic
infinities (`Int.infinity + 1` traps), which is why they stay package-level: a public
`Int.infinity` would mislead library users. `_SemiringScalar`'s requirements keep underscored
names (`_semiringInfinity`, `_semiringNegativeInfinity`), which integers satisfy through these
sentinels and floating point through `±.infinity`. Rejected: `Value?` storage (Haskell's `Tropical = Infinity | Tropical a`)
doubles `Double`'s stride to 16 bytes; and a runtime cast in `zero` turns an unsupported type into
a trap instead of a compile error.

**D5. `CountingSemiring` over `Int` traps on overflow** (SR-214, SR-215, SR-335, SR-337), like
every `W` sum in ShortestPaths ("every sum fits in W"). Saturating would return a wrong count
without saying so, and wrapping would return a wrong count. `CountingSemiring<Double>` rounds past
2^53 (SR-217). For exact big counts, any `Numeric & Hashable` big-integer type works unchanged,
because `Value` is generic. 2^62 paths fit (SR-334), and C(66, 33) ≈ 7.2·10^18 fits (SR-336).

**D6. Weights flow as today:** a non-escaping `(Edges.Index) -> S` closure, so README open
question 3's fast path is unchanged. The wrapper is a one-field `@frozen` struct with
`@inlinable` operations, so `{ TropicalSemiring(w[$0]) }` is an array read (measured below).
The attached maps of open question 9 feed these closures the same way.

**D7. One engine body per algorithm.** The engines already take `arcs` and `weight` as
parameters, not stored closures (the "boxed captures" lesson). They gain an `extend` parameter
(`+` for `W`, `⊗` for `S`) and a relax predicate. The `W` path passes exactly the operations it
uses today, so it does not change. Gate: the benchmark below must stay within 1.05× for
`TropicalSemiring<Double>` before the overloads merge.

**D8. `ShortestPathTree`'s `Distance` loosens to `Comparable`.** It stores and returns
distances and never adds them. `ShortestDistances` (Mohri) and `DistanceMatrix` constrain nothing.

**D9. Floyd–Warshall details.** Init 0̄, diagonal 1̄, parallel edges ⊕-combined, scipy's row skip
(`d[i][k] == .zero` skips row i), then `nil` if any diagonal entry ends better than `.one`
(a negative loop counts: SR-240). Paths are stored as the last edge into each target
(`Edges.Index`, which tells parallel edges apart), as a predecessor-edge matrix, n² entries.
Undirected graphs go through `.directed`. Ties are not pinned beyond the distances.

**D11. Preconditions the tests assume.** Empty sources trap only where a tree is returned
(`dijkstraShortestPaths`, `bellmanFordShortestPaths`, `dagShortestPaths`, as the `W` overloads);
`dagShortestDistances(from: [])` returns every distance `.zero` with `sources == []`, Mohri's
problem with no initial weights. A non-vertex source or target traps in every entry point. The
results trap on a non-vertex (`distance(to:)`, `path(to:)`, `distance(from:to:)`,
`path(from:to:)`) and on an index outside `0..<vertexCount` (`distance(toIndex:)`,
`distance(fromIndex:toIndex:)`, either index). Every ⊕ and ⊗ an algorithm computes must succeed,
so tropical `Int` and `CountingSemiring<Int>` overflow traps (D4, D5).

**D10. Multi-source `dagShortestDistances`:** each source starts at `.one`, listed once, and a
source reached from another adds both: 1 + the number of paths from the other (SR-322), Mohri's
initial weights.

## Performance (measured 2026-10-11, Apple M-series, `swiftc -O -wmo`, Xcode Swift 6.4)

Prototype in the session scratchpad (not kept): the engines' loops copied from
`Dijkstra.swift` and `BellmanFord.swift`, with `IndexedPriorityQueue.swift` copied verbatim and a
`_RowArcs` CSR walk. Random digraph with n = 200,000 and m = 2,000,000 from vertex 0. Interleaved
runs; the table gives the median ratio, with a second run where one was made. Noise is about ±4%.

| Engine | `W` specialised | `S` = `TropicalSemiring` | Ratio S / W |
|---|---|---|---|
| Dijkstra, `Double` | 55.4 ms | 56.9 ms | **1.028**, 0.985 |
| Bellman–Ford, `Double` | 132.9 ms | 128.7 ms | **0.969**, 0.981 |
| Dijkstra, `Int` (closed ⊗) | 56.2 ms | 59.9 ms | 1.065, 1.054, 1.078 |
| Bellman–Ford, `Int` (closed ⊗) | 122.2 ms | 130.7 ms | 1.070, 1.073, 1.066 |
| Dijkstra / Bellman–Ford, `Int` with plain `+` (no 0̄ check) | | | 0.975 / 1.039 |
| Floyd–Warshall, `Double`, n = 1000, p = 0.01 | 619.9 ms | 620.5 ms | **1.001** |

So `TropicalSemiring<Double>` is free: it meets the 1.05× gate. `TropicalSemiring<Int>` pays
5–8% for the lawful 0̄ check (`a == .max || b == .max`). Skipping 0̄-weight edges in the engine
measured worse (1.08). That cost is why the `W` overloads stay separate and are not rerouted
through `TropicalSemiring` (D1, D7): an `Int` caller of the existing API pays nothing.

Floyd–Warshall against the references, on the same kind of graph (random, p = 0.01, weights
0–99.9), best of 5:

| n | Swift, `Double` (scipy's loop) | Swift, semiring, with predecessors | scipy `floyd_warshall` | scipy, predecessors | NetworkX `floyd_warshall_numpy` | NetworkX `floyd_warshall` |
|---|---|---|---|---|---|---|
| 300 | 6.8 – 9.2 ms | 7.0 ms | 7.9 ms | 8.6 ms | 20.2 ms | 1,209 ms |
| 1000 | 535 – 826 ms | 437 – 516 ms | 479 – 728 ms | 634 ms | 962 ms | — |

At n = 1000 the matrix is 8 MB and every implementation is memory-bound, and the spread between
runs is as large as the gap between implementations. The Swift loop is on par with scipy's Cython
and about 2× faster than NetworkX's numpy version. The branch-free `min` store and the predecessor
variant vectorize differently; pick the loop with the repo's benchmark harness when implementing.

## Complexity

| Entry point | Time | Space |
|---|---|---|
| Dijkstra over `S` | O((n + m) log n), like `W` | O(n) |
| Bellman–Ford over `S` | O(nm) worst case, about one pass when no weight is better than `.one` | O(n) |
| `dagShortestPaths`, `dagShortestDistances` | O(n + m) over the reachable part | O(n) |
| `floydWarshallShortestPaths` | O(n³), skipping rows with `d[i][k] == .zero` | O(n²) distances + O(n²) edge positions |
| `kleeneClosure` (phase 2) | O(n³) ⊗ and n `star`s | O(n²) |

## README changes to make when implementing

- Weights (`Semirings`) table: `SelectiveSemiring` and the natural order (D2); `CountingSemiring`
  is `Hashable`, not `Comparable`; Bottleneck's and Boolean's `<` is "better", not the raw value.
- The sentence "the semiring generalization is for algebraic path problems such as Floyd–Warshall
  and DAG paths" becomes: Dijkstra, Bellman–Ford, DAG paths and Floyd–Warshall take selective
  semirings, and `dagShortestDistances` takes any semiring.
- `scripts/modules.py`: ShortestPaths gains the Semirings dependency (the ShortestPaths catalog's
  first version listed it).
- ShortestPaths: Floyd–Warshall and `DistanceMatrix` move to implemented, with the `W` overload.
