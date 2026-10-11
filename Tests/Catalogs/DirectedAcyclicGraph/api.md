# DirectedAcyclicGraphModule: proposed API (phase 1)

`DirectedAcyclicGraph<Base>` wraps a mutable directed representation and keeps it acyclic: an
edge that would close a cycle is rejected, and the call returns `nil` (README Principle 4,
Structures row). The path the edge would close comes from Traversal's existing path query. The wrapper keeps a topological order of its vertices
current under insertions and removals, maintained by Pearce–Kelly, the algorithm JGraphT's
`DirectedAcyclicGraph` and petgraph's `acyclic::Acyclic` both use. It follows the rule-adding
wrapper pattern of README open question 9, as `DirectedMultigraph` over `DirectedPseudograph`
does: every read member forwards to the base, and the wrapper adds only the insertion rule and
the order.

`cases.md` (DAG-001 – DAG-087, 87 rows) pins the values. `ref.py` ports the wrapper over ports
of the three phase-1 bases (`AdjacencyList`, `DirectedPseudograph` and `StableDirectedGraph`:
slots, rows and swap-remove moves as their sources have them). It checks every state against:

- the laws: the order is a permutation of the vertices, and every edge goes forward;
- each witness (`bidirectionalShortestPath(from: v, to: u)` for a rejected u→v), which must be a
  shortest path of the graph from the edge's target to its source.

`--stress` runs 450 seeded sequences of 60 steps (150 on each base) and checks them against:

- a NetworkX specification. It rejects an edge exactly when the edge is a self-loop or
  `has_path(target, source)` holds. It computes Pearce–Kelly's affected sets from
  `descendants` and `ancestors` filtered by the old order. Every state must match the port's
  order exactly;
- a rustworkx `PyDiGraph(check_cycle=True)` shadow, which must accept and reject the same edges;
- NetworkX's `transitive_closure_dag`, `transitive_reduction`, `dag_longest_path_length` and,
  before any removal, `dag_longest_path(topo_order=ours)` exactly;
- `has_path`.

To run it:
`uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/DirectedAcyclicGraph/ref.py [--write] [--stress]`.

## Names

| Name | Decision | Source |
|---|---|---|
| Type | **`DirectedAcyclicGraph<Base>`** (README) | JGraphT `DirectedAcyclicGraph`; NetworkX "DAG" |
| Module | **`DirectedAcyclicGraphModule`** (exists as a stub) | README package layout |
| The order | **`topologicalOrder`**, a `RandomAccessCollection` of vertices (README) | "topological order" (CLRS); JGraphT `iterator()`, petgraph `nodes_iter()` |
| Place in the order | **`topologicalPosition(of:)`**, `topologicalPosition(safe:)` | petgraph `get_position` (`TopologicalPosition`); `at_position` is the collection's subscript |
| Insertion result | **`Edges.Index?`**: the position, or `nil` on a cycle (decided: no `EdgeInsertion` type, an invented name; open question 3) | JGraphT `addEdge` (returns the edge, rejects a cycle); petgraph `try_add_edge` |
| Base access | **`base`** (read-only) | README open question 9; petgraph `inner()` |
| Algorithms | `transitiveClosure()`, `transitiveReduction()`, `longestPath()`, `hasPath(from:to:)` | NetworkX `transitive_closure_dag`, `transitive_reduction`, `dag_longest_path`, `has_path` |

## Storage

```swift
@frozen
public struct DirectedAcyclicGraph<Base: MutableDirectedGraph> {
    @usableFromInline internal var _base: Base
    @usableFromInline internal var _order: ContiguousArray<Int>   // keys in topological order
    @usableFromInline internal var _place: ContiguousArray<Int>   // key -> its offset in _order
}
```

A key is the base's vertex index (its slot) on a dense base, and the vertex position on
`StableDirectedGraph`. As implemented, the places live in a `_KeyTable` paged as `_PositionNumbers`
is (a page table plus 1024-entry blocks, freed and reused once empty), so memory follows the live
vertices on every base. Pearce–Kelly's scratch (the two visited sets, the slot pool and
the stack) is kept in the value and reused between inserts. A visit stamp replaces the clearing
of the sets, so a fast-path insert allocates nothing and a reorder allocates only to grow.

## Base protocol (open question 1)

