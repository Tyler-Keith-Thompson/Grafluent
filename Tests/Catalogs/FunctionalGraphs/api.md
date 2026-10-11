# FunctionalGraphs: proposed API (phase 1)

A functional graph is the graph of a function f : V → V. Every vertex has exactly one out-edge,
v → f(v). Fixed points are self-loops. Each weakly connected component holds exactly one cycle,
with rooted trees hanging off its vertices (Flajolet and Odlyzko, "Random mapping statistics",
EUROCRYPT '89; Laaksonen, *Competitive Programmer's Handbook*, §16.3 "Successor graphs"). The
module has two parts:

- **`FunctionalGraph`**, a stored f over the vertices `0..<n` that conforms to `DirectedGraph`,
  with its O(n) **cycle decomposition** (cycles, trees, tail lengths, preimages, k-th successors);
- **`floydCycleDetection` and `brentCycleDetection`**, which take f as a closure with O(1) memory
  (the README's "can be built straight from a closure, with no stored graph").

`cases.md` (FG-001 – FG-062, 62 rows) pins the values. `ref.py` ports the storage and the
algorithms. It checks every graph against NetworkX 3.7 and against brute force from the
definitions:

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

## Names

| Name | Decision | Source |
|---|---|---|
| Type | **`FunctionalGraph`** (README Structures row; module stub `FunctionalGraphs`) | "functional graph" is the graph-theory term (Harary; Flajolet–Odlyzko say "random mapping"). Laaksonen calls it a "successor graph"; that is the doc comment's second name, with no typealias |
| f(v) | **`successor(of:)`**, singular, next to the protocol's `successors(of:)` | Laaksonen's `succ(x)`; pathfinding's closure argument is named `successor` |
| f^k(v) | **`successor(of:steps:)`** | Laaksonen's `succ(x, k)`, "the node we reach if we begin at x and walk k steps forward". Sage's `evolution_power(k)` is f^k as a whole function (phase 2's `iterated`) |
| Decomposition | **`cycleDecomposition() -> FunctionalGraph.CycleDecomposition`** | For a permutation it is exactly the cycle decomposition (Sage `Permutation.cycle_tuples`, `FiniteDynamicalSystem.cycles()`). For a general f the doc comment says "each vertex's tail and the cycle it reaches", in Flajolet–Odlyzko's terms |
| μ | **`tailLength(of:)`**; tuple label `tailLength` | Flajolet–Odlyzko "tail length". Sage calls it `preperiod` (`orbit(x, preperiod=True)`); pathfinding calls it "index of first element". The doc comment names both |
| λ | **`cycleLength(of:)`**; tuple label `cycleLength` | Flajolet–Odlyzko "cycle length"; pathfinding "cycle size". Knuth and Wikipedia use λ for the cycle and μ for the tail, while Flajolet–Odlyzko swap the letters, so **no Greek letters in the API** |
| First cyclic vertex on v's walk | **`root(of:)`**; tuple label `root` | The root of v's tree (Flajolet–Odlyzko: a component is "a cycle of trees"); `Trees` already says `root`. pathfinding says "first element" |
| Component | **`component(of:) -> Int`**, an index into `cycles` | `Components.component(of:)`, `Forest.component(of:)` |
| Preimages | **`preimages(of:)`**, **`inDegree(of:)`** | "preimage" is the function term; a `predecessors(of:)` here would suggest a `BidirectionalDirectedGraph` conformance that the graph does not have. `inDegree` matches the protocol |
| Closure algorithms | **`floydCycleDetection(from:successor:)`**, **`brentCycleDetection(from:successor:)`** | pathfinding's `cycle_detection::{floyd, brent}(start, successor)`. As in ShortestPaths D7, the algorithm name goes in the function name (`dijkstraShortestPaths`), and "cycle detection" is the problem's name (Knuth, Brent, Wikipedia) |

## Storage

```swift
@frozen
public struct FunctionalGraph {
    @usableFromInline internal var _successors: [Int]   // _successors[v] = f(v), each in 0..<n
}
```

Vertices are `Int`s `0..<n`, as in `CompressedSparseRow` and `AdjacencyMatrix`. For hashable
labels, use `LabeledGraph<Label, FunctionalGraph>` (open question 1). The edge leaving `v` has
position `v`, so edge positions and edge indices are both the source.

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

It is **not** a `BidirectionalDirectedGraph`: predecessors would need a stored inverse (2n + 1
more `Int`s), and most uses never read it. The inverse is built by `cycleDecomposition()`, which
needs it anyway. `_withSuccessorIndexRows` keeps the default (`nil`): the CSR rows would need an
`[0, 1, …, n]` offsets array, and the `CollectionOfOne` zip path is already branch-free.

**Traps:** a vertex outside `0..<n` (FG-019, FG-020), as for every dense representation.

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

**Algorithm** (as implemented; the walk-and-unwind plan first written here measured 4× slower on
a random mapping, a chain of dependent cache misses per vertex):

1. A counting sort of f gives the preimage rows (ascending, FG-031) and the in-degrees.
2. Peel the vertices of in-degree zero, repeatedly, leaves first, adding each one's subtree size
   to its successor's. What remains is exactly the cyclic vertices.
3. Walk each cycle from its least vertex, the cycles in order of least vertex (FG-040, FG-041).
4. Revisit the peeled vertices in reverse (parents first): tail length, root, and a preorder
   number from the subtree sizes (each child takes its parent's next free number).
5. A counting sort of the tree vertices by depth, each depth in preorder, with each one's
   preorder number beside it.
6. For `successor(of:steps:)`: for k < tail(v), the answer is the vertex at depth tail(v) − k
   with the greatest preorder number ≤ pre(v), by binary search (a level-ancestor query, Bender
   and Farach-Colton's problem); for k ≥ tail(v), it is
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

`Vertex` needs only `Equatable`, never `Hashable`: that is the point of O(1) memory (FG-059 uses
a struct with no hash). The orbit of `start` must be eventually periodic. On an infinite orbit,
neither function returns, which is the same contract as `iterativeDeepeningDepthFirstSearch`.

**The pinned formulations** (the `calls` column of FG-047 – FG-059 counts closure calls, so a
different variant fails the tests):

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

  Calls are never more than Floyd's on any catalog row, and about 36% fewer on Collatz-27 (351
  against 554).

### Conformances

- **`Equatable`, `Hashable`**: the successor arrays (FG-060).
- **`Sendable`**.
- **`Codable`** as the bare array. Decoding re-checks the range and throws
  `DecodingError.dataCorrupted` (FG-062).
- **`CustomStringConvertible`**: `FunctionalGraph([1, 2, 0])` (FG-061).

## Performance targets

Measured in the benchmark target. Per the test policy, call counts that are not observable
through a closure are benchmark-only.

| Measure | Target |
|---|---|
| `cycleDecomposition()`, random mapping, n = 10⁶ (√(πn/8) ≈ 627 expected cycle length; long tails) | ≤ 4× `CompressedSparseRow.transposed()` on the same n edges; ≤ 6n + O(1) `Int`s; no per-vertex allocation. 4×, not 3×: the decomposition includes a full transpose (its preimage rows) and then a peel, a reverse pass and a counting sort, the first two a random access per vertex each. **Met** (2026-10-11, p50, under parallel builds): 20 ms against 7.7 ms, 2.6× (6× before the layout of Benchmarks/README.md); 4.1× in a standalone probe against a transpose loop with no allocation. The result is 5n + 3 `Int`s; building it takes 3n more for a moment |
| `CycleDecomposition.successor(of:steps:)` | O(log n) binary search, ≤ 150 ns at n = 10⁶; O(1) when k ≥ tail |
| `FunctionalGraph.successor(of:steps:)` | O(min(k, n)), zero allocation |
| `floydCycleDetection` / `brentCycleDetection` | Zero allocation; closure calls exactly as pinned; the closure is not escaping, so it inlines in a specialized build |
| Generic algorithms (`breadthFirstLayers`, `weaklyConnectedComponents`, `stronglyConnectedComponents`, `topologicalSort`) | ≤ 1.1× the same call on a `CompressedSparseRow` of the same edges. `SuccessorIndices = CollectionOfOne` keeps index-space rows hash-free |
| Memory of the graph | n `Int`s (CSR of the same graph: 2n + 1) |

## Prior art (checked 2026-10-11)

| Source | What it has | Taken |
|---|---|---|
| NetworkX 3.7 | No functional-graph type. `attracting_components` (in a functional graph these are exactly the cycles), `simple_cycles`, `weakly_connected_components`, `find_cycle` | The oracles in `ref.py`; the `Generic` rows (FG-045, FG-046) |
| SageMath `sage.dynamics.finite_dynamical_system` | `FiniteDynamicalSystem(X, φ)`: `evolution()`, `evolution_power(n)`, `orbit(x, preperiod=False)` (with `preperiod=True` returns the smallest k at which φᵏ(x) repeats), `cycles()` ("all cycles, up to cyclic rotation"), `is_invariant`; the invertible subclass adds `orbits()`, `orbit_lengths()`, `inverse_evolution()` | `cycles` (with the rotation fixed to the least vertex); `preperiod` as the doc synonym of `tailLength`; `evolution_power` → phase 2 `iterated(_:)` |
| Mathematica | No functional-graph type: `NestList`, `FixedPointList`, `FindTransientRepeat[list, n]` ({transient, repeat} of a list), `FindCycle` on a `Graph` | Confirms "transient/tail" and "repeat/cycle" as the two parts; nothing taken by name |
| pathfinding (Rust) `directed::cycle_detection` | `floyd`, `brent` → (cycle size, first element, index of first element); `floyd_partial`, `brent_partial` → (size, an element of the cycle, an *upper bound* on the index) | The closure shape and the `successor` label; the partial forms are phase 2 |
| Knuth, TAOCP vol. 2, §3.1 ex. 6 (Floyd); Brent, BIT 20 (1980) | The two algorithms, μ and λ | The pinned formulations |
| Flajolet and Odlyzko (1990) | "tail length", "cycle length", "rho length", "cyclic nodes", "terminal nodes", components as cycles of trees | The names `tailLength`, `cycleLength`, `root` |
| Laaksonen, *CPH* §16.3 | "successor graph", `succ(x, k)` by binary lifting in O(log k) after O(n log u) preprocessing | `successor(of:steps:)`; binary lifting declined (below) |

## Open questions (with recommendations)

1. **`Int` storage or a generic `Vertex`?** *Recommendation:* `Int` over `0..<n`, with labels
   through `LabeledGraph<Label, FunctionalGraph>`. This is the house pattern for representations
   built on vertex numbers (CSR, matrix). A generic `FunctionalGraph<Vertex>` would re-implement
   `LabeledGraph`'s `OrderedSet` and its forwarding.
   - The one gap: `cycleDecomposition()` lives on `FunctionalGraph`, so labeled users call
     `labeled.base.cycleDecomposition()` and map indices through `labeled.vertex(atIndex:)`.
   - Phase 2: a `LabeledGraph where Base == FunctionalGraph` extension returning a labeled view of
     the decomposition.
2. **Binary lifting?** *Recommendation: not in phase 1.* The decomposition answers f^k(v) for
   *every* k ≤ `Int.max` in O(log n) after O(n) preprocessing. Binary lifting needs
   n·⌈log₂ K⌉ `Int`s for a maximum K: 480 MB for n = 10⁶ and K = 10¹⁸. Its only advantage is
   O(log K) *batched* composition, and phase 2's `iterated(_:)` (f^k as a whole graph, O(n) via
   the decomposition) covers that.
3. **Mutation?** *Recommendation:* immutable in phase 1. A `subscript(successorOf:)` setter is
   trivial on the array, but every derived structure (the decomposition) goes stale, and nothing
   asks for it yet. Phase 2, if wanted: `updateSuccessor(of:to:)`-style mutation following the
   repo's mutation naming pass.
4. **`BidirectionalDirectedGraph`?** No (see Reads). Revisit if a generic algorithm that needs
   predecessors (dominators, `ancestors(of:)`) turns out to matter on functional graphs; the
   decomposition can hand out a `CompressedSparseRow` of the inverse at no extra cost.

## Phases

- **Phase 1 (this catalog):**
  - `FunctionalGraph` with its `DirectedGraph` conformance;
  - `successor(of:steps:)`;
  - `cycleDecomposition()`;
  - `floydCycleDetection` and `brentCycleDetection`.
- **Phase 2:**
  - `iterated(_ k:) -> FunctionalGraph` (Sage's `evolution_power`), in O(n) through the
    decomposition;
  - `composed(with:)`;
  - `isPermutation` and `inverse() -> FunctionalGraph?` (Sage's `inverse_evolution`);
  - `floydCycleDetection(partial:)` and `brentCycleDetection(partial:)`, or separate names after
    pathfinding's `_partial`;
  - the labeled decomposition (open question 1);
  - random-mapping statistics (the number of cyclic and terminal vertices) as cheap
    decomposition reads.
