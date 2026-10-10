# BipartiteGraphs test suite

`BipartiteGraphs` has the structure and the recognition algorithms for bipartite graphs:
`BipartiteGraph<Vertex>`, a simple undirected graph whose two sides are part of the value (each
vertex inserted on a side and kept there, every edge across, stored left endpoint first), built on
`UndirectedAdjacencyList` and mutable like it; `isBipartite`, `bipartition()` and `findOddCycle()`
on any `Graph`; and `projectedGraph(onto:)`. The tests were written before the implementation, from
the proposed API (`api.md` in [`Tests/Catalogs/BipartiteGraphs/`](../Catalogs/BipartiteGraphs/), phase 1, with the open questions decided: `BipartiteGraph` is simple,
`insert(edge:)` traps on a same-side edge with no non-trapping variant, no `density`, no
`isBipartition(left:)`, recognition on `Graph` only, no side-local indices, no moving a vertex
between sides). The suite uses only the public API, and each test is self-contained. The shared
material is the `ReferencePseudograph` test conformer, the seeded generator and the tags in
`GrafluentTestSupport`. A conformer private to a file models what the package does not have: a
graph with no vertex or edge indices.

## API under test

```swift
enum BipartiteSide: Hashable, Sendable, CaseIterable, Codable, CustomStringConvertible { case left, right }

struct BipartiteGraph<Vertex: Hashable>: Graph, Hashable, Codable (Vertex: Codable), Sendable (Vertex: Sendable),
                                         CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable
    init(), init?(left:right:), init?(left:right:edges:)          // nil: overlapping sides, an edge inside a side or off both
    init?(_ graph: some Graph<Vertex>)                             // canonical sides; nil exactly when graph.findOddCycle() != nil
    init?(_ graph: some Graph<Vertex>, left: some Sequence<Vertex>)// nil: an edge not across, or a non-vertex in left
    var left: SideVertices, right: SideVertices                    // RandomAccessCollection, Int indices from 0, a value
    func side(of:) -> BipartiteSide                                // traps on a non-vertex
    insert(_:on:), insert(edge:)                                   // trap: other side; endpoints missing or on one side
    remove(_:), remove(edge:), removeAll(keepingCapacity:), removeAllEdges(keepingCapacity:), reserveCapacity(vertexCount:edgeCount:)
    func projectedGraph(onto: BipartiteSide) -> UndirectedAdjacencyList<Vertex>

extension Graph {
    var isBipartite: Bool
    func bipartition() -> Bipartition<Self>?                       // each component's least vertex left
    func findOddCycle() -> Cycle<Vertex, Edges.Index>?             // first BFS conflict, Cycles' canonical form
}
struct Bipartition<G: Graph>: Equatable, CustomStringConvertible  // left, right (ArraySlice), side(of:), side(ofIndex:); Sendable when G and G.Vertex are
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Canonical sides | In each connected component the least vertex number (vertex index, or position in `vertices`) is left and the rest alternate, so isolated vertices are left; each side in `vertices` order | BP-001 – BP-084, BP-085 – BP-092, `RecognitionPropertyTests.swift` |
| Self-loops and parallel edges | A loop is an odd cycle of length 1; parallel edges do not affect bipartiteness, and the witness uses one copy | BP-007 – BP-014, BP-073 |
| The odd cycle | The first conflict of a breadth-first two-colouring (roots in vertex-number order, rows in `incidentEdges` order), closed through the lowest common ancestor, rotated to its least vertex number and turned to leave through the lesser edge; not necessarily a shortest one | every non-bipartite row, BP-052, `exactCycle` |
| Directed input | Through `.undirected`: rows are successors, then predecessors; a 2-cycle is a parallel pair | BP-069 – BP-074 |
| `BipartiteGraph(graph)` | The graph's vertex order; edges in position order (so, without parallel edges, at the graph's positions), each repeat dropped; stored left endpoint first | BP-085 – BP-092 |
| `BipartiteGraph(graph, left:)` | Repeats in `left` are one vertex; a non-vertex gives nil; each component either way | BP-093 – BP-104 |
| `BipartiteGraph(left:right:edges:)` | `left` then `right` in `vertices` order, repeats within a side dropped; endpoints are never inserted implicitly | BP-105 – BP-118 |
| Removal | The last slot moves into the hole (as in `UndirectedAdjacencyList`), and the side's last vertex into its place in `left` or `right`; the last edge into a removed edge's position | BP-124 – BP-139 |
| Equality | Vertex sets, edge sets and each vertex's side; not orders or orientations | BP-162 – BP-166 |
| Projection | The side's vertices in side order; {u, x} once when they share a neighbour, inserted in discovery order (u in side order, w in u's row, x ≠ u in w's row), oriented (u, x) | BP-150 – BP-161 |

## How values are pinned

Every catalog row is written as the catalog writes it: recognition rows on `ReferencePseudograph`
with the listed vertices and the edges in written order (rows in position order, a self-loop's
position twice, parallel edges kept), so every vertex number and edge position is exact; `digraph`
rows on `AdjacencyList` read through `.undirected`; the `BipartiteGraph` rows through the
initializers named in the row. The catalog-row files (`RecognitionTests.swift`,
`RecognitionRepresentationTests.swift`, `BipartiteGraphFromGraphTests.swift`,
`BipartiteGraphSideInitializerTests.swift`, `BipartiteGraphMutationTests.swift`,
`BipartiteGraphPreconditionTests.swift` except its last two tests, `ProjectionTests.swift`,
`BipartiteGraphEqualityTests.swift`) were generated from `cases.md` by a script (`swiftgen.py`, next to `ref.py` and `cases.md` in [`Tests/Catalogs/BipartiteGraphs/`](../Catalogs/BipartiteGraphs/), which says how to
run it). It first checks that `ref.py` reproduces `cases.md` exactly, then re-evaluates each row
with `ref.py`'s model functions, asserts the value matches the catalog cell, and writes it out.
Odd-cycle rows assert the exact cycle (vertices and edge positions) and its validity: odd length,
no repeated vertex or edge, each edge joining consecutive vertices, and
`Cycle(vertices:edges:in:)` not nil. Bipartite rows assert both sides, `side(of:)` for every
vertex, `side(ofIndex:)` against `side(of:)`, every edge across, and `BipartiteGraph(graph)` with the
same sides. `BipartiteGraph` rows compare edges as `[u, v]`, since `UndirectedEdge` equality ignores
orientation and the left endpoint must come first. BP-141 writes `ref.py`'s `random_ops(7)` out
literally, with every intermediate result as the model gives it.

In `RecognitionRepresentationTests.swift` each recognition row runs again on
`UndirectedAdjacencyList` (stored rows, so recognition goes through `_withIncidentIndexRows`) and on
the unindexed conformer, both with the catalog's values; on `AdjacencyList.undirected` with each
edge as an arc as written; and on `AdjacencyMatrix.undirected` for rows on `0..<n` with no arc
twice. Through `.undirected` a row is successors then predecessors, and the matrix's arcs sit at
row-major cells, so the cycle met first can differ: `swiftgen.py` computed those expected values
with `ref.py`'s model on that representation's rows (the sides do not depend on row order). Matrix
positions are compared as `[source, target]`.

The laws, conformance, property and stress files compute their expectations inside each test:
the expected rows from the graph's own `edges`, brute force over every two-colouring, union–find
components, a model of sides and edges, the projection's definition, api.md's breadth-first search
written out over the graph's public rows, and closed forms. The grid's odd cycle at 300 × 300
generalizes BP-039 and was also computed with `ref.py`'s model.

The whole suite was run against a Swift model of the API (a port of `ref.py`'s `BG`, `two_color` and
`normalize_cycle` over the real `UndirectedAdjacencyList`, `Cycle` and representations) before the
implementation existed, compiled with warnings as errors; it passes in about 5 seconds in a debug
build. It was also run against 21 planted bugs in that model, each of which fails tests (count of
failing tests in parentheses): rows read in reverse (32), components rooted from the last vertex
(107), isolated vertices put right (21), the cycle not rotated to its least vertex (9), the cycle
not turned to its lesser edge (9), self-loops ignored by `isBipartite` (11), overlapping sides
accepted (1), a non-vertex in `left:` ignored (2), edges not swapped to put the left endpoint first
(22), `insert(_:on:)` accepting the other side (1), `insert(edge:)` accepting a same-side edge (3),
sides ignored by `==` (3), a hash that ignores the edges (1), decoding accepting overlapping sides
(1) or a same-side edge (1), self-loops in projections (13), sides listed in breadth-first order
instead of `vertices` order (31), the cycle closed through the root instead of the lowest common
ancestor (12), `BipartiteGraph(graph)` inserting edges in reverse (7), `insert(edge:)` returning the
edge as given instead of as stored (5), and the moved slot not renamed after a vertex removal
(crashes the run on a stale side entry).

## Files

| File | Tests | Covers |
|---|---|---|
| `RecognitionTests.swift` | 84 | §Recognition, BP-001 – BP-084: the empty graph, K₁, isolated vertices, orientation and vertex order, loops, parallel edges, paths, cycles C₃ – C₉, K₄, K₅, stars, Kₘ,ₙ, grids, Q₃, Petersen, wheels, bowtie, theta graphs, chords, the C₅ met before a triangle, disconnected graphs, `String` vertices, Möbius ladders, prism, subdivided cubes, deep odd cycles, digraphs through `.undirected`, seeded random graphs |
| `RecognitionRepresentationTests.swift` | 84 | Every recognition row again on `UndirectedAdjacencyList`, a conformer with no indices, `AdjacencyList.undirected` and `AdjacencyMatrix.undirected` |
| `BipartiteGraphFromGraphTests.swift` | 20 | BP-085 – BP-104: `BipartiteGraph(graph)` and `BipartiteGraph(graph, left:)`, on `ReferencePseudograph` and (without parallel edges) `UndirectedAdjacencyList` |
| `BipartiteGraphSideInitializerTests.swift` | 14 | BP-105 – BP-118: `BipartiteGraph(left:right:)` and `(left:right:edges:)` |
| `BipartiteGraphMutationTests.swift` | 23 | BP-119 – BP-141: insertions, removals, slot and side-list moves, re-insertion on the other side, `side(of:)` after moves, projection after mutation, the seeded 37-operation sequence |
| `BipartiteGraphPreconditionTests.swift` | 10 | Exit tests: BP-142 – BP-149; then `side(of:)` and `insert(edge:)` on the empty graph, `Bipartition.side(of:)` on a non-vertex and `side(ofIndex:)` out of range |
| `ProjectionTests.swift` | 12 | BP-150 – BP-161: `projectedGraph(onto:)` |
| `BipartiteGraphEqualityTests.swift` | 5 | BP-162 – BP-166: equality and hashing |
| `BipartiteGraphLawTests.swift` | 3 | `Graph`'s laws (counts, index maps, rows against `edges`, `oppositeVertex`, degrees, `contains(edge:)`, edge indices, `_withIncidentIndexRows` read back against the index-space rows) and the side invariant on seven graphs, fresh and after removals; generic code; stored sides that are not the canonical ones |
| `BipartiteGraphConformanceTests.swift` | 9 | Codable round trips (JSON, property lists; orders and positions kept), invalid payloads throwing `dataCorrupted` or another error but never trapping, Hashable (orders ignored, edges and sides seen), `Sendable` across a `Task`, descriptions (16-item limit, `String` vertices), `SideVertices` as a value, copy-on-write, capacity calls, `BipartiteSide` |
| `BipartitionTests.swift` | 6 | `Bipartition` equality and description, the copy of the graph it holds, generic code, `CompressedSparseRow` through `AdjacencyList(csr).undirected`, `graph.directed.undirected` (every edge a parallel pair), closed forms on paths, cycles, Kₙ and Kₐ,ₙ₋ₐ for n ≤ 9 |
| `RecognitionPropertyTests.swift` | 2 | PropertyBased, shrinking, multigraphs with loops in shuffled vertex orders on both kinds of rows: the four equivalences and the canonical sides against brute force over every two-colouring, `BipartiteGraph(g)`'s edges and orientation, `left:` with random subsets and a non-vertex, the swapped sides, odd-cycle validity and canonical form; the exact cycle against api.md's search written out |
| `BipartiteGraphPropertyTests.swift` | 2 | PropertyBased, shrinking: random operation sequences against a model of sides and edges (results, sets, sides, orientation, index rows, equality and hash with a rebuilt graph after every step; Codable and the initializers from a graph at the end); projections after random removals against the definition and the documented order |
| `BipartiteStressTests.swift` | 5 | Inside a `Task` with a one-minute limit: the 10⁵-vertex path on both kinds of rows, C₁₀₀₀₀₁ and C₁₀₀₀₀₂, the 300 × 300 grid with and without a diagonal, a 10⁵-vertex `BipartiteGraph` built by insertion and half removed, the projections of K₁,₄₀₀ and of the 10⁵-vertex path |

166 catalog rows (158 value rows, 8 trap rows), their 84 representation tests, and 29 more tests
(2 precondition, 3 laws, 9 conformance, 6 bipartition and view, 4 property, 5 stress): 279 tests in
all.

## Case IDs

Case IDs (BP-001 … BP-166) refer to the catalog (`cases.md`), whose values `ref.py` computes with
api.md's model and checks against NetworkX 3.7 (`is_bipartite`, `sets`, `color`,
`is_bipartite_node_set`, `projected_graph`; odd cycles for validity, since no other library
returns the same one). Each test's name starts with its ID; tests without an ID check laws,
representations, properties or conformance that the catalog does not list.

| Cases | Section | File |
|---|---|---|
| BP-001 – BP-084 | Recognition | `RecognitionTests.swift`; again in `RecognitionRepresentationTests.swift` |
| BP-085 – BP-104 | `BipartiteGraph(graph)`, `BipartiteGraph(graph, left:)` | `BipartiteGraphFromGraphTests.swift` |
| BP-105 – BP-118 | `BipartiteGraph(left:right:)` | `BipartiteGraphSideInitializerTests.swift` |
| BP-119 – BP-141 | Mutation | `BipartiteGraphMutationTests.swift` |
| BP-142 – BP-149 | Preconditions (traps) | `BipartiteGraphPreconditionTests.swift` |
| BP-150 – BP-161 | Projection | `ProjectionTests.swift` |
| BP-162 – BP-166 | Equality | `BipartiteGraphEqualityTests.swift` |

Rows with parallel edges (BP-010 – BP-014, BP-089) are not repeated on the adjacency lists or the
matrix, which cannot hold them; they run on the unindexed conformer. Rows whose vertices are not
exactly `0..<n` (BP-059, BP-060) or that have an arc twice are not repeated on the matrix.

## Readings of what api.md leaves open

| Question | Reading taken | Where |
|---|---|---|
| The description of `String` vertices | Written as every representation writes them (`String(reflecting:)`): `["a"] \| ["x", "y"]; ["a"–"x"]`; api.md's example `[a, b] \| [x]; [a–x, b–x]` reads as the shape | `descriptions` |
| Decoded vertex order | `left` then `right`: the only order the encoding carries; edge positions are kept | `roundTrip`, `mutationAgainstModel` |
| Coding keys | Not named by api.md, so the invalid payloads are made by editing a valid encoding, its keys found by their values; the edges are a flat `[Int]` of offsets into `left ++ right`, left endpoint first, as `UndirectedAdjacencyList` encodes | `decodeInvalid` |
| Which decoding errors | Overlapping sides, an edge inside a side, a loop, an endpoint out of range or negative, an odd edge list: `dataCorrupted`; wrong types and missing keys: any error | `decodeInvalid` |
| `remove(edge:)`'s result | The stored edge (left endpoint first), as `UndirectedAdjacencyList` returns it; every catalog removal is written in the stored orientation anyway | BP-141, `mutationAgainstModel` |
| `BipartiteGraph(graph)` on a `BipartiteGraph` whose sides are not the canonical ones | The canonical sides, so a different value (api.md: "the canonical sides of `bipartition()`"); no shortcut that returns the graph itself | `storedSidesAreNotRecomputed` |
| `BipartiteSide.description` | Contains the case name | `sides` |
| Hash quality | Equal values hash alike; twelve graphs with the same counts but different edges or sides hash differently | `hashing` |

## Not tested

| Case | Why |
|---|---|
| Decoding a repeated edge, or a vertex repeated within one side | api.md does not say whether decoding rejects them (as `UndirectedAdjacencyList` does) or drops them (as `init?(left:right:edges:)` does) |
| `Bipartition` equality across different graphs with the same sides | api.md: "compares sides by vertex, as `Components` compares groups"; the tests compare bipartitions of one graph, of the same graph rebuilt with edges in another order, and of graphs with different sides |
| `debugDescription`, `customMirror`, `Bipartition.description` | Formats unspecified; checked non-empty |
| Complexity (O(1) `side(of:)`, recognition reading `_withIncidentIndexRows` without hashing, a trapping `insert(edge:)` not copying, no recursion) | Benchmarks; the stress tests bound costs loosely and run on a `Task`'s small stack |
| Recognition on `CompressedSparseRow` and `DirectedGraph` directly | Out of phase 1 (open question 5): recognition is on `Graph`, and compressed sparse row has no `.undirected`; it is tested through `AdjacencyList(csr).undirected` |
| NetworkX and igraph on random graphs (`just diff`) | Not Swift tests; `ref.py` checks every catalog row against NetworkX 3.7, and the property tests use definition oracles |
