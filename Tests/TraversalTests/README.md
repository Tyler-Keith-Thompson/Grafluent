# Traversal test suite

Tests for `Traversal`: breadth-first and depth-first search as lazy event sequences, reachability,
shortest paths by edge count, topological sorting and cycle finding, written once against
`DirectedGraph`, and searches over successor closures for state spaces that are not finite graphs. The suite uses only the public API and is self-contained per test; shared
material is the fixtures and the `ReferenceDirectedMultigraph` test conformer in `GrafluentTestSupport`.

## API under test

```swift
enum BreadthFirstSearchEvent<Vertex>: discover, treeEdge, nonTreeEdge, finish
enum DepthFirstSearchEvent<Vertex>: discover, treeEdge, backEdge, forwardEdge, crossEdge, finish   // CLRS

struct BreadthFirstSearch<Graph>: Sequence      // Iterator.prune(); forEach (push)
struct DepthFirstSearch<Graph>: Sequence        // Iterator.prune(); forEach (push); preorder, postorder

extension DirectedGraph
    func breadthFirstSearch(from: Vertex | some Sequence<Vertex>, depthLimit: Int? = nil)
    func depthFirstSearch(from: Vertex | some Sequence<Vertex>, depthLimit: Int? = nil)
    func depthFirstSearch(depthLimit: Int? = nil)                 // the whole graph
    func breadthFirstLayers(from:) -> [[Vertex]]
    func breadthFirstTree(from:depthLimit:) -> Arborescence<Vertex> // discovery order
    func depthFirstTree(from:depthLimit:) -> Arborescence<Vertex>   // preorder
    func descendants(of:) -> Set<Vertex>
    func hasPath(from:to:) -> Bool
    func topologicalSort() -> [Vertex]?                            // DFS reverse postorder; nil on a cycle
    func topologicalGenerations() -> [[Vertex]]?                   // Kahn's algorithm
    func lexicographicalTopologicalSort(by:) -> [Vertex]?          // and without `by:` for Comparable vertices
    func findCycle() -> Cycle<Vertex, Edges.Index>?                // the first back edge's cycle
    func findCycle(from:) -> Cycle<Vertex, Edges.Index>?           // only cycles reachable from roots
    var isAcyclic: Bool
extension BidirectionalDirectedGraph
    func ancestors(of:) -> Set<Vertex>
    func bidirectionalShortestPath(from:to:) -> Path<Vertex, Edges.Index>?

enum EdgeBreadthFirstSearchEvent<Vertex, Edge>: discover, treeEdge, nonTreeEdge, finish   // edges by position
enum EdgeDepthFirstSearchEvent<Vertex, Edge>: discover, treeEdge, backEdge, forwardEdge, crossEdge, finish

struct EdgeBreadthFirstSearch<Graph>, EdgeDepthFirstSearch<Graph>: Sequence                  // Iterator.prune(); forEach (push)
struct UndirectedEdgeBreadthFirstSearch<Graph>, UndirectedEdgeDepthFirstSearch<Graph>: Sequence  // the same

extension DirectedGraph, Graph
    func edgeBreadthFirstSearch(from: Vertex | some Sequence<Vertex>, depthLimit: Int? = nil)
    func edgeDepthFirstSearch(from: Vertex | some Sequence<Vertex>, depthLimit: Int? = nil)
    func edgeDepthFirstSearch(depthLimit: Int? = nil)             // the whole graph

func breadthFirstSearch(from:depthLimit:successors:) -> some Sequence<BreadthFirstSearchEvent<V>>
func depthFirstSearch(from:depthLimit:successors:) -> some Sequence<DepthFirstSearchEvent<V>>
func topologicalSort(from:successors:) -> [V]?
func iterativeDeepeningDepthFirstSearch(from:successors:until:) -> [V]?   // V: Equatable only; exponential worst case
```

Inside the package, `IndexSpaceSearch` (package access) is the engine under these: breadth-first
and depth-first search pushed to a visitor in index space, with discovery order, parents and depths
readable afterwards. `Connectivity`, `Flows` and `ShortestPaths` build on it.

## Conventions

