# FunctionalGraphs test suite

`FunctionalGraphs` holds the graph of a function f : V → V. Every vertex has exactly one out-edge,
v → f(v), so each weakly connected component is one cycle with trees hanging off it. The module has
two parts:

- `FunctionalGraph`, a stored f over the vertices `0..<n` that conforms to `DirectedGraph`, with
  `successor(of:steps:)` and its O(n) cycle decomposition;
- `floydCycleDetection` and `brentCycleDetection`, which take f as a closure and use O(1) memory.

The tests come from the proposed API (`api.md` in
[`Tests/Catalogs/FunctionalGraphs/`](../Catalogs/FunctionalGraphs/), phase 1), with its open
questions decided as recommended:

- `Int` storage, with labels through `LabeledGraph<Label, FunctionalGraph>`;
- no binary lifting;
- immutable;
- no `BidirectionalDirectedGraph` conformance.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
struct FunctionalGraph: DirectedGraph, Hashable, Codable, Sendable, CustomStringConvertible
    init(successors:), init(vertexCount:successor:), init?(_ graph: some DirectedGraph)
    successor(of:), successor(of:steps:), cycleDecomposition()
    // DirectedGraph: Vertices = Range<Int>; Successors, OutEdges, SuccessorIndices = CollectionOfOne<Int>;
    // Edges: RandomAccessCollection with Index = Int, the position of the edge leaving p is p
struct FunctionalGraph.CycleDecomposition: Sendable
    cycles                                      // RandomAccessCollection of ArraySlice<Int>
    component(of:), root(of:), tailLength(of:), cycleLength(of:), preimages(of:), inDegree(of:),
        successor(of:steps:)
func floydCycleDetection(from:successor:) -> (tailLength: Int, cycleLength: Int, root: Vertex)
func brentCycleDetection(from:successor:) -> (tailLength: Int, cycleLength: Int, root: Vertex)
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Edge positions | The edge leaving p is at position p, and its edge index is p | FG-002, FG-003, FG-018 |
| `init(vertexCount:successor:)` | Calls the closure once per vertex, in ascending order; never for n = 0 | FG-005, FG-006 |
| `init?(_ graph:)` | Vertex i is the graph's i-th vertex; nil unless every out-degree is 1, parallel edges counted | FG-011 – FG-015 |
| Cycles | Each listed from its least vertex in walk order, and ordered by least vertex, not by discovery | FG-026, FG-040, FG-041 |
| `root(of:)` | The first cyclic vertex on v's walk, not the cycle's least vertex | FG-028 |
| Preimages | Ascending | FG-031 |
| `successor(of:steps:)` | Any k from 0 to `Int.max`, on the graph and on the decomposition | FG-021 – FG-024, FG-032 – FG-034 |
| Floyd and Brent | The formulations api.md pins, so call counts are exact: Floyd 3ν + 2μ + λ | FG-047 – FG-059 |
| Codable | The bare successor array; decoding re-checks the range and throws `dataCorrupted` | FG-062 |
| Traps | A successor off `0..<n`, a negative count, a non-vertex, negative steps | FG-007 – FG-010, FG-019, FG-020, FG-025, FG-043, FG-044 |

## How values are pinned

The catalog-row files are every file except `FunctionalGraphConformanceTests.swift`,
`FunctionalGraphPropertyTests.swift` and `Performance/FunctionalGraphStressTests.swift`. `swiftgen.py`
generated them from `cases.md`; it sits next to `ref.py` and `cases.md` in
[`Tests/Catalogs/FunctionalGraphs/`](../Catalogs/FunctionalGraphs/):

