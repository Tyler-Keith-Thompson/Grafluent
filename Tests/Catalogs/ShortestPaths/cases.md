# ShortestPaths: case catalog

Cases for single-source shortest paths: Dijkstra (one or several sources, an optional inclusive
cutoff, a single-target query that stops when the target is settled), Bellman–Ford with
negative-cycle detection and a witness cycle, A*, unweighted (breadth-first) shortest paths, and
the `ShortestPathTree` result; k shortest simple paths (Yen), all shortest paths, bidirectional
Dijkstra, and all pairs by Johnson's algorithm and by Dijkstra from every vertex (section N). Undirected graphs go through `graph.directedView`. Case IDs `SP-nn`
are stable, so test names can refer to them.

## Sources

The Source column cites the test suites and code that cases were taken from (shallow clones, not kept in the repository):

| Library | Commit | Licence | What was used |
|---|---|---|---|
| Boost.Graph | `1ee1a99` | BSL-1.0 | `relax.hpp`, `dijkstra_shortest_paths.hpp`, `bellman_ford_shortest_paths.hpp`, `astar_search.hpp`, `example/dijkstra-example.cpp` + `dijkstra.expected`, `example/bellman-example.cpp` + `bellman_ford.expected`, `test/bellman-test.cpp` |
| NetworkX | `6da4704` | BSD-3-Clause | `algorithms/shortest_paths/{weighted,astar,unweighted}.py` and `tests/test_{weighted,astar}.py` |
| petgraph | `a4d94bd` | MIT OR Apache-2.0 | `src/algo/{dijkstra,bellman_ford,astar,spfa,mod}.rs`, `src/csr.rs` tests, `tests/spfa.rs`, `tests/quickcheck.rs` |
| JGraphT | `63976aa` | EPL-2.0 OR LGPL-2.1+ | `alg/shortestpath/{BellmanFordShortestPath,AStarShortestPath}.java`, `alg/interfaces/ShortestPathAlgorithm.java`, tests `{BellmanFord,Dijkstra}ShortestPathTest.java`, `ShortestPathTestCase.java` |
| LEMON | `31d79d6` | Boost-style | `lemon/bellman_ford.h`, `lemon/dijkstra.h` |
| igraph | `912f99d` | GPL-2.0+ (**behavior reference only; no code copied**) | `src/paths/dijkstra.c` (weight validation, infinite weights), `include/igraph_paths.h` |
| gonum | `0d48cee` | BSD-3-Clause | `graph/path/{dijkstra,bellman_ford_moore,shortest,weight}.go` |
| rustworkx | `25398ab` | Apache-2.0 | `src/lib.rs` (`edge_weights_from_callable`, `is_valid_weight`), `src/shortest_path/mod.rs` |
| scipy | `ec1861f` | BSD-3-Clause | `sparse/csgraph/_shortest_path.pyx` (`limit`, `min_only`), `tests/test_shortest_path.py` |

## How the expectations were computed

Values marked **(ref)** come from an independent Python reference written for this catalog,
`ref.py` (next to this file): a lazy-deletion Dijkstra that can be run with four tie orders (FIFO,
LIFO, ascending and descending vertex index), the tie rule computed directly from the distances,
Bellman–Ford in weak rounds with a parent-pointer walk for the witness, A* with reopening,
breadth-first search, and Floyd–Warshall as the oracle. `check.py` runs 3000 seeded random
multigraphs (n ≤ 30, p ∈ {0.05, 0.15, 0.3, 0.6}, half with negative weights, half with parallel
edges). On each it checks Dijkstra distances against Floyd–Warshall and NetworkX
`single_source_dijkstra_path_length` (**nx**); that all four tie orders give a parent the tie rule
allows, and the same parent whenever the rule determines it; A* with a zero, a consistent and an
inconsistent admissible heuristic against Floyd–Warshall; Bellman–Ford distances against
Floyd–Warshall, and that every reported negative cycle is reachable, simple, made of edges and
negative; and breadth-first distances against NetworkX. `cases.py`, `cases_bf.py`,
`cases_astar.py` and `bfcheck.py` print every value quoted below. Expectations taken from other
test suites are marked with their source and were re-derived by the reference; where the source
reports a different but equally valid answer (another rotation of the same cycle, another tie),
both are given.

## Orders

As in the Connectivity catalog: "ascending" (AM, CSR) means vertices ascending and out-edges by ascending target, parallel edges impossible. "Written" (`ReferenceDirectedMultigraph`, abbreviated MG) means listed vertices first, then endpoints by first appearance, out-edges in written order with repeats; edge positions are list positions `e0, e1, …` (`GF:Tests/GrafluentTestSupport/ReferenceDirectedMultigraph.swift:7-10`). An undirected edge list `p0, p1, …` built into `UndirectedAdjacencyList` or `ReferencePseudograph` in that order is read through `graph.directedView`, whose arcs are `(position: pk, reversed:)`, forward running from the edge's stored `u` to `v` (`GF:Sources/GraphProtocols/GraphViews.swift:6-13, 55-75`).

## Path prefixes

Prefixes in the Source column, relative to the root of those clones:

| Prefix | Expands to |
|---|---|
| `bgl-relax:` / `bgl-dij:` / `bgl-bf:` / `bgl-astar:` | `graph/include/boost/graph/relax.hpp` / `dijkstra_shortest_paths.hpp` / `bellman_ford_shortest_paths.hpp` / `astar_search.hpp` |
| `bgl-ex:` / `bgl-T:` | `graph/example/` / `graph/test/` |
| `nx-w:` / `nx-a:` / `nx-u:` | `networkx/networkx/algorithms/shortest_paths/weighted.py` / `astar.py` / `unweighted.py` |
| `nx-Tw:` / `nx-Ta:` | `.../shortest_paths/tests/test_weighted.py` / `tests/test_astar.py` |
| `pg-dij:` / `pg-bf:` / `pg-astar:` / `pg-spfa:` / `pg-mod:` | `petgraph/crates/petgraph/src/algo/dijkstra.rs` / `bellman_ford.rs` / `astar.rs` / `spfa.rs` / `mod.rs` |
| `pg-csr:` / `pg-Tspfa:` / `pg-Q:` | `petgraph/crates/petgraph/src/csr.rs` / `tests/spfa.rs` / `tests/quickcheck.rs` |
| `jgt:` / `jgt-I:` / `jgt-T:` | `jgrapht/jgrapht-core/src/main/java/org/jgrapht/alg/shortestpath/` / `.../alg/interfaces/ShortestPathAlgorithm.java` / `jgrapht-core/src/test/java/org/jgrapht/alg/shortestpath/` |
| `lemon-bf:` / `lemon-dij:` | `lemon/lemon/bellman_ford.h` / `lemon/lemon/dijkstra.h` |
| `ig-dij:` | `igraph/src/paths/dijkstra.c` |
| `go-path:` | `gonum/graph/path/` |
| `rx-lib:` / `rx-sp:` | `rustworkx/src/lib.rs` / `rustworkx/src/shortest_path/mod.rs` |
| `sp-T:` / `sp-pyx:` | `scipy/scipy/sparse/csgraph/tests/test_shortest_path.py` / `.../csgraph/_shortest_path.pyx` |
| `GF:` | the Grafluent repository |

