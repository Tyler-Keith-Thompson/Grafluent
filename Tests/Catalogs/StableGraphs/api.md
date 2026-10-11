# StableGraphs: proposed API (phase 1)

A directed pseudograph whose vertex and edge positions do not change while the vertex or edge
exists. `DirectedPseudograph` swap-removes: removing an edge moves the last edge into its
position, and removing a vertex moves the last slot into its place. That keeps storage dense,
but every caller holding a position, and every array kept beside the graph, has to follow the
move. FlowNavigation needs three things the swap-remove types cannot give:

1. Edge and vertex identity that survives removals.
2. Vertices, and each vertex's out- and in-edges, iterating in insertion order across removals.
3. Lookups that answer "no" for a stale identity.

This module adds one type, after petgraph's `StableGraph`. Its cases are `cases.md`
(SG-001 – SG-096, 96 rows). `ref.py` holds two models:

- a port of the storage below;
- a plain specification, in which everything sits at a monotone position.

Every state a case or a random sequence reaches is checked port == spec, plus the
`DirectedGraph` and `BidirectionalDirectedGraph` laws with the state-dependent index bounds
described below. `--stress` runs 300 seeded sequences of 60 steps each, checked against:

- a rustworkx 0.18.1 `PyDiGraph`, which is petgraph's `StableGraph`: live vertices, the edge
  multiset, degrees, and every out- and in-row, ours oldest-first against petgraph's newest-first;
- a NetworkX 3.7 `MultiDiGraph`: vertices, the edge multiset and degrees.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/StableGraphs/ref.py [--write] [--stress] [--bench]`.
Two planted model bugs were both caught by the plain run: removing the oldest copy instead of
the newest, and reusing a vacated vertex slot.

## Names

| Name | Decision | Source |
|---|---|---|
| Type | **`StableDirectedGraph<Vertex>`** | petgraph's `StableDiGraph` (= `StableGraph<N, E, Directed>`), spelled as our `DirectedGraph` and `DirectedPseudograph` |
| Undirected type (later) | **`StableUndirectedGraph<Vertex>`**, reserved and not in phase 1 | petgraph's `StableUndirectedGraph` |
| Refinement | **`SparselyIndexedDirectedGraph`** in GraphProtocols (below) | petgraph's `NodeIndexable` / `EdgeIndexable`, against `NodeCompactIndexable` |
| Module | **`StableGraphs`**, plural like `Multigraphs` and `BipartiteGraphs`. No `Module` suffix is needed, because no type is named `StableGraph` | README's package-layout rule |

There is no type named `StableGraph`. In petgraph it is generic over directedness, and in this
library `Graph` means *undirected*, so a directed type called `StableGraph` would read as the
undirected one. `StableDirectedGraph` is unambiguous and follows our own spelling; petgraph's name for exactly this type is `StableDirectedGraph`.
There are no typealiases. The catalog folder keeps the name the plan gave it
(`Tests/Catalogs/StableGraphs`, renamed with the module; open question 1).

## Slot reuse: decided **no reuse, positions are monotone**

petgraph reuses vacated indices. Its free list is LIFO, so `add_node` after `remove_node(1)`
returns 1 again, and edges work the same way (confirmed in rustworkx: in `--stress`, rustworkx
handed out a vacated index 5,265 times). Its `node_indices()` is index order, so a vertex
inserted into a reused slot comes back *in the middle*. In 10,589 of the 18,000 stress states,
rustworkx's vertex order was not insertion order. Its per-node edge lists are singly linked and
iterate **newest first**.

We do not reuse. A new vertex or edge always gets the current `endIndex`, and a removed position
never comes back (SG-015, SG-031). Only `removeAll()` and `removeAllEdges()` reset an
`endIndex` (SG-039, SG-040). The reasons:

1. **Insertion order for free.** With monotone positions, every order is position order, and
   position order *is* insertion order: `vertices`, `edges`, and each out- and in-row
   (`check_laws` asserts this). Reuse would need a second, threaded insertion-order list over
   vertices and over edges to meet requirement 2.
2. **Stale identities are detectable.** With reuse, a caller holding a removed edge's position
   silently gets whichever edge took the slot (the ABA problem). Monotone positions make
   `edges.indices.contains(p)` false forever after a removal, which is what requirement 3 needs.
   It also lets the planned `safe:` lookups return `nil` with no generation counters.
3. **Side arrays stay simple.** A weight array indexed by position never has to clear a reused
   slot. It is sized `edges.endIndex` and appended to on insert.

The cost is memory proportional to *total insertions*, not live elements: 1 tombstoned vertex
slot (about 40 bytes plus the vertex) and 1 edge record (48 bytes) per removed element, until
`removeAll`. FlowNavigation's graphs are small and long-lived. A program with unbounded churn
converts to `DirectedPseudograph(g)` (compacting, SG-072) or rebuilds. A compaction method that
reports where everything moved is phase 2, if a caller needs it (open question 3).

## Storage

```
_vertices:  ContiguousArray<Vertex?> slots (nil = tombstone); _slots: [Vertex: Int]
rows:       four _RowPools (AdjacencyListModule), per slot: out-targets ∥ out-positions,
            in-sources ∥ in-positions, positions increasing; -1 marks a dead entry
