# NamedGraphs: proposed API

The README plan: "All families are static factories on the representation types, for example
`CompressedSparseRow.complete(vertexCount: 5)`." This file fixes where those factories live, the
vertex numbering of every family, the directed forms, the edge order, the traps and the
performance targets.

`cases.md` (NG-001 – NG-135, 135 rows) pins the values. `ref.py` builds every family from its
definition and checks each row against NetworkX 3.7 (exact edge set under our numbering), igraph 1.0
(exact where igraph numbers the same way, isomorphism for Petersen) and the count and degree laws.
`--stress` sweeps every family over a range of sizes, both kinds (1457 combinations).

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/NamedGraphs/ref.py [--write] [--stress]`.

## Where the factories live

Two underscored protocols in `GraphProtocols`, one per kind, each with a single bulk requirement:

```swift
/// A representation that can be built in bulk from `0..<vertexCount` and a sorted edge list.
/// The caller guarantees the edges are sorted (row-major), have no repeats and no self-loops,
/// and that every endpoint is in range, so the conformer checks nothing per edge (debug builds
/// assert it in O(m)).
public protocol _DirectedGraphConstruction: DirectedGraph where Vertex == Int {
    init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>, _: _ConstructionToken)
}
/// The same for undirected graphs: `UndirectedEdge(u, v)` with `u < v`, sorted lexicographically.
public protocol _GraphConstruction: Graph where Vertex == Int {
    init(_vertexCount: Int, sortedEdges: some Collection<UndirectedEdge<Int>>, _: _ConstructionToken)
}
```

`_ConstructionToken` is public but has only a `package` initializer, so code outside the package
cannot call the unchecked requirement and hand a conformer edges it would write out of bounds.

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
| `Tree<Int>` | `path(vertexCount:)`, `star(vertexCount:)`, `balancedTree(branchingFactor:height:)`: O(n) through the dense `_TreeLayout` (no vertex dictionary), as `Tree(pruferSequence:)` does |
| `BipartiteGraph<Int>` | `completeBipartite(leftCount:rightCount:)`: sides known, no 2-colouring pass |

Package changes (outside this folder): `GraphProtocols` gains the two protocols; each
representation module adds its conformance, written against a `package` unchecked bulk initializer,
`init(_uncheckedVertexCount:sortedEdges:)`; `Trees` adds `package Tree(_vertexCount:treeEnds:)` (the
dense layout from known tree edges) and `BipartiteGraphs` adds `package BipartiteGraph(_leftCount:graph:)`
(sides known, no 2-colouring); `NamedGraphs` depends on `GraphProtocols`, `Trees` and `BipartiteGraphs`.
The lazy pair collections (`_AscendingPairs`, `_DistinctPairs`, `_CrossPairs`) and the count checks are
`package`, so `RandomGraphs` reuses them for its complete-graph shortcuts. `LabeledGraph` and
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
    // Phase 1 additions
    public static func ladder(rungCount n: Int) -> Self
    public static func circularLadder(rungCount n: Int) -> Self
    public static func barbell(cliqueVertexCount k: Int, pathVertexCount p: Int) -> Self
    public static func lollipop(cliqueVertexCount k: Int, pathVertexCount p: Int) -> Self
    public static func completeMultipartite(partSizes: [Int]) -> Self
    public static func turan(vertexCount n: Int, partCount r: Int) -> Self
    public static func balancedTree(branchingFactor r: Int, height h: Int) -> Self
}
extension Tree where Vertex == Int {
    public static func path(vertexCount n: Int) -> Tree      // n ≥ 1
    public static func star(vertexCount n: Int) -> Tree      // n ≥ 1
    public static func balancedTree(branchingFactor r: Int, height h: Int) -> Tree
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
| `ladder(rungCount:)` | rails `0..<n` and `n..<2n` (NetworkX) | i – i+1 on each rail, rungs i – i+n | both arcs | 2n, max(3n−2, 0) | NG-091 – NG-095 |
| `circularLadder(rungCount:)` | as the ladder, n ≥ 3 | the ladder, and each rail closed: 0 – n−1, n – 2n−1 | both arcs | 2n, 3n | NG-096 – NG-099 |
| `barbell(cliqueVertexCount:pathVertexCount:)` | cliques `0..<k` and `k+p..<2k+p`, path `k..<k+p` (NetworkX) | both cliques, and the path k−1 – k – … – k+p | both arcs | 2k+p, k(k−1)+p+1 | NG-100 – NG-105 |
| `lollipop(cliqueVertexCount:pathVertexCount:)` | clique `0..<k`, path `k..<k+p` (NetworkX) | the clique, and the path k−1 – k – … – k+p−1 | both arcs | k+p, k(k−1)/2+p | NG-106 – NG-111 |
| `completeMultipartite(partSizes:)` | parts as consecutive ranges, in order (NetworkX) | every pair in different parts | earlier part → later part (igraph's C `igraph_full_multipartite`, `IGRAPH_OUT`) | Σsᵢ, Σᵢ<ⱼ sᵢsⱼ | NG-112 – NG-118 |
| `turan(vertexCount:partCount:)` | r parts of ⌊n/r⌋ and ⌈n/r⌉, the smaller first (NetworkX) | as `completeMultipartite` | earlier part → later part | n, Σᵢ<ⱼ sᵢsⱼ | NG-119 – NG-125 |
| `balancedTree(branchingFactor:height:)` | breadth-first: root 0, children of p are r·p+1 … r·p+r (NetworkX, igraph `Tree`) | parent – child | parent → child (NetworkX's `create_using=nx.DiGraph`) | 1+r+…+r^h, n−1 | NG-126 – NG-135 |

**The directed form.** Families with a natural orientation (path, cycle, star, wheel, complete
bipartite, and from phase 1 complete multipartite, Turán and the balanced tree) get one arc per edge
along it. Families without one (complete, grid, hypercube, Petersen, and from phase 1 the ladders,
barbell and lollipop) get both arcs, which is `graph.directed` materialized. Complete
multipartite generalizes complete bipartite, so it keeps its left-to-right orientation, earlier part
to later part: `completeMultipartite(partSizes: [a, b])` is `completeBipartite(leftCount: a,
rightCount: b)` on every conformer, and n parts of size 1 give the transitive tournament, not
`complete`'s both arcs. NetworkX raises for a directed ladder, circular ladder, barbell or lollipop;
its `nx.DiGraph(G)` is the both-arcs form. This is NetworkX's `create_using=nx.DiGraph`
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
| Edge or vertex count overflows `Int` | NG-011, NG-068, NG-076 | the kind's own count: n(n − 1)/2 edges undirected, n(n − 1) arcs directed (likewise d·2^(d−1) or d·2^d for the hypercube, and twice the grid's edges). NG-011, n = 2^32, overflows only the directed count, so it runs on the directed conformers; the undirected K_{2^32} passes the check and would fail only to allocate. Checked by division before allocating, never with `multipliedReportingOverflow` and a discarded product (Swift 6.4 folded that flag to false under -O in `Flows`) |
| `cycle` with n < 3 | NG-034 – NG-037 | Cₙ is defined for n ≥ 3; C₁ and C₂ are not simple. NetworkX gives a self-loop for `cycle_graph(1)` and a single edge for `cycle_graph(2)`. One rule on every type, directed included (NG-037) |
| `wheel` with n < 4 | NG-050, NG-051 | the rim must be a cycle |
| `star` with n < 1 | NG-043 | no hub |
| `grid(dimensions: [])` | NG-066 | NetworkX gives the null graph; we trap, since the empty product is ambiguous |
| `Tree.path` / `Tree.star` with n < 1 | NG-028 | a `Tree` has at least one vertex |
| Negative rung count, path length, part size, branching factor or height | NG-095, NG-105, NG-111, NG-117, NG-133, NG-134 | NetworkX raises for each but the balanced tree's, where a negative height gives the null graph and a negative branching factor a single vertex |
| `circularLadder` with n < 3 | NG-099 | each rail must be a cycle, as for `cycle`. NetworkX accepts 2 and returns C₄, the ladder L₂ |
| `barbell` / `lollipop` with a clique of fewer than 2 | NG-104, NG-110 | as NetworkX |
| `turan` without 1 ≤ r ≤ n | NG-124, NG-125 | as NetworkX |
| Multipartite edge count or balanced-tree vertex count overflows `Int` | NG-118, NG-135 | checked by division before allocating |

Behaviours that are not traps: `complete(0)`, `path(0)`, `empty(0)` and `completeBipartite(0, 0)` are
the null graph; a dimension of 0 gives the null graph (NG-056); a periodic dimension of length 1 or
2 adds no wrap edge, so there is never a self-loop or a repeat (NG-060, NG-061: NetworkX's
`grid_graph` wraps a length-1 dimension into a self-loop); `hypercube(dimension: 0)` is K₁, as in
igraph (NetworkX's `hypercube_graph(0)` is the null graph, NG-069); `ladder(rungCount: 0)` and
`completeMultipartite(partSizes: [])` are the null graph; an empty part adds no vertex (NG-113);
`balancedTree` with r = 0 or h = 0 is the root alone, as in NetworkX (NG-129, NG-130).

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

Phase 1's families, measured (`just bench --target NamedGraphsBenchmarks`, p50):

| Graph | `CompressedSparseRow` | `UndirectedAdjacencyList<Int>` |
|---|---|---|
| `ladder(rungCount: 1_000_000)` (6·10⁶ arcs, 3·10⁶ edges) | 27 ms | 109 ms |
| `circularLadder(rungCount: 1_000_000)` | 27 ms | |
| `barbell(cliqueVertexCount: 1000, pathVertexCount: 100_000)` | 10 ms | 26 ms |
| `lollipop(cliqueVertexCount: 1000, pathVertexCount: 1_000_000)` | 13 ms | |
| `turan(vertexCount: 2000, partCount: 4)` (1.5·10⁶ edges) | 1.4 ms | 33 ms |
| `completeMultipartite(partSizes:)`, 200 parts of 10 | 2.0 ms | |
| `balancedTree(branchingFactor: 2, height: 19)` (2²⁰ − 1 vertices) | 2.7 ms | 30 ms (`Tree`: 25 ms) |

The both-arcs families go through one counting placement of the arcs (`_bothArcs`, no sort), so
their CSR cost is about 4.5 ns per arc against the path's 3. Complete multipartite and Turán compute
their edges as read (`_MultipartitePairs`) and allocate no edge list.

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
| `ladder(rungCount:)` | NetworkX's n is the number of rungs ("two paths of n nodes") | `ladder_graph` | | | `LadderGraph` |
| `circularLadder(rungCount:)` | | `circular_ladder_graph` | | | |
| `barbell(cliqueVertexCount:pathVertexCount:)` | NetworkX's m1, m2: the clique and the path, counted in vertices like `vertexCount` | `barbell_graph` | | | |
| `lollipop(cliqueVertexCount:pathVertexCount:)` | NetworkX's m, n, labelled as the barbell's | `lollipop_graph` | | | |
| `completeMultipartite(partSizes:)` | "parts", the graph-theory word; NetworkX's `subset_sizes` | `complete_multipartite_graph` | `igraph_full_multipartite` (C) | | `CompleteGraph[{n1, …}]` |
| `turan(vertexCount:partCount:)` | NetworkX's n, r | `turan_graph` | `igraph_turan` (C) | | `TuranGraph` |
| `balancedTree(branchingFactor:height:)` | NetworkX's name and its words for r and h; on `Tree` too, as `path` and `star` are | `balanced_tree` | `Tree(n, children)` | | `CompleteKaryTree` |

No `Graph` suffix: the type already says it. No `lattice` spelling beside `grid`, and no 2-D
`grid(rowCount:columnCount:)` beside `grid(dimensions:)`.

## Open questions, decided as recommended

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
5. **More `Tree` and `BipartiteGraph` shapes.** Phase 1 added NetworkX's `balanced_tree` under its own
   name, `balancedTree(branchingFactor:height:)`, on `Tree` and on every conformer (the
   `Tree.complete(arity:height:)` once proposed here is not a name any library uses for it). Bipartite
   paths and grids stay deferred.
6. **Generalized Petersen GP(n, k)** (JGraphT, Mathematica's `PetersenGraph[n, k]`). *Recommended:
   defer* to phase 2, below. If added, it is `petersen(vertexCount:step:)` beside `petersen()`, with
   `petersen()` being GP(5, 2) under NetworkX's numbering, which is already GP(5, 2)'s standard
   numbering.

## Not included: datasets

Empirical graphs such as Zachary's karate club (NetworkX `karate_club_graph`, igraph
`Famous("Zachary")`) are data, not mathematical families, so they are not part of the API. A test that
wants one keeps its edge list inline as a fixture. Fixed mathematical graphs such as `petersen()` stay.

## Phase 2

Recorded from the review of phase 1, not yet built:

- the platonic solids: NetworkX's `tetrahedral_graph`, `octahedral_graph`, `cubical_graph`,
  `dodecahedral_graph` and `icosahedral_graph` (the tetrahedron is K₄ and the cube Q₃ under other
  numberings);
- the generalized Petersen graph GP(n, k), open question 6;
- circulant graphs (NetworkX `circulant_graph(n, offsets)`, igraph `Circulant`);
- per-dimension periodic grids (NetworkX's `grid_graph(dim, periodic=[…])`): `periodic` as one flag
  per dimension beside today's single `Bool`.

`RandomGraphs`' phase-2 items (`powerlawCluster`, the configuration model's multigraph hook, and
xoshiro's `jump`/`longJump`) are recorded in its own `api.md`.
