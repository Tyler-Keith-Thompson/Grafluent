# StableGraphs test suite

`StableGraphs` has one type, `StableDirectedGraph<Vertex>`, after petgraph's `StableGraph`: a
directed pseudograph whose vertex and edge positions do not change while the vertex or edge exists.
A removal leaves a hole and moves nothing. The tests were written before the implementation, from
the proposed API (`api.md` in [`Tests/Catalogs/StableGraphs/`](../Catalogs/StableGraphs/), phase 1),
with its open questions decided as recommended: the `StableGraphs` module; no slot reuse; the
dense index bounds `nil` while holes exist; `removeAll()` and `removeAllEdges()` reset `endIndex`;
equality ignores positions; `StableUnGraph` deferred. They also cover `SparselyIndexedDirectedGraph`,
the GraphProtocols refinement for positions with holes, through its public members. The suite uses
only the public API, and each test is self-contained; the shared material is the seeded generator
and the tags in `GrafluentTestSupport`.

## API under test

```swift
struct StableDirectedGraph<Vertex: Hashable>: BidirectionalDirectedGraph, SparselyIndexedDirectedGraph, Hashable,
                                              Codable (Vertex: Codable), Sendable (Vertex: Sendable),
                                              CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable
    init(), init(vertices:), init(edges:), init(vertices:edges:), init(@DirectedGraphBuilder _:), init(_ graph: some DirectedGraph<Vertex>)
    contains(_:), contains(edge:), edges(from:to:) -> EdgesConnecting, edgeCount(from:to:)
    successors(of:), predecessors(of:) -> Neighbors, outEdges(of:) -> OutEdges, inEdges(of:) -> InEdges
    outDegree(of:), inDegree(of:), degree(of:), source(ofEdgeAt:), target(ofEdgeAt:)
    insert(_:), insert(edge:) -> Int                         // the old edges.endIndex
    remove(_:), remove(edge:) -> DirectedEdge?               // the newest copy
    remove(edgeAt:) -> DirectedEdge, removeAllEdges(from:to:) -> Int
    removeAll(keepingCapacity:), removeAllEdges(keepingCapacity:), reserveCapacity(vertexCount:edgeCount:)
    var vertices: Vertices, edges: Edges                     // BidirectionalCollection, Index = position, skip holes
    vertexPositionBound, edgePositionBound, vertexPosition(of:), vertex(atPosition:),
    containsVertex(atPosition:), containsEdge(atPosition:)   // SparselyIndexedDirectedGraph
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Positions | A new vertex or edge gets the current `endIndex`; a removed position never comes back | SG-011 – SG-015, SG-030 – SG-032 |
| Orders | Every order is position order, so insertion order: `vertices`, `edges`, every out- and in-row, `edges(from:to:)` | SG-023, SG-024, SG-034, SG-041, SG-042 |
| `remove(edge:)` | The newest copy; nil, without a change, for an absent pair or a non-vertex | SG-016 – SG-020 |
| Vertex removal | Its slot and every edge at it become holes; the neighbours' rows keep their order | SG-026 – SG-034 |
| Resets | `removeAll()` resets both end indices, `removeAllEdges()` the edge end index | SG-039, SG-040 |
| Dense bounds | `vertexIndexBound` / `edgeIndexBound` are the counts while there are no holes of that kind, `nil` otherwise; the two kinds independent | SG-025, SG-062, SG-066 – SG-068 |
| Live or stale | `edges.indices.contains(p)` and `vertices.indices.contains(p)`, O(1), never trap | SG-046, SG-047 |
| Algorithms with holes | The same results as on `DirectedPseudograph(g)`, whose edge k is the kth live position | SG-069 – SG-072, SG-077 |
| `init(_:)` | Vertices in order, edges at `0..<edgeCount`; a `StableDirectedGraph` unchanged, holes and ends kept | SG-074, SG-075 |
| Equality | Equal vertex sets and equal edge multisets; positions and holes ignored | SG-078 – SG-081 |
| Codable | `{vertices, vertexPositions, vertexEnd, edges, edgePositions, edgeEnd}`, every position and both ends kept | SG-082 – SG-094 |

## How values are pinned

Every catalog row is written as the catalog writes it: `StableDirectedGraph(vertices: V, edges: E)`,
then the calls in order, each call's result checked. After each mutation that another mutation
follows, the test checks the positions: `vertices` and `edges` with their `indices`, `startIndex`
and `endIndex`, and both index bounds. The final state is written out in full: those, the counts,
every live position's ends through `source(ofEdgeAt:)`, `target(ofEdgeAt:)` and `edges[p]`, every
vertex's `firstIndex(of:)`, `vertices[p]`, rows (`successors`, `outEdges`, `predecessors`,
`inEdges`, empty rows included, where the catalog omits them) and degrees, `edges(from:to:)`,
`edgeCount(from:to:)` and `contains(edge:)` for every pair with an edge, and, with dense indices,
`vertexIndex(of:)`, `vertex(atIndex:)` and `edgeIndex(of:)`. The construction rows also check every
other initializer that fits (the builder included) against the same state.

The catalog-row files (every file but `StableGraphConformanceTests.swift`,
`StableGraphPropertyTests.swift` and `StableGraphStressTests.swift`) were generated from `cases.md`
by `swiftgen.py`, next to `ref.py` and `cases.md` in
[`Tests/Catalogs/StableGraphs/`](../Catalogs/StableGraphs/), which says how to run it. It first
checks that `ref.py` reproduces `cases.md` byte for byte, then re-runs each row one call at a time
on `ref.py`'s port of the storage, checked against its plain specification and the laws after every
call, asserts that every value matches the catalog cell, and writes it out. The precondition file
also takes the hand-written exit tests in `extra_traps.swift`.

Trap rows run the setup and the trapping call in a child process (an exit test); the same setup then
runs in this process one step short of the precondition, with its results and the state checked, so
a trap in the setup would fail the test. Codable rows check the encoding byte for byte with sorted
keys, decode both that and the catalog's payload, check the decoded state, and check that the next
insertions get the positions they would have got before encoding. Corrupt payloads check the
`DecodingError.dataCorrupted` case, the catalog's key (the coding path's last key) and message.

The conformance, property and stress files compute their expectations inside each test: from the
compacted `DirectedPseudograph(g)` and the position list `Array(g.edges.indices)`, from the graph's
own `edges`, from a model kept beside the graph, and from closed forms.

The property tests' model holds `(vertex, position)` in insertion order, `(position, source,
target)` in insertion order and the two end indices, and follows only api.md's rules. After every
step it checks every result and the whole state: vertices, edges, positions, every row and degree,
the dense bounds (`nil` exactly while holes exist), the position bounds (`vertexPositionBound` and
`edgePositionBound` are the end indices), liveness by `indices.contains` and
`containsVertex(atPosition:)` / `containsEdge(atPosition:)` for every integer from -1 past the end,
and that every position removed since the last reset stays dead.

The whole suite was run against a Swift model of the API (written from api.md over the real
GraphProtocols, with rows as position-sorted arrays) before the implementation existed, through
Bazel in a scratch copy of the workspace, with warnings as errors, and then against the
implementation. It was also run against 17 bugs planted in that model, each selected at run time;
every one fails tests (count of failing tests in parentheses) or corrupts the storage so that the
run traps: an edge position reused (26), a vertex slot reused (45), `remove(edge:)` taking the
oldest copy (18), out-rows newest first (32), `indices.contains` true at holes (34),
`firstIndex(of:)` returning an offset (82), `vertexIndexBound` ignoring holes (a trap),
`edgeIndexBound` 0 with no live edges (47), equality comparing positions (10), `edgeEnd` encoded
as the live count (13), decoding accepting a repeated vertex (2), the numbered rows reversed
(7), `init(_:)` compacting a `StableDirectedGraph` (16), `removeAll()` keeping the end indices
(26), `removeAllEdges(from:to:)` removing one copy (134), a self-loop counted twice in vertex
removal (a trap), and `degree(of:)` counting a self-loop once (41).

## Files

| File | Tests | Covers |
|---|---|---|
| `StableGraphConstructionTests.swift` | 6 | SG-001 – SG-006: empty, listed vertices first (a repeat once), endpoints in first-appearance order, copies and loops kept, `String` vertices; every other initializer, the builder included |
| `StableGraphInsertionTests.swift` | 4 | SG-007 – SG-010: `insert(_:)`, `insert(edge:)` returning `edges.endIndex` and inserting endpoints, a self-loop |
| `StableGraphEdgeRemovalTests.swift` | 15 | SG-011 – SG-025: holes, no moves, positions never reused, the newest copy, absent pairs and non-vertices, `removeAllEdges(from:to:)`, row order across removals |
| `StableGraphVertexRemovalTests.swift` | 9 | SG-026 – SG-034: vertex and edge holes, loops and copies, re-insertion at a fresh position, every vertex removed |
| `StableGraphSequenceTests.swift` | 6 | SG-035 – SG-040: mixed sequences, churn on one pair, a FlowNavigation replacement, both resets |
| `StableGraphQueryTests.swift` | 9 | SG-041 – SG-049: rows and copies in insertion order, membership after removals, degrees, live-or-stale checks |
| `StableGraphIndexTests.swift` | 12 | SG-066 – SG-077 without SG-062: dense indices and holes, numbering, BFS, the compacting conversion, `init(_:)` both ways, the undirected view, components, Dijkstra by position and topological sort against the compacted copy |
| `StableGraphEqualityTests.swift` | 4 | SG-078 – SG-081 |
| `StableGraphCodableTests.swift` | 13 | SG-082 – SG-094: encoding, round trips keeping fresh positions, the empty and all-holes graphs, nine corrupt payloads |
| `StableGraphDescriptionTests.swift` | 2 | SG-095, SG-096 |
| `StableGraphPreconditionTests.swift` | 23 | Exit tests: SG-050 – SG-065, then `extra_traps.swift`: every neighbourhood and degree of a non-vertex or removed vertex; position lookups at holes, negative and past the end; positions from before a reset; dense index lookups; stepping past either end; a negative edge capacity; the sparse lookups |
| `StableGraphConformanceTests.swift` | 13 | Algorithms (Traversal; Connectivity's components, condensation, attracting components and dominator trees; ShortestPaths) on eight seeded graphs with many holes and before any removal, against the compacted copy; a DAG with holes; the laws with holes; `SparselyIndexedDirectedGraph` through generic code; the collections skipping holes and as values; rows as random-access collections of positions indexed by offset; Codable through JSON and property lists; Hashable; Sendable; the builder and initializers; resets; copy-on-write; capacity |
| `StableGraphPropertyTests.swift` | 4 | PropertyBased, shrinking: random sequences against the model; Codable round trips keeping the next fresh positions; equality and hashing ignoring positions and holes; algorithms on random graphs with holes against the compacted copy |
| `StableGraphStressTests.swift` | 4 | Inside a `Task` with a one-minute limit: a 10⁵-vertex cycle with every other vertex removed and re-connected; 10⁵ copies of one pair churned from both ends; a 10⁵-edge star with every other edge removed by position; a 300 × 300 grid with vertices removed and re-inserted |

96 catalog rows (80 value rows, 16 trap rows), 7 more exit tests and 21 more tests (13
conformance, 4 property, 4 stress): 124 tests in all.

## Case IDs

Case IDs (SG-001 … SG-096) refer to the catalog (`cases.md`), whose values `ref.py` computes with a
port of the proposed storage, checks against a plain specification and the laws in every state, and,
with `--stress`, checks against rustworkx 0.18.1 (petgraph's `StableGraph`) and NetworkX 3.7. Each
test's name starts with its ID; tests without an ID check laws, properties or conformance that the
catalog does not list.

| Cases | Section | File |
|---|---|---|
| SG-001 – SG-006 | Construction | `StableGraphConstructionTests.swift` |
| SG-007 – SG-010 | Insertion | `StableGraphInsertionTests.swift` |
| SG-011 – SG-025 | Edge removal | `StableGraphEdgeRemovalTests.swift` |
| SG-026 – SG-034 | Vertex removal | `StableGraphVertexRemovalTests.swift` |
| SG-035 – SG-040 | Interleaving | `StableGraphSequenceTests.swift` |
| SG-041 – SG-049 | Queries | `StableGraphQueryTests.swift` |
| SG-050 – SG-065 | Traps (SG-062 is listed under Conformance) | `StableGraphPreconditionTests.swift` |
| SG-066 – SG-077 | Conformance | `StableGraphIndexTests.swift` |
| SG-078 – SG-081 | Equality and hashing | `StableGraphEqualityTests.swift` |
| SG-082 – SG-094 | Codable | `StableGraphCodableTests.swift` |
| SG-095, SG-096 | Description | `StableGraphDescriptionTests.swift` |

## Readings of what api.md leaves open

| Question | Reading taken | Where |
|---|---|---|
| "Vertex numbering" (SG-069) | Not public; read through `weaklyConnectedComponents()`, whose components are in `vertices` order, on the edgeless graph | SG-069 |
| SG-077's graph | The catalog names no instance: a graph with vertex and edge holes, and a DAG with both, built in the test | SG-077 |
| When a neighbourhood traps | At the call: the exit tests make the collection with `Array(…)`, so a lazy check would be caught too | SG-050 – SG-052 |
| `Neighbors`' index | Not pinned; only elements, `count` and `reversed()` are checked | `rows` |
| Decoding error key | The coding path's last key is the one the catalog prints, `dataCorrupted(key)` | SG-086 – SG-094 |
| `vertices.index(before: startIndex)` and `edges.index(before: startIndex)` | Trap, like `index(after: endIndex)` | `steppingPastTheEnds` |
| `vertex(atPosition:)` at a hole or past the bound, `vertexPosition(of:)` of a non-vertex | Trap, per the protocol's preconditions | `sparseLookups` |

## Not tested

| Case | Why |
|---|---|
| Complexity (O(1) unlinking, O(1) `indices.contains`, row scans for `contains(edge:)`) and the performance targets | Benchmarks; the stress tests bound costs loosely |
| `_numberedRows(outward:)` and the other underscored hooks | Not public; covered through the algorithms that use them, compared with the compacted copy |
| The mirror's children | api.md lists `CustomReflectable` but not the children |
| `StableUnGraph`, compaction with old → new maps, `safe:` lookups | Deferred (open questions 3 and 8; the plan's later items) |
| rustworkx and NetworkX on random sequences | Not Swift tests; `ref.py --stress` checks 300 sequences against both, and the property tests use api.md's rules as their oracle |
