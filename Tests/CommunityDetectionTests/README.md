# CommunityDetection test suite

`CommunityDetection` partitions a graph's vertices into communities and scores partitions:
modularity (Newman–Girvan with a resolution γ; Leicht–Newman on directed graphs), coverage and
performance, Louvain, greedy modularity (Clauset–Newman–Moore), and label propagation,
semi-synchronous and asynchronous, on `Graph` and (modularity, quality, Louvain, greedy)
`DirectedGraph`, unweighted and weighted. The tests were written before the implementation, from
the proposed API (`api.md`, phase 1). The suite uses only the public API, and each test is
self-contained. The shared material is the `ReferencePseudograph` and
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
}
extension DirectedGraph {               // the same measures, Louvain and greedy modularity, returning Partition<Self>
}
struct Partition<G: DirectedGraph>: RandomAccessCollection, Equatable, CustomStringConvertible
    // Element = ArraySlice<G.Vertex>; community(of:) traps on a non-vertex, community(ofIndex:) out of range
struct PartitionQuality: Hashable, Sendable   // coverage, performance; NaN where the ratio is 0/0
// Partition is Sendable when G and G.Vertex are
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Canonical order | Communities by least vertex number (vertex index, or position in `vertices`), each in `vertices` order, whatever labels an algorithm used; `Equatable` compares communities, so equal partitions from different algorithms or graphs are equal | CD-090, every partition row, `CommunityDetectionConformanceTests.swift` |
| Modularity | Σ_c [L_c/m − γ (d_c/2m)²]; an undirected loop is A_vv = 2w (inside its community, twice in the degree), parallel edges add; directed Σ_c [L_c/m − γ out_c in_c/m²], a loop one out- and one in-arc; `graph.directed` gives the undirected value; 0 when m = 0; empty communities contribute 0 | CD-001, CD-010, CD-016, CD-023, CD-024, CD-035 – CD-068 |
| Partition quality | Coverage over edges, copies each counted, a loop inside, NaN without edges; performance over unordered (directed: ordered) pairs u ≠ v by adjacency ("at least one edge"), loops are not pairs, NaN with fewer than two vertices | CD-002, CD-003, CD-015, CD-021, CD-022, CD-069 – CD-082 |
| Louvain | Vertices in index order; stay when the own community ties the best gain, other ties to the greatest community label; NetworkX's stop rule; parallel edges are weight, loops count in degrees and never move a vertex; Dugué–Perez gain on `DirectedGraph` | CD-083 – CD-114, CD-174 |
| Greedy modularity | CNM: greatest ΔQ, ties to the least pair (i, j), i merged into j; merges with ΔQ = 0 continue; zero total weight gives singletons | CD-115 – CD-132, CD-173 |
| Label propagation | Votes are the row: copies each vote, loops vote for nothing, weights add; keep the current label when it is among the most voted, else take the greatest. Semi-synchronous: largest-degree-first greedy coloring, classes in color order. Asynchronous: index order each sweep | CD-133 – CD-154 |
| `using:` | Louvain shuffles each level's order, asynchronous propagation each sweep's order and its ties; the catalog's `using:` rows are graphs where every order gives the same partition; otherwise properties: a partition in canonical order, Louvain's Q at least the singletons', the stop condition, the same seed repeating, at least n − 1 draws, and orders that differ from index order | CD-112 – CD-114, CD-153, CD-154 |
| Determinism | With integer weights a result is a function of the vertex numbering and the weighted edges: the same twice, with rows and positions permuted, on the adjacency lists, on a conformer without indices, and (Louvain, greedy) on `graph.directed` | `CommunityDetectionPropertyTests.swift`, `CommunityDetectionConformanceTests.swift` |
| Weights | Read once per edge in position order, checked there: finite and ≥ 0 (-0.0 accepted); `Float` closures work as `Double` ones; nothing is read on an edgeless graph | CD-160 – CD-162, CD-167, CD-168, CD-170 – CD-172, `WeightReadingTests.swift` |

## How values are pinned

