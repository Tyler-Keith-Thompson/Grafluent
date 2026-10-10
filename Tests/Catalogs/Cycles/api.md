# Cycles: proposed API (phase 1)

## Scope

**In, phase 1**

| Entry point | On | Why now |
|---|---|---|
| `isAcyclic` | `Graph` | Every library has it (petgraph `is_cyclic_undirected`, LEMON `acyclic`, igraph `is_acyclic`/`is_forest`, NetworkX/JGraphT `is_forest`). `DirectedGraph.isAcyclic` is in Traversal already |
| `findCycle()`, `findCycle(from:)` | `Graph` | The witness behind `isAcyclic`. The README promises it (it calls it `cycle()`). NetworkX `find_cycle`, igraph `find_cycle`, rustworkx `find_cycle` |
| `cycleBasis()` | `Graph` | NetworkX/rustworkx `cycle_basis`, igraph `fundamental_cycles`, JGraphT `CycleBasisAlgorithm`. Linear time; the classic use is Kirchhoff's laws |
| `simpleCycles(maxLength:)` | `DirectedGraph` and `Graph` | NetworkX/rustworkx/igraph `simple_cycles`, JGraphT's five `*SimpleCycles`, Boost `hawick_circuits`. Lazy, with an optional length bound (NetworkX `length_bound`, igraph `max_cycle_length`, Boost `max_length`, JGraphT `setPathLimit`) |
| `girth()` | `Graph` and `DirectedGraph` | NetworkX `girth`, JGraphT `GraphMetrics.getGirth` (both kinds), igraph `girth`, Boost `tiernan_girth_and_circumference` |

**Out, and where it goes**

| Not in phase 1 | Reason |
|---|---|
| `minimumCycleBasis(weight:)` (Horton, de Pina, Kavitha et al.) | Phase 2. Needs weights and shortest paths (a ShortestPaths dependency) and a GF(2) linear-algebra kernel; only NetworkX and igraph have it. Cases CY-150 – CY-156 are already checked |
| `chordlessCycles(maxLength:)` | Phase 2. Only NetworkX has it, its multigraph rules are its own (a loop is chordless unless doubled, a parallel pair unless tripled), and Dias et al. is a separate search. Cases CY-600 – CY-607 are checked on simple graphs |
| NetworkX `find_cycle(orientation=)` | Views cover it: `g.undirected.findCycle()` (a bidirectional digraph) is `"ignore"` (CY-015); `"reverse"` finds the same cycles as `"original"`, reversed, and will be `g.reversed.findCycle()` once GraphOperations' `reversed` view exists |
| A directed cycle basis | JGraphT computes an *undirected* basis of a digraph; that is `digraph.undirected.cycleBasis()` |
| `minCycleLength` (igraph `min_cycle_length`) | `simpleCycles().lazy.filter { $0.length >= k }`; unlike the upper bound it does not prune the search |
| `max_results` (igraph) | `simpleCycles().prefix(k)`: the sequence is lazy |
| Tiernan, Tarjan, Szwarcfiter–Lauer, Hawick–James as separate types (JGraphT) | They enumerate the same set; one algorithm, the best one, behind one name |
| NetworkX `recursive_simple_cycles` | Recursive and eager; same result |
| A witness for girth (igraph returns the shortest cycle) | Phase 2 if asked for; no established name (`shortestCycle()` would be ours) |
| `isForest`, `isTree` | Belong with `Forest`/`Tree` in Trees; there `isForest` is `isAcyclic` and `isTree` adds `isConnected`. One name per concept here |
| Negative cycles | ShortestPaths (`findNegativeCycle`), as now |
| Cycles of a `FunctionalGraph` (Floyd, Brent) | FunctionalGraphs, as the README says |
| Feedback arc / vertex sets (igraph) | NP-hard optimisation; not cycle enumeration |

## Summary

