# CommunityDetection test suite

`CommunityDetection` partitions a graph's vertices into communities and scores partitions:
modularity (Newman–Girvan with a resolution γ; Leicht–Newman on directed graphs), coverage and
performance, the constant Potts model, Louvain (and its levels), Leiden and hierarchical Leiden, greedy modularity
(Clauset–Newman–Moore), label propagation, semi-synchronous and asynchronous, Girvan–Newman's
sequence of partitions, Kernighan–Lin bisection, k-clique percolation, asynchronous fluid
communities, Walktrap and leading-eigenvector communities, spectral clustering (Ng–Jordan–Weiss),
and the split of a grouping into its connected parts, on `Graph` and (modularity, quality, the constant Potts model, Louvain, Leiden, hierarchical Leiden,
greedy, the component split) `DirectedGraph`, unweighted and weighted. The API description (`api.md`) is in
[`Tests/Catalogs/CommunityDetection/`](../Catalogs/CommunityDetection/). The suite uses only the
public API, and each test is self-contained. The shared material is the `ReferencePseudograph` and
`ReferenceDirectedMultigraph` test conformers, `Collider`, the seeded generator and the tags in
`GrafluentTestSupport`. Conformers private to a file model representations the package does not
have: no vertex or edge indices, rows and vertex orders shuffled by a seed, or a generator that
counts its draws.

## API under test