Every catalog row is written as the catalog writes it (listed vertices first, then endpoints by
first appearance, `nx(…)` graphs with NetworkX's node list and edge order, `lcg(…)` pairs and their
first-appearance vertex order; edges in written order, repeats and loops kept) on the
`ReferencePseudograph` or `ReferenceDirectedMultigraph`, whose rows are in position order, so every
vertex number and edge position is exact. The catalog-row files and the representation file were
generated from `cases.md` by a script (`swiftgen.py`, next to `ref.py`) that re-evaluates each row
with `ref.py`'s model, asserts that it matches the catalog cell, and writes the model's value at full
precision; the catalog cells are the same values rounded to 12 digits. Scalars compare within 1e-12
relative to max(1, |value|), partitions exactly in canonical order. Each partition row also checks
`count`, `community(of:)` against membership, `community(ofIndex:)` against `community(of:)`, and
the modularity of the result at the call's weight and resolution against `ref.py`'s value; each
undirected row of modularity, partition quality, Louvain and greedy modularity runs again on
`graph.directed` (the values `ref.py` gives for `directed > op`, which are the same), and each
`using:` row runs twice with the same seed. The `CompressedSparseRow` and `AdjacencyMatrix` rows
rewrite the arcs in row-major order (undirected graphs without loops as symmetric digraphs) and were
computed by `ref.py` on the rewritten graph. The stress literals were computed with `ref.py`'s model
functions at their sizes and are written as the closed forms the output follows (or derived in
closed form, for the modularity and quality of a ring of cliques).

The whole suite was run against an independent brute-force Swift model of the API (index space,
dictionaries, written from `ref.py`) before the implementation existed, compiled with warnings as
errors. It was also run against 18 planted bugs in that model: Louvain ties to the least label,
Louvain leaving its community on a tie with staying, the threshold ignored, the undirected gain on
directed graphs, `using:` not drawing, an undirected loop once in the degree, NaN modularity at
m = 0, directed modularity normalized as undirected, parallel copies counted as pairs in
performance, greedy ties to the greatest pair, greedy stopping at ΔQ = 0, loops voting, parallel
copies voting once, semi-synchronous ties to the least label, communities not in canonical order,
`community(of:)` misnumbered on a conformer without indices, weights read twice, and a negative
resolution accepted. Each of these fails tests (from 2 to 100). The property tests write their oracles inside each test.

## Files

| File | Tests | Covers |
|---|---|---|
| `DegenerateGraphTests.swift` | 34 | §A: the empty graph (both kinds), one vertex, four isolated vertices, lone loops, K₂, one arc: every entry point |
| `ModularityTests.swift` | 34 | §B: P₃ with every split, empty communities and community order, K₄, two triangles at γ = 0, ½, 1, 2 and weighted (heavy, scaled, zero bridge), `connectedComponents()`, two K₅, barbell, ring of cliques, the karate club (observed split, weighted, `graph.directed`), parallel edges as weight, loops (weighted, `graph.directed`), Leicht–Newman on dipaths and two directed triangles, a directed loop, labeled vertices |
| `PartitionQualityTests.swift` | 14 | §C: two triangles (split, singletons, components), the karate club, parallel edges, a loop, directed ordered pairs |
| `LouvainTests.swift` | 33 | §D: cliques joined by edges, barbell, ring of cliques, caveman, the karate club (count, `community(of:)`, weighted, γ = 0, 0.5, 2, `threshold: 1`), Florentine families (`String` vertices), components, parallel edges, loops, a heavy bridge, path and cycle ties, a star, a grid, `lcg` graphs (also weighted), directed (two triangles, karate, `lcg`), `graph.directed`, `using:`; CD-174 |
| `GreedyModularityTests.swift` | 21 | §E: the same families as §D, the karate club with igraph's Q, ties to the least pair, parallel edges and loops, γ = 0, directed; CD-173; two merges with ΔQ = 0 exactly (one arc; a zero-weight bridge at γ = 0), which continue |
| `LabelPropagationTests.swift` | 22 | §F: semi-synchronous and asynchronous on cliques, ring of cliques (flooding in index order), the karate club (also weighted), paths, loops voting for nothing, parallel copies each voting, weights, `lcg`, `using:` |
| `CommunityDetectionPreconditionTests.swift` | 48 | Exit tests: the catalog's 18 trap rows (CD-155 – CD-172); then `community(of:)` on a non-vertex (both kinds), `community(ofIndex:)` at −1, at the count and on an empty result, `partitionQuality(of:)` with a vertex twice or a non-vertex (both kinds), directed modularity with a vertex missing, an infinite or negative resolution, a non-vertex on the empty graph, NaN and infinite resolutions and thresholds for Louvain and greedy modularity (both kinds, also through `using:`), negative, NaN and ±infinite weights through every weighted overload not covered by the catalog (also `Float`) |
| `CommunityDetectionRepresentationTests.swift` | 87 | Every §A – §G value row whose graph has no parallel edges on `UndirectedAdjacencyList` (28 graphs) or `AdjacencyList` (7), and the modularity, quality, Louvain and greedy rows of every graph on 0..<n without parallel edges on `CompressedSparseRow` (26) and `AdjacencyMatrix` (26), directed graphs with their arcs in row-major order and loop-free undirected graphs as symmetric digraphs; one test per graph, every row of that graph |
| `WeightReadingTests.swift` | 7 | The weight closure once per edge in position order through every weighted entry point on a pseudograph with a loop and parallel edges, on `graph.directed`, on a directed multigraph, on `UndirectedAdjacencyList`, `CompressedSparseRow` and `AdjacencyMatrix`; nothing read when there are no edges; -0.0 accepted; `Float` weights |
| `CommunityDetectionConformanceTests.swift` | 14 | `Sendable` across a `Task`, the result holding a copy of the graph, the result types, `RandomAccessCollection` (indices, slices keeping flat indices, reversal), `description`, `Equatable` across algorithms and graphs, generic code over `some Graph` / `some DirectedGraph`, any collection of vertex collections (sets, slices, lazy collections, `Components`, a `Partition`), conformers without indices (the `lcg` rows, vertices not in value order), `Collider` vertices, determinism across representations on the karate club, `using:` drawing from the generator and changing the order |
| `CommunityDetectionPropertyTests.swift` | 9 | PropertyBased, shrinking, multigraphs with loops, shuffled rows and vertex orders: modularity against the matrix definition (both kinds, γ, weights, community order, `graph.directed`, γ = 0 as coverage); quality against pair counts; every overload returns a canonical partition; Louvain and greedy at least the singletons' Q, greedy locally optimal under merges; label propagation's stop condition; representation independence; weight scaling; γ = 0 gives the components; `using:` repeats |
| `CommunityDetectionStressTests.swift` | 8 | Inside a `Task` with a one-minute limit: Louvain on 25,000 disjoint K₄ (also `using:`), a ring of 1000 K₅ and a 10⁵-vertex path; greedy modularity on a ring of 400 K₅; both propagations on a 10⁵-vertex path and 20,000 disjoint K₅; modularity and quality on a ring of 25,000 K₄; directed Louvain and greedy on disjoint 3-cycles on `CompressedSparseRow` |

