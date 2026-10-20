# Cycles API

Finding, enumerating and measuring cycles. `DirectedGraph.findCycle()`, `findCycle(from:)`,
`isAcyclic` and `topologicalSort()` are in Traversal; this module adds the undirected
counterparts, enumeration (simple and chordless cycles), girth, Karp's minimum mean cycle and a
feedback arc set heuristic.

## Public API

```swift
import GraphProtocols
import Walks

extension Graph {
    /// Whether the graph has no cycle; a self-loop and a pair of parallel edges are cycles.
    var isAcyclic: Bool { get }

    /// The cycle closed by the first edge of a depth-first search that leads back to a vertex on
    /// the search path, in canonical form; nil when acyclic.
    func findCycle() -> Cycle<Vertex, Edges.Index>?
    /// The same, searching only from `roots`, in order. Precondition: every root is a vertex.
    func findCycle(from roots: some Sequence<Vertex>) -> Cycle<Vertex, Edges.Index>?

    /// The fundamental cycles of the breadth-first spanning forest: one per non-tree edge, in
    /// ascending position, canonical. m − n + c cycles.
    func cycleBasis() -> [Cycle<Vertex, Edges.Index>]
    func minimumCycleBasis() -> [Cycle<Vertex, Edges.Index>]
    func minimumCycleBasis<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> [Cycle<Vertex, Edges.Index>]

    /// Every simple cycle once, lazily, canonical, in the documented order.
    /// Precondition: maxLength >= 0.
    func simpleCycles(maxLength: Int = .max) -> UndirectedSimpleCycles<Self>

    /// Every chordless (induced) cycle once, lazily, canonical as simpleCycles lists it, in the
    /// same order: simpleCycles(maxLength:) filtered to the cycles whose vertices induce no other
    /// edge. Precondition: maxLength >= 0.
    func chordlessCycles(maxLength: Int = .max) -> UndirectedChordlessCycles<Self>

    /// The length of a shortest cycle (1 with a self-loop, 2 with parallel edges); nil when acyclic.
    func girth() -> Int?
}

extension DirectedGraph {
    func simpleCycles(maxLength: Int = .max) -> DirectedSimpleCycles<Self>
    func chordlessCycles(maxLength: Int = .max) -> DirectedChordlessCycles<Self>
    /// Karp: a cycle of least mean weight, from its least vertex; nil when acyclic. O(n·m) time,
    /// O(n·√n + m) memory; means compared by cross-multiplying.
    func minimumMeanCycle<W: SignedNumeric & Comparable>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
    func girth() -> Int?
    /// Eades–Lin–Smyth's greedy feedback arc set, ascending positions, every self-loop included.
    func feedbackArcSet() -> [Edges.Index]
    func feedbackArcSet(weight: (Edges.Index) -> Double) -> [Edges.Index]
    /// Exact minimum sets by dynamic programming over vertex subsets: at most 28 (arcs) or 32 vertices.
    func minimumFeedbackArcSet() -> [Edges.Index]
    func minimumFeedbackArcSet(weight: (Edges.Index) -> Double) -> [Edges.Index]
    func minimumFeedbackVertexSet() -> [Vertex]      // also on Graph: the fewest vertices leaving a forest
}

@frozen public struct DirectedSimpleCycles<G: DirectedGraph>: Sequence {
    public typealias Element = Cycle<G.Vertex, G.Edges.Index>
    public let maxLength: Int
    public func makeIterator() -> Iterator
    @frozen public struct Iterator: IteratorProtocol { public mutating func next() -> Element? }
}
@frozen public struct UndirectedSimpleCycles<G: Graph>: Sequence { /* the same shape */ }
@frozen public struct DirectedChordlessCycles<G: DirectedGraph>: Sequence { /* the same shape */ }
@frozen public struct UndirectedChordlessCycles<G: Graph>: Sequence { /* the same shape */ }
// Sendable when G is; the iterators when G, G.Vertex and G.Edges.Index are. Neither sequence is a
// Collection.
```

## Result types

- `Cycle<Vertex, Edges.Index>` (Walks) everywhere: vertices plus edge positions, so parallel edges
  are told apart. Equality is up to rotation and reversal; the module emits every undirected cycle
  once, in one orientation, so equal cycles have equal `vertices` and `edges`.
