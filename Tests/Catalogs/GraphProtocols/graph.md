# `Graph` / `UndirectedEdge` test catalog

The cases for the undirected protocol `Graph` and the element type `UndirectedEdge<Vertex>` in
`GraphProtocols`, the views between `Graph` and `DirectedGraph` (`directedView`,
`undirectedView`), and `UndirectedAdjacencyList`, the undirected representation. The protocol and
its laws are documented in `Sources/GraphProtocols/Graph.swift`; the conventions are summarized in
`Tests/GraphProtocolsTests/README.md`. The directed cases are in `directed-graph.md`.

Expected values come from NetworkX 3.7: `undirected_calc.py` and `undirected_calc2.py` (next to
this file) compute the algorithm and view values, and `verify.py` checks the fixtures' counts and
degrees. NetworkX lists a self-loop's vertex once among its neighbors, while `Graph` lists it once
per end, so neighbor lists taken from NetworkX get the loop vertex once more per loop.

## Notation

`UAL` is `UndirectedAdjacencyList`. `RP` is the test conformer `ReferencePseudograph` (in
`GrafluentTestSupport`): edges as written, loops and parallel edges kept, with indexed adjacency.
`F.x` is `UndirectedFixture<Int>.x` from `Tests/GrafluentTestSupport/UndirectedFixtures.swift`.
"Generic" means read through a local `func f<G: Graph>(_ g: G)`. Laws run over `UAL` and `RP` for
every fixture; `UAL` collapses written repeats. Edges are written `a–b`.

## 0. Fixtures (`UndirectedFixture`)

| Name | Edges | n / m (UAL) | Degrees |
|---|---|---|---|
| `empty` | — | 0 / 0 | — |
| `trivial` | vertex 0 | 1 / 0 | `[0:0]` |
| `singleSelfLoop` | 0–0 | 1 / 1 | `[0:2]` |
| `isolatedVertices` | vertices 0…9 | 10 / 0 | all 0 |
| `k3` | 0–1, 0–2, 1–2 | 3 / 3 | all 2 |
| `k3WithLoop` | k3 + 0–0 | 3 / 4 | `[0:4, 1:2, 2:2]` |
| `loopAndPath` | 0–0, 0–1, 1–2 | 3 / 3 | `[0:3, 1:2, 2:1]` |
| `petgraphUndirected` | a–b, a–c, c–a, a–a, b–c, b–a, a–d (a…d = 0…3) | 4 / 5 (RP: 7) | UAL `[0:5, 1:2, 2:2, 3:1]`; RP `[0:7, 1:3, 2:3, 3:1]` |
| `components7` | vertices 0…6; 0–1, 1–2, 3–4 | 7 / 3 | `[0:1, 1:2, 2:1, 3:1, 4:1, 5:0, 6:0]` |
| `path4` | 0–1, 1–2, 2–3 | 4 / 3 | `[0:1, 1:2, 2:2, 3:1]` |
| `cycle5` | 0–1, 1–2, 2–3, 3–4, 0–4 | 5 / 5 | all 2 |
| `k4` | all pairs of 0…3 | 4 / 6 | all 3 |
| `house` | 0–1, 0–2, 1–3, 2–3, 2–4, 3–4 | 5 / 6 | `[0:2, 1:2, 2:3, 3:3, 4:2]` |
| `petersen` | 0–1, 0–4, 0–5, 1–2, 1–6, 2–3, 2–7, 3–4, 3–8, 4–9, 5–7, 5–8, 6–8, 6–9, 7–9 | 10 / 15 | all 3 |
| `cube` | 0–1, 0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7 | 8 / 12 | all 3 |
| `karate` | Zachary's 78 edges | 34 / 78 | `[0:16, 1:9, 2:10, 3:6, 4:3, 5:4, 6:4, 7:4, 8:5, 9:2, 10:3, 11:1, 12:2, 13:5, 14:2, 15:2, 16:2, 17:2, 18:2, 19:3, 20:2, 21:2, 22:2, 23:5, 24:3, 25:3, 26:2, 27:4, 28:3, 29:4, 30:4, 31:6, 32:12, 33:17]` |
| `parallelPath` (RP only) | 0–1, 1–2, 1–2 | 3 / 3 | `[0:1, 1:3, 2:2]` |

