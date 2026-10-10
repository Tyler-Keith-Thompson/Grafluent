# Distances: case catalog (DI-001 – DI-915)

Cases for the Distances module (api.md): `eccentricities()` and the `Eccentricities` value,
`eccentricity(of:)`, `radius()`, `diameter()`, `center()`, `periphery()`, `diameterPath()`,
`centroid()`, `wienerIndex()`, `averageShortestPathLength()` and `density`, on `Graph` and
`DirectedGraph`, unweighted and weighted. Harvested from NetworkX 3.7
(`algorithms/tests/test_distance_measures.py`, the `center` / `centroid` / `density` /
`wiener_index` docstrings), igraph 1.0 (`igraph_probe.py` here, run against python-igraph 1.0.0),
JGraphT `GraphMeasurer` (source read for its conventions), the TreeAlgorithms catalog (every tree
case whose Notes say `= TA-nnn` must give that row's value, which `ref.py` checks), and the edge
cases api.md calls out. Every Expected cell is recomputed by `ref.py` and cross-checked against
brute-force Floyd–Warshall, NetworkX 3.7 and scipy 1.18.1 (see its docstring).

## Notation

**Graph** (read by `ref.py`): `U:` undirected, `D:` directed. An optional vertex list in brackets
comes first, then edges in **position order** (position k is the kth edge written). `vertices` is
the listed vertices, then vertices from generators, then endpoints by first appearance (as
`ReferencePseudograph(vertices:edges:)` / `ReferenceDirectedMultigraph`). Rows (`incidentEdges`,
`outEdges`) are in position order, an undirected self-loop twice, unless `~rev`.

| Token | Edges |
|---|---|
| `u-v`, `u>v` | one edge, or one arc (in a `D:` graph `-` also writes an arc) |
| `P(a,b,…)`, `C(a,b,…,z)` | the path a–b, b–c, …; the cycle a–b, …, z–a (arcs in a `D:` graph) |
| `S(c;a..b)` | the star c–a, …, c–b |
| `K(n)`, `K(a..b)` | every pair i < j, lexicographic (in a `D:` graph: arcs i>j, the acyclic tournament) |
| `KB(a..b;c..d)` | each of the first list to each of the second, row-major |
| `grid(r,c)` | vertices `i*c + j` listed row-major; for each vertex in that order the edge right, then down |
| `kary(n,k)` | vertex i to k·i+1 … k·i+k below n (igraph `kary_tree`) |
| `lcg(n,m,s)` | m pairs over 0..<n from the 64-bit LCG x ← x·6364136223846793005 + 1442695040888963407 (wrapping), seeded x = s: u = (x' >> 33) mod n, then v the same from the next step; a pair with u = v is drawn again |
| `nx(name)` | `networkx.<name>_graph()`: its `nodes` listed, then `edges()` in NetworkX's order |
| `a..b` | every integer from a to b inclusive |
| `~rev` | at the end: every row reversed (a private conformer whose `incidentEdges` order is not position order) |

**Op**: the API call. `weight: [w0, w1, …]` is `{ w[$0] }` by edge position (`weight: k`: every edge
weighs k; `weight: e%k+c`: edge e weighs e mod k + c); a list with a `.` is `Double`, otherwise `Int`.
`directed > op` runs op on `graph.directed` (each edge two arcs), `undirected > op` on
`digraph.undirected` (each arc an edge). `eccentricities` is the `Eccentricities` value read in
`vertices` order (`eccentricity(ofIndex: i)` for each i); the one-shot calls (`radius`, `diameter`,
`center`, `periphery`) must equal the same members of `eccentricities()`, which the Swift tests
should assert for every case.

**Expected**: `#k` a number (`#1.5`, `#inf` for `Double`); `nil`; `[a, b, …]` vertices in order;
for `eccentricities`, numbers or `nil` per vertex in `vertices` order; `[vertices]/[edge positions]`
a path, `… #d` with the weighted distance; `trap` a precondition failure.

## A. Degenerate graphs

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| DI-001 | `U: []` | `eccentricities` | `[]` | Empty graph: no vertices. NetworkX raises `NetworkXPointlessConcept` for every measure here; igraph gives NaN; JGraphT 0 and 0 |
| DI-002 | `U: []` | `radius` | `nil` | |
| DI-003 | `U: []` | `diameter` | `nil` | |
| DI-004 | `U: []` | `center` | `[]` | |
| DI-005 | `U: []` | `periphery` | `[]` | |
| DI-006 | `U: []` | `diameterPath` | `nil` | |
| DI-007 | `U: []` | `centroid` | `[]` | |
| DI-008 | `U: []` | `wienerIndex` | `#0` | The empty sum (NetworkX raises: connectivity of the null graph is undefined) |
| DI-009 | `U: []` | `averageShortestPathLength` | `nil` | No pairs (NetworkX raises) |
| DI-010 | `U: []` | `density` | `#0.0` | NetworkX 0; igraph NaN |
| DI-011 | `D: []` | `diameter` | `nil` | |
| DI-012 | `D: []` | `density` | `#0.0` | |
| DI-013 | `U: [0]` | `eccentricities` | `[0]` | K₁ |
| DI-014 | `U: [0]` | `radius` | `#0` | |
| DI-015 | `U: [0]` | `diameter` | `#0` | = TA-601 |
| DI-016 | `U: [0]` | `center` | `[0]` | = TA-401 |
| DI-017 | `U: [0]` | `periphery` | `[0]` | |
| DI-018 | `U: [0]` | `diameterPath` | `[0]/[]` | = TA-602 |
| DI-019 | `U: [0]` | `centroid` | `[0]` | = TA-501 |
| DI-020 | `U: [0]` | `wienerIndex` | `#0` | |
| DI-021 | `U: [0]` | `averageShortestPathLength` | `#0.0` | NetworkX returns 0 for one vertex; igraph NaN |
| DI-022 | `U: [0]` | `density` | `#0.0` | NetworkX 0; igraph NaN |
| DI-023 | `U: [0]` | `center(weight: [])` | `[0]` | = TA-423: K₁ weighted, the closure is never called |
| DI-024 | `U: [0]` | `diameterPath(weight: [])` | `[0]/[] #0` | = TA-622 |
| DI-025 | `U: [0, 1]` | `eccentricities` | `[nil, nil]` | Two isolated vertices: every eccentricity infinite |
| DI-026 | `U: [0, 1]` | `radius` | `nil` | |
| DI-027 | `U: [0, 1]` | `diameter` | `nil` | |
| DI-028 | `U: [0, 1]` | `center` | `[0, 1]` | Every eccentricity equals the (infinite) radius: every vertex, as JGraphT and scipy's infinities give |
| DI-029 | `U: [0, 1]` | `periphery` | `[0, 1]` | |
| DI-030 | `U: [0, 1]` | `diameterPath` | `nil` | |
| DI-031 | `U: [0, 1]` | `centroid` | `[0, 1]` | |
| DI-032 | `U: [0, 1]` | `wienerIndex` | `nil` | NetworkX `inf` |
| DI-033 | `U: [0, 1]` | `averageShortestPathLength` | `nil` | NetworkX raises |
| DI-034 | `U: [0, 1]` | `density` | `#0.0` | |
| DI-035 | `U: [] 0-1` | `eccentricities` | `[1, 1]` | |
| DI-036 | `U: [] 0-1` | `diameterPath` | `[0, 1]/[0]` | = TA-603 |
| DI-037 | `U: [] 1-0` | `diameterPath` | `[1, 0]/[0]` | = TA-604: `vertices` = [1, 0], so the path starts at 1 |
| DI-038 | `U: [] 0-1` | `density` | `#1.0` | |
| DI-039 | `U: [] 0-0` | `eccentricities` | `[0]` | One vertex with a loop |
| DI-040 | `U: [] 0-0` | `density` | `#0.0` | n ≤ 1 gives 0 whatever the loops (NetworkX) |
| DI-041 | `U: [] 0-0` | `diameterPath` | `[0]/[]` | The loop is never on a path |
| DI-042 | `U: [0]` | `eccentricity(of: 1)` | `trap` | Not a vertex |
| DI-043 | `U: [0]` | `eccentricity(of: 0)` | `#0` | |

## B. Undirected, unweighted

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| DI-101 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `eccentricities` | `[2, 3, 2, 2, 3]` | NetworkX's docstring graph |
| DI-102 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `center` | `[1, 3, 4]` | NetworkX docstring `[1, 3, 4]` |
| DI-103 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `periphery` | `[2, 5]` | NetworkX docstring `[2, 5]` |
| DI-104 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `radius` | `#2` | |
| DI-105 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `diameter` | `#3` | |
| DI-106 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `centroid` | `[1, 3, 4]` | NetworkX 3.7 `centroid` docstring `[1, 3, 4]` |
| DI-107 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `wienerIndex` | `#15` | |
| DI-108 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `averageShortestPathLength` | `#1.5` | |
| DI-109 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `density` | `#0.6` | |
| DI-110 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `diameterPath` | `[2, 1, 3, 5]/[0, 1, 4]` | From 2, the first peripheral vertex, to 5 |
| DI-111 | `U: [] grid(4,4)` | `eccentricities` | `[6, 5, 5, 6, 5, 4, 4, 5, 5, 4, 4, 5, 6, 5, 5, 6]` | NetworkX `test_distance_measures` grid (its labels are ours + 1) |
| DI-112 | `U: [] grid(4,4)` | `diameter` | `#6` | NetworkX 6 |
| DI-113 | `U: [] grid(4,4)` | `radius` | `#4` | NetworkX 4 |
| DI-114 | `U: [] grid(4,4)` | `center` | `[5, 6, 9, 10]` | NetworkX `[6, 7, 10, 11]` |
| DI-115 | `U: [] grid(4,4)` | `periphery` | `[0, 3, 12, 15]` | NetworkX `[1, 4, 13, 16]` |
| DI-116 | `U: [] grid(4,4)` | `diameterPath` | `[0, 1, 2, 3, 7, 11, 15]/[0, 2, 4, 6, 13, 20]` | 0 to 15: breadth-first parents go right before down |
| DI-117 | `U: [] grid(4,4)` | `eccentricity(of: 5)` | `#4` | NetworkX `eccentricity(G, 6)` = 4 |
| DI-118 | `U: [] grid(4,4)` | `centroid` | `[5, 6, 9, 10]` | |
| DI-120 | `U: [] C(0..4)` | `eccentricities` | `[2, 2, 2, 2, 2]` | |
| DI-121 | `U: [] C(0..4)` | `center` | `[0, 1, 2, 3, 4]` | Vertex-transitive: everything |
| DI-122 | `U: [] C(0..4)` | `periphery` | `[0, 1, 2, 3, 4]` | |
| DI-123 | `U: [] C(0..4)` | `diameterPath` | `[0, 1, 2]/[0, 1]` | |
| DI-124 | `U: [] C(0..5)` | `diameterPath` | `[0, 1, 2, 3]/[0, 1, 2]` | Two shortest 0–3 paths: the breadth-first one (via 1) |
| DI-125 | `U: [] C(0..4)` | `averageShortestPathLength` | `#1.5` | igraph 1.5 |
| DI-126 | `U: [] K(5)` | `eccentricities` | `[1, 1, 1, 1, 1]` | |
| DI-127 | `U: [] K(5)` | `diameterPath` | `[0, 1]/[0]` | |
| DI-128 | `U: [] K(5)` | `density` | `#1.0` | |
| DI-129 | `U: [] K(5)` | `wienerIndex` | `#10` | C(5, 2) |
| DI-130 | `U: [] K(5)` | `averageShortestPathLength` | `#1.0` | |
| DI-131 | `U: [] KB(0..2;3..6)` | `eccentricities` | `[2, 2, 2, 2, 2, 2, 2]` | K₃,₄ |
| DI-132 | `U: [] KB(0..2;3..6)` | `diameterPath` | `[0, 3, 1]/[0, 4]` | 0 to 1 through 3 |
| DI-133 | `U: [] KB(0..2;3..6)` | `centroid` | `[0, 1, 2]` | The smaller side has the smaller total: 4·1 + 2·2 = 8 against 3·1 + 3·2 = 9 |
| DI-134 | `U: [] nx(petersen)` | `eccentricities` | `[2, 2, 2, 2, 2, 2, 2, 2, 2, 2]` | |
| DI-135 | `U: [] nx(petersen)` | `wienerIndex` | `#75` | |
| DI-136 | `U: [] nx(petersen)` | `averageShortestPathLength` | `#1.6666666666666667` | |
| DI-137 | `U: [] nx(petersen)` | `density` | `#0.3333333333333333` | |
| DI-138 | `U: [] nx(karate_club)` | `eccentricities` | `[3, 3, 3, 3, 4, 4, 4, 4, 3, 4, 4, 4, 4, 3, 5, 5, 5, 4, 5, 3, 5, 4, 5, 5, 4, 4, 5, 4, 4, 5, 4, 3, 4, 4]` | Zachary's karate club |
| DI-139 | `U: [] nx(karate_club)` | `diameter` | `#5` | |
| DI-140 | `U: [] nx(karate_club)` | `radius` | `#3` | |
| DI-141 | `U: [] nx(karate_club)` | `center` | `[0, 1, 2, 3, 8, 13, 19, 31]` | |
| DI-142 | `U: [] nx(karate_club)` | `periphery` | `[14, 15, 16, 18, 20, 22, 23, 26, 29]` | |
| DI-143 | `U: [] nx(karate_club)` | `centroid` | `[0]` | |
| DI-144 | `U: [] nx(karate_club)` | `wienerIndex` | `#1351` | |
| DI-145 | `U: [] nx(karate_club)` | `averageShortestPathLength` | `#2.408199643493761` | |
| DI-146 | `U: [] nx(karate_club)` | `density` | `#0.13903743315508021` | |
| DI-147 | `U: [] nx(karate_club)` | `diameterPath` | `[14, 32, 2, 0, 5, 16]/[46, 31, 1, 4, 39]` | |
| DI-150 | `U: [] C(0..2), P(2,3,4), C(4..6)` | `eccentricities` | `[4, 4, 3, 2, 3, 4, 4]` | Two triangles joined by a path |
| DI-151 | `U: [] C(0..2), P(2,3,4), C(4..6)` | `center` | `[3]` | |
| DI-152 | `U: [] C(0..2), P(2,3,4), C(4..6)` | `periphery` | `[0, 1, 5, 6]` | |
| DI-153 | `U: [] C(0..2), P(2,3,4), C(4..6)` | `diameterPath` | `[0, 2, 3, 4, 5]/[2, 3, 4, 5]` | |
| DI-154 | `U: [] P(0..29), lcg(30,12,7)` | `eccentricities` | `[8, 7, 6, 5, 4, 5, 6, 7, 7, 6, 7, 7, 7, 6, 7, 6, 5, 6, 5, 5, 6, 6, 5, 5, 5, 6, 7, 8, 8, 7]` | A path plus 12 chords |
| DI-155 | `U: [] P(0..29), lcg(30,12,7)` | `center` | `[4]` | |
| DI-156 | `U: [] P(0..29), lcg(30,12,7)` | `periphery` | `[0, 27, 28]` | |
| DI-157 | `U: [] P(0..29), lcg(30,12,7)` | `diameterPath` | `[0, 1, 2, 3, 4, 24, 25, 26, 27]/[0, 1, 2, 3, 32, 24, 25, 26]` | |
| DI-158 | `U: [] P(0..29), lcg(30,12,7)` | `wienerIndex` | `#1532` | |

## C. Trees: agreement with TreeAlgorithms, and tie order

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| DI-201 | `U: [4, 2, 7, 1] 7-2, 2-4, 4-1` | `center` | `[4, 2]` | = TA-412: `vertices` order, not value order |
| DI-202 | `U: [4, 2, 7, 1] 7-2, 2-4, 4-1` | `periphery` | `[7, 1]` | `vertices` order |
| DI-203 | `U: [4, 2, 7, 1] 7-2, 2-4, 4-1` | `centroid` | `[4, 2]` | = TA-510 |
| DI-204 | `U: [4, 2, 7, 1] 7-2, 2-4, 4-1` | `diameterPath` | `[7, 2, 4, 1]/[0, 1, 2]` | From 7, the first peripheral vertex in `vertices` order |
| DI-205 | `U: [] P(3,1,0,2)` | `center` | `[1, 0]` | NetworkX `center(path_graph([3, 1, 0, 2]))` is `[1, 0]` too |
| DI-206 | `U: [] 1-2, 1-3, 2-4, 2-5` | `center` | `[1, 2]` | = TA-403 |
| DI-207 | `U: [] P(0..4)` | `center` | `[2]` | = TA-404 |
| DI-208 | `U: [] P(0..98)` | `center` | `[49]` | = TA-405 |
| DI-209 | `U: [] P(0..99)` | `center` | `[49, 50]` | = TA-406 |
| DI-210 | `U: [] S(0;1..5)` | `center` | `[0]` | = TA-407 |
| DI-211 | `U: [] kary(40,3)` | `center` | `[0]` | = TA-408 |
| DI-212 | `U: [] S(0;1..6), P(6,7,8,9,10)` | `center` | `[7]` | = TA-409 |
| DI-213 | `U: [] S(0;1..6), P(6,7,8,9,10)` | `centroid` | `[0]` | = TA-506: the median is not the center |
| DI-214 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `center` | `[0]` | = TA-410 |
| DI-215 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `centroid` | `[1]` | = TA-508 |
| DI-216 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `diameter` | `#6` | = TA-608 |
| DI-217 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `diameterPath` | `[6, 4, 1, 0, 2, 5, 8]/[5, 3, 0, 1, 4, 7]` | = TA-609 |
| DI-218 | `U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5` | `diameterPath` | `[6, 4, 1, 0, 2, 5, 8]/[5, 2, 4, 1, 7, 3]` | = TA-610: same vertices, other positions |
| DI-219 | `U: [] a-b, b-c, b-d, d-e` | `center` | `[b, d]` | = TA-411 |
| DI-220 | `U: [] a-b, b-c, b-d, d-e` | `centroid` | `[b]` | = TA-509 |
| DI-221 | `U: [] a-b, b-c, b-d, d-e` | `diameterPath` | `[a, b, d, e]/[0, 2, 3]` | = TA-611 |
| DI-222 | `U: [] S(0;1..5)` | `diameterPath` | `[1, 0, 2]/[0, 1]` | = TA-607 |
| DI-223 | `U: [] S(0;1..6), P(6,7,8,9,10)` | `diameterPath` | `[1, 0, 6, 7, 8, 9, 10]/[0, 5, 6, 7, 8, 9]` | = TA-612 |
| DI-224 | `U: [] kary(40,3)` | `diameter` | `#6` | = TA-613 |
| DI-225 | `U: [] P(0..9)` | `diameterPath` | `[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]/[0, 1, 2, 3, 4, 5, 6, 7, 8]` | = TA-606 |
| DI-226 | `U: [] kary(8,2)` | `centroid` | `[0, 1]` | = TA-505: two medians |
| DI-227 | `U: [] P(0..99)` | `centroid` | `[49, 50]` | = TA-504 |
| DI-228 | `U: [] P(0..4)` | `center(weight: [1, 1, 1, 10])` | `[3]` | = TA-413 |
| DI-229 | `U: [] P(0..3)` | `center(weight: [0, 1, 0])` | `[0, 1, 2, 3]` | = TA-416: zero end edges, four centers |
| DI-230 | `U: [] P(0..3)` | `center(weight: [1, 0, 1])` | `[1, 2]` | = TA-417 |
| DI-231 | `U: [] S(0;1..4)` | `center(weight: [3, 1, 30, 2])` | `[0]` | = TA-419 |
| DI-232 | `U: [] P(0..3)` | `center(weight: [0.5, 0.25, 0.75])` | `[2]` | = TA-420 |
| DI-233 | `U: [] P(0..4)` | `diameter(weight: [1, 1, 1, 10])` | `#13` | = TA-614 |
| DI-234 | `U: [] P(0..4)` | `diameterPath(weight: [1, 1, 1, 10])` | `[0, 1, 2, 3, 4]/[0, 1, 2, 3] #13` | = TA-615 |
| DI-235 | `U: [] S(0;1..4)` | `diameterPath(weight: [3, 1, 3, 2])` | `[1, 0, 3]/[0, 2] #6` | = TA-616 |
| DI-236 | `U: [] P(0..2)` | `diameterPath(weight: [0, 0])` | `[0]/[] #0` | = TA-617: all zero, the trivial path at `vertices[0]` |
| DI-237 | `U: [] P(0..3)` | `diameterPath(weight: [0, 1, 0])` | `[0, 1, 2]/[0, 1] #1` | = TA-618: the least pair at distance 1 is (0, 2) |
| DI-238 | `U: [] P(0..3)` | `diameter(weight: [0.5, 0.25, 0.75])` | `#1.5` | = TA-619 |
| DI-239 | `U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8` | `diameterPath(weight: [5, 1, 1, 1, 1, 1, 1, 1])` | `[6, 4, 1, 0, 2, 5, 8]/[5, 3, 0, 1, 4, 7] #10` | = TA-624 |
| DI-240 | `U: [] P(0..3)` | `center(weight: [1, -1, 1])` | `trap` | TA-421 traps too |
| DI-250 | `U: [5, 4, 3, 2, 1, 0] C(0..5)` | `center` | `[5, 4, 3, 2, 1, 0]` | Everything, in `vertices` order |
| DI-251 | `U: [5, 4, 3, 2, 1, 0] C(0..5)` | `diameterPath` | `[5, 4, 3, 2]/[4, 3, 2]` | u = 5 (first in `vertices`), v = 2 (first at distance 3): breadth-first parents through 4, the first edge in 5's row |
| DI-252 | `U: [5, 4, 3, 2, 1, 0] C(0..5) ~rev` | `diameterPath` | `[5, 0, 1, 2]/[5, 0, 1]` | Rows reversed: the other way round. Row order decides the path, never the endpoints |
| DI-253 | `U: [] grid(3,3)` | `diameterPath` | `[0, 1, 2, 5, 8]/[0, 2, 4, 9]` | |
| DI-254 | `U: [] grid(3,3) ~rev` | `diameterPath` | `[0, 3, 6, 7, 8]/[1, 6, 10, 11]` | |

## D. Disconnected undirected graphs

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| DI-301 | `U: [] P(0..2), 3-4` | `eccentricities` | `[nil, nil, nil, nil, nil]` | NetworkX raises; igraph ignores unreachable vertices and says [2, 1, 2, 1, 1] |
| DI-302 | `U: [] P(0..2), 3-4` | `radius` | `nil` | igraph 1 |
| DI-303 | `U: [] P(0..2), 3-4` | `diameter` | `nil` | igraph `unconn=True`: 2 (the largest finite); `unconn=False`: inf |
| DI-304 | `U: [] P(0..2), 3-4` | `center` | `[0, 1, 2, 3, 4]` | |
| DI-305 | `U: [] P(0..2), 3-4` | `periphery` | `[0, 1, 2, 3, 4]` | |
| DI-306 | `U: [] P(0..2), 3-4` | `diameterPath` | `nil` | igraph `get_diameter` returns [0, 1, 2] |
| DI-307 | `U: [] P(0..2), 3-4` | `centroid` | `[0, 1, 2, 3, 4]` | NetworkX raises `NetworkXNoPath` |
| DI-308 | `U: [] P(0..2), 3-4` | `wienerIndex` | `nil` | NetworkX `inf` |
| DI-309 | `U: [] P(0..2), 3-4` | `averageShortestPathLength` | `nil` | igraph `unconn=True` averages the reachable pairs |
| DI-310 | `U: [] P(0..2), 3-4` | `density` | `#0.3` | |
| DI-311 | `U: [0..3] P(0..2)` | `eccentricities` | `[nil, nil, nil, nil]` | An isolated vertex. igraph: [2, 1, 2, 0], radius 0 |
| DI-312 | `U: [0..3] P(0..2)` | `radius` | `nil` | |
| DI-313 | `U: [0..3] P(0..2)` | `center` | `[0, 1, 2, 3]` | |
| DI-314 | `U: [0..3] P(0..2)` | `eccentricity(of: 1)` | `nil` | |
| DI-315 | `U: [0..3] P(0..2)` | `eccentricity(of: 3)` | `nil` | |
| DI-316 | `U: [] P(0..2), 3-4` | `diameter(weight: [1, 1, 1])` | `nil` | |

## E. Directed graphs

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| DI-401 | `D: [] P(0..2)` | `eccentricities` | `[2, nil, nil]` | Out-distances: only 0 reaches everything. igraph [2, 1, 0] |
| DI-402 | `D: [] P(0..2)` | `radius` | `#2` | Finite though the graph is not strongly connected (Boost, JGraphT). igraph 0 |
| DI-403 | `D: [] P(0..2)` | `diameter` | `nil` | NetworkX raises; igraph `unconn=True` 2 |
| DI-404 | `D: [] P(0..2)` | `center` | `[0]` | |
| DI-405 | `D: [] P(0..2)` | `periphery` | `[1, 2]` | The vertices of infinite eccentricity |
| DI-406 | `D: [] P(0..2)` | `centroid` | `[0]` | |
| DI-407 | `D: [] P(0..2)` | `wienerIndex` | `nil` | |
| DI-408 | `D: [] P(0..2)` | `averageShortestPathLength` | `nil` | |
| DI-409 | `D: [] P(0..2)` | `density` | `#0.3333333333333333` | |
| DI-410 | `D: [] P(0..2)` | `diameterPath` | `nil` | |
| DI-411 | `D: [] P(0..2)` | `eccentricity(of: 0)` | `#2` | |
| DI-412 | `D: [] P(0..2)` | `eccentricity(of: 2)` | `nil` | |
| DI-413 | `D: [] C(0..3)` | `eccentricities` | `[3, 3, 3, 3]` | Directed 4-cycle |
| DI-414 | `D: [] C(0..3)` | `diameterPath` | `[0, 1, 2, 3]/[0, 1, 2]` | |
| DI-415 | `D: [] C(0..3)` | `wienerIndex` | `#24` | Ordered pairs: 4·(1 + 2 + 3) |
| DI-416 | `D: [] C(0..3)` | `averageShortestPathLength` | `#2.0` | |
| DI-417 | `D: [] C(0..3)` | `density` | `#0.3333333333333333` | |
| DI-418 | `D: [] 0>1, 1>2, 2>0, 0>2` | `eccentricities` | `[1, 2, 2]` | |
| DI-419 | `D: [] 0>1, 1>2, 2>0, 0>2` | `center` | `[0]` | |
| DI-420 | `D: [] 0>1, 1>2, 2>0, 0>2` | `periphery` | `[1, 2]` | |
| DI-421 | `D: [] 0>1, 1>2, 2>0, 0>2` | `centroid` | `[0]` | NetworkX 3.7 `centroid` on a digraph sums out-distances: [0] |
| DI-422 | `D: [] 0>1, 1>2, 2>0, 0>2` | `diameterPath` | `[1, 2, 0]/[1, 2]` | From 1, the first peripheral vertex, to 0 |
| DI-423 | `D: [] 0>1, 0>2, 1>3` | `eccentricities` | `[2, nil, nil, nil]` | An arborescence: only the root reaches everything |
| DI-424 | `D: [] 0>1, 0>2, 1>3` | `center` | `[0]` | |
| DI-425 | `D: [] K(4)` | `eccentricities` | `[1, nil, nil, nil]` | The acyclic tournament |
| DI-426 | `D: [] K(4)` | `radius` | `#1` | |
| DI-427 | `D: [] K(4)` | `periphery` | `[1, 2, 3]` | |
| DI-428 | `D: [] K(4)` | `undirected > diameter` | `#1` | `digraph.undirected` is K₄ |
| DI-429 | `D: [] K(4)` | `undirected > density` | `#1.0` | Each arc an edge: twice the directed density |
| DI-430 | `D: [] K(4)` | `density` | `#0.5` | |
| DI-431 | `D: [0..2] 0>1, 1>0` | `eccentricities` | `[nil, nil, nil]` | An isolated vertex |
| DI-432 | `D: [0..2] 0>1, 1>0` | `center` | `[0, 1, 2]` | Every eccentricity infinite: every vertex |
| DI-433 | `D: [] 0>1, 1>0, 1>2, 2>1` | `eccentricities` | `[2, 1, 2]` | Both directions: the undirected path's values |
| DI-434 | `D: [] P(0..2)` | `undirected > eccentricities` | `[2, 1, 2]` | |
| DI-435 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `directed > eccentricities` | `[2, 3, 2, 2, 3]` | `graph.directed`: the same values as DI-101 |
| DI-436 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `directed > center` | `[1, 3, 4]` | |
| DI-437 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `directed > density` | `#0.6` | Twice the arcs, the same density as DI-109 |
| DI-438 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `directed > wienerIndex` | `#30` | Ordered pairs: twice DI-107 |
| DI-439 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `directed > averageShortestPathLength` | `#1.5` | The same as DI-108 |
| DI-440 | `D: [] 0>0` | `eccentricities` | `[0]` | |
| DI-441 | `D: [] 0>0, 0>1, 1>0` | `density` | `#1.5` | Loops count (NetworkX); igraph `loops=False` 1.5 too, `loops=True` 0.75 |
| DI-442 | `D: [0..9] lcg(10,25,3)` | `eccentricities` | `[4, 3, nil, nil, 4, 4, 3, 4, 5, 4]` | |
| DI-443 | `D: [0..9] lcg(10,25,3)` | `center` | `[1, 6]` | |
| DI-444 | `D: [0..9] lcg(10,25,3)` | `diameterPath` | `nil` | |
| DI-445 | `D: [0..9] lcg(10,25,3)` | `centroid` | `[1]` | |

## F. Self-loops and parallel edges

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| DI-501 | `U: [] 0-0, 0-1, 0-1, 1-2` | `eccentricities` | `[2, 1, 2]` | igraph probe graph: loops and parallel edges change no distance |
| DI-502 | `U: [] 0-0, 0-1, 0-1, 1-2` | `center` | `[1]` | |
| DI-503 | `U: [] 0-0, 0-1, 0-1, 1-2` | `diameterPath` | `[0, 1, 2]/[1, 3]` | The first parallel copy in 0's row (position 1) |
| DI-504 | `U: [] 0-0, 0-1, 0-1, 1-2` | `density` | `#1.3333333333333333` | Every edge counts, the loop once: 2·4 / (3·2). NetworkX the same; igraph `loops=False` 1.333…, `loops=True` 0.666… |
| DI-505 | `U: [] 0-0, 0-1, 0-1, 1-2` | `wienerIndex` | `#4` | |
| DI-506 | `U: [] 0-0, 0-1, 0-1, 1-2` | `averageShortestPathLength` | `#1.3333333333333333` | |
| DI-507 | `U: [] 0-1, 0-1, 1-2, 1-2, 0-1` | `density` | `#1.6666666666666667` | Above 1 |
| DI-508 | `D: [] 0>1, 0>1, 1>0` | `eccentricities` | `[1, 1]` | |
| DI-509 | `D: [] 0>1, 0>1, 1>0` | `density` | `#1.5` | |
| DI-510 | `U: [] 1-2, 0-1, 0-1` | `diameterPath` | `[2, 1, 0]/[0, 1]` | `vertices` = [1, 2, 0]: from 2 to 0, through the first copy |

## G. Weighted

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| DI-601 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `eccentricities(weight: [1, 2, 3, 1, 2, 3])` | `[4, 5, 3, 4, 5]` | |
| DI-602 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `center(weight: [1, 2, 3, 1, 2, 3])` | `[3]` | |
| DI-603 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `periphery(weight: [1, 2, 3, 1, 2, 3])` | `[2, 5]` | |
| DI-604 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `radius(weight: [1, 2, 3, 1, 2, 3])` | `#3` | |
| DI-605 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `diameter(weight: [1, 2, 3, 1, 2, 3])` | `#5` | |
| DI-606 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `diameterPath(weight: [1, 2, 3, 1, 2, 3])` | `[2, 1, 3, 5]/[0, 1, 4] #5` | |
| DI-607 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `centroid(weight: [1, 2, 3, 1, 2, 3])` | `[3]` | |
| DI-608 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `wienerIndex(weight: [1, 2, 3, 1, 2, 3])` | `#28` | |
| DI-609 | `U: [] 1-2, 1-3, 1-4, 3-4, 3-5, 4-5` | `averageShortestPathLength(weight: [1.0, 2.0, 3.0, 1.0, 2.0, 3.0])` | `#2.8` | `Double` weights (the weighted average needs `BinaryFloatingPoint`) |
| DI-610 | `U: [] 0-1, 0-1, 1-2` | `eccentricities(weight: [5, 1, 2])` | `[3, 2, 3]` | Parallel edges: the lighter one counts |
| DI-611 | `U: [] 0-1, 0-1, 1-2` | `diameterPath(weight: [5, 1, 2])` | `[0, 1, 2]/[1, 2] #3` | Through position 1, the lighter copy |
| DI-612 | `U: [] 0-1, 0-1, 1-2` | `diameterPath(weight: [1, 5, 2])` | `[0, 1, 2]/[0, 2] #3` | |
| DI-613 | `U: [] 0-0, 0-1` | `eccentricities(weight: [0, 4])` | `[4, 4]` | A zero-weight loop changes nothing |
| DI-614 | `U: [] C(0..3)` | `eccentricities(weight: 0)` | `[0, 0, 0, 0]` | All zero |
| DI-615 | `U: [] C(0..3)` | `center(weight: 0)` | `[0, 1, 2, 3]` | |
| DI-616 | `U: [] C(0..3)` | `diameterPath(weight: 0)` | `[0]/[] #0` | |
| DI-617 | `U: [] C(0..3)` | `eccentricities(weight: [0.5, 0.25, 0.75, 0.125])` | `[0.75, 0.625, 0.75, 0.75]` | Dyadic `Double` weights: exact |
| DI-618 | `U: [] C(0..3)` | `center(weight: [0.5, 0.25, 0.75, 0.125])` | `[1]` | |
| DI-619 | `U: [] C(0..3)` | `diameterPath(weight: [0.5, 0.25, 0.75, 0.125])` | `[0, 1, 2]/[0, 1] #0.75` | |
| DI-620 | `D: [] C(0..2), 0>2` | `eccentricities(weight: [1, 1, 1, 5])` | `[2, 2, 2]` | The direct arc 0>2 is longer than the way round |
| DI-621 | `D: [] C(0..2), 0>2` | `diameterPath(weight: [1, 1, 1, 5])` | `[0, 1, 2]/[0, 1] #2` | |
| DI-622 | `D: [] C(0..2), 0>2` | `wienerIndex(weight: [1, 1, 1, 5])` | `#9` | |
| DI-623 | `D: [] P(0..2)` | `eccentricities(weight: [2, 3])` | `[5, nil, nil]` | |
| DI-624 | `D: [] P(0..2)` | `radius(weight: [2, 3])` | `#5` | |
| DI-625 | `U: [] grid(4,4)` | `eccentricities(weight: e%3+1)` | `[8, 7, 9, 9, 8, 6, 6, 8, 9, 6, 5, 6, 9, 8, 6, 8]` | |
| DI-626 | `U: [] grid(4,4)` | `center(weight: e%3+1)` | `[10]` | |
| DI-627 | `U: [] grid(4,4)` | `periphery(weight: e%3+1)` | `[2, 3, 8, 12]` | |
| DI-628 | `U: [] grid(4,4)` | `centroid(weight: e%3+1)` | `[10]` | |
| DI-629 | `U: [] 0-1` | `eccentricities(weight: [inf])` | `[inf, inf]` | `+infinity` is a value, not "unreachable": the eccentricity is `.some(.infinity)` |
| DI-630 | `U: [] 0-1, 2-3` | `diameter(weight: [1, -1])` | `trap` | A negative weight traps though no search would reach it after the first finds the graph disconnected: every weight is read and checked first |
| DI-631 | `U: [] P(0..3)` | `diameter(weight: [1, nan, 1])` | `trap` | |
| DI-632 | `D: [] 0>1, 2>2` | `eccentricities(weight: [1, -1])` | `trap` | A negative loop |
| DI-633 | `U: [0] 0-1` | `eccentricity(of: 0, weight: [-1])` | `trap` | Single-source too |
| DI-634 | `U: [] 0-1, 1-2` | `eccentricity(of: 1, weight: [3, 4])` | `#4` | |
| DI-635 | `U: [] P(0..2), 3-4` | `wienerIndex(weight: [1, 1, 1])` | `nil` | |
| DI-636 | `U: [] K(4)` | `centroid(weight: [1, 1, 1, 1, 1, 9])` | `[0, 1]` | One heavy edge (2–3) pushes its ends out |

## H. Stress (no recursion, no quadratic memory)

| ID | Graph | Op | Expected | Notes |
|---|---|---|---|---|
| DI-901 | `U: [] P(0..99999)` | `diameter` | `#99999` | Bounding: a handful of searches (benchmark, not public) |
| DI-902 | `U: [] P(0..99999)` | `radius` | `#50000` | |
| DI-903 | `U: [] P(0..99999)` | `center` | `[49999, 50000]` | |
| DI-904 | `U: [] P(0..99999)` | `periphery` | `[0, 99999]` | |
| DI-905 | `U: [] P(0..99999)` | `wienerIndex` | `#166666666650000` | (n³ − n)/6; one search per vertex: 10¹⁰ steps, a benchmark-only case |
| DI-906 | `U: [] S(0;1..99999)` | `diameter` | `#2` | |
| DI-907 | `U: [] S(0;1..99999)` | `radius` | `#1` | |
| DI-908 | `U: [] S(0;1..99999)` | `center` | `[0]` | |
| DI-909 | `U: [] S(0;1..99999)` | `wienerIndex` | `#9999800001` | (n − 1) + (n − 1)(n − 2) |
| DI-910 | `U: [] C(0..9999)` | `diameter` | `#5000` | Bounding's worst shape: every eccentricity equal, so about n searches (NetworkX's documentation names cycles) |
| DI-911 | `U: [] C(0..9999)` | `radius` | `#5000` | |
| DI-912 | `U: [] C(0..9999)` | `wienerIndex` | `#125000000000` | n·(n²/4)/2 for even n |
| DI-913 | `U: [] P(0..99999)` | `centroid` | `[49999, 50000]` | |
| DI-914 | `U: [] S(0;1..99999)` | `centroid` | `[0]` | |
| DI-915 | `U: [] P(0..99999)` | `density` | `#2e-05` | |
