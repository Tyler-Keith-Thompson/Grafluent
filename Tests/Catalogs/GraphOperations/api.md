# GraphOperations: proposed API (phase 1)

The README's Operations section lists three kinds of operation. Unary operations whose rows can be
computed from the base's rows are **lazy views**: `reverseView`, the three subgraph entry points,
and `complement`. Each view is a value holding its base, conforms conditionally to the base's
protocols, and copies nothing per edge. Operations whose result has a different vertex set, or
edges no base row lists, are **materialized**: the line graph, the condensation as a
`DirectedAcyclicGraph`, the quotient, the disjoint union and the join. They are built in one bulk
step through the construction hooks `_DirectedGraphConstruction` / `_GraphConstruction`, the same
way NamedGraphs' generators are. To materialize a view, pass it to a representation's initializer
(`CompressedSparseRow(g.reverseView)`).

`cases.md` (GO-001 – GO-105, 105 rows) pins the values. `ref.py` ports two bases, an
AdjacencyList-like directed pseudograph and its undirected counterpart, and implements every view
and result in index space. Every lookup of a vertex label is counted as a hash. Each result is
checked three ways:

- against NetworkX 3.7: `reverse_view`, `subgraph`, `subgraph_view`, `complement`, `line_graph`,
  `condensation`, `quotient_graph`, `disjoint_union` and `full_join`;
- against igraph 1.0: `induced_subgraph`, `subgraph_edges`, `complementer`, `linegraph`,
  `contract_vertices` and `disjoint_union`. igraph is used on simple graphs only where its
  multigraph semantics differ. Its `complementer` drops edges next to parallel edges;
- against the protocol laws, including the boundary law that a view's index-space members hash
  nothing.

