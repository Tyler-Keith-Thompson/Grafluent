# Walks: API

The API that `cases.md` tests. `ref.py` checks every case that can be computed, against NetworkX
3.7 where it has an answer and against brute force otherwise. Case IDs (WK-…) refer to `cases.md`.

## Definitions

A *walk* alternates vertices and edges, v₀ e₁ v₁ … eₖ vₖ, and its length k counts edges. The
*trivial* walk has one vertex and length 0. A *trail* repeats no edge. A *path* repeats no vertex,
and so repeats no edge. A walk is *closed* when v₀ = vₖ; the trivial walk is closed. A *circuit* is
a closed trail of positive length. A *cycle* is a closed trail whose only repeated vertex is
v₀ = vₖ. In a multigraph a loop is a 1-cycle and two parallel edges form a 2-cycle. In a digraph
u→v→u is a 2-cycle. A walk in a multigraph is not determined by its vertices.

## 1. Types and storage

```swift
@frozen public struct Walk<Vertex: Hashable, Edge: Hashable>
@frozen public struct Trail<Vertex: Hashable, Edge: Hashable>
@frozen public struct Path<Vertex: Hashable, Edge: Hashable>
@frozen public struct Circuit<Vertex: Hashable, Edge: Hashable>
@frozen public struct Cycle<Vertex: Hashable, Edge: Hashable>
```

`Edge` is the graph's `Edges.Index`, the edge position. Positions tell parallel edges apart, so two
walks over the same vertices through different parallel edges are different values.

- Each type stores two arrays, `_vertices` and `_edges`. An open walk (Walk, Trail, Path) has
  `_vertices.count == _edges.count + 1`. A circuit or cycle has equal counts: vertex i goes to
  vertex (i + 1) mod n through edge i, and the start is not repeated.
- Over an undirected graph the vertex sequence orients each edge: the edge at step i is crossed
  from `vertices[i]` to `vertices[i + 1]`. A walk of `g.directedView` uses
  `DirectedView<G>.Edges.Index` (position and `reversed`), and u→v→u over one undirected edge is
  then a 2-cycle of distinct arcs (WK-605).

## 2. Construction and validation

Intrinsic invariants hold for every value: the counts have the right shape, a `Trail` or `Circuit`
repeats no edge position, a `Path` or `Cycle` repeats no vertex, and a `Circuit` or `Cycle` has
length ≥ 1. Validity in a graph (edge i joins `vertices[i]` to `vertices[i + 1]`) is checked once,
by the initializers that take the graph, and lasts until the graph is mutated.

```swift
// Intrinsic check only. Traps on the wrong count shape; nil when the type's invariant fails.
// Walk's version is not failable, since a walk's only rule is its shape.
public init?(vertices: [Vertex], edges: [Edge])

// Intrinsic check plus validity in `graph`. Nil when a vertex is not in the graph (checked with
// contains, so it never traps), the counts have the wrong shape, an edge position is outside
// graph.edges, or an edge does not join its two vertices. Directed: source(ofEdgeAt:) == v[i] and
// target(ofEdgeAt:) == v[i+1]. Undirected: edges[e] == UndirectedEdge(v[i], v[i+1]).
public init?<G: DirectedGraph>(vertices: [Vertex], edges: [Edge], in graph: G)
    where G.Vertex == Vertex, G.Edges.Index == Edge
public init?<G: Graph>(vertices: [Vertex], edges: [Edge], in graph: G)
    where G.Vertex == Vertex, G.Edges.Index == Edge

// Vertices only: edges are picked in outEdges(of:) or incidentEdges(of:) order. Walk and Path
// take the first edge from v[i] to v[i+1]. Trail, Circuit and Cycle take the first edge not
// already used, which finds a trail exactly when one exists (WK-510); Trail(Walk(vs, in: g)) can
// fail where one exists (WK-511). Nil when the sequence is empty, a vertex is missing, or no
// (unused) edge joins a consecutive pair. Circuit and Cycle take the cyclic list without a
// repeated start.
public init?<G: DirectedGraph>(_ vertices: some Sequence<Vertex>, in graph: G)
    where G.Vertex == Vertex, G.Edges.Index == Edge
public init?<G: Graph>(_ vertices: some Sequence<Vertex>, in graph: G)
    where G.Vertex == Vertex, G.Edges.Index == Edge
```

