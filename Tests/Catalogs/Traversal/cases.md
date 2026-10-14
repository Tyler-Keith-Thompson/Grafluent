# Traversal: case catalog

Cases for the `Traversal` module: breadth-first and depth-first search as lazy event sequences,
reachability, bidirectional and iterative-deepening search, topological ordering, cycle finding,
and searches over successor closures. Case IDs `TR-nn` are stable, so test names can refer to them.

## Sources

The Source column cites the test suites and code that cases were taken from (shallow clones, not kept in the repository):

| Library | Commit | Licence | What was used |
|---|---|---|---|
| NetworkX | `6da4704` | BSD-3-Clause | `algorithms/traversal/{depth_first_search,breadth_first_search,edgedfs}.py` and their tests, `dag.py` and `tests/test_dag.py`, `shortest_paths/unweighted.py` and its tests, `chordal.py`, `cycles.py` (`find_cycle`) |
| petgraph | `a4d94bd` | MIT OR Apache-2.0 | `src/visit/{dfsvisit,traversal}.rs`, `src/algo/mod.rs` (`toposort`, `is_cyclic_directed`, `Cycle`), `tests/graph.rs`, `tests/quickcheck.rs` |
| Boost.Graph | `1ee1a99` | BSL-1.0 | `depth_first_search.hpp`, `breadth_first_search.hpp`, `topological_sort.hpp`, `test/dfs.cpp`, `test/bfs.cpp` |
| JGraphT | `63976aa` | EPL-2.0 OR LGPL-2.1+ | `traverse/*Iterator.java`, `event/TraversalListener.java`, and the `traverse` tests |
| LEMON | `31d79d6` | Boost-style | `lemon/dfs.h`, `lemon/bfs.h`, `test/dfs_test.cc` |
| igraph | `912f99d` | GPL-2.0+ (**behavior reference only; no code copied**) | `include/igraph_visitor.h`, `tests/unit/topological_sorting.{c,out}`, `bfs_simple.{c,out}` |
| pathfinding (Rust) | `cd4600b` (cloned for this catalog) | MIT OR Apache-2.0 | `src/directed/{bfs,dfs,iddfs,topological_sort}.rs`, `tests/{dfs-reach,topological_sort,test_bfs_multiple_starts}.rs` |

Path prefixes in the Source column, relative to the root of those clones:

| Prefix | Expands to |
|---|---|
| `nx-dfs:` / `nx-bfs:` | `networkx/networkx/algorithms/traversal/depth_first_search.py` / `breadth_first_search.py` |
| `nx-Tdfs:` / `nx-Tbfs:` | `.../traversal/tests/test_dfs.py` / `test_bfs.py` |
| `nx-dag:` / `nx-Tdag:` | `networkx/networkx/algorithms/dag.py` / `algorithms/tests/test_dag.py` |
| `nx-uw:` / `nx-Tuw:` | `.../shortest_paths/unweighted.py` / `shortest_paths/tests/test_unweighted.py` |
| `pg-dv:` / `pg-tr:` / `pg-algo:` | `petgraph/crates/petgraph/src/visit/dfsvisit.rs` / `visit/traversal.rs` / `algo/mod.rs` |
| `pg-T:` / `pg-Q:` | `petgraph/crates/petgraph/tests/graph.rs` / `tests/quickcheck.rs` |
| `bgl-dfs:` / `bgl-bfs:` / `bgl-topo:` | `graph/include/boost/graph/depth_first_search.hpp` / `breadth_first_search.hpp` / `topological_sort.hpp` |
| `bgl-Tdfs:` / `bgl-Tbfs:` | `graph/test/dfs.cpp` / `graph/test/bfs.cpp` |
| `jgt:` / `jgt-T:` | `jgrapht/jgrapht-core/src/main/java/org/jgrapht/traverse/` / `src/test/java/org/jgrapht/traverse/` |
| `lemon-dfs:` / `lemon-bfs:` / `lemon-T:` | `lemon/lemon/dfs.h` / `lemon/lemon/bfs.h` / `lemon/test/dfs_test.cc` |
| `ig-V:` / `ig-T:` | `igraph/include/igraph_visitor.h` / `igraph/tests/unit/` |
| `pf:` / `pf-T:` | `pathfinding/src/directed/` / `pathfinding/tests/` |
| `GF:` | the Grafluent repository |

## How the expectations were computed

Every expected value marked **(nx)** was computed by the NetworkX checkout above (NetworkX 3.7; the scripts here run it through `uv`). Values marked **(ref)** come from a 120-line Python reference written for this catalog (`ref.py`, next to this file). It implements iterative CLRS DFS with full event transcripts, Boost-order BFS events, Kahn's algorithm (FIFO, min-heap, and generations), and a DFS cycle witness. `check.py` cross-checks the reference against NetworkX on all 36 Grafluent fixtures (the 33 in `DirectedFixtures.swift` plus the 3 real-world ones). On each fixture, from five sources and over the whole graph, it compares tree edges against `nx.dfs_edges`/`nx.bfs_edges`, preorder and postorder against `nx.dfs_{pre,post}order_nodes`, non-tree edges against `nx.dfs_labeled_edges`, distances against `nx.single_source_shortest_path_length`, layers against `nx.bfs_layers`, reachability against `nx.descendants`, "has a back edge" against `nx.is_directed_acyclic_graph`, and the topological orders against `lexicographical_topological_sort` and `topological_generations`. Every check passes. Successors are visited in **ascending order** and whole-graph roots in ascending vertex order. That is exactly what `AdjacencyMatrix` and `CompressedSparseRow` do (`GF:Tests/AdjacencyMatrixTests/README.md:73`, `GF:Tests/CompressedSparseRowTests/README.md:56`), so the (ref) values hold verbatim on those two. `{dump,ports*,compact}.py` print every value used below.

## Transcript notation

`D v` = `.discover(v)`, `X v` = `.finish(v)`, `T u→v` = `.treeEdge(DirectedEdge(from: u, to: v))`, and likewise `B` back, `F` forward, `C` cross, and `N` the BFS `.nonTreeEdge`. A test writes the transcript out as the array literal of events.

---

## How tests pin traversal orders

The protocol fixes successor order only per representation. Tests therefore come in three kinds:

1. **Exact transcripts** on `AdjacencyMatrix` and `CompressedSparseRow`, where successors are ascending and `vertices` is `0..<n`. Every (ref) transcript below applies verbatim to both. A test builds both from the same fixture and expects the same literal.
2. **Exact transcripts in written order** on the `ReferenceDirectedMultigraph` test conformer in `GrafluentTestSupport`, called the Multigraph below. Its successors follow the edges as written, and its `vertices` are the listed vertices followed by endpoints in order of first appearance. It is the only multigraph and the only exact-order host for `String` fixtures. Where written order differs from ascending order, the catalog gives the Multigraph transcript separately (TR-46, TR-47, §E).
3. **Order-independent assertions** on `AdjacencyList`, whose order is unspecified. These cover reachable sets, distances, layers as sets, tree-edge count = reached − 1, "has a back edge", the lexicographical topological order and generations (both order-independent by definition), every property in §L, and equality with the matrix's order-independent results. Back, forward and cross counts are **not** order-independent in general. They are only on fixtures where every cycle is a self-loop (TR-157) or the graph is a DAG (back count 0).

Undirected test graphs are written inline as symmetric edge lists (both directions). On a symmetric digraph, the preorder and postorder equal the undirected search's. Its non-tree edges split into back edges (including the edge back to the parent) and forward edges.

---

## Cases

