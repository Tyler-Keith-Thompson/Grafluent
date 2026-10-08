# Benchmarks

Performance properties that tests cannot assert live here: wall-clock time, and the number of
allocations, which is how copy-on-write and amortized growth are checked ("a no-op mutation of a
copy must not allocate", "4096 appends allocate O(log n) times").

The benchmarks are a separate SwiftPM package that depends on Grafluent by path, so neither the
library nor its tests depend on the benchmark framework
([ordo-one/benchmark](https://github.com/ordo-one/benchmark)). Bazel ignores this directory.
Allocation counts need jemalloc (`brew install jemalloc`).

| Command | Does |
|---|---|
| `just bench` | Run every benchmark |
| `just bench --target CompressedSparseRowBenchmarks` | One representation |
| `just bench-baseline` | Save the current results as the baseline `main` |
| `just bench-compare` | Compare against the saved baseline |

Inputs are generated from fixed seeds (`BenchmarkSupport`), so runs compare like with like.

## What is measured

| Target | Benchmarks |
|---|---|
| `AdjacencyListBenchmarks` | Building from 100k random edges; inserting them one at a time; `contains(edge:)`; visiting every successor; breadth-first search; on a 20k-leaf star, removing every leaf, every edge, or the hub (all linear, not quadratic); the first and a no-op mutation of a copy; `==` on a copy and on an equal graph built differently |
| `AdjacencyMatrixBenchmarks` | On 4096² matrices: iterating edges forward and backward; every row's successors and every column's predecessors; `contains` on a row; `transposed()`; `union`; 4096 appends from empty; Warshall's closure by row unions; a no-op write to a copy; `==` |
| `CompressedSparseRowBenchmarks` | On 1M random edges over 100k vertices: building from random edges, sorted edges, sorted edges with one repeat, parallel arrays, 1M edges with 10k distinct, and a 1M-edge hub (O(n + m) whatever the skew); building with edge indices; validating raw arrays; iterating edges, whole and through a slice; scanning every row, through `successors(of:)`, `withUnsafeBufferPointers`, and a raw-array baseline; breadth-first search; `contains(edge:)`; `source(ofEdgeAt:)`; `transposed()` with and without forward indices; `inDegrees` |
| `EdgeListBenchmarks` | On 1M random edges: building from a lazy sequence; `Array(list)` (must not copy); iterating, slice sorts (must not copy the list) and JSON encoding and decoding, each against a plain-array baseline; sorting by (source, target); `vertices`; one `outDegree` scan and every out-degree in one pass; `description`; `removeEdges(incidentTo:)`; a no-op mutation of a copy; `==` |
| `DirectedGraphBenchmarks` | Through the protocol: breadth-first search concrete vs generic vs existential (generic must match concrete; an existential allocates for every neighborhood); the matrix's O(1) `outDegree` and CSR's binary-search `contains(edge:)` reached from generic code |
| `TraversalBenchmarks` | Breadth-first and depth-first events, pulled with for-in and pushed with forEach, against hand-written loops (about 2.3× pulled, 1.8× pushed for breadth-first; about 2.2× for depth-first); `breadthFirstLayers` (about 1.2×); `AdjacencyList<String>`; an adjacency list searched in index space vs by hashing each neighbor (about 5×); depth-first preorder and topological sorting of a 1M-vertex path; `findCycle`; `descendants` |
| `ConnectivityBenchmarks` | Strong components against a hand-written Tarjan producing the same labels and grouping (CSR, 100k vertices and 400k edges: 6.0 ms against 6.8 ms; a 10⁶ path: 13 ms each), on `AdjacencyList<Int>` and `<String>`; weak components against a hand-written union–find; condensation; Lengauer–Tarjan dominator trees (10⁶ path, and Cooper–Harvey–Kennedy's quadratic family at 10⁵, 4.9 ms); dominance frontiers; `isStronglyConnected`. On `CompressedSparseRow` the engines walk its rows through `_withSuccessorIndexRows` with integer cursors; other representations pay a retain and release of the row storage per visited vertex |

Each benchmark that guards a property says so in its name ("must not allocate"). A regression
shows up in `just bench-compare` as a change in the median.