`--stress` runs 600 random bases, half directed and half undirected, through every operation.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/GraphOperations/ref.py [--write] [--stress]`.

## Names

| Name | Decision | Source |
|---|---|---|
| Reversal view | **`reverseView`**, type **`ReverseView<Base>`**, on `BidirectionalDirectedGraph` only | NetworkX `reverse_view(G)` / `G.reverse(copy=False)`; Boost `reverse_graph` (also only over a `BidirectionalGraph`); LEMON `ReverseDigraph`; JGraphT `EdgeReversedGraph`; petgraph `Reversed`; Mathematica `ReverseGraph` |
| Subgraph view | **`SubgraphView<Base>`**, one type for all three entry points and both protocols | NetworkX `subgraph_view`; JGraphT `AsSubgraph`; LEMON `SubDigraph` / `SubGraph`; Boost `filtered_graph` |
| Induced subgraph | **`inducedSubgraph(on:)`** | igraph `induced_subgraph`; NetworkX `G.subgraph(nodes)` (induced); JGraphT `AsSubgraph(g, vertexSubset)` |
| Spanning subgraph | **`spanningSubgraph(edges:)`**: every vertex, the given edges | Diestel, Bondy–Murty; igraph `subgraph_edges(edges, delete_vertices=False)`; LEMON `FilterArcs` |
| Both filters | **`subgraph(vertices:edges:)`**: an edge is kept when given and both its ends are kept | JGraphT `AsSubgraph(g, vertexSubset, edgeSubset)`; Mathematica `Subgraph`; NetworkX `subgraph_view(filter_node, filter_edge)` |
| Complement | **`complement`**, type **`ComplementView<Base>`** | NetworkX `complement`; igraph `complementer`; petgraph `complement`; Mathematica `GraphComplement` |
| Line graph | **`Target.lineGraph(of:)`** | NetworkX `line_graph`; igraph `linegraph`; JGraphT `LineGraphConverter`; Mathematica `LineGraph` |
| Condensation as a DAG | **`DirectedAcyclicGraph<Base>(_ condensation: Condensation<G>)`** | Connectivity's existing `condensation()` (NetworkX, petgraph); a conversion initializer, like `CompressedSparseRow(g)` |
| Quotient | **`Target.quotient(of:by:)`**, the partition as a sequence of blocks | NetworkX `quotient_graph(G, partition)`; igraph `contract_vertices` + `simplify` |
| Disjoint union | **`Target.disjointUnion(_:_:)`** | NetworkX `disjoint_union`; igraph `disjoint_union`; Mathematica `GraphDisjointUnion` |
| Join | **`Target.join(_:_:)`** | Harary (G + H, Zykov's join); Mathematica `GraphJoin`; NetworkX `full_join` |
| Underlying graph | **`undirected`** (`UndirectedView`, exists) | README open question 8 |
| A view's base | **`base`**, read-only | `UndirectedView`/`DirectedView`; README open question 9 |

There are no typealiases. "Converse" and "transpose" go in `ReverseView`'s doc comment.
"Vertex contraction" goes in `quotient`'s.

### Question 3: the `reversed` conflict

**Decision: `reverseView`.** The README listed `reversed`. A protocol-extension property named
`reversed` would read as the standard library's `reversed()` on any conformer that is also a
`Sequence`, and on `Walk`, `Trail` and `Circuit` it already means the walk backwards. `EdgeList`
uses `transposed()` for the materialized flip, and `CompressedSparseRow`, `AdjacencyMatrix` and
`LabeledGraph` do the same. A lazy `transposed` property would collide with those `transposed()`
methods on the very types that have them. `reverseView` is NetworkX's name for exactly this lazy
view. It has the `View` suffix that `DirectedView` and `UndirectedView` already carry, and it
cannot be mistaken for a sequence reversal. The README Terminology row "Every edge reversed"
becomes `reverseView` (NetworkX `reverse_view`, Boost `reverse_graph`, LEMON `ReverseDigraph`),
and `transposed()` stays the materialized row.

`g.reverseView.reverseView` returns `g` itself: an overload on `ReverseView` gives back `base` in
O(1) (GO-008), so double reversal adds no layer. `ReverseView` needs a
`BidirectionalDirectedGraph`, as Boost's `reverse_graph` does. `CompressedSparseRow` has no
in-rows and keeps `transposed()`.

## Question 1: index spaces

**Subgraph views renumber; they do not use `SparselyIndexedDirectedGraph`.** That protocol has
two drawbacks here:

- Its index-space path is `_numberedRows`. That builds CSR rows for the whole graph on every
  algorithm run, O(n + m) allocation, which is the copy a view exists to avoid. An algorithm on a
  view would then cost at least one materialization.
- It requires `Edges.Index == Int` and bidirectionality. `AdjacencyMatrix` (pair positions) and
  `CompressedSparseRow` (no in-rows) could not be bases.

A `SubgraphView` therefore keeps two `Int` arrays, built once:

- `_old[k]` is the base index of view vertex `k`. The array is ascending, so `vertices` is the
  base's order filtered, which is the index-order law.
- `_new[i]` is the view index of base vertex `i`, or −1.

Then `vertexIndexBound` is the kept count and the laws hold unchanged.
`successorIndices(ofIndex: k)` walks `base.successorIndices(ofIndex: _old[k])` and yields
`_new[w]` where it is not −1: one array load and one predictable branch per edge, with no
hashing (GO-020). `spanningSubgraph` keeps every vertex, leaves both arrays empty and forwards
`vertexIndex` (GO-035).

Edges pass through. `Edges.Index` is `Base.Edges.Index`, so the base's weight closures and, later,
its attached maps work on the view (README open question 9). An edge filter is a bit mask over the
base's `edgeIndex`, plus one `Int32` prefix count per 64-bit word. With it the view reports dense
edge indices: `edgeIndex(of: p)` is the rank of `p`'s bit, O(1) by popcount (GO-031). An induced
subgraph reports `edgeIndexBound == nil` (GO-012), because building its edge mask costs O(m).

**An edge filter over a base without edge indices** (an `AdjacencyMatrix`, whose positions are
cells; a complement; an induced subgraph; a `StableDirectedGraph` with edge holes) takes the slower
path rather than trapping: the view keeps the listed positions that pass, sorted and deduplicated
(`Collection.Index` is `Comparable`). A row entry is kept by a binary search, O(log k), and
`edgeIndex(of:)` is the position's offset in that array, so the view still has dense edge indices
by rank. A listed position is checked against `edges.startIndex ..< endIndex` and through the
base's `sourceIndex(ofEdgeAt:)`, which traps on a cell or slot that holds no edge. Building costs
O(listed log listed). Tested by the hand-written conformance test "An edge set over a base without
edge indices", over an `AdjacencyMatrix` and an undirected complement.

**Complement.** The vertices and their indices are the base's. Row `i` is every `j ≠ i` absent
from the base row. The row iterator marks the base row in a `⌈n/64⌉`-word mask, O(deg + n/64),
then yields the clear bits by trailing-zero count. A row therefore costs O(n/64 + output) and one
small allocation. The complement has Θ(n²) edges on a sparse base, so a traversal is Θ(n²)
whatever the layout. `edgeIndexBound` is `nil`. `Edges.Index` is **`ComplementView.Cell`**, the cell of the adjacency
matrix: a `@frozen` struct with `public let row: Int` and `public let column: Int` (vertex indices)
and a public `init(row:column:)`, `Hashable`, `Sendable`, and `Comparable` in row-major order, as
`AdjacencyMatrix.Edges.Index` is. One type serves both directions: directed, the edge runs from
`row` to `column`; undirected, `row < column`. The init checks nothing, like
`DirectedView.Edges.Index`'s. `contains(edge:)` is `u ≠ v` and not `base.contains(edge:)` (GO-062).
It takes vertices, so it looks both up (and the base's `contains(edge:)` looks them up again); GO-062
counts hashes over the index-space rows only, and lists the `contains(edge:)` answers after. Self-loops and parallel
edges of the base are ignored (GO-053, GO-054, GO-060), as in NetworkX and igraph
(`loops=False`). The complement of the complement is therefore the simple, loopless base (GO-057).

## Question 4: lazy or materialized

| Operation | Kind | Result | Why |
|---|---|---|---|
| `reverseView` | Lazy, O(1) to build | `ReverseView<Base>: BidirectionalDirectedGraph` | Rows are the base's in-rows |
| `inducedSubgraph(on:)` | Lazy, O(n_base + listed) to build | `SubgraphView<Base>` | Rows are the base rows, filtered |
| `spanningSubgraph(edges:)` | Lazy, O(m_base/64 + listed) | `SubgraphView<Base>` | Same |
| `subgraph(vertices:edges:)` | Lazy, both costs | `SubgraphView<Base>` | Same |
| `complement` | Lazy, O(1) | `ComplementView<Base>` | Rows are a function of base rows; a copy is Θ(n²) |
| `undirected` | Lazy (exists) | `UndirectedView<Base>` | |
| `lineGraph(of:)` | Materialized | `Target` | The undirected rows need deduplication across both ends; the directed form could be lazy (phase 2) |
| condensation | Materialized | `DirectedAcyclicGraph<Base>` | New vertex set |
| `quotient(of:by:)` | Materialized | `Target` | New vertex set, deduplicated edges |
| `disjointUnion`, `join` | Materialized | `Target` | Two inputs, new numbering |

`Target` is any `_DirectedGraphConstruction` (`CompressedSparseRow`, `AdjacencyList<Int>`,
`AdjacencyMatrix`, `StableDirectedGraph<Int>`) or `_GraphConstruction`
(`UndirectedAdjacencyList<Int>`). These are static factories on the target type, as NamedGraphs'
generators are (`CompressedSparseRow.complete(vertexCount:)`), so the caller picks the layout and
nothing is copied twice. The hooks take sorted, simple, loop-free edges, so these results are
simple graphs on `0..<n`. Parallel edges merge (GO-069, GO-075, GO-089, GO-098). Two cases with
self-loops trap in phase 1:

- a directed line graph over a graph with a self-loop, whose line graph has a self-loop
  (NetworkX keeps it; GO-070);
- a disjoint union or join of inputs with self-loops (GO-099, GO-105).

**Requests to other modules.** Made with the implementation:

- DirectedAcyclicGraphModule: `package init(_reverseVertexOrderedBase:)`, the mirror of
  `_vertexOrderedBase`, so the condensation initializer sets the order to `n−1, …, 0` without a
  Kahn pass.
- `scripts/modules.py`: `GraphOperations` gains `Connectivity` (for `Condensation`) and
  `CompressedSparseRowModule` (the condensation's graph is one, and an `@inlinable` initializer
  reads it).
- README: the Terminology row, and the Operations table.
- **Index-space hooks on the representations.** `AdjacencyList`, `DirectedPseudograph`,
  `DirectedMultigraph`, `StableDirectedGraph`, `CompressedSparseRow` and `AdjacencyMatrix` now
  implement `outDegree(ofIndex:)` (and `inDegree(ofIndex:)` where bidirectional) and
  `sourceIndex(ofEdgeAt:)` / `targetIndex(ofEdgeAt:)`; `UndirectedAdjacencyList`, `Pseudograph`
  and `Multigraph` implement `degree(ofIndex:)` and `endpointIndices(ofEdgeAt:)`. Each reads the
  stored row length or the edge record, where the protocol defaults looked the vertex up. Views
  that forward them (this module's, `DirectedView`, `UndirectedView`, `DirectedAcyclicGraph`) hash
  nothing as a result, and so does every algorithm that reads degrees or edge ends by index.

Still open:

- GraphProtocols: allowing self-loops in `_DirectedGraphConstruction`'s contract would remove both
  traps. Every conformer's sorted build must be checked for loops first.

### Condensation

Connectivity's `condensation()` keeps its name and its `Condensation<G>` result. A second
`condensation()` in this module with a different return type would make `g.condensation()`
ambiguous under `import Grafluent`. The conversion is an initializer:

```swift
let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())
```

Vertex `i` of `dag` is `condensation.components[i]`. The edges are built through the base's
construction hook in row-major order. Connectivity's law says every condensation edge goes from a
later component to an earlier one, so `topologicalOrder` is `[n−1, …, 0]`, set with no checks
(GO-078 – GO-084; GO-084 is NetworkX's own SCC order). Cost: O(k + e). Base:
`MutableDirectedGraph & _DirectedGraphConstruction`.

## API

```swift
// MARK: Reversal
extension BidirectionalDirectedGraph {
    public var reverseView: ReverseView<Self> { get }                         // O(1)
}
extension ReverseView {
    public var reverseView: Base { get }                                      // the base, O(1)
}
@frozen public struct ReverseView<Base: BidirectionalDirectedGraph>: BidirectionalDirectedGraph {
    public var base: Base { get }
    // Vertex, Vertices: the base's. Edges.Index == Base.Edges.Index, each edge flipped.
    // Successors == Base.Predecessors, OutEdges == Base.InEdges,
    // SuccessorIndices == Base.PredecessorIndices, and the converse for the in-side.
    // source/sourceIndex(ofEdgeAt:) is the base's target, and the reverse. vertexIndexBound,
    // vertexIndex(of:), vertex(atIndex:), edgeIndexBound, edgeIndex(of:) are forwarded.
    // contains(edge: u→v) is base.contains(edge: v→u). _withSuccessorIndexRows is nil.
}

