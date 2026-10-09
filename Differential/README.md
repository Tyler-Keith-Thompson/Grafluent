# Differential testing

The library against independent implementations on the same random graphs: NetworkX 3.7 and
scipy 1.18.1, pinned, run through `uv` so nothing is installed globally.

| Command | Does |
|---|---|
| `just diff` | 2,000 random cases with a random seed (about 20 s) |
| `just diff --cases 20000 --seed 7` | More cases, reproducibly |

`GrafluentDifferential` (this package) reads a batch of cases as JSON and answers them with the
library; `scripts/differential.py` generates the cases, asks NetworkX (and scipy's `csgraph`
where it applies) the same questions, and compares.

## What is compared

Only what ties cannot change: distances, reachability, whether a negative cycle is reachable or
exists anywhere, and the validity of every path and witness the library returns (each step an
edge, the stated length, a negative simple cycle reachable from a source). Parents and the
choice among equal paths are not compared, since correct implementations differ there.

Where two references answer the same question (Dijkstra in NetworkX and scipy), a disagreement
between them is reported on its own: it means a convention differs, not that the library is wrong.

| Library | NetworkX | scipy |
|---|---|---|
| `dijkstraShortestPaths(from:cutoff:weight:)` | `multi_source_dijkstra_path_length(cutoff:)` | `csgraph.dijkstra(indices:, min_only=True, limit:)` |
| `dijkstraShortestPath(from:to:weight:)` | `dijkstra_path_length`; the path is checked | — |
| `bellmanFordShortestPaths(from:weight:)` | `single_source_bellman_ford_path_length` from a super-source with zero edges to the sources; `NetworkXUnbounded` is `nil` | — |
| `findNegativeCycle(from:weight:)`, `findNegativeCycle(weight:)` | unbounded above; `negative_edge_cycle` | — |
| `shortestPaths(from:)` | `single_source_shortest_path_length`, nearest source | — |
| `simpleCycles()`, `simpleCycles(maxLength: 3)` (both kinds) | `simple_cycles`, `simple_cycles(length_bound=3)`, as vertex cycles up to rotation (and reversal, undirected), when there are at most 3 000; also canonical form, order by least vertex, and the bounded sequence equal to the unbounded one filtered | — |
| `girth()` (both kinds) | `girth`; directed, a breadth-first search back to each vertex | — |
| `isAcyclic`, `findCycle()` | `is_forest`; the cycle must exist exactly when the graph is not a forest, valid and canonical | — |
| `cycleBasis()` | m − n + c cycles (`number_connected_components`), independent over GF(2), each valid and canonical (NetworkX's Paton basis differs and is not compared) | — |

Cases: simple graphs on 0..<n (n ≤ 30, every tenth ≤ 300), directed or undirected, self-loops
allowed, sparse, dense, chains and grids, weights from {0…1, 0…3, 0…10, 0…1000} and in 30 % of
cases a few negative ones (half of the directed ones acyclic, so the distances are finite, some
with a negative cycle elsewhere), one to three sources, a cutoff in 30 %. The run prints how many
cases fell in each class.

A disagreement is written to `Differential/Failures/` (not committed) with the case and what
differed; it becomes a test in the module's suite, and then the file is deleted.
