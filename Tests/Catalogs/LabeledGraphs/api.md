# LabeledGraphs: proposed API (phase 1)

`CompressedSparseRow` and `AdjacencyMatrix` take only `Int` vertices `0..<n`. Their layouts are
built on vertex numbers, so they cannot take `Hashable` vertices the way `AdjacencyList` does
(README open question 2). `LabeledGraph<Label, Base>` puts labels on top of one of them. It stores
an `OrderedSet<Label>` whose element `i` names base vertex `i`. It conforms to `DirectedGraph`
(and `BidirectionalDirectedGraph`) with `Vertex == Label`, so algorithms take and return labels.
Every index-space member forwards to the base, so an algorithm runs on the base's rows and hashes
labels only at its inputs.

`cases.md` (LG-001 – LG-086, 86 rows) pins the values. `ref.py` ports the storage over ports of
the CSR and matrix bases, and counts every label hash. Each state is checked against:

- a NetworkX 3.7 spec keyed by label;
- the `convert_node_labels_to_integers(ordering="default", label_attribute=...)` /
  `relabel_nodes` round trip, which must give back the base and the labeled graph;
- the protocol laws;
- the boundary laws. Index-space and whole-graph reads hash nothing. A label-space read hashes
  once. `descendants(of:)` makes one lookup, plus one hash per vertex inserted into the returned
  `Set`. `topologicalSort()` hashes nothing and equals the base's
  result mapped through the labels.

`--stress` runs 400 seeded mutation sequences of 50 steps on the matrix base and 200 random builds
of each kind. Two planted model bugs were caught: successor indices taken through label lookups
(the hash law failed), and a label array that did not follow an insertion (the spec failed).

To run it:
`uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/LabeledGraphs/ref.py [--write] [--stress]`.

## Names

| Name | Decision | Source |
|---|---|---|
| Type | **`LabeledGraph<Label, Base>`** (README Structures row) | BGL's `labeled_graph<Graph, Label, Selector>` |
| Module | **`LabeledGraphs`** (exists as a stub) | README package layout |
| Label ↔ index | **`vertexIndex(of:)` / `vertex(atIndex:)`**, the existing `DirectedGraph` members. The label *is* the vertex, so there is no `label(of:)` and no `index(of:)` alias | GraphProtocols |
| Base access | **`base`** (read-only), as `UndirectedView`/`DirectedView` name it and BGL's `labeled_graph::graph()` provides | README open question 9; BGL |
| Non-trapping | **`vertexIndex(checked:)`**, plus the `checked:` row lookups of Principle 6, throwing `VertexNotFound` | README Principle 6 |

## Storage

```swift
@frozen
public struct LabeledGraph<Label: Hashable, Base> {
    @usableFromInline internal var _labels: OrderedSet<Label>   // element i names base vertex i
    @usableFromInline internal var _base: Base
}
```

`OrderedSet` *is* the design the plan named (a dense array plus a bit-packed hash table), and
swift-collections is already a dependency (open question 4). In the checkout under `.build`:

- `firstIndex(of:)` costs O(1) expected comparisons;
- `append` is amortized O(1);
- `swapAt` is O(1) when storage isn't shared;
- `removeLast()` is O(1).

Swap-remove on the label map (below) is `swapAt(i, count - 1)` followed by `removeLast()`.

**The base invariant: `base.vertices` is exactly `0..<n` in index order, so
`base.vertexIndex(of: i) == i`.** This is the precondition `CompressedSparseRow.init(_:)` already
states. It lets `edges`, `source` and `target` map through `_labels[i]` (an array read) and never
call the base's own vertex lookup. `init(_:labels:)` checks the invariant in O(n), next to the
O(n) hashing of the labels.

Package changes for the implementation are out of scope here. `LabeledGraphs` would add
`OrderedCollections`, `CompressedSparseRowModule` and `AdjacencyMatrixModule` (for the per-base
initializers and mutation) to its dependencies. The representations do not depend back on it.

## API

n = vertices, m = edges, d = the row's degree. "Expected" means hashing.

### Construction

