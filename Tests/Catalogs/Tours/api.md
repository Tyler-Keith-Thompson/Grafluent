# Tours: proposed API (phase 1)

Walks that cover a graph: Eulerian trails and circuits (every edge once), Hamiltonian paths and
cycles (every vertex once), and travelling-salesman tours (the lightest Hamiltonian cycle, exactly
or approximately). The README's row: Hierholzer, backtracking Hamiltonian path and cycle,
Christofides, 2-opt; results `Trail`, `Circuit`, `Path`, `Cycle`. Every result is one of the
`Walks` types, never a new one.

* **Eulerian.** `isEulerian`, `hasEulerianTrail`, `eulerianCircuit()`, `eulerianCircuit(from:)`,
  `eulerianTrail()`, `eulerianTrail(from:)`, on `DirectedGraph` and `Graph`, by Hierholzer's
  algorithm with a pinned edge order (the same walk as igraph's procedure under our row order).
* **Hamiltonian.** `hamiltonianPath()`, `hamiltonianPath(from:)`, `hamiltonianPath(from:to:)`,
  `hamiltonianCycle()` on both: backtracking, the first path or cycle in a documented search order.
* **Tours** (on `Graph`, weights by edge position). `nearestNeighborTour(weight:)` and
  `(from:weight:)`, `christofidesTour(weight:)`, `twoOptTour(weight:)` and
  `twoOptTour(improving:weight:)` (JGraphT `TwoOptHeuristicTSP`'s procedure, the same tour), and
  `shortestTour(weight:)` (Held–Karp, the same tour as JGraphT `HeldKarpTSP`; open question 2), on
  `DirectedGraph` too (the asymmetric problem; added after the critical review, open question 3).
  Every tour requires finite weights: NaN and ±∞ trap.

`cases.md` (TO-001 – TO-531, 531 cases) pins the values; `ref.py` recomputes every row from small
models of this API, checks each against brute force and the reference libraries, renders the
catalog, and compares it with `cases.md` byte for byte. Eulerian rows: the definitions; a brute
search over edge sequences (stress); NetworkX 3.7 `is_eulerian`, `has_eulerian_path`,
`eulerian_circuit`, `eulerian_path`; igraph 1.0's C functions `igraph_is_eulerian`,
`igraph_eulerian_cycle` and `igraph_eulerian_path`, exactly (their walk reproduced by our model
with igraph's row order on every row and 1,500 stress graphs); JGraphT 1.5.2
`HierholzerEulerianCycle.isEulerian`. Hamiltonian rows: brute force over every permutation and
edge choice for the pinned order (n ≤ 8) and a bitmask DP for existence (n ≤ 16). Tours: brute
force over permutations for the optimum (n ≤ 9); `twoOptTour(improving:)`, `shortestTour` and
`nearestNeighborTour` (where its ties allow) equal JGraphT's tours vertex for vertex; Christofides
is checked piecewise (the tree's weight against NetworkX `minimum_spanning_tree`, the matching
against brute force, the 3/2 bound on metric rows, and NetworkX `christofides` where it gives the
same cycle). `--stress` adds 1,500 random multigraphs and digraphs, 400 Hamiltonian instances and
300 tour instances, all against the same oracles and the native libraries. Run `uv run --quiet
--no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1 python3
Tests/Catalogs/Tours/ref.py [--stress] [--write]` (about a second; `IGRAPH_C_LIB` and
`JGRAPHT_CLASSPATH` switch on the native checks, see ref.py's docstring, and `--write` needs both).

## Scope

**In, phase 1**

| Entry point | On | Traces |
|---|---|---|
| `isEulerian` | both | NetworkX `is_eulerian`, igraph `igraph_is_eulerian` (`has_cycle`), JGraphT `HierholzerEulerianCycle.isEulerian`, LEMON `eulerian()`, Mathematica `EulerianGraphQ` |
| `hasEulerianTrail` | both | NetworkX `has_eulerian_path`, igraph `igraph_is_eulerian` (`has_path`), R igraph `has_eulerian_path` |
| `eulerianCircuit()`, `eulerianCircuit(from:)` | both | NetworkX `eulerian_circuit(G, source=)`, igraph `igraph_eulerian_cycle`, JGraphT `getEulerianCycle`, LEMON `EulerIt` / `DiEulerIt` (with a start node), Mathematica `FindEulerianCycle` |
| `eulerianTrail()`, `eulerianTrail(from:)` | both | NetworkX `eulerian_path(G, source=)`, igraph `igraph_eulerian_path`, R igraph `eulerian_path` |
| `hamiltonianPath()`, `(from:)`, `(from:to:)` | both | Mathematica `FindHamiltonianPath[g]`, `[g, s, t]`; NetworkX `tournament.hamiltonian_path` (tournaments only) |
| `hamiltonianCycle()` | both | Mathematica `FindHamiltonianCycle`; JGraphT `HamiltonianCycleAlgorithm.getTour` (the interface) |
| `nearestNeighborTour(weight:)`, `(from:weight:)` | `Graph` | JGraphT `NearestNeighborHeuristicTSP(first)` (its default constructor starts at a random vertex), NetworkX `greedy_tsp(G, source=)` (which is nearest neighbour, despite the name); LEMON `NearestNeighborTsp` is a name trace only: it starts from the lightest edge and grows a deque at both ends, a different procedure and tour |
| `christofidesTour(weight:)` | `Graph` | NetworkX `christofides`, JGraphT `ChristofidesThreeHalvesApproxMetricTSP`, LEMON `ChristofidesTsp` |
| `twoOptTour(weight:)`, `twoOptTour(improving:weight:)` | `Graph` | JGraphT `TwoOptHeuristicTSP.getTour` / `improveTour`; LEMON `Opt2Tsp::run()` / `run(tour)` is a name trace only: first improvement with a restart of the scan after each move, which ends at a different 2-optimal tour |
| `shortestTour(weight:)` | both | JGraphT `HeldKarpTSP` (undirected and directed graphs), Mathematica `FindShortestTour` (the name; it is a heuristic there for large inputs) |

**NetworkX functions, and where each goes**

| NetworkX | Here | Reason |
|---|---|---|
| `is_eulerian` | `isEulerian` | In; isolated vertices ignored here (igraph, JGraphT, the textbook definition), counted there (TO-009) |
| `has_eulerian_path(G, source)` | `hasEulerianTrail`; with a source, `eulerianTrail(from:) != nil` | In; "trail", the README's word for a walk that repeats no edge (`Path` repeats no vertex) |
| `is_semieulerian` | — | `hasEulerianTrail && !isEulerian`; no second name (open question 6) |
| `eulerian_circuit(G, source, keys)` | `eulerianCircuit()`, `eulerianCircuit(from:)` | In. `keys=` is unnecessary: a `Circuit` carries edge positions, which tell parallel edges apart |
| `eulerian_path(G, source, keys)` | `eulerianTrail()`, `eulerianTrail(from:)` | In |
| `eulerize` | — | Phase 2 with the Chinese postman problem (open question 4) |
| `tournament.hamiltonian_path` | `hamiltonianPath()` | Any digraph here; a tournament always has one (TO-374) |
| `christofides(G, tree=)` | `christofidesTour(weight:)` | In; `tree=` (a caller's spanning tree) left out |
| `greedy_tsp(G, source)` | `nearestNeighborTour(from:weight:)` | In under the procedure's name. NetworkX's `greedy_tsp` is nearest neighbour; JGraphT's `GreedyHeuristicTSP` is the greedy edge heuristic, a different algorithm (phase 2) |
| `traveling_salesman_problem(G, nodes, cycle, method)` | — | Phase 2 (open question 5): it runs the heuristic on the shortest-path metric closure and returns a closed walk of G, not a cycle |
| `simulated_annealing_tsp`, `threshold_accepting_tsp` | — | Phase 2 at the earliest: randomized local search with five tuning parameters; 2-opt is the deterministic local search |
| `asadpour_atsp` | — | Phase 2 with asymmetric tours (open question 3); needs an LP and random spanning trees |

**Other libraries**

| Library | Functions | Here |
|---|---|---|
| igraph (C 1.0) | `igraph_is_eulerian(graph, &has_path, &has_cycle)`, `igraph_eulerian_path`, `igraph_eulerian_cycle` (edge and vertex vectors; `IGRAPH_ENOSOL` when none) | In; the same start rules, the same Hierholzer procedure, a different row order. python-igraph 1.0 has none of them; R igraph has `has_eulerian_path`, `has_eulerian_cycle`, `eulerian_path`, `eulerian_cycle` |
| JGraphT 1.5 | `HierholzerEulerianCycle` (`isEulerian`, `getEulerianCycle`), `ChinesePostman.getCPPSolution`, `HamiltonianCycleAlgorithm.getTour`, `HamiltonianCycleImprovementAlgorithm.improveTour`; tours: `ChristofidesThreeHalvesApproxMetricTSP`, `TwoOptHeuristicTSP`, `HeldKarpTSP`, `NearestNeighborHeuristicTSP`, `GreedyHeuristicTSP`, `NearestInsertionHeuristicTSP`, `FarthestInsertionHeuristicTSP`, `RandomTourTSP`, `TwoApproxMetricTSP`, `PalmerHamiltonianCycle` | Christofides, 2-opt, Held–Karp and nearest neighbour in; the insertion, greedy-edge and double-tree heuristics, Palmer (Ore graphs only) and the Chinese postman later. JGraphT has no Eulerian *path* class; its backtracking Hamiltonian path classes are on master only, unreleased |
| LEMON 1.3.1 | `eulerian()`, `EulerIt`, `DiEulerIt`; `ChristofidesTsp`, `GreedyTsp`, `InsertionTsp`, `NearestNeighborTsp`, `Opt2Tsp` | Iterators become our `Circuit`; `eulerian()` counts isolated nodes (its doc notes graphs with an Euler tour that it calls not Eulerian); we do not |
| Boost | `metric_tsp_approx`, `metric_tsp_approx_tour`, `metric_tsp_approx_from_vertex` (MST preorder, the double-tree 2-approximation); no Eulerian or Hamiltonian functions | Double tree later if asked (`TwoApproxMetricTSP` in JGraphT); Christofides dominates it on metric inputs |
| Mathematica | `EulerianGraphQ`, `FindEulerianCycle`, `HamiltonianGraphQ`, `FindHamiltonianCycle`, `FindHamiltonianPath`, `FindShortestTour`, `FindPostmanTour` (no `FindEulerianPath`, no semi-Eulerian test) | The names `shortestTour` (FindShortestTour) and `hamiltonianPath(from:to:)` (`FindHamiltonianPath[g, s, t]`) |
| petgraph 0.8, rustworkx 0.18 | none (checked: no Eulerian, Hamiltonian or TSP function in either) | — |

**Also out**

| Not in phase 1 | Reason |
|---|---|
| Fleury's algorithm | O(m²) (a bridge test per step); Hierholzer is O(n + m) and what every library ships |
| `isHamiltonian` | As expensive as `hamiltonianCycle()`, which answers it (`!= nil`); open question 6 |
| Exact Hamiltonicity by DP (Bellman–Held–Karp on reachability) | The pinned result is the first in search order; any algorithm that returns it is allowed, so DP can become the implementation for n ≤ 20 or so if benchmarks favour it (Implementation notes) |
| Directed (asymmetric) heuristics | Phase 2 (open question 3): nearest neighbour on a digraph, then NetworkX's `asadpour_atsp`; 2-opt and Christofides are symmetric algorithms. `shortestTour` on `DirectedGraph` is in (JGraphT's `HeldKarpTSP` takes digraphs; TO-507 – TO-531) |
| Tours over a distance closure `(Vertex, Vertex) -> W` or points | Phase 2 (open question 5): README open question 3 decided weights are closures over edge positions; a complete graph of n² edges is the input here |
| Or-opt, 3-opt, Lin–Kernighan, neighbour lists, don't-look bits | Phase 2, as separately named functions: they change which tour comes out, and `twoOptTour` is pinned to JGraphT's procedure |
| Eulerize, Chinese postman | Phase 2 (open question 4) |

## Summary

```swift
import GraphProtocols
import Walks

extension DirectedGraph {
    /// Whether some closed trail uses every edge exactly once: every vertex has as many edges in
    /// as out (a self-loop is one of each), and the vertices with edges are weakly connected
    /// (which, balanced, makes them strongly connected). Isolated vertices are ignored, and an
    /// edgeless graph, the empty graph included, is Eulerian. O(n + m).
    public var isEulerian: Bool { get }

    /// Whether some trail uses every edge exactly once: Eulerian, or exactly one vertex with
    /// out − in = 1, one with in − out = 1, the rest balanced, and the vertices with edges weakly
    /// connected. True for every edgeless graph. O(n + m).
    public var hasEulerianTrail: Bool { get }

    /// An Eulerian circuit by Hierholzer's algorithm from the first vertex (in `vertices` order)
    /// with an edge, or nil when the graph is not Eulerian or has no edges (a `Circuit` has at
    /// least one). Pinned: from the current vertex, the first unused edge in `outEdges` order;
    /// the circuit is listed forward, starting at that vertex. O(n + m).
    public func eulerianCircuit() -> Circuit<Vertex, Edges.Index>?

    /// The same from `start`; nil also when `start` has no edges.
    /// - Precondition: `start` is a vertex of the graph.
    public func eulerianCircuit(from start: Vertex) -> Circuit<Vertex, Edges.Index>?

    /// An Eulerian trail, or nil when there is none or the graph has no vertex. Starts at the
    /// vertex with out − in = 1, or, when the graph is Eulerian, at the first vertex with an edge
    /// (the circuit as a closed trail); the trivial trail at the first vertex when there are no
    /// edges. Hierholzer's walk as `eulerianCircuit()`. O(n + m).
    public func eulerianTrail() -> Trail<Vertex, Edges.Index>?

    /// An Eulerian trail from `start`, or nil when none starts there (NetworkX
    /// `has_eulerian_path(G, source)`): `start` must be the vertex with out − in = 1, or, in an
    /// Eulerian graph, any vertex with an edge, or any vertex at all when there are no edges.
    /// - Precondition: `start` is a vertex of the graph.
    public func eulerianTrail(from start: Vertex) -> Trail<Vertex, Edges.Index>?

    /// A Hamiltonian path, or nil when there is none (or no vertex): the first one a
    /// depth-first backtracking search finds, from each vertex in `vertices` order, extending by
    /// `outEdges` order. Self-loops never help; one vertex is the trivial path. Exponential in the
    /// worst case (O(n!) paths); sound pruning keeps the order. The search is rerun from each
    /// start in turn, so a graph with no Hamiltonian path costs n searches.
    public func hamiltonianPath() -> Path<Vertex, Edges.Index>?
    /// The first from `start`.
    /// - Precondition: `start` is a vertex of the graph.
    public func hamiltonianPath(from start: Vertex) -> Path<Vertex, Edges.Index>?
    /// The first from `start` that ends at `end`; nil when `start == end` and there is more than
    /// one vertex.
    /// - Precondition: `start` and `end` are vertices of the graph.
    public func hamiltonianPath(from start: Vertex, to end: Vertex) -> Path<Vertex, Edges.Index>?

    /// A Hamiltonian cycle, or nil: the search from the first vertex, closed by the first edge
    /// back to it. A self-loop is the cycle of a one-vertex graph and an antiparallel pair the
    /// cycle of a two-vertex one (the `Cycle` type's rules). Exponential in the worst case.
    public func hamiltonianCycle() -> Cycle<Vertex, Edges.Index>?
}

extension Graph {
    // Eulerian: the same six entry points. Degrees count a self-loop twice; incidentEdges order.
    public var isEulerian: Bool { get }
    public var hasEulerianTrail: Bool { get }
    public func eulerianCircuit() -> Circuit<Vertex, Edges.Index>?
    public func eulerianCircuit(from start: Vertex) -> Circuit<Vertex, Edges.Index>?
    /// Starts at the first odd vertex (in `vertices` order) when the graph is not Eulerian.
    public func eulerianTrail() -> Trail<Vertex, Edges.Index>?
    /// `start` must be one of the two odd vertices, or, Eulerian, any vertex with an edge.
    public func eulerianTrail(from start: Vertex) -> Trail<Vertex, Edges.Index>?

    // Hamiltonian: the same four, incidentEdges order. Two parallel edges are the cycle of a
    // two-vertex graph.
    public func hamiltonianPath() -> Path<Vertex, Edges.Index>?
    public func hamiltonianPath(from start: Vertex) -> Path<Vertex, Edges.Index>?
    public func hamiltonianPath(from start: Vertex, to end: Vertex) -> Path<Vertex, Edges.Index>?
    public func hamiltonianCycle() -> Cycle<Vertex, Edges.Index>?

    // Tours. A tour is a Hamiltonian cycle of the simple graph: self-loops are ignored and each
    // pair of vertices is joined by its lightest edge (the earliest position on ties), which is
    // the edge the returned `Cycle` uses. nil below three vertices, before any other check.
    // `weight` is called once per non-loop edge, in position order, before any work. A NaN or
    // infinite weight traps (with +∞ and −∞ both present a sum is NaN, which broke Held–Karp's
    // reconstruction: TO-506); sums along a tour must fit in W.

    /// The nearest-neighbour tour from the first vertex: repeatedly the nearest unvisited
    /// vertex, the first in `vertices` order on ties (NetworkX `greedy_tsp`, JGraphT
    /// `NearestNeighborHeuristicTSP(first)`). No approximation guarantee. O(n²).
    /// - Precondition: the graph is complete (every pair of distinct vertices joined).
    public func nearestNeighborTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
    /// The same from `start`. - Precondition: also, `start` is a vertex of the graph.
    public func nearestNeighborTour<W: Comparable & AdditiveArithmetic>(from start: Vertex, weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?

    /// Christofides' tour (Christofides–Serdyukov, 1976): the canonical minimum spanning tree
    /// (SpanningTrees' tree, by a dense Prim of its own), a minimum-weight perfect matching on
    /// its odd-degree vertices (MatchingModule, Galil's blossom), an Eulerian circuit of the
    /// union by Hierholzer from the first vertex, shortcut to the first visit of each vertex. At
    /// most 3/2 × the shortest tour when the weights satisfy the triangle inequality (not
    /// checked). O(n³) (the matching).
    /// Two overloads because `minimumWeightMatching` has two (integer and floating weights).
    /// - Precondition: complete; the matching's bound, n · (2 · |weight| + 1) ≤ `W.max / 8`
    ///   (`greatestFiniteMagnitude / 8`), checked on every weight as it is read, whether or not
    ///   the matching sees it (TO-505); for a fixed-width integer, so n ≤ `W.max / 8`.
    public func christofidesTour<W: SignedInteger>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
    public func christofidesTour<W: FloatingPoint>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?

    /// 2-opt (Croes 1958) from `nearestNeighborTour(weight:)`: `twoOptTour(improving:weight:)` of
    /// that tour.
    /// - Precondition: complete; the sum of any two weights fits in W.
    public func twoOptTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?

    /// `tour` improved by 2-opt to a 2-optimal tour, JGraphT `TwoOptHeuristicTSP.improveTour`'s
    /// procedure (the same tour on integers and exactly representable sums): best improvement,
    /// the first move (i, j) in row-major order on ties, until no exchange of two edges for two
    /// lighter ones remains. The first vertex of `tour` stays first. Only `tour.vertices` is read.
    /// O(n²) per move; no polynomial bound on the number of moves is known in general.
    /// - Precondition: complete; `tour.vertices` lists every vertex of the graph exactly once.
    public func twoOptTour<W: Comparable & AdditiveArithmetic>(improving tour: Cycle<Vertex, Edges.Index>, weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?

    /// The shortest tour, by Held–Karp dynamic programming (Bellman; Held–Karp 1962): the
    /// least-weight Hamiltonian cycle of the simple graph, or nil when there is none; among the
    /// optimal ones, the lexicographically least by vertex index listed from the first vertex
    /// (JGraphT `HeldKarpTSP`'s tour). The graph need not be complete. Θ(2ⁿ n²) time, Θ(2ⁿ n)
    /// memory: n = 20 is practical (2¹⁹ · 19 entries: 80 MB of table for 8-byte weights on a
    /// complete graph, 90 MB on another, with a validity byte per entry).
    /// - Precondition: the table, 2ⁿ⁻¹ · (n − 1) weights and as many validity bytes, fits in
    ///   4 GiB: n ≤ 25 for 8-byte weights, 26 for 4-byte ones (TO-501, TO-502). JGraphT's limit
    ///   of 31 is the width of its `int` bitmask, not a memory bound (its table at 31 vertices
    ///   would be 2³¹ · 31 doubles, about 530 GB).
    public func shortestTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
}

extension DirectedGraph {
    /// The shortest directed tour (the asymmetric problem), by the same Held–Karp program: the
    /// least-weight Hamiltonian cycle of the simple digraph (each ordered pair's lightest arc,
    /// self-loops ignored), each step along an arc; the lexicographically least optimal one
    /// from the first vertex (JGraphT `HeldKarpTSP` on a directed graph). nil below three
    /// vertices, as on `Graph` (an antiparallel pair is a `Cycle`, but not a tour here).
    /// - Precondition: as on `Graph`.
    public func shortestTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
}
```

No new result types. Every walk is the graph's own vertices and edge positions; `Circuit` and
`Cycle` compare up to rotation, so tests compare the arrays (pinned) and the values.

## Names

| Grafluent | Used by | Not chosen, and why |
|---|---|---|
| `isEulerian` | NetworkX `is_eulerian`, JGraphT `isEulerian`, Mathematica `EulerianGraphQ`, LEMON `eulerian()` | — |
| `eulerianCircuit` | NetworkX `eulerian_circuit`; "Eulerian circuit" (Wikipedia, Diestel) | `eulerianCycle` (igraph, JGraphT `getEulerianCycle`, Mathematica `FindEulerianCycle`): in Grafluent a `Cycle` repeats no vertex, and an Eulerian circuit usually does; the result type is `Circuit` |
| `eulerianTrail`, `hasEulerianTrail` | "Eulerian trail" (Wikipedia: "Eulerian trail (or Eulerian path)"); the README's row "Eulerian trail and circuit" | `eulerianPath` (NetworkX, igraph): a `Path` repeats no vertex, so the result would contradict its name; the README's terminology settles path vs trail |
| `hamiltonianPath`, `hamiltonianCycle` | Mathematica `FindHamiltonianPath`, `FindHamiltonianCycle`; NetworkX `tournament.hamiltonian_path` | `hamiltonianTour` (JGraphT's `getTour`): "tour" is kept for the weighted problem |
| `…Tour(weight:)` | JGraphT `getTour`, LEMON's TSP classes (`tour()`), Mathematica `FindShortestTour` | `…TravelingSalesman…` (NetworkX `traveling_salesman_problem`): the problem's name, long, and spelled two ways |
| `nearestNeighborTour` | JGraphT `NearestNeighborHeuristicTSP`, LEMON `NearestNeighborTsp` | `greedyTour` (NetworkX `greedy_tsp`): JGraphT's and LEMON's `Greedy…` are the greedy *edge* heuristic, a different algorithm |
| `christofidesTour` | NetworkX `christofides`, JGraphT `ChristofidesThreeHalvesApproxMetricTSP`, LEMON `ChristofidesTsp` | — |
| `twoOptTour`, `improving:` | JGraphT `TwoOptHeuristicTSP` and `improveTour`, LEMON `Opt2Tsp`; "2-opt" (Croes) | `opt2Tour` (LEMON's word order); `improve…` as a separate verb: the tour is still the result, as `twoOptTour(weight:)`'s |
| `shortestTour` | Mathematica `FindShortestTour` | `heldKarpTour` (JGraphT `HeldKarpTSP`): only needed if a second exact algorithm is added; `optimalTour`, `minimumWeightHamiltonianCycle`: no library spells them (open question 2) |

**Proposed Terminology rows**

* Closed trail using every edge once: Eulerian circuit, `eulerianCircuit()`; a graph with one is
  Eulerian, `isEulerian`. NetworkX; igraph and JGraphT say Eulerian cycle. Mathematical term:
  Euler tour, Eulerian circuit.
* Trail using every edge once: Eulerian trail, `eulerianTrail()`, `hasEulerianTrail`. NetworkX
  and igraph say Eulerian path. Mathematical term: Eulerian trail (semi-Eulerian graph when it is
  not closed).
* Path / cycle through every vertex once: Hamiltonian path, Hamiltonian cycle. All.
* Hamiltonian cycle of a weighted complete graph, as a travelling-salesman solution: tour,
  `…Tour(weight:)`. JGraphT, LEMON, Mathematica. Mathematical term: Hamiltonian cycle; the
  problem is the TSP.

## Semantics

### Eulerian: the rules (decisions)

| Case | Here | NetworkX 3.7 | igraph 1.0 (C) | JGraphT 1.5 | LEMON 1.3 | Rows |
|---|---|---|---|---|---|---|
| Empty graph (no vertex) | Eulerian, has a trail; `eulerianCircuit()` and `eulerianTrail()` nil (a circuit needs an edge, a trail a vertex) | raises `NetworkXPointlessConcept` | has path and cycle; zero-length results | `isEulerian` false; `getEulerianCycle` throws | `eulerian()` true | TO-001 – TO-004 |
| Vertices, no edges | Eulerian; circuit nil; trail the trivial trail at the first vertex | one vertex: Eulerian, empty circuit; two or more: not Eulerian | Eulerian; zero-length | Eulerian; empty walk | not Eulerian when more than one node | TO-005 – TO-012 |
| Isolated vertices beside edges | Ignored | Make it not Eulerian, no path | Ignored | Ignored | Make it not Eulerian | TO-057 – TO-064, TO-205 – TO-208 |
| Self-loop, undirected | Degree + 2; walked once | Degree + 2 | Degree + 2 (listed once in its rows) | Degree + 2 | — | TO-013 – TO-016, TO-073 – TO-076 |
| Self-loop, directed | In + 1, out + 1 | Same | Same | Same | — | TO-173 – TO-176 |
| Loop on an otherwise isolated vertex, plus other edges | Two components with edges: none | Same | Same (its "self-looping singleton" rule) | Same | — | TO-025 – TO-028, TO-081 – TO-084, TO-241 – TO-244 |
| Parallel edges | Separate edges, each walked once | `MultiGraph` | Same | Same | — | TO-033 – TO-040 |
| Directed connectivity | Weak, among vertices with edges | Strong (circuit), weak (path), over all vertices | Weak | Strong, among components with edges | Weak (`undirector`) | TO-201 – TO-204 |

So `isEulerian` holds exactly when `eulerianCircuit() != nil || edgeCount == 0`, and
`hasEulerianTrail` exactly when `eulerianTrail() != nil || vertexCount == 0` (open question 1
asks whether the empty graph should instead be not Eulerian, JGraphT's answer).

### Eulerian: the walk (decision)

Hierholzer's algorithm in its stack form, written down so the result is pinned: push the start;
while the stack is not empty, look at the top vertex v; if v has an unused edge, take the first in
v's `incidentEdges` (`outEdges`) order, mark it, and push its other end; otherwise pop v onto the
output. The output reversed is the trail. On an undirected graph a self-loop appears twice in its
row and is taken once. Start: for a circuit (and a trail of an Eulerian graph) the first vertex in
`vertices` order with an edge; for a trail otherwise the first odd vertex (undirected) or the
vertex with out − in = 1 (directed).

This is igraph's procedure step for step, including both start rules (`igraph_i_is_eulerian_*`
set `start_of_path` the same way). igraph's incidence lists differ (by neighbour, then edge id
descending, a loop once), so its walk differs on some rows; ref.py reproduces igraph's own
output on every row and every stress graph with its row order, which confirms the model and our
start rules. NetworkX's `_simplegraph_eulerian_circuit` is the same procedure too, run on
`G.copy()`, whose adjacency is not the original's (the copy re-inserts every edge from both ends in
node order, so a vertex's earlier-numbered neighbours move to the front): with that row order the
model reproduces NetworkX's `eulerian_path` on every simple graph `--stress` tries (about 200), and with ours it
equals NetworkX where the copy keeps the order (TO-032, TO-144) and differs elsewhere (TO-112,
TO-263). NetworkX's undirected `eulerian_circuit` yields the pop order, so it runs backward relative
to its own `eulerian_path`. LEMON's `EulerIt` starts at "the first node that has an incident
edge", as ours.

The cost of pinning is nil: Hierholzer with a per-vertex cursor into its row is the fast
implementation anyway (Implementation notes).

### Hamiltonian (decision)

* **Definitions follow the `Walks` types.** A Hamiltonian path is a `Path` through every vertex;
  a Hamiltonian cycle a `Cycle` through every vertex. So one vertex is a trivial Hamiltonian path
  (TO-292); a one-vertex graph has a Hamiltonian cycle exactly when it has a self-loop (TO-293,
  TO-295); a two-vertex graph exactly when two parallel edges (an antiparallel pair, directed) join
  them (TO-299, TO-361). Self-loops never extend a path (TO-302). The empty graph has neither
  (TO-290). Mathematica's `HamiltonianGraphQ` and the textbooks require three vertices for a
  simple graph; the multigraph cases follow from the type rules, as `findCycle()` treats a loop
  and a parallel pair as cycles.
* **Which one: the first in search order.** Depth-first backtracking from each vertex in
  `vertices` order (the cycle only from the first vertex: every Hamiltonian cycle passes it),
  extending through each vertex's `incidentEdges` (`outEdges`) in order to an unvisited vertex,
  the cycle closed by the first edge in the last vertex's row that returns to the start and is not
  already used. Equivalently: the least by (start index, the row index of each edge taken, the row
  index of the closing edge), which ref.py checks by enumerating every Hamiltonian path and cycle
  (n ≤ 8). Pruning that only cuts subtrees with no solution (an unreachable vertex, a vertex left
  with too few free neighbours) cannot change the first one, so it is allowed; reordering (Warnsdorff's
  rule, degree ordering) is not, since it would change the result.
* **An undirected cycle leaves the first vertex through the lesser of its two edges in that
  vertex's row**: the search tries that edge's subtree first, and the reversed cycle lies in it.
  This matches Cycles' canonical form ("starts at its least vertex and leaves it through the
  lesser of its two edges").
* **`hamiltonianPath(from:to:)`** with `start == end` is nil unless the graph has one vertex
  (TO-390, TO-391). A vertex that is not the graph's traps (TO-397 – TO-399).

### Tours (decisions)

* **The simple graph.** Tours read the lightest edge of each pair, the earliest position on ties
  (JGraphT `HeldKarpTSP`'s `min`; NetworkX's tours need a simple `Graph`), and ignore
  self-loops (NetworkX `christofides` removes them). The returned `Cycle` uses those edges, so
  `cycle.weight(weight)` is the tour's length (TO-434, TO-482).
* **Fewer than three vertices: nil** (TO-415 – TO-418, TO-437 – TO-440, …). A tour is a Hamiltonian cycle of the
  simple graph, and K₁ and K₂ have none. NetworkX returns `[0, 0]` (`greedy_tsp`) or raises
  (`christofides` on one vertex), and `[a, b, a]` on two; JGraphT returns a one-vertex walk and
  `[a, b, a]`. Neither is a `Cycle` (open question 7).
* **Complete graphs.** The heuristics trap on a missing pair (NetworkX "G must be a complete
  graph", JGraphT "Graph is not complete"), checked before any work (TO-492 – TO-494).
  `shortestTour` needs no completeness: a missing pair is an absent edge, and nil means no
  Hamiltonian cycle (TO-488 – TO-490; JGraphT `HeldKarpTSP` returns null the same way).
* **Weights.** `Comparable & AdditiveArithmetic`, as Dijkstra and the spanning trees; negative and
  zero weights are ordinary (TO-411, TO-454). Weights must be finite: NaN (TO-498 – TO-500,
  TO-529) and ±∞ (TO-503 – TO-506, TO-530) trap in every tour, on every non-loop copy, tested as
  w − w ≠ 0 (zero for every finite value and every integer, NaN for NaN and ±∞). With +∞ and −∞
  both present a sum is NaN, which every comparison rejects: Held–Karp then returned a one-vertex
  `Cycle` (TO-506, found by the critical review), and 2-opt's gains would be NaN. Integers are exact.
  Floating sums are formed in a fixed order, so the results are deterministic; catalog rows use
  dyadic values. `christofidesTour` takes `SignedInteger` or `FloatingPoint`, because
  `minimumWeightMatching` does. 2-opt compares d(a,c) + d(b,e) < d(a,b) + d(c,e) instead of
  subtracting, so unsigned weights work and only sums of two weights must fit.
* **Nearest neighbour**: the nearest unvisited vertex, the first in `vertices` order on ties. Equal
  to NetworkX `greedy_tsp` on every row (its `min` over a set of small integers runs in index
  order), and to JGraphT where its swap array does not reorder ties (rows say which).
* **Christofides**, pinned piece by piece, each piece already pinned upstream: the canonical
  minimum spanning tree (SpanningTrees' `minimumSpanningTree(weight:)`: weight, then position,
  computed here by a dense Prim of Tours' own, which gives the same unique tree); the
  odd-degree tree vertices in `vertices` order; `minimumWeightMatching` on their complete graph
  (pairs i < j lexicographic), which is NetworkX's `min_weight_matching` procedure; the multigraph
  of the tree edges in position order, then the matched pairs; Hierholzer from the first vertex as
  above; the first visit of each vertex kept. NetworkX's tour differs when its MultiGraph's
  adjacency (Kruskal order, then a Python set of matched pairs) leads Hierholzer elsewhere; rows
  say "= NetworkX christofides (as a cycle)" where it does not. On metric rows the tour is within
  3/2 of the optimum (checked by brute force).
* **2-opt** is JGraphT's `improve` exactly: t[0..n] with t[n] = t[0]; repeat: for i in 0 ..< n − 2,
  for j in i + 2 ..< n, change = d(tᵢ, tⱼ) + d(tᵢ₊₁, tⱼ₊₁) − d(tᵢ, tᵢ₊₁) − d(tⱼ, tⱼ₊₁); take the
  least change, the first on ties, when it is below zero, and reverse t[i+1 … j]; stop when none
  is. JGraphT stops below −1e-8 (`minCostImprovement`); we stop at 0. We also form the gain as
  (d(tᵢ, tᵢ₊₁) + d(tⱼ, tⱼ₊₁)) − (d(tᵢ, tⱼ) + d(tᵢ₊₁, tⱼ₊₁)), two sums then one difference, where
  JGraphT forms d1 + d2 − d3 − d4 left to right. The tour is JGraphT's exactly on integers and on
  weights whose sums are exactly representable (the catalog's dyadic rows); on other floating
  weights rounding and the threshold can pick different moves, so the tours may differ. t[0] never
  moves, so the result starts where `tour` does (TO-466).
  `twoOptTour(weight:)` starts from `nearestNeighborTour` from the first vertex; JGraphT's default
  starts from a random tour, NetworkX's annealing from `greedy_tsp`, which is the same tour.
* **Held–Karp**: c(v, S) = the least weight of a path from v through the vertices not in S back to
  the first vertex; the tour reconstructed from the first vertex, each step the lowest-index next
  vertex whose cost matches exactly (JGraphT's `reconstructTour`). Floating ties are compared as
  computed, in the same order JGraphT computes them. On a `DirectedGraph` the same program reads
  d(v, u) as the lightest arc v → u (JGraphT's `computeMinimumWeights` on a directed graph), so the
  tour is the lexicographically least optimal one with every step along an arc; the catalog checks
  it against brute force and JGraphT (TO-507 – TO-528, and 200 `--stress` digraphs).

## Determinism (decision)

| Entry point | Which result | Tests assert |
|---|---|---|
| `isEulerian`, `hasEulerianTrail` | Definitions | Exact |
| `eulerianCircuit`, `eulerianTrail` (both forms) | Hierholzer, first unused edge in row order, the documented start | Exact vertices and edges |
| `hamiltonianPath`, `hamiltonianCycle` (all forms) | The first in search order (row order) | Exact |
| `nearestNeighborTour` | Nearest, first in vertex order on ties | Exact |
| `christofidesTour` | The pinned composition | Exact |
| `twoOptTour` (both forms) | JGraphT's best-improvement procedure | Exact |
| `shortestTour` (both) | Optimal, lexicographically least from the first vertex | Exact |

Everything is pinned, at no cost to speed: each pin is what the fast implementation does anyway
(Hierholzer's cursor, backtracking's natural order, Held–Karp's reconstruction), or the procedure
the README names (2-opt), whose faster relatives (neighbour lists, don't-look bits, Or-opt) belong
to phase 2 under their own names.

## Complexity

n vertices, m edges.

| Entry point | Time | Extra memory |
|---|---|---|
| `isEulerian`, `hasEulerianTrail` | O(n + m) (degrees from the rows, then a depth-first reach from the first vertex with an edge over the same rows, `_runOnUndirectedRows` or the out-rows) | O(n) |
| `eulerianCircuit`, `eulerianTrail` | O(n + m) | rows in index space (O(n + m)), a used bit per edge, a cursor per vertex, the stack |
| `hamiltonianPath`, `hamiltonianCycle` | exponential, O(n!) paths in the worst case; O(degree) per step plus O(n + m) per reachability test, skipped when it cannot fail (the end it left had no other unvisited neighbour), so a path or cycle graph is O(n + m); `hamiltonianPath()` repeats the search per start, n searches when there is none | O(n + m) |
| `nearestNeighborTour` | O(n²) after O(m) to read the weights | n × n weights, or rows read in place |
| `christofidesTour` | O(n³): MST O(n²) (Prim, dense), matching O(k³) on k ≤ n odd vertices, Hierholzer O(n) | O(n²) |
| `twoOptTour` | O(n²) per move | n × n weights |
| `shortestTour` | Θ(2ⁿ n²) | Θ(2ⁿ n): 2ⁿ⁻¹ (n − 1) weights, plus as many validity bytes on a graph that is not complete; 80 MB / 90 MB at n = 20 with 8-byte weights, at most 4 GiB |

## Dependencies, and what upstream has

* **SpanningTrees: not a dependency.** Christofides needs the canonical tree (weight, then
  position), which is unique under that strict order, so its own dense Prim on the matrix
  (O(n²), no graph value to build) gives SpanningTrees' `minimumSpanningTree(weight:)` tree
  exactly. The reuse pass may move that Prim into SpanningTrees as a `package` entry point.
* **MatchingModule: weighted general matching exists.** `minimumWeightMatching(weight:)` (Galil's
  O(n³) primal–dual blossom, NetworkX's `min_weight_matching` operation for operation, integer and
  floating overloads) is the minimum-weight perfect matching Christofides needs on a complete graph
  with an even number of odd vertices. It is an extension on `Graph`, so Tours needs a `Graph` to
  call it on: the complete graph over the odd vertices. Two ways:
  1. **Recommended: a `package` index-space entry point in MatchingModule**, the existing internal
     `_minimumWeightMatching(_:_:half:)` on `_MatchingGraph` made reachable from Tours (both are in
     this package), so no graph value is built and no `Matching` keeps a copy of one. A two-line
     visibility change upstream, plus a constructor for `_MatchingGraph` from (count, edge ends).
  2. Without touching MatchingModule: an internal `Graph` conformer in Tours, the complete graph
     on 0..<k with edge positions in lexicographic pair order, its weight closure reading the
     lightest copies. About 60 lines, and no upstream change.
  JGraphT uses Kolmogorov's Blossom V (`KolmogorovWeightedPerfectMatching`); LEMON its
  `MaxWeightedPerfectMatching`. Neither is needed: Galil's O(n³) on at most n vertices is below
  the O(n²) weights' reading only by a factor n, and Christofides at n = 500 is 68 ms in JGraphT.
* **Walks**: `Trail`, `Circuit`, `Path`, `Cycle` and their `package init(_uncheckedVertices:edges:)`
  are all Tours needs.
* **GraphProtocols**: `_runOnUndirectedRows` and `_withSuccessorIndexRows` give the rows in index
  space; `_vertexNumbering` for graphs without vertex indices. `scripts/modules.py` lists Tours'
  dependencies as GraphProtocols, Walks and MatchingModule.

## Implementation notes and performance plan

* **Hierholzer**: index space; per-vertex cursor into its row (`ptr[v]`), a used bit per edge
  (undirected only; directed edges are consumed by the cursor alone), an explicit stack of
  (vertex, edge) pairs filled into the output array back to front, so no reversal pass. Rows from
  `_withSuccessorIndexRows` / `_runOnUndirectedRows` when the representation offers them; one
  O(n + m) copy otherwise. No recursion, no closures capturing arrays (memory: boxed captures).
* **Hamiltonian search**: explicit stack of row cursors, a visited bit set, and pruning that is
  sound (cannot remove the first solution): a vertex not reachable from the path's end through
  unvisited vertices; for cycles, an unvisited vertex with fewer than two usable neighbours or
  the start unreachable. A bitmask DP (Bellman–Held–Karp on reachability, then the
  lexicographically least reconstruction) gives the same answer and bounds the work by 2ⁿ n²; if
  benchmarks show it wins for small n on non-Hamiltonian inputs (Petersen-like), switch below a
  size cut-off, as Kruskal/Prim switch in SpanningTrees.
* **Tours**: one n × n weight matrix in a flat `ContiguousArray<W>` plus one of edge positions,
  filled from the edges in one pass (lightest copy, earliest on ties); every heuristic reads it.
  2-opt keeps the tour in an array and reverses segments in place; the inner loop is two nested
  integer loops over the matrix, as JGraphT's. Held–Karp: a `[W?]`-free layout, a parallel
  validity byte per entry on a graph that is not complete, the table indexed S · (n − 1) + (v − 1)
  for S a set of vertices other than the first, filled by decreasing S (no recursion; JGraphT's
  recursive memo needs `-Xss` at large n). Directed, d(v, u) is read from a transposed copy of
  the matrix so the inner loop stays contiguous.
* **Baselines, measured here** (Apple silicon; NetworkX 3.7 and igraph 1.0 C in release; JGraphT
  1.5.2 on OpenJDK 25, best of 3 after warm-up):

  | Workload | NetworkX | igraph C | JGraphT |
  |---|---|---|---|
  | Eulerian circuit, torus 316 × 316 (99,856 vertices, 199,712 edges) | 698 ms | 9.3 ms | 81 ms |
  | `is_eulerian`, the same torus | 40 ms | 0.85 ms | — |
  | Eulerian circuit, directed closed walk (10⁴ vertices, 3·10⁵ edges, multi) | 2.65 s | — | — |
  | Christofides, 200 random points | 153 ms | — | 18 ms |
  | Christofides, 500 random points | 2.08 s | — | 68 ms |
  | Nearest neighbour, 1,000 points | 128 ms | — | 201 ms |
  | 2-opt from nearest neighbour, 1,000 points (`improveTour`) | — | — | 292 ms |
  | Held–Karp, 12 / 16 points | — | — | 1.1 ms / 13 ms |

* **Targets.** Eulerian circuit and trail within 1.25× igraph's C (`igraph_eulerian_cycle`) on the
  torus and on random closed walks, and at least 50× NetworkX; `isEulerian` within 1.25× igraph.
  Christofides at least 3× JGraphT at n = 500 (it is Java with boxed vertices and hash maps; ours
  is index space with a dense matrix), 2-opt at least 3× JGraphT's `improveTour` on the same start
  tour (the same moves, so a like-for-like measure of the inner loop), nearest neighbour at least
  10× both. Held–Karp at least 5× JGraphT at n = 16 (iterative, no boxing, a flat table).
  Hamiltonian search: no library baseline exists (JGraphT's backtracking classes are unreleased);
  the benchmark is the dodecahedron and knight's tours on 5 × 5 and 6 × 6 boards (paths) and
  Petersen and 4 × 4 knight (exhaustive failure), tracked against our own DP. LEMON's `EulerIt`
  and `Opt2Tsp` (C++) go into the Benchmarks package's baselines as earlier modules did.

### Tests

Public API only, each test self-contained (memory rules). Every catalog row; multigraph rows on
`Pseudograph` / `DirectedPseudograph`; traps as exit tests. Properties with swift-property-based:
on random closed walks, `eulerianCircuit()` uses every edge once and is a circuit of the graph
(`Circuit(vertices:edges:in:)` succeeds); `isEulerian == (eulerianCircuit() != nil || edgeCount ==
0)`; each Hamiltonian result passes `Path(vertices:edges:in:)` / `Cycle(vertices:edges:in:)` and has
every vertex; `shortestTour` ≤ every heuristic; `twoOptTour` ≤ its start tour and has no improving
move (checked by an O(n²) loop written in the test); Christofides ≤ 3/2 × `shortestTour` on random
Manhattan points. `just diff`: Eulerian answers against NetworkX (with the isolated-vertex rule
written in the comparison) and igraph's C functions under igraph's row order, if the differential
harness gains an igraph C hook; tours against JGraphT is out of `just diff`'s Python harness, so
the catalog carries those comparisons. `just mutate`: the cursor skipping used edges (TO-147), the
start rules (TO-216, TO-116), the closing-edge rule (TO-299), the lightest-copy rule (TO-434), the
tie rule of nearest neighbour (TO-403), 2-opt's first-on-ties (TO-464). `just fuzz`:
`eulerianCircuit` against the definition on random multigraphs.

## Library disagreements found

| Where | What | Catalog |
|---|---|---|
| Isolated vertices | NetworkX and LEMON's `eulerian()` count them (a graph with an isolated vertex is not Eulerian); igraph, JGraphT and the textbook definition ignore them; ours ignore them | TO-009, TO-057, TO-205 |
| Empty graph | NetworkX raises; igraph and LEMON true; JGraphT false; ours true | TO-001 |
| Directed connectivity | NetworkX and JGraphT test strong connectivity, igraph and LEMON weak; equivalent once balanced, except NetworkX counts isolated vertices | TO-201 |
| Undirected circuit direction | NetworkX's `eulerian_circuit` yields Hierholzer's pop order, so it runs backward relative to its own `eulerian_path` | EulerianCircuit rows |
| NetworkX's row order | Its Hierholzer runs on `G.copy()`, whose adjacency lists earlier-numbered neighbours first, so its walk differs from ours on some simple graphs | TO-112, TO-263 |
| igraph's row order | Neighbour, then edge id descending (found by matching 600 random graphs), so its circuit differs from ours on many rows; start rules equal | Eulerian rows |
| "Greedy" TSP | NetworkX `greedy_tsp` is nearest neighbour; JGraphT `GreedyHeuristicTSP` and LEMON `GreedyTsp` are the greedy edge heuristic | NearestNeighborTour rows |
| Tours of one or two vertices | NetworkX `[0, 0]` / `[a, b, a]` or raises; JGraphT a singleton walk / `[a, b, a]`; ours nil | TO-415 – TO-418 |
| JGraphT nearest neighbour ties | Its swap array reorders the candidates, so ties can go to a later vertex | rows marked "its swap-array tie order" |
| NetworkX Christofides | The same tree weight and matching weight, a different Hierholzer walk on some rows | TO-430 |
| JGraphT `TwoOptHeuristicTSP` | Default start is a random tour; stop threshold −1e-8; gains formed d1 + d2 − d3 − d4 | TwoOpt rows |
| JGraphT `HeldKarpTSP` limit | 31 vertices (the `int` bitmask), where the table would be about 530 GB; ours stops at a 4 GiB table (25 vertices with 8-byte weights) | TO-501, TO-502 |
| LEMON `NearestNeighborTsp`, `Opt2Tsp` | The names only: nearest neighbour from the lightest edge grown at both ends; 2-opt by first improvement with restart | — |

## README edits proposed

* **Algorithms table, `Tours` row**: "On `DirectedGraph` and `Graph`: `isEulerian`,
  `hasEulerianTrail`, `eulerianCircuit()`, `eulerianTrail()` (Hierholzer, a documented edge order;
  igraph's procedure), `hamiltonianPath()`, `hamiltonianCycle()` (backtracking, the first in
  search order); on `Graph`, tours of the simple graph: `nearestNeighborTour`, `christofidesTour`,
  `twoOptTour` (JGraphT's procedure), `shortestTour` (Held–Karp, also on `DirectedGraph`)
  (**planned**, phase 1). Later: Chinese postman, asymmetric heuristics, Or-opt and Lin–Kernighan" | results "`Circuit`, `Trail`,
  `Path`, `Cycle`".
* **Terminology**: the four rows under Names.

## Open questions

1. **The empty and edgeless graphs.** Recommended: Eulerian (igraph, LEMON's empty case, the
   vacuous definition), with `eulerianCircuit()` nil because a `Circuit` has an edge, and
   `eulerianTrail()` the trivial trail at the first vertex (nil only with no vertex).
   Alternative: JGraphT's "the null graph is not Eulerian", which makes `hasEulerianTrail` and
   `eulerianTrail() != nil` agree everywhere but leaves edgeless graphs with vertices Eulerian
   anyway. NetworkX's answer (raise; edgeless with two vertices not Eulerian) is not on the table.
2. **Held–Karp in phase 1, and its name.** Recommended: in, as `shortestTour(weight:)` — about
   60 lines, the only exact tour, the oracle every heuristic's tests compare with, and JGraphT's
   tour exactly. Name alternative `heldKarpTour`, if a second exact method (branch and bound,
   Concorde-style) is ever planned. If deferred, the ShortestTour group (TO-469 – TO-491, TO-500,
   TO-501) moves to phase 2.
3. **Asymmetric (directed) tours.** Decided after the critical review: `shortestTour` on
   `DirectedGraph` is in (TO-507 – TO-531). Phase 2: nearest neighbour on a digraph; Christofides
   and 2-opt do not apply; NetworkX's `asadpour_atsp` needs an LP.
4. **Eulerize and the Chinese postman problem.** Recommended: phase 2, as one entry point on
   `Graph`, `chinesePostmanTour(weight:) -> Walk?` (JGraphT `ChinesePostman.getCPPSolution`,
   Mathematica `FindPostmanTour`): Dijkstra between odd vertices (ShortestPaths, a new
   dependency) plus `minimumWeightMatching`, returning the closed walk; NetworkX's `eulerize`
   (which returns a multigraph, unweighted) then needs no separate API, since the walk's repeated
   edges are the added copies. Directed: a minimum-cost flow (Flows), as JGraphT's bipartite
   assignment.
5. **Tours on non-complete graphs and on distance functions.** Recommended: phase 2. NetworkX's
   `traveling_salesman_problem` (metric closure by shortest paths, a closed `Walk` back in the
   graph) needs ShortestPaths; a distance-closure entry point over vertex indices (OR-Tools'
   transit callbacks, Mathematica `FindShortestTour` on points) needs a decision against README
   open question 3, which chose closures over edge positions.
6. **`isHamiltonian`, `isSemiEulerian`.** Recommended: neither. `isHamiltonian` costs the same
   search as `hamiltonianCycle()`; `isSemiEulerian` is `hasEulerianTrail && !isEulerian`. Add
   `isHamiltonian` only if a cheaper decision procedure is used (none is known in general).
7. **Tours below three vertices.** Recommended: nil (the simple graph has no Hamiltonian cycle).
   Alternative: return a `Walk` (closed, `[a, b, a]`) from every tour function, as NetworkX and
   JGraphT do; that changes all tour results from `Cycle` to `Walk` and loses the type's
   guarantee, for two degenerate sizes.
8. **2-opt's start.** Recommended: nearest neighbour from the first vertex for
   `twoOptTour(weight:)` (deterministic, what NetworkX's local searches start from). JGraphT's
   default, the best of k random starts, would need a `using:` generator overload (the house
   pattern from CommunityDetection); phase 2 if asked.
9. **Matching access** (Dependencies): a `package` entry point in MatchingModule (recommended) or
   a private complete-graph conformer in Tours.
10. **Traces not verified by running.** Run here: NetworkX 3.7 (source read, every function
    called), igraph 1.0 C (built from the release tarball, every Eulerian function called; python-igraph
    1.0 has none), JGraphT 1.5.2 (source read; `HierholzerEulerianCycle`, `HeldKarpTSP`,
    `NearestNeighborHeuristicTSP`, `TwoOptHeuristicTSP`, `ChristofidesThreeHalvesApproxMetricTSP`
    called). Checked against documentation or source but not run: LEMON 1.3.1 (`eulerian`,
    `EulerIt`, `DiEulerIt`, `ChristofidesTsp`, `GreedyTsp`, `InsertionTsp`, `NearestNeighborTsp`,
    `Opt2Tsp`), Boost (`metric_tsp_approx*`, develop branch header), petgraph 0.8.3 and rustworkx
    0.18.1 (absence), Mathematica (the seven function pages; `EulerianGraphQ`'s treatment of
    isolated vertices is undocumented, so the table leaves it out).