```swift
import GraphProtocols
import Walks

extension Graph {
    /// Whether the graph has no cycle; a self-loop and a pair of parallel edges are cycles.
    var isAcyclic: Bool { get }                                              // O(n + m); O(1) when m >= max(n, 1)

    /// The cycle closed by the first edge of a depth-first search that leads back to a vertex on
    /// the search path, in canonical form; nil when acyclic.
    func findCycle() -> Cycle<Vertex, Edges.Index>?
    /// The same, searching only from `roots`, in order.  Precondition: every root is a vertex.
    func findCycle(from roots: some Sequence<Vertex>) -> Cycle<Vertex, Edges.Index>?

    /// The fundamental cycles of the breadth-first spanning forest: one per non-tree edge, in
    /// ascending position, canonical. m − n + c cycles.
    func cycleBasis() -> [Cycle<Vertex, Edges.Index>]

    /// Every simple cycle once, lazily, canonical, in the documented order.
    /// Precondition: maxLength >= 0.
    func simpleCycles(maxLength: Int = .max) -> UndirectedSimpleCycles<Self>

    /// The length of a shortest cycle (1 with a self-loop, 2 with parallel edges); nil when acyclic.
    func girth() -> Int?
}

extension DirectedGraph {
    func simpleCycles(maxLength: Int = .max) -> DirectedSimpleCycles<Self>
    func girth() -> Int?
    // findCycle(), findCycle(from:), isAcyclic, topologicalSort(): Traversal, unchanged
}

@frozen public struct DirectedSimpleCycles<G: DirectedGraph>: Sequence {
    public typealias Element = Cycle<G.Vertex, G.Edges.Index>
    public let maxLength: Int
    public func makeIterator() -> Iterator
    @frozen public struct Iterator: IteratorProtocol { public mutating func next() -> Element? }
}
@frozen public struct UndirectedSimpleCycles<G: Graph>: Sequence { /* the same shape */ }

extension DirectedSimpleCycles: Sendable where G: Sendable {}
extension UndirectedSimpleCycles: Sendable where G: Sendable {}
// The iterators are Sendable under the same conditions. Neither sequence is a Collection.
```

`Cycle`'s `Sendable` conformance needs `Vertex: Sendable` and `Edge: Sendable`; a `Sendable` graph
of `Sendable` vertices satisfies both for every representation in the package.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `isAcyclic` (on `Graph`) | igraph `igraph_is_acyclic` (one name for both kinds), LEMON `acyclic(Graph)`, petgraph `is_cyclic_undirected` (negated), and Traversal's `DirectedGraph.isAcyclic` | `isForest` (NetworkX, JGraphT, igraph): the same predicate under a structural name; it goes with `Forest` in Trees. `hasCycle`: no library |
| `findCycle()`, `findCycle(from:)` | NetworkX `find_cycle(G, source)`, igraph `igraph_find_cycle`, rustworkx `find_cycle`/`digraph_find_cycle`, Traversal's directed `findCycle` | The README's `cycle()`: no library uses it, and it reads as a property of the graph |
| `cycleBasis()` | NetworkX and rustworkx `cycle_basis`, JGraphT `CycleBasisAlgorithm.getCycleBasis` | igraph `fundamental_cycles` (precise but less familiar; the documentation says "fundamental") |
| `simpleCycles(maxLength:)` | NetworkX/rustworkx/igraph `simple_cycles`, JGraphT `findSimpleCycles`; `maxLength` as Boost `max_length`, igraph `max_cycle_length`, Swift's `split(maxSplits:)` | "elementary circuits" (Johnson's title; Boost `hawick_circuits`): the README's module row should say "simple cycles (elementary circuits)". `lengthBound` (NetworkX only) |
| `DirectedSimpleCycles`, `UndirectedSimpleCycles` | JGraphT's interface `DirectedSimpleCycles`; the `Directed`/`Undirected` pair of `DirectedEdge`/`UndirectedEdge`, `DirectedView`/`UndirectedView` | One `SimpleCycles<G>` cannot be generic over two unrelated protocols |
| `girth()` | NetworkX `girth`, JGraphT `getGirth`, igraph `girth`, Boost `tiernan_girth_and_circumference` | `girth` as a property: it costs O(n·m) |

## Result types

* **`Cycle<Vertex, Edges.Index>`** (Walks) everywhere: vertices plus edge positions, so parallel
  edges are told apart (JGraphT's `GraphPath`, igraph's edge-ID output). Equality is up to
  rotation only; the module makes that enough by emitting every undirected cycle once, in one
  orientation (below).
* **`[Cycle]`** for `cycleBasis()`. The README's `CycleBasis` type is not needed: JGraphT's
  `CycleBasis` adds only the total length and weight, a `reduce` away; NetworkX, rustworkx and
  igraph return plain lists. (A minimum basis in phase 2 can return the same.)