// MARK: Subgraphs
extension DirectedGraph {
    public func inducedSubgraph(on vertices: some Sequence<Vertex>) -> SubgraphView<Self>
    public func spanningSubgraph(edges: some Sequence<Edges.Index>) -> SubgraphView<Self>
    public func subgraph(vertices: some Sequence<Vertex>, edges: some Sequence<Edges.Index>) -> SubgraphView<Self>
}
extension Graph { /* the same three */ }

@frozen public struct SubgraphView<Base> {
    public let base: Base
    @usableFromInline let _old: [Int]             // view index → base index; empty when every vertex is kept
    @usableFromInline let _new: [Int]             // base index → view index or −1; empty when every vertex is kept
    @usableFromInline let _vertexCount: Int
    @usableFromInline let _edgeMask: _EdgeMask?   // bits by base edgeIndex + per-word prefix counts
    @usableFromInline let _keptPositions: _KeptPositionsBox?  // sorted positions, base without edge indices
    @usableFromInline let _edgeCount: Int?        // known when an edge set was given
}
// An induced subgraph that keeps every vertex leaves _old and _new empty, so its rows and
// degrees are the base's.
extension SubgraphView {
    // Rows shared by both directions, generic over the base's index row and position row:
    public struct IndexRow<Indices: Sequence<Int>, Positions: Sequence>: Sequence      // renumbered
    public struct EdgeRow<Indices: Sequence<Int>, Positions: Sequence>: Sequence       // positions
    public struct EdgeIndexRow<Indices: Sequence<Int>, Positions: Sequence>: Sequence  // ranks
}
extension SubgraphView: DirectedGraph where Base: DirectedGraph
    // Vertices: LazyMapCollection<Range<Int>, Base.Vertex>; Edges: DirectedEdges (base positions);
    // SuccessorIndices: IndexRow<Base.SuccessorIndices, Base.OutEdges>;
    // OutEdges: EdgeRow<Base.SuccessorIndices, Base.OutEdges>; Successors: a lazy map of IndexRow.
