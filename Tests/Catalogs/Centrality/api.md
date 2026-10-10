# Centrality: proposed API (phase 1)

Vertex centrality on `Graph` and `DirectedGraph`: degree (and in- and out-degree), closeness,
harmonic, Brandes betweenness, eigenvector, Katz, PageRank, and HITS (on `DirectedGraph`),
unweighted and weighted where the libraries are. Every measure returns one value type,
`CentralityScores`: a dense `Double` per vertex with `score(of:)` / `score(ofIndex:)`. HITS returns
two of them. `cases.md` (CE-001 – CE-206, 162 cases) pins the values. `ref.py` recomputes every one
with the model below and checks it against the definitions (Floyd–Warshall; Σ σ_sv·σ_vt/σ_st over
edge sequences), dense numpy/scipy solves, and NetworkX 3.7 wherever NetworkX shares the semantics
(`uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 ref.py`, a few
seconds). `probe.py` and `probe2.py` hold the python-igraph 1.0 values quoted below (`uv run
--no-project --with networkx==3.7 --with scipy==1.18.1 --with igraph python3 probe.py`).

## Scope

**In, phase 1**

| Entry point | On | Why |
|---|---|---|
| `degreeCentrality()` | both | The README row. NetworkX `degree_centrality` (directed: in + out). O(n + m), and the one measure every library has |
| `inDegreeCentrality()`, `outDegreeCentrality()` | `DirectedGraph` | NetworkX `in_degree_centrality` / `out_degree_centrality`. On a plain `DirectedGraph` in-degrees take one pass over every row, so no `BidirectionalDirectedGraph` constraint is needed |
| `closenessCentrality(wfImproved:)`, `closenessCentrality(of:wfImproved:)`, each also `(weight:)` | both | The README row. NetworkX `closeness_centrality` (with `u=` for one vertex), igraph `closeness`, JGraphT `ClosenessCentrality`, Boost `closeness_centrality`. One vertex costs one search, not n |
| `harmonicCentrality()`, `harmonicCentrality(of:)`, each also `(weight:)` | both | The README row. NetworkX `harmonic_centrality`, igraph `harmonic_centrality`, JGraphT `HarmonicCentrality`. Closeness for disconnected graphs without a correction factor (Marchiori–Latora 2000, Boldi–Vigna 2014) |
| `betweennessCentrality(normalized:endpoints:)`, also `(weight:normalized:endpoints:)` | both | The README row. Brandes 2001. NetworkX `betweenness_centrality`, igraph `betweenness`, JGraphT `BetweennessCentrality`, Boost `brandes_betweenness_centrality` |
| `eigenvectorCentrality(tolerance:maxIterations:)`, also `(weight:…)` | both | The README row. NetworkX `eigenvector_centrality` (power iteration on A + I), igraph `eigenvector_centrality`, JGraphT `EigenvectorCentrality` |
| `katzCentrality(alpha:beta:normalized:tolerance:maxIterations:)`, also `(weight:…)` | both | The README row. NetworkX `katz_centrality`, JGraphT `KatzCentrality`; Katz 1953 |
| `pageRank(dampingFactor:tolerance:maxIterations:)`, `pageRank(dampingFactor:personalization:tolerance:maxIterations:)`, each also `(weight:…)` | both | The README row. NetworkX `pagerank`, igraph `pagerank` / `personalized_pagerank`, JGraphT `PageRank`, Boost `page_rank`. Personalization is how PageRank is used for recommendation and local ranking, and every library but Boost has it |
| `hits(tolerance:maxIterations:)`, also `(weight:…)` → `HubAndAuthorityScores` | `DirectedGraph` | The README row. NetworkX `hits`, igraph `hub_score` / `authority_score` (C: `igraph_hub_and_authority_scores`); Kleinberg 1999 |

**Out, and where it goes**