```swift
extension LabeledGraph where Base: DirectedGraph<Int> {
    /// labels[i] names base vertex i.
    public init(_ base: Base, labels: some Sequence<Label>) throws(LabelingError)   // O(n) expected
}
extension LabeledGraph where Base == CompressedSparseRow {
    public init()
    public init(vertices: some Sequence<Label>)
    public init(edges: some Sequence<DirectedEdge<Label>>)
    public init(vertices: some Sequence<Label>, edges: some Sequence<DirectedEdge<Label>>)  // O(n + m) expected
    public init(_ graph: some DirectedGraph<Label>)   // = init(vertices: graph.vertices, edges: graph.edges)
}
extension LabeledGraph where Base == AdjacencyMatrix {
    // the same five; O(n² / 64 + m) expected
}
```

- **Index assignment.** The listed vertices come first, then new endpoints in first-appearance
  order. A repeated label is inserted once. This is NetworkX's
  `convert_node_labels_to_integers(ordering="default")` applied to `add_nodes_from` followed by
  `add_edges_from` (`check` asserts it every state, LG-003, LG-004, LG-009).
- **Parallel edges** collapse, because both bases store a set (LG-005, LG-011, LG-015).
- **Positions are the base's.** CSR's are `Int`s in row-major order of the *indices*, not of the
  input (LG-013). The matrix's are `(source, target)` cells (LG-014).
- **`init(_:labels:)` throws `LabelingError`** (decided 2026-10-11, replacing traps; the shape of
  `CompressedSparseRow.ValidationError`), the first requirement broken, checked in this order:
  - `.baseNotDenselyIndexed`: `base.vertexIndexBound == nil`, as on a `StableDirectedGraph` with
    holes (LG-023);
  - `.baseVerticesNotInIndexOrder`: the base vertices are not `0..<n` in index order (LG-021,
    LG-022);
  - `.labelCountMismatch(labelCount:vertexCount:)`: the label count differs from
    `base.vertexCount` (LG-018, LG-019);
  - `.duplicateLabel(position:)`: the label at that offset repeats an earlier one (LG-020).
  Decoding reports the same failures as `DecodingError.dataCorrupted`.

### Reads (`Base: DirectedGraph<Int>`)

```swift
extension LabeledGraph: DirectedGraph where Base: DirectedGraph<Int> {
    public typealias Vertex = Label
    public typealias Vertices = OrderedSet<Label>
    public typealias Successors = LazyMapSequence<Base.SuccessorIndices, Label>
    public typealias OutEdges = Base.OutEdges
    public typealias SuccessorIndices = Base.SuccessorIndices      // overrides the hashing default
    public struct Edges: Collection { Index = Base.Edges.Index, Element = DirectedEdge<Label> }
                                    // BidirectionalCollection / RandomAccessCollection when Base.Edges is

    public var base: Base { get }                                  // O(1)
    public var vertices: OrderedSet<Label> { get }                 // O(1)
    public var edges: Edges { get }                                // O(1); edges[p] O(1), no hashing
    public func successors(of: Label) -> Successors                // O(1) expected + lazy
    public func outEdges(of: Label) -> OutEdges                    // O(1) expected
    public func outDegree(of: Label) -> Int                        // O(1) expected + base's
    public func source(ofEdgeAt: Base.Edges.Index) -> Label        // base's, no hashing
    public func target(ofEdgeAt: Base.Edges.Index) -> Label
    public var vertexCount: Int { get }; public var edgeCount: Int { get }   // base's
    public func contains(_: Label) -> Bool                         // O(1) expected
    public func contains(edge: DirectedEdge<Label>) -> Bool        // 2 hashes + base's contains(edge:)
    public var vertexIndexBound: Int? { get }                      // base's (always non-nil)
    public func vertexIndex(of: Label) -> Int                      // O(1) expected; traps on a non-vertex
    public func vertex(atIndex: Int) -> Label                      // O(1); traps out of 0..<n
    public func successorIndices(ofIndex: Int) -> Base.SuccessorIndices   // base's
    public func outEdges(ofIndex: Int) -> OutEdges                 // base's
    public var edgeIndexBound: Int? { get }                        // base's (CSR m, matrix nil)
    public func edgeIndex(of: Base.Edges.Index) -> Int             // base's (traps on the matrix, LG-048)
    public func _withSuccessorIndexRows<R>(_ body: ...) -> R?      // base's (CSR's offsets/targets)
}
extension LabeledGraph: BidirectionalDirectedGraph where Base: BidirectionalDirectedGraph<Int> {
    Predecessors = LazyMapSequence<Base.PredecessorIndices, Label>; InEdges = Base.InEdges;
    PredecessorIndices = Base.PredecessorIndices
    predecessors(of:), inEdges(of:), inDegree(of:), degree(of:)    // one hash each
    predecessorIndices(ofIndex:), inEdges(ofIndex:)                // base's
}
```

