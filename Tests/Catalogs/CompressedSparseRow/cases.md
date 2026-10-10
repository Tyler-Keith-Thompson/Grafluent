# Test catalog: `CompressedSparseRow` (immutable directed CSR graph)

This catalog collects test cases for Grafluent's planned `CompressedSparseRow`, harvested from mature graph and sparse-matrix libraries. Cases are grouped by behavior and deduplicated across libraries.

The type under test is a directed graph on vertices `0..<vertexCount`. It is stored as `offsets` (n + 1 entries) and `targets` (m entries), with each row's targets sorted ascending. It is built once by initializers. It allows self-loops, collapses duplicate edges (no parallel edges), and offers `vertexCount`, `edgeCount`, `vertices`, `edges` (row-major), `successors(of:)` (a sorted slice), O(1) `outDegree(of:)`, `contains(edge:)` by binary search, `transposed()` (the reverse graph, i.e. the CSC view), and `Equatable`/`Hashable`/`Codable`.

It is a companion to `test-catalog-adjacency-list.md` and `test-catalog-adjacency-matrix.md` in this folder. Those catalogs already cover the general list-graph and matrix conventions (degree laws, Collection laws, value semantics). This file covers only what is specific to CSR.

**Sources** (shallow clones, Oct 2026):

| Library | Commit | Licence | What was used |
|---|---|---|---|
| petgraph | `a4d94bd` | MIT OR Apache-2.0 | `src/csr.rs` and its unit tests; `IndexType` |
| boostorg/graph | `1ee1a99` | BSL-1.0 | `compressed_sparse_row_graph.hpp`, `detail/compressed_sparse_row_struct.hpp`, `detail/histogram_sort.hpp`, `test/csr_graph_test.cpp`, the CSR doc page and examples |
| scipy | `ec1861f` | BSD-3-Clause | `sparse/tests/test_base.py` (TestCSR, TestCOO, non-canonical mixins), `_compressed.py` (`check_format`, `prune`, canonical flags), `_csr.py`, `sparsetools/csr.h`, `csgraph/tests/test_conversions.py` |
| neo4j-labs `graph` (`graph_builder` crate) | `b1d3375` | MIT | `crates/builder/src/graph/csr.rs` (builder, layouts, binary serialization, unit tests), `tests/builder.rs`, `resources/scale_8.graph500` |
| GAP Benchmark Suite (gapbs) | `2972aeb` | BSD-3-Clause | `src/builder.h`, `src/graph.h`, `src/reader.h`, `src/writer.h`, `src/tc.cc`, `test/test.mk`, `test/graphs/4.el`, `test/reference/` |
| NetworkX | `6da4704` | BSD-3-Clause | `tests/test_convert_scipy.py`, `convert_matrix.py` |
| JGraphT (`jgrapht-opt` sparse graphs) | `63976aa` | EPL-2.0 OR LGPL-2.1-or-later | `CSRBooleanMatrix.java`, `NoIncomingNoReindexSparseDirectedSpecifics.java`, `IncomingEdgesSupport.java`, `SparseIntGraphTest.java` |
| igraph | `912f99d` | GPL-2.0-or-later (**behavior reference only; do not copy code**) | `include/igraph_datatype.h` (its `igraph_t` is a bidirectional indexed edge list with CSR-style offsets), `src/graph/type_indexededgelist.c` |
| SuiteSparse:GraphBLAS | `afbe9aa` | Apache-2.0 | `Source/builder/` (`GrB_Matrix_build` duplicate and bounds handling), `Source/import_export/` (fast vs secure CSR import, `jumbled`) |
| Ligra | `8763202` | MIT | `ligra/IO.h` (`AdjacencyGraph` text format), `inputs/rMatGraph_J_5_100` |
| gonum, SwiftGraph, swift-algorithm-club | (earlier clones) | BSD-3 / Apache-2.0 / MIT | Checked: none has a CSR graph type. Nothing harvested. |

Not cloned: rustworkx (it reuses petgraph's types and has no CSR of its own; `rustworkx-core/src/graph_ext/mod.rs:55` only lists petgraph's `Csr`), cuGraph, graph-tool.

**Verification.** Cases marked **(verified)** were confirmed by running probes:

- `csrprobe/src/main.rs` (scratch, not kept) is a Rust program linked against the local petgraph and neo4j clones.
- `bglcsrprobe/main.cpp` (scratch, not kept) is a C++ program compiled against the local Boost.Graph clone, with Homebrew Boost for the other headers.

scipy and NetworkX were not run because scipy is not installed. Their cases come from reading the tests and code.

**Path prefixes used in citations** (relative to the root of the upstream shallow clones, Oct 2026, not kept in the repository)

| Prefix | Expands to |
|---|---|
| `pg:` | `petgraph/crates/petgraph/src/csr.rs` |
| `pg-ix:` | `petgraph/crates/petgraph/src/graph_impl/mod.rs` |
| `bgl-T:` | `graph/test/csr_graph_test.cpp` |
| `bgl-H:` | `graph/include/boost/graph/compressed_sparse_row_graph.hpp` |
| `bgl-S:` | `graph/include/boost/graph/detail/compressed_sparse_row_struct.hpp` |
| `bgl-HS:` | `graph/include/boost/graph/detail/histogram_sort.hpp` |
| `bgl-DOC:` | `graph/doc/modules/ROOT/pages/graph_classes/compressed_sparse_row.adoc` |
| `bgl-EX:` | `graph/example/csr-example.cpp`; `bgl-USE:` = `graph/doc/modules/ROOT/examples/graph_classes/csr_usage.cpp` |
| `sp-TB:` | `scipy/scipy/sparse/tests/test_base.py` |
| `sp-C:` | `scipy/scipy/sparse/_compressed.py`; `sp-R:` = `_csr.py`; `sp-H:` = `sparsetools/csr.h` |
| `sp-CG:` | `scipy/scipy/sparse/csgraph/tests/test_conversions.py` |
| `n4j:` | `neo4j-graph/crates/builder/src/graph/csr.rs`; `n4j-T:` = `.../tests/builder.rs`; `n4j-E:` = `.../src/input/edgelist.rs`; `n4j-M:` = `.../src/graph/mod.rs`; `n4j-O:` = `.../src/graph_ops.rs` |
| `gap-B:` | `gapbs/src/builder.h`; `gap-G:` = `src/graph.h`; `gap-R:` = `src/reader.h`; `gap-W:` = `src/writer.h`; `gap-TC:` = `src/tc.cc`; `gap-TEST:` = `test/` |
| `nx:` | `networkx/networkx/tests/test_convert_scipy.py`; `nx-CM:` = `networkx/networkx/convert_matrix.py` |
| `jgt-M:` | `jgrapht/jgrapht-opt/src/main/java/org/jgrapht/opt/graph/sparse/specifics/CSRBooleanMatrix.java` |
| `jgt-D:` | `.../specifics/NoIncomingNoReindexSparseDirectedSpecifics.java`; `jgt-I:` = `.../sparse/IncomingEdgesSupport.java` |
| `jgt-T:` | `jgrapht/jgrapht-opt/src/test/java/org/jgrapht/opt/graph/sparse/SparseIntGraphTest.java` |
| `ig-DT:` | `igraph/include/igraph_datatype.h`; `ig-IEL:` = `igraph/src/graph/type_indexededgelist.c` |
| `grb-B:` | `graphblas/Source/builder/GB_build.c`; `grb-BR:` = `GB_builder.c`; `grb-MB:` = `GrB_Matrix_build.c` |
| `grb-I:` | `graphblas/Source/import_export/GB_import.c`; `grb-IC:` = `GxB_Matrix_import_CSR.c` |
| `lig:` | `ligra/ligra/IO.h`; `lig-IN:` = `ligra/inputs/rMatGraph_J_5_100` |
| `probe-rs:` / `probe-bgl:` | the two probe programs above |

Case IDs such as `CSR-C07` are stable, so test names can refer to them. **Grafluent decision** marks a point where the libraries disagree and our spec has to choose. Throughout, `n` = `vertexCount` and `m` = `edgeCount` after duplicates collapse.

---

## 0. Cross-library convention table (read this first)

