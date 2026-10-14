# CommunityDetection: case catalog (CD-001 – CD-262, 262 cases)

Cases for the CommunityDetection module (api.md): `modularity(of:)`, `partitionQuality(of:)`,
`louvainCommunities()`, `greedyModularityCommunities()`, `labelPropagationCommunities()`,
`asynchronousLabelPropagationCommunities()`, `girvanNewmanCommunities()`, `constantPottsModel(of:)`,
`leidenCommunities()`, `louvainPartitions()`, `kernighanLinBisection(startingFrom:)`,
`kCliqueCommunities(_:)`, `walktrapCommunities()`, `leadingEigenvectorCommunities()`,
`spectralClustering(clusterCount:)` and `codeLength(of:)`, on `Graph` and
(modularity, quality, Louvain, greedy, the constant Potts model, Leiden) `DirectedGraph`, unweighted and weighted. Every Expected cell is recomputed by `ref.py`'s model of
api.md and checked independently (its docstring lists how): `uv run --quiet --no-project --with
networkx==3.7 --with scipy==1.18.1 --with igraph==1.0.0 python3 ref.py` prints "all values agree". `gen.py` writes the
rows with `?` cells, and `ref.py --fill` fills them.

**Which reference decides.** Modularity, partition quality, greedy modularity and semi-synchronous
label propagation are deterministic in NetworkX, and Expected is NetworkX 3.7's value wherever
NetworkX shares the semantics (the Notes say where it does not: loops and parallel edges in label
propagation and `performance`). Louvain and asynchronous label propagation are randomized in
NetworkX (`seed`); Grafluent's overloads without `using:` are deterministic (api.md: vertices in
index order, ties to the greatest community label), so Expected is `ref.py`'s model, which equals
NetworkX's own code run with the identity shuffle and that tie rule (patched in, see `ref.py`).
`using:` rows have Expected only where every order gives the same partition (checked over 200
random orders and 25 NetworkX seeds); for Leiden, every order and every refinement draw.
Kernighan–Lin and k-clique communities are NetworkX's (deterministic from a given start), Walktrap
is ref.py's exact model (igraph's merges read stale Δσ values and can differ), and leading-eigenvector
communities are igraph's on graphs whose leading eigenvalues are simple. Spectral clustering is the
labeling of least inertia of the Ng–Jordan–Weiss rows over every labeling (brute force), on graphs
whose k smallest normalized-Laplacian eigenvalues stand apart from the next.

## Notation

**Graph** (as in the Centrality catalog; read by `ref.py`): `U:` undirected, `D:` directed. An
optional vertex list in brackets comes first, then edges in **position order**. `vertices` is the
listed vertices, then vertices from generators, then endpoints by first appearance. Rows are in
position order, an undirected self-loop twice.

| Token | Edges |
|---|---|
| `u-v`, `u>v` | one edge, or one arc (in a `D:` graph `-` also writes an arc) |
| `P(a,b,…)`, `C(a,b,…,z)` | the path a–b, b–c, …; the cycle a–b, …, z–a |
| `S(c;a..b)` | the star c–a, …, c–b |
| `K(n)`, `K(a..b)` | every pair i < j, lexicographic |
| `grid(r,c)` | the r × c grid, vertex i·c + j, edges right then down, row-major |
| `lcg(n,m,seed)` | m pseudo-random non-loop pairs over 0..<n (64-bit LCG, as the Centrality catalog); vertices are numbered by first appearance, so canonical communities list labels out of numeric order |
| `nx(name, args…)` | `networkx.<name>(args…)` or `networkx.<name>_graph(args…)`: its `nodes` listed, then `edges()` in NetworkX's order, attributes dropped. `karate_club` (Zachary), `barbell,5,0` (two K5 joined by an edge), `ring_of_cliques,4,4`, `connected_caveman,4,5`, `florentine_families` |
| `a..b` | every integer from a to b inclusive |

**Op**: the API call; omitted arguments take api.md's defaults. `of: [[…], …]` is the partition
given as an array of vertex arrays; `of: components` is `connectedComponents()` (weakly connected
for `D:`). `weight: [w0, …]` is `{ w[$0] }` by edge position (`weight: e%k+c`: edge e weighs
e mod k + c); `nan`, `inf` are `.nan`, `.infinity`. The karate `weight: […]` list is NetworkX's
`weight` attribute in edge order. `using: rng(s)` passes a seeded generator (any generator: the
rows are order-independent). `directed > op` runs op on `graph.directedView`. `.count`,
`.community(of: v)`, `.coverage`, `.performance` read members of the result; `[k]` is the k-th
partition of a sequence of partitions (0 the first). `quality: constantPottsModel` is
`.constantPottsModel`; `kCliqueCommunities(k: 3)` is `kCliqueCommunities(3)`, whose Expected lists the
(overlapping) communities in lexicographic order.

**Expected**: a partition in **canonical order** (communities by least vertex number, each in
`vertices` order), so Swift compares `Array(result.map(Array.init))` to it; `#x` a scalar
(`#nan` is NaN); `trap` a precondition failure.

**Tol**: `exact` means 1e-12 relative to max(1, |Expected|) for scalars, equality for partitions.
Expected scalars are rounded to 12 digits.

