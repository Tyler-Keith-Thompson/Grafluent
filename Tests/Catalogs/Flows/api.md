# Flows API

Maximum flows, minimum cuts, Gomory–Hu trees, minimum-cost flows, and flow-based edge and vertex
connectivity. Capacities, costs and supplies are closures over edge positions and vertices; nothing
is stored in the graph.

* **Maximum flow.** `maximumFlow(from:to:capacity:)` (highest-label push–relabel with the gap and
  global-relabelling heuristics), `maximumFlowValue(from:to:capacity:)` (its first phase only), and
  `edmondsKarpMaximumFlow`, `dinicMaximumFlow` and `boykovKolmogorovMaximumFlow`. All return the
  same value and the same canonical minimum cut. Only Edmonds–Karp's per-edge flow is specified.
* **Feasible flows.** `feasibleCirculation(supply:lowerBound:capacity:)` and
  `feasibleCirculation(lowerBound:capacity:)` on `DirectedGraph` return a `Circulation` (each edge
  between its lower bound and capacity, out − in = supply at every vertex; which one unspecified)
  or nil; `findCirculationBarrier` returns, when there is none, the barrier S (supply of S >
  capacity out of S − lower bounds into S): the source side of the reduction's canonical cut, less
  its super source, in `vertices` order. Supplies must sum to zero; lower bounds may be negative.
* **Cut metrics.** On both kinds of graph, of a vertex set S against its complement (NetworkX's
  `cuts` module): `cutSize(of:)`, `volume(of:)`, `conductance(of:)`, `normalizedCutSize(of:)`,
  `edgeExpansion(of:)`, `mixingExpansion(of:)` with weighted forms (`weight:`; the ratios
  `W: FloatingPoint`), and `nodeExpansion(of:)` and `boundaryExpansion(of:)`. A directed edge crosses
  either way and counts in its tail's volume; an undirected one in the volume of each end (a
  self-loop twice). The weighted mixing expansion divides by twice the total weight. A zero
  denominator gives infinity or NaN.
* **Minimum cut.** `minimumCut(from:to:capacity:)` (s–t), and `minimumCut(capacity:)` without
  terminals: Nagamochi–Ibaraki on `Graph`, Hao–Orlin on `DirectedGraph`.
* **Gomory–Hu tree.** `gomoryHuTree(capacity:)` on `Graph`, by Gusfield's algorithm.
* **Minimum-cost flow.** `minimumCostFlow(supply:capacity:cost:)` (network simplex) and
  `minimumCostMaximumFlow(from:to:capacity:cost:)`, on `DirectedGraph`, with integer capacities and
  costs. `minimumCostFlow` returns nil when the supplies cannot be met.
* **Connectivity.** `edgeConnectivity()`, `vertexConnectivity()`, `minimumVertexCut()` and their
  s–t forms, on both kinds of graph, and `edgeDisjointPaths(from:to:)` and
  `vertexDisjointPaths(from:to:)`, Menger's witnesses.
* **Results.** `Flow`, `Cut`, `GomoryHuTree`, `MinimumCostFlow`, `Circulation`, and `FlowMap`, every edge's flow
  by position.

`Flows` depends on `GraphProtocols`, `Trees` (`GomoryHuTree.tree`) and `Walks` (the disjoint
paths).

