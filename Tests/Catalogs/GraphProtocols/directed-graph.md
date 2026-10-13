# `DirectedGraph` / `BidirectionalDirectedGraph` test catalog

The cases for the two directed protocols in `GraphProtocols`: the laws every conformer satisfies,
the defaults, how the representations conform, generic algorithms written against the protocols,
and conversions between representations. The protocols and their laws are documented in
`Sources/GraphProtocols/DirectedGraph.swift`; the conventions are summarized in
`Tests/GraphProtocolsTests/README.md`.

Expected values for the algorithms come from NetworkX 3.7 (`directed_calc.py`, next to this
file), not from Grafluent.

## Notation

`AL`, `AM` and `CSR` are `AdjacencyList`, `AdjacencyMatrix` and `CompressedSparseRow`. `RM` is
the test conformer `ReferenceDirectedMultigraph` (in `GrafluentTestSupport`): edges as written,
repeats kept, with indexed adjacency. `F.x` is `DirectedFixture<Int>.x` or
`DirectedFixture<String>.x` from `Tests/GrafluentTestSupport/DirectedFixtures.swift`, built as
`AdjacencyList(vertices: F.vertices, edges: F.edges)`,
`AdjacencyMatrix(vertexCount: F.vertexCount, edges: F.edges)`,
`CompressedSparseRow(vertexCount: F.vertexCount, edges: F.edges)` (zero-based fixtures only) and
`ReferenceDirectedMultigraph(vertices: F.vertices, edges: F.edges)`. `RM(edges: …)` without
vertices keeps only the endpoints. "Generic" means the value is read through a local
`func f<G: DirectedGraph>(_ g: G)`, never through the concrete type.

`EdgeList` is not a `DirectedGraph` (DG-T08): its adjacency queries scan every edge. It converts
to and from the graphs (DG-C05, DG-C15).

## 1. Laws (any conformer)