Walk, Trail and Path also have `init(vertex:)`, the trivial walk. There is no empty walk; a missing
walk is `nil`.

Algorithms in other modules build results with `package init(_uncheckedVertices:edges:)`, which
checks the count shape with a precondition and trusts the rest.

## 3. Conversions

| From → to | Signature | Failable? |
|---|---|---|
| Path → Trail → Walk; Cycle → Circuit | `Trail(_ path: Path)`, `Walk(_ trail: Trail)`, `Walk(_ path: Path)`, `Circuit(_ cycle: Cycle)` | no. A path repeats no edge (WK-209) |
| Circuit/Cycle → Walk/Trail | `Walk(_ circuit: Circuit)`, `Walk(_ cycle: Cycle)`, `Trail(_ circuit: Circuit)`, `Trail(_ cycle: Cycle)` | no. The start is appended at the end (O(n) copy) |
| Walk → Trail/Path/Circuit/Cycle; Trail → Path/Circuit/Cycle; Circuit → Cycle | `Trail(_ walk: Walk)`, `Path(_ walk: Walk)`, `Path(_ trail: Trail)`, `Circuit(_ walk: Walk)`, `Circuit(_ trail: Trail)`, `Cycle(_ walk: Walk)`, `Cycle(_ trail: Trail)`, `Cycle(_ circuit: Circuit)` | yes. Circuit and Cycle need the walk closed and of length ≥ 1, and drop the closing vertex |

Conversions that cannot fail and keep the vertex count share storage.

## 4. Members

```swift
// Walk, Trail, Path (open walks)
extension Walk: RandomAccessCollection {          // Element = Vertex, Index = Int, count = length + 1
    public var startIndex: Int { 0 }
    public var endIndex: Int { _vertices.count }
    public subscript(position: Int) -> Vertex { _vertices[position] }
}
public var vertices: [Vertex] { get }            // the stored array, O(1)
public var edges: [Edge] { get }                 // positions in order; edges[i] joins self[i], self[i+1]
public var length: Int { get }                   // edges.count
public var source: Vertex { get }                // first vertex
public var target: Vertex { get }                // last vertex
public var isTrivial: Bool { get }               // length == 0
public var isClosed: Bool { get }                // source == target. Walk and Trail only; true when trivial
public func reversed() -> Self                   // vertices and edges reversed (see below)
public func weight<W: AdditiveArithmetic, E: Error>(_ weight: (Edge) throws(E) -> W) throws(E) -> W
// Walk only
public func appending(_ other: Walk) -> Walk     // precondition: target == other.source
public mutating func append(_ other: Walk)

// Circuit, Cycle (closed, count == length >= 1, no repeated start)
extension Cycle: RandomAccessCollection          // Element = Vertex, Index = Int
public var vertices: [Vertex] { get }
public var edges: [Edge] { get }                 // edges[i] joins self[i] and self[(i + 1) % count]
public var length: Int { get }                   // == count
public func reversed() -> Self                   // [v0] + v[1...].reversed(), edges.reversed()
public func weight<W: AdditiveArithmetic, E: Error>(_ weight: (Edge) throws(E) -> W) throws(E) -> W
```

- A circuit has no `source`, since its rotation is not part of its value.
- `edges` gives positions. The consecutive vertex pairs are `zip(w, w.dropFirst())`; on a circuit
  that leaves out the closing pair.
- `reversed()` returns `Self`, with the same elements as `BidirectionalCollection.reversed()`.
  Over a `Graph` the result is a walk of the same graph. Over a `DirectedGraph` it is a walk of the
  converse graph, each edge keeping its position. A walk of `g.directedView` reversed this way names
  the original arcs, which point backward in `g.directedView` (WK-1007).
