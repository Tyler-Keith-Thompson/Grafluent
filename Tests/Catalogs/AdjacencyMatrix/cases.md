# Test catalog: `AdjacencyMatrix` (dense directed bit-matrix graph)

This catalog collects test cases for Grafluent's planned `AdjacencyMatrix`, harvested from mature graph and bitset libraries. Cases are grouped by behavior and deduplicated across libraries. The type under test is a directed graph on vertices `0..<vertexCount`, stored as an n×n bit matrix. It allows self-loops, cannot hold parallel edges, grows through `appendVertex()`, and has no arbitrary vertex removal.

It is a companion to `test-catalog-adjacency-list.md` in this folder. Section 0 of that file covers list-graph conventions. This file covers what is specific to the matrix representation.

**Sources** (shallow clones, Oct 2026):

| Library | Commit | Licence |
|---|---|---|
| petgraph | `a4d94bd` | MIT OR Apache-2.0 |
| boostorg/graph | `1ee1a99` | BSL-1.0 |
| networkx | `6da4704` | BSD-3-Clause |
| jgrapht | `63976aa` | EPL-2.0 OR LGPL-2.1-or-later |
| gonum | `0d48cee` | BSD-3-Clause |
| swift-algorithm-club | `05c6d0b` | MIT |
| LEMON (OpenROAD mirror) | `31d79d6` | BSL-1.0 |
| igraph | (cloned for this catalog) | GPL-2.0-or-later |
| fixedbitset | `111fb25` | MIT OR Apache-2.0 |
| swift-collections | `3b69ced` | Apache-2.0 with Runtime Library Exception |

Cases marked **(verified)** were confirmed by running a probe program against the local petgraph clone (a scratch Rust probe, not kept). Everything else comes from reading the tests or the code; NetworkX was not run because numpy is not installed.

**Path prefixes used in citations**

| Prefix | Expands to (`research/` = upstream shallow clones, Oct 2026, not kept in the repository) |
|---|---|
| `pg:` | `research/petgraph/crates/petgraph/` (MG = `src/matrix_graph.rs`, AMT = `tests/adjacency_matrix.rs`, G6 = `tests/graph6.rs`, TG = `src/traits_graph.rs`) |
| `bgl:` | `research/graph/` (AMH = `include/boost/graph/adjacency_matrix.hpp`, AMT = `test/adjacency_matrix_test.cpp`, EX = `example/adjacency_matrix.cpp`, DOC = `doc/modules/ROOT/pages/graph_classes/adjacency_matrix.adoc`) |
| `nx:` | `research/networkx/` (TN = `networkx/tests/test_convert_numpy.py`, TS = `networkx/tests/test_convert_scipy.py`, GM = `networkx/linalg/tests/test_graphmatrix.py`, CM = `networkx/convert_matrix.py`, TW = `networkx/algorithms/tests/test_walks.py`) |
| `ig:` | `research/igraph/tests/unit/` |
| `fbs:` | `research/fixedbitset/` (T = `tests/tests.rs`) |
| `sc:` | `research/swift-collections/Tests/BitCollectionsTests/` (BA = `BitArrayTests.swift`) |
| `gn:` | `reviews/oss/gonum/graph/` |
| `jgt:` | `research/jgrapht/jgrapht-io/src/test/java/org/jgrapht/nio/` (ME = `matrix/MatrixExporterTest.java`, CE = `csv/CSVExporterTest.java`, CI = `csv/CSVImporterTest.java`) |
| `sac:` | `reviews/oss/swift-algorithm-club/` |
| `lemon:` | `research/lemon/` |

Case IDs such as `AM-C03` are stable, so test names can refer to them. **Grafluent decision** marks a point where the libraries disagree and our spec has to choose.

---

## 0. Cross-library convention matrix (read this first)

| Convention | petgraph `MatrixGraph` | Boost `adjacency_matrix` | gonum `simple.DirectedMatrix` | NetworkX (matrix conversion) | igraph | Planned Grafluent |
|---|---|---|---|---|---|---|
| Storage | `Vec<Option<E>>`, flat n×n with **capacity-strided rows** when directed; lower triangle when undirected | `std::vector<char>` (one **byte** per entry, not a bit) when there is no edge property, else `vector<pair<bool,EP>>`. n² entries when directed, n(n+1)/2 when undirected | `mat.Dense` of float64 | numpy/scipy array (output only) | sparse or dense matrix (I/O only) | n×n bits |
| Vertex count | grows on `add_node` | **fixed at construction**: `add_vertex` and `remove_vertex` are `BOOST_ASSERT(false)` "UNDER CONSTRUCTION" | fixed at `NewDirectedMatrix(n, ...)` | — | — | grows by `appendVertex()` |
| Vertex removal | yes: clears the row and column and recycles the index for the next `add_node` | no | no | — | — | no |
| Duplicate insert | `add_edge` **panics**; `update_edge` upserts | `add_edge` returns `(e, false)`, no-op | `SetEdge` overwrites the weight | — | — | idempotent (`insert` returns whether it was new) |
| Remove absent edge | `remove_edge` panics; `try_remove_edge` → `None` | silent no-op; count unchanged (tested) | silent no-op, even out of range | — | — | no-op returning `false` |
| Out-of-range query | `has_edge` → `false` (verified) | **undefined behavior** (raw `vector[]` index) | `HasEdgeFromTo` → `false`, `Node` → nil, but `Weight(x,x)` → `(self, true)` for any x | raises on bad nodelist | `IGRAPH_EINVVID` | `contains(edge:)` → `false`; subscript/insert → precondition |
| Out-of-range insert | **silently grows the matrix** despite "Panics" in the docs (verified) | UB | panics (matrix index panic, no explicit check) | — | — | precondition failure |
| Directed loop: out/in degree | listed in both out- and in-neighbors (verified) | out 1, in 1, `degree` = in + out = **2** | **forbidden**: `SetEdge(v,v)` panics; the diagonal holds the `self` value | diagonal = 1 | diagonal = 1 even with LOOPS_TWICE | out 1, in 1, `degree` 2 |
| Undirected loop | neighbors list it **once**; `edges(a).count()` counts it once | `degree == out_degree`, loop counted **once** | — | diagonal **1**, but `G.degree` counts 2 | caller chooses LOOPS_ONCE (1) or LOOPS_TWICE (2) | n/a (directed only) |
| Equality | none | none | — | — | — | `Equatable` by n plus bits |
| Neighbor order | ascending index (row scan) | ascending index | ascending | nodelist order | ascending | ascending (must be documented) |

The main point: **only petgraph supports both growth and removal on a matrix graph, and it does so by keeping removed indices as holes that the next `add_node` reuses.** Boost and gonum fix the vertex count. Grafluent's "append only, no removal" policy sits between the two. Its tests should pin exactly what petgraph gets wrong (see AM-V02, AM-V03).

---

Other conventions that matter for later sections:
- **Loop on the diagonal when exported.** JGraphT `MatrixExporter` writes **2** for a loop, even in a directed graph. JGraphT's CSV MATRIX exporter writes **1** for the same directed loop. NetworkX writes 1 (both directed and undirected). igraph lets the caller choose. LEMON `FullDigraph` counts a loop as 1 out-arc plus 1 in-arc.
- **What "absent" means.** gonum: a user-chosen value (NaN-aware). JGraphT CSV import: only the literal `0` is absent, and `0.0` is a weight-0 edge. JGraphT's generator: every off-diagonal cell is an edge. NetworkX: any nonzero entry is an edge. Grafluent's bit matrix has no such ambiguity, but `init(rows: [[Int]])` must decide what to do with values other than 0 and 1 (AM-C10).

---

