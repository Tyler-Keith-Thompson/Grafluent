# CommunityDetection: proposed API (phase 1)

Partitions of a graph's vertices into communities, and the measures that score them: modularity
(Newman–Girvan, with a resolution γ; Leicht–Newman for directed graphs), coverage and performance,
and four detection algorithms: Louvain, greedy modularity (Clauset–Newman–Moore), and label
propagation, semi-synchronous and asynchronous. Every algorithm returns one value type, `Partition`:
communities as vertex slices in a canonical order, with an O(1) `community(of:)`. Every entry point
is **deterministic**; the two algorithms that other libraries randomize (Louvain, asynchronous label
propagation) also take a caller's `RandomNumberGenerator`. `cases.md` (CD-001 – CD-174, 174 cases)
pins the values. `ref.py` recomputes every one with the model below and checks it against the
matrix definition of modularity, a pair count for performance, and NetworkX 3.7, including
NetworkX's own Louvain and asynchronous label propagation code run with the identity order and
this API's tie rule (`uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3
ref.py`, a few seconds). `probe.py` holds the python-igraph 1.0 values quoted below (`uv run
--no-project --with networkx==3.7 --with igraph python3 probe.py`). `gen.py` wrote the catalog's
rows; `ref.py --fill` computed Expected.

## Scope

**In, phase 1**

| Entry point | On | Why |
|---|---|---|
| `modularity(of:resolution:)`, also `(of:weight:resolution:)` | both | The README row. NetworkX `modularity(G, communities, weight, resolution)`, igraph `modularity(membership, weights, resolution, directed)`, JGraphT `UndirectedModularityMeasurer`. The objective every other entry point here optimizes, and the way a caller compares partitions from different algorithms (or `connectedComponents()`, which is a collection of vertex collections too) |
| `partitionQuality(of:)` → `PartitionQuality` (`coverage`, `performance`) | both | NetworkX `partition_quality` (Fortunato 2010, §3.3.2). Two O(n + m) measures that do not depend on a null model; the task list asks for them, and they are cheap once the partition is numbered |
| `louvainCommunities(resolution:threshold:)`, also `(weight:…)`, each also `(…, using:)` | both | The README row. Blondel et al. 2008; NetworkX `louvain_communities`, igraph `community_multilevel`; the de facto default community algorithm. Directed: NetworkX's gain (Dugué–Perez 2015) |
| `greedyModularityCommunities(resolution:)`, also `(weight:resolution:)` | both | Clauset–Newman–Moore 2004; NetworkX `greedy_modularity_communities`, igraph `community_fastgreedy`. Deterministic in every library, so it is the reference partition to compare others with, and the agglomeration is the same index-space machinery as Louvain's aggregation |
| `labelPropagationCommunities()`, also `(weight:)` | `Graph` | The README row. Semi-synchronous (Cordasco–Gargano 2010) as NetworkX `label_propagation_communities`, which is already deterministic and always terminates (fully synchronous updates oscillate on bipartite graphs) |
| `asynchronousLabelPropagationCommunities()`, also `(weight:)`, each also `(using:)` | `Graph` | Raghavan–Albert–Kumara 2007, the original LPA: NetworkX `asyn_lpa_communities`, igraph `community_label_propagation` |
| `Partition<G>` | | The README's result type: communities in canonical order, `community(of:)`, `community(ofIndex:)`, `count` |

**Out, and where it goes**

| Not in phase 1 | Reason |
|---|---|
| Girvan–Newman (NetworkX `girvan_newman`, igraph `community_edge_betweenness`) and NetworkX `edge_betweenness_partition` | **Edge betweenness belongs in Centrality**, as Centrality's api.md already decided ("Phase 2, with Girvan–Newman"): it is a centrality measure every library files there (NetworkX `edge_betweenness_centrality`, igraph `edge_betweenness`, JGraphT `EdgeBetweennessCentrality`, Boost's `edge_centrality_map` output of `brandes_betweenness_centrality`), its per-edge result type should be designed once with the other edge measures, and Centrality's Brandes engine already computes each slot's dependency. Girvan–Newman then lives here and consumes the `package` engine, recomputing after each removal (O(m²n)). Two decisions block it in phase 1: its result is a hierarchy (NetworkX yields a tuple of communities per level; igraph returns a `VertexDendrogram`), which wants a `Dendrogram` type shared with greedy modularity's merge history and Louvain's levels; and its tie rule ("remove the edge of greatest betweenness") is floating-point sensitive, since mathematically equal betweenness values often differ in the last bit (Centrality's CE-114), so it needs an exact or tolerance-based tie policy. **Phase 2, with edge betweenness** |
| Leiden (Traag–Waltman–van Eck 2019; NetworkX 3.7 `leiden_communities`, igraph `community_leiden`) | Its refinement step is randomized by design: a vertex joins a sub-community with probability ∝ exp(ΔQ/θ), and that randomness is what gives Leiden its guarantee (γ-connected communities); a deterministic order would be a different algorithm. It needs `using:` only, and Louvain's level machinery plus a refinement pass. igraph's default objective is CPM, NetworkX's modularity; the choice of default needs its own catalog. **Phase 2** |
| Louvain's levels (NetworkX `louvain_partitions`, `max_level`; igraph `return_levels`) | A lazy `Sequence` of partitions, or the `Dendrogram` above; decide with Girvan–Newman. Phase 2 |
| Greedy modularity `cutoff`, `best_n` (NetworkX) | NetworkX-only; `best_n` continues merging past the optimum and, when the heap empties, merges the two largest communities by symmetric difference: a dendrogram cut is the clean form. Phase 2, with `Dendrogram` |
| Directed label propagation | Libraries disagree on what a directed vote is: NetworkX `asyn_lpa_communities` counts successors only, `fast_label_propagation_communities` both directions, igraph `mode="out"` lets labels flow along arcs; `label_propagation_communities` refuses directed graphs. `graph.undirected.labelPropagationCommunities()` covers the common need. Revisit if asked |
| Fast label propagation (Traag–Šubelj 2023, NetworkX `fast_label_propagation_communities`) | Randomized queue-based variant; add with `using:` in phase 2 |
| Fluid communities, k-clique percolation, Kernighan–Lin bisection, Lukes, Infomap, Walktrap, spinglass, leading eigenvector | NetworkX-only or igraph-only, or spectral (`SpectralGraphTheory`). k-clique communities would build on Cliques |
| Modularity matrix (NetworkX `modularity_matrix`, igraph `modularity_matrix`) | Linear algebra: `SpectralGraphTheory` |
| A seeded generator type in the library | `using:` takes any `RandomNumberGenerator`; whether Grafluent ships one (SplitMix64, Xoshiro) is a RandomGraphs decision (open question 1). Tests define their own in-file |

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
    /// The same, with each level's visit order shuffled by `generator` (NetworkX's `seed`).
    func louvainCommunities(resolution: Double = 1, threshold: Double = 1e-7,
                            using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>>
    func louvainCommunities<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W, resolution: Double = 1, threshold: Double = 1e-7,
        using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>>

    /// Clauset–Newman–Moore: merge the pair of greatest ΔQ while ΔQ ≥ 0.
    func greedyModularityCommunities(resolution: Double = 1) -> Partition<DirectedView<Self>>
    func greedyModularityCommunities<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W, resolution: Double = 1) -> Partition<DirectedView<Self>>

    /// Semi-synchronous (Cordasco–Gargano), NetworkX's deterministic rules.
    func labelPropagationCommunities() -> Partition<DirectedView<Self>>
    func labelPropagationCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> Partition<DirectedView<Self>>

    /// Raghavan–Albert–Kumara: vertices in index order each sweep, ties to the greatest label.
    func asynchronousLabelPropagationCommunities() -> Partition<DirectedView<Self>>
    func asynchronousLabelPropagationCommunities<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W) -> Partition<DirectedView<Self>>
    /// Each sweep's order shuffled and each tie drawn by `generator` (NetworkX's `seed`).
    func asynchronousLabelPropagationCommunities(
        using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>>
    func asynchronousLabelPropagationCommunities<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>>
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

As in Connectivity and Centrality, `Graph`'s results use `DirectedView<Self>` as `G` (as
`connectedComponents()` does) and hold a copy of the graph to look vertices up, so `Partition` has
`Components`' layout and documentation (copy-on-write graph copy, slices that keep their flat
indices, not returnable through an existential). `Equatable` compares the communities, as
`Components` does: canonical order makes two partitions with the same communities equal whatever
algorithm made them. `count` is `Collection`'s; `Array(partition.map(Array.init))` is the plain
form.

**Why `Partition` and not `Components`.** The README names `Partition` as this module's result, and
the two mean different things: a component is determined by the graph, a community by an objective.
The layout is the same, so the grouping code (`Components.init(vertices:labels:count:)`) moves to
GraphProtocols as `package` and both types call it. No typealias between them (naming policy).

**Why `modularity(of:)` takes any collection of vertex collections, not a `Partition`.** Callers
score their own groupings (ground truth, `connectedComponents()`, another library's output), and
NetworkX and igraph both take plain lists. A `Partition` is such a collection, so
`g.modularity(of: g.louvainCommunities())` reads as expected. igraph's membership-vector form
(`modularity(membership)`) is `partition.map`-able and not offered separately.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `Partition`, `community(of:)` | README module table; NetworkX docs ("a partition of the nodes", `is_partition`, `NotAPartition`, `community_utils`); igraph `VertexClustering.membership`; JGraphT `ClusteringAlgorithm.Clustering` | `Clustering` (JGraphT, igraph `VertexClustering`): "clustering" is also the clustering coefficient (`clusteringCoefficients()` in Cliques). `membership(of:)` (igraph): igraph's word is a whole vector, and Connectivity uses `component(of:)`, so `community(of:)` is its parallel |
| `modularity(of:resolution:)` | NetworkX `modularity(G, communities, resolution=)`, igraph `modularity(membership, resolution=)`, JGraphT `UndirectedModularityMeasurer.modularity(partitions)`; Newman–Girvan 2004, Reichardt–Bornholdt 2006 (γ) | `gamma:`: NetworkX and igraph both say `resolution` |
| `partitionQuality(of:)`, `PartitionQuality`, `coverage`, `performance` | NetworkX `partition_quality` returning `(coverage, performance)`; Fortunato 2010 | Separate `coverage(of:)`, `performance(of:)` (NetworkX < 3.0 had them, deprecated in favour of `partition_quality`, which computes both in one pass) |
| `louvainCommunities(resolution:threshold:)` | NetworkX `louvain_communities(resolution=, threshold=, seed=)`; Blondel et al. 2008 ("the Louvain method") | `multilevelCommunities` (igraph `community_multilevel`): the paper's own name for it is Louvain, and NetworkX's name is the one users search for |
| `greedyModularityCommunities(resolution:)` | NetworkX `greedy_modularity_communities`; Clauset–Newman–Moore 2004 ("greedy modularity optimization") | `fastGreedyCommunities` (igraph `community_fastgreedy`): "fast" describes the 2004 data structure, not the method |
| `labelPropagationCommunities()` | NetworkX `label_propagation_communities` (semi-synchronous); igraph `community_label_propagation` | `semiSynchronousLabelPropagationCommunities`: NetworkX gives the plain name to this variant |
| `asynchronousLabelPropagationCommunities()` | NetworkX `asyn_lpa_communities` ("asynchronous label propagation algorithm"); Raghavan et al. 2007 | `asynLPACommunities`: Swift spells words out (Centrality chose `maxIterations` over `max_iter` the same way) |
| `using generator: inout some RandomNumberGenerator` | Swift standard library (`shuffled(using:)`, `randomElement(using:)`); README ("Random generators take `inout some RandomNumberGenerator`") | `seed: Int` (NetworkX, igraph's global seed): Swift has no seeded generator in the standard library to turn a seed into, and taking a generator lets the caller choose and share one |
| `threshold:` | NetworkX `louvain_communities(threshold=1e-7)` | `tolerance:` (Centrality's word): this is not a convergence tolerance but the least modularity gain that starts another level |

**Proposed Terminology row:** modularity (`modularity(of:resolution:)`; NetworkX, igraph, JGraphT;
Newman–Girvan Q, γ the resolution of Reichardt–Bornholdt).

## Semantics

Throughout, m is the total edge weight (a self-loop once), A the adjacency matrix as the rows list
it (parallel copies add; an undirected self-loop is A_vv = 2w, as `degree(of:)`, NetworkX and igraph
count it), k_v = Σ_w A_vw the (weighted) degree. Unweighted means every weight 1.

### Partition order (canonical)

Communities are ordered by their least vertex number (vertex index, or position in `vertices`),
and each lists its vertices in `vertices` order; so the result is a function of the communities
alone, not of the labels an algorithm used. This is `Components`' order. NetworkX returns sets
in an order that depends on the algorithm (sorted by size for greedy, label-dict order for
Louvain); `cases.md` compares in canonical order.

### Modularity

* **Undirected** (Newman–Girvan 2004, with Reichardt–Bornholdt's γ): Q = Σ_c [L_c/m − γ (d_c/2m)²],
  equal to (1/2m) Σ_ij (A_ij − γ k_i k_j/2m) δ(c_i, c_j). With A_vv = 2w, a self-loop is inside its
  community and counts twice in d_c (CD-023, CD-024, CD-060, CD-061); NetworkX and igraph agree
  (−1/18 on CD-060). Parallel edges add: CD-058 equals the weight-2 CD-059.
* **Directed** (Leicht–Newman 2008, NetworkX and igraph's default): Q = Σ_c [L_c/m − γ out_c in_c/m²]
  with out_c, in_c the community's out- and in-weight. A directed loop is one out- and one in-arc
  (CD-067). `graph.directed` (two arcs per edge, two loop arcs per loop) gives the same Q as the
  undirected graph (CD-057, CD-062).
* **m = 0** (no edges, or every weight 0): **0** (NetworkX; CD-001, CD-010, CD-016). igraph returns
  NaN. Q is 0/0 there, so neither is derived; NetworkX is the README's reference for defaults,
  and 0 keeps Louvain's stop rule free of NaN.
* **Preconditions:** every vertex listed exactly once and nothing else listed (NetworkX raises
  `NotAPartition`: CD-155 – CD-157), checked with a stamp array in O(n + Σ|c|); empty communities
  are allowed and contribute 0 (CD-039; NetworkX's `is_partition` accepts them). γ finite and ≥ 0
  (CD-158, CD-159; a negative γ rewards splitting edges and no algorithm here is defined for it).
  Weights finite and ≥ 0, read once per edge in position order (CD-160 – CD-162): modularity with
  negative weights needs the signed formulation (Gómez et al. 2009), which no library here offers.
* γ = 0 gives the coverage (CD-044); γ = 1 is the classic Q.

### Partition quality

* **coverage** = (edges with both ends in one community) / (edges): unweighted (NetworkX has no
  weights here), parallel copies each count (CD-076), a self-loop is inside (CD-078). NaN without
  edges (CD-002, CD-021: NetworkX raises ZeroDivisionError).
* **performance** = (pairs in one community and adjacent + pairs in different communities and not
  adjacent) / pairs, over unordered pairs {u, v}, u ≠ v (ordered pairs when directed: CD-081).
  Adjacency is "at least one edge", so parallel copies do not matter (CD-077: NetworkX returns −1
  for every multigraph), and self-loops are not pairs (CD-079: NetworkX counts a loop as an
  intra-community edge, giving 1 instead of ⅔). NaN with fewer than two vertices (CD-003, CD-015).
* Same partition precondition as modularity (CD-163).

### Louvain

Blondel et al. 2008, with NetworkX's arithmetic, stop rule and directed gain, so that it is
NetworkX's `louvain_communities` with a fixed order and tie rule (`ref.py` runs NetworkX's own code
so patched and compares every row):

1. **Level 0** is the graph with parallel edges merged (weights summed) and self-loops kept as the
   vertex's inner weight. Each vertex starts in its own community, labelled by its number.
2. **Local moving.** Sweep the vertices **in index order** (with `using:`, in an order shuffled once
   per level by `generator`: NetworkX shuffles once per level too). For vertex u in community C,
   remove u, then for each community D adjacent to u (and C) compute
   gain(D) = k_u,D · m − γ′ · x_D, with k_u,D the weight from u into D (loops excluded),
   γ′ = γ/2 and x_D = Σ_tot(D) · k_u undirected; γ′ = γ and x_D = k_u^out Σ_in(D) + k_u^in Σ_out(D)
   directed (Dugué–Perez 2015, NetworkX). u joins the D of greatest gain; **u stays when C's gain
   ties the best; among other communities a tie goes to the greatest label.** Repeat sweeps until
   one moves nothing.
3. **Stop rule** (NetworkX): the level's partition is kept; if its modularity exceeds the previous
   level's (initially the singletons') by more than `threshold`, aggregate (one vertex per nonempty
   community, numbered in label order, so labels keep their order; edge weights summed, inner
   weight on the loop) and run another level, keeping its partition only if some vertex moved.
4. Edgeless graphs return singletons without a sweep (NetworkX `is_empty`; CD-017); total weight 0
   moves nothing (CD-174).

* **The tie rule.** "Stay on a tie" is every implementation's (NetworkX's strict `gain > best_gain`
  starting from the stay value; igraph the same). Among other communities NetworkX keeps the first
  maximum met in its neighbor-dict order, igraph the first in its own order: an artifact of
  iteration order that would make results depend on a representation's row order. The greatest
  label depends only on vertex numbering, and is the rule NetworkX's deterministic
  `label_propagation_communities` uses (`max(high_labels)`), so the module has one tie rule.
  Ties are common: the first move on a path or cycle is always one (CD-101, CD-102).
* **Floating point.** Gains are compared exactly. With integer (or dyadic) weights every quantity
  is exact, and the result is a function of vertex numbering only. With other weights, k_u,D is
  summed in row order and aggregated weights in edge order, so two representations with different
  row orders can break a near-tie differently; documented. The gain is written exactly as above
  (one multiply, one multiply-subtract per candidate, no division) so that it reproduces
  NetworkX's ties bit for bit.
* **Parameters.** `resolution` γ: finite, ≥ 0 (CD-164); γ = 0 merges each connected component
  (CD-094), larger γ gives smaller communities (CD-092, CD-093). `threshold`: finite, ≥ 0 (CD-165,
  CD-166); NetworkX's 1e-7 default; a large threshold stops after one level (CD-095). Weights
  finite, ≥ 0 (CD-167, CD-168). Defaults are NetworkX's.
* Self-loops count in degrees and never move a vertex (CD-025, CD-099); parallel edges are weight
  (CD-098). Directed: CD-108 – CD-110.

### Greedy modularity (Clauset–Newman–Moore)

Start from singletons with ΔQ_ij = w_ij/m − γ (a_i b_j + b_i a_j) for each adjacent pair (w_ij the
summed weight between i and j in both directions, loops excluded; a = b = k/2m undirected, a = k^out/m,
b = k^in/m directed). Repeatedly take the pair of **greatest ΔQ; ties to the least pair (i, j),
merging i into j** (NetworkX's heap order on `(−ΔQ, i, j)`), and update the neighbors' ΔQ with
CNM's three rules (common neighbor: sum; neighbor of one: subtract γ(a_x b_k + a_k b_x)), exactly as
NetworkX writes them. Stop when the greatest ΔQ is negative (merges with ΔQ = 0 continue: CD-128).
This is NetworkX's `greedy_modularity_communities` with `cutoff = 1`, `best_n = None`, and the
catalog matches it on every row. Edgeless or zero-weight graphs give singletons (CD-018, CD-173;
NetworkX divides by zero on the latter). igraph's `community_fastgreedy` reaches the same Q on the
karate club (0.3807, CD-119).

### Label propagation

A vertex's **votes** are its row: each edge to another vertex adds its weight (1 unweighted) to
that neighbor's label; **self-loops vote for nothing** (Raghavan et al. define the rule over
N(v), v ∉ N(v)); parallel copies each vote (CD-141, CD-149), consistent with weights. A vertex with
no votes keeps its label (CD-019, CD-027). Labels start as vertex numbers. Ties: **keep the current
label if it is among the most voted, else take the greatest** (NetworkX's `_update_label`).

* **Semi-synchronous** (`labelPropagationCommunities`, Cordasco–Gargano 2010, NetworkX): color the
  graph greedily in largest-degree-first order (ties by vertex number; `degree(of:)`, loops ignored
  for the coloring), then, while some vertex with votes does not hold a most-voted label, run a
  round: color classes in increasing color, each class's vertices updated from the current labels
  (a class is independent, so the order inside it does not matter). A vertex with a unique
  most-voted label takes it. On simple graphs this is NetworkX's function exactly (CD-133 – CD-142).
* **Asynchronous** (`asynchronousLabelPropagationCommunities`, Raghavan et al. 2007, NetworkX
  `asyn_lpa_communities`): sweep the vertices in index order (with `using:`, shuffled each sweep,
  and ties drawn uniformly by `generator`, as NetworkX); a vertex whose label is not among the most
  voted takes the greatest of them; stop after a sweep with no change. It terminates: every change
  strictly increases the weight of edges whose ends share a label. The deterministic order is a
  documented weakness: on a ring of cliques one label floods the graph (CD-145) where shuffled
  orders usually find the cliques; `using:` is the remedy, and why the overload exists.
* Weights finite and ≥ 0 (CD-171, CD-172). `Graph` only (Scope).

### Determinism (decision)

**Every entry point without `using:` is a deterministic function of the graph value: its vertex
numbering and its edge weights** (and, for non-integer weights, the floating-point summation order
fixed by rows and edge positions). Louvain and asynchronous label propagation additionally take
`using generator: inout some RandomNumberGenerator`.

* **Why not only a generator.** NetworkX and igraph randomize Louvain and LPA (`seed=None` draws from
  global state; igraph's `community_multilevel` gives 8 different modularities on the karate club
  over 30 seeds, its label propagation 1 to 4 communities: `probe.py`). The README wants results
  that are reproducible and testable from a catalog; Swift's standard library has no seedable
  generator, so a generator-only API would make every caller find or write one, and a default of
  `SystemRandomNumberGenerator` would make the plain call nondeterministic. The deterministic
  sweep order is not a degraded algorithm: it is Blondel et al.'s original formulation (sequential
  order; the paper discusses the order's effect as a heuristic choice), and greedy
  modularity and semi-synchronous propagation are deterministic in every library already.
* **Why still offer `using:`.** Restarting a randomized algorithm and keeping the best partition is
  standard practice for Louvain, and asynchronous LPA needs random order to avoid label flooding
  (CD-145). `using:` follows Swift's `shuffled(using:)` and the README's RandomGraphs convention.
* **What the generator drives** (documented, so a seeded generator reproduces a result across
  releases): Louvain: one Fisher–Yates shuffle of the level's vertices per level, i from k − 1 down
  to 1 swapping i with `Int(generator.next(upperBound: UInt(i + 1)))`; ties keep the label rule.
  Asynchronous LPA: one such shuffle per sweep, and a tie among t labels (in order of first vote in
  the row) takes the `generator.next(upperBound: UInt(t))`-th. The catalog's `using:` rows
  (CD-112 – CD-114, CD-153, CD-154) are graphs where every order gives the same partition (ref.py:
  200 orders, NetworkX 25 seeds); tests add properties (a valid partition; Louvain's Q at least the
  singletons'; the same seeded generator gives the same result).

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
  and a `touched: [Int]` list, reset after each vertex (Blondel's and igraph's layout); Σ_tot per
  community in a `[Double]`.
* **Greedy modularity.** Per community, ΔQ to its neighbors in a sorted adjacency (merged by a
  linear merge of two sorted rows, which is CNM's balanced-tree update in array form); per row its
  maximum, and a global max-heap of row maxima keyed by (ΔQ, −i, −j) so that ties are the least
  pair. `PriorityQueueModule`'s `IndexedPriorityQueue` with a composite key (its ties are
  unspecified, so the key must carry i and j).
* **Label propagation.** Votes accumulate into `[Double]` indexed by label with a touched list;
  the coloring is a counting sort by degree and a first-fit with a stamp array (the
  `ColoringModule` greedy coloring, largest-first, once it exists; until then a private loop).
* **`Partition`** is built from a label per vertex number by the counting sort `Components` uses
  (moved to GraphProtocols as `package`). Canonical relabeling: labels by first appearance in
  vertex order.
* **No recursion; no allocation per sweep or per vertex; `@inlinable`; `some` generics**, as the
  rest of the library. `using:` overloads take the generator `inout` and call the same internal
  loop with an order buffer.
* **Dependencies.** GraphProtocols and PriorityQueueModule. **Proposed edit to
  `scripts/modules.py`:** `CommunityDetection` depends on GraphProtocols, PriorityQueueModule.
  Tests import Connectivity for `modularity(of: g.connectedComponents())`.
* **Tests** (public API only): every catalog row; for each partition-returning row also
  `community(of:)` agrees with membership, `count`, and `modularity(of: result)` against the value
  ref.py prints; Louvain's result has Q ≥ the singletons'; greedy's Q ≥ every partition it passed
  through (checked by property on small random graphs against a brute-force merge); `using:` with a
  test-defined SplitMix64 gives a valid partition and repeats with the same seed. Benchmarks:
  Louvain against igraph `community_multilevel` and NetworkX on LFR-like graphs.

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Modularity, no edges | NetworkX 0; igraph NaN. Ours: 0 | CD-001, CD-016 |
| Directed modularity | NetworkX and igraph (`directed=True`, default): Leicht–Newman, 0 on a dipath split; igraph `directed=False`: −0.125. Ours: Leicht–Newman | CD-063 |
| Self-loop in modularity | NetworkX and igraph agree (A_vv = 2): −0.0556 | CD-060 |
| `performance` | NetworkX returns −1 for every multigraph and counts a self-loop as an intra-community edge (1 on CD-079's graph); ours counts adjacent pairs (⅔) | CD-077, CD-079 |
| coverage / performance at 0/0 | NetworkX raises ZeroDivisionError; ours NaN | CD-002, CD-003, CD-021 |
| Louvain order | NetworkX shuffles always (`seed=None` uses global state): karate Q 0.3854 – 0.4198 over 50 seeds; igraph randomizes too (0.392 – 0.4198 over 30 seeds). Ours: index order, 0.4188; `using:` for shuffled runs | CD-088 |
| Louvain ties | NetworkX: first maximum in neighbor-dict order; ours: greatest label | CD-101, CD-102 |
| Label propagation votes | NetworkX `asyn_lpa_communities` unweighted counts a parallel pair once (`Counter(G[node])`) but weighted counts each copy; a self-loop votes for its own label once. Ours: copies each vote, loops never | CD-141, CD-149, CD-151 |
| Label propagation ties | Cordasco–Gargano and Raghavan et al.: random; NetworkX semi-synchronous: greatest label; NetworkX asynchronous: `seed.choice`. Ours: greatest label, or `generator` with `using:` | CD-031, CD-143 |
| Directed label propagation | NetworkX `asyn_lpa` successors only, `fast_label_propagation` both directions, `label_propagation_communities` refuses; igraph `mode`. Ours: not offered | — |
| Greedy modularity, zero total weight | NetworkX divides by zero; ours singletons | CD-173 |
| Greedy modularity | NetworkX and igraph `community_fastgreedy` agree on the karate club (Q 0.3807) | CD-119 |

## Open questions

1. **Bounded draws.** `generator.next(upperBound:)` is the standard library's (Lemire's method,
   `@inlinable`): reproducible today, but its algorithm is not documented as stable. Pin a
   Grafluent-owned bounded draw (shared with RandomGraphs), or accept the standard library's?
2. **`Dendrogram`.** Girvan–Newman, greedy modularity's merge history, Louvain's levels, and later
   hierarchical clustering all produce hierarchies; one type (igraph's `VertexDendrogram`, SciPy's
   linkage matrix) should be designed before phase 2.
3. **Edge betweenness in Centrality** (phase 2, with Girvan–Newman): confirm the edge-keyed result
   type, and Girvan–Newman's tie policy for floating-point betweenness.
4. **Signed and negative weights** (Gómez et al. 2009): out of scope by precondition; revisit if
   asked.

## README edits proposed

* `CommunityDetection` row: "Modularity (Newman–Girvan with resolution; Leicht–Newman directed),
  coverage and performance, Louvain, greedy modularity (Clauset–Newman–Moore), label propagation
  (semi-synchronous and asynchronous); deterministic, with `using:` overloads for the randomized
  ones (**planned**, phase 1). Later: Girvan–Newman (with edge betweenness in Centrality), Leiden,
  dendrograms"; result types `Partition`, `PartitionQuality`.
* Algorithms → "What is a `Sequence`" → Partitions: add "communities are `Partition`, the same
  layout and canonical order as `Components`".
* Package layout: CommunityDetection depends on GraphProtocols, PriorityQueueModule; move
  `Components`' grouping code to GraphProtocols as `package`.
* Terminology row above (modularity, resolution).
