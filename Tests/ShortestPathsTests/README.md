# ShortestPaths test suite

`ShortestPaths`, phase 1: single-source shortest paths. Dijkstra (one or several sources, an
optional inclusive cutoff, a single-target query that stops when the target is settled),
Bellman–Ford with negative-cycle detection and a witness, A* with reopening, unweighted
(breadth-first) shortest paths, and the `ShortestPathTree` result. Everything is written once
against `DirectedGraph`, with forwarding overloads on `Graph` that read an undirected graph
through `directed`. The suite uses only the public API and is self-contained per test; shared
material is the fixtures, the `ReferenceDirectedMultigraph` and `ReferencePseudograph` test
conformers and the seeded generator in `GrafluentTestSupport`.

## API under test

```swift
struct ShortestPathTree<G: DirectedGraph, Distance: Comparable & AdditiveArithmetic>
        // Sendable where G, G.Vertex, G.Edges.Index and Distance are; not Equatable
    var sources: [G.Vertex]                            // in the order given, each once
    func distance(to:) -> Distance?                    // nil when unreached or beyond the cutoff
    func hasPath(to:) -> Bool
    func parent(of:) -> G.Vertex?                      // nil for a source and for an unreached vertex
    func parentEdge(of:) -> G.Edges.Index?             // the edge from parent(of:); tells parallel edges apart
    func path(to:) -> Path<G.Vertex, G.Edges.Index>?   // from a source; Path(vertex: s) for a source
    func distance(toIndex:) -> Distance?
    func parent(ofIndex:) -> Int?

extension DirectedGraph
    func shortestPaths(from: Vertex | some Sequence<Vertex>) -> ShortestPathTree<Self, Int>
    func dijkstraShortestPaths(from: Vertex | some Sequence<Vertex>, cutoff: W? = nil,
                               weight: (Edges.Index) -> W) -> ShortestPathTree<Self, W>
    func dijkstraShortestPath(from:to:weight:) -> (path: Path<Vertex, Edges.Index>, distance: W)?
    func aStarShortestPath(from:to:weight:heuristic: (Vertex) -> W) -> (path: Path<Vertex, Edges.Index>, distance: W)?
    func bellmanFordShortestPaths(from: Vertex | some Sequence<Vertex>, weight:) -> ShortestPathTree<Self, W>?
    func findNegativeCycle(from: Vertex | some Sequence<Vertex>, weight:) -> Cycle<Vertex, Edges.Index>?
    func findNegativeCycle(weight:) -> Cycle<Vertex, Edges.Index>?   // every vertex a source
extension Graph                                        // weight over the base's positions
    // the same methods, returning ShortestPathTree<DirectedView<Self>, W>, and paths and
    // cycles over DirectedView<Self>.Edges.Index (an arc: a position and its direction)
```

`W` is `Comparable & AdditiveArithmetic` throughout.

## Conventions