`cases.md` (FL-001 – FL-590) holds the expected values. `ref.py` recomputes every row from small
models of this API, checks it independently, renders the catalog and compares it with `cases.md`
byte for byte. Each maximum-flow row runs Edmonds–Karp, Dinic and a FIFO push–relabel model, which
agree on the value and on the canonical cut, computed from each one's residual network and from
push–relabel's first-phase preflow. The cut is also brute-forced over every s–t cut when n ≤ 12,
and compared with NetworkX 3.7 `minimum_cut`'s partition and igraph 1.0 `maxflow`'s partition.
Values are compared with NetworkX `maximum_flow_value` under all five of its `flow_func`s. Global
cut values are compared with brute force, NetworkX `stoer_wagner`, rustworkx 0.18.1
`stoer_wagner_min_cut` and igraph `mincut`. A global cut's sides are listed only where the minimum
cut is unique (or fixed by the components rule), and brute force finds which rows those are.
Gomory–Hu trees are compared with NetworkX `gomory_hu_tree` edge for edge, and every tree edge is
checked to be a minimum cut by brute force. Minimum costs are compared with a
successive-shortest-path model, NetworkX `network_simplex`, `capacity_scaling` and
`max_flow_min_cost`, and brute force over integer flows where small. Whether a displayed flow is
the only optimum is decided by re-solving with each edge forced one unit up and down. Connectivity
is compared with brute force over removed sets, NetworkX and igraph. `--stress` adds 600 random
flow networks, 185 random Gomory–Hu trees and 400 random minimum-cost problems. Run:

```sh
uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1 \
    python3 Tests/Catalogs/Flows/ref.py [--stress] [--write]
```

## Summary

