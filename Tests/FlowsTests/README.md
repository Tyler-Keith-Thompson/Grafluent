# Flows test suite

`Flows` computes maximum flows and minimum cuts on `DirectedGraph` and `Graph` (each undirected
edge usable either way, results over `directed`): `maximumFlow(from:to:capacity:)` (push–relabel),
`maximumFlowValue`, `edmondsKarpMaximumFlow`, `dinicMaximumFlow`, the canonical s–t cut
`minimumCut(from:to:capacity:)` (the least sink side), the global `minimumCut(capacity:)`
(Nagamochi–Ibaraki on `Graph`, Hao–Orlin on `DirectedGraph`; a minimum cut, pinned only where
unique), Gusfield's `gomoryHuTree(capacity:)`, `minimumCostFlow(supply:capacity:cost:)` and
`minimumCostMaximumFlow` (network simplex, integers only), `edgeConnectivity`,
`vertexConnectivity` and `minimumVertexCut` with their s–t forms, and `edgeDisjointPaths` and
`vertexDisjointPaths`. The tests were written before the
implementation, from the proposed API (`api.md` in [`Tests/Catalogs/Flows/`](../Catalogs/Flows/),
phase 1), with the open questions decided: no `FlowNetworks` module and no stored flow network;
no source-minimal cut; minimum-cost flow on integers only, without an infeasibility witness. After
the critical review, the global cuts moved to Nagamochi–Ibaraki and Hao–Orlin (re-specified as
"a minimum cut"), disjoint paths and `flowMap` were added, and FL-488 – FL-531 joined the catalog. The suite uses only the public API, and each test
is self-contained: the procedures, brute-force searches and definitions it checks against are
written out inside it. The shared material is `ReferenceDirectedMultigraph`, `ReferencePseudograph`,
`Collider`, the seeded generator and the tags in `GrafluentTestSupport`; two conformers with no
vertex or edge indices are private to the files that use them.

## API under test

```swift
extension DirectedGraph {   // and the same on Graph, results over `DirectedView<Self>`
    func maximumFlow<C>(from:to:capacity:) -> Flow<Self, C>              // C: Comparable & AdditiveArithmetic
    func maximumFlowValue<C>(from:to:capacity:) -> C
    func edmondsKarpMaximumFlow<C>(from:to:capacity:) -> Flow<Self, C>   // per-edge flow pinned
    func dinicMaximumFlow<C>(from:to:capacity:) -> Flow<Self, C>
    func minimumCut<C>(from:to:capacity:) -> Cut<Self, C>                // the least sink side
    func minimumCut<C>(capacity:) -> Cut<Self, C>?                       // Hao–Orlin; Nagamochi–Ibaraki on Graph
    func minimumCostFlow<S: SignedInteger, C: BinaryInteger, W: SignedInteger>(supply:capacity:cost:) -> MinimumCostFlow<Self, C, W>?
    func minimumCostMaximumFlow<C, W>(from:to:capacity:cost:) -> MinimumCostFlow<Self, C, W>
    func edgeConnectivity() -> Int;   func edgeConnectivity(from:to:) -> Int
    func vertexConnectivity() -> Int; func vertexConnectivity(from:to:) -> Int
    func minimumVertexCut() -> [Vertex]; func minimumVertexCut(from:to:) -> [Vertex]?
    func edgeDisjointPaths(from:to:) -> [Path<Vertex, Edges.Index>]; func vertexDisjointPaths(from:to:) -> [Path<…>]
}
extension Graph { func gomoryHuTree<C>(capacity:) -> GomoryHuTree<Self, C>? }
struct Flow<G, C>            { source; sink; value; flow(ofEdgeAt:); flowMap; minimumCut; == }   // + signed flow(ofEdgeAt:) over directed
struct Cut<G, C>             { value; sourceSide; sinkSide: [G.Vertex]; edges: [G.Edges.Index]; == }
struct FlowMap<G, Value>     { Collection by edge position }
struct GomoryHuTree<G, C>    { tree: Tree<G.Vertex>; capacity(ofEdgeAt:); minimumCutValue(between:and:); minimumCut(between:and:); == }
struct MinimumCostFlow<G, C, W> { cost; value; flow(ofEdgeAt:); flowMap; potential(of:); == }
```

