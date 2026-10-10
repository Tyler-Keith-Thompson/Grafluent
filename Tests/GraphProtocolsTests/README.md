# GraphProtocols test suite

`DirectedGraph` and `BidirectionalDirectedGraph` are the protocols every directed representation
conforms to, and `Graph` the one every undirected representation conforms to; algorithms are
written against them. These tests check the protocols themselves:
the default implementations, dispatch to a representation's own members, which types conform,
generic algorithms that must give the same answers on every representation, and conversions
between representations. The laws each representation must satisfy live in that representation's
own test target (`<Type>DirectedGraphTests.swift`), next to its other tests.

Every value is read through a generic (or existential) function declared inside the test, never
through a concrete type. That alone cannot catch a member whose signature misses the requirement
and silently falls back to the default, since the default gives the same answers; the comparison
counting and benchmarks described below do. Algorithms are written in the test that uses them, so
each test can be copied on its own. Expected values for the algorithms were computed with
NetworkX.

## The protocols

```swift
protocol DirectedGraph<Vertex>
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    associatedtype Edges: Collection<DirectedEdge<Vertex>> where Edges.Index: Hashable
    associatedtype Successors: Sequence<Vertex>
    associatedtype OutEdges: Sequence<Edges.Index>
    var vertices: Vertices
    var edges: Edges
    func successors(of:) -> Successors          // targets, once per edge, in outEdges order
    func outEdges(of:) -> OutEdges              // positions in edges: the edges' identities
    // Requirements with defaults, so a representation's faster version is what generic code calls:
    func source(ofEdgeAt:) / target(ofEdgeAt:) -> Vertex     // edges[position].source / .target
    var vertexCount: Int                        // vertices.count
    var edgeCount: Int                          // edges.count
    func contains(_:) -> Bool                   // a scan of vertices
    func contains(edge:) -> Bool                // endpoints checked, then a scan of successors
    func outDegree(of:) -> Int                  // the length of successors
    var vertexIndexBound: Int?                  // nil: no dense vertex indices
    func vertexIndex(of:) -> Int                // traps without indices
    func vertex(atIndex:) -> Vertex             // traps without indices

protocol BidirectionalDirectedGraph<Vertex>: DirectedGraph
    associatedtype Predecessors: Sequence<Vertex>
    associatedtype InEdges: Sequence<Edges.Index>
    func predecessors(of:) -> Predecessors      // sources, once per edge, in inEdges order
    func inEdges(of:) -> InEdges
    func inDegree(of:) -> Int                   // the length of predecessors
    func degree(of:) -> Int                     // outDegree + inDegree
```

```swift
struct UndirectedEdge<Vertex: Hashable>: Hashable  // Comparable, Sendable, BitwiseCopyable, Codable when Vertex is
    init(_ u: Vertex, _ v: Vertex)
    var u: Vertex, v: Vertex, isSelfLoop: Bool  // u, v keep the order given; == and hash ignore it
    func oppositeVertex(to: Vertex) -> Vertex   // the vertex itself across a self-loop; traps off the edge
    // description "u–v"

protocol Graph<Vertex>
    associatedtype Vertex: Hashable
    associatedtype Vertices: Collection<Vertex>
    associatedtype Edges: Collection<UndirectedEdge<Vertex>> where Edges.Index: Hashable
    associatedtype Neighbors: Sequence<Vertex>
    associatedtype IncidentEdges: Sequence<Edges.Index>
    var vertices: Vertices
    var edges: Edges                            // every edge once, each copy once, a self-loop once
    func neighbors(of:) -> Neighbors            // the far end of every edge end: a self-loop's vertex twice
    func incidentEdges(of:) -> IncidentEdges    // positions in edges, once per end: a self-loop twice
    // Requirements with defaults:
    func oppositeVertex(to:acrossEdgeAt:)       // edges[position].oppositeVertex(to:)
    var vertexCount: Int, edgeCount: Int
    func contains(_:) / contains(edge:)         // never trap; contains(edge:) in either orientation
    func degree(of:) -> Int                     // the length of neighbors: a self-loop counts 2
    var vertexIndexBound: Int?; func vertexIndex(of:), vertex(atIndex:), neighborIndices(ofIndex:)

extension Graph { var directed: DirectedView<Self> }                         // each edge as two arcs
extension BidirectionalDirectedGraph { var undirected: UndirectedView<Self> } // each arc as an edge
```

