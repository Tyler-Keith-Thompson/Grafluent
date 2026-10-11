# ImplicitGraphs: proposed API (phase 1)

An implicit graph is given by a successor function instead of stored edges. The repo already
handles the two cases differently, and this design keeps that split. It adds the one missing piece
and duplicates nothing.

| Case | Where it lives | Status |
|---|---|---|
| **Infinite or unbounded state spaces** (puzzles, unbounded grids): no vertex collection exists | Free functions over a successor closure, in the module of the algorithm: `Traversal.breadthFirstSearch(from:depthLimit:successors:)`, `depthFirstSearch(from:depthLimit:successors:)`, `topologicalSort(from:successors:)`, `iterativeDeepeningDepthFirstSearch(from:successors:until:)` (`Sources/Traversal/SuccessorFunctionSearch.swift`) | **Implemented** |
| The weighted searches of the same shape: `dijkstraShortestPath(from:successors:success:)` and `aStarShortestPath(from:successors:heuristic:success:)`, `successors: (V) -> some Sequence<(V, W)>` | `ShortestPaths`, decision D19 (`Tests/Catalogs/ShortestPaths/cases.md`), pathfinding's signatures | **Designed, not implemented**: IG-024 – IG-029 give it values |
| **Finite but unstored** (a bounded grid, a bounded state space numbered `0..<n`): every `DirectedGraph` algorithm should run on it with no edge storage | **`ImplicitDirectedGraph`**, this module (README Representations row) | **This catalog** |

`cases.md` (IG-001 – IG-029, 29 rows) pins the values. `ref.py` ports the type, counts every
closure call, and checks each graph against:

- the `DirectedGraph` laws: `successors`, `outEdges`, `edges`, the counts, `contains(edge:)`, and
  `edges` stepped by `index(after:)`, which must equal `edges` iterated;
- NetworkX 3.7 on the materialized graph: `bfs_layers` from every vertex and shortest path
  lengths.

`--stress` adds 600 random closures with parallel edges and self-loops. It also runs 200 weighted
Dijkstra and A* searches over an unbounded grid, checked against NetworkX on a 51 × 51 box.

To run it:
`uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/ImplicitGraphs/ref.py [--write] [--stress]`.

## Design question: a type, or a new protocol?

**Recommendation: one concrete type, `ImplicitDirectedGraph`, and no new protocol.**

- **Boost's split** is `IncidenceGraph` (out-edges only) versus `VertexListGraph` (adds
  `vertices`). Grafluent's `DirectedGraph` requires `vertices` and `edges`, so it is Boost's
  `VertexListGraph & EdgeListGraph & IncidenceGraph`. A separate "incidence-only" protocol would
  need a second entry point for every algorithm that should accept it. The algorithms worth having
  on an unbounded space are BFS, DFS, IDDFS, topological order, Dijkstra and A*. They already have
  (or are designed with) closure entry points, which is the `pathfinding` crate's shape. A protocol
  would give these six functions a second spelling and nothing new.
- **Traversal's `_SuccessorFunctionGraph`** already shows how to reuse the graph engines: it is an
  internal "conformer" with empty `vertices` and `edges` and `contains` always true. It is
  deliberately *not* lawful, and stays internal. Making it public would publish a type that breaks
  the protocol's laws.
- **What closures cannot do:** run the algorithms that need the whole vertex set (components,
  SCC, centrality, coloring, all-pairs distances, `Distances`, `Covering`) on a graph too large to
  store. A finite implicit graph that is a *lawful* `DirectedGraph` gives all of them for free.
  That is the README's `ImplicitDirectedGraph` row: "a finite vertex collection whose out-neighbors
  are computed by a closure; never stored. Conforms to `DirectedGraph`, with `Sequence`
  neighbors."

## Names

| Name | Decision | Source |
|---|---|---|
| Type | **`ImplicitDirectedGraph<Row>`** (`Row` is the closure's result type; `Successors` is taken by the protocol) (README Representations row; module stub `ImplicitGraphs`) | "implicit graph" is the standard term (Boost's docs on `grid_graph`, "implicit graphs"; LEMON's `FullGraph`/`GridGraph` are implicit; Wikipedia "Implicit graph"). `Directed` matches `DirectedGraph`, `DirectedPseudograph`, `StableDirectedGraph` |
| Initializer | **`init(vertexCount:successors:)`** | `FunctionalGraph.init(vertexCount:successor:)` and `CompressedSparseRow(vertexCount:…)`; `successors:` is Traversal's existing closure label |
| Edge position | **`ImplicitDirectedGraph.Edges.Index`**, with `source`, `rank` and `target` | Nested like `AdjacencyMatrix.Edges.Index(source:target:)`. "rank" is the position within the row (CSR's offset within a row). Boost's `grid_graph` edge descriptor is the pair (source, target); ours adds the rank so parallel edges stay distinct |

## Storage

```swift
@frozen
public struct ImplicitDirectedGraph<Row: Sequence<Int>> {
    @usableFromInline internal let _vertexCount: Int
    @usableFromInline internal let _successors: (Int) -> Row      // never stored results; called on demand
}
```

Vertices are `Int`s `0..<n`, as in `CompressedSparseRow`. A grid is numbered row-major. For
hashable states over a finite set, use `LabeledGraph<State, ImplicitDirectedGraph<…>>`: its
`init(_:labels:)` needs only base vertices `0..<n` in index order, which this type has. The
generic parameter is the closure's result (an `Array`, a lazy filter over a fixed neighbor list,
…), so a specialized build inlines the closure's sequence with no type erasure.

## API

n = vertices, d = the row's length (the closure's result), m = edges. "Call" means one call of the
closure, plus one pass over its sequence.

