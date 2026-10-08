# GraphProtocols test suite

`DirectedGraph` and `BidirectionalDirectedGraph` are the protocols every directed representation
conforms to, and that algorithms are written against. These tests check the protocols themselves:
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

The laws are written in the protocols' documentation and tested in each representation's suite.

| Type | `DirectedGraph` | Bidirectional | Edge positions | Vertex indices | From any graph |
|---|---|---|---|---|---|
| `AdjacencyList` | yes | yes | (source slot, offset); valid until mutated | the slots; `vertexIndex(of:)` is a hash lookup | `AdjacencyList(_:)`: keeps isolated vertices, collapses parallel edges |
| `AdjacencyMatrix` | yes | yes | the cell | the vertices themselves | `AdjacencyMatrix(_:)`: the vertices must be exactly `0..<vertexCount` |
| `CompressedSparseRow` | yes | no: no in-adjacency | the edge index `0..<m` | the vertices themselves | `CompressedSparseRow(_:)`: as for the matrix |
| `EdgeList` | **no** | — | — | — | `EdgeList(_:)` lists any graph's edges; a list becomes a graph through `AdjacencyList(edges:)` or `CompressedSparseRow(vertexCount:edges:)` |

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

## Files

| File | Covers |
|---|---|
| `Multigraph.swift` | A test conformer: a multigraph with indexed adjacency, for the parallel-edge rules |
| `DirectedGraphDefaultTests.swift` | The defaults through minimal test conformers (single-pass and collection neighborhoods), and that generic code, a second generic layer and existentials call a conformer's own members |
| `DirectedGraphLawTests.swift` | The laws on the multigraph, seeded random graphs observed identically through every representation, and Tarjan's components in reverse topological order |
| `DirectedGraphConformanceTests.swift` | Associated types read through generic code, which types conform, `some` and `any` use, `Sendable`, parallel edges told apart by position, Dijkstra on edge positions, vertex indices through generic layers, conversions and round trips |
| `DirectedGraphAlgorithmTests.swift` | Breadth-first distances and order, depth-first preorder, Kahn's topological generations (including on a multigraph), Tarjan's and Kosaraju's strongly connected components, reverse reachability, and the same through existentials, on every representation |

Case IDs (DG-L01, DG-A09, …) refer to the protocol design catalog, which drew on Boost's graph
concepts, petgraph's `visit` traits, JGraphT's `Graph`, LEMON's concepts and NetworkX.

Each representation's suite also checks that its own members are what generic code reaches:
`AdjacencyList`'s with a vertex type that counts comparisons (a fallback to a default scan makes
hundreds), and the matrix's `outDegree` and CSR's `contains(edge:)` by benchmark.

Deferred: index-based adjacency (`successors` as vertex indices), so an algorithm on an
`AdjacencyList` need not hash each neighbor to find its index; it lands with `Traversal`, which is
its first user. A `DirectedMultigraph` refinement (`edges(from:to:)`, multiplicity) waits for an
algorithm that needs it.