The laws are written in the protocols' documentation. The directed laws are tested in each
representation's suite; the undirected laws are tested here, in `GraphLawTests.swift`, on every
conformer.

| Type | `DirectedGraph` | Bidirectional | Edge positions | Vertex indices | From any graph |
|---|---|---|---|---|---|
| `AdjacencyList` | yes | yes | (source slot, offset); valid until mutated | the slots; `vertexIndex(of:)` is a hash lookup | `AdjacencyList(_:)`: keeps isolated vertices, collapses parallel edges |
| `AdjacencyMatrix` | yes | yes | the cell | the vertices themselves | `AdjacencyMatrix(_:)`: the vertices must be exactly `0..<vertexCount` |
| `CompressedSparseRow` | yes | no: no in-adjacency | the edge index `0..<m` | the vertices themselves | `CompressedSparseRow(_:)`: as for the matrix |
| `EdgeList` | **no** | — | — | — | `EdgeList(_:)` lists any graph's edges; a list becomes a graph through `AdjacencyList(edges:)` or `CompressedSparseRow(vertexCount:edges:)` |

| Type | `Graph` | Edge positions | Vertex indices | From any graph |
|---|---|---|---|---|
| `UndirectedAdjacencyList` | yes | `0..<edgeCount`; valid until mutated | the slots | `UndirectedAdjacencyList(_:)`: keeps isolated vertices, collapses parallel edges, keeps self-loops |
| `DirectedView` (`graph.directed`) | no: a `BidirectionalDirectedGraph` | (base position, reversed) | the base's | `AdjacencyList(g.directed)` collapses a loop's two arcs into one |
| `UndirectedView` (`digraph.undirected`) | yes | the base's own | the base's | reciprocal arcs stay two parallel edges; `UndirectedAdjacencyList(_:)` collapses them |
| `ReferencePseudograph` (test support) | yes | `0..<edgeCount`, written order | written order | — |

## Conventions

| Question | Choice | Why | Disagreement |
|---|---|---|---|
| Defaults | Requirements with defaults, not extension methods | Swift dispatches extension methods statically, so a representation's O(1) `outDegree` would be ignored by generic code | SwiftGraph's `edgeCount` is an extension member |
| Edge identity | An edge is its position in `edges`; `outEdges(of:)` and `inEdges(of:)` list positions, and per-edge values are keyed by `Edges.Index` | Parallel edges must be told apart, and weights, capacities and flow need a key; `Collection.Index` is Swift's spelling of a position | Boost's edge descriptors, petgraph's `EdgeId`, LEMON's arc ids; gonum keys by vertex pair and keeps multigraphs separate |
| Vertex indices | Requirements with defaults (`vertexIndexBound` is `nil` by default), not a refinement | An overload on a refinement is chosen statically, so a second generic layer or an existential would never reach it | petgraph's `NodeIndexable` is a separate trait, but Rust's specialization story differs |
| Parallel edges | Allowed by the base protocol; neighborhoods list a vertex once per edge, counts include repeats, `contains(edge:)` means at least one copy | Then `outDegree == successors.count` everywhere, and Kahn's algorithm needs no special case | NetworkX's `MultiDiGraph` lists distinct successors but counts every edge in `out_degree` |
| Absent vertex | A precondition: a representation may trap or return empty; generic code relies on neither | Matches `Collection`'s "must be a valid index" | NetworkX raises, JGraphT throws, petgraph's `Graph` returns empty, its `Csr` panics |
| `contains` | Never traps; false for anything absent | — | — |
| `EdgeList` | Not a `DirectedGraph` | Every adjacency query scans all edges, so a generic traversal would be O(n·m) without warning | Boost's `edge_list` likewise models only `EdgeListGraph` |
| Finite graphs | `vertices` and `edges` are required; no successors-only base protocol | Every representation is finite, and an edge needs a position; infinite searches get closure-based entry points | Boost's `IncidenceGraph` and petgraph's `IntoNeighbors` need only out-edges |
| Wrappers | A generic wrapper (a view, a relabeling) implements every requirement by forwarding | A default chosen for the wrapper is chosen once, for every base, and ignores the base's faster member | petgraph's `Reversed` forwards each trait |
| `Sendable` | Not refined by the protocols | Representations are conditionally `Sendable`; algorithms ask for `DirectedGraph & Sendable` | — |
| Successors type | `Sequence` | Implicit graphs compute neighbors; `Span` is not a `Sequence` | — |
| Integer graphs that are not `0..<n` | Converting to a matrix or CSR traps | Inferring `max + 1` or renumbering would change what the vertices mean | petgraph and GAP infer `max + 1` |
| Self-loops in undirected neighborhoods | Once per end: `v` twice in `neighbors(of: v)`, the position twice in `incidentEdges(of: v)`, 2 to `degree` | `degree == neighbors.count` everywhere and the degrees sum to `2 · edgeCount`; it is what the undirected view of a directed loop gives | Boost `adjacency_list`, LEMON and igraph agree; NetworkX, JGraphT and petgraph list the loop once while counting it 2 in the degree |
| Undirected edge identity | One position in `edges`, reached from both ends | A weight keyed by position is the same in both directions | Boost and petgraph orient each incidence instead |
| Undirected and directed | Separate protocols; no type is both | `edges` cannot have both element types; the views cross over | LEMON's undirected graphs are also digraphs |
| Traversal on undirected graphs | Through `directed`, the existing directed search | Breadth-first search is identical; edge-classifying searches (bridges, undirected DFS) need edge identity and are written over `incidentEdges` | Boost has a separate `undirected_dfs` |

