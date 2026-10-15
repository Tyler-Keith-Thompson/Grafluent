# CommunityDetection: API

Partitions of a graph's vertices into communities, and the measures that score them: modularity
(Newman–Girvan, with a resolution γ; Leicht–Newman for directed graphs), coverage and performance,
and five detection algorithms: Louvain, greedy modularity (Clauset–Newman–Moore), label
propagation, semi-synchronous and asynchronous, and Girvan–Newman. Every algorithm returns one value
type, `Partition`: communities as vertex slices in a canonical order, with an O(1) `community(of:)`;
Girvan–Newman returns a lazy sequence of them. Every entry point
is **deterministic**; Louvain and asynchronous label propagation also take a caller's
`RandomNumberGenerator`. `cases.md` (CD-001 – CD-191, 191 cases) pins the values. `ref.py`
recomputes every one with the model below and checks it against the matrix definition of
modularity, a pair count for performance, and NetworkX 3.7, including NetworkX's own Louvain and
asynchronous label propagation code run with the identity order and this API's tie rule
(`uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 ref.py`). `gen.py`
writes the catalog's rows; `ref.py --fill` computes Expected.

## Scope

| Entry point | On | Purpose |
|---|---|---|
| `modularity(of:resolution:)`, also `(of:weight:resolution:)` | both | The objective the algorithms optimize, and a way to compare partitions from different algorithms (or `connectedComponents()`) |
| `partitionQuality(of:)` → `PartitionQuality` (`coverage`, `performance`) | both | Two O(n + m) measures that do not depend on a null model (Fortunato 2010, §3.3.2) |
| `louvainCommunities(resolution:threshold:)`, also `(weight:…)`, each also `(…, using:)` | both | Blondel et al. 2008. Directed: the Dugué–Perez 2015 gain |
| `greedyModularityCommunities(resolution:)`, also `(weight:resolution:)` | both | Clauset–Newman–Moore 2004 |
| `labelPropagationCommunities()`, also `(weight:)` | `Graph` | Semi-synchronous (Cordasco–Gargano 2010): deterministic, and always terminates |
| `asynchronousLabelPropagationCommunities()`, also `(weight:)`, each also `(using:)` | `Graph` | Raghavan–Albert–Kumara 2007 |
| `girvanNewmanCommunities()` → `GirvanNewmanSequence` | `Graph` | Girvan–Newman 2002: the divisive hierarchy, coarsest first |
| `spectralClustering(clusterCount:tolerance:maxIterations:)`, also `(…, weight:, …)`, each also `(…, using:)` | `Graph` | Ng–Jordan–Weiss 2001: N's eigenvectors, unit rows, k-means++ (Arthur–Vassilvitskii 2007) |
| `Partition<G>` | | Communities in canonical order, `community(of:)`, `community(ofIndex:)`, `count` |

Label propagation on a directed graph: `digraph.undirectedView.labelPropagationCommunities()`.

## Summary

