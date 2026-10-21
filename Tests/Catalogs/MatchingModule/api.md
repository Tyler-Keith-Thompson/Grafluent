# Matching API

A matching is a set of edges no two of which share an endpoint. The module provides:

* `Matching<G, Weight>`: the edges (positions, ascending), their total weight, `mate(of:)`,
  `matchedEdge(of:)` and `isPerfect`. Every graph entry point returns it.
* Maximum-cardinality matching: Hopcroft–Karp on `BipartiteGraph` and on any `Graph` with a
  `Bipartition` (`maximumBipartiteMatching`), Edmonds' blossom algorithm on any `Graph`
  (`maximumMatching()`), and the greedy maximal matching (`maximalMatching()`).
* Weighted matching: maximum-weight matching on any `Graph`, optionally restricted to
  maximum-cardinality matchings (`maximumWeightMatching(weight:maximumCardinality:)`, Galil's
  O(n³) blossom algorithm), the minimum-weight maximum-cardinality matching
  (`minimumWeightMatching(weight:)`), and on bipartite graphs the minimum-weight full matching
  (`minimumWeightFullMatching(weight:)`, shortest augmenting paths with potentials).
* Two problems not given as a graph: the assignment problem on a cost matrix
  (`linearSumAssignment`) and stable marriage on preference lists (`stableMatching`,
  Gale–Shapley).
* Checks on any edge set: `isMatching`, `isMaximalMatching`, `isPerfectMatching`.

`cases.md` (MA-001 – MA-238) pins the values. `ref.py` computes every row with a model of this API
and checks it against NetworkX 3.7, scipy 1.18.1 and brute force on every small graph, matrix and
preference instance. Its `--stress` mode adds random cost matrices, bipartite graphs, general
graphs and preference instances. Run `uv run --quiet --no-project --with networkx==3.7 --with
scipy==1.18.1 python3 ref.py [--stress] [--write]`.

## Public API