## Files

| File | Covers |
|---|---|
| `ReferenceDirectedMultigraph.swift` | A test conformer: a multigraph with indexed adjacency, for the parallel-edge rules |
| `DirectedGraphDefaultTests.swift` | The defaults through minimal test conformers (single-pass and collection neighborhoods), and that generic code, a second generic layer and existentials call a conformer's own members |
| `DirectedGraphLawTests.swift` | The laws on the multigraph, seeded random graphs observed identically through every representation, and Tarjan's components in reverse topological order |
| `DirectedGraphConformanceTests.swift` | Associated types read through generic code, which types conform, `some` and `any` use, `Sendable`, parallel edges told apart by position, Dijkstra on edge positions, vertex indices through generic layers, conversions and round trips |
| `DirectedGraphAlgorithmTests.swift` | Breadth-first distances and order, depth-first preorder, Kahn's topological generations (including on a multigraph), Tarjan's and Kosaraju's strongly connected components, reverse reachability, and the same through existentials, on every representation |
| `ReferencePseudograph.swift` | A test conformer (in `GrafluentTestSupport`): an undirected pseudograph, loops and parallel edges kept in written order, with indexed adjacency |
| `UndirectedFixtures.swift` | The named undirected fixtures (in `GrafluentTestSupport`), each with simple and pseudograph expected values |
| `UndirectedEdgeTests.swift` | `UndirectedEdge`: symmetric equality and hashing, distinct self-loops, `oppositeVertex`, `Comparable`, kept orientation, description, `Codable`, conditional conformances |
| `GraphLawTests.swift` | The `Graph` laws on `UndirectedAdjacencyList` (Int and String vertices) and on the pseudograph, generic against concrete and against the fixtures, and seeded random graphs observed identically through both |
| `GraphDefaultTests.swift` | The `Graph` defaults through minimal conformers (single-pass and collection neighborhoods), and that generic code, a second generic layer and existentials call a conformer's own members |
| `GraphConformanceTests.swift` | Associated types, `some` and `any Graph`, `Sendable`, that no type is both a `Graph` and a `DirectedGraph`, the `GraphBuilder`, conditional `Comparable`, parallel edges told apart by position, vertex indices through generic layers |
| `GraphAlgorithmTests.swift` | Breadth-first distances and layers, depth-first preorder, connected components, undirected edge classification, bridges, the Euler circuit condition and two-coloring, on both conformers and through existentials |
| `GraphViewTests.swift` | The `directed` and `undirected` views: the directed laws on the two-arc view, its exact arcs, Kosaraju and Traversal's search through it, reciprocal arcs and loops in the undirected view, positions, round trips and conversions |
| `GraphReviewTests.swift` | Added after the critical review: the edge-index laws (UG-L24) on the adjacency list and the pseudograph, and their absence on the undirected view; with edge indices, `edges` in index order (UG-L25); the directed view's predecessor indices and emptiness; the builder's `if` without `else` |
| `DirectedEdgeIndexTests.swift` | Dense edge indices on `DirectedGraph`: one-to-one onto `0..<edgeCount` (DG-L29), out-edges by index (DG-L30), and `edges` in index order (DG-L31, so `undirected` keeps UG-L25), on the adjacency list and compressed sparse row; in-edges by index (DG-L32) on every bidirectional representation and the directed view, through removals |

