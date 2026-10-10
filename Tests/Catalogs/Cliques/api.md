# Cliques: proposed API (phase 1)

Maximal-clique enumeration (Bron–Kerbosch), the maximum clique and clique number, the core
decomposition (core numbers, degeneracy, degeneracy ordering, k-cores and k-shells), and triangle
counts with the clustering coefficients built on them (local, transitivity, average). All on
`Graph`. Directed graphs reach them through `digraph.undirected`. `cases.md` (CQ-001 – CQ-633,
276 cases) pins the values. `ref.py` recomputes every one with the model below and checks it
against brute force, NetworkX 3.7 and Latapy's compact-forward count; it also runs 280 random
graphs, loops and parallel edges included (`uv run --quiet --no-project --with networkx==3.7
python3 ref.py`, about 80 s). `igprobe*.py` hold the python-igraph 1.0.0 values quoted below
(`uv run --no-project --with igraph python3 igprobe.py`).

## Scope

**In, phase 1**

| Entry point | Why |
|---|---|
| `maximalCliques()` → `MaximalCliques<Self>`, a lazy `Sequence` of `[Vertex]` | This is the README row (Bron–Kerbosch). The output can be exponential (3^{n/3} cliques on Moon–Moser graphs, CQ-621), so it is lazy, like `simpleCycles()`. A caller can stop early, and the memory stays O(n + m) whatever the count. NetworkX `find_cliques` is a generator. JGraphT's finders are `Iterable`s, but they store every clique first. |
| `maximumClique()` → `[Vertex]` | Every library has a largest clique: igraph `largest_cliques`, JGraphT `maximumIterator`, NetworkX `max_weight_clique(weight=None)`. Branch and bound with a colouring bound and core pruning is much faster than enumerating every maximal clique and keeping the largest. |
| `cliqueNumber()` → `Int` | igraph `clique_number`, Boost `bron_kerbosch_clique_number`, and NetworkX ≤ 2.x `graph_clique_number`. It can stop as soon as it reaches the degeneracy + 1 upper bound, and it needs no tie rule, so it can be cheaper than `maximumClique()`. |
| `coreNumbers()` → `CoreNumbers<Self>` | This is the README row (k-cores). Batagelj–Zaversnik runs in O(n + m). One value holds the core numbers, the degeneracy, the degeneracy ordering, and the k-cores and k-shells, so none of them is computed twice. This is how `eccentricities()` holds the radius and diameter. NetworkX `core_number`, igraph `coreness`, JGraphT `Coreness`, Boost `core_numbers`. |
| `clusteringCoefficients()` → `ClusteringCoefficients<Self>` | This is the README row (triangle counting, clustering coefficient). One O(m^{3/2}) triangle pass gives each vertex's triangle count and local clustering, plus the transitivity and the average clustering. JGraphT's `ClusteringCoefficient` is the same kind of object, holding local, global and average values. |
| `triangleCount()`, `transitivity()`, `averageClustering()` | One-shot scalars, because every library offers them as plain functions: NetworkX `transitivity` and `average_clustering`, igraph `transitivity_undirected`, JGraphT `getNumberOfTriangles`. `triangleCount()` also skips the per-vertex arrays. Each must equal the same member of `clusteringCoefficients()`. |
| `triangleCount(of:)`, `clusteringCoefficient(of:)` | One vertex costs O(Σ_{w ∈ N(v)} d(w)), not a whole-graph pass. NetworkX `triangles(G, v)`, `clustering(G, v)`; Boost `clustering_coefficient(g, v)`. |

**Out, and where it goes**