```swift
extension ImplicitDirectedGraph {
    public init(vertexCount: Int, successors: @escaping (Int) -> Row)   // O(1); calls nothing (IG-002)
}

extension ImplicitDirectedGraph: DirectedGraph {
    public typealias Vertex = Int
    public typealias Vertices = Range<Int>
    public typealias Successors = LazyMapSequence<Row, Int>             // range-checks each element as it is read
    public typealias SuccessorIndices = Successors                       // overrides the hashing default
    public typealias OutEdges = LazyMapSequence<EnumeratedSequence<Row>, Edges.Index>
    public struct Edges: Collection {                                    // Element = DirectedEdge<Int>
        public struct Index: Comparable, Hashable, Sendable {            // ==, <, hash on (source, rank) only
            public let source: Int, rank: Int, target: Int
        }
        // makeIterator(): O(n + m), one call per vertex (IG-007)
        // startIndex: O(rows until the first non-empty one); index(after:): O(d) — re-reads the row (IG-008)
        // subscript: O(1) from the index
    }

    public var vertices: Range<Int>                                      // O(1)
    public var edges: Edges                                              // O(1) to form
    public func successors(of: Int) -> Successors                        // one call (IG-004)
    public func outEdges(of: Int) -> OutEdges                            // one call; positions carry the target (IG-005)
    public func outDegree(of: Int) -> Int                                // one call, O(d)
    public func source(ofEdgeAt: Edges.Index) -> Int                     // O(1), no call (IG-006)
    public func target(ofEdgeAt: Edges.Index) -> Int                     // O(1), no call
    public var vertexCount: Int                                          // O(1)
    public var edgeCount: Int                                            // O(n + m): one call per vertex (IG-007)
    public func contains(_: Int) -> Bool                                 // O(1), no call (IG-010)
    public func contains(edge: DirectedEdge<Int>) -> Bool                // one call, O(d); false off the vertex range with no call
    public var vertexIndexBound: Int?                                    // n
    public var edgeIndexBound: Int?                                      // nil: no dense edge numbering without a pass
    public func vertexIndex(of:) / vertex(atIndex:)                      // identity, range-checked (IG-011)
    public func successorIndices(ofIndex:) / outEdges(ofIndex:)          // one call each
}
```

- **Positions.** `(source, rank)` is unique even with parallel edges and self-loops (IG-009). The
  target travels in the position, so `weight: { $0.target / 4 + 1 }` costs nothing extra (IG-018).
  Equality and hashing ignore the target, which is a function of `(source, rank)` under the
  determinism law.
- **The determinism law.** The closure must return the same sequence each time it is called with
  the same vertex. That is the protocol's "asking again gives the same answer" law, and it is
  documented, not checked. A closure that breaks it breaks every algorithm, as a mutating `==`
  breaks `Set`.
- **Traps:**
  - a negative `vertexCount` (IG-003);
  - a vertex outside `0..<n` (IG-012, IG-013);
  - a successor outside `0..<n`, trapped when that element is read (IG-014, IG-015). The check is
    one compare per edge inside the lazy map, measured below.
- **Not conformed:**
  - `BidirectionalDirectedGraph`, since predecessors would need an inverse closure (phase 2,
    open question 3);
  - `Equatable`, `Hashable` and `Codable`, since closures have no identity;
  - `Sendable`, since the closure is not `@Sendable`. Phase 2 adds a `@Sendable` initializer
    overload if a caller needs it (open question 2).

**Generic algorithms** run unchanged. `vertexIndexBound` is non-nil, so `_DenseVertices` and
`_VertexIdentifiers` take their indexed paths and never hash. Traversal reads
`successorIndices(ofIndex:)`: one call per expanded vertex (IG-016). ShortestPaths'
`_runInIndexSpace` zips `successorIndices(ofIndex:)` with `outEdges(ofIndex:)`, which is **two
calls per settled vertex**. That is a known cost, listed below with its fix.

## Performance targets