## Conventions

| Question | Choice | Cases |
|---|---|---|
| Capacities asked | Once per non-loop edge, in position order, before any work; self-loops never asked, carry nothing, never cross a cut | every flow, cut and Gomory–Hu row (the closure's calls are recorded), `loopsNeverAsked` |
| Which s–t cut | The least sink side: the vertices that can still reach the sink in the residual network of any maximum flow; the same `Cut` from all three maximum flows and `minimumCut(from:to:)` | FL-001 – FL-212; every `MinimumCut` row checks it against brute force over every s–t cut |
| A cut's edges | Every non-loop edge from the source side to the sink side, zero capacities included, in position order; on `Graph` the arc from the source side (`3r`: against the stored order) | FL-021, FL-026, FL-179, FL-194 |
| Which maximum flow | Unspecified, except Edmonds–Karp's: residual rows in edge-position order, breadth-first search stopped at the sink, bottleneck augmentation | `EdmondsKarpTests.swift`, `directedMaximumFlows` (the procedure written out) |
| Undirected flows | One residual pair per edge, capacity c both ways; the flow on the forward or the reversed `DirectedView` arc, at most one nonzero | FL-164 – FL-212, `undirectedMaximumFlows` |
| Parallel and antiparallel edges | Separate arcs with their own flows; each copy listed in a cut; λ counts copies, κ reads the simple graph | FL-066, FL-071, FL-230, FL-340, FL-481, `parallelEdgesApart` |
| Floating capacities | Dyadic rows exact; rows with capacities that are not multiples of 1/1024 (FL-151 – FL-155) compare values and flows within 1e-12, the cut exactly | `floatingCapacities` |
| Global cut on `Graph` | A minimum cut with the first vertex on its source side, deterministic, which one not pinned (Nagamochi–Ibaraki); when positive edges do not connect the graph, value 0 and the first vertex's component as the source side; nil below two vertices. Rows pin the sides only where unique | FL-227 – FL-248, FL-492 – FL-494, FL-499, FL-500, `globalCuts` |
| Global cut on `DirectedGraph` | A minimum cut, deterministic, which one not pinned (Hao–Orlin); the value also the least over the cyclic pairs vᵢ → vᵢ₊₁ (Schnorr 1979; Esfahanian's Algorithm 8) | FL-250 – FL-257, FL-497, FL-498, FL-501, `globalCuts` |
| Small capacity types in the global cuts and Gomory–Hu | Sums formed in `Int` / `Int128` / `Double`; only the answer must fit | FL-492 – FL-498, FL-526, FL-527 |
| Disjoint paths | λ(s, t) edge-disjoint and κ(s, t) internally vertex-disjoint simple paths (an edge s → t one path), not pinned; a unit flow's cycles dropped (FL-530) | FL-502 – FL-531, `connectivity` |
| Gomory–Hu | Gusfield's tree with the canonical cut, vertices in index order, rooted at the first; edge k joins vertex k + 1 and its parent; `minimumCut(between:and:)` splits at the least tree edge nearest u | FL-258 – FL-273, `gomoryHu` (written out) |
| Minimum-cost flow | Least cost; the flow pinned only where it is the only optimum; negative-cost self-loops saturated, others empty; nil for unbalanced supplies or a set supplying more than its out-edges carry; `Int.max` capacities exact; unsigned capacities accepted | FL-275 – FL-305, FL-488 – FL-491, `minimumCostFlow`, `unsignedMinimumCostCapacities` |
| Optimality | `potential(of:)` certifies it: reduced cost ≥ 0 on every edge below capacity, ≤ 0 on every edge with flow | every minimum-cost row and property |
| `minimumCostMaximumFlow` | The maximum flow value, then the least cost among flows of that value, circulations included | FL-308 – FL-318, `minimumCostMaximumFlow` |
| Connectivity | λ: parallel edges count; κ: the simple graph, κ(Kₙ) = n − 1, 0 below two vertices or when not (strongly) connected; κ(s, t) counts an edge s → t as one path; the s–t vertex cut nil exactly when such an edge exists; the global vertex cut by Even's pairs | FL-320 – FL-484, `connectivity` |
| Preconditions | `source == sink`, a terminal not in the graph, a negative, NaN or infinite capacity, the capacities at the source summing past the type, a cost total past the cost type (no bound on the solver's artificial cost: FL-491 succeeds) | `FlowsPreconditionTests.swift` |

## How values are pinned

Every catalog row is written as the catalog writes it: directed rows on `AdjacencyList` (or
`DirectedPseudograph` when an edge repeats) and undirected rows on `UndirectedAdjacencyList` (or
`Pseudograph` with parallel edges), built by inserting the listed vertices and then the edges in
written order, so every vertex index and edge position is the catalog's. The catalog-row files were
generated from `cases.md` by a script (`swiftgen.py`, next to `ref.py` and `cases.md` in
[`Tests/Catalogs/Flows/`](../Catalogs/Flows/)). It runs `ref.py`'s catalog with every case builder
instrumented, so each network is kept as a structured value, checks that the rendered catalog
equals `cases.md` byte for byte, then re-evaluates each row with `ref.py`'s models (Edmonds–Karp,
Dinic and push–relabel with the canonical cut, the global cut's value with brute force deciding
whether its sides are unique, Gusfield, the successive-shortest-path minimum-cost model, the
split-network connectivity and disjoint-path counts), asserts that the result renders to its catalog
cell exactly, and writes one test per row. The hand-written traps are a generator input
(`extra_traps.swift`), so regenerating reproduces the committed files byte for byte:

```sh
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1 \
    python3 Tests/Catalogs/Flows/swiftgen.py /tmp/fl && diff -r /tmp/fl Tests/FlowsTests   # only the hand-written files differ
```

Each row asserts the exact documented result and then checks it inside the test. Flow rows: the
value; the closure's calls; capacity and conservation edge by edge (the value is the net flow out of
the source and into the sink); the canonical cut exactly, equal to the vertices that still reach the
sink in that flow's residual network (computed in the test from the returned flows); the cut's edges
as every edge from the source side to the sink side; the cut's value as their capacity and the
flow's value, which certifies both optimal. Edmonds–Karp rows add the exact per-edge flow. Value
rows compare with `maximumFlow` and `minimumCut`. Cut rows also find, by brute force over every s–t
cut (n ≤ 12), the least value and the least sink side (the intersection of the minimum cuts' sink
sides), and compare the `Cut` with all three maximum flows' cuts. Global-cut rows brute-force every
nonempty proper vertex set for the value, check the cut's edges and value from its own sides and
(undirected) the first vertex on the source side, compare the sides with the catalog's where it pins
them, and call twice for the same cut. Disjoint-path rows check the count against λ(s, t) or
κ(s, t), each path from s to t along its edges, and that no edge (no inner vertex) repeats. Gomory–Hu rows check every tree edge and capacity, and for every
ordered pair the least capacity on the tree path (the path found in the test) against
`minimumCutValue(between:and:)` and a brute-force minimum cut, and `minimumCut(between:and:)` against
the split at the first least tree edge from u and the graph's crossing edges. Minimum-cost rows check
the cost, the flow where it is the only optimum, the closures' calls, feasibility, the self-loop rule,
the cost as Σ flow × cost and the potentials' complementary slackness; nil rows find an infeasibility
witness in the test (unbalanced supplies, or a vertex set supplying more than its out-edges carry,
Gale's condition). Connectivity rows compare with brute force over removed vertex sets and edge cuts
(n ≤ 10 to 12), with the unit-capacity global cut and maximum flow, and check that each vertex cut
disconnects or separates.

The representation files (one per catalog section) run every non-trap row (465) again: directed rows on `DirectedPseudograph`
(or `ReferenceDirectedMultigraph` for rows already on it), on a conformer with no vertex or edge
indices, and, when no edge repeats, on `CompressedSparseRow` and `AdjacencyMatrix` over the vertex
indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and, when no
arc repeats, `AdjacencyList.undirected` (each edge an arc as written) and `AdjacencyMatrix.undirected`.
`CompressedSparseRow` and `AdjacencyMatrix` number edges by row-major cell, so there each catalog
edge's position is looked up, a cut's edges are listed in that order, and Edmonds–Karp's flow (which
follows positions) was recomputed by `swiftgen.py` with `ref.py`'s model on those positions. Every
other value is position-independent (the canonical cut, the pinned global cuts, Gusfield's tree,
costs, connectivity, path counts) and is the catalog's; global-cut rows with several minimum cuts
check the value and the first vertex's side there.

The conformance, property and stress files compute their expectations inside each test. The
property tests (swift-property-based, shrinking) use multigraphs with self-loops on at most 9
vertices in a seed-shuffled vertex order, so every oracle is a brute force over at most 2⁹ vertex sets
or a polynomial procedure written out: Edmonds–Karp (pinned flow), Gusfield with the library's
canonical cut, the least cyclic pair for the directed global value, a Bellman–Ford
successive-shortest-path minimum-cost oracle, and Menger's theorem for κ, λ and the disjoint paths.
One property runs medium clustered networks (20 – 60 vertices, heavy edges inside up to four
clusters and light ones between, so the minimum cut is rarely one vertex) for the global cuts,
against the least maximum flow from the first vertex (and either way, directed), on both the
bucket queue and the heap. Another runs medium layered networks (50 – 226 vertices) built so that push–relabel
relabels past its global-relabel threshold and opens gaps (measured once with temporary counters:
88 of 120 runs relabel globally again, all 120 open a gap), against Edmonds–Karp written out. Stress values are
known by construction: a 5 · 10⁴-edge path (value 1, the last capacity-1 edge the cut), 300 disjoint
unit paths and K(150, 150)'s matching network (the sink alone on its side), a 150 × 150 grid (value
2), a seeded random network of 2,000 vertices checked by definition, C(600) and two K(30) joined by a
bridge for the undirected global cut, Cd(600) and two Kd(25) joined one way for the directed one, a path and a cycle for Gomory–Hu, Q(6), C(300), Cd(600), the bidirected
C(200) and K(40) for connectivity, an assignment whose only optimum is the identity, 200 parallel
routes, 500 negative 3-cycles and a 2,000-vertex chain for minimum cost. Each runs in a `Task` with
a one-minute limit.