`UndirectedFixture<String>` adds `networkXABCD`, `networkXIJK` and `petgraphUndirected` with
String vertices.

## 1. Laws (any conformer)

| ID | Law | Directed analogue |
|---|---|---|
| UG-L01 | `vertexCount == vertices.count`; vertices distinct | DG-L01 |
| UG-L02 | `edgeCount == edges.count` (each edge once, a loop once, each copy once) | DG-L02 |
| UG-L03 | every `v` in `vertices` has `contains(v)`; both endpoints of every edge are vertices | DG-L03 |
| UG-L04 | for each `v`: the multiset of `neighbors(of: v)` equals the multiset over `edges` of `w` for each `{v, w}` with `w ≠ v`, and `v, v` for each `{v, v}` | DG-L04 |
| UG-L05 | `degree(of: v) == Array(neighbors(of: v)).count == Array(incidentEdges(of: v)).count` | DG-L05 |
| UG-L06 | `Σ degree == 2 · edgeCount` | DG-L06, DG-L12 |
| UG-L07 | for `u, v` in `vertices`: `contains(edge: u–v) == contains(edge: v–u) == edges.contains(u–v) == neighbors(of: u).contains(v)` | DG-L07 |
| UG-L08 | `contains(edge:)` with an absent endpoint is false and does not trap (`-1`, or `"∅"`) | DG-L08 |
| UG-L09 | `contains(x)` for absent `x` is false and does not trap | DG-L09 |
| UG-L10 | for `u ≠ v`, `u` occurs in `neighbors(of: v)` as often as `v` in `neighbors(of: u)` | DG-L13 |
| UG-L11 | each loop copy at `v` puts `v` twice in `neighbors(of: v)` and its position twice in `incidentEdges(of: v)` | DG-L14 |
| UG-L12 | simple conformers (UAL): `Set(edges).count == edgeCount`; `neighbors(of: v)` repeats only `v`, exactly twice when `v–v` exists | DG-L15 |
| UG-L13 | generic equals concrete for `vertexCount`, `edgeCount`, `contains`, `contains(edge:)`, `degree` and `oppositeVertex` on every vertex and edge | DG-L16 |
| UG-L14 | generic counts and degrees equal the fixture's | DG-L17 |
| UG-L15 | `neighbors(of:)` and `incidentEdges(of:)` asked twice are equal | DG-L18 |
| UG-L16 | for each `e` in `incidentEdges(of: v)`, `edges[e]` has `v` as an endpoint, and `incidentEdges(of: v).map { oppositeVertex(to: v, acrossEdgeAt: $0) } == Array(neighbors(of: v))` | DG-L19, DG-L20 |
| UG-L17 | over all vertices, each position occurs exactly twice in the incident lists: once at each end of a non-loop, twice at a loop's vertex; the positions seen are exactly `Set(edges.indices)` | DG-L21 |
| UG-L18 | `oppositeVertex(to: oppositeVertex(to: v, acrossEdgeAt: e), acrossEdgeAt: e) == v` | — |
| UG-L19 | indices map `vertices` one-to-one onto `0..<vertexIndexBound`, and `vertex(atIndex: vertexIndex(of: v)) == v` | DG-L22 |
| UG-L20 | with indices, `vertices.map(vertexIndex) == Array(0..<n)` | DG-L27 |
| UG-L21 | `Array(neighborIndices(ofIndex: vertexIndex(of: v))) == neighbors(of: v).map(vertexIndex)` | — |
| UG-L22 | `vertices` and `edges` are equal when asked again | DG-L23 |
| UG-L23 | stored orientation is stable: `edges[e].u` and `.v` read twice are identical, not merely `==` | — |
| UG-L24 | with edge indices, `edgeIndexBound == edgeCount`, `edgeIndex(of:)` is one-to-one onto `0..<edgeIndexBound`, and `incidentEdgeIndices` is `incidentEdges` mapped through it; the undirected view forwards its base's edge indices, or their absence | DG-L29 |
| UG-L25 | with edge indices, `edges` is in index order | DG-L31 |
| UG-P01 | seeded random graphs (n ∈ 1…30, up to 3n edges, loops and repeats allowed): `UAL` observed generically equals `RP(Set(edges))` observed the same way (counts, sorted neighbors, degrees, adjacency row) | DG-P01 |
| UG-P02 | random insertions and removals on `UAL` keep every law and agree with a set model | — |

