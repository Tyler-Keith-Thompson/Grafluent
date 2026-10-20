# GraphOperations: API

GraphOperations has two kinds of operation. Unary operations whose rows can be computed from the
base's rows are **lazy views**: `transposedView`, the three subgraph entry points, the ego graph,
and `complementView`. Each view is a value holding its base, conforms conditionally to the base's
protocols, and copies nothing per edge. Operations whose result has a different vertex set, or
edges no base row lists, are **materialized**: the line graph, the condensation as a
`DirectedAcyclicGraph`, the quotient, the contractions, the disjoint union and the join, the power,
the transitive closure and reduction, and the relabeling by an ordering. They are built in one bulk
step through the construction hooks `_DirectedGraphConstruction` / `_GraphConstruction`, the same
way NamedGraphs' generators are. The operations that keep vertex labels (the relabeling by a
name map, the union, intersection, difference and symmetric difference) are built on a
`MutableDirectedGraph` / `MutableGraph` target (`AdjacencyList`, `DirectedPseudograph`,
`StableDirectedGraph`; `UndirectedAdjacencyList`, `Pseudograph`) through `_built`, one insertion
per vertex and per edge. No materialized result carries attached maps; a value moves over by
vertex, through the vertex numbering each operation documents. To materialize a view, pass it to a representation's initializer
(`CompressedSparseRow(g.transposedView)`).

`cases.md` (GO-001 – GO-173, 173 rows) pins the values. `ref.py` ports two bases, an
AdjacencyList-like directed pseudograph and its undirected counterpart, and implements every view
and result in index space. Every lookup of a vertex label is counted as a hash. Each result is
checked three ways:

- against NetworkX 3.7: `reverse_view`, `subgraph`, `subgraph_view`, `complement`, `line_graph`,
  `condensation`, `quotient_graph`, `disjoint_union`, `full_join`, `ego_graph`, `power`,
  `contracted_nodes`, `transitive_closure`, `transitive_reduction`, `relabel_nodes`, `compose`,
  `intersection`, `difference` and `symmetric_difference`;
- against igraph 1.0: `induced_subgraph`, `subgraph_edges`, `complementer`, `linegraph`,
  `contract_vertices`, `disjoint_union` and `neighborhood`. igraph is used on simple graphs only where its
  multigraph semantics differ;
- against the protocol laws, including the boundary law that a view's index-space members hash
  nothing.