```swift
/// Boost's `MutableGraph` concept, directed. In GraphProtocols; the hooks are underscored. A key
/// is a vertex's index in `vertices`: its slot on a dense base, its position on a stable one.
public protocol MutableDirectedGraph<Vertex>: BidirectionalDirectedGraph where Vertices.Index == Int {
    init()
    mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)
    mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>?
    mutating func removeAll(keepingCapacity: Bool)
    mutating func removeAllEdges(keepingCapacity: Bool)
    mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)
    func _key(of vertex: Vertex) -> Int?                         // one hash
    func _vertex(atKey key: Int) -> Vertex
    func _successors(ofKey key: Int) -> Successors               // and _predecessors
    func _successorKeys(ofKey key: Int) -> SuccessorIndices      // the stored row; and _predecessorKeys
    func _outEdges(ofKey key: Int) -> OutEdges                   // and _inEdges
    func _outDegree(ofKey key: Int) -> Int                       // and _inDegree
    func _sourceKey(ofEdgeAt position: Edges.Index) -> Int       // and _targetKey
    mutating func _insertVertex(_ vertex: Vertex) -> Int         // appends; returns the key
    mutating func _insertEdge(fromKey: Int, toKey: Int) -> Edges.Index   // existing position on a simple base
    mutating func _removeVertex(atKey key: Int) -> Int?          // the old key of the vertex moved in, if any
    mutating func _removeEdge(at position: Edges.Index) -> DirectedEdge<Vertex>
}
```

Phase-1 conformers are `AdjacencyList`, `DirectedPseudograph` and `StableDirectedGraph`. All
three are bidirectional, and Pearce–Kelly needs the backward search. `DirectedMultigraph` is not
needed: over `DirectedPseudograph` the wrapper already excludes self-loops, the only rule
`DirectedMultigraph` adds. Phase 2 adds `AdjacencyMatrix` and `LabeledGraph<_, AdjacencyMatrix>`
(vertices are only appended, so there is no move) for dense DAGs and the closure.
`CompressedSparseRow` is immutable and never qualifies.

## API

n = vertices, m = edges. δ is the affected region of a Pearce–Kelly reorder: the vertices placed
between the edge's endpoints that it must move, and ‖δ‖ is those vertices plus their edges.

### Construction

```swift
extension DirectedAcyclicGraph {
    public init()                                                    // O(1)
    public init(vertices: some Sequence<Vertex>)                     // O(n) expected; order = vertices order
    public init?(edges: some Sequence<DirectedEdge<Vertex>>)         // O(n + m) expected
    public init?(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>)
    public init?(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content)
    public init?(_ base: Base)                                       // O(n + m), no hashing
    public init?(_ graph: some DirectedGraph<Vertex>)                // = init(vertices:edges:)
}
```

- **Failable, like `DirectedMultigraph`'s:** `nil` when the edges have a cycle, a self-loop
  included (DAG-009, DAG-010). The witness is Traversal's `base.findCycle()`, so the initializer
  does not duplicate it; the order is Kahn's, computed in key space.
- **The base is built as the base builds itself:** listed vertices first, then new endpoints in
  first-appearance order. Copies collapse on `AdjacencyList` (DAG-007) and are kept on the
  others (DAG-006).
- **The initial order is Kahn's, FIFO, with roots in `vertices` order**: Traversal's
  `topologicalGenerations()` flattened (DAG-003, DAG-004). An edgeless graph keeps `vertices`
  order, as online insertion would (DAG-002). The DFS order of `topologicalSort()` would reverse
  it (DAG-005). It costs O(n + m), against O(m · δ) for replaying the edges one by one, so bulk
  construction and replay can give different orders. Both are defined.

### Reads

```swift
extension DirectedAcyclicGraph: BidirectionalDirectedGraph {
    // Every requirement forwards to the base and is @inlinable: vertices, edges, successors,
    // outEdges, source/target, vertexIndexBound, vertexIndex(of:), vertex(atIndex:),
    // successorIndices/predecessorIndices (the base's own types), sourceIndex/targetIndex,
    // edgeIndexBound, edgeIndex(of:), _withSuccessorIndexRows.
}
extension DirectedAcyclicGraph: SparselyIndexedDirectedGraph where Base: SparselyIndexedDirectedGraph {}
extension DirectedAcyclicGraph {
    public var base: Base { get }                                     // O(1)
    public var topologicalOrder: TopologicalOrder { get }             // O(1)
    public func topologicalPosition(of vertex: Vertex) -> Int         // O(1) expected; traps on a non-vertex
    public func topologicalPosition(safe vertex: Vertex) -> Int?
    public func successors(safe:) / predecessors(safe:) / outEdges(safe:) / inEdges(safe:)
        / outDegree(safe:) / inDegree(safe:)                          // one hash, then the base's row
}
public struct TopologicalOrder: RandomAccessCollection {              // nested in DirectedAcyclicGraph
    // Index = Int, 0..<n; subscript O(1) (petgraph's at_position); traps out of range (DAG-061)
    // firstIndex(of:) / contains via the table (the _customIndexOfEquatableElement hook): O(1), or O(log n) behind a removal
}
```

