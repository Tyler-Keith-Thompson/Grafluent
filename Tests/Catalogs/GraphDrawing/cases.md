# GraphDrawing: case catalog (DR-001 – DR-214, 214 rows)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
igraph==1.0.0 --with numpy==2.3.4 --with scipy==1.18.1 python3 Tests/Catalogs/GraphDrawing/ref.py`;
`--write` regenerates this file, `--stress` adds random trees, digraphs and graphs, `--bench` prints
the baselines in api.md). Coordinates only: every expected value is a list of points, a layer, a
count or a bound. The model implements every layout from the definitions in api.md. Circular
positions and `rescaled` are compared with NetworkX 3.7; tree layouts with python-igraph 1.0.0's
`layout_reingold_tilford` and `layout_reingold_tilford_circular`; Sugiyama layers with igraph's
`layout_sugiyama`; stress majorization with NetworkX's `kamada_kawai_layout`; spectral (phase 2)
with NetworkX's `spectral_layout` up to the sign of each axis. Disagreements are in api.md.

## Notation

**Input.** `U:` undirected, `D:` directed; `n=N;` lists vertices 0..<N first; then edges in
**position order**. Vertices are the `Int`s 0..<n, `vertices` in that order. `T:` is a
`RootedTree<Int>` built with `RootedTree(parents:)`, so `children(of:)` lists children by
ascending vertex.

| Token | Edges |
|---|---|
| `u-v`, `u>v` | one edge; one arc |
| `P(a,b,…)`, `C(a,…,z)` | the path a–b, b–c, …; the cycle, closing z–a (arcs in a `D:` graph) |
| `K(n)` | every pair i < j, lexicographic |
| `grid(r,c)` | vertex `i*c + j`; for each vertex in order the edge right, then down |
| `Q(d)` | hypercube: for i in order, for k = 0..<d, i–(i ^ 2^k) when i < i ^ 2^k |
| `petersen` | 0–1, 1–2, 2–3, 3–4, 4–0, then i–(i+5) for i = 0…4, then (5+i)–(5+(i+2) mod 5) |
| `lcggraph(n,m,s)` | m edges (u, v), u ≠ v, from the LCG below: draw u = x mod n, v = x′ mod n, skip u = v (parallel edges possible) |
| `lcgdag(n,m,s)` | as `lcggraph`, each arc oriented min → max |
| `T: [p0, p1, …]` | `parents`, `nil` for the root |
| `T: bal(b,h)` | the complete b-ary tree of height h, parent of v is (v − 1) / b |
| `T: lcgtree(n,s)` | parent of i (1 ≤ i < n) is x mod i, one LCG draw per i |

The LCG: x ← x · 6364136223846793005 + 1442695040888963407 (mod 2⁶⁴), seeded with s, each draw
is x >> 33 after the step.

**Expected.** Points are `(x, y)`; `[…]` lists them in `vertices` order. Values printed with up to
12 decimals involve `cos`/`sin` (circular layouts): compare with tolerance 1e-9. Every other point
list is exact (multiples of 1/2ⁿ from separation-1 arithmetic). `≤ v` rows are quality bounds on a
median over seeds 1…20 of `Xoshiro256StarStar(seed:)` (normalized stress or crossing count, as
defined in api.md, computed in the test from `positions`); `≈ v (±1%)` rows are a converged value.
`#N` is a count. `**trap**` rows are preconditions. Phase 2 rows are pinned now and not run until
the phase 2 entry points exist.