## 1. Construction

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-C01 | Empty graph | petgraph `new()`, `default()` and `with_capacity(10)`: `node_count == 0`, `edge_count == 0`. igraph 0×0 matrix gives vcount 0 and no edges. NetworkX `to_numpy_array(Graph())` gives a 0×0 array (but `to_scipy_sparse_array` **raises** "Graph has no nodes or edges"). JGraphT `CSRBooleanMatrix` **rejects** 0 rows or columns. Swift: `AdjacencyMatrix(vertexCount: 0)` has `vertexCount == 0`, `edgeCount == 0`, `description == ""`, `contains(vertex: 0) == false` | pg:MG:1525-1544; ig:igraph_adjacency.c (0x0 case), .out:1-5; nx:CM:1067-1069, nx:TS:170-172; jgrapht-opt CSRBooleanMatrix.java:62-99 |
| AM-C02 | `init(vertexCount:)` gives n isolated vertices | Boost `Graph g(24)`, then `num_vertices == 24` before any edge. gonum `NewDirectedMatrix(n, absent, …)` with init=absent: every `From(i)` is empty, `Node(5..9) == nil` for n=5. Swift: n ∈ {1, 2, 5, 64}: `edgeCount == 0`, every `successors(of:)` and `predecessors(of:)` is empty, every degree is 0 | bgl:AMT:44-50; gn:simple/densegraph_test.go:542-562 |
| AM-C03 | Fully passable constructor = complete graph **without** loops | gonum `init=1, absent=+Inf`, n=5: every vertex has degree 4 = n-1. Directed n=15, init=1: 15·14 = **210** edges, and after `RemoveEdge(12,11)` there are 209. The diagonal is not an edge. Swift: build K_n by setting every off-diagonal bit. n=15 → `edgeCount == 210`. Remove (12,11) → 209 | gn:simple/densegraph_test.go:565-585, 635-661 |
| AM-C04 | Complete digraph **with** loops has n² arcs | LEMON `FullDigraph(8)`: nodeNum 8, **arcNum 64**, each node out 8 and in 8 (the loop counts once each way). Swift: n=8 all-ones literal → `edgeCount == 64`, `outDegree == inDegree == 8` for every vertex | lemon:test/digraph_test.cc:505-540, 561 |
| AM-C05 | From an edge list | Boost constructs `adjacency_matrix(first, last, n)` from the 43 arcs of FX-02 and the result equals the source graph after sorting and deduplicating the edge pairs. petgraph `from_edges([(0,5),(0,2),(0,3),(0,1),(1,3),(2,3),(2,4),(4,0),(6,6)])` → 7 vertices (implied by max id 6), 9 edges (FX-03) | bgl:AMT:183-238; pg:MG:1860-1889 |
| AM-C06 | From an edge list, the vertex count is **implied** by the max endpoint (petgraph) vs **given** (Boost) | petgraph `from_edges`/`extend_with_edges` add nodes until `max(source, target) < node_count` (MG:674-689). Boost requires `n_vertices` explicitly. **Grafluent decision:** `init(vertexCount:edges:)` takes n explicitly, and an out-of-range endpoint is a precondition failure, not growth | pg:MG:654-689; bgl:AMH:567-580 |
| AM-C07 | Duplicate edges in the input collapse | Boost constructor calls `add_edge` per pair, and `add_edge` on an existing entry returns `false` without incrementing `m_num_edges`. The Boost test sorts and deduplicates before comparing. petgraph `from_edges` with a duplicate **panics** (it calls `add_edge`, which asserts no old weight). Swift: `init(vertexCount: 3, edges: [(0,1),(0,1),(1,2)])` → `edgeCount == 2`. **Grafluent decision:** collapse silently, like Boost | bgl:AMH:918-941, bgl:AMT:229-236; pg:MG:466-469 (verified panic) |
| AM-C08 | From a 0/1 matrix literal, entry (i,j) = 1 means arc i→j (row = source) | petgraph iso tests parse whitespace 0/1 rows with `row` as the source (`update_edge(row, col)`) and assert each entry is 0 or 1. NetworkX `np.diag(ones(4), k=1)` (5×5 superdiagonal) as a DiGraph gives arcs i→i+1 only, so the superdiagonal is the **out** direction. Swift: `[[0,1,0,0,0],[0,0,1,0,0],[0,0,0,1,0],[0,0,0,0,1],[0,0,0,0,0]]` gives path 0→1→2→3→4, `contains(edge: (0,1))` is true and `contains(edge: (1,0))` is false | pg:tests/iso.rs:204-226; nx:TN:399-406, 457-466 |
| AM-C09 | Non-square input is rejected | NetworkX `from_numpy_array([[1,2,3],[4,5,6]])` raises "Adjacency matrix not square". The same holds for scipy `lil_array`. A non-2-D (2×2×3) array raises "Input array must be 2D". igraph 3×1 matrix → `IGRAPH_EINVAL`. JGraphT CSV import with a short row (`;;;1`, 4 cells in a 5-wide matrix) → `ImportException`. JGraphT's generator checks squareness only with Java `assert` (off in production). Swift: `[[0,1],[1]]`, `[[0,1,0],[1,0,0]]` (2×3) and `[[0],[0],[0]]` (3×1) are each a precondition failure. A ragged literal whose row count equals the longest row (`[[0,1,1],[0],[0,0,0]]`) must fail too | nx:TN:38-41, 116-120, nx:TS:64-67, nx:CM:1268-1270; ig:igraph_adjacency.c (non-square case); jgt:CI:619-640; jgrapht-core SimpleWeightedGraphMatrixGenerator.java:79,86 |
| AM-C10 | Entries other than 0/1 | petgraph's test parser asserts `has_edge == 0 \|\| has_edge == 1`. igraph rejects a negative entry (`-3`) with `IGRAPH_EINVAL`. NetworkX treats integers as edge counts or weights. JGraphT CSV import rejects `0.0` in unweighted mode. **Grafluent decision:** precondition that each entry is 0 or 1. Test that `[[0,2],[0,0]]` and `[[0,-1],[0,0]]` trap | pg:tests/iso.rs:213; ig:igraph_adjacency.c (negative case); jgt:CI:565-589 |
| AM-C11 | 1×1 literals | igraph 1×1 `[1]` (directed, loops once or twice) → one arc `0 0`. With NO_LOOPS → no arcs. NetworkX `[[1]]` → self-loop (0,0). Swift: `[[1]]` → `edgeCount == 1`, `contains(edge: (0,0))`. `[[0]]` → `vertexCount == 1`, `edgeCount == 0` | ig:igraph_adjacency.out:7-24; nx:TN:93-114 |
| AM-C12 | An empty literal `[]` is the 0-vertex graph | NetworkX 0×0 → empty graph. igraph 0×0 → vcount 0. Swift: `let m: AdjacencyMatrix = []` equals `AdjacencyMatrix(vertexCount: 0)` | nx:CM:1067-1069; ig:igraph_adjacency.out:1-5 |
| AM-C13 | Isolated vertices survive literal construction | NetworkX `add_nodes_from(nodelist)` runs before edges, so an all-zero n×n gives n vertices and 0 edges. havel_hakimi fixture row 4 is all zero (FX-06). Swift: 5×5 zero literal → `vertexCount == 5`, `edgeCount == 0` | nx:CM:1284-1285; nx:GM:83-89 |
| AM-C14 | Construction is independent of edge order | Boost: adjacency_list (setS) and adjacency_matrix built with the same 43 arcs give identical adjacency, out-edge and in-edge sequences, vertex by vertex. Swift: build FX-02 from `edges.shuffled()` with seeds 1-10, all equal | bgl:AMT:44-160 |

---

## 2. Entry subscript `m[source, target]`

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-S01 | Read entry = membership | petgraph a,b,c with a→b, b→c: `has_edge(a,b)`, `has_edge(b,c)`, `!has_edge(a,c)`. Swift: `m[0,1] == true`, `m[1,2] == true`, `m[0,2] == false`, and `m[1,0] == false` (direction matters) | pg:MG:1601-1613 |
| AM-S02 | Write true = insert; write false = remove; counts track | Boost `add_edge` increments `m_num_edges` only if the bit was clear, and `remove_edge` decrements only if it was set. Swift: `m[0,1] = true` twice → `edgeCount == 1`. `m[0,1] = false` twice → `edgeCount == 0` (never negative) | bgl:AMH:918-967; bgl:AMT:241-255 |
| AM-S03 | Remove-absent does not decrement | Boost `test_remove_edges`: n=2, add (0,1) → E=1, remove → 0, remove again → **still 0**. Run for both directed and undirected. Swift: same sequence through both `remove(edge:)` and `m[0,1] = false` | bgl:AMT:241-255, 273-274 |
| AM-S04 | Reading after a resize preserves entries | petgraph `with_capacity(3)`, nodes 0..3, arcs 1→0, 1→1, then 2→3 triggers growth from capacity 3 to 4. All 3 still present, E=3. Regression #425: 6 nodes, arcs 2→1, 2→3, 2→4 trigger a second extension and all survive. Swift: see AM-G02 | pg:MG:1580-1599, 1615-1631 |
| AM-S05 | Exhaustive cell check against an edge set | petgraph `test_adjacency_matrix` checks `is_adjacent(a,b)` for every ordered pair: true iff (a,b) ∈ edges (or (b,a) when undirected). It runs on the 10 TEST_CASES (FX-04). Swift: for every fixture, `∀ i,j: m[i,j] == edgeSet.contains((i,j))` | pg:AMT:14-33, 181-201 |
| AM-S06 | Matrix export cell semantics | gonum testgraph `AdjacencyMatrix` check: `Matrix()` is square with r == c == order. A cell equals `absent` when `Weight` is !ok, `self` on the diagonal, and the weight otherwise. Swift analogue: `rows` (the `[[Bool]]` or `[[Int]]` view) has n rows of length n, and `rows[i][j] == m[i,j]` | gn:testgraph/testgraph.go:1187-1231 |