## 2. `UndirectedEdge`

| ID | Case | Expected |
|---|---|---|
| UG-E01 | symmetric `==` and hash | `UndirectedEdge(1, 2) == UndirectedEdge(2, 1)`, equal `hashValue` |
| UG-E02 | `Set` | `Set([1–2, 2–1, 1–1]).count == 2` |
| UG-E03 | loops are distinct values | `0–0 != 1–1`; `Set((0..<100).map { UndirectedEdge($0, $0).hashValue }).count == 100` |
| UG-E04 | different endpoints differ | `3–3 != 3–4`; `1–2 != 1–3` |
| UG-E05 | `isSelfLoop` | `2–2` true, `2–3` false |
| UG-E06 | `oppositeVertex(to:)` | `(1–2).oppositeVertex(to: 1) == 2`, `(to: 2) == 1`, `(5–5).oppositeVertex(to: 5) == 5`; exit test: `(1–2).oppositeVertex(to: 3)` traps |
| UG-E07 | `Comparable` | ordered by `(min(u, v), max(u, v))`: neither `1–2 < 2–1` nor `2–1 < 1–2`; `[2–0, 1–0, 0–0].sorted() == [0–0, 0–1, 0–2]` |
| UG-E08 | orientation kept | `UndirectedEdge(2, 1).u == 2`, `.v == 1` |
| UG-E09 | description | `"\(UndirectedEdge(1, 2))" == "1–2"`; `String(reflecting: UndirectedEdge("a", "b")) == "\"a\"–\"b\""` |
| UG-E10 | `Codable` | a JSON round trip of `UndirectedEdge(2, 1)` gives `u == 2, v == 1` |
| UG-E11 | conditional conformances | `UndirectedEdge<Int>` is `Sendable` and `BitwiseCopyable`; with a non-`Sendable` class vertex it is still `Hashable` |

## 3. `UndirectedAdjacencyList` (generic unless noted)

These run in `Tests/UndirectedAdjacencyListTests`.

