# SpanningTrees, phase 1: proposed API

Phase 1 covers minimum and maximum spanning forests of undirected graphs (`Graph`), computed by
Kruskal, Prim and Borůvka. Chu–Liu/Edmonds arborescences and Steiner trees come later; the last
section says what they need.

## 1. Survey: what the established libraries do

| Library | Entry points | Result | Disconnected input | Prim's root | Ties | NaN | Directed input |
|---|---|---|---|---|---|---|---|
| NetworkX 3.7 | `minimum_spanning_edges(G, algorithm='kruskal'\|'prim'\|'boruvka', weight, keys, data, ignore_nan)`, `maximum_spanning_edges`, `minimum_spanning_tree` / `maximum_spanning_tree` (same arguments; return a graph with every node), `partition_spanning_tree`, `SpanningTreeIterator(G, minimum=True)`, `number_of_spanning_trees`, `random_spanning_tree` | a generator of edges in the order they were added, or a graph | a forest ("a spanning forest is found") | none: Prim restarts at an arbitrary unvisited node until all are spanned | Kruskal: a stable `sorted` over `G.edges` order. Prim: heap with an insertion counter. Borůvka: "edges must have distinct weights, otherwise the edges may not form a tree" (the union-find check means it still returns a forest) | `ValueError` by default; `ignore_nan=True` drops the edge | `NetworkXNotImplemented` (`@not_implemented_for("directed")`). Borůvka also refuses multigraphs |
| Boost | `kruskal_minimum_spanning_tree(g, OutputIterator)`; `prim_minimum_spanning_tree(g, PredecessorMap [, root_vertex(r), weight_map, distance_map, ...])` | Kruskal writes edge descriptors to an output iterator, in the order it adds them. Prim fills a predecessor map, with `p[u] = u` for the root and for every vertex not reachable from it | Kruskal: a forest. Prim: only the root's component | Prim's root is required, defaulting to `*vertices(g).first` | Kruskal pops a `std::priority_queue` (no order among equal weights). Prim is Dijkstra with `combine = project2nd` | unspecified | documented for undirected graphs only |
| JGraphT | `SpanningTreeAlgorithm<E>.getSpanningTree()`, with `KruskalMinimumSpanningTree`, `PrimMinimumSpanningTree`, `BoruvkaMinimumSpanningTree` | `SpanningTree<E>`: `getEdges(): Set<E>` and `getWeight(): double`, and it is `Iterable<E>` | a forest; Prim keeps every vertex in its heap, so it spans every component | none | Kruskal uses a stable `List.sort`. Borůvka breaks ties by the edge's position in `edgeSet()`, a total order that Borůvka needs to be correct, and compares weights with a 1e-9 tolerance | — | — |
| petgraph | `min_spanning_tree(g)` (Kruskal), `min_spanning_tree_prim(g)` | an iterator of `Element::Node` for every node, followed by `Element::Edge` for each tree edge, to be passed to `from_elements` | Kruskal gives a forest. Prim gives "only edges for an arbitrary minimum spanning tree for a single component" | Prim starts at the first node | `BinaryHeap<MinScored>`, so no order | `MinScored` orders NaN without panicking | "the input graph is treated as if undirected" |
| LEMON | `kruskal(g, cost, tree_map \| output_iterator)` (LEMON 1.x has no Prim) | the total cost as the return value, plus a `bool` edge map or the tree edges written to an iterator | a forest | — | `std::sort` | — | on a `Digraph` it runs on the arcs as if undirected |
| igraph | `igraph_minimum_spanning_tree(g, edges, weights, IGRAPH_MST_AUTOMATIC\|UNWEIGHTED\|PRIM\|KRUSKAL)` | a vector of edge IDs | a forest of n − c edges | none | — | an error ("Weights must not contain NaN values") | "Directed graphs are treated as undirected" |
| scipy | `csgraph.minimum_spanning_tree(csgraph, overwrite=False)` (Kruskal) | a sparse matrix holding the tree edges | a forest | — | — | — | the matrix is read as undirected (ST-45). A zero entry means "no edge", so a zero weight cannot be expressed |

The libraries disagree in a few places (ref.py checks each one):