| ID | Law | Applies to |
|---|---|---|
| DG-L01 | `g.vertexCount == g.vertices.count`, and the vertices are distinct | all |
| DG-L02 | `g.edgeCount == g.edges.count` | all |
| DG-L03 | Every `v` in `vertices` has `contains(v)`. Every endpoint of every edge is in `vertices` | all |
| DG-L04 | For each `v`: the multiset of `successors(of: v)` equals the multiset of `e.target` over `edges` with `e.source == v` | all |
| DG-L05 | `outDegree(of: v) == Array(successors(of: v)).count`, repeats included | all |
| DG-L06 | `Σ_v outDegree(of: v) == edgeCount` | all |
| DG-L07 | For `u, v` in `vertices`: `contains(edge: u→v) == edges.contains(u→v) == successors(of: u).contains(v)` | all |
| DG-L08 | `contains(edge:)` with an endpoint not in `vertices` is `false` and does not trap (absent vertex `-1`, or `"∅"` for String fixtures) | all |
| DG-L09 | `contains(x)` for `x` not in `vertices` is `false` and does not trap | all |
| DG-L10 | For each `v`: the multiset of `predecessors(of: v)` equals the multiset of `e.source` over `edges` with `e.target == v` | AL, AM, RM |
| DG-L11 | `inDegree(of: v) == Array(predecessors(of: v)).count`; `Σ inDegree == edgeCount` | AL, AM, RM |
| DG-L12 | `degree(of: v) == outDegree(of: v) + inDegree(of: v)`; `Σ degree == 2 · edgeCount` | AL, AM, RM |
| DG-L13 | `u` occurs in `predecessors(of: v)` exactly as many times as `v` occurs in `successors(of: u)` | AL, AM, RM |
| DG-L14 | For each edge `v→v`, `v` is in both `successors(of: v)` and `predecessors(of: v)`, once per copy | all (predecessors: AL, AM, RM) |
| DG-L15 | Simple representations: `edges` has no repeats, and neither has `successors(of: v)` | AL, AM, CSR |
| DG-L16 | The generic value equals the concrete member's value for `vertexCount`, `edgeCount`, `contains`, `contains(edge:)`, `outDegree`, `inDegree` and `degree` on every vertex, so a member whose signature misses the requirement is caught | AL, AM, CSR |
| DG-L17 | Generic `vertexCount`, `edgeCount`, `outDegree` and `inDegree` equal the fixture's | AL, AM, CSR |
| DG-L18 | `successors(of: v)` called twice gives equal sequences | all |
| DG-L19 | `outEdges(of: v)` mapped through `target(ofEdgeAt:)` is `successors(of: v)`, in the same order | all |
| DG-L20 | Every position in `outEdges(of: v)` has `source(ofEdgeAt:) == v`, reads back from `edges`, and appears in no other vertex's out-edges | all |
| DG-L21 | Together the out-edges are every position in `edges` | all |
| DG-L22 | With vertex indices, `vertexIndex(of:)` maps `vertices` one-to-one onto `0..<vertexIndexBound`, and `vertex(atIndex: vertexIndex(of: v)) == v` | all |
| DG-L23 | `vertices` and `edges` are equal when asked again | all |
| DG-L24 | `inEdges(of: v)` mapped through `source(ofEdgeAt:)` is `predecessors(of: v)`, in the same order | AL, AM, RM |
| DG-L25 | Every position in `inEdges(of: v)` has `target(ofEdgeAt:) == v`; their number is `inDegree(of: v)`; together they are every position | AL, AM, RM |
| DG-L26 | `predecessors(of:)` and `inEdges(of:)` asked again give the same answer | AL, AM, RM |
| DG-L27 | With vertex indices, `vertices` is in index order: `vertices.map(vertexIndex) == Array(0..<n)` | all |
| DG-L28 | Flat index rows, when a representation offers them, equal `successorIndices(ofIndex:)` row by row; AL and AM offer none | AL, AM, CSR |
| DG-L29 | With edge indices, `edgeIndexBound == edgeCount` and `edgeIndex(of:)` is one-to-one onto `0..<edgeIndexBound`. Representations without them report `nil`, and `edgeIndex(of:)` traps. AL's positions are `0..<edgeCount` in insertion order until a removal moves the last edge into the hole | AL, CSR; AM and RM have none |
| DG-L30 | `outEdges(ofIndex: vertexIndex(of: v)) == outEdges(of: v)`, defaults included | all, and `directedView` |
| DG-L31 | With edge indices, `edges` is in index order: the `k`th position has `edgeIndex` `k` | AL, CSR |
| DG-L32 | `inEdges(ofIndex: vertexIndex(of: v)) == inEdges(of: v)`, before and after removals | AL, AM, RM, `directedView` |
| DG-P01 | Seeded random graphs (n ∈ 1…30, up to 3n edges, repeats allowed): AL, AM, CSR and `AL(CSR(AL))` observed generically equal RM on the distinct edges (counts, sorted successors, degrees, the adjacency row) | AL, AM, CSR |
| DG-P02 | Tarjan's components on a seeded random graph come out in reverse topological order: every edge between components goes from a later component to an earlier one | CSR; AL and AM agree on the partition |

## 2. Defaults and dispatch

Minimal conformers in the test supply only the required members.

| ID | Case |
|---|---|
| DG-D01 | The defaults from `vertices`, `edges` and single-pass neighborhoods give the fixture's counts and degrees |
| DG-D02 | The bidirectional defaults from collection neighborhoods |
| DG-D03 | A self-loop counts twice in the default `degree` |
| DG-D04 | The default `contains(edge:)` checks both endpoints before reading `successors`, so an absent source does not trap |
| DG-D05 | Generic code, a second generic layer and an existential each call the conformer's own version of every requirement with a default |
| DG-D06 | Without vertex indices, `vertexIndex(of:)` and `vertex(atIndex:)` trap |
| DG-W01 | AL's `contains`, `contains(edge:)` and `outDegree` are O(1) through generic code: on a hub with 200 leaves, a vertex type that counts comparisons sees fewer than 10 per call, where the default scans would make up to 200 |

