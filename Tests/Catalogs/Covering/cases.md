# Covering: case catalog (CV-001 – CV-220, 220 cases)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 [--with
igraph] python3 ref.py`; `--write` regenerates this file, `--stress` adds 1,500 random graphs).
Expected is the API's documented output (api.md, Determinism); the last column says what each row
was checked against. ref.py's docstring lists the reference for each entry point.

## Notation

* **Graphs.** `V [..]; E [..]`: vertices in order (their vertex indices), then edges at positions
  0, 1, …, each `u-v`. Rows list edge ends in position order (an `UndirectedAdjacencyList` built
  by inserting `E` in order; a self-loop twice). `multigraph` rows have parallel edges, so tests
  need an in-file `Graph` conformer whose rows are in position order. `L [..]; R [..]; E [..]` is a
  `BipartiteGraph(left:right:edges:)`, so `vertices` is L then R. `; w [..]` gives vertex weights
  in `vertices` order (the `weight:` closure); unweighted calls weigh every vertex 1.
* **Generators** (as MatchingModule's catalog). `K(n)` every pair i < j lexicographic; `C(n)`
  edges i–(i+1) mod n; `P(n)` the path; `star(k)` hub 0, edges 0–i; `wheel(k)` hub 0, spokes 0–i
  then rim i–(i mod k + 1); `Kb(a,b)` the `BipartiteGraph` with left 0..<a, right a..<a+b, edges
  row-major; `grid(r,c)` vertex i·c+j, edges right then down, row-major; `nx(name)` NetworkX's
  `name()` nodes and `edges()`. `lcg(n,m,seed)`: a 64-bit LCG, x ← x·6364136223846793005 +
  1442695040888963407 (mod 2⁶⁴), each draw x >> 33; an edge is two draws (u = d % n, v = d % n),
  skipped when u = v or the pair is already an edge, until m edges. `lcgv(n,m,seed,k)`: the same
  graph, then n more draws from the same generator, vertex weight 1 + d % k. `lcgb(l,r,m,seed)`: a
  `BipartiteGraph`, left 0..<l, right l..<l+r, an edge u = d % l, v = l + d % r, repeats skipped.
* **Vertex sets** are listed in `vertices` order (the result arrays). `; weight w` is the sum of
  the result's weights (tests sum it; the API returns only the vertices).
* **Edge covers.** `[..] {..}`: positions ascending and the pairs they join.
* **Koenig rows** give the sides of `g.bipartition()` (each component's least vertex left) as
  `left [..], right [..]`.
* **trap** rows are preconditions: tests run them as exit tests (`#expect(processExitsWith:)`).

