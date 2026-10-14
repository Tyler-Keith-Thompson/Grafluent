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