```swift
import GraphProtocols

extension Graph {
    /// Σ_c [L_c/m − γ (d_c / 2m)²]: L_c the weight of edges inside c, d_c the degree sum of c
    /// (a self-loop counts twice), m the total weight. 0 when m = 0.
    /// Precondition: `communities` lists every vertex exactly once (empty communities allowed);
    /// γ finite and ≥ 0.
    func modularity<C: Collection>(of communities: C, resolution: Double = 1) -> Double
        where C.Element: Collection, C.Element.Element == Vertex
    func modularity<C: Collection, W: BinaryFloatingPoint>(
        of communities: C, weight: (Edges.Index) -> W, resolution: Double = 1) -> Double
        where C.Element: Collection, C.Element.Element == Vertex

    /// Coverage (share of edges inside communities) and performance (share of vertex pairs
    /// classified correctly). NaN where the ratio is 0/0.
    func partitionQuality<C: Collection>(of communities: C) -> PartitionQuality
        where C.Element: Collection, C.Element.Element == Vertex

    /// Blondel et al.: vertices in index order, ties to the greatest community label.
    func louvainCommunities(resolution: Double = 1, threshold: Double = 1e-7) -> Partition<DirectedView<Self>>
    func louvainCommunities<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W, resolution: Double = 1, threshold: Double = 1e-7) -> Partition<DirectedView<Self>>
    /// The same, with each level's visit order shuffled by `generator`.
    func louvainCommunities(resolution: Double = 1, threshold: Double = 1e-7,
                            using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>>
    func louvainCommunities<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W, resolution: Double = 1, threshold: Double = 1e-7,
        using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>>

    /// Clauset–Newman–Moore: merge the pair of greatest ΔQ while ΔQ ≥ 0.
    func greedyModularityCommunities(resolution: Double = 1) -> Partition<DirectedView<Self>>
    func greedyModularityCommunities<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W, resolution: Double = 1) -> Partition<DirectedView<Self>>

    /// Semi-synchronous (Cordasco–Gargano).
    func labelPropagationCommunities() -> Partition<DirectedView<Self>>
    func labelPropagationCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> Partition<DirectedView<Self>>

    /// Raghavan–Albert–Kumara: vertices in index order each sweep, ties to the greatest label.
    func asynchronousLabelPropagationCommunities() -> Partition<DirectedView<Self>>
    func asynchronousLabelPropagationCommunities<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W) -> Partition<DirectedView<Self>>
    /// Each sweep's order shuffled and each tie drawn by `generator`.
    func asynchronousLabelPropagationCommunities(
        using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>>
    func asynchronousLabelPropagationCommunities<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>>

    /// Girvan–Newman: remove an edge of greatest betweenness again and again; a partition each
    /// time the number of components grows. Lazy; ties to the least edge position.
    func girvanNewmanCommunities() -> GirvanNewmanSequence<Self>   // Sequence of Partition<DirectedView<Self>>
}

extension DirectedGraph {
    /// Leicht–Newman: Σ_c [L_c/m − γ · out_c · in_c / m²].
    func modularity<C: Collection>(of communities: C, resolution: Double = 1) -> Double
        where C.Element: Collection, C.Element.Element == Vertex
    // … and the weighted overload, partitionQuality(of:) over ordered pairs,
    // louvainCommunities (four overloads, Dugué–Perez gain) and greedyModularityCommunities
    // (two overloads), returning Partition<Self>. No label propagation (Scope).
}

/// A partition of a graph's vertices into communities, in canonical order: communities by their
/// least vertex (in `vertices` order), each community's vertices in `vertices` order.
@frozen public struct Partition<G: DirectedGraph>: RandomAccessCollection, Equatable, CustomStringConvertible {
    public typealias Index = Int
    public typealias Element = ArraySlice<G.Vertex>
    /// The position of `vertex`'s community. O(1) after the graph's `vertexIndex(of:)`.
    /// Precondition: `vertex` is a vertex.
    public func community(of vertex: G.Vertex) -> Int
    /// By vertex index (position in `vertices` without vertex indices). Precondition: in range.
    public func community(ofIndex index: Int) -> Int
    /// As `community(of:)`, throwing `VertexNotFound` instead of trapping.
    public func community(checked vertex: G.Vertex) throws(VertexNotFound) -> Int
}

@frozen public struct PartitionQuality: Hashable, Sendable {
    /// Edges with both ends in one community, over all edges (parallel copies each count, a
    /// self-loop is inside). NaN without edges.
    public var coverage: Double
    /// Vertex pairs {u, v} (ordered pairs when directed) in one community and adjacent, or in
    /// different communities and not adjacent, over all pairs. NaN with fewer than 2 vertices.
    public var performance: Double
}

extension Partition: Sendable where G: Sendable, G.Vertex: Sendable {}
```

