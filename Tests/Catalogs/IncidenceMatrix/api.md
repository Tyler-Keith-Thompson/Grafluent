# IncidenceMatrix: proposed API (phase 1)

The README's representation row is `IncidenceMatrix`, a |V|×|E| matrix "mostly for hypergraphs and
spectral methods". This file proposes two bit-packed value types in `IncidenceMatrixModule`:

- **`IncidenceMatrix`**: the unoriented 0/1 matrix B, with cell (v, p) set when vertex `v` is a
  member of column `p`. A column is a hyperedge, or an ordinary edge's ends. It conforms to
  `Hypergraph` (`Tests/Catalogs/Hypergraphs/api.md`) with `Vertex == Int`.
- **`OrientedIncidenceMatrix`**: the oriented matrix of a directed hypergraph, with −1 at each
  source and +1 at each target of a column. A directed graph's edge is the column with one source
  and one target, which is the form spectral graph theory uses (B·Bᵀ = L) and NetworkX's
  `incidence_matrix(oriented=True)`. Gallo et al. (1993) define the directed hypergraph's matrix
  the same way: aᵢⱼ = −1 if vᵢ ∈ T(Eⱼ), 1 if vᵢ ∈ H(Eⱼ), 0 otherwise. It is stored as two bit
  planes and conforms to `DirectedHypergraph` with `Vertex == Int`.

**Neither conforms to `Graph` or `DirectedGraph`** (open question 2).

`cases.md` (IM-001 – IM-063, 63 rows) pins the values. `ref.py` checks every state against:

- NetworkX 3.7 `incidence_matrix` in both modes, on a `MultiGraph` / `MultiDiGraph` with an
  explicit edge list, so parallel edges keep their columns;
- XGI 0.10.2 `incidence_matrix` for hypergraph inputs, and `DiHypergraph` (`edges.tail`,
  `edges.head`, `nodes.out_degree`, `nodes.in_degree`) for oriented ones;
- the identities B·Bᵀ = D + A (loopless), Bᵀ·B = 2I + A(L(G)) (loopless, simple), and oriented
  B·Bᵀ = L (NetworkX `laplacian_matrix` of the loopless underlying multigraph) whenever every
  column has one source and one target;
- the `Hypergraph` and `DirectedHypergraph` laws, `transposed()` as the dual and an involution, and
  `reversed` as the negation of every entry.

`--stress` adds 300 random hypergraphs, graphs, digraphs and directed hypergraphs (both types, with
loops, parallel edges, empty sides and overlapping sides) and 200 mutation sequences of 40 steps of
each matrix. Planted bugs caught: a loop's oriented column given a −1, a loop's unoriented column
left zero (both from the previous revision), and a vertex on both sides given +1 instead of 0.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 python3 Tests/Catalogs/IncidenceMatrix/ref.py [--write] [--stress] [--baseline]`.

## Names

| Name | Decision | Source |
|---|---|---|
| Types | **`IncidenceMatrix`**, **`OrientedIncidenceMatrix`** | README row; "oriented incidence matrix" (Godsil–Royle, *Algebraic Graph Theory* §8.3; Biggs); NetworkX `incidence_matrix(G, oriented=)`; Gallo et al. (1993) §2 for directed hypergraphs |
| Module | **`IncidenceMatrixModule`** (exists as a stub; `Module` suffix because it would share its main type's name) | README package layout |
| Cell | **`subscript(vertex:hyperedge:)`**: `Bool`, oriented `Int` (−1, 0, +1) | `AdjacencyMatrix.subscript(source:target:)` |
| Column / row reads | the protocols' **`members(ofHyperedgeAt:)`**, **`incidentHyperedges(of:)`**, **`size(ofHyperedgeAt:)`**, **`degree(of:)`**; oriented **`sources(ofHyperedgeAt:)`**, **`targets(ofHyperedgeAt:)`**, **`outHyperedges(of:)`**, **`inHyperedges(of:)`**, **`outDegree(of:)`**, **`inDegree(of:)`** | `Hypergraph`, `DirectedHypergraph` |
| Cell edits | **`insert(_:intoHyperedgeAt:)`**, **`remove(_:fromHyperedgeAt:)`**; oriented **`insert(_:intoSourcesOfHyperedgeAt:)`**, **`insert(_:intoTargetsOfHyperedgeAt:)`**, **`remove(_:fromSourcesOfHyperedgeAt:)`**, **`remove(_:fromTargetsOfHyperedgeAt:)`** | XGI `add_node_to_edge` / `remove_node_from_edge` (a `direction` argument on a `DiHypergraph`), HyperNetX `add_incidence`, in the repo's `insert` / `remove` spelling |
| Growth | **`appendVertex()`** (as `AdjacencyMatrix`), **`insert(hyperedge:)`**, oriented **`insert(sources:targets:)`** and **`insert(edge:)`** for a `DirectedEdge<Int>` (each appends a column and returns its position, as `Pseudograph.insert(edge:)`) | AdjacencyMatrix, Multigraphs, `IncidenceList` |
| Dual | **`transposed()`** | README Terminology ("transposed() … matrix algebra"); `AdjacencyMatrix.transposed()` |
| Sources and targets swapped | oriented **`reversed`**: every entry negated | README Terminology `reversed`; `IncidenceList.reversed` |

No `isOriented` flag and no `oriented:` parameter. The two matrices have different element types
(Bool versus −1/0/+1) and conform to different protocols.

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
    @usableFromInline var _sources: IncidenceMatrix   // the source plane
    @usableFromInline var _targets: IncidenceMatrix   // the target plane
}
```

