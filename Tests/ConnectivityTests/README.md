# Connectivity test suite

`Connectivity` has two halves. The directed half: strong components (Tarjan), weak components,
strong and weak connectivity tests, condensation, attracting components, dominator trees
(Lengauer–Tarjan), dominance frontiers and post-dominator trees, written once against
`DirectedGraph` (post-dominators against `BidirectionalDirectedGraph`). The undirected half, on
`Graph`: connected components, bridges, articulation points, biconnected components (blocks),
bi-edge-connected (2-edge-connected) components, the block–cut tree, and the predicates
`isConnected`, `hasBridges`, `isBiconnected` and `isBiEdgeConnected`; a bidirectional digraph
reaches it through `.undirected`. The undirected tests were written before the implementation,
from the proposed API. The suite uses only the public API and is self-contained per test; shared
material is the fixtures, the `ReferenceDirectedMultigraph` and `ReferencePseudograph` test
conformers and the seeded generator in `GrafluentTestSupport`.

## API under test

```swift
struct Components<G: DirectedGraph>: RandomAccessCollection, Equatable   // Element == ArraySlice<Vertex>
    func component(of: Vertex) -> Int                 // position in the collection, O(1)
    func component(ofIndex: Int) -> Int               // the same in index space
struct Condensation<G: DirectedGraph>
    let components: Components<G>
    let graph: CompressedSparseRow                    // vertex i is components[i]
struct DominatorTree<G: DirectedGraph>
    var root: Vertex
    func immediateDominator(of:) -> Vertex?           // nil for the root and unreachable vertices
    func dominators(of:) -> [Vertex]?                 // [v, idom(v), …, root]; nil if unreachable
    func strictDominators(of:) -> [Vertex]?
    func children(of:) -> ArraySlice<Vertex>          // in vertices order
    func dominates(_:_:) -> Bool                      // false when the second is unreachable
struct DominanceFrontiers<G: DirectedGraph>
    subscript(Vertex) -> ArraySlice<Vertex>?          // vertices order; nil if unreachable

extension DirectedGraph
    func stronglyConnectedComponents() -> Components<Self>
    var isStronglyConnected: Bool
    func weaklyConnectedComponents() -> Components<Self>
    var isWeaklyConnected: Bool
    func condensation() -> Condensation<Self>
    func attractingComponents() -> [[Vertex]]
    func dominatorTree(root:) -> DominatorTree<Self>
    func dominanceFrontiers(root:) -> DominanceFrontiers<Self>
extension BidirectionalDirectedGraph
    func postDominatorTree(exit:) -> DominatorTree<Self>
```

The undirected half:

```swift
struct BiconnectedComponents<G: Graph>: RandomAccessCollection, Equatable  // Element == ArraySlice<Edges.Index>, Index == Int
    func vertices(ofComponentAt: Int) -> ArraySlice<Vertex>      // vertices order
    func component(ofEdgeAt: Edges.Index) -> Int?                // nil for a self-loop
    func components(containing: Vertex) -> ArraySlice<Int>       // ascending; empty when none
struct BlockCutTree<G: Graph>: Equatable
    let blocks: BiconnectedComponents<G>
    let articulationPoints: [Vertex]                             // vertices order
    func articulationPoints(ofBlock: Int) -> ArraySlice<Int>     // places in articulationPoints, ascending
    func blocks(ofArticulationPoint: Int) -> ArraySlice<Int>     // block positions, ascending
    func node(of: Vertex) -> Node?                               // .articulationPoint(i), .block(b) or nil
    var edgeCount: Int
    enum Node: Hashable, Sendable { case block(Int), articulationPoint(Int) }

extension Graph
    func connectedComponents() -> Components<DirectedView<Self>>
    var isConnected: Bool
    func bridges() -> [Edges.Index]                              // ascending position
    var hasBridges: Bool
    func articulationPoints() -> [Vertex]                        // vertices order
    func biconnectedComponents() -> BiconnectedComponents<Self>
    var isBiconnected: Bool
    func biEdgeConnectedComponents() -> Components<DirectedView<Self>>
    var isBiEdgeConnected: Bool
    func blockCutTree() -> BlockCutTree<Self>
```