```swift
import GraphProtocols
import Trees
import Walks

extension DirectedGraph {
    // Maximum flow. `capacity` is called once per non-loop edge, in position order, before any
    // work; self-loops carry no flow and are never asked. Capacities are at least zero, not NaN,
    // finite, and the capacities of the edges out of `source` sum to a value that fits in C.

    /// Highest-label push–relabel with the gap and global-relabelling heuristics, in two phases.
    /// Which maximum flow is returned is unspecified; `value` and `minimumCut` are determined.
    /// O(n² √m).
    public func maximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Flow<Self, C>

    /// Push–relabel's first phase only (a maximum preflow). O(n² √m).
    public func maximumFlowValue<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> C

    /// Shortest augmenting paths by breadth-first search over residual arcs in edge-position
    /// order, stopping when the sink is discovered. The procedure determines the flow. O(n m²).
    public func edmondsKarpMaximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Flow<Self, C>

    /// Edmonds–Karp as a lazy sequence of events (directed only): each augmenting path with its
    /// bottleneck, then `push` or `cancel` on each of its edges from the source end. The pushes
    /// less the cancellations are `edmondsKarpMaximumFlow`'s flows. O(n m²) to iterate.
    public func edmondsKarpEvents<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> EdmondsKarpEvents<Self, C>

    /// Dinic's blocking flows with current-arc pointers. O(n² m); O(m √n) on unit networks;
    /// O(m min(√m, n^(2/3))) with unit capacities.
    public func dinicMaximumFlow<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Flow<Self, C>

    /// The canonical minimum s–t cut: the least sink side. Push–relabel's first phase. O(n² √m).
    public func minimumCut<C: Comparable & AdditiveArithmetic>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C) -> Cut<Self, C>

    /// A minimum cut over all nonempty proper vertex sets S (capacity of the edges leaving S), by
    /// Hao–Orlin; nil below two vertices. O(n²m).
    public func minimumCut<C: Comparable & AdditiveArithmetic>(capacity: (Edges.Index) -> C) -> Cut<Self, C>?

    // Minimum-cost flow. Integer capacities, supplies and costs; exact.

    /// A least-cost flow within capacities that meets every supply, or nil when there is none.
    /// Network simplex with block-search pivots and strongly feasible trees.
    public func minimumCostFlow<S: SignedInteger, C: BinaryInteger, W: SignedInteger>(
        supply: (Vertex) -> S, capacity: (Edges.Index) -> C, cost: (Edges.Index) -> W
    ) -> MinimumCostFlow<Self, C, W>?

    /// The least-cost flow among the maximum flows from `source` to `sink`, circulations
    /// included.
    public func minimumCostMaximumFlow<C: BinaryInteger, W: SignedInteger>(
        from source: Vertex, to sink: Vertex, capacity: (Edges.Index) -> C, cost: (Edges.Index) -> W
    ) -> MinimumCostFlow<Self, C, W>

    // Connectivity, on the graph's edges with unit capacities.

    public func edgeConnectivity() -> Int
    public func edgeConnectivity(from source: Vertex, to target: Vertex) -> Int
    public func vertexConnectivity() -> Int
    public func vertexConnectivity(from source: Vertex, to target: Vertex) -> Int
    public func minimumVertexCut() -> [Vertex]
    public func minimumVertexCut(from source: Vertex, to target: Vertex) -> [Vertex]?
    public func edgeDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, Edges.Index>]
    public func vertexDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, Edges.Index>]
}

extension Graph {
    // The same maximum-flow, s–t cut and connectivity entry points. Each edge carries up to its
    // capacity in either direction, one capacity shared by both (|f| ≤ c). Results are over
    // `directedView`: an edge's flow is on the arc of its direction, and a cut edge is the arc
    // from the source side to the sink side.
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

    /// A global minimum cut by Nagamochi–Ibaraki whose source side holds the first vertex; nil
    /// below two vertices. O(nm log n) in the worst case.
    public func minimumCut<C: Comparable & AdditiveArithmetic>(capacity: (Edges.Index) -> C) -> Cut<DirectedView<Self>, C>?

    /// Gusfield's algorithm with the canonical cut, vertices in order, rooted at the first; nil for
    /// the empty graph. n − 1 maximum flows.
    public func gomoryHuTree<C: Comparable & AdditiveArithmetic>(capacity: (Edges.Index) -> C) -> GomoryHuTree<Self, C>?

    public func edgeConnectivity() -> Int
    public func edgeConnectivity(from source: Vertex, to target: Vertex) -> Int
    public func vertexConnectivity() -> Int
    public func vertexConnectivity(from source: Vertex, to target: Vertex) -> Int
    public func minimumVertexCut() -> [Vertex]
    public func minimumVertexCut(from source: Vertex, to target: Vertex) -> [Vertex]?
    public func edgeDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, DirectedView<Self>.Edges.Index>]
    public func vertexDisjointPaths(from source: Vertex, to target: Vertex) -> [Path<Vertex, DirectedView<Self>.Edges.Index>]
}

@frozen
public struct Flow<G: DirectedGraph, Capacity: Comparable & AdditiveArithmetic>: Equatable {
    public let source: G.Vertex
    public let sink: G.Vertex
    /// The net flow out of the source.
    public let value: Capacity
    /// The canonical minimum cut, from this flow's residual network.
    public let minimumCut: Cut<G, Capacity>
    /// Zero on a self-loop. O(1) with edge indices, O(log m) without.
    public func flow(ofEdgeAt position: G.Edges.Index) -> Capacity
    public func flow(checkedEdgeAt position: G.Edges.Index) throws(EdgeNotFound) -> Capacity
    public var flowMap: FlowMap<G, Capacity> { get }
    /// On a flow over `directedView`: the signed flow of the undirected edge at `position`,
    /// positive along its stored orientation.
    public func flow<Base: Graph>(ofEdgeAt position: Base.Edges.Index) -> Capacity
        where G == DirectedView<Base>, Capacity: SignedNumeric
    public func flow<Base: Graph>(checkedEdgeAt position: Base.Edges.Index) throws(EdgeNotFound) -> Capacity
        where G == DirectedView<Base>, Capacity: SignedNumeric
}

/// Every edge's flow, a collection indexed by the graph's edge positions.
@frozen
public struct FlowMap<G: DirectedGraph, Value>: Collection {
    public subscript(position: G.Edges.Index) -> Value { get }
}

@frozen
public struct Cut<G: DirectedGraph, Capacity: Comparable & AdditiveArithmetic>: Equatable {
    /// The capacity of `edges`.
    public let value: Capacity
    /// The vertices on each side, in `vertices` order.
    public let sourceSide: [G.Vertex]
    public let sinkSide: [G.Vertex]
    /// Every edge from the source side to the sink side, zero capacities included, in position
    /// order.
    public let edges: [G.Edges.Index]
}

@frozen
public struct GomoryHuTree<G: Graph, Capacity: Comparable & AdditiveArithmetic>: Equatable {
    /// The edge at position k joins the vertex with number k + 1 to its parent.
    public let tree: Tree<G.Vertex>
    public func capacity(ofEdgeAt position: Int) -> Capacity
    public func capacity(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Capacity
    /// The least capacity on the tree path. O(n). Precondition: u ≠ v.
    public func minimumCutValue(between u: G.Vertex, and v: G.Vertex) -> Capacity
    public func minimumCutValue(checkedBetween u: G.Vertex, and v: G.Vertex) throws(VertexNotFound) -> Capacity
    /// The split at the least edge on the tree path (nearest `u` among equals), `u` on the source
    /// side, with the graph's crossing edges. O(n + m). Precondition: u ≠ v.
    public func minimumCut(between u: G.Vertex, and v: G.Vertex) -> Cut<DirectedView<G>, Capacity>
    public func minimumCut(checkedBetween u: G.Vertex, and v: G.Vertex) throws(VertexNotFound) -> Cut<DirectedView<G>, Capacity>
}

@frozen
public struct MinimumCostFlow<G: DirectedGraph, Capacity: BinaryInteger, Cost: SignedInteger>: Equatable {
    /// The total cost, Σ flow × cost.
    public let cost: Cost
    /// The sum of the positive supplies; for `minimumCostMaximumFlow`, the maximum flow value.
    public let value: Capacity
    public func flow(ofEdgeAt position: G.Edges.Index) -> Capacity
    public func flow(checkedEdgeAt position: G.Edges.Index) throws(EdgeNotFound) -> Capacity
    public var flowMap: FlowMap<G, Capacity> { get }
    /// An optimal dual, the optimality certificate. Traps when it does not fit in `Cost`.
    public func potential(of vertex: G.Vertex) -> Cost
    public func potential(checked vertex: G.Vertex) throws(VertexNotFound) -> Cost
}
```

