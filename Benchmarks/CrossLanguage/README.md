# Cross-language comparison

Grafluent against native graph libraries in other languages, on the same instance files:
petgraph and rustworkx-core (Rust), the Boost Graph Library, LEMON and Wheatman's PCSR (C++),
and igraph's C core. Nothing goes through Python.

```
just bench-cross                                   # full sizes, median of 5 runs per case
just bench-cross --scale smoke --repeat 3          # small sizes: checks the harness end to end
just bench-cross --only dijkstra bfs --libs grafluent bgl igraph
just bench-cross --instances gnm-1e6 --repeat 9
```

`run.py` does everything:

1. Checks the toolchains. It installs `boost` and `igraph` with Homebrew if missing, and fetches
   LEMON 1.3.1 into `.deps/` (checked by SHA-256). LEMON is not in Homebrew: the `lemon` formula
   there is SQLite's parser generator. LEMON's CMake script does not configure with current
   CMake, so `run.py` writes its one generated header itself and compiles `lemon/base.cc` with
   the harness. The graph algorithms are header-only.
2. Writes the instances once, to `data/<scale>/` (`gen.py`).
3. Builds each harness optimized:
   - Grafluent: `swift build -c release`, a client of the package by path, as an application
     would build it.
   - Rust: `cargo build --release`, with `opt-level = 3`, fat LTO and one codegen unit.
   - C++ and C: `xcrun clang++ -O3` and `xcrun clang -O3`, against Homebrew's Boost and igraph.
4. Runs each (library, algorithm, instance) case in its own process, `--repeat` times, and takes
   the median. `RAYON_NUM_THREADS=1` is set, so every library runs single-threaded.
   rustworkx-core's transitivity and betweenness are otherwise parallel.
5. Checks that the libraries agree, then prints one markdown table and saves it to
   `results/<timestamp>-<scale>.md`. Each table records the load average at the start and at
   the end, and the toolchain and library versions.

Run the full sizes on a quiet machine. The table shows the load average, so a noisy run is easy
to spot.

## What is timed

Only the algorithm. Each harness reads the instance file and builds its graph before the clock
starts. The `build` rows time construction separately: from edge arrays already in memory to
the library's graph. Answers are checked after timing. The exception is LEMON, whose results live
in the algorithm object: its BFS, DFS, Dijkstra and Bellman–Ford rows include an O(n) pass that
counts the reached vertices.

Each harness prints `RESULT <representation> <check> <ms,…>` per representation it runs, or
`NA <reason>`. In the table, Grafluent has two columns:

- AL is `AdjacencyList` for directed algorithms. For the others it is `UndirectedAdjacencyList`,
  `DirectedPseudograph` (flows, which may have repeated arcs) or `BipartiteGraph`.
- CSR is `CompressedSparseRow`. Its weights are permuted to its row order through
  `init(vertexCount:edges:edgeIndices:)`, and repeated arcs' capacities are added. On the dynamic
  rows (insert, walk after the inserts, remove) it is `PackedCompressedSparseRow`, the packed
  memory array of rows that stays mutable.

Every other library has one cell: its fastest representation, starred when that is not its default
one. BGL runs the directed traversals and shortest paths on both `adjacency_list<vecS, vecS>` and
`compressed_sparse_row_graph`. petgraph uses `Graph`. rustworkx-core uses `StableGraph`, which is
what rustworkx itself uses. LEMON uses `SmartDigraph`/`SmartGraph`, and igraph uses `igraph_t`. PCSR (Wheatman and Xu's
single-threaded packed CSR, one header pinned to a commit in `run.py`, its x86 bit scans replaced
by the compiler builtins at setup) runs the dynamic rows only, being a representation rather than
an algorithm library; LEMON's dynamic rows use `ListDigraph`, which has removal.

