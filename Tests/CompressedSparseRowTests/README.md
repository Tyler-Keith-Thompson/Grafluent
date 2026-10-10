# CompressedSparseRow test suite

`CompressedSparseRow` is an immutable directed graph on the vertices `0..<vertexCount`, stored as
`offsets` (`vertexCount + 1` entries) and `targets` (`edgeCount` entries): the successors of `v`
are `targets[offsets[v] ..< offsets[v + 1]]`. Rows are canonical (strictly ascending), self-loops
are kept, and parallel edges cannot be represented. The suite was written before the
implementation, checked against a throwaway naive implementation, and uses only the public API.
Every test is self-contained; shared material is limited to the fixtures and test types in
`GrafluentTestSupport`.

## API under test

```swift
struct CompressedSparseRow: Hashable, Sendable, Codable,
                            CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable

    init()
    init(vertexCount: Int)
    init(vertexCount: Int, edges: some Sequence<DirectedEdge<Int>>)   // any order; repeats collapse
    init(vertexCount: Int, edges: some Collection<DirectedEdge<Int>>) // read twice in place, no copy
    init(vertexCount: Int, edges: some Collection<DirectedEdge<Int>>, edgeIndices: inout [Int])
                                                // edgeIndices[i] = index of input edge i
    init(vertexCount: Int, sources: [Int], targets: [Int])            // parallel arrays (COO)
    init(offsets: [Int], targets: [Int]) throws(ValidationError)      // must already be canonical

    var vertexCount: Int
    var edgeCount: Int
    var vertices: Range<Int>
    var offsets: [Int]
    var targets: [Int]
    var edges: Edges                       // RandomAccessCollection; position = edge index;
                                           // its own SubSequence, O(1) per element when iterated
    var inDegrees: [Int]                   // one O(n + m) pass
    func withUnsafeBufferPointers<R, E>(_: (UnsafeBufferPointer<Int>, UnsafeBufferPointer<Int>) throws(E) -> R) throws(E) -> R
    func contains(_: Int) -> Bool
    func contains(edge: DirectedEdge<Int>) -> Bool               // binary search
    func successors(of: Int) -> ArraySlice<Int>                  // indices are edge indices
    func outDegree(of: Int) -> Int                               // O(1)
    func edgeIndex(of: DirectedEdge<Int>) -> Int?
    func source(ofEdgeAt: Int) -> Int                            // binary search of offsets
    func target(ofEdgeAt: Int) -> Int
    func transposed() -> CompressedSparseRow                     // the reverse graph, canonical
    func transposed(forwardEdgeIndices: inout [Int]) -> CompressedSparseRow
                                                // forward[k] = index here of the transpose's edge k

    enum ValidationError: Error, Hashable
        case emptyOffsets, firstOffsetNotZero, decreasingOffsets(vertex:)
        case lastOffsetMismatch(lastOffset:targetCount:), targetOutOfRange(edgeIndex:)
        case unsortedRow(vertex:), duplicateEdge(vertex:)
```

## Conventions

| Question | Choice | Why | Disagreement |
|---|---|---|---|
| Rows | Sorted and deduplicated, self-loops kept | Binary-search lookup, exact equality on arrays, and edge indices that do not depend on input order | Boost, JGraphT, scipy and neo4j's default keep input order; neo4j's "Deduplicated" layout and GAP also delete self-loops |
| Mutation | None; build once | Inserting one edge moves O(m) others; petgraph's `add_edge` also shifts edge ids | Boost and petgraph offer it |
| Vertex count | Always explicit | Trailing isolated vertices survive | petgraph and GAP infer `max + 1`; neo4j turns an empty edge list into one vertex |
| Edge indices | Position in `targets`, `0..<edgeCount`, row-major | Dense and independent of input order, so an array indexed by edge index stays aligned (the README's plan for weights) | JGraphT and igraph number edges by input order |
| Reverse direction | Not stored; `transposed()` builds it in O(n + m) | Halves memory for the many algorithms that only go forward | neo4j, GAP, igraph and Ligra always store both |
| Index width | `Int` | Simple and never truncates | petgraph narrows targets to `u32` and silently truncates (`u8` accepts 300 nodes) |
| Out-of-range | Initializer, `successors`, `outDegree`, edge-index accessors trap; `contains` and `edgeIndex(of:)` return `false`/`nil` | Same as the other representations | petgraph answers `out_degree(n)` with 0 |
| Raw arrays | `offsets` and `targets` readable; a validating `init(offsets:targets:)` with typed errors | Interop without trusting input | Boost's "sorted" constructor trusts its input and crashed on two unsorted edges |
| Edge values | Not stored. The initializer and `transposed` report each edge's new index; repeated edges share one, and the caller picks first-wins, last-wins, sum or anything else | One mechanism serves every policy, and weights stay external as the README plans | scipy sums, GraphBLAS errors or keeps the last, neo4j keeps an arbitrary one |
| Construction | Two counting sorts (by target, then by source), O(n + m) for any degree distribution; a single pass when the input is already canonical; exactly sized storage afterwards | Real graphs are skewed; a per-row comparison sort is O(d log d) on a hub | Boost and igraph also sort by counting; scipy, neo4j and GAP sort each row |
| Encoded form | `{"offsets": [...], "targets": [...]}`, fully validated | The payload is as large as the graph, so it cannot amplify an allocation; no "trusted" flag | No studied library validates deserialized arrays by default |
| `description` | `[0, 1, 2]; [0→1, 1→2]`, at most 16 of each | Same as every representation | — |
| Mirror | `offsets` and `targets` | They are the storage | — |

## Files

| File | Covers |
|---|---|
| `CompressedSparseRowConstructionTests.swift` | Empty and isolated graphs, unsorted and duplicated input, self-loops, exact arrays for 19 published fixtures, the invariants for every fixture, agreement with `AdjacencyList` and `AdjacencyMatrix`, single-pass and lazy input, parallel arrays, storage sized to the edges after repeats, validating `init(offsets:targets:)` |
| `CompressedSparseRowQueryTests.swift` | Successor slices, empty rows, row-major `edges`, every slice of `edges` and the slicing algorithms, binary-search `firstIndex`/`lastIndex`, exhaustive and boundary lookups, edge indices, property arrays aligned by edge index, exact transposes, `inDegrees`, raw buffers |
| `CompressedSparseRowEdgeValueTests.swift` | Values carried through construction (scipy constructor4, petgraph's weights, every duplicate policy) and through the transpose (Boost's forward edge index) |
| `CompressedSparseRowRealWorldTests.swift` | GAP `4.el`, Graph500 scale 8 and Ligra's rMat graph (vendored in `GrafluentTestSupport`), and a shuffled hub of out-degree 20,000 |
| `CompressedSparseRowConformanceTests.swift` | Equality and hashing laws, every 3-vertex graph, descriptions, exact and corrupt encodings with the coding path and `ValidationError` of each, exit tests for every precondition |
| `CompressedSparseRowModelTests.swift` | Random edge lists against a model at 0 to 200 vertices, Erdős–Rényi graphs, a complete digraph, a hub of out-degree 10,000, value semantics, `Sendable` |

Case IDs (CSR-C06, CSR-E05, …) refer to the catalog of cases (`Tests/Catalogs/CompressedSparseRow/cases.md`) harvested from petgraph, Boost.Graph,
scipy, neo4j's graph crate, GAP, NetworkX, JGraphT, GraphBLAS, Ligra and igraph (behavior reference
only; GPL).
