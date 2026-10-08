# AdjacencyMatrix test suite

`AdjacencyMatrix` is a directed graph on the vertices `0..<vertexCount`, stored as a square
matrix of bits: row `source`, column `target` is set when there is an edge from `source` to
`target`. Self-loops are the diagonal; parallel edges cannot be represented. The suite was written
before the implementation, checked against a throwaway naive implementation, and uses only the
public API. Every test is self-contained; shared material is limited to the fixtures and test
types in `GrafluentTestSupport`.

## API under test

```swift
struct AdjacencyMatrix: Hashable, Sendable, Codable, ExpressibleByArrayLiteral,
                        CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable

    init()
    init(vertexCount: Int)
    init(vertexCount: Int, repeating: Bool)           // true: every cell set
    init(vertexCount: Int, edges: some Sequence<DirectedEdge<Int>>)
    // let m: AdjacencyMatrix = [[0, 1], [0, 0]]       rows of 0s and 1s, row = source

    var vertexCount: Int
    var edgeCount: Int
    var rowsDescription: String                       // the n×n grid of 0s and 1s
    var vertices: Range<Int>                          // 0..<vertexCount
    var edges: Edges                                  // BidirectionalCollection, row-major;
                                                      // a position is a cell (source, target)
    subscript(source: Int, target: Int) -> Bool { get set }
    func contains(_: Int) -> Bool
    func contains(edge: DirectedEdge<Int>) -> Bool
    func successors(of: Int) -> BitSet                // swift-collections; ascending
    func predecessors(of: Int) -> BitSet
    func outDegree(of: Int) -> Int                    // O(1)
    func inDegree(of: Int) -> Int                     // O(1)
    func degree(of: Int) -> Int

    mutating func insert(edge: DirectedEdge<Int>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Int>)
    mutating func remove(edge: DirectedEdge<Int>) -> DirectedEdge<Int>?
    mutating func insertEdges(from: Int, to: BitSet) -> Int   // row ∪= targets
    mutating func removeEdges(from: Int) -> Int               // clear a row
    mutating func removeEdges(to: Int) -> Int                 // clear a column
    mutating func removeEdges(incidentTo: Int) -> Int         // Boost's clear_vertex
    mutating func appendVertex() -> Int
    mutating func removeAllEdges(keepingCapacity: Bool = false)
    mutating func removeAll(keepingCapacity: Bool = false)
    mutating func reserveCapacity(vertexCount: Int)

    // Whole-matrix operations (same vertex count required)
    func union(_:) / formUnion(_:)
    func intersection(_:) / formIntersection(_:)
    func subtracting(_:) / subtract(_:)
    func symmetricDifference(_:) / formSymmetricDifference(_:)
    func complement(includingSelfLoops: Bool = false) -> AdjacencyMatrix
    func transposed() -> AdjacencyMatrix

    static let maximumDecodedVertexCountKey: CodingUserInfoKey
    static let defaultMaximumDecodedVertexCount: Int  // 16,384
```

## Conventions

Where the reference libraries disagree, these are the choices and the reasons.

| Question | Choice | Why | Disagreement |
|---|---|---|---|
| Vertex identity | Positions `0..<vertexCount` | A matrix is indexed by position | — |
| Adding vertices | `appendVertex()`, amortized by doubling | Growth without renumbering | Boost and gonum fix the size; LEMON's `resize` discards edges |
| Removing vertices | Not offered | Removal either renumbers later vertices or leaves holes; petgraph's holes cause a stale `edge_count` and a wrong `is_adjacent` (both confirmed by running petgraph) | petgraph offers it |
| Edge to an out-of-range vertex | `insert(edge:)` and the subscript trap; the matrix never grows to fit | petgraph silently grows despite documenting a panic; Boost has undefined behavior | — |
| `contains` / `remove` out of range | `false` / `nil`, never a trap | Asking about something absent is not an error (same as `AdjacencyList`) | gonum is inconsistent between its own methods |
| Duplicate edges in the input | Collapse | A cell is a bit | petgraph panics |
| Self-loop | One edge; 1 to out-degree, 1 to in-degree, 2 to degree; diagonal cell is 1 | Same as `AdjacencyList` | gonum forbids self-loops; JGraphT exports a 2 on the diagonal |
| Order of successors, predecessors, edges | Ascending; edges row-major | Free with a matrix, and makes output deterministic | — |
| Literal entries | Square, each 0 or 1, else trap | Anything else is ambiguous | NetworkX reads entries as weights |
| `==` | Equal vertex count and equal cells; capacity ignored | swift-algorithm-club's `BitSet` compares words only, so differently sized empty sets compare equal | — |
| `description` | `[0, 1, 2]; [0→1, 1→2]`, at most 16 vertices and 16 edges, then `…`; the grid is `rowsDescription` | One textual form for every representation, so equal graphs print alike and large graphs print small | Bitset libraries disagree on bit order |
| Encoded form | `{"vertexCount": n, "edges": [s₀, t₀, s₁, t₁, …]}`, row-major; malformed input throws | Specified, so corrupt payloads can be tested | — |
| Decoding limit | At most 16,384 vertices (32 MiB of cells) unless the decoder's `userInfo[maximumDecodedVertexCountKey]` says otherwise | A 36-byte payload can name a matrix of gigabytes | — |
| Rows and columns | `BitSet` values, not views into the matrix | O(1) membership, word-at-a-time iteration and set algebra, and mutating the matrix while holding one costs nothing | — |
| Edge positions | A cell (`source`, `target`); still names the same cell after `appendVertex()` | Stable; weights for a matrix are keyed by cell, not by a dense edge index | LEMON's id is `n × source + target`, which shifts when n changes |
| Complement | Excludes self-loops unless `includingSelfLoops: true` | Matches NetworkX | — |

## Files

| File | Covers |
|---|---|
| `AdjacencyMatrixConstructionTests.swift` | Empty, isolated, complete, from edges, literals, order independence, single-pass input |
| `AdjacencyMatrixMutationTests.swift` | The cell subscript, insert and remove, self-loops, clearing; vertex growth and capacity |
| `AdjacencyMatrixQueryTests.swift` | Ascending successors and predecessors, degrees, agreement with `AdjacencyList`, row-major edges, out-of-range membership |
| `AdjacencyMatrixWordBoundaryTests.swift` | Rows straddling 64-bit words (n = 1 … 129), phantom cells, large sparse and dense matrices |
| `AdjacencyMatrixConformanceTests.swift` | Equality and hashing laws, every 3-vertex matrix, `description`, exact and malformed encodings |
| `AdjacencyMatrixPreconditionTests.swift` | Exit tests for every trapping precondition |
| `AdjacencyMatrixValueTests.swift` | Value semantics, views as values, Collection laws, `Sendable`, a model-based randomized test starting at 0 to 120 vertices |
| `AdjacencyMatrixOperationTests.swift` | Transpose, set algebra, complement, row and column clearing, `insertEdges(from:to:)`, a transitive closure written with row unions, stable edge positions, slices, Collection laws on wide matrices, the decoding limit, large descriptions |

Case IDs (AM-C04, AM-W02, …) refer to the catalog of cases harvested from petgraph, Boost.Graph,
gonum, NetworkX, LEMON, JGraphT, igraph (behavior reference only; GPL) and swift-algorithm-club.

Amortized growth, iteration speed and allocation behavior are performance properties: a slower
implementation passes every test. They belong in the benchmarks.

Boolean matrix products, powers and transitive closure (catalog AM-P01–P06) are algorithms and
will be tested with the algorithm modules; the closure test here only shows that row unions make
one easy to write.