---

## How tests pin values

1. **Distances are exact everywhere.** They are unique, so they are pinned on every representation.
2. **Dijkstra and A* parents and paths** are exact where the tie rule determines them, and checked by membership where it does not. The tie rule: the first relaxation to a vertex's final distance wins, so when the shortest-path predecessors of `v` with the smallest distance are all one vertex `u`, the parent is `u` and the parent edge is `u`'s first such edge in `outEdges(of: u)` order. Every case below says which. The tables give parents as `vertex eK` (MG positions, or CSR edge indices for ascending fixtures) or `vertex (pK, fwd/rev)` for arcs of `graph.directedView`.
3. **Bellman–Ford parents** are exact where the shortest-path predecessor is unique. That holds in every Bellman–Ford case below (`bfcheck.py` lists the candidates). Elsewhere they are checked by the tree laws (SP-102). Witness cycles, rotated to start at their first vertex in `vertices` order, are exact wherever exactly one simple negative cycle is reachable.
4. **Unweighted parents** are exact in `outEdges` order (first discovery).
5. **Representations.** AM and CSR take `Int` fixtures with weights in a side array (CSR by edge index, AM by cell); the MG takes everything, including `String` vertices and parallel edges, with weights by position; `AdjacencyList` takes weights through `[DirectedEdge: W]` (it has no parallel edges, so endpoints are a key). It gets distances exactly and parents exactly where determined, because the tie rule does not depend on out-edge order without parallel edges. Undirected fixtures run on `UndirectedAdjacencyList.directedView` and, for parallel edges, `ReferencePseudograph.directedView`, weights by `$0.position`.

Every test inlines its graph and weights (no shared helpers); fixtures from `GrafluentTestSupport` are used only for their edge lists.

---

## Cases

### A. Dijkstra: basics

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-01 | One vertex, no edges | `{0}` from 0 → `distance(to: 0) == 0`, `parent(of: 0) == nil`, `parentEdge(of: 0) == nil`, `path(to: 0) == [0]`, `hasPath(to: 0)`, `sources == [0]` | nx-Tw:504-512 (single node) |
| SP-02 | Unreachable vertices | two vertices, no edges, from 0 → `distance(to: 1) == nil`, `parent(of: 1) == nil`, `path(to: 1) == nil`, `hasPath(to: 1) == false` | jgt-T:BellmanFordShortestPathTest.java:79-90 (`testNoPath`) |
| SP-03 | A path | 0→1→2→3 weights 1 → distances `[0, 1, 2, 3]`, parents `[nil, 0, 1, 2]`, `path(to: 3) == [0, 1, 2, 3]` | nx-Tw:271-276 |
| SP-04 | **NetworkX's XG** (the CLRS figure 24.6 graph). MG written: s→u 10 e0, s→x 5 e1, u→v 1 e2, u→x 2 e3, v→y 1 e4, x→u 3 e5, x→v 5 e6, x→y 2 e7, y→s 7 e8, y→v 6 e9 | from s: distances s 0, u 8, x 5, v 9, y 7; parents (all determined) u ← x e5, x ← s e1, v ← u e2, y ← x e7; `path(to: v) == [s, x, u, v]` (nx) | nx-Tw:45-58, 113-128 |
| SP-05 | XG from every other source | from u: s 9 (y e8), x 2 (u e3), v 1 (u e2), y 2 (v e4); from v: s 8 (y e8), u 16 (x e5), x 13 (s e1), y 1 (v e4); from x: s 9 (y e8), u 3 (x e5), v 4 (u e2), y 2 (x e7); from y: s 7 (y e8), u 15 (x e5), x 12 (s e1), v 6 (y e9) (ref) | — |
| SP-06 | **Boost's example**, A…E = 0…4: A→C 1, B→B 2, B→D 1, B→E 2, C→B 7, C→D 3, D→E 1, E→A 1, E→B 1 | from 0 → distances `[0, 6, 1, 4, 5]`; parents 1 ← 4, 2 ← 0, 3 ← 2, 4 ← 3 (the expected tree "0 → 2, 2 → 3, 3 → 4, 4 → 1"); on MG the parent edges are e8, e0, e5, e6; on CSR (ascending rows) the same edges at indices 8, 0, 5, 6 | bgl-ex:dijkstra-example.cpp:36-38, `dijkstra.expected` |
| SP-07 | JGraphT's shortest-path tree, `Double` weights, vertices 1…5: 1→2 3.0 e0, 2→4 1.0 e1, 1→3 1.0 e2, 3→2 1.0 e3, 3→4 3.0 e4 | from 1 → 1: 0, 2: 2.0 (3 e3), 3: 1.0 (1 e2), 4: 3.0 (2 e1), 5: nil; `path(to: 4) == [1, 3, 2, 4]` | jgt-T:DijkstraShortestPathTest.java:63-113 |
| SP-08 | **scipy's `directed_G`** (5 vertices; 0→1 3, 0→2 3, 1→3 2, 1→4 4, 3→0 1, 4→0 2, 4→3 2), all five sources, AM/CSR | distance rows `[0,3,3,5,7]`, `[3,0,6,2,4]`, `[nil,nil,0,nil,nil]`, `[1,4,4,0,8]`, `[2,5,5,2,0]`; parent rows equal to scipy's `directed_pred`: `[-,0,0,1,1]`, `[3,-,0,1,1]`, `[-,-,-,-,-]`, `[3,0,0,-,1]`, `[4,0,0,4,-]`, every entry determined (ref, scipy) | sp-T:17-56 |
| SP-09 | **scipy's `undirected_G` via `directedView`** (`UndirectedAdjacencyList` edges p0 {0,1} 3, p1 {0,2} 3, p2 {0,3} 1, p3 {0,4} 2, p4 {1,3} 2, p5 {1,4} 4, p6 {3,4} 2) | distance rows equal `undirected_SP`: `[0,3,3,1,2]`, `[3,0,6,2,4]`, `[3,6,0,4,5]`, `[1,2,4,0,2]`, `[2,4,5,2,0]`; parent rows equal `undirected_pred`: `[-,0,0,0,0]`, `[1,-,0,1,1]`, `[2,0,-,0,0]`, `[3,3,0,-,3]`, `[4,4,0,4,-]`. From 1, vertex 0 is reached at 3 both directly and via 3; the rule picks 1 (distance 0 < 2), as scipy does. Parent edges from 1: 0 ← (p0, rev), 2 ← (p1, fwd), 3 ← (p4, fwd), 4 ← (p5, fwd) | sp-T:23-60 |
| SP-10 | NetworkX XG2 (1→4 1, 4→5 1, 5→6 1, 6→3 1, 1→3 50, 1→2 100, 2→3 100) | from 1 → 3 at 4 via `[1, 4, 5, 6, 3]`, 2 at 100 | nx-Tw:62-73, 141 |
| SP-11 | NetworkX XG3 undirected (p0 {0,1} 2, p1 {1,2} 12, p2 {2,3} 1, p3 {3,4} 5, p4 {4,5} 1, p5 {5,0} 10) | from 0 → `[0, 2, 14, 15, 11, 10]`; `path(to: 3) == [0, 1, 2, 3]` (15); 4 ← 5 (p4, rev), 5 ← 0 (p5, rev) | nx-Tw:75-78, 142-143 |

