# Cliques: API

Maximal-clique enumeration (Bron–Kerbosch), the maximum clique and clique number, the core
decomposition (core numbers, degeneracy, degeneracy ordering, k-cores and k-shells), and triangle
counts with the clustering coefficients built on them (local, transitivity, average). All on
`Graph`. Directed graphs reach them through `digraph.undirectedView`. `cases.md` (CQ-001 – CQ-633,
276 cases) pins the values. `ref.py` recomputes every one with the model below and checks it
against brute force, NetworkX 3.7 and Latapy's compact-forward count; it also runs 280 random
graphs, loops and parallel edges included (`uv run --quiet --no-project --with networkx==3.7
python3 ref.py`).

## Scope

| Entry point | Purpose |
|---|---|
| `maximalCliques()` → `MaximalCliques<Self>`, a lazy `Sequence` of `[Vertex]` | The output can be exponential (3^{n/3} cliques on Moon–Moser graphs, CQ-621), so it is lazy, like `simpleCycles()`. A caller can stop early, and memory stays O(n + m) whatever the count |
| `maximumClique()` → `[Vertex]` | Branch and bound with a colouring bound and core pruning, much faster than enumerating every maximal clique |
| `cliqueNumber()` → `Int` | Stops as soon as it reaches the degeneracy + 1 upper bound and needs no tie rule, so it can be cheaper than `maximumClique()` |
| `coreNumbers()` → `CoreNumbers<Self>` | Batagelj–Zaversnik in O(n + m). One value holds the core numbers, the degeneracy, the degeneracy ordering, and the k-cores and k-shells |
| `clusteringCoefficients()` → `ClusteringCoefficients<Self>` | One O(m^{3/2}) triangle pass gives each vertex's triangle count and local clustering, plus the transitivity and the average clustering |
| `triangleCount()`, `transitivity()`, `averageClustering()` | One-shot scalars; `triangleCount()` skips the per-vertex arrays. Each equals the same member of `clusteringCoefficients()` |
| `triangleCount(of:)`, `clusteringCoefficient(of:)` | One vertex costs O(Σ_{w ∈ N(v)} d(w)), not a whole-graph pass |

Related computations that are not entry points:

* Cliques of at least k vertices: `maximalCliques().lazy.filter { $0.count >= k }`.
* A k-crust is `coreNumbers()` filtered by core number `< k`.
* `kCore(_:)` returns the vertex list, not a subgraph.
* `isClique`: `allSatisfy` over `contains(edge:)` for each pair.
* A clique is a `[Vertex]` in `vertices` order, so equal cliques give equal arrays.

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
    public func coreNumber(checked vertex: G.Vertex) throws(VertexNotFound) -> Int
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
    public func clusteringCoefficient(checked vertex: G.Vertex) throws(VertexNotFound) -> Double
    public func clusteringCoefficient(ofIndex index: Int) -> Double
    public func triangleCount(of vertex: G.Vertex) -> Int
    public func triangleCount(checked vertex: G.Vertex) throws(VertexNotFound) -> Int
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
can map a vertex to its index, and they are not `Equatable`.
`MaximalCliques` holds the graph and iterates it again from the start each time, as
`UndirectedSimpleCycles` does.

## Semantics

### Simple-graph semantics

Every op reads the **simple graph underlying `g`**: u and v are adjacent when u ≠ v and at least
one edge joins them. Self-loops are ignored, and parallel copies count once. Degrees here mean
simple degrees, the number of distinct other neighbours. That is less than `degree(of:)` when
there are loops or parallel edges. Nothing traps on a multigraph.

* **Cliques** are vertex sets. A vertex whose only edge is a loop is a clique of one (CQ-021,
  CQ-116).
* **Triangles and clustering** count vertex triples, so a parallel edge adds no triangle
  (CQ-441) and clustering never exceeds 1.
* **Cores** are computed on the simple graph too (CQ-328 – CQ-333, CQ-064). The k-core is a
  statement about distinct neighbours (a (k+1)-clique lies in the k-core, so degeneracy + 1 ≥ ω),
  and the bounds used by `maximumClique()` and `maximalCliques()` rely on it.

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
in σ, so `[2, 3]` precedes `[0, 1, 2]`. Row order reaches the result only through σ (CQ-102).
Tests that do not care about order compare sets, and `ref.py` checks the sets against brute force
and NetworkX for every case.

The sequence is not in lexicographic order of the cliques: pivoting can put a smaller clique in
a later branch.

### `maximumClique()` and `cliqueNumber()`

`cliqueNumber()` is ω, the size of a largest clique: 0 for the empty graph, 1 for an edgeless one,
at most `degeneracy + 1`. `maximumClique()` is the **lexicographically least** largest clique by
index (CQ-201 – CQ-207: two disjoint triangles give the one with the least index, also when
`vertices` is reversed, CQ-203). For karate it is `[0, 1, 2, 3, 7]` over `[0, 1, 2, 3, 13]`
(CQ-211). An edgeless graph gives its first vertex (CQ-207). The rule does not depend on the search
algorithm.

