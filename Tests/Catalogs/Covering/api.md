# Covering: proposed API (phase 1)

Vertex covers, independent sets, dominating sets and edge covers of an undirected graph. Every
result is a plain array: vertices in `vertices` order (as Cliques' `maximumClique()`), edge
positions ascending (as `Matching.edges`).

* **Independent sets.** The exact maximum independent set (`maximumIndependentSet()`, with
  `independenceNumber()`), the lexicographically least one by vertex index, the same tie rule as
  `maximumClique()`. The greedy maximal independent set in vertex order
  (`maximalIndependentSet()`, optionally `containing:` seed vertices: NetworkX's
  `maximal_independent_set` without the randomness).
* **Vertex covers.** The exact minimum vertex cover (`minimumVertexCover()`), defined as the
  complement of `maximumIndependentSet()`. On bipartite graphs and on every bipartite component of
  any graph it runs in O(m √n) from a maximum matching (König), so `BipartiteGraph` needs no
  overload of its own. König's own cover, the one NetworkX's `to_vertex_cover` returns, is
  `minimumVertexCover(bipartition:)`. The Bar-Yehuda–Even 2-approximation, weighted or not
  (`approximateMinimumVertexCover(weight:)`, NetworkX's `min_weighted_vertex_cover`, same output).
* **Dominating sets.** The exact minimum dominating set (`minimumDominatingSet()`,
  lexicographically least) and the greedy (1 + ln Δ)-approximation, weighted or not
  (`approximateMinimumDominatingSet(weight:)`, NetworkX's `min_weighted_dominating_set`, same
  output).
* **Edge covers.** The minimum edge cover from a maximum matching (`minimumEdgeCover()`, Gallai's
  construction as NetworkX's `min_edge_cover`), or from a matching the caller already has
  (`minimumEdgeCover(matching:)`, NetworkX's `matching_algorithm` parameter).
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
point's model (608 of them are bipartite graphs where the lexicographic cover differs from König's).
A mutant of the bipartite lattice step that makes the opposite choice fails 682 of them. Run `uv run --quiet
--no-project --with networkx==3.7 --with igraph python3 ref.py [--stress] [--write]` (seconds;
without `--with igraph` the igraph checks are skipped, so run `--write` with it).

## Scope

**In, phase 1**

| Entry point | On | Why |
|---|---|---|
| `maximumIndependentSet()` | `Graph` | README ("maximum independent set"). igraph `largest_independent_vertex_sets` / `independence_number`, Sage `independent_set`, Mathematica `FindIndependentVertexSet`. Exact: bipartite components in polynomial time, the rest by branch and bound |
| `independenceNumber()` | `Graph` | igraph `independence_number`; α(G). The size without the lexicographic pass, as `cliqueNumber()` beside `maximumClique()` |
| `maximalIndependentSet()`, `maximalIndependentSet(containing:)` | `Graph` | NetworkX `maximal_independent_set(G, nodes, seed)`, Graphs.jl `independent_set(g, MaximalIndependentSet())`. Deterministic: vertex order, not a random choice |
| `minimumVertexCover()` | `Graph` | README ("vertex cover … König's from a maximum matching"). JGraphT `RecursiveExactVCImpl`, Sage `vertex_cover`, Mathematica `FindVertexCover`. The complement of `maximumIndependentSet()` (Gallai: τ + α = n) |
| `minimumVertexCover(bipartition:)` | `Graph` | NetworkX `bipartite.to_vertex_cover(G, matching, top_nodes)`: König's construction from a maximum matching, which MatchingModule deferred here. A different minimum cover from `minimumVertexCover()` (Semantics) |
| `approximateMinimumVertexCover()`, `approximateMinimumVertexCover(weight:)` | `Graph` | NetworkX `approximation.min_weighted_vertex_cover` (Bar-Yehuda–Even local ratio), JGraphT `BarYehudaEvenTwoApproxVCImpl`. O(n + m), at most twice the least weight |
| `minimumDominatingSet()` | `Graph` | README ("dominating set (exact and approximation algorithms)"). Sage `dominating_set`. Exact, branch and bound |
| `approximateMinimumDominatingSet()`, `approximateMinimumDominatingSet(weight:)` | `Graph` | NetworkX `approximation.min_weighted_dominating_set` (Chvátal's greedy set cover). At most H(Δ + 1) ≤ 1 + ln(Δ + 1) times the least weight |
| `minimumEdgeCover()`, `minimumEdgeCover(matching:)` | `Graph` | NetworkX `min_edge_cover(G, matching_algorithm)` and `bipartite.min_edge_cover`. Gallai: ρ = n − ν |
| `isVertexCover`, `isIndependentSet`, `isDominatingSet`, `isEdgeCover` | `Graph` | NetworkX `is_dominating_set`, `is_edge_cover`; igraph `is_independent_vertex_set`; Mathematica `VertexCoverQ`, `IndependentVertexSetQ`; Sage `is_independent_set` |

**NetworkX functions, and where each goes**

| NetworkX | Here | Reason |
|---|---|---|
| `approximation.min_weighted_vertex_cover` | `approximateMinimumVertexCover(weight:)` | In. Same cover when positions are in `G.edges()` order (CV-087 – CV-111; CV-099 and CV-100 show the order difference) |
| `bipartite.to_vertex_cover` | `minimumVertexCover(bipartition:)` | In, without the matching argument: the cover does not depend on which maximum matching is used (Semantics) |
| `maximal_independent_set(G, nodes, seed)` | `maximalIndependentSet(containing:)` | In, deterministic. NetworkX draws each vertex at random; ours takes them in vertex order. Rejects the same seed sets (CV-120, CV-121) |
| `approximation.maximum_independent_set` | — | Out: Boppana–Halldórsson clique removal guarantees only O(n / log² n), is recursive (`ramsey_R2`), and iterates Python sets, so its output depends on hash order. The exact search covers small graphs and `maximalIndependentSet()` large ones (open question 4) |
| `dominating_set(G, start_with)` | — | Out. On a loop-free graph it returns a maximal independent set (each vertex it adds has no neighbour in the set yet), so it is `maximalIndependentSet(containing: [start])` (CV-113 – CV-128 note where NetworkX's set pop order agrees). It pops from a Python set, so its order is not documented |
| `is_dominating_set` | `isDominatingSet` | In |
| `approximation.min_weighted_dominating_set` | `approximateMinimumDominatingSet(weight:)` | In, same output on every row (it scans nodes in order and keeps the first minimum, our tie rule) |
| `approximation.min_edge_dominating_set` | — | Out: it is `maximal_matching` (MatchingModule's `maximalMatching()` is the same 2-approximation of the minimum edge dominating set) |
| `connected_dominating_set`, `is_connected_dominating_set` | — | Phase 2 (Guha–Khuller greedy). It needs a connected graph and has its own approximation bound |
| `min_edge_cover`, `bipartite.min_edge_cover` | `minimumEdgeCover()`, `minimumEdgeCover(matching:)` | In. NetworkX returns vertex pairs (both orientations in the bipartite version); ours positions |
| `is_edge_cover` | `isEdgeCover` | In, on positions |

**Also out**

| Not in phase 1 | Reason |
|---|---|
| Exact minimum-weight vertex cover, maximum-weight independent set | Phase 2. Bipartite: a minimum cut (Flows), which Covering does not depend on. General: the weighted branch and bound (NetworkX `max_weight_clique` on the complement is the oracle `ref.py` already uses) |
| Kernelization (crown, degree-2 folding, linear programming reductions; KaMIS) | Phase 2. The usual reductions keep *some* maximum set but not the lexicographically least one; each one needs a proof that it keeps the tie rule (open question 3). Phase 1 decomposes only by self-loops, connected components and bipartiteness, all of which keep it |
| Greedy minimum-degree independent set (Halldórsson–Radhakrishnan, Graphs.jl `DegreeIndependentSet`), JGraphT `GreedyVCImpl`, `ClarksonTwoApproxVCImpl` | Phase 2 if asked for (open question 4). Each is another tie rule; Clarkson's is a second 2-approximation with no advantage over Bar-Yehuda–Even |
| Randomized `using:` overloads (as `louvainCommunities(using:)`) | Open question 5. The deterministic versions are what tests pin |
| Enumeration: all maximal independent sets (igraph `maximal_independent_vertex_sets`), all largest ones, minimal dominating sets | Phase 2, as lazy sequences like `maximalCliques()` (maximal independent sets are maximal cliques of the complement) |
| Independent and total domination, k-domination, edge domination, feedback vertex set | Phase 2 or other modules. Feedback sets belong with Cycles |
| Directed graphs (out-domination, directed vertex cover) | A cover of a digraph's edges is the cover of `digraph.undirected`, which tests can use. Domination in a digraph (N⁺) is a different problem, so it waits for a caller |
| A `VertexSet` result type | Rejected (Result types) |
| Certificates for the approximations (the local-ratio lower bound, the set-cover dual) | Open question 6 |

## Summary

```swift
import GraphProtocols
import BipartiteGraphs
import MatchingModule

extension Graph {
    // Independent sets: no edge, and no self-loop, has both ends in the set.

    /// A maximum independent set (exact): of all the largest ones, the lexicographically least by
    /// vertex index, in `vertices` order. Of two sets of one size, the lesser is the one that
    /// holds the least vertex of their symmetric difference (`maximumClique()`'s rule). A vertex
    /// with a self-loop is never in it; parallel edges count once. Bipartite components cost
    /// O(m √n); the rest are searched by branch and bound, exponential in the worst case.
    public func maximumIndependentSet() -> [Vertex]

    /// The size of a maximum independent set, α. The same search without the lexicographic pass.
    public func independenceNumber() -> Int

    /// A maximal independent set (NetworkX `maximal_independent_set`, without the randomness):
    /// each vertex in `vertices` order joins when it has no self-loop and no neighbour in the set
    /// yet. O(n + m).
    public func maximalIndependentSet() -> [Vertex]

    /// The same, starting from `seeds`, or nil when `seeds` is not an independent set (two are
    /// adjacent, or one has a self-loop). Repeats are ignored. Precondition: every seed is a vertex.
    public func maximalIndependentSet(containing seeds: some Sequence<Vertex>) -> [Vertex]?

    // Vertex covers: every edge, and every self-loop, has an end in the set.

    /// A minimum vertex cover (exact): `vertices` minus `maximumIndependentSet()`, in `vertices`
    /// order. Every vertex with a self-loop is in it.
    public func minimumVertexCover() -> [Vertex]

    /// König's minimum vertex cover of a bipartite graph (NetworkX `to_vertex_cover`, the same
    /// cover): from a maximum matching, Z is the set of vertices reached from the free left vertices by
    /// alternating paths, and the cover is (left ∖ Z) ∪ (right ∩ Z). It is the one minimum cover
    /// with the most left vertices, so it does not depend on the matching. O(m √n).
    /// Precondition: `bipartition` is this graph's.
    public func minimumVertexCover(bipartition: Bipartition<Self>) -> [Vertex]

    /// A vertex cover of at most twice the least weight (Bar-Yehuda–Even local ratio; NetworkX
    /// `min_weighted_vertex_cover`, the same cover when positions are in its edge order): each edge
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

    /// A minimum dominating set (exact), the lexicographically least. Self-loops and parallel
    /// edges do not matter; isolated vertices are in it. Exponential in the worst case.
    public func minimumDominatingSet() -> [Vertex]

    /// A dominating set of at most H(Δ + 1) times the least weight (Chvátal's greedy set cover;
    /// NetworkX `min_weighted_dominating_set`, the same set): repeatedly the vertex with the least
    /// weight per newly dominated vertex of its closed neighbourhood, the least vertex index on ties.
    /// Integers are compared exactly (w(u)·k(v) < w(v)·k(u)); floating-point weights by w / k, as
    /// NetworkX. O((n + m) log n). Precondition: no weight is negative or NaN; for integers the
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

    /// The same construction from `matching` (NetworkX's `matching_algorithm` parameter): pass
    /// `maximumBipartiteMatching()` on a bipartite graph for O(m √n) and NetworkX's
    /// `bipartite.min_edge_cover`. Minimum when `matching` is maximum; from any other matching
    /// it is still an edge cover. O(n + m). Precondition: `matching` is of this graph.
    public func minimumEdgeCover<W>(matching: Matching<Self, W>) -> [Edges.Index]?

    // Checks. Repeats are ignored. Precondition: every element is a vertex (a position of `edges`).
    public func isVertexCover(_ vertices: some Sequence<Vertex>) -> Bool
    public func isIndependentSet(_ vertices: some Sequence<Vertex>) -> Bool
    public func isDominatingSet(_ vertices: some Sequence<Vertex>) -> Bool
    public func isEdgeCover(_ edges: some Sequence<Edges.Index>) -> Bool
}
```

**Result types: plain arrays.** Vertex sets are `[Vertex]` in `vertices` order, as
`maximumClique()` and `Bipartition.left`; edge sets are `[Edges.Index]` ascending, as
`Matching.edges`. Two equal sets are then equal arrays, so tests compare with `==`, and the
result needs no graph copy. A `VertexSet` type with `contains(_:)` was rejected. Its only
addition is O(1) membership, which callers get from `Set(result)`. It would be a second result
type for something Cliques already returns as an array, and it would have to hold the graph (as
`Matching` does) to answer `contains` for vertices without indices. `Matching` holds the graph
because `mate(of:)` maps a vertex to a vertex; a set has no such query. Weighted results do not
carry their weight either: `Matching.weight` exists because matchings are summed per edge in a
documented order, while a vertex set's weight is one `reduce` the caller writes (and `weight` may be
expensive, so it is called once per vertex and its values are not kept).

**Why one `minimumVertexCover()` and no `BipartiteGraph` overload.** MatchingModule rejected an
overload on `BipartiteGraph` that would shadow the `Graph` extension (`maximumMatching()` versus
`maximumBipartiteMatching()`), because generic code holding the graph as `some Graph` would get one
result and concrete code another. The same trap is here: König's cover (most left vertices) and the
lexicographically least cover are different minimum covers on 608 of the 1,500 stress graphs
(CV-064: `[3, 4, 5]` against König's `[0, 1, 2]`). The overload is also unnecessary, since `Graph`'s
`minimumVertexCover()` finds the bipartite components itself (O(n + m)) and solves them from a
maximum matching. So there is one name with one meaning, polynomial on every bipartite input,
and König's own cover is `minimumVertexCover(bipartition:)`, whose argument says which side it
favours.

**Why `maximumIndependentSet()` decides the cover, and not the other way round.** Covering and
Cliques then agree: `g.maximumIndependentSet()` equals `maximumClique()` of the complement (the
same rule on the same vertex numbers), so the cross-module property test is exact. The cover is
the complement, so `minimumVertexCover()` is the lexicographically *greatest* minimum cover (the
one avoiding the least vertex of a symmetric difference). We document it as "the complement of
`maximumIndependentSet()`", which is easier to state and to test.

**Why the approximations are named `approximate…`.** The problem names (`minimumVertexCover`,
`minimumDominatingSet`) are taken by the exact searches, and NetworkX tells the two apart only by
its `approximation` namespace, which Swift methods do not have. `approximate` is NetworkX's own
prefix for this (`approximate_current_flow_betweenness_centrality`). Naming them after the
algorithm (`barYehudaEvenVertexCover`, as JGraphT's class names do) was the alternative. It reads
worse, and the doc comment carries the author's name either way (open question 1).

**Why two dominating-set overloads.** The greedy step compares weight-per-vertex ratios.
NetworkX divides in floating point; for integers, division would round, so the integer overload
cross-multiplies and is exact. The floating overload divides exactly as NetworkX does, so the same
doubles give the same set (CV-165). The vertex-cover approximation only subtracts, so
`Comparable & AdditiveArithmetic` is enough, and it follows NetworkX operation for operation.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| independent set, `maximumIndependentSet()`, `maximalIndependentSet()` | NetworkX `maximal_independent_set`, `maximum_independent_set`; Sage `independent_set`; JGraphT `IndependentSetAlgorithm`; Graphs.jl `independent_set` | independent vertex set (igraph `largest_independent_vertex_sets`, Mathematica): longer, and "independent set" alone is the common term; stable set (literature) |
| `independenceNumber()` | igraph `independence_number`; α(G) in every textbook | `stabilityNumber`: literature only |
| `containing:` | NetworkX `maximal_independent_set(G, nodes=…)` ("nodes that must be part of the independent set") | `seeds:`, `nodes:`: `containing` says what the result does |
| vertex cover, `minimumVertexCover()` | NetworkX `min_weighted_vertex_cover`, `to_vertex_cover`; JGraphT `VertexCoverAlgorithm`; Sage `vertex_cover`; Mathematica `FindVertexCover` | `vertexCover()` (Sage): leaves out "minimum", which the approximation needs to contrast with |
| `approximateMinimumVertexCover`, `approximateMinimumDominatingSet` | NetworkX's `approximation` package and `approximate_` prefix | `minimumWeightedVertexCover` (NetworkX's name without its namespace): would read as exact; `barYehudaEvenVertexCover` (JGraphT `BarYehudaEvenTwoApproxVCImpl`): open question 1 |
| dominating set, `minimumDominatingSet()` | NetworkX `dominating_set`, `min_weighted_dominating_set`; Sage `dominating_set` | — |
| edge cover, `minimumEdgeCover()` | NetworkX `min_edge_cover`; Mathematica `FindEdgeCover` | — |
| `isVertexCover`, `isIndependentSet`, `isDominatingSet`, `isEdgeCover` | NetworkX `is_dominating_set`, `is_edge_cover`; Sage `is_independent_set`; Mathematica `VertexCoverQ`, `IndependentVertexSetQ`; igraph `is_independent_vertex_set` | `isDominating` (Sage `is_dominating`): NetworkX's full name matches the others |
| `matching:` | NetworkX `min_edge_cover(G, matching_algorithm=…)` (we take the matching, not the algorithm) | — |

**Proposed Terminology rows**

* No edge with both ends in the set: independent set, `maximumIndependentSet()`,
  `maximalIndependentSet()`; its greatest size the independence number. NetworkX, igraph, Sage.
  Mathematical term: stable set; α(G).
* An end of every edge in the set: vertex cover, `minimumVertexCover()`. NetworkX, JGraphT, Sage.
  Mathematical term: same; τ(G) (= n − α).
* Every vertex in the set or adjacent to it: dominating set, `minimumDominatingSet()`. NetworkX,
  Sage. Mathematical term: same; γ(G).
* Every vertex an end of an edge in the set: edge cover, `minimumEdgeCover()`. NetworkX.
  Mathematical term: same; ρ(G) (= n − ν).

## Semantics

### Self-loops, parallel edges, isolated vertices

* **A self-loop {v, v} has both ends at v.** So v must be in every vertex cover (CV-052, CV-054,
  CV-191, CV-192) and is never independent (CV-003, CV-006, CV-031, CV-198). NetworkX agrees: its
  `maximal_independent_set` rejects a looped seed (CV-121) and its `min_weighted_vertex_cover`
  takes the looped vertex (CV-089, CV-090). Its random choice can still pick a looped vertex, though
  (`available_nodes` is never stripped of them), and igraph ignores loops altogether
  (`is_independent_vertex_set([0])` is true with a loop at 0: CV-198). With this rule τ + α = n
  holds on every graph, so `minimumVertexCover()` stays the complement of `maximumIndependentSet()`.
* **Domination ignores loops**: v dominates itself anyway (CV-131, CV-150, CV-206). **An edge
  cover may use a loop** to cover its vertex (CV-169, CV-173, CV-211). NetworkX agrees (a looped
  vertex is not an isolate, and `arbitrary_element(G[v])` can be v).
* **Parallel edges** change nothing for vertex sets (CV-007, CV-055, CV-091, CV-126, CV-134,
  CV-156). Edge covers name positions, so the copy taken is the one the rule meets first
  (CV-175, CV-212).
* **Isolated vertices** are in every maximum (and maximal) independent set and every dominating
  set (CV-004, CV-132, CV-203). They make an edge cover impossible: nil (CV-168, CV-171, CV-187;
  NetworkX raises `NetworkXException`). The empty graph has empty results everywhere, including
  an empty edge cover (CV-001, CV-050, CV-129, CV-167).

### `maximumIndependentSet()`, `independenceNumber()`, `minimumVertexCover()`

* **Result**: the lexicographically least maximum independent set by vertex index. The rule is
  `maximumClique()`'s, and on equal-size sets it is the order of `itertools.combinations` (the
  first sorted index tuple), which is how brute force finds it. Examples: P(4) gives {0, 2} over
  {0, 3} and {1, 3} (CV-011); vertex order, not label order, decides (CV-027).
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
* **Other components: branch and bound, exponential.** First α of the component, by a
  maximum-clique search on the complement's bitset rows with a greedy-colouring bound, in any
  vertex order (degree order is fastest). Then one search for the lexicographically least set of
  exactly α vertices: depth first in ascending index, "include" before "exclude", the same bounds,
  stopping at the first set found (Cliques' `search(exact:)`). Odd cycles, wheels, Petersen
  (CV-015, CV-017, CV-019 – CV-021) and random graphs (CV-037 – CV-039) are the rows here. Mixed graphs combine
  both methods (CV-026, CV-030, CV-032, CV-068).
* **Witness.** `minimumVertexCover()` has no certificate in general. On a bipartite graph its size
  equals `maximumBipartiteMatching().edges.count` (König), which tests assert (CV-062 – CV-066).
* `independenceNumber()` skips the lexicographic search; on bipartite components it is
  n − |matching| with no further pass.

### `minimumVertexCover(bipartition:)` (König)

* **Construction**: NetworkX's. Take a maximum matching (Hopcroft–Karp on the sides, as
  `maximumBipartiteMatching(bipartition:)`) and let Z be the vertices reached from the free left
  vertices by alternating paths: an unmatched edge from left to right, then the matched edge back.
  The cover is (left ∖ Z) ∪ (right ∩ Z). It equals NetworkX `to_vertex_cover` on every row
  (CV-072 – CV-086) and on the stress graphs.
* **It does not depend on the matching.** By brute force it is the one minimum cover with the most
  left vertices (every König row; in `--stress`, a second maximum matching found by augmenting
  paths in reversed vertex order gives the same cover on every bipartite graph). Z ∩ left is the set of
  left vertices that some maximum matching leaves free (Gallai–Edmonds), so Z is determined by the
  graph. This is why the entry point takes no matching.
* **Sides matter.** With `g.bipartition()` each component's least vertex is left, so the
  cover leans to that side. It differs from `minimumVertexCover()` on CV-073, CV-074, CV-076,
  CV-079, CV-081 and CV-085 (each row shows both). A `BipartiteGraph` has its own sides but no
  `Bipartition` value; see open question 2.
* **Parallel edges** are fine (CV-084); a self-loop makes the graph non-bipartite, so it cannot
  have a bipartition.

### `approximateMinimumVertexCover`

* **Procedure** (NetworkX's `min_weighted_vertex_cover`, Bar-Yehuda–Even 1981). cost = weights.
  For each edge {a, b} in position order with neither end in the cover: put in a if cost(a) ≤
  cost(b), else b, where a is the end with the lesser vertex index; subtract the chosen end's cost
  from the other end's. A self-loop puts its vertex in (cost(a) ≤ cost(a)), zeroing its cost
  (CV-089, CV-108).
* **Tie rule = NetworkX's.** NetworkX's `G.edges()` yields each edge from its endpoint that comes
  first in node order, so its `u` is our lesser index, and its `<=` is ours. The outputs are equal
  whenever positions are in `G.edges()` order (by node, then neighbour), which is every row built in
  node order. CV-099 and CV-100 differ only in edge order, and their rows show NetworkX's cover.
  We use positions, as `maximalMatching()` does (MatchingModule MA-025).
* **Guarantee**: weight ≤ 2 · optimum. Every row checks it against the exact weighted optimum, and
  so do the stress graphs with random weights in 0…5. Unweighted (all weights 1) on a loop-free
  graph, the cover lies within the ends of `maximalMatching()` and is often smaller (CV-095:
  the star's hub alone, where the matching has two ends).
* **Weights**: integers exact; floating point follows NetworkX's subtractions in order
  (CV-109). Zero weights are fine (CV-106: weight 0). Negative or NaN weights trap (CV-213,
  CV-214): the local-ratio argument needs w ≥ 0.

### `maximalIndependentSet`

* Vertices in index order; v joins unless it has a self-loop or a neighbour already in the set
  (CV-112 – CV-128). Seeds go in first (CV-117, CV-119). Seeds that are adjacent or looped give
  nil (CV-120, CV-121; NetworkX raises `NetworkXUnfeasible` on the same inputs). Repeated seeds are
  one seed (CV-125).
* **Relation to NetworkX.** NetworkX picks each next vertex at random from the available ones, so
  only validity and maximality compare. Its `dominating_set(G, start_with=s)` performs the same
  greedy pass when its set pops in ascending order, and the rows marked "= NetworkX
  dominating_set" show the outputs agreeing.
* Every maximal independent set is a minimal dominating set on a loop-free graph, so this is also
  the cheap dominating set (NetworkX's `dominating_set`).

### `minimumDominatingSet()`

* **Result**: the lexicographically least minimum dominating set (CV-129 – CV-147), checked as the
  first subset of size γ in combinations order. Components decompose as for independent sets
  (checked: the per-component union agrees on every row).
* **Procedure** (the result does not depend on it): per component, γ by branch and bound
  (branch on an undominated vertex with the fewest possible dominators, over its closed
  neighbourhood), then a lexicographic search in ascending index, "include" first, with budget γ.
  It prunes when some undominated vertex has no undecided or chosen vertex left in its closed
  neighbourhood, and when ⌈undominated / greatest new coverage⌉ exceeds the budget. Exponential;
  intended for small graphs (grid(4,4), Petersen and lcg(14,20,10) are in the catalog).

### `approximateMinimumDominatingSet`

* **Procedure** (NetworkX's): until every vertex is dominated, choose the vertex v not yet chosen
  that minimizes w(v) / k(v), where k(v) is the number of undominated vertices in N[v] (skipping
  k = 0), and on ties the least index. It equals NetworkX on every row (CV-148 – CV-166), since
  NetworkX's `min` over the node-ordered dict keeps the first minimum. Unweighted: the greatest
  k, least index.
* **Guarantee**: weight ≤ H(max |N[v]|) · optimum (Chvátal 1979), checked by brute force
  (CV-160: 5 vertices against the optimum 4).
* **Lazy greedy.** Ratios only grow as vertices become dominated, so a heap of stale keys is a
  lower bound. Pop the least, recompute its key, and take it if it still does not exceed the new
  top (ties by index); otherwise push it back. The output equals the eager scan's.

### `minimumEdgeCover`

* `maximumMatching()`'s edges, then each vertex still uncovered, in vertex order, adds its first
  `incidentEdges` entry (CV-167 – CV-188). With a maximum matching no two uncovered vertices are
  adjacent, so each added edge covers one new vertex and the size is n − ν (Gallai), checked on
  every row against brute force and NetworkX's size. The first entry may be a self-loop (CV-173).
* **Which edges.** Edmonds' matching is MatchingModule's documented procedure, which no library
  shares, so cross-library checks are on size. With
  `minimumEdgeCover(matching: g.maximumBipartiteMatching())` on a `BipartiteGraph` the result
  equals NetworkX `bipartite.min_edge_cover` with Hopcroft–Karp on the same left side, edge for edge
  (CV-185 – CV-188).
* From a matching that is not maximum, the same rule still returns an edge cover. A vertex covered
  by an edge added earlier in the pass is skipped, so two adjacent uncovered vertices share one
  edge. The cover is then not necessarily minimum.

### Checks

Definitions, each O(n + m). Elements may repeat (CV-193, CV-201). A non-vertex or non-position
traps (CV-217, CV-218): a position or vertex outside the graph is a caller bug, as in
MatchingModule's checks, although NetworkX's `is_dominating_set` silently drops non-nodes.
`isDominatingSet` matches NetworkX `is_dominating_set` and `isEdgeCover` matches `is_edge_cover`
(on vertex pairs) on every row.

## Determinism (decision)

| Entry point | Which result | Tests assert |
|---|---|---|
| `maximumIndependentSet()`, `minimumVertexCover()` | Lexicographically least maximum independent set (and its complement) | Exact; brute force; Cliques' `maximumClique()` on the complement; König size on bipartite graphs |
| `independenceNumber()` | α | Exact |
| `minimumVertexCover(bipartition:)` | König's cover: the minimum cover with the most left vertices | Exact; = NetworkX `to_vertex_cover` |
| `approximateMinimumVertexCover` | Bar-Yehuda–Even, positions, lesser index on ties | Exact; = NetworkX where edge orders agree; ≤ 2 · optimum always |
| `maximalIndependentSet` | Greedy in vertex order, seeds first | Exact; independent and maximal |
| `minimumDominatingSet()` | Lexicographically least minimum dominating set | Exact; brute force |
| `approximateMinimumDominatingSet` | Least ratio, least index on ties | Exact; = NetworkX; ≤ H(Δ + 1) · optimum |
| `minimumEdgeCover` | Matching edges, then each uncovered vertex's first edge | Exact; size n − ν; = NetworkX bipartite with Hopcroft–Karp |
| Checks | Definitions | Exact |

The exact optima are defined by a property (lexicographic least), not by a procedure, so the
search can change without changing results. The approximations and the greedy sets are defined by
their procedure, as `maximalMatching()` is.

## Complexity

n vertices, m edges, Δ the greatest degree, c the size of the largest non-bipartite component
left after removing looped vertices.

| Entry point | Time | Extra memory |
|---|---|---|
| `maximumIndependentSet`, `independenceNumber`, `minimumVertexCover` | O(n + m) to split; O(m √n) for bipartite components; exponential in c for the rest | O(n + m), plus c² / 64 words of bitset rows (the complement of one component) |
| `minimumVertexCover(bipartition:)` | O(m √n) | O(n) |
| `approximateMinimumVertexCover` | O(n + m) | n costs and marks |
| `maximalIndependentSet` | O(n + m) | n marks |
| `minimumDominatingSet` | exponential | O(n + m) per search level, iterative |
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
* **Matching.** Hopcroft–Karp on all bipartite components at once (they are disjoint). MatchingModule
  has it in index space; expose its core as a `package` function (`package` is already used
  between GraphProtocols and the algorithm modules) rather than copying it (the final reuse pass
  memo says to dedupe, not to start early, so copying is acceptable too). The alternating reach is
  one queue seeded with every free vertex, tagged with its root's side; the implications are the
  unmatched core edges, scanned from left ends; the greedy is one pass with an explicit stack per
  propagation. `Int32` arrays throughout, `Int` when n ≥ 2³¹.
* **Branch and bound.** Covering cannot use Cliques' `_CliqueSubproblem` (internal to Cliques).
  It gets its own complement-bitset search, which the final reuse pass may merge with Cliques'
  (the same colouring bound and the same flat stack layout). Bitset rows of the component's
  complement among non-looped vertices. Isolated vertices and components of one or two vertices are
  answered without the search.
* **Dominating search.** Bitset closed neighbourhoods per component, an "undominated" bitset per
  depth on a flat stack, no recursion.
* **Bar-Yehuda–Even**: one pass over `edges` with `cost: [W]` read once per vertex from
  `weight` in `vertices` order and `inCover: [Bool]`.
* **Greedy dominating**: `uncovered` counts per vertex, maintained by decrementing N[x] when x
  becomes dominated (O(n + m) total), a binary heap of (key, index) with lazy re-keying
  (PriorityQueueModule's `IndexedPriorityQueue` would make it a `decrease`/`increase`, but keys
  only rise, so a plain heap with stale entries is simpler; add PriorityQueueModule to the
  dependencies only if benchmarks favour it).
* **Edge cover**: `maximumMatching()`'s (or the given) `Matching`'s mate array, then one pass over
  vertices. The result sorts the added positions into the matching's ascending ones by a counting
  pass over edge numbers.
* **Dependencies**: GraphProtocols, BipartiteGraphs (`Bipartition`), MatchingModule (`Matching`,
  `maximumMatching()`, Hopcroft–Karp). `scripts/modules.py` lists GraphProtocols and MatchingModule;
  BipartiteGraphs comes through MatchingModule but is imported directly, so list it.
* **Tests** (public API only, self-contained): every catalog row; `multigraph` rows with an in-file
  `Graph` conformer; generators written out in each file. Properties with swift-property-based:
  `minimumVertexCover()` and `maximumIndependentSet()` partition `vertices`; `isVertexCover`,
  `isIndependentSet` and `isDominatingSet` hold on every result; `maximalIndependentSet()` is
  maximal (adding any vertex breaks independence); on loop-free graphs `maximumIndependentSet()`
  equals the complement graph's `maximumClique()` (Cliques, as a test dependency only); on bipartite
  graphs |`minimumVertexCover()`| = |`minimumVertexCover(bipartition:)`| =
  `maximumBipartiteMatching().edges.count`; approximations within their bounds of the exact
  answers on small graphs; `minimumEdgeCover()!.count` = n − `maximumMatching().edges.count`.
  `just diff` against NetworkX (`min_weighted_vertex_cover`, `min_weighted_dominating_set`,
  `to_vertex_cover`, `bipartite.min_edge_cover`) and igraph (`largest_independent_vertex_sets`) on
  random graphs. `just mutate`: the lattice greedy's choice and propagation direction (CV-029,
  CV-064 – CV-066 and the stress mode catch the swap), the ≤ in Bar-Yehuda–Even (CV-102), the
  ratio tie (CV-163), loop handling (CV-006, CV-031, CV-032, CV-173). `just fuzz`: the exact
  searches against a brute force on random small graphs. Benchmarks against igraph
  (`largest_independent_vertex_sets`, `independence_number`) and NetworkX.

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Self-loops and independence | NetworkX rejects a looped seed but its random choice can take a looped vertex; igraph ignores loops (`is_independent_vertex_set`, `largest_independent_vertex_sets`); ours: a looped vertex is never independent | CV-003, CV-006, CV-114, CV-121, CV-198 |
| Which minimum vertex cover on a bipartite graph | NetworkX `to_vertex_cover`: most left vertices; ours `minimumVertexCover()`: complement of the lexicographically least independent set (`minimumVertexCover(bipartition:)` gives NetworkX's) | CV-064 – CV-066, CV-073 – CV-085 |
| Bar-Yehuda–Even edge order | NetworkX scans `G.edges()` (by node); ours positions | CV-099, CV-100 |
| `maximal_independent_set` | NetworkX random; ours vertex order | MaximalIS rows |
| `dominating_set` | NetworkX pops a Python set (order undocumented); ours has no such entry point (`maximalIndependentSet(containing:)`) | — |
| No edge cover | NetworkX raises `NetworkXException`; ours nil | CV-168, CV-171, CV-187 |
| Check inputs | NetworkX `is_dominating_set` ignores non-nodes; ours traps | CV-217 |
| Multigraphs | NetworkX's approximations run on `MultiGraph` adjacency (keys once), `min_edge_cover` returns pairs; ours names positions | CV-007, CV-175, CV-212 |

## README edits proposed

* **Algorithms table, `Covering` row**: "On `Graph`: `maximumIndependentSet()` and
  `minimumVertexCover()` (exact, the lexicographically least independent set and its complement;
  bipartite components in O(m √n) from a maximum matching), `independenceNumber()`,
  `minimumVertexCover(bipartition:)` (König's cover, NetworkX's), `maximalIndependentSet()`,
  `minimumDominatingSet()` (exact), `approximateMinimumVertexCover(weight:)` (Bar-Yehuda–Even,
  NetworkX's output), `approximateMinimumDominatingSet(weight:)` (greedy set cover, NetworkX's
  output), `minimumEdgeCover()` (Gallai, from a maximum matching), and the checks
  `isVertexCover`, `isIndependentSet`, `isDominatingSet`, `isEdgeCover` (**planned**, phase 1).
  Later: weighted exact covers, reductions, connected domination, enumeration" | results "Vertex
  sets as `[Vertex]` in `vertices` order; edge covers as positions".
* **Terminology**: the four rows under Names.
* **`scripts/modules.py`**: Covering depends on GraphProtocols, BipartiteGraphs, MatchingModule;
  description "Vertex cover, independent set, dominating set, edge cover."

## Open questions

1. **Approximation names.** `approximateMinimumVertexCover` / `approximateMinimumDominatingSet`
   (NetworkX's `approximation` namespace and `approximate_` prefix), or the authors'
   names (`barYehudaEvenVertexCover`, JGraphT; `greedyDominatingSet`)? A second approximation for
   the same problem in phase 2 would force author names.
2. **König's cover on a `BipartiteGraph`.** `minimumVertexCover(bipartition:)` needs a
   `Bipartition`; a `BipartiteGraph` has its own sides but no such value, and `bipartition()`
   recomputes canonical sides that may differ. Options: a `bipartition` property on
   `BipartiteGraph` (BipartiteGraphs), or accept that `BipartiteGraph` users get the lexicographic
   cover. A no-argument overload is ruled out (shadowing).
3. **Kernelization and the tie rule.** Degree-1 and degree-2 reductions, crown reductions and LP
   reductions make large sparse instances tractable (KaMIS), but each picks *a* maximum set. Keep
   the lexicographic rule and add only rule-preserving reductions, or offer a second entry point
   whose result is "a maximum independent set" (documented procedure) for speed?
4. **Heuristics for large graphs.** `approximation.maximum_independent_set` is out. Is a
   min-degree greedy (Graphs.jl `DegreeIndependentSet`) wanted in phase 1, as
   `maximalIndependentSet(order:)` or similar?
5. **`using:` overloads** for `maximalIndependentSet`, as CommunityDetection has (a seeded
   random order, NetworkX's `seed`)? Cheap, but nothing needs it yet.
6. **Certificates for approximations.** Bar-Yehuda–Even's subtracted amounts sum to a lower bound
   L with cover ≤ 2L ≤ 2 · optimum; the greedy set cover has a dual-fitting bound. Return them (a
   result type with `lowerBound`) so callers can see the per-instance ratio, or keep `[Vertex]`?
7. **Exact weighted problems.** Minimum-weight vertex cover on bipartite graphs is a minimum cut;
   should Covering depend on Flows for it in phase 2, or should Flows host it?
8. **Vertex weights by closure** `(Vertex) -> W` (as `pageRank`'s `personalization`). A
   by-index form `(Int) -> W` would skip hashing for graphs without vertex indices. Add it only if
   benchmarks show the hash matters?
9. **`dominationNumber()`** (γ, as `independenceNumber()`): add for symmetry, or wait for a
   caller?
