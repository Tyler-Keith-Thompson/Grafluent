# ImplicitGraphs: API

An implicit graph is given by a successor function instead of stored edges. Grafluent handles two
cases.

| Case | Where it lives |
|---|---|
| **Infinite or unbounded state spaces** (puzzles, unbounded grids), with no vertex collection | Free functions over a successor closure, in the module of the algorithm. Traversal has `breadthFirstSearch(from:depthLimit:successors:)`, `depthFirstSearch(from:depthLimit:successors:)`, `topologicalSort(from:successors:)` and `iterativeDeepeningDepthFirstSearch(from:successors:until:)` (`Sources/Traversal/SuccessorFunctionSearch.swift`). ShortestPaths has `dijkstraShortestPath(from:cutoff:successors:success:)` and `aStarShortestPath(from:cutoff:successors:heuristic:success:)` with `successors: (V) -> some Sequence<(V, W)>` and an inclusive `cutoff:` (`Sources/ShortestPaths/SuccessorFunctionSearch.swift`, D19 in `Tests/Catalogs/ShortestPaths/cases.md`). IG-024 – IG-044 give the ShortestPaths functions values |
| **Finite but unstored** (a bounded grid, a bounded state space numbered `0..<n`), on which every `DirectedGraph` algorithm runs with no edge storage | `ImplicitDirectedGraph`, in this module |

`cases.md` pins the values. `ref.py` ports the type, counts every closure call, and checks each
graph against:

- the `DirectedGraph` laws: `successors`, `outEdges`, `edges`, the counts, `contains(edge:)`, and
  `edges` stepped by `index(after:)`, which must equal `edges` iterated;
- NetworkX 3.7 on the materialized graph: `bfs_layers` from every vertex and shortest path
  lengths.

`--stress` adds 600 random closures with parallel edges and self-loops. It also runs 200 weighted
Dijkstra and A* searches over an unbounded grid, checked against NetworkX on a 51 × 51 box.

To run it:
`uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/ImplicitGraphs/ref.py [--write] [--stress]`.

## Why a type and not a protocol

`DirectedGraph` requires `vertices` and `edges`. The algorithms that make sense on an unbounded
space (BFS, DFS, IDDFS, topological order, Dijkstra, A*) have closure entry points, so they need no
second protocol. The algorithms that need the whole vertex set (components, SCC, centrality,
coloring, all-pairs distances, `Distances`, `Covering`) need a lawful `DirectedGraph`, and
`ImplicitDirectedGraph` is one. Traversal's internal `_SuccessorFunctionGraph`, with empty
`vertices` and `edges`, does not satisfy the laws and stays internal.

## Names

| Name | Spelling |
|---|---|
| Type | `ImplicitDirectedGraph<Row>` in the module `ImplicitGraphs`. `Row` is the closure's result type |
| Initializer | `init(vertexCount:successors:)` |
| Edge position | `ImplicitDirectedGraph.Edges.Index`, with `source`, `rank` and `target`. The rank is the position within the source's row, so parallel edges stay distinct |

## Storage

```swift
@frozen
public struct ImplicitDirectedGraph<Row: Sequence<Int>> {
    @usableFromInline internal let _vertexCount: Int
    @usableFromInline internal let _successors: (Int) -> Row      // called on demand; results never stored
}
```

Vertices are `Int`s `0..<n`, as in `CompressedSparseRow`. A grid is numbered row-major. For
hashable states over a finite set, use `LabeledGraph<State, ImplicitDirectedGraph<…>>`. Its
`init(_:labels:)` needs only base vertices `0..<n` in index order, which this type has. The
generic parameter is the closure's result (an `Array`, a lazy filter over a fixed neighbor list,
…), so a specialized build inlines the closure's sequence with no type erasure. On a hot path the
row should be a small struct that computes its elements up front into fixed slots and yields them
by count. A lazy filter calls its predicate per element and carries the unfiltered iterator.

## API

n = vertices, d = the row's length (the closure's result), m = edges. "Call" means one call of the
closure, plus one pass over its sequence.

