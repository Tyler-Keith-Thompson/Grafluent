# Test catalog: adjacency-list graph container

Test cases taken from NetworkX, petgraph, Boost.Graph (BGL) and JGraphT, grouped by behavior and deduplicated across libraries. A final section covers the swift-collections testing techniques worth copying, followed by licensing.

Sources (shallow clones, Oct 2026): networkx `6da4704`, petgraph `a4d94bd`, boostorg/graph `1ee1a99`, jgrapht `63976aa`, swift-collections `3b69ced`. Per-library raw notes are in `notes-{networkx,petgraph,boost,jgrapht,swift-collections}.md` next to this file.

**Path prefixes used in citations**
| Prefix | Expands to |
|---|---|
| `nx:` | `networkx/networkx/classes/tests/` (TG = test_graph.py, TDG = test_digraph.py, TMG = test_multigraph.py, TMDG = test_multidigraph.py, TF = test_function.py, TRV = test_reportviews.py, HT = historical_tests.py, TDGH = test_digraph_historical.py) |
| `nxsrc:` | `networkx/networkx/classes/` (implementation) |
| `pg:` | `petgraph/crates/petgraph/` (tests in `tests/`, inline tests in `src/csr.rs`) |
| `bgl:` | `graph/` (tests in `test/`, header `include/boost/graph/detail/adjacency_list.hpp` = "hdr") |
| `jgt:` | `jgrapht/jgrapht-core/src/` (`test/java/org/jgrapht/...`, `main/java/org/jgrapht/...`) |
| `sc:` | `swift-collections/` |

Case IDs (e.g. `C-03`) are stable so test names can refer to them. "Grafluent decision" marks a place where the libraries disagree, so our spec has to choose.

---

## 0. Cross-library convention matrix (read this first)

| Convention | NetworkX | petgraph | BGL adjacency_list | JGraphT |
|---|---|---|---|---|
| Simple vs multi | separate classes (Graph/MultiGraph) | `Graph` allows parallel edges; `GraphMap` does not; `Csr` rejects duplicates | type parameter: out-edge `setS` rejects parallel edges, `vecS/listS/multisetS` allow them | `GraphType` flags (Simple/Multi/Pseudo/Default) |
| Duplicate edge in simple graph | silent; attributes updated | `GraphMap.add_edge` is an upsert returning the old weight; `Csr.add_edge` returns `false` | `add_edge` returns `(existing, false)` | `addEdge` returns `null`/`false` |
| `add_edge` with an absent endpoint | auto-adds the vertex | `Graph`/`StableGraph`/`List`: panic (or `Err` from `try_add_edge`); `GraphMap`: auto-adds | vecS: grows the vertex vector to `max(u,v)+1` | throws `IllegalArgumentException` |
| Remove an absent vertex | `remove_node` raises; `remove_nodes_from` is silent | returns `None`/`false` | undefined behavior | returns `false` |
| Remove an absent edge | `remove_edge` raises; `remove_edges_from` is silent | returns `None` | silent no-op | returns `false`/`null` |
| `remove_vertex` removes incident edges | yes | yes | **no**: you must call `clear_vertex` first | yes |
| `remove_edge(u,v)` on parallel edges | removes the **last-added** one | by index only (one) | removes **all** of them | removes **one** |
| Undirected self-loop degree | 2 | 2 (test helper only; no `degree()` API) | **2 with vecS/listS/multisetS, 1 with setS** | 2 |
| Self-loop in neighbor list (undirected) | once | once | twice (vecS), once (setS) | `edgesOf` lists it once |
| Directed self-loop degree | in 1 + out 1 = 2 | n/a | in 1 + out 1 = 2 (bidirectionalS) | in 1 + out 1 = 2 |
| Undirected `inDegree`/`outDegree` | n/a (no in/out on Graph) | `Incoming == Outgoing == neighbors` | `in_degree == out_degree == degree` | `inDegreeOf == outDegreeOf == degreeOf` |
| Size counts a loop as | 1 | 1 | 1 | 1 |
| `==` on the graph | **none** (identity); helper `graphs_equal` | **none** (only `adj::List` derives it) | **none** | structural, order-insensitive, but edge-object identity matters |
| Copy | `copy()` gives independent structure with shared attribute values | deep `Clone` | deep value copy; `swap` = 3 copies | `clone()` gives deep structure with shared vertex and edge objects |
| Vertex iteration order | insertion (dict), not documented | `Graph`: index; `GraphMap`: insertion, then disturbed by `swap_remove` | vecS: index | insertion (LinkedHashMap), documented |
| Neighbor order | insertion | `Graph`/`StableGraph`: **reverse insertion (LIFO)**; `List`/`GraphMap`: insertion; `Csr`: sorted | vecS/listS: insertion; setS: sorted | insertion |

All four libraries count a loop **once** in edge count and **twice** in undirected degree, so the handshake lemma Σdeg = 2|E| holds. The one exception is BGL `setS`, which breaks it (verified empirically, see Q-12). Recommendation: loop counts 1 in size, 2 in undirected degree, 1 in-degree + 1 out-degree when directed, and the loop vertex appears **once** in the neighbor collection.

---

## 1. Construction

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| C-01 | Empty graph: every count is 0 and every view is empty | `Graph()`: `nodes == []`, `adj == {}`. petgraph `List::new()`: `node_count`, `node_bound`, `node_indices().count()`, `node_references().count()` are all 0. `StableGraph::new()`: `node_bound == node_count == 0`. BGL default CSR graph passes the full consistency battery | nx:TG:815-821, nx:HT:310-313; pg:tests/list.rs:35-54, pg:tests/stable_graph.rs:52-55; bgl:test/csr_graph_test.cpp:418-424 |
| C-02 | "Empty" means no **edges**, not no vertices | `is_empty(G)` is true for an empty graph, still true after `add_nodes_from(range(5))`, false after `add_edges_from([(1,2),(3,4)])`, for all 4 graph classes | nx:TF:936-943 |
| C-03 | `init(vertexCount:)` / n isolated vertices | BGL `Graph g(5)`: V=5, E=0. JGraphT `EmptyGraphGenerator(10)`: V=10, E=0. NetworkX `empty_graph(n)` | bgl:test/adj_list_loops.cpp:13-22; jgt:test/.../generate/GraphGeneratorTest.java:47-57 |
| C-04 | From an edge list (undirected K4) | `[(0,1),(0,2),(0,3),(1,2),(1,3),(2,3)]` → V=4, E=6, every vertex has 3 neighbors. Same fixture for `GraphMap` | pg:tests/graph.rs:1785-1797; pg:tests/graphmap.rs:232-256 |
| C-05 | From an edge list, BGL "house + lollipop" graph (fixture FX-06) | 6 vertices; `(5,3),(3,4),(3,2),(4,0),(4,1),(2,1),(1,0)` → V=6, E=7, `edge(5,3)` exists, `edge(5,0)` does not | bgl:test/test_graph.hpp:33-45; bgl:test/test_construction.hpp:97-113; bgl:test/test_iteration.hpp:28,49 |
| C-06 | From an edge list, duplicates collapse in a simple graph and a loop is kept | `Graph([(1,2),(1,2),(2,2)]).edges == [(1,2),(2,2)]` (size 2). Undirected `add_edge(0,1)` then `add_edge(1,0)` gives 1 edge | nx notes "verified"; nx:HT:153-158 |
| C-07 | From an edge list, duplicates kept as parallel edges in a multigraph | `MultiDiGraph([(0,1),(0,1)])` has 2 arcs. petgraph `Graph` keeps a duplicated `(8,6)` as parallel edges | nx:TMDG:231-237; pg:tests/stable_graph.rs:161-196, pg:tests/list.rs:107-135 |
| C-08 | From an adjacency mapping: symmetric undirected input gives **one** edge | `Graph({1:[2], 2:[1]})` → adj `{1:{2},2:{1}}`, size 1 | nx:TG:682-685 |
| C-09 | From an adjacency mapping: directed input gives 2 arcs | `DiGraph({1:[2],2:[1]})` → succ == pred == `{1:{2},2:{1}}`, size 2 | nx:TDG:229-234 |
| C-10 | From an adjacency mapping into a multigraph: still deduplicated (surprising) | `MultiGraph({1:[2],2:[1]})` → `{1:{2:{0:{}}},2:{1:{0:{}}}}`, **1 edge**. Grafluent decision: does a mapping list arcs (directed) or edges? | nx:TMG:197-201 |
| C-11 | Mapping with a self-loop, a duplicate and an isolated vertex (fixture FX-05) | `Graph({0:[1,2,3], 1:[1,2,0], 4:[]})` → V=5, E=5 `{(0,1),(0,2),(0,3),(1,1),(1,2)}`, degrees `{0:3,1:4,2:2,3:1,4:0}`. As a `DiGraph`: 6 arcs, in `{0:1,1:2,2:2,3:1,4:0}`, out `{0:3,1:3,2:0,3:0,4:0}` | nx:TF:15-24, 244, 247 |
| C-12 | Isolated vertex survives construction from mixed input | JGraphT builder `.addVertex(v1).addEdge(v2,v3)`, then `addEdge(v1,v4)` → V=4, E=2. The degree-sequence fixture's isolated vertex has degree 0 | jgt:test/.../graph/builder/GraphBuilderTest.java:83-98; pg:tests/graph.rs:1943-1979 |
| C-13 | Builder auto-adds endpoints | `.addEdge(v1,v2).addEdgeChain(v3,v4,v5,v6).addEdge(v7,v8,10.0)...` → V=8, E=7 | jgt:GraphBuilderTest.java:55-80 |
| C-14 | Dense-index construction implies filler vertices (sparse ids) | CSR `from_sorted_edges([(0,1),(0,2),(1,0),(1,1),(2,2),(2,4)])` → **5** vertices (vertex 3 is isolated, implied by max id 4). BGL vecS `add_edge(2,0)` on an empty graph → 3 vertices; `add_edge(1_000_000,0)` → 1,000,001 vertices (verified). Grafluent decision: hashed vertex keys avoid this entirely | pg:src/csr.rs:978-988; bgl:test/delete_edge.cpp:47-62, hdr:2263-2264 |
| C-15 | Construction is independent of input order | Unsorted `(5,0),(3,2),(4,1),(4,0),(0,2),(5,2)`, n=6, built 3 ways (unsorted, multi-pass, incremental in 2 batches) → all structurally equal | bgl:test/csr_graph_test.cpp:434-497 |
| C-16 | Construction from an iterator round-trips | CSR `edge_references()` fed back into `from_sorted_edges` gives identical arrays. Rebuilding from sorted, reverse-sorted and shuffled source/target arrays gives a graph equal to the original | pg:src/csr.rs:1158-1184; bgl:test/csr_graph_test.cpp:220-290 |
| C-17 | Precondition on construction input: sorted/unique (CSR only) | `[(0,1),(1,0),(0,2)]` → `Err(EdgesNotSorted)`. Applies only if we offer an unchecked fast-path initializer | pg:src/csr.rs:963-976 |
| C-18 | Invalid endpoint values rejected | `None` as a node raises `ValueError` in `add_node`, `add_nodes_from`, `add_edge` and `add_edges_from`. Edge tuple of wrong arity → `NetworkXError`/`TypeError`. (In Swift the type system covers this; skip) | nx:TG:47-56, 777-800 |
| C-19 | Copy-construct from another graph | `Graph(G)` is structurally equal to G with independent attribute dicts. `StableGraph → Graph → StableGraph` preserves nodes and edges, and compacts indices after a removal | nx:TG:342-351; pg:tests/stable_graph.rs:429-465 |
| C-20 | Bulk update with an empty input is a no-op; with no arguments it raises | `K3.update(nodes=[3,4], edges=[(4,5),(6,7)])` → nodes 0..7 | nx:TG:850-921 |
| C-21 | Path/star/cycle helpers: degenerate inputs | `add_path([x])` adds the node with no edges; `add_path([])` is a no-op; `add_cycle([12])` adds the node and **no self-loop**; `add_cycle` of 4 nodes → 4 edges including the closing one | nx:TF:83-199 |

