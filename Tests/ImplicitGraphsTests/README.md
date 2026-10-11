# ImplicitGraphs test suite

`ImplicitGraphs` has one type, `ImplicitDirectedGraph<Row>`. It is a finite graph on the vertices
`0..<n` whose out-neighbors come from a closure `(Int) -> Row`, called on demand and never stored.
It is a lawful `DirectedGraph`, so every generic algorithm runs on it with no edge storage. The
suite also covers the closure searches over unbounded spaces that sit beside it:

- Traversal's existing `breadthFirstSearch(from:depthLimit:successors:)`;
- ShortestPaths decision D19: `dijkstraShortestPath(from:successors:success:)` and
  `aStarShortestPath(from:successors:heuristic:success:)`.

The tests come from the proposed API (`api.md` in
[`Tests/Catalogs/ImplicitGraphs/`](../Catalogs/ImplicitGraphs/), phase 1), with its open questions
decided as recommended:

- `Int` vertices, with labels through `LabeledGraph`;
- no `Sendable`, `BidirectionalDirectedGraph` or undirected variant;
- no `GridGraph`;
- D19 implemented in `ShortestPaths`, with its catalog rows tested here.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
struct ImplicitDirectedGraph<Row: Sequence<Int>>: DirectedGraph
    init(vertexCount:successors:)
    // Vertices = Range<Int>; Successors = SuccessorIndices, the range-checked row;
    // OutEdges, the row's positions
    struct Edges: Collection                   // Element = DirectedEdge<Int>
        struct Index: Comparable, Hashable    // source, rank, target; ==, < and hash on (source, rank)
func dijkstraShortestPath(from:successors:success:) -> (path: [V], distance: W)?              // ShortestPaths
func aStarShortestPath(from:successors:heuristic:success:) -> (path: [V], distance: W)?       // ShortestPaths
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Construction | Calls nothing; an empty graph never calls the closure | IG-001, IG-002 |
| Row reads | `successors(of:)`, `outEdges(of:)`, `outDegree(of:)` and `contains(edge:)` call the closure once | IG-004, IG-005, IG-010 |
| Positions | (source, rank, target); the ends are read from the position with no call | IG-005, IG-006, IG-009 |
| Edges | Iteration, `Array(edges)` and `edgeCount` call once per vertex; `index(after:)` re-reads the row, then each later row up to a non-empty one | IG-007, IG-008 |
| Membership | `contains(_:)` calls nothing; `contains(edge:)` calls nothing for an endpoint off `0..<n` | IG-010 |
| Bounds | `vertexIndexBound` is n, `edgeIndexBound` nil; the index members are the identity | IG-002, IG-011 |
| Range check | Lazy: a successor off `0..<n` traps when it is read, not when the row is formed | IG-014, IG-015 |
| Generic algorithms | Traversal calls once per discovered vertex; the weight closure can read `$0.target` | IG-016 – IG-022 |
| D19 | Distances, and path vertex counts under unit costs. Ties between equal paths are not pinned, so each path is checked step by step against the closure. The goal is tested when it is settled, not when it is pushed | IG-024 – IG-031 |

## How values are pinned

The catalog-row files are every file except `ImplicitGraphConformanceTests.swift`,
`ImplicitGraphPropertyTests.swift` and `ImplicitGraphStressTests.swift`. `swiftgen.py` generated
them from `cases.md`; it sits next to `ref.py` and `cases.md` in
[`Tests/Catalogs/ImplicitGraphs/`](../Catalogs/ImplicitGraphs/):

```
uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/ImplicitGraphs/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. It then evaluates each row's calls
once on `ref.py`'s model, which counts closure calls and is checked against the `DirectedGraph` laws
and NetworkX. It asserts that every formatted value is the catalog cell and writes one test per row.

Each test counts calls in its own closure, written as the catalog names it (`ring5`, `diamond`, …).
The grid returns a `LazyFilterSequence`, so a row type other than `Array` is covered. Positions
passed as arguments are read from `outEdges(of:)` before counting starts, because `Edges.Index` has
no public initializer.

A row over a graph then writes out the whole state from the model, with the calls each read makes:

- the edge count, and the edges iterated, at one call per vertex each;
- every row, by vertex and by index, with its positions;
- the ends of every position, read with no call;
- the edges stepped by `index(after:)`, which must equal iteration and be sorted and distinct;
- `contains(edge:)` for every edge, at one call each.

A trap row runs the trapping call in a child process (an exit test). It then runs the same setup in
this process without the fault. The lazy range check is shown by reading the good prefix of a bad
row without trapping. The precondition file also takes the hand-written exit tests in
`extra_traps.swift`:

- every vertex-taking read off `0..<n`;
- a bad successor read through `outEdges`, `outDegree`, iteration, `startIndex`, `contains(edge:)`
  and a breadth-first search.

`Array(graph.edges)` makes one call per vertex, as iteration does (IG-007): `Edges` copies itself
into an array in one pass and reports an `underestimatedCount` of 0, so `Array.init` never reads
`count` (a second call per vertex) first.

## Hand-written files

- **Conformance.** Seeded random closures, with parallel edges and self-loops, are compared with a
  `DirectedPseudograph<Int>` holding the same rows in the same order, and every result must be
  equal:
  - Traversal: BFS and DFS events, layers, `descendants`, `hasPath`, the topological order and
    `findCycle`;
  - Connectivity: weak, strong and attracting components;
  - ShortestPaths: hop counts, and Dijkstra with the weight read from the position's target. Every
    path is checked against its cost and against the rows, through the position's rank.

  The file also checks:
  - the calls a search makes: one per discovered vertex for BFS and `descendants`, at most two per
    settled vertex for Dijkstra;
  - a `LabeledGraph` over an implicit grid of cells;
  - that an `Array`, a lazy filter and a `StrideTo` serve as rows.
- **Properties** (swift-property-based, with shrinking): the implicit graph laws on random rows,
  each against a model written out in the test:
  - every read, with the closure calls it makes;
  - `index(after:)` stepping, with the model's call count per step;
  - positions unique, ordered, and equal and hash alike when read twice;
  - `contains(edge:)` off the range calling nothing;
  - breadth-first layers against a search written out over the rows, with one call per discovered
    vertex;
  - D19's Dijkstra and A* over an unbounded weighted grid, against Dijkstra on an implicit box with
    slack.
- **Stress.**
  - A 400 × 400 grid with walls, from a lazy-filter closure, against a `CompressedSparseRow` of the
    materialized grid: layers, components and Dijkstra, with one call per discovered vertex.
  - A hashed closure on 10⁵ vertices, against a `DirectedPseudograph`.
  - 200 unbounded weighted searches, where Dijkstra and A* must agree, and each path must cost what
    it says.

## Planted bugs

The suite was checked against 7 bugs planted in a Swift model of the API, outside the repository, and
it caught every one:

| Planted bug | Caught by |
|---|---|
| No range check on successors | IG-014, IG-015, extra traps |
| `startIndex` and `index(after:)` stopping at an empty row instead of skipping it | the conformance tests (the suite dies on a fatal error) |
| Ranks counted from 1 | IG-004 – IG-010, conformance |
| `edgeCount` iterating twice | IG-007, every graph row's state, properties |
| `contains(edge:)` scanning the row for a target off `0..<n` | properties |
| D19 paths returned goal first | IG-024 – IG-027, properties, stress |
| D19 testing the goal when it is pushed, not when it is settled | IG-030, IG-031 (step costs that depend on both ends), properties. With costs that depend only on the cell entered, as in IG-026 and IG-027, the first push of the goal is already optimal |
