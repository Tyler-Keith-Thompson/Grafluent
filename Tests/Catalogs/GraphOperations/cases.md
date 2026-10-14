# GraphOperations: case catalog

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0
python3 Tests/Catalogs/GraphOperations/ref.py`; `--write` regenerates this file, `--stress` adds the random
bases). Every view and result is checked against NetworkX 3.7 and igraph 1.0, the protocol laws, and the
boundary law that index-space members of a view hash nothing.

Conventions:

* `AL V [...]; E [...]` is `AdjacencyList<String>(vertices: V, edges: E)` (with parallel arcs or self-loops:
  `DirectedPseudograph<String>`); `UL` is `UndirectedAdjacencyList<String>` (`Pseudograph<String>` with parallel
  edges or self-loops). `Stable (with holes)` is a `StableDirectedGraph<String>` after a removal, whose
  `vertexIndexBound` is `nil`. Edge positions are `0..<m` in the listed order. Calls follow `/`.
* A view's state: `V [l#i, …]` is `vertices` with each vertex's `vertexIndex(of:)`; `E [p:s→t, …]` is `edges` with
  positions (the base's for reverse and subgraph views; `(i,j)` index pairs for the complement); `bounds a/b` is
  `vertexIndexBound` / `edgeIndexBound`. `rows [v: w …]` lists `successors(of:)` (undirected: `neighbors(of:)`).
* A materialized result: `n` vertices `0..<n`, `E [u→v, …]` its edges at positions `0..<m`. A line graph's vertex
  `k` is the base's edge with `edgeIndex` `k`; a quotient's vertex `i` is block `i`; a disjoint union or join
  numbers `g`'s vertices first, by index, then `h`'s. A condensation lists `components` (Connectivity's Tarjan
  order, each in `vertices` order), whose index is the DAG vertex, and `topologicalOrder`. A power, a
  contraction, a transitive closure or reduction and a relabeling by ordering number the result by the base's
  vertex indices (the contraction's merged vertex at the smaller index, later ones down by one; the ordering's
  `i`th vertex at `i`).
* A result with labels (`relabeled(g, by:)`, written as the name map, and the binary operations on two
  bases `g ; h`): `V [...]` its vertices in order, `E [...]` its edges in position order.
* An ego graph is an induced subgraph view, written out as one.
* `hashes` counts base label lookups (`vertexIndex(of:)` on the base) since the view was built. It is a
  benchmark counter, not API: the Swift suite checks it with a vertex type whose `hash(into:)` counts.
* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).

| ID | Group | Case | Input / call | Expected |
|---|---|---|---|---|
| GO-001 | Reverse | empty | AL V []; E [] / .transposedView | V []; E []; bounds 0/0 |
| GO-002 | Reverse | isolated vertices keep their order | AL V [a, b, c]; E [] / .transposedView | V [a#0, b#1, c#2]; E []; bounds 3/0 |
| GO-003 | Reverse | path: arcs flip, positions kept | AL V [a, b, c]; E [a→b, b→c] / .transposedView | V [a#0, b#1, c#2]; E [0:b→a, 1:c→b]; bounds 3/2; rows [a: ; b: a; c: b] |
| GO-004 | Reverse | self-loop stays a self-loop | AL V [a]; E [a→a] / .transposedView | V [a#0]; E [0:a→a]; bounds 1/1; rows [a: a] |
| GO-005 | Reverse | parallel arcs keep both positions | AL V [a, b]; E [a→b, a→b, b→a] / .transposedView | V [a#0, b#1]; E [0:b→a, 1:b→a, 2:a→b]; bounds 2/3; rows [a: b; b: a a] |
| GO-006 | Reverse | successors are the base's predecessors in in-row order | AL V [a, b, c, d]; E [b→a, c→a, d→a, a→b] / .transposedView | V [a#0, b#1, c#2, d#3]; E [0:a→b, 1:a→c, 2:a→d, 3:b→a]; bounds 4/4; rows [a: b c d; b: a; c: ; d: ] |
| GO-007 | Reverse | edge indices forwarded | AL V [x, y, z]; E [x→y, y→z, z→x] / .transposedView | V [x#0, y#1, z#2]; E [0:y→x, 1:z→y, 2:x→z]; bounds 3/3; edgeIndex(of: 2) 2; sourceIndex(ofEdgeAt: 2) 0 |
| GO-008 | Reverse | reverse of the reverse is the base (same type, O(1)) | AL V [a, b, c]; E [a→b, b→c] / .transposedView.transposedView | V [a#0, b#1, c#2]; E [0:a→b, 1:b→c]; bounds 3/2; is the base: true |
| GO-009 | Reverse | a vertex lookup hashes once, rows none | AL V [a, b, c]; E [a→b, c→b] / .transposedView | V [a#0, b#1, c#2]; E [0:b→a, 1:b→c]; bounds 3/2; outEdges(of: b) [0, 1]; inEdges(ofIndex: 1) []; hashes 1 |
| GO-010 | Induced | empty base, empty set | AL V []; E [] / .inducedSubgraphView(on: []) | V []; E []; bounds 0/0; rows [] |
| GO-011 | Induced | keep nothing | AL V [a, b]; E [a→b] / .inducedSubgraphView(on: []) | V []; E []; bounds 0/nil; rows [] |
| GO-012 | Induced | keep everything: same graph, the base's edge indices | AL V [a, b, c]; E [a→b, b→c, c→a] / .inducedSubgraphView(on: [a, b, c]) | V [a#0, b#1, c#2]; E [0:a→b, 1:b→c, 2:c→a]; bounds 3/3; rows [a: b; b: c; c: a] |
| GO-013 | Induced | renumbered in base order, not listed order | AL V [a, b, c, d]; E [a→b, b→c, c→d, d→a] / .inducedSubgraphView(on: [d, b, a]) | V [a#0, b#1, d#2]; E [0:a→b, 3:d→a]; bounds 3/nil; rows [a: b; b: ; d: a] |
| GO-014 | Induced | repeated vertex listed once | AL V [a, b, c]; E [a→b, b→c] / .inducedSubgraphView(on: [b, b, c]) | V [b#0, c#1]; E [1:b→c]; bounds 2/nil; rows [b: c; c: ] |
| GO-015 | Induced | arcs leaving the set dropped | AL V [a, b, c]; E [a→b, a→c, c→b] / .inducedSubgraphView(on: [a, b]) | V [a#0, b#1]; E [0:a→b]; bounds 2/nil; rows [a: b; b: ] |
| GO-016 | Induced | self-loop kept | AL V [a, b]; E [a→a, a→b] / .inducedSubgraphView(on: [a]) | V [a#0]; E [0:a→a]; bounds 1/nil; rows [a: a] |
| GO-017 | Induced | parallel arcs both kept, base positions | AL V [a, b, c]; E [c→a, a→b, a→b] / .inducedSubgraphView(on: [a, b]) | V [a#0, b#1]; E [1:a→b, 2:a→b]; bounds 2/nil; rows [a: b b; b: ] |
| GO-018 | Induced | isolated kept vertex | AL V [a, b, c]; E [a→b] / .inducedSubgraphView(on: [c, a]) | V [a#0, c#1]; E []; bounds 2/nil; rows [a: ; c: ] |
| GO-019 | Induced | predecessors filtered too | AL V [a, b, c, d]; E [b→a, c→a, d→a] / .inducedSubgraphView(on: [a, c, d]) | V [a#0, c#1, d#2]; E [1:c→a, 2:d→a]; bounds 3/nil; predecessors(of: a) [c, d] |
| GO-020 | Induced | construction hashes once per listed vertex, rows none | AL V [a, b, c, d]; E [a→b, b→c, c→d] / .inducedSubgraphView(on: [b, c, d, c]) | V [b#0, c#1, d#2]; E [1:b→c, 2:c→d]; bounds 3/nil; hashes at construction 4; successorIndices(ofIndex: 0) [1]; edgeIndexBound nil; hashes 0 |
| GO-021 | Induced | edgeCount counts kept arcs (O(Σ out-degree of kept vertices)) | AL V [a, b, c]; E [a→b, b→c, c→a, a→c] / .inducedSubgraphView(on: [a, c]) / .edgeCount | V [a#0, c#1]; E [2:c→a, 3:a→c]; bounds 2/nil; edgeCount 2 |
| GO-022 | Induced | label not in base traps | AL V [a, b]; E [a→b] / .inducedSubgraphView(on: [a, z]) | **trap** (z is not a vertex) |
| GO-023 | Induced | base vertex outside the view: vertexIndex traps | AL V [a, b]; E [a→b] / .inducedSubgraphView(on: [a]) / .vertexIndex(of: b) | **trap** (b is not a vertex of the subgraph) |
| GO-024 | Induced | contains(_:) is false, no trap, for a dropped vertex | AL V [a, b]; E [a→b] / .inducedSubgraphView(on: [a]) / .contains(b) | V [a#0]; E []; bounds 1/nil; contains(b) false; contains(z) false |
| GO-025 | Induced | base without vertex indices traps (phase 1) | Stable (with holes) V [a, b]; E [a→b] / .inducedSubgraphView(on: [a]) | **trap** (the base has no vertex indices (vertexIndexBound is nil)) |
| GO-026 | Induced | undirected: incident rows filtered | UL V [a, b, c, d]; E [a–b, b–c, c–d, d–a, a–c] / .inducedSubgraphView(on: [a, b, c]) | V [a#0, b#1, c#2]; E [0:a–b, 1:b–c, 4:a–c]; bounds 3/nil; rows [a: b c; b: a c; c: b a] |
| GO-027 | Induced | undirected: self-loop listed twice in its row | UL V [a, b]; E [a–a, a–b] / .inducedSubgraphView(on: [a]) | V [a#0]; E [0:a–a]; bounds 1/nil; rows [a: a a] |
| GO-028 | Induced | undirected: parallel edges both kept | UL V [a, b, c]; E [a–b, b–a, b–c] / .inducedSubgraphView(on: [b, a]) | V [a#0, b#1]; E [0:a–b, 1:b–a]; bounds 2/nil; rows [a: b b; b: a a] |
| GO-029 | Spanning | no edges: every vertex, no arcs | AL V [a, b, c]; E [a→b, b→c] / .spanningSubgraphView(edges: []) | V [a#0, b#1, c#2]; E []; bounds 3/0; rows [a: ; b: ; c: ]; edgeIndex [] |
| GO-030 | Spanning | every edge: dense edge indices equal the base's | AL V [a, b, c]; E [a→b, b→c] / .spanningSubgraphView(edges: [0, 1]) | V [a#0, b#1, c#2]; E [0:a→b, 1:b→c]; bounds 3/2; rows [a: b; b: c; c: ]; edgeIndex [0: 0, 1: 1] |
| GO-031 | Spanning | edge indices renumbered by rank in base index order | AL V [a, b, c, d]; E [a→b, b→c, c→d, d→a] / .spanningSubgraphView(edges: [3, 1]) | V [a#0, b#1, c#2, d#3]; E [1:b→c, 3:d→a]; bounds 4/2; rows [a: ; b: c; c: ; d: a]; edgeIndex [1: 0, 3: 1] |
| GO-032 | Spanning | repeated position kept once | AL V [a, b]; E [a→b, b→a] / .spanningSubgraphView(edges: [1, 1]) | V [a#0, b#1]; E [1:b→a]; bounds 2/1; rows [a: ; b: a]; edgeIndex [1: 0] |
| GO-033 | Spanning | one of two parallel arcs | AL V [a, b]; E [a→b, a→b] / .spanningSubgraphView(edges: [1]) | V [a#0, b#1]; E [1:a→b]; bounds 2/1; rows [a: b; b: ]; edgeIndex [1: 0] |
| GO-034 | Spanning | self-loop | AL V [a, b]; E [a→a, a→b] / .spanningSubgraphView(edges: [0]) | V [a#0, b#1]; E [0:a→a]; bounds 2/1; rows [a: a; b: ]; edgeIndex [0: 0] |
| GO-035 | Spanning | vertex indices are the base's (identity, no renumbering) | AL V [a, b, c]; E [c→a] / .spanningSubgraphView(edges: [0]) | V [a#0, b#1, c#2]; E [0:c→a]; bounds 3/1; vertexIndex(of: c) 2 |
| GO-036 | Spanning | position not in base traps | AL V [a, b]; E [a→b] / .spanningSubgraphView(edges: [0, 5]) | **trap** (5 is not an edge position of the base) |
| GO-037 | Spanning | undirected: tree of a cycle | UL V [a, b, c, d]; E [a–b, b–c, c–d, d–a] / .spanningSubgraphView(edges: [0, 1, 2]) | V [a#0, b#1, c#2, d#3]; E [0:a–b, 1:b–c, 2:c–d]; bounds 4/3; rows [a: b; b: a c; c: b d; d: c] |
| GO-038 | Spanning | undirected: self-loop kept twice in its row | UL V [a, b]; E [a–a, a–b] / .spanningSubgraphView(edges: [0]) | V [a#0, b#1]; E [0:a–a]; bounds 2/1; rows [a: a a; b: ] |
| GO-039 | Subgraph | both filters | AL V [a, b, c, d]; E [a→b, b→c, c→d, a→c] / .subgraphView(vertices: [a, b, c], edges: [0, 3]) | V [a#0, b#1, c#2]; E [0:a→b, 3:a→c]; bounds 3/2; rows [a: b c; b: ; c: ] |
| GO-040 | Subgraph | edge with an end outside the vertex set dropped (JGraphT AsSubgraph) | AL V [a, b, c]; E [a→b, b→c] / .subgraphView(vertices: [a, b], edges: [0, 1]) | V [a#0, b#1]; E [0:a→b]; bounds 2/1; rows [a: b; b: ] |
| GO-041 | Subgraph | edge indices count only edges whose ends are kept | AL V [a, b, c]; E [a→b, b→c, c→a] / .subgraphView(vertices: [b, c], edges: [0, 1, 2]) | V [b#0, c#1]; E [1:b→c]; bounds 2/1; rows [b: c; c: ] |
| GO-042 | Subgraph | no vertices | AL V [a, b]; E [a→b] / .subgraphView(vertices: [], edges: [0]) | V []; E []; bounds 0/0; rows [] |
| GO-043 | Subgraph | undirected | UL V [a, b, c, d]; E [a–b, b–c, c–d, d–a] / .subgraphView(vertices: [a, b, d], edges: [0, 3, 1]) | V [a#0, b#1, d#2]; E [0:a–b, 3:d–a]; bounds 3/2; rows [a: b d; b: a; d: a] |
| GO-044 | Subgraph | label not in base traps | AL V [a, b]; E [a→b] / .subgraphView(vertices: [q], edges: [0]) | **trap** (q is not a vertex) |
| GO-045 | Subgraph | position not in base traps | AL V [a, b]; E [a→b] / .subgraphView(vertices: [a], edges: [3]) | **trap** (3 is not an edge position of the base) |
| GO-046 | Subgraph | subgraph of a subgraph: positions still the base's | AL V [a, b, c, d]; E [a→b, b→c, c→d, d→a] / .inducedSubgraphView(on: [a, b, c]).inducedSubgraphView(on: [b, c]) | V [b#0, c#1]; E [1:b→c]; bounds 2/nil; rows [b: c; c: ] |
| GO-047 | Subgraph | reverse of an induced subgraph | AL V [a, b, c]; E [a→b, b→c, c→a] / .inducedSubgraphView(on: [a, b]).transposedView | V [a#0, b#1]; E [0:b→a]; bounds 2/nil; rows [a: ; b: a] |
| GO-048 | Complement | empty graph | AL V []; E [] / .complementView | V []; E []; bounds 0/nil; rows [] |
| GO-049 | Complement | one vertex: no self-loop | AL V [a]; E [] / .complementView | V [a#0]; E []; bounds 1/nil; rows [a: ] |
| GO-050 | Complement | edgeless on three: complete digraph | AL V [a, b, c]; E [] / .complementView | V [a#0, b#1, c#2]; E [(0,1):a→b, (0,2):a→c, (1,0):b→a, (1,2):b→c, (2,0):c→a, (2,1):c→b]; bounds 3/nil; rows [a: b c; b: a c; c: a b] |
| GO-051 | Complement | one arc: the other five | AL V [a, b, c]; E [a→b] / .complementView | V [a#0, b#1, c#2]; E [(0,2):a→c, (1,0):b→a, (1,2):b→c, (2,0):c→a, (2,1):c→b]; bounds 3/nil; rows [a: c; b: a c; c: a b] |
| GO-052 | Complement | complete digraph: no arcs | AL V [a, b]; E [a→b, b→a] / .complementView | V [a#0, b#1]; E []; bounds 2/nil; rows [a: ; b: ] |
| GO-053 | Complement | self-loop ignored | AL V [a, b]; E [a→a] / .complementView | V [a#0, b#1]; E [(0,1):a→b, (1,0):b→a]; bounds 2/nil; rows [a: b; b: a] |
| GO-054 | Complement | parallel arcs count as one | AL V [a, b, c]; E [a→b, a→b] / .complementView | V [a#0, b#1, c#2]; E [(0,2):a→c, (1,0):b→a, (1,2):b→c, (2,0):c→a, (2,1):c→b]; bounds 3/nil; rows [a: c; b: a c; c: a b] |
| GO-055 | Complement | rows ascending by index | AL V [c, a, b]; E [c→b] / .complementView | V [c#0, a#1, b#2]; E [(0,1):c→a, (1,0):a→c, (1,2):a→b, (2,0):b→c, (2,1):b→a]; bounds 3/nil; rows [c: a; a: c b; b: c a] |
| GO-056 | Complement | predecessors when the base is bidirectional | AL V [a, b, c]; E [a→c] / .complementView | V [a#0, b#1, c#2]; E [(0,1):a→b, (1,0):b→a, (1,2):b→c, (2,0):c→a, (2,1):c→b]; bounds 3/nil; predecessors(of: c) [b] |
| GO-057 | Complement | complement twice is the simple loopless base only | AL V [a, b]; E [a→a, a→b, a→b] / .complementView.complementView | V [a#0, b#1]; E [(0,1):a→b]; bounds 2/nil; rows [a: b; b: ] |
| GO-058 | Complement | undirected: path P4 to its complement P4 | UL V [a, b, c, d]; E [a–b, b–c, c–d] / .complementView | V [a#0, b#1, c#2, d#3]; E [(0,2):a–c, (0,3):a–d, (1,3):b–d]; bounds 4/nil; rows [a: c d; b: d; c: a; d: a b] |
| GO-059 | Complement | undirected: C5 is self-complementary (as a set of edges, a different C5) | UL V [a, b, c, d, e]; E [a–b, b–c, c–d, d–e, e–a] / .complementView | V [a#0, b#1, c#2, d#3, e#4]; E [(0,2):a–c, (0,3):a–d, (1,3):b–d, (1,4):b–e, (2,4):c–e]; bounds 5/nil; rows [a: c d; b: d e; c: a e; d: a b; e: b c] |
| GO-060 | Complement | undirected: loop and parallel edges ignored | UL V [a, b, c]; E [a–a, a–b, b–a] / .complementView | V [a#0, b#1, c#2]; E [(0,2):a–c, (1,2):b–c]; bounds 3/nil; rows [a: c; b: c; c: a b] |
| GO-061 | Complement | undirected: K4 has an empty complement | UL V [a, b, c, d]; E [a–b, a–c, a–d, b–c, b–d, c–d] / .complementView | V [a#0, b#1, c#2, d#3]; E []; bounds 4/nil |
| GO-062 | Complement | index-space rows hash nothing; contains(edge:) looks its vertices up, the base's negated | AL V [a, b, c]; E [a→b] / .complementView | V [a#0, b#1, c#2]; E [(0,2):a→c, (1,0):b→a, (1,2):b→c, (2,0):c→a, (2,1):c→b]; bounds 3/nil; outEdges(ofIndex: 0) [(0, 2)]; hashes 0; contains(edge: a→b) false (looks its vertices up); contains(edge: b→b) false (looks its vertices up) |
| GO-063 | Complement | base without vertex indices traps (phase 1) | Stable (with holes) V [a, b]; E [] / .complementView | **trap** (the base has no vertex indices (vertexIndexBound is nil)) |
| GO-064 | LineGraph | no edges | AL V [a, b]; E [] / CompressedSparseRow.lineGraph(of: g) | n 0; E [] |
| GO-065 | LineGraph | directed path: a chain | AL V [a, b, c, d]; E [a→b, b→c, c→d] / CompressedSparseRow.lineGraph(of: g) | n 3; E [0→1, 1→2] |
| GO-066 | LineGraph | directed cycle: a cycle on the arcs | AL V [a, b, c]; E [a→b, b→c, c→a] / CompressedSparseRow.lineGraph(of: g) | n 3; E [0→1, 1→2, 2→0] |
| GO-067 | LineGraph | opposite arcs: a 2-cycle | AL V [a, b]; E [a→b, b→a] / CompressedSparseRow.lineGraph(of: g) | n 2; E [0→1, 1→0] |
| GO-068 | LineGraph | star out of a: no arcs (no arc enters a) | AL V [a, b, c]; E [a→b, a→c] / CompressedSparseRow.lineGraph(of: g) | n 2; E [] |
| GO-069 | LineGraph | parallel arcs: two vertices with the same successors | AL V [a, b, c]; E [a→b, a→b, b→c] / CompressedSparseRow.lineGraph(of: g) | n 3; E [0→2, 1→2] |
| GO-070 | LineGraph | self-loop traps (phase 1: the construction hook takes no self-loops) | AL V [a, b]; E [a→a, a→b] / CompressedSparseRow.lineGraph(of: g) | **trap** (a self-loop's line graph has a self-loop, which the construction targets do not take) |
| GO-071 | LineGraph | undirected path P4 to P3 | UL V [a, b, c, d]; E [a–b, b–c, c–d] / UndirectedAdjacencyList<Int>.lineGraph(of: g) | n 3; E [0–1, 1–2] |
| GO-072 | LineGraph | star K1,3 to a triangle | UL V [a, b, c, d]; E [a–b, a–c, a–d] / UndirectedAdjacencyList<Int>.lineGraph(of: g) | n 3; E [0–1, 0–2, 1–2] |
| GO-073 | LineGraph | triangle to a triangle | UL V [a, b, c]; E [a–b, b–c, c–a] / UndirectedAdjacencyList<Int>.lineGraph(of: g) | n 3; E [0–1, 0–2, 1–2] |
| GO-074 | LineGraph | K4 to the octahedron (12 edges) | UL V [a, b, c, d]; E [a–b, a–c, a–d, b–c, b–d, c–d] / UndirectedAdjacencyList<Int>.lineGraph(of: g) | n 6; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–5, 2–4, 2–5, 3–4, 3–5, 4–5] |
| GO-075 | LineGraph | parallel edges joined once | UL V [a, b, c]; E [a–b, a–b, b–c] / UndirectedAdjacencyList<Int>.lineGraph(of: g) | n 3; E [0–1, 0–2, 1–2] |
| GO-076 | LineGraph | self-loop: adjacent to the edges at its vertex, no loop in L | UL V [a, b, c]; E [a–a, a–b, b–c] / UndirectedAdjacencyList<Int>.lineGraph(of: g) | n 3; E [0–1, 1–2] |
| GO-077 | LineGraph | isolated vertices vanish | UL V [a, b, c]; E [a–b] / UndirectedAdjacencyList<Int>.lineGraph(of: g) | n 1; E [] |
| GO-078 | Condensation | empty | AL V []; E [] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation()) | components []; n 0; E []; topologicalOrder [] |
| GO-079 | Condensation | acyclic: one component per vertex | AL V [a, b, c]; E [a→b, b→c] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation()) | components [{c}, {b}, {a}]; n 3; E [1→0, 2→1]; topologicalOrder [2, 1, 0] |
| GO-080 | Condensation | one cycle: a single vertex | AL V [a, b, c]; E [a→b, b→c, c→a] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation()) | components [{a, b, c}]; n 1; E []; topologicalOrder [0] |
| GO-081 | Condensation | two cycles joined | AL V [a, b, c, d]; E [a→b, b→a, b→c, c→d, d→c] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation()) | components [{c, d}, {a, b}]; n 2; E [1→0]; topologicalOrder [1, 0] |
| GO-082 | Condensation | self-loop does not make an arc in the DAG | AL V [a, b]; E [a→a, a→b] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation()) | components [{b}, {a}]; n 2; E [1→0]; topologicalOrder [1, 0] |
| GO-083 | Condensation | parallel cross arcs merge | AL V [a, b, c]; E [a→b, b→a, a→c, b→c] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation()) | components [{c}, {a, b}]; n 2; E [1→0]; topologicalOrder [1, 0] |
| GO-084 | Condensation | NetworkX order example | AL V [0, 1, 2, 3]; E [0→1, 1→0, 1→2, 3→3] / DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation()) | components [{2}, {0, 1}, {3}]; n 3; E [1→0]; topologicalOrder [2, 1, 0] |
| GO-085 | Quotient | path contracted in pairs | UL V [a, b, c, d]; E [a–b, b–c, c–d] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a, b], [c, d]]) | n 2; E [0–1] |
| GO-086 | Quotient | edges inside a block vanish (no self-loops) | UL V [a, b, c]; E [a–b, b–c] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a, b, c]]) | n 1; E [] |
| GO-087 | Quotient | block order is vertex order of the result | UL V [a, b, c, d]; E [a–b, c–d, b–c] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[c, d], [a, b]]) | n 2; E [0–1] |
| GO-088 | Quotient | directed: both directions kept separately | AL V [a, b, c, d]; E [a→c, d→b] / CompressedSparseRow.quotient(of: g, by: [[a, b], [c, d]]) | n 2; E [0→1, 1→0] |
| GO-089 | Quotient | directed: parallel crossings merge | AL V [a, b, c]; E [a→c, b→c] / CompressedSparseRow.quotient(of: g, by: [[a, b], [c]]) | n 2; E [0→1] |
| GO-090 | Quotient | singletons: a copy with Int vertices | AL V [a, b, c]; E [a→b, b→c] / CompressedSparseRow.quotient(of: g, by: [[a], [b], [c]]) | n 3; E [0→1, 1→2] |
| GO-091 | Quotient | empty block is an isolated vertex | UL V [a, b]; E [a–b] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a], [], [b]]) | n 3; E [0–2] |
| GO-092 | Quotient | vertex in two blocks traps | UL V [a, b]; E [a–b] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a, b], [b]]) | **trap** (b is in two blocks) |
| GO-093 | Quotient | missing vertex traps | UL V [a, b, c]; E [a–b] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a, b]]) | **trap** (the blocks do not cover every vertex) |
| GO-094 | Quotient | label not a vertex traps | UL V [a, b]; E [a–b] / UndirectedAdjacencyList<Int>.quotient(of: g, by: [[a, b, z]]) | **trap** (z is not a vertex) |
| GO-095 | DisjointUnion | two empties | AL V []; E [] ; AL V []; E [] / CompressedSparseRow.disjointUnion(g, h) | n 0; E [] |
| GO-096 | DisjointUnion | h's vertices follow g's | AL V [a, b]; E [a→b] ; AL V [a, b]; E [b→a] / CompressedSparseRow.disjointUnion(g, h) | n 4; E [0→1, 3→2] |
| GO-097 | DisjointUnion | undirected | UL V [x, y]; E [x–y] ; UL V [p, q, r]; E [p–q, q–r] / UndirectedAdjacencyList<Int>.disjointUnion(g, h) | n 5; E [0–1, 2–3, 3–4] |
| GO-098 | DisjointUnion | parallel edges merge | UL V [x, y]; E [x–y, y–x] ; UL V [p]; E [] / UndirectedAdjacencyList<Int>.disjointUnion(g, h) | n 3; E [0–1] |
| GO-099 | DisjointUnion | self-loop traps (phase 1) | AL V [a]; E [a→a] ; AL V [b]; E [] / CompressedSparseRow.disjointUnion(g, h) | **trap** (a self-loop, which the construction targets do not take) |
| GO-100 | Join | K1 + K1 is K2 | UL V [a]; E [] ; UL V [b]; E [] / UndirectedAdjacencyList<Int>.join(g, h) | n 2; E [0–1] |
| GO-101 | Join | empty + anything is a copy | UL V []; E [] ; UL V [a, b]; E [a–b] / UndirectedAdjacencyList<Int>.join(g, h) | n 2; E [0–1] |
| GO-102 | Join | K2 + K2 is K4 | UL V [a, b]; E [a–b] ; UL V [c, d]; E [c–d] / UndirectedAdjacencyList<Int>.join(g, h) | n 4; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3] |
| GO-103 | Join | star K1,3 as K1 + edgeless 3 | UL V [c]; E [] ; UL V [x, y, z]; E [] / UndirectedAdjacencyList<Int>.join(g, h) | n 4; E [0–1, 0–2, 0–3] |
| GO-104 | Join | directed: arcs both ways across | AL V [a]; E [] ; AL V [b, c]; E [b→c] / CompressedSparseRow.join(g, h) | n 3; E [0→1, 0→2, 1→0, 1→2, 2→0] |
| GO-105 | Join | self-loop traps (phase 1) | UL V [a]; E [a–a] ; UL V [b]; E [] / UndirectedAdjacencyList<Int>.join(g, h) | **trap** (a self-loop, which the construction targets do not take) |
| GO-106 | EgoGraph | radius 1: the center and its successors | AL V [a, b, c, d]; E [a→b, b→c, d→a] / .egoGraphView(of: a) | V [a#0, b#1]; E [0:a→b]; bounds 2/nil |
| GO-107 | EgoGraph | radius 2 reaches two arcs out | AL V [a, b, c, d]; E [a→b, b→c, d→a] / .egoGraphView(of: a, radius: 2) | V [a#0, b#1, c#2]; E [0:a→b, 1:b→c]; bounds 3/nil |
| GO-108 | EgoGraph | radius 0 keeps the center alone | AL V [a, b, c]; E [a→b, b→c] / .egoGraphView(of: b, radius: 0) | V [b#0]; E []; bounds 1/nil |
| GO-109 | EgoGraph | undirected: true follows arcs backwards | AL V [a, b, c, d]; E [a→b, b→c, d→a] / .egoGraphView(of: a, undirected: true) | V [a#0, b#1, d#2]; E [0:a→b, 2:d→a]; bounds 3/nil |
| GO-110 | EgoGraph | undirected: false is the directed ego graph | AL V [a, b, c, d]; E [a→b, b→c, d→a] / .egoGraphView(of: a, undirected: false) | V [a#0, b#1]; E [0:a→b]; bounds 2/nil |
| GO-111 | EgoGraph | a radius past the eccentricity keeps every vertex reached | AL V [a, b, c, d]; E [a→b, b→c, c→a] / .egoGraphView(of: b, radius: 9) | V [a#0, b#1, c#2]; E [0:a→b, 1:b→c, 2:c→a]; bounds 3/nil |
| GO-112 | EgoGraph | every vertex kept: the base's rows and edge indices | AL V [a, b, c]; E [a→b, b→c, c→a] / .egoGraphView(of: a, radius: 5) | V [a#0, b#1, c#2]; E [0:a→b, 1:b→c, 2:c→a]; bounds 3/3 |
| GO-113 | EgoGraph | parallel arcs and a self-loop kept as the induced subgraph keeps them | AL V [a, b, c]; E [a→b, a→b, b→b, b→c] / .egoGraphView(of: a, radius: 1) | V [a#0, b#1]; E [0:a→b, 1:a→b, 2:b→b]; bounds 2/nil |
| GO-114 | EgoGraph | undirected path, radius 1 of an inner vertex | UL V [a, b, c, d, e]; E [a–b, b–c, c–d, d–e] / .egoGraphView(of: c) | V [b#0, c#1, d#2]; E [1:b–c, 2:c–d]; bounds 3/nil |
| GO-115 | EgoGraph | undirected: a self-loop twice in its row | UL V [a, b, c]; E [a–a, a–b, b–c] / .egoGraphView(of: a) | V [a#0, b#1]; E [0:a–a, 1:a–b]; bounds 2/nil |
| GO-116 | EgoGraph | center not a vertex traps | AL V [a, b]; E [a→b] / .egoGraphView(of: z) | **trap** (z is not a vertex) |
| GO-117 | EgoGraph | negative radius traps | UL V [a, b]; E [a–b] / .egoGraphView(of: a, radius: -1) | **trap** (the radius must not be negative) |
| GO-118 | EgoGraph | base without vertex indices traps | Stable (with holes) V [a, b]; E [a→b] / .egoGraphView(of: a) | **trap** (the base has no vertex indices (vertexIndexBound is nil)) |
| GO-119 | Power | directed path squared | AL V [a, b, c, d]; E [a→b, b→c, c→d] / CompressedSparseRow.power(of: g, 2) | n 4; E [0→1, 0→2, 1→2, 1→3, 2→3] |
| GO-120 | Power | directed 4-cycle cubed is the complete digraph | AL V [a, b, c, d]; E [a→b, b→c, c→d, d→a] / CompressedSparseRow.power(of: g, 3) | n 4; E [0→1, 0→2, 0→3, 1→0, 1→2, 1→3, 2→0, 2→1, 2→3, 3→0, 3→1, 3→2] |
| GO-121 | Power | first power: loops dropped, parallel arcs merged | AL V [a, b, c]; E [a→a, a→b, a→b, b→c] / CompressedSparseRow.power(of: g, 1) | n 3; E [0→1, 1→2] |
| GO-122 | Power | a power past the longest path adds nothing more | AL V [a, b, c]; E [a→b, b→c] / CompressedSparseRow.power(of: g, 7) | n 3; E [0→1, 0→2, 1→2] |
| GO-123 | Power | undirected path P5 squared | UL V [a, b, c, d, e]; E [a–b, b–c, c–d, d–e] / UndirectedAdjacencyList<Int>.power(of: g, 2) | n 5; E [0–1, 0–2, 1–2, 1–3, 2–3, 2–4, 3–4] |
| GO-124 | Power | undirected C5 squared is K5 | UL V [a, b, c, d, e]; E [a–b, b–c, c–d, d–e, e–a] / UndirectedAdjacencyList<Int>.power(of: g, 2) | n 5; E [0–1, 0–2, 0–3, 0–4, 1–2, 1–3, 1–4, 2–3, 2–4, 3–4] |
| GO-125 | Power | undirected: isolated vertices stay isolated | UL V [a, b, c]; E [a–b] / UndirectedAdjacencyList<Int>.power(of: g, 3) | n 3; E [0–1] |
| GO-126 | Power | undirected: loops and parallel edges ignored | UL V [a, b, c]; E [a–a, a–b, b–a, b–c] / UndirectedAdjacencyList<Int>.power(of: g, 1) | n 3; E [0–1, 1–2] |
| GO-127 | Power | power 0 traps | UL V [a, b]; E [a–b] / UndirectedAdjacencyList<Int>.power(of: g, 0) | **trap** (the power must be at least 1) |
| GO-128 | Contraction | undirected path: two inner vertices merge | UL V [a, b, c, d]; E [a–b, b–c, c–d] / UndirectedAdjacencyList<Int>.contraction(of: g, b, c) | n 3; E [0–1, 1–2] |
| GO-129 | Contraction | directed: nonadjacent vertices merge at the smaller index | AL V [a, b, c, d]; E [a→b, b→c, c→d] / CompressedSparseRow.contraction(of: g, c, a) | n 3; E [0→1, 0→2, 1→0] |
| GO-130 | Contraction | directed: arcs both ways between the two vanish | AL V [a, b, c]; E [a→b, b→a, b→c] / CompressedSparseRow.contraction(of: g, a, b) | n 2; E [0→1] |
| GO-131 | Contraction | undirected: common neighbours' edges merge | UL V [a, b, c, d]; E [a–c, b–c, a–d, b–d] / UndirectedAdjacencyList<Int>.contraction(of: g, a, b) | n 3; E [0–1, 0–2] |
| GO-132 | Contraction | a vertex with itself: a copy, loops dropped | AL V [a, b]; E [a→a, a→b] / CompressedSparseRow.contraction(of: g, b, b) | n 2; E [0→1] |
| GO-133 | Contraction | vertex not in the graph traps | UL V [a, b]; E [a–b] / UndirectedAdjacencyList<Int>.contraction(of: g, a, z) | **trap** (z is not a vertex) |
| GO-134 | Contraction | edge of a triangle: K2 | UL V [a, b, c]; E [a–b, b–c, c–a] / UndirectedAdjacencyList<Int>.contraction(of: g, edgeAt: 1) | n 2; E [0–1] |
| GO-135 | Contraction | edge of C4: a triangle | UL V [a, b, c, d]; E [a–b, b–c, c–d, d–a] / UndirectedAdjacencyList<Int>.contraction(of: g, edgeAt: 0) | n 3; E [0–1, 0–2, 1–2] |
| GO-136 | Contraction | directed: the arc and its parallel copy vanish | AL V [a, b, c]; E [a→b, a→b, b→c] / CompressedSparseRow.contraction(of: g, edgeAt: 0) | n 2; E [0→1] |
| GO-137 | Contraction | a self-loop: a copy without loops | AL V [a, b]; E [a→b, b→b] / CompressedSparseRow.contraction(of: g, edgeAt: 1) | n 2; E [0→1] |
| GO-138 | TransitiveClosure | empty | AL V []; E [] / CompressedSparseRow.transitiveClosure(of: g) | n 0; E [] |
| GO-139 | TransitiveClosure | path: every forward pair | AL V [a, b, c, d]; E [a→b, b→c, c→d] / CompressedSparseRow.transitiveClosure(of: g) | n 4; E [0→1, 0→2, 0→3, 1→2, 1→3, 2→3] |
| GO-140 | TransitiveClosure | cycle: every ordered pair, no loops | AL V [a, b, c]; E [a→b, b→c, c→a] / CompressedSparseRow.transitiveClosure(of: g) | n 3; E [0→1, 0→2, 1→0, 1→2, 2→0, 2→1] |
| GO-141 | TransitiveClosure | two cycles, one arc between | AL V [a, b, c, d]; E [a→b, b→a, b→c, c→d, d→c] / CompressedSparseRow.transitiveClosure(of: g) | n 4; E [0→1, 0→2, 0→3, 1→0, 1→2, 1→3, 2→3, 3→2] |
| GO-142 | TransitiveClosure | a self-loop alone adds nothing | AL V [a, b]; E [a→a] / CompressedSparseRow.transitiveClosure(of: g) | n 2; E [] |
| GO-143 | TransitiveClosure | parallel arcs merge | AL V [a, b, c]; E [a→b, a→b, b→c] / CompressedSparseRow.transitiveClosure(of: g) | n 3; E [0→1, 0→2, 1→2] |
| GO-144 | TransitiveReduction | acyclic: the shortcut goes | AL V [a, b, c]; E [a→b, b→c, a→c] / CompressedSparseRow.transitiveReduction(of: g) | n 3; E [0→1, 1→2] |
| GO-145 | TransitiveReduction | acyclic diamond with a shortcut | AL V [a, b, c, d]; E [a→b, a→c, b→d, c→d, a→d] / CompressedSparseRow.transitiveReduction(of: g) | n 4; E [0→1, 0→2, 1→3, 2→3] |
| GO-146 | TransitiveReduction | cycle with a chord: the cycle in index order | AL V [a, b, c]; E [a→b, b→c, c→a, a→c] / CompressedSparseRow.transitiveReduction(of: g) | n 3; E [0→1, 1→2, 2→0] |
| GO-147 | TransitiveReduction | a component's cycle runs in index order, not the arcs' order | AL V [a, b, c]; E [a→c, c→b, b→a] / CompressedSparseRow.transitiveReduction(of: g) | n 3; E [0→1, 1→2, 2→0] |
| GO-148 | TransitiveReduction | two components: one arc between their first members | AL V [a, b, c, d]; E [a→b, b→a, b→c, b→d, c→d, d→c] / CompressedSparseRow.transitiveReduction(of: g) | n 4; E [0→1, 0→2, 1→0, 2→3, 3→2] |
| GO-149 | TransitiveReduction | components through a middle one: the long arc goes | AL V [a, b, c, d, e]; E [a→b, b→a, a→c, c→d, d→c, d→e, a→e] / CompressedSparseRow.transitiveReduction(of: g) | n 5; E [0→1, 0→2, 1→0, 2→3, 2→4, 3→2] |
| GO-150 | TransitiveReduction | self-loops and parallel arcs dropped | AL V [a, b]; E [a→a, a→b, a→b] / CompressedSparseRow.transitiveReduction(of: g) | n 2; E [0→1] |
| GO-151 | Relabel | ordering reversed | AL V [a, b, c]; E [a→b, b→c] / CompressedSparseRow.relabeled(g, ordering: [c, b, a]) | n 3; E [1→0, 2→1] |
| GO-152 | Relabel | ordering by name | UL V [d, b, a, c]; E [d–b, b–a, a–c] / UndirectedAdjacencyList<Int>.relabeled(g, ordering: [a, b, c, d]) | n 4; E [0–1, 0–2, 1–3] |
| GO-153 | Relabel | parallel edges merge | UL V [a, b]; E [a–b, b–a] / UndirectedAdjacencyList<Int>.relabeled(g, ordering: [b, a]) | n 2; E [0–1] |
| GO-154 | Relabel | vertex listed twice traps | AL V [a, b]; E [a→b] / CompressedSparseRow.relabeled(g, ordering: [a, a]) | **trap** (a is listed twice in the ordering) |
| GO-155 | Relabel | ordering missing a vertex traps | AL V [a, b, c]; E [a→b] / CompressedSparseRow.relabeled(g, ordering: [a, b]) | **trap** (the ordering does not list every vertex) |
| GO-156 | Relabel | self-loop traps (phase 1) | AL V [a, b]; E [a→a] / CompressedSparseRow.relabeled(g, ordering: [a, b]) | **trap** (a self-loop, which the construction targets do not take) |
| GO-157 | Relabel | one-to-one: the edges in order | AL V [a, b, c]; E [a→b, b→c, c→a] / AdjacencyList<String>.relabeled(g, by: [a: x, b: y, c: z]) | V [x, y, z]; E [x→y, y→z, z→x] |
| GO-158 | Relabel | merging two ends makes a self-loop; coinciding arcs kept once | AL V [a, b, c]; E [a→c, b→c, a→b] / AdjacencyList<String>.relabeled(g, by: [a: x, b: x, c: y]) | V [x, y]; E [x→y, x→x] |
| GO-159 | Relabel | merging into a pseudograph keeps every arc | AL V [a, b, c]; E [a→c, b→c, a→b] / DirectedPseudograph<String>.relabeled(g, by: [a: x, b: x, c: y]) | V [x, y]; E [x→y, x→y, x→x] |
| GO-160 | Relabel | undirected: names merge, the first edge's orientation kept | UL V [a, b, c, d]; E [a–b, c–d, b–c, d–a] / UndirectedAdjacencyList<String>.relabeled(g, by: [a: p, b: q, c: p, d: q]) | V [p, q]; E [p–q] |
| GO-161 | Relabel | undirected into a pseudograph | UL V [a, b, c]; E [a–b, b–c] / Pseudograph<String>.relabeled(g, by: [a: p, b: q, c: p]) | V [p, q]; E [p–q, q–p] |
| GO-162 | Union | shared vertices merge: NetworkX compose | AL V [a, b, c]; E [a→b, b→c] ; AL V [b, c, d]; E [c→b, c→d, b→c] / AdjacencyList<String>.union(g, h) | V [a, b, c, d]; E [a→b, b→c, c→b, c→d] |
| GO-163 | Union | disjoint vertex sets | AL V [a, b]; E [a→b] ; AL V [c, d]; E [d→c] / AdjacencyList<String>.union(g, h) | V [a, b, c, d]; E [a→b, d→c] |
| GO-164 | Union | undirected: an edge in both, reversed, once | UL V [a, b, c]; E [a–b, b–c] ; UL V [c, b, d]; E [b–a, c–d] / UndirectedAdjacencyList<String>.union(g, h) | V [a, b, c, d]; E [a–b, b–c, c–d] |
| GO-165 | Union | self-loops kept | UL V [a, b]; E [a–a] ; UL V [b]; E [b–b] / UndirectedAdjacencyList<String>.union(g, h) | V [a, b]; E [a–a, b–b] |
| GO-166 | Intersection | NetworkX example | UL V [0, 1, 2]; E [0–1, 0–2, 1–2] ; UL V [0, 1, 2, 3]; E [0–3, 1–2, 2–3] / UndirectedAdjacencyList<String>.intersection(g, h) | V [0, 1, 2]; E [1–2] |
| GO-167 | Intersection | directed: opposite arcs do not meet | AL V [a, b, c]; E [a→b, b→c] ; AL V [b, a, c]; E [b→a, b→c] / AdjacencyList<String>.intersection(g, h) | V [a, b, c]; E [b→c] |
| GO-168 | Intersection | only the shared vertices | AL V [a, b, c]; E [a→b] ; AL V [d, b, a]; E [a→b] / AdjacencyList<String>.intersection(g, h) | V [a, b]; E [a→b] |
| GO-169 | Difference | NetworkX example | UL V [0, 1, 2, 3]; E [0–1, 0–2, 1–2, 1–3] ; UL V [0, 1, 2, 3]; E [0–1, 1–2, 0–3] / UndirectedAdjacencyList<String>.difference(g, h) | V [0, 1, 2, 3]; E [0–2, 1–3] |
| GO-170 | Difference | directed: an arc's reverse does not remove it | AL V [a, b]; E [a→b, b→a] ; AL V [a, b]; E [b→a] / AdjacencyList<String>.difference(g, h) | V [a, b]; E [a→b] |
| GO-171 | Difference | vertex sets may differ: g's vertices | AL V [a, b, c]; E [a→b, b→c] ; AL V [b, c, d]; E [b→c, c→d] / AdjacencyList<String>.difference(g, h) | V [a, b, c]; E [a→b] |
| GO-172 | SymmetricDifference | NetworkX example | UL V [0, 1, 2, 3]; E [0–1, 0–2, 1–2, 1–3] ; UL V [0, 1, 2, 3]; E [0–1, 1–2, 0–3] / UndirectedAdjacencyList<String>.symmetricDifference(g, h) | V [0, 1, 2, 3]; E [0–2, 0–3, 1–3] |
| GO-173 | SymmetricDifference | directed, vertex sets differ: every vertex of either | AL V [a, b, c]; E [a→b, b→c] ; AL V [c, b, d]; E [b→c, c→d] / AdjacencyList<String>.symmetricDifference(g, h) | V [a, b, c, d]; E [a→b, c→d] |