Every label-space member looks the label up once and then reads the base by index
(`_labels.firstIndex(of:)`, trapping with "`\(label)` is not a vertex of the graph"). Results
come back in the base's row order: ascending index for both bases (LG-025, LG-035, LG-050).

**`checked:` variants (Principle 6).** Each throws `VertexNotFound` for a label that is not a
vertex and costs the one hash of its trapping spelling:

- `vertexIndex(checked:) throws(VertexNotFound) -> Int`;
- `successors(checked:)`, `outEdges(checked:)`, `outDegree(checked:)`;
- with a bidirectional base: `predecessors(checked:)`, `inEdges(checked:)`, `inDegree(checked:)`
  and `degree(checked:)`.

`vertex(atIndex:)` has no `checked:` spelling, because `0..<vertexCount` is a range check the caller
can make. The rows are LG-027, LG-029, LG-037, LG-039 and LG-051.

**Traps.** These are preconditions:

- a label-space member on a non-vertex (LG-030 – LG-032, LG-040 – LG-042, LG-052, LG-061);
- `vertex(atIndex:)` out of range (LG-033, LG-034);
- an edge position that is not an edge (LG-046, LG-049);
- the base's own `edgeIndex(of:)` trap (LG-048).

**Undirected.** `labeled.undirected` is `UndirectedView<LabeledGraph<…>>`, a `Graph<Label>` for
free when the base is bidirectional. Its label-space reads hash twice, because the view calls
`successors` and `predecessors`. Its index-space reads hash nothing. `oppositeVertex` compares
labels with `==` (LG-062 – LG-068). Phase 1 has no `Graph` conformance of its own; see open
question 1.

### Mutation (`Base == AdjacencyMatrix`)

```swift
extension LabeledGraph where Base == AdjacencyMatrix {
    @discardableResult public mutating func insert(_ label: Label) -> (inserted: Bool, memberAfterInsert: Label)
        // appends base vertex n: amortized O(n / 64) (the base's appendVertex) + O(1) expected
    @discardableResult public mutating func insert(edge: DirectedEdge<Label>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Label>)
        // inserts a missing endpoint, source first (NetworkX add_edge; README row "Incremental")
    @discardableResult public mutating func insert(checked edge: DirectedEdge<Label>) throws(VertexNotFound) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Label>)
        // throws, changing nothing, unless both endpoints are vertices
    @discardableResult public mutating func remove(edge: DirectedEdge<Label>) -> DirectedEdge<Label>?
        // nil for a non-edge, including a non-vertex endpoint (the base's remove(edge:) contract)
    @discardableResult public mutating func removeEdges(from: Label) -> Int          // also (to:), (incidentTo:); trap on a non-vertex
    @discardableResult public mutating func removeEdges(checkedFrom: Label) throws(VertexNotFound) -> Int
        // also (checkedTo:), (checkedIncidentTo:): throw, changing nothing, for a non-vertex (LG-097, LG-098)
    public mutating func removeAllEdges(keepingCapacity: Bool = false)   // labels kept
    public mutating func removeAll(keepingCapacity: Bool = false)        // labels and base cleared
    public mutating func reserveCapacity(vertexCount: Int)
}
```

The rows are LG-069 – LG-081. Copy-on-write comes from the two stored values. `base` is
read-only: a `_modify` on it would let a caller add base vertices without labels.