| ID | Group | Case | Input | Op | Expected |
|---|---|---|---|---|---|
| DR-001 | Drawing | empty drawing: no vertices | `Drawing<Int>()` | `count` | 0 |
| DR-002 | Drawing | empty drawing: no bounding box | `Drawing<Int>()` | `boundingBox` | nil |
| DR-003 | Drawing | empty drawing: rescaled stays empty | `Drawing<Int>()` | `rescaled()` | [] |
| DR-004 | Drawing | positions in vertices order | `Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` | `positions` | [(0.0, 0.0), (2.0, 1.0)] |
| DR-005 | Drawing | position(of:) reads by vertex | `Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` | `position(of: 3)` | (2.0, 1.0) |
| DR-006 | Drawing | setPosition(_:of:) writes by vertex | `Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` | `setPosition((7, -1), of: 5); positions` | [(7.0, -1.0), (2.0, 1.0)] |
| DR-007 | Drawing | position(of:) on a missing vertex | `Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` | `position(of: 4)` | **trap** |
| DR-008 | Drawing | position(checked:) on a missing vertex | `Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` | `position(checked: 4)` | throws VertexNotFound |
| DR-009 | Drawing | position(checked:) on a vertex | `Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` | `position(checked: 5)` | (0.0, 0.0) |
| DR-010 | Drawing | vertices and positions of different lengths | `Drawing(vertices: [5, 3], positions: [(0, 0)])` | `init` | **trap** |
| DR-011 | Drawing | duplicate vertex | `Drawing(vertices: [5, 5], positions: [(0, 0), (1, 1)])` | `init` | **trap** |
| DR-012 | Drawing | elements are (vertex, position) pairs in order | `Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` | `Array(self)` | [(5, (0.0, 0.0)), (3, (2.0, 1.0))] |
| DR-013 | Drawing | equal when vertices and positions are equal in order | `Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` vs `Drawing(vertices: [3, 5], positions: [(2, 1), (0, 0)])` | `==` | false |
| DR-014 | Drawing | bounding box | `Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` | `boundingBox` | (min: (0.0, 0.0), max: (2.0, 1.0)) |
| DR-015 | Drawing | rescaled: centred, largest \|coordinate\| = 1 | `Drawing(vertices: [0, 1], positions: [(0.0, 0.0), (2.0, 1.0)])` | `rescaled(scale: 1.0, center: (0.0, 0.0))` | [(-1.0, -0.5), (1.0, 0.5)] |
| DR-016 | Drawing | rescaled: scale 3 | `Drawing(vertices: [0, 1], positions: [(0.0, 0.0), (2.0, 1.0)])` | `rescaled(scale: 3.0, center: (0.0, 0.0))` | [(-3.0, -1.5), (3.0, 1.5)] |
| DR-017 | Drawing | rescaled: centre (10, -2) | `Drawing(vertices: [0, 1], positions: [(0.0, 0.0), (2.0, 1.0)])` | `rescaled(scale: 1.0, center: (10.0, -2.0))` | [(9.0, -2.5), (11.0, -1.5)] |
| DR-018 | Drawing | rescaled: three points, the y extent decides | `Drawing(vertices: [0, 1, 2], positions: [(0.0, 0.0), (1.0, 4.0), (2.0, -4.0)])` | `rescaled(scale: 1.0, center: (0.0, 0.0))` | [(-0.25, 0.0), (0.0, 1.0), (0.25, -1.0)] |
| DR-019 | Drawing | rescaled: one point goes to the centre | `Drawing(vertices: [0], positions: [(3.0, 4.0)])` | `rescaled(scale: 1.0, center: (0.0, 0.0))` | [(0.0, 0.0)] |
| DR-020 | Drawing | rescaled: coincident points go to the centre | `Drawing(vertices: [0, 1], positions: [(3.0, 4.0), (3.0, 4.0)])` | `rescaled(scale: 2.0, center: (1.0, 1.0))` | [(1.0, 1.0), (1.0, 1.0)] |
| DR-021 | Drawing | rescaled: square | `Drawing(vertices: [0, 1, 2, 3], positions: [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)])` | `rescaled(scale: 1.0, center: (0.0, 0.0))` | [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)] |
| DR-022 | Circular | 0 vertices | `U: n=0;` | `circularLayout()` | [] |
| DR-023 | Circular | 1 vertices: the centre | `U: n=1;` | `circularLayout()` | [(0.0, 0.0)] |
| DR-024 | Circular | 2 vertices | `U: n=2;` | `circularLayout()` | [(1.0, 0.0), (-1.0, 0.0)] |
| DR-025 | Circular | 3 vertices | `U: n=3; C(0,1,2)` | `circularLayout()` | [(1.0, 0.0), (-0.5, 0.866025403784), (-0.5, -0.866025403784)] |
| DR-026 | Circular | 4 vertices | `U: n=4; C(0,1,2,3)` | `circularLayout()` | [(1.0, 0.0), (0.0, 1.0), (-1.0, 0.0), (0.0, -1.0)] |
| DR-027 | Circular | 6 vertices | `U: n=6; C(0,1,2,3,4,5)` | `circularLayout()` | [(1.0, 0.0), (0.5, 0.866025403784), (-0.5, 0.866025403784), (-1.0, 0.0), (-0.5, -0.866025403784), (0.5, -0.866025403784)] |
| DR-028 | Circular | radius 2, centre (1, -1) | `U: n=4;` | `circularLayout(radius: 2, center: (1, -1))` | [(3.0, -1.0), (1.0, 1.0), (-1.0, -1.0), (1.0, -3.0)] |
| DR-029 | Circular | edges do not matter: vertices order only | `U: n=3; 0-2, 2-1` | `circularLayout(center: (5, 5))` | [(6.0, 5.0), (4.5, 5.866025403784), (4.5, 4.133974596216)] |
| DR-030 | Circular | directed graph through its undirected view | `D: n=3; 0>1` | `undirectedView.circularLayout()` | [(1.0, 0.0), (-0.5, 0.866025403784), (-0.5, -0.866025403784)] |
| DR-031 | Circular | negative radius | `U: n=3;` | `circularLayout(radius: -1)` | **trap** |
| DR-032 | Circular | NaN centre | `U: n=3;` | `circularLayout(center: (.nan, 0))` | **trap** |
| DR-033 | Tree | one vertex | `T: [nil]` | `reingoldTilfordLayout()` | [(0.0, 0.0)] |
| DR-034 | Tree | two vertices | `T: [nil, 0]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (0.0, 1.0)] |
| DR-035 | Tree | path of 4 | `T: [nil, 0, 1, 2]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (0.0, 1.0), (0.0, 2.0), (0.0, 3.0)] |
| DR-036 | Tree | star K1,3: root over the middle child | `T: [nil, 0, 0, 0]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-1.0, 1.0), (0.0, 1.0), (1.0, 1.0)] |
| DR-037 | Tree | star K1,4: even fan, root over the gap | `T: [nil, 0, 0, 0, 0]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-1.5, 1.0), (-0.5, 1.0), (0.5, 1.0), (1.5, 1.0)] |
| DR-038 | Tree | binary tree of height 2 | `T: bal(2,2)` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-1.0, 1.0), (1.0, 1.0), (-1.5, 2.0), (-0.5, 2.0), (0.5, 2.0), (1.5, 2.0)] |
| DR-039 | Tree | ternary tree of height 2 | `T: bal(3,2)` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-3.0, 1.0), (0.0, 1.0), (3.0, 1.0), (-4.0, 2.0), (-3.0, 2.0), (-2.0, 2.0), (-1.0, 2.0), (0.0, 2.0), (1.0, 2.0), (2.0, 2.0), (3.0, 2.0), (4.0, 2.0)] |
| DR-040 | Tree | binary tree of height 4 | `T: bal(2,4)` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-4.0, 1.0), (4.0, 1.0), (-6.0, 2.0), (-2.0, 2.0), (2.0, 2.0), (6.0, 2.0), (-7.0, 3.0), (-5.0, 3.0), (-3.0, 3.0), (-1.0, 3.0), (1.0, 3.0), (3.0, 3.0), (5.0, 3.0), (7.0, 3.0), (-7.5, 4.0), (-6.5, 4.0), (-5.5, 4.0), (-4.5, 4.0), (-3.5, 4.0), (-2.5, 4.0), (-1.5, 4.0), (-0.5, 4.0), (0.5, 4.0), (1.5, 4.0), (2.5, 4.0), (3.5, 4.0), (4.5, 4.0), (5.5, 4.0), (6.5, 4.0), (7.5, 4.0)] |
| DR-041 | Tree | left child has two leaves, right is a leaf | `T: [nil, 0, 0, 1, 1]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-0.5, 1.0), (0.5, 1.0), (-1.0, 2.0), (0.0, 2.0)] |
| DR-042 | Tree | left leaf, right child has two leaves | `T: [nil, 0, 0, 2, 2]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-0.5, 1.0), (0.5, 1.0), (0.0, 2.0), (1.0, 2.0)] |
| DR-043 | Tree | igraph's example shape: one deep child among leaves | `T: [nil, 0, 0, 0, 1, 1]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-1.0, 1.0), (0.0, 1.0), (1.0, 1.0), (-1.5, 2.0), (-0.5, 2.0)] |
| DR-044 | Tree | two chains under a three-way root | `T: [nil, 0, 0, 0, 1, 4, 3, 6]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-1.0, 1.0), (0.0, 1.0), (1.0, 1.0), (-1.0, 2.0), (-1.0, 3.0), (1.0, 2.0), (1.0, 3.0)] |
| DR-045 | Tree | Walker's spreading: leaves between two wide subtrees are spaced evenly | `T: [nil, 0, 0, 0, 0, 1, 1, 1, 4, 4, 4]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-1.5, 1.0), (-0.5, 1.0), (0.5, 1.0), (1.5, 1.0), (-2.5, 2.0), (-1.5, 2.0), (-0.5, 2.0), (0.5, 2.0), (1.5, 2.0), (2.5, 2.0)] |
| DR-046 | Tree | Walker's spreading, deep: wide subtrees meet two levels down | `T: [nil, 0, 0, 0, 0, 1, 4, 5, 5, 5, 6, 6, 6]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-1.5, 1.0), (-0.5, 1.0), (0.5, 1.0), (1.5, 1.0), (-1.5, 2.0), (1.5, 2.0), (-2.5, 3.0), (-1.5, 3.0), (-0.5, 3.0), (0.5, 3.0), (1.5, 3.0), (2.5, 3.0)] |
| DR-047 | Tree | a small subtree between two large ones moves to the middle | `T: [nil, 0, 0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 7, 7, 8, 8]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-2.0, 1.0), (0.0, 1.0), (2.0, 1.0), (-3.0, 2.0), (-1.0, 2.0), (0.0, 2.0), (1.0, 2.0), (3.0, 2.0), (-3.5, 3.0), (-2.5, 3.0), (-1.5, 3.0), (-0.5, 3.0), (0.5, 3.0), (1.5, 3.0), (2.5, 3.0), (3.5, 3.0)] |
| DR-048 | Tree | caterpillar | `T: [nil, 0, 1, 2, 0, 1, 2, 3]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-0.5, 1.0), (-1.0, 2.0), (-1.5, 3.0), (0.5, 1.0), (0.0, 2.0), (-0.5, 3.0), (-1.5, 4.0)] |
| DR-049 | Tree | broom: a path then a fan | `T: [nil, 0, 1, 2, 2, 2, 2]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (0.0, 1.0), (0.0, 2.0), (-1.5, 3.0), (-0.5, 3.0), (0.5, 3.0), (1.5, 3.0)] |
| DR-050 | Tree | root is not vertex 0 | `T: [2, 2, nil, 1]` | `reingoldTilfordLayout()` | [(-0.5, 1.0), (0.5, 1.0), (0.0, 0.0), (0.5, 2.0)] |
| DR-051 | Tree | random tree, 20 vertices | `T: lcgtree(20,1)` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-0.75, 1.0), (-0.75, 2.0), (0.75, 1.0), (-0.75, 3.0), (-1.25, 4.0), (-2.25, 5.0), (0.25, 2.0), (-2.75, 6.0), (1.25, 2.0), (-1.75, 6.0), (-1.25, 5.0), (-1.75, 7.0), (-0.25, 4.0), (-2.25, 8.0), (-2.25, 9.0), (-1.25, 8.0), (-1.25, 9.0), (-1.25, 10.0), (-0.25, 5.0)] |
| DR-052 | Tree | random tree, 40 vertices | `T: lcgtree(40,7)` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-6.0, 1.0), (-8.5, 2.0), (0.5, 1.0), (-4.5, 2.0), (4.0, 1.0), (3.0, 2.0), (6.0, 1.0), (-7.0, 3.0), (-3.0, 3.0), (3.0, 3.0), (6.0, 2.0), (-1.0, 2.0), (-4.5, 4.0), (-1.0, 3.0), (-2.5, 4.0), (-8.5, 3.0), (-5.5, 5.0), (0.0, 2.0), (-3.5, 2.0), (6.0, 3.0), (-8.5, 4.0), (-2.5, 5.0), (-1.5, 4.0), (0.0, 3.0), (1.0, 2.0), (-7.5, 4.0), (-7.5, 5.0), (-4.5, 5.0), (-3.5, 5.0), (-2.5, 6.0), (4.0, 2.0), (-3.5, 6.0), (-6.5, 4.0), (-6.5, 5.0), (2.0, 2.0), (2.0, 3.0), (-4.5, 6.0), (5.0, 2.0), (-2.0, 3.0)] |
| DR-053 | Tree | random tree, 60 vertices | `T: lcgtree(60,3)` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-0.5, 1.0), (-5.03125, 2.0), (-11.59375, 3.0), (-3.125, 3.0), (-6.78125, 4.0), (-10.09375, 5.0), (0.5, 1.0), (-5.46875, 5.0), (-6.84375, 6.0), (-8.09375, 7.0), (-9.09375, 8.0), (-11.09375, 6.0), (1.53125, 3.0), (-12.09375, 4.0), (1.53125, 4.0), (-5.59375, 7.0), (-12.09375, 7.0), (4.03125, 2.0), (-1.46875, 4.0), (-6.09375, 8.0), (-9.09375, 9.0), (-10.09375, 7.0), (-11.09375, 4.0), (3.03125, 3.0), (-9.09375, 6.0), (-12.09375, 8.0), (-0.46875, 4.0), (-2.46875, 5.0), (-12.09375, 5.0), (2.53125, 4.0), (-9.09375, 10.0), (-10.09375, 8.0), (-13.09375, 9.0), (-9.09375, 11.0), (-4.46875, 5.0), (3.53125, 4.0), (-5.46875, 6.0), (-12.09375, 6.0), (5.03125, 3.0), (-1.46875, 5.0), (-10.09375, 9.0), (4.53125, 4.0), (-0.46875, 5.0), (-12.09375, 9.0), (1.53125, 5.0), (5.53125, 4.0), (0.53125, 4.0), (-9.09375, 7.0), (0.53125, 5.0), (-4.09375, 6.0), (-4.59375, 7.0), (-3.59375, 7.0), (-8.09375, 8.0), (-3.46875, 5.0), (-5.09375, 8.0), (-13.09375, 10.0), (-13.09375, 11.0), (-11.09375, 9.0), (-7.09375, 8.0)] |
| DR-054 | Tree | mirror image draws as the reflection: Walker's spreading: leaves between two wide subtrees are spaced evenly | `T: [nil, 0, 1, 1, 1, 0, 0, 0, 7, 7, 7]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-1.5, 1.0), (-2.5, 2.0), (-1.5, 2.0), (-0.5, 2.0), (-0.5, 1.0), (0.5, 1.0), (1.5, 1.0), (0.5, 2.0), (1.5, 2.0), (2.5, 2.0)] |
| DR-055 | Tree | mirror image draws as the reflection: Walker's spreading, deep: wide subtrees meet two levels down | `T: [nil, 0, 1, 2, 2, 2, 0, 0, 0, 8, 9, 9, 9]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-1.5, 1.0), (-1.5, 2.0), (-2.5, 3.0), (-1.5, 3.0), (-0.5, 3.0), (-0.5, 1.0), (0.5, 1.0), (1.5, 1.0), (1.5, 2.0), (0.5, 3.0), (1.5, 3.0), (2.5, 3.0)] |
| DR-056 | Tree | mirror image draws as the reflection: a small subtree between two large ones moves to the middle | `T: [nil, 0, 1, 2, 2, 1, 5, 5, 0, 8, 0, 10, 11, 11, 10, 14, 14]` | `reingoldTilfordLayout()` | [(0.0, 0.0), (-2.0, 1.0), (-3.0, 2.0), (-3.5, 3.0), (-2.5, 3.0), (-1.0, 2.0), (-1.5, 3.0), (-0.5, 3.0), (0.0, 1.0), (0.0, 2.0), (2.0, 1.0), (1.0, 2.0), (0.5, 3.0), (1.5, 3.0), (3.0, 2.0), (2.5, 3.0), (3.5, 3.0)] |
| DR-057 | Tree | isomorphic subtrees are drawn identically (translated) | `T: bal(2,3)` | `x(subtree of 1) − x(1) == x(subtree of 2) − x(2)` | true |
| DR-058 | Tree | circular: one vertex | `T: [nil]` | `reingoldTilfordCircularLayout()` | [(0.0, 0.0)] |
| DR-059 | Tree | circular: star K1,4 | `T: [nil, 0, 0, 0, 0]` | `reingoldTilfordCircularLayout()` | [(0.0, 0.0), (1.0, 0.0), (-0.104528463268, 0.994521895368), (-0.978147600734, -0.207911690818), (0.309016994375, -0.951056516295)] |
| DR-060 | Tree | circular: igraph's example shape | `T: [nil, 0, 0, 0, 1, 1]` | `reingoldTilfordCircularLayout()` | [(0.0, 0.0), (0.5, 0.866025403784), (-1.0, 0.0), (0.5, -0.866025403784), (2.0, 0.0), (-1.0, 1.732050807569)] |
| DR-061 | Tree | circular: binary tree of height 3 | `T: bal(2,3)` | `reingoldTilfordCircularLayout()` | [(0.0, 0.0), (0.309016994375, 0.951056516295), (-0.104528463268, -0.994521895368), (1.827090915285, 0.813473286152), (-1.0, 1.732050807569), (-1.61803398875, -1.175570504585), (1.338261212718, -1.486289650955), (3.0, 0.0), (2.007391819077, 2.229434476432), (-0.313585389803, 2.983565686105), (-2.427050983125, 1.763355756877), (-2.934442802201, -0.623735072453), (-1.5, -2.598076211353), (0.927050983125, -2.853169548885), (2.740636372928, -1.220209929227)] |
| DR-062 | Tree | circular: two chains under a three-way root | `T: [nil, 0, 0, 0, 1, 4, 3, 6]` | `reingoldTilfordCircularLayout()` | [(0.0, 0.0), (1.0, 0.0), (-0.923879532511, 0.382683432365), (0.707106781187, -0.707106781187), (2.0, 0.0), (3.0, 0.0), (1.414213562373, -1.414213562373), (2.12132034356, -2.12132034356)] |
| DR-063 | Tree | circular: random tree, 20 vertices | `T: lcgtree(20,1)` | `reingoldTilfordCircularLayout()` | [(0.0, 0.0), (-0.987688340595, 0.15643446504), (-1.97537668119, 0.31286893008), (0.488621241497, -0.872496007073), (-2.963065021785, 0.469303395121), (-2.476375797239, 3.141267723523), (3.671612547178, 3.394003727665), (-0.466890727712, -1.944739840795), (6.0, 0.0), (1.90211303259, -0.61803398875), (0.470754574367, 5.981504002399), (-3.095469746549, 3.926584654404), (0.549213670095, 6.978421336132), (-3.32587844921, -2.222280932078), (5.874580075485, 5.430405964264), (6.608902584921, 6.109206709796), (-4.952751594479, 6.282535447046), (-5.571845543789, 7.067852377927), (-6.190939493098, 7.853169308807), (-4.157348061513, -2.777851165098)] |
| DR-064 | Layered | empty graph: layers | `D: n=0;` | `sugiyamaLayout() layer(of:) in vertices order` | [] |
| DR-065 | Layered | empty graph: crossings | `D: n=0;` | `sugiyamaLayout().crossingCount` | #0 |
| DR-066 | Layered | empty graph: positions | `D: n=0;` | `sugiyamaLayout().drawing.positions` | [] |
| DR-067 | Layered | one vertex: layers | `D: n=1;` | `sugiyamaLayout() layer(of:) in vertices order` | [0] |
| DR-068 | Layered | one vertex: crossings | `D: n=1;` | `sugiyamaLayout().crossingCount` | #0 |
| DR-069 | Layered | one vertex: positions | `D: n=1;` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0)] |
| DR-070 | Layered | isolated vertices share layer 0, in vertices order: layers | `D: n=3;` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 0, 0] |
| DR-071 | Layered | isolated vertices share layer 0, in vertices order: crossings | `D: n=3;` | `sugiyamaLayout().crossingCount` | #0 |
| DR-072 | Layered | isolated vertices share layer 0, in vertices order: positions | `D: n=3;` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0)] |
| DR-073 | Layered | one arc: layers | `D: 0>1` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1] |
| DR-074 | Layered | one arc: crossings | `D: 0>1` | `sugiyamaLayout().crossingCount` | #0 |
| DR-075 | Layered | one arc: positions | `D: 0>1` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (0.0, 1.0)] |
| DR-076 | Layered | path: layers | `D: P(0,1,2,3)` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 2, 3] |
| DR-077 | Layered | path: crossings | `D: P(0,1,2,3)` | `sugiyamaLayout().crossingCount` | #0 |
| DR-078 | Layered | path: positions | `D: P(0,1,2,3)` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (0.0, 1.0), (0.0, 2.0), (0.0, 3.0)] |
| DR-079 | Layered | diamond: layers | `D: 0>1, 0>2, 1>3, 2>3` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 1, 2] |
| DR-080 | Layered | diamond: crossings | `D: 0>1, 0>2, 1>3, 2>3` | `sugiyamaLayout().crossingCount` | #0 |
| DR-081 | Layered | diamond: positions | `D: 0>1, 0>2, 1>3, 2>3` | `sugiyamaLayout().drawing.positions` | [(0.5, 0.0), (0.0, 1.0), (1.0, 1.0), (0.5, 2.0)] |
| DR-082 | Layered | diamond with a long arc 0>3 (one bend): layers | `D: 0>1, 0>2, 1>3, 2>3, 0>3, 3>4` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 1, 2, 3] |
| DR-083 | Layered | diamond with a long arc 0>3 (one bend): crossings | `D: 0>1, 0>2, 1>3, 2>3, 0>3, 3>4` | `sugiyamaLayout().crossingCount` | #0 |
| DR-084 | Layered | diamond with a long arc 0>3 (one bend): positions | `D: 0>1, 0>2, 1>3, 2>3, 0>3, 3>4` | `sugiyamaLayout().drawing.positions` | [(1.0, 0.0), (0.0, 1.0), (1.0, 1.0), (1.0, 2.0), (1.0, 3.0)] |
| DR-085 | Layered | diamond with a long arc 0>3 (one bend): bends | `D: 0>1, 0>2, 1>3, 2>3, 0>3, 3>4` | `sugiyamaLayout() bends(ofEdgeAt:) where non-empty` | 4: [(2.0, 1.0)] |
| DR-086 | Layered | long arc over two layers (two bends): layers | `D: P(0,1,2,3), 0>3` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 2, 3] |
| DR-087 | Layered | long arc over two layers (two bends): crossings | `D: P(0,1,2,3), 0>3` | `sugiyamaLayout().crossingCount` | #0 |
| DR-088 | Layered | long arc over two layers (two bends): positions | `D: P(0,1,2,3), 0>3` | `sugiyamaLayout().drawing.positions` | [(0.5, 0.0), (0.0, 1.0), (0.0, 2.0), (0.5, 3.0)] |
| DR-089 | Layered | long arc over two layers (two bends): bends | `D: P(0,1,2,3), 0>3` | `sugiyamaLayout() bends(ofEdgeAt:) where non-empty` | 3: [(1.0, 1.0), (1.0, 2.0)] |
| DR-090 | Layered | two sources, one sink: layers | `D: 0>2, 1>2` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 0, 1] |
| DR-091 | Layered | two sources, one sink: crossings | `D: 0>2, 1>2` | `sugiyamaLayout().crossingCount` | #0 |
| DR-092 | Layered | two sources, one sink: positions | `D: 0>2, 1>2` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (1.0, 0.0), (0.5, 1.0)] |
| DR-093 | Layered | crossing in the initial order is removed: layers | `D: 0>3, 1>2` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 0, 1, 1] |
| DR-094 | Layered | crossing in the initial order is removed: crossings | `D: 0>3, 1>2` | `sugiyamaLayout().crossingCount` | #0 |
| DR-095 | Layered | crossing in the initial order is removed: positions | `D: 0>3, 1>2` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)] |
| DR-096 | Layered | K2,2 between layers: one crossing is unavoidable: layers | `D: 0>2, 0>3, 1>2, 1>3` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 0, 1, 1] |
| DR-097 | Layered | K2,2 between layers: one crossing is unavoidable: crossings | `D: 0>2, 0>3, 1>2, 1>3` | `sugiyamaLayout().crossingCount` | #1 |
| DR-098 | Layered | K2,2 between layers: one crossing is unavoidable: positions | `D: 0>2, 0>3, 1>2, 1>3` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)] |
| DR-099 | Layered | K3,3 between layers: 9 crossings at least: layers | `D: 0>3, 0>4, 0>5, 1>3, 1>4, 1>5, 2>3, 2>4, 2>5` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 0, 0, 1, 1, 1] |
| DR-100 | Layered | K3,3 between layers: 9 crossings at least: crossings | `D: 0>3, 0>4, 0>5, 1>3, 1>4, 1>5, 2>3, 2>4, 2>5` | `sugiyamaLayout().crossingCount` | #9 |
| DR-101 | Layered | K3,3 between layers: 9 crossings at least: positions | `D: 0>3, 0>4, 0>5, 1>3, 1>4, 1>5, 2>3, 2>4, 2>5` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (0.0, 1.0), (1.0, 1.0), (2.0, 1.0)] |
| DR-102 | Layered | binary out-tree: layers | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 1, 2, 2, 2, 2] |
| DR-103 | Layered | binary out-tree: crossings | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `sugiyamaLayout().crossingCount` | #0 |
| DR-104 | Layered | binary out-tree: positions | `D: 0>1, 0>2, 1>3, 1>4, 2>5, 2>6` | `sugiyamaLayout().drawing.positions` | [(1.5, 0.0), (0.5, 1.0), (2.5, 1.0), (0.0, 2.0), (1.0, 2.0), (2.0, 2.0), (3.0, 2.0)] |
| DR-105 | Layered | three layers, crossings in both gaps: layers | `D: 0>4, 1>3, 2>5, 3>8, 4>6, 5>7` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 0, 0, 1, 1, 1, 2, 2, 2] |
| DR-106 | Layered | three layers, crossings in both gaps: crossings | `D: 0>4, 1>3, 2>5, 3>8, 4>6, 5>7` | `sugiyamaLayout().crossingCount` | #0 |
| DR-107 | Layered | three layers, crossings in both gaps: positions | `D: 0>4, 1>3, 2>5, 3>8, 4>6, 5>7` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (1.0, 1.0), (0.0, 1.0), (2.0, 1.0), (0.0, 2.0), (2.0, 2.0), (1.0, 2.0)] |
| DR-108 | Layered | parallel arcs: two edges, no bends: layers | `D: 0>1, 0>1` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1] |
| DR-109 | Layered | parallel arcs: two edges, no bends: crossings | `D: 0>1, 0>1` | `sugiyamaLayout().crossingCount` | #0 |
| DR-110 | Layered | parallel arcs: two edges, no bends: positions | `D: 0>1, 0>1` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (0.0, 1.0)] |
| DR-111 | Layered | self-loop ignored in layering, no bends: layers | `D: 0>0, 0>1` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1] |
| DR-112 | Layered | self-loop ignored in layering, no bends: crossings | `D: 0>0, 0>1` | `sugiyamaLayout().crossingCount` | #0 |
| DR-113 | Layered | self-loop ignored in layering, no bends: positions | `D: 0>0, 0>1` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (0.0, 1.0)] |
| DR-114 | Layered | 2-cycle: one arc reversed: reversed edges (Eades–Lin–Smyth) | `D: 0>1, 1>0` | `sugiyamaLayout().reversedEdges` | [1] |
| DR-115 | Layered | 2-cycle: one arc reversed: layers | `D: 0>1, 1>0` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1] |
| DR-116 | Layered | 2-cycle: one arc reversed: crossings | `D: 0>1, 1>0` | `sugiyamaLayout().crossingCount` | #0 |
| DR-117 | Layered | 2-cycle: one arc reversed: positions | `D: 0>1, 1>0` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (0.0, 1.0)] |
| DR-118 | Layered | 3-cycle: one arc reversed: reversed edges (Eades–Lin–Smyth) | `D: C(0,1,2)` | `sugiyamaLayout().reversedEdges` | [2] |
| DR-119 | Layered | 3-cycle: one arc reversed: layers | `D: C(0,1,2)` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 2] |
| DR-120 | Layered | 3-cycle: one arc reversed: crossings | `D: C(0,1,2)` | `sugiyamaLayout().crossingCount` | #0 |
| DR-121 | Layered | 3-cycle: one arc reversed: positions | `D: C(0,1,2)` | `sugiyamaLayout().drawing.positions` | [(0.5, 0.0), (0.0, 1.0), (0.5, 2.0)] |
| DR-122 | Layered | 3-cycle: one arc reversed: bends | `D: C(0,1,2)` | `sugiyamaLayout() bends(ofEdgeAt:) where non-empty` | 2: [(1.0, 1.0)] |
| DR-123 | Layered | cycle with a tail: reversed edges (Eades–Lin–Smyth) | `D: C(0,1,2,3), 3>4, 4>5` | `sugiyamaLayout().reversedEdges` | [3] |
| DR-124 | Layered | cycle with a tail: layers | `D: C(0,1,2,3), 3>4, 4>5` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 2, 3, 4, 5] |
| DR-125 | Layered | cycle with a tail: crossings | `D: C(0,1,2,3), 3>4, 4>5` | `sugiyamaLayout().crossingCount` | #0 |
| DR-126 | Layered | cycle with a tail: positions | `D: C(0,1,2,3), 3>4, 4>5` | `sugiyamaLayout().drawing.positions` | [(0.5, 0.0), (0.0, 1.0), (0.0, 2.0), (0.5, 3.0), (0.5, 4.0), (0.5, 5.0)] |
| DR-127 | Layered | cycle with a tail: bends | `D: C(0,1,2,3), 3>4, 4>5` | `sugiyamaLayout() bends(ofEdgeAt:) where non-empty` | 3: [(1.0, 2.0), (1.0, 1.0)] |
| DR-128 | Layered | two 3-cycles sharing a vertex: reversed edges (Eades–Lin–Smyth) | `D: C(0,1,2), C(0,3,4)` | `sugiyamaLayout().reversedEdges` | [2, 5] |
| DR-129 | Layered | two 3-cycles sharing a vertex: layers | `D: C(0,1,2), C(0,3,4)` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 2, 1, 2] |
| DR-130 | Layered | two 3-cycles sharing a vertex: crossings | `D: C(0,1,2), C(0,3,4)` | `sugiyamaLayout().crossingCount` | #0 |
| DR-131 | Layered | two 3-cycles sharing a vertex: positions | `D: C(0,1,2), C(0,3,4)` | `sugiyamaLayout().drawing.positions` | [(1.5, 0.0), (0.0, 1.0), (0.5, 2.0), (2.0, 1.0), (2.5, 2.0)] |
| DR-132 | Layered | two 3-cycles sharing a vertex: bends | `D: C(0,1,2), C(0,3,4)` | `sugiyamaLayout() bends(ofEdgeAt:) where non-empty` | 2: [(1.0, 1.0)]; 5: [(3.0, 1.0)] |
| DR-133 | Layered | tournament on 4 vertices with one cycle: reversed edges (Eades–Lin–Smyth) | `D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3` | `sugiyamaLayout().reversedEdges` | [2] |
| DR-134 | Layered | tournament on 4 vertices with one cycle: layers | `D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 2, 3] |
| DR-135 | Layered | tournament on 4 vertices with one cycle: crossings | `D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3` | `sugiyamaLayout().crossingCount` | #0 |
| DR-136 | Layered | tournament on 4 vertices with one cycle: positions | `D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3` | `sugiyamaLayout().drawing.positions` | [(1.0, 0.0), (0.0, 1.0), (1.0, 2.0), (1.0, 3.0)] |
| DR-137 | Layered | tournament on 4 vertices with one cycle: bends | `D: 0>1, 1>2, 2>0, 0>3, 1>3, 2>3` | `sugiyamaLayout() bends(ofEdgeAt:) where non-empty` | 2: [(1.0, 1.0)]; 3: [(2.0, 1.0), (2.0, 2.0)]; 4: [(0.0, 2.0)] |
| DR-138 | Layered | transitive tournament on 4: layers | `D: 0>1, 0>2, 0>3, 1>2, 1>3, 2>3` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 2, 3] |
| DR-139 | Layered | transitive tournament on 4: crossings | `D: 0>1, 0>2, 0>3, 1>2, 1>3, 2>3` | `sugiyamaLayout().crossingCount` | #0 |
| DR-140 | Layered | transitive tournament on 4: positions | `D: 0>1, 0>2, 0>3, 1>2, 1>3, 2>3` | `sugiyamaLayout().drawing.positions` | [(1.0, 0.0), (0.0, 1.0), (1.0, 2.0), (1.0, 3.0)] |
| DR-141 | Layered | transitive tournament on 4: bends | `D: 0>1, 0>2, 0>3, 1>2, 1>3, 2>3` | `sugiyamaLayout() bends(ofEdgeAt:) where non-empty` | 1: [(1.0, 1.0)]; 2: [(2.0, 1.0), (2.0, 2.0)]; 4: [(0.0, 2.0)] |
| DR-142 | Layered | arcs given against vertex order: layers | `D: n=4; 3>2, 2>1, 1>0` | `sugiyamaLayout() layer(of:) in vertices order` | [3, 2, 1, 0] |
| DR-143 | Layered | arcs given against vertex order: crossings | `D: n=4; 3>2, 2>1, 1>0` | `sugiyamaLayout().crossingCount` | #0 |
| DR-144 | Layered | arcs given against vertex order: positions | `D: n=4; 3>2, 2>1, 1>0` | `sugiyamaLayout().drawing.positions` | [(0.0, 3.0), (0.0, 2.0), (0.0, 1.0), (0.0, 0.0)] |
| DR-145 | Layered | two components: layers | `D: 0>1, 2>3, 2>4` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 1, 0, 1, 1] |
| DR-146 | Layered | two components: crossings | `D: 0>1, 2>3, 2>4` | `sugiyamaLayout().crossingCount` | #0 |
| DR-147 | Layered | two components: positions | `D: 0>1, 2>3, 2>4` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (0.0, 1.0), (1.5, 0.0), (1.0, 1.0), (2.0, 1.0)] |
| DR-148 | Layered | random DAG, 12 vertices, 18 arcs: layers | `D: lcgdag(12,18,1)` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 0, 0, 2, 1, 1, 1, 1, 1, 2, 3, 4] |
| DR-149 | Layered | random DAG, 12 vertices, 18 arcs: crossings | `D: lcgdag(12,18,1)` | `sugiyamaLayout().crossingCount` | #5 |
| DR-150 | Layered | random DAG, 12 vertices, 18 arcs: positions | `D: lcgdag(12,18,1)` | `sugiyamaLayout().drawing.positions` | [(1.0, 0.0), (2.0, 0.0), (4.5, 0.0), (1.0, 2.0), (4.5, 1.0), (0.0, 1.0), (1.5, 1.0), (2.5, 1.0), (3.5, 1.0), (4.5, 2.0), (4.0, 3.0), (4.0, 4.0)] |
| DR-151 | Layered | random DAG, 12 vertices, 18 arcs: bends | `D: lcgdag(12,18,1)` | `sugiyamaLayout() bends(ofEdgeAt:) where non-empty` | 0: [(5.5, 1.0)]; 2: [(0.0, 2.0), (0.0, 3.0)]; 3: [(6.5, 1.0), (6.5, 2.0)]; 17: [(2.0, 2.0)] |
| DR-152 | Layered | random DAG, 15 vertices, 25 arcs: total edge span (optimal layering not unique; layers and positions not pinned) | `D: lcgdag(15,25,2)` | `sugiyamaLayout() Σ span` | #44 |
| DR-153 | Layered | random digraph with cycles, 10 vertices, 16 arcs: reversed edges (Eades–Lin–Smyth) | `D: lcggraph(10,16,3)` | `sugiyamaLayout().reversedEdges` | [5] |
| DR-154 | Layered | random digraph with cycles, 10 vertices, 16 arcs: layers | `D: lcggraph(10,16,3)` | `sugiyamaLayout() layer(of:) in vertices order` | [0, 0, 5, 4, 3, 0, 1, 0, 1, 2] |
| DR-155 | Layered | random digraph with cycles, 10 vertices, 16 arcs: crossings | `D: lcggraph(10,16,3)` | `sugiyamaLayout().crossingCount` | #0 |
| DR-156 | Layered | random digraph with cycles, 10 vertices, 16 arcs: positions | `D: lcggraph(10,16,3)` | `sugiyamaLayout().drawing.positions` | [(0.0, 0.0), (1.0, 0.0), (3.0, 5.0), (3.0, 4.0), (5.0, 3.0), (3.5, 0.0), (2.0, 1.0), (2.0, 0.0), (3.0, 1.0), (3.0, 2.0)] |
| DR-157 | Layered | random digraph with cycles, 10 vertices, 16 arcs: bends | `D: lcggraph(10,16,3)` | `sugiyamaLayout() bends(ofEdgeAt:) where non-empty` | 0: [(3.0, 3.0)]; 9: [(5.0, 1.0), (5.0, 2.0)]; 11: [(1.0, 1.0)]; 13: [(0.0, 1.0), (0.0, 2.0), (0.0, 3.0)]; 15: [(4.0, 1.0)] |
| DR-158 | Layered | caller layers: a long arc and its bend | `D: 0>1, 0>2, 1>3` | `sugiyamaLayout(layers: [0, 2, 1, 3]) positions` | [(0.5, 0.0), (1.0, 2.0), (0.0, 1.0), (1.0, 3.0)] |
| DR-159 | Layered | caller layers: bends | `D: 0>1, 0>2, 1>3` | `sugiyamaLayout(layers: [0, 2, 1, 3]) bends(ofEdgeAt: 0)` | [(1.0, 1.0)] |
| DR-160 | Layered | caller layers: an upward arc is reversed, a flat arc has no segment | `D: 0>1, 0>2, 1>3` | `sugiyamaLayout(layers: [1, 0, 1, 1]).reversedEdges` | [0] |
| DR-161 | Layered | caller layers: negative layer | `D: 0>1` | `sugiyamaLayout(layers: [-1, 0])` | **trap** |
| DR-162 | Layered | maxIterations: 0 keeps the initial order | `D: 0>3, 1>2` | `sugiyamaLayout(maxIterations: 0).crossingCount` | #1 |
| DR-163 | Layered | DirectedAcyclicGraph: no edge is reversed | `D: lcgdag(15,25,2)` as `DirectedAcyclicGraph` | `sugiyamaLayout().reversedEdges` | [] |
| DR-164 | Layered | layer(of:) on a missing vertex | `D: 0>1` | `sugiyamaLayout().layer(of: 9)` | **trap** |
| DR-165 | Layered | bends(ofEdgeAt:) on a missing edge | `D: 0>1` | `sugiyamaLayout().bends(ofEdgeAt: 5)` | **trap** |
| DR-166 | ForceDirected | initial positions: x then y per vertex, uniform in [0, 1), seed 1 | `U: n=3;` | `fruchtermanReingoldLayout(iterations: 0, using: &Xoshiro256StarStar(seed: 1))` | [(0.7029218331588505, 0.5204366199388569), (0.5741057000197225, 0.39132860204190445), (0.6971784165599615, 0.1435720367444362)] |
| DR-167 | ForceDirected | initial positions: exactly 2n draws, seed 1 | `U: n=3;` | `draws by fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: 1))` | #6 |
| DR-168 | ForceDirected | initial positions: x then y per vertex, uniform in [0, 1), seed 42 | `U: n=5;` | `fruchtermanReingoldLayout(iterations: 0, using: &Xoshiro256StarStar(seed: 42))` | [(0.08386297105988216, 0.3789802506626686), (0.6800434110281394, 0.9246929453253876), (0.9918039142821028, 0.7697394604342425), (0.7192585778779156, 0.8500084439109727), (0.7613743810057634, 0.5833493097373993)] |
| DR-169 | ForceDirected | initial positions: exactly 2n draws, seed 42 | `U: n=5;` | `draws by fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: 42))` | #10 |
| DR-170 | ForceDirected | empty graph: empty drawing, no draws | `U: n=0;` | `fruchtermanReingoldLayout(using: &g)` | [] (#0 draws) |
| DR-171 | ForceDirected | one vertex: stays at its initial position | `U: n=1;` | `fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: 1))` | [(0.7029218331588505, 0.5204366199388569)] |
| DR-172 | ForceDirected | same seed, same drawing | `U: grid(5,5)` | `two calls with Xoshiro256StarStar(seed: 9)` | equal |
| DR-173 | ForceDirected | initial: drawing missing a vertex | `U: P(0,1,2)` | `fruchtermanReingoldLayout(initial: Drawing(vertices: [0, 1], …))` | **trap** |
| DR-174 | ForceDirected | step() after the last iteration changes nothing | `U: P(0,1,2)` | `FruchtermanReingoldLayout(iterations: 2): step() x 3` | isFinished; drawing equal after steps 2 and 3 |
| DR-175 | ForceDirected | step() count: iterations steps, or fewer when converged | `U: grid(5,5)` | `FruchtermanReingoldLayout(iterations: 50).iteration after run` | ≤ 50 |
| DR-176 | ForceDirected | iterations: -1 | `U: P(0,1,2)` | `fruchtermanReingoldLayout(iterations: -1, using: &g)` | **trap** |
| DR-177 | ForceDirected | two vertices joined by an edge end at distance k (the optimal distance) | `U: 0-1` | `fruchtermanReingoldLayout(iterations: 500, optimalDistance: 1, using: &Xoshiro256StarStar(seed: 1)) distance` | 1.0 ± 1e-3 |
| DR-178 | ForceDirected | Fruchterman–Reingold quality, cycle C12 (median normalized stress over seeds 1…20; NetworkX 0.0171, model 0.0173) | `U: C(0,1,2,3,4,5,6,7,8,9,10,11)` | `fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s))` | ≤ 0.019 |
| DR-179 | ForceDirected | Fruchterman–Reingold quality, grid 5 x 5 (median normalized stress over seeds 1…20; NetworkX 0.0243, model 0.0251) | `U: grid(5,5)` | `fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s))` | ≤ 0.027 |
| DR-180 | ForceDirected | Fruchterman–Reingold quality, binary tree of height 4 (as a graph) (median normalized stress over seeds 1…20; NetworkX 0.0848, model 0.0830) | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 2-6, 3-7, 3-8, 4-9, 4-10, 5-11, 5-12, 6-13, 6-14, 7-15, 7-16, 8-17, 8-18, 9-19, 9-20, 10-21, 10-22, 11-23, 11-24, 12-25, 12-26, 13-27, 13-28, 14-29, 14-30` | `fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s))` | ≤ 0.094 |
| DR-181 | ForceDirected | Fruchterman–Reingold quality, cube Q4 (median normalized stress over seeds 1…20; NetworkX 0.1289, model 0.1286) | `U: Q(4)` | `fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s))` | ≤ 0.142 |
| DR-182 | ForceDirected | Fruchterman–Reingold quality, Petersen (median normalized stress over seeds 1…20; NetworkX 0.1212, model 0.1213) | `U: petersen` | `fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s))` | ≤ 0.134 |
| DR-183 | ForceDirected | Fruchterman–Reingold quality, random graph, 40 vertices, 60 edges (median normalized stress over seeds 1…20; NetworkX 0.1022, model 0.1029) | `U: lcggraph(40,60,5)` | `fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s))` | ≤ 0.113 |
| DR-184 | ForceDirected | Fruchterman–Reingold crossings, cycle C12 (median over seeds 1…20; NetworkX 0, model 0) | `U: C(0,1,2,3,4,5,6,7,8,9,10,11)` | `fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s))` | ≤ 0 |
| DR-185 | ForceDirected | Fruchterman–Reingold crossings, binary tree of height 4 (median over seeds 1…20; NetworkX 1, model 1) | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 2-6, 3-7, 3-8, 4-9, 4-10, 5-11, 5-12, 6-13, 6-14, 7-15, 7-16, 8-17, 8-18, 9-19, 9-20, 10-21, 10-22, 11-23, 11-24, 12-25, 12-26, 13-27, 13-28, 14-29, 14-30` | `fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s))` | ≤ 1 |
| DR-186 | ForceDirected | Barnes–Hut (θ = 1.2) within 15% of exact repulsion, grid 5 x 5 (exact model 0.0251) | `U: grid(5,5)` | `fruchtermanReingoldLayout(barnesHutTheta: 1.2, using: &Xoshiro256StarStar(seed: s)), median` | ≤ 0.029 |
| DR-187 | ForceDirected | Barnes–Hut (θ = 1.2) within 15% of exact repulsion, random graph, 40 vertices, 60 edges (exact model 0.1029) | `U: lcggraph(40,60,5)` | `fruchtermanReingoldLayout(barnesHutTheta: 1.2, using: &Xoshiro256StarStar(seed: s)), median` | ≤ 0.119 |
| DR-188 | ForceDirected | Barnes–Hut θ = 0 is exact repulsion | `U: grid(5,5)` | `fruchtermanReingoldLayout(barnesHutTheta: 0, …) == fruchtermanReingoldLayout(…)` | equal up to 1e-9 |
| DR-189 | ForceDirected | Barnes–Hut θ < 0 | `U: P(0,1,2)` | `fruchtermanReingoldLayout(barnesHutTheta: -1, using: &g)` | **trap** |
| DR-190 | Stress | one vertex | `U: n=1;` | `stressMajorizationLayout()` | [(0.0, 0.0)]; stress 0.0 |
| DR-191 | Stress | one edge | `U: 0-1` | `stressMajorizationLayout()` | [(0.0, 0.0), (-1.0, 0.0)]; stress 0.0 |
| DR-192 | Stress | path of 3 | `U: P(0,1,2)` | `stressMajorizationLayout()` | stress ≤ 0.001, normalized ≤ 0.0002 (NetworkX Kamada–Kawai 0.0000) |
| DR-193 | Stress | cycle C6 | `U: C(0,1,2,3,4,5)` | `stressMajorizationLayout()` | stress ≈ 0.284088 (±1%), normalized ≤ 0.0195 (NetworkX Kamada–Kawai 0.0189) |
| DR-194 | Stress | K4 | `U: K(4)` | `stressMajorizationLayout()` | stress ≈ 0.171576 (±1%), normalized ≤ 0.0293 (NetworkX Kamada–Kawai 0.0286) |
| DR-195 | Stress | cycle C12 | `U: C(0,1,2,3,4,5,6,7,8,9,10,11)` | `stressMajorizationLayout()` | stress ≈ 1.08869 (±1%), normalized ≤ 0.017 (NetworkX Kamada–Kawai 0.0165) |
| DR-196 | Stress | grid 5 x 5 | `U: grid(5,5)` | `stressMajorizationLayout()` | stress ≈ 6.61757 (±1%), normalized ≤ 0.0226 (NetworkX Kamada–Kawai 0.0221) |
| DR-197 | Stress | binary tree of height 4 (as a graph) | `U: 0-1, 0-2, 1-3, 1-4, 2-5, 2-6, 3-7, 3-8, 4-9, 4-10, 5-11, 5-12, 6-13, 6-14, 7-15, 7-16, 8-17, 8-18, 9-19, 9-20, 10-21, 10-22, 11-23, 11-24, 12-25, 12-26, 13-27, 13-28, 14-29, 14-30` | `stressMajorizationLayout()` | stress ≈ 18.0323 (±1%), normalized ≤ 0.0397 (NetworkX Kamada–Kawai 0.0388) |
| DR-198 | Stress | cube Q4 | `U: Q(4)` | `stressMajorizationLayout()` | stress ≈ 15.3057 (±1%), normalized ≤ 0.2572 (NetworkX Kamada–Kawai 0.2520) |
| DR-199 | Stress | Petersen | `U: petersen` | `stressMajorizationLayout()` | stress ≈ 5.23048 (±1%), normalized ≤ 0.1195 (NetworkX Kamada–Kawai 0.1170) |
| DR-200 | Stress | random graph, 40 vertices, 60 edges | `U: lcggraph(40,60,5)` | `stressMajorizationLayout()` | stress ≈ 74.6895 (±1%), normalized ≤ 0.0969 (NetworkX Kamada–Kawai 0.0913; above it at the default tolerance, 0.0869 at tolerance 1e-5) |
| DR-201 | Stress | two components: a triangle and an edge | `U: C(0,1,2), 3-4` | `stressMajorizationLayout()` | stress ≈ 0.0794909 (±1%) |
| DR-202 | Stress | stress never increases between steps | `U: grid(5,5)` | `StressMajorizationLayout: stress after each step()` | non-increasing |
| DR-203 | Stress | initial drawing is used as given (no randomness) | `U: grid(5,5)` | `two calls` | equal |
| DR-204 | Stress | edge length 2 doubles the drawing | `U: C(0,1,2,3,4,5)` | `stressMajorizationLayout(edgeLength: { _ in 2 }) vs default` | positions × 2 (exact) |
| DR-205 | Stress | edge length ≤ 0 | `U: 0-1` | `stressMajorizationLayout(edgeLength: { _ in 0 })` | **trap** |
| DR-206 | Stress | tolerance < 0 | `U: 0-1` | `stressMajorizationLayout(tolerance: -1)` | **trap** |
| DR-207 | Phase 2 | spectral: path of 5 (Fiedler vector, then the third) | `U: P(0,1,2,3,4)` | `spectralLayout()` | [(0.601500955, 0.511667274), (0.371748034, -0.195439508), (0.0, -0.632455532), (-0.371748034, -0.195439508), (-0.601500955, 0.511667274)] |
| DR-208 | Phase 2 | spectral: grid 3 x 4 (Fiedler vector, then the third) | `U: grid(3,4)` | `spectralLayout()` | [(0.37717224, 0.353553391), (0.156229857, 0.353553391), (-0.156229857, 0.353553391), (-0.37717224, 0.353553391), (0.37717224, 0.0), (0.156229857, 0.0), (-0.156229857, 0.0), (-0.37717224, 0.0), (0.37717224, -0.353553391), (0.156229857, -0.353553391), (-0.156229857, -0.353553391), (-0.37717224, -0.353553391)] |
| DR-209 | Phase 2 | spectral: random graph, 12 vertices, 20 edges (Fiedler vector, then the third) | `U: lcggraph(12,20,9)` | `spectralLayout()` | [(0.119991788, 0.208651719), (0.419905181, -0.207746264), (-0.206606006, -0.00394076), (0.560565123, -0.541758472), (-0.269412496, -0.157327642), (0.227769069, 0.300045203), (-0.149251974, 0.047165543), (-0.286239529, -0.121372597), (-0.320589267, -0.195278678), (-0.083030931, 0.074618896), (0.232126938, 0.663287182), (-0.245227896, -0.06634413)] |
| DR-210 | Phase 2 | spectral: path of 5 has x = the Fiedler vector, y = the next eigenvector | `U: P(0,1,2,3,4)` | `spectralLayout() vs fiedlerVector()` | x equal |
| DR-211 | Phase 2 | bfs layout (NetworkX bfs_layout, start 0) | `U: P(0,1,2), 1-3, 3-4` | `bfsLayout(start: 0)` | [(-1.0, 0.0), (-0.375, 0.0), (0.25, -0.3125), (0.25, 0.3125), (0.875, 0.0)] |
| DR-212 | Phase 2 | multipartite layout (NetworkX multipartite_layout) | `U: n=5; 0-2, 1-3, 2-4` layers [0, 0, 1, 1, 2] | `multipartiteLayout(layer: { [0, 0, 1, 1, 2][$0] })` | [(-0.666666666667, -0.416666666667), (-0.666666666667, 0.416666666667), (0.166666666667, -0.416666666667), (0.166666666667, 0.416666666667), (1.0, 0.0)] |
| DR-213 | Phase 2 | ForceAtlas2 quality, grid 5 x 5 (NetworkX median 0.0305) | `U: grid(5,5)` | `forceAtlas2Layout(using: &Xoshiro256StarStar(seed: s)), median over 1…20` | ≤ 0.034 |
| DR-214 | Phase 2 | ForceAtlas2 quality, random graph, 40 vertices, 60 edges (NetworkX median 0.1101) | `U: lcggraph(40,60,5)` | `forceAtlas2Layout(using: &Xoshiro256StarStar(seed: s)), median over 1…20` | ≤ 0.122 |

214 rows.
