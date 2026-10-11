# LabeledGraphs test suite

`LabeledGraphs` has one type, `LabeledGraph<Label, Base>`, after BGL's `labeled_graph`. It puts
`Hashable` labels on a representation that takes only `Int` vertices `0..<n`
(`CompressedSparseRow`, `AdjacencyMatrix`). Its `OrderedSet<Label>` names base vertex `i` by element
`i`, and every index-space member forwards to the base, so algorithms hash labels only at their
inputs. The tests come from the proposed API (`api.md` in
[`Tests/Catalogs/LabeledGraphs/`](../Catalogs/LabeledGraphs/), phase 1), with its open questions
decided as recommended:

- conformance for any dense `DirectedGraph<Int>` base whose vertices are `0..<n` in index order;
- construction and mutation only over CSR and the matrix;
- the matrix is append-only for vertices, with edge insertion and removal;
- `base` is read-only, and there is no `labels` property;
- relabeling is deferred.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
struct LabeledGraph<Label: Hashable, Base>: DirectedGraph (Base: DirectedGraph<Int>),
        BidirectionalDirectedGraph (Base: BidirectionalDirectedGraph<Int>), Equatable, Codable, Sendable,
        CustomStringConvertible
    init(_ base: Base, labels:)                                     // any dense DirectedGraph<Int> base
    init(), init(vertices:), init(edges:), init(vertices:edges:), init(_ graph:)   // Base == CSR / AdjacencyMatrix
    var base: Base; var vertices: OrderedSet<Label>; var edges: Edges   // Edges.Index == Base.Edges.Index
    successors(of:), outEdges(of:), outDegree(of:), predecessors(of:), inEdges(of:), inDegree(of:), degree(of:)
    successors(safe:), outEdges(safe:), outDegree(safe:), predecessors(safe:), inEdges(safe:), inDegree(safe:),
        degree(safe:), vertexIndex(safe:)
    vertexIndex(of:), vertex(atIndex:), successorIndices(ofIndex:), predecessorIndices(ofIndex:), …  // the base's
    insert(_:), insert(edge:), insert(safe:), remove(edge:), removeAllEdges(keepingCapacity:),
        removeAll(keepingCapacity:), reserveCapacity(vertexCount:)  // Base == AdjacencyMatrix
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Index assignment | Listed labels first (a repeat once), then new endpoints in first-appearance order | LG-003 – LG-005, LG-009 – LG-011 |
| Positions | The base's: CSR `Int`s in row-major index order, matrix `(source, target)` cells | LG-013, LG-014, LG-045, LG-047 |
| Row order | Ascending index, the base's order | LG-025, LG-035, LG-050 |
| `init(_:labels:)` | Traps on a count mismatch, a repeat, base vertices not `0..<n` in order, or `vertexIndexBound == nil` | LG-018 – LG-023 |
| Non-vertices | Label-space members trap; `safe:` spellings and `contains(edge:)` answer nil or false; `remove(edge:)` returns nil | LG-029 – LG-032, LG-076, LG-078 |
| Hashing | Index-space and whole-graph reads hash no label; a label-space read hashes once; algorithms hash at their inputs only | LG-054 – LG-057, LG-066 |
| Undirected | `labeled.undirected`: neighbours are successors then predecessors; label-space reads hash twice | LG-062 – LG-068 |
| Mutation | A new label appends base vertex n; `insert(edge:)` inserts a missing source, then a missing target | LG-069 – LG-081 |
| Equality | Equal label sets and equal labeled edge sets, whatever the index assignment | LG-082 – LG-086 |

## How values are pinned

Each catalog row is written the way the catalog writes it: `LabeledGraph<String, Base>(vertices: V,
edges: E)`, the base initializer, or `.undirected` on a matrix-based graph, then the calls in
order, each with its result checked. After a mutation that another mutation follows, the test
checks the labels and the edges with their positions. The final state is written out in full:

- every label's index both ways;
- every row, by label and by index, with empty rows included where the catalog leaves them out;
- every position's ends through `source(ofEdgeAt:)`, `target(ofEdgeAt:)` and `edges[p]`;
- the base's vertex count and edges;
- both bounds, `contains(edge:)` for every edge, and on CSR `edgeIndex(of:)`;
- on the undirected view, its neighbours, incident edges, degrees and opposite vertices.

The construction rows also check every other initializer that fits against the same state. Matrix
positions passed as arguments are cells taken from a one-edge `AdjacencyMatrix`, because a position
names a cell, and `Edges.Index` has no public initializer.

