# DirectedAcyclicGraph test suite

`DirectedAcyclicGraphModule` has one type, `DirectedAcyclicGraph<Base>`. It wraps a mutable directed
representation, rejects any edge that would close a cycle, and keeps a topological order of its
vertices current under insertions and removals, using Pearce–Kelly as JGraphT and petgraph do. Every
read member forwards to the base. The tests come from the proposed API (`api.md` in
[`Tests/Catalogs/DirectedAcyclicGraph/`](../Catalogs/DirectedAcyclicGraph/), phase 1). Its open
questions are decided as recommended, with these exceptions:

- **No `EdgeInsertion` type.** `insert(edge:) -> Edges.Index?` returns the new position, or `nil`
  when the edge would close a cycle. `insert(safe:)` also returns `nil`, changing nothing, when an
  endpoint is missing.
- **The witness for a rejected u→v** is Traversal's existing query
  `bidirectionalShortestPath(from: v, to: u)`. The tests check that it exists and is a genuine
  shortest path. They do not pin a particular depth-first path.
- **`Base: MutableDirectedGraph`**, a GraphProtocols protocol after BGL's `MutableGraph`. Its
  phase-1 conformers are `AdjacencyList`, `DirectedPseudograph` and `StableDirectedGraph`. The tests
  use only these three concrete bases and never name the protocol or its hooks.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
struct DirectedAcyclicGraph<Base: MutableDirectedGraph>: BidirectionalDirectedGraph,
        SparselyIndexedDirectedGraph (Base: SparselyIndexedDirectedGraph), Equatable, Hashable, Codable,
        Sendable, CustomStringConvertible, CustomDebugStringConvertible
    init(), init(vertices:)                                          // order = vertices order
    init?(edges:), init?(vertices:edges:), init?(_ base: Base), init?(_ graph:), init?(@DirectedGraphBuilder _:)
    var base: Base; var topologicalOrder: TopologicalOrder           // RandomAccessCollection, Index 0..<n
    topologicalPosition(of:), topologicalPosition(safe:)
    successors(safe:), predecessors(safe:), outEdges(safe:), inEdges(safe:), outDegree(safe:), inDegree(safe:)
    insert(_:) -> (inserted:, memberAfterInsert:)                    // placed last
    insert(edge:) -> Edges.Index?, insert(safe:) -> Edges.Index?     // nil: would close a cycle (or missing, safe:);
                                                                     // a new source to an old target placed first
    remove(_:), remove(edge:), remove(edgeAt:) (DirectedPseudograph, StableDirectedGraph),
        removeAll(keepingCapacity:), removeAllEdges(keepingCapacity:), reserveCapacity(vertexCount:edgeCount:)
    hasPath(from:to:), transitiveClosure(), transitiveReduction(), longestPath() -> Path?, longestPath(weight:) -> Path?
    addEdgeMap(of:), addVertexMap(of:), removeEdgeMap(_:), removeVertexMap(_:), self[map, …]  // Base == StableDirectedGraph