### B. Ties, self-loops, parallel edges, zero weights

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-12 | **A self-loop never becomes a parent**, even of weight 0 at the source | 0→0 0, 0→1 2, 1→1 0, 1→2 1 → distances `[0, 2, 3]`, `parent(of: 0) == nil`, `parent(of: 1) == 0`, `parent(of: 2) == 1`; Boost's B→B 2 (SP-06) is not B's parent | definition |
| SP-13 | **Parallel edges with different weights** (MG) | petgraph `spfa_multiple_edges`: 0→1 10 e0, 0→1 1 e1, 0→2 4 e2, 0→3 10 e3, 1→2 2 e4, 1→3 2 e5, 2→3 2 e6, 0→3 100 e7, 2→3 20 e8, 0→0 5 e9 → distances `[0, 1, 3, 3]`, parents 1 ← 0 **e1**, 2 ← 1 e4, 3 ← 1 e5 | pg-Tspfa:255-315 |
| SP-14 | **Equal parallel copies: the first in `outEdges` order** (MG) | 0→1 5 e0, 0→1 5 e1 → `parentEdge(of: 1) == 0`; written in the other order with weights 7, 5 → `parentEdge(of: 1) == 1` | — |
| SP-15 | NetworkX multigraphs | MXG (XG plus s→u 15 as e10) → same as SP-04, u's parent edge still e5; `a–b` 100 and 110 (MG, both arcs of each in `ReferencePseudograph.directedView`) → `{a: 0, b: 100}`, parent edge the 100 copy | nx-Tw:60-61, 126-128, 323-329 |
| SP-16 | MXG4 = XG4 plus a parallel {0,1} of weight 3 (`ReferencePseudograph`) | from 0 → `[0, 2, 4, 5, 4, 3, 2, 1]`; 1's parent edge is the weight-2 edge (p0), not the parallel p8; 3's parent unspecified ∈ {2 via p2, 4 via p3} (both at distance 4) | nx-Tw:80-93, 145-146 |
| SP-17 | Zero-weight edges and a zero-weight cycle | 0→1 0, 1→2 0, 2→1 0, 2→3 1 → distances `[0, 0, 0, 1]`; 2 ← 1 and 3 ← 2 are determined; for 1 the rule allows {0, 2} (both at distance 0), and the tree law of SP-102 (no cycle of parents) forces 0 | — |
| SP-18 | **A tie between two predecessors: unspecified, but in the candidate set** | NetworkX 4-cycle undirected (p0 {0,1}, p1 {1,2}, p2 {2,3}, p3 {3,0}, unit) from 0 → distances `[0, 1, 2, 1]`; `parent(of: 2) ∈ {1, 3}` with the matching parent edge (p1, fwd) or (p2, rev); `parent(of: 1) == 0`, `parent(of: 3) == 0` | nx-Tw:278-286 |
| SP-19 | **A tie decided by distance is determined** | 0→1 1, 0→2 3, 1→3 3, 2→3 1 → 3 at 4 from 1 (distance 1) and from 2 (distance 3): `parent(of: 3) == 1`. Same on every representation and every random insertion order of `AdjacencyList` | — |
| SP-20 | Undirected XG (u–x weight 2) | from s → s 0, u 7, x 5, v 8, y 7; u ← x, x ← s, y ← s; `parent(of: v) ∈ {u, y}` (both at 7) | nx-Tw:130-138 |

### C. Single target, sources, cutoff

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-21 | **Early exit stops when the target is settled** | XG `dijkstraShortestPath(from: s, to: v)` → `(path: [s, x, u, v], distance: 9)`. v is first *reached* through x at 10 | nx-Tw:113-128; §P |
| SP-22 | Single target: unreachable, same vertex | XG plus isolated `moon`: `dijkstraShortestPath(from: s, to: moon) == nil`; `(from: s, to: s)` → `([s], 0)`; NetworkX cycle_graph(7) `(0, 0)` → `([0], 0)` | nx-Tw:156-163 |
| SP-23 | **Two sources** | NetworkX: undirected p0 {0,1} 1, p1 {1,2} 1, p2 {2,3} 10, p3 {3,4} 1, sources [0, 4] → distances `{0: 0, 1: 1, 2: 2, 3: 1, 4: 0}`; paths 1: `[0, 1]`, 2: `[0, 1, 2]`, 3: `[4, 3]`, 4: `[4]`; both sources have `parent == nil` | nx-Tw:484-493 |
| SP-24 | A source reached from another source keeps distance 0 and no parent | sources [0, 1], 0→1 0 → `parent(of: 1) == nil`, `distance(to: 1) == 0`; repeated sources `[0, 0]` behave as `[0]` | — |
| SP-25 | **Cutoff is inclusive** | XG from s, cutoff 8 → v not reached (`distance(to: v) == nil`), u reached at exactly 8; MXG4 cutoff 2 → reached `{0, 1, 6, 7}` (1 and 6 at exactly 2), 2 not reached | nx-Tw:304-308, 310-314 |
| SP-26 | scipy `limit = 2` on `undirected_G` | reached per source: 0 → `{0: 0, 3: 1, 4: 2}`; 1 → `{1: 0, 3: 2}`; 2 → `{2: 0}`; 3 → `{0: 1, 1: 2, 3: 0, 4: 2}`; 4 → `{0: 2, 3: 2, 4: 0}` (scipy `undirected_SP_limit_2`) | sp-T:38-42 |
| SP-27 | Cutoff 0 and a negative cutoff | cutoff 0 on `undirected_G` → only the source (scipy `undirected_SP_limit_0`); cutoff −1 → only the source | sp-T:43-44 |