---

## 2. Vertex insertion and removal

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| V-01 | Adding a vertex is idempotent (hashed keys) | NetworkX `add_node("m")` twice → 1 node. JGraphT g1={v1}: `addVertex(v1)` → **false**, `addVertex(v2)` → true, V 1→2. petgraph `GraphMap.add_node` is idempotent; `Graph.add_node` always creates a new index | nx:HT:77-85; jgt:test/.../graph/SimpleDirectedGraphTest.java:115-125; pg:src/graphmap.rs:290-294 |
| V-02 | Insert reports whether the vertex was new | JGraphT returns a `Bool`; BGL named vertices return the **same descriptor** for a duplicate name. Swift: `@discardableResult (inserted: Bool, ...)` like `Set.insert` | jgt:main/.../Graph.java:244-257; bgl:test/named_vertices_test.cpp:66-94 |
| V-03 | Equal-but-not-identical vertices collapse | `EquivVertex` with `equals == true` and hash 1: adding v1 then v2 is a no-op; `addEdge(v1,v2)` becomes a **self-loop**, so `degreeOf(v1) == degreeOf(v2) == 2` | jgt:test/.../graph/GenericGraphsTest.java:107-117, 143-168 |
| V-04 | Removing a vertex removes incident edges in **both** directions | JGraphT 4-cycle 1→2→3→4→1: remove v1 → V=3, **E=2**; remove v2 → E=1; remove v3 → E=0, V=1; remove v4 → V=0. NetworkX K3 `remove_node(0)` → adj `{1:{2},2:{1}}` | jgt:SimpleDirectedGraphTest.java:456-472; nx:TG:751-756 |
| V-05 | Removing a vertex with loops and parallel edges | petgraph undirected a,b,c,d with edges a-b, a-c, c-a, a-a, b-c, b-a, a-d (7 edges). Before: `neighbors(b) == [a,c,a]`. `remove_node(a)` → V=3, **E=1**, `neighbors(b) == [c]`, `find_edge(a,a) == None` | pg:tests/graph.rs:33-71 |
| V-06 | Removing a vertex with a self-loop does not double-free or crash | NetworkX: `add_edge(1,1)`, `remove_node(1)`; `add_edge(0,0)` and `add_edge(1,1)`, then `remove_nodes_from([0,1])`. The implementation snapshots `list(adj[n])` before mutating | nx:TG:180-193, nx:HT:177-186, nxsrc:graph.py:693 |
| V-07 | Removing a vertex leaves no dangling references (in-lists too) | petgraph `GraphMap` regression #431: DiGraphMap `add_edge(1,2)`, `remove_node(2)` → `neighbors(1) == []`, `all_edges() == []`. BGL `clear_vertex(c)`: no vertex has c in its adjacency | pg:tests/graphmap.rs:135-147; bgl:test/graph.cpp:55-90, 442-470 |
| V-08 | Neighbors of other vertices after removal (undirected, with a loop) | petgraph StableGraph a,b,c,d; edges (a,b),(a,c),(b,c),(c,c),(a,d). Remove b → `neighbors(a) == [d,c]`, `neighbors(c) == [c,a]` (loop listed once), `neighbors(d) == [a]`, `neighbors(b) == []` | pg:tests/stable_graph.rs:315-335 |
| V-09 | **Removing an absent vertex** | NetworkX `remove_node(-1)` raises `NetworkXError("The node -1 is not in the graph.")`, but `remove_nodes_from([-1])` is **silent**. petgraph returns `None` (Graph) or `false` (GraphMap). JGraphT returns `false`, and removing again returns false. BGL: undefined. **Grafluent decision**: recommend `@discardableResult remove(vertex:) -> Bool` (no trap) | nx:TG:756-764, nx:HT:83, nxsrc:graph.py:661-709; pg:src/graphmap.rs:296-301; jgt:SimpleDirectedGraphTest.java:456-472, jgt:main/.../graph/AbstractBaseGraph.java:532-547 |
| V-10 | Remove then re-add gives a clean vertex | StableGraph: after removing n(1) and `clear_edges`, the next `add_node` reuses slot 1, then 4 (free list). For a hashed design: re-adding the key gives degree 0 and no ghost arcs | pg:tests/stable_graph.rs:87-96 |
| V-11 | Dense-index compaction on removal (only if indices are dense) | BGL vecS: add v1,v2,v3; arc v3→v1 carries property 1234; `remove_vertex(v2)` → the property survives renumbering. Regression #268: `add_edge(2,0)`, `remove_vertex(1)` → V=2, E=1 (the arc becomes 1→0). petgraph `Graph.remove_node` moves the last node into the hole, so the old last index is invalid: add a(0), b(1); remove a; `gr[b]` **panics** | bgl:test/delete_edge.cpp:13-72; pg:tests/graph.rs:1095-1104, pg:src/graph_impl/mod.rs:754-765 |
| V-12 | Stable indices variant: holes are skipped | StableGraph add 0,1,2; remove 1 → `node_indices() == [0,2]`. 10 nodes, remove 0 and 2 → `node_bound` stays 10 | pg:tests/stable_graph.rs:38-66 |
| V-13 | `clear()` vs `clearEdges()` | `clear()`: no nodes, no edges. `clear_edges()`: nodes kept **in the same order**, adj `{0:{},1:{},2:{}}`, and succ == pred == all-empty for DiGraph | nx:TG:815-831, nx:TDG:281-300; pg:tests/stable_graph.rs:87-96 |
| V-14 | Exact counter deltas on random add/remove | BGL: `add_vertex` ×2 → V grows by exactly 2, neither new vertex has out-edges, neither appears as an endpoint. `remove_vertex` → iterating vertices yields old_N − 1 | bgl:test/graph.cpp:300-395, 472-515 |
| V-15 | Mutating while iterating (CoW analogue) | NetworkX raises "dictionary changed size during iteration". For Swift: iterate `g.vertices` while removing from `g`; the iteration must see the old snapshot (CoW) and must not crash | nxsrc:graph.py:713-718 |
| V-16 | Broken Hashable is detected (debug aid) | JGraphT `ParanoidGraph` throws when an added vertex is `==` to an existing one but hashes differently | jgt:test/.../graph/CloneTest.java:63-105 |

---