## 3. Per-representation cases (exact values, generic)

| ID | Case | Expected |
|---|---|---|
| DG-R01 | `AL(F.house)` | `vertexCount 6`, `edgeCount 7`, `outDegree` `[0:0, 1:1, 2:1, 3:2, 4:2, 5:1]`, `inDegree` `[0:2, 1:2, 2:1, 3:1, 4:1, 5:0]` |
| DG-R02 | `AL(F.networkXABCD)` (String) | `vertexCount 7`, `edgeCount 5`; `Set(successors(of: "A")) == ["B", "C"]`; `degree(of: "G") == 0`; `contains("G")` |
| DG-R03 | `AL(F.singleSelfLoop)` | `successors(of: 0) == [0]`, `predecessors(of: 0) == [0]`, `outDegree 1`, `inDegree 1`, `degree 2`, `contains(edge: 0→0)` |
| DG-R04 | `AM(F.boostExample)` | `Array(successors(of: 1)) == [2, 5]`, `Array(predecessors(of: 0)) == [2, 5]`, `Array(predecessors(of: 2)) == [1, 2]`, `outDegree(of: 2) == 2`, `degree(of: 2) == 4`, `contains(edge: 0→1) == false` |
| DG-R05 | `AM(F.isolatedVertices)` | `vertexCount 10`, `edgeCount 0`, every `successors` empty, `Array(vertices) == Array(0..<10)` |
| DG-R06 | `CSR(F.petgraphCsr1)` | `Array(successors(of: 0)) == [0, 2]`, `(of: 1) == [0, 1, 2]`, `(of: 2) == [2]`; `outDegree` `[2, 3, 1]`; `contains(edge: 2→1) == false`, `contains(edge: 1→1) == true` |
| DG-R07 | `CSR(F.boostCsrUnsorted)`, `edges` | `Array(edges) == [0→2, 3→2, 4→0, 4→1, 5→0, 5→2]` (row-major); `edgeCount 6` |
| DG-R08 | `CSR(F.scipyConstructor2)` | `vertexCount 6`, `edgeCount 1`, `outDegree(of: 3) == 1`, all others 0 |
| DG-R09 | Which types are bidirectional | `is any BidirectionalDirectedGraph`: AL and AM `true`, CSR `false` |
| DG-R10 | `RM(edges: F.pathWithChord.edges)` (1→3 twice) | `edgeCount 7`, `Array(successors(of: 1)) == [2, 3, 3]`, `Array(predecessors(of: 3)) == [2, 1, 1]`, `degree(of: 1) == 4` |
| DG-R11 | `RM(edges: F.jgraphtSparseDirected.edges)` (2→4 three times) | `edgeCount 13`, `Array(successors(of: 2)) == [4, 4, 4]`, `Array(predecessors(of: 4)) == [1, 2, 2, 2, 3]`, `degree(of: 7) == 3`; the three copies are positions `[5, 6, 7]` |
| DG-R14 | AL absent vertex, through an existential: exit tests | `successors(of: 99)`, `outDegree(of: 99)`, `predecessors(of: 99)`, `inDegree(of: 99)`, `degree(of: 99)` each trap on `AL(F.house)` |
| DG-R15 | AM and CSR out of range, through an existential: exit tests | `successors(of: 6)` and `outDegree(of: -1)` trap on `AM(F.house)` and `CSR(F.house)`; `predecessors(of: 6)` traps on AM |
| DG-R16 | The empty graph through every representation | `vertexCount 0`, `edgeCount 0`, `vertices` and `edges` empty, `contains(0) == false`, `contains(edge: 0→0) == false` |

## 4. Type-level and API shape