`--stress` runs 600 random bases, half directed and half undirected, through every operation.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/GraphOperations/ref.py [--write] [--stress]`.

## Names

| Operation | API |
|---|---|
| Reversal view | `transposedView`, type `TransposedView<Base>`, on `BidirectionalDirectedGraph` only |
| Subgraph view | `SubgraphView<Base>`, one type for all three entry points and both protocols |
| Induced subgraph | `inducedSubgraphView(on:)` |
| Spanning subgraph | `spanningSubgraphView(edges:)`: every vertex, the given edges |
| Both filters | `subgraphView(vertices:edges:)`: an edge is kept when given and both its ends are kept |
| Complement | `complementView`, type `ComplementView<Base>` |
| Line graph | `Target.lineGraph(of:)` |
| Condensation as a DAG | `DirectedAcyclicGraph<Base>(_ condensation: Condensation<G>)` |
| Quotient (vertex contraction) | `Target.quotient(of:by:)`, the partition as a sequence of blocks |
| Quotient by key (entity merging) | `Target.quotient(of:byKey:)`, vertices with equal keys as one block, blocks by first vertex |
| Disjoint union | `Target.disjointUnion(_:_:)` |
| Rooted and corona products | `Target.rootedProduct(_:_:root:)` (and `checkedRoot:`), `Target.coronaProduct(_:_:)` |
| Join | `Target.join(_:_:)` |
| Ego graph | `egoGraphView(of:radius:)` of one center or of several, with `undirected:` on a bidirectional base and `maximumVertexCount:priority:` for a vertex budget; a `SubgraphView` |
| Power Gᵏ | `Target.power(of:_:)` |
| Vertex identification | `Target.contraction(of:_:_:)` |
| Edge contraction G/e | `Target.contraction(of:edgeAt:)` |
| Transitive closure, reduction (cycles allowed) | `Target.transitiveClosure(of:)`, `Target.transitiveReduction(of:)` |
| Renumbering (NetworkX `convert_node_labels_to_integers`) | `Target.relabeled(_:ordering:)` |
| Renaming (NetworkX `relabel_nodes`) | `Target.relabeled(_:by:)` on a mutable target |
| Union G ∪ H (NetworkX `compose`) | `Target.union(_:_:)` on a mutable target |
| Intersection, difference, symmetric difference | `Target.intersection(_:_:)`, `difference(_:_:)`, `symmetricDifference(_:_:)` |
| Underlying graph | `undirectedView` (`UndirectedView`, in GraphProtocols) |
| A view's base | `base`, read-only |

`g.transposedView.transposedView` returns `g` itself: an overload on `TransposedView` gives back
`base` in O(1) (GO-008). `TransposedView` needs a `BidirectionalDirectedGraph`.
`CompressedSparseRow` has no in-rows and offers the materialized `transposed()` instead.

## Index spaces

A `SubgraphView` keeps two `Int` arrays, built once:

- `_old[k]` is the base index of view vertex `k`. The array is ascending, so `vertices` is the
  base's order filtered, which is the index-order law.
- `_new[i]` is the view index of base vertex `i`, or −1.

`vertexIndexBound` is the kept count. `successorIndices(ofIndex: k)` walks
`base.successorIndices(ofIndex: _old[k])` and yields `_new[w]` where it is not −1, one array load
per edge with no hashing (GO-020). `spanningSubgraphView` keeps every vertex, leaves both arrays
empty and forwards `vertexIndex` (GO-035).

Edges pass through. `Edges.Index` is `Base.Edges.Index`, so the base's weight closures and
attached maps work on the view. An edge filter is a bit mask over the base's `edgeIndex`, plus one
`Int32` prefix count per 64-bit word. With it the view reports dense edge indices:
`edgeIndex(of: p)` is the rank of `p`'s bit, O(1) by popcount (GO-031). An induced subgraph that
drops a vertex reports `edgeIndexBound == nil`. One on every vertex keeps every edge, so it
reports the base's edge indices (GO-012).

An edge filter over a base without edge indices (an `AdjacencyMatrix`, whose positions are cells;
a complement; an induced subgraph; a `StableDirectedGraph` with edge holes) keeps the listed
positions that pass, sorted and deduplicated. A row entry is kept by a binary search, O(log k), and
`edgeIndex(of:)` is the position's offset in that array, so the view still has dense edge indices
by rank. A listed position is checked against `edges.startIndex ..< endIndex` and through the
base's `sourceIndex(ofEdgeAt:)`, which traps on a cell or slot that holds no edge. Building costs
O(listed log listed). The hand-written conformance test "An edge set over a base without edge
indices" covers this over an `AdjacencyMatrix` and an undirected complement.

A `ComplementView` keeps the base's vertices and indices. Row `i` is every `j ≠ i` absent from the
base row. The row iterator marks the base row in a `⌈n/64⌉`-word mask, O(deg + n/64), then yields
the clear bits by trailing-zero count, so a row costs O(n/64 + output) and one small allocation.
The complement has Θ(n²) edges on a sparse base, so a traversal is Θ(n²). `edgeIndexBound` is
`nil`. `Edges.Index` is `ComplementView.Cell`, the cell of the adjacency matrix: a `@frozen`
struct with `public let source: Int` and `public let target: Int` (vertex indices, the row and the
column) and a public `init(source:target:)`, `Hashable`, `Sendable`, and `Comparable` in row-major
order, as `AdjacencyMatrix.Edges.Index(source:target:)` is. Directed, the edge runs from `source`
to `target`; undirected, `source < target`. `edges.index(after:)` steps from the current column,
one base `contains(edge:)` per column passed, so walking `edges.indices` costs O(n²) tests. The
init checks nothing. `contains(edge:)` is `u ≠ v` and not `base.contains(edge:)` (GO-062). It
takes vertices, so it looks both up; GO-062 counts hashes over the index-space rows only, and lists
the `contains(edge:)` answers after. Self-loops and parallel edges of the base are ignored (GO-053,
GO-054, GO-060), so the complement of the complement is the simple, loopless base (GO-057).

## Lazy and materialized

| Operation | Kind | Result |
|---|---|---|
| `transposedView` | Lazy, O(1) to build | `TransposedView<Base>: BidirectionalDirectedGraph` |
| `inducedSubgraphView(on:)` | Lazy, O(n_base + listed) to build | `SubgraphView<Base>` |
| `spanningSubgraphView(edges:)` | Lazy, O(m_base/64 + listed) | `SubgraphView<Base>` |
| `subgraphView(vertices:edges:)` | Lazy, both costs | `SubgraphView<Base>` |
| `complementView` | Lazy, O(1) | `ComplementView<Base>` |
| `undirectedView` | Lazy | `UndirectedView<Base>` |
| `lineGraph(of:)` | Materialized | `Target` |
| condensation | Materialized | `DirectedAcyclicGraph<Base>` |
| `quotient(of:by:)` | Materialized | `Target` |
| `quotient(of:byKey:)` | Materialized | `Target` |
| `disjointUnion`, `join` | Materialized | `Target` |
| `rootedProduct`, `coronaProduct` | Materialized | `Target` |
| `egoGraphView(of:radius:)` | Lazy, O(n + rows walked) to build | `SubgraphView<Base>` |
| `power`, `contraction`, `transitiveClosure`, `transitiveReduction`, `relabeled(_:ordering:)` | Materialized | `Target` |
| `relabeled(_:by:)`, `union`, `intersection`, `difference`, `symmetricDifference` | Materialized, labels kept | a `MutableDirectedGraph` / `MutableGraph` target |

`Target` is any `_DirectedGraphConstruction` (`CompressedSparseRow`, `AdjacencyList<Int>`,
`AdjacencyMatrix`, `StableDirectedGraph<Int>`) or `_GraphConstruction`
(`UndirectedAdjacencyList<Int>`). These are static factories on the target type, as NamedGraphs'
generators are (`CompressedSparseRow.complete(vertexCount:)`), so the caller picks the layout. The
hooks take sorted, simple, loop-free edges, so these results are simple graphs on `0..<n`.
Parallel edges merge (GO-069, GO-075, GO-089, GO-098). Two cases with self-loops trap:

- a directed line graph over a graph with a self-loop, whose line graph has a self-loop (GO-070);
- a disjoint union or join of inputs with self-loops (GO-099, GO-105).

### Condensation

Connectivity's `condensation()` returns a `Condensation<G>`. The conversion to a DAG is an
initializer:

```swift
let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())
```

Vertex `i` of `dag` is `condensation.components[i]`. The edges are built through the base's
construction hook in row-major order. Every condensation edge goes from a later component to an
earlier one, so `topologicalOrder` is `[n−1, …, 0]`, set with no checks (GO-078 – GO-084; GO-084
uses NetworkX's SCC order). Cost: O(k + e). Base: `MutableDirectedGraph & _DirectedGraphConstruction`.

## API

```swift
// MARK: Reversal
extension BidirectionalDirectedGraph {
    public var transposedView: TransposedView<Self> { get }                         // O(1)
}
extension TransposedView {
    public var transposedView: Base { get }                                      // the base, O(1)
}
@frozen public struct TransposedView<Base: BidirectionalDirectedGraph>: BidirectionalDirectedGraph, GraphAdaptor {
    public let base: Base
    // Vertex, Vertices: the base's. Edges.Index == Base.Edges.Index, each edge flipped.
    // Successors == Base.Predecessors, OutEdges == Base.InEdges,
    // SuccessorIndices == Base.PredecessorIndices, and the converse for the in-side.
    // source/sourceIndex(ofEdgeAt:) is the base's target, and the reverse. vertexIndexBound,
    // vertexIndex(of:), vertex(atIndex:), edgeIndexBound, edgeIndex(of:) are forwarded.
    // contains(edge: u→v) is base.contains(edge: v→u). _withSuccessorIndexRows is nil.
}

