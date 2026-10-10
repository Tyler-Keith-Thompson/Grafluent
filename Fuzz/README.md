# Fuzzing

Coverage-guided fuzz targets for [libFuzzer](https://llvm.org/docs/LibFuzzer.html), one per
component, in their own package so the library never links the fuzzer runtime.

| Target | Checks against |
|---|---|
| `FuzzPriorityQueue` | A dictionary from index to priority: every query after every operation; a snapshot drains in order |
| `FuzzDisjointSet` | A naive label array: union results, `find`, `inSameSet`, `setSize`, `setCount`, canonical `labels()`, equality with a rebuilt value |
| `FuzzAdjacencyList` | Sets of vertices and pairs: neighborhoods, degrees, dense vertex and edge indices, edge positions, equality and hashing, snapshots |
| `FuzzUndirectedAdjacencyList` | The same for unordered pairs, with self-loops listed twice and each position at both ends |
| `FuzzShortestPaths` | Floyd–Warshall: Dijkstra on two representations, single target, A*, unweighted, Bellman–Ford, the negative-cycle witness, undirected Dijkstra |
| `FuzzSpanningTrees` | Brute-force minimum and maximum spanning forests: Kruskal, Prim, Borůvka and the default agree on weight, every result is a spanning forest |
| `FuzzUndirectedConnectivity` | Brute force by deleting each edge or vertex: components, bridges, articulation points, blocks, bi-edge-connected components, on three conformers and after mutations |
| `FuzzWalks` | The definitions: every walk, trail, path, circuit and cycle constructor, conversions, equality and hashing up to rotation |
| `FuzzCycles` | Brute-force enumeration by edge identity on multigraphs with loops: `simpleCycles` (set, canonical form, documented order), the bounded filter, `girth`, `isAcyclic`, `findCycle`, a cycle basis of m − n + c independent cycles; on `UndirectedAdjacencyList` after removals, a conformer without indices, `AdjacencyList` and the directed view |
| `FuzzTrees` | The definitions on edge lists with loops and repeats: `Tree`, `Forest` and `Arborescence` exist exactly when they should; at every root, parents, depths, children, preorder, postorder, descendants, ancestors and paths against a breadth-first search; Prüfer codes round-trip; parent arrays rebuild the tree |
| `FuzzTreeAlgorithms` | Trees of up to 200 vertices (across the 64-entry range-minimum blocks): lowest common ancestors and distances against climbing for every pair, heavy–light segments against the path, the Euler tour, center, centroid, diameter and the centroid decomposition against brute force |
| `FuzzDistances` | Floyd–Warshall on multigraphs with loops, both kinds, unweighted and weighted: eccentricities, radius, diameter, center, periphery (by bounding too), centroid, Wiener index, the diameter path |
| `FuzzCentrality` | Definitions on multigraphs with loops, directed and undirected, unweighted and weighted, with and without vertex indices: degree by counting, closeness and harmonic over Floyd–Warshall, betweenness from shortest-path counts (parallel copies distinct) in every scaling, one-vertex forms; eigenvector, Katz, PageRank and HITS as fixed points of their equations |
| `FuzzCommunityDetection` | Definitions on multigraphs with loops, directed and undirected, unweighted and weighted, without vertex indices: modularity by the matrix definition, coverage and performance by counting pairs, every result a partition in canonical order, greedy modularity a local optimum, label propagation a fixed point, Louvain at least the singletons' modularity, representations agreeing |
| `FuzzBipartiteGraphs` | Recognition against brute force over side assignments on multigraphs with loops (canonical sides, valid canonical odd cycles, `BipartiteGraph(graph)` agreeing), and mutation sequences on `BipartiteGraph` against a model: the invariant, counts, sides, degrees, parallel rows, orientation, order-free equality and hashing, the `init(_:left:)` round trip |
| `FuzzMatching` | Brute force on multigraphs with loops and parallel edges, without vertex indices: maximal and maximum matchings, Hopcroft–Karp's size, the minimum-weight full matching against enumeration; `linearSumAssignment` against every assignment of small matrices with forbidden pairs, minimizing and maximizing; `stableMatching` stable, proposer-optimal and matching the same agents as every stable matching |
| `FuzzCovering` | Brute force over vertex subsets on multigraphs with loops, without vertex indices: the lexicographically least maximum independent set, its complement as the minimum vertex cover, the least minimum dominating set, both approximations within their bounds of the weighted optima, maximality, König's cover as the minimum cover with the most left vertices, edge covers of n − ν edges, and the checks |
| `FuzzMultigraphs` | Random insertions and removals (newest copy, a position, every copy of a pair, a vertex) on the pseudographs against a model of positions with the swap-remove rule: counts, every edge at its position, `edges(between:)` oldest first, degrees, parallel rows, order-free equality and hashing |
| `FuzzCliques` | Brute force over vertex subsets on multigraphs with loops, with and without vertex indices: maximal cliques, clique number, the least maximum clique, core numbers by peeling, the degeneracy ordering's property, triangles, clustering, transitivity |

Each target reads its input as a sequence of small choices (`FuzzInput`): an operation and its
arguments, or a graph's size, edges and weights. Every byte string decodes, and a mutation of one
byte changes one choice, so libFuzzer explores operation sequences rather than parse errors.

## Running

| Command | Does |
|---|---|
| `just fuzz` | Every target for 60 s, all at once, splitting the cores between them |
| `just fuzz FuzzShortestPaths -t 600 -j 16` | One target for 10 minutes on 16 workers |
| `just fuzz-regress` | Replays every corpus once (seconds); run after changing a fuzzed module |
| `just fuzz-repro <target> <crash file>` | Replays a crash and writes a minimized copy beside it |

A run is bounded by wall time. New inputs that add coverage are merged into `Fuzz/Corpus/<target>/`
(local, not committed), so the next run resumes from there. Crashes are written to
`Fuzz/Crashes/<target>/`; each one becomes a test in the module's suite, and then the file is
deleted.

## Toolchain

Xcode's toolchain does not include the libFuzzer runtime (`libclang_rt.fuzzer_osx.a`); the
swift.org toolchains do. The scripts build with `swiftly run swift build +6.3.3` (override with
`GRAFLUENT_FUZZ_SWIFT`), so install it once with `swiftly install 6.3.3`. The build prints
`unknown argument: '-target-arch-variant'` while reading the newer SDK's interfaces, then falls
back and succeeds; the scripts hide it.

Targets are built in release mode with AddressSanitizer: preconditions stay on, and the unsafe
buffer code in the representations and the heap is checked for out-of-bounds access.

SwiftPM links each executable against its own `main`, which conflicts with libFuzzer's, so each
target has an `@main` that calls `runFuzzer`, which starts libFuzzer through
`LLVMFuzzerRunDriver`.

## Adding a target

Add `Sources/Fuzz<Name>/Fuzz<Name>.swift` with an `@main` enum calling `runFuzzer`, and a line in
`Package.swift`. Check against a model simple enough to be obviously right, check after every
operation, keep values small (vertices 0..<10, priorities 0..<8) so collisions and ties are common,
and include a snapshot copy to catch copy-on-write bugs.
