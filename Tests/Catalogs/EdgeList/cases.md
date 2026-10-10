# Test catalog: `EdgeList<Vertex: Hashable>` (a flat, mutable list of directed edges)

This catalog collects test cases for Grafluent's planned `EdgeList`, harvested from mature graph libraries and from the Swift standard library's collection contracts. Cases are grouped by behavior and deduplicated across libraries.

The type under test, as the README sketches it, is "a flat list of edges", mutable, and a `RandomAccessCollection` of `DirectedEdge<Vertex>` ("this one really is a sequence of edges"). It is Kruskal's input format. Unlike its siblings it is a *sequence*, not a set: the questions this catalog has to settle are whether repeats are kept, whether order is part of the value, and where (if anywhere) isolated vertices live.

It is a companion to `test-catalog-adjacency-list.md`, `test-catalog-adjacency-matrix.md` and `test-catalog-csr.md` in this folder. Those cover the set-based conventions (degree laws for simple digraphs, set equality, CSR canonical form). This file covers what is specific to an ordered multiset of edges.

**Sources** (shallow clones, Oct 2026):

| Library | Commit | Licence | What was used |
|---|---|---|---|
| boostorg/graph | `1ee1a99` | BSL-1.0 | `edge_list.hpp` (the `edge_list` adaptor), its doc page, `test/edge_list_cc.cpp`, `example/components_on_edgelist.cpp` + `.expected`, `kruskal_min_spanning_tree.hpp`, `example/kruskal-example.cpp` + `kruskal.expected`, `adjacency_list` `vecS`/`setS` |
| petgraph | `a4d94bd` | MIT OR Apache-2.0 | `Graph` (an edge vector with intrusive lists): `from_edges`, `extend_with_edges`, `add_edge`, `remove_edge` (swap-remove), `retain_edges`, `find_edge`, `edges_connecting`; `GraphMap::from_edges`; `algo/min_spanning_tree.rs`; `tests/min_spanning_tree.rs` |
| NetworkX | `6da4704` | BSD-3-Clause | `readwrite/edgelist.py` and its tests, `convert.py` (`from_edgelist`, `to_edgelist`), `utils/misc.py` (`edges_equal`), `MultiDiGraph`, `algorithms/tree/mst.py`, `classes/tests/test_reportviews.py` |
| igraph (C core) | `912f99d` | GPL-2.0-or-later (**behavior reference only; copy no code or fixtures**) | `igraph_create`, `igraph_read_graph_edgelist`, `igraph_write_graph_edgelist`, `igraph_delete_edges`, `igraph_is_same_graph`, `parse_utils.c`, `tests/unit/igraph_create.c`, `tests/unit/foreign_empty.c` |
| python-igraph (PyPI wheel) | 1.0.0 | GPL-2.0-or-later (behavior only) | Probed: `Graph(edges=)`, `get_edgelist`, `delete_edges`, `delete_vertices`, `Read_Edgelist`, `write_edgelist` |
| JGraphT | `63976aa` | EPL-2.0 OR LGPL-2.1-or-later | `Graphs.addAllEdges`, `KruskalMinimumSpanningTree`, `MinimumSpanningTreeTest`, `nio/csv` (`EDGE_LIST` import and export), `SparseIntGraphTest`, `IncomingOutgoingEdgesTest`, `AbstractGraph.equals` |
| rustworkx | `25398ab` (PyPI 0.18.1 for probes) | Apache-2.0 | `PyDiGraph.edge_list`, `extend_from_edge_list`, `add_edges_from_no_data`, `remove_edge`, `read_edge_list`/`write_edge_list`, the `EdgeList` sequence class (`src/iterators.rs`), `tests/digraph/test_edgelist.py` |
| scipy | `ec1861f` (PyPI 1.18.1 for probes) | BSD-3-Clause | `sparse/_coo.py` (COO is a weighted edge list that keeps duplicates), `sparse/tests/test_coo.py` |
| GAP Benchmark Suite | `2972aeb` | BSD-3-Clause | `src/reader.h` (`.el`, `.wel`, `.gr` readers), `src/builder.h`, `test/graphs/4.el`, `test/graphs/4.wel` |
| neo4j-labs `graph` | `b1d3375` | MIT | `crates/builder/src/input/edgelist.rs` (`EdgeList`, `EdgeListInput`, its parser and tests), `resources/*.el` |
| LEMON | `31d79d6` | BSL-1.0 | `kruskal.h` (sorted `(arc, cost)` sequence input), `test/kruskal_test.cc`, `StaticDigraph::build` (sorted arc list), `ListDigraph` arc order |
| swift-algorithm-club | `05c6d0b` | MIT | `Minimum Spanning Tree/` (`Graph` holds `edgeList: [Edge]`; Kruskal sorts it) |
| SwiftGraph | `6c5fb88` | Apache-2.0 | `Graph.edgeList()` |
| gonum | `0d48cee` | BSD-3-Clause | `graph/path/spanning_tree.go` (`Kruskal`) and its test fixtures |
| swift (stdlib) | `5dc8186` | Apache-2.0 with Runtime Library Exception | `Equatable.swift` (substitutability), `RangeReplaceableCollection.swift`, `MutableCollection.swift`, `Sort.swift` |
| swift-collections | `3b69ced` | Apache-2.0 | `_CollectionsTestSupport/ConformanceCheckers` (already summarised in the adjacency-list catalog §11) |
| ligra, graphblas, fixedbitset, swift-algorithms | (earlier clones) | — | Checked: no edge-list container type or edge-list I/O beyond what the CSR catalog already used. Nothing new harvested. |

**Verification.** Cases marked **(verified)** were confirmed by running probes (scratch, not kept):