- **Algorithms see the base.** Every index-space member is the base's, so Traversal,
  Connectivity, ShortestPaths and the rest run at base speed, the same law `LabeledGraph`
  benchmarks (within 1.05×). Index-space algorithms over a stable base with holes take the
  `SparselyIndexedDirectedGraph` path.
- **`safe:` members** are defined on the wrapper for every base (`_key(of:)` then the row), so a
  base without them, such as `AdjacencyList`, still gets them (Principle 6).
- Traversal's `topologicalSort()`, `topologicalGenerations()`, `lexicographicalTopologicalSort()`,
  `findCycle()`, `isAcyclic`, `descendants(of:)` and `ancestors(of:)` apply unchanged, and none
  returns `nil` or a cycle. The wrapper does not shadow them with non-optional overloads: a
  shadow that differs only in optionality breaks `if let` at call sites that move between a
  graph and a DAG. `topologicalOrder` is the non-optional answer.

### Mutation

```swift
extension DirectedAcyclicGraph {
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex)   // O(1) amortized; last in the order
    @discardableResult public mutating func insert(edge: DirectedEdge<Vertex>) -> Edges.Index?   // nil: a cycle
    @discardableResult public mutating func insert(safe edge: DirectedEdge<Vertex>) -> Edges.Index?   // nil: a cycle or a missing endpoint
    @discardableResult public mutating func remove(_ vertex: Vertex) -> Vertex?     // base cost + O(n − position)
    @discardableResult public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>?  // base cost
    @discardableResult public mutating func remove(edgeAt position: Edges.Index) -> DirectedEdge<Vertex> // base cost; Base: has it
    public mutating func removeAll(keepingCapacity: Bool = false)
    public mutating func removeAllEdges(keepingCapacity: Bool = false)               // order kept
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int)
}
```

**`insert(edge:)`**, for an edge u→v, follows Pearce–Kelly:

1. **Self-loop:** `nil` before anything is inserted, even when u is not a vertex (DAG-030,
   DAG-031, DAG-044).
2. **Missing endpoints** are inserted, source first. **As implemented** after the review, a new
   source whose target is already a vertex is placed first, any other new endpoint last, so the
   edge goes forward and nothing reorders (DAG-014, DAG-016 – DAG-019). Placed last, as first
   proposed, each such source moved its target and all the target's descendants: a chain whose
   sources arrive last took Θ(n²), 637 ms at n = 8000 against the bare base's 1.8 ms.
3. **Fast path:** if u is placed before v, the base inserts the edge. Cost: two array reads plus
   the base's insert (DAG-013, DAG-015, DAG-017).
4. **Forward search:** otherwise, search depth-first from v in `outEdges` order, only through
   vertices placed before u. If the search meets u, the result is `nil`, and nothing changes
   (DAG-032 – DAG-040). The witness is a separate call, Traversal's
   `bidirectionalShortestPath(from: v, to: u)`, a shortest path; where several tie, the cell
   lists each (DAG-034, DAG-036). It searches again, on failure only.
5. **Backward search** from u through vertices placed after v. Then the backward set B, by old
   place, and then the forward set F, by old place, take the pooled places in increasing order.
   Nothing outside B ∪ F moves (DAG-021 – DAG-028). Both sets are defined by reachability and the
   old order, never by row order, so the order after any sequence of operations is a function of
   that sequence (DAG-028, and the stress spec). Cost: O(‖δ‖ + δ log δ).

**Removals never create a cycle, so they keep the order** (DAG-044 – DAG-056):