| Question | Rule |
|---|---|
| Visitors or events | Event sequences, consumed by pulling (`for-in`, lazy, prunable) or pushing (`forEach`, one loop); no visitor protocol. Early exit is breaking the loop |
| Pruning | `prune()` on the iterator, only right after a `discover` (anything else traps): out-edges skipped, `finish` still reported. The closure searches prune by returning fewer successors |
| Depth limit | Vertices at the limit are discovered and finished, their out-edges not reported, so preorder and postorder hold the same vertices. Depth-first, a vertex first reached deeper than the limit is not explored again from a shorter path |
| Self-loops and parallel edges | A self-loop is a back edge (depth-first) or non-tree edge (breadth-first); every copy of an edge gets its own event; a repeated tree edge is a forward edge |
| Recursion | None: depth-first search and iterative deepening keep their own stacks, so a 100 000-vertex path does not overflow |
| Iterative deepening | Only over a successor closure. On a stored graph, breadth-first or bidirectional search is never worse, and iterative deepening is exponential on graphs with many routes |
| Events | Exactly these cases, no `finishEdge` |
| Edge-position searches | `edgeBreadthFirstSearch` / `edgeDepthFirstSearch` report edges by position. Directed, the events are the endpoint search's, read through `source(ofEdgeAt:)` and `target(ofEdgeAt:)`. Undirected, each edge once, at the first row that reaches it: the tree edge is not reported again from below, a parallel edge to the parent is a back (non-tree) edge, a self-loop is reported once |
| Free functions | `breadthFirstSearch(from:successors:)` and friends are hidden by the methods of the same name inside a `DirectedGraph` extension; call them as `Traversal.breadthFirstSearch` there |
| Per-vertex state | Arrays indexed in index space (`successorIndices`) when the graph has vertex indices; dictionaries otherwise |
| Cycles | Topological sorts return `nil`; `findCycle()` returns the witness, a Walks `Cycle` rotated to start at the back edge's target, its edges the search's tree edges and back edge (the first out-edge between consecutive vertices; WK-1202, WK-1203, WK-1214, WK-1215) |
| Paths | Walks' `Path`, its edges the first out-edge between consecutive vertices; `Path(vertex: s)` from `s` to itself (WK-1213). Tests compare `?.vertices` with an array literal, and `?.edges` where the copy taken matters |
| Order in tests | Exact transcripts on the matrix and CSR (ascending successors) and the `ReferenceDirectedMultigraph` (written order); order-independent assertions on `AdjacencyList`, whose successor order is unspecified |

## Files

| File | Covers |
|---|---|
| `SearchTranscriptTests.swift` | Exact event transcripts: breadth-first and depth-first (CLRS classes) on the fixtures and small inline graphs, multigraphs, self-loops, multiple sources and depth limits. Generated from the catalog by `Tests/Catalogs/Traversal/gen.py`, which reproduces it byte for byte |
| `SearchTreeTests.swift` | `breadthFirstTree` and `depthFirstTree` as `Arborescence`: pinned trees, discovery order and tree edges against the searches on every fixture, depth limits, `String` vertices and `Int` vertices out of order, the preconditions |
| `SearchOrderTests.swift` | Layers, breadth-first trees, preorder and postorder, depth-limited orders, pruning, early exit |
| `TopologicalAndReachabilityTests.swift` | The three topological sorts, cycle witnesses, descendants and ancestors, `hasPath`, bidirectional search, iterative deepening, and the closure-based searches |
| `SearchReferenceTests.swift` | Transcripts on random graphs against a reference written in the test (recursive DFS, queue BFS), pulled and pushed, with and without vertex indices, with spread-out Int and String vertices, after vertex removals; topological, cycle and reachability answers against a reachability reference; `forEach` errors; deep closure searches; `findCycle(from:)` |
| `TraversalWalkReviewTests.swift` | `findCycle` and `bidirectionalShortestPath` without vertex indices, over parallel edges (with steps found by the backward search, WK-1217, and by the forward one, WK-1405), and through a directed view's self-loop (WK-1216 – WK-1219) |
| `TraversalWalkTests.swift` | `findCycle` and `bidirectionalShortestPath` as `Cycle` and `Path`, rotation, parallel copies, self-loops, cycles of a graph or of its undirected view |
| `SearchPropertyTests.swift` | Random graphs through every representation (shortest distances, parenthesis theorem, consistent classification, every edge once, back edge iff cycle, topological validity and minimality), real-world fixtures, deep and wide graphs, index-space dispatch, value semantics, preconditions |

Case IDs (TR-01 … TR-191) refer to the catalog of cases (`Tests/Catalogs/Traversal/cases.md`).
Expected transcripts were computed by an independent reference (`ref.py` there) checked against
NetworkX on every fixture (`check.py`). WK-1202 – WK-1205 and WK-1213 – WK-1215 are Walks catalog
cases (`Tests/WalksTests/README.md`), in `TraversalWalkTests.swift`; the rest of that section is in
ShortestPaths' suite.
