# IncidenceMatrix: proposed API (phase 1)

The README's representation row is `IncidenceMatrix`, a |V|×|E| matrix "mostly for hypergraphs and
spectral methods". This file proposes two bit-packed value types in `IncidenceMatrixModule`:

- **`IncidenceMatrix`**: the unoriented 0/1 matrix B, with cell (v, p) set when vertex `v` is a
  member of column `p`. A column is a hyperedge, or an ordinary edge's ends. It conforms to
  `HypergraphProtocol` (`Tests/Catalogs/Hypergraphs/api.md`) with `Vertex == Int`, so the
  `Hypergraphs` algorithms run on it.
- **`OrientedIncidenceMatrix`**: the oriented matrix of a directed graph, with −1 at each edge's
  source and +1 at its target. This is the form spectral graph theory uses (B·Bᵀ = L), and NetworkX's
  `incidence_matrix(oriented=True)`. It is stored as two bit planes.

`cases.md` (IM-001 – IM-051, 51 rows) pins the values. `ref.py` checks every state against:

- NetworkX 3.7 `incidence_matrix` in both modes, on a `MultiGraph` / `MultiDiGraph` with an
  explicit edge list, so parallel edges keep their columns;
- XGI 0.10.2 `incidence_matrix`;
- the identities B·Bᵀ = D + A (loopless), Bᵀ·B = 2I + A(L(G)) (loopless, simple), and oriented
  B·Bᵀ = L (NetworkX `laplacian_matrix` of the loopless underlying multigraph);
- the protocol laws, and `transposed()` as an involution.

`--stress` adds 300 random hypergraphs, graphs and digraphs (both types, with loops and parallel
edges) and 200 mutation sequences of 40 steps. Two planted bugs were caught: a loop's oriented
column given a −1, and a loop's unoriented column left zero.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 python3 Tests/Catalogs/IncidenceMatrix/ref.py [--write] [--stress] [--baseline]`.

## Names

| Name | Decision | Source |
|---|---|---|
| Types | **`IncidenceMatrix`**, **`OrientedIncidenceMatrix`** | README row; "oriented incidence matrix" (Godsil–Royle, *Algebraic Graph Theory* §8.3; Biggs); NetworkX `incidence_matrix(G, oriented=)`; XGI `incidence_matrix` |
| Module | **`IncidenceMatrixModule`** (exists as a stub; `Module` suffix because it would share its main type's name) | README package layout |
| Cell | **`subscript(vertex:hyperedge:) -> Bool`**, oriented **`subscript(vertex:edge:) -> Int`** | `AdjacencyMatrix.subscript(source:target:)` |
| Column / row reads | the protocol's **`members(ofHyperedgeAt:)`**, **`incidentHyperedges(of:)`**, **`size(ofHyperedgeAt:)`**, **`degree(of:)`**; oriented **`outEdges(of:)`**, **`inEdges(of:)`**, **`source(ofEdgeAt:)`**, **`target(ofEdgeAt:)`** | `HypergraphProtocol`; `DirectedGraph` |
| Cell edits | **`insert(_:intoHyperedgeAt:)`**, **`remove(_:fromHyperedgeAt:)`** | XGI `add_node_to_edge` / `remove_node_from_edge`, HyperNetX `add_incidence` / `remove_incidences`, in the repo's `insert` / `remove` spelling |
| Growth | **`appendVertex()`** (as `AdjacencyMatrix`), **`insert(hyperedge:)`**, oriented **`insert(edge:)`** (appends a column and returns its position, as `Pseudograph.insert(edge:)`) | AdjacencyMatrix, Multigraphs |
| Dual | **`transposed()`** | README Terminology ("transposed() … matrix algebra"); `AdjacencyMatrix.transposed()` |

No `isOriented` flag and no `oriented:` parameter. The two matrices have different element types
(Bool versus −1/0/+1) and different invariants: a column has any number of members versus exactly
one source and one target.

## Storage

```swift
@frozen public struct IncidenceMatrix {
    @usableFromInline var _vertexCount: Int
    @usableFromInline var _hyperedgeCount: Int
    @usableFromInline var _rows: _BitRows      // vertexCount rows of ⌈capacity(m)/64⌉ words
    @usableFromInline var _columns: _BitRows   // hyperedgeCount rows of ⌈capacity(n)/64⌉ words
    @usableFromInline var _degrees: ContiguousArray<Int>   // row popcounts
    @usableFromInline var _sizes: ContiguousArray<Int>     // column popcounts
}
@frozen public struct OrientedIncidenceMatrix {
    @usableFromInline var _sources: IncidenceMatrix   // one bit per column: the source
    @usableFromInline var _targets: IncidenceMatrix   // one bit per column: the target
    @usableFromInline var _ends: ContiguousArray<Int> // 2 per column: source, target (O(1) reads)
}
```

- **Both orientations are stored**, at 2·n·m/8 bytes. `members` (a column) and
  `incidentHyperedges` (a row) are then both O(words) `BitSet` copies, as
  `AdjacencyMatrix.successors(of:)` is. Without the second copy, one of them is an O(n) or O(m)
  bit scan, the cost `AdjacencyMatrix.predecessors(of:)` pays.
  - `transposed()` swaps the two copies in O(1). That is the dual.
  - A cell edit writes two bits: O(1).
  - `_BitRows` is `AdjacencyMatrix`'s layout (rows of `_wordsPerRow` words, unused bits zero,
    doubling capacity), factored out.