// MARK: Subgraphs
extension DirectedGraph {
    public func inducedSubgraphView(on vertices: some Sequence<Vertex>) -> SubgraphView<Self>
    public func spanningSubgraphView(edges: some Sequence<Edges.Index>) -> SubgraphView<Self>
    public func subgraphView(vertices: some Sequence<Vertex>, edges: some Sequence<Edges.Index>) -> SubgraphView<Self>
}
extension Graph { /* the same three */ }

@frozen public struct SubgraphView<Base>: GraphAdaptor {
    public let base: Base
    @usableFromInline let _old: [Int]             // view index → base index; empty when every vertex is kept
    @usableFromInline let _new: [Int]             // base index → view index or −1; empty when every vertex is kept
    @usableFromInline let _vertexCount: Int
    @usableFromInline let _edgeTest: _EdgeTestBox? // the edge set, by reference: a mask by base
                                                  // edgeIndex with per-word prefix counts (and its
                                                  // words as a pointer), or the sorted kept positions
                                                  // over a base without edge indices
    @usableFromInline let _edgeCount: Int?        // known when an edge set was given
    @usableFromInline let _rowState: (AnyObject & Sendable)?  // _RowState: _new and the edge set in
                                                  // one reference for the rows; nil when the view
                                                  // keeps every vertex and every edge
}
// An induced subgraph that keeps every vertex leaves _old and _new empty, so its rows and
// degrees are the base's, and so are its edge indices (edgeIndexBound, edgeIndex(of:),
// incidentEdgeIndices) and flat rows (_withSuccessorIndexRows, _withIncidentIndexRows).
extension SubgraphView {
    // Rows shared by both directions, generic over the base's index row and position row:
    public struct IndexRow<Indices: Sequence<Int>, Positions: Sequence>: Sequence      // renumbered
    public struct EdgeRow<Indices: Sequence<Int>, Positions: Sequence>: Sequence       // positions
    public struct EdgeIndexRow<Indices: Sequence<Int>, Positions: Sequence, BaseEdgeIndices: Sequence<Int>>: Sequence
                                                                                       // ranks, or the base's row
}
// An IndexRow holds the base's index row, its position row (only under an edge set) and one
// _RowState reference. _forEachSuccessorIndex, _forEachPredecessorIndex and _forEachNeighborIndex
// loop over the base's rows in place, reading the mask's words at the base's edge index. With an
// edge set, once they have walked n/16 rows, the view builds compact kept rows (_KeptRows, O(n +
// kept) memory, one O(n + m) pass, shared by copies) and walks those, one row per vertex instead
// of the base's index row and edge-index row.
extension SubgraphView: DirectedGraph where Base: DirectedGraph
    // Vertices: LazyMapCollection<Range<Int>, Base.Vertex>; Edges: DirectedEdges (base positions);
    // SuccessorIndices: IndexRow<Base.SuccessorIndices, Base.OutEdges>;
    // OutEdges: EdgeRow<Base.SuccessorIndices, Base.OutEdges>; Successors: a lazy map of IndexRow.