---

## 3. Out-of-range vertices (what each library does)

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-R01 | `contains(edge:)` with out-of-range ids is `false`, not a trap | petgraph `has_edge(10, 100)` on 3 nodes → `false`, and also on an empty graph (verified). gonum `HasEdgeFromTo` → `false`, `Node(5..9)` → nil for n=5. fixedbitset `contains(i)` for i ≥ len → `false` (N=50, checks 0..<60). Swift: `contains(edge: (10,100)) == false`, `contains(vertex: n) == false`, `contains(vertex: -1) == false` | pg:MG:1612, 524-535; gn:simple/dense_directed_matrix.go:136-147, densegraph_test.go:542-562; fbs:T:14-38 |
| AM-R02 | `successors(of:)` and `predecessors(of:)` of an absent vertex | petgraph `edges(0)` and `neighbors(0)` on an empty graph → empty iterator, no panic. **Grafluent decision:** precondition (the planned API) or empty? If it is a precondition, add an exit test. If empty, match petgraph | pg:MG:1914-1924 |
| AM-R03 | Insert with an out-of-range endpoint | petgraph docs say "Panics if any of the nodes don't exist", but `add_edge(0, 5)` on a 1-node graph **silently grows the matrix**: `node_count` stays 1 and `edge_count` becomes 1 (verified). `add_or_update_edge(10, 20)` → `Ok(None)`, `has_edge(10,20)` is true and capacity ≥ 20 (tested, intentional). gonum `SetEdge` panics through the matrix index check. Boost: UB. igraph `are_adjacent(0, vcount+2)` → `IGRAPH_EINVVID`. Swift: `insert(edge: (0, n))`, `m[n, 0] = true` and `remove(edge: (0, n))` are each a precondition failure (exit test) | pg:MG:419-469, 2092-2105; gn:simple/dense_directed_matrix.go:211-214; ig:igraph_are_adjacent.c (invalid vertex block) |
| AM-R04 | `try_update_edge` reports *which* endpoint is missing | petgraph `try_update_edge(10, 20, 5)` → `Err(NodeMissed(10))`, the first bad index. Relevant only if we add a throwing variant | pg:MG:2074-2090, 692-700 |
| AM-R05 | Remove out of range | gonum `RemoveEdge` out of range is a **silent no-op**. petgraph `try_remove_edge` → `None`. Boost: UB. **Grafluent decision** (spec says precondition): test `remove(edge: (n, 0))` traps | gn:simple/dense_directed_matrix.go:182-190; pg:MG:509-519 |
| AM-R06 | Boundary ids: exactly n-1 is valid, n is not | (Not tested anywhere directly.) Swift: for n ∈ {1, 63, 64, 65}: `m[n-1, n-1] = true` works. `contains(edge: (n-1, n))` is false. `m[n-1, n]` traps. This catches off-by-one row-stride bugs | — |
| AM-R07 | `Weight(x,x)` style diagonal queries must not bypass range checks | gonum returns `(self, true)` for **any** x, even out of range. That is a bug class to avoid: Swift `m[n, n]` must trap and `contains(edge: (n, n))` must be false | gn:simple/dense_directed_matrix.go:255-258 |

---

## 4. Vertex addition and growth semantics

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-G01 | `appendVertex()` returns the new index n and the new vertex is isolated | petgraph `add_node` returns sequential indices (a,b → 0,1). `node_count` goes 0 → 2 and `edge_count` stays 0. Swift: `appendVertex()` on n=3 returns 3. After it, `vertexCount == 4`, `successors(of: 3)` and `predecessors(of: 3)` are empty, and every other row gains a 0 in column 3 | pg:MG:1546-1555 |
| AM-G02 | Growth preserves every existing bit at its (i,j) | petgraph `extend_flat_square_matrix` moves each old row from stride `old` to stride `new` (MG:1023-1065). Tests #425 and resize (AM-S04). Swift: for start sizes n ∈ {0,1,3,4,7,8,31,32,63,64,65,127,128}, fill a random pattern with a fixed seed, `appendVertex()` k ∈ {1,2,64} times, then check every old cell is unchanged and every new row and column is 0 | pg:MG:1580-1631, 1023-1065 |
| AM-G03 | Capacity growth policy | petgraph grows to `max(next_power_of_two(n), 4)`, but `with_capacity(c)` is exact. Swift: `reserveCapacity(vertexCount:)` (if offered) must not change `vertexCount`, `==` or `hashValue`. Equality must ignore capacity (AM-Q03) | pg:MG:1023-1037, 1539-1544 |
| AM-G04 | Fixed-size libraries forbid growth | Boost `add_vertex` is `BOOST_ASSERT(false)` "UNDER CONSTRUCTION". The docs warn it is unsupported. gonum has no AddNode. LEMON `resize(n)` "fully destroys and rebuilds" (maps lose values). swift-algorithm-club `createVertex` appends a nil to every row and then a new row, O(n) rows touched per vertex. This is the rationale for testing that `appendVertex()` is amortised (AM-Z03) | bgl:AMH:978-994; bgl:DOC:45; lemon:lemon/full_graph.h:191-196; sac:Graph/Graph/AdjacencyMatrixGraph.swift:43-66 |
| AM-G05 | Index-type limit | petgraph with `Ix = u8` and `with_capacity(255)`: 255 `try_add_node` calls succeed with ids 0..254. The 256th → `Err(NodeIxLimit)`. Swift uses `Int`, so only check that n·n overflow is guarded: `AdjacencyMatrix(vertexCount: Int.max)` must trap, not wrap (see fixedbitset `grow_and_insert(usize::MAX)` overflow test, a known memory-safety bug) | pg:MG:2120-2130; fbs:T:115-122 |
| AM-G06 | Growing across a word boundary | fixedbitset `with_capacity(48)`, set all, `grow(72)`: bits < 48 are set and ≥ 48 are clear. `set(64)` works afterwards. Swift: n=63 all-ones, `appendVertex()` ×2 → row 0 is 63 ones then `00`. Column 63 and 64 are all 0. `m[64,64] = true` works | fbs:T:85-100 |
| AM-G07 | Appending to the empty matrix | (petgraph `add_node` on `new()`.) Swift: `var m = AdjacencyMatrix(vertexCount: 0)`. `m.appendVertex() == 0`, then `m[0,0] = true`, `edgeCount == 1`, `description == "1"` | pg:MG:1546-1555 |

---