- **Both orientations are stored**, at 2·n·m/8 bytes per plane. `members` (a column) and
  `incidentHyperedges` (a row) are then both O(words) `BitSet` copies, as
  `AdjacencyMatrix.successors(of:)` is. Without the second copy, one of them is an O(n) or O(m)
  bit scan, the cost `AdjacencyMatrix.predecessors(of:)` pays.
  - `transposed()` swaps the two copies in O(1), in each plane. That is the dual.
  - `reversed` swaps the two planes in O(1).
  - A cell edit writes two bits: O(1).
  - `_BitRows` is `AdjacencyMatrix`'s layout (rows of `_wordsPerRow` words, unused bits zero,
    doubling capacity), factored out.
- **Self-loops, unoriented.** A loop's column is the one bit at `v`, the hyperedge {v} (IM-009,
  IM-012). NetworkX gives a zero column instead ("self loops give zero column", in both modes), and
  the catalog asserts the divergence. A zero column would make `IncidenceMatrix(g)` forget the loop,
  and the hypergraph reading {v} is the useful one. Godsil–Royle's 2 for a loop is not
  representable in bits; callers who need NetworkX's matrix exactly drop loops first.
- **A vertex that is both a source and a target of a column**, a self-loop included, has both
  bits set, so its entry (target − source) is **0** (IM-041, IM-046):
  - NetworkX gives a self-loop a zero column in the oriented mode, so graph-built matrices agree
    with it everywhere (IM-041, IM-044);
  - HyperGraphs.jl's oriented `incidence_matrix` does `I[v, e] -= 1` for each source and `+= 1`
    for each target, which sums to the same 0;
  - XGI 0.10.2 allows the overlap in a `DiHypergraph` but has no oriented matrix:
    `xgi.incidence_matrix` raises `KeyError: 'in'` on one. Gallo et al. require disjoint sides, so
    the paper never meets the case.
  - Nothing is lost: `sources(ofHyperedgeAt:)`, `targets(ofHyperedgeAt:)` and the stars read the
    planes, equality compares the planes (IM-060, IM-061), and B·Bᵀ is still the Laplacian of the
    loopless underlying multigraph (IM-044).

## API

n = `vertexCount`, m = `hyperedgeCount`, w(x) = ⌈x/64⌉ words.

### `IncidenceMatrix`

