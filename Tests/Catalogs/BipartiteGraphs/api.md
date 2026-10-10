# BipartiteGraphs: proposed API (phase 1)

A bipartite graph is an undirected graph whose vertices split into two sides, `left` and `right`,
with every edge joining a left vertex to a right vertex. This module has the structure and the
recognition algorithms:

* **`BipartiteGraph<Vertex>`**, a graph class whose sides are part of the value: each vertex is
  inserted on a side and stays there, and every edge goes across. It conforms to `Graph`, can be
  mutated, and builds on `UndirectedAdjacencyList`.
* **Recognition on any `Graph`**: `isBipartite`, `bipartition()` (the two sides, with a documented
  canonical assignment per connected component, or nil), and `findOddCycle()` (the witness when
  the graph is not bipartite, a `Cycle` as Cycles returns).
* **`projectedGraph(onto:)`**, NetworkX's `projected_graph`.

MatchingModule (Hopcroft–Karp, Hungarian) and ColoringModule (two-coloring as a `Coloring`, König
edge coloring) build on it next.

`cases.md` (BP-001 – BP-166, 166 cases) pins the values. `ref.py` computes every row with a model
of this API (an exact port of `UndirectedAdjacencyList`'s swap-remove mutation, wrapped as below)
and checks it independently against NetworkX 3.7. Recognition is checked against `is_bipartite`,
`sets`, `color` and `is_bipartite_node_set`. Odd cycles are checked for validity (a simple cycle of
the graph, odd, in canonical form), since no other library returns the same one. Mutation
sequences are checked against a NetworkX graph built by the same operations, and projections
against `projected_graph`. Run `uv run --quiet --no-project --with networkx==3.7 python3 ref.py`
(under a second); `--write` regenerates the catalog. igraph 1.0's side assignment was probed with
`probe.py` (`uv run --quiet --no-project --with igraph python3 probe.py`).

## Scope

**In, phase 1**

| Entry point | On | Why |
|---|---|---|
| `BipartiteGraph<Vertex>`: `init()`, `init?(left:right:)`, `init?(left:right:edges:)`, `init?(_ graph:)`, `init?(_ graph:left:)` | | The README's Structures row. LEMON's `ListBpGraph` / `SmartBpGraph` (red and blue nodes as part of the graph) is the one major library with a bipartite graph type. The others (NetworkX's `bipartite` node attribute, igraph's `type` vertex attribute, JGraphT's partition sets passed alongside) keep the sides outside the graph. Then every bipartite algorithm has to recheck them or trust them, which is what the README's "a class with an invariant enforces it" rules out |
| `insert(_:on:)`, `insert(edge:)`, `remove(_:)`, `remove(edge:)`, `removeAll(keepingCapacity:)`, `removeAllEdges(keepingCapacity:)`, `reserveCapacity(vertexCount:edgeCount:)` | | Matching and assignment problems grow incrementally (online bipartite matching, augmenting from a previous matching), and LEMON's `ListBpGraph` has `addRedNode`, `addBlueNode`, `addEdge`, `erase`. The mutation set is `UndirectedAdjacencyList`'s, with sides added |
| `left`, `right`, `side(of:)`, `BipartiteSide` | | The README row ("exposes `left` and `right` as collections") |
| `isBipartite` | `Graph` | NetworkX `is_bipartite`, Boost `is_bipartite`, igraph `is_bipartite`, JGraphT `GraphTests.isBipartite`, LEMON `bipartite`. All five have it |
| `bipartition() -> Bipartition<Self>?` | `Graph` | NetworkX `sets` and `color`, Boost `is_bipartite(g, index_map, partition_map)`, igraph `is_bipartite(return_types=True)`, JGraphT `BipartitePartitioning.getPartitioning()`, LEMON `bipartitePartitions`. Costs O(n) memory instead of the copy `BipartiteGraph(graph)` makes, for algorithms that need only the sides (ColoringModule's two-coloring) |
| `findOddCycle() -> Cycle<Vertex, Edges.Index>?` | `Graph` | Boost `find_odd_cycle`. The README's cycle-handling rule: a failed recognition returns the witness. `BipartiteGraph(graph) == nil` exactly when it is non-nil |
| `projectedGraph(onto:) -> UndirectedAdjacencyList<Vertex>` | `BipartiteGraph` | NetworkX `bipartite.projected_graph`, igraph `bipartite_projection`. It is the most used function in NetworkX's bipartite package (affiliation networks, collaboration graphs), and it needs a side, which only this module has |

**NetworkX `bipartite` functions, and where each goes**

| NetworkX | Here | Reason |
|---|---|---|
| `is_bipartite` | `isBipartite` | In |
| `color` | `bipartition()`, `side(of:)` | In. A 0/1 colour map is a bipartition with sides named 0 and 1. The two-colouring as a `Coloring` (a function V → colour index) is ColoringModule's, built from a `Bipartition` |
| `sets` | `bipartition()` with `left`, `right` | In, without `AmbiguousSolution`: a disconnected graph gets the canonical assignment (Semantics) |
| `is_bipartite_node_set` | `BipartiteGraph(graph, left:) != nil` | In, as the failable initializer. A predicate that doesn't copy the graph is open question 4 |
| `projected_graph` | `projectedGraph(onto:)` | In |
| `weighted_projected_graph`, `collaboration_weighted_projected_graph`, `overlap_weighted_projected_graph`, `generic_weighted_projected_graph` | — | **Phase 2, here.** They need a result type for edge weights: a projected graph plus a weight per edge position (shared-neighbour count, Newman's collaboration weight, Jaccard). That type should be designed once for all four, and with igraph's `multiplicity`. Not GraphOperations: projection is defined by a side, and GraphOperations does not depend on BipartiteGraphs |
| `density(B, nodes)` | — | **Deferred** (open question 3). It is `edgeCount / (left.count * right.count)`, but Distances already has `density` on `Graph` (2m / n(n − 1)). A `BipartiteGraph` member named `density` would give a different number from the generic call on the same value, depending on the static type |
| `degrees(B, nodes)` | — | Not offered: it is `left.map(g.degree(of:))` |
| `biadjacency_matrix`, `from_biadjacency_matrix` | — | **SpectralGraphTheory**, with the adjacency and Laplacian matrices (a dense or sparse |L| × |R| matrix, scipy's output type) |
| `complete_bipartite_graph` | — | **NamedGraphs** (Kₘ,ₙ is in its list): a static factory `BipartiteGraph.complete(leftCount:rightCount:)` on `Int` vertices, per the README's generator convention |
| `random_graph`, `gnmk_random_graph`, `configuration_model`, `havel_hakimi_graph`, … | — | **RandomGraphs** |
| `hopcroft_karp_matching`, `maximum_matching`, `eppstein_matching`, `minimum_weight_full_matching` | — | **MatchingModule**, on `BipartiteGraph` |
| `to_vertex_cover` (König) | — | **Covering**, from a `Matching` |
| `latapy_clustering`, `robins_alexander_clustering`, `degree_centrality`, `betweenness_centrality`, `closeness_centrality`, `node_redundancy`, `spectral_bipartivity` | — | Later, in Cliques, Centrality and SpectralGraphTheory. They are NetworkX-only, normalized by side sizes |
| `maximal_extendability`, `edgelist`/`matrix` readers | — | GraphFormats / not planned |

**Also out**

| Not in phase 1 | Reason |
|---|---|
| Recognition on `DirectedGraph` | NetworkX and igraph ignore direction. `digraph.undirected.isBipartite` covers bidirectional graphs (each arc an edge; a 2-cycle becomes a parallel pair, which is bipartite: BP-070). Compressed sparse row isn't bidirectional (open question 5) |
| A bipartite multigraph (parallel edges kept) | `BipartiteGraph` is simple, like `UndirectedAdjacencyList`. König's edge-colouring theorem and transportation problems use multigraphs, but recognition here accepts them on any `Graph`. A multigraph type waits for the Multigraphs module (open question 1) |
| Sides that change as edges arrive (online bipartiteness by union–find with parity) | A different structure: its sides are not fixed, so `side(of:)` could not be stable |
| Shortest odd cycle (odd girth) | Needs a breadth-first search from every vertex. It belongs in Cycles next to `girth()` |

## Summary

```swift
import GraphProtocols
import Walks
import AdjacencyListModule

/// Which side of a bipartite graph a vertex is on.
@frozen public enum BipartiteSide: Hashable, Sendable, CaseIterable, Codable, CustomStringConvertible {
    case left, right
}

/// An undirected graph with two fixed sides, every edge joining a left vertex to a right vertex,
/// so no self-loop. Simple: an edge is inserted once, in either orientation. Each edge is stored
/// left endpoint first, so `edges[e].u` is its left end.
///
/// Storage and mutation costs are `UndirectedAdjacencyList`'s: vertex indices are slots
/// (`vertices` order), edge indices are positions, and a removal moves the last slot or edge into
/// the hole, so orders and positions change after a removal.
@frozen public struct BipartiteGraph<Vertex: Hashable> {
    /// The empty graph.
    public init()
    /// No edges; `left` then `right` in `vertices` order, duplicates within a side dropped.
    /// nil when a vertex is on both sides.
    public init?(left: some Sequence<Vertex>, right: some Sequence<Vertex>)
    /// As above, with these edges in order (a repeat, in either orientation, once).
    /// nil when a vertex is on both sides, or an edge has an endpoint on neither side or both
    /// endpoints on one side (a self-loop included).
    public init?(left: some Sequence<Vertex>, right: some Sequence<Vertex>,
                 edges: some Sequence<UndirectedEdge<Vertex>>)
    /// The graph's vertices (in order), edges (at their positions when the graph has no parallel
    /// edges; repeats dropped), and the canonical sides of `bipartition()`. nil when the graph is
    /// not bipartite; `graph.findOddCycle()` is then the witness.
    public init?(_ graph: some Graph<Vertex>)
    /// The same, with `left` as the left side and every other vertex on the right. nil unless every
    /// edge goes across (NetworkX `is_bipartite_node_set`) or when `left` names a non-vertex.
    public init?(_ graph: some Graph<Vertex>, left: some Sequence<Vertex>)

    /// The left vertices, in insertion order (a removal moves the side's last vertex into the hole).
    public var left: SideVertices { get }
    public var right: SideVertices { get }
    /// O(1). Precondition: `vertex` is a vertex.
    public func side(of vertex: Vertex) -> BipartiteSide

    /// Inserts `vertex` on `side` with no edges. (false, existing) when it is already on `side`.
    /// Precondition: it is not a vertex on the other side.
    @discardableResult
    public mutating func insert(_ vertex: Vertex, on side: BipartiteSide) -> (inserted: Bool, memberAfterInsert: Vertex)
    /// Inserts `edge`, stored left endpoint first. (false, existing) when it is already an edge.
    /// Precondition: both endpoints are vertices, on different sides.
    @discardableResult
    public mutating func insert(edge: UndirectedEdge<Vertex>) -> (inserted: Bool, memberAfterInsert: UndirectedEdge<Vertex>)
    /// Removes `vertex` and its edges; nil if it was not a vertex.
    @discardableResult public mutating func remove(_ vertex: Vertex) -> Vertex?
    /// Removes `edge`, in either orientation; nil if it was not an edge.
    @discardableResult public mutating func remove(edge: UndirectedEdge<Vertex>) -> UndirectedEdge<Vertex>?
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func removeAllEdges(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)

    /// The graph on one side's vertices (in `left` or `right` order), with an edge between two
    /// vertices that share a neighbour, once however many they share. NetworkX `projected_graph`.
    public func projectedGraph(onto side: BipartiteSide) -> UndirectedAdjacencyList<Vertex>

    /// A side's vertices: a value, unaffected by later changes to the graph.
    @frozen public struct SideVertices: RandomAccessCollection { /* Int indices from 0 */ }
}

extension BipartiteGraph: Graph {}            // every requirement forwarded, _withIncidentIndexRows included
extension BipartiteGraph: Equatable, Hashable {} // vertex sets, edge sets, and each vertex's side
extension BipartiteGraph: Sendable where Vertex: Sendable {}
extension BipartiteGraph: Codable where Vertex: Codable {} // decoding re-checks the invariant
extension BipartiteGraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {}

extension Graph {
    /// Whether the vertices split into two sides with every edge across: no odd cycle, so no
    /// self-loop. Parallel edges do not matter. O(n + m).
    public var isBipartite: Bool { get }

    /// The two sides, or nil when the graph is not bipartite. In each connected component the
    /// least vertex (in `vertices` order) is left and the rest alternate, so isolated vertices are
    /// left; each side lists its vertices in `vertices` order. O(n + m).
    public func bipartition() -> Bipartition<Self>?

    /// An odd cycle, or nil when the graph is bipartite: the first one a breadth-first two-colouring
    /// meets (roots in `vertices` order, rows in `incidentEdges` order), closed through the two
    /// vertices' lowest common ancestor in the search tree. A self-loop is an odd cycle of
    /// length 1. In Cycles' canonical form: it starts at its least vertex and leaves through the
    /// lesser of its two edges. Not necessarily a shortest odd cycle. O(n + m).
    public func findOddCycle() -> Cycle<Vertex, Edges.Index>?
}

/// A bipartition of a graph's vertices: the result of `bipartition()`.
@frozen public struct Bipartition<G: Graph>: Equatable, CustomStringConvertible {
    /// Each side's vertices in `vertices` order.
    public var left: ArraySlice<G.Vertex> { get }
    public var right: ArraySlice<G.Vertex> { get }
    /// O(1) after the graph's `vertexIndex(of:)`. Precondition: `vertex` is a vertex.
    public func side(of vertex: G.Vertex) -> BipartiteSide
    /// By vertex index (position in `vertices` without vertex indices). Precondition: in range.
    public func side(ofIndex index: Int) -> BipartiteSide
}
extension Bipartition: Sendable where G: Sendable, G.Vertex: Sendable {}
```

**Why `BipartiteGraph<Vertex>` and not the README's `BipartiteGraph<Base>`.** A structure over a
generic base would need a mutation protocol, and the README rules that out ("There is no protocol
for mutation; mutation belongs to concrete types"). An immutable wrapper over any `Graph` would
lose the mutation that matching workloads need. Trees made the same choice: `Tree<Vertex>`, not
`Tree<Base>`. The storage is an `UndirectedAdjacencyList<Vertex>` plus the side bookkeeping, so the
graph half is code that has already been tested, fuzzed and benchmarked. **Proposed edit to
`scripts/modules.py`:** BipartiteGraphs depends on GraphProtocols, Walks, AdjacencyListModule.

**Why sides are fixed and edges trap instead of failing.** The defining property is local: an edge
is legal iff its endpoints are on different sides, an O(1) test the caller can make with
`side(of:)`. So `insert(edge:)` has a precondition, like an array index, and the initializers from
unchecked input (another graph, decoded data, a list of edges) are failable, as in Trees. `DirectedAcyclicGraph`
is the other case. Its cycle test is global and the caller cannot make it cheaply, so its
insertion fails and returns the witness. A `Bool`-returning `insert(edge:)` that refused a same-side
edge would be ignored under `@discardableResult` and conflated with "already present". Open
question 2 asks whether a non-trapping form is wanted anyway.

**Why both `Bipartition` and `BipartiteGraph(graph)`.** They are not synonyms. `Bipartition` is the
result of an algorithm on any graph: O(n) memory, no hashing on index-based graphs, read-only
(Components' layout). `BipartiteGraph` is a mutable copy with its sides in the value. `bipartition()`
on a 10⁷-edge compressed sparse row costs a breadth-first search and two arrays. `BipartiteGraph(graph)`
re-hashes every vertex and edge.

**Why `BipartiteGraph` has no own `isBipartite`.** The `Graph` extension's `isBipartite` applies,
and it is true. A concrete `var isBipartite: Bool { true }` would be a shadowing member that
generic code never calls (the same shadowing problem as `density` below). The O(n + m) search runs
on a `BipartiteGraph` only when someone asks a known answer, as `isAcyclic` does on a `Tree`.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `BipartiteGraph` | README; LEMON `BpGraph` concept ("bipartite graph"); NetworkX `bipartite` package; igraph `Graph.Bipartite`; Boost docs ("bipartite graph") | `BpGraph` (LEMON): an abbreviation |
| `isBipartite` | NetworkX `is_bipartite`, Boost `is_bipartite`, igraph `is_bipartite`, JGraphT `GraphTests.isBipartite`; LEMON `bipartite` | — |
| `findOddCycle()` | Boost `find_odd_cycle`; Grafluent's `findCycle()`, `findNegativeCycle` | `oddCycle()`: the library's witness functions are `find…` |
| `bipartition()`, `Bipartition` | The term in Diestel, Bondy–Murty and Wikipedia; LEMON `bipartitePartitions`; JGraphT `BipartitePartitioning` | `sets()` (NetworkX): no domain meaning, and Swift's `Set` makes it misleading. `color()` (NetworkX): colouring is ColoringModule's word for a `Coloring` with any number of colours. `partition`: CommunityDetection's `Partition` is any number of parts |
| `left`, `right`, `BipartiteSide` | README; CLRS §25.1 (4th ed., §26.3 in the 3rd), "V = L ∪ R"; Hopcroft–Karp, as it is usually presented; scipy `maximum_bipartite_matching` docs (rows and columns, left and right) | `top`/`bottom` (NetworkX), `red`/`blue` (LEMON), `type` False/True (igraph), partition 0/1 (JGraphT): each is used by one library only, and left/right is what the matching literature, the README and the planned MatchingModule use. `BipartiteSide` follows the standard library's `FloatingPointSign`: a small top-level enum qualified by its domain, so no generic-nested type (`BipartiteGraph<V>.Side` would be a different type per `V`, and `Bipartition` couldn't share it) |
| `side(of:)` | The word for L and R in the matching literature ("the left side") | `isLeft(_:)`: an asymmetric predicate for a symmetric question. `part(of:)`: "part" is the mathematical term, but rare in libraries |
| `insert(_:on:)` | `UndirectedAdjacencyList.insert(_:)` plus the side; LEMON `addRedNode`/`addBlueNode` | `insertLeft(_:)`/`insertRight(_:)`: two names for one operation |
| `projectedGraph(onto:)` | NetworkX `projected_graph(B, nodes)`; igraph `bipartite_projection`; "one-mode projection" (Newman, *Networks*, §6.6) | `projection(onto:)`: "projection" alone means a linear map to most Swift readers, and NetworkX's full name is the one users search for |
| `SideVertices` | Pattern of `Dictionary.Keys`: a nested collection named for what it holds | — |

**Proposed Terminology rows**

* Sides of a bipartite graph: `left`, `right`, `side(of:)`. Used by CLRS and the matching
  literature (NetworkX: top and bottom; LEMON: red and blue; igraph: vertex types). Mathematical
  term: the parts, or colour classes, of a bipartition V = L ⊔ R.
* Witness that a graph is not bipartite: `findOddCycle()`. Used by Boost (`find_odd_cycle`).
  Mathematical term: an odd cycle (König's theorem: bipartite iff no odd cycle).

## Semantics

### Recognition (`isBipartite`, `bipartition()`, `findOddCycle()`)

* **Search.** Breadth-first, components rooted at their least vertex number (vertex index, or
  position in `vertices`), each vertex's row read in `incidentEdges` order. The root is left, and
  each newly reached vertex goes on the side opposite the vertex it was reached from. The first
  row entry whose far end is already on the near end's side is the conflict. All three functions
  are one loop: `isBipartite` and `bipartition()` don't read edge numbers, and `findOddCycle()`
  also keeps the parent edge.
* **Canonical sides.** A connected bipartite graph has exactly two bipartitions, which are swaps
  of each other. Fixing "the least vertex of each component is left" picks one. That is igraph's
  rule (first vertex of each component gets type False, isolated vertices too: `probe.py`), and
  NetworkX's `sets` on a connected graph (X holds the first vertex: BP-015 – BP-084). Each side is
  listed in `vertices` order (BP-018: `left [2, 0, 4]` when `vertices` is `[2, 0, 1, 3, 4]`).
  **Isolated vertices are left** (BP-002, BP-003, BP-053, BP-058). NetworkX's `color` gives them
  0, the side without the first vertex, so it is the one library whose assignment depends on
  degree.
* **Self-loops** are odd cycles of length 1 (BP-007 – BP-009, BP-014, BP-073). NetworkX agrees: a
  vertex with a loop is not an isolate there (`len(G[n]) == 1`), and colouring meets the conflict.
* **Parallel edges** don't affect bipartiteness (BP-010 – BP-012). A parallel pair is an even
  cycle. In an odd cycle the witness uses one copy (BP-013: edges 0, 2, 3, not 1).
* **The odd cycle.** On a conflict across edge e = {v, w}, both v and w are already placed. The
  cycle is the search-tree path from their lowest common ancestor down to v, then e, then the tree
  path from w back up. The two tree paths are disjoint below the ancestor and their depths have
  equal parity, so the cycle is simple and odd. It is then put into Cycles' canonical form:
  rotated to start at its least vertex and turned to leave it through the lesser of its two edge
  positions. Two equal cycles then have equal arrays, and the result can be compared with
  `cycleBasis()` and `findCycle()` output. **It is the first odd cycle the search meets, not a
  shortest one** (BP-052: a C5 is reported although a triangle exists further on).
  Breadth-first search keeps it short in practice: with the conflict at depth d it has length at
  most 2d + 1. Boost's `find_odd_cycle` searches depth-first and returns a different cycle. NetworkX,
  igraph, JGraphT and LEMON return none. So cross-library tests check validity only: odd length,
  no repeated vertex or edge, each edge joining consecutive vertices, `Cycle(vertices:edges:in:)`
  non-nil. The catalog's exact cycles are this API's documented output.
* **Edge orientation and vertex labels** don't matter (BP-005, BP-020). Vertex order does
  (BP-006, BP-027): it numbers the vertices.
* **Directed graphs** go through `.undirected` (BP-069 – BP-074): rows are successors, then
  predecessors. A directed 2-cycle is a parallel pair (BP-070).

### `BipartiteGraph`

* **Invariant.** Every vertex has a side. Every edge has one endpoint on each side, so there are
  no self-loops. At most one edge joins two vertices. Every initializer from unchecked input is
  failable. Mutations trap on violations.
* **Orders.** `vertices` follows insertion order (for `init?(left:right:…)`, `left` then `right`:
  BP-118, so a freshly built graph numbers the left side 0..<|L|). `left` and `right` follow
  insertion order within the side. Removing a vertex moves the last slot into its place (as in
  `UndirectedAdjacencyList`) and the side's last vertex into its place in `left` or `right`
  (BP-128: removing `a` from `[a, b, c]` gives `left [c, b]`, `vertices [y, b, c, x]`). Removing an
  edge moves the last edge into its position (BP-124). Orders and positions are therefore
  unspecified after a removal, as in `UndirectedAdjacencyList`. Equality, hashing and the
  invariant don't depend on them.
* **Edges are stored left endpoint first** (BP-108, BP-121, BP-132), whatever orientation they
  were given in. Bipartite algorithms then read the left end as `edges[e].u` with no lookup.
  `UndirectedEdge` equality ignores orientation, so nothing else changes.
* **`init?(_ graph:)`** keeps the graph's vertex order and assigns the canonical sides. Its edges
  are inserted in position order, so with no parallel edges the positions are the graph's
  positions (BP-085, BP-086) and a weight array indexed by the graph's edge indices still
  applies. With parallel edges each repeat is dropped and later edges move down (BP-089), as in
  `UndirectedAdjacencyList(graph)`. A parallel pair doesn't break the invariant, so it isn't a
  reason for nil. That differs from `Tree(graph)`, where a parallel pair is a cycle. It is nil
  exactly when `graph.findOddCycle()` is non-nil (BP-087, BP-088).
* **`init?(_ graph:left:)`** is NetworkX's `is_bipartite_node_set` as a constructor. It is nil when
  an edge has both ends inside `left` or both outside it (BP-095, BP-096, BP-102, BP-104), or when
  `left` names a non-vertex (BP-100: NetworkX ignores it). Repeats in `left` are one vertex
  (BP-099: NetworkX raises `AmbiguousSolution`). Each component can go either way (BP-101), and
  `left` may be empty or everything when there are no edges (BP-097, BP-098).
* **`init?(left:right:)` / `init?(left:right:edges:)`** are nil when the sides overlap (BP-111), or
  when an edge is inside a side, a self-loop, or has an endpoint on neither side (BP-112 – BP-115).
  Endpoints are not inserted implicitly, because their side would be unknown. That is the one
  departure from `UndirectedAdjacencyList(vertices:edges:)`. Repeats within a side are dropped
  (BP-109), and a repeated edge in either orientation is inserted once (BP-110).
* **`insert(_:on:)`** returns `(false, existing)` when the vertex is already on that side (BP-122),
  and traps when it is on the other one (BP-142). Moving a vertex between sides is not offered:
  remove it and insert it again (BP-132).
* **`insert(edge:)`** requires both endpoints to be vertices, on different sides (BP-143 – BP-147).
  An existing edge, in either orientation, returns `(false, existing)` (BP-123).
* **`remove(_:)`, `remove(edge:)`** return nil for an absent vertex or edge, and never trap
  (BP-126, BP-127, BP-131). A vertex keeps its side when its edges go (BP-138).
* **`side(of:)`** traps for a non-vertex (BP-148, BP-149). It is O(1), one hash lookup.
* **Equality** compares vertex sets, edge sets and sides, not orders (BP-162 – BP-166). The same
  graph with its sides swapped is a different value (BP-163). A `BipartiteGraph` and an
  `UndirectedAdjacencyList` are different types and are not compared.
* **Codable**: `left`, `right`, then the edges as index pairs into `left ++ right`, the same scheme
  as `UndirectedAdjacencyList`. Decoding throws `DecodingError.dataCorrupted` when the data
  violates the invariant, as the Walks types re-check their rules.
* **Description**: `[a, b] | [x]; [a–x, b–x]` (left, right, edges; at most 16 of each), the
  undirected form with the vertex list split at the side boundary.

### `projectedGraph(onto:)`

The vertices are the side's, in `left` or `right` order, isolated ones included (BP-153, BP-159).
Two vertices are joined iff they share at least one neighbour, once however many they share
(BP-158). There are no self-loops (NetworkX's `v != u`). Edges are inserted as discovered: for
each u in side order, for each neighbour w in u's row, for each x in w's row with x ≠ u, insert
{u, x}. So positions are a documented function of the rows. The result matches NetworkX's
`projected_graph` on every row (BP-140, BP-150 – BP-161). It is an `UndirectedAdjacencyList`,
not a view, because the edge set has to be materialized to deduplicate it. igraph's
`bipartite_projection` returns both projections at once. Calling the function twice does the
same, and costs no more.

## Complexity

n vertices, m edges; Δ_S the greatest degree on side S.

| Entry point | Time | Extra memory |
|---|---|---|
| `isBipartite` | O(n + m) | n side bytes + an n-entry queue |
| `bipartition()` | O(n + m) | n sides, n vertices (plus the graph copy `Bipartition` holds, copy-on-write: O(1)) |
| `findOddCycle()` | O(n + m) | as `isBipartite`, plus parent edge and depth per vertex |
| `BipartiteGraph(graph)`, `(graph, left:)` | O(n + m) expected (hashing; plus `|left|`) | the graph |
| `init?(left:right:edges:)` | O(|L| + |R| + edges) expected | the graph |
| `insert(_:on:)`, `insert(edge:)` | O(1) amortized expected | — |
| `remove(edge:)` | O(1) expected | — |
| `remove(_:)` | O(degree + degree of the vertex moved into the slot) | — |
| `side(of:)` | O(1) expected (one hash) | — |
| `projectedGraph(onto: S)` | O(Σ_{u ∈ S} Σ_{w ∈ N(u)} deg(w)) ≤ O(m Δ_{other}) expected | the projection |
| `==`, `hash(into:)` | O(n + m) expected | — |

## Implementation notes (index space)

* **Recognition** is one `_UndirectedRowsAlgorithm` run by `_runOnUndirectedRows`, so it gets
  `_withIncidentIndexRows` storage when the representation has it (`UndirectedAdjacencyList`,
  `Tree`, `BipartiteGraph`) and the generic rows otherwise. `readsEdges` is false for
  `isBipartite` and `bipartition()`. The state is a `[Int8]` side per vertex (−1 unreached) and a
  flat `[Int]` queue of n entries with a head cursor. There is no recursion, and the queue is
  allocated once for all components. `findOddCycle()` adds `parentEdge: [Int]` and `depth: [Int]`.
  It maps edge numbers back to `Edges.Index` and normalizes the cycle the way Cycles'
  `findCycle()` does, through the same `package` helper (moved to Walks or GraphProtocols if it
  is not already shared).
* **Neighbour indices are checked once** against n before use (`precondition`, as
  `_ReachesEveryVertex`). Rows from `_withIncidentIndexRows` are validated by
  `_runOnUndirectedRows`.
* **`Bipartition`** stores the graph copy (for `vertexIndex(of:)`, or `_VertexIdentifiers` when
  the graph has no vertex indices), the side per vertex number as `[BipartiteSide]` (one byte), and one
  `ContiguousArray<Vertex>` holding the left vertices then the right ones, built by a two-bucket
  counting pass. `left` and `right` are slices of it. Equality compares sides by vertex, as
  `Components` compares groups.
* **`BipartiteGraph` storage**: `_graph: UndirectedAdjacencyList<Vertex>`; `_side: [BipartiteSide]`
  per slot; `_left: [Int]`, `_right: [Int]` (slots, in side order); `_sideOffset: [Int]` per slot
  (its index in `_left` or `_right`). Vertex removal swap-removes from the side list first, then
  lets `_graph.remove(_:)` move the last slot into the hole. That relies on
  `UndirectedAdjacencyList`'s documented rule ("moves the last slot into its place"), so the
  wrapper then renames that slot in `_side`, `_sideOffset` and its side list. `ref.py`'s `BG`
  class is this algorithm. Every `Graph` requirement, and `_withIncidentIndexRows`, forwards to
  `_graph`. `SideVertices` holds a copy of `_graph` (one retain) and the slot array, so it is a
  value.
* **Copy-on-write**: four arrays and the inner graph. Each mutation checks uniqueness once (the
  arrays are uniquely held whenever the struct is). `insert(edge:)` checks sides before touching
  storage, so a trapping insertion never copies.
* **`init?(_ graph:)`**: one bipartition run in index space, then
  `reserveCapacity(vertexCount: n, edgeCount: m)`, vertices in order, and edges in position
  order with endpoints swapped to put the left one first. A fast path when the source is an
  `UndirectedAdjacencyList` with no edge needing a swap (copy `_graph` whole) is a benchmark
  question, not an API one.
* **`projectedGraph(onto:)`**: a stamp array `lastSeen[x] == u` per side vertex suppresses repeat
  pairs in O(1) without a hash probe. The pair hash in `UndirectedAdjacencyList.insert(edge:)` is
  then reached once per distinct (u, x), and each pair arrives twice, once from each end.
  Reserve with an upper bound of min(Σ, |S|(|S| − 1)/2).
* **`@inlinable`, `some` generics, `@frozen` storage with `@usableFromInline` internals**, as in
  the rest of the library.
* **Tests** (public API only, self-contained): every catalog row. Rows marked `multigraph` need a
  small in-file `Graph` conformer with rows in position order, since every shipped undirected
  representation is simple. Rows marked `digraph` use `AdjacencyList` and `.undirected`. Odd-cycle
  rows assert the exact cycle **and** validity. Properties with swift-property-based on random
  graphs: `isBipartite == (bipartition() != nil) == (findOddCycle() == nil) == (BipartiteGraph(g) != nil)`.
  Every edge of a bipartite graph crosses `bipartition()`. Every odd cycle returned is valid.
  `BipartiteGraph(g, left: bipartition()!.left) != nil`. Random mutation sequences against a
  model (`UndirectedAdjacencyList` plus a side dictionary) keep `left ∪ right == vertices` and
  every edge across. `just diff` against NetworkX `is_bipartite`, `sets` per component, and
  `projected_graph`. `just mutate` on the side-list bookkeeping (BP-128, BP-139 target it).
  `just fuzz` on mutation sequences. Benchmarks: `isBipartite` on CSR grids and random graphs
  against Boost `is_bipartite` and igraph, and `projectedGraph` against NetworkX on an
  affiliation network.

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Side of isolated vertices | NetworkX `color`: 0 (the side without each component's first vertex). igraph: False, the same side as every component's first vertex. Ours: left, like igraph | BP-002, BP-003, BP-053, BP-058, BP-091 |
| Side assignment on directed input | NetworkX `color` skips a vertex with no successors when choosing a start (`len(G[n]) == 0` tests successors only), so its X side holds the first vertex with an out-arc. igraph ignores direction. Ours: least vertex left, through `.undirected` | BP-074 |
| Disconnected graphs | NetworkX `sets` raises `AmbiguousSolution`. Ours: the canonical assignment | BP-053 – BP-058 |
| `is_bipartite_node_set` | NetworkX raises on repeated nodes (`AmbiguousSolution`), raises `NetworkXError` on a non-bipartite graph, raises `NetworkXNotImplemented` on a directed one, and accepts nodes not in G. Ours: a repeat is one vertex, the others nil | BP-099, BP-100, BP-104 |
| Odd-cycle witness | Boost `find_odd_cycle`: depth-first, its own cycle. NetworkX, igraph, JGraphT, LEMON: none (failure only). Ours: breadth-first, canonical form; cross-library tests check validity | BP-007 – BP-084 (non-bipartite rows) |
| Self-loops | All agree: not bipartite. NetworkX via the colour conflict, Boost because the loop is an odd cycle | BP-007, BP-073 |
| Bipartite graph type | LEMON `BpGraph`: red and blue nodes with separate index spaces (`index(RedNode)`). NetworkX and igraph: attributes on a plain graph. Ours: one slot space plus side lists (open question 6) | — |
| `projected_graph` | NetworkX refuses multigraph input and projects directed graphs through successors. igraph returns both sides. Ours: `BipartiteGraph` is simple and undirected, one side per call | BP-150 – BP-161 |

## README edits proposed

* **Structures row**, replacing the current one:
  `BipartiteGraph<Vertex>` | V = L ⊔ R, every edge between L and R (so no self-loop), simple |
  "Invariant: every initializer from unchecked input is failable (`BipartiteGraph(graph)`,
  `BipartiteGraph(graph, left:)`, `BipartiteGraph(left:right:edges:)`), and `insert(edge:)`
  requires the endpoints on different sides; the witness is `findOddCycle()`. `isBipartite` and
  `bipartition()` on any `Graph`" | "`Graph`, mutable as `UndirectedAdjacencyList` (which it is
  built on), with `insert(_:on:)`; `left`, `right`, `side(of:)`; each edge stored left endpoint
  first; `projectedGraph(onto:)`".
  This removes "a 2-coloring that **throws** with an odd cycle", which contradicts the README's
  own rule that a failed recognition returns the witness and does not throw.
* **Cycle handling table**: add `BipartiteGraph` → "**None** for odd cycles (the invariant
  excludes them); even cycles through Cycles". In the `Graph` row add "`findOddCycle()` in
  BipartiteGraphs (Boost's `find_odd_cycle`)".
* **Algorithms table**: in the `ColoringModule` row, drop "bipartiteness test" (now
  BipartiteGraphs) and add "a two-colouring `Coloring` from a `Bipartition`". Add a
  BipartiteGraphs line to the Structures notes: "`isBipartite`, `bipartition()` (canonical: each
  component's least vertex left), `findOddCycle()` on `Graph` (**planned**, phase 1). Later:
  weighted projections".
* **Terminology**: the two rows under Names.
* **Package layout / `scripts/modules.py`**: BipartiteGraphs depends on GraphProtocols, Walks,
  AdjacencyListModule; description "BipartiteGraph and Bipartition: recognition with odd-cycle
  witnesses, projections."
* **Generators**: NamedGraphs' complete bipartite Kₘ,ₙ becomes
  `BipartiteGraph.complete(leftCount:rightCount:)` once NamedGraphs depends on BipartiteGraphs.

## Open questions

1. **Multigraphs.** Should `BipartiteGraph` keep parallel edges, or should a bipartite multigraph
   wait for the Multigraphs module? König's edge-colouring theorem (Δ colours on a bipartite
   multigraph, ColoringModule) and b-matching want them. Matching and projection don't. Phase 1
   is simple, matching `UndirectedAdjacencyList`. Recognition accepts multigraphs.
2. **Trapping `insert(edge:)`.** The precondition is argued above. Is a non-trapping variant
   wanted for untrusted streams? The failable initializers already cover bulk untrusted input.
3. **`density`.** NetworkX `bipartite.density` is |E| / (|L||R|). A `BipartiteGraph.density`
   member would shadow Distances' `density` on `Graph` with a different number. Options: leave it
   out (it is one line), or give it a distinct established name. NetworkX's is only distinct by
   namespace, and no other library names it.
4. **A predicate for `is_bipartite_node_set`.** `BipartiteGraph(g, left:) != nil` copies the
   graph. A non-copying test would need a name. JGraphT's is `GraphTests.isBipartitePartition(g,
   a, b)`, which suggests `isBipartition(left:)` on `Graph`. Add it in phase 1, or wait until a
   caller needs it?
5. **Directed recognition.** `isBipartite`, `bipartition()` and `findOddCycle()` on `DirectedGraph`
   with direction ignored (NetworkX and igraph do this) would serve compressed sparse row, which
   has no `.undirected`. That needs predecessor rows, built by a counting sort, as Centrality
   does. Wait for a caller?
6. **Side-local indices.** Hopcroft–Karp and the Hungarian method index the left side 0..<|L| and
   the right 0..<|R| (LEMON has separate red and blue indices). A fresh `BipartiteGraph` built
   from sides already numbers the left side first, but removals break that. Should MatchingModule
   renumber internally (O(n) per call, likely negligible), or should `BipartiteGraph` expose
   `sideIndex(of:)` (the offset in `left` or `right`, already stored)?
7. **Moving a vertex between sides.** Only legal when it is isolated, or when its whole component
   flips. Not offered: remove and insert. Revisit if a caller needs component flips.