- **`remove(edge:)`** and `remove(edgeAt:)` leave the order untouched.
- **`remove(_:)`** leaves a hole in the vertex's slot (JGraphT leaves a gap too). **As
  implemented** after the review, each vertex's label is its slot in an array of slots with free
  slots at the front (for sources placed first) and holes where vertices were removed; holes at
  either end are trimmed, and the slots are compacted once holes outnumber vertices, so removal
  is amortized O(1) for the order. A Fenwick tree over the slots counts the holes before a slot,
  O(log n) per removal and per `topologicalPosition(of:)` while there are holes, O(1) with none.
  The first implementation closed the gap with a memmove, O(n − position) (removing 10% of 10⁵
  vertices: 185 ms against the base's 75 ms; now 70 against 72), and one early removal made
  every lookup a binary search (143 against 16 ns; now 16 ns after a trimmed removal and 38 ns
  with a hole). petgraph's `get_position` returns a gapped label (its `remove_node` is O(log n)).
- **Swap-remove on dense bases:** the base reports the move (the last slot into the hole). The
  wrapper re-keys the moved vertex in O(1) and its place stays the same (DAG-050, DAG-051).
- **`StableDirectedGraph`** never moves a vertex (DAG-052).
- **`removeAllEdges()`** keeps the order (any order fits an edgeless graph, DAG-054).
- **`removeAll()`** clears it.

**Traps:**

- `remove(edgeAt:)` out of range, or at a stable hole (DAG-047, DAG-048);
- `topologicalPosition(of:)` and `hasPath(from:to:)` on a non-vertex (DAG-058, DAG-065);
- `topologicalOrder[i]` out of range (DAG-061).

Removal of an absent vertex or edge returns `nil` and does not trap (DAG-045, DAG-053).

Phase 2 adds `changeTarget(ofEdgeAt:to:)` and `changeSource(ofEdgeAt:to:)` on a stable base. Each
returns `false` when it fails and costs the same as an insert.

### Algorithms (phase 1)

```swift
extension DirectedAcyclicGraph {
    public func hasPath(from source: Vertex, to target: Vertex) -> Bool      // O(1) when source is placed after target
    public func transitiveClosure() -> Self                                  // O(n · m / 64 + output)
    public func transitiveReduction() -> Self                                // O(n · m / 64)
    public func longestPath() -> Path<Vertex, Edges.Index>?                  // O(n + m); nil only when empty
}
```

- **`hasPath(from:to:)`** shadows Traversal's (a protocol-extension method, so the concrete
  member wins with no change in type). It answers true for the same vertex, and false without a
  search when the source is placed after the target. Otherwise it searches only through the
  places up to the target's (DAG-062 – DAG-064). That is the same pruning Pearce–Kelly uses.
- **`transitiveClosure()`** is NetworkX's `transitive_closure_dag` (not reflexive). It is a copy
  of the DAG with, for each u in topological order, the missing u→w appended for every
  descendant w in topological order. Existing edges and copies keep their positions, and the
  order is unchanged (DAG-068 – DAG-072). Reachability uses bit rows over topological places,
  computed in reverse order.
- **`transitiveReduction()`** is NetworkX's `transitive_reduction`. It keeps u→w exactly when no
  path of two or more edges joins u to w. Of parallel copies it keeps the first, in `edges`
  order. It returns a new value: the vertices in `vertices` order, the kept edges in `edges`
  order at fresh positions (a stable base is compacted), and the same topological order
  (DAG-073 – DAG-077).
- **`longestPath()`** is NetworkX's `dag_longest_path` with unit weights. It walks the
  maintained order. Each vertex's best predecessor edge is the first in `inEdges` order that
  achieves the maximum, and the path ends at the first vertex in topological order with the
  greatest distance. That matches NetworkX given `topo_order=`, and the stress run checks it
  exactly (DAG-078 – DAG-083). Weighted DAG shortest and longest paths stay in ShortestPaths
  phase 2, as README plans. They take the DAG's order and so need no cycle check.

### Conformances

- **`Equatable` and `Hashable`** are the base's: the order is history and does not count
  (DAG-066, DAG-067). `LabeledGraph` likewise ignores its index assignment.
- **`Sendable`** when `Base` is.
- **`Codable`** when `Base` is, as `{base, order}`, with `order` as offsets into
  `base.vertices`, so a round trip keeps the order (DAG-084). Decoding re-checks the payload and
  throws `DecodingError.dataCorrupted` when the base has a cycle, the order is not a permutation,
  or an edge goes backward (DAG-085 – DAG-087). `DecodingError` carries no vertices, so it stays
  `Sendable`.