- **Infinite weights.** NetworkX's Borůvka starts its running minimum at `inf` and replaces it
  only on `wt < minwt`, so it never takes a `+inf` edge (or a `−inf` edge, for the maximum). On a
  bridge of weight `+inf` it returns a forest with one edge too few, while its own Kruskal and Prim
  return the tree (ST-52, ST-88). JGraphT's Prim and Boost's Prim behave the same way: they
  initialize distances to `Double.MAX_VALUE` / `numeric_limits<W>::max()` and relax only on a
  strict `<`, so an edge weighing that much is never taken. scipy keeps an `inf` entry as an edge.
- **Self-loops.** NetworkX's Kruskal reads the weight of every edge, self-loops included, so a NaN
  self-loop raises `ValueError`. Its Prim and Borůvka never read a self-loop, so they do not
  raise (ST-57).
- **Negative weights in Boost's Prim.** Boost runs Dijkstra with `combine = project2nd`.
  Dijkstra's negative-edge test is `compare(combine(zero, w), zero)`, which is `w < 0`. Read
  literally, Boost's Prim therefore throws `negative_edge` on any negative weight. The comment
  next to the test and trac #9012 discuss how this test interacts with projections. Kruskal
  accepts negative weights in every library.
- **Directed input.** NetworkX refuses a directed graph. petgraph, igraph, LEMON and scipy quietly
  treat it as undirected.
- **Prim on a disconnected graph.** NetworkX, JGraphT and igraph return a forest, Boost covers
  the root's component, and petgraph covers the first node's component.

## 2. Proposed public API

```swift
import GraphProtocols

/// A spanning forest of an undirected graph: for each connected component, a tree joining all of
/// its vertices. A connected graph gets a spanning tree. Holds the forest's edges, as positions in
/// the graph's `edges`, and their total weight (JGraphT's `SpanningTree`, NetworkX's
/// "minimum spanning forest").
///
/// A forest of a graph with `n` vertices and `c` connected components has `n − c` edges. It never
/// contains a self-loop. Of a set of parallel edges it contains at most one.
///
/// The forest does not hold a copy of the graph. Its positions are valid for as long as the
/// graph's positions are, that is, until the graph is mutated.
@frozen
public struct SpanningForest<G: Graph, Weight: Comparable & AdditiveArithmetic> {
    /// The forest's edges, as positions in the graph's `edges`, in the order the algorithm added
    /// them (each algorithm documents its order).
    public let edges: [G.Edges.Index]

    /// The sum of the forest's edge weights, added up in `edges` order. Zero when there are no
    /// edges.
    public let weight: Weight
}
// Equatable (synthesized). Hashable when Weight is. Sendable when G.Edges.Index and Weight are.

extension Graph {
    /// A minimum spanning forest: one minimum spanning tree per connected component (NetworkX's
    /// `minimum_spanning_tree`, igraph's `minimum_spanning_tree`).
    ///
    /// The result is the canonical forest (see "Ties"), so it does not depend on which algorithm
    /// runs. Edges are listed in nondecreasing weight; among equal weights, in position order.
    /// Currently this is Kruskal.
    ///
    /// `weight` is called once for each edge that is not a self-loop, and never for a self-loop.
    ///
    /// - Complexity: O(m log m) comparisons, plus O(m α(n)) for the union–find.
    /// - Precondition: no weight is NaN (`w == w` for every weight read), and the sum of the chosen
    ///   weights does not overflow and is not NaN.
    public func minimumSpanningTree<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W>

    /// A spanning forest of an unweighted graph, every edge weighing 1 (NetworkX's default
    /// weight, igraph's unweighted method). This is the first forest in position order: an edge is
    /// taken exactly when it joins two components of the edges taken before it. `weight` is the
    /// number of edges. O(m α(n)), with no sort.
    public func minimumSpanningTree() -> SpanningForest<Self, Int>

    /// A maximum spanning forest (NetworkX's `maximum_spanning_tree`). Computed by comparing in
    /// reverse, never by negating, so unsigned weights work. Ties keep position order, as for the
    /// minimum: among equal weights the earlier position wins. Edges are listed in nonincreasing
    /// weight.
    public func maximumSpanningTree<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W>

    /// Kruskal's algorithm (Boost's `kruskal_minimum_spanning_tree`, JGraphT's
    /// `KruskalMinimumSpanningTree`): sort the edges by (weight, position), then take each edge
    /// that joins two components. Returns the canonical forest, with edges in the order they were
    /// added: nondecreasing (weight, position). Stops once `n − 1` edges have been taken.
    public func kruskalMinimumSpanningTree<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W>

    /// Prim's algorithm over every component (NetworkX, JGraphT, igraph): grow a tree from the
    /// first unspanned vertex in `vertices` order, and repeat until every vertex is spanned. A
    /// minimum spanning forest. Among equal weights, which edges are chosen is unspecified (see
    /// "Ties"). Edges are listed in the order their far vertices joined, so each one connects a
    /// vertex already spanned to a new one.
    ///
    /// - Complexity: O(m log n), with a 4-ary indexed heap.
    public func primMinimumSpanningTree<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W>

    /// Prim's algorithm from `root` (Boost's `prim_minimum_spanning_tree` with `root_vertex`): a
    /// minimum spanning tree of `root`'s connected component only. Vertices not reachable from
    /// `root` stay out of it, as in Boost's `p[u] = u`. `weight` is called only for edges in that
    /// component.
    ///
    /// - Precondition: `contains(root)`.
    public func primMinimumSpanningTree<W: Comparable & AdditiveArithmetic>(
        from root: Vertex, weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W>

    /// Borůvka's algorithm (JGraphT's `BoruvkaMinimumSpanningTree`, NetworkX's `'boruvka'`): in
    /// each round, every component takes its lightest outgoing edge under the strict order
    /// (weight, position). With that order the round cannot close a cycle, so the result is the
    /// canonical forest, the same edge set as Kruskal's. Edges are listed by round, in an
    /// unspecified order within a round.
    ///
    /// - Complexity: O(m log n) over at most ⌈log₂ n⌉ rounds. Each round is a flat scan over an
    ///   edge array, from which edges inside a component are dropped as the rounds go.
    public func boruvkaMinimumSpanningTree<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W
    ) -> SpanningForest<Self, W>
}
```

