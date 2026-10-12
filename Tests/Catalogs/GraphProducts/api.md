# GraphProducts: proposed API (phase 1)

This module provides the four standard graph products, G □ H, G × H, G ⊠ H and G ∘ H, as **lazy
views**. A product never stores an edge. Vertex (g, h) has index `index(g)·|V(H)| + index(h)`,
row-major, the numbering NamedGraphs' grids already use. Every row is computed from the two
factors' index rows, with one division per row and no hashing. An edge's position names the factor
edge or edges, and the factor vertices, that generate it. The products are therefore defined edge
by edge on multigraphs and pseudographs too. To materialize one, pass it to a representation's
initializer (`CompressedSparseRow(cartesianProduct(g, h))`).

`cases.md` (GP-001 – GP-071, 71 rows) pins the values. `ref.py` ports the factors (directed and
undirected, with parallel edges and self-loops kept) and implements all four products in both
directions, counting every factor label lookup as a hash. Each product is checked against:

- the definitions, edge by edge;
- NetworkX 3.7's `cartesian_product`, `tensor_product`, `strong_product` and
  `lexicographic_product`, both on simple factors as `Graph` / `DiGraph` and on loop-free factors
  as `MultiGraph` / `MultiDiGraph`, where positions must match keys one for one;
- NamedGraphs' grid numbering: P_r □ P_c is `grid(dimensions: [r, c])`;
- the protocol laws and the degree formulas, on loop-free factors: □ is d_G + d_H, × is d_G·d_H, ⊠
  is d_G + d_H + d_G·d_H, and ∘ is d_G·|V(H)| + d_H;
- the boundary law that index-space members hash nothing.

