# TreeAlgorithms test suite

`TreeAlgorithms` answers queries over the Trees module's immutable types: the lowest common
ancestor (one-shot on `RootedTree` and `Arborescence`, or precomputed in `LowestCommonAncestors`
with O(1) queries and the unweighted `distance`), the Euler tour of a `RootedTree` as a Walks
`Walk<Vertex, Int>`, the `HeavyLightDecomposition` (heavy children, heads, positions, subtree
intervals, path segments), and the root-free measures on `Tree`: `center`, `centroid`,
`centroidDecomposition`, `diameter` and `diameterPath`, unweighted and weighted. The tests were
written before the implementation, from the proposed API (`api.md`, phase 1). The suite uses only
the public API and is self-contained per test; shared material is the `ReferencePseudograph` and
`ReferenceDirectedMultigraph` test conformers, `Collider`, the seeded generator and the tags in
`GrafluentTestSupport`.

## API under test

```swift
extension RootedTree {                                              // and the first on Arborescence
    func lowestCommonAncestor(of a: Vertex, _ b: Vertex) -> Vertex  // reflexive: lca(v, v) = v; traps on a non-vertex
    var eulerTour: Walk<Vertex, Int>                                // 2n − 1 vertices, children(of:) order
}
struct LowestCommonAncestors<Vertex: Hashable>                       // Sendable when Vertex is
    init(_ tree: RootedTree<Vertex>), init(_ arborescence: Arborescence<Vertex>)
    func lowestCommonAncestor(of:_:) -> Vertex, func distance(from:to:) -> Int
    func lowestCommonAncestor(ofIndex:_:) -> Int, func distance(fromIndex:toIndex:) -> Int
struct HeavyLightDecomposition<Vertex: Hashable>                     // Sendable when Vertex is
    init(_ tree: RootedTree<Vertex>), init(_ arborescence: Arborescence<Vertex>)
    func heavyChild(of:) -> Vertex?, func head(of:) -> Vertex
    func position(of:) -> Int, func position(ofIndex:) -> Int
    var preorder: Preorder                                           // RandomAccessCollection<Vertex>
    func subtree(of:) -> Range<Int>
    func segments(from:to:includingCommonAncestor: Bool = true) -> [Segment]
    func lowestCommonAncestor(of:_:) -> Vertex
    struct Segment: Hashable, Sendable { var positions: Range<Int>; var isReversed: Bool }
extension Tree {
    func center() -> [Vertex], func center<W>(weight: (Int) -> W) -> [Vertex]
    func centroid() -> [Vertex], func centroidDecomposition() -> RootedTree<Vertex>
    func diameter() -> Int, func diameter<W>(weight: (Int) -> W) -> W
    func diameterPath() -> Path<Vertex, Int>
    func diameterPath<W>(weight: (Int) -> W) -> (path: Path<Vertex, Int>, distance: W)
}   // W: Comparable & AdditiveArithmetic; every weight ≥ .zero and not NaN (precondition)
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Ancestor | A vertex is its own ancestor for LCA (NetworkX, CLRS); Trees' `isAncestor` stays strict | TA-006, TA-008 |
| Root dependence | LCA, the Euler tour and HLD follow the rooting; `distance`, center, centroid, diameter do not | TA-009, TA-110, TA-206, TA-328 |
| Index space | `ofIndex` arguments and results are vertex indices of the tree (`vertexIndex(of:)`, `vertices` order) | TA-124 |
| Euler tour | Root, then each child edge down and back up in `children(of:)` (edge-position) order; K₁ is the trivial walk; on an `Arborescence` through `RootedTree(arborescence)` | §C |
| Heavy child | Largest subtree, the first in `children(of:)` order on a tie; nil at a leaf | TA-305, TA-306, TA-330 |
| HLD positions | Preorder with the heavy child first, then the other children in `children(of:)` order | TA-304, TA-307, TA-328 |
| Segments | In walk order; cut where the path changes heavy path; `isReversed` exactly on multi-position segments walked upward; without the common ancestor its position (the low end of its segment) goes, and the segment when it held only that | TA-317 – TA-325 |
| Result order | `center` and `centroid` in `vertices` order, never value order | TA-412, TA-510 |
| Centroid decomposition | Root the first centroid in `vertices` order, recurse on the components; result built by the parent-function rule (input's vertices and order, edges `(parent, child)` per non-root vertex in vertex order) | TA-512 – TA-517 |
| Diameter path | The lexicographically least index pair at the diameter; trivial at `vertices[0]` when the diameter is 0 | TA-604, TA-607, TA-617, TA-618 |
| Weights | Read once per edge in position order (never on K₁); zero allowed (also `-0.0`); negative or NaN traps, `Int` and `Double` | TA-415, TA-423, TA-421, TA-422, TA-620 – TA-622 |

## How values are pinned

Every catalog row is written as the catalog writes it (listed vertices first, then endpoints by
first appearance; edges in written order) on the `ReferencePseudograph` or
`ReferenceDirectedMultigraph`, whose rows are in position order, so every vertex and edge
position is exact; parent arrays and closures go to the Trees initializers directly; the stress
shapes go through `Tree(vertices:edges:)`. Each literal is a catalog cell, computed by the
reference (`ref.py`: api.md's model in index space, a naive implementation from the definitions,
and NetworkX 3.7). Literals that are not catalog cells (heads, heavy children and positions of
every F1 vertex, extra segment lists on catalog sources, `Double` and `-0.0` repeats of `Int`
weighted rows, a few extra queries on catalog sources and on the 10⁶ shapes) were computed with
the same reference by importing `ref.py` and evaluating the extra queries. Centroid
decompositions are compared, edges included, with `RootedTree(parents:)` or
`RootedTree(vertices:parent:)` on the catalog's parent column; segments are compared through
`positions` and `isReversed` (api.md gives `Segment` no public initializer). The whole suite was
run against an independent Swift model of the API (public Trees API only) before the
implementation existed, and against planted bugs in that model. The property tests write their
oracles inside each test.

## Files

| File | Tests | Covers |
|---|---|---|
| `LowestCommonAncestorTests.swift` | 18 | §A: the one-shot query on `RootedTree` and `Arborescence`: K₁, K₂, F1 at roots 0, 4 and 8, siblings, an ancestor, the same vertex, NetworkX's `TestTreeLCA` arborescence, a parent array, the root not at index 0, String vertices |
| `LowestCommonAncestorsTests.swift` | 25 | §B: the structure from both types; `distance`, independent of the root; every ordered pair on F1, F1b, NX, kary(63, 2), P(0..140) at 70, S(0; 1..150) at a leaf and String vertices against ancestor chains, the one-shot query and HLD; index space with indices ≠ values; RMQ block boundaries on paths and stars of 63 … 193 vertices at three roots |
| `EulerTourTests.swift` | 12 | §C: K₁, K₂ both ways, F1, F1b, F1 rerooted, a path from inside, stars from the center and a leaf, the arborescence through `RootedTree`, String vertices; length, closedness, each edge twice |
| `HeavyLightDecompositionTests.swift` | 37 | §D: preorder, heavy children (ties both ways), heads, positions, subtrees of F1, F1b and F1 rerooted; segments up, down, across, the reverse walk, with and without the common ancestor (dropped from the low end, a lone-ancestor segment disappearing, the empty result), one-position segments never reversed; the star, the arborescence, kary(63, 2) at one segment per level, String vertices; every F1 pair expanded back into its path |
| `CenterTests.swift` | 23 | §E: K₁, K₂, NetworkX's trees and paths of 99 and 100, stars, balanced_tree(3, 3), center ≠ centroid, F1, two centers, `vertices` order over value order; weights moving the center, all-zero and zero-end weights (any number of centers), `Double` weights, `Double` repeats and `-0.0`, K₁ never calling the closure, the call order |
| `CentroidTests.swift` | 19 | §F: centroids of K₁, K₂, paths of 99 and 100, full_rary_tree(2, 8), the long-branch star, balanced_tree(3, 3), F1, String and reordered vertices; decompositions of K₁, K₂, paths of 7 and 8 (ties at every level), F1 (and F1b), a star, String vertices, with edges and children by the parent-function rule; heights of kary(63, 2) and P(0..127) |
| `DiameterTests.swift` | 24 | §G: diameters and paths of K₁, K₂ both ways, P(0..9), a star, F1 and F1b, String vertices, the long-branch star, balanced_tree(3, 3); weighted paths with `Int` and `Double` weights, all-zero (trivial path), zero-end (not the most edges), fractional; K₁ never calling the closure; unit weights equal unweighted; `vertices` order picks the start; the call order |
| `TreeAlgorithmStressTests.swift` | 19 | §H inside a `Task` with a one-minute limit: the 10⁶ path (diameter, path, center, centroid, LCA at depth 10⁶ − 1 both ways, distance, Euler tour, one heavy path, rooted in the middle), the 10⁶-leaf star (diameter, center, centroid, path, decomposition, a 10⁶-entry row for LCA, HLD and the tour), P(0..131070)'s decomposition height 16, weighted diameters, kary(10⁶, 2) |
| `TreeAlgorithmPropertyTests.swift` | 8 | PropertyBased, shrinking: LCA and distance on all four entry points against ancestor chains; LCA on 60 – 300-vertex trees of four shapes against parent climbing; the Euler tour against recursion; HLD against its definitions with exact segments on every pair, both modes; unweighted and weighted (`Int`, `Double`, zeros) center, diameter and diameterPath against all-pairs `Path.weight`; centroid against component sizes; the decomposition against one over vertex sets |
| `TreeAlgorithmPreconditionTests.swift` | 11 | Exit tests: non-vertices on the one-shot query (TA-019, TA-020), `LowestCommonAncestors` (TA-123) and every HLD query (TA-336); negative and NaN weights on `center`, `diameter`, `diameterPath` (TA-421, TA-422, TA-620, TA-621) with `Int` and `Double`, the bad weight last, `-infinity` and `Int.min` |
| `TreeAlgorithmConformanceTests.swift` | 9 | `Sendable` across a `Task`, value semantics, `Segment` hashing and mutation, `Preorder` as a `RandomAccessCollection`, generic code; catalog rows on `UndirectedAdjacencyList`, `AdjacencyList`, parent closures, `Tree(edges:)` and `Collider` vertices |

| `TreeAlgorithmReviewTests.swift` | 5 | Added after the review (TA-1001 – TA-1005): `Double` weights whose sums depend on order, all-zero weights, a tree rooted away from vertex 0, lowest common ancestors on 1000 – 5000 vertices, the heavy–light index forms |
210 tests in all.

## Case IDs

Case IDs (TA-001 … TA-918) refer to the catalog (`cases.md`), harvested from NetworkX
(`algorithms/tests/test_lowest_common_ancestors.py` `TestTreeLCA`,
`tree/tests/test_distance_measures.py`, the `tree.center` / `tree.centroid` docstrings), JGraphT's
LCA finders' shapes, cp-algorithms (HLD, Euler tour) and the edge cases the design calls out.
Each test's name starts with its IDs; tests without an ID check laws, representations or
properties the catalog does not list.

| Cases | Section | File |
|---|---|---|
| TA-001 – TA-018 | A. One-shot lowest common ancestor | `LowestCommonAncestorTests.swift`; TA-012 – TA-016 again on `AdjacencyList` and parent closures in `TreeAlgorithmConformanceTests.swift` |
| TA-019, TA-020 | A. Non-vertex | `TreeAlgorithmPreconditionTests.swift` |
| TA-101 – TA-122, TA-124 | B. `LowestCommonAncestors` | `LowestCommonAncestorsTests.swift`; TA-111 – TA-121 also in `TreeAlgorithmPropertyTests.swift` |
| TA-123 | B. Non-vertex | `TreeAlgorithmPreconditionTests.swift` |
| TA-201 – TA-212 | C. Euler tour | `EulerTourTests.swift`; TA-204, TA-210 again in `TreeAlgorithmConformanceTests.swift` |
| TA-301 – TA-335 | D. Heavy–light decomposition | `HeavyLightDecompositionTests.swift`; TA-304, TA-317, TA-332 again in `TreeAlgorithmConformanceTests.swift` |
| TA-336 | D. Non-vertex | `TreeAlgorithmPreconditionTests.swift` |
| TA-401 – TA-420, TA-423 | E. Center | `CenterTests.swift` |
| TA-421, TA-422 | E. Negative and NaN weights | `TreeAlgorithmPreconditionTests.swift` |
| TA-501 – TA-519 | F. Centroid and centroid decomposition | `CentroidTests.swift`; TA-513, TA-515, TA-517 again in `TreeAlgorithmConformanceTests.swift` |
| TA-601 – TA-619, TA-622 – TA-624 | G. Diameter | `DiameterTests.swift` |
| TA-620, TA-621 | G. Negative and NaN weights | `TreeAlgorithmPreconditionTests.swift` |
| TA-901 – TA-918 | H. Large inputs | `TreeAlgorithmStressTests.swift` |

## Not tested

| Case | Why |
|---|---|
| Complexity (O(1) LCA queries, O(log n) segments, O(n) measures, O(n log n) decomposition, the RMQ's memory, "no allocation" for the one-shot query) | Internal costs belong to the benchmarks; the stress tests bound them loosely (10⁶ vertices within the time limit, depth 10⁶ − 1 without recursion) |
| "Not `Equatable`" for the structures | A missing conformance is not expressible as a test |
| The negative half of `Sendable` (not `Sendable` when `Vertex` is not) | Not building is not expressible as a test; the positive half is tested |
| Index-space arguments out of range (`lowestCommonAncestor(ofIndex:_:)`, `distance(fromIndex:toIndex:)`, `position(ofIndex:)`) | api.md states no precondition for them; only vertex arguments are said to trap |
| `Preorder`'s index type | api.md gives only `RandomAccessCollection<Vertex>`; the tests index with `index(_:offsetBy:)` and offsets from `enumerated()`, not literal subscripts |
| `Segment` built by hand | api.md declares no public initializer; segments are compared through `positions` and `isReversed`, and mutated through their `var`s |
| Weights of `+infinity`, overflow of `Int` sums | `+infinity` is not below `.zero` and not NaN, so it is allowed, but api.md says nothing about infinite sums; "sums fit in `W`" is the caller's precondition and is not checked |
