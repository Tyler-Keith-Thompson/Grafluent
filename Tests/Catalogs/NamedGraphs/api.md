# NamedGraphs: API

The named families are static factories on the representation types, for example
`CompressedSparseRow.complete(vertexCount: 5)`. This file fixes where those factories live, the
vertex numbering of every family, the directed forms, the edge order, the traps and the complexity.

`cases.md` (NG-001 – NG-236, 236 rows) pins the values. `ref.py` builds every family from its
definition and checks each row against NetworkX 3.7 (exact edge set under the numbering below),
igraph 1.0 (exact where igraph numbers the same way, isomorphism for Petersen) and the count and
degree laws. For grids it checks the mapping to NetworkX's `grid_2d_graph(r, c)` (node `(i, j)` is
`i·c + j`), to `grid_graph(dim)` (node `(x_{k−1}, …, x₀)`) and to igraph's
`Lattice(dims.reversed())`. `--stress` sweeps every family over a range of sizes, both kinds (1457
combinations).

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
| `CompressedSparseRow` | directed | O(n + m), one pass that fills `offsets` and `targets` with no counting sort. Two exact-size allocations |
| `AdjacencyMatrix` | directed | O(n²/64 + m): zeroed bit rows, one bit per edge |
| `AdjacencyList<Int>` | directed | O(n + m) expected: n slot-dictionary inserts and one slot-pair entry per edge, rows reserved at their exact size |
| `DirectedPseudograph<Int>`, `DirectedMultigraph<Int>` | directed | as `AdjacencyList` (same storage); the multigraph skips its self-loop check, since there are none |
| `StableDirectedGraph<Int>` | directed | O(n + m) expected, pages filled in order |
| `UndirectedAdjacencyList<Int>`, `Pseudograph<Int>`, `Multigraph<Int>` | undirected | O(n + m) expected, as `AdjacencyList` |

Shapes that are a structure get their own statics, built through the structure's dense
initializers and never re-validated:

| Type | Factories |
|---|---|
| `Tree<Int>` | `path(vertexCount:)`, `star(vertexCount:)`, `balancedTree(branchingFactor:height:)`: O(n) through the dense `_TreeLayout`, with no vertex dictionary |
| `BipartiteGraph<Int>` | `completeBipartite(leftCount:rightCount:)`: sides known, no 2-colouring pass |

