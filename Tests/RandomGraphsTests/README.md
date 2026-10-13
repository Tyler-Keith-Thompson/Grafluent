# RandomGraphs test suite

`RandomGraphs` builds the random families as static factories on the representation types, through
`NamedGraphs`' two underscored protocols:

- `erdosRenyi` (G(n, p) and G(n, m)), `barabasiAlbert`, `wattsStrogatz`, `randomGeometric`,
  `stochasticBlockModel`, `randomRegular` and `randomBipartite` on the protocols;
- `BipartiteGraph.randomBipartite`;
- `Tree.random(vertexCount:)`;
- `DirectedAcyclicGraph.erdosRenyi`;
- a public seedable generator, `Xoshiro256StarStar`.

The tests follow `api.md` in [`Tests/Catalogs/RandomGraphs/`](../Catalogs/RandomGraphs/):

- the families live on the `NamedGraphs` protocols, with `Int` vertices `0..<n`;
- every factory takes `inout some RandomNumberGenerator`, and has an overload without `using:`;
- the stream is pinned: each procedure draws only `uniform01` (the top 53 bits) and `below(n)`
  (rejection on the top bit-length-of-n bits);
- Barabási–Albert's directed form points new → old;
- Watts–Strogatz, random geometric and random regular graphs give both arcs of every edge in their
  directed form, as the symmetric named families do;
- `randomGeometric` returns `(graph:, positions:)`, with the positions as a flat `[Double]`.

The suite uses only the public API, and each test is self-contained. Nothing is shared but the tags
in `GrafluentTestSupport`. `RandomGraphsTests` depends on `NamedGraphs` for one row, RG-094, whose
catalog value is "equals `completeBipartite(leftCount: 5, rightCount: 5)`".

## API under test

```swift
struct Xoshiro256StarStar: RandomNumberGenerator, Equatable, Hashable, Sendable
    init(seed: UInt64), init(state: (UInt64, UInt64, UInt64, UInt64)), next()
extension _GraphConstruction {     // UndirectedAdjacencyList, Pseudograph, Multigraph
    static func erdosRenyi(vertexCount:edgeProbability:using:), erdosRenyi(vertexCount:edgeCount:using:),
        barabasiAlbert(vertexCount:edgesPerVertex:using:),
        wattsStrogatz(vertexCount:nearestNeighborCount:rewiringProbability:using:),
        randomGeometric(vertexCount:radius:dimension:using:) -> (graph:, positions:),
        stochasticBlockModel(blockSizes:edgeProbabilities:using:),
        randomRegular(vertexCount:degree:using:),
        randomBipartite(leftCount:rightCount:edgeProbability:using:)
}
extension _DirectedGraphConstruction {   // CSR, AdjacencyMatrix, AdjacencyList, DirectedPseudograph,
                                         // DirectedMultigraph, StableDirectedGraph
    // every factory above, with the same labels
}
extension BipartiteGraph where Vertex == Int { static func randomBipartite(leftCount:rightCount:edgeProbability:using:) }
extension Tree where Vertex == Int { static func random(vertexCount:using:) }
extension DirectedAcyclicGraph { static func erdosRenyi(vertexCount:edgeProbability:using:),
                                             erdosRenyi(vertexCount:edgeCount:using:) }
// …and each again without `using:`.
```

## How values are pinned

**Exact rows** run their family on every conformer, each with a fresh generator:

- the undirected form on the three undirected types;
- the directed form on the six directed types (both arcs of every edge for Watts–Strogatz, random
  geometric and random regular graphs);
- random bipartite rows also on `BipartiteGraph<Int>`, with its sides;
- random DAGs on `DirectedAcyclicGraph` over `AdjacencyList<Int>`, `StableDirectedGraph<Int>` and
  `DirectedPseudograph<Int>`.

The catalog shows one form. `swiftgen.py` takes the other from `ref.py`'s port of the procedures.
Each run checks the vertex and edge counts, `edges` in order (sorted for every factory but
`Tree.random`, which keeps `Tree(pruferSequence:)`'s order), the degrees, and the number of draws:
the generator after the call equals a fresh one advanced that many times. Geometric rows compare
every position exactly. Tree rows compare `pruferSequence` with the drawn code. DAG rows check
`topologicalOrder == 0..<n`, and that the undirected procedure on the same stream gives the same
pairs.

**Statistical rows** recompute the catalog's exact aggregate over the same seeds on every conformer
of the row's kind. The aggregates are an edge sum, a pooled degree variance (to 5 · 10⁻⁵), a count
of degree-m vertices, or a count of missing ring edges. Each row then checks its law with
`api.md`'s tolerance: |z| ≤ 4, within 5 %, ± 0.02 or ± 0.01. The chi-square rows (RG-029,
RG-044 – RG-046, RG-102) pin the count of every outcome from the model, and check χ² against the
catalog's value and its 0.999 quantile. The "laws hold for every seed" rows check each seed:
Barabási–Albert's edge count, degree sum and minimum degree, with the directed out-degrees exactly;
Watts–Strogatz's edge count and minimum degree; a random tree's edge count, its connectivity, and
`degree(v) = 1 + occurrences of v`, where the code is replayed from the stream in the test.

**Trap rows** run the call as an exit test on every conformer the rule covers. G(n, p)'s traps also
run on the DAG. The m > N rows run on the conformers whose N the m exceeds. A valid neighbour of the
call then runs in this process. RG-002 runs `Xoshiro256StarStar(state: (0, 0, 0, 0))`, then a state
with one nonzero word.