| Measure | Target |
|---|---|
| Memory | O(1) for the graph; algorithms keep only their own O(n) per-vertex state |
| `breadthFirstLayers`, 4-neighbor grid 1 000 × 1 000 with a lazy-filter closure | ≤ 1.5× the same call on a `CompressedSparseRow` of the materialized grid; exactly one closure call per discovered vertex |
| `weaklyConnectedComponents` / `stronglyConnectedComponents`, same grid | ≤ 1.5× CSR |
| `dijkstraShortestPaths`, same grid, weight from `Index.target` | ≤ 2× CSR, at two calls per settled vertex. **Phase 2 fix:** an `OutEdges`-only arc source in `_runInIndexSpace` (the target is already in the position), which brings it to one call and ≤ 1.5× |
| The successor range check | ≤ 3% over an unchecked closure, measured in the BFS benchmark; if over, keep it in debug builds only and document the precondition |

## Prior art (checked 2026-10-11)

| Library | What it has | Taken |
|---|---|---|
| Boost.Graph | Concepts `IncidenceGraph` / `VertexListGraph` / `EdgeListGraph`, and `grid_graph<Dimensions>`, an implicit graph with vertices = coordinates and edges = (source, target) | The concept split informs "no new protocol" (above); `grid_graph` is a phase 2 candidate |
| LEMON | `FullGraph`, `GridGraph`, `HypercubeGraph`: implicit structures with O(1) memory, conforming to the full graph concepts | The same choice: implicit *and* a full conformer |
| pathfinding (Rust) | `bfs`, `dfs`, `iddfs`, `dijkstra`, `astar`, `topological_sort` over `successors: FnMut(&N) -> IntoIterator` | Traversal's closure functions; ShortestPaths D19 |
| NetworkX 3.7 | No implicit graphs: every algorithm takes a stored `Graph`. `grid_2d_graph` materializes | The oracle, on the materialized graph |
| petgraph | Visitor traits (`IntoNeighbors`, `NodeCompactIndexable`, …) let users implement the traits on their own implicit type; no ready-made implicit type | Confirms that conformance, not a parallel API, is the reuse mechanism |

## Open questions (with recommendations)

1. **Generic vertices instead of `Int`?** *Recommendation:* `Int` plus `LabeledGraph`, as for CSR
   and `FunctionalGraph`. A generic `ImplicitDirectedGraph<Vertex>` would need either a hashed
   vertex set (that is `LabeledGraph`) or a user-supplied index bijection
   (`index: (V) -> Int, vertex: (Int) -> V`). Grid users write exactly that bijection, so it is a
   reasonable **phase 2** initializer, `init(vertices:indexOf:successors:)`, if a second user asks.
2. **`Sendable`.** *Recommendation:* phase 2 adds `init(vertexCount:successors: @escaping
   @Sendable (Int) -> Row)` and a conditional conformance through a stored `@Sendable` closure
   type parameter. This is not needed until an algorithm crosses isolation on one.
3. **Undirected and bidirectional implicit graphs.** *Recommendation:* phase 2.
   - `ImplicitGraph` conforming to `Graph` needs the incidence law (each edge listed from both ends
     with one position). A closure cannot promise that cheaply: the position would have to be
     normalized as (min, max, rank among parallels).
   - Until then, a symmetric closure on `ImplicitDirectedGraph` covers traversal and shortest
     paths.
   - `predecessors:` as a second closure gives `BidirectionalDirectedGraph`. Its law (predecessors
     mirror successors) would be documented, not checked.
4. **Grid graphs.** Boost's `grid_graph` and LEMON's `GridGraph` are the canonical implicit
   graphs. *Recommendation:* phase 2, as a `GridGraph` in this module with coordinates, optional
   wrapping per dimension (Boost), and an `Int` numbering. It would conform to `Graph` directly,
   with positions defined by (cell, direction), so it avoids question 3's problem.
   `NamedGraphs`' materialized grids stay as they are.
5. **D19 belongs in `ShortestPaths`, not here.** IG-024 – IG-029 are design input for its catalog:
   distances, and vertex counts where every shortest path has the same count. They are checked
   against NetworkX on a bounded box. Tie-breaking between equal paths is ShortestPaths' rule to
   set.

## Phases

- **Phase 1 (this catalog):** `ImplicitDirectedGraph` with its lawful `DirectedGraph` conformance
  and its range-checked lazy rows.
- **Alongside, in `ShortestPaths`:** D19's two closure functions (IG-024 – IG-029).
- **Phase 2:**
  - the one-call arc source in `_runInIndexSpace`;
  - the `@Sendable` initializer;
  - `init(vertices:indexOf:successors:)`;
  - `predecessors:` (bidirectional);
  - `GridGraph` (Boost `grid_graph`, LEMON `GridGraph`);
  - an undirected `ImplicitGraph`, if a caller needs one beyond `GridGraph`.