### A. Breadth-first search events and order

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-01 | A single vertex: discovered and finished, nothing else | `trivial` from 0 → `D0 X0` | definition; nx-Tbfs:52-58 (`bfs_tree` of an isolate) |
| TR-02 | Path: `finish(u)` comes after u's last out-edge and before the next vertex's edges | `directedPath3` from 0 → `D0 T0→1 D1 X0 T1→2 D2 X1 X2` (ref) | Boost event order (bgl-bfs:75-102) |
| TR-03 | Complete digraph: every edge out of a reached vertex is reported once | `completeDirected3` from 0 → `D0 T0→1 D1 T0→2 D2 X0 N1→0 N1→2 X1 N2→0 N2→1 X2` (ref) | bgl-Tbfs:80-101 (every edge is tree or non-tree) |
| TR-04 | A self-loop is a non-tree edge | `singleSelfLoop` from 0 → `D0 N0→0 X0` (ref). NetworkX labels it `"level"` (nx-Tbfs:96-99) | nx-Tbfs:84-146 |
| TR-05 | A self-loop among other out-edges | `networkXFunctionGraph` from 0 → `D0 T0→1 D1 T0→2 D2 T0→3 D3 X0 N1→0 N1→1 N1→2 X1 X2 X3` (ref) | NetworkX `test_function.py` graph |
| TR-06 | DAG from its source | `house` from 5 → `D5 T5→3 D3 X5 T3→2 D2 T3→4 D4 X3 T2→1 D1 X2 T4→0 D0 N4→1 X4 N1→0 X1 X0` (ref) | Boost test graph |
| TR-07 | Cyclic graph | `scc9` from 1 → `D1 T1→7 D7 X1 T7→4 D4 T7→5 D5 X7 N4→1 X4 T5→8 D8 X5 T8→2 D2 T8→6 D6 X8 N2→5 X2 T6→0 D0 X6 T0→3 D3 X0 N3→6 X3` (ref) | petgraph SCC fixture |
| TR-08 | Unreached vertices produce no events (vertex 6 and its loop) | `petgraphEdgesDirected` from 0 → `D0 T0→1 D1 T0→2 D2 T0→3 D3 T0→5 D5 X0 N1→3 X1 N2→3 T2→4 D4 X2 X3 X5 N4→0 X4` (ref) | petgraph matrix_graph fixture |
| TR-09 | NetworkX `TestBFS` graph, symmetric 0–1, 1–2, 1–3, 2–4, 3–4, from 0 | `D0 T0→1 D1 X0 N1→0 T1→2 D2 T1→3 D3 X1 N2→1 T2→4 D4 X2 N3→1 N3→4 X3 N4→2 N4→3 X4`. Tree edges `[(0,1), (1,2), (1,3), (2,4)]` (nx) | nx-Tbfs:33-35 |
| TR-10 | Directed 5-cycle plus a loop at 4 | edges i→(i+1)%5 and 4→4, from 0 → `D0 T0→1 D1 X0 T1→2 D2 X1 T2→3 D3 X2 T3→4 D4 X3 N4→0 N4→4 X4` (ref). NetworkX labels: tree ×4, `(4,0,"reverse")`, `(4,4,"level")` | nx-Tbfs:84-99 |
| TR-11 | Same cycle with 0→2, 1→5, 2→5 and no loop | `D0 T0→1 D1 T0→2 D2 X0 N1→2 T1→5 D5 X1 T2→3 D3 N2→5 X2 X5 T3→4 D4 X3 N4→0 X4` (ref). NetworkX labels: 1→2 `level`, 2→5 `forward`, 4→0 `reverse` (nx) | nx-Tbfs:101-118 |
| TR-12 | Multi-source: every source is discovered before any edge | symmetric K₃ from [0, 1] → `D0 D1 N0→1 T0→2 D2 X0 N1→0 N1→2 X1 N2→0 N2→1 X2`. NetworkX: `[(0,1,"level"), (0,2,"tree"), (1,2,"forward")]` | nx-bfs:526-530 (doctest); bgl-bfs:68-73 |
| TR-13 | Multi-source on a DAG | `house` from [3, 4] → `D3 D4 T3→2 D2 N3→4 X3 T4→0 D0 T4→1 D1 X4 N2→1 X2 X0 N1→0 X1` (ref) | — |
| TR-14 | Repeated sources are ignored | `breadthFirstSearch(from: [0, 0])` == `breadthFirstSearch(from: 0)` on TR-09's graph | nx-Tbfs:60-68 (`[0, 0]`) |
| TR-15 | Empty sources: an empty sequence | `breadthFirstSearch(from: [Int]())` on `house` → `[]` | — |
| TR-16 | Discovery order, ascending successors | NetworkX `bfs_edges` sorted DiGraph 0→1, 0→2, 1→4, 1→3, 2→5 → tree edges `[(0,1), (0,2), (1,3), (1,4), (2,5)]`. With successors in descending order (a Multigraph whose edges are written descending) → `[(0,2), (0,1), (2,5), (1,4), (1,3)]` | nx-Tbfs:43-50 |
| TR-17 | BFS over predecessors equals NetworkX `reverse=True` | DiGraph 0→1, 1→2, 1→3, 2→4, 3→4. BFS from 4 on the reversed edge list → tree edges `[(4,2), (4,3), (2,1), (1,0)]` (nx) | nx-Tbfs:37-41 |
| TR-18 | String vertices on the Multigraph (written order is ascending here) | `petgraphDAG` from "a" → `Da Ta→b Db Ta→d Dd Xa Tb→c Dc Tb→e De Xb Nd→b Nd→e Td→f Df Xd Nc→e Xc Te→g Dg Xe Nf→e Nf→g Xf Xg` (ref) | petgraph tests/graph.rs DAG |

### B. Distances, layers, and the BFS tree

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-19 | Layers on a tree | NetworkX path 0…6 plus 2–7–8–9–10 (symmetric), from 0 → `[[0], [1], [2], [3, 7], [4, 8], [5, 9], [6, 10]]` (nx) | nx-Tbfs:187-196 |
| TR-20 | Layers, NetworkX `TestBFS` graph | from 0 → `[[0], [1], [2, 3], [4]]`; the same from `[0]` and `[0, 0]` (nx) | nx-Tbfs:60-68 |
| TR-21 | Layers, disconnected | NetworkX D = 0–1, 2–3, 2–7–8–9–10 (symmetric), from 2 → `[[2], [3, 7], [8], [9], [10]]` (nx) | nx-Tbfs:197-203 |
| TR-22 | `descendants_at_distance` is a layer | path 0…4 (symmetric) from 2, distance 2 → `{0, 4}`. Binary out-tree 0→1, 0→2, 1→3, 1→4, 2→5, 2→6: layer 2 = `{3, 4, 5, 6}` (nx) | nx-bfs:564-590 (doctests) |
| TR-23 | Distances on the existing fixtures (every representation, order-independent) | `house` from 5 → `[5:0, 3:1, 2:2, 4:2, 0:3, 1:3]`; `scc9` from 1 → `[1:0, 7:1, 4:2, 5:2, 8:3, 2:4, 6:4, 0:5, 3:6]` (nx) | GF DG-A01 – A03 (`DirectedGraphAlgorithmTests.swift:14-46`) |
| TR-24 | Distances on `boost24` from 7 | layers `[[7], [11, 17], [4, 15, 19, 20], [0, 5, 6, 22, 18, 23, 13], [14, 3, 21, 9, 16, 8], [12, 10, 1], [2]]` (ascending order, ref) | Boost adjacency_matrix_test graph |
| TR-25 | BFS parent map, ascending order (AM, CSR) | `house` from 5 → parents `[3:5, 2:3, 4:3, 1:2, 0:4]`; `petgraphEdgesDirected` from 0 → `[1:0, 2:0, 3:0, 5:0, 4:2]` (ref) | JGraphT `getParent` (jgt-T:BreadthFirstIteratorTest.java:90-130) |
| TR-26 | JGraphT search tree, undirected a–b, b–c, b–z, b–d, d–e (symmetric) | depths `a:0, b:1, c:2, d:2, z:2, e:3`; parents `b:a, c:b, d:b, z:b, e:d` (unique, so on every representation) | jgt-T:BreadthFirstIteratorTest.java:90-130 |
| TR-27 | Directed 4-cycle tree | 0→1→2→3→0 from 0 → depths 0, 1, 2, 3; parents `1:0, 2:1, 3:2` | jgt-T:BreadthFirstIteratorTest.java:134-160 |
| TR-28 | Binary out-tree (igraph `kary_tree(20, 2, OUT)`) | edges i→2i+1, i→2i+2 (< 20). From 0: order `0…19`, layer sizes `[1, 2, 4, 8, 5]`. From 7: order `[7, 15, 16]`, layers `[[7], [15, 16]]` | ig-T:bfs_simple.c:61-62 and `.out` |
| TR-29 | `breadthFirstLayers` equals the `discover` events grouped by depth | for every fixture in `DirectedFixture.all` and every source (property) | definition |
| TR-30 | Unreachable target: not in any layer, and `hasPath` is false | `house` 0 → 5: `hasPath == false`; `scipyConstructor2` 0 → 4: false; 3 → 4: true | nx `has_path` |

### C. Depth-first search transcripts (CLRS classification)

