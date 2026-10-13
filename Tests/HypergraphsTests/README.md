# Hypergraphs test suite

`Hypergraphs` holds two representations: `UndirectedIncidenceList<Vertex>`, a `Hypergraph`, and
`IncidenceList<Vertex>`, a `DirectedHypergraph` whose hyperedges each have a source set and a target
set. The two protocols live in `GraphProtocols` and have no shared parent. It also holds the
algorithms written once on each protocol, and the lazy views `IncidenceGraphView` (a `Graph`) and
`DirectedIncidenceGraphView` (a `BidirectionalDirectedGraph`), through which the graph algorithms
reach a hypergraph. The tests come from the proposed API in
[`Tests/Catalogs/Hypergraphs/`](../Catalogs/Hypergraphs/) (`api.md`, phase 1), with every open
question decided as recommended:

- the representations are named after their storage;
- `size(ofHyperedgeAt:)` is undirected only;
- there is no `Hyperedge` value;
- the checked insert is spelled `insert(checked:targets:)`;
- s-components are over hyperedges;
- BF-connection and removal are deferred.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
protocol Hypergraph, protocol DirectedHypergraph                  // GraphProtocols
struct UndirectedIncidenceList<Vertex>: Hypergraph, PropertyGraph, Equatable, Hashable, Codable, Sendable,
        CustomStringConvertible, CustomDebugStringConvertible
    init(), init(vertices:), init(hyperedges:), init(vertices:hyperedges:), init(_ hypergraph:)
    insert(_:), insert(hyperedge:), insert(checked:), removeAll(keepingCapacity:), reserveCapacity(…)
    members / memberIndices / size(ofHyperedgeAt:), incidentHyperedges(of: / ofIndex: / checked:),
    degree(of: / ofIndex: / checked:), contains(_:), contains(hyperedge:), vertexIndex(of: / checked:), …
struct IncidenceList<Vertex>: DirectedHypergraph, …               // the same conformances
    init(…hyperedges: [(sources:, targets:)]), init(_ hypergraph:), init(_ graph: some DirectedGraph)
    insert(sources:targets:), insert(checked:targets:), sources / targets / sourceIndices / targetIndices,
    outHyperedges / inHyperedges(of: / ofIndex: / checked:), outDegree / inDegree / degree(of: / checked:),
    vertexIndex(of: / checked:), reversed
both: generation; addVertexMap / addEdgeMap(default: / of:), removeVertexMap / removeEdgeMap,
    [map, ofVertexAt: / of: / ofEdgeAt:], [map, checkedVertexAt: / checked: / checkedEdgeAt:], values(of:)
extension Hypergraph: neighbors(of:), rank, isUniform(size:), degreeHistogram(), hyperedgeSizeHistogram(),
    dual(), incidenceGraphView, cliqueExpansion(), lineGraph(s:), connectedComponents(), isConnected,
    sConnectedComponents(s:)
extension DirectedHypergraph: dual(), incidenceGraphView, weaklyConnectedComponents(), isWeaklyConnected,
    stronglyConnectedComponents(), isStronglyConnected, bConnectedVertices(from:), isBConnected(from:to:),
    fConnectedVertices(to:), isFConnected(from:to:), isBHypergraph, isFHypergraph, isBFHypergraph,
    cliqueExpansion(), outDegreeHistogram(), inDegreeHistogram(), sourceSizeHistogram(), targetSizeHistogram()
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Index assignment | Listed vertices first (a repeat once), then new members by first appearance; directed, sources before targets | HG-003, HG-004, DH-002 |
| Members | Stored once, in vertex-index order; each side separately when directed | HG-005, HG-006, DH-003, DH-004 |
| What a hyperedge may be | Empty, repeated, and (directed) with an empty side or a vertex on both sides | HG-007, HG-008, DH-005 – DH-007 |
| Rows | Incident, out- and in-hyperedges ascend by position; directed degree is in + out | HG-014, DH-008, DH-009 |
| Non-vertices | Vertex-space members trap; `checked:` spellings throw `VertexNotFound` and change nothing; `contains` answers false | HG-021 – HG-027, DH-012 – DH-017, DH-057 |
| Hash law | Index-space reads and whole-hypergraph algorithms hash no vertex; a vertex-space read hashes once | HG-022, HG-023, DH-011, DH-012, DH-057 |
| Views | Vertex indices `0..<n`, hyperedge `p` at `n + p`; edge q is incidence q, directed source incidences first | HG-059 – HG-061, DH-025, DH-026 |
| Expansions | Every vertex (or every position, for the line graph), edges ascending by index pair, no self-loops | HG-062 – HG-068, DH-041, DH-042 |
| Components | By least vertex index, each ascending; `isConnected` false for no vertices; s-components keep singletons | HG-069 – HG-077, DH-027 – DH-030 |
| B- and F-connection | Gallo et al.'s B-Visit; F-Visit is B-Visit on the reversal, started at the destination | DH-031 – DH-037 |
| Equality | Equal vertex sets and equal multisets of hyperedges, whatever the order | HG-078 – HG-085, DH-046 – DH-050 |
| Codable | `{vertices, hyperedges}` or `{vertices, sources, targets}`, rows ascending; re-checked as `dataCorrupted` | HG-089 – HG-094, DH-052 – DH-056 |