## 5. Vertex removal (and why most matrix graphs don't offer it)

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-V01 | petgraph removal clears the row and column and keeps other indices stable | a→b→c→a, `remove_node(b)` → node_count 2, `neighbors(a) == []`, `neighbors(c) == [a]`. Undirected: remove a → `neighbors(b) == [c]`, `neighbors(c) == [b]`. The index of c stays 2, so there is **no renumbering**. The freed id is pushed onto `removed_ids` and the next `add_node` reuses it (`IdStorage` test: remove b, `add('B')` returns b's id) | pg:MG:1802-1844, 1960-1981, 380-397, 1108-1133 |
| AM-V02 | **petgraph bug: `edge_count` is not decremented by `remove_node`** | a→b, b→c, c→a, remove b → node_count 2 but `edge_count == 3` (should be 1) (verified). No upstream test checks `edge_count` after `remove_node`. Lesson for Grafluent: any future "clear vertex" or "remove vertex" must keep `edgeCount` consistent. Assert `edgeCount == edges.count` after every mutation in the property tests (AM-Z05) | pg:MG:380-397 (verified with the petgraph probe) |
| AM-V03 | Holes break algorithms unless they are skipped | petgraph #523: 3 nodes, remove the middle one. `tarjan_scc == [[0],[2]]` and `kosaraju_scc == [[2],[0]]`. Before the fix, the hole was visited as a vertex. petgraph `StableGraph::is_adjacent` uses `node_count` as the row stride while `adjacency_matrix()` uses `node_bound`. After removing the middle of 3 nodes with arcs 2→0 and 0→2, `is_adjacent(2,0)` returns **false** (verified bug). That is why Grafluent keeps dense ids and has no removal | pg:MG:2040-2072; pg:TG:47-74 (verified) |
| AM-V04 | Fixed-size libraries offer only "clear vertex" | Boost `remove_vertex` is `BOOST_ASSERT(false)`. `clear_vertex(u)` removes every out-edge and (directed) in-edge, in O(V), and leaves the vertex in place. gonum and LEMON have no removal at all. swift-algorithm-club has no removal. Grafluent equivalent (if added later): `removeAllEdges(incidentTo:)`. Test: FX-01 `clear(2)` → row 2 and column 2 are zero, `edgeCount == 7 - 3 == 4` (2→0, 2→2 and 1→2 removed; the loop counts once) | bgl:AMH:996-1029; bgl:DOC:45 |
| AM-V05 | Why removal is avoided | Removing vertex k from a dense-index matrix either renumbers all vertices > k (invalidating caller-held ids; Boost adjacency_list vecS does this, see list catalog V-11) or leaves a hole (petgraph, with the AM-V02/V03 bugs). Removing the row and column is also O(n²) bit moves. Spec test: the type has no `removeVertex` API (compile-time; document it in the DocC article) | design rationale; bgl:DOC:45 |
| AM-V06 | `removeAllEdges()` keeps vertices | petgraph `clear()` removes **nodes too** (node_count → 0). Re-adding 3 nodes then gives empty in- and out-neighbor lists, so no stale bits survive. Grafluent's `removeAllEdges` keeps n. Swift: FX-01 → `removeAllEdges()` → `vertexCount == 6`, `edgeCount == 0`, equals `AdjacencyMatrix(vertexCount: 6)`. Then `appendVertex()` gives a clean row and column | pg:MG:1674-1735, 315-322 |

---

## 6. Edge insertion and removal

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-E01 | Insert returns whether it was new | Boost `add_edge` returns `(e, true)` the first time and `(e, false)` for a duplicate. petgraph `update_edge` returns the old weight: `try_update_edge(a,b,10) → Some(1)`, then `(a,c,33) → None` and `(a,c,66) → Some(33)`. Swift: `insert(edge:)` → `(inserted: true)` then `(inserted: false)`, and `edgeCount` changes only once | bgl:AMH:918-941; pg:MG:2074-2105 |
| AM-E02 | Remove returns whether it was present | petgraph `try_remove_edge(a,b) → Some(1)`, again → `None`, `(a,c)` (never added) → `None`. Boost silently no-ops (AM-S03). Swift: `remove(edge:)` → true, false, false | pg:MG:2107-2118 |
| AM-E03 | Antiparallel arcs are distinct | gonum: set 0→2 with weight 1, remove, re-add with weight 2. `Weight(2,0) != Weight(0,2)`. Swift: insert (0,2), then `contains(edge: (2,0)) == false`. Insert (2,0) → `edgeCount == 2`. Remove (0,2) → (2,0) still present | gn:simple/densegraph_test.go:588-618 |
| AM-E04 | Remove leaves every other edge intact (randomised) | gonum `RemoveEdges`: n=100, random out-edges (PCG seed (1,1), 0-4 per node). After each removal that edge is gone, all others remain, and both endpoints still exist. Swift: same with `SystemRandomNumberGenerator` replaced by a seeded generator. After each removal, `rows` equals the reference `Set<Edge>` | gn:simple/densegraph_test.go:121-138; gn:testgraph/testgraph.go:1932-1975 |
| AM-E05 | Insert-delete sequence with exact counts | gonum `TestDenseLists`: n=15 complete without loops (210), remove (12,11) → 209. Boost: add (0,1), remove, remove → 0, 0 | gn:simple/densegraph_test.go:635-661; bgl:AMT:241-255 |
| AM-E06 | Self-loop insertion | petgraph `add_edge(n1, n1)` is accepted and counts 1 edge (AM-S04). gonum **panics** (`SetEdge(v,v)` for every v in 0..<100). Boost `add_edge(C,C)` is accepted (FX-01). Swift: loops allowed: `insert(edge: (v,v))` for every v in 0..<100 → `edgeCount == 100` and the matrix equals the identity | pg:MG:1615-1631; gn:testgraph/testgraph.go:1728-1750, densegraph_test.go:109-114; bgl:EX |
| AM-E07 | Inserting the same edge set in any order gives `==` matrices | Boost AMT compares two representations built from the same calls. Swift: insert the FX-02 arcs in 10 seeded shuffles; all are `==` with equal `hashValue` | bgl:AMT:44-160 |

---

## 7. Self-loops (the diagonal) and their degree convention

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-L01 | Directed loop appears once in successors and once in predecessors | petgraph `DiMatrix` loop on y: `neighbors_directed(y, Outgoing) == [y]` and `Incoming == [y]` (verified). petgraph `edges_directed` on FX-03: vertex 6 (loop only) has Outgoing count 1 and Incoming count 1. Swift: `m[6,6] = true` → `successors(of: 6) == [6]`, `predecessors(of: 6) == [6]` | pg:MG:1860-1889 (verified) |
| AM-L02 | Directed loop degree: out 1 + in 1 = degree 2 | Boost directed `degree = in_degree + out_degree`, so a loop contributes 2. LEMON FullDigraph: each node has out-arc count 8 and in-arc count 8 including its loop. JGraphT CSV fixture J-FX: vertex 5 has a loop and outdeg 5, indeg 2. Swift: FX-01 vertex C=2 (arcs C→A, C→C; in from B, C) → `outDegree 2`, `inDegree 2`, `degree 4` | bgl:AMH:826-833; lemon:test/digraph_test.cc:505-540; jgt:CE:384-408 |
| AM-L03 | Loop counts **1** in `edgeCount` | Boost FX-01 (with C→C) has 7 arcs. petgraph FX-03 (with 6→6) has 9 edge references, directed and undirected. Swift: FX-01 → `edgeCount == 7` | bgl:EX; pg:MG:1926-1958 |
| AM-L04 | Diagonal value in exports disagrees across libraries | NetworkX: `Graph([(1,1)])` → `[[1]]`, `DiGraph([(1,1)])` → `[[1]]` (FX-07 shows a loop with neighbours). JGraphT `MatrixExporter` pseudograph v1-v2, v3-v1, v1-v1 → triplets `1 2 1 / 1 3 1 / 1 1 2 / 2 1 1 / 3 1 1` (diagonal **2**, "count loops twice"). That code path also runs for directed graphs (untested). JGraphT CSV MATRIX export of J-FX writes **1** at (5,5). igraph undirected 5-vertex fixture with loop 2-2: LOOPS_ONCE → diagonal 1, LOOPS_TWICE → diagonal 2 (FX-08). **Grafluent decision:** the bit matrix stores 1. Any `[[Int]]` export of a *directed* matrix must write 1 | nx:TS:190-210; jgt:ME:51, 82-96; jgrapht-io main MatrixExporter.java:186-188; jgt:CE:110-115; ig:igraph_get_adjacency.out (upper/lower/both blocks) |
| AM-L05 | Row sum is out-degree, column sum is in-degree, **including** the loop | NetworkX notes that for undirected graphs row sum ≠ degree when loops exist (diagonal 1, degree 2). For a directed bit matrix there is no ambiguity. Swift: for every fixture, `outDegree(v) == rows[v].count(true)` and `inDegree(v) == column(v).count(true)` | nx:CM:973-985, 706-712 |
| AM-L06 | Reading a diagonal entry into a loop count | igraph directed: "loops twice (treated as loops once)", so diagonal 4 gives 4 loops whether ONCE or TWICE. Undirected LOOPS_TWICE: diagonal 4 gives 2 loops, and an **odd** diagonal (1) is `IGRAPH_EINVAL`. Swift: a directed bit matrix never halves the diagonal: `[[1]]` → exactly 1 loop | ig:igraph_adjacency.c (odd-diagonal case), .out (directed blocks) |
| AM-L07 | gonum forbids loops and stores `self` on the diagonal | `NewDirectedMatrix(n, init, self, absent)` fills the diagonal with `self`. `From`/`To` skip the diagonal. `RemoveEdge(u,u)` silently overwrites `self` with `absent` (a bug class: diagonal sentinels drift). Not applicable to Grafluent (loops are real edges), but test that `remove(edge: (v,v))` on a loopless v is a no-op that leaves `edgeCount` unchanged | gn:simple/dense_directed_matrix.go:39-56, 101-121, 182-190, 230-252 |
| AM-L08 | Complete digraph with loops vs without | LEMON `FullDigraph(n)` has n² arcs (loops included). `FullGraph(n)` has n(n-1)/2 edges (no loops). gonum fully-passable has n(n-1). Swift: `AdjacencyMatrix.complete(n, includingLoops:)` (if offered) → n² or n(n-1). n=7 → 49 or 42 | lemon:lemon/full_graph.h:155-157; lemon:test/graph_test.cc:281-291, 581-582; gn:simple/densegraph_test.go:635-661 |

---

## 8. Successors and predecessors as row and column scans

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-N01 | Successors = row scan, in ascending column order | petgraph `neighbors(a)` iterates columns 0..capacity of row a (`Edges::on_columns`). Boost directed `out_edges` walks `m_matrix[u*n .. u*n+n]`. gonum `From` scans row u. Swift: FX-03 `successors(of: 0) == [1,2,3,5]` (input order was 5,2,3,1: the result is **sorted**, not insertion order) | pg:MG:622-628, 936-988; bgl:AMH:684-703; gn:simple/dense_directed_matrix.go:101-121 |
| AM-N02 | Predecessors = column scan, ascending row order | petgraph `neighbors_directed(a, Incoming)` uses `Edges::on_rows` (stride n). Boost `in_edges` starts at `m_matrix.begin() + u` with stride n. gonum `To` scans column. Swift: FX-03 `predecessors(of: 3) == [0,1,2]`, `predecessors(of: 0) == [4]` | pg:MG:715-747; bgl:AMH:768-788; gn:simple/dense_directed_matrix.go:230-252 |
| AM-N03 | Per-vertex out and in counts on a mixed fixture | petgraph FX-03: Outgoing counts `[4,1,2,0,1,0,1]`, Incoming counts `[1,1,1,3,1,1,1]` | pg:MG:1860-1889 |
| AM-N04 | Simple out-neighbour checks | petgraph a→b, a→c: `neighbors(a) == {b,c}`, `neighbors(b) == []`, `neighbors(c) == []`. swift-algorithm-club a→b: `edgesFrom(a).count == 1`, `edgesFrom(b).count == 0`. With no edges, both 0 | pg:MG:1764-1781; sac:Graph/GraphTests/GraphTests.swift:57-72, 92-100 |
| AM-N05 | Dense DAG row lengths | swift-algorithm-club n=100 with i→j for all i<j: `outEdges(i).count == 100 - i - 1` and contains every j > i. Swift: also `predecessors(of: j) == Array(0..<j)` and `edgeCount == 4950` | sac:Graph/GraphTests/GraphTests.swift:102-125 |
| AM-N06 | Neighbour lists must stop at n, not at capacity | petgraph scans to `node_capacity` (≥ node_count, power of 2). Correct only because cells beyond n are always null. Swift: n=5 with backing words of 64 bits. Set all 25 bits. `successors(of: 4) == [0,1,2,3,4]` (no 5..63 from padding). After `appendVertex()`, `successors(of: 4)` is unchanged | pg:MG:832-889, 964-988 |
| AM-N07 | Boost adjacency_matrix and adjacency_list agree vertex by vertex | Boost FX-02: for each vertex, `adjacent_vertices`, `out_edges` targets and `in_edges` sequences match an `adjacency_list<setS>` (sorted). Swift: `successors(of:)` and `predecessors(of:)` equal those of the Grafluent adjacency list built from the same edges, sorted | bgl:AMT:118-160, 260-271 |

---

## 9. Degree

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-D01 | `outDegree` = row popcount, `inDegree` = column popcount, `degree` = sum | Boost: `out_degree` counts `out_edges` (O(n)), `in_degree` counts `in_edges`, directed `degree = in + out`. Swift on FX-02 (n=24, 43 arcs): out `[0,1,2,2,2,1,1,2,2,2,3,3,3,3,2,2,2,1,1,2,2,2,1,1]`, in `[2,2,1,1,3,2,2,0,3,1,2,2,2,2,1,3,1,2,2,3,1,1,2,2]` | bgl:AMH:729-743, 812-833; bgl:AMT:44-117 |
| AM-D02 | Handshake: Σ outDegree = Σ inDegree = edgeCount | Holds for every fixture. FX-01 7, FX-02 43, FX-03 9, J-FX 10 (out `[2,0,2,1,5]`, in `[2,2,2,2,2]`) | jgt:CE:384-408 |
| AM-D03 | Complete-graph degrees | gonum fully passable undirected n=5 → degree 4 each. LEMON FullDigraph(8) → out 8, in 8. Swift: all-ones n=8 → out 8, in 8, degree 16 | gn:simple/densegraph_test.go:565-585; lemon:test/digraph_test.cc:505-540 |
| AM-D04 | Undirected degree in Boost's matrix counts a loop **once** | Boost undirected `degree == out_degree`, and the out-edge iterator visits each column once. So a loop on u adds 1, unlike adjacency_list (vecS) which adds 2 (see the list catalog, Q-12). Only relevant if Grafluent later adds `UndirectedAdjacencyMatrix` | bgl:AMH:836-844, 230-282 |

---

## 10. Equality, hashing, Codable, description

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-Q01 | No reference library defines `==` on its matrix graph | petgraph `MatrixGraph` derives only `Clone`. Boost and gonum have none. Equality is ours to define: same `vertexCount` **and** same bits | pg:MG:233 |
| AM-Q02 | Equality must include the dimension, not just the words | swift-algorithm-club BitSet `==` compares `words` only. Two all-zero sets of sizes 60 and 64 compare **equal** (bug). Swift: `AdjacencyMatrix(vertexCount: 3) != AdjacencyMatrix(vertexCount: 4)` and `[] != [[0]]`. Their hashes should differ too (not required, but check they are not trivially equal on a small corpus) | sac:Bit Set/BitSet.playground/Sources/BitSet.swift:151-153 |
| AM-Q03 | Equality and hash ignore capacity and history | petgraph capacity is a power of 2 ≥ n. Swift: build FX-01 (a) directly with n=6, (b) from n=0 via 6× `appendVertex()`, (c) n=6 with extra edges inserted then removed. All `==`, same `hashValue`, same `Set` bucket. Use swift-collections' `checkHashable(equivalenceClasses:)` pattern (BitArray `test_Hashable` classes: `[[]]`, `[[false],[false]]`, `[[false,false,true]…]`) | sc:BA:417-428 |
| AM-Q04 | Codable round trip and malformed payload rejection | swift-collections `BitArray` encodes `[count, word0, word1, …]`: `[]` → `[0]`, `[1,1,0,1]` → `[4, 11]`, 145 ones → `[145, max, max, 2^17-1]`. Decoding rejects: a scalar (`42`), an empty array, `[1]` (missing word), `[1,0,0,0]` (too many words), `[100, 0]` (too few words), and **`[16, UInt64.max]` (bits set beyond count)**. fixedbitset serde: `{"length":10,"data":[76,1,0,…]}` for bits 2,3,6,8. Swift: round-trip FX-01..FX-03 and n ∈ {0,1,63,64,65,129}. Reject a payload whose bit count ≠ n², whose padding bits are set, or whose n is negative | sc:BA:430-510; fbs:T:1281-1291 |
| AM-Q05 | Description format | swift-algorithm-club description for a→b (1.0), b→c (2.0): exactly `"  ø   1.0   ø  \n  ø    ø   2.0 \n  ø    ø    ø  "` with **no trailing newline**. igraph and the petgraph iso fixtures print rows of space-separated 0/1. Bitset displays disagree on bit order: fixedbitset `{2,4}` of length 8 → `"00101000"` (index order, LSB first), but swift-collections `BitArray [F,F,F,F,T,T,T,F]` → `"<01110000>"` (**reversed**, MSB first). Swift: `AdjacencyMatrix` description is row-major with column 0 leftmost. FX-01 → `"000000\n001001\n101000\n000010\n000100\n100000"`. Decide and test the trailing newline and the empty case (`""`) | sac:Graph/GraphTests/GraphTests.swift:13-26; fbs:T:1266-1279; sc:BA:980-1000 |
| AM-Q06 | Value semantics (CoW) | (List catalog §6 covers this in general.) Matrix-specific: `var b = a; b[0,0].toggle()` must not change `a`, including when `a` uses inline storage for n ≤ 8 (if that optimisation exists) and when `b.appendVertex()` reallocates. Use the swift-collections `withHiddenCopies(if: shared, of:)` pattern from `test_toggleAll_range` | sc:BA:928-945 |

---

## 11. Conversion between matrix and list representations (round trips)

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-X01 | Graph → matrix → graph keeps vertices and edges | NetworkX round trips: barbell_graph(10,3) (23 vertices, 94 edges), directed cycle_graph(10), weighted C4. Each runs through `from_numpy_array`, `to_networkx_graph` and `Graph(A)`, and also through scipy csr, coo, csc and dense. Swift: `AdjacencyMatrix(adjacencyList)` then back to `AdjacencyList` equals the original, for every fixture | nx:TN:12-61; nx:TS:69-87 |
| AM-X02 | Matrix ↔ edge list: every structure agrees with the matrix | petgraph runs the same TEST_CASES (FX-04) through Graph, StableGraph, GraphMap, MatrixGraph, Csr and adj::List, checking `is_adjacent` against the edge list. Swift: parameterised `@Test(arguments: fixtures)`: `AdjacencyMatrix(vertexCount:edges:).edges.sorted() == edges.sorted().uniqued()` | pg:AMT:35-178 |
| AM-X03 | Matrix → graph6 → matrix (bit-packed upper triangle, undirected) | petgraph `UnMatrix` graph6 round trip on 20 fixtures: K1 `@`, empty n=2 `A?`, K2 `A_`, K3 `Bw`, K5 `D~{`, K7 `F~~~w`, K10 `I~~~~~~~w`, Petersen `IheA@GUAo`, the 20-vertex "flower", and **orders 62 and 63** (graph6's header switches from 1 byte to 4 at n = 63). Decoded `node_count == order`, `edge_count == size`, and re-encoding gives the identical string. Only relevant if Grafluent adds graph6 I/O, but the n=62/63 fixtures double as large word-boundary graphs | pg:G6:163-195, 231-270 |
| AM-X04 | Vertex order (nodelist) defines rows | NetworkX DiGraph 1→2→3→1 with nodelist [3,2,1] → `[[0,0,1],[1,0,0],[0,1,0]]`. A nodelist subset gives the induced submatrix (P4 with nodelist [0,1,2] equals P3). A duplicate in nodelist raises, and so does a non-node. With n=5, nodelist range(6) or range(4) raises `ValueError`. Swift: `AdjacencyMatrix(list, order: [3,2,1])` (if offered) or the induced-subgraph API. Duplicate or unknown vertices trap | nx:TS:180-188; nx:TN:63-81, 408-414; nx:TS:89-104; nx:GM:281-282 |
| AM-X05 | Header ids map rows by label, not position | JGraphT CSV import with rows in the order C, D, B, A, E still yields the same 10 arcs of J-FX. A tab separator with a quoted id containing a tab works. A blank header id → `ImportException`. Only relevant for labelled import | jgt:CI:464-518, 592-616, 643-680 |
| AM-X06 | Weighted cells: `0.0` is an edge in JGraphT, absent in NetworkX | JGraphT weighted import: the cell D→C = `"0.0"` gives `containsEdge("4","3")` with weight 0. Only the token `"0"` means absent. NetworkX: nonzero means edge, unless a `nonedge` sentinel (NaN or -99) is passed, in which case 0.0 is an edge. Grafluent's `init(rows: [[Int]])` treats only 1 as edge (AM-C10). A future `init(rows: [[Bool]])` is unambiguous | jgt:CI:521-562; nx:TN:535-552 |
| AM-X07 | Parallel edges collapse when going list → bit matrix | NetworkX `adjacency_matrix(MultiGraph)` with an extra (0,1) gives A[0][1] = 2. A bit matrix must collapse it to 1. JGraphT `MatrixExporter` on a directed multigraph v1→v2, v3→v1 ×2 → `1 2 1 / 3 1 2`. Swift: `AdjacencyMatrix(multigraphWithParallelArcs)` has `edgeCount == distinct (u,v) pairs`. Converting back loses multiplicity (document it as lossy) | nx:GM:96-105, 279; jgt:ME:54, 100-115 |

---

## 12. Symmetric matrices vs undirected graphs

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-U01 | Undirected export is symmetric | NetworkX Graph edge (0,1) with weight 1+2j → `[[0,1+2j],[1+2j,0]]`; the DiGraph version → `[[0,1+2j],[0,0]]`. igraph "both" export is symmetric (FX-08). JGraphT `MatrixExporter` on undirected emits both (i,j) and (j,i). Swift: `AdjacencyMatrix(undirected: list)` (if offered) → `isSymmetric == true` and `m == m.transposed()` | nx:TN:250-277; ig:igraph_get_adjacency.out; jgt:ME:82-96 |
| AM-U02 | A symmetric matrix read as undirected gives **one** edge per pair, not two | NetworkX `[[0,1],[1,0]]` into a MultiGraph → a single (0,1) with weight 1. scipy `[[0,3,2],[3,0,1],[2,1,0]]` → 3 edges. Swift: a symmetric `AdjacencyMatrix` viewed as undirected has `edgeCount / 2` off-diagonal edges plus the diagonal count. FX-05 (Petersen) → 30 arcs, 15 undirected edges | nx:TN:196-205; nx:TS:252-281 |
| AM-U03 | Non-symmetric input under an undirected mode | igraph `IGRAPH_ADJ_UNDIRECTED` with a non-symmetric matrix → `IGRAPH_EINVAL`. NetworkX simple Graph silently ORs A[i][j] with A[j][i] (the later entry sets the weight). NetworkX MultiGraph reads **only the upper triangle**, so a lower-only entry `[[0,0],[1,0]]` is dropped. igraph offers MAX, MIN, PLUS, UPPER and LOWER modes. **Grafluent decision:** any `undirectedView` or `symmetrised()` should be explicit (`m.union(m.transposed())`), and a checked initializer should reject asymmetry | ig:igraph_adjacency.c (non-symmetric case and MAX/MIN/PLUS/UPPER/LOWER blocks); nx:CM:1211-1214, 1343-1344 |
| AM-U04 | Symmetric ⇒ in and out are equal | petgraph undirected a-b, a-c: `neighbors(b) == [a]`, `neighbors(c) == [a]`. gonum undirected add 0-2 is visible from both ends. swift-algorithm-club undirected edge = two arcs. Swift: for symmetric fixtures (FX-04 undirected cases, FX-05), `successors(of: v) == predecessors(of: v)` for every v | pg:MG:1783-1800; gn:simple/densegraph_test.go:620-633; sac:Graph/GraphTests/GraphTests.swift:74-90 |
| AM-U05 | Undirected storage halves memory (lower triangle) | petgraph `UnMatrix` stores the lower triangle at `row*(row+1)/2 + col`. Boost undirected stores n(n+1)/2 entries. Their tests: undirected `edges(0).count() == 5` on FX-03 edges (0's neighbours 1,2,3,4,5) and `edges(6).count() == 1` (the loop is listed once). Only relevant for a future undirected bit matrix | pg:MG:1066-1086, 1891-1912; bgl:AMH:557-559, 631-655 |

---

## 13. Transpose = reversed graph

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-T01 | Reverse swaps every arc | NetworkX `DiGraph([(0,1),(1,2)]).reverse()` has edges `[(1,0),(2,1)]`. Removing from the reversed copy leaves the original unchanged. igraph `reverse_edges` on 0→1, 1→2, 2→3, 3→1, 1→4 (FX-09): reversing all arcs gives 1→0, 2→1, 3→2, 1→3, 4→1. Swift: `m.transposed()` on FX-09 equals `AdjacencyMatrix(vertexCount: 5, edges: [(1,0),(2,1),(3,2),(1,3),(4,1)])` | networkx/classes/tests/test_digraph.py:109-122; ig:igraph_reverse_edges.c |
| AM-T02 | Transpose swaps successors with predecessors and outDegree with inDegree | (Derived, not tested directly by any library.) Swift: ∀v: `t.successors(of: v) == m.predecessors(of: v)` and `t.outDegree(v) == m.inDegree(v)`. Run on FX-01..FX-03 and random matrices | — |
| AM-T03 | Transpose is an involution and keeps the diagonal | Swift: `m.transposed().transposed() == m`. The diagonal (loops) is unchanged. `edgeCount` is preserved. A symmetric matrix is a fixed point (FX-05) | — |
| AM-T04 | Transpose across word boundaries | Bit-packed transposes are usually done blockwise (8×8 or 64×64), so bugs hide at partial blocks. Swift: n ∈ {1,7,8,9,63,64,65,127,128,129}, random fill with a fixed seed: `transposed()[i,j] == m[j,i]` for all i,j, and the padding bits stay zero (AM-W03) | — |

---

## 14. Matrix powers, Boolean products, transitive closure

No library tests powers *on its matrix-graph type*. NetworkX tests them through `number_of_walks` (integer A^k), and Warshall-style closure through `transitive_closure`. For a Boolean matrix, "A^k[i][j] = 1 iff a walk of length k exists".

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-P01 | Directed 3-cycle cubed is the identity | 0→1→2→0, k=3 → walks matrix I₃. Boolean: `m.power(3) == identity(3)` | nx:TW:14-18 |
| AM-P02 | Directed 3-cycle squared is the reverse cycle | A→B→C→A, k=2 → rows A=(0,0,1), B=(1,0,0), C=(0,1,0). Boolean: `m.power(2) == m.transposed()` for a directed 3-cycle | nx:TW:26-34 |
| AM-P03 | Undirected C3 cubed (integer) | `[[2,3,3],[3,2,3],[3,3,2]]`. Boolean: all ones (every entry > 0) | nx:TW:20-24 |
| AM-P04 | k = 0 is the identity, k < 0 is an error, weights are ignored | `number_of_walks(G, 0)` → I. k=-1 → `ValueError`. C3 with (1,2) weighted 5 gives the same result. Swift: `power(0) == identity(n)` (including n=0). `power(-1)` traps | nx:TW:36-53 |
| AM-P05 | Transitive closure (Boolean Warshall) | Path 1→2→3→4 → its 6 reachable pairs and no loops. The 3-cycle → all 9 pairs **including loops**, even with reflexive=False, because each vertex reaches itself. reflexive=True adds (v,v) for every vertex. Swift: `m.transitiveClosure()` on path P4 → upper-strict triangle (6 bits). On C3 → all ones | networkx/algorithms/tests/test_dag.py:325-337, 369-391 |
| AM-P06 | Boolean product is OR-of-ANDs, not integer multiply | (Derived.) Swift: for random A, B (n ∈ {1,63,64,65}), `(A*B)[i,j] == (0..<n).contains { A[i,k] && B[k,j] }`. `A * identity == A`. `zero * A == zero`. Exercise with FX-02 squared: `successors(of: 2)` in A² = successors of {5,10} = {14, 8,15,19} | — |

---

## 15. Word-boundary cases for bit-packed storage

No graph library tests 63/64/65-vertex matrices. The cases below are adapted from bitset tests (swift-collections `BitArray`, fixedbitset, swift-algorithm-club `BitSet`) and from petgraph's graph6 fixtures at n=62/63. With row-major n×n bits there are **two** boundary families: n itself (row length vs word size, if rows are word-aligned), and n² (total bits, if rows are packed contiguously). n=8 gives 64 bits total, and n=65 rows straddle words.

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-W01 | Standard boundary sizes | swift-collections uses counts `[0, 1, 2, 13, 63, 64, 65, 127, 128, 129, 1000]` (repeating), `[0,1,2,13,64,65,127,128,129]` (collection conformance) and `[5,63,64,65,100,1000]` (BitSet conversion). Swift: run construction, subscript, successors, predecessors, degrees, `==`, Codable and description over n ∈ {0,1,2,7,8,9,13,31,32,33,63,64,65,127,128,129} | sc:BA:62-112, 262-291 |
| AM-W02 | Last cell of each row and first cell of the next row are independent | (Classic stride bug.) Swift: for each n in AM-W01, set only `m[i, n-1]` for one i and check `m[i+1, 0] == false`, `successors(of: i) == [n-1]`, `predecessors(of: n-1) == [i]`, `edgeCount == 1`. Repeat with only `m[i+1, 0]` set | — |
| AM-W03 | Padding bits never leak (complement or all-ones) | swift-algorithm-club `~` on sizes 4 and 8: complement cardinality = size − cardinality, because `clearUnusedBits` runs after `~`. swift-collections `test_bitwiseComplement` and `toggleAll` over 0..<512. Swift: for each n, an all-ones matrix (or a `complemented()` zero matrix, if offered) has `edgeCount == n*n`, `outDegree(v) == n` (no phantom columns ≥ n), and equals the literal of all ones | sac:Bit Set/BitSet.playground/Sources/BitSet.swift:55-57, 220; sc:BA:897-926 |
| AM-W04 | Bit at index 64 and 65 lives in the second word | swift-algorithm-club BitSet size 66: bit 65 in word 1; all0/all1/any1 transitions. fixedbitset grow(48→72), then `set(64)`. Swift: n=9 (81 bits): `m[7,1]` is bit 64 → set it, check `successors(of: 7) == [1]`. n=65: `m[0,64]`, `m[1,0]` and `m[64,64]` are independent | sac:Bit Set/BitSet.playground/Contents.swift:69-88; fbs:T:85-100 |
| AM-W05 | Construction from raw words masks excess bits | fixedbitset `with_capacity_and_blocks(1, [0xff])` → only bit 0 is set. `(50, [8, 0])` → only bit 3. `(500, [8, 0])` grows and `insert(400)` works. swift-collections decode `[16, UInt64.max]` → **throws**. Swift: any raw-storage initializer or decoder rejects or masks bits ≥ n² (or ≥ n within a row) | fbs:T:40-84; sc:BA:460-510 |
| AM-W06 | Codable payloads at boundaries | swift-collections: 145 ones → `[145, max, max, 2^17-1]`. 343 zeros + 1 → `[344, 0,0,0,0,0, 1<<23]`. Swift: encode the all-ones matrix for n ∈ {8 (64 bits), 9 (81), 11 (121), 12 (144)} and n ∈ {63,64,65}, decode, compare `==` | sc:BA:430-458 |
| AM-W07 | Growth across a boundary (`appendVertex`) | See AM-G06. Also n=63 → 64 → 65 → 128 → 129 by repeated `appendVertex()` from 0, checking a diagonal pattern `m[i,i] = true` stays exact (`edgeCount == n`, `successors(of: i) == [i]`) after every append | fbs:T:85-100 |
| AM-W08 | graph6 boundary fixtures | petgraph graph6 n=62 and n=63 fixtures (header switches at 63) give exact edge lists. Reuse them as large known graphs: build, check `edgeCount`, symmetric, round-trip | pg:G6:261-270 |

---

## 16. Large sparse vs dense cases

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| AM-Z01 | Sparse large graph | Boost FX-02 (24 vertices, 43 arcs). gonum n=100 random 0-4 out-edges per node. Swift: n=1000 with a 1000-arc random sparse set (seeded): `edgeCount == set.count`, every cell checked against the set via `successors(of:)` (1000 row scans) | bgl:AMT:44-117; gn:simple/densegraph_test.go:121-138 |
| AM-Z02 | Dense large graph | swift-algorithm-club n=100 upper-triangular DAG (4950 arcs). gonum n=15 complete (210). LEMON n=8 complete with loops (64). Swift: n=129 all-ones → `edgeCount == 16641`, every degree 258. Remove the diagonal → 16512 | sac:Graph/GraphTests/GraphTests.swift:102-125; gn:simple/densegraph_test.go:635-661; lemon:test/digraph_test.cc:561 |
| AM-Z03 | Growth is amortised | petgraph doubles capacity (`next_power_of_two`, min 4). swift-algorithm-club re-copies every row per vertex. Swift (performance or `.timeLimit` test): 4096 `appendVertex()` calls from 0 finish within a generous bound, and the bits set along the way survive | pg:MG:1023-1037; sac:Graph/Graph/AdjacencyMatrixGraph.swift:43-66 |
| AM-Z04 | Edge enumeration order and count on dense input | petgraph `edge_references` row-major over capacity: FX-03 → 9 references. Undirected → 9 (lower triangle, no duplicates). Swift: `edges` is row-major `(0,1),(0,2),(0,3),(0,5),(1,3),(2,3),(2,4),(4,0),(6,6)` for FX-03 | pg:MG:1926-1958, 850-889 |
| AM-Z05 | Model-based random test | (Pattern from the list catalog §10.) Swift: 1000 random operations (`insert`, `remove`, subscript set, `appendVertex`, `removeAllEdges`) on n starting at 0-3, against a `Set<Edge>` + n model. After each step: `edgeCount`, `contains`, degrees, `==` with a freshly built matrix, `hashValue` equality. This would have caught petgraph AM-V02 and AM-R03 | gn:testgraph/testgraph.go:1932-1975 |

---

## 17. Known fixture graphs with adjacency matrices

Rows are written as 0/1 strings, row = source, column 0 leftmost.

| ID | Fixture | n, E | Matrix rows | Degrees | Source |
|---|---|---|---|---|---|
| FX-01 | Boost example, directed A..F: B→C, B→F, C→A, **C→C**, D→E, E→D, F→A | 6, 7 | `000000 / 001001 / 101000 / 000010 / 000100 / 100000` | out `[0,2,2,1,1,1]`, in `[2,0,2,1,1,1]` | bgl:EX |
| FX-01u | Same example, undirected: B-C, B-F, C-A, D-E, F-A | 6, 5 | `001001 / 001001 / 110000 / 000010 / 000100 / 110000` | degree `[2,2,2,1,1,2]` | bgl:EX |
| FX-02 | Boost 24-vertex test digraph: (1,2) (2,10) (2,5) (3,10) (3,0) (4,5) (4,0) (5,14) (6,3) (7,17) (7,11) (8,17) (8,1) (9,11) (9,1) (10,19) (10,15) (10,8) (11,19) (11,15) (11,4) (12,19) (12,8) (12,4) (13,15) (13,8) (13,4) (14,22) (14,12) (15,22) (15,6) (16,12) (16,6) (17,20) (18,9) (19,23) (19,18) (20,23) (20,13) (21,18) (21,13) (22,21) (23,16) | 24, 43 | (24×24; compute from the list) | see AM-D01. Vertex 7 has in 0; vertex 0 has out 0 | bgl:AMT:50-117 |
| FX-03 | petgraph `test_edges_directed`: (0,5) (0,2) (0,3) (0,1) (1,3) (2,3) (2,4) (4,0) (6,6) | 7, 9 | `0111010 / 0001000 / 0001100 / 0000000 / 1000000 / 0000000 / 0000001` | out `[4,1,2,0,1,0,1]`, in `[1,1,1,3,1,1,1]` | pg:MG:1860-1889 |
| FX-04 | petgraph TEST_CASES (10): (0,[]), (1,[]), (2,[]), (2,[(0,0)]) loop; (5,[(0,2),(0,4),(1,3),(3,4)]); (6,[(2,3)]); (9,[(1,4),(2,8),(3,7),(4,8),(5,8)]); K2 (2,[(0,1)]); K7 (21 edges); Petersen | various | n=5 case: `00101 / 00010 / 00000 / 00001 / 00000`. n=9 case: rows 1→4, 2→8, 3→7, 4→8, 5→8 | n=5: out `[2,1,0,1,0]`, in `[0,0,1,1,2]` | pg:AMT:181-201 |
| FX-05 | Petersen (undirected, as a symmetric matrix): (0,1) (0,4) (0,5) (1,2) (1,6) (2,3) (2,7) (3,4) (3,8) (4,9) (5,7) (5,8) (6,8) (6,9) (7,9) | 10, 15 edges = 30 arcs | `0100110000 / 1010001000 / 0101000100 / 0010100010 / 1001000001 / 1000000110 / 0100000011 / 0010010001 / 0001011000 / 0000101100` | 3-regular | pg:AMT:199-200; pg:G6:255 (graph6 `IheA@GUAo`) |
| FX-06 | NetworkX `havel_hakimi_graph([3,2,2,1,0])` (undirected) | 5, 4 edges | `01110 / 10100 / 11000 / 10000 / 00000` | `[3,2,2,1,0]`, vertex 4 isolated | nx:GM:8-27, 83-89 |
| FX-07 | NetworkX loop fixtures: `Graph([(1,1),(2,3),(3,4)])` nodelist [2,3,4] → `[[0,1,0],[1,0,1],[0,1,0]]`; `DiGraph` same → `[[0,1,0],[0,0,1],[0,0,0]]`; `[[1]]` for the loop alone | 3 | as shown | — | nx:TS:190-210 |
| FX-08 | igraph undirected: 0-1, 1-2, 2-3, 3-4, 4-0, 0-3, **2-2**, 0-1 (parallel) | 5, 8 | "both", loops once: `0 2 0 1 1 / 2 0 1 0 0 / 0 1 1 1 0 / 1 0 1 0 1 / 1 0 0 1 0`. Loops twice: (2,2) = 2. Upper and lower variants are triangular | — | ig:igraph_get_adjacency.c:31, .out |
| FX-09 | igraph reverse fixture: 0→1, 1→2, 2→3, 3→1, 1→4 | 5, 5 | `01000 / 00101 / 00010 / 01000 / 00000` | out `[1,2,1,1,0]`, in `[0,2,1,1,1]` | ig:igraph_reverse_edges.c |
| FX-10 | JGraphT CSV J-FX (1-based ids 1..5): 1→2, 1→3, 3→1, 3→4, 4→5, 5→1, 5→2, 5→3, 5→4, **5→5** | 5, 10 | `01100 / 00000 / 10010 / 00001 / 11111` | out `[2,0,2,1,5]`, in `[2,2,2,2,2]` | jgt:CE:384-408; jgt:CI:347-382 |
| FX-11 | petgraph iso fixtures: G3_1 path `010/101/010` vs G3_2 triangle `011/101/110` (not isomorphic); S1 `111/101/100` vs S2 `111/011/100` (differ only in loops); G8_1/G8_2 8×8 | 3 or 8 | as shown | — | pg:tests/iso.rs:165-200 |
| FX-12 | NetworkX path from the superdiagonal: `diag(ones(4), k=1)` | 5, 4 | `01000 / 00100 / 00010 / 00001 / 00000` | out `[1,1,1,1,0]`, in `[0,1,1,1,1]` | nx:TN:399-406 |
| FX-13 | Complete digraphs: LEMON FullDigraph(8) with loops (64 arcs); gonum n=15 without loops (210); swift-algorithm-club n=100 strict upper triangle (4950) | — | all ones / off-diagonal / strict upper | — | lemon:test/digraph_test.cc:561; gn:simple/densegraph_test.go:635-661; sac:Graph/GraphTests/GraphTests.swift:102-125 |

---

## 18. Licences and porting implications

| Library | Licence | Implication |
|---|---|---|
| petgraph, fixedbitset | MIT OR Apache-2.0 | Fixtures and test logic can be ported with attribution |
| Boost.Graph, LEMON | BSL-1.0 | Permissive; keep the notice if code is copied. Fixtures (edge lists) are facts |
| NetworkX, gonum | BSD-3-Clause | Permissive with attribution |
| swift-algorithm-club | MIT | Permissive |
| swift-collections | Apache-2.0 with Runtime Library Exception | Same licence family as the Swift project; test helpers (`checkHashable`, `withEvery`, `withHiddenCopies`) can be adapted with the notice |
| JGraphT | EPL-2.0 OR LGPL-2.1-or-later | Weak copyleft. Re-derive tests from the described behaviour and fixtures; do not copy source |
| igraph | GPL-2.0-or-later | Strong copyleft. Use only as a behavioural reference (expected outputs and conventions); write the Swift tests from scratch |

Edge lists and small matrices are factual data and are safe to reuse as fixtures regardless of the source licence. Attribution in a `Tests/…/FIXTURES.md` is still good practice.
