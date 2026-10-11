# RandomGraphs: proposed API

Random families as static factories on the representation types, through the same two underscored
protocols as `NamedGraphs` (`_DirectedGraphConstruction`, `_GraphConstruction`; see
`../NamedGraphs/api.md`), plus statics on `Tree` and `DirectedAcyclicGraph`. Every factory takes
`inout some RandomNumberGenerator`, and the module ships a public seedable generator.
`RandomGraphs` depends on `GraphProtocols`, `NamedGraphs` (the complete-graph shortcuts at p = 1 and
k = n, and the lazy pair collections), `Trees` and `DirectedAcyclicGraphModule`.
`Xoshiro256StarStar` lives here: `NamedGraphs` draws nothing.

`cases.md` (RG-001 – RG-108, 108 rows) pins the values: 8 generator rows (one a trap), 59 exact
outputs for fixed seeds (55 of them reproduced by NetworkX), 23 traps, 16 statistical laws and 2
further edge cases. `ref.py` ports the generator and
every procedure draw for draw. Because the procedures draw exactly what CPython's `random.Random`
draws, NetworkX 3.7 can run its own generators on our stream, and every exact row marked
`= NetworkX` is checked edge for edge against it. `--stress` repeats that over 15 300 graphs.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/RandomGraphs/ref.py [--write] [--stress]`.

## The generator

```swift
/// xoshiro256** 1.0 (Blackman and Vigna, "Scrambled linear pseudorandom number generators",
/// ACM TOMS 47(4), 2021): 256 bits of state, period 2^256 − 1.
@frozen
public struct Xoshiro256StarStar: RandomNumberGenerator, Equatable, Hashable, Sendable {
    /// The state filled by four SplitMix64 outputs from `seed` (Steele, Lea and Flood, OOPSLA 2014),
    /// as Vigna recommends and rand_xoshiro's `seed_from_u64` does.
    public init(seed: UInt64)
    /// The state words as given. Precondition: not all zero (RG-002).
    public init(state: (UInt64, UInt64, UInt64, UInt64))
    public mutating func next() -> UInt64
}
```

- **Checked against published vectors** in `ref.py`: state (1, 2, 3, 4) gives rand_xoshiro's test
  sequence (RG-001), and SplitMix64 from 1234567 gives the splitmix64.c harness values.
- **A value type**, so a copy replays the stream (RG-007). `Equatable` lets a test check how many draws a
  factory made: the generator after the call equals a fresh one advanced `draws` times.
- **Why xoshiro256\*\***: it is the general-purpose generator its authors recommend, Rust's
  `rand_xoshiro` and .NET's `System.Random` use it, and it costs a few cycles per draw.
  `GrafluentTestSupport`'s `SeededRandomNumberGenerator` is xoroshiro128+, whose low bits are weak,
  and the benchmarks' `LCG`s are 64-bit LCGs. All of them can move to this type in the final reuse
  pass (`project-final-reuse-pass`).
- Every factory also has an overload without `using:` that draws from `SystemRandomNumberGenerator`,
  as `shuffled()` sits beside `shuffled(using:)`.

## The pinned stream

Every procedure draws only through two internal functions, so its output is a function of the
generator's `next()` sequence:

```swift
/// A double in [0, 1): the top 53 bits. CPython's random() reads its bits the same way.
func uniform01(_ g: inout some RandomNumberGenerator) -> Double {
    Double(g.next() >> 11) * 0x1p-53
}
/// An Int in 0..<n by rejection on the top bitWidth(n) bits: CPython's
/// _randbelow_with_getrandbits, with getrandbits(k) = next() >> (64 − k). Note k is the bit
/// length of n, not of n − 1, so below(1) still draws.
func below(_ n: Int, _ g: inout some RandomNumberGenerator) -> Int {
    let k = Int.bitWidth - n.leadingZeroBitCount
    while true { let r = Int(g.next() >> UInt64(64 - k)); if r < n { return r } }
}
```

- **Never** `Int.random(in:using:)` or `Double.random(in:using:)` inside a factory: the standard
  library does not promise their algorithms, and today they read other bits with other rejection
  rules. If the standard library changed them, outputs would change with no diff in this repository.
- **Matching NetworkX.** `uniform01` is what CPython's `random()` returns and `below(n)` is
  `choice(seq)`'s index when CPython's generator produces our bits. Each procedure below is
  NetworkX's procedure, draw for draw, except where noted. So NetworkX on the same stream
  is a reference for every exact row (`StreamRandom` in `ref.py`).
- **`log` is the one platform dependency.** G(n, p), the SBM and the DAG skip with `log`, which is
  libm's. A skip is `Int(log(1 − u) / log(1 − p))`, so a last-ulp difference between Darwin's and
  glibc's `log` could move one edge when the quotient lands within an ulp of an integer. The exact
  rows are checked on Darwin by `ref.py` (Python's `math.log` is the same libm); Linux CI runs the
  same rows and would show it. Barabási–Albert, Watts–Strogatz, G(n, m), random geometric graphs and
  random trees use no transcendental function and are exact everywhere.

## API

```swift
extension _GraphConstruction {
    public static func erdosRenyi(vertexCount n: Int, edgeProbability p: Double,
                                  using g: inout some RandomNumberGenerator) -> Self
    public static func erdosRenyi(vertexCount n: Int, edgeCount m: Int,
                                  using g: inout some RandomNumberGenerator) -> Self
    public static func barabasiAlbert(vertexCount n: Int, edgesPerVertex m: Int,
                                      using g: inout some RandomNumberGenerator) -> Self
    public static func wattsStrogatz(vertexCount n: Int, nearestNeighborCount k: Int,
                                     rewiringProbability p: Double,
                                     using g: inout some RandomNumberGenerator) -> Self
    public static func randomGeometric(vertexCount n: Int, radius r: Double, dimension: Int = 2,
                                       using g: inout some RandomNumberGenerator)
        -> (graph: Self, positions: [Double])      // positions[v * dimension + i]
    public static func stochasticBlockModel(blockSizes: [Int], edgeProbabilities: [[Double]],
                                            using g: inout some RandomNumberGenerator) -> Self
}
extension _DirectedGraphConstruction {
    // erdosRenyi(vertexCount:edgeProbability:using:), erdosRenyi(vertexCount:edgeCount:using:),
    // barabasiAlbert(vertexCount:edgesPerVertex:using:), stochasticBlockModel(blockSizes:edgeProbabilities:using:)
}
extension Tree where Vertex == Int {
    public static func random(vertexCount n: Int, using g: inout some RandomNumberGenerator) -> Tree
}
extension DirectedAcyclicGraph where Base: _DirectedGraphConstruction {   // Base is already a MutableDirectedGraph
    public static func erdosRenyi(vertexCount:edgeProbability:using:) -> Self
    public static func erdosRenyi(vertexCount:edgeCount:using:) -> Self
}
// …and each again without `using:`.
```

**Output order.** Every factory but `Tree.random` emits its edges sorted, as `NamedGraphs` does:
undirected `UndirectedEdge(u, v)` with `u < v` lexicographically, directed in row-major order. The
procedures produce edge sets, and a counting sort by the smaller endpoint (O(n + m), stable) puts them
in order. CSR then takes its one-pass path, so its total cost matches what its own two counting sorts
would cost, and on the adjacency lists the positions do not depend on the draw order. `Tree.random`
keeps `Tree(pruferSequence:)`'s edge order (RG-095 – RG-100).

### Procedures (pinned)

| Factory | Procedure | NetworkX equivalent on the same stream | Time | Rows |
|---|---|---|---|---|
| `erdosRenyi(vertexCount:edgeProbability:)` | p ≤ 0: empty; p ≥ 1: complete; no draws. Otherwise Batagelj–Brandes geometric skipping (Phys. Rev. E 71, 036113, 2005, algorithm G(n,p)): `lp = log(1 − p)`; v = 1, w = −1; while v < n: `w += 1 + Int(log(1 − uniform01()) / lp)`; while w ≥ v and v < n: w −= v, v += 1; if v < n: edge v–w. Directed: a first sweep emits w → v, then a second sweep v → w | `fast_gnp_random_graph(n, p, directed=)`, exactly | O(n + m) expected; one `log` per edge plus one | RG-009 – RG-029 |
| `erdosRenyi(vertexCount:edgeCount:)` | k = m when 2m ≤ N, else N − m (N = number of pairs). Repeat: u = below(n), v = below(n); skip u == v or a pair already chosen (undirected: either orientation); keep, until k pairs. If k = N − m, output every other pair | `gnm_random_graph(n, m, directed=)` when 2m ≤ N | O(n + m) expected for 2m ≤ N, O(n²) for the complement branch (whose output is Θ(n²) anyway); membership in a hash set of pair codes, or a bitset when n² / 8 bytes is at most ~8 bytes per edge | RG-030 – RG-046 |
| `barabasiAlbert(vertexCount:edgesPerVertex:)` | Star on 0…m (hub 0). `repeated = [0] × m + [1, …, m]`. For each new vertex s in m+1..<n: draw `repeated[below(repeated.count)]` until m distinct targets; edges s–t; append the targets **in ascending order**, then s m times | `barabasi_albert_graph(n, m)` for m = 1, and whenever CPython's set iteration is ascending (NetworkX appends in set order; ours is pinned to ascending so it does not depend on CPython's hash table) | O(n·m) expected (repeated-nodes list; Batagelj–Brandes 2005, algorithm BA) | RG-047 – RG-059 |
| `wattsStrogatz(vertexCount:nearestNeighborCount:rewiringProbability:)` | k = n: complete, no draws. Ring: u – (u+j) mod n for j in 1…k/2. For j in 1…k/2, for u in 0..<n: if uniform01() < p: w = below(n); while w == u or u–w exists { w = below(n); if degree(u) ≥ n − 1 { skip this rewiring } }; otherwise replace u–(u+j) by u–w | `watts_strogatz_graph(n, k, p)`, exactly | O(n·k) expected; membership in per-vertex sorted rows or a hash set | RG-060 – RG-073 |
| `randomGeometric(vertexCount:radius:dimension:)` | positions vertex by vertex, coordinate by coordinate, each `uniform01()`. u–v when Σᵢ (aᵢ − bᵢ)·(aᵢ − bᵢ), summed in coordinate order, ≤ r·r. Found with a cell grid of side ≥ r (Bentley, Stanat and Williams, IPL 6(6), 1977), checking the 3^d neighbouring cells; the cell count is capped at n so memory stays O(n) for tiny r | `random_geometric_graph(n, r, dim=)` without scipy, exactly, positions included | O(n + m) expected for uniform points, plus 3^d per cell | RG-074 – RG-083 |
| `stochasticBlockModel(blockSizes:edgeProbabilities:)` | Blocks are consecutive vertex ranges. Block pairs (i, j): undirected i ≤ j in `combinations_with_replacement` order, directed every (i, j) row-major. Pairs within a pair-block: undirected `combinations` of block i, directed `permutations`, between blocks the `product`, all in ascending order. p = 1: every pair, no draws; 0 < p < 1: repeat `u = uniform01()` (u = 0 ends the block pair), `skip = floor(log(u) / log(1 − p))`, pass `skip` pairs and keep the next; stop past the end | `stochastic_block_model(sizes, p, directed=)` (its default `sparse=True`) when CPython's set of each block iterates in ascending order | O(n + m + B²) expected, by indexing the pair-block arithmetically. NetworkX passes skipped pairs one by one through `islice`, so its "sparse" mode is O(pairs): 26.8 s for 100 000 vertices | RG-084 – RG-094 |
| `Tree.random(vertexCount:)` | n = 1: one vertex, no draws. Otherwise a Prüfer code of n − 2 draws `below(n)`, decoded by `Tree(pruferSequence:)` (O(n), already in `Trees`) | `random_labeled_tree(n)`, exactly | O(n) | RG-095 – RG-103 |
| `DirectedAcyclicGraph.erdosRenyi(…)` | the undirected procedure, each edge u–v (u < v) oriented u → v: the Barak–Erdős model (SIAM J. Algebraic Discrete Methods 5(4), 1984). The sorted pairs build the base in bulk, and `package DirectedAcyclicGraph(_vertexOrderedBase:)` (in `DirectedAcyclicGraphModule`) takes its `vertices` order, 0..<n, as the topological order: O(n), no hashing, no Kahn pass and no per-edge insertion. Bases: the three `MutableDirectedGraph`s, `AdjacencyList<Int>`, `StableDirectedGraph<Int>` and `DirectedPseudograph<Int>`, which all conform to `_DirectedGraphConstruction` | `fast_gnp_random_graph(n, p)` / `gnm_random_graph(n, m)` oriented upward (NetworkX's documented recipe for a random DAG) | as the undirected forms | RG-104 – RG-108 |

The skip in G(n, p) is compared, as a `Double`, against n² before it becomes an `Int` (RG-021): a
skip of n² or more passes every pair left in the sweep (there are fewer than n²/2), so the sweep ends
there, after the draw that produced it. `ref.py` does the same (`if not skip < n * n: return`). The
quotient can reach about 3·10¹⁷, which fits a 64-bit `Int` but not a 32-bit one, and the comparison
costs nothing. For `1 − p == 1` (p below about 1.1·10⁻¹⁶), `log(1 − p)` is 0 and the result is empty
with no draws (RG-020). NetworkX divides by zero there.

### Directed variants

| Family | Directed form | Source |
|---|---|---|
| G(n, p), G(n, m) | ordered pairs u ≠ v | NetworkX `directed=True`, igraph `Erdos_Renyi(directed=True)` |
| Barabási–Albert | the same draws, each edge new vertex → older vertex (RG-054) | igraph `Barabasi(directed=True)` |
| Stochastic block model | ordered pairs, `edgeProbabilities` need not be symmetric (RG-087) | NetworkX `directed=True`, igraph `SBM(directed=True)` |
| Random DAG | upward orientation of the undirected form | Barak–Erdős |
| Watts–Strogatz, random geometric | **none**: neither library has one, and the relation is symmetric. On a directed conformer, use `CompressedSparseRow(UndirectedAdjacencyList<Int>.wattsStrogatz(…).directed)` | |

### Traps

| Trap | Rows |
|---|---|
| Negative `vertexCount` | RG-022 |
| A probability outside 0…1, or NaN | RG-023 – RG-025, RG-071, RG-091 |
| `edgeCount` outside 0…N (NetworkX silently returns the complete graph; igraph and JGraphT reject it) | RG-040 – RG-043, RG-107 |
| `edgesPerVertex` outside 1..<n | RG-055 – RG-057 |
| Odd `nearestNeighborCount` (NetworkX floors it without saying so), or greater than n | RG-069, RG-070 |
| Negative or NaN `radius`, `dimension` < 1 | RG-080 – RG-082 |
| SBM: matrix not square, not symmetric for an undirected conformer (exact equality, where NetworkX allows 1e-8), a negative block size | RG-089 – RG-092 |
| `Tree.random(vertexCount: 0)` | RG-101 |
| `Xoshiro256StarStar(state: (0, 0, 0, 0))` | RG-002 |

### Laws every implementation must satisfy (statistical rows)

The statistical rows give the exact aggregate of the pinned procedure over seeds `0..<S`, which the
Swift suite asserts exactly, and the law it satisfies, which `ref.py` asserts:

- G(n, p): E[m] = p·C(n, 2) and p·n(n − 1) (|z| ≤ 4); pooled degree variance (n − 1)p(1 − p) within 5 %;
  each labeled graph on 3 vertices at its probability (χ², 0.999 quantile).
- G(n, m): exactly m edges; uniform over the C(N, m) graphs, in both branches and directed (χ²).
- Barabási–Albert: m(n − m) edges and degree sum 2m(n − m) every time; every new vertex has degree
  ≥ m; the share of degree-m vertices tends to 2/(m + 2) (Bollobás, Riordan, Spencer and Tusnády,
  Random Structures & Algorithms 18(3), 2001).
- Watts–Strogatz: nk/2 edges for every p; every vertex keeps degree ≥ k/2; the share of ring edges gone
  ≈ p.
- Random geometric: E[m] = C(n, 2)(πr² − 8r³/3 + r⁴/2) in the unit square, for r ≤ 1.
- SBM: E[m] = Σ pairs(i, j)·p(i, j).
- Random trees: n − 1 edges, connected, degree(v) = 1 + occurrences of v in the code; uniform over the
  4² labeled trees on 4 vertices (Cayley).
- Random DAG: acyclic with `topologicalOrder == 0..<n`; E[m] = p·C(n, 2).

## Performance targets

Reference timings on this machine (NetworkX 3.7 and python-igraph 1.0, best of 3; NetworkX single runs):

| Graph | NetworkX | igraph | Target, `CompressedSparseRow` | Target, `UndirectedAdjacencyList<Int>` |
|---|---|---|---|---|
| G(n, p), n = 10⁵, p = 10⁻⁴ (m ≈ 5·10⁵) | 618 ms | 61 ms | ≤ 30 ms (directed; igraph 127 ms) | ≤ 60 ms |
| G(n, m), n = 10⁵, m = 5·10⁵ | 892 ms | 49 ms | ≤ 30 ms | ≤ 50 ms |
| Barabási–Albert, n = 10⁵, m = 5 | 704 ms | 85 ms | ≤ 25 ms (directed) | ≤ 60 ms |
| Watts–Strogatz, n = 10⁵, k = 10, p = 0.1 | 321 ms | 59 ms | — | ≤ 50 ms |
| Random geometric, n = 10⁵, mean degree 10 | (O(n²) without scipy: 21.6 s at n = 10⁴) | 76 ms | — | ≤ 60 ms |
| SBM, 4 × 25 000, mean degree ≈ 5.5 | 26 800 ms | 43 ms | ≤ 15 ms (directed) | ≤ 40 ms |
| `Tree.random`, n = 10⁵ | 212 ms | 9.2 ms (`Tree_Game(method="prufer")`) | — | `Tree`: ≤ 5 ms |

The CSR targets assume the generation cost (one `log` per edge for the skipping families, about two
`below` per edge for BA and G(n, m)) plus a single pass to write the rows. The adjacency-list targets are
igraph's times, since that representation hashes by design. Benchmarks go in
`Benchmarks/Benchmarks/RandomGraphsBenchmarks`, and their inputs then come from these factories instead
of the per-file `LCG`s.

## Names

| Factory | Decision | NetworkX | igraph | JGraphT | Mathematica |
|---|---|---|---|---|---|
| `erdosRenyi(vertexCount:edgeProbability:)` / `(vertexCount:edgeCount:)` | the authors' name (Principle 1), one name with the model chosen by the label, as igraph's `Erdos_Renyi(n, p=)` / `(n, m=)` does. `gnp`/`gnm` are notation, not names | `fast_gnp_random_graph`, `gnm_random_graph` (`erdos_renyi_graph` is an alias) | `Erdos_Renyi` | `GnpRandomGraphGenerator`, `GnmRandomGraphGenerator` | `RandomGraph`, `BernoulliGraphDistribution` |
| `barabasiAlbert(vertexCount:edgesPerVertex:)` | | `barabasi_albert_graph(n, m)` | `Barabasi(n, m)` | `BarabasiAlbertGraphGenerator` | `BarabasiAlbertGraphDistribution` |
| `wattsStrogatz(vertexCount:nearestNeighborCount:rewiringProbability:)` | k as NetworkX counts it: neighbours on both sides together | `watts_strogatz_graph(n, k, p)` | `Watts_Strogatz(dim, size, nei, p)` (nei per side) | `WattsStrogatzGraphGenerator` | `WattsStrogatzGraphDistribution` |
| `randomGeometric(vertexCount:radius:dimension:)` | | `random_geometric_graph` | `GRG` | — | `RandomGraph[SpatialGraphDistribution[…]]` |
| `stochasticBlockModel(blockSizes:edgeProbabilities:)` | | `stochastic_block_model(sizes, p)` | `SBM(pref_matrix, block_sizes)` | — | — |
| `Tree.random(vertexCount:)` | Swift's `random(…using:)` idiom on the type | `random_labeled_tree` | `Tree_Game` | — | `RandomTree` |
| `Xoshiro256StarStar` | the algorithm's name, spelled as Rust's `rand_xoshiro` spells it | — | — | — | — |

## Open questions, decided as recommended

1. **Where factories live.** *Recommended: the `NamedGraphs` protocols*, so each family is written
   once. The procedure body is generic only over the generator (it must be `@inlinable` and specialized,
   or each `next()` is an unspecialized witness call). It produces a sorted edge array and ends in the
   conformer's bulk initializer.
2. **Vertex type.** *Recommended: `Int` `0..<n`.* SBM blocks are consecutive ranges, and geometric
   positions are a flat `[Double]` beside the graph, the repository's side-array convention (README open question 9).
3. **Randomness.**
   - *Recommended: `inout some RandomNumberGenerator` plus `Xoshiro256StarStar` in this module.*
   - *Pin the stream* to the two draws above, and pin each procedure to NetworkX's where NetworkX's is the
     fast one. NetworkX on our stream then checks our outputs exactly. It cannot do that across different
     generators, which is why the rows use ours.
   - The two deliberate departures are Barabási–Albert's target order (ascending, not CPython set order)
     and the SBM's block order (ascending, not set order). Both match NetworkX whenever CPython's order
     happens to be ascending.
   - A change to any procedure changes rows in `cases.md`, which makes it a visible, versioned change.
4. **Algorithms.**
   - *Recommended as in the procedure table.* G(n, m) by Floyd's algorithm (Bentley and Floyd, CACM 30(9),
     1987) was considered. It also needs a hash set, and NetworkX's rejection loop gives the same O(m)
     bound for 2m ≤ N while matching NetworkX's output.
   - The random DAG keeps the fixed order rather than a random permutation. The fixed order is the
     Barak–Erdős model and NetworkX's recipe, and it gives the wrapper its topological order for free. A
     caller who wants hidden labels relabels.
5. **Directed variants.** *Recommended: as in the table above.* Barabási–Albert's directed form follows
   igraph. Watts–Strogatz and random geometric graphs have none.
6. **`edgesPerVertex`** is the least settled label. NetworkX and igraph call it `m` and describe it as
   "number of edges to attach from a new node", JGraphT as "how many edges to add from each new vertex".
   *Recommended: `edgesPerVertex`*, documented as counting the edges each new vertex brings. The
   alternative `attachmentCount` is shorter but appears in no library's documentation.
7. **`randomGeometric` returns a tuple.** *Recommended: `(graph:, positions:)`*, because a geometric
   graph without its positions is rarely useful (drawing, the distance check). NetworkX stores them as a
   node attribute and igraph as `x`/`y` attributes. A flat `[Double]` avoids one allocation per vertex.
   `positions:` taken as an argument (NetworkX's `pos=`) can come later, as a non-random
   `geometric(positions:dimension:radius:)` in `NamedGraphs`.
8. **More families** (random regular, configuration model, `newman_watts_strogatz`, random bipartite
   `BipartiteGraph.random(…)`, a random `Arborescence`). *Recommended: defer.* The protocols make each one
   a single function.
