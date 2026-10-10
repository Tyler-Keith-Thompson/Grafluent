# TreeAlgorithms: proposed API (phase 1)

Queries over the Trees module's immutable types: lowest common ancestors (one-shot and
precomputed), the Euler tour, heavy–light decomposition, and the unrooted measures center,
centroid, centroid decomposition and diameter. `cases.md` (TA-001 – TA-918, 176 cases) pins the
values, and `ref.py` recomputes them.

## Scope

**In, phase 1**

| Entry point | Why |
|---|---|
| `RootedTree.lowestCommonAncestor(of:_:)`, the same on `Arborescence` | NetworkX `lowest_common_ancestor` is one query with no preprocessing. Climbing by depth is O(depth) and allocates nothing, which beats any precomputation for a handful of queries |
| `LowestCommonAncestors<Vertex>` (from `RootedTree` or `Arborescence`): `lowestCommonAncestor(of:_:)` and `distance(from:to:)` in O(1) after O(n) preprocessing | JGraphT ships five LCA finders behind one interface (`LowestCommonAncestorAlgorithm`), and LCA is in every competitive-programming reference. O(1) queries make the batch form (NetworkX `tree_all_pairs_lowest_common_ancestor`, Tarjan offline) a `map`. The unweighted distance is the main use of LCA |
| `RootedTree.eulerTour -> Walk<Vertex, Int>` | README row. The 2n − 1-vertex tour (Tarjan–Vishkin's Euler tour technique; the input to Bender–Farach-Colton LCA; cp-algorithms). A tree's closed walk is already a Walks type, and it carries the edge positions |
| `HeavyLightDecomposition<Vertex>` (from `RootedTree` or `Arborescence`): `heavyChild(of:)`, `head(of:)`, `position(of:)`, `preorder`, `subtree(of:)`, `segments(from:to:includingCommonAncestor:)`, `lowestCommonAncestor(of:_:)` | README row. JGraphT `HeavyPathDecomposition`, cp-algorithms. It maps any path to O(log n) intervals of one array (and any subtree to one interval), which is what a segment tree or Fenwick tree over path values needs |
| `Tree.center()`, `Tree.center(weight:)` | NetworkX `tree.center` and `center(weight=)`, JGraphT `TreeMeasurer.getGraphCenter`. AHU tree isomorphism (IsomorphismModule) roots at the center. O(n) on a tree against O(nm) for the general Distances version |
| `Tree.centroid()` | README row. NetworkX `tree.centroid`; Jordan (1869), Knuth TAOCP 2.3.4.4 |
| `Tree.centroidDecomposition() -> RootedTree<Vertex>` | The centroid's main use: a hierarchy of depth ≤ ⌊log₂ n⌋ for divide and conquer over paths (Laaksonen's *Competitive Programmer's Handbook*, the USACO Guide, Della Giustina–Prezza–Venturini 2019). A rooted tree on the same vertices is the result, in an existing type |
| `Tree.diameter()`, `Tree.diameter(weight:)`, `Tree.diameterPath()`, `Tree.diameterPath(weight:)` | README row. NetworkX/igraph/JGraphT `diameter`; igraph also returns the path (`get_diameter`, `igraph_diameter`'s `vertex_path`). CLRS exercise 22.2-8. O(n) |

**Out, and where it goes**

| Not in phase 1 | Reason |
|---|---|
| Binary lifting, k-th / level ancestor (`ancestor(of:atDepth:)`) | No graph library offers a level-ancestor query (JGraphT's `BinaryLiftingLCAFinder` uses lifting only for LCA). Binary lifting costs n·⌈log₂ n⌉ words (160 MB at 10⁶) for O(log n) queries, beaten by both structures here. Phase 2 candidate: `HeavyLightDecomposition.ancestor(of:atDepth:)` in O(log n) with no extra storage (jump heads, then index `preorder`) |
| Tarjan's offline LCA (NetworkX `tree_all_pairs_lowest_common_ancestor`), Schieber–Vishkin, Farach-Colton–Bender | Algorithms, not API: the structure answers any batch in O(n + q). Of the O(n)/O(1) methods the implementation note below picks the simplest |
| LCA in a DAG (NetworkX `all_pairs_lowest_common_ancestor`, JGraphT `NaiveLCAFinder.getLCASet`) | Not unique in a DAG; it belongs with `DirectedAcyclicGraph` |
| LCA across a `Forest` (JGraphT's finders accept several roots and return `null` across trees) | A `Forest` has no public roots. Per tree: `RootedTree(forest.trees[i], root: r)`. Revisit with `Branching` (Trees phase 2) |
| Weighted distance through the LCA | `d(a) + d(b) − 2·d(lca)` with root distances `d` the caller sums in `preorder` (one line); building it in would make the structure generic over `W` for one subtraction |
| `lowestCommonAncestor(of: some Sequence<Vertex>)` | `reduce` over the pairwise query, O(k) |
| Entry and exit times (the "Euler tour" of subtree-query tutorials) | Already Trees: a subtree is an interval of `preorder` (`descendants(of:)` is that slice), and `HeavyLightDecomposition.subtree(of:)` is the interval in HLD positions |
| Eccentricity, radius, periphery, absolute (edge-point) center | `Distances` (README). Its `center` and `diameter` should use this module's tie rule (`vertices` order) so the general and tree versions agree |
| Center, centroid, diameter on `RootedTree`, `Arborescence`, `Forest` | They do not depend on a root, so they live on `Tree` alone: `Tree(rooted)` is O(1); `Arborescence → RootedTree → Tree` too. A forest: `forest.trees.map { $0.diameter() }` |
| Edge-weighted centroid, NetworkX 3.7 `centroid(G, weight=)` | That is the general-graph median (sum of distances), a `Distances` concept. On a tree it equals `centroid()` for every positive weighting (Goldman 1971, checked by `ref.py`), so a weight parameter would only matter for zero weights |
| Dynamic trees: link–cut trees, Euler tour trees (JGraphT `TreeDynamicConnectivity`) | Trees are immutable (Trees api.md) |
| Path aggregates (a segment tree over HLD positions), tree DP / rerooting framework, virtual (auxiliary) trees | The caller's data structure; HLD gives the intervals. No graph library has them |
| Tree isomorphism (AHU) | `IsomorphismModule`; it calls `center()` |

## Summary

```swift
import Trees
import Walks

extension RootedTree {   // and the same two on Arborescence
    /// The deepest vertex that is an ancestor of both or one of them (a vertex counts as its own
    /// ancestor here, as in NetworkX). O(depth(a) + depth(b)), no allocation.
    /// Precondition: both are vertices.
    public func lowestCommonAncestor(of a: Vertex, _ b: Vertex) -> Vertex

    /// The closed walk from the root that goes down each child edge, in `children(of:)` order,
    /// and back up it: 2n − 1 vertices, each edge position twice. O(n).
    public var eulerTour: Walk<Vertex, Int> { get }
}

@frozen public struct LowestCommonAncestors<Vertex: Hashable> {
    public init(_ tree: RootedTree<Vertex>)            // O(n)
    public init(_ arborescence: Arborescence<Vertex>)  // O(n)
    public func lowestCommonAncestor(of a: Vertex, _ b: Vertex) -> Vertex   // O(1)
    /// The number of edges between them. O(1).
    public func distance(from a: Vertex, to b: Vertex) -> Int
    public func lowestCommonAncestor(ofIndex a: Int, _ b: Int) -> Int
    public func distance(fromIndex a: Int, toIndex b: Int) -> Int
}

@frozen public struct HeavyLightDecomposition<Vertex: Hashable> {
    public init(_ tree: RootedTree<Vertex>)            // O(n)
    public init(_ arborescence: Arborescence<Vertex>)
    /// The child with the largest subtree, the first in `children(of:)` order on a tie; nil at a leaf.
    public func heavyChild(of vertex: Vertex) -> Vertex?
    /// The top vertex of the heavy path through `vertex`.
    public func head(of vertex: Vertex) -> Vertex
    /// The vertex's offset in `preorder`.
    public func position(of vertex: Vertex) -> Int
    public func position(ofIndex index: Int) -> Int
    /// The vertices by position: a preorder that visits each vertex's heavy child first, then
    /// its other children in `children(of:)` order. Heavy paths and subtrees are intervals.
    public var preorder: Preorder { get }              // RandomAccessCollection<Vertex>, O(1)
    /// The positions of the subtree of `vertex`: position(of:) ..< position(of:) + size.
    public func subtree(of vertex: Vertex) -> Range<Int>
    /// The path from `source` to `target` as at most 2⌊log₂ n⌋ + 1 position intervals, in walk
    /// order. Without the common ancestor (for values stored on edges, at their child end) the
    /// ancestor's position is dropped, and a segment left empty with it. O(log n).
    public func segments(from source: Vertex, to target: Vertex,
                         includingCommonAncestor: Bool = true) -> [Segment]
    public func lowestCommonAncestor(of a: Vertex, _ b: Vertex) -> Vertex   // O(log n)

    @frozen public struct Segment: Hashable, Sendable {
        public var positions: Range<Int>
        /// The path visits `positions` from the last to the first (it is going up). False for a
        /// one-position segment.
        public var isReversed: Bool
    }
}

extension Tree {
    /// The vertices of least eccentricity, in `vertices` order: one, or two adjacent ones. O(n).
    public func center() -> [Vertex]
    /// The same by weighted distance: one or two adjacent vertices for positive weights, any
    /// number with zero weights. `weight` is called once per edge, in position order.
    /// Precondition: every weight is at least `.zero` and not NaN; sums fit in `W`.
    public func center<W: Comparable & AdditiveArithmetic>(weight: (Int) -> W) -> [Vertex]

    /// The vertices whose removal leaves no component of more than n/2 vertices, in `vertices`
    /// order: one, or two adjacent ones. O(n).
    public func centroid() -> [Vertex]

    /// The rooted tree on the same vertices whose root is the centroid (the first in
    /// `vertices` order when there are two), and whose root's children are the centroids,
    /// chosen the same way, of the components left when it is removed, and so on. Height at most
    /// ⌊log₂ n⌋; children in `vertices` order (the parent-function rule). O(n log n).
    public func centroidDecomposition() -> RootedTree<Vertex>

    /// The greatest number of edges between two vertices. O(n).
    public func diameter() -> Int
    public func diameter<W: Comparable & AdditiveArithmetic>(weight: (Int) -> W) -> W
    /// A path of that length: from the first vertex in `vertices` order of greatest
    /// eccentricity to the first vertex farthest from it. O(n).
    public func diameterPath() -> Path<Vertex, Int>
    public func diameterPath<W: Comparable & AdditiveArithmetic>(
        weight: (Int) -> W) -> (path: Path<Vertex, Int>, distance: W)
}
```

`LowestCommonAncestors`, `HeavyLightDecomposition`, its `Preorder` and `Segment` are value types,
`Sendable` when `Vertex` is. They share the tree's storage (an O(1) copy) plus their own arrays.
They are not `Equatable`: they are derived from the tree, and NetworkX/JGraphT have no equality
on such results either.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `lowestCommonAncestor(of:_:)` | NetworkX `lowest_common_ancestor`, JGraphT `getLCA` (`org.jgrapht.alg.lca`), cp-algorithms, Bender–Farach-Colton | `lca` (abbreviation); `nearestCommonAncestor` (Harel–Tarjan 1984, LLVM's `findNearestCommonDominator`): the libraries say "lowest" |
| `LowestCommonAncestors` | NetworkX's module `lowest_common_ancestors`; JGraphT `LowestCommonAncestorAlgorithm`; Grafluent's plural-noun query structures (`DominanceFrontiers`, `Components`) | JGraphT's per-algorithm class names (`EulerTourRMQLCAFinder`, …): the algorithm is an implementation detail |
| `distance(from:to:)` | `ShortestPathTree.distance(to:)`, NetworkX `shortest_path_length` | |
| `eulerTour` | Tarjan–Vishkin 1985 ("Euler tour technique"), Bender–Farach-Colton 2000, cp-algorithms, JGraphT `EulerTourRMQLCAFinder` | `eulerianCircuit` is Tours' (each edge once); this crosses each edge twice |
| `HeavyLightDecomposition` | README; cp-algorithms ("heavy-light decomposition"); Sleator–Tarjan 1983 | JGraphT's `HeavyPathDecomposition`: the README already settled the cp-algorithms name |
| `heavyChild(of:)`, `head(of:)`, `position(of:)` | cp-algorithms `heavy[v]`, `head[v]`, `pos[v]`; JGraphT "heavy edges" | |
| `segments(from:to:)` | cp-algorithms ("the path … is split into O(log n) segments") | `ranges`: segments is the HLD word |
| `subtree(of:)` | everywhere | |
| `center()` | NetworkX `center`, `tree.center`; JGraphT `getGraphCenter` | |
| `centroid()` | NetworkX `tree.centroid`; Jordan, Knuth | `barycenter`: NetworkX's former name for the sum-of-distances median, which 3.7 renamed `centroid` (the same set on trees) |
| `centroidDecomposition()` | Laaksonen's Handbook, USACO Guide, Della Giustina et al. 2019 ("centroid decomposition") | `centroidTree`: the result's informal name only |
| `diameter()` | NetworkX, igraph, JGraphT `getDiameter`, CLRS | |
| `diameterPath()` | igraph's diameter path (`get_diameter` in Python, the `vertex_path`/`edge_path` outputs of `igraph_diameter`) | `diameter() -> Path`: the general `Distances.diameter()` will return a number, and an overload returning a `Path` on `Tree` would make `tree.diameter()` ambiguous by return type. `farthestPoints` (igraph `farthest_points`) returns endpoints, not the path. **The one name here that is a judgment call** |

## Semantics

### Lowest common ancestor

* The deepest common ancestor, where a vertex counts as its own ancestor (NetworkX; CLRS 21-3):
  if `a` is an ancestor of `b` the answer is `a` (TA-006), and `lca(v, v) = v` (TA-008). Trees'
  `isAncestor` stays strict; this is the definition LCA always uses.
* It depends on the root (TA-009 against TA-003); `distance` does not (TA-110 = TA-108).
* The one-shot method and both structures give the same answer for every pair (TA-111 – TA-121,
  checked against NetworkX's Tarjan offline implementation).
* A non-vertex traps (TA-019, TA-020, TA-123), as every Trees query.

### Euler tour

Start at the root; at each vertex take its children in `children(of:)` order (edge-position order
of the child edges), crossing each child edge down and, after that subtree, back up: 2n − 1
vertices and 2n − 2 edge positions (each twice). K₁ gives the trivial walk `[r]`. It follows the
rooting, so it differs between F1 and F1b (TA-204, TA-205) and after rerooting (TA-206). It is
the sequence of NetworkX's `dfs_labeled_edges` (forward then reverse) on the same adjacency
order. On an `Arborescence` the walk goes back up arcs, so it is not a directed walk: convert
with `RootedTree(arborescence)`, O(1) (TA-210).

### Heavy–light decomposition

* **Heavy child**: the child with the largest subtree; on a tie, the first in `children(of:)`
  order (TA-305 against TA-306), as cp-algorithms' `>` comparison and NetworkX `tree.centroid`'s
  `max` both do. Every other child edge is light; a root-to-vertex path has at most ⌊log₂ n⌋
  light edges.
* **Positions**: the preorder that takes the heavy child first, then the other children in
  `children(of:)` order (TA-304). A heavy path is the interval from its head, and a subtree is
  `subtree(of:)` (TA-314).
* **Segments**: walking from `source` to `target`, the path's positions are cut where it changes
  heavy path. Each `Segment` lies inside one heavy path; segments on the way up are visited in
  decreasing position order (`isReversed`), on the way down increasing. A one-position segment
  is never reversed (TA-317's `4..<5`), so the flag is canonical. Concatenated in order and
  expanded (reversed where flagged), the segments are the path's positions exactly (`ref.py`
  checks this on every case). The walk's reverse gives the same ranges with the order and flags
  reversed (TA-318).
* `includingCommonAncestor: false` drops the LCA's position: the low end of the one segment that
  holds it (TA-321 – TA-323); if that segment held only the LCA it disappears (TA-325); for
  `source == target` the result is empty (TA-303). This is the edge-value form (store the edge to
  the parent at the child's position), which kactl and most CP libraries select by a flag.
* Segment count ≤ 2⌊log₂ n⌋ + 1 (checked); TA-333 is the worst shape: one segment per level.

### Center

The vertices of least eccentricity, **in `vertices` order** (TA-412: `[4, 2]`, where sorting
values would give `[2, 4]`). Unweighted and with positive weights it is one vertex or two
adjacent ones; with zero weights any number (TA-415, TA-416: all four vertices of a path whose
end edges weigh 0). NetworkX `tree.center` returns its degree dictionary's order (node order),
`center(weight=)` the eccentricity dictionary's: both agree as sets on every case.

### Centroid and centroid decomposition

* `centroid()`: vertices whose removal leaves components of at most ⌊n/2⌋ vertices, in `vertices`
  order (one, or two adjacent, TA-505). Edge weights do not enter. Differs from the center
  (TA-506 / TA-409, TA-508 / TA-410). NetworkX `tree.centroid` lists `[root] + neighbours` from an
  arbitrary root, so its order is not canonical; NetworkX 3.7 `centroid` (the renamed
  `barycenter`) is the same set on every unweighted case, and on every positively weighted one
  (Goldman 1971), as `ref.py` checks.
* `centroidDecomposition()`: root the centroid of the whole tree (the first in `vertices` order
  when there are two, TA-512, TA-514); remove it; each remaining component's centroid, chosen the
  same way, is a child of it; repeat. Returned as a `RootedTree` on the same vertices built by the
  parent-function rule, so its edges are `(parent, child)` per non-root vertex in vertex order and
  `children(of:)` is in vertex order. Its edges are not the input tree's. Height ≤ ⌊log₂ n⌋
  (checked on every case; TA-915: 2¹⁷ − 1 vertices give exactly 16).

### Diameter

* `diameter()`: the greatest eccentricity; 0 for one vertex (TA-601).
* `diameterPath()`: the path between the lexicographically least ordered pair (u, v), by vertex
  index, at distance `diameter`: u is the first vertex of greatest eccentricity, v the first
  vertex farthest from u (TA-609; TA-604: `vertices` = [1, 0] starts at 1; TA-607: a star's
  leaves 1 and 2). When the diameter is zero (one vertex, or all weights zero) it is the trivial
  path at `vertices[0]` (TA-617). With zero weights it is not "the path with most edges" (TA-618:
  (0, 2), not (0, 3)). The rule does not depend on the algorithm, and `ref.py` checks it by brute
  force over all pairs. igraph and NetworkX document no tie rule.
* Weighted: `(path, distance)` as `dijkstraShortestPath` returns.

### Weights

As ShortestPaths: `weight: (Int) -> W` over edge positions with `W: Comparable &
AdditiveArithmetic`, called once per edge in position order (the values go into one array first;
K₁ never calls it, TA-423). **Precondition: every weight is at least `.zero` and not NaN**
(TA-421, TA-422, TA-620, TA-621). A tree's paths are unique, so a negative weight would still give
well-defined path weights; but Grafluent's ShortestPaths treats an undirected negative edge as a
negative 2-cycle (distance undefined), and `Distances` will inherit that, so the tree versions
must not answer where the general ones cannot. NetworkX raises `ValueError` ("Contradictory paths
found: negative weights?"). For floating-point `W` the tie rules compare the computed sums.

## Complexity

| Operation | Cost |
|---|---|
| `lowestCommonAncestor(of:_:)` on `RootedTree` / `Arborescence` | O(depth(a) + depth(b)), no allocation |
| `LowestCommonAncestors.init` | O(n) time; about 2n words plus (n/64)·⌈log₂(n/64)⌉ words (≈ 18 MB at 10⁶) beyond the shared tree |
| `LowestCommonAncestors` queries | O(1) (plus one hash per vertex argument; none in index space) |
| `eulerTour` | O(n), 4n − 3 elements allocated |
| `HeavyLightDecomposition.init` | O(n), 3n words |
| `heavyChild`, `head`, `position`, `subtree`, `preorder[i]` | O(1) |
| `segments`, HLD `lowestCommonAncestor` | O(log n) |
| `center`, `centroid`, `diameter`, `diameterPath` (all forms) | O(n) |
| `centroidDecomposition` | O(n log n) time, O(n) space |

## Implementation notes (index space)

Every algorithm runs over vertex numbers `0..<n` and the Trees layout: rows in position order
(`rowOffsets`, `rowNeighbors`, `rowEdges`), the per-vertex `_TreeNode` (parent, parent edge,
depth, preorder position, subtree size) and `preorder`. Nothing recurses; the 10⁶-vertex path
(TA-901 – TA-909, TA-916), the 10⁶-leaf star (TA-910 – TA-914) and the 10⁶-vertex binary heap
shape (TA-917, TA-918) are the stress shapes.

* **One-shot LCA**: needs only public API (`vertexIndex(of:)`, `depth(ofIndex:)`,
  `parent(ofIndex:)`), but reads `_layout.nodes` to skip the `Optional`s.
* **`LowestCommonAncestors`: preorder RMQ.** For u ≠ v with pos(u) < pos(v), the LCA is the
  parent of the shallowest vertex in preorder positions (pos(u), pos(v)]. Better: store
  `E[i] = pos(parent(preorder[i]))` for i in 1..<n; the parents of that range all lie in the
  LCA's subtree and include it, and the LCA has the least preorder position in its subtree, so
  `lca = preorder[min E(pos u, pos v]]` with no argmin and no depth comparison. This is the Euler
  tour + RMQ reduction (Berkman–Vishkin, Bender–Farach-Colton) on n − 1 entries instead of
  2n − 1. RMQ in O(n)/O(1): blocks of 64; per position a 64-bit mask of the in-block min-stack
  (the minimum of `[l, r]` inside a block is `E[l + ctz(mask[r] >> (l mod 64))]`); a sparse table
  over block minima. Memory: `E` and `mask` (2n words; `E` as `Int32` when n < 2³¹ saves n/2) plus
  the small table. Binary lifting would be n·⌈log₂ n⌉ words and O(log n) per query; a full
  sparse table over the Euler tour 2n·⌈log₂ 2n⌉. The structure keeps a copy of the tree's layout
  (O(1)) for `preorder`, positions, depth and vertex lookup. `distance` is
  `depth(a) + depth(b) − 2·depth(lca)`.
* **Euler tour**: no stack and no row walk. Going through `preorder`, before each next vertex w
  climb from the current vertex to parent(w), emitting each vertex and parent edge; then step
  down to w; finally climb to the root. Built straight into `Walk(_uncheckedVertices:edges:)`
  with capacities 2n − 1 and 2n − 2.
* **HLD**: heavy child from the rows and `size` (first strict maximum, rows skipping the parent
  edge, so `children(of:)` order). Positions by one explicit stack: pop v, give it the next
  position, push its light children in reverse `children(of:)` order, then its heavy child. Store
  `order`, `pos`, `head` (3n words); `heavyChild(v)` is `order[pos(v) + 1]` when that vertex has
  v's head, so it needs no array. `segments`: while heads differ, lift the side whose head is
  deeper (on equal depth either; the set of segments is the same), then one segment on the shared
  heavy path; the source side's segments in order, then the target side's reversed.
* **Eccentricities in one rerooting pass** (center, diameter, diameterPath): reverse `preorder`
  computes each vertex's best and second-best downward chain (and which child gives the best);
  forward `preorder` computes the best chain leaving each vertex's subtree; ecc = max of the two.
  Arrays of `W`: four of n. Unweighted is the same code with `{ _ in 1 }`, specialized. Use the
  layout's own root (`roots[0]`), not vertex 0: `Tree(rooted)` keeps the rooted tree's root.
  Then `diameterPath`: u = first index with the greatest eccentricity; one walk over the rows
  from u for distances (an explicit stack); v = first index farthest from u; the path through
  public `Tree.path(from:to:)`.
* **Centroid**: one pass over the nodes, `part[p] = max(part[p], size(v))` for each non-root v and
  `n − size(v)`; keep v with `2·part(v) ≤ n`. No rows, no walk.
* **Centroid decomposition**: a stack of (start vertex, parent centroid) jobs. Per job, a
  breadth-first walk over rows skipping removed vertices lists the component; sizes in reverse
  walk order; the first-index vertex with `2·max(largest child, m − size) ≤ m` is the centroid;
  mark it removed and push its non-removed neighbours. Each vertex is in O(log n) components.
  The result is built by `_TreeLayout.fromParents(vertices:slots:dense:parents:)` with the input
  tree's own vertices and numbering, so nothing is hashed, then `RootedTree(_layout:)`.
* **Weights** are read once into a `[W]` by position, checking `w >= .zero && w == w` (the
  precondition) as they are read.

### Package accessors needed from Trees

Lift visibility of existing declarations from `@usableFromInline internal` to
`@usableFromInline package` (read only; nothing new to write). Swift allows
`@usableFromInline package` declarations in `@inlinable` code of other modules in the package,
which is how Trees already calls Walks' `package init(_uncheckedVertices:edges:)`.

| Declaration | Members used | By |
|---|---|---|
| `Tree._layout`, `RootedTree._layout`, `Arborescence._layout` | read | all |
| `_TreeLayout` (the struct) | `vertices`, `rowOffsets`, `rowNeighbors`, `rowEdges`, `roots`, `nodes`, `preorder`, `count`, `number(of:)` | all |
| `_TreeLayout.slots`, `.dense`, `static fromParents(vertices:slots:dense:parents:)` | | `centroidDecomposition` |
| `_TreeNode` (the struct) | `parent`, `parentEdge`, `depth`, `preorderPosition`, `size` | all (not `parentOffset`, `component`) |
| `RootedTree.init(_layout:)` | | `centroidDecomposition` |

Also: **add `Walks` to TreeAlgorithms' dependencies** in `scripts/modules.py` (today
`["GraphProtocols", "Trees"]`) for `Path` and `Walk(_uncheckedVertices:edges:)`, which is
already `package`.

## Library comparison and disagreements

| Where | What | Catalog |
|---|---|---|
| Which libraries have these | NetworkX: LCA (directed trees and DAGs), `tree.center`, `tree.centroid`, `diameter`; JGraphT: five LCA finders, `HeavyPathDecomposition`, `TreeMeasurer` (center); igraph: diameter with path, no LCA/HLD/centroid; Boost, LEMON, petgraph, rustworkx: none of LCA, Euler tour, HLD, centroid found | |
| NetworkX `centroid` | 3.7 renamed `barycenter` (min sum of distances, the median) to `centroid`; `tree.centroid` is Jordan's size-based centroid. Equal on trees unweighted and for all positive weights (Goldman 1971); with a zero-weight edge the median widens | TA-501 – TA-510 (checked) |
| Result order | NetworkX `tree.center`: node order; `tree.centroid`: `[root] + neighbours` from an arbitrary root; `center(weight=)`: dict order. Ours: `vertices` order always | TA-412, TA-510 |
| Ancestor in LCA | NetworkX treats a vertex as its own ancestor for LCA while `nx.ancestors` is strict; Trees' `isAncestor` is strict. LCA uses the reflexive notion everywhere | TA-006 |
| LCA input | NetworkX requires a directed tree (`not_implemented_for("undirected")`); ours takes `RootedTree` and `Arborescence` | TA-003, TA-012 |
| Negative weights | NetworkX `diameter`/`center(weight=)` raise `ValueError`; on a tree they would be well defined, but ours is a precondition, matching ShortestPaths | TA-421, TA-620 |
| Heavy-child ties | cp-algorithms (`>`, first maximum in adjacency order) and NetworkX's `_heaviest_child` (`max`, first maximum) agree with ours | TA-305, TA-306, TA-330 |
| Euler tour | cp-algorithms and Bender–Farach-Colton: 2n − 1 vertices; Tarjan–Vishkin: 2n − 2 arcs; tutorials for subtree queries: entry/exit times. `Walk` carries both vertex and edge sequences; entry/exit is `preorder` | TA-201 – TA-212 |
| Diameter path | igraph returns one path, NetworkX none; neither documents which. Ours is the lexicographically least pair by vertex index | TA-606 – TA-618 |