All on `AdjacencyMatrix` and `CompressedSparseRow` unless stated.

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-31 | Single vertex | `trivial` from 0 → `D0 X0` | definition |
| TR-32 | **A self-loop is a back edge** | `singleSelfLoop` from 0 → `D0 B0→0 X0` (ref) | CLRS 22.3; petgraph treats a self-loop as a cycle (pg-algo:201, 229-232) |
| TR-33 | Path: tree edges only; finishes in reverse | `directedPath3` from 0 → `D0 T0→1 D1 T1→2 D2 X2 X1 X0` | — |
| TR-34 | Complete digraph: back and forward edges | `completeDirected3` from 0 → `D0 T0→1 D1 B1→0 T1→2 D2 B2→0 B2→1 X2 X1 F0→2 X0` (ref) | — |
| TR-35 | Back edges to the parent and to self | `networkXFunctionGraph` from 0 → `D0 T0→1 D1 B1→0 B1→1 T1→2 D2 X2 X1 F0→2 T0→3 D3 X3 X0` (ref) | — |
| TR-36 | DAG: cross edges, no back edges | `house` from 5 → `D5 T5→3 D3 T3→2 D2 T2→1 D1 T1→0 D0 X0 X1 X2 T3→4 D4 C4→0 C4→1 X4 X3 X5` (ref) | — |
| TR-37 | Three SCCs | `scc9` from 1 → `D1 T1→7 D7 T7→4 D4 B4→1 X4 T7→5 D5 T5→8 D8 T8→2 D2 B2→5 X2 T8→6 D6 T6→0 D0 T0→3 D3 B3→6 X3 X0 X6 X8 X5 X7 X1` (ref) | petgraph SCC fixture |
| TR-38 | All four classes in one search | `petgraphEdgesDirected` from 0 → `D0 T0→1 D1 T1→3 D3 X3 X1 T0→2 D2 C2→3 T2→4 D4 B4→0 X4 X2 F0→3 T0→5 D5 X5 X0` (ref) | petgraph fixture |
| TR-39 | petgraph `dfs_visit` graph (0→5, 0→2, 0→3, 0→1, 1→3, 2→3, 2→4, 4→0, 4→5) | from 0 → `D0 T0→1 D1 T1→3 D3 X3 X1 T0→2 D2 C2→3 T2→4 D4 B4→0 T4→5 D5 X5 X4 X2 F0→3 F0→5 X0`. CLRS times (1-based): d = `0:1, 1:2, 3:3, 2:6, 4:7, 5:8`; f = `3:4, 1:5, 5:9, 4:10, 2:11, 0:12` (ref) | pg-T:2200-2297 |
| TR-40 | NetworkX `TestDFS` graph, symmetric 0–1, 1–2, 1–3, 2–4, 3–0, 0–4, from 0 | `D0 T0→1 D1 B1→0 T1→2 D2 B2→1 T2→4 D4 B4→0 B4→2 X4 X2 T1→3 D3 B3→0 B3→1 X3 X1 F0→3 F0→4 X0`. Back and forward edges are exactly NetworkX's `nontree` labels in the same positions (nx-Tdfs:67-90) | nx-Tdfs:67-90 |
| TR-41 | Disconnected, whole graph | NetworkX D = 0–1, 2–3 (symmetric), `depthFirstSearch()` → `D0 T0→1 D1 B1→0 X1 X0 D2 T2→3 D3 B3→2 X3 X2` (cf. nx-Tdfs:139-154) | nx-Tdfs:139-154 |
| TR-42 | Reciprocal edge and triangle | `triangleWithReciprocalEdge` from 1 → `D1 T1→2 D2 B2→1 T2→3 D3 B3→1 X3 X2 X1` (ref) | JGraphT fixture |
| TR-43 | Directed cycle: exactly one back edge, closing the cycle | `directedCycle4` from 1 → `D1 T1→2 D2 T2→3 D3 T3→4 D4 B4→1 X4 X3 X2 X1` | JGraphT fixture |
| TR-44 | DAG with forward and cross edges | `neo4jDirected` from 0 → `D0 T0→1 D1 T1→2 D2 T2→4 D4 X4 X2 T1→3 D3 C3→4 X3 X1 F0→2 X0` (ref) | neo4j fixture |
| TR-45 | Self-loops at a root and at a leaf | `petgraphCsr1` from 0 → `D0 B0→0 T0→2 D2 B2→2 X2 X0` (ref) | petgraph csr1 |
| TR-46 | String vertices, Multigraph (written order is ascending for `petgraphDAG`) | from "a" → `Da Ta→b Db Tb→c Dc Tc→e De Te→g Dg Xg Xe Xc Fb→e Xb Ta→d Dd Cd→b Cd→e Td→f Df Cf→e Cf→g Xf Xd Xa` (ref) | petgraph DAG |
| TR-47 | **Neighbor order changes the transcript, not its validity** | `house` from 5 on the Multigraph (written order 3:[4, 2], 4:[0, 1]) → `D5 T5→3 D3 T3→4 D4 T4→0 D0 X0 T4→1 D1 C1→0 X1 X4 T3→2 D2 C2→1 X2 X3 X5`; compare TR-36 on AM/CSR | — |
| TR-48 | `networkXABCD` on the Multigraph (B's successors written D, C) | from "A" → `DA TA→B DB TB→D DD XD TB→C DC CC→D XC XB FA→C XA` (ref) | NetworkX fixture |
| TR-49 | Cube: symmetric, so no cross edges | `cube` from 0 → `D0 T0→1 D1 B1→0 T1→3 D3 B3→1 T3→2 D2 B2→0 B2→3 T2→6 D6 B6→2 T6→4 D4 B4→0 T4→5 D5 B5→1 B5→4 T5→7 D7 B7→3 B7→5 B7→6 X7 X5 B4→6 X4 F6→7 X6 X2 F3→7 X3 F1→5 X1 F0→2 F0→4 X0`; counts T 7, B 12, F 5, C 0 (ref) | — |
| TR-50 | Dense self-loop row | `jgraphtMatrixCSV` from 0 → `D0 T0→1 D1 X1 T0→2 D2 B2→0 T2→3 D3 T3→4 D4 B4→0 C4→1 B4→2 B4→3 B4→4 X4 X3 X2 X0` (ref) | JGraphT CSV fixture |
| TR-51 | LEMON's test digraph (0→1, 1→2, 2→3, 1→4, 4→2, 4→5, 5→0, 6→3) | from 0 → `D0 T0→1 D1 T1→2 D2 T2→3 D3 X3 X2 T1→4 D4 C4→2 T4→5 D5 B5→0 X5 X4 X1 X0`; DFS-tree path 0 → 5 = `[0, 1, 4, 5]`; tree depths `0:0, 1:1, 2:2, 3:3, 4:2, 5:3`; from 6 reaches `[6, 3]` | lemon-T:30-56, 200-224 |

### D. Preorder, postorder and whole-graph DFS

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-52 | Preorder and postorder, NetworkX `TestDFS` G (symmetric) | from 0: preorder `[0, 1, 2, 4, 3]`, postorder `[4, 2, 3, 1, 0]`; from 1: preorder `[1, 0, 3, 4, 2]` (nx) | nx-Tdfs:16-24 |
| TR-53 | Disconnected D, whole graph | preorder `[0, 1, 2, 3]`, postorder `[1, 0, 3, 2]`; from 2 → preorder `[2, 3]`; from 0 → postorder `[1, 0]` (nx) | nx-Tdfs:16-24 |
| TR-54 | DFS tree edges match NetworkX `dfs_edges` | G from 0 → `[(0,1), (1,2), (2,4), (1,3)]`; descending successors → `[(0,4), (4,2), (2,1), (1,3)]`; D whole → `[(0,1), (2,3)]` (nx) | nx-Tdfs:52-65 |
| TR-55 | DFS predecessors and successors (derived from tree edges) | G from 0: predecessors `{1:0, 2:1, 3:1, 4:2}`, successors `{0:[1], 1:[2, 3], 2:[4]}`; from 1: successors `{1:[0], 0:[3, 4], 4:[2]}` (nx) | nx-Tdfs:26-34 |
| TR-56 | Whole graph, roots in `vertices` order (AM, CSR) | `house` → `D0 X0 D1 C1→0 X1 D2 C2→1 X2 D3 C3→2 T3→4 D4 C4→0 C4→1 X4 X3 D5 C5→3 X5` (ref) | Boost `depth_first_search` |
| TR-57 | Whole graph with an isolated vertex and a 2-cycle | `boostExample` → `D0 X0 D1 T1→2 D2 C2→0 B2→2 X2 T1→5 D5 C5→0 X5 X1 D3 T3→4 D4 B4→3 X4 X3` (ref) | Boost example |
| TR-58 | Whole graph: second tree has only cross edges into the first | `scc9` → `D0 T0→3 D3 T3→6 D6 B6→0 X6 X3 X0 D1 T1→7 D7 T7→4 D4 B4→1 X4 T7→5 D5 T5→8 D8 T8→2 D2 B2→5 X2 C8→6 X8 X5 X7 X1` (ref) | — |
| TR-59 | Whole graph with isolated vertices and string vertices (Multigraph: listed G, J, K come first) | `networkXABCD` → `DG XG DJ XJ DK XK DA TA→B DB TB→D DD XD TB→C DC CC→D XC XB FA→C XA` | — |
| TR-60 | JGraphT's iterator visits successors in **reverse** insertion order; with ascending successors the order differs | JGraphT graph (1→2, 1→3, 2→4, 3→5, 3→6, 5→6, 5→7, 6→1, 7→8, 7→9, 8→2, 9→4, isolated "orphan"), whole graph. JGraphT: preorder `1,3,6,5,7,9,4,8,2,orphan`, finish `6:4:9:2:8:7:5:3:1:orphan` (jgt-T:DepthFirstIteratorTest.java:43-57; reproduced by the reference with reversed successors). Grafluent, ascending (Multigraph with edges written ascending): `D1 T1→2 D2 T2→4 D4 X4 X2 T1→3 D3 T3→5 D5 T5→6 D6 B6→1 X6 T5→7 D7 T7→8 D8 C8→2 X8 T7→9 D9 C9→4 X9 X7 X5 F3→6 X3 X1 Dorphan Xorphan` | jgt-T:AbstractGraphIteratorTest.java:94-139 |
| TR-61 | JGraphT bug 1169182 graph (A→B, B→C, C→J, C→D, C→E, C→F, C→G, D→H, E→H, F→I, G→I, H→J, I→C, J→K, K→L) | JGraphT preorder `ABCGIFEHJKLD` (reverse order). Ascending: preorder `ABCDHJKLEFIG`, postorder `LKJHDEIFGCBA`, one back edge I→C; counts T 11, B 1, F 1, C 2 (ref) | jgt-T:DepthFirstIteratorTest.java:105-160 |
| TR-62 | Multi-root DFS: roots in the order given; an already-reached root is skipped | `house` from [3, 0, 5] → `D3 T3→2 D2 T2→1 D1 T1→0 D0 X0 X1 X2 T3→4 D4 C4→0 C4→1 X4 X3 D5 C5→3 X5` (ref) | petgraph `depth_first_search(g, starts, …)` |
| TR-63 | Isolated vertices only | `isolatedVertices` whole → `D0 X0 D1 X1 … D9 X9` (20 events) | — |
| TR-64 | `preorder` and `postorder` views equal the filtered events | for every fixture: `search.preorder` == the `discover` vertices; `search.postorder` == the `finish` vertices | definition |
| TR-65 | Whole-graph DFS of the petgraph Bellman–Ford graph | → `D0 T0→1 D1 B1→0 B1→1 T1→2 D2 T2→3 D3 X3 X2 F1→3 X1 F0→2 X0 D4 T4→5 D5 T5→7 D7 T7→8 D8 X8 X7 X5 X4 D6 C6→7 X6` (ref) | petgraph csr.rs fixture |

### E. Parallel edges and self-loops (Multigraph conformer)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-66 | The second copy of a tree edge is a forward edge | `Multigraph(edges: [0→1, 0→1])` whole → `D0 T0→1 D1 X1 F0→1 X0` | CLRS (v is finished, d[u] < d[v]) |
| TR-67 | Every copy of a self-loop is a back edge | `Multigraph(edges: [0→0, 0→0], vertices: [0, 1])` whole → `D0 B0→0 B0→0 X0 D1 X1`; BFS from 0 → `D0 N0→0 N0→0 X0` | — |
| TR-68 | Antiparallel plus parallel | edges `0→1, 0→1, 1→0` whole → `D0 T0→1 D1 B1→0 X1 F0→1 X0`; BFS → `D0 T0→1 D1 N0→1 X0 N1→0 X1` | — |
| TR-69 | Duplicated chord: two forward events (DFS), one tree and one non-tree event (BFS) | `pathWithChord` on the Multigraph: DFS whole → `D0 T0→1 D1 T1→2 D2 T2→3 D3 T3→4 D4 T4→5 D5 X5 X4 X3 X2 F1→3 F1→3 X1 X0`; BFS from 0 → `D0 T0→1 D1 X0 T1→2 D2 T1→3 D3 N1→3 X1 N2→3 X2 T3→4 D4 X3 T4→5 D5 X4 X5` | GF fixture |
| TR-70 | Parallel edges and self-loop pairs | `selfLoopsAndDuplicates` on the Multigraph: whole → `D1 T1→2 D2 T2→3 D3 X3 F2→3 T2→4 D4 B4→4 X4 X2 X1 D5 B5→5 C5→2 B5→5 X5` (T 3, B 3, F 1, C 1). On AM/CSR the duplicates collapse, but vertices 1…5 are not `0..<n`, so use `AdjacencyList` there and assert only order-independent facts: reachable from 1 = {1, 2, 3, 4}, cyclic | JGraphT fixture |
| TR-71 | A tripled cross edge is three cross events | `jgraphtSparseDirected` on the Multigraph: whole → `D0 T0→1 D1 B1→0 T1→4 D4 T4→5 D5 T5→6 D6 X6 X5 X4 F1→5 F1→6 X1 X0 D2 C2→4 C2→4 C2→4 X2 D3 C3→4 X3 D7 C7→6 B7→7 X7` | JGraphT fixture |
| TR-72 | Edge events out of each reached vertex = its out-degree, repeats included | for every Multigraph built from `DirectedFixture.all`: per vertex, (tree + back + forward + cross) events with that source == `outDegree(of:)` | Boost `finish_edge_calls == num_edges` (bgl-Tdfs:212) |

### F. Depth limit, pruning, early termination

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-73 | Depth limit 0: sources only | `house` from 5, `depthLimit: 0` → `D5 X5`; BFS likewise | NetworkX `depth_limit` |
| TR-74 | DFS depth limit 2 on NetworkX's tree (path 0…6 plus 2–7–8–9–10, symmetric) | from 0, limit 2 → preorder `[0, 1, 2]` (nx), **postorder `[2, 1, 0]`** (NetworkX gives `[1, 0]`, see D9) | nx-Tdfs:182-184 |
| TR-75 | Depth limit 3 from 3 | preorder `[3, 2, 1, 0, 7, 8, 4, 5, 6]` (nx); Grafluent postorder `[0, 1, 8, 7, 2, 6, 5, 4, 3]` (NetworkX `[1, 7, 2, 5, 4, 3]` omits 0, 8, 6) | nx-Tdfs:186-197 |
| TR-76 | Depth limit transcripts | from 5, limit 1 → `D5 T5→4 D4 X4 T5→6 D6 X6 X5`; from 6, limit 2 → `D6 T6→5 D5 T5→4 D4 X4 B5→6 X5 X6` (NetworkX: `(5,4,"reverse-depth_limit")`, `(5,6,"nontree")`) | nx-Tdfs:232-258 |
| TR-77 | **Every discovered vertex is finished**, with or without a limit | property over `DirectedFixture.all` × limits 0…3: `Set(preorder) == Set(postorder)` and the counts are equal | — |
| TR-78 | Depth-limited DFS edges and predecessors | from 9, limit 4 → tree edges `[(9,8), (8,7), (7,2), (2,1), (2,3), (9,10)]` (nx); from 0, limit 3 → predecessors `{1:0, 2:1, 3:2, 7:2}` (nx); from 3, limit 1 → tree `[(3,2), (3,4)]` (nx) | nx-Tdfs:210-230 |
| TR-79 | Depth limit, whole graph, disconnected D (0–1, 2–3, 2–7–8–9–10), limit 1 | → `D0 T0→1 D1 X1 X0 D2 T2→3 D3 X3 T2→7 D7 X7 X2 D8 C8→7 T8→9 D9 X9 X8 D10 C10→9 X10`. NetworkX's labels in the same order: 8→7 and 10→9 `nontree` (nx-Tdfs:260-280) | nx-Tdfs:260-280 |
| TR-80 | BFS depth limit | tree from 1, limit 3 → successors `{1:[0, 2], 2:[3, 7], 3:[4], 7:[8]}`; transcript `D1 T1→0 D0 T1→2 D2 X1 N0→1 X0 N2→1 T2→3 D3 T2→7 D7 X2 N3→2 T3→4 D4 X3 N7→2 T7→8 D8 X7 X4 X8`; from 9, limit 4 → tree `[(9,8), (9,10), (8,7), (7,2), (2,1), (2,3)]` (nx) | nx-Tbfs:149-185 |
| TR-81 | `prune()` after `discover(v)`: v's out-edges are skipped, `finish(v)` is still reported | petgraph graph (TR-39), prune at `discover(2)` → `D0 T0→1 D1 T1→3 D3 X3 X1 T0→2 D2 X2 F0→3 T0→5 D5 X5 X0`; 4 is never discovered | pg-T:2280-2297 ("if we prune 2, we never see 4") |
| TR-82 | Prune the root | same graph, prune at `discover(0)` → `D0 X0` | pg-dv:50-54 |
| TR-83 | BFS prune | same graph, BFS from 0, prune at `discover(2)` → `D0 T0→1 D1 T0→2 D2 T0→3 D3 T0→5 D5 X0 N1→3 X1 X2 X3 X5` (unpruned: `… X1 N2→3 T2→4 D4 X2 X3 X5 N4→0 N4→5 X4`) | — |
| TR-84 | Early exit: path to a goal from tree edges, stopping at the tree edge into the goal | petgraph graph, from 0, stop at `treeEdge(→4)`: the prefix consumed is `D0 T0→1 D1 T1→3 D3 X3 X1 T0→2 D2 C2→3 T2→4`; parent chain 4 → 2 → 0 gives `[0, 2, 4]`; 5 was never discovered | pg-T:2253-2279 |
| TR-85 | Early exit is lazy | on a 100 000-vertex path (CSR), `first { $0 == .discover(10) }` asks for `successors` at most 11 times (a test-local counting conformer wrapping CSR) | laziness (README) |

### G. Topological ordering

`topologicalOrdering()` is DFS reverse postorder with roots in `vertices` order (exact values for AM/CSR); `lexicographicalTopologicalOrdering()` and `topologicalGenerations()` are order-independent (generations compared as sets per generation, or sorted).

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-86 | Empty graph | `empty` → all three return empty; `topologicalGenerations() == []` | nx-Tdag:629-631; pf-T:topological_sort.rs:7-10 |
| TR-87 | No edges | `isolatedVertices`: DFS → `[9, 8, 7, 6, 5, 4, 3, 2, 1, 0]`; lexicographical → `0…9`; generations → `[[0…9]]` (ref; pathfinding `tsig_graph_with_no_edges` → `[[0, 1, 2]]`) | pf-T:topological_sort.rs:76-79 |
| TR-88 | DFS vs Kahn on `house` | DFS → `[5, 3, 4, 2, 1, 0]`; lexicographical → `[5, 3, 2, 4, 1, 0]`; generations → `[[5], [3], [2, 4], [1], [0]]` (nx) | Boost test graph |
| TR-89 | `neo4jDirected` | DFS → `[0, 1, 3, 2, 4]`; lexicographical → `[0, 1, 2, 3, 4]`; generations `[[0], [1], [2, 3], [4]]` | — |
| TR-90 | `boostCsrUnsorted` | DFS → `[5, 4, 3, 1, 0, 2]`; lexicographical → `[3, 4, 1, 5, 0, 2]`; generations `[[3, 4, 5], [0, 1], [2]]`; NetworkX `topological_sort` → `[3, 4, 5, 1, 0, 2]` | — |
| TR-91 | `scipyConstructor2` (isolated vertices around one edge) | DFS → `[5, 3, 4, 2, 1, 0]`; lexicographical → `[0, 1, 2, 3, 4, 5]`; generations `[[0, 1, 2, 3, 5], [4]]` | — |
| TR-92 | `petgraphDAG` (String) | lexicographical → `["a", "d", "b", "c", "f", "e", "g"]`; generations `[["a"], ["d"], ["b", "f"], ["c"], ["e"], ["g"]]`; DFS on the Multigraph → `["a", "d", "f", "b", "c", "e", "g"]` | pg-T:752-790 |
| TR-93 | petgraph's DAG plus a disjoint h→i, h→j, i→j | lexicographical → `a d b c f e g h i j`; generations `[[a, h], [d, i], [b, f, j], [c], [e], [g]]`; every edge respected | pg-T:752-790 |
| TR-94 | `networkXABCD` | lexicographical → `[A, B, C, D, G, J, K]`; generations `[[A, G, J, K], [B], [C], [D]]` (GF DG-A06); DFS on the Multigraph → `[A, B, C, D, K, J, G]` | GF DG-A06 |
| TR-95 | NetworkX `test_topological_sort1` | 1→2, 1→3, 2→3 → `[1, 2, 3]` (all three); add 3→2 → throws, witness `[2, 3]`; then remove 2→3 → `[1, 3, 2]` (all three) | nx-Tdag:142-160 |
| TR-96 | NetworkX's `topological_sort` is generations flattened, each generation in discovery order | AM/CSR: `topologicalGenerations().joined()` for `house` → `[5, 3, 2, 4, 1, 0]`, `boostCsrUnsorted` → `[3, 4, 5, 1, 0, 2]` (nx `topological_sort`); igraph's graph (TR-101) → `[0, 1, 2, 3, 4, 5, 7, 6]`. AL: compare generations as sets | nx-dag:290-303, 381-382 |
| TR-97 | NetworkX lexicographical with a key | 1→2, 2→3, 1→4, 1→5, 2→6 → `[1, 2, 3, 4, 5, 6]`; with `by: >` → `[1, 5, 4, 2, 6, 3]` | nx-Tdag:567-585 |
| TR-98 | Equal keys do not compare vertices | four vertices with one shared priority, edges 0→1, 0→2, 0→3, 2→3, `by: { $0.priority < $1.priority }` → no trap, a valid order (NetworkX: `[0, 1, 2, 3]`) | nx-Tdag:587-611 |
| TR-99 | NetworkX generations | reverse of `{1:[2,3], 2:[4,5], 3:[7], 5:[6,7]}` → `[[4, 6, 7], [3, 5], [2], [1]]`; as a multigraph with an extra 2→1 → the same | nx-Tdag:614-627 |
| TR-100 | pathfinding generation cases | diamond `[[1,2],[3],[3],[]]` → `[[0], [1, 2], [3]]`; `[[1,5],[2],[3],[],[5],[3]]` → `[[0, 4], [1, 5], [2], [3]]` | pf-T:topological_sort.rs:81-96 |
| TR-101 | igraph's Wikipedia DAG (0→3, 0→4, 1→3, 2→4, 2→7, 3→5, 3→6, 3→7, 4→6) | igraph (Kahn FIFO) `[0, 1, 2, 3, 4, 5, 7, 6]` = generations flattened in discovery order; lexicographical `[0…7]`; DFS `[2, 1, 0, 4, 3, 7, 6, 5]`; on the reversed graph igraph gives `[5, 6, 7, 4, 3, 2, 0, 1]`. With 5→0 added → throws, DFS witness `[0, 3, 5]` | ig-T:topological_sorting.c:37-66, `.out` |
| TR-104 | JGraphT's topological iterator is Kahn FIFO; Grafluent's lexicographical and DFS orders on the same graph | v0→v1, v0→v2, v1→v4, v2→v4, v3→v2, v3→v4, v4→v5: JGraphT `v0, v3, v1, v2, v4, v5`; lexicographical `v0, v1, v3, v2, v4, v5`; generations `[[v0, v3], [v1, v2], [v4], [v5]]`; DFS `v3, v0, v2, v1, v4, v5` | jgt-T:TopologicalOrderIteratorTest.java:106-133 |
| TR-105 | Parallel edges count in in-degrees | JGraphT's graph with v0→v1 and v2→v4 doubled (Multigraph): every order is still valid; generations unchanged. Also NetworkX: 9 vertices, edge i→i+1 repeated i times → `[1…9]` as the only order (nx-Tdag:299-305); NetworkX multigraph `[(1,2),(1,2),(2,3),(3,4),(3,5)×3]` → sorts `{[1,2,3,4,5], [1,2,3,5,4]}` | jgt-T:TopologicalOrderIteratorTest.java:180-210; nx-Tdag:293-305 |
| TR-106 | Self-loop: throws with the one-vertex cycle | `singleSelfLoop` → `CycleError.cycle == [0]`; `petgraphCsr1` → `[0]`; `boostExample` → `[2]` (ref) | pg-algo:201 ("Self loops are also cycles") |
| TR-107 | Cycle witness = first back edge (AM, CSR) | `completeDirected3` → `[0, 1]`; `scc9` → `[0, 3, 6]`; `boost24` → `[5, 14, 12, 4]`; `petgraphEdgesDirected` → `[0, 2, 4]`; `igraphReverseEdges` → `[1, 2, 3]`; `directedCycle10` → `[0…9]`; NetworkX `test_topological_sort2` (1→…→5→1 plus 11→…→15) → `[1, 2, 3, 4, 5]`; its `test_topological_sort3` plus 14→1 → `[1, 4, 14]` (ref) | nx-Tdag:170-208 |
| TR-108 | Kahn-based failures still give a valid witness, drawn from the vertices that were never emitted (found by a DFS over them in `vertices` order, so exact on AM/CSR) | `topologicalGenerations()` on `petgraphBellmanFord`: never emitted {0, 1, 2, 3} → witness `[0, 1]`. pathfinding cases: `[[1],[2],[0]]` → `[0, 1, 2]`; `[[1],[2],[3],[2,4],[]]` (never emitted {2, 3, 4}) → `[2, 3]`; `[[1,2],[3],[3],[3]]` → `[3]` (ref). On AL: valid, and a subset of the never-emitted vertices | pf-T:topological_sort.rs:98-117 |

### H. Reachability

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-109 | NetworkX `descendants` | 1→2, 1→3, 4→2, 4→3, 4→5, 2→6, 5→6: of 1 → `{2, 3, 6}`; of 4 → `{2, 3, 5, 6}`; of 3 → `{}` | nx-Tdag:316-323 |
| TR-110 | NetworkX `ancestors` (AL, AM, Multigraph) | same graph: of 6 → `{1, 2, 4, 5}`; of 3 → `{1, 4}`; of 1 → `{}` | nx-Tdag:307-314 |
| TR-111 | Existing reverse-reachability cases through the public API | `scc9` ancestors of 8 → `{1, 2, 4, 5, 7}`; `petgraphBellmanFord` of 8 → `{4, 5, 6, 7}`; `boostExample` of 5 → `{1}` | GF DG-A11 |
| TR-112 | A vertex on a cycle is not its own descendant | `directedCycle4` descendants of 1 → `{2, 3, 4}`; `singleSelfLoop` descendants of 0 → `{}` (NetworkX excludes the source) | nx-dag:36-70 |
| TR-113 | petgraph reach counts | H→I, H→J, I→J, I→K, isolated Z: from H reaches 4, from I reaches 3; ancestors of H = {} (reversed from H reaches only H); reversed from K reaches `{K, I, H}` | pg-T:73-96, 128-160 |
| TR-114 | `hasPath` agrees with `descendants`, and `hasPath(v, v)` is true (NetworkX `has_path(G, v, v)`) | every pair on `DirectedFixture.zeroBased` with n ≤ 10 | nx `has_path` |
| TR-183 | The `checked:` spellings (README Principle 6) | NetworkX's TR-109 graph: `descendants(checked: 4)` = `{2, 3, 5, 6}`, `ancestors(checked: 6)` = `{1, 2, 4, 5}`; for 9, both throw `VertexNotFound` | nx `NodeNotFound`, Rust `checked_*` |

### I. Bidirectional BFS

All expectations are NetworkX `bidirectional_shortest_path` on a DiGraph built with edges inserted in ascending order, so its `succ` and `pred` are ascending, like AM.

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-115 | NetworkX's cycle cases | symmetric 7-cycle: 0→3 `[0, 1, 2, 3]`, 0→4 `[0, 6, 5, 4]`, 3→3 `[3]`; directed 7-cycle 0→3 `[0, 1, 2, 3]` | nx-Tuw:30-38 |
| TR-116 | Fixtures, exact (AM; AL checks length and validity) | `house` 5→0 `[5, 3, 4, 0]`, 5→1 `[5, 3, 2, 1]`, 0→5 `nil`; `scc9` 1→3 `[1, 7, 5, 8, 6, 0, 3]`, 6→6 `[6]`; `boost24` 7→2 `[7, 11, 19, 18, 9, 1, 2]`, 23→3 `[23, 16, 6, 3]`, 1→7 `nil`; `petgraphEdgesDirected` 2→5 `[2, 4, 0, 5]`, 6→0 `nil`; `boostWebGraph` 4→2 `[4, 1, 0, 2]`, 2→4 `[2, 0, 3, 4]`; `cube` 0→7 `[0, 1, 3, 7]`; `petersen` 0→7 `[0, 5, 7]`; `directedCycle10` 9→8 `[9, 0, 1, …, 8]` (nx) | nx-uw:227-345 |
| TR-117 | Length always equals the BFS distance | property over `zeroBased` fixtures × all pairs | — |
| TR-118 | 4×4 grid, 1 → 12 (NetworkX labels 1…16 row-major, symmetric) | a valid path of 5 edges (`[1, 2, 3, 4, 8, 12]` with ascending order) | nx-Tuw:33-35 (`validate_grid_path`) |
| TR-119 | Not available on `CompressedSparseRow` | compile-time: `CompressedSparseRow` has no `bidirectionalShortestPath` (a negative-compile note in the README, not a test) | — |
| TR-120 | Source or target not a vertex traps | `processExitsWith: .failure` for (8, 3), (3, 8), (8, 8) on the 7-cycle | nx-Tuw:40-54 |

### J. Iterative deepening

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-121 | Shortest by edge count; with ascending successors, the first such path found | same values as TR-116 (they coincide on every listed pair): `house` 5→0 `[5, 3, 4, 0]`; `boost24` 7→2 `[7, 11, 19, 18, 9, 1, 2]`; symmetric 7-cycle 0→4 `[0, 6, 5, 4]` (ref) | pf:iddfs.rs:60-120 |
| TR-122 | Source == target | `[s]` | pf:iddfs.rs:101 (success tested before expanding) |
| TR-123 | Unreachable target on a finite graph terminates with `nil` | `house` 0 → 5; `scc9` 0 → 8 | pf:iddfs.rs:87-118 (`Impossible`) |
| TR-124 | Closure form needs only `Equatable` | a non-`Hashable` struct wrapping an `Int`; successors n → n+1, n+3 (≤ 20), in that order; goal 20 → `[0, 1, 2, 5, 8, 11, 14, 17, 20]` (8 edges, the BFS distance) (ref) | pf:iddfs.rs:62 (`N: Eq`) |
| TR-125 | Path length equals the BFS distance | property, `zeroBased` fixtures × pairs | — |

### K. Closure-based entry points (infinite state spaces)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-131 | DFS preorder over a closure | `depthFirstSearch(from: [0], successors: { [$0 + 1, $0 + 5].filter { $0 <= 10 } })`, preorder → `[0, 1, …, 10]` | pf-T:dfs-reach.rs:4-10 (issue 511) |
| TR-132 | Branching closure | successors n+2, n+5 (≤ 10): DFS preorder → `[0, 2, 4, 6, 8, 10, 9, 7, 5]`; BFS order → `[0, 2, 5, 4, 7, 10, 6, 9, 8]` | pf-T:dfs-reach.rs:12-16 |
| TR-133 | Many duplicate successors do not grow the stack per duplicate | 201 states, state k → 200 copies of k+1 → preorder `0…200`; the stack holds at most one frame per depth | pf-T:dfs-reach.rs:18-33 |
| TR-134 | Truly infinite space with early exit | successors n → 2n, 2n+1 from 1; BFS discovery prefix of 15 → `1…15`; DFS with `depthLimit: 3` → preorder `[1, 2, 4, 8, 9, 5, 10, 11, 3, 6, 12, 13, 7, 14, 15]` | — |
| TR-135 | Topological sort from roots over a closure | pathfinding doc: successors n ≤ 7 → [n+1, n+2], 8 → [9], else [] from roots [5, 1] → `[1, 2, 3, 4, 5, 6, 7, 8, 9]` (DFS reverse postorder) | pf:topological_sort.rs:30-44 |
| TR-136 | Closure topological sort with a cycle | pathfinding's second doc graph (n ≤ 6 → [n+1, n+2, 7]; 7 → [8, 9]; 8 → [7, 9]; else [7]) → throws; DFS witness `[7, 8]` | pf:topological_sort.rs:46-70 |
| TR-137 | The closure is called once per discovered state | roots `1…999` in a seeded shuffle, successors n → [n+1] while n < 999 → `[1…999]` with exactly 999 closure calls | pf-T:topological_sort.rs:32-49 (`complexity`) |
| TR-138 | Multi-start closure BFS reaching a goal set | a→b→c→d→e; from [a, b] the first `discover` in {d, e} is d at distance 2; path via tree edges `[b, c, d]` | pf-T:test_bfs_multiple_starts.rs:28-46 |

### L. Properties (seeded random graphs and every fixture)

Random graphs: `SeededRandomNumberGenerator` (`GF:Tests/GrafluentTestSupport/SeededRandomNumberGenerator.swift`), n ∈ {0, 1, 2, 5, 10, 40}, edge probability ∈ {0.05, 0.2, 0.5}, self-loops allowed, 50 graphs per cell, each built as AL, AM, CSR and Multigraph (a Boost-style sweep, bgl-Tdfs:125-135). Every oracle is written inside the test.

| ID | Property | Source |
|---|---|---|
| TR-139 | BFS distances are shortest: equal to a test-local Bellman–Ford with unit weights | bgl-Tbfs:190-200 |
| TR-140 | Every tree edge u→v has dist[v] = dist[u] + 1; every examined edge has dist[v] ≤ dist[u] + 1 | bgl-Tbfs:58-90 |
| TR-141 | BFS and DFS parent maps are trees: following parents from any reached vertex reaches a source in fewer than n steps; one tree edge into every non-source reached vertex | pg-Q:999-1040 ("Two tree edges to …!") |
| TR-142 | Parenthesis theorem: for discovery and finish times (event positions), intervals are disjoint or nested, and nesting means descendant in the parent tree | bgl-Tdfs:164-180 |
| TR-143 | Classification is consistent with state: tree → target undiscovered; back → target discovered and unfinished; forward → target finished and discovered after the source; cross → target finished and discovered before the source | pg-Q:1015-1032; CLRS 22.3 |
| TR-144 | Every edge out of a reached vertex appears in exactly one edge event; whole-graph DFS events cover every edge exactly once | bgl-Tdfs:212; pg-Q:1035-1036 |
| TR-145 | A back edge exists iff the graph has a cycle (oracle: test-local Kahn) | pg-algo:281-292 |
| TR-146 | `topologicalOrdering()` succeeds iff acyclic; the result is a permutation of `vertices` and every edge goes forward; same for the lexicographical order and the flattened generations | pg-T:735-750 (`assert_is_topo_order`) |
| TR-147 | The lexicographical order is the smallest: at each position, the least vertex whose predecessors all appear earlier | NetworkX definition |
| TR-148 | Generation of v = length of the longest path into v; generations partition `vertices` | nx-dag:229 |
| TR-149 | Symmetric graphs (Petersen, cube, ligraRMat, symmetrized randoms) have no cross edges, and with no self-loops, back = tree + forward | ref (Petersen: T 9, B 15, F 6; cube: T 7, B 12, F 5) |
| TR-150 | Results agree across representations: AM and CSR transcripts are identical; AL's order-independent results equal AM's | DG law tests |
| TR-151 | `descendants(of:)` = BFS reach − {v} = DFS reach − {v}; `ancestors(of: v)` in G = `descendants(of: v)` in the reversed edge list | nx-dag:36, 73 |
| TR-152 | Iterating a search twice gives the same events (multi-pass) | — |

### M. Stress and real-world fixtures

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-153 | **Deep path, no stack overflow** | path 0→…→99 999 on CSR, AL and the Multigraph (not AM: 10¹⁰ bits): DFS preorder `0…99 999`, postorder reversed, 99 999 tree events; topological DFS order `0…99 999`; BFS 100 000 layers. Run inside a `Task` so it is on a cooperative thread | pf-T:topological_sort.rs:119-131 |
| TR-154 | Deep cycle | 100 000-cycle on CSR: one back edge 99 999→0; `topologicalOrdering()` throws with a 100 000-vertex cycle `[0…99 999]` | — |
| TR-155 | Hub (out-star) | CSR, 0 → 1…99 999: BFS layers sizes `[1, 99 999]`; DFS transcript `D0 T0→1 D1 X1 T0→2 D2 X2 … X0`, stack depth ≤ 2 | — |
| TR-156 | In-star, whole graph | i → 0 for i in 1…k: `D0 X0 D1 C1→0 X1 D2 C2→0 X2 …` (k = 3 shown; run with k = 99 999) | — |
| TR-157 | `graph500Scale8` (256 vertices, 2171 edges) | from 82 (max out-degree 168): reach 235, layer sizes `[1, 167, 66, 1]`, sum of distances 302. DFS from 82 (AM/CSR): T 234, B 19, F 192, C 1715. Whole graph: T 223, B 19, F 37, C 1892, 33 roots. Every cycle is one of the 19 self-loops (256 strong components), so **B = 19 and T = reach − 1 on every representation**. Without self-loops it is a DAG: 36 generations, 22 sources, 107 sinks; lexicographical prefix `[30, 56, 61, 70, 82, 16, 22, 83, 107, 112, 114, 126]` | GF RealWorldFixtures; (nx, ref) |
| TR-158 | `gap4` (14 vertices, 58 edges) | from 0: reach 13 (vertex 5 unreachable), layers sizes `[1, 12]`; DFS from 0: T 12, B 5, F 9, C 32 (covers all 58 edges); whole graph 2 roots (0, 5). 5 self-loops, otherwise acyclic: without loops 9 generations of sizes `[2, 1, 1, 1, 2, 1, 1, 3, 2]`, lexicographical `[0, 5, 8, 7, 3, 12, 13, 2, 9, 4, 6, 10, …]`; witness with loops `[0]` | GF RealWorldFixtures |
| TR-159 | `ligraRMat` (128 vertices, 708 edges, symmetric) | from 0: reach 125, eccentricity 5, layer sizes `[1, 8, 20, 50, 41, 5]`, sum of distances 387; DFS from 0: T 124, B 354, F 230, **C 0** (symmetric; B = T + F); whole graph 4 roots; witness `[0, 22]` | GF RealWorldFixtures |
| TR-160 | Complete digraph K₁₀ | from 0: T 9, B 45, F 36, C 0; preorder `0…9` | — |
| TR-161 | Real-world, cross-representation | for each real-world fixture: AL, AM, CSR give equal distances from every source, and equal reachability | — |

### N. Generic dispatch, existentials, value semantics, preconditions

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| TR-162 | Index-based adjacency is what `AdjacencyList` runs on: BFS over `AdjacencyList<HashCounting>` hashes only to look up the sources, not once per edge | `boost24` with a test-local vertex type that counts `hash(into:)` calls, reset after construction: a full BFS from 7 makes at most a handful of calls (the source lookup); a `vertexIndex(of:)`-per-neighbor traversal would make ≥ 43 (one per edge) | the AL suite's counting vertex type |
| TR-163 | `successorIndices(ofIndex:)` laws: same multiset and order as `successors(of: vertex(atIndex:))` mapped through `vertexIndex(of:)`, for every representation and the Multigraph | every fixture | — |
| TR-164 | A conformer **without** vertex indices (`vertexIndexBound == nil`, so `successorIndices` is never called) still traverses, on dictionary state; a conformer with indices but no `successorIndices` of its own gets the default | a test-local minimal conformer (as in `DirectedGraphDefaultTests.swift`) on `house` → TR-06's transcript | — |
| TR-165 | A second generic layer reaches the representation's own `successorIndices` | `func run<G: DirectedGraph>(_ g: G)` calling `g.breadthFirstSearch` inside another generic function; hash count as TR-162 | `GF:Tests/GraphProtocolsTests/README.md:70` |
| TR-166 | Existentials through implicit opening | `func preorder(_ g: some DirectedGraph<Int>) -> [Int]` called with each of AL, AM, CSR, Multigraph as `any DirectedGraph<Int>` on `house` from 5 → each representation's preorder; `descendants(of:)` and `topologicalOrdering()` called directly on the existential | GF DG-A12 |
| TR-167 | Value semantics: the search holds a copy | `var g = AdjacencyList(house)`; `let s = g.depthFirstSearch(from: 5)`; then `g.insertEdge(0→5)`; `Array(s)` has no back edge, and a new search has one | contrast nx-Tdag:221-250 |
| TR-168 | `Sendable` | a `DepthFirstSearch<CompressedSparseRow>` and its events cross into a `Task`; compile-time check | — |
| TR-169 | Overloads: `from: "a"` with `String` vertices picks the single-source overload; `from: ["a", "d"]` the sequence one | `petgraphDAG` | — |
| TR-170 | A source that is not a vertex traps | `processExitsWith: .failure` for BFS, DFS, `descendants`, `hasPath` on `house` with 9 | nx-Tbfs:70-74 |
| TR-171 | A negative depth limit traps | `depthLimit: -1` | — |
| TR-172 | `prune()` before the first `next()` and after the sequence ends are harmless no-ops | `house` | — |
| TR-173 | Events are `Hashable` and print readably | `Set` of the events of TR-36 has 19 elements; `String(describing: DepthFirstSearchEvent.treeEdge(DirectedEdge(from: 0, to: 1)))` contains `0→1` | — |

### P. Edge-position searches

`edgeBreadthFirstSearch` and `edgeDepthFirstSearch` report the same events as the endpoint
searches, with each edge given by its position in `edges` (NetworkX's `edge_dfs`/`edge_bfs` yield
`(u, v, key)` for the same reason). Directed, the transcript read back through
`source(ofEdgeAt:)` and `target(ofEdgeAt:)` is the endpoint search's. Undirected, each edge is
reported once, at the first row that reaches it, as Boost's `undirected_dfs` does with edge
colours: the tree edge is not reported again from the vertex it discovered, a parallel edge to the
parent is a back edge (non-tree edge breadth-first), and a self-loop, listed twice in its row, is
reported once. The expected values come from `edges.py`, an independent model that marks each
edge when first reached; `gen.py` writes them into `EdgeSearchTranscriptTests.swift`. In the
transcripts, `T#k` is `.treeEdge(k)` for the edge at position k, and likewise `B#`, `F#`, `C#`
and `N#`; `D v` and `X v` are as above. Positions are offsets into the written edge list.

| ID | Asserts | Graph and call → expected | Source |
|---|---|---|---|
| TR-200 | A repeated tree edge is a forward edge at its own position | ReferenceDirectedMultigraph, edges `0→1, 0→1, 1→0`; `edgeDepthFirstSearch()` → `D0 T#0 D1 B#2 X1 F#1 X0` | edges.py |
| TR-200 | A repeated edge is a non-tree edge at its own position | ReferenceDirectedMultigraph, edges `0→1, 0→1, 1→0`; `edgeBreadthFirstSearch(from: 0)` → `D0 T#0 D1 N#1 X0 N#2 X1` | edges.py |
| TR-201 | Each copy of a directed self-loop is a back edge | ReferenceDirectedMultigraph, edges `0→0, 0→0`, vertices `[0, 1]` listed first; `edgeDepthFirstSearch()` → `D0 B#0 B#1 X0 D1 X1` | edges.py |
| TR-201 | Each copy of a directed self-loop is a non-tree edge | ReferenceDirectedMultigraph, edges `0→0, 0→0`, vertices `[0, 1]` listed first; `edgeBreadthFirstSearch(from: 0)` → `D0 N#0 N#1 X0` | edges.py |
| TR-202 | A tripled cross edge, each copy at its position | ReferenceDirectedMultigraph, edges `0→1, 1→0, 2→1, 2→1, 2→1, 1→1`; `edgeDepthFirstSearch()` → `D0 T#0 D1 B#1 B#5 X1 X0 D2 C#2 C#3 C#4 X2` | edges.py |
| TR-203 | A directed depth limit | ReferenceDirectedMultigraph, edges `0→1, 1→2, 0→2, 2→0, 1→1`; `edgeDepthFirstSearch(from: 0, depthLimit: 1)` → `D0 T#0 D1 X1 T#2 D2 X2 X0` | edges.py |
| TR-203 | A directed breadth-first depth limit | ReferenceDirectedMultigraph, edges `0→1, 1→2, 0→2, 2→0, 1→1`; `edgeBreadthFirstSearch(from: 0, depthLimit: 1)` → `D0 T#0 D1 T#2 D2 X0 X1 X2` | edges.py |
| TR-204 | The tree edge is reported once; a parallel edge to the parent is a back edge | ReferencePseudograph, edges `0–1, 0–1`; `edgeDepthFirstSearch(from: 0)` → `D0 T#0 D1 B#1 X1 X0` | edges.py |
| TR-204 | The tree edge is reported once; a parallel edge to the parent is a non-tree edge | ReferencePseudograph, edges `0–1, 0–1`; `edgeBreadthFirstSearch(from: 0)` → `D0 T#0 D1 N#1 X0 X1` | edges.py |
| TR-205 | An undirected self-loop is one back edge | ReferencePseudograph, edges `0–0, 0–1, 0–0`; `edgeDepthFirstSearch(from: 0)` → `D0 B#0 T#1 D1 X1 B#2 X0` | edges.py |
| TR-205 | An undirected self-loop is one non-tree edge | ReferencePseudograph, edges `0–0, 0–1, 0–0`; `edgeBreadthFirstSearch(from: 0)` → `D0 N#0 T#1 D1 N#2 X0 X1` | edges.py |
| TR-206 | A triangle with a doubled side and a loop: tree and back edges only | ReferencePseudograph, edges `0–1, 1–2, 2–0, 1–2, 2–2`; `edgeDepthFirstSearch(from: 0)` → `D0 T#0 D1 T#1 D2 B#2 B#3 B#4 X2 X1 X0` | edges.py |
| TR-206 | A triangle with a doubled side and a loop, breadth-first | ReferencePseudograph, edges `0–1, 1–2, 2–0, 1–2, 2–2`; `edgeBreadthFirstSearch(from: 0)` → `D0 T#0 D1 T#2 D2 X0 N#1 N#3 X1 N#4 X2` | edges.py |
| TR-207 | Each edge once, reported from the end that reaches it first | ReferencePseudograph, edges `0–1, 1–2, 1–3, 2–4, 3–0, 0–4`; `edgeDepthFirstSearch(from: 0)` → `D0 T#0 D1 T#1 D2 T#3 D4 B#5 X4 X2 T#2 D3 B#4 X3 X1 X0` | edges.py |
| TR-207 | Each edge once, from the end explored first | ReferencePseudograph, edges `0–1, 1–2, 1–3, 2–4, 3–0, 0–4`; `edgeBreadthFirstSearch(from: 0)` → `D0 T#0 D1 T#4 D3 T#5 D4 X0 T#1 D2 N#2 X1 X3 N#3 X4 X2` | edges.py |
| TR-208 | The whole of a disconnected undirected graph | ReferencePseudograph, edges `0–1, 2–3, 3–4, 4–2, 2–3`, vertices `[5]` listed first; `edgeDepthFirstSearch()` → `D5 X5 D0 T#0 D1 X1 X0 D2 T#1 D3 T#2 D4 B#3 X4 B#4 X3 X2` | edges.py |
| TR-209 | An undirected depth limit leaves forward and cross edges | ReferencePseudograph, edges `0–1, 1–2, 0–3, 3–2, 0–2`; `edgeDepthFirstSearch(from: 0, depthLimit: 2)` → `D0 T#0 D1 T#1 D2 X2 X1 T#2 D3 C#3 X3 F#4 X0` | edges.py |
| TR-209 | An undirected breadth-first depth limit | ReferencePseudograph, edges `0–1, 1–2, 0–3, 3–2, 0–2`; `edgeBreadthFirstSearch(from: 0, depthLimit: 1)` → `D0 T#0 D1 T#2 D3 T#4 D2 X0 X1 X3 X2` | edges.py |
| TR-210 | An edge to a pruned vertex is reported from its other end | ReferencePseudograph, edges `0–1, 1–2, 2–0, 1–1`; `edgeDepthFirstSearch(from: 0)`, prune at `discover(1)` → `D0 T#0 D1 X1 T#2 D2 C#1 X2 X0` | edges.py |
| TR-210 | An edge to a pruned vertex is reported from its other end, breadth-first | ReferencePseudograph, edges `0–1, 1–2, 2–0, 1–1`; `edgeBreadthFirstSearch(from: 0)`, prune at `discover(1)` → `D0 T#0 D1 T#2 D2 X0 X1 N#1 X2` | edges.py |
| TR-211 | Several roots; a reached root is skipped | ReferencePseudograph, edges `0–1, 2–3, 1–0`; `edgeDepthFirstSearch(from: [2, 1, 3, 0])` → `D2 T#1 D3 X3 X2 D1 T#0 D0 B#2 X0 X1` | edges.py |
| TR-211 | Several sources, all discovered first | ReferencePseudograph, edges `0–1, 1–2, 2–0, 2–3`; `edgeBreadthFirstSearch(from: [0, 2])` → `D0 D2 T#0 D1 N#2 X0 N#1 T#3 D3 X2 X1 X3` | edges.py |
| TR-212 | Directed: each position's endpoints give the endpoint search's transcript | PropertyBased, 200 random edge lists on 0..<6 with repeats and self-loops, BFS from a random source and DFS of the whole graph and from a list of roots, depth limits 1…3 or none: on CSR, `AdjacencyMatrix`, `AdjacencyList`, `DirectedPseudograph`, the Multigraph, a conformer without vertex indices, a conformer lending pooled rows whose position rows lie apart from its target rows, and a `StableDirectedGraph` with vertex and edge holes; also from several sources, with a vertex pruned (against the endpoint search pruned at the same vertex), and through `forEach` (against the iterator). No position is reported twice; without a limit every edge is reported | — |
| TR-213 | Undirected: the transcript is the edge-marking oracle's, on every representation | PropertyBased, 200 random edge lists on 0..<6 with repeats and self-loops, a random source, depth limit and pruned vertex: BFS, whole-graph DFS and DFS from roots against an oracle written in the test that walks `incidentEdges(of:)`. Unpruned and unlimited: every edge once, only tree and back edges, vertex events equal to the endpoint DFS on `directedView`. `forEach` against the iterator. On the ReferencePseudograph, `Pseudograph`, `UndirectedAdjacencyList`, a conformer without vertex indices, one lending pooled incident rows laid out apart, and two lending edge indices that are not positions (offset by 100, and gapped), which the search must not read as positions | bgl `undirected_dfs.hpp` |
| TR-214 | DirectedPseudograph copies: each at the position `insert(edge:)` returned; a per-copy weight read at the forward edge | hand-written | — |
| TR-215 | Pseudograph: the tree edge reported once, a parallel edge to the parent a back edge (non-tree edge breadth-first), a self-loop once; the endpoint search on `directedView` reports both arcs of all four edges | hand-written | — |
| TR-216 | Directed `prune()` (TR-81's graph, positions in written order), and pruning the root | DFS prune at `discover(2)` → `D0 T#0 D1 T#4 D3 X3 X1 T#1 D2 X2 F#2 T#3 D5 X5 X0`; BFS → `D0 T#0 D1 T#1 D2 T#2 D3 T#3 D5 X0 N#4 X1 X2 X3 X5` | pg-T:2280-2297 |
| TR-217 | Several sources, a repeated one ignored, `String` vertices, directed and undirected | hand-written | — |
| TR-218 | Value semantics, repeated iteration, `Hashable`, `Sendable`, `description` | hand-written | — |
| TR-219 | A source that is not a vertex, a negative depth limit, and `prune()` not right after a `discover` trap | exit tests, directed and undirected | — |
| TR-220 | `forEach` stops at the first error and rethrows it, over lent rows (CSR, `AdjacencyList`, `UndirectedAdjacencyList`) and without them | hand-written | — |
| TR-221 | Views whose edge indices are not their positions or whose rows are built per call: `forEach`, the iterator and the endpoint search on `directedView` agree (vertex events, tree edges, every edge once) | PropertyBased, 150 cases: `spanningSubgraphView(edges:)` keeping every other edge, `inducedSubgraphView(on:)` and `subgraphView(vertices:edges:)` dropping a vertex, a whole spanning subgraph (which lends the base's rows), and the `incidenceGraphView` of a random hypergraph | — |

### Q. All simple paths

`allSimplePaths(from:to:maxLength:)`, after NetworkX's `all_simple_paths` (a target or several, an
optional cutoff): every path with no repeated vertex, as a Walks `Path` with edge positions, so
each copy of a parallel edge gives its own path and a self-loop is on none. The order is a
depth-first search from the source taking edges in row order; a path reaching one of several
targets is listed and then extended towards the others; the source among the targets gives the
trivial path first (NetworkX 3.7 does the same). Undirected, each path is listed once, from the
source. Tests are in `SimplePathTests.swift`.

| ID | Asserts | Graph and call → expected | Source |
|---|---|---|---|
| TR-230 | Every path to one target, in depth-first order, with its positions | ReferenceDirectedMultigraph `0→1, 1→2, 0→2, 2→3`; `allSimplePaths(from: 0, to: 3)` → `[0,1,2,3]/[0,1,3]`, `[0,2,3]/[2,3]`; none from 3 to 0 | hand-computed |
| TR-231 | Several targets: a path through one goes on; the source as a target is the trivial path; repeats count once | the same; `to: [2, 3]` → `[0,1,2]`, `[0,1,2,3]`, `[0,2]`, `[0,2,3]`; `to: [0, 2]` → `[0]`, `[0,1,2]`, `[0,2]` | nx-3.7 `all_simple_paths` |
| TR-232 | `maxLength` keeps the paths of at most that many edges, in order | `to: [1, 2, 3], maxLength: 2` → `[0,1]`, `[0,1,2]`, `[0,2]`, `[0,2,3]`; `maxLength: 0` → the trivial path only | nx-3.7 `cutoff=2` |
| TR-233 | Directed parallel copies give a path each; loops and back edges are never taken | `DirectedPseudograph`, two copies of `0→1`, a loop at 1, `1→2`, `2→0` | hand-computed |
| TR-234 | Undirected: each path once, parallel edges apart, loops never taken | C₄ from 0 to 2 → `[0,1,2]/[0,1]`, `[0,3,2]/[3,2]`; `0–1, 0–1, 1–2` plus loops → two paths `[0,2]`, `[1,2]` | nx-3.7 `all_simple_edge_paths` |
| TR-235 | Unreachable targets, isolated sources, disconnected graphs | `AdjacencyList`, `UndirectedAdjacencyList` | hand-computed |
| TR-236 | Complete digraphs on n = 2 … 7: Σₖ (n − 2)!/(n − 2 − k)! paths between two vertices, directed and undirected | `CompressedSparseRow`, `UndirectedAdjacencyList` | closed form |
| TR-237 | `String` vertices; the sequence holds the graph and iterates again the same; `Sendable` | `AdjacencyList<String>` | — |
| TR-238 | A source or target that is not a vertex, or a negative `maxLength`, traps, when the sequence is made | exit tests | — |
| TR-239 | Directed: content and order are a recursive enumeration's, on every representation | PropertyBased, 200 edge lists on 0..<6 with repeats and loops, one or two targets, every bound: `ReferenceDirectedMultigraph`, a conformer without indices, `DirectedPseudograph`, CSR, `AdjacencyList`, `AdjacencyMatrix`, `StableDirectedGraph` with holes | — |
| TR-240 | Undirected: the same | `ReferencePseudograph`, a conformer without indices, `Pseudograph`, `UndirectedAdjacencyList` | — |

### R. Random walks

`randomWalk(from:length:…using:)`, as igraph's `random_walk` (stopping where it is stuck) and with
node2vec's second-order bias (Grover and Leskovec 2016): after the first step, an edge back to the
previous vertex weighs 1/p, an edge to a vertex the previous vertex has an edge to 1, any other
1/q, times the edge's weight when one is given. A step draws only through the generator's
`next()`: `next() >> (bit length shift)` by rejection for a uniform pick, the top 53 bits as a
`Double` in [0, 1) times the total otherwise, so a seed reproduces a walk on every platform and the
tests replay it draw for draw. An undirected self-loop has two ends in its vertex's row, so it is
twice as likely as another edge. Tests are in `RandomWalkTests.swift`.

| ID | Asserts | Graph and call → expected | Source |
|---|---|---|---|
| TR-250 | A walk of the graph, of the asked length, the same for the same seed; forced steps; length 0 | CSR ring with a branch | — |
| TR-251 | Stops early at a vertex with no out-edges, an isolated vertex, or edges all weighing zero; a zero-weight edge is never taken | `AdjacencyList`, `UndirectedAdjacencyList`, CSR | igraph `stuck = "return"` |
| TR-252 | Parallel copies are separate choices and the copy taken is recorded; an undirected loop has two ends | `DirectedPseudograph`, `Pseudograph`: frequencies within 0.03 of 1/3 and 2/3 over 6 000 walks | — |
| TR-253 | Weighted steps follow the weights; node2vec's 1/p, 1, 1/q bias the second step, undirected and directed | frequencies within 0.02–0.025 of the exact probabilities | Grover and Leskovec 2016 |
| TR-254 | Directed: every walk equals a reference written in the test, draw for draw, uniform, weighted, biased and both | PropertyBased, 200 cases, on the seven directed representations of TR-239 | — |
| TR-255 | Undirected: the same | the four undirected representations of TR-240 | — |
| TR-256 | `Float` weights, `String` vertices | `AdjacencyList<String>` | — |
| TR-257 | A non-vertex source, a negative length, p or q not positive and finite, a negative or NaN weight trap | exit tests | — |

### S. All topological sorts

`allTopologicalSorts()`, NetworkX's `all_topological_sorts`: every order of the vertices with each
edge forward, lazily, in lexicographic order of the vertices' positions in `vertices` (NetworkX
lists them in another order, so the differential compares counts). A cycle or a self-loop leaves
none; the empty graph has one, the empty order. Backtracking over a bit set of ready vertices.
Tests are in `AllTopologicalSortsTests.swift`.

| ID | Asserts | Graph and call → expected | Source |
|---|---|---|---|
| TR-260 | Hand-computed orders: a fork, a diamond, a chain; positions, not values, order them | `[[0,1,2],[0,2,1]]` for `0→1, 0→2` | nx-3.7 |
| TR-261 | The empty graph has `[[]]`; isolated vertices have every permutation (5 040 for 7) | — | nx-3.7 |
| TR-262 | A cycle or a self-loop leaves none; parallel edges change nothing | — | — |
| TR-263 | 70 vertices: the ready set spans two words; the first three orders | CSR | — |
| TR-264 | Every order is a filtered permutation, in lexicographic order, on every representation | PropertyBased, 200 cases, cyclic or acyclic, on the seven directed representations, vertices listed out of order | — |
| TR-265 | The sequence holds the graph and iterates again the same; `Sendable` | — | — |

### T. Lexicographic breadth-first and maximum cardinality search

`lexicographicBreadthFirstSearch()` (Rose, Tarjan and Lueker) and `maximumCardinalitySearch()`
(Tarjan and Yannakakis), with and without `from:`, on the simple graph of an undirected graph.
LexBFS: a vertex's label is the visit positions of its visited neighbors, ascending; the next
vertex has a greatest label (smaller position at the first difference, or extending the other).
MCS: the most visited neighbors. Both start at the first vertex in `vertices` order unless given
`from:`; which of several equal vertices goes next is unspecified, the same for the same graph and
rows. LexBFS is array-based partition refinement, MCS bucket queues, both O(n + m). Tests are in
`ChordalOrderingTests.swift`; Cliques' chordality is built on MCS.

| ID | Asserts | Graph and call → expected | Source |
|---|---|---|---|
| TR-270 | Forced orders: a path from either end, a square's far corner last under LexBFS, a star's center right after a leaf | C₄: LexBFS ends at 2 | hand-computed |
| TR-271 | Labels against counts: a vertex never labelled by the first visit comes last under LexBFS | — | hand-computed |
| TR-272 | Components, isolated vertices, the empty graph; loops and parallel copies; a graph that empties classes faster than it has vertices; repeat calls equal; `String` vertices | — | — |
| TR-273 | A source that is not a vertex traps | exit tests | — |
| TR-274 | Both orders valid at every step by their definitions with explicit labels and counts, starting where asked, and repeatable, with and without a start | PropertyBased, 300 multigraphs on 9 vertices, vertices listed out of order, on `ReferencePseudograph`, a conformer without indices, `Pseudograph`, `UndirectedAdjacencyList` | — |

### O. Benchmarks (not tests)

| ID | Measures |
|---|---|
| TR-B01 | `for _ in g.breadthFirstSearch(from: 0)` vs a hand-written index BFS, CSR, `graph500Scale8` and a 1 000 × 1 000 grid |
| TR-B02 | BFS on `AdjacencyList<Int>` with and without `successorIndices` |
| TR-B03 | DFS event stream vs `preorder` only (does the classification cost matter?) |
| TR-B04 | Dense vs dictionary state: the same graph as CSR vs a conformer without indices |
| TR-B05 | Deep DFS: a 10⁷-vertex path on CSR (memory and time of the explicit stack) |
| TR-B06 | The edge-position searches, pulled and pushed, against the endpoint searches and against hand-written edge-position loops over the flat rows, on CSR, `AdjacencyList` and `UndirectedAdjacencyList` |
| TR-B07 | `allSimplePaths` counts against a hand-written iterative enumeration over the flat rows: the 10 × 10 grid DAG (48 620 paths, all reaching the target) and G(12, 40) (mostly dead ends) |
| TR-B08 | `randomWalk` of 10⁵ steps on CSR and `AdjacencyList` against a hand-written walk over the flat rows drawing the same bits; weighted on CSR; node2vec on `UndirectedAdjacencyList` |
| TR-B09 | `allTopologicalSorts` count (two chains of 3 and 3 free vertices, 60 480 orders) against a hand-written backtracking count |
| TR-B10 | `lexicographicBreadthFirstSearch` and `maximumCardinalitySearch` on `UndirectedAdjacencyList`, G(10⁵, 10⁶), against a hand-written breadth-first search of every component |
