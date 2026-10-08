# Connectivity test suite

`Connectivity` covers the directed half of the planned module: strong components (Tarjan),
weak components, strong and weak connectivity tests, condensation, attracting components,
dominator trees (Lengauer–Tarjan), dominance frontiers and post-dominator trees. Everything is
written once against `DirectedGraph` (post-dominators against `BidirectionalDirectedGraph`). The
suite uses only the public API and is self-contained per test; shared material is the fixtures,
the `Multigraph` test conformer and the seeded generator in `GrafluentTestSupport`.

## API under test

```swift
struct Components<Graph: DirectedGraph>: RandomAccessCollection, Equatable   // Element == ArraySlice<Vertex>
    func component(of: Vertex) -> Int                 // position in the collection, O(1)
    func component(ofIndex: Int) -> Int               // the same in index space
struct Condensation<Graph: DirectedGraph>
    let components: Components<Graph>
    let graph: CompressedSparseRow                    // vertex i is components[i]
struct DominatorTree<Graph: DirectedGraph>
    var root: Vertex
    func immediateDominator(of:) -> Vertex?           // nil for the root and unreachable vertices
    func dominators(of:) -> [Vertex]?                 // [v, idom(v), …, root]; nil if unreachable
    func strictDominators(of:) -> [Vertex]?
    func children(of:) -> ArraySlice<Vertex>          // in vertices order
    func dominates(_:_:) -> Bool                      // false when the second is unreachable
struct DominanceFrontiers<Graph: DirectedGraph>
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

## How tests pin orders

| Representation | What is exact |
|---|---|
| `AdjacencyMatrix`, `CompressedSparseRow` | Everything: component order, members, labels, condensation rows, attracting and weak components, `children(of:)`, frontiers (vertices and successors ascending, repeats collapsed) |
| `Multigraph` | Everything, in written order: listed vertices first, then endpoints by first appearance; successors in written order with repeats. The only exact host for `String` fixtures and vertices that are not `0..<n`. Ported 1-based graphs are written with vertices listed ascending and edges sorted |
| Conformer without indices (`DictionaryGraph`, private per file) | The same as a Multigraph with the same `vertices` and edge order |
| `AdjacencyList` | Partitions as sets, the reverse topological law, laws, and immediate dominators (unique, so exact everywhere); `children(of:)` and frontiers as sets. CN-144 pins everything exactly by comparing with a `Multigraph` written in the adjacency list's own `vertices` and `successors(of:)` order |

Expected values come from the catalog's independent reference (an iterative Tarjan,
Kosaraju–Sharir, union–find, brute-force, Cooper–Harvey–Kennedy and Lengauer–Tarjan dominators,
and Cytron's frontier definition), checked against NetworkX on every fixture in both orders and on
900 random graphs, and against Boost's own `correctIdoms`. Randomized tests write their oracles
inside the test.

## Files

| File | Covers |
|---|---|
| `StrongComponentsTests.swift` | §A – §E: strong components of every fixture (exact), in written order and on adjacency lists, graphs ported from NetworkX, petgraph, Boost, LEMON, gonum, JGraphT and rustworkx, the order guarantees, and the strong and weak connectivity tests and counts |
| `WeakComponentsTests.swift` | §F: weak components, their order, direction ignored, CSR without predecessors, strong refines weak |
| `CondensationTests.swift` | §G – §H: condensation rows and laws, attracting components and their law |
| `SelfLoopAndParallelEdgeTests.swift` | §I: parallel edges and self-loops on the Multigraph |
| `DominatorTests.swift` | §J – §M: immediate dominators (Boost's seven test sets, NetworkX, petgraph, fixtures), tree queries, dominance frontiers, post-dominators |
| `ConnectivityPropertyTests.swift` | §N: seeded random graphs through every representation against oracles written in each test |
| `ConnectivityStressTests.swift` | §O: 100 000-vertex paths, cycles, a lasso and CHK's quadratic family inside a `Task`; wide graphs; the real-world fixtures |
| `ConnectivityConformanceTests.swift` | §P: index-space dispatch, conformers without indices, existentials, value semantics, `Sendable`, equality, preconditions |
| `ConnectivityReferenceTests.swift` | Added after the critical review: an adjacency list after removals, exactly, against a multigraph written in its own order; post-dominators against brute force with and without indices; false `dominates` pairs on deep graphs |

## Case IDs

Case IDs (CN-01 … CN-146) refer to the catalog of cases harvested from NetworkX, petgraph, Boost,
JGraphT, LEMON, igraph (behaviour only), gonum and rustworkx. Each test's name starts with its IDs.

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