`Flow`, `Cut` and `MinimumCostFlow` are `Equatable` on their values, not the graph, and `Sendable`
when the graph, vertex, position and value types are. `GomoryHuTree` is `Equatable` on its tree
and capacities. All four are `CustomStringConvertible`.

Capacities for the maximum flows, cuts, Gomory–Hu and connectivity use one generic constraint,
`C: Comparable & AdditiveArithmetic`, which covers `Int`, the fixed-width integers, unsigned types
and the floating-point types.

## Semantics

### Capacities, numeric types, exactness

* **Preconditions, checked before any work.** `capacity` is called once per non-loop edge, in
  position order. Every capacity is ≥ 0 (FL-220, FL-221, also on edges no path uses), not NaN
  (`c == c`, FL-222), and finite (`c - c == .zero`, which holds for every finite value, fails for
  infinities and NaN, and never overflows; FL-223). The capacities at the source sum without
  overflow (FL-224 – FL-226). The sum is checked up front, so the trap happens even when the value
  would fit.
* **Undirected residuals.** An undirected edge's residual pair reaches c + f, up to twice its
  capacity. When twice the greatest capacity would overflow the type, each edge is carried as two
  independent arcs (Edmonds–Karp keeps its flow both ways instead), so no residual exceeds a
  capacity.
* **Integers are exact.** The maximum-flow algorithms do only `+`, `-` and comparisons. `Int8` up
  to its maximum (FL-156), `UInt8` (FL-159) and `Int.max` totals (FL-161) are rows.
* **Floating point.** The value and conservation hold up to rounding (`ref.py` checks with a
  tolerance). Termination does not depend on the values: each push or augmentation by a bottleneck
  sets that residual to exactly zero, so the combinatorial bounds hold under rounding. The
  canonical cut follows residuals > 0 as computed. FL-151 has 0.1 + 0.2 on parallel edges into a
  0.3 edge; 0.1 + 0.2 = 0.30000000000000004, so the cut is the 0.3 edge and the value 0.3. Other
  rows use dyadic values (FL-146), which are exact.