The dynamic rows time the operations a graph that changes between queries pays for: `insert` adds
the instance's arcs one at a time to a graph of n vertices; `insert-walk` then reads every row
(the layout the inserts left behind); `remove` takes the first half of the arcs out one at a time,
by endpoints where the library looks edges up that way (Grafluent, BGL, petgraph) and by the handle
insertion returned where it does not (LEMON, rustworkx-core's `StableGraph`). Each repeat of the
removals starts from a graph inserted afresh outside the timed region.
The ratio column is the fastest Grafluent time divided by the fastest other library's time.

## Instances (`gen.py`)

All randomness comes from the catalogs' 64-bit LCG (Knuth's MMIX constants, output `x >> 33`), as
in `Tests/Catalogs/Isomorphism/ref.py` and `Tests/Catalogs/DirectedAcyclicGraph/timings.py`. The
flow networks are FlowsBenchmarks' generators, with the same seeds at full size: `lcgnet(5000,
50000, 11, 1000)`, genrmf long (8, 256, 12) and wide (32, 16, 13), and vision 256 × 256 (16), so
they are the graphs FlowsBenchmarks times. The other Swift benchmarks draw from xoroshiro128+
through `Int.random(in:)`. Their instances have the same shapes and sizes
(G(10⁵, 10⁶), G(2000, 10⁴) for betweenness, G(10⁵, 5·10⁵) for PageRank, G(10⁵, 1.2·10⁵) for
bridges, G(2·10⁴, 6·10⁴) and 10⁵ + 10⁵ for matching, G(1000, 10⁴) for Floyd–Warshall), but they
are not the same graphs.

| Instance | Full size | Used by |
|---|---|---|
| `gnm-1e5`, `gnm-1e6` | G(10⁴, 10⁵), G(10⁵, 10⁶) | most rows, the dynamic rows |
| `grid-1e5`, `grid-1e6` | 224 × 224, 708 × 708 (edges point right and down) | traversal, paths, MST, topological sort, cut vertices |
| `ba-1e5`, `ba-1e6` | Barabási–Albert(2·10⁴, 5), (2·10⁵, 5), arcs oriented by a coin | power-law rows, the dynamic rows |
| `dag-1e5`, `dag-1e6` | forward pairs (10⁴, 10⁵), (10⁵, 10⁶) | topological sort |
| `flow-*` | as above | max flow |
| `match-gnm`, `match-bip` | G(2·10⁴, 6·10⁴); 10⁵ + 10⁵ with 3·10⁵ edges | matching |
| `iso-gnm`, `iso-grid` | G(2000, 10⁴) and 100 × 100, each against a relabelled copy | isomorphism |
| `bc-gnm`, `bc-ba` | G(2000, 10⁴), Barabási–Albert(2000, 5) | betweenness |
| `pr-gnm` | G(10⁵, 5·10⁵) | PageRank |
| `art-sparse` | G(10⁵, 1.2·10⁵) | components, articulation points, bridges |
| `fw-gnm` | G(1000, 10⁴) | Floyd–Warshall |

The smoke scale keeps every shape and shrinks it 20–100×. Apart from the flow networks, edges
are distinct unordered pairs without self-loops. Each edge therefore keeps its input position in
every library that stores edges in insertion order, and a weight array indexed by that position
stays aligned. Weights and capacities are integers from 1 to 1000. Libraries that only take
floating-point weights (igraph; petgraph's Bellman–Ford and Floyd–Warshall) get the same values
as `Double`.

## Agreement checks

| Algorithm | Check |
|---|---|
| build | vertex and edge counts |
| BFS, DFS | vertices reached from 0 |
| components | number of components |
| Dijkstra, Bellman–Ford | vertices reached, sum of distances |
| MST | tree edges, total weight |
| topological sort | the order is valid for every edge |
| max flow | flow value |
| matching | matching size |
| isomorphism | the decision |
| betweenness | sum of unnormalized scores, each unordered pair counted once (relative 10⁻⁶) |
| PageRank | Σ pᵢ · (i mod 97 + 1) with p normalized to sum 1 (relative 10⁻⁴; igraph solves exactly with PRPACK) |
| triangles, transitivity | count; value (relative 10⁻⁹) |
| articulation points, bridges | count |
| Floyd–Warshall | reachable ordered pairs, sum of distances |
| insert | vertex and edge counts |
| walk after the inserts, remove | arcs seen and Σ (u·n + v) over every row |

The table takes the answer most libraries gave as the reference. It marks every other answer with
✗ and lists it under Disagreements. A known one: rustworkx-core 0.17.1's `bridges` misses bridges
whose upper end is the root of a depth-first tree. It reports the bridge only inside the non-root
branch of its articulation-point test.

## Gaps (cells marked n/a)

- petgraph: no push–relabel (it has Dinic and Ford–Fulkerson), no betweenness, triangles or
  transitivity. Its `page_rank` is O(n²) per iteration with a fixed iteration count, so it is not
  run. Its general `maximum_matching` (Gabow) also fills the bipartite row.
- rustworkx-core: no SCC, MST, max flow, isomorphism, PageRank, Floyd–Warshall or triangle count.
  rustworkx gets these from petgraph or from its Python-facing crate. Its matching is the
  O(n³) weighted blossom (`max_weight_matching` with unit weights and `max_cardinality`), so it is
  skipped above 5000 vertices. Its topological sort is `lexicographical_topological_sort`, which
  keeps a heap.
- BGL: no Dinic, bridges, transitivity or preflow-only flow value. `push_relabel_max_flow` always
  completes the flow. `page_rank` has no dangling-vertex redistribution, so it gives a different
  answer and is not run. Prim spans only the root's component. Matching runs Edmonds with
  `no_matching_verifier`, so it skips the default verification pass. Triangles use
  `num_triangles_on_vertex`.
- LEMON 1.3.1: no Prim, Dinic, isomorphism, betweenness, PageRank, Floyd–Warshall, triangles or
  bipartite matching. `MaxMatching` fills the bipartite row.
- PCSR: a representation with insertion and update only (`add_edge`, `add_edge_update`), so no
  removal and none of the algorithm rows.
- igraph: no Dinic and no general (non-bipartite) matching. Its `igraph_add_edge` and
  `igraph_delete_edges` rebuild the edge index on every call, O(n + m) each, so the dynamic rows
  are not run. Its Dijkstra, Bellman–Ford, MST and
  flows take `double` weights. igraph caches graph properties in `igraph_t`, so the harness
  clears the cache before each timed run. At full size, `igraph_isomorphic_vf2` is not run on
  the 100 × 100 grid pair (`SKIP_FULL` in `run.py`), where its search does not finish in
  reasonable time.

## Layout

| Path | What |
|---|---|
| `run.py` | Setup, build, run, agreement checks, table |
| `gen.py` | Instance generator and file format |
| `swift/` | Grafluent harness (SwiftPM, depends on the repository by path) |
| `rust/` | petgraph and rustworkx-core harness (Cargo; `Cargo.lock` pins the versions) |
| `cpp/bgl.cpp`, `cpp/lemon.cpp`, `cpp/pcsr.cpp`, `cpp/common.hpp` | BGL, LEMON and PCSR harnesses |
| `c/igraph.c` | igraph harness |
| `data/`, `.deps/`, `build/` | Generated; ignored by git |
| `results/` | Tables; smoke tables are ignored by git |