- **Self-loops.** In the unoriented matrix, a loop's column is the one bit at `v`, the hyperedge
  {v} (IM-009, IM-012). NetworkX gives a zero column instead ("self loops give zero column", in
  both modes), and the catalog asserts the divergence. Two bits cannot be set at one vertex. A
  zero column would make `IncidenceMatrix(g)` forget the loop, and the hypergraph reading {v} is
  the useful one.
  - Godsil–Royle's 2 for a loop is not representable in bits.
  - Callers who need NetworkX's matrix exactly drop loops first.
- **Oriented loops** have a source bit and a target bit at the same vertex, so the entry
  (target − source) is 0, as in NetworkX (IM-041). The ends stay readable through
  `source(ofEdgeAt:)` and `target(ofEdgeAt:)`, and B·Bᵀ is still the Laplacian of the loopless
  underlying multigraph (IM-044).

## API

n = `vertexCount`, m = `hyperedgeCount` (or `edgeCount`), w(x) = ⌈x/64⌉ words.

### `IncidenceMatrix`

```swift
extension IncidenceMatrix {
    public init()
    public init(vertexCount: Int)                                    // O(n)
    public init(vertexCount: Int, hyperedges: some Sequence<some Sequence<Int>>)   // O(n·w(m) + m·w(n) + p)
    public init(_ graph: some Graph)          // vertices by vertexIndex(of:); one column per edge, in edges order
    public init(_ graph: some DirectedGraph)  // unoriented: both ends (NetworkX oriented=False)
    public init(_ hypergraph: some HypergraphProtocol)   // by vertex and hyperedge index
    public init(_ oriented: OrientedIncidenceMatrix)     // |B|, a loop as its one vertex

    public var vertexCount: Int { get }; public var hyperedgeCount: Int { get }       // O(1)
    public subscript(vertex vertex: Int, hyperedge position: Int) -> Bool { get }     // O(1)
    public func members(ofHyperedgeAt position: Int) -> BitSet       // O(w(n)), ascending
    public func incidentHyperedges(of vertex: Int) -> BitSet         // O(w(m)), ascending
    public func size(ofHyperedgeAt position: Int) -> Int             // O(1), cached
    public func degree(of vertex: Int) -> Int                        // O(1), cached

    @discardableResult public mutating func appendVertex() -> Int                    // amortized O(w(m))
    @discardableResult public mutating func insert(hyperedge members: some Sequence<Int>) -> Int   // amortized O(n·w(m)/m + w(n) + k)
    @discardableResult public mutating func insert(_ vertex: Int, intoHyperedgeAt position: Int) -> Bool   // O(1); false if set
    @discardableResult public mutating func remove(_ vertex: Int, fromHyperedgeAt position: Int) -> Bool   // O(1); false if clear
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int)

    public func transposed() -> IncidenceMatrix                       // O(1): the dual
}
extension IncidenceMatrix: HypergraphProtocol {
    // Vertex = Int, Vertices = Range<Int>, Hyperedges: RandomAccessCollection<BitSet> (Index = Int),
    // Members = BitSet, IncidentHyperedges = BitSet; vertexIndexBound = n, hyperedgeIndexBound = m
}
```