**Vertex removal is not in phase 1.** `AdjacencyMatrix` has no vertex removal, and CSR is
immutable. The rule for any future base that removes a vertex by swap-remove (index `n-1` moves
into the hole) is fixed now: the label map follows with `_labels.swapAt(i, n - 1);
_labels.removeLast()`, in the same mutation, at O(1) expected. LEMON's `RangeIdMap` does exactly
this on erase (`_inv_map[Map::operator[](item)] = _inv_map.back()`; it documents "the ids can
change when deleting an item"). The base's attached maps already make the same move.

### Conformances

- **`Equatable` where `Base: Equatable`.** Two labeled graphs are equal when they have equal label
  sets and equal labeled edge sets, whatever the index assignment (LG-082 – LG-086). This is
  `AdjacencyList`'s rule ("insertion order does not matter"). The fast path: when the two
  `_labels` are equal in order, compare `base == base`. Otherwise:
  1. check the label sets, O(n) expected;
  2. map the other graph's indices into this one's, n hashes;
  3. check every mapped edge with the base's `contains(edge:)`: O(m log d) for CSR, O(m) for the
     matrix.
- **`Hashable`** (added after the critical review): an order-independent hash, consistent with
  `==`. It combines the counts, the sum of the labels' hash values, and the sum over the edges of a
  hash of the two ends' hash values, so each label is hashed once and no label per edge.
- **`Sendable`** where `Label` and `Base` are.
- **`Codable`** where both are, as `{labels, base}`. Decoding re-checks the init preconditions
  as `DecodingError.dataCorrupted`.
- **`CustomStringConvertible`**, which prints labeled edges.

## Performance

The targets, measured against the bare base (a benchmark target; per the test policy, the
counters below are not public API):

| Measure | Target |
|---|---|
| Label hashes in an index-space algorithm (`topologicalSort`, components, Dijkstra through `_DenseVertices`/`_VertexIdentifiers`) | **0 per edge**. Inputs hash once each; results are array reads (`_labels[i]`), except where the algorithm's own result type is a `Set`/`Dictionary` of vertices, which hashes once per output vertex, as on any `Hashable` graph |
| Wall time, `breadthFirstLayers` / weak and strong components / Dijkstra on CSR (10⁵ vertices, 10⁶ edges), String labels | ≤ 1.05× the same call on the bare `CompressedSparseRow`, plus the output mapping |
| Same on `AdjacencyMatrix` (4 096 vertices, 10⁶ edges) | ≤ 1.05× |
| The lazy `breadthFirstSearch(from:)` sequence | 1.7–1.8× the bare base: every event carries two labels (a tree edge's ends), each an array read and a retain, where the bare base's events carry two `Int`s |
| `successors(of:)` | one hash, then the base's row; the result holds the row and the labels, with nothing allocated |
| Building from labeled edges | ≤ 1.3× `AdjacencyList<Label>(edges:)` for the hashing, plus the base's own build |

**How the index-space helpers see through.** `vertexIndexBound` is always non-nil, so both
`_DenseVertices` and `_VertexIdentifiers` take their `isIndexed` path. They number vertices by
`vertexIndex(of:)` (one hash at the boundary) and walk `successorIndices(ofIndex:)`. Read:
`Sources/Connectivity/DenseVertices.swift` and `Sources/GraphProtocols/VertexIdentifiers.swift`.
The pieces:

- `_vertexNumbering()` and `_listedVertices()` return `nil` when the bound is non-nil, so they
  never build a dictionary.
- `_withSuccessorIndexRows` forwards to CSR's offsets and targets (on the matrix it returns
  `nil`, the matrix's own behavior).
- `_numberedRows` is not involved, because `LabeledGraph` is never sparsely indexed.

The one trap is the protocol default. Unless `SuccessorIndices` (and `PredecessorIndices`) are
bound to the base's, the default `successorIndices(ofIndex:)` maps `successors(of:)` back through
`vertexIndex(of:)`, which costs one hash *per edge*. `ref.py` plants exactly this bug and the hash
law catches it. The Swift suite needs one benchmark-only check with a counting `Label`.

## Prior art (verified 2026-10-10)

| Library | What it does | Taken |
|---|---|---|
| BGL `labeled_graph<Graph, Label, Selector>` (`boost/graph/labeled_graph.hpp`) | An adaptor over a graph. It keeps label → descriptor in a vector (unsigned integral labels) or a `std::map`/`unordered_map` (`mapS`, `hash_mapS`). It has `add_vertex(label)`, `insert_vertex(label)`, `vertex(label)`, `remove_vertex(label)` and `graph()` for the base. Its vector-mode removal erases from the middle and shifts later labels | The adaptor shape and `base`. Not the shifting removal |
| NetworkX `convert_node_labels_to_integers(G, first_label, ordering, label_attribute)` / `relabel_nodes(G, mapping)` | Labels ↔ `0..<n`, by node order with `ordering="default"`. `ref.py` calls both every state | Index assignment = node order; the round trip as a law |
| LEMON `RangeIdMap` / `CrossRefMap` (`lemon/maps.h`, 1.3.1) | `RangeIdMap` keeps ids dense in `0..<n`; "the ids can change when deleting an item", and erase moves the largest id into the hole. Both maps are invertible (`InverseMap`, `operator()`) | The swap-remove rule for the label map; index ↔ label in both directions |
| igraph (python-igraph tutorial) | The `name` attribute is indexed for amortized O(1) lookup, accepted wherever an ID is, and "maintained transparently … whenever the graph changes". Uniqueness is *not* enforced | Labels accepted by every algorithm; we enforce uniqueness (LG-020) |
| JGraphT `VertexToIntegerMapping` | "A one-to-one mapping for a collection of vertices to the integer range [0, n)", with `getVertexMap()` and `getIndexList()` | The same pair, which is `OrderedSet`'s two halves |
| petgraph `GraphMap` versus `Graph` | `GraphMap` uses node values as identifiers (`N: Copy + Ord + Hash`, hash-table lookups everywhere). `Graph` uses `NodeIndex` | Ours is the third option: hash at the boundary, indices inside |

## Open questions (with recommendations)

1. **Which bases?** *Recommendation:* conform for any `Base: DirectedGraph<Int>` whose vertices
   are `0..<n` in index order (`LabelingError` at init), and give construction and mutation for
   `CompressedSparseRow` and `AdjacencyMatrix` only. Those are the representations that cannot
   take labels themselves.
   - `AdjacencyList<Int>`, `DirectedPseudograph<Int>` and `StableDirectedGraph<Int>` already hash
     their `Int` vertices to slots (`_slots[vertex]`). Labeling them hashes twice at every
     boundary call. They should be used as `AdjacencyList<Label>` and so on directly, and are
     accepted only through `init(_:labels:)`.
   - Undirected: phase 1 uses `labeled.undirected`. A `Graph` conformance of its own waits for an
     `Int`-only undirected representation (the `IncidenceMatrixModule` stub). `UndirectedAdjacencyList`
     and `Pseudograph` take labels already.
   - Implementation note for that later step: `LabeledGraph` cannot nest an `Edges` type in both
     a `DirectedGraph` and a `Graph` constrained extension, so the undirected edge view will need
     its own nested name.
2. **Mutation.** *Recommendation:*
   - immutable over CSR (rebuild through `init(_ graph:)`);
   - over the matrix, append-only vertices plus edge insert and remove;
   - the swap-follow rule above, fixed now for any future base that swap-removes vertices.

   **Over `StableDirectedGraph`: not useful, so don't offer it.** Its slots have holes
   (`vertexIndexBound == nil`), so a dense label array cannot mirror them. A label table with
   holes would just re-implement `StableDirectedGraph<Label>`, which already does what a
   labeled-stable graph would do:
   - it hashes the label once per boundary call (`_slots`);
   - its overridden `_numberedRows` numbers live vertices from slots without hashing;
   - its `EdgeMap`/`VertexMap` already key by position.

   Layering would cost a second hash per boundary call (Label → Int → slot) and gain nothing.
   Rule of thumb:
   - `StableDirectedGraph<Label>` when identities must survive removal;
   - `DirectedPseudograph<Label>` / `AdjacencyList<Label>` for a mutable graph with labels;
   - `LabeledGraph<Label, CompressedSparseRow>` for a read-mostly graph where traversal speed
     matters;
   - `LabeledGraph<Label, AdjacencyMatrix>` for dense graphs.
3. **Surface.** *Recommendation:* as above. The label is the vertex, conversions are the existing
   `vertexIndex(of:)` / `vertex(atIndex:)` plus `vertexIndex(checked:)`, and `base` is read-only.
   No public `labels` property, since `vertices` is the `OrderedSet`.
4. **Performance.** *Recommendation:* forward the index-space members and bind the index
   associated types to the base's. This is the whole mechanism, so there is no special case in
   any algorithm. Add one benchmark-target check with a hash-counting `Label`.
5. **The adaptor protocol (README open question 9).** `LabeledGraph` already has the shape:
   - it stores `base` and exposes it as `var base: Base { get }`;
   - it forwards every index member;
   - its positions are the base's (`Edges.Index == Base.Edges.Index`, vertex index == base
     index), so the base's attached maps work through it unchanged.

   When the protocol lands, it adopts it and the forwarding moves into the protocol's default
   implementations. Only the label-space members and the label map stay in this type. Nothing is
   built now.
6. **Relabeling** (NetworkX `relabel_nodes`, giving a new label type over the same base): useful
   but deferred. NetworkX merges nodes when the mapping isn't injective; we would trap. It is an
   O(n) rebuild of the `OrderedSet` with the base shared.