* **Lazy sequences** for `simpleCycles`: their number is exponential (K₁₃ has 710 771 275), so
  `first`, `prefix(k)` and early `break` must not pay for the rest. Each `makeIterator()` starts
  over from the stored graph (a value), so iterating twice gives the same cycles (CY-763), and
  mutating the original graph afterwards changes nothing (CY-853). `underestimatedCount` is 0.
* **`Int?`** for `girth()`: `nil` for an acyclic graph, where NetworkX and igraph return `inf`,
  JGraphT `Integer.MAX_VALUE` and Boost `0`. An optional cannot be mistaken for a length.

## Semantics

### What a cycle is

A closed path: no vertex and no edge position twice (Walks' `Cycle`). Consequences, all pinned by
§E of the catalog:

| Graph | Cycles | Libraries |
|---|---|---|
| A self-loop | one 1-cycle per loop edge, though an undirected row lists it twice | igraph (`IGRAPH_LOOPS_ONCE`), NetworkX (but NetworkX merges two loops at a vertex into one, CY-401); Boost's undirected `hawick_circuits` reports each loop twice (CY-414); Boost's Tiernan ignores loops (CY-201) |
| k parallel undirected edges u–v | C(k, 2) 2-cycles (CY-403) | igraph; NetworkX reports one `[u, v]` for any k ≥ 2 |
| One undirected edge | no cycle: the walk u–v–u reuses the edge (CY-005) | all but Boost, whose undirected `hawick_circuits` reads every edge as a 2-circuit (CY-413) |
| Opposite arcs u→v, v→u | one 2-cycle (CY-203) | all |
| Parallel arcs, other cycles through them | one cycle per choice of copy (CY-238, CY-243) | igraph, Boost `hawick_circuits`; NetworkX, Boost `hawick_unique_circuits` and Tiernan count vertex sequences |

Counting with edge identity is the only choice consistent with `Cycle` (whose `==` compares edge
positions) and with the rest of Grafluent (Connectivity treats parallel edges as distinct). The
vertex-only count is one line away: `Set(cycles.map { … vertices up to rotation … })`.

### Canonical form

Every undirected cycle the module returns, from any entry point, **starts at its least vertex**
(the first in `vertices` order, which is index order when the graph has vertex indices) and
**leaves it through the lesser of its two edges there**, by position. A directed cycle starts at
its least vertex too; its orientation is fixed. So:

* each undirected cycle has exactly one representation, which makes rotation-only `==` exact and
  lets tests compare `vertices` and `edges` arrays literally;
* a 2-cycle over copies e₁ < e₂ is `[u, v] / [e₁, e₂]` with u before v in `vertices` (CY-402,
  CY-407): the rule by position, not by neighbour, is what makes 2-cycles canonical;
* a 1-cycle is `[v] / [e]`.

NetworkX canonicalises nothing (each cycle comes in whatever rotation and orientation the search
met it); igraph forces "first edge < closing edge" but starts wherever the search started.

### `findCycle()` (undirected)

Which cycle, exactly: a depth-first search with roots in `vertices` order (or `roots`, in their
order, skipping roots already reached), scanning each vertex's `incidentEdges` in order, never
going back along **the edge it arrived by** (not the vertex it came from), stops at the first
edge e from v to a vertex w still on the search path (w = v for a loop). The cycle is the tree
path from w to v plus e, returned in canonical form. Skipping the parent edge rather than the
parent vertex is what finds a parallel pair (CY-008, CY-024; planted mistake P4). Which cycle is
found depends on incidence order (CY-025, CY-026); its form does not. NetworkX's result is the
same cycle on its own examples (CY-013, CY-014), up to form.

`findCycle(from:)` searches only the roots' components and traps on a root that is not a vertex,
as Traversal's directed form does. `findCycle()` is `nil` exactly when `isAcyclic`.

### `isAcyclic` (undirected)

`edgeCount >= max(vertexCount, 1)` answers `false` at once (a forest has m = n − c ≤ n − 1);
otherwise a union–find over `edges` (DisjointSetModule) stops at the first edge whose ends are
already joined, a self-loop included. Equivalent to `findCycle() == nil` and to
`edgeCount == vertexCount − connectedComponents().count` (CY-756). The empty graph is acyclic
(NetworkX's `is_forest` raises `NetworkXPointlessConcept` on it instead).

`Graph.isAcyclic` and Traversal's `DirectedGraph.isAcyclic` never meet: no type conforms to both
protocols. They differ on the views: `g.directed.isAcyclic` is false as soon as g has an edge
(every edge is two opposite arcs), and `digraph.undirected.isAcyclic` is the polytree test
(NetworkX's `find_cycle(orientation="ignore")`, CY-039).

### `cycleBasis()`

The **fundamental cycles of the breadth-first spanning forest**: roots in `vertices` order, each
vertex's `incidentEdges` scanned in order, the tree edge of a vertex the edge that discovered it.
Every other edge (loops and parallel copies included) is a non-tree edge, and gives one cycle: the
edge plus the tree path between its ends, in canonical form. Cycles are in ascending position of
their non-tree edge. There are m − n + c of them, they are independent over GF(2), and each
contains exactly one non-tree edge, its own, so the basis is fundamental (CY-757).

Why breadth-first: fundamental cycles of a BFS tree are short (each is at most twice the tree's
depth plus one), which is what users of a basis want, and it is what igraph
(`fundamental_cycles`) and JGraphT (`QueueBFSFundamentalCycleBasis`) do. Multigraphs and loops are
supported, as in igraph; NetworkX and JGraphT's Paton reject multigraphs, and rustworkx documents
wrong results on them.

NetworkX's and rustworkx's `cycle_basis` (Paton's algorithm, a depth-first stack) is **not
fundamental** in general: a cycle can be closed through an earlier non-tree edge instead of the
tree, so a basis cycle can have no edge of its own (CY-123). JGraphT's documentation calls it
"weakly fundamental". Bases agree with NetworkX's on its own test graphs (CY-106 – CY-110: the
same vertex sets) but not in general, and lengths differ from JGraphT's Paton (CY-111: 41 against
44).

### `simpleCycles(maxLength:)`

**Order.** By least vertex s, in `vertices` order; among the cycles whose least vertex is s,
lexicographically by the offset of each edge in its vertex's row (`outEdges(of:)` or
`incidentEdges(of:)`), taken along the canonical orientation. That is the order a plain
depth-first enumeration from s meets them, and Johnson's algorithm emits in exactly that order
because its blocking only prunes branches that hold no cycle. It is independent of the
algorithm's internals, cheap to reproduce in a test (sort by that key), and it agrees with
JGraphT's pinned orders (CY-205, CY-207, CY-209). Row order matters (CY-248, CY-331): on a
representation whose rows are not in position order (`UndirectedAdjacencyList` after removals)
the set is the same and the order follows the rows. NetworkX's order is unspecified (it pops
components from a list); igraph's follows vertex IDs but not this key.

