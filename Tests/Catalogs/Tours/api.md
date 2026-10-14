# Tours API

Walks that cover a graph: Eulerian trails and circuits (every edge once), Hamiltonian paths and
cycles (every vertex once), and travelling-salesman tours (the lightest Hamiltonian cycle, exactly
or approximately). Every result is one of the `Walks` types: `Trail`, `Circuit`, `Path` or
`Cycle`.

`cases.md` (TO-001 – TO-531) holds the expected values. `ref.py` recomputes every row from small
models of this API, checks each against brute force, renders the catalog, and compares it with
`cases.md` byte for byte. It also checks the Eulerian rows against NetworkX 3.7, and, when
`IGRAPH_C_LIB` and `JGRAPHT_CLASSPATH` are set, against igraph 1.0's C functions and JGraphT 1.5.2;
the tour rows against JGraphT's tours and NetworkX's minimum spanning tree and `christofides`.
`--stress` adds random multigraphs, digraphs, Hamiltonian instances and tour instances against the
same oracles. Run `uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with
rustworkx==0.18.1 python3 Tests/Catalogs/Tours/ref.py [--stress] [--write]` (`--write` needs both
native libraries; see ref.py's docstring).

## Public API

```swift
extension DirectedGraph {
    var isEulerian: Bool                                       // O(n + m)
    var hasEulerianTrail: Bool                                 // O(n + m)
    func eulerianCircuit() -> Circuit<Vertex, Edges.Index>?
    func eulerianCircuit(from start: Vertex) -> Circuit<Vertex, Edges.Index>?
    func eulerianTrail() -> Trail<Vertex, Edges.Index>?
    func eulerianTrail(from start: Vertex) -> Trail<Vertex, Edges.Index>?

    func hamiltonianPath() -> Path<Vertex, Edges.Index>?
    func hamiltonianPath(from start: Vertex) -> Path<Vertex, Edges.Index>?
    func hamiltonianPath(from start: Vertex, to end: Vertex) -> Path<Vertex, Edges.Index>?
    func hamiltonianCycle() -> Cycle<Vertex, Edges.Index>?

    // The asymmetric problem, by Held–Karp.
    func shortestTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
}

extension Graph {
    // The same six Eulerian and four Hamiltonian entry points, in incidentEdges order.

    func nearestNeighborTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
    func nearestNeighborTour<W: Comparable & AdditiveArithmetic>(from start: Vertex, weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
    func christofidesTour<W: SignedInteger>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
    func christofidesTour<W: FloatingPoint>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
    func twoOptTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
    func twoOptTour<W: Comparable & AdditiveArithmetic>(improving tour: Cycle<Vertex, Edges.Index>, weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
    func shortestTour<W: Comparable & AdditiveArithmetic>(weight: (Edges.Index) -> W) -> Cycle<Vertex, Edges.Index>?
}
```

`Circuit` and `Cycle` compare up to rotation and reversal, so tests compare both the arrays and the
values.

## Semantics

### Eulerian: the rules

| Case | Rule | Rows |
|---|---|---|
| Empty graph (no vertex) | Eulerian, has a trail; `eulerianCircuit()` and `eulerianTrail()` nil (a circuit needs an edge, a trail a vertex) | TO-001 – TO-004 |
| Vertices, no edges | Eulerian; circuit nil; trail the trivial trail at the first vertex | TO-005 – TO-012 |
| Isolated vertices beside edges | Ignored | TO-057 – TO-064, TO-205 – TO-208 |
| Self-loop, undirected | Degree + 2; walked once | TO-013 – TO-016, TO-073 – TO-076 |
| Self-loop, directed | In + 1, out + 1 | TO-173 – TO-176 |
| Loop on an otherwise isolated vertex, plus other edges | Two components with edges: no circuit or trail | TO-025 – TO-028, TO-081 – TO-084, TO-241 – TO-244 |
| Parallel edges | Separate edges, each walked once | TO-033 – TO-040 |
| Directed connectivity | Weak, among vertices with edges (balanced, this is strong) | TO-201 – TO-204 |

So `isEulerian` holds exactly when `eulerianCircuit() != nil || edgeCount == 0`, and
`hasEulerianTrail` exactly when `eulerianTrail() != nil || vertexCount == 0`.

### Eulerian: the walk

Hierholzer's algorithm in its stack form: push the start; while the stack is not empty, look at
the top vertex v; if v has an unused edge, take the first in v's `incidentEdges` (`outEdges`)
order, mark it, and push its other end; otherwise pop v onto the output. The output reversed is
the trail. On an undirected graph a self-loop appears twice in its row and is taken once. Start:
for a circuit (and a trail of an Eulerian graph) the first vertex in `vertices` order with an
edge; for a trail otherwise the first odd vertex (undirected) or the vertex with out − in = 1
(directed).

### Hamiltonian

* **Definitions follow the `Walks` types.** A Hamiltonian path is a `Path` through every vertex;
  a Hamiltonian cycle a `Cycle` through every vertex. So one vertex is a trivial Hamiltonian path
  (TO-292); a one-vertex graph has a Hamiltonian cycle exactly when it has a self-loop (TO-293,
  TO-295); a two-vertex graph exactly when two parallel edges (an antiparallel pair, directed) join
  them (TO-299, TO-361). Self-loops never extend a path (TO-302). The empty graph has neither
  (TO-290).
* **Which one: the first in search order.** Depth-first backtracking from each vertex in
  `vertices` order (the cycle only from the first vertex: every Hamiltonian cycle passes it),
  extending through each vertex's `incidentEdges` (`outEdges`) in order to an unvisited vertex,
  the cycle closed by the first edge in the last vertex's row that returns to the start and is not
  already used. Equivalently: the least by (start index, the row index of each edge taken, the row
  index of the closing edge), which ref.py checks by enumerating every Hamiltonian path and cycle
  (n ≤ 8). The search prunes only subtrees with no solution (an unreachable vertex, a vertex left
  with too few free neighbours), so the first solution is unchanged.
* **An undirected cycle leaves the first vertex through the lesser of its two edges in that
  vertex's row**: the search tries that edge's subtree first, and the reversed cycle lies in it.
  This matches Cycles' canonical form.
* **`hamiltonianPath(from:to:)`** with `start == end` is nil unless the graph has one vertex
  (TO-390, TO-391). A vertex that is not the graph's traps (TO-397 – TO-399).

### Tours

* **The simple graph.** Tours read the lightest edge of each pair, the earliest position on ties,
  and ignore self-loops. The returned `Cycle` uses those edges, so `cycle.weight(weight)` is the
  tour's length (TO-434, TO-482). `weight` is called once per non-loop edge, in position order,
  before any work.
* **Fewer than three vertices: nil** (TO-415 – TO-418, TO-437 – TO-440, …), before any other
  check. A tour is a Hamiltonian cycle of the simple graph, and K₁ and K₂ have none.
* **Complete graphs.** The heuristics trap on a missing pair, checked before any work (TO-492 –
  TO-494). `shortestTour` needs no completeness: a missing pair is an absent edge, and nil means
  no Hamiltonian cycle (TO-488 – TO-490).
* **Weights.** `Comparable & AdditiveArithmetic`; negative and zero weights are ordinary (TO-411,
  TO-454). Weights must be finite: NaN (TO-498 – TO-500, TO-529) and ±∞ (TO-503 – TO-506, TO-530)
  trap in every tour, on every non-loop copy, tested as w − w ≠ 0 (zero for every finite value
  and every integer, NaN for NaN and ±∞). Floating sums are formed in a fixed order, so the
  results are deterministic; catalog rows use dyadic values. `christofidesTour` takes
  `SignedInteger` or `FloatingPoint`, as `minimumWeightMatching` does, and checks every weight
  against the matching's bound, n · (2 · |weight| + 1) ≤ `W.max / 8` (`greatestFiniteMagnitude
  / 8`), as it is read (TO-505). 2-opt compares d(a,c) + d(b,e) < d(a,b) + d(c,e) instead of
  subtracting, so unsigned weights work and only sums of two weights must fit.
* **Nearest neighbour**: the nearest unvisited vertex, the first in `vertices` order on ties.
* **Christofides**, determined piece by piece: the canonical minimum spanning tree (weight, then
  position, as SpanningTrees' `minimumSpanningTree(weight:)`, computed by dense Prim on the
  matrix); the odd-degree tree vertices in `vertices` order; `minimumWeightMatching` on their
  complete graph (pairs i < j lexicographic); the multigraph of the tree edges in position order,
  then the matched pairs; Hierholzer from the first vertex as above; the first visit of each
  vertex kept. On metric rows the tour is within 3/2 of the optimum (checked by brute force).
* **2-opt**: t[0..n] with t[n] = t[0]; repeat: over i in 0 ..< n − 2 and j in i + 2 ..< n, take
  the move with the greatest gain (d(tᵢ, tᵢ₊₁) + d(tⱼ, tⱼ₊₁)) − (d(tᵢ, tⱼ) + d(tᵢ₊₁, tⱼ₊₁)),
  the first in row-major order on ties, when the gain is positive, and reverse t[i+1 … j]; stop
  when none gains. t[0] never moves, so the result starts where `tour` does (TO-466).
  `twoOptTour(weight:)` starts from `nearestNeighborTour` from the first vertex.
* **Held–Karp**: c(v, S) = the least weight of a path from v through the vertices not in S back to
  the first vertex; the tour reconstructed from the first vertex, each step the lowest-index next
  vertex whose cost matches exactly, so it is the lexicographically least optimal tour. On a
  `DirectedGraph` the same program reads d(v, u) as the lightest arc v → u, so every step is along
  an arc (TO-507 – TO-528). The table, 2ⁿ⁻¹ · (n − 1) weights and as many validity bytes, must fit
  in 4 GiB: n ≤ 25 for 8-byte weights, 26 for 4-byte ones (TO-501, TO-502).

## Determinism

| Entry point | Which result |
|---|---|
| `isEulerian`, `hasEulerianTrail` | Definitions |
| `eulerianCircuit`, `eulerianTrail` (both forms) | Hierholzer, first unused edge in row order, the documented start |
| `hamiltonianPath`, `hamiltonianCycle` (all forms) | The first in search order (row order) |
| `nearestNeighborTour` | Nearest, first in vertex order on ties |
| `christofidesTour` | The composition above |
| `twoOptTour` (both forms) | Best improvement, first in row-major order on ties |
| `shortestTour` (both) | Optimal, lexicographically least from the first vertex |

Tests assert every result exactly.

## Complexity

n vertices, m edges.

| Entry point | Time | Extra memory |
|---|---|---|
| `isEulerian`, `hasEulerianTrail` | O(n + m): degrees from the rows, then a depth-first reach from the first vertex with an edge | O(n) |
| `eulerianCircuit`, `eulerianTrail` | O(n + m) | rows in index space, a used bit per edge, a cursor per vertex, the stack |
| `hamiltonianPath`, `hamiltonianCycle` | exponential, O(n!) paths in the worst case; O(degree) per step plus O(n + m) per reachability test, skipped when it cannot fail, so a path or cycle graph is O(n + m); `hamiltonianPath()` repeats the search per start, n searches when there is none | O(n + m) |
| `nearestNeighborTour` | O(n²) after O(n + m) to read the weights | n × n weights |
| `christofidesTour` | O(n³): the tree O(n²), the matching O(k³) on k ≤ n odd vertices, Hierholzer O(n) | O(n²) |
| `twoOptTour` | O(n²) per move | n × n weights |
| `shortestTour` | Θ(2ⁿ n²) | Θ(2ⁿ n): 2ⁿ⁻¹ (n − 1) weights, plus as many validity bytes on a graph that is not complete |
