# Flows: proposed API (phase 1)

Maximum flows, minimum cuts, Gomory–Hu trees, minimum-cost flows, and the flow-based edge and
vertex connectivity that the README moved out of `Connectivity`. Capacities, costs and supplies are
closures, as README open question 3 decided for weights; nothing is stored in the graph.

* **Maximum flow.** `maximumFlow(from:to:capacity:)` (highest-label push–relabel with the gap and
  global-relabelling heuristics: Boost's, LEMON's and NetworkX's default family),
  `maximumFlowValue(from:to:capacity:)` (its first phase only), and the named
  `edmondsKarpMaximumFlow` and `dinicMaximumFlow`. All return the same value and the same canonical
  minimum cut; only Edmonds–Karp's per-edge flow is pinned.
* **Minimum cut.** `minimumCut(from:to:capacity:)` (s–t), and `minimumCut(capacity:)` without
  terminals: Nagamochi–Ibaraki on `Graph`, Hao–Orlin on `DirectedGraph` (LEMON's two).
* **Gomory–Hu tree.** `gomoryHuTree(capacity:)` on `Graph`: Gusfield's algorithm, the same tree
  as NetworkX's `gomory_hu_tree` edge for edge.
* **Minimum-cost flow.** `minimumCostFlow(supply:capacity:cost:)` (network simplex) and
  `minimumCostMaximumFlow(from:to:capacity:cost:)`, on `DirectedGraph`, integer capacities and
  costs; nil when the supplies cannot be met.
* **Connectivity.** `edgeConnectivity()`, `vertexConnectivity()`, `minimumVertexCut()` and their
  s–t forms, on both kinds of graph; `edgeDisjointPaths(from:to:)` and
  `vertexDisjointPaths(from:to:)`, Menger's witnesses.
* **Results.** `Flow`, `Cut`, `GomoryHuTree`, `MinimumCostFlow`, and `FlowMap`, every edge's flow
  by position.

`cases.md` (FL-001 – FL-531, 531 cases; FL-488 on were added after the critical review) pins the values; `ref.py` recomputes every row from small
models of this API and checks it independently, then renders the catalog and compares it with
`cases.md` byte for byte. Each maximum-flow row runs Edmonds–Karp, Dinic and a FIFO push–relabel
model, which agree on the value and on the canonical cut (computed from each one's residual
network, and from push–relabel's phase-1 preflow, which is the claim that lets
`maximumFlowValue` and the cut skip phase 2). The cut is also brute-forced over every s–t cut when
n ≤ 12, and it equals NetworkX 3.7 `minimum_cut`'s partition and igraph 1.0 `maxflow`'s partition on
every row. Values equal NetworkX `maximum_flow_value` under all five of its `flow_func`s. Global
cut values equal brute force, NetworkX `stoer_wagner`, rustworkx 0.18.1 `stoer_wagner_min_cut`
and igraph `mincut`; a global cut's sides are pinned only where the minimum cut is unique (or by
the components rule), and brute force finds which rows those are. Gomory–Hu trees equal NetworkX's exactly, and every tree edge is checked to be a
minimum cut by brute force. Minimum costs equal a successive-shortest-path model, NetworkX
`network_simplex` and `capacity_scaling`, `max_flow_min_cost`, and brute force over integer flows
where small; uniqueness of each displayed flow is decided by re-solving with each edge forced one
unit up and down. Connectivity equals brute force over removed sets, NetworkX and igraph. `--stress`
adds 600 random flow networks (all of the above per network), 185 random Gomory–Hu trees against
NetworkX, and 400 random minimum-cost problems against brute force and NetworkX; all pass. Run
`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1
python3 Tests/Catalogs/Flows/ref.py [--stress] [--write]` (seconds).

## FlowNetworks: no stored type (decision proposed)

The README's Structures table has `FlowNetwork<Base, Capacity>`, "a digraph with capacity
c : A → ℝ≥0, a source s, and a sink t", with the residual network as a view of it. **Proposed:
drop it, and with it the `FlowNetworks` module.**

* Open question 3 decided that weights are passed as non-escaping closures over edge positions and
  never stored, because a closure over a dense position is an array read (Dijkstra at 1.02–1.08×
  hand-written). Capacities are weights by another name. A stored `FlowNetwork` would hold an
  escaping closure or a copied capacity array, which is the design question 3 rejected, and it
  would fix one source and sink when Gomory–Hu, connectivity and global cuts run many s–t pairs on
  one graph.
* No library in the survey has the type. NetworkX takes `(G, s, t, capacity="capacity")`, Boost
  `(g, s, t, capacity_map, residual_capacity_map, reverse_edge_map)`, LEMON `Preflow(digraph,
  capacityMap, s, t)`, JGraphT `getMaximumFlow(source, sink)` on a weighted graph, igraph
  `maxflow(source, target, capacity)`, OR-Tools adds arcs to a solver. "Flow network" is the
  mathematical object (CLRS 26.1), not a library type.
* The residual network cannot be a useful public view: algorithms need it as index-space arrays
  with paired reverse arcs (below), not as a `DirectedGraph` conformer; NetworkX's
  `build_residual_network` and its `residual=` parameter exist only for reuse across calls, which
  here is internal (Gomory–Hu, connectivity).
* What would remain for the module is the result types, and results live with their algorithms
  (`Matching` in MatchingModule, `Coloring` in ColoringModule).

So `Flows` depends on `GraphProtocols` and `Trees` (`GomoryHuTree.tree`) only, and
`scripts/modules.py` loses `FlowNetworks` (open question 1). If the user wants the module kept, the
alternative is a public `ResidualNetwork` there for callers who run their own augmenting
algorithms; no surveyed library except Boost (residual capacity maps) exposes one.

## Scope

**In, phase 1**

| Entry point | On | Traces |
|---|---|---|
| `maximumFlow(from:to:capacity:)` | both | NetworkX `maximum_flow` (default `preflow_push`), igraph `Graph.maxflow`, JGraphT `MaximumFlowAlgorithm.getMaximumFlow`, Boost `push_relabel_max_flow`, LEMON `Preflow`, OR-Tools `SimpleMaxFlow::Solve` (push–relabel) |
| `maximumFlowValue(from:to:capacity:)` | both | NetworkX `maximum_flow_value`, igraph `maxflow_value`, JGraphT `getMaximumFlowValue`, LEMON `Preflow::runMinCut` + `flowValue` |
| `edmondsKarpMaximumFlow(from:to:capacity:)` | both | Boost `edmonds_karp_max_flow`, NetworkX `edmonds_karp`, JGraphT `EdmondsKarpMFImpl`, LEMON `EdmondsKarp`, petgraph `ford_fulkerson` (BFS augmenting paths, so Edmonds–Karp) |
| `dinicMaximumFlow(from:to:capacity:)` | both | JGraphT `DinicMFImpl`, petgraph `dinics`, NetworkX `dinitz`; the README's "Dinic" |
| `minimumCut(from:to:capacity:)` | both | NetworkX `minimum_cut`, igraph `mincut(source, target)` / `st_mincut`, JGraphT `MinimumSTCutAlgorithm.calculateMinCut`, OR-Tools `GetSinkSideMinCut` |
| `minimumCut(capacity:)` | `Graph` | LEMON `NagamochiIbaraki` (our algorithm); igraph `mincut()` with no terminals (Stoer–Wagner for undirected); NetworkX `stoer_wagner`, Boost `stoer_wagner_min_cut`, JGraphT `StoerWagnerMinimumCut`, rustworkx `stoer_wagner_min_cut` (the same value) |
| `minimumCut(capacity:)` | `DirectedGraph` | LEMON `HaoOrlin` (our algorithm), igraph `mincut()` on a directed graph |
| `gomoryHuTree(capacity:)` | `Graph` | NetworkX `gomory_hu_tree`, igraph `gomory_hu_tree`, JGraphT `GusfieldGomoryHuCutTree`, LEMON `GomoryHu` |
| `minimumCostFlow(supply:capacity:cost:)` | `DirectedGraph` | NetworkX `min_cost_flow` / `network_simplex`, LEMON `NetworkSimplex`, OR-Tools `SimpleMinCostFlow::Solve`, JGraphT `MinimumCostFlowAlgorithm` |
| `minimumCostMaximumFlow(from:to:capacity:cost:)` | `DirectedGraph` | NetworkX `max_flow_min_cost`, OR-Tools `SolveMaxFlowWithMinCost`, Boost `successive_shortest_path_nonnegative_weights` and `cycle_canceling` ("minimum cost maximum flow" in Boost's docs) |
| `edgeConnectivity()`, `edgeConnectivity(from:to:)` | both | NetworkX `edge_connectivity`, igraph `edge_connectivity` (`adhesion`), Boost `edge_connectivity`, Mathematica `EdgeConnectivity` |
| `vertexConnectivity()`, `vertexConnectivity(from:to:)` | both | igraph `vertex_connectivity` (`cohesion`), NetworkX `node_connectivity`, Mathematica `VertexConnectivity` |
| `minimumVertexCut()`, `minimumVertexCut(from:to:)` | both | NetworkX `minimum_node_cut`, Mathematica `FindVertexCut` |
| `edgeDisjointPaths(from:to:)`, `vertexDisjointPaths(from:to:)` | both | NetworkX `edge_disjoint_paths`, `node_disjoint_paths`; igraph `edge_disjoint_paths`, `vertex_disjoint_paths` (their counts) |
| `Flow`, `Cut`, `GomoryHuTree`, `MinimumCostFlow`, `FlowMap` | — | igraph `Flow` (a `Cut` with `flow`, `value`, `partition`), JGraphT `MaximumFlow` (`getValue`, `getFlowMap`), JGraphT `GusfieldGomoryHuCutTree`, LEMON `NetworkSimplex` (`flow`, `totalCost`, `potential`), LEMON `flowMap` |

**NetworkX functions, and where each goes**

| NetworkX | Here | Reason |
|---|---|---|
| `maximum_flow`, `maximum_flow_value` | `maximumFlow`, `maximumFlowValue` | In. Same value on every row under all five `flow_func`s |
| `flow_func=edmonds_karp`, `dinitz` | `edmondsKarpMaximumFlow`, `dinicMaximumFlow` | In, as named functions (house style: `dijkstraShortestPaths`, `bellmanFordShortestPaths`) |
| `flow_func=preflow_push` | `maximumFlow` | The default; no second name for it |
| `flow_func=shortest_augmenting_path`, `boykov_kolmogorov` | — | Phase 2 if asked. Boykov–Kolmogorov wins on vision grids only; shortest augmenting path is dominated by Dinic |
| `minimum_cut`, `minimum_cut_value` | `minimumCut(from:to:capacity:)`, its `value` | In; the same partition on every row (sink side minimal) |
| `stoer_wagner` | `minimumCut(capacity:)` on `Graph` | In, by Nagamochi–Ibaraki: the same value, one of the minimum cuts. NetworkX raises on a disconnected graph; we return the zero cut (FL-231 – FL-233) |
| `gomory_hu_tree` | `gomoryHuTree(capacity:)` | In; the same tree |
| `min_cost_flow`, `min_cost_flow_cost`, `network_simplex`, `capacity_scaling`, `cost_of_flow` | `minimumCostFlow(supply:capacity:cost:)`, its `cost` | In, network simplex only; `cost_of_flow` is the result's `cost` |
| `max_flow_min_cost` | `minimumCostMaximumFlow` | In, the same definition (circulations included, FL-313) |
| `edge_connectivity`, `local_edge_connectivity`, `minimum_edge_cut`, `minimum_st_edge_cut` | `edgeConnectivity()`, `edgeConnectivity(from:to:)`; the cut is `minimumCut(capacity: { _ in 1 })` / `minimumCut(from:to:capacity: { _ in 1 })` | In; no separate edge-cut name, since a unit-capacity minimum cut is one |
| `node_connectivity`, `local_node_connectivity`, `minimum_node_cut`, `minimum_st_node_cut` | `vertexConnectivity`, `minimumVertexCut` (both forms) | In; "vertex" per the README's terminology |
| `edge_disjoint_paths`, `node_disjoint_paths` | `edgeDisjointPaths(from:to:)`, `vertexDisjointPaths(from:to:)` | In: Menger's witnesses, a path decomposition of a unit flow; "vertex" per the terminology table |
| `all_node_cuts` (Kanevsky) | — | Phase 2 or never |
| `build_residual_network`, `residual=`, `cutoff=`, `two_phase=`, `global_relabel_freq=` | — | Internal. `cutoff` (stop at a value) is used inside connectivity; public later if asked |

**Other libraries**

| Library | Functions | Here |
|---|---|---|
| Boost | `edmonds_karp_max_flow`, `push_relabel_max_flow`, `boykov_kolmogorov_max_flow`, `cycle_canceling`, `successive_shortest_path_nonnegative_weights`, `find_flow_cost`, `stoer_wagner_min_cut`, `edge_connectivity` | Edmonds–Karp, push–relabel, the global cut (`stoer_wagner_min_cut`'s value, by Nagamochi–Ibaraki), edge connectivity in; min-cost max flow by network simplex instead of SSP / cycle cancelling; Boykov–Kolmogorov later |
| LEMON | `Preflow`, `EdmondsKarp`, `NetworkSimplex`, `CostScaling`, `CapacityScaling`, `CycleCanceling`, `GomoryHu`, `HaoOrlin`, `NagamochiIbaraki`, `Circulation` | `Preflow`'s design is ours (two phases, cut after the first); `NetworkSimplex` ours (block search, `potential`, `flowMap`); `NagamochiIbaraki` and `HaoOrlin` ours for the global cuts; the other min-cost algorithms and `Circulation` later |
| JGraphT | `EdmondsKarpMFImpl`, `PushRelabelMFImpl`, `DinicMFImpl`, `BoykovKolmogorovMFImpl`, `GusfieldGomoryHuCutTree`, `GusfieldEquivalentFlowTree`, `StoerWagnerMinimumCut`, `CapacityScalingMinimumCostFlow` | All in by function except Boykov–Kolmogorov and the equivalent flow tree (a Gomory–Hu tree is one). `KolmogorovWeightedPerfectMatching` (the class is not "…MinimumCostPerfectMatching") belongs to MatchingModule |
| igraph | `maxflow`, `maxflow_value`, `mincut`, `mincut_value`, `st_mincut`, `all_st_cuts`, `all_st_mincuts`, `gomory_hu_tree`, `edge_connectivity`, `vertex_connectivity`, `adhesion`, `cohesion`, `edge_disjoint_paths`, `vertex_disjoint_paths`, `dominator` | In except the cut enumerations (Provan–Shier, phase 2); igraph's disjoint paths are counts, ours the paths; `dominator` is Connectivity's `dominatorTree` |
| OR-Tools | `SimpleMaxFlow` (`AddArcWithCapacity`, `Solve`, `OptimalFlow`, `Flow`, `GetSourceSideMinCut`, `GetSinkSideMinCut`), `SimpleMinCostFlow` (`SetNodeSupply`, `Solve` → `OPTIMAL` / `INFEASIBLE` / `UNBALANCED`, `OptimalCost`, `SolveMaxFlowWithMinCost`) | In by function. OR-Tools exposes both minimum cuts; we expose the sink-side one (open question 3) |
| petgraph | `ford_fulkerson`, `dinics` | Both in by function |
| rustworkx | `stoer_wagner_min_cut` | In; no flows in rustworkx |

**Also out**

| Not in phase 1 | Reason |
|---|---|
| A stored `FlowNetwork` | See above (open question 1) |
| Plain Ford–Fulkerson with depth-first augmenting paths | May not terminate with irrational capacities (Zwick 1995) and is exponential in the capacities otherwise. petgraph's `ford_fulkerson` is BFS, i.e. Edmonds–Karp |
| Boykov–Kolmogorov, shortest augmenting path, MPM | Phase 2 if benchmarks or users ask (vision grids) |
| Capacity scaling, cost scaling, cycle cancelling, successive shortest paths as named min-cost functions | Phase 2. Network simplex is LEMON's recommendation and NetworkX's default; cost scaling wins only on large sparse instances (Király–Kovács 2012) |
| Floating-point capacities or costs in minimum-cost flow | Phase 2 (open question 4). Network simplex is exact only in exact arithmetic; NetworkX warns that floats may fail; OR-Tools takes only integers |
| Minimum-cost flow on `Graph` | Out, as NetworkX (`not_implemented_for("undirected")`) and LEMON. `graph.directed` gives each edge two independent arcs of capacity c, which is the usual reduction only when costs are nonnegative |
| Lower bounds on edges (LEMON `lowerMap`), circulations (LEMON `Circulation`) | Phase 2. A lower bound l on u→v is supply(u) − l, supply(v) + l and capacity c − l, written in the doc comment |
| Vertex capacities | A recipe, not an API (no surveyed library has one): split v into v_in → v_out with capacity cap(v). `vertexConnectivity` does it internally |
| Unbounded min-cost problems | Cannot occur: capacities are finite by precondition. NetworkX's `NetworkXUnbounded` comes from infinite capacities |
| Karger's randomized minimum cut (README Flows row) | Out. Nagamochi–Ibaraki is exact, deterministic and O(nm log n) at worst (near LEMON's speed here); Karger–Stein is a Monte Carlo algorithm with no advantage at our sizes. Proposed README edit removes it |
| All s–t cuts, all minimum s–t cuts | Phase 2 |
| A flow checker (`isFlow`) | Out. Tests check capacity and conservation inline; no surveyed library has one |
| Flow decomposition into paths and cycles | Phase 2 (the disjoint paths decompose unit flows only) |
| The source-side minimal cut, lower bounds and GEQ/LEQ supply types, telling UNBALANCED apart from INFEASIBLE, floating-point minimum-cost flow, an infeasibility witness | Phase 2, deferred after the critical review (open questions 3 – 5) |

## Summary

```swift
import GraphProtocols
import Trees
import Walks

extension DirectedGraph {
    // Maximum flow. `capacity` is called once per non-loop edge, in position order, before any
    // work; self-loops carry no flow and are never asked. Capacities are at least zero, not NaN,
    // finite, and the capacities of the edges out of `source` sum to a value that fits in C.

    /// A maximum flow from `source` to `sink`: highest-label push–relabel with the gap and global
    /// relabelling heuristics (Goldberg–Tarjan; Cherkassky–Goldberg), in two phases as LEMON's
    /// `Preflow`. O(n² √m). Which maximum flow is returned is unspecified; `value` and
    /// `minimumCut` are not.
    public func maximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Flow<Self, C>

    /// The maximum flow value: push–relabel's first phase only (a maximum preflow). O(n² √m).
    public func maximumFlowValue<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> C

    /// A maximum flow by Edmonds–Karp: shortest augmenting paths by breadth-first search,
    /// residual arcs in edge-position order, stopping when the sink is discovered (the algorithm
    /// of Boost `edmonds_karp_max_flow`, whose search runs to completion before augmenting). The
    /// flow is pinned by that procedure. O(n m²).
    public func edmondsKarpMaximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Flow<Self, C>

    /// A maximum flow by Dinic's blocking flows with current-arc pointers. O(n² m); O(m √n) on unit
    /// networks (one in- or out-arc of capacity 1 per inner vertex), O(m min(√m, n^(2/3))) with
    /// unit capacities. Push–relabel is the default because of measured cases such as DIMACS
    /// genrmf-long (8 × 8 × 256): 223 ms here against push–relabel's 5 ms.
    public func dinicMaximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Flow<Self, C>

    /// The canonical minimum s–t cut: its sink side is every vertex that can still reach `sink` in
    /// the residual network of a maximum flow, the least sink side of any minimum cut (NetworkX
    /// `minimum_cut`, igraph `mincut`; OR-Tools `GetSinkSideMinCut`). Push–relabel's first phase
    /// suffices. O(n² √m).
    public func minimumCut<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Cut<Self, C>

    /// A minimum cut over all nonempty proper vertex sets S (capacity of the edges leaving S), by
    /// Hao–Orlin (LEMON `HaoOrlin`): one push–relabel run moving the sink, then the same on the
    /// reversed graph. A minimum cut, deterministic; which one among several is not specified.
    /// nil below two vertices. Sums formed wider than C; the cut's value must fit. O(n²m).
    public func minimumCut<C: Comparable & AdditiveArithmetic>(capacity: (Edges.Index) -> C) -> Cut<Self, C>?

    // Minimum-cost flow. Integer capacities, supplies and costs; exact.

    /// A least-cost flow meeting every supply (positive: the vertex sends that much more than it
    /// receives; negative: a demand), within capacities (LEMON `NetworkSimplex`, OR-Tools
    /// `SimpleMinCostFlow`), or nil when there is none: the supplies do not sum to zero, or some set
    /// of vertices supplies more than its out-edges carry. Costs may be negative; negative cycles
    /// are saturated (capacities are finite). A self-loop carries its capacity when its cost is
    /// negative and nothing otherwise. Network simplex with block-search pivots and strongly
    /// feasible trees (Cunningham), LEMON's layout. `supply` is called once per vertex, `capacity`
    /// and `cost` once per edge, in order. Capacities may be unsigned; any up to Int.max works.
    public func minimumCostFlow<S: SignedInteger, C: BinaryInteger, W: SignedInteger>(
        supply: (Vertex) -> S, capacity: (Edges.Index) -> C, cost: (Edges.Index) -> W
    ) -> MinimumCostFlow<Self, C, W>?

    /// The least-cost flow among the maximum flows from `source` to `sink`, circulations
    /// included (NetworkX `max_flow_min_cost`, OR-Tools `SolveMaxFlowWithMinCost`): the maximum
    /// flow value, then `minimumCostFlow` with that supply at `source` and demand at `sink`.
    public func minimumCostMaximumFlow<C: BinaryInteger, W: SignedInteger>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C, cost: (Edges.Index) -> W
    ) -> MinimumCostFlow<Self, C, W>

    // Connectivity, on the graph's edges (unit capacities): parallel edges count for edge
    // connectivity, self-loops never count, and vertex connectivity reads the simple graph.

    /// λ(G): the fewest edges whose removal leaves the graph not strongly connected; 0 below two
    /// vertices. `minimumCut(capacity: { _ in 1 })` gives a cut.
    public func edgeConnectivity() -> Int
    /// The most edge-disjoint paths from `source` to `target`, the fewest edges separating them.
    public func edgeConnectivity(from source: Vertex, to target: Vertex) -> Int
    /// κ(G): the fewest vertices whose removal leaves the graph not strongly connected or with one
    /// vertex; n − 1 for a complete digraph, 0 below two vertices or when not strongly connected.
    public func vertexConnectivity() -> Int
    /// The most internally vertex-disjoint paths from `source` to `target`; an edge source→target
    /// counts as one path (NetworkX).
    public func vertexConnectivity(from source: Vertex, to target: Vertex) -> Int
    /// A minimum vertex cut, in `vertices` order: Even's pairs (api.md, Determinism); the vertices
    /// after the first for a complete digraph; empty when κ = 0.
    public func minimumVertexCut() -> [Vertex]
    /// The minimum source–target vertex cut nearest `target`, or nil when an edge goes from
    /// `source` to `target` (no vertex set separates them).
    public func minimumVertexCut(from source: Vertex, to target: Vertex) -> [Vertex]?

    /// λ(s, t) edge-disjoint paths from `source` to `target` (NetworkX `edge_disjoint_paths`): a
    /// unit maximum flow by Dinic, decomposed into simple paths (flow cycles dropped). Which paths
    /// is not specified; deterministic. Traps when source = target.
    public func edgeDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, Edges.Index>]
    /// κ(s, t) internally vertex-disjoint paths (NetworkX `node_disjoint_paths`): the split
    /// network's unit flow, decomposed; an edge source → target is one path (the first in
    /// position order, listed last). Traps when source = target.
    public func vertexDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, Edges.Index>]
}

extension Graph {
    // The same maximum-flow, s–t cut and connectivity entry points. Each edge carries up to its
    // capacity in either direction (one capacity shared by both: |f| ≤ c). Results are over
    // `directed` (`DirectedView`), as ShortestPaths' are: an edge's flow is on the arc of its
    // direction, and a cut edge is the arc from the source side to the sink side.
    public func maximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Flow<DirectedView<Self>, C>
    public func maximumFlowValue<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> C
    public func edmondsKarpMaximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Flow<DirectedView<Self>, C>
    public func dinicMaximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Flow<DirectedView<Self>, C>
    public func minimumCut<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Cut<DirectedView<Self>, C>

    /// A global minimum cut by Nagamochi–Ibaraki (LEMON `NagamochiIbaraki`; the value of NetworkX
    /// `stoer_wagner`, Boost `stoer_wagner_min_cut`): a minimum cut whose source side holds the
    /// first vertex, deterministic, which one among several not specified; nil below two vertices.
    /// When the edges of positive capacity do not connect the graph, the cut of value 0 whose
    /// source side is the first vertex's component. Parallel capacities add; self-loops are
    /// ignored. Sums formed wider than C; the cut's value must fit. O(nm log n) in the worst case.
    public func minimumCut<C: Comparable & AdditiveArithmetic>(capacity: (Edges.Index) -> C) -> Cut<DirectedView<Self>, C>?

    /// A Gomory–Hu cut tree: every pair's minimum cut value is the least capacity on its tree path,
    /// and every tree edge splits the vertices into a minimum cut between its ends. Gusfield's
    /// algorithm with the canonical cut, vertices in order, rooted at the first: the same tree as
    /// NetworkX `gomory_hu_tree`. nil for the empty graph. n − 1 maximum flows.
    public func gomoryHuTree<C: Comparable & AdditiveArithmetic>(capacity: (Edges.Index) -> C) -> GomoryHuTree<Self, C>?

    public func edgeConnectivity() -> Int
    public func edgeConnectivity(from source: Vertex, to target: Vertex) -> Int
    public func vertexConnectivity() -> Int
    public func vertexConnectivity(from source: Vertex, to target: Vertex) -> Int
    public func minimumVertexCut() -> [Vertex]
    public func minimumVertexCut(from source: Vertex, to target: Vertex) -> [Vertex]?
    /// Over `directed`: each edge an arc in the direction the path uses it.
    public func edgeDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, DirectedView<Self>.Edges.Index>]
    public func vertexDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, DirectedView<Self>.Edges.Index>]
}

/// A flow from `source` to `sink` (igraph `Flow`, JGraphT `MaximumFlow`). Keeps a copy of the
/// graph for lookups (copy-on-write, O(1)), as `Coloring` and `ShortestPathTree` do.
@frozen
public struct Flow<G: DirectedGraph, Capacity: Comparable & AdditiveArithmetic>: Equatable {
    public var source: G.Vertex { get }
    public var sink: G.Vertex { get }
    /// The net flow out of the source.
    public var value: Capacity { get }
    /// The flow on the edge at `position`: O(1) with edge indices. Zero on a self-loop.
    public func flow(ofEdgeAt position: G.Edges.Index) -> Capacity
    /// The canonical minimum cut, from this flow's residual network (computed with the flow).
    public var minimumCut: Cut<G, Capacity> { get }
    /// Every edge's flow by position, in `edges` order (LEMON `flowMap`, JGraphT `getFlowMap`),
    /// over the flow's own storage.
    public var flowMap: FlowMap<G, Capacity> { get }
    /// On a flow over `directed`: the signed flow of the undirected edge at `position`, positive
    /// along its stored orientation (igraph's signed `Flow.flow` on undirected graphs).
    public func flow<Base: Graph>(ofEdgeAt position: Base.Edges.Index) -> Capacity
        where G == DirectedView<Base>, Capacity: SignedNumeric
}

/// Every edge's flow, a collection indexed by the graph's edge positions (LEMON `flowMap`).
@frozen
public struct FlowMap<G: DirectedGraph, Value>: Collection {
    public subscript(position: G.Edges.Index) -> Value { get }
}

/// A cut: the vertices split into a source side and a sink side, and the edges from the first to
/// the second (OR-Tools source-side and sink-side cuts; JGraphT `getSourcePartition`,
/// `getSinkPartition`, `getCutEdges`; igraph `Cut.partition`, `Cut.cut`).
@frozen
public struct Cut<G: DirectedGraph, Capacity: Comparable & AdditiveArithmetic>: Equatable {
    /// The capacity of `edges`, the cut's value.
    public var value: Capacity { get }
    /// The vertices on each side, in `vertices` order, each an array from index zero.
    public var sourceSide: [G.Vertex] { get }
    public var sinkSide: [G.Vertex] { get }
    /// Every edge from the source side to the sink side, zero capacities included, in position
    /// order. Edges back from the sink side are not part of the cut.
    public var edges: [G.Edges.Index] { get }
}

/// A Gomory–Hu tree (JGraphT `GusfieldGomoryHuCutTree`, LEMON `GomoryHu`).
@frozen
public struct GomoryHuTree<G: Graph, Capacity: Comparable & AdditiveArithmetic> {
    /// The tree on the graph's vertices. The edge at position k joins the vertex at index k + 1 to
    /// its parent toward the first vertex.
    public var tree: Tree<G.Vertex> { get }
    /// The capacity of the tree edge at `position`: the minimum cut value between its ends.
    public func capacity(ofEdgeAt position: Int) -> Capacity
    /// The least capacity on the tree path, the minimum cut value between `u` and `v`. O(n).
    public func minimumCutValue(between u: G.Vertex, and v: G.Vertex) -> Capacity
    /// The split at the least edge on the tree path (nearest `u` among equals), `u` on the source
    /// side, with the graph's crossing edges. O(n + m). Precondition: u ≠ v.
    public func minimumCut(between u: G.Vertex, and v: G.Vertex) -> Cut<DirectedView<G>, Capacity>
}

/// A minimum-cost flow (LEMON `NetworkSimplex`: `flow`, `totalCost`, `potential`).
@frozen
public struct MinimumCostFlow<G: DirectedGraph, Capacity: BinaryInteger, Cost: SignedInteger>: Equatable {
    /// The total cost, Σ flow × cost.
    public var cost: Cost { get }
    /// The amount shipped: the sum of the positive supplies; for `minimumCostMaximumFlow`, the
    /// maximum flow value.
    public var value: Capacity { get }
    public func flow(ofEdgeAt position: G.Edges.Index) -> Capacity
    public var flowMap: FlowMap<G, Capacity> { get }
    /// The optimal dual: every edge with positive residual has reduced cost
    /// cost + potential(u) − potential(v) ≥ 0 forward (and ≤ 0 for flow it can give back), the
    /// optimality certificate. Not unique. At most big M + n × the greatest |cost| in magnitude,
    /// big M = (n + 1)(the greatest |cost| + 1): O(n × the greatest |cost|); traps when it does
    /// not fit in Cost.
    public func potential(of vertex: G.Vertex) -> Cost
}
```

Conformances: `Flow`, `Cut` and `MinimumCostFlow` are `Equatable` on their values (not the graph),
`Sendable` when the graph, vertex, position and value types are; `GomoryHuTree` is `Equatable` on
its tree and capacities. `CustomStringConvertible` on all four.

**Named functions, not an algorithm enum.** ColoringModule used one entry point with a strategy
enum because every strategy only produces an order for the same first-fit pass. The maximum-flow
algorithms share nothing but the residual network, differ in what they guarantee (Dinic's unit
network bound, Edmonds–Karp's pinned flow), and the house precedent for that is ShortestPaths'
`dijkstraShortestPaths` and `bellmanFordShortestPaths`. Boost and JGraphT name them separately too;
NetworkX's `flow_func=` is the one parameter-shaped precedent.

**Integer and floating capacities.** One generic signature, `C: Comparable & AdditiveArithmetic`
(Dijkstra's constraint), covers `Int`, the fixed-width integers, unsigned types and `Double`. The
three algorithms need only `+`, `-`, `<` and `min`. See Semantics for exactness and termination.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `maximumFlow`, `maximumFlowValue`, `Flow`, `value`, `flow(ofEdgeAt:)` | NetworkX `maximum_flow`, `maximum_flow_value`; igraph `maxflow`, `Flow.value`, `Flow.flow`; JGraphT `getMaximumFlow`, `getValue` | `maxFlow` (igraph, Boost `_max_flow`): Swift spells words out (`maximumMatching`, `maximumClique`) |
| `edmondsKarpMaximumFlow`, `dinicMaximumFlow` | Boost `edmonds_karp_max_flow`; JGraphT `EdmondsKarpMFImpl`, `DinicMFImpl`; petgraph `dinics` | `dinitzMaximumFlow` (NetworkX `dinitz`, the author's transliteration): the README and JGraphT say Dinic; doc comment carries "Dinitz" |
| `minimumCut`, `Cut`, `sourceSide`, `sinkSide`, `edges` | NetworkX `minimum_cut`; igraph `mincut`, `Cut`; OR-Tools `GetSourceSideMinCut`, `GetSinkSideMinCut`; JGraphT `getSourcePartition`, `getSinkPartition`, `getCutEdges` | `partition` (NetworkX, igraph): a tuple or pair of lists; `sourcePartition`: "partition" is the whole split, not one side |
| `minimumCut(capacity:)` (global) | igraph `mincut()` without terminals; LEMON's `HaoOrlin` and `NagamochiIbaraki` documented as "minimum cut"; "global minimum cut" in the literature | `stoerWagnerMinimumCut` (rustworkx, Boost): only needed if a second algorithm is exposed; `globalMinimumCut`: no library spells it |
| `gomoryHuTree`, `GomoryHuTree`, `capacity(ofEdgeAt:)`, `minimumCutValue(between:and:)` | NetworkX, igraph `gomory_hu_tree`; JGraphT `GusfieldGomoryHuCutTree.getCutCapacity`, `calculateMinCut`; LEMON `GomoryHu::minCutValue` | `cutTree` (Gusfield's paper): less familiar |
| `minimumCostFlow`, `MinimumCostFlow`, `cost`, `supply:`, `potential(of:)` | NetworkX `min_cost_flow`; JGraphT `MinimumCostFlow`, `getCost`; LEMON `supplyMap`, `potential`; OR-Tools `SetNodeSupply`, `OptimalCost` | `demand:` (NetworkX, opposite sign): LEMON, OR-Tools, JGraphT and DIMACS's min format use supply; `networkSimplex`: the algorithm, in the doc comment |
| `minimumCostMaximumFlow` | "min cost max flow", Boost's docs for `successive_shortest_path_nonnegative_weights` and `cycle_canceling`; OR-Tools `SolveMaxFlowWithMinCost` | `maximumFlowMinimumCost` (NetworkX `max_flow_min_cost`): the less common order |
| `edgeConnectivity`, `vertexConnectivity`, `minimumVertexCut` | NetworkX `edge_connectivity`, `minimum_node_cut`; igraph `edge_connectivity`, `vertex_connectivity`; Boost `edge_connectivity`; Mathematica `VertexConnectivity`, `FindVertexCut` | `nodeConnectivity` (NetworkX): Grafluent says vertex (`vertexCount`, `articulationPoints`); `adhesion`/`cohesion` (igraph aliases) |

**Proposed Terminology rows**

* Edge values a flow may not exceed: capacity, `capacity:` (all libraries). Mathematical term: c : E → ℝ≥0.
* Assignment of flow to edges respecting capacities and conservation: flow, `Flow`; its value the
  net flow out of the source. NetworkX, igraph, JGraphT. Mathematical term: s–t flow.
* A split of the vertices with the edges from one side to the other: cut, `Cut`, with a source side
  and a sink side. OR-Tools, JGraphT. Mathematical term: s–t cut (S, T); the cut-set.
* Net amount a vertex sends: supply, `supply:` (positive sends; negative is a demand). LEMON, OR-Tools,
  JGraphT; NetworkX uses demand with the opposite sign. Mathematical term: b(v), node balance.

## Semantics

### Capacities, numeric types, exactness

* **Preconditions, checked before any work** (`capacity` is called once per non-loop edge, in
  position order): every capacity ≥ 0 (FL-220, FL-221: also edges no path uses), not NaN
  (`c == c`, FL-222), finite (`c - c == .zero`, the generic infinity test: it holds for every
  finite value, fails for infinities and NaN, and never overflows; FL-223), and the
  capacities at the source sum without overflow (FL-224 – FL-226: the trap is deterministic even when
  the value would fit, because the sum is checked up front with `addingReportingOverflow` on integers
  and by comparison on floats). With those, no intermediate overflows: a residual is at most its
  edge's capacity, and push–relabel's excesses are at most the source's total.
* **Integers are exact.** All three algorithms do only `+`, `-` and comparisons of capacities and
  flows. `Int8` up to its maximum (FL-156), `UInt8` (FL-159) and `Int.max` totals (FL-161) are rows.
* **Floating point.** The value and conservation hold up to rounding (`ref.py` checks with a
  tolerance). Termination does not depend on the values: push–relabel's bound counts saturating and
  non-saturating pushes and relabels, Edmonds–Karp's counts augmentations by shortest-path length,
  and Dinic's counts phases; each push or augmentation by a bottleneck sets that residual to exactly
  zero (`r − r == 0` in IEEE), so the combinatorial arguments survive rounding. That is why plain
  Ford–Fulkerson, whose termination needs rational capacities (Zwick's irrational example), is not
  offered. The canonical cut follows residuals > 0 as computed: FL-151 has 0.1 + 0.2 on parallel
  edges into a 0.3 edge; 0.1 + 0.2 = 0.30000000000000004, so the cut is the 0.3 edge and the value
  0.3. Catalog rows otherwise use dyadic values (FL-146), which are exact.
* **Minimum-cost flow** takes `BinaryInteger` capacities (unsigned ones too) and `SignedInteger`
  supplies and costs (open question 4). Preconditions: capacities ≥ 0 (FL-306), and Σ capacity ×
  |cost| fits in the cost type, checked before solving (FL-307), which bounds every partial cost
  and the total, so a total cost that could not be represented traps rather than wrapping. The
  solver's artificial cost, big M = (n + 1)(the greatest |cost| + 1), is computed in `Int` and never
  reported: only 4 × big M must fit in `Int` (FL-491: 130 vertices with `Int8` costs). Capacities
  up to `Int.max` are finite and exact: only the artificial arcs are unbounded (LEMON stores INF =
  MAX for both and checks UNBOUNDED; FL-488 – FL-490). Integral data give an integral optimum
  (total unimodularity), so integers are exact.

### Edges: parallel, antiparallel, self-loops, zero capacity

* **Parallel edges** are separate arcs with their own capacities and flows (FL-066); in a cut each
  copy is listed (FL-230). Edge connectivity counts each copy (FL-340: three parallel edges, λ = 3;
  NetworkX's auxiliary digraph collapses them to 1). Vertex connectivity reads the simple graph.
* **Antiparallel edges** u→v and v→u are independent: each gets its own reverse arc in the residual
  network (FL-071, FL-076, FL-091), so no Boost-style `reverse_edge` map is needed and an existing
  antiparallel edge is never mistaken for a reverse arc.
* **Self-loops** carry no flow in maximum flows, are not asked for a capacity, and never cross a cut
  (FL-061, FL-179, FL-235). In minimum-cost flow they can matter: a negative-cost loop is saturated
  (FL-280, FL-300, FL-314; NetworkX's `network_simplex` does the same), a zero- or positive-cost loop
  carries nothing (FL-281). This rule is part of the API, so the loop's flow is pinned even where
  zero-cost alternatives exist.
* **Zero capacities** are allowed; such an edge from S to T is still a cut edge (FL-021, FL-026), as
  in NetworkX's `cutset` and JGraphT's `getCutEdges`.

### Source, sink, and undirected graphs

* **`source == sink` traps** in every s–t entry point (FL-213 – FL-217, FL-319, FL-485 – FL-487), as
  NetworkX raises ("source and sink are the same node") and igraph errors. A vertex not in the graph
  traps (FL-218, FL-219).
* **No path**: value 0, every edge flow 0, and the canonical cut puts the vertices that reach the
  sink (only the sink, if none) on the sink side (FL-006 – FL-020).
* **Undirected graphs**: each edge is one residual pair with capacity c both ways and a signed flow
  (|f| ≤ c, the edge used in one direction; NetworkX's undirected flow, igraph's). Results are over
  `DirectedView`, ShortestPaths' convention: `flow(ofEdgeAt: .init(position: e, reversed: false))` is
  the flow along the stored order, the `reversed: true` arc the flow against it, at most one nonzero
  (FL-164: one edge from its second end, flow on the reversed arc). `flow(ofEdgeAt:)` with the
  undirected graph's own position gives the signed flow, the forward arc's less the reversed
  arc's (igraph's signed undirected `Flow.flow`; FL-164: −5), so no `DirectedView` index is needed
  to read it. A cut lists each crossing edge once, as the arc from the source side (FL-179: `1r`).
  `capacity` is called once per edge.

### The canonical s–t cut (decision)

Minimum cuts are not unique, but they form a lattice under union and intersection, so there is a
least sink side, T* = the vertices that can reach the sink in the residual network of any maximum
flow. **`minimumCut`, `Flow.minimumCut`, and every cut the module builds on use T*.** Reasons:

* **NetworkX and igraph return exactly this cut.** NetworkX `minimum_cut` computes its partition
  by a reverse breadth-first search from the sink over unsaturated arcs; igraph's `maxflow` /
  `mincut` partitions agree on every catalog row and stress network. So `just diff` can compare cuts
  exactly, not just values, and Gomory–Hu trees edge for edge.
* **It costs only push–relabel's first phase.** At the end of phase 1 every vertex with excess is
  cut off from the sink, and phase 2 changes flows only among such vertices, so the vertices that
  reach the sink are already final (`ref.py` checks the preflow's cut on every row). LEMON's
  `Preflow::runMinCut` stops there for the same reason. The source-minimal cut (vertices reachable
  from the source: CLRS's proof, JGraphT's `getSourcePartition`, OR-Tools `GetSourceSideMinCut`)
  needs the full flow.
* It is property-defined: any correct algorithm gives it, so the three maximum-flow functions return
  the same `Cut` (FL-001 – FL-212: the MaximumFlow, Dinic and MinimumCut rows agree).

Consequences visible in the catalog: on a path with equal capacities the cut is the edge into the
sink (FL-031); vertices that can reach the sink but not be reached are on the sink side (FL-051);
vertices unreachable from both sit on the source side (FL-046).

### Global minimum cut

* **`Graph` (Nagamochi–Ibaraki).** Fewer than two vertices: nil (FL-227, FL-228; NetworkX raises).
  When the positive-capacity edges leave more than one component: value 0, source side the first
  vertex's component, edges every crossing edge (all zero) (FL-231 – FL-234; NetworkX raises
  "graph is not connected", rustworkx and igraph return some zero cut). Otherwise **a minimum cut
  whose source side holds the first vertex**, deterministic (the same input gives the same cut),
  without pinning which one when several exist: the catalog shows the sides where the minimum cut
  is unique and "(one of several minimum cuts)" elsewhere, and tests check the value, the cut's
  edges and value from its sides, and the first vertex's side. LEMON's algorithm: the least vertex
  capacity sum first; then phases of maximum adjacency ordering on the contracted graph, each
  prefix's cut value kept incrementally, every edge whose scanned connection q(e) is at least the
  best so far contracted (λ(u, v) ≥ q(e), Nagamochi–Ibaraki 1992), parallel edges merging, so
  later phases run on smaller graphs. A bucket queue for small `Int` connections, a 4-ary heap
  otherwise. Ties compare the accumulated sums exactly (catalog rows use integers or dyadic values).
* **`DirectedGraph` (Hao–Orlin).** A minimum cut over every nonempty proper S, deterministic, which
  one not pinned (FL-250 – FL-257): LEMON `HaoOrlin`'s two passes, the first vertex as the source
  of one push–relabel run that moves the sink through every vertex, then the same on the reversed
  graph. nil below two vertices (FL-250). The catalog's model for the value is the least canonical
  cut over the n pairs vᵢ → vᵢ₊₁ (mod n): every proper S separates such a pair (Schnorr 1979;
  Esfahanian's Algorithm 8, as NetworkX's directed `edge_connectivity`), the method this entry
  point used before Hao–Orlin. FL-251: one edge 0→1; the cut is S = {1}.
* **Wide sums (both, and Gomory–Hu).** A contracted group's connection, a vertex's excess, or a
  group's capacity sum can pass the capacity type while the answer fits (FL-492 – FL-498: `UInt8`
  graphs whose merged groups or vertices pass 255; FL-526, FL-527: an `Int` path whose middle
  vertex sums past `Int.max`). So these algorithms run on capacities converted to `Int` when twice
  the total fits, else `Int128` (exact for every type of up to 64 bits), and on `Double` for
  `Float`; any other type as it is. The only precondition left is that the answer fits: the cut's
  value, and every Gomory–Hu tree capacity.

### Gomory–Hu tree

Gusfield's 1990 cut-tree algorithm, NetworkX's code line for line: parent p[v] = the first vertex
for every other v; for s = 1, 2, … (vertex index order), t = p[s], X = the source side of the
canonical cut from s to t, fl[s] = its value; every other v in X with p[v] = t gets p[v] = s; and if
t is not the first vertex and p[t] ∈ X, then p[s] = p[t], p[t] = s and the two labels swap. With the
canonical cut this is exactly NetworkX's tree on every row and 185 stress graphs. Disconnected
graphs get zero-capacity tree edges (FL-261); one vertex, an empty tree (FL-259); no vertex, nil
(FL-258; NetworkX raises). The cut-tree property (every tree edge's split is a minimum cut between its
ends) is checked by brute force on every row with n ≤ 10, so `minimumCut(between:and:)` is a real
minimum cut, not only its value. `Tree`'s edge order is by child index (FL-270 shows labels).

### Minimum-cost flow

* **Supplies**: positive sends, negative receives (LEMON, OR-Tools, JGraphT; NetworkX's demand is
  the negation). Σ supply ≠ 0 returns nil (FL-284, FL-285), as OR-Tools' `UNBALANCED` and NetworkX's
  `NetworkXUnfeasible` ("total node demand is not zero"); an unmet supply behind a cut returns nil
  (FL-283, FL-286, FL-297, FL-298). The empty graph is feasible at cost 0 (FL-276).
* **Infeasibility is nil, without a witness in phase 1.** The witness exists (a set S with
  supply(S) > capacity out of S, Gale's theorem, read off the auxiliary flow's cut) and is the
  natural phase 2 addition; open question 5.
* **Negative costs and cycles** are fine: capacities are finite, so the optimum exists whenever a
  feasible flow does; negative cycles are saturated even with no supply (FL-279, FL-293, FL-303).
* **Which optimum**: unspecified. Tests assert the cost, feasibility and the optimality certificate
  (`potential(of:)`: every residual arc has nonnegative reduced cost), and the flow only where
  the catalog marks it unique (FL-289 is a tie).
* **`minimumCostMaximumFlow`** minimizes cost over all maximum flows, so a negative cycle away
  from every s–t path is still saturated (FL-313; NetworkX's `max_flow_min_cost` agrees). Boost's
  `successive_shortest_path_nonnegative_weights` would not (it requires nonnegative costs).

### Connectivity

* **Edge connectivity** is the unit-capacity flow or cut: λ(s, t) = edge-disjoint paths; λ(G) the
  global minimum cut with capacities 1 (Nagamochi–Ibaraki on `Graph`, Hao–Orlin on
  `DirectedGraph`); 0 below two vertices and when disconnected (FL-322, FL-325, FL-400).
* **Disjoint paths.** `edgeDisjointPaths(from:to:)` returns λ(s, t) paths, no edge in two (parallel
  edges distinct; NetworkX's auxiliary digraph collapses them, FL-506); `vertexDisjointPaths`
  returns κ(s, t) paths, no inner vertex in two, an edge from s to t one path whatever its
  multiplicity (NetworkX's count, FL-509). Each is a simple path; flow cycles in the unit flow are
  dropped while decomposing. Which paths is not pinned. Over `directed` on `Graph`.
* **Vertex connectivity** follows NetworkX and igraph on simple graphs: κ(K_n) = n − 1 (FL-365),
  κ = 0 below two vertices or when not (strongly) connected (FL-320, FL-398, FL-464). Local
  κ(s, t) splits every other vertex v into v_in → v_out of capacity 1; an edge s → t counts as one
  extra path, once whatever its multiplicity (FL-458: 2; FL-461: the reverse pair 0). igraph errors
  on adjacent pairs by default; NetworkX counts the edge, as here.
* **`minimumVertexCut(from:to:)`**: nil when an edge goes from source to target (FL-336, FL-432;
  NetworkX returns an empty set, which reads as "already separated"). Otherwise the canonical cut
  of the split network: v is in the cut when v_in is on the source side and v_out on the sink side,
  the minimum cut nearest the target. Edge arcs get capacity n, so only split arcs are cut.
* **`minimumVertexCut()`**: Even's algorithm (kept after the review: Esfahanian–Hakimi, which
  would let the pair order be relaxed, was not implemented, so the documented order stands). Best = n − 1 and the vertices after the first. For
  i = 0, 1, … while i ≤ best: for each j > i, each pair (vᵢ, vⱼ) (on `DirectedGraph` also
  (vⱼ, vᵢ)) with no edge from the first to the second, the local canonical cut replaces the best
  when strictly smaller. Correct because the first vertex outside a minimum cut X has index ≤ κ and
  pairs with some later vertex that X separates from it. The complete case (FL-366, FL-450) keeps
  the vertices after the first, NetworkX's answer. NetworkX's own procedure iterates Python sets,
  so its cut can differ (noted per row); sizes agree everywhere.

## Determinism (decision)

| Entry point | Which result | Tests assert |
|---|---|---|
| `maximumFlow`, `dinicMaximumFlow` | Value; the canonical cut; the flow unspecified | Value, cut exactly; flow: capacity and conservation, value = Σ out of source |
| `edmondsKarpMaximumFlow` | The procedure's flow (rows in edge-position order, BFS stops at the sink, bottleneck augment) | Exact per-edge flows |
| `maximumFlowValue` | Value | Exact (floating rows: as computed) |
| `minimumCut(from:to:capacity:)` | Least sink side | Exact; = NetworkX `minimum_cut` partition |
| `minimumCut(capacity:)` | A minimum cut, deterministic: the first vertex on the source side on `Graph` (its component when the positive edges leave several); Hao–Orlin's on `DirectedGraph` | The value exactly; the sides where unique (or by the components rule); otherwise the cut's validity |
| `gomoryHuTree` | Gusfield with the canonical cut, index order | Exact; = NetworkX |
| `minimumCostFlow`, `minimumCostMaximumFlow` | Least cost; loop rule; the flow otherwise unspecified | Cost exactly; flow where unique; certificate |
| connectivity values | Definitions | Exact |
| `minimumVertexCut()` | Even's pair order, first strict minimum, canonical local cuts | Exact |
| `minimumVertexCut(from:to:)` | Nearest the target | Exact |
| `edgeDisjointPaths`, `vertexDisjointPaths` | λ(s, t) / κ(s, t) paths, deterministic, not pinned | The count; each path and the disjointness |

## Complexity

n vertices, m edges, U the greatest capacity, κ the vertex connectivity.

| Entry point | Time | Extra memory |
|---|---|---|
| `maximumFlow`, `minimumCut(from:to:)` | O(n² √m) (highest label; gap and global relabelling only help) | residual CSR: n + 1 offsets, 2m arcs × (head, residual, mate) |
| `maximumFlowValue` | phase 1 of the above | same |
| `edmondsKarpMaximumFlow` | O(n m²) | same, plus a BFS queue and parent arcs |
| `dinicMaximumFlow` | O(n² m); O(m √n) unit networks; O(m min(√m, n^(2/3))) unit capacities | same, plus levels and current arcs |
| `minimumCut(capacity:)`, `Graph` | Nagamochi–Ibaraki: O(nm log n) in the worst case (n phases of O(m log n)); far fewer phases in practice | the contracted graph as linked arc lists (2m arcs), an indexed heap or bucket queue |
| `minimumCut(capacity:)`, `DirectedGraph` | Hao–Orlin: O(n²m) in the worst case (LEMON's), one push–relabel run per pass, two passes | two residual networks (the graph and its reverse), bucket lists |
| `gomoryHuTree` | n − 1 maximum flows | one residual network, reset per run |
| `minimumCostFlow` | no polynomial bound proven for block-search network simplex; O(n m log(nU)) would need cost scaling | spanning-tree arrays (parent, predecessor arc and direction, thread, reverse thread, successor count, last successor, potential), n + m |
| `minimumCostMaximumFlow` | a maximum flow, then `minimumCostFlow` | as both |
| `edgeConnectivity(from:to:)` | Dinic, unit capacities | residual network |
| `edgeConnectivity()` | `Graph`: Nagamochi–Ibaraki, unit (bucket queue); `DirectedGraph`: Hao–Orlin, unit | as the global cuts |
| `edgeDisjointPaths(from:to:)` | Dinic on the unit network, then O(m) decomposition | unit residual network |
| `vertexDisjointPaths(from:to:)` | Dinic on the split network: O(m √n), then O(n + m) | split residual network |
| `vertexConnectivity(from:to:)`, `minimumVertexCut(from:to:)` | Dinic on the split network (2n vertices, n + m arcs): O(m √n) | split residual network |
| `vertexConnectivity()`, `minimumVertexCut()` | O((κ + 1) · n) local flows, each cut off at the best so far | one split network, reset per run |

## Implementation notes and performance plan

* **Residual network.** Index space, compressed sparse row by tail: `offsets` (n + 1), and per arc
  one record {`head: Int32`, `mate: Int32` (the paired reverse arc), `residual: C`}, built in
  O(n + m) by counting sort over the edges in position order, so each row lists its arcs in
  edge-position order (the order Edmonds–Karp's pinned flow depends on). Plus `forwardArc: [Int32]`
  to report flows by edge number. Array of structs (measured: max-flow value on G(5000, 5·10⁴)
  0.81 → 0.64 ms against struct-of-arrays, the row layout unchanged, so Edmonds–Karp's flows are
  identical); built once per call and reset between runs inside Gomory–Hu and connectivity.
  Undirected graphs: one pair per edge, both residuals c. At most 2³¹ − 1 arcs (checked: the split
  networks have 4m or 2(n + 2m)).
* **Push–relabel** (Goldberg–Tarjan; the Cherkassky–Goldberg 1997 heuristics): highest-label
  selection with per-label bucket lists of active vertices (intrusive `next`/`prev` arrays),
  current-arc pointers, the gap heuristic (a count per label; an empty label lifts every vertex
  above it to n), and global relabelling by reverse BFS from the sink at the start and after
  relabel work 12n + 2m (HIPR's rule; it beat half and double here). Phase 1 stops when no active
  vertex has label < n; phase 2 returns the excess to the source LEMON's way: push–relabel toward
  the source on the vertices that cannot reach the sink, labelled by their breadth-first distance
  to the source, highest label first. Saturating source pushes first.
* **Dinic**: BFS levels from the source stopped at the sink's level; an iterative DFS with an
  explicit stack of arcs and current-arc pointers (no recursion, no captured locals).
* **Edmonds–Karp**: BFS with parent arcs, a flat queue array; kept simple; it is the pinned
  procedure and the oracle.
* **Nagamochi–Ibaraki** (replaced Stoer–Wagner after the review: 211 ms → 0.77 ms on
  lcgund(1000, 10⁴), LEMON 0.67 ms): LEMON's layout, the contracted graph as doubly linked arc
  lists per group with parallel edges merged at the start and as groups merge, a member list per
  group for the sides, the best side recorded when a phase improves it. Edges with q(e) at least
  the global best are contracted (LEMON uses the phase's best, a weaker bound), and a merged
  parallel edge keeps the greater q.
* **Hao–Orlin** (replaced the n cyclic-pair flows: 81 ms → 7.2 ms on directed lcgnet(1000, 10⁴),
  LEMON 11 ms): LEMON's layout on our residual network, buckets in ordered lists per set of
  vertices, dormant sets for the gap heuristic, active vertices at the front of each bucket.
* **Network simplex**: LEMON's layout (Király–Kovács): artificial root with big-M arcs, spanning
  tree as parent / pred-arc / thread / reverse-thread / succ-num / last-succ arrays, block search
  pivot (block √m), strongly feasible trees to avoid cycling, potentials updated on the moved
  subtree only. Self-loops are settled before the tree is built (saturated when negative). Only
  the artificial arcs are unbounded: a growing artificial arc never blocks, every problem arc's
  room is c − f exactly (the review found `Int.max` capacities treated as infinite, which wrapped
  the flow). Artificial flows never grow in total (a cycle raising two of them costs big M plus at
  most n − 1 problem arcs, so it never enters), so they stay within the positive supplies' sum.
* **Connectivity**: Dinic on unit and split networks with a value cutoff (stop once the flow reaches
  the best so far), as NetworkX's `cutoff`; the global λ by the global cuts with unit capacities
  (undirected: 228 ms → 0.54 ms on lcgund(1000, 8000), NetworkX 112 ms; directed: 238 ms →
  9.2 ms on lcgnet(1000, 2·10⁴), LEMON `HaoOrlin` 17 ms). Esfahanian's dominating-set method was
  not needed once Nagamochi–Ibaraki was this fast.
* **Swift lessons from earlier modules** (memory): inner loops as one inline loop over unsafe
  buffers, no nested functions capturing the arrays (boxing), integer cursors instead of stored
  iterators, the residual arrays held in an `inout` struct, never read out of a class.
* **Baselines to beat.** Measured here (NetworkX 3.7 and igraph 1.0, release Python, a random
  G(5000, 50000) digraph with capacities 1–1000 from 0 to 4999): NetworkX `preflow_push` 0.16 s,
  `dinitz` 0.49 s, `edmonds_karp` 0.10 s, `boykov_kolmogorov` 0.14 s; igraph `maxflow_value`
  0.004 s. NetworkX `network_simplex` 0.16 s and `capacity_scaling` 2.8 s on a 1000-vertex,
  10,941-arc min-cost instance; `stoer_wagner` 4.8 s on G(1000, 10000); `gomory_hu_tree` 0.11 s on
  G(200, 1000). Random graphs are easy instances (the value is bounded by the terminals' degrees),
  so the benchmark suite uses the DIMACS families: genrmf long and wide, Washington RLG, AK (hard for
  push–relabel), and grid "vision" instances; NETGEN, GRIDGEN and GOTO for min-cost (Király–Kovács
  2012). Targets: within 1.25× LEMON `Preflow` and Boost `push_relabel_max_flow` on those families,
  within 1.5× OR-Tools `SimpleMaxFlow`, at least igraph's speed (C push–relabel) on the random
  families, and LEMON `NetworkSimplex` within 1.5× for min-cost. Benchmarks against the C++
  libraries go through the Benchmarks package's baselines as earlier modules did.

### Tests

Public API only, each test self-contained (memory rules). Every catalog row; multigraph rows on
`DirectedPseudograph`/`Pseudograph`; traps as exit tests. Properties with swift-property-based on
random networks: the three maximum flows agree on value and `minimumCut`; every flow satisfies
capacity and conservation; the cut's value equals the flow value; no vertex on the sink side is
reachable from the source in the residual network built from the returned flow (written out in the
test); `maximumFlowValue` equals `maximumFlow().value`; Gomory–Hu's `minimumCutValue` equals
`minimumCut(from:to:)` for every pair; `minimumCostFlow` passes its potential certificate and
equals a successive-shortest-path oracle written in the test; connectivity ≤ minimum degree and
κ ≤ λ. `just diff`: values and canonical cuts against NetworkX `minimum_cut` and igraph `maxflow`,
Gomory–Hu trees against NetworkX exactly, min-cost costs against `network_simplex`, connectivity
values against NetworkX and igraph. `just mutate`: the residual > 0 test in the cut BFS (FL-021), the
gap heuristic, the global cut's components rule (FL-232), Gusfield's swap (FL-268), the loop rule (FL-281), the
adjacency +1 (FL-458). `just fuzz`: maximum flow against Edmonds–Karp on random small networks.

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Which minimum cut | NetworkX and igraph: least sink side (ours). JGraphT `getSourcePartition` and CLRS: least source side. OR-Tools: both | every MaximumFlow and MinimumCut row |
| Global cut on a disconnected graph | NetworkX raises; rustworkx and igraph return a zero cut of their choosing; ours the first vertex's component | FL-231 – FL-233 |
| Edge-disjoint paths with parallel edges | NetworkX's auxiliary digraph merges them (1 path for three parallel edges); igraph counts them (3, ours) | FL-506, FL-510 |
| Parallel edges in edge connectivity | NetworkX's auxiliary digraph merges them (λ = 1 for three parallel edges); igraph counts them (3, ours) | FL-340, FL-481 |
| Local vertex cut of adjacent vertices | NetworkX returns the empty set; ours nil (no cut exists); igraph raises by default | FL-336 |
| Adjacent pair in local vertex connectivity | igraph errors unless told `neighbors="ignore"` (then counts the edge as 1) or `"negative"` (−1); NetworkX and ours count the edge | FL-458 |
| Global vertex cut | NetworkX's set iteration picks its own minimum cut; sizes agree | MinimumVertexCut rows |
| Gomory–Hu on the empty graph | NetworkX raises; ours nil | FL-258 |
| Minimum-cost flow on the empty graph | NetworkX raises "graph has no nodes"; ours cost 0 | FL-276 |
| `max_flow_min_cost` with negative cycles | NetworkX saturates them (as ours); Boost's SSP requires nonnegative costs | FL-313 |

## README edits proposed

* **Structures table**: remove the `FlowNetwork` row (or, if open question 1 keeps the module, replace
  it with `ResidualNetwork`). **`scripts/modules.py`**: drop `FlowNetworks`; `Flows` depends on
  `GraphProtocols` and `Trees` (not `Traversal`: the searches run in index space; `Walks` joins
  with the disjoint paths in phase 2).
* **Algorithms table, `Flows` row**: "On `DirectedGraph` and `Graph` (each edge either way):
  `maximumFlow` (highest-label push–relabel), `maximumFlowValue`, `edmondsKarpMaximumFlow`,
  `dinicMaximumFlow`, `minimumCut(from:to:)` (the least sink side, NetworkX's), `minimumCut()`
  global (Nagamochi–Ibaraki on `Graph`, Hao–Orlin on `DirectedGraph`), `gomoryHuTree()` (Gusfield;
  NetworkX's tree), `edgeConnectivity`, `vertexConnectivity`, `minimumVertexCut`; on `DirectedGraph`
  `minimumCostFlow(supply:capacity:cost:)` (network simplex, integers) and
  `minimumCostMaximumFlow` (**planned**, phase 1). Later: Boykov–Kolmogorov, cost scaling, lower
  bounds" | results "`Flow` (value, per-edge flow, `minimumCut`), `Cut`
  (source and sink sides plus the crossing edges), `GomoryHuTree`, `MinimumCostFlow` (cost, flows,
  potentials)". Karger is removed.
* **Terminology**: the four rows under Names.

## Open questions

1. **Drop `FlowNetworks` and the `FlowNetwork` type?** Recommended: yes (above). Alternative: keep
   the module for a public `ResidualNetwork`.
2. **Global cut on `DirectedGraph` in phase 1?** Decided: yes; first by n flows, then (after the
   review, measured) by Hao–Orlin behind the same name.
3. **Also expose the least source side?** OR-Tools gives both cuts. **Deferred to phase 2**:
   a `Flow.sourceMinimalCut` (it needs the full flow, which `Flow` has), not a parameter.
4. **Floating-point minimum-cost flow.** **Deferred to phase 2**, as an overload with
   successive shortest paths on integer capacities and `FloatingPoint` costs (terminates by
   units; reduced costs clamped at zero), not network simplex in floats.
5. **Infeasibility witness for `minimumCostFlow`, and UNBALANCED apart from INFEASIBLE.**
   **Deferred to phase 2**: a separate function only once a library name for it is found (none of
   the surveyed libraries has a witness; LEMON and OR-Tools report a status only, and OR-Tools
   tells `UNBALANCED` from `INFEASIBLE`, which nil does not).
6a. **Lower bounds and GEQ/LEQ supply types** (LEMON `lowerMap`, `supplyType`). **Deferred to
   phase 2.**
6. **Traces not verified by running.** Checked by running: NetworkX 3.7 (signatures and behaviour of
   every function above), igraph 1.0 (`maxflow`, `mincut`, `st_mincut`, `all_st_cuts`,
   `gomory_hu_tree`, `vertex_connectivity` and its `neighbors=` modes), rustworkx 0.18.1
   (`stoer_wagner_min_cut`, no flow functions). Cited from memory, to confirm before the README edit:
   Boost's function names; LEMON's class and member names (`Preflow::runMinCut`, `minCutMap`,
   `NetworkSimplex::potential`, `GomoryHu::minCutValue`); JGraphT's class and method names
   (`GusfieldGomoryHuCutTree.getCutCapacity`, `MinimumSTCutAlgorithm` getters,
   `CapacityScalingMinimumCostFlow`); OR-Tools' `GetSourceSideMinCut` / `GetSinkSideMinCut`,
   `SolveMaxFlowWithMinCost` and its status names; petgraph's `dinics`; Mathematica's
   `FindVertexCut`.