- `weight(_:)` adds `weight(e)` from `.zero` in stored edge order, over the edges actually taken.
  Equal (rotated) floating-point cycles can sum differently in the last place (WK-904).
- Concatenation is on `Walk` only, since joining two paths or two trails need not give one.
  `appending(Walk(vertex: w.target))` returns `w` unchanged.
- `SubSequence` is the default `Slice<Self>`.

## 5. Equality, hashing, Codable, Sendable, description

- **Walk, Trail, Path.** `==` compares `vertices` and `edges` exactly, and `hash(into:)` combines
  both arrays. Rotating a closed `Walk` gives a different `Walk` (WK-712).
- **Circuit.** `==` holds up to rotation of the (vertex, edge) steps, not reflection. Edges are
  distinct in a circuit, so only the rotation that lines up `other.edges[0]` can match, and
  equality is O(n) (checked against brute force in WK-711). Undirected callers who want reflection
  write `a == b || a == b.reversed()`.
- **Cycle.** `==` holds up to rotation and reversal: `a == b` when `a` is a rotation of `b` or of
  `b.reversed()`, so the two directions around an undirected cycle are one value (WK-602, WK-607,
  WK-702). A directed cycle's reversal is a cycle of the converse graph, never of the graph itself,
  so two cycles of one directed graph are equal only up to rotation. Still O(n): the reversal is
  compared in place, by the one offset that lines up an edge (WK-711).
- **Hash for Circuit and Cycle.** `hash(into:)` combines `count` and the wrapping sum of one
  finalized `Hasher` per edge position. It is invariant under rotation and reversal, O(n),
  allocation-free and needs no `Comparable` (WK-701 to WK-711).
- **Rotation of results.** Algorithms emit a deterministic rotation, starting at the vertex that
  comes first in `vertices` order. `first` is not rotation-invariant.
- **Codable** (when `Vertex` and `Edge` are): a keyed container `{"vertices": [...], "edges": [...]}`,
  in the stored rotation for circuits. Decoding re-checks the shape and the intrinsic invariant and
  throws `DecodingError.dataCorrupted` instead of trapping (WK-1104).
- **Sendable** when `Vertex` and `Edge` are.
- **Description.** `description` writes the vertices as `Array` does, `[0, 1, 2]`, through
  `GraphDescription.list` with its 16-item limit. `debugDescription` adds the type and the
  positions: `Path(vertices: [0, 1, 2], edges: [3, 5])`. A circuit prints without the repeated
  start.

## 6. Results of other modules

`ShortestPaths` and `Traversal` return these types. Their suites test them (WK-12xx).

| API | Returns |
|---|---|
| `ShortestPathTree.path(to:)` | `Path<G.Vertex, G.Edges.Index>?`; edges are `path(to:)?.edges` |
| `dijkstraShortestPath(from:to:weight:)`, `aStarShortestPath` | `(path: Path<Vertex, Edges.Index>, distance: W)?` |
| `Graph.dijkstraShortestPath`, `Graph.aStarShortestPath` | `(path: Path<Vertex, DirectedView<Self>.Edges.Index>, distance: W)?` |
| `DirectedGraph.findNegativeCycle(...)` | `Cycle<Vertex, Edges.Index>?`, edges from Bellman–Ford's parent edges, starting at the first vertex in `vertices` order |
| `Graph.findNegativeCycle(...)` | `Cycle<Vertex, DirectedView<Self>.Edges.Index>?`. A negative edge {u, v} is the 2-cycle of arcs `(p, r)` and `(p, !r)`; a negative self-loop is `[u]` with arc `(p, false)` |
| `findCycle()`, `findCycle(from:)` | `Cycle<Vertex, Edges.Index>?`, starting at the back edge's target (TR-105) |
| `bidirectionalShortestPath(from:to:)` | `Path<Vertex, Edges.Index>?` |

Orders and successor-function searches (`topologicalSort`, `breadthFirstSearch`,
`iterativeDeepeningDepthFirstSearch`) and dominator chains return `[Vertex]`.