`Graph`'s results use `DirectedView<Self>` as `G` (as
`connectedComponents()` does) and hold a copy of the graph to look vertices up, so `Partition` has
`Components`' layout and documentation (copy-on-write graph copy, slices that keep their flat
indices, not returnable through an existential). `Equatable` compares the communities, as
`Components` does: canonical order makes two partitions with the same communities equal whatever
algorithm made them. `count` is `Collection`'s; `Array(partition.map(Array.init))` is the plain
form.

`Partition` and `Components` share a layout, but a component is determined by the graph and a
community by an objective, so they are separate types.

`modularity(of:)` takes any collection of vertex collections, so callers can score their own
groupings (ground truth, `connectedComponents()`) as well as a `Partition`:
`g.modularity(of: g.louvainCommunities())`.

## Semantics

Throughout, m is the total edge weight (a self-loop once), A the adjacency matrix as the rows list
it (parallel copies add; an undirected self-loop is A_vv = 2w, as `degree(of:)` counts it), k_v =
Σ_w A_vw the (weighted) degree. Unweighted means every weight 1.

### Partition order (canonical)

Communities are ordered by their least vertex number (vertex index, or position in `vertices`),
and each lists its vertices in `vertices` order; so the result is a function of the communities
alone, not of the labels an algorithm used. This is `Components`' order.

### Modularity

* **Undirected** (Newman–Girvan 2004, with Reichardt–Bornholdt's γ): Q = Σ_c [L_c/m − γ (d_c/2m)²],
  equal to (1/2m) Σ_ij (A_ij − γ k_i k_j/2m) δ(c_i, c_j). With A_vv = 2w, a self-loop is inside its
  community and counts twice in d_c (CD-023, CD-024, CD-060, CD-061). Parallel edges add: CD-058
  equals the weight-2 CD-059.
* **Directed** (Leicht–Newman 2008): Q = Σ_c [L_c/m − γ out_c in_c/m²]
  with out_c, in_c the community's out- and in-weight. A directed loop is one out- and one in-arc
  (CD-067). `graph.directedView` (two arcs per edge, two loop arcs per loop) gives the same Q as the
  undirected graph (CD-057, CD-062).
* **m = 0** (no edges, or every weight 0): **0** (CD-001, CD-010, CD-016), which keeps Louvain's
  stop rule free of NaN.
* **Preconditions:** every vertex listed exactly once and nothing else listed (CD-155 – CD-157),
  checked with a stamp array in O(n + Σ|c|); empty communities are allowed and contribute 0
  (CD-039). γ finite and ≥ 0 (CD-158, CD-159). Weights finite and ≥ 0, read once per edge in
  position order (CD-160 – CD-162).
* γ = 0 gives the coverage (CD-044); γ = 1 is the classic Q.

### Partition quality

* **coverage** = (edges with both ends in one community) / (edges): unweighted, parallel copies each
  count (CD-076), a self-loop is inside (CD-078). NaN without edges (CD-002, CD-021).
* **performance** = (pairs in one community and adjacent + pairs in different communities and not
  adjacent) / pairs, over unordered pairs {u, v}, u ≠ v (ordered pairs when directed: CD-081).
  Adjacency is "at least one edge", so parallel copies do not matter (CD-077), and self-loops are
  not pairs (CD-079). NaN with fewer than two vertices (CD-003, CD-015).
* Same partition precondition as modularity (CD-163).

### Louvain

Blondel et al. 2008, with a fixed visit order and tie rule (`ref.py` also runs NetworkX's own
code with that order and tie rule patched in, and compares every row):

1. **Level 0** is the graph with parallel edges merged (weights summed) and self-loops kept as the
   vertex's inner weight. Each vertex starts in its own community, labelled by its number.
2. **Local moving.** Sweep the vertices **in index order** (with `using:`, in an order shuffled once
   per level by `generator`). For vertex u in community C,
   remove u, then for each community D adjacent to u (and C) compute
   gain(D) = k_u,D · m − γ′ · x_D, with k_u,D the weight from u into D (loops excluded),
   γ′ = γ/2 and x_D = Σ_tot(D) · k_u undirected; γ′ = γ and x_D = k_u^out Σ_in(D) + k_u^in Σ_out(D)
   directed (Dugué–Perez 2015). u joins the D of greatest gain; **u stays when C's gain
   ties the best; among other communities a tie goes to the greatest label.** Repeat sweeps until
   one moves nothing.
3. **Stop rule**: the level's partition is kept; if its modularity exceeds the previous
   level's (initially the singletons') by more than `threshold`, aggregate (one vertex per nonempty
   community, numbered in label order, so labels keep their order; edge weights summed, inner
   weight on the loop) and run another level, keeping its partition only if some vertex moved.