### D. Weight edge cases

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-35 | **A negative edge traps, even where the answer could be "repaired"** | s→a 2, s→b 1, b→a −5: `dijkstraShortestPaths(from: s)` traps (exit test). Without the check, b settles first and *decreases* a, so no accidental queue trap would fire | nx-Tw:331-347 |
| SP-36 | **An unexamined negative edge does not trap** | s→a 1, b→c −1 (b unreachable) → distances `{s: 0, a: 1}`, no trap. s→a −1 traps even with `cutoff: 0`, because s's out-edges are examined before the cutoff test | bgl-dij:174-204; go-path:dijkstra.go:16 |
| SP-37 | `Int` sums near the limit | 0→1 `Int.max / 2`, 1→2 `Int.max / 2` → `distance(to: 2) == Int.max - 1` | — |
| SP-38 | **Overflow traps** | 0→1 `Int.max / 2 + 1`, 1→2 `Int.max / 2 + 1` → traps (exit test); Bellman–Ford the same | — |
| SP-39 | `Double.infinity` | s→a +∞, s→b 1, b→a 2 → a at 3.0, parent b; s→c +∞ only → `distance(to: c) == .infinity`, `path(to: c) == [s, c]` | contrast ig-dij:243-245 |
| SP-40 | NaN and −∞ trap | a NaN weight on an examined edge traps in Dijkstra, A* and Bellman–Ford; −∞ traps in Dijkstra (negative); in Bellman–Ford, +∞ and −∞ meeting in one sum trap (NaN) | — |
| SP-41 | Other weight types | the SP-04 graph with `Double`, `Float`, `UInt8` weights (distances fit), and `Duration` → the same distances; a user `struct Cost: Comparable, AdditiveArithmetic` works | — |
| SP-42 | The weight closure sees positions, not endpoints | on the MG, a closure that records every position it is called with → each examined edge exactly once per examination, positions in `0..<edgeCount`; a parallel copy is asked separately | — |

### E. Bellman–Ford: distances