`LabeledGraph` and `EdgeList` do not conform. A labeled graph's labels are not `Int`s (label a
generated graph instead, as in `LabeledGraph(CompressedSparseRow.grid(dimensions: [3, 4]), labels: …)`),
and an `EdgeList` cannot hold isolated vertices.

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
    public static func ladder(rungCount n: Int) -> Self
    public static func circularLadder(rungCount n: Int) -> Self
    public static func barbell(cliqueVertexCount k: Int, pathVertexCount p: Int) -> Self
    public static func lollipop(cliqueVertexCount k: Int, pathVertexCount p: Int) -> Self
    public static func completeMultipartite(partSizes: [Int]) -> Self
    public static func turan(vertexCount n: Int, partCount r: Int) -> Self
    public static func balancedTree(branchingFactor r: Int, height h: Int) -> Self
    public static func circulant(vertexCount n: Int, offsets: [Int]) -> Self
    public static func generalizedPetersen(outerCycleLength n: Int, step k: Int) -> Self
    public static func kneser(setSize n: Int, subsetSize k: Int) -> Self
    public static func windmill(cliqueCount c: Int, cliqueVertexCount k: Int) -> Self
    public static func binomialTree(order k: Int) -> Self
    public static func fullRaryTree(branchingFactor r: Int, vertexCount n: Int) -> Self
    public static func triangularLattice(rowCount m: Int, columnCount n: Int) -> Self
    public static func hexagonalLattice(rowCount m: Int, columnCount n: Int) -> Self
    public static func lcf(vertexCount n: Int, shifts: [Int], repeatCount r: Int) -> Self
    public static func heawood() -> Self                      // and moebiusKantor(), pappus(), desargues(),
    public static func icosahedral() -> Self                  // dodecahedral(), frucht(), tutte(), chvatal(),
                                                              // hoffmanSingleton()
}
extension _DirectedGraphConstruction {
    public static func kautz(alphabetSize s: Int, wordLength L: Int) -> Self   // directed only
}
extension AdjacencyList where Vertex == Int {                 // and DirectedPseudograph: self-loops
    public static func deBruijn(alphabetSize m: Int, wordLength n: Int) -> AdjacencyList
}
extension Tree where Vertex == Int {
    public static func path(vertexCount n: Int) -> Tree      // n ≥ 1
    public static func star(vertexCount n: Int) -> Tree      // n ≥ 1
    public static func balancedTree(branchingFactor r: Int, height h: Int) -> Tree
    public static func binomialTree(order k: Int) -> Tree
    public static func fullRaryTree(branchingFactor r: Int, vertexCount n: Int) -> Tree   // n ≥ 1
}
extension BipartiteGraph where Vertex == Int {
    public static func completeBipartite(leftCount a: Int, rightCount b: Int) -> BipartiteGraph
}
```

### Families

| Factory | Vertices | Undirected edges | Directed form | n, m (undirected) | Rows |
|---|---|---|---|---|---|
| `complete(vertexCount:)` | `0..<n` | every pair | both arcs | n, n(n−1)/2 | NG-001 – NG-011 |
| `completeBipartite(leftCount:rightCount:)` | left `0..<a`, right `a..<a+b` | every left–right pair | both arcs | a+b, ab | NG-012 – NG-020 |
| `path(vertexCount:)` | `0..<n` | i – i+1 | i → i+1 | n, max(n−1, 0) | NG-021 – NG-029 |
| `cycle(vertexCount:)` | `0..<n`, n ≥ 3 | i – (i+1) mod n | i → (i+1) mod n | n, n | NG-030 – NG-037 |
| `star(vertexCount:)` | hub 0, leaves `1..<n`, n ≥ 1 | 0 – i | hub → leaf | n, n−1 | NG-038 – NG-044 |
| `wheel(vertexCount:)` | hub 0, rim `1..<n`, n ≥ 4 | 0 – i, rim cycle 1 – 2 – … – (n−1) – 1 | hub → rim, rim i → i+1 and n−1 → 1 | n, 2(n−1) | NG-045 – NG-051 |
| `grid(dimensions:periodic:)` | row-major: x = (x₀, …, x_{k−1}) is Σ xᵢ·Πⱼ₍ⱼ>ᵢ₎ dⱼ, the last dimension fastest | x – x+eᵢ; with `periodic`, also the wrap edge in each dimension of length ≥ 3 | both arcs | Πdᵢ, Σᵢ (dᵢ−1 or dᵢ when it wraps)·Πⱼ≠ᵢ dⱼ | NG-052 – NG-068 |
| `hypercube(dimension:)` | `0..<2^d`, bit k is coordinate k | u – u ^ (1 << k) | both arcs | 2^d, d·2^(d−1) | NG-069 – NG-076 |
| `petersen()` | outer 0–1–2–3–4, spokes i – i+5, inner 5–7–9–6–8 | 15 edges | both arcs | 10, 15 | NG-077, NG-078 |
| `empty(vertexCount:)` | `0..<n` | none | none | n, 0 | NG-079 – NG-083 |
| `ladder(rungCount:)` | rails `0..<n` and `n..<2n` | i – i+1 on each rail, rungs i – i+n | both arcs | 2n, max(3n−2, 0) | NG-091 – NG-095 |
| `circularLadder(rungCount:)` | as the ladder, n ≥ 3 | the ladder, and each rail closed: 0 – n−1, n – 2n−1 | both arcs | 2n, 3n | NG-096 – NG-099 |
| `barbell(cliqueVertexCount:pathVertexCount:)` | cliques `0..<k` and `k+p..<2k+p`, path `k..<k+p` | both cliques, and the path k−1 – k – … – k+p | both arcs | 2k+p, k(k−1)+p+1 | NG-100 – NG-105 |
| `lollipop(cliqueVertexCount:pathVertexCount:)` | clique `0..<k`, path `k..<k+p` | the clique, and the path k−1 – k – … – k+p−1 | both arcs | k+p, k(k−1)/2+p | NG-106 – NG-111 |
| `completeMultipartite(partSizes:)` | parts as consecutive ranges, in order | every pair in different parts | both arcs | Σsᵢ, Σᵢ<ⱼ sᵢsⱼ | NG-112 – NG-118 |
| `turan(vertexCount:partCount:)` | r parts of ⌊n/r⌋ and ⌈n/r⌉, the smaller first | as `completeMultipartite` | both arcs | n, Σᵢ<ⱼ sᵢsⱼ | NG-119 – NG-125 |
| `balancedTree(branchingFactor:height:)` | breadth-first: root 0, children of p are r·p+1 … r·p+r | parent – child | parent → child | 1+r+…+r^h, n−1 | NG-126 – NG-135 |
| `circulant(vertexCount:offsets:)` | `0..<n`, n ≥ 1 | i – (i ± o) mod n for each offset, each edge once | both arcs | n, n·#{o mod n folded to 1…n/2} (n/2 counts once) | NG-136 – NG-144 |
| `generalizedPetersen(outerCycleLength:step:)` | outer cycle `0..<n`, inner `n..<2n`, 1 ≤ k < n/2 | i – i+1 mod n, spokes i – n+i, inner n+i – n+(i+k) mod n | both arcs | 2n, 3n | NG-145 – NG-152 |
| `kneser(setSize:subsetSize:)` | the k-subsets of `0..<n` in lexicographic order | disjoint subsets | both arcs | C(n, k), C(n, k)·C(n−k, k)/2 | NG-153 – NG-160, NG-236 |
| `windmill(cliqueCount:cliqueVertexCount:)` | hub 0, clique j on 1+j(k−1) ..< 1+(j+1)(k−1) | c copies of K_k sharing 0; k = 3 is the friendship graph | both arcs | 1+c(k−1), c·k(k−1)/2 | NG-161 – NG-167 |
| `binomialTree(order:)` | `0..<2^k` | v & (v − 1) – v | parent → child | 2^k, 2^k − 1 | NG-168 – NG-175 |
| `fullRaryTree(branchingFactor:vertexCount:)` | breadth-first, as `balancedTree`, the last level filled from the left | (c−1)/r – c | parent → child | n, max(n−1, 0) | NG-176 – NG-185 |
| `deBruijn(alphabetSize:wordLength:)` (`AdjacencyList`, `DirectedPseudograph`) | words of n letters as base-m numbers | — | u → (u·m mod mⁿ) + a, the constant words' self-loops included | mⁿ, mⁿ⁺¹ arcs | NG-186 – NG-192 |
| `kautz(alphabetSize:wordLength:)` | words with no two equal neighbors, lexicographic | — | each word to its shifts by a letter ≠ its last | s(s−1)^(L−1), times s−1 arcs | NG-193 – NG-198 |
| `triangularLattice(rowCount:columnCount:)` | m+1 rows of ⌈n/2⌉+1 nodes, row by row (odd rows one shorter for odd n) | row, column and one diagonal per square | both arcs | as NetworkX's `triangular_lattice_graph`, V + mn − 1 edges | NG-199 – NG-206 |
| `hexagonalLattice(rowCount:columnCount:)` | n+1 columns of 2m+2 nodes, column by column, two corners left out | as NetworkX's `hexagonal_lattice_graph` | both arcs | (n+1)(2m+2)−2, V + mn − 1 | NG-207 – NG-214 |
| `lcf(vertexCount:shifts:repeatCount:)` | `0..<n`, n ≥ 3 | the n-cycle and the chords (i mod n) – (i + s_{i mod k}) mod n, i < k·r | both arcs | n, n + distinct chords | NG-215 – NG-223 |
| `heawood()`, `moebiusKantor()`, `pappus()`, `desargues()`, `dodecahedral()`, `frucht()` | their LCF notation | NetworkX's graphs, Frucht up to isomorphism | both arcs | 14, 16, 18, 20, 20, 12 vertices, cubic | NG-224 – NG-230 |
| `icosahedral()`, `tutte()`, `chvatal()`, `hoffmanSingleton()` | their constructions (apices and pentagons; three Tutte fragments; NetworkX's numbering; Robertson's pentagons and pentagrams) | isomorphic to NetworkX's | both arcs | 12/30, 46/69, 12/24, 50/175 | NG-231 – NG-235 |

**The directed form.** Families with a natural orientation (path, cycle, star, wheel, balanced,
binomial and full r-ary tree) get one arc per edge along it. The others (complete, complete bipartite, complete
multipartite, Turán, grid, hypercube, Petersen, the ladders, barbell and lollipop) get both arcs,
which is `graph.directedView` materialized. With both arcs, `completeMultipartite(partSizes: [a, b])`
equals `completeBipartite(leftCount: a, rightCount: b)` on every conformer, and n parts of size 1
equal `complete(vertexCount: n)`.

**Edge order is part of the contract.** Undirected edges are `UndirectedEdge(u, v)` with `u < v`, in
lexicographic order; directed edges are in row-major order. `edges` reads the same on every
conformer (NG-084 – NG-090), CSR builds in one pass, and an adjacency list's positions are
predictable. Cycle's closing edge is `UndirectedEdge(0, n − 1)`, second in the list (NG-031).

### Traps

| Trap | Rows | Note |
|---|---|---|
| Negative count, side or dimension | NG-010, NG-020, NG-029, NG-067, NG-075, NG-083 | |
| Edge or vertex count overflows `Int` | NG-011, NG-068, NG-076 | the kind's own count: n(n − 1)/2 edges undirected, n(n − 1) arcs directed (likewise d·2^(d−1) or d·2^d for the hypercube, and twice the grid's edges). NG-011, n = 2^32, overflows only the directed count, so it runs on the directed conformers; the undirected K_{2^32} passes the check and would fail only to allocate. Checked by division before allocating |
| `cycle` with n < 3 | NG-034 – NG-037 | Cₙ is defined for n ≥ 3; C₁ and C₂ are not simple. Directed included (NG-037) |
| `wheel` with n < 4 | NG-050, NG-051 | the rim must be a cycle |
| `star` with n < 1 | NG-043 | no hub |
| `grid(dimensions: [])` | NG-066 | the empty product is ambiguous |
| `Tree.path` / `Tree.star` with n < 1 | NG-028 | a `Tree` has at least one vertex |
| Negative rung count, path length, part size, branching factor or height | NG-095, NG-105, NG-111, NG-117, NG-133, NG-134 | |
| `circularLadder` with n < 3 | NG-099 | each rail must be a cycle, as for `cycle` |
| `barbell` / `lollipop` with a clique of fewer than 2 | NG-104, NG-110 | |
| `turan` without 1 ≤ r ≤ n | NG-124, NG-125 | |
| Multipartite edge count or balanced-tree vertex count overflows `Int` | NG-118, NG-135 | checked by division before allocating |
| An offset or shift that is a multiple of n (a self-loop); a circulant on 0 vertices; an LCF cycle shorter than 3 or a negative repeat count | NG-143, NG-144, NG-221 – NG-223 | |
| `generalizedPetersen` without n ≥ 3 and 1 ≤ k < n/2 | NG-150 – NG-152 | k = n/2 would repeat the inner edges |
| `kneser` without 1 ≤ k ≤ n, or with C(n, k) past `Int` | NG-159, NG-160, NG-236 | the binomial table saturates, so only the needed coefficients must fit |
| `windmill` with fewer than 2 cliques or cliques of fewer than 2 | NG-166, NG-167 | |
| `binomialTree` order outside 0…62; `fullRaryTree` with r < 1 or n < 0 (`Tree`: n < 1) | NG-174, NG-175, NG-183 – NG-185 | |
| `deBruijn` with m < 1 or n < 1; `kautz` with s < 2 or L < 1 | NG-191, NG-192, NG-197, NG-198 | |
| Negative lattice counts | NG-206, NG-214 | |

Behaviours that are not traps: `complete(0)`, `path(0)`, `empty(0)` and `completeBipartite(0, 0)` are
the null graph; a dimension of 0 gives the null graph (NG-056); a periodic dimension of length 1 or
2 adds no wrap edge, so there is never a self-loop or a repeat (NG-060, NG-061);
`hypercube(dimension: 0)` is K₁ (NG-069); `ladder(rungCount: 0)` and
`completeMultipartite(partSizes: [])` are the null graph; an empty part adds no vertex (NG-113);
`balancedTree` with r = 0 or h = 0 is the root alone (NG-129, NG-130); `star(vertexCount:)` counts
the hub (NG-044); a lattice with no rows or columns is the null graph (NG-204, NG-212); `kneser` with
n < 2k has no edges (NG-155); `fullRaryTree(branchingFactor: r, vertexCount: 0)` is the null graph
(NG-176). The tetrahedron, cube and octahedron are `complete(vertexCount: 4)`,
`hypercube(dimension: 3)` and `turan(vertexCount: 6, partCount: 3)`, so they have no factory of their
own.

### Complexity

Every factory is O(n + m) time and builds no intermediate hash table, except `kneser`
(O(m·k), each neighbor's rank from prefix sums of binomial coefficients) and `deBruijn`, which
builds through the representations' `_built` (rows by counting sort, one pair-table entry per arc). The Θ(n²) families
(`complete`, `completeBipartite`, `completeMultipartite`, `turan`) pass a lazy collection that
computes its edges, so no edge array is allocated (`_AscendingPairs`, `_DistinctPairs`,
`_CrossPairs`, `_MultipartitePairs`, and `_CrossPartArcs` for both arcs). The others pass an
exact-capacity array of m edges, freed after the build. The both-arcs families place their arcs
with one counting pass (`_bothArcs`), not a sort. The body of each family is non-generic except
for the final bulk initializer, so a family adds one small specialization per conformer used.

Benchmarks are in `Benchmarks/Benchmarks/NamedGraphsBenchmarks`.

## Vertex numbering

Vertices are `Int`s `0..<n` everywhere, with each family's numbering fixed above (grid row-major,
hypercube by bits). A caller who wants coordinates computes them from the index or labels the graph
with `LabeledGraph`. Datasets such as Zachary's karate club are not part of the API; a test that
wants one keeps its edge list inline.