```swift
@frozen public struct Matching<G: Graph, Weight: Comparable & AdditiveArithmetic> {
    public let edges: [G.Edges.Index]   // ascending
    public let weight: Weight           // summed in `edges` order; edges.count when unweighted
    public var isPerfect: Bool { get }  // every vertex matched; true for the empty graph
    public func mate(of vertex: G.Vertex) -> G.Vertex?
    public func matchedEdge(of vertex: G.Vertex) -> G.Edges.Index?
    public func mate(checked vertex: G.Vertex) throws(VertexNotFound) -> G.Vertex?
    public func matchedEdge(checked vertex: G.Vertex) throws(VertexNotFound) -> G.Edges.Index?
    public func mate(ofIndex index: Int) -> Int?
}
// Equatable (edges and weight; the graphs are not compared). Hashable when Weight is. Sendable
// when G, G.Vertex, G.Edges.Index and Weight are. CustomStringConvertible: {a–b, c–d}.

extension Graph {
    public func maximalMatching() -> Matching<Self, Int>
    public func maximumMatching() -> Matching<Self, Int>
    public func maximumBipartiteMatching(bipartition: Bipartition<Self>) -> Matching<Self, Int>
    public func maximumWeightMatching<W: SignedInteger>(
        weight: (Edges.Index) -> W, maximumCardinality: Bool = false) -> Matching<Self, W>
    public func maximumWeightMatching<W: FloatingPoint>(
        weight: (Edges.Index) -> W, maximumCardinality: Bool = false) -> Matching<Self, W>
    public func minimumWeightMatching<W: SignedInteger>(weight: (Edges.Index) -> W) -> Matching<Self, W>
    public func minimumWeightMatching<W: FloatingPoint>(weight: (Edges.Index) -> W) -> Matching<Self, W>
    public func minimumWeightFullMatching<W: SignedNumeric & Comparable>(
        bipartition: Bipartition<Self>, weight: (Edges.Index) -> W) -> Matching<Self, W>?
    public func isMatching(_ edges: some Sequence<Edges.Index>) -> Bool
    public func isMaximalMatching(_ edges: some Sequence<Edges.Index>) -> Bool
    public func isPerfectMatching(_ edges: some Sequence<Edges.Index>) -> Bool
    public func maximumWeightBMatching<W: SignedInteger>(
        bipartition: Bipartition<Self>, capacity: (Vertex) -> Int, weight: (Edges.Index) -> W) -> BMatching<Self, W>
}

@frozen public struct BMatching<G: Graph, Weight: Comparable & AdditiveArithmetic> {
    public let edges: [G.Edges.Index]   // ascending, each at most once
    public let weight: Weight           // summed in `edges` order
    public func degree(of vertex: G.Vertex) -> Int
    public func matchedEdges(of vertex: G.Vertex) -> [G.Edges.Index]   // ascending
    public func degree(checked vertex: G.Vertex) throws(VertexNotFound) -> Int
    public func matchedEdges(checked vertex: G.Vertex) throws(VertexNotFound) -> [G.Edges.Index]
}
// Equatable and Hashable on the edges. Sendable when G, G.Vertex, G.Edges.Index and Weight are.

extension BipartiteGraph {
    public func maximumBipartiteMatching() -> Matching<Self, Int>
    public func maximumWeightBMatching<W: SignedInteger>(capacity: (Vertex) -> Int, weight: (Int) -> W) -> BMatching<Self, W>
    public func minimumWeightFullMatching<W: SignedNumeric & Comparable>(
        weight: (Int) -> W) -> Matching<Self, W>?
}

public func linearSumAssignment<W: SignedNumeric & Comparable>(
    rowCount: Int, columnCount: Int, maximize: Bool = false,
    cost: (_ row: Int, _ column: Int) -> W?) -> LinearSumAssignment<W>?

@frozen public struct LinearSumAssignment<Cost: Comparable & AdditiveArithmetic>: Equatable {
    public let rows: [Int]      // ascending
    public let columns: [Int]   // the column of each row
    public let cost: Cost       // summed in `rows` order
}
// Hashable when Cost is. Sendable when Cost is.

public func stableMatching(proposerPreferences: [[Int]], reviewerPreferences: [[Int]]) -> StableMatching

@frozen public struct StableMatching: Hashable, Sendable, CustomStringConvertible {
    public func mate(ofProposer proposer: Int) -> Int?
    public func mate(ofReviewer reviewer: Int) -> Int?
    public func mate(checkedProposer proposer: Int) throws(VertexNotFound) -> Int?
    public func mate(checkedReviewer reviewer: Int) throws(VertexNotFound) -> Int?
}
```

`Matching` keeps a copy of the graph so `mate(of:)` can map vertices to indices and back. Its
`edges` positions are the graph's, valid until the graph is mutated. The blossom-based weighted
entry points take `SignedInteger` or `FloatingPoint` weights because the algorithm halves edge
slacks; duals go negative under `maximumCardinality`, so unsigned types are excluded. The
assignment engine's potentials go negative too, hence `SignedNumeric & Comparable`.

Nothing is offered on `DirectedGraph`; call `digraph.undirectedView`.

## Semantics

### `Matching`

* `edges` is ascending (by edge number, which follows `edges` order), so two matchings with the
  same edges are equal whatever algorithm made them.
* Self-loops never belong to a matching. Every algorithm skips them, and the weighted ones never
  call `weight` for them (MA-016, MA-148).
* Parallel edges: unweighted algorithms match the copy they meet first in the row (`incidentEdges`
  order: MA-010, MA-075, MA-096). Weighted algorithms collapse each pair to its heaviest copy,
  earliest on ties (MA-020, MA-021, MA-149); the minimum full matching takes the lightest.
* `isPerfect` is O(1). The empty graph has a perfect (empty) matching (MA-001).
* Weights are summed in `edges` order, so a floating-point total is reproducible.

### `maximalMatching()`

Each edge in position order joins when neither end is matched (MA-024 – MA-034).

### `maximumBipartiteMatching` (Hopcroft–Karp)

* Each phase runs a breadth-first search from every free left vertex (in `left` order) that layers
  the left vertices by alternating distance and stops expanding at the first layer that reaches a
  free right vertex. Then, for each free left vertex in `left` order, a depth-first search tries
  the row's entries in `incidentEdges` order and descends into the mate of the first right
  neighbour whose mate is one layer deeper (or which is free, at the last layer). A vertex whose
  search fails is removed for the phase. Phases repeat until the breadth-first search reaches no
  free right vertex. The first phase is the greedy matching.
