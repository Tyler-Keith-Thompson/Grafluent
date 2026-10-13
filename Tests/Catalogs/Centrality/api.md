# Centrality: API

Vertex centrality on `Graph` and `DirectedGraph`: degree (and in- and out-degree), closeness,
harmonic, Brandes betweenness, eigenvector, Katz, PageRank, and HITS (on `DirectedGraph`),
unweighted and weighted. Every measure returns one value type, `CentralityScores`: a dense
`Double` per vertex with `score(of:)` / `score(ofIndex:)`. HITS returns two of them. `cases.md`
(CE-001 – CE-206, 162 cases) pins the values. `ref.py` recomputes every one with the model below
and checks it against the definitions (Floyd–Warshall; Σ σ_sv·σ_vt/σ_st over edge sequences),
dense numpy/scipy solves, and NetworkX 3.7 wherever NetworkX shares the semantics
(`uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 ref.py`).

## Scope

| Entry point | On | Purpose |
|---|---|---|
| `degreeCentrality()` | both | Degree over n − 1 (directed: in + out). O(n + m) |
| `inDegreeCentrality()`, `outDegreeCentrality()` | `DirectedGraph` | In-degrees take one pass over every row, so no `BidirectionalDirectedGraph` constraint is needed |
| `closenessCentrality(wfImproved:)`, `closenessCentrality(of:wfImproved:)`, each also `(weight:)` | both | One vertex costs one search, not n |
| `harmonicCentrality()`, `harmonicCentrality(of:)`, each also `(weight:)` | both | Closeness for disconnected graphs without a correction factor (Marchiori–Latora 2000, Boldi–Vigna 2014) |
| `betweennessCentrality(normalized:endpoints:)`, also `(weight:normalized:endpoints:)` | both | Brandes 2001 |
| `eigenvectorCentrality(tolerance:maxIterations:)`, also `(weight:…)` | both | Power iteration on A + I |
| `katzCentrality(alpha:beta:normalized:tolerance:maxIterations:)`, also `(weight:…)` | both | Katz 1953 |
| `pageRank(dampingFactor:tolerance:maxIterations:)`, `pageRank(dampingFactor:personalization:tolerance:maxIterations:)`, each also `(weight:…)` | both | Personalization serves recommendation and local ranking |
| `hits(tolerance:maxIterations:)`, also `(weight:…)` → `HubAndAuthorityScores` | `DirectedGraph` | Kleinberg 1999 |

Related computations that are not entry points:

* Outgoing closeness and harmonic centrality: run on the reversed graph (for example
  `CompressedSparseRow.transposed()`).
* HITS on an undirected graph: `graph.directedView.hits()`.
* Weighted degree ("strength"): `vertices.map { incidentEdges(of: $0).reduce(0) { $0 + w($1) } }`.
* Eccentricity centrality and the centroid are in `Distances`; current-flow and spectral measures
  are in `SpectralGraphTheory`.
* Ranking: `scores.indices.sorted { scores[$0] > scores[$1] }`.

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

    /// Throws NoConvergence when the iteration has not converged after `maxIterations` steps.
    func eigenvectorCentrality(tolerance: Double = 1e-6, maxIterations: Int = 100) throws(NoConvergence) -> CentralityScores<DirectedView<Self>>
    func eigenvectorCentrality<W: BinaryFloatingPoint>(
        weight: (Edges.Index) -> W, tolerance: Double = 1e-6, maxIterations: Int = 100) throws(NoConvergence) -> CentralityScores<DirectedView<Self>>

    func katzCentrality(alpha: Double = 0.1, beta: Double = 1, normalized: Bool = true,
                        tolerance: Double = 1e-6, maxIterations: Int = 1000) throws(NoConvergence) -> CentralityScores<DirectedView<Self>>
    func katzCentrality<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, alpha: Double = 0.1, beta: Double = 1,
                        normalized: Bool = true, tolerance: Double = 1e-6, maxIterations: Int = 1000) throws(NoConvergence) -> CentralityScores<DirectedView<Self>>

    /// Each edge is two arcs (`graph.directedView`), a self-loop two loop arcs.
    func pageRank(dampingFactor: Double = 0.85, tolerance: Double = 1e-6, maxIterations: Int = 100) throws(NoConvergence) -> CentralityScores<DirectedView<Self>>
    func pageRank(dampingFactor: Double = 0.85, personalization: (Vertex) -> Double,
                  tolerance: Double = 1e-6, maxIterations: Int = 100) throws(NoConvergence) -> CentralityScores<DirectedView<Self>>
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
    func hits(tolerance: Double = 1e-8, maxIterations: Int = 100) throws(NoConvergence) -> HubAndAuthorityScores<Self>
    func hits<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, tolerance: Double = 1e-8,
                                      maxIterations: Int = 100) throws(NoConvergence) -> HubAndAuthorityScores<Self>
}

