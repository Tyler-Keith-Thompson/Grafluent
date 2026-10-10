# Cycles: case catalog (CY-001 – CY-879)

Cases for the Cycles module's phase 1 (api.md): undirected `isAcyclic`, `findCycle()`,
`findCycle(from:)`, `cycleBasis()`, `simpleCycles(maxLength:)` on `Graph` and `DirectedGraph`,
and `girth()` on both, plus deferred sections (chordless cycles, minimum cycle bases) kept so
phase 2 starts from checked values. Harvested from NetworkX `test_cycles.py`, JGraphT
(`DirectedSimpleCyclesTest`, `HawickJamesSimpleCyclesTest`, `PatonCycleBaseTest`,
`GraphMetricsTest`), igraph (`igraph_simple_cycles.c`, `igraph_find_cycle.c`, `cycle_bases.c`,
`igraph_girth.c`), Boost (`hawick_circuits.cpp`, `tiernan_all_cycles.cpp`, reproduced exactly by
`boostprobe/main.cpp` against Boost 1.87), and rustworkx (`test_simple_cycles.py`,
`test_cycle_basis.py`, `test_find_cycle.py`).

## Notation

**Graph** cells are read by `ref.py`. `D:` marks a directed graph. An optional vertex list in
brackets comes first, then edges in **position order** (position `k` is the `k`th edge written):

