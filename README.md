# Grafluent

A generic, high-performance graph library for Swift.

This document is the design scaffold. It names every type the library intends to provide, says what each one is, and says which Swift protocols it should (and should not) conform to. `AdjacencyList` and `AdjacencyMatrix` are implemented; everything else is planned.

## Principles

1. **Established names only, familiar ones first.** Every name is the term programmers already know from the major graph libraries (Boost, NetworkX, petgraph, JGraphT), or the algorithm's author (Dijkstra, Tarjan, Hopcroft–Karp). The mathematical term is used only when there is no common one or the common one is ambiguous. Nothing is invented (see [Terminology](#terminology)).
2. **Value semantics, no mutable twins.** Each representation is one copy-on-write value type. `let` is immutable, `var` is mutable, and mutation is a set of `mutating` methods. Representations whose layout makes mutation expensive (compressed sparse row) offer initializers only.
3. **As fast as the standard library.** Storage follows the patterns used by `Array` and swift-collections: one allocation per value, the uniqueness check inlined with the reallocation path out of line, `_modify` accessors, and algorithms written against unsafe handles inside `withUnsafe…` scopes. Public types are `@frozen` and algorithms are `@inlinable`, so generic code specializes fully in the caller.
4. **Invariants live in types.** A `DirectedAcyclicGraph` cannot contain a cycle, and a `Tree` has exactly one `parent(of:)`. Algorithms that need a property say so in their signature instead of checking at run time.
5. **Minimum toolchain: Swift 6.2** (proposed). This gives us `Span`, `InlineArray`, noncopyable types, and typed throws.

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
| Structures | `DirectedAcyclicGraphModule`, `Trees`, `BipartiteGraphs`, `Multigraphs`, `Hypergraphs`, `FlowNetworks`, `FunctionalGraphs` |
| Operations | `GraphOperations`, `GraphProducts` |
| Algorithms | `Traversal`, `ShortestPaths`, `SpanningTrees`, `Connectivity`, `Cycles`, `Tours`, `Flows`, `MatchingModule`, `ColoringModule`, `Cliques`, `Covering`, `Centrality`, `CommunityDetection`, `IsomorphismModule`, `Planarity`, `TreeAlgorithms`, `Distances`, `SpectralGraphTheory` |
| Generators | `NamedGraphs`, `RandomGraphs` |
| Drawing and formats | `GraphDrawing`, `GraphFormats` |