Case IDs (DG-L01, DG-A09, …) refer to the protocol design catalog (`Tests/Catalogs/GraphProtocols/directed-graph.md`), which drew on Boost's graph
concepts, petgraph's `visit` traits, JGraphT's `Graph`, LEMON's concepts and NetworkX.

Each representation's suite also checks that its own members are what generic code reaches:
`AdjacencyList`'s with a vertex type that counts comparisons (a fallback to a default scan makes
hundreds), and the matrix's `outDegree` and CSR's `contains(edge:)` by benchmark.

Deferred: index-based adjacency (`successors` as vertex indices), so an algorithm on an
`AdjacencyList` need not hash each neighbor to find its index; it lands with `Traversal`, which is
its first user. A `DirectedMultigraph` refinement (`edges(from:to:)`, multiplicity) waits for an
algorithm that needs it.

## Undirected catalog (UG)

The undirected cases are numbered as in the `Graph` protocol design catalog (`Tests/Catalogs/GraphProtocols/graph.md`), which drew on Boost's
`undirectedS` adjacency list and `undirected_dfs`, LEMON's `Graph` concept, igraph's loop
conventions, petgraph, JGraphT and NetworkX. Expected values for the algorithms and views were
computed with NetworkX 3.7 (`Graph`, `MultiGraph`, `to_directed`, `to_undirected`). NetworkX lists a
self-loop's vertex once among its neighbors; those lists are adjusted by one more copy per loop.

| IDs | Covers | Where |
|---|---|---|
| UG-L01 – L23 | The laws: counts, membership, neighbors as the far ends of edge ends, degree, handshake, symmetry, loops twice, incident positions each listed twice, `oppositeVertex` across and back, vertex indices, stability | `GraphLawTests.swift`; L16, L17 again after mutations in `UndirectedAdjacencyListMutationTests.swift`; L17, L19, L21 also in `GraphConformanceTests.swift` |
| UG-P01 | Seeded random graphs, loops and repeats included, observed identically through the adjacency list and the pseudograph | `GraphLawTests.swift` |
| UG-E01 – E11 | `UndirectedEdge` | `UndirectedEdgeTests.swift` |
| UG-R01 – R20 | `UndirectedAdjacencyList` on the fixtures, mutation, preconditions, equality, value semantics, description, `Codable`, literals | `Tests/UndirectedAdjacencyListTests` |
| UG-T01 – T05, T08, T09 | Associated types, `some` and `any`, `Sendable`, no dual conformance, the builder, conditional `Comparable` | `GraphConformanceTests.swift` |
| UG-T06, T07 | Defaults through minimal conformers; dispatch to a conformer's own members | `GraphDefaultTests.swift` |
| UG-A01 – A09 | Generic algorithms | `GraphAlgorithmTests.swift` |
| UG-C01 – C11 | Views and conversions | `GraphViewTests.swift` |
| UG-L24 | Dense edge indices: `edgeIndexBound == edgeCount`, `edgeIndex(of:)` one-to-one, `incidentEdgeIndices` is `incidentEdges` mapped (added after the review: bridges and Euler tours need edge state in arrays) | `GraphReviewTests.swift` |
| UG-L25 | With edge indices, `edges` is in index order (added for SpanningTrees: edges gathered from the index-space rows can follow the position tie rule) | `GraphReviewTests.swift` |

Not tested, because a test cannot observe them: that a type conforming to both `Graph` and
`DirectedGraph` fails to compile (UG-T05's last clause; verified when the protocol was designed), and the benchmarks
UG-B01 – B04 (costs of the directed view, O(1) `degree` and `contains(edge:)`, vertex removal,
copying), which belong in the benchmarks.