* The depth-first search is iterative, with one row cursor per stack frame, and keeps O(m √n).
* Sides: on `BipartiteGraph`, `left` order (insertion order). On a `Graph`, the `Bipartition`'s
  `left` (each component's least vertex is left: MA-071 – MA-077). Which side is left changes the
  matching, not its size.
* König cover, for tests: from a maximum matching, let Z be the vertices reached from free left
  vertices by alternating paths (unmatched edges left to right, matched edges right to left).
  (L ∖ Z) ∪ (R ∩ Z) is a minimum vertex cover of the matching's size, which certifies maximality.

### `maximumMatching()` (Edmonds)

* For each vertex r in vertex order that is still free, one breadth-first alternating search
  rooted at r with a FIFO queue. Popping v (even), each row entry (w, e) in `incidentEdges` order:
  skip a self-loop, an edge inside v's current blossom, or an odd w. If w is unlabeled and free,
  augment along w, v, …, r and end the search. If w is unlabeled and matched, w becomes odd and its
  mate even (queued). If w is even, contract the blossom: find the base a (lowest common base of v
  and w, by walking both base paths alternately), then walk from v up to a and from w up to a,
  relabeling each odd vertex even and queueing it in walk order, and setting cross links (Gabow's
  representation; union–find bases). The vertices of a failed search are never on a later
  augmenting path, so later searches skip them.
* The result is the matching this procedure produces, pinned by `ref.py`'s model on every row and
  checked for size against NetworkX and brute force. The vertex order matters (MA-095).
* Blossoms are exercised by MA-088 – MA-094, MA-101 and MA-108 – MA-114. In MA-108 the search from
  r succeeds only through the blossom.

### `maximumWeightMatching` and `minimumWeightMatching`

* Galil's algorithm in Van Rantwijk's formulation, in index space: vertices in vertex order,
  neighbours in row order with parallel copies collapsed (first appearance), the S-vertex queue
  popped last-in first-out, blossoms iterated in creation order, and strict `<` in every δ
  selection. Every catalog row's weight and cardinality is checked by brute force (MA-015 –
  MA-021, MA-115 – MA-156).
* With `maximumCardinality: false` the matching may leave out edges of positive weight and may
  take zero-weight edges (MA-019). Negative edges are never taken (MA-017, MA-143). With `true`,
  negative and zero edges are taken when needed for cardinality (MA-018, MA-121, MA-144, MA-145).
* Integer weights are exact: duals start at the greatest weight and every halved slack is even.
  Floating-point weights halve with `/ 2` (MA-119, MA-146).
* Overflow: every |weight| ≤ `W.max / 8`, and n · |weight| ≤ `W.max / 8` with
  `maximumCardinality`; the total fits in `W`.
* `minimumWeightMatching` is `maximumWeightMatching` on c − w with c = 1 + the greatest non-loop
  weight, `maximumCardinality: true`, reporting the original weights. Self-loops are not weighed
  and the vertex order is kept (MA-164).

### `minimumWeightFullMatching` and `linearSumAssignment`

* Shortest augmenting paths with potentials (Crouse 2016): rows in order; per row, Dijkstra-like
  scans over the remaining columns, which start in reverse order and are swap-removed as they are
  reached; among equal shortest-path costs the scan keeps the first, except that an unassigned
  column replaces an equal assigned one; a tall matrix is solved transposed and read back sorted by
  row; `maximize` negates. Constant matrices give the identity (MA-196). Every row's cost equals
  brute force.
* Forbidden pairs: `cost` returns nil. A row or column that cannot be filled makes the result nil
  (MA-202, MA-203). Forbidden pairs are allowed with `maximize`.
* Integer costs are computed in `W`, so they are exact beyond 2⁵³ (MA-212).
* Floating-point costs follow the operation order `minVal + cost − u[i] − v[j]`.
* The full matching on a graph is that engine on the |L| × |R| biadjacency matrix with missing
  edges forbidden, rows in `left` order. The matrix is never built: row i's costs are scattered
  into one scratch row from its incident edges, so memory is O(n + m). nil when no full matching
  exists (MA-167, MA-181). An empty side gives the empty matching (MA-173, MA-174).