| ID | Group | Case | Input | Call | Expected | Checked |
|---|---|---|---|---|---|---|
| CV-001 | MaximumIS | empty graph | V []; E [] | `maximumIndependentSet()` | [] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-002 | MaximumIS | one vertex | V [0]; E [] | `maximumIndependentSet()` | [0] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-003 | MaximumIS | one vertex with a self-loop | V [0]; E [0-0] | `maximumIndependentSet()` | [] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-004 | MaximumIS | two isolated vertices | V [0, 1]; E [] | `maximumIndependentSet()` | [0, 1] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-005 | MaximumIS | one edge: the lesser end | V [0, 1]; E [0-1] | `maximumIndependentSet()` | [0] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-006 | MaximumIS | self-loop excludes its vertex | V [0, 1]; E [0-0, 0-1] | `maximumIndependentSet()` | [1] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-007 | MaximumIS | parallel edges count once | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `maximumIndependentSet()` | [0, 2] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-008 | MaximumIS | triangle | K(3) | `maximumIndependentSet()` | [0] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-009 | MaximumIS | K(5) | K(5) | `maximumIndependentSet()` | [0] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-010 | MaximumIS | path P(2) | P(2) | `maximumIndependentSet()` | [0] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-011 | MaximumIS | path P(4): {0,2} beats {0,3}, {1,3} | P(4) | `maximumIndependentSet()` | [0, 2] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-012 | MaximumIS | path P(5) | P(5) | `maximumIndependentSet()` | [0, 2, 4] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-013 | MaximumIS | path P(6) | P(6) | `maximumIndependentSet()` | [0, 2, 4] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-014 | MaximumIS | cycle C(4) | C(4) | `maximumIndependentSet()` | [0, 2] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-015 | MaximumIS | cycle C(5) | C(5) | `maximumIndependentSet()` | [0, 2] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-016 | MaximumIS | cycle C(6) | C(6) | `maximumIndependentSet()` | [0, 2, 4] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-017 | MaximumIS | cycle C(7) | C(7) | `maximumIndependentSet()` | [0, 2, 4] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-018 | MaximumIS | star(4): the leaves | star(4) | `maximumIndependentSet()` | [1, 2, 3, 4] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-019 | MaximumIS | wheel(5) | wheel(5) | `maximumIndependentSet()` | [1, 3] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-020 | MaximumIS | wheel(6) | wheel(6) | `maximumIndependentSet()` | [1, 3, 5] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-021 | MaximumIS | Petersen | nx(petersen_graph) | `maximumIndependentSet()` | [0, 2, 8, 9] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-022 | MaximumIS | grid(3,4) | grid(3,4) | `maximumIndependentSet()` | [0, 2, 5, 7, 8, 10] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-023 | MaximumIS | grid(5,5) | grid(5,5) | `maximumIndependentSet()` | [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24] | = oracle reference; least of igraph largest_independent_vertex_sets |
| CV-024 | MaximumIS | Kb(2,3) as BipartiteGraph | Kb(2,3) | `maximumIndependentSet()` | [2, 3, 4] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-025 | MaximumIS | Kb(3,3) | Kb(3,3) | `maximumIndependentSet()` | [0, 1, 2] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-026 | MaximumIS | mixed components: triangle, path, looped pendant | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 1-2, 2-0, 3-4, 4-5, 6-6, 6-7] | `maximumIndependentSet()` | [0, 3, 5, 7] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-027 | MaximumIS | vertex order, not label order | V [d, a, c, b]; E [d-a, a-c, c-b] | `maximumIndependentSet()` | [d, c] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-028 | MaximumIS | bipartite, interleaved vertex order | V [0, 1, 2, 3, 4, 5]; E [0-3, 3-1, 1-4, 4-2, 2-5] | `maximumIndependentSet()` | [0, 1, 2] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-029 | MaximumIS | bipartite core: perfect matching, lattice choice | V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-3, 3-0, 0-5, 4-5] | `maximumIndependentSet()` | [0, 2, 4] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-030 | MaximumIS | odd cycle with pendant | V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-3, 3-4, 4-0, 2-5] | `maximumIndependentSet()` | [0, 3, 5] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-031 | MaximumIS | all vertices looped | V [0, 1, 2]; E [0-0, 1-1, 2-2, 0-1] | `maximumIndependentSet()` | [] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-032 | MaximumIS | loop in a bipartite piece splits it | V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-4, 2-2] | `maximumIndependentSet()` | [0, 3] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-033 | MaximumIS | nx(bull_graph) | nx(bull_graph) | `maximumIndependentSet()` | [0, 3, 4] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-034 | MaximumIS | nx(house_graph) | nx(house_graph) | `maximumIndependentSet()` | [0, 3] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-035 | MaximumIS | nx(krackhardt_kite_graph) | nx(krackhardt_kite_graph) | `maximumIndependentSet()` | [0, 4, 7, 9] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-036 | MaximumIS | nx(frucht_graph) | nx(frucht_graph) | `maximumIndependentSet()` | [0, 2, 5, 9, 11] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-037 | MaximumIS | lcg(12,20,1) | lcg(12,20,1) | `maximumIndependentSet()` | [1, 2, 3, 5, 8, 11] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-038 | MaximumIS | lcg(16,30,2) | lcg(16,30,2) | `maximumIndependentSet()` | [0, 3, 5, 8, 11, 13, 14] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-039 | MaximumIS | lcg(24,40,3) | lcg(24,40,3) | `maximumIndependentSet()` | [0, 1, 2, 3, 4, 6, 7, 9, 10, 16, 18, 20, 22] | = oracle reference; least of igraph largest_independent_vertex_sets |
| CV-040 | MaximumIS | lcgb(6,7,15,4) as BipartiteGraph | lcgb(6,7,15,4) | `maximumIndependentSet()` | [4, 6, 8, 9, 10, 11, 12] | = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-041 | MaximumIS | lcgb(10,10,25,5) | lcgb(10,10,25,5) | `maximumIndependentSet()` | [3, 6, 7, 9, 10, 11, 12, 13, 14, 15, 18] | = oracle reference; least of igraph largest_independent_vertex_sets |
| CV-042 | IndependenceNumber | empty graph | V []; E [] | `independenceNumber()` | 0 | igraph independence_number; = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-043 | IndependenceNumber | one vertex with a self-loop | V [0]; E [0-0] | `independenceNumber()` | 0 | igraph independence_number; = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-044 | IndependenceNumber | C(7) | C(7) | `independenceNumber()` | 3 | igraph independence_number; = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-045 | IndependenceNumber | Petersen: 4 | nx(petersen_graph) | `independenceNumber()` | 4 | igraph independence_number; = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-046 | IndependenceNumber | K(6): 1 | K(6) | `independenceNumber()` | 1 | igraph independence_number; = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-047 | IndependenceNumber | grid(4,4): 8 | grid(4,4) | `independenceNumber()` | 8 | igraph independence_number; = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-048 | IndependenceNumber | nx(dodecahedral_graph) | nx(dodecahedral_graph) | `independenceNumber()` | 8 | igraph independence_number; = oracle reference; least of igraph largest_independent_vertex_sets |
| CV-049 | IndependenceNumber | lcg(20,45,6) | lcg(20,45,6) | `independenceNumber()` | 8 | igraph independence_number; = oracle reference; least of igraph largest_independent_vertex_sets |
| CV-050 | MinimumVC | empty graph | V []; E [] | `minimumVertexCover()` | [] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-051 | MinimumVC | one vertex | V [0]; E [] | `minimumVertexCover()` | [] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-052 | MinimumVC | self-loop: its vertex | V [0]; E [0-0] | `minimumVertexCover()` | [0] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-053 | MinimumVC | one edge: the greater end | V [0, 1]; E [0-1] | `minimumVertexCover()` | [1] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-054 | MinimumVC | loop and edge | V [0, 1]; E [0-0, 0-1] | `minimumVertexCover()` | [0] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-055 | MinimumVC | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `minimumVertexCover()` | [1] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-056 | MinimumVC | triangle | K(3) | `minimumVertexCover()` | [1, 2] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-057 | MinimumVC | K(4) | K(4) | `minimumVertexCover()` | [1, 2, 3] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-058 | MinimumVC | P(4) | P(4) | `minimumVertexCover()` | [1, 3] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-059 | MinimumVC | C(5) | C(5) | `minimumVertexCover()` | [1, 3, 4] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-060 | MinimumVC | star(5): the hub | star(5) | `minimumVertexCover()` | [0] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-061 | MinimumVC | Petersen: 6 | nx(petersen_graph) | `minimumVertexCover()` | [1, 3, 4, 5, 6, 7] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-062 | MinimumVC | Kb(2,3): the left side | Kb(2,3) | `minimumVertexCover()` | [0, 1] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets; size = maximum matching 2 |
| CV-063 | MinimumVC | Kb(3,2): the right side | Kb(3,2) | `minimumVertexCover()` | [3, 4] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets; size = maximum matching 2 |
| CV-064 | MinimumVC | L [0,1,2]; R [3,4,5]: lex vs Koenig | L [0, 1, 2]; R [3, 4, 5]; E [0-3, 1-3, 1-4, 2-4, 2-5] | `minimumVertexCover()` | [3, 4, 5] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets; size = maximum matching 3; NetworkX to_vertex_cover (most left vertices) is [0, 1, 2] |
| CV-065 | MinimumVC | BipartiteGraph with an isolated right vertex | L [0, 1]; R [2, 3, 4]; E [0-2, 1-2, 1-3] | `minimumVertexCover()` | [2, 3] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets; size = maximum matching 2; NetworkX to_vertex_cover (most left vertices) is [0, 1] |
| CV-066 | MinimumVC | lcgb(8,6,18,7) | lcgb(8,6,18,7) | `minimumVertexCover()` | [8, 9, 10, 11, 12, 13] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets; size = maximum matching 6; NetworkX to_vertex_cover (most left vertices) is [0, 1, 3, 4, 5, 6] |
| CV-067 | MinimumVC | grid(4,5) | grid(4,5) | `minimumVertexCover()` | [1, 3, 5, 7, 9, 11, 13, 15, 17, 19] | complement of maximumIndependentSet(); = oracle reference; least of igraph largest_independent_vertex_sets |
| CV-068 | MinimumVC | mixed components | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 1-2, 2-0, 3-4, 4-5, 6-6, 6-7] | `minimumVertexCover()` | [1, 2, 4, 6] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-069 | MinimumVC | letters | V [d, a, c, b]; E [d-a, a-c, c-b] | `minimumVertexCover()` | [a, b] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-070 | MinimumVC | lcg(18,35,8) | lcg(18,35,8) | `minimumVertexCover()` | [0, 1, 5, 6, 7, 10, 11, 14, 15, 16] | complement of maximumIndependentSet(); = oracle reference; least of igraph largest_independent_vertex_sets |
| CV-071 | MinimumVC | wheel(7) | wheel(7) | `minimumVertexCover()` | [0, 2, 4, 6, 7] | complement of maximumIndependentSet(); = oracle reference; brute force; least of igraph largest_independent_vertex_sets |
| CV-072 | KoenigVC | empty graph | V []; E []; left [], right [] | `minimumVertexCover(bipartition: g.bipartition()!)` | [] | = NetworkX to_vertex_cover; size = matching 0; brute force: the unique minimum cover with the most left vertices |
| CV-073 | KoenigVC | one edge | V [0, 1]; E [0-1]; left [0], right [1] | `minimumVertexCover(bipartition: g.bipartition()!)` | [0] | = NetworkX to_vertex_cover; size = matching 1; brute force: the unique minimum cover with the most left vertices; minimumVertexCover() is [1] |
| CV-074 | KoenigVC | P(4) | P(4); left [0, 2], right [1, 3] | `minimumVertexCover(bipartition: g.bipartition()!)` | [0, 2] | = NetworkX to_vertex_cover; size = matching 2; brute force: the unique minimum cover with the most left vertices; minimumVertexCover() is [1, 3] |
| CV-075 | KoenigVC | P(5) | P(5); left [0, 2, 4], right [1, 3] | `minimumVertexCover(bipartition: g.bipartition()!)` | [1, 3] | = NetworkX to_vertex_cover; size = matching 2; brute force: the unique minimum cover with the most left vertices |
| CV-076 | KoenigVC | C(6) | C(6); left [0, 2, 4], right [1, 3, 5] | `minimumVertexCover(bipartition: g.bipartition()!)` | [0, 2, 4] | = NetworkX to_vertex_cover; size = matching 3; brute force: the unique minimum cover with the most left vertices; minimumVertexCover() is [1, 3, 5] |
| CV-077 | KoenigVC | star(3) | star(3); left [0], right [1, 2, 3] | `minimumVertexCover(bipartition: g.bipartition()!)` | [0] | = NetworkX to_vertex_cover; size = matching 1; brute force: the unique minimum cover with the most left vertices |
| CV-078 | KoenigVC | Kb(2,3) | Kb(2,3); left [0, 1], right [2, 3, 4] | `minimumVertexCover(bipartition: g.bipartition()!)` | [0, 1] | = NetworkX to_vertex_cover; size = matching 2; brute force: the unique minimum cover with the most left vertices |
| CV-079 | KoenigVC | L [0,1,2]; R [3,4,5] | L [0, 1, 2]; R [3, 4, 5]; E [0-3, 1-3, 1-4, 2-4, 2-5]; left [0, 1, 2], right [3, 4, 5] | `minimumVertexCover(bipartition: g.bipartition()!)` | [0, 1, 2] | = NetworkX to_vertex_cover; size = matching 3; brute force: the unique minimum cover with the most left vertices; minimumVertexCover() is [3, 4, 5] |
| CV-080 | KoenigVC | grid(3,3) | grid(3,3); left [0, 2, 4, 6, 8], right [1, 3, 5, 7] | `minimumVertexCover(bipartition: g.bipartition()!)` | [1, 3, 5, 7] | = NetworkX to_vertex_cover; size = matching 4; brute force: the unique minimum cover with the most left vertices |
| CV-081 | KoenigVC | grid(4,4) | grid(4,4); left [0, 2, 5, 7, 8, 10, 13, 15], right [1, 3, 4, 6, 9, 11, 12, 14] | `minimumVertexCover(bipartition: g.bipartition()!)` | [0, 2, 5, 7, 8, 10, 13, 15] | = NetworkX to_vertex_cover; size = matching 8; brute force: the unique minimum cover with the most left vertices; minimumVertexCover() is [1, 3, 4, 6, 9, 11, 12, 14] |
| CV-082 | KoenigVC | tree | V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 0-2, 1-3, 1-4, 2-5, 2-6]; left [0, 3, 4, 5, 6], right [1, 2] | `minimumVertexCover(bipartition: g.bipartition()!)` | [1, 2] | = NetworkX to_vertex_cover; size = matching 2; brute force: the unique minimum cover with the most left vertices |
| CV-083 | KoenigVC | two components | V [0, 1, 2, 3, 4, 5]; E [1-0, 1-2, 3-4, 5-4]; left [0, 2, 3, 5], right [1, 4] | `minimumVertexCover(bipartition: g.bipartition()!)` | [1, 4] | = NetworkX to_vertex_cover; size = matching 2; brute force: the unique minimum cover with the most left vertices |
| CV-084 | KoenigVC | parallel edges | multigraph V [0, 1, 2]; E [0-1, 0-1, 1-2]; left [0, 2], right [1] | `minimumVertexCover(bipartition: g.bipartition()!)` | [1] | = NetworkX to_vertex_cover; size = matching 1; brute force: the unique minimum cover with the most left vertices |
| CV-085 | KoenigVC | lcgb(6,7,15,4) | lcgb(6,7,15,4); left [0, 1, 2, 3, 4, 5], right [6, 7, 8, 9, 10, 11, 12] | `minimumVertexCover(bipartition: g.bipartition()!)` | [0, 1, 2, 3, 4, 5] | = NetworkX to_vertex_cover; size = matching 6; brute force: the unique minimum cover with the most left vertices; minimumVertexCover() is [0, 1, 2, 3, 5, 7] |
| CV-086 | KoenigVC | lcgb(9,5,20,9) | lcgb(9,5,20,9); left [0, 1, 2, 3, 4, 5, 6, 7, 8], right [9, 10, 11, 12, 13] | `minimumVertexCover(bipartition: g.bipartition()!)` | [9, 10, 11, 12, 13] | = NetworkX to_vertex_cover; size = matching 5; brute force: the unique minimum cover with the most left vertices |
| CV-087 | ApproxVC | empty graph | V []; E [] | `approximateMinimumVertexCover()` | [] | = NetworkX min_weighted_vertex_cover; weight 0 <= 2 x optimum 0 |
| CV-088 | ApproxVC | one edge | V [0, 1]; E [0-1] | `approximateMinimumVertexCover()` | [0] | = NetworkX min_weighted_vertex_cover; weight 1 <= 2 x optimum 1 |
| CV-089 | ApproxVC | self-loop | V [0]; E [0-0] | `approximateMinimumVertexCover()` | [0] | = NetworkX min_weighted_vertex_cover; weight 1 <= 2 x optimum 1 |
| CV-090 | ApproxVC | loop and edge | V [0, 1]; E [0-0, 0-1] | `approximateMinimumVertexCover()` | [0] | = NetworkX min_weighted_vertex_cover; weight 1 <= 2 x optimum 1 |
| CV-091 | ApproxVC | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `approximateMinimumVertexCover()` | [0, 1] | weight 2 <= 2 x optimum 1 |
| CV-092 | ApproxVC | triangle | K(3) | `approximateMinimumVertexCover()` | [0, 1] | = NetworkX min_weighted_vertex_cover; weight 2 <= 2 x optimum 2 |
| CV-093 | ApproxVC | P(5) | P(5) | `approximateMinimumVertexCover()` | [0, 1, 2, 3] | = NetworkX min_weighted_vertex_cover; weight 4 <= 2 x optimum 2 |
| CV-094 | ApproxVC | C(6) | C(6) | `approximateMinimumVertexCover()` | [0, 1, 2, 3, 4] | = NetworkX min_weighted_vertex_cover; weight 5 <= 2 x optimum 3 |
| CV-095 | ApproxVC | star(4): hub first | star(4) | `approximateMinimumVertexCover()` | [0] | = NetworkX min_weighted_vertex_cover; weight 1 <= 2 x optimum 1 |
| CV-096 | ApproxVC | star(4) leaves first | V [0, 1, 2, 3, 4]; E [1-0, 2-0, 3-0, 4-0] | `approximateMinimumVertexCover()` | [0] | = NetworkX min_weighted_vertex_cover; weight 1 <= 2 x optimum 1 |
| CV-097 | ApproxVC | K(5) | K(5) | `approximateMinimumVertexCover()` | [0, 1, 2, 3] | = NetworkX min_weighted_vertex_cover; weight 4 <= 2 x optimum 4 |
| CV-098 | ApproxVC | Petersen | nx(petersen_graph) | `approximateMinimumVertexCover()` | [0, 1, 2, 3, 4, 5, 6, 7] | = NetworkX min_weighted_vertex_cover; weight 8 <= 2 x optimum 6 |
| CV-099 | ApproxVC | positions not in NetworkX order | V [0, 1, 2, 3]; E [2-3, 0-1, 1-2] | `approximateMinimumVertexCover()` | [0, 2] | NetworkX scans G.edges() (by node), a different order, and returns [0, 1, 2]; weight 2 <= 2 x optimum 2 |
| CV-100 | ApproxVC | lcg(16,30,2) | lcg(16,30,2) | `approximateMinimumVertexCover()` | [1, 2, 3, 6, 7, 8, 10, 11, 12, 15] | NetworkX scans G.edges() (by node), a different order, and returns [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 12]; weight 10 <= 2 x optimum 9 |
| CV-101 | ApproxVC | one edge, heavier first end | V [0, 1]; E [0-1]; w [3, 1] | `approximateMinimumVertexCover(weight:)` | [1]; weight 1 | = NetworkX min_weighted_vertex_cover; weight 1 <= 2 x optimum 1 |
| CV-102 | ApproxVC | equal weights: lesser index | V [0, 1]; E [0-1]; w [2, 2] | `approximateMinimumVertexCover(weight:)` | [0]; weight 2 | = NetworkX min_weighted_vertex_cover; weight 2 <= 2 x optimum 2 |
| CV-103 | ApproxVC | star, heavy hub | star(4); w [10, 1, 1, 1, 1] | `approximateMinimumVertexCover(weight:)` | [1, 2, 3, 4]; weight 4 | = NetworkX min_weighted_vertex_cover; weight 4 <= 2 x optimum 4 |
| CV-104 | ApproxVC | star, light hub | star(4); w [1, 5, 5, 5, 5] | `approximateMinimumVertexCover(weight:)` | [0]; weight 1 | = NetworkX min_weighted_vertex_cover; weight 1 <= 2 x optimum 1 |
| CV-105 | ApproxVC | path, residual costs carry | V [0, 1, 2, 3]; E [0-1, 1-2, 2-3]; w [2, 3, 2, 3] | `approximateMinimumVertexCover(weight:)` | [0, 1, 2]; weight 7 | = NetworkX min_weighted_vertex_cover; weight 7 <= 2 x optimum 4 |
| CV-106 | ApproxVC | zero weights | C(4); w [0, 1, 0, 1] | `approximateMinimumVertexCover(weight:)` | [0, 2]; weight 0 | = NetworkX min_weighted_vertex_cover; weight 0 <= 2 x optimum 0 |
| CV-107 | ApproxVC | triangle weighted | K(3); w [1, 2, 3] | `approximateMinimumVertexCover(weight:)` | [0, 1]; weight 3 | = NetworkX min_weighted_vertex_cover; weight 3 <= 2 x optimum 3 |
| CV-108 | ApproxVC | self-loop weighted | V [0, 1]; E [0-0, 0-1]; w [5, 1] | `approximateMinimumVertexCover(weight:)` | [0]; weight 5 | = NetworkX min_weighted_vertex_cover; weight 5 <= 2 x optimum 5 |
| CV-109 | ApproxVC | float weights | V [0, 1, 2]; E [0-1, 1-2]; w [0.5, 0.75, 0.25] | `approximateMinimumVertexCover(weight:)` | [0, 1]; weight 1.25 | = NetworkX min_weighted_vertex_cover; weight 1.25 <= 2 x optimum 0.75 |
| CV-110 | ApproxVC | lcgv(12,20,3,9) | lcgv(12,20,3,9); w [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3] | `approximateMinimumVertexCover(weight:)` | [0, 1, 5, 6, 7, 9, 11]; weight 34 | NetworkX scans G.edges() (by node), a different order, and returns [0, 1, 3, 5, 6, 7, 9, 11]; weight 34 <= 2 x optimum 28 |
| CV-111 | ApproxVC | lcgv(20,40,5,5) | lcgv(20,40,5,5); w [4, 4, 2, 1, 5, 1, 4, 4, 4, 3, 5, 4, 1, 3, 4, 4, 2, 5, 5, 3] | `approximateMinimumVertexCover(weight:)` | [0, 1, 2, 3, 4, 5, 8, 9, 11, 12, 13, 14, 15, 16]; weight 42 | NetworkX scans G.edges() (by node), a different order, and returns [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]; weight 42 <= 2 x optimum 40 |
| CV-112 | MaximalIS | empty graph | V []; E [] | `maximalIndependentSet()` | [] | independent and maximal |
| CV-113 | MaximalIS | one vertex | V [0]; E [] | `maximalIndependentSet()` | [0] | independent and maximal; = NetworkX dominating_set(start_with: 0) |
| CV-114 | MaximalIS | self-loop: empty | V [0]; E [0-0] | `maximalIndependentSet()` | [] | independent and maximal; looped vertices never taken (NetworkX's random choice can take one) |
| CV-115 | MaximalIS | P(5) | P(5) | `maximalIndependentSet()` | [0, 2, 4] | independent and maximal; = NetworkX dominating_set(start_with: 0) |
| CV-116 | MaximalIS | star(3): hub first | star(3) | `maximalIndependentSet()` | [0] | independent and maximal; = NetworkX dominating_set(start_with: 0) |
| CV-117 | MaximalIS | star(3), seeded with a leaf | star(3) | `maximalIndependentSet(containing: [1])` | [1, 2, 3] | independent and maximal; NetworkX accepts the seeds; = NetworkX dominating_set(start_with: 1) |
| CV-118 | MaximalIS | C(6) | C(6) | `maximalIndependentSet()` | [0, 2, 4] | independent and maximal; = NetworkX dominating_set(start_with: 0) |
| CV-119 | MaximalIS | C(6) seeded {1, 4} | C(6) | `maximalIndependentSet(containing: [1, 4])` | [1, 4] | independent and maximal; NetworkX accepts the seeds |
| CV-120 | MaximalIS | seeds adjacent: nil | C(6) | `maximalIndependentSet(containing: [1, 2])` | nil | NetworkX raises NetworkXUnfeasible |
| CV-121 | MaximalIS | seed with a self-loop: nil | V [0, 1]; E [0-0, 0-1] | `maximalIndependentSet(containing: [0])` | nil | NetworkX raises NetworkXUnfeasible |
| CV-122 | MaximalIS | loop skipped | V [0, 1]; E [0-0, 0-1] | `maximalIndependentSet()` | [1] | independent and maximal; looped vertices never taken (NetworkX's random choice can take one) |
| CV-123 | MaximalIS | Petersen | nx(petersen_graph) | `maximalIndependentSet()` | [0, 2, 6] | independent and maximal; = NetworkX dominating_set(start_with: 0) |
| CV-124 | MaximalIS | letters | V [d, a, c, b]; E [d-a, a-c, c-b] | `maximalIndependentSet()` | [d, c] | independent and maximal; = NetworkX dominating_set(start_with: d) |
| CV-125 | MaximalIS | repeated seed | P(3) | `maximalIndependentSet(containing: [2, 2])` | [0, 2] | independent and maximal; NetworkX accepts the seeds |
| CV-126 | MaximalIS | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `maximalIndependentSet()` | [0, 2] | independent and maximal |
| CV-127 | MaximalIS | lcg(16,30,2) | lcg(16,30,2) | `maximalIndependentSet()` | [0, 2, 3, 6, 9] | independent and maximal; = NetworkX dominating_set(start_with: 0) |
| CV-128 | MaximalIS | lcg(16,30,2) seeded | lcg(16,30,2) | `maximalIndependentSet(containing: [5, 9])` | [0, 3, 5, 6, 7, 9] | independent and maximal; NetworkX accepts the seeds |
| CV-129 | MinimumDS | empty graph | V []; E [] | `minimumDominatingSet()` | [] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-130 | MinimumDS | one vertex | V [0]; E [] | `minimumDominatingSet()` | [0] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-131 | MinimumDS | self-loop | V [0]; E [0-0] | `minimumDominatingSet()` | [0] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-132 | MinimumDS | two isolated | V [0, 1]; E [] | `minimumDominatingSet()` | [0, 1] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-133 | MinimumDS | one edge | V [0, 1]; E [0-1] | `minimumDominatingSet()` | [0] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-134 | MinimumDS | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `minimumDominatingSet()` | [1] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-135 | MinimumDS | P(3): the middle | P(3) | `minimumDominatingSet()` | [1] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-136 | MinimumDS | P(4) | P(4) | `minimumDominatingSet()` | [0, 2] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-137 | MinimumDS | P(7) | P(7) | `minimumDominatingSet()` | [0, 2, 5] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-138 | MinimumDS | C(6) | C(6) | `minimumDominatingSet()` | [0, 3] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-139 | MinimumDS | star(5): the hub | star(5) | `minimumDominatingSet()` | [0] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-140 | MinimumDS | K(4) | K(4) | `minimumDominatingSet()` | [0] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-141 | MinimumDS | Petersen: 3 | nx(petersen_graph) | `minimumDominatingSet()` | [0, 2, 6] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-142 | MinimumDS | grid(3,3) | grid(3,3) | `minimumDominatingSet()` | [0, 2, 7] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-143 | MinimumDS | grid(4,4) | grid(4,4) | `minimumDominatingSet()` | [1, 7, 8, 14] | brute force (first subset of the domination number in combinations order); per-component union agrees; greedy gives 6 |
| CV-144 | MinimumDS | mixed components | V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 1-2, 2-0, 3-4, 4-5, 6-6, 6-7] | `minimumDominatingSet()` | [0, 4, 6] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-145 | MinimumDS | letters | V [d, a, c, b]; E [d-a, a-c, c-b] | `minimumDominatingSet()` | [d, c] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-146 | MinimumDS | three branches | V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 0-2, 0-3, 1-4, 2-5, 3-6, 1-2, 2-3] | `minimumDominatingSet()` | [1, 2, 3] | brute force (first subset of the domination number in combinations order); per-component union agrees |
| CV-147 | MinimumDS | lcg(14,20,10) | lcg(14,20,10) | `minimumDominatingSet()` | [1, 2, 3, 12] | brute force (first subset of the domination number in combinations order); per-component union agrees; greedy gives 5 |
| CV-148 | ApproxDS | empty graph | V []; E [] | `approximateMinimumDominatingSet()` | [] | = NetworkX min_weighted_dominating_set; dominating; weight 0 <= H(1) x optimum 0 |
| CV-149 | ApproxDS | one vertex | V [0]; E [] | `approximateMinimumDominatingSet()` | [0] | = NetworkX min_weighted_dominating_set; dominating; weight 1 <= H(1) x optimum 1 |
| CV-150 | ApproxDS | self-loop | V [0]; E [0-0] | `approximateMinimumDominatingSet()` | [0] | = NetworkX min_weighted_dominating_set; dominating; weight 1 <= H(1) x optimum 1 |
| CV-151 | ApproxDS | P(3) | P(3) | `approximateMinimumDominatingSet()` | [1] | = NetworkX min_weighted_dominating_set; dominating; weight 1 <= H(3) x optimum 1 |
| CV-152 | ApproxDS | P(6) | P(6) | `approximateMinimumDominatingSet()` | [1, 4] | = NetworkX min_weighted_dominating_set; dominating; weight 2 <= H(3) x optimum 2 |
| CV-153 | ApproxDS | C(6) | C(6) | `approximateMinimumDominatingSet()` | [0, 3] | = NetworkX min_weighted_dominating_set; dominating; weight 2 <= H(3) x optimum 2 |
| CV-154 | ApproxDS | star(4) | star(4) | `approximateMinimumDominatingSet()` | [0] | = NetworkX min_weighted_dominating_set; dominating; weight 1 <= H(5) x optimum 1 |
| CV-155 | ApproxDS | Petersen | nx(petersen_graph) | `approximateMinimumDominatingSet()` | [0, 2, 6] | = NetworkX min_weighted_dominating_set; dominating; weight 3 <= H(4) x optimum 3 |
| CV-156 | ApproxDS | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `approximateMinimumDominatingSet()` | [1] | = NetworkX min_weighted_dominating_set; dominating; weight 1 <= H(3) x optimum 1 |
| CV-157 | ApproxDS | grid(4,4) | grid(4,4) | `approximateMinimumDominatingSet()` | [1, 2, 5, 10, 11, 12] | = NetworkX min_weighted_dominating_set; dominating |
| CV-158 | ApproxDS | letters | V [d, a, c, b]; E [d-a, a-c, c-b] | `approximateMinimumDominatingSet()` | [a, c] | = NetworkX min_weighted_dominating_set; dominating; weight 2 <= H(3) x optimum 2 |
| CV-159 | ApproxDS | three branches | V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 0-2, 0-3, 1-4, 2-5, 3-6, 1-2, 2-3] | `approximateMinimumDominatingSet()` | [1, 2, 3] | = NetworkX min_weighted_dominating_set; dominating; weight 3 <= H(5) x optimum 3 |
| CV-160 | ApproxDS | lcg(14,20,10) | lcg(14,20,10) | `approximateMinimumDominatingSet()` | [1, 2, 3, 5, 12] | = NetworkX min_weighted_dominating_set; dominating; weight 5 <= H(7) x optimum 4 |
| CV-161 | ApproxDS | star, heavy hub | star(4); w [10, 1, 1, 1, 1] | `approximateMinimumDominatingSet(weight:)` | [1, 2, 3, 4]; weight 4 | = NetworkX min_weighted_dominating_set; dominating; weight 4 <= H(5) x optimum 4 |
| CV-162 | ApproxDS | star, cheap hub | star(4); w [2, 1, 1, 1, 1] | `approximateMinimumDominatingSet(weight:)` | [0]; weight 2 | = NetworkX min_weighted_dominating_set; dominating; weight 2 <= H(5) x optimum 2 |
| CV-163 | ApproxDS | ratio tie: least index | V [0, 1, 2, 3]; E [0-1, 2-3, 1-2]; w [2, 4, 4, 2] | `approximateMinimumDominatingSet(weight:)` | [0, 3]; weight 4 | = NetworkX min_weighted_dominating_set; dominating; weight 4 <= H(3) x optimum 4 |
| CV-164 | ApproxDS | zero weight vertex first | P(4); w [1, 1, 0, 1] | `approximateMinimumDominatingSet(weight:)` | [0, 2]; weight 1 | = NetworkX min_weighted_dominating_set; dominating; weight 1 <= H(3) x optimum 1 |
| CV-165 | ApproxDS | float weights | P(5); w [0.3, 0.9, 0.3, 0.9, 0.3] | `approximateMinimumDominatingSet(weight:)` | [0, 2, 4]; weight 0.8999999999999999 | = NetworkX min_weighted_dominating_set; dominating; weight 0.8999999999999999 <= H(3) x optimum 0.8999999999999999 |
| CV-166 | ApproxDS | lcgv(12,20,3,9) | lcgv(12,20,3,9); w [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3] | `approximateMinimumDominatingSet(weight:)` | [2, 4, 9, 11]; weight 19 | = NetworkX min_weighted_dominating_set; dominating; weight 19 <= H(8) x optimum 19 |
| CV-167 | MinimumEC | empty graph | V []; E [] | `minimumEdgeCover()` | [] {} | size = NetworkX min_edge_cover; size n - nu = 0 - 0; brute force |
| CV-168 | MinimumEC | isolated vertex: nil | V [0]; E [] | `minimumEdgeCover()` | nil | a vertex has no edge; NetworkX raises NetworkXException |
| CV-169 | MinimumEC | self-loop covers its vertex | V [0]; E [0-0] | `minimumEdgeCover()` | [0] {0–0} | size = NetworkX min_edge_cover; size n - nu = 1 - 0; brute force |
| CV-170 | MinimumEC | one edge | V [0, 1]; E [0-1] | `minimumEdgeCover()` | [0] {0–1} | size = NetworkX min_edge_cover; size n - nu = 2 - 1; brute force |
| CV-171 | MinimumEC | edge and isolated vertex: nil | V [0, 1, 2]; E [0-1] | `minimumEdgeCover()` | nil | a vertex has no edge; NetworkX raises NetworkXException |
| CV-172 | MinimumEC | loop and edge: the matched edge covers both | V [0, 1]; E [0-0, 0-1] | `minimumEdgeCover()` | [1] {0–1} | size = NetworkX min_edge_cover; size n - nu = 2 - 1; brute force |
| CV-173 | MinimumEC | uncovered vertex takes its first edge, a loop | V [0, 1, 2]; E [0-1, 2-2, 1-2] | `minimumEdgeCover()` | [0, 1] {0–1, 2–2} | size = NetworkX min_edge_cover; size n - nu = 3 - 1; brute force |
| CV-174 | MinimumEC | uncovered vertex takes its first edge | V [0, 1, 2]; E [0-1, 1-2, 2-2] | `minimumEdgeCover()` | [0, 1] {0–1, 1–2} | size = NetworkX min_edge_cover; size n - nu = 3 - 1; brute force |
| CV-175 | MinimumEC | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `minimumEdgeCover()` | [0, 2] {0–1, 1–2} | size n - nu = 3 - 1; brute force |
| CV-176 | MinimumEC | P(3) | P(3) | `minimumEdgeCover()` | [0, 1] {0–1, 1–2} | size = NetworkX min_edge_cover; size n - nu = 3 - 1; brute force |
| CV-177 | MinimumEC | P(4) | P(4) | `minimumEdgeCover()` | [0, 2] {0–1, 2–3} | size = NetworkX min_edge_cover; size n - nu = 4 - 2; brute force |
| CV-178 | MinimumEC | triangle | K(3) | `minimumEdgeCover()` | [0, 1] {0–1, 0–2} | size = NetworkX min_edge_cover; size n - nu = 3 - 1; brute force |
| CV-179 | MinimumEC | star(4) | star(4) | `minimumEdgeCover()` | [0, 1, 2, 3] {0–1, 0–2, 0–3, 0–4} | size = NetworkX min_edge_cover; size n - nu = 5 - 1; brute force |
| CV-180 | MinimumEC | C(5) | C(5) | `minimumEdgeCover()` | [0, 2, 3] {0–1, 2–3, 3–4} | size = NetworkX min_edge_cover; size n - nu = 5 - 2; brute force |
| CV-181 | MinimumEC | K(4) | K(4) | `minimumEdgeCover()` | [0, 5] {0–1, 2–3} | size = NetworkX min_edge_cover; size n - nu = 4 - 2; brute force |
| CV-182 | MinimumEC | Petersen | nx(petersen_graph) | `minimumEdgeCover()` | [0, 5, 9, 10, 12] {0–1, 2–3, 4–9, 5–7, 6–8} | size = NetworkX min_edge_cover; size n - nu = 10 - 5; brute force |
| CV-183 | MinimumEC | blossom | V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-5] | `minimumEdgeCover()` | [0, 3, 5] {0–1, 2–3, 4–5} | size = NetworkX min_edge_cover; size n - nu = 6 - 3; brute force |
| CV-184 | MinimumEC | lcg(12,20,1) | lcg(12,20,1) | `minimumEdgeCover()` | [5, 9, 10, 11, 13, 16] {3–10, 7–1, 2–6, 9–8, 0–5, 11–4} | size = NetworkX min_edge_cover; size n - nu = 12 - 6 |
| CV-185 | MinimumEC | Kb(2,3) | Kb(2,3) | `minimumEdgeCover(matching: g.maximumBipartiteMatching())` | [0, 2, 4] {0–2, 0–4, 1–3} | = NetworkX bipartite.min_edge_cover (Hopcroft-Karp, same left); size n - nu |
| CV-186 | MinimumEC | L [0,1,2]; R [3,4,5] | L [0, 1, 2]; R [3, 4, 5]; E [0-3, 1-3, 1-4, 2-4, 2-5] | `minimumEdgeCover(matching: g.maximumBipartiteMatching())` | [0, 2, 4] {0–3, 1–4, 2–5} | = NetworkX bipartite.min_edge_cover (Hopcroft-Karp, same left); size n - nu |
| CV-187 | MinimumEC | isolated right vertex: nil | L [0]; R [1, 2]; E [0-1] | `minimumEdgeCover(matching: g.maximumBipartiteMatching())` | nil | a vertex has no edge |
| CV-188 | MinimumEC | lcgb(6,7,15,4) | lcgb(6,7,15,4) | `minimumEdgeCover(matching: g.maximumBipartiteMatching())` | [0, 1, 2, 3, 7, 11, 12] {2–12, 4–7, 5–10, 1–11, 0–9, 3–6, 1–8} | = NetworkX bipartite.min_edge_cover (Hopcroft-Karp, same left); size n - nu |
| CV-189 | Checks | empty set covers an edgeless graph | V [0, 1]; E [] | `isVertexCover([])` | true | definition |
| CV-190 | Checks | one end covers | V [0, 1]; E [0-1] | `isVertexCover([1])` | true | definition |
| CV-191 | Checks | loop needs its vertex | V [0, 1]; E [0-0, 0-1] | `isVertexCover([1])` | false | definition |
| CV-192 | Checks | loop covered | V [0, 1]; E [0-0, 0-1] | `isVertexCover([0])` | true | definition |
| CV-193 | Checks | repeats are fine | P(3) | `isVertexCover([1, 1])` | true | definition |
| CV-194 | Checks | C(4) alternate | C(4) | `isVertexCover([0, 2])` | true | definition |
| CV-195 | Checks | C(4) adjacent pair misses an edge | C(4) | `isVertexCover([0, 1])` | false | definition |
| CV-196 | Checks | empty set | K(3) | `isIndependentSet([])` | true | definition; = igraph is_independent_vertex_set |
| CV-197 | Checks | adjacent | K(3) | `isIndependentSet([0, 1])` | false | definition; = igraph is_independent_vertex_set |
| CV-198 | Checks | looped vertex is not independent | V [0, 1]; E [0-0, 0-1] | `isIndependentSet([0])` | false | definition; igraph ignores self-loops and says True |
| CV-199 | Checks | other vertex | V [0, 1]; E [0-0, 0-1] | `isIndependentSet([1])` | true | definition; = igraph is_independent_vertex_set |
| CV-200 | Checks | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `isIndependentSet([0, 2])` | true | definition; = igraph is_independent_vertex_set |
| CV-201 | Checks | repeats are fine | P(3) | `isIndependentSet([0, 0, 2])` | true | definition; = igraph is_independent_vertex_set |
| CV-202 | Checks | empty graph, empty set | V []; E [] | `isDominatingSet([])` | true | = NetworkX is_dominating_set |
| CV-203 | Checks | isolated vertex must be in | V [0, 1]; E [] | `isDominatingSet([0])` | false | = NetworkX is_dominating_set |
| CV-204 | Checks | hub dominates | star(4) | `isDominatingSet([0])` | true | = NetworkX is_dominating_set |
| CV-205 | Checks | leaf does not | star(4) | `isDominatingSet([1])` | false | = NetworkX is_dominating_set |
| CV-206 | Checks | self-loop irrelevant | V [0]; E [0-0] | `isDominatingSet([0])` | true | = NetworkX is_dominating_set |
| CV-207 | Checks | Petersen {0,2,6}? | nx(petersen_graph) | `isDominatingSet([0, 2, 6])` | true | = NetworkX is_dominating_set |
| CV-208 | Checks | empty graph | V []; E [] | `isEdgeCover([])` | true | = NetworkX is_edge_cover |
| CV-209 | Checks | one edge | V [0, 1]; E [0-1] | `isEdgeCover([0])` | true | = NetworkX is_edge_cover |
| CV-210 | Checks | P(3) one edge misses | P(3) | `isEdgeCover([0])` | false | = NetworkX is_edge_cover |
| CV-211 | Checks | loop covers its vertex | V [0]; E [0-0] | `isEdgeCover([0])` | true | = NetworkX is_edge_cover |
| CV-212 | Checks | parallel copy | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `isEdgeCover([1, 2])` | true | definition |
| CV-213 | Traps | negative vertex weight | V [0, 1]; E [0-1]; w [-1, 2] | `approximateMinimumVertexCover(weight:)` | trap | precondition: weights >= 0 (the 2-approximation needs it) |
| CV-214 | Traps | NaN weight | V [0, 1]; E [0-1]; w [nan, 1] | `approximateMinimumVertexCover(weight:)` | trap | precondition: no weight is NaN |
| CV-215 | Traps | negative weight, dominating | V [0]; E []; w [-1] | `approximateMinimumDominatingSet(weight:)` | trap | precondition: weights >= 0 |
| CV-216 | Traps | seed not a vertex | P(3) | `maximalIndependentSet(containing: [9])` | trap | precondition: every seed is a vertex |
| CV-217 | Traps | check with a non-vertex | P(3) | `isVertexCover([9])` | trap | precondition: every element is a vertex |
| CV-218 | Traps | check with a non-position | P(3) | `isEdgeCover([7])` | trap | precondition: every element is a position of edges |
| CV-219 | Traps | matching from another graph | P(3) | `minimumEdgeCover(matching: P(5).maximumMatching())` | trap | precondition: matching.edges are positions of this graph (vertex count checked) |
| CV-220 | Traps | bipartition of another graph | P(4) | `minimumVertexCover(bipartition: P(5).bipartition()!)` | trap | precondition: the bipartition's vertex count is this graph's |