| ID | Case | Expected |
|---|---|---|
| DG-T01 | Associated types, read through generic code | AL: `Successors` and `Predecessors` are `AdjacencyList<Int>.Neighbors`, `Vertices` and `Edges` its own views. AM: `BitSet` neighborhoods, `Range<Int>` vertices, `AdjacencyMatrix.Edges`. CSR: `ArraySlice<Int>` successors, `Range<Int>` vertices and out-edges, `CompressedSparseRow.Edges` |
| DG-T02 | Which types conform; `some DirectedGraph<Int>` | AL, AM and CSR are `DirectedGraph`s, `EdgeList` is not. A local `edgeCount(_: some DirectedGraph<Int>)` returns 7 for AL, AM, CSR and RM built from `house` |
| DG-T03 | `some BidirectionalDirectedGraph<String>` | `degree(of: "b") == 4` on `F.petgraphDAG` through AL and RM (in-edges a→b and d→b, out-edges b→c and b→e) |
| DG-T04 | Existentials | `[any DirectedGraph<Int>]` of AL, AM and CSR built from `house`: each has `edgeCount 7`, `vertexCount 6`, `Set(successors(of: 3)) == [2, 4]`, `outDegree(of: 3) == 2`, `contains(edge: 3→2)`, `vertexIndexBound == 6` |
| DG-T05 | `Sendable` composition | `func f<G: DirectedGraph & Sendable>(_: G)` accepts AL, AM and CSR with `Int` vertices, and reads the graph in a detached `Task` |
| DG-T06 | `EdgeList<AnyHashable>` membership overloads | With `list = EdgeList<AnyHashable>([DirectedEdge(from: 1, to: 2)])`: `list.contains(DirectedEdge<AnyHashable>(from: 1, to: 2))` is edge membership, `true`; `list.contains(AnyHashable(1))` is vertex membership, `true`; `list.contains(AnyHashable(DirectedEdge(from: 1, to: 2)))` is `false` |
| DG-T07 | `EdgeList(list)` copies a list | `EdgeList(list) == list`, `count 7` for `F.pathWithChord` |
| DG-T08 | `EdgeList` is not a `DirectedGraph` | `(EdgeList<Int>() as Any) is any DirectedGraph == false` |

## 5. Edge identity and vertex indices

| ID | Case | Expected |
|---|---|---|
| DG-E01 | Parallel edges told apart by position | On `RM` with edges 0→1 (weight 5), 0→1 (weight 1), 0→2 (weight 2), the cheapest out-edge per target from 0 is `[1: 1, 2: 2]` |
| DG-E02 | Dijkstra written once against edge positions | On `F.petgraphBellmanFord` with weights 1…11 by input position, from 0: `[0: 0, 1: 1, 2: 2, 3: 7]` through AL, AM, CSR and RM |
| DG-I01 | Vertex indices through generic layers and existentials | `vertexIndexBound == 6` for AL, AM and CSR built from `house`, through two generic layers and through `any DirectedGraph<Int>`; 7 for `AL(F.networkXABCD)` |
| DG-I02 | Search on arrays when the graph has indices | A search that keeps visited flags in an array indexed by `vertexIndex(of:)` reaches `["A", "B", "C", "D"]` in `AL(F.networkXABCD)` from "A", `[5, 1000, -3]` in an AL whose vertices are not `0..<n`, and `[0, 1, 2, 3, 4]` in `CSR(F.house)` from 3 |
| DG-I03 | Vertex indices after a removal | AL's indices are still one-to-one and in `vertices` order |

## 6. Generic algorithms (test-local, written against the protocol)

Each test declares its algorithm as a local generic function: BFS, DFS (successors visited in
ascending order, so the result does not depend on neighbor order), Kahn's topological generations
(in-degrees from one pass over `edges`), Tarjan's SCC (base protocol) and Kosaraju's SCC
(`BidirectionalDirectedGraph`). Every representation must give the NetworkX value. Sets and
partitions are compared without order.