```
Sources/<Module>/            One directory per module, each with a generated BUILD.bazel
Tests/GrafluentTestSupport/  Shared test data: fixtures, stress vertex types, lifetime tracking
Tests/<Module>Tests/         One test target per module, added when its first suite is written
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
| `just setup-hooks` | Format staged Swift files on commit |

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
| Edge directions dropped | `undirected` | NetworkX, JGraphT | underlying graph |
| Rooted-tree relations | `parent(of:)`, `children(of:)`, `root` | all | same |
| Reachability | `descendants(of:)`, `ancestors(of:)` | NetworkX | same |
| Edge values | weight function | all | w : E → S |

`size` is avoided because programmers read it as memory size. `successors` and `predecessors`
always mean vertices one edge away; in order theory they can mean any reachable vertex, but no
graph library uses them that way.

## Protocols (`GraphProtocols`)

A graph is a pair (V, E). We don't think a graph should itself be a `Sequence`: should iterating it yield vertices or edges? Neither answer is obviously right. A graph instead *exposes* collections, the same way `Dictionary` exposes `keys` and `values`.

| Protocol | Requirements (sketch) | Notes |
|---|---|---|
| `DirectedGraph` | `associatedtype Vertex`, `vertices`, `edges`, `successors(of:)`, `contains(edge:)` | The base protocol. Traversal, shortest paths, and most of the library need only this. `contains(edge:)` (the adjacency test) defaults to a scan of N⁺(u); matrices answer in O(1) and sorted compressed sparse row in O(log d). |
| `Graph` | `neighbors(of:)`, `edges` | An undirected graph. **Decided:** `Graph` and `DirectedGraph` are separate protocols; an undirected graph is not modeled as a symmetric directed graph. |
| `BidirectionalDirectedGraph` | `predecessors(of:)` | Needed for reversed traversal, dominators, and Kosaraju. The name is borrowed from Swift's `BidirectionalCollection`, not from graph theory; see open question 7. |
| `DirectedMultigraph` / `Multigraph` | Edges carry identity, `edges(from:to:)` | Parallel edges are allowed. |
| `Hypergraph` | `hyperedges`, `incidentHyperedges(of:)` | Separate from `DirectedGraph`, because a hyperedge is not an edge. |

All protocols are `Sendable` when their vertex type is. There is no protocol for mutation; mutation belongs to concrete types.

### Associated collections

| Member | Minimum requirement | What representations should return |
|---|---|---|
| `vertices` | `Collection` | `Range<Int>` for index graphs, a `RandomAccessCollection` for labeled graphs |
| `edges` / `edges` | `Collection` | `RandomAccessCollection` for compressed sparse row and edge lists, a forward `Collection` over set bits for matrices |
| `successors(of:)` | `Sequence` | `Span<Vertex>` for contiguous storage, a set-bit `Collection` for matrices, a plain `Sequence` for implicit graphs |

The neighbor requirement is only `Sequence` so that implicit graphs, whose neighbors are computed on demand, can conform. Algorithms that need more (a count, or several passes) put that constraint in their own signature.

### Elements (`GraphProtocols`)

| Type | What it is | Swift conformances |
|---|---|---|
| `DirectedEdge<Vertex>` | Ordered pair (source, target) | `Hashable`, `Sendable`, `Codable` when `Vertex` is; `BitwiseCopyable` when `Vertex` is; `CustomStringConvertible` as `u → v` |
| `UndirectedEdge<Vertex>` | Unordered pair {u, v} | Same as `DirectedEdge`, but `==` and `hash(into:)` are symmetric, so {u, v} = {v, u}. Hashing must not depend on order (needs `Comparable` endpoints, or a commutative hash combination). |
| `Hyperedge<Vertex>` | A nonempty set of vertices | `Hashable`, `Sendable`, `Codable`; possibly `SetAlgebra`, since it really is a set |

### Walks (`Walks`)

| Type | What it is | Swift conformances |
|---|---|---|
| `Walk<Vertex>` | A sequence of vertices with an edge between each consecutive pair; repeats allowed | `RandomAccessCollection` of vertices, `Hashable`, `Codable`, `Sendable`. Exposes `edges` as a lazy `adjacentPairs` view. |
| `Trail<Vertex>` | A walk with no repeated edges | Same as `Walk` |
| `Path<Vertex>` | A walk with no repeated vertices | Same as `Walk` |
| `Circuit<Vertex>` | A closed trail | `RandomAccessCollection`. `==` holds up to rotation, which `hash(into:)` must respect (hash a canonical rotation). |
| `Cycle<Vertex>` | A closed path | Same as `Circuit`. Returned as the *witness* whenever cycle detection succeeds. |

These are the one place where `Collection` conformance is clearly right: a walk *is* a sequence.

### Weights (`Semirings`)

| Type | What it is | Swift conformances |
|---|---|---|
| Weight function | A map w : E → S. Weights are kept separate from the representation and are passed to algorithms, either as a closure or as a dense array indexed by edge. | n/a |
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

**Open question:** whether to add edge operators such as `"a" --> "b"`. They read well, but they cost compile time and make type inference harder.

## Representations

Every representation is a copy-on-write value type built on one `ManagedBuffer` allocation, and every one conforms to `Sendable` (when its vertex type is), `Equatable`, `Hashable`, `CustomStringConvertible`, and `CustomDebugStringConvertible`. `Codable` is conditional on the vertex type.

**Equality means equal vertex sets and equal edge sets.** It is *not* isomorphism, which is a separate algorithm. Equality must not depend on the order edges were inserted. Representations that keep each neighbor list sorted get O(|V| + |A|) equality; the rest have to normalize first.

| Type | What it is | Mutation | Notes and conformances |
|---|---|---|---|
| `AdjacencyList<Vertex>` | Each vertex maps to its out-neighbors | Yes | Stored as one flat edge pool with a range per vertex, not `[[Vertex]]`, which would need one uniqueness check per row. `ExpressibleByDictionaryLiteral`. |
| `AdjacencyMatrix` | A directed graph on vertices `0..<n` as an n×n bit matrix (**implemented**) | Edges, rows and columns; vertices by `appendVertex()`, never removed | `successors(of:)` / `predecessors(of:)` are swift-collections `BitSet`s; O(1) degrees; transpose, union, intersection, subtraction, complement; row-major `edges` whose positions are cells. See `Tests/AdjacencyMatrixTests/README.md`. Weights stay external: for a matrix, as a closure `(source, target) -> W` or an n×n side matrix, never an edge-indexed array (cell positions span n², not the edge count). |
| `IncidenceMatrix` | \|V\|×\|E\| matrix | Yes | Mostly for hypergraphs and spectral methods |
| `CompressedSparseRow` | Offsets array (n+1) plus targets array (m) | **No**, initializers only | The main performance target. Neighbors come back as `Span<Int>`, sorted. |
| `CompressedSparseColumn` | The transpose layout, giving in-neighbors as spans | No | Combined with compressed sparse row, it conforms to `BidirectionalDirectedGraph`. |
| `EdgeList<Vertex>` | A flat list of edges | Yes | `RandomAccessCollection` of `DirectedEdge` (this one really is a sequence of edges). Kruskal's input format. |
| `LabeledGraph<Label, Base>` | Vertex labels mapped to dense indices of an index-based representation | Mirrors `Base` | The label-to-index map follows `OrderedSet`'s design (dense array plus bit-packed hash table). Lets every algorithm run on `Int` vertices. |
| `ImplicitDirectedGraph<Vertex>` | Out-neighbors computed by a closure; never stored | No | Conforms only to `DirectedGraph`, with `Sequence` neighbors. Used for grids, state spaces, and A*. |

## Structures

These are graph classes whose defining property is an invariant enforced by the type.

| Type | Invariant | Cycle handling | Notes and conformances |
|---|---|---|---|
| `DirectedAcyclicGraph<Base>` | No directed cycle | **Inserting an edge that would close a cycle throws `CycleError` containing the `Cycle`.** Uses incremental cycle detection (an online topological ordering such as Pearce–Kelly). | Keeps a topological ordering, exposed as a `RandomAccessCollection`. No separate `isAcyclic` method, because acyclicity is guaranteed. |
| `Tree<Vertex>` | Connected and acyclic, undirected | Invariant, so no detection | `Graph` |
| `RootedTree<Vertex>` | A tree with a distinguished root | Invariant | `parent(of:) -> Vertex?`, `children(of:)`, `root`, `depth(of:)` |
| `Forest<Vertex>` | Acyclic, undirected | Invariant | The components are a `Collection` of `Tree` |
| `Arborescence<Vertex>` | A directed rooted tree, with every edge pointing away from the root | Invariant | `parent`, `children`, `root`. The result type of shortest-path trees and DFS/BFS trees. |
| `BipartiteGraph<Base>` | V = L ⊔ R, and every edge crosses between L and R | n/a | Exposes `left` and `right` as collections. Constructing one from a general graph is a 2-coloring that throws with an odd cycle as the witness. |
| `Multigraph<Base>` / `DirectedMultigraph<Base>` | Parallel edges allowed | n/a | Edges have identity (an index), so a `DirectedEdge` value alone isn't enough to name one |
| `Pseudograph<Base>` | Parallel edges and self-loops allowed | n/a | |
| `Hypergraph<Vertex>` | Edges are vertex subsets of any size | n/a | Conforms to `Hypergraph`, not `DirectedGraph` |
| `FlowNetwork<Base, Capacity>` | A digraph with capacity c : A → ℝ≥0, a source s, and a sink t | n/a | The input to the flow algorithms. The residual network is a view of it, not a copy. |
| `FunctionalGraph` | Every vertex has out-degree exactly 1 (the iteration of a function f : V → V) | **Floyd's and Brent's cycle detection**, with O(1) memory | Can be built straight from a closure, with no stored graph |

## Operations (`GraphOperations`, `GraphProducts`)

Unary operations return **lazy views** with no copying. Each view conforms to the same core protocols as its base, conditionally. Calling a representation's initializer on a view (`CompressedSparseRow(g.reversed)`) copies it into real storage.

| Operation | Result | Kind |
|---|---|---|
| `subgraph(vertices:edges:)`, `inducedSubgraph(on:)`, `spanningSubgraph(edges:)` | Subgraph views | Lazy view |
| `reversed` | Every edge reversed | Lazy view (O(1) when the base is a `BidirectionalDirectedGraph`) |
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

- **Traversals:** `BreadthFirstSearch` and `DepthFirstSearch` are lazy `Sequence`s of events. Traversal is inherently one pass, and making it lazy gives early termination for free. DFS events use the CLRS edge classification: *tree*, *back*, *forward*, and *cross* edges. Algorithms built on DFS (topological ordering, strong components, cut vertices) consume this sequence, so no visitor protocol is needed.
- **Orderings:** topological, lexicographic-BFS, and degeneracy orderings are `RandomAccessCollection`s.
- **Partitions:** connected and strongly connected components are a `RandomAccessCollection` of vertex collections, with an O(1) `component(of:)` lookup.
- **Not sequences:** the result types below. They're functions or sets with structure, and each exposes collections instead of being one.

| Module | Algorithms | Result types |
|---|---|---|
| `Traversal` | BFS, DFS, bidirectional BFS, iterative-deepening DFS, lexicographic BFS, topological ordering (Kahn and DFS) | `BreadthFirstSearch`, `DepthFirstSearch` (both `Sequence`), `TopologicalOrdering` |
| `ShortestPaths` | Dijkstra, Bellman–Ford, A*, bidirectional Dijkstra, DAG shortest and longest paths, Floyd–Warshall, Johnson, Yen's k-shortest paths, Δ-stepping, contraction hierarchies | `ShortestPathTree` (an `Arborescence` plus distances, with `path(to:) -> Path?`), `DistanceMatrix` |
| `SpanningTrees` | Kruskal, Prim, Borůvka, Chu–Liu/Edmonds (minimum arborescence), Steiner tree approximation | `SpanningTree`, `SpanningForest` |
| `Connectivity` | Components, Tarjan and Kosaraju strong components, weak components, blocks (biconnected components), cut vertices, bridges, vertex and edge connectivity, Lengauer–Tarjan dominators | `Components`, `DominatorTree` (a `RootedTree`) |
| `Cycles` | See [Cycle handling](#cycle-handling) | `Cycle`, `CycleBasis` |
| `Tours` | Hierholzer (Eulerian trail and circuit), backtracking Hamiltonian path and cycle, Christofides, 2-opt | `Trail`, `Circuit`, `Path`, `Cycle` |
| `Flows` | Edmonds–Karp, Dinic, push–relabel, minimum-cost flow, Stoer–Wagner minimum cut, Karger, Gomory–Hu | `Flow` (a function A → capacity, plus its value), `Cut` (two vertex sets plus the crossing edges), `GomoryHuTree` |
| `MatchingModule` | Hopcroft–Karp, Hungarian, Edmonds' blossom, Gale–Shapley | `Matching` (a set of edges, with `mate(of:)`) |
| `ColoringModule` | Greedy, DSatur, Welsh–Powell, exact chromatic number, edge coloring, bipartiteness test | `Coloring` (a function V → color index, plus the number of colors) |
| `Cliques` | Bron–Kerbosch, k-core decomposition, triangle counting, clustering coefficient | `Clique` (a vertex set) |
| `Covering` | Vertex cover, maximum independent set, dominating set (exact and approximation algorithms) | Vertex sets |
| `Centrality` | Degree, closeness, harmonic, Brandes betweenness, eigenvector, Katz, PageRank, HITS | A dense vector indexed by vertex |
| `CommunityDetection` | Louvain, Leiden, label propagation, Girvan–Newman, modularity | `Partition` |
| `IsomorphismModule` | VF2 and VF2++ (graph and subgraph isomorphism), Weisfeiler–Leman, canonical labeling | `Isomorphism` (a bijection V(G) → V(H)) |
| `Planarity` | Boyer–Myrvold planarity test and embedding | `PlanarEmbedding`, or a Kuratowski subgraph as the witness that the graph is not planar |
| `TreeAlgorithms` | Lowest common ancestor, Euler tour, heavy–light decomposition, centroid, diameter | |
| `Distances` | Eccentricity, diameter, radius, center, periphery, density, degree sequence | |
| `SpectralGraphTheory` | Adjacency, Laplacian, and normalized Laplacian matrices; Fiedler vector; spectral clustering (Accelerate where it's available) | |

### Cycle handling

Cycle detection is offered only on structures that can contain a cycle. Each one has its own algorithm, and a successful detection always returns the `Cycle` as a witness, not just a `Bool`.

| Structure | Cycle API |
|---|---|
| `DirectedAcyclicGraph`, `Tree`, `Forest`, `Arborescence` | **None.** Acyclicity is an invariant, and the DAG enforces it when an edge is inserted. |
| `DirectedGraph` | `cycle() -> Cycle?` using DFS back edges; `isAcyclic`; topological ordering that throws with the cycle; Johnson's elementary circuits; girth |
| `Graph` | `cycle() -> Cycle?` using DFS or a disjoint-set; cycle basis; girth |
| Weighted `DirectedGraph` | Negative-cycle detection (Bellman–Ford), surfaced as a typed error from the shortest-path algorithms |
| `FunctionalGraph` | Floyd's and Brent's algorithms |

Failures that are part of the mathematics, such as "has a cycle," "not bipartite," or "negative cycle," use **typed throws** (`throws(CycleError)`). That way callers can match on the witness without a cast.

## Generators (`NamedGraphs`, `RandomGraphs`)

All families are static factories on the representation types, for example `CompressedSparseRow.complete(vertexCount: 5)`.

| Module | Graphs |
|---|---|
| `NamedGraphs` | Complete Kₙ, complete bipartite Kₘ,ₙ, path Pₙ, cycle Cₙ, star Sₙ, wheel Wₙ, grid / lattice, hypercube Qₙ, Petersen, empty graph |
| `RandomGraphs` | Erdős–Rényi G(n, p) and G(n, m), Barabási–Albert, Watts–Strogatz, random geometric, stochastic block model, random trees (Prüfer sequences), random DAGs |

Random generators take `inout some RandomNumberGenerator` so their output is reproducible.

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
| `IndexedPriorityQueue` | A d-ary heap with a position array, giving O(log n) decrease-key | **Not** a `Sequence`; it exposes an `unordered` view instead, as swift-collections' `Heap` does. `Sendable`. |
| `DisjointSet` | Union–find with path compression and union by rank | Not a `Sequence`. `Sendable`, `Equatable` (same partition). |
| Bit sets | swift-collections' `BitSet` (`BitCollections`) | `AdjacencyMatrix` rows and columns, and visited sets in algorithms |

## Performance notes

- **Storage:** one `ManagedBuffer` allocation per value, with a shared empty instance so empty graphs never allocate.
- **Copy-on-write:** `isKnownUniquelyReferenced` is checked in an `@inline(__always)` fast path, and the reallocation path is in an `@inline(never)` function. A unique buffer moves its elements on reallocation instead of copying them.
- **Hoisted checks:** bulk mutations check uniqueness once, outside the loop.
- **Unsafe handles:** algorithms run their inner loops against unsafe handles. Scratch storage (distance arrays, BFS queues) uses noncopyable `~Copyable` buffers with no copy-on-write at all.
- **Specialization:** algorithm parameters are `some` generics, never `any`. Public storage is `@frozen` with `@usableFromInline` internals.
- **Checks:** `precondition` on public boundaries; internal invariant checks are compiled in only behind a build flag.
- **Benchmarks:** baselines against BGL and LEMON (C++) and petgraph (Rust).

## Open questions

1. ~~Should `Graph` refine `DirectedGraph`?~~ **Decided: no**, they are separate protocols.
2. ~~Dense `Int` vertices or generic `Vertex: Hashable`?~~ **Decided: generic `Vertex: Hashable`** for representations that can support it (adjacency list, edge list). Matrix and compressed sparse row layouts are inherently index-based; `LabeledGraph` remains the bridge for those.
3. Should weights be stored in representations or always passed in as weight functions?
4. ~~Depend on swift-collections?~~ **Decided: yes**, where its types serve as backing storage (`BitSet` for matrix rows today).
5. Should construction include edge operators such as `-->`?
6. Should the deployment floor be macOS 26 / iOS 26, which `Array.span` requires, or should we support older operating systems with `Span` back-deployment only?
7. `BidirectionalDirectedGraph` is the only name in this document that isn't an established term. Neither graph theory nor the common libraries have a name for "a directed graph that can answer `predecessors(of:)` efficiently," because that's a property of a representation, not of a graph. We could keep the Swift-flavored name, or require `predecessors(of:)` on every `DirectedGraph` and let representations without in-adjacency pay an O(|A|) cost.