* **Minimum-cost flow** takes `BinaryInteger` capacities (unsigned ones too) and `SignedInteger`
  supplies and costs. Capacities are ≥ 0 (FL-306), and Σ capacity × |cost| fits in the cost type,
  checked before solving (FL-307). That bounds every partial cost and the total, so a total that
  could not be represented traps rather than wrapping. The solver's artificial cost,
  big M = (n + 1)(the greatest |cost| + 1), is computed in `Int` and never reported; 4 × big M must
  fit in `Int` (FL-491: 130 vertices with `Int8` costs). Capacities up to `Int.max` are exact; only
  the artificial arcs are unbounded (FL-488 – FL-490). Integral data give an integral optimum.

### Edges: parallel, antiparallel, self-loops, zero capacity

* **Parallel edges** are separate arcs with their own capacities and flows (FL-066), and a cut
  lists each copy (FL-230). Edge connectivity counts each copy (FL-340: three parallel edges,
  λ = 3). Vertex connectivity reads the simple graph.
* **Antiparallel edges** u→v and v→u are independent. Each gets its own reverse arc in the
  residual network (FL-071, FL-076, FL-091).
* **Self-loops** carry no flow in maximum flows, are not asked for a capacity, and never cross a
  cut (FL-061, FL-179, FL-235). In minimum-cost flow a negative-cost loop is saturated (FL-280,
  FL-300, FL-314) and a zero- or positive-cost loop carries nothing (FL-281). The rule fixes the
  loop's flow even where zero-cost alternatives exist.
* **Zero capacities** are allowed. Such an edge from S to T is still a cut edge (FL-021, FL-026).

### Source, sink, and undirected graphs

* **`source == sink` traps** in every s–t entry point (FL-213 – FL-217, FL-319, FL-485 – FL-487).
  A vertex not in the graph traps (FL-218, FL-219).
* **No path**: value 0, every edge flow 0, and the canonical cut puts the vertices that reach the
  sink (only the sink, if none) on the sink side (FL-006 – FL-020).
* **Undirected graphs.** Each edge carries up to c in one direction (|f| ≤ c). Results are over
  `DirectedView`. `flow(ofEdgeAt: .init(position: e, reversed: false))` is the flow along the
  stored order and the `reversed: true` arc the flow against it, at most one nonzero (FL-164: one
  edge used from its second end, flow on the reversed arc). `flow(ofEdgeAt:)` with the undirected
  graph's own position gives the signed flow, the forward arc's less the reversed arc's (FL-164:
  −5). A cut lists each crossing edge once, as the arc from the source side (FL-179: `1r`).
  `capacity` is called once per edge.

### The canonical s–t cut

Minimum cuts form a lattice under union and intersection, so there is a least sink side,
T* = the vertices that can reach the sink in the residual network of any maximum flow.
`minimumCut(from:to:capacity:)`, `Flow.minimumCut`, and every cut the module builds on use T*.

* It depends only on the network, so the three maximum-flow functions return the same `Cut`
  (FL-001 – FL-212: the MaximumFlow, Dinic and MinimumCut rows agree).
* It needs only push–relabel's first phase. At the end of that phase every vertex with excess is
  cut off from the sink, and the second phase changes flows only among such vertices, so the
  vertices that reach the sink are already final. `ref.py` checks the preflow's cut on every row.

On a path with equal capacities the cut is the edge into the sink (FL-031). Vertices that can reach
the sink but cannot be reached are on the sink side (FL-051). Vertices unreachable from both sit on
the source side (FL-046).

### Global minimum cut

* **`Graph` (Nagamochi–Ibaraki).** Fewer than two vertices: nil (FL-227, FL-228). When the
  positive-capacity edges leave more than one component: value 0, the first vertex's component as
  the source side, and every crossing edge, all of capacity zero (FL-231 – FL-234). Otherwise a
  minimum cut whose source side holds the first vertex. The same input gives the same cut, but
  which one is returned when several exist is unspecified. The catalog shows the sides where the
  minimum cut is unique and "(one of several minimum cuts)" elsewhere. The algorithm starts from
  the least vertex capacity sum, then runs phases of maximum adjacency ordering on the contracted
  graph. Each prefix's cut value is kept incrementally, and every edge whose scanned connection
  q(e) is at least the best so far is contracted (λ(u, v) ≥ q(e), Nagamochi–Ibaraki 1992), with
  parallel edges merging. A bucket queue serves small `Int` connections and a 4-ary heap the rest.