- **Conversions from graphs** need `vertexIndexBound != nil` (trap otherwise, as in
  `LabeledGraph.init(_:labels:)`).
  - Rows follow `vertexIndex(of:)` and columns follow `edges` order, which is NetworkX's
    `nodelist` / `edgelist` defaults.
  - Parallel edges keep one column each (IM-008).
  - A self-loop sets one bit (IM-009, IM-012).
- **Traps:**
  - a member or vertex out of `0..<n` (IM-005, IM-019, IM-022, IM-026);
  - a column out of `0..<m` (IM-020, IM-021, IM-029);
  - a negative `vertexCount` (IM-006);
  - storage that does not fit in `Int` (as `AdjacencyMatrix`).
- **Column removal is phase 2.** It shifts every row by one bit, at O(n·w(m)). A
  `removeLastHyperedge()`, or a swap-remove, is the candidate.

### `OrientedIncidenceMatrix`

```swift
extension OrientedIncidenceMatrix {
    public init()
    public init(vertexCount: Int)
    public init(vertexCount: Int, edges: some Sequence<DirectedEdge<Int>>)
    public init(_ graph: some DirectedGraph)  // one column per edge, in edges order
    public init(_ graph: some Graph)          // each edge from edges[p].u to edges[p].v (NetworkX's edgelist tuple order)

    public var vertexCount: Int { get }; public var edgeCount: Int { get }
    public subscript(vertex vertex: Int, edge position: Int) -> Int { get }   // −1, 0, +1; O(1)
    public func source(ofEdgeAt position: Int) -> Int                         // O(1)
    public func target(ofEdgeAt position: Int) -> Int
    public func outEdges(of vertex: Int) -> BitSet                            // the source plane's row
    public func inEdges(of vertex: Int) -> BitSet                             // the target plane's row
    @discardableResult public mutating func appendVertex() -> Int
    @discardableResult public mutating func insert(edge: DirectedEdge<Int>) -> Int   // appends a column
    public mutating func removeAll(keepingCapacity: Bool = false)
}
```

- **Not a hypergraph and not a graph** (open question 2).
- **Traps:** an endpoint or vertex out of range (IM-047), and a column out of range (IM-048).

### Conformances

- **`Equatable`, `Hashable`.** Matrices compare cell for cell, with equal shape (IM-034 – IM-037).
  Column order is observable, as it is for `EdgeList`, because a column's position is what a
  spectral caller indexes by.
  - **Unlike** `Hypergraph<Vertex>`, whose equality ignores positions. Convert with
    `Hypergraph(matrix)` for an order-free comparison.
  - The oriented matrix compares its stored ends, so two loops at different vertices differ
    although every entry is 0 (IM-050).
- **`Sendable`**, **`Codable`** (shape plus set cells, with `AdjacencyMatrix`'s
  `maximumDecodedVertexCount` guard), **`CustomStringConvertible`** (rows of bits, as
  `AdjacencyMatrix.rowsDescription`).

## Performance

`ref.py --baseline` on the development machine (Python 3.12, NetworkX 3.7 with SciPy 1.18.1):

- NetworkX `incidence_matrix` on a G(n, m) multigraph, n = 10⁴, m = 10⁵: **0.37 s** unoriented,
  **0.38 s** oriented (a `lil` fill then a CSC conversion);
- XGI `incidence_matrix`, n = 10⁴, m = 2·10⁴, sizes 2–8: **0.03 s** (SciPy COO).

These are sparse matrices. A dense bit matrix at n = 10⁴, m = 10⁵ is 2·10⁹ bits, 250 MB per
orientation. That is the trap the documentation must state: **`IncidenceMatrix` is for dense or
small incidence** (spectral work at n·m ≲ 10⁹, hypergraphs with large hyperedges). Sparse incidence
is `Hypergraph<Vertex>`'s compressed rows, or `CompressedSparseRow`.

| Measure | Target |
|---|---|
| `IncidenceMatrix(g)` at n = 2 048, m = 2·10⁴ (5 MB per orientation) | ≤ 2× the time to zero its storage plus O(m) bit writes. At least 10× NetworkX's `incidence_matrix` on the same graph |
| Cell read, `degree`, `size` | O(1), no allocation |
| `members`, `incidentHyperedges` | one `BitSet` copy of w(n) or w(m) words, as `AdjacencyMatrix.successors(of:)` |
| `transposed()` | O(1) |
| `connectedComponents()` (the `Hypergraphs` algorithm, through the protocol) | within 1.5× the same call on a `Hypergraph<Int>` copy at density ≥ 1/8, where word scans pay off |