_outDead, _inDead: dead entries per row (_outDead -1 at a vertex hole)
_records:   per edge position: source, target (-1 = tombstone), offset in the out-row, in the in-row
_vertexCount, _edgeCount, _firstVertex, _firstEdge (live)
```

**Decided by benchmark: array rows, not linked lists** (open question 6). Each slot's out- and
in-rows are contiguous arrays of edge positions in increasing order with the far ends' slots
beside them (`DirectedPseudograph`'s row pools, order kept). An edge appends to both rows in O(1)
amortized, and its record keeps its offset in each. Removal is lazy: both entries are marked dead
(-1), trailing dead entries are dropped at once, and a row is compacted (fixing its records'
offsets) when more than half of it is dead. So removal is O(1) amortized, a row is never more than
twice its degree, and walking a row is a contiguous read. The bulk initializers lay the rows out in
slot order at the end (one copy of each pool), so a whole-graph pass reads memory in order.

The doubly linked layout first written (LEMON's `ListDigraph` arc lists with tail pointers) met
every removal target, but a row walk is a cache miss per edge on a random graph: weak components
took 28 ms against `DirectedPseudograph`'s 5.2 ms and strong components 72 against 20 ms
(3.6–5.4×). Shifting array rows (`remove(at:)`) fixed the walks but made hub removal quadratic
(a 10⁵-edge star with every other edge removed: 22.5 s in debug). Lazy deletion keeps both.

There is no pair → copies map: `contains(edge:)` and `edges(from:to:)` scan the shorter row,
as petgraph's `find_edge` does in O(e′), because every insert would otherwise pay a hash (open
question 5).

## Signatures

```swift
@frozen public struct StableDirectedGraph<Vertex: Hashable> {
    // Construction
    public init()
    public init(vertices: some Sequence<Vertex>)                       // repeats once
    public init(edges: some Sequence<DirectedEdge<Vertex>>)            // endpoints in first-appearance order
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>)
    public init(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content)
    public init(_ graph: some DirectedGraph<Vertex>)  // vertices in order, edges at 0..<edgeCount in `edges` order;
                                                      // a StableDirectedGraph is returned unchanged, holes and ends kept (SG-075)

    // Counts and membership
    public var vertexCount: Int { get }                                // O(1), live
    public var edgeCount: Int { get }                                  // O(1), live
    public func contains(_ vertex: Vertex) -> Bool                     // O(1) expected
    public func contains(edge: DirectedEdge<Vertex>) -> Bool           // O(min(outDegree(source), inDegree(target)))
    public func edges(from source: Vertex, to target: Vertex) -> EdgesConnecting   // oldest first; empty for a non-vertex
    public func edgeCount(from source: Vertex, to target: Vertex) -> Int           // O(outDegree(source))

    // Neighborhoods (precondition: a vertex)
    public func successors(of vertex: Vertex) -> Neighbors             // O(1) to make, O(degree) to walk
    public func predecessors(of vertex: Vertex) -> Neighbors
    public func outEdges(of vertex: Vertex) -> OutEdges
    public func inEdges(of vertex: Vertex) -> InEdges
    public func outDegree(of vertex: Vertex) -> Int                    // O(1), stored
    public func inDegree(of vertex: Vertex) -> Int                     // O(1), stored
    public func degree(of vertex: Vertex) -> Int                       // O(1); a self-loop counts 2
    public func source(ofEdgeAt position: Int) -> Vertex               // O(1); precondition: live position
    public func target(ofEdgeAt position: Int) -> Vertex

    // Mutation
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)  // O(1) amortized
    public mutating func insert(edge: DirectedEdge<Vertex>) -> Int     // O(1) amortized; returns the old edges.endIndex
    public mutating func remove(_ vertex: Vertex) -> Vertex?           // O(degree); its slot and its edges become holes
    public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>?  // newest copy; O(outDegree(source))
    public mutating func remove(edgeAt position: Int) -> DirectedEdge<Vertex>         // O(1); precondition: live position
    public mutating func removeAllEdges(from source: Vertex, to target: Vertex) -> Int // O(outDegree(source))
    public mutating func removeAll(keepingCapacity: Bool = false)      // resets both endIndexes to 0
    public mutating func removeAllEdges(keepingCapacity: Bool = false) // resets edges.endIndex to 0
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)

    // Collections (values: unaffected by later changes to the graph)
    @frozen public struct Vertices: BidirectionalCollection { // Element Vertex, Index Int (slot), skips holes
        public struct Indices: BidirectionalCollection        // contains(_:) O(1): `vertices.indices.contains(p)`
        public var count: Int { get }                         // O(1)
        public func firstIndex(of vertex: Vertex) -> Int?     // O(1) expected (via _customIndexOfEquatableElement)
    }
    @frozen public struct Edges: BidirectionalCollection {    // Element DirectedEdge<Vertex>, Index Int, skips holes
        public struct Indices: BidirectionalCollection        // contains(_:) O(1)
        public var count: Int { get }                         // O(1)
    }
    @frozen public struct OutEdges: BidirectionalCollection   // Element Int (position), stored row, count O(1);
    @frozen public struct InEdges: BidirectionalCollection    //   Index is the position (increasing), endIndex Int.max
    @frozen public struct Neighbors: BidirectionalCollection  // targets/sources along OutEdges/InEdges, count O(1)
    @frozen public struct EdgesConnecting: Sequence           // positions of one pair's copies, oldest first (filtered OutEdges)
    public var vertices: Vertices { get }
    public var edges: Edges { get }
}