The rows that read `hashes()` (the reference model's label-hash counter) run a second time on a
label type, local to the test, whose `hash(into:)` and `==` count. They append 16 isolated labels,
because an `OrderedSet` scans linearly up to 15 elements and hashes only from 16. LG-056 differs
from the catalog's count: Traversal's `descendants(of:)` looks its source up twice (`contains(_:)`
for its precondition, then `vertexIndex(of:)`) and hashes each reached vertex into its `Set`
result. The test pins exactly that: two lookups plus the hashes of the same `Set` built in the same
order, and nothing per edge.

The catalog-row files are every file except `LabeledGraphConformanceTests.swift`,
`LabeledGraphHashTests.swift`, `LabeledGraphPropertyTests.swift` and
`LabeledGraphStressTests.swift`. `swiftgen.py` generated them from `cases.md`; it sits next to
`ref.py` and `cases.md` in [`Tests/Catalogs/LabeledGraphs/`](../Catalogs/LabeledGraphs/):

```
uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/LabeledGraphs/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. Then it re-runs each row one call
at a time on `ref.py`'s port of the storage, with the NetworkX spec and the laws checked after every
call, asserts that every value matches the catalog cell, and writes the test. The precondition file
also takes the hand-written exit tests in `extra_traps.swift`.

A trap row runs the trapping call in a child process (an exit test). The same setup then runs in
this process without the call, and its whole state is checked, so the trap comes from the call and
not from the setup.

## Hand-written files

- **Conformance.** Traversal (BFS and DFS events, layers, `descendants`, `ancestors`, both
  topological orders, `hasPath`), Connectivity (weak and strong components, the condensation,
  attracting components, dominators) and ShortestPaths (hop counts, Dijkstra, Bellman–Ford,
  bidirectional search). They run on seeded random graphs over both bases, and each result must
  equal the same call on `graph.base`, mapped through the labels, with positions unchanged. The
  undirected view is checked against the base's own view. The file also covers Codable as
  `{labels, base}` with its corrupt payloads, the edge collections, copy-on-write, the resets,
  `init(_ graph:)` across bases, Sendable, and `init(_:labels:)` over a renumbered base.
- **Hash law.** A counting label on graphs of at least 16 labels:
  - index-space and whole-graph reads cause no hash and no comparison;
  - every label-space member hashes once, `contains(edge:)` twice, and the `safe:` spellings once,
    hit or miss;
  - algorithms hash the same on a sparse graph and on one with eight times the edges and the same
    reachability;
  - building, growing and equality are amortized O(1) per label.
- **Properties** (swift-property-based, with shrinking). Mutation sequences on the matrix base run
  against a written-out model (labels in insertion order, a set of labeled arcs), and the whole
  state is compared after every step. Random builds of both bases are checked against the
  first-appearance rule, equality against the model's rule, and Codable by round trip.
- **Stress.** A CSR with 10⁵ String labels and about 4 × 10⁵ edges, checked against its base. A
  matrix grown to 2 048 labels, with 10⁵ edge changes checked against a set. 2 × 10⁴ counted labels
  whose whole-graph algorithms hash nothing.

## Planted bugs

The suite was checked against 15 bugs planted in a scratch copy of the implementation, and it
caught every one. One more planted bug, a looser range check in `vertex(atIndex:)`, was
equivalent, because `OrderedSet`'s subscript traps anyway.

| Planted bug | Caught by |
|---|---|
| A double lookup in `successors(of:)` | hash law, LG-055, LG-066 |
| `contains(_:)` or `vertexIndex(safe:)` scanning linearly | hash law, LG-056 |
| CSR build numbering the target before the source | LG-025 and most CSR rows |
| `insert(edge:)` inserting the target first | LG-073, properties |
| Equality ignoring edges, or the fast path skipping the base | LG-085, properties |
| `init(_:labels:)` without the repeat or count check | LG-019, LG-020, Codable |
| `insert(safe:)` inserting missing endpoints | LG-076, properties |
| `removeAll()` keeping the labels | LG-080, copy-on-write, resets |
| `inDegree` reading the out-row | matrix rows, stress |
| `outDegree(safe:)` giving 0 for a non-vertex | LG-029, LG-039 |
| The edge iterator, or `source(ofEdgeAt:)`, swapping the ends | construction rows |
| Decoding without validation | Codable |