* **`DirectedGraph` (Hao–Orlin).** A minimum cut over every nonempty proper S; the same input
  gives the same cut, and which one among several is unspecified (FL-250 – FL-257). Two passes run:
  one push–relabel run from the first vertex that moves the sink through every vertex, then the
  same on the reversed graph. nil below two vertices (FL-250). The catalog's model for the value is
  the least canonical cut over the n pairs vᵢ → vᵢ₊₁ (mod n), since every proper S separates such a
  pair (Schnorr 1979). FL-251: one edge 0→1; the cut is S = {1}.
* **Wide sums (both, and Gomory–Hu).** A contracted group's connection, a vertex's excess, or a
  group's capacity sum can exceed the capacity type while the answer fits (FL-492 – FL-498: `UInt8`
  graphs whose merged groups or vertices pass 255; FL-526, FL-527: an `Int` path whose middle
  vertex sums past `Int.max`). These algorithms run on capacities converted to `Int` when twice
  the total fits, else `Int128` (exact for every type of up to 64 bits), and on `Double` for
  `Float`; any other type runs as it is. The precondition is only that the answer fits: the cut's
  value, and every Gomory–Hu tree capacity.

### Gomory–Hu tree

Gusfield's 1990 cut-tree algorithm. Parent p[v] = the first vertex for every other v. For
s = 1, 2, … (vertex number order), t = p[s], X = the source side of the canonical cut from s to t,
and fl[s] = its value. Every other v in X with p[v] = t gets p[v] = s. If t is not the first vertex
and p[t] ∈ X, then p[s] = p[t], p[t] = s and the two labels swap. Disconnected graphs get
zero-capacity tree edges (FL-261); one vertex gives an empty tree (FL-259); no vertex gives nil
(FL-258). Every tree edge's split is a minimum cut between its ends, checked by brute force on
every row with n ≤ 10. `Tree`'s edges are in child order (FL-270 shows labels).

### Minimum-cost flow

* **Supplies.** Positive sends, negative receives. Σ supply ≠ 0 returns nil (FL-284, FL-285), and
  so does an unmet supply behind a cut (FL-283, FL-286, FL-297, FL-298). The empty graph is
  feasible at cost 0 (FL-276).
* **Negative costs and cycles** are allowed. Capacities are finite, so an optimum exists whenever a
  feasible flow does. Negative cycles are saturated even with no supply (FL-279, FL-293, FL-303).
* **Which optimum** is unspecified. Tests assert the cost, feasibility and the optimality
  certificate (`potential(of:)`: every residual arc has nonnegative reduced cost), and the flow
  only where the catalog marks it unique (FL-289 is a tie).
* **`minimumCostMaximumFlow`** minimizes cost over all maximum flows, so a negative cycle away from
  every s–t path is still saturated (FL-313).

### Connectivity

* **Edge connectivity** is the unit-capacity flow or cut. λ(s, t) is the number of edge-disjoint
  paths, and λ(G) the global minimum cut with capacities 1 (Nagamochi–Ibaraki on `Graph`, Hao–Orlin
  on `DirectedGraph`). It is 0 below two vertices and when disconnected (FL-322, FL-325, FL-400).
* **Disjoint paths.** `edgeDisjointPaths(from:to:)` returns λ(s, t) paths with no edge in two;
  parallel edges are distinct (FL-506). `vertexDisjointPaths` returns κ(s, t) paths with no inner
  vertex in two, and edges from s to t give one path whatever their multiplicity (FL-509). Each is
  a simple path, and flow cycles in the unit flow are dropped while decomposing. Which paths are
  returned is unspecified. On `Graph` the paths are over `directedView`.
* **Vertex connectivity.** κ(K_n) = n − 1 (FL-365), and κ = 0 below two vertices or when not
  (strongly) connected (FL-320, FL-398, FL-464). Local κ(s, t) splits every other vertex v into
  v_in → v_out of capacity 1. Edges s → t count as one extra path, once whatever their
  multiplicity (FL-458: 2; FL-461: the reverse pair 0).
