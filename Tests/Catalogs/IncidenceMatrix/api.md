# IncidenceMatrix: API

`IncidenceMatrixModule` has two bit-packed value types:

- **`IncidenceMatrix`**: the unoriented 0/1 matrix B, with cell (v, p) set when vertex `v` is a
  member of column `p`. A column is a hyperedge, or an ordinary edge's ends. It conforms to
  `Hypergraph` (`Tests/Catalogs/Hypergraphs/api.md`) with `Vertex == Int`.
- **`OrientedIncidenceMatrix`**: the oriented matrix of a directed hypergraph, with −1 at each
  source and +1 at each target of a column. A directed graph's edge is the column with one source
  and one target, the form spectral graph theory uses (B·Bᵀ = L). Gallo et al. (1993) define the
  directed hypergraph's matrix the same way: aᵢⱼ = −1 if vᵢ ∈ T(Eⱼ), 1 if vᵢ ∈ H(Eⱼ), 0 otherwise.
  It is stored as two bit planes and conforms to `DirectedHypergraph` with `Vertex == Int`.

Neither conforms to `Graph` or `DirectedGraph`. Cell edits can give an unoriented column any number
of bits, and an oriented column any number of sources and targets. Graph algorithms take the graph
the matrix was built from, or the matrix's `incidenceGraphView`.

`cases.md` pins the values. `ref.py` checks every state against:

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
each matrix. `--baseline` times NetworkX and XGI on a G(n, m) multigraph with n = 10⁴ and m = 10⁵
and a hypergraph of 2·10⁴ edges.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 python3 Tests/Catalogs/IncidenceMatrix/ref.py [--write] [--stress] [--baseline]`.

## Names

| Name | Spelling |
|---|---|
| Types | `IncidenceMatrix`, `OrientedIncidenceMatrix` |
| Module | `IncidenceMatrixModule` (the suffix avoids sharing its main type's name) |
| Cell | `subscript(vertex:hyperedge:)`, a `Bool`, or an `Int` (−1, 0, +1) when oriented |
| Column / row reads | The protocols' `members(ofHyperedgeAt:)`, `incidentHyperedges(of:)`, `size(ofHyperedgeAt:)`, `degree(of:)`. Oriented: `sources(ofHyperedgeAt:)`, `targets(ofHyperedgeAt:)`, `outHyperedges(of:)`, `inHyperedges(of:)`, `outDegree(of:)`, `inDegree(of:)` |
| Cell edits | `insert(_:intoHyperedgeAt:)`, `remove(_:fromHyperedgeAt:)`. Oriented: `insert(_:intoSourcesOfHyperedgeAt:)`, `insert(_:intoTargetsOfHyperedgeAt:)`, `remove(_:fromSourcesOfHyperedgeAt:)`, `remove(_:fromTargetsOfHyperedgeAt:)` |
| Growth | `appendVertex()`, `insert(hyperedge:)`. Oriented: `insert(sources:targets:)` and `insert(edge:)` for a `DirectedEdge<Int>`. Each appends a column and returns its position |
| Dual | `transposed()` |
| Sources and targets swapped | Oriented `reversed`, every entry negated |

There is no `oriented:` flag. The two matrices have different element types (`Bool` versus
−1/0/+1) and conform to different protocols.

## Storage

```swift
@frozen public struct IncidenceMatrix {
    @usableFromInline var _vertexCount: Int
    @usableFromInline var _hyperedgeCount: Int
    @usableFromInline var _rows: _BitRows      // vertexCount rows of ⌈capacity(m)/64⌉ words
    @usableFromInline var _columns: _BitRows   // hyperedgeCount rows of ⌈capacity(n)/64⌉ words
    @usableFromInline var _degrees: ContiguousArray<Int>   // row popcounts
    @usableFromInline var _sizes: ContiguousArray<Int>     // column popcounts
    @usableFromInline var _cellCount: Int                  // set cells: the incidence-graph view's edge count in O(1)
}
@frozen public struct OrientedIncidenceMatrix {
    @usableFromInline var _sources: IncidenceMatrix   // the source plane
    @usableFromInline var _targets: IncidenceMatrix   // the target plane
}
```

- **Both orientations are stored**, at 2·n·m/8 bytes per plane. `members` (a column) and
  `incidentHyperedges` (a row) are then both O(words) `BitSet` copies, as
  `AdjacencyMatrix.successors(of:)` is.
  - `transposed()` swaps the two copies in O(1), in each plane. That is the dual.
  - `reversed` swaps the two planes in O(1).
  - A cell edit writes two bits, O(1).
  - `_BitRows` has `AdjacencyMatrix`'s layout: rows of `_wordsPerRow` words, unused bits zero,
    doubling capacity.
- **Self-loops, unoriented.** A loop's column is the one bit at `v`, the hyperedge {v} (IM-009,
  IM-012). NetworkX's `incidence_matrix` gives a zero column instead, and `ref.py` asserts the
  difference.
- **A vertex that is both a source and a target of a column**, a self-loop included, has both
  bits set, so its entry (target − source) is 0 (IM-041, IM-046). NetworkX's oriented matrix also
  gives a self-loop a zero column, so graph-built matrices agree with it (IM-041, IM-044).
  `sources(ofHyperedgeAt:)`, `targets(ofHyperedgeAt:)` and the stars read the planes, equality
  compares the planes (IM-060, IM-061), and B·Bᵀ is still the Laplacian of the loopless
  underlying multigraph (IM-044).

A dense bit matrix at n = 10⁴, m = 10⁵ is 2·10⁹ bits, 250 MB per orientation, and the oriented
matrix doubles it. The matrices are for dense or small incidence, such as spectral work or
hypergraphs with large hyperedges. Sparse incidence belongs in `UndirectedIncidenceList`,
`IncidenceList` or `CompressedSparseRow`.

## API

n = `vertexCount`, m = `hyperedgeCount`, w(x) = ⌈x/64⌉ words.

### `IncidenceMatrix`

```swift
extension IncidenceMatrix {
    public init()
    public init(vertexCount: Int)                                    // O(n)
    public init(vertexCount: Int, hyperedges: some Sequence<some Sequence<Int>>)   // O(n·w(m) + m·w(n) + p)
    public init(_ graph: some Graph)          // vertices by vertexIndex(of:); one column per edge, in edges order
    public init(_ graph: some DirectedGraph)  // unoriented: both ends
    public init(_ hypergraph: some Hypergraph)            // by vertex and hyperedge index
    public init(_ hypergraph: some DirectedHypergraph)    // each column the union of its sides
    public init(_ oriented: OrientedIncidenceMatrix)      // the union of the planes
    public init<H: Graph & Hypergraph>(_ hypergraph: H)   // a type that is both reads as a hypergraph
    public init<H: DirectedGraph & DirectedHypergraph>(_ hypergraph: H)

