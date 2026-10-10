# Walks: API decisions

Research input for `Sources/Walks`. Every name below is one that JGraphT, NetworkX, LEMON or the
graph-theory texts already use. `ref.py` checks every claim that can be computed (it runs NetworkX
3.7). Case IDs (WK-…) refer to `cases.md`.

## 1. Survey: how libraries model walks

| Library | Representation | Edges stored? | Empty / trivial | Equality | Notes |
|---|---|---|---|---|---|
| **JGraphT** `GraphPath<V,E>` / `GraphWalk<V,E>` | vertex list and/or edge list, plus start, end, weight and graph | Optional. Either list can be `null`; the missing one is derived through `getEdge(u,v)` (an arbitrary edge among parallels) or `getOppositeVertex` | `emptyWalk(g)` (no vertices, `isEmpty()`), `singletonWalk(g, v)` (length 0). `getLength()` counts edges (0 for both) | `equals`: two empty walks are equal. Otherwise it compares start and end, then the vertex lists when `this.edgeList == null` and the *other* graph has no multi-edges, else the edge lists. **Not symmetric, and inconsistent with `hashCode`** (which hashes the edge list when one is present, else the vertex list). No rotation | `verify()` throws `InvalidGraphWalkException`. `reverse()`: undirected graphs reverse both lists; directed graphs look up `getEdge(v,u)` for each arc and throw if one is missing. `concat(ext, weightFn)` requires `end == ext.start` and refuses an empty receiver. The weight is stored, not computed |
| **NetworkX** | node lists everywhere (`shortest_path`, `simple_cycles`, `cycle_basis`, `all_simple_paths`); `find_cycle` returns an **edge list** `(u, v[, key][, direction])` | Only in `find_cycle` (multigraph keys, and `orientation='ignore'` adds `forward`/`reverse`) | `is_path(G, [])` and `is_path(G, [99])` are **True** (pairwise is empty) | none (plain lists). Tests compare cycles with `is_cyclic_permutation` or by edge sets | `is_path` checks a *walk* (repeats allowed). In a multigraph `path_weight` takes the **lightest** parallel edge. `simple_cycles` lists each undirected cycle once **up to rotation and reversal**, each directed cycle once up to rotation; a self-loop is `[v]`; undirected parallel edges are a 2-cycle; parallel *directed* edges do not multiply cycles (WK-512). `find_negative_cycle` returns `[0, 1, 0]`, **repeating the start** |
| **LEMON** `Path`, `SimplePath`, `ListPath`, `StaticPath` | **arcs only** (`addBack`, `addFront`, `nth`, `length`, `front`, `back`). `PathNodeIt` derives the nodes | yes (only arcs) | the empty path has `pathSource == INVALID` | none | `checkPath(g, p)` tests consecutive arcs. "Path" means walk. `PathDumper` is the concept for algorithm outputs that can be copied into a path |
| **Boost** | predecessor maps; no path type | edge predecessor maps, optionally | n/a | n/a | |
| **petgraph** | `Vec<NodeIndex>` (`astar`, `find_negative_cycle`, `all_simple_paths` collected into `Vec`) | no | n/a | `Vec` equality | `toposort` returns `Err(Cycle(node))`, a single node as the witness |
| **igraph** | vertex-id and edge-id vectors: `igraph_get_shortest_path(g, vertices, edges, from, to, mode)` fills **both**; `get_shortest_paths(output="vpath"/"epath")` | yes, when asked | n/a | n/a | |
| **rustworkx** | `PathMapping` of node lists; `find_cycle` returns `EdgeList` | in `find_cycle` | | | |
| **Graphs.jl** | `enumerate_paths` gives `Vector{Int}` of vertices; `a_star` returns `Vector{Edge}` | in `a_star` | | | |