```swift
extension ImplicitDirectedGraph {
    public init(vertexCount: Int, successors: @escaping (Int) -> Row)   // O(1); calls nothing (IG-002)
}

extension ImplicitDirectedGraph: DirectedGraph {
    public typealias Vertex = Int
    public typealias Vertices = Range<Int>
    public struct Successors: Sequence<Int>                              // the row; range-checks each element as it is read
    public typealias SuccessorIndices = Successors                       // overrides the hashing default
    public struct OutEdges: Sequence<Edges.Index>                        // the row with ranks
    // Structs, not lazy maps: a lazy map's closure captures the vertex, and an algorithm that keeps
    // an iterator per vertex (Tarjan's) would allocate its context once per vertex.
    public struct Edges: Collection {                                    // Element = DirectedEdge<Int>
        public struct Index: Comparable, Hashable, Sendable {            // ==, <, hash on (source, rank) only
            public let source: Int, rank: Int, target: Int
        }
        // makeIterator(), Array(edges): O(n + m), one call per vertex (IG-007); underestimatedCount 0
        // startIndex: O(rows until the first non-empty one), so isEmpty and first call the closure up to n times (IG-045)
        // index(after:): O(d), re-reads the row (IG-008)
        // subscript: O(1) from the index
    }

    public var vertices: Range<Int>                                      // O(1)
    public var edges: Edges                                              // O(1) to form
    public func successors(of: Int) -> Successors                        // one call (IG-004)
    public func outEdges(of: Int) -> OutEdges                            // one call; positions carry the target (IG-005)
    public func outDegree(of: Int) -> Int                                // one call, O(d)
    public func source(ofEdgeAt: Edges.Index) -> Int                     // O(1), no call (IG-006)
    public func target(ofEdgeAt: Edges.Index) -> Int                     // O(1), no call
    public var vertexCount: Int                                          // O(1)
    public var edgeCount: Int                                            // O(n + m): one call per vertex (IG-007)
    public func contains(_: Int) -> Bool                                 // O(1), no call (IG-010)
    public func contains(edge: DirectedEdge<Int>) -> Bool                // one call, O(d); false off the vertex range with no call
    public var vertexIndexBound: Int?                                    // n
    public var edgeIndexBound: Int?                                      // nil: no dense edge numbering without a pass
    public func vertexIndex(of:) / vertex(atIndex:)                      // identity, range-checked (IG-011)
    public func successorIndices(ofIndex:) / outEdges(ofIndex:)          // one call each
    public func successors(checked:) / outEdges(checked:) / outDegree(checked:) / vertexIndex(checked:)
                                                                         // throw VertexNotFound off 0..<n, no call (IG-046)
}
```

- **Positions.** `(source, rank)` is unique even with parallel edges and self-loops (IG-009). The
  target travels in the position, so `weight: { $0.target / 4 + 1 }` costs nothing extra (IG-018).
  Equality and hashing ignore the target, which `(source, rank)` determines.
- **Determinism.** The closure must return the same sequence each time it is called with the same
  vertex. This is not checked. A closure that breaks it breaks every algorithm.
- **Traps:**
  - a negative `vertexCount` (IG-003);
  - a vertex outside `0..<n` (IG-012, IG-013);
  - a successor outside `0..<n`, trapped when that element is read (IG-014, IG-015). The check is
    one compare per edge in `Successors.Iterator.next()`.
- **Not conformed:**
  - `BidirectionalDirectedGraph`, since predecessors would need an inverse closure;
  - `Equatable`, `Hashable` and `Codable`, since closures have no identity;
  - `Sendable`, since the closure is not `@Sendable`.

**Generic algorithms** run unchanged. `vertexIndexBound` is non-nil, so `_DenseVertices` and
`_VertexIdentifiers` take their indexed paths and never hash. Traversal reads
`successorIndices(ofIndex:)`, one call per expanded vertex (IG-016). ShortestPaths'
`_runInIndexSpace` zips `successorIndices(ofIndex:)` with `outEdges(ofIndex:)`, which is two calls
per settled vertex.

### No attached maps; a generation

`ImplicitDirectedGraph` is not a `PropertyGraph`. An edge map needs a dense offset for each
position, and `(source, rank)` has one only after counting every earlier row, which calls the
closure once per vertex. An array of `vertexCount` values indexed by vertex serves for vertex
values, since nothing invalidates it. The initializer stamps a generation, which nothing advances.
Copies share it, and a graph built again from the same closure has its own.

Memory is O(1) for the graph. Algorithms keep only their own O(n) per-vertex state.

## The closure searches in ShortestPaths

IG-024 – IG-038 pin distances, and vertex counts where every shortest path has the same count.
IG-030 and IG-031 make step costs depend on both ends, so a search that tests the goal when it is
pushed gives a longer answer. They are checked against NetworkX on a bounded box.

- IG-032 – IG-034 pin `cutoff:`. It is inclusive, it bounds the distance alone under A* too, and
  the start is always expanded.
- IG-035 has an admissible, inconsistent heuristic that reopens a state, with the closures' call
  sequences.
- IG-036 – IG-038 cover `Double` costs, zero costs with a zero-cost cycle, and several goals.
- IG-039 – IG-044 are the traps, including a NaN priority from an infinite cost and an estimate of
  −∞.

Tie-breaking between equal paths is not pinned.