| Convention | petgraph `Csr` | Boost `compressed_sparse_row_graph` | scipy `csr_array` | neo4j `DirectedCsrGraph` | GAP `CSRGraph` | JGraphT `SparseIntDirectedGraph` | igraph `igraph_t` | Planned Grafluent |
|---|---|---|---|---|---|---|---|---|
| Arrays | `row: Vec<usize>` (n+1), `column: Vec<Ix>` (m), `edges: Vec<E>` in lockstep (pg:66-80) | `m_rowstart: vector<EdgeIndex>` (n+1), `m_column: vector<Vertex>` (m), edge props in lockstep (bgl-S:98-99) | `indptr` (n+1), `indices` (nnz), `data` (nnz) | `offsets: Box<[NI]>` (n+1), `targets: Box<[Target<NI,EV>]>` (m) (n4j:58-61) | an **array of n+1 pointers** into `neighs`, not integer offsets. Offsets are rebuilt only for serialization (gap-G:242-258) | `rowOffsets: int[]` (n+1), `columnIndices: int[]` holding **edge ids**, not targets (jgt-M, jgt-D:79) | `from`, `to` (insertion order), `oi`/`ii` (permutations), `os`/`is` (n+1 offsets) (ig-DT:66-113) | `offsets` (n+1), `targets` (m) |
| Offset/target width | offsets `usize`, targets `Ix` (default `u32`; also `u8`, `u16`, `usize`) (pg-ix:29-75) | `EdgeIndex` and `Vertex` template parameters. Default `size_t`; `EdgeIndex` "must not be smaller than `Vertex`" (bgl-DOC:90-97) | int32 when it fits, else int64; **both arrays must share a dtype** (sp-C:186-188, sp-TB:4449-4456, 4720-4740) | **one type `NI` for both** (`Csr<NI, NI, EV>`), so a `u32` graph cannot hold more than 2³² edges (n4j:58-61, 125-131) | node ids `int32` (`SGID`), offsets `int64` (`SGOffset`) (gap-G:92-94) | `int` for both | `igraph_int_t` (64-bit) for everything | `Int` (open question, §13) |
| Targets sorted within a row | yes, kept by `add_edge` insertion (pg:366-383) | **no**: rows keep input order (verified: row 4 of the unsorted fixture is `[1, 0]`) | only if `has_sorted_indices`; constructors from (data, indices, indptr) accept any order (sp-TB:4566-4574) | only for `CsrLayout::Sorted`/`Deduplicated`; the code's default is `Unsorted` (n4j:35-45) | yes after `SquishCSR` (gap-B:139-170) | rows ordered by **edge id** (input order), not target (jgt-M:79) | via `oi` permutation: sorted by (from, to) (ig-IEL:1430-1446) | yes, ascending |
| Duplicate edges | rejected by `from_sorted_edges` (`Err`); `add_edge` returns `false` (pg:233, pg:356) | **kept** (`allow_parallel_edge_tag`, bgl-H:255; verified m = 4 for 4 written edges) | kept by the CSR constructor; **summed** by COO → CSR (sp-TB:5264-5269) and by `sum_duplicates` | kept unless `Deduplicated` (n4j:35-45) | removed by squish (gap-B:155) | kept (multigraph, jgt-D:154) | kept (multigraph) | **collapsed** |
| Self-loops | kept | kept (verified) | kept (diagonal) | kept, **except `Deduplicated` also deletes them** (n4j:42-44, 911-915; verified) | **deleted** by squish (gap-B:139, 156, 203-204) | kept | kept | **kept** |
| Vertex count | `max(endpoint) + 1` from `from_sorted_edges`, so no trailing isolated vertices; `with_nodes(n)` otherwise (pg:182-199) | explicit `numverts` argument | from `shape`, else `len(indptr) − 1` × `max(indices) + 1` (sp-C:103-111) | `max_node_id + 1`; node values can make it larger (n4j:530, 557-561). An **empty edge list gives 1 vertex** (verified) | `max + 1` unless set on the command line (gap-B:323) | explicit; **`rows < 1` throws**, so no empty graph (jgt-M:65) | explicit | explicit `vertexCount` |
| Out-of-range endpoint at construction | impossible in `from_sorted_edges` (n is inferred); `add_edge` → `Err(IndicesOutBounds)` (pg:347-349) | source: `BOOST_ASSERT` only (abort in debug; verified). Target: **never checked** (verified: `column=[5]` with n = 2) | `check_format(full_check=True)` raises "indices must be < N" (sp-C:214-218), but the constructor runs only the O(1) check (sp-C:117) | index panic | unchecked | column checked (`IllegalArgumentException`, jgt-M:88); row not checked | `IGRAPH_EINVVID` (ig-IEL:268-270) | precondition failure (trap) or thrown error, per entry point |
| Unsorted input to the "sorted" constructor | `Err(EdgesNotSorted)` (pg:212-237) | **undefined**: the docs say "silently corrupt graph" (bgl-DOC:224-226); the probe **crashed with SIGBUS** (verified) | n/a | n/a | n/a | n/a | n/a | throw (or trap); never corrupt |
| `contains(u, v)` | linear below 32 targets, binary at or above (pg:29, 366-383); out-of-range `u` panics, out-of-range `v` → `false` (verified) | `edge(u, v)` is **linear**, returns the first parallel edge (bgl-H:1317-1330, bgl-DOC:408-414) | `A[i, j]` | — | — | linear; out of range → `null` (jgt-D:163-179) | binary search over the **smaller** of out-row(u) and in-row(v); out-of-range is always an error (ig-IEL:1468-1482, 1527-1529) | binary search; out of range → `false` |
| Edge identity | position in `column` (`EdgeReference::id`, pg:511). **Shifts when `add_edge` inserts earlier** (verified) | `edge_index` = position in `m_column`; `edge_from_index` uses `upper_bound` on offsets, O(log n) (bgl-H:1333-1345) | position in `indices`/`data` | none exposed | none | **input order** ("no reindex", jgt-D) | insertion order (`from`/`to`); `oi`/`ii` are permutations | position 0..<m in row-major order |
| Inverse (in-edges) storage | none | `bidirectionalS` adds `m_backward`, whose payload is the **forward edge index** (bgl-H:912-922; verified) | `tocsc()` / `.T` (the transpose is an O(1) reinterpretation, sp-R:24-36) | **always** builds both `csr_out` and `csr_inc` (n4j:364-368, 538-543) | built by default (`invert = true`) unless symmetric (gap-B:37-38, 330-331) | `NO_`/`LAZY_`/`FULL_INCOMING_EDGES` (jgt-I) | always (`ii`, `is`) | `transposed()` returns a separate graph. README plans `CompressedSparseColumn` |
| Equality | none (no `PartialEq`) | none | `!=` is element-wise; no structural `==` | none | none | `AbstractGraph.equals` (vertex and edge sets) | `igraph_is_same_graph` | structural `==` over (n, offsets, targets) |
| Serialization | none for `Csr` (graph6 for undirected only) | none | `save_npz` (outside this scope) | raw binary: type name, `[n, m]`, offsets, targets, **no validation** except the type name (n4j:252-311) | `.sg`: `bool directed, int64 m, int64 n, int64 offsets[n+1], int32 neighs[m]`, then the inverse; **no validation** (gap-R:254-300, gap-W:39-70) | Java `Serializable` | GraphML and others | `Codable`, validating |

The main points:

- **Only petgraph sorts targets and rejects duplicates.** It is also the only one besides GAP that matches Grafluent's "simple digraph" model.
- **Boost, the reference design for CSR, is a multigraph with unsorted rows.** That is why its `edge(u, v)` is linear.
- **Nobody validates a deserialized CSR except GraphBLAS's opt-in "secure import" and scipy's `check_format(full_check=True)`.** Grafluent's corrupt-payload tests (§8) have almost no prior art to copy. They have to be written from the invariants.

---

## 1. Construction (`CSR-C`)

### 1a. Empty and isolated vertices

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-C01 | The default or empty graph has `offsets == [0]` (one entry, not zero), `targets == []`, `vertexCount == 0`, `edgeCount == 0`, and empty `edges` | `CompressedSparseRow()` → offsets `[0]` | petgraph `new()` sets `row: vec![0; 1]` (pg:110-119); Boost default `rowstart=[0]` (**verified**, probe-bgl); scipy `test_empty` (sp-TB:682-687) |
| CSR-C02 | `n` isolated vertices: offsets are n + 1 zeros; every `outDegree` is 0; every `successors` is empty | n = 3 → `[0,0,0,0]`; n = 10 → eleven zeros | Boost `G(3)` → `rowstart=[0,0,0,0]` (**verified**); petgraph `with_nodes` (pg:137-149) |
| CSR-C03 | An empty edge list with an explicit vertex count keeps that count. Grafluent must **not** infer n from the edges | `init(vertexCount: 4, edges: [])` → n = 4, offsets `[0,0,0,0,0]` | Contrast: neo4j infers **1** vertex from an empty edge list (**verified** `(1, 0)`; cause n4j-E:84-90 reduces from `zero`); petgraph infers 0 (**verified**); JGraphT throws for 0 rows (jgt-M:64-66) |
| CSR-C04 | Trailing isolated vertices survive. A vertex count larger than `max(endpoint) + 1` gives trailing rows of equal offsets | n = 4, edges `0→1, 1→2` → offsets `[0,1,2,2,2]`; `outDegree(3) == 0` | neo4j `directed_from_node_values_exceeding_edge_list_max_id` (n4j:1222-1237). petgraph's `from_sorted_edges` **cannot** express this (n = max + 1, pg:198) |
| CSR-C05 | Leading and middle empty rows: the first edge's source > 0 | scipy constructor2: n = 6, one edge `3→4` → offsets `[0,0,0,0,1,1,1]`, targets `[4]` | sp-TB:4479-4486 |