## A. Degenerate graphs

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-001 | `U: []` | `modularity(of: [])` | `#0` | exact | Empty graph, empty partition: m = 0, so 0 (NetworkX) |
| CD-002 | `U: []` | `partitionQuality(of: []).coverage` | `#nan` | exact | 0/0: NaN (NetworkX raises ZeroDivisionError) |
| CD-003 | `U: []` | `partitionQuality(of: []).performance` | `#nan` | exact | 0/0 pairs: NaN |
| CD-004 | `U: []` | `louvainCommunities()` | `[]` | exact | Empty partition |
| CD-005 | `U: []` | `louvainCommunities().count` | `#0` | exact |  |
| CD-006 | `U: []` | `greedyModularityCommunities()` | `[]` | exact |  |
| CD-007 | `U: []` | `labelPropagationCommunities()` | `[]` | exact |  |
| CD-008 | `U: []` | `asynchronousLabelPropagationCommunities()` | `[]` | exact |  |
| CD-009 | `D: []` | `louvainCommunities()` | `[]` | exact |  |
| CD-010 | `U: [0]` | `modularity(of: [[0]])` | `#0` | exact | One vertex, no edges: 0 |
| CD-011 | `U: [0]` | `louvainCommunities()` | `[[0]]` | exact | One vertex: one community |
| CD-012 | `U: [0]` | `greedyModularityCommunities()` | `[[0]]` | exact |  |
| CD-013 | `U: [0]` | `labelPropagationCommunities()` | `[[0]]` | exact |  |
| CD-014 | `U: [0]` | `asynchronousLabelPropagationCommunities()` | `[[0]]` | exact |  |
| CD-015 | `U: [0]` | `partitionQuality(of: [[0]]).performance` | `#nan` | exact | No pairs: NaN |
| CD-016 | `U: [0..3]` | `modularity(of: [[0, 1], [2, 3]])` | `#0` | exact | Edgeless: m = 0, so 0 (NetworkX); igraph NaN |
| CD-017 | `U: [0..3]` | `louvainCommunities()` | `[[0], [1], [2], [3]]` | exact | Edgeless: singletons |
| CD-018 | `U: [0..3]` | `greedyModularityCommunities()` | `[[0], [1], [2], [3]]` | exact | Edgeless: singletons (NetworkX `if not G.size()`) |
| CD-019 | `U: [0..3]` | `labelPropagationCommunities()` | `[[0], [1], [2], [3]]` | exact | No votes: every vertex keeps its own label |
| CD-020 | `U: [0..3]` | `asynchronousLabelPropagationCommunities()` | `[[0], [1], [2], [3]]` | exact |  |
| CD-021 | `U: [0..3]` | `partitionQuality(of: [[0, 1], [2, 3]]).coverage` | `#nan` | exact | No edges: NaN |
| CD-022 | `U: [0..3]` | `partitionQuality(of: [[0, 1], [2, 3]]).performance` | `#0.666666666667` | exact | 4 of 6 pairs are inter-community non-edges |
| CD-023 | `U: 0-0` | `modularity(of: [[0]])` | `#0` | exact | A loop alone: L = 1, d = 2, m = 1: 1 − 4/4 = 0 |
| CD-024 | `U: 0-0, 1-1` | `modularity(of: [[0], [1]])` | `#0.5` | exact | Two loops: 2 · (1/2 − 1/4) |
| CD-025 | `U: 0-0, 1-1` | `louvainCommunities()` | `[[0], [1]]` | exact | Loops never join vertices |
| CD-026 | `U: 0-0, 1-1` | `greedyModularityCommunities()` | `[[0], [1]]` | exact | No off-diagonal pair to merge |
| CD-027 | `U: 0-0, 1-1` | `labelPropagationCommunities()` | `[[0], [1]]` | exact | Loops vote for nothing |
| CD-028 | `U: 0-0, 1-1` | `asynchronousLabelPropagationCommunities()` | `[[0], [1]]` | exact |  |
| CD-029 | `U: 0-1` | `louvainCommunities()` | `[[0, 1]]` | exact | K2: one community, Q = 0 > −½ |
| CD-030 | `U: 0-1` | `greedyModularityCommunities()` | `[[0, 1]]` | exact |  |
| CD-031 | `U: 0-1` | `labelPropagationCommunities()` | `[[0, 1]]` | exact | Both adopt the greatest label, 1 |
| CD-032 | `U: 0-1` | `asynchronousLabelPropagationCommunities()` | `[[0, 1]]` | exact | 0 takes 1's label, then 1 keeps it |
| CD-033 | `D: 0>1` | `louvainCommunities()` | `[[0], [1]]` | exact | One arc: Q is 0 either way, and a move needs a strictly greater gain |
| CD-034 | `D: 0>1` | `modularity(of: [[0, 1]])` | `#0` | exact | One community is always 1 − γ = 0 |

## B. Modularity

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-035 | `U: P(0,1,2)` | `modularity(of: [[0, 1], [2]])` | `#-0.125` | exact | (1/2 − 9/16) + (0 − 1/16) |
| CD-036 | `U: P(0,1,2)` | `modularity(of: [[0, 1, 2]])` | `#0` | exact | One community: 1 − γ |
| CD-037 | `U: P(0,1,2)` | `modularity(of: [[0], [1], [2]])` | `#-0.375` | exact | Singletons: −Σ(d/2m)² |
| CD-038 | `U: P(0,1,2)` | `modularity(of: [[2], [0, 1]])` | `#-0.125` | exact | Community order does not matter |
| CD-039 | `U: P(0,1,2)` | `modularity(of: [[0, 1], [], [2]])` | `#-0.125` | exact | An empty community contributes 0 (NetworkX `is_partition` accepts it) |
| CD-040 | `U: K(4)` | `modularity(of: [[0, 1, 2, 3]])` | `#0` | exact |  |
| CD-041 | `U: K(4)` | `modularity(of: [[0, 1], [2, 3]])` | `#-0.166666666667` | exact |  |
| CD-042 | `U: K(0..2), K(3..5), 2-3` | `modularity(of: [[0, 1, 2], [3, 4, 5]])` | `#0.357142857143` | exact | Two triangles: 5/14 = 0.357… |
| CD-043 | `U: K(0..2), K(3..5), 2-3` | `modularity(of: [[0, 1, 2, 3, 4, 5]])` | `#0` | exact |  |
| CD-044 | `U: K(0..2), K(3..5), 2-3` | `modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0)` | `#0.857142857143` | exact | γ = 0: the coverage, 6/7 |
| CD-045 | `U: K(0..2), K(3..5), 2-3` | `modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0.5)` | `#0.607142857143` | exact |  |
| CD-046 | `U: K(0..2), K(3..5), 2-3` | `modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2)` | `#-0.142857142857` | exact |  |
| CD-047 | `U: K(0..2), K(3..5), 2-3` | `modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 5])` | `#0.0454545454545` | exact | A heavy bridge lowers Q |
| CD-048 | `U: K(0..2), K(3..5), 2-3` | `modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])` | `#0.357142857143` | exact | Scaling every weight leaves Q unchanged |
| CD-049 | `U: K(0..2), K(3..5), 2-3` | `modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 0])` | `#0.5` | exact | A zero-weight bridge: two disjoint triangles, ½ |
| CD-050 | `U: K(0..2), K(3..5), 2-3` | `modularity(of: components)` | `#0` | exact | `connectedComponents()` is a partition: one community here |
| CD-051 | `U: K(0..2), K(3..5)` | `modularity(of: components)` | `#0.5` | exact | Two components: ½ |
| CD-052 | `U: K(0..4), K(5..9), 4-5` | `modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])` | `#0.452380952381` | exact |  |
| CD-053 | `U: nx(barbell,5,0)` | `modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])` | `#0.452380952381` | exact | barbell(5, 0) is two K5 joined by an edge |
| CD-054 | `U: nx(ring_of_cliques,4,4)` | `modularity(of: [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]])` | `#0.607142857143` | exact |  |
| CD-055 | `U: nx(karate_club)` | `modularity(of: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21], [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]])` | `#0.358234714004` | exact | Zachary's observed split: 0.3582 (unweighted) |
| CD-056 | `U: nx(karate_club)` | `modularity(of: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21], [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]], weight: [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5])` | `#0.391437566762` | exact | NetworkX's karate `weight` attribute |
| CD-057 | `U: nx(karate_club)` | `directed > modularity(of: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21], [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]])` | `#0.358234714004` | exact | graph.directed (two arcs per edge) gives the same Q |
| CD-058 | `U: 0-1, 0-1, 1-2, 2-3` | `modularity(of: [[0, 1], [2, 3]])` | `#0.21875` | exact | Parallel edges add: the same as weight 2 |
| CD-059 | `U: 0-1, 1-2, 2-3` | `modularity(of: [[0, 1], [2, 3]], weight: [2, 1, 1])` | `#0.21875` | exact | Equals the previous row |
| CD-060 | `U: 0-1, 1-2, 1-1` | `modularity(of: [[0, 1], [2]])` | `#-0.0555555555556` | exact | A loop is A_11 = 2: d(1) = 4, L = 2 (NetworkX, igraph: −1/18) |
| CD-061 | `U: 0-1, 1-2, 1-1` | `modularity(of: [[0, 1], [2]], weight: [1, 1, 3])` | `#-0.02` | exact | A weighted loop counts its weight twice in the degree |
| CD-062 | `U: 0-1, 1-2, 1-1` | `directed > modularity(of: [[0, 1], [2]])` | `#-0.0555555555556` | exact | A loop is two loop arcs in graph.directedView: the same Q |
| CD-063 | `D: 0>1, 1>2` | `modularity(of: [[0, 1], [2]])` | `#0` | exact | Leicht–Newman: (1/2 − 2·1/4) + (0 − 0·1/4) = 0; igraph with `directed=False`: −0.125 |
| CD-064 | `D: 0>1, 1>0, 1>2` | `modularity(of: [[0, 1], [2]])` | `#0` | exact |  |
| CD-065 | `D: C(0,1,2), C(3,4,5), 2>3` | `modularity(of: [[0, 1, 2], [3, 4, 5]])` | `#0.367346938776` | exact |  |
| CD-066 | `D: C(0,1,2), C(3,4,5), 2>3` | `modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2)` | `#-0.122448979592` | exact |  |
| CD-067 | `D: 0>0, 0>1` | `modularity(of: [[0], [1]])` | `#0` | exact | A directed loop is one out- and one in-arc |
| CD-068 | `U: [a, b, c] a-b, b-c` | `modularity(of: [[a, b], [c]])` | `#-0.125` | exact | Labeled vertices |