In the property and stress files, conditions that contain a closure are computed into a named
constant before `#expect`: inside `propertyCheck`'s and `Task`'s closures, a closure in an `#expect`
expansion beside the capacity closures failed SIL verification ("function type mismatch") with the
toolchain this suite was written on.

The whole suite was run against a Swift model of api.md before the implementation existed (Dinic,
Edmonds–Karp and a FIFO push–relabel first phase with the canonical cut; Stoer–Wagner with a lazy
heap; Gusfield; successive shortest paths with Johnson potentials standing in for network simplex;
the split-network connectivity; built in a scratch copy of the workspace through Bazel, with
warnings as errors). That was the phase-1 suite; the Stoer–Wagner and cyclic-pair planted bugs
below tested rules api.md no longer pins. All 991 tests pass against it in about 12 seconds in a debug build. It was
also run against 32 planted bugs in that model, each of which fails tests (failing tests in
parentheses): the cut's search following residuals ≥ 0 (472), the source-side cut (153), residual rows in reverse position order (15), Edmonds–Karp by depth-first search (8), an undirected edge's flow on the wrong arc (40), self-loops asked for a capacity (4, then the model traps), no negative-capacity check (5), no infinity check (1), Stoer–Wagner ties to the greater index (11), the last least phase (17), the last vertex's component on a disconnected graph (1), the directed cyclic pairs reversed (5), the last least pair (7), Gusfield without the swap (18), the swap without exchanging the capacities (10), `minimumCut(between:and:)` at the least edge nearest v (7), zero-cost edges saturated like negative ones (4, then a timeout), the potentials negated (34), unbalanced supplies not nil (2), circulations not saturated when every supply is zero (9), parallel edges collapsed for λ (NetworkX's; 8), κ(s, t) without the edge s → t (21), an empty s–t vertex cut instead of nil (NetworkX's; 22), Even's directed pairs one way only (13), directed κ read on the underlying undirected graph (22), the value as the flow out of the source ignoring flow back into it (19, then the model traps), zero-capacity edges dropped from cuts (17), cuts listing edges back from the sink side (88), undirected cut arcs never reversed (62), the cost closure called twice (29), no source = sink check in `maximumFlowValue` and `minimumCut` (2), and Stoer–Wagner merging the last vertex into the first instead of the second-to-last (15).

## Files

| File | Tests | Covers |
|---|---|---|
| `MaximumFlowTests.swift` | 46 | §MaximumFlow (the MaximumFlow rows of FL-001 – FL-212): degenerate networks, no path, zero capacities, loops, parallel and antiparallel edges, CLRS, NetworkX's example, LCG networks, Double, Int8, UInt8 and Int.max totals, undirected graphs |
| `EdmondsKarpTests.swift` | 41 | §EdmondsKarp: the same networks, the per-edge flow exactly |
| `DinicTests.swift` | 40 | §Dinic |
| `MaximumFlowValueTests.swift` | 46 | §MaximumFlowValue |
| `MinimumCutTests.swift` | 39 | §MinimumCut: brute force over every s–t cut, the same `Cut` as every maximum flow's |
| `GlobalMinimumCutTests.swift` | 41 | §GlobalMinimumCut (FL-227 – FL-248, FL-492 – FL-494, FL-499, FL-500, FL-526, FL-528, FL-529), §DirectedGlobalMinimumCut (FL-250 – FL-257, FL-497, FL-498, FL-501) |
| `GomoryHuTreeTests.swift` | 19 | §GomoryHu (FL-258 – FL-273, FL-495, FL-496, FL-527) |
| `MinimumCostFlowTests.swift` | 34 | §MinimumCostFlow (FL-275 – FL-305, FL-488, FL-489, FL-491) |
| `MinimumCostMaximumFlowTests.swift` | 12 | §MinimumCostMaximumFlow (FL-308 – FL-318, FL-490) |
| `EdgeConnectivityTests.swift` | 55 | §EdgeConnectivity |
| `VertexConnectivityTests.swift` | 55 | §VertexConnectivity |
| `MinimumVertexCutTests.swift` | 55 | §MinimumVertexCut |
| `DisjointPathsTests.swift` | 24 | §EdgeDisjointPaths, §VertexDisjointPaths (FL-502 – FL-523, FL-530, FL-531) |
| `FlowsPreconditionTests.swift` | 34 | Exit tests: the 24 trap rows (FL-213 – FL-226, FL-249, FL-274, FL-306, FL-307, FL-319, FL-485 – FL-487, FL-524, FL-525), then 10 written by hand: the source as the sink on `Graph`; terminals not in the graph for every entry point, also without indices; negative capacities in every maximum flow and the directed global cut; NaN and infinity in the global cut, Gomory–Hu and Dinic; UInt8 and Double source sums past the type; `minimumCut(between:and:)` with u = v; a negative self-loop capacity in minimum-cost flow; `minimumCostMaximumFlow`'s capacity and cost checks; connectivity terminals; foreign positions and vertices on the results |
| `MaximumFlowRepresentationTests.swift`, `EdmondsKarpRepresentationTests.swift`, `DinicRepresentationTests.swift`, `MaximumFlowValueRepresentationTests.swift`, `MinimumCutRepresentationTests.swift` | 46, 41, 40, 46, 39 | Every flow, value and s–t cut row again on the other representations (Edmonds–Karp's flow recomputed on row-major positions) |
| `GlobalMinimumCutRepresentationTests.swift`, `GomoryHuTreeRepresentationTests.swift` | 41, 19 | Every global-cut and Gomory–Hu row again |
| `MinimumCostFlowRepresentationTests.swift` | 46 | Every minimum-cost row again (feasibility and the certificate where the flow is not unique) |
| `EdgeConnectivityRepresentationTests.swift`, `VertexConnectivityRepresentationTests.swift`, `MinimumVertexCutRepresentationTests.swift` | 55 each | Every connectivity row again |
| `DisjointPathsRepresentationTests.swift` | 24 | Every disjoint-path row again: the count, the ends, the disjointness |
| `FlowsConformanceTests.swift` | 16 | Equality of the four results, `Sendable`, descriptions, each result's own copy of the graph, generic code, `Collider` and `String` vertices, Int32, UInt16 and Float capacities, an undirected graph against its `directed` view, self-loops never asked, zero costs, Gomory–Hu lookups both ways, parallel edges kept apart, `flowMap`, the signed undirected flow, cut sides from index zero, unsigned minimum-cost capacities |
| `FlowsPropertyTests.swift` | 10 | PropertyBased with shrinking: directed and undirected maximum flows against brute force and Edmonds–Karp written out; floating capacities (eighths exact, integral Doubles integral); medium layered networks past push–relabel's global-relabel threshold, with gaps; global cuts against brute force, the cut's validity, the components rule and the least cyclic pair, in Int and Double; medium clustered global cuts (20 – 60 vertices) against the least maximum flow from the first vertex; Gomory–Hu against Gusfield written out and brute force; minimum-cost flow against a successive-shortest-path oracle; minimum-cost maximum flow; connectivity and disjoint paths by Menger |
| `FlowsStressTests.swift` | 8 | Inside a `Task` with a one-minute limit; see above |
| `UndirectedCapacityRangeTests.swift` | 3 | Int8 and UInt8 undirected capacities where twice a capacity overflows |

531 catalog rows (507 value rows, 24 trap rows), their 507 representation tests, and 47 more tests
(10 precondition, 16 conformance, 10 property, 8 stress, 3 capacity range): 1,085 tests in all.

## Case IDs

Case IDs (FL-001 … FL-531) refer to the catalog (`cases.md`), whose values `ref.py` computes with
api.md's models and checks against NetworkX 3.7 (`maximum_flow_value` under all five `flow_func`s,
`minimum_cut`, `stoer_wagner`, `gomory_hu_tree`, `network_simplex`, `capacity_scaling`,
`max_flow_min_cost`, `node_connectivity`, `edge_connectivity`, `edge_disjoint_paths`,
`node_disjoint_paths`), igraph 1.0 (`maxflow`, `mincut`, `vertex_connectivity`,
`edge_connectivity`, `edge_disjoint_paths`, `vertex_disjoint_paths`), rustworkx 0.18.1 (`stoer_wagner_min_cut`) and brute
force. Each test's name starts with its ID; tests without an ID check conventions, properties or
scale that the catalog does not list.

| Cases | Section | File |
|---|---|---|
| FL-001 – FL-212, by group | MaximumFlow, EdmondsKarp, Dinic, MaximumFlowValue, MinimumCut | `MaximumFlowTests.swift`, `EdmondsKarpTests.swift`, `DinicTests.swift`, `MaximumFlowValueTests.swift`, `MinimumCutTests.swift` |
| FL-213 – FL-226, FL-249, FL-274, FL-306, FL-307, FL-319, FL-485 – FL-487, FL-524, FL-525 | Preconditions | `FlowsPreconditionTests.swift` |
| FL-227 – FL-248, FL-250 – FL-257, FL-492 – FL-494, FL-497 – FL-501, FL-526, FL-528, FL-529 | GlobalMinimumCut, DirectedGlobalMinimumCut | `GlobalMinimumCutTests.swift` |
| FL-258 – FL-273, FL-495, FL-496, FL-527 | GomoryHu | `GomoryHuTreeTests.swift` |
| FL-275 – FL-305, FL-488, FL-489, FL-491 | MinimumCostFlow | `MinimumCostFlowTests.swift` |
| FL-308 – FL-318, FL-490 | MinimumCostMaximumFlow | `MinimumCostMaximumFlowTests.swift` |
| FL-320 – FL-484, by group | VertexConnectivity, MinimumVertexCut, EdgeConnectivity | `VertexConnectivityTests.swift`, `MinimumVertexCutTests.swift`, `EdgeConnectivityTests.swift` |
| FL-502 – FL-523, FL-530, FL-531 | EdgeDisjointPaths, VertexDisjointPaths | `DisjointPathsTests.swift` |
| every row but the traps | Every non-trap row again | the twelve `…RepresentationTests.swift` files, one per section |

## Readings of what api.md leaves open

| Question | Reading taken | Where |
|---|---|---|
| The capacity closure for the global cut and Gomory–Hu | Once per non-loop edge in position order, as for the maximum flows (api.md states it in the maximum-flow preamble and Semantics) | `GlobalMinimumCutTests.swift`, `GomoryHuTreeTests.swift` |
| The closures of `minimumCostFlow` when it returns nil | `supply` once per vertex in order all the same; `capacity` and `cost` at most once per edge, in order (a solver may stop at unbalanced supplies) | nil rows in `MinimumCostFlowTests.swift` |
| The closures of `minimumCostMaximumFlow` | Not counted: it is a maximum flow, then `minimumCostFlow`, and may read a capacity twice | `MinimumCostMaximumFlowTests.swift` |
| Floating values "as computed" | Within 1e-12 for values and flows on rows whose capacities are not multiples of 1/1024 (FL-151 – FL-155); the cut's sides and edges exact there, and everything exact on dyadic rows | FL-151 – FL-155 |
| The finiteness test | `c - c == .zero`: true for every finite value, false for infinities and NaN, and it never overflows, so it applies to every type (FL-161's 2⁶² capacities do not trap) | FL-161 – FL-163, FL-223 |
| `GomoryHuTree.tree` edge orientation | Not pinned: edge k is the pair {vertex k + 1, its parent}, either way round | `GomoryHuTreeTests.swift` |
| `GomoryHuTree.tree` vertex order | The graph's `vertices` order | `GomoryHuTreeTests.swift`, `gomoryHu` |
| An undirected graph's `directed` view | The same values, cut sides and cut edges as the undirected entry points (each edge two arcs of the same capacity); the global cut value and the connectivity too | `undirectedAgainstDirectedView` |
| Lookups with a position or vertex the graph does not have | Trap (`flow(ofEdgeAt:)`, `MinimumCostFlow.flow(ofEdgeAt:)`, `potential(of:)`) | `foreignLookups` |
| A negative capacity on a self-loop | Traps in `minimumCostFlow` (loops carry flow there); never asked by the maximum flows | `minimumCostMoreTraps`, `loopsNeverAsked` |
| The solver's artificial cost, (n + 1)(the greatest \|cost\| + 1) | Not a precondition on the cost type (it is computed in `Int` and never reported); only 4 × it must fit in `Int` | FL-491 |
| Which global minimum cut among several | Not pinned (api.md): any minimum cut, the same on a second call; on `Graph` the first vertex on its source side | `GlobalMinimumCutTests.swift`, `globalCuts` |
| Equality | On values: two calls on equal inputs are equal; another capacity or terminal differs | `equality` |
| `description` | Not pinned; only that it is not empty | `descriptions` |

## Not tested

| Case | Why |
|---|---|
| Which maximum flow push–relabel and Dinic return, phase 2's push–relabel toward the source | Unspecified by design; the tests check feasibility, the value and the cut from each flow's residual network |
| The gap and global-relabelling heuristics, block-search pivots, strongly feasible trees, current-arc pointers, Nagamochi–Ibaraki's bucket queue and contractions, Hao–Orlin's dormant sets | Internal; their effect is only speed. The medium-network property reaches the push–relabel heuristics' code; mutation testing (`just mutate Flows`) and the benchmarks cover the rest |
| Complexity bounds (O(n² √m), O(nm log n), O(n²m), Dinic's unit-network bound) | Benchmarks; the stress tests bound costs loosely |
| `GomoryHuTree.minimumCutValue(between: u, and: u)` | api.md leaves it open (only `minimumCut(between:and:)` states u ≠ v) |
| Overflow inside undirected residuals (c + f up to 2c for an Int8 edge above 63) | api.md says a residual is at most its edge's capacity, which holds for directed edges only; no catalog row exercises it |
| NetworkX's, igraph's and rustworkx's outputs on random graphs (`just diff`) | Not Swift tests; `ref.py` checks every catalog row and its `--stress` networks against them |
| Floating-point minimum-cost flow, infeasibility witnesses, UNBALANCED told apart from INFEASIBLE, lower bounds and GEQ/LEQ supplies, the source-minimal cut, Boykov–Kolmogorov | Phase 2 or later (api.md, open questions 3 – 6a) |
| Residual arc counts of 2³¹ or more | The precondition exists (every network checks its arc count) but no test can build such a network |
