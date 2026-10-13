# GraphOperations test suite

`GraphOperations` has two kinds of operation. The lazy views (`transposedView`, the subgraph views and
`complementView`) hold their base and compute every row from the base's rows. The materialized results
(the line graph, the condensation as a `DirectedAcyclicGraph`, the quotient, the disjoint union and
the join) are built in one step through the construction hooks, on a target type the caller picks.
The API is described in `api.md` in [`Tests/Catalogs/GraphOperations/`](../Catalogs/GraphOperations/).

- The reversal view is `transposedView` (`TransposedView<Base>`), and it needs a bidirectional base.
- The subgraph views renumber the kept vertices densely in base order and keep the base's positions.
- The materialized operations are static factories on any `_DirectedGraphConstruction` or
  `_GraphConstruction` target.
- The condensation becomes a DAG through an initializer, `DirectedAcyclicGraph<Base>(g.condensation())`.
- Inputs with self-loops trap where the result would need one.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
g.transposedView -> TransposedView<G>                     // G: BidirectionalDirectedGraph; .transposedView gives G back
g.inducedSubgraphView(on:), g.spanningSubgraphView(edges:), g.subgraphView(vertices:edges:) -> SubgraphView<G>
g.complementView -> ComplementView<G>                   // DirectedGraph and Graph bases
view.base
Target.lineGraph(of:), Target.quotient(of:by:), Target.disjointUnion(_:_:), Target.join(_:_:)
DirectedAcyclicGraph<Base>(_ condensation: Condensation<G>)
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Reverse positions | The base's, each edge flipped; rows are the base's in-rows in order | GO-003 – GO-007 |
| Double reversal | `g.transposedView.transposedView` is `g`, of `g`'s type | GO-008 |
| Subgraph numbering | Kept vertices in base index order, whatever the listed order; repeats once | GO-013, GO-014 |
| Subgraph positions | The base's, in base `edges` order | GO-017, GO-031 |
| Edge indices | None for an induced subgraph; with an edge set, the rank in base index order among edges whose ends are kept | GO-012, GO-031, GO-041 |
| Edge with a dropped end | Dropped | GO-040, GO-041 |
| Undirected self-loop | Twice in its row, in every view | GO-027, GO-038 |
| Complement | Every pair of distinct vertices the base lacks; rows ascending; loops and parallel edges ignored | GO-048 – GO-061 |
| Complement positions | Index pairs in row-major order; undirected `(u, v)` with `u < v`. The tests read them through `sourceIndex`/`targetIndex` and `endpointIndices` | GO-050, GO-058 |
| Line graph | Vertex k is the edge with `edgeIndex` k, or the k-th position of `edges` | GO-064 – GO-077 |
| Condensation | Vertex i is component i; the order is n−1, …, 0 | GO-078 – GO-084 |
| Quotient | Block i is vertex i; edges merged; none inside a block; an empty block is isolated | GO-085 – GO-091 |
| Union and join | `g`'s vertices, then `h`'s offset by `|V(g)|`; parallel edges merge | GO-095 – GO-104 |
| Traps | A label or a position not in the base; a base without vertex indices; a directed self-loop in a line graph; a self-loop in a union or join; a bad partition | trap rows |

## How values are pinned

Each catalog row builds its base the way the catalog writes it: `AdjacencyList<String>` or
`UndirectedAdjacencyList<String>`, or `DirectedPseudograph` / `Pseudograph` when the row has
parallel edges or self-loops, and a `StableDirectedGraph<String>` with a removed vertex for "Stable
(with holes)". Then it makes the call. A view's state is written out in full:

- every vertex's index both ways, the counts and both bounds;
- the edges in order, with their positions and their ends by label and by index, and every edge
  index when there are any;
- every row by label and by index: out and in for directed views, with the degrees; incident rows,
  neighbours, degrees, opposite vertices and edge indices for undirected ones;
- `contains(edge:)` for every ordered pair of vertices.

A materialized result is checked edge by edge with its positions and rows. The condensation rows
also check the components, the topological order and the base.

The rows that count `hashes` (GO-009, GO-020, GO-062) run a second time on a vertex type, local to
the test, whose `hash(into:)` counts. GO-062's cell counts the index-space rows only: `contains(edge:)`
takes vertices and looks them up, so the test pins the rows at zero and checks the `contains(edge:)`
answers separately.

A trap row runs the trapping call in a child process (an exit test). The same setup then runs in
this process without the fault (the listed vertices or positions that the base has, a valid
partition, or the Stable base without its removal), and its state is checked, so the trap comes
from the call and not from the setup.