extension SubgraphView: BidirectionalDirectedGraph where Base: BidirectionalDirectedGraph
    // The same over Base.PredecessorIndices and Base.InEdges.
extension SubgraphView: Graph where Base: Graph
    // Edges: UndirectedEdges; NeighborIndices: IndexRow<Base.NeighborIndices, Base.IncidentEdges>;
    // IncidentEdges: EdgeRow<…>; IncidentEdgeIndices: EdgeIndexRow<…> (each kept position's rank).

// MARK: Complement
extension DirectedGraph { public var complement: ComplementView<Self> { get } }  // O(1)
extension Graph { public var complement: ComplementView<Self> { get } }
@frozen public struct ComplementView<Base> {
    public let base: Base
    @frozen public struct Cell: Hashable, Comparable, Sendable {   // Edges.Index, both directions
        public let row: Int, column: Int                         // undirected: row < column
        public init(row: Int, column: Int)
    }
    public struct IndexRow<Row: Sequence<Int>>: Sequence          // the clear bits of the row's mask
    public struct CellRow<Row: Sequence<Int>>: Sequence           // IndexRow as cells
}
extension ComplementView: DirectedGraph where Base: DirectedGraph
extension ComplementView: BidirectionalDirectedGraph where Base: BidirectionalDirectedGraph
extension ComplementView: Graph where Base: Graph

