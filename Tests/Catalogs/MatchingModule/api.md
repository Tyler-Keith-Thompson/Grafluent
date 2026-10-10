# MatchingModule: proposed API (phase 1)

A matching is a set of edges no two of which share an endpoint. This module finds them:

* **One result type, `Matching<G, Weight>`**: the edges (positions, ascending), their total
  weight, `mate(of:)`, `matchedEdge(of:)` and `isPerfect`. Every graph entry point returns it.
* **Maximum-cardinality matching**: Hopcroft–Karp on `BipartiteGraph` and on any `Graph` with a
  `Bipartition` (`maximumBipartiteMatching`), Edmonds' blossom algorithm on any `Graph`
  (`maximumMatching()`), and the greedy maximal matching (`maximalMatching()`).
* **Weighted matching**: maximum-weight matching on any `Graph` with NetworkX's `maxcardinality`
  switch (`maximumWeightMatching(weight:maximumCardinality:)`, Galil's O(n³) blossom algorithm as
  NetworkX implements it), the minimum-weight maximum-cardinality matching
  (`minimumWeightMatching(weight:)`), and on bipartite graphs the minimum-weight full matching
  (`minimumWeightFullMatching(weight:)`, the Hungarian method in scipy's shortest-augmenting-path
  form).
* **Two problems that are not given as a graph**: the assignment problem on a cost matrix
  (`linearSumAssignment`, scipy's `linear_sum_assignment`) and stable marriage on preference lists
  (`stableMatching`, Gale–Shapley).
* **Checks** on any edge set: `isMatching`, `isMaximalMatching`, `isPerfectMatching`.

`cases.md` (MA-001 – MA-238, 238 cases) pins the values. `ref.py` computes every row with a model
of this API and checks it independently: against NetworkX 3.7 (`maximal_matching`, the three
checks, `hopcroft_karp_matching`, `to_vertex_cover`, `max_weight_matching`, `min_weight_matching`,
`minimum_weight_full_matching`), against scipy 1.18.1 (`linear_sum_assignment`), and against brute
force on every small graph, matrix and preference instance. Its `--stress` mode adds 3,000 random
tie-heavy cost matrices with forbidden entries (our Python port of scipy's `rectangular_lsap.cpp`
equals scipy on each one), 400 random bipartite graphs (the Hopcroft–Karp model equals NetworkX's
output exactly, and the König cover equals `to_vertex_cover`), 600 random graphs (Edmonds' size
equals NetworkX's), and 300 random preference instances (stable and proposer-optimal by
enumeration). Run `uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3
ref.py [--stress] [--write]` (a few seconds). A mutant of the Edmonds model
with blossom contraction removed fails MA-109 – MA-113, so those rows guard the blossom code.

## Scope

**In, phase 1**

| Entry point | On | Why |
|---|---|---|
| `Matching<G, Weight>` | | The README's result type ("a set of edges, with `mate(of:)`"). JGraphT's `MatchingAlgorithm.Matching` (`getEdges`, `getWeight`, `isMatched`, `isPerfect`), LEMON's `mate(node)`, `matching(node)`, `matchingSize()`, `matchingWeight()`, Boost's mate map |
| `maximalMatching()` | `Graph` | NetworkX `maximal_matching`, JGraphT `GreedyMaximumCardinalityMatching`, petgraph `greedy_matching`. O(m); the 2-approximation of the minimum vertex cover (Covering) and of the maximum matching |
| `maximumBipartiteMatching()` | `BipartiteGraph` | The README names Hopcroft–Karp. NetworkX `hopcroft_karp_matching` (alias `maximum_matching`), scipy `maximum_bipartite_matching`, igraph `maximum_bipartite_matching`, petgraph `maximum_bipartite_matching`, JGraphT `HopcroftKarpMaximumCardinalityBipartiteMatching`. O(m√n), against O(nm) for Edmonds on the same graph |
| `maximumBipartiteMatching(bipartition:)` | `Graph` | The same on any graph with a `Bipartition` from `bipartition()`: NetworkX takes `top_nodes`, JGraphT the two partition sets. Avoids the hash-based copy `BipartiteGraph(graph)` makes, which matters on a compressed sparse row |
| `maximumMatching()` | `Graph` | The README names Edmonds' blossom. Boost `edmonds_maximum_cardinality_matching`, JGraphT `EdmondsMaximumCardinalityMatching`, LEMON `MaxMatching`, petgraph `maximum_matching` (Gabow). NetworkX has no unweighted general algorithm (`max_weight_matching(maxcardinality=True)` with unit weights is O(n³)) |
| `maximumWeightMatching(weight:maximumCardinality:)` | `Graph` | NetworkX `max_weight_matching(G, maxcardinality, weight)`, LEMON `MaxWeightedMatching`, Boost `maximum_weighted_matching`, JGraphT `KolmogorovWeightedMatching`. The general weighted problem; on bipartite graphs it is the maximum-weight (not necessarily full) bipartite matching too |
| `minimumWeightMatching(weight:)` | `Graph` | NetworkX `min_weight_matching`: the least weight among maximum-cardinality matchings (Christofides' heuristic in Tours needs it: the minimum-weight perfect matching on the odd-degree vertices of a complete graph) |
| `minimumWeightFullMatching(weight:)` | `BipartiteGraph` | NetworkX `bipartite.minimum_weight_full_matching`, JGraphT `KuhnMunkresMinimalWeightBipartitePerfectMatching` (square only), LEMON `MaxWeightedPerfectMatching` (general). The README names the Hungarian method. A full matching covers the smaller side, so it is perfect when the sides are equal |
| `minimumWeightFullMatching(bipartition:weight:)` | `Graph` | As above, on a `Bipartition` |
| `linearSumAssignment(rowCount:columnCount:maximize:cost:)` | cost matrix | scipy `linear_sum_assignment` (rectangular, `maximize`), OR-Tools `LinearSumAssignment`. The assignment problem as people meet it: a dense matrix, often with no graph in sight (tracking, scheduling). The same engine as `minimumWeightFullMatching` |
| `stableMatching(proposerPreferences:reviewerPreferences:)` | preference lists | The README names Gale–Shapley. R `matchingR::galeShapley.marriageMarket`, Python `matching` (`StableMarriage`). Stable marriage is defined by preferences, not by a graph, so it takes two lists of ranked indices |
| `isMatching(_:)`, `isMaximalMatching(_:)`, `isPerfectMatching(_:)` | `Graph` | NetworkX `is_matching`, `is_maximal_matching`, `is_perfect_matching`. For edge sets a caller built; a `Matching` from this module is valid by construction |

**NetworkX `matching` and `bipartite.matching` functions, and where each goes**

| NetworkX | Here | Reason |
|---|---|---|
| `maximal_matching` | `maximalMatching()` | In. Edges scanned in position order (NetworkX scans `G.edges()`, by node: MA-025) |
| `is_matching`, `is_maximal_matching`, `is_perfect_matching` | the three checks | In, on positions instead of vertex pairs, so parallel edges are named exactly |
| `max_weight_matching` | `maximumWeightMatching` | In, with the same output (Determinism) |
| `min_weight_matching` | `minimumWeightMatching` | In |
| `matching_dict_to_set` | — | Not needed: `Matching.edges` is the set, `mate(of:)` the dictionary |
| `hopcroft_karp_matching`, `maximum_matching` | `maximumBipartiteMatching` | In, one name |
| `eppstein_matching` | — | Out: another O(m√n) bipartite algorithm with no advantage over Hopcroft–Karp; NetworkX keeps it for history |
| `minimum_weight_full_matching` | `minimumWeightFullMatching` | In |
| `to_vertex_cover` | — | **Covering**, as `minimumVertexCover()` on `BipartiteGraph` (König's theorem). Covering already depends on MatchingModule, and vertex covers are its result type (README). The construction needs only `mate(of:)` and the sides (Semantics), and the Hopcroft–Karp rows of `cases.md` list the cover for Covering's catalog |

**Also out**

| Not in phase 1 | Reason |
|---|---|
| Gallai–Edmonds decomposition, Tutte–Berge certificate (LEMON `MaxMatching::status` EVEN/ODD/MATCHED, Boost `maximum_cardinality_matching_verifier`, `checked_edmonds_maximum_cardinality_matching`) | Open question 6. It is the certificate of maximality on general graphs: a set S with odd(G − S) − |S| = n − 2|M|. The final search of `maximumMatching()` already labels it (even, odd, unreached), so it is cheap to add, but it needs its own result type. Tests check maximality against brute force and NetworkX instead |
| Micali–Vazirani O(m√n), Gabow's O(nm) general matching | A different search would return a different maximum matching, so it is a new entry point, not a swap (open question 9) |
| Sparse full matching (scipy `min_weight_full_bipartite_matching`, LAPJVsp) | Faster on large sparse graphs, but its tie rule differs from `linear_sum_assignment`, which NetworkX and our full matching follow (open question 4) |
| Maximum-weight bipartite matching by a bipartite algorithm (JGraphT `MaximumWeightBipartiteMatching`) | `maximumWeightMatching` covers it, at O(n³). A faster bipartite path is a benchmark decision |
| b-matching, hospitals/residents (capacities), stable roommates (Irving), ties in preferences, online matching | Phase 2. Hospitals/residents is `stableMatching` with capacities; stable roommates is a different algorithm with no guaranteed solution |
| Matching on `DirectedGraph` | A matching is a set of undirected edges. `digraph.undirected` covers bidirectional graphs |

## Summary

```swift
import GraphProtocols
import BipartiteGraphs

/// A matching in an undirected graph: edges no two of which share an endpoint, as positions in
/// the graph's `edges`, with the sum of their weights (JGraphT's `Matching`: `getEdges`,
/// `getWeight`, `isPerfect`). Never contains a self-loop.
///
/// It keeps a copy of the graph to look vertices up (copy-on-write: O(1) to make; while the
/// result is alive, the next mutation of the original copies the graph).
@frozen public struct Matching<G: Graph, Weight: Comparable & AdditiveArithmetic> {
    /// The matched edges, ascending (in `edges` order).
    public let edges: [G.Edges.Index]
    /// The sum of the matched edges' weights in `edges` order; `edges.count` for the unweighted
    /// entry points (`Weight == Int`).
    public let weight: Weight
    /// Whether every vertex is matched: 2 · `edges.count` == `vertexCount` (true for the empty graph).
    public var isPerfect: Bool { get }
    /// The vertex matched to `vertex`, or nil when it is free. O(1) after the graph's
    /// `vertexIndex(of:)`. Precondition: `vertex` is a vertex.
    public func mate(of vertex: G.Vertex) -> G.Vertex?
    /// The matched edge at `vertex` (among parallel copies, the one in `edges`), or nil.
    public func matchedEdge(of vertex: G.Vertex) -> G.Edges.Index?
    /// By vertex index (position in `vertices` without vertex indices). Precondition: in range.
    public func mate(ofIndex index: Int) -> Int?
}
extension Matching: Equatable {}                          // edges and weight; the graphs are not compared
extension Matching: Hashable where Weight: Hashable {}
extension Matching: Sendable where G: Sendable, G.Vertex: Sendable, Weight: Sendable {}
extension Matching: CustomStringConvertible {}            // {a–b, c–d}

extension Graph {
    /// Greedy: each edge in position order joins the matching when neither end is matched yet.
    /// Self-loops are skipped. Maximal, not necessarily maximum. O(n + m).
    public func maximalMatching() -> Matching<Self, Int>

    /// A maximum-cardinality matching by Edmonds' blossom algorithm: a breadth-first alternating
    /// search from each free vertex in vertex order, augmenting along the first free vertex found.
    /// O(n · m · α(n)).
    public func maximumMatching() -> Matching<Self, Int>

    /// Hopcroft–Karp on `bipartition`'s sides, left vertices in `left` order (NetworkX's output).
    /// Precondition: `bipartition` is this graph's (vertex count; every edge crosses, checked in the
    /// row scan). O(m √n).
    public func maximumBipartiteMatching(bipartition: Bipartition<Self>) -> Matching<Self, Int>

    /// A maximum-weight matching (Galil; NetworkX `max_weight_matching`, the same matching). With
    /// `maximumCardinality`, the heaviest among the maximum-cardinality matchings. Parallel edges:
    /// the heaviest copy (the earliest on ties); self-loops are never weighed. O(n³).
    /// Precondition: no weight is NaN or infinite; weights fit with headroom (Semantics).
    public func maximumWeightMatching<W: SignedInteger>(
        weight: (Edges.Index) -> W, maximumCardinality: Bool = false) -> Matching<Self, W>
    public func maximumWeightMatching<W: FloatingPoint>(
        weight: (Edges.Index) -> W, maximumCardinality: Bool = false) -> Matching<Self, W>

    /// The least weight among maximum-cardinality matchings (NetworkX `min_weight_matching`):
    /// `maximumWeightMatching` on (1 + max weight) − w with `maximumCardinality`. O(n³).
    public func minimumWeightMatching<W: SignedInteger>(weight: (Edges.Index) -> W) -> Matching<Self, W>
    public func minimumWeightMatching<W: FloatingPoint>(weight: (Edges.Index) -> W) -> Matching<Self, W>

    /// A least-weight matching that covers the smaller side, or nil when none exists (NetworkX
    /// `minimum_weight_full_matching`): scipy's `linear_sum_assignment` on the biadjacency matrix,
    /// rows `left`, columns `right`, missing edges forbidden. O(s² t), s ≤ t the side sizes.
    public func minimumWeightFullMatching<W: SignedNumeric & Comparable>(
        bipartition: Bipartition<Self>, weight: (Edges.Index) -> W) -> Matching<Self, W>?

    /// Whether `edges` (positions) is a matching: no position twice, no self-loop, no shared end.
    /// Precondition: every element is a position of `edges`.
    public func isMatching(_ edges: some Sequence<Edges.Index>) -> Bool
    /// A matching with no edge (other than a self-loop) between two free vertices.
    public func isMaximalMatching(_ edges: some Sequence<Edges.Index>) -> Bool
    /// A matching that covers every vertex.
    public func isPerfectMatching(_ edges: some Sequence<Edges.Index>) -> Bool
}

extension BipartiteGraph {
    /// Hopcroft–Karp, left vertices in `left` order. O(m √n).
    public func maximumBipartiteMatching() -> Matching<Self, Int>
    /// As `Graph`'s, rows `left`, columns `right`.
    public func minimumWeightFullMatching<W: SignedNumeric & Comparable>(
        weight: (Int) -> W) -> Matching<Self, W>?
}

/// The assignment problem on a `rowCount` × `columnCount` cost matrix (scipy
/// `linear_sum_assignment`, the same assignment): min(rowCount, columnCount) pairs, no row or
/// column twice, least total cost (greatest with `maximize`). `cost(i, j)` is nil for a forbidden
/// pair (scipy's +inf). nil when no assignment avoids forbidden pairs. O(r² c), r ≤ c the
/// dimensions; `cost` is called O(r² c) times.
/// Precondition: counts ≥ 0; no cost is NaN or infinite.
public func linearSumAssignment<W: SignedNumeric & Comparable>(
    rowCount: Int, columnCount: Int, maximize: Bool = false,
    cost: (_ row: Int, _ column: Int) -> W?) -> LinearSumAssignment<W>?

/// The result of `linearSumAssignment`: scipy's `(row_ind, col_ind)`, by ascending row.
@frozen public struct LinearSumAssignment<Cost: Comparable & AdditiveArithmetic>: Equatable {
    public let rows: [Int]
    public let columns: [Int]
    /// The sum of the assigned costs in `rows` order (OR-Tools `OptimalCost`).
    public let cost: Cost
}
extension LinearSumAssignment: Hashable where Cost: Hashable {}
extension LinearSumAssignment: Sendable where Cost: Sendable {}

/// The proposer-optimal stable matching (Gale–Shapley deferred acceptance). Each list ranks the
/// other side's indices, best first; a pair is acceptable when each lists the other. Unequal
/// sides and incomplete lists allowed. O(total list length).
/// Precondition: indices in range; no index twice in one list.
public func stableMatching(proposerPreferences: [[Int]], reviewerPreferences: [[Int]]) -> StableMatching

@frozen public struct StableMatching: Hashable, Sendable, CustomStringConvertible {
    /// The reviewer matched to `proposer`, or nil. Precondition: in range.
    public func mate(ofProposer proposer: Int) -> Int?
    /// The proposer matched to `reviewer`, or nil. Precondition: in range.
    public func mate(ofReviewer reviewer: Int) -> Int?
}
```

**Why one `Matching` type with a `Weight` parameter.** It follows `SpanningForest<G, Weight>`
(SpanningTrees), whose unweighted entry point returns `SpanningForest<Self, Int>` with the edge
count as its weight, and JGraphT, whose cardinality algorithms return a `Matching` with
`getWeight() == edges.size()`. The alternative, `Matching<G>` with a separate weighted type, is
two names for one concept. There is no `count`: it would duplicate `edges.count` (and `weight` in
the unweighted case).

**Why it holds a graph copy, unlike `SpanningForest`.** `mate(of:)` takes a vertex and returns a
vertex, so it needs `vertexIndex(of:)` and `vertex(atIndex:)`, as `Bipartition` and `Partition` do.
The copy is O(1) (copy-on-write). `edges` positions are still the graph's, valid until it is
mutated.

**Why `maximumBipartiteMatching` and `maximumMatching` are different names.** One overloaded
`maximumMatching()` on `BipartiteGraph` would shadow the `Graph` extension, so generic code
holding a `BipartiteGraph` as `some Graph` would get Edmonds' matching and concrete code
Hopcroft–Karp's: two different matchings for the same call depending on the static type
(BipartiteGraphs' api.md rejected `density` for the same reason). Both names are established:
`maximum_bipartite_matching` (scipy, igraph, petgraph) and `maximum_matching` (petgraph, igraph,
NetworkX).

**Why `linearSumAssignment` and `stableMatching` are free functions on indices.** Neither problem
comes as a graph: the assignment problem is a matrix (scipy's only form), and stable marriage is
two families of rankings, where most pairs that would be edges are irrelevant. Building a
`BipartiteGraph` of r · c hashed edges to call a dense O(r²c) solver costs more than the solve.
The graph form (`minimumWeightFullMatching`) runs the same engine without a matrix.

**Why two overloads (`SignedInteger`, `FloatingPoint`) for the blossom-based weighted entry
points.** Galil's algorithm halves edge slacks (δ₃ = slack / 2, NetworkX's `kslack // 2` or
`/ 2.0`): halving is inherent, since both endpoints' duals move by δ, and no scaling removes it.
`AdditiveArithmetic` has no division; `SignedInteger` and `FloatingPoint` are the two standard
protocols with an exact halving of these values (with integer weights every such slack is even,
NetworkX's `allinteger` path), and they match NetworkX's two code paths. Duals go negative under
`maximumCardinality`, so unsigned types are excluded. The Hungarian engine needs no halving but its
potentials go negative, hence `SignedNumeric & Comparable`, which also makes `maximize` the
negation scipy uses.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `Matching` | README; JGraphT `MatchingAlgorithm.Matching`; every textbook | — |
| `mate(of:)` | README; LEMON `mate(node)`; Boost's mate map (`edmonds_maximum_cardinality_matching(g, mate)`); Edmonds 1965 | `partner(of:)`: no library |
| `matchedEdge(of:)` | LEMON `matching(node)` ("the matching arc incident to the node"); "matched edge" is the standard term (Lovász–Plummer) | `matching(of:)`: reads as a whole matching |
| `isPerfect` | JGraphT `Matching.isPerfect()` | — |
| `maximalMatching()` | NetworkX `maximal_matching` | `greedyMatching()` (petgraph `greedy_matching`): names the method, not the guarantee |
| `maximumMatching()` | petgraph `maximum_matching`, igraph `maximum_matching`, NetworkX `bipartite.maximum_matching` | `edmondsMaximumCardinalityMatching()` (Boost, JGraphT): one algorithm in phase 1, so the problem name, as `minimumSpanningTree` |
| `maximumBipartiteMatching` | scipy, igraph, petgraph `maximum_bipartite_matching` | `hopcroftKarpMatching` (NetworkX): the algorithm's name for the problem's function; a synonym would break the naming policy |
| `maximumWeightMatching(weight:maximumCardinality:)` | NetworkX `max_weight_matching(maxcardinality=)`, Boost `maximum_weighted_matching`, LEMON `MaxWeightedMatching` | `maxWeightMatching`: Swift spells words out (`minimumSpanningTree`) |
| `minimumWeightMatching` | NetworkX `min_weight_matching` | — |
| `minimumWeightFullMatching` | NetworkX `minimum_weight_full_matching`; "full matching" is NetworkX's and scipy's term (`min_weight_full_bipartite_matching`) | `kuhnMunkres…` (JGraphT): requires square, names the algorithm |
| `linearSumAssignment`, `LinearSumAssignment` | scipy `linear_sum_assignment`; OR-Tools `LinearSumAssignment`; "linear sum assignment problem" (Burkard–Dell'Amico–Martello) | `hungarian(…)`: the algorithm is Crouse's shortest augmenting path, not Kuhn's |
| `rows`, `columns`, `cost` | scipy `row_ind`, `col_ind`; OR-Tools `OptimalCost` | — |
| `stableMatching`, `StableMatching` | Gale–Shapley 1962 ("stable marriage"), Gusfield–Irving 1989 *The Stable Marriage Problem: Structure and Algorithms* ("stable matching") | `galeShapley(…)`: the result is algorithm-independent (unique proposer-optimal), so the problem name, as `minimumSpanningTree` |
| proposers, reviewers | R `matchingR` (`proposerUtils`, `reviewerUtils`); Roth's "proposing side" | men/women (1962): dated; suitors/reviewers (Python `matching`): "suitor" is rare |
| `isMatching`, `isMaximalMatching`, `isPerfectMatching` | NetworkX `is_matching`, `is_maximal_matching`, `is_perfect_matching` | — |

**Proposed Terminology rows**

* Edges no two sharing an endpoint: matching, `Matching`. Free vertex: one with no matched edge
  (literature: exposed, unsaturated). `mate(of:)`. Maximal (no edge can be added) vs maximum
  (greatest size); perfect (every vertex matched).
* A matching covering the smaller side of a bipartite graph: full matching (NetworkX, scipy).
  Mathematical term: a matching saturating one side.
* The assignment problem on a cost matrix: `linearSumAssignment` (scipy). Mathematical term: the
  linear sum assignment problem.
* Stable marriage: `stableMatching`, proposers and reviewers. Mathematical term: the stable
  marriage problem (with incomplete lists: SMI).

## Semantics

### `Matching`

* **`edges` ascending** (by edge number, which follows `edges` order), so two matchings with the
  same edges are equal whatever algorithm made them, and the description is stable. The algorithms
  record matched edges per vertex and sort at the end (a counting pass over edge numbers).
* **Self-loops** never belong to a matching (the loop's vertex would be its own mate). NetworkX
  agrees (`is_matching` is false on a loop: MA-042). Every algorithm skips them, and the weighted
  ones never call `weight` for them (SpanningTrees' rule: MA-016, MA-148).
* **Parallel edges.** Unweighted algorithms match the copy they meet first in the row
  (`incidentEdges` order: MA-010, MA-075, MA-096). Weighted algorithms collapse each pair to its heaviest
  copy, earliest on ties (MA-020, MA-021, MA-149), lightest for the minimum full matching. NetworkX
  refuses multigraphs, so these rows are checked by brute force.
* **`isPerfect`** is O(1). The empty graph has a perfect (empty) matching (MA-001, NetworkX
  agrees).
* **Weights** are summed in `edges` order, so a floating-point total is reproducible. Unweighted
  entry points return `weight == edges.count`.

### `maximalMatching()`

Each edge in position order joins when neither end is matched (MA-024 – MA-034). NetworkX scans
`G.edges()`, which lists edges by node and then neighbour, so its result differs when positions
are not in that order (MA-025: ours takes 1–2 listed first; NetworkX takes 0–1 and 2–3). On graphs
built in node order they agree (every other row).

### `maximumBipartiteMatching` (Hopcroft–Karp)

* **Procedure** (NetworkX's `hopcroft_karp_matching`, which is the textbook pseudocode). Each phase
  runs a breadth-first search from every free left vertex (in `left` order) that layers the left
  vertices by alternating distance and stops expanding at the first layer that reaches a free right
  vertex. Then, for each free left vertex in `left` order, a depth-first search tries the row's
  entries in `incidentEdges` order and descends into the mate of the first right neighbour whose
  mate is one layer deeper (or which is free, at the last layer). A vertex whose search fails is
  removed for the phase. Phases repeat until the breadth-first search reaches no free right vertex.
  There is no separate greedy start: the first phase is the greedy matching.
* **Exact parity with NetworkX.** The model equals NetworkX's output on every catalog row and on
  400 random graphs whenever NetworkX iterates its left set in our `left` order (it iterates a
  Python set; for small integers that is ascending). A vertex that succeeds in a phase is never
  entered again in that phase (its layer is fixed below every vertex that could reach it), so the
  iterative form with one row cursor per stack frame is the same procedure and keeps O(m √n).
* **Sides.** On `BipartiteGraph`, `left` order (insertion order). On a `Graph`, the
  `Bipartition`'s `left` (each component's least vertex is left: MA-071 – MA-077). Which side is
  "left" changes the matching, not its size.
* **König cover (for tests and Covering).** From a maximum matching, let Z be the vertices reached
  from free left vertices by alternating paths (unmatched edges left to right, matched edges right
  to left). (L ∖ Z) ∪ (R ∩ Z) is a minimum vertex cover of the same size as the matching (König),
  which certifies maximality. It equals NetworkX `to_vertex_cover` on every row (and the 400 stress
  graphs). Tests build it from `mate(of:)` in a few lines; Covering's `minimumVertexCover()` will
  return it.

### `maximumMatching()` (Edmonds)

* **Procedure.** For each vertex r in vertex order that is still free, one breadth-first
  alternating search rooted at r with a FIFO queue. Popping v (even), each row entry (w, e) in
  `incidentEdges` order: skip a self-loop, an edge inside v's current blossom, or an odd w. If w
  is unlabeled and free, augment along w, v, …, r and end the search. If w is unlabeled and
  matched, w becomes odd and its mate even (queued). If w is even, contract the blossom: find the
  base a (lowest common base of v and w, by walking both base paths alternately), then walk from v
  up to a and from w up to a, relabeling each odd vertex even and queueing it in walk order, and
  setting cross links (Gabow's representation; union–find bases). A root whose search fails stays
  free: no later augmentation can create an augmenting path from it (Edmonds), so one pass
  suffices.
* **Which maximum matching.** The one this procedure produces, pinned by `ref.py`'s model on every
  row (exact edges) and checked for size against NetworkX and brute force. No other library returns
  the same matching (Boost seeds with an extra-greedy matching; NetworkX's weighted algorithm
  chooses by duals), so cross-library tests check validity and size only. The vertex order matters
  (MA-095).
* **Blossoms** are exercised by MA-088 – MA-094, MA-101 and MA-108 – MA-114. MA-108 is the stem
  case: the search from r succeeds only through the blossom; a search without contraction would
  fail there and return different edges of the same size from f.

### `maximumWeightMatching` and `minimumWeightMatching`

* **Same output as NetworkX 3.7.** The implementation is an index-space port of NetworkX's
  `max_weight_matching` (Van Rantwijk's implementation of Galil 1986) with NetworkX's iteration
  orders: vertices in vertex order, neighbours in row order with parallel copies collapsed (first
  appearance), the S-vertex queue popped last-in first-out (NetworkX's `queue.pop()`), blossoms in
  creation order (NetworkX's `blossomdual` dict), and NetworkX's strict `<` in every δ selection.
  Every catalog row is NetworkX's own output (MA-015 – MA-021, MA-115 – MA-156), and its weight (and
  cardinality) is checked by brute force. `just diff` against NetworkX on random graphs is the
  acceptance test for the port.
* **`maximumCardinality: false`** may leave edges out even when they have positive weight, and
  takes zero-weight edges when free (MA-019: NetworkX agrees). Negative edges are never taken
  (MA-017, MA-143). With `true`, negative and zero edges are taken when needed for cardinality
  (MA-018, MA-121, MA-144, MA-145).
* **Integer weights are exact** (the `SignedInteger` overload: NetworkX's `allinteger` path, duals
  start at the greatest weight and every halved slack is even). Floating-point weights follow
  NetworkX's `/ 2.0` path operation for operation, so the same doubles give the same matching
  (MA-119, MA-146).
* **Overflow.** Duals are bounded by a few multiples of the greatest |weight|: proposed
  precondition "every |weight| ≤ W.max / 4, and the total fits", to be confirmed by `just fuzz`
  (open question 2).
* **`minimumWeightMatching`** is `maximumWeightMatching` on c − w with c = 1 + the greatest
  non-loop weight, `maximumCardinality: true`, as NetworkX documents. Differences from NetworkX:
  self-loops are not weighed (NetworkX's maximum includes them), and the vertex order is kept
  (NetworkX rebuilds the graph from its edges, dropping isolated vertices and renumbering: MA-164).
  The catalog rows agree with NetworkX in weight and cardinality, and in edges where the orders
  coincide.

### `minimumWeightFullMatching` and `linearSumAssignment`

* **Same assignment as scipy.** The engine is a port of scipy's `rectangular_lsap.cpp` (Crouse
  2016, shortest augmenting paths with potentials): rows in order; per row, Dijkstra-like scans over
  the remaining columns, which start in **reverse** order and are swap-removed as they are reached;
  among equal shortest-path costs the scan keeps the first, except that an unassigned column
  replaces an equal assigned one; a tall matrix is solved transposed and read back sorted by row;
  `maximize` negates. `ref.py`'s Python port equals scipy on all 33 assignment rows and on 3,000
  random tie-heavy matrices, and every row's cost equals brute force. Constant matrices give the
  identity (MA-196), a scipy design goal (scipy issue 11602).
* **Forbidden pairs**: `cost` returns nil (scipy's +inf). A row or column that cannot be filled
  makes the result nil (MA-202, MA-203; scipy raises "cost matrix is infeasible"). scipy rejects
  +inf under `maximize` (it negates to −inf, "invalid numeric entries"); ours allows nil with
  `maximize`, solved as scipy's own reduction (negate, then minimize).
* **Exact integers.** scipy converts to float64, so an integer matrix beyond 2⁵³ can come back
  wrong (MA-212: scipy returns the costlier assignment). Ours computes in `W`.
* **Floating point** follows scipy's operation order (`minVal + cost − u[i] − v[j]`), so doubles
  give scipy's assignment.
* **Full matching on a graph** is that engine on the |L| × |R| biadjacency matrix with missing
  edges forbidden, rows in `left` order: NetworkX's `minimum_weight_full_matching`, which builds
  exactly this matrix, returns the same edges on all 13 catalog rows where it returns a matching. The matrix is never built: row i's costs are scattered into one scratch row from its
  incident edges, so memory is O(n + m). nil when no full matching exists (MA-167, MA-181; NetworkX
  raises `ValueError`). An empty side gives the empty matching (MA-173, MA-174: NetworkX raises
  `NetworkXError` on an empty left side).
* **`cost` and `weight` are called** O(r² c) times and once per edge, respectively.

### `stableMatching`

* **Output**: the proposer-optimal stable matching, which is unique, so the proposal order does
  not matter (Gale–Shapley; Gusfield–Irving §1.2). Every proposer gets the best reviewer it has in
  any stable matching, and the set of matched agents is the same in all of them (the rural
  hospitals theorem). `ref.py` enumerates every stable matching of every catalog instance and
  checks both (MA-213 – MA-228).
* **Acceptability**: a pair is acceptable iff each lists the other (MA-220). A proposer skips a
  reviewer who does not list it. Lists may be empty or partial, and the sides may differ in size
  (MA-217 – MA-223, MA-228).
* **Roles**: swapping the arguments gives the reviewer-optimal matching of the original (MA-214).
* **Strict preferences** only: a repeat in a list traps (ties make "stable" ambiguous: weakly,
  strongly, super-stable).

### Checks

`isMatching` is false for a repeated position, a self-loop, or two edges sharing an end (MA-035 –
MA-051). Parallel copies are different edges (MA-046, MA-047). `isMaximalMatching` ignores
self-loops when asking whether an edge could be added (MA-044, NetworkX agrees).
`isPerfectMatching` needs every vertex matched, so an isolated vertex rules it out (MA-050).
Positions outside `edges` trap (MA-229): NetworkX returns false for non-edges, but a position is
not a guess at an edge, so it is a precondition, like an array index.

## Determinism (decision)

| Entry point | Which result | Tests assert |
|---|---|---|
| `maximalMatching()` | Greedy in position order | Exact edges (and NetworkX where its edge order agrees) |
| `maximumBipartiteMatching` | NetworkX's Hopcroft–Karp, `left` order | Exact edges and the König cover; `just diff` exact against NetworkX on integer-labelled graphs |
| `maximumMatching()` | This API's Edmonds procedure | Exact edges (model); validity and size against NetworkX and brute force |
| `maximumWeightMatching`, `minimumWeightMatching` | NetworkX 3.7's `max_weight_matching` (with the transform) | Exact edges; weight and cardinality by brute force |
| `minimumWeightFullMatching`, `linearSumAssignment` | scipy 1.18.1's `linear_sum_assignment` | Exact assignment; cost by brute force |
| `stableMatching` | Proposer-optimal (unique) | Exact mates; stability |
| Checks | Definitions | Exact |

Exact outputs are part of the documented behaviour, as in CommunityDetection: a different
procedure would be a new entry point. Every documented output agrees with an established library
except Edmonds' (no library shares one), whose rows are pinned by the model and checked by
validity, size and brute force.

## Complexity

n vertices, m edges; for bipartite inputs s ≤ t the side sizes; r ≤ c the matrix dimensions.

| Entry point | Time | Extra memory |
|---|---|---|
| `maximalMatching()` | O(n + m) | n marks, the result |
| `maximumBipartiteMatching` | O(m √n) | O(n): mates, mate edges, layers, queue, stack |
| `maximumMatching()` | O(n · m · α(n)) | O(n): mates, labels, links, union–find, queue, touched list |
| `maximumWeightMatching`, `minimumWeightMatching` | O(n³) | O(n + m) (blossom child lists, best edges) |
| `minimumWeightFullMatching` | O(s² t + m) | O(n + m) |
| `linearSumAssignment` | O(r² c) | O(r + c) |
| `stableMatching` | O(Σ list lengths) | O(Σ reviewer list lengths) for the rank table |
| `isMatching`, `isPerfectMatching` | O(n + k) | n marks |
| `isMaximalMatching` | O(n + m) | n marks |
| `mate(of:)`, `matchedEdge(of:)` | O(1) after `vertexIndex(of:)` | — |

## Implementation notes (index space)

* **Rows.** Every graph algorithm is an `_UndirectedRowsAlgorithm` run by `_runOnUndirectedRows`,
  reading edges (`readsEdges: true`), so `_withIncidentIndexRows` storage is used where the
  representation has it and lazily copied rows otherwise. Neighbour indices are checked once
  against n, as in BipartiteGraphs.
* **`Matching` storage**: the graph copy (plus `_VertexIdentifiers` when it has no vertex indices),
  `_mate: [Int32]` per vertex number (−1 free; `Int` when n ≥ 2³¹), `_slot: [Int32]` (the matched
  edge's offset in `edges`), `edges`, `weight`. Built from the algorithms' mate-edge arrays by one
  counting pass over edge numbers (ascending) and a map back to `Edges.Index`.
* **Hopcroft–Karp**: left vertices renumbered 0..<s from the side list (O(n), cheaper than a
  hash; this answers BipartiteGraphs' open question 6 without `sideIndex(of:)`), right vertices
  0..<t. Flat arrays `pairLeft`, `pairRight`, `matchedEdge`, `layer` (Int32, with a sentinel for
  "free right"), one queue of s entries, and an explicit DFS stack of (vertex, row cursor). All
  allocated once; each phase resets `layer` only. Row entries whose far end is on the left trap
  (the bipartition does not belong to the graph). No recursion.
* **Edmonds**: `mate`, `mateEdge`, `label: [Int8]`, `link`, `linkEdge`, `base` (union–find with
  path halving), `lcaMark` stamped per call (no clearing), FIFO queue array with head cursor, and a
  touched list so each search resets only the vertices it labelled: O(n · m · α(n)) total instead
  of O(n²) resets. No recursion; augmentation walks links iteratively.
* **Weighted blossom**: a port of NetworkX's code in index space. Blossoms numbered n..<2n from a
  free list, but **iterated in creation order** through an intrusive list (NetworkX's dict order),
  `blossomChildren` and `blossomEdges` as flat pooled arrays, `bestEdge` per vertex/blossom,
  `myBestEdges` per blossom as pooled lists, `allowEdge` as a bit set over collapsed edge numbers,
  and the S-queue as a LIFO array. Parallel edges collapsed up front by a stamp array per vertex
  (first appearance; heaviest copy's position kept). NetworkX's recursive `expandBlossom` /
  `augmentBlossom` become explicit stacks (NetworkX itself converted them to generators for the
  same reason). Integer and floating overloads share one generic body over an internal halving
  closure.
* **Shortest augmenting path (Hungarian)**: arrays `u`, `v`, `shortestPathCosts` (with an
  "unreached" flag instead of +∞, since `W` has no infinity), `path`, `col4row`, `row4col`,
  `remaining`, and SR/SC as stamped Int32 arrays, all allocated once for the run. The graph form
  scatters row i's incident weights into a cost scratch row (forbidden by a stamp) and clears it
  after the row; the transposed case scans right vertices' rows. Operation order as scipy's for
  bitwise-equal doubles.
* **Gale–Shapley**: a rank table (one flat array per reviewer list, prefix offsets), next-proposal
  cursors, a held-proposer array and a stack of free proposers. Preconditions (range, repeats)
  checked while building the rank table.
* **`@inlinable`, `some` generics, `@frozen` storage with `@usableFromInline` internals**, as in the
  rest of the library.
* **Tests** (public API only, self-contained): every catalog row; `multigraph` rows with an in-file
  `Graph` conformer whose rows are in position order; generators (`lcg`, `lcgw`, `lcgb`) written out
  in each file. Properties with swift-property-based: every result `isMatching`; `maximalMatching`
  is maximal; |maximumMatching| == |maximumBipartiteMatching| on bipartite graphs ==
  |maximumWeightMatching(unit, maximumCardinality: true)|; the König cover built in-test from
  `mate(of:)` covers every edge and has the matching's size; `minimumWeightFullMatching` on a
  complete bipartite graph equals `linearSumAssignment` on its matrix; every `stableMatching` has no
  blocking pair. `just diff` against NetworkX (maximal, Hopcroft–Karp, weighted, full) and scipy
  (assignment) on random inputs, exact. `just mutate` on the tie rules (scipy's reversed
  `remaining` and its unassigned-column preference: MA-175, MA-196, MA-206 – MA-211 target them; the
  blossom contraction: MA-108 – MA-113). `just fuzz` on the weighted blossom port (random small
  graphs and weights, compared with brute force) and on overflow bounds. Benchmarks against Boost
  (`edmonds_maximum_cardinality_matching`, `maximum_weighted_matching`), LEMON (`MaxMatching`,
  `MaxWeightedMatching`) and scipy (`linear_sum_assignment`).

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Greedy maximal matching order | NetworkX scans `G.edges()` (by node, then neighbour); ours positions | MA-025 |
| Hopcroft–Karp left order | NetworkX iterates a Python set built from `top_nodes` (hash order); ours `left` order. Equal on integer labels | all Hopcroft–Karp rows |
| `min_weight_matching` | NetworkX weighs self-loops when taking the maximum and rebuilds the graph (isolated vertices dropped, vertices renumbered by edge appearance); ours keeps the graph | MA-164 |
| `minimum_weight_full_matching` on an empty side | NetworkX raises `NetworkXError` ("row_order is empty list"); ours the empty matching | MA-173 |
| No full matching | NetworkX and scipy raise `ValueError`; ours nil | MA-167, MA-181, MA-202, MA-203 |
| Integer cost matrices | scipy rounds to float64 (MA-212 returns the costlier assignment); ours exact | MA-212 |
| Forbidden entries with `maximize` | scipy rejects +inf when maximizing; ours allows nil | — |
| Square-only assignment | JGraphT `KuhnMunkresMinimalWeightBipartitePerfectMatching` requires \|L\| = \|R\|; ours rectangular (full) | MA-169 – MA-171 |
| Multigraphs | NetworkX's matching functions refuse them; ours collapse or scan copies | MA-009, MA-010, MA-020, MA-021, MA-046, MA-047, MA-075, MA-096, MA-149 |
| Which maximum-cardinality matching | Boost seeds with a greedy matching, LEMON and petgraph their own searches; no two agree | Edmonds rows (size checks) |

## README edits proposed

* **Algorithms table, `MatchingModule` row**: "Maximum matching on `Graph` (Edmonds' blossom) and
  on `BipartiteGraph` or a `Bipartition` (Hopcroft–Karp), greedy maximal matching, maximum- and
  minimum-weight matching (Galil, NetworkX's output), minimum-weight full bipartite matching and
  `linearSumAssignment` (scipy's shortest augmenting path), `stableMatching` (Gale–Shapley), and
  the checks `isMatching`, `isMaximalMatching`, `isPerfectMatching` (**planned**, phase 1). Later:
  Gallai–Edmonds decomposition, Micali–Vazirani, sparse full matching, hospitals/residents" |
  results "`Matching` (edge positions, weight, `mate(of:)`, `isPerfect`), `LinearSumAssignment`,
  `StableMatching`".
* **`Covering` row**: add "minimum vertex cover of a bipartite graph from a maximum matching
  (König)".
* **Terminology**: the four rows under Names.
* **`scripts/modules.py`**: MatchingModule depends on GraphProtocols and BipartiteGraphs (no change);
  description "Matching: Hopcroft–Karp, Edmonds' blossom, maximum-weight (Galil), assignment
  (Hungarian, scipy's form), Gale–Shapley."

## Open questions

1. **NetworkX parity for the weighted blossom algorithm.** Porting NetworkX's iteration orders
   (blossom creation order, LIFO queue) makes outputs equal to NetworkX's and `just diff` exact.
   Porting Van Rantwijk's original `mwmatching.py` instead (blossoms by number, reused) is the
   same algorithm with possibly different ties. Parity is proposed; if it proves fragile, tests
   fall back to weight and cardinality.
2. **Weight constraints and overflow.** Two overloads (`SignedInteger`, `FloatingPoint`) for the
   blossom entry points and `SignedNumeric & Comparable` for the Hungarian ones; unsigned and
   `Decimal` weights are not accepted. Is that acceptable, or should there be one internal halving
   protocol? The integer headroom bound (|w| ≤ W.max / 4) is a proposal for fuzzing to confirm.
3. **+∞ as forbidden.** `linearSumAssignment` marks forbidden pairs with nil. A `FloatingPoint`
   overload that also treats +∞ as forbidden would accept scipy matrices unchanged. Add it?
4. **Sparse full matching.** For large sparse bipartite graphs, scipy's
   `min_weight_full_bipartite_matching` (LAPJVsp) beats the dense engine, but returns different
   ties. Phase 2 as a separate entry point, or switch `minimumWeightFullMatching` to it and give up
   NetworkX parity?
5. **`Matching`'s `Weight` parameter.** Kept for `SpanningForest`'s and JGraphT's precedent. The
   cost is a second generic argument on unweighted results (`Matching<G, Int>`). Alternative: a
   plain `Matching<G>` and a `weight(_:)` helper.
6. **Gallai–Edmonds decomposition.** The certificate of maximality for general graphs (LEMON's
   `status`, Boost's verifier). Phase 2, with a result type giving the even, odd and unreached
   vertex sets and the Tutte–Berge barrier?
7. **A `minimumVertexCover()` home.** Decided here: Covering. Revisit if a caller wants the König
   cover without importing Covering.
8. **Stable matching input.** `[[Int]]` index lists. Is a labelled form wanted
   (`[Proposer: [Reviewer]]`), and should hospitals/residents (`capacities:`) share the entry point
   in phase 2?
9. **Promising exact output for `maximumMatching()`.** The documented procedure fixes the
   matching, so switching to Micali–Vazirani later would be a new entry point. Alternatively
   document only "a maximum matching" and keep tests at validity and size.
10. **`maximumBipartiteMatching()` on a plain `Graph`** (computing the bipartition, nil when not
    bipartite). Convenient, but it hides an O(n + m) recognition and a choice of sides. Wait for a
    caller?