// ShortestPaths: dagShortestPaths(from:weight:) on any DirectedGraph (nil when a cycle is reachable),
// and on DirectedAcyclicGraph in its order (not optional).
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Bulk order | Kahn's algorithm, FIFO, roots in `vertices` order: Traversal's `topologicalGenerations()` flattened; an edgeless graph keeps `vertices` order | DAG-002 – DAG-005 |
| The base | Built as it builds itself: listed vertices first, then new endpoints. Copies collapse on `AdjacencyList` and are kept on the others | DAG-006 – DAG-008, DAG-011 |
| Bulk failure | `nil` when the edges have a cycle, a self-loop included, from every initializer | DAG-009, DAG-010 |
| New vertex | Placed last | DAG-012 |
| Forward edge | Inserted with no reordering. A missing endpoint is inserted first, source then target. A new source whose target is already a vertex is placed first, any other new endpoint last, so an edge with a new endpoint goes forward and never reorders; the free front slots grow as sources arrive | DAG-013 – DAG-022 |
| Backward edge | Pearce–Kelly. B (u and its ancestors placed after v), then F (v and its descendants placed before u), each by old place, take the pooled places. Nothing else moves | DAG-023 – DAG-032 |
| Rejected edge | `nil`, a self-loop included (even on a non-vertex), and nothing changes. The witness is `bidirectionalShortestPath(from: target, to: source)`, one of the shortest paths the cell lists | DAG-032 – DAG-043 |
| `insert(safe:)` | `nil` for a missing endpoint or a rejected edge, otherwise `insert(edge:)` | DAG-044 – DAG-048 |
| Removal | Keeps the order. `remove(_:)` leaves a hole in the vertex's slot (trimmed at either end; the slots are compacted once holes outnumber vertices), places count past the holes, and a swap-removed base's moved vertex keeps its slot; `removeAllEdges()` keeps the order; `removeAll()` clears it | DAG-049 – DAG-069 |
| Order queries | `topologicalPosition`, the order's subscript, and an order-pruned `hasPath` (true for the same vertex) | DAG-070 – DAG-078 |
| Equality | The base's: the order is history and does not count | DAG-079, DAG-080 |
| Algorithms | `transitiveClosure()` appends the missing edges per source in topological order. `transitiveReduction()` keeps the first copy, at fresh positions. `longestPath()` takes the first tying in-edge and the first end in topological order; `longestPath(weight:)` is NetworkX's `dag_longest_path(weight=)`, restarting at zero where the best is negative; `dagShortestPaths` (ShortestPaths) relaxes in the order, and agrees with the generic run on `base` | DAG-081 – DAG-111 |
| Codable | `{base, order}`, with the order as offsets into `base.vertices`. Decoding re-checks the payload: a cycle, an order that is not a permutation, or a backward edge is `dataCorrupted`. On every base, holes included; a Stable vertex at position 2⁵⁰ costs one page | DAG-112 – DAG-120 |

## How values are pinned

Each catalog row is written the way the catalog writes it, `DirectedAcyclicGraph<Base<V>>(vertices:
V, edges: E)` followed by the calls in order, and each call's result is checked. After a mutation
that another mutation follows, the test checks the order, the vertices and the edges with their
positions. The final state is written out in full:

- the order, its count and its indices;
- every vertex's place, through `topologicalPosition(of:)`, `topologicalPosition(safe:)` and
  `topologicalOrder.firstIndex(of:)`;
- every row by vertex, out and in, with positions and degrees, through both the plain and the
  `safe:` spellings;
- a non-vertex answering `nil` through every `safe:` member;
- every position's ends;
- the base's vertices and edges.

The construction rows also check every other initializer that fits against the same state:
`init()`, `init(vertices:)`, `init?(edges:)`, `init?(_ base:)`, `init?(_ graph:)` from another
base, and the result builder. Where the edges have a cycle, every one of them must return `nil`.

The catalog-row files are every file except `DirectedAcyclicGraphConformanceTests.swift`,
`DirectedAcyclicGraphPropertyTests.swift` and `DirectedAcyclicGraphStressTests.swift`. `swiftgen.py`
generated them from `cases.md`. It sits next to `ref.py` and `cases.md` in
[`Tests/Catalogs/DirectedAcyclicGraph/`](../Catalogs/DirectedAcyclicGraph/):