The catalog-row files are every file except `RandomGraphPropertyTests.swift`,
`RandomGraphScenarioTests.swift` and `Performance/`. `swiftgen.py`
generated them from `cases.md`; it sits next to `ref.py` and `cases.md` in
[`Tests/Catalogs/RandomGraphs/`](../Catalogs/RandomGraphs/):

```
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/RandomGraphs/swiftgen.py
```

It first checks that `ref.py` reproduces `cases.md` byte for byte. As it builds the rows, `ref.py`
checks the generator's published vectors and runs NetworkX 3.7 on the same stream, which gives the
same graphs except that Barabási–Albert and the SBM use ascending order where NetworkX uses set
order. igraph 1.0 checks the structural laws. `swiftgen.py` then
re-runs every row on the model, asserts that each value is the row's cell, and writes the test.

## Hand-written files

**Scenarios** (`RandomGraphScenarioTests.swift`):

- the geometric cell grid against a check of every pair written in the test, at n ≈ 2000 with
  irregular radii, at radius 0, and where 3^d > n makes the
  factory check every pair itself; both forms, the directed one as both arcs;
- radius 0 at n = 5·10⁴ through the grid, and a radius past 1/2;
- pairs exactly r apart are edges, on the points a generator of fixed words places: coincident
  points at radius 0 through every-pair checking and within one cell, and points 0.25 apart at
  radius 0.25 in neighbouring cells;
- a probability for which 1 − p rounds to 1 (1e-17) gives no edges and no draws in the random
  bipartite graph, both kinds, and in the block model;
- random DAGs built in bulk on all three bases, the same edges inserted one by one, then 400 random
  insertions and removals of edges and vertices against a model with its own cycle check: rejected
  exactly when an edge closes a cycle, the same vertices and edges, and a topological
  `topologicalOrder` after every step;
- random regular graphs with d > (n − 1) / 2: n 6, d 3 is the complement of n 6, d 2 on the same
  stream, edge for edge and draw for draw, in both forms; d = n − 1 is the complete graph and makes
  no draws, counted by a generator written in the test.

**Performance** (`Performance/`, the `RandomGraphsPerformanceTests` target, under one-minute
limits): random regular graphs at n 100 with d 90, 96 and 98 over seeds 0..<20 are simple, have
nd/2 edges and every degree d.

**Properties** (swift-property-based, with shrinking):

- the generator: rand_xoshiro's ten-value vector from (1, 2, 3, 4), and splitmix64.c's vector for
  seed 1234567 through `init(seed:) == init(state:)`. Then, from any seed, the generator agrees
  with SplitMix64 and xoshiro256\*\* written out in the test, and a copy replays;
- G(n, p): simple and sorted, with no draws at p = 0 or 1. Every conformer gives the same edges and
  the same generator state. The directed lower → higher arcs are the undirected draw. The DAG is the
  undirected draw oriented upward;
- G(n, m): exactly m edges in both branches and both kinds, with no draws at m = 0 or m = N;
- Barabási–Albert: m(n − m) edges, the star on 0…m, m older targets per new vertex, connected, and
  the directed form as the reversed undirected edges with the same draws;
- Watts–Strogatz: nk/2 edges, minimum degree k/2, the ring lattice at p = 0;
- random geometric graphs: the positions are the stream's `uniform01` draws, and u – v exactly when
  the squared distance, summed in coordinate order, is at most r²;
- the SBM: no edge in a block pair of probability 0 and every pair in one of probability 1, both
  kinds;
- `Tree.random`: a connected tree whose `pruferSequence` is the stream's n − 2 `below(n)` draws;
- random regular graphs: nd/2 edges, every degree d, sorted, the same edges and draws on every
  conformer, both arcs when directed;
- random bipartite graphs: every edge across the sides, the same edges and draws on the conformers
  and on `BipartiteGraph`, the directed forward sweep equal to the undirected draw;
- every overload without `using:`.

## Planted bugs

Each bug below, planted one at a time, makes the listed tests fail.

| Planted bug | Caught by |
|---|---|
| `uniform01` reads all 64 bits | RG-074 – RG-079 and the geometric property |
| `below(n)` uses the bit length of n − 1 | 13 tests, among them RG-037, RG-044, RG-047 – RG-054 |
| SplitMix64 words stored in reverse | 69 tests, among them RG-003 – RG-007 |
| xoshiro's rotation by 45 written as 44 | 65 tests, among them RG-001 |
| The all-zero state accepted | RG-002 |
| G(n, p)'s two directed sweeps swapped | RG-009 – RG-016 and the G(n, p) property |
| G(n, p) drawing at p = 1 instead of taking the shortcut | RG-018, RG-019 and the G(n, p) property |
| G(n, m) treats u–v and v–u as different pairs | RG-030 – RG-036, RG-044, RG-045, RG-106 and the properties |
| Barabási–Albert appends its targets in `Set` order | RG-049 – RG-054, RG-059 and the property |
| Watts–Strogatz checks for a full vertex before drawing | RG-067 |
| Geometric positions read coordinate-major | RG-074 – RG-079, RG-083 and the property |
| The SBM rounds its skip to nearest | RG-084 – RG-088, RG-092, RG-093 |
| `Tree.random` draws `below(n − 1)` | RG-097 – RG-103 and the property |
| The random DAG takes its pairs from the directed sweep | RG-104, RG-105 and the G(n, p) property |