| Question | Choice | Why |
|---|---|---|
| Weights | A closure over edge positions, `(Edges.Index) -> W`, called only for examined edges (SP-42, SP-130). Tests keep weights in an array by position (ReferenceDirectedMultigraph, AdjacencyList, CompressedSparseRow through `edgeIndices:`), by cell (`AdjacencyMatrix`), or by `$0.position` (undirected through `directed`) | The only form that tells parallel edges apart and works on every representation |
| Unreached | `distance(to:) == nil`, `parent(of:) == nil`, `path(to:) == nil`; no infinity sentinel, so `Int` sums up to `Int.max` are exact (SP-37) and `Double.infinity` is an ordinary weight (SP-39) | Nothing is ever added to a sentinel |
| Negative weights in Dijkstra and A* | Trap on each examined edge, so an unexamined one never traps (SP-35, SP-36) | Boost's and gonum's rule |
| NaN, overflow | NaN weights trap in Dijkstra and A*; a NaN sum traps in Bellman–Ford (+∞ meeting −∞ included); overflow traps (SP-38, SP-40) | Swift's checked arithmetic is the guard |
| Ties | The first relaxation to the final distance wins; vertices at equal distance settle in an unspecified order | A documented tie order cost 7–64 % (PriorityQueue README) |
| Cutoff | Inclusive: reached iff the distance is at most the cutoff; a negative cutoff reaches only the sources (SP-25 – SP-27); a NaN cutoff traps (SP-137) | NetworkX `cutoff`, scipy `limit` |
| Several sources | Dijkstra and unweighted: each at distance 0 with no parent, even when reached from another (SP-24). Bellman–Ford: one super-source, so a source that another reaches by a negative path gets that distance and a parent (SP-133). A repeated source counts once | NetworkX's `multi_source_dijkstra` and `_bellman_ford` |
| Single target | Stops when the target is settled, not when first reached (SP-21) | NetworkX, LEMON |
| Negative cycles | `bellmanFordShortestPaths` returns `nil` exactly when one is reachable from a source; `findNegativeCycle` returns the witness | Traversal's `topologicalSort` / `findCycle` |
| Witness | A `Cycle` (Walks): distinct vertices, the first not repeated, rotated to start at its first vertex in `vertices` order, with Bellman–Ford's parent edges between them, so it is a cycle of the graph that weighs less than zero (SP-69a, WK-1212). A negative self-loop is `[v]` over that loop; an undirected negative edge `[u, v]` over its two arcs, `(p, r)` and `(p, !r)` (SP-63, SP-64, WK-1201) | Traversal's `findCycle()` |
| Zero-weight cycles | Not negative (SP-60) | Strict `<` |
| A* | Reopens a vertex whose distance improves, so an admissible heuristic gives a shortest path even when inconsistent (SP-71); an inadmissible one gives some path (SP-80); source == target returns `(Path(vertex: s), 0)` (SP-81); the target's own estimate is taken as zero, so a negative one (still admissible) cannot end the search early (SP-132) | Boost, NetworkX, JGraphT |
| Unweighted | Breadth-first, fully determined: first discovery in out-edge order (SP-86) | — |
| Undirected graphs | Through `directed`, each edge two arcs sharing its position; the `Graph` overloads take weights by the base position and return the view's tree, whose parent edges are `(position, reversed)` arcs (SP-92) | Traversal's precedent |
| Results | Values holding a copy of the graph: mutating the original afterwards changes nothing (SP-126) | Connectivity's `Components` |
| Index space | On an indexed adjacency list the algorithms hash only the source (and the target), not one vertex per step (SP-129) | Connectivity CN-136 |
| Preconditions | A source, target or query vertex that is not a vertex, an empty source sequence, and `distance(toIndex:)` / `parent(ofIndex:)` outside `0..<vertexIndexBound` trap; tested with exit tests | — |
| Paths and cycles | Paths are `Path` and witnesses `Cycle`, from `Walks`; both carry their edges, which tell parallel edges apart (SP-134, WK-1209, WK-1211). Tests compare `?.vertices` with an array literal where the old API returned `[Vertex]`, and `?.edges` where the edge taken is the point. The path to a source is `Path(vertex: s)` (WK-1207); a path weighs its distance (WK-1210) | Walks' `Path` and `Cycle`; `Cycle` equality is up to rotation |
| Undirected negative edges | Bellman–Ford and the negative-cycle search find a reachable negative edge in one O(V + E) pass and return `nil` or that edge as the witness, before any O(VE) search (SP-135) | Any reachable negative edge is a 2-cycle |

## How tests pin values

| What | How |
|---|---|
| Distances | Exact everywhere |
| Dijkstra and A* parents | Exact where the tie rule determines them: among the shortest-path predecessors of `v`, those with the smallest distance are one vertex `u`; the parent is then `u` and the parent edge `u`'s first such edge in `outEdges(of: u)` order. Elsewhere (SP-16, SP-18, SP-20) the test checks that the parent and its edge are a candidate pair. SP-104 checks the rule on random graphs |
| Bellman–Ford parents | Exact only where the shortest-path predecessor is unique, which holds in every Bellman–Ford case of §E; SP-59 compares parents only there |
| Unweighted parents | Exact |
| Witnesses | Exact where one simple negative cycle is reachable; otherwise the witness laws (SP-69a) |
| Representations | `AdjacencyMatrix`, `CompressedSparseRow` (ascending rows), `ReferenceDirectedMultigraph` (written order, the only host for parallel edges and for `String` and non-`0..<n` vertices with exact positions), `AdjacencyList` (positions in insertion order, so a list built from a written edge list without repeats has the written positions), `UndirectedAdjacencyList` and `ReferencePseudograph` (parallel edges) through `directed`, and a conformer without vertex indices (`DictionaryGraph`, private to `RepresentationTests.swift`) |