| ID | Algorithm / fixture | Expected | Types |
|---|---|---|---|
| DG-A01 | BFS distances, `house` from 5 | `{5:0, 3:1, 2:2, 4:2, 0:3, 1:3}` | AL, AM, CSR, RM |
| DG-A02 | BFS distances, `boost24` from 7 | `{7:0, 11:1, 17:1, 4:2, 15:2, 19:2, 20:2, 0:3, 5:3, 6:3, 13:3, 18:3, 22:3, 23:3, 3:4, 8:4, 9:4, 14:4, 16:4, 21:4, 1:5, 10:5, 12:5, 2:6}`, 24 reached | AL, AM, CSR, RM |
| DG-A03 | BFS distances, `scc9` from 1 | `{1:0, 7:1, 4:2, 5:2, 8:3, 2:4, 6:4, 0:5, 3:6}` | AL, AM, CSR, RM |
| DG-A04 | BFS order with ascending successors, `petgraphEdgesDirected` from 0 | `[0, 1, 2, 3, 5, 4]`; from 6 only `[6]` (self-loop) | AL, AM, CSR, RM |
| DG-A05 | DFS preorder with ascending successors | `petgraphEdgesDirected` from 0: `[0, 1, 3, 2, 4, 5]`; `neo4jDirected` from 0: `[0, 1, 2, 4, 3]`; `petgraphDAG` from "a": `["a", "b", "c", "e", "g", "d", "f"]` | AL, AM, CSR, RM (String: AL, RM) |
| DG-A06 | Topological generations (Kahn) | `house` `[[5],[3],[2,4],[1],[0]]`; `neo4jDirected` `[[0],[1],[2,3],[4]]`; `boostCsrUnsorted` `[[3,4,5],[0,1],[2]]`; `petgraphDAG` `[[a],[d],[b,f],[c],[e],[g]]`; `networkXABCD` `[[A,G,J,K],[B],[C],[D]]` (`RM(edges:)`: `[[A],[B],[C],[D]]`); `scipyConstructor2` `[[0,1,2,3,5],[4]]` (`RM(edges:)`: `[[3],[4]]`) | AL, AM, CSR, RM |
| DG-A07 | Kahn on a multigraph | `RM(edges: pathWithChord.edges)` (1→3 twice) gives `[0, 1, 2, 3, 4, 5]`, all 6 vertices. In-degrees count both copies, so `successors(of: 1)` must list 3 twice or 3 is never emitted | RM, AL |
| DG-A08 | Kahn on cyclic graphs emits fewer than `vertexCount` vertices | `scc9`, `directedCycle4`, `boost24` | all |
| DG-A09 | SCC partition (Tarjan, base protocol) | `scc9` `{{0,3,6},{1,4,7},{2,5,8}}`; `boost24` `{{0},{7},{1…6, 8…23}}` (3 components); `petgraphEdgesDirected` `{{0,2,4},{1},{3},{5},{6}}`; `igraphReverseEdges` `{{0},{1,2,3},{4}}`; `networkXFunctionGraph` `{{0,1},{2},{3},{4}}`; `boostExample` `{{0},{1},{2},{3,4},{5}}` | AL, AM, CSR, RM |
| DG-A10 | SCC partition (Kosaraju, uses `predecessors`) | Same partitions as DG-A09 | AL, AM, RM |
| DG-A11 | Reverse reachability through `predecessors` | ancestors of 8 in `scc9`: `{1,2,4,5,7}`; of 8 in `petgraphBellmanFord`: `{4,5,6,7}`; of 5 in `boostExample`: `{1}` | AL, AM, RM |
| DG-A12 | Reachability through `any DirectedGraph<Int>` | `house` from 5 reaches `{0…5}`, from 2 reaches `{0, 1, 2}` | AL, AM, CSR, RM |

## 7. Conversions