4. Edgeless graphs return singletons without a sweep (CD-017); total weight 0
   moves nothing (CD-174).

* **The tie rule.** Staying on a tie, and otherwise the greatest label, depends only on vertex
  numbering, not on a representation's row order. Label propagation uses the same rule. Ties are
  common: the first move on a path or cycle is always one (CD-101, CD-102).
* **Floating point.** Gains are compared exactly. With integer (or dyadic) weights every quantity
  is exact, and the result is a function of vertex numbering only. With other weights, k_u,D is
  summed in row order and aggregated weights in edge order, so two representations with different
  row orders can break a near-tie differently; documented. The gain is computed exactly as written
  above (one multiply, one multiply-subtract per candidate, no division).
* **Parameters.** `resolution` γ: finite, ≥ 0 (CD-164); γ = 0 merges each connected component
  (CD-094), larger γ gives smaller communities (CD-092, CD-093). `threshold`: finite, ≥ 0 (CD-165,
  CD-166), default 1e-7; a large threshold stops after one level (CD-095). Weights finite, ≥ 0
  (CD-167, CD-168).
* Self-loops count in degrees and never move a vertex (CD-025, CD-099); parallel edges are weight
  (CD-098). Directed: CD-108 – CD-110.

### Greedy modularity (Clauset–Newman–Moore)

Start from singletons with ΔQ_ij = w_ij/m − γ (a_i b_j + b_i a_j) for each adjacent pair (w_ij the
summed weight between i and j in both directions, loops excluded; a = b = k/2m undirected, a =
k^out/m, b = k^in/m directed). Repeatedly take the pair of **greatest ΔQ; ties to the least pair (i,
j), merging i into j**, and update the neighbors' ΔQ with CNM's three rules (common neighbor: sum;
neighbor of one: subtract γ(a_x b_k + a_k b_x)). Stop when the greatest ΔQ is negative (merges with
ΔQ = 0 continue: CD-128). `ref.py` checks every row against NetworkX's
`greedy_modularity_communities`. Edgeless or zero-weight graphs give singletons (CD-018, CD-173).

### Label propagation

A vertex's **votes** are its row: each edge to another vertex adds its weight (1 unweighted) to
that neighbor's label; **self-loops vote for nothing** (Raghavan et al. define the rule over
N(v), v ∉ N(v)); parallel copies each vote (CD-141, CD-149), consistent with weights. A vertex with
no votes keeps its label (CD-019, CD-027). Labels start as vertex numbers. Ties: **keep the current
label if it is among the most voted, else take the greatest**.

* **Semi-synchronous** (`labelPropagationCommunities`, Cordasco–Gargano 2010): color the graph
  greedily in largest-degree-first order (ties by vertex number; `degree(of:)`, loops ignored for
  the coloring), then, while some vertex with votes does not hold a most-voted label, run a round:
  color classes in increasing color, each class's vertices updated from the current labels (a class
  is independent, so the order inside it does not matter). A vertex with a unique most-voted label
  takes it. On simple graphs `ref.py` checks it against NetworkX's `label_propagation_communities`
  (CD-133 – CD-142).