## Prior art (verified 2026-10-11)

| Library | What it does | Taken |
|---|---|---|
| NetworkX 3.7 `incidence_matrix(G, nodelist, edgelist, oriented=False, weight=None, *, dtype)` | SciPy CSC, n × m. Oriented: −1 at `u`, +1 at `v` of each edgelist tuple. **`if u == v: continue  # self loops give zero column`** in both modes. Multigraph edgelists carry keys | Row and column order, the sign convention. The loop column diverges in the unoriented matrix only |
| XGI 0.10.2 `incidence_matrix(H, order=None, sparse=True, index=False, weight=…)` | Rows and columns re-indexed (`index=True` returns the maps); isolated nodes and empty edges dropped from the index | Values match on the shared rows and columns; ours keeps every row and column |
| HyperNetX 2.4.3 `incidence_matrix(index=False, weights=False)` | Same, by node and edge name | — |
| SimpleHypergraphs.jl | The hypergraph *is* its |V|×|E| incidence matrix (`AbstractMatrix`, weights or `nothing`) | The matrix as a hypergraph: `HypergraphProtocol` conformance |
| Godsil–Royle §8.3, Biggs, Chung | Oriented incidence D with D·Dᵀ = L; unoriented B with B·Bᵀ = D + A (Q, the signless Laplacian) | The identities `ref.py` checks |
| JGraphT, Boost, petgraph, LEMON | No incidence-matrix type (JGraphT's class index has none; BGL's `incidence_graph` concept means out-edge access, not a matrix) | The name is free of conflicting meaning in C++ and Java |

## Open questions (with recommendations)

1. **Does `IncidenceMatrix` conform to `HypergraphProtocol`?** *Recommendation:* yes.
   - It is a hypergraph exactly: any column is a vertex set, empty and repeated columns included.
   - The `Hypergraphs` algorithms then run on it with no conversion.
   - `members` and `incidentHyperedges` are `BitSet`s, so their counts are popcounts.
2. **Should either matrix conform to `Graph` or `DirectedGraph` when built from a graph?**
   *Recommendation:* no.
   - **Unoriented.** "Every column has one or two bits" is not an invariant of the type, since
     cell edits break it, so it cannot be a `Graph`.
   - **Oriented.** It could be a `DirectedGraph`, because a column has exactly one source and one
     target. But `successors(of: v)` would scan the source row and then read each column's
     target: O(w(m) + d). `contains(edge:)` would be O(m). That is the cost the README refuses
     for `EdgeList` ("not a `DirectedGraph` at all: its adjacency queries scan every edge").
   - Graph algorithms take the graph the matrix was built from. The matrices are for algebra.
3. **One type with an `oriented` flag, or two?** *Recommendation:* two (above). NetworkX's flag
   changes the element type; Swift should not.
4. **Bit-packed only?** *Recommendation:* yes, in phase 1.
   - Weighted incidence (SimpleHypergraphs, NetworkX `weight=`) is a side array indexed by
     (vertex, column), or by the incidence numbers of `Hypergraph<Vertex>`'s incidence graph.
   - A sparse incidence type would duplicate `Hypergraph<Vertex>`.
5. **Products for spectral methods** (B·Bᵀ, Bᵀ·B, the hypergraph Laplacians): *Recommendation:*
   phase 2, in `SpectralGraphTheory`, built on these planes (popcount of ANDed rows gives
   (B·Bᵀ)ᵤᵥ in O(w(m))). Phase 1 only fixes the identities in the catalog, so that the products
   have a pinned reference.
6. **Labels.** `LabeledGraph` wraps `DirectedGraph<Int>` bases only. *Recommendation:* no
   labeled matrix in phase 1. `Hypergraph<Label>(matrix)` converts, and a labeled hypergraph
   adaptor waits for the README open question 9 adaptor protocol.
7. **Column removal and row removal.** *Recommendation:* phase 2, decided together with
   `Hypergraph<Vertex>` removal (Hypergraphs open question 7). A matrix can only shift or
   swap-remove; it has no stable holes.
8. **Dependencies.** `IncidenceMatrixModule` depends on `GraphProtocols` (where
   `HypergraphProtocol` lives) and `BitCollections`. It does not depend on `Hypergraphs`. The
   `_BitRows` layout could move to a package-level type shared with `AdjacencyMatrixModule` in the
   final reuse pass.
