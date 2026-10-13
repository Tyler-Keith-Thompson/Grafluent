# Covering: API

Vertex covers, independent sets, dominating sets and edge covers of an undirected graph. Every
result is a plain array: vertices in `vertices` order (as Cliques' `maximumClique()`), edge
positions ascending (as `Matching.edges`).

* **Independent sets.** The exact maximum independent set from one solve
  (`maximumIndependentSet()`, with `independenceNumber()`), and the lexicographically least one by
  vertex index (`lexicographicallyFirstMaximumIndependentSet()`, the same tie rule as Cliques'
  `lexicographicallyFirstMaximumClique()`), as ColoringModule splits `minimumColoring()` from
  `lexicographicallyFirstMinimumColoring()`. The greedy maximal independent set in vertex order
  (`maximalIndependentSet()`, optionally `containing:` seed vertices).
* **Vertex covers.** The exact minimum vertex cover (`minimumVertexCover()`), defined as the
  complement of `maximumIndependentSet()`. On bipartite graphs and on every bipartite component of
  any graph it runs in O(m √n) from a maximum matching (König). König's own cover is
  `minimumVertexCover(bipartition:)`. The Bar-Yehuda–Even 2-approximation, weighted or not
  (`approximateMinimumVertexCover(weight:)`).
* **Dominating sets.** The exact minimum dominating set (`minimumDominatingSet()`, and the
  lexicographically least, `lexicographicallyFirstMinimumDominatingSet()`) and the greedy (1 + ln
  Δ)-approximation, weighted or not (`approximateMinimumDominatingSet(weight:)`).
* **Edge covers.** The minimum edge cover from a maximum matching (`minimumEdgeCover()`, Gallai's
  construction), or from a matching the caller already has (`minimumEdgeCover(matching:)`).
* **Checks**: `isVertexCover`, `isIndependentSet`, `isDominatingSet`, `isEdgeCover`.

`cases.md` (CV-001 – CV-220, 220 cases) pins the values. `ref.py` computes every row from a model
of this API and checks it independently. Exact optima are checked against brute force on small
graphs, and on larger ones against a reference that uses no components and no matchings: it adds
vertices one at a time in index order, asking an independence-number oracle (NetworkX
`max_weight_clique` on the complement) at each step. With igraph installed, `maximumIndependentSet`
is also checked against the least of igraph's `largest_independent_vertex_sets`. König rows are
checked against NetworkX `to_vertex_cover`, the approximations against NetworkX's outputs and their
ratio bounds, and edge covers against NetworkX `min_edge_cover` and `bipartite.min_edge_cover`.
`--stress` adds 1,500 random graphs (bipartite-heavy, shuffled edge orders, some self-loops): the
component-and-matching algorithm equals brute force on every one, as does every other entry
point's model. Run `uv run --quiet --no-project --with networkx==3.7 --with igraph python3 ref.py
[--stress] [--write]` (without `--with igraph` the igraph checks are skipped, so run `--write` with
it).

## Scope

| Entry point | Purpose |
|---|---|
| `maximumIndependentSet()` | Exact, one solve: bipartite components in polynomial time, the rest by reductions and branch and bound |
| `lexicographicallyFirstMaximumIndependentSet()` | Exact and fixed by a rule: the least set, decided vertex by vertex, up to one solve per vertex |
| `independenceNumber()` | α(G), the same solve without building the set |
| `maximalIndependentSet()`, `maximalIndependentSet(containing:)` | Deterministic: vertex order, not a random choice |
| `minimumVertexCover()` | The complement of `maximumIndependentSet()` (Gallai: τ + α = n) |
| `minimumVertexCover(bipartition:)` | König's construction from a maximum matching; a different minimum cover from `minimumVertexCover()` (Semantics) |
| `approximateMinimumVertexCover()`, `approximateMinimumVertexCover(weight:)` | Bar-Yehuda–Even local ratio. O(n + m), at most twice the least weight |
| `minimumDominatingSet()` | Exact, branch and bound: γ and the last set found |
| `lexicographicallyFirstMinimumDominatingSet()` | Exact and fixed by a rule: the least set of γ vertices, decided vertex by vertex |
| `approximateMinimumDominatingSet()`, `approximateMinimumDominatingSet(weight:)` | Chvátal's greedy set cover. At most H(Δ + 1) ≤ 1 + ln(Δ + 1) times the least weight |
| `minimumEdgeCover()`, `minimumEdgeCover(matching:)` | Gallai: ρ = n − ν |
| `isVertexCover`, `isIndependentSet`, `isDominatingSet`, `isEdgeCover` | Definitions, O(n + m) |

Related computations that are not entry points:

* A cheap dominating set: `maximalIndependentSet()` is a minimal dominating set on a loop-free
  graph.
* A 2-approximate minimum edge dominating set: MatchingModule's `maximalMatching()`.
* A vertex cover of a digraph's arcs: the cover of `digraph.undirectedView`.

## Summary

```swift
import GraphProtocols
import BipartiteGraphs
import MatchingModule

extension Graph {
    // Independent sets: no edge, and no self-loop, has both ends in the set.

    /// A maximum independent set (exact), in `vertices` order, from one solve; which one depends
    /// on the search. A vertex with a self-loop is never in it; parallel edges count once.
    /// Bipartite components cost O(m √n); the rest are reduced and searched by branch and bound,
    /// exponential in the worst case.
    public func maximumIndependentSet() -> [Vertex]

    /// The lexicographically first maximum independent set: of all the largest ones, the least by
    /// vertex index, in `vertices` order. Of two sets of one size, the lesser is the one that
    /// holds the least vertex of their symmetric difference (`lexicographicallyFirstMaximumClique()`'s
    /// rule). Up to one exponential solve per vertex.
    public func lexicographicallyFirstMaximumIndependentSet() -> [Vertex]

    /// The size of a maximum independent set, α. The same solve without building the set.
    public func independenceNumber() -> Int

    /// A maximal independent set: each vertex in `vertices` order joins when it has no self-loop and no neighbour in the set
    /// yet. O(n + m).
    public func maximalIndependentSet() -> [Vertex]

    /// The same, starting from `seeds`, or nil when `seeds` is not an independent set (two are
    /// adjacent, or one has a self-loop). Repeats are ignored. Precondition: every seed is a vertex.
    public func maximalIndependentSet(containing seeds: some Sequence<Vertex>) -> [Vertex]?

    // Vertex covers: every edge, and every self-loop, has an end in the set.

    /// A minimum vertex cover (exact): `vertices` minus `maximumIndependentSet()`, in `vertices`
    /// order. Every vertex with a self-loop is in it.
    public func minimumVertexCover() -> [Vertex]

    /// König's minimum vertex cover of a bipartite graph: from a maximum matching, Z is the set of vertices reached from the free left vertices by
    /// alternating paths, and the cover is (left ∖ Z) ∪ (right ∩ Z). It is the one minimum cover
    /// with the most left vertices, so it does not depend on the matching. O(m √n).
    /// Precondition: `bipartition` is this graph's.
    public func minimumVertexCover(bipartition: Bipartition<Self>) -> [Vertex]

    /// A vertex cover of at most twice the least weight (Bar-Yehuda–Even local ratio): each edge
    /// in position order with neither end in the cover puts in the end with the lesser remaining
    /// weight (the lesser vertex index on ties) and subtracts that weight from the other end.
    /// `weight` is called once per vertex. O(n + m).
    /// Precondition: no weight is negative or NaN.
    public func approximateMinimumVertexCover<W: Comparable & AdditiveArithmetic>(
        weight: (Vertex) -> W) -> [Vertex]
    /// The same with every weight 1. On a loop-free graph it lies within the ends of
    /// `maximalMatching()`.
    public func approximateMinimumVertexCover() -> [Vertex]

    // Dominating sets: every vertex is in the set or adjacent to one in it.

    /// A minimum dominating set (exact); which one depends on the search. Self-loops and parallel
    /// edges do not matter; isolated vertices are in it. Exponential in the worst case.
    public func minimumDominatingSet() -> [Vertex]

    /// The lexicographically first minimum dominating set: of the smallest, the least by vertex
    /// index. Up to one search per vertex after γ is found.
    public func lexicographicallyFirstMinimumDominatingSet() -> [Vertex]

    /// A dominating set of at most H(Δ + 1) times the least weight (Chvátal's greedy set cover):
    /// repeatedly the vertex with the least
    /// weight per newly dominated vertex of its closed neighbourhood, the least vertex index on ties.
    /// Integers are compared exactly (w(u)·k(v) < w(v)·k(u)); floating-point weights by w / k.
    /// O((n + m) log n). Precondition: no weight is negative or NaN; for integers the
    /// products w · (Δ + 1) fit.
    public func approximateMinimumDominatingSet<W: BinaryInteger>(weight: (Vertex) -> W) -> [Vertex]
    public func approximateMinimumDominatingSet<W: FloatingPoint>(weight: (Vertex) -> W) -> [Vertex]
    /// The same with every weight 1: the vertex dominating the most new vertices, least index on ties.
    public func approximateMinimumDominatingSet() -> [Vertex]

    // Edge covers: every vertex is an end of some edge in the set.

    /// A minimum edge cover (positions, ascending), or nil when some vertex has no edge. The
    /// edges of `maximumMatching()`, then for each vertex still uncovered, in vertex order, its
    /// first edge in `incidentEdges` order (a self-loop covers its vertex). n − ν edges (Gallai).
    /// O(n · m · α(n)).
    public func minimumEdgeCover() -> [Edges.Index]?

    /// The same construction from `matching`: pass `maximumBipartiteMatching()` on a bipartite
    /// graph for O(m √n). Minimum when `matching` is maximum; from any other matching
    /// it is still an edge cover. O(n + m). Precondition: `matching` is of this graph.
    public func minimumEdgeCover<W>(matching: Matching<Self, W>) -> [Edges.Index]?

    // Checks. Repeats are ignored. Precondition: every element is a vertex (a position of `edges`).
    public func isVertexCover(_ vertices: some Sequence<Vertex>) -> Bool
    public func isIndependentSet(_ vertices: some Sequence<Vertex>) -> Bool
    public func isDominatingSet(_ vertices: some Sequence<Vertex>) -> Bool
    public func isEdgeCover(_ edges: some Sequence<Edges.Index>) -> Bool
}
```

Vertex sets are `[Vertex]` in `vertices` order, as `maximumClique()` returns; edge sets are
`[Edges.Index]` ascending, as `Matching.edges`. Two equal sets are equal arrays, and a result holds
no copy of the graph. `Set(result)` gives O(1) membership. Weighted results do not carry their
weight; `weight` is called once per vertex and its values are not kept.

`minimumVertexCover()` finds the bipartite components itself and solves them from a maximum
matching, so it is polynomial on every bipartite input with no `BipartiteGraph` overload. König's
cover, which favours one side, is `minimumVertexCover(bipartition:)`; it can differ from the
complement of the lexicographically least independent set (CV-064: `[3, 4, 5]` against König's
`[0, 1, 2]`). `g.lexicographicallyFirstMaximumIndependentSet()` equals Cliques'
`lexicographicallyFirstMaximumClique()` of the complement, and its complement is the
lexicographically greatest minimum cover. There is no lexicographic cover entry point; take that
complement.

The integer dominating-set overload cross-multiplies, so it compares ratios exactly; the
floating-point overload divides (CV-165). The vertex-cover approximation only subtracts, so
`Comparable & AdditiveArithmetic` is enough.

## Semantics

### Self-loops, parallel edges, isolated vertices

* **A self-loop {v, v} has both ends at v.** So v must be in every vertex cover (CV-052, CV-054,
  CV-191, CV-192) and is never independent (CV-003, CV-006, CV-031, CV-198). With this rule τ + α =
  n holds on every graph, so `minimumVertexCover()` stays the complement of
  `maximumIndependentSet()`.
* **Domination ignores loops**: v dominates itself anyway (CV-131, CV-150, CV-206). **An edge
  cover may use a loop** to cover its vertex (CV-169, CV-173, CV-211).
* **Parallel edges** change nothing for vertex sets (CV-007, CV-055, CV-091, CV-126, CV-134,
  CV-156). Edge covers name positions, so the copy taken is the one the rule meets first
  (CV-175, CV-212).
* **Isolated vertices** are in every maximum (and maximal) independent set and every dominating set
  (CV-004, CV-132, CV-203). They make an edge cover impossible: nil (CV-168, CV-171, CV-187). The
  empty graph has empty results everywhere, including an empty edge cover (CV-001, CV-050, CV-129,
  CV-167).

### Independent sets, `independenceNumber()`, `minimumVertexCover()`

* **`maximumIndependentSet()`**: some maximum independent set, from one solve: the bipartite
  components as below (whose pass gives their least set), complete components their least vertex,
  and each other component one run of the reductions and kernel search below, whose set is
  whatever the search finds. `minimumVertexCover()` is its complement, so MinimumVC rows give τ,
  with the complement of the least set in the Checked column. Tests assert size, order and
  validity, never which set.
* **`lexicographicallyFirstMaximumIndependentSet()`**: the lexicographically least maximum
  independent set by vertex index. The rule is Cliques' `lexicographicallyFirstMaximumClique()`'s:
  of equal-size sets, the first sorted index tuple. Examples: P(4) gives {0, 2}
  over {0, 3} and {1, 3} (CV-011); vertex order, not label order, decides (CV-027).
* **Decomposition, all of which keeps the rule.** Looped vertices are dropped (they are in every
  cover). The rest splits into connected components, and the lexicographically least set of the
  whole graph is the union of each component's lexicographically least set: the least vertex of a
  symmetric difference lies in one component, where that component's choice wins. Each component
  is then solved by one of two methods.
* **Bipartite components: König plus the cover lattice, O(m √n).** Take a maximum matching
  (Hopcroft–Karp). Vertices reached by alternating paths from free left vertices split into
  left ones, in every maximum independent set, and right ones, in every minimum cover. Free
  right vertices give the same split with the sides swapped. The remaining vertices (the core) are
  perfectly matched, and every minimum cover takes exactly one end of each core matched pair X:
  its left end (X = L) or its right end (X = R). An unmatched core edge from X's left end to Y's
  right end requires "X = R implies Y = R" (equivalently "Y = L implies X = L"). The valid choices
  are exactly the assignments that respect these implications (Dulmage–Mendelsohn). The
  lexicographically least independent set comes from one greedy pass: for each core vertex v
  in index order whose pair is undecided, choose the value that keeps v independent (X = R if v is
  X's left end, X = L if its right end) and propagate along the implications (R forward, L
  backward) to undecided pairs. Any undecided pair can take either value: the decided-L pairs are
  closed under predecessors and the decided-R pairs under successors, so an undecided pair has no
  decided descendant forced L and no decided ancestor forced R. Each choice is therefore feasible
  at the earliest vertex it affects, which is the greedy argument for lexicographic optimality.
  Every pair is decided once and every arc crossed at most once: O(n + m) after the matching.
  `ref.py` checks this against brute force on 1,500 random graphs with interleaved sides
  (CV-028, CV-029 and CV-064 – CV-066 are rows where it matters).
* **Other components: branch and bound, exponential.** First α of the component, by a maximum-clique
  search on the complement's bitset rows with a greedy-colouring bound, in any vertex order (degree
  order is fastest). Then one search for the lexicographically least set of exactly α vertices:
  depth first in ascending index, "include" before "exclude", the same bounds, stopping at the first
  set found (Cliques' `search(exact:)`). Odd cycles, wheels, Petersen (CV-015, CV-017, CV-019 –
  CV-021) and random graphs (CV-037 – CV-039) are the rows here. Mixed graphs combine both methods
  (CV-026, CV-030, CV-032, CV-068).
* **Fast spelling.** `maximumIndependentSet()` runs the α computation once with the set kept:
  the reductions, then the search on the kernel's non-bipartite components, the folds undone at
  the end. No vertex-by-vertex pass.
* **Witness.** `minimumVertexCover()` has no certificate in general. On a bipartite graph its size
  equals `maximumBipartiteMatching().edges.count` (König), which tests assert (CV-062 – CV-066).
* `independenceNumber()` is `maximumIndependentSet()`'s solve without the set; on bipartite
  components it is n − |matching| with no further pass.

### `minimumVertexCover(bipartition:)` (König)

* **Construction.** Take a maximum matching (Hopcroft–Karp on the sides, as
  `maximumBipartiteMatching(bipartition:)`) and let Z be the vertices reached from the free left
  vertices by alternating paths: an unmatched edge from left to right, then the matched edge back.
  The cover is (left ∖ Z) ∪ (right ∩ Z). `ref.py` checks it against NetworkX `to_vertex_cover` on
  every row (CV-072 – CV-086).
* **It does not depend on the matching.** By brute force it is the one minimum cover with the most
  left vertices (every König row; in `--stress`, a second maximum matching found by augmenting paths
  in reversed vertex order gives the same cover on every bipartite graph). Z ∩ left is the set of
  left vertices that some maximum matching leaves free (Gallai–Edmonds), so Z is determined by the
  graph. This is why the entry point takes no matching.
* **Sides matter.** With `g.bipartition()` each component's least vertex is left, so the
  cover leans to that side. It differs from `minimumVertexCover()` on CV-073, CV-074, CV-076,
  CV-079, CV-081 and CV-085 (each row shows both). On a `BipartiteGraph`, pass `bipartition()`.
* **Parallel edges** are fine (CV-084); a self-loop makes the graph non-bipartite, so it cannot
  have a bipartition.

### `approximateMinimumVertexCover`

* **Procedure** (Bar-Yehuda–Even 1981). cost = weights.
  For each edge {a, b} in position order with neither end in the cover: put in a if cost(a) ≤
  cost(b), else b, where a is the end with the lesser vertex index; subtract the chosen end's cost
  from the other end's. A self-loop puts its vertex in (cost(a) ≤ cost(a)), zeroing its cost
  (CV-089, CV-108).
* **Edge order** is position order, as `maximalMatching()` uses (MatchingModule MA-025). CV-099
  and CV-100 differ only in edge order.
* **Guarantee**: weight ≤ 2 · optimum. Every row checks it against the exact weighted optimum, and
  so do the stress graphs with random weights in 0…5. Unweighted (all weights 1) on a loop-free
  graph, the cover lies within the ends of `maximalMatching()` and is often smaller (CV-095:
  the star's hub alone, where the matching has two ends).
* **Weights**: integers exact; floating point subtracts in edge order (CV-109). Zero weights are
  fine (CV-106: weight 0). Negative or NaN weights trap (CV-213, CV-214): the local-ratio argument
  needs w ≥ 0.

### `maximalIndependentSet`

* Vertices in index order; v joins unless it has a self-loop or a neighbour already in the set
  (CV-112 – CV-128). Seeds go in first (CV-117, CV-119). Seeds that are adjacent or looped give
  nil (CV-120, CV-121). Repeated seeds are
  one seed (CV-125).

* Every maximal independent set is a minimal dominating set on a loop-free graph, so this is also
  a cheap dominating set.

### `minimumDominatingSet()`, `lexicographicallyFirstMinimumDominatingSet()`

* **`minimumDominatingSet()`**: γ by the branch and reduce below, with every reduction rule; the
  last set the γ search found is the answer, so which set depends on the search. Tests assert
  size, order and validity.
* **`lexicographicallyFirstMinimumDominatingSet()`**: the lexicographically least minimum
  dominating set (CV-129 – CV-147), checked as the first subset of size γ in combinations order. Components decompose as for independent sets
  (checked: the per-component union agrees on every row).
* **Procedure** (the result does not depend on it): per component, γ by branch and bound
  (branch on an undominated vertex with the fewest possible dominators, over its closed
  neighbourhood), then a lexicographic search in ascending index, "include" first, with budget γ.
  It prunes when some undominated vertex has no undecided or chosen vertex left in its closed
  neighbourhood, and when ⌈undominated / greatest new coverage⌉ exceeds the budget. Exponential;
  intended for small graphs (grid(4,4), Petersen and lcg(14,20,10) are in the catalog).

### `approximateMinimumDominatingSet`

* **Procedure**: until every vertex is dominated, choose the vertex v not yet chosen
  that minimizes w(v) / k(v), where k(v) is the number of undominated vertices in N[v] (skipping
  k = 0), and on ties the least index (CV-148 – CV-166). Unweighted: the greatest k, least index.
* **Guarantee**: weight ≤ H(max |N[v]|) · optimum (Chvátal 1979), checked by brute force
  (CV-160: 5 vertices against the optimum 4).
* **Lazy greedy.** Ratios only grow as vertices become dominated, so a heap of stale keys is a
  lower bound. Pop the least, recompute its key, and take it if it still does not exceed the new
  top (ties by index); otherwise push it back. The output equals the eager scan's.

### `minimumEdgeCover`

* `maximumMatching()`'s edges, then each vertex still uncovered, in vertex order, adds its first
  `incidentEdges` entry (CV-167 – CV-188). With a maximum matching no two uncovered vertices are
  adjacent, so each added edge covers one new vertex and the size is n − ν (Gallai), checked on
  every row against brute force. The first entry may be a self-loop (CV-173).
* **Which edges.** They follow MatchingModule's documented Edmonds procedure. With
  `minimumEdgeCover(matching: g.maximumBipartiteMatching())` on a `BipartiteGraph` they follow
  Hopcroft–Karp (CV-185 – CV-188).
* From a matching that is not maximum, the same rule still returns an edge cover. A vertex covered
  by an edge added earlier in the pass is skipped, so two adjacent uncovered vertices share one
  edge. The cover is then not necessarily minimum.

### Checks

Definitions, each O(n + m). Elements may repeat (CV-193, CV-201). A non-vertex or non-position
traps (CV-217, CV-218): a position or vertex outside the graph is a caller bug, as in
MatchingModule's checks.

## Determinism

| Entry point | Which result | Tests assert |
|---|---|---|
| `lexicographicallyFirstMaximumIndependentSet()` | Lexicographically least maximum independent set | Exact; brute force; Cliques' `lexicographicallyFirstMaximumClique()` on the complement |
| `maximumIndependentSet()`, `minimumVertexCover()` | Some maximum independent set (and its complement), from one solve | Size, order, validity; the cover is the set's complement; König size on bipartite graphs |
| `independenceNumber()` | α | Exact |
| `minimumVertexCover(bipartition:)` | König's cover: the minimum cover with the most left vertices | Exact |
| `approximateMinimumVertexCover` | Bar-Yehuda–Even, positions, lesser index on ties | Exact; ≤ 2 · optimum |
| `maximalIndependentSet` | Greedy in vertex order, seeds first | Exact; independent and maximal |
| `lexicographicallyFirstMinimumDominatingSet()` | Lexicographically least minimum dominating set | Exact; brute force |
| `minimumDominatingSet()` | Some minimum dominating set | Size, order, validity |
| `approximateMinimumDominatingSet` | Least ratio, least index on ties | Exact; ≤ H(Δ + 1) · optimum |
| `minimumEdgeCover` | Matching edges, then each uncovered vertex's first edge | Exact; size n − ν |
| Checks | Definitions | Exact |

The lexicographically first optima are defined by a property, not by a procedure, so the search
can change without changing them; the fast spellings return whichever optimum the search finds. The approximations and the greedy sets are defined by
their procedure, as `maximalMatching()` is.

## Complexity

n vertices, m edges, Δ the greatest degree, c the size of the largest non-bipartite component
left after removing looped vertices.

| Entry point | Time | Extra memory |
|---|---|---|
| `maximumIndependentSet`, `independenceNumber`, `minimumVertexCover` | O(n + m) to split and reduce; O(m √n) for bipartite components; one search, exponential in the kernel's size, for the rest | O(n + m), plus k² / 64 words of bitset rows (the complement of one kernel component of k vertices) |
| `lexicographicallyFirstMaximumIndependentSet` | as above, plus up to one such solve per vertex of a component the rules do not settle | the same |
| `minimumVertexCover(bipartition:)` | O(m √n) | O(n) |
| `approximateMinimumVertexCover` | O(n + m) | n costs and marks |
| `maximalIndependentSet` | O(n + m) | n marks |
| `minimumDominatingSet` | exponential | O(n + m) per search level, iterative |
| `lexicographicallyFirstMinimumDominatingSet` | exponential, up to one search per vertex after γ | the same |
| `approximateMinimumDominatingSet` | O((n + m) log n) | heap of n, counts, marks |
| `minimumEdgeCover()` | O(n · m · α(n)) (Edmonds) | O(n) |
| `minimumEdgeCover(matching:)` | O(n + m) | n marks |
| checks | O(n + m + k) | n marks |

## Implementation notes (index space)

* **Rows.** Every algorithm is an `_UndirectedRowsAlgorithm` run by `_runOnUndirectedRows`
  (edge numbers read only by `minimumEdgeCover`), so incident-index rows are used where the
  representation has them. Simple neighbourhoods (no self, parallel copies once) come from a stamp
  array per row scan, as Cliques' `_simpleRows()`; `loop: [Bool]` is filled in the same pass.
* **Components and two-colouring.** One breadth-first pass over the loop-free vertices labels
  components and colours them; a component with a conflicting edge goes to the search. The colouring
  is local (any proper one: the lattice result does not depend on which side is called left).
* **Matching.** Hopcroft–Karp on all bipartite components at once (they are disjoint), after a
  greedy start: MatchingModule's `_hopcroftKarpPhases`, following only targets on a bipartite
  component (a looped neighbour is outside). The alternating reach is
  one queue seeded with every free vertex, tagged with its root's side; the implications are the
  unmatched core edges, scanned from left ends; the greedy is one pass with an explicit stack per
  propagation. `Int32` arrays throughout, `Int` when n ≥ 2³¹.
* **Branch and bound.** Cliques' `_MaximumCliqueSearch` (BBMC) on bitset rows of a kernel
  component's complement, vertices by ascending degree. Isolated vertices and components of one or
  two vertices are answered without the search.
* **Dominating search.** Bitset closed neighbourhoods per component, an "undominated" bitset per
  depth on a flat stack, no recursion.
* **Bar-Yehuda–Even**: one pass over `edges` with `cost: [W]` read once per vertex from
  `weight` in `vertices` order and `inCover: [Bool]`.
* **Greedy dominating**: `uncovered` counts per vertex, maintained by decrementing N[x] when x
  becomes dominated (O(n + m) total), a binary heap of (key, index) with lazy re-keying (keys only
  rise, so stale entries are lower bounds).
* **Edge cover**: `maximumMatching()`'s (or the given) `Matching`'s mate array, then one pass over
  vertices. The result sorts the added positions into the matching's ascending ones by a counting
  pass over edge numbers.
* **Dependencies**: GraphProtocols, BipartiteGraphs (`Bipartition`), MatchingModule (`Matching`,
  `maximumMatching()`, Hopcroft–Karp), Cliques (`_MaximumCliqueSearch`). BipartiteGraphs comes
  through MatchingModule but is imported directly, so it is listed.