* **`minimumVertexCut(from:to:)`** is nil when an edge goes from source to target, because no
  vertex set separates them (FL-336, FL-432). Otherwise it is the canonical cut of the split
  network: v is in the cut when v_in is on the source side and v_out on the sink side, the minimum
  cut nearest the target. Edge arcs get capacity n, so only split arcs are cut.
* **`minimumVertexCut()`** uses Even's algorithm. Best = n − 1 and the vertices after the first.
  For i = 0, 1, … while i ≤ best, for each j > i, each pair (vᵢ, vⱼ) (on `DirectedGraph` also
  (vⱼ, vᵢ)) with no edge from the first to the second gives a local canonical cut, which replaces
  the best when strictly smaller. This is correct because the first vertex outside a minimum cut X
  has index ≤ κ and pairs with some later vertex that X separates from it. A complete graph keeps
  the vertices after the first (FL-366, FL-450).

## Determinism

| Entry point | Which result | Tests assert |
|---|---|---|
| `maximumFlow`, `dinicMaximumFlow` | Value; the canonical cut; the flow unspecified | Value, cut exactly; flow: capacity and conservation, value = Σ out of source |
| `edmondsKarpMaximumFlow` | The procedure's flow (rows in edge-position order, BFS stops at the sink, bottleneck augment) | Exact per-edge flows |
| `maximumFlowValue` | Value | Exact (floating rows: as computed) |
| `minimumCut(from:to:capacity:)` | Least sink side | Exact |
| `minimumCut(capacity:)` | A minimum cut, deterministic: the first vertex on the source side on `Graph` (its component when the positive edges leave several); Hao–Orlin's on `DirectedGraph` | The value exactly; the sides where unique (or by the components rule); otherwise the cut's validity |
| `gomoryHuTree` | Gusfield with the canonical cut, vertex order | Exact |
| `minimumCostFlow`, `minimumCostMaximumFlow` | Least cost; loop rule; the flow otherwise unspecified | Cost exactly; flow where unique; certificate |
| connectivity values | Definitions | Exact |
| `minimumVertexCut()` | Even's pair order, first strict minimum, canonical local cuts | Exact |
| `minimumVertexCut(from:to:)` | Nearest the target | Exact |
| `edgeDisjointPaths`, `vertexDisjointPaths` | λ(s, t) / κ(s, t) paths, deterministic, unspecified | The count; each path and the disjointness |

## Complexity

n vertices, m edges, κ the vertex connectivity.

| Entry point | Time | Extra memory |
|---|---|---|
| `maximumFlow`, `minimumCut(from:to:)` | O(n² √m) | residual network: n + 1 offsets, 2m arcs × (head, mate, residual) |
| `maximumFlowValue` | phase 1 of the above | same |
| `edmondsKarpMaximumFlow` | O(n m²) | same, plus a BFS queue and parent arcs |
| `dinicMaximumFlow` | O(n² m); O(m √n) unit networks; O(m min(√m, n^(2/3))) unit capacities | same, plus levels and current arcs |
| `minimumCut(capacity:)`, `Graph` | O(nm log n) in the worst case (n phases of O(m log n)) | the contracted graph as linked arc lists (2m arcs), an indexed heap or bucket queue |
| `minimumCut(capacity:)`, `DirectedGraph` | O(n²m) in the worst case, one push–relabel run per pass, two passes | two residual networks (the graph and its reverse), bucket lists |
| `gomoryHuTree` | n − 1 maximum flows | one residual network, reset per run |
| `minimumCostFlow` | no polynomial bound for block-search network simplex | spanning-tree arrays (parent, predecessor arc and direction, thread, reverse thread, successor count, last successor, potential), n + m |
| `minimumCostMaximumFlow` | a maximum flow, then `minimumCostFlow` | as both |
| `edgeConnectivity(from:to:)` | Dinic, unit capacities | residual network |
| `edgeConnectivity()` | `Graph`: Nagamochi–Ibaraki, unit; `DirectedGraph`: Hao–Orlin, unit | as the global cuts |
| `edgeDisjointPaths(from:to:)` | Dinic on the unit network, then O(m) decomposition | unit residual network |
| `vertexDisjointPaths(from:to:)` | Dinic on the split network: O(m √n), then O(n + m) | split residual network |
| `vertexConnectivity(from:to:)`, `minimumVertexCut(from:to:)` | Dinic on the split network (2n vertices, n + m arcs): O(m √n) | split residual network |
| `vertexConnectivity()`, `minimumVertexCut()` | O((κ + 1) · n) local flows, each cut off at the best so far | one split network, reset per run |