## Conventions

| Question | Choice | Why |
|---|---|---|
| Strong component order | Tarjan's completion order on a search with roots in `vertices` order and successors in `successors(of:)` order: every edge between components goes from a later component to an earlier one, so `reversed()` is a topological order of the condensation | NetworkX, petgraph and Boost give the same order; Kosaraju's differs (CN-37) and is only a test oracle here |
| Order inside a component | `vertices` order, never stack order | Independent of the algorithm; CN-09 pins it |
| Weak component order | By first vertex in `vertices` order, members in `vertices` order | NetworkX's order |
| Component slices | Indices are positions in flat storage: `components[1].first` is right, `components[1][0]` is not | As `CompressedSparseRow.successors(of:)`; CN-44 |
| Empty graph | Neither strongly nor weakly connected | Then `isStronglyConnected == (count == 1)` for every graph (igraph, JGraphT) |
| Condensation | Rows ascending, no repeats, no self-loops; edges go from higher to lower vertices | Boost, petgraph `make_acyclic`, NetworkX |
| Self-loops and parallel edges | Never change a partition, never become condensation edges, never stop a component attracting; a self-loop on a join point puts it in its own frontier | Definitions |
| Unreachable vertices | No immediate dominator, `dominators(of:)` and frontier `nil`, no children, never dominated | petgraph, NetworkX; LLVM's `dominates` is vacuously true instead |
| Post-dominators on CSR | Not available: CSR has no predecessors. Call `CompressedSparseRow.transposed().dominatorTree(root:)` (CN-113) | — |
| Post-dominance frontiers | Not shipped, so CN-112 has no test | — |
| Index order | With vertex indices, `vertex(atIndex: 0..<vertexIndexBound)` lists `vertices` in order, so the algorithms never hash vertices on an indexed adjacency list (CN-136, CN-138) | — |
| Results | Values holding a copy of the graph; `Sendable` when the graph and vertex are; `Components ==` compares members and offsets, not the graph | — |
| Preconditions | A root, exit or query vertex that is not a vertex traps, as does `component(ofIndex:)` outside `0..<vertexIndexBound` or on a graph without indices; tested with exit tests | — |

The undirected half's conventions (api.md, "Conventions" and "Orders"):

| Question | Choice | Why |
|---|---|---|
| Orders | Every order is canonical, independent of the search: components and 2-edge-connected components by first vertex in `vertices` order, members in `vertices` order (as weak components); bridges by ascending position; articulation points in `vertices` order; blocks by their smallest edge position, edges ascending, vertices in `vertices` order; block–cut tree adjacency ascending on both sides | So every representation is pinned exactly; the search's completion order (Boost, NetworkX, igraph) differs between libraries (CN-319) |
| Empty graph | Not connected, not biconnected, not bi-edge-connected; nothing found (CN-200) | igraph, JGraphT; the directed half's choice, so `isConnected == (connectedComponents().count == 1)` |
| K₁, K₂ | K₁ is connected but neither biconnected nor bi-edge-connected, in no block; K₂ is biconnected, its edge a bridge (CN-201, CN-203) | NetworkX, igraph, JGraphT |
| Isolated vertices | Their own connected and 2-edge-connected component, in no block, no block–cut tree node; a block plus an isolated vertex is not biconnected (CN-269, CN-330) | All the libraries |
| Parallel edges | Edges with identity: a parallel pair is never a bridge and both copies share a block; they never change articulation points (CN-281, CN-361). The search skips the parent edge, not the parent vertex (CN-291, CN-292) | igraph, LEMON; NetworkX, rustworkx and Boost differ |
| Self-loops | Never a bridge, never make an articulation point, in no block: `component(ofEdgeAt:)` is `nil` (CN-280, CN-284 – CN-289) | igraph; LEMON makes a loop a block |
| `.undirected` on a digraph | Each arc an edge, so opposite arcs are parallel and never bridges (CN-296) | JGraphT `AsUndirectedGraph` |
| `isBiconnected`, `isBiEdgeConnected` | n ≥ 2, connected, and no articulation point (no bridge); not "one block", which isolated vertices break | NetworkX, igraph, JGraphT |
| Results | `connectedComponents()` and `biEdgeConnectedComponents()` are `Components<DirectedView<Self>>`, `==` to `directed.weaklyConnectedComponents()` for the former (CN-360, CN-398); the results hold a copy of the graph; `==` compares blocks, their vertices and the tree in order, not the graph | api.md |
| Index space | On an indexed `UndirectedAdjacencyList` no entry point hashes a vertex; queries hash only their argument (CN-395) | As the directed half |
| Preconditions | A query vertex or edge position not in the graph, and every position out of range, trap; tested with exit tests (CN-390 – CN-392) | — |