### Cores

The k-core is the largest subgraph in which every vertex has at least k neighbours. `coreNumber(of:
v)` is the largest k whose k-core contains v. `degeneracy` is the largest core number, and 0 for
the empty graph. `kCore(k)` lists the
vertices with core ≥ k and `kShell(k)` those with core == k, both in `vertices` order. k beyond
the degeneracy gives `[]`, and `kCore(0)` gives every vertex.
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
core numbers never decrease along the ordering. `ref.py` asserts both on every graph, and checks
the core numbers against NetworkX's `core_number` on every case.

### Triangles and clustering

* `triangleCount(of: v)`: the number of triangles {v, a, b} in the simple graph.
  `triangleCount()` is the number of triangles, so the per-vertex sum is 3 × that.
* `clusteringCoefficient(of: v)` = 2T(v) / (d(d − 1)), with d the **simple** degree. It is **0
  when d < 2**. It is a `Double`, not an optional; the denominator-zero rule is the same for every
  ratio here.
* `transitivity()` = 3 × triangles / connected triples = ΣT(v) / Σ d(d − 1)/2. It is **0 when
  there are no triangles**, including when there are no triples (CQ-459). It is computed as one
  integer ratio converted once, so it is the correctly rounded rational.
* `averageClustering()` = Σ clustering(v) / n over **every** vertex, zeros included
  (Watts–Strogatz). It is **0 for the empty graph**. An average over a subset of vertices is a
  `filter` on the `ClusteringCoefficients` value. The local values are summed in `vertices` order
  with one running total, then divided. Python 3.12's `sum()` is compensated, so `ref.py` compares
  NetworkX's average within 1e-15 relative and pins the plain sum in the catalog.

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

* **Batagelj–Zaversnik.** Four `[Int]` arrays of n (+ Δ + 1 for the bins), exactly as in
  "Cores" above. `CoreNumbers` stores the core numbers and the ordering as `[Int]` by number,
  plus the `listed` vertices when the graph has no vertex indices. `degeneracy` is stored.
* **Maximal cliques (ELS + Tomita), no recursion.** The iterator's first `next()` builds the simple
  CSR and σ (the BZ pass) and a rank array. For each outer vertex v, relabel P ∪ X (≤ Δ vertices, P
  ≤ d) **in ascending vertex index**, so bit order is index order. The local adjacency is bitsets
  kept apart over P and over X: rows over P for every member of P ∪ X, rows over X only for P's
  members, so a hub with a large X but few later neighbours costs |P ∪ X|·|P| bits. The rows are
  filled from later-neighbour rows only. Then P and X are bitsets, the pivot score is `popcount(P &
  N(u))` (the least-index tie is the lowest bit, scanning upward and keeping strict maxima), and the
  branch set `P & ~N(u)` is walked lowest bit first. An explicit stack holds frames (P, X, remaining
  branch bits, |R|) in one flat word buffer, plus R as an `[Int]` used as a stack. `next()` resumes
  the stack where it stopped. A reported clique is R mapped to global numbers, sorted (cliques are
  small), and mapped to vertices.
* **`cliqueNumber()`**: branch and bound in σ order (as ELS, P = later neighbours). Skip v when
  core(v) + 1 ≤ best. Each P is searched by `_MaximumCliqueSearch` (`MaximumCliqueSearch.swift`):
  San Segundo et al.'s BBMC (2011), Tomita–Seki's MCQ on bitsets. P is ordered by descending
  degree within P (left as given below 32 vertices, where sorting costs more than it saves); each
  node colours its candidates greedily in that order and branches from the highest colour down,
  pruning when |R| + colour ≤ best. A greedy clique in P seeds best. Stop as soon as best =
  degeneracy + 1, or at a caller's target.
* **`maximumClique()`**: ω from `cliqueNumber()`, then for each v in σ order with core(v) + 1 ≥ ω,
  the least (ω − 1)-clique among its later neighbours (core(v) + 1 ≥ ω) by a witness pass: W =
  any such clique from the engine (skip v if none); walk the candidates u in ascending index with
  C chosen and P their common neighbours left; u ∈ W is taken, any other u is taken exactly when
  the engine finds a (need − 1)-clique in P ∩ N(u), which becomes W, else u leaves P. Invariant:
  W ⊆ C ∪ P. The least of the per-v cliques (by the least vertex of a symmetric difference) is the
  answer; v is skipped when min(v, its candidates) exceeds the best clique's least vertex.
  `ref.py` checks the rule by brute force over all maximal cliques.
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
* **Floating point.** `clusteringCoefficient` = `Double(2 * T) / Double(d * (d - 1))`. The
  average is summed in index order (above).
