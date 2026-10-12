# StableGraphs test suite

`StableGraphs` has one graph type, `StableDirectedGraph<Vertex>`, after petgraph's `StableGraph`, and
maps attached to it, `EdgeMap` and `VertexMap` (LEMON's `ArcMap` and `NodeMap`). The graph is a
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
    changeTarget(ofEdgeAt:to:), changeSource(ofEdgeAt:to:), changeTarget(ofEdgeAt:checked:), changeSource(ofEdgeAt:checked:)
    // PropertyGraph (GraphProtocols)
    addEdgeMap(default:) -> EdgeMap<Value>, addVertexMap(default:) -> VertexMap<Value>, removeEdgeMap(_:), removeVertexMap(_:)
    addEdgeMap(of: T.self) -> EdgeMap<T?>, addVertexMap(of: T.self) -> VertexMap<T?>     // default nil
    subscript(map:ofEdgeAt:), subscript(map:ofVertexAt:), subscript(map:of:) -> Value { get set }   // trap at a dead element
    subscript(map:checkedEdgeAt:), subscript(map:checkedVertexAt:), subscript(map:checked:) -> Value { get throws }
    values(of:) -> EdgeValues<Self, Value> / VertexValues<Self, Value>, generation: GraphGeneration
struct EdgeMap<Value>, VertexMap<Value>: Hashable, Sendable  // handles
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
| Codable | `{vertices, vertexPositions, vertexEnd, edges, edgePositions, edgeEnd}`, every position and both ends kept; a far end decodes in O(elements) within `16 × count + 64` pages | SG-082 – SG-094, SG-108 – SG-116 |
| Pages | Positions keep their elements across freed pages; a position in a freed page reads as removed | SG-117 – SG-122 |
| Re-pointing | `changeTarget` / `changeSource` keep the position and the unchanged end's row place, and join the new end's row in position order | SG-123 – SG-130 |
| Maps | Attached to the graph; every element has the map's default until set (`nil` for `addEdgeMap(of:)`); every removal path removes the removed element's values, and a removed element has none (the plain subscripts trap, the `checked` ones throw); copies keep theirs; `changeTarget` keeps them; a map's pages are freed with the graph's | SG-131 – SG-134, SG-139 – SG-141 |

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
`StableGraphPropertyTests.swift`, `StableGraphSparseConformerTests.swift`, `Performance/StableGraphStressTests.swift`
and `StableGraphChurnTests.swift`) were generated from `cases.md`
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
| `StableGraphInsertionTests.swift` | 6 | SG-007 – SG-010, SG-103, SG-104: `insert(_:)`, `insert(edge:)` returning `edges.endIndex` and inserting endpoints, a self-loop; `insert(checked:)` with both endpoints, and with one missing (throws `VertexNotFound`, nothing changed) |
| `StableGraphEdgeRemovalTests.swift` | 21 | SG-011 – SG-025, SG-097 – SG-102: holes, no moves, positions never reused, the newest copy, absent pairs and non-vertices, `removeAllEdges(from:to:)` (one pass over the shorter row), row order across removals; `removeAllEdges(from:where:)` and `removeAllEdges(where:)`, each predicate call's position recorded and checked against row order |
| `StableGraphVertexRemovalTests.swift` | 9 | SG-026 – SG-034: vertex and edge holes, loops and copies, re-insertion at a fresh position, every vertex removed |
| `StableGraphSequenceTests.swift` | 6 | SG-035 – SG-040: mixed sequences, churn on one pair, a FlowNavigation replacement, both resets |
| `StableGraphQueryTests.swift` | 15 | SG-041 – SG-049, SG-105 – SG-107, SG-135 – SG-137: rows and copies in insertion order, membership after removals, degrees, live-or-stale checks; the `checked:` lookups on a vertex, a removed vertex and a non-vertex (throwing `VertexNotFound`), `descendants(checked:)` and `ancestors(checked:)`, `degree(checked:)` and `vertexIndex(checked:)`; `source(checkedEdgeAt:)` and `target(checkedEdgeAt:)` at live, removed, out-of-range and freed-page positions (throwing `EdgeNotFound`) |
| `StableGraphIndexTests.swift` | 12 | SG-066 – SG-077 without SG-062: dense indices and holes, numbering, BFS, the compacting conversion, `init(_:)` both ways, the undirected view, components, Dijkstra by position and topological sort against the compacted copy |
| `StableGraphEqualityTests.swift` | 4 | SG-078 – SG-081 |
| `StableGraphCodableTests.swift` | 22 | SG-082 – SG-094, SG-108 – SG-116: encoding, round trips keeping fresh positions, the empty and all-holes graphs, nine corrupt payloads; far ends (`Int.max`, 2⁶²) decode in O(1) when nothing follows the gap; page spans one past `16 × count + 64` throw, spans at it decode |
| `StableGraphPagingTests.swift` | 4 | SG-117, SG-118, SG-121, SG-122: edge and vertex churn across freed pages, `removeAll()` after churn, algorithms after churn |
| `StableGraphEdgeChangeTests.swift` | 6 | SG-123 – SG-127, SG-130: `changeTarget` / `changeSource` with copies, self-loops, the same endpoint, back and forth, after removals; the `checked:` spellings, throwing `ElementNotFound.edge` before `.vertex` |
| `StableGraphMapTests.swift` | 7 | SG-131 – SG-134, SG-139 – SG-141: an attached edge map's get, set and nil; every edge removal path removing values; a vertex map by position and by vertex through removal, churn and `removeAll`; several maps, a copy keeping its values, `changeTarget` keeping them, `removeEdgeMap`; a map with a default, new elements reading it, `values(of:)`, and the checked reads throwing at removed and out-of-range elements; edge and vertex map pages freed with the graph's |
| `StableGraphChurnTests.swift` | 8 | 3·10⁴ random churn steps across pages (seeded, PropertyBased) against a model of the live elements, with algorithms, an `EdgeMap` and Codable checked on the way; a copy unchanged by mutations that touch a few pages; attached maps across pages, on copies, removed from one copy; a removed element's map value released in the same call (`LifetimeTracked`), a copy keeping its own; a map's edge pages freed with the graph's through a vertex removal and the one-pass bulk removals; `removeAllEdges(keepingCapacity:)` keeping vertex holes both ways; a freed page between live ones (equality, Codable, numbering, stepping); every page freed |
| `StableGraphDescriptionTests.swift` | 2 | SG-095, SG-096 |
| `StableGraphGenerationTests.swift` | 2 | `generation` (GraphProtocols' `GraphGeneration`): every structural mutation starts one and every call that changes nothing keeps it (an existing vertex, an absent edge, the same endpoint, a predicate choosing nothing, capacity, maps); copies share one until mutated; built and decoded graphs have one; the undirected view reports the graph's |
| `StableGraphPreconditionTests.swift` | 30 | Exit tests: SG-050 – SG-065, SG-138 (`vertexIndex(checked:)` with a vertex hole), then `extra_traps.swift`: every neighbourhood and degree of a non-vertex or removed vertex; position lookups at holes, negative and past the end; positions from before a reset; dense index lookups; stepping past either end; a negative edge capacity; the sparse lookups |
| `StableGraphConformanceTests.swift` | 13 | Algorithms (Traversal; Connectivity's components, condensation, attracting components and dominator trees; ShortestPaths) on eight seeded graphs with many holes and before any removal, against the compacted copy; a DAG with holes; the laws with holes; `SparselyIndexedDirectedGraph` through generic code; the collections skipping holes and as values; rows as random-access collections of positions indexed by offset; Codable through JSON and property lists; Hashable; Sendable; the builder and initializers; resets; copy-on-write; capacity |
| `StableGraphPropertyTests.swift` | 4 | PropertyBased, shrinking: random sequences against the model; Codable round trips keeping the next fresh positions; equality and hashing ignoring positions and holes; algorithms on random graphs with holes against the compacted copy |
| `Performance/StableGraphStressTests.swift` | 6 | Inside a `Task` with a one-minute limit: a 10⁵-vertex cycle with every other vertex removed and re-connected; 10⁵ copies of one pair churned from both ends; a 10⁵-edge star with every other edge removed by position; a 300 × 300 grid with vertices removed and re-inserted; 10⁵ steps of vertex churn (quadratic before the row pools bounded packing by the row table); the three bulk removals on a 10⁵-edge star |
| `StableGraphSparseConformerTests.swift` | 2 | A test-local `SparselyIndexedDirectedGraph` outside the library, on the default `_numberedRows`: components, depth- and breadth-first search, descendants, ancestors, dominator and post-dominator trees against the wrapped graph and the compacted copy; post-dominators and `component(of:)` with one vertex hole against the hole-free graph |
| `StableGraphCheckedDispatchTests.swift` | 3 | The graph's own `checked:` lookups are the ones called on the concrete type, not GraphProtocols' defaults: its `vertexIndex(checked:)` traps on vertex holes (an exit test) where generic code's default throws |

141 catalog rows (120 value rows, 21 trap rows), 9 more exit tests (map handle misuse and reads
and writes of dead elements among them) and 36 more tests (14 conformance, 4 property, 6 stress, 8
churn, 2 sparse conformer, 2 generation): 186 tests in all. The property tests also re-point edges and fill
attached maps, checking after every step that a map has values at exactly the live positions it
was given them for, and that every dead position's checked read throws.

## Case IDs

Case IDs (SG-001 … SG-141) refer to the catalog (`cases.md`), whose values `ref.py` computes with a
port of the proposed storage, checks against a plain specification and the laws in every state, and,
with `--stress`, checks against rustworkx 0.18.1 (petgraph's `StableGraph`) and NetworkX 3.7. Each
test's name starts with its ID; tests without an ID check laws, properties or conformance that the
catalog does not list.

| Cases | Section | File |
|---|---|---|
| SG-001 – SG-006 | Construction | `StableGraphConstructionTests.swift` |
| SG-007 – SG-010, SG-103, SG-104 | Insertion | `StableGraphInsertionTests.swift` |
| SG-011 – SG-025, SG-097 – SG-102 | Edge removal | `StableGraphEdgeRemovalTests.swift` |
| SG-026 – SG-034 | Vertex removal | `StableGraphVertexRemovalTests.swift` |
| SG-035 – SG-040 | Interleaving | `StableGraphSequenceTests.swift` |
| SG-041 – SG-049, SG-105 – SG-107, SG-135 – SG-138 | Queries (SG-138 is a trap) | `StableGraphQueryTests.swift`, `StableGraphPreconditionTests.swift` |
| SG-050 – SG-065 | Traps (SG-062 is listed under Conformance) | `StableGraphPreconditionTests.swift` |
| SG-066 – SG-077 | Conformance | `StableGraphIndexTests.swift` |
| SG-078 – SG-081 | Equality and hashing | `StableGraphEqualityTests.swift` |
| SG-082 – SG-094, SG-108 – SG-116 | Codable | `StableGraphCodableTests.swift` |
| SG-095, SG-096 | Description | `StableGraphDescriptionTests.swift` |
| SG-117 – SG-122 | Paging (SG-119, SG-120 are traps) | `StableGraphPagingTests.swift`, `StableGraphPreconditionTests.swift` |
| SG-123 – SG-130 | Edge change (SG-128, SG-129 are traps) | `StableGraphEdgeChangeTests.swift`, `StableGraphPreconditionTests.swift` |
| SG-131 – SG-134, SG-139 – SG-141 | Maps | `StableGraphMapTests.swift` |

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
| That memory follows the live elements (pages freed, tables trimmed) | Not observable through the public API: StableGraphsBenchmarks measures the allocator's bytes after churn and asserts at setup that 10× the churn holds about the same bytes |
| `_numberedRows(outward:)` and the other underscored hooks | Not public; covered through the algorithms that use them, compared with the compacted copy |
| The mirror's children | api.md lists `CustomReflectable` but not the children |
| `StableUnGraph`, compaction with old → new maps | Deferred (open questions 3 and 8; the plan's later items) |
| rustworkx and NetworkX on random sequences | Not Swift tests; `ref.py --stress` checks 300 sequences against both, and the property tests use api.md's rules as their oracle |
