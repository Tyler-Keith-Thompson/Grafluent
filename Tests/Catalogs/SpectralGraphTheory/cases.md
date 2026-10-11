# SpectralGraphTheory: case catalog (SGT-001 – SGT-217, 217 rows; SGT-205 onward are phase 2)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
scipy==1.18.1 --with numpy==2.5.4 python3 Tests/Catalogs/SpectralGraphTheory/ref.py`; `--write`
regenerates this file, `--stress` adds random multigraphs). The model builds every matrix from the
definitions in api.md in exact fractions (floating point only for the normalized matrices),
takes spectra from `numpy.linalg.eigvalsh`, and counts spanning trees, resistances and effective
graph resistance exactly. Rows are also checked against closed forms (complete, path, cycle,
star, complete bipartite, hypercube, grid, Petersen spectra), brute-force spanning-tree and
arborescence enumeration (at most 16 edges), the Moore–Penrose pseudoinverse, NetworkX 3.7 and
SciPy 1.18.1; the disagreements are in api.md.

## Notation

**Graph**: `U:` undirected, `D:` directed. An optional vertex list in brackets comes first, then
edges in **position order**. `vertices` is the listed vertices, then the vertices of generators,
then endpoints by first appearance. Vertices are `Int`s; matrix rows and vector entries follow
`vertices` order.

| Token | Edges |
|---|---|
| `u-v`, `u>v`, `u=v` | one edge (`u-u` a self-loop); one arc; two parallel edges u–v |
| `P(a,b,…)`, `C(a,b,…,z)` | the path a–b, b–c, …; the cycle a–b, …, z–a (arcs in a `D:` graph) |
| `S(c;a..b)` | the star c–a, …, c–b |
| `K(n)`, `K(a..b)` | vertices listed, every pair i < j, lexicographic |
| `KB(a..b;c..d)` | each of the first list to each of the second, row-major |
| `E(n)` | vertices 0..<n, no edges |
| `grid(r,c)` | vertices `i*c + j` listed; for each vertex in order the edge right, then down |
| `Q(d)` | hypercube: vertices 0..<2^d listed; for i in order, for k = 0..<d, i–(i ^ 2^k) when i < i ^ 2^k |
| `nx(name)` | `networkx.<name>_graph()`: its `nodes` listed, then `edges()` in NetworkX's order |
| `lcg(n,m,s)` | vertices 0..<n, then m non-loop pairs from the 64-bit LCG of the Distances catalog, seeded s (parallel pairs possible) |
| `a..b` | every integer from a to b inclusive |

**Op** is the call on the graph. `(weight:) [w₀, w₁, …]` and `weight: […]` pass a weight closure
returning wₚ for the edge at position p (`nan`, `inf` are those `Double`s).

**Expected.**

- A matrix is its dense rows when n ≤ 8, with `nnz`, the number of stored entries (the nonzero
  ones: a `SparseMatrix` stores no zeros). For larger n: its invariants, `nnz`, the trace, the sum
  of all entries and the sum of their squares.
- A spectrum is ascending, each distinct value once with `×k` for its multiplicity. Above 30
  values: the count, the four smallest and two largest, the sum and the sum of squares.
- `fiedlerVector`: `λ₂ = …; [entries]` when λ₂ is simple, with the canonical sign (api.md); above
  16 vertices the first four entries and the indices of the largest and smallest entry.
  `degenerate: λ₂ = x ×k` means λ₂ has multiplicity k: the test checks only that the result is a
  unit vector orthogonal to the null vector with residual ‖Lx − λ₂x‖ within tolerance and
  Rayleigh quotient λ₂. `nil`: not connected.
- `spectralOrdering` lists vertices. `(ties: …)` marks rows whose order relies on the tie rule or
  a degenerate λ₂ (api.md): the test checks the order is sorted by the returned Fiedler values,
  not the exact list.
- Exact rationals are written `p/q (decimal)`; counts past 2⁵³ are written exactly with the
  `Double` that `numberOfSpanningTrees` returns.
- **Tolerances**: integers and rationals exact up to `Double` rounding (relative 1e-12); dense
  results (matrices, spectra, counts, effective graph resistance, Kemeny constant) within
  1e-9 · max(1, |largest value|); iterative results (`algebraicConnectivity`, `fiedlerVector`,
  `spectralOrdering`, `spectralRadius`, `resistanceDistance`) within 1e-6 · max(1, scale) for
  values and 1e-5 per vector entry. Decimals are printed to 10 significant digits.
- `**trap**` rows are preconditions.


| ID | Group | Case | Graph | Op | Expected |
|---|---|---|---|---|---|
| SGT-001 | Matrices | empty graph | `U:` | `laplacianMatrix()` | 0×0 |
| SGT-002 | Matrices | one vertex: a 1×1 zero matrix, no stored entries | `U: [0]` | `laplacianMatrix()` | [[0]] (nnz 0) |
| SGT-003 | Matrices | path on 3 vertices | `U: P(0,1,2)` | `adjacencyMatrix()` | [[0, 1, 0], [1, 0, 1], [0, 1, 0]] (nnz 4) |
| SGT-004 | Matrices | path on 3 vertices | `U: P(0,1,2)` | `laplacianMatrix()` | [[1, -1, 0], [-1, 2, -1], [0, -1, 1]] (nnz 7) |
| SGT-005 | Matrices | path on 3 vertices | `U: P(0,1,2)` | `normalizedLaplacianMatrix()` | [[1, -0.7071067812, 0], [-0.7071067812, 1, -0.7071067812], [0, -0.7071067812, 1]] (nnz 7) |
| SGT-006 | Matrices | path on 3 vertices | `U: P(0,1,2)` | `randomWalkLaplacianMatrix()` | [[1, -1, 0], [-1/2 (-0.5), 1, -1/2 (-0.5)], [0, -1, 1]] (nnz 7) |
| SGT-007 | Matrices | path on 3 vertices | `U: P(0,1,2)` | `signlessLaplacianMatrix()` | [[1, 1, 0], [1, 2, 1], [0, 1, 1]] (nnz 7) |
| SGT-008 | Matrices | K4 Laplacian | `U: K(4)` | `laplacianMatrix()` | [[3, -1, -1, -1], [-1, 3, -1, -1], [-1, -1, 3, -1], [-1, -1, -1, 3]] (nnz 16) |
| SGT-009 | Matrices | K4 normalized Laplacian | `U: K(4)` | `normalizedLaplacianMatrix()` | [[1, -0.3333333333, -0.3333333333, -0.3333333333], [-0.3333333333, 1, -0.3333333333, -0.3333333333], [-0.3333333333, -0.3333333333, 1, -0.3333333333], [-0.3333333333, -0.3333333333, -0.3333333333, 1]] (nnz 16) |
| SGT-010 | Matrices | star K1,3 normalized Laplacian | `U: S(0;1..3)` | `normalizedLaplacianMatrix()` | [[1, -0.5773502692, -0.5773502692, -0.5773502692], [-0.5773502692, 1, 0, 0], [-0.5773502692, 0, 1, 0], [-0.5773502692, 0, 0, 1]] (nnz 10) |
| SGT-011 | Matrices | rows follow `vertices` order, not vertex values | `U: [2,0,1] 2-0, 0-1` | `laplacianMatrix()` | [[1, -1, 0], [-1, 2, -1], [0, -1, 1]] (nnz 7) |
| SGT-012 | Matrices | rows follow `vertices` order: adjacency | `U: [2,0,1] 2-0, 0-1` | `adjacencyMatrix()` | [[0, 1, 0], [1, 0, 1], [0, 1, 0]] (nnz 4) |
| SGT-013 | Matrices | parallel edges add up | `U: 0=1, 1-2` | `adjacencyMatrix()` | [[0, 2, 0], [2, 0, 1], [0, 1, 0]] (nnz 4) |
| SGT-014 | Matrices | parallel edges add up | `U: 0=1, 1-2` | `laplacianMatrix()` | [[2, -2, 0], [-2, 3, -1], [0, -1, 1]] (nnz 7) |
| SGT-015 | Matrices | parallel edges add up | `U: 0=1, 1-2` | `normalizedLaplacianMatrix()` | [[1, -0.8164965809, 0], [-0.8164965809, 1, -0.5773502692], [0, -0.5773502692, 1]] (nnz 7) |
| SGT-016 | Matrices | self-loop: 2 on the diagonal of A, cancels in L | `U: 0-0, 0-1` | `adjacencyMatrix()` | [[2, 1], [1, 0]] (nnz 3) |
| SGT-017 | Matrices | self-loop: 2 on the diagonal of A, cancels in L | `U: 0-0, 0-1` | `laplacianMatrix()` | [[1, -1], [-1, 1]] (nnz 4) |
| SGT-018 | Matrices | self-loop: 2 on the diagonal of A, cancels in L | `U: 0-0, 0-1` | `normalizedLaplacianMatrix()` | [[0.3333333333, -0.5773502692], [-0.5773502692, 1]] (nnz 4) |
| SGT-019 | Matrices | self-loop: 2 on the diagonal of A, cancels in L | `U: 0-0, 0-1` | `randomWalkLaplacianMatrix()` | [[1/3 (0.3333333333), -1/3 (-0.3333333333)], [-1, 1]] (nnz 4) |
| SGT-020 | Matrices | self-loop: 2 on the diagonal of A, cancels in L | `U: 0-0, 0-1` | `signlessLaplacianMatrix()` | [[5, 1], [1, 1]] (nnz 4) |
| SGT-021 | Matrices | bouquet of two loops: A = [[4]], L = 0 | `U: 0-0, 0-0` | `adjacencyMatrix()` | [[4]] (nnz 1) |
| SGT-022 | Matrices | bouquet of two loops: normalized Laplacian is 0 | `U: 0-0, 0-0` | `normalizedLaplacianMatrix()` | [[0]] (nnz 0) |
| SGT-023 | Matrices | isolated vertex: zero row in the normalized Laplacian | `U: [0,1,2] 0-1` | `normalizedLaplacianMatrix()` | [[1, -1, 0], [-1, 1, 0], [0, 0, 0]] (nnz 4) |
| SGT-024 | Matrices | isolated vertex: zero row in the random-walk Laplacian | `U: [0,1,2] 0-1` | `randomWalkLaplacianMatrix()` | [[1, -1, 0], [-1, 1, 0], [0, 0, 0]] (nnz 4) |
| SGT-025 | Matrices | weighted path | `U: P(0,1,2)` | `adjacencyMatrix(weight:) [2, 0.5]` | [[0, 2, 0], [2, 0, 1/2 (0.5)], [0, 1/2 (0.5), 0]] (nnz 4) |
| SGT-026 | Matrices | weighted path | `U: P(0,1,2)` | `laplacianMatrix(weight:) [2, 0.5]` | [[2, -2, 0], [-2, 5/2 (2.5), -1/2 (-0.5)], [0, -1/2 (-0.5), 1/2 (0.5)]] (nnz 7) |
| SGT-027 | Matrices | weighted path | `U: P(0,1,2)` | `normalizedLaplacianMatrix(weight:) [2, 0.5]` | [[1, -0.894427191, 0], [-0.894427191, 1, -0.4472135955], [0, -0.4472135955, 1]] (nnz 7) |
| SGT-028 | Matrices | weighted path | `U: P(0,1,2)` | `randomWalkLaplacianMatrix(weight:) [2, 0.5]` | [[1, -1, 0], [-4/5 (-0.8), 1, -1/5 (-0.2)], [0, -1, 1]] (nnz 7) |
| SGT-029 | Matrices | weight 0: no stored entry | `U: P(0,1,2)` | `laplacianMatrix(weight:) [1, 0]` | [[1, -1, 0], [-1, 1, 0], [0, 0, 0]] (nnz 4) |
| SGT-030 | Matrices | parallel weights add up | `U: 0=1` | `laplacianMatrix(weight:) [1.5, 2.5]` | [[4, -4], [-4, 4]] (nnz 4) |
| SGT-031 | Matrices | adjacency allows negative weights | `U: P(0,1,2)` | `adjacencyMatrix(weight:) [-1, 2]` | [[0, -1, 0], [-1, 0, 2], [0, 2, 0]] (nnz 4) |
| SGT-032 | Matrices | Laplacian: negative weight | `U: P(0,1,2)` | `laplacianMatrix(weight:) [-1, 2]` | **trap** |
| SGT-033 | Matrices | Laplacian: NaN weight | `U: P(0,1,2)` | `laplacianMatrix(weight:) [nan, 2]` | **trap** |
| SGT-034 | Matrices | Laplacian: infinite weight | `U: P(0,1,2)` | `laplacianMatrix(weight:) [inf, 2]` | **trap** |
| SGT-035 | Matrices | adjacency: NaN weight | `U: P(0,1,2)` | `adjacencyMatrix(weight:) [nan, 2]` | **trap** |
| SGT-036 | Matrices | grid 10×10 Laplacian (invariants) | `U: grid(10,10)` | `laplacianMatrix()` | 100×100, nnz 460, trace 360, Σ entries 0, Σ entries² 1688 |
| SGT-037 | Matrices | hypercube Q4 normalized Laplacian (invariants) | `U: Q(4)` | `normalizedLaplacianMatrix()` | 16×16, nnz 80, trace 16, Σ entries 0, Σ entries² 20 |
| SGT-038 | Matrices | Petersen adjacency (invariants) | `U: nx(petersen)` | `adjacencyMatrix()` | 10×10, nnz 30, trace 0, Σ entries 30, Σ entries² 30 |
| SGT-039 | Matrices | karate club Laplacian (invariants) | `U: nx(karate_club)` | `laplacianMatrix()` | 34×34, nnz 190, trace 156, Σ entries 0, Σ entries² 1368 |
| SGT-040 | Matrices | directed 3-cycle adjacency | `D: C(0,1,2)` | `adjacencyMatrix()` | [[0, 1, 0], [0, 0, 1], [1, 0, 0]] (nnz 3) |
| SGT-041 | Matrices | directed Laplacian: out-degrees | `D: 0>1, 0>2, 1>2` | `laplacianMatrix()` | [[2, -1, -1], [0, 1, -1], [0, 0, 0]] (nnz 5) |
| SGT-042 | Matrices | directed self-loop: 1 on the diagonal, cancels in L | `D: 0>0, 0>1` | `adjacencyMatrix()` | [[1, 1], [0, 0]] (nnz 2) |
| SGT-043 | Matrices | directed self-loop cancels in the Laplacian | `D: 0>0, 0>1` | `laplacianMatrix()` | [[1, -1], [0, 0]] (nnz 2) |
| SGT-044 | Matrices | directed parallel arcs add up | `D: 0>1, 0>1, 1>0` | `adjacencyMatrix()` | [[0, 2], [1, 0]] (nnz 2) |
| SGT-045 | Matrices | directed weighted Laplacian | `D: 0>1, 1>2, 2>0, 0>2` | `laplacianMatrix(weight:) [1, 2, 3, 4]` | [[5, -1, -4], [0, 2, -2], [-3, 0, 3]] (nnz 7) |
| SGT-046 | Matrices | directed isolated vertex | `D: [0,1,2] 0>1` | `laplacianMatrix()` | [[1, -1, 0], [0, 0, 0], [0, 0, 0]] (nnz 2) |
| SGT-047 | Spectra | empty graph | `U:` | `laplacianSpectrum()` | [] |
| SGT-048 | Spectra | one vertex | `U: [0]` | `laplacianSpectrum()` | 0 |
| SGT-049 | Spectra | three isolated vertices | `U: E(3)` | `laplacianSpectrum()` | 0 ×3 |
| SGT-050 | Spectra | K2 | `U: K(2)` | `laplacianSpectrum()` | 0, 2 |
| SGT-051 | Spectra | K5 | `U: K(5)` | `laplacianSpectrum()` | 0, 5 ×4 |
| SGT-052 | Spectra | path P5 | `U: P(0..4)` | `laplacianSpectrum()` | 0, 0.3819660113, 1.381966011, 2.618033989, 3.618033989 |
| SGT-053 | Spectra | cycle C6 | `U: C(0..5)` | `laplacianSpectrum()` | 0, 1 ×2, 3 ×2, 4 |
| SGT-054 | Spectra | star K1,4 | `U: S(0;1..4)` | `laplacianSpectrum()` | 0, 1 ×3, 5 |
| SGT-055 | Spectra | hypercube Q3 | `U: Q(3)` | `laplacianSpectrum()` | 0, 2 ×3, 4 ×3, 6 |
| SGT-056 | Spectra | K5 | `U: K(5)` | `adjacencySpectrum()` | -1 ×4, 4 |
| SGT-057 | Spectra | path P5 | `U: P(0..4)` | `adjacencySpectrum()` | -1.732050808, -1, 0, 1, 1.732050808 |
| SGT-058 | Spectra | cycle C6 | `U: C(0..5)` | `adjacencySpectrum()` | -2, -1 ×2, 1 ×2, 2 |
| SGT-059 | Spectra | star K1,4 | `U: S(0;1..4)` | `adjacencySpectrum()` | -2, 0 ×3, 2 |
| SGT-060 | Spectra | hypercube Q3 | `U: Q(3)` | `adjacencySpectrum()` | -3, -1 ×3, 1 ×3, 3 |
| SGT-061 | Spectra | K5 | `U: K(5)` | `normalizedLaplacianSpectrum()` | 0, 1.25 ×4 |
| SGT-062 | Spectra | path P5 | `U: P(0..4)` | `normalizedLaplacianSpectrum()` | 0, 0.2928932188, 1, 1.707106781, 2 |
| SGT-063 | Spectra | cycle C6 | `U: C(0..5)` | `normalizedLaplacianSpectrum()` | 0, 0.5 ×2, 1.5 ×2, 2 |
| SGT-064 | Spectra | star K1,4 | `U: S(0;1..4)` | `normalizedLaplacianSpectrum()` | 0, 1 ×3, 2 |
| SGT-065 | Spectra | hypercube Q3 | `U: Q(3)` | `normalizedLaplacianSpectrum()` | 0, 0.6666666667 ×3, 1.333333333 ×3, 2 |
| SGT-066 | Spectra | K2,3 Laplacian | `U: KB(0..1;2..4)` | `laplacianSpectrum()` | 0, 2 ×2, 3, 5 |
| SGT-067 | Spectra | K2,3 adjacency | `U: KB(0..1;2..4)` | `adjacencySpectrum()` | -2.449489743, 0 ×3, 2.449489743 |
| SGT-068 | Spectra | Petersen Laplacian | `U: nx(petersen)` | `laplacianSpectrum()` | 0, 2 ×5, 5 ×4 |
| SGT-069 | Spectra | Petersen adjacency | `U: nx(petersen)` | `adjacencySpectrum()` | -2 ×4, 1 ×5, 3 |
| SGT-070 | Spectra | grid 3×4 Laplacian | `U: grid(3,4)` | `laplacianSpectrum()` | 0, 0.5857864376, 1, 1.585786438, 2, 3 ×2, 3.414213562, 3.585786438, 4.414213562, 5, 6.414213562 |
| SGT-071 | Spectra | two triangles: 0 twice | `U: C(0,1,2), C(3,4,5)` | `laplacianSpectrum()` | 0 ×2, 3 ×4 |
| SGT-072 | Spectra | path and isolated vertex, normalized: 0 per component | `U: [0,1,2,3] P(0,1,2)` | `normalizedLaplacianSpectrum()` | 0 ×2, 1, 2 |
| SGT-073 | Spectra | doubled edge | `U: 0=1` | `laplacianSpectrum()` | 0, 4 |
| SGT-074 | Spectra | self-loop: adjacency 1 ± √2 | `U: 0-0, 0-1` | `adjacencySpectrum()` | -0.4142135624, 2.414213562 |
| SGT-075 | Spectra | self-loop: Laplacian unchanged | `U: 0-0, 0-1` | `laplacianSpectrum()` | 0, 2 |
| SGT-076 | Spectra | self-loop: normalized | `U: 0-0, 0-1` | `normalizedLaplacianSpectrum()` | 0, 1.333333333 |
| SGT-077 | Spectra | weighted triangle | `U: C(0,1,2)` | `laplacianSpectrum(weight:) [1, 2, 3]` | 0, 4.267949192, 7.732050808 |
| SGT-078 | Spectra | weighted triangle, normalized | `U: C(0,1,2)` | `normalizedLaplacianSpectrum(weight:) [1, 2, 3]` | 0, 1.276393202, 1.723606798 |
| SGT-079 | Spectra | grid 20×20 Laplacian (summary) | `U: grid(20,20)` | `laplacianSpectrum()` | 400 values; smallest 0, 0.02462331881, 0.02462331881, 0.04924663762; largest 7.877489714, 7.950753362; Σ 1520; Σ² 7368 |
| SGT-080 | Spectra | hypercube Q6 Laplacian (summary) | `U: Q(6)` | `laplacianSpectrum()` | 64 values; smallest 0, 2, 2, 2; largest 10, 12; Σ 384; Σ² 2688 |
| SGT-081 | Spectra | karate club Laplacian (summary) | `U: nx(karate_club)` | `laplacianSpectrum()` | 34 values; smallest 0, 0.4685252267, 0.9092476638, 1.125010718; largest 17.05517119, 18.13669597; Σ 156; Σ² 1368 |
| SGT-082 | Spectra | karate club adjacency (summary) | `U: nx(karate_club)` | `adjacencySpectrum()` | 34 values; smallest -4.487229194, -3.447934858, -3.110690917, -2.437424427; largest 4.977074233, 6.725697728; Σ 0; Σ² 156 |
| SGT-083 | Spectra | random multigraph lcg(60,150,3) normalized (summary) | `U: lcg(60,150,3)` | `normalizedLaplacianSpectrum()` | 60 values; smallest 0, 0.2002576706, 0.2351635713, 0.2403154366; largest 1.754407671, 1.80528904; Σ 60; Σ² 73.58148369 |
| SGT-084 | Spectra | negative weight | `U: P(0,1,2)` | `laplacianSpectrum(weight:) [-1, 1]` | **trap** |
| SGT-085 | Algebraic connectivity | K2 | `U: K(2)` | `algebraicConnectivity()` | 2 |
| SGT-086 | Algebraic connectivity | path P10: 2 − 2cos(π/10) | `U: P(0..9)` | `algebraicConnectivity()` | 0.09788696741 |
| SGT-087 | Algebraic connectivity | cycle C10: 2 − 2cos(2π/10) | `U: C(0..9)` | `algebraicConnectivity()` | 0.3819660113 |
| SGT-088 | Algebraic connectivity | K6 | `U: K(6)` | `algebraicConnectivity()` | 6 |
| SGT-089 | Algebraic connectivity | star K1,5 | `U: S(0;1..5)` | `algebraicConnectivity()` | 1 |
| SGT-090 | Algebraic connectivity | hypercube Q4 | `U: Q(4)` | `algebraicConnectivity()` | 2 |
| SGT-091 | Algebraic connectivity | Petersen | `U: nx(petersen)` | `algebraicConnectivity()` | 2 |
| SGT-092 | Algebraic connectivity | grid 10×10 | `U: grid(10,10)` | `algebraicConnectivity()` | 0.09788696741 |
| SGT-093 | Algebraic connectivity | grid 30×30 | `U: grid(30,30)` | `algebraicConnectivity()` | 0.01095620926 |
| SGT-094 | Algebraic connectivity | karate club | `U: nx(karate_club)` | `algebraicConnectivity()` | 0.4685252267 |
| SGT-095 | Algebraic connectivity | disconnected: 0 | `U: C(0,1,2), C(3,4,5)` | `algebraicConnectivity()` | 0 |
| SGT-096 | Algebraic connectivity | two isolated vertices: 0 | `U: E(2)` | `algebraicConnectivity()` | 0 |
| SGT-097 | Algebraic connectivity | doubled edge: 4 | `U: 0=1` | `algebraicConnectivity()` | 4 |
| SGT-098 | Algebraic connectivity | loops do not change L | `U: 0-0, P(0..3)` | `algebraicConnectivity()` | 0.5857864376 |
| SGT-099 | Algebraic connectivity | weighted path | `U: P(0..3)` | `algebraicConnectivity(weight:) [1, 2, 3]` | 0.9358222275 |
| SGT-100 | Algebraic connectivity | weight 0 disconnects | `U: P(0..3)` | `algebraicConnectivity(weight:) [1, 0, 1]` | 0 |
| SGT-101 | Algebraic connectivity | path P10, normalized: 1 − cos(π/9) | `U: P(0..9)` | `algebraicConnectivity(normalized: true)` | 0.06030737921 |
| SGT-102 | Algebraic connectivity | Petersen, normalized | `U: nx(petersen)` | `algebraicConnectivity(normalized: true)` | 0.6666666667 |
| SGT-103 | Algebraic connectivity | karate club, normalized | `U: nx(karate_club)` | `algebraicConnectivity(normalized: true)` | 0.1322723292 |
| SGT-104 | Algebraic connectivity | self-loop, normalized: loops count in the degrees | `U: 0-0, P(0..3)` | `algebraicConnectivity(normalized: true)` | 0.3110562314 |
| SGT-105 | Algebraic connectivity | lcg(200,600,11) | `U: lcg(200,600,11)` | `algebraicConnectivity()` | 0.6454627161 |
| SGT-106 | Algebraic connectivity | one vertex | `U: [0]` | `algebraicConnectivity()` | **trap** |
| SGT-107 | Algebraic connectivity | empty graph | `U:` | `algebraicConnectivity()` | **trap** |
| SGT-108 | Fiedler vector | path P4 | `U: P(0..3)` | `fiedlerVector()` | λ₂ = 0.5857864376; [0.6532814824, 0.2705980501, -0.2705980501, -0.6532814824] |
| SGT-109 | Fiedler vector | path P5: middle entry 0 | `U: P(0..4)` | `fiedlerVector()` | λ₂ = 0.3819660113; [0.601500955, 0.3717480345, 0, -0.3717480345, -0.601500955] |
| SGT-110 | Fiedler vector | path P4 in another vertex order | `U: P(2,0,3,1)` | `fiedlerVector()` | λ₂ = 0.5857864376; [0.6532814824, 0.2705980501, -0.2705980501, -0.6532814824] |
| SGT-111 | Fiedler vector | canonical sign: the first significant entry is positive | `U: P(3,2,1,0)` | `fiedlerVector()` | λ₂ = 0.5857864376; [0.6532814824, 0.2705980501, -0.2705980501, -0.6532814824] |
| SGT-112 | Fiedler vector | barbell: two K4 joined by an edge | `U: K(0..3), K(4..7), 3-4` | `fiedlerVector()` | λ₂ = 0.3542486889; [0.382527662, 0.382527662, 0.382527662, 0.2470177392, -0.2470177392, -0.382527662, -0.382527662, -0.382527662] |
| SGT-113 | Fiedler vector | grid 3×4 | `U: grid(3,4)` | `fiedlerVector()` | λ₂ = 0.5857864376; [0.3771722397, 0.1562298571, -0.1562298571, -0.3771722397, 0.3771722397, 0.1562298571, -0.1562298571, -0.3771722397, 0.3771722397, 0.1562298571, -0.1562298571, -0.3771722397] |
| SGT-114 | Fiedler vector | weighted path | `U: P(0..3)` | `fiedlerVector(weight:) [1, 2, 3]` | λ₂ = 0.9358222275; [0.7931284139, 0.05090121489, -0.3440296287, -0.5] |
| SGT-115 | Fiedler vector | parallel edge counts twice | `U: 0=1, P(1,2,3)` | `fiedlerVector()` | λ₂ = 0.6570769172; [0.5605806578, 0.3764083525, -0.2392654978, -0.6977235125] |
| SGT-116 | Fiedler vector | loop does not change it | `U: 1-1, P(0..3)` | `fiedlerVector()` | λ₂ = 0.5857864376; [0.2705980501, 0.6532814824, -0.2705980501, -0.6532814824] |
| SGT-117 | Fiedler vector | path P4 normalized | `U: P(0..3)` | `fiedlerVector(normalized: true)` | λ₂ = 0.5; [0.5773502692, 0.4082482905, -0.4082482905, -0.5773502692] |
| SGT-118 | Fiedler vector | karate club | `U: nx(karate_club)` | `fiedlerVector()` | λ₂ = 0.4685252267; first 4 [0.1121374323, 0.04128788812, -0.02321895576, 0.05549978091], argmax 16, argmin 26 |
| SGT-119 | Fiedler vector | K4: λ₂ = 4 ×3 | `U: K(4)` | `fiedlerVector()` | degenerate: λ₂ = 4 ×3 (some unit vector of that eigenspace) |
| SGT-120 | Fiedler vector | cycle C6: λ₂ = 1 ×2 | `U: C(0..5)` | `fiedlerVector()` | degenerate: λ₂ = 1 ×2 (some unit vector of that eigenspace) |
| SGT-121 | Fiedler vector | star K1,4: λ₂ = 1 ×3 | `U: S(0;1..4)` | `fiedlerVector()` | degenerate: λ₂ = 1 ×3 (some unit vector of that eigenspace) |
| SGT-122 | Fiedler vector | hypercube Q3 | `U: Q(3)` | `fiedlerVector()` | degenerate: λ₂ = 2 ×3 (some unit vector of that eigenspace) |
| SGT-123 | Fiedler vector | disconnected | `U: C(0,1,2), C(3,4,5)` | `fiedlerVector()` | nil |
| SGT-124 | Fiedler vector | two isolated vertices | `U: E(2)` | `fiedlerVector()` | nil |
| SGT-125 | Fiedler vector | weight 0 disconnects | `U: P(0..3)` | `fiedlerVector(weight:) [1, 0, 1]` | nil |
| SGT-126 | Fiedler vector | one vertex | `U: [0]` | `fiedlerVector()` | **trap** |
| SGT-127 | Spectral ordering | path in shuffled order | `U: P(2,0,4,1,3)` | `spectralOrdering()` | [3, 1, 4, 0, 2] |
| SGT-128 | Spectral ordering | barbell | `U: K(0..3), K(4..7), 3-4` | `spectralOrdering()` | [5, 6, 7, 4, 3, 0, 1, 2] (ties: index order within tolerance) |
| SGT-129 | Spectral ordering | components by least vertex; small ones in index order | `U: [0,1,2,3,4,5,6,7] P(5,1,6), 3-4, P(0,7,2)` | `spectralOrdering()` | [2, 7, 0, 6, 1, 5, 3, 4] |
| SGT-130 | Spectral ordering | grid 2×5: tied entries in index order | `U: grid(2,5)` | `spectralOrdering()` | [4, 9, 3, 8, 2, 7, 1, 6, 0, 5] (ties: index order within tolerance) |
| SGT-131 | Spectral ordering | weighted path | `U: P(0..4)` | `spectralOrdering(weight:) [1, 3, 1, 3]` | [4, 3, 2, 1, 0] |
| SGT-132 | Spectral ordering | karate club | `U: nx(karate_club)` | `spectralOrdering()` | [26, 29, 14, 15, 18, 20, 22, 25, 23, 24, 32, 27, 33, 31, 28, 9, 30, 8, 2, 19, 13, 1, 7, 3, 17, 21, 12, 0, 11, 4, 10, 5, 6, 16] (ties: index order within tolerance) |
| SGT-133 | Spectral ordering | one vertex | `U: [0]` | `spectralOrdering()` | [0] |
| SGT-134 | Spectral ordering | empty graph | `U:` | `spectralOrdering()` | [] |
| SGT-135 | Spectral radius | K5: 4 | `U: K(5)` | `spectralRadius()` | 4 |
| SGT-136 | Spectral radius | path P5: √3 | `U: P(0..4)` | `spectralRadius()` | 1.732050808 |
| SGT-137 | Spectral radius | cycle C7: 2 | `U: C(0..6)` | `spectralRadius()` | 2 |
| SGT-138 | Spectral radius | star K1,4: 2 | `U: S(0;1..4)` | `spectralRadius()` | 2 |
| SGT-139 | Spectral radius | Petersen: 3 | `U: nx(petersen)` | `spectralRadius()` | 3 |
| SGT-140 | Spectral radius | grid 10×10: 4cos(π/11) | `U: grid(10,10)` | `spectralRadius()` | 3.837971894 |
| SGT-141 | Spectral radius | karate club | `U: nx(karate_club)` | `spectralRadius()` | 6.725697728 |
| SGT-142 | Spectral radius | doubled edge: 2 | `U: 0=1` | `spectralRadius()` | 2 |
| SGT-143 | Spectral radius | self-loop: 1 + √2 | `U: 0-0, 0-1` | `spectralRadius()` | 2.414213562 |
| SGT-144 | Spectral radius | weighted | `U: C(0,1,2)` | `spectralRadius(weight:) [1, 2, 3]` | 4.113090584 |
| SGT-145 | Spectral radius | isolated vertices: 0 | `U: E(3)` | `spectralRadius()` | 0 |
| SGT-146 | Spectral radius | empty graph: 0 | `U:` | `spectralRadius()` | 0 |
| SGT-147 | Spectral radius | lcg(200,600,11) | `U: lcg(200,600,11)` | `spectralRadius()` | 7.070631103 |
| SGT-148 | Spanning trees | empty graph: 0 | `U:` | `numberOfSpanningTrees()` | 0 |
| SGT-149 | Spanning trees | one vertex: 1 | `U: [0]` | `numberOfSpanningTrees()` | 1 |
| SGT-150 | Spanning trees | two isolated vertices: 0 | `U: E(2)` | `numberOfSpanningTrees()` | 0 |
| SGT-151 | Spanning trees | K2 | `U: K(2)` | `numberOfSpanningTrees()` | 1 |
| SGT-152 | Spanning trees | K5: 5³ | `U: K(5)` | `numberOfSpanningTrees()` | 125 |
| SGT-153 | Spanning trees | K10: 10⁸ | `U: K(10)` | `numberOfSpanningTrees()` | 100000000 |
| SGT-154 | Spanning trees | K25: 25²³, past 2⁵³ | `U: K(25)` | `numberOfSpanningTrees()` | 142108547152020037174224853515625 (≈ 1.421085472e+32) |
| SGT-155 | Spanning trees | cycle C6 | `U: C(0..5)` | `numberOfSpanningTrees()` | 6 |
| SGT-156 | Spanning trees | path P6 | `U: P(0..5)` | `numberOfSpanningTrees()` | 1 |
| SGT-157 | Spanning trees | K3,3: 3²·3² | `U: KB(0..2;3..5)` | `numberOfSpanningTrees()` | 81 |
| SGT-158 | Spanning trees | Petersen: 2000 | `U: nx(petersen)` | `numberOfSpanningTrees()` | 2000 |
| SGT-159 | Spanning trees | hypercube Q3: 384 | `U: Q(3)` | `numberOfSpanningTrees()` | 384 |
| SGT-160 | Spanning trees | hypercube Q4 | `U: Q(4)` | `numberOfSpanningTrees()` | 42467328 |
| SGT-161 | Spanning trees | grid 3×3: 192 | `U: grid(3,3)` | `numberOfSpanningTrees()` | 192 |
| SGT-162 | Spanning trees | grid 8×8 | `U: grid(8,8)` | `numberOfSpanningTrees()` | 126231322912498539682594816 (≈ 1.262313229e+26) |
| SGT-163 | Spanning trees | doubled edge and pendant: 2 | `U: 0=1, 1-2` | `numberOfSpanningTrees()` | 2 |
| SGT-164 | Spanning trees | loop ignored | `U: 0-0, C(0,1,2)` | `numberOfSpanningTrees()` | 3 |
| SGT-165 | Spanning trees | weighted triangle: 1·2 + 2·3 + 1·3 | `U: C(0,1,2)` | `numberOfSpanningTrees(weight:) [1, 2, 3]` | 11 |
| SGT-166 | Spanning trees | weighted, fractional | `U: K(4)` | `numberOfSpanningTrees(weight:) [0.5, 1, 2, 1, 0.25, 3]` | 185/8 (23.125) |
| SGT-167 | Spanning trees | disconnected: 0 | `U: C(0,1,2), C(3,4,5)` | `numberOfSpanningTrees()` | 0 |
| SGT-168 | Spanning trees | karate club | `U: nx(karate_club)` | `numberOfSpanningTrees()` | 5090996323019136 |
| SGT-169 | Resistance distance | path: series | `U: P(0..3)` | `resistanceDistance(from: 0, to: 3)` | 3 |
| SGT-170 | Resistance distance | cycle C4: two paths of 2 in parallel | `U: C(0..3)` | `resistanceDistance(from: 0, to: 2)` | 1 |
| SGT-171 | Resistance distance | K4: 2/n | `U: K(4)` | `resistanceDistance(from: 1, to: 2)` | 1/2 (0.5) |
| SGT-172 | Resistance distance | same vertex: 0 | `U: K(4)` | `resistanceDistance(from: 2, to: 2)` | 0 |
| SGT-173 | Resistance distance | different components: nil | `U: C(0,1,2), C(3,4,5)` | `resistanceDistance(from: 0, to: 4)` | nil |
| SGT-174 | Resistance distance | isolated vertex to itself: 0 | `U: [0,1] ` | `resistanceDistance(from: 1, to: 1)` | 0 |
| SGT-175 | Resistance distance | doubled edge: 1/2 | `U: 0=1` | `resistanceDistance(from: 0, to: 1)` | 1/2 (0.5) |
| SGT-176 | Resistance distance | weights are conductances | `U: P(0..2)` | `resistanceDistance(from: 0, to: 2) weight: [2, 4]` | 3/4 (0.75) |
| SGT-177 | Resistance distance | Wheatstone bridge | `U: 0-1, 0-2, 1-2, 1-3, 2-3` | `resistanceDistance(from: 0, to: 3)` | 1 |
| SGT-178 | Resistance distance | Petersen, adjacent | `U: nx(petersen)` | `resistanceDistance(from: 0, to: 1)` | 3/5 (0.6) |
| SGT-179 | Resistance distance | Petersen, at distance 2 | `U: nx(petersen)` | `resistanceDistance(from: 0, to: 2)` | 4/5 (0.8) |
| SGT-180 | Resistance distance | grid 3×3 corners | `U: grid(3,3)` | `resistanceDistance(from: 0, to: 8)` | 3/2 (1.5) |
| SGT-181 | Resistance distance | loop ignored | `U: 1-1, P(0..2)` | `resistanceDistance(from: 0, to: 2)` | 2 |
| SGT-182 | Resistance distance | weight 0 disconnects: nil | `U: P(0..2)` | `resistanceDistance(from: 0, to: 2) weight: [1, 0]` | nil |
| SGT-183 | Resistance distance | not a vertex | `U: P(0..2)` | `resistanceDistance(from: 0, to: 9)` | **trap** |
| SGT-184 | Resistance distance | negative weight | `U: P(0..2)` | `resistanceDistance(from: 0, to: 2) weight: [1, -1]` | **trap** |
| SGT-185 | Effective graph resistance | empty graph: 0 | `U:` | `effectiveGraphResistance()` | 0 |
| SGT-186 | Effective graph resistance | one vertex: 0 | `U: [0]` | `effectiveGraphResistance()` | 0 |
| SGT-187 | Effective graph resistance | K5: n − 1 | `U: K(5)` | `effectiveGraphResistance()` | 4 |
| SGT-188 | Effective graph resistance | path P4: the Wiener index | `U: P(0..3)` | `effectiveGraphResistance()` | 10 |
| SGT-189 | Effective graph resistance | cycle C6 | `U: C(0..5)` | `effectiveGraphResistance()` | 35/2 (17.5) |
| SGT-190 | Effective graph resistance | Petersen | `U: nx(petersen)` | `effectiveGraphResistance()` | 33 |
| SGT-191 | Effective graph resistance | weighted | `U: C(0,1,2)` | `effectiveGraphResistance(weight:) [1, 2, 3]` | 12/11 (1.090909091) |
| SGT-192 | Effective graph resistance | disconnected: nil | `U: C(0,1,2), C(3,4,5)` | `effectiveGraphResistance()` | nil |
| SGT-193 | Effective graph resistance | karate club | `U: nx(karate_club)` | `effectiveGraphResistance()` | 37408337509227643/79546817547174 (470.268185) |
| SGT-194 | Kemeny constant | empty graph: 0 | `U:` | `kemenyConstant()` | 0 |
| SGT-195 | Kemeny constant | one vertex: 0 | `U: [0]` | `kemenyConstant()` | 0 |
| SGT-196 | Kemeny constant | K2: 1/2 | `U: K(2)` | `kemenyConstant()` | 0.5 |
| SGT-197 | Kemeny constant | K5 | `U: K(5)` | `kemenyConstant()` | 3.2 |
| SGT-198 | Kemeny constant | path P4 | `U: P(0..3)` | `kemenyConstant()` | 3.166666667 |
| SGT-199 | Kemeny constant | cycle C6 | `U: C(0..5)` | `kemenyConstant()` | 5.833333333 |
| SGT-200 | Kemeny constant | star K1,4 | `U: S(0;1..4)` | `kemenyConstant()` | 3.5 |
| SGT-201 | Kemeny constant | self-loop counts twice in the degree | `U: 0-0, P(0,1,2)` | `kemenyConstant()` | 2.333333333 |
| SGT-202 | Kemeny constant | weighted | `U: C(0,1,2)` | `kemenyConstant(weight:) [1, 2, 3]` | 1.363636364 |
| SGT-203 | Kemeny constant | disconnected: nil | `U: C(0,1,2), C(3,4,5)` | `kemenyConstant()` | nil |
| SGT-204 | Kemeny constant | karate club | `U: nx(karate_club)` | `kemenyConstant()` | 42.88668274 |
| SGT-205 | Phase 2 | arborescences of a directed 3-cycle from 0 | `D: C(0,1,2)` | `numberOfSpanningTrees(root: 0)` | 1 |
| SGT-206 | Phase 2 | arborescences, both arcs of K3 | `D: 0>1, 1>0, 0>2, 2>0, 1>2, 2>1` | `numberOfSpanningTrees(root: 0)` | 3 |
| SGT-207 | Phase 2 | arborescences: root reaches nothing | `D: 1>0, 2>0` | `numberOfSpanningTrees(root: 0)` | 0 |
| SGT-208 | Phase 2 | arborescences: weighted | `D: 0>1, 0>2, 1>2, 2>1` | `numberOfSpanningTrees(root: 0) weight: [1, 2, 3, 4]` | 13 |
| SGT-209 | Phase 2 | arborescences: parallel arcs and a loop | `D: 0>1, 0>1, 1>1, 1>2` | `numberOfSpanningTrees(root: 0)` | 2 |
| SGT-210 | Phase 2 | arborescences: root not a vertex | `D: C(0,1,2)` | `numberOfSpanningTrees(root: 7)` | **trap** |
| SGT-211 | Phase 2 | signless Laplacian of a bipartite graph = its Laplacian spectrum | `U: C(0..5)` | `signlessLaplacianSpectrum()` | 0, 1 ×2, 3 ×2, 4 |
| SGT-212 | Phase 2 | signless Laplacian of a triangle | `U: C(0,1,2)` | `signlessLaplacianSpectrum()` | 1 ×2, 4 |
| SGT-213 | Phase 2 | signless Laplacian with a loop: Q[v][v] gains 4 | `U: 0-0, 0-1` | `signlessLaplacianSpectrum()` | 0.7639320225, 5.236067977 |
| SGT-214 | Phase 2 | spectral bisection of the barbell | `U: K(0..3), K(4..7), 3-4` | `spectralBisection()` | ([4, 5, 6, 7], [0, 1, 2, 3]) |
| SGT-215 | Phase 2 | spectral bisection of P5: the zero entry joins the nonnegative side | `U: P(0..4)` | `spectralBisection()` | ([3, 4], [0, 1, 2]) |
| SGT-216 | Phase 2 | spectral bisection, degenerate λ₂ | `U: C(0..5)` | `spectralBisection()` | degenerate λ₂: some split by a λ₂ eigenvector |
| SGT-217 | Phase 2 | spectral bisection, disconnected | `U: C(0,1,2), C(3,4,5)` | `spectralBisection()` | nil |

217 rows.
