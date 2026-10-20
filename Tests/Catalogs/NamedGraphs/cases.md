# NamedGraphs: case catalog

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0
python3 Tests/Catalogs/NamedGraphs/ref.py`; `--write` regenerates this file, `--stress` adds the size
sweeps). Every non-trap row is checked against NetworkX 3.7 under the numbering of `api.md` (exact edge
set), against igraph 1.0 (exact where igraph numbers the same way, isomorphism for Petersen), and against
the family's count and degree laws.

Conventions:

* `U` rows use `UndirectedAdjacencyList<Int>`, `C` rows `CompressedSparseRow`; the Representations group
  repeats one family on the other conformers. Every factory gives the same vertices and edges on every
  conformer of the same kind.
* `E [u–v, …]` is `edges` in order: undirected edges are `UndirectedEdge(u, v)` with `u < v`, sorted
  lexicographically; directed edges `u→v` are in row-major order. The order is part of the contract
  (it is the insertion order on the adjacency lists, and CSR builds from it in one pass).
* `deg` is the degree of each vertex in order; `out` / `in` the out- and in-degrees.
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).

| ID | Group | Case | Call | Expected |
|---|---|---|---|---|
| NG-001 | Complete | K0 | `UndirectedAdjacencyList<Int>.complete(vertexCount: 0)` | n 0; m 0; deg []; E [] |
| NG-002 | Complete | K1 | `UndirectedAdjacencyList<Int>.complete(vertexCount: 1)` | n 1; m 0; deg [0]; E [] |
| NG-003 | Complete | K2 | `UndirectedAdjacencyList<Int>.complete(vertexCount: 2)` | n 2; m 1; deg [1, 1]; E [0–1] |
| NG-004 | Complete | K3 | `UndirectedAdjacencyList<Int>.complete(vertexCount: 3)` | n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2] |
| NG-005 | Complete | K5 | `UndirectedAdjacencyList<Int>.complete(vertexCount: 5)` | n 5; m 10; deg [4, 4, 4, 4, 4]; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–4, 2–3, 2–4, 3–4] |
| NG-006 | Complete | K0 directed: both arcs, row-major | `CompressedSparseRow.complete(vertexCount: 0)` | n 0; m 0; out []; in []; E [] |
| NG-007 | Complete | K1 directed: both arcs, row-major | `CompressedSparseRow.complete(vertexCount: 1)` | n 1; m 0; out [0]; in [0]; E [] |
| NG-008 | Complete | K3 directed: both arcs, row-major | `CompressedSparseRow.complete(vertexCount: 3)` | n 3; m 6; out [2, 2, 2]; in [2, 2, 2]; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1] |
| NG-009 | Complete | K60 counts only | `UndirectedAdjacencyList<Int>.complete(vertexCount: 60)` | n 60; m 1770; deg 59…59 |
| NG-010 | Complete | negative count | `UndirectedAdjacencyList<Int>.complete(vertexCount: -1)` | **trap**: vertexCount -1 is negative |
| NG-011 | Complete | n(n − 1) overflows Int | `CompressedSparseRow.complete(vertexCount: 1 << 32)` | **trap**: edge count overflows Int |
| NG-012 | CompleteBipartite | K0,0: left 0..<0, right 0..<0 | `UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 0, rightCount: 0)` | n 0; m 0; deg []; E [] |
| NG-013 | CompleteBipartite | K0,3: left 0..<0, right 0..<3 | `UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 0, rightCount: 3)` | n 3; m 0; deg [0, 0, 0]; E [] |
| NG-014 | CompleteBipartite | K1,1: left 0..<1, right 1..<2 | `UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 1, rightCount: 1)` | n 2; m 1; deg [1, 1]; E [0–1] |
| NG-015 | CompleteBipartite | K2,3: left 0..<2, right 2..<5 | `UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: 3)` | n 5; m 6; deg [3, 3, 2, 2, 2]; E [0–2, 0–3, 0–4, 1–2, 1–3, 1–4] |
| NG-016 | CompleteBipartite | K3,2: left 0..<3, right 3..<5 | `UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 3, rightCount: 2)` | n 5; m 6; deg [2, 2, 2, 3, 3]; E [0–3, 0–4, 1–3, 1–4, 2–3, 2–4] |
| NG-017 | CompleteBipartite | K2,3 directed: both arcs | `CompressedSparseRow.completeBipartite(leftCount: 2, rightCount: 3)` | n 5; m 12; out [3, 3, 2, 2, 2]; in [3, 3, 2, 2, 2]; E [0→2, 0→3, 0→4, 1→2, 1→3, 1→4, 2→0, 2→1, 3→0, 3→1, 4→0, 4→1] |
| NG-018 | CompleteBipartite | BipartiteGraph sides | `BipartiteGraph<Int>.completeBipartite(leftCount: 2, rightCount: 2)` | n 4; m 4; deg [2, 2, 2, 2]; E [0–2, 0–3, 1–2, 1–3]; left [0, 1]; right [2, 3] |
| NG-019 | CompleteBipartite | BipartiteGraph with an empty side | `BipartiteGraph<Int>.completeBipartite(leftCount: 0, rightCount: 2)` | n 2; m 0; deg [0, 0]; E []; left []; right [0, 1] |
| NG-020 | CompleteBipartite | negative side | `UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: -1)` | **trap**: rightCount -1 is negative |
| NG-021 | Path | P0 | `UndirectedAdjacencyList<Int>.path(vertexCount: 0)` | n 0; m 0; deg []; E [] |
| NG-022 | Path | P1 | `UndirectedAdjacencyList<Int>.path(vertexCount: 1)` | n 1; m 0; deg [0]; E [] |
| NG-023 | Path | P2 | `UndirectedAdjacencyList<Int>.path(vertexCount: 2)` | n 2; m 1; deg [1, 1]; E [0–1] |
| NG-024 | Path | P5 | `UndirectedAdjacencyList<Int>.path(vertexCount: 5)` | n 5; m 4; deg [1, 2, 2, 2, 1]; E [0–1, 1–2, 2–3, 3–4] |
| NG-025 | Path | P4 directed: i → i + 1 | `CompressedSparseRow.path(vertexCount: 4)` | n 4; m 3; out [1, 1, 1, 0]; in [0, 1, 1, 1]; E [0→1, 1→2, 2→3] |
| NG-026 | Path | Tree.path | `Tree<Int>.path(vertexCount: 4)` | n 4; m 3; deg [1, 2, 2, 1]; E [0–1, 1–2, 2–3] |
| NG-027 | Path | Tree.path(1) is one vertex | `Tree<Int>.path(vertexCount: 1)` | n 1; m 0; deg [0]; E [] |
| NG-028 | Path | Tree.path(0): a tree is never empty | `Tree<Int>.path(vertexCount: 0)` | **trap**: a Tree has at least one vertex |
| NG-029 | Path | negative count | `UndirectedAdjacencyList<Int>.path(vertexCount: -2)` | **trap**: vertexCount -2 is negative |
| NG-030 | Cycle | C3: closing edge stored as 0–2 | `UndirectedAdjacencyList<Int>.cycle(vertexCount: 3)` | n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2] |
| NG-031 | Cycle | C4: closing edge stored as 0–3 | `UndirectedAdjacencyList<Int>.cycle(vertexCount: 4)` | n 4; m 4; deg [2, 2, 2, 2]; E [0–1, 0–3, 1–2, 2–3] |
| NG-032 | Cycle | C6: closing edge stored as 0–5 | `UndirectedAdjacencyList<Int>.cycle(vertexCount: 6)` | n 6; m 6; deg [2, 2, 2, 2, 2, 2]; E [0–1, 0–5, 1–2, 2–3, 3–4, 4–5] |
| NG-033 | Cycle | C4 directed: i → i + 1 mod n, row-major | `CompressedSparseRow.cycle(vertexCount: 4)` | n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0] |
| NG-034 | Cycle | C0 is not a simple cycle | `UndirectedAdjacencyList<Int>.cycle(vertexCount: 0)` | **trap**: a cycle needs at least 3 vertices, not 0 |
| NG-035 | Cycle | C1 is not a simple cycle | `UndirectedAdjacencyList<Int>.cycle(vertexCount: 1)` | **trap**: a cycle needs at least 3 vertices, not 1 |
| NG-036 | Cycle | C2 is not a simple cycle | `UndirectedAdjacencyList<Int>.cycle(vertexCount: 2)` | **trap**: a cycle needs at least 3 vertices, not 2 |
| NG-037 | Cycle | C2 directed is trapped too (one rule for every type) | `CompressedSparseRow.cycle(vertexCount: 2)` | **trap**: a cycle needs at least 3 vertices, not 2 |
| NG-038 | Star | star of 1 vertices: hub 0 | `UndirectedAdjacencyList<Int>.star(vertexCount: 1)` | n 1; m 0; deg [0]; E [] |
| NG-039 | Star | star of 2 vertices: hub 0 | `UndirectedAdjacencyList<Int>.star(vertexCount: 2)` | n 2; m 1; deg [1, 1]; E [0–1] |
| NG-040 | Star | star of 5 vertices: hub 0 | `UndirectedAdjacencyList<Int>.star(vertexCount: 5)` | n 5; m 4; deg [4, 1, 1, 1, 1]; E [0–1, 0–2, 0–3, 0–4] |
| NG-041 | Star | directed: hub → leaf | `CompressedSparseRow.star(vertexCount: 4)` | n 4; m 3; out [3, 0, 0, 0]; in [0, 1, 1, 1]; E [0→1, 0→2, 0→3] |
| NG-042 | Star | Tree.star | `Tree<Int>.star(vertexCount: 4)` | n 4; m 3; deg [3, 1, 1, 1]; E [0–1, 0–2, 0–3] |
| NG-043 | Star | no hub | `UndirectedAdjacencyList<Int>.star(vertexCount: 0)` | **trap**: a star needs its hub: vertexCount 0 < 1 |
| NG-044 | Star | NetworkX's star_graph(4) has 5 vertices; ours counts vertices | `UndirectedAdjacencyList<Int>.star(vertexCount: 5)` | n 5; m 4; deg [4, 1, 1, 1, 1] |
| NG-045 | Wheel | W4: hub 0, rim 1..<4 | `UndirectedAdjacencyList<Int>.wheel(vertexCount: 4)` | n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3] |
| NG-046 | Wheel | W5: hub 0, rim 1..<5 | `UndirectedAdjacencyList<Int>.wheel(vertexCount: 5)` | n 5; m 8; deg [4, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–4, 2–3, 3–4] |
| NG-047 | Wheel | W7: hub 0, rim 1..<7 | `UndirectedAdjacencyList<Int>.wheel(vertexCount: 7)` | n 7; m 12; deg [6, 3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 1–6, 2–3, 3–4, 4–5, 5–6] |
| NG-048 | Wheel | W4 is K4 | `UndirectedAdjacencyList<Int>.wheel(vertexCount: 4) == UndirectedAdjacencyList<Int>.complete(vertexCount: 4)` | n 4; m 6; deg [3, 3, 3, 3]; equal true |
| NG-049 | Wheel | directed: hub → rim, rim cycle 1 → 2 → … → n − 1 → 1 | `CompressedSparseRow.wheel(vertexCount: 5)` | n 5; m 8; out [4, 1, 1, 1, 1]; in [0, 2, 2, 2, 2]; E [0→1, 0→2, 0→3, 0→4, 1→2, 2→3, 3→4, 4→1] |
| NG-050 | Wheel | W0: rim shorter than 3 | `UndirectedAdjacencyList<Int>.wheel(vertexCount: 0)` | **trap**: a wheel needs a hub and a rim of at least 3: vertexCount 0 < 4 |
| NG-051 | Wheel | W3: rim shorter than 3 | `UndirectedAdjacencyList<Int>.wheel(vertexCount: 3)` | **trap**: a wheel needs a hub and a rim of at least 3: vertexCount 3 < 4 |
| NG-052 | Grid | 3 | `UndirectedAdjacencyList<Int>.grid(dimensions: [3])` | n 3; m 2; deg [1, 2, 1]; E [0–1, 1–2] |
| NG-053 | Grid | 2×3 | `UndirectedAdjacencyList<Int>.grid(dimensions: [2, 3])` | n 6; m 7; deg [2, 3, 2, 2, 3, 2]; E [0–1, 0–3, 1–2, 1–4, 2–5, 3–4, 4–5] |
| NG-054 | Grid | 3×3 | `UndirectedAdjacencyList<Int>.grid(dimensions: [3, 3])` | n 9; m 12; deg [2, 3, 2, 3, 4, 3, 2, 3, 2]; E [0–1, 0–3, 1–2, 1–4, 2–5, 3–4, 3–6, 4–5, 4–7, 5–8, 6–7, 7–8] |
| NG-055 | Grid | 2×2×2 | `UndirectedAdjacencyList<Int>.grid(dimensions: [2, 2, 2])` | n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7] |
| NG-056 | Grid | 0×4 | `UndirectedAdjacencyList<Int>.grid(dimensions: [0, 4])` | n 0; m 0; deg []; E [] |
| NG-057 | Grid | 1×1 | `UndirectedAdjacencyList<Int>.grid(dimensions: [1, 1])` | n 1; m 0; deg [0]; E [] |
| NG-058 | Grid | 3 periodic | `UndirectedAdjacencyList<Int>.grid(dimensions: [3], periodic: true)` | n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2] |
| NG-059 | Grid | 3×4 periodic | `UndirectedAdjacencyList<Int>.grid(dimensions: [3, 4], periodic: true)` | n 12; m 24; deg [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]; E [0–1, 0–3, 0–4, 0–8, 1–2, 1–5, 1–9, 2–3, 2–6, 2–10, 3–7, 3–11, 4–5, 4–7, 4–8, 5–6, 5–9, 6–7, 6–10, 7–11, 8–9, 8–11, 9–10, 10–11] |
| NG-060 | Grid | 2×3 periodic | `UndirectedAdjacencyList<Int>.grid(dimensions: [2, 3], periodic: true)` | n 6; m 9; deg [3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–4, 2–5, 3–4, 3–5, 4–5] |
| NG-061 | Grid | 1×3 periodic | `UndirectedAdjacencyList<Int>.grid(dimensions: [1, 3], periodic: true)` | n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2] |
| NG-062 | Grid | 3×3×3 periodic | `UndirectedAdjacencyList<Int>.grid(dimensions: [3, 3, 3], periodic: true)` | n 27; m 81; deg 6…6 |
| NG-063 | Grid | 2×3 directed: both arcs | `CompressedSparseRow.grid(dimensions: [2, 3])` | n 6; m 14; out [2, 3, 2, 2, 3, 2]; in [2, 3, 2, 2, 3, 2]; E [0→1, 0→3, 1→0, 1→2, 1→4, 2→1, 2→5, 3→0, 3→4, 4→1, 4→3, 4→5, 5→2, 5→4] |
| NG-064 | Grid | 3×3 periodic directed | `CompressedSparseRow.grid(dimensions: [3, 3], periodic: true)` | n 9; m 36; out [4, 4, 4, 4, 4, 4, 4, 4, 4]; in [4, 4, 4, 4, 4, 4, 4, 4, 4] |
| NG-065 | Grid | 100×100 counts | `UndirectedAdjacencyList<Int>.grid(dimensions: [100, 100])` | n 10000; m 19800; deg 2…4 |
| NG-066 | Grid | no dimensions | `UndirectedAdjacencyList<Int>.grid(dimensions: [])` | **trap**: grid needs at least one dimension |
| NG-067 | Grid | negative dimension | `UndirectedAdjacencyList<Int>.grid(dimensions: [3, -1])` | **trap**: dimension -1 is negative |
| NG-068 | Grid | vertex count overflows Int | `UndirectedAdjacencyList<Int>.grid(dimensions: [1 << 32, 1 << 32])` | **trap**: vertex count overflows Int |
| NG-069 | Hypercube | Q0: u – u ^ (1 << k) | `UndirectedAdjacencyList<Int>.hypercube(dimension: 0)` | n 1; m 0; deg [0]; E [] |
| NG-070 | Hypercube | Q1: u – u ^ (1 << k) | `UndirectedAdjacencyList<Int>.hypercube(dimension: 1)` | n 2; m 1; deg [1, 1]; E [0–1] |
| NG-071 | Hypercube | Q2: u – u ^ (1 << k) | `UndirectedAdjacencyList<Int>.hypercube(dimension: 2)` | n 4; m 4; deg [2, 2, 2, 2]; E [0–1, 0–2, 1–3, 2–3] |
| NG-072 | Hypercube | Q3: u – u ^ (1 << k) | `UndirectedAdjacencyList<Int>.hypercube(dimension: 3)` | n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7] |
| NG-073 | Hypercube | Q2 directed: both arcs | `CompressedSparseRow.hypercube(dimension: 2)` | n 4; m 8; out [2, 2, 2, 2]; in [2, 2, 2, 2]; E [0→1, 0→2, 1→0, 1→3, 2→0, 2→3, 3→1, 3→2] |
| NG-074 | Hypercube | Q10 counts | `UndirectedAdjacencyList<Int>.hypercube(dimension: 10)` | n 1024; m 5120; deg 10…10 |
| NG-075 | Hypercube | negative dimension | `UndirectedAdjacencyList<Int>.hypercube(dimension: -1)` | **trap**: dimension -1 is negative |
| NG-076 | Hypercube | 2^63 vertices overflow Int | `UndirectedAdjacencyList<Int>.hypercube(dimension: 63)` | **trap**: 2^63 vertices overflow Int |
| NG-077 | Petersen | NetworkX's numbering: outer 0–4, spokes i–i+5, inner pentagram | `UndirectedAdjacencyList<Int>.petersen()` | n 10; m 15; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–4, 0–5, 1–2, 1–6, 2–3, 2–7, 3–4, 3–8, 4–9, 5–7, 5–8, 6–8, 6–9, 7–9] |
| NG-078 | Petersen | directed: both arcs | `CompressedSparseRow.petersen()` | n 10; m 30; out [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3, 3, 3, 3] |
| NG-079 | Empty | empty graph on 0 | `UndirectedAdjacencyList<Int>.empty(vertexCount: 0)` | n 0; m 0; deg []; E [] |
| NG-080 | Empty | empty graph on 1 | `UndirectedAdjacencyList<Int>.empty(vertexCount: 1)` | n 1; m 0; deg [0]; E [] |
| NG-081 | Empty | empty graph on 4 | `UndirectedAdjacencyList<Int>.empty(vertexCount: 4)` | n 4; m 0; deg [0, 0, 0, 0]; E [] |
| NG-082 | Empty | directed | `CompressedSparseRow.empty(vertexCount: 3)` | n 3; m 0; out [0, 0, 0]; in [0, 0, 0]; E [] |
| NG-083 | Empty | negative count | `UndirectedAdjacencyList<Int>.empty(vertexCount: -1)` | **trap**: vertexCount -1 is negative |
| NG-084 | Representations | AdjacencyList<Int>: same arcs, edges in row-major order | `AdjacencyList<Int>.cycle(vertexCount: 4)` | n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0] |
| NG-085 | Representations | AdjacencyMatrix: same arcs, edges in row-major order | `AdjacencyMatrix.cycle(vertexCount: 4)` | n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0] |
| NG-086 | Representations | StableDirectedGraph<Int>: same arcs, edges in row-major order | `StableDirectedGraph<Int>.cycle(vertexCount: 4)` | n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0] |
| NG-087 | Representations | DirectedPseudograph<Int>: same arcs, edges in row-major order | `DirectedPseudograph<Int>.cycle(vertexCount: 4)` | n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0] |
| NG-088 | Representations | DirectedMultigraph<Int>: same arcs, edges in row-major order | `DirectedMultigraph<Int>.cycle(vertexCount: 4)` | n 4; m 4; out [1, 1, 1, 1]; in [1, 1, 1, 1]; E [0→1, 1→2, 2→3, 3→0] |
| NG-089 | Representations | Pseudograph<Int>: same edges, sorted | `Pseudograph<Int>.wheel(vertexCount: 4)` | n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3] |
| NG-090 | Representations | Multigraph<Int>: same edges, sorted | `Multigraph<Int>.wheel(vertexCount: 4)` | n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3] |
| NG-091 | Ladder | L0 is the null graph | `UndirectedAdjacencyList<Int>.ladder(rungCount: 0)` | n 0; m 0; deg []; E [] |
| NG-092 | Ladder | L1 is K2 | `UndirectedAdjacencyList<Int>.ladder(rungCount: 1)` | n 2; m 1; deg [1, 1]; E [0–1] |
| NG-093 | Ladder | L4: rails 0..<4 and 4..<8, rungs i–i+4 | `UndirectedAdjacencyList<Int>.ladder(rungCount: 4)` | n 8; m 10; deg [2, 3, 3, 2, 2, 3, 3, 2]; E [0–1, 0–4, 1–2, 1–5, 2–3, 2–6, 3–7, 4–5, 5–6, 6–7] |
| NG-094 | Ladder | L3 directed: both arcs | `CompressedSparseRow.ladder(rungCount: 3)` | n 6; m 14; out [2, 3, 2, 2, 3, 2]; in [2, 3, 2, 2, 3, 2]; E [0→1, 0→3, 1→0, 1→2, 1→4, 2→1, 2→5, 3→0, 3→4, 4→1, 4→3, 4→5, 5→2, 5→4] |
| NG-095 | Ladder | negative count | `UndirectedAdjacencyList<Int>.ladder(rungCount: -1)` | **trap**: rungCount -1 is negative |
| NG-096 | CircularLadder | CL3: each rail closed by its first and last vertex | `UndirectedAdjacencyList<Int>.circularLadder(rungCount: 3)` | n 6; m 9; deg [3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–4, 2–5, 3–4, 3–5, 4–5] |
| NG-097 | CircularLadder | CL4: each rail closed by its first and last vertex | `UndirectedAdjacencyList<Int>.circularLadder(rungCount: 4)` | n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–3, 0–4, 1–2, 1–5, 2–3, 2–6, 3–7, 4–5, 4–7, 5–6, 6–7] |
| NG-098 | CircularLadder | CL3 directed: both arcs | `CompressedSparseRow.circularLadder(rungCount: 3)` | n 6; m 18; out [3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3]; E [0→1, 0→2, 0→3, 1→0, 1→2, 1→4, 2→0, 2→1, 2→5, 3→0, 3→4, 3→5, 4→1, 4→3, 4→5, 5→2, 5→3, 5→4] |
| NG-099 | CircularLadder | CL2: the rails are not cycles (NetworkX returns C4) | `UndirectedAdjacencyList<Int>.circularLadder(rungCount: 2)` | **trap**: a circular ladder needs at least 3 rungs, not 2 |
| NG-100 | Barbell | two K2 joined by a path of 0 | `UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 0)` | n 4; m 3; deg [1, 2, 2, 1]; E [0–1, 1–2, 2–3] |
| NG-101 | Barbell | two K3 joined by a path of 2 | `UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 2)` | n 8; m 9; deg [2, 2, 3, 2, 2, 3, 2, 2]; E [0–1, 0–2, 1–2, 2–3, 3–4, 4–5, 5–6, 5–7, 6–7] |
| NG-102 | Barbell | two K4 joined by a path of 0 | `UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 4, pathVertexCount: 0)` | n 8; m 13; deg [3, 3, 3, 4, 4, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 3–4, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7] |
| NG-103 | Barbell | directed: both arcs | `CompressedSparseRow.barbell(cliqueVertexCount: 3, pathVertexCount: 1)` | n 7; m 16; out [2, 2, 3, 2, 3, 2, 2]; in [2, 2, 3, 2, 3, 2, 2]; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1, 2→3, 3→2, 3→4, 4→3, 4→5, 4→6, 5→4, 5→6, 6→4, 6→5] |
| NG-104 | Barbell | clique of 1 | `UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 1, pathVertexCount: 2)` | **trap**: a barbell needs a clique of at least 2 vertices, not 1 |
| NG-105 | Barbell | negative path | `UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: -1)` | **trap**: pathVertexCount -1 is negative |
| NG-106 | Lollipop | K2 with a path of 0 at 1 | `UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 0)` | n 2; m 1; deg [1, 1]; E [0–1] |
| NG-107 | Lollipop | K3 with a path of 2 at 2 | `UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 2)` | n 5; m 5; deg [2, 2, 3, 2, 1]; E [0–1, 0–2, 1–2, 2–3, 3–4] |
| NG-108 | Lollipop | K4 with a path of 1 at 3 | `UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 4, pathVertexCount: 1)` | n 5; m 7; deg [3, 3, 3, 4, 1]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 3–4] |
| NG-109 | Lollipop | directed: both arcs | `CompressedSparseRow.lollipop(cliqueVertexCount: 3, pathVertexCount: 2)` | n 5; m 10; out [2, 2, 3, 2, 1]; in [2, 2, 3, 2, 1]; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1, 2→3, 3→2, 3→4, 4→3] |
| NG-110 | Lollipop | clique of 1 | `UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 1, pathVertexCount: 2)` | **trap**: a lollipop needs a clique of at least 2 vertices, not 1 |
| NG-111 | Lollipop | negative path | `UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: -1)` | **trap**: pathVertexCount -1 is negative |
| NG-112 | CompleteMultipartite | parts [] | `UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [])` | n 0; m 0; deg []; E [] |
| NG-113 | CompleteMultipartite | parts [2, 0, 1] | `UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [2, 0, 1])` | n 3; m 2; deg [1, 1, 2]; E [0–2, 1–2] |
| NG-114 | CompleteMultipartite | parts [1, 2, 3] | `UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1, 2, 3])` | n 6; m 11; deg [5, 4, 4, 3, 3, 3]; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5] |
| NG-115 | CompleteMultipartite | parts [1, 1, 1, 1] | `UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1, 1, 1, 1])` | n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3] |
| NG-116 | CompleteMultipartite | directed: both arcs | `CompressedSparseRow.completeMultipartite(partSizes: [1, 2, 3])` | n 6; m 22; out [5, 4, 4, 3, 3, 3]; in [5, 4, 4, 3, 3, 3]; E [0→1, 0→2, 0→3, 0→4, 0→5, 1→0, 1→3, 1→4, 1→5, 2→0, 2→3, 2→4, 2→5, 3→0, 3→1, 3→2, 4→0, 4→1, 4→2, 5→0, 5→1, 5→2] |
| NG-117 | CompleteMultipartite | negative part size | `UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [2, -1])` | **trap**: part size -1 is negative |
| NG-118 | CompleteMultipartite | edge count overflows Int | `UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1 << 32, 1 << 32])` | **trap**: edge count overflows Int |
| NG-119 | Turan | T(5, 2): parts [2, 3], smaller first | `UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 2)` | n 5; m 6; deg [3, 3, 2, 2, 2]; E [0–2, 0–3, 0–4, 1–2, 1–3, 1–4] |
| NG-120 | Turan | T(7, 3): parts [2, 2, 3] | `UndirectedAdjacencyList<Int>.turan(vertexCount: 7, partCount: 3)` | n 7; m 16; deg [5, 5, 5, 5, 4, 4, 4]; E [0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 1–3, 1–4, 1–5, 1–6, 2–4, 2–5, 2–6, 3–4, 3–5, 3–6] |
| NG-121 | Turan | T(4, 4) is K4 | `UndirectedAdjacencyList<Int>.turan(vertexCount: 4, partCount: 4)` | n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3] |
| NG-122 | Turan | T(4, 1): one part, no edges | `UndirectedAdjacencyList<Int>.turan(vertexCount: 4, partCount: 1)` | n 4; m 0; deg [0, 0, 0, 0]; E [] |
| NG-123 | Turan | directed: both arcs | `CompressedSparseRow.turan(vertexCount: 5, partCount: 2)` | n 5; m 12; out [3, 3, 2, 2, 2]; in [3, 3, 2, 2, 2]; E [0→2, 0→3, 0→4, 1→2, 1→3, 1→4, 2→0, 2→1, 3→0, 3→1, 4→0, 4→1] |
| NG-124 | Turan | no parts | `UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 0)` | **trap**: a Turán graph needs 1 ≤ partCount ≤ vertexCount, not 0 and 5 |
| NG-125 | Turan | more parts than vertices | `UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 6)` | **trap**: a Turán graph needs 1 ≤ partCount ≤ vertexCount, not 6 and 5 |
| NG-126 | BalancedTree | r = 2, h = 2: children of p are 2p + 1, 2p + 2 | `UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 2)` | n 7; m 6; deg [2, 3, 3, 1, 1, 1, 1]; E [0–1, 0–2, 1–3, 1–4, 2–5, 2–6] |
| NG-127 | BalancedTree | r = 3, h = 2 | `UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 3, height: 2)` | n 13; m 12; deg [3, 4, 4, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1]; E [0–1, 0–2, 0–3, 1–4, 1–5, 1–6, 2–7, 2–8, 2–9, 3–10, 3–11, 3–12] |
| NG-128 | BalancedTree | r = 1, h = 3 is the path P4 | `UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 1, height: 3)` | n 4; m 3; deg [1, 2, 2, 1]; E [0–1, 1–2, 2–3] |
| NG-129 | BalancedTree | r = 0, h = 3 is the root alone | `UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 0, height: 3)` | n 1; m 0; deg [0]; E [] |
| NG-130 | BalancedTree | r = 2, h = 0 is the root alone | `UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 0)` | n 1; m 0; deg [0]; E [] |
| NG-131 | BalancedTree | directed: parent → child | `CompressedSparseRow.balancedTree(branchingFactor: 2, height: 2)` | n 7; m 6; out [2, 2, 2, 0, 0, 0, 0]; in [0, 1, 1, 1, 1, 1, 1]; E [0→1, 0→2, 1→3, 1→4, 2→5, 2→6] |
| NG-132 | BalancedTree | Tree.balancedTree | `Tree<Int>.balancedTree(branchingFactor: 2, height: 3)` | n 15; m 14; deg [2, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1]; E [0–1, 0–2, 1–3, 1–4, 2–5, 2–6, 3–7, 3–8, 4–9, 4–10, 5–11, 5–12, 6–13, 6–14] |
| NG-133 | BalancedTree | negative height | `UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: -1)` | **trap**: height -1 is negative |
| NG-134 | BalancedTree | negative branching factor | `UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: -1, height: 2)` | **trap**: branchingFactor -1 is negative |
| NG-135 | BalancedTree | vertex count overflows Int | `UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 63)` | **trap**: vertex count overflows Int |
| NG-136 | Circulant | C6(1, 2) | `UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 2])` | n 6; m 12; deg [4, 4, 4, 4, 4, 4]; E [0–1, 0–2, 0–4, 0–5, 1–2, 1–3, 1–5, 2–3, 2–4, 3–4, 3–5, 4–5] |
| NG-137 | Circulant | C5(1) is C5 | `UndirectedAdjacencyList<Int>.circulant(vertexCount: 5, offsets: [1])` | n 5; m 5; deg [2, 2, 2, 2, 2]; E [0–1, 0–4, 1–2, 2–3, 3–4] |
| NG-138 | Circulant | C8(1, 4): offset n/2 gives each edge once | `UndirectedAdjacencyList<Int>.circulant(vertexCount: 8, offsets: [1, 4])` | n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–4, 0–7, 1–2, 1–5, 2–3, 2–6, 3–4, 3–7, 4–5, 5–6, 6–7] |
| NG-139 | Circulant | C6(2, -2, 4): 2, −2 and 4 are one offset | `UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [2, -2, 4])` | n 6; m 6; deg [2, 2, 2, 2, 2, 2]; E [0–2, 0–4, 1–3, 1–5, 2–4, 3–5] |
| NG-140 | Circulant | C2(1) is K2 | `UndirectedAdjacencyList<Int>.circulant(vertexCount: 2, offsets: [1])` | n 2; m 1; deg [1, 1]; E [0–1] |
| NG-141 | Circulant | C1() is K1 | `UndirectedAdjacencyList<Int>.circulant(vertexCount: 1, offsets: [])` | n 1; m 0; deg [0]; E [] |
| NG-142 | Circulant | directed: both arcs | `CompressedSparseRow.circulant(vertexCount: 6, offsets: [1, 2])` | n 6; m 24; out [4, 4, 4, 4, 4, 4]; in [4, 4, 4, 4, 4, 4]; E [0→1, 0→2, 0→4, 0→5, 1→0, 1→2, 1→3, 1→5, 2→0, 2→1, 2→3, 2→4, 3→1, 3→2, 3→4, 3→5, 4→0, 4→2, 4→3, 4→5, 5→0, 5→1, 5→3, 5→4] |
| NG-143 | Circulant | an offset that is a multiple of n is a self-loop | `UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 6])` | **trap**: offset 6 is a multiple of vertexCount 6: a self-loop |
| NG-144 | Circulant | no vertices | `UndirectedAdjacencyList<Int>.circulant(vertexCount: 0, offsets: [])` | **trap**: a circulant graph needs at least 1 vertex, not 0 |
| NG-145 | GeneralizedPetersen | GP(5, 2) is the Petersen graph | `UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 2)` | n 10; m 15; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–4, 0–5, 1–2, 1–6, 2–3, 2–7, 3–4, 3–8, 4–9, 5–7, 5–8, 6–8, 6–9, 7–9] |
| NG-146 | GeneralizedPetersen | GP(4, 1) is the cube | `UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 4, step: 1)` | n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–3, 0–4, 1–2, 1–5, 2–3, 2–6, 3–7, 4–5, 4–7, 5–6, 6–7] |
| NG-147 | GeneralizedPetersen | GP(7, 2) | `UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 7, step: 2)` | n 14; m 21; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–6, 0–7, 1–2, 1–8, 2–3, 2–9, 3–4, 3–10, 4–5, 4–11, 5–6, 5–12, 6–13, 7–9, 7–12, 8–10, 8–13, 9–11, 10–12, 11–13] |
| NG-148 | GeneralizedPetersen | GP(3, 1) is the prism | `UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 3, step: 1)` | n 6; m 9; deg [3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–4, 2–5, 3–4, 3–5, 4–5] |
| NG-149 | GeneralizedPetersen | directed: both arcs | `CompressedSparseRow.generalizedPetersen(outerCycleLength: 5, step: 2)` | n 10; m 30; out [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0→1, 0→4, 0→5, 1→0, 1→2, 1→6, 2→1, 2→3, 2→7, 3→2, 3→4, 3→8, 4→0, 4→3, 4→9, 5→0, 5→7, 5→8, 6→1, 6→8, 6→9, 7→2, 7→5, 7→9, 8→3, 8→5, 8→6, 9→4, 9→6, 9→7] |
| NG-150 | GeneralizedPetersen | step 0 | `UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 0)` | **trap**: step 0 is not in 1 ..< 5/2 |
| NG-151 | GeneralizedPetersen | step n/2 repeats the inner edges | `UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 6, step: 3)` | **trap**: step 3 is not in 1 ..< 6/2 |
| NG-152 | GeneralizedPetersen | outer cycle of 2 | `UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 2, step: 1)` | **trap**: a generalized Petersen graph needs an outer cycle of at least 3, not 2 |
| NG-153 | Kneser | KG(5, 2): the Petersen graph, subsets in lexicographic order | `UndirectedAdjacencyList<Int>.kneser(setSize: 5, subsetSize: 2)` | n 10; m 15; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–7, 0–8, 0–9, 1–5, 1–6, 1–9, 2–4, 2–6, 2–8, 3–4, 3–5, 3–7, 4–9, 5–8, 6–7] |
| NG-154 | Kneser | KG(4, 1) is K4 | `UndirectedAdjacencyList<Int>.kneser(setSize: 4, subsetSize: 1)` | n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3] |
| NG-155 | Kneser | KG(5, 3): n < 2k, no edges | `UndirectedAdjacencyList<Int>.kneser(setSize: 5, subsetSize: 3)` | n 10; m 0; deg [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; E [] |
| NG-156 | Kneser | KG(6, 2) | `UndirectedAdjacencyList<Int>.kneser(setSize: 6, subsetSize: 2)` | n 15; m 45; deg [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]; E [0–9, 0–10, 0–11, 0–12, 0–13, 0–14, 1–6, 1–7, 1–8, 1–12, 1–13, 1–14, 2–5, 2–7, 2–8, 2–10, 2–11, 2–14, 3–5, 3–6, 3–8, 3–9, 3–11, 3–13, 4–5, 4–6, 4–7, 4–9, 4–10, 4–12, 5–12, 5–13, 5–14, 6–10, 6–11, 6–14, 7–9, 7–11, 7–13, 8–9, 8–10, 8–12, 9–14, 10–13, 11–12] |
| NG-157 | Kneser | KG(1, 1): one vertex | `UndirectedAdjacencyList<Int>.kneser(setSize: 1, subsetSize: 1)` | n 1; m 0; deg [0]; E [] |
| NG-158 | Kneser | directed: both arcs | `CompressedSparseRow.kneser(setSize: 5, subsetSize: 2)` | n 10; m 30; out [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0→7, 0→8, 0→9, 1→5, 1→6, 1→9, 2→4, 2→6, 2→8, 3→4, 3→5, 3→7, 4→2, 4→3, 4→9, 5→1, 5→3, 5→8, 6→1, 6→2, 6→7, 7→0, 7→3, 7→6, 8→0, 8→2, 8→5, 9→0, 9→1, 9→4] |
| NG-159 | Kneser | subsets of 0 | `UndirectedAdjacencyList<Int>.kneser(setSize: 4, subsetSize: 0)` | **trap**: subsetSize 0 is not in 1...4 |
| NG-160 | Kneser | subsets larger than the set | `UndirectedAdjacencyList<Int>.kneser(setSize: 3, subsetSize: 4)` | **trap**: subsetSize 4 is not in 1...3 |
| NG-161 | Windmill | Wd(3, 2): the friendship graph F2 (butterfly) | `UndirectedAdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3)` | n 5; m 6; deg [4, 2, 2, 2, 2]; E [0–1, 0–2, 0–3, 0–4, 1–2, 3–4] |
| NG-162 | Windmill | Wd(3, 3): F3 | `UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 3)` | n 7; m 9; deg [6, 2, 2, 2, 2, 2, 2]; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 3–4, 5–6] |
| NG-163 | Windmill | Wd(2, 3) is a star | `UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2)` | n 4; m 3; deg [3, 1, 1, 1]; E [0–1, 0–2, 0–3] |
| NG-164 | Windmill | Wd(4, 2) | `UndirectedAdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 4)` | n 7; m 12; deg [6, 3, 3, 3, 3, 3, 3]; E [0–1, 0–2, 0–3, 0–4, 0–5, 0–6, 1–2, 1–3, 2–3, 4–5, 4–6, 5–6] |
| NG-165 | Windmill | directed: both arcs | `CompressedSparseRow.windmill(cliqueCount: 2, cliqueVertexCount: 3)` | n 5; m 12; out [4, 2, 2, 2, 2]; in [4, 2, 2, 2, 2]; E [0→1, 0→2, 0→3, 0→4, 1→0, 1→2, 2→0, 2→1, 3→0, 3→4, 4→0, 4→3] |
| NG-166 | Windmill | one clique | `UndirectedAdjacencyList<Int>.windmill(cliqueCount: 1, cliqueVertexCount: 3)` | **trap**: a windmill needs at least 2 cliques, not 1 |
| NG-167 | Windmill | cliques of 1 | `UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 1)` | **trap**: a windmill's cliques need at least 2 vertices, not 1 |
| NG-168 | BinomialTree | B0: parent of v is v & (v − 1) | `UndirectedAdjacencyList<Int>.binomialTree(order: 0)` | n 1; m 0; deg [0]; E [] |
| NG-169 | BinomialTree | B1: parent of v is v & (v − 1) | `UndirectedAdjacencyList<Int>.binomialTree(order: 1)` | n 2; m 1; deg [1, 1]; E [0–1] |
| NG-170 | BinomialTree | B2: parent of v is v & (v − 1) | `UndirectedAdjacencyList<Int>.binomialTree(order: 2)` | n 4; m 3; deg [2, 1, 2, 1]; E [0–1, 0–2, 2–3] |
| NG-171 | BinomialTree | B3: parent of v is v & (v − 1) | `UndirectedAdjacencyList<Int>.binomialTree(order: 3)` | n 8; m 7; deg [3, 1, 2, 1, 3, 1, 2, 1]; E [0–1, 0–2, 0–4, 2–3, 4–5, 4–6, 6–7] |
| NG-172 | BinomialTree | directed: parent → child | `CompressedSparseRow.binomialTree(order: 3)` | n 8; m 7; out [3, 0, 1, 0, 2, 0, 1, 0]; in [0, 1, 1, 1, 1, 1, 1, 1]; E [0→1, 0→2, 0→4, 2→3, 4→5, 4→6, 6→7] |
| NG-173 | BinomialTree | Tree.binomialTree | `Tree<Int>.binomialTree(order: 3)` | n 8; m 7; deg [3, 1, 2, 1, 3, 1, 2, 1]; E [0–1, 0–2, 0–4, 2–3, 4–5, 4–6, 6–7] |
| NG-174 | BinomialTree | negative order | `UndirectedAdjacencyList<Int>.binomialTree(order: -1)` | **trap**: order -1 is negative |
| NG-175 | BinomialTree | 2^63 vertices overflow Int | `UndirectedAdjacencyList<Int>.binomialTree(order: 63)` | **trap**: 2^63 vertices overflow Int |
| NG-176 | FullRaryTree | r = 2, n = 0 is the null graph | `UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0)` | n 0; m 0; deg []; E [] |
| NG-177 | FullRaryTree | r = 2, n = 1 is one vertex | `UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1)` | n 1; m 0; deg [0]; E [] |
| NG-178 | FullRaryTree | r = 2, n = 6: the last level partly filled | `UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 6)` | n 6; m 5; deg [2, 3, 2, 1, 1, 1]; E [0–1, 0–2, 1–3, 1–4, 2–5] |
| NG-179 | FullRaryTree | r = 3, n = 10 | `UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 10)` | n 10; m 9; deg [3, 4, 4, 1, 1, 1, 1, 1, 1, 1]; E [0–1, 0–2, 0–3, 1–4, 1–5, 1–6, 2–7, 2–8, 2–9] |
| NG-180 | FullRaryTree | r = 1, n = 4 is the path P4 | `UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 4)` | n 4; m 3; deg [1, 2, 2, 1]; E [0–1, 1–2, 2–3] |
| NG-181 | FullRaryTree | directed: parent → child | `CompressedSparseRow.fullRaryTree(branchingFactor: 2, vertexCount: 6)` | n 6; m 5; out [2, 2, 1, 0, 0, 0]; in [0, 1, 1, 1, 1, 1]; E [0→1, 0→2, 1→3, 1→4, 2→5] |
| NG-182 | FullRaryTree | Tree.fullRaryTree | `Tree<Int>.fullRaryTree(branchingFactor: 3, vertexCount: 7)` | n 7; m 6; deg [3, 4, 1, 1, 1, 1, 1]; E [0–1, 0–2, 0–3, 1–4, 1–5, 1–6] |
| NG-183 | FullRaryTree | branching factor 0 | `UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3)` | **trap**: branchingFactor 0 < 1 |
| NG-184 | FullRaryTree | negative count | `UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1)` | **trap**: vertexCount -1 is negative |
| NG-185 | FullRaryTree | Tree.fullRaryTree(0): a tree is never empty | `Tree<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0)` | **trap**: a Tree has at least one vertex |
| NG-186 | DeBruijn | B(2, 3): loops at 000 and 111 | `AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 3)` | n 8; m 16; out [2, 2, 2, 2, 2, 2, 2, 2]; in [2, 2, 2, 2, 2, 2, 2, 2]; E [0→0, 0→1, 1→2, 1→3, 2→4, 2→5, 3→6, 3→7, 4→0, 4→1, 5→2, 5→3, 6→4, 6→5, 7→6, 7→7] |
| NG-187 | DeBruijn | B(3, 1): every arc, loops included | `AdjacencyList<Int>.deBruijn(alphabetSize: 3, wordLength: 1)` | n 3; m 9; out [3, 3, 3]; in [3, 3, 3]; E [0→0, 0→1, 0→2, 1→0, 1→1, 1→2, 2→0, 2→1, 2→2] |
| NG-188 | DeBruijn | B(1, 2): one word, one loop | `AdjacencyList<Int>.deBruijn(alphabetSize: 1, wordLength: 2)` | n 1; m 1; out [1]; in [1]; E [0→0] |
| NG-189 | DeBruijn | B(2, 1) | `AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 1)` | n 2; m 4; out [2, 2]; in [2, 2]; E [0→0, 0→1, 1→0, 1→1] |
| NG-190 | DeBruijn | DirectedPseudograph: the same arcs | `DirectedPseudograph<Int>.deBruijn(alphabetSize: 2, wordLength: 2)` | n 4; m 8; out [2, 2, 2, 2]; in [2, 2, 2, 2]; E [0→0, 0→1, 1→2, 1→3, 2→0, 2→1, 3→2, 3→3] |
| NG-191 | DeBruijn | empty alphabet | `AdjacencyList<Int>.deBruijn(alphabetSize: 0, wordLength: 2)` | **trap**: alphabetSize 0 < 1 |
| NG-192 | DeBruijn | empty words | `AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 0)` | **trap**: wordLength 0 < 1 |
| NG-193 | Kautz | words of 3 over 2 letters: 010 and 101 | `CompressedSparseRow.kautz(alphabetSize: 2, wordLength: 3)` | n 2; m 2; out [1, 1]; in [1, 1]; E [0→1, 1→0] |
| NG-194 | Kautz | words of 2 over 3 letters | `CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 2)` | n 6; m 12; out [2, 2, 2, 2, 2, 2]; in [2, 2, 2, 2, 2, 2]; E [0→2, 0→3, 1→4, 1→5, 2→0, 2→1, 3→4, 3→5, 4→0, 4→1, 5→2, 5→3] |
| NG-195 | Kautz | words of 1 over 3 letters is the complete digraph on 3 | `CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 1)` | n 3; m 6; out [2, 2, 2]; in [2, 2, 2]; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1] |
| NG-196 | Kautz | words of 2 over 4 letters | `CompressedSparseRow.kautz(alphabetSize: 4, wordLength: 2)` | n 12; m 36; out [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0→3, 0→4, 0→5, 1→6, 1→7, 1→8, 2→9, 2→10, 2→11, 3→0, 3→1, 3→2, 4→6, 4→7, 4→8, 5→9, 5→10, 5→11, 6→0, 6→1, 6→2, 7→3, 7→4, 7→5, 8→9, 8→10, 8→11, 9→0, 9→1, 9→2, 10→3, 10→4, 10→5, 11→6, 11→7, 11→8] |
| NG-197 | Kautz | one letter | `CompressedSparseRow.kautz(alphabetSize: 1, wordLength: 2)` | **trap**: alphabetSize 1 < 2 |
| NG-198 | Kautz | empty words | `CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 0)` | **trap**: wordLength 0 < 1 |
| NG-199 | TriangularLattice | 1 × 1 triangles: one triangle | `UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 1, columnCount: 1)` | n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2] |
| NG-200 | TriangularLattice | 1 × 2 triangles: a rhombus | `UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 1, columnCount: 2)` | n 4; m 5; deg [2, 3, 3, 2]; E [0–1, 0–2, 1–2, 1–3, 2–3] |
| NG-201 | TriangularLattice | 2 × 3 triangles: odd n, odd rows one shorter | `UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: 3)` | n 8; m 13; deg [2, 4, 2, 5, 5, 2, 4, 2]; E [0–1, 0–3, 1–2, 1–3, 1–4, 2–4, 3–4, 3–5, 3–6, 4–6, 4–7, 5–6, 6–7] |
| NG-202 | TriangularLattice | 2 × 4 triangles | `UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 2, columnCount: 4)` | n 9; m 16; deg [2, 4, 3, 5, 6, 3, 2, 4, 3]; E [0–1, 0–3, 1–2, 1–3, 1–4, 2–4, 2–5, 3–4, 3–6, 3–7, 4–5, 4–7, 4–8, 5–8, 6–7, 7–8] |
| NG-203 | TriangularLattice | 3 × 2 triangles | `UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 3, columnCount: 2)` | n 8; m 13; deg [2, 3, 5, 3, 3, 5, 3, 2]; E [0–1, 0–2, 1–2, 1–3, 2–3, 2–4, 2–5, 3–5, 4–5, 4–6, 5–6, 5–7, 6–7] |
| NG-204 | TriangularLattice | 0 × 3 triangles: no rows, the null graph | `UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 0, columnCount: 3)` | n 0; m 0; deg []; E [] |
| NG-205 | TriangularLattice | directed: both arcs | `CompressedSparseRow.triangularLattice(rowCount: 2, columnCount: 2)` | n 6; m 18; out [2, 3, 5, 3, 2, 3]; in [2, 3, 5, 3, 2, 3]; E [0→1, 0→2, 1→0, 1→2, 1→3, 2→0, 2→1, 2→3, 2→4, 2→5, 3→1, 3→2, 3→5, 4→2, 4→5, 5→2, 5→3, 5→4] |
| NG-206 | TriangularLattice | negative rows | `UndirectedAdjacencyList<Int>.triangularLattice(rowCount: -1, columnCount: 2)` | **trap**: rowCount -1 is negative |
| NG-207 | HexagonalLattice | 1 × 1 hexagons is C6 | `UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 1)` | n 6; m 6; deg [2, 2, 2, 2, 2, 2]; E [0–1, 0–3, 1–2, 2–5, 3–4, 4–5] |
| NG-208 | HexagonalLattice | 1 × 2 hexagons | `UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 2)` | n 10; m 11; deg [2, 2, 2, 2, 3, 3, 2, 2, 2, 2]; E [0–1, 0–3, 1–2, 2–5, 3–4, 4–5, 4–7, 5–6, 6–9, 7–8, 8–9] |
| NG-209 | HexagonalLattice | 2 × 1 hexagons | `UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 2, columnCount: 1)` | n 10; m 11; deg [2, 2, 3, 2, 2, 2, 2, 3, 2, 2]; E [0–1, 0–5, 1–2, 2–3, 2–7, 3–4, 4–9, 5–6, 6–7, 7–8, 8–9] |
| NG-210 | HexagonalLattice | 2 × 2 hexagons | `UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 2, columnCount: 2)` | n 16; m 19; deg [2, 2, 3, 2, 2, 2, 3, 3, 3, 3, 2, 2, 2, 3, 2, 2]; E [0–1, 0–5, 1–2, 2–3, 2–7, 3–4, 4–9, 5–6, 6–7, 6–11, 7–8, 8–9, 8–13, 9–10, 10–15, 11–12, 12–13, 13–14, 14–15] |
| NG-211 | HexagonalLattice | 1 × 3 hexagons: odd n drops the top of the last column | `UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 3)` | n 14; m 16; deg [2, 2, 2, 2, 3, 3, 2, 2, 3, 3, 2, 2, 2, 2]; E [0–1, 0–3, 1–2, 2–5, 3–4, 4–5, 4–8, 5–6, 6–10, 7–8, 7–11, 8–9, 9–10, 9–13, 11–12, 12–13] |
| NG-212 | HexagonalLattice | 3 × 0 hexagons: no columns, the null graph | `UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 3, columnCount: 0)` | n 0; m 0; deg []; E [] |
| NG-213 | HexagonalLattice | directed: both arcs | `CompressedSparseRow.hexagonalLattice(rowCount: 1, columnCount: 2)` | n 10; m 22; out [2, 2, 2, 2, 3, 3, 2, 2, 2, 2]; in [2, 2, 2, 2, 3, 3, 2, 2, 2, 2]; E [0→1, 0→3, 1→0, 1→2, 2→1, 2→5, 3→0, 3→4, 4→3, 4→5, 4→7, 5→2, 5→4, 5→6, 6→5, 6→9, 7→4, 7→8, 8→7, 8→9, 9→6, 9→8] |
| NG-214 | HexagonalLattice | negative columns | `UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: -1)` | **trap**: columnCount -1 is negative |
| NG-215 | LCF | [3, -3]^3 on 6: K3,3 | `UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3)` | n 6; m 9; deg [3, 3, 3, 3, 3, 3]; E [0–1, 0–3, 0–5, 1–2, 1–4, 2–3, 2–5, 3–4, 4–5] |
| NG-216 | LCF | [4]^8 on 8: the Wagner graph, chords repeated from both ends | `UndirectedAdjacencyList<Int>.lcf(vertexCount: 8, shifts: [4], repeatCount: 8)` | n 8; m 12; deg [3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–4, 0–7, 1–2, 1–5, 2–3, 2–6, 3–4, 3–7, 4–5, 5–6, 6–7] |
| NG-217 | LCF | [2]^4 on 4: K4 | `UndirectedAdjacencyList<Int>.lcf(vertexCount: 4, shifts: [2], repeatCount: 4)` | n 4; m 6; deg [3, 3, 3, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3] |
| NG-218 | LCF | []^0 on 5: no chords, C5 | `UndirectedAdjacencyList<Int>.lcf(vertexCount: 5, shifts: [], repeatCount: 0)` | n 5; m 5; deg [2, 2, 2, 2, 2]; E [0–1, 0–4, 1–2, 2–3, 3–4] |
| NG-219 | LCF | [2]^1 on 6: one chord | `UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [2], repeatCount: 1)` | n 6; m 7; deg [3, 2, 3, 2, 2, 2]; E [0–1, 0–2, 0–5, 1–2, 2–3, 3–4, 4–5] |
| NG-220 | LCF | directed: both arcs | `CompressedSparseRow.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3)` | n 6; m 18; out [3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3]; E [0→1, 0→3, 0→5, 1→0, 1→2, 1→4, 2→1, 2→3, 2→5, 3→0, 3→2, 3→4, 4→1, 4→3, 4→5, 5→0, 5→2, 5→4] |
| NG-221 | LCF | a cycle of 2 | `UndirectedAdjacencyList<Int>.lcf(vertexCount: 2, shifts: [1], repeatCount: 1)` | **trap**: an LCF graph needs a cycle of at least 3 vertices, not 2 |
| NG-222 | LCF | a shift that is a multiple of n is a self-loop | `UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, 6], repeatCount: 3)` | **trap**: shift 6 is a multiple of vertexCount 6: a self-loop |
| NG-223 | LCF | negative repeat count | `UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: -1)` | **trap**: repeatCount -1 is negative |
| NG-224 | NamedLCF | heawood: [5, -5]^7 on 14 | `UndirectedAdjacencyList<Int>.heawood()` | n 14; m 21; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–5, 0–13, 1–2, 1–10, 2–3, 2–7, 3–4, 3–12, 4–5, 4–9, 5–6, 6–7, 6–11, 7–8, 8–9, 8–13, 9–10, 10–11, 11–12, 12–13] |
| NG-225 | NamedLCF | moebiusKantor: [5, -5]^8 on 16 | `UndirectedAdjacencyList<Int>.moebiusKantor()` | n 16; m 24; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–5, 0–15, 1–2, 1–12, 2–3, 2–7, 3–4, 3–14, 4–5, 4–9, 5–6, 6–7, 6–11, 7–8, 8–9, 8–13, 9–10, 10–11, 10–15, 11–12, 12–13, 13–14, 14–15] |
| NG-226 | NamedLCF | pappus: [5, 7, -7, 7, -7, -5]^3 on 18 | `UndirectedAdjacencyList<Int>.pappus()` | n 18; m 27; deg 3…3; E [0–1, 0–5, 0–17, 1–2, 1–8, 2–3, 2–13, 3–4, 3–10, 4–5, 4–15, 5–6, 6–7, 6–11, 7–8, 7–14, 8–9, 9–10, 9–16, 10–11, 11–12, 12–13, 12–17, 13–14, 14–15, 15–16, 16–17] |
| NG-227 | NamedLCF | desargues: [5, -5, 9, -9]^5 on 20 | `UndirectedAdjacencyList<Int>.desargues()` | n 20; m 30; deg 3…3; E [0–1, 0–5, 0–19, 1–2, 1–16, 2–3, 2–11, 3–4, 3–14, 4–5, 4–9, 5–6, 6–7, 6–15, 7–8, 7–18, 8–9, 8–13, 9–10, 10–11, 10–19, 11–12, 12–13, 12–17, 13–14, 14–15, 15–16, 16–17, 17–18, 18–19] |
| NG-228 | NamedLCF | dodecahedral: [10, 7, 4, -4, -7, 10, -4, 7, -7, 4]^2 on 20 | `UndirectedAdjacencyList<Int>.dodecahedral()` | n 20; m 30; deg 3…3; E [0–1, 0–10, 0–19, 1–2, 1–8, 2–3, 2–6, 3–4, 3–19, 4–5, 4–17, 5–6, 5–15, 6–7, 7–8, 7–14, 8–9, 9–10, 9–13, 10–11, 11–12, 11–18, 12–13, 12–16, 13–14, 14–15, 15–16, 16–17, 17–18, 18–19] |
| NG-229 | NamedLCF | frucht: [-5, -2, -4, 2, 5, -2, 2, 5, -2, -5, 4, 2]^1 on 12 | `UndirectedAdjacencyList<Int>.frucht()` | n 12; m 18; deg [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0–1, 0–7, 0–11, 1–2, 1–11, 2–3, 2–10, 3–4, 3–5, 4–5, 4–9, 5–6, 6–7, 6–8, 7–8, 8–9, 9–10, 10–11] |
| NG-230 | NamedLCF | Heawood directed: both arcs | `CompressedSparseRow.heawood()` | n 14; m 42; out [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]; E [0→1, 0→5, 0→13, 1→0, 1→2, 1→10, 2→1, 2→3, 2→7, 3→2, 3→4, 3→12, 4→3, 4→5, 4→9, 5→0, 5→4, 5→6, 6→5, 6→7, 6→11, 7→2, 7→6, 7→8, 8→7, 8→9, 8→13, 9→4, 9→8, 9→10, 10→1, 10→9, 10→11, 11→6, 11→10, 11→12, 12→3, 12→11, 12→13, 13→0, 13→8, 13→12] |
| NG-231 | NamedConstructions | icosahedral | `UndirectedAdjacencyList<Int>.icosahedral()` | n 12; m 30; deg [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–2, 1–5, 1–6, 1–7, 2–3, 2–7, 2–8, 3–4, 3–8, 3–9, 4–5, 4–9, 4–10, 5–6, 5–10, 6–7, 6–10, 6–11, 7–8, 7–11, 8–9, 8–11, 9–10, 9–11, 10–11] |
| NG-232 | NamedConstructions | tutte | `UndirectedAdjacencyList<Int>.tutte()` | n 46; m 69; deg 3…3; E [0–1, 0–16, 0–31, 1–2, 1–3, 2–4, 2–5, 3–5, 3–6, 4–7, 4–8, 5–9, 6–10, 6–11, 7–12, 7–44, 8–9, 8–13, 9–11, 10–14, 10–15, 11–15, 12–13, 12–14, 13–15, 14–22, 16–17, 16–18, 17–19, 17–20, 18–20, 18–21, 19–22, 19–23, 20–24, 21–25, 21–26, 22–27, 23–24, 23–28, 24–26, 25–29, 25–30, 26–30, 27–28, 27–29, 28–30, 29–37, 31–32, 31–33, 32–34, 32–35, 33–35, 33–36, 34–37, 34–38, 35–39, 36–40, 36–41, 37–42, 38–39, 38–43, 39–41, 40–44, 40–45, 41–45, 42–43, 42–44, 43–45] |
| NG-233 | NamedConstructions | chvatal | `UndirectedAdjacencyList<Int>.chvatal()` | n 12; m 24; deg [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]; E [0–1, 0–4, 0–6, 0–9, 1–2, 1–5, 1–7, 2–3, 2–6, 2–8, 3–4, 3–7, 3–9, 4–5, 4–8, 5–10, 5–11, 6–10, 6–11, 7–8, 7–11, 8–10, 9–10, 9–11] |
| NG-234 | NamedConstructions | hoffmanSingleton | `UndirectedAdjacencyList<Int>.hoffmanSingleton()` | n 50; m 175; deg 7…7 |
| NG-235 | NamedConstructions | icosahedral directed: both arcs | `CompressedSparseRow.icosahedral()` | n 12; m 60; out [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]; in [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5]; E [0→1, 0→2, 0→3, 0→4, 0→5, 1→0, 1→2, 1→5, 1→6, 1→7, 2→0, 2→1, 2→3, 2→7, 2→8, 3→0, 3→2, 3→4, 3→8, 3→9, 4→0, 4→3, 4→5, 4→9, 4→10, 5→0, 5→1, 5→4, 5→6, 5→10, 6→1, 6→5, 6→7, 6→10, 6→11, 7→1, 7→2, 7→6, 7→8, 7→11, 8→2, 8→3, 8→7, 8→9, 8→11, 9→3, 9→4, 9→8, 9→10, 9→11, 10→4, 10→5, 10→6, 10→9, 10→11, 11→6, 11→7, 11→8, 11→9, 11→10] |
| NG-236 | Kneser | C(70, 35) vertices overflow Int | `UndirectedAdjacencyList<Int>.kneser(setSize: 70, subsetSize: 35)` | **trap**: vertex count overflows Int |
| NG-237 | MargulisGabberGalil | side 1: every step returns to the vertex, no edges | `UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 1)` | n 1; m 0; deg [0]; E [] |
| NG-238 | MargulisGabberGalil | side 2 | `UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 2)` | n 4; m 4; deg [2, 2, 2, 2]; E [0–1, 0–2, 1–3, 2–3] |
| NG-239 | MargulisGabberGalil | side 3: 4-regular | `UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 3)` | n 9; m 18; deg [4, 4, 4, 4, 4, 4, 4, 4, 4]; E [0–1, 0–2, 0–3, 0–6, 1–2, 1–4, 1–7, 2–5, 2–8, 3–4, 3–5, 3–6, 4–5, 4–7, 5–8, 6–7, 6–8, 7–8] |
| NG-240 | MargulisGabberGalil | side 4: a step that meets another is one edge, degrees 4 to 6 | `UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 4)` | n 16; m 40; deg [4, 5, 4, 5, 5, 6, 5, 6, 4, 5, 4, 5, 5, 6, 5, 6]; E [0–1, 0–3, 0–4, 0–12, 1–2, 1–5, 1–9, 1–13, 2–3, 2–6, 2–14, 3–7, 3–11, 3–15, 4–5, 4–6, 4–7, 4–8, 5–6, 5–7, 5–9, 5–13, 6–7, 6–10, 7–11, 7–15, 8–9, 8–11, 8–12, 9–10, 9–13, 10–11, 10–14, 11–15, 12–13, 12–14, 12–15, 13–14, 13–15, 14–15] |
| NG-241 | MargulisGabberGalil | side 5: degrees 4 to 8 | `UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 5)` | n 25; m 70; deg 4…8 |
| NG-242 | MargulisGabberGalil | directed: both arcs | `CompressedSparseRow.margulisGabberGalil(side: 3)` | n 9; m 36; out [4, 4, 4, 4, 4, 4, 4, 4, 4]; in [4, 4, 4, 4, 4, 4, 4, 4, 4]; E [0→1, 0→2, 0→3, 0→6, 1→0, 1→2, 1→4, 1→7, 2→0, 2→1, 2→5, 2→8, 3→0, 3→4, 3→5, 3→6, 4→1, 4→3, 4→5, 4→7, 5→2, 5→3, 5→4, 5→8, 6→0, 6→3, 6→7, 6→8, 7→1, 7→4, 7→6, 7→8, 8→2, 8→5, 8→6, 8→7] |
| NG-243 | MargulisGabberGalil | side 7 | `UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 7)` | n 49; m 154; deg 4…8 |
| NG-244 | MargulisGabberGalil | side 0 | `UndirectedAdjacencyList<Int>.margulisGabberGalil(side: 0)` | **trap**: a Margulis–Gabber–Galil graph needs a side of at least 1, not 0 |
| NG-245 | ChordalCycle | p = 2: K2 | `UndirectedAdjacencyList<Int>.chordalCycle(prime: 2)` | n 2; m 1; deg [1, 1]; E [0–1] |
| NG-246 | ChordalCycle | p = 3: a triangle, 1 and 2 are their own inverses | `UndirectedAdjacencyList<Int>.chordalCycle(prime: 3)` | n 3; m 3; deg [2, 2, 2]; E [0–1, 0–2, 1–2] |
| NG-247 | ChordalCycle | p = 5 | `UndirectedAdjacencyList<Int>.chordalCycle(prime: 5)` | n 5; m 5; deg [2, 2, 2, 2, 2]; E [0–1, 0–4, 1–2, 2–3, 3–4] |
| NG-248 | ChordalCycle | p = 7 | `UndirectedAdjacencyList<Int>.chordalCycle(prime: 7)` | n 7; m 9; deg [2, 2, 3, 3, 3, 3, 2]; E [0–1, 0–6, 1–2, 2–3, 2–4, 3–4, 3–5, 4–5, 5–6] |
| NG-249 | ChordalCycle | p = 11 | `UndirectedAdjacencyList<Int>.chordalCycle(prime: 11)` | n 11; m 13; deg [2, 2, 3, 2, 2, 3, 3, 2, 2, 3, 2]; E [0–1, 0–10, 1–2, 2–3, 2–6, 3–4, 4–5, 5–6, 5–9, 6–7, 7–8, 8–9, 9–10] |
| NG-250 | ChordalCycle | directed: both arcs | `CompressedSparseRow.chordalCycle(prime: 7)` | n 7; m 18; out [2, 2, 3, 3, 3, 3, 2]; in [2, 2, 3, 3, 3, 3, 2]; E [0→1, 0→6, 1→0, 1→2, 2→1, 2→3, 2→4, 3→2, 3→4, 3→5, 4→2, 4→3, 4→5, 5→3, 5→4, 5→6, 6→0, 6→5] |
| NG-251 | ChordalCycle | p = 101 | `UndirectedAdjacencyList<Int>.chordalCycle(prime: 101)` | n 101; m 148; deg 2…3 |
| NG-252 | ChordalCycle | 1 is not prime | `UndirectedAdjacencyList<Int>.chordalCycle(prime: 1)` | **trap**: a chordal cycle graph needs a prime, not 1 |
| NG-253 | ChordalCycle | 9 is not prime | `UndirectedAdjacencyList<Int>.chordalCycle(prime: 9)` | **trap**: a chordal cycle graph needs a prime, not 9 |
| NG-254 | Paley | p = 5: C5 | `UndirectedAdjacencyList<Int>.paley(prime: 5)` | n 5; m 5; deg [2, 2, 2, 2, 2]; E [0–1, 0–4, 1–2, 2–3, 3–4] |
| NG-255 | Paley | p = 13: 6-regular | `UndirectedAdjacencyList<Int>.paley(prime: 13)` | n 13; m 39; deg [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]; E [0–1, 0–3, 0–4, 0–9, 0–10, 0–12, 1–2, 1–4, 1–5, 1–10, 1–11, 2–3, 2–5, 2–6, 2–11, 2–12, 3–4, 3–6, 3–7, 3–12, 4–5, 4–7, 4–8, 5–6, 5–8, 5–9, 6–7, 6–9, 6–10, 7–8, 7–10, 7–11, 8–9, 8–11, 8–12, 9–10, 9–12, 10–11, 11–12] |
| NG-256 | Paley | p = 17 | `UndirectedAdjacencyList<Int>.paley(prime: 17)` | n 17; m 68; deg 8…8 |
| NG-257 | Paley | directed, p = 13: both arcs | `CompressedSparseRow.paley(prime: 13)` | n 13; m 78; out [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]; in [6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6]; E [0→1, 0→3, 0→4, 0→9, 0→10, 0→12, 1→0, 1→2, 1→4, 1→5, 1→10, 1→11, 2→1, 2→3, 2→5, 2→6, 2→11, 2→12, 3→0, 3→2, 3→4, 3→6, 3→7, 3→12, 4→0, 4→1, 4→3, 4→5, 4→7, 4→8, 5→1, 5→2, 5→4, 5→6, 5→8, 5→9, 6→2, 6→3, 6→5, 6→7, 6→9, 6→10, 7→3, 7→4, 7→6, 7→8, 7→10, 7→11, 8→4, 8→5, 8→7, 8→9, 8→11, 8→12, 9→0, 9→5, 9→6, 9→8, 9→10, 9→12, 10→0, 10→1, 10→6, 10→7, 10→9, 10→11, 11→1, 11→2, 11→7, 11→8, 11→10, 11→12, 12→0, 12→2, 12→3, 12→8, 12→9, 12→11] |
| NG-258 | Paley | directed, p = 3: the Paley tournament, one arc per pair | `CompressedSparseRow.paley(prime: 3)` | n 3; m 3; out [1, 1, 1]; in [1, 1, 1]; E [0→1, 1→2, 2→0] |
| NG-259 | Paley | directed, p = 7: the Paley tournament | `CompressedSparseRow.paley(prime: 7)` | n 7; m 21; out [3, 3, 3, 3, 3, 3, 3]; in [3, 3, 3, 3, 3, 3, 3]; E [0→1, 0→2, 0→4, 1→2, 1→3, 1→5, 2→3, 2→4, 2→6, 3→0, 3→4, 3→5, 4→1, 4→5, 4→6, 5→0, 5→2, 5→6, 6→0, 6→1, 6→3] |
| NG-260 | Paley | directed, p = 2: both arcs of K2 | `CompressedSparseRow.paley(prime: 2)` | n 2; m 2; out [1, 1]; in [1, 1]; E [0→1, 1→0] |
| NG-261 | Paley | p = 101 | `UndirectedAdjacencyList<Int>.paley(prime: 101)` | n 101; m 2525; deg 50…50 |
| NG-262 | Paley | undirected needs p ≡ 1 (mod 4): 7 | `UndirectedAdjacencyList<Int>.paley(prime: 7)` | **trap**: the Paley graph is undirected only for a prime ≡ 1 (mod 4), not 7 |
| NG-263 | Paley | undirected needs p ≡ 1 (mod 4): 2 | `UndirectedAdjacencyList<Int>.paley(prime: 2)` | **trap**: the Paley graph is undirected only for a prime ≡ 1 (mod 4), not 2 |
| NG-264 | Paley | 0 is not prime | `UndirectedAdjacencyList<Int>.paley(prime: 0)` | **trap**: a Paley graph needs a prime, not 0 |
| NG-265 | Paley | 15 is not prime | `UndirectedAdjacencyList<Int>.paley(prime: 15)` | **trap**: a Paley graph needs a prime, not 15 |
| NG-266 | Paley | directed: 1 is not prime | `CompressedSparseRow.paley(prime: 1)` | **trap**: a Paley graph needs a prime, not 1 |
