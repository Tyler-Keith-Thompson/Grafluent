# BipartiteGraphs: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 python3 ref.py`;
`--write` regenerates this file). Every row's Expected is the model's output, and every row is
checked independently against NetworkX 3.7 (see ref.py's docstring).

Conventions:

* `V` lists the vertices in order (their vertex indices); `E` lists the edges at positions 0, 1, ….
  Rows list edge ends in position order (an `UndirectedAdjacencyList` built by inserting `E` in
  order). `multigraph` rows have parallel edges or several loops, so tests need a Graph conformer
  that keeps them (an in-file struct, rows in position order). `digraph` rows are a
  `DirectedGraph` (an `AdjacencyList` with arcs inserted in order) read through `.undirected`:
  rows are successors, then predecessors.
* `left` and `right` are `bipartition()!.left` / `.right` (and `BipartiteGraph(g)!.left`): the
  least vertex of each connected component is left; each side in `vertices` order.
* `findOddCycle()` rows give the exact cycle this API's breadth-first search returns, in Cycles'
  canonical form (starts at its least vertex, leaves through the lesser edge). Tests check the
  exact value **and** validity (an odd simple cycle of the graph, `Cycle(vertices:edges:in:)` not
  nil). Other libraries return other odd cycles (Boost's `find_odd_cycle` searches depth-first;
  NetworkX has none), so cross-library checks are validity only.
* `BipartiteGraph` rows print `V` (`vertices` order), `L` (`left`), `R` (`right`), `E` (`edges`
  by position, each left endpoint first). Mutation rows list each call's result, separated by `/`.
* `trap` rows are preconditions: tests run them as exit tests (`#expect(processExitsWith:)`).

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| BP-001 | Recognition | empty graph | V []; E [] | isBipartite true; left []; right []; findOddCycle() nil |
| BP-002 | Recognition | one vertex | V [0]; E [] | isBipartite true; left [0]; right []; findOddCycle() nil |
| BP-003 | Recognition | two isolated vertices | V [0, 1]; E [] | isBipartite true; left [0, 1]; right []; findOddCycle() nil |
| BP-004 | Recognition | one edge | V [0, 1]; E [0–1] | isBipartite true; left [0]; right [1]; findOddCycle() nil |
| BP-005 | Recognition | one edge, written 1–0 | V [0, 1]; E [1–0] | isBipartite true; left [0]; right [1]; findOddCycle() nil |
| BP-006 | Recognition | one edge, vertex order [1, 0] | V [1, 0]; E [0–1] | isBipartite true; left [1]; right [0]; findOddCycle() nil |
| BP-007 | Recognition | self-loop alone | V [0]; E [0–0] | isBipartite false; bipartition() nil; findOddCycle() cycle [0] via [0] (length 1) |
| BP-008 | Recognition | self-loop beside an edge | V [0, 1]; E [0–1, 1–1] | isBipartite false; bipartition() nil; findOddCycle() cycle [1] via [1] (length 1) |
| BP-009 | Recognition | self-loop on an isolated vertex of a bipartite graph | V [0, 1, 2]; E [0–1, 2–2] | isBipartite false; bipartition() nil; findOddCycle() cycle [2] via [1] (length 1) |
| BP-010 | Recognition | parallel pair | multigraph V [0, 1]; E [0–1, 0–1] | isBipartite true; left [0]; right [1]; findOddCycle() nil |
| BP-011 | Recognition | parallel pair, second copy written 1–0 | multigraph V [0, 1]; E [0–1, 1–0] | isBipartite true; left [0]; right [1]; findOddCycle() nil |
| BP-012 | Recognition | three parallel copies | multigraph V [0, 1]; E [0–1, 0–1, 0–1] | isBipartite true; left [0]; right [1]; findOddCycle() nil |
| BP-013 | Recognition | parallel pair inside a triangle | multigraph V [0, 1, 2]; E [0–1, 0–1, 1–2, 2–0] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 2, 3] (length 3) |
| BP-014 | Recognition | two self-loops on one vertex | multigraph V [0]; E [0–0, 0–0] | isBipartite false; bipartition() nil; findOddCycle() cycle [0] via [0] (length 1) |
| BP-015 | Recognition | path P3 | V [0, 1, 2]; E [0–1, 1–2] | isBipartite true; left [0, 2]; right [1]; findOddCycle() nil |
| BP-016 | Recognition | path P4 | V [0, 1, 2, 3]; E [0–1, 1–2, 2–3] | isBipartite true; left [0, 2]; right [1, 3]; findOddCycle() nil |
| BP-017 | Recognition | path P7 | V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6] | isBipartite true; left [0, 2, 4, 6]; right [1, 3, 5]; findOddCycle() nil |
| BP-018 | Recognition | path P5 listed from the middle | V [2, 0, 1, 3, 4]; E [0–1, 1–2, 2–3, 3–4] | isBipartite true; left [2, 0, 4]; right [1, 3]; findOddCycle() nil |
| BP-019 | Recognition | triangle C3 | V [0, 1, 2]; E [0–1, 1–2, 2–0] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 1, 2] (length 3) |
| BP-020 | Recognition | triangle written backwards | V [0, 1, 2]; E [2–1, 1–0, 0–2] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [1, 0, 2] (length 3) |
| BP-021 | Recognition | square C4 | V [0, 1, 2, 3]; E [0–1, 1–2, 2–3, 3–0] | isBipartite true; left [0, 2]; right [1, 3]; findOddCycle() nil |
| BP-022 | Recognition | pentagon C5 | V [0, 1, 2, 3, 4]; E [0–1, 1–2, 2–3, 3–4, 4–0] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2, 3, 4] via [0, 1, 2, 3, 4] (length 5) |
| BP-023 | Recognition | hexagon C6 | V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0] | isBipartite true; left [0, 2, 4]; right [1, 3, 5]; findOddCycle() nil |
| BP-024 | Recognition | heptagon C7 | V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–0] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2, 3, 4, 5, 6] via [0, 1, 2, 3, 4, 5, 6] (length 7) |
| BP-025 | Recognition | C9 | V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–8, 8–0] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2, 3, 4, 5, 6, 7, 8] via [0, 1, 2, 3, 4, 5, 6, 7, 8] (length 9) |
| BP-026 | Recognition | C8 | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–0] | isBipartite true; left [0, 2, 4, 6]; right [1, 3, 5, 7]; findOddCycle() nil |
| BP-027 | Recognition | C5 with vertex order reversed | V [4, 3, 2, 1, 0]; E [0–1, 1–2, 2–3, 3–4, 4–0] | isBipartite false; bipartition() nil; findOddCycle() cycle [4, 3, 2, 1, 0] via [3, 2, 1, 0, 4] (length 5) |
| BP-028 | Recognition | C5 with shuffled edge positions | V [0, 1, 2, 3, 4]; E [3–4, 0–1, 4–0, 2–3, 1–2] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2, 3, 4] via [1, 4, 3, 0, 2] (length 5) |
| BP-029 | Recognition | K4 | V [0, 1, 2, 3]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 3, 1] (length 3) |
| BP-030 | Recognition | K5 | V [0, 1, 2, 3, 4]; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–4, 2–3, 2–4, 3–4] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 4, 1] (length 3) |
| BP-031 | Recognition | star K1,4 | V [0, 1, 2, 3, 4]; E [0–1, 0–2, 0–3, 0–4] | isBipartite true; left [0]; right [1, 2, 3, 4]; findOddCycle() nil |
| BP-032 | Recognition | star with centre last | V [0, 1, 2, 3, 4]; E [4–0, 4–1, 4–2, 4–3] | isBipartite true; left [0, 1, 2, 3]; right [4]; findOddCycle() nil |
| BP-033 | Recognition | K2,3 | V [0, 1, 2, 3, 4]; E [0–2, 0–3, 0–4, 1–2, 1–3, 1–4] | isBipartite true; left [0, 1]; right [2, 3, 4]; findOddCycle() nil |
| BP-034 | Recognition | K3,3 | V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5] | isBipartite true; left [0, 1, 2]; right [3, 4, 5]; findOddCycle() nil |
| BP-035 | Recognition | K3,3 plus one edge inside a side | V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 0–1] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 3, 1] via [0, 3, 9] (length 3) |
| BP-036 | Recognition | K3,3 plus one edge inside the other side | V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5, 4–5] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 4, 5] via [1, 9, 2] (length 3) |
| BP-037 | Recognition | grid 3×3 | V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 0–3, 1–2, 1–4, 2–5, 3–4, 3–6, 4–5, 4–7, 5–8, 6–7, 7–8] | isBipartite true; left [0, 2, 4, 6, 8]; right [1, 3, 5, 7]; findOddCycle() nil |
| BP-038 | Recognition | grid 2×4 | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–4, 1–2, 1–5, 2–3, 2–6, 3–7, 4–5, 5–6, 6–7] | isBipartite true; left [0, 2, 5, 7]; right [1, 3, 4, 6]; findOddCycle() nil |
| BP-039 | Recognition | grid 3×3 plus a diagonal | V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 0–3, 1–2, 1–4, 2–5, 3–4, 3–6, 4–5, 4–7, 5–8, 6–7, 7–8, 0–4] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 4] via [0, 3, 12] (length 3) |
| BP-040 | Recognition | hypercube Q3 | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7] | isBipartite true; left [0, 3, 5, 6]; right [1, 2, 4, 7]; findOddCycle() nil |
| BP-041 | Recognition | Petersen graph | V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0–1, 0–4, 0–5, 1–2, 1–6, 2–3, 2–7, 3–4, 3–8, 4–9, 5–7, 5–8, 6–8, 6–9, 7–9] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2, 3, 4] via [0, 3, 5, 7, 1] (length 5) |
| BP-042 | Recognition | wheel W5 (hub 0, rim C5) | V [0, 1, 2, 3, 4, 5]; E [0–1, 0–2, 0–3, 0–4, 0–5, 1–2, 2–3, 3–4, 4–5, 5–1] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 5, 1] (length 3) |
| BP-043 | Recognition | wheel W4 (hub 0, rim C4) | V [0, 1, 2, 3, 4]; E [0–1, 0–2, 0–3, 0–4, 1–2, 2–3, 3–4, 4–1] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 4, 1] (length 3) |
| BP-044 | Recognition | two triangles sharing a vertex (bowtie) | V [0, 1, 2, 3, 4]; E [0–1, 1–2, 2–0, 2–3, 3–4, 4–2] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 1, 2] (length 3) |
| BP-045 | Recognition | triangle at the end of a path | V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–3] | isBipartite false; bipartition() nil; findOddCycle() cycle [3, 4, 5] via [3, 4, 5] (length 3) |
| BP-046 | Recognition | C5 hanging off a long path | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–3] | isBipartite false; bipartition() nil; findOddCycle() cycle [3, 4, 5, 6, 7] via [3, 4, 5, 6, 7] (length 5) |
| BP-047 | Recognition | theta graph: paths of length 2, 2, 4 between 0 and 1 | V [0, 1, 2, 3, 4, 5, 6]; E [0–2, 2–1, 0–3, 3–1, 0–4, 4–5, 5–6, 6–1] | isBipartite true; left [0, 1, 5]; right [2, 3, 4, 6]; findOddCycle() nil |
| BP-048 | Recognition | theta graph: paths of length 1, 2, 3 (odd cycles) | V [0, 1, 2, 3, 4]; E [0–1, 0–2, 2–1, 0–3, 3–4, 4–1] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 2, 1] (length 3) |
| BP-049 | Recognition | C4 plus a chord | V [0, 1, 2, 3]; E [0–1, 1–2, 2–3, 3–0, 0–2] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 1, 4] (length 3) |
| BP-050 | Recognition | C6 plus a long chord (two C4s) | V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0, 0–3] | isBipartite true; left [0, 2, 4]; right [1, 3, 5]; findOddCycle() nil |
| BP-051 | Recognition | C6 plus a short chord (two odd cycles) | V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0, 0–2] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 1, 6] (length 3) |
| BP-052 | Recognition | first conflict met is a C5 although a triangle exists | V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 0–2, 1–3, 2–4, 3–4, 3–5, 5–6, 6–3] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 3, 4, 2] via [0, 2, 4, 3, 1] (length 5) |
| BP-053 | Recognition | disconnected: edge, isolated vertex, path | V [0, 1, 2, 3, 4, 5]; E [1–2, 3–4, 4–5] | isBipartite true; left [0, 1, 3, 5]; right [2, 4]; findOddCycle() nil |
| BP-054 | Recognition | disconnected: least vertex of a component is not its first endpoint | V [0, 1, 2, 3, 4, 5]; E [5–3, 3–1, 4–2] | isBipartite true; left [0, 1, 2, 5]; right [3, 4]; findOddCycle() nil |
| BP-055 | Recognition | disconnected: bipartite component then triangle | V [0, 1, 2, 3, 4, 5]; E [0–1, 2–3, 3–4, 4–2] | isBipartite false; bipartition() nil; findOddCycle() cycle [2, 3, 4] via [1, 2, 3] (length 3) |
| BP-056 | Recognition | disconnected: triangle in the second component, first is C4 | V [0, 1, 2, 3, 4, 5, 6]; E [0–1, 1–2, 2–3, 3–0, 4–5, 5–6, 6–4] | isBipartite false; bipartition() nil; findOddCycle() cycle [4, 5, 6] via [4, 5, 6] (length 3) |
| BP-057 | Recognition | disconnected: two triangles | V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–0, 3–4, 4–5, 5–3] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 1, 2] (length 3) |
| BP-058 | Recognition | isolated vertices around a C4 | V [0, 1, 2, 3, 4, 5, 6]; E [1–2, 2–4, 4–5, 5–1] | isBipartite true; left [0, 1, 3, 4, 6]; right [2, 5]; findOddCycle() nil |
| BP-059 | Recognition | string vertices: a–x, b–x, b–y | V [a, b, x, y]; E [a–x, b–x, b–y] | isBipartite true; left [a, b]; right [x, y]; findOddCycle() nil |
| BP-060 | Recognition | string vertices: triangle a, b, c | V [c, b, a]; E [a–b, b–c, c–a] | isBipartite false; bipartition() nil; findOddCycle() cycle [c, b, a] via [1, 0, 2] (length 3) |
| BP-061 | Recognition | tree (caterpillar) | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 1–4, 2–5, 3–6, 3–7] | isBipartite true; left [0, 2, 4, 6, 7]; right [1, 3, 5]; findOddCycle() nil |
| BP-062 | Recognition | Möbius ladder M8 (not bipartite) | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–0, 0–4, 1–5, 2–6, 3–7] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2, 3, 7] via [0, 1, 2, 11, 7] (length 5) |
| BP-063 | Recognition | Möbius ladder M6 = K3,3 | V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–0, 0–3, 1–4, 2–5] | isBipartite true; left [0, 2, 4]; right [1, 3, 5]; findOddCycle() nil |
| BP-064 | Recognition | prism C3 × K2 | V [0, 1, 2, 3, 4, 5]; E [0–1, 1–2, 2–0, 3–4, 4–5, 5–3, 0–3, 1–4, 2–5] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 1, 2] (length 3) |
| BP-065 | Recognition | cube with one edge subdivided twice | V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7, 0–8, 8–9, 9–1] | isBipartite true; left [0, 3, 5, 6, 9]; right [1, 2, 4, 7, 8]; findOddCycle() nil |
| BP-066 | Recognition | cube with one edge subdivided once | V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–2, 0–4, 1–3, 1–5, 2–3, 2–6, 3–7, 4–5, 4–6, 5–7, 6–7, 0–8, 8–1] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 2, 3, 1, 8] via [0, 4, 2, 12, 11] (length 5) |
| BP-067 | Recognition | odd cycle deep in a BFS tree | V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0–1, 1–2, 2–3, 3–4, 4–5, 5–6, 6–7, 7–8, 8–9, 9–5] | isBipartite false; bipartition() nil; findOddCycle() cycle [5, 6, 7, 8, 9] via [5, 6, 7, 8, 9] (length 5) |
| BP-068 | Recognition | two odd cycles; the one met first is later in vertex order | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–7, 7–6, 6–0, 1–2, 2–3, 3–1, 0–1] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 7, 6] via [0, 1, 2] (length 3) |
| BP-069 | Recognition | directed path 0→1→2 | digraph V [0, 1, 2]; E [0–1, 1–2] | isBipartite true; left [0, 2]; right [1]; findOddCycle() nil |
| BP-070 | Recognition | directed 2-cycle 0⇄1 (a parallel pair once undirected) | digraph V [0, 1]; E [0–1, 1–0] | isBipartite true; left [0]; right [1]; findOddCycle() nil |
| BP-071 | Recognition | directed triangle 0→1→2→0 | digraph V [0, 1, 2]; E [0–1, 1–2, 2–0] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 1, 2] (length 3) |
| BP-072 | Recognition | transitive triangle 0→1, 0→2, 1→2 | digraph V [0, 1, 2]; E [0–1, 0–2, 1–2] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 1, 2] via [0, 2, 1] (length 3) |
| BP-073 | Recognition | directed self-loop | digraph V [0, 1]; E [0–1, 1–1] | isBipartite false; bipartition() nil; findOddCycle() cycle [1] via [1] (length 1) |
| BP-074 | Recognition | directed C4 with all arcs into 0 and 2 | digraph V [0, 1, 2, 3]; E [1–0, 3–0, 1–2, 3–2] | isBipartite true; left [0, 2]; right [1, 3]; findOddCycle() nil |
| BP-075 | Recognition | random bipartite #1 (seed 20261009) | V [0, 1, 2, 3, 4, 5, 6]; E [3–1, 4–1, 6–1, 5–1, 6–2, 3–2, 5–2, 0–2, 0–1, 4–2] | isBipartite true; left [0, 3, 4, 5, 6]; right [1, 2]; findOddCycle() nil |
| BP-076 | Recognition | random G(n, m) #1 (seed 20261009) | V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–3, 6–7, 4–8, 3–8, 1–6, 1–8, 1–7, 0–7, 2–6, 2–4, 1–2] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 3, 8, 1, 7] via [0, 3, 5, 6, 7] (length 5) |
| BP-077 | Recognition | random bipartite #2 (seed 20261009) | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–7, 3–7, 1–2, 4–7, 3–2, 4–2, 6–7, 5–2, 1–7, 6–2, 0–2] | isBipartite true; left [0, 1, 3, 4, 5, 6]; right [2, 7]; findOddCycle() nil |
| BP-078 | Recognition | random G(n, m) #2 (seed 20261009) | V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0–1, 3–7, 4–6, 5–8, 1–6, 7–8, 2–4, 1–5, 2–8, 2–5, 2–6, 4–7] | isBipartite false; bipartition() nil; findOddCycle() cycle [2, 4, 6] via [6, 2, 10] (length 3) |
| BP-079 | Recognition | random bipartite #3 (seed 20261009) | V [0, 1, 2, 3, 4, 5]; E [3–2, 0–5, 0–1, 3–1] | isBipartite true; left [0, 3, 4]; right [1, 2, 5]; findOddCycle() nil |
| BP-080 | Recognition | random G(n, m) #3 (seed 20261009) | V [0, 1, 2, 3, 4, 5]; E [4–5, 0–5, 3–4, 2–3, 1–5, 0–2] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 5, 4, 3, 2] via [1, 0, 2, 3, 5] (length 5) |
| BP-081 | Recognition | random bipartite #4 (seed 20261009) | V [0, 1, 2, 3, 4, 5]; E [2–1, 3–4, 5–1, 5–4] | isBipartite true; left [0, 1, 4]; right [2, 3, 5]; findOddCycle() nil |
| BP-082 | Recognition | random G(n, m) #4 (seed 20261009) | V [0, 1, 2, 3, 4, 5, 6, 7]; E [6–7, 1–6, 0–7, 1–2, 1–5, 1–7, 3–7, 2–7] | isBipartite false; bipartition() nil; findOddCycle() cycle [1, 6, 7] via [1, 0, 5] (length 3) |
| BP-083 | Recognition | random bipartite #5 (seed 20261009) | V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [5–0, 4–2, 4–1, 5–1, 8–1, 5–3, 8–0, 8–6, 8–3, 4–9, 8–2, 5–2, 8–9] | isBipartite true; left [0, 1, 2, 3, 6, 7, 9]; right [4, 5, 8]; findOddCycle() nil |
| BP-084 | Recognition | random G(n, m) #5 (seed 20261009) | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–4, 0–1, 2–6, 3–5, 6–7, 1–4, 3–7, 0–5, 1–2, 2–5, 1–7] | isBipartite false; bipartition() nil; findOddCycle() cycle [0, 4, 1] via [0, 5, 1] (length 3) |
| BP-085 | BipartiteGraph(graph) | path P4, canonical sides | V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g) | V [0, 1, 2, 3]; L [0, 2]; R [1, 3]; E [0–1, 2–1, 2–3] |
| BP-086 | BipartiteGraph(graph) | path P4 with edges written right to left | V [0, 1, 2, 3]; E [1–0, 2–1, 3–2]; BipartiteGraph(g) | V [0, 1, 2, 3]; L [0, 2]; R [1, 3]; E [0–1, 2–1, 2–3] |
| BP-087 | BipartiteGraph(graph) | triangle: nil | V [0, 1, 2]; E [0–1, 1–2, 2–0]; BipartiteGraph(g) | nil |
| BP-088 | BipartiteGraph(graph) | self-loop: nil | V [0, 1]; E [0–1, 1–1]; BipartiteGraph(g) | nil |
| BP-089 | BipartiteGraph(graph) | parallel pair collapses; positions of first copies | multigraph V [0, 1, 2]; E [0–1, 1–2, 1–0, 2–1]; BipartiteGraph(g) | V [0, 1, 2]; L [0, 2]; R [1]; E [0–1, 2–1] |
| BP-090 | BipartiteGraph(graph) | empty graph | V []; E []; BipartiteGraph(g) | V []; L []; R []; E [] |
| BP-091 | BipartiteGraph(graph) | isolated vertices only: all left | V [3, 1, 2]; E []; BipartiteGraph(g) | V [3, 1, 2]; L [3, 1, 2]; R []; E [] |
| BP-092 | BipartiteGraph(graph) | disconnected: each component's least vertex left | V [0, 1, 2, 3, 4]; E [4–1, 2–3]; BipartiteGraph(g) | V [0, 1, 2, 3, 4]; L [0, 1, 2]; R [3, 4]; E [1–4, 2–3] |
| BP-093 | BipartiteGraph(graph) | left: [1, 3] on P4 | V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [1, 3]) | V [0, 1, 2, 3]; L [1, 3]; R [0, 2]; E [1–0, 1–2, 3–2] |
| BP-094 | BipartiteGraph(graph) | left: [0, 2] on P4 | V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [0, 2]) | V [0, 1, 2, 3]; L [0, 2]; R [1, 3]; E [0–1, 2–1, 2–3] |
| BP-095 | BipartiteGraph(graph) | left: [0, 1] on P4: nil (edge 0–1 inside left) | V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [0, 1]) | nil |
| BP-096 | BipartiteGraph(graph) | left: [] on P4: nil (every edge inside right) | V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: []) | nil |
| BP-097 | BipartiteGraph(graph) | left: [] on an edgeless graph: every vertex right | V [0, 1, 2]; E []; BipartiteGraph(g, left: []) | V [0, 1, 2]; L []; R [0, 1, 2]; E [] |
| BP-098 | BipartiteGraph(graph) | left: every vertex on an edgeless graph | V [0, 1, 2]; E []; BipartiteGraph(g, left: [0, 1, 2]) | V [0, 1, 2]; L [0, 1, 2]; R []; E [] |
| BP-099 | BipartiteGraph(graph) | left: listed twice is the same set | V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [1, 3, 1]) | V [0, 1, 2, 3]; L [1, 3]; R [0, 2]; E [1–0, 1–2, 3–2] |
| BP-100 | BipartiteGraph(graph) | left: a non-vertex: nil | V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [1, 3, 9]) | nil |
| BP-101 | BipartiteGraph(graph) | left: per component, either side | V [0, 1, 2, 3, 4, 5]; E [0–1, 2–3, 4–5]; BipartiteGraph(g, left: [1, 2, 5]) | V [0, 1, 2, 3, 4, 5]; L [1, 2, 5]; R [0, 3, 4]; E [1–0, 2–3, 5–4] |
| BP-102 | BipartiteGraph(graph) | left: on a self-loop vertex: nil | V [0, 1]; E [0–1, 1–1]; BipartiteGraph(g, left: [0]) | nil |
| BP-103 | BipartiteGraph(graph) | left: on K3,3 with sides swapped | V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5]; BipartiteGraph(g, left: [3, 4, 5]) | V [0, 1, 2, 3, 4, 5]; L [3, 4, 5]; R [0, 1, 2]; E [3–0, 4–0, 5–0, 3–1, 4–1, 5–1, 3–2, 4–2, 5–2] |
| BP-104 | BipartiteGraph(graph) | left: triangle, any set: nil | V [0, 1, 2]; E [0–1, 1–2, 2–0]; BipartiteGraph(g, left: [0]) | nil |
| BP-105 | BipartiteGraph(left:right:) | no vertices | left [], right [] | V []; L []; R []; E [] |
| BP-106 | BipartiteGraph(left:right:) | sides only | left [a, b], right [x] | V [a, b, x]; L [a, b]; R [x]; E [] |
| BP-107 | BipartiteGraph(left:right:) | one edge | left [a], right [x], edges [a–x] | V [a, x]; L [a]; R [x]; E [a–x] |
| BP-108 | BipartiteGraph(left:right:) | edge written right endpoint first is stored left first | left [a], right [x], edges [x–a] | V [a, x]; L [a]; R [x]; E [a–x] |
| BP-109 | BipartiteGraph(left:right:) | duplicate within a side dropped | left [a, b, a], right [x], edges [a–x] | V [a, b, x]; L [a, b]; R [x]; E [a–x] |
| BP-110 | BipartiteGraph(left:right:) | repeated edge, either orientation, once | left [a, b], right [x], edges [a–x, x–a, b–x] | V [a, b, x]; L [a, b]; R [x]; E [a–x, b–x] |
| BP-111 | BipartiteGraph(left:right:) | overlapping sides: nil | left [a, b], right [b, x] | nil |
| BP-112 | BipartiteGraph(left:right:) | edge inside left: nil | left [a, b], right [x], edges [a–b] | nil |
| BP-113 | BipartiteGraph(left:right:) | edge inside right: nil | left [a], right [x, y], edges [x–y] | nil |
| BP-114 | BipartiteGraph(left:right:) | self-loop: nil | left [a], right [x], edges [a–a] | nil |
| BP-115 | BipartiteGraph(left:right:) | missing endpoint: nil | left [a], right [x], edges [a–z] | nil |
| BP-116 | BipartiteGraph(left:right:) | empty left side | left [], right [x, y] | V [x, y]; L []; R [x, y]; E [] |
| BP-117 | BipartiteGraph(left:right:) | K2,3 | left [0, 1], right [2, 3, 4], edges [0–2, 0–3, 0–4, 1–2, 1–3, 1–4] | V [0, 1, 2, 3, 4]; L [0, 1]; R [2, 3, 4]; E [0–2, 0–3, 0–4, 1–2, 1–3, 1–4] |
| BP-118 | BipartiteGraph(left:right:) | integer sides interleaved | left [0, 2, 4], right [1, 3, 5], edges [0–1, 2–1, 2–3, 4–5, 0–5] | V [0, 2, 4, 1, 3, 5]; L [0, 2, 4]; R [1, 3, 5]; E [0–1, 2–1, 2–3, 4–5, 0–5] |
| BP-119 | Mutation | insert a left vertex into an empty graph | left [], right []; insert("a", on: .left) | inserted true; final V [a]; L [a]; R []; E [] |
| BP-120 | Mutation | insert vertices on both sides, then an edge | left [], right []; insert("a", on: .left); insert("x", on: .right); insert(edge: a–x) | inserted true / inserted true / inserted true, a–x; final V [a, x]; L [a]; R [x]; E [a–x] |
| BP-121 | Mutation | insert an edge given right endpoint first | left [], right []; insert("a", on: .left); insert("x", on: .right); insert(edge: x–a) | inserted true / inserted true / inserted true, a–x; final V [a, x]; L [a]; R [x]; E [a–x] |
| BP-122 | Mutation | insert an existing vertex on its side: not inserted | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert("a", on: .left) | inserted false; final V [a, b, c, x, y]; L [a, b, c]; R [x, y]; E [a–x, b–x, b–y, c–y] |
| BP-123 | Mutation | insert an existing edge, reversed: not inserted | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: x–a) | inserted false, a–x; final V [a, b, c, x, y]; L [a, b, c]; R [x, y]; E [a–x, b–x, b–y, c–y] |
| BP-124 | Mutation | remove the first edge: the last edge moves into position 0 | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: a–x) | a–x; final V [a, b, c, x, y]; L [a, b, c]; R [x, y]; E [c–y, b–x, b–y] |
| BP-125 | Mutation | remove the last edge | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: c–y) | c–y; final V [a, b, c, x, y]; L [a, b, c]; R [x, y]; E [a–x, b–x, b–y] |
| BP-126 | Mutation | remove an absent edge across sides | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: a–y) | nil; final V [a, b, c, x, y]; L [a, b, c]; R [x, y]; E [a–x, b–x, b–y, c–y] |
| BP-127 | Mutation | remove an edge with a non-vertex endpoint | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: a–zz) | nil; final V [a, b, c, x, y]; L [a, b, c]; R [x, y]; E [a–x, b–x, b–y, c–y] |
| BP-128 | Mutation | remove a left vertex: last slot moves in, left list swap-removed | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("a") | a; final V [y, b, c, x]; L [c, b]; R [x, y]; E [c–y, b–x, b–y] |
| BP-129 | Mutation | remove the last vertex | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("y") | y; final V [a, b, c, x]; L [a, b, c]; R [x]; E [a–x, b–x] |
| BP-130 | Mutation | remove a right vertex of degree 2 | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("x") | x; final V [a, b, c, y]; L [a, b, c]; R [y]; E [b–y, c–y] |
| BP-131 | Mutation | remove a non-vertex | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("q") | nil; final V [a, b, c, x, y]; L [a, b, c]; R [x, y]; E [a–x, b–x, b–y, c–y] |
| BP-132 | Mutation | remove then reinsert a vertex on the other side | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("a"); insert("a", on: .right); insert(edge: a–b) | a / inserted true / inserted true, b–a; final V [y, b, c, x, a]; L [c, b]; R [x, y, a]; E [c–y, b–x, b–y, b–a] |
| BP-133 | Mutation | remove every edge, keep the vertices | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; removeAllEdges() | —; final V [a, b, c, x, y]; L [a, b, c]; R [x, y]; E [] |
| BP-134 | Mutation | remove everything | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; removeAll() | —; final V []; L []; R []; E [] |
| BP-135 | Mutation | remove every vertex one by one | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("a"); remove("b"); remove("c"); remove("x"); remove("y") | a / b / c / x / y; final V []; L []; R []; E [] |
| BP-136 | Mutation | build K2,2 then remove a perfect matching | left [0, 1], right [2, 3], edges [0–2, 0–3, 1–2, 1–3]; remove(edge: 0–2); remove(edge: 1–3) | 0–2 / 1–3; final V [0, 1, 2, 3]; L [0, 1]; R [2, 3]; E [1–2, 0–3] |
| BP-137 | Mutation | insert, remove, insert the same edge | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: b–y); insert(edge: y–b) | b–y / inserted true, b–y; final V [a, b, c, x, y]; L [a, b, c]; R [x, y]; E [a–x, b–x, c–y, b–y] |
| BP-138 | Mutation | isolated vertex stays on its side after its edges go | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: c–y); side(of: "c") | c–y / .left; final V [a, b, c, x, y]; L [a, b, c]; R [x, y]; E [a–x, b–x, b–y] |
| BP-139 | Mutation | side(of:) after the slot moved | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("b"); side(of: "y"); side(of: "c") | b / .right / .left; final V [a, y, c, x]; L [a, c]; R [x, y]; E [a–x, c–y] |
| BP-140 | Mutation | projection still correct after mutation | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("b"); insert("d", on: .left); insert(edge: d–x); insert(edge: d–y); projectedGraph(onto: .left) | b / inserted true / inserted true, d–x / inserted true, d–y / V [a, c, d]; E [a–d, c–d]; final V [a, y, c, x, d]; L [a, c, d]; R [x, y]; E [a–x, c–y, d–x, d–y] |
| BP-141 | Mutation | long random sequence (seed 7) | from empty, 37 random operations (ref.py `random_ops(7)`) | final V [6, 9, 1]; L [6]; R [1, 9]; E [6–9] |
| BP-142 | Preconditions | insert a vertex on the other side | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert("a", on: .right) | trap (the vertex is on the other side) |
| BP-143 | Preconditions | insert an edge inside left | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: a–b) | trap (both endpoints are on one side) |
| BP-144 | Preconditions | insert an edge inside right | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: x–y) | trap (both endpoints are on one side) |
| BP-145 | Preconditions | insert a self-loop | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: a–a) | trap (both endpoints are on one side) |
| BP-146 | Preconditions | insert an edge with a missing endpoint | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: a–z) | trap (an endpoint is not a vertex) |
| BP-147 | Preconditions | insert an edge with both endpoints missing | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: p–q) | trap (an endpoint is not a vertex) |
| BP-148 | Preconditions | side(of:) a non-vertex | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; side(of: "z") | trap (not a vertex) |
| BP-149 | Preconditions | side(of:) a removed vertex | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("a"); side(of: "a") | trap (not a vertex) |
| BP-150 | Projection | K2,3 onto left: one edge | left [0, 1], right [2, 3, 4], edges [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]; projectedGraph(onto: .left) | V [0, 1]; E [0–1] |
| BP-151 | Projection | K2,3 onto right: a triangle | left [0, 1], right [2, 3, 4], edges [0–2, 0–3, 0–4, 1–2, 1–3, 1–4]; projectedGraph(onto: .right) | V [2, 3, 4]; E [2–3, 2–4, 3–4] |
| BP-152 | Projection | star centre left, onto right: K4 | left [0], right [1, 2, 3, 4], edges [0–1, 0–2, 0–3, 0–4]; projectedGraph(onto: .right) | V [1, 2, 3, 4]; E [1–2, 1–3, 1–4, 2–3, 2–4, 3–4] |
| BP-153 | Projection | star centre left, onto left: one isolated vertex | left [0], right [1, 2, 3, 4], edges [0–1, 0–2, 0–3, 0–4]; projectedGraph(onto: .left) | V [0]; E [] |
| BP-154 | Projection | path a–x–b–y–c onto left: path a–b–c | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; projectedGraph(onto: .left) | V [a, b, c]; E [a–b, b–c] |
| BP-155 | Projection | path onto right: one edge x–y | left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; projectedGraph(onto: .right) | V [x, y]; E [x–y] |
| BP-156 | Projection | edgeless: isolated vertices of the side | left [0, 1], right [2]; projectedGraph(onto: .left) | V [0, 1]; E [] |
| BP-157 | Projection | empty side | left [], right [0, 1]; projectedGraph(onto: .left) | V []; E [] |
| BP-158 | Projection | two shared neighbours give one edge (simple projection) | left [0, 1], right [2, 3], edges [0–2, 0–3, 1–2, 1–3]; projectedGraph(onto: .left) | V [0, 1]; E [0–1] |
| BP-159 | Projection | isolated left vertex kept | left [0, 1, 5], right [2], edges [0–2, 1–2]; projectedGraph(onto: .left) | V [0, 1, 5]; E [0–1] |
| BP-160 | Projection | C6 onto one side: a triangle | left [0, 2, 4], right [1, 3, 5], edges [0–1, 1–2, 2–3, 3–4, 4–5, 5–0]; projectedGraph(onto: .left) | V [0, 2, 4]; E [0–2, 0–4, 2–4] |
| BP-161 | Projection | affiliation network: people onto events they share | left [p1, p2, p3, p4], right [e1, e2, e3], edges [p1–e1, p2–e1, p2–e2, p3–e2, p4–e3]; projectedGraph(onto: .left) | V [p1, p2, p3, p4]; E [p1–p2, p2–p3] |
| BP-162 | Equality | same sides and edges, different insertion order | (left [a, b], right [x], edges [a–x, b–x]) == (left [b, a], right [x], edges [x–b, a–x]) | true |
| BP-163 | Equality | same graph, sides swapped: not equal | (left [a], right [x], edges [a–x]) == (left [x], right [a], edges [a–x]) | false |
| BP-164 | Equality | same sides, different edges | (left [a, b], right [x], edges [a–x]) == (left [a, b], right [x], edges [b–x]) | false |
| BP-165 | Equality | an extra isolated vertex | (left [a], right [x], edges [a–x]) == (left [a, b], right [x], edges [a–x]) | false |
| BP-166 | Equality | empty and empty | (left [], right []) == (left [], right []) | true |