* **Asynchronous** (`asynchronousLabelPropagationCommunities`, Raghavan et al. 2007): sweep the
  vertices in index order (with `using:`, shuffled each sweep, and ties drawn uniformly by
  `generator`); a vertex whose label is not among the most voted takes the greatest of them; stop
  after a sweep with no change. A zero-weight edge casts no vote. It terminates: every change
  strictly increases the weight of edges whose ends share a label. With the deterministic order, one
  label floods a ring of cliques (CD-145) where shuffled orders usually find the cliques; use
  `using:` there.
* Weights finite and ≥ 0 (CD-171, CD-172). `Graph` only; for a directed graph use
  `digraph.undirectedView`.

### Girvan–Newman

Repeatedly remove the edge of greatest edge betweenness (`Centrality`'s
`edgeBetweennessCentrality()`: ordered-pair sums, parallel copies sharing their pairs' paths),
recomputed after every removal, and list the components each time their number grows (NetworkX's
`girvan_newman`): the first partition has one more community than the graph has components, each
later one splits one community in two, and the last is every vertex alone, n − c partitions in all.
A tie goes to the least edge position, by exact equality of the computed scores (CD-179, CD-189).
Self-loops are never removed and never matter; a graph with no other edges lists its components
once (CD-176, CD-177; NetworkX yields nothing for a graph of loops alone). Removing an edge changes
only the shortest paths inside its component, so only that component (both parts after a split) is
recomputed. The sequence is lazy, and each iterator starts from the whole graph.

### Spectral clustering (Ng–Jordan–Weiss)

`spectralClustering(clusterCount: k)`: N's k smallest eigenvectors (SpectralGraphTheory's
`normalizedLaplacianEigenpairs(smallest: k)`, with its accuracy and limits; it throws
`NoConvergence` as that does) as columns, rows scaled to unit length (a zero row stays zero),
k-means on the rows: the least inertia of 10 runs (the first on ties), each seeded by k-means++
from `generator` and refined by Lloyd's iteration until no assignment changes or 300 iterations,
ties to the lower center, a cluster left empty taking the row farthest from its center among
clusters of two or more. Exactly k communities, in canonical order. A weight of 0 is no edge;
weights are finite and at least 0. Traps when k is not in `1...vertexCount`, `tolerance ≤ 0` or
`maxIterations < 1`. Catalog rows pin the labeling of least inertia over all labelings where the k
smallest eigenvalues stand apart from the next (CD-241 – CD-246; traps CD-247, CD-248).

### The map equation (Infomap)

- `codeLength(of:)` and `codeLength(of:weight:)` on `Graph`: the two-level map equation (Rosvall and
  Bergstrom) in bits. The flow is d_v / 2W at each vertex (a loop counts twice in d_v) and w / 2W
  along each edge each way, W the total weight; q_i is the flow along a community's edges leaving
  it and p_i its vertices' flow; L(M) = f(Σ q_i) − 2 Σ f(q_i) − Σ f(p_v) + Σ f(q_i + p_i),
  f(x) = x log₂ x. 0 when W = 0. Traps as `modularity(of:)` on the grouping and on the weights.
- `infomapCommunities(trials:using:)` and `infomapCommunities(weight:trials:using:)` on `Graph`: the
  partition of least code length found in `trials` (default 10, at least 1) randomized runs of the
  core algorithm (greedy moves in shuffled order, modules merged into nodes level by level), each
  tuned while that shortens the code length (from its modules on the vertices, and on their
  submodules), the single module when shorter. Not catalogued: the result depends on the generator.

### Determinism

**Every entry point without `using:` is a deterministic function of the graph value: its vertex
numbering and its edge weights** (and, for non-integer weights, the floating-point summation order
fixed by rows and edge positions). Louvain and asynchronous label propagation additionally take
`using generator: inout some RandomNumberGenerator`.

