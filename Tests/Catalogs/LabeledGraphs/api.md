# LabeledGraphs: API

`CompressedSparseRow` and `AdjacencyMatrix` take only `Int` vertices `0..<n`, because their layouts
are built on vertex numbers. `LabeledGraph<Label, Base>` puts `Hashable` labels on top of one of
them. It stores an `OrderedSet<Label>` whose element `i` names base vertex `i`, and conforms to
`DirectedGraph` (and `BidirectionalDirectedGraph`) with `Vertex == Label`, so algorithms take and
return labels. Every index-space member forwards to the base, so an algorithm runs on the base's
rows and hashes labels only at its inputs.

`cases.md` pins the values. `ref.py` ports the storage over ports of the CSR and matrix bases and
counts every label hash. Each state is checked against:

- a NetworkX 3.7 spec keyed by label;
- the `convert_node_labels_to_integers(ordering="default", label_attribute=...)` /
  `relabel_nodes` round trip, which must give back the base and the labeled graph;
- the protocol laws;
- the boundary laws. Index-space and whole-graph reads hash nothing. A label-space read hashes
  once. `descendants(of:)` makes one lookup, plus one hash per vertex inserted into the returned
  `Set`. `topologicalSort()` hashes nothing and equals the base's result mapped through the labels.

`--stress` runs 400 seeded mutation sequences of 50 steps on the matrix base and 200 random builds
of each kind.

To run it:
`uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/LabeledGraphs/ref.py [--write] [--stress]`.

## Names

| Name | Spelling |
|---|---|
| Type | `LabeledGraph<Label, Base>` in the module `LabeledGraphs` |
| Label ↔ index | `vertexIndex(of:)` / `vertex(atIndex:)`, the `DirectedGraph` members. The label is the vertex, so there is no `label(of:)` and no `index(of:)` |
| Base access | `base`, read-only |
| Non-trapping | `vertexIndex(checked:)` and the `checked:` row lookups, throwing `VertexNotFound` |

## Storage

```swift
@frozen
public struct LabeledGraph<Label: Hashable, Base> {
    @usableFromInline internal var _labels: OrderedSet<Label>   // element i names base vertex i
    @usableFromInline internal var _base: Base
}
```

`OrderedSet.firstIndex(of:)` costs O(1) expected comparisons and `append` is amortized O(1).

The base invariant is that `base.vertices` is exactly `0..<n` in index order, so
`base.vertexIndex(of: i) == i`. It lets `edges`, `source` and `target` map through `_labels[i]`, an
array read, without calling the base's own vertex lookup. `init(_:labels:)` checks the invariant in
O(n), next to the O(n) hashing of the labels.

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
  order. A repeated label is inserted once. `ref.py` checks this against NetworkX's
  `convert_node_labels_to_integers(ordering="default")` applied to `add_nodes_from` followed by
  `add_edges_from` in every state (LG-003, LG-004, LG-009).
- **Parallel edges** collapse, because both bases store a set (LG-005, LG-011, LG-015).
- **Positions are the base's.** CSR's are `Int`s in row-major order of the indices, not of the
  input (LG-013). The matrix's are `(source, target)` cells (LG-014).
- **`init(_:labels:)` throws `LabelingError`** for the first requirement broken, checked in this
  order:
  - `.baseNotDenselyIndexed`: `base.vertexIndexBound == nil`, as on a `StableDirectedGraph` with
    holes (LG-023);
  - `.baseVerticesNotInIndexOrder`: the base vertices are not `0..<n` in index order (LG-021,
    LG-022);
  - `.labelCountMismatch(labelCount:vertexCount:)`: the label count differs from
    `base.vertexCount` (LG-018, LG-019);
  - `.duplicateLabel(position:)`: the label at that offset repeats an earlier one (LG-020).

  Decoding reports the same failures as `DecodingError.dataCorrupted`.

`init(_:labels:)` accepts any dense `DirectedGraph<Int>` base. `AdjacencyList<Int>`,
`DirectedPseudograph<Int>` and `StableDirectedGraph<Int>` already hash their vertices to slots, so
labeling them hashes twice at every boundary call. Use `AdjacencyList<Label>` and the others with
the labels directly.

### Reads (`Base: DirectedGraph<Int>`)

```swift
extension LabeledGraph: DirectedGraph where Base: DirectedGraph<Int> {
    public typealias Vertex = Label
    public typealias Vertices = OrderedSet<Label>
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
    InEdges = Base.InEdges; PredecessorIndices = Base.PredecessorIndices
    predecessors(of:), inEdges(of:), inDegree(of:), degree(of:)    // one hash each
    predecessorIndices(ofIndex:), inEdges(ofIndex:)                // base's
}
```

Every label-space member looks the label up once with `_labels.firstIndex(of:)`, trapping with
"`\(label)` is not a vertex of the graph", and then reads the base by index. Results come back in
the base's row order, which is ascending index for both bases (LG-025, LG-035, LG-050).

**`checked:` variants.** Each throws `VertexNotFound` for a label that is not a vertex and costs the
one hash of its trapping spelling:

