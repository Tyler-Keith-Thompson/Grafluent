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
| `TraversalBenchmarks` | Breadth-first and depth-first events, pulled with for-in and pushed with forEach, against hand-written loops (about 1.9× pulled, 1.4× pushed for breadth-first; about 1.8× pulled, 1.6× pushed for depth-first, every edge classified); `breadthFirstLayers` (about 1.2×); `AdjacencyList<String>`; an adjacency list searched in index space vs by hashing each neighbor (about 5×); depth-first preorder and topological sorting of a 1M-vertex path; `findCycle`; `descendants` |
| `ConnectivityBenchmarks` | Strong components against a hand-written Tarjan producing the same labels and grouping (CSR, 100k vertices and 400k edges: 6.0 ms against 6.8 ms; a 10⁶ path: 13 ms each), on `AdjacencyList<Int>` and `<String>`; weak components against a hand-written union–find; condensation; Lengauer–Tarjan dominator trees (10⁶ path, and Cooper–Harvey–Kennedy's quadratic family at 10⁵, 4.9 ms); dominance frontiers; `isStronglyConnected`. On `CompressedSparseRow` the engines walk its rows through `_withSuccessorIndexRows` with integer cursors; other representations pay a retain and release of the row storage per visited vertex |
| `DisjointSetBenchmarks` | `union` over 4M random pairs and 4M already-merged pairs, Kruskal-shaped unions over G(n, 4n), `find`, `labels()` against a hand-written union–find on 10⁶ elements (unions and `labels()` within 1.1×; a single checked `find` call about 1.25× a loop holding one buffer); `inSameSet`, `sets()`, `==` on values built in different orders, finds on a shared flat copy (no copy), `init(count:)` and `makeSet()`; weak components through `DisjointSet` against Connectivity's own |
| `PriorityQueueBenchmarks` | Dijkstra on G(10⁵, 10⁶) with `IndexedPriorityQueue` against a hand-written indexed 4-ary heap (19 ms against 21 ms; 13 against 16 with weights 1…4) and against swift-collections `Heap` with lazy deletion (31 ms); 10⁶ inserts and decreases then pop all (119 ms against 348 ms re-pushing into `Heap`); heap sort of 10⁶ `Int`s against `Heap` (122 ms against 73: use `Heap` when nothing is decreased). Arity, layout, tie-breaking and comparator variants were measured in the research prototype (`IndexedPriorityQueue`'s design notes): 4-ary, inline pairs, no tie rule, `Comparable` |
| `UndirectedAdjacencyListBenchmarks` | Building from 500k edges; breadth-first search through `directed` against a hand-written loop over `neighborIndices` (about 1.7×, as on the directed `AdjacencyList`); every neighborhood; O(1) `degree` and `contains(edge:)` through generic code at a 20k hub; removing the hub and every edge of a star; the first mutation of a copy; `==` on a copy |

Each benchmark that guards a property says so in its name ("must not allocate"). A regression
shows up in `just bench-compare` as a change in the median.
