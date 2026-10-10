# ColoringModule: case catalog (CO-001 – CO-281, 281 cases)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
rustworkx python3 ref.py`; `--write` regenerates this file, `--stress` adds 1,500 random graphs and
300 bipartite multigraphs). Expected is the API's documented output (api.md, Determinism); the last
column says what each row was checked against.

## Notation

* **Graphs.** `V [..]; E [..]`: vertices in order (their vertex indices), then edges at positions
  0, 1, …, each `u-v`. Rows list edge ends in position order (an `UndirectedAdjacencyList` built
  by inserting `E` in order; a self-loop twice). `multigraph` rows have parallel edges (tests need
  an in-file `Graph` conformer). `L [..]; R [..]; E [..]` is a `BipartiteGraph(left:right:edges:)`.
* **Generators.** `K(n)` every pair i < j lexicographic; `C(n)` edges i–(i+1) mod n; `P(n)` the
  path; `star(k)` hub 0, edges 0–i; `wheel(k)` hub 0, spokes 0–i then rim i–(i mod k + 1);
  `Kb(a,b)` the `BipartiteGraph` with left 0..<a, right a..<a+b, edges row-major; `crown(k)`:
  `Kb(k,k)` without the edges i–(k+i), row-major, as a `BipartiteGraph`; `crownx(k)`: the crown
  numbered u_i = 2i, w_i = 2i+1, edges 2i–(2j+1) for i ≠ j row-major, an
  `UndirectedAdjacencyList`; `grid(r,c)` vertex i·c+j, edges right then down, row-major;
  `queen(n)`: square i·n+j, an edge between squares on one row, column or diagonal, pairs a < b
  lexicographic; `nx(name[,arg])` NetworkX's `name(arg)` nodes and `edges()` in order.
  `lcg(n,m,seed)`: a 64-bit LCG, x ← x·6364136223846793005 + 1442695040888963407 (mod 2⁶⁴), each
  draw x >> 33; an edge is two draws (u = d % n, v = d % n), skipped when u = v or the pair is
  already an edge, until m edges. `lcgb(l,r,m,seed)`: a `BipartiteGraph`, left 0..<l, right
  l..<l+r, an edge u = d % l, v = l + d % r, repeats skipped.
* **Colourings.** `colors [..]; k colors`: the colour of each vertex in `vertices` order
  (`coloring.color(of:)`), then `colorCount`. Colour classes follow: class c is the vertices of
  colour c in `vertices` order. Edge colourings list the colour of each edge in position order.
* **Orders** in the Checked column are vertex indices.
* **trap** rows are preconditions: tests run them as exit tests (`#expect(processExitsWith:)`).
* **`minimumColoring()`** rows (after CO-253) repeat the graphs of CO-167 – CO-194. Its colouring
  is whichever optimal one the exact search finds, renumbered by first appearance, so Expected
  gives the colours only where they are forced (no edges; bipartite, the sides; or the only
  χ-colouring so numbered, by exhaustive search on at most 12 vertices), and otherwise
  χ and the rule: proper, χ colours, the first vertex colour 0 and each colour first used after
  the one below it.