```swift
extension IncidenceMatrix {
    public init()
    public init(vertexCount: Int)                                    // O(n)
    public init(vertexCount: Int, hyperedges: some Sequence<some Sequence<Int>>)   // O(n·w(m) + m·w(n) + p)
    public init(_ graph: some Graph)          // vertices by vertexIndex(of:); one column per edge, in edges order
    public init(_ graph: some DirectedGraph)  // unoriented: both ends (NetworkX oriented=False)
    public init(_ hypergraph: some Hypergraph)            // by vertex and hyperedge index
    public init(_ hypergraph: some DirectedHypergraph)    // each column the union of its sides
    public init(_ oriented: OrientedIncidenceMatrix)      // the union of the planes

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
extension IncidenceMatrix: Hypergraph {
    // Vertex = Int, Vertices = Range<Int>, Hyperedges: RandomAccessCollection<BitSet> (Index = Int),
    // Members = BitSet, IncidentHyperedges = BitSet; vertexIndexBound = n, hyperedgeIndexBound = m
}
```

- **Conversions from graphs and hypergraphs** need `vertexIndexBound != nil` (trap otherwise, as
  in `LabeledGraph.init(_:labels:)`). Rows follow `vertexIndex(of:)` and columns follow `edges` /
  `hyperedges` order, NetworkX's `nodelist` / `edgelist` defaults. Parallel edges keep one column
  each (IM-008). A self-loop sets one bit (IM-009, IM-012).
- **Traps:** a member or vertex out of `0..<n` (IM-005, IM-019, IM-022, IM-026); a column out of
  `0..<m` (IM-020, IM-021, IM-029); a negative `vertexCount` (IM-006); storage that does not fit
  in `Int` (as `AdjacencyMatrix`).
- **Column removal is phase 2.** It shifts every row by one bit, at O(n·w(m)).

### `OrientedIncidenceMatrix`

```swift
extension OrientedIncidenceMatrix {
    public init()
    public init(vertexCount: Int)
    public init<S: Sequence, T: Sequence>(vertexCount: Int, hyperedges: some Sequence<(sources: S, targets: T)>)
        where S.Element == Int, T.Element == Int
    public init(vertexCount: Int, edges: some Sequence<DirectedEdge<Int>>)   // one source, one target per column
    public init(_ hypergraph: some DirectedHypergraph)   // by vertex and hyperedge index
    public init(_ graph: some DirectedGraph)  // one column per edge, in edges order
    public init(_ graph: some Graph)          // each edge from edges[p].u to edges[p].v (NetworkX's edgelist tuple order)

    public var vertexCount: Int { get }; public var hyperedgeCount: Int { get }
    public subscript(vertex vertex: Int, hyperedge position: Int) -> Int { get }   // target − source: −1, 0, +1; O(1)
    public func sources(ofHyperedgeAt position: Int) -> BitSet    // the source plane's column; O(w(n))
    public func targets(ofHyperedgeAt position: Int) -> BitSet
    public func outHyperedges(of vertex: Int) -> BitSet           // the source plane's row; O(w(m))
    public func inHyperedges(of vertex: Int) -> BitSet            // the target plane's row
    public func outDegree(of vertex: Int) -> Int; public func inDegree(of vertex: Int) -> Int   // O(1), cached
    public func degree(of vertex: Int) -> Int                     // outDegree + inDegree

    @discardableResult public mutating func appendVertex() -> Int
    @discardableResult public mutating func insert(sources: some Sequence<Int>, targets: some Sequence<Int>) -> Int
    @discardableResult public mutating func insert(edge: DirectedEdge<Int>) -> Int
    @discardableResult public mutating func insert(_ vertex: Int, intoSourcesOfHyperedgeAt position: Int) -> Bool
    @discardableResult public mutating func insert(_ vertex: Int, intoTargetsOfHyperedgeAt position: Int) -> Bool
    @discardableResult public mutating func remove(_ vertex: Int, fromSourcesOfHyperedgeAt position: Int) -> Bool
    @discardableResult public mutating func remove(_ vertex: Int, fromTargetsOfHyperedgeAt position: Int) -> Bool
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int)

    public func transposed() -> OrientedIncidenceMatrix   // O(1): the dual; column v has sources outHyperedges(of: v), targets inHyperedges(of: v)
    public var reversed: OrientedIncidenceMatrix { get }  // O(1): every entry negated, the overlap still 0
}
extension OrientedIncidenceMatrix: DirectedHypergraph {
    // Vertex = Int, Vertices = Range<Int>, Members = BitSet, IncidentHyperedges = BitSet,
    // Hyperedges.Element = (sources: BitSet, targets: BitSet), Index = Int; both index bounds non-nil
}
```