**Bound.** `maxLength` counts edges (= vertices, for a cycle): 0 gives nothing, 1 the loops, 2
adds 2-cycles. `simpleCycles(maxLength: k)` is the unbounded sequence filtered to `length <= k`,
in the same order (CY-753). A bound at or above `vertexCount` is the unbounded search. Negative
traps (NetworkX raises `ValueError`).

**Algorithm.** Johnson (1975) unbounded, Gupta–Suzumura (2021) bounded, both as NetworkX runs
them but iterative, in rounds over **pieces**: the strong components (directed), or the blocks
(biconnected components; undirected), that can hold a cycle: two or more vertices, or, for a
block, two or more edges (so a parallel pair counts and a bridge does not). Undirected, each vertex
with a self-loop is also a piece of its own, since loops are in no block. Pieces sit in a heap
keyed by their least vertex.

1. Decompose the graph once and heap the pieces.
2. Take every piece whose least vertex is the heap's minimum s (an undirected cut vertex can head
   several blocks). Every vertex below s is on no cycle of what is left, so s is the least vertex
   of every remaining cycle through it.
3. Enumerate the cycles through s inside the union of those pieces, emitting each as found.
4. Remove s; re-decompose only those pieces minus s, and heap the parts that can still hold a
   cycle. Pieces not containing s are untouched. Repeat until the heap is empty.