## C. Partition quality

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-069 | `U: K(0..2), K(3..5), 2-3` | `partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).coverage` | `#0.857142857143` | exact | 6 of 7 edges inside |
| CD-070 | `U: K(0..2), K(3..5), 2-3` | `partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).performance` | `#0.933333333333` | exact | (6 + 8)/15 |
| CD-071 | `U: K(0..2), K(3..5), 2-3` | `partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).coverage` | `#0` | exact |  |
| CD-072 | `U: K(0..2), K(3..5), 2-3` | `partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).performance` | `#0.533333333333` | exact | Every non-edge pair is correct: 8/15 |
| CD-073 | `U: K(0..2), K(3..5), 2-3` | `partitionQuality(of: components).performance` | `#0.466666666667` | exact | One community: the density 7/15 |
| CD-074 | `U: nx(karate_club)` | `partitionQuality(of: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21], [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]).coverage` | `#0.858974358974` | exact |  |
| CD-075 | `U: nx(karate_club)` | `partitionQuality(of: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21], [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]).performance` | `#0.614973262032` | exact |  |
| CD-076 | `U: 0-1, 0-1, 1-2` | `partitionQuality(of: [[0, 1], [2]]).coverage` | `#0.666666666667` | exact | Parallel edges each count: 2/3 |
| CD-077 | `U: 0-1, 0-1, 1-2` | `partitionQuality(of: [[0, 1], [2]]).performance` | `#0.666666666667` | exact | Pairs by adjacency: 2/3; NetworkX returns −1 on multigraphs |
| CD-078 | `U: 0-1, 1-2, 1-1` | `partitionQuality(of: [[0, 1], [2]]).coverage` | `#0.666666666667` | exact | A loop is inside its community: 2/3 |
| CD-079 | `U: 0-1, 1-2, 1-1` | `partitionQuality(of: [[0, 1], [2]]).performance` | `#0.666666666667` | exact | Loops are not pairs: 2/3 (NetworkX counts the loop: 1) |
| CD-080 | `D: 0>1, 1>2` | `partitionQuality(of: [[0, 1], [2]]).coverage` | `#0.5` | exact |  |
| CD-081 | `D: 0>1, 1>2` | `partitionQuality(of: [[0, 1], [2]]).performance` | `#0.666666666667` | exact | Ordered pairs: (1 + 3)/6 |
| CD-082 | `D: 0>1, 1>0, 1>2` | `partitionQuality(of: [[0, 1], [2]]).performance` | `#0.833333333333` | exact |  |