There is nothing on `DirectedGraph`. To run these on a bidirectional directed graph, call
`digraph.undirected.minimumSpanningTree(weight:)`. Each arc becomes an edge, so `u → v` and
`v → u` are parallel edges and the lighter one wins.

### Names, and who uses them

| Name | Source | Rejected alternatives |
|---|---|---|
| `minimumSpanningTree(weight:)` | NetworkX `minimum_spanning_tree`, igraph `minimum_spanning_tree`, scipy `minimum_spanning_tree`, petgraph `min_spanning_tree`. All of them return a forest on disconnected input under this name | `minimumSpanningForest`: no library names its entry point that way |
| `maximumSpanningTree(weight:)` | NetworkX `maximum_spanning_tree` | petgraph and igraph have no maximum and tell users to negate the weights, which unsigned `W` cannot do |
| `kruskalMinimumSpanningTree`, `primMinimumSpanningTree` | Boost `kruskal_minimum_spanning_tree`, `prim_minimum_spanning_tree`; JGraphT `KruskalMinimumSpanningTree`, `PrimMinimumSpanningTree`. Same shape as ShortestPaths' `dijkstraShortestPaths` | an `algorithm:` enum (NetworkX's string). Separate methods give each algorithm its own documentation (tie rule, edge order) and its own complexity |
| `boruvkaMinimumSpanningTree` | JGraphT `BoruvkaMinimumSpanningTree`; NetworkX `'boruvka'` (it accepts both `boruvka` and `borůvka`) | the diacritic in a Swift identifier |
| `SpanningForest` | NetworkX's docs ("a spanning forest is found"), LEMON's docs ("minimum cost spanning forest"), and the README's planned `SpanningForest`. Principle 4: a type called `SpanningTree` would be lying whenever the graph is disconnected | `SpanningTree` (JGraphT's interface, which is in fact a forest). Keep that name for a future type that really is one tree |
| `edges`, `weight` | JGraphT `getEdges()`, `getWeight()`; LEMON returns the total cost as the "weight" of the tree | `totalWeight` and `cost` (both invented here). The type's `weight` is a value and the methods' `weight:` is a closure, so they do not clash in use |
| `from root:` | ShortestPaths' `from:`; Boost's `root_vertex` | `root:` |

### Decisions