## 3. Arc and edge insertion and removal

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| E-01 | Duplicate arc in a simple graph is not added; the result says so | JGraphT g2 has 2→1: `addEdge(v2,v1)` → `null`. g4 lacks 2→1 → non-null. BGL setS returns `(existing, false)`. petgraph CSR `add_edge(1,2)` again → `false` with arrays unchanged. NetworkX: silent, count unchanged (path_graph(6) + `add_edge(1,3)` twice → still 1 edge) | jgt:SimpleDirectedGraphTest.java:83-85, 106-108; bgl:test/graph.cpp:131-137; pg:src/csr.rs:928-931; nx:TRV:1018-1021 |
| E-02 | Undirected duplicate in reversed orientation is the same edge | petgraph GraphMap undirected: `add_edge(f,b,16)` after (b,f) → `Some(15)` (old weight). `update_edge(a,b)` then `update_edge(b,a)` → 1 edge, same index | pg:tests/graphmap.rs:34-81; pg:tests/graph.rs:367-391 |
| E-03 | Directed: an antiparallel arc is **not** a duplicate | GraphMap directed `add_edge(e,d)` when d→e exists → `None` (new). JGraphT g2 {1→2, 2→1} is a valid simple digraph | pg:tests/graphmap.rs:257-278; jgt:SimpleDirectedGraphTest.java:565-611 |
| E-04 | Upsert semantics (if arcs carry labels or weights) | petgraph `update_edge(a,b,1)` returns e; `update_edge(a,b,2)` returns the same e with weight 2; `update_edge(b,a,3)` adds a new arc (directed) → E=2 | pg:tests/graph.rs:367-417 |
| E-05 | Parallel edges in a multigraph each get a distinct identity | NetworkX: each `add_edge` gets a new key; `add_edges_from([(0,1),(0,1,{w:3})])` → keys 0,1, repeated → 2,3. BGL `add_edge(u,v)` ×2 → E=2 (vecS/listS/multisetS × all 3 directions). petgraph `Graph`: two a→b → E=2 | nx:TMG:310-331; bgl:test/adj_list_loops.cpp:24-36, 69-89; pg:tests/graph.rs:293-301 |
| E-06 | Self-loop accepted where allowed | Directed: `add_edge(a,a)` → `find_edge(a,a)` is Some; removing it → None. BGL loop: E=1, then after `remove_edge(v,v)` E=0, for vecS/listS/setS/multisetS × 3 directions | pg:tests/graph.rs:166-185; bgl:test/adj_list_loops.cpp:38-48 |
| E-07 | Self-loop rejected in a "simple" (loopless) graph | JGraphT `SimpleDirectedGraph.addEdge(v1,v1)` → `IllegalArgumentException`. Only relevant if we have a loopless policy | jgt:SimpleDirectedGraphTest.java:66-70, 90-94 |
| E-08 | Parallel self-loops | BGL: `add_edge(v,v)` ×2 → E=2; `remove_edge(v,v)` → 0 (removes all). NetworkX multi: K3 + `(0,0)` ×2 + keyed `(0,0)`, remove that key → `number_of_edges(0,0) == 2`; `remove_edge(0,0)` → 1. The BGL header has special code so a loop's property is not freed twice ("Without this skip, this loop will double-delete properties of loop edges") | bgl:test/adj_list_loops.cpp:50-60; nx:TMG:110-118 |
| E-09 | Arc to a missing endpoint | JGraphT: `addEdge(v2,v1)` on {v1} → IAE. petgraph `try_add_edge(a,10)` → `Err(NodeOutBounds)`; StableGraph `add_edge(a, removedB)` panics "is not a node". NetworkX/GraphMap: **auto-insert**. **Grafluent decision**: auto-insert (ergonomic) vs precondition | jgt:SimpleDirectedGraphTest.java:94-98; pg:tests/graph.rs:2632-2646, pg:tests/stable_graph.rs:287-306, pg:tests/list.rs:186-214; nx:HT:177-186 |
| E-10 | Removing an arc removes exactly that direction (directed) | NetworkX K3-bidirected `remove_edge(0,1)` → succ `{0:{2},1:{0,2},2:{0,1}}`, pred `{0:{1,2},1:{2},2:{0,1}}` | nx:TDG:266-272 |
| E-11 | Removing an undirected edge given in either orientation | K3 `remove_edge(0,1)` → `{0:{2},1:{2},2:{0,1}}`. GraphMap undirected `remove_edge(2,1)` removes the 1-2 edge, and `edge_weight` in both orientations is None | nx:TG:802-807; pg:tests/graphmap.rs:113-133 |
| E-12 | **Removing an absent arc** | NetworkX `remove_edge(-1,0)` raises; `remove_edges_from([(0,0)])` is silent. petgraph returns `None`; directed `remove_edge(2,1)` with only 1→2 present → None. BGL: no-op, count unchanged (`remove_edge(5,0)` keeps M−4). JGraphT `removeEdge(neverInserted)` → false; `removeAllEdges(v3,v2)` with no such arc → empty set; with a missing vertex → **null**. Recommend returning `Bool`/count | nx:TG:806-813, nxsrc:graph.py:1117-1175; pg:tests/graphmap.rs:148-170; bgl:test/test_destruction.hpp:88-90; jgt:SimpleDirectedGraphTest.java:406-450 |
| E-13 | **Removing one of several parallel arcs** | NetworkX `remove_edge(u,v)` without a key removes the **last added**. BGL `remove_edge(u,v)` removes **all** (2 → 0); `remove_edge(e)` removes exactly one (`old_E == E + 1`). JGraphT `removeEdge(u,v)` removes **one**; `removeAllEdges(u,v)` removes all and returns them. **Grafluent decision**: offer both `removeArc(from:to:)` (one; say which) and `removeAllArcs(from:to:)` | nxsrc:multigraph.py:645; nx:TMG:393-406, nx:TMDG:345-377; bgl:test/adj_list_loops.cpp:24-36, bgl:test/graph.cpp:217-285; jgt:main/.../graph/AbstractBaseGraph.java:499-509, jgt:SimpleDirectedGraphTest.java:431-450 |
| E-14 | Remove a specific loop among several | petgraph: x has loops with weights 14, 15, 16; remove 15 → `edges(x) == [(x,16),(x,14),(n1,13)]` | pg:tests/stable_graph.rs:161-196 |
| E-15 | Bulk removal on a multigraph: each tuple removes one | K3 plus an extra 0-1 (key 1): `remove_edges_from([(0,1,0),(0,2,0,{}),(1,2)])` → `{0:{1:{1:{}}},1:{0:{1:{}}},2:{}}`. Removing every element of `G.edges()` empties the graph | nx:TMG:373-391 |
| E-16 | Bulk remove fed with a live view of self | `remove_edges_from(selfloop_edges(G))` works for Graph/DiGraph; for a multigraph with `keys=True` it raises `RuntimeError`. Swift: `g.removeArcs(g.loops)` must work, because CoW snapshots the argument | nx:TF:980-1015 |
| E-17 | Removing an arc never removes vertices | petgraph retain fixture: node count is unchanged after `retain_edges`. BGL "disconnect" sequence: V stays 6 | pg:tests/graph.rs:1799-1828; bgl:test/test_destruction.hpp:66-91 |
| E-18 | Disconnect sequence on FX-06 (exact counts) | Remove (5,3) by id → 6; `remove_edge(3,2)` → 5; `clear_vertex(0)` (incident 4-0, 1-0) → 3; `remove_edge(5,0)` (absent) → 3. Remaining arcs `{(3,4),(4,1),(2,1)}` | bgl:test/test_destruction.hpp:66-91 |
| E-19 | Reusing an edge identity with different endpoints is rejected and the graph is unchanged | JGraphT `IntrusiveEdgeException`; E stays 1 and all in/out sets are unchanged (directed and undirected) | jgt:test/.../graph/IncomingOutgoingEdgesTest.java:44-77, 167-194 |
| E-20 | Index-type capacity limits (if the index type is generic) | `Graph<_,_,_,u8>` holds 255 nodes; the 256th `add_node` panics, while `try_add_node` returns `Err(NodeIxLimit)`. 255 loops on one node are OK, then `Err(EdgeIxLimit)` | pg:tests/graph.rs:1121-1147, 2622-2647 |

---