/// A score per vertex, stored densely by vertex index.
@frozen public struct CentralityScores<G: DirectedGraph> {
    /// Precondition: `vertex` is a vertex.
    public func score(of vertex: G.Vertex) -> Double
    /// Throws `VertexNotFound` for a non-vertex instead.
    public func score(checked vertex: G.Vertex) throws(VertexNotFound) -> Double
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

Every measure returns the same shape, a `Double` per vertex with no derived members, so they
share `CentralityScores`. HITS has two vectors, so `HubAndAuthorityScores` holds two of them.

## Semantics

### Degree

degree(of: v)/(n − 1), so a self-loop counts 2 and each parallel copy counts (CE-031, CE-032):
the value is the graph's `degree(of:)` scaled, and can exceed 1 on a multigraph.
Directed: `degreeCentrality()` is (in + out)/(n − 1), and a directed loop is one in-arc and one
out-arc (CE-036). **One vertex scores 1** (CE-009, CE-041), the
empty graph gives an empty result. `g.directedView.degreeCentrality()` is twice
`g.degreeCentrality()` (CE-040).

### Closeness and harmonic

Distances are shortest-path lengths in edges, or weighted sums. **Directed: incoming distances
d(v, u)**, how far u is from the vertices that reach it (CE-054, CE-072), so a sink of many short
paths is central. For outgoing distances, run on the reversed graph.

* **Closeness** (Bavelas, Sabidussi): with r the number of vertices that reach u (u included) and
  S the sum of their distances, C(u) = (r − 1)/S · (r − 1)/(n − 1) when `wfImproved` (the default,
  Wasserman–Faust's correction), (r − 1)/S without it.
  **0 when S = 0** (nothing else reaches u, or n = 1: CE-010, CE-053, CE-066). With
  `wfImproved: false` each component is scored on its own, so a K₂ component scores 1 like the
  middle of a P₃ (CE-052); the correction weighs by the share of the graph reached (CE-051).
* **Harmonic** (Marchiori–Latora, Boldi–Vigna): H(u) = Σ 1/d(v, u) over v with 0 < d < ∞, **not
  normalized**. Unreachable
  vertices add 0, so no correction is needed (CE-071). A distance of 0 to another vertex (zero
  weights) is skipped (CE-076), not counted as 1/0.
* **Weights:** as Distances: called once per edge in position order before any search; precondition
  ≥ 0 and not NaN (CE-063, CE-064, CE-080). Zero weights are allowed (CE-062). Distances are summed
  in `W` along paths (Dijkstra) and converted to `Double` per vertex as they are added to S, so
  integer weights are exact up to 2⁵³. Two overloads, `BinaryInteger` and `BinaryFloatingPoint`,
  because a generic `Comparable & AdditiveArithmetic` weight cannot be divided or converted.
* Self-loops and parallel copies change no distance (CE-067).

### Betweenness

B(v) = Σ σ_st(v)/σ_st over ordered pairs s ≠ v ≠ t with t reachable from s, σ_st the number of
shortest s–t paths and σ_st(v) those through v (Freeman 1977; Brandes 2001), then rescaled:

| | normalized (default) | not normalized |
|---|---|---|
| undirected | ÷ (n − 1)(n − 2) on the ordered sum, i.e. per unordered pair ÷ (n − 1)(n − 2)/2 | ÷ 2 (unordered pairs) |
| directed | ÷ (n − 1)(n − 2) | as is |
| with `endpoints: true` | each reachable pair also credits s and t (+1 each), and n(n − 1) replaces (n − 1)(n − 2) | |

No scaling when the divisor would be 0 (n ≤ 2, or n < 2 with endpoints; CE-013, CE-025, CE-026).
`g.directedView` gives the same normalized values and twice the unnormalized ones (CE-106, CE-107).

* **Paths are edge sequences.** In a multigraph each parallel copy is a distinct shortest path
  (CE-108: 0 → 2 has three shortest paths, two through vertex 1, so B(1) = ⅔), consistent with
  `Path` carrying edges and `degree(of:)` counting copies. Self-loops lie on no shortest path
  and are dropped when rows are copied (CE-109).
* **Weights:** any `W: Comparable & AdditiveArithmetic` (only sums and comparisons are needed, so
  `Int` weights are exact). **Precondition: every weight > 0 and not NaN**, checked as the weights
  are read (once per edge, in position order, before any search), loops included (CE-115 – CE-117).
  Brandes' algorithm assumes positive weights: with a zero-weight edge the shortest-path DAG can
  have cycles.
* **Ties by exact equality** of path sums. With floating-point weights two paths of
  mathematically equal length may not tie: 0.1 + 0.2 > 0.15 + 0.15 (CE-114). Exact equality is
  the same rule for every `W`; use integer weights when ties matter.
* Path counts σ are `Double`: they grow as 2^{n/2} on ladder-like graphs
  and would overflow `Int`; above 2⁵³ they are rounded, which the ratios σ_v/σ_w tolerate.

### Eigenvector centrality

The principal eigenvector of Aᵀ (in-arcs for a directed graph: a vertex is central when central
vertices point to it, the "left" eigenvector), with A the
graph's adjacency matrix **as its rows list it**: A_vw = Σ weights of the slots v → w, so parallel
copies add (CE-140, CE-148) and an undirected self-loop contributes 2 to A_vv (CE-139), consistent
with `degree(of:)` and `graph.directedView`.

Computed by power iteration: x₀ uniform (1/n), x_{k+1} = (Aᵀ + I)x_k / ‖(Aᵀ + I)x_k‖₂. The shift by
I makes bipartite graphs converge (CE-131, CE-133: plain power iteration oscillates there) without
changing eigenvectors. Result normalized to Euclidean norm 1. Disconnected graphs: the limit is the
Perron vector of the components with the greatest spectral radius, the rest 0 (CE-137); with several
such components, their mix from the uniform start (CE-138). A DAG (nilpotent A) has no positive
eigenvector: the iterates creep polynomially and the call throws `NoConvergence` (CE-142). The empty
graph gives an empty result; an edgeless one is uniform (CE-019).

### Katz

x = α Aᵀx + β1 (in-arcs; the same A as eigenvector), computed by iteration: x₀ = 0,
x_{k+1} = αAᵀx_k + β, then divided by ‖x‖₂ when `normalized` (default; CE-164 without). It
converges exactly when α < 1/ρ(A); otherwise the iterates grow and the call throws `NoConvergence` (CE-163, CE-171). No
precondition on α beyond finite (a check would need ρ(A), an eigen-solve). Defaults α = 0.1, β = 1.
Parallel copies add (CE-169).

### PageRank

x = d(Pᵀx + (dangling mass)·p) + (1 − d)p with P the row-normalized weight matrix (each arc's weight
over its source's out-weight), d the damping factor (0.85), p the personalization normalized to sum
1 (uniform by default). A dangling vertex (no out-arcs, or out-weight 0: CE-185) sends its mass
along p. x₀ uniform; scores sum to 1. On `Graph` each edge is two arcs and a self-loop two loop arcs
(`graph.directedView`'s reading, CE-182). Parallel arcs add (CE-183). Preconditions: 0 ≤ d ≤ 1;
personalization values finite and ≥ 0 with a positive sum (CE-187, CE-188); weights finite and ≥ 0
(CE-191). The personalization closure is called once per vertex, in `vertices` order, before
iterating; there are two overloads (with and without), not an optional closure, so the closure stays
non-escaping.

### HITS

Authorities a = Aᵀh, hubs h = Aa (Kleinberg), from h₀ uniform, each rescaled to greatest 1 every
step; the stop rule is on h; at the end both are divided by their sums. Where σ₁ is not simple,
the iteration's limit from the uniform start is returned (CE-195, CE-199). **An edgeless
graph gives uniform scores** (CE-017, CE-023): every vector is a singular vector of the zero
matrix. `DirectedGraph` only; on an undirected graph use `graph.directedView.hits()`, whose hubs
and authorities equal the eigenvector centrality rescaled to sum 1 (CE-204, CE-205).

### Convergence policy (eigenvector, Katz, PageRank, HITS)

* **Stop rule** (one rule for all four): stop after the first step k with ‖x_k − x_{k−1}‖₁ < n ·
  `tolerance` (x is h for HITS). The defaults are 1e-6, 1e-6, 1e-6, 1e-8 and 100, 1000, 100, 100
  iterations (eigenvector, Katz, PageRank, HITS).
* **Non-convergence throws `NoConvergence`.** The methods are `throws(NoConvergence)` and
  return `CentralityScores` / `HubAndAuthorityScores`. The error (in `GraphProtocols`, shared
  with SpectralGraphTheory's eigensolvers) carries `iterations` (`maxIterations`) and `residual`,
  the last step's L1 change over n, on `tolerance`'s scale (infinite or NaN once Katz
  overflows). It happens on valid input (a DAG for eigenvector, α ≥ 1/ρ for Katz, too few
  iterations for any of them: CE-142, CE-145, CE-163, CE-171, CE-186, CE-206). Raise
  `maxIterations` or `tolerance` to get a result; `try?` gives an optional. `ref.py` checks that
  NetworkX also fails to converge on every `NoConvergence` row it can run.
* **Preconditions:** `tolerance > 0` and finite, `maxIterations ≥ 1`, α and β finite, weights
  finite and ≥ 0 (CE-149), 0 ≤ dampingFactor ≤ 1.
* The empty graph returns an empty result without iterating or throwing (CE-005 – CE-008).

### Numerical policy

* **`Double` everywhere.** HITS's default tolerance (1e-8) is below `Float`'s resolution. Weights of
  the iterative measures are any `BinaryFloatingPoint`, converted to `Double` once per edge.
* **Deterministic summation order**, so a result is bitwise reproducible across runs and across
  representations with the same row order: sources in index order for closeness, harmonic and
  betweenness; each iteration sums contributions into vertex w in increasing source index, then row
  order; norms and L1 differences in index order. x is normalized every step, so ‖x‖² cannot
  overflow.
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
  methods. Undirected graphs via `_runOnUndirectedRows`.
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
  allocates nothing per source and works on `DirectedGraph` without in-rows. All arrays are
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
