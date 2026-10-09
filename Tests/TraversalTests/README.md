# Traversal test suite

`Traversal` is the first algorithm module: breadth-first and depth-first search as lazy event
sequences, reachability, shortest paths by edge count, topological sorting and cycle finding,
written once against `DirectedGraph` and searches over successor closures for state spaces that
are not finite graphs. The suite uses only the public API and is self-contained per test; shared
material is the fixtures and the `ReferenceDirectedMultigraph` test conformer in `GrafluentTestSupport`.

## API under test

```swift
enum BreadthFirstSearchEvent<Vertex>: discover, treeEdge, nonTreeEdge, finish        // Boost's names
enum DepthFirstSearchEvent<Vertex>: discover, treeEdge, backEdge, forwardEdge, crossEdge, finish   // CLRS

struct BreadthFirstSearch<Graph>: Sequence      // Iterator.prune(); forEach (push)
struct DepthFirstSearch<Graph>: Sequence        // Iterator.prune(); forEach (push); preorder, postorder

extension DirectedGraph
    func breadthFirstSearch(from: Vertex | some Sequence<Vertex>, depthLimit: Int? = nil)
    func depthFirstSearch(from: Vertex | some Sequence<Vertex>, depthLimit: Int? = nil)
    func depthFirstSearch(depthLimit: Int? = nil)                 // the whole graph
    func breadthFirstLayers(from:) -> [[Vertex]]                   // NetworkX bfs_layers
    func descendants(of:) -> Set<Vertex>
    func hasPath(from:to:) -> Bool
    func topologicalSort() -> [Vertex]?                            // DFS reverse postorder; nil on a cycle
    func topologicalGenerations() -> [[Vertex]]?                   // Kahn, NetworkX topological_generations
    func lexicographicalTopologicalSort(by:) -> [Vertex]?          // and without `by:` for Comparable vertices
    func findCycle() -> Cycle<Vertex, Edges.Index>?                // the first back edge's cycle
    func findCycle(from:) -> Cycle<Vertex, Edges.Index>?           // only cycles reachable from roots
    var isAcyclic: Bool
extension BidirectionalDirectedGraph
    func ancestors(of:) -> Set<Vertex>
    func bidirectionalShortestPath(from:to:) -> Path<Vertex, Edges.Index>?   // NetworkX's algorithm

func breadthFirstSearch(from:depthLimit:successors:) -> some Sequence<BreadthFirstSearchEvent<V>>
func depthFirstSearch(from:depthLimit:successors:) -> some Sequence<DepthFirstSearchEvent<V>>
func topologicalSort(from:successors:) -> [V]?
func iterativeDeepeningDepthFirstSearch(from:successors:until:) -> [V]?   // V: Equatable only; exponential worst case
```

Inside the package, `IndexSpaceSearch` (package access) is the engine under these: breadth-first
and depth-first search pushed to a visitor in index space, with discovery order, parents and depths
readable afterwards. It is what `Connectivity`, `Flows` and `ShortestPaths` will build on.

## Conventions

