# GraphProducts test suite

`GraphProducts` has the four standard graph products as lazy views: `cartesianProduct(_:_:)`
(G □ H), `tensorProduct(_:_:)` (G × H), `strongProduct(_:_:)` (G ⊠ H) and
`lexicographicProduct(_:_:)` (G ∘ H). Each returns a struct holding both factors. Its vertex is
`Pair(g, h)`, with index `index(g)·|V(H)| + index(h)`. Its rows are computed from the factors'
index rows, so it stores no edge. The tests come from the proposed API (`api.md` in
[`Tests/Catalogs/GraphProducts/`](../Catalogs/GraphProducts/), phase 1), with its open questions
decided as recommended:

- the vertex type is the shared `Pair<First, Second>` (not a nested type per product, not
  `OrderedPair`);
- free functions, one overload for two `DirectedGraph`s and one for two `Graph`s;
- every product of loop-free or looped, simple or multigraph factors is defined edge by edge, with
  each generating tuple its own edge;
- the product types have no `Equatable`, `Hashable` or `Codable`;
- undirected ×, ⊠ and ∘ report no edge indices.

The suite uses only the public API, and each test is self-contained. The only shared material is
the seeded generator and the tags in `GrafluentTestSupport`.

## API under test

```swift
struct Pair<First: Hashable, Second: Hashable>: Hashable   // Comparable, Sendable, Codable, BitwiseCopyable when both are
    var first: First; var second: Second; init(_:_:); description "(g, h)"
func cartesianProduct(_:_:), tensorProduct(_:_:), strongProduct(_:_:), lexicographicProduct(_:_:)
    // (G: DirectedGraph, H: DirectedGraph) or (G: Graph, H: Graph)
CartesianProduct<First, Second> (and Tensor-, Strong-, LexicographicProduct):
    DirectedGraph, BidirectionalDirectedGraph or Graph as the factors are; Sendable when both are
    var first: First; var second: Second
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Numbering | (g, h) at index(g)·\|V(H)\| + index(h), row-major, as NamedGraphs' grid | GP-057, GP-065 |
| Row order | □: G-moves, then H-moves; ×: G outer, H inner; ⊠: □'s row, then ×'s; ∘: each G-neighbour with every H-vertex, then the H-moves | GP-003, GP-031, GP-045 |
| Edge order | □: every G-edge at every H-vertex, then every G-vertex with every H-edge; ⊠: □'s, then ×'s; ∘: G-edges by H-vertex pairs, then H-moves | GP-003, GP-032, GP-046 |
| Undirected × | Two edges per pair of non-loop factor edges, straight then crossed; one when either is a loop | GP-017, GP-023 – GP-025 |
| Undirected ∘ over a loop | Only h ≤ h′ | GP-051, GP-053 |
| Self-loops | Each generating tuple is its own edge, so counts can exceed NetworkX's MultiGraph | GP-011, GP-039, GP-051, GP-053 |
| Edge indices | □ always; directed ×, ⊠, ∘; never undirected ×, ⊠, ∘ | GP-066 – GP-068 |
| Hashing | Index-space rows hash nothing; a pair lookup hashes twice (one lookup per factor) | GP-014, GP-028, GP-042, GP-056 |
| Preconditions | A factor without vertex indices, a vertex count that overflows `Int`, a pair whose part is not a vertex | GP-069 – GP-071 |

## How values are pinned

api.md leaves the Swift spelling of the position types open (enum or struct, case and field
names, initializers). So the tests never name a position's parts. They pin each position through
what the protocols expose:

- its place in `edges` (positions are distinct, and `edges.indices` is sorted);
- its endpoints by value (`edges[p]`, `source`/`target`) and by index (`sourceIndex`/`targetIndex`,
  `endpointIndices`, `oppositeVertex`);
- its `edgeIndex` when there are edge indices;
- its offset in `edges` wherever it appears in a row.

Each catalog row builds the factors the way the catalog writes them: `AdjacencyList<String>` or
`UndirectedAdjacencyList<String>`, or `DirectedPseudograph` and `Pseudograph` when a factor has
parallel edges or self-loops. It then writes out the product's whole state:

- the vertices and their indices both ways;
- the counts and both bounds;
- every edge in order, by value and by index, and the edge indices;
- every row, by vertex and by index, with each row's positions given as offsets in `edges`;
- the in-rows of a directed product;
- `contains(_:)` for every vertex, and `contains(edge:)` for every ordered pair.

The rows that read `hashes` run again on a vertex type, local to the test, whose `hash(into:)`
counts. The identity rows also check P2 □ P3 against `UndirectedAdjacencyList<Int>.grid`, the
nested cube, and the swapped lexicographic product.

The catalog-row files are every file except `ProductConformanceTests.swift`,
`ProductPropertyTests.swift` and `ProductHashTests.swift`. `swiftgen.py` generated them from
`cases.md`. It sits next to `ref.py` and `cases.md` in
[`Tests/Catalogs/GraphProducts/`](../Catalogs/GraphProducts/):

```
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/GraphProducts/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. It then rebuilds each row's
product on the model, which checks it against the definitions, NetworkX and the laws, asserts that
the recomputed cell is the catalog's, and writes the test. The precondition file also takes the
hand-written exit tests in `extra_traps.swift`. A trap row runs the trapping call in a child process
(an exit test). The same setup then runs in this process without the fault, so the trap comes from
the call. GP-070's 2^32-vertex factor is an edgeless `Graph` conformer declared inside the test,
which stores only its count.