    public var vertexCount: Int { get }; public var hyperedgeCount: Int { get }       // O(1)
    public subscript(vertex vertex: Int, hyperedge position: Int) -> Bool { get }     // O(1)
    public func members(ofHyperedgeAt position: Int) -> BitSet       // O(w(n)), ascending
    public func incidentHyperedges(of vertex: Int) -> BitSet         // O(w(m)), ascending
    public func size(ofHyperedgeAt position: Int) -> Int             // O(1), cached
    public func degree(of vertex: Int) -> Int                        // O(1), cached
    public func incidentHyperedges(checked:) / degree(checked:) / vertexIndex(checked:)   // throw VertexNotFound off 0..<n (IM-064)

    @discardableResult public mutating func appendVertex() -> Int                    // amortized O(w(m))
    @discardableResult public mutating func insert(hyperedge members: some Sequence<Int>) -> Int   // amortized O(n·w(m)/m + w(n) + k)
    @discardableResult public mutating func insert(checked members: some Sequence<Int>) throws(VertexNotFound) -> Int   // checks first; throws, changing nothing (IM-065, IM-066)
    @discardableResult public mutating func insert(_ vertex: Int, intoHyperedgeAt position: Int) -> Bool   // O(1); false if set
    @discardableResult public mutating func remove(_ vertex: Int, fromHyperedgeAt position: Int) -> Bool   // O(1); false if clear
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int)

    public func transposed() -> IncidenceMatrix                       // O(1): the dual
}
extension IncidenceMatrix: Hypergraph {
    // Vertex = Int, Vertices = Range<Int>, Hyperedges: RandomAccessCollection<BitSet> (Index = Int),
    // Members = BitSet, IncidentHyperedges = BitSet; vertexIndexBound = n, hyperedgeIndexBound = m.
    // MemberIndices (nested, IncidenceMatrix.MemberIndices): the column's stored words read in
    // place, with no allocation; IncidentHyperedgeIndices = MemberIndices over the vertex's row;
    // oriented sourceIndices, targetIndices, outHyperedgeIndices and inHyperedgeIndices likewise,
    // and sourceSize / targetSize from the cached sizes. _forEachMemberIndex scans the words
    // (oriented: the two planes ORed), so union–find over the columns allocates nothing per column
    // or per vertex.
}
```

- **Conversions from graphs and hypergraphs** need `vertexIndexBound != nil` and trap otherwise.
  Rows follow `vertexIndex(of:)` and columns follow `edges` / `hyperedges` order. Parallel edges
  keep one column each (IM-008). A self-loop sets one bit (IM-009, IM-012).
- **Traps:** a member or vertex out of `0..<n` (IM-005, IM-019, IM-022, IM-026); a column out of
  `0..<m` (IM-020, IM-021, IM-029); a negative `vertexCount` (IM-006); storage that does not fit
  in `Int`. The `checked:` spellings throw `VertexNotFound` for a vertex out of `0..<n` instead.
  Column positions and the cell edits keep their traps.

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
    public init(_ graph: some Graph)          // each edge from edges[p].u to edges[p].v
    public init<H: DirectedGraph & DirectedHypergraph>(_ hypergraph: H)   // a type that is both reads as a hypergraph

    public var vertexCount: Int { get }; public var hyperedgeCount: Int { get }
    public subscript(vertex vertex: Int, hyperedge position: Int) -> Int { get }   // target − source: −1, 0, +1; O(1)
    public func sources(ofHyperedgeAt position: Int) -> BitSet    // the source plane's column; O(w(n))
    public func targets(ofHyperedgeAt position: Int) -> BitSet
    public func outHyperedges(of vertex: Int) -> BitSet           // the source plane's row; O(w(m))
    public func inHyperedges(of vertex: Int) -> BitSet            // the target plane's row
    public func outDegree(of vertex: Int) -> Int; public func inDegree(of vertex: Int) -> Int   // O(1), cached
    public func degree(of vertex: Int) -> Int                     // outDegree + inDegree
    // outHyperedges / inHyperedges / outDegree / inDegree / degree / vertexIndex(checked:): throw VertexNotFound off 0..<n (IM-067)

    @discardableResult public mutating func appendVertex() -> Int
    @discardableResult public mutating func insert(sources: some Sequence<Int>, targets: some Sequence<Int>) -> Int
    @discardableResult public mutating func insert(edge: DirectedEdge<Int>) -> Int
    // insert(checked:targets:), insert(checked: DirectedEdge<Int>): check first; throw VertexNotFound, changing nothing (IM-068, IM-069)
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

- `transposed()` follows `IncidenceList.dual()`: it transposes each plane (IM-049).
- The `Hypergraphs` algorithms on `DirectedHypergraph` (B- and F-connection, components, the
  clique expansion) run on it with no conversion.
- **Traps:** a vertex out of range (IM-056, IM-059), a column out of range (IM-057, IM-058).

### Conformances

- **`Equatable`, `Hashable`.** Matrices compare cell for cell, with equal shape (IM-034 – IM-037).
  The oriented one compares both planes, so a vertex on both sides differs from one on neither
  although both entries are 0 (IM-060), and two loops at different vertices differ (IM-061).
  Column order counts, because a column's position is what a spectral caller indexes by (IM-035,
  IM-063). `UndirectedIncidenceList` and `IncidenceList` ignore positions. Convert with
  `UndirectedIncidenceList(matrix)` or `IncidenceList(matrix)` for an order-free comparison.
- **`Sendable`**.
- **`Codable`**, with a fixed form: the shape plus the set cells, per plane, each column ascending,
  so equal matrices encode identically.
  - `IncidenceMatrix` is `{"vertexCount": 3, "hyperedges": [[0, 1], [], [2]]}`, each column by
    position as its members.
  - `OrientedIncidenceMatrix` is `{"vertexCount": 2, "sources": [[0]], "targets": [[0, 1]]}`, the
    `IncidenceList` form with a shape in place of the vertices.
  - Decoding throws `DecodingError.dataCorrupted` for a negative vertex count, a member out of
    range, a column (or side) not strictly ascending, `sources` and `targets` of different lengths,
    and storage over the limit. The limit is on the words the decoded matrix would store,
    n·w(m) + m·w(n) + n + m per plane (two planes for the oriented matrix), computed with
    overflow checks, because a short payload can name a huge shape. The key is
    `IncidenceMatrix.maximumDecodedWordCountKey` in `userInfo` (an `Int`), and the default is
    `defaultMaximumDecodedWordCount`, 2²⁴ words or 128 MiB. Both matrices read the one key.
- **`CustomStringConvertible`**: the shape, then the rows, column 0 leftmost, at most 16 rows of at
  most 64 columns, each cut with `…`:
  - unoriented `3×2 [10, 01, 11]`, cells as `1` and `0`;
  - oriented `3×2 [-0, +-, 0+]`, entries as `-`, `0` and `+` (a vertex on both sides is `0`);
  - the empty matrix `0×0 []`.

## Complexity

| Operation | Cost |
|---|---|
| Cell read, degrees, `size` | O(1), no allocation |
| `members`, `sources`, `incidentHyperedges`, `outHyperedges` | One `BitSet` copy of w(n) or w(m) words |
| `transposed()`, `reversed` | O(1) |
| `IncidenceMatrix(g)` | Zeroing the storage plus two bit writes per edge |