## How values are pinned

Each catalog row is built the way the catalog writes it, as
`UndirectedIncidenceList<String>(vertices:hyperedges:)` or `IncidenceList<String>(vertices:hyperedges:)`
(with `Int` vertices where the labels are numbers). The calls then run in order, each with its
result checked. After a mutation that another mutation follows, the test checks the vertices and
the hyperedges. The final state is written out in full:

- every vertex's index both ways;
- every row, by vertex and by index, empty ones included;
- every hyperedge's members, or both sides, by vertex and by index, and membership through
  `contains(hyperedge:)` or `contains(sources:targets:)`;
- both bounds.

Views, expansions, duals and reversals are checked the same way, together with every neighbor, row
and degree of the view. The construction rows also check every other initializer that fits, and
building by inserting one element at a time, against the same state. The `hashes()` rows run a
second time on a vertex type, local to the test, whose `hash(into:)` and `==` count. They append 16
isolated vertices, because an `OrderedSet` hashes only from 16 elements.

The catalog-row files are every file except `HypergraphConformanceTests.swift`,
`HypergraphEdgeCaseTests.swift`, `HypergraphHashTests.swift`, `HypergraphPropertyTests.swift`,
`IncidenceGraphViewCheckedTests.swift` (the incidence graph views' `checked:` lookups),
`HypergraphMapTests.swift`, `HypergraphMapPropertyTests.swift`, `HypergraphGenerationTests.swift`
and `Performance/HypergraphStressTests.swift`.
`swiftgen.py`, which sits next to `ref.py`, generated them:

```
uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 --with hypernetx==2.4.3 \
    --with halp==1.0.0 python3 Tests/Catalogs/Hypergraphs/swiftgen.py
```

The generator first checks that `ref.py` reproduces `cases.md` byte for byte. It then re-runs each
row on `ref.py`'s model, with XGI, HyperNetX, halp, NetworkX and the laws checked after every call,
asserts that every value matches the catalog cell, and writes the test. The precondition file also
takes the hand-written exit tests in `extra_traps.swift`. A trap row runs the trapping call in a
child process. The same setup then runs in this process without the call, and its whole state is
checked.

## Hand-written files

- **Conformance.** Graph algorithms on the incidence-graph view must equal the same algorithms on
  the view copied into an `UndirectedAdjacencyList<Int>` or `AdjacencyList<Int>`. Edge positions and
  row orders agree, so the comparison is exact.
  - Undirected: Connectivity, BFS and DFS events, ShortestPaths, SpanningTrees, BipartiteGraphs and
    Cycles.
  - Directed: weak and strong components, the condensation, topological order, BFS and DFS,
    descendants and ancestors, and Dijkstra.
  - The hypergraph components equal the view's restricted to the vertex side, and B-connection
    lies inside plain reachability.
  - A minimal test-local conformer of each protocol checks that the defaults and the algorithms
    work for any conformer with indices.
  - Also: `IncidenceList(_:)` from a directed graph (B- and F-connection there are reachability),
    Codable round trips, copy-on-write, the resets and capacity, `init(_:)` across conformers, and
    Sendable.
- **Edge cases** (`HypergraphEdgeCaseTests.swift`), one behavior each, written for the planted
  bugs the rest let through (`scripts/mutants/Hypergraphs.py`):
  - a hyperedge of 40 members past the builder's insertion-sort limit, unsorted and repeated;
  - copies of conformers without vertex indices;
  - re-inserting a vertex adds no row; `hyperedgeIndex(of:)` traps out of range;
  - the in-side `checked:` reads, and `contains(sources:targets:)` on both sides;
  - near-miss equality (same sizes, other members; sides split differently) and hashing;
  - hostile payloads: a negative index, a repeated vertex;
  - the views' membership, opposite ends and trapping reads, and edge subscripts, components and
    bridges on views over test-local conformers (the protocols' computed rows);
  - the clique expansions' vertex indices, edge membership and predecessors.
- **Hash law.** A counting vertex on hypergraphs of at least 16 vertices:
  - index-space reads, whole-hypergraph algorithms and graph algorithms on the views cause no hash
    and no comparison;
  - every vertex-space member hashes once, hit or miss;
  - each vertex argument of an algorithm is looked up once, `contains(hyperedge:)` hashes each
    member once, and B- and F-Visit hash only their argument whatever the chain length;
  - hashing a hypergraph hashes each vertex once;
  - building and equality are amortized O(1) per incidence.
- **Properties** (swift-property-based, with shrinking):
  - mutation sequences of both kinds against a written-out model, with the whole state compared
    and the incidence, handshake and index laws checked after every step;
  - dual(dual) ≅ H, relabeled to indices with positions kept;
  - reversal as an involution that commutes with the dual;
  - B- and F-Visit against the fixpoint of Gallo et al.'s definition;
  - strong and weak components, both clique expansions, the s-line graph, s-components, neighbors,
    rank and uniformity against direct computations;
  - equality and hashing under any vertex and hyperedge order, and Codable.
- **Attached maps** (`HypergraphMapTests.swift`), on both representations: defaults for every
  element and every new one (the vertices a hyperedge's insertion adds included), values by index,
  by vertex and by position, `values(of:)` snapshots, the checked reads throwing just outside the
  elements, `removeAll` emptying the maps and keeping them attached, several maps and removed
  ones, copy-on-write (two copies keep their own values whichever mutates first: every mutation
  on one, then every mutation on the other), reference values, `reversed` carrying the maps, and
  equality, hashing and
  `Codable` ignoring them. The traps (out of range, a non-vertex, a handle of another hypergraph or
  of a removed map) are in `extra_traps.swift`.
- **Maps against a model** (`HypergraphMapPropertyTests.swift`, swift-property-based): random
  insertions, checked insertions, writes, reversals and resets against dictionaries keyed by vertex
  and by position, every value read every way after every step, and a copy taken midway that must
  not change.
- **Generations** (`HypergraphGenerationTests.swift`): every structural mutation starts one, a
  call that changes nothing does not, copies share one until either is mutated, and built and
  decoded hypergraphs have one; on both representations, two copies under every interleaving of
  three steps never share a generation in different states.
- **Stress.**
  - 2 × 10⁴ vertices and 4 × 10⁴ hyperedges, whose components equal the view's.
  - A directed chain of 10⁴ Horn clauses for B- and F-Visit.
  - A directed cycle of 10⁴ hyperedges, which is one strong component.
  - 10⁴ counted vertices whose whole-hypergraph algorithms hash nothing.

The suite does not count hashes in `cliqueExpansion()`. Building its `UndirectedAdjacencyList<Vertex>`
hashes each vertex once (api.md), which the benchmark target checks at scale.

## Planted bugs

The suite was checked against a Swift model of the API in a scratch copy of the workspace, built
through Bazel, with one bug planted at a time. It caught every one:

| Planted bug | Caught by |
|---|---|
| Members kept in first-appearance order, not vertex-index order | HG-003 and 17 more rows, properties, Codable |
| `insert(checked:)` dropping a missing member and inserting the rest | HG-040, properties |
| `contains(hyperedge:)` of the empty set always false | HG-008, HG-019 and every state check |
| `incidentHyperedges(of:)` looking the vertex up twice | hash law, HG-022 |
| `incidentHyperedges(ofIndex:)` read through a vertex lookup | hash law, HG-022, stress |
| A vertex listed as its own neighbor | HG-009, HG-024, properties |
| `s` read as "more than s" in the line graph and s-components | HG-065 – HG-068, HG-074 – HG-077 |
| `isConnected` true with no vertices | HG-071 |
| `isUniform(size:)` ignoring singletons (XGI's rule) | HG-048, properties |
| The dual listing its vertices in reverse | HG-055 – HG-058, properties |
| The incidence view listing a hyperedge's incidences in reverse | HG-059 – HG-061, conformance |
| Equality ignoring the member sets | HG-083 |
| A hash that depends on hyperedge order | HG-079, HG-084, properties |
| Decoding rows that are not strictly ascending | HG-093, HG-094, DH-055 |
| The description eliding after 17 elements, not 16 | HG-088 |
| `cliqueExpansion()` leaving out isolated vertices | HG-062, properties |
| B-Visit firing a hyperedge once any source is reached | DH-031, DH-032, the fixpoint property, stress |
| `fConnectedVertices(to:)` visiting forward | DH-035 – DH-037, the fixpoint property, stress |
| The directed clique expansion keeping a vertex on both sides as a self-loop | DH-041, properties, conformance |
| `reversed` swapping the rows but not the stars | DH-022, properties, stress |
| Directed `degree(of:)` counting an overlap once | DH-005, DH-009 and every directed state check |
| Strong components stepping from a hyperedge back to its sources | DH-028, stress |
| `insert(sources:targets:)` numbering the targets first | DH-002 and 15 more rows |
| The directed dual swapping sources and targets | DH-023, properties |