## Implementation

* **Residual network.** Compressed sparse rows by tail in index space: `first` (n + 1 offsets) and
  per arc one record {`head: Int32`, `mate: Int32` (the paired reverse arc), `residual: C`}. It is
  built in O(n + m) by a counting sort over the edges in position order, so each row lists its arcs
  in edge-position order, which Edmonds–Karp's flow depends on. `forwardArc: [Int32]` reports flows
  by edge number. It is built once per call and reset between runs inside Gomory–Hu and
  connectivity. At most 2³¹ − 1 arcs (checked; the split networks have 4m or 2(n + 2m)).
* **Push–relabel** (Goldberg–Tarjan, with the Cherkassky–Goldberg 1997 heuristics). Highest-label
  selection with per-label lists of active and inactive vertices, current-arc pointers, the gap
  heuristic, and global relabelling by reverse BFS from the sink at the start and after relabel work
  of 12n + 2m. The first phase stops when no active vertex has a label below n. The second returns
  the excess to the source by push–relabel toward the source on the vertices that cannot reach the
  sink, labelled by their breadth-first distance to the source, highest label first.
* **Dinic.** BFS levels from the source, stopped at the sink's level, and an iterative DFS with an
  explicit stack of arcs and current-arc pointers.
* **Edmonds–Karp.** BFS with parent arcs and a flat queue.
* **Nagamochi–Ibaraki.** The contracted graph as doubly linked arc lists per group, parallel edges
  merged at the start and as groups merge, a member list per group for the sides, and the best side
  recorded when a phase improves it. Edges with q(e) at least the global best are contracted, and a
  merged parallel edge keeps the greater q.
* **Hao–Orlin.** On the same residual network, with buckets in ordered lists per set of vertices,
  dormant sets for the gap heuristic, and active vertices at the front of each bucket.
* **Network simplex** (Király–Kovács 2012). An artificial root with big-M arcs, the spanning tree
  as parent, predecessor arc, thread, reverse thread, successor count and last successor arrays, the
  block search pivot (blocks of √m arcs), strongly feasible trees to avoid cycling, and potentials
  updated on the moved subtree only. Self-loops are settled before the tree is built. Only the
  artificial arcs are unbounded: a growing artificial arc never blocks, and every problem arc's room
  is c − f exactly. Artificial flows never grow in total, because a cycle raising two of them costs
  big M plus at most n − 1 problem arcs and so never enters, and they stay within the positive
  supplies' sum.
* **Connectivity.** Dinic on unit and split networks with a value cutoff (stop once the flow reaches
  the best so far). The global λ uses the global cuts with unit capacities.

## Tests

Public API only, each test self-contained. Every catalog row; multigraph rows on
`DirectedPseudograph`/`Pseudograph`; traps as exit tests. Properties with swift-property-based on
random networks: the three maximum flows agree on value and `minimumCut`; every flow satisfies
capacity and conservation; the cut's value equals the flow value; no vertex on the sink side is
reachable from the source in the residual network built from the returned flow; `maximumFlowValue`
equals `maximumFlow().value`; Gomory–Hu's `minimumCutValue` equals `minimumCut(from:to:)` for every
pair; `minimumCostFlow` passes its potential certificate and equals a successive-shortest-path
oracle written in the test; connectivity ≤ minimum degree and κ ≤ λ.
