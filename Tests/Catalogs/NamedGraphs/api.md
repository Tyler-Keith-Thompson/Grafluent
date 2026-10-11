# NamedGraphs: proposed API

The README plan: "All families are static factories on the representation types, for example
`CompressedSparseRow.complete(vertexCount: 5)`." This file fixes where those factories live, the
vertex numbering of every family, the directed forms, the edge order, the traps and the
performance targets.

`cases.md` (NG-001 – NG-090, 90 rows) pins the values. `ref.py` builds every family from its
definition and checks each row against NetworkX 3.7 (exact edge set under our numbering), igraph 1.0
(exact where igraph numbers the same way, isomorphism for Petersen) and the count and degree laws.
`--stress` sweeps every family over a range of sizes, both kinds (863 combinations).

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/NamedGraphs/ref.py [--write] [--stress]`.

## Where the factories live

Two underscored protocols in `GraphProtocols`, one per kind, each with a single bulk requirement:

```swift
/// A representation that can be built in bulk from `0..<vertexCount` and a sorted edge list.
/// The caller guarantees the edges are sorted (row-major), have no repeats and no self-loops,
/// and that every endpoint is in range, so the conformer checks nothing per edge.
public protocol _DirectedGraphConstruction: DirectedGraph where Vertex == Int {
    init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>)
}
/// The same for undirected graphs: `UndirectedEdge(u, v)` with `u < v`, sorted lexicographically.
public protocol _GraphConstruction: Graph where Vertex == Int {
    init(_vertexCount: Int, sortedEdges: some Collection<UndirectedEdge<Int>>)
}
```

Each family is written once, as an `extension _DirectedGraphConstruction` / `extension
_GraphConstruction` static, and reaches every conformer:

| Conformer | Protocol | Bulk build from sorted edges |
|---|---|---|
| `CompressedSparseRow` | directed | O(n + m), one pass: `_build` already detects canonical input and fills `offsets`/`targets` without its two counting sorts. Two exact-size allocations |
| `AdjacencyMatrix` | directed | O(n²/64 + m): zeroed bit rows, one bit per edge |
| `AdjacencyList<Int>` | directed | O(n + m) expected: n slot-dictionary inserts and one slot-pair entry per edge (the representation's own hashing), rows reserved at their exact size |
| `DirectedPseudograph<Int>`, `DirectedMultigraph<Int>` | directed | as `AdjacencyList` (same storage); the multigraph skips its self-loop check, since there are none |
| `StableDirectedGraph<Int>` | directed | O(n + m) expected, pages filled in order |
| `UndirectedAdjacencyList<Int>`, `Pseudograph<Int>`, `Multigraph<Int>` | undirected | O(n + m) expected, as `AdjacencyList` |

Shapes that are a structure get their own statics, built through the structure's dense
initializers and never re-validated:

| Type | Factories |
|---|---|
| `Tree<Int>` | `path(vertexCount:)`, `star(vertexCount:)`: O(n) through the dense `_TreeLayout` (no vertex dictionary), as `Tree(pruferSequence:)` does |
| `BipartiteGraph<Int>` | `completeBipartite(leftCount:rightCount:)`: sides known, no 2-colouring pass |

Package changes (outside this folder): `GraphProtocols` gains the two protocols; each
representation module adds its conformance, written against a `package` unchecked bulk initializer;
`NamedGraphs` depends on `GraphProtocols`, `Trees` and `BipartiteGraphs`. `LabeledGraph` and
`EdgeList` do not conform: a labeled graph's labels are not `Int`s (`LabeledGraph(CompressedSparseRow.grid(dimensions: [3, 4]), labels: …)` labels one), and an
`EdgeList` cannot hold isolated vertices.

## API

n = vertices, m = edges (arcs for directed conformers).

```swift
extension _GraphConstruction {            // and the same names on _DirectedGraphConstruction
    public static func complete(vertexCount n: Int) -> Self
    public static func completeBipartite(leftCount a: Int, rightCount b: Int) -> Self
    public static func path(vertexCount n: Int) -> Self
    public static func cycle(vertexCount n: Int) -> Self
    public static func star(vertexCount n: Int) -> Self
    public static func wheel(vertexCount n: Int) -> Self
    public static func grid(dimensions: [Int], periodic: Bool = false) -> Self
    public static func hypercube(dimension d: Int) -> Self
    public static func petersen() -> Self
    public static func empty(vertexCount n: Int) -> Self
}
extension Tree where Vertex == Int {
    public static func path(vertexCount n: Int) -> Tree      // n ≥ 1
    public static func star(vertexCount n: Int) -> Tree      // n ≥ 1
}
extension BipartiteGraph where Vertex == Int {
    public static func completeBipartite(leftCount a: Int, rightCount b: Int) -> BipartiteGraph
}
```

### Families

| Factory | Vertices | Undirected edges | Directed form | n, m (undirected) | Rows |
|---|---|---|---|---|---|
| `complete(vertexCount:)` | `0..<n` | every pair | both arcs | n, n(n−1)/2 | NG-001 – NG-011 |
| `completeBipartite(leftCount:rightCount:)` | left `0..<a`, right `a..<a+b` (NetworkX) | every left–right pair | left → right (igraph `Full_Bipartite(mode="out")`) | a+b, ab | NG-012 – NG-020 |
| `path(vertexCount:)` | `0..<n` | i – i+1 | i → i+1 | n, max(n−1, 0) | NG-021 – NG-029 |
| `cycle(vertexCount:)` | `0..<n`, n ≥ 3 | i – (i+1) mod n | i → (i+1) mod n | n, n | NG-030 – NG-037 |
| `star(vertexCount:)` | hub 0, leaves `1..<n`, n ≥ 1 | 0 – i | hub → leaf | n, n−1 | NG-038 – NG-044 |
| `wheel(vertexCount:)` | hub 0, rim `1..<n`, n ≥ 4 | 0 – i, rim cycle 1 – 2 – … – (n−1) – 1 | hub → rim, rim i → i+1 and n−1 → 1 (star and cycle composed; NetworkX has no directed wheel) | n, 2(n−1) | NG-045 – NG-051 |
| `grid(dimensions:periodic:)` | row-major: x = (x₀, …, x_{k−1}) is Σ xᵢ·Πⱼ₍ⱼ>ᵢ₎ dⱼ, the last dimension fastest | x – x+eᵢ; with `periodic`, also the wrap edge in each dimension of length ≥ 3 | both arcs | Πdᵢ, Σᵢ (dᵢ−1 or dᵢ when it wraps)·Πⱼ≠ᵢ dⱼ | NG-052 – NG-068 |
| `hypercube(dimension:)` | `0..<2^d`, bit k is coordinate k | u – u ^ (1 << k) | both arcs | 2^d, d·2^(d−1) | NG-069 – NG-076 |
| `petersen()` | NetworkX's: outer 0–1–2–3–4, spokes i – i+5, inner 5–7–9–6–8 | 15 edges | both arcs | 10, 15 | NG-077, NG-078 |
| `empty(vertexCount:)` | `0..<n` | none | none | n, 0 | NG-079 – NG-083 |

**The directed form.** Families with a natural orientation (path, cycle, star, wheel, complete
bipartite) get one arc per edge along it. Families without one (complete, grid, hypercube, Petersen)
get both arcs, which is `graph.directed` materialized. This is NetworkX's `create_using=nx.DiGraph`
everywhere NetworkX allows it (complete, path, cycle, star, grid_2d), and NetworkX's `nx.DiGraph(G)`
for the rest. igraph orients a directed `Hypercube` from lower to higher index and a directed
`Lattice` along increasing coordinates unless `mutual=True`; we follow NetworkX and keep one rule.

**Edge order is part of the contract.** Undirected edges are `UndirectedEdge(u, v)` with `u < v`, in
lexicographic order; directed edges are in row-major order. So `edges` reads the same on every
conformer (NG-084 – NG-090), CSR builds in one pass, and an adjacency list's positions are
predictable. Cycle's closing edge is `UndirectedEdge(0, n − 1)`, second in the list (NG-031).

**Grids against the libraries.** NetworkX's `grid_2d_graph(r, c)` node `(i, j)` is our `i·c + j`.
NetworkX's `grid_graph(dim)` lists the coordinates the other way round: its node `(x_{k−1}, …, x₀)` is
ours. igraph's `Lattice(dims)` runs the first dimension fastest, so ours is `Lattice(dims.reversed())`.
`ref.py` checks all three.

### Traps

| Trap | Rows | Note |
|---|---|---|
| Negative count, side or dimension | NG-010, NG-020, NG-029, NG-067, NG-075, NG-083 | |
| Edge or vertex count overflows `Int` | NG-011, NG-068, NG-076 | checked with `multipliedReportingOverflow` before allocating |
| `cycle` with n < 3 | NG-034 – NG-037 | Cₙ is defined for n ≥ 3; C₁ and C₂ are not simple. NetworkX gives a self-loop for `cycle_graph(1)` and a single edge for `cycle_graph(2)`. One rule on every type, directed included (NG-037) |
| `wheel` with n < 4 | NG-050, NG-051 | the rim must be a cycle |
| `star` with n < 1 | NG-043 | no hub |
| `grid(dimensions: [])` | NG-066 | NetworkX gives the null graph; we trap, since the empty product is ambiguous |
| `Tree.path` / `Tree.star` with n < 1 | NG-028 | a `Tree` has at least one vertex |

Behaviours that are not traps: `complete(0)`, `path(0)`, `empty(0)` and `completeBipartite(0, 0)` are
the null graph; a dimension of 0 gives the null graph (NG-056); a periodic dimension of length 1 or
2 adds no wrap edge, so there is never a self-loop or a repeat (NG-060, NG-061: NetworkX's
`grid_graph` wraps a length-1 dimension into a self-loop); `hypercube(dimension: 0)` is K₁, as in
igraph (NetworkX's `hypercube_graph(0)` is the null graph, NG-069).

### Complexity and performance targets

Every factory is O(n + m) time and builds no intermediate hash table. The Θ(n²) families
(`complete`, `completeBipartite`) pass a lazy collection that computes its edges, so no edge array
is ever allocated; the others pass an exact-capacity array of m edges, freed after the build. The
body of each family is non-generic except for the final bulk initializer, so a family adds one small
specialization per conformer used.

Reference timings, measured on this machine with NetworkX 3.7 and python-igraph 1.0 (best of 3):

| Graph | NetworkX | igraph | Target, `CompressedSparseRow` | Target, `UndirectedAdjacencyList<Int>` |
|---|---|---|---|---|
| `complete(vertexCount: 2000)` (2.0 M edges) | 664 ms | 60 ms | ≤ 15 ms (4 M arcs, one pass) | ≤ 60 ms |
| `grid(dimensions: [300, 300])` | 152 ms | 3.5 ms | ≤ 2 ms | ≤ 5 ms |
| `hypercube(dimension: 16)` (524 k edges) | 4521 ms | 10.4 ms | ≤ 5 ms | ≤ 15 ms |
| `path(vertexCount: 1_000_000)` | 866 ms | 20 ms | ≤ 5 ms | ≤ 30 ms |

The CSR targets are the cost of writing `offsets` and `targets` once; the adjacency-list targets
are igraph's time, since that representation hashes every vertex and edge by design. Benchmarks go in
`Benchmarks/Benchmarks/NamedGraphsBenchmarks`, one per family per conformer kind.

## Names

| Factory | Decision | NetworkX | igraph | JGraphT | Mathematica |
|---|---|---|---|---|---|
| `complete(vertexCount:)` | the shared word | `complete_graph` | `Full` | `CompleteGraphGenerator` | `CompleteGraph` |
| `completeBipartite(leftCount:rightCount:)` | sides named `left`/`right` as `BipartiteGraph` does | `complete_bipartite_graph` | `Full_Bipartite` | `CompleteBipartiteGraphGenerator` | `CompleteGraph[{m, n}]` |
| `path(vertexCount:)` | | `path_graph` | `Ring(circular=False)` | `LinearGraphGenerator` | `PathGraph` |
| `cycle(vertexCount:)` | | `cycle_graph` | `Ring` | `RingGraphGenerator` | `CycleGraph` |
| `star(vertexCount:)` | counts every vertex, as igraph, JGraphT and Mathematica do. NetworkX's `star_graph(n)` has n + 1 vertices (NG-044) | `star_graph` | `Star` | `StarGraphGenerator` | `StarGraph` |
| `wheel(vertexCount:)` | counts every vertex, as all four do | `wheel_graph` | `Wheel` (C) | `WheelGraphGenerator` | `WheelGraph` |
| `grid(dimensions:periodic:)` | NetworkX's words (`dim`, `periodic`); one entry for every dimension count | `grid_graph`, `grid_2d_graph` | `Lattice(circular=)` | `GridGraphGenerator` | `GridGraph` |
| `hypercube(dimension:)` | | `hypercube_graph` | `Hypercube` | `HyperCubeGraphGenerator` | `HypercubeGraph` |
| `petersen()` | | `petersen_graph` | `Famous("Petersen")` | `NamedGraphGenerator.petersenGraph` | `PetersenGraph` |
| `empty(vertexCount:)` | | `empty_graph` | `Graph(n)` | `EmptyGraphGenerator` | `EmptyGraph` |

No `Graph` suffix: the type already says it. No `lattice` spelling beside `grid`, and no 2-D
`grid(rowCount:columnCount:)` beside `grid(dimensions:)`.

## Open questions, with recommendations

1. **Where factories live.** *Recommended: the two underscored protocols above.* Alternatives
   considered:
   - Per-type statics: 10 families × 9 conformers of nearly identical code, and each new conformer
     needs all of them.
   - A factory over `MutableDirectedGraph` (JGraphT's `GraphGenerator.generateGraph(target)`, petgraph's
     `Build`): excludes `CompressedSparseRow` and `AdjacencyMatrix`, and inserting one edge at a time
     costs a membership check per edge.
   - A public protocol: no library names this capability. Boost has the same arrangement by
     convention, with no named concept: every graph type has an edge-iterator constructor
     `Graph(first, last, n)`, and Boost's generators are edge iterators. An underscored protocol keeps
     the name out of the API, like `MutableDirectedGraph`'s `_insertVertex` hooks, until one is
     established.

   The bulk requirement takes sorted, simple input, so a conformer validates nothing and CSR takes
   its one-pass path.
2. **Vertex type.** *Recommended: `Int` vertices `0..<n` everywhere, with the numbering of each family
   documented above* (grid row-major, hypercube by bits, Petersen as NetworkX). Tuple vertices (NetworkX's
   grids and hypercubes) are not `Hashable` in Swift and would rule out CSR and the matrix. A caller who
   wants coordinates computes them from the index or labels the graph with `LabeledGraph`.
3. **`empty(vertexCount:)` overlaps `init(vertexCount:)`** on `CompressedSparseRow` and
   `AdjacencyMatrix`. *Recommended: keep it.* It is the plan's "empty graph", NetworkX's `empty_graph`,
   and the only spelling every conformer shares (`AdjacencyList<Int>` has no `init(vertexCount:)`). It is
   a factory, not a typealias.
4. **Wheel and cycle lower bounds.** *Recommended: trap below 4 and 3* (rows above), rather than
   NetworkX's degenerate small cases, so every result is a simple graph of the named shape.
5. **More `Tree` and `BipartiteGraph` shapes** (`Tree.complete(arity:height:)`, NetworkX's
   `balanced_tree`; bipartite paths and grids). *Recommended: defer.* They are not in the plan, and the
   protocol makes them one function each later.
6. **Generalized Petersen GP(n, k)** (JGraphT, Mathematica's `PetersenGraph[n, k]`). *Recommended:
   defer.* If added, it is `petersen(vertexCount:step:)` beside `petersen()`, with `petersen()` being
   GP(5, 2) under NetworkX's numbering, which is already GP(5, 2)'s standard numbering.