```
uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/DirectedAcyclicGraph/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. Then it re-runs each row one call
at a time on `ref.py`'s port of the wrapper and the bases, with the laws checked after every call,
asserts that every value matches the catalog cell, and writes the test. The precondition file also
takes the hand-written exit tests in `extra_traps.swift`.

A trap row runs the trapping call in a child process (an exit test). The same setup then runs in
this process without the call, and its whole state is checked, so the trap comes from the call and
not from the setup.

## Hand-written files

- **Conformance.** Seeded random DAGs over each base, built by random inserts (some rejected),
  vertex removals and edge removals, `remove(edgeAt:)` included. After every operation the order must
  be a permutation of the vertices with every edge going forward. Traversal (BFS and DFS events,
  layers, `descendants`, `ancestors`, the three topological sorts, `findCycle`, `isAcyclic`,
  `hasPath`, `bidirectionalShortestPath`) and Connectivity (weak and strong components, the
  condensation, attracting components, dominators) must equal the same call on `graph.base`, with
  positions unchanged. The stable base has holes and so takes the sparse path. The file also covers
  equality and hashing that ignore the order, the descriptions, Codable round trips on every base,
  copy-on-write, the resets and capacity, `init(_ graph:)` across bases, the order collection,
  Sendable and the result builder.
- **Properties** (swift-property-based, with shrinking). Random mutation sequences run on each base
  against a written-out model: the vertex set, the multiset of arcs (a set on `AdjacencyList`), and
  the order, maintained from Pearce–Kelly's definition through the model's own descendants and
  ancestors. An edge must be rejected exactly when it is a self-loop or the model's reachability
  closes a cycle. A rejected insert must change nothing: equality, order, edges and positions are
  all as before. Its witness must be a genuine path of the graph, as long as the model's BFS
  distance. Nothing placed outside the endpoints' range may move. After every step the order must
  equal the model's, every edge must go forward, and the graph must be acyclic. Random bulk builds
  are checked against Kahn's algorithm and against `topologicalGenerations()`, and Codable by
  round trip.
- **Stress.** Each base gets a chain of 2 × 10⁴ vertices:
  - built forward, closed by a rejected edge whose witness runs the whole chain, and taken apart
    from the front;
  - built with its edges in random order, then given parallel copies;
  - cut in the middle and rejoined the other way round, which reorders everything once, then
    holed.

  An adversarial order reverses a chain one edge at a time, moving the whole prefix on every
  insert. Pearce and Kelly's own model is a random DAG with a hidden order and its edges inserted
  in random order. Later edges down the hidden order are rejected exactly when the base finds a
  path. Churn on each base puts new sources first and new targets last, reorders and removes
  anywhere (so the free front slots grow, holes are made, trimmed and compacted), and after each
  round checks every place three ways and every subscript against the order.
- **Review findings.** The attached maps of a `StableDirectedGraph` base, through the wrapper
  (README Q9); `remove(_:)` as a `MutableDirectedGraph` requirement, from generic code; vertex
  removal through the wrapper hashing as the bare base's removal does (one more on the stable
  base, whose removal finds and drops the vertex in one dictionary operation), compared between
  two copies of one base since a dictionary removal rehashes the entries it shifts; the two
  causes of `insert(safe:)`'s nil.
- **ShortestPaths** (`Tests/ShortestPathsTests/DAGShortestPathTests.swift`): `dagShortestPaths`
  on every representation, `nil` exactly when a cycle is reachable, several sources, ties, and
  random DAGs with holes against Bellman–Ford.

## Planted bugs

The suite was checked against 19 bugs planted in a Swift model of the API, built over the real
bases in a scratch copy of the workspace. It caught 17 of them. The other two are equivalent: they
drop Pearce–Kelly's bounds on the searches, letting the forward search pass the source's place or
the backward search pass the target's. The extra vertices then sort to the ends of the moved list
and take back their own places, so the order comes out the same and only the work grows. That is a
benchmark property, not a test one. A first run let `transitiveClosure()` appending in `vertices`
order survive, because every closure row had the two orders equal; DAG-075 was added for it.

| Planted bug | Caught by |
|---|---|
| A self-loop accepted | DAG-030, DAG-031, DAG-044, conformance, properties |
| Missing endpoints inserted target first | DAG-014, DAG-029, DAG-057 |
| `insert(safe:)` inserting missing endpoints | DAG-042, properties |
| A backward edge inserted without the reorder | 45 tests: reordering rows, conformance, properties, stress |
| F placed before B | DAG-014, DAG-016, 27 more |
| B and F each placed in reverse old order | DAG-014, DAG-016, DAG-023, DAG-027, DAG-028 |
| A cycle-closing edge inserted anyway | DAG-029, DAG-032 – DAG-035, properties |
| `remove(_:)` leaving the shifted tail's places stale | properties (a trap) |
| `removeAll()` keeping the order | resets, properties |
| `insert(_:)` of an existing vertex appending it again | DAG-012 – DAG-015, 30 more |
| `hasPath` pruning at the source's place | DAG-066, conformance, stress |
| `transitiveClosure()` appending in `vertices` order | DAG-075 |
| `transitiveReduction()` keeping parallel copies | DAG-077 |
| `longestPath()` taking the last tying in-edge | DAG-086 |
| Decoding without the backward-edge check | DAG-090 |
| Equality comparing the order | DAG-068, equality, descriptions |
| The bulk order taking roots in reverse | DAG-002, DAG-003, DAG-005, 18 more |

The suite also passes against the implementation in `Sources/DirectedAcyclicGraphModule`.