python-igraph 1.0 exposes no product function, so igraph is not an oracle here. The benchmark
baseline is igraph's C library product, if the pinned version has one; check before benchmarking.
`--stress` runs 3,200 random products: 400 factor pairs for each of the four kinds, directed and
undirected.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/GraphProducts/ref.py [--write] [--stress]`.

## Names

| Name | Decision | Source |
|---|---|---|
| Cartesian product G □ H | **`cartesianProduct(_:_:)`** → **`CartesianProduct<First, Second>`** | NetworkX `cartesian_product`; Mathematica `GraphProduct[g, h, "Cartesian"]`; Hammack–Imrich–Klavžar |
| Tensor product G × H | **`tensorProduct(_:_:)`** → **`TensorProduct<First, Second>`** | NetworkX `tensor_product`; Mathematica `"Tensor"`. Also called the direct, categorical or Kronecker product; those names go in the doc comment, not in typealiases |
| Strong product G ⊠ H | **`strongProduct(_:_:)`** → **`StrongProduct<First, Second>`** | NetworkX `strong_product`; Mathematica `"Strong"` |
| Lexicographic product G ∘ H | **`lexicographicProduct(_:_:)`** → **`LexicographicProduct<First, Second>`** | NetworkX `lexicographic_product`; Mathematica `"Lexicographic"`. Also called the composition; doc comment only |
| Product vertex (g, h) | **`Pair<First: Hashable, Second: Hashable>`**, with `first` and `second` | JGraphT `Pair<A, B>` (`getFirst` / `getSecond`); C++ `std::pair`. The literature's "ordered pair" |
| The factors | **`first`**, **`second`** on each product | Match `Pair`. NetworkX's parameter names are G and H, used in the doc comments |

Free functions rather than methods, because a product treats its factors symmetrically. NetworkX
writes `cartesian_product(G, H)`, and swift-algorithms writes `product(_:_:)` for sequences.

### Question 2: the vertex type

Tuples are not `Hashable`, and `Vertex: Hashable` is a protocol requirement, so the vertex is a
struct. The options were:

- a nested type per product. Rejected: `CartesianProduct<G, H>.Vertex` and
  `TensorProduct<G, H>.Vertex` would be different types for the same (g, h), and a vertex could
  not move between products of the same factors, nor feed a nested product;
- an invented `ProductVertex`. Rejected: no library uses the name;
- **`Pair`**. Chosen: one shared struct in this module, as JGraphT's `Pair` and C++'s `std::pair`.

`Pair` is `Hashable`, `Sendable`, `Codable` and `BitwiseCopyable` when both parts are, `Comparable`
lexicographically when both are (as tuples compare), and `CustomStringConvertible` as `(g, h)`. The
risk is that an app with its own `Pair` shadows ours. Code that needs ours then writes
`GraphProducts.Pair`, the same remedy as `Walks.Path`. If that cost is judged too high, the
fallback is `OrderedPair` (the literature's term). There is no typealias either way.

A nested product such as `cartesianProduct(cartesianProduct(a, b), c)` has vertices
`Pair<Pair<A, B>, C>`, and its index is `(i·|B| + j)·|C| + k` (GP-058).

## Question 1: index space

- **`vertexIndexBound`** is |V(G)|·|V(H)|. Building the product traps when either factor has no
  vertex indices (`StableDirectedGraph` with holes, phase 1; GP-069), or when the product
  overflows `Int`. The overflow guard is written as the comparison `nG <= Int.max / nH`, not as
  `multipliedReportingOverflow` (GP-070).
- **`vertex(atIndex: i)`** costs one `quotientAndRemainder(dividingBy: nH)` and two factor
  `vertex(atIndex:)` calls.
- **`vertexIndex(of: p)`** makes two factor lookups, which is two hashes for factors with hashed
  vertices (GP-014). A pair whose part is not in its factor traps (GP-071). `contains(_:)` is false
  in that case and does not trap.
- **Rows** (`successorIndices(ofIndex:)`, `neighborIndices(ofIndex:)`, `outEdges(ofIndex:)`, …)
  split the index once and walk the factor rows. They never hash: zero lookups over every row of
  every product (GP-014, GP-028, GP-042, GP-056).

| Product | Row of (g, h), in order | Degree (loop-free) |
|---|---|---|
| □ | G-moves `(g′, h)` for g′ in G's row of g, then H-moves `(g, h′)` | d_G + d_H |
| × | `(g′, h′)` for g′ in G's row, h′ in H's row (G outer) | d_G·d_H |
| ⊠ | □'s row, then ×'s | d_G + d_H + d_G·d_H |
| ∘ | `(g′, h′)` for g′ in G's row and **every** h′ in V(H), then H-moves `(g, h′)` | d_G·\|V(H)\| + d_H |

**Edge positions** are nested `Edges.Index` types, ordered as `edges` lists them. Each is a
`@frozen` generic type nested in its product, over the factors' position types
(`CartesianProduct<G, H>.Position<G.Edges.Index, H.Edges.Index>`), so one type serves the
directed and the undirected product. All are `Hashable` and `Comparable`, and `Sendable` when the
factor positions are. Enum cases are public, and the tensor struct has a public memberwise
`init(first:second:reversed:)`; nothing is checked, as with `DirectedView.Edges.Index`:

| Product | Type | Cases or fields |
|---|---|---|
| □ | `enum CartesianProduct.Position` | `.first(edge: FirstEdge, vertexIndex: Int)` (G's edge at H's vertex index), `.second(vertexIndex: Int, edge: SecondEdge)` |
| × | `struct TensorProduct.Position` | `first: FirstEdge`, `second: SecondEdge`, `reversed: Bool` |
| ⊠ | `enum StrongProduct.Position` | `.first(edge:vertexIndex:)`, `.second(vertexIndex:edge:)` as □, then `.both(first:second:reversed:)` as × |
| ∘ | `enum LexicographicProduct.Position` | `.first(edge: FirstEdge, uVertexIndex: Int, vVertexIndex: Int)` (H's vertex indices at the G-edge's `u` end, directed its source, and at its `v` end, directed its target), `.second(vertexIndex: Int, edge: SecondEdge)` |

The comparisons are the derived ones for □ and ∘ (case order, then the associated values), and
written out for × and ⊠ (`Bool` is not `Comparable`; straight before reversed). The end index of
□, ∘ is `.second(vertexIndex: |V(G)|, edge: H.edges.startIndex)`, and of ×, ⊠ the tensor position
past G's last edge. The positions in detail:

- □: `.first(edgeOfG, vertexIndexOfH)` for every G-edge and H-vertex, G-edge outer, then
  `.second(vertexIndexOfG, edgeOfH)`.
- ×: `(edgeOfG, edgeOfH, reversed)`. `reversed` is `DirectedView.Edges.Index`'s field name. In an
  undirected product a pair of non-loop edges {a, b}, {c, d} yields two edges, the straight
  {(a,c),(b,d)} and the reversed {(a,d),(b,c)}. When either edge is a self-loop the two coincide
  and there is one (GP-023 – GP-025). Directed, `reversed` is always false.
- ⊠: the □ positions, then the × positions.
- ∘: `.first(edgeOfG, uH, vH)` for every G-edge and every pair of H-vertices. Over an
  undirected self-loop at a there is only `uH ≤ vH`, since (a,h)–(a,h′) and (a,h′)–(a,h)
  are one edge. Then `.second(vertexIndexOfG, edgeOfH)`.

**Edge indices**, when both factors have dense ones:

- **□**, both directions (GP-066): `eG·nH + h`, then `mG·nH + g·mH + eH`.
- **Directed ×**: `eG·mH + eH`.
- **Directed ⊠**: □, then × (GP-067).
- **Directed ∘**: `eG·nH² + h·nH + h′`, then `mG·nH² + g·mH + eH`.
- **Undirected ×, ⊠ and ∘** report `nil` (GP-068). There a self-loop changes how many product edges
  a factor pair yields, so the index is not arithmetic. A rank structure would fix that in phase 2.

**Counts.** The directed `edgeCount` and the undirected □ `edgeCount` are O(1). The undirected ×,
⊠ and ∘ counts need the factors' self-loop counts: ℓ_G and ℓ_H, O(mG + mH) per call.

- × has 2·mG·mH − (ℓ_G·mH + ℓ_H·mG − ℓ_G·ℓ_H) edges.
- ∘ has (mG − ℓ_G)·nH² + ℓ_G·nH(nH + 1)/2 + nG·mH edges.

**Undirected self-loops in rows.** A self-loop sits twice in its vertex's incident row (the `Graph`
law). The product row must list each product edge once per end at (g, h), so the row iterator
keeps the loops it has met in a short array, as `DirectedView.Arcs.Iterator` does:

- **× (and ⊠'s × part):** a G-loop pairs only from its first appearance; an H-loop pairs only from
  its first appearance when the G-edge is not a loop (GP-023 – GP-025, GP-037 – GP-039).
- **∘:** a G-loop's first appearance yields (a, h′) for every h′ (position min/max). Its second
  appearance yields only (a, h), the product loop's second end (GP-051, GP-053).

ref.py checks that every edge meets its ends exactly twice over all rows.

**Differences from NetworkX:** none on loop-free factors, simple or multi. On factors with
self-loops NetworkX's `MultiGraph` merges product edges that share their ends and their factor key,
so the counts differ:

| Rows | Product | NetworkX | Here |
|---|---|---|---|
| GP-011 | □ of two single-vertex loops | 1 edge | 2 |
| GP-039 | ⊠ | 2 | 3 |
| GP-051 | ∘ | 8 | 9 |
| GP-053 | ∘ | 1 | 2 |

The rows note NetworkX's count. Here each generating tuple is its own edge, so `edgeCount`, the
rows and the degree sum always agree.

## API

```swift
@frozen public struct Pair<First: Hashable, Second: Hashable>: Hashable {
    public var first: First
    public var second: Second
    public init(_ first: First, _ second: Second)
}
// Comparable (lexicographic), Sendable, Codable, BitwiseCopyable, CustomStringConvertible "(g, h)",
// each when both parts are.

