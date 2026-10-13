# ImplicitGraphs: case catalog

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 python3
Tests/Catalogs/ImplicitGraphs/ref.py`; `--write` regenerates this file, `--stress` adds random
closures). Every graph is checked against the DirectedGraph laws and against NetworkX 3.7 on the
materialized graph (`bfs_layers`, components, shortest path lengths, Dijkstra).

Conventions:

* `IG (n, closure)` is `ImplicitDirectedGraph(vertexCount: n, successors: closure)`. Named closures:
  * `ring5` = `{ [($0 + 1) % 5] }`;
  * `diamond` = `{ [[1, 2], [3], [3], []][$0] }`;
  * `parallel` = `{ [[1, 1, 0], []][$0] }`;
  * `twoCycles` = `{ [[1], [0, 2], [3], [2], []][$0] }`;
  * `grid` is a 4 × 3 grid of cells `r * 4 + c`, walls at 5 and 6 (no edges in or out), with
    neighbors in the order up, left, right, down.
* Edge positions are written `s.r→t`: source `s`, rank `r` in the source's row, target `t`. They are
  equal and ordered by `(s, r)`; the target rides along.
* `calls()` is the number of closure calls since the previous `calls()` (the test counts in its
  own closure, so this is public behavior, not a benchmark counter).
* Groups `Generic` and `Closures` are cross-module. `Generic` runs the Traversal,
  Connectivity, Cycles and ShortestPaths algorithms on the implicit graph and compares with
  NetworkX. Components are compared as sets, since their order is the owning module's rule.
  `Closures` rows cover ShortestPaths D19 and one Traversal entry point. They pin
  distances and path vertex counts, not tie-breaking. `P(x, y)` is a `Hashable` point, and
  `knight1` gives each knight move cost 1. In `costly` a step's cost depends only on the cell
  entered, so the goal's first push already has its distance; in `twoEnded` it depends on both
  ends, and a search that tests the goal when it is pushed, not when it is settled, answers more
  (`ref.py` asserts this for IG-030 and IG-031). `line2` = `{ [($0 + 1, 2)] }`; `reopen` is
  S→A 1, S→B 2, A→C 3, B→C 1, C→G 3 on states 0…4 (S, A, B, C, G); `zeroCycle` is
  0→1→2→3→0 at cost 0, with 0→9 at 2 and 3→9 at 1.
* `**trap**` rows are preconditions, run as exit tests.
* `throws VertexNotFound` is what a `checked:` spelling throws for a vertex not in `0..<n` (README
  Principle 6), where the plain spelling traps.

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| IG-001 | Construction | no vertices: the closure is never called | IG (0, { _ in [] }) / vertices / edges / edgeCount / calls() | []; []; 0; 0 |
| IG-002 | Construction | a ring; nothing is called at construction | IG (5, ring5) / calls() / vertexCount / vertexIndexBound / edgeIndexBound | 0; 5; 5; nil |
| IG-003 | Construction | negative vertex count | ImplicitDirectedGraph(vertexCount: -1, successors: { _ in [] }) | **trap** (negative vertex count -1) |
| IG-004 | Reads | successors(of:) calls the closure once and returns its sequence | IG (4, diamond) / successors(of: 0) / calls() / successors(of: 3) / calls() | [1, 2]; 1; []; 1 |
| IG-005 | Reads | outEdges(of:) positions carry (source, rank, target); one call | IG (4, diamond) / outEdges(of: 0) / calls() / outDegree(of: 0) / calls() | [0.0→1, 0.1→2]; 1; 2; 1 |
| IG-006 | Reads | source/target(ofEdgeAt:) read the position, no call | IG (4, diamond) / let p = outEdges(of: 0)[1] / calls() / source(ofEdgeAt: p) / target(ofEdgeAt: p) / calls() | 0.1→2; 1; 0; 2; 0 |
| IG-007 | Reads | edges in row order; one call per vertex; edgeCount the same | IG (4, diamond) / Array(edges) / calls() / edgeCount / calls() | [0.0→1, 0.1→2, 1.0→3, 2.0→3]; 4; 4; 4 |
| IG-008 | Reads | edges.index(after:) re-reads the row: O(d) per step | IG (4, diamond) / edges.index(after: 0.0→1) / calls() / edges.index(after: 0.1→2) / calls() / edges.index(after: 2.0→3) / calls() | 0.1→2; 1; 1.0→3; 2; endIndex; 2 |
| IG-009 | Reads | parallel edges and a self-loop are distinct positions | IG (2, parallel) / outEdges(of: 0) / outDegree(of: 0) / contains(edge: 0→1) / contains(edge: 0→0) / contains(edge: 1→0) | [0.0→1, 0.1→1, 0.2→0]; 3; true; true; false |
| IG-010 | Reads | contains: no call for vertices, one row scan for an edge | IG (4, diamond) / contains(3) / contains(4) / contains(-1) / calls() / contains(edge: 1→3) / contains(edge: 9→3) / calls() | true; false; false; 0; true; false; 1 |
| IG-011 | Reads | index members are the identity | IG (4, diamond) / vertexIndex(of: 2) / vertex(atIndex: 3) / successorIndices(ofIndex: 0) | 2; 3; [1, 2] |
| IG-012 | Traps | successors(of:) a non-vertex | IG (4, diamond) / successors(of: 4) | **trap** (4 is not a vertex of the graph) |
| IG-013 | Traps | outDegree(of:) a negative vertex | IG (4, diamond) / outDegree(of: -1) | **trap** (-1 is not a vertex of the graph) |
| IG-014 | Traps | the closure returns a non-vertex: trap when it is read | IG (2, { _ in [0, 2] }) / successors(of: 0) | **trap** (successor 2 of 0 is not a vertex (0..<2)) |
| IG-015 | Traps | a negative successor, read by edgeCount | IG (2, { _ in [-1] }) / edgeCount | **trap** (successor -1 of 0 is not a vertex (0..<2)) |
| IG-016 | Generic | breadthFirstLayers on the grid: one call per discovered vertex | IG (12, grid) / breadthFirstLayers(from: 0) / calls() / breadthFirstLayers(from: 5) | [[0], [1, 4], [2, 8], [3, 9], [7, 10], [11]]; 10; [[5]] |
| IG-017 | Generic | shortestPaths(from:) distances | IG (12, grid) / shortestPaths(from: 0).distance(to:) for 0..<12 | [0, 1, 2, 3, 1, nil, nil, 4, 2, 3, 4, 5] |
| IG-018 | Generic | dijkstraShortestPaths with weight from the position: entering a cell in row r costs r + 1 | IG (12, grid) / dijkstraShortestPaths(from: 0, weight: { $0.target / 4 + 1 }).distance(to:) for 0..<12 | [0, 1, 2, 3, 2, nil, nil, 5, 5, 8, 11, 8] |
| IG-019 | Generic | weaklyConnectedComponents as sets | IG (5, twoCycles) / weaklyConnectedComponents() | [[0, 1, 2, 3], [4]] |
| IG-020 | Generic | stronglyConnectedComponents as sets | IG (5, twoCycles) / stronglyConnectedComponents() | [[0, 1], [2, 3], [4]] |
| IG-021 | Generic | topologicalSort is a valid order on a DAG and nil on a cycle | IG (4, diamond) / topologicalSort() is a topological order / IG(5, twoCycles).topologicalSort() | true; nil |
| IG-022 | Generic | a ring is one strongly connected component | IG (5, ring5) / stronglyConnectedComponents() / findCycle()!.count | [[0, 1, 2, 3, 4]]; 5 |
| IG-023 | Closures | Traversal (exists): breadthFirstSearch over an unbounded grid, depth limit 2 | breadthFirstSearch(from: [P(0, 0)], depthLimit: 2, successors: grid4) / discovered vertices | 13 |
| IG-024 | Closures | D19 Dijkstra: knight from (0, 0) to (7, 7) on an unbounded board | dijkstraShortestPath(from: P(0, 0), successors: knight1, success: { $0 == P(7, 7) }) / (distance, path.count) | (6, 7) |
| IG-025 | Closures | D19 A*: the same, with the admissible knight bound | aStarShortestPath(from: P(0, 0), successors: knight1, heuristic: knightBound, success: { $0 == P(7, 7) }) / (distance, path.count) | (6, 7) |
| IG-026 | Closures | D19 Dijkstra: unbounded grid, entering (x, y) costs 1 + (x² + y) mod 3 | dijkstraShortestPath(from: P(0, 0), successors: costly, success: { $0 == P(4, -3) }) / distance | 12 |
| IG-027 | Closures | D19 A*: the same with Manhattan distance (admissible: every step costs ≥ 1) | aStarShortestPath(from: P(0, 0), successors: costly, heuristic: manhattan(to: P(4, -3)), success: { $0 == P(4, -3) }) / distance | 12 |
| IG-028 | Closures | D19: the start satisfies success | dijkstraShortestPath(from: 3, successors: { [($0 + 1, 1)] }, success: { $0 == 3 }) / (distance, path.count) | (0, 1) |
| IG-029 | Closures | D19: a finite space with no goal returns nil | dijkstraShortestPath(from: 0, successors: { $0 < 10 ? [($0 + 1, 1)] : [] }, success: { $0 == 20 }) / (distance, path.count) | nil |
| IG-030 | Closures | D19 Dijkstra: a step from p to q costs 1 + (p.x · q.y) mod 3, so the goal's first push is not its distance | dijkstraShortestPath(from: P(0, 0), successors: twoEnded, success: { $0 == P(-4, 4) }) / distance | 8 |
| IG-031 | Closures | D19 A*: the same with Manhattan distance | aStarShortestPath(from: P(0, 0), successors: twoEnded, heuristic: manhattan(to: P(-4, 4)), success: { $0 == P(-4, 4) }) / distance | 8 |
| IG-032 | Closures | D19 cutoff, inclusive: each step costs 2, so the goal 3 (distance 6) is found under cutoff 6 and not under 5, and the search ends on the infinite line | dijkstraShortestPath(from: 0, cutoff: 6, successors: line2, success: { $0 == 3 }) / (distance, path.count) / the same with cutoff: 5 / states expanded under cutoff 5 | (6, 4); nil; [0, 1, 2] |
| IG-033 | Closures | D19 cutoff below zero: only the start is reached, and it is still expanded | dijkstraShortestPath(from: 0, cutoff: -1, successors: line2, success: { $0 == 0 }) / (distance, path.count) / the same with success: { $0 == 1 } / successors calls | (0, 1); nil; 1 |
| IG-034 | Closures | D19 cutoff under A*: it bounds the distance, so the costly grid's goal (12) is found under cutoff 12, not under 11, by A* and Dijkstra alike | aStarShortestPath(from: P(0, 0), cutoff: 12, successors: costly, heuristic: manhattan(to: P(4, -3)), success: { $0 == P(4, -3) }) / distance / the same with cutoff: 11 / dijkstraShortestPath with cutoff: 11 | 12; nil; nil |
| IG-035 | Closures | D19 A* with an admissible, inconsistent heuristic reopens C (3) and still answers 6; successors is called once per expansion and heuristic once per push | aStarShortestPath(from: 0, successors: reopen, heuristic: { [0, 0, 4, 0, 0][$0] }, success: { $0 == 4 }) / (distance, path) / states expanded / heuristic calls / dijkstraShortestPath: states expanded | (6, [0, 2, 3, 4]); [0, 1, 3, 2, 3]; [0, 1, 2, 3, 4, 3, 4]; [0, 1, 2, 3] |
| IG-036 | Closures | D19 with Double costs | dijkstraShortestPath(from: 0, successors: { $0 < 3 ? [($0 + 1, 0.5), ($0 + 2, 1.25)] : [] }, success: { $0 == 3 }) / (distance, path.count) / aStarShortestPath with heuristic: { Double(3 - $0) * 0.5 } | (1.5, 4); (1.5, 4) |
| IG-037 | Closures | D19 zero-cost steps and a zero-cost cycle: each state is expanded once | dijkstraShortestPath(from: 0, successors: zeroCycle, success: { $0 == 9 }) / (distance, path) / states expanded | (1, [0, 1, 2, 3, 9]); [0, 1, 2, 3] |
| IG-038 | Closures | D19 several goals: the nearest by cost (5, five steps), not by steps (-3, three steps costing 6) | dijkstraShortestPath(from: 0, successors: { [($0 + 1, 1), ($0 - 1, 2)] }, success: { $0 == 5 \|\| $0 == -3 }) / (distance, path) / aStarShortestPath with heuristic: { min(abs(5 - $0), abs(-3 - $0)) } | (5, [0, 1, 2, 3, 4, 5]); (5, [0, 1, 2, 3, 4, 5]) |
| IG-039 | Closures | D19: a negative step cost | dijkstraShortestPath(from: 0, successors: { _ in [(1, -1)] }, success: { $0 == 1 }) | **trap** (Dijkstra's algorithm and A* need nonnegative weights (and no NaN); use Bellman–Ford) |
| IG-040 | Closures | D19: a negative step cost traps even when the cutoff drops the step | dijkstraShortestPath(from: 0, cutoff: 0, successors: { _ in [(1, -1)] }, success: { $0 == 1 }) | **trap** (Dijkstra's algorithm and A* need nonnegative weights (and no NaN); use Bellman–Ford) |
| IG-041 | Closures | D19: a NaN step cost | dijkstraShortestPath(from: 0, successors: { _ in [(1, Double.nan)] }, success: { $0 == 1 }) | **trap** (Dijkstra's algorithm and A* need nonnegative weights (and no NaN); use Bellman–Ford) |
| IG-042 | Closures | D19: a NaN heuristic estimate | aStarShortestPath(from: 0, successors: { $0 == 0 ? [(1, 1.0)] : [] }, heuristic: { $0 == 1 ? .nan : 0 }, success: { $0 == 1 }) | **trap** (An A* priority (distance plus heuristic estimate) is NaN) |
| IG-043 | Closures | D19: an infinite cost plus an estimate of -∞ is a NaN priority | aStarShortestPath(from: 0, successors: { $0 == 0 ? [(1, .infinity), (3, 5)] : [] }, heuristic: { $0 == 1 ? -.infinity : 0 }, success: { $0 == 1 \|\| $0 == 3 }) | **trap** (An A* priority (distance plus heuristic estimate) is NaN) |
| IG-044 | Closures | D19: a NaN cutoff | dijkstraShortestPath(from: 0, cutoff: .nan, successors: { _ in [(1, 1.0)] }, success: { $0 == 1 }) | **trap** (The cutoff is NaN) |
| IG-045 | Reads | edges.isEmpty and edges.first read startIndex: a call per row up to the first non-empty one, so n calls when there are no edges | IG (5, { _ in [] }) / edges.isEmpty / calls() / edges.first / calls() | true; 5; nil; 5 |
| IG-046 | Reads | checked: spellings answer a vertex as the plain ones do, one call each; a non-vertex throws without a call | IG (4, diamond) / successors(checked: 0) / calls() / outEdges(checked: 0) / outDegree(checked: 3) / vertexIndex(checked: 2) / calls() / successors(checked: 4) / outEdges(checked: -1) / outDegree(checked: 4) / vertexIndex(checked: -1) / vertexIndex(checked: 4) / calls() | [1, 2]; 1; [0.0→1, 0.1→2]; 0; 2; 2; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; throws VertexNotFound; 0 |