### 1b. Unsorted input

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-C06 | Unsorted input produces sorted rows (**Grafluent differs from Boost**, which keeps input order) | Boost "unsorted" fixture, n = 6: `(5,0),(3,2),(4,1),(4,0),(0,2),(5,2)` → offsets `[0,1,1,1,2,4,6]`, targets `[2, 2, 0,1, 0,2]`. Boost itself yields targets `[2,2,1,0,0,2]` (**verified**) | bgl-T:434-470 |
| CSR-C07 | Construction is order-independent: the identity, reverse-sorted and Fisher–Yates-shuffled orderings of the same edges give `==` graphs and identical `offsets`/`targets` | Boost shuffles with `minstd_rand(42)`. Use any seeded shuffle of `boostWebGraph` or `boost24` | bgl-T:228-292 (three in-place variants) |
| CSR-C08 | Unsorted with values: each value follows its edge into place | scipy constructor4: rows `[2,3,1,3,0,1,3,0,2,1,2]`, cols `[0,1,0,0,1,1,2,2,2,2,1]`, data `[6,10,3,9,1,4,11,2,8,5,7]`, shape 4×3 → dense = `arange(12).reshape(4,3)` (entry (0,0) = 0 is absent). For a graph: n = 4 needs square; use as an edge-property permutation test with any n ≥ 4 | sp-TB:4498-4512 |
| CSR-C09 | Unsorted *within* rows only (sources already grouped) still sorts each row | offsets `[0,3,5]`, targets `[7,2,1,5,4]` (n ≥ 8) → after canonicalization `[1,2,7,4,5]` | scipy `test_sort_indices` (sp-TB:4566-4574); neo4j `sort_targets_test`: offsets `[0,2,5,5,8]`, targets `[1,0,4,2,3,5,6,7]` → `[0,1,2,3,4,5,6,7]` (n4j:998-1008) |

### 1c. Duplicates and self-loops

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-C10 | Duplicates collapse: `edgeCount` counts distinct pairs | scipy: `([1,1,1,1], ([0,2,2,0], [0,1,1,0]))` → nnz 2, i.e. edges `0→0` and `2→1`, n = 3 → offsets `[0,1,1,2]`, targets `[0,1]` | sp-TB:4514-4516; COO → CSR drops 2 of 4 (sp-TB:5264-5269) |
| CSR-C11 | Duplicate and self-loop together, in a sorted fast-path input | `(0,1),(0,1),(1,1),(1,1)`, n = 3 → offsets `[0,1,2,2]`, targets `[1,1]`, m = 2. Boost keeps all 4: `rowstart=[0,2,4,4] column=[1,1,1,1]` (**verified**) | probe-bgl |
| CSR-C12 | Dedup and sort within rows, keeping self-loops (**Grafluent differs from neo4j `Deduplicated` and from GAP**, which delete self-loops) | neo4j kernel input: offsets `[0,3,7,7,10]`, targets `[1,1,0, 4,2,3,2, , 5,6,7]` (rows 0–3). neo4j → offsets `[0,1,4,4,7]`, targets `[1,2,3,4,5,6,7]` (row 0 loses `0→0`). Grafluent, n = 8 → offsets `[0,2,5,5,8,8,8,8,8]`, targets `[0,1, 2,3,4, 5,6,7]` | n4j:1010-1020 |
| CSR-C13 | The three neo4j layouts on one input, to pin each Grafluent property separately | edges `(0,2),(0,1),(0,2),(0,0),(1,1),(2,0)`, n = 3. neo4j Unsorted out0 `[2,1,2,0]`; Sorted `[0,1,2,2]`; Deduplicated `[1,2]`, out1 `[]` (**verified**). **Grafluent** → offsets `[0,3,4,5]`, targets `[0,1,2, 1, 0]`, m = 5; in-rows: in0 `[0,2]`, in1 `[0,1]`, in2 `[0]` | probe-rs |
| CSR-C14 | Self-loop-only graph | `singleSelfLoop`: n = 1 → offsets `[0,1]`, targets `[0]`; `contains(0→0)` | petgraph `(0,0),(2,2)` → n = 3, m = 2, `neighbors(0) == [0]` (**verified**) |
| CSR-C15 | Mixed self-loops in every row | petgraph csr1: `(0,0),(1,2),(2,2),(0,2),(1,0),(1,1)`, n = 3 → offsets `[0,2,5,6]`, targets `[0,2, 0,1,2, 2]` | pg:919-940 (asserts `column` and `row` exactly) |
| CSR-C16 | A heavy-duplicate real file: 256 lines collapse to 58 distinct edges (5 self-loops: 0, 7, 8, 9, 13) | GAP `test/graphs/4.el` (§12, F-GAP4). Grafluent m = 58; GAP's squished m = 53 because it also drops the loops | gap-TEST:`graphs/4.el`, `reference/graph-4.el.out` ("14 nodes and 53 directed edges") |

### 1d. Out-of-range endpoints

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-C17 | Target ≥ n is rejected (trap, or a thrown error from the validating initializer) | n = 2, edge `0→5`. Boost silently stores `column=[5]` (**verified**). Grafluent must refuse | probe-bgl; JGraphT throws "Entry at invalid column" (jgt-M:87-89); igraph `IGRAPH_EINVVID` (ig-IEL:268-270) |
| CSR-C18 | Source ≥ n is rejected | n = 2, edge `5→0`. Boost `BOOST_ASSERT(key_transform(*i) < numkeys)` aborts (exit 134, **verified**); release builds would write out of bounds | bgl-HS:67, 110, 148 |
| CSR-C19 | Negative endpoints are rejected | `-1→0` | scipy "indices must be >= 0" (sp-C:217-218) |
| CSR-C20 | `source == n` and `target == n` (off-by-one) are rejected, not accepted as an empty row | n = 3, edge `3→0`; edge `0→3` | petgraph `out_degree(node_count)` returns 0 instead of panicking (**verified**, cause pg:393-401 `get(a+1).unwrap_or(len)`): an off-by-one acceptance Grafluent must not copy |