public func cartesianProduct<G: DirectedGraph, H: DirectedGraph>(_ g: G, _ h: H) -> CartesianProduct<G, H>
public func cartesianProduct<G: Graph, H: Graph>(_ g: G, _ h: H) -> CartesianProduct<G, H>
// likewise tensorProduct, strongProduct, lexicographicProduct. A mixed pair (one directed factor,
// one undirected) matches neither overload and does not compile.

@frozen public struct CartesianProduct<First, Second> {
    public var first: First { get }
    public var second: Second { get }
}
extension CartesianProduct: DirectedGraph where First: DirectedGraph, Second: DirectedGraph
extension CartesianProduct: BidirectionalDirectedGraph where First: BidirectionalDirectedGraph, Second: BidirectionalDirectedGraph
extension CartesianProduct: Graph where First: Graph, Second: Graph
// Vertex == Pair<First.Vertex, Second.Vertex>; Vertices: a RandomAccessCollection over 0..<nG·nH.
// TensorProduct, StrongProduct and LexicographicProduct are shaped the same way.
```

One generic type with conditional conformances to both `DirectedGraph` and `Graph` compiles. Each
constrained extension declares its own nested `Edges` type and members, checked on Swift 6 in a
scratch file. No product is both, because no factor is.

Phase 1 has no `Equatable`, `Hashable` or `Codable` on the product types. Compare or encode a
materialized copy. That matches the GraphOperations views and NetworkX's views. Products are
`Sendable` when both factors are.

### Parallel arcs in a directed strong product

A directed ⊠ can have parallel arcs although neither factor has any: a G-loop at g with an H-arc
h → h′ gives (g, h) → (g, h′) twice, once as the □ arc `.second(g, h→h′)` and once as the × arc
`.both(g→g, h→h′)`. The product lists both, and `edgeCount`, the rows and the degrees count both.
`CompressedSparseRow(product)` and `AdjacencyList(product)` merge them, as those types keep simple
graphs; materialize into `DirectedPseudograph(product)` to keep every arc. `strongProduct`'s doc
comment says so. Undirected, a G-loop and an H-edge likewise give a □ edge and a × edge on the same
ends; `Pseudograph(product)` keeps both.

### Row types and the measured traps

- Stored generic iterators cost about 3× in index-space loops. A row's iterator nevertheless holds
  the factor rows' iterators (one per factor; the undirected ×, ⊠ and ∘ rows also hold the factors
  by one reference); there is no integer-cursor path. Algorithms that walk every row (union–find,
  breadth-first search) go through `_forEachSuccessorIndex`, `_forEachPredecessorIndex` and
  `_forEachNeighborIndex`, which each product implements as loops over its factors' own hooks, with
  no row value: □ and ∘ components then run at or under the copy's, and ⊠ reads H's row once per
  vertex into a stack buffer.
- ∘'s G-part is a counted loop over `0..<nH` for each G-neighbour, with no inner iterator.
- No `lazy.map { self… }`: it copies the product, and both factors, on every call.
- `_withSuccessorIndexRows` and `_withIncidentIndexRows` are `nil`. The rows are computed.
- The public row types are nested in each product. Directed rows and □'s undirected rows are
  generic over the factor rows (`CartesianProduct.IndexRow<First.SuccessorIndices,
  Second.SuccessorIndices>`, `EdgeRow`, and □'s `EdgeIndexRow`), so one type serves out-rows,
  in-rows and undirected rows. The undirected ×, ⊠ and ∘ rows (`UndirectedIndexRow`,
  `UndirectedEdgeRow`) walk each factor's neighbor indices and incident positions in step, to tell
  a self-loop's two appearances apart; their position rows also read the factor edge's ends
  (`endpointIndices(ofEdgeAt:)`, O(1) on the adjacency lists) for `reversed` and for ∘'s
  orientation. Factor rows are re-iterated (the H-row once per G-entry in ×), never copied.
- `vertices` is a `LazyMapCollection` over `0..<|V(G)|·|V(H)|`; label-space rows are the index
  rows mapped through `vertex(atIndex:)`, so `neighbors(of:)` costs the two lookups of
  `vertexIndex(of:)` and no more.

## Complexity

| Member | □ | × | ⊠ | ∘ |
|---|---|---|---|---|
| Build | O(1) | O(1) | O(1) | O(1) |
| Row, one vertex | O(d_G + d_H) | O(d_G·d_H) | O(d_G + d_H + d_G·d_H) | O(d_G·nH + d_H) |
| `outDegree(ofIndex:)` / `degree(ofIndex:)` | O(1) from the factors' degrees | directed O(1); undirected the factors' degrees and loop counts, O(d_G + d_H) | as × | directed O(1); undirected O(d_G) |
| `edgeCount` | O(1) | directed O(1); undirected O(mG + mH) | as × | as × |
| `edgeIndexBound` | O(1) | directed O(1); undirected `nil` | as × | as × |
| `contains(edge: (g,h)→(g′,h′))` | g = g′ and the H-edge, or h = h′ and the G-edge: factor `contains(edge:)`, O(1) | both factor edges | either | the G-edge, or g = g′ and the H-edge |

An undirected degree law needs care. With a self-loop in a factor the loop-free formula is wrong
(a loop counts 2 in the factor, but its product contribution depends on the kind). The undirected
×, ⊠ and ∘ degrees use closed forms in the factors' degrees and self-loop counts ℓ (a loop is two
entries of its row, so ℓ_g is half the entries of g's row that are g; counting them is O(d), not
the product row's O(d_G·d_H)):

- ×: (d_G − 2ℓ_g)·(d_H − ℓ_h) + ℓ_g·d_H. A G-entry that is not a loop meets each H-entry but an
  H-loop's second appearance; a G-loop, counted at its first appearance, meets every H-entry.
- ⊠: d_G + d_H, the Cartesian moves, plus ×'s.
- ∘: (d_G − 2ℓ_g)·|V(H)| + ℓ_g·(|V(H)| + 1) + d_H. A G-entry that is not a loop gives a whole
  block; a G-loop its block at its first appearance and (g, h) at its second.
- □: d_G + d_H, which holds with loops too.

The randomized property test compares each with the row's length on pseudographs with loops.

## Performance targets

| Benchmark | Target |
|---|---|
| BFS and `connectedComponents()` on `cartesianProduct(g, h)`, g and h 1k-vertex sparse graphs (UndirectedAdjacencyList), vs the same on `UndirectedAdjacencyList(product)` materialized | ≤ 1.2× |
| The same for ⊠ and ∘ | ≤ 1.2× |
| BFS on the product vs NetworkX `cartesian_product` + BFS | ≥ 50× faster |
| BFS on the product vs the C library's product + BFS, if it has one | ≤ 1× of build + BFS |
| `CompressedSparseRow(cartesianProduct(g, h))` (materializing) vs NetworkX `cartesian_product` | ≥ 30× faster |
| P_r □ P_c vs NamedGraphs `grid(dimensions: [r, c])`, BFS | ≤ 1.2× (the grid is a CSR) |
| Hashes in index-space members | 0 (catalog rows; property-tested) |

## Phase 2

- Factors without dense vertex indices (sparsely indexed `StableDirectedGraph`): index through
  `vertexPosition`.
- Edge indices for undirected ×, ⊠ and ∘ through rank over the factors' loop flags.
- Other products, only if asked for: NetworkX's `rooted_product`, `corona_product` and
  `modular_product`.
- Products of more than two factors without nesting: `cartesianProduct(_:_:_:)`. Nesting already
  works (GP-058).