- `transposed()` is `IncidenceList.dual()`'s convention: it transposes each plane (IM-049),
  as SimpleDirectedHypergraphs.jl's `dual` does.
- The `Hypergraphs` algorithms on `DirectedHypergraph` (B- and F-connection, components, the
  clique expansion) run on it with no conversion.
- **Traps:** a vertex out of range (IM-056, IM-059), a column out of range (IM-057, IM-058).

### Conformances

- **`Equatable`, `Hashable`.** Matrices compare cell for cell, with equal shape (IM-034 – IM-037);
  the oriented one compares both planes, so a vertex on both sides differs from it on neither
  although both entries are 0 (IM-060), and two loops at different vertices differ (IM-061).
  Column order is observable, as it is for `EdgeList`, because a column's position is what a
  spectral caller indexes by (IM-035, IM-063).
  - **Unlike** `UndirectedIncidenceList` and `IncidenceList`, whose equality ignores positions.
    Convert with `UndirectedIncidenceList(matrix)` or `IncidenceList(matrix)` for an order-free
    comparison.
- **`Sendable`**, **`Codable`** (shape plus set cells, per plane, with `AdjacencyMatrix`'s
  `maximumDecodedVertexCount` guard), **`CustomStringConvertible`** (rows of bits, as
  `AdjacencyMatrix.rowsDescription`; the oriented one as rows of `-`, `0`, `+`).

## Performance

`ref.py --baseline` on the development machine (Python 3.12, NetworkX 3.7 with SciPy 1.18.1):

- NetworkX `incidence_matrix` on a G(n, m) multigraph, n = 10⁴, m = 10⁵: **0.37 s** unoriented,
  **0.38 s** oriented (a `lil` fill then a CSC conversion);
- XGI `incidence_matrix`, n = 10⁴, m = 2·10⁴, sizes 2–8: **0.03 s** (SciPy COO).

These are sparse matrices. A dense bit matrix at n = 10⁴, m = 10⁵ is 2·10⁹ bits, 250 MB per
orientation, and the oriented matrix doubles it. That is the trap the documentation must state:
**`IncidenceMatrix` and `OrientedIncidenceMatrix` are for dense or small incidence** (spectral work
at n·m ≲ 10⁹, hypergraphs with large hyperedges). Sparse incidence is `UndirectedIncidenceList` /
`IncidenceList`, or `CompressedSparseRow`.

| Measure | Target |
|---|---|
| `IncidenceMatrix(g)` at n = 2 048, m = 2·10⁴ (5 MB per orientation) | ≤ 2× the time to zero its storage plus O(m) bit writes. At least 10× NetworkX's `incidence_matrix` on the same graph |
| Cell read, degrees, `size` | O(1), no allocation |
| `members`, `sources`, `incidentHyperedges`, `outHyperedges` | one `BitSet` copy of w(n) or w(m) words |
| `transposed()`, `reversed` | O(1) |
| `connectedComponents()`, `weaklyConnectedComponents()` (the `Hypergraphs` algorithms, through the protocols) | within 1.5× the same call on an incidence-list copy at density ≥ 1/8, where word scans pay off |

## Prior art (verified 2026-10-11)