## How tests pin orders

| Representation | What is exact |
|---|---|
| `AdjacencyMatrix`, `CompressedSparseRow` | Everything: component order, members, labels, condensation rows, attracting and weak components, `children(of:)`, frontiers (vertices and successors ascending, repeats collapsed) |
| `ReferenceDirectedMultigraph` | Everything, in written order: listed vertices first, then endpoints by first appearance; successors in written order with repeats. The only exact host for `String` fixtures and vertices that are not `0..<n`. Ported 1-based graphs are written with vertices listed ascending and edges sorted |
| Conformer without indices (`DictionaryGraph`, private per file) | The same as a ReferenceDirectedMultigraph with the same `vertices` and edge order |
| `AdjacencyList` | Partitions as sets, the reverse topological law, laws, and immediate dominators (unique, so exact everywhere); `children(of:)` and frontiers as sets. CN-144 pins everything exactly by comparing with a `ReferenceDirectedMultigraph` written in the adjacency list's own `vertices` and `successors(of:)` order |

For the undirected half, every test in §A – §G runs on the `ReferencePseudograph` written as the
catalog writes the graph (listed vertices first, then endpoints by first appearance; edges in
written order, repeats and loops kept), and on an `UndirectedAdjacencyList` built in the same order
when no edge repeats, so positions and vertices order are the written ones and every value is
exact: components, bridges, articulation points, blocks with their vertices, each edge's block,
each vertex's blocks and node, 2-edge-connected components, the block–cut tree's adjacency and the
predicates. Rows with repeats collapse on the adjacency list and are pinned there by CN-341.
`AdjacencyList.undirected` (arcs as edges), `AdjacencyMatrix.undirected` (positions are cells,
no edge indices) and two conformers private to `UndirectedRepresentationTests.swift` (`PlainGraph`
without indices, `VertexIndexedGraph` with vertex indices only) are exact too (§H).

Expected values come from the catalog's independent reference (an iterative Tarjan,
Kosaraju–Sharir, union–find, brute-force, Cooper–Harvey–Kennedy and Lengauer–Tarjan dominators,
and Cytron's frontier definition), checked against NetworkX on every fixture in both orders and on
900 random graphs, and against Boost's own `correctIdoms`. The undirected half's reference
(`ref.py`) is brute force from the definitions (vertex and edge removal, far-end connectivity in
G − w for blocks, every single-edge removal for 2-edge-connected components) and an iterative
Hopcroft–Tarjan that skips the parent edge, which agree on every row and on 1900 random
multigraphs, cross-checked against NetworkX 3.7. The test files for §A – §G were generated from
the catalog with those values and hold them as plain literals.
Randomized tests write their oracles inside the test.

## Files