| Not in phase 1 | Reason |
|---|---|
| Cliques, cores or clustering on `DirectedGraph` | The libraries disagree, and no two agree. NetworkX `find_cliques` and `triangles` raise on digraphs. igraph ignores directions with a warning. Boost's `bron_kerbosch_all_cliques` needs arcs in both directions. NetworkX `core_number` uses in-degree + out-degree, so a reciprocal pair counts twice. igraph `coreness(mode=)` offers all, in or out. Boost `core_numbers` uses in-degree. NetworkX `clustering` uses Fagiolo's directed triangles. `digraph.undirected.op()` already gives the "directions ignored" reading, which is igraph's, because the simple graph merges opposite arcs (CQ-501 – CQ-515). Phase 2: D-cores (Giatsidis–Thilikos–Vazirgiannis 2011, (k, l) in/out cores, cited by NetworkX's core.py) on `BidirectionalDirectedGraph`, and Fagiolo clustering if it is asked for. |
| A `Clique` result type (README) | A clique is a vertex set with no structure beyond its members. Unlike `Cycle`, it carries no edges: with parallel edges, the edges of a clique are not even determined. `[Vertex]` in `vertices` order is what `center()` and `articulationPoints()` return, and equal cliques give equal arrays. NetworkX and igraph return lists and JGraphT `Set<V>`. **Proposed README edit:** drop `Clique`. |
| `minSize:` / `maxSize:` on `maximalCliques()` (igraph `min`/`max`, Boost `min`) | `.lazy.filter { $0.count >= k }` gives the same sequence. The only gain is pruning `|R| + |P| < k`. That is a phase 2 overload, added only if a benchmark shows a win. |
| All cliques, not only maximal ones (NetworkX `enumerate_all_cliques`, igraph `cliques`) | Every clique is a subset of a maximal one. The output is far larger (4^8 = 65 536 cliques on `moon(8)` against 6 561 maximal ones), and its uses (motif counts) belong with a motif or census module. |
| Weighted maximum clique (NetworkX `max_weight_clique`) | Only NetworkX has it. Phase 2, with `weight: (Vertex) -> W`, where the weight is on vertices, not edges. |
| Per-vertex clique number and clique counts (NetworkX `node_clique_number`, `number_of_cliques`) | Only NetworkX has them, and both are one pass over `maximalCliques()`. |
| k-crust, k-corona, onion layers, k-truss (NetworkX `k_crust`, `k_corona`, `onion_layers`, `k_truss`) | NetworkX-only, or NetworkX and igraph (truss). A crust is `coreNumbers` filtered by `< k`. A corona needs neighbour counts within the core. Onion layers refine BZ and could become a member of `CoreNumbers` later. A truss is an edge decomposition (by triangles per edge), so it is a separate algorithm. Phase 2 candidates. |
| A subgraph for `kCore(_:)` | Grafluent has no subgraph type yet. `kCore(_:)` returns the vertex list, and GraphOperations' planned induced-subgraph view turns it into a graph. NetworkX returns a subgraph, and igraph `k_core` returns graphs. |
| Weighted clustering | NetworkX uses Onnela's geometric mean, normalised by the largest weight in the whole graph, so a vertex's value depends on edges far away. igraph uses Barrat's definition (`transitivity_local_undirected(weights=)`). On CQ-401's graph with weights 1, 2, 3, 4, vertex 2 gets 0.2777… from igraph and 0.1514… from NetworkX (`igprobe2.py`, `nxorder.py`). Two incompatible definitions in two libraries. Phase 2, if one is asked for. |
| `square_clustering`, `generalized_degree` | NetworkX-only. |
| Listing triangles (NetworkX 3.7 `all_triangles`, igraph `list_triangles`) | A lazy listing with a documented order (lexicographic by index) costs O(m · d_max) when the vertices are ordered by index. The O(m^{3/2}) bound needs a degree ordering, which emits triangles in a different order. Phase 2: a `triangles()` sequence in compact-forward order, each triangle in `vertices` order. |
| Weighted core numbers (Boost `weighted_core_numbers`) | Boost-only. |
| `isClique(_:)` (igraph `is_clique`) | Write it as `allSatisfy` over `contains(edge:)`. |
| Timeouts (JGraphT's finders) | The sequence is lazy, so the caller stops. |

## Summary

```swift
import GraphProtocols

extension Graph {
    /// Every maximal clique once, lazily, each in `vertices` order. The order is in
    /// "Order of maximal cliques". Self-loops and parallel copies are ignored, and an isolated
    /// vertex is a clique of one.
    func maximalCliques() -> MaximalCliques<Self>

    /// The lexicographically least largest clique, by vertex index; [] for the empty graph.
    func maximumClique() -> [Vertex]
    /// The size of a largest clique, ω(G); 0 for the empty graph.
    func cliqueNumber() -> Int

    /// The core decomposition (Batagelj–Zaversnik): O(n + m).
    func coreNumbers() -> CoreNumbers<Self>

    /// Triangles and clustering for every vertex: one pass, O(m^{3/2}).
    func clusteringCoefficients() -> ClusteringCoefficients<Self>
    func triangleCount() -> Int                          // triangles in the graph
    func transitivity() -> Double                        // 3·triangles / connected triples; 0 with none
    func averageClustering() -> Double                   // mean of the local values, zeros included; 0 when empty
    /// Precondition: `vertex` is a vertex.
    func triangleCount(of vertex: Vertex) -> Int
    func clusteringCoefficient(of vertex: Vertex) -> Double  // 2T/(d(d−1)), 0 when d < 2
}

@frozen public struct MaximalCliques<G: Graph>: Sequence {
    public typealias Element = [G.Vertex]
    public struct Iterator: IteratorProtocol { public mutating func next() -> [G.Vertex]? }
}

@frozen public struct CoreNumbers<G: Graph> {
    /// Precondition: `vertex` is a vertex.
    public func coreNumber(of vertex: G.Vertex) -> Int
    /// By vertex index (positions in `vertices` without vertex indices).  Precondition: in range.
    public func coreNumber(ofIndex index: Int) -> Int
    /// The greatest core number; 0 for the empty graph. O(1).
    public var degeneracy: Int { get }
    /// Every vertex once, each with at most `degeneracy` neighbours after it (Batagelj–Zaversnik's
    /// removal order). O(n).
    public var degeneracyOrdering: [G.Vertex] { get }
    /// The vertices of the k-core (core number ≥ k), in `vertices` order. Precondition: k ≥ 0.
    public func kCore(_ k: Int) -> [G.Vertex]
    /// The vertices of core number exactly k, in `vertices` order. Precondition: k ≥ 0.
    public func kShell(_ k: Int) -> [G.Vertex]
}

@frozen public struct ClusteringCoefficients<G: Graph> {
    public func clusteringCoefficient(of vertex: G.Vertex) -> Double
    public func clusteringCoefficient(ofIndex index: Int) -> Double
    public func triangleCount(of vertex: G.Vertex) -> Int
    public func triangleCount(ofIndex index: Int) -> Int
    public var triangleCount: Int { get }          // O(1): stored
    public var transitivity: Double { get }        // O(1): stored
    public var averageClustering: Double { get }   // O(1): stored
}

extension MaximalCliques: Sendable where G: Sendable {}
extension MaximalCliques.Iterator: Sendable where G: Sendable, G.Vertex: Sendable {}
extension CoreNumbers: Sendable where G: Sendable, G.Vertex: Sendable {}
extension ClusteringCoefficients: Sendable where G: Sendable, G.Vertex: Sendable {}
```

`CoreNumbers` and `ClusteringCoefficients` hold a copy of the graph so that `coreNumber(of:)`
can map a vertex to its index (as `Eccentricities` does), and so they are not `Equatable`.
`MaximalCliques` holds the graph and iterates it again from the start each time, as
`UndirectedSimpleCycles` does.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `maximalCliques()`, `MaximalCliques` | igraph `maximal_cliques`, JGraphT `MaximalCliqueEnumerationAlgorithm`, the literature (Tomita, Eppstein–Löffler–Strash) | NetworkX `find_cliques`, because Swift names a non-mutating query by the noun it returns. Boost `bron_kerbosch_all_cliques`, because that is the algorithm's name, and "all cliques" means something else in NetworkX and igraph (every clique, maximal or not). |
| `maximumClique()` | the standard term (maximum vs. maximal); JGraphT `maximumIterator`, NetworkX `approximation.max_clique` | igraph `largest_cliques`: the same idea, but less used in the literature. |
| `cliqueNumber()` | igraph `clique_number`, Boost `bron_kerbosch_clique_number`, NetworkX ≤ 2.x `graph_clique_number`; ω(G) | |
| `coreNumbers()`, `coreNumber(of:)`, `CoreNumbers` | NetworkX `core_number`, Boost `core_numbers`, Batagelj–Zaversnik | igraph `coreness` and JGraphT `Coreness`: equally established, but "core number" is the paper's term and the plural follows `eccentricities()`. |
| `degeneracy`, `degeneracyOrdering` | JGraphT `getDegeneracy`, `DegeneracyOrderingIterator`; Eppstein–Löffler–Strash; the README's "Orderings" bullet | "smallest-last ordering" (Matula–Beck): older and less familiar. |
| `kCore(_:)`, `kShell(_:)` | NetworkX `k_core`, `k_shell`; igraph `k_core`, `shell_index` | |
| `triangleCount()`, `triangleCount(of:)` | JGraphT `getNumberOfTriangles`, igraph R `count_triangles` | NetworkX `triangles`: as a Swift method `triangles()` reads as a listing, which NetworkX 3.7 calls `all_triangles`. |
| `clusteringCoefficient(of:)`, `clusteringCoefficients()`, `ClusteringCoefficients` | Boost `clustering_coefficient`, `all_clustering_coefficients`; JGraphT `ClusteringCoefficient`; Watts–Strogatz | NetworkX `clustering` (an adjective as a noun). igraph `transitivity_local_undirected`. |
| `transitivity()` | NetworkX `transitivity`, igraph `transitivity_undirected` | JGraphT `getGlobalClusteringCoefficient`: "global clustering coefficient" names both this and the average in the literature. |
| `averageClustering()` | NetworkX `average_clustering`; JGraphT `getAverageClusteringCoefficient`, Boost `mean_clustering_coefficient` | igraph `transitivity_avglocal_undirected`. |

**Proposed Terminology rows:** maximal clique / maximum clique (`maximalCliques()`,
`maximumClique()`) — all libraries; clique number ω (`cliqueNumber()`); core number
(`coreNumbers()`, NetworkX, Boost; igraph and JGraphT: coreness); degeneracy (JGraphT, ELS);
transitivity (NetworkX, igraph; global clustering coefficient).

## Semantics

### Simple-graph semantics

Every op reads the **simple graph underlying `g`**: u and v are adjacent when u ≠ v and at least
one edge joins them. Self-loops are ignored, and parallel copies count once. Degrees here mean
simple degrees, the number of distinct other neighbours. That is less than `degree(of:)` when
there are loops or parallel edges. Nothing traps on a multigraph.

* **Cliques** are vertex sets, so this is the only reading that makes sense. NetworkX
  `find_cliques` drops loops (`adj = {u: {v for v in G[u] if v != u}}`) and accepts a MultiGraph.
  igraph ignores loops and multi-edges (`igprobe.py`). JGraphT's degeneracy finder requires a
  simple graph. A vertex whose only edge is a loop is a clique of one (CQ-021, CQ-116).
* **Triangles and clustering**: NetworkX ("self loops are ignored"; `triangles(G)` on a MultiGraph
  counts vertex triples) and igraph (multi-edges ignored, CQ-441's graph: 1.0) agree. JGraphT's
  `getNumberOfTriangles` multiplies by edge multiplicities (CQ-441: 2 there, 1 here). Under a
  multigraph count, clustering would exceed 1, so the simple count is the coherent choice.
* **Cores**: NetworkX raises `NetworkXNotImplemented` on any self-loop and on multigraphs. igraph
  counts multi-edges, and each loop twice (`igprobe2.py`: a doubled K₂ has coreness [2, 2], K₂
  with a loop at each end [3, 3]). Here: the simple graph (CQ-328 – CQ-333, CQ-064). The reasons:
  (1) the k-core is a statement about distinct neighbours ("a (k+1)-clique lies in the k-core",
  degeneracy + 1 ≥ ω) and every bound used by `maximumClique()` and `maximalCliques()` relies on
  it; (2) one rule for the whole module; (3) never trapping on ordinary input (Distances made the
  same choice over NetworkX's raises). A caller who wants igraph's multigraph coreness has a
  different problem: degeneracy of the degree sequence, counted with multiplicity.

### Order of maximal cliques

Each clique is listed in `vertices` order (by vertex index). Equal cliques therefore give equal
arrays, so callers can compare a whole result as `Set` of arrays or sort it. The sequence order
is the one the algorithm meets them in. It is fully determined, as `simpleCycles()`'s is:

1. σ = `coreNumbers().degeneracyOrdering` (below).
2. For each v in σ order: P = the neighbours of v after it in σ, X = those before it. Run
   Bron–Kerbosch with Tomita pivoting from R = {v}. Each maximal clique is reported exactly once,
   from its first vertex in σ (Eppstein–Löffler–Strash 2010).
3. In each call, if P and X are both empty, report R. Otherwise pick the pivot u ∈ P ∪ X
   maximising |P ∩ N(u)|, with ties going to the least vertex index. Branch on each w in
   P \ N(u) **in ascending index**: recurse on (R ∪ {w}, P ∩ N(w), X ∩ N(w)), then move w from P
   to X.

So the cliques of the vertices removed first come first. In CQ-101, the pendant vertex 3 is first
in σ, so `[2, 3]` precedes `[0, 1, 2]`. NetworkX lists set order (`[[2, 0, 1], [2, 3]]`, neither
the cliques nor their members in node order). igraph lists its own order (`[(3, 2), (0, 1, 2)]`).
JGraphT returns `Set`s. Row order reaches the result only through σ (CQ-102). Tests that do not
care about order compare sets, and `ref.py` checks the sets against brute force and NetworkX for
every case.

*Alternative considered:* lexicographic order of the sorted index arrays. Plain Bron–Kerbosch
without a pivot, branching in ascending index, emits exactly that order. But it loses Tomita's
O(3^{n/3}) worst-case bound and ELS's O(d·n·3^{d/3}) bound, and pivoting breaks lexicographic
order (a later branch can contain a smaller pivot neighbour). Sorting needs every clique in
memory. The documented algorithmic order keeps laziness and the bound.

### `maximumClique()` and `cliqueNumber()`

`cliqueNumber()` is ω, the size of a largest clique: 0 for the empty graph, 1 for an edgeless
one, at most `degeneracy + 1`. `maximumClique()` is the **lexicographically least** largest
clique by index (CQ-201 – CQ-207: two disjoint triangles give the one with the least index, also
when `vertices` is reversed, CQ-203). For karate it is `[0, 1, 2, 3, 7]` over
`[0, 1, 2, 3, 13]` (CQ-211). NetworkX `max_weight_clique(weight=None)` returns the *last*
isolated vertex on an edgeless graph (`[2]` against our `[0]`, CQ-207). igraph returns all
largest cliques. The rule is independent of the algorithm, so faster branch-and-bound later does
not change answers.

### Cores

The k-core is the largest subgraph in which every vertex has at least k neighbours. `coreNumber(of:
v)` is the largest k whose k-core contains v. `degeneracy` is the largest core number, and 0 for
the empty graph (NetworkX's `max(core_number(G).values())` raises on it). `kCore(k)` lists the
vertices with core ≥ k and `kShell(k)` those with core == k, both in `vertices` order. k beyond
the degeneracy gives `[]` (NetworkX returns an empty graph), and `kCore(0)` gives every vertex.
A negative k traps (CQ-069), like `simpleCycles(maxLength:)`'s precondition.

**`degeneracyOrdering`** is the order in which Batagelj–Zaversnik removes vertices. It is
specified exactly so that it, and the clique order that depends on it, is reproducible:

1. Sort the vertices by simple degree with a counting sort that is stable in index order (`vert`,
   with `pos` and the bin starts `bin[d]`).
2. For i = 0 ..< n, v = vert[i]: for each neighbour u of v **in row order** (the simple row:
   `incidentEdges` order, first appearance, loops dropped) with deg[u] > deg[v]: swap u with the
   first vertex of its bin (`vert[bin[deg[u]]]`), advance `bin[deg[u]]`, then decrement deg[u].
3. `vert` is the ordering, and the final `deg` gives the core numbers.

Each vertex then has at most `degeneracy` (at most its own core number) neighbours after it, and
core numbers never decrease along the ordering. `ref.py` asserts both on every graph. This is
exactly NetworkX's internal `core_number` loop. NetworkX does not expose the order, but
`nxorder.py` replays its loop on its own rows and gets the same order on 500 random graphs, and
`core_number` agrees on every case. No library documents a tie rule for its ordering, so only
the ordering property is portable. The order is pinned so that results are deterministic.

### Triangles and clustering

* `triangleCount(of: v)`: the number of triangles {v, a, b} in the simple graph.
  `triangleCount()` is the number of triangles, so the per-vertex sum is 3 × that.
* `clusteringCoefficient(of: v)` = 2T(v) / (d(d − 1)), with d the **simple** degree. It is **0
  when d < 2** (NetworkX, JGraphT, Boost; igraph returns NaN unless `mode="zero"`). It is a
  `Double`, not an optional: the denominator-zero rule is the same for every ratio here, and
  NetworkX's `0` is the majority choice.
* `transitivity()` = 3 × triangles / connected triples = ΣT(v) / Σ d(d − 1)/2. It is **0 when
  there are no triangles**, including when there are no triples (NetworkX; igraph gives NaN for
  0/0, CQ-459). It is computed as one integer ratio converted once, so it is bit-identical to
  NetworkX's `sum(t) / sum(d(d−1))`. Both are the same rational, correctly rounded.
* `averageClustering()` = Σ clustering(v) / n over **every** vertex, zeros included (NetworkX's
  default `count_zeros=True`, JGraphT, igraph `mode="zero"`; Watts–Strogatz). It is **0 for the
  empty graph**, as JGraphT ("the average is 0 if the graph is empty"); NetworkX raises
  `ZeroDivisionError` and igraph returns NaN. NetworkX's `count_zeros=False` drops every zero,
  including vertices of degree ≥ 2 with no triangle, and it also raises when all are zero.
  igraph's default drops only degree < 2. Neither is offered: both are one `filter` away on the
  `ClusteringCoefficients` value. **Summation:** the local values are summed in `vertices` order
  with one running total, then divided. NetworkX on Python ≥ 3.12 sums with `sum()`, which is
  compensated (Neumaier), so the last bit differs on about half of random graphs (146 of 300 in
  `avgbits.py`). `ref.py` therefore compares the average within 1e-15 relative and pins the plain sum
  in the catalog.

## Complexity

n vertices, m edges (after merging parallel edges), d = degeneracy, Δ = maximum degree.

| Entry point | Time | Extra memory |
|---|---|---|
| `coreNumbers()` | O(n + m) | O(n + m) (simple rows, `vert`, `pos`, `bin`, `deg`) |
| `CoreNumbers` queries | `coreNumber` O(1) after `vertexIndex(of:)`; `degeneracy` O(1); `degeneracyOrdering`, `kCore`, `kShell` O(n) | |
| `maximalCliques()` | O(n + m) before the first clique; in total O(d · n · 3^{d/3}) (Eppstein–Löffler–Strash), which is optimal in the worst case (Moon–Moser) | O(n + m) plus O(d²/64) words per stack level (bitsets, below) |
| `cliqueNumber()`, `maximumClique()` | exponential in the worst case, O(n · 3^{d/3}) bounded as above; fast on sparse graphs with core pruning | O(n + m) |
| `clusteringCoefficients()`, `triangleCount()`, `transitivity()`, `averageClustering()` | O(m^{3/2}) (Latapy's compact-forward; O(m · d) with the degeneracy bound, Chiba–Nishizeki) | O(n + m) |
| `triangleCount(of:)`, `clusteringCoefficient(of:)` | O(d(v) + Σ_{w ∈ N(v)} d(w)) | O(d(v)), a set of N(v), no n-sized array |

No entry point recurses: CQ-601 – CQ-633 include 10⁵-vertex paths and stars, a 300 × 300 grid,
K₁₂₀, `moon(8)` (6 561 cliques) and a 2 000-vertex random multigraph.

## Implementation notes (index space)

* **Rows.** All entry points go through `_runOnUndirectedRows` with an `_UndirectedRowsAlgorithm`
  whose `readsEdges` is `false` (no edge numbers are ever built). The first thing each algorithm
  does is copy the rows **once** into a private simple CSR (offsets plus neighbour numbers),
  dropping self-loops and repeats with a stamp array (`stamp[w] == v` means already seen in v's
  row). It keeps first-appearance row order, because that order decides the degeneracy ordering
  and the clique order. Simple degrees are the row lengths. `UndirectedAdjacencyList`'s
  `_withIncidentIndexRows` buffers are read without hashing.
* **Shared helpers.** `_listedVertices()` and `_vertex(number:_:)` now exist in both Cycles and
  Distances (and twice in Distances). Cliques would add a third copy. **Proposed:** move them
  to GraphProtocols as `package` members next to `_runOnUndirectedRows`.
* **Batagelj–Zaversnik.** Four `[Int]` arrays of n (+ Δ + 1 for the bins), exactly as in
  "Cores" above. `CoreNumbers` stores the core numbers and the ordering as `[Int]` by number,
  plus the `listed` vertices when the graph has no vertex indices. `degeneracy` is stored.
* **Maximal cliques (ELS + Tomita), no recursion.** The iterator's first `next()` builds the
  simple CSR and σ (the BZ pass) and a rank array. For each outer vertex v, relabel P ∪ X
  (≤ Δ vertices, P ≤ d) **in ascending vertex index**, so bit order is index order. Build
  the local adjacency as bitsets: one row of ⌈|P ∪ X|/64⌉ words per local vertex, filled by
  scanning each member's simple row against a local-id map. That costs O(Σ degrees of P ∪ X)
  and is reset after use. Then P and X are bitsets, the pivot score is `popcount(P & N(u))`
  (the least-index tie is the lowest bit, scanning upward and keeping strict maxima), and the
  branch set `P & ~N(u)` is walked lowest bit first. An explicit stack holds frames (P, X,
  remaining branch bits, |R|) in one flat word buffer, plus R as an `[Int]` used as a stack.
  `next()` resumes the stack where it stopped. A reported clique is R mapped to global numbers,
  sorted (cliques are small), and mapped to vertices. Eppstein–Strash 2011 measured
  this hybrid (adjacency lists outside, matrices inside each subproblem) fastest on large sparse
  graphs. For hubs (|X| large but |P| ≤ d), the X-only rows can be skipped: only P ∪ X × P
  adjacency is ever read, so build N(u) ∩ P bits, not N(u) ∩ (P ∪ X), for u ∈ X. Benchmark
  before choosing.
* **`cliqueNumber()`**: branch and bound in σ order (as ELS, P = later neighbours). Skip v when
  core(v) + 1 ≤ best. Prune a node when |R| + colours(P) ≤ best, with a greedy colouring of P in
  bitset form (Tomita–Seki MCQ/MCS style). Stop as soon as best = degeneracy + 1. Seed best with
  a greedy clique grown from the last vertex of σ.
* **`maximumClique()`**: ω from `cliqueNumber()`, then for each v in **index** order with
  core(v) + 1 ≥ ω, search for a clique of size ω whose least index is v. P = the neighbours with
  a greater index, branching in ascending index, pruning |R| + colours(P) < ω. The first clique
  found is the lexicographically least one with least vertex v, and v ascends, so it is the
  answer. `ref.py` checks the rule by brute force over all maximal cliques.
* **Triangles, whole graph (compact-forward, Latapy 2008).** Rank the vertices by (simple degree,
  index) with a counting sort. Keep each vertex's forward neighbours (greater rank). For each v
  in rank order, mark its forward neighbours with a stamp. For each forward neighbour w and each
  forward neighbour x of w that is marked, count the triangle and add 1 to T[v], T[w] and T[x].
  The work is O(m^{3/2}). `ref.py` checks it against per-vertex marking on every graph of up to
  5 000 vertices. Clustering needs only T and the simple degrees. The transitivity numerator and
  denominator are `Int` sums, then one division.
* **One vertex.** Collect N(v) (simple) into a `Set` of numbers (or of `Vertex` without vertex
  indices), then for each w ∈ N(v) count the members of N(w) other than v that are in the set,
  and halve. No n-sized allocation, so the query stays local.
* **Floating point.** `clusteringCoefficient` = `Double(2 * T) / Double(d * (d - 1))`, which is
  NetworkX's `t / (d*(d-1))` with t = 2T, bit-identical. The average is summed in index order
  (above).
* **Dependencies.** GraphProtocols only, as `scripts/modules.py` already says. There is no
  priority queue, because BZ uses bins.
* **Tests** (public API only): every catalog row. For every case, also check that the one-shots
  equal the value's members, that `Set(maximalCliques())` matches the catalog as a set, and
  that every listed clique is a clique and maximal (`contains(edge:)` for each pair, no outside
  vertex adjacent to all). Check that `maximumClique().count == cliqueNumber()`, that
  `cliqueNumber() <= degeneracy + 1`, and that `g.directed.undirected` gives the same values as
  `g` (opposite arcs merge). Property tests (swift-property-based) do the same on random
  multigraphs with loops. `just diff` checks against NetworkX `find_cliques` (as sets),
  `core_number` on the simple graph, `triangles` and `clustering`. Benchmarks, not tests: the
  BZ, ELS and compact-forward bounds, and bitset against list subproblems.

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Cores with loops or parallel edges | NetworkX raises `NetworkXNotImplemented` (any self-loop, any MultiGraph); igraph counts multiplicity and each loop twice (doubled K₂: [2, 2]; K₂ with two loops: [3, 3]); ours: the simple graph ([1, 1]) | CQ-064, CQ-328 – CQ-333 |
| Triangles with parallel edges | NetworkX and igraph count vertex triples; JGraphT `getNumberOfTriangles` multiplies by multiplicities | CQ-441 |
| NetworkX `triangles` on a MultiGraph | `triangles(G)` accepts it, but `triangles(G, v)` raises (`_triangles_and_degree_iter` is `not_implemented_for("multigraph")`); `clustering`, `transitivity`, `core_number` raise | asserted in `ref.py` |
| Local clustering at degree < 2 | NetworkX, JGraphT, Boost 0; igraph NaN by default | CQ-067, CQ-403 |
| Average clustering | NetworkX (default), JGraphT, igraph `mode="zero"` count zeros; igraph's default drops degree < 2 (karate 0.5879… against 0.5706…); NetworkX `count_zeros=False` drops all zeros and raises `ZeroDivisionError` when nothing is left | CQ-405, CQ-440 |
| Empty graph | NetworkX `average_clustering` raises `ZeroDivisionError`, `transitivity` 0; igraph NaN for both; JGraphT average 0; ours 0, 0 | CQ-009, CQ-010 |
| Transitivity with no triple | NetworkX 0, igraph NaN | CQ-459 |
| Average clustering, last bit | Python ≥ 3.12 `sum()` is compensated, so NetworkX's average differs from a plain left-to-right sum in the last bit on 146 of 300 random graphs | `avgbits.py`; `ref.py` tolerance |
| Maximum clique ties | NetworkX `max_weight_clique(weight=None)` returns the last isolated vertex (`[1]` of two, `[2]` of three); ours the lexicographically least | CQ-207 |
| Clique order | NetworkX: set order (`[2, 0, 1]`); igraph: its own (`(3, 2)`); JGraphT: `Set`s; ours: each clique in `vertices` order, sequence by the documented algorithm | CQ-101 |
| Directed graphs | NetworkX cliques/triangles raise; igraph ignores direction (warning); Boost cliques need both arcs; NetworkX cores in + out (reciprocal twice: [2, 2] on a 2-cycle), igraph `mode` in/out/all, Boost in-degree, JGraphT `Coreness` undirected only | CQ-501 – CQ-515 |
| `graph_clique_number` | Removed from NetworkX 3.x; `max(len(c) for c in find_cliques(G))` is the replacement | — |
| Boost Bron–Kerbosch | The header says it "does not implement the candidate selection optimization" (no pivot) and is recursive, with default `min = 2` (singletons skipped) | — |

## README edits proposed

* `Cliques` row: "Maximal cliques (Bron–Kerbosch with Tomita pivoting in degeneracy order,
  Eppstein–Löffler–Strash; lazy), maximum clique and clique number, core numbers
  (Batagelj–Zaversnik) with degeneracy, degeneracy ordering, k-cores and k-shells, triangle counts,
  local clustering, transitivity, average clustering; all on the simple graph underlying a
  `Graph` (**planned**)". Result types: `MaximalCliques`, `CoreNumbers`,
  `ClusteringCoefficients` (drop `Clique`).
* "What is a `Sequence`" → Orderings: the degeneracy ordering is `CoreNumbers.degeneracyOrdering`
  (an `Array`, so a `RandomAccessCollection`).
* Terminology: the rows under "Names" above.
