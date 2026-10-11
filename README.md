# Grafluent

A generic, high-performance graph library for Swift.

This document is the design scaffold. It names every type the library intends to provide, says what each one is, and says which Swift protocols it should (and should not) conform to. `AdjacencyList`, `AdjacencyMatrix`, `CompressedSparseRow` and `EdgeList` are implemented; everything else is planned.

## Principles

1. **Established names only, familiar ones first.** Every name is the term programmers already know from the major graph libraries (Boost, NetworkX, petgraph, JGraphT), or the algorithm's author (Dijkstra, Tarjan, Hopcroft–Karp). The mathematical term is used only when there is no common one or the common one is ambiguous. Nothing is invented (see [Terminology](#terminology)).
2. **Value semantics, no mutable twins.** Each representation is one copy-on-write value type. `let` is immutable, `var` is mutable, and mutation is a set of `mutating` methods. Representations whose layout makes mutation expensive (compressed sparse row) offer initializers only. Mutation stays off the read protocols; the one mutable protocol, `MutableDirectedGraph`, exists so that a rule-adding wrapper such as `DirectedAcyclicGraph` can own any mutable directed representation.
3. **As fast as the standard library.** Storage follows the patterns used by `Array` and swift-collections: one allocation per value, the uniqueness check inlined with the reallocation path out of line, `_modify` accessors, and algorithms written against unsafe handles inside `withUnsafe…` scopes. Public types are `@frozen` and algorithms are `@inlinable`, so generic code specializes fully in the caller.
4. **Invariants live in types.** A `DirectedAcyclicGraph` cannot contain a cycle, and a `Tree` has exactly one `parent(of:)`. Algorithms that need a property say so in their signature instead of checking at run time.
5. **Minimum toolchain: Swift 6.2** (proposed). This gives us `Span`, `InlineArray`, noncopyable types, and typed throws.
6. **Trapping by default, `safe:` on request** (implemented on `StableDirectedGraph`, `LabeledGraph`, `DirectedAcyclicGraph` and Traversal's `descendants` / `ancestors`; planned repo-wide). A query on a missing vertex or edge is a precondition failure, like an `Array` subscript. Where callers hold IDs that may not belong to the graph, each such query gets a variant spelled with a `safe:` label that returns `nil` instead, after the common `array[safe: i]` idiom: `graph.successors(safe: v)`, `graph.outDegree(safe: v)`. The label marks the extra membership check, so the trapping spelling stays the fast path and the non-trapping one is always deliberate.

## Package layout

The package is split into focused modules the way swift-collections is (`DequeModule`,
`HeapModule`, `OrderedCollections`): each module holds one family of types and has its own test
target, and `import Grafluent` imports them all. A module takes a `Module` suffix only when it
would otherwise share a name with its main type (`AdjacencyListModule` holds `AdjacencyList`).

The module graph is written once, in `scripts/modules.py`. `Package.swift` and every
`BUILD.bazel` are generated from it (`just modules`), so SwiftPM and Bazel cannot drift.

| Group | Modules |
|---|---|
| Vocabulary | `GraphProtocols` (protocols, `DirectedEdge`, `UndirectedEdge`, builders), `Walks`, `Semirings` |
| Data structures | `PriorityQueueModule`, `DisjointSetModule` (bit sets come from swift-collections' `BitCollections`) |
| Representations | `AdjacencyListModule`, `AdjacencyMatrixModule`, `IncidenceMatrixModule`, `CompressedSparseRowModule`, `EdgeListModule`, `ImplicitGraphs`, `LabeledGraphs` |
| Structures | `DirectedAcyclicGraphModule`, `Trees`, `BipartiteGraphs`, `Multigraphs`, `StableGraphs`, `Hypergraphs`, `FunctionalGraphs` |
| Operations | `GraphOperations`, `GraphProducts` |
| Algorithms | `Traversal`, `ShortestPaths`, `SpanningTrees`, `Connectivity`, `Cycles`, `Tours`, `Flows`, `MatchingModule`, `ColoringModule`, `Cliques`, `Covering`, `Centrality`, `CommunityDetection`, `IsomorphismModule`, `Planarity`, `TreeAlgorithms`, `Distances`, `SpectralGraphTheory` |
| Generators | `NamedGraphs`, `RandomGraphs` |
| Drawing and formats | `GraphDrawing`, `GraphFormats` |

```
Sources/<Module>/            One directory per module, each with a generated BUILD.bazel
Tests/GrafluentTestSupport/  Shared test data: fixtures, stress vertex types, lifetime tracking
Tests/<Module>Tests/         One test target per module, added when its first suite is written
Tests/Catalogs/<Module>/     Each suite's case catalog, reference model and test generator (not built)
scripts/modules.py           The module graph
tools/swift_rules.bzl        First-party rule wrappers: warnings as errors, Swift 6 mode
```

## Building

Bazel is the build system; SwiftPM is the published package. Both build the same graph.

| Command | Does |
|---|---|
| `just build` | `bazel build //...` |
| `just test` | `bazel test //...` |
| `just test-one //Tests/AdjacencyListTests` | One test target |
| `just filter <pattern>` | Tests matching a name |
| `just test-release` | Every test under `-O` |
| `just spm-test` | The tests via SwiftPM |
| `just verify` | Both build systems; run before pushing |
| `just generate` | An Xcode project from the Bazel graph (rules_xcodeproj) |
| `just modules` | Regenerate `Package.swift` and every `BUILD.bazel` |

`just test` is always green. Suites are written test-first: while a suite is being written it is
checked against a throwaway naive implementation outside the repository, and it lands together
with the real implementation that passes it.

## Terminology

Graph theory and graph libraries diverged in vocabulary. Grafluent uses the terms the major
libraries share, and notes the mathematical term for readers coming from the literature.

| Concept | Name in Grafluent | Used by | Mathematical term |
|---|---|---|---|
| Directed edge | `DirectedEdge`, with `source` and `target` | Boost, petgraph, JGraphT | arc, with tail and head |
| Undirected edge | `UndirectedEdge`, with two endpoints | all | edge |
| Edge from a vertex to itself | self-loop, `isSelfLoop` | NetworkX, Boost, JGraphT | loop |
| Vertices one edge out of v | `successors(of:)` | NetworkX, JGraphT | out-neighbors, N⁺(v) |
| Vertices one edge into v | `predecessors(of:)` | NetworkX, JGraphT | in-neighbors, N⁻(v) |
| Neighbors in an undirected graph | `neighbors(of:)` | all | N(v) |
| Degrees | `outDegree(of:)`, `inDegree(of:)`, `degree(of:)` | all | d⁺(v), d⁻(v), d(v) |
| Number of vertices / edges | `vertexCount`, `edgeCount` | petgraph, Boost | order \|V\|, size \|E\| |
| Vertex set / edge set | `vertices`, `edges` | all | V, E (A for arcs) |
| Every edge reversed | `reversed` | NetworkX, Boost, JGraphT | converse |
| Every edge reversed, materialized (index-based representations) | `transposed()` | scipy, Boost (`transpose_graph`), matrix algebra | transpose |
| Edge directions dropped | `undirected` | NetworkX, JGraphT | underlying graph |
| Rooted-tree relations | `parent(of:)`, `children(of:)`, `root`, `depth(of:)` (edges to the root), `height` (the greatest depth) | all; CLRS and Knuth for depth and height (Swing has them the other way round) | same |
| Tree with every edge directed away from the root | `Arborescence` | NetworkX, LEMON, Edmonds (igraph: out-tree) | out-tree, directed rooted tree |
| Reachability | `descendants(of:)`, `ancestors(of:)`; `descendants(safe:)`, `ancestors(safe:)` return `nil` for a vertex not in the graph (Principle 6) | NetworkX | same |
| Edge values | weight function | all | w : E → S |
| Edge whose removal adds a component | bridge, `bridges()` | NetworkX, JGraphT, igraph, petgraph | cut edge, isthmus |
| Vertex whose removal adds a component | articulation point, `articulationPoints()` | NetworkX, Boost, igraph, petgraph | cut vertex |
| Maximal biconnected subgraph | biconnected component, `biconnectedComponents()` | NetworkX, Boost, igraph | block |
| Maximal set joined by two edge-disjoint paths | bi-edge-connected component, `biEdgeConnectedComponents()` | LEMON (NetworkX: bridge component) | 2-edge-connected component |
| Closed walk with no repeated vertex | simple cycle, `simpleCycles()` | NetworkX, igraph, JGraphT, rustworkx | cycle; elementary circuit (Johnson, Boost) |
| Length of a shortest cycle | `girth()` | NetworkX, igraph, JGraphT, Boost | girth |
| Graph with no cycle | `isAcyclic` | igraph, LEMON (NetworkX, JGraphT: `is_forest`) | forest (undirected), DAG (directed) |
| Clique no other clique contains / of greatest size | maximal clique, `maximalCliques()` / maximum clique, `maximumClique()`; its size the clique number | NetworkX, igraph, JGraphT | same; ω(G) |
| Largest k with v in a subgraph of minimum degree k | core number, `coreNumbers()` | NetworkX, igraph (coreness), JGraphT (Coreness) | same; the greatest is the degeneracy |
| 3 × triangles / connected triples | `transitivity()` | NetworkX, igraph | global clustering coefficient |
| Share of shortest paths through a vertex | betweenness, `betweennessCentrality()` | NetworkX, igraph, JGraphT, Boost (Brandes) | Freeman's betweenness |
| Stationary distribution of a damped random walk | `pageRank(dampingFactor:)` | Boost, igraph, JGraphT (damping factor); NetworkX (`alpha`) | Brin–Page |
| Kleinberg's mutually reinforcing scores | hubs and authorities, `hits()` | NetworkX, igraph (hub and authority scores) | HITS |
| Fraction of edges inside communities minus its expected value | modularity, `modularity(of:resolution:)` | NetworkX, igraph, JGraphT | Q; γ is the resolution (Reichardt–Bornholdt) |
| The two vertex classes of a bipartite graph | left and right, `left`, `right`, `side(of:)` | CLRS (V = L ∪ R) | top and bottom (NetworkX), red and blue (LEMON), types (igraph) |
| A cycle of odd length, the witness that a graph is not bipartite | odd cycle, `findOddCycle()` | Boost (`find_odd_cycle`) | |
| Edges no two of which share an endpoint | matching, `Matching`; maximal (no edge can be added) / maximum (most edges) / perfect (covers every vertex) | NetworkX, Boost, LEMON, JGraphT | independent edge set |
| Cheapest one-to-one pairing of rows and columns | assignment problem, `linearSumAssignment` | scipy | Hungarian method (Kuhn–Munkres) |
| Pairing with no pair that prefers each other to their partners | stable matching, `stableMatching` | Gale–Shapley, Gusfield–Irving | stable marriage |
| Vertices touching every edge / no two adjacent / with every vertex in or next to one | vertex cover, independent set, dominating set; `minimumVertexCover()`, `maximumIndependentSet()`, `minimumDominatingSet()` | NetworkX, igraph, JGraphT | τ, α (independence number), γ |
| Colours on the vertices with the two ends of every edge different / fewest colours possible | vertex colouring, `Coloring`, `isVertexColoring`; chromatic number, `chromaticNumber()`, `minimumColoring()`, `lexicographicallyFirstMinimumColoring()` | NetworkX, igraph, JGraphT, Boost, rustworkx | proper colouring; χ(G) |
| Colours on the edges with every two edges sharing an end different | edge colouring, `EdgeColoring`, `edgeColoring()`, `isEdgeColoring` | igraph, rustworkx, Boost, Sage | proper edge colouring; the fewest colours is the chromatic index χ′(G) |
| Graph allowing parallel edges / and self-loops | multigraph, `Multigraph` / pseudograph, `Pseudograph` (directed: `DirectedMultigraph`, `DirectedPseudograph`) | JGraphT, Harary | NetworkX, Boost, igraph: "multigraph" for both |
| Number of edges joining two vertices | multiplicity, `edgeCount(between:and:)` | NetworkX (`number_of_edges(u, v)`) | |
| Cycles that generate every cycle (mod 2) | cycle basis, `cycleBasis()` | NetworkX, JGraphT, rustworkx (igraph: fundamental cycles) | basis of the cycle space |
| Edge values a flow may not exceed | capacity, `capacity:` | all libraries | c : E → ℝ≥0 |
| Assignment of flow to edges within capacities, conserved at every vertex but the source and sink | flow, `Flow`; its value the net flow out of the source | NetworkX, igraph, JGraphT | s–t flow |
| A split of the vertices with the edges from one side to the other | cut, `Cut`, with a source side and a sink side | OR-Tools, JGraphT | s–t cut (S, T); the cut-set |
| Net amount a vertex sends | supply, `supply:` (positive sends; negative is a demand) | LEMON, OR-Tools, JGraphT (NetworkX: demand, the opposite sign) | b(v), node balance |

`size` is avoided because programmers read it as memory size. `successors` and `predecessors`
always mean vertices one edge away; in order theory they can mean any reachable vertex, but no
graph library uses them that way.

## Protocols (`GraphProtocols`)

A graph is a pair (V, E). We don't think a graph should itself be a `Sequence`: should iterating it yield vertices or edges? Neither answer is obviously right. A graph instead *exposes* collections, the same way `Dictionary` exposes `keys` and `values`.

| Protocol | Requirements (sketch) | Notes |
|---|---|---|
| `DirectedGraph` | `associatedtype Vertex`, `vertices`, `edges`, `successors(of:)`, `outEdges(of:)`; with defaults `source(ofEdgeAt:)`, `target(ofEdgeAt:)`, `vertexCount`, `edgeCount`, `contains(_:)`, `contains(edge:)`, `outDegree(of:)`, and dense vertex indices (`vertexIndexBound`, `vertexIndex(of:)`, `vertex(atIndex:)`), which number `vertices` in order (**implemented**) | The base protocol. Members with defaults are requirements, so a representation's faster version is what generic code calls. Parallel edges are allowed: neighborhoods list a vertex once per edge and counts include repeats. See `Tests/GraphProtocolsTests/README.md`. Traversal, shortest paths, and most of the library need only this. `contains(edge:)` (the adjacency test) defaults to a scan of N⁺(u); matrices answer in O(1) and sorted compressed sparse row in O(log d). |
| `Graph` | `associatedtype Vertex`, `vertices`, `edges`, `neighbors(of:)`, `incidentEdges(of:)`; with defaults `oppositeVertex(to:acrossEdgeAt:)`, `vertexCount`, `edgeCount`, `contains(_:)`, `contains(edge:)`, `degree(of:)`, dense vertex indices with `neighborIndices(ofIndex:)`, and dense edge indices (`edgeIndexBound`, `edgeIndex(of:)`, `incidentEdgeIndices(ofIndex:)`, Boost's `edge_index`) for algorithms that mark edges (**implemented**) | An undirected graph. **Decided:** `Graph` and `DirectedGraph` are separate protocols; an undirected graph is not modeled as a symmetric directed graph, and no type conforms to both. Each edge is listed once in `edges`, and its position is its identity from both ends. A self-loop is listed twice in `neighbors(of:)` and `incidentEdges(of:)` and counts 2 in `degree(of:)` (Boost's `adjacency_list`, LEMON, igraph), so degree is always the neighborhood's length and degrees sum to twice `edgeCount`. `graph.directed` reads it as a `BidirectionalDirectedGraph` (each edge two arcs), and `digraph.undirected` reads a bidirectional directed graph as undirected (each arc an edge), so Traversal runs on undirected graphs. `UndirectedAdjacencyList` conforms. See `Tests/GraphProtocolsTests/README.md`. |
| `BidirectionalDirectedGraph` | `predecessors(of:)`, `inEdges(of:)`; with defaults `inDegree(of:)`, `degree(of:)`, `predecessorIndices(ofIndex:)`, `inEdges(ofIndex:)` (**implemented**) | Needed for reversed traversal, dominators, and Kosaraju. The name is Boost's `BidirectionalGraph` concept, with "Directed" since `Graph` here means undirected. Adjacency list and matrix conform; compressed sparse row does not, and `EdgeList` is not a `DirectedGraph` at all (its adjacency queries scan every edge). |
| `SparselyIndexedDirectedGraph` | Refines `BidirectionalDirectedGraph` with `Edges.Index == Int`: `vertexPositionBound`, `edgePositionBound`, `vertexPosition(of:)`, `vertex(atPosition:)`, `containsVertex(atPosition:)`, `containsEdge(atPosition:)` (O(1) liveness), and `_numberedRows(outward:edges:)`, with a default built from those for a conformer outside the library (**implemented**) | Positions in `0..<bound` with holes: petgraph's `NodeIndexable` / `EdgeIndexable`, where the dense `vertexIndexBound` is its `NodeCompactIndexable`. Lets index-space helpers number the live vertices with arrays while a `StableDirectedGraph` has holes, instead of hashing, through a paged position map, so nothing is sized by the bounds (upper bounds only); the dense laws are untouched. |
| `MutableDirectedGraph` | Refines `BidirectionalDirectedGraph` with `Vertices.Index == Int`: `init()`, `insert(_:)`, `remove(edge:)`, `removeAll(keepingCapacity:)`, `removeAllEdges(keepingCapacity:)`, `reserveCapacity(vertexCount:edgeCount:)`, and underscored hooks on vertex keys (a vertex's index in `vertices`: its slot, or its stable position): `_key(of:)`, `_vertex(atKey:)`, the rows and degrees by key, `_insertVertex`, `_insertEdge(fromKey:toKey:)`, `_removeVertex(atKey:)` (reporting a swap-remove's move), `_removeEdge(at:)` (**implemented**; `AdjacencyList`, `DirectedPseudograph`, `StableDirectedGraph`) | Boost's `MutableGraph` concept (`add_vertex`, `add_edge`, `remove_edge`, `remove_vertex`), directed. For wrappers that own a base and add a rule: one hash per vertex, then key-space work with no hashing. Callers mutate through the representations' own members. |
| `Hypergraph` | `hyperedges`, `incidentHyperedges(of:)` | Separate from `DirectedGraph`, because a hyperedge is not an edge. |

The protocols do not refine `Sendable`; every representation is `Sendable` when its vertex type is, and algorithms that cross isolation ask for `DirectedGraph & Sendable`. Mutation belongs to concrete types; `MutableDirectedGraph` gives wrappers only the hooks they need to mutate a base generically. The base protocol requires `vertices` and `edges`, so it describes finite graphs; infinite state spaces (`ImplicitDirectedGraph`) will be traversed through closure-based entry points in `Traversal`.

### Associated collections

| Member | Minimum requirement | What representations should return |
|---|---|---|
| `vertices` | `Collection` | `Range<Int>` for index graphs, a `RandomAccessCollection` for labeled graphs |
| `edges` / `edges` | `Collection` | `RandomAccessCollection` for compressed sparse row and edge lists, a forward `Collection` over set bits for matrices |
| `successors(of:)` | `Sequence` | A slice or view of contiguous storage, a set-bit `Collection` for matrices, a plain `Sequence` for implicit graphs. (`Span` cannot be the protocol's type: it is not a `Sequence` and cannot escape; representations offer it, or unsafe buffers, as their own API.) |

The neighbor requirement is only `Sequence` so that implicit graphs, whose neighbors are computed on demand, can conform. Algorithms that need more (a count, or several passes) put that constraint in their own signature.

### Elements (`GraphProtocols`)

| Type | What it is | Swift conformances |
|---|---|---|
| `DirectedEdge<Vertex>` | Ordered pair (source, target) | `Hashable`, `Sendable`, `Codable` when `Vertex` is; `BitwiseCopyable` when `Vertex` is; `CustomStringConvertible` as `u → v` |
| `UndirectedEdge<Vertex>` | Unordered pair {u, v} (**implemented**) | Same as `DirectedEdge`, but `==` and `hash(into:)` are symmetric, so {u, v} = {v, u}: the hash combines the smaller endpoint hash, then the larger, so no `Comparable` is needed. `Comparable` when `Vertex` is, by (min, max). The stored order of `u` and `v` is not part of the value; `oppositeVertex(to:)` gives the far end. `CustomStringConvertible` as `u–v` |
| `Hyperedge<Vertex>` | A nonempty set of vertices | `Hashable`, `Sendable`, `Codable`; possibly `SetAlgebra`, since it really is a set |

### Walks (`Walks`)

| Type | What it is | Swift conformances |
|---|---|---|
| `Walk<Vertex, Edge>` | A sequence of vertices with the edge positions between them, each edge joining a vertex to the next; repeats allowed (**implemented**) | `RandomAccessCollection` of vertices, with `edges` (positions), `length`, `source`, `target`; `Hashable`, `Codable` (decoding re-checks the rules), `Sendable`. `Edge` is the graph's `Edges.Index`: positions tell parallel edges apart, which vertices alone cannot (JGraphT's `GraphPath<V, E>`). Over an undirected graph the vertex order orients each edge |
| `Trail<Vertex, Edge>` | A walk with no repeated edge | Same as `Walk` |
| `Path<Vertex, Edge>` | A walk with no repeated vertex (and so no repeated edge) | Same as `Walk`. Returned by `ShortestPathTree.path(to:)`, the single-target searches and `bidirectionalShortestPath`. In a file that also imports SwiftUI, write `Walks.Path` or `SwiftUI.Path` |
| `Circuit<Vertex, Edge>` | A closed trail, at least one edge, listed without repeating its start | `RandomAccessCollection`. `==` holds up to rotation (not reversal), and `hash(into:)` is rotation-invariant: a wrapping sum of per-step hashes, so no `Comparable` is needed |
| `Cycle<Vertex, Edge>` | A closed path (a self-loop, or two parallel edges, count) | Same as `Circuit`. Returned as the *witness* whenever cycle detection succeeds: `findCycle()`, `findNegativeCycle` |

These are the one place where `Collection` conformance is clearly right: a walk *is* a sequence.

### Weights (`Semirings`)

| Type | What it is | Swift conformances |
|---|---|---|
| Weight function | A map w : E → S. Weights are kept separate from the representation and are passed to algorithms as a closure over edge positions (`(G.Edges.Index) -> S`), so parallel edges can weigh differently. For compressed sparse row and edge lists the position is a dense `Int`, so the closure is often an array lookup. | n/a |
| `Semiring` (protocol) | (S, ⊕, ⊗, 0̄, 1̄). Shortest-path algorithms are generic over it. | Swift's numeric protocols don't fit: `AdditiveArithmetic` has one operation and `Numeric` assumes ring arithmetic. The protocol needs its own `⊕`, `⊗`, `zero`, `one`. |
| `TropicalSemiring` | (min, +) → shortest paths | `Sendable`, `Hashable`, `Comparable` |
| `BottleneckSemiring` | (max, min) → widest paths | Same |
| `BooleanSemiring` | (∨, ∧) → reachability, transitive closure | Same |
| `CountingSemiring` | (+, ×) → number of walks | Same |

Dijkstra itself only needs `Comparable & AdditiveArithmetic` weights that are never negative. The semiring generalization is for algebraic path problems such as Floyd–Warshall and DAG paths.

### Construction (`GraphProtocols`)

| Entry point | Shape |
|---|---|
| `@DirectedGraphBuilder` / `@GraphBuilder` | Result builders that support `for`, `if`, and `switch`: `AdjacencyList { DirectedEdge(from: "a", to: "b"); for i in 0..<n { DirectedEdge(from: i, to: i + 1) } }` |
| Literals | `ExpressibleByDictionaryLiteral` (adjacency `["a": ["b", "c"]]`) and `ExpressibleByArrayLiteral` (edge lists, matrix rows) |
| Sequence initializers | `init(edges:)`, `init(vertices:edges:)`, `init(adjacency:)` |
| Bulk initializers | `init(vertexCount:edgeCount:initializingWith:)`, modeled on `Array(unsafeUninitializedCapacity:initializingWith:)`, so compressed sparse row can be built with no intermediate allocation |
| Conversion | `AdjacencyMatrix(g)` and `CompressedSparseRow(g)`, the same way `Array(seq)` converts |
| Incremental | `insert(_:)` / `remove(_:)` for vertices and `insert(edge:)` / `remove(edge:)` for edges, plus `reserveCapacity`, on representations that support mutation. Edge operations are labeled so they can never be confused with vertex operations. |
| Incremental, endpoints required (implemented on `StableDirectedGraph`, `DirectedAcyclicGraph` and `LabeledGraph` over `AdjacencyMatrix`; planned for every mutable representation) | `insert(edge:)` inserts a missing endpoint (NetworkX's `add_edge`). `insert(safe:)` adds the edge only when both endpoints are already vertices, and otherwise returns `nil` and changes nothing. Requiring the endpoints is JGraphT's `addEdge` precondition (it throws `IllegalArgumentException`) and petgraph's `try_add_edge` (`GraphError::NodeMissed`); no library has an optional-returning spelling, so this one takes the `safe:` label of Principle 6. For callers whose IDs may come from another graph. |

**Open question:** whether to add edge operators such as `"a" --> "b"`. They read well, but they cost compile time and make type inference harder.

## Representations

Every representation is a copy-on-write value type, and every one conforms to `Sendable` (when its vertex type is), `Equatable`, `Hashable`, `CustomStringConvertible`, and `CustomDebugStringConvertible`. `Codable` is conditional on the vertex type.

**For the graph representations, equality means equal vertex sets and equal edge sets.** It is *not* isomorphism, which is a separate algorithm, and it must not depend on the order edges were inserted. Representations that keep each neighbor list sorted get O(|V| + |A|) equality; the rest have to normalize first. **`EdgeList` is the exception:** it is a `MutableCollection` whose positions are observable, so, like `Array`, two lists are equal only when their edges are equal in order. Order-free comparisons go through `Set`, sorting, or `AdjacencyList`.

| Type | What it is | Mutation | Notes and conformances |
|---|---|---|---|
| `AdjacencyList<Vertex>` | Each vertex maps to its out- and in-neighbors (**implemented**) | Yes | Dense slots with a vertex → slot dictionary, an out-row and an in-row of slots per vertex, and a slot-pair → list-positions dictionary: O(1) `contains(edge:)`, O(1) edge removal, O(degree) vertex removal. The rows of each direction share one pool: a full row grows in place or moves to the end at double capacity, and abandoned blocks are packed away once they exceed half the pool, so building 100k edges over 10k vertices takes about 100 allocations and copying a graph copies a constant number of buffers. `ExpressibleByDictionaryLiteral`. See `Tests/AdjacencyListTests/README.md`. |
| `AdjacencyMatrix` | A directed graph on vertices `0..<n` as an n×n bit matrix (**implemented**) | Edges, rows and columns; vertices by `appendVertex()`, never removed | `successors(of:)` / `predecessors(of:)` are swift-collections `BitSet`s; O(1) degrees; transpose, union, intersection, subtraction, complement; row-major `edges` whose positions are cells. See `Tests/AdjacencyMatrixTests/README.md`. Weights stay external: for a matrix, as a closure `(source, target) -> W` or an n×n side matrix, never an edge-indexed array (cell positions span n², not the edge count). |
| `IncidenceMatrix` | \|V\|×\|E\| matrix | Yes | Mostly for hypergraphs and spectral methods |
| `CompressedSparseRow` | Offsets array (n+1) plus targets array (m); rows canonical (**implemented**) | **No**, initializers only | `successors(of:)` is an `ArraySlice` whose indices are edge indices; binary-search `contains(edge:)`; stable edge indices `0..<m` for weight arrays, with the initializer and `transposed(forwardEdgeIndices:)` reporting where each edge went so weights can follow; O(n + m) construction for any degree distribution; `inDegrees` in one pass; `withUnsafeBufferPointers` for kernels. See `Tests/CompressedSparseRowTests/README.md`. |
| `CompressedSparseColumn` | Not a separate type: `CompressedSparseRow.transposed()` is the column form | — | Revisit with the `BidirectionalDirectedGraph` design |
| `EdgeList<Vertex>` | A directed pseudograph as an ordered list of edges (**implemented**) | Yes, as an `Array` | `RandomAccessCollection`, `MutableCollection` and `RangeReplaceableCollection` of `DirectedEdge` with `Int` positions, which are the edge identities (weights live in an array indexed the same way). Parallel edges kept; order preserved and part of `==`; vertices are the endpoints, so no isolated vertices; graph queries are O(m) scans; `transposed()` flips edges, `reversed()` stays the stdlib's. Kruskal's input format. See `Tests/EdgeListTests/README.md`. |
| `LabeledGraph<Label, Base>` (module `LabeledGraphs`) | `Hashable` vertex labels over an index-based representation whose vertices are `0..<n` (BGL's `labeled_graph` adaptor) (**implemented**) | Over `CompressedSparseRow`: none (rebuild through `init(_:)`; `transposed()` reverses every edge under the same labels in O(n + m)). Over `AdjacencyMatrix`: vertices appended (`insert(_:)`), edges inserted (`insert(edge:)` adds missing endpoints, source first; `insert(safe:)` does not) and removed (`remove(edge:)`, and `removeEdges(from:)`, `removeEdges(to:)`, `removeEdges(incidentTo:)` by label) | An `OrderedSet<Label>` whose element `i` names base vertex `i` (swift-collections: a dense array plus a bit-packed hash table), beside the base. `DirectedGraph` with `Vertex == Label`, and `BidirectionalDirectedGraph` over a bidirectional base. Label-space members hash once and then read the base by index; every index-space member, `SuccessorIndices` and `PredecessorIndices` included, is the base's own, so index-space algorithms hash only their inputs (benchmarked with a hash-counting label: no hash per edge; `breadthFirstLayers`, components and Dijkstra within 1.05× the bare base, while the lazy `breadthFirstSearch` sequence costs 1.7–1.8× because each of its events carries two labels). Positions are the base's (`Int` edge indices on CSR, cells on the matrix), so data kept by position stays valid. Indices follow NetworkX's `convert_node_labels_to_integers(ordering="default")`: listed vertices first, then new endpoints by first appearance. `init(_:labels:)` labels any `DirectedGraph<Int>` whose vertices are `0..<n` in index order (trapping otherwise); `vertexIndex(of:)` / `vertex(atIndex:)` convert, `vertexIndex(safe:)` and the `safe:` row lookups return `nil`; `base` is read-only. Equality ignores the index assignment, and so does `Hashable` (each label hashed once, no label per edge); `Codable` as `{labels, base}`, re-checked on decoding; built with `@DirectedGraphBuilder` like the other representations. Undirected use is `labeled.undirected`. A future base that removes vertices by swap-remove moves the last label into the hole, as LEMON's `RangeIdMap` does. See `Tests/Catalogs/LabeledGraphs/api.md`. |
| `ImplicitDirectedGraph<Vertex>` | A finite vertex collection whose out-neighbors are computed by a closure; never stored | No | Conforms to `DirectedGraph`, with `Sequence` neighbors. Used for grids and bounded state spaces. **Infinite** state spaces (A* over an unbounded search) are not graphs in the protocol's sense, since it requires `vertices` and `edges`; `Traversal` and `ShortestPaths` give them closure-based entry points (`from:successors:`), as Rust's `pathfinding` crate does. |

## Structures

These are graph classes whose defining property is an invariant enforced by the type.

| Type | Invariant | Cycle handling | Notes and conformances |
|---|---|---|---|
| `DirectedAcyclicGraph<Base>` | No directed cycle (**implemented**) | **Inserting an edge that would close a cycle is rejected**: `insert(edge:)` and `insert(safe:)` return `nil` and change nothing (a self-loop included; `insert(safe:)` also when an endpoint is missing). The witness is Traversal's `bidirectionalShortestPath(from: edge.target, to: edge.source)`, searched only when asked for. The order is maintained by Pearce and Kelly's dynamic topological sort (JEA 11, 2006): O(1) for an edge already going forward, otherwise two searches bounded by the endpoints' places, O(‖δ‖ + δ log δ). A new source whose target is already a vertex is placed first, any other new endpoint last, so an edge with a new endpoint never reorders. Bulk construction (failable) orders by Kahn's algorithm. | A wrapper over any `MutableDirectedGraph` (`AdjacencyList`, `DirectedPseudograph`, `StableDirectedGraph`): every read and index-space member is the base's, with the base's types, so algorithms run at the base's speed and positions are the base's. `topologicalOrder` (a `RandomAccessCollection`), `topologicalPosition(of:)` / `(safe:)` (O(1) while no removal has left a hole, O(log n) by a Fenwick tree otherwise), the six row `safe:` lookups, order-pruned `hasPath(from:to:)`, `transitiveClosure()`, `transitiveReduction()`, `longestPath()` and `longestPath(weight:)` (NetworkX's `dag_longest_path`); ShortestPaths' `dagShortestPaths(from:weight:)` relaxes in the maintained order. Over `StableDirectedGraph`, the base's `EdgeMap` and `VertexMap` attach and work through the wrapper (Q9). Removals keep the order; a vertex removal leaves a hole in its slot, amortized O(1) plus O(log n) for the hole count, holes at the ends are trimmed and the slots compacted once holes outnumber vertices, and on a swap-remove base the moved vertex keeps its place. Equality is the base's. Codable as `{base, order}`, re-checked on decoding. No separate `isAcyclic` method, because acyclicity is guaranteed. |
| `Tree<Vertex>` | Connected and acyclic, undirected, at least one vertex (**implemented**) | Invariant: every initializer from unchecked input is failable (`Tree(graph)`, `Tree(vertices:edges:)`); the witnesses are `findCycle()` and `connectedComponents()`. `isTree` on any `Graph` | `Graph`, immutable, copy-on-write; vertices and edge positions as given; `path(from:to:) -> Path`; `pruferSequence` and `Tree(pruferSequence:)` |
| `RootedTree<Vertex>` | A tree with a distinguished root (**implemented**) | Invariant | `Graph`; `root`, `parent(of:)`, `parentEdge(of:)`, `children(of:)` (child edges in position order), `depth(of:)`, `height`, `preorder` (the storage layout), `postorder`, `descendants(of:)` (an O(1) slice of `preorder`), `ancestors(of:)`, `isAncestor(_:of:)` (strict, O(1)), `path(from:to:)`; built from a tree and a root, a graph, or a parent function (`init?(vertices:parent:)`, `init?(parents:)`) |
| `Forest<Vertex>` | Acyclic, undirected, possibly empty (**implemented**) | Invariant (`Forest(g) != nil` is Cycles' `isAcyclic`) | `Graph`; `trees`, a `RandomAccessCollection` of `Tree` by least vertex, each built when read; `component(of:)`; `path(from:to:) -> Path?` |
| `Arborescence<Vertex>` | A directed rooted tree, with every edge pointing away from the root (**implemented**) | Invariant. `isArborescence` on any `DirectedGraph` | `BidirectionalDirectedGraph`: successors are the children, predecessors the parent; the rooted queries of `RootedTree`, converting to and from one in O(1); `path(from:to:)` is nil unless it goes down. Shortest-path, dominator and search trees convert through the parent-function initializer |
| `BipartiteGraph<Vertex>` | V = L ⊔ R, and every edge crosses between L and R, so no self-loop; simple (**implemented**) | Invariant: initializers from unchecked input are failable (`BipartiteGraph(graph)`, `BipartiteGraph(graph, left:)`, `BipartiteGraph(left:right:edges:)`), and `insert(edge:)` traps on an edge inside a side; the witness is `findOddCycle()`. `isBipartite`, `bipartition()` and `findOddCycle()` on any `Graph` | `Graph`, mutable, copy-on-write (an `UndirectedAdjacencyList` plus sides); `left` and `right` as collections, `side(of:)`; each edge stored left endpoint first; `projectedGraph(onto:)` |
| `Pseudograph<Vertex>` / `DirectedPseudograph<Vertex>` | Parallel edges and self-loops allowed (**implemented**) | n/a | `Graph` / `BidirectionalDirectedGraph`, mutable, copy-on-write, `UndirectedAdjacencyList`'s and `AdjacencyList`'s storage keeping every copy: an edge is its position; `insert(edge:)` always adds a copy and returns its position; `edges(between:and:)` / `edges(from:to:)` (oldest first, `.last` the newest) and `edgeCount(between:and:)` in O(1); `remove(edge:)` removes the newest copy (NetworkX), `remove(edgeAt:)` one copy, `removeAllEdges(between:and:)` every copy; equality on the edge multiset |
| `Multigraph<Vertex>` / `DirectedMultigraph<Vertex>` | Parallel edges allowed, no self-loops (**implemented**) | Invariant: initializers from unchecked input are failable, a self-loop insertion traps | The pseudographs' API and storage (JGraphT's four names: NetworkX's `MultiGraph` is our `Pseudograph`) |
| `StableDirectedGraph<Vertex>` (module `StableGraphs`) | A directed pseudograph whose vertex and edge positions survive removals (petgraph's `StableDiGraph`) (**implemented**) | n/a | `BidirectionalDirectedGraph` and `SparselyIndexedDirectedGraph`, mutable, copy-on-write. Removal leaves a hole instead of moving the last element in, and positions are never reused (petgraph reuses them), so a position names one element for as long as it exists, `edges.indices.contains(p)` is an O(1) stale check, and a side array indexed by position stays valid; only `removeAll` and `removeAllEdges` reset an `endIndex`. Vertices, edges and each vertex's out- and in-edges iterate in insertion order, also across removals; rows are arrays in position order with lazy deletion (O(1) amortized removal, contiguous walks; doubly linked rows, as LEMON's `ListDigraph`, walked 3.6–5.4× slower). The dense index bounds are `nil` while holes exist (the `DirectedGraph` laws are unchanged); the `SparselyIndexedDirectedGraph` refinement (petgraph's `NodeIndexable`, against `NodeCompactIndexable`) reports the positions and their bounds, so index-space algorithms number live vertices with arrays instead of hashing. Equality ignores positions. For FlowNavigation: `removeAllEdges(from:where:)`, `removeAllEdges(where:)` (petgraph's `retain_edges`, inverted) and `removeAllEdges(from:to:)` remove in one pass over a row; `successors(safe:)`, `predecessors(safe:)`, `outEdges(safe:)`, `inEdges(safe:)`, `outDegree(safe:)`, `inDegree(safe:)` and `insert(safe:)` return `nil` for a vertex not in the graph (Principle 6). Storage is paged (1024 positions a page): a page whose positions are all dead is freed, so under churn memory follows the live elements, a copy shares every page and the first mutation copies only the pages it touches, and an algorithm run costs O(live + pages). Maps attached to the graph (`addEdgeMap(of:)`, `addVertexMap(of:)`, after LEMON's `ArcMap` / `NodeMap` and their `AlterationNotifier`) keep data by position, paged like the graph and read through `graph[map: handle, ofEdgeAt: p]`; every removal clears the removed element's values in the same mutation, and copies carry their maps. `changeTarget(ofEdgeAt:to:)` / `changeSource(ofEdgeAt:to:)` (LEMON's, with `safe:` spellings) re-point an edge without changing its position. `StableUndirectedGraph` is deferred. |
| `Hypergraph<Vertex>` | Edges are vertex subsets of any size | n/a | Conforms to `Hypergraph`, not `DirectedGraph` |
| `FunctionalGraph` | Every vertex has out-degree exactly 1 (the iteration of a function f : V → V) | **Floyd's and Brent's cycle detection**, with O(1) memory | Can be built straight from a closure, with no stored graph |

## Operations (`GraphOperations`, `GraphProducts`)

Unary operations return **lazy views** with no copying. Each view conforms to the same core protocols as its base, conditionally. Calling a representation's initializer on a view (`CompressedSparseRow(g.reversed)`) copies it into real storage.

| Operation | Result | Kind |
|---|---|---|
| `subgraph(vertices:edges:)`, `inducedSubgraph(on:)`, `spanningSubgraph(edges:)` | Subgraph views | Lazy view |
| `reversed` | Every edge reversed | Lazy view (O(1) when the base is a `BidirectionalDirectedGraph`). **Open:** on `EdgeList`, a collection, this name would collide with the standard library's `reversed()` (the edges in reverse order, each edge unchanged); `EdgeList` uses `transposed()` for the flip, and the view needs a name that cannot be confused with it |
| `undirected` | Edge directions dropped | Lazy view |
| `complement` | Edges exactly where the base has none | Lazy view |
| `lineGraph` | One vertex per edge of the base, adjacent when the edges share an endpoint | Materialized |
| `condensation` | One vertex per strongly connected component | Materialized, and always a `DirectedAcyclicGraph` |
| `quotient(by:)` | Vertices contracted by a partition | Materialized |
| `union`, `intersection`, `join`, disjoint union | Binary operations | Materialized |
| `cartesianProduct` (G □ H), `tensorProduct` (G × H), `strongProduct` (G ⊠ H), `lexicographicProduct` (G ∘ H) | Graph products | Lazy view (the product's vertex set is V(G) × V(H)) |

## Algorithms

Every algorithm is a generic function, or an extension constrained to the narrowest protocol it needs. Results are dedicated types, not tuples.

### What is a `Sequence`

- **Traversals** (**implemented**): `BreadthFirstSearch` and `DepthFirstSearch` are lazy `Sequence`s of events; see `Tests/TraversalTests/README.md`. Traversal is inherently one pass, and making it lazy gives early termination for free. DFS events use the CLRS edge classification: *tree*, *back*, *forward*, and *cross* edges. Library algorithms built on DFS (topological ordering, strong components, dominators) run dedicated index-space loops instead of consuming it, because events cost about twice a hand-written loop; user code consumes the sequence, so no visitor protocol is needed.
- **Orderings:** topological, lexicographic-BFS, and degeneracy orderings are `RandomAccessCollection`s.
- **Partitions** (**implemented** for directed graphs): strongly and weakly connected components are `Components`, a `RandomAccessCollection` of vertex slices in a documented order, with a `component(of:)` lookup that is O(1) after the graph's `vertexIndex(of:)` (no hashing on a matrix or compressed sparse row); see `Tests/ConnectivityTests/README.md`.
- **Not sequences:** the result types below. They're functions or sets with structure, and each exposes collections instead of being one.

| Module | Algorithms | Result types |
|---|---|---|
| `Traversal` | BFS, DFS, layers, descendants and ancestors, bidirectional BFS, iterative-deepening DFS, topological sorting (DFS, Kahn generations, lexicographical), cycle finding, and searches over successor closures (**implemented**). Lexicographic BFS waits for the undirected `Graph` | `BreadthFirstSearch`, `DepthFirstSearch` (both `Sequence`) |
| `ShortestPaths` | Dijkstra, Bellman–Ford, A*, DAG (`dagShortestPaths`, Boost's `dag_shortest_paths`: one relaxation per edge in a topological order, negative weights allowed, `nil` when a cycle is reachable; on a `DirectedAcyclicGraph`, in its maintained order) and unweighted shortest paths (**implemented**); DAG longest paths are `DirectedAcyclicGraph.longestPath(weight:)`; later bidirectional Dijkstra, Floyd–Warshall, Johnson, Yen's k-shortest paths, Δ-stepping, contraction hierarchies | `ShortestPathTree` (an `Arborescence` plus distances, with `path(to:) -> Path?`), `DistanceMatrix` |
| `SpanningTrees` | Minimum and maximum spanning forests of undirected graphs by Kruskal, Prim and Borůvka, with a canonical tie rule (weight, then position) (**implemented**, phase 1); later Chu–Liu/Edmonds (minimum arborescence), Steiner tree approximation | `SpanningForest` (edge positions and the total weight) |
| `Connectivity` | **Implemented:** Tarjan strong components (Pearce's layout; reverse topological order), `isStronglyConnected`, weak components (union–find), `isWeaklyConnected`, condensation (a `CompressedSparseRow`), attracting components, Lengauer–Tarjan dominator trees, dominance frontiers, post-dominator trees. All on `DirectedGraph` except post-dominators (`BidirectionalDirectedGraph`; for a `CompressedSparseRow`, use `transposed()`). Kosaraju is a test oracle only: it gives a second, different component order. **Implemented, undirected:** connected components, bridges, articulation points, biconnected components (blocks, as edge sets), bi-edge-connected components and the block–cut tree, by one iterative Hopcroft–Tarjan that skips the parent edge (so parallel edges are never bridges), with canonical orders. Vertex and edge connectivity belong to `Flows` | `Components`, `Condensation`, `DominatorTree` (a `RootedTree` once `Trees` exists), `DominanceFrontiers`, `BiconnectedComponents`, `BlockCutTree` |
| `Cycles` | `isAcyclic`, `findCycle()` and `findCycle(from:)` on `Graph`; `cycleBasis()` (fundamental cycles of the breadth-first forest); `simpleCycles(maxLength:)` on both kinds (Johnson, and Gupta–Suzumura with a bound; also called elementary circuits), lazy; `girth()` on both kinds. Self-loops and parallel edges count as cycles, each copy of an edge apart (**implemented**). Minimum cycle bases and chordless cycles later. See [Cycle handling](#cycle-handling) | `Cycle`, `DirectedSimpleCycles`, `UndirectedSimpleCycles` |
| `Tours` | On `DirectedGraph` and `Graph`: `isEulerian`, `hasEulerianTrail` (isolated vertices ignored; edgeless graphs, the empty one included, are Eulerian), `eulerianCircuit()`, `eulerianCircuit(from:)`, `eulerianTrail()`, `eulerianTrail(from:)` (Hierholzer, the first unused edge in row order, igraph's procedure and start rules; the graph's own rows on a compressed sparse row), `hamiltonianPath()`, `hamiltonianPath(from:)`, `hamiltonianPath(from:to:)`, `hamiltonianCycle()` (depth-first backtracking, the first in search order, with pruning that cannot change it); on `Graph`, tours of the simple graph (lightest copy of each pair, self-loops ignored, nil below three vertices): `nearestNeighborTour(weight:)` and `(from:weight:)` (NetworkX `greedy_tsp`), `christofidesTour(weight:)` (the canonical minimum spanning tree, MatchingModule's Galil matching, Hierholzer, shortcutting; integer and floating weights), `twoOptTour(weight:)` and `twoOptTour(improving:weight:)` (JGraphT `TwoOptHeuristicTSP`'s best-improvement procedure, from nearest neighbour), `shortestTour(weight:)` (Held–Karp, JGraphT `HeldKarpTSP`'s tour, any graph up to 31 vertices) (**implemented**, phase 1). Later (phase 2): directed (asymmetric) tours, eulerize and the Chinese postman tour, tours on non-complete graphs over the shortest-path closure and on distance functions, Or-opt, 3-opt and Lin–Kernighan, the greedy-edge, insertion and double-tree heuristics, a seeded random start for 2-opt | `Circuit`, `Trail`, `Path`, `Cycle` |
| `Flows` | On `DirectedGraph` and `Graph` (each edge either way): `maximumFlow` (highest-label push–relabel with gap and global relabelling, LEMON's two-phase `Preflow`), `maximumFlowValue` (its first phase), `edmondsKarpMaximumFlow` (the flow pinned by the procedure), `dinicMaximumFlow`, `minimumCut(from:to:)` (the least sink side, NetworkX's and igraph's), `minimumCut(capacity:)` global (Nagamochi–Ibaraki on `Graph`, Hao–Orlin on `DirectedGraph`, LEMON's two; a minimum cut, not pinned among several; sums formed wider than the capacity type), `gomoryHuTree()` (Gusfield; NetworkX's tree), `edgeConnectivity`, `vertexConnectivity`, `minimumVertexCut` (global and s–t), `edgeDisjointPaths` and `vertexDisjointPaths` (NetworkX's `edge_disjoint_paths`, `node_disjoint_paths`); on `DirectedGraph` `minimumCostFlow(supply:capacity:cost:)` (network simplex in LEMON's layout, integers, unsigned capacities allowed) and `minimumCostMaximumFlow` (**implemented**, phase 1). Measured and kept: the directed global cut by Hao–Orlin (7.2 ms against 81 ms for the n cyclic-pair flows on lcgnet(1000, 10⁴)); Even's pair order for `minimumVertexCut()` (Esfahanian–Hakimi not implemented). Later (phase 2, open items): Boykov–Kolmogorov, cost scaling, floating-point minimum-cost flow, lower bounds and GEQ/LEQ supply types, UNBALANCED told apart from INFEASIBLE, an infeasibility witness, the source-side minimal cut | `Flow` (value, per-edge flow, `flowMap`, the signed flow of an undirected edge, `minimumCut`), `Cut` (source and sink sides plus the crossing edges), `GomoryHuTree`, `MinimumCostFlow` (cost, flows, `flowMap`, potentials), `FlowMap`, disjoint paths as `Path`s |
| `MatchingModule` | On `Graph`: `maximalMatching()` (greedy), `maximumMatching()` (Edmonds' blossom, a documented procedure), `maximumBipartiteMatching(bipartition:)` (Hopcroft–Karp, NetworkX's matching), `maximumWeightMatching(weight:maximumCardinality:)` and `minimumWeightMatching(weight:)` (Galil's weighted blossom, NetworkX's matching, integer and floating weights), `minimumWeightFullMatching(bipartition:weight:)`, `isMatching`, `isMaximalMatching`, `isPerfectMatching`; the same bipartite entry points on `BipartiteGraph`; `linearSumAssignment` (scipy's assignment on a cost closure, exact integers) and `stableMatching` (Gale–Shapley, proposer-optimal) on indices (**implemented**, phase 1). Later: Gallai–Edmonds certificate, sparse full matching, b-matching, stable roommates | `Matching` (edges by position, `weight`, `mate(of:)`, `matchedEdge(of:)`, `isPerfect`), `LinearSumAssignment`, `StableMatching` |
| `ColoringModule` | On `Graph`, vertex colourings of its simple graph (self-loops ignored, parallel edges once): `greedyColoring(strategy:)` with a `ColoringStrategy`: `.largestFirst` (Welsh–Powell, the default), `.smallestLast` (Matula–Beck), `.saturationLargestFirst` (DSatur), `.independentSet`, `.connectedSequentialBreadthFirst` and `.connectedSequentialDepthFirst` (NetworkX's strategies, with NetworkX's colourings where its ties are in index order), and `.coloredNeighbors` (igraph's, with igraph's colourings); `greedyColoring(strategy:presetColor:)` (rustworkx's preset colours), `greedyColoring(order:)` (first fit in a given order), `chromaticNumber()` (exact, DSatur branch and bound), `minimumColoring()` (the search's optimal colouring, numbered by first appearance, as fast as `chromaticNumber()`) and `lexicographicallyFirstMinimumColoring()` (per component the lexicographically first colouring with its χ colours, Khuller–Vazirani's lexicographically first k-colouring; much slower on large sparse graphs). Edge colourings: `edgeColoring()` (Misra–Gries, ≤ Δ + 1, simple graphs), `bipartiteEdgeColoring()` (König, exactly Δ with parallel edges counted, `nil` when not bipartite), `greedyEdgeColoring()` (rustworkx's, ≤ 2Δ − 1, any graph, so `digraph.undirected` too). The checks `isVertexColoring`, `isEdgeColoring` (**implemented**, phase 1). Later: interchange, equitable colouring, exact chromatic index, Shannon/Vizing multigraph edge colouring | `Coloring` (`color(of:)`, `color(ofIndex:)`, `colors` in index order, `colorCount`, `colorClasses`), `EdgeColoring` (`color(ofEdgeAt:)`, `colorCount`, `colorClasses` as edge positions) |
| `Cliques` | On `Graph`, over its simple graph (loops ignored, parallel edges once): `maximalCliques()` (lazy; Eppstein–Löffler–Strash in degeneracy order with Tomita's pivot, a documented order), `cliqueNumber()`, `maximumClique()` (the lexicographically least), `coreNumbers()` (Batagelj–Zaversnik: core numbers, `degeneracy`, `degeneracyOrdering`, `kCore`, `kShell`), `clusteringCoefficients()` and the one-shots `triangleCount()`, `transitivity()`, `averageClustering()`, `triangleCount(of:)`, `clusteringCoefficient(of:)` (compact-forward triangles) (**implemented**). Directed cores and clustering, weighted clustering, k-truss later | `MaximalCliques`, `CoreNumbers`, `ClusteringCoefficients` |
| `Covering` | On `Graph`: `maximumIndependentSet()`, `independenceNumber()`, `minimumVertexCover()` and `minimumDominatingSet()` (exact, the lexicographically least sets; bipartite components in O(m √n) from a maximum matching, the rest by branch and bound), König's `minimumVertexCover(bipartition:)` (NetworkX `to_vertex_cover`), `maximalIndependentSet()` (greedy, optionally from seeds), `approximateMinimumVertexCover` (Bar-Yehuda–Even) and `approximateMinimumDominatingSet` (Chvátal's greedy), both NetworkX's sets, `minimumEdgeCover()`, and the checks `isVertexCover`, `isIndependentSet`, `isDominatingSet`, `isEdgeCover` (**implemented**, phase 1). Later: exact weighted covers (minimum cut, in `Flows`), connected domination, reductions | Vertex sets as `[Vertex]` in `vertices` order, edge sets as positions |
| `Centrality` | On `Graph` and `DirectedGraph`, with NetworkX's defaults: `degreeCentrality()` (and in- and out-degree), `closenessCentrality()` (Wasserman–Faust corrected by default) and `harmonicCentrality()` over incoming distances, whole or for one vertex, `betweennessCentrality()` (Brandes, accumulated on the successor side; parallel edges are distinct paths), unweighted and weighted; `eigenvectorCentrality()`, `katzCentrality()`, `pageRank()` (optionally personalized) and, on `DirectedGraph`, `hits()`, by power iteration, `nil` when they do not converge (**implemented**). Later: approximate betweenness by sampling, edge betweenness, load, current-flow and percolation centrality | `CentralityScores` (a dense vector indexed by vertex, with `score(of:)`), `HubAndAuthorityScores` |
| `CommunityDetection` | `modularity(of:resolution:)` (Newman–Girvan; Leicht–Newman on `DirectedGraph`) and `partitionQuality(of:)` for any grouping of the vertices; `louvainCommunities()` (Blondel et al., with NetworkX's gain and stop rule), `greedyModularityCommunities()` (Clauset–Newman–Moore), and on `Graph` `labelPropagationCommunities()` (semi-synchronous) and `asynchronousLabelPropagationCommunities()`, unweighted and weighted, deterministic (vertices in index order; ties keep the current community, else the greatest label), with `using:` overloads that shuffle like NetworkX's `seed` (**implemented**, phase 1). Later: Leiden, Girvan–Newman with edge betweenness, dendrograms, fast label propagation | `Partition` (communities in canonical order, `community(of:)`), `PartitionQuality` |
| `IsomorphismModule` | VF2 and VF2++ (graph and subgraph isomorphism), Weisfeiler–Leman, canonical labeling | `Isomorphism` (a bijection V(G) → V(H)) |
| `Planarity` | Boyer–Myrvold planarity test and embedding | `PlanarEmbedding`, or a Kuratowski subgraph as the witness that the graph is not planar |
| `TreeAlgorithms` | Lowest common ancestors (one query by climbing, or `LowestCommonAncestors`: O(n) build, O(1) queries by a range minimum over preorder), `eulerTour`, `HeavyLightDecomposition` (heavy paths and subtrees as position intervals, a path as at most 2⌊log₂ n⌋ + 1 segments), and on `Tree`: `center`, `centroid`, `centroidDecomposition`, `diameter` and `diameterPath`, unweighted and weighted, with canonical tie rules in `vertices` order (**implemented**) | `LowestCommonAncestors`, `HeavyLightDecomposition`, `Walk`, `Path`, `RootedTree` |
| `Distances` | On `Graph` and `DirectedGraph` (out-distances), unweighted and weighted: `eccentricities()`, `eccentricity(of:)`, `radius()`, `diameter()`, `center()`, `periphery()`, `diameterPath()`, `centroid()` (least total distance; NetworkX 3.7's name), `wienerIndex()`, `averageShortestPathLength()`, `density`. An unreachable vertex makes an eccentricity `nil` (infinite), so the diameter is `nil` exactly when the graph is not (strongly) connected. Undirected unweighted extrema by Takes–Kosters bounding (a handful of searches on sparse graphs), directed by pruned searches, weighted by Dijkstra from every vertex; tie rules as `TreeAlgorithms` (**implemented**). Later: iFUB, bounding on directed and weighted graphs, a `DistanceMatrix` with Floyd–Warshall and Johnson | `Eccentricities`, `Path` |
| `SpectralGraphTheory` | Adjacency, Laplacian, and normalized Laplacian matrices; Fiedler vector; spectral clustering (Accelerate where it's available) | |

### Cycle handling

Cycle detection is offered only on structures that can contain a cycle. Each one has its own algorithm, and a successful detection always returns the `Cycle` as a witness, not just a `Bool`.

| Structure | Cycle API |
|---|---|
| `DirectedAcyclicGraph`, `Tree`, `Forest`, `Arborescence` | **None.** Acyclicity is an invariant, and the DAG enforces it when an edge is inserted. |
| `DirectedGraph` | `simpleCycles(maxLength:)` (Johnson's elementary circuits; Gupta–Suzumura with a bound) and `girth()` in `Cycles`. Finding one cycle, `isAcyclic` and topological sorting are in `Traversal`: `findCycle()`, `isAcyclic`, `topologicalSort()` returning `nil` on a cycle. A cycle basis of a digraph is the undirected one: `digraph.undirected.cycleBasis()` |
| `Graph` | `isAcyclic` (a disjoint-set over the rows), `findCycle() -> Cycle?` (depth-first, never back along the edge it arrived by, so a parallel pair is found), `cycleBasis()`, `simpleCycles(maxLength:)` and `girth()` in `Cycles`; `findOddCycle()` (the witness that a graph is not bipartite) in `BipartiteGraphs`, also the witness for `bipartiteEdgeColoring()` returning `nil` in `ColoringModule`. Every undirected cycle returned starts at its least vertex and leaves it through the lesser of its two edges, so equal cycles have equal arrays |
| Weighted `DirectedGraph` | Negative-cycle detection (Bellman–Ford): `bellmanFordShortestPaths` returns `nil` when a negative cycle is reachable, and `findNegativeCycle` returns one as the witness, as `topologicalSort()` and `findCycle()` do |
| `BipartiteGraph` | **None for odd cycles**: every cycle is even, an invariant. Even cycles are `Graph`'s |
| `FunctionalGraph` | Floyd's and Brent's algorithms |

Failures that are part of the mathematics, such as "has a cycle," "not bipartite," or "negative cycle," **return the witness** (`findCycle() -> Cycle<Vertex, Edges.Index>?`, an optional result next to it), rather than throwing: a thrown error must be `Sendable` in Swift 6, which would exclude vertex types that are not.

## Generators (`NamedGraphs`, `RandomGraphs`)

All families are static factories on the representation types, for example
`CompressedSparseRow.complete(vertexCount: 5)` or
`UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 1000, edgeProbability: 0.01, using: &generator)`
(**implemented**). Each family is written once, against two underscored protocols in
`GraphProtocols`, `_DirectedGraphConstruction` and `_GraphConstruction`, whose one requirement is a
bulk initializer from sorted, simple `Int` edges (Boost's edge-iterator constructor, by name). The
conformers are `CompressedSparseRow` (one pass, no hashing), `AdjacencyMatrix`, `AdjacencyList<Int>`,
`DirectedPseudograph<Int>`, `DirectedMultigraph<Int>` and `StableDirectedGraph<Int>`, and undirected
`UndirectedAdjacencyList<Int>`, `Pseudograph<Int>` and `Multigraph<Int>`. Vertices are `0..<n` with a
documented numbering, and edges come sorted, so `edges` reads the same on every conformer.

| Module | Graphs |
|---|---|
| `NamedGraphs` | `complete`, `completeBipartite`, `path`, `cycle`, `star`, `wheel`, `grid(dimensions:periodic:)` (any number of dimensions, row-major, optionally a torus), `hypercube`, `petersen`, `empty`; directed forms along the natural orientation (path, cycle, star, wheel, left → right) or with both arcs (complete, grid, hypercube, Petersen); `Tree.path`, `Tree.star` and `BipartiteGraph.completeBipartite` built without validation. The Θ(n²) families read their edges lazily, with no edge list |
| `RandomGraphs` | `erdosRenyi` G(n, p) (Batagelj–Brandes skipping) and G(n, m), `barabasiAlbert` (directed new → old), `wattsStrogatz`, `randomGeometric` (with its positions, through a cell grid), `stochasticBlockModel` (skipping over each block pair, indexed arithmetically), `Tree.random` (a Prüfer code), and the Barak–Erdős random DAG `DirectedAcyclicGraph.erdosRenyi`, whose order 0..<n is handed to the wrapper with no Kahn pass |

Random generators take `inout some RandomNumberGenerator` so their output is reproducible, and each
has an overload on the system generator. `RandomGraphs` ships `Xoshiro256StarStar` (Blackman and
Vigna), seeded through SplitMix64. Every procedure draws only a 53-bit `uniform01` and CPython's
rejection `below(n)`, never the standard library's `random(in:)`, so each output is a function of the
generator's stream and is pinned in the catalog: NetworkX 3.7, run on the same stream, reproduces
the graphs edge for edge (Barabási–Albert and the block model wherever CPython's set order happens
to be ascending, G(n, m) while 2m ≤ n(n − 1)/2). See `Tests/Catalogs/NamedGraphs/` and `Tests/Catalogs/RandomGraphs/`.

## Drawing (`GraphDrawing`)

Graph drawing (layout) means assigning a point in the plane to every vertex. It works on any graph; it is not a graph type.

| Approach | Methods |
|---|---|
| ForceDirected | Fruchterman–Reingold, Kamada–Kawai, ForceAtlas2, stress majorization, Barnes–Hut approximation (quadtree) |
| Layered | Sugiyama framework for DAGs: cycle removal, layer assignment, crossing minimization, coordinate assignment |
| Trees | Reingold–Tilford, radial |
| Spectral | Coordinates from Laplacian eigenvectors |
| Circular | Circular layout |

The result, `Drawing<Vertex>`, maps vertices to `SIMD2<Double>` positions. Iterative methods can run one step at a time (`mutating step()`), so a layout can be animated.

## Formats (`GraphFormats`)

Readers and writers for DOT (Graphviz), GraphML, GML, GEXF, JSON node-link, Matrix Market, and edge-list and adjacency-list text. Representations also get `Codable` conformance where their vertex type is `Codable`.

## Data structures

These are public, because they're useful on their own.

| Type | What it is | Conformances |
|---|---|---|
| `IndexedPriorityQueue` | A 4-ary min-heap over the indices `0..<indexBound` with a position array, giving O(log n) `decreasePriority(of:to:)` (**implemented**) | **Not** a `Sequence`; it exposes an `unordered` view instead, as swift-collections' `Heap` does. `Sendable`. Ties leave in an unspecified order (a documented rule cost 7–64% in Dijkstra). Not a replacement for `Heap`, which cannot change a queued element: lazy deletion with `Heap` is 1.1–1.4× slower in Dijkstra and 2.6× slower when every item is decreased, while for pushes and pops alone `Heap` is faster. `insertOrDecreasePriority(of:to:)` is the one-call relaxation step. |
| `DisjointSet` | Union–find over `0..<count` with union by size and path halving | Not a `Sequence`. `Sendable`, `Hashable` (same partition, whatever the representatives). `find` and `union` are `mutating`; the other queries work on a `let`. |
| Bit sets | swift-collections' `BitSet` (`BitCollections`) | `AdjacencyMatrix` rows and columns, and visited sets in algorithms |

## Performance notes

- **Storage:** as few allocations per value as the layout allows, in `ContiguousArray`/`Array` storage (whose copy-on-write is already the standard library's) or a `ManagedBuffer` where one block fits better. `CompressedSparseRow` holds two arrays, sized exactly; an empty graph shares one static offsets array.
- **Copy-on-write:** `isKnownUniquelyReferenced` is checked in an `@inline(__always)` fast path, and the reallocation path is in an `@inline(never)` function. A unique buffer moves its elements on reallocation instead of copying them.
- **Hoisted checks:** bulk mutations check uniqueness once, outside the loop.
- **Unsafe handles:** algorithms run their inner loops against unsafe handles. Scratch storage (distance arrays, BFS queues) uses noncopyable `~Copyable` buffers with no copy-on-write at all.
- **Specialization:** algorithm parameters are `some` generics, never `any`, and algorithms are `@inlinable`: across a module boundary, unspecialized generic code runs 10–18× slower than specialized code, and an existential allocates for every neighborhood it reads. Public storage is `@frozen` with `@usableFromInline` internals.
- **Checks:** `precondition` on public boundaries; internal invariant checks are compiled in only behind a build flag.
- **Benchmarks:** baselines against BGL and LEMON (C++) and petgraph (Rust).

## Open questions

1. ~~Should `Graph` refine `DirectedGraph`?~~ **Decided: no**, they are separate protocols.
2. ~~Dense `Int` vertices or generic `Vertex: Hashable`?~~ **Decided: generic `Vertex: Hashable`** for representations that can support it (adjacency list, edge list). Matrix and compressed sparse row layouts are inherently index-based; `LabeledGraph` remains the bridge for those.
3. ~~Should weights be stored in representations or always passed in as weight functions?~~ **Decided: passed in**, as a non-escaping closure over edge positions, `(Edges.Index) -> W`, never stored. With dense edge positions (`edgeIndexBound`) the closure is an array read: Dijkstra on compressed sparse row then runs at 1.02–1.08× a hand-written loop. A closure over endpoints costs 1.2–7×. `AdjacencyList` has dense `Int` positions for this reason.
4. ~~Depend on swift-collections?~~ **Decided: yes**, where its types serve as backing storage (`BitSet` for matrix rows today).
5. Should construction include edge operators such as `-->`?
6. Should the deployment floor be macOS 26 / iOS 26, which `Array.span` requires, or should we support older operating systems with `Span` back-deployment only?
7. ~~Is `BidirectionalDirectedGraph` an established name?~~ **Decided: yes.** It is Boost's `BidirectionalGraph` concept, defined for exactly this property. `predecessors(of:)` stays off the base protocol, so compressed sparse row does not hide an O(|A|) cost behind an O(1)-looking call.
8. ~~Names of the views between `Graph` and `DirectedGraph`?~~ **Decided:** `graph.directed` (`DirectedView`) and `digraph.undirected` (`UndirectedView`), after NetworkX's directed view and JGraphT's `AsUndirectedGraph` (which, unlike NetworkX's undirected view, keeps opposite arcs as parallel edges). No type conforms to both protocols, since they share member names (`edges`, `degree(of:)`) with different meanings.
9. Can we do better than data kept in arrays beside the graph? (Last in the plan, after every module and the reuse pass.) Today vertex and edge data (labels, weights, payloads) lives in caller-owned arrays indexed by position, and callers must mirror every swap-remove themselves. Candidates: maps that follow the graph's mutations (LEMON's `NodeMap`/`ArcMap`, BGL's property maps), representations that store payloads (petgraph's `Graph<N, E>`, NetworkX attributes), or `StableDirectedGraph`'s fixed positions. Any answer must keep question 3's fast path: algorithms still read weights through a closure over positions. **Direction chosen:**
   - **Attached maps.** Maps the graph owns, after LEMON's `NodeMap`/`ArcMap` and its alteration notifier, in value form: `addEdgeMap(of:)` gives a handle, and `graph[map, ofEdgeAt:]` reads and writes. Every removal updates the maps in the same mutation; a swap-remove moves the swapped edge's entries. `StableDirectedGraph` is the prototype; every mutable representation gets the same protocol.
   - **Weights.** A typed read-only view of a map feeds the existing `weight:` closures, with no new algorithm overloads.
   - **Graph adaptors** (BGL's and LEMON's term). `DirectedView`, `UndirectedView`, and later the reversed, filtered and residual views and `LabeledGraph`, share a protocol exposing `base`. They pass positions through, so the base's maps work through the adaptor.
   - **Rule-adding wrappers.** `DirectedMultigraph` over `DirectedPseudograph`, `Multigraph` over `Pseudograph` and `BipartiteGraph` over `UndirectedAdjacencyList` adopt the same `base` protocol. Every read member is forwarded by default and inlined, so a wrapper holds only its insertion rules. `DirectedAcyclicGraph` is the first wrapper generic over its base, through `MutableDirectedGraph` (Boost's `MutableGraph`), whose underscored key hooks are the mutation side of that protocol. A representation that changes storage, like `StableDirectedGraph`, stays its own type, built from shared storage components such as the row pool.
   - **Derived structures built once.** A condensation or a compressed sparse row snapshot detects staleness with a generation counter on the graph rather than with observation. Swift's Observation is class-based and doesn't survive value copies.

## License

MIT. See [LICENSE](LICENSE).