| File | Covers |
|---|---|
| `StrongComponentsTests.swift` | §A – §E: strong components of every fixture (exact), in written order and on adjacency lists, graphs ported from NetworkX, petgraph, Boost, LEMON, gonum, JGraphT and rustworkx, the order guarantees, and the strong and weak connectivity tests and counts |
| `WeakComponentsTests.swift` | §F: weak components, their order, direction ignored, CSR without predecessors, strong refines weak |
| `CondensationTests.swift` | §G – §H: condensation rows and laws, attracting components and their law |
| `SelfLoopAndParallelEdgeTests.swift` | §I: parallel edges and self-loops on the ReferenceDirectedMultigraph |
| `DominatorTests.swift` | §J – §M: immediate dominators (Boost's seven test sets, NetworkX, petgraph, fixtures), tree queries, dominance frontiers, post-dominators |
| `ConnectivityPropertyTests.swift` | §N: seeded random graphs through every representation against oracles written in each test |
| `ConnectivityStressTests.swift` | §O: 100 000-vertex paths, cycles, a lasso and CHK's quadratic family inside a `Task`; wide graphs; the real-world fixtures |
| `ConnectivityConformanceTests.swift` | §P: index-space dispatch, conformers without indices, existentials, value semantics, `Sendable`, equality, preconditions |
| `ConnectivityReferenceTests.swift` | Added after the critical review: an adjacency list after removals, exactly, against a multigraph written in its own order; post-dominators against brute force with and without indices; false `dominates` pairs on deep graphs |
| `UndirectedComponentsTests.swift` | §A: the empty graph, K₁, K₂, isolated vertices and small graphs from NetworkX, petgraph, rustworkx, Boost and LEMON, every entry point exact |
| `BridgeTests.swift` | §B: bridges and 2-edge-connected components from NetworkX, igraph, rustworkx and JGraphT, multiedges included |
| `BiconnectedComponentTests.swift` | §C: articulation points, blocks and the block–cut tree from NetworkX, JGraphT, petgraph, Boost, igraph, rustworkx and LEMON |
| `UndirectedSelfLoopAndParallelEdgeTests.swift` | §D: parallel edges (the parent edge, not the parent vertex) and self-loops (in no block), a digraph through `.undirected` |
| `UndirectedFamilyTests.swift` | §E: paths, cycles, stars, complete and complete bipartite graphs, grids, wheels, chains of blocks, the canonical block order |
| `UndirectedFixtureTests.swift` | §F: the named `UndirectedFixture` graphs |
| `UndirectedDisconnectedTests.swift` | §G: isolated vertices, loop-only components, interleaved components, gap4 as written |
| `UndirectedRepresentationTests.swift` | §H: collapsed rows on `UndirectedAdjacencyList`, `AdjacencyList.undirected`, `AdjacencyMatrix.undirected`, conformers without indices and with vertex indices only, an adjacency list after removals, `Collider` vertices |
| `UndirectedConnectivityPropertyTests.swift` | §I: seeded random multigraphs with loops against oracles written in each test (removal, far-end connectivity, single-edge removals, the block–cut forest, invariances), Boost's G(100, 500), a PropertyBased check that shrinks, and `hasBridges`'s early exit on a row-counting conformer |
| `UndirectedConnectivityStressTests.swift` | §J: deep paths, a cycle, a doubled path, a star, a grid, K₃₀₀, a lasso and a triangle chain inside a `Task`; the real-world fixtures read as undirected graphs |
| `UndirectedConnectivityReviewTests.swift` | §L: added after the critical review: a conformer with edge indices but no vertex indices (file-private), `UndirectedAdjacencyList` after mutations that repack its rows, and index rows that break the laws trapping |
| `UndirectedConnectivityConformanceTests.swift` | §K: self-loop queries, value semantics, `Sendable`, equality, index-space dispatch, generic code and existentials, digraphs through `.undirected`, the `Components` result type, determinism, preconditions |

## Case IDs

Case IDs (CN-01 … CN-146 for the directed half, CN-200 … CN-404 for the undirected half) refer to
the catalogs of cases harvested from NetworkX, petgraph, Boost, JGraphT, LEMON, igraph (behaviour
only), gonum and rustworkx. Each test's name starts with its IDs.

| Cases | Section | File |
|---|---|---|
| CN-01 – CN-16 | A. Strong components on the fixtures | `StrongComponentsTests.swift` |
| CN-17 – CN-22 | B. Written order and adjacency lists | `StrongComponentsTests.swift` |
| CN-23 – CN-38 | C. Ported cases | `StrongComponentsTests.swift` |
| CN-39 – CN-45 | D. Order guarantees and invariances | `StrongComponentsTests.swift` |
| CN-46 – CN-50 | E. Connectivity tests and counts | `StrongComponentsTests.swift` |
| CN-51 – CN-57 | F. Weak components | `WeakComponentsTests.swift` |
| CN-58 – CN-67 | G. Condensation | `CondensationTests.swift` |
| CN-68 – CN-72 | H. Attracting components | `CondensationTests.swift` |
| CN-73 – CN-76 | I. Multigraphs and self-loops | `SelfLoopAndParallelEdgeTests.swift` |
| CN-77 – CN-93 | J. Immediate dominators | `DominatorTests.swift` |
| CN-94 – CN-98 | K. Dominator tree queries | `DominatorTests.swift` |
| CN-99 – CN-108 | L. Dominance frontiers | `DominatorTests.swift` |
| CN-109 – CN-111 | M. Post-dominators | `DominatorTests.swift` |
| CN-112 | Post-dominance frontiers | not tested: not shipped |
| CN-113 | Post-dominators on CSR | this README (compile-time note above) |
| CN-114 – CN-126 | N. Properties | `ConnectivityPropertyTests.swift` |
| CN-127 – CN-135 | O. Stress and real-world fixtures | `ConnectivityStressTests.swift` |
| CN-136 – CN-143 | P. Dispatch, existentials, value semantics, preconditions | `ConnectivityConformanceTests.swift` |
| CN-144 – CN-146 | Review additions: slots that moved, post-dominators by brute force, deep `dominates` | `ConnectivityReferenceTests.swift` |
| CN-B01 – CN-B07 | Benchmarks | not tests; CN-130 asserts only the answer, its time is CN-B05's |
| CN-200 – CN-219 | A. Undirected basics | `UndirectedComponentsTests.swift` |
| CN-220 – CN-234 | B. Bridges and 2-edge-connected components | `BridgeTests.swift` |
| CN-235 – CN-279 | C. Articulation points and blocks | `BiconnectedComponentTests.swift` |
| CN-280 – CN-299 | D. Parallel edges and self-loops | `UndirectedSelfLoopAndParallelEdgeTests.swift` |
| CN-300 – CN-319 | E. Forests, paths, cycles, complete graphs | `UndirectedFamilyTests.swift` |
| CN-320 – CN-329 | F. Named fixtures | `UndirectedFixtureTests.swift` |
| CN-330 – CN-339 | G. Disconnected graphs | `UndirectedDisconnectedTests.swift` |
| CN-340, CN-341 | Every row on the `ReferencePseudograph` and the `UndirectedAdjacencyList` | every test in §A – §G; CN-341's collapsed rows in `UndirectedRepresentationTests.swift` |
| CN-342 – CN-349 | H. Representations | `UndirectedRepresentationTests.swift` |
| CN-350 – CN-369 | I. Properties | `UndirectedConnectivityPropertyTests.swift` |
| CN-367 | Agreement with NetworkX | not a Swift test: `ref.py` checks every row and random graph against NetworkX 3.7 |
| CN-370 – CN-382 | J. Stress and real-world fixtures | `UndirectedConnectivityStressTests.swift`, at half the catalog's sizes or less (a 50 000-vertex path, cycle and star, a 25 000-vertex doubled path and lasso, a 150 × 150 grid, 15 000 triangles) to keep each test well under two seconds in a debug build; the benchmarks run 10⁶ |
| CN-400 – CN-404 | L. Review cases | `UndirectedConnectivityReviewTests.swift` |
| CN-390 – CN-399 | K. Preconditions and conformance | `UndirectedConnectivityConformanceTests.swift`; CN-397's "nothing on `DirectedGraph`" is an absence, so only the `.undirected` route is tested |
| CN-B10 – CN-B14 | Undirected benchmarks | not tests |