## 4. Queries

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| Q-01 | `contains(vertex)` | K3: `1 in G`, `4 not in G`. JGraphT g1: v1 true, v2 false | nx:TG:23-29; jgt:SimpleDirectedGraphTest.java:180-198 |
| Q-02 | `contains(arc)` is directional for digraphs and symmetric for undirected graphs | JGraphT g1: (1,2) false, (1,1) false; g2: both directions true; g4 has 1→2 but not 1→4. NetworkX EdgeView: undirected (1,2) and (2,1) both present; directed only (1,2) | jgt:SimpleDirectedGraphTest.java:153-177; nx:TRV:625-640 |
| Q-03 | `contains(arc)` with an absent endpoint returns false (never traps) | NetworkX `has_edge(0,-1)` → False. JGraphT `g3.containsEdge(v4,v2)` → false. NetworkX `get_edge_data(10,20)` → None | nx:TG:65-68, 842-848; jgt:SimpleDirectedGraphTest.java:153-177 |
| Q-04 | Queries about an absent vertex: libraries **split** | NetworkX: `neighbors(-1)`, `degree(-1)`, `successors(-1)` raise. JGraphT: `inDegreeOf("")` → IAE. petgraph/GraphMap: empty iterator. **Grafluent decision**: recommend returning empty (or `nil`) for neighbors and 0 for degree, or document a precondition; be consistent | nx:TG:13-18, 70-75, nx:TDG:17-32; jgt:SimpleDirectedGraphTest.java:356-370; pg:src/graph_impl/mod.rs:895 |
| Q-05 | Out-neighbors and in-neighbors on a small DAG | FX-06 directed: out-degree v0..v5 = **0,1,1,2,2,1**; `target(out(v1)) == v0`, `out(v2) == v1`, `out(v5) == v3`. In-degree = **2,2,1,1,1,0**; `source(in(v2)) == v3`, `in(v3) == v5`, `in(v4) == v3` | bgl:test/test_direction.hpp:20-53, 67-96 |
| Q-06 | Undirected degree on the same edges | FX-06 undirected: **2,3,2,3,3,1** (sum 14 = 2M). Equals out + in from Q-05 | bgl:test/test_direction.hpp:109-134 |
| Q-07 | Successors and predecessors on the "ABCD" fixture (FX-07) | Directed: `successors(A) == [B,C]`, `successors(C) == [D]`, `predecessors(C) == [A,B]`, `predecessors(A) == []`, isolated `successors(G) == []`. In-degree `{A0,B1,C2,D2}`, out-degree `{A2,B2,C1,D0}` | nx:TDGH:16-63 |
| Q-08 | Incoming and outgoing arcs keep their (source, target) orientation | GraphMap `edges_directed(c, Incoming) == [(a,c,9),(b,c,10)]`, not flipped. JGraphT g2: `outgoingEdgesOf(v1) == incomingEdgesOf(v2)` | pg:tests/graphmap.rs:83-111; jgt:SimpleDirectedGraphTest.java:345-353 |
| Q-09 | Undirected: in == out == all incident | petgraph: for every vertex, `edges_directed(Out)` == `edges(i)` == `edges_directed(In)`; outgoing edges are re-oriented so `source == i`, incoming so `target == i`. JGraphT undirected: `inDegreeOf == outDegreeOf == degreeOf`. BGL undirected: `in_degree == degree == out_degree` | pg:tests/graph.rs:1434-1494; jgt:main/.../graph/specifics/UndirectedSpecifics.java:229-260; bgl:hdr:1101-1130 |
| Q-10 | Directed degree = in + out | NetworkX bidirected K3 degree 4 (2+2). DiGraph `[(1,24),(1,2)]` in `[0,1]`, out `[0,2]`, degree `[1,2]` (sorted). JGraphT multi-triangle `{1→2,2→1,2→3,3→1}`: in 2,1,1; out 1,2,1; `edgesOf` sizes 3,3,2 | nx:TDG:75-94, nx:TDGH:47-52; jgt:test/.../graph/DirectedGraphTest.java:103-137, 160-170 |
| Q-11 | **Undirected self-loop counts 2 in degree** (handshake) | `Graph(); add_edge(1,1)` → `degree(1) == 2`, size 1, `neighbors(1) == [1]`. `MultiGraph` with two loops → degree 4. Implementation: `len(nbrs) + (n in nbrs)` | nx:TG:171-178, nxsrc:reportviews.py:717, 789-790 |
| Q-12 | Self-loop degree, cross-library confirmation | JGraphT pseudograph (FX-10) undirected degrees `[1,5,2,3,5]`; Javadoc: "self-loops are counted twice". petgraph test helper "self loops count twice"; degree sequence of FX-12 = `[5,3,3,2,2,1,0]`. **BGL: depends on the selector.** Verified by compiling against the cloned headers: undirected loop (0,0) plus edge (0,1) gives `degree(0) == 2` with setS, versus a loop counting 2 with vecS/listS/multisetS (after removing (0,1): setS deg 1, vecS deg 2) | jgt:IncomingOutgoingEdgesTest.java:199-258, jgt:main/.../Graph.java:317; pg:tests/graph.rs:1925-1979; bgl:hdr:1058-1108 (verified locally) |
| Q-13 | Directed self-loop: in 1, out 1, degree 2, size 1 | NetworkX DiGraph loop: degree 2, in 1, out 1, size 1. BGL bidirectionalS: deg 2, out 1, in 1 (verified). JGraphT FX-10 directed: in `[0,2,2,2,2]`, out `[1,3,0,1,3]`, degree `[1,5,2,3,5]` | nxsrc:reportviews.py:638; jgt:IncomingOutgoingEdgesTest.java:79-138 |
| Q-14 | **Loop multiplicity in neighbor or incident lists** | petgraph directed `(a,a),(a,b),(c,a),(a,a)`: `out(a) == [a,a,b]` (sorted), `in(a) == [a,a,c]`, `neighbors_undirected(a) == [a,a,b,c]`, so each loop appears once per list. Undirected `(a,a),(a,b),(c,a)`: `neighbors(a) == [a,b,c]` (once). JGraphT: `edgesOf(5)` = 3 edges while `degreeOf(5)` = 5, so **edge count of incident list ≠ degree**. BGL vecS: the loop appears twice in `out_edges`. **Grafluent decision**: recommend listing the loop once in neighbors and adding 2 to degree; test that `degree != neighbors.count` when loops are present | pg:tests/graph.rs:1847-1925, pg:tests/graphmap.rs:385-407; jgt:IncomingOutgoingEdgesTest.java:79-138 |
| Q-15 | Order and size | `len(G) == order() == number_of_nodes() == 3`; `size() == number_of_edges() == 3` (K3); DiGraph bidirected K3 size 6. JGraphT edge counts: g1 0, g2 2, g3 6, g4 4 | nx:TG:31-35, 133-136, nx:TDG:96-99; jgt:SimpleDirectedGraphTest.java:204-228 |
| Q-16 | Size counts loops once; incident count | path_graph(9) + (1,1): `len(edges) == 9`; `len(edges(1)) == 3` undirected. Multi: `len(H.edges(1)) == 3 + is_multigraph - is_directed` | nx:TRV:371-386, 654-663 |
| Q-17 | Arc multiplicity between a pair | `number_of_edges(A,B) == 1`, `(A,D) == 0`; multigraph count of (0,0) loops | nx:HT:315-322, nx:TMG:116 |
| Q-18 | Self-loop helpers | K3 + (0,0) for all 4 classes: `number_of_selfloops == 1`, `nodes_with_selfloops == [0]`, `selfloop_edges == [(0,0)]` | nx:TF:946-955 |
| Q-19 | Cached count == iterated count (invariant) | BGL: `num_edges(g) == distance(edges(g))` after every random op. petgraph: `node_count == node_indices().count()`, `edge_count == edge_references().count()`, and every stored (s,t) can be found with `find_edge` | bgl:test/graph.cpp:93-150; pg:tests/graph.rs:1830-1846, pg:tests/quickcheck.rs:108-123 |
| Q-20 | Arcs between a pair, including parallels | Directed a→a, a→b(#1), a→c, c→b, a→b(#2), b→a: `edges_connecting(a,b)` = exactly the 2 a→b ids. Undirected: 3 ids (b→a counts) | pg:tests/graph.rs:303-365 |
| Q-21 | Degree over a subset silently drops non-members | `P3.degree(["A","B"]) == {}`; `P5.degree(P3) == [1,2,2]`; `P3.degree(P5) == [1,1,2]` | nx:HT:298-308 |
| Q-22 | Sources and sinks | petgraph `externals`: 4 nodes, edges a-b, a-c. Undirected: Outgoing externals = `[d]`. Directed: Incoming (sources) = `[a,d]`, Outgoing (sinks) = `[b,c,d]`. FX-06: v5 is the only source, v0 the only sink | pg:tests/graph.rs:711-733 |
| Q-23 | Density with loops can exceed 1 (a derived-metric trap) | Single node + loop → density 0.0; add (1,2) → **2.0**. FX-05 density 0.5 (undirected) and 0.3 (directed) | nx:TF:247-258 |
| Q-24 | Non-neighbors and common neighbors (derived queries) | K100 non-neighbors of v: 0; P100 interior 97, endpoint 98; 10 isolated → 9. `common_neighbors(K5,0,1) == [2,3,4]`, `(P3,0,2) == [1]` | nx:TF:313-363, 437-481 |

---

## 5. Directed vs undirected semantics, converse, conversion

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| D-01 | Undirected adjacency is symmetric | For every stored edge, `find_edge(s,t)` and `find_edge(t,s)` are both Some. `edge_weight(1,2) == edge_weight(2,1)`. NetworkX `adj[0][1] is adj[1][0]` (same data object) | pg:tests/graph.rs:52-55, pg:tests/graphmap.rs:113-121; nx:TG:766-775 |
| D-02 | Directed out-adjacency and in-adjacency mirror each other | `add_edge(0,1)` → succ `{0:{1},1:{}}`, pred `{0:{},1:{0}}`. petgraph rebuilds `incoming[j]` by scanning `neighbors(i)` and asserts it equals `edges_directed(j, Incoming)`. BGL CSR: forward and backward sets are equal after sorting | nx:TDG:236-248; pg:tests/stable_graph.rs:225-260; bgl:test/csr_graph_test.cpp:150-185 |
| D-03 | Converse (reverse) as a copy | `DiGraph([(0,1),(1,2)]).reverse()` → `[(1,0),(2,1)]`, and mutating R leaves G alone. Multi: `[(0,1),(0,1)]` reversed → `[(1,0),(1,0)]` (parallels kept). Isolated nodes kept: nodes 1..4 with no edges → same nodes | nx:TDG:109-115, nx:TMDG:231-237, nx:TDGH:99-109 |
| D-04 | Converse swaps in-degree and out-degree (property) | The out-degree vector before equals the in-degree vector after, and vice versa; the graph stays consistent | pg:tests/quickcheck.rs:125-152 |
| D-05 | A symmetric digraph is its own converse; undirected reverse is isomorphic to the original | `reverse(to_directed(K10))` has an identical edge set. Undirected `reverse()` is isomorphic to the original | nx:TDGH:92-97; pg:tests/quickcheck.rs:100-106 |
| D-06 | Converse as a live view | JGraphT `EdgeReversedGraph` on {v1→v2}: `r.containsEdge(v2,v1)`, `!r.containsEdge(v1,v2)`; in(v1)=1, out(v2)=1; `getEdgeSource(e) == v2`; toString `"([v1, v2], [(v2,v1)])"`. After `g.removeEdge(e)`, r is empty. NetworkX `reverse(copy=False)` is read-only: `remove_edge` raises | jgt:SimpleDirectedGraphTest.java:498-562; nx:TDG:117-122 |
| D-07 | Converse incoming == original outgoing, edge by edge | On FX-08 + loop c→c: `gr.edges_directed(i, Incoming)` equals `reversed.edges(i)` (same ids, same order) | pg:tests/graph.rs:1320-1385 |
| D-08 | Directed → undirected merges antiparallel arcs | ABCD `.to_undirected()` → edges at A,B: `[(A,B),(A,C),(B,C),(B,D)]`; removing (A,B) removes the edge in both directions. `(0,1),(1,0)` → 1 edge, **even for a MultiDiGraph** (keys collide). The MultiDiGraph K3 → MultiGraph result depends on traversal order (the test accepts 3 or 4 edges). **Grafluent decision**: specify multiplicity explicitly | nx:HT:362-388; nx:TMDG:153-167 |
| D-09 | Directed → undirected, reciprocal only | 1→2 alone → no edge; add 2→1 → edge | nx:TDG:101-107, nx:TMDG:223-229 |
| D-10 | Directed → undirected **without merging** | petgraph `into_edge_type::<Undirected>()` is O(1) with no adjustment, so a→b and b→a become **2 parallel undirected edges** (contrast with D-08) | pg:src/graph_impl/mod.rs:1802-1805; pg:tests/graph.rs:1058-1092 |
| D-11 | Undirected → directed doubles every edge | ABCD undirected → `out_edges(["A","B"]) == [(A,B),(A,C),(B,A),(B,C),(B,D)]`; removing A→B leaves B→A. Undirected K3 (size 3) → directed size 6 | nx:HT:338-360 |
| D-12 | Undirected view of a directed graph | JGraphT AsUndirected over `{1→2, 2→3, 2→4, 4→4}`: degrees `[1,3,1,3]` (v4 = e24 + loop×2), in == out == degree, `getEdge(v1,v2) == getEdge(v2,v1)`, `getAllEdges(v4,v4) == {loop}`. `addEdge` on the view throws; `addVertex` writes through | jgt:test/.../graph/AsUndirectedGraphTest.java:53-229 |
| D-13 | Undirected degree = directed out + in (cross-check) | FX-06: (0+2, 1+2, 1+1, 2+1, 2+1, 1+0) = 2,3,2,3,3,1 | bgl:test/test_direction.hpp |
| D-14 | Equality respects direction | Undirected 0-1 added as (0,1) vs (1,0) → equal, same hash. Directed → not equal, different hash | jgt:test/.../graph/EqualsAndHashCodeTest.java:299-331 |
| D-15 | Text form distinguishes direction | Directed `"([v1, v2, v3, v4], [(v1,v2), (v2,v3), (v2,v4), (v4,v4)])"`; undirected `"... [{v1,v2}, ...]"`. NetworkX `"Graph with 3 nodes and 2 edges"` | jgt:AsUndirectedGraphTest.java:203-210; nx:TG:312-320 |
| D-16 | Traversal over the converse | H→I, H→J, I→J, I→K, isolated Z: DFS from H visits 4; on the converse from H visits 1, from K visits 3 (K,I,H) | pg:tests/graph.rs:72-96 |

---

## 6. Equality semantics and copying (maps to Swift `Equatable`, `Hashable` and CoW)

| ID | What is asserted | Fixture → expected | Source |
|---|---|---|---|
| K-01 | Equality ignores insertion order | JGraphT DefaultDirectedGraph V{v1..v4}, E{1→2, 2→3, 3→1}; the same graph inserted in reverse order is equal with the same hash. Isolated v4 is part of the comparison | jgt:EqualsAndHashCodeTest.java:44-76 |
| K-02 | Missing arc → not equal | The same graph without 1→2 is ≠ | jgt:EqualsAndHashCodeTest.java:44-76 |
| K-03 | Isolated vertices count toward equality | The extra isolated vertex in K-01 must match | jgt:EqualsAndHashCodeTest.java:44-76 |
| K-04 | Parallel edge multiplicity counts | Pseudograph with parallel 1-2 ×2 plus loop 1-1 (5 edges) is equal regardless of order; dropping one parallel edge → ≠ | jgt:EqualsAndHashCodeTest.java:153-189 |
| K-05 | Arc labels and weights count, compared exactly | Weights {10,20,30} vs {10,20,30} equal; vs {100,200,300} not; 2+1e-8 vs 2-1e-8 not equal | jgt:EqualsAndHashCodeTest.java:227-297 |
| K-06 | Libraries without `==` | NetworkX `G == G.copy()` is **False** (identity); structure is compared with `graphs_equal` (adj, nodes and graph attributes equal) and the order-insensitive `edges_equal`. petgraph compares with `is_isomorphic_matching` or sequence equality of node and edge references. BGL `assert_graphs_equal`: same V and E, and per vertex the same out-degree and the same **sorted** target multiset. Swift: our `==` should be the BGL helper's definition (vertex set + arc multiset), independent of order | networkx/networkx/utils/misc.py:555-560, 636-655; pg:tests/stable_graph.rs:420-427; bgl:test/csr_graph_test.cpp:58-127 |
| K-07 | Hash consistent with order-insensitive equality | JGraphT hashCode = vertex-set hash + Σ over edges of f(edge, pair(s,t), weight), so it is commutative. Test with `checkHashable` (S-04) | jgt:main/.../graph/AbstractGraph.java:210-296 |
| K-08 | Copy is independent: mutate the copy, the original is unchanged | petgraph `old = gr.clone()`; negate every weight in gr; `gr == -old` (old unchanged). NetworkX reverse copy, deepcopy `D.add_edge(1,2)`: D has one more edge, G unaffected. `different_attrdict` mutates H and checks `G._adj != H._adj`. JGraphT CloneTest removes both edges from the clone, **but never checks the original**, so we must add that check | pg:tests/graph.rs:1149-1200; nx:TG:255-271, 331-351, 420-431; jgt:CloneTest.java:36-58 |
| K-09 | Copy is structurally equal to the original | BGL `CSRGraphT g2(g)` → `assert_graphs_equal`. NetworkX `H.adj == G.adj`, `H is not G` | bgl:test/csr_graph_test.cpp:201-210; nx:HT:324-329 |
| K-10 | Copy depth for payloads | NetworkX `copy()` = new dicts at every level with shared attribute values; `to_directed()` and deepcopy are deep. JGraphT `clone` shares vertex and edge objects. Swift: values give deep semantics for free; with class payloads, test with `LifetimeTracked` that the copy retains rather than duplicates them | nxsrc:graph.py:1591-1640; jgt:main/.../graph/AbstractBaseGraph.java:372-400 |
| K-11 | Copy does not leak | NetworkX counts gc objects of the graph type before and after `G.copy()` and expects them equal; views must not create reference cycles (a weakref dies by refcount alone). Swift: `.leakChecked` trait (S-02) | nx:TG:79-114, 207-234 |
| K-12 | Swap | BGL `swap` compiles; it is implemented as three deep copies. Swift: `swap(&a,&b)` must be O(1) (buffer swap); assert storage IDs are exchanged | bgl:test/swap.cpp; bgl:include/boost/graph/adjacency_list.hpp:363-369 |
| K-13 | Map/transform preserves structure | petgraph identity `map`/`filter_map` preserves nodes, weights and endpoints; `map` with weights ×2: (ab 7 → 14, bc 14 → 28, ca 9 → 18) | pg:tests/quickcheck.rs:1158-1184; pg:tests/stable_graph.rs:515-556 |
| K-14 | Serialization round trip preserves equality | NetworkX pickle → `graphs_equal`; the EdgeView pickles equal | nx:TG:675-680, nx:TRV:564-570 |
| K-15 | Read-only or frozen wrapper rejects mutation | NetworkX `freeze`; JGraphT `AsUnmodifiableGraph` throws `UnsupportedOperationException`. Swift: `let` covers this; skip | nx:TF:260-290; jgt:AsUnmodifiableGraphTest.java:40-93 |

---

## 7. Iteration-order guarantees

| ID | Library / type | Guarantee | Asserted by |
|---|---|---|---|
| O-01 | NetworkX | **Not documented**; dict insertion order in practice. Most tests sort or use order-insensitive helpers. Exact order is asserted only in str/repr tests: path_graph(9) nodes iterate 0..8; edges `"[(0, 1), ..., (7, 8)]"`; MultiEdgeView groups parallel keys under (u,v): `(0,1,0),(1,2,0),(1,2,3),(2,3,0)` | nx:TRV:26-66, 575-586, 794-800 |
| O-02 | NetworkX | `add_edges_from([(3,1),(2,0)]); add_node(9)` → nodes `[3,1,2,0,9]` (first-seen); each undirected edge is reported once, from the endpoint seen first. `clear_edges` keeps node order. Subgraphs are "not guaranteed to preserve order" | nx:TG:823-831; nxsrc:graph.py:1851 |
| O-03 | petgraph `Graph`/`StableGraph` | Neighbors are **LIFO** (reverse insertion). Directed a→b, a→a, c→a, a→c, c→a, b→a → `neighbors(a) == [c,a,b]`, `incoming(a) == [b,c,c,a]` | pg:tests/graph.rs:1980-2003; pg:src/graph_impl/mod.rs:923-925 |
| O-04 | petgraph undirected | Outgoing first (LIFO), then incoming (LIFO). `[(0,1),(0,2),(1,4),(1,3),(5,1)]` → `neighbors(1) == [3,4,5,0]`, `neighbors(0) == [2,1]`; directed `incoming(1) == [5,0]` | pg:tests/graph.rs:2649-3198; pg:tests/stable_graph.rs:685-1234 |
| O-05 | petgraph `edges_connecting` | 3× 0→1 (e0..e2), 3× 1→0 (e3..e5): directed (0,1) → `[e2,e1,e0]`; undirected (0,1) → `[e2,e1,e0,e5,e4,e3]` | pg:tests/graph.rs:3199-3274 |
| O-06 | petgraph `adj::List`, `GraphMap` | **FIFO** (insertion order): List `neighbors(a) == [b,c,d]`; GraphMap `edges_directed(c,Out) == [(c,d),(c,f)]`. GraphMap nodes iterate in insertion order (1000 nodes → (i,i)), **but** `remove_node`/`remove_edge` use `swap_remove`, so removal moves the last element into the hole | pg:tests/list.rs:222-238; pg:tests/graphmap.rs:83-111, 423-450; pg:src/graphmap.rs:302,315,416 |
| O-07 | petgraph `Csr` | Neighbors sorted by target regardless of insertion order: adding (0,0),(1,2),(2,2),(0,2),(1,0),(1,1) gives column `[0,2,0,1,2,2]`, row `[0,2,5,6]` | pg:src/csr.rs:919-940 |
| O-08 | BGL | "The placement of the new edge in the out-edge list is in general unspecified"; in practice vecS/listS keep insertion order and setS/multisetS sort by target. vecS vertices are in index order. Tests that compare edge sets **sort first** | bgl:doc/modules/ROOT/pages/graph_classes/adjacency_list.adoc:413; bgl:test/csr_graph_test.cpp:95-125 |
| O-09 | JGraphT | **Documented**: "All implemented strategies guarantee deterministic vertex and edge set ordering (via LinkedHashMap and LinkedHashSet)", so vertex, edge and per-vertex edge sets follow insertion order. Edges 1→2, 2→3, 3→1 iterate in that order; toString `"([v1, v2, v3], [(v1,v2), (v2,v3), (v3,v1)])"`. The HashMap-backed variant runs the same assertions with no order checks | jgt:main/.../graph/AbstractBaseGraph.java:37-40; jgt:DirectedGraphTest.java:45-98, 142-150 |
| O-10 | **Grafluent decision** | Choose one: (a) insertion order (OrderedDictionary-like; must specify what removal does: stable compaction vs swap-remove), (b) unspecified. Either way, write order-insensitive behavior tests and **separate** order-contract tests (as JGraphT does). If the order is unspecified, add a test that `==` and `hashValue` are independent of order | — |

---

## 8. Edge cases

| ID | Case | Fixture → expected | Source |
|---|---|---|---|
| X-01 | Large or extreme vertex ids | BGL vecS `add_edge(1_000_000,0)` → 1,000,001 vertices (verified locally). For hashed keys: `Int.max`, `Int.min`, `0`, `-1` as vertices must behave like any other key (no dense allocation) | bgl:hdr:2263-2264 |
| X-02 | Sparse ids | CSR edges on 0..4 with nothing touching 3 → 5 vertices. StableGraph: SCC9 with node 4 removed and a replacement x = n(9) | pg:src/csr.rs:978-988; pg:tests/stable_graph.rs:108-196 |
| X-03 | Many vertices, no arcs | BGL `G g(10)` directed: minimum-degree ordering is a valid permutation. JGraphT EmptyGraphGenerator(10). NetworkX `empty_graph(10).subgraph([1..5])` is isomorphic to `empty_graph(5)`; 10 isolated vertices → 9 non-neighbors each | bgl:test/min_degree_empty.cpp; nx:HT:433-441, nx:TF:335-338 |
| X-04 | Large sparse random graphs | Erdős–Rényi n=1000, p ∈ {0.001, 0.0005}, seed 42: copy equals original, rebuild equals original | bgl:test/csr_graph_test.cpp:356-362, 428-429 |
| X-05 | Graph with only loops | One vertex + one loop: size 1, degree 2, density 0. 255 loops on a single node (u8 index). CSR `from_sorted_edges([(0,0)])` | nx:TF:253-256; pg:tests/graph.rs:2631-2647; pg:src/csr.rs:1151-1156 |
| X-06 | Loops and parallels injected into real inputs | DIMACS planar corpus; every 5th vertex gets 1-6 loops and every 7th edge is duplicated 2-6 times; Euler V−E+F=2 still holds | bgl:test/parallel_edges_loops_test.cpp:46-130 |
| X-07 | Single-value vertex type | GraphMap with `()` as the node type: loop add/remove; `neighbors(())` yields `()` once | pg:tests/graphmap.rs:385-420 |
| X-08 | Mixed or heterogeneous keys | ints and strings in one graph; tuple nodes (Swift: `AnyHashable` or enum keys) | nx:HT:48-68, 471-476 |
| X-09 | Stale handle after removal | petgraph swap-remove: stale index panics; StableGraph: stale index gives empty neighbors and `None` weight, and `add_edge` panics. If we expose vertex handles, test that a stale handle can be detected | pg:tests/graph.rs:1095-1104; pg:tests/stable_graph.rs:287-335 |
| X-10 | Count of 1000 arcs including a loop | `add_edge(i/2, i)` for i in 0..<1000 (i=0 gives the loop 0→0) | pg:tests/graphmap.rs:423-450 |
| X-11 | Precondition traps | BGL compile-fail: `remove_edge` on a vecS edge list. Swift: use exit tests for any `precondition` (S-07) | bgl:test/bidir_vec_remove_edge.cpp |

---

## 9. Standard fixture graphs (with known properties)

Reproduce these as named static fixtures (`Fixtures.k3`, etc.) and use them in parameterized `arguments:`.

| ID | Name | Definition | Known values | Source |
|---|---|---|---|---|
| FX-01 | K3 undirected | V {0,1,2}, E {01, 02, 12} | n=3, m=3, every degree 2, `neighbors(0) == {1,2}`; remove 0 → `{1:{2},2:{1}}`; remove edge 01 → `{0:{2},1:{2},2:{0,1}}` | nx:TG:661-673 |
| FX-02 | K3 bidirected digraph | all 6 ordered pairs | m=6, in 2, out 2, degree 4 for every vertex; converse equals itself | nx:TDG:204-218; jgt:SimpleDirectedGraphTest.java (g3) |
| FX-03 | P3 directed | 0→1→2 | succ `{0:{1},1:{2},2:{}}`, pred `{0:{},1:{0},2:{1}}` | nx:TDG:220-227 |
| FX-04 | K4 / K5 / K10 / K100 | complete | Kn: m = n(n−1)/2 undirected, n(n−1) directed (K10: 45 / 90); every degree n−1 | pg:tests/graph.rs:1785-1797; jgt:test/.../generate/GraphGeneratorTest.java:134-174 |
| FX-05 | NetworkX TestFunction graph | `{0:[1,2,3], 1:[1,2,0], 4:[]}` | see C-11: degrees 3,4,2,1,0; degree histogram `[1,1,1,1,1]`; 2 components; density 0.5. (The fixture's own `Gdegree` dict says 1:2, which is stale; do not copy it) | nx:TF:15-35, 244-247 |
| FX-06 | BGL "house + lollipop" (Wikipedia Graph Theory figure) | V 0..5; arcs (5,3),(3,4),(3,2),(4,0),(4,1),(2,1),(1,0) | DAG (every arc goes from a higher to a lower id; topological order 5,3,4,2,1,0); out 0,1,1,2,2,1; in 2,2,1,1,1,0; undirected 2,3,2,3,3,1; one source (5), one sink (0) | bgl:test/test_graph.hpp:33-45; bgl:test/test_direction.hpp |
| FX-07 | NetworkX "ABCD" | (A,B),(A,C),(B,D),(C,B),(C,D) + isolated G,J,K | undirected n=7, m=5, sorted degrees `[0,0,0,2,2,3,3]`; directed in `{A0,B1,C2,D2}`, out `{A2,B2,C1,D0}` | nx:HT:249-400; nx:TDGH:16-63 |
| FX-08 | petgraph 7-node weighted DAG | a→b 7, a→d 5, d→b 9, b→c 8, b→e 7, c→e 5, d→e 15, d→f 6, f→e 8, f→g 11, e→g 9 (+ loop c→c 8 in the iterator variant) | 11 arcs, acyclic (12 with the loop) | pg:tests/graph.rs:1149-1318 |
| FX-09 | SCC9 | (6,0),(0,3),(3,6),(8,6),(8,2),(2,5),(5,8),(7,5),(1,7),(7,4),(4,1) | 9 vertices, 11 arcs; SCCs {0,3,6}, {2,5,8}, {1,4,7}; the converse has the same SCCs; condensation is a path; weakly connected | pg:tests/graph.rs:859-940 |
| FX-10 | JGraphT loop/multi stress | V 1..5; 1→2, 2→3, 2→3, 2→4, 4→4, 5→5, 5→2, 5→5 | directed in `[0,2,2,2,2]`, out `[1,3,0,1,3]`, degree `[1,5,2,3,5]`; undirected degree `[1,5,2,3,5]`; `edgesOf(5)` = 3 edges. Run over 4 configurations (multi × loops) | jgt:IncomingOutgoingEdgesTest.java:79-285 |
| FX-11 | Dijkstra6 (Wikipedia) | undirected a-b 7, c-a 9, a-d 14, b-c 10, d-c 2, d-e 9, b-f 15, c-f 11, e-f 6 | 6 vertices, 9 edges; distances from A: 0,7,9,11,20,20 | pg:tests/graph.rs:419-460 |
| FX-12 | Degree-sequence fixture | (0,1),(1,2),(1,3),(2,4),(3,4),(4,4),(4,5),(3,5) + isolated 6 | sorted degrees `[5,3,3,2,2,1,0]` (vertex 4: 3 neighbors + loop 2) | pg:tests/graph.rs:1942-1979 |
| FX-13 | Iteration-order fixture | `[(0,1),(0,2),(1,4),(1,3),(5,1)]` | see O-04 | pg:tests/graph.rs:2649+ |
| FX-14 | JGraphT directed set g1-g4 | g1 {v1}; g2 v1⇄v2; g3 complete digraph on 3; g4 4-cycle 1→2→3→4→1 | edge counts 0, 2, 6, 4; g4 in = out = 1 everywhere | jgt:SimpleDirectedGraphTest.java:565-611 |
| FX-15 | Directed multi-triangle | 1→2, 2→1, 2→3, 3→1 | `edgesOf` 3,3,2; in 2,1,1; out 1,2,1 | jgt:DirectedGraphTest.java:160-170 |
| FX-16 | Petersen | GP(5,2) | 10 vertices, 15 edges, cubic, girth 5, diameter 2, radius 2, 0 triangles | jgt:test/.../generate/GeneralizedPetersenGraphGeneratorTest.java:51-57; jgt:test/.../GraphMetricsTest.java:335-344 |
| FX-17 | Cube GP(4,1) | Q3 | 8 vertices, 12 edges, cubic, bipartite, girth 4, diameter 3 | jgt:GeneralizedPetersenGraphGeneratorTest.java:37-49 |
| FX-18 | Path / ring / star / empty generators | P_n, C_n, S_n, empty(n) | Linear(10): 9 arcs, start in 0/out 1, end in 1/out 0, inner 1/1. Ring(10): 10 arcs, all 1/1, a 10-step walk returns to the start. Star `S_n`: n+1 vertices, hub 0 | jgt:GraphGeneratorTest.java:63-130; nx:TF:292-338 |
| FX-19 | K_{5,3} and small bipartite graphs | a..e each joined to f, g, h | bipartite; adding a-b breaks it | pg:tests/graph.rs:222-292 |
| FX-20 | Degree-view fixture | path_graph(6) + `add_edge(1,3)` ×2 | simple: degrees `{0:1,1:3,2:2,3:3,4:2,5:1}`; multi: `{0:1,1:4,2:2,3:4,4:2,5:1}`; directed out `{0:1,1:2,2:1,3:1,4:1,5:0}`, in `{0:0,1:1,2:1,3:2,4:1,5:1}` | nx:TRV:1018-1300 |
| FX-21 | Exhaustive small graphs | all graphs on n vertices | undirected with loops: 2^{n(n+1)/2} (n=3 → 64; without loops 8). Directed n=3: 512 with loops, 64 without. DAG counts n=0..3: 1,1,3,25 (OEIS A003024) | pg:tests/graph.rs:608-705 |

---

## 10. Property-based and randomized tests

### 10.1 petgraph quickcheck generators (`pg:src/quickcheck.rs`, `pg:tests/utils/qc.rs`)
- **Graph** (`src/quickcheck.rs:26-90`): `n = usize::arbitrary(g)` (bounded by the gen size, default 100); `edge_prob = U(0,1)·U(0,1)`, which skews toward sparse graphs. Every ordered pair (undirected: i ≤ j, so loops are included) gets an edge with probability `edge_prob`. **The result is simple: loops are possible, parallel edges are not.**
- **Shrink**: keep only the even-index vertices, or only the odd-index ones (at most 2 candidates; edges are never shrunk individually) (`:62-89`).
- **StableGraph** (`:92-163`): like Graph, then with probability ½ removes `u8 % n` random vertices to **create holes**.
- **GraphMap** (`:165-212`): arbitrary node values, sorted and deduplicated; same edge-probability scheme; no shrinking.
- `Small<T>` halves the gen size; `Tournament` puts exactly one arc of random direction between every pair, with no loops (`tests/utils/qc.rs:7-71`). `Dag` is a layered random DAG (`tests/quickcheck.rs:576-634`).

### 10.2 Container-relevant properties to port
| ID | Property | Source |
|---|---|---|
| P-01 | Consistency invariant (run after every operation): `nodeCount == vertices.count`, `edgeCount == arcs.count`, every stored arc is findable, every arc (a,b) has b in `neighbors(a)` and, if undirected, a in `neighbors(b)` | pg:tests/quickcheck.rs:108-123, 435-457 |
| P-02 | Converse swaps the in- and out-degree vectors; an undirected graph's converse is isomorphic to it | pg:tests/quickcheck.rs:100-152 |
| P-03 | `remove_edge(a,b)` for arbitrary a,b (including out-of-range): contains is symmetric when undirected; after removal it is not contained, b ∉ N(a), and a ∉ N(b) when undirected; the graph stays consistent | pg:tests/quickcheck.rs:346-394 |
| P-04 | GraphMap: `remove(a,b).isSome == contains(a,b)`; a second remove returns None (idempotent) | pg:tests/quickcheck.rs:459-477 |
| P-05 | `contains(a,b) == add_edge(a,b).returnedOld` (add reports a pre-existing edge) | pg:tests/quickcheck.rs:479-487 |
| P-06 | Random op-sequence toggle (`Vec<(u8,u8)>`): add if absent and both ends exist, otherwise remove; absence then holds in both orientations and both neighbor lists | pg:tests/quickcheck.rs:396-433 |
| P-07 | `retain_nodes` and `retain_edges`: removed count == number of predicate failures; the result is isomorphic to the `filter_map` equivalent (differential test) | pg:tests/quickcheck.rs:154-268 |
| P-08 | A random relabeling is isomorphic; changing one weight breaks weighted isomorphism | pg:tests/quickcheck.rs:270-344 |
| P-09 | Representation round trip: Graph → StableGraph → Graph preserves node, edge and endpoint sequences exactly; converting from a graph with holes compacts it while keeping relative order | pg:tests/quickcheck.rs:1106-1156 |
| P-10 | Complement of the complement equals the original (loop-free graphs only) | pg:tests/quickcheck.rs:963-988 |
| P-11 | Identity map and filter_map preserve everything; filter_map with removals drops incident edges and keeps survivor ids | pg:tests/quickcheck.rs:1158-1222 |

### 10.3 Seeded randomized tests (non-quickcheck)
- **BGL `graph.cpp`** (model-based, the most portable): `mt19937(42)`, 5 vertices, 10 rounds of {6 random `add_edge` without loops, 2 `remove_edge(u,v)`, 2 `remove_edge(e)`, 2 `add_vertex`, 4 `add_edge` touching new vertices, `clear_vertex`, `remove_vertex`}. **Invariants are checked after every operation.** The same body is compiled 9 times over {vecS, listS, setS} × {directed, bidirectional, undirected} (`bgl:test/graph.cpp:93-515`, `bgl:test/Jamfile.v2:71-79`).
- **JGraphT**: differential test with 50 seeded random graphs (20 vertices, 200 edges), checking the DAG implementation against `SimpleDirectedGraph` + `CycleDetector` (`jgt:DirectedAcyclicGraphTest.java:46-102`).
- **BGL CSR**: Erdős–Rényi graphs with `minstd_rand(42)`; checks that a copy equals the original and that rebuilding from sorted, reverse-sorted and shuffled input gives an equal graph (`bgl:test/csr_graph_test.cpp:220-290, 356-362`).

### 10.4 Swift Testing mapping
- No Hypothesis or quickcheck dependency is needed. Make the seed an argument, `@Test(arguments: 0..<100 as Range<UInt64>) func randomOps(seed:)`, so a failure is reproducible from its test-case ID. Use a SplitMix64 RNG.
- Generator: copy petgraph's (n ≤ 30, `p = U·U`, loops on) and add a **multigraph mode** (parallel edges), which petgraph's generator never produces.
- Reference model: `[V: [V]]` (multigraph) or `[V: Set<V>]` (simple). Compare after each step, as swift-collections does with its `ref` Dictionary.
- Exhaustive mode: all 512 directed graphs on 3 vertices (FX-21) as `arguments:`, with P-01, P-02 and the equality and hash laws checked on each.

---

## 11. swift-collections testing infrastructure, and how to replicate it in Swift Testing

Sources: `sc:Tests/_CollectionsTestSupport/` (about 8.5k lines; `Tests/README.md` says it is "not source stable", so copy the ideas rather than depending on it). Almost all of it is XCTest (`CollectionTestCase: XCTestCase`, `AssertionContexts/CollectionTestCase.swift:14`). Swift Testing appears only in `Tests/TrailingElementsTests/` and `Tests/DequeTests/RigidDequeCrashTests.swift` (exit tests).

### S-01 Copy-on-write
**What they do.** They test behavior, not buffer pointers. `withHiddenCopies` (`AssertionContexts/Combinatorics.swift`):
```swift
guard enabled else { return try body(&value) }
let copy = value
let expected = Array(value)
let result = try body(&value)
expectEqualElements(copy, expected, file: file, line: line)
checker(copy)
```
Every mutation test runs twice, with `withEvery("isShared", in: [false, true])`, against a stdlib reference model (`Tests/HashTreeCollectionsTests/TreeDictionary Tests.swift:512-528`; `DequeTests.swift:239-317`). OrderedDictionary also passes `checker: { $0._checkInvariants() }`, so the untouched copy is validated too. Element identity is checked with `expectIdentical(set.first, a1)` (`TreeSet Tests.swift:58-84`), and `isKnownUniquelyReferenced(&item)` confirms the container dropped its extra references (`OrderedDictionary+Values Tests.swift:113`). Internals are exposed through `_capacity` and `__unstable`, and `_checkInvariants()` is compiled only under `COLLECTIONS_INTERNAL_CHECKS` (`Sources/OrderedCollections/OrderedSet/OrderedSet+Invariants.swift:29-68`).

**Swift Testing.**
```swift
@Test(arguments: Fixtures.all, [false, true])
func removeVertex(_ f: Fixture, isShared: Bool) {
  var g = f.graph
  let before = f.graph.sortedArcs            // independent snapshot, not just ==
  withHiddenCopy(if: isShared, of: &g) { $0.remove(vertex: f.someVertex) }
  ...
}
func withHiddenCopy<G: Graph>(if on: Bool, of g: inout G,
    sourceLocation: SourceLocation = #_sourceLocation, _ body: (inout G) -> Void) {
  guard on else { return body(&g) }
  let copy = g, snapshot = copy.sortedArcs
  body(&g)
  #expect(copy.sortedArcs == snapshot, "hidden copy mutated", sourceLocation: sourceLocation)
  copy._checkInvariants()
}
```
Also add direct buffer-identity tests, which swift-collections does not have, through `@_spi(Testing) var _storageID: ObjectIdentifier`: (1) `let b = a` shares the ID; (2) mutating b changes b's ID and leaves a intact; (3) mutating a uniquely referenced value keeps its ID (no spurious copy); (4) `swap` exchanges the IDs.

### S-02 LifetimeTracked and leak checking
**What they do.** `Utilities/LifetimeTracker.swift:19-36,104-114`: `deinit { check() }`, `expectEqual(instances, 0, "Potential leak of \(instances) objects")`, and `withLifetimeTracking { tracker in ... }`. `LifetimeTracked.swift:18-34` increments the count in `init` and decrements it in `deinit`, uses `precondition(serialNumber != 0, "Double deinit")` to trap a double deinit, and forwards `Equatable`/`Hashable`/`Comparable` to its payload, so two different instances can compare equal (this tests which instance the container keeps).

**Swift Testing.** Use a `TestScoping` trait with a `@TaskLocal` tracker, not a global, because Swift Testing runs tests in parallel:
```swift
struct LeakChecked: TestTrait, TestScoping {
  func provideScope(for test: Test, testCase: Test.Case?,
                    performing body: () async throws -> Void) async throws {
    let t = LifetimeTracker()
    try await LifetimeTracker.$current.withValue(t) { try await body() }
    #expect(t.instances == 0, "leaked \(t.instances) objects")
  }
}
extension Trait where Self == LeakChecked { static var leakChecked: Self { .init() } }
@Test(.leakChecked) func removeVertexReleasesIncidentArcLabels() { ... }
```
The tracker must be `Sendable` (`Mutex`/`Atomic` from `Synchronization`). Instantiate `AdjacencyList<LifetimeTracked<Int>>` (and tracked arc labels if we have them). The priority targets are V-04/V-05/V-06 (removing a vertex with loops: catches the double-free that BGL guards against, E-08) and E-13 (removing parallel arcs).

### S-03 Conformance checkers
**What they do.**
- `checkSequence` (`ConformanceCheckers/CheckSequence.swift:22-62`) checks `underestimatedCount ≤ count`, `_copyContents` and `withContiguousStorageIfAvailable`.
- `checkCollection` (`CheckCollection.swift:62-125`) checks `index(after:)` against `formIndex(after:)`, `index(_:offsetBy:)`, `distance`, and slices over sampled ranges.
- `checkBidirectionalCollection` (`CheckBidirectionalCollection.swift:44-170`) checks backward walks against the reversed forward walk.
- `checkEquatable(equivalenceClasses:)` (`CheckEquatable.swift:51-138`) checks reflexivity, symmetry and transitivity, and validates the oracle itself ("bad oracle").
- `checkHashable` adds equal values ⇒ equal `hashValue`, `hash(into:)` and seeded `_rawHashValue(seed:)`.
- `checkComparable` checks irreflexivity and that the operators agree.

The checkers are tested against the Minimal types (`Tests/CollectionsTestSupportTests/MinimalTypeConformances.swift`).

**Swift Testing.** Port them as free generic functions taking `sourceLocation: SourceLocation = #_sourceLocation` and using `#expect(..., sourceLocation:)`, so failures point at the caller. Apply `checkCollection` to every view (`vertices`, `arcs`, `successors(of:)`, `predecessors(of:)`, `neighbors(of:)`). Apply `checkEquatable`/`checkHashable` to graph **equivalence classes**:
- `[K3 built in each of the 6 arc orders]`;
- `[graph with arc added then removed, graph never given it]`;
- each of the following in its own class: an extra isolated vertex, a reversed arc, an extra parallel arc, an extra loop.

These encode K-01 to K-07 and D-14 directly.

### S-04 Minimal and abusive types
**What they do.**
- `MinimalSequence(elements:underestimatedCount:)` (`MinimalTypes/MinimalSequence.swift:41-80`) is **single pass** (iterator state is shared), and `underestimatedCount` can be `.precise`, `.half`, `.overestimate` (a lie: `count*3+5`) or `.value(n)`.
- `MinimalCollection` plus `_CollectionState` detects stale indices (`_CollectionState.swift:14-120`).
- `MinimalEncoder`/`MinimalDecoder` give exact Codable trees: `expectEqual(try MinimalEncoder.encode(s2), .array([.int(3)]))` (`TreeSet Tests.swift:772-800`).
- `Collider` hashes only a chosen value, so collisions are forced; `RawCollider` **traps** in `hashValue` and `hash(into:)`, which proves the raw-hash path is used (`Tests/HashTreeCollectionsTests/Colliders.swift:14-95`).
- `HashableBox` is a reference-typed key. `RepeatableRandomNumberGenerator(seed:)` is an LCG; `AllOnesRandomNumberGenerator` is adversarial.

**Swift Testing.**
- Test `init(arcs:)` and `init(vertices:)` with `MinimalSequence`, using `@Test(arguments: [.precise, .half, .overestimate, .value(0)])`.
- Vertex key types: `Int`, `String`, an all-colliding `Collider`, `LifetimeTracked<Int>`, and extreme Ints (X-01).
- Swift Testing cannot parameterize over *types*, so write generic helper bodies and one thin `@Test` per key type (or one `@Suite` per type).
- If the graph has stable indices or handles, a `_CollectionState`-style generation counter lets X-09 detect stale handles.

### S-05 Combinatorics and failure traces
**What they do.**
- `withEvery(label, in:)`, `withEveryRange`, `withSome(maxSamples:)` with edge-biased samples `[0,1,c/2-1,c/2,c/2+1,c-2,c-1]`, `withEverySubset` and `withEveryPermutation` (`AssertionContexts/Combinatorics.swift`).
- Exhaustive layouts: `withEveryDeque("layout", ofCapacities: [0,1,2,3,5,10])` (`DequeTests/DequeInternals.swift:128-151`).
- `TestContext` (`AssertionContexts/TestContext.swift`) keeps a global label stack that is prepended to every failure. It caps failures at 100, `failIfTraceMatches` breaks at a pasted trace, and the global stack makes it serial-only.

**Swift Testing.**
- Parameterized `arguments:` (a cartesian product of two collections, or `zip`) replaces `withEvery`. Each case is named and can be rerun, which replaces `failIfTraceMatches`.
- Port `everyPermutation` and `everySubset` as array-returning helpers, for example: every permutation of the K3 arc list gives an equal graph; removing k edges from K4 gives size 6−k.
- Exhaustive small graphs (FX-21) are the graph analogue of `withEveryDeque`.
- Inside long loops use `try #require` so the first failure stops the run, and add context to the message: `#expect(x, "step \(i) op \(op)")`.

### S-06 Invariant checker
Expose `_checkInvariants()` behind `@_spi(Testing)` or `#if GRAFLUENT_INTERNAL_CHECKS`, and call it after every mutation (swift-collections pattern; petgraph's `assert_graph_consistent`; BGL's per-op checks). It checks:
- every out-arc u→v has a matching in-arc entry;
- `arcCount == Σ outDegree` (directed) or the handshake rule (undirected);
- undirected symmetry;
- no dangling vertex ids;
- loop bookkeeping.

### S-07 Exit tests for preconditions
`Tests/DequeTests/RigidDequeCrashTests.swift:28-35`:
```swift
@Test("Append to full deque fails")
... await #expect(processExitsWith: .failure) { ... }
```
Use this for any trapping API (an arc to a missing vertex if we trap, or a stale handle). Requires Swift 6.2 or later; runs on macOS, Linux and Windows.

### S-08 Traits and organization
- `.tags(.cow, .leak, .exhaustive, .randomized, .orderContract)`.
- `.timeLimit(.minutes(1))` on exhaustive and random suites.
- `.serialized` only where a truly global resource exists.
- `.enabled(if:)` for tests that need internal checks.
- Organize like NetworkX (one test hierarchy re-run for each graph class) and BGL (one body compiled for 9 configurations): put shared generic test bodies in a `@Suite` per `(directedness × multiplicity)` configuration, or use `@Test(arguments: GraphKind.allCases)` when the kinds are values rather than types. Like JGraphT (`SimpleIdentityDirectedGraphTest` reruns the whole suite on a different storage strategy), the same bodies should run against every storage backend we add later.

---

## 12. Licenses and porting implications

| Source | License (verified) | File | Notice requirement |
|---|---|---|---|
| NetworkX | BSD-3-Clause ("NetworkX is distributed with the 3-clause BSD license", © 2004-2026 NetworkX Developers) | `networkx/LICENSE.txt` | Keep the copyright notice and conditions in source redistributions; no endorsement using their names |
| petgraph | MIT OR Apache-2.0 (dual; `license = "MIT OR Apache-2.0"` in `Cargo.toml:16`) | `petgraph/LICENSE-MIT`, `petgraph/LICENSE-APACHE` | MIT: include the notice. Apache: the notice plus a statement of changes |
| Boost.Graph | BSL-1.0 | `graph/LICENSE` | Include the notice in source copies; **no requirement for compiled binaries** |
| JGraphT | **EPL-2.0 OR LGPL-2.1-or-later** (dual; SPDX `LGPL-2.1-or-later OR EPL-2.0`; per-file headers say `EPL-2.0 OR LGPL-2.1-or-later`). Note: "-or-later", not just 2.1 | `jgrapht/license-EPL.txt`, `jgrapht/license-LGPL.txt`, `README.md:27-45` | Copying or translating code creates a derivative work under weak copyleft (EPL: file-level; LGPL: library-level) |
| swift-collections | Apache-2.0 with Runtime Library Exception | `swift-collections/LICENSE.txt:205+` | Apache notice for copied code; same family as Swift, so it is compatible with a typical Apache-2.0 or MIT Swift package |

**Implications for this suite.**
1. **Facts are not copyrightable.** Graph definitions (K3, Petersen, the "house" DAG), expected degree sequences, edge counts and conventions are mathematical facts and API behavior. They can be restated in our own Swift tests from any source, **including JGraphT**. Good practice (not a legal requirement): cite the origin in a comment, e.g. `// Fixture from Boost.Graph test/test_graph.hpp (BSL-1.0)`.
2. **Test structure and code** (a line-by-line translation of a test method, helper function or generator) can be a derivative work.
   - BSD, MIT/Apache and BSL sources: translating is fine if we keep the notice. Put a `THIRD_PARTY_NOTICES` entry (or a header comment) in any file that is substantially translated, for example a port of petgraph's quickcheck generator or the `graph.cpp` random-ops harness.
   - Apache (petgraph option, swift-collections): also mark the file as modified. A port of `withHiddenCopies`/`LifetimeTracker` should carry the Apache notice and attribution "Portions derived from swift-collections"; reimplementing the idea from scratch carries no obligation.
3. **JGraphT: do not translate code.** Re-derive its fixtures and expected values (FX-10, FX-14, FX-15, the Q6 equality cases) as facts, and write the test code independently. Translated EPL/LGPL code would bring copyleft obligations into an otherwise permissively licensed package.
4. Copying expected values from NetworkX, petgraph or BGL with a citation is safe under all three licenses. A one-line attribution per test file and a NOTICE section listing NetworkX (BSD-3), petgraph (MIT), Boost (BSL-1.0) and swift-collections (Apache-2.0) covers the realistic cases.
5. Not legal advice. If Grafluent's own license is GPL-incompatible or unusual, recheck point 2 for Apache-2.0 (patent clause) and point 3.