extension StableDirectedGraph: BidirectionalDirectedGraph {}  // Edges.Index == Int; associated types as above
extension StableDirectedGraph: Equatable, Hashable {}         // vertex set + edge multiset; positions and holes ignored
extension StableDirectedGraph: Sendable where Vertex: Sendable {}
extension StableDirectedGraph: Codable where Vertex: Codable {}  // keeps positions and ends (below)
extension StableDirectedGraph: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {}
```

The collection types are `BidirectionalCollection`, not `RandomAccessCollection`: with holes,
`index(_:offsetBy:)` is a scan. `Vertices.Index` and `Edges.Index` are the positions themselves,
and `endIndex` is the high-water mark, the next position handed out (petgraph's `node_bound()` /
`edge_bound()`). So a side array is sized `graph.edges.endIndex`, and `edges.indices.contains(p)`
is the O(1) live-or-stale check (SG-046, SG-047). These are standard `Collection` spellings, so
nothing new is named.

## Positions, indices, and how algorithms see holes

GraphProtocols requires that dense indices are *dense*:

- `vertexIndexBound == vertexCount`, `vertexIndex(of:)` is onto `0..<vertexIndexBound`, and
  `vertices` is in index order;
- likewise `edgeIndexBound == edgeCount` for edges.

A graph with holes cannot satisfy that in O(1). So the bounds are **state-dependent**:

| | No holes (never removed, or reset) | Holes |
|---|---|---|
| `vertexIndexBound` | `vertexCount`; `vertexIndex(of:)` = slot, `vertex(atIndex:)` = slot lookup, `successorIndices` / `predecessorIndices` read the target/source slot straight from the record | `nil` |
| `edgeIndexBound` | `edgeCount`; `edgeIndex(of:)` = position | `nil` |

Vertex holes and edge holes are independent. Removing only edges keeps vertex indices
(SG-062), and removing a vertex usually makes both kinds of hole (SG-027). This satisfies every
law as written: the laws say "a representation with dense indices reports…", and the checks in
`ref.py` assert both directions in every state. A graph that is built and never removed from
runs every algorithm on the dense, array-backed path, at `DirectedPseudograph`'s speed apart
from the linked rows.

With holes, the dense laws stay exactly as they are, and a refinement in GraphProtocols carries
the positions instead (decided after review: "refine the protocols for the stable version"):

```swift
public protocol SparselyIndexedDirectedGraph<Vertex>: BidirectionalDirectedGraph where Edges.Index == Int {
    var vertexPositionBound: Int { get }                 // petgraph's node_bound(): vertices.endIndex
    var edgePositionBound: Int { get }                   // edge_bound(): edges.endIndex
    func vertexPosition(of vertex: Vertex) -> Int
    func vertex(atPosition position: Int) -> Vertex
    func containsVertex(atPosition position: Int) -> Bool   // O(1) liveness
    func containsEdge(atPosition position: Int) -> Bool
    func _numberedRows(outward: Bool, edges: Bool) -> _NumberedRows  // live vertices numbered 0..<n in
}                                                           // `vertices` order, rows in that numbering
```

The name follows petgraph's traits: `NodeIndexable` / `EdgeIndexable` allow holes (a bound
"suitable for the size of a bitmap"), `NodeCompactIndexable` does not; our `vertexIndexBound` is
the compact kind. `_numberedRows` builds, with arrays sized by the bound and no hashing, the
position → number map and flat successor (or predecessor) rows with edge positions beside them,
in O(bound + m). `DirectedGraph._sparselyIndexed()` casts to the refinement once per run when
`vertexIndexBound` is `nil`.

Wired in phase 1 (each keeps its hash path for other index-less graphs):

- GraphProtocols' `_VertexIdentifiers` gains a *numbered* mode (`isDense`, `rows`, predecessor
  rows on first use), so Traversal (breadth- and depth-first search, both engines and the public
  iterators, `breadthFirstLayers`, reachability, bidirectional paths, topological sorts, step
  edges) and ShortestPaths (`_runInIndexSpace` over `_NumberedArcs`) run on the numbered rows;
- Connectivity's `_DenseVertices`: weak components, strong components (Tarjan over the numbered
  rows with integer cursors), condensation, attracting components and dominator trees;
- Flows' directed `_flowEdges`: edge numbers from positions through an array.

Not wired: the undirected helpers (`_vertexNumbering`, `_LazyIncidenceRows`, `_edgeNumbers`)
serve `Graph`, reached only through the `undirected` view, which does not conform; SpanningTrees,
Centrality, Tours, Distances, Cliques and the other undirected modules likewise. Directed modules
with private numberings (Centrality's directed rows, Cycles' directed rows, Tours'
`_DirectedTourRows`, CommunityDetection) still hash once per vertex and once per edge end while
holes exist; each can adopt `_numberedRows` the same way.

`_numberedRows` is called through the existential, so it runs unspecialized: it must not touch a
`Vertex?` per slot (a witness call each, 4.8 ms for 10⁵ slots). Liveness is read from `_outDead`
(-1 at a vertex hole) instead, 1.2 ms for the benchmark graph. Weights stay closures over positions (README question 3), so `w[p]` with `w` sized
`edges.endIndex` is still an array read; `_withSuccessorIndexRows` stays at its `nil` default.
For hot loops, `DirectedPseudograph(g)` still compacts in O(n + m), and edge `k` of the copy is
the `k`th live position (SG-072).

**The README needed an edit**, now made. Its plan entry said "`edgeIndexBound` counts holes, so
algorithms skip them". That would break the `edgeIndexBound == edgeCount` law and every algorithm
that allocates `edgeIndexBound` slots and walks them. It reads "the index bounds are `nil` while
holes exist", and names the refinement.

## Iteration-order guarantees

- `vertices`: increasing position = insertion order. A re-inserted vertex is new and goes last
  (SG-030).
- `edges`: increasing position = insertion order.
- `outEdges(of:)` / `successors(of:)`, `inEdges(of:)` / `predecessors(of:)`: increasing position,
  so the oldest live edge comes first. This is the reverse of petgraph (checked against rustworkx
  in every stress state), and the same as `DirectedPseudograph` before any removal.
- `edges(from:to:)`: oldest first, `.last` the newest. `remove(edge:)` removes the newest copy,
  as `DirectedPseudograph` and NetworkX do.
- A self-loop appears once in its vertex's out-row and once in its in-row (SG-010).

## Traps (precondition failures, as exit tests)

- `successors` / `predecessors` / `outEdges` / `inEdges` / degrees of a non-vertex or a removed
  vertex.
- `source(ofEdgeAt:)`, `target(ofEdgeAt:)`, `edges[p]`, `remove(edgeAt:)` at a hole, a negative
  position or a position past the end.
- `vertices[p]` at a hole.
- `vertex(atIndex:)`, `vertexIndex(of:)` and `edgeIndex(of:)` while the matching bound is `nil`,
  or out of range.
- `index(after: endIndex)`.
- A negative `reserveCapacity`.

`remove(_:)`, `remove(edge:)` and `removeAllEdges(from:to:)` never trap. They return `nil` or 0,
and `contains`, `contains(edge:)`, `edges(from:to:)` and `*.indices.contains` never trap either.

## Codable

```json
{"vertices":[0,2,3],"vertexPositions":[0,2,3],"vertexEnd":4,"edges":[1,0,0,0],"edgePositions":[2,3],"edgeEnd":4}
```

`edges` holds index pairs into `vertices`, as in the simple lists' format. A round trip keeps
every position and both ends, so the next insert gets the same fresh position it would have got
before encoding (SG-083). Errors are `DecodingError.dataCorrupted` for:

- an odd edge list;
- a repeated vertex;
- a positions/values count mismatch;
- positions that do not strictly increase or that reach past the end;
- an endpoint out of range.

## Accommodating the later plan items

- **`safe:` lookups.** Monotone positions make every `safe:` variant a plain membership test, with
  no generation check. Two kinds follow the same pattern:
  - vertex lookups: `successors(safe:)`, `outEdges(safe:)`, `outDegree(safe:)` and the rest are
    `contains(v) ? … : nil`;
  - position lookups: `source(safe:)`, `edges[safe: p]` and the rest are
    `edges.indices.contains(p) ? … : nil`.

  The underlying O(1) checks ship now.
- **Endpoints-required failable insert** (JGraphT `addEdge`). It is `insert(edge:)` with
  `guard contains(source), contains(target) else { return nil }` and no state change. Its
  spelling is chosen repo-wide later.
- **Side arrays → NodeMap/ArcMap or payloads.** Positions that never move are the easiest case:
  a map over positions only has to grow on insert, and a removal never moves a value. The final
  phase can wrap a `ContiguousArray<Value?>` sized `endIndex`, or store payloads in the records
  (petgraph's `StableGraph<N, E>`).

## Performance targets

The instance is the `MultigraphsBenchmarks` one: 10⁵ vertices, 5·10⁵ LCG pairs. The rustworkx
column is petgraph's `StableGraph` behind Python bindings, from `ref.py --bench` (best of 3, this
machine, 2026-10-10). Its bulk calls are mostly Rust, and its nodes are bare indices with no
vertex hashing. The `DirectedPseudograph` column is from `Benchmarks/README.md`.

| Operation | rustworkx (petgraph) | DirectedPseudograph | Target for StableDirectedGraph | Measured (2026-10-10, one run, p50) |
|---|---|---|---|---|
| Build `init(vertices:edges:)` | 28 ms (`add_nodes_from` + `add_edges_from_no_data`) | 162 ms | ≤ 130 ms (no pair map to maintain); stretch ≤ 3× rustworkx | 104 ms against 162 ms (met; the stretch, 84 ms, is not: 3.7× rustworkx, whose nodes are bare indices with no hashing) |
| Remove 10% of vertices | 7.9 ms (`remove_nodes_from`) | 77 ms | ≤ 40 ms | 8.4 ms against 85 ms |
| Remove every other edge by position | 66 ms (Python loop over `remove_edge_from_index`) | (`remove(edge:)` half: 141 ms) | ≤ 25 ms: O(1) amortized each | 21 ms; `remove(edge:)` for half the edges 64 ms against 129 ms |
| Weakly connected components / full traversal | 3.0 ms (`number_weakly_connected_components`) | measure | ≤ 1.5× DirectedPseudograph, no holes | weak components 3.5 ms against 3.8 ms (0.93×); `breadthFirstLayers` 4.2 against 5.0 ms |
| The same, after removing 10% of vertices | 3.2 ms | n/a | ≤ 1.3× the no-hole run (numbered rows); ≤ 1.2× `DirectedPseudograph(g)` plus the run | weak components 3.8 ms (1.09×), `breadthFirstLayers` 5.0 ms (1.21×); compacting first and running: 120 ms |
| Strongly connected components | 46 ms | measure | ≤ 1.5× DirectedPseudograph | 10 ms against 11 ms; with 10% vertex holes 6.6 ms (the compacted copy alone: 9.5 ms) |
| `insert(edge:)` one at a time | 33 ms (Python loop) | measure | ≤ 1.1× `DirectedPseudograph.insert(edge:)` | 92 ms against 161 ms |
| `contains(edge:)` for every edge | n/a | O(1) hash | ≤ 2× DirectedPseudograph at mean degree 5 (row scan) | 72 ms against 47 ms (1.5×) |

The numbered rows of the graph with holes take 1.2 ms to build. A churned graph (10⁴ vertices,
5·10⁴ live edges, 5·10⁵ edges inserted and removed) sums over `edges` in 49 µs against its
compacted copy's 25 µs (the walk is O(`endIndex`) over the 32-byte records), and finds weak
components in 0.44 ms. Measured with other builds loading the machine (load average 3–7), so
compare ratios within the run.

Iteration over `vertices` or `edges` costs O(`endIndex`), not O(live count). The benchmark should
also report a churned graph: insert, then remove, 10× the live size. That shows the cost of
holes the docs will quote.

## Open questions and recommendations

1. **Module and catalog name.** *Recommend* the `StableGraphs` module and renaming this folder
   to match (as `Multigraphs` is). The plan called it "StableGraph". A module named
   `StableGraph` would only need a `Module` suffix if a type shared the name, and none does.
2. **GraphProtocols: sparse index bounds?** Relaxing the dense laws (`vertexIndexBound` above
   `vertexCount`, every index loop skipping holes) was rejected: it touches every algorithm
   module's loops and results. *Decided:* the laws stay, and the `SparselyIndexedDirectedGraph`
   refinement above carries the positions, so index-space helpers number live vertices with
   arrays instead of hashing.
3. **Compaction.** *Recommend* deferring a `compact()`-style method that returns the old → new
   maps until a caller with unbounded churn appears. No established library offers it on a
   stable graph (petgraph converts `StableGraph` into `Graph` instead). `DirectedPseudograph(g)`
   covers the need today.
4. **Should `removeAll()` / `removeAllEdges()` reset `endIndex`?** If they reset, a position from
   before the reset can name a new edge (SG-039). If they keep it, the "never comes back" rule
   holds with no exception. *Recommend reset.* It matches petgraph's `clear` and Swift's
   `removeAll`, and it is the only way to reclaim tombstones short of a new value. Document it as
   "invalidates every position, like assigning `StableDirectedGraph()`".
5. **A pair → copies map** for O(1) `contains(edge:)` and `edgeCount(from:to:)`, as in
   `DirectedPseudograph`. *Recommend not in phase 1.* It costs a hash on every insert and
   remove, petgraph's `find_edge` is O(e′) too, and FlowNavigation's degrees are small. Revisit
   if benchmarks show `contains(edge:)` on hot paths.
6. **Linked rows or position-sorted array rows?** *Decided by benchmark: array rows with lazy
   deletion* (see Storage): linked rows walked 3.6–5.4× slower; shifting array rows made hub
   removal quadratic; lazy deletion with half-dead compaction keeps O(1) amortized removal and
   contiguous walks.
7. **Equality.** Positions are observable, but the README's representation rule ignores insertion
   order and positions, as `DirectedPseudograph` does (SG-078, SG-079). *Recommend following the
   rule.* Callers who care about identities compare `Array(g.edges.indices)` too.
8. **`StableUndirectedGraph`.** *Recommend deferring* until an undirected caller exists. The design
   carries over: one incidence list per vertex, each edge linked twice and a self-loop twice, as
   in `Pseudograph`. It would conform to `Graph`, with the same state-dependent bounds, and its
   stored-rows hook (`_withIncidentIndexRows`) stays nil while holes exist.
9. **Bounds when every element is gone** (SG-025, SG-033). A graph with zero live edges and
   `endIndex` 2 could report `edgeIndexBound == 0`, which is lawful. *Recommend the plain "no
   holes" rule*: it is one predicate, and nothing gains from the special case.