174 catalog rows (156 value rows, 18 trap rows) and their 87 representation tests, 30 more
precondition tests, and 40 more tests (the two ΔQ = 0 merges, weight reading, conformance, properties,
stress): 331 tests in all.

## Case IDs

Case IDs (CD-001 … CD-174) refer to the catalog (`cases.md`), harvested from NetworkX 3.7's
community tests and docstrings, python-igraph 1.0, Newman 2006, Leicht–Newman 2008, Blondel et al.
2008, Clauset–Newman–Moore 2004, Raghavan–Albert–Kumara 2007, Cordasco–Gargano 2010 and the edge
cases api.md calls out. Each test's name starts with its IDs; tests without an ID check laws,
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
| CD-174 | G. Louvain at total weight 0 (not a trap) | `LouvainTests.swift`; again in `CommunityDetectionRepresentationTests.swift` |

Rows with parallel edges (CD-058, CD-076, CD-077, CD-098, CD-127, CD-140, CD-141, CD-149, CD-151)
and the `lcg` rows (whose random pairs repeat) are not repeated on the adjacency lists, which cannot
hold parallel edges; label propagation and `graph.directed` rows are not repeated on
`CompressedSparseRow` and `AdjacencyMatrix`, which are directed.

## Not tested

| Case | Why |
|---|---|
| The exact draw sequence of the `using:` overloads (Fisher–Yates from k − 1 down to 1 with `next(upperBound:)`, a tie drawn among the labels in order of first vote) | api.md documents it, but open question 1 (a Grafluent-owned bounded draw) is undecided, and pinning a seeded partition would pin the standard library's `next(upperBound:)` too. The suite checks properties instead: valid canonical partitions, Q at least the singletons', the stop condition, repetition with the same seed, at least n − 1 draws, and that shuffled orders change the result |
| Louvain's levels, greedy modularity's merge history, `cutoff`, `best_n`, Leiden, Girvan–Newman, directed label propagation | Out of phase 1 (api.md, "Out") |
| Partitions from non-integer weights compared across representations | api.md: k_u,D is summed in row order, so different row orders may break a near-tie differently; the determinism tests use integer weights, and the karate weighted rows use integers |
| Whether a zero-weight edge is a vote in label propagation | api.md does not say; NetworkX counts it (a label with 0 votes can be among the most voted), and api.md's termination argument (each change strictly increases the weight inside labels) does not hold with zero weights. The suite uses zero weights only where both readings agree: the stop condition in the property tests compares vote weights, and the -0.0 bridge in `WeightReadingTests.swift` |
| `Partition`'s `subscript` out of range | api.md does not state it; `Components` traps, and a `RandomAccessCollection` may |
| Complexity (O(n + m) per sweep, no allocation per sweep) | Benchmarks; the stress tests bound costs loosely (each shape within the time limit in a debug build) |
| NetworkX and igraph on random graphs (`just diff`) | Not Swift tests; `ref.py` checks every catalog row against NetworkX 3.7 where it shares the semantics, and the property tests use definition oracles |