- `vertexIndex(checked:) throws(VertexNotFound) -> Int`;
- `successors(checked:)`, `outEdges(checked:)`, `outDegree(checked:)`;
- with a bidirectional base, `predecessors(checked:)`, `inEdges(checked:)`, `inDegree(checked:)`
  and `degree(checked:)`.

`vertex(atIndex:)` has no `checked:` spelling, because the caller can check `0..<vertexCount`. The
rows are LG-027, LG-029, LG-037, LG-039 and LG-051.

**Traps.** These are preconditions:

- a label-space member on a non-vertex (LG-030 – LG-032, LG-040 – LG-042, LG-052, LG-061);
- `vertex(atIndex:)` out of range (LG-033, LG-034);
- an edge position that is not an edge (LG-046, LG-049);
- the base's own `edgeIndex(of:)` trap (LG-048).

**Undirected.** `labeled.undirectedView` is `UndirectedView<LabeledGraph<…>>`, a `Graph<Label>`
when the base is bidirectional. Its label-space reads hash twice, because the view calls
`successors` and `predecessors`. Its index-space reads hash nothing. `oppositeVertex` compares
labels with `==` (LG-062 – LG-068).

### Mutation (`Base == AdjacencyMatrix`)

```swift
extension LabeledGraph where Base == AdjacencyMatrix {
    @discardableResult public mutating func insert(_ label: Label) -> (inserted: Bool, memberAfterInsert: Label)
        // appends base vertex n: amortized O(n / 64) (the base's appendVertex) + O(1) expected
    @discardableResult public mutating func insert(edge: DirectedEdge<Label>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Label>)
        // inserts a missing endpoint, source first
    @discardableResult public mutating func insert(checked edge: DirectedEdge<Label>) throws(VertexNotFound) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Label>)
        // throws, changing nothing, unless both endpoints are vertices
    @discardableResult public mutating func remove(edge: DirectedEdge<Label>) -> DirectedEdge<Label>?
        // nil for a non-edge, including a non-vertex endpoint
    @discardableResult public mutating func removeEdges(from: Label) -> Int          // also (to:), (incidentTo:); trap on a non-vertex
    @discardableResult public mutating func removeEdges(checkedFrom: Label) throws(VertexNotFound) -> Int
        // also (checkedTo:), (checkedIncidentTo:): throw, changing nothing, for a non-vertex (LG-097, LG-098)
    public mutating func removeAllEdges(keepingCapacity: Bool = false)   // labels kept
    public mutating func removeAll(keepingCapacity: Bool = false)        // labels and base cleared
    public mutating func reserveCapacity(vertexCount: Int)
}
```

The rows are LG-069 – LG-084, LG-097 and LG-098. Copy-on-write comes from the two stored values. `base` is
read-only, because a vertex added to the base directly would have no label.

Over CSR the graph is immutable and is rebuilt through `init(_ graph:)`. Neither base removes a
vertex, so a labeled graph has no vertex removal.

### Conformances

- **`Equatable`** where `Base: Equatable`. Two labeled graphs are equal when they have equal label
  sets and equal labeled edge sets, whatever the index assignment (LG-089 – LG-093). When the two
  `_labels` are equal in order, the bases are compared directly. Otherwise:
  1. the label sets are compared, O(n) expected;
  2. the other graph's indices are mapped into this one's, n hashes;
  3. every mapped edge is looked up with the base's `contains(edge:)`, O(m log d) for CSR and O(m)
     for the matrix.
- **`Hashable`**: an order-independent hash consistent with `==`. It combines the counts, the sum
  of the labels' hash values, and the sum over the edges of a hash of the two ends' hash values.
  Each label is hashed once and no label is hashed per edge.
- **`Sendable`** where `Label` and `Base` are.
- **`Codable`** where both are, as `{labels, base}`. Decoding checks the init requirements and
  reports a failure as `DecodingError.dataCorrupted`.
- **`CustomStringConvertible`**, which prints labeled edges.

## Index-space algorithms

`vertexIndexBound` is always non-nil, so both `_DenseVertices` and `_VertexIdentifiers` take their
indexed path. They number vertices by `vertexIndex(of:)`, one hash at the boundary, and walk
`successorIndices(ofIndex:)`. See `Sources/Connectivity/DenseVertices.swift` and
`Sources/GraphProtocols/VertexIdentifiers.swift`.

- `_vertexNumbering()` and `_listedVertices()` return `nil` when the bound is non-nil, so they
  never build a dictionary.
- `_withSuccessorIndexRows` forwards to CSR's offsets and targets. On the matrix it returns `nil`.
- `_numberedRows` is not involved, because `LabeledGraph` is never sparsely indexed.

`SuccessorIndices` and `PredecessorIndices` are bound to the base's. The protocol default
`successorIndices(ofIndex:)` would map `successors(of:)` back through `vertexIndex(of:)`, one hash
per edge. The hash law in `ref.py` and the Swift hash tests check that an index-space algorithm
hashes each input label once and nothing per edge. An algorithm whose result is a `Set` or
`Dictionary` of vertices also hashes once per output vertex.