All parents below are the unique shortest-path predecessors, so they are exact on every representation.

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-50 | **CLRS figure 24.4 (Boost's example)**: u→y −4, u→x 8, u→v 5, v→u −2, x→y 9, x→v −3, y→v 7, y→z 2, z→u 6, z→x 7 | from z → u 2 (v), v 4 (x), x 7 (z), y −2 (u), z 0; on the MG parent edges u e3, v e5, x e9, y e0 | bgl-ex:bellman-example.cpp:61-63, `bellman_ford.expected` |
| SP-51 | Negative edges, no cycle | NetworkX cycle5 with 1→2 −3 from 0 → `{0: 0, 1: 1, 2: -2, 3: -1, 4: 0}`, parents `{1: 0, 2: 1, 3: 2, 4: 3}`, paths `[0]`, `[0,1]`, `[0,1,2]`, `[0,1,2,3]`, `[0,1,2,3,4]` | nx-Tw:642-670 |
| SP-52 | JGraphT's Wikipedia example (`Double`): w→z 2, y→w 4, x→w 6, x→y 3, z→x −7, y→z 5, z→y −3, and s→{w, y, x, z} 0 | from s → w −1 (x), y −4 (x), x −7 (z), z 0 (s), s 0 | jgt-T:BellmanFordShortestPathTest.java:93-121 |
| SP-53 | JGraphT negated bias graph (directed): V1→V2 −2, V1→V3 −3, V2→V4 −5, V3→V4 −20, V4→V5 −5, V1→V5 −100 | from V1 → V4 −23 via `[V1, V3, V4]`, V5 −100 via `[V1, V5]` | jgt-T:BellmanFordShortestPathTest.java:65-76; `ShortestPathTestCase.java:84-114` |
| SP-54 | **Undirected through `directedView`**, JGraphT's graph (p0 V1V2 2, p1 V1V3 3, p2 V2V4 5, p3 V3V4 20, p4 V4V5 5, p5 V1V5 100) | from V3 → V1 3, V2 5, V3 0, V4 10, V5 15; path to V5 `[V3, V1, V2, V4, V5]` with parent edges (p1, rev), (p0, fwd), (p2, fwd), (p4, fwd), JGraphT's `e13, e12, e24, e45` | jgt-T:BellmanFordShortestPathTest.java:39-55 |
| SP-55 | **Boost's undirected regression**: A, B, Z with one edge {B, A} 11 (stored B first) | from A → B 11, parent A, parent edge (p0, rev); Z unreached ("B: 2147483647 B" was the bug) | bgl-T:bellman-test.cpp:8-15 |
| SP-56 | petgraph doc example (`Double`): 0→1 2, 0→3 4, 1→2 1, 1→5 7, 2→4 5, 4→5 1, 3→4 1 | from 0 → `[0, 2, 3, 4, 5, 6]`, parents `[nil, 0, 1, 0, 3, 4]` | pg-bf:40-80 |
| SP-57 | petgraph CSR test (`Double`, AM/CSR): 0→1 0.5, 0→2 2, 1→0 1, 1→1 1, 1→2 1, 1→3 1, 2→3 3, 4→5 1, 5→7 2, 6→7 1, 7→8 3 | from 0 → `[0, 0.5, 1.5, 1.5]`, vertices 4…8 unreached (petgraph checks `is_infinite`); CSR parent edges 1 ← e0, 2 ← e4, 3 ← e5 | pg-csr:1066-1087 |
| SP-58 | Unreachable negative cycle is ignored | JGraphT: 1→2→3→4 (1 each), 5→4 1, 5→6 −1, 6→7 −1, 7→5 −1 → from "1": `{1: 0, 2: 1, 3: 2, 4: 3}`, 5, 6, 7 unreached; `findNegativeCycle(from: "1") == nil`; `findNegativeCycle(weight:)` (whole graph) → `["5", "6", "7"]` | jgt-T:BellmanFordShortestPathTest.java:239-262 |
| SP-59 | Bellman–Ford equals Dijkstra on nonnegative weights | SP-04 – SP-11 graphs → identical distances; parents identical where both are determined | pg-Q:1046-1062 |
| SP-60 | **Zero-weight cycles are not negative** | NetworkX cycle5 with 2→3 −4 (total 0) from 1 → tree `{0: -1, 1: 0, 2: 1, 3: -3, 4: -2}`; the heuristic graph 0→1 −1, 1→2 −1, 2→3 −1, 3→0 3 → tree `{0: 0, 1: -1, 2: -2, 3: -3}`, and with 2→0 2 added still a tree | nx-Tw:533-543, 612-624 |
| SP-61 | Multiple sources | NetworkX cycle5 (unit) with every vertex a source → every distance 0, no parents | nx-w:2144-2210 (`negative_edge_cycle` adds a super-source) |

### F. Negative cycles and witnesses

Witnesses after the witness rotation (ref). `bellmanFordShortestPaths` returns `nil` in every case of this section.

| ID | Asserts | Graph → witness | Source |
|---|---|---|---|
| SP-62 | Directed 5-cycle with 1→2 −7, from each of 0…4 | `[0, 1, 2, 3, 4]` from every source (NetworkX raises from every source) | nx-Tw:562-576 |
| SP-63 | **An undirected negative edge is a 2-cycle** | undirected 5-cycle with {1,2} −3, from each of 0…4 → `[1, 2]`; NetworkX's single edge {0,1} −1 from 1 → `[0, 1]` (NetworkX `[1, 0, 1]`); petgraph's undirected doc graph from 0 → `[0, 1]` | nx-Tw:577-590, 637-640; pg-bf:83-94 |
| SP-64 | A negative self-loop | `{1}` with 1→1 −1 → `[1]`; petgraph `find_neg_cycle1` (CSR, 1→1 −1) → `[1]`; on the MG, 1→1 −1 written twice → `[1]` | nx-Tw:591-611; pg-csr:1105-1119 |
| SP-65 | Barely negative | cycle5 with 2→3 −4.0001 from 1 → `[0, 1, 2, 3, 4]`; heuristic graph plus 2→0 1.999 → `[0, 1, 2]` | nx-Tw:533-543, 619-624 |
| SP-66 | **The cycle is not where the search starts** | NetworkX's longer cycle (cycle5, plus 3→5→6→7→8→9→3 unit, 1→2 −30): from 1 → `[0, 1, 2, 3, 4]` (NetworkX `[0, 1, 2, 3, 4, 0]`); from 7 → `[0, 1, 2, 3, 4]` (NetworkX `[2, 3, 4, 0, 1, 2]`, another rotation) | nx-Tw:626-631 |
| SP-67 | Docstring and doc examples | NetworkX `[(0,1,2),(1,2,2),(2,0,1),(1,4,2),(4,0,-5)]` from 0 → `[0, 1, 4]` (NetworkX `[4, 0, 1, 4]`); petgraph doc (AM/CSR) 0→1 1, 0→2 1, 0→3 1, 1→3 1, 2→1 1, 3→2 −3 from 0 → `[1, 3, 2]`, exactly petgraph's answer | nx-w:2246-2251; pg-bf:150-165 |
| SP-68 | JGraphT's cycles | Wikipedia graph with y→z 3 → `["y", "z", "x"]` (JGraphT: start x, 3 edges, weight −1); undirected w–y 1, y–x 1, y–x −1 (`ReferencePseudograph`) from w → `["y", "x"]` (JGraphT: 2 edges, weight −2); testNegativeCycle (1→…→9, 7→x −3, x→4 −3) from "1" → `["4", "5", "6", "7", "x"]` (JGraphT: start "6", 5 edges, weight −3); 1→2→3→4→1 (−5) → `["1", "2", "3", "4"]` (weight −2) | jgt-T:BellmanFordShortestPathTest.java:154-190, 211-237, 264-307, 309-345 |
| SP-69 | Whole-graph search | cycle5 plus 8→9 −7, 9→8 3: `findNegativeCycle(weight:)` → `[8, 9]`; `findNegativeCycle(from: 0) == nil`; cycle5 alone → `nil` | nx-Tw:331-347 |
| SP-69a | Witness laws | for every witness: its vertices are distinct, each consecutive pair (and last → first) is an edge, the cheapest such edges sum to < 0, the first vertex has the smallest index of the cycle, and it is reachable from a source | — |

### G. A*

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-70 | **`h ≡ 0` is Dijkstra** | XG s→v → `([s, x, u, v], 9)`; XG2 1→3 → `([1, 4, 5, 6, 3], 4)`; XG3 undirected 0→3 → `([0, 1, 2, 3], 15)`; XG4 undirected 0→2 → `([0, 1, 2], 4)` | nx-Ta:43-45, 87-122 |
| SP-71 | **Inconsistent but admissible heuristic: still shortest (reopening)** | n5→n1 11, n5→n2 9, n2→n1 1, n1→n0 32, h = {n5: 36, n2: 4, n1: 0, n0: 0} → `([n5, n2, n1, n0], 42)`; without reopening `([n5, n1, n0], 43)` | nx-Ta:124-138 (GH 3464) |
| SP-72 | A parent is not overwritten by a worse re-expansion | a→b 1, a→c 1, b→d 2, c→d 1, d→e 1 → `([a, c, d, e], 3)` | nx-Ta:140-154 |
| SP-73 | Unweighted XG-like graph (weights 1) | `astar_w1` graph s→v → `([s, u, v], 2)` | nx-Ta:161-179 |
| SP-74 | Unreachable target | XG plus `moon`: `aStarShortestPath(from: s, to: moon) == nil` | nx-Ta:181-183 |
| SP-75 | Cycle graphs | undirected 7-cycle 0→3 → `([0, 1, 2, 3], 3)`; 0→4 → `([0, 6, 5, 4], 3)` | nx-Ta:223-226 |
| SP-76 | A heuristic large at the source only | XG with h = {s: 36, y: 4, x: 0, u: 0, v: 0} → distance 9 (h(s) never matters) | nx-Ta:192-203 |
| SP-77 | Grid, Manhattan heuristic, ties | 4 × 4 unit grid (undirected), (0,0)→(3,3) → distance 6; the path is a monotone staircase (tie-dependent: `check` that it has 7 vertices, each step +1 in a coordinate) | nx-Tw:42 (grid fixture) |
| SP-78 | Weighted grid, unique answer | 6 × 6 grid, the 60 weights listed in `cases_astar.py` output (seed 5), Manhattan to (5,5) → distance 25, path `(0,0) (0,1) (1,1) (2,1) (2,2) (2,3) (2,4) (2,5) (3,5) (4,5) (5,5)`; equals Dijkstra | (ref) |
| SP-79 | Multiple optimal paths, slightly inadmissible h | undirected a–b 0.18, a–c 0.68, b–c 0.50, c–d 0.67, h = {a: 1.35, b: 1.18, c: 0.67, d: 0} → path ∈ {`[a, c, d]`, `[a, b, c, d]`}, distance 1.35 (both sums are exactly 1.35 in `Double`) | nx-Ta:25-41 |
| SP-80 | **Inadmissible heuristic: a path, not necessarily shortest** | XG with h = {s: 36, y: 14, x: 10, u: 10, v: 0} → `([s, x, v], 10)` (shortest is 9). The documented law: the result is a path and its distance ≥ the Dijkstra distance | nx-Ta:205-217 |
| SP-81 | Negative weights trap; source == target | an examined negative edge traps (as SP-35); `(from: s, to: s)` → `([s], 0)` without calling the heuristic on another vertex | — |

### H. Unweighted shortest paths

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-85 | XG without weights (MG) | from s → u 1 (s e0), x 1 (s e1), v 2 (u e2), y 2 (x e7); `path(to: v) == [s, u, v]` | nx-Tw:94-111, 147-153 |
| SP-86 | **First discovery wins, deterministic** | 4-cycle undirected from 0 → `parent(of: 2) == 1`, parent edge (p1, fwd) (1 is dequeued before 3) | — |
| SP-87 | Multiple sources | undirected path 0–1–2–3–4, sources [0, 4] → distances `[0, 1, 2, 1, 0]`, parents `[nil, 0, 1, 4, nil]` | — |
| SP-88 | scipy's unweighted `directed_G` (AM/CSR) | from 0 → `[0, 1, 1, 2, 2]`, parents `[nil, 0, 0, 1, 1]`; from 1 → `[2, 0, 3, 1, 1]`, parents `[3, nil, 0, 1, 1]`; from 3 → `[1, 2, 2, 0, 3]`; from 4 → `[1, 2, 2, 1, 0]` | sp-T:30 (`unweighted_G`) |
| SP-89 | petgraph's Dijkstra doc graph with unit weights | from 1 → `[3, 0, 1, 2, 1, 2, 3, 4, nil]`, equal to `dijkstraShortestPaths` with `{ _ in 1 }`, and to Traversal's `breadthFirstLayers` | pg-dij:47-90 |

### I. Representations and weight styles

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-90 | **Same answers on every representation** | SP-04 (String: MG and `AdjacencyList<String>`), SP-06, SP-08, SP-13 (MG only), SP-50 on AM (cell side matrix), CSR (edge-index array via `init(vertexCount:edges:edgeIndices:)`), `AdjacencyList` (`[DirectedEdge: W]`), MG (position array) → identical distances, identical determined parents, identical witnesses | — |
| SP-91 | `AdjacencyMatrix` cell weights | AM of `directed_G`, `weight: { w[$0.source][$0.target] }` → SP-08 | — |
| SP-92 | Undirected graphs | SP-09 on `UndirectedAdjacencyList.directedView` and through the `Graph` overloads → the same distances and parents; the parent edges are `DirectedView` arcs with the base position | — |
| SP-93 | `AdjacencyList.undirectedView.directedView` (opposite arcs become parallel edges) | AL with 0→1 3 and 1→0 5, viewed undirected then directed, weights by arc position → from 0: 1 at 3 | `GF:Sources/GraphProtocols/GraphViews.swift:16-24` |
| SP-94 | A conformer without vertex indices | a test-local `DictionaryGraph` with SP-04's edges → the SP-04 result (dictionary path) | — |
| SP-95 | Edge positions survive the CSR initializer | build CSR from SP-06's edges in a shuffled order with `edgeIndices:`, place weights through it → SP-06 | `GF:Sources/CompressedSparseRowModule/CompressedSparseRow.swift:76-79` |

### J. Properties (seeded random graphs)

`SeededRandomNumberGenerator`; n ∈ {1, 2, 5, 10, 30}, p ∈ {0.05, 0.2, 0.5}, self-loops and (MG) parallel edges allowed, weights `Int` in 0…10 (nonnegative) or −3…10, 50 graphs per cell; every oracle inside the test.

| ID | Property | Source |
|---|---|---|
| SP-100 | **Dijkstra = Floyd–Warshall** (test-local, O(n³)) on nonnegative weights: every distance, and `nil` iff unreachable | `check.py` |
| SP-101 | **Bellman–Ford = Floyd–Warshall** when no negative cycle is reachable; `nil` iff some vertex reachable from the source has a negative Floyd–Warshall diagonal | `check.py` |
| SP-102 | **Tree laws**, for Dijkstra, Bellman–Ford and unweighted: a source has distance 0 and no parent; for every other reached v, `parentEdge` runs from `parent` to v and `distance(v) == distance(parent) + weight(parentEdge)`; following parents reaches a source without repeating; `path(to:)` is that walk reversed, and its weights sum to `distance(to:)` | pg-Q:773-795 (`dijkstra_triangle_ineq`) |
| SP-103 | **Triangle inequality**: for every edge u→v with u reached, v is reached and `distance(v) <= distance(u) + w` (with cutoff: whenever `distance(u) + w <= cutoff`) | pg-Q:773-795 |
| SP-104 | the tie rule: wherever the test-local rule says determined, `parent(of:)` equals it; otherwise it is a candidate | — |
| SP-105 | A* with `h ≡ 0`, with h = ⌊exact distance to target / 2⌋ (consistent), and with a random admissible inconsistent h → distance equals Dijkstra's; the path is a path whose weights sum to it | pg-Q:797-860 (`astar_compare_with_dijkstra`) |
| SP-106 | `dijkstraShortestPath(from:to:)` equals the tree's `distance(to:)` and its path is a valid shortest path | — |
| SP-107 | `shortestPaths(from:)` distances equal Dijkstra's with `{ _ in 1 }`; its parents are exact (first discovery), Dijkstra's are checked only by the SP-102 laws | — |
| SP-108 | Reweighting invariance: with random potentials π, `w'(u→v) = w + π(u) − π(v) ≥ 0` (built from Bellman–Ford distances from a super-source, as Johnson does) → `dist'(v) = dist(v) + π(s) − π(v)` | Johnson's lemma |
| SP-109 | Relabeling: a random permutation of `Int` vertices (MG) maps distances to distances and witnesses to rotations of the permuted witness (after re-rotation) | — |

### K. Stress (no recursion, no quadratic paths)

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-115 | **10⁶-vertex path** (CSR), unit weights, in a `Task` | Dijkstra, Bellman–Ford and unweighted from 0: `distance(to: 999 999) == 999 999`; `path(to: 999 999).count == 1 000 000` (path reconstruction is iterative); Bellman–Ford finishes in one pass per vertex, well under a second | — |
| SP-116 | 1000 × 1000 grid, both directions, unit weights | distance of (r, c) from (0, 0) is r + c; A* with Manhattan to (999, 999) → 1998, path with 1999 vertices | — |
| SP-117 | **Long negative cycle** | 0→1→…→99 999 weight 1, 99 999→0 weight −100 000 → witness `[0, 1, …, 99 999]` (100 000 vertices, total −1) | — |
| SP-118 | **Lasso**: 0→1→…→n−1 weight 1, n−1 → n/2 weight −n, n = 10⁵ | witness `[50 000, …, 99 999]` (50 000 vertices); `findNegativeCycle(from: 0)` finds it although 0 is not on it | — |
| SP-119 | Negative path | 0→1→…→99 999 weight −1 → `distance(to: k) == -k`, a tree (no cycle) | — |
| SP-120 | Wide graphs | out-star 0→i (10⁵ leaves, weights i) → leaf i at i; complete digraph on 1000 vertices (999 000 edges), random weights → equals Bellman–Ford | — |
| SP-121 | Real-world fixtures | `gap4`, `graph500Scale8`, `ligraRMat` with weights `1 + (u · 31 + v) % 17` → Dijkstra = Bellman–Ford = test-local Floyd–Warshall on all three, on AL, AM, CSR | `GF:Tests/GrafluentTestSupport/RealWorldFixtures.swift` |

### L. Preconditions, value semantics, dispatch

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-125 | Preconditions trap (exit tests) | source not a vertex (Dijkstra, Bellman–Ford, A*, unweighted, `findNegativeCycle`); target not a vertex; an empty source sequence; `tree.distance(to:)` / `parent(of:)` / `path(to:)` of a non-vertex; `distance(toIndex: n)` | nx-Tw:263-269, 457-470, 477-482 |
| SP-126 | **Value semantics** | `var g = AdjacencyList(XG)`; `let t = g.dijkstraShortestPaths(from: "s") { … }`; then `g.insert(edge: s→v)` → `t.distance(to: "v") == 9`; a new computation gives the new value | — |
| SP-127 | `Sendable` | `ShortestPathTree<CompressedSparseRow, Int>` crosses into a `Task` (compile-time) | — |
| SP-128 | Existentials need a `some` wrapper | `func run(_ g: some DirectedGraph<Int>) -> Int? { g.dijkstraShortestPaths(from: 0) { _ in 1 }.distance(to: 3) }` called with each representation as `any DirectedGraph<Int>` → 3 on SP-03 | Connectivity CN-139 |
| SP-129 | **No per-vertex hashing on an indexed `AdjacencyList`** | SP-04 in `AdjacencyList<HashCountingVertex>` with weights in an array by position (or a closure that does not hash): `dijkstraShortestPaths`, `bellmanFordShortestPaths`, `shortestPaths` → at most a handful of hash calls (the source lookup), not one per settled vertex | Connectivity CN-136; `GF:Tests/TraversalTests/SearchPropertyTests.swift:329-340` |
| SP-130 | Weights are read only for examined edges | a closure that counts calls on SP-21's early exit → fewer calls than `edgeCount` | — |

### N. Path enumeration, bidirectional Dijkstra, all pairs

Values from `cases_paths.py` (NetworkX `shortest_simple_paths`, `all_shortest_paths`,
`bidirectional_dijkstra`, `johnson`, `floyd_warshall`, each re-checked by brute force over
`all_simple_paths` where it applies), kept in `cases_paths.out`. Paths of equal length come in an
unspecified order, so ties are compared as sets.

| ID | Asserts | Graph → expected | Source |
|---|---|---|---|
| SP-160 | `shortestSimplePaths`, undirected | cycle C₇, 0 → 3 → `[0,1,2,3]` (3), `[0,6,5,4,3]` (4), weighted and unweighted; arcs oriented | nx `shortest_simple_paths` docstring |
| SP-161 | Yen's example | C→D 3, C→E 2, D→F 4, E→D 1, E→F 2, E→G 3, F→G 2, F→H 1, G→H 2; C → H → lengths `[5, 7, 8, 8, 8, 11, 11]`, the three 8s as a set; `prefix(3)` → `[5, 7, 8]`; AL, reference multigraph, stable graph with a hole | Yen 1971; Wikipedia "Yen's algorithm" |
| SP-162 | XG s → v | the six simple paths in order, lengths `[9, 10, 11, 13, 17, 20]`; the first through edges `[1, 5, 2]` | nx-Tw XG |
| SP-163 | 3 × 3 grid, unweighted | undirected: 6 of length 4, 4 of 6, 2 of 8; directed right/down: the 6 monotone paths, at 8 with weight 2 | (ref) brute force |
| SP-164 | Trivial and empty | s = t → the trivial path alone, at 0; unreachable → empty; a self-loop is on no simple path; one vertex | — |
| SP-165 | Parallel edges | 0⇉1 (3, 1), 1→2 (1), 0→2 (5) → edge sequences `[b,c]` (2), `[a,c]` (4), `[d]` (5); unweighted `[1, 2, 2]`; undirected parallel pair | — |
| SP-166 | Laziness | a 60-rung ladder (2⁵⁹ paths): `prefix(5)` at 59; `weight` called once per edge when the sequence is made, never while listing; a new iterator starts over | — |
| SP-167 | Preconditions | a negative weight anywhere traps when the sequence is made; a target that is not a vertex | — |
| SP-168 | Property, directed | ≤ 12 edges on 5 vertices, weights 0…4, loops and parallel edges: the same edge sequences as brute force, each once, lengths nondecreasing, weighted and unweighted | (ref) brute force |
| SP-169 | Property, undirected | ≤ 9 edges on 5 vertices: as SP-168 by edge position | (ref) brute force |
| SP-170 | `allShortestPaths`, undirected | 0-1-2-3 and 0-10-20-3 → both, distance 3 (6 at weight 2); reversed from 3 | nx `test_all_shortest_paths` |
| SP-171 | 3 × 3 grid | the 6 monotone paths, each once, arcs oriented; directed: 6, none back | (ref) |
| SP-172 | Yen's example | weighted: `[C,E,F,H]` alone at 5; unweighted: 3 paths at 3; AL, reference multigraph, stable graph with a hole | (ref) |
| SP-173 | Trivial and empty | s = t → `[s]`; unreachable → empty, `distance == nil`; a zero-weight self-loop is on no path; a new iterator starts over | — |
| SP-174 | Zero weights | 0→1, 0→2 (1), 1⇄2 (0), 1→3, 2→3 (1) → `[0,1,3]`, `[0,2,3]`, `[0,1,2,3]`, `[0,2,1,3]`; an edge into the target from its own distance; a zero-weight cycle through the source | — |
| SP-175 | Parallel edges | equal copies give distinct paths, a heavier copy none; unweighted all four | — |
| SP-176 | Preconditions | a negative examined weight; a target that is not a vertex | — |
| SP-177 | Property | ≤ 12 edges on 5 vertices, weights 0…3: the shortest simple paths of brute force, each once, weighted and unweighted, directed and undirected | (ref) brute force |
| SP-178 | `bidirectionalDijkstraShortestPath` | XG s → v → 9 `[s,x,u,v]`; v → s → 8 `[v,y,s]`; AL, reference multigraph, stable graph with a hole, pseudograph | nx `bidirectional_dijkstra` |
| SP-179 | Yen's example, C₇ | C → H → 5 `[C,E,F,H]`, H → C → nil; C₇ 0 → 4 → 3 `[0,6,5,4]`, arcs oriented | nx |
| SP-180 | Edge cases | s = t → `[s]` at 0; unreachable; a zero-weight loop; the lighter of parallel edges; a zero-weight edge | — |
| SP-181 | Preconditions | a negative examined weight; a target that is not a vertex | — |
| SP-182 | Property | ≤ 24 edges on 8 vertices, weights 0…5: Dijkstra's distance, a valid path that weighs it; directed (reference multigraph, pseudograph) and undirected | (ref) Dijkstra |
| SP-183 | `johnsonShortestPaths` | CLRS figure 25.6 → rows `[0,1,-3,2,-4]`, `[3,0,-4,1,-1]`, `[7,4,0,5,3]`, `[2,-1,-5,0,-2]`, `[8,5,1,6,0]`; every path valid and of that weight; 1 → 3 is `[1,5,4,3]`; AL, reference multigraph, stable graph with a hole | CLRS §25.3; nx `johnson` |
| SP-184 | Unreachable pairs | NetworkX's test_johnson: from 0 `[0,-5,-1,0]`, from 1 `[nil,0,4,5]`, from 3 only itself | nx `test_johnson` |
| SP-185 | `allPairsDijkstraShortestPaths` | XG → rows `[0,8,5,9,7]`, `[9,0,2,1,2]`, `[9,3,0,4,2]`, `[8,16,13,0,1]`, `[7,15,12,6,0]`, the same by Johnson | nx `all_pairs_dijkstra` |
| SP-186 | Negative cycles | 0→1→2→0 at −1 → Johnson nil, `findNegativeCycle` `[0,1,2]`; a negative loop → nil; a zero-weight cycle → distances | — |
| SP-187 | Undirected | both equal Floyd–Warshall; a negative edge → Johnson nil | — |
| SP-188 | Edge cases | empty graph; one vertex with a loop; parallel edges (the lighter is the path), a loop | — |
| SP-189 | Checked lookups | `distance(checkedFrom:to:)`, `path(checkedFrom:to:)`, `hasPath(checkedFrom:to:)` throw `VertexNotFound`; nil keeps its meaning | — |
| SP-190 | Preconditions | a negative weight in all-pairs Dijkstra; a lookup of a non-vertex | — |
| SP-191 | Property | ≤ 20 edges on 6 vertices, weights −2…6, loops and parallel edges: Johnson equals Floyd–Warshall and is nil exactly when it is; all-pairs Dijkstra on |w| equals it on two representations | (ref) Floyd–Warshall |

---

## Benchmarks (not tests)

| ID | Measures |
|---|---|
| SP-B01 | `dijkstraShortestPaths` on CSR (`Int` and `Double` weights, closure over an array) vs a hand-written CSR loop with the same `IndexedPriorityQueue`: G(10⁵, 10⁶), the 1000 × 1000 grid, `graph500Scale8`, the 10⁶ path |
| SP-B02 | The same on `AdjacencyList<Int>` and `AdjacencyList<String>`, with weights by `[Edges.Index: W]`, by `[DirectedEdge: W]`, and by array |
| SP-B03 | Undirected: `UndirectedAdjacencyList` through `directedView` vs the native `Graph` overload vs a symmetric CSR |
| SP-B04 | Cost of the negative check, of the parent-edge array, and of `cutoff: nil` vs a cutoff branch |
| SP-B05 | Single-target early exit vs the full tree on random targets; A* (Manhattan) vs Dijkstra on 1000 × 1000 grids with 0%, 20% and 40% blocked cells: time and expanded vertices (counted by a heuristic closure) |
| SP-B06 | Bellman–Ford (active rounds) vs classical full-edge rounds vs a queue (SPFA) on random graphs with negative edges, on the 10⁶ path in reverse order, and on the lasso |
| SP-B07 | Interleaved `(target, weight)` rows vs separate arrays, hand-written, on G(10⁶, 10⁷) |
| SP-B08 | `shortestSimplePaths(...).prefix(k)` on a grid; `allShortestPaths` on a grid; `bidirectionalDijkstraShortestPath` vs `dijkstraShortestPath` on random s–t pairs; `johnsonShortestPaths` and `allPairsDijkstraShortestPaths` vs `floydWarshallShortestPaths` on a sparse graph |