- `elprobe-bgl/` — C++ against the local Boost.Graph clone (Homebrew Boost for other headers): `main.cpp` (edge_list ids, parallels, view semantics, Bellman–Ford), `kr.cpp` (Kruskal on `edge_list`, does not compile), `s.cpp` (`vecS` vs `setS`).
- `elprobe-rs/` — Rust against the local petgraph and neo4j clones: `src/main.rs`, `src/bin/nb.rs`, `src/bin/n4j.rs`.
- `elprobe-py/nxprobe.py` — NetworkX from the local clone (`PYTHONPATH=research/networkx`).
- `elprobe-py/rxprobe.py` — rustworkx 0.18.1, python-igraph 1.0.0 and scipy 1.18.1 from PyPI.
- `elprobe-gap/` — GAP's own `Reader` class on hand-made corrupt `.el` files.
- `elprobe-lemon/` — LEMON headers (`ListDigraph` order, `StaticDigraph::build` on unsorted input).
- `elfx.py` (fixture statistics) and `elkr.py` (an independent Kruskal, cross-checked against NetworkX's Kruskal *and* Prim on a `MultiGraph`) computed every expected number in §16 and §17.

**Path prefixes used in citations** (relative to the root of the upstream shallow clones, Oct 2026, not kept in the repository)

| Prefix | Expands to |
|---|---|
| `bgl-EL:` | `graph/include/boost/graph/edge_list.hpp`; `bgl-ELD:` = `graph/doc/modules/ROOT/pages/adaptors/edge_list.adoc` |
| `bgl-K:` | `graph/include/boost/graph/kruskal_min_spanning_tree.hpp`; `bgl-KX:` = `graph/example/kruskal-example.cpp` (+ `kruskal.expected`) |
| `bgl-CC:` | `graph/example/components_on_edgelist.cpp` (+ `.expected`); `bgl-ELT:` = `graph/test/edge_list_cc.cpp` |
| `pg-G:` | `petgraph/crates/petgraph/src/graph_impl/mod.rs`; `pg-M:` = `.../src/graphmap.rs`; `pg-MST:` = `.../src/algo/min_spanning_tree.rs`; `pg-MSTT:` = `petgraph/crates/petgraph/tests/min_spanning_tree.rs` |
| `nx-EL:` | `networkx/networkx/readwrite/edgelist.py`; `nx-ELT:` = `.../readwrite/tests/test_edgelist.py` |
| `nx-C:` | `networkx/networkx/convert.py`; `nx-U:` = `networkx/networkx/utils/misc.py`; `nx-MST:` = `networkx/networkx/algorithms/tree/mst.py` |
| `nx-MDG:` | `networkx/networkx/classes/multidigraph.py`; `nx-RV:` = `networkx/networkx/classes/tests/test_reportviews.py` |
| `ig-BC:` | `igraph/src/constructors/basic_constructors.c`; `ig-EL:` = `igraph/src/io/edgelist.c`; `ig-PU:` = `igraph/src/io/parse_utils.c` |
| `ig-IEL:` | `igraph/src/graph/type_indexededgelist.c`; `ig-T:` = `igraph/tests/unit/` |
| `jgt-G:` | `jgrapht/jgrapht-core/src/main/java/org/jgrapht/Graphs.java`; `jgt-AG:` = `.../graph/AbstractGraph.java` |
| `jgt-K:` | `.../alg/spanning/KruskalMinimumSpanningTree.java`; `jgt-KT:` = `jgrapht-core/src/test/java/org/jgrapht/alg/spanning/MinimumSpanningTreeTest.java` |
| `jgt-CI:` | `jgrapht/jgrapht-io/src/main/java/org/jgrapht/nio/csv/CSVEventDrivenImporter.java`; `jgt-CE:` = `.../CSVExporter.java`; `jgt-CF:` = `.../CSVFormat.java`; `jgt-CET:` = `jgrapht-io/src/test/.../csv/CSVExporterTest.java` |
| `jgt-SIT:` | `jgrapht/jgrapht-opt/src/test/java/org/jgrapht/opt/graph/sparse/SparseIntGraphTest.java`; `jgt-IO:` = `jgrapht-core/src/test/java/org/jgrapht/graph/IncomingOutgoingEdgesTest.java` |
| `rx-D:` | `rustworkx/src/digraph.rs`; `rx-I:` = `rustworkx/src/iterators.rs`; `rx-T:` = `rustworkx/tests/digraph/test_edgelist.py` |
| `sp-COO:` | `scipy/scipy/sparse/_coo.py`; `sp-COOT:` = `scipy/scipy/sparse/tests/test_coo.py` |
| `gap-R:` | `gapbs/src/reader.h`; `gap-B:` = `gapbs/src/builder.h`; `gap-TEST:` = `gapbs/test/` |
| `n4j-EL:` | `neo4j-graph/crates/builder/src/input/edgelist.rs` |
| `lem-K:` | `lemon/lemon/kruskal.h`; `lem-KT:` = `lemon/test/kruskal_test.cc`; `lem-S:` = `lemon/lemon/static_graph.h`; `lem-L:` = `lemon/lemon/list_graph.h` |
| `sac-K:` | `sac/Minimum Spanning Tree/Kruskal.swift`; `sac-G:` = `.../MinimumSpanningTree.playground/Sources/Graph.swift`; `sac-C:` = `.../MinimumSpanningTree.playground/Contents.swift` |
| `sg:` | `swiftgraph/Sources/SwiftGraph/Graph.swift`; `gn-ST:` = `gonum/graph/path/spanning_tree.go`; `gn-STT:` = `gonum/graph/path/spanning_tree_test.go` |
| `sw-EQ:` | `swift/stdlib/public/core/Equatable.swift`; `sw-RRC:` = `.../RangeReplaceableCollection.swift`; `sw-MC:` = `.../MutableCollection.swift`; `sw-SORT:` = `.../Sort.swift` |
| `AL-cat:` / `CSR-cat:` | the sibling catalogs in this folder |

Case IDs such as `EL-C07` are stable, so test names can refer to them. **Grafluent decision** marks a point where the libraries disagree and our spec has to choose. Throughout, *written* means "as given, repeats included" and *distinct* means "after duplicates collapse"; `m` is the written count.

### The API this catalog assumes (the recommendation, for reading the cases)

```swift
struct EdgeList<Vertex: Hashable>
    : RandomAccessCollection, MutableCollection, RangeReplaceableCollection,
      ExpressibleByArrayLiteral, Hashable,            // Sendable, Codable when Vertex is
      CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable
    // Element == DirectedEdge<Vertex>, Index == Int, Indices == Range<Int>

    init()                                            // RangeReplaceableCollection
    init(_ edges: some Sequence<DirectedEdge<Vertex>>)
    init(@DirectedGraphBuilder<Vertex> _: () -> ...)   // bare vertices: decision EL-C14
    init<G: DirectedGraph>(_ graph: G) where G.Vertex == Vertex   // copies graph.edges in its order

    // DirectedGraph conformance; vertices are the endpoints, in first-appearance order
    var vertices: [Vertex]                            // O(m)
    var vertexCount: Int                              // O(m)
    var edges: Self                                   // the list itself
    var edgeCount: Int                                // == count, O(1)
    func contains(_: Vertex) -> Bool                  // O(m)
    func contains(edge: DirectedEdge<Vertex>) -> Bool // O(m), Sequence.contains
    func successors(of: Vertex) -> some Collection<Vertex>   // with multiplicity, in edge order
    func predecessors(of: Vertex) -> some Collection<Vertex>
    func outDegree(of:) / inDegree(of:) / degree(of:) -> Int // O(m), multiplicity counted
    func multiplicity(of: DirectedEdge<Vertex>) -> Int       // optional; = edges(from:to:).count
    func transposed() -> EdgeList                     // each edge flipped, order kept

    mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>?   // first occurrence
    mutating func removeEdges(incidentTo: Vertex) -> Int      // Boost clear_vertex; AdjacencyMatrix's name
    // plus everything RangeReplaceableCollection and MutableCollection give for free
```

---

## 0. Cross-library convention table (read this first)

| Convention | Boost `edge_list` | petgraph `Graph` | NetworkX `MultiDiGraph` + edgelist I/O | igraph `igraph_t` | JGraphT pseudograph + CSV | rustworkx `PyDiGraph` / `EdgeList` | scipy `coo_array` | GAP `EdgeList` (`pvector<Edge>`) | neo4j `EdgeList` | LEMON `ListDigraph` / `StaticDigraph` | SAC `Graph` | Planned Grafluent |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| What it is | non-owning **view** over a caller's iterator range of pairs (bgl-EL:20-35, 300-303) | edge vector + intrusive in/out lists | dict of dicts keyed by edge key | flat `from`/`to` vectors + sort permutations | edge objects in a `LinkedHashMap` | petgraph `StableGraph`; `edge_list()` returns a read-only sequence class | `row`, `col`, `data` arrays | `pvector<EdgePair>` filled by the readers (gap-R:35, 50-57) | `Box<[(NI, NI, EV)]>` (n4j-EL:93-96) | linked lists / CSR arrays | `edgeList: [Edge<T>]` + `vertices: Set<T>` (sac-G:15-16) | an owning, copy-on-write array of `DirectedEdge` |
| Parallel edges | kept: `allow_parallel_edge_tag` (bgl-EL:295); 4 written → `num_edges` 4 (**verified**) | kept (pg-G:628); `from_edges` with `(0,1)` twice → 4 edges for 4 written (**verified**) | kept by `MultiDiGraph`, collapsed by `DiGraph` (**verified** 5 vs 4) | kept (**verified**) | kept by pseudographs; ids 5, 6, 7 for `2→4` ×3 (jgt-SIT:525) | kept by default; `multigraph=False` collapses on read, last weight wins (rx-T:150-164) | kept until `sum_duplicates` (sp-COOT:275-301; **verified** nnz 4) | kept (**verified**) | kept (**verified**) | `ListDigraph` keeps them | kept (append) | **kept**; positions distinguish them |
| Insertion order | the range's order (**verified**) | edge index order; **`remove_edge` swap-removes** (pg-G:851-874) and `retain_edges` visits in reverse (**verified**) | grouped by source in vertex-insertion order, not edge order (**verified**: `[(2,0),(1,0),(2,1)]` iterates `(2,0),(2,1),(1,0)`) | edge id = insertion order; `delete_edges` compacts in order (ig-IEL:537-545; **verified**) | insertion order (`LinkedHashMap`, notes-jgrapht.md:86) | slot order; a removed slot is **reused** by the next `add_edge` (**verified**) | kept until canonicalized (sorted by row, col) | file order | file order, but the parallel file parser appends chunks in thread-completion order (n4j-EL:205-250) | **neither**: `ArcIt` walks vertices newest-first and arcs newest-first (**verified**) | array order | **preserved and part of the value** |
| Edge identity | position (`edge_index` = offset; bgl-EL:208-216, 228, 256) | `EdgeIndex` = position, invalidated by removals | `(u, v, key)` | integer id = position | object identity | stable integer slot | position | position | position | `Arc` handle | none | position (`Int` index) |
| Isolated vertices | **not representable**: no vertex set at all (`vertex_iterator` is `void`, bgl-EL:98, 189); callers pass `N` separately (bgl-CC:59-63) | `from_edges` makes `0...max`; trailing isolated vertices impossible | in the graph yes, in the edgelist **file no** ("isolated nodes are not written", nx-ELT:258, 269, 278) | `n` parameter, "increased automatically" to max + 1 (ig-BC:33-36) | CSV: a one-field line declares a vertex (jgt-CI:239-251) | `extend_from_edge_list` makes `0...max` (rx-D:1426-1446) | `shape` | max + 1 (gap-B:322-323) | max + 1, or `with_max_node_id` (n4j-EL:99-112) | separate node set | **no**: vertices are only inserted by `addEdge` (sac-G:33-41) | **not stored**; vertices are the endpoints |
| `==` | none | none (no `PartialEq` on `Graph`) | identity; helper `edges_equal` is **multiset**, order-free (nx-U:555-633) | `igraph_is_same_graph`: multiset, order-free (ig-IEL:1916-1990); Python `==` is identity (**verified**) | `AbstractGraph.equals`: edge objects + endpoints, order-free (jgt-AG:250-285) | `EdgeList.__eq__`: **ordered, element-wise**, also against a plain list (rx-I:520-547; **verified**) | value comparison after summing duplicates (**verified**: two COO arrays with permuted entries compare equal) | none | none | none | none | **ordered, element-wise** (like `Array`) |
| Hash | — | — | — | — | Java `hashCode` of the graph | ordered (rx-I:558-562) | unhashable | — | — | — | — | ordered |
| `contains(u, v)` | none; caller scans | `find_edge` O(out-degree), returns the **newest** parallel edge (**verified** id 1 of 0, 1) | O(1) dict | `get_eid` binary search | O(1) | O(out-degree) | — | — | — | — | — | **O(m)** scan |
| Degree | none | O(degree) | O(degree), counts multiplicity | O(1) from offsets | O(1) | O(degree) | — | `CountDegrees` O(m) scan (gap-B:80) | `degrees()` O(m) scan of the list (n4j-EL:61-77) | O(degree) | — | **O(m)** scan |
| Remove by endpoints | — | — | `remove_edge(u, v)` removes the **last-added** parallel (nx-MDG:535; **verified**) | by id or selector | `removeEdge(u, v)` removes **one** (notes-jgrapht.md:113) | `remove_edge(u, v)` removes **one, the newest** (rx-D:1563-1580; **verified**) | — | — | — | — | — | `remove(edge:)` removes the **first** occurrence (Swift's `firstIndex(of:)`) |
| Remove a vertex | — | removes incident edges, swap-removes the vertex (**verified**) | removes incident edges (**verified**) | removes incident edges, renumbers vertices (**verified**) | removes incident edges | removes incident edges, ids stable (**verified**) | — | — | — | — | — | `removeEdges(incidentTo:)`; no renumbering (vertices are values) |
| Text format | — | — | `u v [data]`, `#` comments, skips lines with < 2 tokens (nx-EL:282-293) | whitespace-separated integers, even count, no comments (ig-EL:46-55) | CSV, mixed edge/adjacency lines (jgt-CF:24-60) | `u v [weight]`, optional comment string (rx-D:2515-2585) | — | `u v` pairs read by `>>`, **stops silently at the first bad token** (gap-R:50-57; **verified**) | `u<1 byte>v\n`, **panics** on anything else (**verified**) | LGF | — | `Codable` only; text readers belong to `GraphFormats` |

The main points:

- **Every library that stores a flat list of edges keeps parallel edges and keeps them at distinct positions.** Collapsing happens only in containers that are sets (NetworkX `DiGraph`, petgraph `GraphMap`, Boost `setS`, rustworkx `multigraph=False`, Grafluent's own `AdjacencyList`).
- **No library both preserves insertion order under removal and gives a structural `==`.** Boost and scipy preserve order but have no graph equality. rustworkx's `EdgeList` has ordered equality but is a read-only snapshot of a graph whose own order is not preserved under removal. Grafluent's "an `EdgeList` *is* an `Array` of edges with graph queries" is closest to the Swift Algorithm Club's `[Edge]` and to igraph's `from`/`to` vectors.
- **No flat edge list represents isolated vertices.** Boost's adaptor has no vertex set at all; igraph, GAP, neo4j and petgraph infer `max + 1` for integer ids and take an explicit count otherwise; NetworkX's file format drops them silently. Only JGraphT's CSV dialect can write one, and only because it mixes in adjacency-list lines.

---

## 1. Construction (`EL-C`)

### 1a. Empty and literal forms

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-C01 | `EdgeList()` is empty: `count == 0`, `isEmpty`, `startIndex == endIndex == 0`, `vertices == []`, `vertexCount == 0`, `edgeCount == 0` | `DirectedFixture.empty` | igraph: an empty edge-list file gives 0 vertices (ig-T:`foreign_empty.c`:36-39); rustworkx `test_empty_edge_list_digraph` (rx-T:21-24). Contrast: neo4j turns an empty list into **1** vertex (**verified** `n=1 m=0`; CSR-cat C03) |
| EL-C02 | Array literal: `let e: EdgeList<Int> = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]` equals `EdgeList([0→1, 1→2])` | `directedPath3` | README "ExpressibleByArrayLiteral (edge lists …)" |
| EL-C03 | The empty literal `[]` equals `EdgeList()` | — | `ExpressibleByArrayLiteral` law |
| EL-C04 | A literal keeps repeats and order verbatim: `[1→3, 1→3]` has `count == 2`, `[0] == [1]` | `pathWithChord` (7 written) → `count == 7` | parallel edges kept everywhere a list is stored (§0) |

### 1b. From sequences

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-C05 | `EdgeList(fixture.edges)` has `count == fixture.edges.count` (written), and `Array(list) == fixture.edges` element for element, for every fixture | every `DirectedFixture.all` and `.realWorld` (§17a lists written counts: e.g. `selfLoopsAndDuplicates` 8, `jgraphtSparseDirected` 13, `gap4` 256, `graph500Scale8` 4096) | petgraph `from_edges` keeps all 4 of 4 (**verified**); Boost `num_edges == distance(first, last)` (bgl-EL:302) |
| EL-C06 | A single-pass input sequence (an `AnyIterator`, or `MinimalSequence` from `GrafluentTestSupport`) is read exactly once and gives the same list | `boostCsrUnsorted` through `MinimalSequence` | Boost has separate single-pass and multi-pass constructors (CSR-cat C35); petgraph `extend_with_edges` reserves from `size_hint().0` then iterates once (pg-G:1505-1523) |
| EL-C07 | A lazy sequence (`(0..<10).lazy.map { DirectedEdge(from: $0, to: ($0 + 1) % 10) }`) gives `directedCycle10` in order | `directedCycle10` | — |
| EL-C08 | Construction does **not** reorder: unsorted input stays unsorted | `boostCsrUnsorted` → `[5→0, 3→2, 4→1, 4→0, 0→2, 5→2]` exactly | Boost `edge_list` iterates the range as given (**verified** `e0=0->1 e1=0->1 e2=1->1 e3=2->0`); contrast CSR (CSR-cat C06), LEMON `StaticDigraph`, which **requires** sorted input (lem-S:385-402) |
| EL-C09 | Construction does not collapse: `EdgeList(jgraphtSparseDirected.edges)` contains `2→4` at positions 5, 6 and 7 | `jgraphtSparseDirected` | JGraphT gives exactly ids `{5, 6, 7}` to the three `2→4` edges (jgt-SIT:525); Grafluent positions match JGraphT's ids because both number by input order |
| EL-C10 | Self-loops are kept as ordinary elements | `petgraphCsr1` → positions 0, 2, 5 are loops (`0→0`, `2→2`, `1→1`) | — |
| EL-C11 | `EdgeList(other)` from a `DirectedGraph` copies `other.edges` in `other.edges`' order (whatever it is) and has `count == other.edgeCount` | `AdjacencyList(house)` → 7 edges, each in `house`; `CompressedSparseRow(house)` → row-major `[1→0, 2→1, 3→2, 3→4, 4→0, 4→1, 5→3]` | rustworkx `edge_list()` reflects graph order (rx-D:1009-1024); SwiftGraph `edgeList()` walks vertices in index order (sg:50-64) |
| EL-C12 | `init(repeating:count:)` (from `RangeReplaceableCollection`) makes `count` parallel copies | `EdgeList(repeating: 0→1, count: 3)` → `count == 3`, `multiplicity(of: 0→1) == 3`, `vertices == [0, 1]` | stdlib RRC default |
| EL-C13 | `reserveCapacity(_:)` then appends: contents equal the un-reserved build (capacity itself is a benchmark property) | 10,000 appends | petgraph reserves on `extend_with_edges` (pg-G:1513-1514) |

### 1c. Builder

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-C14 | **Grafluent decision: bare vertex statements in `@DirectedGraphBuilder`.** `EdgeList { 0; DirectedEdge(from: 1, to: 2) }`: the builder hands over `content.vertices == [0]`, which an edge list cannot store. Options: (a) trap (precondition), (b) ignore silently, (c) a separate edge-only builder so it does not compile. Recommend (c) if the builder can be specialized cheaply, else (a); never (b) | `boostExample` (lists `0`), `scipyConstructor2` (lists `0, 1, 2, 5`) | Ignoring is what NetworkX's reader does with a one-token line (nx-EL:291-293; **verified** `["1"]` → empty graph); JGraphT keeps the vertex (jgt-CI:239-251); rustworkx **panics** (**verified**); igraph errors (**verified**) |
| EL-C15 | Builder with `for`, `if`, `switch` gives edges in statement order, repeats included | `pathWithChord`'s builder → 7 edges, `[5] == [6] == 1→3` | `DirectedGraphBuilder.buildArray` concatenates in order (Sources/GraphProtocols/DirectedGraphBuilder.swift) |
| EL-C16 | An empty builder body gives `EdgeList()` | `DirectedFixture.empty` | — |

### 1d. String and reference vertices

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-C17 | `String` vertices | `networkXABCD` → 5 edges; `vertices == ["A", "B", "C", "D"]` (G, J, K are lost, EL-V05) | NX `test_digraph_historical.py` (AL-cat) |
| EL-C18 | `Collider` vertices (all hash equal): construction and `contains(edge:)` still exact | 20 edges over 10 colliding vertices | AL suite `VertexTypeTests` |
| EL-C19 | Equal-but-distinct reference instances are stored as given (no canonicalization): `list[0].source === a1`, `list[1].source === a2` when `a1 == a2` | `HashableBox` / `LifetimeTracked` | Contrast `AdjacencyList`, which keeps the first stored instance (AL README "Equal-but-distinct vertex instances"). An `Array` stores what it is given |
| EL-C20 | Extreme `Int` vertices (`.min`, `.max`, negative) are ordinary values; nothing infers `max + 1` | `[Int.min → Int.max]` → `vertices == [Int.min, Int.max]` | igraph rejects negative ids (ig-BC:59-61; **verified**); GAP and rustworkx assume non-negative ints. Grafluent vertices are `Hashable`, not indices |

---

## 2. Vertices implied by endpoints (`EL-V`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-V01 | `vertices` is the set of endpoints, each once, in **first-appearance order** (source before target within an edge) | `house` → `[5, 3, 4, 2, 0, 1]`; `boostCsrUnsorted` → `[5, 0, 3, 2, 4, 1]`; `scc9` → `[6, 0, 3, 8, 2, 5, 7, 1, 4]` | NetworkX `MultiDiGraph(edges)` orders nodes by first appearance (**verified**: `[(1,2),(0,1),…]` gives nodes `1, 2, 0, 3`); rustworkx `labels=True` assigns indices in first-appearance order (rx-D:2541-2558) |
| EL-V02 | `vertexCount == Set(vertices).count == vertices.count` | every fixture: §17a "endpoint vertices" column | — |
| EL-V03 | `contains(_ vertex:)` is true exactly for endpoints | `petgraphCsrFrom`: `contains(3) == false` (3 is listed isolated), `contains(4) == true` | — |
| EL-V04 | A self-loop's vertex appears once | `singleSelfLoop` → `vertices == [0]` | — |
| EL-V05 | Isolated vertices of a fixture are **not** present, so `vertexCount` can be smaller than `fixture.vertexCount` | `trivial` 1 → 0; `isolatedVertices` 10 → 0; `networkXFunctionGraph` 5 → 4; `scipyConstructor2` 6 → 2; `networkXABCD` 7 → 4; `gap4` 14 → 13 (vertex 5); `graph500Scale8` 256 → 241; `ligraRMat` 128 → 125 (1, 5, 40) | Boost `components_on_edgelist` needs `N = 6` from outside because vertex 3 is in no edge, and still reports it as its own component (bgl-CC:59-63, `.expected`); NetworkX: "isolated nodes are not written in edgelist" (nx-ELT:258) |
| EL-V06 | Removing the last edge incident to `v` removes `v` from `vertices` | `[0→1, 1→2]`, `remove(at: 0)` → `vertices == [1, 2]` | Consequence of EL-V01; contrast `AdjacencyList`, where vertices outlive their edges (AL-cat §2), and igraph "vertices will be kept even if they lose all their edges" (ig-IEL:486-487) |
| EL-V07 | `removeEdges(incidentTo: v)` can make *other* vertices disappear too | `selfLoopsAndDuplicates`, `removeEdges(incidentTo: 2)` → returns 4, list `[4→4, 5→5, 5→5]`, `vertices == [4, 5]` (1 and 3 had no other edges) | derived |
| EL-V08 | `vertices` is a value: mutating the list afterwards does not change an array already read | — | — |
| EL-V09 | **Grafluent decision recorded by a test:** there is no `insert(_ vertex:)` and no `init(vertices:edges:)`. Conversions that need isolated vertices take them as an argument (EL-X04, EL-X08) | — | Boost passes `N` (bgl-CC:63-68); igraph passes `n` (ig-BC:33-36); neo4j `with_max_node_id` (n4j-EL:106-112). §18 Q-d gives the reasoning |
| EL-V10 | `vertices` on 10⁵ edges over 10³ vertices is correct (O(m) with one hash set; timing belongs to benchmarks) | seeded random | — |

---

## 3. Parallel edges and self-loops (`EL-M`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-M01 | Parallel edges occupy distinct positions and compare equal as elements | `jgraphtSparseDirected`: `list[5] == list[6] == list[7] == 2→4` | JGraphT ids 5, 6, 7 (jgt-SIT:525) |
| EL-M02 | `multiplicity(of:)` (or `filter { $0 == e }.count`) | `gap4`: `0→0` 27, `0→8` 21, `0→7` 21; `graph500Scale8`: `82→82` 42, `82→231` 39; `jgraphtSparseDirected`: `2→4` 3 | `elfx.py` |
| EL-M03 | `Set(list).count` is the distinct count | `gap4` 58; `graph500Scale8` 2171; `selfLoopsAndDuplicates` 6; `pathWithChord` 6; `jgraphtSparseDirected` 11 | GAP's own reference "53 directed edges" is after deleting loops too (CSR-cat C16) |
| EL-M04 | Degrees count multiplicity: `outDegree(of: v) == list.filter { $0.source == v }.count` | `jgraphtSparseDirected` out `[0:1, 1:4, 2:3, 3:1, 4:1, 5:1, 6:0, 7:2]`, in `[0:1, 1:1, 2:0, 3:0, 4:5, 5:2, 6:3, 7:1]` | exactly JGraphT's multigraph assertions (jgt-SIT:422-472) |
| EL-M05 | Same, with self-loops in the duplicates | `selfLoopsAndDuplicates` out `[1:1, 2:3, 3:0, 4:1, 5:3]`, in `[1:0, 2:2, 3:2, 4:2, 5:2]` | exactly JGraphT's `DirectedPseudograph` assertions (jgt-IO:116-132); the `DirectedFixture` degrees are the re-derived simple ones |
| EL-M06 | Same for a duplicated chord | `pathWithChord`: `outDegree(of: 1) == 3`, `inDegree(of: 3) == 3` | NetworkX `TestOutMultiDegreeView` `dv[1] == 3` and `TestInMultiDegreeView` `dv[3] == 3` (nx-RV:1295, 1347) |
| EL-M07 | A self-loop contributes 1 to `outDegree`, 1 to `inDegree`, 2 to `degree`, and a repeated self-loop counts each time | `selfLoopsAndDuplicates`: `degree(of: 5) == 5` (out 3 + in 2) | sibling convention (AL README); NetworkX `MultiDiGraph` `degree(2) == 4` for `(1,2),(1,2),(2,2)` (**verified**) |
| EL-M08 | `successors(of:)` lists a target once per parallel edge, in edge order | `selfLoopsAndDuplicates`: `successors(of: 5) == [5, 2, 5]`; `jgraphtSparseDirected`: `successors(of: 2) == [4, 4, 4]` | petgraph `neighbors(0) == [2, 1, 1]` for `(0,1),(0,1),(0,2)` (repeats, newest first; **verified**). Contrast NetworkX `MultiDiGraph.successors(1) == [2]` while `out_degree(1) == 2` (**verified**), so its `count != degree` |
| EL-M09 | Collapsing is a conversion, not a mutation: `AdjacencyList(edges: list).edgeCount == Set(list).count` and the list is unchanged | `gap4` → 58, list still 256 | NetworkX `DiGraph(edges)` collapses (**verified** 4 of 5); petgraph `GraphMap::from_edges` collapses with **last weight wins** (**verified** `w(0,1) = 11`) |

---

## 4. Order and identity (`EL-O`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-O01 | Iteration order is insertion order, for every fixture | `Array(EdgeList(f.edges)) == f.edges` | Boost (**verified**), igraph `get_edgelist` "order of the edges is given by the edge IDs" (igraph `src/misc/conversion.c`:310), JGraphT `LinkedHashMap` (notes-jgrapht.md:86) |
| EL-O02 | `append` puts the edge at `endIndex - 1`; existing positions are unchanged | — | stdlib `append` |
| EL-O03 | `remove(at: i)` shifts later edges down by one and keeps their relative order (Array semantics), **not** swap-remove | `[a, b, c, d].remove(at: 0)` → `[b, c, d]` | petgraph swap-removes: removing edge 0 of `[0→1, 0→1, 1→1, 4→0]` gives `[4→0, 0→1, 1→1]` (**verified**; "invalidates the last edge index", pg-G:851, 874). igraph compacts in order (**verified** `[(0,1),(1,1),(3,0)]`) |
| EL-O04 | `removeAll(where:)` keeps survivors in order | `[0→1, 1→2, 2→3, 3→4, 4→5]`, keep even-weighted (positions 1, 3) → `[1→2, 3→4]` | petgraph `retain_edges` gives `[3→4, 1→2]`, **reversed** (**verified**; "the order edges are visited is not specified", pg-G:1447). Swift's `removeAll(where:)` uses `_halfStablePartition`, which keeps the survivors' order (sw-RRC:1164-1167) |
| EL-O05 | A removal followed by an append puts the new edge at the end, never in the freed slot | remove index 0 of `[0→1, 1→2, 2→3]`, append `3→0` → `[1→2, 2→3, 3→0]` | rustworkx reuses the slot: result `[(3,0), (1,2), (2,3)]` with indices `[0, 1, 2]` (**verified**) |
| EL-O06 | Order is part of the value: `EdgeList([a, b]) != EdgeList([b, a])` when `a != b` | `[0→1, 1→2]` vs `[1→2, 0→1]` | rustworkx `EdgeList == list` is element-wise (rx-I:525-547; **verified** `False` for a permutation) |
| EL-O07 | Positions are the edge identities: for each `i`, `list[i]` is "edge i"; there is no separate edge id | `boostKruskal` (§17b) position 2 is `1→4` | Boost `edge_list` RA specialization: `edge_descriptor` *is* the position, `source(e) = g._first[e].first` (bgl-EL:183, 208, 216) |
| EL-O08 | Order is independent of hashing: two lists built from the same input with different hash seeds (separate processes are impractical; instead use `Collider` vertices vs `Int` vertices of the same shape) iterate identically | — | guards against an implementation backed by a `Dictionary` |

---

## 5. `RandomAccessCollection` laws, indices and slicing (`EL-L`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-L01 | `Index == Int`, `startIndex == 0`, `endIndex == count`, `indices == 0..<count` | every fixture | README: "RandomAccessCollection of DirectedEdge" |
| EL-L02 | `index(_:offsetBy:)` and `distance(from:to:)` are O(1) and agree with `Int` arithmetic, including negative offsets and `limitedBy:` | `boost24` (43 edges): `index(0, offsetBy: 43) == endIndex`; `index(5, offsetBy: 40, limitedBy: 43) == nil` | `checkBidirectionalCollection` laws (swift-collections ConformanceCheckers; AL-cat S-03) |
| EL-L03 | `index(after:)`/`index(before:)` round trip over the whole range | every fixture | same |
| EL-L04 | Multi-pass: iterating twice gives the same sequence; `first`, `last`, `count`, `underestimatedCount == count` | every fixture | `checkSequence` |
| EL-L05 | `subscript(i)` equals the i-th element of `Array(list)` | every fixture | — |
| EL-L06 | Slicing: `list[2..<5]` has `startIndex == 2` and shares indices with the base (Array/ArraySlice style), `Array(slice) == Array(list)[2..<5]` | `house` | stdlib `Slice`/`ArraySlice` index sharing |
| EL-L07 | Every slice of every fixture of ≤ 13 edges satisfies the collection laws (all `O(m²)` ranges) | `jgraphtSparseDirected`, `boostWebGraph` | the CSR suite's "every slice of `edges`" test (CSR README) |
| EL-L08 | `EdgeList(list[2..<5])` makes an independent list re-indexed from 0 | `house` → `[3→2, 4→0, 4→1]` | — |
| EL-L09 | Empty slices at `startIndex`, in the middle and at `endIndex` | — | — |
| EL-L10 | Stdlib `reversed()` reverses **order** and keeps each edge's direction | `directedPath3.reversed()` → `[1→2, 0→1]` | `BidirectionalCollection.reversed()`. **Naming hazard**: the README's graph operation `reversed` (every edge flipped) collides with this; see EL-Q12 and §19 |
| EL-L11 | `firstIndex(of:)` / `lastIndex(of:)` find the first and last parallel copy | `jgraphtSparseDirected`: `firstIndex(of: 2→4) == 5`, `lastIndex(of: 2→4) == 7` | — |
| EL-L12 | `firstIndex(where:)` on a missing edge returns `nil` | — | — |
| EL-L13 | `withContiguousStorageIfAvailable` (or a `span` property) is non-nil and its buffer equals `Array(list)` | `boost24` | README principle 3 ("one allocation per value", `Span`) |
| EL-L14 | `Sendable`: a list can be sent to a task and read there | — | README: every representation is `Sendable` when its vertex type is |
| EL-L15 | `elementsEqual` with the fixture's array; `starts(with:)` on a prefix | — | — |
| EL-L16 | `Indices` stay valid (same positions, same elements) across any non-mutating operation and across a *copy's* mutation | — | value semantics |

---

## 6. `MutableCollection`, sorting and swapping (`EL-S`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-S01 | `list[i] = e` replaces in place; `count` unchanged; other positions unchanged | `house[0] = 0→5` | `MutableCollection` |
| EL-S02 | Element mutation through the subscript: `list[i].target = v` | `directedPath3[1].target = 0` → `[0→1, 1→0]` | `_modify` accessor (README principle 3) |
| EL-S03 | `swapAt(i, j)` exchanges two edges; `swapAt(i, i)` is a no-op | `[a, b, c].swapAt(0, 2)` → `[c, b, a]` | sw-MC:174, 322 |
| EL-S04 | `sort(by:)` by `(source, target)` for `Comparable` vertices | `boostCsrUnsorted` → `[0→2, 3→2, 4→0, 4→1, 5→0, 5→2]` | CSR construction and Kruskal both start by sorting edges; GAP sorts its edge list for the in-place build (gap-B:200) |
| EL-S05 | Sort **stability** by source only: equal sources keep input order | `boostCsrUnsorted` sorted by `source` → `[0→2, 3→2, 4→1, 4→0, 5→0, 5→2]` (`4→1` stays before `4→0`) | Swift's sort "is guaranteed to be stable" (sw-SORT:40); NetworkX Kruskal relies on Python's stable `sorted` (nx-MST:220); JGraphT on `List.sort` (jgt-K:59). gonum uses `slices.SortFunc`, **not** stable (gn-ST:167) |
| EL-S06 | Sorting a list with duplicates keeps all copies adjacent | `gap4` sorted by `(source, target)`: first 27 elements are `0→0`, last is `13→13` | `elfx.py` |
| EL-S07 | `reverse()` (in place) equals `reversed()` | — | — |
| EL-S08 | `partition(by: \.isSelfLoop)` puts loops after the pivot; multiset unchanged | `petgraphCsr1` → 3 non-loops then 3 loops | stdlib `partition` (unstable: test only the multiset and the predicate split) |
| EL-S09 | `shuffle(using: &SeededRandomNumberGenerator)` keeps the multiset; equal seeds give equal orders | `boost24` | `GrafluentTestSupport/SeededRandomNumberGenerator.swift` |
| EL-S10 | `sort(by:)` on a copy leaves the original untouched (CoW) | — | value semantics |
| EL-S11 | **Grafluent decision:** no `sort()` without arguments, because `DirectedEdge` is not `Comparable`. If one is added (`where Vertex: Comparable`), it must be lexicographic `(source, target)` and agree with EL-S04 | — | `DirectedEdge` declares only `Hashable` (Sources/GraphProtocols/DirectedEdge.swift) |
| EL-S12 | Swapping through two slices (`list[0..<2].swapAt(0, 1)` via `withSubrange`-style mutation) writes back to the base | — | `MutableCollection` slice `_modify` |

---

## 7. `RangeReplaceableCollection` mutation (`EL-R`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-R01 | `append(_:)`, `append(contentsOf:)` | build `directedCycle10` by appends == from the array | — |
| EL-R02 | Appending an edge already present adds a parallel copy (no `inserted: false`) | `[0→1].append(0→1)` → `count == 2` | Contrast `AdjacencyList.insert(edge:)` (AL README "Parallel edges"); petgraph `add_edge` vs `update_edge` (pg-G:628, 698) |
| EL-R03 | `insert(_:at:)` at 0, middle and `endIndex` | `[a, c].insert(b, at: 1)` → `[a, b, c]` | — |
| EL-R04 | `insert(contentsOf:at:)` | — | — |
| EL-R05 | `remove(at:)` returns the removed edge | `selfLoopsAndDuplicates.remove(at: 4)` → `4→4`; list `[1→2, 2→3, 2→3, 2→4, 5→5, 5→2, 5→5]` | — |
| EL-R06 | `removeFirst()`, `removeFirst(k)`, `removeLast()`, `removeLast(k)`, `popLast()` (`nil` on empty) | — | stdlib |
| EL-R07 | `removeSubrange(_:)` and `replaceSubrange(_:with:)` with shorter, equal and longer replacements | replace `house[1..<3]` with `[]`, with 2 edges, with 5 edges | the one primitive RRC requires |
| EL-R08 | `removeAll(keepingCapacity:)` gives `== EdgeList()` (both values of the flag) | — | holds only because the list has no hidden vertex set (Q-d) |
| EL-R09 | `removeAll(where:)` removes every match, keeps the rest in order | `petgraphCsr1.removeAll(where: \.isSelfLoop)` → `[1→2, 0→2, 1→0]`; `jgraphtSparseDirected.removeAll { $0 == 2→4 }` → 10 edges | sw-RRC:1164-1167 |
| EL-R10 | `remove(edge:)` removes the **first** occurrence only and returns it; `nil` when absent | `selfLoopsAndDuplicates.remove(edge: 2→3)` → returns `2→3`, list `[1→2, 2→3, 2→4, 4→4, 5→5, 5→2, 5→5]` (position 1 removed, not 2) | **Grafluent decision.** NetworkX removes the **last-added** (nx-MDG:535; **verified**: keys 0, 1 remain of 0, 1, 2); rustworkx removes the newest (`find_edge` is LIFO; **verified** indices `[0, 1, 3]` remain); JGraphT removes one (notes-jgrapht.md:113); Boost `remove_edge(u, v)` removes **all** (AL-cat §0). Recommend first, matching `firstIndex(of:)` |
| EL-R11 | `remove(edge:)` of an absent edge, or with absent endpoints, returns `nil` and changes nothing (no trap) | `house.remove(edge: 0→5)` → `nil` | sibling convention (AL README "Removing something absent") |
| EL-R12 | Removing all copies of an edge is `removeAll { $0 == e }`, and the return count (via `count` before/after) is the multiplicity | `gap4`, remove all `0→0` → 229 left | — |
| EL-R13 | `removeEdges(incidentTo: v)` removes every edge with `v` as source or target (self-loops once) and returns how many | `gap4`, `removeEdges(incidentTo: 0)` → removes out 153 + in 27 − loops 27 = 153 + 27 − 27 = **153** edges; 103 remain | name from `AdjacencyMatrix.removeEdges(incidentTo:)` (AM README), i.e. Boost's `clear_vertex`. NetworkX, petgraph, igraph and rustworkx `remove_node` all drop incident edges (**verified** each) |
| EL-R14 | `removeEdges(incidentTo:)` keeps survivors in order and does not renumber vertices | `[0→1, 2→3, 1→2, 3→0]`, incident to 1 → `[2→3, 3→0]` | igraph renumbers survivors to `[(1,2),(2,0)]` (**verified**); petgraph swap-removes the vertex so `3` becomes `1` (**verified** `[1->0, 2->1]`). Hashable vertices have nothing to renumber |
| EL-R15 | `removeEdges(incidentTo:)` for a vertex not present returns 0 | — | — |
| EL-R16 | Mutating while iterating a copy: `for e in list { list.append(e.transposed) }` terminates and doubles the count (the loop iterates the original value) | `directedPath3` → 4 edges | AL suite "mutating while iterating" |
| EL-R17 | `+`, `+=` with another `EdgeList` and with an `Array` of edges | `directedPath3 + directedPath3` → 4 edges, every edge multiplicity 2 | RRC operators |
| EL-R18 | Index validity after mutation (documented, tested by values not by stale indices): after `remove(at: i)`, index `j > i` refers to the old `j + 1`; after `append`, every old index still refers to the same edge | — | "Calling this method may invalidate any existing indices" (sw-RRC:98, 207, 233 …); petgraph documents a different rule (only the last index moves, pg-G:851) |
| EL-R19 | **API-shape test:** there is no `insert(edge:) -> (inserted:, memberAfterInsert:)` on `EdgeList` (it would always say `true` and invite set semantics) | — | Grafluent decision; §18 Q-e |

---

## 8. Graph queries (`EL-Q`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-Q01 | `contains(edge:)` is true for every element and false for every other pair over `vertices × vertices` | `boost24`, `jgraphtSparseDirected`, `petgraphCsr1` | CSR-cat L01 pattern |
| EL-Q02 | `contains(edge:)` with endpoints that are not vertices is `false` (no trap) | `house.contains(edge: 9→0)` | sibling convention |
| EL-Q03 | `contains(edge:)` distinguishes direction | `directedPath3`: `0→1` yes, `1→0` no | igraph `is_same_graph` doc example (ig-IEL:1930-1937) |
| EL-Q04 | `edgeCount == count` | every fixture | — |
| EL-Q05 | `successors(of:)` / `predecessors(of:)` in edge order with multiplicity | `house`: `successors(of: 3) == [4, 2]`, `predecessors(of: 1) == [4, 2]`; `jgraphtSparseDirected`: `predecessors(of: 4) == [1, 2, 2, 2, 3]` | EL-M08 |
| EL-Q06 | `successors(of: v).count == outDegree(of: v)` and `predecessors(of: v).count == inDegree(of: v)` for every vertex of every fixture | all | the identity NetworkX's `MultiDiGraph` breaks (**verified**, EL-M08) |
| EL-Q07 | `Σ outDegree == Σ inDegree == count` and `Σ degree == 2 · count`, over `vertices` | every fixture, including `gap4` (256) and `graph500Scale8` (4096) | handshake lemma with multiplicity; AL-cat degree-sum cases |
| EL-Q08 | Degrees of a vertex that is not an endpoint: **Grafluent decision.** `AdjacencyList` traps for an absent vertex. An edge list has no vertex set to be absent from, and the check itself is O(m). Recommend: return 0 / empty, no trap, and document it | `house.outDegree(of: 42) == 0` | petgraph returns an empty neighbor list for an absent node (AL README, "Successors, predecessors or degree of an absent vertex"); NetworkX raises `KeyError`. Recorded as a deliberate difference from the sibling |
| EL-Q09 | Hub degrees: one vertex with out-degree 20,000 in a shuffled list | `outDegree(of: hub) == 20000` | CSR suite's shuffled hub (CSR README) |
| EL-Q10 | Real-data multigraph degrees | `gap4`: out `[153, 0, 6, 8, 1, 0, 0, 23, 37, 9, 1, 0, 1, 17]`, in `[27, 14, 14, 12, 23, 0, 5, 33, 23, 33, 9, 9, 13, 41]`; `graph500Scale8`: `outDegree(of: 82) == 871`, `outDegree(of: 0) == 2`, `inDegree(of: 0) == 14` | `elfx.py`; neo4j's Graph500 test expects in0 with repeats, 14 entries (CSR-cat T08) |
| EL-Q11 | `edges` is the list itself: `list.edges.elementsEqual(list)` and has the same indices | — | README: "this one really is a sequence of edges" |
| EL-Q12 | `transposed()` flips every edge and **keeps order** | `house.transposed()` → `[3→5, 4→3, 2→3, 0→4, 1→4, 1→2, 0→1]`; `transposed().transposed() == list`; loops unchanged | Name from the README's "materialized" row (`transposed()`, as CSR and AM). The lazy `reversed` view would collide with `BidirectionalCollection.reversed()` (EL-L10) |
| EL-Q13 | `transposed()` swaps degrees: `t.outDegree(of: v) == inDegree(of: v)` | every fixture | — |
| EL-Q14 | Self-loop queries | `petgraphEdgesDirected`: `contains(edge: 6→6)`, `successors(of: 6) == [6]`, `degree(of: 6) == 2` | — |
| EL-Q15 | `multiplicity(of:)` (if offered) equals `filter { $0 == e }.count` and is 0 for absent edges | EL-M02 values | JGraphT `getAllEdges(u, v)` (jgt-SIT:515-536); NetworkX `number_of_edges(u, v) == 2` (**verified**) |

---

## 9. Conversions and round trips (`EL-X`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-X01 | `AdjacencyList(edges: list)` collapses: `edgeCount == Set(list).count`, `vertexCount == list.vertexCount` | `gap4` → 58 edges, 13 vertices; `graph500Scale8` → 2171, 241 | NetworkX `DiGraph(edges)` (**verified**) |
| EL-X02 | `AdjacencyList(edges: list) == AdjacencyList(edges: list.shuffled())` and `== AdjacencyList(edges: Array(Set(list)))` | every fixture | conversion forgets order and multiplicity |
| EL-X03 | `EdgeList(adjacencyList)` has `edgeCount == g.edgeCount`, no repeats, and `AdjacencyList(edges: EdgeList(g)) == g` **when g has no isolated vertices** | every fixture without isolated vertices (§17a) | NetworkX `identity_conversion` pattern (CSR-cat C31) |
| EL-X04 | With isolated vertices: `AdjacencyList(vertices: g.vertices, edges: EdgeList(g)) == g` | `networkXABCD`, `petgraphCsrFrom`, `scipyConstructor2`, `isolatedVertices` | Boost's `N` argument (bgl-CC:63-68); igraph's `n` (ig-BC:33-36) |
| EL-X05 | `CompressedSparseRow(vertexCount:edges: list)` equals the CSR of the fixture | every `zeroBased` fixture, with `vertexCount: f.vertexCount` | CSR README |
| EL-X06 | CSR edge indices map list positions to CSR edges, repeats sharing one | `pathWithChord` list `[0→1, 1→2, 2→3, 3→4, 4→5, 1→3, 1→3]` → `edgeIndices == [0, 1, 3, 4, 5, 2, 2]` | CSR `init(vertexCount:edges:edgeIndices:)` (CSR README) |
| EL-X07 | Round trip through CSR canonicalizes: `EdgeList(CompressedSparseRow(vertexCount: n, edges: list).edges)` == `list` sorted by `(source, target)` with duplicates removed | `boostCsrUnsorted` → `[0→2, 3→2, 4→0, 4→1, 5→0, 5→2]`; `gap4` → 58 edges, row-major | CSR-cat §12 arrays |
| EL-X08 | Trailing isolated vertices survive only through the explicit count | `scipyConstructor2`: `CompressedSparseRow(vertexCount: 6, edges: list).vertexCount == 6` although `list.vertexCount == 2` | neo4j `with_max_node_id` (n4j-EL:106-112); petgraph `from_sorted_edges` cannot (CSR-cat C04) |
| EL-X09 | `AdjacencyMatrix(vertexCount:edges: list)` collapses repeats | `jgraphtSparseDirected` → `edgeCount == 11` | AM README |
| EL-X10 | `EdgeList(adjacencyMatrix)` is row-major and repeat-free | `boostExample` → `[1→2, 1→5, 2→0, 2→2, 3→4, 4→3, 5→0]` | AM README: `edges` is row-major |
| EL-X11 | Out-of-range endpoints when converting to an index representation trap (the CSR/AM preconditions), even though the list itself accepts any `Int` | `[0→5]` into `vertexCount: 2` | CSR-cat C17-C20 |
| EL-X12 | `EdgeList(list.reversed-view)` / `EdgeList(transposedGraph)` agree with `list.transposed()` up to order (as multisets) | — | — |
| EL-X13 | `EdgeList` conforms to `DirectedGraph`, so a generic algorithm written against the protocol (a BFS in the test file) gives the same reachable set as on `AdjacencyList(edges: list)` | `scc9`, `house` | README protocols |
| EL-X14 | String-vertex conversion | `networkXABCD` → `AdjacencyList(edges:)` has 4 vertices; with `vertices:` 7 | — |

---

## 10. Kruskal-style use: weights indexed by position (`EL-K`)

The README keeps weights out of representations, "passed to algorithms … as a dense array indexed by edge". For an edge list the edge index is the position. Every library studied pairs edges with costs one of two ways: the cost travels inside the element (NetworkX `(wt, u, v, d)` tuples, nx-MST:203-217; LEMON `std::pair<Arc, Cost>`, lem-K:263-268; GAP `NodeWeight`, gap-R:59-67; neo4j `(NI, NI, EV)`, n4j-EL:93-96; petgraph `IntoWeightedEdge`; swift-algorithm-club `Edge.weight`, sac-K:12), or in a parallel array indexed by position (Boost `edge_list` + `iterator_property_map` over `edge_index`, **verified** in the Bellman–Ford probe; scipy COO `data`).

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-K01 | A stable argsort of the weights orders the positions | `boostKruskal` weights `[1, 1, 2, 7, 3, 1, 1, 1]` → `list.indices.sorted { w[$0] < w[$1] } == [0, 1, 5, 6, 7, 2, 4, 3]` | Swift sort is stable (sw-SORT:40) |
| EL-K02 | Permuting the list by that order and the weights by the same order keeps every `(edge, weight)` pair together | same → sorted edges `[0→2, 1→3, 3→4, 4→0, 4→1, 1→4, 2→3, 2→1]` with weights `[1, 1, 1, 1, 1, 2, 3, 7]` | scipy keeps `data` in lockstep through `sum_duplicates` (sp-COO:810-830) |
| EL-K03 | **Hazard test:** `list.sort(by:)` alone does *not* move a separate weight array; after sorting, `w[i]` no longer belongs to `list[i]` (documents why EL-K01's argsort is the recommended idiom) | `boostKruskal` | — |
| EL-K04 | Removing an edge at `i` must be mirrored by `weights.remove(at: i)`; with Array semantics both shift identically | — | petgraph's swap-remove breaks a mirrored `Vec` unless the caller also swap-removes (pg-G:851-874) |
| EL-K05 | Kruskal over the list (as an undirected multigraph) on the Boost example: total weight **4**, 4 tree edges. Stable tie-breaking chooses positions `{0, 1, 5, 6}` | `boostKruskal` | bgl-KX:21-24 and `kruskal.expected` (prints `0-2, 3-4, 4-0, 1-3`, the same set); petgraph on the same input: same set (**verified**). NetworkX `MultiGraph` picks `{0, 1, 6, 7}`, also weight 4 (**verified**), so **with ties, test the total, not the edge set** |
| EL-K06 | Parallel edges with different weights: the cheaper copy is chosen and the other is not | `[0→1 (5), 0→1 (2), 1→2 (3), 2→2 (0)]` → tree `[0→1 (2), 1→2 (3)]`, total 5; the loop is never chosen | petgraph (**verified**) |
| EL-K07 | LEMON's fixture: 6 vertices, 10 edges with costs −10…−1 → total **−31**, tree positions `[0, 1, 4, 6, 8]` in cost order; with every cost 2 → total **10** | §17b `lemonKruskal` | lem-KT:77-145 (asserts −31, 10 and the exact tree `e1, e2, e5, e7, e9`) |
| EL-K08 | Direction is ignored by Kruskal: an `EdgeList` of `DirectedEdge` is read as undirected | LEMON's `v1→v2` and `v2→v1` (positions 2, 3) are parallel for Kruskal; neither is in the tree | lem-K:256-259 ("If the graph is directed, the algorithm consider it to be undirected") |
| EL-K09 | Disconnected input gives a spanning forest | `petgraphMstKruskal` (§17b): total 41, 8 edges for 10 vertices in 2 components; `jgraphtDisconnected`: total 60, 6 edges | pg-MSTT:9-61; jgt-KT:63-68, 118-150; lem-K:296-297 |
| EL-K10 | Isolated vertices change the forest's component count but not its edges or weight | `gap4wel` (§17b): 12 edges, total **183** whether vertices are derived (13 vertices, 1 component) or given as `0..<14` (2 components, vertex 5 alone) | Boost Kruskal requires a vertex list for exactly this reason (bgl-K:55, 72) |
| EL-K11 | Distinct weights give a unique tree: exact edge sets | `petgraphMST9` total 112, `petgraphMST10` 257, `petgraphMST15` 503, `petgraphMST20` 699 (positions in §17b) | pg-MSTT:213-226 (expected tree edges listed there); totals by `elkr.py`, cross-checked with NetworkX Kruskal and Prim |
| EL-K12 | Published Wikipedia examples via gonum: Kruskal WP figure 1 → 11; Kruskal WP example → 39; Borůvka WP example → 83 | §17b | gn-STT:68-143 |
| EL-K13 | swift-algorithm-club's graph (Swift prior art built on `[Edge]`) → total **15** | `sacMST` | sac-C:72-81; sac-K:9-30 |
| EL-K14 | Real weighted data: GAP `4.wel` (same 256 pairs as `4.el`, weights 1…254, 159 distinct) → forest of 12 edges, total 183 | `gap4wel` | gap-TEST:`graphs/4.wel` (BSD-3) |
| EL-K15 | NaN weights: the argsort with `<` is not a strict weak ordering. **Grafluent decision** for the future `SpanningTrees` module: precondition, or `ignoringNaN:`. The edge list itself is unaffected; record the hazard | — | NetworkX raises `ValueError: NaN found as an edge weight` unless `ignore_nan=True` (nx-MST:206-209; **verified**) |
| EL-K16 | An empty list gives an empty forest with weight 0 | — | gonum "Empty" case, want 0 (gn-STT:41-45); Boost returns early on 0 vertices (bgl-K:51) |
| EL-K17 | Kruskal's input contract varies: LEMON's sequence input "must be in cost-ascending order" (lem-K:266-268) and is trusted; Boost and petgraph sort with a binary heap (bgl-K:76; pg-MST:96-99), so ties come out in heap order; NetworkX, JGraphT and swift-algorithm-club sort stably. A test that pins the exact tree on tied weights is testing a tie-breaking rule, which Grafluent should document (recommend: stable by position) | `boostKruskal` | — |

---

## 11. Equality and hashing (`EL-E`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-E01 | `==` is element-wise in order: equal iff same count and `list[i] == other[i]` for all `i` | `[0→1, 1→2]` vs itself, vs a permutation (≠), vs a prefix (≠) | rustworkx `EdgeList` (rx-I:525-547); Swift `Array` |
| EL-E02 | Multiplicity matters: `[0→1] != [0→1, 0→1]` | — | NetworkX `edges_equal([(0,1),(0,1)], [(0,1)]) == False` (**verified**); igraph compares counts too (ig-IEL:1957-1959) |
| EL-E03 | Exhaustive over 2 vertices, lengths 0–3: the 85 lists form **85** equivalence classes under `==`; mapped through `AdjacencyList(edges:)` they form **15**; as sorted multisets **35** | all 4⁰ + 4¹ + 4² + 4³ lists over `{0→0, 0→1, 1→0, 1→1}` | counts computed by script; mirrors the AL/CSR "every 3-vertex graph" test |
| EL-E04 | Exhaustive over 3 vertices, lengths 0–2: 91 lists, 91 classes; 55 multisets; 46 edge sets | — | same |
| EL-E05 | Hash consistency: `a == b ⇒ a.hashValue == b.hashValue` over EL-E03's lists, including equal lists built different ways (literal, appends, `replaceSubrange`, slice copy) | — | `checkHashable` (AL-cat S-03) |
| EL-E06 | Equal-but-distinct reference vertices compare equal (`==` on `Vertex`), even though EL-C19 keeps both instances | `HashableBox` | — |
| EL-E07 | Order-insensitive comparisons are spelled explicitly, and give the expected answers: `Set(a) == Set(b)` (set), `a.sorted(by:) == b.sorted(by:)` (multiset), `AdjacencyList(edges: a) == AdjacencyList(edges: b)` (graph) | `boostCsrUnsorted` vs its reverse: `!=` as lists, `==` all three ways | NetworkX's helper docs warn that comparing raw lists "can give unexpected results" (nx-U:603-618) |
| EL-E08 | `==` is not isomorphism | `[0→1]` vs `[1→0]` | igraph doc (ig-IEL:1930-1937) |
| EL-E09 | `Equatable` substitutability holds: if `a == b` then `a.first == b.first`, `a.vertices == b.vertices`, `a.description == b.description` | random pairs | "Equality implies substitutability" (sw-EQ:112-114). This is why multiset `==` would be wrong for a `MutableCollection` |
| EL-E10 | An `EdgeList` and an `AdjacencyList` with the same edges are different types; no cross-type `==` is offered | — | API shape |

---

## 12. Codable (`EL-D`)

`EdgeList` is `Codable` when `Vertex` is. Because the payload grows with the edge count, decoding cannot amplify an allocation, so no decoding limit is needed (contrast AM's `maximumDecodedVertexCountKey`, CSR-cat D23).

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-D01 | Round trip with `JSONEncoder`/`JSONDecoder` and `PropertyListEncoder`, order and repeats preserved: `decode(encode(list)) == list` (ordered `==`) | every fixture, `String` fixtures, `gap4` | AL suite `CodableTests` |
| EL-D02 | **Grafluent decision: the encoded form.** Options: (a) unkeyed `[{"source": s, "target": t}, …]` (what `[DirectedEdge]` encodes to today); (b) flat unkeyed `[s₀, t₀, s₁, t₁, …]` (igraph's `edges` vector, ig-BC:30-32, and AM's `edges` field); (c) keyed `{"edges": […]}`. Recommend (b): compact, mirrors the sibling encoding, and makes "odd length" the one structural error | `directedPath3` → `[0,1,1,2]`; `EdgeList()` → `[]` | AM README "Encoded form" |
| EL-D03 | The empty list encodes and decodes | — | igraph and rustworkx accept an empty edge-list file (ig-T:`foreign_empty.c`:36; rx-T:21-24) |
| EL-D04 | Isolated vertices cannot appear in the payload (there is nowhere to put them), so `AdjacencyList → EdgeList → JSON → EdgeList → AdjacencyList` loses them, exactly as NetworkX's edgelist file does | `networkXABCD`: 7 vertices → 4 | nx-ELT:251-281; igraph `write_edgelist` of 5 vertices + one edge rereads as 2 (**verified**) |
| EL-D05 | Corrupt: odd number of values in form (b) → `DecodingError.dataCorrupted` | `[0, 1, 2]` | igraph "Invalid (odd) edges vector" (ig-BC:56-58; ig-T:`igraph_create.c`); igraph's reader "Integer expected, reached end of file" (ig-PU:213; **verified**) |
| EL-D06 | Corrupt: wrong element type (`"a"` for `Int`), `null`, a nested array, a keyed container where an unkeyed one is expected → `DecodingError` with the coding path of the bad element | `[0, "x"]` → `typeMismatch` at index 1 | NetworkX "Failed to convert nodes" (nx-ELT:148-150) |
| EL-D07 | Negative and huge `Int` values decode as ordinary vertices (an edge list has no range to check) | `[-1, 9223372036854775807]` | igraph rejects negative ids (**verified**); GAP silently accepts `-1` (**verified**) and silently drops an overflowing id (EL-T08). Grafluent has no range, so nothing to reject |
| EL-D08 | Decoding never produces a partial value: a payload corrupt at its last element throws rather than returning the prefix | `[0,1, 1,2, 2]` | GAP returns the prefix silently (**verified**, EL-T05) |
| EL-D09 | Encoding is deterministic: the same list always encodes to the same bytes (order is the list's order) | — | — |
| EL-D10 | `String` and `Optional` vertices round-trip (`nil` endpoints) | `[nil → 1]` | AL suite vertex types |

---

## 13. Text edge-list formats seen in the wild (`EL-T`)

These are cases for the future `GraphFormats` edge-list reader and writer, recorded here because they decide what an `EdgeList` must be able to hold. Each row was run through the libraries named.

| Format | Shape | Comments | Isolated vertices | Repeats | Source |
|---|---|---|---|---|---|
| NetworkX edgelist | `u v [dict or typed values]`, any whitespace (or a given delimiter) | `#` to end of line by default, configurable or `None` (nx-EL:284-289) | dropped on write (nx-ELT:258) | kept by `MultiDiGraph`, collapsed by `DiGraph` (**verified**) | nx-EL:218-341 |
| igraph edgelist | an even count of non-negative integers separated by any whitespace, newlines optional (ig-EL:46-55) | none: `#` is a parse error (**verified**) | lost on write; `n` restores a count on read | kept | ig-EL:77-110 |
| GAP `.el` / `.wel` | `u v` / `u v w`, read with `>>` (gap-R:50-67) | none: a `#` line makes the reader stop and return **0 edges, silently** (**verified**) | middle ones implied by `max + 1`; trailing ones lost | kept | gap-R |
| SNAP (`snap.stanford.edu`) | `# …` header lines, often `# Nodes: N Edges: M`, then `FromNodeId<TAB>ToNodeId` | `#` header | the header's `Nodes:` count is ignored by every reader tried | kept | a probe file |
| rustworkx edgelist | `u v [weight…]`, whitespace or a given delimiter | optional comment string | lost | kept unless `multigraph=False` (last weight wins, rx-T:150-164) | rx-D:2515-2585 |
| neo4j `.el` | `u` + one byte + `v` + newline; `.wel` adds ` value` | none | trailing lost unless `with_max_node_id` | kept | n4j-EL:14-21, 186-250 |
| JGraphT CSV `EDGE_LIST` | `a,b` per line, but any line may continue as an adjacency list (`c,a,b` = two edges) (jgt-CF:24-60) | none | a one-field line is a vertex (jgt-CI:239-251) | depends on the graph type | jgt-CI, jgt-CE:203-217 |

| ID | Input | Expected for Grafluent's reader (recommendation) | What the libraries do |
|---|---|---|---|
| EL-T01 | `"0 1\n1 2\n"` | `[0→1, 1→2]` | all agree (**verified** NetworkX, igraph, GAP, rustworkx, neo4j) |
| EL-T02 | Same without the final newline | same | neo4j **panics** (`range start index 1 out of range`, n4j-EL:237; **verified**); others accept |
| EL-T03 | A one-token line `"0 1\n5\n"` | error (or, with an opt-in, an isolated vertex — but `EdgeList` cannot hold it) | NetworkX skips the line (nx-EL:291-293; **verified**); igraph "Integer expected, reached end of file" (**verified**); GAP drops the token (**verified** 2 edges); rustworkx **panics** (`index out of bounds`, rx-D:2562; **verified**); JGraphT makes vertex `5` (jgt-CI:239-251) |
| EL-T04 | A non-integer token `"0 1\nx 2\n"` for `Int` vertices | error naming line 2 | NetworkX `TypeError: Failed to convert nodes` (**verified**); igraph "Unexpected character 'x'" (ig-PU:98; **verified**); rustworkx `ValueError: invalid digit` (**verified**); GAP **stops silently** after 1 edge (**verified**); neo4j **panics** (**verified**) |
| EL-T05 | An odd token count across lines `"0 1\n1 2\n3\n"` | error | igraph errors (**verified**); GAP returns 2 edges silently (**verified**) |
| EL-T06 | A third column without a declared data schema `"0 1 7\n1 2\n"` | error, or the column read as a weight only when asked | NetworkX `TypeError: Failed to convert edge data` (nx-ELT:151-154; **verified**); GAP **re-pairs the tokens** and returns `0→1, 7→1` (**verified**: the stray `7` shifts every later edge); rustworkx keeps `"7"` as the weight string; neo4j panics |
| EL-T07 | A negative id `"0 -1\n"` | accepted for `Int` vertices (they are values) | igraph "Invalid (negative or too large) vertex ID" (ig-BC:59-61; **verified**); rustworkx `ValueError` (`usize`, **verified**); GAP accepts `0→-1` (**verified**) |
| EL-T08 | An id beyond `Int64`/`Int32` | error | GAP (`int32` ids) returns **0 edges**, silently (**verified** with `99999999999`) |
| EL-T09 | Comments: `"# c\n0 1\n"` and a trailing `"0 1 # c"` | `[0→1]` when a comment marker is configured | NetworkX strips both (**verified**); igraph errors (**verified**); GAP returns 0 edges (**verified**); rustworkx needs `comment="#"` (**verified**) |
| EL-T10 | A SNAP header (`# Nodes: 5 Edges: 3`, three edges, vertex 4 absent) | 3 edges, 4 vertices; the header's count is metadata only (it would be the only way to recover isolated vertices, and nobody uses it) | NetworkX and rustworkx (with `comment`) read 3 edges, 4 nodes; igraph errors; GAP returns 0 edges (all **verified**) |
| EL-T11 | Blank and whitespace-only lines | skipped | NetworkX skips (**verified**); rustworkx skips them **unless a comment string is set**, in which case a blank line **panics** (`index out of bounds`, rx-D:2519-2522, 2561; **verified**); neo4j panics on a leading blank line (**verified**) |
| EL-T12 | Tabs and repeated spaces as separators | accepted | NetworkX and igraph accept (**verified**); neo4j accepts one tab but **panics on two spaces** (it skips exactly one byte, n4j-EL:224-225; **verified**) |
| EL-T13 | CRLF line endings | accepted | neo4j has a `windows.el` test (n4j-EL:336-348); NetworkX splits on any whitespace by default, which absorbs the `\r` |
| EL-T14 | Repeated lines `"0 1\n0 1\n"` | `[0→1, 0→1]` (an edge list keeps repeats) | all keep them in multigraph mode (**verified** NetworkX `MultiDiGraph`, rustworkx, GAP, neo4j, igraph) |
| EL-T15 | Writer output: one `u v` line per edge, in list order, repeats repeated; the empty list writes the empty string | `pathWithChord` → 7 lines, `1 3` twice | NetworkX writes `MultiDiGraph` parallels as separate lines (**verified** `b'1 2\n1 2\n…'`); rustworkx writes `""` for an empty graph (rx-T:181-187); JGraphT writes in `edgeSet` (insertion) order (jgt-CET:50-56) |
| EL-T16 | Writer → reader round trip is the identity on `EdgeList` (including order and repeats), but not on a graph with isolated vertices | `gap4` (256 lines in, 256 out) | NetworkX's round-trip tests remove the isolated node before comparing (nx-ELT:251-260) |
| EL-T17 | Large file parsed in parallel keeps file order | 10⁶ lines | neo4j appends each thread's chunk under a lock in completion order (n4j-EL:205-250), so its order is not guaranteed for large files (from code; not observed on small inputs) |

---

## 14. Description and reflection (`EL-N`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-N01 | `description` uses the shared form `[vertices]; [edges]` with derived vertices and repeated edges listed each time | `pathWithChord` → `[0, 1, 2, 3, 4, 5]; [0→1, 1→2, 2→3, 3→4, 4→5, 1→3, 1→3]` | `GraphDescription.graph` (Sources/GraphProtocols/GraphDescription.swift) |
| EL-N02 | Elision after 16 vertices and 16 edges with `…` | `completeDirected10` → all 10 vertices, the first 16 edges, then `…` | `GraphDescription.limit` |
| EL-N03 | `String` endpoints are quoted as `Array` writes them | `[DirectedEdge(from: "a", to: "b")]` → `["a", "b"]; ["a"→"b"]` | AL description tests |
| EL-N04 | `debugDescription` adds the type and counts, like the siblings | `EdgeList<String>(vertexCount: 2, edgeCount: 1, vertices: ["a", "b"], edges: ["a"→"b"])` | AL suite (`AdjacencyList<String>(vertexCount: 1, edgeCount: 1, vertices: ["a"], edges: ["a"→"a"])`) |
| EL-N05 | **Grafluent decision: the mirror.** As a `Collection`, the natural mirror is `displayStyle: .collection` with one child per edge (what `Array` does, and what playgrounds and debuggers expect). The siblings show `vertices` and `edges` children. Recommend `.collection` of edges | — | AL README "the mirror shows `vertices` and `edges`" |
| EL-N06 | The empty list | `[]; []` | — |
| EL-N07 | Equal lists print alike; a permutation prints differently (order is part of the value) | — | EL-E09 |

---

## 15. Value semantics, copy-on-write, lifetime (`EL-W`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-W01 | Every mutation (subscript set, `swapAt`, `sort`, `append`, `insert`, `remove(at:)`, `remove(edge:)`, `removeAll(where:)`, `removeEdges(incidentTo:)`, `replaceSubrange`, `reverse`) leaves an earlier copy unchanged | `boost24` | AL suite `ValueSemanticsTests` |
| EL-W02 | A slice taken before a mutation keeps the old elements | — | ArraySlice semantics |
| EL-W03 | The list owns its edges: mutating the source array after construction does not change the list | `var a = house.edges; let l = EdgeList(a); a[0] = 0→0` → `l[0] == 5→3` | Boost's `edge_list` is a **view**: mutating the vector after construction changes the graph (**verified** `after mutate e0=5->5`) |
| EL-W04 | `LifetimeTracked` vertices are released when the edges holding them are removed, and when the list is destroyed; no leaks | — | AL suite `LifetimeTests`; `GrafluentTestSupport/LifetimeTracked.swift` |
| EL-W05 | Copies are independent across tasks (`Sendable`) | — | — |
| EL-W06 | Model test: seeded random sequences of every mutation applied to an `EdgeList` and to an `[DirectedEdge]` reference stay `elementsEqual` after every step, at sizes 0–200 | seeds from `SeededRandomNumberGenerator` | AL suite `ModelTests`; the reference model is trivial because an edge list *is* an array |
| EL-W07 | Whether a no-op mutation copies storage is a benchmark property, not tested here | — | AL README last paragraph |

---

## 16. Preconditions — exit tests (`EL-P`)

| ID | Expression | Expected |
|---|---|---|
| EL-P01 | `list[count]`, `list[-1]` (get and set) | trap |
| EL-P02 | `list.remove(at: count)` | trap |
| EL-P03 | `list.insert(e, at: count + 1)` | trap |
| EL-P04 | `EdgeList().removeFirst()`, `removeLast()`; `removeFirst(3)` on 2 edges | trap |
| EL-P05 | `list.swapAt(0, count)` | trap |
| EL-P06 | `list.replaceSubrange(0 ..< count + 1, with: [])`, `list[0 ..< count + 1]` | trap |
| EL-P07 | Builder with bare vertices, if EL-C14 chooses (a) | trap |
| EL-P08 | `remove(edge:)` absent, `contains(edge:)` absent, degrees of a non-endpoint | **no trap** (EL-R11, EL-Q02, EL-Q08) |
| EL-P09 | `CompressedSparseRow(vertexCount: 2, edges: [0→2] as EdgeList)` | trap (CSR's own precondition) |
| EL-P10 | `popLast()` on empty | **no trap**, `nil` |

---

## 17. Large, real-data and published fixtures (`EL-G`, `EL-F`)

### 17a. Existing `DirectedFixture` fixtures, read as edge lists

"Written" counts every edge the fixture lists, repeats included; this is `EdgeList(f.edges).count`. "Endpoint vertices" is `EdgeList(f.edges).vertexCount`. Every value was computed by a scratch script (not kept; it read the upstream clones' data files) from the Swift sources and the vendored data files.

| Fixture | written m | distinct | parallel extras | max multiplicity | self-loops written | `vertexCount` (fixture) | endpoint vertices | isolated (lost) | already sorted by (source, target) |
|---|---|---|---|---|---|---|---|---|---|
| `empty` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — | yes |
| `trivial` | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | yes |
| `singleSelfLoop` | 1 | 1 | 0 | 1 | 1 | 1 | 1 | — | yes |
| `isolatedVertices` | 0 | 0 | 0 | 0 | 0 | 10 | 0 | all 10 | yes |
| `directedPath3` | 2 | 2 | 0 | 1 | 0 | 3 | 3 | — | yes |
| `completeDirected3` | 6 | 6 | 0 | 1 | 0 | 3 | 3 | — | yes |
| `completeDirected10` | 90 | 90 | 0 | 1 | 0 | 10 | 10 | — | yes |
| `networkXFunctionGraph` | 6 | 6 | 0 | 1 | 1 | 5 | 4 | 4 | no |
| `house` | 7 | 7 | 0 | 1 | 0 | 6 | 6 | — | no |
| `scc9` | 11 | 11 | 0 | 1 | 0 | 9 | 9 | — | no |
| `selfLoopsAndDuplicates` | **8** | 6 | 2 | 2 | 3 | 5 | 5 | — | no |
| `directedCycle4` | 4 | 4 | 0 | 1 | 0 | 4 | 4 | — | yes |
| `triangleWithReciprocalEdge` | 4 | 4 | 0 | 1 | 0 | 3 | 3 | — | yes |
| `pathWithChord` | **7** | 6 | 1 | 2 | 0 | 6 | 6 | — | no |
| `petersen` | 30 | 30 | 0 | 1 | 0 | 10 | 10 | — | no |
| `cube` | 24 | 24 | 0 | 1 | 0 | 8 | 8 | — | no |
| `directedPath10` | 9 | 9 | 0 | 1 | 0 | 10 | 10 | — | yes |
| `directedCycle10` | 10 | 10 | 0 | 1 | 0 | 10 | 10 | — | yes |
| `boostExample` | 7 | 7 | 0 | 1 | 1 | 6 | 6 | — (0 is listed but is a target) | yes |
| `boost24` | 43 | 43 | 0 | 1 | 0 | 24 | 24 | — | no |
| `petgraphEdgesDirected` | 9 | 9 | 0 | 1 | 1 | 7 | 7 | — | no |
| `igraphReverseEdges` | 5 | 5 | 0 | 1 | 0 | 5 | 5 | — | no |
| `jgraphtMatrixCSV` | 10 | 10 | 0 | 1 | 1 | 5 | 5 | — | yes |
| `boostCsrUnsorted` | 6 | 6 | 0 | 1 | 0 | 6 | 6 | — | no |
| `boostWebGraph` | 13 | 13 | 0 | 1 | 0 | 6 | 6 | — | yes |
| `petgraphCsr1` | 6 | 6 | 0 | 1 | 3 | 3 | 3 | — | no |
| `petgraphCsrFrom` | 6 | 6 | 0 | 1 | 2 | 5 | 4 | 3 | yes |
| `petgraphBellmanFord` | 11 | 11 | 0 | 1 | 1 | 9 | 9 | — | yes |
| `neo4jDirected` | 6 | 6 | 0 | 1 | 0 | 5 | 5 | — | yes |
| `jgraphtSparseDirected` | **13** | 11 | 2 | 3 | 1 | 8 | 8 | — | yes |
| `scipyConstructor2` | 1 | 1 | 0 | 1 | 0 | 6 | 2 | 0, 1, 2, 5 | yes |
| `networkXABCD` (String) | 5 | 5 | 0 | 1 | 0 | 7 | 4 | G, J, K | no |
| `petgraphDAG` (String) | 11 | 11 | 0 | 1 | 0 | 7 | 7 | — | no |
| `gap4` | **256** | 58 | 198 | 27 (`0→0`) | 36 | 14 | 13 | 5 | no |
| `graph500Scale8` | **4096** | 2171 | 1925 | 42 (`82→82`) | 85 | 256 | 241 | 15 vertices | no |
| `ligraRMat` | 708 | 708 | 0 | 1 | 0 | 128 | 125 | 1, 5, 40 | yes |

The `DirectedFixture.edgeCount`/`outDegree`/`inDegree` fields are **simple-graph** expectations and must not be used for `EdgeList` degrees on the five fixtures with repeats (bold). Use EL-M04–M06 and EL-Q10, or compute with `filter` in the test. Fixtures whose "endpoint vertices" differ from `vertexCount` need the vertex list passed explicitly in conversion tests (EL-X04, EL-X08).

Large cases:

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| EL-G01 | `gap4`: 256 in file order; first three `0→13, 0→13, 0→9`, last `0→9`; distinct 58; degrees per EL-Q10 | vendored | gap-TEST `graphs/4.el` (BSD-3) |
| EL-G02 | `graph500Scale8`: 4096 in file order; first `17→138`, last `82→1`; distinct 2171; 85 loop entries; `outDegree(of: 82) == 871` | vendored | neo4j `scale_8.graph500` (MIT) |
| EL-G03 | `ligraRMat`: 708, already sorted and repeat-free; `list.sorted(by: (source, target)) == list` | vendored | Ligra (MIT) |
| EL-G04 | 10⁶ appends then `removeAll(where:)` of half: correct count and order (time belongs to benchmarks) | seeded | — |
| EL-G05 | A hub of out-degree 20,000, shuffled: `outDegree`, `successors(of:).count`, `removeEdges(incidentTo: hub)` returns 20,000 | seeded | CSR suite hub |
| EL-G06 | 10⁵ copies of one edge: `multiplicity == 10⁵`, `vertices == [u, v]`, `AdjacencyList(edges:).edgeCount == 1` | — | stress for the "repeats kept" contract |

### 17b. New published fixtures (weighted, for Kruskal-style tests)

Vertices are 0-based; edge positions are list positions. Weights are an array aligned by position. Totals were computed by a scratch script (not kept) (union–find over a stable argsort) and each was matched by NetworkX's Kruskal **and** Prim on a `MultiGraph`.

| Name | Edges as written (`u→v`) | Weights by position | n | Total | Tree positions (stable ties) | Source |
|---|---|---|---|---|---|---|
| F-BK `boostKruskal` | `0→2, 1→3, 1→4, 2→1, 2→3, 3→4, 4→0, 4→1` | `1, 1, 2, 7, 3, 1, 1, 1` | 5 | **4** | `0, 1, 5, 6` (4 edges) | bgl-KX:21-24, `kruskal.expected` (BSL-1.0). Note `1→4` (2) and `4→1` (1) are parallel for an undirected MST |
| F-LK `lemonKruskal` | `0→1, 0→2, 1→2, 2→1, 1→3, 3→2, 2→4, 4→3, 3→5, 4→5` (s = 0, v1…v4 = 1…4, t = 5) | `−10, −9, −8, −7, −6, −5, −4, −3, −2, −1` | 6 | **−31** (all 2s: **10**) | `0, 1, 4, 6, 8` | lem-KT:77-145 (BSL-1.0) |
| F-PGK `petgraphMstKruskal` | A…J = 0…9: `0→1, 0→3, 3→1, 1→2, 1→4, 2→4, 3→4, 3→5, 5→4, 5→6, 4→6, 7→8, 7→9, 8→9` | `7, 5, 9, 8, 7, 5, 15, 6, 8, 11, 9, 1, 3, 1` | 10 | **41**, 2 components | `11, 13, 1, 5, 7, 0, 4, 10` (8 edges) | pg-MSTT:9-61 (MIT/Apache) |
| F-PG9 `petgraphMST9` | first `TEST_CASES` entry, 30 edges | as listed there | 9 | **112** | `15, 25, 22, 13, 19, 11, 6, 1` | pg-MSTT:215-216 |
| F-PG10 `petgraphMST10` | second entry, 29 edges | as listed | 10 | **257** | `1, 23, 26, 22, 5, 16, 7, 28, 0` | pg-MSTT:218-219 |
| F-PG15 `petgraphMST15` | third entry, 40 edges | as listed | 15 | **503** | `18, 10, 23, 38, 33, 39, 5, 25, 9, 6, 22, 34, 16, 28` | pg-MSTT:221-222 |
| F-PG20 `petgraphMST20` | fourth entry, 36 edges | as listed | 20 | **699** | `2, 0, 6, 35, 9, 8, 4, 14, 10, 28, 31, 23, 12, 19, 30, 15, 1, 7, 25` | pg-MSTT:224-225 |
| F-SAC `sacMST` | `1→2, 1→3, 1→4, 2→3, 2→5, 3→4, 3→5, 3→6, 4→6, 5→6` (1-based) | `6, 1, 5, 5, 3, 5, 6, 4, 2, 6` | 6 | **15** | `1, 8, 4, 7, 3` | sac-C:72-81 (MIT) |
| F-GKW `gonumKruskalWPfig1` | a…e = 0…4: `0→1, 0→4, 1→2, 1→4, 2→3, 2→4, 3→4` | `3, 1, 5, 4, 2, 6, 7` | 5 | **11** | `1, 4, 0, 2` | gn-STT:68-87 (BSD-3) |
| F-GKE `gonumKruskalWPexample` | A…G = 0…6: `0→1, 0→3, 1→2, 1→3, 1→4, 2→4, 3→4, 3→5, 4→5, 4→6, 5→6` (the A…G part of `petgraphMstKruskal`, in gonum's order) | `7, 5, 8, 9, 7, 5, 15, 6, 8, 9, 11` | 7 | **39** | `1, 5, 7, 0, 4, 9` | gn-STT:89-114 |
| F-GBW `gonumBoruvkaWP` | A…L = 0…11, 20 edges as in gonum | `13, 6, 7, 1, 14, 8, 20, 9, 3, 2, 18, 15, 5, 19, 10, 17, 11, 16, 4, 12` | 12 | **83** | `3, 9, 8, 18, 12, 1, 2, 14, 19, 11, 10` | gn-STT:116-158 |
| F-JD `jgraphtDisconnected` | A…H = 0…7: `0→1, 0→2, 1→3, 2→3, 4→5, 4→6, 6→7, 5→7` | `5, 10, 15, 20, 20, 15, 10, 5` | 8 | **60**, 2 components | `0, 7, 1, 6, 2, 5` | jgt-KT:63-68, 118-150 (assert only the weight and a subset; re-derived) |
| F-JC `jgraphtConnected` | `0→1, 0→2, 1→3, 2→3, 3→4, 0→4` | `2, 3, 5, 20, 5, 100` | 5 | **15** | `0, 1, 2, 4` | jgt-KT:70-75, 152-175 |
| F-GW `gap4wel` | `test/graphs/4.wel`: the 256 pairs of `4.el`, same order | the file's third column (1…254; 159 distinct; sum 32,149) | 14 (13 endpoints) | **183** | 12 edges: `249, 57, 77, 199, 234, 68, 86, 93, 27, 238, 225, 145` | gap-TEST (BSD-3); vendor next to `gap4` |

`gap4wel` is the only new data file. It is BSD-3 like `4.el` and can be vendored the same way (`RealWorldFixtures.swift` already carries the GAP attribution). The petgraph, LEMON, Boost, swift-algorithm-club and gonum fixtures are a handful of numbers each and can be written inline with a source comment.

---

## 18. Design evidence for the open questions

**Q-a. Parallel edges: kept or collapsed?**

- *Kept, with positions distinguishing them:* Boost `edge_list` (`allow_parallel_edge_tag`, bgl-EL:295; **verified**), petgraph `Graph` (pg-G:628; **verified**), NetworkX `MultiDiGraph` and its edgelist reader (**verified**), igraph (**verified**), JGraphT pseudographs (jgt-SIT:525), rustworkx by default (**verified**), scipy COO until `sum_duplicates` (sp-COO:799-808; **verified**), GAP and neo4j edge lists (**verified**), LEMON `ListDigraph` (**verified**), swift-algorithm-club `[Edge]`.
- *Collapsed:* only in set-based containers: NetworkX `DiGraph`, petgraph `GraphMap` (last weight wins, **verified**), Boost `setS` (**verified** 3 of 4), rustworkx `multigraph=False` (last weight wins, rx-T:150-164), and Grafluent's `AdjacencyList`, `AdjacencyMatrix`, `CompressedSparseRow`.
- Kruskal fixtures depend on it: LEMON's test graph (positions 2, 3) and Boost's example (positions 2, 7) both contain edges that are parallel for an undirected spanning tree, with different weights.
- *Recommendation:* keep them. An `EdgeList` that collapsed would be a fourth set representation and could not be a faithful `RandomAccessCollection` of what the caller appended. Collapsing is a conversion (`AdjacencyList(edges:)`, `CompressedSparseRow(vertexCount:edges:)`).

**Q-b. Is insertion order preserved and part of identity?**

- *Preserved by construction and by in-order removal:* Boost (a view), igraph (compaction, ig-IEL:537-545), scipy COO (until canonicalized), GAP, swift-algorithm-club.
- *Preserved on insert but broken by removal:* petgraph (swap-remove, pg-G:874; `retain_edges` reverses), rustworkx (slot reuse).
- *Not preserved:* NetworkX `MultiDiGraph` (grouped by source), LEMON `ListDigraph` (newest first per vertex), neo4j's parallel file parser.
- *Part of identity:* only rustworkx's `EdgeList` sequence class (ordered `__eq__`/`__hash__`, rx-I:520-562).
- *Recommendation:* preserve it under every operation, with `Array`'s exact semantics (`remove(at:)` shifts, `removeAll(where:)` keeps survivors in order), and make it part of `==`. Weight arrays aligned by position (the README's plan) are only usable if positions behave like `Array` indices.

**Q-c. Equality and hashing.**

- *Ordered:* rustworkx `EdgeList`, Swift `Array`.
- *Multiset, order-free:* igraph `igraph_is_same_graph` (ig-IEL:1916-1990), NetworkX `edges_equal` (nx-U:555-633).
- *Set:* NetworkX `DiGraph` via `graphs_equal`; Grafluent `AdjacencyList`.
- *None:* Boost, petgraph, GAP, neo4j, LEMON, swift-algorithm-club, python-igraph `==` (identity, **verified**).
- Swift requires `==` to imply substitutability (sw-EQ:112-114). For a `MutableCollection`, `a == b` with `a[0] != b[0]` would break it, so multiset or set `==` is not available to a type that exposes positions.
- *Recommendation:* ordered element-wise `==` and an ordered hash. Order-free comparisons are spelled through conversions (EL-E07). Test the 85/35/15 class counts (EL-E03) to pin all three.

**Q-d. Isolated vertices.**

- *Not representable in the list:* Boost `edge_list` (no vertex set; `N` passed separately, bgl-CC:59-68), NetworkX edgelist files (nx-ELT:258), igraph/GAP/neo4j/petgraph/rustworkx (integer `max + 1`, plus an explicit count where offered), swift-algorithm-club (its `vertices` set is filled only by `addEdge`, sac-G:33-41).
- *Representable:* JGraphT's CSV dialect (one-field lines), and every graph type that is not a flat list.
- If an `EdgeList` stored extra vertices, `removeAll()` would leave a value that is empty as a collection but `!= EdgeList()`, `init(Array(list)) != list`, and `description` would show vertices that no element mentions. Kruskal does not need them: isolated vertices change the component count, never the chosen edges or weight (EL-K10).
- *Recommendation:* do not store them. `vertices` is the endpoints in first-appearance order, computed in O(m). Conversions that need more take `vertices:` or `vertexCount:` (EL-X04, EL-X08). The builder's bare-vertex statements are rejected (EL-C14).

**Q-e. Mutation API and conformances.**

- `RangeReplaceableCollection` (append, insert, remove(at:), removeSubrange, replaceSubrange, removeAll(where:), `+`) and `MutableCollection` (subscript set, swapAt, sort(by:), reverse, partition, shuffle) both fit, because the value is exactly its sequence. Both are what `[Edge]` gives swift-algorithm-club for free.
- `remove(edge:)`: libraries disagree on which parallel copy goes: NetworkX the last-added (nx-MDG:535), rustworkx/petgraph the newest (LIFO `find_edge`), JGraphT one, Boost all. Swift's own idiom is `firstIndex(of:)` + `remove(at:)`. *Recommendation:* `remove(edge:)` removes the **first** occurrence and returns it (`nil` if absent); "all copies" is `removeAll { $0 == e }`.
- `insert(edge:) -> (inserted:, memberAfterInsert:)` from the siblings would always report `true`. *Recommendation:* omit it; `append` is the insertion.
- `removeEdges(incidentTo:)`: the AdjacencyMatrix name for Boost's `clear_vertex`; returns the number removed.

**Q-f. `contains(edge:)` complexity.**

- Boost's adaptor offers no `edge(u, v)` at all; petgraph and rustworkx scan the out-list (O(out-degree), and only because they keep adjacency lists); NetworkX and JGraphT use hash maps; igraph binary-searches its sorted permutation.
- A flat list has none of those structures. *Recommendation:* O(m) scan (`Sequence.contains`), documented. Code that needs fast membership converts to `AdjacencyList` or `CompressedSparseRow` (O(1) and O(log d)). Do not add a hidden index: it would break the "one allocation" principle and make every mutation pay for it.

**Q-g. Vertex removal removing incident edges.**

- NetworkX, petgraph, igraph, rustworkx and JGraphT all remove incident edges with the vertex (**verified** for the first four). petgraph also swap-renumbers vertices; igraph renumbers survivors; rustworkx keeps ids stable.
- An edge list has no vertex to remove; removing the incident edges *is* removing the vertex (EL-V06). *Recommendation:* `removeEdges(incidentTo:) -> Int`, order-preserving, no renumbering (vertices are `Hashable` values).

**Q-h. Degree queries cost.**

- neo4j's `EdgeList::degrees` and GAP's `CountDegrees` are both a full O(m) pass over the list (n4j-EL:61-77; gap-B:80), done once to build a CSR. Boost's adaptor offers no degree function.
- *Recommendation:* O(m) per query, multiplicity counted, and `successors(of:).count == outDegree(of:)` exactly (EL-Q06). Code that needs many degree queries builds a CSR (`inDegrees` is one pass) or an `AdjacencyList`. Document the cost on each method, as `Array.contains` is documented.

---

## 19. Surprising disagreements

1. **Boost's docs say Kruskal works on `edge_list`; the code says it cannot.** The adaptor page states `edge_list` "works with algorithms that only need edge iteration, such as `bellman_ford_shortest_paths` and `kruskal_minimum_spanning_tree`" (bgl-ELD:9-12), but `kruskal_mst_impl` asserts `VertexListGraphConcept` and calls `num_vertices` (bgl-K:51-56). A probe calling Kruskal on an `edge_list` **fails to compile** (`use of undeclared identifier 'num_vertices'`, **verified**). Bellman–Ford does work, because its `edge_list` overload takes `N` explicitly (**verified** distances `0, 1, 2`). Kruskal needs a vertex set even when its input is "an edge list".
2. **Boost's non-random-access `edge_list` cannot report edge indices.** `get(edge_index, g, e)` returns `e._i`, but the descriptor's field is `_id` (bgl-EL:60-63 vs 135, 165). Instantiating it on a `std::list` iterator **does not compile** (**verified**). Only the random-access specialization, where the index is the position, works.
3. **"Remove the edge from u to v" removes four different things.** NetworkX removes the last-added copy, petgraph and rustworkx the newest (their `find_edge` is LIFO), JGraphT one, Boost all of them. None removes the first, which is what Swift's `firstIndex(of:)` idiom does.
4. **petgraph's in-place filters reverse order.** `retain_edges` keeps `[1→2, 3→4]` as `[3→4, 1→2]` (**verified**), because it removes back to front with swap-remove. Its docs only say "the order edges are visited is not specified" (pg-G:1447); the resulting order is not documented at all.
5. **rustworkx's edge-list sequence has ordered equality, but its graph does not keep order.** `edge_list() == [(0,1), …]` is element-wise (rx-I:520-547), yet removing edge 0 and adding another puts the new edge first (**verified**), so two graphs with the same history-free contents can produce unequal edge lists.
6. **NetworkX's multigraph neighbors and degrees disagree.** `MultiDiGraph([(1,2),(1,2)])`: `successors(1) == [2]` but `out_degree(1) == 2` (**verified**). petgraph's `neighbors` repeats instead (**verified** `[2, 1, 1]`). Grafluent should keep `successors(of:).count == outDegree(of:)`.
7. **Text readers fail in five different ways on the same bad line.** For `"0 1\nx 2\n"`: NetworkX raises `TypeError`, igraph a parse error, rustworkx `ValueError`, neo4j **panics**, and GAP **silently returns the first edge** (all **verified**). For a stray third column GAP re-pairs every later token (`0 1 7 / 1 2` → `0→1, 7→1`), and a `#` comment line makes it return **0 edges** with no error. A SNAP file, the most common public edge-list format, therefore loads in GAP as an empty graph.
8. **rustworkx panics on blank lines only when a comment string is given** (rx-D:2519-2522: blank lines are skipped only when `comment` is `None`), and on any one-token line (**verified**). neo4j panics on a missing final newline, a blank line or a double space (**verified**).
9. **Kruskal tie-breaking is not portable.** On Boost's own example (five weight-1 edges), Boost and petgraph choose positions `{0, 1, 5, 6}` and NetworkX chooses `{0, 1, 6, 7}` (both **verified**, both weight 4). Boost and petgraph pop ties from a binary heap; NetworkX, JGraphT and swift-algorithm-club sort stably but iterate edges in different orders; gonum's sort is unstable. Tests on tied weights should assert the total; only distinct-weight fixtures (petgraph's `TEST_CASES`, gonum's Wikipedia graphs) can assert exact trees.
10. **JGraphT's `addAllEdges` copies weights for edges it did not add.** It tests `modified && needWeightCopy` after `modified |= destination.addEdge(…)` (jgt-G:238-240), so once any edge has been added, every later edge's weight is copied even when that edge already existed, contrary to its doc ("except when the edge already exists in the destination", jgt-G:205-210). (From reading the code; not run.)
11. **neo4j documents a wrong edge count for its own format.** "The edge count will be twice the number of lines in the file" (n4j-EL:20-21) describes the undirected CSR it builds, not the `EdgeList`, whose tests expect one edge per line (n4j-EL:288-310).
12. **An `EdgeList` is the one representation where the README's `reversed` name collides with the standard library.** `BidirectionalCollection.reversed()` reverses order; the planned graph view `reversed` flips edges (README Terminology and Unary operations). On an `EdgeList` both would be in scope. Use `transposed()` for the materialized flip, as CSR and `AdjacencyMatrix` already do, and leave `reversed()` with its stdlib meaning (EL-L10, EL-Q12).
13. **The only Swift prior art is accidentally an edge list without isolated vertices.** swift-algorithm-club's `Graph` stores `edgeList: [Edge]` and a `vertices: Set` that only `addEdge` fills (sac-G:15-16, 33-41), and its Kruskal sorts the array with Swift's stable sort (sac-K:12). That is exactly the recommended Grafluent model, arrived at independently.

---

## 20. Licences and porting notes

- **Data that may be vendored with attribution:** GAP `test/graphs/4.wel` (BSD-3, same notice as the already-vendored `4.el`); neo4j `resources/*.el` (MIT) if a CRLF case is wanted.
- **Small numeric fixtures written inline with a source comment:** Boost `kruskal-example.cpp` (BSL-1.0), LEMON `kruskal_test.cc` (BSL-1.0), petgraph `tests/min_spanning_tree.rs` (MIT/Apache-2.0), gonum `spanning_tree_test.go` (BSD-3), swift-algorithm-club (MIT), NetworkX test strings (BSD-3), rustworkx test strings (Apache-2.0).
- **Behavior reference only:** igraph and python-igraph (GPL-2.0-or-later). The igraph rows above describe behavior; no igraph code or fixture is copied. JGraphT (EPL-2.0/LGPL): its multigraph degree numbers coincide with values recomputed independently here (EL-M04, EL-M05), so the tests cite them without copying code.
- **Expected values:** every number in §17 was computed by the scripts named there, from the fixture definitions and data files, independently of any implementation under test; each Kruskal total was cross-checked by two NetworkX algorithms.
- **Case count:** 207 cases (C 20, V 10, M 9, O 8, L 16, S 12, R 19, Q 15, X 14, K 17, E 10, D 10, T 17, N 7, W 7, P 10, G 6), plus 14 new weighted fixtures.