**Definitions** (West, Bondy & Murty, Diestel). A *walk* alternates vertices and edges,
v₀ e₁ v₁ … eₖ vₖ, and its **length k counts edges**. The *trivial* walk has one vertex and length 0.
A *trail* repeats no edge. A *path* repeats no vertex, which implies it repeats no edge. A walk is
*closed* when v₀ = vₖ. West counts the trivial walk as closed; Bondy & Murty require positive length.
A *circuit* is a closed trail of positive length. A *cycle* is a closed trail whose only repeated
vertex is v₀ = vₖ. In a simple graph a cycle has length ≥ 3. In a multigraph a loop is a
1-cycle and two parallel edges form a 2-cycle. In a digraph u→v→u is a 2-cycle. A walk in a
multigraph is **not determined by its vertices**.

## 2. Decisions

### 2.1 The types are generic over `Vertex` and `Edge`, and store both

```swift
@frozen public struct Walk<Vertex: Hashable, Edge: Hashable>
@frozen public struct Trail<Vertex: Hashable, Edge: Hashable>
@frozen public struct Path<Vertex: Hashable, Edge: Hashable>
@frozen public struct Circuit<Vertex: Hashable, Edge: Hashable>
@frozen public struct Cycle<Vertex: Hashable, Edge: Hashable>
```

`Edge` is the graph's `Edges.Index`, the edge position. Grafluent already treats the position as
an edge's identity: weights are `(Edges.Index) -> W`, and `pathEdges(to:)` exists because vertices
cannot tell parallel edges apart.

