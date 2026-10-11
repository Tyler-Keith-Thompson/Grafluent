# FunctionalGraphs: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 python3
Tests/Catalogs/FunctionalGraphs/ref.py`; `--write` regenerates this file, `--stress` adds the random
runs). Every graph is checked against NetworkX 3.7 (`attracting_components`, `simple_cycles`,
`weakly_connected_components`, distances to the cycles on the reverse graph, predecessors) and against
brute force from the definitions (iterating f; the first repeat of each orbit).

Conventions:

* `FG [f(0), f(1), …]` is `FunctionalGraph(successors: [...])`. Calls follow, separated by `/`; the
  expected column lists each call's result in order, separated by `;`.
* Edges are `p:s→t` with the edge position `p` (always the source).
* Decomposition calls are on `cycleDecomposition()`; `for 0..<n` lists the call for every vertex.
* A cycle detection result `(tail μ, cycle λ, root r)` is `(tailLength: μ, cycleLength: λ, root: r)`:
  μ steps from the start reach r, the first vertex on the cycle, and the cycle has λ vertices. `calls`
  is the number of times the closure was called (a test counts it in the closure); it pins the
  formulation in api.md.
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).
* Group `Generic` pins cross-module agreement (Connectivity) and lives in the integration suite.

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| FG-001 | Construction | empty | FG [] / vertexCount / edgeCount / edges | 0; 0; [] |
| FG-002 | Construction | one fixed point is a self-loop | FG [0] / vertices / edges / outDegree(of: 0) | [0]; [0:0→0]; 1 |
| FG-003 | Construction | edge position p is the edge leaving p | FG [1, 2, 0] / edges / edgeIndexBound / edgeIndex(of: 2) | [0:0→1, 1:1→2, 2:2→0]; 3; 2 |
| FG-004 | Construction | two vertices sharing a successor | FG [0, 0] / edges / contains(edge: 0→0) / contains(edge: 1→0) / contains(edge: 0→1) | [0:0→0, 1:1→0]; true; true; false |
| FG-005 | Construction | init(vertexCount:successor:), v² + 1 mod 5; called once per vertex, ascending | FunctionalGraph(vertexCount: 5, successor: { ($0 * $0 + 1) % 5 }) / successors / calls | [1, 2, 0, 0, 2]; [0, 1, 2, 3, 4] |
| FG-006 | Construction | init(vertexCount:successor:), no vertices: the closure is never called | FunctionalGraph(vertexCount: 0, successor: { _ in 0 }) / successors / calls | []; [] |
| FG-007 | Construction | init(vertexCount:successor:) with a successor outside 0..<n | FunctionalGraph(vertexCount: 2, successor: { _ in 2 }) | **trap** (successor 2 of 0 is not a vertex (0..<2)) |
| FG-008 | Construction | init(vertexCount:successor:) with a negative count | FunctionalGraph(vertexCount: -1, successor: { $0 }) | **trap** (negative vertex count -1) |
| FG-009 | Construction | successor out of range | FunctionalGraph(successors: [0, 3]) | **trap** (successor 3 of 1 is not a vertex (0..<2)) |
| FG-010 | Construction | negative successor | FunctionalGraph(successors: [-1]) | **trap** (successor -1 of 0 is not a vertex (0..<1)) |
| FG-011 | Construction | init?(_ graph:): vertex i is the graph's i-th vertex | FunctionalGraph(DirectedPseudograph(vertices: [c, a, b], edges: [c→a, a→b, b→a])) / successors | [1, 2, 1] |
| FG-012 | Construction | init?(_ graph:): the empty graph | FunctionalGraph(DirectedPseudograph(vertices: [], edges: [])) / successors | [] |
| FG-013 | Construction | init?(_ graph:): nil: b has out-degree 0 | FunctionalGraph(DirectedPseudograph(vertices: [a, b], edges: [a→b])) / successors | nil |
| FG-014 | Construction | init?(_ graph:): nil: a has out-degree 2 | FunctionalGraph(DirectedPseudograph(vertices: [a, b], edges: [a→b, a→a, b→b])) / successors | nil |
| FG-015 | Construction | init?(_ graph:): nil: parallel edges give a out-degree 2 | FunctionalGraph(DirectedPseudograph(vertices: [a, b], edges: [a→b, a→b, b→a])) / successors | nil |
| FG-016 | Reads | successor rows | FG [1, 2, 0, 0] / successor(of: 3) / successors(of: 3) / outEdges(of: 3) / outDegree(of: 3) / successorIndices(ofIndex: 1) | 0; [0]; [3]; 1; [2] |
| FG-017 | Reads | contains is false for non-vertices | FG [1, 2, 0] / contains(2) / contains(3) / contains(-1) / contains(edge: 2→0) / contains(edge: 2→1) / contains(edge: 5→0) | true; false; false; true; false; false |
| FG-018 | Reads | dense indices are the vertices | FG [1, 2, 0] / vertexIndexBound / vertexIndex(of: 2) / vertex(atIndex: 1) / source(ofEdgeAt: 1) / target(ofEdgeAt: 1) | 3; 2; 1; 1; 2 |
| FG-019 | Traps | successor(of:) a non-vertex | FG [1, 2, 0] / successor(of: 3) | **trap** (3 is not a vertex of the graph) |
| FG-020 | Traps | successor(of:) a negative vertex | FG [1, 2, 0] / successor(of: -1) | **trap** (-1 is not a vertex of the graph) |
| FG-021 | Steps | zero steps is the vertex itself | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / successor(of: 2, steps: 0) | 2 |
| FG-022 | Steps | steps inside the tail, onto the cycle, around it | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / successor(of: 2, steps: 1) / successor(of: 2, steps: 2) / successor(of: 2, steps: 3) / successor(of: 2, steps: 4) / successor(of: 2, steps: 5) / successor(of: 2, steps: 6) / successor(of: 2, steps: 7) | 1; 0; 3; 5; 6; 3; 5 |
| FG-023 | Steps | more steps than vertices (Brent, then a walk) | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / successor(of: 2, steps: 13) / successor(of: 11, steps: 1_000_000) / successor(of: 2, steps: Int.max) | 5; 9; 5 |
| FG-024 | Steps | a permutation, Int.max steps | FG [1, 2, 0, 4, 3, 5] / successor(of: 0, steps: Int.max) / successor(of: 3, steps: Int.max) / successor(of: 5, steps: Int.max) | 1; 4; 5 |
| FG-025 | Traps | negative steps | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / successor(of: 0, steps: -1) | **trap** (negative step count -1) |
| FG-026 | Decomposition | the featured graph: cycles by least vertex, each from its least vertex | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / cycles / cycles.count | [[3, 5, 6], [7], [9, 10]]; 3 |
| FG-027 | Decomposition | component(of:) is the index of the cycle reached | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / component(of:) for 0..<12 | [0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 2] |
| FG-028 | Decomposition | root(of:) is the first cyclic vertex reached | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / root(of:) for 0..<12 | [3, 3, 3, 3, 3, 5, 6, 7, 9, 9, 10, 9] |
| FG-029 | Decomposition | tailLength(of:), zero on a cycle | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / tailLength(of:) for 0..<12 | [1, 2, 3, 0, 1, 0, 0, 0, 1, 0, 0, 2] |
| FG-030 | Decomposition | cycleLength(of:) for tree vertices too | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / cycleLength(of:) for 0..<12 | [3, 3, 3, 3, 3, 3, 3, 1, 2, 2, 2, 2] |
| FG-031 | Decomposition | preimage rows ascending; in-degree | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / preimages(of: 3) / preimages(of: 2) / preimages(of: 7) / inDegree(of:) for 0..<12 | [0, 4, 6]; []; [7]; [1, 1, 0, 3, 0, 1, 1, 1, 1, 2, 1, 0] |
| FG-032 | Decomposition | successor(of:steps:) by level ancestor in a tree | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / successor(of: 2, steps: 0) / successor(of: 2, steps: 1) / successor(of: 2, steps: 2) / successor(of: 2, steps: 3) / successor(of: 11, steps: 1) | 2; 1; 0; 3; 8 |
| FG-033 | Decomposition | successor(of:steps:) around the cycle, any k | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / successor(of: 2, steps: 4) / successor(of: 2, steps: 1_000_000) / successor(of: 11, steps: Int.max) / successor(of: 7, steps: Int.max) | 5; 5; 10; 7 |
| FG-034 | Decomposition | level ancestor in a branching tree | FG [0, 0, 0, 1, 1, 2, 2, 3, 6] / successor(of: 7, steps: 2) / successor(of: 8, steps: 1) / successor(of: 8, steps: 2) / successor(of: 4, steps: 1) / tailLength(of:) for 0..<9 | 1; 6; 2; 1; [0, 1, 1, 2, 2, 2, 2, 3, 3] |
| FG-035 | Decomposition | empty graph | FG [] / cycles | [] |
| FG-036 | Decomposition | a permutation: its cycle decomposition, every tail zero | FG [1, 2, 0, 4, 3, 5] / cycles / tailLength(of:) for 0..<6 / inDegree(of:) for 0..<6 | [[0, 1, 2], [3, 4], [5]]; [0, 0, 0, 0, 0, 0]; [1, 1, 1, 1, 1, 1] |
| FG-037 | Decomposition | a constant map: one fixed point | FG [0, 0, 0, 0] / cycles / tailLength(of:) for 0..<4 | [[0]]; [0, 1, 1, 1] |
| FG-038 | Decomposition | the identity: n fixed points | FG [0, 1, 2] / cycles / component(of:) for 0..<3 | [[0], [1], [2]]; [0, 1, 2] |
| FG-039 | Decomposition | a path into a fixed point | FG [1, 2, 3, 4, 4] / cycles / tailLength(of:) for 0..<5 / root(of: 0) | [[4]]; [4, 3, 2, 1, 0]; 4 |
| FG-040 | Decomposition | a cycle is rotated to start at its least vertex | FG [2, 0, 1] / cycles | [[0, 2, 1]] |
| FG-041 | Decomposition | cycles ordered by least vertex, not by discovery | FG [3, 2, 1, 4, 3] / cycles / component(of:) for 0..<5 | [[1, 2], [3, 4]]; [1, 0, 0, 1, 1] |
| FG-042 | Decomposition | one long cycle | FG [1, 2, 3, 4, 5, 6, 7, 0] / cycles / successor(of: 5, steps: 11) | [[0, 1, 2, 3, 4, 5, 6, 7]]; 0 |
| FG-043 | Traps | decomposition query on a non-vertex | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / cycleDecomposition().tailLength(of: 12) | **trap** (12 is not a vertex of the graph) |
| FG-044 | Traps | decomposition: negative steps | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / cycleDecomposition().successor(of: 0, steps: -1) | **trap** (negative step count -1) |
| FG-045 | Generic | weaklyConnectedComponents() has the decomposition's components | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / weaklyConnectedComponents() as sets | [[0, 1, 2, 3, 4, 5, 6], [7], [8, 9, 10, 11]] |
| FG-046 | Generic | stronglyConnectedComponents(): the cycles, plus one singleton per tree vertex | FG [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8] / nontrivial or looped components | [[3, 5, 6], [7], [9, 10]] |
| FG-047 | Closures | a fixed point at the start | f = { $0 } / floydCycleDetection(from: 7, successor: f) / calls / brentCycleDetection(from: 7, successor: f) / calls | (tail 0, cycle 1, root 7); 4; (tail 0, cycle 1, root 7); 2 |
| FG-048 | Closures | start on a 5-cycle | f = { ($0 + 1) % 5 } / floydCycleDetection(from: 0, successor: f) / calls / brentCycleDetection(from: 0, successor: f) / calls | (tail 0, cycle 5, root 0); 20; (tail 0, cycle 5, root 0); 17 |
| FG-049 | Closures | a 2-cycle at the start | f = { 1 - $0 } / floydCycleDetection(from: 0, successor: f) / calls / brentCycleDetection(from: 0, successor: f) / calls | (tail 0, cycle 2, root 0); 8; (tail 0, cycle 2, root 0); 5 |
| FG-050 | Closures | one step into a fixed point | f = { _ in 0 } / floydCycleDetection(from: 5, successor: f) / calls / brentCycleDetection(from: 5, successor: f) / calls | (tail 1, cycle 1, root 0); 6; (tail 1, cycle 1, root 0); 5 |
| FG-051 | Closures | the featured graph from 2 (tail 3 into a 3-cycle) | f = { [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8][$0] } / floydCycleDetection(from: 2, successor: f) / calls / brentCycleDetection(from: 2, successor: f) / calls | (tail 3, cycle 3, root 3); 18; (tail 3, cycle 3, root 3); 15 |
| FG-052 | Closures | the featured graph from 11 | f = { [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8][$0] } / floydCycleDetection(from: 11, successor: f) / calls / brentCycleDetection(from: 11, successor: f) / calls | (tail 2, cycle 2, root 9); 12; (tail 2, cycle 2, root 9); 11 |
| FG-053 | Closures | Pollard's rho: x² + 1 mod 1 000 | f = { ($0 * $0 + 1) % 1_000 } / floydCycleDetection(from: 3, successor: f) / calls / brentCycleDetection(from: 3, successor: f) / calls | (tail 5, cycle 6, root 26); 34; (tail 5, cycle 6, root 26); 29 |
| FG-054 | Closures | Pollard's rho: x² + 1 mod 8 051 (= 83·97) | f = { ($0 * $0 + 1) % 8_051 } / floydCycleDetection(from: 2, successor: f) / calls / brentCycleDetection(from: 2, successor: f) / calls | (tail 4, cycle 15, root 7474); 68; (tail 4, cycle 15, root 7474); 53 |
| FG-055 | Closures | Collatz from 27: tail 109 into 4 → 2 → 1 | f = { $0 % 2 == 0 ? $0 / 2 : 3 * $0 + 1 } / floydCycleDetection(from: 27, successor: f) / calls / brentCycleDetection(from: 27, successor: f) / calls | (tail 109, cycle 3, root 4); 554; (tail 109, cycle 3, root 4); 351 |
| FG-056 | Closures | long tail, short cycle: 100 steps into a 1-cycle | f = { min($0 + 1, 100) } / floydCycleDetection(from: 0, successor: f) / calls / brentCycleDetection(from: 0, successor: f) / calls | (tail 100, cycle 1, root 100); 501; (tail 100, cycle 1, root 100); 329 |
| FG-057 | Closures | short tail, long cycle: 1 step into a 100-cycle | f = { $0 == 0 ? 1 : $0 % 100 + 1 } / floydCycleDetection(from: 0, successor: f) / calls / brentCycleDetection(from: 0, successor: f) / calls | (tail 1, cycle 100, root 1); 402; (tail 1, cycle 100, root 1); 329 |
| FG-058 | Closures | a cycle of length 2^k + 1 (Brent's power doubling boundary) | f = { ($0 + 1) % 17 } / floydCycleDetection(from: 0, successor: f) / calls / brentCycleDetection(from: 0, successor: f) / calls | (tail 0, cycle 17, root 0); 68; (tail 0, cycle 17, root 0); 65 |
| FG-059 | Closures | Equatable states that are not Int: Fibonacci pairs mod 10, Pisano period 60 | struct Pair: Equatable { var a, b: Int }; f = { Pair(a: $0.b, b: ($0.a + $0.b) % 10) } / floydCycleDetection(from: Pair(a: 0, b: 1), successor: f) / calls / brentCycleDetection(from: Pair(a: 0, b: 1), successor: f) / calls | (tail 0, cycle 60, root Pair(a: 0, b: 1)); 240; (tail 0, cycle 60, root Pair(a: 0, b: 1)); 183 |
| FG-060 | Conformances | Equatable compares successor arrays | FG [1, 0] == FG [1, 0] / FG [1, 0] == FG [0, 1] | true; false |
| FG-061 | Conformances | description | FG [1, 2, 0].description | FunctionalGraph([1, 2, 0]) |
| FG-062 | Conformances | Codable round trip as the successor array; decoding re-checks the range | encode FG [1, 2, 0] / decode [0, 3] | [1,2,0]; DecodingError.dataCorrupted |
