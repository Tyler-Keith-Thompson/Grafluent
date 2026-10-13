# Multigraphs test suite

`Multigraphs` has four mutable representations that keep parallel edges: `Pseudograph<Vertex>`
(undirected, copies and self-loops), `Multigraph<Vertex>` (undirected, copies, no self-loop),
`DirectedPseudograph<Vertex>` and `DirectedMultigraph<Vertex>` (the same, directed). The
pseudographs hold the storage, laid out like `UndirectedAdjacencyList` and `AdjacencyList` (dense
slots, rows, swap-remove) with a parallel class per vertex pair that keeps the copies in insertion
order. The multigraphs wrap a pseudograph and add the no-loop invariant. The suite uses only the
public API, and each test is self-contained. The shared material is `ReferencePseudograph`,
`ReferenceDirectedMultigraph`, the named fixtures, `Collider`, the seeded generator and the tags in
`GrafluentTestSupport`. The catalog (`api.md`, `ref.py`, `cases.md`, `swiftgen.py`) is in
[`Tests/Catalogs/Multigraphs/`](../Catalogs/Multigraphs/).

## API under test

```swift
struct Pseudograph<Vertex: Hashable>: Graph, Hashable, Codable (Vertex: Codable), Sendable (Vertex: Sendable),
                                      CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable
    init(), init(vertices:), init(edges:), init(vertices:edges:), init(@GraphBuilder _:), init(_ graph: some Graph<Vertex>)
    func contains(edge:) -> Bool                                   // at least one copy, either orientation; never traps
    func edges(between:and:) -> EdgesConnecting                    // positions, oldest copy first; a value
    func edgeCount(between:and:) -> Int
    insert(_:), insert(edge:) -> Int                               // the new copy's position, the old edgeCount
    remove(_:), remove(edge:) -> UndirectedEdge?                   // the newest copy, in its stored orientation
    remove(edgeAt:) -> UndirectedEdge, removeAllEdges(between:and:) -> Int
    removeAll(keepingCapacity:), removeAllEdges(keepingCapacity:), reserveCapacity(vertexCount:edgeCount:)
    insert(checked:) throws(VertexNotFound) -> Int                 // only between existing vertices
    neighbors(checked:), incidentEdges(checked:), degree(checked:), vertexIndex(checked:)  // throw VertexNotFound
struct Multigraph<Vertex: Hashable>                                // the same; init?(edges:), init?(vertices:edges:),
                                                                   // init?(builder), init?(_ graph:) nil on a loop;
                                                                   // insert(edge:) throws LooplessEdgeError.selfLoop
                                                                   // on a loop; insert(checked:) also .missingEndpoint
struct DirectedPseudograph<Vertex: Hashable>: BidirectionalDirectedGraph, …   // edges(from:to:), edgeCount(from:to:),
                                                                   // removeAllEdges(from:to:); the directed checked:
                                                                   // lookups, source/target(checkedEdgeAt:) (EdgeNotFound)
struct DirectedMultigraph<Vertex: Hashable>                        // as Multigraph, directed
// The pseudographs are PropertyGraphs (dense, swap-moved maps) and stamp a generation; the
// multigraphs are GraphDelegators of them (`base`), so every read, the maps and `generation` are
// their base's.
    addEdgeMap(default:), addEdgeMap(of:), addVertexMap(default:), addVertexMap(of:), removeEdgeMap(_:), removeVertexMap(_:)
    subscript(map, ofEdgeAt:), subscript(map, of:), subscript(map, ofVertexAt:)   // get set; trap outside the graph
    subscript(map, checkedEdgeAt:), subscript(map, checked:), subscript(map, checkedVertexAt:)  // throw EdgeNotFound / VertexNotFound
    values(of:) -> EdgeValues / VertexValues, generation: GraphGeneration
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Positions | Edges at `0..<edgeCount` in insertion order, each in its given orientation; a removal moves the last edge into the hole | MG-045, MG-047 – MG-054, MG-068, MG-069 |
| Rows | Freshly built: each edge appended at u, then at v (a loop's two ends adjacent), as the reference conformers; a removal moves the row's last entry into the hole, an undirected loop's later end first | MG-042 – MG-046, MG-072 – MG-074 |
| Parallel classes | `edges(between:and:)` / `edges(from:to:)` list the copies oldest first, an order that survives the renaming of positions | MG-015 – MG-025, MG-065, MG-070, MG-096 |
| `remove(edge:)` | The newest copy, returned in its stored orientation; nil, without a change, for an absent pair or a non-vertex | MG-055 – MG-067 |
| `removeAllEdges(between:and:)` | Repeated `remove(edge:)`; returns the count; both vertices stay; directed: one direction | MG-084 – MG-089 |
| Vertex removal | Its edges detached last row entry first (out row, then in row), then the last slot moves into its place | MG-090 – MG-104 |
| Loops and degrees | Undirected: twice in the row, degree 2, once in `edges(between: v, and: v)`; directed: once out, once in, degree 2 | MG-026 – MG-031, MG-036 |
| No-loop invariant | Failable initializers and decoding reject a loop; `insert(edge:)` throws `LooplessEdgeError.selfLoop` and changes nothing | MG-011 – MG-013, MG-032 – MG-034, MG-139, MG-140, MG-168, MG-171, MG-175, MG-176 |
| `checked:` spellings | Throw where the plain spellings trap and change nothing: `VertexNotFound` for a non-vertex, `EdgeNotFound` for a position outside `0..<edgeCount`; the multigraphs' `insert(checked:)` throws `LooplessEdgeError`, `.missingEndpoint` before `.selfLoop` | MG-193 – MG-211 |
| Equality | Equal vertex sets and equal edge multisets (orientation ignored for the undirected types) | MG-115 – MG-128 |
| Codable | The simple lists' format, plus a `copyOrder` key when a removal left a class out of position order; vertex order, positions and class order kept, rows rebuilt in position order | MG-129 – MG-153, MG-1002, MG-1003 |
| Attached maps | Dense, one value per position or slot; every removal swap-moves the values with the storage, so a value stays with its edge copy or vertex; a new element reads the default; `removeAllEdges()` / `removeAll()` empty the maps and keep them attached; plain reads trap outside the graph and `checked` reads throw; the multigraphs' maps are their base's | MG-212 – MG-226, `MultigraphMapPropertyTests.swift`, `MultigraphMapPreconditionTests.swift` |
| Generations | Every structural mutation starts one; a call that changes nothing, a map write and `reserveCapacity` do not; bulk builds and decoding stamp one; the multigraphs report their base's | `MultigraphGenerationTests.swift` |
| Conversions | To the simple lists: each pair's first copy by position, in its orientation. From any graph: vertices in order, then every edge in `edges` order. From the same type: unchanged, rows included | MG-160 – MG-178 |

## How values are pinned

Every catalog row is written as the catalog writes it: `Kind(vertices: V, edges: E)` with the
listed vertices and the edges in written order, then the calls in order, each call's result
checked. The final state is written out in full: `vertices`, `edges` by position as `[u, v]` /
`[source, target]` (since `UndirectedEdge` equality ignores orientation), `vertexCount`,
`edgeCount`, and every vertex's rows (`neighbors` and `incidentEdges`, or `successors`,
`outEdges`, `predecessors` and `inEdges`, empty rows included, where the catalog omits them). Beyond
the catalog cell, each final state also checks `edges(between:and:)` / `edges(from:to:)` and
`edgeCount` for every pair that has an edge, with ref.py's model's class order (which ref.py checks
against the key order of NetworkX 3.7's `G[u][v]`). The catalog-row files (MG-001 – MG-226) are
generated from `cases.md` by `swiftgen.py`, which says how to run it. It first checks that `ref.py` reproduces `cases.md` exactly, then re-evaluates each row
with `ref.py`'s model (structured values, not the printed cells), asserts that every value matches
the catalog cell, and writes it out.

Trap rows run the trapping call in a child process (an exit test), built from `init(vertices:)` and
`insert(edge:)` so the child never unwraps a failable initializer; the same setup then runs in this
process one step short of the precondition, so a trap in the setup would fail the test. Codable
rows check the encoding byte for byte with sorted keys (`{"edges":[…],"vertices":[…]}`), decode
both that and the catalog's payload, and check the decoded state; corrupt payloads check the
`DecodingError` case and, for `dataCorrupted`, the catalog's message.

The laws, conformance, property and stress files compute their expectations inside each test:
from the graph's own `edges` (every position's ends, the copies of each pair, degree sums), from
`ReferencePseudograph` / `ReferenceDirectedMultigraph` built the same way, from the named
fixtures' `pseudographEdgeCount` and `pseudographDegree`, from a model kept beside the graph, and
from closed forms (removing position 0 k times from n copies leaves the class `1, …, n − k − 1, 0`).

The property tests' model holds a vertex list in slot order, an edge list in position order (each
edge in its stored orientation, with an insertion stamp) and each vertex's rows, and follows only
the documented rules: insertion appends at u, then at v; a removal moves the last edge into the
hole and each row's last entry into its hole (for an undirected loop the later end first); a
vertex removal detaches its row from the last entry, then moves the last slot into its place;
`remove(edge:)` takes the copy with the newest stamp; `edges(between:and:)` lists the copies by
stamp. Every result and the whole state (vertices, edges, rows, index rows, every pair's class,
`contains(edge:)`, equality and hash with a graph rebuilt from the model in shuffled orders) are
checked after every step, for all four types.

## Files

| File | Tests | Covers |
|---|---|---|
| `MultigraphConstructionTests.swift` | 14 | MG-001 – MG-014: the four types empty, listed vertices first (a repeat once), endpoints in first-appearance order, `String` vertices, the multigraphs nil on a loop, opposite arcs, the builder |
| `MultigraphQueryTests.swift` | 30 | MG-015 – MG-046 without the trap rows: copies in both orientations, interleaved copies, absent pairs and non-vertices (empty, 0, false, no trap), directed copies, loops (twice in a row, degree 2), degrees counting copies, rows of fresh graphs |
| `MultigraphInsertionTests.swift` | 8 | MG-047 – MG-054: positions returned, endpoints inserted, loops, `insert(_:)`, insertion after a removal |
| `MultigraphEdgeRemovalTests.swift` | 31 | MG-055 – MG-089 without the trap rows: the newest copy, orientation-free lookup and the stored orientation returned, absent pairs, re-insertion, loops, class order across moves, `remove(edgeAt:)` from the front, the back and the middle, loops moved and removed, `removeAllEdges(between:and:)` / `(from:to:)` |
| `MultigraphVertexRemovalTests.swift` | 15 | MG-090 – MG-104: the last slot moved in, copies and loops removed, a moved vertex with loops and copies, class order between survivors, directed, the wrappers, every vertex |
| `MultigraphSequenceTests.swift` | 10 | MG-105 – MG-114: mixed sequences, `removeAllEdges()`, `removeAll()`, `String` vertices, re-inserting a removed vertex |
| `MultigraphEqualityTests.swift` | 14 | MG-115 – MG-128: equality and hashing |
| `MultigraphCodableTests.swift` | 25 | MG-129 – MG-153: round trips, copies and loops accepted, loops rejected by the multigraphs, odd length, repeated vertex, endpoints out of range, missing keys, cross-type payloads |
| `MultigraphDescriptionTests.swift` | 6 | MG-154 – MG-159: `description`, `debugDescription`, the 16-item limit |
| `MultigraphConversionTests.swift` | 19 | MG-160 – MG-178: to and from the simple lists, between the multigraphs and the pseudographs, through `.undirectedView` and `.directedView`, the same type unchanged |
| `MultigraphMapTests.swift` | 15 | MG-212 – MG-226: attached maps on the four types: a default map, a map of an Optional, the values through `remove(edgeAt:)`, `remove(edge:)`'s newest copy, `removeAllEdges(between:and:)` / `(from:to:)`, vertex removal with loops and copies and the slot that moves in, `removeAllEdges()` and `removeAll()`, two maps with one removed, `String` vertices, `insert(checked:)`, the `checked` reads, the multigraphs through their base; every final state checks every map at every position and vertex |
| `MultigraphMapPropertyTests.swift` | 4 | PropertyBased, shrinking: on each of the four types, random insertions, removals, clears and value writes against a model keyed by each copy's insertion stamp and by vertex (the copy at a position is named by its ordinal in `edges(between:and:)` / `edges(from:to:)`, not by the maps); every value through the subscripts and `values(of:)` after every step |
| `MultigraphMapCopyTests.swift` | 2 | On both pseudographs, two copies with an edge map and a vertex map: every mutation on one (insertions, every removal path, `reserveCapacity`, the clears, value writes), then every mutation on the other, in both orders; each copy's values are what its own mutation alone gives, and so after a further insertion on each |
| `PseudographMapConcurrencyTests.swift` | 1 | Two copies of a `Pseudograph` with an edge map and a vertex map, inserting edges with new endpoints, writing their values and removing an edge on two threads at once, over many rounds; each copy's maps then hold one value per edge and per vertex, and only its own |
| `MultigraphMapPreconditionTests.swift` | 12 | Exit tests: map reads and writes at removed or out-of-range positions and slots, non-vertices, a handle from another graph or after `remove…Map`, on the four types; then the setups without the trapping calls |
| `MultigraphGenerationTests.swift` | 7 | Every structural mutation of both pseudographs starts a generation and a call that changes nothing does not; copies; built, bulk-built and decoded graphs; the multigraphs report their base's; on both pseudographs, two copies under every interleaving of three steps never share a generation in different states |
| `MultigraphDelegatorTests.swift` | 5 | The multigraphs answer every read requirement as their base through a generic context; maps attached through the wrapper or the base read through either and survive the O(1) conversions; equality, hashing and coding ignore maps |
| `MultigraphCheckedTests.swift` | 19 | MG-193 – MG-211: `insert(checked:)` on the four types (a copy, a missing endpoint, the multigraphs' self-loop, a loop at a missing vertex), the vertex lookups' `checked:` spellings present and absent, `source` / `target(checkedEdgeAt:)` in and out of range and after a removal, `String` vertices, a moved slot |
| `MultigraphReviewTests.swift` | 3 | MG-1001 – MG-1003: `edges(between:and:)` as a bidirectional collection (`.last` is the newest copy, `reversed()`), a Codable round trip keeping the order of copies a removal put out of position order, a malformed copy order throwing |
| `MultigraphIndexHookTests.swift` | 4 | The index-space hooks (`outDegree(ofIndex:)`, `inDegree(ofIndex:)`, `sourceIndex(ofEdgeAt:)`, `targetIndex(ofEdgeAt:)`, `degree(ofIndex:)`, `endpointIndices(ofEdgeAt:)`) against the vertex-space members after removals |
| `MultigraphOutIndexRowsTests.swift` | 2 | `_withOutIndexRows` against `successorIndices(ofIndex:)` and `outEdges(ofIndex:)` after removals |
| `PseudographMutableGraphTests.swift` | 1 | `Pseudograph` through `MutableGraph`, called generically |
| `MultigraphPreconditionTests.swift` | 20 | Exit tests: MG-039, MG-040, MG-075 – MG-077, MG-080, MG-179 – MG-192 |
| `MultigraphLawTests.swift` | 8 | `Graph`'s laws (counts, index maps, rows against `edges`, `oppositeVertex`, degrees, edge indices, every pair's class, `contains(edge:)`, `_withIncidentIndexRows` read back) on `Pseudograph` fresh and after removals; `Multigraph` forwarding every requirement to its storage; `BidirectionalDirectedGraph`'s laws on both directed types; the drop-in check against both reference conformers on hand-made shapes and every fixture; the fixtures' pseudograph degrees; generic code |
| `MultigraphConformanceTests.swift` | 10 | Codable through JSON and property lists after removals, malformed payloads throwing on all four types, Hashable (orders ignored, multisets told apart, colliding vertex hashes), `Sendable` across a `Task`, the mirror, the builders with control flow, the remaining initializers, `EdgesConnecting` as a collection and a value, copy-on-write on every mutation, capacity |
| `MultigraphPropertyTests.swift` | 10 | PropertyBased, shrinking: random operation sequences against the model for each of the four types; the laws on random graphs after random removals (undirected, directed); equality and hashing independent of orders; Codable round trips; the collapse to the simple lists and simple graphs both ways; the drop-in check against the reference conformers |
| `Performance/MultigraphStressTests.swift` | 4 | Inside a `Task` with a one-minute limit: 10⁵ copies of one pair (newest-first removal, removal from the front, directed with a second class), a seeded random pseudograph and directed pseudograph on 10⁵ vertices against the reference conformers and then half removed, 10⁵ edges inserted and removed again by edge, by pair, by vertex and by position |

298 tests in all.

## Case IDs

Case IDs (MG-001 … MG-226) refer to the catalog (`cases.md`), whose values `ref.py` computes with
api.md's model and checks against NetworkX 3.7 `MultiGraph` / `MultiDiGraph` (degrees,
`number_of_edges(u, v)` for every pair, the self-loop count, the copy `remove_edge(u, v)` removes,
the key order of `G[u][v]`, the collapse to `nx.Graph` / `nx.DiGraph`). Each test's name starts with
its ID; tests without an ID check laws, properties or conformance that the catalog does not list.

| Cases | Section | File |
|---|---|---|
| MG-001 – MG-014 | Construction | `MultigraphConstructionTests.swift` |
| MG-015 – MG-046 | Parallel copies, loops, degrees, rows | `MultigraphQueryTests.swift` (traps MG-032 – MG-034, MG-039, MG-040 in `MultigraphPreconditionTests.swift`) |
| MG-047 – MG-054 | Insert | `MultigraphInsertionTests.swift` |
| MG-055 – MG-089 | Remove edge, remove at, remove all copies | `MultigraphEdgeRemovalTests.swift` (traps MG-075 – MG-077, MG-080 in `MultigraphPreconditionTests.swift`) |
| MG-090 – MG-104 | Remove vertex | `MultigraphVertexRemovalTests.swift` |
| MG-105 – MG-114 | Sequences | `MultigraphSequenceTests.swift` |
| MG-115 – MG-128 | Equality | `MultigraphEqualityTests.swift` |
| MG-129 – MG-153 | Codable | `MultigraphCodableTests.swift` |
| MG-154 – MG-159 | Descriptions | `MultigraphDescriptionTests.swift` |
| MG-160 – MG-178 | Conversions | `MultigraphConversionTests.swift` |
| MG-179 – MG-192 | Preconditions (traps) | `MultigraphPreconditionTests.swift` |
| MG-193 – MG-211 | `checked:` spellings | `MultigraphCheckedTests.swift` |
| MG-212 – MG-226 | Attached maps | `MultigraphMapTests.swift` |
| MG-1001 – MG-1003 | Bidirectional copies, copy order through Codable (not in the catalog) | `MultigraphReviewTests.swift` |

## Readings of what api.md leaves open

| Question | Reading taken | Where |
|---|---|---|
| Degrees of a non-vertex on the directed types (MG-040, `degrees(1)`) | `outDegree`, `inDegree` and `degree` each trap: three exit tests | MG-040 |
| The decoding error messages | The catalog's: the simple lists' `Edge list has odd length`, `Repeated vertex`, `Edge endpoint out of range`, and `Self-loop` for the multigraphs, each as `dataCorrupted` | MG-139 – MG-153 |
| The coding keys | `vertices` and `edges`, as api.md and the catalog name them; encoding checked byte for byte with sorted keys | MG-129 – MG-136 |
| `Pseudograph(_:)` from a `Pseudograph` through the generic initializer | Unchanged, rows included: api.md documents it on `init(_ graph: some Graph<Vertex>)` itself, so a `some Graph` argument whose dynamic type is `Pseudograph` keeps its rows too | MG-178 |
| The mirror's children | `vertices` as `[Vertex]` and `edges` as `[UndirectedEdge<Vertex>]`, as the simple lists show them | `mirror` |
| `Sendable` views | `Edges` and `Neighbors` (the simple lists' types) cross a `Task`; `EdgesConnecting` is not required to be `Sendable` | `sendable` |
| Hash quality | Equal values hash alike; twelve graphs with the same counts but different edge multisets hash differently | `hashing` |
| `edges(between:and:)` for an undirected pair asked in the other order | The same copies in the same order | `pseudographLaws`, property tests |

## Not tested

| Case | Why |
|---|---|
| Complexity (O(1) `edgeCount(between:)` and `remove(edge:)`, the class map's cost against `UndirectedAdjacencyList`, `Pseudograph(multigraph)` in O(1), no copy of shared storage on a no-op or trapping mutation) | Benchmarks; the stress tests bound costs loosely, and the copy-on-write test checks values only |
| A trapping `insert(edge:)` on a multigraph leaving no stray vertex | The trap ends the child process, so its state cannot be observed |
| `_withSuccessorIndexRows` on the directed types | An underscored hook; the directed types keep the protocol's default (`nil`), which is not a contract |
| `_withOutIndexRows` beyond agreement with `successorIndices`/`outEdges` | `MultigraphOutIndexRowsTests.swift` checks only that the lent rows are the stored ones |
| NetworkX on random graphs (`just diff`) | Not Swift tests; `ref.py` checks every catalog row and 1,200 random sequences against NetworkX 3.7, and the property tests use the documented rules as their oracle |