| Question | Choice | Why | Disagreement |
|---|---|---|---|
| Visitors or events | Event sequences, consumed by pulling (`for-in`, lazy, prunable) or pushing (`forEach`, one loop); no visitor protocol | Early exit is breaking the loop | Boost, LEMON and JGraphT use visitors or listeners; petgraph has both |
| Cost of events | Pulled events cost about 2.3× a hand-written breadth-first loop on CSR, pushed ones about 1.8×; depth-first, about 2.2× either way. The queries (`breadthFirstLayers`, `descendants`, `hasPath`) run dedicated loops at about 1.2× | Every edge becomes an event; laziness is not free | — |
| Pruning | `prune()` on the iterator, only right after a `discover` (anything else traps): out-edges skipped, `finish` still reported. The closure searches prune by returning fewer successors | Pruning after any other event has no clear meaning; petgraph panics after `Finish` | petgraph's `Prune` after an edge event skips the edge |
| Depth limit | Vertices at the limit are discovered and finished, their out-edges not reported. Depth-first, a vertex first reached deeper than the limit is not explored again from a shorter path | Every discovered vertex finishes, so preorder and postorder agree on the set | NetworkX's `dfs_postorder_nodes` drops vertices at the limit |
| Self-loops and parallel edges | A self-loop is a back edge (depth-first) or non-tree edge (breadth-first); every copy of an edge gets its own event; a repeated tree edge is a forward edge | CLRS; the protocol lists a successor once per edge | NetworkX's `MultiDiGraph` lists distinct successors |
| Recursion | None: depth-first search and iterative deepening keep their own stacks | A 100 000-vertex path must not overflow | petgraph's event-based `depth_first_search` is recursive |
| Iterative deepening | Only over a successor closure | It exists to save memory on state spaces; on a stored graph, breadth-first or bidirectional search is never worse, while iterative deepening is exponential on graphs with many routes (a 6×6 grid took 16 s) | — |
| Events | Exactly these cases, no `finishEdge` | Every consumer planned (strong components, cut vertices, flows) works from these; adding a case later is a breaking change, decided now | Boost has `finish_edge` |
| Free functions | `breadthFirstSearch(from:successors:)` and friends are hidden by the methods of the same name inside a `DirectedGraph` extension; call them as `Traversal.breadthFirstSearch` there | The names are the established ones | — |
| Per-vertex state | Arrays indexed in index space (`successorIndices`) when the graph has vertex indices; dictionaries otherwise | An adjacency list searched by hashing each neighbor is 3.5× slower | — |
| Cycles | Topological sorts return `nil`; `findCycle()` returns the witness, a Walks `Cycle` rotated to start at the back edge's target, its edges the search's tree edges and back edge (the first out-edge between consecutive vertices; WK-1202, WK-1203, WK-1214, WK-1215) | A thrown error must be `Sendable`, which would rule out non-`Sendable` vertices | petgraph returns `Err(Cycle(node))`, NetworkX raises |
| Paths | Walks' `Path`, its edges the first out-edge between consecutive vertices; `Path(vertex: s)` from `s` to itself (WK-1213). Tests compare `?.vertices` with an array literal, and `?.edges` where the copy taken matters | Paths and cycles carry their edges, which tell parallel copies apart | — |
| Order in tests | Exact transcripts on the matrix and CSR (ascending successors) and the `ReferenceDirectedMultigraph` (written order); order-independent assertions on `AdjacencyList` | The protocol fixes successor order per representation only | — |
| Lexicographic BFS | Deferred | It is an undirected algorithm (chordality); it lands with `Graph` | JGraphT refuses directed input |

## Files

| File | Covers |
|---|---|
| `SearchTranscriptTests.swift` | Exact event transcripts: breadth-first (Boost order) and depth-first (CLRS classes) on NetworkX, petgraph, LEMON, JGraphT and Boost graphs, multigraphs, self-loops, multiple sources and depth limits. Generated from the catalog once, then checked in |
| `SearchOrderTests.swift` | Layers, breadth-first trees, preorder and postorder, depth-limited orders, pruning, early exit |
| `TopologicalAndReachabilityTests.swift` | The three topological sorts, cycle witnesses, descendants and ancestors, `hasPath`, bidirectional search, iterative deepening, and the closure-based searches |
| `SearchReferenceTests.swift` | Transcripts on random graphs against a reference written in the test (recursive DFS, queue BFS), pulled and pushed, with and without vertex indices, with spread-out Int and String vertices, after vertex removals; topological, cycle and reachability answers against a reachability reference; `forEach` errors; deep closure searches; `findCycle(from:)` |
| `TraversalWalkReviewTests.swift` | Walks migration, after the review: `findCycle` and `bidirectionalShortestPath` without vertex indices, over parallel edges (with steps found by the backward search), and through a directed view's self-loop (WK-1216 – WK-1219) |
| `TraversalWalkTests.swift` | Walks migration: `findCycle` and `bidirectionalShortestPath` as `Cycle` and `Path`, rotation, parallel copies, self-loops, NetworkX's `find_cycle` answers as cycles of the graph or its undirected view |
| `SearchPropertyTests.swift` | Random graphs through every representation (shortest distances, parenthesis theorem, consistent classification, every edge once, back edge iff cycle, topological validity and minimality), real-world fixtures, deep and wide graphs, index-space dispatch, value semantics, preconditions |

Case IDs (TR-01 … TR-174) refer to the catalog of cases harvested from NetworkX, petgraph, Boost,
JGraphT, LEMON, igraph and the Rust `pathfinding` crate. Expected transcripts were computed by an
independent reference checked against NetworkX on every fixture. WK-1202 – WK-1205 and
WK-1213 – WK-1215 are the Walks catalog's migration cases (`Tests/WalksTests/README.md`), in
`TraversalWalkTests.swift`; the rest of that section is in ShortestPaths' suite.