- **`CustomStringConvertible`** and `CustomDebugStringConvertible` (the debug form also lists the
  order).
- **`@DirectedGraphBuilder`**, through the failable initializer.

## Comparison

| | Grafluent (proposed) | JGraphT `DirectedAcyclicGraph` | petgraph `Acyclic<G>` | rustworkx `PyDiGraph(check_cycle=True)` |
|---|---|---|---|---|
| Algorithm | Pearce–Kelly | Pearce–Kelly (JEA 2007) | Pearce–Kelly | a reachability search per insert, no order kept |
| Base | generic `MutableDirectedGraph` (three in phase 1) | its own storage (`AbstractBaseGraph`) | generic `G` (`Graph`, `StableGraph`) | its own storage |
| On a cycle | returns `nil`; `bidirectionalShortestPath(from: v, to: u)` gives the path | throws `GraphCycleProhibitedException`, no witness | `Err(AcyclicEdgeError::Cycle(Cycle<N>))`, one node | raises `DAGWouldCycle`, no witness |
| Self-loop | rejected (`nil`) | rejected | `AcyclicEdgeError::SelfLoop` | **accepted when the source has no in-edges or the target no out-edges**: 990 of 1243 tried in `--stress` |
| Missing endpoint | `insert(edge:)` inserts it; `insert(safe:)` returns `nil` | `IllegalArgumentException` | `AcyclicEdgeError::InvalidEdge` | panics on an invalid index |
| Order exposed | `topologicalOrder` (random access), `topologicalPosition(of:)` | `iterator()` only | `nodes_iter()`, `range(..)`, `get_position`, `at_position` | none (`topological_sort` recomputes it) |
| Check without inserting | `!hasPath(from: target, to: source)`, pruned by the order | — | `is_valid_edge` | — |
| Vertex removal | O(n − position) shift, re-keys the swap move | yes | O(v) | yes |
| Ancestors and descendants | Traversal's | `getAncestors`, `getDescendants` | via `G` | `ancestors`, `descendants` |

petgraph's witness is a single node. Grafluent's is a full shortest path, from Traversal's
existing query, at the cost of a second search on failure only.

## Performance targets

Benchmarks against petgraph `Acyclic<StableDiGraph>::try_add_edge` (Rust, release) and JGraphT
`DirectedAcyclicGraph.addEdge` (JVM, warmed up), on the same instances:

| Instance | Target |
|---|---|
| Fast-path inserts (edges given in a topological order), n = 10⁵, m = 5·10⁵ | within 1.1× the bare base's `insert(edge:)`; ≥ petgraph's throughput |
| Pearce–Kelly's model: a random DAG with a hidden order, edges inserted in random order, n = 10⁴ – 10⁵, m = 2n – 10n | ≥ petgraph's and ≥ 2× JGraphT's inserts per second; no allocation once the scratch has grown |
| Random pairs with rejections (most inserts reject once the graph is dense) | ≥ petgraph's; a rejection allocates nothing |
| Adversarial: reverse a chain one edge at a time | O(n) per insert, no worse than petgraph |
| Index-space algorithms (components, Dijkstra, BFS layers) through the wrapper | within 1.05× the bare base |
| `remove(_:)` over 10% of vertices | the base's cost plus O(log n) per removal |

`--stress` also counts work for the algorithm choice, below.

## Decisions on the open questions

1. **Bases.** Constrain `Base: MutableDirectedGraph`, a new GraphProtocols protocol named after
   BGL's `MutableGraph` concept (directed, as `BidirectionalDirectedGraph` is BGL's
   `BidirectionalGraph`). It refines `BidirectionalDirectedGraph` and carries underscored
   key-space hooks. Phase-1 conformers: `AdjacencyList`, `DirectedPseudograph`,
   `StableDirectedGraph`. **Recommendation: adopt it.** It is the "same `base` protocol" open
   question 9 plans for every rule-adding wrapper (`DirectedMultigraph`, `Multigraph`,
   `BipartiteGraph`) and for attached maps on every mutable representation. It reverses the
   README sentence "The protocol has no mutation" only for the hooks a wrapper needs. The
   alternative, concrete overloads per base, triples the code and gives no generic `Base`.