// MARK: Materialized
extension _DirectedGraphConstruction {
    public static func lineGraph(of graph: some DirectedGraph) -> Self
    public static func quotient<G: DirectedGraph>(
        of graph: G, by partition: some Sequence<some Sequence<G.Vertex>>) -> Self
    public static func disjointUnion(_ g: some DirectedGraph, _ h: some DirectedGraph) -> Self
    public static func join(_ g: some DirectedGraph, _ h: some DirectedGraph) -> Self
}
extension _GraphConstruction { /* the same four over Graph */ }
extension DirectedAcyclicGraph where Base: _DirectedGraphConstruction {
    public init<G>(_ condensation: Condensation<G>)
}
```

One generic type with conditional conformances to both `DirectedGraph` and `Graph` compiles. Each
constrained extension declares its own `Edges` typealias and members, checked on Swift 6 in a
scratch file. No type is ever both, because no base is (README open question 8).

Result numbering:

- **Line graph:** vertex `k` is the edge with `edgeIndex` `k`, or the `k`th position of `edges`
  when the graph has no edge indices. That second case costs one hash per edge.
- **Quotient:** vertex `i` is block `i`.
- **Disjoint union and join:** `g`'s vertex index `i` is `i`, and `h`'s `j` is `|V(g)| + j`, as in
  NetworkX and igraph.

## Semantics, preconditions and traps

| Case | Behaviour | Rows |
|---|---|---|
| `inducedSubgraph(on:)` / `subgraph` with a vertex not in the base | **Trap.** NetworkX's `subgraph` silently skips it, igraph raises. A `safe:` variant comes with the repo-wide pass (Principle 6) | GO-022, GO-044 |
| A position not in the base | **Trap** | GO-036, GO-045 |
| Repeated vertex or position | Set semantics; the hash count still counts each listed occurrence | GO-014, GO-020, GO-032 |
| `subgraph(vertices:edges:)` edge with an end outside the vertex set | Dropped, as in JGraphT's `AsSubgraph` and NetworkX's filters | GO-040, GO-041 |
| A base vertex outside the view | `contains` is false; `vertexIndex(of:)` and the rows trap | GO-023, GO-024 |
| Base with `vertexIndexBound == nil` (`StableDirectedGraph` with holes) | **Trap** in phase 1, at construction | GO-025, GO-063 |
| `ReverseView` over a non-bidirectional base | Does not compile | — |
| `complement`: self-loops, parallel edges | Ignored; the complement is simple and loop-free | GO-053, GO-054, GO-060 |
| Undirected self-loop in a subgraph | Listed twice in its row, as in the base | GO-027, GO-038 |
| Directed line graph with a self-loop | **Trap** (phase 1) | GO-070 |
| Undirected line graph with a self-loop | The loop is adjacent to the other edges at its vertex; no loop in L | GO-076 |
| `quotient`: vertex in two blocks, a vertex in no block, a label not in the graph | **Trap.** NetworkX 3.7 does not check | GO-092 – GO-094 |
| `quotient`: an empty block | An isolated vertex | GO-091 |
| `quotient`: edges inside a block | Dropped, with no self-loops, as in NetworkX | GO-086 |
| `disjointUnion` / `join` with a self-loop | **Trap** (phase 1) | GO-099, GO-105 |
| Mutating the base after making a view | Impossible: the view holds a copy (value semantics). Mutating the original never shows through | — |
| `spanningSubgraph` / `subgraph` over a base without edge indices | The slower path: sorted kept positions, binary search per row entry and per rank; dense edge indices still | hand-written test |
| A materialized operation over a graph without vertex indices | **Trap** in phase 1, like the views | — |

## Complexity

n and m are the base's counts, and k is the number of kept vertices.

| Member | `ReverseView` | `SubgraphView` | `ComplementView` |
|---|---|---|---|
| Build | O(1) | induced: O(n + listed), plus one hash per listed vertex; spanning: O(m/64 + listed); both: the sum | O(1) |
| Row (`successorIndices`, `outEdges`, …) | the base's in-row | base row length; one load and a branch per entry | O(n/64 + output), one allocation of ⌈n/64⌉ words |
| `outDegree(ofIndex:)` | base `inDegree` | O(base degree) | O(deg + n/64) |
| `vertexIndex(of:)` | the base's | the base's plus one load | the base's |
| `edgeCount` | O(1) | O(1) with an edge set; induced: O(Σ base out-degree of kept vertices) | O(n + m) |
| `edgeIndexBound` | the base's | the kept count with an edge set; `nil` induced | `nil` |
| `contains(edge:)` | base, flipped | base, both ends kept; with an edge set, a scan of the source's row | base, negated |

| Materialized | Time | Memory |
|---|---|---|
| `lineGraph`, directed | O(m + \|E(L)\| + Σ row sorts) | the target |
| `lineGraph`, undirected | O(Σᵥ deg(v)² + sorts), with a stamp array for deduplication | O(m) scratch |
| condensation → DAG | O(k + e) after `condensation()` | the target |
| `quotient` | O(n + m + sort), one hash per listed vertex | O(n) |
| `disjointUnion`, `join` | O(n + m), join + O(\|V(g)\|·\|V(h)\|) | the target |

## Implementation notes from the measured traps

- Row sequences are concrete structs that hold the base row and read `_new` / `_old` by index.
  They are not `lazy.map { self… }` closures: a lazy map capturing `self` copies the view's base on
  every call.
- `_withSuccessorIndexRows` and `_withIncidentIndexRows` return `nil` on every view here, with one
  exception. Their contract forbids forwarding through a view that changes incidence, and a
  `ReverseView`'s rows are not the base's out-rows. A directed induced subgraph that keeps every
  vertex leaves `_old` and `_new` empty and has no edge set, so its rows and positions are the
  base's, and it forwards `_withSuccessorIndexRows`. (The undirected hook is not forwarded: it
  carries edge indices, which an induced subgraph does not report.)
- The edge set is a class (`_EdgeTest<Position>`, subclassed per base) held once by the view, so
  a row holds one optional reference rather than a copy of the base; a row that would hold the base
  by value was copied through value witnesses on every row (measured: 2–3× on BFS).
- Every requirement with a default is implemented by forwarding (`DirectedGraph`'s "Defaults"
  rule). A default chosen for the view would ignore the base's faster member.
- Overflow guards are written as comparisons, not `multipliedReportingOverflow` with the product
  discarded. That form was miscompiled under -O in Flows.
- Each view stores `base` as a `let` with a public getter, and positions pass through `ReverseView`
  and `SubgraphView`. They slot into the planned adaptor protocol of README open question 9
  without change. That protocol is not built here: four views do not yet justify it, and its
  default forwarding is the open question's subject.

## Performance targets

Benchmarks on 1M-edge Erdős–Rényi and grid bases. "Base" is the same algorithm on the base or on a
materialized copy, with that copy's fast paths. CompressedSparseRow's flat-row path does not apply
through a view, and the ratio includes that loss.

| Benchmark | Target |
|---|---|
| BFS and `stronglyConnectedComponents()` on `g.reverseView` (AdjacencyList) vs on `AdjacencyList(g.reverseView)` | ≤ 1.05× |
| BFS and `connectedComponents()` / `weaklyConnectedComponents()` on `inducedSubgraph` keeping 100% (AdjacencyList and UndirectedAdjacencyList) vs the base | ≤ 1.2× |
| The same keeping 50% at random, vs a materialized `CompressedSparseRow` of the subgraph | ≤ 1.2× including the view's build; the build alone ≤ 0.1× of materializing |
| BFS on `inducedSubgraph` over `CompressedSparseRow` keeping 100% vs the base (which uses flat rows) | ≤ 1.3×, flagged as the risk |
| `spanningSubgraph` of a spanning tree's edges, BFS vs the base | ≤ 1.2× |
| BFS on `complement` of a sparse graph (n = 20k) vs a materialized complement CSR | ≤ 1.5×; ≥ 10× faster than NetworkX `complement` + BFS |
| `CompressedSparseRow.lineGraph(of:)` | ≤ 1× igraph `linegraph`, ≥ 20× faster than NetworkX `line_graph` |
| Condensation → DAG | ≤ 1.1× `condensation()` alone |
| Hashes in any index-space member of a view | 0 (catalog rows; property-tested) |

## Phase 2

- **`union` and `intersection`** (NetworkX `compose` and `intersection`, igraph `union` /
  `intersection`, Mathematica `GraphUnion` / `GraphIntersection`). The vertices are matched by
  value, so the result must keep `Vertex`, which the `Int` construction hooks cannot. They wait
  for a target protocol that keeps labels: `MutableDirectedGraph` covers the directed side, and
  the undirected side needs its counterpart. Semantics to pin: V = V(G) ∪ V(H) (∩ for
  intersection), and edges as sets, as in NetworkX's simple graphs.
- Sparsely indexed bases (`StableDirectedGraph` with holes) for the subgraph views and the
  complement: renumber from `vertexPosition` through `_PositionNumbers` instead of trapping.
- Edge indices for `inducedSubgraph`, through an O(m) mask built on request.
- Predicate filters: `subgraph(where:)` over vertices and edges (NetworkX `subgraph_view`, LEMON
  `FilterNodes` / `FilterArcs`).
- A nested `SubgraphView<SubgraphView<B>>` collapses to one level by composing the maps (GO-046
  shows the nested form, which works).
- A fast path for `AdjacencyMatrix.complement`: word-wise NOT of the `BitSet` rows, and a
  materialized `complement` on the matrix itself.
- A lazy directed line graph: the rows are `outEdges(of: target(e))`, and the vertices are edge
  positions.
- Self-loops through the construction hooks, which lifts GO-070, GO-099 and GO-105.