Each round emits at least one cycle and costs the size of s's pieces, so the total stays within
Johnson's O((n + m)(c + 1)); a tree costs one decomposition (CY-805), and a chain of 10 000
triangles costs O(1) per triangle (CY-809). Two choices that look simpler are slower:
recomputing the decomposition of the whole alive graph each round (Johnson's paper) is O(n + m)
per round even when cycles are tiny (igraph skips decomposing and instead skips start vertices of
degree < 3 already visited, which is what loses cycles in CY-252); and 2-edge-connected components instead of blocks keep a
chain of triangles in one piece (cut vertices do not split them), so each round walks the whole
chain: quadratic on CY-809. Directed has the same weakness (a chain of directed triangles is one
strong component); NetworkX's own test notes it, and Johnson's bound still holds. NetworkX's
undirected scheme (pick an edge, enumerate paths, delete the edge, re-decompose) is also
block-based but emits in an order no one could specify. Undirected specifics, inside step 3:

* the search walks the graph as two arcs per edge; an arc back to s along the edge just taken
  (s–w–s) is not a cycle;
* each cycle of length ≥ 2 is met in both orientations; only the canonical one (first edge less
  than closing edge, igraph's rule) is emitted;
* a loop at s is met twice in s's row and emitted at its first occurrence (P5).

For unblocking, both kinds of closure that are not emitted must still count as "found". For the
other orientation this is required in the **bounded** search: without it a vertex stays locked
and a later cycle is missed (CY-491, planted P2; found by shuffled-row random tests, never with
rows in position order, and never in the unbounded search). For the closure along the same edge
it is unobservable (any cycle through w is also found from w's branch, P1 never fails); igraph
counts both, and so should we, since it only loosens pruning.

**Complexity.** Unbounded: O((n + m)(c + 1)) time for c cycles (Johnson), O(n + m) memory. Bounded
by k: O((c + n)·k·d^k) for average degree d (Gupta–Suzumura, as NetworkX quotes). Without the
blocking a naive search can take exponential time with one cycle (CY-802: 2³⁰ dead ends).

### `girth()`

The least `length` of a cycle, by the definition above: 1 with a loop, 2 with a parallel pair
(undirected) or opposite arcs (directed). `nil` when acyclic. Undirected: breadth-first search
from every vertex, skipping the edge each vertex was reached by, a non-tree edge (u, w) giving
depth(u) + depth(w) + 1, stopping a search once 2·depth + 1 reaches the best so far (JGraphT,
NetworkX; Itai–Rodeh). Directed: breadth-first search from every vertex until it returns to its
root. O(n·m) time, O(n) memory; a loop answers 1 at once.

| Library | Loops | Parallel edges | Acyclic |
|---|---|---|---|
| Grafluent, JGraphT | 1 | 2 | `nil` / `Integer.MAX_VALUE` |
| NetworkX | 1 (on `Graph`); multigraphs rejected | — | `inf` |
| igraph | ignored | ignored (CY-518, CY-520: 4 where we say 1 and 2) | `inf` |
| Boost `tiernan_girth_and_circumference` | ignored | ignored when undirected (CY-524: 3 where we say 2) | 0 |

## Implementation notes (index space)

* **Undirected rows.** Use Connectivity's row machinery (`_IncidenceRowSource`, `_IncidenceRows`,
  `_LazyIncidenceRows`, `_UndirectedRowsAlgorithm`, `Graph._runOnUndirectedRows`,
  `_edgeNumbers`). They are internal to Connectivity today; make them `package` and move them to
  GraphProtocols (Cycles, Tours' Hierholzer and Matching all need them), rather than adding a
  Cycles → Connectivity dependency for plumbing. `findCycle`, `cycleBasis` and undirected `girth`
  are `_UndirectedRowsAlgorithm`s: they run on `_withIncidentIndexRows` buffers when the
  representation lends them, so nothing is hashed on an `UndirectedAdjacencyList` (CY-857).
* **Directed rows.** Pair `successorIndices(ofIndex:)` with `outEdges(ofIndex:)` (positions are
  needed: `_stepEdges`'s first-matching-edge trick picks the wrong copy of a parallel arc), through
  `_VertexIdentifiers` as Traversal's `IndexSpaceSearch` does.
* **The lazy iterators cannot hold borrowed buffers**: `_withIncidentIndexRows` and
  `_withSuccessorIndexRows` lend storage only for the closure's duration, and `next()` returns
  between calls. On the first `next()` the iterator copies the rows into its own flat arrays
  (offsets, neighbour numbers, edge numbers: a CSR, O(n + m)) and works on those; it also keeps
  `[Edges.Index]` by edge number to build each `Cycle`'s edges. Edge numbers order like positions
  (the protocol law: `edges` is in index order), so "lesser edge" compares numbers.
* **Per-round decompositions of one piece.** Step 4 decomposes a piece minus s, so its cost must
  be the piece's size, not the graph's. Connectivity's searches work on the whole graph; write two
  small iterative ones in Cycles over the iterator's CSR, restricted to a piece by a membership
  stamp per vertex (an `[Int]` of round numbers, so nothing is cleared between rounds): Tarjan's
  strong components, and Hopcroft–Tarjan blocks with an edge stack, skipping the parent edge (as
  Connectivity's `_BiconnectivitySearch` does). The heap is a binary heap of (least vertex, piece)
  with pieces stored as slices of one vertex buffer.
* **Search state.** Explicit stacks: the path's vertex numbers and edge numbers, and a row cursor
  per depth (NetworkX's iterator stack, igraph's `neigh_iteration_progress`). Johnson: a `blocked`
  bit set, a `closed` flag per depth, and B-lists with Johnson's "if v ∉ B(w)" test (igraph scans
  the list, O(d); a stamp array makes it O(1)). Gupta–Suzumura: `lock` per vertex, `blen` per
  depth, the same B-lists. No recursion anywhere: CY-803 and CY-804 search 10⁵ deep.
* **`isAcyclic`.** The O(1) shortcut, then `DisjointSet(count: n)` over `edges` with vertex
  numbers (`vertexIndex(of:)` with indices, a dictionary otherwise), stopping at the first failed
  `union`. This is the only use of DisjointSetModule.
* **Emitting.** A cycle is built from the path stacks at the moment of closure: vertices
  `vertex(atIndex:)` (or the listed array without indices) and edge positions by number, through
  `Cycle(_uncheckedVertices:edges:)`. The rotation is already canonical (it starts at s), and the
  orientation too (the closure test). `findCycle` and `cycleBasis` canonicalise explicitly:
  rotate to the least vertex number, then reverse if the closing edge's number is less than the
  first's.

## Relation to Traversal

Traversal keeps `DirectedGraph.findCycle()`, `findCycle(from:)`, `isAcyclic` and
`topologicalSort()`, unchanged: they are by-products of the depth-first search Traversal owns.
Cycles adds the undirected counterparts and everything that enumerates or measures cycles. The
directed `findCycle()` returns its cycle starting at the back edge's target, not at the least
vertex; this module's canonical form applies to what this module returns. Because `Cycle`'s `==` is
rotation-invariant, `digraph.findCycle()` compares equal to the matching element of
`digraph.simpleCycles()` regardless (a test worth writing: CY-756's directed analogue).

## Library disagreements found while harvesting

| Where | What | Catalog |
|---|---|---|
| igraph 1.0 `simple_cycles` | Misses cycles in digraphs: `D: [0..5] 1>3 4>5 0>4 3>2 2>5 5>1` gives none (one exists); Boost's own ER test graph gives 111 for 113. Its "skip visited start vertices of degree < 3" shortcut is unsound for digraphs | CY-252, CY-244 |
| NetworkX / rustworkx / JGraphT Paton `cycle_basis` | Not a fundamental basis in general (a cycle with no edge of its own); JGraphT says "weakly fundamental", NetworkX says nothing | CY-123 |
| Boost `hawick_circuits`, undirected | Every edge is a 2-circuit, every cycle reported twice, each loop twice: the count of `g.directed`, not of g | CY-328, CY-413 – CY-417 |
| Boost `tiernan_all_cycles` | Ignores self-loops; vertex sequences only; undirected cycles both ways | CY-200, CY-201, CY-328 |
| Multiplicity | NetworkX, Boost `hawick_unique_circuits`, Tiernan count vertex sequences; igraph, Boost `hawick_circuits`, JGraphT (edge objects) and Grafluent count edge choices | CY-238, CY-243, CY-327, CY-403 |
| Girth with loops / parallel edges | JGraphT 1 / 2 (ours); igraph ignores both; Boost ignores loops and undirected 2-cycles; NetworkX rejects multigraphs | CY-518, CY-520, CY-524 |
| "No girth" | `inf` (NetworkX, igraph), `Integer.MAX_VALUE` (JGraphT), 0 (Boost), `nil` (ours) | CY-505 |
| Empty graph | NetworkX `is_forest` raises; igraph and ours: acyclic | CY-001 |
| `findCycle` on a multigraph | NetworkX's `test_multigraph` accepts either parallel copy ("hash randomization"); ours is pinned to the first copy met | CY-013 |
| Cycle basis lengths | JGraphT's Paton basis on its `testPatonCycleBasis1` graph totals 44; the breadth-first basis 41 | CY-111 |
