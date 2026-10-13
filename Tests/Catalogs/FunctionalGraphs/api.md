# FunctionalGraphs: API

A functional graph is the graph of a function f : V → V. Every vertex has exactly one out-edge,
v → f(v). Fixed points are self-loops. Each weakly connected component holds exactly one cycle,
with rooted trees hanging off its vertices (Flajolet and Odlyzko, "Random mapping statistics",
EUROCRYPT '89). The module has two parts:

- `FunctionalGraph`, a stored f over the vertices `0..<n` that conforms to `DirectedGraph`, with
  its O(n) cycle decomposition (cycles, trees, tail lengths, preimages, k-th successors);
- `floydCycleDetection` and `brentCycleDetection`, which take f as a closure and use O(1) memory.

`cases.md` (FG-001 – FG-066) pins the values. `ref.py` ports the storage and the algorithms. It
checks every graph against NetworkX 3.7 and against brute force from the definitions:

- the cycles against `attracting_components` and `simple_cycles`;
- the components against `weakly_connected_components`;
- the tail lengths against distances to the cycles on the reverse graph;
- the preimages against predecessors;
- `successor(of:steps:)` against iterating f, for every k up to 2n + 2 and for `Int.max`;
- `(tailLength, cycleLength, root)` against the first repeat of each orbit.

It also checks the Floyd call count against its closed form (below). `--stress` adds:

- 1 500 random mappings, permutations and long-tail mappings;
- 300 Pollard-rho closures;
- one random mapping on 200 000 vertices.

To run it:
`uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/FunctionalGraphs/ref.py [--write] [--stress]`.

Knuth and Wikipedia use λ for the cycle and μ for the tail, while Flajolet and Odlyzko swap the
letters, so the API uses `tailLength` and `cycleLength` and no Greek letters. Below, μ is the tail
and λ the cycle.

## Storage

```swift
@frozen
public struct FunctionalGraph {
    @usableFromInline internal var _successors: [Int]   // _successors[v] = f(v), each in 0..<n
    // plus the attached maps and the generation stamp
}
```

Vertices are `Int`s `0..<n`, as in `CompressedSparseRow` and `AdjacencyMatrix`. For hashable
labels, use `LabeledGraph<Label, FunctionalGraph>`. The edge leaving `v` has position `v`, so edge
positions and edge indices are both the source. The graph is immutable.

## API

n = vertices. All bounds are worst case unless marked.

### Construction

```swift
extension FunctionalGraph {
    public init(successors: some Sequence<Int>)                       // O(n)
    public init(vertexCount: Int, successor: (Int) -> Int)            // O(n): calls successor(v) once per v, ascending
    public init?(_ graph: some DirectedGraph)                         // O(n + m); vertex i = graph's i-th vertex
}
```

- `init?(_ graph:)` returns nil unless every out-degree is 1. Parallel edges count (FG-013 –
  FG-015). Index i is the i-th vertex in `vertices` order (FG-011), so
  `LabeledGraph(FunctionalGraph(g)!, labels: g.vertices)` gives the labels back.
- **Traps:**
  - a successor outside `0..<n` (FG-007, FG-009, FG-010);
  - a negative `vertexCount` (FG-008).

### Reads (`DirectedGraph`)

```swift
extension FunctionalGraph: DirectedGraph {
    public typealias Vertex = Int
    public typealias Vertices = Range<Int>
    public typealias Successors = CollectionOfOne<Int>
    public typealias OutEdges = CollectionOfOne<Int>
    public typealias SuccessorIndices = CollectionOfOne<Int>          // overrides the hashing default
    public struct Edges: RandomAccessCollection { Index = Int, Element = DirectedEdge<Int> }   // edges[p] = p → f(p)

    public func successor(of v: Int) -> Int                           // O(1)
    public var vertices: Range<Int>; var edges: Edges                 // O(1)
    public func successors(of:) / outEdges(of:) -> CollectionOfOne<Int>   // O(1)
    public func outDegree(of:) -> Int                                 // 1
    public var vertexCount: Int; var edgeCount: Int                   // both n
    public func contains(_:) -> Bool                                  // O(1), false outside 0..<n
    public func contains(edge:) -> Bool                               // O(1): f(s) == t
    public var vertexIndexBound: Int? / edgeIndexBound: Int?          // n / n
    public func vertexIndex(of:), vertex(atIndex:), edgeIndex(of:)    // identity, range-checked
    public func successorIndices(ofIndex:) / outEdges(ofIndex:)       // O(1)
    public func source(ofEdgeAt:) -> Int                              // p
    public func target(ofEdgeAt:) -> Int                              // f(p)
}
```

It is not a `BidirectionalDirectedGraph`. The preimages come from `cycleDecomposition()`.
`_withSuccessorIndexRows` keeps the default (`nil`).

**Traps:** a vertex outside `0..<n` (FG-019, FG-020), as for every dense representation.

**`checked:` spellings**: `successor(checked:)`, `successor(checked:steps:)`,
`successors(checked:)`, `outEdges(checked:)`, `outDegree(checked:)` and `vertexIndex(checked:)` throw
`VertexNotFound` for a vertex outside `0..<n`; `source(checkedEdgeAt:)` and `target(checkedEdgeAt:)`
throw `EdgeNotFound` for a position outside `0..<n` (FG-063). Each checks once and then calls the
plain spelling. A negative step count is a misuse, not a missing vertex, and still traps (FG-064).
The cycle decomposition has the same: `component(checked:)`, `root(checked:)`, `tailLength(checked:)`,
`cycleLength(checked:)`, `preimages(checked:)`, `inDegree(checked:)` and `successor(checked:steps:)`
throw `VertexNotFound` off `0..<n` (FG-065); negative steps still trap (FG-066).

```swift
extension FunctionalGraph {
    /// f^k(v). O(min(k, n)) time, O(1) memory: walks k steps when k <= n, otherwise finds v's
    /// tail and cycle by Brent's algorithm and walks μ + (k − μ) mod λ steps.
    public func successor(of v: Int, steps k: Int) -> Int
    public func cycleDecomposition() -> CycleDecomposition            // O(n) time, ≈ 5n Ints
}
```

**Trap:** `steps < 0` (FG-025).

### The cycle decomposition

```swift
extension FunctionalGraph {
    @frozen public struct CycleDecomposition: Sendable {
        /// The cycles, each listed from its least vertex in walk order (v, f(v), …), and the cycles
        /// ordered by least vertex. A collection of slices of one flat array, as `Components`.
        public var cycles: Cycles { get }                             // RandomAccessCollection of ArraySlice<Int>
        public func component(of v: Int) -> Int                       // O(1): the index in `cycles` of the cycle v reaches
        public func root(of v: Int) -> Int                            // O(1): the first cyclic vertex on v's walk
        public func tailLength(of v: Int) -> Int                      // O(1): steps to root(of: v); 0 on a cycle
        public func cycleLength(of v: Int) -> Int                     // O(1)
        public func preimages(of v: Int) -> ArraySlice<Int>           // O(1), ascending
        public func inDegree(of v: Int) -> Int                        // O(1)
        public func successor(of v: Int, steps k: Int) -> Int         // O(log n), any k >= 0
    }
}
```

**Algorithm:**

1. A counting sort of f gives the preimage rows (ascending, FG-031) and the in-degrees.
2. Peel the vertices of in-degree zero, repeatedly, leaves first, adding each one's subtree size
   to its successor's. What remains is exactly the cyclic vertices.
3. Walk each cycle from its least vertex, the cycles in order of least vertex (FG-040, FG-041).
4. Revisit the peeled vertices in reverse (parents first): tail length, root, and a preorder
   number from the subtree sizes (each child takes its parent's next free number).
5. A counting sort of the tree vertices by depth, each depth in preorder, with each one's
   preorder number beside it.
6. For `successor(of:steps:)`: for k < tail(v), the answer is the vertex at depth tail(v) − k
   with the greatest preorder number ≤ pre(v), by binary search (a level-ancestor query); for
   k ≥ tail(v), it is
   `cycle[(position(root) + k − tail) mod λ]`, with no overflow even at `Int.max`.

Nothing recurses. The result is 5n + O(1) `Int`s plus one per cycle and per unit of the longest
tail: the per-vertex records are three `Int32`s (as `Trees` keeps its nodes), so the
decomposition needs fewer than 2³¹ vertices.

**Traps:**
- a vertex outside `0..<n` (FG-043);
- `steps < 0` (FG-044);
- `cycleDecomposition()` on 2³¹ − 1 vertices or more (not testable at that size).

### Cycle detection over a closure

```swift
public func floydCycleDetection<Vertex: Equatable>(
    from start: Vertex, successor: (Vertex) -> Vertex
) -> (tailLength: Int, cycleLength: Int, root: Vertex)
public func brentCycleDetection<Vertex: Equatable>(
    from start: Vertex, successor: (Vertex) -> Vertex
) -> (tailLength: Int, cycleLength: Int, root: Vertex)
```

`Vertex` needs only `Equatable`, not `Hashable` (FG-059 uses a struct with no hash). The orbit of
`start` must be eventually periodic. On an infinite orbit, neither function returns.

**The formulations** (the `calls` column of FG-047 – FG-059 counts closure calls, so a different
variant fails the tests):

- **Floyd** (Knuth TAOCP vol. 2, §3.1 ex. 6):
  1. `t = f(x0); h = f(f(x0))`, then while `t != h`: `t = f(t); h = f(f(h))`;
  2. `μ = 0; t = x0`, then while `t != h`: `t = f(t); h = f(h); μ += 1`;
  3. `λ = 1; h = f(t)`, then while `t != h`: `h = f(h); λ += 1`.

  Calls: **3ν + 2μ + λ**, where ν is the least multiple of λ that is ≥ max(μ, 1). `ref.py`
  asserts this closed form.
- **Brent** (BIT 20 (1980) 176–184):
  1. `power = λ = 1; t = x0; h = f(x0)`;
  2. while `t != h`: if `power == λ` then `t = h; power *= 2; λ = 0`; then `h = f(h); λ += 1`;
  3. `t = h = x0`, then advance `h` λ times;
  4. `μ = 0`, then while `t != h`: `t = f(t); h = f(h); μ += 1`.

  Calls are never more than Floyd's on any catalog row.

### Conformances

- `Equatable`, `Hashable`: the successor arrays (FG-060).
- `Sendable`.
- `Codable` as the bare array. Decoding re-checks the range and throws
  `DecodingError.dataCorrupted` (FG-062).
- `CustomStringConvertible`: `FunctionalGraph([1, 2, 0])` (FG-061).

### Attached maps and the generation

`FunctionalGraph` is a `PropertyGraph` (GraphProtocols): a vertex map and an edge map are each one
dense array of n values, allocated in full when attached, the edge leaving `v` at position `v`. The
plain subscripts trap off `0..<n`; the `checked` subscripts throw. Every initializer stamps a
generation, which nothing advances, since the graph is immutable. Equality, hashing and coding
ignore both.

## Performance

| Measure | Bound |
|---|---|
| `cycleDecomposition()` | O(n); 5n + 3 `Int`s in the result, 3n more while building; no per-vertex allocation |
| `CycleDecomposition.successor(of:steps:)` | O(log n) binary search; O(1) when k ≥ tail |
| `FunctionalGraph.successor(of:steps:)` | O(min(k, n)), no allocation |
| `floydCycleDetection` / `brentCycleDetection` | No allocation; closure calls exactly as above |
| Generic algorithms | `SuccessorIndices = CollectionOfOne` keeps index-space rows hash-free |
| Memory of the graph | n `Int`s |