```
uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/FunctionalGraphs/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. It then evaluates each row's calls
once on `ref.py`'s model, which is checked against NetworkX and brute force, asserts that every
formatted value is the catalog cell, and writes one test per row that checks each call's result.

A row over a stored graph then writes out the whole state from the model:

- every successor, edge, position and index member;
- `contains` on and off the vertex range;
- the full decomposition: cycles, components, roots, tail and cycle lengths, preimages and
  in-degrees;
- `successor(of:steps:)` on the graph and on the decomposition, for steps 0, 1, 2, n, n + 1,
  2n + 2 and `Int.max`.

A Floyd or Brent row counts the closure's calls in the closure itself, so the count is public
behavior. It also walks f to check the result against the definition: the root is `tailLength`
steps out, on a cycle of `cycleLength`, and the vertex before it is not on that cycle.

A trap row runs the trapping call in a child process (an exit test). It then runs the same setup in
this process without the call, or, for a rejected construction, the nearest accepted input, and
checks the whole state. The precondition file also takes the hand-written exit tests in
`extra_traps.swift`: every vertex-taking read, edge position and decomposition query off `0..<n`.

## Hand-written files

- **Conformance.** Seeded random mappings, permutations and long tails are compared with a
  `DirectedPseudograph<Int>` holding the same edges, and every result must be equal:
  - Traversal: BFS and DFS events, layers, `descendants`, `hasPath`, the topological order (always
    nil for n > 0) and `findCycle`;
  - Connectivity: weak, strong and attracting components;
  - ShortestPaths: hop counts, and Dijkstra with the weight read from the edge's source.

  The decomposition is checked against those results:
  - the attracting components are the cycles;
  - one weak component per cycle;
  - a vertex's strong component is its cycle, or the vertex alone;
  - the tail length is the hop distance to the root;
  - the hop-k vertex is f^k.

  The file also covers `LabeledGraph` over a `FunctionalGraph`, Codable round trips and corrupt
  payloads, equality and hashing over every graph on up to three vertices, and `Sendable`.
- **Properties** (swift-property-based, with shrinking), each against a model written out in the
  test:
  - the decomposition laws, against orbits walked with a dictionary of first occurrences;
  - f^k on the graph and the decomposition against iterating f, for small k and for huge k
    reduced by the orbit;
  - Floyd and Brent against the orbit model. Floyd's call count is checked against its closed form,
    and Brent's against the pinned formulation run on the array;
  - Pollard-rho closures;
  - `init?(_ graph:)` round trips with rotated vertex orders, and is nil with one edge more or one
    fewer;
  - `init(vertexCount:successor:)` calls the closure in ascending order.
- **Stress.**
  - A random mapping on 3 × 10⁵ vertices, checked against the decomposition's invariants, 200
    sampled orbits and Connectivity.
  - A path of 10⁶ vertices into a fixed point, which needs a decomposition without recursion.
  - A permutation of 10⁵ vertices.
  - 120 Pollard-rho closures x² + c mod m with m up to 3 × 10⁹, and the factor 97 of 8 051 found
    from the detected cycle.
- **Without vertex indices** (`FunctionalGraphUnindexedTests.swift`): `init?(_ graph:)` on a
  minimal conformer whose `vertexIndexBound` is nil, the hashed path no library conformer takes:
  vertex i is the i-th listed vertex, and the result is nil on out-degree 0 or 2. Added for planted
  bugs in `just mutate FunctionalGraphs` that every other test let through.
- **Rebuilds** (`FunctionalGraphRebuildTests.swift`): 40 decompositions of a broom built in a row,
  with freed buffers full of large values in between, so a build step that reads memory it never
  wrote (a depth count not reset) shows as a wrong tail or step.

## Planted bugs

The suite was checked against 15 bugs planted in a Swift model of the API, outside the repository,
and it caught every one:

| Planted bug | Caught by |
|---|---|
| `init(vertexCount:successor:)` calling in descending order | FG-005, properties |
| `init?(_ graph:)` accepting two parallel edges as one successor | FG-015, properties |
| `successor(of:steps:)` past n reducing k by the cycle length alone, ignoring the tail | FG-023, every graph row's state, properties |
| The edge collection swapping its ends | FG-002 – FG-004, every graph row's state |
| `contains` true for negative vertices | FG-017, every graph row's state |
| Cycles not rotated to their least vertex | FG-040, properties, stress |
| Cycles in discovery order | FG-041, properties |
| `root(of:)` giving the cycle's least vertex | FG-028, properties, conformance |
| Tail lengths of 2 or more one too long | FG-029, FG-034, FG-039, properties |
| Preimages descending | FG-031, every graph row's state, stress |
| `inDegree(of:)` one too high for vertex 0 | FG-031, FG-036, properties |
| The level-ancestor walk one step short | FG-032, FG-034, every graph row's state, properties, stress |
| Floyd's hare starting one step behind | FG-047, FG-050, FG-056; it then never returns, so the suite times out |
| Brent's power tripling instead of doubling | Brent call counts in 11 of FG-047 – FG-059 |
| Decoding without the range check | FG-062, conformance |