The catalog-row files are every file except `GraphOperationsConformanceTests.swift`,
`GraphOperationsPropertyTests.swift`, `ViewCheckedLookupTests.swift` (the views' `checked:` lookups) and `ViewMapTests.swift` (the views as graph adaptors). `swiftgen.py` generated them from `cases.md`; it sits next to
`ref.py` and `cases.md` in [`Tests/Catalogs/GraphOperations/`](../Catalogs/GraphOperations/):

```
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/GraphOperations/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. Then it re-runs each row on
`ref.py`'s model, checked against NetworkX and igraph and the laws, asserts that every value matches the
catalog cell, and writes the test. The precondition file also takes the hand-written exit tests in
`extra_traps.swift`.

## Hand-written files

- **Conformance.** Seeded random directed and undirected pseudographs, with parallel edges and
  self-loops. Every view (and views of views) runs Traversal (BFS and DFS events, layers,
  descendants, ancestors, `hasPath`, topological sort, `findCycle`), Connectivity (strong and weak
  components, the condensation, attracting components; connected components, bridges, articulation
  points and bi-edge-connected components undirected) and ShortestPaths (Dijkstra, Bellman–Ford,
  hop counts). Each result must equal the same call on `DirectedPseudograph(view)` or
  `Pseudograph(view)`, with view position p mapped to its offset in `view.edges`. Views over
  `CompressedSparseRow` and `AdjacencyMatrix` bases get the same check, and the subgraph and
  reverse views are checked to use the base's positions. An edge set over a base without edge
  indices (an `AdjacencyMatrix`, a complement) keeps its sorted positions: the view still has dense
  edge indices by rank, and its rows are filtered by them. The induced subgraph on every vertex,
  over `Pseudograph` and over `UndirectedAdjacencyList` (whose flat rows and edge indices it
  forwards), and the undirected views of directed views get the same checks; the latter's rows are
  ordered out-row first, so components and layers (as sets) are compared. Walking
  `complementView.edges.indices` on 1500 vertices, directed and undirected, must finish within a minute
  and list every cell once, ascending. The materialized operations must agree
  across `CompressedSparseRow`, `AdjacencyList<Int>`, `AdjacencyMatrix` and `StableDirectedGraph<Int>`
  targets, and the condensation DAG over two bases.
- **Properties.** swift-property-based checks, with shrinking, against written-out models: the three
  subgraph views directed and undirected (vertices, positions, every row by label and index, edge
  indices by rank, membership of every pair); the transposed view's laws; the complement, directed and
  undirected, and the complement of the complement; the line graph's definition (also over a view
  without edge indices); the quotient, the disjoint union and the join; the condensation DAG.
- **Views as adaptors.** `ViewMapTests.swift`. Each view's generation is its base's. The
  transposed and subgraph views read the base's edge and vertex maps at the base's positions, and
  the complement reads vertex maps. A subgraph view's `[map, of:]` and `[map, ofEdgeAt:]` trap
  (exit tests) for a dropped vertex, a dropped edge or a dead position, and the `checked:` forms
  throw, directed over `StableDirectedGraph` and undirected over a file-private dense graph with
  maps. A property check compares a subgraph view's reads with a dictionary model under random
  insertions and removals.
- **Boundary law.** A counting vertex type on random pseudographs: every index-space row of every
  view hashes nothing, including the reverse view's degrees and edge ends by index, which it
  forwards to the base.

## Planted bugs

Each bug below, planted in a model of the API, is caught by the listed tests.

| Planted bug | Caught by |
|---|---|
| `transposedView`'s index rows are the base's out-rows | GO-003, GO-005 – GO-007, GO-009; conformance (crash) |
| `transposedView`'s `contains(edge:)` not flipped | GO-003, GO-006, GO-007, GO-009, GO-047 |
| `inducedSubgraphView(on:)` hashing each listed vertex twice | GO-020 |
| Directed subgraph rows ignoring the edge set | GO-029, GO-039, properties |
| `subgraphView(vertices:edges:)` ranking edges whose ends are dropped | GO-040 – GO-042, properties, conformance |
| An induced subgraph that drops a vertex reporting edge indices | GO-011, GO-013 – GO-028, properties |
| An undirected subgraph listing a self-loop once | properties |
| A subgraph's `vertexIndex(of:)` accepting a dropped vertex | GO-023 |
| The directed complement keeping self-loops | GO-049 – GO-062 (10 rows); properties (crash in the line graph of the complement) |
| Undirected complement positions not ordered `(min, max)` | GO-058 – GO-060 |
| The directed line graph accepting a self-loop | GO-070, extra traps |
| The undirected line graph joining only some edges at a vertex | properties |
| `quotient` without the cover check | GO-093 |
| The directed quotient losing direction | GO-088, extra traps, properties |
| `disjointUnion` not offsetting `h` | GO-096, properties |
| The directed join adding one direction only | GO-104, extra traps, properties |
| The condensation DAG in forward order | GO-079, GO-081 – GO-084 |