* **What the generator drives** (so a seeded generator reproduces a result): Louvain: one
  Fisher–Yates shuffle of the level's vertices per level, i from k − 1 down to 1 swapping i with
  `Int(generator.next(upperBound: UInt64(i + 1)))`; ties keep the label rule. Asynchronous LPA: one
  such shuffle per sweep, and a tie among t labels (in order of first vote in the row) takes the
  `generator.next(upperBound: UInt64(t))`-th. The catalog's `using:` rows (CD-112 – CD-114, CD-153,
  CD-154) are graphs where every order gives the same partition (`ref.py` checks 200 orders and 25
  NetworkX seeds); tests add properties (a valid partition; Louvain's Q at least the singletons';
  the same seeded generator gives the same result).

## Complexity

n vertices, m edges, k communities, s sweeps or rounds, L Louvain levels.

| Entry point | Time | Extra memory |
|---|---|---|
| `modularity(of:)` | O(n + m + Σ\|c\|) (plus `vertexIndex(of:)` per listed vertex) | n + k |
| `partitionQuality(of:)` | O(n + m + Σ\|c\|): adjacent pairs counted once with a per-vertex stamp | n + k |
| `louvainCommunities` | O(n + m) per sweep, O(n + m) per aggregation; L = O(log n) in practice | O(n + m) |
| `greedyModularityCommunities` | O(m d log n) (CNM; d the depth of the merge tree, log n on sparse hierarchical graphs) | O(n + m) |
| `labelPropagationCommunities` | O(n + m) for the coloring, O(n + m) per round | O(n + m) |
| `asynchronousLabelPropagationCommunities` | O(n + m) per sweep | O(n) |
| `girvanNewmanCommunities` | O(m) to start; O(n_C · m_C) per removal from a component C, O(n) per partition; O(m² n) for the whole sequence | O(n + m) |
| `spectralClustering` | the eigenpairs, then 10 k-means runs of at most 300 Lloyd iterations, O(n k²) each | n k |

Sweeps and rounds are not polynomially bounded in theory for Louvain and asynchronous LPA (each
move strictly increases a bounded objective, so they terminate); in practice s is small.

## Implementation notes (index space)

* **Rows.** As Centrality: `_VertexIdentifiers` for numbering; `_runOnUndirectedRows` for `Graph`;
  `_withSuccessorIndexRows` or one copy into a private CSR for `DirectedGraph`. Directed Louvain
  needs in-weights per pair: the level-0 graph is built from the out-rows and, by counting sort, the
  in-rows (no `BidirectionalDirectedGraph` constraint). Weights are read once per edge in position
  order and checked there.
* **Level graphs as CSR, no dictionaries.** Louvain's level graph is (offsets, neighbor, weight,
  innerWeight, degree or out/in): parallel slots merged with a stamp array (`lastSeen[w] == v`
  ⇒ add to that slot). Aggregation renumbers communities by a prefix sum over "nonempty" and builds
  the next level by counting sort into a second pair of buffers; the two buffers ping-pong, so a
  run allocates O(n + m) once. Local moving keeps `neighborWeight: [Double]` indexed by community
  and a `touched: [Int]` list, reset after each vertex; Σ_tot per community in a `[Double]`.
  Only vertices whose inputs changed are evaluated again: when u moves from A to B, the members of
  A and B and their neighbors are marked.
* **Greedy modularity.** Per community, ΔQ to its neighbors in a sorted row (two rows merged
  linearly, CNM's balanced-tree update in array form), and a binary max-heap of merges ordered by
  (ΔQ, least pair). Entries go stale when their pair's ΔQ changes and are checked against the rows
  when popped; the heap is rebuilt from the rows when stale entries outnumber live ones, so memory
  stays O(m).
* **Label propagation.** Votes accumulate into `[Double]` indexed by label with a touched list;
  the coloring is a sort by degree and a first-fit with a stamp array.
* **`Partition`** is built from a label per vertex number by the counting sort `Components` uses.
  Canonical relabeling: labels by first appearance in vertex order.
* **No recursion and no allocation per sweep or per vertex.** `using:` overloads take the generator
  `inout` and call the same internal loop with an order buffer.