| Question | Decision | Why |
|---|---|---|
| Result | `SpanningForest`: an array of edge positions plus the total weight, without a copy of the graph | Edge positions are the only identity that tells parallel edges apart (Boost and igraph return edge IDs, JGraphT edge objects). Without a graph copy there is no copy-on-write trap when the graph is mutated (compare ShortestPathTree's warning). Callers build a subgraph from the positions when they need one, as with NetworkX's `T` |
| Disconnected graphs | Always a forest: n − c edges | NetworkX, JGraphT, igraph, scipy, LEMON and petgraph's Kruskal all do this. petgraph's single-component Prim is the outlier |
| Prim's root | The forest by default (restarting in `vertices` order). `from:` gives the root's component only | The default matches NetworkX, JGraphT and igraph, and keeps one meaning for "minimum spanning tree" across all four entry points. `from:` is Boost's only form, and the cheap way to get one component's tree (ST-47) |
| Ties | **Canonical rule:** edges are ordered by (weight, position in `edges`). Under that strict total order the minimum spanning forest is unique. Kruskal (with a stable sort) and Borůvka (which needs a total order to be correct, as JGraphT's code notes) return exactly that forest at no extra cost, and so does `minimumSpanningTree`. **Prim:** unspecified among equal weights | The library's rule is to document a tie order only when it is free. Kruskal: Swift's `sort` is stable, and when the gathering order is not position order the secondary key is compared only on ties. Borůvka: it needs a tie-break anyway. Prim: making it canonical means a `(W, Int)` priority, 16 bytes instead of 8 in the heap. Benchmark ST-B03 measures that; adopt it only if it costs ≤ 2 % |
| What "position" means | The order of `edges`. With dense edge indices, `edgeIndex(of:)`. **Proposed new `Graph` law:** "with edge indices, `edges` is in index order", mirroring the vertex law (L27) | Kruskal and Borůvka gather edges from the rows in index space (`neighborIndices` next to `incidentEdgeIndices`, keeping each edge at its lower-index end), which hashes nothing. The law makes `edgeIndex` the position rank, so the rule holds without a second pass. Every current conformer already satisfies it: `edgeIndex(of: p) == p` |
| Self-loops | Never in the forest, and never weighed | A self-loop can never join two components. Not reading it also means a NaN self-loop does not trap (ST-57), unlike NetworkX's Kruskal |
| Parallel edges | The lightest copy wins; among equal copies, the first position (ST-28, ST-30) | Follows from the tie rule. NetworkX's Borůvka refuses multigraphs |
| Negative and zero weights | Ordinary weights | Every MST algorithm uses only comparisons. Boost's Prim is the only exception in the survey |
| NaN | Trap on every weight read (`precondition(w == w)`), so every non-loop edge is checked. No `ignore_nan` | ShortestPaths' rule. NetworkX raises by default and igraph errors. To drop NaN edges, filter them out with `spanningSubgraph(edges:)` once that view exists |
| ±∞ | Ordinary weights: a `+∞` bridge is in the tree (ST-52). If the forest contains both `+∞` and `−∞`, the total is NaN and traps (ST-55) | No sentinel is ever compared, so nothing is dropped, unlike NetworkX's Borůvka and JGraphT's and Boost's Prim. A NaN sum traps, as in ShortestPaths' Bellman–Ford |
| Total weight | Added up in `edges` order. Swift's checked arithmetic traps on overflow (ST-60). `Int.max` is exact (ST-59). Kruskal and Prim may add Doubles in different orders, so their Double totals can differ in the last ulp: tests compare edge sets, or use exact weights | `W: AdditiveArithmetic` provides `+` and `.zero`, which is all a sum needs |
| Unweighted | `minimumSpanningTree()`: union–find in position order, `Weight == Int` (the edge count) | NetworkX's default weight is 1. igraph has an unweighted method. Free under the tie rule |
| Maximum | A reversed comparison, never negation, so `UInt8` works (ST-61). Ties keep position order | NetworkX sorts with `reverse=True`, which is stable. igraph and LEMON tell users to negate |
| Directed graphs | Not offered. Use `.undirected` | NetworkX refuses directed input, and treating it as undirected silently is how petgraph, igraph and scipy surprise their users. ShortestPaths goes the other way (undirected through `directed`), and this mirrors it |
| Vertex indices | With `vertexIndexBound`, every array is indexed by vertex. Without it, vertices are numbered once through a dictionary (`_numberedVertices`, as in ShortestPaths) | ShortestPaths' and Connectivity's precedent. The goal is no hashing on an indexed graph (ST-128) |
| Edge indices | Not required. With `edgeIndexBound`, edges are gathered from the rows with no hashing. Without it, edges are walked in `edges` order and each endpoint is looked up once | Either way the edge list is a flat array of `(weight, rank, u, v)` |
| Sendable / Equatable | Equatable is synthesized: two results are equal when their edge arrays and weights match. Sendable is conditional | Since the default is canonical, equality is meaningful there. For Prim it compares outputs, not correctness |
| Weight calls | Exactly once per non-loop edge, for every algorithm. Prim skips an edge whose far end is already spanned *before* weighing it, so it reads each edge once, from the end spanned first. `from:` reads only the root's component | Predictable cost with an expensive closure, and testable (ST-63) |

### Performance plan and the default

- **Kruskal**: gather the edges into a `ContiguousArray` of `(w, rank, u, v)`, sort it stably by
  `w`, then run `DisjointSet(count: n)` with `union` until `n − 1` edges are taken. That early
  exit is NetworkX's `edges_needed`; Boost lacks it. Cost: O(m log m), cache-friendly, and the
  sort dominates. An alternative is a lazy heap, as Boost and petgraph do. It wins only when the
  caller stops early, so it is left for a later lazy `Sequence` API (single-linkage clustering
  reads Kruskal's edges in order).
- **Prim**: `IndexedPriorityQueue<W>(indexBound: n)` with `insertOrDecreasePriority`, a
  `parentEdge` array and a `spanned` bitmap. O(m log n). It wins on dense graphs (K₁₅₀₀, ST-113)
  because it never sorts m edges. `IndexedPriorityQueue.insert` already traps on NaN.
- **Borůvka**: a flat edge array. Each round, for each component, keep the best `(w, rank)` edge
  in an array indexed by representative, merge, then compact away the edges inside a component.
  At most ⌈log₂ n⌉ rounds. It parallelizes well, which matters for a later parallel variant.
- **Default `minimumSpanningTree` = Kruskal.** NetworkX, igraph (whose `AUTOMATIC` picks Kruskal
  "see benchmarks"), scipy and petgraph all default to it. It is canonical and fastest on sparse
  graphs. The documented result is the canonical forest in nondecreasing order, so the default
  can later switch to Borůvka (by sorting its n − 1 edges) without changing any answer, but not
  to Prim unless Prim becomes canonical.
- Benchmarks (not tests): ST-B01 Kruskal against Prim against Borůvka on a grid, a G(n, p) graph
  and K₁₅₀₀. ST-B02 gathering from rows against walking `edges`. ST-B03 Prim with a `(W, Int)`
  priority against plain `W`. ST-B04 the early exit at n − 1.

## 3. Later phases: what each needs

| Feature | Library precedent | Needs |
|---|---|---|
| Chu–Liu/Edmonds minimum arborescence and branching | NetworkX `minimum_spanning_arborescence`, `maximum_branching`, `Edmonds`; LEMON `MinCostArborescence`; JGraphT has no direct counterpart | `DirectedGraph` with arc weights `(Edges.Index) -> W` and an optional root. The result is an `Arborescence` from the Trees module (`parent(of:)`, `parentEdge(of:)`, the root) plus the weight. For O(m log n) (Tarjan / Gabow–Galil–Spencer–Tarjan), a mergeable heap (skew or leftist, with lazy add) and a `DisjointSet` for contraction. The naive version is O(nm). With no root, a super-root. Return `nil` when no spanning arborescence exists |
| Steiner tree (2-approximation) | NetworkX `steiner_tree(G, terminal_nodes, weight, method='mehlhorn'\|'kou')` | ShortestPaths' Dijkstra from several sources (Mehlhorn uses one Voronoi pass), this module's Kruskal on the metric closure, then pruning non-terminal leaves. The result is a `SpanningForest`-like set of edge positions plus the weight, approximation ratio 2(1 − 1/ℓ) |
| `number_of_spanning_trees` | NetworkX (Kirchhoff, with weights it is the sum of weight products) | SpectralGraphTheory: a Laplacian determinant |
| `SpanningTreeIterator` / `partition_spanning_tree` | NetworkX (Sörensen–Janssens) | Kruskal with forced-in and forced-out edges (NetworkX's `EdgePartition` INCLUDED/EXCLUDED). Expose it as an internal Kruskal over a partition first |
| `random_spanning_tree` | NetworkX, Boost `random_spanning_tree` (Wilson), igraph (loop-erased random walk) | RandomGraphs' generator plus Wilson's algorithm |
| A lazy Kruskal `Sequence` | NetworkX's `minimum_spanning_edges` generator, petgraph's iterator | Stops early, for single-linkage clustering at k clusters |