- **Not vertices only** (the README's `Walk<Vertex>`). Two parallel edges with different weights
  give two different walks over the same vertices. NetworkX's `path_weight` has to guess between
  them (it takes the minimum, WK-901), and JGraphT's derived edge list takes an arbitrary one.
  The README's own weight design (closures over positions) needs the positions.
- **Not `Walk<G: DirectedGraph>`.** That ties a value to one representation, so an `AdjacencyList`
  walk and a `CompressedSparseRow` walk of the same graph would have different types. It cannot
  also cover `Graph` (undirected), and the conformances would be conditional on `G`. `<V, E>` is
  JGraphT's `GraphPath<V, E>` exactly.
- **Not edges only** (LEMON). A trivial walk would have no vertex, and every read would need the
  graph.
- **Undirected graphs need no orientation flag.** The stored vertex sequence orients each edge: the
  edge at step i is crossed from `vertices[i]` to `vertices[i+1]`. So `Walk<V, G.Edges.Index>`
  serves a `Graph` and a `DirectedGraph` alike. A walk of `g.directed` uses
  `DirectedView<G>.Edges.Index` (position and `reversed`), and then u→v→u over one undirected edge
  is a 2-cycle of distinct arcs (WK-605). That is how the existing undirected `findNegativeCycle`
  result types (WK-1206).
- **Storage.** Two arrays, `_vertices: [Vertex]` and `_edges: [Edge]`. For an open walk
  `_vertices.count == _edges.count + 1`. For a circuit or cycle the counts are equal: vertex i
  goes to vertex (i+1) mod n through edge i, and the start is not repeated. That is the convention
  of NetworkX's `simple_cycles`, petgraph's `find_negative_cycle`, and Grafluent's current
  `findCycle` and `findNegativeCycle`. NetworkX's `find_negative_cycle`, which repeats the start,
  is the exception. The struct is 16 bytes. A trivial walk allocates once (its `edges` is the empty
  singleton), and `edges` and `vertices` hand out the stored arrays without copying.

### 2.2 Construction and validation

The invariants come in two kinds.

- **Intrinsic** invariants are part of the type and hold for every value: the counts have the
  right shape, a `Trail` or `Circuit` repeats no edge position, a `Path` or `Cycle` repeats no
  vertex, and a `Circuit` or `Cycle` has length ≥ 1.
- **Graph-relative** validity (edge i joins `vertices[i]` to `vertices[i+1]` in g) cannot live in a
  value that outlives the graph, just as `pathEdges(to:)` positions are "valid until the graph is
  mutated". The checked initializers below test it once.

Each of the five types `T` has the same initializer set:

```swift
// Intrinsic check only. Traps on the wrong count shape (a programmer error); nil when the
// type's invariant fails (a repeated vertex for Path, a repeated edge for Trail, and so on).
public init?(vertices: [Vertex], edges: [Edge])

// Intrinsic check plus graph validity (JGraphT's verify(), LEMON's checkPath). Nil when any
// vertex is not in the graph (checked with contains, so it never traps), when the counts do not
// match, or when an edge does not join its two vertices. Directed: source(ofEdgeAt:) == v[i] and
// target(ofEdgeAt:) == v[i+1]. Undirected: edges[e] == UndirectedEdge(v[i], v[i+1]).
// Precondition: every edge is a position in graph.edges, as for source(ofEdgeAt:).
public init?<G: DirectedGraph>(vertices: [Vertex], edges: [Edge], in graph: G)
    where G.Vertex == Vertex, G.Edges.Index == Edge
public init?<G: Graph>(vertices: [Vertex], edges: [Edge], in graph: G)
    where G.Vertex == Vertex, G.Edges.Index == Edge

// Vertices only (NetworkX style): the edges are picked from outEdges(of:) or incidentEdges(of:)
// order. Walk and Path take the first edge from v[i] to v[i+1]. Trail, Circuit and Cycle take
// the first edge not already used, which finds a trail exactly when one exists (WK-510), whereas
// Trail(Walk(vs, in: g)) can fail where one exists (WK-511). Nil when the sequence is empty, a
// vertex is missing, or no (unused) edge joins a consecutive pair. Circuit and Cycle take the
// cyclic list without a repeated start.
public init?<G: DirectedGraph>(_ vertices: some Sequence<Vertex>, in graph: G)
    where G.Vertex == Vertex, G.Edges.Index == Edge
public init?<G: Graph>(_ vertices: some Sequence<Vertex>, in graph: G)
    where G.Vertex == Vertex, G.Edges.Index == Edge
```

Walk, Trail and Path also get `public init(vertex: Vertex)`, the trivial walk (JGraphT's
`singletonWalk`). There is **no empty walk**. JGraphT's `emptyWalk` only stands in for "no path",
and Swift has `Optional` for that. Every walk has a `source`.

Algorithms build results through `@usableFromInline package init(_uncheckedVertices:edges:)`,
which checks the count shape with a precondition and checks the intrinsic invariant only under the
library's internal-checks build flag (README, Performance notes). `package` access reaches
`ShortestPaths`, `Traversal` and the other modules without adding a public unchecked API. The
precedent is swift-collections' `OrderedSet(uncheckedUniqueElements:)`.

The checked initializer costs O(k) graph reads. The distinctness test costs O(k) expected time
with a `Set<Vertex>` or `Set<Edge>`. When the graph has `vertexIndexBound` or `edgeIndexBound`, it
uses a `[Bool]` keyed by index instead, so no hashing is needed.

### 2.3 Conversions

| From → to | Signature | Failable? |
|---|---|---|
| Path → Trail → Walk; Cycle → Circuit | `Trail(_ path: Path)`, `Walk(_ trail: Trail)`, `Walk(_ path: Path)`, `Circuit(_ cycle: Cycle)` | no. A path repeats no edge in any graph (WK-209) |
| Circuit/Cycle → Walk/Trail | `Walk(_ circuit: Circuit)`, `Walk(_ cycle: Cycle)`, `Trail(_ circuit: Circuit)`, `Trail(_ cycle: Cycle)` | no. The start is appended at the end (O(n) copy) |
| Walk → Trail/Path/Circuit/Cycle; Trail → Path/Circuit/Cycle; Circuit → Cycle | `Trail(_ walk: Walk)`, `Path(_ walk: Walk)`, `Path(_ trail: Trail)`, `Circuit(_ walk: Walk)`, `Circuit(_ trail: Trail)`, `Cycle(_ walk: Walk)`, `Cycle(_ trail: Trail)`, `Cycle(_ circuit: Circuit)` | yes: `init?`. Circuit and Cycle need the walk closed and of length ≥ 1, and they drop the closing vertex |

These are initializers, not properties. That is Swift's convention for value conversions
(`Int(exactly:)`, `Array(set)`). Upward conversions share storage.

### 2.4 Members

```swift
// Walk, Trail, Path (open walks)
extension Walk: RandomAccessCollection {          // Element = Vertex, Index = Int, count = length + 1
    public var startIndex: Int { 0 }
    public var endIndex: Int { _vertices.count }
    public subscript(position: Int) -> Vertex { _vertices[position] }
}
public var vertices: [Vertex] { get }            // the stored array, O(1)
public var edges: [Edge] { get }                 // positions in order; edges[i] joins self[i], self[i+1]
public var length: Int { get }                   // edges.count (JGraphT getLength, LEMON length())
public var source: Vertex { get }                // first vertex (NetworkX, Grafluent's from:to:)
public var target: Vertex { get }                // last vertex
public var isTrivial: Bool { get }               // length == 0
public var isClosed: Bool { get }                // source == target. Walk and Trail only; true when trivial (West)
public func reversed() -> Self                   // vertices and edges reversed (see below)
public func weight<W: AdditiveArithmetic, E: Error>(_ weight: (Edge) throws(E) -> W) throws(E) -> W
// Walk only
public func appending(_ other: Walk) -> Walk     // precondition: target == other.source (JGraphT concat)
public mutating func append(_ other: Walk)

// Circuit, Cycle (closed, count == length >= 1, no repeated start)
extension Cycle: RandomAccessCollection          // Element = Vertex, Index = Int
public var vertices: [Vertex] { get }
public var edges: [Edge] { get }                 // edges[i] joins self[i] and self[(i + 1) % count]
public var length: Int { get }                   // == count
public func reversed() -> Self                   // [v0] + v[1...].reversed(), edges.reversed()
public func weight<W: AdditiveArithmetic, E: Error>(_ weight: (Edge) throws(E) -> W) throws(E) -> W
```

- **Naming.** `source`/`target` matches Grafluent's `DirectedEdge` and its `from source:, to target:`
  labels, and NetworkX's `shortest_path(G, source, target)`. JGraphT's `getStartVertex`/`getEndVertex`
  is the alternative. Neither is optional, because a walk is never empty. A circuit has no
  `source`, since its rotation is not part of its value.
- **`edges` is positions, not `adjacentPairs`.** The README's planned `edges` (a lazy
  `adjacentPairs` view of the vertices) is still available for free as
  `walk.adjacentPairs()` from swift-algorithms, since a walk is a `Collection`. On a circuit it
  leaves out the closing pair. `edges` needs to give positions, because only positions identify
  parallel edges.