| ID | Case | Expected |
|---|---|---|
| DG-C01 | `AdjacencyList(RM(edges: F.pathWithChord.edges))` | `vertexCount 6`, `edgeCount 6` (the repeated 1→3 collapses), equal to `AL(F.pathWithChord)` |
| DG-C02 | `AdjacencyList(AM(F.scipyConstructor2))` keeps isolated vertices | `vertexCount 6`, `edgeCount 1`, `contains(5)`; `EdgeList(AM(F.scipyConstructor2)).vertexCount == 2` |
| DG-C03 | `AdjacencyList(AdjacencyMatrix(vertexCount: 10))` | `vertexCount 10`, `edgeCount 0` |
| DG-C04 | `CompressedSparseRow(AM(F.boostCsrUnsorted))` exact arrays | `offsets == [0, 1, 1, 1, 2, 4, 6]`, `targets == [2, 2, 0, 1, 0, 2]` |
| DG-C05 | `EdgeList(graph)` lists the graph's `edges` in its order | `EdgeList(CSR(F.house))` is row-major `[1→0, 2→1, 3→2, 3→4, 4→0, 4→1, 5→3]`; for every zero-based fixture, `EdgeList(g)` equals `Array(g.edges)` for AL, AM and CSR; `EdgeList(RM(edges: F.pathWithChord.edges))` keeps both copies of 1→3 |
| DG-C06 | `EdgeList(AM(F.boostExample))` | `[1→2, 1→5, 2→0, 2→2, 3→4, 4→3, 5→0]` |
| DG-C07 | Round trips over every zero-based fixture | `AdjacencyMatrix(CSR(AL(F))) == AM(F)`, `CSR(AM(F)) == CSR(F)`, `AdjacencyList(CSR(F)) == AL(F)`, `AdjacencyList(AM(F)) == AL(F)`, `CSR(RM(F)) == CSR(F)` |
| DG-C08 | Self-conversion is identity | `AdjacencyList(al) == al` (String vertices and isolated vertices included); `AdjacencyMatrix(am) == am`; `CompressedSparseRow(csr) == csr` |
| DG-C09 | Exit test: vertices not exactly `0..<n` | `AdjacencyMatrix(_:)` and `CompressedSparseRow(_:)` trap on an AL built from `F.directedCycle4` (vertices 1…4, n = 4), from `[0→2]`, and from a lone vertex outside `0..<n` (`-1`, `5`); CSR also on `F.triangleWithReciprocalEdge` |
| DG-C10 | Exit test: a conformer whose vertices are not `0..<n` | `CompressedSparseRow(RM(edges: [0→2]))` and `AdjacencyMatrix(RM(edges: [0→2]))` trap (vertex 2 with n = 2) |
| DG-C11 | A multigraph on exactly `0..<n` | `CompressedSparseRow(RM(edges: neo4j.edges + neo4j.edges)) == CSR(vertexCount: 5, edges: neo4j.edges)`, and the same for `AdjacencyMatrix` |
| DG-C12 | String vertices | `AdjacencyList(RM(edges: F.networkXABCD.edges)).vertexCount == 4`; `AdjacencyList(AL(F.networkXABCD)).vertexCount == 7` |
| DG-C13 | Conversion keeps the generic answers | For each zero-based fixture, `vertexCount`, `edgeCount`, every `outDegree` and every `contains(edge:)` agree across AL, `AM(AL)`, `CSR(AL)`, `AL(CSR(AL))` and `AL(AM(AL))` |
| DG-C14 | Conversion keeps vertex order | `AdjacencyList(RM(vertices: ["c", "a", "b"], edges: [b→a])).vertices == ["c", "a", "b"]` |
| DG-C15 | Graphs from an edge list, through their edge initializers | From `EdgeList(F.pathWithChord.edges)`: `AdjacencyList(edges:)`, `CompressedSparseRow(vertexCount: 6, edges:)` and `AdjacencyMatrix(vertexCount: 6, edges:)` each have `edgeCount 6` |

## 8. Benchmarks

These are measured in `Benchmarks/Benchmarks/DirectedGraphBenchmarks`, not tested.

| ID | Measurement |
|---|---|
| DG-B01 | BFS from vertex 0 on a random graph (100,000 vertices, 1,000,000 edges): a concrete loop, `some DirectedGraph` and `any DirectedGraph` |
| DG-B02 | `outDegree(of:)` through generic code on AM at n = 4096: O(1), not the O(n/64) `BitSet.count` |
| DG-B03 | `contains(edge:)` through generic code on CSR with a hub of out-degree 20,000: O(log d), not the O(d) default scan |