```swift
extension Graph {                       // partitions are Partition<DirectedView<Self>>
    func modularity<C>(of: C, resolution: Double = 1) -> Double          // C: Collection of vertex collections
    func modularity<C, W: BinaryFloatingPoint>(of: C, weight: (Edges.Index) -> W, resolution: Double = 1) -> Double
    func partitionQuality<C>(of: C) -> PartitionQuality                  // coverage, performance
    func louvainCommunities(resolution: 1, threshold: 1e-7) -> Partition<…>   // also (weight:…), each also (…, using:)
    func greedyModularityCommunities(resolution: 1) -> Partition<…>          // also (weight:resolution:)
    func labelPropagationCommunities() -> Partition<…>                        // also (weight:)
    func asynchronousLabelPropagationCommunities() -> Partition<…>            // also (weight:), each also (using:)
    func girvanNewmanCommunities() -> GirvanNewmanSequence<Self>              // a lazy Sequence of Partition<…>, coarsest first
    func constantPottsModel<C>(of: C, resolution: Double = 1) -> Double      // also (of:weight:resolution:)
    func leidenCommunities(quality: .modularity, resolution: 1, randomness: 0.01, iterations: nil, using:) -> Partition<…>  // also (weight:…), each also without using:
    func hierarchicalLeidenCommunities(maximumCommunitySize:, quality: .modularity, resolution: 1, randomness: 0.01, iterations: nil, using:) -> CommunityHierarchy<…>  // also (weight:…), each also without using:
    func louvainPartitions(resolution: 1, threshold: 1e-7) -> [Partition<…>]  // finest first; also (weight:…), each also (…, using:)
    func lazy.louvain(resolution: 1, threshold: 1e-7) -> LouvainEvents<…>  // lazy, index order; also (weight:…); Element LouvainEvent<…>:
        // move(v, from:, to:, gain:), levelFinished(Partition, modularity:), aggregate(vertexCount:)
    func connectedComponents<C>(within: C) -> Partition<…>                    // DirectedGraph: weaklyConnectedComponents(within:)
    func kernighanLinBisection(iterations: 10, using:) -> Partition<…>        // also (startingFrom:iterations:), each also (weight:…), and without using:
    func kCliqueCommunities(_ k: Int) -> [[Vertex]]                           // overlapping
    func asynchronousFluidCommunities(count:iterations: 100, using:) -> Partition<…>  // also without using:
    func walktrapCommunities(steps: 4) -> Partition<…>                        // also (weight:steps:)
    func leadingEigenvectorCommunities(tolerance: 1e-10, maxIterations: nil) throws(NoConvergence) -> Partition<…>  // also (weight:…)
}
extension DirectedGraph {               // the same measures, Louvain and greedy modularity, returning Partition<Self>
}
struct Partition<G: DirectedGraph>: RandomAccessCollection, Equatable, CustomStringConvertible
    // Element = ArraySlice<G.Vertex>; community(of:) traps on a non-vertex, community(ofIndex:) out of range;
    // community(checked:) throws VertexNotFound instead
struct PartitionQuality: Hashable, Sendable   // coverage, performance; NaN where the ratio is 0/0
struct GirvanNewmanSequence<G: Graph>: Sequence   // Element = Partition<DirectedView<G>>; each iterator starts over
// Partition is Sendable when G and G.Vertex are
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Canonical order | Communities by least vertex number (vertex index, or position in `vertices`), each in `vertices` order, whatever labels an algorithm used; `Equatable` compares communities, so equal partitions from different algorithms or graphs are equal | CD-090, every partition row, `CommunityDetectionConformanceTests.swift` |
| Modularity | Σ_c [L_c/m − γ (d_c/2m)²]; an undirected loop is A_vv = 2w (inside its community, twice in the degree), parallel edges add; directed Σ_c [L_c/m − γ out_c in_c/m²], a loop one out- and one in-arc; `graph.directedView` gives the undirected value; 0 when m = 0; empty communities contribute 0 | CD-001, CD-010, CD-016, CD-023, CD-024, CD-035 – CD-068 |
| Partition quality | Coverage over edges, copies each counted, a loop inside, NaN without edges; performance over unordered (directed: ordered) pairs u ≠ v by adjacency ("at least one edge"), loops are not pairs, NaN with fewer than two vertices | CD-002, CD-003, CD-015, CD-021, CD-022, CD-069 – CD-082 |
| Louvain | Vertices in index order; stay when the own community ties the best gain, other ties to the greatest community label; levels stop when modularity rises by no more than `threshold`; parallel edges are weight, loops count in degrees and never move a vertex; Dugué–Perez gain on `DirectedGraph` | CD-083 – CD-114, CD-174 |
| Greedy modularity | CNM: greatest ΔQ, ties to the least pair (i, j), i merged into j; merges with ΔQ = 0 continue; zero total weight gives singletons | CD-115 – CD-132, CD-173 |
| Label propagation | Votes are the row: copies each vote, loops vote for nothing, weights add; keep the current label when it is among the most voted, else take the greatest. Semi-synchronous: largest-degree-first greedy coloring, classes in color order. Asynchronous: index order each sweep | CD-133 – CD-154 |
| `using:` | Louvain shuffles each level's order, asynchronous propagation each sweep's order and its ties; the catalog's `using:` rows are graphs where every order gives the same partition; otherwise properties: a partition in canonical order, Louvain's Q at least the singletons', the stop condition, the same seed repeating, at least n − 1 draws, and orders that differ from index order | CD-112 – CD-114, CD-153, CD-154 |
| Determinism | With integer weights a result is a function of the vertex numbering and the weighted edges: the same twice, with rows and positions permuted, on the adjacency lists, on a conformer without indices, and (Louvain, greedy) on `graph.directedView` | `CommunityDetectionPropertyTests.swift`, `CommunityDetectionConformanceTests.swift` |
| Girvan–Newman | Remove the edge of greatest betweenness (Brandes' accumulation, recomputed on the removed edge's component only), ties to the least edge position by exact equality of the computed scores; a partition each time the number of components grows, ending with every vertex alone; parallel copies share their pairs' paths; self-loops never matter; without non-loop edges, the components once | CD-175 – CD-191 |
| Leiden | Move phase from a shuffled queue (an empty community is a choice, ties stay), refinement within each community (well-connected vertices join well-connected neighboring refined communities with gain ≥ 0, or stay, with probability ∝ exp(ΔH/θ)), aggregation; iterations until one changes nothing (node optimal), then each community split into its connected parts | CD-200 – CD-212, `LeidenTests.swift`, `LeidenPropertyTests.swift` |
| Kernighan–Lin | NetworkX's alternating single moves, heap ties to the earliest insertion, the best prefix while it lowers the cut | CD-218 – CD-223, `KernighanLinTests.swift` |
| Walktrap | Exact Ward merges of adjacent communities by Δσ over t-step walks with an added loop per vertex, ties to the least pair of community numbers, the cut of greatest modularity | CD-230 – CD-235 |
| Leading eigenvector | Bisection by the signs of B⁽ᵍ⁾'s leading eigenvector (zero entries to the side of greater gain), dense below 64 vertices, Lanczos above | CD-236 – CD-240, `LeadingEigenvectorTests.swift` |
| Spectral clustering | The unit rows of N's k smallest eigenvectors, k-means: the least inertia of 10 k-means++ runs from the generator, Lloyd's iteration until nothing changes or 300 iterations, an emptied cluster taking the farthest row; exactly k communities | CD-241 – CD-248, `SpectralClusteringTests.swift` |
| Weights | Read once per edge in position order, checked there: finite and ≥ 0 (-0.0 accepted); `Float` closures work as `Double` ones; nothing is read on an edgeless graph | CD-160 – CD-162, CD-167, CD-168, CD-170 – CD-172, `WeightReadingTests.swift` |

## How values are pinned

Every catalog row is written as the catalog writes it (listed vertices first, then endpoints by
first appearance, `nx(…)` graphs with NetworkX's node list and edge order, `lcg(…)` pairs and their
first-appearance vertex order; edges in written order, repeats and loops kept) on the
`ReferencePseudograph` or `ReferenceDirectedMultigraph`, whose rows are in position order, so every
vertex number and edge position is exact. The catalog-row files and the representation file are
generated from `cases.md` by `swiftgen.py` (next to `ref.py` and `cases.md` in
[`Tests/Catalogs/CommunityDetection/`](../Catalogs/CommunityDetection/), which says how to run it),
which re-evaluates each row with `ref.py`'s model, asserts that it matches the catalog cell, and
writes the model's value at full precision; the catalog cells are the same values rounded to 12
digits. Scalars compare within 1e-12 relative to max(1, |value|), partitions exactly in canonical
order. Each partition row also checks `count`, `community(of:)` against membership,
`community(ofIndex:)` against `community(of:)`, and the modularity of the result at the call's
weight and resolution against `ref.py`'s value; each undirected row of modularity, partition
quality, Louvain and greedy modularity runs again on `graph.directedView` (the values `ref.py` gives
for `directed > op`, which are the same), and each `using:` row runs twice with the same seed. The
`CompressedSparseRow` and `AdjacencyMatrix` rows rewrite the arcs in row-major order (undirected
graphs without loops as symmetric digraphs) and were computed by `ref.py` on the rewritten graph.
The stress literals were computed with `ref.py`'s model functions at their sizes (`stress_vals.py`,
`stress3.py` and `stress4.py`, next to it) and are written as the closed forms the output follows
(or derived in closed form, for the modularity and quality of a ring of cliques).

The property tests write their oracles inside each test.

## Files

| File | Tests | Covers |
|---|---|---|
| `DegenerateGraphTests.swift` | 34 | §A: the empty graph (both kinds), one vertex, four isolated vertices, lone loops, K₂, one arc: every entry point |
| `ModularityTests.swift` | 34 | §B: P₃ with every split, empty communities and community order, K₄, two triangles at γ = 0, ½, 1, 2 and weighted (heavy, scaled, zero bridge), `connectedComponents()`, two K₅, barbell, ring of cliques, the karate club (observed split, weighted, `graph.directedView`), parallel edges as weight, loops (weighted, `graph.directedView`), Leicht–Newman on dipaths and two directed triangles, a directed loop, labeled vertices |
| `PartitionQualityTests.swift` | 14 | §C: two triangles (split, singletons, components), the karate club, parallel edges, a loop, directed ordered pairs |
| `PartitionCheckedTests.swift` | 1 | `Partition.community(checked:)` on indexed, unindexed and directed graphs: agrees with `community(of:)`, throws `VertexNotFound` for a non-vertex |
| `LouvainTests.swift` | 33 | §D: cliques joined by edges, barbell, ring of cliques, caveman, the karate club (count, `community(of:)`, weighted, γ = 0, 0.5, 2, `threshold: 1`), Florentine families (`String` vertices), components, parallel edges, loops, a heavy bridge, path and cycle ties, a star, a grid, `lcg` graphs (also weighted), directed (two triangles, karate, `lcg`), `graph.directedView`, `using:`; CD-174 |
| `GreedyModularityTests.swift` | 21 | §E: the same families as §D, the karate club, ties to the least pair, parallel edges and loops, γ = 0, directed; CD-173; two merges with ΔQ = 0 exactly (one arc; a zero-weight bridge at γ = 0), which continue |
| `LabelPropagationTests.swift` | 22 | §F: semi-synchronous and asynchronous on cliques, ring of cliques (flooding in index order), the karate club (also weighted), paths, loops voting for nothing, parallel copies each voting, weights, `lcg`, `using:` |
| `CommunityDetectionPreconditionTests.swift` | 48 | Exit tests: the catalog's 18 trap rows (CD-155 – CD-172); then `community(of:)` on a non-vertex (both kinds), `community(ofIndex:)` at −1, at the count and on an empty result, `partitionQuality(of:)` with a vertex twice or a non-vertex (both kinds), directed modularity with a vertex missing, an infinite or negative resolution, a non-vertex on the empty graph, NaN and infinite resolutions and thresholds for Louvain and greedy modularity (both kinds, also through `using:`), negative, NaN and ±infinite weights through every weighted overload not covered by the catalog (also `Float`) |
| `GirvanNewmanTests.swift` | 17 | §H: no vertices, no edges, loops only, two triangles (the first, a tie-decided and the last level), two K₅, barbell, caveman, the karate club's first three levels (NetworkX's), Florentine families (`String` vertices), an already disconnected graph with a loop, parallel copies |
| `GirvanNewmanSequenceTests.swift` | 4 | The karate club's 33 levels; parallel copies against `edgeBetweennessCentrality`; a graph without vertex indices listed out of value order; laziness, restarting iterators, each level splitting one community of the last, `nil` after the end |
| `LeidenCatalogTests.swift` | 26 | §I: the constant Potts model (undirected, directed, weighted, loops and copies inside, the karate club), Leiden on graphs where every order gives one partition (both quality functions, γ, loops, parallel edges, directed), Louvain's levels; traps |
| `CommunityMethodsCatalogTests.swift` | 23 | §J: Kernighan–Lin from a start (NetworkX's), k-clique communities (NetworkX's, overlapping), Walktrap (exact model), leading eigenvector (igraph's); traps |
| `LeidenDrawTests.swift` | 34 | Leiden and fluid communities draw for draw with a SplitMix64 stream against `draws.py`'s exact model of the implementation (generated by it): inputs on which each planted bug of the move phase, refinement, stop test, final split into connected parts and fluid sweeps changes the answer, then 24 seeded multigraphs (both kinds, weights, both quality functions, `iterations`) |
| `LeidenTests.swift` | 13 | Leiden on cliques, the karate club's optimum for 20 seeds, degenerate graphs, weights and copies, directed, seeds, `iterations`, representations; `constantPottsModel(of:)`, `connectedComponents(within:)`, `louvainPartitions` |
| `LeidenPropertyTests.swift` | 3 | PropertyBased: Leiden node optimal for the quality by its definition, connected, canonical, repeatable; unweighted equals unit weights; the component split against a search |
| `LeidenPreconditionTests.swift` | 22 | Exit tests: randomness, resolution, iterations, weights, the constant Potts model's and Louvain levels' arguments, the component split's grouping |
| `KernighanLinTests.swift` | 5 | Hand cases and NetworkX's halves on the karate club, degenerate graphs, the random start; PropertyBased: sizes kept, the cut never raised |
| `OverlappingAndWalkCommunitiesTests.swift` | 6 | k-clique communities (hand cases, the karate club, brute force), fluid communities, Walktrap; PropertyBased partitions |
| `LeadingEigenvectorTests.swift` | 4 | igraph's karate club communities, small graphs, the Lanczos path and its budget; PropertyBased: every community indivisible by a dense eigensolver in the test |
| `SpectralClusteringCatalogTests.swift` | 8 | §K: two triangles, two components, one cluster, a tree where the unit rows decide, three triangles in a chain, a weight-0 edge; traps for the cluster count |
| `SpectralClusteringTests.swift` | 11 | Planted blocks for five seeds, the row scaling deciding, k-means++ seeding draw for draw over ten SplitMix64 seeds, components, the count at 1 and n, identical rows, an edgeless graph, determinism, weights (also `Float`), lookups on a graph without vertex indices; exit tests for the count, tolerance, `maxIterations`, a negative weight and a lookup off the graph; PropertyBased: 2 to 4 planted cliques recovered |
| `BisectionAndOverlapPreconditionTests.swift` | 12 | Exit tests for Kernighan–Lin, k-clique, fluid and Walktrap arguments |
| `Performance/SpectralClusteringStressTests.swift` | 1 | Six planted blocks of 500 vertices recovered exactly, under a one-minute limit |
| `Performance/LeidenStressTests.swift` | 3 | Leiden on 25,000 disjoint K₄, a ring of 1000 K₅ (both quality functions; Louvain's levels), a 20,000-vertex path and one iteration on 10⁵ vertices |
| `GirvanNewmanPropertyTests.swift` | 1 | PropertyBased: the levels against an oracle recomputing edge betweenness on the whole remaining graph (up to the first near tie); always n − c levels, each splitting one community in two, ending with singletons |
| `CommunityDetectionRepresentationTests.swift` | 88 | Every §A – §H value row whose graph has no parallel edges on `UndirectedAdjacencyList` (28 graphs) or `AdjacencyList` (7), and the modularity, quality, Louvain and greedy rows of every graph on 0..<n without parallel edges on `CompressedSparseRow` (26) and `AdjacencyMatrix` (26), directed graphs with their arcs in row-major order and loop-free undirected graphs as symmetric digraphs; one test per graph, every row of that graph |
| `WeightReadingTests.swift` | 7 | The weight closure once per edge in position order through every weighted entry point on a pseudograph with a loop and parallel edges, on `graph.directedView`, on a directed multigraph, on `UndirectedAdjacencyList`, `CompressedSparseRow` and `AdjacencyMatrix`; nothing read when there are no edges; -0.0 accepted; `Float` weights |
| `CommunityDetectionConformanceTests.swift` | 14 | `Sendable` across a `Task`, the result holding a copy of the graph, the result types, `RandomAccessCollection` (indices, slices keeping flat indices, reversal), `description`, `Equatable` across algorithms and graphs, generic code over `some Graph` / `some DirectedGraph`, any collection of vertex collections (sets, slices, lazy collections, `Components`, a `Partition`), conformers without indices (the `lcg` rows, vertices not in value order), `Collider` vertices, determinism across representations on the karate club, `using:` drawing from the generator and changing the order |
| `CommunityDetectionPropertyTests.swift` | 9 | PropertyBased, shrinking, multigraphs with loops, shuffled rows and vertex orders: modularity against the matrix definition (both kinds, γ, weights, community order, `graph.directedView`, γ = 0 as coverage); quality against pair counts; every overload returns a canonical partition; Louvain and greedy at least the singletons' Q, greedy locally optimal under merges; label propagation's stop condition; representation independence; weight scaling; γ = 0 gives the components; `using:` repeats |
| `LouvainEventsTests.swift` | 6 | CD-900 – CD-905: Louvain as events, two traced graphs against `cases_events.py`, trivial, directed and weighted graphs, value semantics, traps, a property test replaying `louvainPartitions` |
| `Performance/LouvainEventsRatioTests.swift` | 1 | CD-906: every event within 1.8× of `louvainCommunities` (release) |
| `Performance/CommunityDetectionStressTests.swift` | 9 | Inside a `Task` with a one-minute limit: Louvain on 25,000 disjoint K₄ (also `using:`), a ring of 1000 K₅ and a 10⁵-vertex path; greedy modularity on a ring of 400 K₅; both propagations on a 10⁵-vertex path and 20,000 disjoint K₅; modularity and quality on a ring of 25,000 K₄; directed Louvain and greedy on disjoint 3-cycles on `CompressedSparseRow` |

248 catalog rows (222 value rows, 26 trap rows) and their 88 representation tests, the
hand-written, property and precondition tests listed above: 522 tests in `CommunityDetectionTests`
and 13 in `CommunityDetectionPerformanceTests`.

## Case IDs

Case IDs (CD-001 … CD-248) refer to the catalog (`cases.md`). Each test's name starts with its IDs; tests without an ID check laws,
representations, properties or conformance that the catalog does not list.

| Cases | Section | File |
|---|---|---|
| CD-001 – CD-034 | A. Degenerate graphs | `DegenerateGraphTests.swift`; again in `CommunityDetectionRepresentationTests.swift` |
| CD-035 – CD-068 | B. Modularity | `ModularityTests.swift`; again in `CommunityDetectionRepresentationTests.swift` |
| CD-069 – CD-082 | C. Partition quality | `PartitionQualityTests.swift`; again in `CommunityDetectionRepresentationTests.swift` |
| CD-083 – CD-114 | D. Louvain | `LouvainTests.swift`; again in `CommunityDetectionRepresentationTests.swift` |
| CD-115 – CD-132 | E. Greedy modularity | `GreedyModularityTests.swift`; again in `CommunityDetectionRepresentationTests.swift` |
| CD-133 – CD-154 | F. Label propagation | `LabelPropagationTests.swift`; again in `CommunityDetectionRepresentationTests.swift` |
| CD-155 – CD-172 | G. Preconditions (traps) | `CommunityDetectionPreconditionTests.swift` |
| CD-173 | G. Greedy modularity at total weight 0 (not a trap) | `GreedyModularityTests.swift`; again in `CommunityDetectionRepresentationTests.swift` |
| CD-900 – CD-906 | Louvain as events (not in `cases.md`; CD-900 and CD-901 traced by `cases_events.py` into `cases_events.out`) | `LouvainEventsTests.swift`, `Performance/LouvainEventsRatioTests.swift` |
| CD-174 | G. Louvain at total weight 0 (not a trap) | `LouvainTests.swift`; again in `CommunityDetectionRepresentationTests.swift` |
| CD-192 – CD-217 | I. Leiden, the constant Potts model and Louvain's levels | `LeidenCatalogTests.swift` |
| CD-218 – CD-240 | J. Kernighan–Lin, k-clique, Walktrap and leading eigenvector | `CommunityMethodsCatalogTests.swift` |
| CD-241 – CD-248 | K. Spectral clustering | `SpectralClusteringCatalogTests.swift` |
| CD-175 – CD-191 | H. Girvan–Newman | `GirvanNewmanTests.swift`; again in `CommunityDetectionRepresentationTests.swift` (all but CD-190, CD-191) |

Rows with parallel edges (CD-058, CD-076, CD-077, CD-098, CD-127, CD-140, CD-141, CD-149, CD-151)
and the `lcg` rows (whose random pairs repeat) are not repeated on the adjacency lists, which cannot
hold parallel edges; label propagation and `graph.directedView` rows are not repeated on
`CompressedSparseRow` and `AdjacencyMatrix`, which are directed.

## Not tested

| Case | Why |
|---|---|
| The exact draw sequence of the `using:` overloads (Fisher–Yates from k − 1 down to 1 with `next(upperBound:)`, a tie drawn among the labels in order of first vote) | Pinning a seeded partition would pin the standard library's `next(upperBound:)` too. The suite checks properties instead: valid canonical partitions, Q at least the singletons', the stop condition, repetition with the same seed, at least n − 1 draws, and that shuffled orders change the result |
| Greedy modularity's merge history, `cutoff`, `best_n`, weighted or directed Girvan–Newman, directed label propagation, Infomap | Not part of the API |
| The exact draws of the random Kernighan–Lin start | As for `using:` above (Leiden's and fluid communities' draws are pinned in `LeidenDrawTests.swift` against an exact model, whose SplitMix64 stream and Lemire `next(upperBound:)` it reproduces) |
| Partitions from non-integer weights compared across representations | api.md: k_u,D is summed in row order, so different row orders may break a near-tie differently; the determinism tests use integer weights, and the karate weighted rows use integers |
| A zero-weight edge's vote in label propagation | A zero-weight edge casts no vote, which keeps propagation terminating. The suite uses zero weights only where a vote of weight 0 would not change the outcome: the stop condition in the property tests compares vote weights, and the -0.0 bridge in `WeightReadingTests.swift` |
| `Partition`'s `subscript` out of range | Unspecified; `Components` traps, and a `RandomAccessCollection` may |
| Complexity (O(n + m) per sweep, no allocation per sweep) | Benchmarks; the stress tests bound costs loosely (each shape within the time limit in a debug build) |
| NetworkX and igraph on random graphs (`just diff`) | Not Swift tests; `ref.py` checks every catalog row against NetworkX 3.7 where it shares the semantics, and the property tests use definition oracles |