## D. Louvain

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-083 | `U: K(0..2), K(3..5), 2-3` | `louvainCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact | The two triangles |
| CD-084 | `U: K(0..4), K(5..9), 4-5` | `louvainCommunities()` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact |  |
| CD-085 | `U: nx(barbell,5,0)` | `louvainCommunities()` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact |  |
| CD-086 | `U: nx(ring_of_cliques,4,4)` | `louvainCommunities()` | `[[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]` | exact | One community per clique |
| CD-087 | `U: nx(connected_caveman,4,5)` | `louvainCommunities()` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14], [15, 16, 17, 18, 19]]` | exact |  |
| CD-088 | `U: nx(karate_club)` | `louvainCommunities()` | `[[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16], [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]` | exact | Q = 0.4188, igraph `community_multilevel`'s value; NetworkX's shuffled runs give 0.3854 – 0.4198 by seed (50 seeds) |
| CD-089 | `U: nx(karate_club)` | `louvainCommunities().count` | `#4` | exact |  |
| CD-090 | `U: nx(karate_club)` | `louvainCommunities().community(of: 33)` | `#2` | exact | Communities ordered by least vertex |
| CD-091 | `U: nx(karate_club)` | `louvainCommunities(weight: [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5])` | `[[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16], [8, 9, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]` | exact |  |
| CD-092 | `U: nx(karate_club)` | `louvainCommunities(resolution: 0.5)` | `[[0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19, 21], [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]` | exact | Lower γ, larger communities |
| CD-093 | `U: nx(karate_club)` | `louvainCommunities(resolution: 2)` | `[[0, 1, 11, 12, 17, 19, 21], [2, 3, 7, 13], [4, 5, 6, 10, 16], [8, 30], [9, 26, 29, 33], [14, 15, 18, 20, 22, 32], [23, 24, 25, 27, 28, 31]]` | exact | Higher γ, smaller communities |
| CD-094 | `U: nx(karate_club)` | `louvainCommunities(resolution: 0)` | `[[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]` | exact | γ = 0: every connected component is one community |
| CD-095 | `U: nx(karate_club)` | `louvainCommunities(threshold: 1)` | `[[0, 1, 11, 17, 19, 21], [2, 3, 7, 9, 12, 13], [4, 10], [5, 6, 16], [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]` | exact | Threshold ≥ any gain: stops after the first level |
| CD-096 | `U: nx(florentine_families)` | `louvainCommunities()` | `[[Acciaiuoli, Medici, Barbadori, Ridolfi, Tornabuoni], [Castellani, Peruzzi, Strozzi, Bischeri], [Albizzi, Guadagni, Ginori, Lamberteschi], [Salviati, Pazzi]]` | exact | String vertices |
| CD-097 | `U: K(0..2), K(3..5)` | `louvainCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact | Components never merge (merging lowers Q) |
| CD-098 | `U: K(0..2), K(3..5), 2-3, 2-3, 2-3` | `louvainCommunities()` | `[[0, 1], [2, 3], [4, 5]]` | exact | Parallel edges are weight: the triple bridge pulls 2 and 3 together |
| CD-099 | `U: K(0..2), K(3..5), 2-3, 0-0, 4-4` | `louvainCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact | Loops count in degrees |
| CD-100 | `U: K(0..2), K(3..5), 2-3` | `louvainCommunities(weight: [1, 1, 1, 1, 1, 1, 10])` | `[[0, 1], [2, 3], [4, 5]]` | exact | A heavy bridge |
| CD-101 | `U: P(0,1,2,3,4,5,6,7)` | `louvainCommunities()` | `[[0, 1, 2, 3], [4, 5, 6, 7]]` | exact | Path: ties broken to the greatest label |
| CD-102 | `U: C(0,1,2,3,4,5,6,7,8,9)` | `louvainCommunities()` | `[[0, 1, 2, 9], [3, 4, 5, 6], [7, 8]]` | exact | Cycle: every first move is a tie |
| CD-103 | `U: S(0;1..6)` | `louvainCommunities()` | `[[0, 1, 2, 3, 4, 5, 6]]` | exact | Star |
| CD-104 | `U: grid(4,4)` | `louvainCommunities()` | `[[0, 1, 4, 5], [2, 3, 6, 7], [8, 9, 12, 13], [10, 11, 14, 15]]` | exact |  |
| CD-105 | `U: lcg(40,90,7)` | `louvainCommunities()` | `[[38, 29, 2, 16, 37, 8, 10, 28, 21, 22], [31, 36, 33, 14, 18, 30, 11], [25, 32, 0, 5, 9, 27, 12, 15, 34, 1, 17, 23], [19, 24, 4, 6, 13, 35, 39, 7], [20, 26, 3]]` | exact | Pseudo-random graph (api.md `lcg`) |
| CD-106 | `U: lcg(60,150,11)` | `louvainCommunities()` | `[[16, 34, 8, 38, 10, 22, 59, 36, 1, 35, 3, 20, 50, 14], [31, 13, 42, 17, 55, 57, 27], [23, 48, 29, 54, 37, 32, 26, 12], [43, 0, 58, 30, 51, 9, 2, 28, 11, 5], [15, 47, 19, 39, 40, 33, 21, 53], [44, 7, 56, 4, 49, 46, 24, 25], [6, 18, 41, 45, 52]]` | exact |  |
| CD-107 | `U: lcg(30,60,3)` | `louvainCommunities(weight: e%5+1)` | `[[29, 23, 9, 26, 7, 14], [13, 24, 12, 6], [5, 28, 25, 16, 11, 0, 10, 27], [19, 18, 17, 8, 15], [21, 3, 2, 4], [1, 20]]` | exact |  |
| CD-108 | `D: C(0,1,2), C(3,4,5), 2>3` | `louvainCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact | Directed (Dugué–Perez gain) |
| CD-109 | `D: nx(karate_club)` | `louvainCommunities()` | `[[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16], [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]` | exact | Each edge as one arc u → v, u < v; the same communities as undirected here |
| CD-110 | `D: lcg(40,100,5)` | `louvainCommunities()` | `[[32, 34, 5, 35, 33, 37, 21, 7, 31, 39, 27, 26], [13, 2, 20, 17, 22], [15, 29, 10, 24, 30, 25, 4, 16], [11, 19, 28, 23, 8, 1, 9, 12, 3, 18], [14, 38, 36, 0, 6]]` | exact |  |
| CD-111 | `U: K(0..2), K(3..5), 2-3` | `directed > louvainCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact | graph.directedView: the same communities |
| CD-112 | `U: K(0..4), K(5..9)` | `louvainCommunities(using: rng(1))` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact | Disjoint cliques: every order gives this (ref.py: 200 orders, NetworkX 25 seeds) |
| CD-113 | `U: nx(ring_of_cliques,4,4)` | `louvainCommunities(using: rng(2))` | `[[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]` | exact | Every order gives one community per clique |
| CD-114 | `U: K(0..4), K(5..9), 4-5` | `louvainCommunities(using: rng(3))` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact |  |

## E. Greedy modularity (Clauset–Newman–Moore)

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-115 | `U: K(0..2), K(3..5), 2-3` | `greedyModularityCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact |  |
| CD-116 | `U: K(0..4), K(5..9), 4-5` | `greedyModularityCommunities()` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact |  |
| CD-117 | `U: nx(ring_of_cliques,4,4)` | `greedyModularityCommunities()` | `[[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]` | exact |  |
| CD-118 | `U: nx(connected_caveman,4,5)` | `greedyModularityCommunities()` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14], [15, 16, 17, 18, 19]]` | exact |  |
| CD-119 | `U: nx(karate_club)` | `greedyModularityCommunities()` | `[[0, 4, 5, 6, 10, 11, 16, 19], [1, 2, 3, 7, 9, 12, 13, 17, 21], [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]` | exact | Q = 0.3807; igraph `community_fastgreedy` reaches the same Q |
| CD-120 | `U: nx(karate_club)` | `greedyModularityCommunities().count` | `#3` | exact |  |
| CD-121 | `U: nx(karate_club)` | `greedyModularityCommunities(weight: [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5])` | `[[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16], [8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]` | exact |  |
| CD-122 | `U: nx(karate_club)` | `greedyModularityCommunities(resolution: 0.5)` | `[[0, 1, 3, 4, 5, 6, 7, 10, 11, 12, 13, 16, 17, 19, 21], [2, 8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]` | exact |  |
| CD-123 | `U: nx(karate_club)` | `greedyModularityCommunities(resolution: 2)` | `[[0, 4, 5, 6, 10, 11, 16], [1, 17, 19, 21], [2, 9, 28], [3, 7, 12, 13], [8, 30], [14, 15, 18, 20, 22, 26, 29, 32, 33], [23, 24, 25, 27, 31]]` | exact |  |
| CD-124 | `U: nx(florentine_families)` | `greedyModularityCommunities()` | `[[Acciaiuoli, Medici, Ridolfi, Tornabuoni, Salviati, Pazzi], [Castellani, Peruzzi, Strozzi, Barbadori, Bischeri], [Albizzi, Guadagni, Ginori, Lamberteschi]]` | exact |  |
| CD-125 | `U: P(0,1,2,3,4,5,6,7)` | `greedyModularityCommunities()` | `[[0, 1, 2, 3], [4, 5, 6, 7]]` | exact | Ties: the least pair (u, v), u merged into v |
| CD-126 | `U: C(0,1,2,3,4,5,6,7,8,9)` | `greedyModularityCommunities()` | `[[0, 1, 2, 3], [4, 5, 6, 7], [8, 9]]` | exact |  |
| CD-127 | `U: K(0..2), K(3..5), 2-3, 2-3, 0-0` | `greedyModularityCommunities()` | `[[0, 1], [2, 3, 4, 5]]` | exact | Parallel edges and loops |
| CD-128 | `U: K(0..2), K(3..5)` | `greedyModularityCommunities(resolution: 0)` | `[[0, 1, 2], [3, 4, 5]]` | exact | γ = 0: ΔQ ≥ 0 for every adjacent pair, so components |
| CD-129 | `U: lcg(40,90,7)` | `greedyModularityCommunities()` | `[[38, 29, 2, 16, 33, 8, 10, 26, 11, 21, 22], [31, 19, 24, 36, 13, 35, 39, 17], [25, 32, 0, 37, 9, 27, 15, 28, 34], [4, 6, 18, 30, 20, 3, 7], [5, 14, 12, 1, 23]]` | exact |  |
| CD-130 | `U: lcg(30,60,3)` | `greedyModularityCommunities(weight: e%5+1)` | `[[29, 13, 9, 26, 7, 14, 15], [5, 28, 25, 16, 11, 0, 10, 27], [24, 23, 12, 6], [19, 18, 17, 8, 1, 20], [21, 3, 2, 4]]` | exact |  |
| CD-131 | `D: C(0,1,2), C(3,4,5), 2>3` | `greedyModularityCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact | Directed |
| CD-132 | `D: lcg(40,100,5)` | `greedyModularityCommunities()` | `[[32, 34, 5, 35, 33, 37, 31, 39], [13, 2, 20, 17, 22], [15, 29, 30, 25, 4, 7, 16, 26], [11, 19, 10, 24, 28, 23, 8, 1, 9, 12, 27, 3, 18], [21, 14, 38, 36, 0, 6]]` | exact |  |

## F. Label propagation

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-133 | `U: K(0..2), K(3..5), 2-3` | `labelPropagationCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact | Semi-synchronous (Cordasco–Gargano), NetworkX's deterministic rule |
| CD-134 | `U: K(0..4), K(5..9), 4-5` | `labelPropagationCommunities()` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact |  |
| CD-135 | `U: nx(ring_of_cliques,4,4)` | `labelPropagationCommunities()` | `[[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]` | exact |  |
| CD-136 | `U: nx(karate_club)` | `labelPropagationCommunities()` | `[[0, 1, 3, 4, 7, 10, 11, 12, 13, 17, 19, 21, 24, 25, 31], [2, 8, 9, 14, 15, 18, 20, 22, 23, 26, 27, 28, 29, 30, 32, 33], [5, 6, 16]]` | exact | NetworkX `label_propagation_communities` itself; Q = 0.3251 |
| CD-137 | `U: nx(karate_club)` | `labelPropagationCommunities().count` | `#3` | exact |  |
| CD-138 | `U: nx(karate_club)` | `labelPropagationCommunities(weight: [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5])` | `[[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 10], [5, 6, 16], [8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]` | exact | Weighted votes (NetworkX has no weight here) |
| CD-139 | `U: P(0,1,2,3,4,5)` | `labelPropagationCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact |  |
| CD-140 | `U: K(0..2), 2-3, 3-3, 3-3` | `labelPropagationCommunities()` | `[[0, 1, 2, 3]]` | exact | Loops vote for nothing |
| CD-141 | `U: 0-1, 0-1, 1-2` | `labelPropagationCommunities()` | `[[0, 1, 2]]` | exact | Parallel edges each vote |
| CD-142 | `U: lcg(40,90,7)` | `labelPropagationCommunities()` | `[[38, 31, 5, 14, 18, 30, 12, 8, 10, 20, 26, 3, 1, 23, 7], [25, 4, 6, 32, 0, 16, 33, 37, 9, 27, 15, 28, 34, 11], [19, 13, 39, 17], [24, 36, 35], [29, 2, 21, 22]]` | exact |  |
| CD-143 | `U: K(0..2), K(3..5), 2-3` | `asynchronousLabelPropagationCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact | Index order, ties to the greatest label |
| CD-144 | `U: K(0..4), K(5..9), 4-5` | `asynchronousLabelPropagationCommunities()` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact |  |
| CD-145 | `U: nx(ring_of_cliques,4,4)` | `asynchronousLabelPropagationCommunities()` | `[[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]]` | exact | Index order floods the ring with one label: the known weakness of asynchronous propagation; shuffled orders usually find the cliques |
| CD-146 | `U: nx(karate_club)` | `asynchronousLabelPropagationCommunities()` | `[[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21, 24, 25, 28, 30, 31], [9, 14, 15, 18, 20, 22, 23, 26, 27, 29, 32, 33]]` | exact | Q = 0.2807 |
| CD-147 | `U: nx(karate_club)` | `asynchronousLabelPropagationCommunities(weight: [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5])` | `[[0, 1, 2, 3, 7, 8, 11, 12, 13, 17, 19, 21, 30], [4, 10], [5, 6, 16], [9, 15, 18, 22, 27, 28, 33], [14, 20, 23, 26, 29, 32], [24, 25, 31]]` | exact |  |
| CD-148 | `U: P(0,1,2,3,4,5)` | `asynchronousLabelPropagationCommunities()` | `[[0, 1], [2, 3], [4, 5]]` | exact |  |
| CD-149 | `U: 0-1, 0-1, 1-2` | `asynchronousLabelPropagationCommunities()` | `[[0, 1, 2]]` | exact | 1 sides with 0 (two votes) |
| CD-150 | `U: 0-1, 1-2` | `asynchronousLabelPropagationCommunities(weight: [1, 3])` | `[[0, 1, 2]]` | exact |  |
| CD-151 | `U: K(0..2), 2-3, 3-3, 3-3` | `asynchronousLabelPropagationCommunities()` | `[[0, 1, 2, 3]]` | exact | Loops vote for nothing |
| CD-152 | `U: lcg(40,90,7)` | `asynchronousLabelPropagationCommunities()` | `[[38, 31, 25, 19, 24, 4, 6, 32, 0, 29, 2, 5, 36, 16, 33, 14, 18, 13, 37, 30, 35, 9, 27, 12, 15, 8, 10, 20, 26, 28, 34, 11, 3, 39, 1, 21, 17, 23, 7, 22]]` | exact |  |
| CD-153 | `U: K(0..4), K(5..9)` | `asynchronousLabelPropagationCommunities(using: rng(1))` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact | Every order and tie choice gives this |
| CD-154 | `U: K(0..3), K(4..7), K(8..11)` | `asynchronousLabelPropagationCommunities(using: rng(9))` | `[[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11]]` | exact |  |

## G. Preconditions

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-155 | `U: P(0,1,2)` | `modularity(of: [[0, 1]])` | `trap` | exact | Vertex 2 missing (NetworkX `NotAPartition`) |
| CD-156 | `U: P(0,1,2)` | `modularity(of: [[0, 1], [1, 2]])` | `trap` | exact | Vertex 1 twice |
| CD-157 | `U: P(0,1,2)` | `modularity(of: [[0, 1], [2, 7]])` | `trap` | exact | 7 is not a vertex |
| CD-158 | `U: P(0,1,2)` | `modularity(of: [[0, 1], [2]], resolution: -1)` | `trap` | exact |  |
| CD-159 | `U: P(0,1,2)` | `modularity(of: [[0, 1], [2]], resolution: nan)` | `trap` | exact |  |
| CD-160 | `U: P(0,1,2)` | `modularity(of: [[0, 1], [2]], weight: [1, -1])` | `trap` | exact |  |
| CD-161 | `U: P(0,1,2)` | `modularity(of: [[0, 1], [2]], weight: [1, nan])` | `trap` | exact |  |
| CD-162 | `U: P(0,1,2)` | `modularity(of: [[0, 1], [2]], weight: [1, inf])` | `trap` | exact |  |
| CD-163 | `U: P(0,1,2)` | `partitionQuality(of: [[0, 1]]).coverage` | `trap` | exact |  |
| CD-164 | `U: P(0,1,2)` | `louvainCommunities(resolution: -0.5)` | `trap` | exact |  |
| CD-165 | `U: P(0,1,2)` | `louvainCommunities(threshold: -1)` | `trap` | exact |  |
| CD-166 | `U: P(0,1,2)` | `louvainCommunities(threshold: nan)` | `trap` | exact |  |
| CD-167 | `U: P(0,1,2)` | `louvainCommunities(weight: [1, -2])` | `trap` | exact |  |
| CD-168 | `D: P(0,1,2)` | `louvainCommunities(weight: [1, nan])` | `trap` | exact |  |
| CD-169 | `U: P(0,1,2)` | `greedyModularityCommunities(resolution: -1)` | `trap` | exact |  |
| CD-170 | `U: P(0,1,2)` | `greedyModularityCommunities(weight: [1, -1])` | `trap` | exact |  |
| CD-171 | `U: P(0,1,2)` | `labelPropagationCommunities(weight: [1, -1])` | `trap` | exact |  |
| CD-172 | `U: P(0,1,2)` | `asynchronousLabelPropagationCommunities(weight: [inf, 1])` | `trap` | exact |  |
| CD-173 | `U: P(0,1,2)` | `greedyModularityCommunities(weight: [0, 0])` | `[[0], [1], [2]]` | exact | Not a trap: total weight 0 gives singletons (NetworkX divides by 0) |
| CD-174 | `U: P(0,1,2)` | `louvainCommunities(weight: [0, 0])` | `[[0], [1], [2]]` | exact | Not a trap: no gain is positive |

## H. Girvan–Newman

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-175 | `U: []` | `girvanNewmanCommunities()[0]` | `[]` | exact | No vertices: one empty partition |
| CD-176 | `U: [0..3]` | `girvanNewmanCommunities()[0]` | `[[0], [1], [2], [3]]` | exact | No edges: the components once (NetworkX) |
| CD-177 | `U: 0-0, 1-1` | `girvanNewmanCommunities()[0]` | `[[0], [1]]` | exact | Self-loops only: the components once (NetworkX yields nothing here) |
| CD-178 | `U: K(0..2), K(3..5), 2-3` | `girvanNewmanCommunities()[0]` | `[[0, 1, 2], [3, 4, 5]]` | exact | The bridge carries every crossing pair |
| CD-179 | `U: K(0..2), K(3..5), 2-3` | `girvanNewmanCommunities()[1]` | `[[0], [1, 2], [3, 4, 5]]` | exact | Then every triangle edge ties: 0-1 goes (least position), then 0-2 of the path left |
| CD-180 | `U: K(0..2), K(3..5), 2-3` | `girvanNewmanCommunities()[4]` | `[[0], [1], [2], [3], [4], [5]]` | exact | The last level: every vertex alone |
| CD-181 | `U: K(0..4), K(5..9), 4-5` | `girvanNewmanCommunities()[0]` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact | Two K5 and their bridge |
| CD-182 | `U: nx(barbell,5,0)` | `girvanNewmanCommunities()[0]` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact |  |
| CD-183 | `U: nx(connected_caveman,4,5)` | `girvanNewmanCommunities()[0]` | `[[0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [10, 11, 12, 13, 14, 15, 16, 17, 18, 19]]` | exact |  |
| CD-184 | `U: nx(karate_club)` | `girvanNewmanCommunities()[0]` | `[[0, 1, 3, 4, 5, 6, 7, 10, 11, 12, 13, 16, 17, 19, 21], [2, 8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]` | exact | NetworkX agrees (no tie decides it) |
| CD-185 | `U: nx(karate_club)` | `girvanNewmanCommunities()[1]` | `[[0, 1, 3, 4, 5, 6, 7, 10, 11, 12, 13, 16, 17, 19, 21], [2, 8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33], [9]]` | exact | Vertex 9 splits off |
| CD-186 | `U: nx(karate_club)` | `girvanNewmanCommunities()[2]` | `[[0, 1, 3, 7, 11, 12, 13, 17, 19, 21], [2, 8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33], [4, 5, 6, 10, 16], [9]]` | exact |  |
| CD-187 | `U: nx(florentine_families)` | `girvanNewmanCommunities()[0]` | `[[Acciaiuoli, Medici, Castellani, Peruzzi, Strozzi, Barbadori, Ridolfi, Tornabuoni, Albizzi, Bischeri, Guadagni, Ginori, Lamberteschi], [Salviati, Pazzi]]` | exact | `String` vertices |
| CD-188 | `U: P(0,1,2), 3-4, 2-2` | `girvanNewmanCommunities()[0]` | `[[0], [1, 2], [3, 4]]` | exact | Already disconnected: one more community than the components; the loop changes nothing |
| CD-189 | `U: P(0,1,2), 3-4, 2-2` | `girvanNewmanCommunities()[1]` | `[[0], [1], [2], [3, 4]]` | exact | 1-2 and 3-4 tie: 1-2 has the lesser position |
| CD-190 | `U: 0-1, 1-2, 0-1` | `girvanNewmanCommunities()[0]` | `[[0, 1], [2]]` | exact | Parallel copies share their pairs' paths, so the single edge goes first |
| CD-191 | `U: 0-1, 1-2, 0-1` | `girvanNewmanCommunities()[1]` | `[[0], [1], [2]]` | exact | Then both copies, one at a time |

## I. Leiden, the constant Potts model and Louvain's levels

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-192 | `U: K(0..2), K(3..5), 2-3` | `constantPottsModel(of: [[0, 1, 2], [3, 4, 5]])` | `#-3` | exact | 2 (3 − 9/2) |
| CD-193 | `U: K(0..2), K(3..5), 2-3` | `constantPottsModel(of: [[0, 1, 2], [3, 4, 5]], resolution: 0.5)` | `#1.5` | exact | 2 (3 − 9/4) |
| CD-194 | `U: K(0..2), K(3..5), 2-3` | `constantPottsModel(of: [[0, 1, 2, 3, 4, 5]], weight: [1, 2, 3, 4, 5, 6, 7], resolution: 0.1)` | `#26.2` | exact | 28 − 0.05 · 36 |
| CD-195 | `U: 0-0, 0-1, 1-0` | `constantPottsModel(of: [[0, 1]])` | `#1` | exact | A loop and both copies are inside: 3 − 2 |
| CD-196 | `D: C(0,1,2), C(3,4,5), 2>3` | `constantPottsModel(of: [[0, 1, 2], [3, 4, 5]])` | `#-12` | exact | Directed: Σ [e_c − γ n_c²] |
| CD-197 | `U: nx(karate_club)` | `constantPottsModel(of: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21], [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]], resolution: 0.05)` | `#52.55` | exact | NetworkX `constant_potts_model` |
| CD-198 | `U: []` | `constantPottsModel(of: [])` | `#0` | exact |  |
| CD-199 | `U: P(0,1,2)` | `constantPottsModel(of: [[0, 1, 2]], resolution: -1)` | `trap` | exact |  |
| CD-200 | `U: K(0..2), K(3..5), 2-3` | `leidenCommunities(using: rng(1))` | `[[0, 1, 2], [3, 4, 5]]` | exact | Every order gives the triangles |
| CD-201 | `U: K(0..4), K(5..9), 4-5` | `leidenCommunities(using: rng(2))` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact |  |
| CD-202 | `U: nx(ring_of_cliques,4,4)` | `leidenCommunities(using: rng(3))` | `[[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]` | exact | One community per clique |
| CD-203 | `U: nx(connected_caveman,4,5)` | `leidenCommunities(using: rng(4))` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14], [15, 16, 17, 18, 19]]` | exact |  |
| CD-204 | `U: K(0..2), K(3..5), 2-3` | `leidenCommunities(quality: constantPottsModel, resolution: 0.5, using: rng(5))` | `[[0, 1, 2], [3, 4, 5]]` | exact | Each triangle 3 − 9/4 > 0 |
| CD-205 | `U: K(0..2), K(3..5), 2-3` | `leidenCommunities(quality: constantPottsModel, resolution: 0.1, using: rng(6))` | `[[0, 1, 2, 3, 4, 5]]` | exact | 7 − 1.8 beats 2 (3 − 0.45) |
| CD-206 | `U: K(0..2), K(3..5), 2-3` | `leidenCommunities(quality: constantPottsModel, resolution: 2, using: rng(7))` | `[[0], [1], [2], [3], [4], [5]]` | exact | Every community of two or more is below 0: singletons |
| CD-207 | `U: [0..3]` | `leidenCommunities(using: rng(8))` | `[[0], [1], [2], [3]]` | exact | No edges: singletons |
| CD-208 | `U: 0-0, 1-1` | `leidenCommunities(using: rng(9))` | `[[0], [1]]` | exact | Loops never join vertices |
| CD-209 | `U: K(0..2), K(3..5), 2-3, 2-3, 2-3` | `leidenCommunities(using: rng(10))` | `[[0, 1], [2, 3], [4, 5]]` | exact | Parallel edges are weight |
| CD-210 | `D: C(0,1,2), C(3,4,5), 2>3` | `leidenCommunities(using: rng(11))` | `[[0, 1, 2], [3, 4, 5]]` | exact | Directed modularity |
| CD-211 | `U: P(0,1,2)` | `leidenCommunities(randomness: 0, using: rng(1))` | `trap` | exact |  |
| CD-212 | `U: P(0,1,2)` | `leidenCommunities(iterations: 0, using: rng(1))` | `trap` | exact |  |
| CD-213 | `U: K(0..2), K(3..5), 2-3` | `louvainPartitions()[0]` | `[[0, 1, 2], [3, 4, 5]]` | exact | The first level |
| CD-214 | `U: nx(karate_club)` | `louvainPartitions()[0]` | `[[0, 1, 11, 17, 19, 21], [2, 3, 7, 9, 12, 13], [4, 10], [5, 6, 16], [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]` | exact |  |
| CD-215 | `U: nx(karate_club)` | `louvainPartitions()[1]` | `[[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16], [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]` | exact | The last level is louvainCommunities() (CD-088) |
| CD-216 | `D: C(0,1,2), C(3,4,5), 2>3` | `louvainPartitions()[0]` | `[[0, 1, 2], [3, 4, 5]]` | exact |  |
| CD-217 | `U: [0..2]` | `louvainPartitions()[0]` | `[[0], [1], [2]]` | exact | No edges: one level of singletons |

## J. Kernighan–Lin, k-clique, Walktrap and leading-eigenvector communities

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-218 | `U: K(0..2), K(3..5), 2-3` | `kernighanLinBisection(startingFrom: [[0, 3, 4], [1, 2, 5]])` | `[[0, 1, 2], [3, 4, 5]]` | exact | NetworkX `kernighan_lin_bisection` agrees |
| CD-219 | `U: nx(karate_club)` | `kernighanLinBisection(startingFrom: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], [17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]])` | `[[0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19, 21], [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]` | exact | NetworkX agrees |
| CD-220 | `U: nx(karate_club)` | `kernighanLinBisection(startingFrom: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16], [17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]], weight: [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5])` | `[[0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19, 21], [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]` | exact | NetworkX agrees |
| CD-221 | `U: K(0..2), K(3..5), 2-3` | `kernighanLinBisection(startingFrom: [[0, 3, 4], [1, 2, 5]], iterations: 0)` | `[[0, 3, 4], [1, 2, 5]]` | exact | No pass: the start |
| CD-222 | `U: [0..3]` | `kernighanLinBisection(startingFrom: [[0, 1], [2, 3]])` | `[[0, 1], [2, 3]]` | exact | No edges: no pass lowers the cut |
| CD-223 | `U: P(0,1,2)` | `kernighanLinBisection(startingFrom: [[0], [1], [2]])` | `trap` | exact |  |
| CD-224 | `U: nx(karate_club)` | `kCliqueCommunities(k: 3)` | `[[0, 1, 2, 3, 7, 8, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23, 26, 27, 28, 29, 30, 31, 32, 33], [0, 4, 5, 6, 10, 16], [24, 25, 31]]` | exact | NetworkX `k_clique_communities`; communities overlap |
| CD-225 | `U: nx(karate_club)` | `kCliqueCommunities(k: 4)` | `[[0, 1, 2, 3, 7, 13], [8, 30, 32, 33], [23, 29, 32, 33]]` | exact |  |
| CD-226 | `U: K(0..3), K(3..6)` | `kCliqueCommunities(k: 4)` | `[[0, 1, 2, 3], [3, 4, 5, 6]]` | exact | Two K4 sharing a vertex: separate, overlapping |
| CD-227 | `U: K(0..2), 1-3, 2-3, 3-4` | `kCliqueCommunities(k: 3)` | `[[0, 1, 2, 3]]` | exact | Two triangles sharing an edge percolate |
| CD-228 | `U: K(0..2), 1-3, 2-3, 3-4` | `kCliqueCommunities(k: 2)` | `[[0, 1, 2, 3, 4]]` | exact | k = 2: the components with an edge |
| CD-229 | `U: P(0,1,2)` | `kCliqueCommunities(k: 1)` | `trap` | exact |  |
| CD-230 | `U: K(0..2), K(3..5), 2-3` | `walktrapCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact |  |
| CD-231 | `U: nx(karate_club)` | `walktrapCommunities()` | `[[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16], [8, 9, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]` | exact | Exact Ward merges; igraph's `community_walktrap` reads stale Δσ and cuts at Q = 0.3532 |
| CD-232 | `U: K(0..4), K(5..9), 4-5` | `walktrapCommunities(steps: 2)` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact |  |
| CD-233 | `U: nx(connected_caveman,4,5)` | `walktrapCommunities()` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14], [15, 16, 17, 18, 19]]` | exact |  |
| CD-234 | `U: [0..2]` | `walktrapCommunities()` | `[[0], [1], [2]]` | exact | No edges: singletons |
| CD-235 | `U: P(0,1,2)` | `walktrapCommunities(steps: 0)` | `trap` | exact |  |
| CD-236 | `U: K(0..2), K(3..5), 2-3` | `leadingEigenvectorCommunities()` | `[[0, 1, 2], [3, 4, 5]]` | exact | igraph `community_leading_eigenvector` agrees |
| CD-237 | `U: nx(karate_club)` | `leadingEigenvectorCommunities()` | `[[0, 4, 5, 6, 10, 11, 16], [1, 2, 3, 7, 12, 13, 17, 19, 21], [8, 9, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]` | exact | igraph agrees: Q = 0.3934 |
| CD-238 | `U: nx(barbell,5,0)` | `leadingEigenvectorCommunities()` | `[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]` | exact | The two K5 (a symmetric ring of cliques has a repeated leading eigenvalue, so no row) |
| CD-239 | `U: [0..3]` | `leadingEigenvectorCommunities()` | `[[0], [1], [2], [3]]` | exact | Total weight 0: singletons (igraph agrees) |
| CD-240 | `U: K(0..3)` | `leadingEigenvectorCommunities()` | `[[0, 1, 2, 3]]` | exact | λ ≤ 0: indivisible |

## K. Spectral clustering

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-241 | `U: K(0..2), K(3..5), 2-3` | `spectralClustering(clusterCount: 2, using: rng(1))` | `[[0, 1, 2], [3, 4, 5]]` | exact | The two triangles |
| CD-242 | `U: P(0,1,2), P(3,4,5)` | `spectralClustering(clusterCount: 2, using: rng(1))` | `[[0, 1, 2], [3, 4, 5]]` | exact | Two components |
| CD-243 | `U: P(0..3)` | `spectralClustering(clusterCount: 1, using: rng(1))` | `[[0, 1, 2, 3]]` | exact | One cluster |
| CD-244 | `U: 0-1, 0-2, 0-5, 1-6, 2-3, 3-4, 4-7` | `spectralClustering(clusterCount: 2, using: rng(1))` | `[[0, 1, 5, 6], [2, 3, 4, 7]]` | exact | A tree where the unit rows decide: without the row scaling, 2 goes with 0 |
| CD-245 | `U: K(0..2), K(3..5), K(6..8), 2-3, 5-6` | `spectralClustering(clusterCount: 3, using: rng(1))` | `[[0, 1, 2], [3, 4, 5], [6, 7, 8]]` | exact | Three triangles in a chain |
| CD-246 | `U: P(0..5)` | `spectralClustering(clusterCount: 2, weight: [3, 3, 0, 3, 3], using: rng(1))` | `[[0, 1, 2], [3, 4, 5]]` | exact | A weight-0 edge separates |
| CD-247 | `U: P(0,1,2)` | `spectralClustering(clusterCount: 4, using: rng(1))` | `trap` | exact | clusterCount > vertexCount |
| CD-248 | `U: P(0,1,2)` | `spectralClustering(clusterCount: 0, using: rng(1))` | `trap` | exact | clusterCount < 1 |

## L. The map equation

| ID | Graph | Op | Expected | Tol | Notes |
|---|---|---|---|---|---|
| CD-249 | `U: K(0..2), K(3..5), 2-3` | `codeLength(of: [[0, 1, 2], [3, 4, 5]])` | `#2.32073035683` | exact | igraph `community_infomap` finds it, codelength 2.3207303568 |
| CD-250 | `U: K(0..2), K(3..5), 2-3` | `codeLength(of: [[0, 1, 2, 3, 4, 5]])` | `#2.55665670746` | exact | One module: the entropy of the vertex flows |
| CD-251 | `U: K(0..2), K(3..5), 2-3` | `codeLength(of: [[0], [1], [2], [3], [4], [5]])` | `#4.55665670746` | exact | Singletons |
| CD-252 | `U: nx(karate_club)` | `codeLength(of: [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16], [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]])` | `#4.3117926458` | exact | igraph `community_infomap`'s partition, codelength 4.3117926458 |
| CD-253 | `U: nx(karate_club)` | `codeLength(of: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21], [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]])` | `#4.46209072138` | exact | The club's split |
| CD-254 | `U: nx(karate_club)` | `codeLength(of: [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21], [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]], weight: [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5])` | `#4.25414247029` | exact | Weighted: flows by weight |
| CD-255 | `U: 0-0, 1-1` | `codeLength(of: [[0], [1]])` | `#0` | exact | Loops never leave a module: 0 |
| CD-256 | `U: 0-0, 1-1` | `codeLength(of: [[0, 1]])` | `#1` | exact | One module of two equal flows: 1 bit |
| CD-257 | `U: 0-1, 0-1, 1-2` | `codeLength(of: [[0, 1], [2]])` | `#2.12581458369` | exact | Parallel edges add |
| CD-258 | `U: [0..2]` | `codeLength(of: [[0, 1, 2]])` | `#0` | exact | No edges: 0 |
| CD-259 | `U: []` | `codeLength(of: [])` | `#0` | exact |  |
| CD-260 | `U: P(0,1,2)` | `codeLength(of: [[0, 1, 2]], weight: [0, 0])` | `#0` | exact | Total weight 0: 0 |
| CD-261 | `U: P(0,1,2)` | `codeLength(of: [[0, 1], [1, 2]])` | `trap` | exact | A vertex listed twice |
| CD-262 | `U: P(0,1,2)` | `codeLength(of: [[0, 1, 2]], weight: [1, -1])` | `trap` | exact | A negative weight |