| Token | Edges |
|---|---|
| `u-v`, `u>v` | one edge (undirected), one arc (directed). Negative vertices are written `3--2`, `-2--3` |
| `P(a,b,c,…)` | the path a–b, b–c, … (arcs in a `D:` graph) |
| `C(a,b,…,z)` | the cycle a–b, …, z–a (a directed cycle in a `D:` graph) |
| `K(a..b)`, `K(n)` | every pair i < j, lexicographic; `K(n)` is `K(0..n-1)` |
| `DK(n)` | every arc i>j, i ≠ j, row-major over 0..n−1 (NetworkX `complete_graph(n).to_directed()`, rustworkx `directed_mesh_graph`); vertices listed |
| `DKL(n)` | every arc i>j including i = j, row-major (JGraphT `DirectedSimpleCyclesTest`) |
| `TT(n)` | every arc x>y for y < x, row-major (NetworkX's acyclic tournament, igraph `full_citation`) |
| `S(c;a..b)` | the star c–a, …, c–b |
| `W(c;a..b)` | the star c–a..b, then the rim cycle a..b (igraph `igraph_wheel` with center c) |
| `KB(a..b;c..d)` | complete bipartite: each of the first list to each of the second, row-major |
| `grid(r,c)` | vertices `i*c + j` listed row-major; for each vertex in that order the edge right, then down |
| `kary(n,k)` | igraph `kary_tree`: vertex i to k·i+1 … k·i+k below n |
| `johnson(k)` | Johnson (1975) figure 1, in NetworkX's edge order (`test_cycles.py` `worst_case_graph`), its one repeated arc (2k+1)>(2k+2) written once as `nx.DiGraph` keeps it: 3k cycles |
| `nx(name)` | `networkx.<name>_graph()`: its `nodes` listed, then `edges()` in NetworkX's order |
| `hamladder(n)` | NetworkX's giant-Hamiltonian graph: for each v, the edge v–(v+2) when v is even, then v–(v+1), mod n |
| `a..b` | every integer from a to b inclusive |
| `~rev`, `~rot` | at the end: every vertex's incidence row reversed, or rotated left by one: a representation whose `incidentEdges` (`outEdges`) order is not position order, such as `UndirectedAdjacencyList` after removals. Write it as a private conformer |

**Vertex order** (`vertices`) is the listed vertices, then endpoints by first appearance: exactly
`ReferencePseudograph(vertices:edges:)` and `ReferenceDirectedMultigraph`. Rows (`incidentEdges`,
`outEdges`) are in position order, a self-loop twice in an undirected row, unless `~rev`/`~rot`.

**Op** names the call: `isAcyclic`; `findCycle`, `findCycle(from: [r, …])`; `cycleBasis`;
`basisCount` (`cycleBasis().count`); `simpleCycles`, `simpleCycles(maxLength: k)` (every cycle,
in emitted order); `count`, `count(maxLength: k)` (the number of cycles emitted);
`directedCount` (`graph.directed.simpleCycles().count`, the undirected graph read as two arcs per
edge); `girth`; deferred: `chordlessCycles`, `chordlessCount`, `minimumCycleBasisLengths`.

**Expected** cells:

| Form | Meaning |
|---|---|
| `[v0,v1,…]/[e0,e1,…]` | a cycle: its vertices from its start, and its edge positions (edge i joins vertex i and vertex i+1 mod n); a list is separated by `;` in emitted order |
| `none`, `nil` | no cycle emitted; no cycle found / no girth (acyclic) |
| `#k` | a count; `T` / `F` a Boolean |

Every cycle is in api.md's canonical form: it starts at its least vertex (in `vertices` order),
and an undirected cycle leaves that vertex through the lesser of its two edges there (by position);
`simpleCycles` emits by least vertex, then lexicographically by each edge's offset in its
vertex's row along the canonical orientation.

**Source** cells name the library and test, and state the library's own value where it is
checkable; `ref.py` checks every one under that library's semantics:

| Claim | Checked as |
|---|---|
| `nx#k`, `rx#k` | NetworkX / rustworkx `simple_cycles`: cycles collapsed to vertex sequences, up to rotation (and reversal, undirected) |
| `ig#k`, `jg#k` | igraph `simple_cycles`, JGraphT `findSimpleCycles`: edge identity, our count |
| `bh#k`, `bhu#k` | Boost `hawick_circuits` (edge multiplicity; an undirected graph as two arcs per edge, a loop twice) and `hawick_unique_circuits` (vertex sequences) |
| `bt#k` | Boost `tiernan_all_cycles`: vertex sequences, no self-loops; undirected cycles of length ≥ 3 in both directions |
| `nxb#k`, `igb#k` | `cycle_basis` / `fundamental_cycles` size |
| `nxg=k`, `jgg=k`, `igg=k`, `btg=k` | girth: NetworkX and JGraphT (loops 1, parallel pairs 2), igraph (loops and multi-edges ignored), Boost `tiernan_girth_and_circumference` (no loops, no undirected 2-cycles; 0 when acyclic) |

`ref.py` recomputes every Expected cell from brute force (two independent enumerations, the sort
key computed per cycle), runs api.md's algorithm in Python and requires the same cycles in the
same order, and cross-checks NetworkX 3.7 (and python-igraph 1.0 when run `--with igraph`) on
every graph row.

`ref.py` also plants six mistakes and lists the rows that catch them. P3 (emitting both
orientations of undirected cycles) fails 66 rows; P4 (`findCycle` skipping the parent vertex, not
the parent edge) fails CY-008, CY-010, CY-013, CY-024, CY-033; P5 (a self-loop emitted once per
incidence) fails 16 rows (CY-325 – CY-327, CY-400, CY-401, CY-404, CY-406, CY-418 – CY-421,
CY-460 – CY-463, CY-498); P6 (ordering by the first edge's position instead of the least vertex)
fails CY-210, CY-248, CY-326, CY-328, CY-331, CY-420 – CY-422, CY-704 – CY-706; P2 (a bounded
undirected search not counting other-orientation closures as found) fails only CY-491 and the
shuffled-row random graphs. P1 (not counting the closure back along the edge just taken as found)
fails nothing, by design (api.md).

python-igraph 1.0.0 is wrong on two rows, CY-244 (111 for 113) and CY-252 (none for one); Boost
and NetworkX agree with brute force on both, and `ref.py` reports them as known.

## A. Undirected cycle detection (CY-001 – CY-049)

| ID | Source | Graph | Op | Expected | Note |
|---|---|---|---|---|---|
| CY-001 | igraph null graph | `[]` | `isAcyclic` | `T` | The empty graph is acyclic (and a forest) |
| CY-002 | igraph null graph | `[]` | `findCycle` | `nil` |  |
| CY-003 | K₁ | `[0]` | `isAcyclic` | `T` |  |
| CY-004 | igraph several isolated vertices | `[0..4]` | `findCycle` | `nil` |  |
| CY-005 | K₂ | `0-1` | `isAcyclic` | `T` | One edge is not a 2-cycle: an undirected walk may not reuse it |
| CY-006 | petgraph `is_cyclic_undirected`, NetworkX | `0-0` | `isAcyclic` | `F` | A self-loop is a cycle |
| CY-007 | NetworkX `test_simple_cycles_singleton` | `0-0` | `findCycle` | `[0]/[0]` | Listed twice in the row, found once |
| CY-008 | igraph, JGraphT multigraph | `0-1 0-1` | `findCycle` | `[0,1]/[0,1]` | A parallel pair is a 2-cycle |
| CY-009 | igraph `find_cycle` isolated vertices with self-loops | `[0..2] 1-1 1-1 2-2` | `findCycle` | `[1]/[0]` | igraph: vertices (1), edges (0) |
| CY-010 | igraph `find_cycle` small undirected multigraph | `[0..4] 1-2 3-4 3-4 3-4` | `findCycle` | `[3,4]/[1,2]` | igraph: vertices (4 3), edges (1 2): the same cycle, other start |
| CY-011 | NetworkX `TestFindCycle` (`nx.Graph`, repeats collapsed) | `-1-0 0-1 2-1 3-1` | `isAcyclic` | `T` | `test_graph_nocycle` |
| CY-012 | NetworkX `test_graph_nocycle` | `-1-0 0-1 2-1 3-1` | `findCycle(from: [0,1,2,3])` | `nil` |  |
| CY-013 | NetworkX `test_multigraph` (`nx.MultiGraph`) | `-1-0 0-1 1-0 1-0 2-1 3-1` | `findCycle(from: [0,1,2,3])` | `[0,1]/[1,2]` | NetworkX: `[(0,1,0),(1,0,1)]` "or (1,0,2)"; ours is pinned: the second copy |
| CY-014 | NetworkX `test_graph_cycle` | `-1-0 0-1 2-1 3-1 2-0` | `findCycle(from: [0,1,2,3])` | `[0,1,2]/[1,2,4]` | NetworkX: `[(0,1),(1,2),(2,0)]` |
| CY-015 | NetworkX `test_dag` with `orientation="ignore"` | `0-1 0-2 1-2` | `findCycle` | `[0,1,2]/[0,2,1]` | NetworkX: `[(0,1,F),(1,2,F),(0,2,R)]`; in Grafluent `digraph.undirected.findCycle()` |
| CY-016 | forest, then a cycle | `P(0,1,2) C(3,4,5)` | `findCycle(from: [0])` | `nil` | Only 0's component is searched |
| CY-017 |  | `P(0,1,2) C(3,4,5)` | `findCycle(from: [0,3])` | `[3,4,5]/[2,3,4]` |  |
| CY-018 |  | `P(0,1,2) C(3,4,5)` | `findCycle` | `[3,4,5]/[2,3,4]` |  |
| CY-019 |  | `P(0,1,2) C(3,4,5)` | `isAcyclic` | `F` |  |
| CY-020 | lollipop | `P(0..3) C(3,4,5)` | `findCycle` | `[3,4,5]/[3,4,5]` |  |
| CY-021 | loop at a leaf | `P(0..4) 4-4` | `findCycle` | `[4]/[4]` |  |
| CY-022 | triangle and loop | `0-1 1-2 2-0 1-1` | `findCycle` | `[0,1,2]/[0,1,2]` | 1's row reaches 2 before its loop: the triangle closes first |
| CY-023 | loop first | `1-1 0-1 1-2 2-0` | `findCycle` | `[1]/[0]` | Vertex 1 is first in `vertices`; its loop is its first edge |
| CY-024 | parallel copy of the tree edge | `0-1 1-2 1-2` | `findCycle` | `[1,2]/[1,2]` | Skips the parent EDGE, not the parent vertex |
| CY-025 | C₄ with a chord | `C(0..3) 0-2` | `findCycle` | `[0,1,2,3]/[0,1,2,3]` | The depth-first search walks the rim first |
| CY-026 | the same, rows reversed | `C(0..3) 0-2 ~rev` | `findCycle` | `[0,3,2]/[3,2,4]` | Which cycle depends on incidence order; the form does not |
| CY-027 | grid | `grid(3,3)` | `findCycle` | `[1,2,5,4]/[2,4,7,3]` |  |
| CY-028 | star | `S(0;1..5)` | `isAcyclic` | `T` |  |
| CY-029 | NetworkX `random_labeled_tree(10, seed=42)` | `[0..9] 0-6 0-4 1-5 1-2 1-8 2-3 3-4 3-7 8-9` | `isAcyclic` | `T` |  |
| CY-030 | NetworkX `empty_graph(10)` | `[0..9]` | `isAcyclic` | `T` |  |
| CY-031 | String vertices | `A-B B-C C-A` | `findCycle` | `[A,B,C]/[0,1,2]` |  |
| CY-032 | K₄ | `K(4)` | `findCycle` | `[0,1,2]/[0,3,1]` |  |
| CY-033 | JGraphT `AsUndirectedGraph` of `D: 0>1 1>0` | `0-1 1-0` | `findCycle` | `[0,1]/[0,1]` | Opposite arcs read as parallel edges: a 2-cycle |
| CY-034 | loop on an isolated vertex | `P(0,1,2) [3] 3-3` | `findCycle(from: [0])` | `nil` |  |
| CY-035 |  | `P(0,1,2) 3-3` | `findCycle` | `[3]/[2]` |  |
| CY-036 | m ≥ n means cyclic | `C(0,1,2) [3,4]` | `isAcyclic` | `F` | m = 3 < n = 5 and still cyclic: the m ≥ n shortcut only rejects |
| CY-037 |  | `P(0..5) 5-0` | `isAcyclic` | `F` |  |
| CY-038 | roots repeated and out of order | `P(0,1) C(2,3,4)` | `findCycle(from: [4,0,4])` | `[2,3,4]/[1,2,3]` | Searches from 4 first |
| CY-039 | NetworkX `test_dag` | `0-1 0-2 1-2` | `isAcyclic` | `F` | `D: 0>1 0>2 1>2` is acyclic as a digraph, not as a graph |

## B. Cycle basis (CY-100 – CY-159)

| ID | Source | Graph | Op | Expected | Note |
|---|---|---|---|---|---|
| CY-100 | igraph `cycle_bases` null graph | `[]` | `cycleBasis` | `none` |  |
| CY-101 | igraph singleton | `[0]` | `cycleBasis` | `none` |  |
| CY-102 | igraph single vertex with loop; NetworkX `test_cycle_basis_self_loop` | `0-0` | `cycleBasis` | `[0]/[0]` | igraph: (0) |
| CY-103 | igraph tree `kary_tree(3, 2)` | `kary(3,2)` | `cycleBasis` | `none` |  |
| CY-104 | igraph 2-cycle | `0-1 0-1` | `cycleBasis` | `[0,1]/[0,1]` | igraph: (0 1). NetworkX and JGraphT's Paton reject multigraphs |
| CY-105 | igraph disconnected multigraph (igb#7) | `[0..12] 1-2 2-3 3-1 4-5 5-4 4-5 6-7 7-8 8-9 9-6 6-8 10-10 10-11 12-12` | `cycleBasis` | `[1,2,3]/[0,1,2]; [4,5]/[3,4]; [4,5]/[3,5]; [6,7,8]/[6,7,10]; [6,9,8]/[9,8,10]; [10]/[11]; [12]/[13]` | igraph: (1 0 2) (4 5) (3 5) (7 6 10) (8 10 9) (11) (13): the same cycles but (4 5) for (3 4) |
| CY-106 | NetworkX `test_cycle_basis` (nxb#3) | `0-1 0-3 0-5 0-8 1-2 1-6 2-3 3-4 4-5 6-7 7-8 8-9` | `cycleBasis` | `[0,1,2,3]/[0,4,6,1]; [0,3,4,5]/[1,7,8,2]; [0,1,6,7,8]/[0,5,9,10,3]` | NetworkX, sorted: [0,1,2,3], [0,1,6,7,8], [0,3,4,5]: the same vertex sets |
| CY-107 | NetworkX disconnected, `add_cycle("ABC")` (nxb#4) | `0-1 0-3 0-5 0-8 1-2 1-6 2-3 3-4 4-5 6-7 7-8 8-9 A-B B-C C-A` | `cycleBasis` | `[0,1,2,3]/[0,4,6,1]; [0,3,4,5]/[1,7,8,2]; [0,1,6,7,8]/[0,5,9,10,3]; [A,B,C]/[12,13,14]` |  |
| CY-108 | NetworkX `test_cycle_basis_self_loop` (nxb#4) | `[0,1,2,3,6] 0-1 0-3 0-0 0-6 0-2 1-2 2-3 2-6` | `cycleBasis` | `[0]/[2]; [0,1,2]/[0,5,4]; [0,3,2]/[1,6,4]; [0,6,2]/[3,7,4]` | NetworkX sorted: [0], [0,1,2], [0,2,3], [0,2,6] |
| CY-109 | rustworkx `test_cycle_basis` (nxb#2) | `[0..5] 0-1 0-3 0-5 1-2 2-3 3-4 4-5` | `cycleBasis` | `[0,1,2,3]/[0,3,4,1]; [0,3,4,5]/[1,5,6,2]` | rustworkx sorted: [0,1,2,3], [0,3,4,5] |
| CY-110 | rustworkx `test_self_loop` (nxb#4) | `[0..9] 0-1 0-3 0-5 0-8 1-2 1-6 2-3 3-4 4-5 6-7 7-8 8-9 1-1` | `cycleBasis` | `[0,1,2,3]/[0,4,6,1]; [0,3,4,5]/[1,7,8,2]; [0,1,6,7,8]/[0,5,9,10,3]; [1]/[12]` |  |
| CY-111 | JGraphT `testPatonCycleBasis1` | `1-2 1-3 1-4 1-12 3-5 3-6 12-13 6-7 6-8 13-14 7-9 8-10 14-15 10-11 2-11 5-4 5-9 9-10 9-11 10-14 11-15` | `cycleBasis` | `[1,2,11,9,7,6,3]/[0,14,18,10,7,5,1]; [1,2,11,10,8,6,3]/[0,14,13,11,8,5,1]; [1,2,11,15,14,13,12]/[0,14,20,12,9,6,3]; [1,3,5,4]/[1,4,15,2]; [1,2,11,9,5,3]/[0,14,18,16,4,1]; [9,10,11]/[17,13,18]; [1,2,11,10,14,13,12]/[0,14,13,19,9,6,3]` | JGraphT's Paton basis has total length 44; this breadth-first one 41 (7, 7, 7, 4, 6, 3, 7): bases differ by forest |
| CY-112 | JGraphT `testPatonCycleBasis` | `1-2 1-3 2-4 2-5 3-6 3-7 4-5 6-7 4-6` | `cycleBasis` | `[2,4,5]/[2,6,3]; [3,6,7]/[4,7,5]; [1,2,4,6,3]/[0,2,8,4,1]` |  |
| CY-113 | K₄ | `K(4)` | `cycleBasis` | `[0,1,2]/[0,3,1]; [0,1,3]/[0,4,2]; [0,2,3]/[1,5,2]` | Breadth-first from 0: every cycle a triangle through 0 |
| CY-114 | Petersen | `nx(petersen)` | `basisCount` | `#6` | 15 − 10 + 1 |
| CY-115 | JGraphT grid | `grid(3,4)` | `cycleBasis` | `[0,1,5,4]/[0,3,7,1]; [1,2,6,5]/[2,5,9,3]; [2,3,7,6]/[4,6,11,5]; [0,1,5,9,8,4]/[0,3,10,14,8,1]; [1,2,6,10,9,5]/[2,5,12,15,10,3]; [2,3,7,11,10,6]/[4,6,13,16,12,5]` |  |
| CY-116 | tree | `P(0..6) 3-7 7-8` | `cycleBasis` | `none` |  |
| CY-117 | NetworkX `test_cycle_basis_ordered` (gh-6654) | `[0..7] 0-1 0-4 1-2 2-3 3-4 3-7 4-5 5-6 6-7` | `cycleBasis` | `[0,1,2,3,4]/[0,2,3,4,1]; [3,4,5,6,7]/[4,6,7,8,5]` |  |
| CY-118 | grid, rows reversed | `grid(3,3) ~rev` | `cycleBasis` | `[0,1,4,3]/[0,3,5,1]; [0,1,2,5,4,3]/[0,2,4,7,5,1]; [3,4,7,6]/[5,8,10,6]; [3,4,5,8,7,6]/[5,7,9,11,10,6]` | The forest follows incidence order: compare CY-122 |
| CY-119 | everything at once | `0-1 1-2 2-0 0-1 2-2` | `cycleBasis` | `[0,1,2]/[0,1,2]; [0,1]/[0,3]; [2]/[4]` | One cycle per non-tree edge, ascending position: a triangle, the 2-cycle, the loop |
| CY-120 | string vertices | `A-B B-C C-A C-D` | `cycleBasis` | `[A,B,C]/[0,1,2]` |  |
| CY-121 | wheel | `W(0;1..6)` | `cycleBasis` | `[0,1,2]/[0,6,1]; [0,2,3]/[1,7,2]; [0,3,4]/[2,8,3]; [0,4,5]/[3,9,4]; [0,5,6]/[4,10,5]; [0,1,6]/[0,11,5]` |  |
| CY-122 | grid | `grid(3,3)` | `cycleBasis` | `[0,1,4,3]/[0,3,5,1]; [1,2,5,4]/[2,4,7,3]; [0,1,4,7,6,3]/[0,3,8,10,6,1]; [1,2,5,8,7,4]/[2,4,9,11,8,3]` |  |
| CY-123 | not every basis is fundamental: NetworkX `cycle_basis` (Paton) gives [0,3,4], [2,3,4], [0,1,3], [0,2,4], and [0,3,4] has no edge of its own (nxb#4) | `[0..4] 0-4 0-3 0-2 0-1 1-3 2-4 2-3 3-4` | `cycleBasis` | `[0,3,1]/[1,4,3]; [0,4,2]/[0,5,2]; [0,3,2]/[1,6,2]; [0,4,3]/[0,7,1]` | Ours: each cycle holds exactly one non-tree edge, its own. JGraphT documents Paton's output as "weakly fundamental" |
| CY-150 | deferred: NetworkX `test_unweighted_diamond` | `C(1,2,3,4) 2-4` | `minimumCycleBasisLengths` | `[3,3]` | NetworkX [[2,4,1],[3,4,2]] |
| CY-151 | deferred: NetworkX `test_complete_graph` | `K(5)` | `minimumCycleBasisLengths` | `[3,3,3,3,3,3]` |  |
| CY-152 | deferred: NetworkX `test_petersen_graph` | `nx(petersen)` | `minimumCycleBasisLengths` | `[5,5,5,5,5,5]` |  |
| CY-153 | deferred: NetworkX gh-6787, unweighted | `C(0..3) 0-2 1-3` | `minimumCycleBasisLengths` | `[3,3,3]` |  |
| CY-154 | deferred: NetworkX `test_tree_graph` | `P(0..4) 1-5 1-6` | `minimumCycleBasisLengths` | `[]` |  |
| CY-155 | deferred: NetworkX docstring | `C(0,1,2,3) 3-4 4-5 5-0` | `minimumCycleBasisLengths` | `[4,4]` | NetworkX [[5,4,3,0],[3,2,1,0]] |
| CY-156 | deferred: igraph `igraph_girth.c` ring | `C(0..99) 0-50` | `minimumCycleBasisLengths` | `[51,51]` |  |

## C. Directed simple cycles (CY-200 – CY-269)

| ID | Source | Graph | Op | Expected | Note |
|---|---|---|---|---|---|
| CY-200 | NetworkX `test_simple_cycles` and docstring; rustworkx (nx#5 rx#5 bh#5 bhu#5 bt#3) | `D: 0>0 0>1 0>2 1>2 2>0 2>1 2>2` | `simpleCycles` | `[0]/[0]; [0,1,2]/[1,3,4]; [0,2]/[2,4]; [1,2]/[3,5]; [2]/[6]` | NetworkX sorted: [0], [0,1,2], [0,2], [1,2], [2] |
| CY-201 | JGraphT `reflexiveCycleFind`; Boost probe (bh#1 bt#0) | `D: 0>0` | `simpleCycles` | `[0]/[0]` | Boost's Tiernan ignores loops |
| CY-202 | JGraphT `noCyclesFind` | `D: [A,B,C] A>B B>C` | `simpleCycles` | `none` |  |
| CY-203 | JGraphT `singleDirectCycleFind` (jg#1) | `D: A>B B>A` | `simpleCycles` | `[A,B]/[0,1]` |  |
| CY-204 | JGraphT `indirectCycleFind` (jg#1) | `D: A>B B>C C>A` | `simpleCycles` | `[A,B,C]/[0,1,2]` |  |
| CY-205 | JGraphT `twoCycles` (jg#2) | `D: A>B B>A B>C C>A` | `simpleCycles` | `[A,B]/[0,1]; [A,B,C]/[0,2,3]` | JGraphT's order too |
| CY-206 | JGraphT `twoSharingEdge` (jg#2) | `D: [A,B,C,D] B>C A>B C>A D>B C>D` | `simpleCycles` | `[A,B,C]/[1,0,2]; [B,C,D]/[0,4,3]` |  |
| CY-207 | JGraphT `simplestCycles` (jg#3) | `D: A>B B>A A>A B>B` | `simpleCycles` | `[A,B]/[0,1]; [A]/[2]; [B]/[3]` | JGraphT pins [A,B], [A], [B]: the same order |
| CY-208 | JGraphT `complexGraph` (jg#2) | `D: [A,B,C,D,E,F] A>B B>C B>E C>D D>E E>F F>A` | `simpleCycles` | `[A,B,C,D,E,F]/[0,1,3,4,5,6]; [A,B,E,F]/[0,2,5,6]` |  |
| CY-209 | JGraphT `testOrder` (jg#2) | `D: [0..5] 0>1 1>2 2>3 3>0 1>4 4>5 5>2` | `simpleCycles` | `[0,1,2,3]/[0,1,2,3]; [0,1,4,5,2,3]/[0,4,5,6,2,3]` | JGraphT pins "0,1,2,3" then "0,1,4,5,2,3": the same |
| CY-210 | JGraphT `DirectedSimpleCyclesTest` incremental (jg#5) | `D: [0..6] 0>0 1>1 0>1 1>0 1>2 2>3 3>0 6>6` | `simpleCycles` | `[0]/[0]; [0,1]/[2,3]; [0,1,2,3]/[2,4,5,6]; [1]/[1]; [6]/[7]` |  |
| CY-211 | NetworkX `test_unsortable` | `D: a>1 1>a` | `simpleCycles` | `[a,1]/[0,1]` |  |
| CY-212 | NetworkX `test_simple_cycles_small` | `D: C(1,2,3)` | `simpleCycles` | `[1,2,3]/[0,1,2]` |  |
| CY-213 | NetworkX `test_simple_cycles_small` | `D: C(1,2,3) C(10,20,30)` | `simpleCycles` | `[1,2,3]/[0,1,2]; [10,20,30]/[3,4,5]` |  |
| CY-214 | NetworkX `test_simple_cycles_empty`; rustworkx | `D: []` | `simpleCycles` | `none` |  |
| CY-215 | NetworkX / rustworkx Johnson figure 1, k = 3 (nx#9) | `D: johnson(3)` | `simpleCycles` | `[1,2,5,6,7]/[0,1,8,10,6]; [1,3,5,6,7]/[2,3,8,10,6]; [1,4,5,6,7]/[4,5,8,10,6]; [5,8,9]/[7,13,12]; [5,6,8,9]/[8,9,13,12]; [5,6,7,8,9]/[8,10,11,13,12]; [8,9,12]/[13,14,19]; [8,10,12]/[15,16,19]; [8,11,12]/[17,18,19]` |  |
| CY-216 | NetworkX / rustworkx figure 1, k = 9 (nx#27) | `D: johnson(9)` | `count` | `#27` |  |
| CY-217 | NetworkX `test_simple_graph_with_reported_bug` (nx#26) | `D: [0,2,3,1,4,5] 0>2 0>3 2>1 2>4 3>2 3>4 1>0 1>3 4>0 4>1 4>5 5>0 5>1 5>2 5>3` | `count` | `#26` |  |
| CY-218 | NetworkX A006231 | `D: DK(1)` | `count` | `#0` |  |
| CY-219 | NetworkX A006231; rustworkx mesh | `D: DK(2)` | `count` | `#1` |  |
| CY-220 |  | `D: DK(3)` | `count` | `#5` |  |
| CY-221 |  | `D: DK(4)` | `count` | `#20` |  |
| CY-222 |  | `D: DK(5)` | `count` | `#84` |  |
| CY-223 |  | `D: DK(6)` | `count` | `#409` |  |
| CY-224 |  | `D: DK(7)` | `count` | `#2365` |  |
| CY-225 | rustworkx `test_mesh_graph` n = 8 | `D: DK(8)` | `count` | `#16064` |  |
| CY-226 | JGraphT `DirectedSimpleCyclesTest` RESULTS | `D: DKL(1)` | `count` | `#1` | Every loop is a cycle: A006231 + n |
| CY-227 |  | `D: DKL(2)` | `count` | `#3` |  |
| CY-228 |  | `D: DKL(3)` | `count` | `#8` |  |
| CY-229 |  | `D: DKL(4)` | `count` | `#24` |  |
| CY-230 |  | `D: DKL(5)` | `count` | `#89` |  |
| CY-231 |  | `D: DKL(6)` | `count` | `#415` |  |
| CY-232 |  | `D: DKL(7)` | `count` | `#2372` |  |
| CY-233 | JGraphT RESULTS[8] | `D: DKL(8)` | `count` | `#16072` | RESULTS[9] = 125 673 is CY-806 |
| CY-234 | igraph directed cycle graph (ig#1) | `D: C(0..9)` | `simpleCycles` | `[0,1,2,3,4,5,6,7,8,9]/[0,1,2,3,4,5,6,7,8,9]` |  |
| CY-235 | igraph directed star | `D: S(0;1..6)` | `simpleCycles` | `none` |  |
| CY-236 | igraph directed wheel, OUT (ig#1) | `D: S(0;1..7) C(1..7)` | `simpleCycles` | `[1,2,3,4,5,6,7]/[7,8,9,10,11,12,13]` | Its ALL reading is CY-338 |
| CY-237 | igraph complete DAG (`full_citation(5)`), OUT | `D: TT(5)` | `simpleCycles` | `none` | Its ALL reading is K₅, CY-310 |
| CY-238 | igraph cycle of 4 with a multi-edge, directed (ig#2 nx#1) | `D: [0..4] 1>2 2>3 2>3 3>4 4>1` | `simpleCycles` | `[1,2,3,4]/[0,1,3,4]; [1,2,3,4]/[0,2,3,4]` | Edge identity: one cycle per parallel copy |
| CY-239 | igraph PR 2181 (ig#2) | `D: [0..4] 0>1 1>2 2>3 3>0 1>4 4>2` | `simpleCycles` | `[0,1,2,3]/[0,1,2,3]; [0,1,4,2,3]/[0,4,5,2,3]` |  |
| CY-240 | igraph "stable boat" (ig#4) | `D: 0>2 0>3 0>4 1>0 2>3 3>4 4>1 4>3` | `simpleCycles` | `[0,2,3,4,1]/[0,4,5,6,3]; [0,3,4,1]/[1,5,6,3]; [0,4,1]/[2,6,3]; [3,4]/[5,7]` |  |
| CY-241 | igraph "stable letter" (ig#7) | `D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2` | `simpleCycles` | `[0,2,3,1,4]/[0,4,6,3,7]; [0,2,4]/[0,5,7]; [0,3,1,2,4]/[1,6,2,5,7]; [0,3,1,4]/[1,6,3,7]; [2,3,1]/[4,6,2]; [2,3,1,4]/[4,6,3,8]; [2,4]/[5,8]` |  |
| CY-242 | igraph "double square" (ig#2) | `D: 0>2 0>4 1>3 2>5 3>0 4>1 5>4` | `simpleCycles` | `[0,2,5,4,1,3]/[0,3,6,5,2,4]; [0,4,1,3]/[1,5,2,4]` |  |
| CY-243 | Boost `hawick_circuits.cpp` directed ER(20, 0.1), default `minstd_rand` (bh#31 bhu#24 bt#24) | `D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19` | `count` | `#31` | `hawick_circuits` counts parallel copies as we do; `hawick_unique_circuits` and Tiernan count vertex sequences |
| CY-244 | Boost `tiernan_all_cycles.cpp` directed ER(20, 0.1), seed 42 (bh#113 bhu#74 bt#74) | `D: [0..19] 0>11 5>8 13>19 12>14 0>4 15>10 9>0 17>9 16>15 10>11 9>17 15>8 17>7 18>0 1>6 6>8 19>12 12>3 18>17 17>18 11>3 3>9 13>9 0>1 7>15 10>12 18>6 1>3 8>6 3>13 4>17 6>1 2>4 8>6 11>3 12>6 6>18 16>19 7>0 18>5` | `count` | `#113` |  |
| CY-245 | NetworkX `test_simple_cycles_acyclic_tournament` | `D: TT(10)` | `simpleCycles` | `none` |  |
| CY-246 | NetworkX `test_chordless_cycles_directed` graph | `D: 0>1 1>2 2>3 3>4 4>0 4>5 5>6 6>7 7>8 8>9 9>10 10>11 11>4` | `simpleCycles` | `[0,1,2,3,4]/[0,1,2,3,4]; [4,5,6,7,8,9,10,11]/[5,6,7,8,9,10,11,12]` |  |
| CY-247 | the same plus 7>3 | `D: 0>1 1>2 2>3 3>4 4>0 4>5 5>6 6>7 7>8 8>9 9>10 10>11 11>4 7>3` | `simpleCycles` | `[0,1,2,3,4]/[0,1,2,3,4]; [3,4,5,6,7]/[3,5,6,7,13]; [4,5,6,7,8,9,10,11]/[5,6,7,8,9,10,11,12]` |  |
| CY-248 | rows reversed | `D: 0>1 0>2 1>0 2>0 ~rev` | `simpleCycles` | `[0,2]/[1,3]; [0,1]/[0,2]` | Within a start vertex, out-edge order decides |
| CY-249 | a loop after an arc | `D: 0>1 1>0 0>0` | `simpleCycles` | `[0,1]/[0,1]; [0]/[2]` | The loop is 0's second out-edge |
| CY-250 | start is the least vertex in `vertices` order, not by value | `D: [2,1,0] 0>1 1>2 2>0` | `simpleCycles` | `[2,0,1]/[2,0,1]` |  |
| CY-251 | NetworkX `test_directed_chordless_cycle_undirected` graph | `D: 1>2 2>3 3>4 4>5 5>0 5>1 0>2` | `simpleCycles` | `[1,2,3,4,5]/[0,1,2,3,5]; [2,3,4,5,0]/[1,2,3,4,6]` |  |
| CY-252 | python-igraph 1.0.0 `simple_cycles` returns no cycle here (an igraph bug; NetworkX and Boost agree with us) | `D: [0..5] 1>3 4>5 0>4 3>2 2>5 5>1` | `simpleCycles` | `[1,3,2,5]/[0,3,4,5]` | igraph skips start vertices of degree < 3 already visited, which is wrong for digraphs: 1, 2, 3 were visited from 0, which is on no cycle. It also undercounts CY-244 (111) |

## D. Undirected simple cycles (CY-300 – CY-349)

| ID | Source | Graph | Op | Expected | Note |
|---|---|---|---|---|---|
| CY-300 | NetworkX `test_simple_cycles_graph` | `C(0..7)` | `simpleCycles` | `[0,1,2,3,4,5,6,7]/[0,1,2,3,4,5,6,7]` |  |
| CY-301 | the same with pendant paths | `[0,1,2,3,4,5,6,7,-1,-2,-3,-4] 0-1 0-7 1-2 2-3 3-4 3--2 4-5 4--1 5-6 6-7 -2--3 -3--4` | `simpleCycles` | `[0,1,2,3,4,5,6,7]/[0,2,3,4,6,8,9,1]` |  |
| CY-302 | plus `cycle_graph(8..15)` | `[0,1,2,3,4,5,6,7,-1,-2,-3,-4,8,9,10,11,12,13,14,15] 0-1 0-7 1-2 2-3 3-4 3--2 4-5 4--1 5-6 6-7 -2--3 -3--4 8-9 8-15 9-10 10-11 11-12 12-13 13-14 14-15` | `simpleCycles` | `[0,1,2,3,4,5,6,7]/[0,2,3,4,6,8,9,1]; [8,9,10,11,12,13,14,15]/[12,14,15,16,17,18,19,13]` |  |
| CY-303 | plus `cycle_graph(4..11)` (nx#6) | `[0,1,2,3,4,5,6,7,-1,-2,-3,-4,8,9,10,11,12,13,14,15] 0-1 0-7 1-2 2-3 3-4 3--2 4-5 4--1 4-11 5-6 6-7 7-8 -2--3 -3--4 8-9 8-15 9-10 10-11 11-12 12-13 13-14 14-15` | `simpleCycles` | `[0,1,2,3,4,5,6,7]/[0,2,3,4,6,9,10,1]; [0,1,2,3,4,11,10,9,8,7]/[0,2,3,4,8,17,16,14,11,1]; [0,1,2,3,4,11,12,13,14,15,8,7]/[0,2,3,4,8,18,19,20,21,15,11,1]; [4,5,6,7,8,9,10,11]/[6,9,10,11,14,16,17,8]; [4,5,6,7,8,15,14,13,12,11]/[6,9,10,11,15,21,20,19,18,8]; [8,9,10,11,12,13,14,15]/[14,16,17,18,19,20,21,15]` | NetworkX lists the six by vertices |
| CY-304 | NetworkX "basis size 5" figure (nx#20) | `[0..15] 0-1 0-11 1-2 2-3 2-13 2-14 3-4 4-5 4-14 4-15 5-6 6-7 7-8 8-9 8-12 8-15 9-10 10-11 10-12 10-13` | `count` | `#20` | 2⁵ − 1 − 11 disjoint combinations |
| CY-305 | NetworkX A002807 | `[]` | `count` | `#0` | K₀ |
| CY-306 |  | `K(1)` | `count` | `#0` |  |
| CY-307 |  | `K(2)` | `count` | `#0` |  |
| CY-308 |  | `K(3)` | `count` | `#1` |  |
| CY-309 |  | `K(4)` | `count` | `#7` |  |
| CY-310 | NetworkX A002807; igraph complete DAG under ALL (ig#37) | `K(5)` | `count` | `#37` |  |
| CY-311 |  | `K(6)` | `count` | `#197` |  |
| CY-312 |  | `K(7)` | `count` | `#1172` |  |
| CY-313 | igraph undirected ring | `C(0..9)` | `count` | `#1` |  |
| CY-314 | igraph undirected star | `S(0;1..6)` | `count` | `#0` |  |
| CY-315 | igraph ring ∪ star | `C(0..9) S(10;11..16)` | `count` | `#1` |  |
| CY-316 | igraph ring ∪ star plus 7–13 | `C(0..9) S(10;11..16) 7-13` | `count` | `#1` |  |
| CY-317 | igraph `kary_tree(20, 3)` | `kary(20,3)` | `count` | `#0` |  |
| CY-318 | igraph undirected wheel of 10 (ig#73) | `W(0;1..9)` | `count` | `#73` | igraph's comment: 9 of 10 vertices, 10 of 9, 9 of each length 8 … 3 |
| CY-319 | igraph "envelope" (ig#13) | `0-1 0-3 0-4 1-2 1-3 2-3 2-4 3-4` | `simpleCycles` | `[0,1,2,3]/[0,3,5,1]; [0,1,2,3,4]/[0,3,5,7,2]; [0,1,2,4]/[0,3,6,2]; [0,1,2,4,3]/[0,3,6,7,1]; [0,1,3]/[0,4,1]; [0,1,3,2,4]/[0,4,5,6,2]; [0,1,3,4]/[0,4,7,2]; [0,3,1,2,4]/[1,4,3,6,2]; [0,3,2,4]/[1,5,6,2]; [0,3,4]/[1,7,2]; [1,2,3]/[3,5,4]; [1,2,4,3]/[3,6,7,4]; [3,2,4]/[5,6,7]` |  |
| CY-320 | igraph "boat" (ig#6) | `0-2 0-4 1-2 1-3 1-4 2-3 2-4` | `simpleCycles` | `[0,2,1,4]/[0,2,4,1]; [0,2,3,1,4]/[0,5,3,4,1]; [0,2,4]/[0,6,1]; [2,1,3]/[2,3,5]; [2,1,4]/[2,4,6]; [2,3,1,4]/[5,3,4,6]` |  |
| CY-321 | igraph "house" (ig#3) | `0-3 0-4 1-2 1-3 1-4 2-3` | `simpleCycles` | `[0,3,1,4]/[0,3,4,1]; [0,3,2,1,4]/[0,5,2,4,1]; [3,1,2]/[3,2,5]` |  |
| CY-322 | igraph "prism" (ig#14) | `0-1 0-3 0-5 1-4 1-5 2-3 2-4 2-5 3-4` | `count` | `#14` |  |
| CY-323 | igraph "7 vertices" (ig#89) | `0-1 0-4 0-5 0-6 1-2 1-3 1-5 1-6 2-3 2-6 3-4 3-5 3-6 4-5` | `count` | `#89` |  |
| CY-324 | igraph "shooting star" (ig#295) | `0-1 0-2 0-3 0-4 0-6 1-2 1-3 1-4 1-5 1-6 2-3 2-4 2-6 3-4 3-5 4-6 5-6` | `count` | `#295` | 18 + 43 + 78 + 96 + 60 |
| CY-325 | igraph "Mickey" (ig#3) | `[0..6] 0-1 1-2 2-0 0-0 0-3 3-4 4-5 5-0` | `simpleCycles` | `[0,1,2]/[0,1,2]; [0]/[3]; [0,3,4,5]/[4,5,6,7]` |  |
| CY-326 | igraph "Mickey2" (ig#3) | `[0..6] 0-1 1-2 2-0 1-1 0-3 3-4 4-5 5-0` | `simpleCycles` | `[0,1,2]/[0,1,2]; [0,3,4,5]/[4,5,6,7]; [1]/[3]` |  |
| CY-327 | igraph "Mickey3" (ig#6 nx#5) | `[0..6] 0-1 1-2 2-0 0-3 3-4 4-5 5-0 1-1 5-6 6-5 5-5 5-5` | `simpleCycles` | `[0,1,2]/[0,1,2]; [0,3,4,5]/[3,4,5,6]; [1]/[7]; [5,6]/[8,9]; [5]/[10]; [5]/[11]` | Two loops at 5 are two cycles; NetworkX merges them |
| CY-328 | Boost `hawick_circuits.cpp` undirected ER(20, 0.1) (bh#30 bhu#27 bt#8) | `[0..19] 0-1 12-17 19-3 10-7 5-14 1-11 11-16 11-10 17-19 14-19 5-8 17-13 18-19 3-17 18-5 18-8 6-10 7-15 13-10 11-1` | `simpleCycles` | `[1,11]/[5,19]; [3,19,17]/[2,8,13]; [5,14,19,18]/[4,9,12,14]; [5,14,19,18,8]/[4,9,12,15,10]; [5,8,18]/[10,15,14]` | Boost reads an undirected graph as two arcs per edge: every edge is a circuit, every cycle twice (CY-415) |
| CY-329 | Boost `tiernan_all_cycles.cpp` undirected, seed 42 (bh#32 bhu#20 bt#2) | `[0..19] 0-11 5-8 13-19 12-14 0-4 15-10 9-0 17-9 16-15 10-11 9-17 15-8 17-7 18-0 1-6 6-8 19-12 12-3 18-17 17-18` | `simpleCycles` | `[0,9,17,18]/[6,7,18,13]; [0,9,17,18]/[6,7,19,13]; [0,9,17,18]/[6,10,18,13]; [0,9,17,18]/[6,10,19,13]; [9,17]/[7,10]; [17,18]/[18,19]` |  |
| CY-330 | K₄: the canonical form and order | `K(4)` | `simpleCycles` | `[0,1,2]/[0,3,1]; [0,1,2,3]/[0,3,5,2]; [0,1,3]/[0,4,2]; [0,1,3,2]/[0,4,5,1]; [0,2,1,3]/[1,3,4,2]; [0,2,3]/[1,5,2]; [1,2,3]/[3,5,4]` |  |
| CY-331 | K₄, rows reversed | `K(4) ~rev` | `simpleCycles` | `[0,2,3]/[1,5,2]; [0,2,1,3]/[1,3,4,2]; [0,1,3,2]/[0,4,5,1]; [0,1,3]/[0,4,2]; [0,1,2,3]/[0,3,5,2]; [0,1,2]/[0,3,1]; [1,2,3]/[3,5,4]` | The same seven cycles, the same canonical forms, another order |
| CY-332 | C₄ with a chord | `C(0..3) 0-2` | `simpleCycles` | `[0,1,2,3]/[0,1,2,3]; [0,1,2]/[0,1,4]; [0,3,2]/[3,2,4]` |  |
| CY-333 | bowtie | `C(0,1,2) C(0,3,4)` | `simpleCycles` | `[0,1,2]/[0,1,2]; [0,3,4]/[3,4,5]` |  |
| CY-334 | ladder (rungs choose 2) | `grid(2,4)` | `count` | `#6` |  |
| CY-335 | 3 × 3 grid | `grid(3,3)` | `count` | `#13` |  |
| CY-336 | Petersen | `nx(petersen)` | `count` | `#57` |  |
| CY-337 | complete bipartite K₃,₃ | `KB(0..2;3..5)` | `count` | `#15` |  |
| CY-338 | igraph directed wheel under ALL (ig#43) | `W(0;1..7)` | `count` | `#43` |  |
| CY-339 | string vertices | `A-B B-C C-A` | `simpleCycles` | `[A,B,C]/[0,1,2]` |  |
| CY-340 | least vertex by `vertices` order | `C(3,4,5) C(0,1,2)` | `simpleCycles` | `[3,4,5]/[0,1,2]; [0,1,2]/[3,4,5]` | 3 comes first in `vertices` |
| CY-341 | cycles through a cut vertex | `C(0,1,2) C(2,3,4) C(4,5,6)` | `simpleCycles` | `[0,1,2]/[0,1,2]; [2,3,4]/[3,4,5]; [4,5,6]/[6,7,8]` |  |
| CY-342 | NetworkX `test_chordless_cycles_graph` graph | `0-1 0-4 1-2 2-3 3-4 4-5 4-11 5-6 6-7 7-8 8-9 9-10 10-11` | `simpleCycles` | `[0,1,2,3,4]/[0,2,3,4,1]; [4,5,6,7,8,9,10,11]/[5,7,8,9,10,11,12,6]` |  |
| CY-343 | the same plus 7–3 | `0-1 0-4 1-2 2-3 3-4 4-5 4-11 5-6 6-7 7-8 8-9 9-10 10-11 7-3` | `simpleCycles` | `[0,1,2,3,4]/[0,2,3,4,1]; [0,1,2,3,7,6,5,4]/[0,2,3,13,8,7,5,1]; [0,1,2,3,7,8,9,10,11,4]/[0,2,3,13,9,10,11,12,6,1]; [4,3,7,6,5]/[4,13,8,7,5]; [4,3,7,8,9,10,11]/[4,13,9,10,11,12,6]; [4,5,6,7,8,9,10,11]/[5,7,8,9,10,11,12,6]` |  |

## E. Multigraphs and self-loops (CY-400 – CY-439)

| ID | Source | Graph | Op | Expected | Note |
|---|---|---|---|---|---|
| CY-400 | NetworkX `test_simple_cycles_singleton` (nx#1 ig#1) | `0-0` | `simpleCycles` | `[0]/[0]` | Once, though the row lists it twice. Boost's undirected Hawick emits it twice (CY-414) |
| CY-401 | two loops (nx#1) | `0-0 0-0` | `simpleCycles` | `[0]/[0]; [0]/[1]` | Edge identity: two cycles |
| CY-402 | igraph single length-2 loop (ig#1 nx#1) | `0-1 0-1` | `simpleCycles` | `[0,1]/[0,1]` | Canonical: the lesser position leaves 0 |
| CY-403 | igraph three length-2 loops (ig#3 nx#1) | `0-1 0-1 0-1` | `simpleCycles` | `[0,1]/[0,1]; [0,1]/[0,2]; [0,1]/[1,2]` | One per pair of copies: C(3, 2) |
| CY-404 | igraph length-2 loop and a self-loop (ig#2) | `0-1 0-1 0-0` | `simpleCycles` | `[0,1]/[0,1]; [0]/[2]` |  |
| CY-405 | triangle with a doubled side (nx#2) | `0-1 0-1 1-2 2-0` | `simpleCycles` | `[0,1]/[0,1]; [0,1,2]/[0,2,3]; [0,1,2]/[1,2,3]` | Each copy gives its own triangle |
| CY-406 | triangle with a loop | `C(0,1,2) 1-1` | `simpleCycles` | `[0,1,2]/[0,1,2]; [1]/[3]` |  |
| CY-407 | canonical start is by `vertices`, orientation by position | `1-0 0-1` | `simpleCycles` | `[1,0]/[0,1]` |  |
| CY-408 | Boost probe "doubled 2-cycle" (bh#2 bhu#1 bt#1 nx#1) | `D: 0>1 0>1 1>0` | `simpleCycles` | `[0,1]/[0,2]; [0,1]/[1,2]` |  |
| CY-409 | two directed loops (nx#1) | `D: 0>0 0>0` | `simpleCycles` | `[0]/[0]; [0]/[1]` |  |
| CY-410 | 2 × 2 antiparallel copies | `D: 0>1 1>0 1>0 0>1` | `simpleCycles` | `[0,1]/[0,1]; [0,1]/[0,2]; [0,1]/[3,1]; [0,1]/[3,2]` |  |
| CY-411 | igraph cycle of 4 with a multi-edge, undirected (ig#3 nx#2) | `[0..4] 1-2 2-3 2-3 3-4 4-1` | `simpleCycles` | `[1,2,3,4]/[0,1,3,4]; [1,2,3,4]/[0,2,3,4]; [2,3]/[1,2]` |  |
| CY-412 | two doubled sides of C₄ | `C(0..3) 0-1 2-3` | `simpleCycles` | `[0,1,2,3]/[0,1,2,3]; [0,1,2,3]/[0,1,5,3]; [0,1]/[0,4]; [0,3,2,1]/[3,2,1,4]; [0,3,2,1]/[3,5,1,4]; [2,3]/[2,5]` | 2 × 2 four-cycles and two 2-cycles |
| CY-413 | Boost probe "U K2" (bh#1) | `0-1` | `directedCount` | `#1` | In `g.directed` an edge is two arcs: a 2-cycle |
| CY-414 | Boost probe "U self-loop" (bh#2) | `0-0` | `directedCount` | `#2` | `g.directed` lists a loop's two ends as two arcs |
| CY-415 | Boost probe "U doubled K2" (bh#4) | `0-1 0-1` | `directedCount` | `#4` |  |
| CY-416 | Boost probe "U triangle" (bh#5) | `C(0,1,2)` | `directedCount` | `#5` | Three digons and both orientations |
| CY-417 | Boost undirected ER(20, 0.1) (bh#30) | `[0..19] 0-1 12-17 19-3 10-7 5-14 1-11 11-16 11-10 17-19 14-19 5-8 17-13 18-19 3-17 18-5 18-8 6-10 7-15 13-10 11-1` | `directedCount` | `#30` | Boost's undirected count is our `g.directed` count |
| CY-418 | loop on a vertex in no cycle | `P(0,1,2) 1-1` | `simpleCycles` | `[1]/[2]` |  |
| CY-419 | bridge with loops at both ends | `0-0 0-1 1-1` | `simpleCycles` | `[0]/[0]; [1]/[2]` |  |
| CY-420 | NetworkX `test_chordless_cycles_multigraph_self_loops` graph (nx#3) | `1-1 2-2 1-2 1-2` | `simpleCycles` | `[1]/[0]; [1,2]/[2,3]; [2]/[1]` |  |
| CY-421 | the same plus a doubled pendant | `1-1 2-2 1-2 1-2 2-3 3-4 3-4 1-3` | `simpleCycles` | `[1]/[0]; [1,2]/[2,3]; [1,2,3]/[2,4,7]; [1,2,3]/[3,4,7]; [2]/[1]; [3,4]/[5,6]` |  |
| CY-422 | rows reversed: orientation still by position | `0-1 0-1 1-2 2-0 ~rev` | `simpleCycles` | `[0,1,2]/[1,2,3]; [0,1,2]/[0,2,3]; [0,1]/[0,1]` |  |
| CY-423 | `.undirected` of `D: 0>1 1>0 1>0` | `0-1 1-0 1-0` | `simpleCycles` | `[0,1]/[0,1]; [0,1]/[0,2]; [0,1]/[1,2]` |  |

## F. Length bounds (CY-450 – CY-499)

| ID | Source | Graph | Op | Expected | Note |
|---|---|---|---|---|---|
| CY-450 | NetworkX `test_simple_cycles_bound_corner_cases` | `C(0..3)` | `count(maxLength: 0)` | `#0` |  |
| CY-451 | NetworkX corner cases | `D: C(0..3)` | `count(maxLength: 0)` | `#0` |  |
| CY-452 | NetworkX example, bound 1 | `D: 0>0 0>1 0>2 1>2 2>0 2>1 2>2` | `simpleCycles(maxLength: 1)` | `[0]/[0]; [2]/[6]` |  |
| CY-453 | NetworkX example, bound 2 | `D: 0>0 0>1 0>2 1>2 2>0 2>1 2>2` | `simpleCycles(maxLength: 2)` | `[0]/[0]; [0,2]/[2,4]; [1,2]/[3,5]; [2]/[6]` |  |
| CY-454 | NetworkX `test_simple_cycles_bounded` nested directed cycles, bound 0 | `D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0` | `count(maxLength: 0)` | `#0` | One cycle of every length 1 … 9 |
| CY-455 | bound 1 | `D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0` | `count(maxLength: 1)` | `#1` |  |
| CY-456 | bound 2 | `D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0` | `count(maxLength: 2)` | `#2` |  |
| CY-457 | bound 5 | `D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0` | `simpleCycles(maxLength: 5)` | `[0]/[0]; [0,1]/[1,2]; [0,1,2]/[1,3,4]; [0,1,2,3]/[1,3,5,6]; [0,1,2,3,4]/[1,3,5,7,8]` |  |
| CY-458 | bound 8 | `D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0` | `count(maxLength: 8)` | `#8` |  |
| CY-459 | bound 9 | `D: 0>0 0>1 1>0 1>2 2>0 2>3 3>0 3>4 4>0 4>5 5>0 5>6 6>0 6>7 7>0 7>8 8>0` | `count(maxLength: 9)` | `#9` |  |
| CY-460 | NetworkX disjoint undirected cycles, bound 1 | `0-0 1-2 1-3 2-3 4-5 4-7 5-6 6-7 8-9 8-12 9-10 10-11 11-12 13-14 13-18 14-15 15-16 16-17 17-18 19-20 19-25 20-21 21-22 22-23 23-24 24-25 26-27 26-33 27-28 28-29 29-30 30-31 31-32 32-33 34-35 34-42 35-36 36-37 37-38 38-39 39-40 40-41 41-42` | `count(maxLength: 1)` | `#1` | "one cycle of every length except 2" |
| CY-461 | bound 2 | `0-0 1-2 1-3 2-3 4-5 4-7 5-6 6-7 8-9 8-12 9-10 10-11 11-12 13-14 13-18 14-15 15-16 16-17 17-18 19-20 19-25 20-21 21-22 22-23 23-24 24-25 26-27 26-33 27-28 28-29 29-30 30-31 31-32 32-33 34-35 34-42 35-36 36-37 37-38 38-39 39-40 40-41 41-42` | `count(maxLength: 2)` | `#1` |  |
| CY-462 | bound 3 | `0-0 1-2 1-3 2-3 4-5 4-7 5-6 6-7 8-9 8-12 9-10 10-11 11-12 13-14 13-18 14-15 15-16 16-17 17-18 19-20 19-25 20-21 21-22 22-23 23-24 24-25 26-27 26-33 27-28 28-29 29-30 30-31 31-32 32-33 34-35 34-42 35-36 36-37 37-38 38-39 39-40 40-41 41-42` | `count(maxLength: 3)` | `#2` |  |
| CY-463 | bound 9 | `0-0 1-2 1-3 2-3 4-5 4-7 5-6 6-7 8-9 8-12 9-10 10-11 11-12 13-14 13-18 14-15 15-16 16-17 17-18 19-20 19-25 20-21 21-22 22-23 23-24 24-25 26-27 26-33 27-28 28-29 29-30 30-31 31-32 32-33 34-35 34-42 35-36 36-37 37-38 38-39 39-40 40-41 41-42` | `count(maxLength: 9)` | `#8` |  |
| CY-464 | igraph wheel of 10, bound 3 (ig#9) | `W(0;1..9)` | `count(maxLength: 3)` | `#9` |  |
| CY-465 | igraph wheel of 10, bound 4 (ig#18) | `W(0;1..9)` | `count(maxLength: 4)` | `#18` |  |
| CY-466 | igraph cycle of 4 with a multi-edge, directed, bound 4 (ig#2) | `D: [0..4] 1>2 2>3 2>3 3>4 4>1` | `count(maxLength: 4)` | `#2` |  |
| CY-467 | igraph the same, undirected, bound 4 (ig#3) | `[0..4] 1-2 2-3 2-3 3-4 4-1` | `count(maxLength: 4)` | `#3` |  |
| CY-468 | igraph PR 2181, bound 3 (ig#0) | `D: [0..4] 0>1 1>2 2>3 3>0 1>4 4>2` | `count(maxLength: 3)` | `#0` |  |
| CY-469 | bound 4 (ig#1) | `D: [0..4] 0>1 1>2 2>3 3>0 1>4 4>2` | `simpleCycles(maxLength: 4)` | `[0,1,2,3]/[0,1,2,3]` |  |
| CY-470 | bound 5 (ig#2) | `D: [0..4] 0>1 1>2 2>3 3>0 1>4 4>2` | `count(maxLength: 5)` | `#2` |  |
| CY-471 | igraph stable boat, bound 2 (ig#1) | `D: 0>2 0>3 0>4 1>0 2>3 3>4 4>1 4>3` | `count(maxLength: 2)` | `#1` |  |
| CY-472 | bound 3 (ig#2) | `D: 0>2 0>3 0>4 1>0 2>3 3>4 4>1 4>3` | `count(maxLength: 3)` | `#2` |  |
| CY-473 | bound 4 (ig#3) | `D: 0>2 0>3 0>4 1>0 2>3 3>4 4>1 4>3` | `count(maxLength: 4)` | `#3` |  |
| CY-474 | igraph stable letter, bound 1 (ig#0) | `D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2` | `count(maxLength: 1)` | `#0` |  |
| CY-475 | bound 2 (ig#1) | `D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2` | `count(maxLength: 2)` | `#1` |  |
| CY-476 | bound 3 (ig#3) | `D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2` | `count(maxLength: 3)` | `#3` |  |
| CY-477 | bound 4 (ig#5) | `D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2` | `count(maxLength: 4)` | `#5` |  |
| CY-478 | bound 5 (ig#7) | `D: 0>2 0>3 1>2 1>4 2>3 2>4 3>1 4>0 4>2` | `count(maxLength: 5)` | `#7` |  |
| CY-479 | igraph double square, bound 3 (ig#0) | `D: 0>2 0>4 1>3 2>5 3>0 4>1 5>4` | `count(maxLength: 3)` | `#0` |  |
| CY-480 | bound 4 (ig#1) | `D: 0>2 0>4 1>3 2>5 3>0 4>1 5>4` | `count(maxLength: 4)` | `#1` |  |
| CY-481 | bound 6 (ig#2) | `D: 0>2 0>4 1>3 2>5 3>0 4>1 5>4` | `count(maxLength: 6)` | `#2` |  |
| CY-482 | Boost directed ER, `max_length` 2 (bh#3 bhu#3) | `D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19` | `count(maxLength: 2)` | `#3` | Boost's `max_length` counts vertices, the same number for a cycle |
| CY-483 | `max_length` 4 (bh#13 bhu#10) | `D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19` | `count(maxLength: 4)` | `#13` |  |
| CY-484 | `max_length` 7 (bh#24 bhu#19) | `D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19` | `count(maxLength: 7)` | `#24` |  |
| CY-485 | `max_length` 9 (bh#30 bhu#23) | `D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19` | `count(maxLength: 9)` | `#30` |  |
| CY-486 | Boost undirected ER, `max_length` 3 (bh#26 bhu#23) | `[0..19] 0-1 12-17 19-3 10-7 5-14 1-11 11-16 11-10 17-19 14-19 5-8 17-13 18-19 3-17 18-5 18-8 6-10 7-15 13-10 11-1` | `directedCount(maxLength: 3)` | `#26` |  |
| CY-487 | the same graph, our undirected count, bound 3 | `[0..19] 0-1 12-17 19-3 10-7 5-14 1-11 11-16 11-10 17-19 14-19 5-8 17-13 18-19 3-17 18-5 18-8 6-10 7-15 13-10 11-1` | `simpleCycles(maxLength: 3)` | `[1,11]/[5,19]; [3,19,17]/[2,8,13]; [5,8,18]/[10,15,14]` |  |
| CY-488 | JGraphT `limitPaths1` | `D: A>B B>A` | `simpleCycles(maxLength: 1)` | `none` |  |
| CY-489 | JGraphT `limitPaths2` | `D: A>B B>C C>A` | `simpleCycles(maxLength: 2)` | `none` |  |
| CY-490 | JGraphT `limitPathsTwoCycles` (jg#2) | `D: A>B B>A C>D D>C` | `simpleCycles(maxLength: 2)` | `[A,B]/[0,1]; [C,D]/[2,3]` |  |
| CY-491 | the bounded search must count other-orientation closures as found | `[0..3] 1-3 2-0 3-0 0-1 2-1 ~rot` | `simpleCycles(maxLength: 4)` | `[0,3,1]/[2,0,3]; [0,2,1]/[1,4,3]; [0,2,1,3]/[1,4,0,2]` | Planted P2 emits two of these three; unbounded Johnson is immune |
| CY-492 | NetworkX A000292 triangles, K₆ | `K(6)` | `count(maxLength: 3)` | `#20` |  |
| CY-493 | triangles and 4-cycles of K₆ (A050534: 45) | `K(6)` | `count(maxLength: 4)` | `#65` |  |
| CY-494 | NetworkX A000292, K₁₁ | `K(11)` | `count(maxLength: 3)` | `#165` |  |
| CY-495 | NetworkX `test_directed_chordless_cycle_diclique`, bound 2 | `D: DK(9)` | `count(maxLength: 2)` | `#36` | n(n − 1)/2 digons |
| CY-496 | bound above n | `C(0..3)` | `count(maxLength: 100)` | `#1` |  |
| CY-497 | NetworkX `test_directed_chordless_loop_blockade`, bound 1 | `D: [0..9] 0>0 1>1 2>2 3>3 4>4 5>5 6>6 7>7 8>8 9>9 C(0..9)` | `simpleCycles(maxLength: 1)` | `[0]/[0]; [1]/[1]; [2]/[2]; [3]/[3]; [4]/[4]; [5]/[5]; [6]/[6]; [7]/[7]; [8]/[8]; [9]/[9]` |  |
| CY-498 | undirected bound 2: loops and 2-cycles only | `0-1 0-1 1-2 2-0 2-2` | `simpleCycles(maxLength: 2)` | `[0,1]/[0,1]; [2]/[4]` |  |

## G. Girth (CY-500 – CY-549)

| ID | Source | Graph | Op | Expected | Note |
|---|---|---|---|---|---|
| CY-500 | NetworkX `TestGirth` (nxg=4) | `nx(chvatal)` | `girth` | `4` |  |
| CY-501 | NetworkX (nxg=4) | `nx(tutte)` | `girth` | `4` |  |
| CY-502 | NetworkX (nxg=5) | `nx(petersen)` | `girth` | `5` |  |
| CY-503 | NetworkX (nxg=6) | `nx(heawood)` | `girth` | `6` |  |
| CY-504 | NetworkX (nxg=6) | `nx(pappus)` | `girth` | `6` |  |
| CY-505 | NetworkX random tree (nxg=inf) | `[0..9] 0-6 0-4 1-5 1-2 1-8 2-3 3-4 3-7 8-9` | `girth` | `nil` | NetworkX `inf`, JGraphT `Integer.MAX_VALUE`, igraph `inf`: ours `nil` |
| CY-506 | NetworkX `empty_graph(10)` | `[0..9]` | `girth` | `nil` |  |
| CY-507 | NetworkX two disjoint cycles (nxg=4) | `[0,1,2,3,4,6,7,8,9] 0-1 0-4 1-2 2-3 3-4 6-7 6-9 7-8 8-9` | `girth` | `4` |  |
| CY-508 | NetworkX 11-edge graph (nxg=3) | `[0,6,8,9,1,2,4,5,7] 0-6 0-8 0-9 6-8 6-9 8-1 8-2 8-7 9-2 9-4 9-5` | `girth` | `3` |  |
| CY-509 | JGraphT `testGraphGirthAcyclic` | `[0..5] 0-1 0-4 0-5 1-2 1-3` | `girth` | `nil` |  |
| CY-510 | JGraphT `testGraphDirectedAcyclic` | `D: [0..3] 0>1 0>2 1>3 2>3` | `girth` | `nil` |  |
| CY-511 | JGraphT `testGraphDirectedCyclic` (jgg=4) | `D: [0..3] 0>1 1>2 2>3 3>0` | `girth` | `4` |  |
| CY-512 | JGraphT `testGraphDirectedCyclic2` (jgg=2) | `D: [0,1] 0>1 1>0` | `girth` | `2` |  |
| CY-513 | JGraphT grid 3 × 4 (jgg=4) | `grid(3,4)` | `girth` | `4` |  |
| CY-514 | JGraphT ring 10 (jgg=10) | `C(0..9)` | `girth` | `10` |  |
| CY-515 | JGraphT ring 9 (jgg=9) | `C(0..8)` | `girth` | `9` |  |
| CY-516 | JGraphT wheel of 5 (jgg=3) | `W(0;1..4)` | `girth` | `3` |  |
| CY-517 | JGraphT `testGraphDirected1` (jgg=2) | `D: [0..3] 1>0 3>0 1>2 2>3 3>2` | `girth` | `2` |  |
| CY-518 | JGraphT `testPseudoGraphUndirected` (jgg=1 igg=4) | `[0..3] 0-1 0-1 1-2 2-2 2-3 3-0` | `girth` | `1` | igraph ignores loops and multi-edges |
| CY-519 | JGraphT `testPseudoGraphDirected` (jgg=1) | `D: [0..3] 0>1 0>1 1>2 2>2 2>3 3>0` | `girth` | `1` |  |
| CY-520 | JGraphT `testMultiGraphUndirected` (jgg=2 igg=4) | `[0..3] 0-1 0-1 1-2 2-3 3-0` | `girth` | `2` |  |
| CY-521 | JGraphT `testMultiGraphDirected` (jgg=4) | `D: [0..3] 0>1 0>1 1>2 2>3 3>0` | `girth` | `4` | Parallel arcs in one direction make no 2-cycle |
| CY-522 | igraph `igraph_girth.c` (igg=51) | `C(0..99) 0-50` | `girth` | `51` |  |
| CY-523 | igraph null graph | `[]` | `girth` | `nil` |  |
| CY-524 | Boost `tiernan_girth_and_circumference` on the undirected ER graph (btg=3) | `[0..19] 0-1 12-17 19-3 10-7 5-14 1-11 11-16 11-10 17-19 14-19 5-8 17-13 18-19 3-17 18-5 18-8 6-10 7-15 13-10 11-1` | `girth` | `2` | Boost ignores the parallel pair 1–11 |
| CY-525 | Boost, directed ER (btg=2) | `D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19` | `girth` | `2` |  |
| CY-526 | Boost, undirected seed 42 (btg=4) | `[0..19] 0-11 5-8 13-19 12-14 0-4 15-10 9-0 17-9 16-15 10-11 9-17 15-8 17-7 18-0 1-6 6-8 19-12 12-3 18-17 17-18` | `girth` | `2` |  |
| CY-527 | K₃ | `K(3)` | `girth` | `3` |  |
| CY-528 | K₂ | `K(2)` | `girth` | `nil` |  |
| CY-529 | self-loop | `0-0` | `girth` | `1` |  |
| CY-530 | parallel pair | `0-1 0-1` | `girth` | `2` |  |
| CY-531 | directed loop | `D: 0>0` | `girth` | `1` |  |
| CY-532 | K₃,₃ | `KB(0..2;3..5)` | `girth` | `4` |  |
| CY-533 | loop far from the start vertex | `P(0..5) C(5,6,7) 7-7` | `girth` | `1` |  |
| CY-534 | directed: shortest cycle not through vertex 0 | `D: C(0..5) 3>1` | `girth` | `3` |  |

## H. Chordless cycles, deferred (CY-600 – CY-629)

Phase 2. Simple graphs only: NetworkX's multigraph rules (a loop is chordless unless doubled; a
parallel pair is a 2-cycle unless tripled; no edge with a parallel copy in a longer cycle) are its
own, and no other library has the function.

| ID | Source | Graph | Op | Expected | Note |
|---|---|---|---|---|---|
| CY-600 | NetworkX docstring | `K(4)` | `chordlessCycles` | `[0,1,2]/[0,3,1]; [0,1,3]/[0,4,2]; [0,2,3]/[1,5,2]; [1,2,3]/[3,5,4]` | NetworkX: [1,0,2], [1,0,3], [2,0,3], [2,1,3] |
| CY-601 | NetworkX `test_chordless_cycles_clique` | `K(5)` | `chordlessCount` | `#10` | C(n, 3) |
| CY-602 |  | `K(7)` | `chordlessCount` | `#35` |  |
| CY-603 | NetworkX `test_chordless_cycles_graph` | `0-1 0-4 1-2 2-3 3-4 4-5 4-11 5-6 6-7 7-8 8-9 9-10 10-11` | `chordlessCycles` | `[0,1,2,3,4]/[0,2,3,4,1]; [4,5,6,7,8,9,10,11]/[5,7,8,9,10,11,12,6]` |  |
| CY-604 | plus 7–3 | `0-1 0-4 1-2 2-3 3-4 4-5 4-11 5-6 6-7 7-8 8-9 9-10 10-11 7-3` | `chordlessCycles` | `[0,1,2,3,4]/[0,2,3,4,1]; [4,3,7,6,5]/[4,13,8,7,5]; [4,3,7,8,9,10,11]/[4,13,9,10,11,12,6]; [4,5,6,7,8,9,10,11]/[5,7,8,9,10,11,12,6]` | NetworkX adds [3..7] and [4,3,7,8,9,10,11] |
| CY-605 | NetworkX giant Hamiltonian, n = 12 | `hamladder(12)` | `chordlessCount` | `#7` | n/2 triangles and the cycle of evens |
| CY-606 | Petersen | `nx(petersen)` | `chordlessCount` | `#22` |  |
| CY-607 | hexagon with a long chord | `C(0..5) 0-3` | `chordlessCycles` | `[0,1,2,3]/[0,1,2,6]; [0,5,4,3]/[5,4,3,6]` |  |

## I. Representations (CY-700 – CY-729)

Rows with a Graph cell are checked by `ref.py`; the others name a test to write.

| ID | Source | Graph | Op | Expected | Note |
|---|---|---|---|---|---|
| CY-700 | every row of §A – §G on `ReferencePseudograph` / `ReferenceDirectedMultigraph` as written | — | — | — | Exact, positions included |
| CY-701 | `UndirectedAdjacencyList` / `AdjacencyList` built in written order, rows without repeats | — | — | — | Exact; rows with parallel edges or loops collapse on representations that store a set, and are pinned through the reference conformers only |
| CY-702 | `AdjacencyMatrix` (cells as positions, no edge indices), `CompressedSparseRow` | — | — | — | The same vertex sequences; positions are the representation's own |
| CY-703 | conformers without vertex indices, with vertex indices only, with both (private per file) | — | — | — | Same results; no vertex hashed on indexed graphs (counting conformer) |
| CY-704 | rows reversed | `K(4) ~rev` | `simpleCycles` | `[0,2,3]/[1,5,2]; [0,2,1,3]/[1,3,4,2]; [0,1,3,2]/[0,4,5,1]; [0,1,3]/[0,4,2]; [0,1,2,3]/[0,3,5,2]; [0,1,2]/[0,3,1]; [1,2,3]/[3,5,4]` | = CY-331 |
| CY-705 | rows rotated | `K(4) ~rot` | `simpleCycles` | `[0,2,1,3]/[1,3,4,2]; [0,2,3]/[1,5,2]; [0,1,2,3]/[0,3,5,2]; [0,1,2]/[0,3,1]; [0,1,3,2]/[0,4,5,1]; [0,1,3]/[0,4,2]; [1,2,3]/[3,5,4]` |  |
| CY-706 | rows rotated, directed | `D: DK(3) ~rot` | `simpleCycles` | `[0,2,1]/[1,5,2]; [0,2]/[1,4]; [0,1,2]/[0,3,4]; [0,1]/[0,2]; [1,2]/[3,5]` |  |
| CY-707 | `g.directed` of an undirected graph | `C(0..3) 0-2` | `directedCount` | `#11` | 2 × 3 cycles + 5 digons |
| CY-708 | `digraph.undirected` (bidirectional): antiparallel arcs become a 2-cycle | `0-1 1-0 1-2 2-0` | `simpleCycles` | `[0,1]/[0,1]; [0,1,2]/[0,2,3]; [0,1,2]/[1,2,3]` | Written as the undirected view's edges, arcs at their own positions |
| CY-709 | `String`, `Collider` vertices (hash collisions) | — | — | — | Same results as `Int` relabelled |
| CY-710 | an `UndirectedAdjacencyList` after removals (rows no longer in position order) against a `ReferencePseudograph` written in its own incidence order | — | — | — | As Connectivity's CN-401 |

## J. Properties against brute force (CY-750 – CY-779)

Checked by `ref.py` on 600 random multigraphs with loops (n ≤ 7, m ≤ 12, half directed), 400 more
with shuffled rows, and every catalog row; the Swift tests write each oracle inside the test.

| ID | Property |
|---|---|
| CY-750 | `simpleCycles()` equals a naive backtracking enumeration in content and in order (the order key computed per cycle) |
| CY-751 | Every emitted value is a `Cycle` of the graph (`Cycle(vertices:edges:in:)` accepts it) in canonical form; no two are `==` |
| CY-752 | For tiny graphs, the enumeration equals every ordered vertex subset times every parallel-edge choice |
| CY-753 | `simpleCycles(maxLength: k)` is the unbounded sequence filtered to `length <= k`, in the same order, for every k in 0 … n + 1 |
| CY-754 | Collapsing edge identity gives exactly NetworkX's `simple_cycles` (rotation, plus reversal undirected) |
| CY-755 | The count equals igraph's `simple_cycles` (edge identity) |
| CY-756 | `isAcyclic == (findCycle() == nil) == cycleBasis().isEmpty == simpleCycles().first == nil == (edgeCount == vertexCount − components)` |
| CY-757 | `cycleBasis().count == m − n + c`; its edge sets are independent over GF(2); every simple cycle lies in their span |
| CY-758 | `girth() == simpleCycles().map(\.length).min()` |
| CY-759 | `g.directed.simpleCycles().count == 2·(cycles of length ≥ 3) + 2·(2-cycles) + (non-loop edges) + 2·(loops)` |
| CY-760 | Directed: the converse graph's cycles are the reversed cycles (same edge sets) |
| CY-761 | Shuffling rows changes order only: the set of canonical cycles is invariant (CY-331) |
| CY-762 | Relabelling vertices (permuting `vertices`) maps cycles to cycles; only canonical starts and order change |
| CY-763 | Two iterations of the same sequence give equal arrays (the sequence restarts) |
| CY-764 | `findCycle(from: roots)` is nil exactly when no cycle is in the roots' components |
| CY-765 | Boost: `hawick_circuits` count is ours (directed) or `g.directed`'s (undirected); `hawick_unique_circuits` is the collapsed count |

## K. Stress (CY-800 – CY-829)

Graph cells here are plain text: `ref.py stress()` checks them by the algorithm and a closed
form, since brute force cannot. Swift tests run inside a `Task` and stay under two seconds in a
debug build; the benchmarks take the big sizes.

| ID | Source | Graph | Op | Expected | Note |
|---|---|---|---|---|---|
| CY-800 | NetworkX Johnson figure 1, k = 3 … 9 | D: johnson(k) | count | #3k | |
| CY-801 | figure 1, k = 1000 | D: johnson(1000) | count | #3000 | Linear per cycle; a naive search is not |
| CY-802 | 2³⁰ dead-end paths and one 2-cycle | D: diamonds(30) | simpleCycles | one 2-cycle | Johnson blocks after the first dead end; Tiernan would take 2³⁰ steps |
| CY-803 | 100 000-vertex directed cycle | D: C(0..99999) | count | #1 | No recursion: the path stack is 10⁵ deep |
| CY-804 | 100 000-vertex undirected cycle | C(0..99999) | findCycle, count | length 100000, #1 | |
| CY-805 | 100 000-vertex path | P(0..99999) | isAcyclic, count, cycleBasis | T, #0, none | Every block is a bridge: one decomposition, no search |
| CY-806 | JGraphT RESULTS[9] | D: DKL(9) | count | #125673 | |
| CY-807 | NetworkX A002807 | K(9) | count | #62814 | |
| CY-808 | lazy: the first cycle of K₂₀₀ | K(200) | first | [0,1,2]/[0,199,1] | Must not enumerate; time bounded by one search |
| CY-809 | 10 000 triangles in a chain | T(10000) | count | #10000 | Each triangle a block of its own |
| CY-810 | star of 10⁵ leaves, a loop on each | S(0;1..100000) then i-i for each leaf | count | #100000 | Wide rows, loops only |
| CY-811 | ladder 2 × 1000 | grid(2,1000) | count(maxLength: 4) | #999 | The squares, out of C(1000, 2) = 499 500 cycles |
| CY-813 | girth is O(n·m) on a long cycle: keep it small | C(0..1999), D: C(0..1999) | girth | 2000, 2000 | Every breadth-first search runs to the end: 4·10⁶ steps. At 10⁵ vertices it would be 10¹⁰ |
| CY-814 | girth stops early on a grid | grid(100,100) | girth | 4 | The first search finds a 4-cycle; every later one stops at depth 2 |
| CY-812 | NetworkX giant Hamiltonian, n = 1000, chordless (deferred) | hamladder(1000) | chordlessCount | #501 | |

## L. Preconditions and conformance (CY-850 – CY-879)

| ID | Case |
|---|---|
| CY-850 | `simpleCycles(maxLength: -1)` traps (NetworkX raises `ValueError`); `maxLength: 0` is empty |
| CY-851 | `findCycle(from:)` with a root that is not a vertex traps, as Traversal's directed form |
| CY-852 | The sequences are `Sendable` when the graph is; a `Task` can iterate one |
| CY-853 | Value semantics: mutating the graph after making the sequence does not change it |
| CY-854 | `underestimatedCount == 0`; the sequence is not a `Collection` |
| CY-855 | Laziness: `first` on a row-counting conformer reads only the rows one search reaches |
| CY-856 | Generic code over `some Graph` and `some DirectedGraph` gets the same results |
| CY-857 | Index space: on an indexed `UndirectedAdjacencyList` / `AdjacencyList` no vertex is hashed (counting `Collider`) |
| CY-858 | `Graph.isAcyclic` and `DirectedGraph.isAcyclic` never meet: no type conforms to both; `g.directed.isAcyclic` is false whenever g has an edge |
| CY-859 | Every returned `Cycle` survives `Codable` round trip and `==`/`hash` up to rotation |
| CY-860 | Rows that break the index laws trap (the unchecked buffers are checked once), as Connectivity's CN-404 |
