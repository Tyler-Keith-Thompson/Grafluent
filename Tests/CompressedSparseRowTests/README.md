# CompressedSparseRow test suite

`CompressedSparseRow` is an immutable directed graph on the vertices `0..<vertexCount`, stored as
`offsets` (`vertexCount + 1` entries) and `targets` (`edgeCount` entries): the successors of `v`
are `targets[offsets[v] ..< offsets[v + 1]]`. Rows are canonical (strictly ascending), self-loops
are kept, and parallel edges cannot be represented. The suite uses only the public API. Every
test is self-contained; shared material is limited to the fixtures and test types in
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
    // checked: spellings throw instead of trapping
    func successors(checked:) / outEdges(checked:) / outDegree(checked:) / vertexIndex(checked:)  // VertexNotFound
    func source(checkedEdgeAt: Int) / target(checkedEdgeAt: Int)                                // EdgeNotFound
    func transposed() -> CompressedSparseRow                     // the reverse graph, canonical
    func transposed(forwardEdgeIndices: inout [Int]) -> CompressedSparseRow
                                                // forward[k] = index here of the transpose's edge k

    // PropertyGraph: dense maps, allocated in full when attached; positions are vertices and edge indices
    mutating func addEdgeMap<V>(default: V) -> EdgeMap<V>      // addEdgeMap(of: T.self) -> EdgeMap<T?>
    mutating func addVertexMap<V>(default: V) -> VertexMap<V>
    mutating func removeEdgeMap(_:) / removeVertexMap(_:)
    subscript(map, ofEdgeAt: Int) / (map, ofVertexAt: Int) / (map, of: Int) -> V { get set }  // trap out of range
    subscript(map, checkedEdgeAt:) / (map, checkedVertexAt:) / (map, checked:) -> V           // throw
    func values(of: EdgeMap<V>) -> EdgeValues<Self, V>         // snapshot, one array load per read
    func values(of: VertexMap<V>) -> VertexValues<Self, V>

    var generation: GraphGeneration             // stamped by every initializer but init(); never advances
    var sourceGeneration: GraphGeneration       // the source's, from init(_:); else .untracked
    func isCurrent(for: some DirectedGraph) -> Bool

    enum ValidationError: Error, Hashable
        case emptyOffsets, firstOffsetNotZero, decreasingOffsets(vertex:)
        case lastOffsetMismatch(lastOffset:targetCount:), targetOutOfRange(edgeIndex:)
        case unsortedRow(vertex:), duplicateEdge(vertex:)
```

## Conventions

| Question | Choice | Why |
|---|---|---|
| Rows | Sorted and deduplicated, self-loops kept | Binary-search lookup, exact equality on arrays, and edge indices that do not depend on input order |
| Mutation | None; build once | Inserting one edge moves O(m) others |
| Vertex count | Always explicit | Trailing isolated vertices survive |
| Edge indices | Position in `targets`, `0..<edgeCount`, row-major | Dense and independent of input order, so an array indexed by edge index stays aligned |
| Reverse direction | Not stored; `transposed()` builds it in O(n + m) | Halves memory for the many algorithms that only go forward |
| Index width | `Int` | Simple and never truncates |
| Out-of-range | Initializer, `successors`, `outDegree`, edge-index accessors trap; their `checked:` spellings throw `VertexNotFound` / `EdgeNotFound`; `contains` and `edgeIndex(of:)` return `false`/`nil` | Same as the other representations |
| Raw arrays | `offsets` and `targets` readable; a validating `init(offsets:targets:)` with typed errors | Interop without trusting input |
| Edge values | Given with the edges: not stored. The initializer and `transposed` report each edge's new index; repeated edges share one, and the caller picks first-wins, last-wins, sum or anything else. Attached afterwards: dense maps (`addEdgeMap(default:)`), by edge index, carried by copies and dropped by `transposed` and every other new graph | One mechanism serves every duplicate policy; maps keep the values with the graph |
| Generation | Stamped once by every initializer but `init()` (which allocates nothing); `init(_:)` also keeps the source's as `sourceGeneration` | The graph never changes, so its generation only tells it from other graphs; the source's tells whether the source has changed since |
| Construction | Two counting sorts (by target, then by source), O(n + m) for any degree distribution; a single pass when the input is already canonical; exactly sized storage afterwards | Real graphs are skewed; a per-row comparison sort is O(d log d) on a hub |
| Encoded form | `{"offsets": [...], "targets": [...]}`, fully validated | The payload is as large as the graph, so it cannot amplify an allocation |
| `description` | `[0, 1, 2]; [0→1, 1→2]`, at most 16 of each | Same as every representation |
| Mirror | `offsets` and `targets` | They are the storage |

## Files

| File | Covers |
|---|---|
| `CompressedSparseRowConstructionTests.swift` | Empty and isolated graphs, unsorted and duplicated input, self-loops, exact arrays for 19 published fixtures, the invariants for every fixture, agreement with `AdjacencyList` and `AdjacencyMatrix`, single-pass and lazy input, parallel arrays, storage sized to the edges after repeats, validating `init(offsets:targets:)` |
| `CompressedSparseRowQueryTests.swift` | Successor slices, empty rows, row-major `edges`, every slice of `edges` and the slicing algorithms, binary-search `firstIndex`/`lastIndex`, exhaustive and boundary lookups, edge indices, property arrays aligned by edge index, exact transposes, `inDegrees`, raw buffers |
| `CompressedSparseRowEdgeValueTests.swift` | Values carried through construction (every duplicate policy) and through the transpose (the forward edge index) |
| `CompressedSparseRowRealWorldTests.swift` | The `4.el`, Graph500 scale-8 and rMat fixture graphs vendored in `GrafluentTestSupport`, and a shuffled hub of out-degree 20,000 |
| `CompressedSparseRowConformanceTests.swift` | Equality and hashing laws, every 3-vertex graph, descriptions, exact and corrupt encodings with the coding path and `ValidationError` of each, exit tests for every precondition |
| `CompressedSparseRowCheckedTests.swift` | The `checked:` spellings (CSR-P08, CSR-P09): equal to the trapping spellings in range, throwing `VertexNotFound` or `EdgeNotFound` outside it |
| `CompressedSparseRowMapTests.swift` | Attached maps: defaults, writes by edge index and vertex, the `checked` subscripts, `values(of:)` snapshots, copy-on-write, removal, equality and coding ignoring maps, traps (exit tests) for out-of-range positions and foreign or removed handles, a model against dictionaries keyed by edge and vertex (swift-property-based); generations of every initializer, and `sourceGeneration`/`isCurrent(for:)` against a graph that stamps on each insertion |
| `CompressedSparseRowModelTests.swift` | Random edge lists against a model at 0 to 200 vertices, Erdős–Rényi graphs, a complete digraph, a hub of out-degree 10,000, value semantics, `Sendable` |

Case IDs (CSR-C06, CSR-E05, …) refer to the case catalog in
`Tests/Catalogs/CompressedSparseRow/cases.md`.
