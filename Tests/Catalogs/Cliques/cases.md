# Cliques: case catalog (CQ-001 – CQ-633, 276 cases)

Cases for the Cliques module (api.md): `maximalCliques()`, `maximumClique()`, `cliqueNumber()`,
`coreNumbers()` and the `CoreNumbers` value (`degeneracy`, `degeneracyOrdering`, `kCore(_:)`,
`kShell(_:)`), `clusteringCoefficients()` and the `ClusteringCoefficients` value, and the one-shot
`triangleCount()`, `triangleCount(of:)`, `clusteringCoefficient(of:)`, `transitivity()`,
`averageClustering()`, all on `Graph`. Harvested from NetworkX 3.7 (`clique.py`, `core.py`,
`cluster.py` docstrings and behaviour), python-igraph 1.0.0 (`igprobe.py`, `igprobe2.py` here),
JGraphT and Boost sources (read for conventions), and the edge cases api.md calls out. Every
Expected cell is recomputed by `ref.py` and cross-checked against brute force (all vertex
subsets up to 14 vertices, peeling for cores), NetworkX 3.7 and Latapy's compact-forward count
(see its docstring); 250 random multigraphs with loops and 30 G(n, p) graphs are checked the same
way.

## Notation

**Graph** (the Distances catalog's notation, read by `ref.py`): `U:` undirected, `D:` directed.
An optional vertex list in brackets comes first, then edges in **position order**. `vertices` is
the listed vertices, then vertices from generators, then endpoints by first appearance. Rows
(`incidentEdges`) are in position order, a self-loop twice, unless `~rev` (every row reversed).

| Token | Edges |
|---|---|
| `u-v`, `u>v` | one edge, or one arc |
| `P(a,b,…)`, `C(a,b,…,z)` | the path a–b, b–c, …; the cycle a–b, …, z–a (arcs in a `D:` graph) |
| `S(c;a..b)` | the star c–a, …, c–b |
| `K(n)`, `K(a..b)` | every pair i < j, lexicographic; its vertices listed in order |
| `KB(a..b;c..d)` | each of the first list to each of the second, row-major |
| `KM(a,b,…)` | the complete multipartite graph with parts of a, b, … consecutive vertices from 0; pairs i < j in different parts, lexicographic |
| `moon(k)` | the Moon–Moser graph `KM(3,3,…,3)`, k parts: 3^k maximal cliques, the most any 3k-vertex graph has |
| `grid(r,c)` | vertices `i*c + j` row-major; for each vertex in order the edge right, then down |
| `lcg(n,m,s)` | vertices 0..<n, then m non-loop pairs from the 64-bit LCG of the Distances catalog, seeded s (parallel pairs possible) |
| `nx(name)` | `networkx.<name>_graph()`: its `nodes` listed, then `edges()` in NetworkX's order |
| `a..b` | every integer from a to b inclusive |

**Op**: the API call on the graph; `undirected > op` runs op on `digraph.undirected` (each arc an
edge). `maximalCliques` is the whole sequence in order; `.count` its length. `coreNumbers`,
`triangleCounts`, `clusteringCoefficients` list the value's per-vertex answers in `vertices` order
(`coreNumber(ofIndex: i)`, `triangleCount(ofIndex: i)`, `clusteringCoefficient(ofIndex: i)`);
`degeneracy`, `degeneracyOrdering`, `kCore(k)`, `kShell(k)` are members of `coreNumbers()`;
`triangleCount`, `transitivity`, `averageClustering` are the one-shot calls, which must equal the
same members of `clusteringCoefficients()` (the Swift tests should assert that for every case).

**Expected**: `#k` a number (`Double` printed shortest round-trip, as Swift's `description`);
`[a, b, …]` vertices in order, or numbers per vertex; `[[…], […]]` cliques in sequence order;
`trap` a precondition failure.

## A. Degenerate graphs

The empty graph, one vertex, isolated vertices, one edge. Every op on each.

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| CQ-001 | `U: []` | `maximalCliques` | `[]` | Empty graph |
| CQ-002 | `U: []` | `maximumClique` | `[]` |  |
| CQ-003 | `U: []` | `cliqueNumber` | `#0` |  |
| CQ-004 | `U: []` | `coreNumbers` | `[]` |  |
| CQ-005 | `U: []` | `degeneracy` | `#0` |  |
| CQ-006 | `U: []` | `degeneracyOrdering` | `[]` |  |
| CQ-007 | `U: []` | `triangleCount` | `#0` |  |
| CQ-008 | `U: []` | `clusteringCoefficients` | `[]` |  |
| CQ-009 | `U: []` | `transitivity` | `#0.0` |  |
| CQ-010 | `U: []` | `averageClustering` | `#0.0` |  |
| CQ-011 | `U: [0]` | `maximalCliques` | `[[0]]` | K₁ |
| CQ-012 | `U: [0]` | `maximumClique` | `[0]` |  |
| CQ-013 | `U: [0]` | `cliqueNumber` | `#1` |  |
| CQ-014 | `U: [0]` | `coreNumbers` | `[0]` |  |
| CQ-015 | `U: [0]` | `degeneracy` | `#0` |  |
| CQ-016 | `U: [0]` | `degeneracyOrdering` | `[0]` |  |
| CQ-017 | `U: [0]` | `triangleCount` | `#0` |  |
| CQ-018 | `U: [0]` | `clusteringCoefficients` | `[0.0]` |  |
| CQ-019 | `U: [0]` | `transitivity` | `#0.0` |  |
| CQ-020 | `U: [0]` | `averageClustering` | `#0.0` |  |
| CQ-021 | `U: [0] 0-0` | `maximalCliques` | `[[0]]` | K₁ with a self-loop: the loop is ignored by every op |
| CQ-022 | `U: [0] 0-0` | `maximumClique` | `[0]` |  |
| CQ-023 | `U: [0] 0-0` | `cliqueNumber` | `#1` |  |
| CQ-024 | `U: [0] 0-0` | `coreNumbers` | `[0]` |  |
| CQ-025 | `U: [0] 0-0` | `degeneracy` | `#0` |  |
| CQ-026 | `U: [0] 0-0` | `degeneracyOrdering` | `[0]` |  |
| CQ-027 | `U: [0] 0-0` | `triangleCount` | `#0` |  |
| CQ-028 | `U: [0] 0-0` | `clusteringCoefficients` | `[0.0]` |  |
| CQ-029 | `U: [0] 0-0` | `transitivity` | `#0.0` |  |
| CQ-030 | `U: [0] 0-0` | `averageClustering` | `#0.0` |  |
| CQ-031 | `U: [0, 1]` | `maximalCliques` | `[[0], [1]]` | Two isolated vertices |
| CQ-032 | `U: [0, 1]` | `maximumClique` | `[0]` |  |
| CQ-033 | `U: [0, 1]` | `cliqueNumber` | `#1` |  |
| CQ-034 | `U: [0, 1]` | `coreNumbers` | `[0, 0]` |  |
| CQ-035 | `U: [0, 1]` | `degeneracy` | `#0` |  |
| CQ-036 | `U: [0, 1]` | `degeneracyOrdering` | `[0, 1]` |  |
| CQ-037 | `U: [0, 1]` | `triangleCount` | `#0` |  |
| CQ-038 | `U: [0, 1]` | `clusteringCoefficients` | `[0.0, 0.0]` |  |
| CQ-039 | `U: [0, 1]` | `transitivity` | `#0.0` |  |
| CQ-040 | `U: [0, 1]` | `averageClustering` | `#0.0` |  |
| CQ-041 | `U: 0-1` | `maximalCliques` | `[[0, 1]]` | K₂ |
| CQ-042 | `U: 0-1` | `maximumClique` | `[0, 1]` |  |
| CQ-043 | `U: 0-1` | `cliqueNumber` | `#2` |  |
| CQ-044 | `U: 0-1` | `coreNumbers` | `[1, 1]` |  |
| CQ-045 | `U: 0-1` | `degeneracy` | `#1` |  |
| CQ-046 | `U: 0-1` | `degeneracyOrdering` | `[0, 1]` |  |
| CQ-047 | `U: 0-1` | `triangleCount` | `#0` |  |
| CQ-048 | `U: 0-1` | `clusteringCoefficients` | `[0.0, 0.0]` |  |
| CQ-049 | `U: 0-1` | `transitivity` | `#0.0` |  |
| CQ-050 | `U: 0-1` | `averageClustering` | `#0.0` |  |
| CQ-051 | `U: 0-1, 0-1, 1-0` | `maximalCliques` | `[[0, 1]]` | K₂ as three parallel edges: one edge in the simple graph |
| CQ-052 | `U: 0-1, 0-1, 1-0` | `maximumClique` | `[0, 1]` |  |
| CQ-053 | `U: 0-1, 0-1, 1-0` | `cliqueNumber` | `#2` |  |
| CQ-054 | `U: 0-1, 0-1, 1-0` | `coreNumbers` | `[1, 1]` |  |
| CQ-055 | `U: 0-1, 0-1, 1-0` | `degeneracy` | `#1` |  |
| CQ-056 | `U: 0-1, 0-1, 1-0` | `degeneracyOrdering` | `[0, 1]` |  |
| CQ-057 | `U: 0-1, 0-1, 1-0` | `triangleCount` | `#0` |  |
| CQ-058 | `U: 0-1, 0-1, 1-0` | `clusteringCoefficients` | `[0.0, 0.0]` |  |
| CQ-059 | `U: 0-1, 0-1, 1-0` | `transitivity` | `#0.0` |  |
| CQ-060 | `U: 0-1, 0-1, 1-0` | `averageClustering` | `#0.0` |  |
| CQ-061 | `U: []` | `kCore(0)` | `[]` |  |
| CQ-062 | `U: [0]` | `kCore(0)` | `[0]` | Every vertex is in the 0-core |
| CQ-063 | `U: [0]` | `kCore(1)` | `[]` |  |
| CQ-064 | `U: [0] 0-0` | `kCore(1)` | `[]` | A loop adds no degree (igraph: coreness 2, NetworkX raises) |
| CQ-065 | `U: [0, 1]` | `kShell(0)` | `[0, 1]` |  |
| CQ-066 | `U: [0]` | `triangleCount(of: 0)` | `#0` |  |
| CQ-067 | `U: [0]` | `clusteringCoefficient(of: 0)` | `#0.0` | Degree < 2: 0 (NetworkX, JGraphT, Boost; igraph NaN) |
| CQ-068 | `U: [0]` | `triangleCount(of: 1)` | `trap` | Not a vertex: precondition |
| CQ-069 | `U: [0]` | `kCore(-1)` | `trap` | Precondition k >= 0 |

## B. Maximal cliques

Each clique in `vertices` order; the sequence in the order of api.md (degeneracy ordering, Tomita pivot, least-index ties, branches ascending).

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| CQ-101 | `U: K(0..2), 2-3` | `maximalCliques` | `[[2, 3], [0, 1, 2]]` | Vertex 3 is first in the degeneracy ordering, so its clique comes first. NetworkX's `find_cliques` gives `[[2, 0, 1], [2, 3]]` (set order) |
| CQ-102 | `U: K(0..2), 2-3 ~rev` | `maximalCliques` | `[[2, 3], [0, 1, 2]]` | Rows reversed: same cliques, same order here |
| CQ-103 | `U: K(4)` | `maximalCliques` | `[[0, 1, 2, 3]]` |  |
| CQ-104 | `U: K(5)` | `maximalCliques` | `[[0, 1, 2, 3, 4]]` |  |
| CQ-105 | `U: C(0..3)` | `maximalCliques` | `[[0, 1], [0, 3], [1, 2], [2, 3]]` | C₄: four edges |
| CQ-106 | `U: C(0..4)` | `maximalCliques` | `[[0, 1], [0, 4], [1, 2], [2, 3], [3, 4]]` |  |
| CQ-107 | `U: P(0..4)` | `maximalCliques` | `[[0, 1], [3, 4], [1, 2], [2, 3]]` |  |
| CQ-108 | `U: S(0;1..4)` | `maximalCliques` | `[[0, 1], [0, 2], [0, 3], [0, 4]]` | Star: the centre first in no clique; each edge a clique |
| CQ-109 | `U: S(4;0..3)` | `maximalCliques` | `[[4, 0], [4, 1], [4, 2], [4, 3]]` | Centre last in `vertices` |
| CQ-110 | `U: K(0..2), K(2..4)` | `maximalCliques` | `[[0, 1, 2], [2, 3, 4]]` | Bowtie: two triangles sharing vertex 2 |
| CQ-111 | `U: K(0..2), 1-3, 2-3` | `maximalCliques` | `[[0, 1, 2], [1, 2, 3]]` | Diamond: K₄ less an edge |
| CQ-112 | `U: S(0;1..5), C(1..5)` | `maximalCliques` | `[[0, 1, 2], [0, 1, 5], [0, 2, 3], [0, 3, 4], [0, 4, 5]]` | Wheel W₆ |
| CQ-113 | `U: KB(0..2;3..5)` | `maximalCliques` | `[[0, 3], [0, 4], [0, 5], [3, 1], [3, 2], [4, 1], [4, 2], [5, 1], [5, 2]]` | K₃,₃: nine edges. `vertices` is 0, 3, 4, 5, 1, 2 (first appearance), so `[3, 1]` is in index order |
| CQ-114 | `U: moon(2)` | `maximalCliques` | `[[0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]]` | Moon–Moser with 2 parts is K₃,₃ again, but numbered by part: 3² = 9 cliques |
| CQ-115 | `U: [0, 1, 2] K(3..5)` | `maximalCliques` | `[[0], [1], [2], [3, 4, 5]]` | Isolated vertices are maximal cliques of one (NetworkX, igraph) |
| CQ-116 | `U: [0] 0-0, 1-1, 1-2` | `maximalCliques` | `[[0], [1, 2]]` | Self-loops ignored: [0] alone, [1, 2] |
| CQ-117 | `U: 0-1, 1-2, 2-0, 0-1, 2-2` | `maximalCliques` | `[[0, 1, 2]]` | Parallel and loop: one triangle |
| CQ-118 | `U: a-b, b-c, c-a, c-d, d-e, e-c` | `maximalCliques` | `[[a, b, c], [c, d, e]]` | Labels |
| CQ-119 | `U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c` | `maximalCliques` | `[[e, d, c], [c, b, a]]` | Labels, `vertices` reversed: each clique in `vertices` order |
| CQ-120 | `U: nx(petersen)` | `maximalCliques` | `[[0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8], [6, 8], [6, 9], [7, 9]]` | Triangle-free: the 15 edges |
| CQ-121 | `U: nx(karate_club)` | `maximalCliques` | `[[0, 11], [2, 9], [9, 33], [0, 3, 12], [14, 32, 33], [15, 32, 33], [5, 6, 16], [0, 1, 17], [18, 32, 33], [20, 32, 33], [0, 1, 21], [22, 32, 33], [26, 29, 33], [0, 4, 6], [0, 4, 10], [0, 5, 10], [0, 1, 19], [19, 33], [24, 25, 31], [24, 27], [23, 25], [2, 28], [28, 31, 33], [0, 5, 6], [23, 29, 32, 33], [2, 27], [23, 27, 33], [0, 31], [31, 32, 33], [1, 30], [8, 30, 32, 33], [0, 1, 2, 3, 7], [2, 8, 32], [13, 33], [0, 2, 8], [0, 1, 2, 3, 13]]` | 36 maximal cliques |
| CQ-122 | `U: K(0..3), K(3..6), 0-6` | `maximalCliques` | `[[0, 1, 2, 3], [3, 4, 5, 6], [0, 3, 6]]` |  |
| CQ-123 | `U: nx(karate_club)` | `maximalCliques.count` | `#36` | igraph `maximal_cliques`: 36 |
| CQ-124 | `U: moon(4)` | `maximalCliques.count` | `#81` | 3⁴ |

## C. Maximum clique and clique number

The lexicographically least largest clique, by vertex index.

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| CQ-201 | `U: K(0..2), K(3..5)` | `maximumClique` | `[0, 1, 2]` | Two triangles: the first |
| CQ-202 | `U: K(0..2), K(3..5)` | `cliqueNumber` | `#3` |  |
| CQ-203 | `U: [5, 4, 3, 2, 1, 0] K(0..2), K(3..5)` | `maximumClique` | `[5, 4, 3]` | `vertices` reversed: [5, 4, 3] has indices [0, 1, 2] |
| CQ-204 | `U: [5, 4, 3, 2, 1, 0] K(0..2), K(3..5)` | `cliqueNumber` | `#3` |  |
| CQ-205 | `U: K(3..5), K(0..2)` | `maximumClique` | `[3, 4, 5]` | Edge order does not matter |
| CQ-206 | `U: K(3..5), K(0..2)` | `cliqueNumber` | `#3` |  |
| CQ-207 | `U: [0, 1, 2]` | `maximumClique` | `[0]` | Edgeless: the first vertex (NetworkX `max_weight_clique(weight=None)`: `[2]`, the last) |
| CQ-208 | `U: [0, 1, 2]` | `cliqueNumber` | `#1` |  |
| CQ-209 | `U: KB(0..2;3..5)` | `maximumClique` | `[0, 3]` | Bipartite: an edge, the least |
| CQ-210 | `U: KB(0..2;3..5)` | `cliqueNumber` | `#2` |  |
| CQ-211 | `U: nx(karate_club)` | `maximumClique` | `[0, 1, 2, 3, 7]` | Two 5-cliques, [0, 1, 2, 3, 7] and [0, 1, 2, 3, 13] (igraph `largest_cliques`: both) |
| CQ-212 | `U: nx(karate_club)` | `cliqueNumber` | `#5` |  |
| CQ-213 | `U: S(0;1..5), C(1..5)` | `maximumClique` | `[0, 1, 2]` |  |
| CQ-214 | `U: S(0;1..5), C(1..5)` | `cliqueNumber` | `#3` |  |
| CQ-215 | `U: C(0..4), K(5..8)` | `maximumClique` | `[5, 6, 7, 8]` |  |
| CQ-216 | `U: C(0..4), K(5..8)` | `cliqueNumber` | `#4` |  |
| CQ-217 | `U: moon(3)` | `maximumClique` | `[0, 3, 6]` |  |
| CQ-218 | `U: moon(3)` | `cliqueNumber` | `#3` |  |
| CQ-219 | `U: P(0..3), 3-3, 3-3` | `maximumClique` | `[0, 1]` |  |
| CQ-220 | `U: P(0..3), 3-3, 3-3` | `cliqueNumber` | `#2` |  |

## D. Core numbers and degeneracy

Cores of the simple graph: loops and parallel copies add nothing.

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| CQ-301 | `U: K(0..2), 2-3` | `coreNumbers` | `[2, 2, 2, 1]` |  |
| CQ-302 | `U: K(0..2), 2-3` | `degeneracy` | `#2` |  |
| CQ-303 | `U: K(0..2), 2-3` | `degeneracyOrdering` | `[3, 0, 1, 2]` |  |
| CQ-304 | `U: P(0..4)` | `coreNumbers` | `[1, 1, 1, 1, 1]` |  |
| CQ-305 | `U: P(0..4)` | `degeneracy` | `#1` |  |
| CQ-306 | `U: P(0..4)` | `degeneracyOrdering` | `[0, 4, 1, 3, 2]` |  |
| CQ-307 | `U: C(0..4)` | `coreNumbers` | `[2, 2, 2, 2, 2]` |  |
| CQ-308 | `U: C(0..4)` | `degeneracy` | `#2` |  |
| CQ-309 | `U: C(0..4)` | `degeneracyOrdering` | `[0, 1, 2, 3, 4]` |  |
| CQ-310 | `U: S(0;1..4)` | `coreNumbers` | `[1, 1, 1, 1, 1]` |  |
| CQ-311 | `U: S(0;1..4)` | `degeneracy` | `#1` |  |
| CQ-312 | `U: S(0;1..4)` | `degeneracyOrdering` | `[1, 2, 3, 4, 0]` |  |
| CQ-313 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `coreNumbers` | `[3, 3, 3, 3, 2, 2, 2]` | K₄ with a pendant triangle |
| CQ-314 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `degeneracy` | `#3` |  |
| CQ-315 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `degeneracyOrdering` | `[5, 6, 4, 1, 2, 0, 3]` |  |
| CQ-316 | `U: K(0..2), 1-3, 2-3` | `coreNumbers` | `[2, 2, 2, 2]` | Diamond |
| CQ-317 | `U: K(0..2), 1-3, 2-3` | `degeneracy` | `#2` |  |
| CQ-318 | `U: K(0..2), 1-3, 2-3` | `degeneracyOrdering` | `[0, 3, 1, 2]` |  |
| CQ-319 | `U: nx(karate_club)` | `coreNumbers` | `[4, 4, 4, 4, 3, 3, 3, 4, 4, 2, 3, 1, 2, 4, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 2, 3, 3, 3, 4, 3, 4, 4]` | Degeneracy 4 (NetworkX, igraph) |
| CQ-320 | `U: nx(karate_club)` | `degeneracy` | `#4` |  |
| CQ-321 | `U: nx(karate_club)` | `degeneracyOrdering` | `[11, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 4, 10, 19, 24, 25, 28, 5, 6, 29, 27, 31, 23, 30, 7, 32, 33, 8, 1, 3, 13, 0, 2]` |  |
| CQ-322 | `U: nx(petersen)` | `coreNumbers` | `[3, 3, 3, 3, 3, 3, 3, 3, 3, 3]` | 3-regular |
| CQ-323 | `U: nx(petersen)` | `degeneracy` | `#3` |  |
| CQ-324 | `U: nx(petersen)` | `degeneracyOrdering` | `[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]` |  |
| CQ-325 | `U: grid(3,4)` | `coreNumbers` | `[2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]` |  |
| CQ-326 | `U: grid(3,4)` | `degeneracy` | `#2` |  |
| CQ-327 | `U: grid(3,4)` | `degeneracyOrdering` | `[0, 3, 8, 11, 1, 4, 2, 7, 9, 10, 5, 6]` |  |
| CQ-328 | `U: [0, 1] 0-1, 0-1` | `coreNumbers` | `[1, 1]` | Parallel pair: core 1 (igraph `coreness`: 2) |
| CQ-329 | `U: [0, 1] 0-1, 0-1` | `degeneracy` | `#1` |  |
| CQ-330 | `U: [0, 1] 0-1, 0-1` | `degeneracyOrdering` | `[0, 1]` |  |
| CQ-331 | `U: [0, 1] 0-1, 0-0, 1-1` | `coreNumbers` | `[1, 1]` | Loops: core 1 (igraph: 3; NetworkX raises) |
| CQ-332 | `U: [0, 1] 0-1, 0-0, 1-1` | `degeneracy` | `#1` |  |
| CQ-333 | `U: [0, 1] 0-1, 0-0, 1-1` | `degeneracyOrdering` | `[0, 1]` |  |
| CQ-334 | `U: S(0;1..4) ~rev` | `coreNumbers` | `[1, 1, 1, 1, 1]` |  |
| CQ-335 | `U: S(0;1..4) ~rev` | `degeneracy` | `#1` |  |
| CQ-336 | `U: S(0;1..4) ~rev` | `degeneracyOrdering` | `[1, 2, 3, 4, 0]` |  |
| CQ-337 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kCore(0)` | `[0, 1, 2, 3, 4, 5, 6]` |  |
| CQ-338 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kCore(1)` | `[0, 1, 2, 3, 4, 5, 6]` |  |
| CQ-339 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kCore(2)` | `[0, 1, 2, 3, 4, 5, 6]` |  |
| CQ-340 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kCore(3)` | `[0, 1, 2, 3]` |  |
| CQ-341 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kCore(4)` | `[]` |  |
| CQ-342 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kCore(5)` | `[]` |  |
| CQ-343 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kShell(0)` | `[]` |  |
| CQ-344 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kShell(1)` | `[]` |  |
| CQ-345 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kShell(2)` | `[4, 5, 6]` |  |
| CQ-346 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kShell(3)` | `[0, 1, 2, 3]` |  |
| CQ-347 | `U: K(4), 3-4, 4-5, 5-6, 6-4` | `kShell(4)` | `[]` |  |
| CQ-348 | `U: nx(karate_club)` | `kCore(4)` | `[0, 1, 2, 3, 7, 8, 13, 30, 32, 33]` | The main core |
| CQ-349 | `U: nx(karate_club)` | `kShell(1)` | `[11]` |  |

## E. Triangles and clustering

Triangles of the simple graph; clustering 2T/(d(d−1)) with d the simple degree, 0 when d < 2; transitivity 3·triangles / connected triples, 0 with no triples; average over every vertex, zeros included.

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| CQ-401 | `U: K(0..2), 2-3` | `triangleCount` | `#1` | NetworkX doc: transitivity 0.6 (also igraph 0.6000000000000001) |
| CQ-402 | `U: K(0..2), 2-3` | `triangleCounts` | `[1, 1, 1, 0]` |  |
| CQ-403 | `U: K(0..2), 2-3` | `clusteringCoefficients` | `[1.0, 1.0, 0.3333333333333333, 0.0]` |  |
| CQ-404 | `U: K(0..2), 2-3` | `transitivity` | `#0.6` |  |
| CQ-405 | `U: K(0..2), 2-3` | `averageClustering` | `#0.5833333333333334` | igraph `transitivity_avglocal_undirected`: 0.5833333333333334 with `mode="zero"`, 0.7777777777777778 by default (degree < 2 left out) |
| CQ-406 | `U: K(5)` | `triangleCount` | `#10` | NetworkX docstring: 10 triangles, 6 per vertex |
| CQ-407 | `U: K(5)` | `triangleCounts` | `[6, 6, 6, 6, 6]` |  |
| CQ-408 | `U: K(5)` | `clusteringCoefficients` | `[1.0, 1.0, 1.0, 1.0, 1.0]` |  |
| CQ-409 | `U: K(5)` | `transitivity` | `#1.0` |  |
| CQ-410 | `U: K(5)` | `averageClustering` | `#1.0` |  |
| CQ-411 | `U: K(0..2), K(2..4)` | `triangleCount` | `#2` | Bowtie |
| CQ-412 | `U: K(0..2), K(2..4)` | `triangleCounts` | `[1, 1, 2, 1, 1]` |  |
| CQ-413 | `U: K(0..2), K(2..4)` | `clusteringCoefficients` | `[1.0, 1.0, 0.3333333333333333, 1.0, 1.0]` |  |
| CQ-414 | `U: K(0..2), K(2..4)` | `transitivity` | `#0.6` |  |
| CQ-415 | `U: K(0..2), K(2..4)` | `averageClustering` | `#0.8666666666666668` |  |
| CQ-416 | `U: K(0..2), 1-3, 2-3` | `triangleCount` | `#2` | Diamond |
| CQ-417 | `U: K(0..2), 1-3, 2-3` | `triangleCounts` | `[1, 2, 2, 1]` |  |
| CQ-418 | `U: K(0..2), 1-3, 2-3` | `clusteringCoefficients` | `[1.0, 0.6666666666666666, 0.6666666666666666, 1.0]` |  |
| CQ-419 | `U: K(0..2), 1-3, 2-3` | `transitivity` | `#0.75` |  |
| CQ-420 | `U: K(0..2), 1-3, 2-3` | `averageClustering` | `#0.8333333333333333` |  |
| CQ-421 | `U: S(0;1..5), C(1..5)` | `triangleCount` | `#5` | Wheel |
| CQ-422 | `U: S(0;1..5), C(1..5)` | `triangleCounts` | `[5, 2, 2, 2, 2, 2]` |  |
| CQ-423 | `U: S(0;1..5), C(1..5)` | `clusteringCoefficients` | `[0.5, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666, 0.6666666666666666]` |  |
| CQ-424 | `U: S(0;1..5), C(1..5)` | `transitivity` | `#0.6` |  |
| CQ-425 | `U: S(0;1..5), C(1..5)` | `averageClustering` | `#0.6388888888888887` |  |
| CQ-426 | `U: C(0..3)` | `triangleCount` | `#0` | Square: no triangle |
| CQ-427 | `U: C(0..3)` | `triangleCounts` | `[0, 0, 0, 0]` |  |
| CQ-428 | `U: C(0..3)` | `clusteringCoefficients` | `[0.0, 0.0, 0.0, 0.0]` |  |
| CQ-429 | `U: C(0..3)` | `transitivity` | `#0.0` |  |
| CQ-430 | `U: C(0..3)` | `averageClustering` | `#0.0` |  |
| CQ-431 | `U: nx(petersen)` | `triangleCount` | `#0` | Girth 5 |
| CQ-432 | `U: nx(petersen)` | `triangleCounts` | `[0, 0, 0, 0, 0, 0, 0, 0, 0, 0]` |  |
| CQ-433 | `U: nx(petersen)` | `clusteringCoefficients` | `[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]` |  |
| CQ-434 | `U: nx(petersen)` | `transitivity` | `#0.0` |  |
| CQ-435 | `U: nx(petersen)` | `averageClustering` | `#0.0` |  |
| CQ-436 | `U: nx(karate_club)` | `triangleCount` | `#45` |  |
| CQ-437 | `U: nx(karate_club)` | `triangleCounts` | `[18, 12, 11, 10, 2, 3, 3, 6, 5, 0, 2, 0, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 4, 3, 3, 13, 15]` |  |
| CQ-438 | `U: nx(karate_club)` | `clusteringCoefficients` | `[0.15, 0.3333333333333333, 0.24444444444444444, 0.6666666666666666, 0.6666666666666666, 0.5, 0.5, 1.0, 0.5, 0.0, 0.6666666666666666, 0.0, 1.0, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0, 0.3333333333333333, 1.0, 1.0, 1.0, 0.4, 0.3333333333333333, 0.3333333333333333, 1.0, 0.16666666666666666, 0.3333333333333333, 0.6666666666666666, 0.5, 0.2, 0.19696969696969696, 0.11029411764705882]` |  |
| CQ-439 | `U: nx(karate_club)` | `transitivity` | `#0.2556818181818182` | igraph `transitivity_undirected`: the same |
| CQ-440 | `U: nx(karate_club)` | `averageClustering` | `#0.5706384782076823` | igraph: the same with `mode="zero"`, 0.5879305533048848 by default |
| CQ-441 | `U: 0-1, 1-2, 2-0, 0-1, 1-1` | `triangleCount` | `#1` | Parallel edge and loop: as the triangle (JGraphT `getNumberOfTriangles`: 2) |
| CQ-442 | `U: 0-1, 1-2, 2-0, 0-1, 1-1` | `triangleCounts` | `[1, 1, 1]` |  |
| CQ-443 | `U: 0-1, 1-2, 2-0, 0-1, 1-1` | `clusteringCoefficients` | `[1.0, 1.0, 1.0]` |  |
| CQ-444 | `U: 0-1, 1-2, 2-0, 0-1, 1-1` | `transitivity` | `#1.0` |  |
| CQ-445 | `U: 0-1, 1-2, 2-0, 0-1, 1-1` | `averageClustering` | `#1.0` |  |
| CQ-446 | `U: [0, 1, 2, 3]` | `triangleCount` | `#0` | Edgeless |
| CQ-447 | `U: [0, 1, 2, 3]` | `triangleCounts` | `[0, 0, 0, 0]` |  |
| CQ-448 | `U: [0, 1, 2, 3]` | `clusteringCoefficients` | `[0.0, 0.0, 0.0, 0.0]` |  |
| CQ-449 | `U: [0, 1, 2, 3]` | `transitivity` | `#0.0` |  |
| CQ-450 | `U: [0, 1, 2, 3]` | `averageClustering` | `#0.0` |  |
| CQ-451 | `U: P(0..2)` | `triangleCount` | `#0` | No triangle: transitivity 0/1 |
| CQ-452 | `U: P(0..2)` | `triangleCounts` | `[0, 0, 0]` |  |
| CQ-453 | `U: P(0..2)` | `clusteringCoefficients` | `[0.0, 0.0, 0.0]` |  |
| CQ-454 | `U: P(0..2)` | `transitivity` | `#0.0` |  |
| CQ-455 | `U: P(0..2)` | `averageClustering` | `#0.0` |  |
| CQ-456 | `U: [0, 1] 0-1, 2-3` | `triangleCount` | `#0` | No connected triple: transitivity 0 (0/0; NetworkX 0, igraph NaN) |
| CQ-457 | `U: [0, 1] 0-1, 2-3` | `triangleCounts` | `[0, 0, 0, 0]` |  |
| CQ-458 | `U: [0, 1] 0-1, 2-3` | `clusteringCoefficients` | `[0.0, 0.0, 0.0, 0.0]` |  |
| CQ-459 | `U: [0, 1] 0-1, 2-3` | `transitivity` | `#0.0` |  |
| CQ-460 | `U: [0, 1] 0-1, 2-3` | `averageClustering` | `#0.0` |  |
| CQ-461 | `U: K(0..2), 2-3` | `triangleCount(of: 2)` | `#1` |  |
| CQ-462 | `U: K(0..2), 2-3` | `clusteringCoefficient(of: 2)` | `#0.3333333333333333` |  |
| CQ-463 | `U: K(0..2), 2-3` | `clusteringCoefficient(of: 3)` | `#0.0` | Degree 1 |
| CQ-464 | `U: nx(karate_club)` | `clusteringCoefficient(of: 0)` | `#0.15` |  |
| CQ-465 | `U: nx(karate_club)` | `triangleCount(of: 33)` | `#15` |  |
| CQ-466 | `U: K(0..2), 2-3` | `clusteringCoefficient(of: 9)` | `trap` | Not a vertex: precondition |

## F. Directed graphs through `undirected`

`digraph.undirected` keeps opposite arcs as parallel edges; the simple graph collapses them, giving igraph's "directions ignored" values.

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| CQ-501 | `D: 0>1, 1>0, 1>2, 2>0` | `undirected > maximalCliques` | `[[0, 1, 2]]` | Reciprocal pair collapses (NetworkX `core_number` on the DiGraph: in + out degree) |
| CQ-502 | `D: 0>1, 1>0, 1>2, 2>0` | `undirected > coreNumbers` | `[2, 2, 2]` |  |
| CQ-503 | `D: 0>1, 1>0, 1>2, 2>0` | `undirected > triangleCounts` | `[1, 1, 1]` |  |
| CQ-504 | `D: 0>1, 1>0, 1>2, 2>0` | `undirected > clusteringCoefficients` | `[1.0, 1.0, 1.0]` |  |
| CQ-505 | `D: 0>1, 1>0, 1>2, 2>0` | `undirected > transitivity` | `#1.0` |  |
| CQ-506 | `D: C(0..2), C(2..0)` | `undirected > maximalCliques` | `[[0, 1, 2]]` | Both orientations: one triangle |
| CQ-507 | `D: C(0..2), C(2..0)` | `undirected > coreNumbers` | `[2, 2, 2]` |  |
| CQ-508 | `D: C(0..2), C(2..0)` | `undirected > triangleCounts` | `[1, 1, 1]` |  |
| CQ-509 | `D: C(0..2), C(2..0)` | `undirected > clusteringCoefficients` | `[1.0, 1.0, 1.0]` |  |
| CQ-510 | `D: C(0..2), C(2..0)` | `undirected > transitivity` | `#1.0` |  |
| CQ-511 | `D: 0>1, 1>2, 0>2, 2>3, 3>2` | `undirected > maximalCliques` | `[[2, 3], [0, 1, 2]]` |  |
| CQ-512 | `D: 0>1, 1>2, 0>2, 2>3, 3>2` | `undirected > coreNumbers` | `[2, 2, 2, 1]` |  |
| CQ-513 | `D: 0>1, 1>2, 0>2, 2>3, 3>2` | `undirected > triangleCounts` | `[1, 1, 1, 0]` |  |
| CQ-514 | `D: 0>1, 1>2, 0>2, 2>3, 3>2` | `undirected > clusteringCoefficients` | `[1.0, 1.0, 0.3333333333333333, 0.0]` |  |
| CQ-515 | `D: 0>1, 1>2, 0>2, 2>3, 3>2` | `undirected > transitivity` | `#0.6` |  |

## G. Large shapes

Recursion-free and linear where api.md says so; values from the same model.

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| CQ-601 | `U: P(0..99999)` | `maximalCliques.count` | `#99999` |  |
| CQ-602 | `U: P(0..99999)` | `degeneracy` | `#1` |  |
| CQ-603 | `U: P(0..99999)` | `triangleCount` | `#0` |  |
| CQ-604 | `U: P(0..99999)` | `transitivity` | `#0.0` |  |
| CQ-605 | `U: P(0..99999)` | `averageClustering` | `#0.0` |  |
| CQ-606 | `U: P(0..99999)` | `cliqueNumber` | `#2` |  |
| CQ-607 | `U: S(0;1..99999)` | `maximalCliques.count` | `#99999` |  |
| CQ-608 | `U: S(0;1..99999)` | `degeneracy` | `#1` |  |
| CQ-609 | `U: S(0;1..99999)` | `triangleCount` | `#0` |  |
| CQ-610 | `U: S(0;1..99999)` | `transitivity` | `#0.0` |  |
| CQ-611 | `U: S(0;1..99999)` | `cliqueNumber` | `#2` |  |
| CQ-612 | `U: grid(300,300)` | `maximalCliques.count` | `#179400` |  |
| CQ-613 | `U: grid(300,300)` | `degeneracy` | `#2` |  |
| CQ-614 | `U: grid(300,300)` | `triangleCount` | `#0` |  |
| CQ-615 | `U: K(120)` | `maximalCliques.count` | `#1` |  |
| CQ-616 | `U: K(120)` | `cliqueNumber` | `#120` |  |
| CQ-617 | `U: K(120)` | `degeneracy` | `#119` |  |
| CQ-618 | `U: K(120)` | `triangleCount` | `#280840` |  |
| CQ-619 | `U: K(120)` | `transitivity` | `#1.0` |  |
| CQ-620 | `U: K(120)` | `averageClustering` | `#1.0` |  |
| CQ-621 | `U: moon(8)` | `maximalCliques.count` | `#6561` |  |
| CQ-622 | `U: moon(8)` | `cliqueNumber` | `#8` |  |
| CQ-623 | `U: moon(8)` | `maximumClique` | `[0, 3, 6, 9, 12, 15, 18, 21]` |  |
| CQ-624 | `U: moon(8)` | `degeneracy` | `#21` |  |
| CQ-625 | `U: moon(8)` | `triangleCount` | `#1512` |  |
| CQ-626 | `U: moon(8)` | `transitivity` | `#0.9` |  |
| CQ-627 | `U: lcg(2000,20000,7)` | `maximalCliques.count` | `#17618` |  |
| CQ-628 | `U: lcg(2000,20000,7)` | `cliqueNumber` | `#3` |  |
| CQ-629 | `U: lcg(2000,20000,7)` | `maximumClique` | `[0, 164, 284]` |  |
| CQ-630 | `U: lcg(2000,20000,7)` | `degeneracy` | `#14` |  |
| CQ-631 | `U: lcg(2000,20000,7)` | `triangleCount` | `#1315` |  |
| CQ-632 | `U: lcg(2000,20000,7)` | `transitivity` | `#0.009915274046110423` |  |
| CQ-633 | `U: lcg(2000,20000,7)` | `averageClustering` | `#0.00983522597322751` |  |
