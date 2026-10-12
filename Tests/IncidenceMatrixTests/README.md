# IncidenceMatrix test suite

`IncidenceMatrixModule` holds two bit-packed matrices.

- `IncidenceMatrix` is the unoriented 0/1 matrix B, a `Hypergraph` with `Int` vertices.
- `OrientedIncidenceMatrix` has −1 at each source and +1 at each target. It is stored as two bit
  planes and is a `DirectedHypergraph` with `Int` vertices.

The tests come from the proposed API in [`Tests/Catalogs/IncidenceMatrix/`](../Catalogs/IncidenceMatrix/)
(`api.md`, phase 1), with every open question decided as recommended:

- the two conformances, and neither matrix a `Graph` or `DirectedGraph`;
- two types, not an `oriented` flag;
- an entry of 0 with both bits kept for a vertex on both sides;
- bits only;
- spectral products, labels and removal deferred.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
struct IncidenceMatrix: Hypergraph, Equatable, Hashable, Codable, Sendable, CustomStringConvertible
    init(), init(vertexCount:), init(vertexCount:hyperedges:), init(_ graph: some Graph),
    init(_ graph: some DirectedGraph), init(_ hypergraph: some Hypergraph),
    init(_ hypergraph: some DirectedHypergraph), init(_ oriented: OrientedIncidenceMatrix)
    subscript(vertex:hyperedge:) -> Bool, members(ofHyperedgeAt:), incidentHyperedges(of:), size, degree
    appendVertex(), insert(hyperedge:), insert(_:intoHyperedgeAt:), remove(_:fromHyperedgeAt:),
    removeAll(keepingCapacity:), reserveCapacity(vertexCount:hyperedgeCount:), transposed()
    incidentHyperedges(checked:), degree(checked:), vertexIndex(checked:), insert(checked:)   // throw VertexNotFound
struct OrientedIncidenceMatrix: DirectedHypergraph, …             // the same conformances
    init(vertexCount:hyperedges:), init(vertexCount:edges:), init(_ hypergraph:), init(_ graph:) (both kinds)
    subscript(vertex:hyperedge:) -> Int, sources, targets, outHyperedges, inHyperedges, outDegree, inDegree,
    degree, appendVertex(), insert(sources:targets:), insert(edge:), insert/remove(_:into/fromSources/TargetsOfHyperedgeAt:),
    removeAll, reserveCapacity, transposed(), reversed
    outHyperedges/inHyperedges/outDegree/inDegree/degree/vertexIndex(checked:),
    insert(checked:targets:), insert(checked:)                         // throw VertexNotFound
// Both: PropertyGraph (dense column and row maps, appended with their column or row; removeAll
// keeps them attached), addEdgeMap(default:) / addVertexMap(default:) and the (of:) forms,
// subscripts by column, vertex position and vertex, the checked: subscripts (EdgeNotFound /
// VertexNotFound), values(of:), and generation
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Columns | In input or `edges` order; a repeated member is one bit; repeated and empty columns kept | IM-003, IM-004, IM-008 |
| Self-loops, unoriented | One bit at the vertex (NetworkX: a zero column) | IM-009, IM-012 |
| A vertex on both sides | Both bits kept, entry 0, as NetworkX's oriented loop column | IM-041, IM-046, IM-053 |
| Growth | Rows and columns grow past 64 with every bit kept | IM-024, IM-031 |
| Dual | `transposed()`, each plane transposed; `reversed` swaps the planes (every entry negated) | IM-032, IM-049, IM-050 |
| Equality | Cell for cell with equal shape; column order observable; both planes compared | IM-034 – IM-037, IM-060 – IM-063 |
| `checked:` spellings | The plain answer for a vertex in range; `VertexNotFound` out of it, and a throwing insert changes nothing | IM-064 – IM-069 |
| Traps | A vertex or column out of range, a negative vertex count | IM-005, IM-006, IM-019 – IM-022, IM-026, IM-029, IM-056 – IM-059 |

## How values are pinned

Each catalog row is built the way the catalog writes it:

- `IncidenceMatrix(vertexCount:hyperedges:)`;
- the conversion of a `Pseudograph<Int>` or `DirectedPseudograph<Int>` on `0 ..< n`;
- `OrientedIncidenceMatrix(vertexCount:edges:)` or `(vertexCount:hyperedges:)`.

The calls then run in order, each with its result checked. The final state is written out in full:

- every cell as the catalog's row strings (`1`/`0`, or `-`/`0`/`+`);
- every column's members, or both sides, with their sizes;
- every row's incident columns and degrees, by vertex and by index, out and in when oriented;
- membership of every column, and the protocol bounds.

The construction rows also check the same matrix through an incidence-list copy and by appending
one column at a time. `transposed()` and `reversed` are checked as involutions, and `reversed` as
negation.

The catalog-row files are every file except `IncidenceMatrixConformanceTests.swift`,
`IncidenceMatrixEdgeCaseTests.swift`, `IncidenceMatrixPropertyTests.swift`, the three map files
and `Performance/IncidenceMatrixStressTests.swift`. `swiftgen.py`, which
sits next to `ref.py`, generated them:

```
uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 python3 Tests/Catalogs/IncidenceMatrix/swiftgen.py
```

The generator first checks that `ref.py` reproduces `cases.md` byte for byte. It then re-runs each
row on `ref.py`'s model, with NetworkX, XGI, the identities and the laws checked after every call,
asserts that every value matches the catalog cell, and writes the test. The precondition file also
takes the hand-written exit tests in `extra_traps.swift`.

There is no hash-law file. The vertices are `Int`s, and every read is in index space.

## Hand-written files

- **Conformance.**
  - Every `Hypergraphs` algorithm on an `IncidenceMatrix` equals the same algorithm on an
    `UndirectedIncidenceList<Int>` copy, and on an `OrientedIncidenceMatrix` the same on an
    `IncidenceList<Int>` copy.
  - `transposed()` is the lists' `dual()`, and `reversed` is their reversal.
  - Also: the conversions between all four types and from graphs (one column per edge in `edges`
    order, by vertex index), Codable round trips, copy-on-write, the resets and capacity, Hashable,
    and Sendable.
- **Edge cases** (`IncidenceMatrixEdgeCaseTests.swift`), one behavior each, written for the planted
  bugs the rest let through (`scripts/mutants/IncidenceMatrixModule.py`): the descriptions and
  their elision, hashing across storage strides, near-miss membership and equality, the trapping
  index reads, the decoder's overflow guards, and edge subscripts on the oriented matrix's
  incidence graph.
- **Properties** (swift-property-based, with shrinking):
  - B·Bᵀ = D + A on loopless multigraphs and Bᵀ·B = 2I + A(L(G)) on loopless simple graphs,
    computed from the public cells;
  - oriented B·Bᵀ = L, the Laplacian of the loopless underlying multigraph, with self-loops in
    the input;
  - cell-edit sequences on both matrices against a set of cells per plane, with every cell,
    column, row and degree and the handshake law checked after each step;
  - `transposed()` swapping rows and columns;
  - equality as cell for cell.
- **Maps and generations** (`IncidenceMatrixMapTests.swift`,
  `IncidenceMatrixMapPreconditionTests.swift`, `IncidenceMatrixMapPropertyTests.swift`): values
  follow appends and survive cell edits on both matrices; `removeAll` keeps the maps; the checked
  reads throw out of range; copies are copy-on-write; `transposed()`, `reversed` and the
  conversions carry no map (the handle traps there); equality and coding ignore maps; every
  structural mutation starts a generation and a cell edit that changes nothing does not; random
  mutations against arrays by column and row (swift-property-based).
- **Stress.**
  - A multigraph at n = 2 048 and m = 2 × 10⁴, api.md's benchmark shape.
  - 10⁵ cell edits against a set.
  - The components of a 512 × 512 matrix at density 1/8 against an incidence-list copy.

## Planted bugs

The suite was checked against a Swift model of the API in a scratch copy of the workspace, built
through Bazel, with one bug planted at a time. It caught every one:

| Planted bug | Caught by |
|---|---|
| A self-loop's unoriented column left zero (NetworkX's matrix) | IM-009, conversions, stress |
| A vertex on both sides given +1 instead of 0 | IM-041, IM-044 – IM-046 and 9 more |
| `transposed()` keeping the vertex count | IM-033, properties, conformance, stress |
| Equality ignoring the shape | IM-036, properties |
| A cell insert updating the column but not the row | IM-027, IM-031, IM-053, properties, stress |
| An undirected edge oriented v → u | IM-043, conversions |
| Oriented `reversed` returning the matrix unchanged | IM-050, conformance, copy-on-write |