| ID | Case | Expected |
|---|---|---|
| UG-R01 | `F.empty` | `vertexCount 0`, `edgeCount 0`, `contains(0) == false`, `contains(edge: 0–0) == false` |
| UG-R02 | `F.trivial` | `neighbors(of: 0) == []`, `degree 0`, `incidentEdges == []` |
| UG-R03 | `F.singleSelfLoop` | `edges == [0–0]`, `edgeCount 1`, `neighbors(of: 0) == [0, 0]`, `incidentEdges(of: 0) == [0, 0]`, `degree 2`, `contains(edge: 0–0)` |
| UG-R04 | `F.k3` | `neighbors(of: 0).sorted() == [1, 2]`; incident edges of 0 read back as `{0–1, 0–2}`; degrees all 2; `edgeCount 3`; `contains(edge: 1–0)`; `contains(edge: 0–(-1)) == false` |
| UG-R05 | `F.k3WithLoop` | degrees `[0:4, 1:2, 2:2]`, `edgeCount 4`, `neighbors(of: 0).sorted() == [0, 0, 1, 2]` |
| UG-R06 | `F.loopAndPath`, insertion order | `neighbors(of: 0) == [0, 0, 1]`, `incidentEdges(of: 0) == [0, 0, 1]`, degrees `[3, 2, 1]`, `Σ == 6` |
| UG-R07 | `F.petgraphUndirected` | `edgeCount 5`, degrees `[0:5, 1:2, 2:2, 3:1]`, `neighbors(of: 1).sorted() == [0, 2]`; after `remove(0)`: `vertexCount 3`, `edgeCount 1`, `edges == [1–2]`, `neighbors(of: 1) == [2]` |
| UG-R08 | remove a vertex with an incident loop | `F.loopAndPath` `.remove(0)` returns `0`; `vertices` `{1, 2}`, `edges == [1–2]`, `degree(of: 1) == 1` |
| UG-R09 | remove a loop, then a vertex so that a slot with a loop moves | `{0–0, 0–1, 0–2, 2–2}`: `remove(edge: 0–0)` → `edgeCount 3`, `degree(of: 0) == 2`; then `remove(1)` → `edgeCount 2`, `degree(of: 2) == 3`, `neighbors(of: 2).sorted() == [0, 2, 2]`; the laws hold after each step, and after removing every vertex in turn |
| UG-R10 | reinsertion | after `insert(edge: 0–1)`, `insert(edge: 1–0)` returns `(false, 0–1)` with `.u == 0`; `edgeCount` unchanged; `remove(edge: 1–0)` returns `0–1` (stored orientation); a repeated self-loop is inserted once |
| UG-R11 | positions | `Array(edges.indices) == Array(0..<edgeCount)`; after each `remove(edge:)` the positions are still `0..<edgeCount` and UG-L16, L17 hold |
| UG-R12 | `F.petersen`, `F.cube` | `(10, 15)`, `(8, 12)`, every degree 3, `Set(edges)` equals the fixture list |
| UG-R13 | `F.karate` | `vertexCount 34`, `edgeCount 78`, degrees as in §0 |
| UG-R14 | `F.isolatedVertices` | `vertexCount 10`, `edgeCount 0`, all degrees 0 |
| UG-R15 | exit tests: absent vertex | on `UAL(F.k3)`: `neighbors(of: 99)`, `incidentEdges(of: 99)`, `degree(of: 99)`, `vertexIndex(of: 99)` trap; `oppositeVertex(to: 2, acrossEdgeAt: 0)` (edge `0–1`) traps |
| UG-R16 | equality and hashing | `UAL(edges: [0–1, 1–2]) == UAL(edges: [2–1, 1–0])` with equal hashes; `!=` after adding isolated vertex 3; `!=` with `0–0` added; `UAL(edges: [0–1]) != UAL(edges: [0–2])`; edgeless graphs on different vertices differ; all 64 graphs on three vertices with loops allowed are pairwise distinct |
| UG-R17 | value semantics | `var b = a; b.insert(edge: 5–6)` leaves `a` unchanged, and so does every other kind of mutation |
| UG-R18 | description | `UAL(vertices: [0, 1, 2], edges: [0–1, 1–2]).description == "[0, 1, 2]; [0–1, 1–2]"`; elements are written as `Array` writes them; long lists stop after 16 items |
| UG-R19 | `Codable` | JSON and property-list round trips are `==`, also after removals; decoding keeps each edge's position and orientation, and rejects an edge given twice in either orientation |
| UG-R20 | dictionary literal | `["a": ["b"], "b": ["a"]]` has `edgeCount 1`, `vertexCount 2` |
| UG-R21 | `removeAllEdges` | every `contains(edge:)` is false, degrees are 0, and reinserting works |
| UG-R22 | edge indices | `edgeIndexBound == edgeCount`, the indices are the positions, and the incident ones run parallel to `neighborIndices` |

## 4. Type-level and API shape