extension SubgraphView: BidirectionalDirectedGraph where Base: BidirectionalDirectedGraph
    // The same over Base.PredecessorIndices and Base.InEdges.
extension SubgraphView: Graph where Base: Graph
    // Edges: UndirectedEdges; NeighborIndices: IndexRow<Base.NeighborIndices, Base.IncidentEdges>;
    // IncidentEdges: EdgeRow<…>; IncidentEdgeIndices: EdgeIndexRow<…, Base.IncidentEdgeIndices>
    // (each kept position's rank, or the base's row when the view keeps everything).

// MARK: Complement
extension DirectedGraph { public var complementView: ComplementView<Self> { get } }  // O(1)
extension Graph { public var complementView: ComplementView<Self> { get } }
@frozen public struct ComplementView<Base>: GraphAdaptor {
    public let base: Base
    @frozen public struct Cell: Hashable, Comparable, Sendable {   // Edges.Index, both directions
        public let source: Int, target: Int                      // undirected: source < target
        public init(source: Int, target: Int)
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
    public static func rootedProduct<H: DirectedGraph>(_ g: some DirectedGraph, _ h: H, root: H.Vertex) -> Self  // also checkedRoot: throws(VertexNotFound)
    public static func coronaProduct(_ g: some DirectedGraph, _ h: some DirectedGraph) -> Self
    public static func join(_ g: some DirectedGraph, _ h: some DirectedGraph) -> Self
}
extension _GraphConstruction { /* the same four over Graph */ }

// MARK: Ego graph
extension DirectedGraph {
    public func egoGraphView(of center: Vertex, radius: Int = 1) -> SubgraphView<Self>
    public func egoGraphView(checkedOf center: Vertex, radius: Int = 1) throws(VertexNotFound) -> SubgraphView<Self>
    public func egoGraphView(of centers: some Sequence<Vertex>, radius: Int = 1) -> SubgraphView<Self>
    public func egoGraphView<S: Comparable>(of centers: some Sequence<Vertex>, radius: Int = 1, maximumVertexCount: Int, priority: (Vertex) -> S) -> SubgraphView<Self>
    // and their checkedOf: forms; BidirectionalDirectedGraph adds undirected: to each
}
extension BidirectionalDirectedGraph {
    public func egoGraphView(of center: Vertex, radius: Int = 1, undirected: Bool) -> SubgraphView<Self>
    public func egoGraphView(checkedOf center: Vertex, radius: Int = 1, undirected: Bool) throws(VertexNotFound) -> SubgraphView<Self>
}
extension Graph { /* egoGraphView(of:radius:) and egoGraphView(checkedOf:radius:) */ }

// MARK: Materialized in index space
extension _DirectedGraphConstruction {
    public static func power<G: DirectedGraph>(of graph: G, _ k: Int) -> Self
    public static func contraction<G: DirectedGraph>(of graph: G, _ u: G.Vertex, _ v: G.Vertex) -> Self
    public static func contraction<G: DirectedGraph>(of graph: G, checked u: G.Vertex, _ v: G.Vertex) throws(VertexNotFound) -> Self
    public static func contraction<G: DirectedGraph>(of graph: G, edgeAt position: G.Edges.Index) -> Self
    public static func transitiveClosure<G: DirectedGraph>(of graph: G) -> Self
    public static func transitiveReduction<G: DirectedGraph>(of graph: G) -> Self
    public static func relabeled<G: DirectedGraph>(_ graph: G, ordering: some Sequence<G.Vertex>) -> Self
}
extension _GraphConstruction { /* power, the three contractions and relabeled(_:ordering:) over Graph */ }

// MARK: Materialized with labels
extension MutableDirectedGraph {
    public static func relabeled<G: DirectedGraph>(_ graph: G, by transform: (G.Vertex) -> Vertex) -> Self
    public static func union(_ g: some DirectedGraph<Vertex>, _ h: some DirectedGraph<Vertex>) -> Self
    public static func intersection(_ g: some DirectedGraph<Vertex>, _ h: some DirectedGraph<Vertex>) -> Self
    public static func difference(_ g: some DirectedGraph<Vertex>, _ h: some DirectedGraph<Vertex>) -> Self
    public static func symmetricDifference(_ g: some DirectedGraph<Vertex>, _ h: some DirectedGraph<Vertex>) -> Self
}
extension MutableGraph { /* the same five over Graph */ }
extension DirectedAcyclicGraph where Base: _DirectedGraphConstruction {
    public init<G>(_ condensation: Condensation<G>)
}
```

`SubgraphView` and `ComplementView` conform conditionally to both `DirectedGraph` and `Graph`.
Each constrained extension declares its own `Edges` typealias and members. No view is ever both,
because no base is.

Result numbering:

- Line graph: vertex `k` is the edge with `edgeIndex` `k`, or the `k`th position of `edges` when
  the graph has no edge indices. That second case costs one hash per edge.
- Quotient: vertex `i` is block `i`.
- Disjoint union and join: `g`'s vertex index `i` is `i`, and `h`'s `j` is `|V(g)| + j`.
- Power, transitive closure and reduction: vertex `i` is the graph's vertex at index `i`.
- Contraction: the merged vertex takes the smaller of the two indices; the vertices after the
  larger one move down by one.
- `relabeled(_:ordering:)`: vertex `i` is `ordering[i]`; the ordering is the label table.
- `relabeled(_:by:)`: the distinct names in vertex order, each at its first occurrence; the edges
  inserted in `edges` order, renamed. Equal names merge (an edge between them becomes a
  self-loop); a simple target keeps the first of coinciding edges, a pseudograph all of them.
- Union and symmetric difference: `g`'s vertices, then `h`'s that `g` lacks; intersection, the
  shared ones in `g`'s order; difference, `g`'s. Equal vertices are one vertex, so the vertex sets
  may overlap (NetworkX's `compose`; `disjointUnion` keeps them apart). Edges are sets, inserted
  in row-major order of the result's vertices, undirected with the earlier end first; self-loops
  are edges like any other. Difference and symmetric difference accept different vertex sets.

## Semantics, preconditions and traps

| Case | Behaviour | Rows |
|---|---|---|
| `inducedSubgraphView(on:)` / `subgraph` with a vertex not in the base | **Trap** | GO-022, GO-044 |
| A position not in the base | **Trap** | GO-036, GO-045 |
| Repeated vertex or position | Set semantics; the hash count still counts each listed occurrence | GO-014, GO-020, GO-032 |
| `subgraphView(vertices:edges:)` edge with an end outside the vertex set | Dropped | GO-040, GO-041 |
| A base vertex outside the view | `contains` is false; `vertexIndex(of:)` and the rows trap | GO-023, GO-024 |
| Base with `vertexIndexBound == nil` (`StableDirectedGraph` with holes) | **Trap** at construction | GO-025, GO-063 |
| `TransposedView` over a non-bidirectional base | Does not compile | — |
| `complementView`: self-loops, parallel edges | Ignored; the complement is simple and loop-free | GO-053, GO-054, GO-060 |
| Undirected self-loop in a subgraph | Listed twice in its row, as in the base | GO-027, GO-038 |
| Directed line graph with a self-loop | **Trap** | GO-070 |
| Undirected line graph with a self-loop | The loop is adjacent to the other edges at its vertex; no loop in L | GO-076 |
| `quotient`: vertex in two blocks, a vertex in no block, a label not in the graph | **Trap** | GO-092 – GO-094 |
| `quotient`: an empty block | An isolated vertex | GO-091 |
| `quotient`: edges inside a block | Dropped, with no self-loops | GO-086 |
| `disjointUnion` / `join` with a self-loop | **Trap** | GO-099, GO-105 |
| `rootedProduct` / `coronaProduct` with a self-loop, or a root not in `h` | **Trap**; `checkedRoot:` throws `VertexNotFound` | GO-196, GO-197, GO-204 |
| Mutating the base after making a view | Impossible: the view holds a copy, so mutating the original never shows through | — |
| `spanningSubgraphView` / `subgraph` over a base without edge indices | Sorted kept positions, binary search per row entry and per rank; dense edge indices still | hand-written test |
| A materialized operation over a graph without vertex indices | **Trap**, like the views | GO-118, extra traps |
| `egoGraphView`: a center not a vertex, negative radius, negative maximum vertex count | **Trap**; `checkedOf:` throws `VertexNotFound` for a center | GO-116, GO-117, GO-186, GO-187 |
| `power(of:_:)` with k < 1 | **Trap** | GO-127, extra traps |
| `power`: self-loops, parallel edges | Ignored | GO-121, GO-126 |
| `contraction`: a vertex not in the graph | **Trap**; `checked:` throws `VertexNotFound` | GO-133 |
| `contraction`: edges between the two, other self-loops | Dropped (the targets take no loops); `u == v` is a copy | GO-130, GO-132, GO-137 |
| `transitiveClosure`: a vertex on a cycle | No self-loop (not reflexive) | GO-140, GO-142 |
| `transitiveReduction` on a graph with cycles | Each component of two or more a cycle in index order; one arc between first members per condensation-reduction arc (Aho, Garey and Ullman); a subgraph only on acyclic input | GO-146 – GO-149 |
| `relabeled(_:ordering:)`: a vertex listed twice, a vertex missing, a self-loop | **Trap** | GO-154 – GO-156 |

## Complexity

n and m are the base's counts, and k is the number of kept vertices.

| Member | `TransposedView` | `SubgraphView` | `ComplementView` |
|---|---|---|---|
| Build | O(1) | induced: O(n + listed), plus one hash per listed vertex; spanning: O(m/64 + listed); both: the sum | O(1) |
| Row (`successorIndices`, `outEdges`, …) | the base's in-row | base row length; one load and a branch per entry | O(n/64 + output), one allocation of ⌈n/64⌉ words |
| `outDegree(ofIndex:)` | base `inDegree` | O(base degree) | O(deg + n/64) |
| `vertexIndex(of:)` | the base's | the base's plus one load | the base's |
| `edgeCount` | O(1) | O(1) with an edge set; induced: O(Σ base out-degree of kept vertices) | O(n + m) |
| `edgeIndexBound` | the base's | the kept count with an edge set; induced, the base's on every vertex, otherwise `nil` | `nil` |
| `contains(edge:)` | base, flipped | base, both ends kept; with an edge set, a scan of the source's row | base, negated |

| Materialized | Time | Memory |
|---|---|---|
| `lineGraph`, directed | O(m + \|E(L)\| + Σ row sorts) | the target |
| `lineGraph`, undirected | O(Σᵥ deg(v)² + sorts), with a stamp array for deduplication | O(m) scratch |
| condensation → DAG | O(k + e) after `condensation()` | the target |
| `quotient` | O(n + m + sort), one hash per listed vertex | O(n) |
| `disjointUnion`, `join` | O(n + m), join + O(\|V(g)\|·\|V(h)\|) | the target |
| `rootedProduct`, `coronaProduct` | O(\|V(g)\|·(\|V(h)\| + \|E(h)\|) + \|E(g)\|) | the target |
| `power(of:_:)` | O(n · (n + m)) worst case, a search per vertex stopped after k layers | O(n) scratch |
| `contraction` | O(n + m + row sorts), one hash per named vertex | O(n) |
| `transitiveClosure` | O(n + m + k·e/64 + output and its sorts), k components, e arcs between them | k²/8 bytes |
| `transitiveReduction` | O(n + m + k·e/64) | k²/8 bytes |
| `relabeled(_:ordering:)` | O(n + m + row sorts), one hash per listed vertex | O(n) |
| `relabeled(_:by:)` | O(n + m), one hash per vertex plus the target's insertions | O(n + m) |
| `union`, `intersection`, `difference`, `symmetricDifference` | O(n + m + row sorts), one lookup in `g` per vertex of `h`, plus the target's insertions | O(n + m) |
| `egoGraphView` | O(n + rows walked) to build, one hash for the center | O(n) |

## Implementation notes

- Row sequences are concrete structs that hold the base row and read `_new` / `_old` by index,
  not `lazy.map` closures capturing `self`, which would copy the view's base on every call.
- `_withSuccessorIndexRows` and `_withIncidentIndexRows` return `nil` on every view here, with one
  exception. Their contract forbids forwarding through a view that changes incidence, and a
  `TransposedView`'s rows are not the base's out-rows. An induced subgraph that keeps every vertex
  leaves `_old` and `_new` empty and has no edge set, so its rows, positions and edge indices are
  the base's. It forwards `_withSuccessorIndexRows`, and undirected `_withIncidentIndexRows`,
  `edgeIndexBound`, `edgeIndex(of:)` and `incidentEdgeIndices(ofIndex:)`.
- The edge set is a class (`_EdgeTest<Position>`, subclassed per base) held once by the view, so a
  row holds one optional reference rather than a copy of the base.
- Every requirement with a default is implemented by forwarding, so the base's own member is the
  one called.
- Each view is a `GraphAdaptor` whose generation is its base's. `TransposedView` and
  `SubgraphView` keep the base's positions and read the base's vertex and edge maps;
  `ComplementView` reads vertex maps only.