2. **Online order.** **Pearce–Kelly.** The alternatives were Marchetti-Spaccamela–Nanni–Rohnert
   (MNR); Alpern et al.; Haeupler–Kavitha–Mathew–Sen–Tarjan two-way search (O(m^{3/2}) total);
   and Bender–Fineman–Gilbert–Tarjan (O(min(m^{1/2}, n^{2/3}) · m) total).
   - **Literature:** Pearce and Kelly's experiments (JEA 2006/2007) find PK fastest on sparse
     graphs, with MNR better only on dense ones. The bounds of Haeupler et al. and
     Bender–Fineman–Gilbert–Tarjan are amortized totals with larger constants and more
     structure (an ordered-list data structure or levels). No library ships them.
   - **Measured with `ref.py --stress`:** PK costs forward and backward edge visits plus
     δ log δ, and MNR costs forward visits plus the shifted region. On PK's model (a hidden-order
     DAG) PK does 9–94× less work. Representative counts: n = 5000 and m = 20000 gives 63,808
     for PK against 6,022,505 for MNR, and n = 1000 and m = 3000 gives 8,394 against 207,436.
     On random pairs, where most inserts reject, the two are within 0.8–1.2×.
   - **Precedent:** JGraphT, petgraph and Abseil's `GraphCycles` all use PK.
   - **Removals keep the order** (it stays topological), and the gap is closed. Over swap-remove
     bases the moved vertex is re-keyed and keeps its place.
3. **Insertion result.** **Decided (coordinator): `insert(edge:) -> Edges.Index?`**, `nil` when the
   edge would close a cycle; no `EdgeInsertion` type, because no library has that name. The
   witness for a rejected u→v is Traversal's `bidirectionalShortestPath(from: v, to: u)`, which
   costs a second search on failure only. Both inserts are `@discardableResult`, as every base's
   `insert(edge:)` is.
4. **DAG algorithms.**
   - **Phase 1:** `topologicalOrder` and `topologicalPosition`, order-pruned `hasPath`,
     `transitiveClosure()`, `transitiveReduction()`, and unweighted `longestPath()`.
   - **Already elsewhere:** `topologicalGenerations`, `lexicographicalTopologicalSort`,
     `descendants` and `ancestors` (Traversal), and dominators (Connectivity).
   - **Phase 2:** `allTopologicalSorts()`, a lazy Sequence (NetworkX `all_topological_sorts`,
     Knuth–Szwarcfiter); `antichains()` (NetworkX); weighted DAG shortest and longest paths
     (ShortestPaths, rustworkx `dag_weighted_longest_path`); `changeTarget` and `changeSource`;
     the matrix bases; a batch `insert(edges:)` that switches to a full Kahn rebuild when the
     batch is large; and an unchecked init from Connectivity's `Condensation`. Today
     `init?(condensation.graph)` costs O(n + m), so the GraphOperations row "always a
     `DirectedAcyclicGraph`" is met by conversion. The CSR result stays as Connectivity built it.
5. **`safe:`.** As on `StableDirectedGraph`. `insert(safe:)` returns `nil` and changes nothing
   when an endpoint is missing or the edge would close a cycle, a self-loop included
   (DAG-041 – DAG-045).
   `topologicalPosition(safe:)` and the six row lookups return `nil` for a non-vertex. Removal
   of an absent element returns `nil` or 0 and never traps.
6. **How algorithms see the DAG.** Forward every `DirectedGraph`, `BidirectionalDirectedGraph`
   and (conditionally) `SparselyIndexedDirectedGraph` requirement to the base, `@inlinable`,
   with the base's own associated types (`SuccessorIndices`, `OutEdges`). The `DirectedGraph`
   doc comment requires exactly this of a wrapper. Positions are the base's, so attached maps
   and side arrays keyed by position stay valid through the wrapper.

## Package changes (done)

- `DirectedAcyclicGraphModule` depends on `GraphProtocols` and `Walks` only. The conformances to
  `MutableDirectedGraph` need the bases' internals, so they live in `AdjacencyListModule`,
  `Multigraphs` and `StableGraphs`, beside their other conformances; the bulk order is Kahn's in
  key space, so `Traversal` is not needed.
- `MutableDirectedGraph` is in GraphProtocols.
- `scripts/modules.py` generates the BUILD files.
- The README Structures row no longer hedges ("such as Pearce–Kelly").