* `cost` is called once per cell and again for each assigned pair; `weight` once per edge, in
  position order.

### `maximumWeightBMatching`

* A maximum-weight b-matching of a bipartite graph: edges, each taken at most once, meeting each
  vertex `v` at most `capacity(v)` times, of greatest total weight. A minimum-cost circulation by
  the network simplex: a source feeds each left vertex up to its capacity, each edge of positive
  weight is an arc of capacity one and cost minus its weight from its left end to its right end,
  each right vertex drains into a sink up to its capacity, and the sink returns to the source;
  the arcs with flow are the matching, reported ascending.
* Edges of weight zero or less are never taken, so the matching is a minimal optimum; self-loops
  are ignored; parallel copies are distinct edges that may both be taken. Capacities of zero give
  the empty matching. `capacity` is called once per vertex in `vertices` order, `weight` once per
  edge in position order. Which optimum is returned among equal-weight ones is unspecified, but
  the same input gives the same result.
* Traps: a negative capacity; a bipartition that is not the graph's; an edge within one side;
  capacities whose sum overflows `Int`; a weight outside the network simplex's bound (the
  minimum-cost flow's preconditions).
* Checked against brute force over edge subsets in the tests and the fuzz driver, and against
  the linear program (integral on bipartite graphs) in the differential tests.

### `stableMatching`

* The proposer-optimal stable matching, which is unique, so the proposal order does not matter
  (Gale–Shapley; Gusfield–Irving §1.2). Every proposer gets the best reviewer it has in any stable
  matching, and the set of matched agents is the same in all of them (the rural hospitals
  theorem). `ref.py` enumerates every stable matching of every catalog instance and checks both
  (MA-213 – MA-228).
* A pair is acceptable iff each lists the other (MA-220). Lists may be empty or partial, and the
  sides may differ in size (MA-217 – MA-223, MA-228).
* Swapping the arguments gives the reviewer-optimal matching of the original (MA-214).
* Preferences are strict: a repeat in a list traps.

### Checks

`isMatching` is false for a repeated position, a self-loop, or two edges sharing an end (MA-035 –
MA-051). Parallel copies are different edges (MA-046, MA-047). `isMaximalMatching` ignores
self-loops when asking whether an edge could be added (MA-044). `isPerfectMatching` needs every
vertex matched, so an isolated vertex rules it out (MA-050). Positions outside `edges` trap
(MA-229).

## Determinism

| Entry point | Which result | Tests assert |
|---|---|---|
| `maximalMatching()` | Greedy in position order | Exact edges |
| `maximumBipartiteMatching` | Hopcroft–Karp as above, `left` order | Exact edges and the König cover |
| `maximumMatching()` | The Edmonds procedure above | Exact edges; validity and size against brute force |
| `maximumWeightMatching`, `minimumWeightMatching` | The weighted blossom procedure above | Exact edges; weight and cardinality by brute force |
| `minimumWeightFullMatching`, `linearSumAssignment` | The shortest augmenting path procedure above | Exact assignment; cost by brute force |
| `stableMatching` | Proposer-optimal (unique) | Exact mates; stability |
| Checks | Definitions | Exact |

## Complexity

n vertices, m edges; for bipartite inputs s ≤ t the side sizes; r ≤ c the matrix dimensions.

| Entry point | Time | Extra memory |
|---|---|---|
| `maximalMatching()` | O(n + m) | n marks, the result |
| `maximumBipartiteMatching` | O(m √n) | O(n) |
| `maximumMatching()` | O(n · m · log n) | O(n) |
| `maximumWeightMatching`, `minimumWeightMatching` | O(n³) | O(n + m) |
| `minimumWeightFullMatching` | O(s² t + m) | O(n + m) |
| `linearSumAssignment` | O(r² c) | O(r c) |
| `stableMatching` | O(Σ list lengths) | O(Σ reviewer list lengths) |
| `isMatching`, `isPerfectMatching` | O(n + k) with edge indices, O(n + m) without; k = edges checked | n marks |
| `isMaximalMatching` | O(n + m) | n marks |
| `mate(of:)`, `matchedEdge(of:)` | O(1) after `vertexIndex(of:)` | — |
