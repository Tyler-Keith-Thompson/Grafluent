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
| NG-017 | CompleteBipartite | K2,3 directed: left → right | `CompressedSparseRow.completeBipartite(leftCount: 2, rightCount: 3)` | n 5; m 6; out [3, 3, 0, 0, 0]; in [0, 0, 2, 2, 2]; E [0→2, 0→3, 0→4, 1→2, 1→3, 1→4] |
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