### 1e. Sorted fast path validation

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-C21 | The sorted initializer accepts valid sorted, unique input and gives the same graph as the general initializer | petgraph csr_from: `(0,1),(0,2),(1,0),(1,1),(2,2),(2,4)`, n = 5 → offsets `[0,2,4,6,6,6]`, targets `[1,2,0,1,2,4]` | pg:978-988 |
| CSR-C22 | Sources out of order are rejected | `(0,1),(1,0),(0,2)` → error (petgraph `Err(EdgesNotSorted{first_error:(0,2)})`) | `csr_from_error_1` (pg:962-968, check at pg:212-216) |
| CSR-C23 | Targets out of order within a row are rejected | `(0,1),(1,0),(1,2),(1,1)` → error at `(1,1)` | `csr_from_error_2` (pg:970-976, check at pg:233-237) |
| CSR-C24 | **Decision: a duplicate in the sorted fast path** is an error (petgraph's strict `m > x`; **verified** `is_err=true`) or a collapse | `(0,1),(0,1)` | pg:233. Recommend: error. The fast path's contract is "already canonical". Collapsing silently would hide caller bugs, and the general initializer exists for that |
| CSR-C25 | An unsorted edge never produces a corrupt graph. Even a "trusted" path must check or trap | `(1,0),(0,1)`, n = 2. Boost `edges_are_sorted` crashed (SIGBUS, **verified**) | bgl-DOC:224-226; bgl-S:195-229 (loop `current_vertex_plus_one != src + 1` runs off the end when src decreases) |
| CSR-C26 | Sortedness detection is free while bounds-checking. A test can only observe that sorted and shuffled input give equal results (performance belongs to benchmarks) | — | GraphBLAS computes `known_sorted` during its bounds pass and skips the sort if set (grb-BR:390, 439, 571) |
| CSR-C27 | The fast path also works with edge values, and values stay in lockstep | petgraph Bellman–Ford fixture (§12, F-PGBF) with weights `0.5, 2, 1, 1, 1, 1, 3, 1, 2, 1, 3`: `edges_slice(1) == [1,1,1,1]` | pg:1065-1087; Boost `edges_are_sorted` with `weights` (bgl-T:391-414) |

### 1f. From other representations

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-C28 | Copying from another graph (`CompressedSparseRow(adjacencyList)`, `CompressedSparseRow(adjacencyMatrix)`) preserves n, m, each vertex's out-degree, sorted successor multisets, and the sorted list of all edges | Boost compares with `assert_graphs_equal` (bgl-T:59-128) for Erdős–Rényi graphs n = 1000, p = 0.001 and 0.0005, seed 42 (bgl-T:356-362, 428-429) | bgl-T:203-210 |
| CSR-C29 | From a dense 0/1 matrix (row = source) | scipy constructor1 `[[0,4,0],[3,0,0],[0,2,0]]` → offsets `[0,1,2,3]`, targets `[1,0,1]`; constructor3 (3×2, not square: use only as a negative case) | sp-TB:4467-4497 |
| CSR-C30 | Explicit zeros in a weighted matrix: **Decision**. NetworkX and scipy disagree on whether a stored zero is an edge. For a Boolean matrix source the question does not arise | — | scipy csgraph counts explicit zeros as edges (`csgraph/tests/test_matching.py:79`); `eliminate_zeros` (sp-TB:4576-4585) |
| CSR-C31 | Round trip with an adjacency list: `AdjacencyList(CompressedSparseRow(g)) == g` for every `DirectedFixture.zeroBased` | — | NetworkX `identity_conversion` (nx:34-87) |
| CSR-C32 | Vertex order of a relabelled source: rows follow the provided order | NetworkX `test_ordering`: cycle `1→2→3→1` with nodelist `[3,2,1]` → `[[0,0,1],[1,0,0],[0,1,0]]` → offsets `[0,1,2,3]`, targets `[2,0,1]` | nx:180-188 |
| CSR-C33 | Round trip through the edge sequence: rebuilding from `edges` gives identical arrays (and values) | petgraph `test_edge_references` (F-PGBF): `row`, `column`, `edges` all equal | pg:1158-1184 |
| CSR-C34 | Bulk initializer `init(vertexCount:edgeCount:initializingWith:)` (planned in the Grafluent README): a closure that writes offsets and targets is validated like a decoded payload (§8) | — | GraphBLAS fast vs secure import (grb-I:340-378) |
| CSR-C35 | Single-pass input sequences are accepted: the initializer must not iterate the edge sequence twice, or must buffer it | — | Boost has two unsorted constructors: single-pass (caches) and multi-pass (bgl-H:70-86, bgl-DOC:118-200). Both give the same graph (bgl-T:463-466) |
| CSR-C36 | Builders that add edges after construction are not offered. A test asserts `CompressedSparseRow` has no `insert(edge:)` | — | Boost `add_edges` is O(n + m + k log k) (bgl-DOC:733); petgraph `add_edge` is O(m) per call (pg:296-301) and shifts edge ids (CSR-E05) |

---

## 2. Offsets/targets invariants (`CSR-I`)

These are the checks Boost's `check_consistency_one` runs after every construction (bgl-T:130-152). Grafluent should run them as a shared helper after every initializer, and in the decoder (§8).

| ID | Invariant | Concrete check | Source |
|---|---|---|---|
| CSR-I01 | `offsets.count == vertexCount + 1` | for n = 0, `offsets == [0]` | scipy "index pointer size … should be M + 1" (sp-C:198-199); petgraph "Always node_count + 1 long" (pg:73-75) |
| CSR-I02 | `offsets[0] == 0` | — | bgl-T:134; sp-C:200-201 |
| CSR-I03 | `offsets` non-decreasing | `offsets[i+1] >= offsets[i]` for all i | bgl-T:135-139; scipy "indptr must be a non-decreasing sequence" (sp-C:219-220) |
| CSR-I04 | `offsets[n] == targets.count == edgeCount` | — | petgraph doc (pg:73-75); neo4j doc (n4j:47-57); scipy only requires `indptr[-1] <= len(indices)` and **prunes** the excess (sp-C:206-210, 1136-1150). **Decision**: Grafluent requires equality |
| CSR-I05 | Every target in `0..<n` | — | bgl-T:144-149 (`m_column[i] < m_rowstart.size() - 1`) |
| CSR-I06 | Each row strictly ascending (sorted **and** unique) | `targets[k] < targets[k+1]` for `offsets[i] <= k < offsets[i+1]-1` | scipy `csr_has_canonical_format` uses strict `<` and also rejects `Ap[i] > Ap[i+1]` (sp-H:335-349); "sorted" alone is the non-strict version (sp-H:306-318) |
| CSR-I07 | Equivalence: `edges.count == edgeCount == offsets.last` and `Σ outDegree == edgeCount` | — | `distance(edges(g)) == num_edges(g)` (bgl-T:207-208, 215-216) |
| CSR-I08 | The transpose satisfies I01–I06 too, and `Σ inDegree == edgeCount` | — | `check_consistency(m_backward)` (bgl-T:184-190) |

---

## 3. `successors(of:)` and `outDegree(of:)` (`CSR-S`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-S01 | `successors(of: v)` equals `targets[offsets[v]..<offsets[v+1]]`, ascending | neo4j: `edges (0,1),(0,2),(1,2),(1,3),(2,4),(3,4)` → out0 `[1,2]`, out1 `[2,3]`, out2 `[4]`, out3 `[4]`, out4 `[]` | n4j-T:68-76, 493-532 |
| CSR-S02 | `outDegree(of: v) == offsets[v+1] - offsets[v] == successors(of: v).count` | same fixture → `[2,2,1,1,0]` | n4j-T:497-501; pg:409-416 |
| CSR-S03 | The successor slice's indices are the edge indices: `successors(of: v).indices == offsets[v]..<offsets[v+1]` (if the slice is an `ArraySlice`/`Span` of `targets`) | — | Boost `adjacent_vertices` returns `m_column.begin() + rowstart[v]` (bgl-H:1296-1305); petgraph's `edges()` iterator numbers from `r.start` (pg:441-452) |
| CSR-S04 | An empty row is an empty slice (not a trap), including the first and last vertex | `boostExample` vertex 0 (offsets `[0,0,…]`), `house` vertex 0, `neo4jDirected` vertex 4 | n4j-T:519 |
| CSR-S05 | `vertices` iterates `0..<n` strictly ascending; each out-edge's source is that vertex | — | bgl-T:308-326 |
| CSR-S06 | `edges` is row-major, sources non-decreasing, and within a source targets ascending | — | bgl-T:295-306 (checks `src >= last_src`) |
| CSR-S07 | `edges` on a graph whose first rows are empty starts at the first non-empty row; an all-empty or n = 0 graph gives an empty sequence | `scipyConstructor2` (rows 0–2 empty); `isolatedVertices`; `CompressedSparseRow()` | Boost special-cases `rowstart.size() == 1 \|\| column.empty()` and skips leading empty rows (bgl-H:1356-1374); Boost `edges(empty)` empty (**verified**) |
| CSR-S08 | Successors of a high-degree vertex (≥ 32, petgraph's linear/binary cutoff) are correct and ascending | `completeDirected10` gives degree 9 only. Add a star `0→1…40` (degree 40) | pg:29 |
| CSR-S09 | `successors(of:)` and `outDegree(of:)` with `v` outside `0..<n` trap. That includes `v == n`, which petgraph silently answers with 0 | n = 2, `outDegree(of: 2)` and `outDegree(of: 5)`. petgraph: `out_degree(2) == 0`, `out_degree(5)` panics; neo4j panics on `out_degree(7)` (**verified**) | probe-rs |

---

## 4. Binary-search edge lookup (`CSR-L`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-L01 | `contains(edge:)` is true for every edge of every fixture and false for every other pair in `0..<n × 0..<n` (exhaustive over n ≤ 24) | `boost24`, `jgraphtSparseDirected`, `petgraphCsr1` | petgraph `adjacency_matrix` test runs Csr through the same cases as `Graph` (`tests/adjacency_matrix.rs:141-163`) |
| CSR-L02 | Lookups at the row boundaries: the first and last target of a row, a value below the first, a value above the last, and a value between two targets | row `[1,3,7]`: probe 0, 1, 2, 3, 7, 8 | petgraph's `find_edge_pos` returns `Err(insert_pos)` for absent values (pg:366-383) |
| CSR-L03 | Lookup in an empty row is false and does not read the neighbouring row | `boostExample`: `contains(0→2)` false although row 1 starts with 2 | — (classic off-by-one; derived from I04) |
| CSR-L04 | Self-loop lookup | `petgraphEdgesDirected`: `contains(6→6)`; `contains(5→5)` false | — |
| CSR-L05 | Rows both below and at or above the 32-entry threshold (petgraph switches from linear to binary search at 32) give identical answers to a linear scan | star of degree 31, 32, 33 with gaps | pg:29, 368 |
| CSR-L06 | Out-of-range source or target → `false`, never a trap (Grafluent's sibling convention) | n = 2: `contains(5→0)`, `contains(0→5)`, `contains(2→0)`, `contains(-1→0)` | petgraph: `(0,99)` false, `(5,0)` **panics** (**verified**); igraph always errors on an invalid id (ig-IEL:1527-1529); JGraphT → `null` (jgt-D:165-170). **Decision** recorded in the AM README: `false` |
| CSR-L07 | Lookup agrees with the transpose: `g.contains(u→v) == g.transposed().contains(v→u)` | all fixtures | igraph searches whichever of out-row(u) and in-row(v) is shorter (ig-IEL:1468-1482) |
| CSR-L08 | **(If an `edgeIndex(of:)` API exists)** returns the position `k` with `targets[k] == v` in row u, or nil | `boostCsrUnsorted` sorted: `index(of: 4→1) == 3`, `index(of: 4→0) == 2` | Boost `edge(u,v)` returns the descriptor with `idx` (**verified** `edge(0,1) idx=0`) |

---

## 5. Edge indices and their stability (`CSR-E`)

CSR alone can name each edge with an integer `0..<m` that is dense and needs no side table, and that index is stable for the life of the immutable value. Boost builds its edge-property maps on this (bgl-H:1609-1640). petgraph exposes it as `EdgeReference::id` (pg:511).

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-E01 | The k-th element of `edges` has index k; indices cover `0..<m` exactly once | — | petgraph `edge_references` ids `0..5` (**verified**) |
| CSR-E02 | `source(ofEdgeAt: k)` is the u with `offsets[u] <= k < offsets[u+1]`, found by binary search on offsets (`upper_bound − 1`). It is correct across empty rows | n = 5, edges `(0,1),(3,2),(3,0)` → offsets `[0,1,1,1,3,3]`, targets `[1,0,2]`; source(0) = 0, source(1) = 3, source(2) = 3 (Boost **verified**, though its column is `[1,2,0]`) | `edge_from_index` (bgl-H:1333-1345); round trip `edge_from_index(get(edge_index, e)) == e` for every edge (bgl-T:295-306) |
| CSR-E03 | `target(ofEdgeAt: k) == targets[k]` | — | bgl-H:1247-1252 |
| CSR-E04 | Index k ≥ m (or < 0) traps | — | `BOOST_ASSERT(idx < num_edges(g))` (bgl-H:1337) |
| CSR-E05 | **Stability across construction order**: because rows are canonical, an edge's index depends only on the edge set, not on input order or duplicates | `boostCsrUnsorted` in input order, reversed, and shuffled → `3→2` always has index 1, `5→2` always index 5 | Derived. petgraph shows the contrary under mutation: `(0,2)` has id 0, then id 1 after `add_edge(0,1)` (**verified**). JGraphT and igraph number edges by input order (jgt-D:72-81, ig-DT:72-80), so their ids change if the input is permuted |
| CSR-E06 | Copies share indices: `g2 = g; g2.edgeIndex(e) == g.edgeIndex(e)` (value semantics) | — | Boost: descriptors are "simple integer indices" valid for the object's lifetime (bgl-DOC:744-745) |
| CSR-E07 | Edge-property arrays: a `[W]` of length m indexed by edge index lines up with `edges` | Boost csr_usage: `{0,1},{0,2},{1,2},{2,3}` with km `{460,775,310,200}` → `0→1 460`, `0→2 775`, `1→2 310`, `2→3 200` (bgl-USE, expected output `csr_usage.txt`) | bgl-USE; Boost betweenness writes edge centralities through `edge_index` (bgl-T:328-353) |
| CSR-E08 | Values passed with unsorted input are permuted along with their edges | give the csr_usage edges reversed, props reversed → same per-edge values | Boost in-place constructor with `edge_props` (bgl-DOC:270-285); neo4j `in_neighbors_with_values(2) == [(0,0.2),(1,0.3)]` (n4j-T:123-145) |
| CSR-E09 | **Decision: which value survives a duplicate collapse.** Options seen: error (GraphBLAS `dup == NULL` per its documentation, grb-MB:10-11), last wins (`GxB_IGNORE_DUP`: "the first tuple is ignored and C(i,j) is equal to x2", grb-B:17-21), sum (scipy, sp-TB:5246-5257), min (scipy csgraph `csgraph_to_dense`, sp-CG:45-62), arbitrary (neo4j: `Target` equality ignores the value, n4j-M:5-30, and the sort is unstable, n4j:886-894) | `(0,1,w:5),(0,1,w:7)` | Recommend: a `uniquingEdgesWith:` combine closure, like `Dictionary(_:uniquingKeysWith:)`. Test first-wins, last-wins and sum |
| CSR-E10 | In-edge entries of the transpose carry the **forward** edge index, so a property array works from both directions | `boostCsrUnsorted` bidir: in(0) = `(4→0 idx 3)`, `(5→0 idx 4)`; in(2) = `(0→2 idx 0)`, `(3→2 idx 1)`, `(5→2 idx 5)` (**verified**) | bgl-H:912-922 (backward payload is a `counting_iterator<EdgeIndex>(0)`); `assert_bidir_equal_in_both_dirs` (bgl-T:154-182). Applies only if Grafluent stores or exposes the inverse permutation |

---

## 6. Transpose, CSC view and in-degree (`CSR-T`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-T01 | `transposed()` reverses every edge: `contains(u→v) ⇔ transposed().contains(v→u)` and `edgeCount` is unchanged | all fixtures | Boost `transpose_edges` (bgl-H:915-918); Ligra builds in-edges by sorting `(target, source)` (lig:233-270) |
| CSR-T02 | The transpose's rows are sorted. The counting-sort transpose of a canonical CSR is canonical | `boostCsrUnsorted` → T.offsets `[0,2,3,6,6,6,6]`, T.targets `[4,5, 4, 0,3,5]` (equals Boost's `m_backward`, **verified**) | scipy `csr_tocsc`: "Input: column indices *are not* assumed to be in sorted order. Output: row indices *will be* in sorted order" (sp-H:417-422) |
| CSR-T03 | `transposed().transposed() == g` | all fixtures | — |
| CSR-T04 | In-degree from the transpose: `inDegree(of: v) == transposed().outDegree(of: v)` | neo4j: in-degrees `[0,1,2,1,2]`, in0 `[]`, in1 `[0]`, in2 `[0,1]`, in3 `[1]`, in4 `[2,3]` | n4j-T:503-532 |
| CSR-T05 | A symmetric graph is its own transpose: `g.transposed() == g` | Ligra `rMatGraph_J_5_100` (n = 128, m = 708, symmetric, **verified** by script); `petersen`, `cube`, `completeDirected3` | lig-IN |
| CSR-T06 | A self-loop stays in place under transpose | `jgraphtSparseDirected`: `7→7` in both; T row 7 `[7]` | — |
| CSR-T07 | Transpose of the empty and edgeless graphs keeps n | n = 0 → `[0]`; n = 10, m = 0 → eleven zeros | — |
| CSR-T08 | Transpose of a large graph with duplicates in its source data (in-row multiset becomes a set) | graph500 vertex 0: neo4j `Sorted` in0 `[12,26,50,50,52,82,82,82,106,109,172,186,250,250]` → Grafluent in0 `[12,26,50,52,82,106,109,172,186,250]` (10) | n4j-T:449-469 (expected computed by script) |
| CSR-T09 | **Decision: separate type or not.** Boost (`bidirectionalS`), neo4j and GAP store both directions in one object. scipy flips the format flag in O(1). JGraphT lets the caller choose none, lazy or full. The Grafluent README plans `CompressedSparseColumn` paired with CSR for `BidirectionalDirectedGraph`. Test that `CompressedSparseColumn(g)` and `g.transposed()` hold the same arrays | — | jgt-I:30-42; `testDirectedLazyNoIncomingFail`: in-edge queries throw `UnsupportedOperationException` without incoming support (jgt-T:78-86) |

---

## 7. Equality and hashing (`CSR-Q`)

No studied CSR library offers structural equality (petgraph's `Csr`, Boost, neo4j and GAP have none, and scipy's `==` is element-wise). These cases come from Grafluent's representation contract ("equality means equal vertex sets and equal edge sets; must not depend on insertion order") plus the canonical form.

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-Q01 | Two graphs built from permuted or duplicated inputs of the same edge set are `==` and hash equal | `pathWithChord` written with `1→3` once vs twice | Grafluent README §Representations; Boost order independence (bgl-T:228-292) |
| CSR-Q02 | Same edges, different vertex count → `!=` (trailing isolated vertex matters) | n = 3 vs n = 4, edges `0→1` | — |
| CSR-Q03 | Same offsets, different targets → `!=`; same targets, different offsets → `!=` | offsets `[0,1,2]` targets `[1,0]` vs offsets `[0,2,2]` targets `[0,1]` (both m = 2, n = 2) | catches an implementation that compares only `targets` |
| CSR-Q04 | `g != g.transposed()` for an asymmetric graph; `==` for a symmetric one | `directedPath3` vs `petersen` | — |
| CSR-Q05 | Hash consistency: `a == b ⇒ a.hashValue == b.hashValue` over all 3-vertex digraphs (2⁹ = 512) | — | the AM suite's "every 3-vertex matrix" test |
| CSR-Q06 | Equality agrees with other representations: `CompressedSparseRow(m) == CompressedSparseRow(AdjacencyList(m))` | all zero-based fixtures | — |
| CSR-Q07 | Equality is O(n + m) on canonical arrays. That is a performance property, so test only correctness | — | — |

---

## 8. Codable and serialization (`CSR-D`)

### 8a. Formats seen

| Library | Layout | Validation on read |
|---|---|---|
| neo4j | binary: `usize` type-name length, type-name bytes, `[node_count, edge_count]` as `NI`, `offsets` (n+1 × NI), `targets` (m × Target). Directed graphs write node values, then `csr_out`, then `csr_inc` (n4j:252-271, 274-311, 613-660) | Only the id type name. A `u32` file read as `usize` → `Error::InvalidIdType` (n4j:285-290; test n4j:1169-1192). No check of offsets or targets |
| GAP `.sg` | `bool directed`, `int64 num_edges`, `int64 num_nodes`, `int64 offsets[n+1]`, `int32 neighs[m]`, then for directed graphs the inverse arrays (gap-W:39-70, gap-R:254-300) | none |
| Ligra `AdjacencyGraph` (text) | `AdjacencyGraph`, `n`, `m`, then **n** offsets (no trailing m), then m targets (lig:184-216) | header word and token count (`len != n + m + 2` → "Bad input file", lig:196-201). The last row's end is implied as m (lig:226). Offsets are not checked. `m = 0` with a non-symmetric graph reads `temp[0]` out of bounds (lig:269) |
| GraphBLAS import | `Ap`, `Aj`, `Ax` plus a `jumbled` flag (rows may be unsorted) (grb-IC:35) | **fast import trusts the data by default**; "secure import" runs `GB_matvec_check` and returns `GrB_INVALID_OBJECT` on any inconsistency. The comment cites CWE-502 (grb-I:340-378) |
| scipy | `csr_array((data, indices, indptr))` | O(1) checks on construction (sp-C:117, 179-210); full checks only on `check_format(full_check=True)` (sp-C:212-225) |

### 8b. Cases

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-D01 | Round trip: `decode(encode(g)) == g`, with identical `offsets`/`targets`, for every fixture | neo4j round trips `(0,1),(0,2),(1,2),(1,3),(2,3),(3,1)` for `usize` and `u32`, comparing out- and in-neighbors per vertex (n4j:1045-1166) | — |
| CSR-D02 | The exact encoded form is pinned. **Decision**: either the sibling format `{"vertexCount": n, "edges": [s₀,t₀,…]}` (AM README) or raw arrays `{"offsets": […], "targets": […]}`. With raw arrays, n is implied by `offsets.count − 1`, so `vertexCount` must not also be stored, or must be checked against it | `directedPath3` → `{"offsets":[0,1,2,2],"targets":[1,2]}` | Recommendation in §13 |
| CSR-D03 | The empty graph encodes and decodes (`offsets: [0]`) | — | (Ligra cannot represent m = 0 safely; JGraphT cannot represent n = 0) |
| CSR-D04 | Width independence: a payload decodes the same whatever the in-memory index width | — | neo4j files are **not** portable between `u32` and `usize` (n4j:1169-1192). Grafluent's JSON should not mention the width |

### 8c. Validation of corrupt arrays (one decoding error per case; never a trap, never a corrupt value)

| ID | Corrupt payload (raw-array form) | Rule violated | Source of the rule |
|---|---|---|---|
| CSR-D10 | `offsets: []` | I01 (count must be ≥ 1) | scipy "index pointer has invalid length" (sp-C:1141-1142) |
| CSR-D11 | `offsets: [1, 1]`, `targets: [0]` | I02 (`offsets[0] == 0`) | sp-C:200-201 |
| CSR-D12 | `offsets: [0, 2, 1, 3]`, `targets: [1, 2, 0]` | I03 non-monotone | sp-C:219-220 |
| CSR-D13 | `offsets: [0, 1, 2]`, `targets: [1]` (last offset > count) | I04 | scipy "Last value of index pointer should be less than the size of index and data arrays" (sp-C:206-208) |
| CSR-D14 | `offsets: [0, 1]`, `targets: [0, 0]` (last offset < count; scipy would prune) | I04, strict | sp-C:1136-1150 (prune). **Decision**: reject, do not prune |
| CSR-D15 | `offsets: [0, 1, 1]`, `targets: [2]` (target == n) | I05 | "indices must be < N" (sp-C:214-216) |
| CSR-D16 | `targets: [-1]` | I05 | "indices must be >= 0" (sp-C:217-218) |
| CSR-D17 | `offsets: [0, 2, 2]`, `targets: [1, 0]` (row unsorted) | I06 | scipy flags it non-canonical (sp-H:306-318, 335-349) but keeps it. GraphBLAS calls it "jumbled". **Decision**: reject, or canonicalize. Recommend reject, so decoded values are already canonical and `==` stays exact |
| CSR-D18 | `offsets: [0, 2, 2]`, `targets: [1, 1]` (duplicate in row) | I06 strict | scipy `has_canonical_format` is false with duplicates (sp-TB:4652-4664) |
| CSR-D19 | A huge offset (`offsets: [0, 9223372036854775807]`) or a sum that overflows | I04 plus overflow safety | GraphBLAS "Problem too large: nvals" (grb-B:176-178) |
| CSR-D20 | Both `vertexCount` and `offsets` present and disagreeing (if both are encoded) | consistency | neo4j stores `[n, m]` redundantly with the arrays and never checks them (n4j:259-261, 292-306) |
| CSR-D21 | Missing key, wrong type (string where an int is expected), `null` | structural | — |
| CSR-D22 | Edge-list form (if chosen): odd-length `edges`, endpoint ≥ `vertexCount`, negative `vertexCount` | — | igraph "Invalid (odd) length of edges vector" (ig-IEL:265-267); same as the AM catalog's malformed encodings |
| CSR-D23 | Decoding limit: with the edge-list form, a tiny payload `{"vertexCount": 10¹², "edges": []}` would allocate 10¹² + 1 offsets. The raw-array form cannot amplify (the payload *is* the arrays) | — | AM README's `maximumDecodedVertexCountKey`. **Decision** in §13 |
| CSR-D24 | A flag in a payload cannot vouch for its own validity: there is no "trusted"/"sorted" flag | — | scipy shows the hazard: setting `has_canonical_format = True` on duplicated data makes `sum_duplicates` a silent no-op (sp-TB:4670-4681, 4711-4718) |

---

## 9. Large-graph cases (`CSR-G`)

| ID | Asserts | Fixture → expected | Source |
|---|---|---|---|
| CSR-G01 | Erdős–Rényi n = 1000, p = 0.001 and p = 0.0005 (seeded): building from an `AdjacencyList` and from the edge list give `==` graphs, invariants I01–I08 hold, and edge indices round-trip | — | bgl-T:356-362, 428-429 |
| CSR-G02 | Graph500 scale 8 (`resources/scale_8.graph500`, 4096 packed 12-byte edges, n = 256): **Grafluent** m = **2171** distinct edges including **19** distinct self-loops (85 loop entries); out0 `[37,157]`; in0 `[12,26,50,52,82,106,109,172,186,250]`; max out-degree 168; 15 isolated vertices. Expected values computed by script from the file | neo4j (keeps duplicates): n = 256, m = 4096, out0 `[37,157]`, in0 with repeats (n4j-T:449-469) | n4j-T:449-491; decode `v0 = v0_low \| (high & 0xFFFF) << 32`, `v1 = v1_low \| (high >> 16) << 32` (`src/input/graph500.rs:113-126`) |
| CSR-G03 | Ligra `rMatGraph_J_5_100`: n = 128, m = 708, already canonical (sorted, unique, no loops), symmetric, 3 isolated vertices, max degree 19, row 0 `[22,36,39,45,56,81,89,106]`. Building from its arrays must keep them unchanged, and `transposed() == g` | — | lig-IN (properties verified by script) |
| CSR-G04 | GAP Kronecker/uniform generators: `-g10` gives 1024 nodes and 10496 undirected edges, `-u10` gives 1024 and 16125 (after GAP's squish, which removes loops and duplicates). Usable only if Grafluent reproduces GAP's generator, so treat as optional | — | gap-TEST:`reference/graph-g10.out`, `graph-u10.out` |
| CSR-G05 | Complete digraph with loops, n = 200 (m = 40,000): every row is `0..<200`; `contains` is true everywhere | — | dense stress for binary search (derived) |
| CSR-G06 | Width boundary (only if a narrow index type is offered): a vertex count beyond the index type's range is rejected at construction | petgraph `Csr<…, u8>::with_nodes(300)` is **accepted** (**verified**): 300 rows, but only 256 addressable (`Ix::new` truncates with `x as u8`, pg-ix:60-75). scipy switches to int64 at exactly 2³¹ columns (`test_scalar_idx_dtype`, sp-TB:4720-4742) and at targets > int32 max (`test_constructor_largecol`, sp-TB:4553-4564) | — |
| CSR-G07 | A degree-skewed graph (one hub of out-degree ≥ 10⁴): successors sorted, binary search correct at both ends | — | derived from Graph500 skew (max out-degree 168 at scale 8) |

---

## 10. Preconditions (`CSR-P`) — exit tests

| ID | Expression | Expected |
|---|---|---|
| CSR-P01 | `successors(of: n)`, `successors(of: -1)` | trap (CSR-S09) |
| CSR-P02 | `outDegree(of: n)` | trap. petgraph returns 0 (**verified**) |
| CSR-P03 | `init(vertexCount: 2, edges: [0→2])` | trap (CSR-C17) |
| CSR-P04 | `init(vertexCount: -1, edges: [])` | trap |
| CSR-P05 | Sorted fast path with unsorted or duplicate input | trap, or a thrown error if the API is `throws` (CSR-C22–C25) |
| CSR-P06 | `source(ofEdgeAt: m)`, `target(ofEdgeAt: -1)` | trap (CSR-E04) |
| CSR-P07 | `contains(edge:)` out of range | **no trap**, returns `false` (CSR-L06) |

---

## 11. Value semantics and API shape (brief; mostly covered by sibling suites)

| ID | Asserts | Source |
|---|---|---|
| CSR-V01 | Copy-on-write: a copy's arrays are unaffected by building another graph from the same input buffer | — |
| CSR-V02 | `offsets`/`targets` exposure (if public): reading them yields exactly the canonical arrays, satisfying I01–I06, for each fixture in §12 | Boost exposes `m_rowstart`/`m_column` publicly (the test reads them, bgl-T:130-152); petgraph keeps them private but tests read them in-module (pg:929-930) |
| CSR-V03 | `Sendable`; can be shared across tasks without copying | — |
| CSR-V04 | Boost's graph-level property bundle (`graph_name`) is out of scope | bgl-T:364-377 |

---

## 12. Fixture graphs with expected CSR arrays (`CSR-F`)

"T." means the transpose (CSC of g = CSR of the reverse graph). All arrays assume Grafluent's canonical form: sorted rows, duplicates collapsed, loops kept. Values were computed by `fixtures.py` (next to this file).

### 12a. Existing `DirectedFixtures` (zero-based ones)

| Fixture | n | m | offsets | targets | T.offsets | T.targets |
|---|---|---|---|---|---|---|
| `empty` | 0 | 0 | `[0]` | `[]` | `[0]` | `[]` |
| `trivial` | 1 | 0 | `[0,0]` | `[]` | `[0,0]` | `[]` |
| `singleSelfLoop` | 1 | 1 | `[0,1]` | `[0]` | `[0,1]` | `[0]` |
| `isolatedVertices` | 10 | 0 | eleven `0`s | `[]` | eleven `0`s | `[]` |
| `directedPath3` | 3 | 2 | `[0,1,2,2]` | `[1,2]` | `[0,0,1,2]` | `[0,1]` |
| `completeDirected3` | 3 | 6 | `[0,2,4,6]` | `[1,2,0,2,0,1]` | `[0,2,4,6]` | `[1,2,0,2,0,1]` |
| `networkXFunctionGraph` | 5 | 6 | `[0,3,6,6,6,6]` | `[1,2,3,0,1,2]` | `[0,1,3,5,6,6]` | `[1,0,1,0,1,0]` |
| `house` | 6 | 7 | `[0,0,1,2,4,6,7]` | `[0,1,2,4,0,1,3]` | `[0,2,4,5,6,7,7]` | `[1,4,2,4,3,5,3]` |
| `scc9` | 9 | 11 | `[0,1,2,3,4,5,6,7,9,11]` | `[3,7,5,6,1,8,0,4,5,2,6]` | `[0,1,2,3,4,5,7,9,10,11]` | `[6,4,8,0,7,2,7,3,8,1,5]` |
| `pathWithChord` | 6 | 6 | `[0,1,3,4,5,6,6]` | `[1,2,3,3,4,5]` | `[0,0,1,2,4,5,6]` | `[0,1,1,2,3,4]` |
| `boostExample` | 6 | 7 | `[0,0,2,4,5,6,7]` | `[2,5,0,2,4,3,0]` | `[0,2,2,4,5,6,7]` | `[2,5,1,2,4,3,1]` |
| `petgraphEdgesDirected` | 7 | 9 | `[0,4,5,7,7,8,8,9]` | `[1,2,3,5,3,3,4,0,6]` | `[0,1,2,3,6,7,8,9]` | `[4,0,0,0,1,2,2,0,6]` |
| `igraphReverseEdges` | 5 | 5 | `[0,1,3,4,5,5]` | `[1,2,4,3,1]` | `[0,0,2,3,4,5]` | `[0,3,1,2,1]` |
| `jgraphtMatrixCSV` | 5 | 10 | `[0,2,2,4,5,10]` | `[1,2,0,3,4,0,1,2,3,4]` | `[0,2,4,6,8,10]` | `[2,4,0,4,0,4,2,4,3,4]` |
| `directedCycle10` | 10 | 10 | `[0,1,…,10]` | `[1,2,3,4,5,6,7,8,9,0]` | `[0,1,…,10]` | `[9,0,1,2,3,4,5,6,7,8]` |
| `boost24` | 24 | 43 | `[0,0,1,3,5,7,8,9,11,13,15,18,21,24,27,29,31,33,34,35,37,39,41,42,43]` | `[2,5,10,0,10,0,5,14,3,11,17,1,17,1,11,8,15,19,4,15,19,4,8,19,4,8,15,12,22,6,22,6,12,20,9,18,23,13,23,13,18,21,16]` | `[0,2,4,5,6,9,11,13,13,16,17,19,21,23,25,26,29,30,32,34,37,38,39,41,43]` | `[3,4,8,9,1,6,11,12,13,2,4,15,16,10,12,13,18,2,3,7,9,14,16,20,21,5,10,11,13,23,7,8,19,21,10,11,12,17,22,14,15,19,20]` |
| `selfLoopsAndDuplicates` (1-based, so n = 6 with vertex 0 isolated) | 6 | 6 | `[0,0,1,3,3,4,6]` | `[2,3,4,4,2,5]` | `[0,0,0,2,3,5,6]` | `[1,5,2,2,4,5]` |

`directedCycle4` and `triangleWithReciprocalEdge` are 1-based. Use them with n = max + 1, or leave them out (`DirectedFixture.zeroBased` already excludes them).

### 12b. New fixtures harvested for CSR (suggest adding to `GrafluentTestSupport`)

| Name | Edges as written | n | m | offsets | targets | T.offsets | T.targets | Source |
|---|---|---|---|---|---|---|---|---|
| F-BUNS `boostCsrUnsorted` | `(5,0),(3,2),(4,1),(4,0),(0,2),(5,2)` | 6 | 6 | `[0,1,1,1,2,4,6]` | `[2,2,0,1,0,2]` | `[0,2,3,6,6,6,6]` | `[4,5,4,0,3,5]` | bgl-T:436-438 |
| F-BPROP `boostCsrProps` | `(0,1),(0,3),(1,2),(3,1),(3,4),(4,2)` with weights `1,1,0.5,1,1,0.5`; Brandes centrality `[0,1.5,0,1,0.5]` | 5 | 6 | `[0,2,3,3,5,6]` | `[1,3,2,1,4,2]` | `[0,0,2,4,5,6]` | `[0,3,1,4,0,3]` | bgl-T:391-414 |
| F-BWEB `boostWebGraph` | `(0,1),(0,2),(0,3),(1,0),(1,3),(1,5),(2,0),(2,5),(3,1),(3,4),(4,1),(5,0),(5,2)` (sorted fast path) | 6 | 13 | `[0,3,6,8,10,11,13]` | `[1,2,3,0,3,5,0,5,1,4,1,0,2]` | `[0,3,6,8,10,11,13]` | `[1,2,5,0,3,4,0,5,0,1,3,1,2]` | bgl-EX:37-41 |
| F-PG1 `petgraphCsr1` | `(0,0),(1,2),(2,2),(0,2),(1,0),(1,1)`, then `(1,2)` again (rejected as present) | 3 | 6 | `[0,2,5,6]` | `[0,2,0,1,2,2]` | `[0,2,3,6]` | `[0,1,1,0,1,2]` | pg:919-940 |
| F-PGFROM `petgraphCsrFrom` | `(0,1),(0,2),(1,0),(1,1),(2,2),(2,4)` | 5 | 6 | `[0,2,4,6,6,6]` | `[1,2,0,1,2,4]` | `[0,1,3,5,5,6]` | `[1,0,1,0,2,2]` | pg:978-988 |
| F-PGBF `petgraphBellmanFord` | `(0,1,.5),(0,2,2),(1,0,1),(1,1,1),(1,2,1),(1,3,1),(2,3,3),(4,5,1),(5,7,2),(6,7,1),(7,8,3)`; distances from 0 `[0,.5,1.5,1.5,∞…]` | 9 | 11 | `[0,2,6,7,7,8,9,10,11,11]` | `[1,2,0,1,2,3,3,5,7,7,8]` | `[0,1,3,5,7,7,8,8,10,11]` | `[1,0,1,0,1,1,2,4,5,6,7]` | pg:1065-1087, 1158-1184 |
| F-N4J `neo4jDirected` | `(0,1),(0,2),(1,2),(1,3),(2,4),(3,4)` | 5 | 6 | `[0,2,4,5,6,6]` | `[1,2,2,3,4,4]` | `[0,0,1,3,4,6]` | `[0,0,1,1,2,3]` | n4j-T:68-76, 493-532 |
| F-N4JS `neo4jSerialize` | `(0,1),(0,2),(1,2),(1,3),(2,3),(3,1)` | 4 | 6 | `[0,2,4,5,6]` | `[1,2,2,3,3,1]` | `[0,0,2,4,6]` | `[0,3,0,1,1,2]` | n4j:1045-1082 |
| F-JGT `jgraphtSparseDirected` | `(0,1),(1,0),(1,4),(1,5),(1,6),(2,4)×3,(3,4),(4,5),(5,6),(7,6),(7,7)` (13 written; JGraphT keeps 13 with ids 0–12, `getAllEdges(2,4) == {5,6,7}`) | 8 | 11 | `[0,1,5,6,7,8,9,9,11]` | `[1,0,4,5,6,4,4,5,6,6,7]` | `[0,1,2,2,2,5,7,10,11]` | `[1,0,1,2,3,1,4,1,5,7,7]` | jgt-T:396-536 |
| F-NXORD `nxCycleOrdering` | cycle `1→2→3→1` relabelled by nodelist `[3,2,1]` | 3 | 3 | `[0,1,2,3]` | `[2,0,1]` | `[0,1,2,3]` | `[1,2,0]` | nx:180-188 |
| F-SP1 `scipyConstructor1` | dense `[[0,4,0],[3,0,0],[0,2,0]]` | 3 | 3 | `[0,1,2,3]` | `[1,0,1]` | `[0,1,3,3]` | `[1,0,2]` | sp-TB:4467-4477 |
| F-SP2 `scipyConstructor2` | one edge `3→4` | 6 | 1 | `[0,0,0,0,1,1,1]` | `[4]` | `[0,0,0,0,0,1,1]` | `[3]` | sp-TB:4479-4486 |
| F-GAP4 `gap4el` | `test/graphs/4.el`: 256 lines, n = 14 (max id 13) | 14 | 58 | `[0,13,13,18,23,24,24,24,34,44,50,51,51,52,58]` | `[0,1,2,3,4,6,7,8,9,10,11,12,13, 1,4,6,9,10, 2,4,9,12,13, 6, 1,2,3,4,7,9,10,11,12,13, 1,2,3,4,7,8,9,11,12,13, 1,4,6,9,10,11, 1, 1, 2,4,9,10,11,13]` | `[0,1,8,13,16,23,23,27,30,32,39,44,49,53,58]` | `[0, 0,2,7,8,9,10,12, 0,3,7,8,13, 0,7,8, 0,2,3,7,8,9,13, 0,2,4,9, 0,7,8, 0,8, 0,2,3,7,8,9,13, 0,2,7,9,13, 0,7,8,9,13, 0,3,7,8, 0,3,7,8,13]` | gap-TEST. GAP without loops: m = 53, offsets `[0,12,12,17,22,23,23,23,32,41,46,47,47,48,53]` |
| F-LIG `ligraRMat` | the file's own arrays (already canonical, symmetric) | 128 | 708 | file lines 4–131 plus a trailing 708 | file lines 132–839 | = offsets | = targets | lig-IN |
| F-G500 `graph500Scale8` | the packed file (4096 edges) | 256 | 2171 | (generate) | (generate) | (generate) | (generate) | §9 CSR-G02 |

Licence note for the data files: `4.el` is BSD-3 (GAP), `scale_8.graph500` is MIT (neo4j-labs), and `rMatGraph_J_5_100` is MIT (Ligra). All three can be vendored with attribution. igraph is GPL, so use it for behavior only and copy no code or fixtures from it.

---

## 13. Design evidence for the open questions

**Q1. Store the inverse (predecessors/CSC) alongside?**

- *Always stored:* neo4j (`csr_out` + `csr_inc`, n4j:364-368), GAP (`invert = true` by default, gap-B:37-38; it skips the inverse only for symmetric graphs), igraph (`ii`/`is`), Ligra (builds in-edges unless `-s`, lig:228-300).
- *Optional:* Boost (`bidirectionalS` is a separate specialization with a "limited constructor set", bgl-DOC:43); JGraphT (`NO_`/`LAZY_`/`FULL_INCOMING_EDGES`, whose rationale is "several algorithms do not require the use of incoming edges … may save considerable amount of space", jgt-I:20-24).
- *Never:* petgraph; scipy (transpose by reinterpretation instead).
- Why they store it: pull-direction algorithms (GAP's direction-optimizing BFS and PageRank pull), O(1) in-degree, and igraph's `min(out_deg(u), in_deg(v))` lookup.
- Cost: it doubles memory, and the backward array has to carry the forward edge index (Boost) so that properties stay shared.
- *Recommendation:* keep `CompressedSparseRow` single-direction and make `transposed()` (or `CompressedSparseColumn(g)`) an explicit O(n + m) build. This matches the README's CSR + CSC pairing for `BidirectionalDirectedGraph`. If the pair is offered, have the CSC carry a permutation `forwardEdgeIndex` (Boost's design) and test CSR-E10.

**Q2. Index width.**

- petgraph: targets `Ix` (default `u32`), but **offsets `usize`**.
- GAP: ids `int32`, **offsets `int64`**.
- Boost: `Vertex` and `EdgeIndex` are independent, with `EdgeIndex ≥ Vertex`. The docs give the example "16-bit `Vertex` with 32-bit `EdgeIndex` allows a complete graph" (bgl-DOC:94-97).
- scipy: one dtype for both, upgraded to int64 only when needed. Mismatched dtypes are an error (gh-21959).
- neo4j: one type for both, which caps m at the vertex type's range. That is a real limitation.
- Everyone who narrows has to choose between truncating silently (petgraph `x as u32`, **verified** for `u8`) and checking.
- *Recommendation:* ship `Int`/`Int`. If a narrow variant is ever added, make offsets and targets independently generic, with offsets at least as wide, and check the range at construction (CSR-G06).

**Q3. Construction APIs.** Every mature library has at least three:

- unsorted edges (Boost single-pass and multi-pass; neo4j's default);
- a sorted fast path (Boost `edges_are_sorted`, petgraph `from_sorted_edges`);
- in-place sort of caller-owned source/target vectors (Boost `construct_inplace_from_sources_and_targets`, an in-place histogram sort, bgl-HS:155-190; GAP `MakeCSRInPlace`).

Hazards:

- Boost's sorted path trusts its input and is undefined behavior otherwise (it crashed).
- petgraph validates and returns `Err`.
- GraphBLAS detects sortedness for free during the bounds pass (grb-BR:390-571), so a separate fast-path API is unnecessary for correctness.

*Recommendation:*

- `init(vertexCount:edges:)`: general; counting sort by source, then per-row sort and dedup. Detect "already sorted" during the bounds pass, as GraphBLAS does.
- A throwing or trapping `init(vertexCount:sortedEdges:)`, only if benchmarks justify it.
- `init(_ other:)` from any `DirectedGraph`.
- A validating bulk/raw-array initializer that shares the decoder's checks.

**Q4. Expose raw `offsets`/`targets`?**

- Boost makes `m_rowstart`/`m_column` public members, and its tests read them directly.
- petgraph keeps them private.
- neo4j keeps them `pub(crate)`.
- GAP and scipy expose them; scipy's `indptr`/`indices` are even assignable, and the canonical-flag tests show the flag going stale when they are reassigned (sp-TB:4711-4718).

*Recommendation:* read-only exposure (`Span<Int>` or a borrowing view) is low-risk and enables interop (scipy-style export, GPU upload). Never allow mutation, and never add a "trusted" flag (CSR-D24).

**Q5. Edge identity and property arrays.**

- Boost: edge index = position in the CSR, with `edge_from_index` by upper-bound binary search (O(log n)). Its in-edges carry forward indices. Edge-property vectors are permuted together with the edges during construction.
- petgraph: the same position-based id, but it shifts on mutation (**verified**).
- JGraphT and igraph: ids in input order, with the CSR rows holding ids. That is stable under input permutation only if the caller keeps the order.
- Because Grafluent's rows are canonical and the type is immutable, the position id is both dense and **independent of input order** (CSR-E05). This is a guarantee none of the studied libraries makes.

*Recommendation:* offer `edgeIndex(source:target:) -> Int?` (binary search), `source(ofEdgeAt:)`/`target(ofEdgeAt:)`, and an initializer taking `(edge, value)` pairs with a `uniquingEdgesWith:` combine closure (CSR-E09). It returns the graph plus a `[Value]` aligned to edge indices, or a `WeightedCompressedSparseRow`.

**Codable format.** The raw-array form `{"offsets": [...], "targets": [...]}` cannot amplify allocations, maps directly onto I01–I06, and matches GAP's `.sg` and neo4j's layout. The sibling edge-list form keeps the representations' encodings uniform but needs a decoded-vertex-count limit. Either way, validate fully on decode, as GraphBLAS's secure import does (grb-I:341-378). No studied library validates by default.

---

## 14. Surprising disagreements

1. **Sorted rows are the exception, not the rule.** Boost (the reference CSR graph), JGraphT, scipy's constructors and neo4j's default layout all leave rows in input order. Only petgraph and GAP canonicalize. Grafluent's sorted-unique rows are a stronger contract than Boost's, so `contains` can be O(log d) where Boost's `edge(u, v)` is linear.
2. **neo4j's doc and code disagree about the default layout.** The doc comment says `Sorted` is the default ("This is the default representation", n4j:37-38), but `#[default]` is on `Unsorted` (n4j:40-41).
3. **"Deduplicated" means different things.** neo4j's `Deduplicated` and GAP's squish both silently delete self-loops (n4j:42-44, gap-B:139). scipy's canonical form keeps the diagonal. Grafluent keeps loops, so its edge counts on GAP's `4.el` differ (58 vs 53).
4. **Duplicates and values: five policies.** Error (GraphBLAS documented `dup == NULL`), last wins (`GxB_IGNORE_DUP`), sum (scipy COO → CSR), min (scipy csgraph `csgraph_to_dense`), arbitrary (neo4j). NetworkX additionally reads integer weights as parallel-edge *counts* when asked (nx:212-250).
5. **Empty graphs are second-class.** neo4j turns an empty edge list into a one-vertex graph. JGraphT forbids 0 rows. Ligra reads `temp[0]` when m = 0. NetworkX refuses to export a null graph (`to_scipy_sparse_array(nx.Graph())` raises, nx:170-172, nx-CM:670-671).
6. **Out-of-range handling is inconsistent even within one library.** petgraph's `contains_edge` panics for a bad source but returns `false` for a bad target. Its `out_degree(n)` returns 0. Boost asserts on sources but stores bad targets silently.
7. **The "sorted" constructor is a footgun in Boost.** The docs promise a "silently corrupt graph", but in practice it crashed with SIGBUS on a two-edge input.
8. **petgraph's `contains_edge` documents O(log |V|)** but is linear below 32 targets per row (pg:29, 368, 385). That is a reasonable optimization but a misleading doc. Grafluent's docs should say O(log outDegree).