- `[Cycle]` for `cycleBasis()`.
- Lazy sequences for `simpleCycles`: their number is exponential (K₁₃ has 710 771 275), so `first`,
  `prefix(k)` and early `break` do not pay for the rest. Each `makeIterator()` starts over from the
  stored graph (a value), so iterating twice gives the same cycles (CY-763), and mutating the
  original graph afterwards changes nothing (CY-853). `underestimatedCount` is 0.
- `Int?` for `girth()`: `nil` for an acyclic graph.

## Semantics

### What a cycle is

A closed path: no vertex and no edge position twice (Walks' `Cycle`). §E of the catalog pins the
consequences:

| Graph | Cycles |
|---|---|
| A self-loop | one 1-cycle per loop edge, though an undirected row lists it twice |
| k parallel undirected edges u–v | C(k, 2) 2-cycles (CY-403) |
| One undirected edge | no cycle: the walk u–v–u reuses the edge (CY-005) |
| Opposite arcs u→v, v→u | one 2-cycle (CY-203) |
| Parallel arcs, other cycles through them | one cycle per choice of copy (CY-238, CY-243) |

### Canonical form

Every undirected cycle the module returns starts at its least vertex (the first in `vertices`
order, which is index order when the graph has vertex indices) and leaves it through the lesser
of its two edges there, by position. A directed cycle starts at its least vertex too. So:

- each undirected cycle has exactly one representation;
- a 2-cycle over copies e₁ < e₂ is `[u, v] / [e₁, e₂]` with u before v in `vertices` (CY-402,
  CY-407);
- a 1-cycle is `[v] / [e]`.

### `findCycle()` (undirected)

A depth-first search with roots in `vertices` order (or `roots`, in their order, skipping roots
already reached), scanning each vertex's `incidentEdges` in order, never going back along the edge
it arrived by (not the vertex it came from), stops at the first edge e from v to a vertex w still
on the search path (w = v for a loop). The cycle is the tree path from w to v plus e, returned in
canonical form. Skipping the parent edge rather than the parent vertex finds a parallel pair
(CY-008, CY-024). Which cycle is found depends on incidence order (CY-025, CY-026); its form does
not.

`findCycle(from:)` searches only the roots' components and traps on a root that is not a vertex.
`findCycle()` is `nil` exactly when `isAcyclic`.

### `isAcyclic` (undirected)

`edgeCount >= max(vertexCount, 1)` answers `false` at once. Otherwise a union–find over the rows
joins each edge's ends the first time a row lists it and stops at the first edge whose ends are
already joined, a self-loop included. Equivalent to `findCycle() == nil` and to
`edgeCount == vertexCount − components` (CY-756). The empty graph is acyclic.

`Graph.isAcyclic` and Traversal's `DirectedGraph.isAcyclic` never meet: no type conforms to both
protocols. On the views, `g.directedView.isAcyclic` is false as soon as g has an edge (every edge
is two opposite arcs), and `digraph.undirectedView.isAcyclic` is the polytree test (CY-039).

### `cycleBasis()`

The fundamental cycles of the breadth-first spanning forest: roots in `vertices` order, each
vertex's `incidentEdges` scanned in order, the tree edge of a vertex the edge that discovered it.
Every other edge (loops and parallel copies included) is a non-tree edge and gives one cycle: the
edge plus the tree path between its ends, in canonical form. Cycles are in ascending position of
their non-tree edge. There are m − n + c of them, they are independent over GF(2), and each
contains exactly one non-tree edge, its own (CY-757). Multigraphs and loops are supported.

### `minimumCycleBasis()`, `minimumCycleBasis(weight:)`

De Pina's algorithm: the supports start as the unit vectors of the edges outside the breadth-first
forest; for each support in turn, the lightest cycle with an odd overlap with it joins the basis (the
lightest closed walk from (u, 0) to (u, 1) in the graph lifted to two copies of each vertex, an
edge of the support crossing between them, over the ends u of the support's edges), and every later
support with an odd overlap with that cycle takes the symmetric difference with the chosen support.
m − n + c cycles, independent over GF(2), of the least total length (or weight, each weight finite
and greater than zero), canonical, in nondecreasing weight, then length, then edge positions.
Loops and parallel copies give 1- and 2-cycles.

### `simpleCycles(maxLength:)`

Order: by least vertex s, in `vertices` order; among the cycles whose least vertex is s,
lexicographically by the offset of each edge in its vertex's row (`outEdges(of:)` or
`incidentEdges(of:)`), taken along the canonical orientation. That is the order a plain
depth-first enumeration from s meets them. Row order matters (CY-248, CY-331): on a representation
whose rows are not in position order (`UndirectedAdjacencyList` after removals) the set is the same
and the order follows the rows.

Bound: `maxLength` counts edges: 0 gives nothing, 1 the loops, 2 adds 2-cycles.
`simpleCycles(maxLength: k)` is the unbounded sequence filtered to `length <= k`, in the same order
(CY-753). A negative bound traps.

Algorithm: Johnson (1975) unbounded, Gupta–Suzumura (2021) bounded, iterative, in rounds over
pieces: the strong components (directed) or blocks (undirected) that can hold a cycle, plus,
undirected, a piece for each vertex with a self-loop. Round s searches from s inside the pieces
that contain it, never visiting a vertex below s. Unbounded, a round then removes s and
decomposes only those pieces again, so a round costs the size of its pieces; bounded, the pieces
are decomposed once.

Undirected, the search walks each edge as two arcs; an arc back to s along the edge just taken is
not a cycle; each cycle of length ≥ 2 is met in both orientations and emitted in the canonical
one; a loop at s is met twice in its row and emitted once. Both kinds of closure that are not
emitted still count as reaching s for unblocking. In the bounded search this matters: without it
a vertex stays locked and a later cycle is missed (CY-491).

Complexity: the first `next()` copies the rows, O(n + m). Unbounded, O((n + m)(c + 1)) time for
c cycles, O(n + m) memory. Bounded by k, O((c + n)·k·d^k) for average degree d.

### `girth()`

The least `length` of a cycle: 1 with a loop, 2 with a parallel pair (undirected) or opposite arcs
(directed); `nil` when acyclic. Only vertices that can be on a cycle are searched: undirected, the
2-core; directed, the strong components with two or more vertices. Undirected: breadth-first
search from every vertex, skipping the edge each vertex was reached by, a non-tree edge (u, w)
giving depth(u) + depth(w) + 1, stopping a search once its depth cannot beat the best so far.
Directed: breadth-first search from every vertex until it returns to its root. O(n·m) time,
O(n + m) memory.

### `feedbackArcSet()`

Eades, Lin and Smyth's greedy heuristic: a feedback arc set, small in practice but not minimum, as
ascending positions. Every self-loop is in it. Removing the returned edges leaves no directed
cycle; on an acyclic graph the result is empty. The weighted form compares weighted out-degree
minus weighted in-degree; every weight must be finite. O((n + m) log n) time.

### `minimumFeedbackArcSet()`, `minimumFeedbackVertexSet()`

Exact minimum sets. The arc set orders the vertices to minimize the arcs pointing leftward, by
dynamic programming over the vertex subsets (Θ(2ⁿ · m) time, 2ⁿ entries of 9 bytes: at most 28
vertices); every self-loop is in it, and the weighted form minimizes the total weight, every
weight finite and at least zero. The vertex set marks every subset inducing an acyclic subgraph
(directed) or a forest (undirected) by peeling sources, or vertices of degree at most one, and
takes the largest, with the complement listing first by `vertices` offsets on ties (Θ(2ⁿ · n)
time, 2ⁿ bytes: at most 32 vertices). A vertex with a self-loop, or one end of parallel undirected
edges, is always in it.

## Index space

- Undirected algorithms run on the graph's incidence rows (`_runOnUndirectedRows`), so nothing is
  hashed on an indexed `UndirectedAdjacencyList` (CY-857).
- The lazy iterators copy the rows into flat arrays on the first `next()` (offsets, neighbour
  numbers, edge numbers) and keep each edge number's position to build each `Cycle`. Edge numbers
  order like positions, so "lesser edge" compares numbers.
- Searches keep explicit stacks; nothing recurses (CY-803 and CY-804 search 10⁵ deep).