- **`reversed()`** has the same name as `BidirectionalCollection.reversed()`. It returns `Self`,
  and its elements are exactly the `ReversedCollection`'s elements, so the two cannot disagree.
  The concrete member wins overload resolution. Over a `Graph` the result is a walk of the same
  graph (JGraphT reverses undirected walks the same way). Over a `DirectedGraph` it is a walk of
  `graph.reversed`, the converse. JGraphT instead swaps each arc for an arbitrary `getEdge(v,u)`,
  which is not well-defined with parallel arcs, so that form is not offered. A walk of
  `g.directed` reversed this way names the original arcs, which point backward in `g.directed`
  (WK-1007). Document it, and keep orientation-flipping for a later `Walk` over `DirectedView`
  if it is ever needed.
- **`weight(_:)`** (NetworkX `path_weight`, JGraphT `getWeight`) adds `weight(e)` from `.zero`, in
  stored edge order, using the edge actually taken, so there is no lightest-parallel guess. Grafluent
  passes weights as closures and never stores them, so the weight is computed and not kept (unlike
  JGraphT's stored weight). The floating-point caveat: equal (rotated) cycles can sum differently
  in the last place (WK-904).
- **Concatenation** is on `Walk` only. Concatenating two paths does not give a path in general,
  and the same holds for trails. `appending(Walk(vertex: w.target))` returns `w` unchanged (JGraphT
  `testConcatPathWithSingleton`).
- **SubSequence** stays the default `Slice<Self>`. A sub-walk API (`walk[i...j]` as a `Walk`) can
  come later if an algorithm needs one.

### 2.5 Equality, hashing, Codable, Sendable, description

- **Walk, Trail, Path:** `==` compares `vertices` and `edges` exactly. `hash(into:)` combines both
  arrays. Rotating a closed `Walk` gives a different `Walk` (WK-712).
- **Circuit, Cycle:** `==` holds **up to rotation** of the (vertex, edge) steps, as the README asks.
  Edges are distinct in a circuit, so at most one rotation offset can match (the one that lines up
  `other.edges[0]`), and equality is O(n), checked against brute force in WK-711. Reflection is
  **not** included. NetworkX treats undirected cycles as equal up to reversal, but these types do
  not know whether their positions are directed or undirected, and for a directed graph a reversed
  cycle is not even a cycle of g. Undirected callers write `a == b || a == b.reversed()`.
  Deduplicating undirected cycles is the job of the enumerating algorithm (`Cycles` emits each one
  once). JGraphT does not include rotation either: `GraphWalk.equals` is exact.
- **Hash for Circuit and Cycle: no canonical rotation.** The README planned to hash a canonical
  rotation, but a rotation chosen by vertex order needs `Comparable`. Instead, `hash(into:)`
  combines `count` and the wrapping sum of one finalized `Hasher` per step `(vertices[i], edges[i])`.
  That is rotation-invariant, O(n), needs no allocation and no `Comparable`, and follows the same
  pattern as `Set`'s commutative hash (WK-701 to WK-711). Nothing is cached, since a cached hash
  would need class storage.
- **Algorithms still emit a deterministic rotation**, so that tests and descriptions are stable:
  start at the vertex that comes first in `vertices` order (the current `findNegativeCycle` rule).
  `first` is not rotation-invariant, as `Set`'s iteration order is not part of its value.
- **Codable** (when `Vertex` and `Edge` are): a keyed container `{"vertices": [...], "edges": [...]}`,
  in the stored rotation for circuits. Decoding re-checks the shape and the intrinsic invariant and
  throws `DecodingError.dataCorrupted` instead of trapping (WK-1104). `DirectedView.Edges.Index` is
  not `Codable`, so walks of a directed view are not `Codable` either. That is acceptable.
- **Sendable** when `Vertex` and `Edge` are. No `BitwiseCopyable`, since the values hold arrays.
- **Description.** `description` writes the vertices as `Array` does, `[0, 1, 2]`, as JGraphT's
  `toString` writes its vertex list, with `GraphDescription.list` and its 16-item limit.
  `debugDescription` adds the type and the positions: `Path(vertices: [0, 1, 2], edges: [3, 5])`.
  A circuit prints without the repeated start.

## 3. Migration of existing APIs

`ShortestPaths` and `Traversal` gain a dependency on `Walks` in `scripts/modules.py`. Nothing
depends on them in the other direction, so no cycle forms.

| Today | New | Notes |
|---|---|---|
| `ShortestPathTree.path(to:) -> [G.Vertex]?` | `-> Path<G.Vertex, G.Edges.Index>?` | Tree paths never repeat a vertex: parent pointers form a forest, also for multi-source Bellman–Ford |
| `ShortestPathTree.pathEdges(to:) -> [G.Edges.Index]?` | **removed**; use `path(to:)?.edges` | |
| `dijkstraShortestPath(from:to:weight:) -> (path: [Vertex], edges: [Edges.Index], distance: W)?` | `-> (path: Path<Vertex, Edges.Index>, distance: W)?` | same for `aStarShortestPath` |
| `Graph.dijkstraShortestPath` / `aStarShortestPath` `(path, edges: [DirectedView<Self>.Edges.Index], distance)` | `-> (path: Path<Vertex, DirectedView<Self>.Edges.Index>, distance: W)?` | stays consistent with `ShortestPathTree<DirectedView<Self>>` |
| `DirectedGraph.findNegativeCycle(...) -> [Vertex]?` (3 overloads) | `-> Cycle<Vertex, Edges.Index>?` | edges from Bellman–Ford's `parentEdge`, which also fixes "between parallel edges the cycle does not say which was taken". Rotation stays: first vertex in `vertices` order |
| `Graph.findNegativeCycle(...) -> [Vertex]?` | `-> Cycle<Vertex, DirectedView<Self>.Edges.Index>?` | `[u, v]` becomes arcs `(p, r)` and `(p, !r)`, a genuine 2-cycle of `g.directed`. A negative self-loop is `[u]` with arc `(p, false)`. Over the undirected graph it would only be a closed walk that repeats an edge (WK-604), so the arc form is the honest type |
| `findCycle() -> [Vertex]?`, `findCycle(from:)` | `-> Cycle<Vertex, Edges.Index>?` | `IndexSpaceSearch` must record the parent edge and the back edge's position (one more `[Edges.Index]` per search, paid only by `findCycle`). The rotation stays at the back edge's target, as today (TR-105) |
| `bidirectionalShortestPath(from:to:) -> [Vertex]?` | `-> Path<Vertex, Edges.Index>?` | both frontiers keep parent edges (out-edges forward, in-edges backward) |
| `isAcyclic`, `topologicalSort()`, `topologicalGenerations()`, `lexicographicalTopologicalSort` | unchanged | orders, not walks |
| successor-function `topologicalSort(from:successors:)`, `breadthFirstSearch`, `iterativeDeepeningDepthFirstSearch -> [Vertex]?` | unchanged `[Vertex]` | no edge identities, and IDDFS asks only `Equatable` |
| `DominatorTree.dominators(of:)`, `strictDominators(of:)` | unchanged `[Vertex]` | a chain in the dominator tree, not a walk of g |
| `breadthFirstLayers`, `Components`, `bridges()`, `articulationPoints()` | unchanged | |
| README Walks table, Cycle handling table (`findCycle() -> [Vertex]?`) | `Walk<Vertex, Edge>` etc.; `findCycle() -> Cycle<Vertex, Edges.Index>?` | |

The existing tests that compare with array literals, for example `findNegativeCycle(...) == [0, 1, 2, 3, 4]`,
migrate to `.map(Array.init) == [0, 1, 2, 3, 4]` or `?.vertices == [...]`. The vertex
sequences, and therefore those expectations, do not change.

## 4. Performance notes

- The layout is two contiguous arrays, and subscripting is inlined direct array access. Upward
  conversions are O(1) and share storage. Circuit → Walk copies once to append the start.
- `path(to:)` builds both arrays backward along the parents and reverses them in place, the same
  cost as today's `path` plus `pathEdges`, which callers previously paid twice.
- Validation is opt-in through the checked initializers. Algorithms use the package unchecked
  initializer, with zero overhead in release builds.
- Circuit and Cycle `==` and `hash` are O(n), with no allocation and no canonical-rotation
  computation, either lazy or eager.
- Benchmark to add: `findNegativeCycle` and `findCycle` with edge recording against today's
  vertex-only versions. The expectation is noise, since the cycle is O(n) at the end of an
  O(VE) or O(V + E) search.