| Not in phase 1 | Reason |
|---|---|
| Edge betweenness (NetworkX `edge_betweenness_centrality`, igraph `edge_betweenness`, Boost's `edge_centrality_map`, JGraphT `EdgeBetweennessCentrality`) | Its main consumer is Girvan–Newman (CommunityDetection, planned), which recomputes it after every edge removal and so needs the engine, not a one-shot. A public per-edge result also needs a type keyed by edge position on both protocols (`Graph`'s results are `DirectedView`-based, whose edge positions are arcs), which should be designed once for every edge measure (edge load, edge current flow). The engine is written for it now: the successor-side accumulation below computes each slot's credit σ_v/σ_w·(1 + δ_w), which is exactly the edge's dependency, so phase 2 adds an accumulator, not an algorithm. **Phase 2, with Girvan–Newman** |
| Approximate betweenness by sampling (NetworkX `k=`, `seed=`; Brandes–Pich 2007; Riondato–Kornaropoulos 2016) | Needs the library's random-number story (`RandomGraphs` takes `inout some RandomNumberGenerator`); NetworkX's `k` scales by n/k, a choice to make with that. Phase 2 |
| `betweenness_centrality_subset`, stress, distance-scaled and bounded variants (Brandes 2008) | NetworkX-only (subset) or not in any library we compare with. They share the engine; add if asked |
| Load centrality (NetworkX `load_centrality`, Goh et al.) | NetworkX-only, and NetworkX documents that it differs from betweenness only in a subtle split rule |
| Current-flow closeness and betweenness, information centrality, Laplacian centrality, subgraph centrality, communicability, second-order centrality, Estrada index | Linear algebra on the Laplacian or the matrix exponential: `SpectralGraphTheory` |
| A direct eigen-solver (NetworkX `eigenvector_centrality_numpy` / `katz_centrality_numpy`, igraph's ARPACK, PRPACK for PageRank) | A sparse eigen-solver or linear solver is a dependency Grafluent does not have (swift-numerics has none; Accelerate is platform-only, and `SpectralGraphTheory` is where it would come in). Power iteration converges geometrically on every input where the answer is unique; non-convergence is reported (below). Phase 2 in `SpectralGraphTheory` |
| igraph's closeness `mode` / JGraphT's `incoming` flag | Directed closeness and harmonic use incoming distances (NetworkX, below). Outgoing: run on the transpose: `CompressedSparseRow.transposed()` today, the `reversed` view (README Terminology) once it exists. Revisit if `reversed` is not added |
| `nstart` (NetworkX, a start vector for the iterations) | It changes the answer exactly where the answer is not unique (CE-138, CE-195): a fixed start (uniform) makes results reproducible. Not offered |
| `dangling=` (NetworkX-only: a separate distribution for dangling vertices) | NetworkX-only. Dangling vertices follow the personalization (NetworkX's default; igraph and JGraphT do the same with a uniform jump). Phase 2 if asked |
| Per-vertex Katz β (NetworkX `beta` as a dict), Bonacich alpha/power centrality (igraph `alpha_centrality`, `power_centrality`, JGraphT `AlphaCentrality`) | The per-vertex β is NetworkX's exogenous term, which is Bonacich's alpha centrality; add as one overload `katzCentrality(alpha:beta: (Vertex) -> Double, …)` if asked |
| Weighted degree ("strength", igraph `strength`) | `vertices.map { incidentEdges(of: $0).reduce(0) { $0 + w($1) } }`; NetworkX has no weighted degree centrality |
| HITS on `Graph` | On a symmetric matrix hubs and authorities are equal, and both are the eigenvector centrality rescaled to sum 1 (igraph warns "These are the same as eigenvector centralities"; CE-204, CE-205). `graph.directed.hits()` gives it |
| Eccentricity centrality, centroid | `Distances` |
| Group, percolation, trophic, VoteRank, closeness vitality, dispersion, reaching | NetworkX-only |
| Parallel Brandes (one task per block of sources) | Sources are independent; worth an `async` overload once the library has a concurrency story. Combining per-task arrays changes the summation order, so it would document its own order |

## Summary

```swift
import GraphProtocols

extension Graph {
    /// degree(of: v) / (n − 1); a self-loop counts 2, parallel copies each count. One vertex scores 1.
    func degreeCentrality() -> CentralityScores<DirectedView<Self>>

    /// (r − 1)/Σd(u, v) · (r − 1)/(n − 1) over the r vertices that reach u (itself included);
    /// `wfImproved: false` drops the second factor. 0 when nothing else reaches u.
    func closenessCentrality(wfImproved: Bool = true) -> CentralityScores<DirectedView<Self>>
    func closenessCentrality(of vertex: Vertex, wfImproved: Bool = true) -> Double
    func closenessCentrality<W: BinaryInteger>(weight: (Edges.Index) -> W, wfImproved: Bool = true) -> CentralityScores<DirectedView<Self>>
    func closenessCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, wfImproved: Bool = true) -> CentralityScores<DirectedView<Self>>
    func closenessCentrality<W: BinaryInteger>(of vertex: Vertex, weight: (Edges.Index) -> W, wfImproved: Bool = true) -> Double
    func closenessCentrality<W: BinaryFloatingPoint>(of vertex: Vertex, weight: (Edges.Index) -> W, wfImproved: Bool = true) -> Double

    /// Σ 1/d(v, u) over the vertices v ≠ u at a positive finite distance. Not normalized.
    func harmonicCentrality() -> CentralityScores<DirectedView<Self>>
    func harmonicCentrality(of vertex: Vertex) -> Double
    // … and the same four weighted overloads as closeness.

    /// Brandes. normalized: ÷ (n − 1)(n − 2)/2 (with endpoints: ÷ n(n − 1)/2); otherwise over
    /// unordered pairs. Weights: precondition > 0, not NaN.
    func betweennessCentrality(normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<DirectedView<Self>>
    func betweennessCentrality<W: Comparable & AdditiveArithmetic>(
        weight: (Edges.Index) -> W, normalized: Bool = true, endpoints: Bool = false) -> CentralityScores<DirectedView<Self>>

    /// nil when the iteration has not converged after `maxIterations` steps.
    func eigenvectorCentrality(tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<DirectedView<Self>>?
    func eigenvectorCentrality<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<DirectedView<Self>>?

    func katzCentrality(alpha: Double = 0.1, beta: Double = 1, normalized: Bool = true,
                        tolerance: Double = 1e-6, maxIterations: Int = 1000) -> CentralityScores<DirectedView<Self>>?
    func katzCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, alpha: Double = 0.1, beta: Double = 1,
                        normalized: Bool = true, tolerance: Double = 1e-6, maxIterations: Int = 1000) -> CentralityScores<DirectedView<Self>>?

    /// Each edge is two arcs (`graph.directed`), a self-loop two loop arcs.
    func pageRank(dampingFactor: Double = 0.85, tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<DirectedView<Self>>?
    func pageRank(dampingFactor: Double = 0.85, personalization: (Vertex) -> Double,
                  tolerance: Double = 1e-6, maxIterations: Int = 100) -> CentralityScores<DirectedView<Self>>?
    // … and both with a leading `weight: (Edges.Index) -> W`, W: BinaryFloatingPoint.
}

extension DirectedGraph {
    func degreeCentrality() -> CentralityScores<Self>      // (in + out) / (n − 1)
    func inDegreeCentrality() -> CentralityScores<Self>
    func outDegreeCentrality() -> CentralityScores<Self>
    // closeness, harmonic: over incoming distances d(v, u); betweenness over ordered pairs
    // (normalized ÷ (n − 1)(n − 2), unnormalized not halved); eigenvector and Katz over in-arcs
    // (the left eigenvector); PageRank over out-arcs: the same members as Graph, returning
    // CentralityScores<Self>.

    /// Kleinberg's hubs and authorities, each summing to 1.
    func hits(tolerance: Double = 1e-8, maxIterations: Int = 100) -> HubAndAuthorityScores<Self>?
    func hits<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, tolerance: Double = 1e-8,
                                      maxIterations: Int = 100) -> HubAndAuthorityScores<Self>?
}

/// A score per vertex (README: "a dense vector indexed by vertex").
@frozen public struct CentralityScores<G: DirectedGraph> {
    /// Precondition: `vertex` is a vertex.
    public func score(of vertex: G.Vertex) -> Double
    /// By vertex index (position in `vertices` without vertex indices). Precondition: in range.
    public func score(ofIndex index: Int) -> Double
    /// Every score, in `vertices` order (by vertex index). O(1): stored.
    public var scores: [Double] { get }
}

@frozen public struct HubAndAuthorityScores<G: DirectedGraph> {
    public var hubs: CentralityScores<G> { get }
    public var authorities: CentralityScores<G> { get }
}

extension CentralityScores: Sendable where G: Sendable, G.Vertex: Sendable {}
extension HubAndAuthorityScores: Sendable where G: Sendable, G.Vertex: Sendable {}
```

As in Distances, `Graph`'s results use `DirectedView<Self>` as `G` (as `Eccentricities` and
`shortestPaths(from:)` do), and the values hold a copy of the graph to map vertices to indices, so
they are not `Equatable`. `scores` is the dense vector itself (callers rank it with
`indices.sorted { scores[$0] > scores[$1] }`), so no top-k API is needed.

**One result type, not one per measure.** Every measure is the same shape, a `Double` per vertex,
and has no derived members (unlike `Eccentricities`' radius and center, or `CoreNumbers`'
degeneracy). Ten structurally identical types (`BetweennessCentrality`, `PageRank`, …) would add
names and no meaning. JGraphT's `VertexScoringAlgorithm` (`getVertexScore`, `getScores`) is the
precedent for one "scores" abstraction across all measures, and "score" is igraph's word too
(`hub_score`, `authority_score`). HITS has two vectors, so it has its own type with two members
(README: "Results are dedicated types, not tuples"); its name is igraph's C function.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `degreeCentrality()`, `inDegreeCentrality()`, `outDegreeCentrality()` | NetworkX `degree_centrality`, `in_degree_centrality`, `out_degree_centrality`; Freeman 1978 | |
| `closenessCentrality(…)`, `wfImproved:` | NetworkX `closeness_centrality(wf_improved=)`, JGraphT `ClosenessCentrality`, Boost `closeness_centrality`, igraph `closeness` | `wassermanFaust:` (the authors' name; NetworkX's own parameter name is the one users search for). igraph's `normalized` means something else (dividing by r − 1, which NetworkX always does) |
| `harmonicCentrality(…)` | NetworkX, igraph `harmonic_centrality`, JGraphT `HarmonicCentrality` | |
| `betweennessCentrality(normalized:endpoints:)` | NetworkX `betweenness_centrality(normalized=, endpoints=)`, JGraphT `BetweennessCentrality(normalize)`, igraph `betweenness` | `brandesBetweennessCentrality` (Boost): the algorithm, not the measure |
| `eigenvectorCentrality(tolerance:maxIterations:)` | NetworkX `eigenvector_centrality(tol=, max_iter=)`, igraph, JGraphT `EigenvectorCentrality(maxIterations, tolerance)` | `tol`/`maxIter`: Swift spells words out; JGraphT's parameter names are these |
| `katzCentrality(alpha:beta:normalized:…)` | NetworkX `katz_centrality(alpha=, beta=, normalized=)`, JGraphT `KatzCentrality`, Katz 1953 (α) | JGraphT calls α `dampingFactor` and β `exogenousFactor`; NetworkX and the paper use α and β |
| `pageRank(dampingFactor:personalization:…)` | NetworkX `pagerank(personalization=)`, Boost `page_rank` (camel-cased), igraph `pagerank(damping=)`, JGraphT `PageRank(dampingFactor)`; Brin–Page 1998 call it the damping factor | `alpha:` (NetworkX): also Katz's α, a different quantity; the damping factor is the term the paper, igraph, Boost and JGraphT share |
| `hits()`, `HubAndAuthorityScores`, `hubs`, `authorities` | NetworkX `hits` returning `(hubs, authorities)`; igraph C `igraph_hub_and_authority_scores`, R `hits_scores`; Kleinberg 1999 | `hubsAndAuthorities()`: no library spells the call that way |
| `CentralityScores`, `score(of:)`, `scores` | JGraphT `VertexScoringAlgorithm.getVertexScore`, `getScores`; igraph `*_score`; README "dense vector indexed by vertex" | `CentralityMap` (Boost's property map): "map" reads as a dictionary type (Distances rejected `EccentricityMap` for the same reason) |

**Proposed Terminology rows:** betweenness (`betweennessCentrality()`, all libraries; Freeman
1977, Brandes 2001); PageRank (`pageRank()`, damping factor; NetworkX `alpha`); hubs and
authorities (`hits()`).

## Semantics

### Degree

degree(of: v)/(n − 1), so a self-loop counts 2 and each parallel copy counts (CE-031, CE-032):
the value is the graph's `degree(of:)` scaled, and can exceed 1 on a multigraph, as in NetworkX.
Directed: `degreeCentrality()` is (in + out)/(n − 1) (NetworkX), and a directed loop is one
in-arc and one out-arc (CE-036). **One vertex scores 1** (NetworkX's rule, CE-009, CE-041), the
empty graph gives an empty result. `g.directed.degreeCentrality()` is twice
`g.degreeCentrality()` (CE-040).

### Closeness and harmonic

Distances are shortest-path lengths in edges, or weighted sums. **Directed: incoming distances
d(v, u)**, how far u is from the vertices that reach it (NetworkX, for both closeness and harmonic;
CE-054, CE-072). igraph's default mode is "all" (directions ignored, CE-054's note), JGraphT and
Boost default to outgoing. NetworkX is the README's reference for defaults, and the incoming
reading is the one that makes a sink of many short paths central. Outgoing distances: run on the
transpose (Scope).

* **Closeness** (Bavelas, Sabidussi): with r the number of vertices that reach u (u included) and
  S the sum of their distances, C(u) = (r − 1)/S · (r − 1)/(n − 1) when `wfImproved` (the default,
  Wasserman–Faust's correction, NetworkX), (r − 1)/S without it (igraph's `normalized=True`).
  **0 when S = 0** (nothing else reaches u, or n = 1: CE-010, CE-053, CE-066). With
  `wfImproved: false` each component is scored on its own, so a K₂ component scores 1 like the
  middle of a P₃ (CE-052); the correction weighs by the share of the graph reached (CE-051).
* **Harmonic** (Marchiori–Latora, Boldi–Vigna): H(u) = Σ 1/d(v, u) over v with 0 < d < ∞, **not
  normalized** (NetworkX; igraph divides by n − 1 by default, JGraphT optionally). Unreachable
  vertices add 0, so no correction is needed (CE-071). A distance of 0 to another vertex (zero
  weights) is skipped, as NetworkX does (CE-076), not counted as 1/0.
* **Weights:** as Distances: called once per edge in position order before any search; precondition
  ≥ 0 and not NaN (CE-063, CE-064, CE-080). Zero weights are allowed (CE-062). Distances are summed
  in `W` along paths (Dijkstra) and converted to `Double` per vertex as they are added to S, so
  integer weights are exact up to 2⁵³. Two overloads, `BinaryInteger` and `BinaryFloatingPoint`,
  because a generic `Comparable & AdditiveArithmetic` weight cannot be divided or converted.
* Self-loops and parallel copies change no distance (CE-067).

### Betweenness

B(v) = Σ σ_st(v)/σ_st over ordered pairs s ≠ v ≠ t with t reachable from s, σ_st the number of
shortest s–t paths and σ_st(v) those through v (Freeman 1977; Brandes 2001), then NetworkX's
rescaling:

| | normalized (default) | not normalized |
|---|---|---|
| undirected | ÷ (n − 1)(n − 2) on the ordered sum, i.e. per unordered pair ÷ (n − 1)(n − 2)/2 | ÷ 2 (unordered pairs) |
| directed | ÷ (n − 1)(n − 2) | as is |
| with `endpoints: true` | each reachable pair also credits s and t (+1 each), and n(n − 1) replaces (n − 1)(n − 2) | |

No scaling when the divisor would be 0 (n ≤ 2, or n < 2 with endpoints; CE-013, CE-025, CE-026).
`g.directed` gives the same normalized values and twice the unnormalized ones (CE-106, CE-107).

* **Paths are edge sequences.** In a multigraph each parallel copy is a distinct shortest path
  (CE-108: 0 → 2 has three shortest paths, two through vertex 1, so B(1) = ⅔). This is what Boost
  and igraph compute (both iterate out-edges); NetworkX iterates neighbours, so it counts parallel
  copies once ([½, ½, ½, ½]). Grafluent's paths (`Path`) carry edges, `degree(of:)` counts copies,
  and the Brandes loop over rows gives this with no extra work. Self-loops lie on no shortest path
  and are dropped when rows are copied (CE-109).
* **Weights:** any `W: Comparable & AdditiveArithmetic` (only sums and comparisons are needed, so
  `Int` weights are exact). **Precondition: every weight > 0 and not NaN**, checked as the weights
  are read (once per edge, in position order, before any search), loops included (CE-115 – CE-117).
  Brandes' algorithm assumes positive weights: with a zero-weight edge the shortest-path DAG can
  have cycles. igraph refuses too ("Edge weights must be positive for betweenness"); NetworkX
  accepts zeros and miscounts (CE-117: a zero-weight loop gives vertex 1 the unnormalized value 3
  instead of 1; on `0-1, 1-2, 2-3` with weights 1, 0, 1 it gives 3 to vertices 1 and 2 instead of 2).
* **Ties by exact equality** of path sums (NetworkX, Boost). With floating-point weights two paths
  of mathematically equal length may not tie: 0.1 + 0.2 > 0.15 + 0.15 (CE-114). igraph compares
  with a relative epsilon and splits that pair. Exact equality is the only rule that is the same
  for every `W`, and integer weights give exact ties. Documented, with the advice to use integer
  weights when ties matter.
* Path counts σ are `Double` (as NetworkX and igraph): they grow as 2^{n/2} on ladder-like graphs
  and would overflow `Int`; above 2⁵³ they are rounded, which the ratios σ_v/σ_w tolerate.

### Eigenvector centrality

The principal eigenvector of Aᵀ (in-arcs for a directed graph: a vertex is central when central
vertices point to it, NetworkX's "left" eigenvector; igraph and JGraphT the same), with A the
graph's adjacency matrix **as its rows list it**: A_vw = Σ weights of the slots v → w, so parallel
copies add (CE-140, CE-148) and an undirected self-loop contributes 2 to A_vv (CE-139), consistent
with `degree(of:)`, `graph.directed`, and igraph. NetworkX counts an undirected loop once and its
`eigenvector_centrality` refuses multigraphs (while `eigenvector_centrality_numpy` sums parallel
copies).

Computed as NetworkX does: x₀ uniform (1/n), x_{k+1} = (Aᵀ + I)x_k / ‖(Aᵀ + I)x_k‖₂. The shift by
I makes bipartite graphs converge (CE-131, CE-133: plain power iteration oscillates there) without
changing eigenvectors. Result normalized to Euclidean norm 1 (NetworkX; igraph scales the greatest
to 1). Disconnected graphs: the limit is the Perron vector of the components with the greatest
spectral radius, the rest 0 (CE-137); with several such components, their mix from the uniform
start (CE-138). NetworkX's numpy variant raises `AmbiguousSolution` there; the iteration is
defined, so it is returned. A DAG (nilpotent A) has no positive eigenvector: the iterates creep
polynomially and the result is nil (CE-142); igraph special-cases DAGs to 1 on sinks. The empty
graph gives an empty result; an edgeless one is uniform (CE-019).

### Katz

x = α Aᵀx + β1 (in-arcs; the same A as eigenvector), computed as NetworkX does: x₀ = 0,
x_{k+1} = αAᵀx_k + β, then divided by ‖x‖₂ when `normalized` (default; CE-164 without). It
converges exactly when α < 1/ρ(A); otherwise the iterates grow and the result is nil (CE-163, CE-171).
No precondition on α beyond finite (a check would need ρ(A), an eigen-solve). Defaults α = 0.1,
β = 1 (NetworkX). NetworkX refuses multigraphs; ours counts copies (CE-169).

### PageRank

x = d(Pᵀx + (dangling mass)·p) + (1 − d)p with P the row-normalized weight matrix (each arc's weight
over its source's out-weight), d the damping factor (0.85), p the personalization normalized to sum
1 (uniform by default). A dangling vertex (no out-arcs, or out-weight 0: CE-185) sends its mass
along p, as NetworkX does by default. x₀ uniform; scores sum to 1. On `Graph` each edge is two arcs
and a self-loop two loop arcs (`graph.directed`'s reading; igraph agrees, CE-182; NetworkX's
`to_directed` makes one loop arc). Parallel arcs add (NetworkX MultiDiGraph and igraph agree,
CE-183). Preconditions: 0 ≤ d ≤ 1; personalization values finite and ≥ 0 with a positive sum
(CE-187, CE-188); weights finite and ≥ 0 (CE-191). The personalization closure is called once per
vertex, in `vertices` order, before iterating; there are two overloads (with and without), not an
optional closure, so the closure stays non-escaping.

### HITS

Authorities a = Aᵀh, hubs h = Aa (Kleinberg), from h₀ uniform, each rescaled to greatest 1 every
step (NetworkX's reference iteration `_hits_python`); the stop rule is on h; at the end both are
divided by their sums (NetworkX `normalized=True`; igraph scales the greatest to 1). NetworkX 3.7
computes HITS with ARPACK's `svds`, which agrees wherever σ₁ is simple (checked by `ref.py`); where
it is not, the iteration's limit from the uniform start is returned (CE-195, CE-199). **An edgeless
graph gives uniform scores** (CE-017, CE-023): every vector is a singular vector of the zero
matrix; NetworkX returns NaN, igraph all-equal. `DirectedGraph` only (Scope).

### Convergence policy (eigenvector, Katz, PageRank, HITS)

* **Stop rule** (one rule for all four): stop after the first step k with
  ‖x_k − x_{k−1}‖₁ < n · `tolerance` (x is h for HITS). This is NetworkX's rule for eigenvector,
  Katz and PageRank; NetworkX's HITS uses ‖·‖₁ < tol without the n, which makes our HITS stop no
  later than n× looser. The defaults are NetworkX's (1e-6, 1e-6, 1e-6, 1e-8; 100, 1000, 100, 100
  iterations), so results match NetworkX's within the catalog's Tol (1e-4; CE-146 with
  `tolerance: 1e-10`: 1e-8).
* **Non-convergence returns nil.** The result type is `CentralityScores?` / `HubAndAuthorityScores?`.
  Reasons: (1) it happens on valid input (a DAG for eigenvector, α ≥ 1/ρ for Katz, too few
  iterations for any of them: CE-142, CE-145, CE-163, CE-171, CE-186, CE-206), so a precondition
  would crash ordinary programs, and α ≥ 1/ρ cannot be checked up front without an eigen-solve;
  (2) NetworkX raises `PowerIterationFailedConvergence` on exactly these inputs (`ref.py` checks
  that NetworkX raises on every nil row it can run), and Grafluent maps such failures to an
  optional, not a throw (README: a thrown error must be `Sendable`); (3) a result with a
  `converged` flag would be ignored by callers and gives scores with no guarantee; a caller who
  wants a result anyway raises `maxIterations` or `tolerance`.
* **Preconditions:** `tolerance > 0` and finite, `maxIterations ≥ 1`, α and β finite, weights
  finite and ≥ 0 (CE-149), 0 ≤ dampingFactor ≤ 1.
* The empty graph returns an empty (non-nil) result without iterating (CE-005 – CE-008).

### Numerical policy

* **`Double` everywhere**, not a generic `Score: BinaryFloatingPoint`: every library returns
  doubles; HITS's default tolerance (1e-8) is below `Float`'s resolution (about 6e-8 relative),
  and the others leave `Float` one or two digits of headroom; a generic parameter would add a type argument to every result for no
  established use. Weights of the iterative measures are any `BinaryFloatingPoint`, converted to
  `Double` once per edge.
* **Deterministic summation order**, so a result is bitwise reproducible across runs and across
  representations with the same row order: sources in index order for closeness, harmonic and
  betweenness; each iteration sums contributions into vertex w in increasing source index, then row
  order; norms and L1 differences in index order. No swift-numerics dependency: `squareRoot()` is
  all the iterations need (no `hypot`: x is normalized every step, so ‖x‖² cannot overflow).
* Tests compare with tolerances (Tol column), never bit for bit: Expected is rounded to 12 digits
  and, for the iterative measures, is the limit, not the iterate.

## Complexity

n vertices, m edges, k iterations.

| Entry point | Time | Extra memory |
|---|---|---|
| `degreeCentrality()`, `outDegreeCentrality()` | O(n) with O(1) `degree(of:)`, else O(n + m) | n |
| `inDegreeCentrality()`, directed `degreeCentrality()` | O(n + m): one pass over the rows | n |
| `closenessCentrality()`, `harmonicCentrality()` | O(n(n + m)); weighted O(n · m log n) (Dijkstra, 4-ary indexed heap) | O(n + m) |
| `closenessCentrality(of:)`, `harmonicCentrality(of:)` | one search: O(n + m), weighted O(m log n); directed also O(n + m) to transpose the rows | O(n + m) |
| `betweennessCentrality()` | O(nm) (Brandes); weighted O(n · m log n) | O(n + m) |
| `eigenvectorCentrality`, `katzCentrality`, `pageRank`, `hits` | O(n + m) to copy the rows, then O(n + m) per iteration (HITS two passes) | O(n + m) |

Iterations to converge: geometric in |λ₂/λ₁| (eigenvector, with the shift (1 + λ₂)/(1 + λ₁)), αρ(A)
(Katz), d (PageRank: the L1 step shrinks by d each iteration from at most 2, so at most
⌈log(n · tol / 2)/log d⌉ iterations: 47 for n = 1000 at the defaults), (σ₂/σ₁)² (HITS).

## Implementation notes (index space)

* **Rows.** As Distances: `_VertexIdentifiers` for numbering; `_withSuccessorIndexRows` when the
  representation lends flat rows (compressed sparse row: borrowed, nothing copied); otherwise copy
  **once** into a private CSR (offsets, targets, edge numbers; for weighted runs the weight per
  slot), self-loops dropped for the searches and kept (twice when undirected) for the matrix
  methods. Undirected graphs via `_runOnUndirectedRows`. Distances' `_DistanceRows` /
  `_CopyDistanceRows` are internal to Distances; **proposed:** move them to GraphProtocols as
  `package` (as `_IncidenceRowSource` was moved for Cycles) so Centrality, Distances and later
  CommunityDetection share one copy routine.
* **Incoming distances** (directed closeness, harmonic): transpose the private CSR once by
  counting sort over sources in index order (O(n + m)); no `BidirectionalDirectedGraph`
  constraint. Undirected rows are their own transpose.
* **One search, reused** (closeness, harmonic): a queue `[Int]` of capacity n and `dist: [Int]`
  initialised to −1, reset only for the vertices reached; r and S accumulate as vertices are
  dequeued. Weighted: one `IndexedPriorityQueue<W>(indexBound: n)`, `dist: [W]` with a round stamp.
* **Brandes with flat arrays.** Per source: `sigma: [Double]`, `dist: [Int]` (or `[W]` with a
  stamp), `delta: [Double]`, and `order: [Int]` — the BFS queue itself, which lists vertices in
  non-decreasing distance, read backwards as Brandes' stack (weighted: the settle order of the
  heap). **No predecessor lists:** accumulate on the successor side, for v in reverse order and each
  slot v → w with dist[w] == dist[v] + 1 (weighted: dist[v] + w(slot), the same exact test as the
  forward pass), δ[v] += σ[v]/σ[w] · (1 + δ[w]). This reads each row twice per source but
  allocates nothing per source (Boost and NetworkX build predecessor lists: m appends per source)
  and works on `DirectedGraph` without in-rows. Benchmark it against a predecessor-slot array
  (Bader–Madduri) before committing; the API does not depend on the choice. All arrays are
  allocated once and only reached entries are reset. With σ[w] > 0 for every reached w, there is no
  division by zero. Equal-distance vertices may leave the heap in any order (IndexedPriorityQueue's
  ties are unspecified), which does not change any sum: δ[v] reads only strictly farther vertices.
  Rescaling is one multiplication per vertex at the end.
* **Power iteration on CSR.** Two `[Double]` vectors, swapped each step; no allocation per
  iteration. y[w] = Σ_{v → w} x[v]·a_vw is computed by scattering over out-rows in index order,
  which sums into each y[w] in increasing v, the same order as a gather over a transposed CSR with
  rows sorted by source; so no transpose is built. For an undirected graph the rows are symmetric.
  The L1 difference and the squared norm are accumulated in the same pass that writes y. PageRank
  precomputes 1/out-weight per vertex (0 for dangling) and the dangling list; HITS runs Aᵀ then A
  over the same rows (scatter then gather).
* **No recursion; `@inlinable`; `some` generics** as the rest of the library.
* **Dependencies.** Centrality needs GraphProtocols and PriorityQueueModule, not ShortestPaths or
  Traversal: its searches are internal loops (ShortestPaths' public API allocates a
  `ShortestPathTree` per run, and Traversal's events cost 2× a hand-written loop). **Proposed edit
  to `scripts/modules.py`:** `Centrality` depends on GraphProtocols, PriorityQueueModule. Tests
  import ShortestPaths to cross-check closeness against `shortestPaths(from:)` sums.
* **Tests** (public API only): every catalog row; for each case also `closenessCentrality(of: v)`
  equals `closenessCentrality().score(of: v)` (and harmonic), `g.directed` gives the documented
  relation (equal, or twice for unnormalized betweenness and degree), and `score(of:)` agrees with
  `scores` and `score(ofIndex:)`. Property tests: betweenness against the definition on small random
  multigraphs; PageRank sums to 1; eigenvector has norm 1; Katz with α → 0 tends to uniform.
  Benchmarks: Brandes against BGL's `brandes_betweenness_centrality` and NetworkX; PageRank against
  igraph's PRPACK.

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Directed closeness / harmonic | NetworkX: incoming distances (source of a path scores 0); igraph python default `mode="all"` ([⅔, 1, ⅔] on a dipath; `"in"` gives NaN at the source); JGraphT and Boost: outgoing. Ours: NetworkX | CE-054, CE-072 |
| Closeness normalization | NetworkX `wf_improved=True` by default; igraph `normalized=True` equals NetworkX's `wf_improved=False` | CE-051, CE-052 |
| Harmonic normalization | NetworkX: raw sum; igraph: ÷ (n − 1) by default ([0.75, 1, 0.75] mode all) | CE-070 |
| Betweenness on multigraphs | Boost and igraph count parallel edges as distinct paths ([⅔, ⅔, ⅓, ⅓]); NetworkX counts neighbours once ([½, ½, ½, ½]). Ours: edge sequences | CE-108 |
| Betweenness with zero weights | NetworkX accepts and miscounts (a zero-weight loop triples vertex 1's value, CE-117's graph: 3.0; a zero edge gives 3 instead of 2); igraph refuses. Ours: precondition > 0 | CE-115, CE-117 |
| Betweenness floating ties | NetworkX and Boost: exact equality ([1, 0, 0, 1]); igraph: epsilon ([1, ½, 0, ½]) | CE-114 |
| Undirected self-loop in A | NetworkX counts it once (eigenvector [0.408, 0.816, 0.408]; PageRank [0.2128, 0.5745, 0.2128]); igraph twice ([0.366, 1, 0.366] scaled; PageRank [0.1842, 0.6316, 0.1842]); ours twice, as `degree(of:)` | CE-139, CE-182 |
| NetworkX internal | `eigenvector_centrality` and `katz_centrality` refuse multigraphs, `eigenvector_centrality_numpy` and `pagerank` sum parallel copies | CE-140, CE-169, CE-183 |
| Eigenvector on a DAG | NetworkX raises `PowerIterationFailedConvergence`; igraph returns 1 on sinks, 0 elsewhere (with a warning). Ours: nil | CE-142 |
| Eigenvector, disconnected | NetworkX iteration: 4.5e-6 on the smaller component; `eigenvector_centrality_numpy`: raises `AmbiguousSolution`. Ours: the limit (0) | CE-137 |
| Scaling | NetworkX: Euclidean norm 1 (eigenvector, Katz), sum 1 (PageRank, HITS); igraph: greatest = 1 (eigenvector, hub/authority) | CE-130, CE-197 |
| Empty graph | NetworkX `eigenvector_centrality` raises `NetworkXPointlessConcept`, the others return `{}`. Ours: empty for all | CE-001 – CE-008 |
| Edgeless HITS | NetworkX (svds): NaN; igraph: all equal. Ours: uniform 1/n | CE-023 |
| HITS stop rule | NetworkX's `_hits_python` uses ‖Δh‖₁ < tol, its other methods n · tol; NetworkX 3.7's `hits` itself calls ARPACK `svds`. Ours: n · tol for all four | CE-195 – CE-206 |
| One vertex | NetworkX degree centrality 1 (ours too); closeness, betweenness 0 | CE-009 – CE-013 |

## README edits proposed

* `Centrality` row: "Degree (in, out), closeness (Wasserman–Faust), harmonic, Brandes betweenness,
  eigenvector, Katz, PageRank (personalized), HITS, unweighted and weighted (**planned**)"; result
  types `CentralityScores`, `HubAndAuthorityScores`. Edge betweenness: listed under phase 2 with
  Girvan–Newman.
* Package layout: Centrality depends on GraphProtocols, PriorityQueueModule (not ShortestPaths,
  Traversal); move the private distance rows to GraphProtocols as `package`.
* Terminology rows above.
