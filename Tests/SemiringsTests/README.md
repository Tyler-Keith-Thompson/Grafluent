# Semirings test suite

`Semirings` holds the `Semiring` protocol, its `SelectiveSemiring` refinement and four semirings:
`TropicalSemiring` (min, +), `BottleneckSemiring` (max, min), `BooleanSemiring` (∨, ∧) and
`CountingSemiring` (+, ×). The algorithms that take them are ShortestPaths overloads: Dijkstra,
Bellman–Ford, DAG paths and Floyd–Warshall over a selective semiring, and `dagShortestDistances`
(Mohri's shortest distance) over any semiring. The tests come from the proposed API (`api.md` in
[`Tests/Catalogs/Semirings/`](../Catalogs/Semirings/), phase 1), with its open questions decided as
recommended:

- overloads of the existing entry points, not new names; the `W` overloads stay as they are;
- the protocol requires `zero`, `one`, `plus(_:)` and `times(_:)` (Haskell's `Data.Semiring`
  names), and `⊕` and `⊗` are operators in an extension that call them;
- the laws are documented, not checked by the types; `<` is the natural order ("better");
- distances start at `.zero`, so an edge of weight zero carries no path;
- `Int.max` is the tropical zero and absorbs (Boost's `closed_plus`); other sums trap on overflow,
  and so does `CountingSemiring<Int>`;
- Dijkstra requires that no examined weight is better than `.one`;
- Floyd–Warshall returns `nil` when a diagonal entry ends better than `.one`.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
protocol Semiring: Equatable { static var zero, one; func plus(_:), times(_:) }   // ⊕, ⊗ in an extension
protocol SelectiveSemiring: Semiring, Comparable                                    // < is the natural order
TropicalSemiring<Value>, BottleneckSemiring<Value>, BooleanSemiring, CountingSemiring<Value>  // .value, init(_:)
extension DirectedGraph {
    dijkstraShortestPaths(from:cutoff:weight:), dijkstraShortestPath(from:to:weight:)   // S: SelectiveSemiring
    bellmanFordShortestPaths(from:weight:), dagShortestPaths(from:weight:)             // optional
    dagShortestDistances(from:weight:) -> ShortestDistances<Self, S>?                  // S: Semiring
    floydWarshallShortestPaths(weight:) -> DistanceMatrix<Self, D>?                    // S, and the W overload
}
extension DirectedAcyclicGraph { dagShortestPaths, dagShortestDistances }               // not optional
ShortestDistances: sources, distance(to:), distance(toIndex:)
DistanceMatrix: distance(from:to:), distance(fromIndex:toIndex:), path(from:to:)
```

## How values are pinned

`swiftgen.py` writes one test per phase-1 catalog row (SR-001 – SR-429; SR-341 – SR-429 came from the review: −∞ in
Bellman–Ford, the floating-point `W` Floyd–Warshall, and the other scalar widths). It sits next to `ref.py`
and `cases.md` in [`Tests/Catalogs/Semirings/`](../Catalogs/Semirings/):

```
uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with numpy==2.3.4 \
    python3 Tests/Catalogs/Semirings/swiftgen.py [--phase2]
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. `ref.py` recomputes every row and
checks every algorithm row against NetworkX, scipy or brute force. With `--phase2` it also writes
`SemiringPhase2Tests.swift` (SR-430 – SR-458: `star`, `kleeneClosure`, `LogSemiring`), which phase
1 does not declare. Without the flag it removes that file.

- **Laws.** The catalog's operands, `S(value)`. The law is written with `plus(_:)` and `times(_:)`,
  both sides are compared, and their value is pinned. The same law in the operators must give the
  same values. Order rows also check `a < b` against its definition (`a.plus(b) == a && a != b`).
- **Arithmetic.** Both spellings, both operand orders. In the trap rows both spellings trap.
- **Graphs.** Algorithm rows build a `DirectedPseudograph` from the listed edges in position order.
  Undirected rows build a `Pseudograph` and read it through `.directed`. `w` holds the raw weights by
  position, and the weight closure is `{ S(w[$0]) }`. `ladder(k)` and `grid(r, c)` are built by loops.
- **Trees.** `distance(to:)`, `distance(toIndex:)`, `hasPath(to:)`, `sources`, and every
  `path(to:)` checked by the definition:
  - consecutive arcs of the graph;
  - from a source;
  - with a `times` product equal to the distance;
  - ending in `parentEdge(of:)`.
- **Matrices.** `distance(from:to:)`, `distance(fromIndex:toIndex:)`, and every `path(from:to:)`
  checked the same way, `nil` exactly where the distance is `nil`.
- **`dagShortestDistances`.** Every vertex, zero where no path. Over a selective semiring it is also
  checked against `dagShortestPaths`.
- **Agreement rows.** These also run the `W` overload, or Traversal's `descendants(of:)`.
- **Type rows** (SR-324, SR-333). The call that must not compile sits in an `#if false` block. The
  test checks through metatypes that `CountingSemiring` is a `Semiring` but neither selective nor
  `Comparable`.

A trap row runs the call in a child process (an exit test). The same setup then runs in this process
without the fault, so the trap comes from the call. The precondition file also takes the hand-written
exit tests in `extra_traps.swift`:

- non-vertex sources and targets in every entry point;
- empty source lists;
- tropical overflow in Bellman–Ford, the DAG entry points and Floyd–Warshall;
- counting overflow along a path and across paths;
- a weight better than one in the single-target search, with a cutoff, over `Double` and through
  `.directed`;
- out-of-range index reads;
- results read at a non-vertex.

`#expect` folds its expression without the custom operators' precedences, so `#expect(a ⊕ b == x
&& …)` does not type-check. The tests compute operator expressions outside the macro or
parenthesize them.

## Hand-written file

**Properties** (`SemiringPropertyTests.swift`, swift-property-based, with shrinking):

- **Laws on random values of all seven instantiations.** The values include the infinities (and
  `Int.min`, the tropical −∞). The test
  checks associativity, both identities, annihilation, distributivity on both sides and
  commutativity, in both spellings and with precedence. For the selective semirings it also checks
  selectivity, idempotence, the natural order against `plus`, trichotomy, transitivity, zero as the
  worst element, and the derived `<=` and `>`.
- **Semiring and `W` overloads agree** on random multigraphs with loops, parallel edges and
  negative weights, over `Int` and `Double`:
  - Dijkstra, with and without a cutoff, from one source and from several;
  - Bellman–Ford, including `nil`;
  - Floyd–Warshall, including `nil`, with each row equal to Bellman–Ford's;
  - DAG paths and `dagShortestDistances` on the acyclic orientation, also on `DirectedAcyclicGraph`.
- **Path counting on random DAGs against brute-force enumeration**, over `Int` and `Double`, on the
  graph and on its wrapper. Unit weights count the paths. With several sources, a source reached
  from another counts both.
- **Widest paths against brute force** over the simple paths: Dijkstra (also over `Double` and with
  a cutoff), Bellman–Ford, Floyd–Warshall, the single-target path's bottleneck, and DAG paths.
- **Boolean Floyd–Warshall against breadth-first search** over the true edges. The closure is
  reflexive. Dijkstra and Bellman–Ford reach the same vertices, and every matrix path uses only true
  edges.

**Undirected overloads** (`SemiringUndirectedTests.swift`, hand-written, 8 tests): the `Graph`
overloads of Dijkstra (one source, several, a cutoff, the single-target search), Bellman–Ford and
Floyd–Warshall against the same call on `.directed` and against the numeric overloads, on a
`Pseudograph` (native search) and an `UndirectedAdjacencyList<String>` (through the view); `nil`
exactly when an edge better than one is reachable (an edge at one is not); tree edges oriented the
way they are taken, against the stored edge's order too; and the same traps as the directed calls.

**Review additions** (`SemiringReviewTests.swift`, hand-written, 6 tests): Floyd–Warshall over
`Double` and `Float` reads `.infinity` (or a path rounding to it) as no edge, as in scipy, while
an integer or generic `W` keeps every weight as an edge, also on undirected graphs;
`DistanceMatrix.hasPath(from:to:)`; `BottleneckSemiring`'s order reversed from the values'
(`.max()` is the narrowest); and −∞ ⊗ +∞ over `Double` is NaN (the carrier is ℝ ∪ {+∞}). The
NaN-weight exit tests for every engine are in `extra_traps.swift`.

**Sentinels** (`SemiringSentinelTests.swift`, hand-written, 8 tests): what the catalog leaves out.
The unsigned bottleneck zero is 0, and `UInt.max` is the unsigned tropical zero and absorbs.
`Int.min` is the tropical −∞ and absorbs every finite value, and the zero absorbs before it
(`Int.max ⊗ Int.min` is the zero). Bellman–Ford with −∞ edges: a −∞ chain with a zero-weight
edge back is a tree; a cycle through a −∞ edge closed two edges later is `nil`; so is a finite
negative cycle whose vertices are already at −∞. DAG paths: an edge at the tropical zero reaches
nothing.

## Planted bugs

The suite was checked against a Swift model of the API outside the repository, built through Bazel
in a scratch copy of the workspace. It passes on the model (352 tests, and 381 with `--phase2`), and
it caught all 20 bugs planted in the model. A 21st mutant, setting each source to `.one` instead of
adding it, was equivalent, because sources are listed once.

| Planted bug | Caught by |
|---|---|
| Tropical `plus` is max | laws, SR-008 and 37 more |
| Tropical `Int` product without the `Int.max` check | SR-018, SR-023, overflow traps |
| Bottleneck product is max | SR-284, SR-301 – SR-303, widest-path property |
| Boolean `<` reversed | SR-005, SR-155, SR-159, SR-160 |
| Counting product adds | SR-170 and 33 more, counting property |
| `⊕` calls `times` | 126 tests |
| Tropical description not the value | SR-001, SR-002 |
| Dijkstra relaxing on ties, so a zero edge reaches | SR-224, SR-247, SR-274, SR-305, Boolean property |
| Dijkstra without the better-than-one check | SR-223, SR-246, extra traps |
| Dijkstra's cutoff inverted | SR-222, SR-245, SR-279, SR-292 |
| Bellman–Ford never `nil` | SR-228, SR-251, SR-265, agreement property |
| DAG order ignoring a reachable cycle | SR-232, SR-255, SR-320, SR-329 |
| A source reached from another not counting both | SR-322, SR-331, counting property |
| DAG distances overwriting instead of adding | SR-313, SR-316 and 22 more |
| Floyd–Warshall without the diagonal check | SR-238, SR-240, SR-261, SR-263 |
| Floyd–Warshall storing the wrong last edge | path checks in 23 matrix rows |
| Floyd–Warshall keeping the last parallel edge | SR-270, SR-302, SR-310, Boolean property |
| Floyd–Warshall skipping rows on one, not zero | SR-270, SR-307, SR-310, SR-315 |
| `ShortestDistances.distance(toIndex:)` unchecked | extra traps |
| `W` Floyd–Warshall never `nil` | agreement property |
