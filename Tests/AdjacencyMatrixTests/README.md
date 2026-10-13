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
    // checked: spellings throw VertexNotFound / EdgeNotFound instead of trapping (Principle 6)
    func successors(checked:) / predecessors(checked:) / outEdges(checked:) / inEdges(checked:)
    func outDegree(checked:) / inDegree(checked:) / degree(checked:) / vertexIndex(checked:)
    func source(checkedEdgeAt: Edges.Index) / target(checkedEdgeAt: Edges.Index)  // EdgeNotFound

    mutating func insert(edge: DirectedEdge<Int>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Int>)
    mutating func insert(checked: DirectedEdge<Int>) throws(VertexNotFound) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Int>)
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

    // PropertyGraph: attached maps; a removed edge's cell goes back to the default
    mutating func addEdgeMap(default:) -> EdgeMap<V> / addEdgeMap(of:) -> EdgeMap<V?>
    mutating func addVertexMap(default:) -> VertexMap<V> / addVertexMap(of:) -> VertexMap<V?>
    mutating func removeEdgeMap(_:) / removeVertexMap(_:)
    subscript(map, ofEdgeAt: Edges.Index) / (map, ofVertexAt: Int) / (map, of: Int)   // trap off an edge or vertex
    subscript(map, checkedEdgeAt:) / (map, checkedVertexAt:) / (map, checked:)      // EdgeNotFound / VertexNotFound
    func values(of:) -> EdgeValues<AdjacencyMatrix, V> / VertexValues<AdjacencyMatrix, V>
    var generation: GraphGeneration
```

## Conventions

Where the reference libraries disagree, these are the choices and the reasons.

| Question | Choice | Why | Disagreement |
|---|---|---|---|
| Vertex identity | Positions `0..<vertexCount` | A matrix is indexed by position | — |
| Adding vertices | `appendVertex()`, amortized by doubling | Growth without renumbering | Boost and gonum fix the size; LEMON's `resize` discards edges |
| Removing vertices | Not offered | Removal either renumbers later vertices or leaves holes; petgraph's holes cause a stale `edge_count` and a wrong `is_adjacent` (both confirmed by running petgraph) | petgraph offers it |
| Edge to an out-of-range vertex | `insert(edge:)` and the subscript trap; the matrix never grows to fit; `insert(checked:)` throws `VertexNotFound` and changes nothing | petgraph silently grows despite documenting a panic; Boost has undefined behavior | — |
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
| Edge map layout | One value per cell at Szudzik's pairing, `s < t ? t·t + s : s·s + s + t` | The cells of `0..<n` are exactly `0..<n²`, so `appendVertex()` appends 2n + 1 values and moves none | LEMON's `n × source + target` shifts when n changes |
| Removed edge's value | Every removal (one edge, a row, a column, a whole-matrix operation, `removeAllEdges`) sets the cell back to the default; reading or writing it traps, the checked read throws `EdgeNotFound` | A cell with no edge always holds the default, so an insertion writes nothing | — |
| Derived matrices | `union` and the other set operations carry this matrix's maps; `complement()`, `transposed()` and decoding carry none | The set operations are mutations of a copy; the others are new graphs | — |

## Files

| File | Covers |
|---|---|
| `AdjacencyMatrixConstructionTests.swift` | Empty, isolated, complete, from edges, literals, order independence, single-pass input |
| `AdjacencyMatrixMutationTests.swift` | The cell subscript, insert and remove, self-loops, clearing; vertex growth and capacity |
| `AdjacencyMatrixQueryTests.swift` | Ascending successors and predecessors, degrees, agreement with `AdjacencyList`, row-major edges, out-of-range membership |
| `AdjacencyMatrixWordBoundaryTests.swift` | Rows straddling 64-bit words (n = 1 … 129), phantom cells, large sparse and dense matrices |
| `AdjacencyMatrixConformanceTests.swift` | Equality and hashing laws, every 3-vertex matrix, `description`, exact and malformed encodings |
| `AdjacencyMatrixPreconditionTests.swift` | Exit tests for every trapping precondition |
| `AdjacencyMatrixCheckedTests.swift` | The `checked:` spellings (AM-R08): each equals its trapping spelling in range and throws `VertexNotFound` or `EdgeNotFound` outside it; `insert(checked:)` changes nothing when it throws |
| `AdjacencyMatrixValueTests.swift` | Value semantics, views as values, Collection laws, `Sendable`, a model-based randomized test starting at 0 to 120 vertices |
| `AdjacencyMatrixMapTests.swift` | Attached maps: defaults, values kept across `appendVertex()` past 64 vertices, every removal path resetting its cells (rows past one word too), vertex maps, `removeAll`, copies (one that attaches, removes or writes a map leaves the original's later removals to the original), derived matrices, equality and coding |
| `AdjacencyMatrixMapPreconditionTests.swift` | Exit tests: a removed edge's value, a vertex out of range, a handle on another or a derived matrix or after removal |
| `AdjacencyMatrixMapPropertyTests.swift` | Random mutations with two edge maps and a vertex map against dictionaries (swift-property-based); a cell with no edge must read the default |
| `AdjacencyMatrixGenerationTests.swift` | Every structural mutation starts a generation, a call that changes nothing and map writes do not; copies and derived matrices; two copies under every interleaving of three steps never share a generation in different states; `removeAll` of an empty matrix starts one in each copy |
| `AdjacencyMatrixOperationTests.swift` | Transpose, set algebra, complement, row and column clearing, `insertEdges(from:to:)`, a transitive closure written with row unions, stable edge positions, slices, Collection laws on wide matrices, the decoding limit, large descriptions |

Case IDs (AM-C04, AM-W02, …) refer to the catalog of cases (`Tests/Catalogs/AdjacencyMatrix/cases.md`) harvested from petgraph, Boost.Graph,
gonum, NetworkX, LEMON, JGraphT, igraph (behavior reference only; GPL) and swift-algorithm-club.

Amortized growth, iteration speed and allocation behavior are performance properties: a slower
implementation passes every test. They belong in the benchmarks.

Boolean matrix products, powers and transitive closure (catalog AM-P01–P06) are algorithms and
will be tested with the algorithm modules; the closure test here only shows that row unions make
one easy to write.
