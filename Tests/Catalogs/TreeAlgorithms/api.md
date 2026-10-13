# TreeAlgorithms: API

Queries over the Trees module's immutable types: lowest common ancestors (one-shot and
precomputed), the Euler tour, heavy–light decomposition, and the unrooted measures center,
centroid, centroid decomposition and diameter. `cases.md` (TA-001 – TA-918, 176 cases) pins the
values, and `ref.py` recomputes them.

## Scope

| Entry point | Purpose |
|---|---|
| `RootedTree.lowestCommonAncestor(of:_:)`, the same on `Arborescence` | One query with no preprocessing. Climbing by depth is O(depth) and allocates nothing, which suits a handful of queries |
| `LowestCommonAncestors<Vertex>` (from `RootedTree` or `Arborescence`): `lowestCommonAncestor(of:_:)` and `distance(from:to:)` | O(1) queries after O(n) preprocessing, so a batch of queries is a `map`. The unweighted distance is the main use |
| `RootedTree.eulerTour -> Walk<Vertex, Int>` | The 2n − 1-vertex tour of the Euler tour technique (Tarjan–Vishkin), with its edge positions |
| `HeavyLightDecomposition<Vertex>` (from `RootedTree` or `Arborescence`): `heavyChild(of:)`, `head(of:)`, `position(of:)`, `preorder`, `subtree(of:)`, `segments(from:to:includingCommonAncestor:)`, `lowestCommonAncestor(of:_:)` | Maps any path to O(log n) intervals of one array and any subtree to one interval, for a segment tree or Fenwick tree over path values |
| `Tree.center()`, `Tree.center(weight:)` | O(n) on a tree, against O(nm) for the general Distances version |
| `Tree.centroid()` | Jordan's centroid (1869; Knuth TAOCP 2.3.4.4) |
| `Tree.centroidDecomposition() -> RootedTree<Vertex>` | A hierarchy of depth ≤ ⌊log₂ n⌋ for divide and conquer over paths |
| `Tree.diameter()`, `Tree.diameter(weight:)`, `Tree.diameterPath()`, `Tree.diameterPath(weight:)` | The diameter and a path that attains it, in O(n) |

Related computations that are not entry points:

* Weighted distance through the LCA is `d(a) + d(b) − 2·d(lca)`, with root distances `d` summed
  over `preorder`.
* The LCA of several vertices is a `reduce` over the pairwise query.
* Entry and exit times are `preorder` positions. A subtree is an interval of `preorder`, and
  `HeavyLightDecomposition.subtree(of:)` is the interval in HLD positions.
* Center, centroid and diameter do not depend on a root, so they are on `Tree` only. `Tree(rooted)`
  is O(1). For a forest, map over `forest.trees`.

## Summary

```swift
import Trees
import Walks

extension RootedTree {   // and the same two on Arborescence
    /// The deepest vertex that is an ancestor of both (a vertex counts as its own ancestor).
    /// O(depth(a) + depth(b)), no allocation.
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
    // lowestCommonAncestor(checked:_:), distance(checkedFrom:to:) throw VertexNotFound; so does
    // lowestCommonAncestor(checked:_:) on RootedTree and Arborescence.
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
    // heavyChild, head, position, subtree, lowestCommonAncestor (checked:) and
    // segments(checkedFrom:to:includingCommonAncestor:) throw VertexNotFound.

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
They are not `Equatable`.

## Semantics

### Lowest common ancestor

* The deepest common ancestor, where a vertex counts as its own ancestor (CLRS 21-3): if `a` is
  an ancestor of `b` the answer is `a` (TA-006), and `lca(v, v) = v` (TA-008). Trees'
  `isAncestor` is strict.
* It depends on the root (TA-009 against TA-003); `distance` does not (TA-110 = TA-108).
* The one-shot method and both structures give the same answer for every pair (TA-111 – TA-121;
  `ref.py` also checks NetworkX's `tree_all_pairs_lowest_common_ancestor`).
* A non-vertex traps (TA-019, TA-020, TA-123), as every Trees query.

### Euler tour

Start at the root; at each vertex take its children in `children(of:)` order (edge-position order
of the child edges), crossing each child edge down and, after that subtree, back up: 2n − 1
vertices and 2n − 2 edge positions (each twice). K₁ gives the trivial walk `[r]`. It follows the
rooting, so it differs between F1 and F1b (TA-204, TA-205) and after rerooting (TA-206). On an
`Arborescence` the walk goes back up arcs, so it is not a directed walk. Convert with
`RootedTree(arborescence)`, which is O(1) (TA-210).

### Heavy–light decomposition

* **Heavy child**: the child with the largest subtree; on a tie, the first in `children(of:)` order
  (TA-305 against TA-306). Every other child edge is light; a root-to-vertex path has at most ⌊log₂
  n⌋ light edges.
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
  `source == target` the result is empty (TA-303). This is the form for values stored on edges,
  each at its child's position.
* Segment count ≤ 2⌊log₂ n⌋ + 1 (checked); TA-333 is the worst shape: one segment per level.

### Center

The vertices of least eccentricity, **in `vertices` order** (TA-412: `[4, 2]`, where sorting
values would give `[2, 4]`). Unweighted and with positive weights it is one vertex or two
adjacent ones; with zero weights any number (TA-415, TA-416: all four vertices of a path whose
end edges weigh 0).

### Centroid and centroid decomposition

* `centroid()`: vertices whose removal leaves components of at most ⌊n/2⌋ vertices, in `vertices`
  order (one, or two adjacent, TA-505). Edge weights do not enter. Differs from the center
  (TA-506 / TA-409, TA-508 / TA-410). On a tree it is also the set minimizing the sum of
  distances, unweighted and for every positive weighting (Goldman 1971), which `ref.py` checks.
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
  force over all pairs.
* Weighted: `(path, distance)` as `dijkstraShortestPath` returns.

### Weights

As ShortestPaths: `weight: (Int) -> W` over edge positions with `W: Comparable &
AdditiveArithmetic`, called once per edge in position order (the values go into one array first; K₁
never calls it, TA-423). **Precondition: every weight is at least `.zero` and not NaN** (TA-421,
TA-422, TA-620, TA-621). This is the same rule as ShortestPaths and Distances, where an undirected
negative edge is a negative 2-cycle. For floating-point `W` the tie rules compare the computed sums.

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

* **One-shot LCA** climbs by depth over `_layout.nodes`.
* **`LowestCommonAncestors`** is a preorder range-minimum query. For u ≠ v with
  pos(u) < pos(v), store
  `E[i] = pos(parent(preorder[i]))` for i in 1..<n; the parents of that range all lie in the
  LCA's subtree and include it, and the LCA has the least preorder position in its subtree, so
  `lca = preorder[min E(pos u, pos v]]` with no argmin and no depth comparison. This is the Euler
  tour + RMQ reduction (Berkman–Vishkin, Bender–Farach-Colton) on n − 1 entries instead of
  2n − 1. RMQ in O(n)/O(1): blocks of 64; per position a 64-bit mask of the in-block min-stack
  (the minimum of `[l, r]` inside a block is `E[l + ctz(mask[r] >> (l mod 64))]`); a sparse table
  over block minima. The structure keeps a copy of the tree's layout
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
  Unweighted is the same code with unit weights. The pass starts at the layout's own root
  (`roots[0]`), which `Tree(rooted)` keeps from the rooted tree. Then `diameterPath`: u is the
  first index with the greatest eccentricity; one walk over the rows from u gives distances; v is
  the first index farthest from u.
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