## Hand-written files

- **Conformance.** Seeded random pseudograph factors, with parallel edges and self-loops, under all
  four products and the swapped lexicographic one:
  - **Directed.** The copy is a `DirectedPseudograph` built by inserting every vertex's out-edges
    in row order, so its out-rows are the product's. BFS and DFS events, layers, the topological
    sort, strong and weak components, the condensation, `descendants`, `ancestors`, `hasPath`, hop
    counts and Dijkstra (distances, parents, parent edges mapped through `edges` order, and paths)
    must match exactly.
  - **CompressedSparseRow factors.** The product is forward-only, with no in-rows, and must search
    like its copy.
  - **Undirected.** The copy is `Pseudograph(product)`, whose positions are the offsets in `edges`.
    Components, `isConnected`, bridges (as offsets), articulation points, BFS layers as sets, hop
    counts and Dijkstra distances must match.
  - **Grids.** P_r □ P_c against NamedGraphs' `grid(dimensions: [r, c])`: the same index-space
    edges, rows and distances.
  - **Sendable and nesting.** A product crosses into a detached task, and Q3 nests either way.
- **Properties** (swift-property-based, with shrinking). Random factor pairs, directed and
  undirected, from the empty graph up, with loops and parallel edges, against each product's
  definition written out edge by edge in index space:
  - the edges in order;
  - `edgeCount`, and the undirected ×/∘ count formulas with ℓ_G and ℓ_H;
  - every row as a multiset;
  - breadth-first layers, connected (weak) components and, directed, ancestors, against the same
    computed over the rows: these walk each row in place through the products'
    `_forEach…Index` hooks, which must list the row's entries in its order;
  - each entry's position and its other end;
  - each edge met once per end over all rows (a self-loop twice in its row), and each arc once in
    an out-row and once in an in-row;
  - `contains(edge:)` for every pair, and the numbering both ways;
  - the edge-index law;
  - the loop-free degree formulas.

  Pair's laws: equality and hashing, lexicographic order as tuples compare, the description, and
  Codable by round trip.
- **Hash law.** A counting vertex type over both directions and all four kinds:
  - every index-space row, `vertex(atIndex:)`, `edges` by value, the counts and the bounds hash
    nothing;
  - `vertexIndex(of:)`, `contains(_:)` and a label-space row each hash twice;
  - a BFS over a strong product hashes the same with a path factor as with a complete one.

## Planted bugs

The suite was checked against 14 bugs planted in a Swift model of api.md, in a scratch copy of the
workspace. It caught every one.

| Planted bug | Caught by |
|---|---|
| `Pair`'s `<` comparing the second parts first | Pair laws, directed conformance |
| Directed × arcs with the H-ends swapped | GP-020 – GP-022, GP-027, properties, conformance |
| Undirected × without the crossed edge | GP-017, GP-018, GP-023 – GP-028, properties |
| Undirected × pairing a G-loop at both of its ends | GP-023, GP-025, GP-037, GP-039, properties, conformance |
| A pair lookup hashing a third time | GP-014, GP-028, GP-042, GP-056, hash law |
| Index rows looking their vertex up | GP-014, GP-028, GP-042, GP-056, hash law |
| □ H-part edge index g + eH·nG instead of g·mH + eH | GP-010, GP-057, properties, conformance |
| The loop-free degree formula used with self-loops | GP-023 – GP-025, GP-037 – GP-039, properties |
| Directed ∘ in-rows without the H-moves | GP-048 – GP-050, GP-055, properties, conformance |
| Column-major vertex numbering | GP-003 onwards, properties |
| □ rows listing H-moves before G-moves | most undirected rows |
| Undirected ∘ over a loop listing both (h, h′) and (h′, h) | GP-051, properties, conformance |
| No overflow check | GP-070, extra traps |
| A factor without vertex indices accepted | GP-069, extra traps |