| ID | Group | Case | Input | Call | Expected | Checked |
|---|---|---|---|---|---|---|
| CO-001 | Greedy.largestFirst | empty graph | V []; E [] | `greedyColoring(strategy: .largestFirst)` | colors []; 0 colors | = NetworkX greedy_color largest_first |
| CO-002 | Greedy.smallestLast | empty graph | V []; E [] | `greedyColoring(strategy: .smallestLast)` | colors []; 0 colors | = NetworkX greedy_color smallest_last; order [] is smallest-last; <= degeneracy + 1 = 1 |
| CO-003 | Greedy.saturationLargestFirst | empty graph | V []; E [] | `greedyColoring(strategy: .saturationLargestFirst)` | colors []; 0 colors | = NetworkX greedy_color saturation_largest_first; order [] |
| CO-004 | Greedy.independentSet | empty graph | V []; E [] | `greedyColoring(strategy: .independentSet)` | colors []; 0 colors | = NetworkX greedy_color independent_set |
| CO-005 | Greedy.connectedSequentialBreadthFirst | empty graph | V []; E [] | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors []; 0 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-006 | Greedy.connectedSequentialDepthFirst | empty graph | V []; E [] | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors []; 0 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-007 | Greedy.largestFirst | one vertex | V [0]; E [] | `greedyColoring(strategy: .largestFirst)` | colors [0]; 1 colors | = NetworkX greedy_color largest_first; order [0] |
| CO-008 | Greedy.smallestLast | one vertex | V [0]; E [] | `greedyColoring(strategy: .smallestLast)` | colors [0]; 1 colors | = NetworkX greedy_color smallest_last; order [0] is smallest-last; <= degeneracy + 1 = 1 |
| CO-009 | Greedy.saturationLargestFirst | one vertex | V [0]; E [] | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0]; 1 colors | = NetworkX greedy_color saturation_largest_first; order [0] |
| CO-010 | Greedy.independentSet | one vertex | V [0]; E [] | `greedyColoring(strategy: .independentSet)` | colors [0]; 1 colors | = NetworkX greedy_color independent_set |
| CO-011 | Greedy.connectedSequentialBreadthFirst | one vertex | V [0]; E [] | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0]; 1 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-012 | Greedy.connectedSequentialDepthFirst | one vertex | V [0]; E [] | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0]; 1 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-013 | Greedy.largestFirst | one vertex with a self-loop: loop ignored | V [0]; E [0-0] | `greedyColoring(strategy: .largestFirst)` | colors [0]; 1 colors | = NetworkX greedy_color largest_first; order [0] |
| CO-014 | Greedy.saturationLargestFirst | one vertex with a self-loop: loop ignored | V [0]; E [0-0] | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0]; 1 colors | = NetworkX greedy_color saturation_largest_first; order [0] |
| CO-015 | Greedy.smallestLast | one vertex with a self-loop: loop ignored | V [0]; E [0-0] | `greedyColoring(strategy: .smallestLast)` | colors [0]; 1 colors | NetworkX smallest_last raises KeyError (a self-loop breaks its degree buckets); order [0] is smallest-last; <= degeneracy + 1 = 1 |
| CO-016 | Greedy.largestFirst | two isolated vertices | V [0, 1]; E [] | `greedyColoring(strategy: .largestFirst)` | colors [0, 0]; 1 colors | = NetworkX greedy_color largest_first; order [0, 1] |
| CO-017 | Greedy.largestFirst | one edge | V [0, 1]; E [0-1] | `greedyColoring(strategy: .largestFirst)` | colors [0, 1]; 2 colors | = NetworkX greedy_color largest_first; order [0, 1] |
| CO-018 | Greedy.largestFirst | parallel edges count once (degree 1 at 0) | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `greedyColoring(strategy: .largestFirst)` | colors [1, 0, 1]; 2 colors | = NetworkX greedy_color largest_first; order [1, 0, 2] |
| CO-019 | Greedy.saturationLargestFirst | two isolated vertices | V [0, 1]; E [] | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 0]; 1 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1] |
| CO-020 | Greedy.saturationLargestFirst | one edge | V [0, 1]; E [0-1] | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1]; 2 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1] |
| CO-021 | Greedy.saturationLargestFirst | parallel edges count once (degree 1 at 0) | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `greedyColoring(strategy: .saturationLargestFirst)` | colors [1, 0, 1]; 2 colors | = NetworkX greedy_color saturation_largest_first; order [1, 0, 2] |
| CO-022 | Greedy.largestFirst | self-loops ignored; also in the degree that orders | V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2] | `greedyColoring(strategy: .largestFirst)` | colors [1, 2, 0, 1]; 3 colors | NetworkX largest_first gives [2, 0, 1, 0] (NetworkX's degree counts the loop twice); order [2, 0, 1, 3] |
| CO-023 | Greedy.saturationLargestFirst | self-loops ignored; also in the degree that orders | V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2] | `greedyColoring(strategy: .saturationLargestFirst)` | colors [1, 2, 0, 1]; 3 colors | NetworkX saturation_largest_first gives [2, 0, 1, 0] (NetworkX's degree counts the loop twice); order [2, 0, 1, 3] |
| CO-024 | Greedy.independentSet | self-loops ignored; also in the degree that orders | V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2] | `greedyColoring(strategy: .independentSet)` | colors [0, 1, 2, 0]; 3 colors | NetworkX independent_set gives [0, 2, 1, 0] (NetworkX's degree counts the loop twice) |
| CO-025 | Greedy.connectedSequentialBreadthFirst | self-loops ignored; also in the degree that orders | V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2] | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 1, 2, 0]; 3 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-026 | Greedy.largestFirst | triangle | K(3) | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 2]; 3 colors | = NetworkX greedy_color largest_first; order [0, 1, 2] |
| CO-027 | Greedy.largestFirst | K(5) | K(5) | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 2, 3, 4]; 5 colors | = NetworkX greedy_color largest_first; order [0, 1, 2, 3, 4] |
| CO-028 | Greedy.largestFirst | path P(5) | P(5) | `greedyColoring(strategy: .largestFirst)` | colors [1, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color largest_first; order [1, 2, 3, 0, 4] |
| CO-029 | Greedy.largestFirst | cycle C(5) | C(5) | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 0, 1, 2]; 3 colors | = NetworkX greedy_color largest_first; order [0, 1, 2, 3, 4] |
| CO-030 | Greedy.largestFirst | cycle C(6) | C(6) | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color largest_first; order [0, 1, 2, 3, 4, 5] |
| CO-031 | Greedy.largestFirst | star(4): hub first | star(4) | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 1, 1, 1]; 2 colors | = NetworkX greedy_color largest_first; order [0, 1, 2, 3, 4] |
| CO-032 | Greedy.largestFirst | wheel(5) | wheel(5) | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 2, 1, 2, 3]; 4 colors | = NetworkX greedy_color largest_first; order [0, 1, 2, 3, 4, 5] |
| CO-033 | Greedy.largestFirst | wheel(6) | wheel(6) | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 2, 1, 2, 1, 2]; 3 colors | = NetworkX greedy_color largest_first; order [0, 1, 2, 3, 4, 5, 6] |
| CO-034 | Greedy.largestFirst | Petersen | nx(petersen_graph) | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]; 3 colors | = NetworkX greedy_color largest_first; order [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] |
| CO-035 | Greedy.largestFirst | grid(3,4) | grid(3,4) | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color largest_first; order [5, 6, 1, 2, 4, 7, 9, 10, 0, 3, 8, 11] |
| CO-036 | Greedy.largestFirst | Kb(2,3) | Kb(2,3) | `greedyColoring(strategy: .largestFirst)` | colors [0, 0, 1, 1, 1]; 2 colors | = NetworkX greedy_color largest_first; order [0, 1, 2, 3, 4] |
| CO-037 | Greedy.largestFirst | crown(4) | crown(4) | `greedyColoring(strategy: .largestFirst)` | colors [0, 0, 0, 0, 1, 1, 1, 1]; 2 colors | = NetworkX greedy_color largest_first; order [0, 1, 2, 3, 4, 5, 6, 7] |
| CO-038 | Greedy.largestFirst | crownx(4): index order pairs the crown, 4 colours | crownx(4) | `greedyColoring(strategy: .largestFirst)` | colors [0, 0, 1, 1, 2, 2, 3, 3]; 4 colors | = NetworkX greedy_color largest_first; order [0, 1, 2, 3, 4, 5, 6, 7] |
| CO-039 | Greedy.largestFirst | vertex order, not label order | V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c] | `greedyColoring(strategy: .largestFirst)` | colors [0, 2, 1, 2]; 3 colors | = NetworkX greedy_color largest_first; order [0, 2, 1, 3] |
| CO-040 | Greedy.largestFirst | ties: equal degrees keep vertex order | V [0, 1, 2, 3, 4, 5]; E [5-4, 3-2, 1-0, 0-5] | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color largest_first; order [0, 5, 1, 2, 3, 4] |
| CO-041 | Greedy.largestFirst | nx(bull_graph) | nx(bull_graph) | `greedyColoring(strategy: .largestFirst)` | colors [2, 0, 1, 1, 0]; 3 colors | = NetworkX greedy_color largest_first; order [1, 2, 0, 3, 4] |
| CO-042 | Greedy.largestFirst | nx(house_x_graph) | nx(house_x_graph) | `greedyColoring(strategy: .largestFirst)` | colors [2, 3, 0, 1, 2]; 4 colors | = NetworkX greedy_color largest_first; order [2, 3, 0, 1, 4] |
| CO-043 | Greedy.largestFirst | nx(krackhardt_kite_graph) | nx(krackhardt_kite_graph) | `greedyColoring(strategy: .largestFirst)` | colors [2, 1, 3, 0, 3, 1, 2, 0, 1, 0]; 4 colors | = NetworkX greedy_color largest_first; order [3, 5, 6, 0, 1, 2, 4, 7, 8, 9] |
| CO-044 | Greedy.largestFirst | nx(karate_club_graph) | nx(karate_club_graph) | `greedyColoring(strategy: .largestFirst)` | colors [0, 1, 2, 3, 1, 1, 2, 4, 3, 1, 2, 1, 1, 4, 2, 2, 0, 2, 2, 2, 2, 2, 2, 2, 0, 1, 1, 1, 1, 3, 2, 2, 1, 0]; 5 colors | = NetworkX greedy_color largest_first; order [33, 0, 32, 2, 1, 3, 31, 8, 13, 23, 5, 6, 7, 27, 29, 30, 4, 10, 19, 24, 25, 28, 9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26, 11] |
| CO-045 | Greedy.largestFirst | nx(florentine_families_graph): string vertices | nx(florentine_families_graph) | `greedyColoring(strategy: .largestFirst)` | colors [1, 0, 1, 2, 0, 2, 1, 2, 1, 1, 0, 1, 0, 0, 1]; 3 colors | = NetworkX greedy_color largest_first; order [1, 4, 12, 2, 3, 6, 7, 8, 11, 5, 9, 0, 10, 13, 14] |
| CO-046 | Greedy.largestFirst | lcg(12,24,1) | lcg(12,24,1) | `greedyColoring(strategy: .largestFirst)` | colors [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2]; 4 colors | = NetworkX greedy_color largest_first; order [10, 6, 9, 2, 4, 0, 8, 1, 7, 11, 3, 5] |
| CO-047 | Greedy.largestFirst | lcg(20,50,7) | lcg(20,50,7) | `greedyColoring(strategy: .largestFirst)` | colors [2, 3, 0, 1, 0, 0, 2, 1, 1, 2, 0, 1, 1, 2, 3, 2, 0, 0, 2, 1]; 4 colors | = NetworkX greedy_color largest_first; order [5, 12, 10, 18, 8, 14, 16, 0, 3, 6, 13, 15, 1, 7, 17, 19, 4, 11, 2, 9] |
| CO-048 | Greedy.largestFirst | lcg(30,90,3) | lcg(30,90,3) | `greedyColoring(strategy: .largestFirst)` | colors [0, 0, 1, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 1, 2, 3, 0, 4, 2, 1, 1]; 5 colors | = NetworkX greedy_color largest_first; order [6, 19, 11, 15, 18, 25, 29, 5, 16, 17, 23, 24, 7, 9, 26, 0, 8, 13, 14, 21, 27, 2, 3, 12, 20, 28, 10, 22, 1, 4] |
| CO-049 | Greedy.smallestLast | triangle | K(3) | `greedyColoring(strategy: .smallestLast)` | colors [2, 1, 0]; 3 colors | = NetworkX greedy_color smallest_last; order [2, 1, 0] is smallest-last; <= degeneracy + 1 = 3 |
| CO-050 | Greedy.smallestLast | path P(5) | P(5) | `greedyColoring(strategy: .smallestLast)` | colors [0, 1, 0, 1, 0]; 2 colors | = NetworkX greedy_color smallest_last; order [4, 3, 2, 1, 0] is smallest-last; <= degeneracy + 1 = 2 |
| CO-051 | Greedy.smallestLast | cycle C(6) | C(6) | `greedyColoring(strategy: .smallestLast)` | colors [1, 0, 1, 0, 1, 0]; 2 colors | = NetworkX greedy_color smallest_last; order [5, 4, 3, 2, 1, 0] is smallest-last; <= degeneracy + 1 = 3 |
| CO-052 | Greedy.smallestLast | star(4) | star(4) | `greedyColoring(strategy: .smallestLast)` | colors [1, 0, 0, 0, 0]; 2 colors | NetworkX smallest_last gives [0, 1, 1, 1, 1] (NetworkX iterates a Python set); order [4, 0, 3, 2, 1] is smallest-last; <= degeneracy + 1 = 2 |
| CO-053 | Greedy.smallestLast | wheel(5) | wheel(5) | `greedyColoring(strategy: .smallestLast)` | colors [2, 3, 1, 0, 1, 0]; 4 colors | NetworkX smallest_last gives [1, 3, 2, 0, 2, 0] (NetworkX iterates a Python set); order [5, 4, 0, 3, 2, 1] is smallest-last; <= degeneracy + 1 = 4 |
| CO-054 | Greedy.smallestLast | Petersen | nx(petersen_graph) | `greedyColoring(strategy: .smallestLast)` | colors [0, 2, 0, 2, 1, 2, 1, 1, 0, 0]; 3 colors | = NetworkX greedy_color smallest_last; order [9, 6, 8, 7, 5, 4, 3, 2, 1, 0] is smallest-last; <= degeneracy + 1 = 4 |
| CO-055 | Greedy.smallestLast | grid(3,4) | grid(3,4) | `greedyColoring(strategy: .smallestLast)` | colors [1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0]; 2 colors | NetworkX smallest_last gives [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1] (NetworkX iterates a Python set); order [11, 10, 7, 6, 9, 5, 8, 4, 3, 2, 1, 0] is smallest-last; <= degeneracy + 1 = 3 |
| CO-056 | Greedy.smallestLast | crown(4) | crown(4) | `greedyColoring(strategy: .smallestLast)` | colors [1, 1, 1, 1, 0, 0, 0, 0]; 2 colors | = NetworkX greedy_color smallest_last; order [6, 3, 4, 1, 7, 2, 5, 0] is smallest-last; <= degeneracy + 1 = 4 |
| CO-057 | Greedy.smallestLast | crownx(4) | crownx(4) | `greedyColoring(strategy: .smallestLast)` | colors [0, 1, 0, 1, 0, 1, 0, 1]; 2 colors | NetworkX smallest_last gives [1, 0, 1, 0, 1, 0, 1, 0] (NetworkX iterates a Python set); order [6, 5, 2, 1, 7, 4, 3, 0] is smallest-last; <= degeneracy + 1 = 4 |
| CO-058 | Greedy.smallestLast | nx(bull_graph) | nx(bull_graph) | `greedyColoring(strategy: .smallestLast)` | colors [2, 1, 0, 0, 1]; 3 colors | = NetworkX greedy_color smallest_last; order [2, 1, 0, 4, 3] is smallest-last; <= degeneracy + 1 = 3 |
| CO-059 | Greedy.smallestLast | nx(dodecahedral_graph) | nx(dodecahedral_graph) | `greedyColoring(strategy: .smallestLast)` | colors [3, 2, 1, 2, 0, 2, 0, 1, 0, 2, 0, 1, 2, 1, 0, 1, 0, 1, 0, 1]; 4 colors | NetworkX smallest_last gives [2, 0, 2, 1, 0, 1, 0, 1, 2, 0, 1, 0, 2, 1, 0, 2, 0, 2, 1, 0] (NetworkX iterates a Python set); order [16, 15, 14, 13, 12, 17, 18, 11, 10, 9, 8, 7, 6, 5, 4, 19, 3, 2, 1, 0] is smallest-last; <= degeneracy + 1 = 4 |
| CO-060 | Greedy.smallestLast | nx(karate_club_graph) | nx(karate_club_graph) | `greedyColoring(strategy: .smallestLast)` | colors [2, 3, 0, 4, 1, 1, 0, 1, 3, 1, 0, 0, 0, 1, 2, 2, 2, 0, 2, 1, 2, 0, 2, 3, 2, 0, 1, 1, 1, 2, 2, 3, 1, 0]; 5 colors | NetworkX smallest_last gives [3, 2, 1, 0, 1, 1, 0, 4, 0, 0, 0, 0, 1, 4, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 3, 3, 1, 1, 0, 3, 2] (NetworkX iterates a Python set); order [33, 32, 30, 8, 2, 13, 1, 0, 3, 7, 31, 28, 29, 23, 27, 25, 24, 19, 10, 5, 6, 4, 26, 22, 21, 20, 18, 17, 16, 15, 14, 12, 9, 11] is smallest-last; <= degeneracy + 1 = 5 |
| CO-061 | Greedy.smallestLast | lcg(12,24,1) | lcg(12,24,1) | `greedyColoring(strategy: .smallestLast)` | colors [0, 3, 3, 1, 0, 1, 2, 1, 2, 1, 0, 1]; 4 colors | NetworkX smallest_last gives [1, 1, 1, 0, 3, 0, 0, 0, 0, 2, 3, 1] (NetworkX iterates a Python set); order [10, 9, 6, 2, 4, 11, 8, 7, 1, 0, 5, 3] is smallest-last; <= degeneracy + 1 = 4 |
| CO-062 | Greedy.smallestLast | lcg(20,50,7) | lcg(20,50,7) | `greedyColoring(strategy: .smallestLast)` | colors [4, 1, 2, 3, 0, 0, 1, 3, 1, 0, 2, 2, 2, 1, 1, 1, 0, 0, 0, 2]; 5 colors | NetworkX smallest_last gives [4, 0, 1, 3, 1, 1, 0, 3, 0, 0, 2, 2, 2, 0, 0, 0, 1, 1, 1, 2] (NetworkX iterates a Python set); order [18, 14, 12, 17, 10, 8, 5, 15, 16, 13, 19, 6, 3, 0, 11, 7, 4, 1, 9, 2] is smallest-last; <= degeneracy + 1 = 5 |
| CO-063 | Greedy.smallestLast | lcg(30,90,3) | lcg(30,90,3) | `greedyColoring(strategy: .smallestLast)` | colors [1, 1, 1, 2, 0, 2, 3, 1, 1, 2, 2, 2, 1, 3, 3, 2, 3, 0, 1, 0, 2, 0, 3, 0, 1, 0, 0, 3, 4, 1]; 5 colors | NetworkX smallest_last gives [3, 1, 0, 1, 2, 1, 2, 2, 3, 1, 1, 1, 1, 3, 0, 1, 2, 0, 3, 0, 3, 0, 2, 1, 3, 0, 0, 3, 0, 2] (NetworkX iterates a Python set); order [25, 24, 11, 19, 7, 9, 6, 26, 15, 29, 23, 14, 18, 16, 5, 28, 8, 17, 13, 27, 0, 22, 21, 12, 20, 10, 3, 2, 4, 1] is smallest-last; <= degeneracy + 1 = 5 |
| CO-064 | Greedy.smallestLast | planar: nx(icosahedral_graph), <= 6 colours | nx(icosahedral_graph) | `greedyColoring(strategy: .smallestLast)` | colors [4, 2, 1, 3, 2, 1, 2, 3, 0, 1, 0, 0]; 5 colors | NetworkX smallest_last gives [1, 2, 3, 0, 2, 3, 3, 0, 2, 1, 0, 1] (NetworkX iterates a Python set); order [10, 9, 6, 8, 4, 3, 11, 2, 7, 5, 1, 0] is smallest-last; <= degeneracy + 1 = 6 |
| CO-065 | Greedy.saturationLargestFirst | triangle | K(3) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 2]; 3 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1, 2] |
| CO-066 | Greedy.saturationLargestFirst | K(5) | K(5) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 2, 3, 4]; 5 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1, 2, 3, 4] |
| CO-067 | Greedy.saturationLargestFirst | path P(5) | P(5) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [1, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color saturation_largest_first; order [1, 2, 3, 0, 4] |
| CO-068 | Greedy.saturationLargestFirst | cycle C(5) | C(5) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 0, 1, 2]; 3 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1, 2, 3, 4] |
| CO-069 | Greedy.saturationLargestFirst | cycle C(7) | C(7) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 0, 1, 0, 1, 2]; 3 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1, 2, 3, 4, 5, 6] |
| CO-070 | Greedy.saturationLargestFirst | star(4) | star(4) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 1, 1, 1]; 2 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1, 2, 3, 4] |
| CO-071 | Greedy.saturationLargestFirst | wheel(5) | wheel(5) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 2, 1, 2, 3]; 4 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1, 2, 3, 4, 5] |
| CO-072 | Greedy.saturationLargestFirst | wheel(6) | wheel(6) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 2, 1, 2, 1, 2]; 3 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1, 2, 3, 4, 5, 6] |
| CO-073 | Greedy.saturationLargestFirst | Petersen | nx(petersen_graph) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]; 3 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1, 2, 3, 4, 5, 7, 6, 8, 9] |
| CO-074 | Greedy.saturationLargestFirst | grid(3,4) | grid(3,4) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color saturation_largest_first; order [5, 6, 1, 2, 4, 7, 9, 10, 0, 3, 8, 11] |
| CO-075 | Greedy.saturationLargestFirst | crown(4) | crown(4) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 0, 0, 0, 1, 1, 1, 1]; 2 colors | = NetworkX greedy_color saturation_largest_first; order [0, 5, 2, 3, 4, 1, 6, 7] |
| CO-076 | Greedy.saturationLargestFirst | crownx(5): DSatur is exact on bipartite graphs | crownx(5) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color saturation_largest_first; order [0, 3, 4, 1, 2, 5, 6, 7, 8, 9] |
| CO-077 | Greedy.saturationLargestFirst | vertex order, not label order | V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c] | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 2, 1, 2]; 3 colors | = NetworkX greedy_color saturation_largest_first; order [0, 2, 1, 3] |
| CO-078 | Greedy.saturationLargestFirst | nx(bull_graph) | nx(bull_graph) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [2, 0, 1, 1, 0]; 3 colors | = NetworkX greedy_color saturation_largest_first; order [1, 2, 0, 3, 4] |
| CO-079 | Greedy.saturationLargestFirst | nx(house_x_graph) | nx(house_x_graph) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [2, 3, 0, 1, 2]; 4 colors | = NetworkX greedy_color saturation_largest_first; order [2, 3, 0, 1, 4] |
| CO-080 | Greedy.saturationLargestFirst | nx(dodecahedral_graph) | nx(dodecahedral_graph) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2]; 3 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1, 2, 3, 19, 4, 5, 6, 7, 8, 9, 10, 11, 18, 17, 12, 13, 14, 16, 15] |
| CO-081 | Greedy.saturationLargestFirst | nx(chvatal_graph) | nx(chvatal_graph) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3]; 4 colors | = NetworkX greedy_color saturation_largest_first; order [0, 1, 2, 3, 4, 5, 8, 9, 10, 6, 11, 7] |
| CO-082 | Greedy.saturationLargestFirst | nx(mycielski_graph,4): Groetzsch | nx(mycielski_graph,4) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [1, 0, 1, 2, 0, 1, 2, 1, 2, 3, 0]; 4 colors | = NetworkX greedy_color saturation_largest_first; order [10, 5, 1, 0, 6, 2, 8, 4, 3, 9, 7] |
| CO-083 | Greedy.saturationLargestFirst | nx(karate_club_graph) | nx(karate_club_graph) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [1, 2, 0, 3, 0, 0, 2, 4, 2, 1, 2, 0, 0, 4, 2, 2, 1, 0, 2, 3, 2, 0, 2, 2, 0, 1, 1, 1, 1, 3, 3, 2, 1, 0]; 5 colors | = NetworkX greedy_color saturation_largest_first; order [33, 32, 31, 8, 30, 2, 0, 1, 3, 13, 7, 19, 23, 29, 27, 24, 25, 28, 12, 14, 15, 17, 18, 20, 21, 22, 26, 5, 6, 4, 10, 16, 9, 11] |
| CO-084 | Greedy.saturationLargestFirst | two components: saturation 0 restarts at the greatest degree | V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 1-2, 3-4, 3-5, 3-6] | `greedyColoring(strategy: .saturationLargestFirst)` | colors [1, 0, 1, 0, 1, 1, 1]; 2 colors | = NetworkX greedy_color saturation_largest_first; order [3, 4, 5, 6, 1, 0, 2] |
| CO-085 | Greedy.saturationLargestFirst | lcg(12,24,1) | lcg(12,24,1) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 2, 3, 1, 0, 1, 1, 1, 1, 2, 0, 2]; 4 colors | = NetworkX greedy_color saturation_largest_first; order [10, 6, 9, 2, 4, 0, 8, 1, 7, 11, 3, 5] |
| CO-086 | Greedy.saturationLargestFirst | lcg(20,50,7) | lcg(20,50,7) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [3, 1, 0, 2, 0, 0, 3, 2, 2, 1, 1, 1, 1, 2, 2, 2, 0, 0, 0, 1]; 4 colors | = NetworkX greedy_color saturation_largest_first; order [5, 12, 14, 18, 10, 8, 0, 3, 16, 6, 7, 13, 19, 15, 1, 17, 4, 11, 2, 9] |
| CO-087 | Greedy.saturationLargestFirst | lcg(30,90,3) | lcg(30,90,3) | `greedyColoring(strategy: .saturationLargestFirst)` | colors [0, 0, 3, 1, 0, 3, 0, 3, 2, 2, 2, 2, 3, 2, 0, 0, 1, 1, 2, 1, 2, 0, 2, 2, 3, 0, 1, 1, 1, 3]; 4 colors | = NetworkX greedy_color saturation_largest_first; order [6, 19, 11, 24, 15, 18, 25, 5, 16, 7, 9, 26, 29, 13, 28, 23, 17, 12, 20, 0, 8, 14, 21, 10, 27, 2, 22, 1, 3, 4] |
| CO-088 | Greedy.independentSet | triangle | K(3) | `greedyColoring(strategy: .independentSet)` | colors [0, 1, 2]; 3 colors | = NetworkX greedy_color independent_set |
| CO-089 | Greedy.independentSet | path P(5) | P(5) | `greedyColoring(strategy: .independentSet)` | colors [0, 1, 0, 1, 0]; 2 colors | = NetworkX greedy_color independent_set |
| CO-090 | Greedy.independentSet | cycle C(5) | C(5) | `greedyColoring(strategy: .independentSet)` | colors [0, 1, 0, 1, 2]; 3 colors | = NetworkX greedy_color independent_set |
| CO-091 | Greedy.independentSet | star(4): leaves first | star(4) | `greedyColoring(strategy: .independentSet)` | colors [1, 0, 0, 0, 0]; 2 colors | = NetworkX greedy_color independent_set |
| CO-092 | Greedy.independentSet | wheel(5) | wheel(5) | `greedyColoring(strategy: .independentSet)` | colors [2, 0, 1, 0, 1, 3]; 4 colors | = NetworkX greedy_color independent_set |
| CO-093 | Greedy.independentSet | Petersen | nx(petersen_graph) | `greedyColoring(strategy: .independentSet)` | colors [0, 1, 0, 1, 2, 1, 2, 2, 0, 0]; 3 colors | = NetworkX greedy_color independent_set |
| CO-094 | Greedy.independentSet | grid(3,4) | grid(3,4) | `greedyColoring(strategy: .independentSet)` | colors [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color independent_set |
| CO-095 | Greedy.independentSet | crownx(4) | crownx(4) | `greedyColoring(strategy: .independentSet)` | colors [0, 1, 0, 1, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color independent_set |
| CO-096 | Greedy.independentSet | nx(bull_graph) | nx(bull_graph) | `greedyColoring(strategy: .independentSet)` | colors [0, 1, 2, 0, 0]; 3 colors | = NetworkX greedy_color independent_set |
| CO-097 | Greedy.independentSet | nx(karate_club_graph) | nx(karate_club_graph) | `greedyColoring(strategy: .independentSet)` | colors [3, 2, 4, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 2, 3, 4]; 5 colors | NetworkX independent_set gives [3, 2, 4, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 4, 2, 3] (NetworkX iterates a Python set) |
| CO-098 | Greedy.independentSet | lcg(12,24,1) | lcg(12,24,1) | `greedyColoring(strategy: .independentSet)` | colors [1, 1, 1, 0, 0, 0, 2, 0, 0, 3, 4, 1]; 5 colors | NetworkX independent_set gives [1, 1, 1, 0, 0, 0, 4, 0, 0, 2, 3, 1] (NetworkX iterates a Python set) |
| CO-099 | Greedy.independentSet | lcg(20,50,7) | lcg(20,50,7) | `greedyColoring(strategy: .independentSet)` | colors [1, 1, 0, 0, 0, 2, 1, 0, 0, 1, 2, 0, 0, 1, 1, 1, 2, 2, 3, 0]; 4 colors | NetworkX independent_set gives [1, 1, 0, 0, 0, 2, 1, 0, 0, 1, 2, 0, 0, 1, 4, 1, 2, 1, 3, 0] (NetworkX iterates a Python set) |
| CO-100 | Greedy.connectedSequentialBreadthFirst | path P(5) | P(5) | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 1, 0, 1, 0]; 2 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-101 | Greedy.connectedSequentialDepthFirst | path P(5) | P(5) | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0, 1, 0, 1, 0]; 2 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-102 | Greedy.connectedSequentialBreadthFirst | cycle C(6) | C(6) | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 1, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-103 | Greedy.connectedSequentialDepthFirst | cycle C(6) | C(6) | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0, 1, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-104 | Greedy.connectedSequentialBreadthFirst | star(4) | star(4) | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 1, 1, 1, 1]; 2 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-105 | Greedy.connectedSequentialDepthFirst | star(4) | star(4) | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0, 1, 1, 1, 1]; 2 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-106 | Greedy.connectedSequentialBreadthFirst | Petersen | nx(petersen_graph) | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 1, 0, 2, 1, 1, 0, 3, 3, 2]; 4 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-107 | Greedy.connectedSequentialDepthFirst | Petersen | nx(petersen_graph) | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0, 1, 0, 1, 2, 1, 2, 2, 0, 0]; 3 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-108 | Greedy.connectedSequentialBreadthFirst | grid(3,4) | grid(3,4) | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-109 | Greedy.connectedSequentialDepthFirst | grid(3,4) | grid(3,4) | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-110 | Greedy.connectedSequentialBreadthFirst | crownx(4) | crownx(4) | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 1, 0, 1, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-111 | Greedy.connectedSequentialDepthFirst | crownx(4) | crownx(4) | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0, 1, 0, 1, 0, 1, 0, 1]; 2 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-112 | Greedy.connectedSequentialBreadthFirst | two components, least vertex roots each | V [0, 1, 2, 3, 4, 5, 6]; E [0-4, 4-6, 1-2, 2-3, 3-5, 5-1] | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 0, 1, 0, 1, 1, 0]; 2 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-113 | Greedy.connectedSequentialDepthFirst | two components, least vertex roots each | V [0, 1, 2, 3, 4, 5, 6]; E [0-4, 4-6, 1-2, 2-3, 3-5, 5-1] | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0, 0, 1, 0, 1, 1, 0]; 2 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-114 | Greedy.connectedSequentialBreadthFirst | component {5, 9}-style: root is the least vertex, not a set's first | V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [9-5, 0-1, 1-2, 2-3, 3-4, 6-7, 7-8, 8-6] | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 1, 0, 1, 0, 0, 0, 1, 2, 1]; 3 colors | NetworkX connected_sequential_bfs gives [0, 1, 0, 1, 0, 1, 2, 1, 0, 0] (NetworkX iterates a Python set) |
| CO-115 | Greedy.connectedSequentialDepthFirst | component {5, 9}-style: root is the least vertex, not a set's first | V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [9-5, 0-1, 1-2, 2-3, 3-4, 6-7, 7-8, 8-6] | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0, 1, 0, 1, 0, 0, 0, 1, 2, 1]; 3 colors | NetworkX connected_sequential_dfs gives [0, 1, 0, 1, 0, 1, 2, 1, 0, 0] (NetworkX iterates a Python set) |
| CO-116 | Greedy.connectedSequentialBreadthFirst | lcg(12,24,1) | lcg(12,24,1) | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 0, 0, 0, 3, 1, 1, 1, 1, 2, 3, 0]; 4 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-117 | Greedy.connectedSequentialDepthFirst | lcg(12,24,1) | lcg(12,24,1) | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0, 0, 0, 0, 2, 1, 1, 1, 1, 3, 2, 0]; 4 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-118 | Greedy.connectedSequentialBreadthFirst | lcg(20,50,7) | lcg(20,50,7) | `greedyColoring(strategy: .connectedSequentialBreadthFirst)` | colors [0, 3, 0, 1, 1, 2, 0, 1, 1, 2, 2, 1, 1, 0, 3, 0, 2, 0, 0, 1]; 4 colors | = NetworkX greedy_color connected_sequential_bfs |
| CO-119 | Greedy.connectedSequentialDepthFirst | lcg(20,50,7) | lcg(20,50,7) | `greedyColoring(strategy: .connectedSequentialDepthFirst)` | colors [0, 0, 1, 1, 1, 2, 3, 1, 1, 0, 0, 0, 1, 0, 3, 3, 2, 0, 2, 1]; 4 colors | = NetworkX greedy_color connected_sequential_dfs |
| CO-120 | Greedy.order | empty order on the empty graph | V []; E [] | `greedyColoring(order: [])` | colors []; 0 colors | empty |
| CO-121 | Greedy.order | path in reverse | P(5) | `greedyColoring(order: [4, 3, 2, 1, 0])` | colors [0, 1, 0, 1, 0]; 2 colors | = NetworkX greedy_color with that order as strategy |
| CO-122 | Greedy.order | crown(4) interleaved: the classic n/2-colour trap | crown(4) | `greedyColoring(order: [0, 4, 1, 5, 2, 6, 3, 7])` | colors [0, 1, 2, 3, 0, 1, 2, 3]; 4 colors | = NetworkX greedy_color with that order as strategy |
| CO-123 | Greedy.order | crown(4) sides first: 2 colours | crown(4) | `greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7])` | colors [0, 0, 0, 0, 1, 1, 1, 1]; 2 colors | = NetworkX greedy_color with that order as strategy |
| CO-124 | Greedy.order | labels | V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c] | `greedyColoring(order: [c, b, a, d])` | colors [2, 1, 0, 1]; 3 colors | = NetworkX greedy_color with that order as strategy |
| CO-125 | Greedy.order | Petersen, outer then inner | nx(petersen_graph) | `greedyColoring(order: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])` | colors [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]; 3 colors | = NetworkX greedy_color with that order as strategy |
| CO-126 | Greedy.order | Petersen, inner then outer | nx(petersen_graph) | `greedyColoring(order: [5, 6, 7, 8, 9, 0, 1, 2, 3, 4])` | colors [1, 2, 0, 2, 0, 0, 0, 1, 1, 2]; 3 colors | = NetworkX greedy_color with that order as strategy |
| CO-127 | Greedy.order | self-loop ignored | V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2] | `greedyColoring(order: [3, 2, 1, 0])` | colors [2, 0, 1, 0]; 3 colors | = NetworkX greedy_color with that order as strategy |
| CO-128 | Greedy.order | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `greedyColoring(order: [2, 1, 0])` | colors [0, 1, 0]; 2 colors | = NetworkX greedy_color with that order as strategy |
| CO-129 | ChromaticNumber | empty graph: 0 | V []; E [] | `chromaticNumber()` | 0 | = inclusion-exclusion count |
| CO-130 | ChromaticNumber | one vertex: 1 | V [0]; E [] | `chromaticNumber()` | 1 | = inclusion-exclusion count |
| CO-131 | ChromaticNumber | self-loop ignored: 1 | V [0]; E [0-0] | `chromaticNumber()` | 1 | = inclusion-exclusion count |
| CO-132 | ChromaticNumber | edgeless: 1 | V [0, 1]; E [] | `chromaticNumber()` | 1 | = inclusion-exclusion count |
| CO-133 | ChromaticNumber | one edge: 2 | V [0, 1]; E [0-1] | `chromaticNumber()` | 2 | = inclusion-exclusion count |
| CO-134 | ChromaticNumber | parallel edges: 2 | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `chromaticNumber()` | 2 | = inclusion-exclusion count |
| CO-135 | ChromaticNumber | K(1) | K(1) | `chromaticNumber()` | 1 | = inclusion-exclusion count |
| CO-136 | ChromaticNumber | K(4) | K(4) | `chromaticNumber()` | 4 | = inclusion-exclusion count |
| CO-137 | ChromaticNumber | K(7) | K(7) | `chromaticNumber()` | 7 | = inclusion-exclusion count |
| CO-138 | ChromaticNumber | path P(6) | P(6) | `chromaticNumber()` | 2 | = inclusion-exclusion count |
| CO-139 | ChromaticNumber | cycle C(4) | C(4) | `chromaticNumber()` | 2 | = inclusion-exclusion count |
| CO-140 | ChromaticNumber | cycle C(5) | C(5) | `chromaticNumber()` | 3 | = inclusion-exclusion count |
| CO-141 | ChromaticNumber | cycle C(9) | C(9) | `chromaticNumber()` | 3 | = inclusion-exclusion count |
| CO-142 | ChromaticNumber | wheel(4): even rim, 3 | wheel(4) | `chromaticNumber()` | 3 | = inclusion-exclusion count |
| CO-143 | ChromaticNumber | wheel(5): odd rim, 4 | wheel(5) | `chromaticNumber()` | 4 | = inclusion-exclusion count |
| CO-144 | ChromaticNumber | wheel(8) | wheel(8) | `chromaticNumber()` | 3 | = inclusion-exclusion count |
| CO-145 | ChromaticNumber | Petersen: 3 | nx(petersen_graph) | `chromaticNumber()` | 3 | = inclusion-exclusion count |
| CO-146 | ChromaticNumber | nx(mycielski_graph,3): C5 | nx(mycielski_graph,3) | `chromaticNumber()` | 3 | = inclusion-exclusion count |
| CO-147 | ChromaticNumber | nx(mycielski_graph,4): Groetzsch, triangle-free, 4 | nx(mycielski_graph,4) | `chromaticNumber()` | 4 | = inclusion-exclusion count |
| CO-148 | ChromaticNumber | nx(mycielski_graph,5): 23 vertices, triangle-free, 5 | nx(mycielski_graph,5) | `chromaticNumber()` | 5 | = literature value (clique number 2) |
| CO-149 | ChromaticNumber | nx(chvatal_graph): 4 | nx(chvatal_graph) | `chromaticNumber()` | 4 | = inclusion-exclusion count |
| CO-150 | ChromaticNumber | crown(5): 2 | crown(5) | `chromaticNumber()` | 2 | = inclusion-exclusion count |
| CO-151 | ChromaticNumber | crownx(6): 2 | crownx(6) | `chromaticNumber()` | 2 | = inclusion-exclusion count |
| CO-152 | ChromaticNumber | queen(4) | queen(4) | `chromaticNumber()` | 5 | = inclusion-exclusion count |
| CO-153 | ChromaticNumber | queen(5): 5 | queen(5) | `chromaticNumber()` | 5 | = literature value (clique number 5) |
| CO-154 | ChromaticNumber | queen(6): 7 | queen(6) | `chromaticNumber()` | 7 | = literature value (clique number 6) |
| CO-155 | ChromaticNumber | grid(4,4): 2 | grid(4,4) | `chromaticNumber()` | 2 | = inclusion-exclusion count |
| CO-156 | ChromaticNumber | nx(dodecahedral_graph): 3 | nx(dodecahedral_graph) | `chromaticNumber()` | 3 | certified: not bipartite, and the colouring has 3 |
| CO-157 | ChromaticNumber | nx(icosahedral_graph): 4 | nx(icosahedral_graph) | `chromaticNumber()` | 4 | = inclusion-exclusion count |
| CO-158 | ChromaticNumber | nx(octahedral_graph): 3 | nx(octahedral_graph) | `chromaticNumber()` | 3 | = inclusion-exclusion count |
| CO-159 | ChromaticNumber | nx(heawood_graph): 2 | nx(heawood_graph) | `chromaticNumber()` | 2 | = inclusion-exclusion count |
| CO-160 | ChromaticNumber | nx(frucht_graph): 3 | nx(frucht_graph) | `chromaticNumber()` | 3 | = inclusion-exclusion count |
| CO-161 | ChromaticNumber | nx(karate_club_graph): 5 | nx(karate_club_graph) | `chromaticNumber()` | 5 | certified by a clique of 5 |
| CO-162 | ChromaticNumber | components: max over components | V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0-1, 1-2, 2-0, 3-4, 5-6, 6-7, 7-8, 8-5, 5-7, 6-8] | `chromaticNumber()` | 4 | = inclusion-exclusion count |
| CO-163 | ChromaticNumber | lcg(14,40,5) | lcg(14,40,5) | `chromaticNumber()` | 4 | = inclusion-exclusion count |
| CO-164 | ChromaticNumber | lcg(16,60,9) | lcg(16,60,9) | `chromaticNumber()` | 5 | = inclusion-exclusion count |
| CO-165 | ChromaticNumber | lcg(18,70,2) | lcg(18,70,2) | `chromaticNumber()` | 5 | = inclusion-exclusion count |
| CO-166 | ChromaticNumber | odd cycle with a self-loop: 3 | V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-4, 4-0, 2-2] | `chromaticNumber()` | 3 | = inclusion-exclusion count |
| CO-167 | LexicographicallyFirstMinimumColoring | empty graph | V []; E [] | `lexicographicallyFirstMinimumColoring()` | colors []; 0 colors | per component = brute force; = inclusion-exclusion count |
| CO-168 | LexicographicallyFirstMinimumColoring | one vertex | V [0]; E [] | `lexicographicallyFirstMinimumColoring()` | colors [0]; 1 colors | per component = brute force; = inclusion-exclusion count |
| CO-169 | LexicographicallyFirstMinimumColoring | self-loop ignored | V [0]; E [0-0] | `lexicographicallyFirstMinimumColoring()` | colors [0]; 1 colors | per component = brute force; = inclusion-exclusion count |
| CO-170 | LexicographicallyFirstMinimumColoring | two isolated | V [0, 1]; E [] | `lexicographicallyFirstMinimumColoring()` | colors [0, 0]; 1 colors | per component = brute force; = inclusion-exclusion count |
| CO-171 | LexicographicallyFirstMinimumColoring | one edge | V [0, 1]; E [0-1] | `lexicographicallyFirstMinimumColoring()` | colors [0, 1]; 2 colors | per component = brute force; = inclusion-exclusion count |
| CO-172 | LexicographicallyFirstMinimumColoring | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 0]; 2 colors | per component = brute force; = inclusion-exclusion count |
| CO-173 | LexicographicallyFirstMinimumColoring | triangle | K(3) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 2]; 3 colors | per component = brute force; = inclusion-exclusion count |
| CO-174 | LexicographicallyFirstMinimumColoring | K(5): index order | K(5) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 2, 3, 4]; 5 colors | per component = brute force; = inclusion-exclusion count |
| CO-175 | LexicographicallyFirstMinimumColoring | path P(5): bipartition | P(5) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 0, 1, 0]; 2 colors | per component = brute force; = inclusion-exclusion count |
| CO-176 | LexicographicallyFirstMinimumColoring | cycle C(5) | C(5) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 0, 1, 2]; 3 colors | per component = brute force; = inclusion-exclusion count |
| CO-177 | LexicographicallyFirstMinimumColoring | cycle C(7) | C(7) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 0, 1, 0, 1, 2]; 3 colors | per component = brute force; = inclusion-exclusion count |
| CO-178 | LexicographicallyFirstMinimumColoring | wheel(5) | wheel(5) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 2, 1, 2, 3]; 4 colors | per component = brute force; = inclusion-exclusion count |
| CO-179 | LexicographicallyFirstMinimumColoring | wheel(6) | wheel(6) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 2, 1, 2, 1, 2]; 3 colors | per component = brute force; = inclusion-exclusion count |
| CO-180 | LexicographicallyFirstMinimumColoring | Petersen | nx(petersen_graph) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 0, 1, 2, 1, 0, 2, 2, 1]; 3 colors | per component = brute force; = inclusion-exclusion count |
| CO-181 | LexicographicallyFirstMinimumColoring | crownx(4): 2 colours, where first fit needs 4 | crownx(4) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 0, 1, 0, 1, 0, 1]; 2 colors | per component = brute force; = inclusion-exclusion count |
| CO-182 | LexicographicallyFirstMinimumColoring | first fit not optimal, so the search decides | V [0, 1, 2, 3, 4, 5]; E [0-2, 2-3, 3-1, 1-4, 4-5, 5-0, 2-5] | `lexicographicallyFirstMinimumColoring()` | colors [0, 0, 1, 2, 1, 2]; 3 colors | per component = brute force; = inclusion-exclusion count |
| CO-183 | LexicographicallyFirstMinimumColoring | P4 numbered 0-2-3-1 beside a triangle: each component its own chi | V [0, 1, 2, 3, 4, 5, 6]; E [0-2, 2-3, 3-1, 4-5, 5-6, 6-4] | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 1, 0, 0, 1, 2]; 3 colors | per component = brute force; = inclusion-exclusion count |
| CO-184 | LexicographicallyFirstMinimumColoring | vertex order, not label order | V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c] | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 2, 1]; 3 colors | per component = brute force; = inclusion-exclusion count |
| CO-185 | LexicographicallyFirstMinimumColoring | nx(mycielski_graph,4): Groetzsch | nx(mycielski_graph,4) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3]; 4 colors | per component = brute force; = inclusion-exclusion count |
| CO-186 | LexicographicallyFirstMinimumColoring | nx(chvatal_graph) | nx(chvatal_graph) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3, 3]; 4 colors | per component = brute force; = inclusion-exclusion count |
| CO-187 | LexicographicallyFirstMinimumColoring | queen(5) | queen(5) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 2, 3, 4, 2, 3, 4, 0, 1, 4, 0, 1, 2, 3, 1, 2, 3, 4, 0, 3, 4, 0, 1, 2]; 5 colors | per component = plain index-order backtracking; = literature value (clique number 5) |
| CO-188 | LexicographicallyFirstMinimumColoring | nx(dodecahedral_graph) | nx(dodecahedral_graph) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 0, 1, 0, 1, 2, 0, 2, 0, 1, 0, 1, 2, 1, 2, 0, 2, 1, 2]; 3 colors | per component = plain index-order backtracking; certified: not bipartite, and the colouring has 3 |
| CO-189 | LexicographicallyFirstMinimumColoring | nx(bull_graph) | nx(bull_graph) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 2, 0, 0]; 3 colors | per component = brute force; = inclusion-exclusion count |
| CO-190 | LexicographicallyFirstMinimumColoring | nx(house_x_graph) | nx(house_x_graph) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 2, 3, 0]; 4 colors | per component = brute force; = inclusion-exclusion count |
| CO-191 | LexicographicallyFirstMinimumColoring | lcg(12,24,1) | lcg(12,24,1) | `lexicographicallyFirstMinimumColoring()` | colors [0, 0, 0, 0, 1, 1, 2, 2, 2, 3, 1, 0]; 4 colors | per component = brute force; = inclusion-exclusion count |
| CO-192 | LexicographicallyFirstMinimumColoring | lcg(14,40,5) | lcg(14,40,5) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 1, 1, 2, 3, 3, 3, 0, 0, 0, 3, 3, 2]; 4 colors | per component = plain index-order backtracking; = inclusion-exclusion count |
| CO-193 | LexicographicallyFirstMinimumColoring | lcg(16,60,9) | lcg(16,60,9) | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 1, 2, 0, 2, 1, 2, 3, 4, 4, 0, 3, 2, 1, 0]; 5 colors | per component = plain index-order backtracking; = inclusion-exclusion count |
| CO-194 | LexicographicallyFirstMinimumColoring | self-loops ignored in a bigger graph | V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2] | `lexicographicallyFirstMinimumColoring()` | colors [0, 1, 2, 0]; 3 colors | per component = brute force; = inclusion-exclusion count |
| CO-195 | EdgeColoring | empty graph | V []; E [] | `edgeColoring()` | colors []; 0 colors | proper; Delta = 0, so 0 <= colors <= 1 |
| CO-196 | EdgeColoring | one vertex | V [0]; E [] | `edgeColoring()` | colors []; 0 colors | proper; Delta = 0, so 0 <= colors <= 1 |
| CO-197 | EdgeColoring | one edge | V [0, 1]; E [0-1] | `edgeColoring()` | colors [0]; 1 colors | proper; Delta = 1, so 1 <= colors <= 2; = rustworkx misra_gries_edge_color |
| CO-198 | EdgeColoring | path P(5): Delta 2 | P(5) | `edgeColoring()` | colors [0, 1, 0, 1]; 2 colors | proper; Delta = 2, so 2 <= colors <= 3; rustworkx misra_gries uses 3 |
| CO-199 | EdgeColoring | triangle: class 2, Delta + 1 | K(3) | `edgeColoring()` | colors [0, 1, 2]; 3 colors | proper; Delta = 2, so 2 <= colors <= 3; = rustworkx misra_gries_edge_color |
| CO-200 | EdgeColoring | K(4): class 1 | K(4) | `edgeColoring()` | colors [0, 1, 2, 3, 1, 0]; 4 colors | proper; Delta = 3, so 3 <= colors <= 4; rustworkx misra_gries uses 4 |
| CO-201 | EdgeColoring | K(5): class 2 | K(5) | `edgeColoring()` | colors [0, 1, 2, 3, 4, 1, 2, 3, 0, 4]; 5 colors | proper; Delta = 4, so 4 <= colors <= 5; rustworkx misra_gries uses 5 |
| CO-202 | EdgeColoring | cycle C(5): odd, 3 | C(5) | `edgeColoring()` | colors [0, 1, 0, 1, 2]; 3 colors | proper; Delta = 2, so 2 <= colors <= 3; rustworkx misra_gries uses 3 |
| CO-203 | EdgeColoring | cycle C(6) | C(6) | `edgeColoring()` | colors [0, 1, 0, 1, 0, 1]; 2 colors | proper; Delta = 2, so 2 <= colors <= 3; rustworkx misra_gries uses 3 |
| CO-204 | EdgeColoring | star(5): Delta | star(5) | `edgeColoring()` | colors [0, 1, 2, 3, 4]; 5 colors | proper; Delta = 5, so 5 <= colors <= 6; rustworkx misra_gries uses 5 |
| CO-205 | EdgeColoring | wheel(5) | wheel(5) | `edgeColoring()` | colors [0, 1, 2, 3, 4, 5, 0, 1, 0, 1]; 6 colors | proper; Delta = 5, so 5 <= colors <= 6; rustworkx misra_gries uses 6 |
| CO-206 | EdgeColoring | Petersen: class 2, 4 colours | nx(petersen_graph) | `edgeColoring()` | colors [2, 1, 0, 1, 0, 0, 2, 3, 1, 0, 1, 2, 3, 2, 3]; 4 colors | proper; Delta = 3, so 3 <= colors <= 4; rustworkx misra_gries uses 4 |
| CO-207 | EdgeColoring | grid(3,4) | grid(3,4) | `edgeColoring()` | colors [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0]; 4 colors | proper; Delta = 4, so 4 <= colors <= 5; rustworkx misra_gries uses 5 |
| CO-208 | EdgeColoring | Kb(3,3) | Kb(3,3) | `edgeColoring()` | colors [0, 1, 2, 1, 2, 0, 2, 0, 1]; 3 colors | proper; Delta = 3, so 3 <= colors <= 4; rustworkx misra_gries uses 3 |
| CO-209 | EdgeColoring | nx(dodecahedral_graph) | nx(dodecahedral_graph) | `edgeColoring()` | colors [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 2, 1, 0, 1, 0, 1, 0]; 3 colors | proper; Delta = 3, so 3 <= colors <= 4; rustworkx misra_gries uses 4 |
| CO-210 | EdgeColoring | nx(karate_club_graph) | nx(karate_club_graph) | `edgeColoring()` | colors [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 14, 13, 16, 1, 2, 3, 4, 13, 6, 7, 0, 8, 2, 3, 4, 5, 6, 7, 3, 4, 5, 0, 1, 16, 0, 1, 2, 0, 1, 3, 0, 16, 0, 1, 3, 2, 2, 4, 5, 4, 6, 5, 7, 0, 1, 2, 6, 8, 1, 0, 2, 3, 0, 9, 10, 0, 11, 8, 12, 9, 13, 10, 15, 14]; 17 colors | proper; Delta = 17, so 17 <= colors <= 18; rustworkx misra_gries uses 17 |
| CO-211 | EdgeColoring | edge order matters: C(4) listed 0-1, 2-3, 1-2, 3-0 | V [0, 1, 2, 3]; E [0-1, 2-3, 1-2, 3-0] | `edgeColoring()` | colors [0, 0, 1, 1]; 2 colors | proper; Delta = 2, so 2 <= colors <= 3; = rustworkx misra_gries_edge_color |
| CO-212 | EdgeColoring | lcg(12,24,1) | lcg(12,24,1) | `edgeColoring()` | colors [0, 0, 1, 1, 2, 0, 4, 3, 1, 1, 3, 3, 1, 2, 4, 3, 0, 4, 2, 5, 0, 2, 6, 5]; 7 colors | proper; Delta = 7, so 7 <= colors <= 8; rustworkx misra_gries uses 8 |
| CO-213 | EdgeColoring | lcg(20,50,7) | lcg(20,50,7) | `edgeColoring()` | colors [0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 2, 1, 3, 3, 1, 2, 1, 2, 2, 3, 0, 2, 2, 0, 3, 4, 2, 4, 3, 0, 5, 6, 2, 3, 4, 4, 5, 7, 5, 3, 7, 0, 6, 4, 6, 1, 5, 4, 6, 8]; 9 colors | proper; Delta = 9, so 9 <= colors <= 10; rustworkx misra_gries uses 9 |
| CO-214 | EdgeColoring | lcg(30,90,3) | lcg(30,90,3) | `edgeColoring()` | colors [0, 6, 1, 1, 1, 4, 0, 2, 1, 2, 0, 0, 3, 1, 3, 0, 0, 3, 3, 8, 4, 5, 4, 2, 0, 2, 5, 8, 1, 4, 2, 4, 1, 4, 6, 6, 1, 7, 8, 1, 4, 0, 0, 6, 1, 2, 2, 5, 3, 3, 3, 12, 7, 1, 6, 2, 6, 4, 8, 4, 0, 3, 8, 5, 5, 0, 6, 8, 1, 5, 9, 9, 10, 7, 3, 2, 6, 10, 2, 11, 9, 2, 5, 2, 9, 8, 7, 6, 7, 0]; 13 colors | proper; Delta = 13, so 13 <= colors <= 14; rustworkx misra_gries uses 13 |
| CO-215 | EdgeColoring | self-loop | V [0]; E [0-0] | `edgeColoring()` | trap | precondition: simple graph |
| CO-216 | EdgeColoring | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `edgeColoring()` | trap | precondition: simple graph |
| CO-217 | BipartiteEdgeColoring | empty graph | V []; E [] | `bipartiteEdgeColoring()` | colors []; 0 colors | proper; exactly Delta = 0 colors (Koenig) |
| CO-218 | BipartiteEdgeColoring | one edge | V [0, 1]; E [0-1] | `bipartiteEdgeColoring()` | colors [0]; 1 colors | proper; exactly Delta = 1 colors (Koenig); rustworkx bipartite_edge_color uses 1 |
| CO-219 | BipartiteEdgeColoring | path P(6) | P(6) | `bipartiteEdgeColoring()` | colors [0, 1, 0, 1, 0]; 2 colors | proper; exactly Delta = 2 colors (Koenig); rustworkx bipartite_edge_color uses 2 |
| CO-220 | BipartiteEdgeColoring | cycle C(6) | C(6) | `bipartiteEdgeColoring()` | colors [0, 1, 0, 1, 0, 1]; 2 colors | proper; exactly Delta = 2 colors (Koenig); rustworkx bipartite_edge_color uses 2 |
| CO-221 | BipartiteEdgeColoring | Kb(3,3): Latin square | Kb(3,3) | `bipartiteEdgeColoring()` | colors [2, 0, 1, 1, 2, 0, 0, 1, 2]; 3 colors | proper; exactly Delta = 3 colors (Koenig); rustworkx bipartite_edge_color uses 3 |
| CO-222 | BipartiteEdgeColoring | Kb(2,4) | Kb(2,4) | `bipartiteEdgeColoring()` | colors [1, 2, 3, 0, 0, 1, 2, 3]; 4 colors | proper; exactly Delta = 4 colors (Koenig); rustworkx bipartite_edge_color uses 4 |
| CO-223 | BipartiteEdgeColoring | crown(4) | crown(4) | `bipartiteEdgeColoring()` | colors [0, 1, 2, 2, 0, 1, 1, 2, 0, 0, 1, 2]; 3 colors | proper; exactly Delta = 3 colors (Koenig); rustworkx bipartite_edge_color uses 3 |
| CO-224 | BipartiteEdgeColoring | grid(3,4) | grid(3,4) | `bipartiteEdgeColoring()` | colors [0, 1, 1, 2, 0, 2, 1, 0, 2, 1, 3, 0, 3, 2, 0, 1, 0]; 4 colors | proper; exactly Delta = 4 colors (Koenig); rustworkx bipartite_edge_color uses 4 |
| CO-225 | BipartiteEdgeColoring | nx(heawood_graph) | nx(heawood_graph) | `bipartiteEdgeColoring()` | colors [0, 1, 2, 1, 2, 0, 2, 1, 2, 0, 2, 1, 0, 2, 1, 0, 2, 1, 0, 1, 0]; 3 colors | proper; exactly Delta = 3 colors (Koenig); rustworkx bipartite_edge_color uses 3 |
| CO-226 | BipartiteEdgeColoring | bipartite multigraph: parallel edges need different colours | multigraph V [0, 1, 2]; E [0-1, 0-1, 1-2, 0-1] | `bipartiteEdgeColoring()` | colors [0, 1, 3, 2]; 4 colors | proper; exactly Delta = 4 colors (Koenig); rustworkx bipartite_edge_color uses 4 |
| CO-227 | BipartiteEdgeColoring | lcgb(6,6,20,4) | lcgb(6,6,20,4) | `bipartiteEdgeColoring()` | colors [1, 1, 0, 2, 1, 2, 2, 1, 2, 0, 0, 3, 0, 3, 0, 4, 0, 2, 1, 3]; 5 colors | proper; exactly Delta = 5 colors (Koenig); rustworkx bipartite_edge_color uses 5 |
| CO-228 | BipartiteEdgeColoring | lcgb(8,5,30,11) | lcgb(8,5,30,11) | `bipartiteEdgeColoring()` | colors [2, 5, 3, 3, 1, 2, 1, 4, 0, 0, 0, 4, 4, 3, 6, 2, 2, 1, 3, 5, 3, 5, 4, 1, 5, 2, 1, 4, 0, 0]; 7 colors | proper; exactly Delta = 7 colors (Koenig); rustworkx bipartite_edge_color uses 7 |
| CO-229 | BipartiteEdgeColoring | triangle: nil | K(3) | `bipartiteEdgeColoring()` | nil | not bipartite (NetworkX is_bipartite false) |
| CO-230 | BipartiteEdgeColoring | self-loop: nil | V [0, 1]; E [0-1, 1-1] | `bipartiteEdgeColoring()` | nil | not bipartite (NetworkX is_bipartite false) |
| CO-231 | BipartiteEdgeColoring | Petersen: nil | nx(petersen_graph) | `bipartiteEdgeColoring()` | nil | not bipartite (NetworkX is_bipartite false) |
| CO-232 | Checks | empty colouring of the empty graph | V []; E [] | `isVertexColoring { [][$0] }` | true | = NetworkX is_coloring |
| CO-233 | Checks | one colour on an edge | V [0, 1]; E [0-1] | `isVertexColoring { [0, 0][$0] }` | false | = NetworkX is_coloring |
| CO-234 | Checks | two colours on an edge | V [0, 1]; E [0-1] | `isVertexColoring { [0, 1][$0] }` | true | = NetworkX is_coloring |
| CO-235 | Checks | self-loop ignored | V [0]; E [0-0] | `isVertexColoring { [0][$0] }` | true | NetworkX is_coloring says False (it checks self-loops) |
| CO-236 | Checks | self-loop ignored with a proper rest | V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2] | `isVertexColoring { [0, 1, 2, 0][$0] }` | true | NetworkX is_coloring says False (it checks self-loops) |
| CO-237 | Checks | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `isVertexColoring { [0, 1, 0][$0] }` | true | = NetworkX is_coloring |
| CO-238 | Checks | triangle with a repeat | K(3) | `isVertexColoring { [0, 1, 1][$0] }` | false | = NetworkX is_coloring |
| CO-239 | Checks | colours need not be 0..<k or contiguous | P(3) | `isVertexColoring { [7, -2, 7][$0] }` | true | = NetworkX is_coloring |
| CO-240 | Checks | Petersen, a greedy colouring | nx(petersen_graph) | `isVertexColoring { [0, 1, 0, 1, 2, 1, 0, 2, 2, 1][$0] }` | true | = NetworkX is_coloring |
| CO-241 | Checks | empty | V []; E [] | `isEdgeColoring { [][$0] }` | true | definition |
| CO-242 | Checks | path, alternating | P(4) | `isEdgeColoring { [0, 1, 0][$0] }` | true | definition |
| CO-243 | Checks | path, repeat at a shared end | P(4) | `isEdgeColoring { [0, 0, 1][$0] }` | false | definition |
| CO-244 | Checks | parallel edges share both ends | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `isEdgeColoring { [0, 0, 1][$0] }` | false | definition |
| CO-245 | Checks | parallel edges, distinct | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `isEdgeColoring { [0, 1, 2][$0] }` | true | definition |
| CO-246 | Checks | a self-loop meets the other edges at its vertex | V [0, 1]; E [0-0, 0-1] | `isEdgeColoring { [0, 0][$0] }` | false | definition |
| CO-247 | Checks | a self-loop alone | V [0]; E [0-0] | `isEdgeColoring { [0][$0] }` | true | definition |
| CO-248 | Trap | order misses a vertex | P(3) | `greedyColoring(order: [0, 1])` | trap | precondition: every vertex exactly once (NetworkX KeyError later, Boost undefined) |
| CO-249 | Trap | order repeats a vertex | P(3) | `greedyColoring(order: [0, 1, 1, 2])` | trap | precondition |
| CO-250 | Trap | order names a non-vertex | P(3) | `greedyColoring(order: [0, 1, 2, 3])` | trap | precondition |
| CO-251 | Trap | color(of:) a non-vertex | P(3) | `greedyColoring().color(of: 9)` | trap | precondition |
| CO-252 | Trap | color(ofIndex:) out of range | P(3) | `greedyColoring().color(ofIndex: 3)` | trap | precondition: index in 0..<vertexCount |
| CO-253 | EdgeColoring | lcgb(8,5,30,11): Delta + 1 on a bipartite graph (bipartiteEdgeColoring gives Delta, CO-228) | lcgb(8,5,30,11) | `edgeColoring()` | colors [0, 0, 1, 0, 2, 1, 2, 3, 0, 4, 0, 4, 3, 1, 3, 3, 5, 2, 1, 1, 4, 4, 5, 3, 4, 6, 2, 7, 5, 5]; 8 colors | proper; Delta = 7, so 7 <= colors <= 8; rustworkx misra_gries uses 8 |
| CO-254 | MinimumColoring | empty graph | V []; E [] | `minimumColoring()` | colors []; 0 colors | forced: no edges; = inclusion-exclusion count |
| CO-255 | MinimumColoring | one vertex | V [0]; E [] | `minimumColoring()` | colors [0]; 1 colors | forced: no edges; = inclusion-exclusion count |
| CO-256 | MinimumColoring | self-loop ignored | V [0]; E [0-0] | `minimumColoring()` | colors [0]; 1 colors | forced: no edges; = inclusion-exclusion count |
| CO-257 | MinimumColoring | two isolated | V [0, 1]; E [] | `minimumColoring()` | colors [0, 0]; 1 colors | forced: no edges; = inclusion-exclusion count |
| CO-258 | MinimumColoring | one edge | V [0, 1]; E [0-1] | `minimumColoring()` | colors [0, 1]; 2 colors | forced: bipartite, the sides; = inclusion-exclusion count |
| CO-259 | MinimumColoring | parallel edges | multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2] | `minimumColoring()` | colors [0, 1, 0]; 2 colors | forced: bipartite, the sides; = inclusion-exclusion count |
| CO-260 | MinimumColoring | triangle | K(3) | `minimumColoring()` | colors [0, 1, 2]; 3 colors | forced: the only χ-colouring numbered by first appearance (exhaustive search); = inclusion-exclusion count |
| CO-261 | MinimumColoring | K(5): index order | K(5) | `minimumColoring()` | colors [0, 1, 2, 3, 4]; 5 colors | forced: the only χ-colouring numbered by first appearance (exhaustive search); = inclusion-exclusion count |
| CO-262 | MinimumColoring | path P(5): bipartition | P(5) | `minimumColoring()` | colors [0, 1, 0, 1, 0]; 2 colors | forced: bipartite, the sides; = inclusion-exclusion count |
| CO-263 | MinimumColoring | cycle C(5) | C(5) | `minimumColoring()` | 3 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-264 | MinimumColoring | cycle C(7) | C(7) | `minimumColoring()` | 3 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-265 | MinimumColoring | wheel(5) | wheel(5) | `minimumColoring()` | 4 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-266 | MinimumColoring | wheel(6) | wheel(6) | `minimumColoring()` | colors [0, 1, 2, 1, 2, 1, 2]; 3 colors | forced: the only χ-colouring numbered by first appearance (exhaustive search); = inclusion-exclusion count |
| CO-267 | MinimumColoring | Petersen | nx(petersen_graph) | `minimumColoring()` | 3 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-268 | MinimumColoring | crownx(4): 2 colours, where first fit needs 4 | crownx(4) | `minimumColoring()` | colors [0, 1, 0, 1, 0, 1, 0, 1]; 2 colors | forced: bipartite, the sides; = inclusion-exclusion count |
| CO-269 | MinimumColoring | first fit not optimal, so the search decides | V [0, 1, 2, 3, 4, 5]; E [0-2, 2-3, 3-1, 1-4, 4-5, 5-0, 2-5] | `minimumColoring()` | 3 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-270 | MinimumColoring | P4 numbered 0-2-3-1 beside a triangle: each component its own chi | V [0, 1, 2, 3, 4, 5, 6]; E [0-2, 2-3, 3-1, 4-5, 5-6, 6-4] | `minimumColoring()` | 3 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-271 | MinimumColoring | vertex order, not label order | V [d, a, c, b]; E [d-a, a-c, c-b, b-d, d-c] | `minimumColoring()` | colors [0, 1, 2, 1]; 3 colors | forced: the only χ-colouring numbered by first appearance (exhaustive search); = inclusion-exclusion count |
| CO-272 | MinimumColoring | nx(mycielski_graph,4): Groetzsch | nx(mycielski_graph,4) | `minimumColoring()` | 4 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-273 | MinimumColoring | nx(chvatal_graph) | nx(chvatal_graph) | `minimumColoring()` | 4 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-274 | MinimumColoring | queen(5) | queen(5) | `minimumColoring()` | 5 colors, proper, numbered by first appearance | = literature value (clique number 5) |
| CO-275 | MinimumColoring | nx(dodecahedral_graph) | nx(dodecahedral_graph) | `minimumColoring()` | 3 colors, proper, numbered by first appearance | certified: not bipartite, and the colouring has 3 |
| CO-276 | MinimumColoring | nx(bull_graph) | nx(bull_graph) | `minimumColoring()` | 3 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-277 | MinimumColoring | nx(house_x_graph) | nx(house_x_graph) | `minimumColoring()` | 4 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-278 | MinimumColoring | lcg(12,24,1) | lcg(12,24,1) | `minimumColoring()` | 4 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-279 | MinimumColoring | lcg(14,40,5) | lcg(14,40,5) | `minimumColoring()` | 4 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-280 | MinimumColoring | lcg(16,60,9) | lcg(16,60,9) | `minimumColoring()` | 5 colors, proper, numbered by first appearance | = inclusion-exclusion count |
| CO-281 | MinimumColoring | self-loops ignored in a bigger graph | V [0, 1, 2, 3]; E [0-1, 1-1, 1-2, 2-3, 3-3, 0-2] | `minimumColoring()` | 3 colors, proper, numbered by first appearance | = inclusion-exclusion count |