| ID | Case | Expected |
|---|---|---|
| UG-T01 | associated types | `UAL<Int>.IncidentEdges == ArraySlice<Int>`, `.NeighborIndices == ArraySlice<Int>`, `.Edges.Index == Int`; `Neighbors`, `Vertices` and `Edges` are the adjacency list's own views |
| UG-T02 | `some Graph<Int>` | accepts `UAL` and `RP` built from `F.house` (`edgeCount` 6, 6) and `AdjacencyList(DirectedFixture.house).undirectedView` (7) |
| UG-T03 | `any Graph<Int>` | `[UAL(F.house), RP(F.house), AdjacencyList(UAL(F.house).directedView).undirectedView]`: `edgeCount` 6, 6, 12 (each edge's two arcs become two parallel edges); `vertexCount 5`, `Set(neighbors(of: 2)) == [0, 3, 4]` and `vertexIndexBound == 5` through each |
| UG-T04 | `Graph & Sendable` | accepts `UAL<Int>`, `UAL<String>` and `RP`, read in a detached `Task` |
| UG-T05 | no dual conformance | `UAL` and `RP` are not `DirectedGraph`s; `AdjacencyList` is not a `Graph`; `directedView` is only a `BidirectionalDirectedGraph` and `undirectedView` only a `Graph` |
| UG-T06 | defaults through minimal conformers | with single-pass and with collection neighborhoods: default `degree` counts a self-loop twice, default `contains(edge:)` checks both endpoints before reading neighbors, default `oppositeVertex` reads `edges`, default `neighborIndices` maps `neighbors` through `vertexIndex`; without vertex indices, asking for one traps |
| UG-T07 | dispatch | a conformer's own version of every requirement with a default is reached from generic code, a second generic layer and `any Graph` |
| UG-T08 | builder | `UAL<Int> { for i in 0..<5 { UndirectedEdge(i, (i + 1) % 5) }; 99 }` has `vertexCount 6`, `edgeCount 5`; `UAL<UndirectedEdge<Int>> { UndirectedEdge(1, 2) }` reads the expression as an edge; an `if` without an `else`, and either branch of an `if`–`else` |
| UG-T09 | `Comparable` only when possible | `UndirectedEdge<Int>` is `Comparable`; `UndirectedEdge<AnyHashable>` is not |

## 5. Generic algorithms (test-local, against `Graph`)

| ID | Algorithm / fixture | Expected | Types |
|---|---|---|---|
| UG-A01 | BFS distances from 0 | `petersen {0:0, 1:1, 4:1, 5:1, 2:2, 3:2, 6:2, 7:2, 8:2, 9:2}`; `cube {0:0, 1:1, 2:1, 4:1, 3:2, 5:2, 6:2, 7:3}`; `house {0:0, 1:1, 2:1, 3:2, 4:2}`; `karate {0:0; 1–8, 10–13, 17, 19, 21, 31:1; 9, 16, 24, 25, 27, 28, 30, 32, 33:2; 14, 15, 18, 20, 22, 23, 26, 29:3}` | UAL, RP |
| UG-A02 | BFS layers from 0 | `petersen [[0],[1,4,5],[2,3,6,7,8,9]]`; `cube [[0],[1,2,4],[3,5,6],[7]]`; `cycle5 [[0],[1,4],[2,3]]` | UAL, RP |
| UG-A03 | DFS preorder, ascending neighbors | `petersen [0,1,2,3,4,9,6,8,5,7]`; `cube [0,1,3,2,6,4,5,7]`; `house [0,1,3,2,4]`; `karate [0,1,2,3,7,12,13,33,8,30,32,14,15,18,20,22,23,25,24,27,31,28,29,26,9,19,17,21,4,6,5,10,16,11]` | UAL, RP |
| UG-A04 | connected components (union–find over `edges`) | `components7 {{0,1,2},{3,4},{5},{6}}`, 4 components; `petersen`, `karate` 1 | UAL, RP |
| UG-A05 | undirected DFS edge classes, edges marked by position | `k4` from 0: 3 tree, 3 back (m − n + c); `singleSelfLoop`: 0 tree, 1 back; RP `{0–1, 0–1}`: 1 tree, 1 back. A directed DFS over `UAL(k4).directedView` classifies arcs instead: 3 tree, 6 back, 3 forward, 0 cross | UAL, RP |
| UG-A06 | bridges by edge position | `path4 {0–1, 1–2, 2–3}`; `karate {0–11}`; `petersen`, `cube`, `house`, `k4`, `cycle5` none; RP `parallelPath {0–1}` (the doubled edge is not a bridge); `UAL(parallelPath)` collapses to a path, both edges bridges | UAL, RP |
| UG-A07 | Euler circuit condition (connected, all degrees even) using `degree` | `singleSelfLoop` true; `k3WithLoop` true (4, 2, 2); RP `{0–1, 1–2, 2–0, 0–1}` false (3, 3, 2), its UAL true; `cycle5` true; `k4` false | UAL, RP |
| UG-A08 | two-coloring by BFS | `cube`, `path4` true; `petersen`, `cycle5`, `k4`, `house`, `singleSelfLoop` false | UAL, RP |
| UG-A09 | the same through `any Graph<Int>` | UG-A01 and UG-A04 values | all |

## 6. Views and conversions

| ID | Case | Expected |
|---|---|---|
| UG-C01 | `directedView` laws, every fixture | `vertexCount == n`, `edgeCount == 2m`, `outDegree(of: v) == degree(of: v)`, `successors == neighbors`, `successorIndices == neighborIndices`, DG-L19 – L21 (every arc once in `outEdges`), `edges[a]` is the base edge or its reverse, `contains(edge: u→v) == contains(edge: v→u) == base.contains(edge: u–v)`; `edges` is empty exactly when the base has no edges |
| UG-C02 | `directedView`, exactly | `UAL(F.loopAndPath).directedView`: `Array(edges) == [0→0, 0→0, 0→1, 1→0, 1→2, 2→1]`, `edgeCount 6`; `AdjacencyList(that view)` has 5 edges `{0→0, 0→1, 1→0, 1→2, 2→1}` |
| UG-C03 | `directedView` is bidirectional | `predecessors(of: v) == neighbors(of: v)`; `predecessorIndices` is `predecessors` mapped; `inDegree == degree`; `degree(of: v) == 2 · base.degree(of: v)`; Kosaraju on it gives the connected components of UG-A04 |
| UG-C04 | Traversal through the view | `UAL(F.petersen).lazy.breadthFirstSearch(from: 0)` distances equal UG-A01 |
| UG-C05 | `undirectedView` of `AdjacencyList(DirectedFixture.house)` | degrees `{0:2, 1:3, 2:2, 3:3, 4:3, 5:1}`; BFS from 5 `{5:0, 3:1, 2:2, 4:2, 0:3, 1:3}`; 1 component |
| UG-C06 | reciprocal arcs stay parallel in the view | `DirectedFixture.triangleWithReciprocalEdge`: the view has `edgeCount 4`, degrees `{1:3, 2:3, 3:2}`; `UAL(view)` collapses to `edgeCount 3`, degrees all 2 |
| UG-C07 | directed loops in the view | `AdjacencyList(DirectedFixture.selfLoopsAndDuplicates).undirectedView`: degrees `{1:1, 2:4, 3:1, 4:3, 5:3}`, equal to the base's `degree`; `neighbors(of: 4)` contains 4 twice; `Σ degree == 12 == 2 · 6` |
| UG-C08 | view positions | the `undirectedView`'s `Edges.Index` is `AdjacencyList.Edges.Index`; a weight dictionary keyed by base positions gives the same value from `incidentEdges` of both ends |
| UG-C09 | round trips over every fixture | `UAL(AdjacencyList(ual.directedView).undirectedView) == ual`; `UAL(ual) == ual` |
| UG-C10 | conversion from a pseudograph | `UAL(RP(F.petgraphUndirected))` has `edgeCount 5` (copies collapse, the loop stays) and equals `UAL(F.petgraphUndirected)` |
| UG-C11 | CSR to undirected | `UAL(vertices: csr.vertices, edges: csr.edges.map { UndirectedEdge($0.source, $0.target) })` for `DirectedFixture.house` equals `UAL(AdjacencyList(house).undirectedView)`: `edgeCount 7`, `Set(neighbors(of: 2)) == [1, 3]` |

## 7. Benchmarks

These are measured in `Benchmarks/Benchmarks/UndirectedAdjacencyListBenchmarks`, not tested.

| ID | Measurement |
|---|---|
| UG-B01 | BFS: a hand-written loop over `neighborIndices` against Traversal's `breadthFirstSearch` through `directedView` and against `any Graph` |
| UG-B02 | `degree(of:)` and `contains(edge:)` through generic code on a hub of degree 20,000: O(1), not the default scans |
| UG-B03 | `remove(_:)` of the hub: O(degree) |
| UG-B04 | a copy shares storage until its first mutation, which copies a constant number of buffers |