Expected values come from the catalog's independent reference (`ref.py`: a lazy-deletion Dijkstra
run with four tie orders, the tie rule computed from the distances, Bellman–Ford in LEMON's
active-vertex rounds with LEMON's witness walk, A* with reopening, breadth-first search and
Floyd–Warshall), checked against NetworkX and scipy, and from the ported suites' own expectations.
Randomized tests write their oracles inside the test (Floyd–Warshall, the tie rule, a queue
breadth-first search, Johnson's reweighting).

## Files

| File | Covers |
|---|---|
| `DijkstraBasicsTests.swift` | §A: the trivial cases, a path, NetworkX's XG from every source, Boost's example, JGraphT's tree, scipy's directed and undirected graphs, XG2, XG3 |
| `TiesAndMultigraphTests.swift` | §B: self-loops, parallel edges, NetworkX's multigraphs, zero weights, ties left open and ties decided by distance (every insertion order of an adjacency list) |
| `TargetSourcesAndCutoffTests.swift` | §C: the single-target query, several sources, the inclusive cutoff, scipy's `limit` |
| `WeightEdgeCaseTests.swift` | §D: negative weights (examined and not), sums at the limit, overflow, infinities and NaN, other weight types (`Double`, `Float`, `UInt8`, `Duration`, a user type), what the weight closure is asked |
| `BellmanFordTests.swift` | §E: CLRS 24.4, negative edges, JGraphT, petgraph and Boost graphs, undirected through `directed`, unreachable negative cycles, Bellman–Ford against Dijkstra, zero-weight cycles, every vertex a source |
| `NegativeCycleTests.swift` | §F: witnesses from every source, undirected 2-cycles, self-loops, barely negative cycles, cycles away from the source, ported examples, the whole-graph search, the witness laws |
| `AStarTests.swift` | §G: the zero heuristic, an inconsistent admissible heuristic, re-expansion, grids, several optimal paths, an inadmissible heuristic, source == target, negative weights |
| `UnweightedShortestPathTests.swift` | §H: first discovery, several sources, scipy's unweighted graph, agreement with unit-weight Dijkstra and Traversal's `breadthFirstLayers` |
| `RepresentationTests.swift` | §I: the same answers on every representation, matrix cells, the `Graph` overloads, `AdjacencyList.undirected.directed`, a conformer without indices, CSR's `edgeIndices:` |
| `ShortestPathPropertyTests.swift` | §J: seeded random graphs against oracles written in each test |
| `ShortestPathStressTests.swift` | §K: a 10⁶-vertex path, a 1000 × 1000 grid, long negative cycles, a lasso, a negative path, wide graphs, the real-world fixtures, inside a `Task` |
| `ShortestPathConformanceTests.swift` | §L: preconditions, index-space queries, value semantics, `Sendable`, existentials, index-space dispatch, lazy weight reads |
| `ShortestPathReviewTests.swift` | §M: the critical review's cases, with conformers without vertex indices (`PlainDigraph`, `PlainGraph`, private to the file) |
| `ShortestPathWalkReviewTests.swift` | Walks migration, after the review (WK-1220 – WK-1222) |
| `ShortestPathWalkTests.swift` | Walks migration: paths and witnesses as `Path` and `Cycle`, their edges between parallel copies and over undirected arcs, the trivial path, and the path and witness laws on random graphs |

## Case IDs

Case IDs (SP-01 … SP-137) refer to the catalog of cases (`Tests/Catalogs/ShortestPaths/cases.md`, with `ref.py` and the scripts that print each `.out`) harvested from Boost, NetworkX,
petgraph, JGraphT, LEMON, igraph (behaviour only), gonum, rustworkx and scipy. Each test's name
starts with its ID. WK-12nn cases are the Walks catalog's migration section (`Tests/WalksTests/README.md`); WK-1202 – WK-1205 and WK-1213 – WK-1215 are in Traversal's suite.

| Cases | Section | File |
|---|---|---|
| SP-01 – SP-11 | A. Dijkstra basics | `DijkstraBasicsTests.swift` |
| SP-12 – SP-20 | B. Ties, self-loops, parallel edges, zero weights | `TiesAndMultigraphTests.swift` |
| SP-21 – SP-27 | C. Single target, sources, cutoff | `TargetSourcesAndCutoffTests.swift` |
| SP-35 – SP-42 | D. Weight edge cases | `WeightEdgeCaseTests.swift` |
| SP-50 – SP-61 | E. Bellman–Ford distances | `BellmanFordTests.swift` |
| SP-62 – SP-69a | F. Negative cycles and witnesses | `NegativeCycleTests.swift` |
| SP-70 – SP-81 | G. A* | `AStarTests.swift` |
| SP-85 – SP-89 | H. Unweighted shortest paths | `UnweightedShortestPathTests.swift` |
| SP-90 – SP-95 | I. Representations and weight styles | `RepresentationTests.swift` |
| SP-100 – SP-109 | J. Properties | `ShortestPathPropertyTests.swift` |
| SP-115 – SP-121 | K. Stress | `ShortestPathStressTests.swift` |
| SP-125 – SP-130 | L. Preconditions, value semantics, dispatch | `ShortestPathConformanceTests.swift` |
| SP-131 | J. Properties with shrinking (PropertyBased) | `ShortestPathPropertyTests.swift` |
| SP-132 – SP-137 | M. Review cases: A*'s target estimate, Bellman–Ford's super-source, parallel edges in paths and witnesses, undirected negative edges with and without indices, the native undirected path, the NaN cutoff | `ShortestPathReviewTests.swift` |
| WK-1201, WK-1206 – WK-1212 | Walks catalog §12, migration: witnesses and paths as walks | `ShortestPathWalkTests.swift` |
| WK-1220 – WK-1222 | Walks migration, after the review: a source improved by another, undirected paths as arcs of the directed view, an undirected negative self-loop | `ShortestPathWalkReviewTests.swift` |
| SP-B01 – SP-B08 | Benchmarks | not tests; SP-115 and SP-116 assert only answers (and SP-115 that Bellman–Ford reads each weight about once on a path) |

Not tested here: the successor-closure entry points (`dijkstraShortestPath(from:successors:success:)`
and `aStarShortestPath(from:successors:heuristic:success:)`, catalog D19), deferred to a later
phase; and `bidirectionalShortestPath`, which stays in Traversal and is tested there.