| Library | What it does | Taken |
|---|---|---|
| NetworkX 3.7 `incidence_matrix(G, nodelist, edgelist, oriented=False, weight=None, *, dtype)` | SciPy CSC, n × m. Oriented: −1 at `u`, +1 at `v` of each edgelist tuple. **`if u == v: continue  # self loops give zero column`** in both modes | Row and column order, the sign convention. The loop column diverges in the unoriented matrix only |
| XGI 0.10.2 `incidence_matrix(H, order=None, sparse=True, index=False, weight=…)` | Rows and columns re-indexed; isolated nodes and empty edges dropped from the index. **Fails on a `DiHypergraph`** (`KeyError: 'in'`) | Values match on the shared rows and columns; ours keeps every row and column |
| HyperGraphs.jl (Diaz & Stumpf 2022) `incidence_matrix` | Oriented case: `I[idx[v], i] -= s` for each source, `+= s` for each target (stoichiometries; 1 when unweighted). A species on both sides sums | The encoding of a vertex on both sides |
| SimpleDirectedHypergraphs.jl | A directed hypergraph as two |V|×|E| matrices, `hg_tail` and `hg_head`; `dual` transposes both | Two planes |
| SimpleHypergraphs.jl | The hypergraph *is* its |V|×|E| incidence matrix | The matrix as a hypergraph |
| Gallo, Longo, Pallottino, Nguyen (1993) §2 | Directed hypergraph incidence matrix, −1 for a tail node, +1 for a head node; "a one-to-one correspondence between hypergraphs and (−1, 0, 1) matrices" (disjoint sides) | The oriented matrix as a directed hypergraph |
| Godsil–Royle §8.3, Biggs, Chung | Oriented incidence D with D·Dᵀ = L; unoriented B with B·Bᵀ = D + A | The identities `ref.py` checks |
| JGraphT, Boost, petgraph, LEMON | No incidence-matrix type | The name is free of conflicting meaning |

## Open questions (with recommendations)

1. **Conformances.** *Recommendation:* `IncidenceMatrix: Hypergraph` and
   `OrientedIncidenceMatrix: DirectedHypergraph`. Any column is a vertex set (or a pair of them),
   empty and repeated columns included, so the `Hypergraphs` algorithms run on both with no
   conversion.
2. **`Graph` or `DirectedGraph` when built from a graph?** *Recommendation:* no, for either.
   - **Unoriented.** "Every column has one or two bits" is not an invariant, since cell edits
     break it.
   - **Oriented.** Now that a column may have any number of sources and targets, it is not even a
     directed multigraph. Restricted to one-and-one columns it would be, but `successors(of: v)`
     would scan the source row and read each column's target, O(w(m) + d), and `contains(edge:)`
     would be O(m): the cost the README refuses for `EdgeList`.
   - Graph algorithms take the graph the matrix was built from, or the matrix's `incidenceGraph`
     view through the hypergraph protocols. The matrices are for algebra.
3. **One type with an `oriented` flag, or two?** *Recommendation:* two. NetworkX's flag changes
   the element type; Swift should not.
4. **The overlap entry.** *Recommendation:* 0 with both bits kept (above). The alternatives were a
   trap on insertion, which XGI's `DiHypergraph` and `IncidenceList` would then disagree with, or a
   third value, which no reference has.
5. **Bit-packed only?** *Recommendation:* yes, in phase 1. Weighted incidence (SimpleHypergraphs,
   HyperGraphs.jl stoichiometries, NetworkX `weight=`) is a side array indexed by (vertex, column),
   or by the incidence numbers of the incidence lists' views. A sparse incidence type would
   duplicate the incidence lists.
6. **Products for spectral methods** (B·Bᵀ, Bᵀ·B, the hypergraph and directed-hypergraph
   Laplacians): *Recommendation:* phase 2, in `SpectralGraphTheory`, built on these planes
   (popcount of ANDed rows gives (B·Bᵀ)ᵤᵥ in O(w(m)); the oriented product is four such
   popcounts). Phase 1 fixes the identities in the catalog.
7. **Labels.** *Recommendation:* no labeled matrix in phase 1. `UndirectedIncidenceList<Label>`
   and `IncidenceList<Label>` convert.
8. **Column and row removal.** *Recommendation:* phase 2, decided with the incidence lists'
   removal. A matrix can only shift or swap-remove; it has no stable holes.
9. **Dependencies.** `IncidenceMatrixModule` depends on `GraphProtocols` (where both hypergraph
   protocols live) and `BitCollections`, not on `Hypergraphs`. `_BitRows` could move to a
   package-level type shared with `AdjacencyMatrixModule` in the final reuse pass.
